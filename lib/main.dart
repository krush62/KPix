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
import 'dart:collection';
import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/reference_image_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/main/main_toolbar_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:kpix/widgets/main/right_bar_widget.dart';
import 'package:kpix/widgets/main/status_bar_widget.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/widgets/canvas/canvas_widget.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;


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

ThemeNotifier themeSettings = ThemeNotifier();
late List<String> cmdLineArgs; //--dart-entrypoint-args <args>

void main(final List<String> args) {
  cmdLineArgs = args;
  WidgetsFlutterBinding.ensureInitialized();
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
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  home: const KPixApp(),
                  theme: KPixTheme.monochromeTheme,
                  darkTheme: KPixTheme.monochromeThemeDark,
                  themeMode: themeSettings.themeMode,
                );
              },
            ),
          ),
        );
      },
    )
  );

  if (Helper.isDesktop()) {
    doWhenWindowReady(() {
      const initialSize = Size(1600, 900);
      appWindow.minSize = initialSize;
      appWindow.size = initialSize;
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
  final ValueNotifier<bool> initialized = ValueNotifier(false);
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
    _initPrefs();
    WidgetsBinding.instance.addObserver(this);
    _lastAppLifeCycleState = AppLifecycleState.resumed;
    if (!kIsWeb)
    {
      _recoverTimer = Timer.periodic(Duration(minutes: 2), (final Timer _) {_recoverCheck();});
    }
  }

  @override
  void dispose()
  {
    WidgetsBinding.instance.removeObserver(this);
    _recoverTimer.cancel();
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
        FileHandler.clearRecoverDir().then((final void value)
        {
          final String fileName = appState.projectName.value ?? FileHandler.recoverFileName;
          final String finalPath = p.join(appState.internalDir, FileHandler.recoverSubDirName, "$fileName.${FileHandler.fileExtensionKpix}");
          FileHandler.saveKPixFile(appState: appState, path: finalPath);
        },);
      }
    }
    else
    {
      FileHandler.clearRecoverDir();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state)
  {
    switch (state)
    {
      case AppLifecycleState.detached:
        //This state is only entered on iOS, Android, and web, although on all platforms it is the default state before the application begins running.
        break;
      case AppLifecycleState.resumed:
        //On all platforms, this state indicates that the application is in the default running mode for a running application that has input focus and is visible.
        break;
      case AppLifecycleState.inactive:
        //At least one view of the application is visible, but none have input focus. The application is otherwise running normally.
        if (!kIsWeb)
        {
          _recoverCheck(ignoreState: true);
        }
        break;
      case AppLifecycleState.hidden:
        //All views of an application are hidden, either because the application is about to be paused (on iOS and Android), or because it has been minimized or placed on a desktop that is no longer visible (on non-web desktop), or is running in a window or tab that is no longer visible (on the web).
        break;
      case AppLifecycleState.paused:
        //The application is not currently visible to the user, and not responding to user input.
        break;
    }

  }

  Future<void> _initPrefs() async
  {
    final sPrefs = await SharedPreferences.getInstance();
    final Map<PixelFontType, KFont> fontMap = await FontManager.readFonts();
    final HashMap<StampType, KStamp> stampMap = await StampManager.readStamps();
    GetIt.I.registerSingleton<PreferenceManager>(PreferenceManager(sPrefs, FontManager(kFontMap: fontMap), StampManager(stampMap: stampMap)));
    final String exportDirString = await FileHandler.findExportDir();
    final String internalDirString = await FileHandler.findInternalDir();
    final AppState appState = AppState(exportDir: exportDirString, internalDir: internalDirString);

    GetIt.I.registerSingleton<AppState>(appState);
    GetIt.I.registerSingleton<PackageInfo>(await PackageInfo.fromPlatform());
    GetIt.I.registerSingleton<ReferenceImageManager>(ReferenceImageManager());
    GetIt.I.registerSingleton<HistoryManager>(HistoryManager(maxEntries: GetIt.I.get<PreferenceManager>().behaviorPreferenceContent.undoSteps.value));

    //For the future: Device independent canvas scaling
    if (context.mounted)
    {
      final BuildContext c = context;
      appState.statusBarState.devicePixelRatio = MediaQuery.of(c).devicePixelRatio;
    }

    //CREATE DIALOG OVERLAYS
    _closeWarningDialog = OverlayEntries.getThreeButtonDialog(
        onYes: _closeWarningYes,
        onNo: _closeWarningNo,
        onCancel: _closeAllMenus,
        outsideCancelable: false,
        message: "There are unsaved changes, do you want to save first?");

    _saveNewWarningDialog = OverlayEntries.getThreeButtonDialog(
        onYes: _saveNewWarningYes,
        onNo: _saveNewWarningNo,
        onCancel: _saveNewWarningCancel,
        outsideCancelable: false,
        message: "There are unsaved changes, do you want to save first?"
    );
    _newProjectDialog = OverlayEntries.getNewProjectDialog(
        onDismiss: () {Helper.exitApplication();},
        onAccept: _newFilePressed,
        onOpen: _openPressed
    );


    GetIt.I.get<HotkeyManager>().addListener(action: HotkeyAction.generalExit, func: _closePressed);

    final ThemeMode currentTheme = GetIt.I.get<PreferenceManager>().guiPreferenceContent.themeType.value;
    if (themeSettings.themeMode != currentTheme)
    {
      themeSettings.themeMode =  currentTheme;
    }
    appState.hasProjectNotifier.addListener(_hasProjectChanged);

    if (!kIsWeb)
    {
      await FileHandler.createInternalDirectories();
    }

    if (!kIsWeb)
    {
      await _handleInitialFile();
    }

    initialized.value = true;
  }


  Future<void> _handleInitialFile() async
  {
    final AppState appState = GetIt.I.get<AppState>();
    final PreferenceManager preferenceManager = GetIt.I.get<PreferenceManager>();

    bool fromRecovery = false;
    String? initialFilePath = await FileHandler.getRecoveryFile();

    if (initialFilePath == null)
    {
      if (cmdLineArgs.isNotEmpty && Helper.isDesktop())
      {
        initialFilePath = cmdLineArgs[0];
      }
      else if (!kIsWeb && Platform.isAndroid)
      {
        const MethodChannel channel = MethodChannel('app.channel.shared.data');
        initialFilePath = await channel.invokeMethod('getSharedFile');
      }

      await FileHandler.importProject(path: initialFilePath, showMessages: false);
      final String fileName = Helper.extractFilenameFromPath(path: initialFilePath);
      final String expectedFileName = initialFilePath = p.join(appState.internalDir, FileHandler.projectsSubDirName, fileName);
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
      final LoadFileSet lfs = await FileHandler.loadKPixFile(
          fileData: null,
          constraints: preferenceManager.kPalConstraints,
          path: initialFilePath,
          sliderConstraints: preferenceManager.kPalSliderConstraints,
          referenceLayerSettings: preferenceManager.referenceLayerSettings,
          gridLayerSettings: preferenceManager.gridLayerSettings);
      if (lfs.path != null && lfs.historyState != null)
      {
        appState.restoreFromFile(loadFileSet: lfs, setHasChanges: fromRecovery);
        appState.hasProjectNotifier.value = true;
        _newProjectDialog.hide();
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
      Helper.exitApplication();
    }
  }

  void _closeWarningYes()
  {
    if (KPixApp.saveCallbackFunc != null)
    {
      KPixApp.saveCallbackFunc!(callback: _saveBeforeClosedFinished);
    }
  }


  void _closeWarningNo()
  {
    Helper.exitApplication();
  }

  void _saveBeforeClosedFinished()
  {
    Helper.exitApplication();
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
      KPixApp.saveCallbackFunc!(callback: _saveBeforeNewFinished);
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


  void _newFilePressed({required CoordinateSetI size})
  {
    GetIt.I.get<AppState>().init(dimensions: size);
    _newProjectDialog.hide();
  }

  void _openPressed()
  {
    if (KPixApp.openCallbackFunc != null)
    {
      KPixApp.openCallbackFunc!(callback: _openPerformed);
    }
  }

  void _openPerformed()
  {
    GetIt.I.get<AppState>().hasProjectNotifier.value = true;
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
          return ToastProvider(
            child: MainWidget(
              closePressed: _closePressed
            )
          );
        }
        else
        {
          return  Padding(
            padding: const EdgeInsets.all(32.0),
            child: Stack(
              children: [
                Center(child: Image.asset("imgs/kpix_icon.png"),),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    "Loading...",
                    style: Theme.of(context).textTheme.displayLarge?.apply(color: Theme.of(context).primaryColorLight)
                  )
                )
              ]
            ),
          );
        }
      },
    );
  }
}

