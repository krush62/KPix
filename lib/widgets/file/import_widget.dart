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

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';


class ImportData
{
  final int maxClusters;
  final int maxRamps;
  final int maxColors;
  final String filePath;
  final Uint8List? imageBytes;
  final bool includeReference;
  ImportData({required this.maxRamps, required this.maxColors, required this.filePath, required this.includeReference, required this.maxClusters, required this.imageBytes});
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
  final ValueNotifier<String?> _fileNameNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _includeReferenceNotifier = ValueNotifier(false);
  Uint8List? _imageData;

  @override
  void initState()
  {
    super.initState();
    _maxRampsNotifier = ValueNotifier(_constraints.rampCountDefault);
    _maxColorsPerRampNotifier = ValueNotifier(_constraints.colorCountDefault);
  }


  void _chooseImagePressed()
  {
    FileHandler.getPathAndDataForImage().then((final (String?, Uint8List?) loadData) {
      _fileNameNotifier.value = loadData.$1;
      _imageData = loadData.$2;
    });
  }

  void _loadImage()
  {
    if (_fileNameNotifier.value != null) //should never happen
    {
      final ImportData data = ImportData(filePath: _fileNameNotifier.value!, includeReference: _includeReferenceNotifier.value, maxColors: _maxColorsPerRampNotifier.value, maxRamps: _maxRampsNotifier.value, maxClusters: _constraints.maxClusters, imageBytes: _imageData);
      widget.import(importData: data);
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Material(
      elevation: _options.elevation,
      shadowColor: Theme.of(context).primaryColorDark,
      borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
      child: Container(
        constraints: BoxConstraints(
          minHeight: _options.minHeight,
          minWidth: _options.minWidth,
          maxHeight: _options.maxHeight,
          maxWidth: _options.maxWidth,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          border: Border.all(
            color: Theme.of(context).primaryColorLight,
            width: _options.borderWidth,
          ),
          borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
        ),
        child: Padding(
          padding: EdgeInsets.all(_options.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("IMPORT IMAGE", style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: _options.padding),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text("File")
                  ),
                  Expanded(
                    flex: 6,
                    child: ValueListenableBuilder<String?>(
                      valueListenable: _fileNameNotifier,
                      builder: (final BuildContext context, final String? path, final Widget? child) {
                        return Text(
                          path == null ? "<NO FILE SELECTED>" : Helper.extractFilenameFromPath(path: path),
                          textAlign: TextAlign.center,
                        );
                      },
                    )
                  ),
                  Expanded(
                    flex: 1,
                    child: Tooltip(
                      message: "Choose Image",
                      waitDuration: AppState.toolTipDuration,
                      child: IconButton.outlined(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(_options.padding),
                        onPressed: _chooseImagePressed,
                        icon: FaIcon(
                          FontAwesomeIcons.folderOpen,
                          size: _options.iconSize / 2
                        ),
                        color: Theme.of(context).primaryColorLight,
                        style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Theme.of(context).primaryColor
                        ),
                      ),
                    )
                  )
                ]
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text("Max Color Ramps")
                  ),
                  Expanded(
                    flex: 6,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _maxRampsNotifier,
                      builder: (final BuildContext context, final int maxRampValue, final Widget? child) {
                        return Slider(
                          value: maxRampValue.toDouble(),
                          min: _constraints.rampCountMin.toDouble(),
                          max: _constraints.maxClusters.toDouble(),
                          divisions: _constraints.maxClusters - _constraints.rampCountMin,
                          label: maxRampValue.toString(),
                          onChanged: (final double newValue) {
                            _maxRampsNotifier.value = newValue.round();
                          },
                        );
                      },
                    )
                  ),
                  Expanded(
                    flex: 1,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _maxRampsNotifier,
                      builder: (final BuildContext context, final int maxRampValue, final Widget? child) {
                        return Text("$maxRampValue", textAlign: TextAlign.center);
                      },
                    )
                  ),
                ]
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text("Max Colors per Ramp")
                  ),
                  Expanded(
                    flex: 6,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _maxColorsPerRampNotifier,
                      builder: (final BuildContext context, final int maxColorsValue, final Widget? child) {
                        return Slider(
                          value: maxColorsValue.toDouble(),
                          min: _constraints.colorCountMin.toDouble(),
                          max: _constraints.colorCountMax.toDouble(),
                          divisions: _constraints.colorCountMax - _constraints.colorCountMin,
                          label: maxColorsValue.toString(),
                          onChanged: (final double newValue) {
                            _maxColorsPerRampNotifier.value = newValue.round();
                          },
                        );
                      },
                    )
                  ),
                  Expanded(
                    flex: 1,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _maxColorsPerRampNotifier,
                      builder: (final BuildContext context, final int maxColorsValue, final Widget? child) {
                        return Text("$maxColorsValue", textAlign: TextAlign.center);
                      },
                    )
                  ),
                ]
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 8,
                    child: Text("Include Image as Reference Layer")
                  ),
                  Expanded(
                    flex: 1,
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
                    )
                  )
                ]
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.all(_options.padding),
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
                    )
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.all(_options.padding),
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
                    )
                  ),
                ]
              ),
            ],
          )
        )
      )
    );
  }
}
