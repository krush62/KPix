/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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

import 'package:material_ui/material_ui.dart';

abstract final class _KPixDropdownOptions {
  // The box matches a default KPixSlider: 24px tall with 8px above and below.
  static const double boxHeight = 24.0;
  static const double margin = 8.0;
  static const double borderRadius = 8.0;
  static const double borderWidth = 1.0;
  static const double borderWidthFocused = 2.0;
  // Same text inset as the text fields.
  static const double textPadding = 8.0;
  static const double tabWidth = 24.0;
  static const double iconSize = 20.0;
  static const double itemHeight = 32.0;
  static const double menuGap = 4.0;
  static const double menuPaddingVertical = 2.0;
  static const int hoverAlpha = 32;
}

/// A dropdown that opens inside the overlay it is shown in.
///
/// [DropdownButton] opens its menu as a route. [Navigator] keeps route entries
/// below every entry that was inserted into the overlay by hand, so a dropdown
/// inside a [KPixOverlay] drops its menu behind the dialog and a second tap
/// trips an assertion in the framework. This one hangs the menu off the entry it
/// lives in, so it is drawn above it.
class KPixDropdown<E> extends StatefulWidget {
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
  State<KPixDropdown<E>> createState() => _KPixDropdownState<E>();
}

class _KPixDropdownState<E> extends State<KPixDropdown<E>> {
  final MenuController _controller = MenuController();
  bool _hovered = false;
  bool _focused = false;
  bool _open = false;

  void _setOpen(final bool open) {
    if (mounted && _open != open) {
      setState(() {_open = open;});
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle textStyle = theme.textTheme.bodyLarge!;

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        return MenuAnchor(
          controller: _controller,
          // The anchor includes the margin below the box.
          alignmentOffset: const Offset(0.0, _KPixDropdownOptions.menuGap - _KPixDropdownOptions.margin),
          onOpen: () => _setOpen(true),
          onClose: () => _setOpen(false),
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll<Color?>(theme.primaryColorDark),
            surfaceTintColor: const WidgetStatePropertyAll<Color?>(Colors.transparent),
            shadowColor: const WidgetStatePropertyAll<Color?>(Colors.transparent),
            elevation: const WidgetStatePropertyAll<double?>(0.0),
            shape: const WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(_KPixDropdownOptions.borderRadius)))),
            side: WidgetStatePropertyAll<BorderSide>(BorderSide(color: theme.primaryColorLight)),
            padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.symmetric(vertical: _KPixDropdownOptions.menuPaddingVertical)),
            //the menu is as wide as the button
            minimumSize: WidgetStatePropertyAll<Size>(Size(constraints.maxWidth, 0.0)),
            maximumSize: WidgetStatePropertyAll<Size>(Size(constraints.maxWidth, double.infinity)),
          ),
          menuChildren: <Widget>[
            for (final MapEntry<E, String> entry in widget.valueMap.entries)
              _buildItem(theme: theme, entry: entry, width: constraints.maxWidth, textStyle: textStyle),
          ],
          child: _buildBox(theme: theme, textStyle: textStyle),
        );
      },
    );
  }

  Widget _buildItem({required final ThemeData theme, required final MapEntry<E, String> entry, required final double width, required final TextStyle textStyle}) {
    final bool selected = entry.key == widget.value;
    final TextStyle style = widget.itemTextStyle?.call(entry.key) ?? textStyle;
    final Color overlay = (selected ? theme.primaryColorDark : theme.primaryColorLight).withAlpha(_KPixDropdownOptions.hoverAlpha);
    final Size size = Size(width, _KPixDropdownOptions.itemHeight);
    return MenuItemButton(
      style: ButtonStyle(
        //the entries carry the width, so the menu ends up as wide as the button
        fixedSize: WidgetStatePropertyAll<Size>(size),
        minimumSize: WidgetStatePropertyAll<Size>(size),
        maximumSize: WidgetStatePropertyAll<Size>(size),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.symmetric(horizontal: _KPixDropdownOptions.textPadding)),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder()),
        backgroundColor: WidgetStatePropertyAll<Color?>(selected ? theme.primaryColorLight : null),
        overlayColor: WidgetStateProperty.resolveWith((final Set<WidgetState> states) =>
            states.contains(WidgetState.hovered) || states.contains(WidgetState.focused) || states.contains(WidgetState.pressed) ? overlay : null),
      ),
      onPressed: () {
        widget.onChanged(entry.key);
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          entry.value,
          style: selected ? style.copyWith(color: theme.primaryColorDark) : style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildBox({required final ThemeData theme, required final TextStyle textStyle}) {
    const BorderRadius radius = BorderRadius.all(Radius.circular(_KPixDropdownOptions.borderRadius));
    final Color fill;
    if (_open) {
      fill = theme.primaryColorDark;
    } else if (_hovered) {
      fill = theme.primaryColorLight.withAlpha(_KPixDropdownOptions.hoverAlpha);
    } else {
      fill = Colors.transparent;
    }

    //the ink needs a material of its own, so the dropdown can also be
    //used where nothing else provides one
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          if (_controller.isOpen) {
            _controller.close();
          } else {
            _controller.open();
          }
        },
        onHover: (final bool hovered) {
          setState(() {_hovered = hovered;});
        },
        onFocusChange: (final bool focused) {
          setState(() {_focused = focused;});
        },
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        // The margin is part of the tap target, like with the text fields.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _KPixDropdownOptions.margin),
          child: Container(
            height: _KPixDropdownOptions.boxHeight,
            foregroundDecoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: theme.primaryColorLight,
                width: _focused ? _KPixDropdownOptions.borderWidthFocused : _KPixDropdownOptions.borderWidth,
              ),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: ColoredBox(
                color: fill,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: _KPixDropdownOptions.textPadding),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.valueMap[widget.value] ?? "",
                            style: widget.itemTextStyle?.call(widget.value) ?? textStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    ColoredBox(
                      color: theme.primaryColorLight,
                      child: SizedBox(
                        width: _KPixDropdownOptions.tabWidth,
                        height: _KPixDropdownOptions.boxHeight,
                        child: Icon(Icons.keyboard_arrow_down, size: _KPixDropdownOptions.iconSize, color: theme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
