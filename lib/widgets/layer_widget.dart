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

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas_operations_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';


class LayerWidgetOptions
{
  final double outerPadding;
  final double innerPadding;
  final double borderRadius;
  final double buttonSizeMin;
  final double buttonSizeMax;
  final double iconSize;
  final double height;
  final double dragOpacity;
  final double borderWidth;
  final double dragFeedbackSize;
  final double dragTargetHeight;
  final int dragTargetShowDuration;
  final int dragDelay;
  final int thumbUpdateTimerSec;
  final int thumbUpdateTimerMsec;

  LayerWidgetOptions({
    required this.outerPadding,
    required this.innerPadding,
    required this.borderRadius,
    required this.buttonSizeMin,
    required this.buttonSizeMax,
    required this.iconSize,
    required this.height,
    required this.dragOpacity,
    required this.borderWidth,
    required this.dragFeedbackSize,
    required this.dragTargetHeight,
    required this.dragTargetShowDuration,
    required this.dragDelay,
    required this.thumbUpdateTimerSec,
    required this.thumbUpdateTimerMsec});
}

enum LayerVisibilityState
{
  visible,
  hidden
}

const Map<int, LayerVisibilityState> layerVisibilityStateValueMap =
{
  0: LayerVisibilityState.visible,
  1: LayerVisibilityState.hidden,
};

enum LayerLockState
{
  unlocked,
  transparency,
  locked
}

const Map<int, LayerLockState> layerLockStateValueMap =
{
  0: LayerLockState.unlocked,
  1: LayerLockState.transparency,
  2: LayerLockState.locked
};

class ColorReference
{
  final KPalRampData ramp;
  final int colorIndex;
  ColorReference({required this.colorIndex, required this.ramp});
  IdColor getIdColor()
  {
    return ramp.colors[colorIndex].value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorReference &&
          runtimeType == other.runtimeType &&
          ramp == other.ramp &&
          colorIndex == other.colorIndex;

  @override
  int get hashCode => ramp.hashCode ^ colorIndex.hashCode;
}

class LayerState
{
  final ValueNotifier<LayerVisibilityState> visibilityState = ValueNotifier(LayerVisibilityState.visible);
  final ValueNotifier<LayerLockState> lockState = ValueNotifier(LayerLockState.unlocked);
  final ValueNotifier<bool> isSelected = ValueNotifier(false);
  final ValueNotifier<ui.Image?> thumbnail = ValueNotifier(null);
  final CoordinateSetI size;
  final CoordinateColorMap _data;
  ui.Image? raster;
  bool isRasterizing = false;
  bool doManualRaster = false;
  final Map<CoordinateSetI, ColorReference?> rasterQueue = {};


  LayerState._({required CoordinateColorMap data2, required this.size, LayerLockState lState = LayerLockState.unlocked, LayerVisibilityState vState = LayerVisibilityState.visible}) : _data = data2
  {
    _createRaster().then((final (ui.Image, ui.Image) images) => _rasterizingDone(image: images.$1, thb: images.$2));
    lockState.value = lState;
    visibilityState.value = vState;
    LayerWidgetOptions options = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
    Timer.periodic(Duration(seconds: options.thumbUpdateTimerSec, milliseconds: options.thumbUpdateTimerMsec), (final Timer t) {updateTimerCallback(timer: t);});

  }

  factory LayerState.from({required LayerState other})
  {
    CoordinateColorMap data2 = HashMap();
  for (final CoordinateColor ref in other._data.entries)
    {
      data2[ref.key] = ref.value;
    }
    return LayerState._(size: other.size, data2: data2, lState: other.lockState.value, vState: other.visibilityState.value);
  }


  factory LayerState({required CoordinateSetI size, final CoordinateColorMapNullable? content})
  {
    CoordinateColorMap data2 = HashMap();

    if (content != null)
    {
      for (final CoordinateColorNullable entry in content.entries)
      {
        if (entry.key.x >= 0 && entry.key.y >= 0 && entry.key.x < size.x && entry.key.y < size.y && entry.value != null)
        {
          data2[entry.key] = entry.value!;
        }
      }
    }
    return LayerState._(data2: data2, size: size);
  }

  void updateTimerCallback({required final Timer timer}) async
  {
    if ((rasterQueue.isNotEmpty || doManualRaster) && !isRasterizing)
    {
      isRasterizing = true;
      _createRaster().then((final (ui.Image, ui.Image) images) => _rasterizingDone(image: images.$1, thb: images.$2));
    }
  }

