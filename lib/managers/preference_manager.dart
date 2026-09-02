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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/main.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/util/color_names.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum PreferenceDouble
{
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

  DrawingLayerConstraints_MinDarkenBrighten(defaultValue: -5),
  DrawingLayerConstraints_DefaultDarkenBrighten(defaultValue: -1),
  DrawingLayerConstraints_MaxDarkenBrighten(defaultValue: 5),
  DrawingLayerConstraints_MinGlowDepth(defaultValue: -6),
  DrawingLayerConstraints_DefaultGlowDepth(defaultValue: 3),
  DrawingLayerConstraints_MaxGlowDepth(defaultValue: 6),
  DrawingLayerConstraints_MinBevelDistance(defaultValue: 1),
  DrawingLayerConstraints_DefaultBevelDistance(defaultValue: 1),
  DrawingLayerConstraints_MaxBevelDistance(defaultValue: 8),
  DrawingLayerConstraints_MinBevelStrength(defaultValue: 1),
  DrawingLayerConstraints_DefaultBevelStrength(defaultValue: 2),
  DrawingLayerConstraints_MaxBevelStrength(defaultValue: 8),
  DrawingLayerConstraints_MinDropShadowDistance(defaultValue: -16),
  DrawingLayerConstraints_DefaultDropShadowDistance(defaultValue: 1),
  DrawingLayerConstraints_MaxDropShadowDistance(defaultValue: 16),

  ShadingLayerConstraints_MinAmount(defaultValue: 0),
  ShadingLayerConstraints_DefaultAmountDarken(defaultValue: 4),
  ShadingLayerConstraints_DefaultAmountBrighten(defaultValue: 4),
  ShadingLayerConstraints_MaxAmount(defaultValue: 8),
  ShadingLayerConstraints_MaxDither(defaultValue: 16),

  FrameConstraints_MinFps(defaultValue: 1),
  FrameConstraints_MaxFps(defaultValue: 30),
  FrameConstraints_DefaultFps(defaultValue: 12),

  Painter_CheckerBoardSize(defaultValue: 8),
  Painter_CheckerBoardContrast(defaultValue: 25),
  Painter_BackupImagePollingRateMs(defaultValue: 50),

  ColorNames_Scheme(defaultValue: 0),

  Opacity_Tool(defaultValue: 50),
  Opacity_Selection(defaultValue: 50),
  Opacity_CanvasBorder(defaultValue: 50),

  HistoryOptions_Steps(defaultValue: 100),
  HistoryOptions_StepsMax(defaultValue: 1000),
  HistoryOptions_StepsMin(defaultValue: 10),

  DefaultShadingLayerSettings_Darken(defaultValue: 0),
  DefaultShadingLayerSettings_MaxDarken(defaultValue: 5),

  ThemeType(defaultValue: 0),

  StylusOptions_LongPressDelay(defaultValue: 150),
  StylusOptions_LongPressDelayMin(defaultValue: 50),
  StylusOptions_LongPressDelayMax(defaultValue: 1000),
  StylusOptions_PollInterval(defaultValue: 50),
  StylusOptions_PollIntervalMin(defaultValue: 20),
  StylusOptions_PollIntervalMax(defaultValue: 150),
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

  SelectShapeAfterInsert(defaultValue: false),
  SelectLayerAfterInsert(defaultValue: true),
  ShowReferenceOutsideCanvas(defaultValue: false),

  ProjectDirectory_UseCustom(defaultValue: false),

  DrawingLayerConstraints_DefaultGlowRecursive(defaultValue: true),


  ;
  const PreferenceBool({
    required this.defaultValue,
  });
  final bool defaultValue;
}

enum PreferenceString
{
  ColorNames_ColorNamePath(defaultValue: PreferenceManager.ASSET_PATH_COLOR_NAMES),
  ProjectDirectory_CustomPath(defaultValue: ""),

  ;
  const PreferenceString({
    required this.defaultValue,
  });
  final String defaultValue;
}


