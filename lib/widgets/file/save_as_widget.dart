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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/widgets/callback_typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// A simple widget for entering a project name for saving.
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
  final ValueNotifier<String> _fileName = ValueNotifier<String>("");
  final ProjectSession _projectSession = GetIt.I.get<ProjectSession>();
  final ValueNotifier<FileNameStatus> _fileNameStatus = ValueNotifier<FileNameStatus>(FileNameStatus.available);


  @override
  void initState()
  {
    super.initState();
    _fileName.value = _projectSession.projectName.value == null ? "" : _projectSession.projectName.value!;
    _updateFileNameStatus();
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.saveAsFileNameTextFocus).requestFocus();
  }

  void _updateFileNameStatus()
  {
    _fileNameStatus.value = checkFileName(fileName: _fileName.value, directory: GetIt.I.get<AppPaths>().projectsDir, extension: fileExtensionKpix, allowRecoverFile: false);
  }

  @override
  Widget build(final BuildContext context)
  {
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
          Text("SAVE PROJECT AS", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
          Padding(
            padding:  const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
            child: Row(
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
                        focusNode: _hotkeyManager.getFocusNode(id: FocusNodeEntry.saveAsFileNameTextFocus),
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
                        message: status.label,
                        waitDuration: toolTipDuration,
                        child: Icon(
                          status.icon,
                          size: OverlayEntryAlertDialogOptions.iconSize / 2,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                    child: IconButton.outlined(
                      icon: const Icon(
                        TablerIcons.x,
                      ),
                      onPressed: () {
                        widget.dismiss();
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                    child: ValueListenableBuilder<FileNameStatus>(
                      valueListenable: _fileNameStatus,
                      builder: (final BuildContext context, final FileNameStatus status, final Widget? child) {
                        return IconButton.outlined(
                          icon: const Icon(
                            TablerIcons.check,
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
    );
  }
}
