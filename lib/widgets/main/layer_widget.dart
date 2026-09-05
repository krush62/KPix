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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/layer_widget_options.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/util/layer_color_supplier.dart';
import 'package:kpix/widgets/overlays/overlay_anchor.dart';
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

class _LayerWidgetState extends State<LayerWidget> {
  final DocumentState _documentState = GetIt.I.get<DocumentState>();
  final LayerManager _layerManager = GetIt.I.get<LayerManager>();
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();


  final GlobalKey actionsAnchorKey = GlobalKey();
  late KPixOverlay actionsMenuDrawing;
  late KPixOverlay actionsMenuDrawingLinked;
  late KPixOverlay actionsMenuReduced;
  late KPixOverlay actionsMenuRaster;


  @override
  void initState()
  {
    super.initState();
    actionsMenuDrawing = getDrawingLayerMenu(
      onDismiss: _closeActionsMenus,
      anchorKey: actionsAnchorKey,
      onDelete: _deletePressed,
      onMergeDown: _mergeDownPressed,
      onDuplicate: _duplicatePressed,
    );
    actionsMenuDrawingLinked = getDrawingLayerMenuLinked(
      onDismiss: _closeActionsMenus,
      anchorKey: actionsAnchorKey,
      onDelete: _deletePressed,
      onUnlink: _unlinkPressed,
      onDuplicate: _duplicatePressed,
    );
    actionsMenuReduced = getReducedLayerMenu(
      onDismiss: _closeActionsMenus,
      anchorKey: actionsAnchorKey,
      onDelete: _deletePressed,
      onDuplicate: _duplicatePressed,
    );
    actionsMenuRaster = getRasterLayerMenu(
      onDismiss: _closeActionsMenus,
      anchorKey: actionsAnchorKey,
      onDelete: _deletePressed,
      onDuplicate: _duplicatePressed,
      onRaster: _rasterPressed,
    );
  }

  void _deletePressed()
  {
    _layerManager.layerDeletedSelected(deleteLayer: widget.layerState);
    _closeActionsMenus();
  }

  void _mergeDownPressed()
  {
    _layerManager.layerMerged(mergeLayer: widget.layerState);
    _closeActionsMenus();
  }

  void _duplicatePressed()
  {
    _layerManager.layerDuplicateSelected(duplicateLayer: widget.layerState);
    _closeActionsMenus();
  }

  void _unlinkPressed()
  {
    final LayerState? duplicatedLayer = _layerManager.layerDuplicateSelected(duplicateLayer: widget.layerState, addToHistoryStack: false);
    if (duplicatedLayer != null)
    {
      _layerManager.layerDeletedSelected(deleteLayer: widget.layerState, addToHistoryStack: false);
      _layerManager.selectLayer(newLayer: duplicatedLayer);
      _documentState.timeline.layerChangeNotifier.reportChange();
    }
    _closeActionsMenus();
  }

  void _rasterPressed()
  {
    _layerManager.layerRasterPressed(rasterLayer: widget.layerState);
    _closeActionsMenus();
  }

  void _closeActionsMenus()
  {
    actionsMenuDrawing.hide();
    actionsMenuDrawingLinked.hide();
    actionsMenuReduced.hide();
    actionsMenuRaster.hide();
  }

  void _actionsButtonPressed()
  {
    if (_documentState.timeline.isLayerLinked(layer: widget.layerState))
    {
      actionsMenuDrawingLinked.show(context: context);
      return;
    }
    switch (widget.layerState.menuKind)
    {
      case LayerMenuKind.drawing:   actionsMenuDrawing.show(context: context);
      case LayerMenuKind.raster:    actionsMenuRaster.show(context: context);
      case LayerMenuKind.reference: actionsMenuReduced.show(context: context);
    }
  }

  void _visibilityButtonPressed()
  {
    _layerManager.changeLayerVisibility(layerState: widget.layerState);
  }

  void _lockButtonPressed()
  {
    _layerManager.changeLayerLockState(layerState: widget.layerState);
  }

  void _settingsButtonPressed()
  {
    _layerManager.selectLayer(newLayer: widget.layerState);
    GetIt.I.get<ViewState>().layerSettingsVisible = true;
  }


