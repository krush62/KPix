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
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/frame_blending_options.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/timeline/frame_blending_widget.dart';
import 'package:kpix/widgets/timeline/frame_time_widget.dart';
import 'package:kpix/widgets/timeline/timeline_widget.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

/// Starts what the last change animates, then runs it to its end.
Future<void> _settleDown(final WidgetTester tester) async
{
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Finder _button(final String tooltipStart) => find.byWidgetPredicate((final Widget w) => w is IconButton && (w.tooltip ?? "").startsWith(tooltipStart));

Finder get _timingCells => find.byWidgetPredicate((final Widget w) => w is Text && (w.data ?? "").startsWith("1/"));

AppLocalizations _l10n(final WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(TimeLineWidget)))!;

bool _isUsable(final WidgetTester tester, final Finder button) => tester.widget<IconButton>(button).onPressed != null;

Timeline get _timeline => GetIt.I.get<DocumentState>().timeline;

Future<void> _pumpTimeline(final WidgetTester tester, {required final int frameCount}) async
{
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await bootProject(canvasSize: CoordinateSetI(x: 4, y: 4));
  });
  for (int i = 1; i < frameCount; i++)
  {
    _timeline.addNewFrameRight();
  }
  _timeline.selectFrameByIndex(index: 0);
  await tester.pumpWidget(ToastificationWrapper(child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Material(child: Column(children: <Widget>[TimeLineWidget(timeline: _timeline)])),
  ),),);
  await tester.pump();
  await tester.tap(_button(_l10n(tester).expandTimeline));
  await _settleDown(tester);
}

