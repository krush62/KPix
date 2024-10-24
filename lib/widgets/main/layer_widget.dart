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

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class LayerWidget extends StatefulWidget
{
  final LayerState layerState;
  const LayerWidget({
    super.key,
    required this.layerState,
  });

  @override
  State<LayerWidget> createState() => _LayerWidgetState();
}

class _LayerWidgetState extends State<LayerWidget>
{
  final AppState _appState = GetIt.I.get<AppState>();
  final LayerWidgetOptions _options = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();

  static const Map<LayerVisibilityState, IconData> _visibilityIconMap = {
    LayerVisibilityState.visible: FontAwesomeIcons.eye,
    LayerVisibilityState.hidden: FontAwesomeIcons.eyeSlash,
  };

  static const Map<LayerVisibilityState, String> _visibilityTooltipMap = {
    LayerVisibilityState.visible: "Visible",
    LayerVisibilityState.hidden: "Hidden",
  };

  static const Map<LayerLockState, IconData> _lockIconMap = {
    LayerLockState.unlocked: FontAwesomeIcons.lockOpen,
    LayerLockState.transparency: FontAwesomeIcons.unlockKeyhole,
    LayerLockState.locked: FontAwesomeIcons.lock,
  };

  static const Map<LayerLockState, String> _lockStringMap = {
    LayerLockState.unlocked: "Unlocked",
    LayerLockState.transparency: "Transparency locked",
    LayerLockState.locked: "Locked",
  };

  final LayerLink settingsLink = LayerLink();
  late KPixOverlay settingsMenuDrawing;
  late KPixOverlay settingsMenuReference;

  @override
  void initState() {
    super.initState();
    settingsMenuDrawing = OverlayEntries.getDrawingLayerMenu(
      onDismiss: _closeSettingsMenus,
      layerLink: settingsLink,
      onDelete: _deletePressed,
      onMergeDown: _mergeDownPressed,
      onDuplicate: _duplicatePressed,
    );
    settingsMenuReference = OverlayEntries.getReferenceLayerMenu(
      onDismiss: _closeSettingsMenus,
      layerLink: settingsLink,
      onDelete: _deletePressed,
      onDuplicate: _duplicatePressed,
    );
  }

  void _deletePressed()
  {
    _appState.layerDeleted(deleteLayer: widget.layerState);
    _closeSettingsMenus();
  }

  void _mergeDownPressed()
  {
    _appState.layerMerged(mergeLayer: widget.layerState);
    _closeSettingsMenus();
  }

  void _duplicatePressed()
  {
    _appState.layerDuplicated(duplicateLayer: widget.layerState);
    _closeSettingsMenus();
  }

  void _closeSettingsMenus()
  {
    settingsMenuDrawing.hide();
    settingsMenuReference.hide();
  }

  void _settingsButtonPressed()
  {
    if (widget.layerState.runtimeType == DrawingLayerState)
    {
      settingsMenuDrawing.show(context: context);
    }
    else if (widget.layerState.runtimeType == ReferenceLayerState)
    {
      settingsMenuReference.show(context: context);
    }
  }


  void _visibilityButtonPressed()
  {
    _appState.changeLayerVisibility(layerState: widget.layerState);
  }

  void _lockButtonPressed()
  {
    _appState.changeLayerLockState(layerState: widget.layerState);
  }


