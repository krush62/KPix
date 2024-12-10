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
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlay_entries.dart';


enum FileExportType
{
  png,
  aseprite,
  //photoshop,
  gimp,
  kpix
}

enum PaletteExportType
{
  kpal,
  png,
  aseprite,
  gimp,
  paintNet,
  adobe,
  jasc,
  corel,
  openOffice
}

class PaletteExportData
{
  final String extension;
  final String name;
  final String fileName;
  final String directory;
  const PaletteExportData({required this.name, required this.extension, this.fileName = "", this.directory = ""});
  factory PaletteExportData.fromWithConcreteData({required PaletteExportData other, required String fileName, required String directory})
  {
    return PaletteExportData(name: other.name, extension: other.extension, directory: directory, fileName: fileName);
  }
}

const Map<PaletteExportType, PaletteExportData> paletteExportTypeMap =
{
  PaletteExportType.png:PaletteExportData(name: "PNG", extension: "png"),
  PaletteExportType.aseprite:PaletteExportData(name: "ASEPRITE", extension: "aseprite"),
  PaletteExportType.gimp:PaletteExportData(name: "GIMP", extension: "gpl"),
  PaletteExportType.paintNet:PaletteExportData(name: "PAINT.NET", extension: "txt"),
  PaletteExportType.adobe:PaletteExportData(name: "ADOBE", extension: "ase"),
  PaletteExportType.jasc:PaletteExportData(name: "JASC", extension: "pal"),
  PaletteExportType.corel:PaletteExportData(name: "COREL", extension: "xml"),
  PaletteExportType.openOffice:PaletteExportData(name: "STAROFFICE", extension: "soc"),
  PaletteExportType.kpal:PaletteExportData(name: "KPAL", extension: FileHandler.fileExtensionKpal),
};

enum ExportSectionType
{
  project,
  palette
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

const Map<FileExportType, ExportData> fileExportTypeMap = {
  FileExportType.png : ExportData(name: "PNG", extension: "png", scalable: true),
  FileExportType.aseprite : ExportData(name: "ASEPRITE", extension: "aseprite", scalable: false),
  //ExportType.photoshop : ExportData(name: "PHOTOSHOP", extension: "psd", scalable: false),
  FileExportType.gimp : ExportData(name: "GIMP", extension: "xcf", scalable: false),
  FileExportType.kpix : ExportData(name: "KPIX", extension: FileHandler.fileExtensionKpix, scalable: false),
};




class ExportWidget extends StatefulWidget
{
  final Function() dismiss;
  final ExportDataFn acceptFile;
  final PaletteDataFn acceptPalette;

  const ExportWidget({
    super.key,
    required this.dismiss,
    required this.acceptFile,
    required this.acceptPalette
  });

  @override
  State<ExportWidget> createState() => _ExportWidgetState();
}

class _ExportWidgetState extends State<ExportWidget>
{
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<FileExportType> _fileExportType = ValueNotifier(FileExportType.png);
  final ValueNotifier<PaletteExportType> _paletteExportType = ValueNotifier(PaletteExportType.kpal);
  final ValueNotifier<int> _scalingIndex = ValueNotifier(0);
  final ValueNotifier<String> _fileName = ValueNotifier("");
  final AppState _appState = GetIt.I.get<AppState>();
  final ValueNotifier<FileNameStatus> _fileNameStatus = ValueNotifier(FileNameStatus.available);
  final ValueNotifier<ExportSectionType> _selectedSection = ValueNotifier(ExportSectionType.project);

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
    _hotkeyManager.exportFileNameTextFocus.requestFocus();
  }

