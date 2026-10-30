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
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/file_name_check.dart';
import 'package:kpix/util/file_pickers.dart';
import 'package:kpix/util/helpers/format_helper.dart';
import 'package:kpix/widgets/callback_typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// Supported image export types.
class ExportWidget extends StatefulWidget
{
  final Function() dismiss;
  final ImageExportDataFn acceptFile;
  final PaletteExportDataFn acceptPalette;
  final AnimationExportDataFn acceptAnimation;

  const ExportWidget({
    super.key,
    required this.dismiss,
    required this.acceptFile,
    required this.acceptPalette,
    required this.acceptAnimation,
  });

  @override
  State<ExportWidget> createState() => ExportWidgetState();
}

class ExportWidgetState extends State<ExportWidget>
{
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final ValueNotifier<ImageExportType> _fileExportType = ValueNotifier<ImageExportType>(ImageExportType.png);
  final ValueNotifier<PaletteExportType> _paletteExportType = ValueNotifier<PaletteExportType>(PaletteExportType.kpal);
  final ValueNotifier<AnimationExportType> _animationExportType = ValueNotifier<AnimationExportType>(AnimationExportType.gif);
  final ValueNotifier<KPixExportType> _kpixExportType = ValueNotifier<KPixExportType>(KPixExportType.kpix);
  final ValueNotifier<bool> _animationSectionOnly = ValueNotifier<bool>(false);
  final ValueNotifier<int> _scalingIndex = ValueNotifier<int>(0);
  final ValueNotifier<String> _fileName = ValueNotifier<String>("");
  final ProjectSession _projectSession = GetIt.I.get<ProjectSession>();
  final DocumentState _documentState = GetIt.I.get<DocumentState>();
  final CanvasState _canvasState = GetIt.I.get<CanvasState>();
  final ValueNotifier<FileNameStatus> _fileNameStatus = ValueNotifier<FileNameStatus>(FileNameStatus.available);
  final ValueNotifier<ExportSectionType> _selectedSection = ValueNotifier<ExportSectionType>(ExportSectionType.image);

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

