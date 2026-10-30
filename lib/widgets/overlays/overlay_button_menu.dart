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
import 'package:kpix/layer_widget_options.dart';
import 'package:kpix/widgets/overlays/overlay_anchor.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// One button of an [OverlayButtonMenu].
class OverlayMenuEntry
{
  const OverlayMenuEntry({required this.tooltip, required this.icon, required this.onPressed, this.rotateIcon = false});

  final String tooltip;
  final IconData icon;
  final Function() onPressed;

  /// Turns the icon around, for arrows that point the wrong way.
  final bool rotateIcon;
}

enum _MenuPlacement
{
  below,
  above,
  leftOfLayer,
}

/// A popup menu of icon buttons that scales into view next to the
/// [OverlayAnchor] carrying [anchorKey].
///
/// It has to be inserted into an overlay [Stack] together with the barrier that
/// dismisses it. Pressing a button only invokes its callback, closing the menu
/// is left to the owner of the overlay.
class OverlayButtonMenu extends StatefulWidget
{
  /// A column of buttons below the anchor and centred on it.
  const OverlayButtonMenu.below({super.key, required this.anchorKey, required this.entries, this.width = OverlayEntrySubMenuOptions.width / 2}) : _placement = _MenuPlacement.below;

  /// A column of buttons above the anchor and centred on it.
  const OverlayButtonMenu.above({super.key, required this.anchorKey, required this.entries, this.width = OverlayEntrySubMenuOptions.width / 2}) : _placement = _MenuPlacement.above;

  /// A row of square buttons left of the layer entry the anchor marks.
  const OverlayButtonMenu.leftOfLayer({super.key, required this.anchorKey, required this.entries}) : _placement = _MenuPlacement.leftOfLayer, width = 0;

  final GlobalKey anchorKey;
  final List<OverlayMenuEntry> entries;

  /// The width of a column; a row is as wide as its buttons.
  final double width;
  final _MenuPlacement _placement;

  @override
  State<OverlayButtonMenu> createState() => _OverlayButtonMenuState();
}

class _OverlayButtonMenuState extends State<OverlayButtonMenu> with SingleTickerProviderStateMixin
{
  /// The edge length of a row button relative to the icon it contains.
  static const double _buttonToIconRatio = 1.7;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: OverlayEntrySubMenuOptions.animationLengthMs),
  );

  @override
  void initState()
  {
    super.initState();
    // the menu is built when it is already visible, so the animation starts right away
    _controller.forward();
  }

  @override
  void dispose()
  {
    _controller.dispose();
    super.dispose();
  }

  Widget _icon({required final OverlayMenuEntry entry})
  {
    final Icon icon = Icon(entry.icon);
    return entry.rotateIcon ? Transform.rotate(angle: pi, child: icon) : icon;
  }

  Widget _columnButton({required final OverlayMenuEntry entry})
  {
    return Padding(
      padding: const EdgeInsets.all(OverlayEntrySubMenuOptions.buttonSpacing / 2),
      child: IconButton.outlined(
        tooltip: entry.tooltip,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(OverlayEntrySubMenuOptions.buttonSpacing),
        onPressed: entry.onPressed,
        icon: _icon(entry: entry),
      ),
    );
  }

  Widget _rowButton({required final OverlayMenuEntry entry})
  {
    return SizedBox(
      width: OverlayEntrySubMenuOptions.buttonHeight * _buttonToIconRatio,
      height: OverlayEntrySubMenuOptions.buttonHeight * _buttonToIconRatio,
      child: IconButton.outlined(
        tooltip: entry.tooltip,
        padding: const EdgeInsets.all(OverlayEntrySubMenuOptions.buttonSpacing),
        onPressed: entry.onPressed,
        icon: _icon(entry: entry),
      ),
    );
  }

  Widget _animated({required final Widget child})
  {
    return Material(
      color: Colors.transparent,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)),
        child: child,
      ),
    );
  }

  @override
  Widget build(final BuildContext context)
  {
    if (widget._placement == _MenuPlacement.leftOfLayer)
    {
      const double height = OverlayEntrySubMenuOptions.buttonHeight * _buttonToIconRatio;
      final double width = (height + (OverlayEntrySubMenuOptions.buttonSpacing / 2)) * widget.entries.length;
      return AnchoredOverlayBox(
        anchorKey: widget.anchorKey,
        width: width,
        height: height,
        offset: Offset(-width, LayerWidgetOptions.height / 2 - height / 2 - LayerWidgetOptions.innerPadding),
        child: _animated(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[for (final OverlayMenuEntry entry in widget.entries) _rowButton(entry: entry)],
          ),
        ),
      );
    }

    final double offsetY = widget._placement == _MenuPlacement.below
        ? OverlayEntrySubMenuOptions.offsetY + OverlayEntrySubMenuOptions.buttonSpacing
        : -(widget.entries.length + 1) * (OverlayEntrySubMenuOptions.offsetY + OverlayEntrySubMenuOptions.buttonSpacing) - OverlayEntrySubMenuOptions.buttonSpacing;
    return AnchoredOverlayBox(
      anchorKey: widget.anchorKey,
      width: widget.width,
      centerHorizontally: true,
      offset: Offset(OverlayEntrySubMenuOptions.offsetX, offsetY),
      child: _animated(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[for (final OverlayMenuEntry entry in widget.entries) _columnButton(entry: entry)],
        ),
      ),
    );
  }
}
