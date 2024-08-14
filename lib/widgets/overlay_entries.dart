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
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/about_screen_widget.dart';
import 'package:kpix/widgets/canvas_size_widget.dart';
import 'package:kpix/widgets/credits_widget.dart';
import 'package:kpix/widgets/export_widget.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/licenses_widget.dart';


class KPixOverlay
{
  bool isVisible;
  OverlayEntry entry;
  KPixOverlay({required this.entry, this.isVisible = false});

  void show(BuildContext context)
  {
    if (!isVisible)
    {
      Overlay.of(context).insert(entry);
      isVisible = true;
    }
  }

  void hide()
  {
    if (isVisible)
    {
      entry.remove();
      isVisible = false;
    }
  }
}

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
  static KPixOverlay getLoadMenu({
    required final Function onDismiss,
    required Function onLoadFile,
    required Function onLoadPalette,
    required final LayerLink layerLink,

  })
  {
    final OverlayEntrySubMenuOptions options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
    return KPixOverlay(entry: OverlayEntry(
      builder: (context) => Stack(
        children: [
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            onDismiss: () {onDismiss();},
          ),
          Positioned(
            width: options.width / 2,
            child: CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              offset: Offset(
                options.offsetX,
                options.offsetY + options.buttonSpacing,
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
                      child: IconButton.outlined(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(
                            options.buttonSpacing),
                        onPressed: () {onLoadFile();},
                        icon: FaIcon(
                            Icons.file_open,
                            size: options.buttonHeight),
                        color: Theme.of(context).primaryColorLight,
                        style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Theme.of(context).primaryColor),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(options.buttonSpacing / 2),
                      child: IconButton.outlined(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(
                            options.buttonSpacing),
                        onPressed: () {onLoadPalette();},
                        icon: FaIcon(
                            FontAwesomeIcons.palette,
                            size: options.buttonHeight),
                        color: Theme.of(context).primaryColorLight,
                        style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                )
              ),
            ),
          ),
        ],
      ),
    ));
  }


  static KPixOverlay getSaveMenu({
    required final Function onDismiss,
    required Function onSaveFile,
    required Function onSaveAsFile,
    required Function onExportFile,
    required Function onSavePalette,
    required final LayerLink layerLink,
  })
  {
    final OverlayEntrySubMenuOptions options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
    return KPixOverlay(entry: OverlayEntry(
      builder: (context) => Stack(
        children: [
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            onDismiss: () {onDismiss();},
          ),
          Positioned(
            width: options.width / 2,
            child: CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              offset: Offset(
                options.offsetX,
                options.offsetY + options.buttonSpacing,
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
                      child: IconButton.outlined(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(
                            options.buttonSpacing),
                        onPressed: () {onSaveFile();},
                        icon: FaIcon(
                            Icons.save,
                            size: options.buttonHeight),
                        color: Theme.of(context).primaryColorLight,
                        style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Theme.of(context).primaryColor),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(options.buttonSpacing / 2),
                      child: IconButton.outlined(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(
                            options.buttonSpacing),
                        onPressed: () {onSaveAsFile();},
                        icon: FaIcon(
                            Icons.save_as,
                            size: options.buttonHeight),
                        color: Theme.of(context).primaryColorLight,
                        style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Theme.of(context).primaryColor),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(options.buttonSpacing / 2),
                      child: IconButton.outlined(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(
                            options.buttonSpacing),
                        onPressed: () {onExportFile();},
                        icon: FaIcon(
                            Icons.share,
                            size: options.buttonHeight),
                        color: Theme.of(context).primaryColorLight,
                        style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Theme.of(context).primaryColor),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(options.buttonSpacing / 2),
                      child: IconButton.outlined(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(
                            options.buttonSpacing),
                        onPressed: () {onSavePalette();},
                        icon: FaIcon(
                            Icons.palette,
                            size: options.buttonHeight),
                        color: Theme.of(context).primaryColorLight,
                        style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                )
              ),
            ),
          ),
        ],
      ),
    ));
  }


  static KPixOverlay getLayerMenu({
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
    return KPixOverlay(
      entry: OverlayEntry(
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
                            backgroundColor: Theme.of(context).primaryColor)
                      ),
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
                            backgroundColor: Theme.of(context).primaryColor)
                      ),
                    ],
                  )
                ),
              ),
            ),
          ],
        ),
      )
    );
  }



  static KPixOverlay getKPal({
    required final Function() onDismiss,
    required final ColorRampUpdateFn onAccept,
    required final ColorRampFn onDelete,
    required final KPalRampData colorRamp,

  })
  {
    return KPixOverlay(entry:  OverlayEntry(
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
    ));
  }

  static KPixOverlay getAlertDialog({
    required final Function() onDismiss,
    required final Function() onAccept,
    required final String message,
})
  {
    OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
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
      )
    );
  }

  static KPixOverlay getThreeButtonDialog({
    required final Function() onYes,
    required final Function() onNo,
    required final Function() onCancel,
    required bool outsideCancelable,
    required final String message,
  })
  {
    OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (context) => Stack(
          children: [
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
              onDismiss: outsideCancelable ? onCancel : null,//onCancel,
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
                                  FontAwesomeIcons.thumbsUp,
                                  size: options.iconSize,
                                ),
                                onPressed: () {
                                  onYes();
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
                                  FontAwesomeIcons.thumbsDown,
                                  size: options.iconSize,
                                ),
                                onPressed: () {
                                  onNo();
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
                                  FontAwesomeIcons.ban,
                                  size: options.iconSize,
                                ),
                                onPressed: () {
                                  onCancel();
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
      )
    );
  }


  static KPixOverlay getExportDialog({
    required final Function() onDismiss,
    required final ExportDataFn onAccept,
    required final CoordinateSetI canvasSize
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (context) => Stack(
          children: [
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
              onDismiss: () {onDismiss();},
            ),
            Center(
              child: ExportWidget(accept: onAccept, dismiss: onDismiss, canvasSize: canvasSize),
            ),
          ]
        )
      )
    );
  }

  static KPixOverlay getAboutDialog({
    required final Function() onDismiss,
    required final CoordinateSetI canvasSize
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (context) => Stack(
          children: [
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
              onDismiss: () {onDismiss();},
            ),
            const Center(
              child: AboutScreenWidget()
            ),
          ]
        )
     )
    );
  }

  static KPixOverlay getLicensesDialog({
    required final Function() onDismiss,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (context) => Stack(
          children: [
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
              onDismiss: () {onDismiss();},
            ),
            const Center(
              child: LicensesWidget(),
            ),
          ]
        )
      )
    );
  }

  static KPixOverlay getCreditsDialog({
    required final Function() onDismiss,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (context) => Stack(
          children: [
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
              onDismiss: () {onDismiss();},
            ),
            const Center(
              child: CreditsWidget(),
            ),
          ]
        )
      )
    );
  }

  static KPixOverlay getCanvasSizeDialog({
    required final Function() onDismiss,
    required final CanvasSizeFn onAccept
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (context) => Stack(
          children: [
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
              onDismiss: () {onDismiss();},
            ),
            Center(
              child: CanvasSizeWidget(accept: onAccept, dismiss: onDismiss),
            ),
          ]
        )
      )
    );
  }
}