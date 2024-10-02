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

class KPalRampWidgetOptions
{
  final KPalColorCardWidgetOptions colorCardWidgetOptions;
  final double padding;
  final int centerFlex;
  final int rightFlex;
  final int rowLabelFlex;
  final int rowControlFlex;
  final int rowValueFlex;
  final double minHeight;
  final double maxHeight;
  final double borderWidth;
  final double borderRadius;
  final double dividerThickness;
  final int colorNameShowThreshold;


  KPalRampWidgetOptions({
    required this.colorCardWidgetOptions,
    required this.padding,
    required this.centerFlex,
    required this.rightFlex,
    required this.minHeight,
    required this.maxHeight,
    required this.borderWidth,
    required this.borderRadius,
    required this.dividerThickness,
    required this.rowControlFlex,
    required this.rowLabelFlex,
    required this.rowValueFlex,
    required this.colorNameShowThreshold
  });
}

class KPalRamp extends StatefulWidget
{
  final KPalRampData rampData;
  const KPalRamp({
    super.key,
    required this.rampData,
  });

  @override
  State<KPalRamp> createState() => _KPalRampState();
}

class _KPalRampState extends State<KPalRamp>
{
  final List<KPalColorCardWidget> _colorCards = [];
  final KPalRampWidgetOptions _options = GetIt.I.get<PreferenceManager>().kPalWidgetOptions.rampOptions;

  @override
  void initState()
  {
    super.initState();
    _createColorCards();
  }

  void _createColorCards()
  {
    _colorCards.clear();
    for (int i = 0; i < widget.rampData.shiftedColors.length; i++)
    {
      final ValueNotifier<IdColor> notifier = widget.rampData.shiftedColors[i];
      final ShiftSet shiftSet = widget.rampData.shifts[i];
      final KPalColorCardWidget card = KPalColorCardWidget(
          colorNotifier: notifier,
          shiftSet: shiftSet,
          isLast: notifier == widget.rampData.shiftedColors.last,
          showName: widget.rampData.shiftedColors.length < _options.colorNameShowThreshold);
      _colorCards.add(card);
    }
  }

  void _settingsChanged({final bool colorCountChanged = false})
  {
    setState(() {
      widget.rampData._updateColors(colorCountChanged: colorCountChanged);
      if (colorCountChanged)
      {
        _createColorCards();
      }
    });
  }

  void _colorCountSliderChanged({required final double newVal})
  {
    widget.rampData.settings.colorCount = newVal.round();
    _settingsChanged(colorCountChanged: true);
  }

  void _baseHueSliderChanged({required final double newVal})
  {
    widget.rampData.settings.baseHue = newVal.round();
    _settingsChanged();
  }

  void _baseSatSliderChanged({required final double newVal})
  {
    widget.rampData.settings.baseSat = newVal.round();
    _settingsChanged();
  }

  void _hueShiftSliderChanged({required final double newVal})
  {
    widget.rampData.settings.hueShift = newVal.round();
    _settingsChanged();
  }

  void _hueShiftExpSliderChanged({required final double newVal})
  {
    widget.rampData.settings.hueShiftExp = newVal;
    _settingsChanged();
  }

  void _satShiftSliderChanged({required final double newVal})
  {
    widget.rampData.settings.satShift = newVal.round();
    _settingsChanged();
  }

  void _satShiftExpSliderChanged({required final double newVal})
  {
    widget.rampData.settings.satShiftExp = newVal;
    _settingsChanged();
  }

  void _satCurveModeChanged({required final SatCurve newCurve})
  {
    widget.rampData.settings.satCurve = newCurve;
    _settingsChanged();
  }

