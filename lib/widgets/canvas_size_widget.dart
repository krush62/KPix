import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/overlay_entries.dart';


class CanvasSizeOptions
{
  final int sizeMin;
  final int sizeMax;
  final int previewSize;

  CanvasSizeOptions({
    required this.sizeMin,
    required this.sizeMax,
    required this.previewSize
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
  final AppState _appState = GetIt.I.get<AppState>();
  final ValueNotifier<CoordinateSetI> _size = ValueNotifier(CoordinateSetI(x: 0, y: 0));
  final ValueNotifier<CoordinateSetI> _offset = ValueNotifier(CoordinateSetI(x: 0, y: 0));
  final ValueNotifier<CoordinateSetI> _minOffset = ValueNotifier(CoordinateSetI(x: 0, y: 0));
  final ValueNotifier<CoordinateSetI> _maxOffset = ValueNotifier(CoordinateSetI(x: 0, y: 0));
  double _scalingFactor = 1.0;
  final ValueNotifier<ui.Image?> _image = ValueNotifier(null);

  @override
  void initState()
  {
    super.initState();
    _setSize(_appState.canvasSize);
    Helper.getImageFromLayers(_appState.canvasSize, _appState.layers.value, _appState.canvasSize).then(_setImage);

  }

  void _setImage(final ui.Image img)
  {
    _image.value = img;
  }

  void _sizeXSliderChanged(final double newVal)
  {
    final CoordinateSetI newCoords = CoordinateSetI(x: newVal.round(), y: _size.value.y);
    _setSize(newCoords);
  }

  void _sizeXInputChanged(final String newVal)
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null)
    {
      final int val = min(max(parsedVal, _sizeOptions.sizeMin), _sizeOptions.sizeMax);
      final CoordinateSetI newCoords = CoordinateSetI(x: val, y: _size.value.y);
      _setSize(newCoords);
    }
    else
    {
      final CoordinateSetI newCoords = CoordinateSetI.from(_size.value);
      _setSize(newCoords);
    }
  }

  void _sizeYSliderChanged(final double newVal)
  {
    final CoordinateSetI newCoords = CoordinateSetI(x: _size.value.x, y: newVal.round());
    _setSize(newCoords);
  }

