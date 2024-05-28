import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models.dart';
import 'package:kpix/typedefs.dart';
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
  //TODO TEMP
  final ValueNotifier<Color> color;

  //TODO TEMP
  final AppState appState;

  final List<List<ColorReference?>> data;

  LayerState._({required this.data, required this.color, required this.appState});


  factory LayerState({required int width, required int height, required Color color, required AppState appState})
  {
    List<List<ColorReference?>> data = List.generate(height + 1, (i) => List.filled(width + 1, null, growable: false), growable: false);
    
    //TODO TEMP
    for (int i = 0; i < 200; i++)
    {
      KPalRampData ramp = appState.colorRamps.value[Random().nextInt(appState.colorRamps.value.length)];
      data[Random().nextInt(width)][Random().nextInt(height)] = ColorReference(colorIndex: Random().nextInt(ramp.colors.length), ramp: ramp);
    }
    
    ValueNotifier<Color> vnColor = ValueNotifier(color);
    return LayerState._(data: data, color: vnColor, appState: appState);
  }

}



class LayerWidget extends StatefulWidget
{
  final LayerState layerState;
  final LayerWidgetOptions options;
  final LayerSelectedFn layerSelectedFn;
  final LayerDeleteFn layerDeleteFn;
  final LayerMergeDownFn layerMergeDownFn;
  final LayerDuplicateFn layerDuplicateFn;

  final OverlayEntrySubMenuOptions menuOptions;
  const LayerWidget({
    super.key,
    required this.layerState,
    required this.options,
    required this.layerSelectedFn,
    required this.menuOptions,
    required this.layerDuplicateFn,
    required this.layerMergeDownFn,
    required this.layerDeleteFn});

  @override
  State<LayerWidget> createState() => _LayerWidgetState();

}

class _LayerWidgetState extends State<LayerWidget>
{
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
      options: widget.menuOptions,
      onDelete: _deletePressed,
      onMergeDown: _mergeDownPressed,
      onDuplicate: _duplicatePressed,
    );
  }

  void _deletePressed()
  {
    widget.layerDeleteFn(widget.layerState);
    _closeSettingsMenu();
  }

  void _mergeDownPressed()
  {
    widget.layerMergeDownFn(widget.layerState);
    _closeSettingsMenu();
  }

  void _duplicatePressed()
  {
    widget.layerDuplicateFn(widget.layerState);
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
      delay: Duration(milliseconds: widget.options.dragDelay),
      data: widget.layerState,
      feedback: Container(
        width: widget.options.dragFeedbackSize,
        height: widget.options.dragFeedbackSize,
        color: Theme.of(context).primaryColor.withOpacity(widget.options.dragOpacity),
      ),
      //childWhenDragging: const SizedBox.shrink(),
      childWhenDragging: Container(
        height: widget.options.dragTargetHeight,
        color: Theme.of(context).primaryColor,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: widget.options.outerPadding, right: widget.options.outerPadding),
        child: SizedBox(
          height: widget.options.height,
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.layerState.isSelected,
            builder: (BuildContext context, bool isSelected, child) {
            return Container(
                padding: EdgeInsets.all(widget.options.innerPadding),

                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.all(
                        Radius.circular(widget.options.borderRadius),
                    ),
                    border: isSelected ? Border.all(
                      color: Theme.of(context).primaryColorLight,
                      width: widget.options.borderWidth,
                    ) : null
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          right: widget.options.innerPadding),
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
                                        maxHeight: widget.options.buttonSizeMax,
                                        maxWidth: widget.options.buttonSizeMax,
                                        minWidth: widget.options.buttonSizeMin,
                                        minHeight: widget.options.buttonSizeMin,
                                      ),
                                      style: const ButtonStyle(
                                        tapTargetSize: MaterialTapTargetSize
                                            .shrinkWrap,
                                      ),
                                      onPressed: _visibilityButtonPressed,
                                      icon: FaIcon(
                                        _visibilityIconMap[visibility],
                                        size: widget.options.iconSize,
                                      )
                                  );
                                }
                            ),
                          ),
                          SizedBox(height: widget.options.innerPadding),
                          Expanded(
                            child: ValueListenableBuilder<LayerLockState>(
                                valueListenable: widget.layerState.lockState,
                                builder: (BuildContext context,
                                    LayerLockState lock, child) {
                                  return IconButton.outlined(
                                      tooltip: _lockStringMap[lock],
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(
                                        maxHeight: widget.options.buttonSizeMax,
                                        maxWidth: widget.options.buttonSizeMax,
                                        minWidth: widget.options.buttonSizeMin,
                                        minHeight: widget.options.buttonSizeMin,
                                      ),
                                      style: const ButtonStyle(
                                        tapTargetSize: MaterialTapTargetSize
                                            .shrinkWrap,
                                      ),
                                      onPressed: _lockButtonPressed,
                                      icon: FaIcon(
                                        _lockIconMap[lock],
                                        size: widget.options.iconSize,
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
                          onTap: () {widget.layerSelectedFn(widget.layerState);},
                          child: ValueListenableBuilder<Color>(
                            valueListenable: widget.layerState.color,
                            builder: (BuildContext context, Color color, child)
                            {
                              return ColoredBox(color: color);
                            },
                          ),
                        )),
                    Padding(
                      padding: EdgeInsets.only(
                          left: widget.options.innerPadding),
                      child: CompositedTransformTarget(
                        link: settingsLink,
                        child: IconButton.outlined(
                            tooltip: "Settings",
                            constraints: BoxConstraints(
                              maxHeight: widget.options.buttonSizeMax,
                              maxWidth: widget.options.buttonSizeMax,
                              minWidth: widget.options.buttonSizeMin,
                              minHeight: widget.options.buttonSizeMin,
                            ),
                            style: const ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _settingsButtonPressed,
                            icon: FaIcon(
                              FontAwesomeIcons.bars,
                              size: widget.options.iconSize,
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