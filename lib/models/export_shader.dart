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

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:kpix/l10n/app_localizations.dart';

/// The shaders that can be applied to an exported image.
enum ExportShaderType
{
  crt,
  lcd,
  upscale,
  color,
  dithering,
  effects,
}

/// How the value of an [ExportShaderSliderParameter] is shown.
enum ExportShaderValueFormat
{
  percent,
  pixels,
  decimal,
  degrees,
  integer,
}

/// A value of an export shader the user can change.
///
/// [uniform] is the name of the float uniform in the shader the value is written to.
sealed class ExportShaderParameter
{
  final String uniform;
  final String Function(AppLocalizations l10n) label;
  /// The heading of the group this parameter belongs to; the dialog shows a heading where it changes.
  final String Function(AppLocalizations l10n)? section;
  const ExportShaderParameter({required this.uniform, required this.label, this.section});

  Object get initialValue;
  void apply({required final FragmentShader shader, required final Object value});
}

final class ExportShaderSliderParameter extends ExportShaderParameter
{
  final double min;
  final double max;
  final double initial;
  /// Null for a continuous slider.
  final int? divisions;
  final ExportShaderValueFormat format;
  /// Shows these colors along the track instead of the value.
  final List<Color>? trackGradient;

  const ExportShaderSliderParameter({
    required super.uniform,
    required super.label,
    required this.min,
    required this.max,
    required this.initial,
    required this.format,
    this.divisions,
    this.trackGradient,
    super.section,
  });

  @override
  Object get initialValue => initial;

  @override
  void apply({required final FragmentShader shader, required final Object value})
  {
    shader.getUniformFloat(uniform).set(value as double);
  }

  String formatValue({required final double value})
  {
    switch (format)
    {
      case ExportShaderValueFormat.percent:
        return "${(value * 100).round()}%";
      case ExportShaderValueFormat.pixels:
        return "${value.round()} px";
      case ExportShaderValueFormat.decimal:
        return value.toStringAsFixed(2);
      case ExportShaderValueFormat.degrees:
        return "${value.round()}°";
      case ExportShaderValueFormat.integer:
        return "${value.round()}";
    }
  }
}

/// A switch, written as 0 or 1.
final class ExportShaderToggleParameter extends ExportShaderParameter
{
  final bool initial;
  const ExportShaderToggleParameter({required super.uniform, required super.label, required this.initial, super.section});

  @override
  Object get initialValue => initial;

  @override
  void apply({required final FragmentShader shader, required final Object value})
  {
    shader.getUniformFloat(uniform).set((value as bool) ? 1.0 : 0.0);
  }
}

/// One of several named options, written as its index.
final class ExportShaderChoiceParameter extends ExportShaderParameter
{
  final List<String Function(AppLocalizations l10n)> options;
  final int initial;
  /// Written instead of the index, one per option, where the shader expects other numbers.
  final List<double>? values;
  const ExportShaderChoiceParameter({required super.uniform, required super.label, required this.options, required this.initial, this.values, super.section});

  @override
  Object get initialValue => initial;

  @override
  void apply({required final FragmentShader shader, required final Object value})
  {
    final int index = value as int;
    shader.getUniformFloat(uniform).set(values?[index] ?? index.toDouble());
  }
}

/// One algorithm of an [ExportShaderDefinition]; the shaders are in `shaders/` and listed in `pubspec.yaml`.
class ExportShaderVariant
{
  final String name;
  final String asset;
  final List<ExportShaderParameter> parameters;
  /// Below this export scaling the shader does not work or look as intended; null for no minimum.
  final int? minScalingFactor;

  const ExportShaderVariant({required this.name, required this.asset, this.parameters = const <ExportShaderParameter>[], this.minScalingFactor});
}

class ExportShaderDefinition
{
  final ExportShaderType type;
  final String Function(AppLocalizations l10n) name;
  final List<ExportShaderVariant> variants;

  const ExportShaderDefinition({required this.type, required this.name, required this.variants});
}

