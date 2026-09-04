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
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// Supported image export types.
enum ImageExportType
{
  png,
  aseprite,
  photoshop,
  gimp,
  pixelorama,
  kpix,
  texturePack
}

/// Supported animation export types.
enum AnimationExportType
{
  gif,
  apng,
  zippedPng,
  //aseprite,
  //pixelorama,
  texturePack
}

/// Supported palette export types.
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
  openOffice,
  json
}

/// Supported special export types.
enum KPixExportType
{
  kpix,
  texturePack,
  texturePackAnimated
}

// Available export sections.
enum ExportSectionType
{
  image,
  animation,
  palette,
  kpix
}

/// Data structure for holding information needed for exporting. Like the
/// [extension], [directory], ...
abstract class ExportData
{
  final String extension;
  final String name;
  final String fileName;
  final String directory;
  const ExportData({required this.name, required this.extension, this.fileName = "", this.directory = ""});
}

/// [ExportData] specialization for palettes.
class PaletteExportData extends ExportData
{
  const PaletteExportData({required super.name, required super.extension, super.fileName = "", super.directory = ""});
  factory PaletteExportData.fromWithConcreteData({required final PaletteExportData other, required final String fileName, required final String directory})
  {
    return PaletteExportData(name: other.name, extension: other.extension, directory: directory, fileName: fileName);
  }

  static const Map<PaletteExportType, PaletteExportData> exportTypeMap =
  <PaletteExportType, PaletteExportData>{
    PaletteExportType.png:PaletteExportData(name: "PNG", extension: "png"),
    PaletteExportType.aseprite:PaletteExportData(name: "ASEPRITE", extension: "aseprite"),
    PaletteExportType.gimp:PaletteExportData(name: "GIMP", extension: "gpl"),
    PaletteExportType.paintNet:PaletteExportData(name: "PAINT.NET", extension: "txt"),
    PaletteExportType.adobe:PaletteExportData(name: "ADOBE", extension: "ase"),
    PaletteExportType.jasc:PaletteExportData(name: "JASC", extension: "pal"),
    PaletteExportType.corel:PaletteExportData(name: "COREL", extension: "xml"),
    PaletteExportType.openOffice:PaletteExportData(name: "STAROFFICE", extension: "soc"),
    PaletteExportType.json:PaletteExportData(name: "PIXELORAMA", extension: "json"),
    PaletteExportType.kpal:PaletteExportData(name: "KPAL", extension: fileExtensionKpal),
  };
}

/// Available export scaling values.
const List<int> exportScalingValues = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

/// [ExportData] specialization for images.
class ImageExportData extends ExportData
{
  final int scaling;
  final bool scalable;
  const ImageExportData({required super.name, required super.extension, required this.scalable, this.scaling = 1, super.fileName = "", super.directory = ""});
  factory ImageExportData.fromWithConcreteData({required final ImageExportData other, required final int scaling, required final String fileName, required final String directory})
  {
    return ImageExportData(name: other.name, extension: other.extension, scalable: other.scalable, scaling: scaling, directory: directory, fileName: fileName);
  }

  static const Map<ImageExportType, ImageExportData> exportTypeMap = <ImageExportType, ImageExportData>{
    ImageExportType.png : ImageExportData(name: "PNG", extension: "png", scalable: true),
    ImageExportType.aseprite : ImageExportData(name: "ASEPRITE", extension: "aseprite", scalable: false),
    ImageExportType.photoshop : ImageExportData(name: "PHOTOSHOP", extension: "psd", scalable: false),
    ImageExportType.gimp : ImageExportData(name: "GIMP", extension: "xcf", scalable: false),
    ImageExportType.pixelorama : ImageExportData(name: "PIXELORAMA", extension: "pxo", scalable: false),
    ImageExportType.texturePack : ImageExportData(name: "TEXTURE PACK", extension: "zip", scalable: false),
    //NOT USED:
    ImageExportType.kpix : ImageExportData(name: "KPIX", extension: fileExtensionKpix, scalable: false),
  };
}

