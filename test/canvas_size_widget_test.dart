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
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/constraints/canvas_size_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/canvas/canvas_size_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

//the rows, in the order the dialog shows them
const int _width = 0;
const int _height = 1;
const int _offsetX = 2;
const int _offsetY = 3;

final CoordinateSetI _canvasSize = CoordinateSetI(x: 64, y: 32);

KPixSlider _slider(final WidgetTester tester, final int row) => tester.widgetList<KPixSlider>(find.byType(KPixSlider)).elementAt(row);

TextField _field(final WidgetTester tester, final int row) => tester.widgetList<TextField>(find.byType(TextField)).elementAt(row);

String _text(final WidgetTester tester, final int row) => _field(tester, row).controller!.text;

AppLocalizations _l10n(final WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(CanvasSizeWidget)))!;

/// The positioned parts of the preview: the image, its border, and the two
/// borders of the new size.
List<Positioned> _preview(final WidgetTester tester)
{
  final Finder stack = find.ancestor(of: find.byType(RawImage), matching: find.byType(Stack)).first;
  return tester.widget<Stack>(stack).children.whereType<Positioned>().toList();
}

void _expectPlace(final Positioned part, {required final double left, required final double top, required final double width, required final double height})
{
  expect((part.left, part.top, part.width, part.height), (left, top, width, height));
}

Future<void> _settleDown(final WidgetTester tester) async
{
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _type(final WidgetTester tester, final int row, final String text) async
{
  await tester.enterText(find.byType(TextField).at(row), text);
  await _settleDown(tester);
}

Future<void> _dragSlider(final WidgetTester tester, final int row, final double dx) async
{
  await tester.drag(find.byType(KPixSlider).at(row), Offset(dx, 0));
  await _settleDown(tester);
}

/// A dialog over a booted project, which records what it hands over.
class _Dialog
{
  CoordinateSetI? size;
  CoordinateSetI? offset;
  int dismissed = 0;
}

Future<_Dialog> _pumpDialog(final WidgetTester tester) async
{
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await bootProject(canvasSize: _canvasSize);
  });
  final _Dialog dialog = _Dialog();
  await tester.pumpWidget(ToastificationWrapper(child: MaterialApp(
    theme: monochromeTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Material(child: Center(child: CanvasSizeWidget(
      dismiss: () => dialog.dismissed++,
      accept: ({required final CoordinateSetI size, required final CoordinateSetI offset}) {
        dialog.size = size;
        dialog.offset = offset;
      },
    ),),),
  ),),);
  await _settleDown(tester);
  return dialog;
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

Future<void> _accept(final WidgetTester tester) async
{
  await tester.tap(find.byTooltip(_l10n(tester).apply));
  await _settleDown(tester);
}

