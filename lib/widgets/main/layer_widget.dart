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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

class LayerWidget extends StatefulWidget {
  final LayerState layerState;

  const LayerWidget({
    super.key,
    required this.layerState,
  });

  @override
  State<LayerWidget> createState() => _LayerWidgetState();
}

const Map<Type, IconData> layerIconMap = <Type, IconData>{
  ReferenceLayerState: FontAwesomeIcons.image,
  GridLayerState: FontAwesomeIcons.tableCells,
  ShadingLayerState: Icons.exposure,
};

class _LayerWidgetState extends State<LayerWidget> {
  final AppState _appState = GetIt.I.get<AppState>();
  final LayerWidgetOptions _options =
      GetIt.I.get<PreferenceManager>().layerWidgetOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();

  static const Map<LayerVisibilityState, IconData> _visibilityIconMap =
      <LayerVisibilityState, IconData>{
    LayerVisibilityState.visible: FontAwesomeIcons.eye,
    LayerVisibilityState.hidden: FontAwesomeIcons.eyeSlash,
  };

  static const Map<LayerVisibilityState, String> _visibilityTooltipMap =
      <LayerVisibilityState, String>{
    LayerVisibilityState.visible: "Visible",
    LayerVisibilityState.hidden: "Hidden",
  };

  static const Map<LayerLockState, IconData> _lockIconMap =
      <LayerLockState, IconData>{
    LayerLockState.unlocked: FontAwesomeIcons.lockOpen,
    LayerLockState.transparency: FontAwesomeIcons.unlockKeyhole,
    LayerLockState.locked: FontAwesomeIcons.lock,
  };

  static const Map<LayerLockState, String> _lockStringMap =
      <LayerLockState, String>{
    LayerLockState.unlocked: "Unlocked",
    LayerLockState.transparency: "Transparency locked",
    LayerLockState.locked: "Locked",
  };

  final LayerLink actionsLink = LayerLink();
  late KPixOverlay actionsMenuDrawing;
  late KPixOverlay actionsMenuReduced;
  late KPixOverlay actionsMenuRaster;

  @override
  void initState()
  {
    super.initState();
    actionsMenuDrawing = getDrawingLayerMenu(
      onDismiss: _closeActionsMenus,
      layerLink: actionsLink,
      onDelete: _deletePressed,
      onMergeDown: _mergeDownPressed,
      onDuplicate: _duplicatePressed,
    );
    actionsMenuReduced = getReducedLayerMenu(
      onDismiss: _closeActionsMenus,
      layerLink: actionsLink,
      onDelete: _deletePressed,
      onDuplicate: _duplicatePressed,
    );
    actionsMenuRaster = getRasterLayerMenu(
      onDismiss: _closeActionsMenus,
      layerLink: actionsLink,
      onDelete: _deletePressed,
      onDuplicate: _duplicatePressed,
      onRaster: _rasterPressed,
    );
  }

  void _deletePressed()
  {
    _appState.layerDeleted(deleteLayer: widget.layerState);
    _closeActionsMenus();
  }

  void _mergeDownPressed()
  {
    _appState.layerMerged(mergeLayer: widget.layerState);
    _closeActionsMenus();
  }

  void _duplicatePressed()
  {
    _appState.layerDuplicated(duplicateLayer: widget.layerState);
    _closeActionsMenus();
  }

  void _rasterPressed()
  {
    _appState.layerRastered(rasterLayer: widget.layerState);
    _closeActionsMenus();
  }

  void _closeActionsMenus()
  {
    actionsMenuDrawing.hide();
    actionsMenuReduced.hide();
    actionsMenuRaster.hide();
  }

