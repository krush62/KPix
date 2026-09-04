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
import 'package:toastification/toastification.dart';

/// Shows a transient toast at the bottom of the screen.
///
/// Holds no state and needs no build context of its own, so it lives here
/// rather than on a state object.
void showMessage({required final String text})
{
  toastification.showCustom(
    alignment: Alignment.bottomCenter,
    autoCloseDuration: const Duration(seconds: 3),
    builder: (final BuildContext context, final ToastificationItem holder) {
      const double padding = 8.0;
      return Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.only(left: padding, right: padding, top: padding, bottom: padding * 2),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorDark,
          border: Border(
            left: BorderSide(color: Theme.of(context).primaryColor, width: 2.0,),
            right: BorderSide(color: Theme.of(context).primaryColor, width: 2.0,),
            top: BorderSide(color: Theme.of(context).primaryColor, width: 2.0,),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
        ),
        child: Text(
          text,
          softWrap: true,
          style: Theme.of(context).textTheme.titleMedium,),
      );
    },
    animationBuilder: (final BuildContext context, final Animation<double> animation, final Alignment alignment, final Widget? child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: const Offset(0, 0.25), //this is hacky
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.fastOutSlowIn,
        ),),
        child: child,
      );
    },
  );
}
