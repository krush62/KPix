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
import 'package:kpix/models/app_state.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Not used in this animation example
import 'package:kpix/widgets/controls/kpix_slider.dart';

class SymmetryState
{
  final ValueNotifier<bool> horizontalActivated = ValueNotifier<bool>(false);
  final ValueNotifier<double> horizontalValue = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> verticalActivated = ValueNotifier<bool>(false);
  final ValueNotifier<double> verticalValue = ValueNotifier<double>(0.0);
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
  //TODO add to preference manager
  final double dividerWidth = 2.0;
  final double padding = 2.0;
  final double height = 72.0;
  final int animationDurationMs = 200;
  final double buttonWidth = 96.0;
  final double buttonHeight = 36;
  final double expandIconSize = 16;

  final ValueNotifier<bool> isExpanded = ValueNotifier<bool>(false);
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: animationDurationMs),
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
        padding: EdgeInsets.only(top: padding),
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
                      padding: EdgeInsets.all(padding),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isExpanded,
                        builder: (final BuildContext context, final bool expanded, final Widget? child)
                        {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: <Widget>[
                              const Spacer(),
                              Icon(Icons.border_inner, color: Theme.of(context).primaryColorLight, size: expandIconSize,),
                              Text(
                                !expanded ? '⯅' : '⯆',
                                style: Theme.of(context).textTheme.titleSmall,
                                textAlign: TextAlign.center,
                              ),
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
                padding: EdgeInsets.all(padding),
                child: Row(
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
                                    width: padding,
                                  ),
                                  const Spacer(),
                                  Text("Horizontal", style: Theme.of(context).textTheme.titleLarge,),
                                  const Spacer(),
                                  Padding(
                                    padding:  EdgeInsets.only(right: padding * 4),
                                    child: SizedBox(
                                      width: buttonWidth,
                                      height: buttonHeight,
                                      child: OutlinedButton(
                                        onPressed: horActivated ? () {
                                          //TODO: Implement button logic
                                        } : null,
                                        child: const Text("CENTER"),
                                      ),
                                    ),
                                  ),
                                ],
                              ) ,
                              Padding(
                                padding: EdgeInsets.only(left: padding * 4, right: padding * 4),
                                child: ValueListenableBuilder<double>(
                                  valueListenable: widget.state.horizontalValue,
                                  builder: (final BuildContext context, final double horVal, final Widget? child) {
                                    return KPixSlider(
                                      min: 0.0, //TODO
                                      value: horVal,
                                      max: 100, //TODO
                                      divisions: 200, //TODO
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
                        }
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: LimitedBox(
                        maxHeight: height,
                        child: VerticalDivider(
                          color: Theme.of(context).primaryColorLight,
                          thickness: dividerWidth,
                          width: dividerWidth,
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
                                      width: padding,
                                    ),
                                    const Spacer(),
                                    Text("Vertical", style: Theme.of(context).textTheme.titleLarge,),
                                    const Spacer(),
                                    Padding(
                                      padding: EdgeInsets.only(right: padding * 4),
                                      child: SizedBox(
                                        width: buttonWidth,
                                        height: buttonHeight,
                                        child: OutlinedButton(
                                          onPressed: vertActivated ? () {
                                            //TODO: Implement button logic
                                          } : null,
                                          child: const Text("CENTER"),
                                        ),
                                      ),
                                    ),
                                  ],
                                ) ,
                                Padding(
                                  padding: EdgeInsets.only(left: padding * 4, right: padding * 4),
                                  child: ValueListenableBuilder<double>(
                                    valueListenable: widget.state.verticalValue,
                                    builder: (final BuildContext context, final double horVal, final Widget? child) {
                                      return KPixSlider(
                                        min: 0.0, //TODO
                                        value: horVal,
                                        max: 100, //TODO
                                        divisions: 200, //TODO
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
                          }
                      ),
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