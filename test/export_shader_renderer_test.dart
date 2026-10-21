/*
 * KPix
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kpix/models/export_shader.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/export_shader_renderer.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:path/path.dart' as p;

import 'support/selection_harness.dart';

const ui.Color _red = ui.Color(0xFFFF0000);
const ui.Color _transparent = ui.Color(0x00000000);

Future<ui.Image> _source({required final int width, required final int height, required final ui.Color Function(int x, int y) color}) async
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  for (int y = 0; y < height; y++)
  {
    for (int x = 0; x < width; x++)
    {
      canvas.drawRect(ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), ui.Paint()..color = color(x, y));
    }
  }
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}

ExportShaderValues _lcd({final Map<String, Object> overrides = const <String, Object>{}})
{
  final ExportShaderValues values = ExportShaderValues(definition: exportShaderDefinitions[ExportShaderType.lcd]!);
  for (final ExportShaderParameter parameter in values.definition.parameters)
  {
    final Object? value = overrides[parameter.uniform];
    if (value != null)
    {
      values.setValue(parameter: parameter, value: value);
    }
  }
  return values;
}

Future<(Uint8List, int)> _render({required final ExportShaderValues values, required final ui.Image source, required final int scaling}) async
{
  final ui.Image image = await renderExportShaderRegion(
    values: values,
    source: source,
    scaling: scaling,
    region: ExportShaderRegion(x: 0, y: 0, width: source.width * scaling, height: source.height * scaling),
  );
  final ByteData bytes = (await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;
  final int width = image.width;
  image.dispose();
  return (bytes.buffer.asUint8List(), width);
}

List<int> _pixel(final (Uint8List, int) rendered, final int x, final int y)
{
  final int i = (y * rendered.$2 + x) * 4;
  return rendered.$1.sublist(i, i + 4);
}

bool _sameBytes(final Uint8List a, final Uint8List b)
{
  if (a.length != b.length)
  {
    return false;
  }
  for (int i = 0; i < a.length; i++)
  {
    if (a[i] != b[i])
    {
      return false;
    }
  }
  return true;
}

void main()
{
  group("lcd shader", () {
    testWidgets("draws the grid on the trailing edge of every cell", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 2, height: 1, color: (final int x, final int y) => x == 0 ? _red : _transparent);
        final (Uint8List, int) out = await _render(values: _lcd(overrides: <String, Object>{"uGridGray": 0.0}), source: source, scaling: 4);

        expect(_pixel(out, 0, 0), <int>[255, 0, 0, 255]);
        expect(_pixel(out, 2, 2), <int>[255, 0, 0, 255]);
        expect(_pixel(out, 3, 0), <int>[0, 0, 0, 255], reason: "right gap");
        expect(_pixel(out, 0, 3), <int>[0, 0, 0, 255], reason: "bottom gap");
        expect(_pixel(out, 5, 1)[3], 0, reason: "transparent cell stays transparent");
        expect(_pixel(out, 7, 1)[3], 0, reason: "no grid over transparency by default");
        source.dispose();
      });
    });

    testWidgets("puts the grid over transparent cells when asked", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 2, height: 1, color: (final int x, final int y) => x == 0 ? _red : _transparent);
        final (Uint8List, int) out = await _render(values: _lcd(overrides: <String, Object>{"uGridGray": 0.0, "uGridOnTransparency": true}), source: source, scaling: 4);

        expect(_pixel(out, 7, 1), <int>[0, 0, 0, 255]);
        expect(_pixel(out, 5, 1)[3], 0);
        source.dispose();
      });
    });

    testWidgets("applies brightness and blends the grid with hard light", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 1, height: 1, color: (final int x, final int y) => _red);
        Future<List<int>> gap({required final double gray}) async
        {
          final (Uint8List, int) out = await _render(
            values: _lcd(overrides: <String, Object>{"uBrightness": 0.5, "uGridGray": gray}),
            source: source,
            scaling: 4,
          );
          expect(_pixel(out, 1, 1), <int>[128, 0, 0, 255], reason: "the body is the darkened red");
          return _pixel(out, 3, 1);
        }

        final List<int> multiplied = await gap(gray: 0.25);
        expect(multiplied[0], closeTo(64, 1));
        expect(multiplied[1], 0);
        final List<int> neutral = await gap(gray: 0.5);
        expect(neutral.sublist(0, 3), <int>[128, 0, 0]);
        final List<int> screened = await gap(gray: 0.75);
        expect(screened[0], closeTo(191, 1));
        expect(screened[1], closeTo(128, 1));
        expect(screened[2], closeTo(128, 1));
        source.dispose();
      });
    });

    testWidgets("splits the cell into rgb stripes", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 1, height: 1, color: (final int x, final int y) => const ui.Color(0xFFFFFFFF));
        final (Uint8List, int) out = await _render(values: _lcd(overrides: <String, Object>{"uSubpixels": 1.0}), source: source, scaling: 7);

        expect(_pixel(out, 0, 0), <int>[255, 0, 0, 255]);
        expect(_pixel(out, 3, 0), <int>[0, 255, 0, 255]);
        expect(_pixel(out, 5, 0), <int>[0, 0, 255, 255]);
        source.dispose();
      });
    });

    testWidgets("a tiled export matches a single render", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        const int scaling = 7;
        final ui.Image source = await _source(width: 300, height: 4, color: (final int x, final int y) => ui.Color.fromARGB(x % 3 == 0 ? 0 : 255, (x * 7) % 256, (y * 50) % 256, 90));
        expect(source.width * scaling, greaterThan(exportShaderMaxTileSize), reason: "setup: the export has to be tiled");
        final ExportShaderValues values = _lcd(overrides: <String, Object>{"uGridOnTransparency": true, "uSoftness": 0.5});

        final Uint8List png = (await renderExportShaderPng(values: values, source: source, scaling: scaling))!;
        final img.Image decoded = img.decodePng(png)!;
        final (Uint8List, int) single = await _render(values: values, source: source, scaling: scaling);

        expect(decoded.width, source.width * scaling);
        expect(_sameBytes(decoded.getBytes(order: img.ChannelOrder.rgba), single.$1), isTrue);
        source.dispose();
      });
    });
  });

  testWidgets("exports the current frame through the shader to a png file", (final WidgetTester tester) async {
    final Directory exportDir = Directory.systemTemp.createTempSync("kpix_shader_export_test");
    try
    {
      await withProject(tester: tester, canvasSize: CoordinateSetI(x: 4, y: 3), body: (final ProjectSession projectSession) async {
        final String? path = await exportShaderImage(
          exportData: ShaderExportData(
            shaderValues: _lcd(overrides: <String, Object>{"uGridOnTransparency": true}),
            scaling: 5,
            fileName: "shaded",
            directory: exportDir.path,
          ),
        );

        expect(path, p.join(exportDir.path, "shaded.png"));
        final img.Image decoded = img.decodePng(File(path!).readAsBytesSync())!;
        expect(decoded.width, 20);
        expect(decoded.height, 15);
        expect(decoded.getPixel(4, 1).a, 255, reason: "the grid covers the empty canvas");
        expect(decoded.getPixel(1, 1).a, 0);
      },);
    }
    finally
    {
      exportDir.deleteSync(recursive: true);
    }
  });
}
