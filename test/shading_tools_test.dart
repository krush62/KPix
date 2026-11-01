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

import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/models/constraints/tool_shape_constraints.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/stamp_manager_data.dart';
import 'package:kpix/painting/eraser_painter.dart';
import 'package:kpix/painting/line_painter.dart';
import 'package:kpix/painting/pencil_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/painting/shape_painter.dart';
import 'package:kpix/painting/spray_can_painter.dart';
import 'package:kpix/painting/stamp_painter.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/tool_geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/painter_harness.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 12, y: 8);

ShaderOptions get _shader => GetIt.I.get<ShaderOptions>();
ToolOptions get _tools => GetIt.I.get<ToolOptions>();

/// A row the tools below are made to touch, and the same pixels as a map.
final Set<CoordinateSetI> _row = <CoordinateSetI>{for (int x = 2; x <= 6; x++) CoordinateSetI(x: x, y: 3)};

/// One way to touch [_row] with a tool.
class _Tool
{
  final String name;
  final void Function(ShadingLayerState layer) use;
  const _Tool({required this.name, required this.use});
}

final List<_Tool> _rowTools = <_Tool>[
  _Tool(name: "pencil", use: (final ShadingLayerState layer)
  {
    _tools.pencilOptions.size.value = 1;
    _tools.pencilOptions.shape.value = PencilShape.round;
    _tools.pencilOptions.pixelPerfect.value = false;
    dragTool(painter: PencilPainter(painterOptions: testPainterOptions()), layer: layer, path: _row.toList());
  },),
  _Tool(name: "line", use: (final ShadingLayerState layer)
  {
    _tools.lineOptions.width.value = 1;
    final LinePainter painter = LinePainter(painterOptions: testPainterOptions());
    for (final CoordinateSetI at in <CoordinateSetI>[_row.first, _row.last])
    {
      painter.calculate(drawParams: toolParams(layer: layer, cursor: at));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: at, primaryDown: true));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: at));
    }
  },),
  _Tool(name: "shape", use: (final ShadingLayerState layer)
  {
    _tools.shapeOptions.shape.value = DrawingShape.rectangle;
    dragTool(painter: ShapePainter(painterOptions: testPainterOptions()), layer: layer, path: <CoordinateSetI>[_row.first, _row.last]);
  },),
];

void _shadingTest(final String description, final Future<void> Function(ShadingLayerState layer, DrawingLayerState below) body, {final bool skip = false, final bool pixelsBelow = false})
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      final DrawingLayerState below = layerAt(projectSession: projectSession, index: 0);
      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.shading, select: true).$2! as ShadingLayerState;
      shading.settings.shadingStepsPlus.value = 2;
      shading.settings.shadingStepsMinus.value = 2;
      _shader.shaderDirection.value = ShaderDirection.right;
      if (pixelsBelow)
      {
        below.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{for (final CoordinateSetI coord in _row) coord: GetIt.I.get<PaletteState>().colorRamps[0].references[1]}));
      }
      await settle();
      await body(shading, below);
    },);
  }, skip: skip,);
}

Map<CoordinateSetI, int> _all({required final Iterable<CoordinateSetI> coords, required final int value})
{
  return <CoordinateSetI, int>{for (final CoordinateSetI coord in coords) coord: value};
}

