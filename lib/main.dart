import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kpix/font_manager.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/main_toolbar_widget.dart';
import 'package:kpix/widgets/right_bar_widget.dart';
import 'package:kpix/widgets/status_bar_widget.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/widgets/canvas_widget.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KPixApp());

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    doWhenWindowReady(() {
      const initialSize = Size(1600, 900);
      appWindow.minSize = initialSize;
      //appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.title = "KPix";
      appWindow.maximize();
      appWindow.show();
    });
  } else {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}

class KPixApp extends StatefulWidget {
  const KPixApp({super.key});

  @override
  State<KPixApp> createState() => _KPixAppState();
}

class _KPixAppState extends State<KPixApp> {
  ValueNotifier<bool> initialized = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    final sPrefs = await SharedPreferences.getInstance();
    Map<PixelFontType, KFont> fontMap = await FontManager.readFonts();
    GetIt.I.registerSingleton<PreferenceManager>(PreferenceManager(sPrefs, FontManager(kFontMap: fontMap)));
    GetIt.I.registerSingleton<AppState>(AppState());
    //TODO TEMP
    AppState appState = GetIt.I.get<AppState>();
    appState.setCanvasDimensions(width: 256, height: 128);
    appState.addNewRamp();
    appState.addNewRamp();
    appState.addNewRamp();
    appState.addNewRamp();
    appState.addNewLayer();
    appState.addNewLayer(select: true);
    initialized.value = true;
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
          return MaterialApp(
            home: MainWidget(),
            theme: KPixTheme.monochromeTheme,
            darkTheme: KPixTheme.monochromeThemeDark,
          );
        }
        else
        {
          return MaterialApp(
            home: Padding(
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
            ),
            theme: KPixTheme.monochromeTheme,
            darkTheme: KPixTheme.monochromeThemeDark,
          );
        }
      },
    );
  }
}

class MainWidget extends StatelessWidget {
  const MainWidget({super.key});

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
                      child: Text(
                        "KPix",
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    )
                  ])),
                  Row(
                    children: [
                      MinimizeWindowButton(colors: windowButtonColors),
                      MaximizeWindowButton(colors: windowButtonColors),
                      CloseWindowButton(colors: windowButtonColors),
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