/// [ExportData] specialization for animations.
class AnimationExportData extends ImageExportData
{
  final bool loopOnly;
  const AnimationExportData({required super.name, required super.extension, required super.scalable, super.scaling = 1, super.fileName = "", super.directory = "", this.loopOnly = false});
  factory AnimationExportData.fromWithConcreteData({required final AnimationExportData other, required final int scaling, required final String fileName, required final String directory, required final bool loopOnly})
  {
    return AnimationExportData(name: other.name, extension: other.extension, scalable: other.scalable, loopOnly: loopOnly, scaling: scaling, directory: directory, fileName: fileName);
  }
  static const Map<AnimationExportType, AnimationExportData> exportTypeMap = <AnimationExportType, AnimationExportData>{
    AnimationExportType.gif : AnimationExportData(name: "GIF", extension: "gif", scalable: true, ),
    AnimationExportType.apng : AnimationExportData(name: "APNG", extension: "apng", scalable: true, ),
    AnimationExportType.zippedPng : AnimationExportData(name: "PNG SEQUENCE", extension: "zip", scalable: true, ),
    //AnimationExportType.aseprite : AnimationExportData(name: "ASEPRITE", extension: "aseprite", scalable: false),
    //AnimationExportType.pixelorama : AnimationExportData(name: "PIXELORAMA", extension: "pxo", scalable: false),
    AnimationExportType.texturePack : AnimationExportData(name: "TEXTURE PACK", extension: "zip", scalable: false, ),
  };
}

/// The screen for showing all the options for exporting a project.
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
  State<ExportWidget> createState() => _ExportWidgetState();
}

