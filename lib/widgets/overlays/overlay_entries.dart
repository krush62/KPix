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
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas/canvas_size_widget.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_color_picker_widget.dart';
import 'package:kpix/widgets/extra/about_screen_widget.dart';
import 'package:kpix/widgets/extra/credits_widget.dart';
import 'package:kpix/widgets/extra/licenses_widget.dart';
import 'package:kpix/widgets/extra/preferences_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/file/import_widget.dart';
import 'package:kpix/widgets/file/new_project_widget.dart';
import 'package:kpix/widgets/file/project_manager_widget.dart';
import 'package:kpix/widgets/file/save_as_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/overlays/overlay_add_new_layer_menu.dart';
import 'package:kpix/widgets/overlays/overlay_drawing_layer_menu.dart';
import 'package:kpix/widgets/overlays/overlay_load_menu.dart';
import 'package:kpix/widgets/overlays/overlay_raster_layer_menu.dart';
import 'package:kpix/widgets/overlays/overlay_reduced_layer_menu.dart';
import 'package:kpix/widgets/overlays/overlay_save_menu.dart';
import 'package:kpix/widgets/palette/palette_manager_widget.dart';
import 'package:kpix/widgets/palette/save_palette_widget.dart';
import 'package:kpix/widgets/stamps/stamp_manager_widget.dart';


class KPixOverlay
{
  bool isVisible;
  OverlayEntry entry;
  KPixOverlay({required this.entry, this.isVisible = false});
  Function()? closeCallback;

  void show({required final BuildContext context, final Function()? callbackFunction})
  {
    if (!isVisible)
    {
      Overlay.of(context).insert(entry);
      isVisible = true;
    }
    closeCallback = callbackFunction;
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
  final int animationLengthMs;

  OverlayEntrySubMenuOptions({
    required this.offsetX,
    required this.offsetXLeft,
    required this.offsetY,
    required this.buttonSpacing,
    required this.width,
    required this.buttonHeight,
    required this.smokeOpacity,
    required this.animationLengthMs,
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



  KPixOverlay getLoadMenu({
    required final Function() onDismiss,
    required final Function() onNewFile,
    required final Function() onLoadFile,
    required final Function() onImportFile,
    required final LayerLink layerLink,
  })
  {
    final OverlayEntrySubMenuOptions options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
    return KPixOverlay(entry: OverlayEntry(
      builder: (final BuildContext context) => Stack(
        children: <Widget>[
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            onDismiss: () {onDismiss();},
          ),
          OverlayLoadMenu(layerLink: layerLink, onNewFile: onNewFile, onImportFile: onImportFile, onLoadFile: onLoadFile),
        ],
      ),
    ),);
  }


  KPixOverlay getSaveMenu({
    required final Function() onDismiss,
    required final Function() onSaveFile,
    required final Function() onSaveAsFile,
    required final Function() onExportFile,
    required final LayerLink layerLink,
  })
  {
    final OverlayEntrySubMenuOptions options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;

    return KPixOverlay(entry: OverlayEntry(
      builder: (final BuildContext context) => Stack(
        children: <Widget>[
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            onDismiss: () {onDismiss();},
          ),
          OverlaySaveMenu(layerLink: layerLink, onSaveFile: onSaveFile, onSaveAsFile: onSaveAsFile, onExportFile: onExportFile),
        ],
      ),
    ),);
  }


  KPixOverlay getDrawingLayerMenu({
    required final Function() onDismiss,
    required final Function() onDelete,
    required final Function() onMergeDown,
    required final Function() onDuplicate,
    required final LayerLink layerLink,
  })
  {
    final OverlayEntrySubMenuOptions options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
              onDismiss: () {onDismiss();},
            ),
            OverlayDrawingLayerMenu(onDelete: onDelete, onMergeDown: onMergeDown, onDuplicate: onDuplicate, layerLink: layerLink),
          ],
        ),
      ),
    );
  }

  KPixOverlay getReducedLayerMenu({
    required final Function() onDismiss,
    required final Function() onDelete,
    required final Function() onDuplicate,
    required final LayerLink layerLink,
  })
  {
    final OverlayEntrySubMenuOptions options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
              onDismiss: () {onDismiss();},
            ),
            OverlayReducedLayerMenu(onDelete: onDelete, onDuplicate: onDuplicate, layerLink: layerLink),
            ],
          ),
        ),
    );
  }

