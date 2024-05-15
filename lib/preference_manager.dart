
// ignore_for_file: constant_identifier_names
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
import 'package:kpix/widgets/color_chooser_widget.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/listener_example.dart';
import 'package:kpix/widgets/main_toolbar_widget.dart';
import 'package:kpix/widgets/palette_widget.dart';
import 'package:kpix/widgets/status_bar_widget.dart';
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
  Layout_ColorEntry_UnselectedMargin(defaultValue: 2.0),
  Layout_ColorEntry_SelectedMargin(defaultValue: 0.0),
  Layout_ColorEntry_RoundRadius(defaultValue: 4.0),
  Layout_ColorEntry_ContrastColorThreshold(defaultValue: 0.95),
  Layout_ColorEntry_ButtonPadding(defaultValue: 4.0),
  Layout_ColorEntry_MinSize(defaultValue: 8.0),
  Layout_ColorEntry_MaxSize(defaultValue: 64.0),
  Layout_ColorEntry_DragFeedbackSize(defaultValue: 32.0),
  Layout_ColorEntry_DragTargetWidth(defaultValue: 6.0),

  Layout_ColorChooser_IconSize(defaultValue: 36.0),
  Layout_ColorChooser_ColorContainerBorderRadius(defaultValue: 16.0),
  Layout_ColorChooser_Padding(defaultValue: 8.0),

  Layout_ToolsSettings_Padding(defaultValue: 8.0),

  Layout_MainToolbar_DividerHeight(defaultValue: 2.0),

  Layout_Shader_OutsidePadding(defaultValue: 8.0),

  Layout_StatusBar_Height(defaultValue: 20.0),
  Layout_StatusBar_Padding(defaultValue: 2.0),
  Layout_StatusBar_DividerWidth(defaultValue: 2.0),


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

  Layout_MainToolbar_PaletteFlex(defaultValue: 6),
  Layout_MainToolbar_ToolSettingsFlex(defaultValue: 4),

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
  late CanvasOptions canvasWidgetOptions;
  late ToolsWidgetOptions toolsWidgetOptions;
  late PaletteWidgetOptions paletteWidgetOptions;
  late ColorEntryWidgetOptions colorEntryOptions;
  late ColorChooserWidgetOptions colorChooserWidgetOptions;
  late ToolSettingsWidgetOptions toolSettingsWidgetOptions;
  late MainToolbarWidgetOptions mainToolbarWidgetOptions;
  late ShaderWidgetOptions shaderWidgetOptions;
  late StatusBarWidgetOptions statusBarWidgetOptions;

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
        padding: getValueD(PreferenceDouble.Layout_ToolsSettings_Padding));
    mainToolbarWidgetOptions = MainToolbarWidgetOptions(
        paletteFlex: getValueI(PreferenceInt.Layout_MainToolbar_PaletteFlex),
        toolSettingsFlex: getValueI(PreferenceInt.Layout_MainToolbar_ToolSettingsFlex),
        dividerHeight: getValueD(PreferenceDouble.Layout_MainToolbar_DividerHeight));
    shaderWidgetOptions = ShaderWidgetOptions(
        outSidePadding: getValueD(PreferenceDouble.Layout_Shader_OutsidePadding));
    statusBarWidgetOptions = StatusBarWidgetOptions(
        height: getValueD(PreferenceDouble.Layout_StatusBar_Height),
        padding: getValueD(PreferenceDouble.Layout_StatusBar_Padding),
        dividerWidth: getValueD(PreferenceDouble.Layout_StatusBar_DividerWidth),
        );
    shaderOptions = ShaderOptions(
        shaderDirectionDefault: getValueB(PreferenceBool.Shader_DirectionRight),
        onlyCurrentRampEnabledDefault: getValueB(PreferenceBool.Shader_CurrentRampOnly),
        isEnabledDefault: getValueB(PreferenceBool.Shader_IsEnabled));

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
        selectFromWholeRampDefault: getValueB(PreferenceBool.Tool_Wand_SelectFromWholeRamp));
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

}

