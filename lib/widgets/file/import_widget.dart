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

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/image_importer.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas/canvas_size_widget.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';


class ImportData
{
  final int maxClusters;
  final int maxRamps;
  final int maxColors;
  final bool includeReference;
  final bool createNewPalette;
  final ui.Image image;
  final String filePath;
  const ImportData({required this.filePath, required this.maxRamps, required this.maxColors, required this.image, required this.includeReference, required this.maxClusters, required this.createNewPalette});
}

class ImportWidget extends StatefulWidget
{
  final Function() dismiss;
  final ImportImageFn import;
  const ImportWidget({super.key, required this.dismiss, required this.import});

  @override
  State<ImportWidget> createState() => _ImportWidgetState();
}

class _ImportWidgetState extends State<ImportWidget>
{
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final KPalConstraints _constraints = GetIt.I.get<PreferenceManager>().kPalConstraints;
  late ValueNotifier<int> _maxRampsNotifier;
  late ValueNotifier<int> _maxColorsPerRampNotifier;
  final ValueNotifier<String?> _fileNameNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _includeReferenceNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _createNewPaletteNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<String> _messageNotifier = ValueNotifier<String>("");
  final ValueNotifier<ui.Image?> _imageNotifier = ValueNotifier<ui.Image?>(null);


  @override
  void dispose()
  {
    super.dispose();
    _maxRampsNotifier.dispose();
    _maxColorsPerRampNotifier.dispose();
    _fileNameNotifier.dispose();
    _includeReferenceNotifier.dispose();
    _messageNotifier.dispose();
  }

  @override
  void initState()
  {
    super.initState();
    _maxRampsNotifier = ValueNotifier<int>(_constraints.rampCountDefault);
    _maxColorsPerRampNotifier = ValueNotifier<int>(_constraints.colorCountDefault);
  }


  void _chooseImagePressed()
  {
    getPathAndDataForImage().then((final (String?, Uint8List?) loadData) {
      _prepareImageData(loadData: loadData);
    });
  }

  void _prepareImageData({required final (String?, Uint8List?) loadData})
  {
    if (loadData.$1 != null || loadData.$2 != null)
    {
      loadImage(path: loadData.$1!, bytes: loadData.$2).then((final ui.Image? img)
      {
        final CanvasSizeOptions canvasSizeOptions = GetIt.I.get<PreferenceManager>().canvasSizeOptions;
        if (img != null)
        {
          if (img.width > canvasSizeOptions.sizeMax || img.height > canvasSizeOptions.sizeMax || img.width < canvasSizeOptions.sizeMin || img.height < canvasSizeOptions.sizeMin)
          {
            _fileNameNotifier.value = null;
            _imageNotifier.value = null;
            _messageNotifier.value = "Image dimensions cannot exceed ${canvasSizeOptions.sizeMax}x${canvasSizeOptions.sizeMax}!";
          }
          else
          {
            _messageNotifier.value = "";
            _imageNotifier.value = img;
            _fileNameNotifier.value = loadData.$1;
          }
        }
        else
        {
          _messageNotifier.value = "Could not decode image!";
          _imageNotifier.value = null;
          _fileNameNotifier.value = null;
        }
      },);
    }
    else
    {
      _messageNotifier.value = "Could not load file!";
      _imageNotifier.value = null;
      _fileNameNotifier.value = null;
    }
  }

  void _loadImage()
  {
    if (_fileNameNotifier.value != null && _imageNotifier.value != null) //should never happen
    {

      final ImportData data = ImportData(image: _imageNotifier.value!, filePath: _fileNameNotifier.value!, includeReference: _includeReferenceNotifier.value, maxColors: _maxColorsPerRampNotifier.value, maxRamps: _maxRampsNotifier.value, maxClusters: _constraints.maxClusters, createNewPalette: _createNewPaletteNotifier.value);
      widget.import(importData: data);
    }
  }

