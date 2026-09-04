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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';

class SymmetryState
{
  final ValueNotifier<bool> horizontalActivated = ValueNotifier<bool>(false);
  final ValueNotifier<double> horizontalValue = ValueNotifier<double>(1.0);
  final ValueNotifier<bool> verticalActivated = ValueNotifier<bool>(false);
  final ValueNotifier<double> verticalValue = ValueNotifier<double>(1.0);

  void reset()
  {
    horizontalActivated.value = false;
    horizontalValue.value = GetIt.I.get<CanvasState>().canvasSize.x.toDouble() / 2.0;
    verticalActivated.value = false;
    verticalValue.value = GetIt.I.get<CanvasState>().canvasSize.y.toDouble() / 2.0;
  }

  void newCanvasDimensions({required final CoordinateSetI newSize})
  {
    horizontalValue.value = horizontalValue.value.clamp(1.0, newSize.x - 1).toDouble();
    verticalValue.value = verticalValue.value.clamp(1.0, newSize.y - 1).toDouble();
  }
}


abstract final class _SymmetryWidgetOptions
{
  static const double dividerWidth = 2.0;
  static const double padding = 2.0;
  static const double height = 72.0;
  static const int animationDurationMs = 200;
  static const double buttonWidth = 96.0;
  static const double buttonHeight = 36.0;
  static const double expandIconSize = 20.0;
  //static const double verticalIconSize = 16.0;
  //static const double horizontalIconSize = 20.0;
  //static const double centerButtonIconSize = 24.0;
}

class SymmetryWidget extends StatefulWidget
{
  final SymmetryState state;
  const SymmetryWidget({super.key, required this.state});

  @override
  State<SymmetryWidget> createState() => _SymmetryWidgetState();
}

