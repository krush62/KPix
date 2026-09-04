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

import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_logger.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/project_manager.dart';
import 'package:kpix/managers/reference_image_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/update_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:kpix/util/helpers/format_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/helpers/update_helper.dart';
import 'package:kpix/util/messages.dart';
import 'package:kpix/widgets/canvas/canvas_widget.dart';
import 'package:kpix/widgets/controls/kpix_splitter.dart';
import 'package:kpix/widgets/main/main_toolbar_widget.dart';
import 'package:kpix/widgets/main/right_bar_widget.dart';
import 'package:kpix/widgets/main/status_bar_widget.dart';
import 'package:kpix/widgets/main/symmetry_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/stamps/stamp_manager_widget.dart';
import 'package:kpix/widgets/timeline/frame_blending_options.dart';
import 'package:kpix/widgets/timeline/timeline_widget.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:version/version.dart';

/// Notifier for theme change.
class ThemeNotifier extends ChangeNotifier
{
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode
  {
   return _themeMode;
  }

  set themeMode(final ThemeMode theme)
  {
    _themeMode = theme;
    notifyListeners();
  }

  @override
  void notifyListeners()
  {
    super.notifyListeners();
  }
}

/// Currently used theme (system/light/dark).
final ThemeNotifier themeSettings = ThemeNotifier();
/// Default size of the desktop application.
const Size defaultDesktopSize = Size(1600, 900);
/// Minimum screen resolution size a device needs to have.
const Size minimumApplicationSize = Size(1200, 600);

/// Command line arguments.
late List<String> cmdLineArgs; //--dart-entrypoint-args <args>

void main(final List<String> args)
{
  final KPixLogger logger = KPixLogger();
  GetIt.I.registerSingleton<Logger>(logger);
  logger.i("Starting application");
  cmdLineArgs = args;
  WidgetsFlutterBinding.ensureInitialized();
  logger.logSystemInfo();
  final HotkeyManager hotkeyManager = HotkeyManager();
  final FocusNode focusNode = FocusNode();
  GetIt.I.registerSingleton<HotkeyManager>(hotkeyManager);
  runApp(
    ValueListenableBuilder<Map<SingleActivator, VoidCallback>>(
      valueListenable: hotkeyManager.callbackMapNotifier,
      builder: (final BuildContext context, final Map<SingleActivator, VoidCallback> callbacks, final Widget? child) {
        return CallbackShortcuts(
          bindings: callbacks,
          child: KeyboardListener(

            focusNode: focusNode,
            autofocus: true,
            onKeyEvent: hotkeyManager.handleRawKeyboardEvent,
            child: AnimatedBuilder(
              animation: themeSettings,
              builder: (final BuildContext context, final Widget? child) {
                return ToastificationWrapper(
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    home: const KPixApp(),
                    theme: monochromeTheme,
                    darkTheme: monochromeThemeDark,
                    themeMode: themeSettings.themeMode,
                  ),
                );
              },
            ),
          ),
        );
      },
    ),
  );

  if (isDesktop()) {
    doWhenWindowReady(() {
      appWindow.minSize = defaultDesktopSize;
      appWindow.size = defaultDesktopSize;
      appWindow.alignment = Alignment.center;
      appWindow.title = "KPix";
      appWindow.maximize();
      appWindow.show();
    });
  } else {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}

class KPixApp extends StatefulWidget
{
  //This is ugly, I know
  static Function({Function()? callback})? saveCallbackFunc;
  static Function({Function()? callback})? openCallbackFunc;
  const KPixApp({super.key});

  @override
  State<KPixApp> createState() => _KPixAppState();
}


class _KPixAppState extends State<KPixApp> with WidgetsBindingObserver
{
  final ValueNotifier<bool> initialized = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isFocused = ValueNotifier<bool>(true);
  late KPixOverlay _closeWarningDialog;
  late KPixOverlay _newProjectDialog;
  late KPixOverlay _saveNewWarningDialog;
  late Timer _recoverTimer;
  late AppLifecycleState _lastAppLifeCycleState;
  HistoryState? _lastHistoryState;


