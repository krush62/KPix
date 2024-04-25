import 'dart:ffi';

import 'package:shared_preferences/shared_preferences.dart';

enum PreferenceDouble
{
  Layout_SplitViewHorizontal_Ratio(defaultValue: 0.75),
  Layout_SplitViewHorizontal_TopMinRatio(defaultValue: 0.5),
  Layout_SplitViewHorizontal_BottomMinRatio(defaultValue: 0.1),
  Layout_SplitViewVertical_Ratio(defaultValue: 0.25),
  Layout_SplitViewVertical_LeftMinRatio(defaultValue: 0.1),
  Layout_SplitViewVertical_RightMinRatio(defaultValue: 0.75),
  Layout_Canvas_LongPressCancelDistance(defaultValue: 10.0),
  Layout_Tools_Padding(defaultValue: 8.0),
  Layout_Tools_ButtonResizeFactor(defaultValue: 64.0),
  Layout_Tools_SpacingFactor(defaultValue: 32.0),
  Layout_Tools_IconSize(defaultValue: 28.0);

  const PreferenceDouble({
    required this.defaultValue,
  });

  final double defaultValue;
}

enum PreferenceInt
{
  Layout_Canvas_LongPressDuration(defaultValue: 1000),
  Layout_Canvas_Stylus_PollRate(defaultValue: 100)


  ;
  const PreferenceInt({
    required this.defaultValue
  });
  final int defaultValue;
}

class _DoublePair
{
  final double value;
  bool changed = false;
  _DoublePair(double val) : this.value = val;
}

class _IntPair
{
  final int value;
  bool changed = false;
  _IntPair(int val) : this.value = val;
}

class PreferenceManager
{
  final SharedPreferences _prefs;
  final Map<PreferenceDouble, _DoublePair> _doubleMap = {};
  final Map<PreferenceInt, _IntPair> _intMap = {};


  PreferenceManager(SharedPreferences prefs) : _prefs = prefs
  {
    _init();
  }

  void _init()
  {
    for (PreferenceDouble dblEnum in PreferenceDouble.values)
    {
      _doubleMap[dblEnum] = _DoublePair(_prefs.getDouble(dblEnum.name) ?? dblEnum.defaultValue);
    }

    for (PreferenceInt intEnum in PreferenceInt.values)
    {
      _intMap[intEnum] = _IntPair(_prefs.getInt(intEnum.name) ?? intEnum.defaultValue);
    }
  }

double getValueD(PreferenceDouble prefName)
{
  double retVal = 0.0;
  final double? val = _doubleMap[prefName]?.value;
  if (val != null)
  {
    retVal = val;
  }
  return retVal;
}

int getValueI(PreferenceInt prefName)
{
  int retVal = 0;
  final int? val = _intMap[prefName]?.value;
  if (val != null)
  {
    retVal = val;
  }
  return retVal;
}


   Future<void> savePreferences()
  async {
    _doubleMap.forEach((key, value)
    {
      if (value.changed)
      {
        _prefs.setDouble(key.name, value.value);
      }
    });
    _intMap.forEach((key, value)
    {
      if (value.changed)
      {
        _prefs.setInt(key.name, value.value);
      }
    });
  }

}

