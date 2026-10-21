/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/format_helper.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';

abstract final class ShaderExportWidgetOptions
{
  static const double outsidePadding = 16.0;
  static const double padding = 8.0;
  static const double dividerThickness = 2.0;
  static const double borderRadius = 8.0;
  static const double maxWidth = 1600.0;
  static const double maxHeight = 1000.0;
  static const int smokeOpacity = 128;
  static const int renderIntervalMs = 100;
  static const double iconSize = 32.0;
}

class ShaderExportWidget extends StatefulWidget
{
  final Function() dismiss;
  const ShaderExportWidget({super.key, required this.dismiss});

  @override
  State<ShaderExportWidget> createState() => ShaderExportWidgetState();
}

class ShaderExportWidgetState extends State<ShaderExportWidget>
{
  final String _extension = ImageExportData.exportTypeMap[ImageExportType.png]?.extension ?? "png";
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final ValueNotifier<String> _fileName = ValueNotifier<String>("");
  final ValueNotifier<FileNameStatus> _fileNameStatus = ValueNotifier<FileNameStatus>(FileNameStatus.available);
  final ValueNotifier<int> _scalingIndex = ValueNotifier<int>(0);
  final CanvasState _canvasState = GetIt.I.get<CanvasState>();

  @override
  void initState()
  {
    super.initState();


    _hotkeyManager.getFocusNode(id: FocusNodeEntry.shaderExportFileNameTextFocus).requestFocus();
  }

  void _changeDirectoryPressed()
  {
    getDirectory(startDir: GetIt.I.get<AppPaths>().exportDir, dialogTitle: AppLocalizations.of(context)!.chooseDirectory).then((final String? chosenDir) {_handleChosenDirectory(chosenDir: chosenDir);});
  }

  void _handleChosenDirectory({required final String? chosenDir})
  {
    if (chosenDir != null)
    {
      GetIt.I.get<AppPaths>().exportDir = chosenDir;
      _updateFileNameStatus();
    }
  }

  void _updateFileNameStatus()
  {
    _fileNameStatus.value = checkFileName(fileName: _fileName.value, directory: GetIt.I.get<AppPaths>().exportDir, extension: _extension);
  }

  void accept()
  {
    widget.dismiss();
  }

  void cancel()
  {
    widget.dismiss();
  }

  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Center(
      child: KPixAnimationWidget(
        constraints: const BoxConstraints(
          maxWidth: ShaderExportWidgetOptions.maxWidth,
          maxHeight: ShaderExportWidgetOptions.maxHeight,
        ),
        child: Column (
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.exportShaderImage,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            Divider(
              color: Theme.of(context).primaryColorLight,
              thickness: ShaderExportWidgetOptions.dividerThickness,
              height: ShaderExportWidgetOptions.dividerThickness + (ShaderExportWidgetOptions.padding * 2),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SegmentedButton(
                          segments: <ButtonSegment<int>>[
                            ButtonSegment(value: 0, label: Text("Shader0")),
                            ButtonSegment(value: 1, label: Text("Shader1")),
                            ButtonSegment(value: 2, label: Text("Shader2")),
                            ButtonSegment(value: 3, label: Text("Shader3")),
                            ButtonSegment(value: 4, label: Text("Shader4")),
                            ButtonSegment(value: 5, label: Text("Shader5")),
                          ],
                          selected: {0},
                          showSelectedIcon: false,
                        ),
                        Expanded(child: Placeholder()),
                        // DIRECTORY
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Expanded(
                              child: Text(l10n.directory, style: Theme.of(context).textTheme.titleMedium),
                            ),
                            Expanded(
                              flex: 4,
                              child: ValueListenableBuilder<String>(
                                valueListenable: GetIt.I.get<AppPaths>().exportDirNotifier,
                                builder: (final BuildContext context, final String expDir, final Widget? child) {
                                  return Text(expDir, textAlign: TextAlign.center);
                                },
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: IconButton.outlined(
                                tooltip: l10n.changeDirectory,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(ShaderExportWidgetOptions.padding),
                                onPressed: _changeDirectoryPressed,
                                icon: const Icon(
                                  TablerIcons.folder,
                                  size: ShaderExportWidgetOptions.iconSize / 2,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // FILE NAME
                        Row(
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
                                    focusNode: _hotkeyManager.getFocusNode(id: FocusNodeEntry.shaderExportFileNameTextFocus),
                                    controller: controller,
                                    onChanged: (final String value) {
                                      _fileName.value = value;
                                      _updateFileNameStatus();
                                    },
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: Text(".$_extension"),
                            ),
                            Expanded(
                              child: ValueListenableBuilder<FileNameStatus>(
                                valueListenable: _fileNameStatus,
                                builder: (final BuildContext context, final FileNameStatus status, final Widget? child) {
                                  return Tooltip(
                                    message: status.label(AppLocalizations.of(context)!),
                                    child: Icon(
                                      status.icon,
                                      size: ShaderExportWidgetOptions.iconSize / 2,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(
                    color: Theme.of(context).primaryColorLight,
                    thickness: ShaderExportWidgetOptions.dividerThickness,
                    width: ShaderExportWidgetOptions.dividerThickness + (ShaderExportWidgetOptions.padding * 2),
                  ),

                  Expanded(
                    child: Column(
                      children: [
                        const Expanded(child: Placeholder()),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Expanded(
                              child: Text(l10n.scaling, style: Theme.of(context).textTheme.titleMedium),
                            ),
                            Expanded(
                              flex: 4,
                              child: ValueListenableBuilder<int>(
                                valueListenable: _scalingIndex,
                                builder: (final BuildContext context2, final int scalingIndexVal, final Widget? child2) {
                                  return KPixSlider(
                                    value: scalingIndexVal.toDouble(),
                                    max: exportShadingScalingValues.length.toDouble() - 1,
                                    //divisions: exportScalingValues.length,
                                    label: "${exportShadingScalingValues[scalingIndexVal]}:1",
                                    onChanged: (final double newVal){_scalingIndex.value = newVal.round();},
                                    textStyle: Theme.of(context).textTheme.bodyLarge!,
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: ValueListenableBuilder<int>(
                                valueListenable: _scalingIndex,
                                builder: (final BuildContext context2, final int scalingIndexVal, final Widget? child2) {
                                  return Text(formatDimension(width: _canvasState.canvasSize.x *  exportScalingValues[scalingIndexVal], height: _canvasState.canvasSize.y *  exportScalingValues[scalingIndexVal]),
                                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: Theme.of(context).primaryColorLight,
              thickness: ShaderExportWidgetOptions.dividerThickness,
              height: ShaderExportWidgetOptions.dividerThickness + (ShaderExportWidgetOptions.padding * 2),
            ),

            // BUTTON ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(ShaderExportWidgetOptions.padding),
                    child: IconButton.outlined(
                      tooltip: l10n.cancel,
                      icon: const Icon(TablerIcons.x),
                      onPressed: cancel,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(ShaderExportWidgetOptions.padding),
                    child: IconButton.outlined(
                      tooltip: l10n.apply,
                      icon: const Icon(TablerIcons.check),
                      onPressed: accept,
                    ),
                  ),
                ),
              ],
            ),
          ],
        )
      ),
    );
  }
}