KPixOverlay getRasterLayerMenu({
  required final Function() onDismiss,
  required final Function() onDelete,
  required final Function() onDuplicate,
  required final Function() onRaster,
  required final LayerLink layerLink,
})
{
  final OverlayEntrySubMenuOptions options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
  return KPixOverlay(
    entry: OverlayEntry(
      builder: (final BuildContext context) => Stack(
        children: <Widget>[
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            onDismiss: () {onDismiss();},
          ),
          OverlayRasterLayerMenu(layerLink: layerLink, onDuplicate: onDuplicate, onDelete: onDelete, onRaster: onRaster),
        ],
      ),
    ),
  );
}



  KPixOverlay getKPal({
    required final ColorRampUpdateFn onAccept,
    required final ColorRampFn onDelete,
    required final KPalRampData colorRamp,
    required final int usedPixels
  })
  {
    return KPixOverlay(entry:  OverlayEntry(
      builder: (final BuildContext context) => Stack(
        children: <Widget>[
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(GetIt.I.get<PreferenceManager>().kPalWidgetOptions.smokeOpacity),
          ),
          Padding(
            padding: EdgeInsets.all(GetIt.I.get<PreferenceManager>().kPalWidgetOptions.outsidePadding),
            child: KPal(
              accept: onAccept,
              delete: onDelete,
              colorRamp: colorRamp,
              usedPixels: usedPixels,
            ),
          ),
        ],
      ),
    ),);
  }

  KPixOverlay getThreeButtonDialog({
    required final Function() onYes,
    required final Function() onNo,
    required final Function() onCancel,
    required final bool outsideCancelable,
    required final String message,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
              onDismiss: outsideCancelable ? onCancel : null,//onCancel,
            ),
            Center(
              child: KPixAnimationWidget(
                constraints: BoxConstraints(
                  minHeight: options.minHeight,
                  minWidth: options.minWidth,
                  maxHeight: options.maxHeight,
                  maxWidth: options.maxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Center(child: Padding(
                      padding: EdgeInsets.all(options.padding),
                      child: Text(message, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center,),
                    ),),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(options.padding),
                            child: IconButton.outlined(
                              icon: FaIcon(
                                FontAwesomeIcons.check,
                                size: options.iconSize,
                              ),
                              onPressed: () {
                                onYes();
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(options.padding),
                            child: IconButton.outlined(
                              icon: FaIcon(
                                FontAwesomeIcons.xmark,
                                size: options.iconSize,
                              ),
                              onPressed: () {
                                onNo();
                              },
                            ),
                          ),
                        ),
                        Expanded(
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
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  KPixOverlay getTwoButtonDialog({
    required final Function() onYes,
    required final Function() onNo,
    required final bool outsideCancelable,
    required final String message,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
        entry: OverlayEntry(
          builder: (final BuildContext context) => Stack(
            children: <Widget>[
              ModalBarrier(
                color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
                onDismiss: outsideCancelable ? onNo : null,
              ),
              Center(
                child: KPixAnimationWidget(
                  constraints: BoxConstraints(
                    minHeight: options.minHeight,
                    minWidth: options.minWidth,
                    maxHeight: options.maxHeight,
                    maxWidth: options.maxWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Center(child: Padding(
                        padding: EdgeInsets.all(options.padding),
                        child: Text(message, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center,),
                      ),),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(options.padding),
                              child: IconButton.outlined(
                                icon: FaIcon(
                                  FontAwesomeIcons.check,
                                  size: options.iconSize,
                                ),
                                onPressed: () {
                                  onYes();
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(options.padding),
                              child: IconButton.outlined(
                                icon: FaIcon(
                                  FontAwesomeIcons.xmark,
                                  size: options.iconSize,
                                ),
                                onPressed: () {
                                  onNo();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              ],
            ),
        ),
    );
  }

KPixOverlay getSingleButtonDialog({
  required final Function() onAction,
  required final String message,
})
{
  final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  return KPixOverlay(
    entry: OverlayEntry(
      builder: (final BuildContext context) => Stack(
        children: <Widget>[
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
          ),
          Center(
            child: KPixAnimationWidget(
              constraints: BoxConstraints(
                minHeight: options.minHeight,
                minWidth: options.minWidth,
                maxHeight: options.maxHeight,
                maxWidth: options.maxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Center(child: Padding(
                    padding: EdgeInsets.all(options.padding),
                    child: Text(message, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center,),
                  ),),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(options.padding),
                          child: IconButton.outlined(
                            icon: FaIcon(
                              FontAwesomeIcons.check,
                              size: options.iconSize,
                            ),
                            onPressed: () {
                              onAction();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  KPixOverlay getExportDialog({
    required final Function() onDismiss,
    required final ExportDataFn onAcceptFile,
    required final PaletteDataFn onAcceptPalette,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
              child: ExportWidget(acceptFile: onAcceptFile, acceptPalette: onAcceptPalette, dismiss: onDismiss),
            ),
          ],
        ),
      ),
    );
  }

  KPixOverlay getImportDialog({
    required final Function() onDismiss,
    required final ImportImageFn onAcceptImage,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
              child: ImportWidget(dismiss: onDismiss, import: onAcceptImage,),
            ),
          ],
        ),
      ),
    );
  }

  KPixOverlay getPaletteSaveDialog({
    required final Function() onDismiss,
    required final PaletteDataFn onAccept,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
              child: SavePaletteWidget(accept: onAccept, dismiss: onDismiss),
            ),
          ],
        ),
      ),
    );
  }

  KPixOverlay getSaveAsDialog({
    required final Function() onDismiss,
    required final SaveFileFn onAccept,
    final Function()? callback,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
              child: SaveAsWidget(accept: onAccept, dismiss: onDismiss, callback: callback),
            ),
          ],
        ),
      ),
    );
  }

  KPixOverlay getAboutDialog({
    required final Function() onDismiss,
    required final CoordinateSetI canvasSize,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
              child: AboutScreenWidget(onDismiss: onDismiss),
            ),
          ],
        ),
     ),
    );
  }

  KPixOverlay getLicensesDialog({
    required final Function() onDismiss,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
              child: LicensesWidget(onDismiss: onDismiss),
            ),
          ],
        ),
      ),
    );
  }

  KPixOverlay getCreditsDialog({
    required final Function() onDismiss,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
              child: CreditsWidget(onDismiss: onDismiss),
            ),
          ],
        ),
      ),
    );
  }

  KPixOverlay getCanvasSizeDialog({
    required final Function() onDismiss,
    required final CanvasSizeFn onAccept,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
              child: CanvasSizeWidget(accept: onAccept, dismiss: onDismiss),
            ),
          ],
        ),
      ),
    );
  }

  KPixOverlay getPreferencesDialog({
    required final Function() onDismiss,
    required final Function() onAccept,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
              child: PreferencesWidget(dismiss: onDismiss, accept: onAccept),
            ),
          ],
        ),
      ),
    );
  }

  KPixOverlay getNewProjectDialog({
    required final Function() onDismiss,
    required final NewFileFn onAccept,
    required final Function() onOpen,
  })
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
              child: NewProjectWidget(accept: onAccept, dismiss: onDismiss, open: onOpen),
            ),
          ],
        ),
      ),
    );
  }

  KPixOverlay getPaletteManagerDialog({required final Function() onDismiss})
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
              child: PaletteManagerWidget(dismiss: onDismiss,),
            ),
          ],
        ),
      ),
    );
  }

  KPixOverlay getProjectManagerDialog({required final Function() onDismiss, required final SaveKnownFileFn onSave, required final Function() onLoad})
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
                child: ProjectManagerWidget(dismiss: onDismiss, saveKnownFileFn: onSave, fileLoad: onLoad,),
            ),
          ],
        ),
      ),
    );
  }

