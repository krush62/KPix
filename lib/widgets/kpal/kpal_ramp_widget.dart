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



abstract final class _KPalRampWidgetOptions
{
  //final KPalColorCardWidgetOptions colorCardWidgetOptions;
  static const double padding = 8.0;
  //static const int centerFlex = 6;
  //static const int rightFlex = 2;
  static const int rowLabelFlex = 4;
  static const int rowControlFlex = 25;
  //static const int rowValueFlex = 3;
  //static const double borderWidth = 4.0;
  static const double borderRadius = 8.0;
  static const double dividerThickness = 2.0;
  static const int colorNameShowThreshold = 10;
  static const int renderIntervalMs = 100;

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
  final AppState _appState = GetIt.I.get<AppState>();
  final ValueNotifier<ui.Image?> _previewImage = ValueNotifier<ui.Image?>(null);
  bool _hasRenderChanges = false;
  bool _hasShiftChanges = false;
  bool _isDisposed = false;
  final List<ui.Image> _imagesToRetire = <ui.Image>[];
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
    _renderTimer = Timer.periodic(const Duration(milliseconds: _KPalRampWidgetOptions.renderIntervalMs), (final Timer t) {_renderCheck(t: t);});
    for (final ValueNotifier<IdColor> shiftNotifier in widget.rampData.shiftedColors)
    {
      shiftNotifier.addListener(_shiftChanged);
    }
    _settingsChanged();
  }

  void _shiftChanged()
  {
    _hasShiftChanges = true;
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

  /// Releases the layer copies made for the preview.
  ///
  /// Each copy started its own periodic raster timer, which keeps firing - and
  /// keeps the copy, its pixel map and its images reachable - until the layer is
  /// disposed.
  void _disposeLayers({required final Iterable<RasterableLayerState> layers})
  {
    for (final RasterableLayerState layer in layers)
    {
      layer.dispose();
    }
  }

  /// Disposes [image] once the current frame has been painted.
  ///
  /// The preview is shown through a [RawImage], which holds the handle until the
  /// frame that drops it has been drawn; releasing earlier trips an assertion in
  /// the engine.
  void _retireImage({required final ui.Image image})
  {
    _imagesToRetire.add(image);
    if (_imagesToRetire.length > 1)
    {
      //a flush is already scheduled and will take this one too
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      final List<ui.Image> images = List<ui.Image>.of(_imagesToRetire);
      _imagesToRetire.clear();
      for (final ui.Image image in images)
      {
        image.dispose();
      }
    });
    //nothing else may be dirty, in which case no frame would ever be produced
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void deactivate() {
    super.deactivate();
    _renderTimer.cancel();
  }

  @override
  void dispose()
  {
    _isDisposed = true;
    //idempotent; deactivate normally gets here first
    _renderTimer.cancel();
    for (final ValueNotifier<IdColor> shiftNotifier in widget.rampData.shiftedColors)
    {
      shiftNotifier.removeListener(_shiftChanged);
    }
    _disposeLayers(layers: _drawingLayers);
    _drawingLayers = <RasterableLayerState>[];

    final ui.Image? lastPreview = _previewImage.value;
    _previewImage.dispose();
    _colorCards.dispose();
    if (lastPreview != null)
    {
      _retireImage(image: lastPreview);
    }
    super.dispose();
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
        if (_isDisposed)
        {
          img.dispose();
          return;
        }
        final ui.Image? previous = _previewImage.value;
        _previewImage.value = img;
        if (previous != null)
        {
          _retireImage(image: previous);
        }
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
          showName: widget.rampData.shiftedColors.length < _KPalRampWidgetOptions.colorNameShowThreshold,);

      newList.add(card);
    }
    _colorCards.value = newList;
  }

  void _settingsChanged({final bool colorCountChanged = false})
  {
    setState(() {
      widget.rampData.updateColors(colorCountChanged: colorCountChanged);
      if (colorCountChanged)
      {
        //the copies being replaced own timers and images of their own
        _disposeLayers(layers: _drawingLayers);
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
      padding: const EdgeInsets.all(_KPalRampWidgetOptions.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(_KPalRampWidgetOptions.borderRadius)),
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
                      borderRadius: const BorderRadius.all(Radius.circular(_KPalRampWidgetOptions.borderRadius)),
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
                    padding: const EdgeInsets.all(_KPalRampWidgetOptions.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                    onTap: ()
                                    {
                                      _colorCountSliderChanged(newVal: KPalConstraints.colorCountDefault.toDouble());
                                    },
                                    child: const Text("Color Count"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.colorCount.toDouble(),
                                  min: KPalConstraints.colorCountMin.toDouble(),
                                  max: KPalConstraints.colorCountMax.toDouble(),
                                  //divisions: KPalConstraints.colorCountMax - KPalConstraints.colorCountMin,
                                  onChanged: (final double newVal) {_colorCountSliderChanged(newVal: newVal);},
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          color: Theme.of(context).primaryColorDark,
                          thickness: _KPalRampWidgetOptions.dividerThickness,
                          height: _KPalRampWidgetOptions.dividerThickness,
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                    onTap: ()
                                    {
                                      _baseHueSliderChanged(newVal: KPalConstraints.baseHueDefault.toDouble());
                                    },
                                    child: const Text("Base Hue"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.baseHue.toDouble(),
                                  min: KPalConstraints.baseHueMin.toDouble(),
                                  max: KPalConstraints.baseHueMax.toDouble(),
                                  divisions: KPalConstraints.baseHueMax - KPalConstraints.baseHueMin,
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
                                flex: _KPalRampWidgetOptions.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                    onTap: ()
                                    {
                                      _hueShiftSliderChanged(newVal: KPalConstraints.hueShiftDefault.toDouble());
                                    },
                                    child: const Text("Hue Shift"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.hueShift.toDouble(),
                                  showPlusSignForPositive: true,
                                  min: KPalConstraints.hueShiftMin.toDouble(),
                                  max: KPalConstraints.hueShiftMax.toDouble(),
                                  //divisions: KPalConstraints.hueShiftMax - KPalConstraints.hueShiftMin,
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
                                flex: _KPalRampWidgetOptions.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                    onTap: ()
                                    {
                                      _hueShiftExpSliderChanged(newVal: KPalConstraints.hueShiftExpDefault);
                                    },
                                    child: const Text("↳ Exponent"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.hueShiftExp,
                                  min: KPalConstraints.hueShiftExpMin,
                                  max: KPalConstraints.hueShiftExpMax,
                                  //divisions: (KPalConstraints.hueShiftExpMax * 100.0 - KPalConstraints.hueShiftExpMin * 100.0).round(),
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
                          thickness: _KPalRampWidgetOptions.dividerThickness,
                          height: _KPalRampWidgetOptions.dividerThickness,
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                    onTap: ()
                                    {
                                      _baseSatSliderChanged(newVal: KPalConstraints.baseSatDefault.toDouble());
                                    },
                                    child: const Text("Base Sat"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.baseSat.toDouble(),
                                  min: KPalConstraints.baseSatMin.toDouble(),
                                  max: KPalConstraints.baseSatMax.toDouble(),
                                  //divisions: KPalConstraints.baseSatMax - KPalConstraints.baseSatMin,
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
                                flex: _KPalRampWidgetOptions.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                    onTap: ()
                                    {
                                      _satShiftSliderChanged(newVal: KPalConstraints.satShiftDefault.toDouble());
                                    },
                                    child: const Text("Sat Shift"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.satShift.toDouble(),
                                  min: KPalConstraints.satShiftMin.toDouble(),
                                  max: KPalConstraints.satShiftMax.toDouble(),
                                  showPlusSignForPositive: true,
                                  //divisions: KPalConstraints.satShiftMax - KPalConstraints.satShiftMin,
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
                                flex: _KPalRampWidgetOptions.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                      onTap: ()
                                      {
                                        _satShiftExpSliderChanged(newVal: KPalConstraints.satShiftExpDefault);
                                      },
                                      child: const Text("↳ Exponent"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowControlFlex,
                                child: KPixSlider(
                                  value: widget.rampData.settings.satShiftExp,
                                  min: KPalConstraints.satShiftExpMin,
                                  max: KPalConstraints.satShiftExpMax,
                                  //divisions: (KPalConstraints.satShiftExpMax * 100.0 - KPalConstraints.satShiftExpMin * 100.0).round(),
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
                              const Expanded(
                                flex: _KPalRampWidgetOptions.rowLabelFlex,
                                child: Text("Sat Curve"),
                              ),
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowControlFlex,
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
                                      label: Icon(KPixIcons.noFlat),
                                    ),
                                    ButtonSegment<SatCurve>(
                                      value: SatCurve.darkFlat,
                                      label: Icon(KPixIcons.darkFlat),
                                    ),
                                    ButtonSegment<SatCurve>(
                                      value: SatCurve.brightFlat,
                                      label: Icon(KPixIcons.brightFlat),
                                    ),
                                    ButtonSegment<SatCurve>(
                                      value: SatCurve.linear,
                                      label: Icon(KPixIcons.linear),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          color: Theme.of(context).primaryColorDark,
                          thickness: _KPalRampWidgetOptions.dividerThickness,
                          height: _KPalRampWidgetOptions.dividerThickness,
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowLabelFlex,
                                child: Tooltip(
                                  waitDuration: AppState.toolTipDuration,
                                  message: _valueToolTipMessage,
                                  child: GestureDetector(
                                      onTap: ()
                                      {
                                        _valueRangeSliderChanged(newVals: RangeValues(KPalConstraints.valueRangeMinDefault.toDouble(), KPalConstraints.valueRangeMaxDefault.toDouble()));
                                      },
                                      child: const Text("Value Range"),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: _KPalRampWidgetOptions.rowControlFlex,
                                child: KPixRangeSlider(
                                  values: RangeValues(widget.rampData.settings.valueRangeMin.toDouble(), widget.rampData.settings.valueRangeMax.toDouble()),
                                  min: KPalConstraints.valueRangeMin.toDouble(),
                                  max: KPalConstraints.valueRangeMax.toDouble(),
                                  //divisions: KPalConstraints.valueRangeMax - KPalConstraints.valueRangeMin,
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
                    padding: const EdgeInsets.all(_KPalRampWidgetOptions.padding),
                    child: ValueListenableBuilder<ui.Image?>(
                      valueListenable: _previewImage,
                      builder: (final BuildContext context, final ui.Image? img, final Widget? child) {
                        return ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(_KPalRampWidgetOptions.borderRadius)),
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
