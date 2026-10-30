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
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/constraints/tool_text_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/tool_options/text_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/canvas/canvas_size_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/extra/change_text_tool_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/file/new_project_widget.dart';
import 'package:kpix/widgets/file/save_as_widget.dart';
import 'package:kpix/widgets/file/shader_export_widget.dart';
import 'package:kpix/widgets/palette/save_palette_widget.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

Finder _field(final int index) => find.byType(TextField).at(index);

TextEditingController _controller(final WidgetTester tester, {final int index = 0}) => tester.widget<TextField>(_field(index)).controller!;

Future<void> _settleDown(final WidgetTester tester) async
{
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Boots a project and shows [child], built once the project exists.
Future<void> _pump(final WidgetTester tester, {required final Widget Function() child, final String? projectName}) async
{
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await bootProject(canvasSize: CoordinateSetI(x: 64, y: 64));
  });
  GetIt.I.get<ProjectSession>().projectName.value = projectName;
  await tester.pumpWidget(ToastificationWrapper(child: MaterialApp(
    theme: monochromeTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    //the test font is wider than the real one, and the dialogs have a fixed size
    builder: (final BuildContext context, final Widget? app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.5)),
      child: app!,
    ),
    home: Material(child: Center(child: child())),
  ),),);
  await _settleDown(tester);
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

/// One of the dialogs with a field for a name or text.
class _TextDialog
{
  final String name;
  final Widget Function({required void Function(String text) onAccept, required GlobalKey key}) build;
  final void Function(GlobalKey key) accept;
  final FocusNodeEntry focus;
  final TextAlign textAlign;
  final int? maxLength;
  final bool startsWithProjectName;
  const _TextDialog({required this.name, required this.build, required this.accept, required this.focus, this.textAlign = TextAlign.end, this.maxLength, this.startsWithProjectName = false});
}

final List<_TextDialog> _textDialogs = <_TextDialog>[
  _TextDialog(
    name: "export",
    focus: FocusNodeEntry.exportFileNameTextFocus,
    startsWithProjectName: true,
    build: ({required final void Function(String text) onAccept, required final GlobalKey key}) => ExportWidget(
      key: key,
      dismiss: () {},
      acceptFile: ({required final ImageExportData exportData, required final ImageExportType exportType}) => onAccept(exportData.fileName),
      acceptPalette: ({required final PaletteExportData saveData, required final PaletteExportType paletteType}) => onAccept(saveData.fileName),
      acceptAnimation: ({required final AnimationExportData exportData, required final AnimationExportType exportType}) => onAccept(exportData.fileName),
    ),
    accept: (final GlobalKey key) => (key.currentState! as ExportWidgetState).accept(),
  ),
  _TextDialog(
    name: "save as",
    focus: FocusNodeEntry.saveAsFileNameTextFocus,
    startsWithProjectName: true,
    build: ({required final void Function(String text) onAccept, required final GlobalKey key}) => SaveAsWidget(
      key: key,
      dismiss: () {},
      callback: null,
      accept: ({required final String fileName, required final Function()? callback}) => onAccept(fileName),
    ),
    accept: (final GlobalKey key) => (key.currentState! as SaveAsWidgetState).accept(),
  ),
  _TextDialog(
    name: "shader export",
    focus: FocusNodeEntry.shaderExportFileNameTextFocus,
    startsWithProjectName: true,
    //its layout fills what the overlay gives it
    build: ({required final void Function(String text) onAccept, required final GlobalKey key}) => SizedBox(
      width: 1300,
      height: 800,
      child: ShaderExportWidget(
        key: key,
        dismiss: () {},
        accept: ({required final ShaderExportData exportData}) => onAccept(exportData.fileName),
      ),
    ),
    accept: (final GlobalKey key) => (key.currentState! as ShaderExportWidgetState).accept(),
  ),
  _TextDialog(
    name: "save palette",
    focus: FocusNodeEntry.savePaletteNameTextFocus,
    maxLength: 16,
    build: ({required final void Function(String text) onAccept, required final GlobalKey key}) => SavePaletteWidget(
      key: key,
      dismiss: () {},
      accept: ({required final PaletteExportData saveData, required final PaletteExportType paletteType}) => onAccept(saveData.fileName),
    ),
    accept: (final GlobalKey key) => (key.currentState! as SavePaletteWidgetState).accept(),
  ),
  _TextDialog(
    name: "change text",
    focus: FocusNodeEntry.changeTextToolFocus,
    textAlign: TextAlign.start,
    maxLength: 32,
    build: ({required final void Function(String text) onAccept, required final GlobalKey key}) => ChangeTextToolWidget(
      key: key,
      dismiss: () {},
      accept: ({required final String newText}) => onAccept(newText),
    ),
    accept: (final GlobalKey key) => (key.currentState! as ChangeTextToolWidgetState).accept(),
  ),
];