class _Pair<E>
{
  E _value;
  bool _changed = false;
  _Pair({required final E val}) : _value=val;
  E get value
  {
    return _value;
  }
  set value(final E newVal)
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
  static const String ASSET_ICON = "imgs/kpix_icon.png";
  static const String ASSET_CONTROLS = "docs/controls.md";
  static const String ASSET_CREDITS = "docs/credits.md";
  static const String ASSET_PATH_STAMPS = "stamps";
  static const String ASSET_PATH_PALETTES = "palettes";
  static const String ASSET_PATH_FONTS = "fonts";
  static const String ASSET_PATH_COLOR_NAMES = "color_names";


  final SharedPreferences _prefs;
  final Map<PreferenceDouble, _Pair<double>> _doubleMap = <PreferenceDouble, _Pair<double>>{};
  final Map<PreferenceInt, _Pair<int>> _intMap = <PreferenceInt, _Pair<int>>{};
  final Map<PreferenceBool, _Pair<bool>> _boolMap = <PreferenceBool, _Pair<bool>>{};
  final Map<PreferenceString, _Pair<String>> _stringMap = <PreferenceString, _Pair<String>>{};
  late DrawingLayerSettingsConstraints drawingLayerSettingsConstraints;
  late ShadingLayerSettingsConstraints shadingLayerSettingsConstraints;
  late KPixPainterOptions kPixPainterOptions;
  late FrameConstraints frameConstraints;

  late ColorNames colorNames;

  late GuiPreferenceContent guiPreferenceContent;
  late BehaviorPreferenceContent behaviorPreferenceContent;
  late StylusPreferenceContent stylusPreferenceContent;
  late TouchPreferenceContent touchPreferenceContent;
  late DesktopPreferenceContent desktopPreferenceContent;

  bool _preferenceContentCreated = false;



  PreferenceManager(final SharedPreferences prefs) : _prefs = prefs
  {
    _init();
    _loadWidgetOptions();
    _loadColorNames();
    _loadPainterOptions();
    loadPreferences();

  }

  void _init()
  {
    for (final PreferenceDouble dblEnum in PreferenceDouble.values)
    {
      _doubleMap[dblEnum] = _Pair<double>(val: _prefs.getDouble(dblEnum.name) ?? dblEnum.defaultValue);
    }

    for (final PreferenceInt intEnum in PreferenceInt.values)
    {
      _intMap[intEnum] = _Pair<int>(val: _prefs.getInt(intEnum.name) ?? intEnum.defaultValue);
    }

    for (final PreferenceBool boolEnum in PreferenceBool.values)
    {
      _boolMap[boolEnum] = _Pair<bool>(val: _prefs.getBool(boolEnum.name) ?? boolEnum.defaultValue);
    }

    for (final PreferenceString stringEnum in PreferenceString.values)
    {
      _stringMap[stringEnum] = _Pair<String>(val: _prefs.getString(stringEnum.name) ?? stringEnum.defaultValue);
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
    _doubleMap.forEach((final PreferenceDouble key, final _Pair<double> value)
    {
      if (value.changed)
      {
        _prefs.setDouble(key.name, value.value);
      }
    });
    _intMap.forEach((final PreferenceInt key, final _Pair<int> value)
    {
      if (value.changed)
      {
        _prefs.setInt(key.name, value.value);
      }
    });
    _boolMap.forEach((final PreferenceBool key, final _Pair<bool> value)
    {
      if (value.changed)
      {
        _prefs.setBool(key.name, value.value);
      }
    });
    _stringMap.forEach((final PreferenceString key, final _Pair<String> value)
    {
      if (value.changed)
      {
        _prefs.setString(key.name, value.value);
      }
    });
  }

  void _loadWidgetOptions()
  {
    drawingLayerSettingsConstraints = DrawingLayerSettingsConstraints(
        darkenBrightenMin: _getValueI(PreferenceInt.DrawingLayerConstraints_MinDarkenBrighten),
        darkenBrightenDefault: _getValueI(PreferenceInt.DrawingLayerConstraints_DefaultDarkenBrighten),
        darkenBrightenMax: _getValueI(PreferenceInt.DrawingLayerConstraints_MaxDarkenBrighten),
        glowDepthMin: _getValueI(PreferenceInt.DrawingLayerConstraints_MinGlowDepth),
        glowDepthDefault: _getValueI(PreferenceInt.DrawingLayerConstraints_DefaultGlowDepth),
        glowDepthMax: _getValueI(PreferenceInt.DrawingLayerConstraints_MaxGlowDepth),
        glowRecursiveDefault: _getValueB(PreferenceBool.DrawingLayerConstraints_DefaultGlowRecursive),
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
        shadingStepsDefaultBrighten: _getValueI(PreferenceInt.ShadingLayerConstraints_DefaultAmountBrighten),
        shadingStepsDefaultDarken: _getValueI(PreferenceInt.ShadingLayerConstraints_DefaultAmountDarken),
        shadingStepsMax: _getValueI(PreferenceInt.ShadingLayerConstraints_MaxAmount),
        ditherStepsMax: _getValueI(PreferenceInt.ShadingLayerConstraints_MaxDither),);
    frameConstraints = FrameConstraints(
      minFps: _getValueI(PreferenceInt.FrameConstraints_MinFps),
      maxFps: _getValueI(PreferenceInt.FrameConstraints_MaxFps),
      defaultFps: _getValueI(PreferenceInt.FrameConstraints_DefaultFps),);
  }


  void _loadColorNames()
  {
    colorNames = ColorNames(scheme: ColorNameScheme.fromId(_getValueI(PreferenceInt.ColorNames_Scheme)));
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
        backupPainterPollingRateMs: _getValueI(PreferenceInt.Painter_BackupImagePollingRateMs),
    );
  }

