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
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/reference_image_manager.dart';
import 'package:kpix/widgets/tools/reference_layer_options_widget.dart';

class ReferenceLayerState extends LayerState
{
  final ReferenceLayerSettings _refSettings = GetIt.I.get<PreferenceManager>().referenceLayerSettings;
  final ValueNotifier<int> opacityNotifier;
  final ValueNotifier<double> aspectRatioNotifier;
  final ValueNotifier<int> zoomNotifier;
  final ValueNotifier<double> offsetXNotifier;
  final ValueNotifier<double> offsetYNotifier;
  final ValueNotifier<ReferenceImage?> imageNotifier;

  ReferenceLayerState({required final int opacity, required final double aspectRatio, required final int zoom, required final ReferenceImage? image, required final double offsetX, required final double offsetY}) :
        opacityNotifier = ValueNotifier(opacity),
        aspectRatioNotifier = ValueNotifier(aspectRatio),
        zoomNotifier = ValueNotifier(zoom),
        offsetXNotifier = ValueNotifier(offsetX),
        offsetYNotifier = ValueNotifier(offsetY),
        imageNotifier = ValueNotifier(image)
  {
    if (image != null)
    {
      imageNotifier.value = image;
      thumbnail.value = image.image;
    }
  }

  factory ReferenceLayerState.from({required ReferenceLayerState other})
  {
    return ReferenceLayerState(aspectRatio: other.aspectRatioNotifier.value, opacity: other.opacityNotifier.value, zoom: other.zoomNotifier.value, image: other.imageNotifier.value, offsetX: other.offsetXNotifier.value, offsetY: other.offsetYNotifier.value);
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
    setZoomSliderValue(newVal: (pow(factor, 1.0 / _refSettings.zoomCurveExponent.toDouble()) * _refSettings.zoomDefault).round());
  }

  void setZoomSliderValue({required final int newVal})
  {
    if (newVal < _refSettings.zoomMin)
    {
      zoomNotifier.value = _refSettings.zoomMin;
    }
    else if (newVal > _refSettings.zoomMax)
    {
      zoomNotifier.value = _refSettings.zoomMax;
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
    return pow(zoomSliderValue.toDouble() / _refSettings.zoomDefault.toDouble(), _refSettings.zoomCurveExponent.toDouble()).toDouble();
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