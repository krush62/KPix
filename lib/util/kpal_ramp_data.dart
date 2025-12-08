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
  final List<KHSV> _originalColors = <KHSV>[];
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
    red.colorCount = 6;
    red.baseHue = 357;
    red.baseSat = 79;
    red.hueShift = 9;
    red.hueShiftExp = 0.91;
    red.satShift = -5;
    red.satShiftExp = 1.00;
    red.satCurve = SatCurve.darkFlat;
    red.valueRangeMin = 26;
    red.valueRangeMax = 97;
    final List<HistoryShiftSet> redShifts = <HistoryShiftSet>[];
    redShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 3));
    redShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    redShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    redShifts.add(HistoryShiftSet(hueShift: 0, satShift: -5, valShift: 1));
    redShifts.add(HistoryShiftSet(hueShift: -2, satShift: -2, valShift: 1));
    redShifts.add(HistoryShiftSet(hueShift: -4, satShift: 1, valShift: 1));

    final KPalRampSettings yellow = KPalRampSettings(constraints: constraints);
    yellow.colorCount = 5;
    yellow.baseHue = 35;
    yellow.baseSat = 75;
    yellow.hueShift = 5;
    yellow.hueShiftExp = 0.90;
    yellow.satShift = -10;
    yellow.satShiftExp = 0.89;
    yellow.satCurve = SatCurve.darkFlat;
    yellow.valueRangeMin = 43;
    yellow.valueRangeMax = 93;
    final List<HistoryShiftSet> yellowShifts = <HistoryShiftSet>[];
    yellowShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    yellowShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    yellowShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    yellowShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    yellowShifts.add(HistoryShiftSet(hueShift: 0, satShift: -2, valShift: -3));

    final KPalRampSettings green = KPalRampSettings(constraints: constraints);
    green.colorCount = 6;
    green.baseHue = 119;
    green.baseSat = 58;
    green.hueShift = -20;
    green.hueShiftExp = 0.9;
    green.satShift = -17;
    green.satShiftExp = 0.93;
    green.satCurve = SatCurve.darkFlat;
    green.valueRangeMin = 22;
    green.valueRangeMax = 91;
    final List<HistoryShiftSet> greenShifts = <HistoryShiftSet>[];
    greenShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    greenShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    greenShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    greenShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 3));
    greenShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    greenShifts.add(HistoryShiftSet(hueShift: 3, satShift: 4, valShift: -4));

    final KPalRampSettings blue = KPalRampSettings(constraints: constraints);
    blue.colorCount = 5;
    blue.baseHue = 238;
    blue.baseSat = 33;
    blue.hueShift = -11;
    blue.hueShiftExp = 0.91;
    blue.satShift = -11;
    blue.satShiftExp = 1.05;
    blue.satCurve = SatCurve.darkFlat;
    blue.valueRangeMin = 29;
    blue.valueRangeMax = 95;
    final List<HistoryShiftSet> blueShifts = <HistoryShiftSet>[];
    blueShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 3));
    blueShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    blueShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 6));
    blueShifts.add(HistoryShiftSet(hueShift: 0, satShift: 4, valShift: 0));
    blueShifts.add(HistoryShiftSet(hueShift: 0, satShift: 2, valShift: -7));

    final KPalRampSettings purple = KPalRampSettings(constraints: constraints);
    purple.colorCount = 5;
    purple.baseHue = 338;
    purple.baseSat = 63;
    purple.hueShift = 4;
    purple.hueShiftExp = 0.88;
    purple.satShift = -16;
    purple.satShiftExp = 1.08;
    purple.satCurve = SatCurve.darkFlat;
    purple.valueRangeMin = 30;
    purple.valueRangeMax = 95;
    final List<HistoryShiftSet> purpleShifts = <HistoryShiftSet>[];
    purpleShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 3));
    purpleShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    purpleShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    purpleShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    purpleShifts.add(HistoryShiftSet(hueShift: 0, satShift: 6, valShift: -4));

    final KPalRampSettings brown = KPalRampSettings(constraints: constraints);
    brown.colorCount = 7;
    brown.baseHue = 10;
    brown.baseSat = 46;
    brown.hueShift = -2;
    brown.hueShiftExp = 0.88;
    brown.satShift = -11;
    brown.satShiftExp = 0.84;
    brown.satCurve = SatCurve.darkFlat;
    brown.valueRangeMin = 19;
    brown.valueRangeMax = 88;
    final List<HistoryShiftSet> brownShifts = <HistoryShiftSet>[];
    brownShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 3));
    brownShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 1));
    brownShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    brownShifts.add(HistoryShiftSet(hueShift: 0, satShift: -5, valShift: 2));
    brownShifts.add(HistoryShiftSet(hueShift: 0, satShift: -3, valShift: 0));
    brownShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    brownShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: -2));



    final KPalRampSettings grey = KPalRampSettings(constraints: constraints);
    grey.colorCount = 7;
    grey.baseHue = 191;
    grey.baseSat = 10;
    grey.hueShift = -14;
    grey.hueShiftExp = 0.85;
    grey.satShift = -2;
    grey.satShiftExp = 0.92;
    grey.satCurve = SatCurve.darkFlat;
    grey.valueRangeMin = 9;
    grey.valueRangeMax = 95;
    final List<HistoryShiftSet> greyShifts = <HistoryShiftSet>[];
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 4));
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: -3));
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: -4));
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: -5));
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: -3));
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));
    greyShifts.add(HistoryShiftSet(hueShift: 0, satShift: 0, valShift: 0));


    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: purple, historyShifts: purpleShifts));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: red, historyShifts: redShifts));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: brown, historyShifts: brownShifts));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: yellow, historyShifts: yellowShifts));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: green, historyShifts: greenShifts));
    rampList.add(KPalRampData(uuid: const Uuid().v1(), settings: blue, historyShifts: blueShifts));
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
        _originalColors.add(KHSV.fromColor(color:black));
        shiftedColors.add(ValueNotifier<IdColor>(IdColor(hsv: KHSV.fromColor(color: black), uuid: uuid.v1())));
        references.add(ColorReference(colorIndex: i, ramp: this));
      }
    }

    
    final int centerIndex = settings.colorCount ~/ 2;
    final bool isEven = settings.colorCount.isEven;
    final double valueStepSize = ((settings.valueRangeMax - settings.valueRangeMin) / 100.0) / (settings.colorCount - 1);

    //setting central (center) color
    final KHSV centerColor = KHSV(h: settings.baseHue.toDouble() % 360,
        s: (settings.baseSat.toDouble() / 100.0).clamp(0.0, 1.0),
        v: ((settings.valueRangeMin.toDouble() + ((settings.valueRangeMax.toDouble() - settings.valueRangeMin.toDouble()) / 2.0)) / 100.0).clamp(0.0, 1.0),
    );
    if (!isEven)
    {
      _originalColors[centerIndex] = centerColor;
    }

    //setting brighter colors
    for (int i = isEven ? (settings.colorCount ~/ 2) : (settings.colorCount ~/ 2 + 1); i < settings.colorCount; i++)
    {
      final double distanceToCenter = isEven? (i - centerIndex).abs().toDouble() + 0.5 : (i - centerIndex).abs().toDouble();
      KHSV col = KHSV(
          h: (centerColor.h + (settings.hueShiftExp * settings.hueShift * pow(distanceToCenter, settings.hueShiftExp))) % 360,
          s: (centerColor.s + ((settings.satShift.toDouble() / 100.0) * settings.satShiftExp * pow(distanceToCenter, settings.satShiftExp))).clamp(0.0, 1.0),
          v: (centerColor.v + (valueStepSize * distanceToCenter)).clamp(0.0, 1.0),
      );
      if (settings.satCurve == SatCurve.brightFlat)
      {
        col = KHSV(h: col.h, v: col.v, s: centerColor.s);
      }
      else if (settings.satCurve == SatCurve.linear)
      {
        col = KHSV(h: col.h, v: col.v, s: (centerColor.s - ((settings.satShift.toDouble() / 100.0) * settings.satShiftExp * pow(distanceToCenter, settings.satShiftExp))).clamp(0.0, 1.0));
      }
      _originalColors[i] = col;
    }

    //setting darker colors
    for (int i = settings.colorCount ~/ 2 - 1; i >= 0; i--)
    {
      final double distanceToCenter = isEven? (i - centerIndex).abs().toDouble() - 0.5 : (i - centerIndex).abs().toDouble();
      KHSV col = KHSV(
          h: (centerColor.h - (settings.hueShiftExp * settings.hueShift * pow(distanceToCenter, settings.hueShiftExp))) % 360,
          s: (centerColor.s + ((settings.satShift.toDouble() / 100.0) * settings.satShiftExp * pow(distanceToCenter, settings.satShiftExp))).clamp(0.0, 1.0),
          v: (centerColor.v - (valueStepSize * distanceToCenter)).clamp(0.0, 1.0),
      );
      if (settings.satCurve == SatCurve.darkFlat)
      {
        col = KHSV(h: col.h, v: col.v, s: centerColor.s);
      }
      _originalColors[i] = col;
    }

    //SETTING SHIFTED COLORS
    for (int i = 0; i < _originalColors.length; i++)
    {
      final KHSV orig = _originalColors[i];
      final KHSV shiftedColor = KHSV(
          h: (orig.h + shifts[i].hueShiftNotifier.value) % 360,
          s: (orig.s + (shifts[i].satShiftNotifier.value.toDouble() / 100.0)).clamp(0.0, 1.0),
          v: (orig.v + (shifts[i].valShiftNotifier.value.toDouble() / 100.0)).clamp(0.0, 1.0),
      );
      shiftedColors[i].value = IdColor(hsv: shiftedColor, uuid: shiftedColors[i].value.uuid);
    }
  }

  int getIndex()
  {
    return GetIt.I.get<AppState>().colorRamps.indexOf(this);
  }
}
