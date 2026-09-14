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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:toastification/toastification.dart';

abstract final class _ToastLayoutOptions
{
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Offset slideAnimationStart = Offset(0.0, 1.0);
  static const Offset slideAnimationEnd = Offset.zero;
  static const double fadeAnimationStart = 0.0;
  static const double fadeAnimationEnd = 1.0;
  static const int limit = 3;
  static const EdgeInsetsGeometry margin = EdgeInsetsGeometry.zero;
  static const Duration showDurationShort = Duration(seconds: 2);
  static const Duration showDurationLong = Duration(seconds: 4);
  static const double borderWidth = 2.0;
  static const double padding = 8.0;
  static const double borderRadius = 8.0;
  static const double iconSize = 24.0;
}

/// Returns the main wrapper for app-wide notifications
ToastificationWrapper getToastificationWrapper({required final Widget child})
{
  return ToastificationWrapper(
      config: ToastificationConfig(
        animationDuration: _ToastLayoutOptions.animationDuration,
        maxToastLimit: _ToastLayoutOptions.limit,
        alignment: AlignmentGeometry.bottomCenter,
        itemWidth: 800,
        marginBuilder: (final BuildContext context, final AlignmentGeometry alignment)
        {
          return _ToastLayoutOptions.margin;
        },
        animationBuilder: (final BuildContext context, final Animation<double> animation, final Alignment alignment, final Widget? child,)
        {
          final Animation<Offset> slideAnimation = Tween<Offset>(
            begin: _ToastLayoutOptions.slideAnimationStart,
            end: _ToastLayoutOptions.slideAnimationEnd,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            ),
          );

          final Animation<double> fadeAnimation = Tween<double>(
            begin: _ToastLayoutOptions.fadeAnimationStart,
            end: _ToastLayoutOptions.fadeAnimationEnd,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
              reverseCurve: Curves.easeOut,
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },
      ),
      child: child,
  );
}

enum ToastType
{
  info(isLong: true, color: infoColor),
  undo(iconData: TablerIcons.arrow_back_up),
  redo(iconData: TablerIcons.arrow_forward_up),
  warning(iconData: TablerIcons.exclamation_circle_filled, color: warningColor, isLong: true),
  error(iconData: TablerIcons.xbox_x_filled, color: errorColor, isLong: true),
  success(iconData: TablerIcons.circle_check_filled, color: successColor);

  final IconData iconData;
  final bool isLong;
  final Color? color;

  const ToastType({this.iconData = TablerIcons.info_circle, this.isLong = false, this.color});
}



/// Shows a transient toast at the bottom of the screen.
///
/// Holds no state and needs no build context of its own, so it lives here
/// rather than on a state object.
void showMessage({required final String text, required final ToastType toastType})
{
  toastification.showCustom(
    autoCloseDuration: toastType.isLong ? _ToastLayoutOptions.showDurationLong : _ToastLayoutOptions.showDurationShort,
    builder: (final BuildContext context, final ToastificationItem holder) {
      return Align(
        alignment: AlignmentGeometry.bottomCenter,
        child: Container(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(_ToastLayoutOptions.padding),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorDark,
            border: Border(
              left: BorderSide(color: Theme.of(context).primaryColor, width: _ToastLayoutOptions.borderWidth,),
              right: BorderSide(color: Theme.of(context).primaryColor, width: _ToastLayoutOptions.borderWidth,),
              top: BorderSide(color: Theme.of(context).primaryColor, width: _ToastLayoutOptions.borderWidth,),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(_ToastLayoutOptions.borderRadius)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                toastType.iconData,
                size: _ToastLayoutOptions.iconSize,
                color: toastType.color ?? Theme.of(context).primaryColorLight,
              ),
              const SizedBox(
                width: _ToastLayoutOptions.padding,
              ),
              Flexible(
                child: Text(
                  text,
                  softWrap: true,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
