
// ignore_for_file: constant_identifier_names
import 'package:kpix/color_names.dart';
import 'package:kpix/font_manager.dart';
import 'package:kpix/main.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/tool_options/color_pick_options.dart';
import 'package:kpix/tool_options/curve_options.dart';
import 'package:kpix/tool_options/eraser_options.dart';
import 'package:kpix/tool_options/fill_options.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/shape_options.dart';
import 'package:kpix/tool_options/spray_can_options.dart';
import 'package:kpix/tool_options/text_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/shader_options.dart';
import 'package:kpix/tool_options/wand_options.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/main_button_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:kpix/widgets/color_chooser_widget.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/canvas_widget.dart';
import 'package:kpix/widgets/main_toolbar_widget.dart';
import 'package:kpix/widgets/palette_widget.dart';
import 'package:kpix/widgets/selection_bar_widget.dart';
import 'package:kpix/widgets/status_bar_widget.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';
import 'package:kpix/widgets/tools_widget.dart';
import 'package:kpix/widgets/shader_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kpal/kpal_widget.dart';

enum PreferenceDouble
{
  Layout_SplitView_DividerWidth(defaultValue: 8.0),
  Layout_SplitView_GrooveGap(defaultValue: 8.0),
  Layout_SplitView_GrooveThickness(defaultValue: 4.0),
  Layout_SplitView_GrooveSize(defaultValue: 2.0),
  Layout_SplitView_FlexLeftMin(defaultValue: 3),
  Layout_SplitView_FlexLeftMax(defaultValue: 4.0),
  Layout_SplitView_FlexRightMin(defaultValue: 2.0),
  Layout_SplitView_FlexRightMax(defaultValue: 3.0),
  Layout_SplitView_FlexLeftDefault(defaultValue: 3.5),
  Layout_SplitView_FlexCenterDefault(defaultValue: 12.0),
  Layout_SplitView_FlexRightDefault(defaultValue: 2.0),

  Layout_Canvas_LongPressCancelDistance(defaultValue: 10.0),
  Layout_Canvas_StylusZoomStepDistance(defaultValue: 10.0),
  Layout_Canvas_TouchZoomStepDistance(defaultValue: 25.0),
  Layout_Canvas_MinVisibilityFactor(defaultValue: 0.1),

  Layout_Tools_Padding(defaultValue: 8.0),
  Layout_Tools_IconSize(defaultValue: 16.0),
  Layout_Tools_ButtonSize(defaultValue: 48.0),

  Layout_Palette_Padding(defaultValue: 8.0),

  Layout_ColorEntry_AddIconSize(defaultValue: 24.0),
  Layout_ColorEntry_SettingsIconSize(defaultValue: 24.0),
  Layout_ColorEntry_UnselectedMargin(defaultValue: 2.0),
  Layout_ColorEntry_SelectedMargin(defaultValue: 0.0),
  Layout_ColorEntry_RoundRadius(defaultValue: 4.0),
  Layout_ColorEntry_ButtonPadding(defaultValue: 4.0),
  Layout_ColorEntry_MinSize(defaultValue: 8.0),
  Layout_ColorEntry_MaxSize(defaultValue: 32.0),

  Layout_ColorChooser_IconSize(defaultValue: 36.0),
  Layout_ColorChooser_ColorContainerBorderRadius(defaultValue: 16.0),
  Layout_ColorChooser_Padding(defaultValue: 8.0),
  Layout_ColorChooser_Width(defaultValue: 400.0),
  Layout_ColorChooser_Height(defaultValue: 500.0),
  Layout_ColorChooser_DividerWidth(defaultValue: 2.0),
  Layout_ColorChooser_Elevation(defaultValue: 16.0),
  Layout_ColorChooser_BorderRadius(defaultValue: 16.0),
  Layout_ColorChooser_BorderWidth(defaultValue: 2.0),
  Layout_ColorChooser_OutsidePadding(defaultValue: 16.0),

  Layout_ToolsSettings_Padding(defaultValue: 8.0),

  Layout_MainToolbar_DividerHeight(defaultValue: 2.0),
  Layout_MainToolbar_DividerPadding(defaultValue: 8.0),

  Layout_Shader_OutsidePadding(defaultValue: 8.0),

  Layout_StatusBar_Height(defaultValue: 20.0),
  Layout_StatusBar_Padding(defaultValue: 2.0),
  Layout_StatusBar_DividerWidth(defaultValue: 2.0),

  Layout_OverlayEntrySubMenu_OffsetX(defaultValue: -32.0),
  Layout_OverlayEntrySubMenu_OffsetXLeft(defaultValue: -128.0),
  Layout_OverlayEntrySubMenu_OffsetY(defaultValue: 32.0),
  Layout_OverlayEntrySubMenu_ButtonSpacing(defaultValue: 6.0),
  Layout_OverlayEntrySubMenu_Width(defaultValue: 160.0),
  Layout_OverlayEntrySubMenu_ButtonHeight(defaultValue: 40.0),

