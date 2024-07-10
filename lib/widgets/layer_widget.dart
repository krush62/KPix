import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/preference_manager.dart';
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
  final HashMap<CoordinateSetI, ColorReference> _data;
  ui.Image? raster;
  bool isRasterizing = false;
  bool doManualRaster = false;
  Queue<(CoordinateSetI, ColorReference?)> rasterQueue = Queue();

  LayerState._({required HashMap<CoordinateSetI, ColorReference> data2, required this.size, LayerLockState lState = LayerLockState.unlocked, LayerVisibilityState vState = LayerVisibilityState.visible}) : _data = data2
  {
    _createRaster().then((final ui.Image image) => _rasterizingDone(image));
    lockState.value = lState;
    visibilityState.value = vState;
    LayerWidgetOptions options = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
    Timer.periodic(Duration(seconds: options.thumbUpdateTimerSec, milliseconds: options.thumbUpdateTimerMsec), updateTimerCallback);

  }

  factory LayerState.from({required LayerState other})
  {
    HashMap<CoordinateSetI, ColorReference> data2 = HashMap();
  for (final MapEntry<CoordinateSetI, ColorReference> ref in other._data.entries)
    {
      data2[ref.key] = ref.value;
    }
    return LayerState._(size: other.size, data2: data2, lState: other.lockState.value, vState: other.visibilityState.value);
  }


  factory LayerState({required int width, required int height, final HashMap<CoordinateSetI, ColorReference?>? content})
  {
    HashMap<CoordinateSetI, ColorReference> data2 = HashMap();
    final CoordinateSetI size = CoordinateSetI(x: width, y: height);

    if (content != null)
    {
      for (final MapEntry<CoordinateSetI, ColorReference?> entry in content.entries)
      {
        if (entry.key.x > 0 && entry.key.y > 0 && entry.key.x < width && entry.key.y < height && entry.value != null)
        {
          data2[entry.key] = entry.value!;
        }
      }
    }
    return LayerState._(data2: data2, size: size);
  }

  void updateTimerCallback(final Timer timer) async
  {
    if ((rasterQueue.isNotEmpty || doManualRaster) && !isRasterizing)
    {
      isRasterizing = true;
      _createRaster().then((final ui.Image image) => _rasterizingDone(image));

    }
  }

  void deleteRamp({required final KPalRampData ramp})
  {
    isRasterizing = true;
    final Set<CoordinateSetI> deleteData = {};
    for (final MapEntry<CoordinateSetI, ColorReference> entry in _data.entries)
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

  void remapColors({required final KPalRampData newData, required final HashMap<int, int> map})
  {
    isRasterizing = true;
    for (final MapEntry<CoordinateSetI, ColorReference> entry in _data.entries)
    {
      if (entry.value.ramp == newData)
      {
        _data[entry.key] = newData.references[map[entry.value.colorIndex]!];
      }
    }
    isRasterizing = false;
  }


  void _rasterizingDone(final ui.Image image)
  {
    isRasterizing = false;
    raster = image;
    thumbnail.value = raster;
    doManualRaster = false;
    GetIt.I.get<AppState>().repaintNotifier.repaint();
  }

  //TODO thumbnail is rasterized without selection data
  Future<ui.Image> _createRaster() async
  {
    while(rasterQueue.isNotEmpty)
    {
      final (CoordinateSetI, ColorReference?) entry = rasterQueue.removeFirst();
      if (entry.$2 == null)
      {
        _data.remove(entry.$1);
      }
      else
      {
        _data[entry.$1] = entry.$2!;
      }
    }

    final ByteData byteData = ByteData(size.x * size.y * 4);
    for (final MapEntry<CoordinateSetI, ColorReference?> entry in _data.entries)
    {
      if (entry.value != null) {
        final Color dColor = entry.value!.ramp.colors[entry.value!.colorIndex]
            .value.color;
        byteData.setUint32((entry.key.y * size.x + entry.key.x) * 4,
            Helper.argbToRgba(dColor.value));
      }

    }
    final Completer<ui.Image> c = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      byteData.buffer.asUint8List(),
      size.x,
      size.y,
      ui.PixelFormat.rgba8888, (ui.Image convertedImage)
      {
        c.complete(convertedImage);
      }
    );
    return c.future;
  }


  ColorReference? getDataEntry(final CoordinateSetI coord)
  {
    if (_data.containsKey(coord))
    {
      return _data[coord];
    }
    else if (rasterQueue.isNotEmpty)
    {
      for (final (CoordinateSetI, ColorReference?) entry in rasterQueue)
      {
        if (entry.$1 == coord)
        {
          return entry.$2;
        }
      }
    }
    return null;
  }

  HashMap<CoordinateSetI, ColorReference> getData()
  {
    return _data;
  }

  void setDataAll(final HashMap<CoordinateSetI, ColorReference?> list)
  {
    final Set<(CoordinateSetI, ColorReference?)> it = {};
    for (final MapEntry<CoordinateSetI, ColorReference?> entry in list.entries)
    {
      bool foundInRaster = false;
      for (int i = 0; i < rasterQueue.length; i++)
      {
        final (CoordinateSetI, ColorReference?) rasterEntry = rasterQueue.elementAt(i);
        if (rasterEntry.$1 == entry.key && rasterEntry.$2 != entry.value)
        {
          rasterQueue.remove(rasterEntry);
          it.add((entry.key, entry.value));
          foundInRaster = true;
          break;
        }
      }

      if (entry.value != _data[entry.key] && !foundInRaster)
      {
        it.add((entry.key, entry.value));
      }
    }
    if (it.isNotEmpty)
    {
      rasterQueue.addAll(it);
    }


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
  AppState appState = GetIt.I.get<AppState>();
  LayerWidgetOptions options = GetIt.I.get<PreferenceManager>().layerWidgetOptions;

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
  late OverlayEntry settingsMenu;
  bool settingsMenuVisible = false;

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
    appState.layerDeleted(widget.layerState);
    _closeSettingsMenu();
  }

  void _mergeDownPressed()
  {
    appState.layerMerged(widget.layerState);
    _closeSettingsMenu();
  }

  void _duplicatePressed()
  {
    appState.layerDuplicated(widget.layerState);
    _closeSettingsMenu();
  }

  void _closeSettingsMenu()
  {
    if (settingsMenuVisible)
    {
      settingsMenu.remove();
      settingsMenuVisible = false;
    }
  }

  void _settingsButtonPressed()
  {
    if (!settingsMenuVisible)
    {
      Overlay.of(context).insert(settingsMenu);
      settingsMenuVisible = true;
    }
  }


  void _visibilityButtonPressed()
  {
    setState(() {
      if (widget.layerState.visibilityState.value == LayerVisibilityState.visible)
      {
        widget.layerState.visibilityState.value = LayerVisibilityState.hidden;
      }
      else if (widget.layerState.visibilityState.value == LayerVisibilityState.hidden)
      {
        widget.layerState.visibilityState.value = LayerVisibilityState.visible;
      }
    });
  }

  void _lockButtonPressed()
  {
    setState(() {
      if (widget.layerState.lockState.value == LayerLockState.unlocked)
      {
        widget.layerState.lockState.value = LayerLockState.transparency;
      }
      else if (widget.layerState.lockState.value == LayerLockState.transparency)
      {
        widget.layerState.lockState.value = LayerLockState.locked;
      }
      else if (widget.layerState.lockState.value == LayerLockState.locked)
      {
        widget.layerState.lockState.value = LayerLockState.unlocked;
      }

    });
  }



  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<LayerState>(
      delay: Duration(milliseconds: options.dragDelay),
      data: widget.layerState,
      feedback: Container(
        width: options.dragFeedbackSize,
        height: options.dragFeedbackSize,
        color: Theme.of(context).primaryColor.withOpacity(options.dragOpacity),
      ),
      //childWhenDragging: const SizedBox.shrink(),
      childWhenDragging: Container(
        height: options.dragTargetHeight,
        color: Theme.of(context).primaryColor,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: options.outerPadding, right: options.outerPadding),
        child: SizedBox(
          height: options.height,
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.layerState.isSelected,
            builder: (BuildContext context, bool isSelected, child) {
            return Container(
                padding: EdgeInsets.all(options.innerPadding),

                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.all(
                        Radius.circular(options.borderRadius),
                    ),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColorDark,
                      width: options.borderWidth,
                    )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          right: options.innerPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ValueListenableBuilder<LayerVisibilityState>(
                                valueListenable: widget.layerState
                                    .visibilityState,
                                builder: (BuildContext context,
                                    LayerVisibilityState visibility, child) {
                                  return IconButton.outlined(
                                      tooltip: _visibilityTooltipMap[visibility],
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(
                                        maxHeight: options.buttonSizeMax,
                                        maxWidth: options.buttonSizeMax,
                                        minWidth: options.buttonSizeMin,
                                        minHeight: options.buttonSizeMin,
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
                                        size: options.iconSize,
                                      )
                                  );
                                }
                            ),
                          ),
                          SizedBox(height: options.innerPadding),
                          Expanded(
                            child: ValueListenableBuilder<LayerLockState>(
                              valueListenable: widget.layerState.lockState,
                              builder: (BuildContext context,
                                LayerLockState lock, child) {
                                return IconButton.outlined(
                                  tooltip: _lockStringMap[lock],
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                    maxHeight: options.buttonSizeMax,
                                    maxWidth: options.buttonSizeMax,
                                    minWidth: options.buttonSizeMin,
                                    minHeight: options.buttonSizeMin,
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
                                    size: options.iconSize,
                                  )
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
                            appState.layerSelected(widget.layerState);
                          },
                          child: ValueListenableBuilder<ui.Image?>(
                            valueListenable: widget.layerState.thumbnail,
                            builder: (BuildContext context, ui.Image? img, child)
                            {
                              return RawImage(image: img,);
                            },
                          ),
                        )),
                    Padding(
                      padding: EdgeInsets.only(
                          left: options.innerPadding),
                      child: CompositedTransformTarget(
                        link: settingsLink,
                        child: IconButton.outlined(
                            tooltip: "Settings",
                            constraints: BoxConstraints(
                              maxHeight: options.buttonSizeMax,
                              maxWidth: options.buttonSizeMax,
                              minWidth: options.buttonSizeMin,
                              minHeight: options.buttonSizeMin,
                            ),
                            style: const ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _settingsButtonPressed,
                            icon: FaIcon(
                              FontAwesomeIcons.bars,
                              size: options.iconSize,
                            )
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