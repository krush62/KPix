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

    List<Color> colors = [Colors.red, Colors.amber, Colors.green, Colors.yellow, Colors.lightBlue, Colors.white12, Colors.cyan, Colors.lightGreen];
    appState.setColors(colors, prefs.colorEntryOptions);
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
                    return PaletteWidget(options: prefs.paletteOptions, appState: appState,);
                  }
                ),
              ),
              Expanded(
                flex: 4,
                child: ValueListenableBuilder<ToolType>(
                    valueListenable: appState.selectedTool,
                    builder: (BuildContext context, ToolType value,child) {
                      return ToolsWidget(options: prefs.toolsOptions, changeToolFn: changeTool, appState: appState,);
                      //return ColorEntryWidget();
                    }
                ),
              ),

            ]
          ),
          right: HorizontalSplitView(
              top: ListenerExample(options: prefs.canvasOptions,),
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

  //TODO temp
  void selectColor(ColorEntryWidget e)
  {
    print("cew selected");
  }
}