  @override
  Widget build(final BuildContext context)
  {
    return KPixAnimationWidget(
      constraints: BoxConstraints(
        minHeight: _options.minHeight,
        minWidth: _options.minWidth,
        maxHeight: _options.maxHeight,
        maxWidth: _options.maxWidth,
      ),
      child: Padding(
        padding: EdgeInsets.all(_options.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text("IMPORT IMAGE", style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: _options.padding),
            Row(
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          const Expanded(
                            flex: 2,
                            child: Text("File"),
                          ),
                          Expanded(
                            flex: 5,
                            child: ValueListenableBuilder<String?>(
                              valueListenable: _fileNameNotifier,
                              builder: (final BuildContext context, final String? path, final Widget? child) {
                                return Text(
                                  path == null ? "<NO FILE SELECTED>" : extractFilenameFromPath(path: path),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: Tooltip(
                              message: "Choose Image",
                              waitDuration: AppState.toolTipDuration,
                              child: IconButton.outlined(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.all(_options.padding),
                                onPressed: _chooseImagePressed,
                                icon: FaIcon(
                                  FontAwesomeIcons.folderOpen,
                                  size: _options.iconSize / 2,
                                ),
                                color: Theme.of(context).primaryColorLight,
                                style: IconButton.styleFrom(
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          const Expanded(
                            flex: 7,
                            child: Text("Create a New Palette From Image"),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          const Expanded(
                            flex: 3,
                            child: Text("Max Color Ramps"),
                          ),
                          Expanded(
                            flex: 4,
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _createNewPaletteNotifier,
                              builder: (final BuildContext context, final bool createNew, final Widget? child)
                              {
                                return  ValueListenableBuilder<int>(
                                  valueListenable: _maxRampsNotifier,
                                  builder: (final BuildContext context, final int maxRampValue, final Widget? child) {
                                    return KPixSlider(
                                      value: maxRampValue.toDouble(),
                                      min: _constraints.rampCountMin.toDouble(),
                                      max: _constraints.maxClusters.toDouble(),
                                      divisions: _constraints.maxClusters - _constraints.rampCountMin,
                                      onChanged: createNew ? (final double newValue) {
                                        _maxRampsNotifier.value = newValue.round();
                                      } : null,
                                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                                    );
                                  },
                                );
                              },

                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          const Expanded(
                            flex: 3,
                            child: Text("Max Colors per Ramp"),
                          ),
                          Expanded(
                            flex: 4,
                            child: ValueListenableBuilder<bool>(
                                valueListenable: _createNewPaletteNotifier,
                                builder: (final BuildContext context, final bool createNew, final Widget? child)
                                {
                                  return ValueListenableBuilder<int>(
                                    valueListenable: _maxColorsPerRampNotifier,
                                    builder: (final BuildContext context, final int maxColorsValue, final Widget? child) {
                                      return KPixSlider(
                                        value: maxColorsValue.toDouble(),
                                        min: _constraints.colorCountMin.toDouble(),
                                        max: _constraints.colorCountMax.toDouble(),
                                        divisions: _constraints.colorCountMax - _constraints.colorCountMin,
                                        onChanged: createNew ? (final double newValue) {
                                          _maxColorsPerRampNotifier.value = newValue.round();
                                        } : null,
                                        textStyle: Theme.of(context).textTheme.bodyLarge!,
                                      );
                                    },
                                  );
                                },
                            ),
                          ),

                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          const Expanded(
                            flex: 7,
                            child: Text("Include Image as Reference Layer"),
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
                SizedBox(width: _options.padding * 2,),
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).primaryColorLight, width: _options.borderWidth),
                        borderRadius: BorderRadius.circular(_options.borderRadius / 2),
                      ),
                      child: ValueListenableBuilder<ui.Image?>(
                        valueListenable: _imageNotifier,
                        builder: (final BuildContext context, final ui.Image? img, final Widget? child) {
                          return Padding(
                            padding: EdgeInsets.all(_options.borderWidth),
                            child: RawImage(image: img, fit: BoxFit.contain, filterQuality: FilterQuality.none,),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),




            SizedBox(height: _options.padding * 2,),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Tooltip(
                    waitDuration: AppState.toolTipDuration,
                    message: "Close",
                    child: IconButton.outlined(
                      icon: FaIcon(
                        FontAwesomeIcons.xmark,
                        size: _options.iconSize,
                      ),
                      onPressed: () {
                        widget.dismiss();
                      },
                    ),
                  ),
                ),
                SizedBox(width: _options.padding),
                Expanded(
                  child: Tooltip(
                    waitDuration: AppState.toolTipDuration,
                    message: "Import",
                    child: ValueListenableBuilder<String?>(
                      valueListenable: _fileNameNotifier,
                      builder: (final BuildContext context, final String? fileNameValue, final Widget? child) {
                        return IconButton.outlined(
                          icon: FaIcon(
                            FontAwesomeIcons.check,
                            size: _options.iconSize,
                          ),
                          onPressed: _fileNameNotifier.value == null ? null : () {
                            _loadImage();
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
