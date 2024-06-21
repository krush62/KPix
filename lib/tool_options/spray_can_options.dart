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
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required SprayCanOptions sprayCanOptions,
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
                builder: (BuildContext context, int radius, child)
                {
                  return Slider(
                    value: radius.toDouble(),
                    min: sprayCanOptions.radiusMin.toDouble(),
                    max: sprayCanOptions.radiusMax.toDouble(),
                    divisions: sprayCanOptions.radiusMax - sprayCanOptions.radiusMin,
                    onChanged: (double newVal) {sprayCanOptions.radius.value = newVal.round();},
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
                builder: (BuildContext context, int blobSize, child)
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
                builder: (BuildContext context, int intensity, child)
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
  void changeSize(int steps, int originalValue)
  {
    radius.value = min(max(originalValue + steps, radiusMin), radiusMax);
  }

  @override
  int getSize()
  {
    return radius.value;
  }

}