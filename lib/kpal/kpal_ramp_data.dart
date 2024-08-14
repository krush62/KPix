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

  static List<KPalRampData> getDefaultPalette({required final KPalConstraints constraints})
  {
    final List<KPalRampData> rampList = [];

    final KPalRampSettings blue = KPalRampSettings(constraints: constraints);
    blue.colorCount = 7;
    blue.baseHue = 209;
    blue.baseSat = 57;
    blue.hueShift = -17;
    blue.hueShiftExp = 1.0;
    blue.satShift = -3;
    blue.satShiftExp = 1.67;
    blue.satCurve = SatCurve.darkFlat;
    blue.valueRangeMin = 15;
    blue.valueRangeMax = 95;

    final KPalRampSettings green = KPalRampSettings(constraints: constraints);
    green.colorCount = 7;
    green.baseHue = 99;
    green.baseSat = 62;
    green.hueShift = -17;
    green.hueShiftExp = 1.0;
    green.satShift = -3;
    green.satShiftExp = 1.71;
    green.satCurve = SatCurve.darkFlat;
    green.valueRangeMin = 15;
    green.valueRangeMax = 83;

    final KPalRampSettings brown = KPalRampSettings(constraints: constraints);
    brown.colorCount = 7;
    brown.baseHue = 23;
    brown.baseSat = 40;
    brown.hueShift = 17;
    brown.hueShiftExp = 1.0;
    brown.satShift = -3;
    brown.satShiftExp = 1.68;
    brown.satCurve = SatCurve.darkFlat;
    brown.valueRangeMin = 15;
    brown.valueRangeMax = 90;

    final KPalRampSettings gold = KPalRampSettings(constraints: constraints);
    gold.colorCount = 7;
    gold.baseHue = 42;
    gold.baseSat = 72;
    gold.hueShift = 17;
    gold.hueShiftExp = 1.0;
    gold.satShift = -3;
    gold.satShiftExp = 1.75;
    gold.satCurve = SatCurve.noFlat;
    gold.valueRangeMin = 16;
    gold.valueRangeMax = 95;

    final KPalRampSettings red = KPalRampSettings(constraints: constraints);
    red.colorCount = 7;
    red.baseHue = 317;
    red.baseSat = 66;
    red.hueShift = 12;
    red.hueShiftExp = 1.45;
    red.satShift = -10;
    red.satShiftExp = 1.0;
    red.satCurve = SatCurve.darkFlat;
    red.valueRangeMin = 15;
    red.valueRangeMax = 95;

    final KPalRampSettings purple = KPalRampSettings(constraints: constraints);
    purple.colorCount = 7;
    purple.baseHue = 276;
    purple.baseSat = 47;
    purple.hueShift = 17;
    purple.hueShiftExp = 1.26;
    purple.satShift = -3;
    purple.satShiftExp = 1.65;
    purple.satCurve = SatCurve.darkFlat;
    purple.valueRangeMin = 15;
    purple.valueRangeMax = 95;

    final KPalRampSettings grey = KPalRampSettings(constraints: constraints);
    grey.colorCount = 7;
    grey.baseHue = 191;
    grey.baseSat = 31;
    grey.hueShift = -10;
    grey.hueShiftExp = 1.57;
    grey.satShift = -10;
    grey.satShiftExp = 1.16;
    grey.satCurve = SatCurve.darkFlat;
    grey.valueRangeMin = 8;
    grey.valueRangeMax = 95;

    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: blue));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: green));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: brown));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: gold));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: red));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: purple));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: grey));

    return rampList;
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