class _SymmetryWidgetState extends State<SymmetryWidget> with SingleTickerProviderStateMixin
{
  final ValueNotifier<bool> isExpanded = ValueNotifier<bool>(false);
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _SymmetryWidgetOptions.animationDurationMs),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (isExpanded.value) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand()
  {
    isExpanded.value = !isExpanded.value;
    if (isExpanded.value)
    {
      _animationController.forward();
    }
    else
    {
      _animationController.reverse();
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.only(top: _SymmetryWidgetOptions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min, // Important for Column containing SizeTransition
          children: <Widget>[
            Tooltip(
              message: "Symmetry Options",
              waitDuration: toolTipDuration,
              child: GestureDetector(
                onTap: _toggleExpand,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ColoredBox(
                    color: Theme.of(context).primaryColor,
                    child: Padding(
                      padding: const EdgeInsets.all(_SymmetryWidgetOptions.padding),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isExpanded,
                        builder: (final BuildContext context, final bool expanded, final Widget? child)
                        {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              const Spacer(),
                              Icon(TablerIcons.flip_vertical, color: Theme.of(context).primaryColorLight, size: _SymmetryWidgetOptions.expandIconSize,),
                              Icon(expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Theme.of(context).primaryColorLight, size: _SymmetryWidgetOptions.expandIconSize,),
                              const Spacer(),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _animation,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(_SymmetryWidgetOptions.padding),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(_SymmetryWidgetOptions.padding),
                      child: Divider(
                        color: Theme.of(context).primaryColorLight,
                        thickness: _SymmetryWidgetOptions.dividerWidth,
                        height: _SymmetryWidgetOptions.dividerWidth,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: widget.state.horizontalActivated,
                            builder: (final BuildContext context, final bool horActivated, final Widget? child) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Switch(
                                        value: horActivated,
                                        onChanged: (final bool value)
                                        {widget.state.horizontalActivated.value = value;},
                                      ),
                                      const SizedBox(
                                        width: _SymmetryWidgetOptions.padding,
                                      ),
                                      const Spacer(),
                                      Icon(TablerIcons.flip_vertical, size: _SymmetryWidgetOptions.buttonHeight, color: Theme.of(context).primaryColorDark),
                                      const Spacer(),
                                      Padding(
                                        padding:  const EdgeInsets.only(right: _SymmetryWidgetOptions.padding * 4),
                                        child: Tooltip(
                                          message: "Center Horizontal Ruler",
                                          waitDuration: toolTipDuration,
                                          child: SizedBox(
                                            width: _SymmetryWidgetOptions.buttonWidth,
                                            height: _SymmetryWidgetOptions.buttonHeight,
                                            child: IconButton.outlined(
                                              onPressed: horActivated ? () {
                                                widget.state.horizontalValue.value = GetIt.I.get<CanvasState>().canvasSize.x.toDouble() / 2.0;
                                              } : null,
                                              icon: const Icon(TablerIcons.layout_align_middle, size: _SymmetryWidgetOptions.buttonHeight,),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ) ,
                                  Padding(
                                    padding: const EdgeInsets.only(left: _SymmetryWidgetOptions.padding * 4, right: _SymmetryWidgetOptions.padding * 4),
                                    child: ValueListenableBuilder<double>(
                                      valueListenable: widget.state.horizontalValue,
                                      builder: (final BuildContext context, final double horVal, final Widget? child) {
                                        return KPixSlider(
                                          min: 1.0,
                                          value: horVal,
                                          max: max(GetIt.I.get<CanvasState>().canvasSize.x - 1, 1.0),
                                          //divisions: max((GetIt.I.get<CanvasState>().canvasSize.x - 2) * 2, 1),
                                          label: horVal.toStringAsFixed(1),
                                          onChanged: horActivated ? (final double value) {
                                            widget.state.horizontalValue.value = (value * 2).roundToDouble() / 2.0;
                                          } : null,
                                          textStyle: Theme.of(context).textTheme.bodyLarge!,);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(_SymmetryWidgetOptions.padding * 4),
                          child: LimitedBox(
                            maxHeight: _SymmetryWidgetOptions.height,
                            child: VerticalDivider(
                              color: Theme.of(context).primaryColorLight,
                              thickness: _SymmetryWidgetOptions.dividerWidth,
                              width: _SymmetryWidgetOptions.dividerWidth,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: widget.state.verticalActivated,
                            builder: (final BuildContext context, final bool vertActivated, final Widget? child) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Switch(
                                        value: vertActivated,
                                        onChanged: (final bool value)
                                        {widget.state.verticalActivated.value = value;},
                                      ),
                                      const SizedBox(
                                        width: _SymmetryWidgetOptions.padding,
                                      ),
                                      const Spacer(),
                                      Column(
                                        children: <Widget>[
                                          Icon(TablerIcons.flip_horizontal, size: _SymmetryWidgetOptions.buttonHeight, color: Theme.of(context).primaryColorDark),
                                        ],
                                      ),
                                      const Spacer(),
                                      Padding(
                                        padding: const EdgeInsets.only(right: _SymmetryWidgetOptions.padding * 4),
                                        child: Tooltip(
                                          message: "Center Vertical Ruler",
                                          waitDuration: toolTipDuration,
                                          child: SizedBox(
                                            width: _SymmetryWidgetOptions.buttonWidth,
                                            height: _SymmetryWidgetOptions.buttonHeight,
                                            child: IconButton.outlined(
                                              onPressed: vertActivated ? () {
                                                widget.state.verticalValue.value = GetIt.I.get<CanvasState>().canvasSize.y.toDouble() / 2.0;
                                              } : null,
                                              icon: const Icon(TablerIcons.layout_align_center, size: _SymmetryWidgetOptions.buttonHeight,),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ) ,
                                  Padding(
                                    padding: const EdgeInsets.only(left: _SymmetryWidgetOptions.padding * 4, right: _SymmetryWidgetOptions.padding * 4),
                                    child: ValueListenableBuilder<double>(
                                      valueListenable: widget.state.verticalValue,
                                      builder: (final BuildContext context, final double horVal, final Widget? child) {
                                        return KPixSlider(
                                          min: 1.0,
                                          value: horVal,
                                          max: max(GetIt.I.get<CanvasState>().canvasSize.y - 1, 1.0),
                                          //divisions: max((GetIt.I.get<CanvasState>().canvasSize.y - 2) * 2, 1),
                                          label: horVal.toStringAsFixed(1),
                                          onChanged: vertActivated ? (final double value) {
                                            widget.state.verticalValue.value = (value * 2).roundToDouble() / 2.0;
                                          } : null,
                                          textStyle: Theme.of(context).textTheme.bodyLarge!,);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
