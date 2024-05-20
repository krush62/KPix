import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/models.dart';
import 'package:kpix/widgets/horizontal_split_view.dart';
import 'package:kpix/widgets/main_toolbar_widget.dart';
import 'package:kpix/widgets/palette_widget.dart';
import 'package:kpix/widgets/status_bar_widget.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';
import 'package:kpix/widgets/tools_widget.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/widgets/vertical_split_view.dart';
import 'package:kpix/widgets/listener_example.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const KPixApp());

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    doWhenWindowReady(() {
      const initialSize = Size(1366, 768);
      appWindow.maximize();
      appWindow.minSize = initialSize;
      //appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.title = "KPix";
      appWindow.maximize();
      appWindow.show();
    });
  }
  else
  {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}

class KPixApp extends StatefulWidget {
  const KPixApp({super.key});

  @override
  State<KPixApp> createState() => _KPixAppState();
}

class _KPixAppState extends State<KPixApp> {
  late PreferenceManager prefs;
  late AppState appState;
  bool prefsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    final sPrefs = await SharedPreferences.getInstance();
    prefs = PreferenceManager(sPrefs);
    appState = AppState(kPalConstraints: prefs.kPalConstraints);
    //TODO TEMP
    appState.addNewRamp();
    prefsInitialized = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!prefsInitialized) {
      return MaterialApp(
        home: const Text("LOADING"),
        theme: KPixTheme.monochromeTheme,
        darkTheme: KPixTheme.monochromeThemeDark,
      );
    } else {
      return MaterialApp(
        home: MainWidget(appState: appState, prefs: prefs),
        theme: KPixTheme.monochromeTheme,
        darkTheme: KPixTheme.monochromeThemeDark,
      );
    }
  }
}

class MainWidget extends StatelessWidget
{


  final AppState appState;
  final PreferenceManager prefs;

  const MainWidget({super.key, required this.appState, required this.prefs});

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
          child: (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) ?
          Row(children: [
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
              :
          const SizedBox.shrink(),
        ),
        Expanded(
          child: VerticalSplitView(
              //LEFT SIDE
              left: MainToolbarWidget(
                appState: appState,
                toolSettingsWidgetOptions: prefs.toolSettingsWidgetOptions,
                toolOptions: prefs.toolOptions,
                mainToolbarWidgetOptions: prefs.mainToolbarWidgetOptions,
                paletteWidgetOptions: prefs.paletteWidgetOptions,
                toolsWidgetOptions: prefs.toolsWidgetOptions,
                shaderWidgetOptions: prefs.shaderWidgetOptions,
                shaderOptions: prefs.shaderOptions,
                overlayEntryOptions: prefs.overlayEntryOptions,
                colorChooserWidgetOptions: prefs.colorChooserWidgetOptions,
                colorEntryWidgetOptions: prefs.colorEntryOptions,
                kPalWidgetOptions: prefs.kPalWidgetOptions,
                kPalConstraints: prefs.kPalConstraints,
                alertDialogOptions: prefs.alertDialogOptions,
                colorNames: prefs.colorNames,
                addNewRampFn: appState.addNewRamp,
                updateRampFn: appState.updateRamp,
                deleteRampFn: appState.deleteRamp,
                colorSelectedFn: appState.colorSelected,
              ),
              //RIGHT SIDE
              right: HorizontalSplitView(
                  top: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ListenerExample(
                        options: prefs.canvasWidgetOptions,
                        appState: appState,
                      ),
                      StatusBarWidget(
                          options: prefs.statusBarWidgetOptions,
                          zoomFactorString: appState.statusBarZoomFactorString,
                          usedColorsString: appState.statusBarUsedColorsString,
                          cursorPositionString: appState.statusBarCursorPositionString,
                          dimensionString: appState.statusBarDimensionString,
                          toolDimensionString: appState.statusBarToolDimensionString,
                          toolDiagonalString: appState.statusBarToolDiagonalString,
                          toolAspectRatioString: appState.statusBarToolAspectRatioString,
                          toolAngleString: appState.statusBarToolAngleString,)
                    ],
                  ),
                  bottom: Text(
                    "ANIMATION STUFF",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  ratio: prefs.getValueD(
                      PreferenceDouble.Layout_SplitViewHorizontal_Ratio),
                  minRatioTop: prefs.getValueD(PreferenceDouble
                      .Layout_SplitViewHorizontal_TopMinRatio),
                  minRatioBottom: prefs.getValueD(PreferenceDouble
                      .Layout_SplitViewHorizontal_BottomMinRatio)),
              ratio: prefs.getValueD(
                  PreferenceDouble.Layout_SplitViewVertical_Ratio),
              minRatioLeft: prefs.getValueD(
                  PreferenceDouble.Layout_SplitViewVertical_LeftMinRatio),
              minRatioRight: prefs.getValueD(
                  PreferenceDouble.Layout_SplitViewVertical_RightMinRatio)),
        ),
      ],
    );
  }
}
