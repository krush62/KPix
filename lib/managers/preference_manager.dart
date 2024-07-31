
// ignore_for_file: constant_identifier_names
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/main.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/tool_options/color_pick_options.dart';
import 'package:kpix/tool_options/eraser_options.dart';
import 'package:kpix/tool_options/fill_options.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/shape_options.dart';
import 'package:kpix/tool_options/spray_can_options.dart';
import 'package:kpix/tool_options/stamp_options.dart';
import 'package:kpix/tool_options/text_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/main_button_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
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
import '../kpal/kpal_widget.dart';

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
  Layout_Canvas_StylusToolSizeDistance(defaultValue: 5.0),
  Layout_Canvas_TouchZoomStepDistance(defaultValue: 25.0),
  Layout_Canvas_MinVisibilityFactor(defaultValue: 0.1),

  Layout_Tools_Padding(defaultValue: 8.0),
  Layout_Tools_IconSize(defaultValue: 20.0),
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

  Layout_ToolsSettings_Padding(defaultValue: 8.0),
  Layout_ToolSettings_SmallButtonSize(defaultValue: 36.0),
  Layout_ToolSettings_SmallIconSize(defaultValue: 20),

  Layout_MainToolbar_DividerHeight(defaultValue: 2.0),
  Layout_MainToolbar_DividerPadding(defaultValue: 8.0),

  Layout_Shader_OutsidePadding(defaultValue: 8.0),

  Layout_StatusBar_Height(defaultValue: 20.0),
  Layout_StatusBar_Padding(defaultValue: 2.0),
  Layout_StatusBar_DividerWidth(defaultValue: 2.0),

  Layout_OverlayEntrySubMenu_OffsetX(defaultValue: 0),
  Layout_OverlayEntrySubMenu_OffsetXLeft(defaultValue: -128.0),
  Layout_OverlayEntrySubMenu_OffsetY(defaultValue: 32.0),
  Layout_OverlayEntrySubMenu_ButtonSpacing(defaultValue: 8.0),
  Layout_OverlayEntrySubMenu_Width(defaultValue: 160.0),
  Layout_OverlayEntrySubMenu_ButtonHeight(defaultValue: 24.0),

  Layout_OverlayAlertDialog_MinWidth(defaultValue: 200.0),
  Layout_OverlayAlertDialog_MinHeight(defaultValue: 150.0),
  Layout_OverlayAlertDialog_MaxWidth(defaultValue: 600.0),
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
  Painter_PixelExtension(defaultValue: 0.15),
  Painter_SelectionDashStrokeWidth(defaultValue: 2.0),
  Painter_SelectionPolygonCircleRadius(defaultValue: 16.0),
  Painter_SelectionStrokeWidthLarge(defaultValue: 4.0),
  Painter_SelectionStrokeWidthSmall(defaultValue: 2.0),

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
  Layout_Canvas_HistoryCheck_PollRate(defaultValue: 250),
  Layout_Canvas_SingleTouchDelay(defaultValue: 50),
  Layout_Canvas_IdleTimerRate(defaultValue: 15),

  Layout_ColorChooser_SmokeOpacity(defaultValue: 128),

  Layout_Tools_ColCount(defaultValue: 6),

  Layout_ToolSettings_ColumnWidthRatio(defaultValue: 2),

  Layout_MainToolbar_PaletteFlex(defaultValue: 2),
  Layout_MainToolbar_ToolSettingsFlex(defaultValue: 1),

  Layout_OverlayEntry_SmokeOpacity(defaultValue: 128),

  Layout_LayerWidget_DragTargetShowDuration(defaultValue: 100),
  Layout_LayerWidget_DragDelay(defaultValue: 200),
  Layout_LayerWidget_ThumbUpdateTimerSec(defaultValue: 0),
  Layout_LayerWidget_ThumbUpdateTimerMSec(defaultValue: 50),

  Layout_SelectionBar_OpacityDuration(defaultValue: 150),

  Tool_Pencil_SizeMin(defaultValue: 1),
  Tool_Pencil_SizeMax(defaultValue: 32),
  Tool_Pencil_Size(defaultValue: 1),
  Tool_Pencil_Shape(defaultValue: 0),
  Tool_Shape_Shape(defaultValue: 1),
  Tool_Shape_StrokeWidthMin(defaultValue: 1),
  Tool_Shape_StrokeWidthMax(defaultValue: 16),
  Tool_Shape_StrokeWidth(defaultValue: 1),
  Tool_Shape_CornerRadiusMin(defaultValue: 0),
  Tool_Shape_CornerRadiusMax(defaultValue: 16),
  Tool_Shape_CornerRadius(defaultValue: 0),
  Tool_Shape_CornerCountMin(defaultValue: 5),
  Tool_Shape_CornerCountMax(defaultValue: 9),
  Tool_Shape_CornerCount(defaultValue: 5),
  Tool_Shape_EllipseAngleMin(defaultValue: 0),
  Tool_Shape_EllipseAngleMax(defaultValue: 90),
  Tool_Shape_EllipseAngle(defaultValue: 0),
  Tool_Shape_EllipseAngleSteps(defaultValue: 5),
  Tool_Select_Shape(defaultValue: 0),
  Tool_Select_Mode(defaultValue: 0),
  Tool_Eraser_SizeMin(defaultValue: 1),
  Tool_Eraser_SizeMax(defaultValue: 32),
  Tool_Eraser_Size(defaultValue: 1),
  Tool_Eraser_Shape(defaultValue: 0),
  Tool_Text_SizeMin(defaultValue: 1),
  Tool_Text_SizeMax(defaultValue: 8),
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
  Tool_Line_BezierCalculationPoints(defaultValue: 1000),
  Tool_Curve_WidthMin(defaultValue: 1),
  Tool_Curve_WidthMax(defaultValue: 16),
  Tool_Curve_Width(defaultValue: 1),
  Tool_Wand_Mode(defaultValue: 0),
  Tool_Stamp_ScaleMin(defaultValue: 1),
  Tool_Stamp_ScaleMax(defaultValue: 8),
  Tool_Stamp_ScaleDefault(defaultValue: 1),
  Tool_Stamp_StampDefault(defaultValue: 0),



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

  Painter_CheckerBoardSize(defaultValue: 8),

  ColorNames_Scheme(defaultValue: 0),

  HistoryOptions_Steps(defaultValue: 50),

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
  Tool_Shape_StrokeOnly(defaultValue: false),
  Tool_Fill_FillAdjacent(defaultValue: true),
  Tool_Fill_FillWholeRamp(defaultValue: false),
  Tool_Select_KeepAspectRatio(defaultValue: false),
  Tool_Select_WandContinuous(defaultValue: true),
  Tool_Select_WandWholeRamp(defaultValue: false),
  Tool_Line_IntegerAspectRatio(defaultValue: false),
  Tool_Wand_SelectFromWholeRamp(defaultValue: false),
  Tool_Wand_Continuous(defaultValue: true),
  Tool_Stamp_FlipH(defaultValue: false),
  Tool_Stamp_FlipV(defaultValue: false),
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

  late HistoryManagerOptions historyManagerOptions;

  late ColorNames colorNames;

  final FontManager _fontManager;
  final StampManager _stampManager;

  PreferenceManager(final SharedPreferences prefs, final FontManager fontManager, final StampManager stampManager) : _prefs = prefs, _fontManager = fontManager, _stampManager = stampManager
  {
    _init();
    _loadHistoryOptions();
    _loadWidgetOptions();
    _loadToolOptions();
    _loadKPalOptions();
    _loadColorNames();
    _loadPainterOptions();

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

  double _getValueD(PreferenceDouble prefName)
  {
    return _doubleMap[prefName]?.value ?? 0.0;
  }

  int _getValueI(PreferenceInt prefName)
  {
    return _intMap[prefName]?.value ?? 0;
  }

  bool _getValueB(PreferenceBool prefName)
  {
    return _boolMap[prefName]?.value ?? false;
  }

  String _getValueS(PreferenceString prefName)
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

  void _loadHistoryOptions()
  {
    historyManagerOptions = HistoryManagerOptions(stepCount: _getValueI(PreferenceInt.HistoryOptions_Steps));
  }


  void _loadWidgetOptions()
  {
    mainLayoutOptions = MainLayoutOptions(
        splitViewDividerWidth: _getValueD(PreferenceDouble.Layout_SplitView_DividerWidth),
        splitViewGrooveGap: _getValueD(PreferenceDouble.Layout_SplitView_GrooveGap),
        splitViewGrooveThickness: _getValueD(PreferenceDouble.Layout_SplitView_GrooveThickness),
        splitViewGrooveSize: _getValueD(PreferenceDouble.Layout_SplitView_GrooveSize),
        splitViewFlexLeftMin: _getValueD(PreferenceDouble.Layout_SplitView_FlexLeftMin),
        splitViewFlexLeftMax: _getValueD(PreferenceDouble.Layout_SplitView_FlexLeftMax),
        splitViewFlexRightMin: _getValueD(PreferenceDouble.Layout_SplitView_FlexRightMin),
        splitViewFlexRightMax: _getValueD(PreferenceDouble.Layout_SplitView_FlexRightMax),
        splitViewGrooveCountMin: _getValueI(PreferenceInt.Layout_SplitView_GrooveCountMin),
        splitViewGrooveCountMax: _getValueI(PreferenceInt.Layout_SplitView_GrooveCountMax),
        splitViewAnimationLength: _getValueI(PreferenceInt.Layout_SplitView_AnimationLength),
        splitViewFlexLeftDefault: _getValueD(PreferenceDouble.Layout_SplitView_FlexLeftDefault),
        splitViewFlexCenterDefault: _getValueD(PreferenceDouble.Layout_SplitView_FlexCenterDefault),
        splitViewFlexRightDefault: _getValueD(PreferenceDouble.Layout_SplitView_FlexRightDefault));
    canvasWidgetOptions = CanvasOptions(
        stylusPollRate: _getValueI(PreferenceInt.Layout_Canvas_Stylus_PollRate),
        historyCHeckPollRate: _getValueI(PreferenceInt.Layout_Canvas_HistoryCheck_PollRate),
        singleTouchDelay: _getValueI(PreferenceInt.Layout_Canvas_SingleTouchDelay),
        longPressDuration: _getValueI(PreferenceInt.Layout_Canvas_LongPressDuration),
        longPressCancelDistance: _getValueD(PreferenceDouble.Layout_Canvas_LongPressCancelDistance),
        stylusZoomStepDistance: _getValueD(PreferenceDouble.Layout_Canvas_StylusZoomStepDistance),
        touchZoomStepDistance: _getValueD(PreferenceDouble.Layout_Canvas_TouchZoomStepDistance),
        stylusToolSizeDistance: _getValueD(PreferenceDouble.Layout_Canvas_StylusToolSizeDistance),
        minVisibilityFactor: _getValueD(PreferenceDouble.Layout_Canvas_MinVisibilityFactor),
        idleTimerRate: _getValueI(PreferenceInt.Layout_Canvas_IdleTimerRate));
    toolsWidgetOptions = ToolsWidgetOptions(
        padding: _getValueD(PreferenceDouble.Layout_Tools_Padding),
        colCount: _getValueI(PreferenceInt.Layout_Tools_ColCount),
        buttonSize: _getValueD(PreferenceDouble.Layout_Tools_ButtonSize),
        iconSize: _getValueD(PreferenceDouble.Layout_Tools_IconSize));
    paletteWidgetOptions = PaletteWidgetOptions(
        padding: _getValueD(PreferenceDouble.Layout_Palette_Padding));
    colorEntryOptions = ColorEntryWidgetOptions(
        unselectedMargin: _getValueD(PreferenceDouble.Layout_ColorEntry_UnselectedMargin),
        selectedMargin: _getValueD(PreferenceDouble.Layout_ColorEntry_SelectedMargin),
        roundRadius: _getValueD(PreferenceDouble.Layout_ColorEntry_RoundRadius),
        addIconSize: _getValueD(PreferenceDouble.Layout_ColorEntry_AddIconSize),
        settingsIconSize: _getValueD(PreferenceDouble.Layout_ColorEntry_SettingsIconSize),
        buttonPadding: _getValueD(PreferenceDouble.Layout_ColorEntry_ButtonPadding),
        minSize: _getValueD(PreferenceDouble.Layout_ColorEntry_MinSize),
        maxSize: _getValueD(PreferenceDouble.Layout_ColorEntry_MaxSize),);
    toolSettingsWidgetOptions = ToolSettingsWidgetOptions(
        columnWidthRatio: _getValueI(PreferenceInt.Layout_ToolSettings_ColumnWidthRatio),
        padding: _getValueD(PreferenceDouble.Layout_ToolsSettings_Padding),
        smallButtonSize: _getValueD(PreferenceDouble.Layout_ToolSettings_SmallButtonSize),
        smallIconSize: _getValueD(PreferenceDouble.Layout_ToolSettings_SmallIconSize));
    mainToolbarWidgetOptions = MainToolbarWidgetOptions(
        paletteFlex: _getValueI(PreferenceInt.Layout_MainToolbar_PaletteFlex),
        toolSettingsFlex: _getValueI(PreferenceInt.Layout_MainToolbar_ToolSettingsFlex),
        dividerHeight: _getValueD(PreferenceDouble.Layout_MainToolbar_DividerHeight),
        dividerPadding: _getValueD(PreferenceDouble.Layout_MainToolbar_DividerPadding),);
    shaderWidgetOptions = ShaderWidgetOptions(
        outSidePadding: _getValueD(PreferenceDouble.Layout_Shader_OutsidePadding));
    statusBarWidgetOptions = StatusBarWidgetOptions(
      height: _getValueD(PreferenceDouble.Layout_StatusBar_Height),
      padding: _getValueD(PreferenceDouble.Layout_StatusBar_Padding),
      dividerWidth: _getValueD(PreferenceDouble.Layout_StatusBar_DividerWidth),);
    shaderOptions = ShaderOptions(
        shaderDirectionDefault: _getValueB(PreferenceBool.Shader_DirectionRight),
        onlyCurrentRampEnabledDefault: _getValueB(PreferenceBool.Shader_CurrentRampOnly),
        isEnabledDefault: _getValueB(PreferenceBool.Shader_IsEnabled));
    overlayEntryOptions = OverlayEntrySubMenuOptions(
        offsetX: _getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_OffsetX),
        offsetXLeft: _getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_OffsetXLeft),
        offsetY: _getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_OffsetY),
        buttonSpacing: _getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_ButtonSpacing),
        width: _getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_Width),
        buttonHeight: _getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_ButtonHeight),
        smokeOpacity: _getValueI(PreferenceInt.Layout_OverlayEntry_SmokeOpacity));
    alertDialogOptions = OverlayEntryAlertDialogOptions(
        smokeOpacity: _getValueI(PreferenceInt.Layout_OverlayEntry_SmokeOpacity),
        minWidth: _getValueD(PreferenceDouble.Layout_OverlayAlertDialog_MinWidth),
        minHeight: _getValueD(PreferenceDouble.Layout_OverlayAlertDialog_MinHeight),
        maxWidth: _getValueD(PreferenceDouble.Layout_OverlayAlertDialog_MaxWidth),
        maxHeight: _getValueD(PreferenceDouble.Layout_OverlayAlertDialog_MaxHeight),
        padding: _getValueD(PreferenceDouble.Layout_OverlayAlertDialog_Padding),
        borderWidth: _getValueD(PreferenceDouble.Layout_OverlayAlertDialog_BorderWidth),
        borderRadius: _getValueD(PreferenceDouble.Layout_OverlayAlertDialog_BorderRadius),
        iconSize: _getValueD(PreferenceDouble.Layout_OverlayAlertDialog_IconSize),
        elevation: _getValueD(PreferenceDouble.Layout_OverlayAlertDialog_Elevation));
    mainButtonWidgetOptions = MainButtonWidgetOptions(
        padding: _getValueD(PreferenceDouble.Layout_MainButton_Padding),
        menuIconSize: _getValueD(PreferenceDouble.Layout_MainButton_MenuIconSize),
        dividerSize: _getValueD(PreferenceDouble.Layout_MainButton_DividerSize));
    layerWidgetOptions = LayerWidgetOptions(
        outerPadding: _getValueD(PreferenceDouble.Layout_LayerWidget_OuterPadding),
        innerPadding: _getValueD(PreferenceDouble.Layout_LayerWidget_InnerPadding),
        borderRadius: _getValueD(PreferenceDouble.Layout_LayerWidget_BorderRadius),
        buttonSizeMin: _getValueD(PreferenceDouble.Layout_LayerWidget_ButtonSizeMin),
        buttonSizeMax: _getValueD(PreferenceDouble.Layout_LayerWidget_ButtonSizeMax),
        iconSize: _getValueD(PreferenceDouble.Layout_LayerWidget_IconSize),
        height: _getValueD(PreferenceDouble.Layout_LayerWidget_Height),
        borderWidth: _getValueD(PreferenceDouble.Layout_LayerWidget_BorderWidth),
        dragFeedbackSize: _getValueD(PreferenceDouble.Layout_LayerWidget_DragFeedbackSize),
        dragOpacity: _getValueD(PreferenceDouble.Layout_LayerWidget_DragOpacity),
        dragTargetHeight: _getValueD(PreferenceDouble.Layout_LayerWidget_DragTargetHeight),
        dragTargetShowDuration: _getValueI(PreferenceInt.Layout_LayerWidget_DragTargetShowDuration),
        dragDelay: _getValueI(PreferenceInt.Layout_LayerWidget_DragDelay),
        thumbUpdateTimerSec: _getValueI(PreferenceInt.Layout_LayerWidget_ThumbUpdateTimerSec),
        thumbUpdateTimerMsec: _getValueI(PreferenceInt.Layout_LayerWidget_ThumbUpdateTimerMSec));
    selectionBarWidgetOptions = SelectionBarWidgetOptions(
        iconHeight: _getValueD(PreferenceDouble.Layout_SelectionBar_IconHeight,),
        padding: _getValueD(PreferenceDouble.Layout_SelectionBar_Padding),
        opacityDuration: _getValueI(PreferenceInt.Layout_SelectionBar_OpacityDuration));

  }

  void _loadToolOptions()
  {
    PencilOptions pencilOptions = PencilOptions(
        sizeMin: _getValueI(PreferenceInt.Tool_Pencil_SizeMin),
        sizeMax: _getValueI(PreferenceInt.Tool_Pencil_SizeMax),
        sizeDefault: _getValueI(PreferenceInt.Tool_Pencil_Size),
        shapeDefault: _getValueI(PreferenceInt.Tool_Pencil_Shape),
        pixelPerfectDefault: _getValueB(PreferenceBool.Tool_Pencil_PixelPerfect));
    ShapeOptions shapeOptions = ShapeOptions(
        shapeDefault: _getValueI(PreferenceInt.Tool_Shape_Shape),
        keepRatioDefault: _getValueB(PreferenceBool.Tool_Shape_KeepAspectRatio),
        strokeOnlyDefault: _getValueB(PreferenceBool.Tool_Shape_StrokeOnly),
        strokeWidthMin: _getValueI(PreferenceInt.Tool_Shape_StrokeWidthMin),
        strokeWidthMax: _getValueI(PreferenceInt.Tool_Shape_StrokeWidthMax),
        strokeWidthDefault: _getValueI(PreferenceInt.Tool_Shape_StrokeWidth),
        cornerRadiusMin: _getValueI(PreferenceInt.Tool_Shape_CornerRadiusMin),
        cornerRadiusMax: _getValueI(PreferenceInt.Tool_Shape_CornerRadiusMax),
        cornerRadiusDefault: _getValueI(PreferenceInt.Tool_Shape_CornerRadius),
        cornerCountMin: _getValueI(PreferenceInt.Tool_Shape_CornerCountMin),
        cornerCountMax: _getValueI(PreferenceInt.Tool_Shape_CornerCountMax),
        cornerCountDefault: _getValueI(PreferenceInt.Tool_Shape_CornerCount),
        ellipseAngleMin: _getValueI(PreferenceInt.Tool_Shape_EllipseAngleMin),
        ellipseAngleMax: _getValueI(PreferenceInt.Tool_Shape_EllipseAngleMax),
        ellipseAngleDefault: _getValueI(PreferenceInt.Tool_Shape_EllipseAngle),
        ellipseAngleSteps: _getValueI(PreferenceInt.Tool_Shape_EllipseAngleSteps),);
    FillOptions fillOptions = FillOptions(
        fillAdjacentDefault: _getValueB(PreferenceBool.Tool_Fill_FillAdjacent),
        fillWholeRampDefault: _getValueB(PreferenceBool.Tool_Fill_FillWholeRamp));
    SelectOptions selectOptions = SelectOptions(
        shapeDefault: _getValueI(PreferenceInt.Tool_Select_Shape),
        keepAspectRatioDefault: _getValueB(PreferenceBool.Tool_Select_KeepAspectRatio),
        modeDefault: _getValueI(PreferenceInt.Tool_Select_Mode),
        wandContinuousDefault: _getValueB(PreferenceBool.Tool_Wand_Continuous),
        wandWholeRampDefault: _getValueB(PreferenceBool.Tool_Wand_SelectFromWholeRamp));
    ColorPickOptions colorPickOptions = ColorPickOptions();
    EraserOptions eraserOptions = EraserOptions(
        sizeMin: _getValueI(PreferenceInt.Tool_Eraser_SizeMin),
        sizeMax: _getValueI(PreferenceInt.Tool_Eraser_SizeMax),
        sizeDefault: _getValueI(PreferenceInt.Tool_Eraser_Size),
        shapeDefault: _getValueI(PreferenceInt.Tool_Eraser_Shape));
    TextOptions textOptions = TextOptions(
        fontManager: _fontManager,
        fontDefault: _getValueI(PreferenceInt.Tool_Text_Font),
        sizeMin: _getValueI(PreferenceInt.Tool_Text_SizeMin),
        sizeMax: _getValueI(PreferenceInt.Tool_Text_SizeMax),
        sizeDefault: _getValueI(PreferenceInt.Tool_Text_Size),
        textDefault: _getValueS(PreferenceString.Tool_Text_TextDefault),
        maxLength: _getValueI(PreferenceInt.Tool_Text_MaxLength));
    SprayCanOptions sprayCanOptions = SprayCanOptions(
        radiusMin: _getValueI(PreferenceInt.Tool_SprayCan_RadiusMin),
        radiusMax: _getValueI(PreferenceInt.Tool_SprayCan_RadiusMax),
        radiusDefault: _getValueI(PreferenceInt.Tool_SprayCan_Radius),
        blobSizeMin: _getValueI(PreferenceInt.Tool_SprayCan_BlobSizeMin),
        blobSizeMax: _getValueI(PreferenceInt.Tool_SprayCan_BlobSizeMax),
        blobSizeDefault: _getValueI(PreferenceInt.Tool_SprayCan_BlobSize),
        intensityMin: _getValueI(PreferenceInt.Tool_SprayCan_IntensityMin),
        intensityMax: _getValueI(PreferenceInt.Tool_SprayCan_IntensityMax),
        intensityDefault: _getValueI(PreferenceInt.Tool_SprayCan_Intensity));
    LineOptions lineOptions = LineOptions(
        widthMin: _getValueI(PreferenceInt.Tool_Line_WidthMin),
        widthMax: _getValueI(PreferenceInt.Tool_Line_WidthMax),
        widthDefault: _getValueI(PreferenceInt.Tool_Line_Width),
        bezierCalculationPoints: _getValueI(PreferenceInt.Tool_Line_BezierCalculationPoints),
        integerAspectRatioDefault: _getValueB(PreferenceBool.Tool_Line_IntegerAspectRatio));
    StampOptions stampOptions = StampOptions(
        stampManager: _stampManager,
        scaleMin: _getValueI(PreferenceInt.Tool_Stamp_ScaleMin),
        scaleMax: _getValueI(PreferenceInt.Tool_Stamp_ScaleMax),
        scaleDefault: _getValueI(PreferenceInt.Tool_Stamp_ScaleDefault),
        stampDefault: _getValueI(PreferenceInt.Tool_Stamp_StampDefault),
        flipHDefault: _getValueB(PreferenceBool.Tool_Stamp_FlipH),
        flipVDefault: _getValueB(PreferenceBool.Tool_Stamp_FlipH));
    toolOptions = ToolOptions(
        pencilOptions: pencilOptions,
        shapeOptions: shapeOptions,
        fillOptions: fillOptions,
        selectOptions: selectOptions,
        colorPickOptions: colorPickOptions,
        eraserOptions: eraserOptions,
        textOptions: textOptions,
        sprayCanOptions: sprayCanOptions,
        stampOptions: stampOptions,
        lineOptions: lineOptions,);
  }

  void _loadKPalOptions()
  {
    kPalConstraints = KPalConstraints(
        colorCountMin: _getValueI(PreferenceInt.KPal_Constraints_ColorCountMin),
        colorCountMax: _getValueI(PreferenceInt.KPal_Constraints_ColorCountMax),
        colorCountDefault: _getValueI(PreferenceInt.KPal_Constraints_ColorCountDefault),
        baseHueMin: _getValueI(PreferenceInt.KPal_Constraints_BaseHueMin),
        baseHueMax: _getValueI(PreferenceInt.KPal_Constraints_BaseHueMax),
        baseHueDefault: _getValueI(PreferenceInt.KPal_Constraints_BaseHueDefault),
        baseSatMin: _getValueI(PreferenceInt.KPal_Constraints_BaseSatMin),
        baseSatMax: _getValueI(PreferenceInt.KPal_Constraints_BaseSatMax),
        baseSatDefault: _getValueI(PreferenceInt.KPal_Constraints_BaseSatDefault),
        hueShiftMin: _getValueI(PreferenceInt.KPal_Constraints_HueShiftMin),
        hueShiftMax: _getValueI(PreferenceInt.KPal_Constraints_HueShiftMax),
        hueShiftDefault: _getValueI(PreferenceInt.KPal_Constraints_HueShiftDefault),
        hueShiftExpMin: _getValueD(PreferenceDouble.KPal_Constraints_hueShiftExpMin),
        hueShiftExpMax: _getValueD(PreferenceDouble.KPal_Constraints_hueShiftExpMax),
        hueShiftExpDefault: _getValueD(PreferenceDouble.KPal_Constraints_hueShiftExpDefault),
        satShiftMin: _getValueI(PreferenceInt.KPal_Constraints_SatShiftMin),
        satShiftMax: _getValueI(PreferenceInt.KPal_Constraints_SatShiftMax),
        satShiftDefault: _getValueI(PreferenceInt.KPal_Constraints_SatShiftDefault),
        satShiftExpMin: _getValueD(PreferenceDouble.KPal_Constraints_satShiftExpMin),
        satShiftExpMax: _getValueD(PreferenceDouble.KPal_Constraints_satShiftExpMax),
        satShiftExpDefault: _getValueD(PreferenceDouble.KPal_Constraints_staShiftExpDefault),
        valueRangeMin: _getValueI(PreferenceInt.KPal_Constraints_ValueRangeMin),
        valueRangeMinDefault: _getValueI(PreferenceInt.KPal_Constraints_ValueRangeMinDefault),
        valueRangeMax: _getValueI(PreferenceInt.KPal_Constraints_ValueRangeMax),
        valueRangeMaxDefault: _getValueI(PreferenceInt.KPal_Constraints_ValueRangeMaxDefault),
        satCurveDefault: _getValueI(PreferenceInt.KPal_Constraints_SatCurveDefault));

    KPalColorCardWidgetOptions colorCardWidgetOptions = KPalColorCardWidgetOptions(
        borderRadius: _getValueD(PreferenceDouble.KPalColorCard_Layout_BorderRadius),
        borderWidth: _getValueD(PreferenceDouble.KPalColorCard_Layout_BorderWidth),
        outsidePadding: _getValueD(PreferenceDouble.KPalColorCard_Layout_OutsidePadding),
        colorFlex: _getValueI(PreferenceInt.KPalColorCard_Layout_ColorFlex),
        colorNameFlex: _getValueI(PreferenceInt.KPalColorCard_Layout_ColorNameFlex),
        colorNumbersFlex: _getValueI(PreferenceInt.KPalColorCard_Layout_ColorNumbersFlex));

    KPalRampWidgetOptions rampWidgetOptions = KPalRampWidgetOptions(
        padding: _getValueD(PreferenceDouble.KPalRamp_Layout_OutsidePadding),
        centerFlex: _getValueI(PreferenceInt.KPalRamp_Layout_CenterFlex),
        rightFlex: _getValueI(PreferenceInt.KPalRamp_Layout_RightFlex),
        minHeight: _getValueD(PreferenceDouble.KPalRamp_Layout_MinHeight),
        maxHeight: _getValueD(PreferenceDouble.KPalRamp_Layout_MaxHeight),
        borderWidth: _getValueD(PreferenceDouble.KPalRamp_Layout_BorderWidth),
        borderRadius: _getValueD(PreferenceDouble.KPalRamp_Layout_BorderRadius),
        dividerThickness: _getValueD(PreferenceDouble.KPalRamp_Layout_DividerThickness),
        rowControlFlex: _getValueI(PreferenceInt.KPalRamp_Layout_RowControlFlex),
        rowLabelFlex: _getValueI(PreferenceInt.KPalRamp_Layout_RowLabelFlex),
        rowValueFlex: _getValueI(PreferenceInt.KPalRamp_Layout_RowValueFlex),
        colorCardWidgetOptions: colorCardWidgetOptions);

    kPalWidgetOptions = KPalWidgetOptions(
        borderWidth: _getValueD(PreferenceDouble.KPal_Layout_BorderWidth),
        outsidePadding: _getValueD(PreferenceDouble.KPal_Layout_OutsidePadding),
        smokeOpacity: _getValueI(PreferenceInt.KPal_Layout_SmokeOpacity),
        borderRadius: _getValueD(PreferenceDouble.KPal_Layout_BorderRadius),
        iconSize: _getValueD(PreferenceDouble.KPal_Layout_IconSize),
        insidePadding: _getValueD(PreferenceDouble.KPal_Layout_InsidePadding),
        rampOptions: rampWidgetOptions);
  }

  void _loadColorNames()
  {
    ColorNamesOptions options = ColorNamesOptions(
        defaultNameScheme: _getValueI(PreferenceInt.ColorNames_Scheme),
        defaultColorNamePath: _getValueS(PreferenceString.ColorNames_ColorNamePath));

    colorNames = ColorNames(options: options);

  }

  void _loadPainterOptions()
  {
    kPixPainterOptions = KPixPainterOptions(
        cursorSize: _getValueD(PreferenceDouble.Painter_CursorSize),
        cursorBorderWidth: _getValueD(PreferenceDouble.Painter_CursorBorderWidth),
        checkerBoardSize: _getValueI(PreferenceInt.Painter_CheckerBoardSize),
        pixelExtension: _getValueD(PreferenceDouble.Painter_PixelExtension),
        selectionSolidStrokeWidth: _getValueD(PreferenceDouble.Painter_SelectionSolidStrokeWidth),
        selectionPolygonCircleRadius: _getValueD(PreferenceDouble.Painter_SelectionPolygonCircleRadius),
        selectionStrokeWidthLarge: _getValueD(PreferenceDouble.Painter_SelectionStrokeWidthLarge),
        selectionStrokeWidthSmall: _getValueD(PreferenceDouble.Painter_SelectionStrokeWidthSmall),
    );
  }

}

