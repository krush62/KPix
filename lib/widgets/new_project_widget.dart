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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas_size_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class NewProjectWidget extends StatefulWidget
{
  final Function() dismiss;
  final NewFileFn accept;
  const NewProjectWidget({super.key, required this.dismiss, required this.accept});

  @override
  State<NewProjectWidget> createState() => _NewProjectWidgetState();
}

class _NewProjectWidgetState extends State<NewProjectWidget>
{
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final CanvasSizeOptions _sizeOptions = GetIt.I.get<PreferenceManager>().canvasSizeOptions;
  final ValueNotifier<int> _width = ValueNotifier(64);
  final ValueNotifier<int> _height = ValueNotifier(64);
  static const double _maxPreviewHeight = 128;
  static const double _maxPreviewWidth = 192;

  void _widthInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null)
    {
      final int val = min(max(parsedVal, _sizeOptions.sizeMin), _sizeOptions.sizeMax);
      _width.value = val;
    }
  }

  void _heightInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null)
    {
      final int val = min(max(parsedVal, _sizeOptions.sizeMin), _sizeOptions.sizeMax);
      _height.value = val;
    }
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Create New Project", style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: _options.padding),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: _maxPreviewHeight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text("Width", style: Theme.of(context).textTheme.titleSmall)
                              ),
                              Expanded(
                                flex: 4,
                                child: ValueListenableBuilder<int>(
                                  valueListenable: _width,
                                  builder: (final BuildContext context, final int width, final Widget? child) {
                                    return Slider(
                                      value: width.toDouble(),
                                      min: _sizeOptions.sizeMin.toDouble(),
                                      max: _sizeOptions.sizeMax.toDouble(),
                                      onChanged: (final double newVal) {_width.value = newVal.toInt();},
                                    );
                                  },
                                )
                              ),
                              Expanded(
                                flex: 1,
                                child: ValueListenableBuilder<int>(
                                  valueListenable: _width,
                                  builder: (final BuildContext context, final int width, final Widget? child) {
                                    final TextEditingController controller = TextEditingController(text: width.toString());
                                    controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                    return TextField(
                                      textAlign: TextAlign.end,
                                      controller: controller,
                                      onChanged: (final String newVal) {_widthInputChanged(newVal: newVal);},
                                    );
                                  },
                                )
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                  flex: 1,
                                  child: Text("Height", style: Theme.of(context).textTheme.titleSmall)
                              ),
                              Expanded(
                                flex: 4,
                                child: ValueListenableBuilder<int>(
                                  valueListenable: _height,
                                  builder: (final BuildContext context, final int height, final Widget? child) {
                                    return Slider(
                                      value: height.toDouble(),
                                      min: _sizeOptions.sizeMin.toDouble(),
                                      max: _sizeOptions.sizeMax.toDouble(),
                                      onChanged: (final double newVal) {_height.value = newVal.toInt();},
                                    );
                                  },
                                )
                              ),
                              Expanded(
                                flex: 1,
                                child: ValueListenableBuilder<int>(
                                  valueListenable: _height,
                                  builder: (final BuildContext context, final int height, final Widget? child) {
                                    final TextEditingController controller = TextEditingController(text: height.toString());
                                    controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                    return TextField(
                                      textAlign: TextAlign.end,
                                      controller: controller,
                                      onChanged: (final String newVal) {_heightInputChanged(newVal: newVal);},
                                    );
                                  },
                                )
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Stack(
                        children: [
                          ValueListenableBuilder<int>(
                            valueListenable: _width,
                            builder: (final BuildContext context, final int width, final Widget? child) {
                              return ValueListenableBuilder<int>(
                                valueListenable: _height,
                                builder: (final BuildContext context, final int height, final Widget? child) {
                                  final double scaledWidth = _maxPreviewWidth / width;
                                  final double scaledHeight = _maxPreviewHeight / height;
                                  final double scale = min(scaledWidth, scaledHeight);
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColorLight,
                                      border: Border.all(
                                        color: Theme.of(context).primaryColorDark,
                                        width: _options.borderWidth,
                                      ),
                                    ),
                                    width: width * scale,
                                    height: height * scale,
                                  );
                                }
                              );
                            },
                          )
                        ]
                      )
                    )
                  )
                ],
              ),
              SizedBox(height: _options.padding * 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    flex: 1,
                    child: IconButton.outlined(
                      icon: FaIcon(
                        FontAwesomeIcons.powerOff,
                        size: _options.iconSize,
                      ),
                      onPressed: () {
                        widget.dismiss();
                      },
                    )
                  ),
                  SizedBox(width: _options.padding),
                  Expanded(
                    flex: 1,
                    child: IconButton.outlined(
                      icon: FaIcon(
                        FontAwesomeIcons.check,
                        size: _options.iconSize,
                      ),
                      onPressed: () {
                        widget.accept(size: CoordinateSetI(x: _width.value, y: _height.value));
                      },
                    )
                  ),
                ]
              ),
            ]
          )
        )
      )
    );
  }
}