Future<void> _close(final WidgetTester tester) async
{
  if (_timeline.isPlaying.value)
  {
    _timeline.togglePlaying();
  }
  await _settleDown(tester);
  await tester.pumpWidget(const SizedBox.shrink());
  for (final Frame frame in _timeline.frames.value)
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
  group("frame buttons", () {
    testWidgets("are locked during playback", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 3);
      _timeline.selectFrameByIndex(index: 1);
      await tester.pump();
      final AppLocalizations l10n = _l10n(tester);
      final List<Finder> buttons = <Finder>[
        _button(l10n.moveFrameLeft), _button(l10n.moveFrameRight),
        _button(l10n.addFrameLeft), _button(l10n.addFrameRight),
        _button(l10n.copyFrameLeft), _button(l10n.copyFrameRight),
        _button(l10n.createLinkedFrameLeft), _button(l10n.createLinkedFrameRight),
        _button(l10n.deleteFrame), _button(l10n.frameBlending),
      ];
      for (final Finder button in buttons)
      {
        expect(_isUsable(tester, button), isTrue, reason: "$button");
      }

      _timeline.togglePlaying();
      await tester.pump();
      for (final Finder button in buttons)
      {
        expect(_isUsable(tester, button), isFalse, reason: "$button");
      }

      _timeline.togglePlaying();
      await _settleDown(tester);
      for (final Finder button in buttons)
      {
        expect(_isUsable(tester, button), isTrue, reason: "$button");
      }
      await _close(tester);
    });

    testWidgets("moving follows the selected frame and the number of frames", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 1);
      final AppLocalizations l10n = _l10n(tester);
      final Finder left = _button(l10n.moveFrameLeft);
      final Finder right = _button(l10n.moveFrameRight);
      expect((_isUsable(tester, left), _isUsable(tester, right)), (false, false));

      _timeline.addNewFrameRight();
      _timeline.addNewFrameRight();
      _timeline.selectFrameByIndex(index: 0);
      await tester.pump();
      expect((_isUsable(tester, left), _isUsable(tester, right)), (false, true));

      _timeline.selectFrameByIndex(index: 1);
      await tester.pump();
      expect((_isUsable(tester, left), _isUsable(tester, right)), (true, true));

      _timeline.selectFrameByIndex(index: 2);
      await tester.pump();
      expect((_isUsable(tester, left), _isUsable(tester, right)), (true, false));

      final Frame moved = _timeline.selectedFrame!;
      await tester.tap(left);
      await tester.pump();
      expect(_timeline.frames.value.indexOf(moved), 1);
      await tester.tap(right);
      await tester.pump();
      expect(_timeline.frames.value.indexOf(moved), 2);
      await _close(tester);
    });

    testWidgets("moving also follows frames that leave the selected index alone", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 3);
      final Finder right = _button(_l10n(tester).moveFrameRight);
      _timeline.selectFrameByIndex(index: 1);
      await tester.pump();
      expect(_isUsable(tester, right), isTrue);

      final List<Frame> frames = _timeline.frames.value;
      _timeline.frames.value = frames.sublist(0, 2);
      await tester.pump();
      expect(_timeline.selectedFrameIndex, 1);
      expect(_isUsable(tester, right), isFalse);

      _timeline.frames.value = frames;
      await tester.pump();
      expect(_isUsable(tester, right), isTrue);
      await _close(tester);
    });

    testWidgets("adding reports when there is no room for another frame", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: Timeline.maxFrames);
      final AppLocalizations l10n = _l10n(tester);
      await tester.tap(_button(l10n.addFrameRight));
      await _settleDown(tester);
      //a toast is only inserted a moment after it was asked for
      await _settleDown(tester);
      expect(_timeline.frames.value, hasLength(Timeline.maxFrames));
      expect(find.text(l10n.cannotAddMoreFrames), findsOneWidget);

      toastification.dismissAll(delayForAnimation: false);
      await tester.pump(const Duration(seconds: 10));
      await _close(tester);
    });

    testWidgets("moving names its hotkey", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 1);
      final AppLocalizations l10n = _l10n(tester);
      final HotkeyManager hotkeys = GetIt.I.get<HotkeyManager>();
      final BuildContext context = tester.element(find.byType(TimeLineWidget));
      final String shortcut = hotkeys.getShortcutString(action: HotkeyAction.timelineMoveFrameLeft, context: context);
      expect(shortcut, isNotEmpty);
      expect(tester.widget<IconButton>(_button(l10n.moveFrameLeft)).tooltip, l10n.moveFrameLeft + shortcut);
      expect(tester.widget<IconButton>(_button(l10n.moveFrameRight)).tooltip, l10n.moveFrameRight + hotkeys.getShortcutString(action: HotkeyAction.timelineMoveFrameRight, context: context));
      await _close(tester);
    });

    testWidgets("delete is locked on the last frame", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 2);
      final Finder delete = _button(_l10n(tester).deleteFrame);
      expect(_isUsable(tester, delete), isTrue);
      await tester.tap(delete);
      await tester.pump();
      expect(_timeline.frames.value, hasLength(1));
      expect(_isUsable(tester, delete), isFalse);

      _timeline.addNewFrameRight();
      await tester.pump();
      expect(_isUsable(tester, delete), isTrue);
      await _close(tester);
    });

    testWidgets("each one adds its kind of frame on its side", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 1);
      await tester.runAsync(() async {
        GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.drawing);
        await settle();
      });
      await tester.pump();
      final AppLocalizations l10n = _l10n(tester);
      final Frame source = _timeline.selectedFrame!;

      //linked frames last, as they leave the layers of the source linked
      final List<(String, int, int, bool)> cases = <(String, int, int, bool)>[
        (l10n.addFrameLeft, -1, 1, false),
        (l10n.addFrameRight, 1, 1, false),
        (l10n.copyFrameLeft, -1, 2, false),
        (l10n.copyFrameRight, 1, 2, false),
        (l10n.createLinkedFrameLeft, -1, 2, true),
        (l10n.createLinkedFrameRight, 1, 2, true),
      ];
      for (final (String tooltip, int side, int layers, bool linked) in cases)
      {
        _timeline.selectFrameByIndex(index: _timeline.frames.value.indexOf(source));
        await tester.pump();
        await tester.tap(_button(tooltip));
        await tester.pump();
        final Frame created = _timeline.selectedFrame!;
        expect(created, isNot(source), reason: tooltip);
        expect(_timeline.frames.value.indexOf(created) - _timeline.frames.value.indexOf(source), side, reason: tooltip);
        expect(created.layerList.length, layers, reason: tooltip);
        expect(_timeline.isLayerLinked(layer: created.layerList.getLayer(index: 0)), linked, reason: tooltip);
      }
      await _close(tester);
    });

    testWidgets("a new selection only rebuilds the buttons that depend on it", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 3);
      final AppLocalizations l10n = _l10n(tester);
      final List<IconButton> before = tester.widgetList<IconButton>(find.byType(IconButton)).toList();
      _timeline.selectFrameByIndex(index: 1);
      await tester.pump();
      final List<IconButton> after = tester.widgetList<IconButton>(find.byType(IconButton)).toList();
      final List<String> rebuilt = <String>[for (int i = 0; i < after.length; i++) if (!identical(before[i], after[i])) after[i].tooltip!];
      expect(rebuilt, hasLength(2));
      expect(rebuilt[0], startsWith(l10n.moveFrameLeft));
      expect(rebuilt[1], startsWith(l10n.moveFrameRight));
      await _close(tester);
    });
  });

  group("play buttons", () {
    testWidgets("need a loop of more than one frame and turn into pause", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 3);
      final AppLocalizations l10n = _l10n(tester);
      final Finder play = _button(l10n.play);
      final Finder pause = _button(l10n.pause);
      expect(play, findsNWidgets(2));
      expect(_isUsable(tester, play.first), isTrue);
      expect(_isUsable(tester, play.last), isTrue);

      _timeline.setLoopEndMarker(index: 0);
      await tester.pump();
      expect(_isUsable(tester, play.first), isFalse);
      expect(_isUsable(tester, play.last), isFalse);

      _timeline.resetEndMarker();
      await tester.pump();
      expect(_isUsable(tester, play.first), isTrue);
      expect(_isUsable(tester, play.last), isTrue);

      _timeline.setLoopStartMarker(index: 2);
      await tester.pump();
      expect(_isUsable(tester, play.first), isFalse);
      expect(_isUsable(tester, play.last), isFalse);

      _timeline.resetStartMarker();
      await tester.pump();
      await tester.tap(play.last);
      await tester.pump();
      expect(_timeline.isPlaying.value, isTrue);
      expect(pause, findsNWidgets(2));
      await tester.tap(pause.first);
      await _settleDown(tester);
      expect(_timeline.isPlaying.value, isFalse);
      expect(play, findsNWidgets(2));

      await tester.tap(play.first);
      await tester.pump();
      expect(_timeline.isPlaying.value, isTrue);
      await tester.tap(pause.last);
      await _settleDown(tester);
      expect(_timeline.isPlaying.value, isFalse);
      await _close(tester);
    });
  });

  group("loop markers", () {
    List<int> markedSlots(final WidgetTester tester)
    {
      final Iterable<Container> slots = tester.widgetList<Container>(find.descendant(of: find.byType(TimeLineMiniWidget), matching: find.byType(Container)));
      return <int>[for (int i = 0; i < slots.length; i++) if (slots.elementAt(i).color != Colors.transparent) i];
    }

    testWidgets("the mini strip only shows them for a shortened loop", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 4);
      //a slot before and after each of the frames
      expect(markedSlots(tester), isEmpty);

      _timeline.setLoopStartMarker(index: 1);
      await tester.pump();
      expect(markedSlots(tester), <int>[2, 7]);

      _timeline.setLoopEndMarker(index: 2);
      await tester.pump();
      expect(markedSlots(tester), <int>[2, 5]);

      _timeline.resetStartMarker();
      await tester.pump();
      expect(markedSlots(tester), <int>[0, 5]);

      _timeline.resetEndMarker();
      await tester.pump();
      expect(markedSlots(tester), isEmpty);
      await _close(tester);
    });

    testWidgets("the mini strip follows the frames", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 3);
      final AppLocalizations l10n = _l10n(tester);
      //a frame behind a shortened loop leaves the markers where they are
      _timeline.setLoopEndMarker(index: 1);
      _timeline.selectFrameByIndex(index: 2);
      await tester.pump();
      expect(find.byTooltip(l10n.frameNumber(4)), findsNothing);
      _timeline.addNewFrameRight();
      await tester.pump();
      expect(_timeline.loopEndIndex.value, 1);
      expect(find.byTooltip(l10n.frameNumber(4)), findsOneWidget);
      await _close(tester);
    });

    testWidgets("the marker row follows both of them", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 4);
      final Finder markers = find.byWidgetPredicate((final Widget w) => w is Draggable<TimeLineMarker>);
      final double startBefore = tester.getTopLeft(markers.first).dx;
      final double endBefore = tester.getTopLeft(markers.last).dx;

      _timeline.setLoopStartMarker(index: 1);
      await tester.pump();
      expect(tester.getTopLeft(markers.first).dx, greaterThan(startBefore));
      expect(tester.getTopLeft(markers.last).dx, endBefore);

      _timeline.setLoopEndMarker(index: 2);
      await tester.pump();
      expect(tester.getTopLeft(markers.last).dx, lessThan(endBefore));
      await _close(tester);
    });
  });

  group("frame timing", () {
    testWidgets("Enter applies the picked value to the tapped frame", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 3);
      final int fps = _timeline.frames.value.first.fps.value;
      await tester.tap(_timingCells.at(2));
      await _settleDown(tester);
      expect(_timeline.selectedFrameIndex, 2);
      expect(find.byType(FrameTimeWidget), findsOneWidget);

      tester.widget<FrameTimeWidget>(find.byType(FrameTimeWidget)).valueNotifier.value = fps + 3;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settleDown(tester);
      expect(find.byType(FrameTimeWidget), findsNothing);
      expect(_timeline.frames.value.map((final Frame f) => f.fps.value), <int>[fps, fps, fps + 3]);
      expect(find.text("1/${fps + 3}"), findsOneWidget);
      await _close(tester);
    });

    testWidgets("Escape and cancel change nothing", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 2);
      final int fps = _timeline.frames.value.first.fps.value;
      await tester.tap(_timingCells.at(0));
      await _settleDown(tester);
      tester.widget<FrameTimeWidget>(find.byType(FrameTimeWidget)).valueNotifier.value = fps + 3;
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settleDown(tester);
      expect(find.byType(FrameTimeWidget), findsNothing);
      expect(_timeline.frames.value.first.fps.value, fps);

      await tester.tap(_timingCells.at(0));
      await _settleDown(tester);
      tester.widget<FrameTimeWidget>(find.byType(FrameTimeWidget)).valueNotifier.value = fps + 3;
      await tester.tap(_button(_l10n(tester).cancel));
      await _settleDown(tester);
      expect(find.byType(FrameTimeWidget), findsNothing);
      expect(_timeline.frames.value.first.fps.value, fps);
      await _close(tester);
    });

    testWidgets("the buttons apply to one frame or to all", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 2);
      final AppLocalizations l10n = _l10n(tester);
      final int fps = _timeline.frames.value.first.fps.value;
      await tester.tap(_timingCells.at(1));
      await _settleDown(tester);
      tester.widget<FrameTimeWidget>(find.byType(FrameTimeWidget)).valueNotifier.value = fps + 1;
      await tester.tap(_button(l10n.applyToCurrentFrame));
      await _settleDown(tester);
      expect(_timeline.frames.value.map((final Frame f) => f.fps.value), <int>[fps, fps + 1]);

      await tester.tap(_timingCells.at(0));
      await _settleDown(tester);
      tester.widget<FrameTimeWidget>(find.byType(FrameTimeWidget)).valueNotifier.value = fps + 2;
      await tester.tap(_button(l10n.applyToAllFrames));
      await _settleDown(tester);
      expect(_timeline.frames.value.map((final Frame f) => f.fps.value), <int>[fps + 2, fps + 2]);
      await _close(tester);
    });

    testWidgets("during playback a tap only selects the frame", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 3);
      _timeline.togglePlaying();
      await tester.pump();
      await tester.tap(_timingCells.at(2));
      await tester.pump();
      expect(_timeline.selectedFrameIndex, 2);
      expect(find.byType(FrameTimeWidget), findsNothing);
      await _close(tester);
    });

    testWidgets("a cell rebuilds for its frame time and its selection, not for playback", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 3);
      final AppLocalizations l10n = _l10n(tester);
      Future<List<int>> rebuiltBy(final void Function() change) async
      {
        final Finder cells = find.byWidgetPredicate((final Widget w) => w is Tooltip && w.message == l10n.changeDuration);
        final List<Widget> before = tester.widgetList(cells).toList();
        change();
        await tester.pump();
        final List<Widget> after = tester.widgetList(cells).toList();
        return <int>[for (int i = 0; i < after.length; i++) if (!identical(before[i], after[i])) i];
      }

      expect(await rebuiltBy(() => _timeline.frames.value[1].fps.value = 30), <int>[1]);
      expect(await rebuiltBy(() => _timeline.selectFrameByIndex(index: 2)), <int>[0, 2]);
      expect(await rebuiltBy(_timeline.togglePlaying), isEmpty);
      await _close(tester);
    });
  });

  group("frame blending button", () {
    testWidgets("is highlighted while blending is on and nothing plays", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 2);
      final Finder button = _button(_l10n(tester).frameBlending);
      final FrameBlendingOptions options = GetIt.I.get<FrameBlendingOptions>();
      ButtonStyle style() => tester.widget<IconButton>(button).style!;

      expect(style().backgroundColor, isNull);
      expect(style().iconColor, isNull);

      options.enabled.value = true;
      await tester.pump();
      expect(style().backgroundColor, isNotNull);
      expect(style().iconColor, isNotNull);

      _timeline.togglePlaying();
      await tester.pump();
      expect(style().backgroundColor, isNull);
      expect(style().iconColor, isNull);

      _timeline.togglePlaying();
      await _settleDown(tester);
      expect(style().backgroundColor, isNotNull);

      options.enabled.value = false;
      await tester.pump();
      expect(style().backgroundColor, isNull);
      await _close(tester);
    });

    testWidgets("opens the dialog, which Escape, Enter and its button close", (final WidgetTester tester) async {
      await _pumpTimeline(tester, frameCount: 1);
      final AppLocalizations l10n = _l10n(tester);
      final Finder button = _button(l10n.frameBlending);
      final Finder dialog = find.byType(FrameBlendingWidget);

      await tester.tap(button);
      await _settleDown(tester);
      expect(dialog, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settleDown(tester);
      expect(dialog, findsNothing);

      await tester.tap(button);
      await _settleDown(tester);
      expect(dialog, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settleDown(tester);
      expect(dialog, findsNothing);

      await tester.tap(button);
      await _settleDown(tester);
      await tester.tap(_button(l10n.close));
      await _settleDown(tester);
      expect(dialog, findsNothing);
      await _close(tester);
    });
  });
}
