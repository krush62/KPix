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
  final double borderWidth;
  final double borderRadius;
  final double dividerThickness;
  final int colorNameShowThreshold;
  final int renderIntervalMs;

  KPalRampWidgetOptions({
    required this.colorCardWidgetOptions,
    required this.padding,
    required this.centerFlex,
    required this.rightFlex,
    required this.borderWidth,
    required this.borderRadius,
    required this.dividerThickness,
    required this.rowControlFlex,
    required this.rowLabelFlex,
    required this.rowValueFlex,
    required this.colorNameShowThreshold,
    required this.renderIntervalMs,
  });
}

class KPalRamp extends StatefulWidget
{
  final KPalRampData rampData;
  final KPalRampData originalRampData;
  const KPalRamp({
    super.key,
    required this.rampData,
    required this.originalRampData,
  });

  @override
  State<KPalRamp> createState() => _KPalRampState();
}

class _KPalRampState extends State<KPalRamp>
{
  final ValueNotifier<List<KPalColorCardWidget>> _colorCards = ValueNotifier<List<KPalColorCardWidget>>(<KPalColorCardWidget>[]);
  final KPalRampWidgetOptions _options = GetIt.I.get<PreferenceManager>().kPalWidgetOptions.rampOptions;
  final AppState _appState = GetIt.I.get<AppState>();
  final ValueNotifier<ui.Image?> _previewImage = ValueNotifier<ui.Image?>(null);
  bool _hasRenderChanges = false;
  bool _hasShiftChanges = false;
  late Timer _renderTimer;
  final String _valueToolTipMessage = "Press to reset";

  late List<RasterableLayerState> _drawingLayers;

  @override
  void initState()
  {
    super.initState();
    _createColorCards();
    _drawingLayers = _copyLayers(originalLayers: _appState.timeline.selectedFrame!.layerList.getVisibleRasterLayers());
    _hasRenderChanges = true;
    _renderTimer = Timer.periodic(Duration(milliseconds: _options.renderIntervalMs), (final Timer t) {_renderCheck(t: t);});
    for (final ValueNotifier<IdColor> shiftNotifier in widget.rampData.shiftedColors)
    {
      shiftNotifier.addListener(() {
        _hasShiftChanges = true;
      },);
    }
    _settingsChanged();
  }


  List<RasterableLayerState> _copyLayers({required final Iterable<RasterableLayerState> originalLayers})
  {
    final List<RasterableLayerState> drawingLayers = <RasterableLayerState>[];
    for (final LayerState visibleLayer in originalLayers)
    {
      if (visibleLayer is DrawingLayerState)
      {
        final DrawingLayerState drawingLayer = DrawingLayerState.from(other: visibleLayer, layerStack: drawingLayers);
        drawingLayers.add(drawingLayer);
      }
      else if (visibleLayer is ShadingLayerState)
      {
        final ShadingLayerState shadingLayer = ShadingLayerState.from(other: visibleLayer, layerStack: drawingLayers);
        drawingLayers.add(shadingLayer);
      }
    }
    return drawingLayers;
  }

  @override
  void deactivate() {
    super.deactivate();
    _renderTimer.cancel();
  }

  void _renderCheck({required final Timer t})
  {
    if (_hasShiftChanges)
    {
      _settingsChanged();
      _hasShiftChanges = false;
    }
    final bool hasRasterizingLayers = _drawingLayers.where((final RasterableLayerState l) => l.visibilityState.value == LayerVisibilityState.visible && (l.doManualRaster || l.isRasterizing)).isNotEmpty;
    if (_hasRenderChanges && !hasRasterizingLayers)
    {
      getImageFromLayers(canvasSize: _appState.canvasSize, layerCollection: _appState.timeline.selectedFrame!.layerList, selection: _appState.selectionState.selection, layerStack: _drawingLayers).then((final ui.Image img) {
        _previewImage.value = img;
      });
      _hasRenderChanges = false;
    }
  }

  void _createColorCards()
  {
    final List<KPalColorCardWidget> newList = <KPalColorCardWidget>[];
    for (int i = 0; i < widget.rampData.shiftedColors.length; i++)
    {
      final ValueNotifier<IdColor> notifier = widget.rampData.shiftedColors[i];
      final ShiftSet shiftSet = widget.rampData.shifts[i];
      final KPalColorCardWidget card = KPalColorCardWidget(
          colorNotifier: notifier,
          shiftSet: shiftSet,
          isLast: notifier == widget.rampData.shiftedColors.last,
          showName: widget.rampData.shiftedColors.length < _options.colorNameShowThreshold,);

      newList.add(card);
    }
    _colorCards.value = newList;
  }