  @override
  void initState()
  {
    super.initState();
    _initPrefs().then((final void value) {
      WidgetsBinding.instance.addObserver(this);
      _lastAppLifeCycleState = AppLifecycleState.resumed;
      if (!kIsWeb)
      {
        _recoverTimer = Timer.periodic(const Duration(minutes: _MainLayoutOptions.recoverCheckIntervalMinutes), (final Timer _) {_recoverCheck();});
      }
    },);

  }

  @override
  void dispose()
  {
    WidgetsBinding.instance.removeObserver(this);
    _recoverTimer.cancel();
    if (GetIt.I.isRegistered<ProjectManager>())
    {
      GetIt.I.get<ProjectManager>().dispose();
    }
    super.dispose();
  }

  void _recoverCheck({final bool ignoreState = false})
  {
    _lastAppLifeCycleState = WidgetsBinding.instance.lifecycleState ?? _lastAppLifeCycleState;
    final AppState appState = GetIt.I.get<AppState>();
    if (appState.hasProject && appState.hasChanges.value)
    {
      if ((ignoreState || _lastAppLifeCycleState == AppLifecycleState.resumed) && GetIt.I.get<HistoryManager>().getCurrentState() != _lastHistoryState)
      {
        _lastHistoryState = GetIt.I.get<HistoryManager>().getCurrentState();
        clearRecoverDir().then((final void value)
        {
          final String fileName = appState.projectName.value ?? recoverFileName;
          final String finalPath = p.join(GetIt.I.get<AppPaths>().internalDir, recoverSubDirName, "$fileName.$fileExtensionKpix");
          saveKPixFile(appState: appState, path: finalPath);
        },);
      }
    }
    else
    {
      clearRecoverDir();
    }
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state)
  {
    switch (state)
    {
      case AppLifecycleState.detached:
        //This state is only entered on iOS, Android, and web, although on all platforms it is the default state before the application begins running.
        break;
      case AppLifecycleState.resumed:
        //On all platforms, this state indicates that the application is in the default running mode for a running application that has input focus and is visible.
        //a frozen process does not receive file system events, and on Android the
        //watch itself can be dropped, so the project cache is refreshed here
        _isFocused.value = true;
        if (!kIsWeb && initialized.value && GetIt.I.isRegistered<ProjectManager>())
        {
          unawaited(GetIt.I.get<ProjectManager>().reindex());
        }
      case AppLifecycleState.inactive:
        //At least one view of the application is visible, but none have input focus. The application is otherwise running normally.
        _isFocused.value = false;
        if (!kIsWeb && initialized.value)
        {
          _recoverCheck(ignoreState: true);
        }
      case AppLifecycleState.hidden:
        _isFocused.value = false;
        //All views of an application are hidden, either because the application is about to be paused (on iOS and Android), or because it has been minimized or placed on a desktop that is no longer visible (on non-web desktop), or is running in a window or tab that is no longer visible (on the web).
        //break;
      case AppLifecycleState.paused:
        _isFocused.value = false;
        //The application is not currently visible to the user, and not responding to user input.
        //break;
    }

  }

  /// Exits the application and clears the recovery directory.
  void exitApplication({final int exitCode = 0})
  {
    clearRecoverDir().then((final void value)
    {
      if (Platform.isAndroid)
      {
        SystemNavigator.pop();
      }
      else
      {
        exit(exitCode);
      }
    },);
  }

