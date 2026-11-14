/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/constraints/canvas_size_constraints.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/util/file_pickers.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:kpix/util/helpers/format_helper.dart';
import 'package:kpix/util/helpers/image_helper.dart';
import 'package:kpix/util/image_importer.dart';
import 'package:kpix/widgets/callback_typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:material_ui/material_ui.dart';


/// Data structure for import options used in [ImportWidget].
class ImportWidget extends StatefulWidget
{
  final Function() dismiss;
  final ImportImageFn import;
  final String? initialPath;
  const ImportWidget({super.key, required this.dismiss, required this.import, this.initialPath});

  @override
  State<ImportWidget> createState() => ImportWidgetState();
}

class ImportWidgetState extends State<ImportWidget>
{
  late ValueNotifier<int> _maxRampsNotifier;
  late ValueNotifier<int> _maxColorsPerRampNotifier;
  final ValueNotifier<String?> _fileNameNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _includeReferenceNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _createNewPaletteNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> _messageNotifier = ValueNotifier<String>("");
  final ValueNotifier<ui.Image?> _imageNotifier = ValueNotifier<ui.Image?>(null);
  bool _imageHandedOver = false;
  final ValueNotifier<int> _scaleDownNotifier = ValueNotifier<int>(1);
  final KPixOverlay _loadingDialog = getLoadingDialog(message: (final AppLocalizations l10n) => l10n.openingImageDot);
  static const int _maximumScale = 16;
  int _currentMinScale = 1;
  int _currentMaxScale = 1;

  @override
  void dispose()
  {
    super.dispose();
    _loadingDialog.hide();
    _maxRampsNotifier.dispose();
    _maxColorsPerRampNotifier.dispose();
    _fileNameNotifier.dispose();
    _includeReferenceNotifier.dispose();
    _messageNotifier.dispose();
    final ui.Image? image = _imageNotifier.value;
    if (image != null && !_imageHandedOver)
    {
      disposeAfterFrame(images: <ui.Image>[image]);
    }
  }

  @override
  void initState()
  {
    super.initState();
    _maxRampsNotifier = ValueNotifier<int>(KPalConstraints.rampCountLimits.defaultValue);
    _maxColorsPerRampNotifier = ValueNotifier<int>(KPalConstraints.colorCountLimits.defaultValue);
    final String? initialPath = widget.initialPath;
    if (initialPath != null)
    {
      //the loading dialog needs the overlay, which is still building here
      WidgetsBinding.instance.addPostFrameCallback((final Duration _)
      {
        if (mounted)
        {
          _prepareImageData(loadData: (initialPath, null), l10n: AppLocalizations.of(context)!);
        }
      });
    }
  }

  void _chooseImagePressed({required final AppLocalizations l10n})
  {
    getPathAndDataForImage().then((final (String?, Uint8List?) loadData) {
      if (!mounted)
      {
        return;
      }
      _prepareImageData(loadData: loadData, l10n: l10n);
    });
  }

