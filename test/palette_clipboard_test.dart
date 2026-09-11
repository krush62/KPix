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

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_color_reference.dart';
import 'package:kpix/models/history/history_drawing_layer.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/export_functions.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

Future<Uint8List> _save() async => (await createKPixData()).buffer.asUint8List();

Future<LoadFileSet> _load({required final Uint8List bytes}) async
{
  final PreferenceManager prefs = GetIt.I.get<PreferenceManager>();
  return loadKPixFile(
    fileData: bytes,
    path: "palette_clipboard.kpix",
    drawingLayerSettingsConstraints: prefs.drawingLayerSettingsConstraints,
    shadingLayerSettingsConstraints: prefs.shadingLayerSettingsConstraints,
    frameConstraints: prefs.frameConstraints,
  );
}

/// Saves and reloads the project; every drawing layer pixel as "ramp/color".
Future<Map<CoordinateSetI, String>> _roundTrip() async
{
  final LoadFileSet loaded = await _load(bytes: await _save());
  expect(loaded.historyState, isNotNull, reason: "the saved file must load again: ${loaded.status}");
  final Map<CoordinateSetI, String> pixels = <CoordinateSetI, String>{};
  for (final HistoryLayer layer in loaded.historyState!.timeline.allLayers)
  {
    if (layer is HistoryDrawingLayer)
    {
      for (final MapEntry<CoordinateSetI, HistoryColorReference> entry in layer.data.entries)
      {
        pixels[entry.key] = "${entry.value.rampIndex}/${entry.value.colorIndex}";
      }
    }
  }
  return pixels;
}

void _put({required final DrawingLayerState layer, required final Map<CoordinateSetI, ColorReference> pixels})
{
  layer.setDataAll(list: CoordinateColorMapNullable.from(pixels));
}

/// What the ramp editor does when a new color count is accepted.
void _changeColorCount({required final KPalRampData ramp, required final int colorCount})
{
  final KPalRampData original = KPalRampData.from(other: ramp);
  ramp.settings.colorCount = colorCount;
  ramp.updateColors(colorCountChanged: true);
  GetIt.I.get<PaletteState>().updateRamp(ramp: ramp, originalData: original);
}

/// Every color on the layers and in the floating selection is one of the
/// palette's own ramp objects and in range for it.
void _expectOnlyPaletteColors()
{
  final List<KPalRampData> ramps = GetIt.I.get<PaletteState>().colorRamps;
  void check(final ColorReference color, final String where)
  {
    expect(ramps.any((final KPalRampData ramp) => identical(ramp, color.ramp)), isTrue, reason: "$where holds a color of a ramp that is not in the palette");
    expect(color.colorIndex, lessThan(color.ramp.references.length), reason: "$where holds a color index outside its ramp");
  }
  for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
  {
    for (int i = 0; i < frame.layerList.length; i++)
    {
      final LayerState layer = frame.layerList.getLayer(index: i);
      if (layer is DrawingLayerState)
      {
        for (final ColorReference color in layer.usedColors())
        {
          check(color, "a layer");
        }
      }
    }
  }
  for (final ColorReference? color in GetIt.I.get<DocumentState>().selectionState.selection.selectedPixels.values)
  {
    if (color != null)
    {
      check(color, "the selection");
    }
  }
}

