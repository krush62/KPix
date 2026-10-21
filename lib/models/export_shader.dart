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
}

/// How the value of an [ExportShaderSliderParameter] is shown.
enum ExportShaderValueFormat
{
  percent,
  pixels,
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

/// A shader bundled with the app, see `shaders/` and the `shaders:` section of `pubspec.yaml`.
class ExportShaderDefinition
{
  final ExportShaderType type;
  final String asset;
  final String Function(AppLocalizations l10n) name;
  final List<ExportShaderParameter> parameters;

  const ExportShaderDefinition({required this.type, required this.asset, required this.name, required this.parameters});
}

String _lcdName(final AppLocalizations l10n) => l10n.shaderLcd;
String _brightnessLabel(final AppLocalizations l10n) => l10n.brightness;
String _gridWidthLabel(final AppLocalizations l10n) => l10n.gridWidth;
String _gridColorLabel(final AppLocalizations l10n) => l10n.gridColor;
String _softnessLabel(final AppLocalizations l10n) => l10n.softness;
String _subpixelsLabel(final AppLocalizations l10n) => l10n.subpixels;
String _gridOnTransparencyLabel(final AppLocalizations l10n) => l10n.gridOnTransparency;

const Map<ExportShaderType, ExportShaderDefinition> exportShaderDefinitions = <ExportShaderType, ExportShaderDefinition>{
  ExportShaderType.lcd: ExportShaderDefinition(
    type: ExportShaderType.lcd,
    asset: "shaders/lcd.frag",
    name: _lcdName,
    parameters: <ExportShaderParameter>[
      ExportShaderSliderParameter(uniform: "uBrightness", label: _brightnessLabel, min: 0.25, max: 3.0, initial: 1.0, format: ExportShaderValueFormat.percent),
      ExportShaderSliderParameter(uniform: "uGridWidth", label: _gridWidthLabel, min: 1.0, max: 6.0, initial: 1.0, divisions: 5, format: ExportShaderValueFormat.pixels),
      ExportShaderSliderParameter(uniform: "uGridGray", label: _gridColorLabel, min: 0.0, max: 1.0, initial: 0.25, format: ExportShaderValueFormat.percent, trackGradient: <Color>[Color(0xFF000000), Color(0xFFFFFFFF)]),
      ExportShaderSliderParameter(uniform: "uSoftness", label: _softnessLabel, min: 0.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.percent),
      ExportShaderSliderParameter(uniform: "uSubpixels", label: _subpixelsLabel, min: 0.0, max: 1.0, initial: 0.0, format: ExportShaderValueFormat.percent),
      ExportShaderToggleParameter(uniform: "uGridOnTransparency", label: _gridOnTransparencyLabel, initial: false),
    ],
  ),
};

/// The current parameter values of one export shader.
class ExportShaderValues extends ChangeNotifier
{
  final ExportShaderDefinition definition;
  final Map<ExportShaderParameter, Object> _values;

  ExportShaderValues({required this.definition}) : _values = <ExportShaderParameter, Object>{
    for (final ExportShaderParameter parameter in definition.parameters) parameter: parameter.initialValue,
  };

  ExportShaderValues.from({required final ExportShaderValues other}) : definition = other.definition, _values = Map<ExportShaderParameter, Object>.of(other._values);

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

  void applyTo({required final FragmentShader shader})
  {
    for (final MapEntry<ExportShaderParameter, Object> entry in _values.entries)
    {
      entry.key.apply(shader: shader, value: entry.value);
    }
  }
}