  Layout_OverlayAlertDialog_MinWidth(defaultValue: 200.0),
  Layout_OverlayAlertDialog_MinHeight(defaultValue: 150.0),
  Layout_OverlayAlertDialog_MaxWidth(defaultValue: 500.0),
  Layout_OverlayAlertDialog_MaxHeight(defaultValue: 500.0),
  Layout_OverlayAlertDialog_Padding(defaultValue: 8.0),
  Layout_OverlayAlertDialog_BorderWidth(defaultValue: 2.0),
  Layout_OverlayAlertDialog_BorderRadius(defaultValue: 8.0),
  Layout_OverlayAlertDialog_IconSize(defaultValue: 32.0),
  Layout_OverlayAlertDialog_Elevation(defaultValue: 8.0),

  Layout_MainButton_Padding(defaultValue: 8.0),
  Layout_MainButton_MenuIconSize(defaultValue: 16.0),
  Layout_MainButton_DividerSize(defaultValue: 2.0),

  Layout_LayerWidget_OuterPadding(defaultValue: 8.0),
  Layout_LayerWidget_InnerPadding(defaultValue: 4.0),
  Layout_LayerWidget_BorderRadius(defaultValue: 8.0),
  Layout_LayerWidget_ButtonSizeMin(defaultValue: 24.0),
  Layout_LayerWidget_ButtonSizeMax(defaultValue: 32.0),
  Layout_LayerWidget_IconSize(defaultValue: 12.0),
  Layout_LayerWidget_Height(defaultValue: 64.0),
  Layout_LayerWidget_DragOpacity(defaultValue: 0.75),
  Layout_LayerWidget_BorderWidth(defaultValue: 2.0),
  Layout_LayerWidget_DragFeedbackSize(defaultValue: 64.0),
  Layout_LayerWidget_DragTargetHeight(defaultValue: 64.0),

  Layout_SelectionBar_IconHeight(defaultValue: 16.0),
  Layout_SelectionBar_Padding(defaultValue: 4.0),

  KPal_Constraints_hueShiftExpMin(defaultValue: 0.5),
  KPal_Constraints_hueShiftExpMax(defaultValue: 2.0),
  KPal_Constraints_hueShiftExpDefault(defaultValue: 1.0),
  KPal_Constraints_satShiftExpMin(defaultValue: 0.5),
  KPal_Constraints_satShiftExpMax(defaultValue: 2.0),
  KPal_Constraints_staShiftExpDefault(defaultValue: 1.0),

  KPal_Layout_BorderRadius(defaultValue: 8.0),
  KPal_Layout_BorderWidth(defaultValue: 2.0),
  KPal_Layout_OutsidePadding(defaultValue: 16.0),
  KPal_Layout_InsidePadding(defaultValue: 8.0),
  KPal_Layout_IconSize(defaultValue: 32.0),

  KPalRamp_Layout_OutsidePadding(defaultValue: 8.0),
  KPalRamp_Layout_MinHeight(defaultValue: 128.0),
  KPalRamp_Layout_MaxHeight(defaultValue: 400.0),
  KPalRamp_Layout_BorderWidth(defaultValue: 4.0),
  KPalRamp_Layout_DividerThickness(defaultValue: 2.0),
  KPalRamp_Layout_BorderRadius(defaultValue: 8.0),

  KPalColorCard_Layout_BorderRadius(defaultValue: 8.0),
  KPalColorCard_Layout_BorderWidth(defaultValue: 2.0),
  KPalColorCard_Layout_OutsidePadding(defaultValue: 8.0),

  Painter_CursorSize(defaultValue: 4.0),
  Painter_CursorBorderWidth(defaultValue: 2.0),
  Painter_SelectionSolidStrokeWidth(defaultValue: 2.0),
  Painter_PixelExtensionFactor(defaultValue: 0.1),
  Painter_CheckerBoardDivisor(defaultValue: 2.0),
  Painter_CheckerBoardSizeMin(defaultValue: 8.0),
  Painter_CheckerBoardSizeMax(defaultValue: 64.0),
  Painter_SelectionDashStrokeWidth(defaultValue: 2.0),
  Painter_SelectionDashSegmentLength(defaultValue: 8.0),
  Painter_SelectionCircleSegmentCount(defaultValue: 32.0),
  Painter_SelectionCursorStrokeWidth(defaultValue: 2.0),
  ;

  const PreferenceDouble({
    required this.defaultValue,
  });

  final double defaultValue;
}

enum PreferenceInt
{
  Layout_SplitView_GrooveCountMin(defaultValue: 5),
  Layout_SplitView_GrooveCountMax(defaultValue: 9),
  Layout_SplitView_AnimationLength(defaultValue: 250),

  Layout_Canvas_LongPressDuration(defaultValue: 250),
  Layout_Canvas_Stylus_PollRate(defaultValue: 100),

  Layout_ColorChooser_SmokeOpacity(defaultValue: 128),

  Layout_Tools_ColCount(defaultValue: 6),

  Layout_ToolSettings_ColumnWidthRatio(defaultValue: 2),

  Layout_MainToolbar_PaletteFlex(defaultValue: 2),
  Layout_MainToolbar_ToolSettingsFlex(defaultValue: 1),

  Layout_OverlayEntry_SmokeOpacity(defaultValue: 128),

  Layout_LayerWidget_DragTargetShowDuration(defaultValue: 100),
  Layout_LayerWidget_DragDelay(defaultValue: 200),