class MainWidget extends StatelessWidget
{
  const MainWidget({super.key, required this.closePressed});
  final Function()? closePressed;

  @override
  Widget build(BuildContext context) {
    final WindowButtonColors windowButtonColors = WindowButtonColors(
      iconNormal: Theme.of(context).primaryColorLight,
      mouseOver: Theme.of(context).highlightColor,
      mouseDown: Theme.of(context).splashColor,
      iconMouseOver: Theme.of(context).primaryColor,
      iconMouseDown: Theme.of(context).primaryColorDark);
    return Column(
      children: [
        //TOP BAR
        ColoredBox(
          color: Theme.of(context).primaryColor,
          child: (Helper.isDesktop()) ?
            Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      WindowTitleBarBox(child: MoveWindow()),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: GetIt.I.get<AppState>().hasChanges,
                            builder: (final BuildContext context, final bool __, Widget? ___) {
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
                        )
                      ]
                    )
                  ),
                  Row(
                    children: [
                      MinimizeWindowButton(colors: windowButtonColors),
                      MaximizeWindowButton(colors: windowButtonColors),
                      CloseWindowButton(colors: windowButtonColors, onPressed: closePressed),
                    ],
                  )
                ]
              )
              : const SizedBox.shrink(),
          ),
          Expanded(
            child: MultiSplitViewTheme(
              data: MultiSplitViewThemeData(
                dividerThickness: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewDividerWidth,
                dividerPainter: DividerPainters.grooved2(
                  backgroundColor: Theme.of(context).primaryColor,
                  color: Theme.of(context).primaryColorDark,
                  highlightedColor: Theme.of(context).primaryColorLight,
                  count: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewGrooveCountMin,
                  highlightedCount: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewGrooveCountMax,
                  gap: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewGrooveGap,
                  animationDuration: Duration(milliseconds: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewAnimationLength),
                  thickness: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewGrooveThickness,
                  size: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewGrooveSize
                )
              ),
              child: MultiSplitView(
                initialAreas: [
                  Area(
                    builder: (final BuildContext context, final Area area) {
                      return const MainToolbarWidget();
                    },
                    flex: Helper.isDesktop() ? GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexLeftMin : GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexLeftMax,
                    min: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexLeftMin,
                    max: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexLeftMax
                  ),
                  Area(builder: (context, area) {
                    return ValueListenableBuilder(
                      valueListenable: GetIt.I.get<AppState>().hasProjectNotifier,
                      builder: (final BuildContext context, final bool hasProject, final Widget? child) {
                        return hasProject ? Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const CanvasWidget(),
                            StatusBarWidget()
                          ],
                        ) : Container(color: Theme.of(context).primaryColorDark);
                      },
                    );
                  },
                  flex: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexCenterDefault
                ),
                Area(
                  builder: (final BuildContext context, final Area area){
                    return const RightBarWidget();
                  },
                  flex: Helper.isDesktop() ? GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexRightMin : GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexRightMax,
                  min: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexRightMin,
                  max: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexRightMax,
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}

class MainLayoutOptions
{
  final double splitViewDividerWidth;
  final double splitViewGrooveGap;
  final double splitViewGrooveThickness;
  final double splitViewGrooveSize;
  final double splitViewFlexLeftMin;
  final double splitViewFlexLeftMax;
  final double splitViewFlexRightMin;
  final double splitViewFlexRightMax;
  final double splitViewFlexLeftDefault;
  final double splitViewFlexCenterDefault;
  final double splitViewFlexRightDefault;
  final int splitViewGrooveCountMin;
  final int splitViewGrooveCountMax;
  final int splitViewAnimationLength;


  MainLayoutOptions({
    required this.splitViewDividerWidth,
    required this.splitViewGrooveGap,
    required this.splitViewGrooveThickness,
    required this.splitViewGrooveSize,
    required this.splitViewFlexLeftMin,
    required this.splitViewFlexLeftMax,
    required this.splitViewFlexRightMin,
    required this.splitViewFlexRightMax,
    required this.splitViewGrooveCountMin,
    required this.splitViewGrooveCountMax,
    required this.splitViewAnimationLength,
    required this.splitViewFlexLeftDefault,
    required this.splitViewFlexCenterDefault,
    required this.splitViewFlexRightDefault});
}
