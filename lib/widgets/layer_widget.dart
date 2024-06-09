import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
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
    required this.dragDelay});
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
}

class LayerState
{
  final ValueNotifier<LayerVisibilityState> visibilityState = ValueNotifier(LayerVisibilityState.visible);
  final ValueNotifier<LayerLockState> lockState = ValueNotifier(LayerLockState.unlocked);
  final ValueNotifier<bool> isSelected = ValueNotifier(false);
  final ValueNotifier<ui.Image?> thumbnail = ValueNotifier(null);
  final CoordinateSetI size;


  final List<List<ColorReference?>> data;

  LayerState._({required this.data, required this.size})
  {
    createThumbnail();
  }


  factory LayerState({required int width, required int height, final HashMap<CoordinateSetI, ColorReference?>? content})
  {
    List<List<ColorReference?>> data = List.generate(width + 1, (i) => List.filled(height + 1, null, growable: false), growable: false);
    final CoordinateSetI size = CoordinateSetI(x: width, y: height);

    if (content != null)
    {
      for (final MapEntry<CoordinateSetI, ColorReference?> entry in content.entries)
      {
        if (entry.key.x > 0 && entry.key.y > 0 && entry.key.x < width && entry.key.y < height)
        {
          data[entry.key.x][entry.key.y] = entry.value;
        }
      }
    }
    else
    {
      //TODO TEMP
      AppState appState = GetIt.I.get<AppState>();
      for (int i = 0; i < 10000; i++)
      {
        KPalRampData ramp = appState.colorRamps.value[Random().nextInt(appState.colorRamps.value.length)];
        data[Random().nextInt(width)][Random().nextInt(height)] = ColorReference(colorIndex: Random().nextInt(ramp.colors.length), ramp: ramp);
      }

    }


    return LayerState._(data: data, size: size);
  }

  Future<void> createThumbnail({SelectionList? selection}) async
  {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas c = Canvas(recorder);
    final Paint paint = Paint();
    paint.style = PaintingStyle.fill;
    for (int x = 0; x < size.x; x++)
    {
       for (int y = 0; y < size.y; y++)
       {
         ColorReference? col = data[x][y];
         final CoordinateSetI curCor = CoordinateSetI(x: x, y: y);
         if (selection != null && selection.currentLayer == this && selection.contains(curCor) && selection.getColorReference(curCor) != null)
         {
           ColorReference selCol = selection.getColorReference(curCor)!;
           paint.color = selCol.ramp.colors[selCol.colorIndex].value.color;
           c.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
         }
         else if (col != null)
         {
           paint.color = col.ramp.colors[col.colorIndex].value.color;
           c.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
         }
       }
    }
    ui.Picture p = recorder.endRecording();
    thumbnail.value = p.toImageSync(size.x, size.y);
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
                                      style: const ButtonStyle(
                                        tapTargetSize: MaterialTapTargetSize
                                            .shrinkWrap,
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
                                      style: const ButtonStyle(
                                        tapTargetSize: MaterialTapTargetSize
                                            .shrinkWrap,
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