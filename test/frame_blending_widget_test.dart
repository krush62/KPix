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
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/constraints/frame_blending_constraints.dart';
import 'package:kpix/models/frame_blending_options.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/timeline/frame_blending_widget.dart';

//the controls, in the order the dialog shows them
const int _enabledSwitch = 0;
const int _wrapBeforeSwitch = 1;
const int _wrapAfterSwitch = 2;
const int _gradualSwitch = 3;
const int _tintingSwitch = 4;
const int _activeLayerSwitch = 5;
const int _framesBeforeSlider = 0;
const int _framesAfterSlider = 1;
const int _opacitySlider = 2;

Switch _switchAt({required final WidgetTester tester, required final int index}) => tester.widgetList<Switch>(find.byType(Switch)).elementAt(index);

KPixSlider _sliderAt({required final WidgetTester tester, required final int index}) => tester.widgetList<KPixSlider>(find.byType(KPixSlider)).elementAt(index);

Future<void> _tapSwitch({required final WidgetTester tester, required final int index}) async
{
  await tester.tap(find.byType(Switch).at(index));
  await tester.pump();
}

Future<void> _dragSlider({required final WidgetTester tester, required final int index, required final double dx}) async
{
  await tester.drag(find.byType(KPixSlider).at(index), Offset(dx, 0));
  await tester.pump();
}

