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

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/layer_image.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/export_shader.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/file_name_check.dart';
import 'package:kpix/util/file_pickers.dart';
import 'package:kpix/util/helpers/format_helper.dart';
import 'package:kpix/widgets/callback_typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/controls/kpix_text_field.dart';
import 'package:kpix/widgets/file/shader_preview_widget.dart';

abstract final class ShaderExportWidgetOptions
{
  static const double outsidePadding = 16.0;
  static const double padding = 8.0;
  static const double dividerThickness = 2.0;
  static const double borderRadius = 8.0;
  static const double maxWidth = 1600.0;
  static const double maxHeight = 1000.0;
  static const int smokeOpacity = 128;
  static const double iconSize = 32.0;
  static const int rowLabelFlex = 2;
  static const int rowControlFlex = 4;
  static const double resetButtonSize = 32.0;
}

class ShaderExportWidget extends StatefulWidget
{
  final Function() dismiss;
  final ShaderExportDataFn accept;
  const ShaderExportWidget({super.key, required this.dismiss, required this.accept});

  @override
  State<ShaderExportWidget> createState() => ShaderExportWidgetState();
}

class ShaderExportWidgetState extends State<ShaderExportWidget>
{
  //kept for the session, so reopening the dialog continues where it was left
  static final Map<ExportShaderType, ExportShaderValues> _sessionValues = <ExportShaderType, ExportShaderValues>{};
  static ExportShaderType _sessionShaderType = ExportShaderType.values.first;
  static int _sessionScalingIndex = exportShadingScalingValues.indexOf(4);

  final String _extension = ImageExportData.exportTypeMap[ImageExportType.png]?.extension ?? "png";
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final ValueNotifier<String> _fileName = ValueNotifier<String>("");
  final ValueNotifier<FileNameStatus> _fileNameStatus = ValueNotifier<FileNameStatus>(FileNameStatus.available);
  final ValueNotifier<int> _scalingIndex = ValueNotifier<int>(_sessionScalingIndex);
  final ValueNotifier<ExportShaderType> _shaderType = ValueNotifier<ExportShaderType>(_sessionShaderType);
  final ValueNotifier<ui.Image?> _source = ValueNotifier<ui.Image?>(null);
  final CanvasState _canvasState = GetIt.I.get<CanvasState>();
  final DocumentState _documentState = GetIt.I.get<DocumentState>();
  bool _isDisposed = false;

  @override
  void initState()
  {
    super.initState();
    final String? projectName = GetIt.I.get<ProjectSession>().projectName.value;
    _fileName.value = projectName ?? "";
    _updateFileNameStatus();
    getImageFromLayers(
      canvasSize: _canvasState.canvasSize,
      layerCollection: _documentState.timeline.selectedFrame!.layerList,
      selection: _documentState.selectionState.selection,
    ).then((final ui.Image image) {
      if (_isDisposed)
      {
        image.dispose();
        return;
      }
      _source.value = image;
    });
    //the on-screen keyboard would cover half of the dialog
    if (defaultTargetPlatform != TargetPlatform.android)
    {
      _hotkeyManager.getFocusNode(id: FocusNodeEntry.shaderExportFileNameTextFocus).requestFocus();
    }
  }

  @override
  void dispose()
  {
    _isDisposed = true;
    _sessionShaderType = _shaderType.value;
    _sessionScalingIndex = _scalingIndex.value;
    final ui.Image? source = _source.value;
    _fileName.dispose();
    _fileNameStatus.dispose();
    _scalingIndex.dispose();
    _shaderType.dispose();
    _source.dispose();
    //the renderer works on its own handle of the source, so this one can go right away
    source?.dispose();
    super.dispose();
  }

