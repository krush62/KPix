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
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/timeline/timeline_widget.dart';

import 'support/selection_harness.dart';

/// Mounts the timeline behind the same project switch as MainWidget, so that
/// toggling [ProjectSession.hasProjectNotifier] remounts it like File > New does.
Future<ProjectSession> _pumpTimeline(final WidgetTester tester, {required final int frameCount}) async
{
  late ProjectSession projectSession;
  await tester.runAsync(() async {
    projectSession = await bootProject(canvasSize: CoordinateSetI(x: 4, y: 4));
  });
  final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
  for (int i = 1; i < frameCount; i++)
  {
    timeline.addNewFrameRight();
  }

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(
        child: ValueListenableBuilder<bool>(
          valueListenable: projectSession.hasProjectNotifier,
          builder: (final BuildContext context, final bool hasProject, final Widget? child) {
            return hasProject ? Column(children: <Widget>[TimeLineWidget(timeline: timeline)]) : const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return projectSession;
}

Future<void> _remount(final WidgetTester tester, final ProjectSession projectSession) async
{
  projectSession.hasProjectNotifier.value = false;
  await tester.pump();
  projectSession.hasProjectNotifier.value = true;
  await tester.pump();
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
  await tester.pump();
}

void main()
{
  testWidgets("the frame hotkeys move one frame after the timeline was remounted", (final WidgetTester tester) async {
    final ProjectSession projectSession = await _pumpTimeline(tester, frameCount: 6);
    final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();

    for (int remounts = 0; remounts < 3; remounts++)
    {
      timeline.selectFrameByIndex(index: 2);
      hotkeyManager.triggerShortcut(action: HotkeyAction.timelineNextFrame);
      expect(timeline.selectedFrameIndex, 3, reason: "next frame after $remounts remounts");
      hotkeyManager.triggerShortcut(action: HotkeyAction.timelinePreviousFrame);
      expect(timeline.selectedFrameIndex, 2, reason: "previous frame after $remounts remounts");
      await _remount(tester, projectSession);
    }

    await _close(tester);
  });

  testWidgets("an unmounted timeline no longer reacts to the frame hotkeys", (final WidgetTester tester) async {
    final ProjectSession projectSession = await _pumpTimeline(tester, frameCount: 3);
    final Timeline timeline = GetIt.I.get<DocumentState>().timeline;

    projectSession.hasProjectNotifier.value = false;
    await tester.pump();
    timeline.selectFrameByIndex(index: 0);
    GetIt.I.get<HotkeyManager>().triggerShortcut(action: HotkeyAction.timelineNextFrame);
    expect(timeline.selectedFrameIndex, 0);

    await _close(tester);
  });
}