  Layout_SelectionBar_OpacityDuration(defaultValue: 150),

  Tool_Pencil_SizeMin(defaultValue: 1),
  Tool_Pencil_SizeMax(defaultValue: 32),
  Tool_Pencil_Size(defaultValue: 1),
  Tool_Pencil_Shape(defaultValue: 0),
  Tool_Shape_Shape(defaultValue: 0),
  Tool_Shape_StrokeWidthMin(defaultValue: 1),
  Tool_Shape_StrokeWidthMax(defaultValue: 16),
  Tool_Shape_StrokeWidth(defaultValue: 1),
  Tool_Shape_CornerRadiusMin(defaultValue: 0),
  Tool_Shape_CornerRadiusMax(defaultValue: 16),
  Tool_Shape_CornerRadius(defaultValue: 0),
  Tool_Select_Shape(defaultValue: 0),
  Tool_Select_Mode(defaultValue: 0),
  Tool_Eraser_SizeMin(defaultValue: 1),
  Tool_Eraser_SizeMax(defaultValue: 32),
  Tool_Eraser_Size(defaultValue: 1),
  Tool_Eraser_Shape(defaultValue: 0),
  Tool_Text_SizeMin(defaultValue: 1),
  Tool_Text_SizeMax(defaultValue: 16),
  Tool_Text_Size(defaultValue: 1),
  Tool_Text_Font(defaultValue: 0),
  Tool_Text_MaxLength(defaultValue: 32),
  Tool_SprayCan_RadiusMin(defaultValue: 3),
  Tool_SprayCan_RadiusMax(defaultValue: 32),
  Tool_SprayCan_Radius(defaultValue: 8),
  Tool_SprayCan_BlobSizeMin(defaultValue: 1),
  Tool_SprayCan_BlobSizeMax(defaultValue: 8),
  Tool_SprayCan_BlobSize(defaultValue: 1),
  Tool_SprayCan_IntensityMin(defaultValue: 1),
  Tool_SprayCan_IntensityMax(defaultValue: 32),
  Tool_SprayCan_Intensity(defaultValue: 8),
  Tool_Line_WidthMin(defaultValue: 1),
  Tool_Line_WidthMax(defaultValue: 16),
  Tool_Line_Width(defaultValue: 1),
  Tool_Curve_WidthMin(defaultValue: 1),
  Tool_Curve_WidthMax(defaultValue: 16),
  Tool_Curve_Width(defaultValue: 1),
  Tool_Wand_Mode(defaultValue: 0),




  KPal_Constraints_ColorCountMin(defaultValue: 3),
  KPal_Constraints_ColorCountMax(defaultValue: 15),
  KPal_Constraints_ColorCountDefault(defaultValue: 5),
  KPal_Constraints_BaseHueMin(defaultValue: 0),
  KPal_Constraints_BaseHueMax(defaultValue: 360),
  KPal_Constraints_BaseHueDefault(defaultValue: 180),
  KPal_Constraints_BaseSatMin(defaultValue: 0),
  KPal_Constraints_BaseSatMax(defaultValue: 100),
  KPal_Constraints_BaseSatDefault(defaultValue: 60),
  KPal_Constraints_HueShiftMin(defaultValue: -90),
  KPal_Constraints_HueShiftMax(defaultValue: 90),
  KPal_Constraints_HueShiftDefault(defaultValue: -10),
  KPal_Constraints_SatShiftMin(defaultValue: -25),
  KPal_Constraints_SatShiftMax(defaultValue: 25),
  KPal_Constraints_SatShiftDefault(defaultValue: -10),
  KPal_Constraints_ValueRangeMin(defaultValue: 0),
  KPal_Constraints_ValueRangeMinDefault(defaultValue: 15),
  KPal_Constraints_ValueRangeMax(defaultValue: 100),
  KPal_Constraints_ValueRangeMaxDefault(defaultValue: 95),
  KPal_Constraints_SatCurveDefault(defaultValue: 0),

  KPal_Layout_SmokeOpacity(defaultValue: 128),

  KPalRamp_Layout_CenterFlex(defaultValue: 4),
  KPalRamp_Layout_RightFlex(defaultValue: 1),
  KPalRamp_Layout_RowLabelFlex(defaultValue: 2),
  KPalRamp_Layout_RowControlFlex(defaultValue: 8),
  KPalRamp_Layout_RowValueFlex(defaultValue: 2),

  KPalColorCard_Layout_ColorNameFlex(defaultValue: 1),
  KPalColorCard_Layout_ColorFlex(defaultValue: 6),
  KPalColorCard_Layout_ColorNumbersFlex(defaultValue: 1),

  ColorNames_Scheme(defaultValue: 0),

  ;


  const PreferenceInt({
    required this.defaultValue
  });
  final int defaultValue;
}

enum PreferenceBool
{
  Shader_IsEnabled(defaultValue: false),
  Shader_DirectionRight(defaultValue: true),
  Shader_CurrentRampOnly(defaultValue: false),

