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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/main/layer_widget.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

class ReferenceLayerSettings
{
  final int opacityDefault;
  final int opacityMin;
  final int opacityMax;
  final double aspectRatioDefault;
  final double aspectRatioMin;
  final double aspectRatioMax;
  final int zoomDefault;
  final int zoomMin;
  final int zoomMax;

  ReferenceLayerSettings({
    required this.opacityDefault,
    required this.opacityMin,
    required this.opacityMax,
    required this.aspectRatioDefault,
    required this.aspectRatioMin,
    required this.aspectRatioMax,
    required this.zoomDefault,
    required this.zoomMin,
    required this.zoomMax});
}

class ReferenceLayerOptionsWidget extends StatefulWidget
{
  final ReferenceLayerState referenceState;
  const ReferenceLayerOptionsWidget({super.key, required this.referenceState});

  @override
  State<ReferenceLayerOptionsWidget> createState() => _ReferenceLayerOptionsWidgetState();
}

class _ReferenceLayerOptionsWidgetState extends State<ReferenceLayerOptionsWidget>
{
  final ToolSettingsWidgetOptions toolSettingsWidgetOptions = GetIt.I.get<PreferenceManager>().toolSettingsWidgetOptions;
  final ReferenceLayerSettings refSettings = GetIt.I.get<PreferenceManager>().referenceLayerSettings;

  void _onLoadPressed()
  {

  }

  void _expandHorizontal()
  {

  }

  void _expandVertical()
  {

  }

  void _fill()
  {

  }


  @override
  Widget build(BuildContext context)
  {
    return Material (
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: EdgeInsets.all(toolSettingsWidgetOptions.padding),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
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
                          "File",
                          style: Theme.of(context).textTheme.labelLarge,
                        )
                    ),
                  ),
                  Expanded(
                    flex: toolSettingsWidgetOptions.columnWidthRatio,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Align(
                            alignment: Alignment.center,
                            child: ValueListenableBuilder<String>(
                              valueListenable: widget.referenceState.pathNotifier,
                              builder: (final BuildContext context, final String path, final Widget? child) {
                                return Text(
                                  path.isEmpty ? "<NO FILE LOADED>" : path,
                                  style: Theme.of(context).textTheme.labelSmall,
                                );
                              },
                            )
                          ),
                        ),
                        SizedBox(
                          width: toolSettingsWidgetOptions.padding,
                        ),
                        Expanded(
                          flex: 1,
                          child: Tooltip(
                            waitDuration: AppState.toolTipDuration,
                            message: "Open Reference File",
                            child: IconButton.outlined(
                              onPressed: _onLoadPressed,
                              icon: FaIcon(
                                FontAwesomeIcons.file
                              )
                            ),
                          )
                        )
                      ],
                    ),
                  )
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
                        "Opacity",
                        style: Theme.of(context).textTheme.labelLarge,
                      )
                    ),
                  ),
                  Expanded(
                    flex: toolSettingsWidgetOptions.columnWidthRatio,
                    child: ValueListenableBuilder<int>(
                      valueListenable: widget.referenceState.opacityNotifier,
                      builder: (final BuildContext context, final int opacity, final Widget? child){
                        return Slider(
                          value: opacity.toDouble(),
                          min: refSettings.opacityMin.toDouble(),
                          max: refSettings.opacityMax.toDouble(),
                          divisions: refSettings.opacityMax - refSettings.opacityMin,
                          onChanged: (final double newVal) {widget.referenceState.opacityNotifier.value = newVal.round();},
                          label: opacity.round().toString(),
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
                        "Aspect Ratio",
                        style: Theme.of(context).textTheme.labelLarge,
                      )
                    ),
                  ),
                  Expanded(
                    flex: toolSettingsWidgetOptions.columnWidthRatio,
                    child: ValueListenableBuilder<double>(
                      valueListenable: widget.referenceState.aspectRatioNotifier,
                      builder: (final BuildContext context, final double aspectRatio, final Widget? child)
                      {
                        return Slider(
                          value: aspectRatio.toDouble(),
                          min: refSettings.aspectRatioMin.toDouble(),
                          max: refSettings.aspectRatioMax.toDouble(),
                          onChanged: (final double newVal) {widget.referenceState.aspectRatioNotifier.value = newVal;},
                          label: aspectRatio.toString(),
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
                        "Zoom",
                        style: Theme.of(context).textTheme.labelLarge,
                      )
                    ),
                  ),
                  Expanded(
                    flex: toolSettingsWidgetOptions.columnWidthRatio,
                    child: ValueListenableBuilder<int>(
                      valueListenable: widget.referenceState.zoomNotifier,
                      builder: (final BuildContext context, final int zoom, final Widget? child) {
                        return Slider(
                          value: zoom.toDouble(),
                          min: refSettings.zoomMin.toDouble(),
                          max: refSettings.zoomMax.toDouble(),
                          divisions: refSettings.zoomMax - refSettings.zoomMin,
                          onChanged: (final double newVal) {widget.referenceState.zoomNotifier.value = newVal.round();},
                          label: zoom.round().toString(),
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
                    child: IconButton.outlined(
                      onPressed: _expandHorizontal,
                      icon: FaIcon(
                        FontAwesomeIcons.arrowsLeftRight
                      )
                    )
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton.outlined(
                      onPressed: _expandVertical,
                      icon: FaIcon(
                        FontAwesomeIcons.arrowsUpDown
                      )
                    )
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton.outlined(
                      onPressed: _fill,
                      icon: FaIcon(
                        FontAwesomeIcons.arrowsUpDownLeftRight
                      ),
                    )
                  ),
                ],
              ),
            ],
          ),
        ),
      )
    );
  }
}
