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
import 'package:kpix/widgets/controls/kpix_text_field.dart';

class _WatchedText extends ValueNotifier<String>
{
  _WatchedText(super.value);
  bool get isWatched => hasListeners;
}

TextField _textField(final WidgetTester tester) => tester.widget<TextField>(find.byType(TextField));

TextEditingController _controller(final WidgetTester tester) => _textField(tester).controller!;

Future<void> _pump(final WidgetTester tester, {required final ValueNotifier<String> text, final ValueChanged<String>? onChanged, final int? maxLength, final FocusNode? focusNode, final TextAlign textAlign = TextAlign.start, final TextStyle? style}) async
{
  await tester.pumpWidget(MaterialApp(home: Material(child: KPixTextField(text: text, onChanged: onChanged, maxLength: maxLength, focusNode: focusNode, textAlign: textAlign, style: style))));
}

void main()
{
  group("KPixTextField", () {
    testWidgets("starts with the text and the caret behind it", (final WidgetTester tester) async {
      await _pump(tester, text: ValueNotifier<String>("hello"));
      expect(_controller(tester).text, "hello");
      expect(_controller(tester).selection, const TextSelection.collapsed(offset: 5));
    });

    testWidgets("writes what is typed to the notifier, and only then calls back", (final WidgetTester tester) async {
      final ValueNotifier<String> text = ValueNotifier<String>("");
      final List<String> seen = <String>[];
      await _pump(tester, text: text, onChanged: (final String value) => seen.add("$value/${text.value}"));
      await tester.enterText(find.byType(TextField), "abc");
      expect(text.value, "abc");
      expect(seen, <String>["abc/abc"]);
    });

    testWidgets("keeps one controller while typing", (final WidgetTester tester) async {
      final ValueNotifier<String> text = ValueNotifier<String>("");
      await _pump(tester, text: text);
      final TextEditingController first = _controller(tester);
      await tester.enterText(find.byType(TextField), "abc");
      await tester.pump();
      text.value = "changed";
      await tester.pump();
      expect(identical(_controller(tester), first), isTrue);
    });

    testWidgets("keeps caret, selection and composing text while typing", (final WidgetTester tester) async {
      final ValueNotifier<String> text = ValueNotifier<String>("");
      await _pump(tester, text: text);
      await tester.enterText(find.byType(TextField), "abcd");
      await tester.pump();

      tester.testTextInput.updateEditingValue(const TextEditingValue(text: "abXcd", selection: TextSelection.collapsed(offset: 3)));
      await tester.pump();
      expect(_controller(tester).selection, const TextSelection.collapsed(offset: 3));

      tester.testTextInput.updateEditingValue(const TextEditingValue(text: "abXcd", selection: TextSelection(baseOffset: 1, extentOffset: 4)));
      await tester.pump();
      expect(_controller(tester).selection, const TextSelection(baseOffset: 1, extentOffset: 4));

      tester.testTextInput.updateEditingValue(const TextEditingValue(text: "ab~Xcd", selection: TextSelection.collapsed(offset: 3), composing: TextRange(start: 2, end: 3)));
      await tester.pump();
      expect(_controller(tester).value.composing, const TextRange(start: 2, end: 3));
      expect(text.value, "ab~Xcd");
    });

    testWidgets("shows a text set from outside, with the caret behind it", (final WidgetTester tester) async {
      final ValueNotifier<String> text = ValueNotifier<String>("start");
      await _pump(tester, text: text);
      text.value = "changed";
      await tester.pump();
      expect(_controller(tester).text, "changed");
      expect(_controller(tester).selection, const TextSelection.collapsed(offset: 7));
    });

    testWidgets("follows another notifier and lets go of the old one", (final WidgetTester tester) async {
      final _WatchedText first = _WatchedText("first");
      final ValueNotifier<String> second = ValueNotifier<String>("second");
      await _pump(tester, text: first);
      expect(first.isWatched, isTrue);
      await _pump(tester, text: second);
      expect(first.isWatched, isFalse);
      expect(_controller(tester).text, "second");
      expect(_controller(tester).selection, const TextSelection.collapsed(offset: 6));

      first.value = "ignored";
      await tester.pump();
      expect(_controller(tester).text, "second");

      second.value = "followed";
      await tester.pump();
      expect(_controller(tester).text, "followed");

      await tester.enterText(find.byType(TextField), "typed");
      expect(second.value, "typed");
      expect(first.value, "ignored");
    });

    testWidgets("stops listening when it is gone", (final WidgetTester tester) async {
      final ValueNotifier<String> text = ValueNotifier<String>("start");
      await _pump(tester, text: text);
      await tester.pumpWidget(const SizedBox.shrink());
      //a disposed controller would throw if it was still updated
      text.value = "after";
      expect(tester.takeException(), isNull);
    });

    testWidgets("disposes its controller with it", (final WidgetTester tester) async {
      await _pump(tester, text: ValueNotifier<String>("start"));
      final TextEditingController controller = _controller(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    testWidgets("hands its settings to the field", (final WidgetTester tester) async {
      final FocusNode focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      const TextStyle style = TextStyle(fontSize: 21);
      await _pump(tester, text: ValueNotifier<String>(""), maxLength: 3, focusNode: focusNode, textAlign: TextAlign.end, style: style);
      expect(_textField(tester).focusNode, focusNode);
      expect(_textField(tester).textAlign, TextAlign.end);
      expect(_textField(tester).style, style);
      expect(_textField(tester).maxLength, 3);
    });

    testWidgets("cuts typed text off at the maximum length", (final WidgetTester tester) async {
      final ValueNotifier<String> text = ValueNotifier<String>("");
      await _pump(tester, text: text, maxLength: 3);
      await tester.enterText(find.byType(TextField), "abcdef");
      expect(text.value, "abc");
    });
  });

  group("showTextInController", () {
    test("leaves the caret alone when the text is already there", () {
      final TextEditingController controller = TextEditingController.fromValue(const TextEditingValue(text: "abcd", selection: TextSelection.collapsed(offset: 2)));
      addTearDown(controller.dispose);
      showTextInController(controller: controller, text: "abcd");
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });

    test("puts other text in with the caret behind it", () {
      final TextEditingController controller = TextEditingController.fromValue(const TextEditingValue(text: "abcd", selection: TextSelection.collapsed(offset: 2)));
      addTearDown(controller.dispose);
      showTextInController(controller: controller, text: "xyz");
      expect(controller.text, "xyz");
      expect(controller.selection, const TextSelection.collapsed(offset: 3));
    });
  });
}