  Tool_Pencil_PixelPerfect(defaultValue: true),
  Tool_Shape_KeepAspectRatio(defaultValue: false),
  Tool_Shape_StrokeOnly(defaultValue: true),
  Tool_Fill_FillAdjacent(defaultValue: true),
  Tool_Select_KeepAspectRatio(defaultValue: false),
  Tool_Line_IntegerAspectRatio(defaultValue: false),
  Tool_Wand_SelectFromWholeRamp(defaultValue: false),
  ;
  const PreferenceBool({
    required this.defaultValue
  });
  final bool defaultValue;
}

enum PreferenceString
{
  Tool_Text_TextDefault(defaultValue: "Text"),

  ColorNames_ColorNamePath(defaultValue: "color_names"),

  ;
  const PreferenceString({
    required this.defaultValue
  });
  final String defaultValue;
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

class _StringPair
{
  final String value;
  bool changed = false;
  _StringPair(String val) : value = val;
}

class PreferenceManager
{
  final SharedPreferences _prefs;
  final Map<PreferenceDouble, _DoublePair> _doubleMap = {};
  final Map<PreferenceInt, _IntPair> _intMap = {};
  final Map<PreferenceBool, _BoolPair> _boolMap = {};
  final Map<PreferenceString, _StringPair> _stringMap = {};
  late MainLayoutOptions mainLayoutOptions;
  late CanvasOptions canvasWidgetOptions;
  late ToolsWidgetOptions toolsWidgetOptions;
  late PaletteWidgetOptions paletteWidgetOptions;
  late ColorEntryWidgetOptions colorEntryOptions;
  late ColorChooserWidgetOptions colorChooserWidgetOptions;
  late ToolSettingsWidgetOptions toolSettingsWidgetOptions;
  late MainToolbarWidgetOptions mainToolbarWidgetOptions;
  late ShaderWidgetOptions shaderWidgetOptions;
  late StatusBarWidgetOptions statusBarWidgetOptions;
  late OverlayEntrySubMenuOptions overlayEntryOptions;
  late OverlayEntryAlertDialogOptions alertDialogOptions;
  late MainButtonWidgetOptions mainButtonWidgetOptions;
  late LayerWidgetOptions layerWidgetOptions;
  late SelectionBarWidgetOptions selectionBarWidgetOptions;

  late KPixPainterOptions kPixPainterOptions;

  late ToolOptions toolOptions;
  late ShaderOptions shaderOptions;

  late KPalConstraints kPalConstraints;
  late KPalWidgetOptions kPalWidgetOptions;

  late ColorNames colorNames;

  final FontManager _fontManager;

