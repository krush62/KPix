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

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/reference_layer_state.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/reference_image_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

class ReferenceLayerSettings
{
  final int opacityDefault;
  final int opacityMin;
  final int opacityMax;
  final double aspectRatioDefault;
  final double aspectRatioMin;
  final double aspectRatioMax;
  final int zoomDefault;
  final int zoomMin;
  final int zoomMax;
  final double zoomCurveExponent;

  ReferenceLayerSettings
  (
      {required this.opacityDefault,
      required this.opacityMin,
      required this.opacityMax,
      required this.aspectRatioDefault,
      required this.aspectRatioMin,
      required this.aspectRatioMax,
      required this.zoomDefault,
      required this.zoomMin,
      required this.zoomMax,
      required this.zoomCurveExponent}
  );
}

class ReferenceLayerOptionsWidget extends StatefulWidget
{
  final ReferenceLayerState referenceState;
  const ReferenceLayerOptionsWidget({super.key, required this.referenceState});

  @override
  State<ReferenceLayerOptionsWidget> createState() => _ReferenceLayerOptionsWidgetState();}

class _ReferenceLayerOptionsWidgetState extends State<ReferenceLayerOptionsWidget>
{
  final ToolSettingsWidgetOptions _toolSettingsWidgetOptions = GetIt.I.get<PreferenceManager>().toolSettingsWidgetOptions;
  final ReferenceLayerSettings _refSettings = GetIt.I.get<PreferenceManager>().referenceLayerSettings;
  final ReferenceImageManager _refManager = GetIt.I.get<ReferenceImageManager>();

  void _onLoadPressed()
  {
    FileHandler.getPathAndDataForImage().then((final (String?, Uint8List?) loadData,) {
      _loadPathChosen(loadPath: loadData.$1, imageData: loadData.$2);
    });
  }

  void _loadPathChosen({required final String? loadPath, required final Uint8List? imageData})
  {
    if (loadPath != null && loadPath.isNotEmpty)
    {
      _refManager.loadImageFile(path: loadPath, imageData: imageData).then((final ReferenceImage? img)
      {
        if (img != null)
        {
          final ReferenceImage? oldImage = widget.referenceState.imageNotifier.value;
          widget.referenceState.imageNotifier.value = img;
          widget.referenceState.thumbnail.value = img.image;
          final CoordinateSetI canvasSize = GetIt.I.get<AppState>().canvasSize;
          final double targetZoomX = canvasSize.x.toDouble() / (widget.referenceState.image!.image.width.toDouble() * widget.referenceState.aspectRatioFactorX);
          final double targetZoomY = canvasSize.y.toDouble() / (widget.referenceState.image!.image.height.toDouble() * widget.referenceState.aspectRatioFactorY);
          if (targetZoomX < targetZoomY)
          {
            _fitHorizontal();
          }
          else
          {
            _fitVertical();
          }
          if (oldImage != null) {
            GetIt.I.get<ReferenceImageManager>().removeImage(refImage: oldImage);
          }
          GetIt.I.get<HistoryManager>().addState(appState: GetIt.I.get<AppState>(), identifier: HistoryStateTypeIdentifier.layerChangeReferenceImage);
        }
        else
        {
          GetIt.I.get<AppState>().showMessage(text: "Could not load image from $loadPath");
        }
      });
    }
  }

  void _resetAspectRatio()
  {
    widget.referenceState.aspectRatioNotifier.value =
        _refSettings.aspectRatioDefault;
  }

  void _fitHorizontal()
  {
    if (widget.referenceState.image != null)
    {
      final CoordinateSetI canvasSize = GetIt.I.get<AppState>().canvasSize;
      final double targetZoom = canvasSize.x.toDouble() / (widget.referenceState.image!.image.width.toDouble() * widget.referenceState.aspectRatioFactorX);
      widget.referenceState.setZoomSliderFromZoomFactor(factor: targetZoom);
      widget.referenceState.offsetXNotifier.value = 0;
      widget.referenceState.offsetYNotifier.value = (canvasSize.y - (widget.referenceState.image!.image.height.toDouble() * targetZoom * widget.referenceState.aspectRatioFactorY)) / 2.0;
    }
  }

