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
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// The default animation container for "zoom in" animation for overlays.
class KPixAnimationWidget extends StatefulWidget
{
  final Widget child;
  final BoxConstraints? constraints;
  final Duration? animationLength;

  const KPixAnimationWidget({super.key, required this.child, this.constraints, this.animationLength = const Duration(milliseconds: 150)});

  @override
  State<KPixAnimationWidget> createState() => _KPixAnimationWidgetState();
}

class _KPixAnimationWidgetState extends State<KPixAnimationWidget> with SingleTickerProviderStateMixin
{
  late AnimationController animationController;
  late Animation<double> animation;
  late BoxConstraints _constraints;


  @override
  void dispose()
  {
    animationController.dispose();
    super.dispose();
  }

  @override
  void initState()
  {
    super.initState();

    _constraints = widget.constraints ??
      const BoxConstraints(
        minHeight: OverlayEntryAlertDialogOptions.minHeight,
        minWidth: OverlayEntryAlertDialogOptions.minWidth,
        maxHeight: OverlayEntryAlertDialogOptions.maxHeight,
        maxWidth: OverlayEntryAlertDialogOptions.maxWidth,
      );

    animationController = AnimationController(
      vsync: this,
      duration: widget.animationLength,
    );
    animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        curve: const Interval(0.0, 1.0,curve: Curves.easeInOutCubic,),
        parent: animationController,
      ),
    );
    animationController.forward();
  }

  @override
  Widget build(final BuildContext context)
  {
    return ScaleTransition(
      scale: animation,
      child: Material(
        elevation: OverlayEntryAlertDialogOptions.elevation,
        shadowColor: Theme.of(context).primaryColorDark,
        borderRadius: const BorderRadius.all(Radius.circular(OverlayEntryAlertDialogOptions.borderRadius)),
        child: Container(
          constraints: _constraints,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            border: Border.all(
              color: Theme.of(context).primaryColorLight,
              width: OverlayEntryAlertDialogOptions.borderWidth,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(OverlayEntryAlertDialogOptions.borderRadius)),
          ),
          child: Padding(
              padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
              child: widget.child,
          ),
        ),
      ),
    );
  }
}