  void deleteRamp({required final KPalRampData ramp})
  {
    isRasterizing = true;
    final Set<CoordinateSetI> deleteData = {};
    for (final CoordinateColor entry in _data.entries)
    {
      if (entry.value.ramp == ramp)
      {
        deleteData.add(entry.key);
      }
    }

    for (final CoordinateSetI coord in deleteData)
    {
      _data.remove(coord);
    }

    isRasterizing = false;
  }

  void remapAllColors({required final HashMap<ColorReference, ColorReference> rampMap})
  {
    isRasterizing = true;
    for (final CoordinateColor entry in _data.entries)
    {
      _data[entry.key] = rampMap[entry.value]!;
    }
    isRasterizing = false;
  }

  void remapSingleRamp({required final KPalRampData newData, required final HashMap<int, int> map})
  {
    isRasterizing = true;
    for (final CoordinateColor entry in _data.entries)
    {
      if (entry.value.ramp == newData)
      {
        _data[entry.key] = newData.references[map[entry.value.colorIndex]!];
      }
    }
    isRasterizing = false;
  }


  void _rasterizingDone({required final ui.Image image, required final ui.Image thb})
  {
    isRasterizing = false;
    raster = image;
    thumbnail.value = thb;
    doManualRaster = false;
    GetIt.I.get<AppState>().repaintNotifier.repaint();
  }

  Future<(ui.Image, ui.Image)> _createRaster() async
  {
    final AppState appState = GetIt.I.get<AppState>();
    bool differentThumb = false;
    if (appState.currentLayer == this && appState.selectionState.selection.hasValues())
    {
      differentThumb = true;
    }

    for (final CoordinateColorNullable entry in rasterQueue.entries)
    {
      if (entry.value == null)
      {
        _data.remove(entry.key);
      }
      else
      {
        _data[entry.key] = entry.value!;
      }
    }
    rasterQueue.clear();

    final ByteData byteDataImg = ByteData(size.x * size.y * 4);
    ByteData? byteDataThumb;
    if (differentThumb)
    {
      byteDataThumb = ByteData(size.x * size.y * 4);
    }
    for (final CoordinateColorNullable entry in _data.entries)
    {
      if (entry.value != null)
      {
        final Color dColor = entry.value!.getIdColor().color;
        final int index = (entry.key.y * size.x + entry.key.x) * 4;
        if (index < byteDataImg.lengthInBytes)
        {
          byteDataImg.setUint32(index, Helper.argbToRgba(argb: dColor.value));
          if (byteDataThumb != null)
          {
            byteDataThumb.setUint32(index, Helper.argbToRgba(argb: dColor.value));
          }
        }
      }
    }
    if (differentThumb)
    {
      final Iterable<CoordinateSetI> selectionCoords = appState.selectionState.selection.getCoordinates();
      for (final CoordinateSetI coord in selectionCoords)
      {
        final ColorReference? colRef = appState.selectionState.selection.getColorReference(coord: coord);
        if (colRef != null)
        {
          final Color dColor = colRef.getIdColor().color;
          final int index = (coord.y * size.x + coord.x) * 4;
          if (index > 0 && index < byteDataThumb!.lengthInBytes)
          {
            byteDataThumb.setUint32(index, Helper.argbToRgba(argb: dColor.value));
          }
        }
      }
    }


    final Completer<ui.Image> completerImg = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      byteDataImg.buffer.asUint8List(),
      size.x,
      size.y,
      ui.PixelFormat.rgba8888, (ui.Image convertedImage)
      {
        completerImg.complete(convertedImage);
      }
    );

    final ui.Image img = await completerImg.future;

    if (differentThumb)
    {
      final Completer<ui.Image> completerThumb = Completer<ui.Image>();
      ui.decodeImageFromPixels(
          byteDataThumb!.buffer.asUint8List(),
          size.x,
          size.y,
          ui.PixelFormat.rgba8888, (ui.Image convertedImage)
      {
        completerThumb.complete(convertedImage);
      }
      );
      final ui.Image thumb = await completerThumb.future;
      return (img, thumb);
    }
    else
    {
      return (img, img);
    }
  }


  ColorReference? getDataEntry({required final CoordinateSetI coord})
  {
    if (_data.containsKey(coord))
    {
      return _data[coord];
    }
    else if (rasterQueue.isNotEmpty)
    {
      return rasterQueue[coord];
    }
    return null;
  }

  CoordinateColorMap getData()
  {
    return _data;
  }

  void setDataAll({required final CoordinateColorMapNullable list})
  {
    rasterQueue.addAll(list);
  }

  Future <void> removeDataAll({required final Set<CoordinateSetI> removeCoordList}) async
  {
    for (final CoordinateSetI coord in removeCoordList)
    {
     rasterQueue[coord] = null;
    }
  }


