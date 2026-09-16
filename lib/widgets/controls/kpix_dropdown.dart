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

/// Layout values matching [DropdownButton], so the two cannot drift apart.
abstract final class _KPixDropdownOptions {
  static const double itemHeight = kMinInteractiveDimension;
  static const EdgeInsets itemPadding = EdgeInsets.symmetric(horizontal: 16.0);
  static const double underlineBottom = 8.0;
  static const double underlineHeight = 1.0;
  static const Color underlineColor = Color(0xFFBDBDBD);
  static const double elevation = 8.0;
  static const double iconSize = 24.0;
}

/// A dropdown that opens inside the overlay it is shown in.
///
/// [DropdownButton] opens its menu as a route. [Navigator] keeps route entries
/// below every entry that was inserted into the overlay by hand, so a dropdown
/// inside a [KPixOverlay] drops its menu behind the dialog and a second tap
/// trips an assertion in the framework. This one hangs the menu off the entry it
/// lives in, so it is drawn above it.
///
/// The appearance follows [DropdownButton] so both can be used side by side.
class KPixDropdown<E> extends StatelessWidget {
  const KPixDropdown({
    super.key,
    required this.value,
    required this.valueMap,
    required this.onChanged,
    this.itemTextStyle,
  });

  final E value;
  final Map<E, String> valueMap;
  final void Function(E value) onChanged;

  /// The style for a single entry, for dropdowns that show each entry differently.
  final TextStyle? Function(E value)? itemTextStyle;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle textStyle = theme.textTheme.titleMedium!;
    final Color iconColor = theme.brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade700;

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        return MenuAnchor(
          //the menu is as wide as the button, like the one of a DropdownButton
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color?>(theme.primaryColorDark),
            surfaceTintColor: const WidgetStatePropertyAll<Color?>(Colors.transparent),
            elevation: const WidgetStatePropertyAll<double?>(_KPixDropdownOptions.elevation),
            padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.zero),
            minimumSize: WidgetStatePropertyAll<Size>(Size(constraints.maxWidth, 0.0)),
            maximumSize: WidgetStatePropertyAll<Size>(Size(constraints.maxWidth, double.infinity)),
          ),
          menuChildren: <Widget>[
            for (final MapEntry<E, String> entry in valueMap.entries)
              MenuItemButton(
                style: ButtonStyle(
                  //the entries carry the width, so the menu ends up as wide as the button
                  fixedSize: WidgetStatePropertyAll<Size>(Size(constraints.maxWidth, _KPixDropdownOptions.itemHeight)),
                  maximumSize: WidgetStatePropertyAll<Size>(Size(constraints.maxWidth, _KPixDropdownOptions.itemHeight)),
                  padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(_KPixDropdownOptions.itemPadding),
                  backgroundColor: WidgetStatePropertyAll<Color?>(entry.key == value ? theme.primaryColor : null),
                ),
                onPressed: () {
                  onChanged(entry.key);
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(entry.value, style: itemTextStyle?.call(entry.key) ?? textStyle),
                ),
              ),
          ],
          builder: (final BuildContext context, final MenuController controller, final Widget? child) {
            //the ink needs a material of its own, so the dropdown can also be
            //used where nothing else provides one
            return Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                focusColor: theme.primaryColor,
                child: Stack(
                  children: <Widget>[
                    SizedBox(
                      height: _KPixDropdownOptions.itemHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                valueMap[value] ?? "",
                                style: itemTextStyle?.call(value) ?? textStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, size: _KPixDropdownOptions.iconSize, color: iconColor),
                        ],
                      ),
                    ),
                    const Positioned(
                      left: 0.0,
                      right: 0.0,
                      bottom: _KPixDropdownOptions.underlineBottom,
                      child: SizedBox(
                        height: _KPixDropdownOptions.underlineHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: _KPixDropdownOptions.underlineColor, width: 0.0)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
