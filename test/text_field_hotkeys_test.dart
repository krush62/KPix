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
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/tool_options/text_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/canvas/canvas_size_widget.dart';
import 'package:kpix/widgets/extra/change_text_tool_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/file/new_project_widget.dart';
import 'package:kpix/widgets/file/save_as_widget.dart';
import 'package:kpix/widgets/file/shader_export_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/palette/save_palette_widget.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

HotkeyManager get _hotkeys => GetIt.I.get<HotkeyManager>();

/// A text field somewhere in the app and the focus node the hotkeys watch for it.
class _Field
{
  final String name;
  final FocusNodeEntry focus;
  final Widget Function() build;
  const _Field({required this.name, required this.focus, required this.build});
}

Widget _exportWidget() => ExportWidget(
  dismiss: () {},
  acceptFile: ({required final ImageExportData exportData, required final ImageExportType exportType}) {},
  acceptPalette: ({required final PaletteExportData saveData, required final PaletteExportType paletteType}) {},
  acceptAnimation: ({required final AnimationExportData exportData, required final AnimationExportType exportType}) {},
);

Widget _canvasSizeWidget() => CanvasSizeWidget(dismiss: () {}, accept: ({required final CoordinateSetI size, required final CoordinateSetI offset}) {});

Widget _newProjectWidget() => NewProjectWidget(open: () {}, accept: ({required final CoordinateSetI size}) {});

final List<_Field> _fields = <_Field>[
  const _Field(name: "the export dialog", focus: FocusNodeEntry.exportFileNameTextFocus, build: _exportWidget),
  _Field(name: "the save as dialog", focus: FocusNodeEntry.saveAsFileNameTextFocus, build: () => SaveAsWidget(dismiss: () {}, callback: null, accept: ({required final String fileName, required final Function()? callback}) {})),
  _Field(name: "the shader export dialog", focus: FocusNodeEntry.shaderExportFileNameTextFocus, build: () => SizedBox(width: 1300, height: 800, child: ShaderExportWidget(dismiss: () {}, accept: ({required final ShaderExportData exportData}) {}))),
  _Field(name: "the save palette dialog", focus: FocusNodeEntry.savePaletteNameTextFocus, build: () => SavePaletteWidget(dismiss: () {}, accept: ({required final PaletteExportData saveData, required final PaletteExportType paletteType}) {})),
  _Field(name: "the change text dialog", focus: FocusNodeEntry.changeTextToolFocus, build: () => ChangeTextToolWidget(dismiss: () {}, accept: ({required final String newText}) {})),
  _Field(name: "the text tool", focus: FocusNodeEntry.textOptionsTextFocus, build: () => SizedBox(
    width: 600,
    height: 400,
    child: Builder(builder: (final BuildContext context) => TextOptions.getWidget(context: context, textOptions: GetIt.I.get<ToolOptions>().textOptions)),
  ),),
  const _Field(name: "the new project width", focus: FocusNodeEntry.newProjectWidthTextFocus, build: _newProjectWidget),
  const _Field(name: "the new project height", focus: FocusNodeEntry.newProjectHeightTextFocus, build: _newProjectWidget),
  const _Field(name: "the canvas width", focus: FocusNodeEntry.canvasSizeWidthTextFocus, build: _canvasSizeWidget),
  const _Field(name: "the canvas height", focus: FocusNodeEntry.canvasSizeHeightTextFocus, build: _canvasSizeWidget),
  const _Field(name: "the canvas x offset", focus: FocusNodeEntry.canvasSizeOffsetXTextFocus, build: _canvasSizeWidget),
  const _Field(name: "the canvas y offset", focus: FocusNodeEntry.canvasSizeOffsetYTextFocus, build: _canvasSizeWidget),
];

Future<void> _settleDown(final WidgetTester tester) async
{
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Mounts [content] below the same keyboard wiring as main.dart, and reports how
/// often the hotkey of the pencil was triggered.
Future<ValueNotifier<int>> _pumpApp(final WidgetTester tester, {required final ValueNotifier<Widget> content}) async
{
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await bootProject(canvasSize: CoordinateSetI(x: 64, y: 64));
  });

  final FocusNode appFocus = FocusNode();
  addTearDown(appFocus.dispose);
  final ValueNotifier<int> triggered = ValueNotifier<int>(0);
  _hotkeys.addListener(func: () => triggered.value++, action: HotkeyAction.selectToolPencil);

  await tester.pumpWidget(ValueListenableBuilder<Map<SingleActivator, VoidCallback>>(
    valueListenable: _hotkeys.callbackMapNotifier,
    builder: (final BuildContext context, final Map<SingleActivator, VoidCallback> callbacks, final Widget? child) {
      return CallbackShortcuts(
        bindings: callbacks,
        child: KeyboardListener(
          focusNode: appFocus,
          autofocus: true,
          onKeyEvent: _hotkeys.handleRawKeyboardEvent,
          child: ToastificationWrapper(child: MaterialApp(
            theme: monochromeTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            //the test font is wider than the real one, and the dialogs have a fixed size
            builder: (final BuildContext context, final Widget? app) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.5)),
              child: app!,
            ),
            home: Material(child: Center(child: ValueListenableBuilder<Widget>(
              valueListenable: content,
              builder: (final BuildContext context, final Widget current, final Widget? child) => current,
            ),),),
          ),),
        ),
      );
    },
  ),);
  await _settleDown(tester);
  return triggered;
}

