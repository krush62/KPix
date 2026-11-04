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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/infra/stylus_bridge.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/main.dart';
import 'package:kpix/managers/project_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/file_callbacks.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/update_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/canvas/canvas_widget.dart';
import 'package:kpix/widgets/file/new_project_widget.dart';
import 'package:kpix/widgets/main/main_toolbar_widget.dart';
import 'package:kpix/widgets/main/right_bar_widget.dart';
import 'package:kpix/widgets/main/status_bar_widget.dart';
import 'package:kpix/widgets/main/symmetry_widget.dart';
import 'package:kpix/widgets/timeline/timeline_widget.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/selection_harness.dart';
import 'support/widget_harness.dart';

class _FakePaths extends PathProviderPlatform with MockPlatformInterfaceMixin
{
  final String root;
  _FakePaths({required this.root});

  @override
  Future<String?> getApplicationSupportPath() async => p.join(root, "support");

  @override
  Future<String?> getDownloadsPath() async => p.join(root, "downloads");
}

/// Boots the real application, the way main does it, into a directory of its own.
Future<Directory> _bootApp(final WidgetTester tester, {final void Function(String internalDir)? prepare, final Size window = const Size(1600, 900)}) async
{
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final Directory root = (await tester.runAsync(() => Directory.systemTemp.createTemp("kpix_boot_test")))!;
  addTearDown(()
  {
    try
    {
      root.deleteSync(recursive: true);
    }
    catch (_)
    {
      //the operating system may still hold a file for a moment
    }
  });
  final String internalDir = p.join(root.path, "support");
  await tester.runAsync(() async
  {
    await Directory(internalDir).create();
    await Directory(p.join(root.path, "downloads")).create();
    //what it cached belongs to the fake time of the test before
    rootBundle.clear();
    PathProviderPlatform.instance = _FakePaths(root: root.path);
    PackageInfo.setMockInitialValues(appName: "KPix", packageName: "kpix", version: "1.0.0", buildNumber: "1", buildSignature: "");
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await GetIt.I.reset();
    GetIt.I.registerSingleton<Logger>(Logger(level: Level.off));
    GetIt.I.registerSingleton<HotkeyManager>(HotkeyManager());
    GetIt.I.registerSingleton<StylusBridge>(StylusBridge());
    saveFileCallback = null;
    openFileCallback = null;
    cmdLineArgs = <String>[];
    prepare?.call(internalDir);
  });
  await tester.pumpWidget(testApp(textScale: 0.5, child: const KPixApp()));
  return root;
}

/// Waits for the start up, which reads fonts, stamps and files, to get to its dialog or screen.
Future<void> _waitForBoot(final WidgetTester tester, {required final bool Function() until}) async
{
  for (int i = 0; i < 400 && !until(); i++)
  {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    await tester.pump(const Duration(milliseconds: 25));
  }
  expect(until(), isTrue, reason: "the application did not get there");
  await settleUi(tester);
}

/// What the platform runners send when a second launch hands its file over.
Future<void> _handOver(final WidgetTester tester, {required final String path}) async
{
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'app.channel.shared.data',
    const StandardMethodCodec().encodeMethodCall(MethodCall('openFile', path)),
    (final ByteData? _) {},
  );
}

Future<void> _closeApp(final WidgetTester tester) async
{
  await tester.pumpWidget(const SizedBox.shrink());
  if (GetIt.I.isRegistered<DocumentState>())
  {
    for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
    {
      for (int i = 0; i < frame.layerList.length; i++)
      {
        frame.layerList.getLayer(index: i).dispose();
      }
    }
  }
  await tester.pump(const Duration(seconds: 10));
}

