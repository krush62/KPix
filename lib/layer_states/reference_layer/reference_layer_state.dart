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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/reference_image_manager.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/models/constraints/reference_layer_constraints.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/models/history/history_reference_layer.dart';
import 'package:kpix/models/view_state.dart';

class ReferenceLayerState extends LayerState
{
  final ValueNotifier<int> opacityNotifier;
  final ValueNotifier<double> aspectRatioNotifier;
  final ValueNotifier<int> zoomNotifier;
  final ValueNotifier<double> offsetXNotifier;
  final ValueNotifier<double> offsetYNotifier;
  final ValueNotifier<ReferenceImage?> imageNotifier;
  final ValueNotifier<double> brightnessNotifier;
  final ValueNotifier<double> contrastNotifier;
  final ValueNotifier<double> saturationNotifier;
  final ValueNotifier<double> warmthNotifier;

  @override IconData get icon => TablerIcons.photo;
  @override LayerMenuKind get menuKind => LayerMenuKind.reference;
  @override
  ReferenceLayerState copy({final List<RasterableLayerState>? layerStack}) =>
      ReferenceLayerState.from(other: this);

  @override
  HistoryReferenceLayer toHistoryLayer({
    required final List<HistoryRampData> ramps,
    final HistoryLayer? previousLayer,
  })
  {
    return HistoryReferenceLayer.fromReferenceLayer(referenceState: this);
  }

  ReferenceLayerState({
    required final int opacity,
    required final double aspectRatio,
    required final int zoom,
    required final ReferenceImage? image,
    required final double offsetX,
    required final double offsetY,
    required final double brightness,
    required final double contrast,
    required final double saturation,
    required final double warmth,
  }) :
        opacityNotifier = ValueNotifier<int>(opacity),
        aspectRatioNotifier = ValueNotifier<double>(aspectRatio),
        zoomNotifier = ValueNotifier<int>(zoom),
        offsetXNotifier = ValueNotifier<double>(offsetX),
        offsetYNotifier = ValueNotifier<double>(offsetY),
        brightnessNotifier = ValueNotifier<double>(brightness),
        contrastNotifier = ValueNotifier<double>(contrast),
        saturationNotifier = ValueNotifier<double>(saturation),
        warmthNotifier = ValueNotifier<double>(warmth),
        imageNotifier = ValueNotifier<ReferenceImage?>(image)
  {
    if (image != null)
    {
      imageNotifier.value = image;
      thumbnail.value = image.image;
    }
    for (final Listenable notifier in _canvasRelevantNotifiers)
    {
      notifier.addListener(_requestRepaint);
    }
  }

  late final List<Listenable> _canvasRelevantNotifiers = <Listenable>[
    opacityNotifier,
    aspectRatioNotifier,
    zoomNotifier,
    imageNotifier,
    brightnessNotifier,
    contrastNotifier,
    saturationNotifier,
    warmthNotifier,
  ];

  void _requestRepaint()
  {
    GetIt.I.get<ViewState>().repaintNotifier.repaint();
  }

  @override
  void dispose()
  {
    markDisposed();
    for (final Listenable notifier in _canvasRelevantNotifiers)
    {
      notifier.removeListener(_requestRepaint);
    }
    imageNotifier.value = null;
    thumbnail.value = null;
  }

  factory ReferenceLayerState.from({required final ReferenceLayerState other})
  {
    return ReferenceLayerState(
        aspectRatio: other.aspectRatioNotifier.value,
        opacity: other.opacity,
        zoom: other.zoomNotifier.value,
        image: other.image,
        offsetX: other.offsetX,
        offsetY: other.offsetY,
        brightness: other.brightnessNotifier.value,
        contrast: other.contrastNotifier.value,
        saturation: other.saturationNotifier.value,
        warmth: other.warmthNotifier.value,
    );
  }

  void increaseZoom({final int step = 1})
  {
    final int newVal = zoomSliderValue + step;
    setZoomSliderValue(newVal: newVal);
  }

  void decreaseZoom({final int step = 1})
  {
    final int newVal = zoomSliderValue - step;
    setZoomSliderValue(newVal: newVal);
  }

  void setZoomSliderFromZoomFactor({required final double factor})
  {
    setZoomSliderValue(newVal: (pow(factor, 1.0 / ReferenceLayerConstraints.zoomCurveExponent) * ReferenceLayerConstraints.zoomDefault).round());
  }

  void setZoomSliderValue({required final int newVal})
  {
    if (newVal < ReferenceLayerConstraints.zoomMin)
    {
      zoomNotifier.value = ReferenceLayerConstraints.zoomMin;
    }
    else if (newVal > ReferenceLayerConstraints.zoomMax)
    {
      zoomNotifier.value = ReferenceLayerConstraints.zoomMax;
    }
    else
    {
      zoomNotifier.value = newVal;
    }
  }

  int get opacity
  {
    return opacityNotifier.value;
  }

  double get aspectRatioFactorX
  {
    return (aspectRatioNotifier.value > 0) ? 1.0 + aspectRatioNotifier.value : 1.0;
  }

  double get aspectRatioFactorY
  {
    return (aspectRatioNotifier.value < 0) ? 1.0 - aspectRatioNotifier.value : 1.0;
  }

  int get zoomSliderValue
  {
    return zoomNotifier.value;
  }

  double get zoomFactor
  {
    return pow(zoomSliderValue.toDouble() / ReferenceLayerConstraints.zoomDefault.toDouble(), ReferenceLayerConstraints.zoomCurveExponent).toDouble();
  }


  double get offsetX
  {
    return offsetXNotifier.value;
  }

  double get offsetY
  {
    return offsetYNotifier.value;
  }

  ReferenceImage? get image
  {
    return imageNotifier.value;
  }

}
