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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

class OverlayAddNewLayerMenu extends StatefulWidget
{
  final LayerLink layerLink;
  final Function() onNewDrawingLayer;
  final Function() onNewReferenceLayer;
  final Function() onNewGridLayer;
  final Function() onNewShadingLayer;
  final Function() onNewDitherLayer;

  const OverlayAddNewLayerMenu({
    super.key,
    required this.layerLink,
    required this.onNewDrawingLayer,
    required this.onNewReferenceLayer,
    required this.onNewGridLayer,
    required this.onNewShadingLayer,
    required this.onNewDitherLayer,
  });


  @override
  State<OverlayAddNewLayerMenu> createState() => _OverlayAddNewLayerMenuState();

}

class _OverlayAddNewLayerMenuState extends State<OverlayAddNewLayerMenu> with SingleTickerProviderStateMixin
{
  final OverlayEntrySubMenuOptions _options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  late AnimationController _controller;

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
          _options.offsetY + _options.buttonSpacing,
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
                Padding(
                  padding: EdgeInsets.all(_options.buttonSpacing / 2),
                  child: Tooltip(
                    message: "Add New Drawing Layer${_hotkeyManager.getShortcutString(action: HotkeyAction.layersNewDrawing)}",
                    preferBelow: false,
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(_options.buttonSpacing),
                      onPressed: () {widget.onNewDrawingLayer();},
                      icon: FaIcon(
                        FontAwesomeIcons.paintbrush,
                        size: _options.buttonHeight,
                      ) ,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.buttonSpacing / 2),
                  child: Tooltip(
                    message: "Add New Shading Layer${_hotkeyManager.getShortcutString(action: HotkeyAction.layersNewShading)}",
                    preferBelow: false,
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(_options.buttonSpacing),
                      onPressed: () {widget.onNewShadingLayer();},
                      icon: FaIcon(
                        Icons.exposure,
                        size: _options.buttonHeight,
                      ),
                    )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.buttonSpacing / 2),
                  child: Tooltip(
                    message: "Add New Dither Layer",
                    preferBelow: false,
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(_options.buttonSpacing),
                      onPressed: () {widget.onNewDitherLayer();},
                      icon: FaIcon(
                        Icons.gradient,
                        size: _options.buttonHeight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.buttonSpacing / 2),
                  child: Tooltip(
                    message: "Add New Reference Layer${_hotkeyManager.getShortcutString(action: HotkeyAction.layersNewReference)}",
                    preferBelow: false,
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(_options.buttonSpacing),
                      onPressed: () {widget.onNewReferenceLayer();},
                      icon: FaIcon(
                        FontAwesomeIcons.image,
                        size: _options.buttonHeight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.buttonSpacing / 2),
                  child: Tooltip(
                    message: "Add New Grid Layer${_hotkeyManager.getShortcutString(action: HotkeyAction.layersNewGrid)}",
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(_options.buttonSpacing),
                      onPressed: () {widget.onNewGridLayer();},
                      icon: FaIcon(
                        FontAwesomeIcons.tableCells,
                        size: _options.buttonHeight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