// CATEGORY STRINGS
String _lcdName(final AppLocalizations l10n) => l10n.shaderLcd;
String _smoothEdgesName(final AppLocalizations l10n) => l10n.shaderSmoothEdges;
String _ditheringName(final AppLocalizations l10n) => l10n.shaderDithering;
String _effectsName(final AppLocalizations l10n) => l10n.shaderEffects;
String _colorName(final AppLocalizations l10n) => l10n.color;
// LCD STRINGS
String _brightnessLabel(final AppLocalizations l10n) => l10n.brightness;
String _gridWidthLabel(final AppLocalizations l10n) => l10n.gridWidth;
String _gridColorLabel(final AppLocalizations l10n) => l10n.gridColor;
String _softnessLabel(final AppLocalizations l10n) => l10n.softness;
String _subpixelsLabel(final AppLocalizations l10n) => l10n.subpixels;
String _gridOnTransparencyLabel(final AppLocalizations l10n) => l10n.gridOnTransparency;
// SMOOTH EDGES STRINGS
String _colorToleranceLabel(final AppLocalizations l10n) => l10n.colorTolerance;
String _smoothnessLabel(final AppLocalizations l10n) => l10n.smoothness;
String _antiAliasingLabel(final AppLocalizations l10n) => l10n.antiAliasing;
String _lineWidthLabel(final AppLocalizations l10n) => l10n.lineWidth;
String _similarityThresholdLabel(final AppLocalizations l10n) => l10n.similarityThreshold;
// DITHERING STRINGS
String _colorDepthLabel(final AppLocalizations l10n) => l10n.colorDepth;
String _tuneDitheringLabel(final AppLocalizations l10n) => l10n.tuneDithering;
String _bayerLevelLabel(final AppLocalizations l10n) => l10n.bayerLevel;
String _bayer2Option(final AppLocalizations l10n) => "2×2";
String _bayer4Option(final AppLocalizations l10n) => "4×4";
String _bayer8Option(final AppLocalizations l10n) => "8×8";
String _bayer16Option(final AppLocalizations l10n) => "16×16";
String _checkerWidthLabel(final AppLocalizations l10n) => l10n.influence;
String _strengthLabel(final AppLocalizations l10n) => l10n.strength;
String _roundingLabel(final AppLocalizations l10n) => l10n.rounding;
String _fullRangeLabel(final AppLocalizations l10n) => l10n.fullRange;
//EFFECTS STRINGS
String _dotSizeLabel(final AppLocalizations l10n) => l10n.dotSize;
String _originalMixLabel(final AppLocalizations l10n) => l10n.originalMix;
String _dotGainLabel(final AppLocalizations l10n) => l10n.dotGain;
String _dotShapeLabel(final AppLocalizations l10n) => l10n.dotShape;
String _roundOption(final AppLocalizations l10n) => l10n.round;
String _diamondOption(final AppLocalizations l10n) => l10n.diamond;
String _squareOption(final AppLocalizations l10n) => l10n.square;
String _angleLabel(final AppLocalizations l10n) => l10n.angle;
String _misregistrationLabel(final AppLocalizations l10n) => l10n.misregistration;
String _backgroundBrightnessLabel(final AppLocalizations l10n) => l10n.backgroundBrightness;
String _backgroundWarmthLabel(final AppLocalizations l10n) => l10n.backgroundWarmth;
String _outerRadiusLabel(final AppLocalizations l10n) => l10n.outerRadius;
String _innerRadiusLabel(final AppLocalizations l10n) => l10n.innerRadius;
String _sharpnessLabel(final AppLocalizations l10n) => l10n.sharpness;
String _lightAngleLabel(final AppLocalizations l10n) => l10n.lightAngle;
String _depthLabel(final AppLocalizations l10n) => l10n.depth;
String _bevelWidthLabel(final AppLocalizations l10n) => l10n.bevelWidth;
String _heightFromBrightnessLabel(final AppLocalizations l10n) => l10n.heightFromBrightness;
String _colorLabel(final AppLocalizations l10n) => l10n.color;
String _outlineWidthLabel(final AppLocalizations l10n) => l10n.outlineWidth;
String _outlineStrengthLabel(final AppLocalizations l10n) => l10n.outlineStrength;
String _saturationLabel(final AppLocalizations l10n) => l10n.saturation;
//CRT STRINGS
String _crtName(final AppLocalizations l10n) => l10n.shaderCrt;
String _mediumSection(final AppLocalizations l10n) => l10n.medium;
String _signalSection(final AppLocalizations l10n) => l10n.signal;
String _colorEncodingSection(final AppLocalizations l10n) => l10n.colorEncoding;
String _tvSection(final AppLocalizations l10n) => l10n.tv;
String _mediumLabel(final AppLocalizations l10n) => l10n.medium;
String _wearLabel(final AppLocalizations l10n) => l10n.wear;
String _signalLabel(final AppLocalizations l10n) => l10n.signal;
String _artifactsLabel(final AppLocalizations l10n) => l10n.artifacts;
String _noiseLabel(final AppLocalizations l10n) => l10n.noise;
String _ghostingLabel(final AppLocalizations l10n) => l10n.ghosting;
String _encodingLabel(final AppLocalizations l10n) => l10n.encoding;
String _phaseErrorLabel(final AppLocalizations l10n) => l10n.phaseError;
String _convergenceLabel(final AppLocalizations l10n) => l10n.convergence;
String _scanlinesLabel(final AppLocalizations l10n) => l10n.scanlines;
String _maskLabel(final AppLocalizations l10n) => l10n.mask;
String _maskStrengthLabel(final AppLocalizations l10n) => l10n.maskStrength;
String _bloomLabel(final AppLocalizations l10n) => l10n.bloom;
String _curvatureLabel(final AppLocalizations l10n) => l10n.curvature;
String _vignetteLabel(final AppLocalizations l10n) => l10n.vignette;
String _noneOption(final AppLocalizations l10n) => l10n.none;
String _vhsOption(final AppLocalizations l10n) => "VHS";
String _betamaxOption(final AppLocalizations l10n) => "Betamax";
String _video8Option(final AppLocalizations l10n) => "Video8";
String _technicolorOption(final AppLocalizations l10n) => "Technicolor";
String _rgbOption(final AppLocalizations l10n) => "RGB";
String _sVideoOption(final AppLocalizations l10n) => "S-Video";
String _compositeOption(final AppLocalizations l10n) => "Composite";
String _rfOption(final AppLocalizations l10n) => "RF";
String _ntscOption(final AppLocalizations l10n) => "NTSC";
String _palOption(final AppLocalizations l10n) => "PAL";
String _secamOption(final AppLocalizations l10n) => "SECAM";
String _apertureGrilleOption(final AppLocalizations l10n) => l10n.apertureGrille;
String _slotMaskOption(final AppLocalizations l10n) => l10n.slotMask;
String _shadowMaskOption(final AppLocalizations l10n) => l10n.shadowMask;
// COLOR STRINGS
String _paletteLabel(final AppLocalizations l10n) => l10n.palette;
String _cgaOption(final AppLocalizations l10n) => "CGA";
String _egaOption(final AppLocalizations l10n) => "EGA";
String _pico8Option(final AppLocalizations l10n) => "PICO-8";
String _dmgOption(final AppLocalizations l10n) => "DMG";
String _c64Option(final AppLocalizations l10n) => "C64";
String _zxOption(final AppLocalizations l10n) => "ZX";
String _contrastLabel(final AppLocalizations l10n) => l10n.contrast;
String _whiteBalanceLabel(final AppLocalizations l10n) => l10n.whiteBalance;
String _tintLabel(final AppLocalizations l10n) => l10n.tint;