  void _actionsButtonPressed()
  {
    final Type layerType = widget.layerState.runtimeType;
    if (layerType == DrawingLayerState) {
      actionsMenuDrawing.show(context: context);
    } else if (layerType == GridLayerState || layerType == ShadingLayerState) {
      actionsMenuRaster.show(context: context);
    } else {
      actionsMenuReduced.show(context: context);
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

  void _settingsButtonPressed()
  {
    _appState.selectLayer(newLayer: widget.layerState);
    _appState.layerSettingsVisible = true;
  }


  @override
  Widget build(final BuildContext context)
  {
    return Padding(
      padding: EdgeInsets.only(
          left: _options.outerPadding, right: _options.outerPadding,),
      child: SizedBox(
        height: _options.height,
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.layerState.isSelected,
          builder: (final BuildContext context, final bool isSelected,final Widget? child,)
          {
            return Row(
              children: [
                Draggable<LayerState>(
                  data: widget.layerState,
                  feedback: Container(
                    width: _options.dragFeedbackSize * 3,
                    height: _options.dragFeedbackSize,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha((_options.dragOpacity * 255.0).toInt()),
                      borderRadius: BorderRadius.all(
                        Radius.circular(_options.borderRadius),
                      ),
                      border: Border.all(
                        color: Theme.of(context).primaryColorDark,
                        width: _options.borderWidth,
                      ),
                    ),
                  ),
                  childWhenDragging: IconButton(
                    padding: EdgeInsets.only(right: _options.innerPadding),
                    iconSize: _options.buttonSizeMin,
                    constraints: const BoxConstraints(),
                    icon: FaIcon(
                      color: Theme.of(context).indicatorColor,
                      FontAwesomeIcons.gripVertical,
                    ),
                    onPressed: null,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.only(right: _options.innerPadding),
                    iconSize: _options.buttonSizeMin,
                    constraints: BoxConstraints(
                      minHeight: _options.height,
                    ),
                    icon: FaIcon(
                      color: Theme.of(context).primaryColor,
                      FontAwesomeIcons.gripVertical,
                    ),
                    onPressed: null,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(_options.innerPadding),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.all(
                        Radius.circular(_options.borderRadius),
                      ),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColorLight
                            : Theme.of(context).primaryColorDark,
                        width: _options.borderWidth,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(
                            right: _options.innerPadding,
                          ),
                          child: Builder(
                            builder: (final BuildContext context) {
                              final Column leftColumn = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Expanded(
                                    child: ValueListenableBuilder<
                                        LayerVisibilityState>(
                                      valueListenable:
                                          widget.layerState.visibilityState,
                                      builder: (final BuildContext context,
                                          final LayerVisibilityState visibility,
                                          final Widget? child,) {
                                        return Tooltip(
                                          message:
                                              _visibilityTooltipMap[visibility]! +
                                                  _hotkeyManager.getShortcutString(
                                                      action: HotkeyAction
                                                          .layersSwitchVisibility,),
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
                                              tapTargetSize:
                                                  MaterialTapTargetSize.shrinkWrap,
                                              backgroundColor: visibility ==
                                                      LayerVisibilityState.hidden
                                                  ? WidgetStatePropertyAll<Color?>(
                                                      Theme.of(context)
                                                          .primaryColorLight,)
                                                  : null,
                                              iconColor: visibility ==
                                                      LayerVisibilityState.hidden
                                                  ? WidgetStatePropertyAll<Color?>(
                                                      Theme.of(context)
                                                          .primaryColor,)
                                                  : null,
                                            ),
                                            onPressed: _visibilityButtonPressed,
                                            icon: FaIcon(
                                              _visibilityIconMap[visibility],
                                              size: _options.iconSize,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );

                              if (widget.layerState.runtimeType ==
                                      DrawingLayerState ||
                                  widget.layerState.runtimeType ==
                                      ShadingLayerState) {
                                final ValueNotifier<LayerLockState> layerLockState =
                                    (widget.layerState.runtimeType ==
                                            DrawingLayerState)
                                        ? (widget.layerState as DrawingLayerState)
                                            .lockState
                                        : (widget.layerState as ShadingLayerState)
                                            .lockState;
                                leftColumn.children
                                    .add(SizedBox(height: _options.innerPadding));
                                leftColumn.children.add(
                                  Expanded(
                                    child: ValueListenableBuilder<LayerLockState>(
                                      valueListenable: layerLockState,
                                      builder: (final BuildContext context,
                                          final LayerLockState lock,
                                          final Widget? child,) {
                                        return Tooltip(
                                          message: _lockStringMap[lock]! +
                                              _hotkeyManager.getShortcutString(
                                                  action: HotkeyAction
                                                      .layersSwitchLock,),
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
                                              tapTargetSize:
                                                  MaterialTapTargetSize.shrinkWrap,
                                              backgroundColor: lock ==
                                                      LayerLockState.unlocked
                                                  ? null
                                                  : WidgetStatePropertyAll<Color?>(
                                                      Theme.of(context)
                                                          .primaryColorLight,),
                                              iconColor: lock ==
                                                      LayerLockState.unlocked
                                                  ? null
                                                  : WidgetStatePropertyAll<Color?>(
                                                      Theme.of(context)
                                                          .primaryColor,),
                                            ),
                                            onPressed: _lockButtonPressed,
                                            icon: FaIcon(
                                              _lockIconMap[lock],
                                              size: _options.iconSize,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                              return leftColumn;
                            },
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _appState.selectLayer(newLayer: widget.layerState);
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                ValueListenableBuilder<ui.Image?>(
                                  valueListenable: widget.layerState.thumbnail,
                                  builder: (final BuildContext context,
                                      final ui.Image? img, final Widget? child,) {
                                    return RawImage(
                                      image: img,
                                    );
                                  },
                                ),
                                Center(
                                  child: FaIcon(
                                    layerIconMap[widget.layerState.runtimeType],
                                    size: _options.height / 2,
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
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: _options.innerPadding,
                          ),
                          child: Builder(
                            builder: (final BuildContext context) {
                              final Column rightColumn = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Expanded(
                                    child: CompositedTransformTarget(
                                      link: actionsLink,
                                      child: Tooltip(
                                        message: "Layer Actions...",
                                        waitDuration: AppState.toolTipDuration,
                                        child: Builder(
                                          builder: (final BuildContext context) {
                                            ValueNotifier<LayerLockState> lockStateNotifier = ValueNotifier<LayerLockState>(LayerLockState.unlocked);
                                            if (widget.layerState is RasterableLayerState)
                                            {
                                              final RasterableLayerState rasterLayer = widget.layerState as RasterableLayerState;
                                              lockStateNotifier = rasterLayer.lockState;
                                            }
                                            return ValueListenableBuilder<LayerLockState>(
                                              valueListenable: lockStateNotifier,
                                              builder: (final BuildContext context, final LayerLockState lockState, final Widget? child) {
                                                return IconButton.outlined(
                                                  padding: EdgeInsets.zero,
                                                  constraints: BoxConstraints(
                                                    maxHeight: _options.buttonSizeMax,
                                                    maxWidth: _options.buttonSizeMax,
                                                    minWidth: _options.buttonSizeMin,
                                                    minHeight: _options.buttonSizeMin,
                                                  ),
                                                  style: const ButtonStyle(
                                                    tapTargetSize:
                                                    MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  onPressed: lockState != LayerLockState.locked ? _actionsButtonPressed : null,
                                                  icon: FaIcon(
                                                    FontAwesomeIcons.bars,
                                                    size: _options.iconSize,
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );

                              if (widget.layerState.runtimeType ==
                                      DrawingLayerState ||
                                  widget.layerState.runtimeType ==
                                      ShadingLayerState) {
                                rightColumn.children
                                    .add(SizedBox(height: _options.innerPadding));

                                rightColumn.children.add(
                                  Expanded(
                                    child: Tooltip(
                                      message: "Settings",
                                      waitDuration: AppState.toolTipDuration,
                                      child: Builder(
                                        builder: (final BuildContext context) {
                                          ValueNotifier<LayerLockState> lockStateNotifier = ValueNotifier<LayerLockState>(LayerLockState.unlocked);
                                          Listenable changeListenable = ChangeNotifier();
                                          final LayerState layer = widget.layerState;
                                          if (layer is RasterableLayerState)
                                          {
                                            lockStateNotifier = layer.lockState;
                                            changeListenable = layer.layerSettings;
                                          }
                                          return ValueListenableBuilder<LayerLockState>(
                                            valueListenable: lockStateNotifier,
                                            builder: (final BuildContext context, final LayerLockState lockState, final Widget? child) {
                                              return ListenableBuilder(
                                                listenable: changeListenable,
                                                builder: (final BuildContext context, final Widget? child) {
                                                  final LayerState layer = widget.layerState;
                                                  final bool hasChanges = layer is RasterableLayerState && layer.layerSettings.hasActiveSettings();
                                                  return IconButton.outlined(
                                                    padding: EdgeInsets.zero,
                                                    constraints: BoxConstraints(
                                                      maxHeight: _options.buttonSizeMax,
                                                      maxWidth: _options.buttonSizeMax,
                                                      minWidth: _options.buttonSizeMin,
                                                      minHeight: _options.buttonSizeMin,
                                                    ),
                                                    style: ButtonStyle(
                                                      tapTargetSize:
                                                      MaterialTapTargetSize.shrinkWrap,
                                                      backgroundColor: !hasChanges ? null : WidgetStatePropertyAll<Color?>(
                                                        Theme.of(context)
                                                            .primaryColorLight,),
                                                      iconColor: !hasChanges
                                                          ? null
                                                          : WidgetStatePropertyAll<Color?>(
                                                        Theme.of(context)
                                                            .primaryColor,),
                                                    ),
                                                    onPressed: lockState != LayerLockState.locked ? _settingsButtonPressed : null,
                                                    icon: FaIcon(
                                                      FontAwesomeIcons.gear,
                                                      size: _options.iconSize,
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return rightColumn;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