  @override
  Widget build(final BuildContext context) {
    return LongPressDraggable<LayerState>(
      delay: Duration(milliseconds: _options.dragDelay),
      data: widget.layerState,
      feedback: Container(
        width: _options.dragFeedbackSize,
        height: _options.dragFeedbackSize,
        color: Theme.of(context).primaryColor.withOpacity(_options.dragOpacity),
      ),
      //childWhenDragging: const SizedBox.shrink(),
      childWhenDragging: Container(
        height: _options.dragTargetHeight,
        color: Theme.of(context).primaryColor,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: _options.outerPadding, right: _options.outerPadding),
        child: SizedBox(
          height: _options.height,
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.layerState.isSelected,
            builder: (final BuildContext context, final bool isSelected, final Widget? child) {
            return Container(
              padding: EdgeInsets.all(_options.innerPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.all(
                    Radius.circular(_options.borderRadius),
                ),
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColorDark,
                  width: _options.borderWidth,
                )
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        right: _options.innerPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<LayerVisibilityState>(
                            valueListenable: widget.layerState.visibilityState,
                            builder: (final BuildContext context, final LayerVisibilityState visibility, final Widget? child) {
                              return Tooltip(
                                message: _visibilityTooltipMap[visibility]! + _hotkeyManager.getShortcutString(action: HotkeyAction.layersSwitchVisibility),
                                waitDuration: AppState.toolTipDuration,
                                child: IconButton.outlined(
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                    maxHeight: _options.buttonSizeMax,
                                    maxWidth: _options.buttonSizeMax,
                                    minWidth: _options.buttonSizeMin,
                                    minHeight: _options.buttonSizeMin,
                                  ),
                                  style: ButtonStyle(
                                    tapTargetSize: MaterialTapTargetSize
                                        .shrinkWrap,
                                    backgroundColor: visibility == LayerVisibilityState.hidden ? WidgetStatePropertyAll(Theme.of(context).primaryColorLight) : null,
                                    iconColor: visibility == LayerVisibilityState.hidden ? WidgetStatePropertyAll(Theme.of(context).primaryColor) : null,
                                  ),
                                  onPressed: _visibilityButtonPressed,
                                  icon: FaIcon(
                                    _visibilityIconMap[visibility],
                                    size: _options.iconSize,
                                  )
                                ),
                              );
                            }
                          ),
                        ),
                        SizedBox(height: _options.innerPadding),
                        Builder(
                          builder: (final BuildContext context) {
                            if (widget.layerState.runtimeType == DrawingLayerState)
                            {
                              final DrawingLayerState drawingLayer = widget.layerState as DrawingLayerState;
                              return Expanded(
                                child: ValueListenableBuilder<LayerLockState>(
                                    valueListenable: drawingLayer.lockState,
                                    builder: (final BuildContext context, final LayerLockState lock, final Widget? child) {
                                      return Tooltip(
                                        message: _lockStringMap[lock]! + _hotkeyManager.getShortcutString(action: HotkeyAction.layersSwitchLock),
                                        waitDuration: AppState.toolTipDuration,
                                        child: IconButton.outlined(
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(
                                              maxHeight: _options.buttonSizeMax,
                                              maxWidth: _options.buttonSizeMax,
                                              minWidth: _options.buttonSizeMin,
                                              minHeight: _options.buttonSizeMin,
                                            ),
                                            style: ButtonStyle(
                                              tapTargetSize: MaterialTapTargetSize
                                                  .shrinkWrap,
                                              backgroundColor: lock == LayerLockState.unlocked ? null : WidgetStatePropertyAll(Theme.of(context).primaryColorLight),
                                              iconColor: lock == LayerLockState.unlocked ? null: WidgetStatePropertyAll(Theme.of(context).primaryColor),
                                            ),
                                            onPressed: _lockButtonPressed,
                                            icon: FaIcon(
                                              _lockIconMap[lock],
                                              size: _options.iconSize,
                                            )
                                        ),
                                      );
                                    }
                                ),
                              );
                            }
                            else //REFERENCE LAYER
                            {
                               return SizedBox.shrink();
                            }
                          },
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _appState.layerSelected(newLayer: widget.layerState);
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ValueListenableBuilder<ui.Image?>(
                            valueListenable: widget.layerState.thumbnail,
                            builder: (final BuildContext context, final ui.Image? img, final Widget? child)
                            {
                              return RawImage(image: img,);
                            },
                          ),
                          Center(
                            child: Text(
                              (widget.layerState.runtimeType == ReferenceLayerState) ? "REF" : "",
                              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                                color: Theme.of(context).primaryColorLight,
                                shadows: <Shadow>[
                                  Shadow(
                                    offset: const Offset(0.0, 1.0),
                                    blurRadius: 2.0,
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        left: _options.innerPadding),
                    child: CompositedTransformTarget(
                      link: settingsLink,
                      child: Tooltip(
                        message: "Settings...",
                        waitDuration: AppState.toolTipDuration,
                        child: IconButton.outlined(
                          constraints: BoxConstraints(
                            maxHeight: _options.buttonSizeMax,
                            maxWidth: _options.buttonSizeMax,
                            minWidth: _options.buttonSizeMin,
                            minHeight: _options.buttonSizeMin,
                          ),
                          style: const ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _settingsButtonPressed,
                          icon: FaIcon(
                            FontAwesomeIcons.bars,
                            size: _options.iconSize,
                          )
                        ),
                      ),
                    ),
                  )
                ],
              )
            );
          }
          )
        ),
      ),
    );
  }

}