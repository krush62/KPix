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
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

class OverlaySelectionAlignMenu extends StatefulWidget
 {
   final LayerLink layerLink;
   final Function() onDismiss;
   final Function() onAlignLeft;
   final Function() onAlignRight;
   final Function() onAlignTop;
   final Function() onAlignBottom;
   final Function() onAlignCenterH;
   final Function() onAlignCenterV;


   const OverlaySelectionAlignMenu({
     super.key,
     required this.layerLink,
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
   final OverlayEntrySubMenuOptions _options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
   late AnimationController _controller;
   static const int _entryCount = 6;

   @override
   void initState()
   {
     super.initState();
     _controller = AnimationController(
       vsync: this,
       duration: Duration(milliseconds: _options.animationLengthMs),
     );
     _controller.forward();
   }

   @override
   void dispose()
   {
     _controller.dispose();
     super.dispose();
   }

   Widget _getEntry({required final String toolTipMessage, required final Function() onPressed, required final IconData icon})
   {
     return Padding(
       padding: EdgeInsets.all(_options.buttonSpacing / 2),
       child: Tooltip(
         message: toolTipMessage,
         preferBelow: false,
         waitDuration: AppState.toolTipDuration,
         child: IconButton.outlined(
           constraints: const BoxConstraints(),
           padding: EdgeInsets.all(_options.buttonSpacing),
           onPressed: onPressed,
           icon: Icon(icon),
         ),
       ),
     );
   }


   @override
   Widget build(final BuildContext context)
   {
     return Positioned(
       width: _options.width / 2,
       child: CompositedTransformFollower(
         link: widget.layerLink,
         showWhenUnlinked: false,
         offset: Offset(
           _options.offsetX,
           -(_entryCount + 1) *  (_options.offsetY + _options.buttonSpacing) - _options.buttonSpacing,
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
                 _getEntry(toolTipMessage: "Center Horizontally", onPressed: widget.onAlignCenterH, icon: Icons.align_horizontal_center),
                 _getEntry(toolTipMessage: "Center Vertically", onPressed: widget.onAlignCenterV, icon: Icons.align_vertical_center),
                 _getEntry(toolTipMessage: "Left", onPressed: widget.onAlignLeft, icon: Icons.align_horizontal_left),
                 _getEntry(toolTipMessage: "Right", onPressed: widget.onAlignRight, icon: Icons.align_horizontal_right),
                 _getEntry(toolTipMessage: "Top", onPressed: widget.onAlignTop, icon: Icons.align_vertical_top),
                 _getEntry(toolTipMessage: "Bottom", onPressed: widget.onAlignBottom, icon: Icons.align_vertical_bottom),
               ],
             ),
           ),
         ),
       ),
     );
   }
 }
