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
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/canvas/canvas_size_widget.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

class NewProjectWidget extends StatefulWidget
{
  final Function() dismiss;
  final NewFileFn accept;
  final Function() open;
  const NewProjectWidget({super.key, required this.dismiss, required this.accept, required this.open});

  @override
  State<NewProjectWidget> createState() => _NewProjectWidgetState();
}

class _NewProjectWidgetState extends State<NewProjectWidget>
{
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final CanvasSizeOptions _sizeOptions = GetIt.I.get<PreferenceManager>().canvasSizeOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final ValueNotifier<int> _width = ValueNotifier<int>(64);
  final ValueNotifier<int> _height = ValueNotifier<int>(64);
  static const double _maxPreviewHeight = 128;
  static const double _maxPreviewWidth = 224;
  final ValueNotifier<bool> _locked = ValueNotifier<bool>(false);
  double _aspectRatio = 1.0;

  void _setAspectRatio()
  {
    _aspectRatio = _width.value.toDouble() / _height.value.toDouble();
  }

  void _widthInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null)
    {
      _changeWidth(newWidth: parsedVal);
    }
  }

  void _heightInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null)
    {
      _changeHeight(newHeight: parsedVal);
    }
  }

  void _setResolutionViaButton({required final int width, required final int height})
  {
    _width.value = width.clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
    _height.value = height.clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
    _setAspectRatio();
  }

  void _changeWidth({required final int newWidth})
  {
    _width.value = newWidth.clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
    if (_locked.value)
    {
      _height.value = (_width.value / _aspectRatio).toInt().clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
    }
  }

  void _changeHeight({required final int newHeight})
  {
    _height.value = newHeight.clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
    if (_locked.value)
    {
      _width.value = (_height.value * _aspectRatio).toInt().clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
    }
  }

  @override
  Widget build(final BuildContext context)
  {
    return KPixAnimationWidget(
      constraints: BoxConstraints(
        minHeight: _options.minHeight,
        minWidth: _options.minWidth,
        maxHeight: _options.maxHeight,
        maxWidth: _options.maxWidth * 1.2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text("Create New Project", style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: _options.padding / 2),
          Divider(height: _options.padding / 4, thickness: _options.padding / 4, color: Theme.of(context).primaryColorLight,),
          SizedBox(height: _options.padding / 2),
          Text("Presets", style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: _options.padding / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(child: Text("1:1", style: Theme.of(context).textTheme.titleMedium)),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 16, height: 16);}, child: const Text("16x16"))),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 32, height: 32);}, child: const Text("32x32"))),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 64, height: 64);}, child: const Text("64x64"))),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 100, height: 100);}, child: const Text("100x100"))),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 128, height: 128);}, child: const Text("128x128"))),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 256, height: 256);}, child: const Text("256x256"))),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 512, height: 512);}, child: const Text("512x512"))),
              ],
          ),
          SizedBox(height: _options.padding),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(child: Text("4:3", style: Theme.of(context).textTheme.titleMedium)),
                SizedBox(width: _options.padding),
                Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 96, height: 72);}, child: const Text("96x72"))),
                SizedBox(width: _options.padding),
                Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 128, height: 96);}, child: const Text("128x96"))),
                SizedBox(width: _options.padding),
                Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 160, height: 120);}, child: const Text("160x120"))),
                SizedBox(width: _options.padding),
                Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 192, height: 144);}, child: const Text("192x144"))),
                SizedBox(width: _options.padding),
                Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 256, height: 192);}, child: const Text("256x192"))),
                SizedBox(width: _options.padding),
                Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 320, height: 240);}, child: const Text("320x240"))),
                SizedBox(width: _options.padding),
                Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 480, height: 360);}, child: const Text("480x360"))),
              ],
          ),
          SizedBox(height: _options.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(child: Text("16:9", style: Theme.of(context).textTheme.titleMedium)),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 128, height: 72);}, child: const Text("128x72"))),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 160, height: 90);}, child: const Text("160x90"))),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 192, height: 108);}, child: const Text("192x108"))),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 256, height: 144);}, child: const Text("256x144"))),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 320, height: 180);}, child: const Text("320x180"))),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 384, height: 216);}, child: const Text("384x216"))),
              SizedBox(width: _options.padding),
              Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: 480, height: 270);}, child: const Text("480x270"))),
            ],
          ),
          SizedBox(height: _options.padding),
          Divider(height: _options.padding / 4, thickness: _options.padding / 4, color: Theme.of(context).primaryColorLight,),
          SizedBox(height: _options.padding / 2),
          Text("Custom", style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: _options.padding / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: _maxPreviewHeight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text("Width", style: Theme.of(context).textTheme.titleSmall),
                          ),
                          Expanded(
                            flex: 4,
                            child: ValueListenableBuilder<int>(
                              valueListenable: _width,
                              builder: (final BuildContext context, final int width, final Widget? child) {
                                return KPixSlider(
                                  value: width.toDouble(),
                                  trackHeight: 32,
                                  min: _sizeOptions.sizeMin.toDouble(),
                                  max: _sizeOptions.sizeMax.toDouble(),
                                  onChanged: (final double newVal) {_changeWidth(newWidth: newVal.toInt());},
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: _options.padding * 2,
                          ),
                          Expanded(
                            child: ValueListenableBuilder<int>(
                              valueListenable: _width,
                              builder: (final BuildContext context, final int width, final Widget? child) {
                                final TextEditingController controller = TextEditingController(text: width.toString());
                                controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                return TextField(
                                  focusNode: _hotkeyManager.newProjectWidthTextFocus,
                                  textAlign: TextAlign.end,
                                  controller: controller,
                                  onChanged: (final String newVal) {_widthInputChanged(newVal: newVal);},
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                              child: Text("Height", style: Theme.of(context).textTheme.titleSmall),
                          ),
                          Expanded(
                            flex: 4,
                            child: ValueListenableBuilder<int>(
                              valueListenable: _height,
                              builder: (final BuildContext context, final int height, final Widget? child) {
                                return KPixSlider(
                                  value: height.toDouble(),
                                  trackHeight: 32,
                                  min: _sizeOptions.sizeMin.toDouble(),
                                  max: _sizeOptions.sizeMax.toDouble(),
                                  onChanged: (final double newVal) {_changeHeight(newHeight: newVal.toInt());},
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: _options.padding * 2,
                          ),
                          Expanded(
                            child: ValueListenableBuilder<int>(
                              valueListenable: _height,
                              builder: (final BuildContext context, final int height, final Widget? child) {
                                final TextEditingController controller = TextEditingController(text: height.toString());
                                controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                return TextField(
                                  focusNode: _hotkeyManager.newProjectHeightTextFocus,
                                  textAlign: TextAlign.end,
                                  controller: controller,
                                  onChanged: (final String newVal) {_heightInputChanged(newVal: newVal);},
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: _options.padding),
              ValueListenableBuilder<bool>(
                valueListenable: _locked,
                builder: (final BuildContext context, final bool locked, final Widget? child)
                {
                  return IconButton.outlined(
                    constraints: BoxConstraints(
                      minHeight: _options.iconSize * 2.5,
                      minWidth: _options.iconSize,
                      maxHeight: _options.iconSize * 2.5,
                      maxWidth: _options.iconSize,
                    ),
                    icon: FaIcon(
                      locked ? FontAwesomeIcons.lock : FontAwesomeIcons.lockOpen,
                      size: _options.iconSize / 2,
                    ),
                    style: ButtonStyle(
                      tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: locked
                          ? WidgetStatePropertyAll<Color?>(
                        Theme.of(context)
                            .primaryColorLight,)
                          : null,
                      iconColor: locked
                          ? WidgetStatePropertyAll<Color?>(
                        Theme.of(context)
                            .primaryColor,)
                          : null,
                    ),
                    onPressed: () {
                      _locked.value = !_locked.value;
                      _setAspectRatio();
                    },
                  );
                },
              ),
              Expanded(
                child: Center(
                  child: Stack(
                    children: <Widget>[
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
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _options.padding / 2),
          Divider(height: _options.padding / 4, thickness: _options.padding / 4, color: Theme.of(context).primaryColorLight,),
          SizedBox(height: _options.padding),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Expanded(
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
              SizedBox(width: _options.padding),
              Expanded(
                  child: IconButton.outlined(
                    icon: FaIcon(
                      FontAwesomeIcons.folderOpen,
                      size: _options.iconSize,
                    ),
                    onPressed: () {
                      widget.open();
                    },
                  ),
              ),
              SizedBox(width: _options.padding),
              Expanded(
                child: IconButton.outlined(
                  icon: FaIcon(
                    FontAwesomeIcons.check,
                    size: _options.iconSize,
                  ),
                  onPressed: () {
                    widget.accept(size: CoordinateSetI(x: _width.value, y: _height.value));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