void main()
{
  late FrameBlendingOptions options;
  late int repaints;
  late int dismissed;

  Future<void> pumpDialog(final WidgetTester tester) async
  {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: FrameBlendingWidget(options: options, onDismiss: () => dismissed++)),
    ),);
    //past the scale-in, during which the dialog has no size to tap on
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(()
  {
    GetIt.I.registerSingleton<HotkeyManager>(HotkeyManager());
    GetIt.I.registerSingleton<StatusBarState>(StatusBarState());
    GetIt.I.registerSingleton<ViewState>(ViewState(devicePixelRatio: 1.0));
    options = FrameBlendingOptions();
    repaints = 0;
    dismissed = 0;
    GetIt.I.get<ViewState>().repaintNotifier.addListener(() => repaints++);
  });

  tearDown(() async
  {
    await GetIt.I.reset();
  });

  testWidgets("only the enabled switch can be used until blending is enabled", (final WidgetTester tester) async {
    await pumpDialog(tester);
    expect(_switchAt(tester: tester, index: _enabledSwitch).onChanged, isNotNull);
    for (final int index in <int>[_wrapBeforeSwitch, _wrapAfterSwitch, _gradualSwitch, _tintingSwitch, _activeLayerSwitch])
    {
      expect(_switchAt(tester: tester, index: index).onChanged, isNull, reason: "switch $index");
    }
    for (final int index in <int>[_framesBeforeSlider, _framesAfterSlider, _opacitySlider])
    {
      expect(_sliderAt(tester: tester, index: index).onChanged, isNull, reason: "slider $index");
    }

    await _tapSwitch(tester: tester, index: _enabledSwitch);
    expect(options.enabled.value, isTrue);
    expect(repaints, 1);
    for (final int index in <int>[_wrapBeforeSwitch, _wrapAfterSwitch, _gradualSwitch, _tintingSwitch, _activeLayerSwitch])
    {
      expect(_switchAt(tester: tester, index: index).onChanged, isNotNull, reason: "switch $index");
    }
    for (final int index in <int>[_framesBeforeSlider, _framesAfterSlider, _opacitySlider])
    {
      expect(_sliderAt(tester: tester, index: index).onChanged, isNotNull, reason: "slider $index");
    }
  });

  testWidgets("each switch changes its own option and repaints", (final WidgetTester tester) async {
    options.enabled.value = true;
    await pumpDialog(tester);
    final Map<int, ValueNotifier<bool>> optionOf = <int, ValueNotifier<bool>>{
      _wrapBeforeSwitch: options.wrapAroundBefore,
      _wrapAfterSwitch: options.wrapAroundAfter,
      _gradualSwitch: options.gradualOpacity,
      _tintingSwitch: options.tinting,
      _activeLayerSwitch: options.activeLayerOnly,
    };
    int expectedRepaints = 0;
    for (final MapEntry<int, ValueNotifier<bool>> entry in optionOf.entries)
    {
      final bool before = entry.value.value;
      await _tapSwitch(tester: tester, index: entry.key);
      expectedRepaints++;
      expect(entry.value.value, !before, reason: "switch ${entry.key}");
      expect(repaints, expectedRepaints, reason: "switch ${entry.key}");
      expect(_switchAt(tester: tester, index: entry.key).value, !before, reason: "switch ${entry.key}");
    }
  });

  testWidgets("wrap around can only be used while its side has frames", (final WidgetTester tester) async {
    options.enabled.value = true;
    await pumpDialog(tester);

    options.framesBefore.value = 0;
    await tester.pump();
    expect(_switchAt(tester: tester, index: _wrapBeforeSwitch).onChanged, isNull);
    expect(_switchAt(tester: tester, index: _wrapAfterSwitch).onChanged, isNotNull);

    options.framesAfter.value = 0;
    await tester.pump();
    expect(_switchAt(tester: tester, index: _wrapAfterSwitch).onChanged, isNull);

    options.framesBefore.value = 2;
    await tester.pump();
    expect(_switchAt(tester: tester, index: _wrapBeforeSwitch).onChanged, isNotNull);
    expect(_switchAt(tester: tester, index: _wrapAfterSwitch).onChanged, isNull);
    //no frames on one side says nothing about the other options
    expect(_switchAt(tester: tester, index: _gradualSwitch).onChanged, isNotNull);
  });

  testWidgets("sliders change their own option within its limits and repaint", (final WidgetTester tester) async {
    options.enabled.value = true;
    await pumpDialog(tester);

    await _dragSlider(tester: tester, index: _framesBeforeSlider, dx: 500);
    expect(options.framesBefore.value, FrameBlendingConstraints.frameOffsetMax);
    expect(options.framesAfter.value, FrameBlendingConstraints.framesAfterDefault);
    expect(repaints, greaterThan(0));

    await _dragSlider(tester: tester, index: _framesAfterSlider, dx: -500);
    expect(options.framesAfter.value, FrameBlendingConstraints.frameOffsetMin);
    expect(options.framesBefore.value, FrameBlendingConstraints.frameOffsetMax);

    await _dragSlider(tester: tester, index: _opacitySlider, dx: -500);
    expect(options.opacity.value, FrameBlendingConstraints.opacityMin);
    await _dragSlider(tester: tester, index: _opacitySlider, dx: 500);
    expect(options.opacity.value, FrameBlendingConstraints.opacityMax);
  });

  testWidgets("sliders show their value with the right limits", (final WidgetTester tester) async {
    await pumpDialog(tester);
    options.framesBefore.value = 3;
    options.framesAfter.value = 2;
    options.opacity.value = 0.5;
    await tester.pump();

    final KPixSlider before = _sliderAt(tester: tester, index: _framesBeforeSlider);
    expect((before.value, before.min, before.max, before.decimals), (3.0, 0.0, 4.0, 0));
    final KPixSlider after = _sliderAt(tester: tester, index: _framesAfterSlider);
    expect((after.value, after.min, after.max, after.decimals), (2.0, 0.0, 4.0, 0));
    final KPixSlider opacity = _sliderAt(tester: tester, index: _opacitySlider);
    expect((opacity.value, opacity.min, opacity.max, opacity.decimals), (0.5, 0.1, 0.9, 1));
  });

  testWidgets("a changed option only rebuilds the controls that show it", (final WidgetTester tester) async {
    options.enabled.value = true;
    await pumpDialog(tester);

    List<Widget> controls() => <Widget>[...tester.widgetList<Switch>(find.byType(Switch)), ...tester.widgetList<KPixSlider>(find.byType(KPixSlider))];
    Future<List<int>> changedBy(final void Function() change) async
    {
      final List<Widget> before = controls();
      change();
      await tester.pump();
      final List<Widget> after = controls();
      return <int>[for (int i = 0; i < after.length; i++) if (!identical(before[i], after[i])) i];
    }

    const int sliderOffset = 6;
    expect(await changedBy(() => options.tinting.value = true), <int>[_tintingSwitch]);
    expect(await changedBy(() => options.framesBefore.value = 3), <int>[_wrapBeforeSwitch, sliderOffset + _framesBeforeSlider]);
    expect(await changedBy(() => options.opacity.value = 0.5), <int>[sliderOffset + _opacitySlider]);
  });

  testWidgets("the close button dismisses the dialog", (final WidgetTester tester) async {
    await pumpDialog(tester);
    expect(dismissed, 0);
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(dismissed, 1);
  });
}
