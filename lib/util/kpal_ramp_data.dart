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

part of '../widgets/kpal/kpal_widget.dart';

class ShiftSet
{
  final ValueNotifier<int> hueShiftNotifier;
  final ValueNotifier<int> satShiftNotifier;
  final ValueNotifier<int> valShiftNotifier;
  ShiftSet({required this.hueShiftNotifier, required this.satShiftNotifier, required this.valShiftNotifier});
}


class KPalRampData
{
  final KPalRampSettings settings;
  final String uuid;
  final List<HSVColor> _originalColors = <HSVColor>[];
  final List<ValueNotifier<IdColor>> shiftedColors = <ValueNotifier<IdColor>>[];
  final List<ColorReference> references = <ColorReference>[];
  final List<ShiftSet> shifts = <ShiftSet>[];

  KPalRampData({
    required this.uuid,
    required this.settings,
    final List<HistoryShiftSet>? historyShifts,
  })
  {
    for (int i = 0; i < settings.constraints.colorCountMax; i++)
    {
      final KPalSliderConstraints shiftConstraints = GetIt.I.get<PreferenceManager>().kPalSliderConstraints;
      final ValueNotifier<int> hueNotifier = ValueNotifier<int>((historyShifts == null || i >= historyShifts.length) ? shiftConstraints.defaultHue : historyShifts[i].hueShift);
      final ValueNotifier<int> satNotifier = ValueNotifier<int>((historyShifts == null || i >= historyShifts.length) ? shiftConstraints.defaultSat : historyShifts[i].satShift);
      final ValueNotifier<int> valNotifier = ValueNotifier<int>((historyShifts == null || i >= historyShifts.length) ? shiftConstraints.defaultVal : historyShifts[i].valShift);
      final ShiftSet shiftSet = ShiftSet(hueShiftNotifier: hueNotifier, satShiftNotifier: satNotifier, valShiftNotifier: valNotifier);
      shiftSet.hueShiftNotifier.addListener(_shiftChanged);
      shiftSet.satShiftNotifier.addListener(_shiftChanged);
      shiftSet.valShiftNotifier.addListener(_shiftChanged);
      shifts.add(shiftSet);
    }
    _updateColors(colorCountChanged: true, resetListeners: historyShifts == null);
  }

  factory KPalRampData.from({required final KPalRampData other})
  {
    const Uuid uuid = Uuid();
    final KPalRampSettings newSettings = KPalRampSettings.from(other: other.settings);
    final List<HistoryShiftSet> shifts = <HistoryShiftSet>[];
    for (final ShiftSet shiftSet in other.shifts)
    {
       shifts.add(HistoryShiftSet(hueShift: shiftSet.hueShiftNotifier.value, satShift: shiftSet.satShiftNotifier.value, valShift: shiftSet.valShiftNotifier.value));
    }
    return KPalRampData(uuid: uuid.v1(), settings: newSettings, historyShifts: shifts);
  }

  void updateFromOther({required final KPalRampData other})
  {
    final bool colorChange = (settings.colorCount != other.settings.colorCount);
    //SETTINGS
    settings.satShift = other.settings.satShift;
    settings.hueShift = other.settings.hueShift;
    settings.colorCount = other.settings.colorCount;
    settings.valueRangeMax = other.settings.valueRangeMax;
    settings.valueRangeMin = other.settings.valueRangeMin;
    settings.baseSat = other.settings.baseSat;
    settings.baseHue = other.settings.baseHue;
    settings.satCurve = other.settings.satCurve;
    settings.satShiftExp = other.settings.satShiftExp;
    settings.hueShiftExp = other.settings.hueShiftExp;

    //SHIFTS
    for (int i = 0; i < settings.colorCount; i++)
    {
      shifts[i].hueShiftNotifier.removeListener(_shiftChanged);
      shifts[i].hueShiftNotifier.value = other.shifts[i].hueShiftNotifier.value;
      shifts[i].hueShiftNotifier.addListener(_shiftChanged);

      shifts[i].satShiftNotifier.removeListener(_shiftChanged);
      shifts[i].satShiftNotifier.value = other.shifts[i].satShiftNotifier.value;
      shifts[i].satShiftNotifier.addListener(_shiftChanged);

      shifts[i].valShiftNotifier.removeListener(_shiftChanged);
      shifts[i].valShiftNotifier.value = other.shifts[i].valShiftNotifier.value;
      shifts[i].valShiftNotifier.addListener(_shiftChanged);
    }


    _updateColors(colorCountChanged: colorChange);

  }

