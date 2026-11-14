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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:material_ui/material_ui.dart';

/// The key handling around the app as built in main.dart: the shortcut
/// callbacks on key down, the [KeyboardListener] for the key up handling.
class _Host
{
  final HotkeyManager manager = HotkeyManager();
  final FocusNode listenerFocus = FocusNode(debugLabel: "key listener");
  final FocusNode appFocus = FocusNode(debugLabel: "inside the app");

  Future<void> pump(final WidgetTester tester) async
  {
    addTearDown(listenerFocus.dispose);
    addTearDown(appFocus.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<Map<SingleActivator, VoidCallback>>(
        valueListenable: manager.callbackMapNotifier,
        builder: (final BuildContext context, final Map<SingleActivator, VoidCallback> callbacks, final Widget? child) {
          return CallbackShortcuts(
            bindings: callbacks,
            child: KeyboardListener(
              focusNode: listenerFocus,
              autofocus: true,
              onKeyEvent: manager.handleRawKeyboardEvent,
              child: MaterialApp(
                home: Material(child: Focus(focusNode: appFocus, child: const SizedBox.expand())),
              ),
            ),
          );
        },
      ),
    );
    await tester.pump();
  }

  /// Counts how often [action] is triggered.
  int Function() count(final HotkeyAction action)
  {
    int calls = 0;
    void listener() {calls++;}
    manager.addListener(func: listener, action: action);
    addTearDown(() {manager.removeListener(func: listener, action: action);});
    return () => calls;
  }
}

Future<void> _focus(final WidgetTester tester, final FocusNode node) async
{
  node.requestFocus();
  await tester.pump();
  expect(node.hasPrimaryFocus, isTrue);
}

void main()
{
  //the focus traversal of the app only consumes the key down while the focus is inside of it
  for (final bool insideApp in <bool>[true, false])
  {
    final String where = insideApp ? "inside the app" : "on the key listener";

    testWidgets("an arrow key triggers its action once with the focus $where", (final WidgetTester tester) async {
      final _Host host = _Host();
      final int Function() nextFrame = host.count(HotkeyAction.timelineNextFrame);
      await host.pump(tester);
      await _focus(tester, insideApp ? host.appFocus : host.listenerFocus);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(nextFrame(), 1);
    });

    testWidgets("tab triggers its action once with the focus $where", (final WidgetTester tester) async {
      final _Host host = _Host();
      final int Function() blending = host.count(HotkeyAction.timelineToggleFrameBlending);
      await host.pump(tester);
      await _focus(tester, insideApp ? host.appFocus : host.listenerFocus);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(blending(), 1);
    });
  }

  testWidgets("an arrow key with a modifier still goes through the shortcuts", (final WidgetTester tester) async {
    final _Host host = _Host();
    final int Function() moveFrame = host.count(HotkeyAction.timelineMoveFrameRight);
    final int Function() nextFrame = host.count(HotkeyAction.timelineNextFrame);
    await host.pump(tester);
    await _focus(tester, host.appFocus);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(moveFrame(), 1);
    expect(nextFrame(), 0);
  });

  group("a key press triggers its action and nothing else", () {
    const LogicalKeyboardKey ctrl = LogicalKeyboardKey.controlLeft;
    const LogicalKeyboardKey shift = LogicalKeyboardKey.shiftLeft;
    const LogicalKeyboardKey alt = LogicalKeyboardKey.altLeft;

    for (final (List<LogicalKeyboardKey>, LogicalKeyboardKey, HotkeyAction) entry in <(List<LogicalKeyboardKey>, LogicalKeyboardKey, HotkeyAction)>[
      (<LogicalKeyboardKey>[ctrl], LogicalKeyboardKey.keyC, HotkeyAction.selectionCopy),
      (<LogicalKeyboardKey>[ctrl, shift], LogicalKeyboardKey.keyC, HotkeyAction.selectionCopyMerged),
      (<LogicalKeyboardKey>[ctrl], LogicalKeyboardKey.keyX, HotkeyAction.selectionCut),
      (<LogicalKeyboardKey>[ctrl], LogicalKeyboardKey.keyV, HotkeyAction.selectionPaste),
      (<LogicalKeyboardKey>[ctrl, shift], LogicalKeyboardKey.keyV, HotkeyAction.selectionPasteAsNewLayer),
      (<LogicalKeyboardKey>[shift], LogicalKeyboardKey.keyV, HotkeyAction.selectionFlipV),
      (<LogicalKeyboardKey>[], LogicalKeyboardKey.keyC, HotkeyAction.selectToolSelectCircle),
      (<LogicalKeyboardKey>[ctrl], LogicalKeyboardKey.keyZ, HotkeyAction.generalUndo),
      (<LogicalKeyboardKey>[ctrl], LogicalKeyboardKey.keyY, HotkeyAction.generalRedo),
      (<LogicalKeyboardKey>[ctrl, shift], LogicalKeyboardKey.keyZ, HotkeyAction.generalRedo),
      (<LogicalKeyboardKey>[ctrl], LogicalKeyboardKey.keyQ, HotkeyAction.generalExit),
      (<LogicalKeyboardKey>[alt], LogicalKeyboardKey.f4, HotkeyAction.generalExit),
      (<LogicalKeyboardKey>[ctrl], LogicalKeyboardKey.keyD, HotkeyAction.selectionDeselect),
      (<LogicalKeyboardKey>[], LogicalKeyboardKey.escape, HotkeyAction.selectionDeselect),
      (<LogicalKeyboardKey>[], LogicalKeyboardKey.delete, HotkeyAction.selectionDelete),
      (<LogicalKeyboardKey>[shift], LogicalKeyboardKey.delete, HotkeyAction.layersDelete),
      (<LogicalKeyboardKey>[], LogicalKeyboardKey.space, HotkeyAction.shadingToggle),
      (<LogicalKeyboardKey>[], LogicalKeyboardKey.arrowUp, HotkeyAction.layersSelectAbove),
      (<LogicalKeyboardKey>[shift], LogicalKeyboardKey.arrowUp, HotkeyAction.layersMoveUp),
      (<LogicalKeyboardKey>[ctrl], LogicalKeyboardKey.arrowUp, HotkeyAction.selectionMoveUp),
      (<LogicalKeyboardKey>[], LogicalKeyboardKey.numpadAdd, HotkeyAction.panZoomZoomIn),
      (<LogicalKeyboardKey>[], LogicalKeyboardKey.enter, HotkeyAction.timelinePlay),
      (<LogicalKeyboardKey>[], LogicalKeyboardKey.pageDown, HotkeyAction.timelineExpand),
    ]) {
      final String keys = <String>[...entry.$1.map((final LogicalKeyboardKey key) => key.debugName ?? ""), entry.$2.debugName ?? ""].join(" + ");

      testWidgets("$keys is ${entry.$3.name}", (final WidgetTester tester) async {
        final _Host host = _Host();
        final List<HotkeyAction> triggered = <HotkeyAction>[];
        for (final HotkeyAction action in HotkeyAction.values) {
          host.manager.addListener(func: () {triggered.add(action);}, action: action);
        }
        await host.pump(tester);
        await _focus(tester, host.appFocus);

        for (final LogicalKeyboardKey modifier in entry.$1) {
          await tester.sendKeyDownEvent(modifier);
        }
        await tester.sendKeyEvent(entry.$2);
        for (final LogicalKeyboardKey modifier in entry.$1.reversed) {
          await tester.sendKeyUpEvent(modifier);
        }

        expect(triggered, <HotkeyAction>[entry.$3]);
      });
    }
  });
}
