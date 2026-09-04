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
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/layer_widget_options.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/widgets/overlays/overlay_anchor.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// A popup menu with the actions available for a layer that can only be
/// deleted or duplicated.
///
/// The menu scales into view left of the [OverlayAnchor] carrying [anchorKey],
/// vertically centred on the layer entry, so it has to be inserted into an
/// overlay [Stack] together with the barrier that dismisses it. Pressing a
/// button only invokes the matching callback, closing the menu is left to the
/// owner of the overlay.
class OverlayReducedLayerMenu extends StatefulWidget
{
  /// The key of the [OverlayAnchor] the menu is positioned relative to.
  final GlobalKey anchorKey;
  final Function() onDelete;
  final Function() onDuplicate;
  const OverlayReducedLayerMenu({super.key, required this.onDelete,  required this.onDuplicate, required this.anchorKey});

  @override
  State<OverlayReducedLayerMenu> createState() => _OverlayReducedLayerMenuState();
}

class _OverlayReducedLayerMenuState extends State<OverlayReducedLayerMenu> with SingleTickerProviderStateMixin
{
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();

  /// The number of entries the menu is sized for, which has to match the number
  /// of buttons built in [build].
  final int _buttonCount = 2;

  /// The edge length of a menu button relative to the icon it contains.
  final double _buttonToIconRatio = 1.7;

  /// The width of the whole button row.
  late double _width;

  /// The height of the whole button row, which is the height of a single button.
  late double _height;

  /// The driver of the scale animation the menu opens with.
  late AnimationController _controller;

  @override
  void initState()
  {
    super.initState();
    _width = ((OverlayEntrySubMenuOptions.buttonHeight * _buttonToIconRatio) + (OverlayEntrySubMenuOptions.buttonSpacing / 2)) * _buttonCount;
    _height = OverlayEntrySubMenuOptions.buttonHeight * _buttonToIconRatio;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: OverlayEntrySubMenuOptions.animationLengthMs),
    );
    // the menu is built when it is already visible, so the animation starts right away
    _controller.forward();
  }

  @override
  void dispose()
  {
    _controller.dispose();
    super.dispose();
  }

  /// A single square menu entry showing [icon].
  ///
  /// The [tooltip] is shown after [toolTipDuration] of hovering,
  /// pressing the entry calls [onPressedFunc].
  Tooltip _createMenuButton({required final String tooltip, required final IconData icon, required final void Function() onPressedFunc})
  {
    return Tooltip(
      message: tooltip,
      waitDuration: toolTipDuration,
      child: SizedBox(
        width: OverlayEntrySubMenuOptions.buttonHeight * _buttonToIconRatio,
        height: OverlayEntrySubMenuOptions.buttonHeight * _buttonToIconRatio,
        child: IconButton.outlined(
          padding: const EdgeInsets.all(OverlayEntrySubMenuOptions.buttonSpacing),
          onPressed: onPressedFunc,
          icon: Icon(icon),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context)
  {
    return AnchoredOverlayBox(
      anchorKey: widget.anchorKey,
      width: _width,
      height: _height,
      offset: Offset(
        -_width,
        LayerWidgetOptions.height/2 - _height/2 - LayerWidgetOptions.innerPadding,
      ),
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _createMenuButton(tooltip: "Delete Layer${_hotkeyManager.getShortcutString(action: HotkeyAction.layersDelete)}", icon: TablerIcons.trash, onPressedFunc: widget.onDelete),
              _createMenuButton(tooltip: "Duplicate Layer${_hotkeyManager.getShortcutString(action: HotkeyAction.layersDuplicate)}", icon: TablerIcons.squares, onPressedFunc: widget.onDuplicate),
            ],
          ),
        ),
      ),
    );
  }
}
