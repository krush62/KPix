import 'package:flutter/material.dart';

class Helper
{

  static String colorToHexString(final Color c) {
    return '#${c.red.toRadixString(16).padLeft(2, '0')}'
        '${c.green.toRadixString(16).padLeft(2, '0')}'
        '${c.blue.toRadixString(16).padLeft(2, '0')}';
  }

  static String colorToRGBString(final Color c) {
    return '${c.red.toString()} | '
        '${c.green.toString()} | '
        '${c.blue.toString()}';
  }

  static String colorToHSVString(final Color c) {
    return hsvColorToHSVString(HSVColor.fromColor(c));
  }

  static String hsvColorToHSVString(final HSVColor c) {
    return "${c.hue.round().toString()}° | "
        "${(c.saturation * 100.0).round().toString()}% | "
        "${(c.value * 100.0).round().toString()}%";
  }
}