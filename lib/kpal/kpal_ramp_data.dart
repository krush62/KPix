part of 'kpal_widget.dart';

class KPalRampData
{
  final KPalRampSettings settings;
  final String uuid;
  final List<ValueNotifier<IdColor>> colors = [];

    KPalRampData({
    required this.uuid,
    required this.settings
  })
  {
    updateColors(colorCountChanged: true);
  }

  void updateColors({required bool colorCountChanged})
  {
    if (colorCountChanged)
    {
      Uuid uuid = const Uuid();
      colors.clear();
      for (int i = 0; i < settings.colorCount; i++)
      {
         colors.add(ValueNotifier(IdColor(color: Colors.black, uuid: uuid.v1())));

      }
    }

    
    int centerIndex = settings.colorCount ~/ 2;
    bool isEven = settings.colorCount % 2 == 0;
    double valueStepSize = ((settings.valueRangeMax - settings.valueRangeMin) / 100.0) / (settings.colorCount - 1);

    //setting central (center) color
    HSVColor centerColor = HSVColor.fromAHSV(
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

      double distanceToCenter = (i - centerIndex).abs().toDouble();
      if (isEven)
      {
        distanceToCenter += 0.5;
      }
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
    double distanceToCenter = (i - centerIndex).abs().toDouble();
    if (isEven)
    {
      distanceToCenter -= 0.5;
    }

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