  Future<void> _initPrefs() async
  {
    final Logger logger = GetIt.I.get<Logger>();
    try
    {
      logger.i("Initializing preferences");
      final SharedPreferences sPrefs = await SharedPreferences.getInstance();
      logger.i("Initializing fonts");
      final Map<PixelFontType, KFont> fontMap = await FontManager.readFonts();
      logger.i("Creating Tool Options");
      GetIt.I.registerSingleton<ToolOptions>(ToolOptions(fontManager: FontManager(kFontMap: fontMap)));
      logger.i("Creating Preferences");
      GetIt.I.registerSingleton<PreferenceManager>(PreferenceManager(sPrefs));
      logger.i("Creating Blending Options");
      GetIt.I.registerSingleton<FrameBlendingOptions>(FrameBlendingOptions());
      logger.i("Creating Shader Options");
      GetIt.I.registerSingleton<ShaderOptions>(ShaderOptions());
      logger.i("Getting Directories");
      final String exportDirString = await findExportDir();
      logger.i("Export Dir: $exportDirString");
      final String internalDirString = await findInternalDir();
      logger.i("Internal Dir: $internalDirString");
      final ProjectDirectoryResolveResult projectDirResult = await resolveProjectsDir(internalDir: internalDirString);
      logger.i("Projects Dir: ${projectDirResult.resolvedDir}");

      if (!context.mounted)
      {
        const String contextNotMountedMessage = "BuildContext not mounted.";
        logger.e(contextNotMountedMessage);
        return;
      }


      final BuildContext c = context;
      final double devicePixelRatio = MediaQuery.of(c).devicePixelRatio;
      logger.i("Pixel Ratio: $devicePixelRatio");
      logger.i("Creating App Paths");
      GetIt.I.registerSingleton<AppPaths>(AppPaths(exportDir: exportDirString, internalDir: internalDirString, projectsDir: projectDirResult.resolvedDir));
      logger.i("Creating Update State");
      GetIt.I.registerSingleton<UpdateState>(UpdateState());
      logger.i("Creating Status Bar State");
      GetIt.I.registerSingleton<StatusBarState>(StatusBarState());
      logger.i("Creating View State");
      GetIt.I.registerSingleton<ViewState>(ViewState(devicePixelRatio: devicePixelRatio));
      logger.i("Creating Palette State");
      GetIt.I.registerSingleton<PaletteState>(PaletteState());
      logger.i("Creating App State");
      final AppState appState = AppState();

      GetIt.I.registerSingleton<AppState>(appState);
      logger.i("Creating Tool State");
      GetIt.I.registerSingleton<ToolState>(ToolState());
      final Size logicalSize = MediaQuery.of(c).size;
      logger.i("Logical Size: $logicalSize");

      if (logicalSize.width < minimumApplicationSize.width || logicalSize.height < minimumApplicationSize.height)
      {
        const String wrongResolutionMessage = "This device does not support the minimum logical resolution to run this application.";
        logger.w(wrongResolutionMessage);
        final KPixOverlay resolutionDialog = kIsWeb ? getLoadingDialog(message: wrongResolutionMessage, textStyle: Theme.of(c).textTheme.titleMedium) : getSingleButtonDialog(onAction: () => exitApplication(), message: wrongResolutionMessage);
        resolutionDialog.show(context: c);
        return;
      }

      logger.i("Creating Stamp Manager");
      final StampManager stampManager = StampManager();
      await stampManager.loadAllStamps();
      GetIt.I.registerSingleton<StampManager>(stampManager);

      logger.i("Creating Package Info");
      GetIt.I.registerSingleton<PackageInfo>(await PackageInfo.fromPlatform());
      logger.i("Creating Reference Image Manager");
      GetIt.I.registerSingleton<ReferenceImageManager>(ReferenceImageManager());
      logger.i("Creating History Manager");
      GetIt.I.registerSingleton<HistoryManager>(HistoryManager(maxEntries: GetIt.I.get<PreferenceManager>().behaviorPreferenceContent.undoSteps.value));
      logger.i("Creating Project Manager");
      final ProjectManager projectManager = ProjectManager();
      GetIt.I.registerSingleton<ProjectManager>(projectManager);
      //indexing the project directory runs in the background, so that the cache
      //is warm by the time the project manager is opened without holding up the
      //start up here
      unawaited(projectManager.start());

      //CREATE DIALOG OVERLAYS
      _closeWarningDialog = getThreeButtonDialog(
        onYes: _closeWarningYes,
        onNo: _closeWarningNo,
        onCancel: _closeAllMenus,
        outsideCancelable: false,
        message: "There are unsaved changes, do you want to save first?",
      );

      _saveNewWarningDialog = getThreeButtonDialog(
        onYes: _saveNewWarningYes,
        onNo: _saveNewWarningNo,
        onCancel: _saveNewWarningCancel,
        outsideCancelable: false,
        message: "There are unsaved changes, do you want to save first?",
      );
      _newProjectDialog = getNewProjectDialog(
        onDismiss: !kIsWeb ? () {exitApplication();} : null,
        onAccept: _newFilePressed,
        onOpen: _openPressed,
      );

      GetIt.I.get<HotkeyManager>().addListener(action: HotkeyAction.generalExit, func: _closePressed);

      final ThemeMode currentTheme = GetIt.I.get<PreferenceManager>().guiPreferenceContent.themeType.value;
      if (themeSettings.themeMode != currentTheme)
      {
        logger.i("Changing Theme Mode");
        themeSettings.themeMode = currentTheme;
      }
      appState.hasProjectNotifier.addListener(_hasProjectChanged);

      if (!kIsWeb)
      {
        logger.i("Creating internal directories if needed.");
        try
        {
          await createInternalDirectories();
        }
        catch (e, s)
        {
          const String couldNotCreateDirsMessage = "Could not create internal directories.";
          logger.w(couldNotCreateDirsMessage, error: e, stackTrace: s);
          if (c.mounted)
          {
            final KPixOverlay dirDialog = getSingleButtonDialog(onAction: () => exitApplication(), message: couldNotCreateDirsMessage);
            dirDialog.show(context: c);
          }
        }

        await _handleInitialFile();

        if (projectDirResult.useCustom && !projectDirResult.customValid)
        {
          final PreferenceManager preferenceManager = GetIt.I.get<PreferenceManager>();
          preferenceManager.behaviorPreferenceContent.useCustomProjectDirectory.value = false;
          preferenceManager.behaviorPreferenceContent.customProjectDirectory.value = "";
          showMessage(text: "Custom Project directory invalid. Switching to default directory.");
        }


        if (!kIsWeb && Platform.isAndroid && c.mounted)
        {
          await _checkAllFilesAccessOnStartup(context: c);
        }

        if (isDesktop())
        {
          getLatestVersionInfo().then((final UpdateInfoPackage? value) {
            _updateDataReceived(updateInfo: value);
          });
        }
      }
      else
      {
        _hasProjectChanged();
      }
      final String versionString = GetIt.I.get<PackageInfo>().version;
      initialized.value = true;
      logger.i("Application initialized. Version: $versionString");


    }
    catch (e, s)
    {
      const String couldNotInitializeAppMessage = "Could not initialize the application.";
      logger.w(couldNotInitializeAppMessage, error: e, stackTrace: s);
      if (context.mounted)
      {
        final BuildContext c = context;
        final KPixOverlay dirDialog = kIsWeb ? getLoadingDialog(message: couldNotInitializeAppMessage, textStyle: Theme.of(c).textTheme.titleMedium) : getSingleButtonDialog(onAction: () => exitApplication(), message: couldNotInitializeAppMessage);
        dirDialog.show(context: c);
      }
    }


  }

