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
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/overlays/overlay_anchor.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// A popup menu with the buttons for aligning the current selection.
///
/// The menu scales into view above the [OverlayAnchor] carrying [anchorKey],
/// because it is opened from the selection bar at the bottom of the canvas, so
/// it has to be inserted into an overlay [Stack] together with the barrier that
/// dismisses it. Pressing a button only invokes the matching callback, closing
/// the menu is left to the owner of the overlay.
class OverlaySelectionAlignMenu extends StatefulWidget
 {
   /// The key of the [OverlayAnchor] the menu is positioned relative to.
   final GlobalKey anchorKey;
   final Function() onDismiss;
   final Function() onAlignLeft;
   final Function() onAlignRight;
   final Function() onAlignTop;
   final Function() onAlignBottom;
   final Function() onAlignCenterH;
   final Function() onAlignCenterV;


   const OverlaySelectionAlignMenu({
     super.key,
     required this.anchorKey,
     required this.onDismiss,
     required this.onAlignLeft,
     required this.onAlignRight,
     required this.onAlignTop,
     required this.onAlignBottom,
     required this.onAlignCenterH,
     required this.onAlignCenterV,
   });

   @override
   State<OverlaySelectionAlignMenu> createState() => _OverlaySelectionAlignMenuState();
 }

 class _OverlaySelectionAlignMenuState extends State<OverlaySelectionAlignMenu> with SingleTickerProviderStateMixin
 {
   /// The driver of the scale animation the menu opens with.
   late AnimationController _controller;

   /// The number of entries the menu is shifted upwards by, which has to match
   /// the number of buttons built in [build].
   static const int _entryCount = 6;

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
   /// The [toolTipMessage] is shown after [AppState.toolTipDuration] of
   /// hovering and is placed above the entry, so it does not cover the entries
   /// below. Pressing the entry calls [onPressed].
   Widget _getEntry({required final String toolTipMessage, required final Function() onPressed, required final IconData icon})
   {
     return Padding(
       padding: const EdgeInsets.all(OverlayEntrySubMenuOptions.buttonSpacing / 2),
       child: Tooltip(
         message: toolTipMessage,
         preferBelow: false,
         waitDuration: AppState.toolTipDuration,
         child: IconButton.outlined(
           constraints: const BoxConstraints(),
           padding: const EdgeInsets.all(OverlayEntrySubMenuOptions.buttonSpacing),
           onPressed: onPressed,
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
       width: OverlayEntrySubMenuOptions.width / 3,
       offset: const Offset(
         OverlayEntrySubMenuOptions.offsetX,
         -(_entryCount + 1) *  (OverlayEntrySubMenuOptions.offsetY + OverlayEntrySubMenuOptions.buttonSpacing) - OverlayEntrySubMenuOptions.buttonSpacing,
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
               _getEntry(toolTipMessage: "Center Horizontally", onPressed: widget.onAlignCenterH, icon: TablerIcons.layout_align_middle),
               _getEntry(toolTipMessage: "Center Vertically", onPressed: widget.onAlignCenterV, icon: TablerIcons.layout_align_center),
               _getEntry(toolTipMessage: "Left", onPressed: widget.onAlignLeft, icon: TablerIcons.layout_align_left),
               _getEntry(toolTipMessage: "Right", onPressed: widget.onAlignRight, icon: TablerIcons.layout_align_right),
               _getEntry(toolTipMessage: "Top", onPressed: widget.onAlignTop, icon: TablerIcons.layout_align_top),
               _getEntry(toolTipMessage: "Bottom", onPressed: widget.onAlignBottom, icon: TablerIcons.layout_align_bottom),
             ],
           ),
         ),
       ),
     );
   }
 }
