library kpal;


import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/color_names.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/kpix_icons.dart';

part 'kpal_ramp_widget.dart';
part 'kpal_color_card_widget.dart';
part 'kpal_ramp_data.dart';


class IdColor
{
  final Color color;
  final String uuid;
  IdColor({required this.color, required this.uuid});
}

enum SatCurve
{
  noFlat,
  darkFlat,
  brightFlat,
  linear,
}

const Map<int, SatCurve> satCurveMap = {
  0:SatCurve.noFlat,
  1:SatCurve.darkFlat,
  2:SatCurve.brightFlat,
  3:SatCurve.linear
};

class KPalRampSettings
{
  final KPalConstraints constraints;
  late int colorCount;
  late int baseHue;
  late int baseSat;
  late int hueShift;
  late double hueShiftExp;
  late int satShift;
  late double satShiftExp;
  late int valueRangeMin;
  late int valueRangeMax;
  late SatCurve satCurve;

  KPalRampSettings({required this.constraints})
  {
    colorCount = constraints.colorCountDefault;
    baseHue = constraints.baseHueDefault;
    baseSat = constraints.baseSatDefault;
    hueShift = constraints.hueShiftDefault;
    hueShiftExp = constraints.hueShiftExpDefault;
    satShift = constraints.satShiftDefault;
    satShiftExp = constraints.satShiftExpDefault;
    valueRangeMin = constraints.valueRangeMinDefault;
    valueRangeMax = constraints.valueRangeMaxDefault;
    satCurve = satCurveMap[constraints.satCurveDefault] ?? SatCurve.noFlat;
  }

  factory KPalRampSettings.from({required KPalRampSettings other})
  {
    KPalRampSettings newSettings = KPalRampSettings(constraints: other.constraints);
    newSettings.colorCount = other.colorCount;
    newSettings.baseHue = other.baseHue;
    newSettings.baseSat = other.baseSat;
    newSettings.hueShift = other.hueShift;
    newSettings.hueShiftExp = other.hueShiftExp;
    newSettings.satShift = other.satShift;
    newSettings.satShiftExp = other.satShiftExp;
    newSettings.valueRangeMin = other.valueRangeMin;
    newSettings.valueRangeMax = other.valueRangeMax;
    newSettings.satCurve = other.satCurve;
    return newSettings;
  }
}

class KPalConstraints
{
  final int colorCountMin;
  final int colorCountMax;
  final int colorCountDefault;
  final int baseHueMin;
  final int baseHueMax;
  final int baseHueDefault;
  final int baseSatMin;
  final int baseSatMax;
  final int baseSatDefault;
  final int hueShiftMin;
  final int hueShiftMax;
  final int hueShiftDefault;
  final double hueShiftExpMin;
  final double hueShiftExpMax;
  final double hueShiftExpDefault;
  final int satShiftMin;
  final int satShiftMax;
  final int satShiftDefault;
  final double satShiftExpMin;
  final double satShiftExpMax;
  final double satShiftExpDefault;
  final int valueRangeMin;
  final int valueRangeMinDefault;
  final int valueRangeMax;
  final int valueRangeMaxDefault;
  final int satCurveDefault;

  KPalConstraints({
    required this.colorCountMin,
    required this.colorCountMax,
    required this.colorCountDefault,
    required this.baseHueMin,
    required this.baseHueMax,
    required this.baseHueDefault,
    required this.baseSatMin,
    required this.baseSatMax,
    required this.baseSatDefault,
    required this.hueShiftMin,
    required this.hueShiftMax,
    required this.hueShiftDefault,
    required this.hueShiftExpMin,
    required this.hueShiftExpMax,
    required this.hueShiftExpDefault,
    required this.satShiftMin,
    required this.satShiftMax,
    required this.satShiftDefault,
    required this.satShiftExpMin,
    required this.satShiftExpMax,
    required this.satShiftExpDefault,
    required this.valueRangeMin,
    required this.valueRangeMinDefault,
    required this.valueRangeMax,
    required this.valueRangeMaxDefault,
    required this.satCurveDefault,
  });
}

class KPalWidgetOptions
{
  final KPalRampWidgetOptions rampOptions;
  final double borderWidth;
  final double outsidePadding;
  final double insidePadding;
  final double borderRadius;
  final int smokeOpacity;
  final double iconSize;

  KPalWidgetOptions({
    required this.borderWidth,
    required this.outsidePadding,
    required this.smokeOpacity,
    required this.rampOptions,
    required this.borderRadius,
    required this.insidePadding,
    required this.iconSize,
  });


}

class KPal extends StatefulWidget {
  final KPalRampData colorRamp;
  final Function() dismiss;
  final ColorRampUpdateFn accept;
  final ColorRampFn delete;


  const KPal({
    super.key,
    required this.colorRamp,
    required this.dismiss,
    required this.accept,
    required this.delete,
  });



  @override
  State<KPal> createState() => _KPalState();
}

class _KPalState extends State<KPal>
{
  bool _alertDialogVisible = false;
  late OverlayEntry _alertDialog;
  final KPalWidgetOptions _options = GetIt.I.get<PreferenceManager>().kPalWidgetOptions;
  late KPalRampData _originalData;

  @override
  void initState() {
    super.initState();
    widget.colorRamp;
    _originalData = KPalRampData.from(other: widget.colorRamp);

    _alertDialog = OverlayEntries.getAlertDialog(
        onDismiss: _dismissAlertDialog,
        onAccept: _acceptDeletion,
        message: "Do you really want to delete this color ramp?",
      );
  }


  void _acceptDeletion()
  {
    _dismissAlertDialog();
    widget.delete(widget.colorRamp);
  }

  void _dismissAlertDialog()
  {
    if (_alertDialogVisible)
    {
       _alertDialog.remove();
       _alertDialogVisible = false;
    }
  }

  void _showDeleteDialog()
  {
    if (!_alertDialogVisible) {
      Overlay.of(context).insert(_alertDialog);
      _alertDialogVisible = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(_options.outsidePadding),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).primaryColorLight,
              width: _options.borderWidth,
            ),
            borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
          ),
          child: Material(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                KPalRamp(
                  rampData: widget.colorRamp,
                ),
                Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: EdgeInsets.all(_options.insidePadding),
                          child: IconButton.outlined(
                            icon: FaIcon(
                              FontAwesomeIcons.xmark,
                              size: _options.iconSize,
                            ),
                            onPressed: () {
                              widget.dismiss();
                            },
                          ),
                        )
                      ),
                      Expanded(
                          flex: 1,
                          child: Padding(
                            padding: EdgeInsets.all(_options.insidePadding),
                            child: IconButton.outlined(
                              icon: FaIcon(
                                FontAwesomeIcons.trash,
                                size: _options.iconSize,
                              ),
                              onPressed: () {
                                _showDeleteDialog();
                              },
                            ),
                          )
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: EdgeInsets.all(_options.insidePadding),
                          child: IconButton.outlined(
                            icon: FaIcon(
                              FontAwesomeIcons.check,
                              size: _options.iconSize,
                            ),
                            onPressed: () {
                              widget.accept(widget.colorRamp, _originalData);
                            },
                          ),
                        )
                      ),
                    ]
                ),
              ],
            )
          ),
        ),
      ),
    );
  }
  
}