  void _updateDataReceived({required final UpdateInfoPackage? updateInfo})
  {
    final Logger logger = GetIt.I.get<Logger>();
    bool hasUpdate = false;
    if (updateInfo != null)
    {
      logger.i("Received update information. Available version: ${updateInfo.version}.");
      final Version? currentVersion = convertStringToVersion(version: GetIt.I.get<PackageInfo>().version);
      if (currentVersion != null)
      {
        if (updateInfo.version > currentVersion)
        {
          logger.i("Newer version available at ${updateInfo.url}.");
          GetIt.I.get<UpdateState>().updatePackage = updateInfo;
          hasUpdate = true;
        }
      }
      else
      {
        logger.w("Could not determine current version.");

      }
    }
    GetIt.I.get<UpdateState>().hasUpdateNotifier.value = hasUpdate;
  }



  Future<void> _checkAllFilesAccessOnStartup({required final BuildContext context}) async
  {
    final String defaultProjectsDir = getDefaultProjectsDir(internalDir: GetIt.I.get<AppPaths>().internalDir);
    if (!p.equals(GetIt.I.get<AppPaths>().projectsDir, defaultProjectsDir) && !await hasAllFilesAccess())
    {
      GetIt.I.get<Logger>().w("Using a custom project directory without all files access.");
      final KPixOverlay permissionDialog = getAllFilesAccessDialog(
        message: 'A custom project directory is used, but KPix does not have the "All files access" permission. Project files created by other apps (e.g. sync tools) might not be shown.\nDo you want to open the system settings to grant the permission?',
      );
      if (context.mounted)
      {
        permissionDialog.show(context: context);
      }
    }
  }

