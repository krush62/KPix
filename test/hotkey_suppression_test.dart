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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// The text field that stands in for the dialog inputs (e.g. the file name of
/// the save as dialog).
const FocusNodeEntry _textFieldEntry = FocusNodeEntry.saveAsFileNameTextFocus;

/// Rebuilds the part of the app that routes the keyboard into the manager: the
/// [KeyboardListener] sits above everything, so it also receives the events
/// that bubble up from a focussed text field.
Future<void> _pumpHost(final WidgetTester tester, final HotkeyManager manager) async
{
  final FocusNode appFocus = FocusNode();
  addTearDown(appFocus.dispose);

  //the listener has to stay above the [MaterialApp], otherwise the routes of
  //the navigator end up above it and it stops receiving the key events as soon
  //as the text field hands the focus back
  await tester.pumpWidget(
    KeyboardListener(
      focusNode: appFocus,
      autofocus: true,
      onKeyEvent: manager.handleRawKeyboardEvent,
      child: MaterialApp(
        home: Material(
          child: TextField(focusNode: manager.getFocusNode(id: _textFieldEntry)),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _focusTextField(final WidgetTester tester, final HotkeyManager manager) async
{
  manager.getFocusNode(id: _textFieldEntry).requestFocus();
  await tester.pump();
}

Future<void> _unfocusTextField(final WidgetTester tester, final HotkeyManager manager) async
{
  manager.getFocusNode(id: _textFieldEntry).unfocus();
  await tester.pump();
}

/// An overlay that is not inserted anywhere but reports itself as visible, so
/// that it can act as a suppression source.
KPixOverlay _visibleOverlay()
{
  return KPixOverlay(
    entry: OverlayEntry(builder: (final BuildContext context) => const SizedBox.shrink()),
    isVisible: true,
  );
}

void main()
{
  group("modifier tracking", ()
  {
    testWidgets("follows the keyboard while the hotkeys are active", (final WidgetTester tester) async {
      final HotkeyManager manager = HotkeyManager();
      await _pumpHost(tester, manager);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(manager.shiftIsPressed, isTrue);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(manager.shiftIsPressed, isFalse);
    });

    testWidgets("stops while a text field has focus", (final WidgetTester tester) async {
      final HotkeyManager manager = HotkeyManager();
      await _pumpHost(tester, manager);
      await _focusTextField(tester, manager);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(manager.shiftIsPressed, isFalse);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(manager.controlIsPressed, isFalse);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      expect(manager.altIsPressed, isFalse);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    });

    testWidgets("is cleared for a modifier that is held when the suppression starts", (final WidgetTester tester) async {
      final HotkeyManager manager = HotkeyManager();
      await _pumpHost(tester, manager);

      //this is the state ctrl+shift+s leaves behind when the save as dialog takes focus
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(manager.shiftIsPressed, isTrue);
      expect(manager.controlIsPressed, isTrue);

      await _focusTextField(tester, manager);
      expect(manager.shiftIsPressed, isFalse);
      expect(manager.controlIsPressed, isFalse);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    });

    testWidgets("is read back from the keyboard when the suppression ends", (final WidgetTester tester) async {
      final HotkeyManager manager = HotkeyManager();
      await _pumpHost(tester, manager);
      await _focusTextField(tester, manager);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(manager.shiftIsPressed, isFalse);

      //the key down was ignored, so leaving the field has to resync the state
      await _unfocusTextField(tester, manager);
      expect(manager.shiftIsPressed, isTrue);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(manager.shiftIsPressed, isFalse);
    });

    testWidgets("stays cleared when the key was released during the suppression", (final WidgetTester tester) async {
      final HotkeyManager manager = HotkeyManager();
      await _pumpHost(tester, manager);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await _focusTextField(tester, manager);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await _unfocusTextField(tester, manager);

      expect(manager.shiftIsPressed, isFalse);
    });
  });

  group("callback suppression", ()
  {
    testWidgets("a focussed text field disables the hotkey callbacks", (final WidgetTester tester) async {
      final HotkeyManager manager = HotkeyManager();
      await _pumpHost(tester, manager);
      expect(manager.callbackMap, isNotEmpty);

      await _focusTextField(tester, manager);
      expect(manager.callbackMap, isEmpty);

      await _unfocusTextField(tester, manager);
      expect(manager.callbackMap, isNotEmpty);
    });

    testWidgets("losing the text field focus does not re-enable the hotkeys below an open overlay", (final WidgetTester tester) async {
      final HotkeyManager manager = HotkeyManager();
      await _pumpHost(tester, manager);

      final KPixOverlay overlay = _visibleOverlay();
      manager.deactivateCallbacks(source: overlay);
      await _focusTextField(tester, manager);
      expect(manager.callbackMap, isEmpty);

      //clicking next to the input of an open dialog must not bring the hotkeys back
      await _unfocusTextField(tester, manager);
      expect(manager.callbackMap, isEmpty);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(manager.shiftIsPressed, isFalse);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      overlay.isVisible = false;
      manager.activateCallbacks(source: overlay);
      expect(manager.callbackMap, isNotEmpty);
    });

    testWidgets("hiding one of two overlays keeps the hotkeys disabled", (final WidgetTester tester) async {
      final HotkeyManager manager = HotkeyManager();
      await _pumpHost(tester, manager);

      final KPixOverlay outer = _visibleOverlay();
      final KPixOverlay inner = _visibleOverlay();
      manager.deactivateCallbacks(source: outer);
      manager.deactivateCallbacks(source: inner);

      inner.isVisible = false;
      manager.activateCallbacks(source: inner);
      expect(manager.callbackMap, isEmpty);

      outer.isVisible = false;
      manager.activateCallbacks(source: outer);
      expect(manager.callbackMap, isNotEmpty);
    });

    testWidgets("suppressing twice from the same source needs only one release", (final WidgetTester tester) async {
      final HotkeyManager manager = HotkeyManager();
      await _pumpHost(tester, manager);

      //show() deactivates unconditionally, even for an already visible overlay
      final KPixOverlay overlay = _visibleOverlay();
      manager.deactivateCallbacks(source: overlay);
      manager.deactivateCallbacks(source: overlay);
      expect(manager.callbackMap, isEmpty);

      overlay.isVisible = false;
      manager.activateCallbacks(source: overlay);
      expect(manager.callbackMap, isNotEmpty);
    });

    testWidgets("a source that was torn down without releasing does not disable the hotkeys forever", (final WidgetTester tester) async {
      final HotkeyManager manager = HotkeyManager();
      await _pumpHost(tester, manager);

      //an overlay whose widget was disposed while it was still shown
      final KPixOverlay leaked = _visibleOverlay();
      manager.deactivateCallbacks(source: leaked);
      expect(manager.callbackMap, isEmpty);
      leaked.isVisible = false;

      //the next re-evaluation has to drop it again
      await _focusTextField(tester, manager);
      await _unfocusTextField(tester, manager);
      expect(manager.callbackMap, isNotEmpty);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(manager.shiftIsPressed, isTrue);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    });
  });

  group("programmatic triggers", ()
  {
    testWidgets("an action is triggered while an overlay suppresses the hotkeys", (final WidgetTester tester) async {
      final HotkeyManager manager = HotkeyManager();
      await _pumpHost(tester, manager);

      int calls = 0;
      void listener() {calls++;}
      manager.addListener(func: listener, action: HotkeyAction.panZoomOptimalZoom);
      addTearDown(() {manager.removeListener(func: listener, action: HotkeyAction.panZoomOptimalZoom);});

      //fitting the canvas is requested while the loading dialog is still up
      final KPixOverlay loadingDialog = _visibleOverlay();
      manager.deactivateCallbacks(source: loadingDialog);
      manager.triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
      expect(calls, 1);

      loadingDialog.isVisible = false;
      manager.activateCallbacks(source: loadingDialog);
      manager.triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
      expect(calls, 2);
    });

    testWidgets("an action with several key bindings is triggered only once", (final WidgetTester tester) async {
      final HotkeyManager manager = HotkeyManager();
      await _pumpHost(tester, manager);

      int calls = 0;
      void listener() {calls++;}
      //deselect is bound to both [Escape] and [Ctrl]+[D]
      manager.addListener(func: listener, action: HotkeyAction.selectionDeselect);
      addTearDown(() {manager.removeListener(func: listener, action: HotkeyAction.selectionDeselect);});

      manager.triggerShortcut(action: HotkeyAction.selectionDeselect);
      expect(calls, 1);
    });
  });
}
