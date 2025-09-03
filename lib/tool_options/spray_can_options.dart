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
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Radius",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<int>(
                valueListenable: sprayCanOptions.radius,
                builder: (final BuildContext context, final int radius, final Widget? child)
                {
                  return KPixSlider(
                    value: radius.toDouble(),
                    min: sprayCanOptions.radiusMin.toDouble(),
                    max: sprayCanOptions.radiusMax.toDouble(),
                    //divisions: sprayCanOptions.radiusMax - sprayCanOptions.radiusMin,
                    onChanged: (final double newVal) {sprayCanOptions.radius.value = newVal.round();},
                    textStyle: Theme.of(context).textTheme.bodyLarge!,
                  );
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Blob Size",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<int>(
                valueListenable: sprayCanOptions.blobSize,
                builder: (final BuildContext context, final int blobSize, final Widget? child)
                {
                  return KPixSlider(
                    value: blobSize.toDouble(),
                    min: sprayCanOptions.blobSizeMin.toDouble(),
                    max: sprayCanOptions.blobSizeMax.toDouble(),
                    //divisions: sprayCanOptions.blobSizeMax - sprayCanOptions.blobSizeMin,
                    onChanged: (final double newVal) {sprayCanOptions.blobSize.value = newVal.round();},
                    textStyle: Theme.of(context).textTheme.bodyLarge!,
                  );
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Intensity",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<int>(
                valueListenable: sprayCanOptions.intensity,
                builder: (final BuildContext context, final int intensity, final Widget? child)
                {
                  return KPixSlider(
                    value: intensity.toDouble(),
                    min: sprayCanOptions.intensityMin.toDouble(),
                    max: sprayCanOptions.intensityMax.toDouble(),
                    //divisions: sprayCanOptions.intensityMax - sprayCanOptions.intensityMin,
                    onChanged: (final double newVal) {sprayCanOptions.intensity.value = newVal.round();},
                    textStyle: Theme.of(context).textTheme.bodyLarge!,
                  );
                },
              ),
            ),
          ],
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
