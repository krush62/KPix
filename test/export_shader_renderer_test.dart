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
import 'dart:math';
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
  for (final ExportShaderParameter parameter in values.variant.parameters)
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

ExportShaderValues _upscale({required final String variant})
{
  final ExportShaderValues values = ExportShaderValues(definition: exportShaderDefinitions[ExportShaderType.upscale]!);
  values.variantIndex = values.definition.variants.indexWhere((final ExportShaderVariant v) => v.name == variant);
  return values;
}

ExportShaderValues _relief({final Map<String, Object> overrides = const <String, Object>{}})
{
  return _effect(variant: "Relief", overrides: overrides);
}

ExportShaderValues _effect({required final String variant, final Map<String, Object> overrides = const <String, Object>{}})
{
  final ExportShaderDefinition definition = exportShaderDefinitions[ExportShaderType.effects]!;
  final ExportShaderValues values = ExportShaderValues(definition: definition);
  values.variantIndex = definition.variants.indexWhere((final ExportShaderVariant v) => v.name == variant);
  for (final ExportShaderParameter parameter in values.variant.parameters)
  {
    final Object? value = overrides[parameter.uniform];
    if (value != null)
    {
      values.setValue(parameter: parameter, value: value);
    }
  }
  return values;
}

/// The largest difference of any channel of any pixel from [color].
int _maxDeviation({required final Uint8List rgba, required final List<int> color})
{
  int deviation = 0;
  for (int i = 0; i < rgba.length; i++)
  {
    deviation = max(deviation, (rgba[i] - color[i % 4]).abs());
  }
  return deviation;
}

/// How many output pixels differ from plain pixel repetition of [sourceColor].
int _differentFromNearest({required final (Uint8List, int) rendered, required final int scaling, required final List<int> Function(int x, int y) sourceColor})
{
  int count = 0;
  final int height = rendered.$1.length ~/ (rendered.$2 * 4);
  for (int y = 0; y < height; y++)
  {
    for (int x = 0; x < rendered.$2; x++)
    {
      final List<int> expected = sourceColor(x ~/ scaling, y ~/ scaling);
      final List<int> actual = _pixel(rendered, x, y);
      for (int c = 0; c < 4; c++)
      {
        if ((expected[c] - actual[c]).abs() > 8)
        {
          count++;
          break;
        }
      }
    }
  }
  return count;
}

