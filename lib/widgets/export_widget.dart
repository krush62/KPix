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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/overlay_entries.dart';


enum ExportType
{
  png,
  aseprite,
  //photoshop,
  gimp
}

const List<int> exportScalingValues = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

class ExportData
{
  final String extension;
  final String name;
  final int scaling;
  final String fileName;
  final String directory;
  final bool scalable;
  const ExportData({required this.name, required this.extension, required this.scalable, this.scaling = 1, this.fileName = "", this.directory = ""});
  factory ExportData.fromWithConcreteData({required ExportData other, required int scaling, required String fileName, required String directory})
  {
    return ExportData(name: other.name, extension: other.extension, scalable: other.scalable, scaling: scaling, directory: directory, fileName: fileName);
  }
}

const Map<ExportType, ExportData> exportTypeMap = {
  ExportType.png : ExportData(name: "PNG", extension: "png", scalable: true),
  ExportType.aseprite : ExportData(name: "ASEPRITE", extension: "aseprite", scalable: false),
  //ExportType.photoshop : ExportData(name: "PHOTOSHOP", extension: "psd", scalable: false),
  ExportType.gimp : ExportData(name: "GIMP", extension: "xcf", scalable: false)
};




class ExportWidget extends StatefulWidget
{
  final Function() dismiss;
  final ExportDataFn accept;

  const ExportWidget({
    super.key,
    required this.dismiss,
    required this.accept,
  });

  @override
  State<ExportWidget> createState() => _ExportWidgetState();
}

class _ExportWidgetState extends State<ExportWidget>
{
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<ExportType> _exportType = ValueNotifier(ExportType.png);
  final ValueNotifier<int> _scalingIndex = ValueNotifier(0);
  final ValueNotifier<String> _fileName = ValueNotifier("");
  final AppState _appState = GetIt.I.get<AppState>();
  final ValueNotifier<FileNameStatus> _fileNameStatus = ValueNotifier(FileNameStatus.available);

    void _changeDirectoryPressed()
    {
      FileHandler.getDirectory(startDir: _appState.exportDir).then((final String? chosenDir) {_handleChosenDirectory(chosenDir: chosenDir);});
    }

    void _handleChosenDirectory({required final String? chosenDir})
    {
      if (chosenDir != null)
      {
        _appState.exportDir = chosenDir;
        _updateFileNameStatus();
      }
    }

  @override
  void initState()
  {
    super.initState();
    _fileName.value = _appState.projectName.value == null ? "" : _appState.projectName.value!;
    _updateFileNameStatus();
  }

  void _updateFileNameStatus()
  {
    _fileNameStatus.value = FileHandler.checkFileName(fileName: _fileName.value, directory: _appState.exportDir, extension: exportTypeMap[_exportType.value]!.extension);
  }

