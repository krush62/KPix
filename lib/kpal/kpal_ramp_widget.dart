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
    required this.rowValueFlex

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
  late List<KPalColorCardWidget> colorCards = [];
  final KPalRampWidgetOptions options = GetIt.I.get<PreferenceManager>().kPalWidgetOptions.rampOptions;

  @override
  void initState()
  {
    super.initState();
    _createColorCards();
  }

  void _createColorCards()
  {
    colorCards.clear();
    for (ValueNotifier<IdColor> notifier in widget.rampData.colors)
    {
      colorCards.add(KPalColorCardWidget(
          colorNotifier: notifier,
          isLast: notifier == widget.rampData.colors.last)
      );
    }
  }

  void settingsChanged({final bool colorCountChanged = false})
  {
    setState(() {
      widget.rampData.updateColors(colorCountChanged: colorCountChanged);
      if (colorCountChanged)
      {
        _createColorCards();
      }
    });
  }



  void _colorCountSliderChanged(final double newVal)
  {
    widget.rampData.settings.colorCount = newVal.round();
    settingsChanged(colorCountChanged: true);
  }

  void _baseHueSliderChanged(final double newVal)
  {
    widget.rampData.settings.baseHue = newVal.round();
    settingsChanged();
  }

  void _baseSatSliderChanged(final double newVal)
  {
    widget.rampData.settings.baseSat = newVal.round();
    settingsChanged();
  }

  void _hueShiftSliderChanged(final double newVal)
  {
    widget.rampData.settings.hueShift = newVal.round();
    settingsChanged();
  }

  void _hueShiftExpSliderChanged(final double newVal)
  {
    widget.rampData.settings.hueShiftExp = newVal;
    settingsChanged();
  }

  void _satShiftSliderChanged(final double newVal)
  {
    widget.rampData.settings.satShift = newVal.round();
    settingsChanged();
  }

  void _satShiftExpSliderChanged(final double newVal)
  {
    widget.rampData.settings.satShiftExp = newVal;
    settingsChanged();
  }

  void _satCurveModeChanged(final SatCurve newCurve)
  {
    widget.rampData.settings.satCurve = newCurve;
    settingsChanged();
  }

  void _valueRangeSliderChanged(final RangeValues newVals)
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
    settingsChanged();
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(options.padding),
      constraints: BoxConstraints(
        minHeight: options.minHeight,
        maxHeight: options.maxHeight,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: options.centerFlex,
            child: ColoredBox(
              color: Theme.of(context).primaryColorDark,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...colorCards,
                ],
              )
            )
          ),
          Expanded(
            flex: options.rightFlex,
            child: Container(
              color: Theme.of(context).primaryColor,
              padding: EdgeInsets.all(options.padding),
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
                            flex: options.rowLabelFlex,
                            child: const Text("Color Count")
                        ),
                        Expanded(
                          flex: options.rowControlFlex,
                          child: Slider(
                            value: widget.rampData.settings.colorCount.toDouble(),
                            min: widget.rampData.settings.constraints.colorCountMin.toDouble(),
                            max: widget.rampData.settings.constraints.colorCountMax.toDouble(),
                            divisions: widget.rampData.settings.constraints.colorCountMax - widget.rampData.settings.constraints.colorCountMin,
                            onChanged: _colorCountSliderChanged,
                            label: widget.rampData.settings.colorCount.toString(),
                          ),
                        ),
                        Expanded(
                            flex: options.rowValueFlex,
                            child: Text(widget.rampData.settings.colorCount.toString(), textAlign: TextAlign.end)
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Theme.of(context).primaryColorDark,
                    thickness: options.dividerThickness,
                    height: options.dividerThickness,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            flex: options.rowLabelFlex,
                            child: const Text("Base Hue")
                        ),
                        Expanded(
                          flex: options.rowControlFlex,
                          child: Slider(
                            value: widget.rampData.settings.baseHue.toDouble(),
                            min: widget.rampData.settings.constraints.baseHueMin.toDouble(),
                            max: widget.rampData.settings.constraints.baseHueMax.toDouble(),
                            divisions: widget.rampData.settings.constraints.baseHueMax - widget.rampData.settings.constraints.baseHueMin,
                            onChanged: _baseHueSliderChanged,
                            label: widget.rampData.settings.baseHue.toString(),
                          ),
                        ),
                        Expanded(
                            flex: options.rowValueFlex,
                            child: Text(widget.rampData.settings.baseHue.toString(), textAlign: TextAlign.end)
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Theme.of(context).primaryColorDark,
                    thickness: options.dividerThickness,
                    height: options.dividerThickness,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            flex: options.rowLabelFlex,
                            child: const Text("Base Sat")
                        ),
                        Expanded(
                          flex: options.rowControlFlex,
                          child: Slider(
                            value: widget.rampData.settings.baseSat.toDouble(),
                            min: widget.rampData.settings.constraints.baseSatMin.toDouble(),
                            max: widget.rampData.settings.constraints.baseSatMax.toDouble(),
                            divisions: widget.rampData.settings.constraints.baseSatMax - widget.rampData.settings.constraints.baseSatMin,
                            onChanged: _baseSatSliderChanged,
                            label: widget.rampData.settings.baseSat.toString(),
                          ),
                        ),
                        Expanded(
                            flex: options.rowValueFlex,
                            child: Text(widget.rampData.settings.baseSat.toString(), textAlign: TextAlign.end)
                        ),
                      ],
                    ),
                  ),
              Divider(
                color: Theme.of(context).primaryColorDark,
                thickness: options.dividerThickness,
                height: options.dividerThickness,
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                     Expanded(
                        flex: options.rowLabelFlex,
                        child: const Text("Hue Shift")
                    ),
                    Expanded(
                      flex: options.rowControlFlex,
                      child: Slider(
                        value: widget.rampData.settings.hueShift.toDouble(),
                        min: widget.rampData.settings.constraints.hueShiftMin.toDouble(),
                        max: widget.rampData.settings.constraints.hueShiftMax.toDouble(),
                        divisions: widget.rampData.settings.constraints.hueShiftMax - widget.rampData.settings.constraints.hueShiftMin,
                        onChanged: _hueShiftSliderChanged,
                        label: widget.rampData.settings.hueShift.toString(),
                      ),
                    ),
                    Expanded(
                        flex: options.rowValueFlex,
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
                             flex: options.rowLabelFlex,
                            child: const Text("↳ Exponent")
                        ),
                        Expanded(
                          flex: options.rowControlFlex,
                          child: Slider(
                            value: widget.rampData.settings.hueShiftExp.toDouble(),
                            min: widget.rampData.settings.constraints.hueShiftExpMin.toDouble(),
                            max: widget.rampData.settings.constraints.hueShiftExpMax.toDouble(),
                            divisions: (widget.rampData.settings.constraints.hueShiftExpMax * 100.0 - widget.rampData.settings.constraints.hueShiftExpMin * 100.0).round(),
                            onChanged: _hueShiftExpSliderChanged,
                            label: widget.rampData.settings.hueShiftExp.toStringAsFixed(2),
                          ),
                        ),
                        Expanded(
                            flex: options.rowValueFlex,
                            child: Text(widget.rampData.settings.hueShiftExp.toStringAsFixed(2), textAlign: TextAlign.end)
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Theme.of(context).primaryColorDark,
                    thickness: options.dividerThickness,
                    height: options.dividerThickness,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            flex: options.rowLabelFlex,
                            child: const Text("Sat Shift")
                        ),
                        Expanded(
                          flex: options.rowControlFlex,
                          child: Slider(
                            value: widget.rampData.settings.satShift.toDouble(),
                            min: widget.rampData.settings.constraints.satShiftMin.toDouble(),
                            max: widget.rampData.settings.constraints.satShiftMax.toDouble(),
                            divisions: widget.rampData.settings.constraints.satShiftMax - widget.rampData.settings.constraints.satShiftMin,
                            onChanged: _satShiftSliderChanged,
                            label: widget.rampData.settings.satShift.toString(),
                          ),
                        ),
                        Expanded(
                            flex: options.rowValueFlex,
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
                            flex: options.rowLabelFlex,
                            child: const Text("↳ Exponent")
                        ),
                        Expanded(
                          flex: options.rowControlFlex,
                          child: Slider(
                            value: widget.rampData.settings.satShiftExp.toDouble(),
                            min: widget.rampData.settings.constraints.satShiftExpMin.toDouble(),
                            max: widget.rampData.settings.constraints.satShiftExpMax.toDouble(),
                            divisions: (widget.rampData.settings.constraints.satShiftExpMax * 100.0 - widget.rampData.settings.constraints.satShiftExpMin * 100.0).round(),
                            onChanged: _satShiftExpSliderChanged,
                            label: widget.rampData.settings.satShiftExp.toStringAsFixed(2),
                          ),
                        ),
                        Expanded(
                            flex: options.rowValueFlex,
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
                            flex: options.rowLabelFlex,
                            child: const Text("Sat Curve")
                        ),
                        Expanded(
                            flex: options.rowControlFlex + options.rowValueFlex,
                          child: Row
                            (
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              IconButton(
                                color: widget.rampData.settings.satCurve == SatCurve.noFlat ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                                isSelected: widget.rampData.settings.satCurve == SatCurve.noFlat,
                                onPressed: () {_satCurveModeChanged(SatCurve.noFlat);},
                                icon: FaIcon(KPixIcons.no_flat, color: widget.rampData.settings.satCurve == SatCurve.noFlat ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColorDark),
                              ),
                              IconButton(
                                color: widget.rampData.settings.satCurve == SatCurve.darkFlat ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                                isSelected: widget.rampData.settings.satCurve == SatCurve.darkFlat,
                                onPressed: () {_satCurveModeChanged(SatCurve.darkFlat);},
                                icon: FaIcon(KPixIcons.dark_flat, color: widget.rampData.settings.satCurve == SatCurve.darkFlat ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColorDark),
                              ),
                              IconButton(
                                color: widget.rampData.settings.satCurve == SatCurve.brightFlat ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                                isSelected: widget.rampData.settings.satCurve == SatCurve.brightFlat,
                                onPressed: () {_satCurveModeChanged(SatCurve.brightFlat);},
                                icon: FaIcon(KPixIcons.bright_flat, color: widget.rampData.settings.satCurve == SatCurve.brightFlat ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColorDark),
                              ),
                              IconButton(
                                color: widget.rampData.settings.satCurve == SatCurve.linear ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                                isSelected: widget.rampData.settings.satCurve == SatCurve.linear,
                                onPressed: () {_satCurveModeChanged(SatCurve.linear);},
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
                    thickness: options.dividerThickness,
                    height: options.dividerThickness,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            flex: options.rowLabelFlex,
                            child: const Text("Value Range")
                        ),
                        Expanded(
                          flex: options.rowControlFlex,
                          child: RangeSlider(
                            values: RangeValues(widget.rampData.settings.valueRangeMin.toDouble(), widget.rampData.settings.valueRangeMax.toDouble()),
                            min: widget.rampData.settings.constraints.valueRangeMin.toDouble(),
                            max: widget.rampData.settings.constraints.valueRangeMax.toDouble(),
                            divisions: widget.rampData.settings.constraints.valueRangeMax - widget.rampData.settings.constraints.valueRangeMin,
                            onChanged: _valueRangeSliderChanged,
                            labels: RangeLabels(widget.rampData.settings.valueRangeMin.toString(), widget.rampData.settings.valueRangeMax.toString()),
                          ),
                        ),
                        Expanded(
                            flex: options.rowValueFlex,
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