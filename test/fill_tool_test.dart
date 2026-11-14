/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/painting/fill_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/fill_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/painter_harness.dart';
import 'support/selection_harness.dart';

final CoordinateSetI _canvasSize = CoordinateSetI(x: 6, y: 4);
final CoordinateSetI _left = CoordinateSetI(x: 0, y: 1);
final CoordinateSetI _right = CoordinateSetI(x: 5, y: 2);

FillOptions get _options => GetIt.I.get<ToolOptions>().fillOptions;
ShaderOptions get _shader => GetIt.I.get<ShaderOptions>();
List<KPalRampData> get _ramps => GetIt.I.get<PaletteState>().colorRamps;

FillPainter _painter() => FillPainter(painterOptions: testPainterOptions());

/// Fills from [at] across the whole canvas, not only what is adjacent.
Future<void> _fill({required final FillPainter painter, required final LayerState layer, required final CoordinateSetI at}) async
{
  _options.fillAdjacent.value = false;
  dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[at]);
  await settle();
}

Set<CoordinateSetI> _everyPixel()
{
  return <CoordinateSetI>{
    for (int x = 0; x < _canvasSize.x; x++)
      for (int y = 0; y < _canvasSize.y; y++) CoordinateSetI(x: x, y: y),
  };
}

void _fillTest(final String description, final Future<void> Function(DrawingLayerState layer) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      await body(layerAt(projectSession: projectSession, index: 0));
    },);
  });
}

void _shadingFillTest(final String description, final Future<void> Function(ShadingLayerState layer) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: _canvasSize, body: (final ProjectSession projectSession) async
    {
      final ShadingLayerState shading = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.shading, select: true).$2! as ShadingLayerState;
      shading.settings.shadingStepsPlus.value = 3;
      shading.settings.shadingStepsMinus.value = 3;
      await settle();
      await body(shading);
    },);
  });
}

