
// ignore_for_file: constant_identifier_names
import 'package:kpix/tool_options.dart';
import 'package:kpix/shader_options.dart';
import 'package:kpix/widgets/color_chooser_widget.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/listener_example.dart';
import 'package:kpix/widgets/main_toolbar_widget.dart';
import 'package:kpix/widgets/palette_widget.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';
import 'package:kpix/widgets/tools_widget.dart';
import 'package:kpix/widgets/shader_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PreferenceDouble
{
  Layout_SplitViewHorizontal_Ratio(defaultValue: 0.75),
  Layout_SplitViewHorizontal_TopMinRatio(defaultValue: 0.5),
  Layout_SplitViewHorizontal_BottomMinRatio(defaultValue: 0.1),

  Layout_SplitViewVertical_Ratio(defaultValue: 0.25),
  Layout_SplitViewVertical_LeftMinRatio(defaultValue: 0.16),
  Layout_SplitViewVertical_RightMinRatio(defaultValue: 0.6),

  Layout_Canvas_LongPressCancelDistance(defaultValue: 10.0),

  Layout_Tools_Padding(defaultValue: 8.0),
  Layout_Tools_ButtonResizeFactor(defaultValue: 52.0),
  Layout_Tools_SpacingFactor(defaultValue: 32.0),
  Layout_Tools_IconSize(defaultValue: 20.0),

  Layout_Palette_Padding(defaultValue: 8.0),
  Layout_Palette_ColumnCountResizeFactor(defaultValue: 52.0),
  Layout_Palette_TopIconSize(defaultValue: 24.0),
  Layout_Palette_SelectedColorHeightMin(defaultValue: 8.0),
  Layout_Palette_SelectedColorHeightMax(defaultValue: 24.0),

  Layout_ColorEntry_AddIconSize(defaultValue: 24.0),
  Layout_ColorEntry_UnselectedMargin(defaultValue: 4.0),
  Layout_ColorEntry_SelectedMargin(defaultValue: 0.0),
  Layout_ColorEntry_RoundRadius(defaultValue: 8.0),
  Layout_ColorEntry_ContrastColorThreshold(defaultValue: 0.95),
  Layout_ColorEntry_ButtonPadding(defaultValue: 4.0),
  Layout_ColorEntry_MinSize(defaultValue: 8.0),
  Layout_ColorEntry_MaxSize(defaultValue: 64.0),
  Layout_ColorEntry_DragFeedbackSize(defaultValue: 32.0),
  Layout_ColorEntry_DragTargetWidth(defaultValue: 8.0),

  Layout_ColorChooser_IconSize(defaultValue: 36.0),
  Layout_ColorChooser_ColorContainerBorderRadius(defaultValue: 16.0),
  Layout_ColorChooser_Padding(defaultValue: 8.0),

  Layout_ToolsSettings_Padding(defaultValue: 8.0),

  Layout_MainToolbar_DividerHeight(defaultValue: 2.0),

  Layout_Shader_OutsidePadding(defaultValue: 8.0),


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
  Layout_ColorEntry_Stylus_PollRate(defaultValue: 100),
  Layout_ColorEntry_LongPressDuration(defaultValue: 1000),
  Layout_ColorEntry_DragDelay(defaultValue: 100),
  Layout_ColorEntry_DragFeedbackAlpha(defaultValue: 160),

  Layout_ToolSettings_ColumnWidthRatio(defaultValue: 2),
  Layout_ToolSettings_CrossFadeDuration(defaultValue: 100),

  Layout_MainToolbar_PaletteFlex(defaultValue: 6),
  Layout_MainToolbar_ToolSettingsFlex(defaultValue: 4),

  Tool_Pencil_SizeMin(defaultValue: 1),
  Tool_Pencil_SizeMax(defaultValue: 32),
  Tool_Pencil_SizeDefault(defaultValue: 1),
  Tool_Pencil_ShapeDefault(defaultValue: 0),

  ;


  const PreferenceInt({
    required this.defaultValue
  });
  final int defaultValue;
}

