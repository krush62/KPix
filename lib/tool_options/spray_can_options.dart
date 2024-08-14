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
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

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

  final ValueNotifier<int> radius = ValueNotifier(3);
  final ValueNotifier<int> blobSize = ValueNotifier(1);
  final ValueNotifier<int> intensity = ValueNotifier(8);

  SprayCanOptions({
  required this.radiusMin,
  required this.radiusMax,
  required this.radiusDefault,
  required this.blobSizeMin,
  required this.blobSizeMax,
  required this.blobSizeDefault,
  required this.intensityMin,
  required this.intensityMax,
  required this.intensityDefault
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
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Radius",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<int>(
                valueListenable: sprayCanOptions.radius,
                builder: (final BuildContext context, final int radius, final Widget? child)
                {
                  return Slider(
                    value: radius.toDouble(),
                    min: sprayCanOptions.radiusMin.toDouble(),
                    max: sprayCanOptions.radiusMax.toDouble(),
                    divisions: sprayCanOptions.radiusMax - sprayCanOptions.radiusMin,
                    onChanged: (final double newVal) {sprayCanOptions.radius.value = newVal.round();},
                    label: radius.round().toString(),
                  );
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Blob Size",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<int>(
                valueListenable: sprayCanOptions.blobSize,
                builder: (final BuildContext context, final int blobSize, final Widget? child)
                {
                  return Slider(
                    value: blobSize.toDouble(),
                    min: sprayCanOptions.blobSizeMin.toDouble(),
                    max: sprayCanOptions.blobSizeMax.toDouble(),
                    divisions: sprayCanOptions.blobSizeMax - sprayCanOptions.blobSizeMin,
                    onChanged: (double newVal) {sprayCanOptions.blobSize.value = newVal.round();},
                    label: blobSize.round().toString(),
                  );
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Intensity",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<int>(
                valueListenable: sprayCanOptions.intensity,
                builder: (final BuildContext context, final int intensity, final Widget? child)
                {
                  return Slider(
                    value: intensity.toDouble(),
                    min: sprayCanOptions.intensityMin.toDouble(),
                    max: sprayCanOptions.intensityMax.toDouble(),
                    divisions: sprayCanOptions.intensityMax - sprayCanOptions.intensityMin,
                    onChanged: (double newVal) {sprayCanOptions.intensity.value = newVal.round();},
                    label: intensity.round().toString(),
                  );
                }
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void changeSize({required int steps, required int originalValue})
  {
    radius.value = min(max(originalValue + steps, radiusMin), radiusMax);
  }

  @override
  int getSize()
  {
    return radius.value;
  }

}