void main()
{
  group("the application", ()
  {
    testWidgets("starts on the new project screen and shows a loading screen until then", (final WidgetTester tester) async
    {
      await _bootApp(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(GetIt.I.isRegistered<ProjectManager>(), isTrue);
      expect(await tester.runAsync(() => Directory(p.join(GetIt.I.get<AppPaths>().internalDir, projectsSubDirName)).exists()), isTrue, reason: "the internal directories are in place");
      await _closeApp(tester);
    });

    testWidgets("shows the whole workspace once a project was created", (final WidgetTester tester) async
    {
      await _bootApp(tester);
      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);

      await tester.tap(find.byTooltip(testL10n.createProject));
      await settleUi(tester);
      await tester.runAsync(settle);
      await settleUi(tester);

      expect(GetIt.I.get<ProjectSession>().hasProject, isTrue);
      expect(find.byType(NewProjectWidget), findsNothing);
      for (final Type part in <Type>[MainToolbarWidget, RightBarWidget, CanvasWidget, StatusBarWidget, SymmetryWidget, TimeLineWidget])
      {
        expect(find.byType(part), findsOneWidget, reason: "$part");
      }
      expect(tester.takeException(), isNull);
      await _closeApp(tester);
    });

    testWidgets("asks before leaving a project with changes for a new one", (final WidgetTester tester) async
    {
      await _bootApp(tester);
      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);
      await tester.tap(find.byTooltip(testL10n.createProject));
      await settleUi(tester);
      await tester.runAsync(settle);
      final ProjectSession session = GetIt.I.get<ProjectSession>();
      session.hasChanges.value = true;

      session.hasProjectNotifier.value = false;
      await settleUi(tester);
      expect(find.text(testL10n.thereAreUnsavedChanges), findsOneWidget);

      await tapTooltip(tester, testL10n.cancel);
      expect(find.text(testL10n.thereAreUnsavedChanges), findsNothing);
      expect(session.hasProject, isTrue, reason: "cancel stays with the project");

      session.hasProjectNotifier.value = false;
      await settleUi(tester);
      await tapTooltip(tester, testL10n.no);
      expect(find.byType(NewProjectWidget), findsOneWidget);
      await _closeApp(tester);
    });

    testWidgets("says so when the window is too small", (final WidgetTester tester) async
    {
      await _bootApp(tester, window: const Size(800, 400));

      await _waitForBoot(tester, until: () => find.text(testL10n.thisDeviceDoesNotSupportResolution).evaluate().isNotEmpty);

      expect(find.byType(NewProjectWidget), findsNothing);
      await _closeApp(tester);
    });

    testWidgets("says so when the start up fails", (final WidgetTester tester) async
    {
      await _bootApp(tester, prepare: (final String internalDir)
      {
        PathProviderPlatform.instance = _BrokenPaths();
      },);

      await _waitForBoot(tester, until: () => find.text(testL10n.couldNotInitializeApp).evaluate().isNotEmpty);

      expect(find.byType(NewProjectWidget), findsNothing);
      await _closeApp(tester);
    });

    testWidgets("opens a project from the command line", (final WidgetTester tester) async
    {
      final File project = await _createProject(tester);
      await _bootApp(tester, prepare: (final String internalDir)
      {
        cmdLineArgs = <String>[project.path];
      },);

      await _waitForBoot(tester, until: () => GetIt.I.isRegistered<ProjectSession>() && GetIt.I.get<ProjectSession>().hasProject && find.byType(CanvasWidget).evaluate().isNotEmpty);
      await tester.runAsync(settle);

      expect(find.byType(NewProjectWidget), findsNothing);
      expect(GetIt.I.get<DocumentState>().timeline.frames.value, isNotEmpty);
      await _closeApp(tester);
    });

    testWidgets("opens a file that a second launch hands over", (final WidgetTester tester) async
    {
      final File project = await _createProject(tester);
      await _bootApp(tester);
      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);

      await _handOver(tester, path: project.path);
      await _waitForBoot(tester, until: () => GetIt.I.get<ProjectSession>().hasProject && find.byType(CanvasWidget).evaluate().isNotEmpty);
      await tester.runAsync(settle);

      expect(find.byType(NewProjectWidget), findsNothing);
      expect(GetIt.I.get<ProjectSession>().projectName.value, "project");
      await _closeApp(tester);
    });

    testWidgets("asks before a handed over file replaces unsaved changes", (final WidgetTester tester) async
    {
      final File project = await _createProject(tester);
      await _bootApp(tester);
      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);
      await tester.tap(find.byTooltip(testL10n.createProject));
      await settleUi(tester);
      await tester.runAsync(settle);
      final ProjectSession session = GetIt.I.get<ProjectSession>();
      session.hasChanges.value = true;

      await _handOver(tester, path: project.path);
      await settleUi(tester);
      expect(find.text(testL10n.unsavedChangesSaveFirst), findsOneWidget);

      await tapTooltip(tester, testL10n.cancel);
      expect(find.text(testL10n.unsavedChangesSaveFirst), findsNothing);
      expect(session.projectName.value, isNull, reason: "cancel stays with the project");

      await _handOver(tester, path: project.path);
      await settleUi(tester);
      await tapTooltip(tester, testL10n.no);
      await _waitForBoot(tester, until: () => session.projectName.value == "project");

      expect(find.text(testL10n.unsavedChangesSaveFirst), findsNothing);
      expect(session.hasChanges.value, isFalse);
      await tester.runAsync(settle);
      await _closeApp(tester);
    });

    testWidgets("brings back what it recovered and says so", (final WidgetTester tester) async
    {
      final File project = await _createProject(tester);
      final List<int> bytes = (await tester.runAsync(project.readAsBytes))!;
      await _bootApp(tester, prepare: (final String internalDir)
      {
        final Directory recovery = Directory(p.join(internalDir, recoverSubDirName))..createSync();
        File(p.join(recovery.path, "work.$fileExtensionKpix")).writeAsBytesSync(bytes);
      },);

      await _waitForBoot(tester, until: () => find.text(testL10n.workRecovered).evaluate().isNotEmpty);

      expect(GetIt.I.get<ProjectSession>().hasProject, isTrue);
      await tester.runAsync(settle);
      await _closeApp(tester);
    });

    testWidgets("looks for updates and marks a newer version", (final WidgetTester tester) async
    {
      await _bootApp(tester);
      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);

      //there is no network in a test, so nothing newer can be known
      expect(GetIt.I.get<UpdateState>().hasUpdateNotifier.value, isFalse);
      await _closeApp(tester);
    });

    testWidgets("follows the state of the application", (final WidgetTester tester) async
    {
      await _bootApp(tester);
      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);
      final HotkeyManager hotkeys = GetIt.I.get<HotkeyManager>();
      hotkeys.shiftNotifier.value = true;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(hotkeys.shiftIsPressed, isFalse, reason: "a key released while away is never reported");

      for (final AppLifecycleState state in <AppLifecycleState>[AppLifecycleState.hidden, AppLifecycleState.paused])
      {
        hotkeys.shiftNotifier.value = true;
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
        expect(hotkeys.shiftIsPressed, isFalse, reason: state.name);
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await _closeApp(tester);
    });

    testWidgets("keeps its recovery up to date", (final WidgetTester tester) async
    {
      await _bootApp(tester);
      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);
      await tester.tap(find.byTooltip(testL10n.createProject));
      await settleUi(tester);
      await tester.runAsync(settle);
      GetIt.I.get<ProjectSession>().hasChanges.value = true;
      GetIt.I.get<LayerManager>().addNewLayer(layerType: LayerKind.drawing, addToHistoryStack: false);
      await tester.runAsync(settle);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      for (int i = 0; i < 20; i++)
      {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      final List<FileSystemEntity> files = (await tester.runAsync(() => Directory(p.join(GetIt.I.get<AppPaths>().internalDir, recoverSubDirName)).list().toList()))!;
      expect(files, isNotEmpty);
      await _closeApp(tester);
    });
  });

  group("the main screen", ()
  {
    testWidgets("zooms to fit when the zoom in the status bar is tapped, and shows it", (final WidgetTester tester) async
    {
      await _bootApp(tester);
      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);
      await tester.tap(find.byTooltip(testL10n.createProject));
      await settleUi(tester);
      await tester.runAsync(settle);
      await settleUi(tester);
      final ViewState view = GetIt.I.get<ViewState>();
      final int fitted = view.zoomFactor;
      view.setZoomLevel(val: fitted == 1 ? 2 : 1);
      await tester.pump();
      expect(find.text("${view.zoomFactor * 100}%"), findsOneWidget);

      await tester.tap(find.text("${view.zoomFactor * 100}%"));
      await settleUi(tester);

      expect(view.zoomFactor, fitted);
      await _closeApp(tester);
    });

    testWidgets("shows what the status bar knows", (final WidgetTester tester) async
    {
      await _bootApp(tester);
      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);
      await tester.tap(find.byTooltip(testL10n.createProject));
      await settleUi(tester);
      await tester.runAsync(settle);
      await settleUi(tester);
      final StatusBarState status = GetIt.I.get<StatusBarState>();

      status.setStatusBarCursorPosition(coords: CoordinateSetI(x: 12, y: 34));
      status.setStatusBarToolDimension(width: 5, height: 6);
      status.setStatusBarToolDiagonal(3, 4);
      status.setStatusBarToolAspectRatio(width: 8, height: 4);
      status.setStatusBarToolAngle(startPos: CoordinateSetI(x: 0, y: 0), endPos: CoordinateSetI(x: 5, y: 0));
      await tester.pump();

      expect(find.text("12,34"), findsOneWidget);
      expect(find.text("5.0"), findsOneWidget);
      expect(find.text("2:1"), findsOneWidget);
      expect(find.text("0.0°"), findsOneWidget);

      status.hideStatusBarCursorPosition();
      await tester.pump();
      expect(find.text("12,34"), findsNothing);
      await _closeApp(tester);
    });

    testWidgets("offers tools for drawing layers and options for the others", (final WidgetTester tester) async
    {
      await _bootApp(tester);
      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);
      await tester.tap(find.byTooltip(testL10n.createProject));
      await settleUi(tester);
      await tester.runAsync(settle);
      await settleUi(tester);
      expect(find.byType(MainToolbarWidget), findsOneWidget);

      for (final LayerKind kind in <LayerKind>[LayerKind.reference, LayerKind.grid, LayerKind.shading, LayerKind.dither, LayerKind.drawing])
      {
        GetIt.I.get<LayerManager>().addNewLayer(layerType: kind, select: true, addToHistoryStack: false);
        await settleUi(tester);
        expect(tester.takeException(), isNull, reason: kind.name);
      }
      await tester.runAsync(settle);
      await _closeApp(tester);
    });

    testWidgets("blocks the side bars during playback", (final WidgetTester tester) async
    {
      await _bootApp(tester);
      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);
      await tester.tap(find.byTooltip(testL10n.createProject));
      await settleUi(tester);
      await tester.runAsync(settle);
      await settleUi(tester);
      final Timeline timeline = GetIt.I.get<DocumentState>().timeline;
      final int barriers = find.byType(ModalBarrier).evaluate().length;
      timeline.addNewFrameRight();
      timeline.loopEndIndex.value = 1;
      await tester.runAsync(settle);
      await tester.pump();

      timeline.isPlaying.value = true;
      await tester.pump();
      expect(find.byType(ModalBarrier).evaluate().length, barriers + 2);

      timeline.isPlaying.value = false;
      await settleUi(tester);
      expect(find.byType(ModalBarrier).evaluate().length, barriers);
      await tester.runAsync(settle);
      await _closeApp(tester);
    });

    testWidgets("hides the workspace while there is no project", (final WidgetTester tester) async
    {
      await _bootApp(tester);
      await _waitForBoot(tester, until: () => find.byType(NewProjectWidget).evaluate().isNotEmpty);

      expect(find.byType(CanvasWidget), findsNothing);
      expect(find.byType(StatusBarWidget), findsNothing);
      await _closeApp(tester);
    });
  });
}

class _BrokenPaths extends PathProviderPlatform with MockPlatformInterfaceMixin
{
  @override
  Future<String?> getApplicationSupportPath() async => throw const FileSystemException("no directory for you");

  @override
  Future<String?> getDownloadsPath() async => null;
}

/// A project on disk, written by the application itself.
Future<File> _createProject(final WidgetTester tester) async
{
  final Directory directory = (await tester.runAsync(() => Directory.systemTemp.createTemp("kpix_boot_project")))!;
  addTearDown(()
  {
    try
    {
      directory.deleteSync(recursive: true);
    }
    catch (_)
    {
      //the operating system may still hold a file for a moment
    }
  });
  final File file = File(p.join(directory.path, "project.$fileExtensionKpix"));
  await tester.runAsync(() async
  {
    await bootProject(canvasSize: CoordinateSetI(x: 8, y: 8));
    final String? written = await saveKPixFile(path: file.path);
    expect(written, isNotNull, reason: "setup");
    for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
    {
      for (int i = 0; i < frame.layerList.length; i++)
      {
        frame.layerList.getLayer(index: i).dispose();
      }
    }
  });
  return file;
}
