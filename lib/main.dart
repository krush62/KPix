import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/models.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/horizontal_split_view.dart';
import 'package:kpix/widgets/palette_widget.dart';
import 'package:kpix/widgets/tools_widget.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/widgets/vertical_split_view.dart';
import 'package:kpix/widgets/listener_example.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main()
{
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const KPixApp());
}

class KPixApp extends StatefulWidget {
  const KPixApp({super.key});

  @override
  State<KPixApp> createState() => _KPixAppState();
}

class _KPixAppState extends State<KPixApp> {
  late PreferenceManager prefs;
  late CanvasOptions canvasOptions;
  late ToolsWidgetOptions _toolsOptions;
  AppState appState = AppState();
  bool prefsInitialized = false;


  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs()
  async {
    final sPrefs = await SharedPreferences.getInstance();
    prefs = PreferenceManager(sPrefs);
    canvasOptions = CanvasOptions(
        prefs.getValueI(PreferenceInt.Layout_Canvas_Stylus_PollRate),
        prefs.getValueI(PreferenceInt.Layout_Canvas_LongPressDuration),
        prefs.getValueD(PreferenceDouble.Layout_Canvas_LongPressCancelDistance));
    _toolsOptions = ToolsWidgetOptions(
        prefs.getValueD(PreferenceDouble.Layout_Tools_Padding),
        prefs.getValueD(PreferenceDouble.Layout_Tools_ButtonResizeFactor),
        prefs.getValueD(PreferenceDouble.Layout_Tools_SpacingFactor),
        prefs.getValueD(PreferenceDouble.Layout_Tools_IconSize));
    prefsInitialized = true;
    setState(() {} );
  }

  @override
  Widget build(BuildContext context) {
    
    if (!prefsInitialized)
      {
        return MaterialApp(
          home: const Text("LOADING"),
          theme: KPixTheme.lightThemeData(context),
          darkTheme: KPixTheme.darkThemeData(),
        );
      }
    else
    {
      return MaterialApp(
        home: VerticalSplitView(
          left: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                flex: 3,
                child: ValueListenableBuilder<ToolType>(
                  valueListenable: appState.selectedTool,
                  builder: (BuildContext context, ToolType value,child) {
                    //return ToolsWidget(options: _toolsOptions, changeToolFn: changeTool, appState: appState,);
                    return PaletteWidget();
                  }
                ),
              ),
              Expanded(
                flex: 4,
                child: ValueListenableBuilder<ToolType>(
                    valueListenable: appState.selectedTool,
                    builder: (BuildContext context, ToolType value,child) {
                      return ToolsWidget(options: _toolsOptions, changeToolFn: changeTool, appState: appState,);
                      //return ColorEntryWidget();
                    }
                ),
              ),
              Expanded(
                flex: 1,
                child: ValueListenableBuilder<ToolType>(
                    valueListenable: appState.selectedTool,
                    builder: (BuildContext context, ToolType value,child) {
                      return ColorEntryWidget();
                    }
                ),
              ),
            ]
          ),
          right: HorizontalSplitView(
              top: ListenerExample(options: canvasOptions,),
              bottom: Text("ANIMATION STUFF", style: Theme.of(context).textTheme.headlineMedium,),
              ratio: prefs.getValueD(PreferenceDouble.Layout_SplitViewHorizontal_Ratio),
              minRatioTop: prefs.getValueD(PreferenceDouble.Layout_SplitViewHorizontal_TopMinRatio),
              minRatioBottom: prefs.getValueD(PreferenceDouble.Layout_SplitViewHorizontal_BottomMinRatio)
          ),
          ratio: prefs.getValueD(PreferenceDouble.Layout_SplitViewVertical_Ratio),
          minRatioLeft: prefs.getValueD(PreferenceDouble.Layout_SplitViewVertical_LeftMinRatio),
          minRatioRight: prefs.getValueD(PreferenceDouble.Layout_SplitViewVertical_RightMinRatio)),
        theme: KPixTheme.lightThemeData(context),
        darkTheme: KPixTheme.darkThemeData(),
      );
    }

  }

  void changeTool(ToolType t)
  {
    print("ChangeTool");
  }
}


