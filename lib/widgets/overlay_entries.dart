import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/color_chooser_widget.dart';
import 'package:kpix/widgets/layer_widget.dart';

class OverlayEntrySubMenuOptions
{
  final double offsetX;
  final double offsetXLeft;
  final double offsetY;
  final double buttonSpacing;
  final double width;
  final double buttonHeight;
  final int smokeOpacity;

  OverlayEntrySubMenuOptions({
    required this.offsetX,
    required this.offsetXLeft,
    required this.offsetY,
    required this.buttonSpacing,
    required this.width,
    required this.buttonHeight,
    required this.smokeOpacity
  });
}

class OverlayEntryAlertDialogOptions
{
  final int smokeOpacity;
  final double minWidth;
  final double minHeight;
  final double maxWidth;
  final double maxHeight;
  final double padding;
  final double borderWidth;
  final double borderRadius;
  final double iconSize;
  final double elevation;

  OverlayEntryAlertDialogOptions({
    required this.smokeOpacity,
    required this.minWidth,
    required this.minHeight,
    required this.maxWidth,
    required this.maxHeight,
    required this.padding,
    required this.borderWidth,
    required this.borderRadius,
    required this.iconSize,
    required this.elevation,
  });
}


class OverlayEntries
{
  static OverlayEntry getLoadMenu({
    required final Function onDismiss,
    required Function onLoadFile,
    required Function onLoadPalette,
    required final LayerLink layerLink,

  })
  {
    final OverlayEntrySubMenuOptions options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            onDismiss: () {onDismiss();},
          ),
          Positioned(
            width: options.width,
            child: CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              offset: Offset(
                options.offsetX,
                options.offsetY,
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(options.buttonSpacing / 2),
                      child: SizedBox(
                        height: options.buttonHeight,
                        child: ElevatedButton(
                          onPressed: () {
                            onLoadFile();
                            },
                          child: const Text("Load Project")
                        )
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(options.buttonSpacing / 2),
                      child: SizedBox(
                        height: options.buttonHeight,
                        child: ElevatedButton(
                          onPressed: () {
                            onLoadPalette();
                          },
                            child: const Text("Load Palette")
                        )
                      ),
                    ),
                  ],
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  static OverlayEntry getSaveMenu({
    required final Function onDismiss,
    required Function onSaveFile,
    required Function onSavePalette,
    required final LayerLink layerLink,
  })
  {
    final OverlayEntrySubMenuOptions options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            onDismiss: () {onDismiss();},
          ),
          Positioned(
            width: options.width,
            child: CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              offset: Offset(
                options.offsetX,
                options.offsetY,
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(options.buttonSpacing / 2),
                      child: SizedBox(
                        height: options.buttonHeight,
                        child: ElevatedButton(
                            onPressed: () {
                              onSaveFile();
                            },
                            child: const Text("Save Project")
                        )
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(options.buttonSpacing / 2),
                      child: SizedBox(
                        height: options.buttonHeight,
                        child: ElevatedButton(
                            onPressed: () {
                              onSavePalette();
                            },
                            child: const Text("Save Palette")
                        )
                      ),
                    ),
                  ],
                )
              ),
            ),
          ),
        ],
      ),
    );
  }


  static OverlayEntry getLayerMenu({
    required final Function onDismiss,
    required Function onDelete,
    required Function onMergeDown,
    required Function onDuplicate,
    required final LayerLink layerLink,
  })
  {
    OverlayEntrySubMenuOptions options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
    LayerWidgetOptions layerWidgetOptions = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
    const int buttonCount = 3;
    final double width = (options.buttonHeight + (options.buttonSpacing * 2)) * buttonCount;
    final double height = options.buttonHeight + 2 * options.buttonSpacing;
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            onDismiss: () {onDismiss();},
          ),
          Positioned(
            width: width,
            height: height,
            child: CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              offset: Offset(
                -width,
                layerWidgetOptions.height/2 - height/2 - layerWidgetOptions.innerPadding,
              ),
              child: Material(
                color: Colors.transparent,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton.outlined(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(
                            options.buttonSpacing),
                        onPressed: () {onDelete();},
                        icon: FaIcon(
                          FontAwesomeIcons.trashCan,
                          size: options.buttonHeight),
                        color: Theme.of(context).primaryColorLight,
                        style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: Theme.of(context).primaryColor),
                          ),
                    IconButton.outlined(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(options.buttonSpacing),
                        onPressed: () {onDuplicate();},
                        icon: FaIcon(
                          FontAwesomeIcons.clone,
                          size: options.buttonHeight,),
                        color: Theme.of(context).primaryColorLight,
                        style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Theme.of(context).primaryColor)),
                    IconButton.outlined(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(options.buttonSpacing),
                        onPressed: () {onMergeDown();},
                        icon: FaIcon(
                          FontAwesomeIcons.turnDown,
                          size: options.buttonHeight,),
                        color: Theme.of(context).primaryColorLight,
                        style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Theme.of(context).primaryColor)),
                  ],
                )
              ),
            ),
          ),
        ],
      ),
    );
  }


  static OverlayEntry getColorChooser({
    required final Function() onDismiss,
    required Function(Color) onSelected,
    required ColorChooserWidgetOptions options,
  })
  {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            onDismiss: () {onDismiss();},
          ),
          Padding(
            padding: EdgeInsets.all(options.outsidePadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: options.width,
                height: options.height,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).primaryColorLight,
                    width: options.borderWidth,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
                ),
                child: ColorChooserWidget(
                  inputColor: Colors.red,
                  options: options,
                  colorSelected: onSelected,
                  dismiss: onDismiss,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static OverlayEntry getKPal({
    required final Function() onDismiss,
    required final ColorRampFn onAccept,
    required final ColorRampFn onDelete,
    required final KPalRampData colorRamp,

  })
  {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(GetIt.I.get<PreferenceManager>().kPalWidgetOptions.smokeOpacity),
            onDismiss: () {onDismiss();},
          ),
          Padding(
            padding: EdgeInsets.all(GetIt.I.get<PreferenceManager>().kPalWidgetOptions.outsidePadding),
            child: Align(
              alignment: Alignment.center,
              child: KPal(
                dismiss: onDismiss,
                accept: onAccept,
                delete: onDelete,
                colorRamp: colorRamp,
              )
            ),
          ),
        ],
      ),
    );
  }

  static OverlayEntry getAlertDialog({
    required final Function() onDismiss,
    required final Function() onAccept,
    required final String message,
})
  {
    OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            onDismiss: () {onDismiss();},
          ),
          Center(
            child: Material(
              elevation: options.elevation,
              shadowColor: Theme.of(context).primaryColorDark,
              borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
              child: Container(
                  constraints: BoxConstraints(
                    minHeight: options.minHeight,
                    minWidth: options.minWidth,
                    maxHeight: options.maxHeight,
                    maxWidth: options.maxWidth,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    border: Border.all(
                      color: Theme.of(context).primaryColorLight,
                      width: options.borderWidth,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
                  ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(child: Padding(
                      padding: EdgeInsets.all(options.padding),
                      child: Text(message, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center,),
                    )),
                    Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                              flex: 1,
                              child: Padding(
                                padding: EdgeInsets.all(options.padding),
                                child: IconButton.outlined(
                                  icon: FaIcon(
                                    FontAwesomeIcons.xmark,
                                    size: options.iconSize,
                                  ),
                                  onPressed: () {
                                    onDismiss();
                                  },
                                ),
                              )
                          ),
                          Expanded(
                              flex: 1,
                              child: Padding(
                                padding: EdgeInsets.all(options.padding),
                                child: IconButton.outlined(
                                  icon: FaIcon(
                                    FontAwesomeIcons.check,
                                    size: options.iconSize,
                                  ),
                                  onPressed: () {
                                    onAccept();
                                  },
                                ),
                              )
                          ),
                        ]
                    ),
                  ],
                )
              )
            ),
          ),
        ]
      )
    );
  }
}