KPixOverlay getStampManagerDialog({required final Function() onDismiss, required final StampEntryDataFn onLoad})
{
  final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  return KPixOverlay(
    entry: OverlayEntry(
      builder: (final BuildContext context) => Stack(
        children: <Widget>[
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
          ),
          Center(
            child: StampManagerWidget(dismiss: onDismiss, fileLoad: onLoad,),
          ),
        ],
      ),
    ),
  );
}

  KPixOverlay getAddLayerMenu({
    required final Function() onDismiss,
    required final Function() onNewDrawingLayer,
    required final Function() onNewReferenceLayer,
    required final Function() onNewGridLayer,
    required final Function() onNewShadingLayer,
    required final LayerLink layerLink,
  })
  {
    final OverlayEntrySubMenuOptions options = GetIt.I.get<PreferenceManager>().overlayEntryOptions;
    return KPixOverlay(entry: OverlayEntry(
      builder: (final BuildContext context) => Stack(
        children: <Widget>[
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            onDismiss: () {onDismiss();},
          ),
          OverlayAddNewLayerMenu(layerLink: layerLink, onNewDrawingLayer: onNewDrawingLayer, onNewReferenceLayer: onNewReferenceLayer, onNewGridLayer: onNewGridLayer, onNewShadingLayer: onNewShadingLayer),
        ],
      ),
    ),);
  }

  KPixOverlay getLoadingDialog({required final String message})
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixOverlay(
      entry: OverlayEntry(
        builder: (final BuildContext context) => Stack(
          children: <Widget>[
            ModalBarrier(
              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
            ),
            Center(
              child: Center(
                child: KPixAnimationWidget(
                  constraints: BoxConstraints(
                    maxHeight: options.maxHeight / 4.0,
                    maxWidth: options.maxWidth / 2.0,
                  ),
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

KPixOverlay getColorPickerDialog({required final Function() onDismiss, required final ColorReferenceSelectedFn onColorSelected, required final List<KPalRampData> ramps, final String title = "SELECT A COLOR"})
{
  final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  return KPixOverlay(
    entry: OverlayEntry(
      builder: (final BuildContext context) => Stack(
        children: <Widget>[
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
          ),
          Center(
            child: KPixAnimationWidget(
              constraints: BoxConstraints(
                maxHeight: options.maxHeight,
                maxWidth: options.maxWidth,
              ),
              child: KPixColorPickerWidget(
                dismiss: onDismiss,
                colorSelected: onColorSelected,
                ramps: ramps,
                title: title,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
