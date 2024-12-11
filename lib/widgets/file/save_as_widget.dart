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
import 'package:path/path.dart' as p;

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
  final ValueNotifier<String> _fileName = ValueNotifier<String>("");
  final AppState _appState = GetIt.I.get<AppState>();
  final ValueNotifier<FileNameStatus> _fileNameStatus = ValueNotifier<FileNameStatus>(FileNameStatus.available);


  @override
  void initState()
  {
    super.initState();
    _fileName.value = _appState.projectName.value == null ? "" : _appState.projectName.value!;
    _updateFileNameStatus();
    _hotkeyManager.saveAsFileNameTextFocus.requestFocus();
  }

  void _updateFileNameStatus()
  {
    _fileNameStatus.value = checkFileName(fileName: _fileName.value, directory: p.join(_appState.internalDir, projectsSubDirName), extension: fileExtensionKpix, allowRecoverFile: false);
  }

  @override
  Widget build(final BuildContext context)
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
            children: <Widget>[
              Text("SAVE PROJECT AS", style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: _options.padding),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    child: Text("File Name", style: Theme.of(context).textTheme.titleMedium),
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
                          focusNode: _hotkeyManager.saveAsFileNameTextFocus,
                          controller: controller,
                          onChanged: (final String value) {
                            _fileName.value = value;
                            _updateFileNameStatus();
                          },
                        );
                      },
                    ),
                  ),
                  const Expanded(
                    child: Text(".$fileExtensionKpix"),
                  ),
                  Expanded(
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
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
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
                      ),
                    ),
                    Expanded(
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ),
    );
  }
}