  void _updateFileNameStatus()
  {
    final String extension = _selectedSection.value == ExportSectionType.project ? fileExportTypeMap[_fileExportType.value]!.extension : paletteExportTypeMap[_paletteExportType.value]!.extension;
    _fileNameStatus.value = FileHandler.checkFileName(fileName: _fileName.value, directory: _appState.exportDir, extension: extension);
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
          maxWidth: _options.maxWidth * 2,
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
              ValueListenableBuilder<ExportSectionType>(
                valueListenable: _selectedSection,
                builder: (final BuildContext context, final ExportSectionType section, final Widget? child) {
                  return SegmentedButton(
                    segments: const [
                      ButtonSegment(
                        value: ExportSectionType.project,
                        label: Tooltip(
                            message: "Image",
                            waitDuration: AppState.toolTipDuration,
                            child: Icon(
                                FontAwesomeIcons.image
                            )
                        )
                      ),
                      ButtonSegment(
                        value: ExportSectionType.palette,
                        label: Tooltip(
                            message: "Palette",
                            waitDuration: AppState.toolTipDuration,
                            child: Icon(
                                FontAwesomeIcons.palette
                            )
                        )
                      ),
                    ],
                    selected: <ExportSectionType>{section},
                    emptySelectionAllowed: false,
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                    onSelectionChanged: (final Set<ExportSectionType> exportSections) {_selectedSection.value = exportSections.first; _updateFileNameStatus();},
                  );
                },
              ),
              Padding(
                padding: EdgeInsets.only(top: _options.padding, bottom: _options.padding),
                child: Divider(
                  color: Theme.of(context).primaryColorLight,
                  thickness: _options.borderWidth,
                  height: _options.borderWidth,
                ),
              ),
              ValueListenableBuilder<ExportSectionType>(
                valueListenable: _selectedSection,
                builder: (final BuildContext context, final ExportSectionType section, final Widget? child) {
                  String title = "EXPORT";
                  if (section == ExportSectionType.project)
                  {
                    title += " PROJECT";
                  }
                  else if (section == ExportSectionType.palette)
                  {
                    title += " PALETTE";
                  }
                    return Column(
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleLarge),
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
                              child: Stack(
                                fit: StackFit.passthrough,
                                children: [
                                  Visibility(
                                    visible: section == ExportSectionType.project,
                                    child: ValueListenableBuilder<FileExportType>(
                                      valueListenable: _fileExportType,
                                      builder: (final BuildContext context, final FileExportType exportTypeEnum, final Widget? child) {
                                        return SegmentedButton<FileExportType>(
                                          selected: <FileExportType>{exportTypeEnum},
                                          multiSelectionEnabled: false,
                                          showSelectedIcon: false,
                                          onSelectionChanged: (final Set<FileExportType> types) {_fileExportType.value = types.first; _updateFileNameStatus();},
                                          segments: FileExportType.values.map((x) => ButtonSegment<FileExportType>(value: x, label: Text(fileExportTypeMap[x]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == x ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)))).toList(),
                                        );
                                      },
                                    ),
                                  ),
                                  Visibility(
                                    visible: section == ExportSectionType.palette,
                                    child: ValueListenableBuilder<PaletteExportType>(
                                      valueListenable: _paletteExportType,
                                      builder: (final BuildContext context, final PaletteExportType exportType, final Widget? child) {
                                        return SegmentedButton<PaletteExportType>(
                                          selected: <PaletteExportType>{exportType},
                                          multiSelectionEnabled: false,
                                          showSelectedIcon: false,
                                          onSelectionChanged: (final Set<PaletteExportType> types) {_paletteExportType.value = types.first; _updateFileNameStatus();},
                                          segments: PaletteExportType.values.map((x) => ButtonSegment<PaletteExportType>(value: x, label: Text(paletteExportTypeMap[x]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportType == x ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)))).toList(),

                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ]
                        ),
                        Opacity(
                          opacity: section == ExportSectionType.project ? 1.0 : 0.0,
                          child: Row(
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
                                child: ValueListenableBuilder<FileExportType>(
                                  valueListenable: _fileExportType,
                                  builder: (final BuildContext context1, final FileExportType type, final Widget? child1) {
                                    return ValueListenableBuilder<int>(
                                      valueListenable: _scalingIndex,
                                      builder: (final BuildContext context2, final int scalingIndexVal, final Widget? child2) {
                                        return KPixSlider(
                                          value: fileExportTypeMap[type]!.scalable ? scalingIndexVal.toDouble() : 0,
                                          min: 0,
                                          max: exportScalingValues.length.toDouble() - 1,
                                          divisions: exportScalingValues.length,
                                          label: "${exportScalingValues[scalingIndexVal]}:1",
                                          onChanged: fileExportTypeMap[type]!.scalable ? (final double newVal){_scalingIndex.value = newVal.round();} : null,
                                          textStyle: Theme.of(context).textTheme.bodyLarge!,
                                        );
                                      },
                                    );
                                  },
                                )
                              ),
                              Expanded(
                                flex: 2,
                                child: ValueListenableBuilder<FileExportType>(
                                  valueListenable: _fileExportType,
                                  builder: (final BuildContext context1, final FileExportType type, final Widget? child) {
                                    return ValueListenableBuilder<int>(
                                      valueListenable: _scalingIndex,
                                      builder: (final BuildContext context2, final int scalingIndexVal, final Widget? child2) {
                                        return Text( fileExportTypeMap[type]!.scalable ?
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
                        ),
                        Row(
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
                                child: ValueListenableBuilder<PaletteExportType>(
                                  valueListenable: _paletteExportType,
                                  builder: (final BuildContext context, final PaletteExportType paletteExportType, final Widget? child) {
                                  return ValueListenableBuilder<FileExportType>(
                                    valueListenable: _fileExportType,
                                    builder: (final BuildContext context, final FileExportType fileExportType, final Widget? child) {
                                      return (section == ExportSectionType.project) ? Text(".${fileExportTypeMap[fileExportType]!.extension}") : Text(".${paletteExportTypeMap[paletteExportType]!.extension}");
                                    },
                                  );
                                  }
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
                      ],
                    );
                },
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
                      child: ValueListenableBuilder<ExportSectionType>(
                        valueListenable: _selectedSection,
                        builder: (final BuildContext context, final ExportSectionType selSection, final Widget? child) {
                          return ValueListenableBuilder<FileNameStatus>(
                            valueListenable: _fileNameStatus,
                            builder: (final BuildContext context, final FileNameStatus status, final Widget? child) {
                              return Tooltip(
                                waitDuration: AppState.toolTipDuration,
                                message: "Export File",
                                child: IconButton.outlined(
                                  icon: FaIcon(
                                    FontAwesomeIcons.check,
                                    size: _options.iconSize,
                                  ),
                                  onPressed: (status == FileNameStatus.available || status == FileNameStatus.overwrite) ?
                                    () {
                                      if (selSection == ExportSectionType.project)
                                      {
                                        widget.acceptFile(exportData: ExportData.fromWithConcreteData(other: fileExportTypeMap[_fileExportType.value]!, scaling: exportScalingValues[_scalingIndex.value], fileName: _fileName.value, directory: _appState.exportDir), exportType: _fileExportType.value);
                                      }
                                      else if (selSection == ExportSectionType.palette)
                                      {
                                        widget.acceptPalette(saveData: PaletteExportData.fromWithConcreteData(other: paletteExportTypeMap[_paletteExportType.value]!, fileName: _fileName.value, directory: _appState.exportDir), paletteType: _paletteExportType.value);
                                      }
                                    } : null,
                                ),
                              );
                            },
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