  void _prepareImageData({required final (String?, Uint8List?) loadData, required final AppLocalizations l10n})
  {
    if (loadData.$1 != null || loadData.$2 != null)
    {
      _loadingDialog.show(context: context);
      loadImage(path: loadData.$1!, bytes: loadData.$2).then((final ui.Image? img)
      {
        _loadingDialog.hide();
        if (!mounted)
        {
          img?.dispose();
          return;
        }
        if (img != null)
        {
          if ((img.width ~/ _maximumScale) > CanvasSizeConstraints.sizeMax || (img.height ~/ _maximumScale) > CanvasSizeConstraints.sizeMax || img.width < CanvasSizeConstraints.sizeMin || img.height < CanvasSizeConstraints.sizeMin)
          {
            img.dispose();
            _currentMinScale = 1;
            _currentMaxScale = 1;
            _scaleDownNotifier.value = 1;
            _fileNameNotifier.value = null;
            _setImage(image: null);
            _messageNotifier.value = l10n.imageDimensionsExceed(width: CanvasSizeConstraints.sizeMax * _maximumScale, height: CanvasSizeConstraints.sizeMax * _maximumScale);
          }
          else
          {
            int? minScale;
            int? maxScale;
            for (int i = 1; i <= _maximumScale; i++)
            {
              final int tempX = img.width ~/ i;
              final int tempY = img.height ~/ i;
              if (minScale == null && tempX <= CanvasSizeConstraints.sizeMax && tempY <= CanvasSizeConstraints.sizeMax)
              {
                minScale = i;
              }
              if (tempX >= CanvasSizeConstraints.sizeMin && tempY >= CanvasSizeConstraints.sizeMin)
              {
                maxScale = i;
              }
              else
              {
                break;
              }
            }
            _currentMinScale = minScale ?? 1;
            _currentMaxScale = maxScale ?? 1;
            _scaleDownNotifier.value = _currentMinScale;
            _messageNotifier.value = "";
            _setImage(image: img);
            _fileNameNotifier.value = loadData.$1;
          }
        }
        else
        {
          _currentMinScale = 1;
          _currentMaxScale = 1;
          _scaleDownNotifier.value = 1;
          _messageNotifier.value = l10n.couldNotDecodeImage;
          _setImage(image: null);
          _fileNameNotifier.value = null;
        }
      },)
      .catchError((final Object e)
      {
        _loadingDialog.hide();
      },);
    }
    else
    {
      _currentMinScale = 1;
      _currentMaxScale = 1;
      _scaleDownNotifier.value = 1;
      _messageNotifier.value = l10n.couldNotLoadFile;
      _setImage(image: null);
      _fileNameNotifier.value = null;
    }
  }

  /// Does nothing until an image was chosen, like the disabled import button.
  void accept()
  {
    if (_fileNameNotifier.value != null)
    {
      _loadImage();
    }
  }

  /// Shows [image] in place of the current one, which is released unless the import took it.
  void _setImage({required final ui.Image? image})
  {
    final ui.Image? previous = _imageNotifier.value;
    _imageNotifier.value = image;
    if (previous != null && !identical(previous, image) && !_imageHandedOver)
    {
      disposeAfterFrame(images: <ui.Image>[previous]);
    }
    _imageHandedOver = false;
  }

  void _loadImage()
  {
    if (_fileNameNotifier.value != null && _imageNotifier.value != null) //should never happen
    {
      //the import owns the image from here on
      _imageHandedOver = true;
      final ImportData data = ImportData(image: _imageNotifier.value!, scale: _scaleDownNotifier.value, filePath: _fileNameNotifier.value!, includeReference: _includeReferenceNotifier.value, maxColors: _maxColorsPerRampNotifier.value, maxRamps: _maxRampsNotifier.value, maxClusters: KPalConstraints.maxClusters, createNewPalette: _createNewPaletteNotifier.value);
      widget.import(importData: data);
    }
  }