enum PreferenceBool
{
  Tool_Pencil_PixelPerfect(defaultValue: true),

  Shader_IsEnabledDefault(defaultValue: false),
  Shader_DirectionRightDefault(defaultValue: true),
  Shader_CurrentRampOnlyDefault(defaultValue: false),

  ;
  const PreferenceBool({
    required this.defaultValue
  });
  final bool defaultValue;
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

class _BoolPair
{
  final bool value;
  bool changed = false;
  _BoolPair(bool val) : value = val;
}

class PreferenceManager
{
  final SharedPreferences _prefs;
  final Map<PreferenceDouble, _DoublePair> _doubleMap = {};
  final Map<PreferenceInt, _IntPair> _intMap = {};
  final Map<PreferenceBool, _BoolPair> _boolMap = {};
  late CanvasOptions canvasWidgetOptions;
  late ToolsWidgetOptions toolsWidgetOptions;
  late PaletteWidgetOptions paletteWidgetOptions;
  late ColorEntryWidgetOptions colorEntryOptions;
  late ColorChooserWidgetOptions colorChooserWidgetOptions;
  late ToolSettingsWidgetOptions toolSettingsWidgetOptions;
  late MainToolbarWidgetOptions mainToolbarWidgetOptions;
  late ShaderWidgetOptions shaderWidgetOptions;

  late ToolOptions toolOptions;
  late ShaderOptions shaderOptions;