  Future<void> _handleInitialFile() async
  {
    final AppState appState = GetIt.I.get<AppState>();
    final PreferenceManager preferenceManager = GetIt.I.get<PreferenceManager>();

    bool fromRecovery = false;
    String? initialFilePath = await getRecoveryFile();

    if (initialFilePath == null)
    {
      if (cmdLineArgs.isNotEmpty && isDesktop())
      {
        initialFilePath = cmdLineArgs.first;
      }
      else if (!kIsWeb && Platform.isAndroid)
      {
        const MethodChannel channel = MethodChannel('app.channel.shared.data');
        initialFilePath = await channel.invokeMethod('getSharedFile');
      }

      await importProject(path: initialFilePath);
      final String fileName = extractFilenameFromPath(path: initialFilePath);
      final String expectedFileName = initialFilePath = p.join(GetIt.I.get<AppPaths>().projectsDir, fileName);
      final File expectedFile = File(expectedFileName);

      if (await expectedFile.exists())
      {
        initialFilePath = expectedFileName;
      }
      else
      {
        initialFilePath = null;
      }
    }
    else
    {
      fromRecovery = true;
    }

    if (initialFilePath != null && initialFilePath.isNotEmpty)
    {
      final LoadFileSet lfs = await loadKPixFile(
          fileData: null,
          path: initialFilePath,
          drawingLayerSettingsConstraints: preferenceManager.drawingLayerSettingsConstraints,
          shadingLayerSettingsConstraints: preferenceManager.shadingLayerSettingsConstraints,
          frameConstraints: preferenceManager.frameConstraints,
      );
      if (lfs.path != null && lfs.historyState != null)
      {
        await appState.restoreFromFile(loadFileSet: lfs, setHasChanges: fromRecovery);
        appState.hasProjectNotifier.value = true;
        _newProjectDialog.hide();
        showMessage(text: "work recovered");
      }
      else
      {
        _hasProjectChanged();
      }
    }
    else
    {
      _hasProjectChanged();
    }
  }

  void _hasProjectChanged()
  {
    if (!GetIt.I.get<AppState>().hasProject)
    {
      _newFile();
    }
  }

  void _closePressed()
  {
    if (GetIt.I.get<AppState>().hasChanges.value)
    {
      _closeWarningDialog.show(context: context);
    }
    else
    {
      GetIt.I.get<Logger>().i("Exiting application.");
      exitApplication();
    }
  }

  void _closeWarningYes()
  {
    if (KPixApp.saveCallbackFunc != null)
    {
      KPixApp.saveCallbackFunc?.call(callback: _saveBeforeClosedFinished);
    }
  }


