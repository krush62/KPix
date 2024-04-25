

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krush_flutter_test/KPixTheme.dart';
import 'package:krush_flutter_test/Models.dart';
import 'package:krush_flutter_test/widgets/HorizontalSplitView.dart';
import 'package:krush_flutter_test/widgets/ToolsWidget.dart';
import 'package:krush_flutter_test/widgets/PreferenceManager.dart';
import 'package:krush_flutter_test/widgets/VerticalSplitView.dart';
import 'package:krush_flutter_test/widgets/ListenerExample.dart';
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
  late ToolsWidget _toolsWidget;
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
        //home: const ListenerExample(),
        home: VerticalSplitView(
          left: ValueListenableBuilder<ToolType>(
            valueListenable: appState.selectedTool,
            builder: (BuildContext context, ToolType value,child) {
              return ToolsWidget(options: _toolsOptions,
                changeToolFn: ChangeTool,
                appState: appState,);
            }
          ),
          right: HorizontalSplitView(
              top: ListenerExample(options: canvasOptions,),
              bottom: Text("ANIMATION STUFF"),
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

  void ChangeTool(ToolType t)
  {
    print("ChangeTool");
  }
}