  Widget _createPaletteLimitRow({required final String label, required final ValueNotifier<int> notifier, required final int min, required final int max})
  {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Text(label),
        ),
        Expanded(
          flex: 4,
          child: ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[_createNewPaletteNotifier, notifier]),
            builder: (final BuildContext context, final Widget? child)
            {
              return KPixSlider(
                value: notifier.value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                onChanged: _createNewPaletteNotifier.value ? (final double newValue) {
                  notifier.value = newValue.round();
                } : null,
                textStyle: Theme.of(context).textTheme.bodyLarge!,
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return KPixAnimationWidget(
      constraints: const BoxConstraints(
        minHeight: OverlayEntryAlertDialogOptions.minHeight,
        minWidth: OverlayEntryAlertDialogOptions.minWidth,
        maxHeight: OverlayEntryAlertDialogOptions.maxHeight,
        maxWidth: OverlayEntryAlertDialogOptions.maxWidth,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(l10n.importImage.toUpperCase(), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
          Padding(
            padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: Text(l10n.file),
                          ),
                          Expanded(
                            flex: 5,
                            child: ValueListenableBuilder<String?>(
                              valueListenable: _fileNameNotifier,
                              builder: (final BuildContext context, final String? path, final Widget? child) {
                                return Text(
                                  path == null ? "<${l10n.noFileSelected.toUpperCase()}>" : extractFilenameFromPath(path: path),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                          ),
                          DialogActionButton.directory(
                            l10n: l10n,
                            onPressed: () {_chooseImagePressed(l10n: l10n);},
                            tooltip: l10n.chooseImage,
                            icon: TablerIcons.folder_open,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: Text(l10n.scaleDown),
                          ),
                          Expanded(
                            flex: 4,
                            child: ListenableBuilder(
                              listenable: Listenable.merge(<Listenable>[_imageNotifier, _scaleDownNotifier]),
                              builder: (final BuildContext context, final Widget? child)
                              {
                                final ui.Image? img = _imageNotifier.value;
                                final int scaleVal = _scaleDownNotifier.value;
                                final String originalDims = img != null ? formatDimension(width: img.width, height: img.height) : "";
                                final String scaledDims = img != null ? formatDimension(width: img.width ~/ scaleVal, height: img.height ~/ scaleVal) : "";

                                return KPixSlider(
                                  value: scaleVal.toDouble(),
                                  label: img != null ? "$originalDims -> $scaledDims" : "",
                                  min: _currentMinScale.toDouble(),
                                  max: _currentMaxScale.toDouble(),
                                  onChanged: (img != null) ? (final double newValue) {
                                    _scaleDownNotifier.value = newValue.round();
                                  } : null,
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Divider(height: 2, thickness: 2, color: Theme.of(context).primaryColorLight,),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Expanded(
                            flex: 7,
                            child: Text(l10n.createNewPaletteFromImage),
                          ),
                          Expanded(
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _createNewPaletteNotifier,
                              builder: (final BuildContext context, final bool createNewPalette, final Widget? child) {
                                return Switch(
                                  value: createNewPalette,
                                  onChanged: (final bool newVal) {
                                    _createNewPaletteNotifier.value = newVal;
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      _createPaletteLimitRow(
                        label: l10n.maxColorRamps,
                        notifier: _maxRampsNotifier,
                        min: KPalConstraints.rampCountLimits.min,
                        max: KPalConstraints.maxClusters,
                      ),
                      _createPaletteLimitRow(
                        label: l10n.maxColorsPerRamp,
                        notifier: _maxColorsPerRampNotifier,
                        min: KPalConstraints.colorCountLimits.min,
                        max: KPalConstraints.colorCountLimits.max,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Divider(height: 2, thickness: 2, color: Theme.of(context).primaryColorLight,),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Expanded(
                            flex: 7,
                            child: Text(l10n.includeImageAsReferenceLayer),
                          ),
                          Expanded(
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _includeReferenceNotifier,
                              builder: (final BuildContext context, final bool includeReference, final Widget? child) {
                                return Switch(
                                  value: includeReference,
                                  onChanged: (final bool newVal) {
                                    _includeReferenceNotifier.value = newVal;
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: _messageNotifier,
                        builder: (final BuildContext context, final String message, final Widget? child)
                        {
                          return Text(message, style: Theme.of(context).textTheme.bodyMedium!.apply(color: Theme.of(context).primaryColorDark));
                        },
                      ),

                    ],
                  ),
                ),
                const SizedBox(width: OverlayEntryAlertDialogOptions.padding * 2,),
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).primaryColorLight, width: OverlayEntryAlertDialogOptions.borderWidth),
                        borderRadius: BorderRadius.circular(OverlayEntryAlertDialogOptions.borderRadius / 2),
                      ),
                      child: ValueListenableBuilder<ui.Image?>(
                        valueListenable: _imageNotifier,
                        builder: (final BuildContext context, final ui.Image? img, final Widget? child) {
                          return Padding(
                            padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.borderWidth),
                            child: RawImage(image: img, fit: BoxFit.contain, filterQuality: FilterQuality.none,),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              DialogActionButton.cancel(onPressed: widget.dismiss, l10n: l10n),
              const SizedBox(width: OverlayEntryAlertDialogOptions.padding),
              ValueListenableBuilder<String?>(
                valueListenable: _fileNameNotifier,
                builder: (final BuildContext context, final String? fileNameValue, final Widget? child) {
                  return DialogActionButton(
                    tooltip: l10n.importImage,
                    icon: TablerIcons.check,
                    onPressed: _fileNameNotifier.value == null ? null : accept,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
