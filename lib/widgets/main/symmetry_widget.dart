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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
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
    horizontalValue.value = GetIt.I.get<AppState>().canvasSize.x.toDouble() / 2.0;
    verticalActivated.value = false;
    verticalValue.value = GetIt.I.get<AppState>().canvasSize.y.toDouble() / 2.0;
  }

  void newCanvasDimensions({required final CoordinateSetI newSize})
  {
    horizontalValue.value = horizontalValue.value.clamp(1.0, newSize.x - 1).toDouble();
    verticalValue.value = verticalValue.value.clamp(1.0, newSize.y - 1).toDouble();
  }
}


class SymmetryWidgetOptions
{
  final double dividerWidth;
  final double padding;
  final double height;
  final int animationDurationMs;
  final double buttonWidth;
  final double buttonHeight;
  final double expandIconSize;
  final double verticalIconSize;
  final double horizontalIconSize;
  final double centerButtonIconSize;

  const SymmetryWidgetOptions({
    required this.dividerWidth,
    required this.padding,
    required this.height,
    required this.animationDurationMs,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.expandIconSize,
    required this.verticalIconSize,
    required this.horizontalIconSize,
    required this.centerButtonIconSize,
  });
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
  final SymmetryWidgetOptions _options = GetIt.I.get<PreferenceManager>().symmetryWidgetOptions;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _options.animationDurationMs),
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
        padding: EdgeInsets.only(top: _options.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min, // Important for Column containing SizeTransition
          children: <Widget>[
            Tooltip(
              message: "Symmetry Options",
              waitDuration: AppState.toolTipDuration,
              child: GestureDetector(
                onTap: _toggleExpand,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ColoredBox(
                    color: Theme.of(context).primaryColor,
                    child: Padding(
                      padding: EdgeInsets.all(_options.padding),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isExpanded,
                        builder: (final BuildContext context, final bool expanded, final Widget? child)
                        {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              const Spacer(),
                              Icon(Icons.border_inner, color: Theme.of(context).primaryColorLight, size: _options.expandIconSize,),
                              Icon(expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Theme.of(context).primaryColorLight, size: _options.expandIconSize,),
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
              axisAlignment: -1.0,
              child: Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(_options.padding),
                      child: Divider(
                        color: Theme.of(context).primaryColorLight,
                        thickness: _options.dividerWidth,
                        height: _options.dividerWidth,
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
                                      SizedBox(
                                        width: _options.padding,
                                      ),
                                      const Spacer(),
                                      Icon(FontAwesomeIcons.caretRight, size: _options.horizontalIconSize, color: Theme.of(context).primaryColorLight),
                                      Container(
                                        height: _options.horizontalIconSize,
                                        width: _options.dividerWidth,
                                        color: Theme.of(context).primaryColorLight,
                                      ),
                                      Icon(FontAwesomeIcons.caretLeft, size: _options.horizontalIconSize, color: Theme.of(context).primaryColorLight,),
                                      const Spacer(),
                                      Padding(
                                        padding:  EdgeInsets.only(right: _options.padding * 4),
                                        child: Tooltip(
                                          message: "Center Horizontal Ruler",
                                          waitDuration: AppState.toolTipDuration,
                                          child: SizedBox(
                                            width: _options.buttonWidth,
                                            height: _options.buttonHeight,
                                            child: IconButton.outlined(
                                              onPressed: horActivated ? () {
                                                widget.state.horizontalValue.value = GetIt.I.get<AppState>().canvasSize.x.toDouble() / 2.0;
                                              } : null,
                                              icon: Icon(Icons.border_vertical, size: _options.centerButtonIconSize,),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ) ,
                                  Padding(
                                    padding: EdgeInsets.only(left: _options.padding * 4, right: _options.padding * 4),
                                    child: ValueListenableBuilder<double>(
                                      valueListenable: widget.state.horizontalValue,
                                      builder: (final BuildContext context, final double horVal, final Widget? child) {
                                        return KPixSlider(
                                          min: 1.0,
                                          value: horVal,
                                          max: max(GetIt.I.get<AppState>().canvasSize.x - 1, 1.0),
                                          //divisions: max((GetIt.I.get<AppState>().canvasSize.x - 2) * 2, 1),
                                          label: horVal.toStringAsFixed(1),
                                          onChanged: horActivated ? (final double value) {
                                            widget.state.horizontalValue.value = value;
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
                          padding: EdgeInsets.all(_options.padding * 4),
                          child: LimitedBox(
                            maxHeight: _options.height,
                            child: VerticalDivider(
                              color: Theme.of(context).primaryColorLight,
                              thickness: _options.dividerWidth,
                              width: _options.dividerWidth,
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
                                      SizedBox(
                                        width: _options.padding,
                                      ),
                                      const Spacer(),
                                      Column(
                                        children: <Widget>[
                                          Icon(FontAwesomeIcons.caretDown, size: _options.verticalIconSize, color: Theme.of(context).primaryColorLight,),
                                          Container(
                                            height: _options.dividerWidth,
                                            width: _options.verticalIconSize,
                                            color: Theme.of(context).primaryColorLight,
                                          ),
                                          Icon(FontAwesomeIcons.caretUp, size: _options.verticalIconSize, color: Theme.of(context).primaryColorLight,),
                                        ],
                                      ),
                                      const Spacer(),
                                      Padding(
                                        padding: EdgeInsets.only(right: _options.padding * 4),
                                        child: Tooltip(
                                          message: "Center Vertical Ruler",
                                          waitDuration: AppState.toolTipDuration,
                                          child: SizedBox(
                                            width: _options.buttonWidth,
                                            height: _options.buttonHeight,
                                            child: IconButton.outlined(
                                              onPressed: vertActivated ? () {
                                                widget.state.verticalValue.value = GetIt.I.get<AppState>().canvasSize.y.toDouble() / 2.0;
                                              } : null,
                                              icon: Icon(Icons.border_horizontal, size: _options.centerButtonIconSize,),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ) ,
                                  Padding(
                                    padding: EdgeInsets.only(left: _options.padding * 4, right: _options.padding * 4),
                                    child: ValueListenableBuilder<double>(
                                      valueListenable: widget.state.verticalValue,
                                      builder: (final BuildContext context, final double horVal, final Widget? child) {
                                        return KPixSlider(
                                          min: 1.0,
                                          value: horVal,
                                          max: max(GetIt.I.get<AppState>().canvasSize.y - 1, 1.0),
                                          //divisions: max((GetIt.I.get<AppState>().canvasSize.y - 2) * 2, 1),
                                          label: horVal.toStringAsFixed(1),
                                          onChanged: vertActivated ? (final double value) {
                                            widget.state.verticalValue.value = value;
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