/// Colors that outlive their place in the palette.
///
/// The clipboard remembers colors by ramp uuid and is matched against the
/// palette when it is pasted, so deleting a ramp, changing its color count,
/// undoing either, or a full undo rebuilding every ramp must never let a pixel
/// reach the image that the palette does not contain. The floating selection is
/// part of the image and is updated right away instead.
///
/// The default palette is purple (5 colors), red (6), brown (7), yellow (5),
/// green (6), blue (5), grey (7).
void main()
{
  final CoordinateSetI canvasSize = CoordinateSetI(x: 4, y: 4);
  final CoordinateSetI a = CoordinateSetI(x: 1, y: 1);
  final CoordinateSetI b = CoordinateSetI(x: 2, y: 2);

  group("deleting a ramp", ()
  {
    testWidgets("drops its pixels from a paste but keeps the other colors and the shape", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
        final KPalRampData doomed = palette.colorRamps[1];
        final KPalRampData keeper = palette.colorRamps[3];
        final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
        _put(layer: layer, pixels: <CoordinateSetI, ColorReference>{a: doomed.references[2], b: keeper.references[1]});
        await settle();
        sel.selectAll();
        sel.copy();
        await settle();

        palette.deleteRamp(ramp: doomed);
        await settle();
        sel.paste();
        await settle();

        expect(sel.selection.contains(coord: a), isTrue, reason: "the pasted selection keeps its shape");
        expect(sel.selection.getColorReference(coord: a), isNull, reason: "but the deleted ramp's pixel is transparent");
        expect(sel.selection.getColorReference(coord: b), same(keeper.references[1]), reason: "the other color pastes unchanged");
        _expectOnlyPaletteColors();

        sel.deselect(addToHistoryStack: true);
        await settle();
        expect(layer.getDataEntry(coord: a), isNull);
        expect(await _roundTrip(), <CoordinateSetI, String>{b: "${palette.colorRamps.indexOf(keeper)}/1"});
      },);
    });

    testWidgets("pastes nothing when every copied color is gone", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
        final KPalRampData doomed = palette.colorRamps[1];
        _put(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: doomed.references[2]});
        await settle();
        sel.selectAll();
        sel.copy();
        await settle();

        palette.deleteRamp(ramp: doomed);
        await settle();
        final int layerCount = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.length;
        sel.paste();
        sel.pasteAsNewLayer();
        await settle();

        expect(sel.selection.isEmpty, isTrue, reason: "paste must not create an empty floating selection");
        expect(GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.length, layerCount, reason: "paste as new layer must not add an empty layer");
        expect(sel.hasClipboard, isTrue, reason: "the clipboard is kept, undoing the deletion brings its colors back");
      },);
    });

    testWidgets("brings its pixels back to the clipboard when the deletion is undone", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
        final KPalRampData doomed = palette.colorRamps[1];
        _put(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: doomed.references[2]});
        await settle();
        sel.selectAll();
        sel.copy();
        await settle();

        palette.deleteRamp(ramp: doomed);
        await settle();
        GetIt.I.get<HistoryController>().undoPressed();
        await settle();
        await settle();
        sel.paste();
        await settle();

        final ColorReference? pasted = sel.selection.getColorReference(coord: a);
        expect(pasted, isNotNull);
        expect(pasted!.ramp.uuid, doomed.uuid);
        expect(pasted.colorIndex, 2);
        _expectOnlyPaletteColors();
      },);
    });

    testWidgets("empties the floating selection and counts it and the clipboard in the warning", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
        final KPalRampData doomed = palette.colorRamps[1];
        final KPalRampData keeper = palette.colorRamps[3];
        _put(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: doomed.references[2], b: keeper.references[1]});
        await settle();
        sel.selectAll();
        sel.copy(keepSelection: true);
        await settle();

        final RampPixelUsage usage = palette.getPixelUsageForRamp(ramp: doomed);
        expect(usage.layers, 0, reason: "select all lifted the pixel off the layer");
        expect(usage.selection, 1);
        expect(usage.clipboard, 1);

        palette.deleteRamp(ramp: doomed);
        await settle();
        expect(sel.selection.contains(coord: a), isTrue, reason: "the selection keeps its shape");
        expect(sel.selection.getColorReference(coord: a), isNull, reason: "but no longer holds the deleted ramp");
        expect(sel.selection.getColorReference(coord: b), same(keeper.references[1]));
        _expectOnlyPaletteColors();
        expect(await _roundTrip(), <CoordinateSetI, String>{b: "${palette.colorRamps.indexOf(keeper)}/1"});
      },);
    });
  });

  group("changing a ramp's color count", ()
  {
    testWidgets("remaps a paste the same way as the layers", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
        final KPalRampData brown = palette.colorRamps[2];
        final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
        _put(layer: layer, pixels: <CoordinateSetI, ColorReference>{a: brown.references[6]});
        await settle();
        sel.selectAll();
        sel.copy();
        await settle();

        _changeColorCount(ramp: brown, colorCount: 3);
        await settle();
        expect(layer.getDataEntry(coord: a)!.colorIndex, 2, reason: "setup: the layer pixel moved from 6 to 2");

        sel.paste();
        await settle();
        expect(sel.selection.getColorReference(coord: a), same(brown.references[2]), reason: "the pasted pixel lands on the same index");
        sel.deselect(addToHistoryStack: true);
        await settle();
        _expectOnlyPaletteColors();
        expect(await _roundTrip(), <CoordinateSetI, String>{a: "2/2"});
      },);
    });

    testWidgets("pastes the original color after the change is undone", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
        _put(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: palette.colorRamps[2].references[6]});
        await settle();
        sel.selectAll();
        sel.copy();
        await settle();

        _changeColorCount(ramp: palette.colorRamps[2], colorCount: 3);
        await settle();
        GetIt.I.get<HistoryController>().undoPressed();
        await settle();
        await settle();
        expect(palette.colorRamps[2].references.length, 7, reason: "setup: undo restored seven colors");

        sel.paste();
        await settle();
        expect(sel.selection.getColorReference(coord: a), same(palette.colorRamps[2].references[6]));
        _expectOnlyPaletteColors();
      },);
    });

    testWidgets("remaps the floating selection", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
        final KPalRampData brown = palette.colorRamps[2];
        _put(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: brown.references[6]});
        await settle();
        sel.selectAll();
        await settle();

        _changeColorCount(ramp: brown, colorCount: 3);
        await settle();

        expect(sel.selection.getColorReference(coord: a), same(brown.references[2]));
        _expectOnlyPaletteColors();
        expect(await _roundTrip(), <CoordinateSetI, String>{a: "2/2"});
      },);
    });

    testWidgets("leaves a selected color of another ramp alone", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final KPalRampData purple = palette.colorRamps[0];
        final ColorReference beyondPurple = palette.colorRamps[2].references[6];
        final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
        _put(layer: layer, pixels: <CoordinateSetI, ColorReference>{a: purple.references[4]});
        await settle();

        //an index purple does not have, which used to abort the update
        palette.selectedColor = beyondPurple;
        _changeColorCount(ramp: purple, colorCount: 3);
        await settle();
        expect(palette.selectedColor, same(beyondPurple));
        expect(layer.getDataEntry(coord: a)!.colorIndex, 2, reason: "the layers are remapped");
        _expectOnlyPaletteColors();
        expect(await _roundTrip(), <CoordinateSetI, String>{a: "0/2"});

        //an index purple does have, which used to move the selection into purple
        final ColorReference withinPurple = palette.colorRamps[1].references[1];
        palette.selectedColor = withinPurple;
        _changeColorCount(ramp: purple, colorCount: 4);
        await settle();
        expect(palette.selectedColor, same(withinPurple));
      },);
    });
  });

  group("a full undo rebuilding the ramps", ()
  {
    testWidgets("does not leave the clipboard pointing at discarded ramps", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
        _put(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: palette.colorRamps[0].references[1]});
        await settle();
        sel.selectAll();
        sel.copy();
        await settle();

        GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState);
        await settle();
        GetIt.I.get<HistoryController>().undoPressed();
        await settle();
        await settle();

        final KPalRampData liveRamp = palette.colorRamps[0];
        sel.paste();
        sel.deselect(addToHistoryStack: true);
        await settle();
        final DrawingLayerState liveLayer = layerAt(projectSession: projectSession, index: 0);
        expect(liveLayer.getDataEntry(coord: a)!.ramp, same(liveRamp));
        _expectOnlyPaletteColors();
        expect(palette.getPixelUsageForRamp(ramp: liveRamp).layers, 1, reason: "the pasted pixel counts for its ramp");

        palette.deleteRamp(ramp: liveRamp);
        await settle();
        expect(liveLayer.getDataEntry(coord: a), isNull, reason: "and is deleted with it");
      },);
    });
  });

  group("replacing the palette", ()
  {
    testWidgets("remaps the floating selection into the new palette", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
        _put(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: palette.colorRamps[1].references[2]});
        await settle();
        sel.selectAll();
        await settle();

        palette.replacePalette(loadPaletteSet: LoadPaletteSet(status: "", rampData: KPalRampData.getDefaultPalette()), paletteReplaceBehavior: PaletteReplaceBehavior.remap);
        await settle();

        expect(sel.selection.getColorReference(coord: a), isNotNull);
        _expectOnlyPaletteColors();
        expect((await _roundTrip()).keys, <CoordinateSetI>[a]);
      },);
    });

    testWidgets("empties the floating selection when the colors are not remapped", (final WidgetTester tester) async
    {
      await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
      {
        final PaletteState palette = GetIt.I.get<PaletteState>();
        final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
        _put(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: palette.colorRamps[1].references[2]});
        await settle();
        sel.selectAll();
        await settle();

        palette.replacePalette(loadPaletteSet: LoadPaletteSet(status: "", rampData: KPalRampData.getDefaultPalette()), paletteReplaceBehavior: PaletteReplaceBehavior.replace);
        await settle();

        expect(sel.selection.contains(coord: a), isTrue);
        expect(sel.selection.getColorReference(coord: a), isNull);
        _expectOnlyPaletteColors();
        expect(await _roundTrip(), isEmpty);
      },);
    });
  });

  testWidgets("starting a new project clears the clipboard", (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: canvasSize, body: (final ProjectSession projectSession) async
    {
      final SelectionState sel = GetIt.I.get<DocumentState>().selectionState;
      _put(layer: layerAt(projectSession: projectSession, index: 0), pixels: <CoordinateSetI, ColorReference>{a: GetIt.I.get<PaletteState>().colorRamps[0].references[0]});
      await settle();
      sel.selectAll();
      sel.copy();
      expect(sel.hasClipboard, isTrue, reason: "setup: something was copied");

      projectSession.init(dimensions: canvasSize);
      await settle();
      expect(sel.hasClipboard, isFalse);
    },);
  });
}