  LayerState getTransformedLayer({required final CanvasTransformation transformation})
  {
    final CoordinateColorMap rotatedContent = HashMap();
    final CoordinateSetI newSize = CoordinateSetI.from(other: size);
    if (transformation == CanvasTransformation.rotate)
    {
      newSize.x = size.y;
      newSize.y = size.x;
    }
    for (final CoordinateColor entry in _data.entries)
    {
      final CoordinateSetI rotCoord = CoordinateSetI.from(other: entry.key);
      if (transformation == CanvasTransformation.rotate)
      {
        rotCoord.x = ((size.y - 1) - entry.key.y).toInt();
        rotCoord.y = entry.key.x;
      }
      else if (transformation == CanvasTransformation.flipH)
      {
        rotCoord.x = ((size.x - 1) - entry.key.x).toInt();
      }
      else if (transformation == CanvasTransformation.flipV)
      {
        rotCoord.y = ((size.y - 1) - entry.key.y).toInt();
      }

      rotatedContent[rotCoord] = entry.value;
    }
    if (rasterQueue.isNotEmpty)
    {
      for (final CoordinateColorNullable entry in rasterQueue.entries)
      {
        final CoordinateSetI rotCoord = CoordinateSetI.from(other: entry.key);
        if (transformation == CanvasTransformation.rotate)
        {
          rotCoord.x = ((size.y - 1) - entry.key.y).toInt();
          rotCoord.y = entry.key.x;
        }
        else if (transformation == CanvasTransformation.flipH)
        {
          rotCoord.x = ((size.x - 1) - entry.key.x).toInt();
        }
        else if (transformation == CanvasTransformation.flipV)
        {
          rotCoord.y = ((size.y - 1) - entry.key.y).toInt();
        }
        if (entry.value != null)
        {
          rotatedContent[rotCoord] = entry.value!;
        }
        else if (rotatedContent.containsKey(rotCoord))
        {
          rotatedContent.remove(rotCoord);
        }
      }
    }
    return LayerState(size: newSize, content: rotatedContent);
  }

  LayerState getResizedLayer({required final CoordinateSetI newSize, required final CoordinateSetI offset})
  {
    final CoordinateColorMap croppedContent = HashMap();
    for (final CoordinateColor entry in _data.entries)
    {
      final CoordinateSetI newCoord = CoordinateSetI(x: entry.key.x + offset.x, y: entry.key.y + offset.y);
      if (newCoord.x >= 0 && newCoord.x < newSize.x && newCoord.y >= 0 && newCoord.y < newSize.y)
      {
        croppedContent[newCoord] = entry.value;
      }
    }

    if (rasterQueue.isNotEmpty)
    {
      for (final CoordinateColorNullable entry in rasterQueue.entries)
      {
        final CoordinateSetI newCoord = CoordinateSetI(x: entry.key.x + offset.x, y: entry.key.y + offset.y);
        if (newCoord.x >= 0 && newCoord.x < newSize.x && newCoord.y >= 0 && newCoord.y < newSize.y)
        {
          if (entry.value != null)
          {
            croppedContent[newCoord] = entry.value!;
          }
          else if (croppedContent.containsKey(newCoord))
          {
            croppedContent.remove(newCoord);
          }
        }
      }
    }
    return LayerState(size: newSize, content: croppedContent);
  }
}


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
  late KPixOverlay settingsMenu;

  @override
  void initState() {
    super.initState();
    settingsMenu = OverlayEntries.getLayerMenu(
      onDismiss: _closeSettingsMenu,
      layerLink: settingsLink,
      onDelete: _deletePressed,
      onMergeDown: _mergeDownPressed,
      onDuplicate: _duplicatePressed,
    );
  }

  void _deletePressed()
  {
    _appState.layerDeleted(deleteLayer: widget.layerState);
    _closeSettingsMenu();
  }

  void _mergeDownPressed()
  {
    _appState.layerMerged(mergeLayer: widget.layerState);
    _closeSettingsMenu();
  }

  void _duplicatePressed()
  {
    _appState.layerDuplicated(duplicateLayer: widget.layerState);
    _closeSettingsMenu();
  }

  void _closeSettingsMenu()
  {
    settingsMenu.hide();
  }

  void _settingsButtonPressed()
  {
    settingsMenu.show(context: context);
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
                        Expanded(
                          child: ValueListenableBuilder<LayerLockState>(
                            valueListenable: widget.layerState.lockState,
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
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _appState.layerSelected(newLayer: widget.layerState);
                      },
                      child: ValueListenableBuilder<ui.Image?>(
                        valueListenable: widget.layerState.thumbnail,
                        builder: (final BuildContext context, final ui.Image? img, final Widget? child)
                        {
                          return RawImage(image: img,);
                        },
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