void main()
{
  group("rows", () {
    testWidgets("start with the size of the canvas and no offset", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      expect(<String>[for (int row = 0; row < 4; row++) _text(tester, row)], <String>["64", "32", "0", "0"]);
      expect(<double>[for (int row = 0; row < 4; row++) _slider(tester, row).value], <double>[64, 32, 0, 0]);
      await _close(tester);
    });

    testWidgets("are titled in order", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      final AppLocalizations l10n = _l10n(tester);
      final List<String> titles = <String>[l10n.width, l10n.height, "X", "Y"];
      for (int row = 0; row < 4; row++)
      {
        final Finder rowFinder = find.ancestor(of: find.byType(KPixSlider).at(row), matching: find.byType(Row)).first;
        expect(find.descendant(of: rowFinder, matching: find.text(titles[row])), findsOneWidget, reason: titles[row]);
      }
      await _close(tester);
    });

    testWidgets("align their numbers to the end", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      for (int row = 0; row < 4; row++)
      {
        expect(_field(tester, row).textAlign, TextAlign.end, reason: "row $row");
      }
      await _close(tester);
    });

    testWidgets("limit the size to the constraints", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      for (final int row in <int>[_width, _height])
      {
        expect(_slider(tester, row).min, CanvasSizeConstraints.sizeMin.toDouble(), reason: "row $row");
        expect(_slider(tester, row).max, CanvasSizeConstraints.sizeMax.toDouble(), reason: "row $row");
      }
      await _close(tester);
    });

    testWidgets("give each offset the room of its own axis", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      expect((_slider(tester, _offsetX).min, _slider(tester, _offsetX).max), (0.0, 0.0));
      expect((_slider(tester, _offsetY).min, _slider(tester, _offsetY).max), (0.0, 0.0));

      await _type(tester, _width, "100");
      expect((_slider(tester, _offsetX).min, _slider(tester, _offsetX).max), (0.0, 36.0));
      expect((_slider(tester, _offsetY).min, _slider(tester, _offsetY).max), (0.0, 0.0));

      await _type(tester, _height, "50");
      expect((_slider(tester, _offsetX).min, _slider(tester, _offsetX).max), (0.0, 36.0));
      expect((_slider(tester, _offsetY).min, _slider(tester, _offsetY).max), (0.0, 18.0));

      await _type(tester, _width, "40");
      expect((_slider(tester, _offsetX).min, _slider(tester, _offsetX).max), (-24.0, 0.0));

      await _type(tester, _height, "20");
      expect((_slider(tester, _offsetY).min, _slider(tester, _offsetY).max), (-12.0, 0.0));
      await _close(tester);
    });

    testWidgets("follow a limit that changes on its own", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      await _type(tester, _width, "40");
      expect((_slider(tester, _offsetX).min, _slider(tester, _offsetX).max), (-24.0, 0.0));
      //only the minimum moves here, and the offset stays at 0
      await _type(tester, _width, "50");
      expect((_slider(tester, _offsetX).min, _slider(tester, _offsetX).max), (-14.0, 0.0));
      await _close(tester);
    });

    testWidgets("each slider moves its own value and shows it in its own field", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      await _type(tester, _width, "300");
      await _type(tester, _height, "200");
      List<double> values() => <double>[for (int row = 0; row < 4; row++) _slider(tester, row).value];
      for (int row = 0; row < 4; row++)
      {
        final List<double> before = values();
        await _dragSlider(tester, row, 40);
        final List<double> after = values();
        for (int other = 0; other < 4; other++)
        {
          if (other == row)
          {
            expect(after[other], greaterThan(before[other]), reason: "row $row");
            expect(_text(tester, other), after[other].round().toString(), reason: "row $row");
          }
          else if (row >= _offsetX || other < _offsetX)
          {
            //a new size also moves the offsets along with their room
            expect(after[other], before[other], reason: "row $row moved $other");
          }
        }
      }
      await _close(tester);
    });

    testWidgets("each field sets its own value", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester);
      await _type(tester, _width, "300");
      await _type(tester, _height, "200");
      await _type(tester, _offsetX, "10");
      await _type(tester, _offsetY, "20");
      expect(_slider(tester, _width).value, 300);
      expect(_slider(tester, _height).value, 200);
      expect(_slider(tester, _offsetX).value, 10);
      expect(_slider(tester, _offsetY).value, 20);
      await _accept(tester);
      expect(dialog.size, CoordinateSetI(x: 300, y: 200));
      expect(dialog.offset, CoordinateSetI(x: 10, y: 20));
      await _close(tester);
    });

    testWidgets("ignore an offset outside of its room, and one below it", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester);
      await _type(tester, _width, "100");
      await _type(tester, _height, "50");
      await _type(tester, _offsetX, "37");
      await _type(tester, _offsetY, "-1");
      await _accept(tester);
      expect(dialog.offset, CoordinateSetI(x: 0, y: 0));
      await _close(tester);
    });

    testWidgets("take a negative offset for a canvas that shrinks", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester);
      await _type(tester, _width, "32");
      await _type(tester, _height, "16");
      await _type(tester, _offsetX, "-10");
      await _type(tester, _offsetY, "-8");
      await _accept(tester);
      expect(dialog.size, CoordinateSetI(x: 32, y: 16));
      expect(dialog.offset, CoordinateSetI(x: -10, y: -8));
      await _close(tester);
    });

    testWidgets("pull the offset back along with a shrinking size", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      await _type(tester, _width, "100");
      await _type(tester, _offsetX, "30");
      await _type(tester, _width, "70");
      expect(_text(tester, _offsetX), "6");
      expect(_slider(tester, _offsetX).value, 6);
      await _close(tester);
    });
  });

  group("center buttons", () {
    testWidgets("center their own axis in the room it has", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester);
      final AppLocalizations l10n = _l10n(tester);
      await _type(tester, _width, "100");
      await _type(tester, _height, "50");

      await tester.tap(find.byTooltip(l10n.centerHorizontally));
      await _settleDown(tester);
      expect((_text(tester, _offsetX), _text(tester, _offsetY)), ("18", "0"));

      await tester.tap(find.byTooltip(l10n.centerVertically));
      await _settleDown(tester);
      expect((_text(tester, _offsetX), _text(tester, _offsetY)), ("18", "9"));
      await _accept(tester);
      expect(dialog.offset, CoordinateSetI(x: 18, y: 9));
      await _close(tester);
    });
  });

  group("buttons", () {
    testWidgets("apply hands over size and offset", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester);
      await _accept(tester);
      expect(dialog.size, _canvasSize);
      expect(dialog.offset, CoordinateSetI.zero());
      expect(dialog.dismissed, 0);
      await _close(tester);
    });

    testWidgets("cancel dismisses without handing anything over", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester);
      await tester.tap(find.byTooltip(_l10n(tester).cancel));
      await _settleDown(tester);
      expect(dialog.dismissed, 1);
      expect(dialog.size, isNull);
      await _close(tester);
    });
  });

  group("preview", () {
    testWidgets("fits the larger side of canvas and new size", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      //64 wide on 300 pixels
      const double scale = 300 / 64;
      List<Positioned> parts = _preview(tester);
      expect(parts, hasLength(4));
      _expectPlace(parts[0], left: 0, top: 75, width: 64 * scale, height: 32 * scale);
      _expectPlace(parts[1], left: 0, top: 75, width: 64 * scale, height: 32 * scale);
      _expectPlace(parts[2], left: 0, top: 75, width: 64 * scale, height: 32 * scale);
      _expectPlace(parts[3], left: 0, top: 75, width: 64 * scale, height: 32 * scale);

      await _type(tester, _width, "300");
      await _type(tester, _height, "200");
      parts = _preview(tester);
      _expectPlace(parts[0], left: 0, top: 50, width: 64, height: 32);
      _expectPlace(parts[1], left: 0, top: 50, width: 64, height: 32);
      _expectPlace(parts[2], left: 0, top: 50, width: 300, height: 200);
      _expectPlace(parts[3], left: 0, top: 50, width: 300, height: 200);
      await _close(tester);
    });

    testWidgets("follows a width or height that changes on its own", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      await _type(tester, _width, "128");
      //128 wide on 300 pixels
      _expectPlace(_preview(tester)[2], left: 0, top: 112.5, width: 300, height: 75);

      await _type(tester, _height, "64");
      _expectPlace(_preview(tester)[2], left: 0, top: 75, width: 300, height: 150);
      await _close(tester);
    });

    testWidgets("keeps the scale of the canvas when the new size is smaller", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      await _type(tester, _width, "32");
      await _type(tester, _height, "16");
      const double scale = 300 / 64;
      final List<Positioned> parts = _preview(tester);
      _expectPlace(parts[0], left: 75, top: 112.5, width: 64 * scale, height: 32 * scale);
      _expectPlace(parts[2], left: 75, top: 112.5, width: 32 * scale, height: 16 * scale);
      await _close(tester);
    });

    testWidgets("moves the image and its border with each offset, not the new size", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      await _type(tester, _width, "300");
      await _type(tester, _height, "200");

      await _type(tester, _offsetX, "10");
      List<Positioned> parts = _preview(tester);
      _expectPlace(parts[0], left: 10, top: 50, width: 64, height: 32);
      _expectPlace(parts[1], left: 10, top: 50, width: 64, height: 32);
      _expectPlace(parts[2], left: 0, top: 50, width: 300, height: 200);

      await _type(tester, _offsetY, "20");
      parts = _preview(tester);
      _expectPlace(parts[0], left: 10, top: 70, width: 64, height: 32);
      _expectPlace(parts[1], left: 10, top: 70, width: 64, height: 32);
      _expectPlace(parts[3], left: 0, top: 50, width: 300, height: 200);
      await _close(tester);
    });

    testWidgets("draws its borders over each other in the theme's colors", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      final ThemeData theme = Theme.of(tester.element(find.byType(CanvasSizeWidget)));
      (Color, double) border(final Positioned part)
      {
        final BorderSide side = ((part.child as DecoratedBox).decoration as BoxDecoration).border!.top;
        return (side.color, side.width);
      }
      final List<Positioned> parts = _preview(tester);
      expect(border(parts[1]), (theme.primaryColorLight, 4.0));
      expect(border(parts[2]), (theme.primaryColorDark, 3.0));
      expect(border(parts[3]), (theme.primaryColorLight, 1.0));
      await _close(tester);
    });

    testWidgets("shows the image once it has arrived, without filtering", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      final RawImage image = tester.widget<RawImage>(find.byType(RawImage));
      expect((image.image?.width, image.image?.height), (_canvasSize.x, _canvasSize.y));
      expect(image.fit, BoxFit.fill);
      expect(image.filterQuality, FilterQuality.none);
      await _close(tester);
    });
  });

  group("rebuilds", () {
    List<Widget> controls(final WidgetTester tester) => <Widget>[
      ...tester.widgetList<KPixSlider>(find.byType(KPixSlider)),
      ...tester.widgetList<TextField>(find.byType(TextField)),
    ];

    List<int> rebuilt({required final List<Widget> before, required final List<Widget> after}) =>
        <int>[for (int i = 0; i < after.length; i++) if (!identical(before[i], after[i])) i];

    //the sliders come first, then the fields
    const int field = 4;

    testWidgets("an offset only rebuilds its own row", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      await _type(tester, _width, "300");
      await _settleDown(tester);
      final List<Widget> before = controls(tester);
      await _type(tester, _offsetX, "10");
      expect(rebuilt(before: before, after: controls(tester)), <int>[_offsetX, field + _offsetX]);
      await _close(tester);
    });

    testWidgets("new room for an offset rebuilds its slider, not its field", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      final List<Widget> before = controls(tester);
      await _type(tester, _width, "300");
      expect(rebuilt(before: before, after: controls(tester)), <int>[_width, _offsetX, field + _width]);
      await _close(tester);
    });

    testWidgets("the preview follows without rebuilding the rows", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      await _type(tester, _width, "300");
      final Widget before = tester.widget(find.ancestor(of: find.byType(RawImage), matching: find.byType(Stack)).first);
      final List<Widget> controlsBefore = controls(tester);
      await tester.tap(find.byTooltip(_l10n(tester).centerHorizontally));
      await _settleDown(tester);
      expect(identical(tester.widget(find.ancestor(of: find.byType(RawImage), matching: find.byType(Stack)).first), before), isFalse);
      expect(rebuilt(before: controlsBefore, after: controls(tester)), <int>[_offsetX, field + _offsetX]);
      await _close(tester);
    });
  });
}
