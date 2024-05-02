
// ignore_for_file: constant_identifier_names
import 'package:kpix/widgets/color_chooser_widget.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/listener_example.dart';
import 'package:kpix/widgets/palette_widget.dart';
import 'package:kpix/widgets/tools_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PreferenceDouble
{
  Layout_SplitViewHorizontal_Ratio(defaultValue: 0.75),
  Layout_SplitViewHorizontal_TopMinRatio(defaultValue: 0.5),
  Layout_SplitViewHorizontal_BottomMinRatio(defaultValue: 0.1),
  Layout_SplitViewVertical_Ratio(defaultValue: 0.25),
  Layout_SplitViewVertical_LeftMinRatio(defaultValue: 0.1),
  Layout_SplitViewVertical_RightMinRatio(defaultValue: 0.75),
  Layout_Canvas_LongPressCancelDistance(defaultValue: 10.0),
  Layout_Tools_Padding(defaultValue: 8.0),
  Layout_Tools_ButtonResizeFactor(defaultValue: 64.0),
  Layout_Tools_SpacingFactor(defaultValue: 32.0),
  Layout_Tools_IconSize(defaultValue: 28.0),
  Layout_Palette_Padding(defaultValue: 8.0),
  Layout_Palette_ColumnCountResizeFactor(defaultValue: 52.0),
  Layout_Palette_TopIconSize(defaultValue: 24.0),
  Layout_Palette_AddIconSize(defaultValue: 28.0),
  Layout_ColorEntry_UnselectedMargin(defaultValue: 4.0),
  Layout_ColorEntry_SelectedMargin(defaultValue: 0.0),
  Layout_ColorEntry_RoundRadius(defaultValue: 8.0),
  Layout_ColorEntry_ContrastColorThreshold(defaultValue: 0.95),
  Layout_ColorChooser_IconSize(defaultValue: 36),
  Layout_ColorChooser_ColorContainerBorderRadius(defaultValue: 16.0),
  Layout_ColorChooser_Padding(defaultValue: 8.0),

  ;

  const PreferenceDouble({
    required this.defaultValue,
  });

  final double defaultValue;
}

enum PreferenceInt
{
  Layout_Canvas_LongPressDuration(defaultValue: 1000),
  Layout_Canvas_Stylus_PollRate(defaultValue: 100),
  Layout_ColorEntry_HsvDisplayDigits(defaultValue: 2),
  Layout_ColorEntry_HoverTimer(defaultValue: 100),
  ;
  const PreferenceInt({
    required this.defaultValue
  });
  final int defaultValue;
}

class _DoublePair
{
  final double value;
  bool changed = false;
  _DoublePair(double val) : value = val;
}

class _IntPair
{
  final int value;
  bool changed = false;
  _IntPair(int val) : value = val;
}

class PreferenceManager
{
  final SharedPreferences _prefs;
  final Map<PreferenceDouble, _DoublePair> _doubleMap = {};
  final Map<PreferenceInt, _IntPair> _intMap = {};
  late CanvasOptions canvasOptions;
  late ToolsWidgetOptions toolsOptions;
  late PaletteWidgetOptions paletteOptions;
  late ColorEntryWidgetOptions colorEntryOptions;
  late ColorChooserWidgetOptions colorChooserOptions;


  PreferenceManager(SharedPreferences prefs) : _prefs = prefs
  {
    _init();
    canvasOptions = CanvasOptions(
        stylusPollRate: getValueI(PreferenceInt.Layout_Canvas_Stylus_PollRate),
        longPressDuration: getValueI(PreferenceInt.Layout_Canvas_LongPressDuration),
        longPressCancelDistance: getValueD(PreferenceDouble.Layout_Canvas_LongPressCancelDistance));
    toolsOptions = ToolsWidgetOptions(
        padding: getValueD(PreferenceDouble.Layout_Tools_Padding),
        buttonResizeFactor: getValueD(PreferenceDouble.Layout_Tools_ButtonResizeFactor),
        spacingFactor: getValueD(PreferenceDouble.Layout_Tools_SpacingFactor),
        iconSize: getValueD(PreferenceDouble.Layout_Tools_IconSize));
    paletteOptions = PaletteWidgetOptions(
        padding: getValueD(PreferenceDouble.Layout_Palette_Padding),
        columnCountResizeFactor: getValueD(PreferenceDouble.Layout_Palette_ColumnCountResizeFactor),
        topiconSize: getValueD(PreferenceDouble.Layout_Palette_TopIconSize),
        addIconSize: getValueD(PreferenceDouble.Layout_Palette_AddIconSize));
    colorEntryOptions = ColorEntryWidgetOptions(
        unselectedMargin: getValueD(PreferenceDouble.Layout_ColorEntry_UnselectedMargin),
        selectedMargin: getValueD(PreferenceDouble.Layout_ColorEntry_SelectedMargin),
        roundRadius: getValueD(PreferenceDouble.Layout_ColorEntry_RoundRadius),
        contrastColorThreshold: getValueD(PreferenceDouble.Layout_ColorEntry_ContrastColorThreshold),
        hsvDisplayDigits: getValueI(PreferenceInt.Layout_ColorEntry_HsvDisplayDigits),
        hoverTimer: getValueI(PreferenceInt.Layout_ColorEntry_HoverTimer));
    colorChooserOptions = ColorChooserWidgetOptions(
        iconButtonSize: getValueD(PreferenceDouble.Layout_ColorChooser_IconSize),
        colorContainerBorderRadius: getValueD(PreferenceDouble.Layout_ColorChooser_ColorContainerBorderRadius),
        padding: getValueD(PreferenceDouble.Layout_ColorChooser_Padding));

  }

  void _init()
  {
    for (PreferenceDouble dblEnum in PreferenceDouble.values)
    {
      _doubleMap[dblEnum] = _DoublePair(_prefs.getDouble(dblEnum.name) ?? dblEnum.defaultValue);
    }

    for (PreferenceInt intEnum in PreferenceInt.values)
    {
      _intMap[intEnum] = _IntPair(_prefs.getInt(intEnum.name) ?? intEnum.defaultValue);
    }
  }

double getValueD(PreferenceDouble prefName)
{
  double retVal = 0.0;
  final double? val = _doubleMap[prefName]?.value;
  if (val != null)
  {
    retVal = val;
  }
  return retVal;
}

int getValueI(PreferenceInt prefName)
{
  int retVal = 0;
  final int? val = _intMap[prefName]?.value;
  if (val != null)
  {
    retVal = val;
  }
  return retVal;
}


   Future<void> savePreferences()
  async {
    _doubleMap.forEach((key, value)
    {
      if (value.changed)
      {
        _prefs.setDouble(key.name, value.value);
      }
    });
    _intMap.forEach((key, value)
    {
      if (value.changed)
      {
        _prefs.setInt(key.name, value.value);
      }
    });
  }

}