const Map<ExportShaderType, ExportShaderDefinition> exportShaderDefinitions = <ExportShaderType, ExportShaderDefinition>{
  ExportShaderType.crt: ExportShaderDefinition(
    type: ExportShaderType.crt,
    name: _crtName,
    variants: <ExportShaderVariant>[
      ExportShaderVariant(
        name: "CRT",
        asset: "shaders/crt.frag",
        minScalingFactor: 4,
        parameters: <ExportShaderParameter>[
          ExportShaderChoiceParameter(uniform: "uMedium", label: _mediumLabel, section: _mediumSection, options: <String Function(AppLocalizations)>[_noneOption, _vhsOption, _betamaxOption, _video8Option, _technicolorOption], initial: 1),
          ExportShaderSliderParameter(uniform: "uWear", label: _wearLabel, section: _mediumSection, min: 0.0, max: 1.0, initial: 0.5, format: ExportShaderValueFormat.percent),
          ExportShaderChoiceParameter(uniform: "uSignal", label: _signalLabel, section: _signalSection, options: <String Function(AppLocalizations)>[_rgbOption, _sVideoOption, _compositeOption, _rfOption], initial: 2),
          ExportShaderSliderParameter(uniform: "uArtifacts", label: _artifactsLabel, section: _signalSection, min: 0.0, max: 1.0, initial: 0.3, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uNoise", label: _noiseLabel, section: _signalSection, min: 0.0, max: 1.0, initial: 0.15, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uGhosting", label: _ghostingLabel, section: _signalSection, min: 0.0, max: 1.0, initial: 0.15, format: ExportShaderValueFormat.percent),
          ExportShaderChoiceParameter(uniform: "uEncoding", label: _encodingLabel, section: _colorEncodingSection, options: <String Function(AppLocalizations)>[_ntscOption, _palOption, _secamOption], initial: 0),
          ExportShaderSliderParameter(uniform: "uPhaseError", label: _phaseErrorLabel, section: _colorEncodingSection, min: -45.0, max: 45.0, initial: 0.0, divisions: 18, format: ExportShaderValueFormat.degrees),
          ExportShaderSliderParameter(uniform: "uSharpness", label: _sharpnessLabel, section: _tvSection, min: 0.0, max: 1.0, initial: 0.5, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uConvergence", label: _convergenceLabel, section: _tvSection, min: 0.0, max: 1.0, initial: 0.3, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uScanlines", label: _scanlinesLabel, section: _tvSection, min: 0.0, max: 1.0, initial: 0.6, format: ExportShaderValueFormat.percent),
          ExportShaderChoiceParameter(uniform: "uMask", label: _maskLabel, section: _tvSection, options: <String Function(AppLocalizations)>[_noneOption, _apertureGrilleOption, _slotMaskOption, _shadowMaskOption], initial: 1),
          ExportShaderSliderParameter(uniform: "uMaskStrength", label: _maskStrengthLabel, section: _tvSection, min: 0.0, max: 1.0, initial: 0.2, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uBloom", label: _bloomLabel, section: _tvSection, min: 0.0, max: 1.0, initial: 0.05, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uCurvature", label: _curvatureLabel, section: _tvSection, min: 0.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uVignette", label: _vignetteLabel, section: _tvSection, min: 0.0, max: 1.0, initial: 0.4, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uBrightness", label: _brightnessLabel, section: _tvSection, min: 0.5, max: 2.0, initial: 1.0, format: ExportShaderValueFormat.percent),
        ],
      ),
    ],
  ),
  ExportShaderType.lcd: ExportShaderDefinition(
    type: ExportShaderType.lcd,
    name: _lcdName,
    variants: <ExportShaderVariant>[
      ExportShaderVariant(
        name: "LCD",
        asset: "shaders/lcd.frag",
        minScalingFactor: 4,
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uBrightness", label: _brightnessLabel, min: 0.25, max: 3.0, initial: 1.25, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uGridWidth", label: _gridWidthLabel, min: 1.0, max: 6.0, initial: 1.0, divisions: 5, format: ExportShaderValueFormat.pixels),
          ExportShaderSliderParameter(uniform: "uGridGray", label: _gridColorLabel, min: 0.0, max: 1.0, initial: 0.3, format: ExportShaderValueFormat.percent, trackGradient: <Color>[Color(0xFF000000), Color(0xFFFFFFFF)]),
          ExportShaderSliderParameter(uniform: "uSoftness", label: _softnessLabel, min: 0.0, max: 1.0, initial: 0.3, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uSubpixels", label: _subpixelsLabel, min: 0.0, max: 1.0, initial: 0.1, format: ExportShaderValueFormat.percent),
          ExportShaderToggleParameter(uniform: "uGridOnTransparency", label: _gridOnTransparencyLabel, initial: false),
        ],
      ),
    ],
  ),
  ExportShaderType.upscale: ExportShaderDefinition(
    type: ExportShaderType.upscale,
    name: _smoothEdgesName,
    variants: <ExportShaderVariant>[
      ExportShaderVariant(
        name: "CleanEdge",
        asset: "shaders/upscale_clean_edge.frag",
        parameters: <ExportShaderParameter>[
          //the shader clamps the width to this range while 2:1 slopes are on
          ExportShaderSliderParameter(uniform: "uLineWidth", label: _lineWidthLabel, min: 0.44, max: 1.14, initial: 1.0, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uSimilarityThreshold", label: _similarityThresholdLabel, min: 0.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.decimal),
        ],
      ),
      ExportShaderVariant(
        name: "OmniScale",
        asset: "shaders/upscale_omniscale.frag",
        parameters: <ExportShaderParameter>[
          //0 = the thresholds of the original in SameBoy, 1 = the looser ones of the libretro port
          ExportShaderSliderParameter(uniform: "uTolerance", label: _colorToleranceLabel, min: 0.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.decimal),
        ],
      ),
      ExportShaderVariant(
        name: "xBR",
        asset: "shaders/upscale_xbr.frag",
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uEqThreshold", label: _colorToleranceLabel, min: 0.0, max: 1.0, initial: 0.32, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uCoefficient", label: _smoothnessLabel, min: 0.0, max: 1.0, initial: 0.3, format: ExportShaderValueFormat.decimal),
          ExportShaderToggleParameter(uniform: "uBlending", label: _antiAliasingLabel, initial: true),
        ],
      ),
      ExportShaderVariant(
        name: "xBRZ",
        asset: "shaders/upscale_xbrz.frag",
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uColorTolerance", label: _colorToleranceLabel, min: 0.0, max: 0.5, initial: 30.0 / 255.0, format: ExportShaderValueFormat.decimal),
        ],
      ),
    ],
  ),
  ExportShaderType.color: ExportShaderDefinition(
    type: ExportShaderType.color,
    name: _colorName,
    variants: <ExportShaderVariant>[
      ExportShaderVariant(
        name: "Color",
        asset: "shaders/color_adjust.frag",
        parameters: <ExportShaderParameter>[
          ExportShaderChoiceParameter(uniform: "uPalette", label: _paletteLabel, options: <String Function(AppLocalizations)>[_noneOption, _cgaOption, _egaOption, _pico8Option, _dmgOption, _c64Option, _zxOption], initial: 0),
          ExportShaderSliderParameter(uniform: "uColorDepth", label: _colorDepthLabel, min: 1.0, max: 8.0, divisions: 7, initial: 8.0, format: ExportShaderValueFormat.integer),
          ExportShaderSliderParameter(uniform: "uBrightness", label: _brightnessLabel, min: -1.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uContrast", label: _contrastLabel, min: 0.0, max: 2.0, initial: 1.0, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uSaturation", label: _saturationLabel, min: 0.0, max: 2.0, initial: 1.0, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uTemperature", label: _whiteBalanceLabel, min: -1.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uTint", label: _tintLabel, min: -1.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.decimal),
        ],
      ),
    ],
  ),
  ExportShaderType.dithering: ExportShaderDefinition(
    type: ExportShaderType.dithering,
    name: _ditheringName,
    variants: <ExportShaderVariant>[
      ExportShaderVariant(
        name: "Bayer",
        asset: "shaders/dither_bayer.frag",
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uColorDepth", label: _colorDepthLabel, min: 1.0, max: 8.0, divisions: 7, initial: 2.0, format: ExportShaderValueFormat.integer),
          ExportShaderChoiceParameter(uniform: "uBayerLevel", label: _bayerLevelLabel, options: <String Function(AppLocalizations)>[_bayer2Option, _bayer4Option, _bayer8Option, _bayer16Option], values: <double>[1.0, 2.0, 3.0, 4.0], initial: 1),
          ExportShaderSliderParameter(uniform: "uDitherTune", label: _tuneDitheringLabel, min: -64.0, max: 64.0, initial: 0.0, divisions: 128, format: ExportShaderValueFormat.decimal),
        ],
      ),
      ExportShaderVariant(
        name: "Checkerboard",
        asset: "shaders/dither_checkerboard.frag",
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uColorDepth", label: _colorDepthLabel, min: 1.0, max: 8.0, divisions: 7, initial: 2.0, format: ExportShaderValueFormat.integer),
          ExportShaderSliderParameter(uniform: "uCheckerWidth", label: _checkerWidthLabel, min: 0.0, max: 1.0, initial: 0.5, format: ExportShaderValueFormat.percent),
        ],
      ),
      ExportShaderVariant(
        name: "PSX",
        asset: "shaders/dither_psx.frag",
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uColorDepth", label: _colorDepthLabel, min: 1.0, max: 8.0, divisions: 7, initial: 5.0, format: ExportShaderValueFormat.integer),
          ExportShaderSliderParameter(uniform: "uDitherStrength", label: _strengthLabel, min: 0.0, max: 2.0, initial: 1.0, format: ExportShaderValueFormat.decimal),
          ExportShaderToggleParameter(uniform: "uRounding", label: _roundingLabel, initial: false),
          ExportShaderToggleParameter(uniform: "uFullRange", label: _fullRangeLabel, initial: true),
        ],
      ),
      ExportShaderVariant(
        name: "Noise",
        asset: "shaders/dither_noise.frag",
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uColorDepth", label: _colorDepthLabel, min: 1.0, max: 8.0, divisions: 7, initial: 2.0, format: ExportShaderValueFormat.integer),
          ExportShaderSliderParameter(uniform: "uDitherTune", label: _tuneDitheringLabel, min: -64.0, max: 64.0, initial: 0.0, divisions: 128, format: ExportShaderValueFormat.decimal),
        ],
      ),
      ExportShaderVariant(
        name: "Clustered Dot",
        asset: "shaders/dither_clustered_dot.frag",
        minScalingFactor: 4,
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uColorDepth", label: _colorDepthLabel, min: 1.0, max: 8.0, divisions: 7, initial: 2.0, format: ExportShaderValueFormat.integer),
        ],
      ),
    ],
  ),
  ExportShaderType.effects: ExportShaderDefinition(
    type: ExportShaderType.effects,
    name: _effectsName,
    variants: <ExportShaderVariant>[
      ExportShaderVariant(
        name: "CMYK/Halftone",
        asset: "shaders/effects_cmyk_halftone.frag",
        minScalingFactor: 6,
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uDotSize", label: _dotSizeLabel, min: 4.0, max: 32.0, initial: 8.0, divisions: 28, format: ExportShaderValueFormat.pixels),
          ExportShaderSliderParameter(uniform: "uOriginalMix", label: _originalMixLabel, min: 0.0, max: 1.0, initial: 0.3, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uDotGain", label: _dotGainLabel, min: 0.5, max: 2.0, initial: 1.0, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uSoftness", label: _softnessLabel, min: 0.0, max: 2.0, initial: 0.0, format: ExportShaderValueFormat.decimal),
          ExportShaderChoiceParameter(uniform: "uDotShape", label: _dotShapeLabel, options: <String Function(AppLocalizations)>[_roundOption, _diamondOption, _squareOption], initial: 0),
          ExportShaderSliderParameter(uniform: "uAngle", label: _angleLabel, min: 0.0, max: 90.0, initial: 0.0, format: ExportShaderValueFormat.degrees),
          ExportShaderSliderParameter(uniform: "uMisregistration", label: _misregistrationLabel, min: 0.0, max: 3.0, initial: 0.0, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uBackgroundBrightness", label: _backgroundBrightnessLabel, min: 0.0, max: 1.0, initial: 0.8, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uBackgroundWarmth", label: _backgroundWarmthLabel, min: -1.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.decimal),

        ],
      ),
      ExportShaderVariant(
        name: "Bead",
        asset: "shaders/effects_bead.frag",
        minScalingFactor: 6,
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uBeadHigh", label: _outerRadiusLabel, min: 0.0, max: 0.71, initial: 0.45, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uBeadLow", label: _innerRadiusLabel, min: 0.0, max: 0.71, initial: 0.25, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uBeadSharp", label: _sharpnessLabel, min: 1.0, max: 20.0, initial: 5.0, divisions: 19, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uBackgroundBrightness", label: _backgroundBrightnessLabel, min: 0.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uBackgroundWarmth", label: _backgroundWarmthLabel, min: -1.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.decimal),

        ],
      ),
      ExportShaderVariant(
        name: "Relief",
        asset: "shaders/effects_relief.frag",
        minScalingFactor: 4,
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uLightAngle", label: _lightAngleLabel, min: 0.0, max: 360.0, initial: 135.0, divisions: 24, format: ExportShaderValueFormat.degrees),
          ExportShaderSliderParameter(uniform: "uDepth", label: _depthLabel, min: 0.0, max: 16.0, initial: 8.0, divisions: 16, format: ExportShaderValueFormat.pixels),
          ExportShaderSliderParameter(uniform: "uBevelWidth", label: _bevelWidthLabel, min: 1.0, max: 8.0, initial: 2.0, divisions: 7, format: ExportShaderValueFormat.pixels),
          ExportShaderSliderParameter(uniform: "uBrightnessInfluence", label: _heightFromBrightnessLabel, min: 0.0, max: 1.0, initial: 1.0, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uStrength", label: _strengthLabel, min: 0.0, max: 2.0, initial: 1.0, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uColorAmount", label: _colorLabel, min: 0.0, max: 1.0, initial: 1.0, format: ExportShaderValueFormat.percent),
        ],
      ),
      ExportShaderVariant(
        name: "Cel Shading",
        asset: "shaders/effects_cel.frag",
        minScalingFactor: 4,
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uOutlineWidth", label: _outlineWidthLabel, min: 0.0, max: 4.0, initial: 1.0, divisions: 4, format: ExportShaderValueFormat.pixels),
          ExportShaderSliderParameter(uniform: "uOutlineStrength", label: _outlineStrengthLabel, min: 0.0, max: 1.0, initial: 1.0, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uThreshold", label: _similarityThresholdLabel, min: 0.0, max: 0.5, initial: 0.1, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uSaturation", label: _saturationLabel, min: 0.0, max: 2.0, initial: 1.25, format: ExportShaderValueFormat.percent),
        ],
      ),
    ],
  ),
};