  void _sizeYInputChanged(final String newVal)
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null)
    {
      final int val = min(max(parsedVal, _sizeOptions.sizeMin), _sizeOptions.sizeMax);
      final CoordinateSetI newCoords = CoordinateSetI(x: _size.value.x, y: val);
      _setSize(newCoords);
    }
    else
    {
      final CoordinateSetI newCoords = CoordinateSetI.from(_size.value);
      _setSize(newCoords);
    }
  }

  void _setSize(final CoordinateSetI newSize)
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

    final CoordinateSetI newOffset = CoordinateSetI.from(_offset.value);
    newOffset.x = min(max(newOffset.x, _minOffset.value.x), _maxOffset.value.x);
    newOffset.y = min(max(newOffset.y, _minOffset.value.y), _maxOffset.value.y);
    _offset.value = newOffset;

  }

  void _offsetXSliderChanged(final double newVal)
  {
    final CoordinateSetI newCoords = CoordinateSetI(x: newVal.round(), y: _offset.value.y);
    _offset.value = newCoords;
  }

  void _offsetXInputChanged(final String newVal)
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null)
    {
      final int val = min(max(parsedVal, _minOffset.value.x), _maxOffset.value.x);
      final CoordinateSetI newCoords = CoordinateSetI(x: val, y: _offset.value.y);
      _offset.value = newCoords;
    }
    else
    {
      final CoordinateSetI newCoords = CoordinateSetI.from(_offset.value);
      _offset.value = newCoords;
    }
  }

  void _offsetYSliderChanged(final double newVal)
  {
    final CoordinateSetI newCoords = CoordinateSetI(x: _offset.value.x, y: newVal.round());
    _offset.value = newCoords;
  }

  void _offsetYInputChanged(final String newVal)
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null)
    {
      final int val = min(max(parsedVal, _minOffset.value.y), _maxOffset.value.y);
      final CoordinateSetI newCoords = CoordinateSetI(x: _offset.value.x, y: val);
      _offset.value = newCoords;
    }
    else
    {
      final CoordinateSetI newCoords = CoordinateSetI.from(_offset.value);
      _offset.value = newCoords;
    }
  }

  void _centerH()
  {
    final CoordinateSetI newOffset = CoordinateSetI.from(_offset.value);
    newOffset.x = (_minOffset.value.x + _maxOffset.value.x) ~/ 2;
    _offset.value = newOffset;
  }

  void _centerV()
  {
    final CoordinateSetI newOffset = CoordinateSetI.from(_offset.value);
    newOffset.y = (_minOffset.value.y + _maxOffset.value.y) ~/ 2;
    _offset.value = newOffset;
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
          maxHeight: _options.maxHeight * 1.5,
          maxWidth: _options.maxWidth * 2,
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
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text("Canvas Size", style: Theme.of(context).textTheme.titleLarge),
                          Row(
                            children: [
                              const Expanded(
                                flex: 1,
                                child: Text("Width")
                              ),
                              Expanded(
                                flex: 7,
                                child: ValueListenableBuilder<CoordinateSetI>(
                                  valueListenable: _size,
                                  builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                    return Slider(
                                      onChanged: _sizeXSliderChanged,
                                      value: value.x.toDouble(),
                                      min: _sizeOptions.sizeMin.toDouble(),
                                      max: _sizeOptions.sizeMax.toDouble()
                                    );
                                  },
                                )
                              ),
                              Expanded(
                                flex: 1,
                                child: ValueListenableBuilder<CoordinateSetI>(
                                  valueListenable: _size,
                                  builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                    final TextEditingController controller = TextEditingController(text: value.x.toString());
                                    controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                    return TextField(
                                      textAlign: TextAlign.end,
                                      controller: controller,
                                      onChanged: _sizeXInputChanged
                                    );
                                  },
                                )
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Expanded(
                                flex: 1,
                                child: Text("Height")
                              ),
                              Expanded(
                                flex: 7,
                                child: ValueListenableBuilder<CoordinateSetI>(
                                  valueListenable: _size,
                                  builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                    return Slider(
                                      onChanged: _sizeYSliderChanged,
                                      value: value.y.toDouble(),
                                      min: _sizeOptions.sizeMin.toDouble(),
                                      max: _sizeOptions.sizeMax.toDouble()
                                    );
                                  },
                                )
                              ),
                              Expanded(
                                flex: 1,
                                child: ValueListenableBuilder<CoordinateSetI>(
                                  valueListenable: _size,
                                  builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                    final TextEditingController controller = TextEditingController(text: value.y.toString());
                                    controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                    return TextField(
                                      textAlign: TextAlign.end,
                                      controller: controller,
                                      onChanged: _sizeYInputChanged
                                    );
                                  },
                                )
                              ),
                            ],
                          ),
                          SizedBox(height: _options.padding,),
                          Text("Offset", style: Theme.of(context).textTheme.titleLarge),
                          Row(
                            children: [
                              const Expanded(
                                flex: 1,
                                child:
                                Text("X")
                              ),
                              Expanded(
                                flex: 7,
                                child: ValueListenableBuilder<CoordinateSetI>(
                                  valueListenable: _offset,
                                  builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                    return Slider(
                                      min: _minOffset.value.x.toDouble(),
                                      max: _maxOffset.value.x.toDouble(),
                                      onChanged: _offsetXSliderChanged,
                                      value: value.x.toDouble(),
                                    );
                                  },
                                )
                              ),
                              Expanded(
                                  flex: 1,
                                  child: ValueListenableBuilder<CoordinateSetI>(
                                    valueListenable: _offset,
                                    builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                      final TextEditingController controller = TextEditingController(text: value.x.toString());
                                      controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                      return TextField(
                                          textAlign: TextAlign.end,
                                          controller: controller,
                                          onChanged: _offsetXInputChanged
                                      );
                                    },
                                  )
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Expanded(
                                flex: 1,
                                child: Text("Y")
                              ),
                              Expanded(
                                flex: 7,
                                child: ValueListenableBuilder<CoordinateSetI>(
                                  valueListenable: _offset,
                                  builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                    return Slider(
                                      min: _minOffset.value.y.toDouble(),
                                      max: _maxOffset.value.y.toDouble(),
                                      onChanged: _offsetYSliderChanged,
                                      value: value.y.toDouble(),
                                    );
                                  },
                                )
                              ),
                              Expanded(
                                flex: 1,
                                child: ValueListenableBuilder<CoordinateSetI>(
                                  valueListenable: _offset,
                                  builder: (final BuildContext context, final CoordinateSetI value, final Widget? child) {
                                    final TextEditingController controller = TextEditingController(text: value.y.toString());
                                    controller.selection = TextSelection.collapsed(offset: controller.text.length);
                                    return TextField(
                                        textAlign: TextAlign.end,
                                        controller: controller,
                                        onChanged: _offsetYInputChanged
                                    );
                                  },
                                )
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<CoordinateSetI>(
                              valueListenable: _size,
                              builder: (final BuildContext context1, final CoordinateSetI size, final Widget? child1) {
                                return ValueListenableBuilder<CoordinateSetI>(
                                  valueListenable: _offset,
                                  builder: (final BuildContext context2, final CoordinateSetI offset, final Widget? child) {
                                    final CoordinateSetD scaledCanvasSize = CoordinateSetD(x: _appState.canvasSize.x * _scalingFactor, y: _appState.canvasSize.y * _scalingFactor);
                                    final CoordinateSetD scaledNewSize = CoordinateSetD(x: _size.value.x * _scalingFactor, y: _size.value.y * _scalingFactor);

                                    return Stack(
                                      children: [
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
                                                isAntiAlias: false,
                                                image: img,
                                              );
                                            },
                                          )
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
                                          )
                                        ),
                                        Positioned(
                                          left: (_sizeOptions.previewSize / 2) - (scaledNewSize.x / 2),
                                          top: (_sizeOptions.previewSize / 2) - (scaledNewSize.y / 2),
                                          width: scaledNewSize.x,
                                          height: scaledNewSize.y,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                                border: Border.all(color:  Theme.of(context).primaryColorDark, width: 3)
                                            ),
                                          )
                                        ),
                                        Positioned(
                                          left: (_sizeOptions.previewSize / 2) - (scaledNewSize.x / 2),
                                          top: (_sizeOptions.previewSize / 2) - (scaledNewSize.y / 2),
                                          width: scaledNewSize.x,
                                          height: scaledNewSize.y,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                                border: Border.all(color:  Theme.of(context).primaryColorLight, width: 1)
                                            ),
                                          )
                                        )
                                      ],
                                    );
                                  },
                                );
                              },
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: EdgeInsets.all(_options.padding),
                                  child: IconButton.outlined(
                                    icon: FaIcon(
                                      FontAwesomeIcons.leftRight,
                                      size: _options.iconSize / 2,
                                    ),
                                    onPressed: _centerH,
                                  ),
                                )
                              ),
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: EdgeInsets.all(_options.padding),
                                  child: IconButton.outlined(
                                    icon: FaIcon(
                                      FontAwesomeIcons.upDown,
                                      size: _options.iconSize / 2,
                                    ),
                                    onPressed: _centerV,
                                  ),
                                )
                              ),
                            ]
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),

              SizedBox(height: _options.padding,),
              Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 1,
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
                      )
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.all(_options.padding),
                        child: IconButton.outlined(
                          icon: FaIcon(
                            FontAwesomeIcons.check,
                            size: _options.iconSize,
                          ),
                          onPressed: () {
                            widget.accept(_size.value, _offset.value);
                          },
                        ),
                      )
                  ),
                ]
              )
            ],
          ),
        )
      )
    );
  }

}