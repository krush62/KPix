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
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/widgets/callback_typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:path/path.dart' as p;

class SavePaletteWidget extends StatefulWidget
{
  final Function() dismiss;
  final PaletteExportDataFn accept;
  
  const SavePaletteWidget({super.key, required this.dismiss, required this.accept});

  @override
  State<SavePaletteWidget> createState() => SavePaletteWidgetState();
}

class SavePaletteWidgetState extends State<SavePaletteWidget>
{
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final ValueNotifier<FileNameStatus> _fileNameStatus = ValueNotifier<FileNameStatus>(FileNameStatus.forbidden);
  final ValueNotifier<String> _fileName = ValueNotifier<String>("");

  void _updateFileNameStatus()
  {
    _fileNameStatus.value = checkFileName(fileName: _fileName.value, directory: p.join(GetIt.I.get<AppPaths>().internalDir, palettesSubDirName), extension: fileExtensionKpal);
  }

  /// Does nothing for an unusable name; an existing palette is only replaced
  /// with [allowOverwrite].
  void accept({final bool allowOverwrite = true})
  {
    final FileNameStatus status = _fileNameStatus.value;
    if (status == FileNameStatus.available || (allowOverwrite && status == FileNameStatus.overwrite))
    {
      widget.accept(saveData: PaletteExportData(extension: fileExtensionKpal, directory: p.join(GetIt.I.get<AppPaths>().internalDir, palettesSubDirName), fileName: _fileName.value, name: "KPAL"), paletteType: PaletteExportType.kpal);
    }
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
          Text(l10n.savePalette.toUpperCase(), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
          Padding(
            padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                    child: Text(l10n.fileName, style: Theme.of(context).textTheme.titleMedium),
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
                          focusNode: _hotkeyManager.getFocusNode(id: FocusNodeEntry.savePaletteNameTextFocus),
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
                  child: Text(".$fileExtensionKpal"),
                ),
                Expanded(
                  child: ValueListenableBuilder<FileNameStatus>(
                    valueListenable: _fileNameStatus,
                    builder: (final BuildContext context, final FileNameStatus status, final Widget? child) {
                      return Tooltip(
                        message: status.label(AppLocalizations.of(context)!),
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
                    tooltip: l10n.close,
                    icon: const Icon(TablerIcons.x),
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
                        tooltip: l10n.savePalette,
                        icon: const Icon(TablerIcons.check),
                        onPressed: (status == FileNameStatus.available || status == FileNameStatus.overwrite) ? accept : null,
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