class _ExportWidgetState extends State<ExportWidget>
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
      getDirectory(startDir: GetIt.I.get<AppPaths>().exportDir).then((final String? chosenDir) {_handleChosenDirectory(chosenDir: chosenDir);});
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
      label: Tooltip(
        message: tooltip,
        waitDuration: toolTipDuration,
        child: Icon(icon),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
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
                    _createExportSection(type: ExportSectionType.image, tooltip: "Image", icon: TablerIcons.photo),
                    _createExportSection(type: ExportSectionType.animation, tooltip: "Animation", icon: TablerIcons.movie, isEnabled: _documentState.timeline.frames.value.length > 1),
                    _createExportSection(type: ExportSectionType.palette, tooltip: "Palette", icon: Icons.palette),
                    _createExportSection(type: ExportSectionType.kpix, tooltip: "KPix project", icon: TablerIcons.file_export),
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
              builder: (final BuildContext context, final ExportSectionType section, final Widget? child) {
                String title = "EXPORT";
                if (section == ExportSectionType.image)
                {
                  title += " IMAGE";
                }
                else if (section == ExportSectionType.palette)
                {
                  title += " PALETTE";
                }
                else if (section == ExportSectionType.animation)
                {
                  title += " ANIMATION";
                }
                else if (section == ExportSectionType.kpix)
                {
                  title += " PROJECT";
                }
                return Column(
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Expanded(
                          child: Text("Format", style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Expanded(
                          flex: 6,
                          child: Stack(
                            fit: StackFit.passthrough,
                            children: <Widget>[
                              Visibility(
                                visible: section == ExportSectionType.image,
                                child: ValueListenableBuilder<ImageExportType>(
                                  valueListenable: _fileExportType,
                                  builder: (final BuildContext context, final ImageExportType exportTypeEnum, final Widget? child) {
                                    final bool isValidTexturePack = _documentState.timeline.selectedFrame!.layerList.getVisibleRasterLayers().isNotEmpty;
                                    return SegmentedButton<ImageExportType>(
                                      selected: <ImageExportType>{exportTypeEnum},
                                      showSelectedIcon: false,
                                      onSelectionChanged: (final Set<ImageExportType> types) {_fileExportType.value = types.first; _updateFileNameStatus();},
                                      segments: ImageExportType.values
                                        .where((final ImageExportType type) => type != ImageExportType.kpix && type != ImageExportType.texturePack)
                                        .map((final ImageExportType x) => ButtonSegment<ImageExportType>(value: x, enabled: x != ImageExportType.texturePack || isValidTexturePack, label: Text(ImageExportData.exportTypeMap[x]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == x ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)))).toList(),
                                    );
                                  },
                                ),
                              ),
                              Visibility(
                                visible: section == ExportSectionType.animation,
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: _animationSectionOnly,
                                  builder: (final BuildContext context0, final bool sectionOnly, final Widget? child0) {
                                    return ValueListenableBuilder<AnimationExportType>(
                                      valueListenable: _animationExportType,
                                      builder: (final BuildContext context, final AnimationExportType exportTypeEnum, final Widget? child) {
                                        bool isValidTexturePack = true;
                                        final int startFrameIndex = sectionOnly ? _documentState.timeline.loopStartIndex.value : 0;
                                        final int endFrameIndex = sectionOnly ? _documentState.timeline.loopEndIndex.value : _documentState.timeline.frames.value.length - 1;
                                        for (int i = startFrameIndex; i <= endFrameIndex; i++)
                                        {
                                          if (_documentState.timeline.frames.value[i].layerList.getVisibleRasterLayers().isEmpty)
                                          {
                                            isValidTexturePack = false;
                                            break;
                                          }
                                        }

                                        return SegmentedButton<AnimationExportType>(
                                          selected: <AnimationExportType>{exportTypeEnum},
                                          showSelectedIcon: false,
                                          onSelectionChanged: (final Set<AnimationExportType> types) {_animationExportType.value = types.first; _updateFileNameStatus();},
                                          segments: AnimationExportType.values
                                            .where((final AnimationExportType type) => type != AnimationExportType.texturePack)
                                            .map((final AnimationExportType x) => ButtonSegment<AnimationExportType>(value: x, enabled: x != AnimationExportType.texturePack || isValidTexturePack, label: Text(AnimationExportData.exportTypeMap[x]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == x ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)))).toList(),
                                        );
                                      },
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
                                      showSelectedIcon: false,
                                      onSelectionChanged: (final Set<PaletteExportType> types) {_paletteExportType.value = types.first; _updateFileNameStatus();},
                                      segments: PaletteExportType.values.map((final PaletteExportType x) => ButtonSegment<PaletteExportType>(value: x, label: Text(PaletteExportData.exportTypeMap[x]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportType == x ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)))).toList(),
                                    );
                                  },
                                ),
                              ),
                              Visibility(
                                visible: section == ExportSectionType.kpix,
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: _animationSectionOnly,
                                  builder: (final BuildContext context0, final bool sectionOnly, final Widget? child0) {
                                    return ValueListenableBuilder<KPixExportType>(
                                      valueListenable: _kpixExportType,
                                      builder: (final BuildContext context, final KPixExportType exportTypeEnum, final Widget? child) {
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

                                        return SegmentedButton<KPixExportType>(
                                          selected: <KPixExportType>{exportTypeEnum},
                                          showSelectedIcon: false,
                                          onSelectionChanged: (final Set<KPixExportType> types) {_kpixExportType.value = types.first; _updateFileNameStatus();},
                                          segments: <ButtonSegment<KPixExportType>>[
                                            ButtonSegment<KPixExportType>(value: KPixExportType.kpix, label: Text("KPIX PROJECT", style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == KPixExportType.kpix ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight))),
                                            ButtonSegment<KPixExportType>(enabled: isValidTexturePack, value: KPixExportType.texturePack, label: Text("TEXTURE PACK", style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == KPixExportType.texturePack ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight))),
                                            ButtonSegment<KPixExportType>(enabled: isValidTexturePackAnimation, value: KPixExportType.texturePackAnimated, label: Text("TEXTURE PACK ANIMATION", style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == KPixExportType.texturePackAnimated ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight))),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Opacity(
                      opacity: (section == ExportSectionType.image || section == ExportSectionType.animation) ? 1.0 : 0.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Expanded(
                            child: Text("Scaling", style: Theme.of(context).textTheme.titleMedium),
                          ),
                          Expanded(
                            flex: 4,
                            child: ValueListenableBuilder<AnimationExportType>(
                              valueListenable: _animationExportType,
                              builder: (final BuildContext context, final AnimationExportType animationType, final Widget? child) {
                                return ValueListenableBuilder<ImageExportType>(
                                  valueListenable: _fileExportType,
                                  builder: (final BuildContext context1, final ImageExportType imageType, final Widget? child1) {
                                    return ValueListenableBuilder<int>(
                                      valueListenable: _scalingIndex,
                                      builder: (final BuildContext context2, final int scalingIndexVal, final Widget? child2) {
                                        final bool isScalable = (section == ExportSectionType.image && ImageExportData.exportTypeMap[imageType]!.scalable) || (section == ExportSectionType.animation && AnimationExportData.exportTypeMap[animationType]!.scalable);
                                        return KPixSlider(
                                          value: isScalable? scalingIndexVal.toDouble() : 0,
                                          max: exportScalingValues.length.toDouble() - 1,
                                          //divisions: exportScalingValues.length,
                                          label: "${exportScalingValues[scalingIndexVal]}:1",
                                          onChanged: isScalable ? (final double newVal){_scalingIndex.value = newVal.round();} : null,
                                          textStyle: Theme.of(context).textTheme.bodyLarge!,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: ValueListenableBuilder<AnimationExportType>(
                              valueListenable: _animationExportType,
                              builder: (final BuildContext context, final AnimationExportType animationType, final Widget? child) {
                                return ValueListenableBuilder<ImageExportType>(
                                  valueListenable: _fileExportType,
                                  builder: (final BuildContext context1, final ImageExportType imageType, final Widget? child) {
                                    return ValueListenableBuilder<int>(
                                      valueListenable: _scalingIndex,
                                      builder: (final BuildContext context2, final int scalingIndexVal, final Widget? child2) {
                                        final bool isScalable = (section == ExportSectionType.image && ImageExportData.exportTypeMap[imageType]!.scalable) || (section == ExportSectionType.animation && AnimationExportData.exportTypeMap[animationType]!.scalable);
                                        return Text(isScalable ?
                                        "${_canvasState.canvasSize.x *  exportScalingValues[scalingIndexVal]} x ${_canvasState.canvasSize.y *  exportScalingValues[scalingIndexVal]}" : "${_canvasState.canvasSize.x} x ${_canvasState.canvasSize.y}",
                                          textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<KPixExportType>(
                      valueListenable: _kpixExportType,
                      builder: (final BuildContext context0, final KPixExportType kPixExportType, final Widget? child0) {
                        return Opacity(
                          opacity: (section == ExportSectionType.animation || (section == ExportSectionType.kpix && kPixExportType == KPixExportType.texturePackAnimated)) ? 1.0 : 0.0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Expanded(
                                child: Text("Selection Only", style: Theme.of(context).textTheme.titleMedium),
                              ),
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
                                    final String animationLength = "$frameCount frames (${(animationLengthMs.toDouble() / 1000.0).toStringAsFixed(3)}s)";
                                    return Text(animationLength, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Expanded(
                          child: Text("Directory", style: Theme.of(context).textTheme.titleMedium),
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
                          child: Tooltip(
                            message: "Change Directory",
                            waitDuration: toolTipDuration,
                            child: IconButton.outlined(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                              onPressed: _changeDirectoryPressed,
                              icon: const Icon(
                                  TablerIcons.folder,
                                  size: OverlayEntryAlertDialogOptions.iconSize / 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                            child: ValueListenableBuilder<KPixExportType>(
                              valueListenable: _kpixExportType,
                              builder: (final BuildContext context, final KPixExportType kPixExportType, final Widget? child) {
                                return ValueListenableBuilder<AnimationExportType>(
                                  valueListenable: _animationExportType,
                                  builder: (final BuildContext context, final AnimationExportType animationType, final Widget? child) {
                                    return ValueListenableBuilder<PaletteExportType>(
                                      valueListenable: _paletteExportType,
                                      builder: (final BuildContext context, final PaletteExportType paletteExportType, final Widget? child) {
                                        return ValueListenableBuilder<ImageExportType>(
                                          valueListenable: _fileExportType,
                                          builder: (final BuildContext context, final ImageExportType imageExportType, final Widget? child) {
                                            final String extension = _getExtension(section: section);
                                            return Text(".$extension");
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
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
                    child: Tooltip(
                      waitDuration: toolTipDuration,
                      message: "Close",
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
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                    child: ValueListenableBuilder<ExportSectionType>(
                      valueListenable: _selectedSection,
                      builder: (final BuildContext context, final ExportSectionType selSection, final Widget? child) {
                        return ValueListenableBuilder<FileNameStatus>(
                          valueListenable: _fileNameStatus,
                          builder: (final BuildContext context, final FileNameStatus status, final Widget? child) {
                            return Tooltip(
                              waitDuration: toolTipDuration,
                              message: "Export File",
                              child: IconButton.outlined(
                                icon: const Icon(
                                  TablerIcons.check,
                                ),
                                onPressed: (status == FileNameStatus.available || status == FileNameStatus.overwrite) ?
                                () {
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
                                } : null,
                              ),
                            );
                          },
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