  @override
  Widget build(final BuildContext context) {
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
              Text("EXPORT PROJECT", style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: _options.padding),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                      flex: 1,
                      child: Text("Format", style: Theme.of(context).textTheme.titleMedium)
                  ),
                  Expanded(
                    flex: 6,
                    child: ValueListenableBuilder<ExportType>(
                      valueListenable: _exportType,
                      builder: (final BuildContext context, final ExportType exportTypeEnum, final Widget? child) {
                        return SegmentedButton<ExportType>(
                          selected: <ExportType>{exportTypeEnum},
                          multiSelectionEnabled: false,
                          showSelectedIcon: false,
                          onSelectionChanged: (final Set<ExportType> types) {_exportType.value = types.first;},
                          segments: ExportType.values.map((x) => ButtonSegment<ExportType>(value: x, label: Text(exportTypeMap[x]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == x ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)))).toList(),
                        );
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
                    flex: 1,
                    child: Text("Scaling", style: Theme.of(context).textTheme.titleMedium)
                  ),
                  Expanded(
                    flex: 4,
                    child: ValueListenableBuilder<ExportType>(
                      valueListenable: _exportType,
                      builder: (final BuildContext context1, final ExportType type, final Widget? child1) {
                        return ValueListenableBuilder<int>(
                          valueListenable: _scalingIndex,
                          builder: (final BuildContext context2, final int scalingIndexVal, final Widget? child2) {
                            return Slider(
                              value: exportTypeMap[type]!.scalable ? scalingIndexVal.toDouble() : 0,
                              min: 0,
                              max: exportScalingValues.length.toDouble() - 1,
                              divisions: exportScalingValues.length,
                              label: exportScalingValues[scalingIndexVal].toString(),
                              onChanged: exportTypeMap[type]!.scalable ? (final double newVal){_scalingIndex.value = newVal.round();} : null,
                            );
                          },
                        );
                      },
                    )
                  ),
                  Expanded(
                    flex: 2,
                    child: ValueListenableBuilder<ExportType>(
                      valueListenable: _exportType,
                      builder: (final BuildContext context1, final ExportType type, final Widget? child) {
                        return ValueListenableBuilder<int>(
                          valueListenable: _scalingIndex,
                          builder: (final BuildContext context2, final int scalingIndexVal, final Widget? child2) {
                            return Text( exportTypeMap[type]!.scalable ?
                              "${_appState.canvasSize.x *  exportScalingValues[scalingIndexVal]} x ${_appState.canvasSize.y *  exportScalingValues[scalingIndexVal]}" : "${_appState.canvasSize.x} x ${_appState.canvasSize.y}",
                              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium
                            );
                          },
                        );
                      },

                    )
                  ),
                ]
              ),
              Visibility(
                visible: !kIsWeb,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text("Directory", style: Theme.of(context).textTheme.titleMedium)
                    ),
                    Expanded(
                      flex: 4,
                      child: ValueListenableBuilder<String>(
                        valueListenable: _appState.exportDirNotifier,
                        builder: (final BuildContext context, final String expDir, Widget? child) {
                          return Text(expDir, textAlign: TextAlign.center);
                        },
                      )
                    ),
                    Expanded(
                      flex: 2,
                      child: Tooltip(
                        message: "Change Directory",
                        waitDuration: AppState.toolTipDuration,
                        child: IconButton.outlined(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.all(_options.padding),
                          onPressed: _changeDirectoryPressed,
                          icon: FaIcon(
                            FontAwesomeIcons.file,
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
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                      flex: 1,
                      child: Text("File Name", style: Theme.of(context).textTheme.titleMedium)
                  ),
                  Expanded(
                      flex: 3,
                      child: ValueListenableBuilder<String?>(
                        valueListenable: _fileName,
                        builder: (final BuildContext context, final String? filePath, Widget? child) {
                          final TextEditingController controller = TextEditingController(text: filePath);
                          controller.selection = TextSelection.collapsed(offset: controller.text.length);
                          return TextField(
                            textAlign: TextAlign.end,
                            focusNode: _hotkeyManager.exportFileNameTextFocus,
                            controller: controller,
                            onChanged: (final String value) {
                              _fileName.value = value;
                              _updateFileNameStatus();
                            },
                          );
                        },
                      )
                  ),
                  Expanded(
                    flex: 1,
                    child: ValueListenableBuilder<ExportType>(
                      valueListenable: _exportType,
                      builder: (final BuildContext context, final ExportType exportType, final Widget? child) {
                        return Text(".${exportTypeMap[exportType]!.extension}");
                      },

                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ValueListenableBuilder<FileNameStatus>(
                      valueListenable: _fileNameStatus,
                      builder: (final BuildContext context, final FileNameStatus status, final Widget? child) {
                        return Tooltip(
                          message: fileNameStatusTextMap[status],
                          waitDuration: AppState.toolTipDuration,
                          child: FaIcon(
                            fileNameStatusIconMap[status],
                            size: _options.iconSize / 2,
                          ),
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
                      child: IconButton.outlined(
                        icon: FaIcon(
                          FontAwesomeIcons.xmark,
                          size: _options.iconSize,
                        ),
                        onPressed: () {
                          widget.dismiss();
                        },
                      ),
                    )
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.all(_options.padding),
                      child: ValueListenableBuilder<FileNameStatus>(
                        valueListenable: _fileNameStatus,
                        builder: (final BuildContext context, final FileNameStatus status, final Widget? child) {
                          return IconButton.outlined(
                            icon: FaIcon(
                              FontAwesomeIcons.check,
                              size: _options.iconSize,
                            ),
                            onPressed: (status == FileNameStatus.available || status == FileNameStatus.overwrite) ?
                                () {
                                  widget.accept(exportData: ExportData.fromWithConcreteData(other: exportTypeMap[_exportType.value]!, scaling: exportScalingValues[_scalingIndex.value], fileName: _fileName.value, directory: _appState.exportDir), exportType: _exportType.value);
                                } : null,
                          );
                        },
                      ),
                    )
                  ),
                ]
              ),
            ],
          ),
        )
      )
    );
  }

}