  ExportShaderValues _valuesFor({required final ExportShaderType type})
  {
    return _sessionValues.putIfAbsent(type, () => ExportShaderValues(definition: exportShaderDefinitions[type]!));
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

  /// Does nothing for an unusable name; an existing file is only replaced with [allowOverwrite].
  void accept({final bool allowOverwrite = true})
  {
    final FileNameStatus status = _fileNameStatus.value;
    if (status != FileNameStatus.available && !(allowOverwrite && status == FileNameStatus.overwrite))
    {
      return;
    }
    widget.accept(
      exportData: ShaderExportData(
        shaderValues: ExportShaderValues.from(other: _valuesFor(type: _shaderType.value)),
        scaling: exportShadingScalingValues[_scalingIndex.value],
        fileName: _fileName.value,
        directory: GetIt.I.get<AppPaths>().exportDir,
      ),
    );
  }

  void cancel()
  {
    widget.dismiss();
  }

  Widget _parameterControl({required final ExportShaderValues values, required final ExportShaderParameter parameter, required final AppLocalizations l10n})
  {
    switch (parameter)
    {
      case final ExportShaderSliderParameter slider:
        final double value = values.valueOf<double>(parameter: slider);
        return KPixSlider(
          value: value,
          min: slider.min,
          max: slider.max,
          divisions: slider.divisions,
          gradientColors: slider.trackGradient,
          label: slider.formatValue(value: value),
          onChanged: (final double newValue) {values.setValue(parameter: slider, value: newValue);},
          textStyle: Theme.of(context).textTheme.bodyLarge!,
        );
      case final ExportShaderToggleParameter toggle:
        return Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: values.valueOf<bool>(parameter: toggle),
            onChanged: (final bool newValue) {values.setValue(parameter: toggle, value: newValue);},
          ),
        );
      case final ExportShaderChoiceParameter choice:
        return SegmentedButton<int>(
          segments: <ButtonSegment<int>>[
            for (int i = 0; i < choice.options.length; i++)
              ButtonSegment<int>(value: i, label: Text(choice.options[i](l10n))),
          ],
          selected: <int>{values.valueOf<int>(parameter: choice)},
          showSelectedIcon: false,
          onSelectionChanged: (final Set<int> selection) {values.setValue(parameter: choice, value: selection.first);},
        );
    }
  }

  /// The parameter rows of [values], with a heading wherever the section changes.
  List<Widget> _parameterRows({required final ExportShaderValues values, required final AppLocalizations l10n})
  {
    final List<Widget> rows = <Widget>[];
    String? currentSection;
    for (final ExportShaderParameter parameter in values.variant.parameters)
    {
      final String? section = parameter.section?.call(l10n);
      if (section != null && section != currentSection)
      {
        if (currentSection != null)
        {
          rows.add(Divider(color: Theme.of(context).primaryColorLight, thickness: ShaderExportWidgetOptions.dividerThickness, height: ShaderExportWidgetOptions.padding * 3));
        }
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: ShaderExportWidgetOptions.padding / 2),
            child: Text(section.toUpperCase(), style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          ),
        );
      }
      currentSection = section;
      rows.add(_parameterRow(values: values, parameter: parameter, l10n: l10n));
    }
    return rows;
  }

  Widget _parameterRow({required final ExportShaderValues values, required final ExportShaderParameter parameter, required final AppLocalizations l10n})
  {
    final bool isDefault = values.isDefault(parameter: parameter);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ShaderExportWidgetOptions.padding / 2),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: ShaderExportWidgetOptions.rowLabelFlex,
            child: Text(parameter.label(l10n), style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            flex: ShaderExportWidgetOptions.rowControlFlex,
            child: _parameterControl(values: values, parameter: parameter, l10n: l10n),
          ),
          Padding(
            padding: const EdgeInsets.only(left: ShaderExportWidgetOptions.padding),
            child: IconButton.outlined(
              tooltip: l10n.resetValue,
              icon: const Icon(TablerIcons.refresh),
              onPressed: isDefault ? null : () {values.setValue(parameter: parameter, value: parameter.initialValue);},
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(ShaderExportWidgetOptions.resetButtonSize, ShaderExportWidgetOptions.resetButtonSize),
                maximumSize: const Size(ShaderExportWidgetOptions.resetButtonSize, ShaderExportWidgetOptions.resetButtonSize),
                iconSize: ShaderExportWidgetOptions.resetButtonSize - ShaderExportWidgetOptions.padding,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
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
                        ValueListenableBuilder<ExportShaderType>(
                          valueListenable: _shaderType,
                          builder: (final BuildContext context, final ExportShaderType shaderType, final Widget? child) {
                            return SegmentedButton<ExportShaderType>(
                              style: Theme.of(context).segmentedButtonTheme.style!.copyWith(visualDensity: const VisualDensity(vertical: 1.5)),
                              segments: <ButtonSegment<ExportShaderType>>[
                                for (final ExportShaderDefinition definition in exportShaderDefinitions.values)
                                  ButtonSegment<ExportShaderType>(
                                    value: definition.type,
                                    label: Text(
                                      style: Theme.of(context).textTheme.titleSmall!.apply(color: definition.type == shaderType ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight),
                                      definition.name(l10n).toUpperCase(),
                                    ),
                                  ),
                              ],
                              selected: <ExportShaderType>{shaderType},
                              showSelectedIcon: false,
                              onSelectionChanged: (final Set<ExportShaderType> selection) {_shaderType.value = selection.first;},
                            );
                          },
                        ),
                        Divider(
                          color: Theme.of(context).primaryColorLight,
                          thickness: ShaderExportWidgetOptions.dividerThickness,
                          height: ShaderExportWidgetOptions.dividerThickness + (ShaderExportWidgetOptions.padding * 2),
                        ),
                        Expanded(
                          child: ValueListenableBuilder<ExportShaderType>(
                            valueListenable: _shaderType,
                            builder: (final BuildContext context, final ExportShaderType shaderType, final Widget? child) {
                              final ExportShaderValues values = _valuesFor(type: shaderType);
                              return ListenableBuilder(
                                listenable: values,
                                builder: (final BuildContext context, final Widget? child) {
                                  return ListView(
                                    padding: const EdgeInsets.symmetric(vertical: ShaderExportWidgetOptions.padding),
                                    children: <Widget>[
                                      if (values.definition.variants.length > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: ShaderExportWidgetOptions.padding),
                                          child: SegmentedButton<int>(
                                            segments: <ButtonSegment<int>>[
                                              for (int i = 0; i < values.definition.variants.length; i++)
                                                ButtonSegment<int>(value: i, label: Text(values.definition.variants[i].name)),
                                            ],
                                            selected: <int>{values.variantIndex},
                                            showSelectedIcon: false,
                                            onSelectionChanged: (final Set<int> selection) {values.variantIndex = selection.first;},
                                          ),
                                        ),
                                      ..._parameterRows(values: values, l10n: l10n),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Divider(
                          color: Theme.of(context).primaryColorLight,
                          thickness: ShaderExportWidgetOptions.dividerThickness,
                          height: ShaderExportWidgetOptions.dividerThickness + (ShaderExportWidgetOptions.padding * 2),
                        ),

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
                              child: KPixTextField(
                                text: _fileName,
                                textAlign: TextAlign.end,
                                focusNode: _hotkeyManager.getFocusNode(id: FocusNodeEntry.shaderExportFileNameTextFocus),
                                onChanged: (final String value) {_updateFileNameStatus();},
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: ValueListenableBuilder<ExportShaderType>(
                            valueListenable: _shaderType,
                            builder: (final BuildContext context, final ExportShaderType shaderType, final Widget? child) {
                              return ValueListenableBuilder<int>(
                                valueListenable: _scalingIndex,
                                builder: (final BuildContext context, final int scalingIndex, final Widget? child) {
                                  return ValueListenableBuilder<ui.Image?>(
                                    valueListenable: _source,
                                    builder: (final BuildContext context, final ui.Image? source, final Widget? child) {
                                      return ShaderPreviewWidget(
                                        source: source,
                                        values: _valuesFor(type: shaderType),
                                        scaling: exportShadingScalingValues[scalingIndex],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
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
                                    divisions: exportShadingScalingValues.length - 1,
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
                                  return Text(formatDimension(width: _canvasState.canvasSize.x * exportShadingScalingValues[scalingIndexVal], height: _canvasState.canvasSize.y * exportShadingScalingValues[scalingIndexVal]),
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
                    child: ValueListenableBuilder<FileNameStatus>(
                      valueListenable: _fileNameStatus,
                      builder: (final BuildContext context, final FileNameStatus status, final Widget? child) {
                        return IconButton.outlined(
                          tooltip: l10n.apply,
                          icon: const Icon(TablerIcons.check),
                          onPressed: status == FileNameStatus.available || status == FileNameStatus.overwrite ? accept : null,
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
    );
  }
}
