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
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';


class CanvasSizeOptions
{
  final int sizeMin;
  final int sizeMax;
  final int previewSize;

  CanvasSizeOptions({
    required this.sizeMin,
    required this.sizeMax,
    required this.previewSize,
  });
}

class CanvasSizeWidget extends StatefulWidget
{
  final Function() dismiss;
  final CanvasSizeFn accept;
  const CanvasSizeWidget({required this.dismiss, required this.accept, super.key});

  @override
  State<StatefulWidget> createState() => CanvasSizeWidgetState();

}

class CanvasSizeWidgetState extends State<CanvasSizeWidget>
{
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final CanvasSizeOptions _sizeOptions = GetIt.I.get<PreferenceManager>().canvasSizeOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final AppState _appState = GetIt.I.get<AppState>();
  final ValueNotifier<int> _width = ValueNotifier<int>(0);
  final ValueNotifier<int> _height = ValueNotifier<int>(0);
  final ValueNotifier<int> _offsetX = ValueNotifier<int>(0);
  final ValueNotifier<int> _offsetY = ValueNotifier<int>(0);
  final ValueNotifier<int> _minOffsetX = ValueNotifier<int>(0);
  final ValueNotifier<int> _maxOffsetX = ValueNotifier<int>(0);
  final ValueNotifier<int> _minOffsetY = ValueNotifier<int>(0);
  final ValueNotifier<int> _maxOffsetY = ValueNotifier<int>(0);
  double _scalingFactor = 1.0;
  final ValueNotifier<ui.Image?> _image = ValueNotifier<ui.Image?>(null);
  final TextEditingController _textControllerWidth = TextEditingController();
  final TextEditingController _textControllerHeight = TextEditingController();
  final TextEditingController _textControllerOffsetX = TextEditingController();
  final TextEditingController _textControllerOffsetY = TextEditingController();