  PreferenceManager(final SharedPreferences prefs, final FontManager fontManager) : _prefs = prefs, _fontManager = fontManager
  {
    _init();
    loadWidgetOptions();
    loadToolOptions();
    loadKPalOptions();
    loadColorNames();
    loadPainterOptions();

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

    for (PreferenceString stringEnum in PreferenceString.values)
    {
      _stringMap[stringEnum] = _StringPair(_prefs.getString(stringEnum.name) ?? stringEnum.defaultValue);
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

  String getValueS(PreferenceString prefName)
  {
    return _stringMap[prefName]?.value ?? "";
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


  void loadWidgetOptions()
  {
    mainLayoutOptions = MainLayoutOptions(
        splitViewDividerWidth: getValueD(PreferenceDouble.Layout_SplitView_DividerWidth),
        splitViewGrooveGap: getValueD(PreferenceDouble.Layout_SplitView_GrooveGap),
        splitViewGrooveThickness: getValueD(PreferenceDouble.Layout_SplitView_GrooveThickness),
        splitViewGrooveSize: getValueD(PreferenceDouble.Layout_SplitView_GrooveSize),
        splitViewFlexLeftMin: getValueD(PreferenceDouble.Layout_SplitView_FlexLeftMin),
        splitViewFlexLeftMax: getValueD(PreferenceDouble.Layout_SplitView_FlexLeftMax),
        splitViewFlexRightMin: getValueD(PreferenceDouble.Layout_SplitView_FlexRightMin),
        splitViewFlexRightMax: getValueD(PreferenceDouble.Layout_SplitView_FlexRightMax),
        splitViewGrooveCountMin: getValueI(PreferenceInt.Layout_SplitView_GrooveCountMin),
        splitViewGrooveCountMax: getValueI(PreferenceInt.Layout_SplitView_GrooveCountMax),
        splitViewAnimationLength: getValueI(PreferenceInt.Layout_SplitView_AnimationLength),
        splitViewFlexLeftDefault: getValueD(PreferenceDouble.Layout_SplitView_FlexLeftDefault),
        splitViewFlexCenterDefault: getValueD(PreferenceDouble.Layout_SplitView_FlexCenterDefault),
        splitViewFlexRightDefault: getValueD(PreferenceDouble.Layout_SplitView_FlexRightDefault));
    canvasWidgetOptions = CanvasOptions(
        stylusPollRate: getValueI(PreferenceInt.Layout_Canvas_Stylus_PollRate),
        longPressDuration: getValueI(PreferenceInt.Layout_Canvas_LongPressDuration),
        longPressCancelDistance: getValueD(PreferenceDouble.Layout_Canvas_LongPressCancelDistance),
        stylusZoomStepDistance: getValueD(PreferenceDouble.Layout_Canvas_StylusZoomStepDistance),
        touchZoomStepDistance: getValueD(PreferenceDouble.Layout_Canvas_TouchZoomStepDistance),
        minVisibilityFactor: getValueD(PreferenceDouble.Layout_Canvas_MinVisibilityFactor));
    toolsWidgetOptions = ToolsWidgetOptions(
        padding: getValueD(PreferenceDouble.Layout_Tools_Padding),
        colCount: getValueI(PreferenceInt.Layout_Tools_ColCount),
        buttonSize: getValueD(PreferenceDouble.Layout_Tools_ButtonSize),
        iconSize: getValueD(PreferenceDouble.Layout_Tools_IconSize));
    paletteWidgetOptions = PaletteWidgetOptions(
        padding: getValueD(PreferenceDouble.Layout_Palette_Padding));
    colorEntryOptions = ColorEntryWidgetOptions(
        unselectedMargin: getValueD(PreferenceDouble.Layout_ColorEntry_UnselectedMargin),
        selectedMargin: getValueD(PreferenceDouble.Layout_ColorEntry_SelectedMargin),
        roundRadius: getValueD(PreferenceDouble.Layout_ColorEntry_RoundRadius),
        addIconSize: getValueD(PreferenceDouble.Layout_ColorEntry_AddIconSize),
        settingsIconSize: getValueD(PreferenceDouble.Layout_ColorEntry_SettingsIconSize),
        buttonPadding: getValueD(PreferenceDouble.Layout_ColorEntry_ButtonPadding),
        minSize: getValueD(PreferenceDouble.Layout_ColorEntry_MinSize),
        maxSize: getValueD(PreferenceDouble.Layout_ColorEntry_MaxSize),);
    colorChooserWidgetOptions = ColorChooserWidgetOptions(
        iconButtonSize: getValueD(PreferenceDouble.Layout_ColorChooser_IconSize),
        colorContainerBorderRadius: getValueD(PreferenceDouble.Layout_ColorChooser_ColorContainerBorderRadius),
        padding: getValueD(PreferenceDouble.Layout_ColorChooser_Padding),
        smokeOpacity: getValueI(PreferenceInt.Layout_ColorChooser_SmokeOpacity),
        width: getValueD(PreferenceDouble.Layout_ColorChooser_Width),
        height: getValueD(PreferenceDouble.Layout_ColorChooser_Height),
        dividerThickness: getValueD(PreferenceDouble.Layout_ColorChooser_DividerWidth),
        elevation: getValueD(PreferenceDouble.Layout_ColorChooser_Elevation),
        borderRadius: getValueD(PreferenceDouble.Layout_ColorChooser_BorderRadius),
        borderWidth: getValueD(PreferenceDouble.Layout_ColorChooser_BorderWidth),
        outsidePadding: getValueD(PreferenceDouble.Layout_ColorChooser_OutsidePadding));
    toolSettingsWidgetOptions = ToolSettingsWidgetOptions(
        columnWidthRatio: getValueI(PreferenceInt.Layout_ToolSettings_ColumnWidthRatio),
        padding: getValueD(PreferenceDouble.Layout_ToolsSettings_Padding));
    mainToolbarWidgetOptions = MainToolbarWidgetOptions(
        paletteFlex: getValueI(PreferenceInt.Layout_MainToolbar_PaletteFlex),
        toolSettingsFlex: getValueI(PreferenceInt.Layout_MainToolbar_ToolSettingsFlex),
        dividerHeight: getValueD(PreferenceDouble.Layout_MainToolbar_DividerHeight),
        dividerPadding: getValueD(PreferenceDouble.Layout_MainToolbar_DividerPadding),);
    shaderWidgetOptions = ShaderWidgetOptions(
        outSidePadding: getValueD(PreferenceDouble.Layout_Shader_OutsidePadding));
    statusBarWidgetOptions = StatusBarWidgetOptions(
      height: getValueD(PreferenceDouble.Layout_StatusBar_Height),
      padding: getValueD(PreferenceDouble.Layout_StatusBar_Padding),
      dividerWidth: getValueD(PreferenceDouble.Layout_StatusBar_DividerWidth),);
    shaderOptions = ShaderOptions(
        shaderDirectionDefault: getValueB(PreferenceBool.Shader_DirectionRight),
        onlyCurrentRampEnabledDefault: getValueB(PreferenceBool.Shader_CurrentRampOnly),
        isEnabledDefault: getValueB(PreferenceBool.Shader_IsEnabled));
    overlayEntryOptions = OverlayEntrySubMenuOptions(
        offsetX: getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_OffsetX),
        offsetXLeft: getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_OffsetXLeft),
        offsetY: getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_OffsetY),
        buttonSpacing: getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_ButtonSpacing),
        width: getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_Width),
        buttonHeight: getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_ButtonHeight),
        smokeOpacity: getValueI(PreferenceInt.Layout_OverlayEntry_SmokeOpacity));
    alertDialogOptions = OverlayEntryAlertDialogOptions(
        smokeOpacity: getValueI(PreferenceInt.Layout_OverlayEntry_SmokeOpacity),
        minWidth: getValueD(PreferenceDouble.Layout_OverlayAlertDialog_MinWidth),
        minHeight: getValueD(PreferenceDouble.Layout_OverlayAlertDialog_MinHeight),
        maxWidth: getValueD(PreferenceDouble.Layout_OverlayAlertDialog_MaxWidth),
        maxHeight: getValueD(PreferenceDouble.Layout_OverlayAlertDialog_MaxHeight),
        padding: getValueD(PreferenceDouble.Layout_OverlayAlertDialog_Padding),
        borderWidth: getValueD(PreferenceDouble.Layout_OverlayAlertDialog_BorderWidth),
        borderRadius: getValueD(PreferenceDouble.Layout_OverlayAlertDialog_BorderRadius),
        iconSize: getValueD(PreferenceDouble.Layout_OverlayAlertDialog_IconSize),
        elevation: getValueD(PreferenceDouble.Layout_OverlayAlertDialog_Elevation));
    mainButtonWidgetOptions = MainButtonWidgetOptions(
        padding: getValueD(PreferenceDouble.Layout_MainButton_Padding),
        menuIconSize: getValueD(PreferenceDouble.Layout_MainButton_MenuIconSize),
        dividerSize: getValueD(PreferenceDouble.Layout_MainButton_DividerSize));
    layerWidgetOptions = LayerWidgetOptions(
        outerPadding: getValueD(PreferenceDouble.Layout_LayerWidget_OuterPadding),
        innerPadding: getValueD(PreferenceDouble.Layout_LayerWidget_InnerPadding),
        borderRadius: getValueD(PreferenceDouble.Layout_LayerWidget_BorderRadius),
        buttonSizeMin: getValueD(PreferenceDouble.Layout_LayerWidget_ButtonSizeMin),
        buttonSizeMax: getValueD(PreferenceDouble.Layout_LayerWidget_ButtonSizeMax),
        iconSize: getValueD(PreferenceDouble.Layout_LayerWidget_IconSize),
        height: getValueD(PreferenceDouble.Layout_LayerWidget_Height),
        borderWidth: getValueD(PreferenceDouble.Layout_LayerWidget_BorderWidth),
        dragFeedbackSize: getValueD(PreferenceDouble.Layout_LayerWidget_DragFeedbackSize),
        dragOpacity: getValueD(PreferenceDouble.Layout_LayerWidget_DragOpacity),
        dragTargetHeight: getValueD(PreferenceDouble.Layout_LayerWidget_DragTargetHeight),
        dragTargetShowDuration: getValueI(PreferenceInt.Layout_LayerWidget_DragTargetShowDuration),
        dragDelay: getValueI(PreferenceInt.Layout_LayerWidget_DragDelay));
    selectionBarWidgetOptions = SelectionBarWidgetOptions(
        iconHeight: getValueD(PreferenceDouble.Layout_SelectionBar_IconHeight,),
        padding: getValueD(PreferenceDouble.Layout_SelectionBar_Padding),
        opacityDuration: getValueI(PreferenceInt.Layout_SelectionBar_OpacityDuration));

  }

  void loadToolOptions()
  {
    PencilOptions pencilOptions = PencilOptions(
        sizeMin: getValueI(PreferenceInt.Tool_Pencil_SizeMin),
        sizeMax: getValueI(PreferenceInt.Tool_Pencil_SizeMax),
        sizeDefault: getValueI(PreferenceInt.Tool_Pencil_Size),
        shapeDefault: getValueI(PreferenceInt.Tool_Pencil_Shape),
        pixelPerfectDefault: getValueB(PreferenceBool.Tool_Pencil_PixelPerfect));
    ShapeOptions shapeOptions = ShapeOptions(
        shapeDefault: getValueI(PreferenceInt.Tool_Shape_Shape),
        keepRatioDefault: getValueB(PreferenceBool.Tool_Shape_KeepAspectRatio),
        strokeOnlyDefault: getValueB(PreferenceBool.Tool_Shape_StrokeOnly),
        strokeWidthMin: getValueI(PreferenceInt.Tool_Shape_StrokeWidthMin),
        strokeWidthMax: getValueI(PreferenceInt.Tool_Shape_StrokeWidthMax),
        strokeWidthDefault: getValueI(PreferenceInt.Tool_Shape_StrokeWidth),
        cornerRadiusMin: getValueI(PreferenceInt.Tool_Shape_CornerRadiusMin),
        cornerRadiusMax: getValueI(PreferenceInt.Tool_Shape_CornerRadiusMax),
        cornerRadiusDefault: getValueI(PreferenceInt.Tool_Shape_CornerRadius));
    FillOptions fillOptions = FillOptions(
        fillAdjacentDefault: getValueB(PreferenceBool.Tool_Fill_FillAdjacent));
    SelectOptions selectOptions = SelectOptions(
        shapeDefault: getValueI(PreferenceInt.Tool_Select_Shape),
        keepAspectRatioDefault: getValueB(PreferenceBool.Tool_Select_KeepAspectRatio),
        modeDefault: getValueI(PreferenceInt.Tool_Select_Mode));
    ColorPickOptions colorPickOptions = ColorPickOptions();
    EraserOptions eraserOptions = EraserOptions(
        sizeMin: getValueI(PreferenceInt.Tool_Eraser_SizeMin),
        sizeMax: getValueI(PreferenceInt.Tool_Eraser_SizeMax),
        sizeDefault: getValueI(PreferenceInt.Tool_Eraser_Size),
        shapeDefault: getValueI(PreferenceInt.Tool_Eraser_Shape));
    TextOptions textOptions = TextOptions(
        fontManager: _fontManager,
        fontDefault: getValueI(PreferenceInt.Tool_Text_Font),
        sizeMin: getValueI(PreferenceInt.Tool_Text_SizeMin),
        sizeMax: getValueI(PreferenceInt.Tool_Text_SizeMax),
        sizeDefault: getValueI(PreferenceInt.Tool_Text_Size),
        textDefault: getValueS(PreferenceString.Tool_Text_TextDefault),
        maxLength: getValueI(PreferenceInt.Tool_Text_MaxLength));
    SprayCanOptions sprayCanOptions = SprayCanOptions(
        radiusMin: getValueI(PreferenceInt.Tool_SprayCan_RadiusMin),
        radiusMax: getValueI(PreferenceInt.Tool_SprayCan_RadiusMax),
        radiusDefault: getValueI(PreferenceInt.Tool_SprayCan_Radius),
        blobSizeMin: getValueI(PreferenceInt.Tool_SprayCan_BlobSizeMin),
        blobSizeMax: getValueI(PreferenceInt.Tool_SprayCan_BlobSizeMax),
        blobSizeDefault: getValueI(PreferenceInt.Tool_SprayCan_BlobSize),
        intensityMin: getValueI(PreferenceInt.Tool_SprayCan_IntensityMin),
        intensityMax: getValueI(PreferenceInt.Tool_SprayCan_IntensityMax),
        intensityDefault: getValueI(PreferenceInt.Tool_SprayCan_Intensity));
    LineOptions lineOptions = LineOptions(
        widthMin: getValueI(PreferenceInt.Tool_Line_WidthMin),
        widthMax: getValueI(PreferenceInt.Tool_Line_WidthMax),
        widthDefault: getValueI(PreferenceInt.Tool_Line_Width),
        integerAspectRatioDefault: getValueB(PreferenceBool.Tool_Line_IntegerAspectRatio));
    WandOptions wandOptions = WandOptions(
        selectFromWholeRampDefault: getValueB(PreferenceBool.Tool_Wand_SelectFromWholeRamp),
        modeDefault: getValueI(PreferenceInt.Tool_Wand_Mode));
    CurveOptions curveOptions = CurveOptions(
        widthMin: getValueI(PreferenceInt.Tool_Curve_WidthMin),
        widthMax: getValueI(PreferenceInt.Tool_Curve_WidthMax),
        widthDefault: getValueI(PreferenceInt.Tool_Curve_Width));
    toolOptions = ToolOptions(
        pencilOptions: pencilOptions,
        shapeOptions: shapeOptions,
        fillOptions: fillOptions,
        selectOptions: selectOptions,
        colorPickOptions: colorPickOptions,
        eraserOptions: eraserOptions,
        textOptions: textOptions,
        sprayCanOptions: sprayCanOptions,
        lineOptions: lineOptions,
        wandOptions: wandOptions,
        curveOptions: curveOptions);
  }

  void loadKPalOptions()
  {
    kPalConstraints = KPalConstraints(
        colorCountMin: getValueI(PreferenceInt.KPal_Constraints_ColorCountMin),
        colorCountMax: getValueI(PreferenceInt.KPal_Constraints_ColorCountMax),
        colorCountDefault: getValueI(PreferenceInt.KPal_Constraints_ColorCountDefault),
        baseHueMin: getValueI(PreferenceInt.KPal_Constraints_BaseHueMin),
        baseHueMax: getValueI(PreferenceInt.KPal_Constraints_BaseHueMax),
        baseHueDefault: getValueI(PreferenceInt.KPal_Constraints_BaseHueDefault),
        baseSatMin: getValueI(PreferenceInt.KPal_Constraints_BaseSatMin),
        baseSatMax: getValueI(PreferenceInt.KPal_Constraints_BaseSatMax),
        baseSatDefault: getValueI(PreferenceInt.KPal_Constraints_BaseSatDefault),
        hueShiftMin: getValueI(PreferenceInt.KPal_Constraints_HueShiftMin),
        hueShiftMax: getValueI(PreferenceInt.KPal_Constraints_HueShiftMax),
        hueShiftDefault: getValueI(PreferenceInt.KPal_Constraints_HueShiftDefault),
        hueShiftExpMin: getValueD(PreferenceDouble.KPal_Constraints_hueShiftExpMin),
        hueShiftExpMax: getValueD(PreferenceDouble.KPal_Constraints_hueShiftExpMax),
        hueShiftExpDefault: getValueD(PreferenceDouble.KPal_Constraints_hueShiftExpDefault),
        satShiftMin: getValueI(PreferenceInt.KPal_Constraints_SatShiftMin),
        satShiftMax: getValueI(PreferenceInt.KPal_Constraints_SatShiftMax),
        satShiftDefault: getValueI(PreferenceInt.KPal_Constraints_SatShiftDefault),
        satShiftExpMin: getValueD(PreferenceDouble.KPal_Constraints_satShiftExpMin),
        satShiftExpMax: getValueD(PreferenceDouble.KPal_Constraints_satShiftExpMax),
        satShiftExpDefault: getValueD(PreferenceDouble.KPal_Constraints_staShiftExpDefault),
        valueRangeMin: getValueI(PreferenceInt.KPal_Constraints_ValueRangeMin),
        valueRangeMinDefault: getValueI(PreferenceInt.KPal_Constraints_ValueRangeMinDefault),
        valueRangeMax: getValueI(PreferenceInt.KPal_Constraints_ValueRangeMax),
        valueRangeMaxDefault: getValueI(PreferenceInt.KPal_Constraints_ValueRangeMaxDefault),
        satCurveDefault: getValueI(PreferenceInt.KPal_Constraints_SatCurveDefault));

    KPalColorCardWidgetOptions colorCardWidgetOptions = KPalColorCardWidgetOptions(
        borderRadius: getValueD(PreferenceDouble.KPalColorCard_Layout_BorderRadius),
        borderWidth: getValueD(PreferenceDouble.KPalColorCard_Layout_BorderWidth),
        outsidePadding: getValueD(PreferenceDouble.KPalColorCard_Layout_OutsidePadding),
        colorFlex: getValueI(PreferenceInt.KPalColorCard_Layout_ColorFlex),
        colorNameFlex: getValueI(PreferenceInt.KPalColorCard_Layout_ColorNameFlex),
        colorNumbersFlex: getValueI(PreferenceInt.KPalColorCard_Layout_ColorNumbersFlex));

    KPalRampWidgetOptions rampWidgetOptions = KPalRampWidgetOptions(
        padding: getValueD(PreferenceDouble.KPalRamp_Layout_OutsidePadding),
        centerFlex: getValueI(PreferenceInt.KPalRamp_Layout_CenterFlex),
        rightFlex: getValueI(PreferenceInt.KPalRamp_Layout_RightFlex),
        minHeight: getValueD(PreferenceDouble.KPalRamp_Layout_MinHeight),
        maxHeight: getValueD(PreferenceDouble.KPalRamp_Layout_MaxHeight),
        borderWidth: getValueD(PreferenceDouble.KPalRamp_Layout_BorderWidth),
        borderRadius: getValueD(PreferenceDouble.KPalRamp_Layout_BorderRadius),
        dividerThickness: getValueD(PreferenceDouble.KPalRamp_Layout_DividerThickness),
        rowControlFlex: getValueI(PreferenceInt.KPalRamp_Layout_RowControlFlex),
        rowLabelFlex: getValueI(PreferenceInt.KPalRamp_Layout_RowLabelFlex),
        rowValueFlex: getValueI(PreferenceInt.KPalRamp_Layout_RowValueFlex),
        colorCardWidgetOptions: colorCardWidgetOptions);

    kPalWidgetOptions = KPalWidgetOptions(
        borderWidth: getValueD(PreferenceDouble.KPal_Layout_BorderWidth),
        outsidePadding: getValueD(PreferenceDouble.KPal_Layout_OutsidePadding),
        smokeOpacity: getValueI(PreferenceInt.KPal_Layout_SmokeOpacity),
        borderRadius: getValueD(PreferenceDouble.KPal_Layout_BorderRadius),
        iconSize: getValueD(PreferenceDouble.KPal_Layout_IconSize),
        insidePadding: getValueD(PreferenceDouble.KPal_Layout_InsidePadding),
        rampOptions: rampWidgetOptions);
  }

  void loadColorNames()
  {
    ColorNamesOptions options = ColorNamesOptions(
        defaultNameScheme: getValueI(PreferenceInt.ColorNames_Scheme),
        defaultColorNamePath: getValueS(PreferenceString.ColorNames_ColorNamePath));

    colorNames = ColorNames(options: options);

  }

  void loadPainterOptions()
  {
    kPixPainterOptions = KPixPainterOptions(
        cursorSize: getValueD(PreferenceDouble.Painter_CursorSize),
        cursorBorderWidth: getValueD(PreferenceDouble.Painter_CursorBorderWidth),
        checkerBoardDivisor: getValueD(PreferenceDouble.Painter_CheckerBoardDivisor),
        checkerBoardSizeMin: getValueD(PreferenceDouble.Painter_CheckerBoardSizeMin),
        checkerBoardSizeMax: getValueD(PreferenceDouble.Painter_CheckerBoardSizeMax),
        pixelExtensionFactor: getValueD(PreferenceDouble.Painter_PixelExtensionFactor),
        selectionSolidStrokeWidth: getValueD(PreferenceDouble.Painter_SelectionSolidStrokeWidth),
        selectionDashSegmentLength: getValueD(PreferenceDouble.Painter_SelectionDashSegmentLength),
        selectionDashStrokeWidth: getValueD(PreferenceDouble.Painter_SelectionDashStrokeWidth),
        selectionCircleSegmentCount: getValueD(PreferenceDouble.Painter_SelectionCircleSegmentCount),
        selectionCursorStrokeWidth: getValueD(PreferenceDouble.Painter_SelectionCursorStrokeWidth)
    );
  }

}