void main()
{
  group("filling across the canvas", ()
  {
    _fillTest("colors an empty layer completely and is an undo step", (final DrawingLayerState layer) async
    {
      final FillPainter painter = _painter();
      final ColorReference color = GetIt.I.get<PaletteState>().selectedColor!;

      await _fill(painter: painter, layer: layer, at: _left);

      expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{for (final CoordinateSetI coord in _everyPixel()) coord: color});
      expect(painter.hasHistoryData, isTrue);
      expect(painter.historyIdentifier, HistoryStateTypeIdentifier.toolFill);
    });

    _fillTest("replaces a color everywhere, also where it is not connected", (final DrawingLayerState layer) async
    {
      final ColorReference old = _ramps[0].references[1];
      final ColorReference other = _ramps[1].references[1];
      final ColorReference color = _ramps[2].references[1];
      GetIt.I.get<PaletteState>().selectedColor = color;
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_left: old, _right: old, CoordinateSetI(x: 2, y: 2): other}));
      await settle();

      await _fill(painter: _painter(), layer: layer, at: _left);

      expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{_left: color, _right: color, CoordinateSetI(x: 2, y: 2): other});
    });

    _fillTest("takes the whole ramp when asked to", (final DrawingLayerState layer) async
    {
      final ColorReference color = _ramps[2].references[1];
      final ColorReference other = _ramps[1].references[1];
      GetIt.I.get<PaletteState>().selectedColor = color;
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_left: _ramps[0].references[1], _right: _ramps[0].references[3], CoordinateSetI(x: 2, y: 2): other}));
      await settle();
      _options.fillWholeRamp.value = true;

      await _fill(painter: _painter(), layer: layer, at: _left);

      expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{_left: color, _right: color, CoordinateSetI(x: 2, y: 2): other});
    });

    for (final (ShaderDirection direction, int step) shading in <(ShaderDirection, int)>[(ShaderDirection.right, 1), (ShaderDirection.left, -1)])
    {
      _fillTest("steps the color ${shading.$1.name} when shading", (final DrawingLayerState layer) async
      {
        final List<ColorReference> ramp = _ramps[0].references;
        layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_left: ramp[2], _right: ramp[2], CoordinateSetI(x: 2, y: 2): ramp[3]}));
        await settle();
        _shader.isEnabled.value = true;
        _shader.shaderDirection.value = shading.$1;

        await _fill(painter: _painter(), layer: layer, at: _left);

        expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{_left: ramp[2 + shading.$2], _right: ramp[2 + shading.$2], CoordinateSetI(x: 2, y: 2): ramp[3]});
      });
    }

    _fillTest("leaves a color at the end of its ramp alone when shading", (final DrawingLayerState layer) async
    {
      final List<ColorReference> ramp = _ramps[0].references;
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_left: ramp.last, CoordinateSetI(x: 1, y: 1): ramp.first}));
      await settle();
      _shader.isEnabled.value = true;
      _shader.shaderDirection.value = ShaderDirection.right;

      await _fill(painter: _painter(), layer: layer, at: _left);

      expect(colorsOf(layer: layer)[_left], ramp.last);

      _shader.shaderDirection.value = ShaderDirection.left;
      await _fill(painter: _painter(), layer: layer, at: CoordinateSetI(x: 1, y: 1));

      expect(colorsOf(layer: layer)[CoordinateSetI(x: 1, y: 1)], ramp.first);
    });

    _fillTest("shades every ramp at once when not bound to the current one", (final DrawingLayerState layer) async
    {
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_left: _ramps[0].references[1], _right: _ramps[1].references[2]}));
      await settle();
      _shader.isEnabled.value = true;
      _shader.shaderDirection.value = ShaderDirection.right;
      _shader.onlyCurrentRampEnabled.value = false;
      _options.fillWholeRamp.value = true;

      await _fill(painter: _painter(), layer: layer, at: _left);

      expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{_left: _ramps[0].references[2], _right: _ramps[1].references[3]});
    });

    group("with a floating selection", ()
    {
      Future<void> selectLeftHalf() async
      {
        GetIt.I.get<DocumentState>().selectionState.newSelectionFromShape(start: CoordinateSetI(x: 0, y: 0), end: CoordinateSetI(x: 2, y: 3), selectShape: SelectShape.rectangle);
        await settle();
      }

      _fillTest("only fills inside of it", (final DrawingLayerState layer) async
      {
        await selectLeftHalf();
        final ColorReference color = GetIt.I.get<PaletteState>().selectedColor!;

        await _fill(painter: _painter(), layer: layer, at: _left);

        expect(colorsOf(layer: layer), isEmpty, reason: "the selection floats above the layer");
        expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: CoordinateSetI(x: 2, y: 3)), color);
      });

      _fillTest("does nothing for a click outside of it", (final DrawingLayerState layer) async
      {
        await selectLeftHalf();

        await _fill(painter: _painter(), layer: layer, at: _right);

        expect(colorsOf(layer: layer), isEmpty);
        expect(GetIt.I.get<DocumentState>().selectionState.selection.getColorReference(coord: _left), isNull);
      });

      _fillTest("steps the colors inside of it when shading", (final DrawingLayerState layer) async
      {
        final List<ColorReference> ramp = _ramps[0].references;
        layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_left: ramp[2], CoordinateSetI(x: 1, y: 1): ramp[2], _right: ramp[2]}));
        await settle();
        await selectLeftHalf();
        _shader.isEnabled.value = true;
        _shader.shaderDirection.value = ShaderDirection.right;

        await _fill(painter: _painter(), layer: layer, at: _left);

        final SelectionList selection = GetIt.I.get<DocumentState>().selectionState.selection;
        expect(selection.getColorReference(coord: _left), ramp[3]);
        expect(selection.getColorReference(coord: CoordinateSetI(x: 1, y: 1)), ramp[3]);
        expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{_right: ramp[2]}, reason: "outside of the selection nothing changes");

        _shader.shaderDirection.value = ShaderDirection.left;
        await _fill(painter: _painter(), layer: layer, at: _left);

        expect(selection.getColorReference(coord: _left), ramp[2]);
      });

      _fillTest("takes the whole ramp inside of it when asked to", (final DrawingLayerState layer) async
      {
        final List<ColorReference> ramp = _ramps[0].references;
        final ColorReference color = _ramps[2].references[1];
        GetIt.I.get<PaletteState>().selectedColor = color;
        layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_left: ramp[1], CoordinateSetI(x: 1, y: 1): ramp[3]}));
        await settle();
        await selectLeftHalf();
        _options.fillWholeRamp.value = true;

        await _fill(painter: _painter(), layer: layer, at: _left);

        final SelectionList selection = GetIt.I.get<DocumentState>().selectionState.selection;
        expect(selection.getColorReference(coord: _left), color);
        expect(selection.getColorReference(coord: CoordinateSetI(x: 1, y: 1)), color);
      });
    });
  });

  group("on a shading layer", ()
  {
    _shadingFillTest("brightens everything that holds the same value", (final ShadingLayerState layer) async
    {
      final FillPainter painter = _painter();
      _shader.shaderDirection.value = ShaderDirection.right;

      await _fill(painter: painter, layer: layer, at: _left);

      expect(shadesOf(layer: layer), <CoordinateSetI, int>{for (final CoordinateSetI coord in _everyPixel()) coord: 1});
      expect(painter.hasHistoryData, isTrue);
    });

    _shadingFillTest("darkens the other way", (final ShadingLayerState layer) async
    {
      _shader.shaderDirection.value = ShaderDirection.left;

      await _fill(painter: _painter(), layer: layer, at: _left);

      expect(shadesOf(layer: layer), <CoordinateSetI, int>{for (final CoordinateSetI coord in _everyPixel()) coord: -1});
    });

    _shadingFillTest("only touches the value it started on", (final ShadingLayerState layer) async
    {
      _shader.shaderDirection.value = ShaderDirection.right;
      await _fill(painter: _painter(), layer: layer, at: _left);
      layer.removeCoords(coords: <CoordinateSetI>[_right]);
      await settle();

      await _fill(painter: _painter(), layer: layer, at: _left);

      expect(shadesOf(layer: layer)[_left], 2);
      expect(shadesOf(layer: layer).containsKey(_right), isFalse);
    });

    _shadingFillTest("stops at the limit of the layer", (final ShadingLayerState layer) async
    {
      _shader.shaderDirection.value = ShaderDirection.right;

      for (int i = 0; i < 5; i++)
      {
        await _fill(painter: _painter(), layer: layer, at: _left);
      }

      expect(shadesOf(layer: layer)[_left], 3);
    });

    _shadingFillTest("removes values that reach zero", (final ShadingLayerState layer) async
    {
      _shader.shaderDirection.value = ShaderDirection.right;
      await _fill(painter: _painter(), layer: layer, at: _left);
      _shader.shaderDirection.value = ShaderDirection.left;

      await _fill(painter: _painter(), layer: layer, at: _left);

      expect(shadesOf(layer: layer), isEmpty);
    });

    _shadingFillTest("does nothing on a locked layer", (final ShadingLayerState layer) async
    {
      layer.lockState.value = LayerLockState.locked;
      final FillPainter painter = _painter();

      await _fill(painter: painter, layer: layer, at: _left);

      expect(shadesOf(layer: layer), isEmpty);
      expect(painter.hasHistoryData, isFalse);
    });

    _shadingFillTest("does nothing on a hidden layer", (final ShadingLayerState layer) async
    {
      layer.visibilityState.value = LayerVisibilityState.hidden;

      await _fill(painter: _painter(), layer: layer, at: _left);

      expect(shadesOf(layer: layer), isEmpty);
    });
  });

  group("what is refused", ()
  {
    _fillTest("does nothing on a locked layer", (final DrawingLayerState layer) async
    {
      layer.lockState.value = LayerLockState.locked;
      final FillPainter painter = _painter();

      await _fill(painter: painter, layer: layer, at: _left);

      expect(colorsOf(layer: layer), isEmpty);
      expect(painter.hasHistoryData, isFalse);
    });

    _fillTest("does nothing on a hidden layer", (final DrawingLayerState layer) async
    {
      layer.visibilityState.value = LayerVisibilityState.hidden;

      await _fill(painter: _painter(), layer: layer, at: _left);

      expect(colorsOf(layer: layer), isEmpty);
    });

    _fillTest("does nothing from an empty pixel of a transparency locked layer", (final DrawingLayerState layer) async
    {
      final ColorReference old = _ramps[0].references[1];
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_right: old}));
      await settle();
      layer.lockState.value = LayerLockState.transparency;

      await _fill(painter: _painter(), layer: layer, at: _left);

      expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{_right: old});
    });

    _fillTest("recolors from a filled pixel of a transparency locked layer", (final DrawingLayerState layer) async
    {
      final ColorReference color = _ramps[2].references[1];
      GetIt.I.get<PaletteState>().selectedColor = color;
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_right: _ramps[0].references[1]}));
      await settle();
      layer.lockState.value = LayerLockState.transparency;

      await _fill(painter: _painter(), layer: layer, at: _right);

      expect(colorsOf(layer: layer), <CoordinateSetI, ColorReference>{_right: color});
    });

    _fillTest("a press off the canvas fills nothing", (final DrawingLayerState layer) async
    {
      await _fill(painter: _painter(), layer: layer, at: CoordinateSetI(x: 40, y: 40));

      expect(colorsOf(layer: layer), isEmpty);
    });
  });

  group("the rest of the tool", ()
  {
    _fillTest("fires once per press", (final DrawingLayerState layer) async
    {
      final FillPainter painter = _painter();
      final List<ColorReference> ramp = _ramps[0].references;
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{_left: ramp[1]}));
      await settle();
      _shader.isEnabled.value = true;
      _shader.shaderDirection.value = ShaderDirection.right;
      _options.fillAdjacent.value = false;

      //held and redrawn several times, as the canvas does during a press
      dragTool(painter: painter, layer: layer, path: <CoordinateSetI>[_left, _left, _left]);
      await settle();

      expect(colorsOf(layer: layer)[_left], ramp[2]);
    });

    _fillTest("the overlays cope with the cursor resting and leaving", (final DrawingLayerState layer) async
    {
      final FillPainter painter = _painter();

      exerciseToolOverlays(painter: painter, layer: layer, cursor: _left);
      expect(painter.statusBarData.cursorPos, _left);

      painter.drawCursorOutline(drawParams: toolParams(layer: layer, cursor: null));
      painter.setStatusBarData(drawParams: toolParams(layer: layer, cursor: null));
      expect(painter.statusBarData.cursorPos, isNull);
    });

    _fillTest("reset forgets a fill that has not happened yet", (final DrawingLayerState layer) async
    {
      final FillPainter painter = _painter();
      _options.fillAdjacent.value = false;
      painter.calculate(drawParams: toolParams(layer: layer, cursor: _left, primaryDown: true));

      painter.reset();
      painter.drawExtras(drawParams: toolParams(layer: layer, cursor: _left, primaryDown: true));
      await settle();

      expect(colorsOf(layer: layer), isEmpty);
    });
  });
}
