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
import 'package:kpix/widgets/right_bar_widget.dart';
import 'package:kpix/widgets/status_bar_widget.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';
import 'package:kpix/widgets/tools_widget.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/widgets/vertical_split_view.dart';
import 'package:kpix/widgets/listener_example.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const KPixApp());

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    doWhenWindowReady(() {
      const initialSize = Size(1600, 900);
      appWindow.maximize();
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

class MainWidget extends StatelessWidget {
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
                dividerThickness: prefs.mainLayoutOptions.splitViewDividerWidth,
                dividerPainter: DividerPainters.grooved2(
                  backgroundColor: Theme.of(context).primaryColor,
                  color: Theme.of(context).primaryColorDark,
                  highlightedColor: Theme.of(context).primaryColorLight,
                  count: prefs.mainLayoutOptions.splitViewGrooveCountMin,
                  highlightedCount: prefs.mainLayoutOptions.splitViewGrooveCountMax,
                  gap: prefs.mainLayoutOptions.splitViewGrooveGap,
                  animationDuration: Duration(milliseconds: prefs.mainLayoutOptions.splitViewAnimationLength),
                  thickness: prefs.mainLayoutOptions.splitViewGrooveThickness,
                  size: prefs.mainLayoutOptions.splitViewGrooveSize
                )
              ),
              child: MultiSplitView(
                initialAreas: [
                Area(builder: (context, area) {

                  return MainToolbarWidget(
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
                  );
                },
                flex: prefs.mainLayoutOptions.splitViewFlexLeftDefault,
                min: prefs.mainLayoutOptions.splitViewFlexLeftMin,
                max: prefs.mainLayoutOptions.splitViewFlexLeftMax),
                Area(builder: (context, area) {
                  return Column(
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
                        cursorPositionString:
                            appState.statusBarCursorPositionString,
                        dimensionString: appState.statusBarDimensionString,
                        toolDimensionString: appState.statusBarToolDimensionString,
                        toolDiagonalString: appState.statusBarToolDiagonalString,
                        toolAspectRatioString:
                            appState.statusBarToolAspectRatioString,
                        toolAngleString: appState.statusBarToolAngleString,
                      )
                    ],
                  );
                },
                flex: prefs.mainLayoutOptions.splitViewFlexCenterDefault
                ),
                Area(builder: (context, area){
                 return RightBarWidget(
                   overlayEntrySubMenuOptions: prefs.overlayEntryOptions,
                   mainButtonWidgetOptions: prefs.mainButtonWidgetOptions,
                 );
                },
                  flex: prefs.mainLayoutOptions.splitViewFlexRightDefault,
                  min: prefs.mainLayoutOptions.splitViewFlexRightMin,
                  max: prefs.mainLayoutOptions.splitViewFlexRightMax,

                )
                        ],
                      ),
            )),
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