  @override
  void initState()
  {
    super.initState();
    if (_documentState.timeline.loopStartIndex.value != _documentState.timeline.loopEndIndex.value)
    {
      _selectedSection.value = ExportSectionType.animation;
    }
    _fileName.value = _projectSession.projectName.value == null ? "" : _projectSession.projectName.value!;
    _updateFileNameStatus();
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.exportFileNameTextFocus).requestFocus();
  }

  String _getExtension({required final ExportSectionType section})
  {
    String extension;
    switch(section)
    {
      case ExportSectionType.image:
        extension = ImageExportData.exportTypeMap[_fileExportType.value]!.extension;
      case ExportSectionType.palette:
        extension = PaletteExportData.exportTypeMap[_paletteExportType.value]!.extension;
      case ExportSectionType.animation:
        extension = AnimationExportData.exportTypeMap[_animationExportType.value]!.extension;
      case ExportSectionType.kpix:
        if (_kpixExportType.value == KPixExportType.texturePack)
        {
          extension = ImageExportData.exportTypeMap[ImageExportType.texturePack]!.extension;
        }
        else if (_kpixExportType.value == KPixExportType.texturePackAnimated)
        {
          extension = AnimationExportData.exportTypeMap[AnimationExportType.texturePack]!.extension;
        }
        else
        {
          extension = fileExtensionKpix;
        }
    }
    return extension;
  }

  void _updateFileNameStatus()
  {
    final String extension = _getExtension(section: _selectedSection.value);
    _fileNameStatus.value = checkFileName(fileName: _fileName.value, directory: GetIt.I.get<AppPaths>().exportDir, extension: extension);
  }

  ButtonSegment<ExportSectionType> _createExportSection({required final ExportSectionType type, required final String tooltip, required final IconData icon, final bool isEnabled = true})
  {
    return ButtonSegment<ExportSectionType>(
      enabled: isEnabled,
      value: type,
      tooltip: tooltip,
      icon: Icon(icon),
    );
  }

  /// Does nothing for an unusable name; an existing file is only replaced with
  /// [allowOverwrite].
  void accept({final bool allowOverwrite = true})
  {
    final FileNameStatus status = _fileNameStatus.value;
    if (status != FileNameStatus.available && !(allowOverwrite && status == FileNameStatus.overwrite))
    {
      return;
    }
    final ExportSectionType selSection = _selectedSection.value;
    final String exportDir = GetIt.I.get<AppPaths>().exportDir;
    if (selSection == ExportSectionType.image)
    {
      widget.acceptFile(exportData: ImageExportData.fromWithConcreteData(other: ImageExportData.exportTypeMap[_fileExportType.value]!, scaling: exportScalingValues[_scalingIndex.value], fileName: _fileName.value, directory: exportDir), exportType: _fileExportType.value);
    }
    else if (selSection == ExportSectionType.palette)
    {
      widget.acceptPalette(saveData: PaletteExportData.fromWithConcreteData(other: PaletteExportData.exportTypeMap[_paletteExportType.value]!, fileName: _fileName.value, directory: exportDir), paletteType: _paletteExportType.value);
    }
    else if (selSection == ExportSectionType.animation)
    {
      widget.acceptAnimation(exportData: AnimationExportData.fromWithConcreteData(other: AnimationExportData.exportTypeMap[_animationExportType.value]!, scaling: exportScalingValues[_scalingIndex.value], fileName: _fileName.value, directory: exportDir, loopOnly: _animationSectionOnly.value), exportType: _animationExportType.value);
    }
    else if (selSection == ExportSectionType.kpix)
    {
      if (_kpixExportType.value == KPixExportType.kpix)
      {
        widget.acceptFile(exportData: ImageExportData.fromWithConcreteData(other: const ImageExportData(name: "KPIX", extension: fileExtensionKpix, scalable: false), scaling: 1, fileName: _fileName.value, directory: exportDir), exportType: ImageExportType.kpix);
      }
      else if (_kpixExportType.value == KPixExportType.texturePack)
      {
        widget.acceptFile(exportData: ImageExportData.fromWithConcreteData(other: ImageExportData.exportTypeMap[ImageExportType.texturePack]!, scaling: 1, fileName: _fileName.value, directory: exportDir), exportType: ImageExportType.texturePack);
      }
      else if (_kpixExportType.value == KPixExportType.texturePackAnimated)
      {
        widget.acceptAnimation(exportData: AnimationExportData.fromWithConcreteData(other: AnimationExportData.exportTypeMap[AnimationExportType.texturePack]!, scaling: 1, fileName: _fileName.value, directory: exportDir, loopOnly: _animationSectionOnly.value), exportType: AnimationExportType.texturePack);
      }

    }
  }

  bool _isScalable({required final ExportSectionType section})
  {
    return (section == ExportSectionType.image && ImageExportData.exportTypeMap[_fileExportType.value]!.scalable) || (section == ExportSectionType.animation && AnimationExportData.exportTypeMap[_animationExportType.value]!.scalable);
  }

  ButtonSegment<T> _createTypeSegment<T>({required final ValueNotifier<T> type, required final T value, required final String label, final bool isEnabled = true})
  {
    return ButtonSegment<T>(
      value: value,
      enabled: isEnabled,
      label: Text(label, style: Theme.of(context).textTheme.bodyMedium!.apply(color: type.value == value ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)),
    );
  }

  /// The formats of one section; [dependsOn] is what [segments] reads besides [type].
  Widget _createTypeSelector<T>({required final ValueNotifier<T> type, final Listenable? dependsOn, required final List<ButtonSegment<T>> Function() segments})
  {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable?>[type, dependsOn]),
      builder: (final BuildContext context, final Widget? child) {
        return SegmentedButton<T>(
          selected: <T>{type.value},
          showSelectedIcon: false,
          onSelectionChanged: (final Set<T> types) {type.value = types.first; _updateFileNameStatus();},
          segments: segments(),
        );
      },
    );
  }

  List<ButtonSegment<KPixExportType>> _createKPixSegments({required final AppLocalizations l10n})
  {
    final bool sectionOnly = _animationSectionOnly.value;
    bool isValidTexturePackAnimation = _documentState.timeline.frames.value.length > 1;
    final bool isValidTexturePack = _documentState.timeline.selectedFrame!.layerList.getVisibleRasterLayers().isNotEmpty;
    final int startFrameIndex = sectionOnly ? _documentState.timeline.loopStartIndex.value : 0;
    final int endFrameIndex = sectionOnly ? _documentState.timeline.loopEndIndex.value : _documentState.timeline.frames.value.length - 1;
    for (int i = startFrameIndex; i <= endFrameIndex; i++)
    {
      if (_documentState.timeline.frames.value[i].layerList.getVisibleRasterLayers().isEmpty)
      {
        isValidTexturePackAnimation = false;
        break;
      }
    }
    return <ButtonSegment<KPixExportType>>[
      _createTypeSegment<KPixExportType>(type: _kpixExportType, value: KPixExportType.kpix, label: l10n.kpixProject.toUpperCase()),
      _createTypeSegment<KPixExportType>(type: _kpixExportType, value: KPixExportType.texturePack, label: l10n.texturePack.toUpperCase(), isEnabled: isValidTexturePack),
      _createTypeSegment<KPixExportType>(type: _kpixExportType, value: KPixExportType.texturePackAnimated, label: l10n.texturePackAnimation.toUpperCase(), isEnabled: isValidTexturePackAnimation),
    ];
  }

  Widget _createLabeledRow({required final String label, required final List<Widget> children})
  {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        ...children,
      ],
    );
  }

  Widget _createFormatRow({required final ExportSectionType section, required final AppLocalizations l10n})
  {
    return _createLabeledRow(
      label: l10n.format,
      children: <Widget>[
        Expanded(
          flex: 6,
          child: Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              Visibility(
                visible: section == ExportSectionType.image,
                child: _createTypeSelector<ImageExportType>(
                  type: _fileExportType,
                  segments: () => ImageExportType.values
                    .where((final ImageExportType type) => type != ImageExportType.kpix && type != ImageExportType.texturePack)
                    .map((final ImageExportType x) => _createTypeSegment<ImageExportType>(type: _fileExportType, value: x, label: getImageExportTypeLabel(type: x, l10n: l10n)))
                    .toList(),
                ),
              ),
              Visibility(
                visible: section == ExportSectionType.animation,
                child: _createTypeSelector<AnimationExportType>(
                  type: _animationExportType,
                  segments: () => AnimationExportType.values
                    .where((final AnimationExportType type) => type != AnimationExportType.texturePack)
                    .map((final AnimationExportType x) => _createTypeSegment<AnimationExportType>(type: _animationExportType, value: x, label: getAnimationExportTypeLabel(type: x, l10n: l10n)))
                    .toList(),
                ),
              ),
              Visibility(
                visible: section == ExportSectionType.palette,
                child: _createTypeSelector<PaletteExportType>(
                  type: _paletteExportType,
                  segments: () => PaletteExportType.values
                    .map((final PaletteExportType x) => _createTypeSegment<PaletteExportType>(type: _paletteExportType, value: x, label: PaletteExportData.exportTypeMap[x]!.name))
                    .toList(),
                ),
              ),
              Visibility(
                visible: section == ExportSectionType.kpix,
                child: _createTypeSelector<KPixExportType>(
                  type: _kpixExportType,
                  dependsOn: _animationSectionOnly,
                  segments: () => _createKPixSegments(l10n: l10n),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _createScalingRow({required final ExportSectionType section, required final AppLocalizations l10n})
  {
    final Listenable scaling = Listenable.merge(<Listenable>[_animationExportType, _fileExportType, _scalingIndex]);
    return Opacity(
      opacity: (section == ExportSectionType.image || section == ExportSectionType.animation) ? 1.0 : 0.0,
      child: _createLabeledRow(
        label: l10n.scaling,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: ListenableBuilder(
              listenable: scaling,
              builder: (final BuildContext context, final Widget? child) {
                final bool isScalable = _isScalable(section: section);
                return KPixSlider(
                  value: isScalable ? _scalingIndex.value.toDouble() : 0,
                  max: exportScalingValues.length.toDouble() - 1,
                  label: "${exportScalingValues[_scalingIndex.value]}:1",
                  onChanged: isScalable ? (final double newVal){_scalingIndex.value = newVal.round();} : null,
                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                );
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: ListenableBuilder(
              listenable: scaling,
              builder: (final BuildContext context, final Widget? child) {
                final int factor = _isScalable(section: section) ? exportScalingValues[_scalingIndex.value] : 1;
                return Text(
                  formatDimension(width: _canvasState.canvasSize.x * factor, height: _canvasState.canvasSize.y * factor),
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _createSelectionOnlyRow({required final ExportSectionType section, required final AppLocalizations l10n})
  {
    return ValueListenableBuilder<KPixExportType>(
      valueListenable: _kpixExportType,
      builder: (final BuildContext context0, final KPixExportType kPixExportType, final Widget? child0) {
        return Opacity(
          opacity: (section == ExportSectionType.animation || (section == ExportSectionType.kpix && kPixExportType == KPixExportType.texturePackAnimated)) ? 1.0 : 0.0,
          child: _createLabeledRow(
            label: l10n.selectionOnly,
            children: <Widget>[
              Expanded(
                flex: 4,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _animationSectionOnly,
                  builder: (final BuildContext context, final bool animationSectionOnly, final Widget? child) {
                    final bool moreThanOneFrame = _documentState.timeline.loopStartIndex.value != _documentState.timeline.loopEndIndex.value;
                    final bool sectionIsNotWhole = _documentState.timeline.loopStartIndex.value > 0 || _documentState.timeline.loopEndIndex.value < _documentState.timeline.frames.value.length - 1;
                    return Switch(
                      value: animationSectionOnly,
                      onChanged: (moreThanOneFrame && sectionIsNotWhole) ? (final bool newValue) {_animationSectionOnly.value = newValue;} : null,
                    );
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _animationSectionOnly,
                  builder: (final BuildContext context, final bool animationSectionOnly, final Widget? child) {
                    final int animationLengthMs = _documentState.timeline.calculateTotalFrameTime(sectionOnly: animationSectionOnly);
                    final int frameCount = animationSectionOnly ? _documentState.timeline.loopEndIndex.value - _documentState.timeline.loopStartIndex.value + 1 : _documentState.timeline.frames.value.length;
                    final String animationLength = "${l10n.nFrames(frameCount)} (${(animationLengthMs.toDouble() / 1000.0).toStringAsFixed(3)}s)";
                    return Text(animationLength, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _createDirectoryRow({required final AppLocalizations l10n})
  {
    return _createLabeledRow(
      label: l10n.directory,
      children: <Widget>[
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
            padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
            onPressed: _changeDirectoryPressed,
            icon: const Icon(
                TablerIcons.folder,
                size: OverlayEntryAlertDialogOptions.iconSize / 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _createFileNameRow({required final ExportSectionType section, required final AppLocalizations l10n})
  {
    return _createLabeledRow(
      label: l10n.fileName,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: ValueListenableBuilder<String?>(
            valueListenable: _fileName,
            builder: (final BuildContext context, final String? filePath, final Widget? child) {
              final TextEditingController controller = TextEditingController(text: filePath);
              controller.selection = TextSelection.collapsed(offset: controller.text.length);
              return TextField(
                textAlign: TextAlign.end,
                focusNode: _hotkeyManager.getFocusNode(id: FocusNodeEntry.exportFileNameTextFocus),
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
          child: ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[_kpixExportType, _animationExportType, _paletteExportType, _fileExportType]),
            builder: (final BuildContext context, final Widget? child) {
              return Text(".${_getExtension(section: section)}");
            },
          ),
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
    );
  }

  @override
  Widget build(final BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return KPixAnimationWidget(
      constraints: const BoxConstraints(
        minHeight: OverlayEntryAlertDialogOptions.minHeight,
        minWidth: OverlayEntryAlertDialogOptions.minWidth,
        maxHeight: OverlayEntryAlertDialogOptions.maxHeight,
        maxWidth: OverlayEntryAlertDialogOptions.maxWidth * 2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            ValueListenableBuilder<ExportSectionType>(
              valueListenable: _selectedSection,
              builder: (final BuildContext context, final ExportSectionType section, final Widget? child) {
                return SegmentedButton<ExportSectionType>(
                  segments:  <ButtonSegment<ExportSectionType>>[
                    _createExportSection(type: ExportSectionType.image, tooltip: l10n.image, icon: TablerIcons.photo),
                    _createExportSection(type: ExportSectionType.animation, tooltip: l10n.animation, icon: TablerIcons.movie, isEnabled: _documentState.timeline.frames.value.length > 1),
                    _createExportSection(type: ExportSectionType.palette, tooltip: l10n.palette, icon: Icons.palette),
                    _createExportSection(type: ExportSectionType.kpix, tooltip: l10n.kpixProject, icon: TablerIcons.file_export),
                  ],
                  selected: <ExportSectionType>{section},
                  showSelectedIcon: false,
                  onSelectionChanged: (final Set<ExportSectionType> exportSections) {_selectedSection.value = exportSections.first; _updateFileNameStatus(); },
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: OverlayEntryAlertDialogOptions.padding, bottom: OverlayEntryAlertDialogOptions.padding),
              child: Divider(
                color: Theme.of(context).primaryColorLight,
                thickness: OverlayEntryAlertDialogOptions.borderWidth,
                height: OverlayEntryAlertDialogOptions.borderWidth,
              ),
            ),
            ValueListenableBuilder<ExportSectionType>(
              valueListenable: _selectedSection,
              builder: (final BuildContext context, final ExportSectionType section, final Widget? child)
              {
                final AppLocalizations l10n = AppLocalizations.of(context)!;
                String title = l10n.export.toUpperCase();
                if (section == ExportSectionType.image)
                {
                  title += " ${l10n.image.toUpperCase()}";
                }
                else if (section == ExportSectionType.palette)
                {
                  title += " ${l10n.palette.toUpperCase()}";
                }
                else if (section == ExportSectionType.animation)
                {
                  title += " ${l10n.animation.toUpperCase()}";
                }
                else if (section == ExportSectionType.kpix)
                {
                  title += " ${l10n.kpixProject.toUpperCase()}";
                }
                return Column(
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
                    _createFormatRow(section: section, l10n: l10n),
                    _createScalingRow(section: section, l10n: l10n),
                    _createSelectionOnlyRow(section: section, l10n: l10n),
                    _createDirectoryRow(l10n: l10n),
                    _createFileNameRow(section: section, l10n: l10n),
                  ],
                );
              },
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
                          tooltip: l10n.exportFile,
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
      ),
    );
  }

}