double _meanBrightness(final Uint8List rgba)
{
  int sum = 0;
  for (int i = 0; i < rgba.length; i += 4)
  {
    sum += rgba[i] + rgba[i + 1] + rgba[i + 2];
  }
  return sum / (rgba.length / 4 * 3);
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

  group("upscale shader", () {
    const ui.Color blue = ui.Color(0xFF3366CC);
    List<int> staircase(final int x, final int y) => x > y ? <int>[255, 255, 255, 255] : <int>[0, 0, 0, 255];

    for (final String variant in <String>["OmniScale", "xBR", "xBRZ", "CleanEdge"])
    {
      testWidgets("$variant keeps a single color as it is", (final WidgetTester tester) async {
        await tester.runAsync(() async {
          final ui.Image source = await _source(width: 4, height: 3, color: (final int x, final int y) => blue);
          final (Uint8List, int) out = await _render(values: _upscale(variant: variant), source: source, scaling: 3);

          expect(out.$2, 12);
          expect(_maxDeviation(rgba: out.$1, color: <int>[0x33, 0x66, 0xCC, 0xFF]), lessThanOrEqualTo(1));
          source.dispose();
        });
      });

      testWidgets("$variant smooths a diagonal staircase", (final WidgetTester tester) async {
        await tester.runAsync(() async {
          final ui.Image source = await _source(width: 6, height: 6, color: (final int x, final int y) {
            final List<int> c = staircase(x, y);
            return ui.Color.fromARGB(c[3], c[0], c[1], c[2]);
          },);
          final (Uint8List, int) out = await _render(values: _upscale(variant: variant), source: source, scaling: 4);

          expect(_differentFromNearest(rendered: out, scaling: 4, sourceColor: staircase), greaterThan(0));
          source.dispose();
        });
      });

      testWidgets("$variant keeps transparent areas transparent", (final WidgetTester tester) async {
        await tester.runAsync(() async {
          final ui.Image source = await _source(width: 6, height: 6, color: (final int x, final int y) => x > y ? _red : _transparent);
          final (Uint8List, int) out = await _render(values: _upscale(variant: variant), source: source, scaling: 4);

          expect(_pixel(out, 2, 20)[3], 0, reason: "far inside the transparent half");
          expect(_pixel(out, 20, 2), <int>[255, 0, 0, 255], reason: "far inside the red half");
          source.dispose();
        });
      });
    }

    testWidgets("a tiled upscale export matches a single render", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        const int scaling = 7;
        final ui.Image source = await _source(width: 300, height: 4, color: (final int x, final int y) => ui.Color.fromARGB(255, (x * 7) % 256, (y * 50) % 256, (x * 3) % 256));
        expect(source.width * scaling, greaterThan(exportShaderMaxTileSize), reason: "setup: the export has to be tiled");
        final ExportShaderValues values = _upscale(variant: "xBRZ");

        final Uint8List png = (await renderExportShaderPng(values: values, source: source, scaling: scaling))!;
        final img.Image decoded = img.decodePng(png)!;
        final (Uint8List, int) single = await _render(values: values, source: source, scaling: scaling);

        expect(_sameBytes(decoded.getBytes(order: img.ChannelOrder.rgba), single.$1), isTrue);
        source.dispose();
      });
    });
  });

  group("relief shader", () {
    testWidgets("leaves flat areas as they are", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 3, height: 3, color: (final int x, final int y) => const ui.Color(0xFF3366CC));
        final (Uint8List, int) out = await _render(values: _relief(), source: source, scaling: 8);

        expect(_maxDeviation(rgba: out.$1, color: <int>[0x33, 0x66, 0xCC, 0xFF]), lessThanOrEqualTo(1));
        source.dispose();
      });
    });

    testWidgets("lights the bevels facing the light and shades the others", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        //a raised grey pixel on transparency, lit from the left
        final ui.Image source = await _source(width: 3, height: 3, color: (final int x, final int y) => x == 1 && y == 1 ? const ui.Color(0xFF808080) : _transparent);
        final (Uint8List, int) out = await _render(values: _relief(overrides: <String, Object>{"uBrightnessInfluence": 0.0, "uLightAngle": 180.0}), source: source, scaling: 8);

        expect(_pixel(out, 8, 12)[0], greaterThan(150), reason: "left bevel faces the light");
        expect(_pixel(out, 15, 12)[0], lessThan(100), reason: "right bevel faces away");
        expect(_pixel(out, 12, 12)[0], closeTo(128, 1), reason: "flat top keeps its color");
        expect(_pixel(out, 4, 12)[3], 0, reason: "transparent stays transparent");
        source.dispose();
      });
    });
  });

  group("cel shading shader", () {
    testWidgets("keeps the original color of flat areas, without outlines", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 3, height: 3, color: (final int x, final int y) => const ui.Color(0xFF3366CC));
        final (Uint8List, int) out = await _render(values: _effect(variant: "Cel Shading"), source: source, scaling: 8);

        expect(_maxDeviation(rgba: out.$1, color: <int>[0x33, 0x66, 0xCC, 0xFF]), lessThanOrEqualTo(1));
        source.dispose();
      });
    });

    testWidgets("turns grey without saturation", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 1, height: 1, color: (final int x, final int y) => const ui.Color(0xFF3366CC));
        final (Uint8List, int) out = await _render(values: _effect(variant: "Cel Shading", overrides: <String, Object>{"uSaturation": 0.0}), source: source, scaling: 4);

        final List<int> grey = _pixel(out, 2, 2);
        expect(grey[0], closeTo(grey[1], 1));
        expect(grey[1], closeTo(grey[2], 1));
        source.dispose();
      });
    });

    testWidgets("keeps shades of one hue in one cell, but outlines another hue", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        //dark red, red, green
        const List<ui.Color> colors = <ui.Color>[ui.Color(0xFFA01818), ui.Color(0xFFE02020), ui.Color(0xFF20C020)];
        final ui.Image source = await _source(width: 3, height: 1, color: (final int x, final int y) => colors[x]);
        final (Uint8List, int) out = await _render(values: _effect(variant: "Cel Shading"), source: source, scaling: 8);

        expect(_pixel(out, 7, 4), <int>[0xA0, 0x18, 0x18, 0xFF], reason: "no line between the two reds");
        expect(_pixel(out, 15, 4), <int>[0, 0, 0, 255], reason: "a line between red and green, in the darker red");
        source.dispose();
      });
    });

    testWidgets("draws one sharp black line into the darker cell", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 2, height: 1, color: (final int x, final int y) => x == 0 ? const ui.Color(0xFFE0E0E0) : const ui.Color(0xFF3366CC));
        final (Uint8List, int) out = await _render(values: _effect(variant: "Cel Shading"), source: source, scaling: 8);

        expect(_pixel(out, 8, 4), <int>[0, 0, 0, 255], reason: "first column of the darker blue cell");
        expect(_pixel(out, 7, 4), _pixel(out, 3, 4), reason: "the light cell keeps its color up to the edge");
        expect(_pixel(out, 9, 4), _pixel(out, 12, 4), reason: "the line is one pixel wide");
        source.dispose();
      });
    });

    testWidgets("makes the line as wide as the outline width", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 2, height: 1, color: (final int x, final int y) => x == 0 ? const ui.Color(0xFFE0E0E0) : const ui.Color(0xFF3366CC));
        final (Uint8List, int) out = await _render(values: _effect(variant: "Cel Shading", overrides: <String, Object>{"uOutlineWidth": 3.0}), source: source, scaling: 8);

        expect(_pixel(out, 10, 4), <int>[0, 0, 0, 255]);
        expect(_pixel(out, 11, 4), _pixel(out, 13, 4));
        source.dispose();
      });
    });

    testWidgets("puts similar colors into one cell below the threshold", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 2, height: 1, color: (final int x, final int y) => x == 0 ? const ui.Color(0xFF808080) : const ui.Color(0xFF8C8C8C));
        final (Uint8List, int) similar = await _render(values: _effect(variant: "Cel Shading"), source: source, scaling: 8);
        final (Uint8List, int) exact = await _render(values: _effect(variant: "Cel Shading", overrides: <String, Object>{"uThreshold": 0.0}), source: source, scaling: 8);

        expect(_pixel(similar, 7, 4), _pixel(similar, 3, 4), reason: "no line with the default threshold");
        expect(_pixel(exact, 7, 4), <int>[0, 0, 0, 255], reason: "a line when the colors have to match exactly");
        source.dispose();
      });
    });

    testWidgets("keeps black black and transparency transparent", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 2, height: 1, color: (final int x, final int y) => x == 0 ? const ui.Color(0xFF000000) : _transparent);
        final (Uint8List, int) out = await _render(values: _effect(variant: "Cel Shading"), source: source, scaling: 8);

        expect(_pixel(out, 3, 4), <int>[0, 0, 0, 255]);
        expect(_pixel(out, 12, 4)[3], 0);
        source.dispose();
      });
    });
  });

  group("choice parameters", () {
    testWidgets("the Bayer options reach the shader as levels 1 to 4", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        //at 1 bit and this gray only the highest threshold(s) of each matrix switch a pixel on, so the output repeats with the matrix size
        final ui.Image source = await _source(width: 32, height: 32, color: (final int x, final int y) => const ui.Color(0xFF454545));
        final ExportShaderDefinition definition = exportShaderDefinitions[ExportShaderType.dithering]!;
        int period(final (Uint8List, int) out)
        {
          for (final int p in <int>[1, 2, 4, 8, 16])
          {
            bool repeats = true;
            for (int y = 0; y < 32 - p && repeats; y++)
            {
              for (int x = 0; x < 32 - p && repeats; x++)
              {
                final int c = _pixel(out, x, y)[0];
                repeats = c == _pixel(out, x + p, y)[0] && c == _pixel(out, x, y + p)[0];
              }
            }
            if (repeats)
            {
              return p;
            }
          }
          return -1;
        }

        final List<int> periods = <int>[];
        for (int option = 0; option < 4; option++)
        {
          final ExportShaderValues values = ExportShaderValues(definition: definition);
          values.variantIndex = definition.variants.indexWhere((final ExportShaderVariant v) => v.name == "Bayer");
          for (final ExportShaderParameter parameter in values.variant.parameters)
          {
            if (parameter.uniform == "uBayerLevel")
            {
              values.setValue(parameter: parameter, value: option);
            }
            else if (parameter.uniform == "uColorDepth")
            {
              values.setValue(parameter: parameter, value: 1.0);
            }
          }
          periods.add(period(await _render(values: values, source: source, scaling: 1)));
        }

        expect(periods, <int>[2, 4, 8, 16]);
        source.dispose();
      });
    });

    testWidgets("every dot shape draws different dots", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 4, height: 4, color: (final int x, final int y) => const ui.Color(0xFF8040C0));
        final List<Uint8List> shapes = <Uint8List>[
          for (int shape = 0; shape < 3; shape++)
            (await _render(values: _effect(variant: "CMYK/Halftone", overrides: <String, Object>{"uDotShape": shape}), source: source, scaling: 8)).$1,
        ];

        expect(_sameBytes(shapes[0], shapes[1]), isFalse);
        expect(_sameBytes(shapes[1], shapes[2]), isFalse);
        expect(_sameBytes(shapes[0], shapes[2]), isFalse);
        source.dispose();
      });
    });
  });

  group("crt shader", () {
    const Map<String, Object> allOff = <String, Object>{
      "uMedium": 0, "uSignal": 0, "uArtifacts": 0.0, "uNoise": 0.0, "uGhosting": 0.0, "uEncoding": 0, "uPhaseError": 0.0, "uSharpness": 0.0,
      "uConvergence": 0.0, "uScanlines": 0.0, "uMask": 0, "uBloom": 0.0, "uCurvature": 0.0, "uVignette": 0.0, "uBrightness": 1.0,
    };
    ExportShaderValues crt(final Map<String, Object> overrides)
    {
      final ExportShaderValues values = ExportShaderValues(definition: exportShaderDefinitions[ExportShaderType.crt]!);
      for (final ExportShaderParameter parameter in values.variant.parameters)
      {
        final Object? value = overrides[parameter.uniform] ?? allOff[parameter.uniform];
        if (value != null)
        {
          values.setValue(parameter: parameter, value: value);
        }
      }
      return values;
    }
    ui.Color colorful(final int x, final int y) => <ui.Color>[const ui.Color(0xFFE04030), const ui.Color(0xFF30C040), const ui.Color(0xFF3060E0), const ui.Color(0xFFF0F0F0), const ui.Color(0xFF101010)][(x + 2 * y) % 5];

    testWidgets("with every stage switched off, it is plain pixel scaling", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 8, height: 6, color: colorful);
        final (Uint8List, int) out = await _render(values: crt(<String, Object>{}), source: source, scaling: 4);

        int maxDiff = 0;
        for (int y = 0; y < 24; y++)
        {
          for (int x = 0; x < 32; x++)
          {
            final ui.Color c = colorful(x ~/ 4, y ~/ 4);
            final List<int> p = _pixel(out, x, y);
            maxDiff = max(maxDiff, max((p[0] - (c.r * 255).round()).abs(), max((p[1] - (c.g * 255).round()).abs(), (p[2] - (c.b * 255).round()).abs())));
          }
        }
        expect(maxDiff, lessThanOrEqualTo(1));
        source.dispose();
      });
    });

    //each stage against the same chain without it
    const Map<String, Object> sVideo = <String, Object>{"uSignal": 1};
    const Map<String, Object> composite = <String, Object>{"uSignal": 2};
    final Map<String, (Map<String, Object>, Map<String, Object>)> stages = <String, (Map<String, Object>, Map<String, Object>)>{
      "VHS": (const <String, Object>{}, <String, Object>{"uMedium": 1, "uWear": 0.5}),
      "Betamax": (const <String, Object>{}, <String, Object>{"uMedium": 2, "uWear": 0.5}),
      "Video8": (const <String, Object>{}, <String, Object>{"uMedium": 3, "uWear": 0.5}),
      "S-Video": (const <String, Object>{}, sVideo),
      "composite artifacts": (composite, <String, Object>{"uSignal": 2, "uArtifacts": 0.5}),
      "RF": (composite, <String, Object>{"uSignal": 3}),
      "noise": (const <String, Object>{}, <String, Object>{"uNoise": 0.5}),
      "ghosting": (const <String, Object>{}, <String, Object>{"uGhosting": 0.5}),
      "NTSC phase error": (sVideo, <String, Object>{"uSignal": 1, "uPhaseError": 20.0}),
      "PAL": (sVideo, <String, Object>{"uSignal": 1, "uEncoding": 1}),
      "sharpness": (const <String, Object>{}, <String, Object>{"uSharpness": 0.5}),
      "convergence": (const <String, Object>{}, <String, Object>{"uConvergence": 0.5}),
      "scanlines": (const <String, Object>{}, <String, Object>{"uScanlines": 0.5}),
      "mask": (const <String, Object>{}, <String, Object>{"uMask": 1, "uMaskStrength": 0.5}),
      "bloom": (const <String, Object>{}, <String, Object>{"uBloom": 0.5}),
      "curvature": (const <String, Object>{}, <String, Object>{"uCurvature": 0.5}),
      "vignette": (const <String, Object>{}, <String, Object>{"uVignette": 0.5}),
      "brightness": (const <String, Object>{}, <String, Object>{"uBrightness": 1.5}),
    };
    for (final MapEntry<String, (Map<String, Object>, Map<String, Object>)> stage in stages.entries)
    {
      testWidgets("${stage.key} changes the image on its own", (final WidgetTester tester) async {
        await tester.runAsync(() async {
          final ui.Image source = await _source(width: 8, height: 6, color: colorful);
          final (Uint8List, int) off = await _render(values: crt(stage.value.$1), source: source, scaling: 4);
          final (Uint8List, int) on = await _render(values: crt(stage.value.$2), source: source, scaling: 4);

          expect(_sameBytes(off.$1, on.$1), isFalse);
          source.dispose();
        });
      });
    }

    testWidgets("composite artifacts appear at color edges only, never on a plain area", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 24, height: 4, color: (final int x, final int y) => const ui.Color(0xFFE04030));
        final List<Map<String, Object>> chains = <Map<String, Object>>[
          composite,
          <String, Object>{"uSignal": 3},
          <String, Object>{"uSignal": 2, "uEncoding": 1},
        ];
        for (final Map<String, Object> chain in chains)
        {
          final (Uint8List, int) out = await _render(values: crt(<String, Object>{...chain, "uArtifacts": 1.0}), source: source, scaling: 4);
          //source columns 8..15 are out of reach of the picture border
          final List<int> reference = _pixel(out, 48, 8);
          int maxDiff = 0;
          for (int y = 4; y < 16; y++)
          {
            for (int x = 32; x < 64; x++)
            {
              final List<int> p = _pixel(out, x, y);
              maxDiff = max(maxDiff, max((p[0] - reference[0]).abs(), max((p[1] - reference[1]).abs(), (p[2] - reference[2]).abs())));
            }
          }
          expect(maxDiff, 0, reason: "$chain");
        }
        source.dispose();
      });
    });

    testWidgets("VHS takes color away from plain areas, Betamax much less", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 16, height: 8, color: (final int x, final int y) => const ui.Color(0xFF3060E0));
        double saturation(final (Uint8List, int) out)
        {
          double sum = 0;
          for (int y = 4; y < 20; y++)
          {
            for (int x = 16; x < 48; x++)
            {
              final List<int> p = _pixel(out, x, y);
              sum += max(p[0], max(p[1], p[2])) - min(p[0], min(p[1], p[2]));
            }
          }
          return sum / (16 * 32);
        }
        final double off = saturation(await _render(values: crt(<String, Object>{}), source: source, scaling: 4));
        final double vhs = saturation(await _render(values: crt(<String, Object>{"uMedium": 1, "uWear": 0.5}), source: source, scaling: 4));
        final double betamax = saturation(await _render(values: crt(<String, Object>{"uMedium": 2, "uWear": 0.5}), source: source, scaling: 4));

        expect(vhs, lessThan(off * 0.85));
        expect(betamax, greaterThan(off * 0.9));
        source.dispose();
      });
    });

    testWidgets("keeps the average brightness with the default settings", (final WidgetTester tester) async {
      await tester.runAsync(() async {
        final ui.Image source = await _source(width: 8, height: 6, color: colorful);
        final (Uint8List, int) off = await _render(values: crt(<String, Object>{}), source: source, scaling: 4);
        final (Uint8List, int) standard = await _render(values: ExportShaderValues(definition: exportShaderDefinitions[ExportShaderType.crt]!), source: source, scaling: 4);

        expect(_meanBrightness(standard.$1), closeTo(_meanBrightness(off.$1), _meanBrightness(off.$1) * 0.1));
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