Future<void> _close(final WidgetTester tester) async
{
  await tester.pumpWidget(const SizedBox.shrink());
  for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
  {
    for (int i = 0; i < frame.layerList.length; i++)
    {
      frame.layerList.getLayer(index: i).dispose();
    }
  }
  await tester.pump(const Duration(seconds: 1));
}

void main()
{
  testWidgets("hotkeys work with no text field around", (final WidgetTester tester) async {
    final ValueNotifier<int> triggered = await _pumpApp(tester, content: ValueNotifier<Widget>(const SizedBox.shrink()));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    expect(triggered.value, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    expect(triggered.value, 2);
    await _close(tester);
  }, semanticsEnabled: false,);

  for (final _Field field in _fields)
  {
    testWidgets("hotkeys stay out of the way of ${field.name} and return after leaving it", (final WidgetTester tester) async {
      final ValueNotifier<int> triggered = await _pumpApp(tester, content: ValueNotifier<Widget>(field.build()));
      final FocusNode node = _hotkeys.getFocusNode(id: field.focus);
      expect(tester.widgetList<TextField>(find.byType(TextField)).map((final TextField f) => f.focusNode), contains(node));

      //the shortcuts follow the focus one frame later
      node.requestFocus();
      await _settleDown(tester);
      expect(node.hasFocus, isTrue);
      expect(_hotkeys.callbackMap, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      expect(triggered.value, 0);

      node.unfocus();
      await _settleDown(tester);
      expect(_hotkeys.callbackMap, isNotEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      expect(triggered.value, 1);
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("hotkeys return when ${field.name} goes away while it has focus", (final WidgetTester tester) async {
      final ValueNotifier<Widget> content = ValueNotifier<Widget>(field.build());
      final ValueNotifier<int> triggered = await _pumpApp(tester, content: content);
      _hotkeys.getFocusNode(id: field.focus).requestFocus();
      await _settleDown(tester);
      expect(_hotkeys.callbackMap, isEmpty);

      content.value = const SizedBox.shrink();
      await _settleDown(tester);
      expect(_hotkeys.callbackMap, isNotEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      expect(triggered.value, 1);
      await _close(tester);
    }, semanticsEnabled: false,);
  }

  group("in a real overlay", () {
    /// Shows [overlay] over the app and focuses the field it asked for.
    Future<void> show(final WidgetTester tester, final KPixOverlay overlay) async
    {
      overlay.show(context: tester.element(find.byType(Center)));
      await _settleDown(tester);
    }

    testWidgets("Enter accepts what was typed and the hotkeys return", (final WidgetTester tester) async {
      final ValueNotifier<int> triggered = await _pumpApp(tester, content: ValueNotifier<Widget>(const SizedBox.shrink()));
      final List<String> accepted = <String>[];
      late final KPixOverlay overlay;
      overlay = getSaveAsDialog(
        onDismiss: () => overlay.hide(),
        onAccept: ({required final String fileName, required final Function()? callback}) {
          accepted.add(fileName);
          overlay.hide();
        },
      );
      await show(tester, overlay);
      await tester.enterText(find.byType(TextField), "abcd");
      await tester.pump();
      tester.testTextInput.updateEditingValue(const TextEditingValue(text: "abXcd", selection: TextSelection.collapsed(offset: 3)));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      expect(triggered.value, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settleDown(tester);
      expect(accepted, <String>["abXcd"]);
      expect(overlay.isVisible, isFalse);
      expect(_hotkeys.callbackMap, isNotEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      expect(triggered.value, 1);
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("Escape closes the dialog and the hotkeys return", (final WidgetTester tester) async {
      final ValueNotifier<int> triggered = await _pumpApp(tester, content: ValueNotifier<Widget>(const SizedBox.shrink()));
      late final KPixOverlay overlay;
      overlay = getChangeTextToolDialog(
        onDismiss: () => overlay.hide(),
        onAccept: ({required final String newText}) {},
        initialText: "text",
      );
      await show(tester, overlay);
      expect(_hotkeys.getFocusNode(id: FocusNodeEntry.changeTextToolFocus).hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      expect(triggered.value, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settleDown(tester);
      expect(overlay.isVisible, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      expect(triggered.value, 1);
      await _close(tester);
    }, semanticsEnabled: false,);
  });
}
