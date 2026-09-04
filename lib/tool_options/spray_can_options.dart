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
import 'package:kpix/models/constraints/tool_spraycan_constraints.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

class SprayCanOptions extends IToolOptions
{


  final ValueNotifier<int> radius = ValueNotifier<int>(SpraycanConstraints.radiusDefault);
  final ValueNotifier<int> blobSize = ValueNotifier<int>(SpraycanConstraints.blobSizeDefault);
  final ValueNotifier<int> intensity = ValueNotifier<int>(SpraycanConstraints.intensityDefault);

  static Column getWidget({
    required final BuildContext context,
    required final SprayCanOptions sprayCanOptions,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ToolSliderRow<int>(
          label: "Radius",
          notifier: sprayCanOptions.radius,
          minVal: SpraycanConstraints.radiusMin.toDouble(),
          maxVal: SpraycanConstraints.radiusMax.toDouble(),
          //divisions: sprayCanOptions.radiusMax - sprayCanOptions.radiusMin,
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
        ),
        ToolSliderRow<int>(
          label:  "Blob Size",
          notifier: sprayCanOptions.blobSize,
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
          minVal: SpraycanConstraints.blobSizeMin.toDouble(),
          maxVal: SpraycanConstraints.blobSizeMax.toDouble(),
          //divisions: sprayCanOptions.blobSizeMax - sprayCanOptions.blobSizeMin,
        ),
        ToolSliderRow<int>(
          label: "Intensity",
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
          notifier: sprayCanOptions.intensity,
          minVal: SpraycanConstraints.intensityMin.toDouble(),
          maxVal: SpraycanConstraints.intensityMax.toDouble(),
          //divisions: sprayCanOptions.intensityMax - sprayCanOptions.intensityMin,
        ),
      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    radius.value = (originalValue + steps).clamp(SpraycanConstraints.radiusMin, SpraycanConstraints.radiusMax);
  }

  @override
  int getSize()
  {
    return radius.value;
  }

}