void main()
{
  for (final _Tool tool in _rowTools)
  {
    group(tool.name, ()
    {
      _shadingTest("brightens what it touches and leaves the layer below alone", (final ShadingLayerState layer, final DrawingLayerState below) async
      {
        tool.use(layer);
        await settle();

        expect(shadesOf(layer: layer), _all(coords: _row, value: 1));
        expect(colorsOf(layer: below).values.toSet(), <ColorReference>{GetIt.I.get<PaletteState>().colorRamps[0].references[1]});
      }, pixelsBelow: true,);

      _shadingTest("darkens the other way", (final ShadingLayerState layer, final DrawingLayerState below) async
      {
        _shader.shaderDirection.value = ShaderDirection.left;

        tool.use(layer);
        await settle();

        expect(shadesOf(layer: layer), _all(coords: _row, value: -1));
      }, pixelsBelow: true,);

      _shadingTest("adds up and stops at the limit of the layer", (final ShadingLayerState layer, final DrawingLayerState below) async
      {
        for (int i = 0; i < 4; i++)
        {
          tool.use(layer);
          await settle();
        }

        expect(shadesOf(layer: layer), _all(coords: _row, value: 2));
      }, pixelsBelow: true,);

      _shadingTest("removes what comes back to zero", (final ShadingLayerState layer, final DrawingLayerState below) async
      {
        tool.use(layer);
        await settle();
        _shader.shaderDirection.value = ShaderDirection.left;

        tool.use(layer);
        await settle();

        expect(shadesOf(layer: layer), isEmpty);
      }, pixelsBelow: true,);

      _shadingTest("does nothing on a locked layer", (final ShadingLayerState layer, final DrawingLayerState below) async
      {
        layer.lockState.value = LayerLockState.locked;

        tool.use(layer);
        await settle();

        expect(shadesOf(layer: layer), isEmpty);
      }, pixelsBelow: true,);

      _shadingTest("does nothing on a hidden layer", (final ShadingLayerState layer, final DrawingLayerState below) async
      {
        layer.visibilityState.value = LayerVisibilityState.hidden;

        tool.use(layer);
        await settle();

        expect(shadesOf(layer: layer), isEmpty);
      }, pixelsBelow: true,);
    });
  }

  group("with nothing below", ()
  {
    for (final _Tool tool in _rowTools.where((final _Tool t) => t.name != "shape"))
    {
      _shadingTest("the ${tool.name} still shades, for what is drawn there later", (final ShadingLayerState layer, final DrawingLayerState below) async
      {
        tool.use(layer);
        await settle();

        expect(shadesOf(layer: layer), _all(coords: _row, value: 1));
      });
    }

    //BUG: skipped until fixed, the shape tool only commits when its preview holds
    //pixels, and the preview of a shading layer over nothing is empty
    _shadingTest("the shape still shades, for what is drawn there later", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      _rowTools.firstWhere((final _Tool t) => t.name == "shape").use(layer);
      await settle();

      expect(shadesOf(layer: layer), _all(coords: _row, value: 1));
    }, skip: true,);
  });

  group("pencil", ()
  {
    _shadingTest("is an undo step", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      _tools.pencilOptions.size.value = 1;
      final PencilPainter painter = PencilPainter(painterOptions: testPainterOptions());

      dragTool(painter: painter, layer: layer, path: _row.toList());
      await settle();

      expect(painter.hasHistoryData, isTrue);
    });

    _shadingTest("draws a straight line with shift, from where it stopped", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      _tools.pencilOptions.size.value = 1;
      final PencilPainter painter = PencilPainter(painterOptions: testPainterOptions());
      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 2, y: 3)]);
      await settle();

      GetIt.I.get<HotkeyManager>().shiftNotifier.value = true;
      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 6, y: 3)]);
      GetIt.I.get<HotkeyManager>().shiftNotifier.value = false;
      await settle();

      expect(shadesOf(layer: layer).keys.toSet(), _row);
    });
  });

  group("eraser", ()
  {
    _shadingTest("takes values away, whichever way they went", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      layer.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{CoordinateSetI(x: 2, y: 3): 1, CoordinateSetI(x: 3, y: 3): -2, CoordinateSetI(x: 8, y: 3): 1}));
      await settle();
      _tools.eraserOptions.size.value = 1;
      final EraserPainter painter = EraserPainter(painterOptions: testPainterOptions());

      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 2, y: 3), CoordinateSetI(x: 3, y: 3), CoordinateSetI(x: 4, y: 3)]);
      await settle();

      expect(shadesOf(layer: layer), <CoordinateSetI, int>{CoordinateSetI(x: 8, y: 3): 1});
      expect(painter.hasHistoryData, isTrue);
    });

    _shadingTest("does nothing on a locked layer", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      layer.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{CoordinateSetI(x: 2, y: 3): 1}));
      await settle();
      layer.lockState.value = LayerLockState.locked;
      _tools.eraserOptions.size.value = 1;

      dragTool(painter: EraserPainter(painterOptions: testPainterOptions()), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 2, y: 3)]);
      await settle();

      expect(shadesOf(layer: layer), hasLength(1));
    });
  });

  group("spray can", ()
  {
    _shadingTest("shades around the cursor and nowhere else", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      _tools.sprayCanOptions.radius.value = 2;
      _tools.sprayCanOptions.blobSize.value = 1;
      _tools.sprayCanOptions.intensity.value = 50;
      final CoordinateSetI center = CoordinateSetI(x: 6, y: 4);
      final SprayCanPainter painter = SprayCanPainter(painterOptions: testPainterOptions());
      painter.calculate(drawParams: toolParams(layer: layer, cursor: center));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: center, primaryDown: true));
      //the can sprays on a timer while it is held
      await Future<void>.delayed(const Duration(milliseconds: 120));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: center, primaryDown: true));
      painter.calculate(drawParams: toolParams(layer: layer, cursor: center));
      await settle();

      final Map<CoordinateSetI, int> shades = shadesOf(layer: layer);
      expect(shades, isNotEmpty);
      expect(painter.hasHistoryData, isTrue);
      for (final MapEntry<CoordinateSetI, int> shade in shades.entries)
      {
        expect((shade.key.x - center.x).abs(), lessThanOrEqualTo(3), reason: "${shade.key}");
        expect((shade.key.y - center.y).abs(), lessThanOrEqualTo(3), reason: "${shade.key}");
        expect(shade.value, greaterThan(0));
      }
    });
  });

  group("stamp", ()
  {
    /// A stamp of two pixels, the second one lighter by [lighter].
    void selectStamp({final int lighter = 1})
    {
      if (!GetIt.I.isRegistered<StampManager>())
      {
        GetIt.I.registerSingleton<StampManager>(StampManager());
      }
      GetIt.I.get<StampManager>().selectedStamp.value = StampManagerEntryData(
        path: "",
        thumbnail: null,
        name: "stamp",
        isLocked: false,
        data: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{CoordinateSetI(x: 0, y: 0): 0, CoordinateSetI(x: 1, y: 0): lighter}),
        width: 2,
        height: 1,
      );
    }

    _shadingTest("adds the stamp's own steps to the direction", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      selectStamp();
      final CoordinateSetI at = CoordinateSetI(x: 6, y: 4);
      final StampPainter painter = StampPainter(painterOptions: testPainterOptions());

      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[at]);
      await settle();

      expect(shadesOf(layer: layer), <CoordinateSetI, int>{CoordinateSetI(x: 4, y: 3): 1, CoordinateSetI(x: 5, y: 3): 2});
      expect(painter.hasHistoryData, isTrue);
    });

    _shadingTest("goes the other way and stops at the limit", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      selectStamp(lighter: 3);
      _shader.shaderDirection.value = ShaderDirection.left;

      dragTool(painter: StampPainter(painterOptions: testPainterOptions()), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 6, y: 4)]);
      await settle();

      expect(shadesOf(layer: layer), <CoordinateSetI, int>{CoordinateSetI(x: 4, y: 3): -1, CoordinateSetI(x: 5, y: 3): -2});
    });

    _shadingTest("removes what comes back to zero", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      selectStamp();
      final CoordinateSetI at = CoordinateSetI(x: 6, y: 4);
      dragTool(painter: StampPainter(painterOptions: testPainterOptions()), layer: layer, path: <CoordinateSetI>[at]);
      await settle();
      _shader.shaderDirection.value = ShaderDirection.left;

      dragTool(painter: StampPainter(painterOptions: testPainterOptions()), layer: layer, path: <CoordinateSetI>[at]);
      await settle();

      expect(shadesOf(layer: layer), isEmpty);
    });

    _shadingTest("does nothing on a locked layer", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      selectStamp();
      layer.lockState.value = LayerLockState.locked;

      dragTool(painter: StampPainter(painterOptions: testPainterOptions()), layer: layer, path: <CoordinateSetI>[CoordinateSetI(x: 6, y: 4)]);
      await settle();

      expect(shadesOf(layer: layer), isEmpty);
    });

    _shadingTest("the preview shows the same as the draw", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      selectStamp();
      final List<ColorReference> ramp = GetIt.I.get<PaletteState>().colorRamps[0].references;
      below.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 4, y: 3): ramp[1], CoordinateSetI(x: 5, y: 3): ramp[1]}));
      await settle();
      final StampPainter painter = StampPainter(painterOptions: testPainterOptions());

      final CoordinateColorMap preview = painter.getStampPixelsToDrawForShading(
        canvasSize: _canvasSize,
        currentLayer: layer,
        stampData: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{CoordinateSetI(x: 4, y: 3): 0, CoordinateSetI(x: 5, y: 3): 1, CoordinateSetI(x: 6, y: 3): 0}),
        shaderOptions: _shader,
      );

      expect(preview, <CoordinateSetI, ColorReference>{CoordinateSetI(x: 4, y: 3): ramp[2], CoordinateSetI(x: 5, y: 3): ramp[3]}, reason: "nothing below to preview at the third pixel");
    });

    //BUG: skipped until fixed, the stamp preview asks for hidden layers to be included,
    //unlike every other tool, so it shows pixels that are not on the canvas
    _shadingTest("the preview leaves out hidden layers", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      final List<ColorReference> ramp = GetIt.I.get<PaletteState>().colorRamps[0].references;
      below.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 4, y: 3): ramp[1]}));
      below.visibilityState.value = LayerVisibilityState.hidden;
      await settle();
      final StampPainter painter = StampPainter(painterOptions: testPainterOptions());

      final CoordinateColorMap preview = painter.getStampPixelsToDrawForShading(canvasSize: _canvasSize, currentLayer: layer, stampData: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{CoordinateSetI(x: 4, y: 3): 0}), shaderOptions: _shader);

      expect(preview, isEmpty);
    }, skip: true,);
  });

  group("what a tool previews on a shading layer", ()
  {
    /// The preview for [coords], asked for the way the tools ask for it.
    CoordinateColorMap preview({required final ShadingLayerState layer, required final Set<CoordinateSetI> coords})
    {
      return ShapePainter(painterOptions: testPainterOptions()).getPixelsToDrawForShading(canvasSize: _canvasSize, currentLayer: layer, coords: coords, shaderOptions: _shader);
    }

    _shadingTest("is the color below, one step along", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      final List<ColorReference> ramp = GetIt.I.get<PaletteState>().colorRamps[0].references;
      final CoordinateSetI spot = CoordinateSetI(x: 4, y: 3);
      below.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{spot: ramp[1]}));
      await settle();

      expect(preview(layer: layer, coords: <CoordinateSetI>{spot, CoordinateSetI(x: 5, y: 3), CoordinateSetI(x: 40, y: 40)}), <CoordinateSetI, ColorReference>{spot: ramp[2]}, reason: "nothing to shade next to it, and off the canvas");
    });

    _shadingTest("does not move past the limit of the layer or the end of the ramp", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      final List<ColorReference> ramp = GetIt.I.get<PaletteState>().colorRamps[0].references;
      final CoordinateSetI atLimit = CoordinateSetI(x: 4, y: 3);
      final CoordinateSetI atEnd = CoordinateSetI(x: 5, y: 3);
      below.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{atLimit: ramp[0], atEnd: ramp.last}));
      layer.addCoords(coords: HashMap<CoordinateSetI, int>.of(<CoordinateSetI, int>{atLimit: 2}));
      await settle();

      expect(preview(layer: layer, coords: <CoordinateSetI>{atLimit, atEnd}), <CoordinateSetI, ColorReference>{atLimit: ramp[2], atEnd: ramp.last});
    });

    _shadingTest("is nothing on a locked layer", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      below.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 4, y: 3): GetIt.I.get<PaletteState>().colorRamps[0].references[1]}));
      layer.lockState.value = LayerLockState.locked;
      await settle();

      expect(preview(layer: layer, coords: <CoordinateSetI>{CoordinateSetI(x: 4, y: 3)}), isEmpty);
    });

    _shadingTest("leaves out hidden layers", (final ShadingLayerState layer, final DrawingLayerState below) async
    {
      below.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{CoordinateSetI(x: 4, y: 3): GetIt.I.get<PaletteState>().colorRamps[0].references[1]}));
      below.visibilityState.value = LayerVisibilityState.hidden;
      await settle();

      expect(preview(layer: layer, coords: <CoordinateSetI>{CoordinateSetI(x: 4, y: 3)}), isEmpty);
    });
  });

  group("on a dither layer", ()
  {
    testWidgets("a tool stores its steps and only previews what the pattern changes", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
      {
        final DrawingLayerState below = layerAt(projectSession: projectSession, index: 0);
        final List<ColorReference> ramp = GetIt.I.get<PaletteState>().colorRamps[0].references;
        below.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{for (final CoordinateSetI coord in _row) coord: ramp[1]}));
        final DitherLayerState dither = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.dither, select: true).$2! as DitherLayerState;
        _shader.shaderDirection.value = ShaderDirection.right;
        await settle();
        final ShapePainter painter = ShapePainter(painterOptions: testPainterOptions());

        final CoordinateColorMap preview = painter.getPixelsToDrawForShading(canvasSize: _canvasSize, currentLayer: dither, coords: _row, shaderOptions: _shader);
        _tools.lineOptions.width.value = 1;
        final LinePainter line = LinePainter(painterOptions: testPainterOptions());
        for (final CoordinateSetI at in <CoordinateSetI>[_row.first, _row.last])
        {
          line.calculate(drawParams: toolParams(layer: dither, cursor: at));
          line.calculate(drawParams: toolParams(layer: dither, cursor: at, primaryDown: true));
          line.calculate(drawParams: toolParams(layer: dither, cursor: at));
        }
        await settle();

        expect(shadesOf(layer: dither), _all(coords: _row, value: 1));
        for (final CoordinateSetI coord in _row)
        {
          expect(preview.containsKey(coord), dither.getDisplayValueAt(coord: coord) != 0, reason: "$coord");
        }
      },);
    });
  });
}