  void _closeWarningNo()
  {
    exitApplication();
  }

  void _saveBeforeClosedFinished()
  {
    exitApplication();
  }

  void _closeAllMenus()
  {
    _closeWarningDialog.hide();
  }

  void _newFile()
  {
    if (GetIt.I.get<AppState>().hasChanges.value)
    {
      _saveNewWarningDialog.show(context: context);
    }
    else
    {
      _newProjectDialog.show(context: context);

    }
  }

  void _saveNewWarningYes()
  {
    if (KPixApp.saveCallbackFunc != null)
    {
      KPixApp.saveCallbackFunc?.call(callback: _saveBeforeNewFinished);
    }

  }

  void _saveNewWarningNo()
  {
    _saveBeforeNewFinished();
  }

  void _saveNewWarningCancel()
  {
    _saveNewWarningDialog.hide();
    GetIt.I.get<AppState>().hasProjectNotifier.value = true;
  }

  void _saveBeforeNewFinished()
  {
    _saveNewWarningDialog.hide();
    _newProjectDialog.show(context: context);
  }


  void _newFilePressed({required final CoordinateSetI size})
  {
    GetIt.I.get<AppState>().init(dimensions: size);
    _newProjectDialog.hide();
  }

  void _openPressed()
  {
    if (KPixApp.openCallbackFunc != null)
    {
      KPixApp.openCallbackFunc?.call(callback: _openPerformed);
    }
  }

  void _openPerformed()
  {
    GetIt.I.get<AppState>().hasProjectNotifier.value = true;
    GetIt.I.get<HotkeyManager>().triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
    _newProjectDialog.hide();
  }