void main()
{
  group("typing in the middle of a name", () {
    for (final _TextDialog dialog in _textDialogs)
    {
      testWidgets("keeps the caret in the ${dialog.name} dialog", (final WidgetTester tester) async {
        await _pump(tester, child: () => dialog.build(onAccept: (final String _) {}, key: GlobalKey()));
        await tester.enterText(_field(0), "abcd");
        await tester.pump();
        tester.testTextInput.updateEditingValue(const TextEditingValue(text: "abXcd", selection: TextSelection.collapsed(offset: 3)));
        await tester.pump();
        expect(_controller(tester).text, "abXcd");
        expect(_controller(tester).selection, const TextSelection.collapsed(offset: 3));
        await _close(tester);
      }, semanticsEnabled: false,);

      testWidgets("replaces a selection and keeps the caret in the ${dialog.name} dialog", (final WidgetTester tester) async {
        await _pump(tester, child: () => dialog.build(onAccept: (final String _) {}, key: GlobalKey()));
        await tester.enterText(_field(0), "abcd");
        await tester.pump();
        tester.testTextInput.updateEditingValue(const TextEditingValue(text: "abcd", selection: TextSelection(baseOffset: 1, extentOffset: 3)));
        await tester.pump();
        expect(_controller(tester).selection, const TextSelection(baseOffset: 1, extentOffset: 3));
        tester.testTextInput.updateEditingValue(const TextEditingValue(text: "aXd", selection: TextSelection.collapsed(offset: 2)));
        await tester.pump();
        expect(_controller(tester).text, "aXd");
        expect(_controller(tester).selection, const TextSelection.collapsed(offset: 2));
        await _close(tester);
      }, semanticsEnabled: false,);

      testWidgets("keeps composing text in the ${dialog.name} dialog", (final WidgetTester tester) async {
        await _pump(tester, child: () => dialog.build(onAccept: (final String _) {}, key: GlobalKey()));
        await tester.enterText(_field(0), "abcd");
        await tester.pump();
        tester.testTextInput.updateEditingValue(const TextEditingValue(text: "ab~cd", selection: TextSelection.collapsed(offset: 3), composing: TextRange(start: 2, end: 3)));
        await tester.pump();
        expect(_controller(tester).value.composing, const TextRange(start: 2, end: 3));
        await _close(tester);
      }, semanticsEnabled: false,);

      //the hotkeys stay out of the way by watching these focus nodes
      testWidgets("keeps the focus node and settings of the ${dialog.name} dialog", (final WidgetTester tester) async {
        await _pump(tester, child: () => dialog.build(onAccept: (final String _) {}, key: GlobalKey()));
        final TextField field = tester.widget<TextField>(_field(0));
        expect(field.focusNode, GetIt.I.get<HotkeyManager>().getFocusNode(id: dialog.focus));
        expect(field.textAlign, dialog.textAlign);
        expect(field.maxLength, dialog.maxLength);
        await _close(tester);
      }, semanticsEnabled: false,);

      testWidgets("hands over what was typed in the ${dialog.name} dialog", (final WidgetTester tester) async {
        final List<String> accepted = <String>[];
        final GlobalKey key = GlobalKey();
        await _pump(tester, child: () => dialog.build(onAccept: accepted.add, key: key));
        await tester.enterText(_field(0), "abcd");
        await tester.pump();
        tester.testTextInput.updateEditingValue(const TextEditingValue(text: "abXcd", selection: TextSelection.collapsed(offset: 3)));
        await tester.pump();
        dialog.accept(key);
        expect(accepted, <String>["abXcd"]);
        await _close(tester);
      }, semanticsEnabled: false,);

      if (dialog.startsWithProjectName)
      {
        testWidgets("starts with the caret behind the name in the ${dialog.name} dialog", (final WidgetTester tester) async {
          await _pump(tester, projectName: "project", child: () => dialog.build(onAccept: (final String _) {}, key: GlobalKey()));
          expect(_controller(tester).text, "project");
          expect(_controller(tester).selection, const TextSelection.collapsed(offset: 7));
          await _close(tester);
        }, semanticsEnabled: false,);
      }
    }

    testWidgets("starts with the caret behind the given text in the change text dialog", (final WidgetTester tester) async {
      await _pump(tester, child: () => ChangeTextToolWidget(dismiss: () {}, accept: ({required final String newText}) {}, initialText: "hello"));
      expect(_controller(tester).text, "hello");
      expect(_controller(tester).selection, const TextSelection.collapsed(offset: 5));
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("hands its text style and length to the field of the change text dialog", (final WidgetTester tester) async {
      await _pump(tester, child: () => ChangeTextToolWidget(dismiss: () {}, accept: ({required final String newText}) {}, maxStringLength: 12));
      final TextField field = tester.widget<TextField>(_field(0));
      expect(field.maxLength, 12);
      expect(field.style, Theme.of(tester.element(find.byType(ChangeTextToolWidget))).textTheme.titleLarge);
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("enables the apply button of the change text dialog as it is typed", (final WidgetTester tester) async {
      await _pump(tester, child: () => ChangeTextToolWidget(dismiss: () {}, accept: ({required final String newText}) {}));
      final AppLocalizations l10n = AppLocalizations.of(tester.element(find.byType(ChangeTextToolWidget)))!;
      final Finder apply = find.byWidgetPredicate((final Widget w) => w is IconButton && w.tooltip == l10n.apply);
      expect(tester.widget<IconButton>(apply).onPressed, isNull);
      await tester.enterText(_field(0), "a");
      await tester.pump();
      expect(tester.widget<IconButton>(apply).onPressed, isNotNull);
      await _close(tester);
    }, semanticsEnabled: false,);
  });

  group("the text tool", () {
    TextOptions options() => GetIt.I.get<ToolOptions>().textOptions;

    Future<void> pumpOptions(final WidgetTester tester) async
    {
      await _pump(tester, child: () => SizedBox(
        width: 600,
        height: 400,
        child: Builder(builder: (final BuildContext context) => TextOptions.getWidget(context: context, textOptions: options())),
      ),);
    }

    testWidgets("keeps the caret when typing in the middle", (final WidgetTester tester) async {
      await pumpOptions(tester);
      await tester.enterText(_field(0), "abcd");
      await tester.pump();
      tester.testTextInput.updateEditingValue(const TextEditingValue(text: "abXcd", selection: TextSelection.collapsed(offset: 3)));
      await tester.pump();
      expect(options().text.value, "abXcd");
      expect(_controller(tester).selection, const TextSelection.collapsed(offset: 3));
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("keeps its focus node and maximum length", (final WidgetTester tester) async {
      await pumpOptions(tester);
      final TextField field = tester.widget<TextField>(_field(0));
      expect(field.focusNode, GetIt.I.get<HotkeyManager>().getFocusNode(id: FocusNodeEntry.textOptionsTextFocus));
      expect(field.maxLength, TextConstraints.maxLength);
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("shows a text set from outside, with the caret behind it", (final WidgetTester tester) async {
      await pumpOptions(tester);
      options().text.value = "changed";
      await tester.pump();
      expect(_controller(tester).text, "changed");
      expect(_controller(tester).selection, const TextSelection.collapsed(offset: 7));
      await _close(tester);
    }, semanticsEnabled: false,);
  });

  group("the new project dialog", () {
    Future<void> pumpDialog(final WidgetTester tester, {final void Function(CoordinateSetI size)? onAccept}) async
    {
      await _pump(tester, child: () => NewProjectWidget(key: _newProjectKey, open: () {}, accept: ({required final CoordinateSetI size}) => onAccept?.call(size)));
    }

    testWidgets("keeps the caret when typing in the middle of a number", (final WidgetTester tester) async {
      CoordinateSetI? accepted;
      await pumpDialog(tester, onAccept: (final CoordinateSetI size) => accepted = size);
      await tester.showKeyboard(_field(0));
      tester.testTextInput.updateEditingValue(const TextEditingValue(text: "164", selection: TextSelection.collapsed(offset: 1)));
      await tester.pump();
      expect(_controller(tester).text, "164");
      expect(_controller(tester).selection, const TextSelection.collapsed(offset: 1));
      _newProjectKey.currentState!.accept();
      expect(accepted, CoordinateSetI(x: 164, y: 64));
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("shows a size set from outside the field, with the caret behind it", (final WidgetTester tester) async {
      await pumpDialog(tester);
      expect(_controller(tester).text, "64");
      await tester.tap(find.text("16×16"));
      await _settleDown(tester);
      expect(_controller(tester).text, "16");
      expect(_controller(tester).selection, const TextSelection.collapsed(offset: 2));
      expect(_controller(tester, index: 1).text, "16");

      await tester.drag(find.byType(KPixSlider).first, const Offset(100, 0));
      await _settleDown(tester);
      expect(_controller(tester).text, isNot("16"));
      expect(_controller(tester).selection, TextSelection.collapsed(offset: _controller(tester).text.length));
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("leaves a number out of range alone until the field is left", (final WidgetTester tester) async {
      await pumpDialog(tester);
      await tester.showKeyboard(_field(0));
      tester.testTextInput.updateEditingValue(const TextEditingValue(text: "9999", selection: TextSelection.collapsed(offset: 2)));
      await tester.pump();
      expect(_controller(tester).text, "9999");
      expect(_controller(tester).selection, const TextSelection.collapsed(offset: 2));

      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();
      expect(_controller(tester).text, "64");
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("disposes its controllers", (final WidgetTester tester) async {
      await pumpDialog(tester);
      final List<TextEditingController> controllers = <TextEditingController>[_controller(tester), _controller(tester, index: 1)];
      await _close(tester);
      for (final TextEditingController controller in controllers)
      {
        expect(() => controller.addListener(() {}), throwsFlutterError);
      }
    }, semanticsEnabled: false,);

    testWidgets("cleans up a number written differently", (final WidgetTester tester) async {
      await pumpDialog(tester);
      await tester.showKeyboard(_field(0));
      tester.testTextInput.updateEditingValue(const TextEditingValue(text: "007", selection: TextSelection.collapsed(offset: 3)));
      await tester.pump();
      expect(_controller(tester).text, "7");
      expect(_controller(tester).selection, const TextSelection.collapsed(offset: 1));
      await _close(tester);
    }, semanticsEnabled: false,);
  });

  group("the canvas size dialog", () {
    Future<void> pumpDialog(final WidgetTester tester, {final void Function(CoordinateSetI size, CoordinateSetI offset)? onAccept}) async
    {
      await _pump(tester, child: () => CanvasSizeWidget(key: _canvasSizeKey, dismiss: () {}, accept: ({required final CoordinateSetI size, required final CoordinateSetI offset}) => onAccept?.call(size, offset)));
    }

    testWidgets("keeps the caret when typing in the middle of a size", (final WidgetTester tester) async {
      await pumpDialog(tester);
      for (final int index in <int>[0, 1])
      {
        await tester.showKeyboard(_field(index));
        tester.testTextInput.updateEditingValue(const TextEditingValue(text: "164", selection: TextSelection.collapsed(offset: 1)));
        await tester.pump();
        expect(_controller(tester, index: index).text, "164", reason: "field $index");
        expect(_controller(tester, index: index).selection, const TextSelection.collapsed(offset: 1), reason: "field $index");
      }
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("keeps the caret when typing in the middle of an offset", (final WidgetTester tester) async {
      CoordinateSetI? offset;
      await pumpDialog(tester, onAccept: (final CoordinateSetI s, final CoordinateSetI o) => offset = o);
      //a larger canvas leaves room to move the content around
      await tester.enterText(_field(0), "300");
      await tester.pump();
      await tester.enterText(_field(1), "300");
      await tester.pump();
      for (final int index in <int>[2, 3])
      {
        await tester.showKeyboard(_field(index));
        tester.testTextInput.updateEditingValue(const TextEditingValue(text: "12", selection: TextSelection.collapsed(offset: 2)));
        await tester.pump();
        tester.testTextInput.updateEditingValue(const TextEditingValue(text: "132", selection: TextSelection.collapsed(offset: 2)));
        await tester.pump();
        expect(_controller(tester, index: index).text, "132", reason: "field $index");
        expect(_controller(tester, index: index).selection, const TextSelection.collapsed(offset: 2), reason: "field $index");
      }
      _canvasSizeKey.currentState!.accept();
      expect(offset, CoordinateSetI(x: 132, y: 132));
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("shows a value set from outside the field", (final WidgetTester tester) async {
      await pumpDialog(tester);
      expect(_controller(tester).text, "64");
      await tester.drag(find.byType(KPixSlider).first, const Offset(100, 0));
      await _settleDown(tester);
      expect(_controller(tester).text, isNot("64"));
      expect(_controller(tester).selection, TextSelection.collapsed(offset: _controller(tester).text.length));
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("a smaller size pulls the offset back into range and shows it", (final WidgetTester tester) async {
      await pumpDialog(tester);
      await tester.enterText(_field(0), "300");
      await tester.pump();
      await tester.enterText(_field(2), "100");
      await tester.pump();
      expect(_controller(tester, index: 2).text, "100");
      await tester.enterText(_field(0), "80");
      await tester.pump();
      expect(_controller(tester, index: 2).text, "16");
      await _close(tester);
    }, semanticsEnabled: false,);

    testWidgets("disposes its controllers", (final WidgetTester tester) async {
      await pumpDialog(tester);
      final List<TextEditingController> controllers = <TextEditingController>[for (int i = 0; i < 4; i++) _controller(tester, index: i)];
      await _close(tester);
      for (final TextEditingController controller in controllers)
      {
        expect(() => controller.addListener(() {}), throwsFlutterError);
      }
    }, semanticsEnabled: false,);

    testWidgets("resets an unusable value when the field is left", (final WidgetTester tester) async {
      await pumpDialog(tester);
      await tester.showKeyboard(_field(0));
      tester.testTextInput.updateEditingValue(const TextEditingValue(text: "9999", selection: TextSelection.collapsed(offset: 2)));
      await tester.pump();
      expect(_controller(tester).text, "9999");
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();
      expect(_controller(tester).text, "64");
      await _close(tester);
    }, semanticsEnabled: false,);
  });
}

final GlobalKey<NewProjectWidgetState> _newProjectKey = GlobalKey<NewProjectWidgetState>();
final GlobalKey<CanvasSizeWidgetState> _canvasSizeKey = GlobalKey<CanvasSizeWidgetState>();
