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

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/palette_adjustment_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/palette_adjustment.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/palette/color_entry_widget.dart';

abstract final class PaletteAdjustmentWidgetOptions
{
  static const double outsidePadding = 16.0;
  static const double padding = 8.0;
  static const double borderRadius = 8.0;
  static const double maxWidth = 1600.0;
  static const double maxHeight = 1000.0;
  static const int smokeOpacity = 128;
  static const int renderIntervalMs = 100;
  static const int rowLabelFlex = 7;
  static const int rowControlFlex = 20;
  static const int controlsFlex = 3;
  static const int rampsFlex = 2;
  static const double resetButtonSize = 32.0;
  static const double switchWidth = 64.0;
  static const double swatchHeight = 28.0;
  static const double swatchMargin = 2.0;
  static const double swatchRadius = 4.0;
  static const double indicatorSize = 14.0;
  static const double previewHintSize = 32.0;
  static const double previewHintBlur = 3.0;
}

class PaletteAdjustmentWidget extends StatefulWidget
{
  final Function() dismiss;
  const PaletteAdjustmentWidget({super.key, required this.dismiss});

  @override
  State<PaletteAdjustmentWidget> createState() => _PaletteAdjustmentWidgetState();
}

class _PaletteAdjustmentWidgetState extends State<PaletteAdjustmentWidget>
{
  final PaletteState _paletteState = GetIt.I.get<PaletteState>();
  final DocumentState _documentState = GetIt.I.get<DocumentState>();
  final CanvasState _canvasState = GetIt.I.get<CanvasState>();

  final ValueNotifier<PaletteAdjustment> _adjustment = ValueNotifier<PaletteAdjustment>(const PaletteAdjustment());

  /// The ramps of the palette with the settings they had when the dialog was
  /// opened.
  ///
  /// Every adjustment starts from those, so the sliders stay absolute and going
  /// back to the defaults restores the palette exactly.
  late final List<KPalRampData> _ramps;
  final Map<KPalRampData, KPalRampSettings> _originalSettings = <KPalRampData, KPalRampSettings>{};
  final Map<KPalRampData, ValueNotifier<bool>> _rampIncluded = <KPalRampData, ValueNotifier<bool>>{};

  final ValueNotifier<ui.Image?> _previewImage = ValueNotifier<ui.Image?>(null);

  /// The preview as it was when the dialog opened, shown while the preview is
  /// held down.
  ///
  /// This is the first image the render produced, so it is the handle
  /// [_previewImage] starts out with as well; it is retired when the dialog
  /// closes rather than when the preview moves on.
  ui.Image? _originalImage;
  final ValueNotifier<bool> _showOriginal = ValueNotifier<bool>(false);

  final List<ui.Image> _imagesToRetire = <ui.Image>[];
  late Timer _renderTimer;
  late List<RasterableLayerState> _previewLayers;
  bool _hasRenderChanges = false;
  bool _isDisposed = false;

  @override
  void initState()
  {
    super.initState();
    _ramps = List<KPalRampData>.from(_paletteState.colorRamps);
    for (final KPalRampData ramp in _ramps)
    {
      _originalSettings[ramp] = KPalRampSettings.from(other: ramp.settings);
      _rampIncluded[ramp] = ValueNotifier<bool>(true);
    }
    _previewLayers = _copyLayers(originalLayers: _documentState.timeline.selectedFrame!.layerList.getVisibleRasterLayers());
    _rasterPreview();
    _renderTimer = Timer.periodic(const Duration(milliseconds: PaletteAdjustmentWidgetOptions.renderIntervalMs), (final Timer t) {_renderCheck();});
  }

  /// Puts every preview layer in for a new raster.
  ///
  /// The first raster has to be forced as well: a shading layer renders against
  /// the layers below it, and those are not in the stack yet while the copies
  /// are being made, so a copy made first would come out of [_copyLayers]
  /// rendered against nothing.
  void _rasterPreview()
  {
    for (final RasterableLayerState layer in _previewLayers)
    {
      layer.doManualRaster = true;
    }
    _hasRenderChanges = true;
  }

