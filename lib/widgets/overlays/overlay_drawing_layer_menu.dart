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
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

class OverlayDrawingLayerMenu extends StatefulWidget
{
  final LayerLink layerLink;
  final Function() onDelete;
  final Function() onMergeDown;
  final Function() onDuplicate;
  const OverlayDrawingLayerMenu({super.key, required this.onDelete, required this.onMergeDown, required this.onDuplicate, required this.layerLink});

  @override
  State<OverlayDrawingLayerMenu> createState() => _OverlayDrawingLayerMenuState();
}

class _OverlayDrawingLayerMenuState extends State<OverlayDrawingLayerMenu> with SingleTickerProviderStateMixin
{
  final OverlayEntrySubMenuOptions _options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
  final LayerWidgetOptions _layerWidgetOptions = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final int _buttonCount = 3;
  late double _width;
  late double _height;
  late AnimationController _controller;

  @override
  void initState()
  {
    super.initState();
    _width = (_options.buttonHeight + (_options.buttonSpacing * 2)) * _buttonCount;
    _height = _options.buttonHeight + 2 * _options.buttonSpacing;
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
      width: _width,
      height: _height,
      child: CompositedTransformFollower(
        link: widget.layerLink,
        showWhenUnlinked: false,
        offset: Offset(
          -_width,
          _layerWidgetOptions.height/2 - _height/2 - _layerWidgetOptions.innerPadding,
        ),
        child: Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Tooltip(
                  message: "Delete Layer${_hotkeyManager.getShortcutString(action: HotkeyAction.layersDelete)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(
                      _options.buttonSpacing,),
                    onPressed: () {widget.onDelete();},
                    icon: FaIcon(
                      FontAwesomeIcons.trashCan,
                      size: _options.buttonHeight,),
                    color: Theme.of(context).primaryColorLight,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Theme.of(context).primaryColor,),
                  ),
                ),
                Tooltip(
                  message: "Duplicate Layer${_hotkeyManager.getShortcutString(action: HotkeyAction.layersDuplicate)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(_options.buttonSpacing),
                    onPressed: () {widget.onDuplicate();},
                    icon: FaIcon(
                      FontAwesomeIcons.clone,
                      size: _options.buttonHeight,),
                    color: Theme.of(context).primaryColorLight,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Theme.of(context).primaryColor,),
                  ),
                ),
                Tooltip(
                  message: "Merge Down Layer${_hotkeyManager.getShortcutString(action: HotkeyAction.layersMerge)}",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.all(_options.buttonSpacing),
                    onPressed: () {widget.onMergeDown();},
                    icon: FaIcon(
                      FontAwesomeIcons.turnDown,
                      size: _options.buttonHeight,),
                    color: Theme.of(context).primaryColorLight,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Theme.of(context).primaryColor,),
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
