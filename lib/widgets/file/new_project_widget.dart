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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
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
  final Function()? dismiss;
  final NewFileFn accept;
  final Function() open;
  const NewProjectWidget({super.key, this.dismiss, required this.accept, required this.open});

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
  final TextEditingController _textWidthController = TextEditingController();
  final TextEditingController _textHeightController = TextEditingController();

  @override
  void initState()
  {
    super.initState();
    _hotkeyManager.newProjectWidthTextFocus.addListener(_widthFocusChanged);
    _hotkeyManager.newProjectHeightTextFocus.addListener(_heightFocusChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _hotkeyManager.newProjectWidthTextFocus.removeListener(_widthFocusChanged);
    _hotkeyManager.newProjectHeightTextFocus.removeListener(_heightFocusChanged);
  }

  void _widthFocusChanged()
  {
    if (!_hotkeyManager.newProjectWidthTextFocus.hasFocus)
    {
      _textWidthController.text = _width.value.toString();
    }
  }

  void _heightFocusChanged()
  {
    if (!_hotkeyManager.newProjectHeightTextFocus.hasFocus)
    {
      _textHeightController.text = _height.value.toString();
    }
  }

  void _setAspectRatio()
  {
    _aspectRatio = _width.value.toDouble() / _height.value.toDouble();
  }
  void _sizeInputChanged({required final String newVal, required final Function({required int newVal}) changeFunc})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null && parsedVal >= _sizeOptions.sizeMin && parsedVal <= _sizeOptions.sizeMax)
    {
      changeFunc(newVal: parsedVal);
    }
  }

  void _setResolutionViaButton({required final int width, required final int height})
  {
    _width.value = width.clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
    _height.value = height.clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
    _setAspectRatio();
  }

  void _changeWidth({required final int newVal})
  {
    _width.value = newVal.clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
    if (_locked.value)
    {
      _height.value = (_width.value / _aspectRatio).toInt().clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
    }
  }

  void _changeHeight({required final int newVal})
  {
    _height.value = newVal.clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
    if (_locked.value)
    {
      _width.value = (_height.value * _aspectRatio).toInt().clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
    }
  }

  Row _getSizeRow({required final List<CoordinateSetI> sizes, required final String title, required final double padding})
  {
    final List<Widget> items = <Widget>[];
    items.add(Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center)));
    for (final CoordinateSetI resolution in sizes)
    {
      items.add(SizedBox(width: padding));
      items.add(Expanded(flex: 2, child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: resolution.x, height: resolution.y);}, child: Text("${resolution.x}x${resolution.y}"))));

    }
    return  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, mainAxisSize: MainAxisSize.min, children: items);
  }

  Row _getInputRow({
    required final String title,
    required final ValueNotifier<int> notifier,
    required final TextEditingController controller,
    required final FocusNode focusNode,
    required final Function({required int newVal}) changeFunc,
  })
  {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(
          flex: 4,
          child: ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (final BuildContext context, final int val, final Widget? child) {
              return KPixSlider(
                value: val.toDouble(),
                trackHeight: 32,
                min: _sizeOptions.sizeMin.toDouble(),
                max: _sizeOptions.sizeMax.toDouble(),
                onChanged: (final double newVal) {changeFunc(newVal: newVal.toInt());},
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
            valueListenable: notifier,
            builder: (final BuildContext context, final int val, final Widget? child) {
              controller.text = val.toString();
              controller.selection = TextSelection.collapsed(offset: controller.text.length);
              return TextField(
                focusNode: focusNode,
                textAlign: TextAlign.end,
                controller: controller,
                onChanged: (final String newVal) {_sizeInputChanged(newVal: newVal, changeFunc: changeFunc);},
              );
            },
          ),
        ),
      ],
    );
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
          _getSizeRow(
              sizes: <CoordinateSetI>[
                CoordinateSetI(x: 16, y: 16),
                CoordinateSetI(x: 32, y: 32),
                CoordinateSetI(x: 64, y: 64),
                CoordinateSetI(x: 100, y: 100),
                CoordinateSetI(x: 128, y: 128),
                CoordinateSetI(x: 256, y: 256),
                CoordinateSetI(x: 512, y: 512),
              ],
              title: "1:1",
              padding: _options.padding,
          ),
          SizedBox(height: _options.padding),
          _getSizeRow(
              sizes: <CoordinateSetI>[
                CoordinateSetI(x: 96, y: 72),
                CoordinateSetI(x: 128, y: 96),
                CoordinateSetI(x: 160, y: 120),
                CoordinateSetI(x: 192, y: 144),
                CoordinateSetI(x: 256, y: 192),
                CoordinateSetI(x: 320, y: 240),
                CoordinateSetI(x: 480, y: 360),
              ],
              title: "4:3",
              padding: _options.padding,
          ),
          SizedBox(height: _options.padding),
          _getSizeRow(
              sizes: <CoordinateSetI>[
                CoordinateSetI(x: 128, y: 72),
                CoordinateSetI(x: 160, y: 90),
                CoordinateSetI(x: 192, y: 108),
                CoordinateSetI(x: 256, y: 144),
                CoordinateSetI(x: 320, y: 180),
                CoordinateSetI(x: 384, y: 216),
                CoordinateSetI(x: 480, y: 270),
              ],
              title: "16:9",
              padding: _options.padding,
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
                      _getInputRow(title: "Width", notifier: _width, controller: _textWidthController, focusNode: _hotkeyManager.newProjectWidthTextFocus, changeFunc: _changeWidth),
                      _getInputRow(title: "Height", notifier: _height, controller: _textHeightController, focusNode: _hotkeyManager.newProjectHeightTextFocus, changeFunc: _changeHeight),
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
                    icon: Icon(
                      locked ? TablerIcons.lock : TablerIcons.lock_open_2,
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
              if (widget.dismiss != null) ...<Widget>[
                Expanded(
                  child: IconButton.outlined(
                    icon: const Icon(
                      TablerIcons.x,
                    ),
                    onPressed: () {
                      widget.dismiss!();
                    },
                  ),
                ),
                SizedBox(width: _options.padding),
              ],
              Expanded(
                  child: IconButton.outlined(
                    icon: const Icon(
                      TablerIcons.folder_open,
                    ),
                    onPressed: () {
                      widget.open();
                    },
                  ),
              ),
              SizedBox(width: _options.padding),
              Expanded(
                child: IconButton.outlined(
                  icon: const Icon(
                    TablerIcons.check,
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