  void _valueRangeSliderChanged({required final RangeValues newVals})
  {
    if (newVals.start < newVals.end)
    {
      widget.rampData.settings.valueRangeMin = newVals.start.round();
      widget.rampData.settings.valueRangeMax = newVals.end.round();
    }
    else
    {
      widget.rampData.settings.valueRangeMin = newVals.end.round();
      widget.rampData.settings.valueRangeMax = newVals.start.round();
    }
    _settingsChanged();
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_options.padding),
      constraints: BoxConstraints(
        minHeight: _options.minHeight,
        maxHeight: _options.maxHeight,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: _options.centerFlex,
            child: ColoredBox(
              color: Theme.of(context).primaryColorDark,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ..._colorCards,
                ],
              )
            )
          ),
          Expanded(
            flex: _options.rightFlex,
            child: Container(
              color: Theme.of(context).primaryColor,
              padding: EdgeInsets.all(_options.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            flex: _options.rowLabelFlex,
                            child: const Text("Color Count")
                        ),
                        Expanded(
                          flex: _options.rowControlFlex,
                          child: Slider(
                            value: widget.rampData.settings.colorCount.toDouble(),
                            min: widget.rampData.settings.constraints.colorCountMin.toDouble(),
                            max: widget.rampData.settings.constraints.colorCountMax.toDouble(),
                            divisions: (widget.rampData.settings.constraints.colorCountMax - widget.rampData.settings.constraints.colorCountMin),
                            onChanged: (final double newVal) {_colorCountSliderChanged(newVal: newVal);},
                            label: widget.rampData.settings.colorCount.toString(),
                          ),
                        ),
                        Expanded(
                            flex: _options.rowValueFlex,
                            child: Text(widget.rampData.settings.colorCount.toString(), textAlign: TextAlign.end)
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Theme.of(context).primaryColorDark,
                    thickness: _options.dividerThickness,
                    height: _options.dividerThickness,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            flex: _options.rowLabelFlex,
                            child: const Text("Base Hue")
                        ),
                        Expanded(
                          flex: _options.rowControlFlex,
                          child: Slider(
                            value: widget.rampData.settings.baseHue.toDouble(),
                            min: widget.rampData.settings.constraints.baseHueMin.toDouble(),
                            max: widget.rampData.settings.constraints.baseHueMax.toDouble(),
                            divisions: widget.rampData.settings.constraints.baseHueMax - widget.rampData.settings.constraints.baseHueMin,
                            onChanged: (final double newVal) {_baseHueSliderChanged(newVal: newVal);},
                            label: widget.rampData.settings.baseHue.toString(),
                          ),
                        ),
                        Expanded(
                            flex: _options.rowValueFlex,
                            child: Text(widget.rampData.settings.baseHue.toString(), textAlign: TextAlign.end)
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Theme.of(context).primaryColorDark,
                    thickness: _options.dividerThickness,
                    height: _options.dividerThickness,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            flex: _options.rowLabelFlex,
                            child: const Text("Base Sat")
                        ),
                        Expanded(
                          flex: _options.rowControlFlex,
                          child: Slider(
                            value: widget.rampData.settings.baseSat.toDouble(),
                            min: widget.rampData.settings.constraints.baseSatMin.toDouble(),
                            max: widget.rampData.settings.constraints.baseSatMax.toDouble(),
                            divisions: widget.rampData.settings.constraints.baseSatMax - widget.rampData.settings.constraints.baseSatMin,
                            onChanged: (final double newVal) {_baseSatSliderChanged(newVal: newVal);},
                            label: widget.rampData.settings.baseSat.toString(),
                          ),
                        ),
                        Expanded(
                            flex: _options.rowValueFlex,
                            child: Text(widget.rampData.settings.baseSat.toString(), textAlign: TextAlign.end)
                        ),
                      ],
                    ),
                  ),
              Divider(
                color: Theme.of(context).primaryColorDark,
                thickness: _options.dividerThickness,
                height: _options.dividerThickness,
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                     Expanded(
                        flex: _options.rowLabelFlex,
                        child: const Text("Hue Shift")
                    ),
                    Expanded(
                      flex: _options.rowControlFlex,
                      child: Slider(
                        value: widget.rampData.settings.hueShift.toDouble(),
                        min: widget.rampData.settings.constraints.hueShiftMin.toDouble(),
                        max: widget.rampData.settings.constraints.hueShiftMax.toDouble(),
                        divisions: widget.rampData.settings.constraints.hueShiftMax - widget.rampData.settings.constraints.hueShiftMin,
                        onChanged: (final double newVal) {_hueShiftSliderChanged(newVal: newVal);},
                        label: widget.rampData.settings.hueShift.toString(),
                      ),
                    ),
                    Expanded(
                        flex: _options.rowValueFlex,
                        child: Text(widget.rampData.settings.hueShift.toString(), textAlign: TextAlign.end)
                    ),
                  ],
                ),
              ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                         Expanded(
                             flex: _options.rowLabelFlex,
                            child: const Text("↳ Exponent")
                        ),
                        Expanded(
                          flex: _options.rowControlFlex,
                          child: Slider(
                            value: widget.rampData.settings.hueShiftExp.toDouble(),
                            min: widget.rampData.settings.constraints.hueShiftExpMin.toDouble(),
                            max: widget.rampData.settings.constraints.hueShiftExpMax.toDouble(),
                            divisions: (widget.rampData.settings.constraints.hueShiftExpMax * 100.0 - widget.rampData.settings.constraints.hueShiftExpMin * 100.0).round(),
                            onChanged: (final double newVal) {_hueShiftExpSliderChanged(newVal: newVal);},
                            label: widget.rampData.settings.hueShiftExp.toStringAsFixed(2),
                          ),
                        ),
                        Expanded(
                            flex: _options.rowValueFlex,
                            child: Text(widget.rampData.settings.hueShiftExp.toStringAsFixed(2), textAlign: TextAlign.end)
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Theme.of(context).primaryColorDark,
                    thickness: _options.dividerThickness,
                    height: _options.dividerThickness,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            flex: _options.rowLabelFlex,
                            child: const Text("Sat Shift")
                        ),
                        Expanded(
                          flex: _options.rowControlFlex,
                          child: Slider(
                            value: widget.rampData.settings.satShift.toDouble(),
                            min: widget.rampData.settings.constraints.satShiftMin.toDouble(),
                            max: widget.rampData.settings.constraints.satShiftMax.toDouble(),
                            divisions: widget.rampData.settings.constraints.satShiftMax - widget.rampData.settings.constraints.satShiftMin,
                            onChanged: (final double newVal) {_satShiftSliderChanged(newVal: newVal);},
                            label: widget.rampData.settings.satShift.toString(),
                          ),
                        ),
                        Expanded(
                            flex: _options.rowValueFlex,
                            child: Text(widget.rampData.settings.satShift.toString(), textAlign: TextAlign.end)
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            flex: _options.rowLabelFlex,
                            child: const Text("↳ Exponent")
                        ),
                        Expanded(
                          flex: _options.rowControlFlex,
                          child: Slider(
                            value: widget.rampData.settings.satShiftExp.toDouble(),
                            min: widget.rampData.settings.constraints.satShiftExpMin.toDouble(),
                            max: widget.rampData.settings.constraints.satShiftExpMax.toDouble(),
                            divisions: (widget.rampData.settings.constraints.satShiftExpMax * 100.0 - widget.rampData.settings.constraints.satShiftExpMin * 100.0).round(),
                            onChanged: (final double newVal) {_satShiftExpSliderChanged(newVal: newVal);},
                            label: widget.rampData.settings.satShiftExp.toStringAsFixed(2),
                          ),
                        ),
                        Expanded(
                            flex: _options.rowValueFlex,
                            child: Text(widget.rampData.settings.satShiftExp.toStringAsFixed(2), textAlign: TextAlign.end)
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            flex: _options.rowLabelFlex,
                            child: const Text("Sat Curve")
                        ),
                        Expanded(
                            flex: _options.rowControlFlex + _options.rowValueFlex,
                          child: Row
                            (
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              IconButton(
                                color: widget.rampData.settings.satCurve == SatCurve.noFlat ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                                style: IconButton.styleFrom(
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                isSelected: widget.rampData.settings.satCurve == SatCurve.noFlat,
                                onPressed: () {_satCurveModeChanged(newCurve: SatCurve.noFlat);},
                                icon: FaIcon(KPixIcons.noFlat, color: widget.rampData.settings.satCurve == SatCurve.noFlat ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColorDark),
                              ),
                              IconButton(
                                color: widget.rampData.settings.satCurve == SatCurve.darkFlat ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                                style: IconButton.styleFrom(
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                isSelected: widget.rampData.settings.satCurve == SatCurve.darkFlat,
                                onPressed: () {_satCurveModeChanged(newCurve: SatCurve.darkFlat);},
                                icon: FaIcon(KPixIcons.darkFlat, color: widget.rampData.settings.satCurve == SatCurve.darkFlat ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColorDark),
                              ),
                              IconButton(
                                color: widget.rampData.settings.satCurve == SatCurve.brightFlat ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                                style: IconButton.styleFrom(
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                isSelected: widget.rampData.settings.satCurve == SatCurve.brightFlat,
                                onPressed: () {_satCurveModeChanged(newCurve: SatCurve.brightFlat);},
                                icon: FaIcon(KPixIcons.brightFlat, color: widget.rampData.settings.satCurve == SatCurve.brightFlat ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColorDark),
                              ),
                              IconButton(
                                color: widget.rampData.settings.satCurve == SatCurve.linear ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                                style: IconButton.styleFrom(
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                isSelected: widget.rampData.settings.satCurve == SatCurve.linear,
                                onPressed: () {_satCurveModeChanged(newCurve: SatCurve.linear);},
                                icon: FaIcon(KPixIcons.linear, color: widget.rampData.settings.satCurve == SatCurve.linear ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColorDark),
                              )
                            ],
                          )
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Theme.of(context).primaryColorDark,
                    thickness: _options.dividerThickness,
                    height: _options.dividerThickness,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            flex: _options.rowLabelFlex,
                            child: const Text("Value Range")
                        ),
                        Expanded(
                          flex: _options.rowControlFlex,
                          child: RangeSlider(
                            values: RangeValues(widget.rampData.settings.valueRangeMin.toDouble(), widget.rampData.settings.valueRangeMax.toDouble()),
                            min: widget.rampData.settings.constraints.valueRangeMin.toDouble(),
                            max: widget.rampData.settings.constraints.valueRangeMax.toDouble(),
                            divisions: widget.rampData.settings.constraints.valueRangeMax - widget.rampData.settings.constraints.valueRangeMin,
                            onChanged: (final RangeValues newVals) {_valueRangeSliderChanged(newVals: newVals);},
                            labels: RangeLabels(widget.rampData.settings.valueRangeMin.toString(), widget.rampData.settings.valueRangeMax.toString()),
                          ),
                        ),
                        Expanded(
                            flex: _options.rowValueFlex,
                            child: Text("${widget.rampData.settings.valueRangeMin.toString()}-${widget.rampData.settings.valueRangeMax.toString()}", textAlign: TextAlign.end)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}