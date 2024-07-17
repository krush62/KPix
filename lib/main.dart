import 'dart:collection';
import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/widgets/main_toolbar_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:kpix/widgets/right_bar_widget.dart';
import 'package:kpix/widgets/status_bar_widget.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/widgets/canvas_widget.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
      MaterialApp(
          home: const KPixApp(),
          theme: KPixTheme.monochromeTheme,
          darkTheme: KPixTheme.monochromeThemeDark,

      )
  );

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
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
  const KPixApp({super.key});

  @override
  State<KPixApp> createState() => _KPixAppState();
}

class _KPixAppState extends State<KPixApp>
{
  final ValueNotifier<bool> initialized = ValueNotifier(false);
  late OverlayEntry _closeWarningDialog;
  bool _closeWarningVisible = false;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }


  Future<void> _initPrefs() async {
    final sPrefs = await SharedPreferences.getInstance();
    final Map<PixelFontType, KFont> fontMap = await FontManager.readFonts();
    final HashMap<StampType, KStamp> stampMap = await StampManager.readStamps();
    GetIt.I.registerSingleton<PreferenceManager>(PreferenceManager(sPrefs, FontManager(kFontMap: fontMap), StampManager(stampMap: stampMap)));
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory tempDir = await getTemporaryDirectory();
    final Directory cache = await getApplicationCacheDirectory();
    GetIt.I.registerSingleton<AppState>(AppState(appDir: appDir.path, cacheDir: cache.path, tempDir: tempDir.path));
    AppState appState = GetIt.I.get<AppState>();

    //TODO TEMP
    appState.setCanvasDimensions(width: 256, height: 160, addToHistoryStack: false);
    appState.addNewRamp(addToHistoryStack: false);
    appState.addNewLayer(select: true, addToHistoryStack: false);

    GetIt.I.registerSingleton<HistoryManager>(HistoryManager());
    GetIt.I.get<HistoryManager>().addState(appState: appState, description: "initial", setHasChanges: false);
    if (context.mounted)
    {
      final BuildContext c = context;
      appState.statusBarState.devicePixelRatio = MediaQuery.of(c).devicePixelRatio;
    }

    _closeWarningDialog = OverlayEntries.getThreeButtonDialog(
        onYes: _closeWarningYes,
        onNo: _closeWarningNo,
        onCancel: _closeAllMenus,
        outsideCancelable: false,
        message: "There are unsaved changes, do you want to save first?");

    initialized.value = true;
  }

  void _closePressed()
  {
    if (GetIt.I.get<AppState>().hasChanges.value)
    {
      Overlay.of(context).insert(_closeWarningDialog);
      _closeWarningVisible = true;
    }
    else
    {
      exit(0);
    }
  }

  void _closeWarningYes()
  {
    FileHandler.saveFilePressed(finishCallback: _saveBeforeClosedFinished);
  }

  void _closeWarningNo()
  {
    exit(0);
  }

  void _saveBeforeClosedFinished()
  {
    exit(0);
  }

  void _closeAllMenus()
  {
    if (_closeWarningVisible)
    {
      _closeWarningDialog.remove();
    }
  }


  @override
  Widget build(BuildContext context)
  {
    return ValueListenableBuilder<bool>(
      valueListenable: initialized,
      builder: (BuildContext context, bool init, child)
      {
        if (init)
        {
          return ToastProvider(child: MainWidget(closePressed: _closePressed,));
        }
        else
        {
          return  Padding(
            //TODO magic
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
          child: (!kIsWeb &&
                  (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
              ? Row(children: [
                  Expanded(
                      child: Stack(alignment: Alignment.centerLeft, children: [
                    WindowTitleBarBox(child: MoveWindow()),

                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: GetIt.I.get<AppState>().hasChanges,
                        builder: (final BuildContext context, final bool __, Widget? ___) {
                          return ValueListenableBuilder<String?>(
                            valueListenable: GetIt.I.get<AppState>().filePath,
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
                  ])),
                  Row(
                    children: [
                      MinimizeWindowButton(colors: windowButtonColors),
                      MaximizeWindowButton(colors: windowButtonColors),
                      CloseWindowButton(colors: windowButtonColors, onPressed: closePressed),
                    ],
                  )
                ])
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
                Area(builder: (context, area) {
                  return const MainToolbarWidget();
                },
                flex: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexLeftDefault,
                min: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexLeftMin,
                max: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexLeftMax),
                Area(builder: (context, area) {
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const CanvasWidget(
                      ),
                      StatusBarWidget(
                      )
                    ],
                  );
                },
                flex: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexCenterDefault
                ),
                Area(builder: (context, area)
                {
                 return const RightBarWidget();
                },
                  flex: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexRightDefault,
                  min: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexRightMin,
                  max: GetIt.I.get<PreferenceManager>().mainLayoutOptions.splitViewFlexRightMax,

                )
                        ],
                      ),
            )

        ),
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
