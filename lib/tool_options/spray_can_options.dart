import 'package:flutter/material.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/typedefs.dart';
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

  int radius = 3;
  int blobSize = 1;
  int intensity = 8;

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
    radius = radiusDefault;
    blobSize = blobSizeDefault;
    intensity = intensityDefault;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required SprayCanOptions sprayCanOptions,
    SprayCanRadiusChanged? sprayCanRadiusChanged,
    SprayCanBlobSizeChanged? sprayCanBlobSizeChanged,
    SprayCanIntensityChanged? sprayCanIntensityChanged
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
              child: Slider(
                value: sprayCanOptions.radius.toDouble(),
                min: sprayCanOptions.radiusMin.toDouble(),
                max: sprayCanOptions.radiusMax.toDouble(),
                divisions: sprayCanOptions.radiusMax - sprayCanOptions.radiusMin,
                onChanged: sprayCanRadiusChanged,
                label: sprayCanOptions.radius.round().toString(),
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
              child: Slider(
                value: sprayCanOptions.blobSize.toDouble(),
                min: sprayCanOptions.blobSizeMin.toDouble(),
                max: sprayCanOptions.blobSizeMax.toDouble(),
                divisions: sprayCanOptions.blobSizeMax - sprayCanOptions.blobSizeMin,
                onChanged: sprayCanBlobSizeChanged,
                label: sprayCanOptions.blobSize.round().toString(),
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
              child: Slider(
                value: sprayCanOptions.intensity.toDouble(),
                min: sprayCanOptions.intensityMin.toDouble(),
                max: sprayCanOptions.intensityMax.toDouble(),
                divisions: sprayCanOptions.intensityMax - sprayCanOptions.intensityMin,
                onChanged: sprayCanIntensityChanged,
                label: sprayCanOptions.intensity.round().toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}