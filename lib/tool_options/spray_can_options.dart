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


import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

class SprayCanOptions extends IToolOptions
{
  final int radiusMin;
  final int radiusMax;
  final int radiusDefault;
  final int blobSizeMin;
  final int blobSizeMax;
  final int blobSizeDefault;
  final int intensityMin;
  final int intensityMax;
  final int intensityDefault;

  final ValueNotifier<int> radius = ValueNotifier<int>(3);
  final ValueNotifier<int> blobSize = ValueNotifier<int>(1);
  final ValueNotifier<int> intensity = ValueNotifier<int>(8);

  SprayCanOptions({
  required this.radiusMin,
  required this.radiusMax,
  required this.radiusDefault,
  required this.blobSizeMin,
  required this.blobSizeMax,
  required this.blobSizeDefault,
  required this.intensityMin,
  required this.intensityMax,
  required this.intensityDefault,
  })
  {
    radius.value = radiusDefault;
    blobSize.value = blobSizeDefault;
    intensity.value = intensityDefault;
  }

  static Column getWidget({
    required final BuildContext context,
    required final ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required final SprayCanOptions sprayCanOptions,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ToolSliderRow<int>(
          label: "Radius",
          notifier: sprayCanOptions.radius,
          minVal: sprayCanOptions.radiusMin.toDouble(),
          maxVal: sprayCanOptions.radiusMax.toDouble(),
          //divisions: sprayCanOptions.radiusMax - sprayCanOptions.radiusMin,
          flex: toolSettingsWidgetOptions.columnWidthRatio,
        ),
        ToolSliderRow<int>(
          label:  "Blob Size",
          notifier: sprayCanOptions.blobSize,
          flex: toolSettingsWidgetOptions.columnWidthRatio,
          minVal: sprayCanOptions.blobSizeMin.toDouble(),
          maxVal: sprayCanOptions.blobSizeMax.toDouble(),
          //divisions: sprayCanOptions.blobSizeMax - sprayCanOptions.blobSizeMin,
        ),
        ToolSliderRow<int>(
          label: "Intensity",
          flex: toolSettingsWidgetOptions.columnWidthRatio,
          notifier: sprayCanOptions.intensity,
          minVal: sprayCanOptions.intensityMin.toDouble(),
          maxVal: sprayCanOptions.intensityMax.toDouble(),
          //divisions: sprayCanOptions.intensityMax - sprayCanOptions.intensityMin,
        ),
      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    radius.value = (originalValue + steps).clamp(radiusMin, radiusMax);
  }

  @override
  int getSize()
  {
    return radius.value;
  }

}