  void _settingsChanged({final bool colorCountChanged = false})
  {
    setState(() {
      widget.rampData._updateColors(colorCountChanged: colorCountChanged);
      if (colorCountChanged)
      {
        _drawingLayers = _copyLayers(originalLayers: _appState.timeline.selectedFrame!.layerList.getVisibleRasterLayers());
        final HashMap<int, int> indexMap = remapIndices(oldLength: widget.originalRampData.shiftedColors.length, newLength: widget.rampData.shiftedColors.length);
        for (final LayerState layerState in _drawingLayers)
        {
          if (layerState.runtimeType == DrawingLayerState)
          {
            final DrawingLayerState drawingLayer = layerState as DrawingLayerState;
            drawingLayer.remapSingleRamp(newData: widget.rampData, map: indexMap);
            drawingLayer.remapSingleRampLayerEffects(newData: widget.rampData, map: indexMap);
          }
        }
        _createColorCards();
      }
      for (final RasterableLayerState rasterLayer in _drawingLayers)
      {
          rasterLayer.doManualRaster = true;
      }
      _hasRenderChanges = true;
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
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ValueListenableBuilder<List<KPalColorCardWidget>>(
              valueListenable: _colorCards,
              builder: (final BuildContext context, final List<KPalColorCardWidget> cards, final Widget? child) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorDark,
                      borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ...cards,
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(_options.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _options.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                    onTap: ()
                                    {
                                      _colorCountSliderChanged(newVal: widget.rampData.settings.constraints.colorCountDefault.toDouble());
                                    },
                                    child: const Text("Color Count"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _options.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.colorCount.toDouble(),
                                  min: widget.rampData.settings.constraints.colorCountMin.toDouble(),
                                  max: widget.rampData.settings.constraints.colorCountMax.toDouble(),
                                  //divisions: widget.rampData.settings.constraints.colorCountMax - widget.rampData.settings.constraints.colorCountMin,
                                  onChanged: (final double newVal) {_colorCountSliderChanged(newVal: newVal);},
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                ),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _options.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                    onTap: ()
                                    {
                                      _baseHueSliderChanged(newVal: widget.rampData.settings.constraints.baseHueDefault.toDouble());
                                    },
                                    child: const Text("Base Hue"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _options.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.baseHue.toDouble(),
                                  min: widget.rampData.settings.constraints.baseHueMin.toDouble(),
                                  max: widget.rampData.settings.constraints.baseHueMax.toDouble(),
                                  divisions: widget.rampData.settings.constraints.baseHueMax - widget.rampData.settings.constraints.baseHueMin,
                                  onChanged: (final double newVal) {_baseHueSliderChanged(newVal: newVal);},
                                  isRainbow: true,
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,

                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _options.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                    onTap: ()
                                    {
                                      _hueShiftSliderChanged(newVal: widget.rampData.settings.constraints.hueShiftDefault.toDouble());
                                    },
                                    child: const Text("Hue Shift"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _options.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.hueShift.toDouble(),
                                  showPlusSignForPositive: true,
                                  min: widget.rampData.settings.constraints.hueShiftMin.toDouble(),
                                  max: widget.rampData.settings.constraints.hueShiftMax.toDouble(),
                                  //divisions: widget.rampData.settings.constraints.hueShiftMax - widget.rampData.settings.constraints.hueShiftMin,
                                  onChanged: (final double newVal) {_hueShiftSliderChanged(newVal: newVal);},
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _options.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                    onTap: ()
                                    {
                                      _hueShiftExpSliderChanged(newVal: widget.rampData.settings.constraints.hueShiftExpDefault);
                                    },
                                    child: const Text("↳ Exponent"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _options.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.hueShiftExp,
                                  min: widget.rampData.settings.constraints.hueShiftExpMin,
                                  max: widget.rampData.settings.constraints.hueShiftExpMax,
                                  //divisions: (widget.rampData.settings.constraints.hueShiftExpMax * 100.0 - widget.rampData.settings.constraints.hueShiftExpMin * 100.0).round(),
                                  onChanged: (final double newVal) {_hueShiftExpSliderChanged(newVal: newVal);},
                                  label: widget.rampData.settings.hueShiftExp.toStringAsFixed(2),
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                ),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _options.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                    onTap: ()
                                    {
                                      _baseSatSliderChanged(newVal: widget.rampData.settings.constraints.baseSatDefault.toDouble());
                                    },
                                    child: const Text("Base Sat"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _options.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.baseSat.toDouble(),
                                  min: widget.rampData.settings.constraints.baseSatMin.toDouble(),
                                  max: widget.rampData.settings.constraints.baseSatMax.toDouble(),
                                  //divisions: widget.rampData.settings.constraints.baseSatMax - widget.rampData.settings.constraints.baseSatMin,
                                  onChanged: (final double newVal) {_baseSatSliderChanged(newVal: newVal);},
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _options.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                    onTap: ()
                                    {
                                      _satShiftSliderChanged(newVal: widget.rampData.settings.constraints.satShiftDefault.toDouble());
                                    },
                                    child: const Text("Sat Shift"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _options.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.satShift.toDouble(),
                                  min: widget.rampData.settings.constraints.satShiftMin.toDouble(),
                                  max: widget.rampData.settings.constraints.satShiftMax.toDouble(),
                                  showPlusSignForPositive: true,
                                  //divisions: widget.rampData.settings.constraints.satShiftMax - widget.rampData.settings.constraints.satShiftMin,
                                  onChanged: (final double newVal) {_satShiftSliderChanged(newVal: newVal);},
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _options.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                      onTap: ()
                                      {
                                        _satShiftExpSliderChanged(newVal: widget.rampData.settings.constraints.satShiftExpDefault);
                                      },
                                      child: const Text("↳ Exponent"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _options.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.satShiftExp,
                                  min: widget.rampData.settings.constraints.satShiftExpMin,
                                  max: widget.rampData.settings.constraints.satShiftExpMax,
                                  //divisions: (widget.rampData.settings.constraints.satShiftExpMax * 100.0 - widget.rampData.settings.constraints.satShiftExpMin * 100.0).round(),
                                  onChanged: (final double newVal) {_satShiftExpSliderChanged(newVal: newVal);},
                                  label: widget.rampData.settings.satShiftExp.toStringAsFixed(2),
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _options.rowLabelFlex,
                                child: const Text("Sat Curve"),
                              ),
                              Expanded(
                                flex: _options.rowControlFlex,
                                child: SegmentedButton<SatCurve>(
                                  selected: <SatCurve>{widget.rampData.settings.satCurve},
                                  showSelectedIcon: false,
                                  onSelectionChanged: (final Set<SatCurve> curves)
                                  {
                                    if (curves.isNotEmpty && curves.first != widget.rampData.settings.satCurve)
                                    {
                                      _satCurveModeChanged(newCurve: curves.first);
                                    }
                                  },
                                  segments: const <ButtonSegment<SatCurve>>[
                                    ButtonSegment<SatCurve>(
                                      value: SatCurve.noFlat,
                                      label: FaIcon(KPixIcons.noFlat),
                                    ),
                                    ButtonSegment<SatCurve>(
                                      value: SatCurve.darkFlat,
                                      label: FaIcon(KPixIcons.darkFlat),
                                    ),
                                    ButtonSegment<SatCurve>(
                                      value: SatCurve.brightFlat,
                                      label: FaIcon(KPixIcons.brightFlat),
                                    ),
                                    ButtonSegment<SatCurve>(
                                      value: SatCurve.linear,
                                      label: FaIcon(KPixIcons.linear),
                                    ),
                                  ],
                                ),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _options.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                      onTap: ()
                                      {
                                        _valueRangeSliderChanged(newVals: RangeValues(widget.rampData.settings.constraints.valueRangeMinDefault.toDouble(), widget.rampData.settings.constraints.valueRangeMaxDefault.toDouble()));
                                      },
                                      child: const Text("Value Range"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _options.rowControlFlex,
                                child: KPixRangeSlider(
                                  values: RangeValues(widget.rampData.settings.valueRangeMin.toDouble(), widget.rampData.settings.valueRangeMax.toDouble()),
                                  min: widget.rampData.settings.constraints.valueRangeMin.toDouble(),
                                  max: widget.rampData.settings.constraints.valueRangeMax.toDouble(),
                                  //divisions: widget.rampData.settings.constraints.valueRangeMax - widget.rampData.settings.constraints.valueRangeMin,
                                  onChanged: (final RangeValues newVals) {_valueRangeSliderChanged(newVals: newVals);},
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(_options.padding),
                    child: ValueListenableBuilder<ui.Image?>(
                      valueListenable: _previewImage,
                      builder: (final BuildContext context, final ui.Image? img, final Widget? child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
                          child: RawImage(
                            fit: BoxFit.contain,
                            filterQuality: ui.FilterQuality.none,
                            color: Theme.of(context).primaryColorDark,
                            colorBlendMode: ui.BlendMode.dstATop,
                            image: img,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
