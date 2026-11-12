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

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/constraints/tool_select_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/tool_type.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:material_ui/material_ui.dart';

import 'support/selection_harness.dart';

HotkeyManager get _hotkeys => GetIt.I.get<HotkeyManager>();
Timeline get _timeline => GetIt.I.get<DocumentState>().timeline;
SelectionState get _selection => GetIt.I.get<DocumentState>().selectionState;
HistoryManager get _history => GetIt.I.get<HistoryManager>();
ToolState get _tools => GetIt.I.get<ToolState>();

void _test(final String description, final Future<void> Function(DrawingLayerState layer) body)
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 8, y: 8), body: (final ProjectSession projectSession) async
    {
      await body(layerAt(projectSession: projectSession, index: 0));
    },);
  });
}

void _trigger(final HotkeyAction action) => _hotkeys.triggerShortcut(action: action);

/// The box 2|2 to 3|3.
void _selectBox()
{
  GetIt.I.get<ToolOptions>().selectOptions.mode.value = SelectMode.replace;
  _selection.newSelectionFromShape(start: CoordinateSetI(x: 2, y: 2), end: CoordinateSetI(x: 3, y: 3), selectShape: SelectShape.rectangle);
}

void main()
{
  group("the tool hotkeys", ()
  {
    for (final (HotkeyAction, ToolType) entry in <(HotkeyAction, ToolType)>[
      (HotkeyAction.selectToolPencil, ToolType.pencil),
      (HotkeyAction.selectToolFill, ToolType.fill),
      (HotkeyAction.selectToolShape, ToolType.shape),
      (HotkeyAction.selectToolEraser, ToolType.erase),
      (HotkeyAction.selectToolText, ToolType.font),
      (HotkeyAction.selectToolSprayCan, ToolType.spraycan),
      (HotkeyAction.selectToolLine, ToolType.line),
      (HotkeyAction.selectToolStamp, ToolType.stamp),
    ])
    {
      _test("${entry.$1.name} selects ${entry.$2.name}", (final DrawingLayerState layer) async
      {
        _tools.setToolSelection(tool: ToolType.select);

        _trigger(entry.$1);

        expect(_tools.selectedTool, entry.$2);
      });
    }

    for (final (HotkeyAction, SelectShape) entry in <(HotkeyAction, SelectShape)>[
      (HotkeyAction.selectToolSelectRectangle, SelectShape.rectangle),
      (HotkeyAction.selectToolSelectCircle, SelectShape.ellipse),
      (HotkeyAction.selectToolSelectWand, SelectShape.wand),
    ])
    {
      _test("${entry.$1.name} selects the ${entry.$2.name} selection", (final DrawingLayerState layer) async
      {
        _trigger(entry.$1);

        expect(_tools.selectedTool, ToolType.select);
        expect(GetIt.I.get<ToolOptions>().selectOptions.shape.value, entry.$2);
      });
    }

    _test("cannot select what the layer does not allow", (final DrawingLayerState layer) async
    {
      GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.shading, select: true);
      await settle();
      _tools.setToolSelection(tool: ToolType.pencil);

      _trigger(HotkeyAction.selectToolSelectRectangle);

      expect(_tools.selectedTool, ToolType.pencil);
    });
  });

  group("the layer hotkeys", ()
  {
    _test("switch the visibility of the selected layer", (final DrawingLayerState layer) async
    {
      _trigger(HotkeyAction.layersSwitchVisibility);
      expect(layer.visibilityState.value, LayerVisibilityState.hidden);

      _trigger(HotkeyAction.layersSwitchVisibility);
      expect(layer.visibilityState.value, LayerVisibilityState.visible);
    });

    _test("switch the lock of the selected layer", (final DrawingLayerState layer) async
    {
      _trigger(HotkeyAction.layersSwitchLock);
      expect(layer.lockState.value, LayerLockState.transparency);
    });

    _test("move the selected layer", (final DrawingLayerState layer) async
    {
      final LayerState above = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.drawing).$2!;
      await settle();
      expect(_timeline.selectedFrame!.layerList.getLayerPosition(state: layer), 1, reason: "setup");

      _trigger(HotkeyAction.layersMoveUp);
      expect(_timeline.selectedFrame!.layerList.getLayerPosition(state: layer), 0);

      _trigger(HotkeyAction.layersMoveDown);
      expect(_timeline.selectedFrame!.layerList.getLayerPosition(state: layer), 1);
      expect(_timeline.selectedFrame!.layerList.getLayerPosition(state: above), 0);
    });

    _test("step through the layers", (final DrawingLayerState layer) async
    {
      final LayerState above = GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.drawing, select: true).$2!;
      await settle();

      _trigger(HotkeyAction.layersSelectBelow);
      expect(_timeline.getCurrentLayer(), same(layer));

      _trigger(HotkeyAction.layersSelectAbove);
      expect(_timeline.getCurrentLayer(), same(above));
    });
  });

  group("the selection hotkeys", ()
  {
    _test("select everything", (final DrawingLayerState layer) async
    {
      _trigger(HotkeyAction.selectionSelectAll);

      expect(_selection.selection.contains(coord: CoordinateSetI(x: 0, y: 0)), isTrue);
      expect(_selection.selection.contains(coord: CoordinateSetI(x: 7, y: 7)), isTrue);
    });

    _test("invert what is selected", (final DrawingLayerState layer) async
    {
      _selectBox();

      _trigger(HotkeyAction.selectionInvert);

      expect(_selection.selection.contains(coord: CoordinateSetI(x: 2, y: 2)), isFalse);
      expect(_selection.selection.contains(coord: CoordinateSetI(x: 0, y: 0)), isTrue);
    });

    _test("deselect, as an undo step", (final DrawingLayerState layer) async
    {
      _selectBox();

      _trigger(HotkeyAction.selectionDeselect);

      expect(_selection.selection.isEmpty, isTrue);
      expect(_history.getCurrentIdentifier(), HistoryStateTypeIdentifier.selectionDeselect);
    });

    for (final (HotkeyAction, CoordinateSetI) entry in <(HotkeyAction, CoordinateSetI)>[
      (HotkeyAction.selectionMoveUp, CoordinateSetI(x: 2, y: 1)),
      (HotkeyAction.selectionMoveDown, CoordinateSetI(x: 2, y: 3)),
      (HotkeyAction.selectionMoveLeft, CoordinateSetI(x: 1, y: 2)),
      (HotkeyAction.selectionMoveRight, CoordinateSetI(x: 3, y: 2)),
    ])
    {
      _test("${entry.$1.name} moves the box one pixel", (final DrawingLayerState layer) async
      {
        _selectBox();

        _trigger(entry.$1);

        final CoordinateSetI corner = entry.$2;
        for (int x = 0; x < 2; x++)
        {
          for (int y = 0; y < 2; y++)
          {
            expect(_selection.selection.contains(coord: CoordinateSetI(x: corner.x + x, y: corner.y + y)), isTrue);
          }
        }
        expect(_selection.selection.contains(coord: CoordinateSetI(x: corner.x + 2, y: corner.y)), isFalse);
      });
    }

    for (final HotkeyAction action in <HotkeyAction>[
      HotkeyAction.selectionInvert,
      HotkeyAction.selectionDeselect,
      HotkeyAction.selectionMoveUp,
      HotkeyAction.selectionMoveDown,
      HotkeyAction.selectionMoveLeft,
      HotkeyAction.selectionMoveRight,
    ])
    {
      _test("${action.name} does nothing without a selection", (final DrawingLayerState layer) async
      {
        final HistoryState? before = _history.getCurrentState();

        _trigger(action);

        expect(_selection.selection.isEmpty, isTrue);
        expect(_history.getCurrentState(), same(before));
      });
    }
  });

  group("the zoom hotkeys", ()
  {
    for (final (HotkeyAction, int) entry in <(HotkeyAction, int)>[
      (HotkeyAction.panZoomSetZoom200, 2),
      (HotkeyAction.panZoomSetZoom400, 4),
      (HotkeyAction.panZoomSetZoom800, 8),
      (HotkeyAction.panZoomSetZoom1600, 16),
      (HotkeyAction.panZoomSetZoom3200, 32),
      (HotkeyAction.panZoomSetZoom4800, 48),
      (HotkeyAction.panZoomSetZoom6400, 64),
      (HotkeyAction.panZoomSetZoom8000, 80),
    ])
    {
      _test("${entry.$1.name} goes to level ${entry.$2}", (final DrawingLayerState layer) async
      {
        _trigger(entry.$1);

        expect(GetIt.I.get<ViewState>().zoomFactor, entry.$2);
        expect(GetIt.I.get<StatusBarState>().statusBarZoomFactorString.value, "${entry.$2 * 100}%");
      });
    }

    _test("panZoomSetZoom100 goes back to the first level", (final DrawingLayerState layer) async
    {
      _trigger(HotkeyAction.panZoomSetZoom800);

      _trigger(HotkeyAction.panZoomSetZoom100);

      expect(GetIt.I.get<ViewState>().zoomFactor, 1);
    });

    _test("step in and out", (final DrawingLayerState layer) async
    {
      _trigger(HotkeyAction.panZoomSetZoom800);

      _trigger(HotkeyAction.panZoomZoomIn);
      expect(GetIt.I.get<ViewState>().zoomFactor, 9);

      _trigger(HotkeyAction.panZoomZoomOut);
      _trigger(HotkeyAction.panZoomZoomOut);
      expect(GetIt.I.get<ViewState>().zoomFactor, 7);
    });
  });

  group("the mouse", ()
  {
    for (final (String, int, HotkeyAction?) entry in <(String, int, HotkeyAction?)>[
      ("back button", kBackMouseButton, HotkeyAction.generalUndo),
      ("forward button", kForwardMouseButton, HotkeyAction.generalRedo),
      ("primary button", kPrimaryButton, null),
    ])
    {
      testWidgets("${entry.$1} ${entry.$3 == null ? "means nothing" : "triggers ${entry.$3!.name}"}", (final WidgetTester tester) async
      {
        final HotkeyManager manager = HotkeyManager();
        final Map<HotkeyAction, int> calls = <HotkeyAction, int>{};
        for (final HotkeyAction action in <HotkeyAction>[HotkeyAction.generalUndo, HotkeyAction.generalRedo])
        {
          manager.addListener(func: () {calls[action] = (calls[action] ?? 0) + 1;}, action: action);
        }

        manager.handleMouseEvent(PointerDownEvent(buttons: entry.$2));

        expect(calls, entry.$3 == null ? isEmpty : <HotkeyAction, int>{entry.$3!: 1});
      });
    }
  });

  group("the shortcut text", ()
  {
    Future<(HotkeyManager, BuildContext, AppLocalizations)> pumpContext(final WidgetTester tester) async
    {
      late BuildContext captured;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale("en"),
        home: Builder(builder: (final BuildContext context) {
          captured = context;
          return const SizedBox.shrink();
        },),
      ),);
      return (HotkeyManager(), captured, AppLocalizations.of(captured)!);
    }

    testWidgets("exists for every action", (final WidgetTester tester) async
    {
      final (HotkeyManager manager, BuildContext context, AppLocalizations _) = await pumpContext(tester);

      for (final HotkeyAction action in HotkeyAction.values)
      {
        expect(manager.getShortcutString(action: action, context: context), isNotEmpty, reason: action.name);
      }
    });

    testWidgets("names the modifiers and comes in brackets on a line of its own", (final WidgetTester tester) async
    {
      final (HotkeyManager manager, BuildContext context, AppLocalizations l10n) = await pumpContext(tester);

      expect(manager.getShortcutString(action: HotkeyAction.selectionCopy, context: context), "\n[${l10n.keyCtrl} + C]");
      expect(manager.getShortcutString(action: HotkeyAction.generalSaveAs, context: context), "\n[${l10n.keyShift} + ${l10n.keyCtrl} + S]");
      expect(manager.getShortcutString(action: HotkeyAction.selectToolPencil, context: context), "\n[B]");
    });

    testWidgets("can do without the line and the brackets", (final WidgetTester tester) async
    {
      final (HotkeyManager manager, BuildContext context, AppLocalizations l10n) = await pumpContext(tester);

      expect(manager.getShortcutString(action: HotkeyAction.selectionCopy, context: context, precededNewLine: false, showSquareBrackets: false), "${l10n.keyCtrl} + C");
    });

    testWidgets("gives the space bar a name", (final WidgetTester tester) async
    {
      final (HotkeyManager manager, BuildContext context, AppLocalizations l10n) = await pumpContext(tester);

      expect(manager.getShortcutString(action: HotkeyAction.shadingToggle, context: context, precededNewLine: false), "[${l10n.keySpace}]");
    });

    testWidgets("lists all shortcuts of an action", (final WidgetTester tester) async
    {
      final (HotkeyManager manager, BuildContext context, AppLocalizations l10n) = await pumpContext(tester);

      expect(manager.getShortcutString(action: HotkeyAction.generalExit, context: context, precededNewLine: false), "[${l10n.keyAlt} + F4]\n[${l10n.keyCtrl} + Q]");
    });
  });
}