  /// Copies the visible layers, so the preview can be rastered with the adjusted
  /// colors while the layers of the document keep the ones they were opened
  /// with.
  List<RasterableLayerState> _copyLayers({required final Iterable<RasterableLayerState> originalLayers})
  {
    final List<RasterableLayerState> layers = <RasterableLayerState>[];
    for (final RasterableLayerState originalLayer in originalLayers)
    {
      layers.add(originalLayer.copy(layerStack: layers) as RasterableLayerState);
    }
    return layers;
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
  void deactivate()
  {
    super.deactivate();
    _renderTimer.cancel();
  }

  @override
  void dispose()
  {
    _isDisposed = true;
    //idempotent; deactivate normally gets here first
    _renderTimer.cancel();
    _disposeLayers(layers: _previewLayers);
    _previewLayers = <RasterableLayerState>[];
    for (final ValueNotifier<bool> included in _rampIncluded.values)
    {
      included.dispose();
    }
    _adjustment.dispose();
    _showOriginal.dispose();

    final ui.Image? lastPreview = _previewImage.value;
    final ui.Image? original = _originalImage;
    _originalImage = null;
    _previewImage.dispose();
    if (lastPreview != null)
    {
      _retireImage(image: lastPreview);
    }
    if (original != null && original != lastPreview)
    {
      _retireImage(image: original);
    }
    super.dispose();
  }

  void _renderCheck()
  {
    final bool hasRasterizingLayers = _previewLayers.where((final RasterableLayerState l) => l.visibilityState.value == LayerVisibilityState.visible && (l.doManualRaster || l.isRasterizing)).isNotEmpty;
    if (_hasRenderChanges && !hasRasterizingLayers)
    {
      getImageFromLayers(canvasSize: _canvasState.canvasSize, layerCollection: _documentState.timeline.selectedFrame!.layerList, selection: _documentState.selectionState.selection, layerStack: _previewLayers).then((final ui.Image img) {
        if (_isDisposed)
        {
          img.dispose();
          return;
        }
        final ui.Image? previous = _previewImage.value;
        _previewImage.value = img;
        _originalImage ??= img;
        if (previous != null && previous != _originalImage)
        {
          _retireImage(image: previous);
        }
      });
      _hasRenderChanges = false;
    }
  }

  void _adjustmentChanged({required final PaletteAdjustment adjustment})
  {
    _adjustment.value = adjustment;
    _applyToRamps();
  }

  void _rampInclusionChanged({required final KPalRampData ramp, required final bool included})
  {
    _rampIncluded[ramp]!.value = included;
    _applyToRamps();
  }

  /// Rebuilds every ramp from the settings it was opened with.
  ///
  /// The ramps of the document are changed in place, so the color references on
  /// the layers stay valid and only the preview has to be rastered again.
  void _applyToRamps()
  {
    final PaletteAdjustment adjustment = _adjustment.value;
    for (final KPalRampData ramp in _ramps)
    {
      final KPalRampSettings originalSettings = _originalSettings[ramp]!;
      ramp.settings.setFrom(
        other: _rampIncluded[ramp]!.value
            ? adjustRampSettings(settings: originalSettings, adjustment: adjustment)
            : originalSettings,
      );
      ramp.updateColors(colorCountChanged: false);
    }
    _rasterPreview();
  }

  void _resetPressed()
  {
    _adjustmentChanged(adjustment: const PaletteAdjustment());
  }

  void _acceptPressed()
  {
    _paletteState.paletteAdjusted();
    widget.dismiss();
  }

  void _cancelPressed()
  {
    for (final KPalRampData ramp in _ramps)
    {
      ramp.settings.setFrom(other: _originalSettings[ramp]!);
      ramp.updateColors(colorCountChanged: false);
    }
    _paletteState.paletteAdjusted(addToHistoryStack: false);
    widget.dismiss();
  }

  Widget _getSliderRow({
    required final String label,
    required final double value,
    required final double min,
    required final double max,
    required final double defaultValue,
    required final ValueChanged<double> onChanged,
    required final AppLocalizations l10n,
  })
  {
    return Expanded(
      child: Row(
        children: <Widget>[
          Expanded(
            flex: PaletteAdjustmentWidgetOptions.rowLabelFlex,
            child: Tooltip(
              message: l10n.pressToReset,
              child: GestureDetector(
                onTap: () {onChanged(defaultValue);},
                child: Text(label),
              ),
            ),
          ),
          Expanded(
            flex: PaletteAdjustmentWidgetOptions.rowControlFlex,
            child: KPixSlider(
              value: value,
              min: min,
              max: max,
              showPlusSignForPositive: true,
              onChanged: onChanged,
              textStyle: Theme.of(context).textTheme.bodyLarge!,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: PaletteAdjustmentWidgetOptions.padding),
            child: IconButton.outlined(
              tooltip: l10n.resetValue,
              icon: const Icon(TablerIcons.refresh),
              //nothing to take back while the slider sits on its default
              onPressed: value == defaultValue ? null : () {onChanged(defaultValue);},
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(PaletteAdjustmentWidgetOptions.resetButtonSize, PaletteAdjustmentWidgetOptions.resetButtonSize),
                maximumSize: const Size(PaletteAdjustmentWidgetOptions.resetButtonSize, PaletteAdjustmentWidgetOptions.resetButtonSize),
                iconSize: PaletteAdjustmentWidgetOptions.resetButtonSize - PaletteAdjustmentWidgetOptions.padding,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSliders({required final AppLocalizations l10n})
  {
    return ValueListenableBuilder<PaletteAdjustment>(
      valueListenable: _adjustment,
      builder: (final BuildContext context, final PaletteAdjustment adjustment, final Widget? child)
      {
        return Padding(
          padding: const EdgeInsets.all(PaletteAdjustmentWidgetOptions.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _getSliderRow(
                l10n: l10n,
                label: l10n.brightness,
                value: adjustment.brightness,
                min: PaletteAdjustmentConstraints.brightnessMin,
                max: PaletteAdjustmentConstraints.brightnessMax,
                defaultValue: PaletteAdjustmentConstraints.brightnessDefault,
                onChanged: (final double newVal) {_adjustmentChanged(adjustment: adjustment.copyWith(brightness: newVal));},
              ),
              _getSliderRow(
                l10n: l10n,
                label: l10n.contrast,
                value: adjustment.contrast,
                min: PaletteAdjustmentConstraints.contrastMin,
                max: PaletteAdjustmentConstraints.contrastMax,
                defaultValue: PaletteAdjustmentConstraints.contrastDefault,
                onChanged: (final double newVal) {_adjustmentChanged(adjustment: adjustment.copyWith(contrast: newVal));},
              ),
              _getSliderRow(
                l10n: l10n,
                label: l10n.saturation,
                value: adjustment.saturation,
                min: PaletteAdjustmentConstraints.saturationMin,
                max: PaletteAdjustmentConstraints.saturationMax,
                defaultValue: PaletteAdjustmentConstraints.saturationDefault,
                onChanged: (final double newVal) {_adjustmentChanged(adjustment: adjustment.copyWith(saturation: newVal));},
              ),
              _getSliderRow(
                l10n: l10n,
                label: l10n.whiteBalance,
                value: adjustment.whiteBalance,
                min: PaletteAdjustmentConstraints.whiteBalanceMin,
                max: PaletteAdjustmentConstraints.whiteBalanceMax,
                defaultValue: PaletteAdjustmentConstraints.whiteBalanceDefault,
                onChanged: (final double newVal) {_adjustmentChanged(adjustment: adjustment.copyWith(whiteBalance: newVal));},
              ),
              _getSliderRow(
                l10n: l10n,
                label: l10n.tint,
                value: adjustment.tint,
                min: PaletteAdjustmentConstraints.tintMin,
                max: PaletteAdjustmentConstraints.tintMax,
                defaultValue: PaletteAdjustmentConstraints.tintDefault,
                onChanged: (final double newVal) {_adjustmentChanged(adjustment: adjustment.copyWith(tint: newVal));},
              ),
              _getSliderRow(
                l10n: l10n,
                label: l10n.hueShift,
                value: adjustment.hueShift,
                min: PaletteAdjustmentConstraints.hueShiftMin,
                max: PaletteAdjustmentConstraints.hueShiftMax,
                defaultValue: PaletteAdjustmentConstraints.hueShiftDefault,
                onChanged: (final double newVal) {_adjustmentChanged(adjustment: adjustment.copyWith(hueShift: newVal));},
              ),
              _getSliderRow(
                l10n: l10n,
                label: l10n.hueSpread,
                value: adjustment.hueSpread,
                min: PaletteAdjustmentConstraints.hueSpreadMin,
                max: PaletteAdjustmentConstraints.hueSpreadMax,
                defaultValue: PaletteAdjustmentConstraints.hueSpreadDefault,
                onChanged: (final double newVal) {_adjustmentChanged(adjustment: adjustment.copyWith(hueSpread: newVal));},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getPreview({required final AppLocalizations l10n})
  {
    return Padding(
      padding: const EdgeInsets.all(PaletteAdjustmentWidgetOptions.padding),
      child: Tooltip(
        message: l10n.holdToShowOriginal,
        //a long press is how the original is asked for, the hover is left
        triggerMode: TooltipTriggerMode.manual,
        child: GestureDetector(
          //the image leaves the bars beside it unpainted, and they are part of
          //the target as much as the image itself
          behavior: HitTestBehavior.opaque,
          onTapDown: (final TapDownDetails details) {_showOriginal.value = true;},
          onTapUp: (final TapUpDetails details) {_showOriginal.value = false;},
          onTapCancel: () {_showOriginal.value = false;},
          child: ValueListenableBuilder<bool>(
            valueListenable: _showOriginal,
            builder: (final BuildContext context, final bool showOriginal, final Widget? child) {
              return ValueListenableBuilder<ui.Image?>(
                valueListenable: _previewImage,
                builder: (final BuildContext context, final ui.Image? img, final Widget? child) {
                  final ui.Image? shownImage = showOriginal ? (_originalImage ?? img) : img;
                  //giving the box the shape of the image leaves no bars beside
                  //it, so the corner of the box is the corner of the image
                  return Center(
                    child: AspectRatio(
                      aspectRatio: shownImage != null
                          ? shownImage.width / shownImage.height
                          : _canvasState.canvasSize.x / _canvasState.canvasSize.y,
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(PaletteAdjustmentWidgetOptions.borderRadius)),
                              child: RawImage(
                                fit: BoxFit.contain,
                                filterQuality: ui.FilterQuality.none,
                                color: Theme.of(context).primaryColorDark,
                                colorBlendMode: ui.BlendMode.dstATop,
                                image: shownImage,
                              ),
                            ),
                          ),
                          Positioned(
                            top: PaletteAdjustmentWidgetOptions.padding / 2.0,
                            right: PaletteAdjustmentWidgetOptions.padding / 2.0,
                            //shows that there is something to press here; the
                            //image below it can be any color, so the icon
                            //carries its own outline
                            child: Icon(
                              TablerIcons.click,
                              size: PaletteAdjustmentWidgetOptions.previewHintSize,
                              color: Theme.of(context).primaryColorLight,
                              shadows: <Shadow>[
                                Shadow(color: Theme.of(context).primaryColorDark, blurRadius: PaletteAdjustmentWidgetOptions.previewHintBlur),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _getRamps({required final AppLocalizations l10n})
  {
    return Padding(
      padding: const EdgeInsets.all(PaletteAdjustmentWidgetOptions.padding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorDark,
          borderRadius: const BorderRadius.all(Radius.circular(PaletteAdjustmentWidgetOptions.borderRadius)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(PaletteAdjustmentWidgetOptions.padding / 2.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final KPalRampData ramp in _ramps)
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: PaletteAdjustmentWidgetOptions.switchWidth,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _rampIncluded[ramp]!,
                          builder: (final BuildContext context, final bool included, final Widget? child) {
                            return Tooltip(
                              message: l10n.includeRampInAdjustment,
                              child: Switch(
                                value: included,
                                onChanged: (final bool newVal) {_rampInclusionChanged(ramp: ramp, included: newVal);},
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            for (int index = 0; index < ramp.shiftedColors.length; index++)
                              _AdjustmentColorEntry(ramp: ramp, index: index),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Center(
      child: KPixAnimationWidget(
        constraints: const BoxConstraints(
          maxHeight: PaletteAdjustmentWidgetOptions.maxHeight,
          maxWidth: PaletteAdjustmentWidgetOptions.maxWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.paletteAdjustments,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            Expanded(
              flex: PaletteAdjustmentWidgetOptions.controlsFlex,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: _getSliders(l10n: l10n)),
                  Expanded(child: _getPreview(l10n: l10n)),
                ],
              ),
            ),
            Expanded(
              flex: PaletteAdjustmentWidgetOptions.rampsFlex,
              child: _getRamps(l10n: l10n),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(PaletteAdjustmentWidgetOptions.padding),
                    child: IconButton.outlined(
                      tooltip: l10n.cancel,
                      icon: const Icon(TablerIcons.x),
                      onPressed: _cancelPressed,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(PaletteAdjustmentWidgetOptions.padding),
                    child: IconButton.outlined(
                      tooltip: l10n.resetAllAdjustments,
                      icon: const Icon(TablerIcons.refresh),
                      onPressed: _resetPressed,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(PaletteAdjustmentWidgetOptions.padding),
                    child: IconButton.outlined(
                      tooltip: l10n.apply,
                      icon: const Icon(TablerIcons.check),
                      onPressed: _acceptPressed,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A palette color in the adjustment dialog with the clipping indicators of the
/// color on top of it.
class _AdjustmentColorEntry extends StatelessWidget
{
  final KPalRampData ramp;
  final int index;
  const _AdjustmentColorEntry({required this.ramp, required this.index});

  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Expanded(
      child: ValueListenableBuilder<IdColor>(
        valueListenable: ramp.shiftedColors[index],
        builder: (final BuildContext context, final IdColor idColor, final Widget? child)
        {
          final bool valueClipping = hasValueClipping(ramp: ramp, index: index);
          final bool saturationClipping = hasSaturationClipping(ramp: ramp, index: index);
          final StringBuffer tooltip = StringBuffer(colorTooltipText(idColor: idColor));
          if (valueClipping)
          {
            tooltip.write("\n${l10n.valueClipping}");
          }
          if (saturationClipping)
          {
            tooltip.write("\n${l10n.saturationClipping}");
          }
          //the indicators sit on the color itself, so they take the side of the
          //brightness scale the color is not on
          final Color indicatorColor = idColor.hsv.v > 0.5 ? Colors.black : Colors.white;
          return Tooltip(
            message: tooltip.toString(),
            textAlign: TextAlign.center,
            child: Container(
              height: PaletteAdjustmentWidgetOptions.swatchHeight,
              margin: const EdgeInsets.all(PaletteAdjustmentWidgetOptions.swatchMargin),
              decoration: BoxDecoration(
                color: idColor.color,
                borderRadius: const BorderRadius.all(Radius.circular(PaletteAdjustmentWidgetOptions.swatchRadius)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (valueClipping) Icon(TablerIcons.sun_filled, size: PaletteAdjustmentWidgetOptions.indicatorSize, color: indicatorColor),
                  if (saturationClipping) Icon(TablerIcons.droplet_filled, size: PaletteAdjustmentWidgetOptions.indicatorSize, color: indicatorColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
