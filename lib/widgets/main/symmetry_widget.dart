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
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/symmetry_state.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';



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

  Widget _createRulerControls({
    required final ValueNotifier<bool> activated,
    required final ValueNotifier<double> ruler,
    required final int Function() canvasExtent,
    required final IconData icon,
    required final String centerTooltip,
    required final IconData centerIcon,
  })
  {
    return ValueListenableBuilder<bool>(
      valueListenable: activated,
      builder: (final BuildContext context, final bool isActivated, final Widget? child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Switch(
                  value: isActivated,
                  onChanged: (final bool value)
                  {activated.value = value;},
                ),
                const SizedBox(
                  width: _SymmetryWidgetOptions.padding,
                ),
                const Spacer(),
                Icon(icon, size: _SymmetryWidgetOptions.buttonHeight, color: Theme.of(context).primaryColorDark),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: _SymmetryWidgetOptions.padding * 4),
                  child: SizedBox(
                    width: _SymmetryWidgetOptions.buttonWidth,
                    height: _SymmetryWidgetOptions.buttonHeight,
                    child: IconButton.outlined(
                      tooltip: centerTooltip,
                      onPressed: isActivated ? () {
                        ruler.value = canvasExtent().toDouble() / 2.0;
                      } : null,
                      icon: Icon(centerIcon, size: _SymmetryWidgetOptions.buttonHeight,),
                    ),
                  ),
                ),
              ],
            ) ,
            Padding(
              padding: const EdgeInsets.only(left: _SymmetryWidgetOptions.padding * 4, right: _SymmetryWidgetOptions.padding * 4),
              child: ValueListenableBuilder<double>(
                valueListenable: ruler,
                builder: (final BuildContext context, final double rulerValue, final Widget? child) {
                  return KPixSlider(
                    min: 1.0,
                    value: rulerValue,
                    max: max(canvasExtent() - 1, 1.0),
                    label: rulerValue.toStringAsFixed(1),
                    onChanged: isActivated ? (final double value) {
                      ruler.value = (value * 2).roundToDouble() / 2.0;
                    } : null,
                    textStyle: Theme.of(context).textTheme.bodyLarge!,);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.only(top: _SymmetryWidgetOptions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min, // Important for Column containing SizeTransition
          children: <Widget>[
            Tooltip(
              message: l10n.symmetryOptions,
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
                          child: _createRulerControls(
                            activated: widget.state.horizontalActivated,
                            ruler: widget.state.horizontalValue,
                            canvasExtent: () => GetIt.I.get<CanvasState>().canvasSize.x,
                            icon: TablerIcons.flip_vertical,
                            centerTooltip: l10n.centerHorizontalRuler,
                            centerIcon: TablerIcons.layout_align_middle,
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
                          child: _createRulerControls(
                            activated: widget.state.verticalActivated,
                            ruler: widget.state.verticalValue,
                            canvasExtent: () => GetIt.I.get<CanvasState>().canvasSize.y,
                            icon: TablerIcons.flip_horizontal,
                            centerTooltip: l10n.centerVerticalRuler,
                            centerIcon: TablerIcons.layout_align_center,
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