  @override
  void initState()
  {
    super.initState();
    _width.value = _appState.canvasSize.x;
    _height.value = _appState.canvasSize.y;
    _setSize();
    final Frame frame = _appState.timeline.selectedFrame!;
    getImageFromLayers(canvasSize: _appState.canvasSize, layerCollection: frame.layerList, selection: _appState.selectionState.selection, frame: frame).then((final ui.Image img){_image.value = img;});
    _hotkeyManager.canvasSizeWidthTextFocus.addListener(_widthFocusChanged);
    _hotkeyManager.canvasSizeHeightTextFocus.addListener(_heightFocusChanged);
    _hotkeyManager.canvasSizeOffsetXTextFocus.addListener(_offsetXFocusChanged);
    _hotkeyManager.canvasSizeOffsetYTextFocus.addListener(_offsetYFocusChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _hotkeyManager.canvasSizeWidthTextFocus.removeListener(_widthFocusChanged);
    _hotkeyManager.canvasSizeHeightTextFocus.removeListener(_heightFocusChanged);
    _hotkeyManager.canvasSizeOffsetXTextFocus.removeListener(_offsetXFocusChanged);
    _hotkeyManager.canvasSizeOffsetYTextFocus.removeListener(_offsetYFocusChanged);
  }

  void _widthFocusChanged()
  {
    if (!_hotkeyManager.canvasSizeWidthTextFocus.hasFocus)
    {
      _textControllerWidth.text = _width.value.toString();
    }
  }

  void _heightFocusChanged()
  {
    if (!_hotkeyManager.canvasSizeHeightTextFocus.hasFocus)
    {
      _textControllerHeight.text = _height.value.toString();
    }
  }

  void _offsetXFocusChanged()
  {
    if (!_hotkeyManager.canvasSizeOffsetXTextFocus.hasFocus)
    {
      _textControllerOffsetX.text = _offsetX.value.toString();
    }
  }

  void _offsetYFocusChanged()
  {
    if (!_hotkeyManager.canvasSizeOffsetYTextFocus.hasFocus)
    {
      _textControllerOffsetY.text = _offsetY.value.toString();
    }
  }


  void _sizeXSliderChanged({required final double newVal})
  {
    _width.value = newVal.round();
    _setSize();
  }

  void _sizeXInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null && parsedVal >= _sizeOptions.sizeMin && parsedVal <= _sizeOptions.sizeMax)
    {
      final int val = parsedVal.clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
      _width.value = val;

    }
    _setSize();
  }

  void _sizeYSliderChanged({required final double newVal})
  {
    _height.value = newVal.round();
    _setSize();
  }

  void _sizeYInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null && parsedVal >= _sizeOptions.sizeMin && parsedVal <= _sizeOptions.sizeMax)
    {
      final int val = parsedVal.clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
      _height.value = val;
    }
    _setSize();
  }

  void _setSize()
  {
    _calculateOffset();
    final int xExp = max(_width.value, _appState.canvasSize.x);
    final int yExp = max(_height.value, _appState.canvasSize.y);
    _scalingFactor = _sizeOptions.previewSize / max(xExp, yExp);
  }

  void _calculateOffset()
  {
    final CoordinateSetI oMin = CoordinateSetI(x: 0, y: 0);
    final CoordinateSetI oMax = CoordinateSetI(x: 0, y: 0);

    if (_width.value < _appState.canvasSize.x)
    {
      oMin.x = _width.value - _appState.canvasSize.x;
      oMax.x = 0;
    }
    else
    {
      oMin.x = 0;
      oMax.x = _width.value - _appState.canvasSize.x;
    }

    if (_height.value < _appState.canvasSize.y)
    {
      oMin.y = _height.value - _appState.canvasSize.y;
      oMax.y = 0;
    }
    else
    {
      oMin.y = 0;
      oMax.y = _height.value - _appState.canvasSize.y;
    }
    _minOffsetX.value = oMin.x;
    _minOffsetY.value = oMin.y;
    _maxOffsetX.value = oMax.x;
    _maxOffsetY.value = oMax.y;

    _offsetX.value = _offsetX.value.clamp(_minOffsetX.value, _maxOffsetX.value);
    _offsetY.value = _offsetY.value.clamp(_minOffsetY.value, _maxOffsetY.value);

  }

  void _offsetXSliderChanged({required final double newVal})
  {
    _offsetX.value = newVal.round();
  }

  void _offsetXInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null && parsedVal >= _minOffsetX.value && parsedVal <= _maxOffsetX.value)
    {
      _offsetX.value = parsedVal.clamp(_minOffsetX.value, _maxOffsetX.value);
    }
  }

  void _offsetYSliderChanged({required final double newVal})
  {
    _offsetY.value = newVal.round();
  }

  void _offsetYInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null && parsedVal >= _minOffsetY.value && parsedVal <= _maxOffsetY.value)
    {
      _offsetY.value = parsedVal.clamp(_minOffsetY.value, _maxOffsetY.value);
    }
  }

  void _centerH()
  {
    _offsetX.value = (_minOffsetX.value + _maxOffsetX.value) ~/ 2;
  }

  void _centerV()
  {
    _offsetY.value = (_minOffsetY.value + _maxOffsetY.value) ~/ 2;
  }

  Row _getSizeRow({
    required final String title,
    required final ValueNotifier<int> notifier,
    required final Function({required double newVal}) sliderFunc,
    required final Function({required String newVal}) changeFunc,
    required final FocusNode focusNode,
    required final TextEditingController textController,
  })
  {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(title),
        ),
        Expanded(
          flex: 7,
          child: ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (final BuildContext context, final int value, final Widget? child) {
              return KPixSlider(
                onChanged: (final double newVal) {sliderFunc(newVal: newVal);},
                value: value.toDouble(),
                min: _sizeOptions.sizeMin.toDouble(),
                max: _sizeOptions.sizeMax.toDouble(),
                textStyle: Theme.of(context).textTheme.bodyLarge!,
              );
            },
          ),
        ),
        SizedBox(width: _options.padding),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (final BuildContext context, final int value, final Widget? child) {
              textController.text = value.toString();
              textController.selection = TextSelection.collapsed(offset: textController.text.length);
              return TextField(
                focusNode: focusNode,
                textAlign: TextAlign.end,
                controller: textController,
                onChanged: (final String newVal) {changeFunc(newVal: newVal);},
              );
            },
          ),
        ),
      ],
    );
  }

  ValueListenableBuilder<int> _getOffsetRow({
    required final String title,
    required final ValueNotifier<int> notifier,
    required final TextEditingController textController,
    required final ValueNotifier<int> minOffsetNotifier,
    required final ValueNotifier<int> maxOffsetNotifier,
    required final FocusNode focusNode,
    required final Function({required double newVal}) sliderFunc,
    required final Function({required String newVal}) changeFunc,
})
  {
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (final BuildContext context0, final int offsetVal, final Widget? child0) {
        textController.text = offsetVal.toString();
        textController.selection = TextSelection.collapsed(offset: textController.text.length);
        return ValueListenableBuilder<int>(
          valueListenable: minOffsetNotifier,
          builder: (final BuildContext context1, final int minOffset, final Widget? child1) {
            return ValueListenableBuilder<int>(
              valueListenable: maxOffsetNotifier,
              builder: (final BuildContext context2, final int maxOffset, final Widget? child2) {
                return Row(
                  children: <Widget>[
                    Expanded(
                      child:
                      Text(title),
                    ),
                    Expanded(
                      flex: 7,
                      child: KPixSlider(
                        min: minOffset.toDouble(),
                        max: maxOffset.toDouble(),
                        onChanged: (final double newVal) {sliderFunc(newVal: newVal);},
                        value: offsetVal.toDouble(),
                        textStyle: Theme.of(context).textTheme.bodyLarge!,
                      ),
                    ),
                    SizedBox(width: _options.padding),
                    Expanded(
                      child: TextField(
                        focusNode: focusNode,
                        textAlign: TextAlign.end,
                        controller: textController,
                        onChanged: (final String newVal) {changeFunc(newVal: newVal);},
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(final BuildContext context)
  {
    return KPixAnimationWidget(
      constraints: BoxConstraints(
        minHeight: _options.minHeight,
        minWidth: _options.minWidth,
        maxHeight: _options.maxHeight * 1.5,
        maxWidth: _options.maxWidth * 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(_options.padding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Canvas Size", style: Theme.of(context).textTheme.titleLarge),
                      _getSizeRow(
                          title: "Width",
                          notifier: _width,
                          sliderFunc: _sizeXSliderChanged,
                          changeFunc: _sizeXInputChanged,
                          focusNode: _hotkeyManager.canvasSizeWidthTextFocus,
                          textController: _textControllerWidth,
                      ),
                      _getSizeRow(
                        title: "Height",
                        notifier: _height,
                        sliderFunc: _sizeYSliderChanged,
                        changeFunc: _sizeYInputChanged,
                        focusNode: _hotkeyManager.canvasSizeHeightTextFocus,
                        textController: _textControllerHeight,
                      ),
                      SizedBox(height: _options.padding,),
                      Text("Offset", style: Theme.of(context).textTheme.titleLarge),
                      _getOffsetRow(
                          title: "X",
                          notifier: _offsetX,
                          textController: _textControllerOffsetX,
                          minOffsetNotifier: _minOffsetX,
                          maxOffsetNotifier: _maxOffsetX,
                          focusNode: _hotkeyManager.canvasSizeOffsetXTextFocus,
                          sliderFunc: _offsetXSliderChanged,
                          changeFunc: _offsetXInputChanged,
                      ),
                      _getOffsetRow(
                        title: "Y",
                        notifier: _offsetY,
                        textController: _textControllerOffsetY,
                        minOffsetNotifier: _minOffsetY,
                        maxOffsetNotifier: _maxOffsetY,
                        focusNode: _hotkeyManager.canvasSizeOffsetYTextFocus,
                        sliderFunc: _offsetYSliderChanged,
                        changeFunc: _offsetYInputChanged,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: _options.padding * 2,
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ValueListenableBuilder<int>(
                        valueListenable: _width,
                        builder: (final BuildContext context, final int width, final Widget? child) {
                          return ValueListenableBuilder<int>(
                            valueListenable: _height,
                            builder: (final BuildContext context1, final int height, final Widget? child1) {
                              return ValueListenableBuilder<int>(
                                valueListenable: _offsetX,
                                builder: (final BuildContext context, final int offsetX, final Widget? child) {
                                  return ValueListenableBuilder<int>(
                                    valueListenable: _offsetY,
                                    builder: (final BuildContext context2, final int offsetY, final Widget? child) {
                                      final CoordinateSetD scaledCanvasSize = CoordinateSetD(x: _appState.canvasSize.x * _scalingFactor, y: _appState.canvasSize.y * _scalingFactor);
                                      final CoordinateSetD scaledNewSize = CoordinateSetD(x: width * _scalingFactor, y: height * _scalingFactor);

                                      return Stack(
                                        children: <Widget>[
                                          SizedBox(
                                            width: _sizeOptions.previewSize.toDouble(),
                                            height: _sizeOptions.previewSize.toDouble(),
                                          ),
                                          Positioned(
                                            left: (_sizeOptions.previewSize / 2) - (scaledNewSize.x / 2) + (offsetX * _scalingFactor),
                                            top: (_sizeOptions.previewSize / 2) - (scaledNewSize.y / 2) + (offsetY * _scalingFactor),
                                            width: scaledCanvasSize.x,
                                            height: scaledCanvasSize.y,
                                            child: ValueListenableBuilder<ui.Image?>(
                                              valueListenable: _image,
                                              builder: (final BuildContext context, final ui.Image? img, final Widget? child) {
                                                return RawImage(
                                                  fit: BoxFit.fill,
                                                  filterQuality: ui.FilterQuality.none,
                                                  image: img,
                                                );
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            left: (_sizeOptions.previewSize / 2) - (scaledNewSize.x / 2) + (offsetX * _scalingFactor),
                                            top: (_sizeOptions.previewSize / 2) - (scaledNewSize.y / 2) + (offsetY * _scalingFactor),
                                            width: scaledCanvasSize.x,
                                            height: scaledCanvasSize.y,
                                            child: DecoratedBox(

                                              decoration: BoxDecoration(
                                                border: Border.all(color:  Theme.of(context).primaryColorLight, width: 4),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: (_sizeOptions.previewSize / 2) - (scaledNewSize.x / 2),
                                            top: (_sizeOptions.previewSize / 2) - (scaledNewSize.y / 2),
                                            width: scaledNewSize.x,
                                            height: scaledNewSize.y,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                  border: Border.all(color:  Theme.of(context).primaryColorDark, width: 3),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: (_sizeOptions.previewSize / 2) - (scaledNewSize.x / 2),
                                            top: (_sizeOptions.previewSize / 2) - (scaledNewSize.y / 2),
                                            width: scaledNewSize.x,
                                            height: scaledNewSize.y,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                  border: Border.all(color:  Theme.of(context).primaryColorLight),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
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
                              child: IconButton.outlined(
                                icon: Icon(
                                  TablerIcons.layout_align_middle,
                                  size: _options.iconSize,
                                ),
                                onPressed: _centerH,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(_options.padding),
                              child: IconButton.outlined(
                                icon: Transform.rotate(
                                  angle: pi / 2,
                                  child: Icon(
                                    TablerIcons.layout_align_middle,
                                    size: _options.iconSize,
                                  ),
                                ),
                                onPressed: _centerV,
                              ),
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

          SizedBox(height: _options.padding,),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                    icon: Icon(
                      TablerIcons.x,
                      size: _options.iconSize,
                    ),
                    onPressed: () {
                      widget.dismiss();
                    },
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                    icon: Icon(
                      TablerIcons.check,
                      size: _options.iconSize,
                    ),
                    onPressed: () {
                      widget.accept(size: CoordinateSetI(x: _width.value, y: _height.value), offset: CoordinateSetI(x: _offsetX.value, y: _offsetY.value));
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