  @override
  Widget build(final BuildContext context)
  {
    return ValueListenableBuilder<bool>(
      valueListenable: initialized,
      builder: (final BuildContext context, final bool init, final Widget? child)
      {
        if (init)
        {
          return MainWidget(
            closePressed: _closePressed,
            inFocus: _isFocused,
          );
        }
        else
        {
          return Padding(
            padding: const EdgeInsets.all(_MainLayoutOptions.loadingScreenPadding),
            child: Stack(
              children: <Widget>[
                Center(child: Image.asset(PreferenceManager.ASSET_ICON),),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    "Loading...",
                    style: Theme.of(context).textTheme.displayLarge?.apply(color: Theme.of(context).primaryColorLight),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

/// The main widget holding the application.
///
/// The general layout is represented in this class.
class MainWidget extends StatelessWidget
{
  const MainWidget({super.key, required this.closePressed, required this.inFocus});
  final Function()? closePressed;
  final ValueNotifier<bool> inFocus;

  @override
  Widget build(final BuildContext context) {
    final WindowButtonColors windowButtonColors = WindowButtonColors(
      iconNormal: Theme.of(context).primaryColorLight,
      mouseOver: Theme.of(context).highlightColor,
      mouseDown: Theme.of(context).splashColor,
      iconMouseOver: Theme.of(context).primaryColor,
      iconMouseDown: Theme.of(context).primaryColorDark,
    );
    return Column(
      children: <Widget>[
        //TOP BAR
        ExcludeFocus(
          child: ValueListenableBuilder<bool>(
            valueListenable: inFocus,
            builder: (final BuildContext context, final bool foc, final Widget? child) {
              return ColoredBox(
                color: foc? Theme.of(context).primaryColor : Theme.of(context).primaryColorDark,
                child: (isDesktop()) ?
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: <Widget>[
                            WindowTitleBarBox(child: MoveWindow()),
                            Padding(
                              padding: const EdgeInsets.all(_MainLayoutOptions.titleBarPadding),
                              child: ValueListenableBuilder<bool>(
                                valueListenable: GetIt.I.get<AppState>().hasChanges,
                                  builder: (final BuildContext context, final bool __, final Widget? ___) {
                                    return ValueListenableBuilder<String?>(
                                      valueListenable: GetIt.I.get<AppState>().projectName,
                                      builder: (final BuildContext _, final String? ____, final Widget? _____) {
                                        return Text(
                                          GetIt.I.get<AppState>().getTitle(),
                                          style: Theme.of(context).textTheme.bodyLarge,
                                          textAlign: TextAlign.center,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            MinimizeWindowButton(colors: windowButtonColors),
                            MaximizeWindowButton(colors: windowButtonColors),
                            CloseWindowButton(colors: windowButtonColors, onPressed: closePressed),
                          ],
                        ),
                      ],
                    )
                    : const SizedBox.shrink(),
                );
            },
          ),
        ),
        Expanded(
          child: KPixSplitter(
            left: ValueListenableBuilder<bool>(
              valueListenable: GetIt.I.get<AppState>().timeline.isPlaying,
              builder: (final BuildContext context1, final bool isPlaying, final Widget? child1) {
                return Stack(
                  children: <Widget>[
                    const MainToolbarWidget(),
                    if (isPlaying) ModalBarrier(
                      color: Theme.of(context).primaryColorDark.withAlpha(OverlayEntrySubMenuOptions.smokeOpacity),
                      dismissible: false,) else const SizedBox.shrink(),
                  ],
                );
              },
            ),
            center: ExcludeFocus(
              child: ValueListenableBuilder<bool>(
                valueListenable: GetIt.I.get<AppState>().hasProjectNotifier,
                builder: (final BuildContext context, final bool hasProject, final Widget? child) {
                  return hasProject ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TimeLineWidget(timeline: GetIt.I.get<AppState>().timeline, expandedHeight: 320,),
                      const Expanded(child: ClipRect(child: CanvasWidget())),
                      StatusBarWidget(),
                      SymmetryWidget(state: GetIt.I.get<AppState>().symmetryState,),
                    ],
                  ) : Container(color: Theme.of(context).primaryColorDark);
                },
              ),
            ),
            right: ExcludeFocus(
              child: ValueListenableBuilder<bool>(
                valueListenable: GetIt.I.get<AppState>().timeline.isPlaying,
                builder: (final BuildContext context1, final bool isPlaying, final Widget? child1) {
                  return Stack(
                    children: <Widget>[
                      const RightBarWidget(),
                      if (isPlaying) ModalBarrier(
                        color: Theme.of(context).primaryColorDark.withAlpha(OverlayEntrySubMenuOptions.smokeOpacity),
                        dismissible: false,) else const SizedBox.shrink(),
                    ],
                  );
                },
              ),
            ),
            //dividerWidth: _MainLayoutOptions.splitViewDividerWidth, //8.0
            ratioLeft: _MainLayoutOptions.splitViewFlexLeftDefault, //0.2
            minRatioLeft: _MainLayoutOptions.splitViewFlexLeftMin, //0.15
            maxRatioLeft: _MainLayoutOptions.splitViewFlexLeftMax, //0.25
            ratioRight: _MainLayoutOptions.splitViewFlexRightDefault, //0.15
            minRatioRight: _MainLayoutOptions.splitViewFlexRightMin, //0.1
            maxRatioRight: _MainLayoutOptions.splitViewFlexRightMax, //0.2
          ),
        ),
      ],
    );
  }
}

abstract final class _MainLayoutOptions
{
  //static const double splitViewDividerWidth = 8.0;

  static const double splitViewFlexLeftMin = 0.15;
  static const double splitViewFlexLeftDefault = 0.2;
  static const double splitViewFlexLeftMax = 0.25;

  static const double splitViewFlexRightMin = 0.1;
  static const double splitViewFlexRightDefault = 0.15;
  static const double splitViewFlexRightMax = 0.2;

  static const int recoverCheckIntervalMinutes = 2;
  static const double titleBarPadding = 4.0;
  static const double loadingScreenPadding = 32.0;
}
