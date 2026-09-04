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
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/controls/kpix_range_slider.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/tools/constraints/grid_layer_constraints.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

bool isPerspectiveGridType({required final GridType gridType})
{
  return gridType == GridType.onePointPerspective || gridType == GridType.twoPointPerspective || gridType == GridType.threePointPerspective;
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
  late GridType lastNormalGridType;
  late GridType lastPerspectiveGridType;

  @override
  void initState()
  {
    super.initState();
    if (!isPerspectiveGridType(gridType: widget.gridState.gridType))
    {
      lastNormalGridType = widget.gridState.gridType;
      lastPerspectiveGridType = GridType.onePointPerspective;
    }
    else
    {
      lastNormalGridType = GridType.rectangular;
      lastPerspectiveGridType = widget.gridState.gridType;
    }
  }

  @override
  Widget build(final BuildContext context)
  {
    return Material(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(ToolSettingsWidgetOptions.padding),
        child: SingleChildScrollView(
          child: ValueListenableBuilder<GridType>(
            valueListenable: widget.gridState.gridTypeNotifier,
            builder: (final BuildContext context, final GridType gridType, final Widget? child) {
              final bool isPerspective = isPerspectiveGridType(gridType: gridType);
              if (widget.gridState.vanishingPoint1 > widget.gridState.vanishingPoint2)
              {
                widget.gridState.vanishingPoint1Notifier.value = widget.gridState.vanishingPoint2;
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SegmentedButton<bool>(
                    selected: <bool>{isPerspective},
                    showSelectedIcon: false,
                    onSelectionChanged: (final Set<bool> types)
                    {
                      if (!types.first)
                      {
                        widget.gridState.gridTypeNotifier.value = lastNormalGridType;
                      }
                      else
                      {
                        widget.gridState.gridTypeNotifier.value = lastPerspectiveGridType;
                      }
                      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: widget.gridState);
                    },
                    segments: <ButtonSegment<bool>>[
                      ButtonSegment<bool>(
                        value: false,
                        label: Tooltip(waitDuration: AppState.toolTipDuration, message: "Grid", child: Text("GRID", style: Theme.of(context).textTheme.labelSmall!.apply(color: !isPerspective ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight))),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Tooltip(waitDuration: AppState.toolTipDuration, message: "Perspective", child: Text("PERSPECTIVE", style: Theme.of(context).textTheme.labelSmall!.apply(color: isPerspective ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight))),
                      ),
                    ],
                  ),
                  SegmentedButton<GridType>(
                    segments: <ButtonSegment<GridType>>[
                      for (final GridType g in GridType.values)
                        if (isPerspectiveGridType(gridType: g) == isPerspective)
                          ButtonSegment<GridType>(
                            value: g,
                            label: Tooltip(waitDuration: AppState.toolTipDuration, message: g.name, child: Text(g.label, style: Theme.of(context).textTheme.labelSmall!.apply(color: gridType == g? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight))),
                          ),
                    ],
                    selected: <GridType>{gridType},
                    showSelectedIcon: false,
                    onSelectionChanged: (final Set<GridType> types)
                    {
                      if (!isPerspective)
                      {
                        lastNormalGridType = types.first;
                      }
                      else
                      {
                        lastPerspectiveGridType = types.first;
                      }
                      widget.gridState.gridTypeNotifier.value = types.first;
                      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: widget.gridState);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Opacity",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: ToolSettingsWidgetOptions.columnWidthRatio,
                        child: ValueListenableBuilder<int>(
                          valueListenable: widget.gridState.opacityNotifier,
                          builder: (final BuildContext context, final int opacity, final Widget? child) {
                            return KPixSlider(
                              value: opacity.toDouble(),
                              label: "$opacity%",
                              min: GridLayerConstraints.opacityMin.toDouble(),
                              max: GridLayerConstraints.opacityMax.toDouble(),
                              //divisions: GridLayerConstraints.opacityMax - GridLayerConstraints.opacityMin,
                              onChanged: (final double newVal) {
                                widget.gridState.opacityNotifier.value = newVal.round();
                              },
                              onChangedEnd: (final double value) {
                                GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: widget.gridState);
                              },
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
                            "Brightness",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: ToolSettingsWidgetOptions.columnWidthRatio,
                        child: ValueListenableBuilder<int>(
                          valueListenable: widget.gridState.brightnessNotifier,
                          builder: (final BuildContext context, final int brightness, final Widget? child) {
                            return KPixSlider(
                              value: brightness.toDouble(),
                              min: GridLayerConstraints.brightnessMin.toDouble(),
                              max: GridLayerConstraints.brightnessMax.toDouble(),
                              //divisions: GridLayerConstraints.brightnessMax - GridLayerConstraints.brightnessMin,
                              onChanged: (final double newVal) {
                                widget.gridState.brightnessNotifier.value = newVal.round();
                              },
                              onChangedEnd: (final double value) {
                                GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: widget.gridState);
                              },
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
                            !isPerspective ? "Interval X" : "Interval",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: ToolSettingsWidgetOptions.columnWidthRatio,
                        child: ValueListenableBuilder<int>(
                          valueListenable: widget.gridState.intervalXNotifier,
                          builder: (final BuildContext context, final int intervalX, final Widget? child) {
                            return KPixSlider(
                              value: intervalX.toDouble(),
                              min: GridLayerConstraints.intervalXMin.toDouble(),
                              max: GridLayerConstraints.intervalXMax.toDouble(),
                              //divisions: GridLayerConstraints.intervalXMax - GridLayerConstraints.intervalXMin,
                              onChanged: (final double newVal) {
                                widget.gridState.intervalXNotifier.value = newVal.round();
                              },
                              onChangedEnd: (final double value) {
                                GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: widget.gridState);
                              },
                              textStyle: Theme.of(context).textTheme.bodyLarge!,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if (!isPerspective)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Interval Y",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: ToolSettingsWidgetOptions.columnWidthRatio,
                        child: ValueListenableBuilder<int>(
                          valueListenable: widget.gridState.intervalYNotifier,
                          builder: (final BuildContext context, final int intervalY, final Widget? child) {
                            return KPixSlider(
                              value: intervalY.toDouble(),
                              min: GridLayerConstraints.intervalYMin.toDouble(),
                              max: GridLayerConstraints.intervalYMax.toDouble(),
                              //divisions: GridLayerConstraints.intervalYMax - GridLayerConstraints.intervalYMin,
                              onChanged: (final double newVal) {
                                widget.gridState.intervalYNotifier.value = newVal.round();
                              },
                              onChangedEnd: (final double value) {
                                GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: widget.gridState);
                              },
                              textStyle: Theme.of(context).textTheme.bodyLarge!,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if (isPerspective)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Horizon",
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ToolSettingsWidgetOptions.columnWidthRatio,
                          child: ValueListenableBuilder<double>(
                            valueListenable: widget.gridState.horizonPositionNotifier,
                            builder: (final BuildContext context, final double horizon, final Widget? child) {
                              return KPixSlider(
                                value: horizon,
                                min: GridLayerConstraints.vanishingPointMin,
                                max: GridLayerConstraints.vanishingPointMax,
                                decimals: 2,
                                onChanged: (final double newVal) {
                                  widget.gridState.horizonPositionNotifier.value = newVal;
                                },
                                onChangedEnd: (final double value) {
                                  GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: widget.gridState);
                                },
                                textStyle: Theme.of(context).textTheme.bodyLarge!,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  if (gridType == GridType.onePointPerspective)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Vanishing Point",
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ToolSettingsWidgetOptions.columnWidthRatio,
                          child: ValueListenableBuilder<double>(
                            valueListenable: widget.gridState.vanishingPoint1Notifier,
                            builder: (final BuildContext context, final double horizon, final Widget? child) {
                              return KPixSlider(
                                value: horizon,
                                min: GridLayerConstraints.vanishingPointMin,
                                max: GridLayerConstraints.vanishingPointMax,
                                decimals: 2,
                                onChanged: (final double newVal) {
                                  widget.gridState.vanishingPoint1Notifier.value = newVal;
                                },
                                onChangedEnd: (final double value) {
                                  GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: widget.gridState);
                                },
                                textStyle: Theme.of(context).textTheme.bodyLarge!,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  if (gridType == GridType.twoPointPerspective || gridType == GridType.threePointPerspective)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Hor Points",
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ToolSettingsWidgetOptions.columnWidthRatio,
                          child: ValueListenableBuilder<double>(
                            valueListenable: widget.gridState.vanishingPoint1Notifier,
                            builder: (final BuildContext context1, final double van1, final Widget? child1) {
                              return ValueListenableBuilder<double>(
                                valueListenable: widget.gridState.vanishingPoint2Notifier,
                                builder: (final BuildContext context2, final double van2, final Widget? child2)
                                {
                                   return KPixRangeSlider(
                                     values: RangeValues(van1, van2),
                                     min: GridLayerConstraints.vanishingPointMin,
                                     max: GridLayerConstraints.vanishingPointMax,
                                     textStyle: Theme.of(context).textTheme.bodyLarge!,
                                     decimals: 2,
                                     onChanged: (final RangeValues newVals)
                                     {
                                       widget.gridState.vanishingPoint1Notifier.value = newVals.start;
                                       widget.gridState.vanishingPoint2Notifier.value = newVals.end;
                                     },
                                     onChangedEnd: (final RangeValues values) {
                                       GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: widget.gridState);
                                     },
                                   );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  if (gridType == GridType.threePointPerspective)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Ver Point",
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ToolSettingsWidgetOptions.columnWidthRatio,
                          child: ValueListenableBuilder<double>(
                            valueListenable: widget.gridState.vanishingPoint3Notifier,
                            builder: (final BuildContext context, final double van3, final Widget? child) {
                              return KPixSlider(
                                value: van3,
                                min: GridLayerConstraints.vanishingPointMin,
                                max: GridLayerConstraints.vanishingPointMax,
                                decimals: 2,
                                onChanged: (final double newVal) {
                                  widget.gridState.vanishingPoint3Notifier.value = newVal;
                                },
                                onChangedEnd: (final double value) {
                                  GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: widget.gridState);
                                },
                                textStyle: Theme.of(context).textTheme.bodyLarge!,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
