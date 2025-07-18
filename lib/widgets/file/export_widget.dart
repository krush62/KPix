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
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';


enum ImageExportType
{
  png,
  aseprite,
  //photoshop,
  gimp,
  pixelorama,
  kpix
}

enum AnimationExportType
{
  gif,
  apng,
  zippedPng,
  //aseprite,
  //pixelorama,
}

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

enum ExportSectionType
{
  image,
  animation,
  palette
}

abstract class ExportData
{
  final String extension;
  final String name;
  final String fileName;
  final String directory;
  const ExportData({required this.name, required this.extension, this.fileName = "", this.directory = ""});
}

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

const List<int> exportScalingValues = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

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
    //ExportType.photoshop : ExportData(name: "PHOTOSHOP", extension: "psd", scalable: false),
    ImageExportType.gimp : ImageExportData(name: "GIMP", extension: "xcf", scalable: false),
    ImageExportType.pixelorama : ImageExportData(name: "PIXELORAMA", extension: "pxo", scalable: false),
    ImageExportType.kpix : ImageExportData(name: "KPIX", extension: fileExtensionKpix, scalable: false),
  };
}



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
  };
}




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
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<ImageExportType> _fileExportType = ValueNotifier<ImageExportType>(ImageExportType.png);
  final ValueNotifier<PaletteExportType> _paletteExportType = ValueNotifier<PaletteExportType>(PaletteExportType.kpal);
  final ValueNotifier<AnimationExportType> _animationExportType = ValueNotifier<AnimationExportType>(AnimationExportType.gif);
  final ValueNotifier<bool> _animationSectionOnly = ValueNotifier<bool>(false);
  final ValueNotifier<int> _scalingIndex = ValueNotifier<int>(0);
  final ValueNotifier<String> _fileName = ValueNotifier<String>("");
  final AppState _appState = GetIt.I.get<AppState>();
  final ValueNotifier<FileNameStatus> _fileNameStatus = ValueNotifier<FileNameStatus>(FileNameStatus.available);
  final ValueNotifier<ExportSectionType> _selectedSection = ValueNotifier<ExportSectionType>(ExportSectionType.image);

    void _changeDirectoryPressed()
    {
      getDirectory(startDir: _appState.exportDir).then((final String? chosenDir) {_handleChosenDirectory(chosenDir: chosenDir);});
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
    if (_appState.timeline.loopStartIndex.value != _appState.timeline.loopEndIndex.value)
    {
      _selectedSection.value = ExportSectionType.animation;
    }
    _fileName.value = _appState.projectName.value == null ? "" : _appState.projectName.value!;
    _updateFileNameStatus();
    _hotkeyManager.exportFileNameTextFocus.requestFocus();
  }

  void _updateFileNameStatus()
  {
    final String extension = _selectedSection.value == ExportSectionType.image ? ImageExportData.exportTypeMap[_fileExportType.value]!.extension : PaletteExportData.exportTypeMap[_paletteExportType.value]!.extension;
    _fileNameStatus.value = checkFileName(fileName: _fileName.value, directory: _appState.exportDir, extension: extension);
  }

  @override
  Widget build(final BuildContext context) {
    return KPixAnimationWidget(
      constraints: BoxConstraints(
        minHeight: _options.minHeight,
        minWidth: _options.minWidth,
        maxHeight: _options.maxHeight,
        maxWidth: _options.maxWidth * 2,
      ),
      child: Padding(
        padding: EdgeInsets.all(_options.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            ValueListenableBuilder<ExportSectionType>(
              valueListenable: _selectedSection,
              builder: (final BuildContext context, final ExportSectionType section, final Widget? child) {
                return SegmentedButton<ExportSectionType>(
                  segments:  <ButtonSegment<ExportSectionType>>[
                    const ButtonSegment<ExportSectionType>(
                      value: ExportSectionType.image,
                      label: Tooltip(
                          message: "Image",
                          waitDuration: AppState.toolTipDuration,
                          child: Icon(
                              FontAwesomeIcons.image,
                          ),
                      ),
                    ),
                    ButtonSegment<ExportSectionType>(
                      enabled: _appState.timeline.frames.value.length > 1,
                      value: ExportSectionType.animation,
                      label: const Tooltip(
                        message: "Animation",
                        waitDuration: AppState.toolTipDuration,
                        child: Icon(
                          FontAwesomeIcons.film,
                        ),
                      ),
                    ),
                    const ButtonSegment<ExportSectionType>(
                      value: ExportSectionType.palette,
                      label: Tooltip(
                          message: "Palette",
                          waitDuration: AppState.toolTipDuration,
                          child: Icon(
                              FontAwesomeIcons.palette,
                          ),
                      ),
                    ),
                  ],
                  selected: <ExportSectionType>{section},
                  showSelectedIcon: false,
                  onSelectionChanged: (final Set<ExportSectionType> exportSections) {_selectedSection.value = exportSections.first; _updateFileNameStatus();},
                );
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: _options.padding, bottom: _options.padding),
              child: Divider(
                color: Theme.of(context).primaryColorLight,
                thickness: _options.borderWidth,
                height: _options.borderWidth,
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
                  return Column(
                    children: <Widget>[
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: _options.padding),
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
                                      return SegmentedButton<ImageExportType>(
                                        selected: <ImageExportType>{exportTypeEnum},
                                        showSelectedIcon: false,
                                        onSelectionChanged: (final Set<ImageExportType> types) {_fileExportType.value = types.first; _updateFileNameStatus();},
                                        segments: ImageExportType.values.map((final ImageExportType x) => ButtonSegment<ImageExportType>(value: x, label: Text(ImageExportData.exportTypeMap[x]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == x ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)))).toList(),
                                      );
                                    },
                                  ),
                                ),
                                Visibility(
                                  visible: section == ExportSectionType.animation,
                                  child: ValueListenableBuilder<AnimationExportType>(
                                    valueListenable: _animationExportType,
                                    builder: (final BuildContext context, final AnimationExportType exportTypeEnum, final Widget? child) {
                                      return SegmentedButton<AnimationExportType>(
                                        selected: <AnimationExportType>{exportTypeEnum},
                                        showSelectedIcon: false,
                                        onSelectionChanged: (final Set<AnimationExportType> types) {_animationExportType.value = types.first; _updateFileNameStatus();},
                                        segments: AnimationExportType.values.map((final AnimationExportType x) => ButtonSegment<AnimationExportType>(value: x, label: Text(AnimationExportData.exportTypeMap[x]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == x ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)))).toList(),
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
                                            divisions: exportScalingValues.length,
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
                                          "${_appState.canvasSize.x *  exportScalingValues[scalingIndexVal]} x ${_appState.canvasSize.y *  exportScalingValues[scalingIndexVal]}" : "${_appState.canvasSize.x} x ${_appState.canvasSize.y}",
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
                      Opacity(
                        opacity: (section == ExportSectionType.animation) ? 1.0 : 0.0,
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
                                  final bool moreThanOneFrame = _appState.timeline.loopStartIndex.value != _appState.timeline.loopEndIndex.value;
                                  final bool sectionIsNotWhole = _appState.timeline.loopStartIndex.value > 0 || _appState.timeline.loopEndIndex.value < _appState.timeline.frames.value.length - 1;
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
                                  final int animationLengthMs = _appState.timeline.calculateTotalFrameTime(sectionOnly: animationSectionOnly);
                                  final int frameCount = animationSectionOnly ? _appState.timeline.loopEndIndex.value - _appState.timeline.loopStartIndex.value + 1 : _appState.timeline.frames.value.length;
                                  final String animationLength = "$frameCount frames (${(animationLengthMs.toDouble() / 1000.0).toStringAsFixed(3)}s)";
                                  return Text(animationLength, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium);
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
                            child: Text("Directory", style: Theme.of(context).textTheme.titleMedium),
                          ),
                          Expanded(
                            flex: 4,
                            child: ValueListenableBuilder<String>(
                              valueListenable: _appState.exportDirNotifier,
                              builder: (final BuildContext context, final String expDir, final Widget? child) {
                                return Text(expDir, textAlign: TextAlign.center);
                              },
                            ),
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
                                    size: _options.iconSize / 2,
                                ),
                                color: Theme.of(context).primaryColorLight,
                                style: IconButton.styleFrom(
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: Theme.of(context).primaryColor,
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
                                    focusNode: _hotkeyManager.exportFileNameTextFocus,
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
                              child: ValueListenableBuilder<AnimationExportType>(
                                valueListenable: _animationExportType,
                                builder: (final BuildContext context, final AnimationExportType animationType, final Widget? child) {
                                  return ValueListenableBuilder<PaletteExportType>(
                                    valueListenable: _paletteExportType,
                                    builder: (final BuildContext context, final PaletteExportType paletteExportType, final Widget? child) {
                                      return ValueListenableBuilder<ImageExportType>(
                                        valueListenable: _fileExportType,
                                        builder: (final BuildContext context, final ImageExportType imageExportType, final Widget? child) {
                                          String extension = "";
                                          if (section == ExportSectionType.image)
                                          {
                                            extension = ImageExportData.exportTypeMap[imageExportType]!.extension;
                                          }
                                          else if (section == ExportSectionType.palette)
                                          {
                                            extension = PaletteExportData.exportTypeMap[paletteExportType]!.extension;
                                          }
                                          else if (section == ExportSectionType.animation)
                                          {
                                            extension = AnimationExportData.exportTypeMap[animationType]!.extension;
                                          }
                                          return Text(".$extension");
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
                    padding: EdgeInsets.all(_options.padding),
                    child: Tooltip(
                      waitDuration: AppState.toolTipDuration,
                      message: "Close",
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
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(_options.padding),
                    child: ValueListenableBuilder<ExportSectionType>(
                      valueListenable: _selectedSection,
                      builder: (final BuildContext context, final ExportSectionType selSection, final Widget? child) {
                        return ValueListenableBuilder<FileNameStatus>(
                          valueListenable: _fileNameStatus,
                          builder: (final BuildContext context, final FileNameStatus status, final Widget? child) {
                            return Tooltip(
                              waitDuration: AppState.toolTipDuration,
                              message: "Export File",
                              child: IconButton.outlined(
                                icon: FaIcon(
                                  FontAwesomeIcons.check,
                                  size: _options.iconSize,
                                ),
                                onPressed: (status == FileNameStatus.available || status == FileNameStatus.overwrite) ?
                                  () {
                                    if (selSection == ExportSectionType.image)
                                    {
                                      widget.acceptFile(exportData: ImageExportData.fromWithConcreteData(other: ImageExportData.exportTypeMap[_fileExportType.value]!, scaling: exportScalingValues[_scalingIndex.value], fileName: _fileName.value, directory: _appState.exportDir), exportType: _fileExportType.value);
                                    }
                                    else if (selSection == ExportSectionType.palette)
                                    {
                                      widget.acceptPalette(saveData: PaletteExportData.fromWithConcreteData(other: PaletteExportData.exportTypeMap[_paletteExportType.value]!, fileName: _fileName.value, directory: _appState.exportDir), paletteType: _paletteExportType.value);
                                    }
                                    else if (selSection == ExportSectionType.animation)
                                    {
                                      widget.acceptAnimation(exportData: AnimationExportData.fromWithConcreteData(other: AnimationExportData.exportTypeMap[_animationExportType.value]!, scaling: exportScalingValues[_scalingIndex.value], fileName: _fileName.value, directory: _appState.exportDir, loopOnly: _animationSectionOnly.value), exportType: _animationExportType.value);
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