  void _fitVertical()
  {
    if (widget.referenceState.image != null)
    {
      final CoordinateSetI canvasSize = GetIt.I.get<AppState>().canvasSize;
      final double targetZoom = canvasSize.y.toDouble() / (widget.referenceState.image!.image.height.toDouble() * widget.referenceState.aspectRatioFactorY);
      widget.referenceState.setZoomSliderFromZoomFactor(factor: targetZoom);
      widget.referenceState.offsetYNotifier.value = 0;
      widget.referenceState.offsetXNotifier.value = (canvasSize.x - (widget.referenceState.image!.image.width.toDouble() * targetZoom * widget.referenceState.aspectRatioFactorX)) / 2.0;
    }
  }

  void _fill()
  {
    if (widget.referenceState.image != null)
    {
      final CoordinateSetI canvasSize = GetIt.I.get<AppState>().canvasSize;
      widget.referenceState.offsetXNotifier.value = 0;
      widget.referenceState.offsetYNotifier.value = 0;
      final double targetAspectRatioX = canvasSize.x.toDouble() / canvasSize.y.toDouble();
      final double referenceAspectRatioX = widget.referenceState.image!.image.width.toDouble() / widget.referenceState.image!.image.height.toDouble();
      final double scalingFactor = targetAspectRatioX / referenceAspectRatioX;
      if (scalingFactor > 1)
      {
        widget.referenceState.aspectRatioNotifier.value = (targetAspectRatioX - 1).clamp(_refSettings.aspectRatioMin, _refSettings.aspectRatioMax);
      }
      else
      {
        widget.referenceState.aspectRatioNotifier.value = (-(1.0 / scalingFactor) + 1).clamp(_refSettings.aspectRatioMin, _refSettings.aspectRatioMax);
      }
      final double targetZoom = canvasSize.x.toDouble() / (widget.referenceState.image!.image.width.toDouble() * widget.referenceState.aspectRatioFactorX);
      widget.referenceState.setZoomSliderFromZoomFactor(factor: targetZoom);
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Material(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: EdgeInsets.all(_toolSettingsWidgetOptions.padding),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: ValueListenableBuilder<ReferenceImage?>(
            valueListenable: widget.referenceState.imageNotifier,
            builder: (final BuildContext context,
                final ReferenceImage? refImg, final Widget? child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "File",
                            style: Theme.of(context).textTheme.labelLarge,
                          )
                        ),
                      ),
                      Expanded(
                        flex: _toolSettingsWidgetOptions.columnWidthRatio,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  refImg == null ? "<NO FILE LOADED>" : Helper.extractFilenameFromPath(path: refImg.path),
                                  style: Theme.of(context).textTheme.labelSmall,
                                )
                              ),
                            ),
                            SizedBox(
                              width: _toolSettingsWidgetOptions.padding,
                            ),
                            Expanded(
                              flex: 1,
                              child: Tooltip(
                                waitDuration: AppState.toolTipDuration,
                                message: "Open Reference File",
                                child: IconButton.outlined(
                                  onPressed: _onLoadPressed,
                                  icon: FaIcon(FontAwesomeIcons.image)
                                ),
                              )
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Opacity",
                            style: Theme.of(context).textTheme.labelLarge,
                          )
                        ),
                      ),
                      Expanded(
                        flex: _toolSettingsWidgetOptions.columnWidthRatio,
                        child: ValueListenableBuilder<int>(
                          valueListenable:
                              widget.referenceState.opacityNotifier,
                          builder: (final BuildContext context,
                              final int opacity, final Widget? child) {
                            return KPixSlider(
                              value: opacity.toDouble(),
                              min: _refSettings.opacityMin.toDouble(),
                              max: _refSettings.opacityMax.toDouble(),
                              divisions: _refSettings.opacityMax - _refSettings.opacityMin,
                              onChanged: refImg == null ? null : (final double newVal) {
                                widget.referenceState.opacityNotifier.value = newVal.round();
                              },
                              textStyle: Theme.of(context).textTheme.bodyLarge!,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Aspect Ratio",
                            style: Theme.of(context).textTheme.labelLarge,
                          )
                        ),
                      ),
                      Expanded(
                        flex: _toolSettingsWidgetOptions.columnWidthRatio,
                        child: Row(
                          children: [
                            Expanded(
                              child: ValueListenableBuilder<double>(
                                valueListenable:
                                    widget.referenceState.aspectRatioNotifier,
                                builder: (final BuildContext context,
                                    final double aspectRatio,
                                    final Widget? child) {
                                  return KPixSlider(
                                    value: aspectRatio.toDouble(),
                                    min: _refSettings.aspectRatioMin
                                        .toDouble(),
                                    max: _refSettings.aspectRatioMax
                                        .toDouble(),
                                    onChanged: refImg == null ? null : (final double newVal) {
                                      widget.referenceState.aspectRatioNotifier.value = newVal;
                                    },
                                    decimals: 2,
                                    textStyle: Theme.of(context).textTheme.bodyLarge!,
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: _toolSettingsWidgetOptions.padding,),
                            Tooltip(
                              waitDuration: AppState.toolTipDuration,
                              message: "Reset Aspect Ratio",
                              child: IconButton.outlined(
                                onPressed: refImg == null ? null: _resetAspectRatio,
                                icon: FaIcon(FontAwesomeIcons.arrowRotateLeft),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Zoom",
                            style: Theme.of(context).textTheme.labelLarge,
                          )
                        ),
                      ),
                      Expanded(
                        flex: _toolSettingsWidgetOptions.columnWidthRatio,
                        child: ValueListenableBuilder<int>(
                          valueListenable: widget.referenceState.zoomNotifier,
                          builder: (final BuildContext context,
                              final int zoom, final Widget? child) {
                            return KPixSlider(
                              value: zoom.toDouble(),
                              min: _refSettings.zoomMin.toDouble(),
                              max: _refSettings.zoomMax.toDouble(),
                              divisions: _refSettings.zoomMax - _refSettings.zoomMin,
                              onChanged: refImg == null ? null : (final double newVal) {
                                widget.referenceState.zoomNotifier.value = newVal.round();
                              },
                              label: "${(zoom / 10.0).toStringAsFixed(1)}%",
                              textStyle: Theme.of(context).textTheme.bodyLarge!,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Tooltip(
                          waitDuration: AppState.toolTipDuration,
                          message: "Expand horizontally and center by keeping the current aspect ratio",
                          child: IconButton.outlined(
                            onPressed: refImg == null ? null : _fitHorizontal,
                            icon:
                              FaIcon(FontAwesomeIcons.arrowsLeftRight)
                          ),
                        )
                      ),
                      SizedBox(width: _toolSettingsWidgetOptions.padding),
                      Expanded(
                        flex: 1,
                        child: Tooltip(
                          waitDuration: AppState.toolTipDuration,
                          message: "Expand vertically and center by keeping the current aspect ratio",
                          child: IconButton.outlined(
                            onPressed: refImg == null ? null : _fitVertical,
                            icon: FaIcon(FontAwesomeIcons.arrowsUpDown)
                          ),
                        ),
                      ),
                      SizedBox(width: _toolSettingsWidgetOptions.padding),
                      Expanded(
                        flex: 1,
                        child: Tooltip(
                          waitDuration: AppState.toolTipDuration,
                          message: "Fits the image into the canvas (changes aspect ratio)",
                          child: IconButton.outlined(
                            onPressed: refImg == null ? null : _fill,
                            icon: FaIcon(
                                FontAwesomeIcons.arrowsUpDownLeftRight),
                          ),
                        )
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      )
    );
  }
}
