/*
 * KPix
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// ignore_for_file: constant_identifier_names
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer_settings.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer_settings.dart';
import 'package:kpix/main.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/preferences/behavior_preferences.dart';
import 'package:kpix/preferences/desktop_preferences.dart';
import 'package:kpix/preferences/gui_preferences.dart';
import 'package:kpix/preferences/stylus_preferences.dart';
import 'package:kpix/preferences/touch_preferences.dart';
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
import 'package:kpix/util/color_names.dart';
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';
import 'package:kpix/widgets/canvas/canvas_size_widget.dart';
import 'package:kpix/widgets/canvas/canvas_widget.dart';
import 'package:kpix/widgets/canvas/selection_bar_widget.dart';
import 'package:kpix/widgets/file/project_manager_entry_widget.dart';
import 'package:kpix/widgets/file/project_manager_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/main/main_button_widget.dart';
import 'package:kpix/widgets/main/main_toolbar_widget.dart';
import 'package:kpix/widgets/main/status_bar_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/palette/color_entry_widget.dart';
import 'package:kpix/widgets/palette/palette_manager_entry_widget.dart';
import 'package:kpix/widgets/palette/palette_manager_widget.dart';
import 'package:kpix/widgets/palette/palette_widget.dart';
import 'package:kpix/widgets/tools/grid_layer_options_widget.dart';
import 'package:kpix/widgets/tools/reference_layer_options_widget.dart';
import 'package:kpix/widgets/tools/shader_widget.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';
import 'package:kpix/widgets/tools/tools_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PreferenceDouble
{
  MainLayout_SplitView_DividerWidth(defaultValue: 8.0),
  MainLayout_SplitView_FlexLeftMin(defaultValue: 0.15),
  MainLayout_SplitView_FlexLeftDefault(defaultValue: 0.2),
  MainLayout_SplitView_FlexLeftMax(defaultValue: 0.25),
  MainLayout_SplitView_FlexRightMin(defaultValue: 0.1),
  MainLayout_SplitView_FlexRightDefault(defaultValue: 0.15),
  MainLayout_SplitView_FlexRightMax(defaultValue: 0.2),
  MainLayout_TitleBar_Padding(defaultValue: 4.0),
  MainLayout_LoadingScreen_Padding(defaultValue: 32.0),

  Layout_Canvas_MinVisibilityFactor(defaultValue: 0.1),

  Layout_Tools_Padding(defaultValue: 8.0),
  Layout_Tools_IconSize(defaultValue: 20.0),
  Layout_Tools_ButtonSize(defaultValue: 48.0),

  Layout_Palette_Padding(defaultValue: 8.0),
  Layout_Palette_ManagerButtonSize(defaultValue: 32.0),
  Layout_Palette_BorderRadius(defaultValue: 8.0),

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

  Layout_CanvasOperations_IconHeight(defaultValue: 12.0),
  Layout_CanvasOperations_Padding(defaultValue: 4.0),

  Layout_PaletteManagerEntry_BorderWidth(defaultValue: 2.0),
  Layout_PaletteManagerEntry_BorderRadius(defaultValue: 3.0),

  Layout_PaletteManager_EntryAspectRatio(defaultValue: 0.75),

  Layout_ProjectManagerEntry_BorderWidth(defaultValue: 2.0),
  Layout_ProjectManagerEntry_BorderRadius(defaultValue: 3.0),
  Layout_ProjectManager_EntryAspectRatio(defaultValue: 0.75),
  Layout_ProjectManager_MaxWidth(defaultValue: 800.0),
  Layout_ProjectManager_MaxHeight(defaultValue: 600.0),

  ReferenceLayer_AspectRatioDefault(defaultValue: 0.0),
  ReferenceLayer_AspectRatioMax(defaultValue: 5.0),
  ReferenceLayer_AspectRatioMin(defaultValue: -5.0),
  ReferenceLayer_ZoomCurveExponent(defaultValue: 2.0),

  GridLayer_VanishingPointMin(defaultValue: 0.0),
  GridLayer_VanishingPointMax(defaultValue: 1.0),
  GridLayer_HorizonDefault(defaultValue: 0.5),
  GridLayer_VanishingPoint1Default(defaultValue: 0.1),
  GridLayer_VanishingPoint2Default(defaultValue: 0.9),
  GridLayer_VanishingPoint3Default(defaultValue: 0.9),


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

  StylusOptions_LongPressCancelDistance(defaultValue: 10.0),
  StylusOptions_LongPressCancelDistanceMin(defaultValue: 5.0),
  StylusOptions_LongPressCancelDistanceMax(defaultValue: 50.0),
  StylusOptions_ZoomStepDistance(defaultValue: 10.0),
  StylusOptions_ZoomStepDistanceMin(defaultValue: 2.0),
  StylusOptions_ZoomStepDistanceMax(defaultValue: 50.0),
  StylusOptions_SizeStepDistance(defaultValue: 5.0),
  StylusOptions_SizeStepDistanceMin(defaultValue: 2.0),
  StylusOptions_SizeStepDistanceMax(defaultValue: 50.0),

  TouchOptions_ZoomStepDistance(defaultValue: 25.0),
  TouchOptions_ZoomStepDistanceMin(defaultValue: 10.0),
  TouchOptions_ZoomStepDistanceMax(defaultValue: 100.0),




  ;

  const PreferenceDouble({
    required this.defaultValue,
  });

  final double defaultValue;
}

enum PreferenceInt
{
  Main_RecoveryCheckInterValMinutes(defaultValue: 2),

  Layout_Canvas_HistoryCheck_PollRate(defaultValue: 250),
  Layout_Canvas_IdleTimerRate(defaultValue: 15),

  Layout_ColorChooser_SmokeOpacity(defaultValue: 128),

  Layout_Tools_ColCount(defaultValue: 6),

  Layout_ToolSettings_ColumnWidthRatio(defaultValue: 2),

  Layout_MainToolbar_PaletteFlex(defaultValue: 2),
  Layout_MainToolbar_ToolSettingsFlex(defaultValue: 1),
  Layout_MainToolbar_ToolHeight(defaultValue: 300),

  Layout_OverlayEntry_SmokeOpacity(defaultValue: 128),

  Layout_OverlayEntrySubMenu_AnimationLengthMs(defaultValue: 150),

  Layout_LayerWidget_DragTargetShowDuration(defaultValue: 100),
  Layout_LayerWidget_DragDelay(defaultValue: 200),
  Layout_LayerWidget_ThumbUpdateTimerMSec(defaultValue: 20),
  Layout_LayerWidget_AddLayerButtonSize(defaultValue: 32),

  Layout_SelectionBar_OpacityDuration(defaultValue: 150),

  Layout_CanvasSize_SizeMin(defaultValue: 4),
  Layout_CanvasSize_SizeMax(defaultValue: 640),
  Layout_CanvasSize_PreviewSize(defaultValue: 300),

  Layout_PaletteManagerEntry_LayoutFlex(defaultValue: 6),
  Layout_PaletteManager_ColCount(defaultValue: 4),
  Layout_ProjectManagerEntry_LayoutFlex(defaultValue: 6),
  Layout_ProjectManager_ColCount(defaultValue: 5),

  ReferenceLayer_OpacityDefault(defaultValue: 100),
  ReferenceLayer_OpacityMax(defaultValue: 100),
  ReferenceLayer_OpacityMin(defaultValue: 0),
  ReferenceLayer_ZoomDefault(defaultValue: 1000),
  ReferenceLayer_ZoomMax(defaultValue: 2000),
  ReferenceLayer_ZoomMin(defaultValue: 1),

  GridLayer_OpacityDefault(defaultValue: 100),
  GridLayer_OpacityMin(defaultValue: 0),
  GridLayer_OpacityMax(defaultValue: 100),
  GridLayer_BrightnessDefault(defaultValue: 50),
  GridLayer_BrightnessMin(defaultValue: 0),
  GridLayer_BrightnessMax(defaultValue: 100),
  GridLayer_IntervalXDefault(defaultValue: 8),
  GridLayer_IntervalXMin(defaultValue: 2),
  GridLayer_IntervalXMax(defaultValue: 64),
  GridLayer_IntervalYDefault(defaultValue: 8),
  GridLayer_IntervalYMin(defaultValue: 2),
  GridLayer_IntervalYMax(defaultValue: 64),
  GridLayer_GridTypeDefault(defaultValue: 0),



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
  Tool_SprayCan_IntensityMax(defaultValue: 128),
  Tool_SprayCan_Intensity(defaultValue: 8),
  Tool_Line_WidthMin(defaultValue: 1),
  Tool_Line_WidthMax(defaultValue: 16),
  Tool_Line_Width(defaultValue: 1),
  Tool_Line_BezierCalculationPoints(defaultValue: 1000),
  Tool_Line_SegmentSortStyle(defaultValue: 1),
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
  KPal_Constraints_ColorCountDefault(defaultValue: 7),
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
  KPal_Constraints_RampCountMin(defaultValue: 1),
  KPal_Constraints_RampCountMax(defaultValue: 64),
  KPal_Constraints_RampCountDefault(defaultValue: 8),
  KPal_Constraints_MaxClusters(defaultValue: 16),

  KPal_Layout_SmokeOpacity(defaultValue: 128),

  KPalRamp_Layout_CenterFlex(defaultValue: 6),
  KPalRamp_Layout_RightFlex(defaultValue: 2),
  KPalRamp_Layout_RowLabelFlex(defaultValue: 4),
  KPalRamp_Layout_RowControlFlex(defaultValue: 25),
  KPalRamp_Layout_RowValueFlex(defaultValue: 3),
  KPalRamp_Layout_ColorShowThreshold(defaultValue: 10),
  KPalRamp_Layout_RenderIntervalMs(defaultValue: 100),

  KPalColorCard_Layout_ColorNameFlex(defaultValue: 2),
  KPalColorCard_Layout_ColorFlex(defaultValue: 9),
  KPalColorCard_Layout_ColorNumbersFlex(defaultValue: 3),
  KPalColorCard_Layout_EditAnimationDuration(defaultValue: 250),
  KPalColorCard_Layout_TouchTimeout(defaultValue: 1500),

  KPalSliderConstraints_MinHue(defaultValue: -50),
  KPalSliderConstraints_MinSat(defaultValue: -25),
  KPalSliderConstraints_MinVal(defaultValue: -25),
  KPalSliderConstraints_MaxHue(defaultValue: 50),
  KPalSliderConstraints_MaxSat(defaultValue: 25),
  KPalSliderConstraints_MaxVal(defaultValue: 25),
  KPalSliderConstraints_DefaultHue(defaultValue: 0),
  KPalSliderConstraints_DefaultSat(defaultValue: 0),
  KPalSliderConstraints_DefaultVal(defaultValue: 0),


  DrawingLayerConstraints_MinDarkenBrighten(defaultValue: -5),
  DrawingLayerConstraints_DefaultDarkenBrighten(defaultValue: -1),
  DrawingLayerConstraints_MaxDarkenBrighten(defaultValue: 5),
  DrawingLayerConstraints_MinGlowDepth(defaultValue: 2),
  DrawingLayerConstraints_DefaultGlowDepth(defaultValue: 3),
  DrawingLayerConstraints_MaxGlowDepth(defaultValue: 8),
  DrawingLayerConstraints_MinBevelDistance(defaultValue: 1),
  DrawingLayerConstraints_DefaultBevelDistance(defaultValue: 1),
  DrawingLayerConstraints_MaxBevelDistance(defaultValue: 8),
  DrawingLayerConstraints_MinBevelStrength(defaultValue: 1),
  DrawingLayerConstraints_DefaultBevelStrength(defaultValue: 2),
  DrawingLayerConstraints_MaxBevelStrength(defaultValue: 8),
  DrawingLayerConstraints_MinDropShadowDistance(defaultValue: -16),
  DrawingLayerConstraints_DefaultDropShadowDistance(defaultValue: 1),
  DrawingLayerConstraints_MaxDropShadowDistance(defaultValue: 16),

  ShadingLayerConstraints_MinAmount(defaultValue: 1),
  ShadingLayerConstraints_DefaultAmount(defaultValue: 4),
  ShadingLayerConstraints_MaxAmount(defaultValue: 6),

  Painter_CheckerBoardSize(defaultValue: 8),
  Painter_CheckerBoardContrast(defaultValue: 25),

  ColorNames_Scheme(defaultValue: 0),

  Opacity_Tool(defaultValue: 50),
  Opacity_Selection(defaultValue: 50),
  Opacity_CanvasBorder(defaultValue: 50),

  HistoryOptions_Steps(defaultValue: 100),
  HistoryOptions_StepsMax(defaultValue: 1000),
  HistoryOptions_StepsMin(defaultValue: 10),

  ThemeType(defaultValue: 0),

  StylusOptions_LongPressDelay(defaultValue: 250),
  StylusOptions_LongPressDelayMin(defaultValue: 50),
  StylusOptions_LongPressDelayMax(defaultValue: 1000),
  StylusOptions_PollInterval(defaultValue: 100),
  StylusOptions_PollIntervalMin(defaultValue: 20),
  StylusOptions_PollIntervalMax(defaultValue: 500),
  StylusOptions_PickMaxDuration(defaultValue: 400),
  StylusOptions_PickMaxDurationMin(defaultValue: 100),
  StylusOptions_PickMaxDurationMax(defaultValue: 1000),

  TouchOptions_SingleTouchDelay(defaultValue: 50),
  TouchOptions_SingleTouchDelayMin(defaultValue: 10),
  TouchOptions_SingleTouchDelayMax(defaultValue: 250),

  DesktopOptions_CursorType(defaultValue: 1),

  ;


  const PreferenceInt({
    required this.defaultValue,
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
  Tool_Line_SegmentSorting(defaultValue: false),
  Tool_Wand_SelectFromWholeRamp(defaultValue: false),
  Tool_Wand_Continuous(defaultValue: true),
  Tool_Stamp_FlipH(defaultValue: false),
  Tool_Stamp_FlipV(defaultValue: false),

  SelectShapeAfterInsert(defaultValue: false),
  SelectLayerAfterInsert(defaultValue: true),

  DrawingLayerConstraints_DefaultGlowDirection(defaultValue: true),
  ;
  const PreferenceBool({
    required this.defaultValue,
  });
  final bool defaultValue;
}

enum PreferenceString
{
  Tool_Text_TextDefault(defaultValue: "Text"),

  ColorNames_ColorNamePath(defaultValue: "color_names"),

  ;
  const PreferenceString({
    required this.defaultValue,
  });
  final String defaultValue;
}


class _DoublePair
{
  double _value;
  bool _changed = false;
  _DoublePair({required final double val}) : _value=val;
  double get value
  {
    return _value;
  }
  set value(final double newVal)
  {
    if (value != newVal)
    {
      _changed = true;
      _value = newVal;
    }
  }
  bool get changed
  {
    return _changed;
  }
}

class _IntPair
{
  int _value;
  bool _changed = false;
  _IntPair({required final int val}) : _value=val;
  int get value
  {
    return _value;
  }
  set value(final int newVal)
  {
    if (value != newVal)
    {
      _changed = true;
      _value = newVal;
    }
  }
  bool get changed
  {
    return _changed;
  }
}

class _BoolPair
{
  bool _value;
  bool _changed = false;
  _BoolPair({required final bool val}) : _value=val;
  bool get value
  {
    return _value;
  }
  set value(final bool newVal)
  {
    if (value != newVal)
    {
      _changed = true;
      _value = newVal;
    }
  }
  bool get changed
  {
    return _changed;
  }
}

class _StringPair
{
  String _value;
  bool _changed = false;
  _StringPair({required final String val}) : _value=val;
  String get value
  {
    return _value;
  }
  set value(final String newVal)
  {
    if (value != newVal)
    {
      _changed = true;
      _value = newVal;
    }
  }
  bool get changed
  {
    return _changed;
  }
}

class PreferenceManager
{
  final SharedPreferences _prefs;
  final Map<PreferenceDouble, _DoublePair> _doubleMap = <PreferenceDouble, _DoublePair>{};
  final Map<PreferenceInt, _IntPair> _intMap = <PreferenceInt, _IntPair>{};
  final Map<PreferenceBool, _BoolPair> _boolMap = <PreferenceBool, _BoolPair>{};
  final Map<PreferenceString, _StringPair> _stringMap = <PreferenceString, _StringPair>{};
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
  late DrawingLayerSettingsConstraints drawingLayerSettingsConstraints;
  late ShadingLayerSettingsConstraints shadingLayerSettingsConstraints;
  late SelectionBarWidgetOptions selectionBarWidgetOptions;
  late CanvasOperationsWidgetOptions canvasOperationsWidgetOptions;
  late CanvasSizeOptions canvasSizeOptions;
  late PaletteManagerEntryOptions paletteManagerEntryOptions;
  late PaletteManagerOptions paletteManagerOptions;
  late ProjectManagerEntryOptions projectManagerEntryOptions;
  late ProjectManagerOptions projectManagerOptions;

  late KPixPainterOptions kPixPainterOptions;

  late ToolOptions toolOptions;
  late ShaderOptions shaderOptions;

  late KPalConstraints kPalConstraints;
  late KPalWidgetOptions kPalWidgetOptions;
  late KPalSliderConstraints kPalSliderConstraints;

  late ReferenceLayerSettings referenceLayerSettings;
  late GridLayerSettings gridLayerSettings;

  late ColorNames colorNames;

  final FontManager _fontManager;
  final StampManager _stampManager;

  late GuiPreferenceContent guiPreferenceContent;
  late BehaviorPreferenceContent behaviorPreferenceContent;
  late StylusPreferenceContent stylusPreferenceContent;
  late TouchPreferenceContent touchPreferenceContent;
  late DesktopPreferenceContent desktopPreferenceContent;




  PreferenceManager(final SharedPreferences prefs, final FontManager fontManager, final StampManager stampManager) : _prefs = prefs, _fontManager = fontManager, _stampManager = stampManager
  {
    _init();
    _loadWidgetOptions();
    _loadToolOptions();
    _loadKPalOptions();
    _loadColorNames();
    _loadPainterOptions();
    loadPreferences();

  }

  void _init()
  {
    for (final PreferenceDouble dblEnum in PreferenceDouble.values)
    {
      _doubleMap[dblEnum] = _DoublePair(val: _prefs.getDouble(dblEnum.name) ?? dblEnum.defaultValue);
    }

    for (final PreferenceInt intEnum in PreferenceInt.values)
    {
      _intMap[intEnum] = _IntPair(val: _prefs.getInt(intEnum.name) ?? intEnum.defaultValue);
    }

    for (final PreferenceBool boolEnum in PreferenceBool.values)
    {
      _boolMap[boolEnum] = _BoolPair(val: _prefs.getBool(boolEnum.name) ?? boolEnum.defaultValue);
    }

    for (final PreferenceString stringEnum in PreferenceString.values)
    {
      _stringMap[stringEnum] = _StringPair(val: _prefs.getString(stringEnum.name) ?? stringEnum.defaultValue);
    }
  }

  double _getValueD(final PreferenceDouble prefName)
  {
    return _doubleMap[prefName]?.value ?? 0.0;
  }

  int _getValueI(final PreferenceInt prefName)
  {
    return _intMap[prefName]?.value ?? 0;
  }

  bool _getValueB(final PreferenceBool prefName)
  {
    return _boolMap[prefName]?.value ?? false;
  }

  String _getValueS(final PreferenceString prefName)
  {
    return _stringMap[prefName]?.value ?? "";
  }


   Future<void> _savePreferences() async
   {
    _doubleMap.forEach((final PreferenceDouble key, final _DoublePair value)
    {
      if (value.changed)
      {
        _prefs.setDouble(key.name, value.value);
      }
    });
    _intMap.forEach((final PreferenceInt key, final _IntPair value)
    {
      if (value.changed)
      {
        _prefs.setInt(key.name, value.value);
      }
    });
    _boolMap.forEach((final PreferenceBool key, final _BoolPair value)
    {
      if (value.changed)
      {
        _prefs.setBool(key.name, value.value);
      }
    });
    _stringMap.forEach((final PreferenceString key, final _StringPair value)
    {
      if (value.changed)
      {
        _prefs.setString(key.name, value.value);
      }
    });
  }

  void _loadWidgetOptions()
  {
    mainLayoutOptions = MainLayoutOptions(
        splitViewDividerWidth: _getValueD(PreferenceDouble.MainLayout_SplitView_DividerWidth),
        splitViewFlexLeftMin: _getValueD(PreferenceDouble.MainLayout_SplitView_FlexLeftMin),
        splitViewFlexLeftMax: _getValueD(PreferenceDouble.MainLayout_SplitView_FlexLeftMax),
        splitViewFlexRightMin: _getValueD(PreferenceDouble.MainLayout_SplitView_FlexRightMin),
        splitViewFlexRightMax: _getValueD(PreferenceDouble.MainLayout_SplitView_FlexRightMax),
        splitViewFlexLeftDefault: _getValueD(PreferenceDouble.MainLayout_SplitView_FlexLeftDefault),
        splitViewFlexRightDefault: _getValueD(PreferenceDouble.MainLayout_SplitView_FlexRightDefault),
        recoverCheckIntervalMinutes: _getValueI(PreferenceInt.Main_RecoveryCheckInterValMinutes),
        loadingScreenPadding: _getValueD(PreferenceDouble.MainLayout_LoadingScreen_Padding),
        titleBarPadding: _getValueD(PreferenceDouble.MainLayout_TitleBar_Padding),
        );
    canvasWidgetOptions = CanvasOptions(
        historyCheckPollRate: _getValueI(PreferenceInt.Layout_Canvas_HistoryCheck_PollRate),
        minVisibilityFactor: _getValueD(PreferenceDouble.Layout_Canvas_MinVisibilityFactor),
        idleTimerRate: _getValueI(PreferenceInt.Layout_Canvas_IdleTimerRate),);
    toolsWidgetOptions = ToolsWidgetOptions(
        padding: _getValueD(PreferenceDouble.Layout_Tools_Padding),
        colCount: _getValueI(PreferenceInt.Layout_Tools_ColCount),
        buttonSize: _getValueD(PreferenceDouble.Layout_Tools_ButtonSize),
        iconSize: _getValueD(PreferenceDouble.Layout_Tools_IconSize),);
    paletteWidgetOptions = PaletteWidgetOptions(
        padding: _getValueD(PreferenceDouble.Layout_Palette_Padding),
        managerButtonSize: _getValueD(PreferenceDouble.Layout_Palette_ManagerButtonSize),
        borderRadius: _getValueD(PreferenceDouble.Layout_Palette_BorderRadius),);
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
        smallIconSize: _getValueD(PreferenceDouble.Layout_ToolSettings_SmallIconSize),);
    mainToolbarWidgetOptions = MainToolbarWidgetOptions(
        paletteFlex: _getValueI(PreferenceInt.Layout_MainToolbar_PaletteFlex),
        toolSettingsFlex: _getValueI(PreferenceInt.Layout_MainToolbar_ToolSettingsFlex),
        dividerHeight: _getValueD(PreferenceDouble.Layout_MainToolbar_DividerHeight),
        dividerPadding: _getValueD(PreferenceDouble.Layout_MainToolbar_DividerPadding),
        toolHeight: _getValueI(PreferenceInt.Layout_MainToolbar_ToolHeight),);
    shaderWidgetOptions = ShaderWidgetOptions(
        outSidePadding: _getValueD(PreferenceDouble.Layout_Shader_OutsidePadding),);
    statusBarWidgetOptions = StatusBarWidgetOptions(
      height: _getValueD(PreferenceDouble.Layout_StatusBar_Height),
      padding: _getValueD(PreferenceDouble.Layout_StatusBar_Padding),
      dividerWidth: _getValueD(PreferenceDouble.Layout_StatusBar_DividerWidth),);
    shaderOptions = ShaderOptions(
        shaderDirectionDefault: _getValueB(PreferenceBool.Shader_DirectionRight),
        onlyCurrentRampEnabledDefault: _getValueB(PreferenceBool.Shader_CurrentRampOnly),
        isEnabledDefault: _getValueB(PreferenceBool.Shader_IsEnabled),);
    overlayEntryOptions = OverlayEntrySubMenuOptions(
        offsetX: _getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_OffsetX),
        offsetXLeft: _getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_OffsetXLeft),
        offsetY: _getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_OffsetY),
        buttonSpacing: _getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_ButtonSpacing),
        width: _getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_Width),
        buttonHeight: _getValueD(PreferenceDouble.Layout_OverlayEntrySubMenu_ButtonHeight),
        smokeOpacity: _getValueI(PreferenceInt.Layout_OverlayEntry_SmokeOpacity),
        animationLengthMs: _getValueI(PreferenceInt.Layout_OverlayEntrySubMenu_AnimationLengthMs),);
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
        elevation: _getValueD(PreferenceDouble.Layout_OverlayAlertDialog_Elevation),);
    mainButtonWidgetOptions = MainButtonWidgetOptions(
        padding: _getValueD(PreferenceDouble.Layout_MainButton_Padding),
        menuIconSize: _getValueD(PreferenceDouble.Layout_MainButton_MenuIconSize),
        dividerSize: _getValueD(PreferenceDouble.Layout_MainButton_DividerSize),);
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
        thumbUpdateTimerMsec: _getValueI(PreferenceInt.Layout_LayerWidget_ThumbUpdateTimerMSec),
        addButtonSize: _getValueI(PreferenceInt.Layout_LayerWidget_AddLayerButtonSize),);
    drawingLayerSettingsConstraints = DrawingLayerSettingsConstraints(
        darkenBrightenMin: _getValueI(PreferenceInt.DrawingLayerConstraints_MinDarkenBrighten),
        darkenBrightenDefault: _getValueI(PreferenceInt.DrawingLayerConstraints_DefaultDarkenBrighten),
        darkenBrightenMax: _getValueI(PreferenceInt.DrawingLayerConstraints_MaxDarkenBrighten),
        glowDepthMin: _getValueI(PreferenceInt.DrawingLayerConstraints_MinGlowDepth),
        glowDepthDefault: _getValueI(PreferenceInt.DrawingLayerConstraints_DefaultGlowDepth),
        glowDepthMax: _getValueI(PreferenceInt.DrawingLayerConstraints_MaxGlowDepth),
        glowDirectionDefault: _getValueB(PreferenceBool.DrawingLayerConstraints_DefaultGlowDirection),
        bevelDistanceMin: _getValueI(PreferenceInt.DrawingLayerConstraints_MinBevelDistance),
        bevelDistanceDefault: _getValueI(PreferenceInt.DrawingLayerConstraints_DefaultBevelDistance),
        bevelDistanceMax: _getValueI(PreferenceInt.DrawingLayerConstraints_MaxBevelDistance),
        bevelStrengthMin: _getValueI(PreferenceInt.DrawingLayerConstraints_MinBevelStrength),
        bevelStrengthDefault: _getValueI(PreferenceInt.DrawingLayerConstraints_DefaultBevelStrength),
        bevelStrengthMax: _getValueI(PreferenceInt.DrawingLayerConstraints_MaxBevelStrength),
        dropShadowOffsetMin: _getValueI(PreferenceInt.DrawingLayerConstraints_MinDropShadowDistance),
        dropShadowOffsetDefault: _getValueI(PreferenceInt.DrawingLayerConstraints_DefaultDropShadowDistance),
        dropShadowOffsetMax: _getValueI(PreferenceInt.DrawingLayerConstraints_MaxDropShadowDistance),);
    shadingLayerSettingsConstraints = ShadingLayerSettingsConstraints(
        shadingStepsMin: _getValueI(PreferenceInt.ShadingLayerConstraints_MinAmount),
        shadingStepsDefault: _getValueI(PreferenceInt.ShadingLayerConstraints_DefaultAmount),
        shadingStepsMax: _getValueI(PreferenceInt.ShadingLayerConstraints_MaxAmount),);
    selectionBarWidgetOptions = SelectionBarWidgetOptions(
        iconHeight: _getValueD(PreferenceDouble.Layout_SelectionBar_IconHeight,),
        padding: _getValueD(PreferenceDouble.Layout_SelectionBar_Padding),
        opacityDuration: _getValueI(PreferenceInt.Layout_SelectionBar_OpacityDuration),);
    canvasOperationsWidgetOptions = CanvasOperationsWidgetOptions(
        iconHeight: _getValueD(PreferenceDouble.Layout_CanvasOperations_IconHeight),
        padding: _getValueD(PreferenceDouble.Layout_CanvasOperations_Padding),);
    canvasSizeOptions = CanvasSizeOptions(
        sizeMin: _getValueI(PreferenceInt.Layout_CanvasSize_SizeMin),
        sizeMax: _getValueI(PreferenceInt.Layout_CanvasSize_SizeMax),
        previewSize: _getValueI(PreferenceInt.Layout_CanvasSize_PreviewSize),);
    paletteManagerEntryOptions = PaletteManagerEntryOptions(
        borderRadius: _getValueD(PreferenceDouble.Layout_PaletteManagerEntry_BorderRadius),
        borderWidth: _getValueD(PreferenceDouble.Layout_PaletteManagerEntry_BorderWidth),
        layoutFlex: _getValueI(PreferenceInt.Layout_PaletteManagerEntry_LayoutFlex),);
    paletteManagerOptions = PaletteManagerOptions(
      colCount: _getValueI(PreferenceInt.Layout_PaletteManager_ColCount),
      entryAspectRatio: _getValueD(PreferenceDouble.Layout_PaletteManager_EntryAspectRatio),);
    projectManagerEntryOptions = ProjectManagerEntryOptions(
        borderRadius: _getValueD(PreferenceDouble.Layout_ProjectManagerEntry_BorderRadius),
        borderWidth: _getValueD(PreferenceDouble.Layout_ProjectManagerEntry_BorderWidth),
        layoutFlex: _getValueI(PreferenceInt.Layout_ProjectManagerEntry_LayoutFlex),);
    projectManagerOptions = ProjectManagerOptions(
        colCount: _getValueI(PreferenceInt.Layout_ProjectManager_ColCount),
        entryAspectRatio: _getValueD(PreferenceDouble.Layout_ProjectManager_EntryAspectRatio),
        maxWidth: _getValueD(PreferenceDouble.Layout_ProjectManager_MaxWidth),
        maxHeight: _getValueD(PreferenceDouble.Layout_ProjectManager_MaxHeight),);

    referenceLayerSettings = ReferenceLayerSettings(
      opacityDefault: _getValueI(PreferenceInt.ReferenceLayer_OpacityDefault),
      opacityMin: _getValueI(PreferenceInt.ReferenceLayer_OpacityMin),
      opacityMax: _getValueI(PreferenceInt.ReferenceLayer_OpacityMax),
      zoomDefault: _getValueI(PreferenceInt.ReferenceLayer_ZoomDefault),
      zoomMin: _getValueI(PreferenceInt.ReferenceLayer_ZoomMin),
      zoomMax: _getValueI(PreferenceInt.ReferenceLayer_ZoomMax),
      aspectRatioDefault: _getValueD(PreferenceDouble.ReferenceLayer_AspectRatioDefault),
      aspectRatioMin: _getValueD(PreferenceDouble.ReferenceLayer_AspectRatioMin),
      aspectRatioMax: _getValueD(PreferenceDouble.ReferenceLayer_AspectRatioMax),
      zoomCurveExponent: _getValueD(PreferenceDouble.ReferenceLayer_ZoomCurveExponent),
    );

    gridLayerSettings = GridLayerSettings(
      opacityDefault: _getValueI(PreferenceInt.GridLayer_OpacityDefault),
      opacityMin: _getValueI(PreferenceInt.GridLayer_OpacityMin),
      opacityMax: _getValueI(PreferenceInt.GridLayer_OpacityMax),
      brightnessDefault: _getValueI(PreferenceInt.GridLayer_BrightnessDefault),
      brightnessMin: _getValueI(PreferenceInt.GridLayer_BrightnessMin),
      brightnessMax: _getValueI(PreferenceInt.GridLayer_BrightnessMax),
      intervalXDefault: _getValueI(PreferenceInt.GridLayer_IntervalXDefault),
      intervalXMin: _getValueI(PreferenceInt.GridLayer_IntervalXMin),
      intervalXMax: _getValueI(PreferenceInt.GridLayer_IntervalXMax),
      intervalYDefault: _getValueI(PreferenceInt.GridLayer_IntervalYDefault),
      intervalYMin: _getValueI(PreferenceInt.GridLayer_IntervalYMin),
      intervalYMax: _getValueI(PreferenceInt.GridLayer_IntervalYMax),
      horizonDefault: _getValueD(PreferenceDouble.GridLayer_HorizonDefault),
      vanishingPointMin: _getValueD(PreferenceDouble.GridLayer_VanishingPointMin),
      vanishingPointMax: _getValueD(PreferenceDouble.GridLayer_VanishingPointMax),
      vanishingPoint1Default: _getValueD(PreferenceDouble.GridLayer_VanishingPoint1Default),
      vanishingPoint2Default: _getValueD(PreferenceDouble.GridLayer_VanishingPoint2Default),
      vanishingPoint3Default: _getValueD(PreferenceDouble.GridLayer_VanishingPoint3Default),
      gridTypeValue: _getValueI(PreferenceInt.GridLayer_GridTypeDefault),
    );
  }

  void _loadToolOptions()
  {
    final PencilOptions pencilOptions = PencilOptions(
        sizeMin: _getValueI(PreferenceInt.Tool_Pencil_SizeMin),
        sizeMax: _getValueI(PreferenceInt.Tool_Pencil_SizeMax),
        sizeDefault: _getValueI(PreferenceInt.Tool_Pencil_Size),
        shapeDefault: _getValueI(PreferenceInt.Tool_Pencil_Shape),
        pixelPerfectDefault: _getValueB(PreferenceBool.Tool_Pencil_PixelPerfect),);
    final ShapeOptions shapeOptions = ShapeOptions(
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
    final FillOptions fillOptions = FillOptions(
        fillAdjacentDefault: _getValueB(PreferenceBool.Tool_Fill_FillAdjacent),
        fillWholeRampDefault: _getValueB(PreferenceBool.Tool_Fill_FillWholeRamp),);
    final SelectOptions selectOptions = SelectOptions(
        shapeDefault: _getValueI(PreferenceInt.Tool_Select_Shape),
        keepAspectRatioDefault: _getValueB(PreferenceBool.Tool_Select_KeepAspectRatio),
        modeDefault: _getValueI(PreferenceInt.Tool_Select_Mode),
        wandContinuousDefault: _getValueB(PreferenceBool.Tool_Wand_Continuous),
        wandWholeRampDefault: _getValueB(PreferenceBool.Tool_Wand_SelectFromWholeRamp),);
    final ColorPickOptions colorPickOptions = ColorPickOptions();
    final EraserOptions eraserOptions = EraserOptions(
        sizeMin: _getValueI(PreferenceInt.Tool_Eraser_SizeMin),
        sizeMax: _getValueI(PreferenceInt.Tool_Eraser_SizeMax),
        sizeDefault: _getValueI(PreferenceInt.Tool_Eraser_Size),
        shapeDefault: _getValueI(PreferenceInt.Tool_Eraser_Shape),);
    final TextOptions textOptions = TextOptions(
        fontManager: _fontManager,
        fontDefault: _getValueI(PreferenceInt.Tool_Text_Font),
        sizeMin: _getValueI(PreferenceInt.Tool_Text_SizeMin),
        sizeMax: _getValueI(PreferenceInt.Tool_Text_SizeMax),
        sizeDefault: _getValueI(PreferenceInt.Tool_Text_Size),
        textDefault: _getValueS(PreferenceString.Tool_Text_TextDefault),
        maxLength: _getValueI(PreferenceInt.Tool_Text_MaxLength),);
    final SprayCanOptions sprayCanOptions = SprayCanOptions(
        radiusMin: _getValueI(PreferenceInt.Tool_SprayCan_RadiusMin),
        radiusMax: _getValueI(PreferenceInt.Tool_SprayCan_RadiusMax),
        radiusDefault: _getValueI(PreferenceInt.Tool_SprayCan_Radius),
        blobSizeMin: _getValueI(PreferenceInt.Tool_SprayCan_BlobSizeMin),
        blobSizeMax: _getValueI(PreferenceInt.Tool_SprayCan_BlobSizeMax),
        blobSizeDefault: _getValueI(PreferenceInt.Tool_SprayCan_BlobSize),
        intensityMin: _getValueI(PreferenceInt.Tool_SprayCan_IntensityMin),
        intensityMax: _getValueI(PreferenceInt.Tool_SprayCan_IntensityMax),
        intensityDefault: _getValueI(PreferenceInt.Tool_SprayCan_Intensity),);
    final LineOptions lineOptions = LineOptions(
        segmentSortingDefault: _getValueB(PreferenceBool.Tool_Line_SegmentSorting),
        segmentSortStyleDefault: _getValueI(PreferenceInt.Tool_Line_SegmentSortStyle),
        widthMin: _getValueI(PreferenceInt.Tool_Line_WidthMin),
        widthMax: _getValueI(PreferenceInt.Tool_Line_WidthMax),
        widthDefault: _getValueI(PreferenceInt.Tool_Line_Width),
        bezierCalculationPoints: _getValueI(PreferenceInt.Tool_Line_BezierCalculationPoints),
        integerAspectRatioDefault: _getValueB(PreferenceBool.Tool_Line_IntegerAspectRatio),);
    final StampOptions stampOptions = StampOptions(
        stampManager: _stampManager,
        scaleMin: _getValueI(PreferenceInt.Tool_Stamp_ScaleMin),
        scaleMax: _getValueI(PreferenceInt.Tool_Stamp_ScaleMax),
        scaleDefault: _getValueI(PreferenceInt.Tool_Stamp_ScaleDefault),
        stampDefault: _getValueI(PreferenceInt.Tool_Stamp_StampDefault),
        flipHDefault: _getValueB(PreferenceBool.Tool_Stamp_FlipH),
        flipVDefault: _getValueB(PreferenceBool.Tool_Stamp_FlipH),);
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
        satCurveDefault: _getValueI(PreferenceInt.KPal_Constraints_SatCurveDefault),
        rampCountMin: _getValueI(PreferenceInt.KPal_Constraints_RampCountMin),
        rampCountMax: _getValueI(PreferenceInt.KPal_Constraints_RampCountMax),
        rampCountDefault: _getValueI(PreferenceInt.KPal_Constraints_RampCountDefault),
        maxClusters: _getValueI(PreferenceInt.KPal_Constraints_MaxClusters),);

    kPalSliderConstraints = KPalSliderConstraints(
        minHue: _getValueI(PreferenceInt.KPalSliderConstraints_MinHue),
        minSat: _getValueI(PreferenceInt.KPalSliderConstraints_MinSat),
        minVal: _getValueI(PreferenceInt.KPalSliderConstraints_MinVal),
        maxHue: _getValueI(PreferenceInt.KPalSliderConstraints_MaxHue),
        maxSat: _getValueI(PreferenceInt.KPalSliderConstraints_MaxSat),
        maxVal: _getValueI(PreferenceInt.KPalSliderConstraints_MaxVal),
        defaultHue: _getValueI(PreferenceInt.KPalSliderConstraints_DefaultHue),
        defaultSat: _getValueI(PreferenceInt.KPalSliderConstraints_DefaultSat),
        defaultVal: _getValueI(PreferenceInt.KPalSliderConstraints_DefaultVal),
    );

    final KPalColorCardWidgetOptions colorCardWidgetOptions = KPalColorCardWidgetOptions(
        borderRadius: _getValueD(PreferenceDouble.KPalColorCard_Layout_BorderRadius),
        borderWidth: _getValueD(PreferenceDouble.KPalColorCard_Layout_BorderWidth),
        outsidePadding: _getValueD(PreferenceDouble.KPalColorCard_Layout_OutsidePadding),
        colorFlex: _getValueI(PreferenceInt.KPalColorCard_Layout_ColorFlex),
        colorNameFlex: _getValueI(PreferenceInt.KPalColorCard_Layout_ColorNameFlex),
        colorNumbersFlex: _getValueI(PreferenceInt.KPalColorCard_Layout_ColorNumbersFlex),
        editAnimationDuration: _getValueI(PreferenceInt.KPalColorCard_Layout_EditAnimationDuration),
        touchTimeout: _getValueI(PreferenceInt.KPalColorCard_Layout_TouchTimeout),);

    final KPalRampWidgetOptions rampWidgetOptions = KPalRampWidgetOptions(
        padding: _getValueD(PreferenceDouble.KPalRamp_Layout_OutsidePadding),
        centerFlex: _getValueI(PreferenceInt.KPalRamp_Layout_CenterFlex),
        rightFlex: _getValueI(PreferenceInt.KPalRamp_Layout_RightFlex),
        borderWidth: _getValueD(PreferenceDouble.KPalRamp_Layout_BorderWidth),
        borderRadius: _getValueD(PreferenceDouble.KPalRamp_Layout_BorderRadius),
        dividerThickness: _getValueD(PreferenceDouble.KPalRamp_Layout_DividerThickness),
        rowControlFlex: _getValueI(PreferenceInt.KPalRamp_Layout_RowControlFlex),
        rowLabelFlex: _getValueI(PreferenceInt.KPalRamp_Layout_RowLabelFlex),
        rowValueFlex: _getValueI(PreferenceInt.KPalRamp_Layout_RowValueFlex),
        colorNameShowThreshold: _getValueI(PreferenceInt.KPalRamp_Layout_ColorShowThreshold),
        colorCardWidgetOptions: colorCardWidgetOptions,
        renderIntervalMs: _getValueI(PreferenceInt.KPalRamp_Layout_RenderIntervalMs),);

    kPalWidgetOptions = KPalWidgetOptions(
        borderWidth: _getValueD(PreferenceDouble.KPal_Layout_BorderWidth),
        outsidePadding: _getValueD(PreferenceDouble.KPal_Layout_OutsidePadding),
        smokeOpacity: _getValueI(PreferenceInt.KPal_Layout_SmokeOpacity),
        borderRadius: _getValueD(PreferenceDouble.KPal_Layout_BorderRadius),
        iconSize: _getValueD(PreferenceDouble.KPal_Layout_IconSize),
        insidePadding: _getValueD(PreferenceDouble.KPal_Layout_InsidePadding),
        rampOptions: rampWidgetOptions,);
  }

  void _loadColorNames()
  {
    final ColorNamesOptions options = ColorNamesOptions(
        defaultNameScheme: _getValueI(PreferenceInt.ColorNames_Scheme),
        defaultColorNamePath: _getValueS(PreferenceString.ColorNames_ColorNamePath),);

    colorNames = ColorNames(options: options);

  }

  void _loadPainterOptions()
  {
    kPixPainterOptions = KPixPainterOptions(
        cursorSize: _getValueD(PreferenceDouble.Painter_CursorSize),
        cursorBorderWidth: _getValueD(PreferenceDouble.Painter_CursorBorderWidth),
        pixelExtension: _getValueD(PreferenceDouble.Painter_PixelExtension),
        selectionSolidStrokeWidth: _getValueD(PreferenceDouble.Painter_SelectionSolidStrokeWidth),
        selectionPolygonCircleRadius: _getValueD(PreferenceDouble.Painter_SelectionPolygonCircleRadius),
        selectionStrokeWidthLarge: _getValueD(PreferenceDouble.Painter_SelectionStrokeWidthLarge),
        selectionStrokeWidthSmall: _getValueD(PreferenceDouble.Painter_SelectionStrokeWidthSmall),
    );
  }

  Future<void> loadPreferences() async
  {
    guiPreferenceContent = GuiPreferenceContent(
      colorNameSchemeValue: _getValueI(PreferenceInt.ColorNames_Scheme),
      rasterContrast: _getValueI(PreferenceInt.Painter_CheckerBoardContrast),
      rasterSizeValue: _getValueI(PreferenceInt.Painter_CheckerBoardSize),
      themeTypeValue: _getValueI(PreferenceInt.ThemeType),
      canvasBorderOpacityValue: _getValueI(PreferenceInt.Opacity_CanvasBorder),
      selectionOpacityValue: _getValueI(PreferenceInt.Opacity_Selection),
      toolOpacityValue: _getValueI(PreferenceInt.Opacity_Tool),
    );

    behaviorPreferenceContent = BehaviorPreferenceContent(
      undoSteps: _getValueI(PreferenceInt.HistoryOptions_Steps),
      selectAfterInsert: _getValueB(PreferenceBool.SelectShapeAfterInsert),
      selectLayerAfterInsert: _getValueB(PreferenceBool.SelectLayerAfterInsert),
      undoStepsMax: _getValueI(PreferenceInt.HistoryOptions_StepsMax),
      undoStepsMin: _getValueI(PreferenceInt.HistoryOptions_StepsMin),
    );

    stylusPreferenceContent = StylusPreferenceContent(
      stylusLongPressCancelDistance: _getValueD(PreferenceDouble.StylusOptions_LongPressCancelDistance),
      stylusLongPressCancelDistanceMin: _getValueD(PreferenceDouble.StylusOptions_LongPressCancelDistanceMin),
      stylusLongPressCancelDistanceMax: _getValueD(PreferenceDouble.StylusOptions_LongPressCancelDistanceMax),
      stylusLongPressDelay: _getValueI(PreferenceInt.StylusOptions_LongPressDelay),
      stylusLongPressDelayMin: _getValueI(PreferenceInt.StylusOptions_LongPressDelayMin),
      stylusLongPressDelayMax: _getValueI(PreferenceInt.StylusOptions_LongPressDelayMax),
      stylusPollInterval: _getValueI(PreferenceInt.StylusOptions_PollInterval),
      stylusPollIntervalMin: _getValueI(PreferenceInt.StylusOptions_PollIntervalMin),
      stylusPollIntervalMax: _getValueI(PreferenceInt.StylusOptions_PollIntervalMax),
      stylusSizeStepDistance: _getValueD(PreferenceDouble.StylusOptions_SizeStepDistance),
      stylusSizeStepDistanceMin: _getValueD(PreferenceDouble.StylusOptions_SizeStepDistanceMin),
      stylusSizeStepDistanceMax: _getValueD(PreferenceDouble.StylusOptions_SizeStepDistanceMax),
      stylusZoomStepDistance: _getValueD(PreferenceDouble.StylusOptions_ZoomStepDistance),
      stylusZoomStepDistanceMin: _getValueD(PreferenceDouble.StylusOptions_ZoomStepDistanceMin),
      stylusZoomStepDistanceMax: _getValueD(PreferenceDouble.StylusOptions_ZoomStepDistanceMax),
      stylusPickMaxDuration: _getValueI(PreferenceInt.StylusOptions_PickMaxDuration),
      stylusPickMaxDurationMin: _getValueI(PreferenceInt.StylusOptions_PickMaxDurationMin),
      stylusPickMaxDurationMax: _getValueI(PreferenceInt.StylusOptions_PickMaxDurationMax),
    );

    touchPreferenceContent = TouchPreferenceContent(
      singleTouchDelay: _getValueI(PreferenceInt.TouchOptions_SingleTouchDelay),
      singleTouchDelayMin: _getValueI(PreferenceInt.TouchOptions_SingleTouchDelayMin),
      singleTouchDelayMax: _getValueI(PreferenceInt.TouchOptions_SingleTouchDelayMax),
      zoomStepDistance: _getValueD(PreferenceDouble.TouchOptions_ZoomStepDistance),
      zoomStepDistanceMin: _getValueD(PreferenceDouble.TouchOptions_ZoomStepDistanceMin),
      zoomStepDistanceMax: _getValueD(PreferenceDouble.TouchOptions_ZoomStepDistanceMax),
    );

    desktopPreferenceContent = DesktopPreferenceContent(
      cursorTypeValue: _getValueI(PreferenceInt.DesktopOptions_CursorType),
    );
  }

  Future<void> saveUserPrefs() async
  {
    //GUI PREFERENCES
    if (guiPreferenceContent.colorNameScheme.value != colorNameSchemeIndexMap[_intMap[PreferenceInt.ColorNames_Scheme]!.value])
    {
      _intMap[PreferenceInt.ColorNames_Scheme]!.value = colorNameSchemeIndexMap.keys.firstWhere((final int x) => colorNameSchemeIndexMap[x] == guiPreferenceContent.colorNameScheme.value, orElse:() => PreferenceInt.ColorNames_Scheme.defaultValue);
      _loadColorNames();
    }
    _intMap[PreferenceInt.Painter_CheckerBoardContrast]!.value = guiPreferenceContent.rasterContrast.value;
    _intMap[PreferenceInt.Painter_CheckerBoardSize]!.value = rasterSizes[guiPreferenceContent.rasterSizeIndex.value];
    if (guiPreferenceContent.themeType.value != themeTypeIndexMap[_intMap[PreferenceInt.ThemeType]!.value])
    {
      _intMap[PreferenceInt.ThemeType]!.value = themeTypeIndexMap.keys.firstWhere((final int x) => themeTypeIndexMap[x] == guiPreferenceContent.themeType.value, orElse:() => PreferenceInt.ThemeType.defaultValue);
      themeSettings.themeMode =  guiPreferenceContent.themeType.value;
    }
    _intMap[PreferenceInt.Opacity_Tool]!.value = guiPreferenceContent.toolOpacity.value;
    _intMap[PreferenceInt.Opacity_Selection]!.value = guiPreferenceContent.selectionOpacity.value;
    _intMap[PreferenceInt.Opacity_CanvasBorder]!.value = guiPreferenceContent.canvasBorderOpacity.value;

    //BEHAVIOR PREFERENCES
    if (_intMap[PreferenceInt.HistoryOptions_Steps]!.value != behaviorPreferenceContent.undoSteps.value)
    {
      _intMap[PreferenceInt.HistoryOptions_Steps]!.value = behaviorPreferenceContent.undoSteps.value;
      GetIt.I.get<HistoryManager>().changeMaxEntries(maxEntries: behaviorPreferenceContent.undoSteps.value);
    }
    _boolMap[PreferenceBool.SelectShapeAfterInsert]!.value = behaviorPreferenceContent.selectShapeAfterInsert.value;

    //STYLUS PREFERENCES
    _doubleMap[PreferenceDouble.StylusOptions_LongPressCancelDistance]!.value = stylusPreferenceContent.stylusLongPressCancelDistance.value;
    _intMap[PreferenceInt.StylusOptions_LongPressDelay]!.value = stylusPreferenceContent.stylusLongPressDelay.value;
    _intMap[PreferenceInt.StylusOptions_PollInterval]!.value = stylusPreferenceContent.stylusPollInterval.value;
    _doubleMap[PreferenceDouble.StylusOptions_SizeStepDistance]!.value = stylusPreferenceContent.stylusSizeStepDistance.value;
    _doubleMap[PreferenceDouble.StylusOptions_ZoomStepDistance]!.value = stylusPreferenceContent.stylusZoomStepDistance.value;
    _intMap[PreferenceInt.StylusOptions_PickMaxDuration]!.value = stylusPreferenceContent.stylusPickMaxDuration.value;

    //TOUCH PREFERENCES
    _intMap[PreferenceInt.TouchOptions_SingleTouchDelay]!.value = touchPreferenceContent.singleTouchDelay.value;
    _doubleMap[PreferenceDouble.TouchOptions_ZoomStepDistanceMax]!.value = touchPreferenceContent.zoomStepDistance.value;

    //DESKTOP PREFERENCES
    if (desktopPreferenceContent.cursorType.value != cursorTypeIndexMap[_intMap[PreferenceInt.DesktopOptions_CursorType]!.value])
    {
      _intMap[PreferenceInt.DesktopOptions_CursorType]!.value = cursorTypeIndexMap.keys.firstWhere((final int x) => cursorTypeIndexMap[x] == desktopPreferenceContent.cursorType.value, orElse:() => PreferenceInt.DesktopOptions_CursorType.defaultValue);
    }

    await _savePreferences();


  }
}