/// The chosen variant and the parameter values of one export shader.
class ExportShaderValues extends ChangeNotifier
{
  final ExportShaderDefinition definition;
  final Map<ExportShaderParameter, Object> _values;
  int _variantIndex = 0;

  ExportShaderValues({required this.definition}) : _values = <ExportShaderParameter, Object>{
    for (final ExportShaderVariant variant in definition.variants)
      for (final ExportShaderParameter parameter in variant.parameters) parameter: parameter.initialValue,
  };

  ExportShaderValues.from({required final ExportShaderValues other}) : definition = other.definition, _values = Map<ExportShaderParameter, Object>.of(other._values), _variantIndex = other._variantIndex;

  int get variantIndex => _variantIndex;
  ExportShaderVariant get variant => definition.variants[_variantIndex];

  set variantIndex(final int index)
  {
    if (index != _variantIndex)
    {
      _variantIndex = index;
      notifyListeners();
    }
  }

  T valueOf<T extends Object>({required final ExportShaderParameter parameter})
  {
    return _values[parameter]! as T;
  }

  void setValue({required final ExportShaderParameter parameter, required final Object value})
  {
    if (_values[parameter] != value)
    {
      _values[parameter] = value;
      notifyListeners();
    }
  }

  bool isDefault({required final ExportShaderParameter parameter})
  {
    return _values[parameter] == parameter.initialValue;
  }

  /// Writes the parameters of the current [variant] to its last pass.
  void applyTo({required final FragmentShader shader})
  {
    for (final ExportShaderParameter parameter in variant.parameters)
    {
      parameter.apply(shader: shader, value: _values[parameter]!);
    }
  }
}
