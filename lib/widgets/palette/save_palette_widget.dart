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
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';

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
  final AppState _appState = GetIt.I.get<AppState>();
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<FileNameStatus> _fileNameStatus = ValueNotifier(FileNameStatus.forbidden);
  final ValueNotifier<String> _fileName = ValueNotifier("");

  void _updateFileNameStatus()
  {
    _fileNameStatus.value = FileHandler.checkFileName(fileName: _fileName.value, directory: _appState.internalDir, extension: FileHandler.fileExtensionKpal);
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
                  Text("SAVE PALETTE", style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: _options.padding),
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
                            builder: (final BuildContext context, final String? filePath, final Widget? child) {
                              final TextEditingController controller = TextEditingController(text: filePath);
                              controller.selection = TextSelection.collapsed(offset: controller.text.length);
                              return TextField(
                                textAlign: TextAlign.end,
                                maxLength: 16,
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
                      const Expanded(
                        flex: 1,
                        child: Text(".${FileHandler.fileExtensionKpal}"),
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
                                  widget.accept(saveData: PaletteExportData(extension: FileHandler.fileExtensionKpal, directory: _appState.internalDir, fileName: _fileName.value, name: "KPAL"), paletteType: PaletteExportType.kpal);
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