  PreferenceManager(SharedPreferences prefs) : _prefs = prefs
  {
    _init();
    canvasWidgetOptions = CanvasOptions(
        stylusPollRate: getValueI(PreferenceInt.Layout_Canvas_Stylus_PollRate),
        longPressDuration: getValueI(PreferenceInt.Layout_Canvas_LongPressDuration),
        longPressCancelDistance: getValueD(PreferenceDouble.Layout_Canvas_LongPressCancelDistance));
    toolsWidgetOptions = ToolsWidgetOptions(
        padding: getValueD(PreferenceDouble.Layout_Tools_Padding),
        buttonResizeFactor: getValueD(PreferenceDouble.Layout_Tools_ButtonResizeFactor),
        spacingFactor: getValueD(PreferenceDouble.Layout_Tools_SpacingFactor),
        iconSize: getValueD(PreferenceDouble.Layout_Tools_IconSize));
    paletteWidgetOptions = PaletteWidgetOptions(
        padding: getValueD(PreferenceDouble.Layout_Palette_Padding),
        columnCountResizeFactor: getValueD(PreferenceDouble.Layout_Palette_ColumnCountResizeFactor),
        topIconSize: getValueD(PreferenceDouble.Layout_Palette_TopIconSize),
        selectedColorHeightMin: getValueD(PreferenceDouble.Layout_Palette_SelectedColorHeightMin),
        selectedColorHeightMax: getValueD(PreferenceDouble.Layout_Palette_SelectedColorHeightMax));
    colorEntryOptions = ColorEntryWidgetOptions(
        unselectedMargin: getValueD(PreferenceDouble.Layout_ColorEntry_UnselectedMargin),
        selectedMargin: getValueD(PreferenceDouble.Layout_ColorEntry_SelectedMargin),
        roundRadius: getValueD(PreferenceDouble.Layout_ColorEntry_RoundRadius),
        contrastColorThreshold: getValueD(PreferenceDouble.Layout_ColorEntry_ContrastColorThreshold),
        hsvDisplayDigits: getValueI(PreferenceInt.Layout_ColorEntry_HsvDisplayDigits),
        hoverTimer: getValueI(PreferenceInt.Layout_ColorEntry_HoverTimer),
        stylusPollRate: getValueI(PreferenceInt.Layout_ColorEntry_Stylus_PollRate),
        longPressDuration: getValueI(PreferenceInt.Layout_ColorEntry_LongPressDuration),
        addIconSize: getValueD(PreferenceDouble.Layout_ColorEntry_AddIconSize),
        buttonPadding: getValueD(PreferenceDouble.Layout_ColorEntry_ButtonPadding),
        minSize: getValueD(PreferenceDouble.Layout_ColorEntry_MinSize),
        maxSize: getValueD(PreferenceDouble.Layout_ColorEntry_MaxSize),
        dragFeedbackSize: getValueD(PreferenceDouble.Layout_ColorEntry_DragFeedbackSize),
        dragDelay: getValueI(PreferenceInt.Layout_ColorEntry_DragDelay),
        dragFeedbackAlpha: getValueI(PreferenceInt.Layout_ColorEntry_DragFeedbackAlpha),
        dragTargetWidth: getValueD(PreferenceDouble.Layout_ColorEntry_DragTargetWidth));
    colorChooserWidgetOptions = ColorChooserWidgetOptions(
        iconButtonSize: getValueD(PreferenceDouble.Layout_ColorChooser_IconSize),
        colorContainerBorderRadius: getValueD(PreferenceDouble.Layout_ColorChooser_ColorContainerBorderRadius),
        padding: getValueD(PreferenceDouble.Layout_ColorChooser_Padding),);
    toolSettingsWidgetOptions = ToolSettingsWidgetOptions(
        columnWidthRatio: getValueI(PreferenceInt.Layout_ToolSettings_ColumnWidthRatio),
        padding: getValueD(PreferenceDouble.Layout_ToolsSettings_Padding),
        crossFadeDuration: getValueI(PreferenceInt.Layout_ToolSettings_CrossFadeDuration));
    mainToolbarWidgetOptions = MainToolbarWidgetOptions(
        paletteFlex: getValueI(PreferenceInt.Layout_MainToolbar_PaletteFlex),
        toolSettingsFlex: getValueI(PreferenceInt.Layout_MainToolbar_ToolSettingsFlex),
        dividerHeight: getValueD(PreferenceDouble.Layout_MainToolbar_DividerHeight));
    shaderWidgetOptions = ShaderWidgetOptions(
        outSidePadding: getValueD(PreferenceDouble.Layout_Shader_OutsidePadding));

    shaderOptions = ShaderOptions(
        shaderDirectionDefault: getValueB(PreferenceBool.Shader_DirectionRightDefault),
        onlyCurrentRampEnabledDefault: getValueB(PreferenceBool.Shader_CurrentRampOnlyDefault),
        isEnabledDefault: getValueB(PreferenceBool.Shader_IsEnabledDefault));

    PencilOptions pencilOptions = PencilOptions(
        sizeMin: getValueI(PreferenceInt.Tool_Pencil_SizeMin),
        sizeMax: getValueI(PreferenceInt.Tool_Pencil_SizeMax),
        sizeDefault: getValueI(PreferenceInt.Tool_Pencil_SizeDefault),
        shapeDefault: getValueI(PreferenceInt.Tool_Pencil_ShapeDefault),
        pixelPerfectDefault: getValueB(PreferenceBool.Tool_Pencil_PixelPerfect));
    toolOptions = ToolOptions(pencilOptions: pencilOptions);
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

    for (PreferenceBool boolEnum in PreferenceBool.values)
    {
      _boolMap[boolEnum] = _BoolPair(_prefs.getBool(boolEnum.name) ?? boolEnum.defaultValue);
    }
  }

double getValueD(PreferenceDouble prefName)
{
  return _doubleMap[prefName]?.value ?? 0.0;
}

int getValueI(PreferenceInt prefName)
{
  return _intMap[prefName]?.value ?? 0;
}

bool getValueB(PreferenceBool prefName)
{
  return _boolMap[prefName]?.value ?? false;
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

