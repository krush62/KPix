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
import 'package:kpix/widgets/overlay_entries.dart';

class SaveAsWidget extends StatefulWidget
{
  final Function() dismiss;
  final SaveFileFn accept;
  final Function()? callback;
  const SaveAsWidget({super.key, required this.accept, required this.dismiss, required this.callback});

  @override
  State<SaveAsWidget> createState() => _SaveAsWidgetState();
}

class _SaveAsWidgetState extends State<SaveAsWidget>
{
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<String> _fileName = ValueNotifier("");
  final AppState _appState = GetIt.I.get<AppState>();
  final ValueNotifier<FileNameStatus> _fileNameStatus = ValueNotifier(FileNameStatus.available);

  void _changeDirectoryPressed()
  {
    FileHandler.getDirectory(startDir: _appState.saveDir).then((final String? chosenDir) {_handleChosenDirectory(chosenDir: chosenDir);});
  }

  void _handleChosenDirectory({required final String? chosenDir})
  {
    if (chosenDir != null)
    {
      _appState.saveDir = chosenDir;
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
    _fileNameStatus.value = FileHandler.checkFileName(fileName: _fileName.value, directory: _appState.saveDir, extension: FileHandler.fileExtensionKpix);
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
              Text("SAVE PROJECT AS", style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: _options.padding),
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
                      valueListenable: _appState.saveDirNotifier,
                      builder: (final BuildContext context, final String saveDir, Widget? child) {
                        return Text(saveDir, textAlign: TextAlign.center);
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
                          focusNode: _hotkeyManager.saveAsFileNameTextFocus,
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
                    child: Text(".${FileHandler.fileExtensionKpix}"),
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
                                widget.accept(fileName: _fileName.value, callback: widget.callback);
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
