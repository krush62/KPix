import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/color_names.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/color_chooser_widget.dart';

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
    required final OverlayEntrySubMenuOptions options
  })
  {
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
    required final OverlayEntrySubMenuOptions options
  })
  {
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
    required final OverlayEntrySubMenuOptions options
  })
  {
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
                options.offsetXLeft,
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
                                  onDelete();
                                },
                                child: const Text("Delete Layer")
                            )
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(options.buttonSpacing / 2),
                        child: SizedBox(
                            height: options.buttonHeight,
                            child: ElevatedButton(
                                onPressed: () {
                                  onMergeDown();
                                },
                                child: const Text("Merge Down")
                            )
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(options.buttonSpacing / 2),
                        child: SizedBox(
                            height: options.buttonHeight,
                            child: ElevatedButton(
                                onPressed: () {
                                  onDuplicate();
                                },
                                child: const Text("Duplicate Layer")
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
    required final KPalWidgetOptions options,
    required final KPalConstraints constraints,
    required final KPalRampData colorRamp,
    required final OverlayEntryAlertDialogOptions alertDialogOptions,
    required final ColorNames colorNames,

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
              alignment: Alignment.center,
              child: KPal(
                kPalConstraints: constraints,
                options: options,
                colorRamp: colorRamp,
                dismiss: onDismiss,
                accept: onAccept,
                delete: onDelete,
                alertDialogOptions: alertDialogOptions,
                colorNames: colorNames,
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
    required final OverlayEntryAlertDialogOptions options,
})
  {
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