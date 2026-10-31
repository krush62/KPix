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
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/models/constraints/grid_layer_constraints.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/widgets/controls/kpix_range_slider.dart';

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

  void _commitChange()
  {
    GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.layerSettingsChange, originLayer: widget.gridState);
  }

  Widget _createLabeledRow({required final String label, required final Widget child})
  {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        Expanded(
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
          child: child,
        ),
      ],
    );
  }

  Widget _createIntRow({required final String label, required final ValueNotifier<int> notifier, required final int min, required final int max, final String Function(int value)? valueLabel})
  {
    return ToolSliderRow<int>(
      label: label,
      notifier: notifier,
      minVal: min.toDouble(),
      maxVal: max.toDouble(),
      labelBuilder: valueLabel,
      onChangedEnd: (final double value) {_commitChange();},
    );
  }

  Widget _createPositionRow({required final String label, required final ValueNotifier<double> notifier})
  {
    return ToolSliderRow<double>(
      label: label,
      notifier: notifier,
      minVal: GridLayerConstraints.vanishingPointMin,
      maxVal: GridLayerConstraints.vanishingPointMax,
      decimals: 2,
      onChangedEnd: (final double value) {_commitChange();},
    );
  }

  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
                      _commitChange();
                    },
                    segments: <ButtonSegment<bool>>[
                      ButtonSegment<bool>(
                        value: false,
                        tooltip: l10n.grid,
                        label: Text(l10n.gridButton, style: Theme.of(context).textTheme.labelSmall!.apply(color: !isPerspective ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight)),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        tooltip: l10n.perspective,
                        label: Text(l10n.perspectiveButton, style: Theme.of(context).textTheme.labelSmall!.apply(color: isPerspective ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight)),
                      ),
                    ],
                  ),
                  SegmentedButton<GridType>(
                    segments: <ButtonSegment<GridType>>[
                      for (final GridType g in GridType.values)
                        if (isPerspectiveGridType(gridType: g) == isPerspective)
                          ButtonSegment<GridType>(
                            value: g,
                            tooltip: g.desc(l10n),
                            label: Text(g.label(l10n), style: Theme.of(context).textTheme.labelSmall!.apply(color: gridType == g? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight)),
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
                      _commitChange();
                    },
                  ),
                  _createIntRow(
                    label: l10n.opacity,
                    notifier: widget.gridState.opacityNotifier,
                    min: GridLayerConstraints.opacityMin,
                    max: GridLayerConstraints.opacityMax,
                    valueLabel: (final int value) => "$value%",
                  ),
                  _createIntRow(
                    label: l10n.brightness,
                    notifier: widget.gridState.brightnessNotifier,
                    min: GridLayerConstraints.brightnessMin,
                    max: GridLayerConstraints.brightnessMax,
                  ),
                  _createIntRow(
                    label: !isPerspective ? l10n.intervalX : l10n.interval,
                    notifier: widget.gridState.intervalXNotifier,
                    min: GridLayerConstraints.intervalXMin,
                    max: GridLayerConstraints.intervalXMax,
                  ),
                  if (!isPerspective)
                    _createIntRow(
                      label: l10n.intervalY,
                      notifier: widget.gridState.intervalYNotifier,
                      min: GridLayerConstraints.intervalYMin,
                      max: GridLayerConstraints.intervalYMax,
                    ),
                  if (isPerspective)
                    _createPositionRow(label: l10n.horizon, notifier: widget.gridState.horizonPositionNotifier),
                  if (gridType == GridType.onePointPerspective)
                    _createPositionRow(label: l10n.vanishingPoint, notifier: widget.gridState.vanishingPoint1Notifier),
                  if (gridType == GridType.twoPointPerspective || gridType == GridType.threePointPerspective)
                    _createLabeledRow(
                      label: l10n.horPoints,
                      child: ListenableBuilder(
                        listenable: Listenable.merge(<Listenable>[widget.gridState.vanishingPoint1Notifier, widget.gridState.vanishingPoint2Notifier]),
                        builder: (final BuildContext context, final Widget? child)
                        {
                          return KPixRangeSlider(
                            values: RangeValues(widget.gridState.vanishingPoint1Notifier.value, widget.gridState.vanishingPoint2Notifier.value),
                            min: GridLayerConstraints.vanishingPointMin,
                            max: GridLayerConstraints.vanishingPointMax,
                            textStyle: Theme.of(context).textTheme.bodyLarge!,
                            decimals: 2,
                            onChanged: (final RangeValues newVals)
                            {
                              widget.gridState.vanishingPoint1Notifier.value = newVals.start;
                              widget.gridState.vanishingPoint2Notifier.value = newVals.end;
                            },
                            onChangedEnd: (final RangeValues values) {_commitChange();},
                          );
                        },
                      ),
                    ),
                  if (gridType == GridType.threePointPerspective)
                    _createPositionRow(label: l10n.verPoint, notifier: widget.gridState.vanishingPoint3Notifier),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
