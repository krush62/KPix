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
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/widgets/overlays/overlay_anchor.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// A popup menu with the buttons for starting, opening and importing a project.
///
/// The menu scales into view below the [OverlayAnchor] carrying [anchorKey], so
/// it has to be inserted into an overlay [Stack] together with the barrier that
/// dismisses it. Pressing a button only invokes the matching callback, closing
/// the menu is left to the owner of the overlay.
class OverlayLoadMenu extends StatefulWidget
{
  /// The key of the [OverlayAnchor] the menu is positioned relative to.
  final GlobalKey anchorKey;
  final Function() onNewFile;
  final Function() onLoadFile;
  final Function() onImportFile;
  const OverlayLoadMenu({super.key, required this.anchorKey, required this.onNewFile, required this.onImportFile, required this.onLoadFile});

  @override
  State<OverlayLoadMenu> createState() => _OverlayLoadMenuState();
}

class _OverlayLoadMenuState extends State<OverlayLoadMenu> with SingleTickerProviderStateMixin
{
  /// The driver of the scale animation the menu opens with.
  late AnimationController _controller;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();

  @override
  void initState()
  {
    super.initState();
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

  /// A single menu entry showing [icon], padded to line up with its neighbours.
  ///
  /// The [tooltip] is shown after [toolTipDuration] of hovering,
  /// pressing the entry calls [onPressedFunc].
  Padding _createMenuButton({required final String tooltip, required final IconData icon, required final void Function() onPressedFunc})
  {
    return Padding(
      padding: const EdgeInsets.all(OverlayEntrySubMenuOptions.buttonSpacing / 2),
      child: Tooltip(
        message: tooltip,
        waitDuration: toolTipDuration,
        child: IconButton.outlined(
          constraints: const BoxConstraints(),
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
      width: OverlayEntrySubMenuOptions.width / 2,
      offset: const Offset(
        OverlayEntrySubMenuOptions.offsetX,
        OverlayEntrySubMenuOptions.offsetY + OverlayEntrySubMenuOptions.buttonSpacing,
      ),
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _createMenuButton(tooltip: "New Project${_hotkeyManager.getShortcutString(action: HotkeyAction.generalNew)}", icon: TablerIcons.file, onPressedFunc: widget.onNewFile),
              _createMenuButton(tooltip: "Open Project${_hotkeyManager.getShortcutString(action: HotkeyAction.generalOpen)}", icon: TablerIcons.folder_open, onPressedFunc: widget.onLoadFile),
              _createMenuButton(tooltip: "Import Image", icon: TablerIcons.file_import, onPressedFunc: widget.onImportFile),
            ],
          ),
        ),
      ),
    );
  }
}
