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
  lcd,
  upscale,
  dithering,
}

/// How the value of an [ExportShaderSliderParameter] is shown.
enum ExportShaderValueFormat
{
  percent,
  pixels,
  decimal,
}

/// A value of an export shader the user can change.
///
/// [uniform] is the name of the float uniform in the shader the value is written to.
sealed class ExportShaderParameter
{
  final String uniform;
  final String Function(AppLocalizations l10n) label;
  const ExportShaderParameter({required this.uniform, required this.label});

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
    }
  }
}

/// A switch, written as 0 or 1.
final class ExportShaderToggleParameter extends ExportShaderParameter
{
  final bool initial;
  const ExportShaderToggleParameter({required super.uniform, required super.label, required this.initial});

  @override
  Object get initialValue => initial;

  @override
  void apply({required final FragmentShader shader, required final Object value})
  {
    shader.getUniformFloat(uniform).set((value as bool) ? 1.0 : 0.0);
  }
}

/// One algorithm of an [ExportShaderDefinition]; the shaders are in `shaders/` and listed in `pubspec.yaml`.
class ExportShaderVariant
{
  final String name;
  final String asset;
  final List<ExportShaderParameter> parameters;

  const ExportShaderVariant({required this.name, required this.asset, this.parameters = const <ExportShaderParameter>[]});
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
String _colorDepth(final AppLocalizations l10n) => l10n.colorDepth;
String _tuneDithering(final AppLocalizations l10n) => l10n.tuneDithering;
String _bayerLevel(final AppLocalizations l10n) => l10n.bayerLevel;
String _checkerWidth(final AppLocalizations l10n) => l10n.influence;

const Map<ExportShaderType, ExportShaderDefinition> exportShaderDefinitions = <ExportShaderType, ExportShaderDefinition>{
  ExportShaderType.lcd: ExportShaderDefinition(
    type: ExportShaderType.lcd,
    name: _lcdName,
    variants: <ExportShaderVariant>[
      ExportShaderVariant(
        name: "LCD",
        asset: "shaders/lcd.frag",
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uBrightness", label: _brightnessLabel, min: 0.25, max: 3.0, initial: 1.0, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uGridWidth", label: _gridWidthLabel, min: 1.0, max: 6.0, initial: 1.0, divisions: 5, format: ExportShaderValueFormat.pixels),
          ExportShaderSliderParameter(uniform: "uGridGray", label: _gridColorLabel, min: 0.0, max: 1.0, initial: 0.25, format: ExportShaderValueFormat.percent, trackGradient: <Color>[Color(0xFF000000), Color(0xFFFFFFFF)]),
          ExportShaderSliderParameter(uniform: "uSoftness", label: _softnessLabel, min: 0.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.percent),
          ExportShaderSliderParameter(uniform: "uSubpixels", label: _subpixelsLabel, min: 0.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.percent),
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
  ExportShaderType.dithering: ExportShaderDefinition(
    type: ExportShaderType.dithering,
    name: _ditheringName,
    variants: <ExportShaderVariant>[
      ExportShaderVariant(
        name: "Bayer",
        asset: "shaders/dither_bayer.frag",
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uColorDepth", label: _colorDepth, min: 1.0, max: 8.0, divisions: 7, initial: 2.0, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uBayerLevel", label: _bayerLevel, min: 1.0, max: 4.0, initial: 2.0, divisions: 3, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uDitherTune", label: _tuneDithering, min: -64.0, max: 64.0, initial: 0.0, divisions: 128, format: ExportShaderValueFormat.decimal),
        ],
      ),
      ExportShaderVariant(
        name: "Noise",
        asset: "shaders/dither_noise.frag",
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uColorDepth", label: _colorDepth, min: 1.0, max: 8.0, divisions: 7, initial: 2.0, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uDitherTune", label: _tuneDithering, min: -64.0, max: 64.0, initial: 0.0, divisions: 128, format: ExportShaderValueFormat.decimal),
        ],
      ),
      ExportShaderVariant(
        name: "Checkerboard",
        asset: "shaders/dither_checkerboard.frag",
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uColorDepth", label: _colorDepth, min: 1.0, max: 8.0, divisions: 7, initial: 2.0, format: ExportShaderValueFormat.decimal),
          ExportShaderSliderParameter(uniform: "uCheckerWidth", label: _checkerWidth, min: 0.0, max: 1.0, initial: 0.5, format: ExportShaderValueFormat.decimal),
        ],
      ),
      ExportShaderVariant(
        name: "Clustered Dot",
        asset: "shaders/dither_clustered_dot.frag",
        parameters: <ExportShaderParameter>[
          ExportShaderSliderParameter(uniform: "uColorDepth", label: _colorDepth, min: 1.0, max: 8.0, divisions: 7, initial: 2.0, format: ExportShaderValueFormat.decimal),
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