  static List<KPalRampData> getDefaultPalette({required final KPalConstraints constraints})
  {
    final List<KPalRampData> rampList = <KPalRampData>[];

    final KPalRampSettings red = KPalRampSettings(constraints: constraints);
    red.colorCount = 7;
    red.baseHue = 0;
    red.baseSat = 75;
    red.hueShift = 6;
    red.hueShiftExp = 1.17;
    red.satShift = -12;
    red.satShiftExp = 0.84;
    red.satCurve = SatCurve.noFlat;
    red.valueRangeMin = 21;
    red.valueRangeMax = 100;
    final List<HistoryShiftSet> redShifts = <HistoryShiftSet>[];
    redShifts.add(HistoryShiftSet(hueShift: -19, satShift: -10, valShift: -1));
    redShifts.add(HistoryShiftSet(hueShift: -2, satShift: -1, valShift: -1));
    redShifts.add(HistoryShiftSet(hueShift: 0, satShift: -7, valShift: 0));
    redShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    redShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: -2));
    redShifts.add(HistoryShiftSet(hueShift: -2, satShift: 6, valShift: -4));
    redShifts.add(HistoryShiftSet(hueShift: -6, satShift: 4, valShift: -9));

    final KPalRampSettings green = KPalRampSettings(constraints: constraints);
    green.colorCount = 7;
    green.baseHue = 137;
    green.baseSat = 70;
    green.hueShift = -6;
    green.hueShiftExp = 1.17;
    green.satShift = -12;
    green.satShiftExp = 0.84;
    green.satCurve = SatCurve.noFlat;
    green.valueRangeMin = 15;
    green.valueRangeMax = 95;
    final List<HistoryShiftSet> greenShifts = <HistoryShiftSet>[];
    greenShifts.add(HistoryShiftSet(hueShift: -1, satShift: 2, valShift: 3));
    greenShifts.add(HistoryShiftSet(hueShift: 5, satShift: 5, valShift: 0));
    greenShifts.add(HistoryShiftSet(hueShift: 6, satShift: -2, valShift: -2));
    greenShifts.add(HistoryShiftSet(hueShift: 3, satShift: 0, valShift: -6));
    greenShifts.add(HistoryShiftSet(hueShift: 2, satShift: -8, valShift: -7));
    greenShifts.add(HistoryShiftSet(hueShift: 7, satShift: -2, valShift: -7));
    greenShifts.add(HistoryShiftSet(hueShift: -3, satShift: -6, valShift: -9));

    final KPalRampSettings blue = KPalRampSettings(constraints: constraints);
    blue.colorCount = 7;
    blue.baseHue = 219;
    blue.baseSat = 75;
    blue.hueShift = -6;
    blue.hueShiftExp = 1.16;
    blue.satShift = -12;
    blue.satShiftExp = 0.84;
    blue.satCurve = SatCurve.noFlat;
    blue.valueRangeMin = 25;
    blue.valueRangeMax = 95;
    final List<HistoryShiftSet> blueShifts = <HistoryShiftSet>[];
    blueShifts.add(HistoryShiftSet(hueShift: -9, satShift: -7, valShift: 0));
    blueShifts.add(HistoryShiftSet(hueShift: 3, satShift: 1, valShift: 0));
    blueShifts.add(HistoryShiftSet(hueShift: -1, satShift: -2, valShift: 2));
    blueShifts.add(HistoryShiftSet(hueShift: -3, satShift: -5, valShift: 5));
    blueShifts.add(HistoryShiftSet(hueShift: -2, satShift: -2, valShift: 0));
    blueShifts.add(HistoryShiftSet(hueShift: 1, satShift: 2, valShift: -4));
    blueShifts.add(HistoryShiftSet(hueShift: 8, satShift: 4, valShift: -5));

    final KPalRampSettings yellow = KPalRampSettings(constraints: constraints);
    yellow.colorCount = 7;
    yellow.baseHue = 61;
    yellow.baseSat = 75;
    yellow.hueShift = 7;
    yellow.hueShiftExp = 1.16;
    yellow.satShift = -12;
    yellow.satShiftExp = 0.84;
    yellow.satCurve = SatCurve.noFlat;
    yellow.valueRangeMin = 13;
    yellow.valueRangeMax = 90;
    final List<HistoryShiftSet> yellowShifts = <HistoryShiftSet>[];
    yellowShifts.add(HistoryShiftSet(hueShift: 15, satShift: 1, valShift: 5));
    yellowShifts.add(HistoryShiftSet(hueShift: 7, satShift: 1, valShift: 2));
    yellowShifts.add(HistoryShiftSet(hueShift: 0, satShift: -3, valShift: -1));
    yellowShifts.add(HistoryShiftSet(hueShift: -3, satShift: -2, valShift: -5));
    yellowShifts.add(HistoryShiftSet(hueShift: -7, satShift: -3, valShift: -7));
    yellowShifts.add(HistoryShiftSet(hueShift: -7, satShift: -4, valShift: -7));
    yellowShifts.add(HistoryShiftSet(hueShift: -12, satShift: -8, valShift: -7));

    final KPalRampSettings purple = KPalRampSettings(constraints: constraints);
    purple.colorCount = 7;
    purple.baseHue = 287;
    purple.baseSat = 75;
    purple.hueShift = 6;
    purple.hueShiftExp = 1.16;
    purple.satShift = -12;
    purple.satShiftExp = 0.83;
    purple.satCurve = SatCurve.noFlat;
    purple.valueRangeMin = 18;
    purple.valueRangeMax = 100;
    final List<HistoryShiftSet> purpleShifts = <HistoryShiftSet>[];
    purpleShifts.add(HistoryShiftSet(hueShift: -14, satShift: -8, valShift: 5));
    purpleShifts.add(HistoryShiftSet(hueShift: 3, satShift: -3, valShift: 1));
    purpleShifts.add(HistoryShiftSet(hueShift: 3, satShift: -2, valShift: 2));
    purpleShifts.add(HistoryShiftSet(hueShift: 0, satShift: -2, valShift: 6));
    purpleShifts.add(HistoryShiftSet(hueShift: 3, satShift: -1, valShift: 1));
    purpleShifts.add(HistoryShiftSet(hueShift: -1, satShift: -1, valShift: 0));
    purpleShifts.add(HistoryShiftSet(hueShift: 0, satShift: -2, valShift: 0));

    final KPalRampSettings brown = KPalRampSettings(constraints: constraints);
    brown.colorCount = 7;
    brown.baseHue = 20;
    brown.baseSat = 40;
    brown.hueShift = 6;
    brown.hueShiftExp = 1.19;
    brown.satShift = -12;
    brown.satShiftExp = 0.83;
    brown.satCurve = SatCurve.noFlat;
    brown.valueRangeMin = 20;
    brown.valueRangeMax = 90;
    final List<HistoryShiftSet> brownShifts = <HistoryShiftSet>[];
    brownShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    brownShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    brownShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 1));
    brownShifts.add(HistoryShiftSet(hueShift: 0, satShift: -2, valShift: 2));
    brownShifts.add(HistoryShiftSet(hueShift: -2, satShift: 1, valShift: 0));
    brownShifts.add(HistoryShiftSet(hueShift: -4, satShift: 3, valShift: -2));
    brownShifts.add(HistoryShiftSet(hueShift: -5, satShift: 2, valShift: -5));

    final KPalRampSettings grey = KPalRampSettings(constraints: constraints);
    grey.colorCount = 7;
    grey.baseHue = 333;
    grey.baseSat = 8;
    grey.hueShift = -6;
    grey.hueShiftExp = 1.19;
    grey.satShift = -6;
    grey.satShiftExp = 0.5;
    grey.satCurve = SatCurve.noFlat;
    grey.valueRangeMin = 15;
    grey.valueRangeMax = 90;
    final List<HistoryShiftSet> greyShifts = <HistoryShiftSet>[];
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 2));
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 1));
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: -1));
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: -1));
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: -1));



    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: red, historyShifts: redShifts));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: green, historyShifts: greenShifts));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: blue, historyShifts: blueShifts));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: yellow, historyShifts: yellowShifts));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: purple, historyShifts: purpleShifts));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: brown, historyShifts: brownShifts));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: grey, historyShifts: greyShifts));


    return rampList;
  }

  void _shiftChanged()
  {
    _updateColors(colorCountChanged: false);
  }

  void _updateColors({required final bool colorCountChanged, final bool resetListeners = true})
  {
    if (colorCountChanged)
    {
      final KPalSliderConstraints shiftConstraints = GetIt.I.get<PreferenceManager>().kPalSliderConstraints;
      const Uuid uuid = Uuid();
      _originalColors.clear();
      shiftedColors.clear();
      references.clear();
      for (final ShiftSet shiftSet in shifts)
      {
        shiftSet.hueShiftNotifier.removeListener(_shiftChanged);
        shiftSet.satShiftNotifier.removeListener(_shiftChanged);
        shiftSet.valShiftNotifier.removeListener(_shiftChanged);
        if (resetListeners)
        {
          shiftSet.hueShiftNotifier.value = shiftConstraints.defaultHue;
          shiftSet.satShiftNotifier.value = shiftConstraints.defaultSat;
          shiftSet.valShiftNotifier.value = shiftConstraints.defaultVal;
        }
        shiftSet.hueShiftNotifier.addListener(_shiftChanged);
        shiftSet.satShiftNotifier.addListener(_shiftChanged);
        shiftSet.valShiftNotifier.addListener(_shiftChanged);

      }
      for (int i = 0; i < settings.colorCount; i++)
      {
        const Color black = Colors.black;
        _originalColors.add(HSVColor.fromColor(black));
        shiftedColors.add(ValueNotifier<IdColor>(IdColor(hsvColor: HSVColor.fromColor(black), uuid: uuid.v1())));
        references.add(ColorReference(colorIndex: i, ramp: this));
      }
    }

    
    final int centerIndex = settings.colorCount ~/ 2;
    final bool isEven = settings.colorCount.isEven;
    final double valueStepSize = ((settings.valueRangeMax - settings.valueRangeMin) / 100.0) / (settings.colorCount - 1);

    //setting central (center) color
    final HSVColor centerColor = HSVColor.fromAHSV(
        1.0,
        settings.baseHue.toDouble() % 360,
        (settings.baseSat.toDouble() / 100.0).clamp(0.0, 1.0),
        ((settings.valueRangeMin.toDouble() + ((settings.valueRangeMax.toDouble() - settings.valueRangeMin.toDouble()) / 2.0)) / 100.0).clamp(0.0, 1.0),
    );
    if (!isEven)
    {
      _originalColors[centerIndex] = centerColor;
    }

    //setting brighter colors
    for (int i = isEven ? (settings.colorCount ~/ 2) : (settings.colorCount ~/ 2 + 1); i < settings.colorCount; i++)
    {
      final double distanceToCenter = isEven? (i - centerIndex).abs().toDouble() + 0.5 : (i - centerIndex).abs().toDouble();
      HSVColor col = HSVColor.fromAHSV(
          1.0,
          (centerColor.hue + (settings.hueShiftExp * settings.hueShift * pow(distanceToCenter, settings.hueShiftExp))) % 360,
          (centerColor.saturation + ((settings.satShift.toDouble() / 100.0) * settings.satShiftExp * pow(distanceToCenter, settings.satShiftExp))).clamp(0.0, 1.0),
          (centerColor.value + (valueStepSize * distanceToCenter)).clamp(0.0, 1.0),
      );
      if (settings.satCurve == SatCurve.brightFlat)
      {
        col = col.withSaturation(centerColor.saturation);
      }
      else if (settings.satCurve == SatCurve.linear)
      {
        col = col.withSaturation((centerColor.saturation - ((settings.satShift.toDouble() / 100.0) * settings.satShiftExp * pow(distanceToCenter, settings.satShiftExp))).clamp(0.0, 1.0));
      }
      _originalColors[i] = col;
    }

    //setting darker colors
    for (int i = settings.colorCount ~/ 2 - 1; i >= 0; i--)
    {
      final double distanceToCenter = isEven? (i - centerIndex).abs().toDouble() - 0.5 : (i - centerIndex).abs().toDouble();
      HSVColor col = HSVColor.fromAHSV(
          1.0,
          (centerColor.hue - (settings.hueShiftExp * settings.hueShift * pow(distanceToCenter, settings.hueShiftExp))) % 360,
          (centerColor.saturation + ((settings.satShift.toDouble() / 100.0) * settings.satShiftExp * pow(distanceToCenter, settings.satShiftExp))).clamp(0.0, 1.0),
          (centerColor.value - (valueStepSize * distanceToCenter)).clamp(0.0, 1.0),
      );
      if (settings.satCurve == SatCurve.darkFlat)
      {
        col = col.withSaturation(centerColor.saturation);
      }
      _originalColors[i] = col;
    }

    //SETTING SHIFTED COLORS
    for (int i = 0; i < _originalColors.length; i++)
    {
      final HSVColor orig = _originalColors[i];
      final HSVColor shiftedColor = HSVColor.fromAHSV(
          1.0,
          (orig.hue + shifts[i].hueShiftNotifier.value) % 360,
          (orig.saturation + (shifts[i].satShiftNotifier.value.toDouble() / 100.0)).clamp(0.0, 1.0),
          (orig.value + (shifts[i].valShiftNotifier.value.toDouble() / 100.0)).clamp(0.0, 1.0),
      );
      shiftedColors[i].value = IdColor(hsvColor: shiftedColor, uuid: shiftedColors[i].value.uuid);
    }
  }
}