  Future<void> loadPreferences() async
  {
    final GuiPreferenceContent guiContent = GuiPreferenceContent(
      colorNameSchemeValue: _getValueI(PreferenceInt.ColorNames_Scheme),
      rasterContrast: _getValueI(PreferenceInt.Painter_CheckerBoardContrast),
      rasterSizeValue: _getValueI(PreferenceInt.Painter_CheckerBoardSize),
      themeTypeValue: _getValueI(PreferenceInt.ThemeType),
      canvasBorderOpacityValue: _getValueI(PreferenceInt.Opacity_CanvasBorder),
      selectionOpacityValue: _getValueI(PreferenceInt.Opacity_Selection),
      toolOpacityValue: _getValueI(PreferenceInt.Opacity_Tool),
    );

    shadingLayerSettingsConstraints = ShadingLayerSettingsConstraints(
      shadingStepsMin: _getValueI(PreferenceInt.ShadingLayerConstraints_MinAmount),
      shadingStepsDefaultBrighten: _getValueI(PreferenceInt.ShadingLayerConstraints_DefaultAmountBrighten),
      shadingStepsDefaultDarken: _getValueI(PreferenceInt.ShadingLayerConstraints_DefaultAmountDarken),
      shadingStepsMax: _getValueI(PreferenceInt.ShadingLayerConstraints_MaxAmount),
      ditherStepsMax: _getValueI(PreferenceInt.ShadingLayerConstraints_MaxDither),);

    frameConstraints = FrameConstraints(
      minFps: _getValueI(PreferenceInt.FrameConstraints_MinFps),
      maxFps: _getValueI(PreferenceInt.FrameConstraints_MaxFps),
      defaultFps: _getValueI(PreferenceInt.FrameConstraints_DefaultFps),
    );

    final BehaviorPreferenceContent behaviorContent = BehaviorPreferenceContent(
      undoSteps: _getValueI(PreferenceInt.HistoryOptions_Steps),
      selectAfterInsert: _getValueB(PreferenceBool.SelectShapeAfterInsert),
      selectLayerAfterInsert: _getValueB(PreferenceBool.SelectLayerAfterInsert),
      undoStepsMax: _getValueI(PreferenceInt.HistoryOptions_StepsMax),
      undoStepsMin: _getValueI(PreferenceInt.HistoryOptions_StepsMin),
      frameConstraints: frameConstraints,
      shadingConstraints: shadingLayerSettingsConstraints,
      showReferenceOutsideCanvas: _getValueB(PreferenceBool.ShowReferenceOutsideCanvas),
      useCustomProjectDirectory: _getValueB(PreferenceBool.ProjectDirectory_UseCustom),
      customProjectDirectory: _getValueS(PreferenceString.ProjectDirectory_CustomPath),
    );

    final StylusPreferenceContent stylusContent = StylusPreferenceContent(
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

    final TouchPreferenceContent touchContent = TouchPreferenceContent(
      singleTouchDelay: _getValueI(PreferenceInt.TouchOptions_SingleTouchDelay),
      singleTouchDelayMin: _getValueI(PreferenceInt.TouchOptions_SingleTouchDelayMin),
      singleTouchDelayMax: _getValueI(PreferenceInt.TouchOptions_SingleTouchDelayMax),
      zoomStepDistance: _getValueD(PreferenceDouble.TouchOptions_ZoomStepDistance),
      zoomStepDistanceMin: _getValueD(PreferenceDouble.TouchOptions_ZoomStepDistanceMin),
      zoomStepDistanceMax: _getValueD(PreferenceDouble.TouchOptions_ZoomStepDistanceMax),
    );

    final DesktopPreferenceContent desktopContent = DesktopPreferenceContent(
      cursorTypeValue: _getValueI(PreferenceInt.DesktopOptions_CursorType),
    );

    if (_preferenceContentCreated)
    {
      guiPreferenceContent.copyValuesFrom(other: guiContent);
      behaviorPreferenceContent.copyValuesFrom(other: behaviorContent);
      stylusPreferenceContent.copyValuesFrom(other: stylusContent);
      touchPreferenceContent.copyValuesFrom(other: touchContent);
      desktopPreferenceContent.copyValuesFrom(other: desktopContent);
    }
    else
    {
      guiPreferenceContent = guiContent;
      behaviorPreferenceContent = behaviorContent;
      stylusPreferenceContent = stylusContent;
      touchPreferenceContent = touchContent;
      desktopPreferenceContent = desktopContent;
      _preferenceContentCreated = true;
    }
  }

  Future<void> saveUserPrefs() async
  {
    //GUI PREFERENCES
    if (guiPreferenceContent.colorNameScheme.value != ColorNameScheme.fromId(_intMap[PreferenceInt.ColorNames_Scheme]!.value))
    {
      _intMap[PreferenceInt.ColorNames_Scheme]!.value = guiPreferenceContent.colorNameScheme.value.id;
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

    _intMap[PreferenceInt.ShadingLayerConstraints_DefaultAmountDarken]!.value = behaviorPreferenceContent.shadingStepsMinus.value;
    _intMap[PreferenceInt.ShadingLayerConstraints_DefaultAmountBrighten]!.value = behaviorPreferenceContent.shadingStepsPlus.value;

    _intMap[PreferenceInt.FrameConstraints_DefaultFps]!.value = behaviorPreferenceContent.fps.value;
    _boolMap[PreferenceBool.ShowReferenceOutsideCanvas]!.value = behaviorPreferenceContent.showReferenceOutsideCanvas.value;

    _boolMap[PreferenceBool.ProjectDirectory_UseCustom]!.value = behaviorPreferenceContent.useCustomProjectDirectory.value;
    _stringMap[PreferenceString.ProjectDirectory_CustomPath]!.value = behaviorPreferenceContent.customProjectDirectory.value;


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
    if (desktopPreferenceContent.cursorType.value != CursorType.fromId(_intMap[PreferenceInt.DesktopOptions_CursorType]!.value))
    {
      _intMap[PreferenceInt.DesktopOptions_CursorType]!.value = desktopPreferenceContent.cursorType.value.id;
    }

    await _savePreferences();


  }
}
