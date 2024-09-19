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

enum PaletteType
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

class PaletteSaveData
{
  final String extension;
  final String name;
  final String fileName;
  final String directory;
  const PaletteSaveData({required this.name, required this.extension, this.fileName = "", this.directory = ""});
  factory PaletteSaveData.fromWithConcreteData({required PaletteSaveData other, required String fileName, required String directory})
  {
    return PaletteSaveData(name: other.name, extension: other.extension, directory: directory, fileName: fileName);
  }
}

const Map<PaletteType, PaletteSaveData> paletteExportTypeMap =
{
  PaletteType.kpal:PaletteSaveData(name: "KPAL", extension: FileHandler.fileExtensionKpal),
  PaletteType.png:PaletteSaveData(name: "PNG", extension: "png"),
  PaletteType.aseprite:PaletteSaveData(name: "ASEPRITE", extension: "aseprite"),
  PaletteType.gimp:PaletteSaveData(name: "GIMP", extension: "gpl"),
  PaletteType.paintNet:PaletteSaveData(name: "PAINT.NET", extension: "txt"),
  PaletteType.adobe:PaletteSaveData(name: "ADOBE", extension: "ase"),
  PaletteType.jasc:PaletteSaveData(name: "JASC", extension: "pal"),
  PaletteType.corel:PaletteSaveData(name: "COREL", extension: "xml"),
  PaletteType.openOffice:PaletteSaveData(name: "STAROFFICE", extension: "soc")
};

class SavePaletteWidget extends StatefulWidget
{
  final Function() dismiss;
  final PaletteDataFn accept;
  const SavePaletteWidget({super.key, required this.dismiss, required this.accept});

  @override
  State<SavePaletteWidget> createState() => _SavePaletteWidgetState();
}

class _SavePaletteWidgetState extends State<SavePaletteWidget>
{
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<PaletteType> _exportType = ValueNotifier(PaletteType.kpal);
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
    _fileNameStatus.value = FileHandler.checkFileName(fileName: _fileName.value, directory: _appState.exportDir, extension: paletteExportTypeMap[_exportType.value]!.extension);
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
                  Text("SAVE PALETTE", style: Theme.of(context).textTheme.titleLarge),
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
                            child: ValueListenableBuilder<PaletteType>(
                              valueListenable: _exportType,
                              builder: (final BuildContext context, final PaletteType exportType, final Widget? child) {
                                return SegmentedButton<PaletteType>(
                                  selected: <PaletteType>{exportType},
                                  multiSelectionEnabled: false,
                                  showSelectedIcon: false,
                                  onSelectionChanged: (final Set<PaletteType> types) {_exportType.value = types.first; _updateFileNameStatus();},
                                  segments: PaletteType.values.map((x) => ButtonSegment<PaletteType>(value: x, label: Text(paletteExportTypeMap[x]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportType == x ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)))).toList(),

                                );
                              },
                            )
                        ),
                      ]
                  ),
                  SizedBox(height: _options.padding),
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
                                  focusNode: _hotkeyManager.savePaletteNameTextFocus,
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
                          child: ValueListenableBuilder<PaletteType>(
                            valueListenable: _exportType,
                            builder: (final BuildContext context, final PaletteType exportType, final Widget? child) {
                              return Text(".${paletteExportTypeMap[exportType]!.extension}");
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
                                      widget.accept(saveData: PaletteSaveData.fromWithConcreteData(other: paletteExportTypeMap[_exportType.value]!, fileName: _fileName.value, directory: _appState.exportDir), paletteType: _exportType.value);
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
