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
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/grid_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

enum GridType
{
  rectangular,
  diagonal,
  isometric
}

const Map<int, GridType> gridTypeValueMap =
{
  0: GridType.rectangular,
  1: GridType.diagonal,
  2: GridType.isometric
};

class GridLayerSettings
{
  final int opacityDefault;
  final int opacityMin;
  final int opacityMax;
  final int brightnessDefault;
  final int brightnessMin;
  final int brightnessMax;
  final int intervalXDefault;
  final int intervalXMin;
  final int intervalXMax;
  final int intervalYDefault;
  final int intervalYMin;
  final int intervalYMax;
  final GridType gridTypeDefault;

  GridLayerSettings({
    required this.opacityDefault,
    required this.opacityMin,
    required this.opacityMax,
    required this.brightnessDefault,
    required this.brightnessMin,
    required this.brightnessMax,
    required this.intervalXDefault,
    required this.intervalXMin,
    required this.intervalXMax,
    required this.intervalYDefault,
    required this.intervalYMin,
    required this.intervalYMax,
    required int gridTypeValue}) : gridTypeDefault = gridTypeValueMap[gridTypeValue] ?? GridType.rectangular;

}

class GridLayerOptionsWidget extends StatefulWidget
{
  final GridLayerState gridState;
  const GridLayerOptionsWidget({super.key, required this.gridState});

  @override
  State<GridLayerOptionsWidget> createState() => _GridLayerOptionsWidgetState();
}

class _GridLayerOptionsWidgetState extends State<GridLayerOptionsWidget>
{
  final ToolSettingsWidgetOptions _toolSettingsWidgetOptions = GetIt.I.get<PreferenceManager>().toolSettingsWidgetOptions;
  final GridLayerSettings _gridSettings = GetIt.I.get<PreferenceManager>().gridLayerSettings;

  @override
  Widget build(BuildContext context)
  {
    return Material(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: EdgeInsets.all(_toolSettingsWidgetOptions.padding),
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
                          "Type",
                          style: Theme.of(context).textTheme.labelLarge,
                        )
                    ),
                  ),
                  Expanded(
                    flex: _toolSettingsWidgetOptions.columnWidthRatio,
                    child: ValueListenableBuilder<GridType>(
                      valueListenable: widget.gridState.gridTypeNotifier,
                      builder: (final BuildContext context, final GridType gridType, final Widget? child) {
                        return SegmentedButton(
                          segments: [
                            ButtonSegment(
                              value: GridType.rectangular,
                              label: Text("RECT", style: Theme.of(context).textTheme.labelSmall!.apply(color: gridType == GridType.rectangular ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight))
                            ),
                            ButtonSegment(
                              value: GridType.diagonal,
                                label: Text("DIAG", style: Theme.of(context).textTheme.labelSmall!.apply(color: gridType == GridType.diagonal ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight))
                            ),
                            ButtonSegment(
                              value: GridType.isometric,
                                label: Text("ISO", style: Theme.of(context).textTheme.labelSmall!.apply(color: gridType == GridType.isometric ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight))
                            )
                          ],
                          selected: <GridType>{gridType},
                          emptySelectionAllowed: false,
                          multiSelectionEnabled: false,
                          showSelectedIcon: false,
                          onSelectionChanged: (final Set<GridType> types)
                          {
                            widget.gridState.gridTypeNotifier.value = types.first;
                          },
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
                          "Opacity",
                          style: Theme.of(context).textTheme.labelLarge,
                        )
                    ),
                  ),
                  Expanded(
                    flex: _toolSettingsWidgetOptions.columnWidthRatio,
                    child: ValueListenableBuilder<int>(
                      valueListenable: widget.gridState.opacityNotifier,
                      builder: (final BuildContext context, final int opacity, final Widget? child) {
                        return Slider(
                          value: opacity.toDouble(),
                          min: _gridSettings.opacityMin.toDouble(),
                          max: _gridSettings.opacityMax.toDouble(),
                          divisions: _gridSettings.opacityMax - _gridSettings.opacityMin,
                          onChanged: (final double newVal) {
                            widget.gridState.opacityNotifier.value = newVal.round();
                          },
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
                        "Brightness",
                        style: Theme.of(context).textTheme.labelLarge,
                      )
                    ),
                  ),
                  Expanded(
                    flex: _toolSettingsWidgetOptions.columnWidthRatio,
                    child: ValueListenableBuilder<int>(
                      valueListenable: widget.gridState.brightnessNotifier,
                      builder: (final BuildContext context, final int brightness, final Widget? child) {
                        return Slider(
                          value: brightness.toDouble(),
                          min: _gridSettings.brightnessMin.toDouble(),
                          max: _gridSettings.brightnessMax.toDouble(),
                          divisions: _gridSettings.brightnessMax - _gridSettings.brightnessMin,
                          onChanged: (final double newVal) {
                            widget.gridState.brightnessNotifier.value = newVal.round();
                          },
                          label: brightness.round().toString(),
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
                        "Interval X",
                        style: Theme.of(context).textTheme.labelLarge,
                      )
                    ),
                  ),
                  Expanded(
                    flex: _toolSettingsWidgetOptions.columnWidthRatio,
                    child: ValueListenableBuilder<int>(
                      valueListenable: widget.gridState.intervalXNotifier,
                      builder: (final BuildContext context, final int intervalX, final Widget? child) {
                        return Slider(
                          value: intervalX.toDouble(),
                          min: _gridSettings.intervalXMin.toDouble(),
                          max: _gridSettings.intervalXMax.toDouble(),
                          divisions: _gridSettings.intervalXMax - _gridSettings.intervalXMin,
                          onChanged: (final double newVal) {
                            widget.gridState.intervalXNotifier.value = newVal.round();
                          },
                          label: intervalX.round().toString(),
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
                        "Interval Y",
                        style: Theme.of(context).textTheme.labelLarge,
                      )
                    ),
                  ),
                  Expanded(
                    flex: _toolSettingsWidgetOptions.columnWidthRatio,
                    child: ValueListenableBuilder<int>(
                      valueListenable: widget.gridState.intervalYNotifier,
                      builder: (final BuildContext context, final int intervalY, final Widget? child) {
                        return Slider(
                          value: intervalY.toDouble(),
                          min: _gridSettings.intervalYMin.toDouble(),
                          max: _gridSettings.intervalYMax.toDouble(),
                          divisions: _gridSettings.intervalYMax - _gridSettings.intervalYMin,
                          onChanged: (final double newVal) {
                            widget.gridState.intervalYNotifier.value = newVal.round();
                          },
                          label: intervalY.round().toString(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          )
        )
      )
    );
  }
}