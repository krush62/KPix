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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlay_entries.dart';


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
  final ValueNotifier<CoordinateSetI> _size = ValueNotifier<CoordinateSetI>(CoordinateSetI(x: 0, y: 0));
  final ValueNotifier<CoordinateSetI> _offset = ValueNotifier<CoordinateSetI>(CoordinateSetI(x: 0, y: 0));
  final ValueNotifier<CoordinateSetI> _minOffset = ValueNotifier<CoordinateSetI>(CoordinateSetI(x: 0, y: 0));
  final ValueNotifier<CoordinateSetI> _maxOffset = ValueNotifier<CoordinateSetI>(CoordinateSetI(x: 0, y: 0));
  double _scalingFactor = 1.0;
  final ValueNotifier<ui.Image?> _image = ValueNotifier<ui.Image?>(null);

  @override
  void initState()
  {
    super.initState();
    _setSize(newSize: _appState.canvasSize);
    getImageFromLayers(appState: _appState).then((final ui.Image img){_image.value = img;});

  }


  void _sizeXSliderChanged({required final double newVal})
  {
    final CoordinateSetI newCoords = CoordinateSetI(x: newVal.round(), y: _size.value.y);
    _setSize(newSize: newCoords);
  }

  void _sizeXInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null)
    {
      final int val = parsedVal.clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
      final CoordinateSetI newCoords = CoordinateSetI(x: val, y: _size.value.y);
      _setSize(newSize: newCoords);
    }
    else
    {
      final CoordinateSetI newCoords = CoordinateSetI.from(other: _size.value);
      _setSize(newSize: newCoords);
    }
  }

  void _sizeYSliderChanged({required final double newVal})
  {
    final CoordinateSetI newCoords = CoordinateSetI(x: _size.value.x, y: newVal.round());
    _setSize(newSize: newCoords);
  }

  void _sizeYInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null)
    {
      final int val = parsedVal.clamp(_sizeOptions.sizeMin, _sizeOptions.sizeMax);
      final CoordinateSetI newCoords = CoordinateSetI(x: _size.value.x, y: val);
      _setSize(newSize: newCoords);
    }
    else
    {
      final CoordinateSetI newCoords = CoordinateSetI.from(other: _size.value);
      _setSize(newSize: newCoords);
    }
  }

  void _setSize({required final CoordinateSetI newSize})
  {
    _size.value = newSize;
    _calculateOffset();
    final int xExp = max(newSize.x, _appState.canvasSize.x);
    final int yExp = max(newSize.y, _appState.canvasSize.y);
    _scalingFactor = _sizeOptions.previewSize / max(xExp, yExp);
  }

  void _calculateOffset()
  {
    final CoordinateSetI oMin = CoordinateSetI(x: 0, y: 0);
    final CoordinateSetI oMax = CoordinateSetI(x: 0, y: 0);

    if (_size.value.x < _appState.canvasSize.x)
    {
      oMin.x = _size.value.x - _appState.canvasSize.x;
      oMax.x = 0;
    }
    else
    {
      oMin.x = 0;
      oMax.x = _size.value.x - _appState.canvasSize.x;
    }

    if (_size.value.y < _appState.canvasSize.y)
    {
      oMin.y = _size.value.y - _appState.canvasSize.y;
      oMax.y = 0;
    }
    else
    {
      oMin.y = 0;
      oMax.y = _size.value.y - _appState.canvasSize.y;
    }
    _minOffset.value = oMin;
    _maxOffset.value = oMax;

    final CoordinateSetI newOffset = CoordinateSetI.from(other: _offset.value);
    newOffset.x = newOffset.x.clamp(_minOffset.value.x, _maxOffset.value.x);
    newOffset.y = newOffset.y.clamp(_minOffset.value.y, _maxOffset.value.y);
    _offset.value = newOffset;

  }

  void _offsetXSliderChanged({required final double newVal})
  {
    final CoordinateSetI newCoords = CoordinateSetI(x: newVal.round(), y: _offset.value.y);
    _offset.value = newCoords;
  }

  void _offsetXInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null)
    {
      final int val = parsedVal.clamp(_minOffset.value.x, _maxOffset.value.x);
      final CoordinateSetI newCoords = CoordinateSetI(x: val, y: _offset.value.y);
      _offset.value = newCoords;
    }
    else
    {
      final CoordinateSetI newCoords = CoordinateSetI.from(other: _offset.value);
      _offset.value = newCoords;
    }
  }

  void _offsetYSliderChanged({required final double newVal})
  {
    final CoordinateSetI newCoords = CoordinateSetI(x: _offset.value.x, y: newVal.round());
    _offset.value = newCoords;
  }

  void _offsetYInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null)
    {
      final int val = parsedVal.clamp(_minOffset.value.y, _maxOffset.value.y);
      final CoordinateSetI newCoords = CoordinateSetI(x: _offset.value.x, y: val);
      _offset.value = newCoords;
    }
    else
    {
      final CoordinateSetI newCoords = CoordinateSetI.from(other: _offset.value);
      _offset.value = newCoords;
    }
  }

  void _centerH()
  {
    final CoordinateSetI newOffset = CoordinateSetI.from(other: _offset.value);
    newOffset.x = (_minOffset.value.x + _maxOffset.value.x) ~/ 2;
    _offset.value = newOffset;
  }

  void _centerV()
  {
    final CoordinateSetI newOffset = CoordinateSetI.from(other: _offset.value);
    newOffset.y = (_minOffset.value.y + _maxOffset.value.y) ~/ 2;
    _offset.value = newOffset;
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
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text("Width"),
                          ),
                          Expanded(
                            flex: 7,
                            child: ValueListenableBuilder<CoordinateSetI>(
                              valueListenable: _size,
                              builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                return KPixSlider(
                                  onChanged: (final double newVal) {_sizeXSliderChanged(newVal: newVal);},
                                  value: value.x.toDouble(),
                                  min: _sizeOptions.sizeMin.toDouble(),
                                  max: _sizeOptions.sizeMax.toDouble(),
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: _options.padding),
                          Expanded(
                            child: ValueListenableBuilder<CoordinateSetI>(
                              valueListenable: _size,
                              builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                final TextEditingController controller = TextEditingController(text: value.x.toString());
                                controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                return TextField(
                                  focusNode: _hotkeyManager.canvasSizeWidthTextFocus,
                                  textAlign: TextAlign.end,
                                  controller: controller,
                                  onChanged: (final String newVal) {_sizeXInputChanged(newVal: newVal);},
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text("Height"),
                          ),
                          Expanded(
                            flex: 7,
                            child: ValueListenableBuilder<CoordinateSetI>(
                              valueListenable: _size,
                              builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                return KPixSlider(
                                  onChanged: (final double newVal) {_sizeYSliderChanged(newVal: newVal);},
                                  value: value.y.toDouble(),
                                  min: _sizeOptions.sizeMin.toDouble(),
                                  max: _sizeOptions.sizeMax.toDouble(),
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: _options.padding),
                          Expanded(
                            child: ValueListenableBuilder<CoordinateSetI>(
                              valueListenable: _size,
                              builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                final TextEditingController controller = TextEditingController(text: value.y.toString());
                                controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                return TextField(
                                  focusNode: _hotkeyManager.canvasSizeHeightTextFocus,
                                  textAlign: TextAlign.end,
                                  controller: controller,
                                  onChanged: (final String newVal) {_sizeYInputChanged(newVal: newVal);},
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _options.padding,),
                      Text("Offset", style: Theme.of(context).textTheme.titleLarge),
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child:
                            Text("X"),
                          ),
                          Expanded(
                            flex: 7,
                            child: ValueListenableBuilder<CoordinateSetI>(
                              valueListenable: _offset,
                              builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                return KPixSlider(
                                  min: _minOffset.value.x.toDouble(),
                                  max: _maxOffset.value.x.toDouble(),
                                  onChanged: (final double newVal) {_offsetXSliderChanged(newVal: newVal);},
                                  value: value.x.toDouble(),
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: _options.padding),
                          Expanded(
                            child: ValueListenableBuilder<CoordinateSetI>(
                              valueListenable: _offset,
                              builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                final TextEditingController controller = TextEditingController(text: value.x.toString());
                                controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                return TextField(
                                  focusNode: _hotkeyManager.canvasSizeOffsetXTextFocus,
                                  textAlign: TextAlign.end,
                                  controller: controller,
                                  onChanged: (final String newVal) {_offsetXInputChanged(newVal: newVal);},
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text("Y"),
                          ),
                          Expanded(
                            flex: 7,
                            child: ValueListenableBuilder<CoordinateSetI>(
                              valueListenable: _offset,
                              builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                return KPixSlider(
                                  min: _minOffset.value.y.toDouble(),
                                  max: _maxOffset.value.y.toDouble(),
                                  onChanged: (final double newVal) {_offsetYSliderChanged(newVal: newVal);},
                                  value: value.y.toDouble(),
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: _options.padding),
                          Expanded(
                            child: ValueListenableBuilder<CoordinateSetI>(
                              valueListenable: _offset,
                              builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                final TextEditingController controller = TextEditingController(text: value.y.toString());
                                controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                return TextField(
                                  focusNode: _hotkeyManager.canvasSizeOffsetYTextFocus,
                                  textAlign: TextAlign.end,
                                  controller: controller,
                                  onChanged: (final String newVal) {_offsetYInputChanged(newVal: newVal);},
                                );
                              },
                            ),
                          ),
                        ],
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
                      ValueListenableBuilder<CoordinateSetI>(
                        valueListenable: _size,
                        builder: (final BuildContext context1, final CoordinateSetI size, final Widget? child1) {
                          return ValueListenableBuilder<CoordinateSetI>(
                            valueListenable: _offset,
                            builder: (final BuildContext context2, final CoordinateSetI offset, final Widget? child) {
                              final CoordinateSetD scaledCanvasSize = CoordinateSetD(x: _appState.canvasSize.x * _scalingFactor, y: _appState.canvasSize.y * _scalingFactor);
                              final CoordinateSetD scaledNewSize = CoordinateSetD(x: _size.value.x * _scalingFactor, y: _size.value.y * _scalingFactor);

                              return Stack(
                                children: <Widget>[
                                  SizedBox(
                                    width: _sizeOptions.previewSize.toDouble(),
                                    height: _sizeOptions.previewSize.toDouble(),
                                  ),
                                  Positioned(
                                    left: (_sizeOptions.previewSize / 2) - (scaledNewSize.x / 2) + (offset.x * _scalingFactor),
                                    top: (_sizeOptions.previewSize / 2) - (scaledNewSize.y / 2) + (offset.y * _scalingFactor),
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
                                    left: (_sizeOptions.previewSize / 2) - (scaledNewSize.x / 2) + (offset.x * _scalingFactor),
                                    top: (_sizeOptions.previewSize / 2) - (scaledNewSize.y / 2) + (offset.y * _scalingFactor),
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
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(_options.padding),
                              child: IconButton.outlined(
                                icon: FaIcon(
                                  FontAwesomeIcons.leftRight,
                                  size: _options.iconSize / 2,
                                ),
                                onPressed: _centerH,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(_options.padding),
                              child: IconButton.outlined(
                                icon: FaIcon(
                                  FontAwesomeIcons.upDown,
                                  size: _options.iconSize / 2,
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
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                    icon: FaIcon(
                      FontAwesomeIcons.check,
                      size: _options.iconSize,
                    ),
                    onPressed: () {
                      widget.accept(size: _size.value, offset: _offset.value);
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