  @override
  Widget build(final BuildContext context)
  {
    return Padding(
      padding: const EdgeInsets.only(
          left: LayerWidgetOptions.outerPadding, right: LayerWidgetOptions.outerPadding,),
      child: SizedBox(
        height: LayerWidgetOptions.height,
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.layerState.selectedInCurrentFrameNotifier,
          builder: (final BuildContext context, final bool isSelected,final Widget? child,)
          {
            final Widget iconButton = Padding(
              padding: const EdgeInsets.only(right: LayerWidgetOptions.innerPadding),
              child: ClipRect(
                child: Align(
                  widthFactor: 0.5,
                  child: Icon(TablerIcons.grip_vertical, color: Theme.of(context).primaryColor, size: 32),
                ),
              ),
            );
            return Row(
              children: <Widget>[
                Draggable<LayerState>(
                  data: widget.layerState,
                  feedback: Container(
                    width: LayerWidgetOptions.dragFeedbackSize * 3,
                    height: LayerWidgetOptions.dragFeedbackSize,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha((LayerWidgetOptions.dragOpacity * 255.0).toInt()),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(LayerWidgetOptions.borderRadius),
                      ),
                      border: Border.all(
                        color: Theme.of(context).primaryColorDark,
                        width: LayerWidgetOptions.borderWidth,
                      ),
                    ),
                  ),
                  childWhenDragging: iconButton,
                  child: iconButton,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(LayerWidgetOptions.innerPadding),
                    decoration: BoxDecoration(
                      color: _documentState.timeline.isLayerLinked(layer: widget.layerState) ?
                        getColorForLayer(hashCode: widget.layerState.hashCode, context: context, selected: true):
                        Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(LayerWidgetOptions.borderRadius),
                      ),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColorLight
                            : Theme.of(context).primaryColorDark,
                        width: LayerWidgetOptions.borderWidth,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                            right: LayerWidgetOptions.innerPadding,
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
                                              visibility.desc +
                                                  _hotkeyManager.getShortcutString(
                                                      action: HotkeyAction
                                                          .layersSwitchVisibility,),
                                          waitDuration: toolTipDuration,
                                          child: IconButton.outlined(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              maxHeight: LayerWidgetOptions.buttonSizeMax,
                                              maxWidth: LayerWidgetOptions.buttonSizeMax,
                                              minWidth: LayerWidgetOptions.buttonSizeMin,
                                              minHeight: LayerWidgetOptions.buttonSizeMin,
                                            ),
                                            style: ButtonStyle(
                                              shape: const WidgetStatePropertyAll<OutlinedBorder?>(
                                                RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.all(
                                                    Radius.circular(LayerWidgetOptions.borderRadius / 2),
                                                  ),
                                                ),
                                              ),
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
                                            icon: Icon(
                                              visibility.icon,
                                              size: LayerWidgetOptions.iconSize,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );

                              if (widget.layerState is RasterableLayerState) {
                                final ValueNotifier<LayerLockState> layerLockState =
                                         (widget.layerState as RasterableLayerState)
                                            .lockState;
                                leftColumn.children
                                    .add(const SizedBox(height: LayerWidgetOptions.innerPadding));
                                leftColumn.children.add(
                                  Expanded(
                                    child: ValueListenableBuilder<LayerLockState>(
                                      valueListenable: layerLockState,
                                      builder: (final BuildContext context,
                                          final LayerLockState lock,
                                          final Widget? child,) {
                                        return Tooltip(
                                          message: lock.desc +
                                              _hotkeyManager.getShortcutString(
                                                  action: HotkeyAction
                                                      .layersSwitchLock,),
                                          waitDuration: toolTipDuration,
                                          child: IconButton.outlined(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              maxHeight: LayerWidgetOptions.buttonSizeMax,
                                              maxWidth: LayerWidgetOptions.buttonSizeMax,
                                              minWidth: LayerWidgetOptions.buttonSizeMin,
                                              minHeight: LayerWidgetOptions.buttonSizeMin,
                                            ),
                                            style: ButtonStyle(
                                            shape: const WidgetStatePropertyAll<OutlinedBorder?>(
                                              RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(LayerWidgetOptions.borderRadius / 2),
                                                ),
                                              ),
                                            ),
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
                                            icon: Icon(
                                              lock.icon,
                                              size: LayerWidgetOptions.iconSize,
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
                              _layerManager.selectLayer(newLayer: widget.layerState);
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                RepaintBoundary(
                                  child: ValueListenableBuilder<ui.Image?>(
                                    valueListenable: widget.layerState.thumbnail,
                                    builder: (final BuildContext context,
                                        final ui.Image? img, final Widget? child,) {
                                      return RawImage(
                                        image: img,
                                      );
                                    },
                                  ),
                                ),
                                if (!widget.layerState.thumbnailIsContent)
                                  Center(
                                    child: Icon(
                                      widget.layerState.icon,
                                      size: LayerWidgetOptions.height / 2,
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
                          padding: const EdgeInsets.only(
                            left: LayerWidgetOptions.innerPadding,
                          ),
                          child: Builder(
                            builder: (final BuildContext context) {
                              final Column rightColumn = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Expanded(
                                    child: OverlayAnchor(
                                      anchorKey: actionsAnchorKey,
                                      child: Tooltip(
                                        message: "Layer Actions...",
                                        waitDuration: toolTipDuration,
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
                                                  constraints: const BoxConstraints(
                                                    maxHeight: LayerWidgetOptions.buttonSizeMax,
                                                    maxWidth: LayerWidgetOptions.buttonSizeMax,
                                                    minWidth: LayerWidgetOptions.buttonSizeMin,
                                                    minHeight: LayerWidgetOptions.buttonSizeMin,
                                                  ),
                                                  style: const ButtonStyle(
                                                    shape: WidgetStatePropertyAll<OutlinedBorder?>(
                                                      RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.all(
                                                          Radius.circular(LayerWidgetOptions.borderRadius / 2),
                                                        ),
                                                      ),
                                                    ),
                                                    tapTargetSize:
                                                    MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  onPressed: lockState != LayerLockState.locked ? _actionsButtonPressed : null,
                                                  icon: const Icon(
                                                    TablerIcons.menu_2,
                                                    size: LayerWidgetOptions.iconSize,
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
                                    .add(const SizedBox(height: LayerWidgetOptions.innerPadding));

                                rightColumn.children.add(
                                  Expanded(
                                    child: Tooltip(
                                      message: "Settings",
                                      waitDuration: toolTipDuration,
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
                                                    constraints: const BoxConstraints(
                                                      maxHeight: LayerWidgetOptions.buttonSizeMax,
                                                      maxWidth: LayerWidgetOptions.buttonSizeMax,
                                                      minWidth: LayerWidgetOptions.buttonSizeMin,
                                                      minHeight: LayerWidgetOptions.buttonSizeMin,
                                                    ),
                                                    style: ButtonStyle(
                                                      shape: const WidgetStatePropertyAll<OutlinedBorder?>(
                                                        RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.all(
                                                            Radius.circular(LayerWidgetOptions.borderRadius / 2),
                                                          ),
                                                        ),
                                                      ),
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
                                                    icon: const Icon(
                                                      TablerIcons.settings,
                                                      size: LayerWidgetOptions.iconSize,
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
