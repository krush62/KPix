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

part of 'kpal_widget.dart';

class KPalRampData
{
  final KPalRampSettings settings;
  final String uuid;
  final List<ValueNotifier<IdColor>> colors = [];
  final List<ColorReference> references = [];

    KPalRampData({
    required this.uuid,
    required this.settings
  })
  {
    _updateColors(colorCountChanged: true);
  }

  factory KPalRampData.from({required KPalRampData other})
  {
    const Uuid uuid = Uuid();
    final KPalRampSettings newSettings = KPalRampSettings.from(other: other.settings);
    return KPalRampData(uuid: uuid.v1(), settings: newSettings);
  }

  void _updateColors({required bool colorCountChanged})
  {
    if (colorCountChanged)
    {
      const Uuid uuid = Uuid();
      colors.clear();
      references.clear();
      for (int i = 0; i < settings.colorCount; i++)
      {
        final IdColor color = IdColor(color: Colors.black, uuid: uuid.v1());
        colors.add(ValueNotifier(color));
        references.add(ColorReference(colorIndex: i, ramp: this));
      }
    }

    
    final int centerIndex = settings.colorCount ~/ 2;
    final bool isEven = settings.colorCount % 2 == 0;
    final double valueStepSize = ((settings.valueRangeMax - settings.valueRangeMin) / 100.0) / (settings.colorCount - 1);

    //setting central (center) color
    final HSVColor centerColor = HSVColor.fromAHSV(
        1.0,
        settings.baseHue.toDouble() % 360,
        (settings.baseSat.toDouble() / 100.0).clamp(0.0, 1.0),
        ((settings.valueRangeMin.toDouble() + ((settings.valueRangeMax.toDouble() - settings.valueRangeMin.toDouble()) / 2.0)) / 100.0).clamp(0.0, 1.0)
    );
    if (!isEven)
    {
      colors[centerIndex].value = IdColor(color: centerColor.toColor(), uuid: colors[centerIndex].value.uuid);
    }

    //setting brighter colors
    for (int i = isEven ? (settings.colorCount ~/ 2) : (settings.colorCount ~/ 2 + 1); i < settings.colorCount; i++)
    {
      final double distanceToCenter = isEven? (i - centerIndex).abs().toDouble() + 0.5 : (i - centerIndex).abs().toDouble();
      HSVColor col = HSVColor.fromAHSV(
          1.0,
          (centerColor.hue + (settings.hueShiftExp * settings.hueShift * pow(distanceToCenter, settings.hueShiftExp))) % 360,
          (centerColor.saturation + ((settings.satShift.toDouble() / 100.0) * settings.satShiftExp * pow(distanceToCenter, settings.satShiftExp))).clamp(0.0, 1.0),
          (centerColor.value + (valueStepSize * distanceToCenter)).clamp(0.0, 1.0)
      );
      if (settings.satCurve == SatCurve.brightFlat)
      {
        col = col.withSaturation(centerColor.saturation);
      }
      else if (settings.satCurve == SatCurve.linear)
      {
        col = col.withSaturation((centerColor.saturation - ((settings.satShift.toDouble() / 100.0) * settings.satShiftExp * pow(distanceToCenter, settings.satShiftExp))).clamp(0.0, 1.0));
      }
      colors[i].value = IdColor(color: col.toColor(), uuid: colors[i].value.uuid);
    }

    //setting darker colors
    for (int i = (settings.colorCount ~/ 2 - 1); i >= 0; i--)
    {
      final double distanceToCenter = isEven? (i - centerIndex).abs().toDouble() - 0.5 : (i - centerIndex).abs().toDouble();
      HSVColor col = HSVColor.fromAHSV(
          1.0,
          (centerColor.hue - (settings.hueShiftExp * settings.hueShift * pow(distanceToCenter, settings.hueShiftExp))) % 360,
          (centerColor.saturation + ((settings.satShift.toDouble() / 100.0) * settings.satShiftExp * pow(distanceToCenter, settings.satShiftExp))).clamp(0.0, 1.0),
          (centerColor.value - (valueStepSize * distanceToCenter)).clamp(0.0, 1.0)
      );
      if (settings.satCurve == SatCurve.darkFlat)
      {
        col = col.withSaturation(centerColor.saturation);
      }
      colors[i].value = IdColor(color: col.toColor(), uuid: colors[i].value.uuid);
    }
  }
}