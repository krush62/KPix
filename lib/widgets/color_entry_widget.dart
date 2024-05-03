import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kpix/models.dart';
import 'package:kpix/typedefs.dart';

class ColorEntryWidgetOptions {
  final double unselectedMargin;
  final double selectedMargin;
  final double roundRadius;
  final double contrastColorThreshold;
  final int hsvDisplayDigits;
  final int hoverTimer;
  final int stylusPollRate;
  final int longPressDuration;
  final double addIconSize;
  final double buttonPadding;
  final double minSize;
  final double maxSize;

  ColorEntryWidgetOptions({
    required this.unselectedMargin,
    required this.selectedMargin,
    required this.roundRadius,
    required this.contrastColorThreshold,
    required this.hsvDisplayDigits,
    required this.hoverTimer,
    required this.stylusPollRate,
    required this.longPressDuration,
    required this.addIconSize,
    required this.buttonPadding,
    required this.minSize,
    required this.maxSize,
  });
}

class ColorEntryNotifiySet {
  IdColor color = IdColor(color: Colors.black, uuid: "");
  Color textColor = Colors.white;
  String colorString = "0.00\n0.00\n0.00";

  ColorEntryNotifiySet(
      this.color, this.textColor, this.colorString);

  ColorEntryNotifiySet.clone(ColorEntryNotifiySet other)
      : this(other.color, other.textColor, other.colorString);
}

class ColorEntryWidget extends StatefulWidget {
  final ValueNotifier<ColorEntryNotifiySet> colorData = ValueNotifier(
      ColorEntryNotifiySet(
          IdColor(color: Colors.black, uuid: ""), Colors.white, "0.00\n0.00\n0.00"));
  final ColorSelectedFn colorSelectedFn;
  final ColorEntryWidgetOptions options;
  final AppState appState;

  ColorEntryWidget(IdColor c, this.appState, this.colorSelectedFn, this.options, {super.key}) {
    setColor(c);
  }

  Color _getContrastColor(Color color) {
    if (HSVColor.fromColor(color).value > options.contrastColorThreshold) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }

  String _createColorString(Color c) {
    HSVColor hsv = HSVColor.fromColor(c);
    return "${(hsv.hue / 360.0).toStringAsFixed(options.hsvDisplayDigits)}\n"
        "${hsv.saturation.toStringAsFixed(options.hsvDisplayDigits)}\n"
        "${hsv.value.toStringAsFixed(options.hsvDisplayDigits)}";
  }

  @override
  State<ColorEntryWidget> createState() => _ColorEntryWidgetState();

  void setColor(final IdColor c) {
    ColorEntryNotifiySet newSet =
        ColorEntryNotifiySet.clone(colorData.value);
    newSet.textColor = _getContrastColor(c.color);
    newSet.color = c;
    newSet.colorString = _createColorString(c.color);
    colorData.value = newSet;
  }

  void setColorHSV(final double hue, final double saturation, final double value, final String uuid) {
    assert(hue >= 0.0 && hue <= 1.0, 'hue must be in range 0.0-1.0');
    assert(saturation >= 0.0 && saturation <= 1.0,
        'saturation must be in range 0.0-1.0');
    assert(value >= 0.0 && value <= 1.0, 'value must be in range 0.0-1.0');
    setColor(IdColor(color: HSVColor.fromAHSV(1.0, hue, saturation, value).toColor(), uuid: uuid));
  }

  void setColorRGB(final int r, final int g, final int b, final String uuid) {
    assert(r >= 0 && r < 256, 'red value must be in range 0-255');
    assert(g >= 0 && g < 256, 'green value must be in range 0-255');
    assert(b >= 0 && b < 256, 'blue value must be in range 0-255');
    setColor(IdColor(color: Color.fromRGBO(r, g, b, 1.0), uuid: uuid));
  }

}

class _ColorEntryWidgetState extends State<ColorEntryWidget> {
  bool _pointerHover = false;
  bool _mouseOver = false;
  bool _textIsVisible = false;
  late Timer _hoverPollTimer;
  bool stylusButtonDetected = false;
  bool stylusButtonDown = false;
  bool timerRunning = false;
  late Duration timeoutLongPress;
  late Timer timerLongPress;
  bool primaryIsDown = false;
  bool secondaryIsDown = false;
  late Timer timerStylusBtnPoll;
  late Timer timerStylusBtnLongPress;

  @override
  void initState() {
    super.initState();
    _hoverPollTimer = Timer.periodic(
        Duration(milliseconds: widget.options.hoverTimer), _hoverPoll);
    timerStylusBtnPoll = Timer.periodic(
        Duration(milliseconds: widget.options.stylusPollRate),
        _stylusBtnTimeout);
    timeoutLongPress = Duration(milliseconds: widget.options.longPressDuration);
  }

  void _hoverPoll(Timer t) {
    if ((_pointerHover || _mouseOver) && !_textIsVisible) {
      setState(() {
        _textIsVisible = true;
      });
    } else if ((!_pointerHover && !_mouseOver) && _textIsVisible) {
      setState(() {
        _textIsVisible = false;
      });
    }
    //this should always be true, but was added to get rid of the "unused variable" warning
    if (_hoverPollTimer.isActive) {
      _pointerHover = false;
    }
  }

  void _hover(PointerHoverEvent e) {
    if (e.buttons == kSecondaryButton && !stylusButtonDetected) {
      stylusButtonDetected = true;
    }
    _pointerHover = true;
  }

  void _mouseEnter(PointerEnterEvent e) {
    _mouseOver = true;
  }

  void _mouseExit(PointerExitEvent e) {
    _mouseOver = false;
  }

  void _down(PointerEvent e) {
    if (e.buttons == kPrimaryButton) {
      primaryIsDown = true;
      if (!timerRunning) {
        timerRunning = true;
        timerLongPress = Timer(timeoutLongPress, handleTimeoutLongPress);
      }
      widget.colorSelectedFn(widget.colorData.value.color.uuid);
      print("PRIMARY DOWN");
    } else if (e.buttons == kSecondaryButton) {
      secondaryIsDown = true;
      stylusBtnDown();
    }
  }

  void _up(PointerUpEvent e) {
    if (primaryIsDown) {
      timerLongPress.cancel();
      primaryIsDown = false;
      print("PRIMARY UP");
    } else if (secondaryIsDown) {
      stylusBtnUp();
      secondaryIsDown = false;
    }
    timerRunning = false;
  }

  void _stylusBtnTimeout(Timer t) {
    if (stylusButtonDetected && !stylusButtonDown) {
      stylusButtonDown = true;
      stylusBtnDown();
      timerStylusBtnLongPress =
          Timer(timeoutLongPress, handleTimeoutStylusBtnLongPress);
    } else if (!stylusButtonDetected && stylusButtonDown) {
      stylusBtnUp();
      stylusButtonDown = false;
      timerStylusBtnLongPress.cancel();
    }
    stylusButtonDetected = false;
  }

  void handleTimeoutLongPress() {
    // callback function
    timerRunning = false;
    print("LONG PRESS PRIMARY");
  }

  void stylusBtnDown() {
    print("SECONDARY DOWN");
  }

  void stylusBtnUp() {
    print("SECONDARY UP");
  }

  void handleTimeoutStylusBtnLongPress() {
    print("STYLUS BTN LONG PRESS");
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ColorEntryNotifiySet>(
      valueListenable: widget.colorData,
      builder: (BuildContext context, ColorEntryNotifiySet value, child) {
        return ValueListenableBuilder(
            valueListenable: widget.appState.selectedColorId,
            builder: (BuildContext context2, String selectedColorId, child2)
            {
              return Expanded(
                  child: MouseRegion(
                      onEnter: _mouseEnter,
                      onExit: _mouseExit,
                      child: Listener(
                          onPointerHover: _hover,
                          onPointerDown: _down,
                          onPointerUp: _up,
                          child: Container(
                              constraints: BoxConstraints(
                                  minHeight: widget.options.minSize,
                                  minWidth: widget.options.minSize,
                                  maxHeight: widget.options.maxSize,
                                  maxWidth: widget.options.maxSize),
                              child: AspectRatio(
                                  aspectRatio: 1.0,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
                                            minHeight: widget.options.minSize,
                                            minWidth: widget.options.minSize,
                                            maxHeight: widget.options.maxSize,
                                            maxWidth: widget.options.maxSize),
                                        margin: EdgeInsets.all(widget.colorData.value.color.uuid == selectedColorId
                                            ? widget.options.selectedMargin
                                            : widget.options.unselectedMargin),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: widget.colorData.value.color.uuid == selectedColorId
                                                    ? Theme.of(context).primaryColorLight
                                                    : Colors.transparent,
                                                width: (widget
                                                    .options.unselectedMargin -
                                                    widget.options.selectedMargin)),
                                            color: value.color.color,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                    widget.options.roundRadius))),
                                      ),
                                      Visibility(
                                          visible: _textIsVisible,
                                          child: Text(
                                            value.colorString,
                                            style: TextStyle(
                                              color: value.textColor,
                                              fontSize: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.fontSize,
                                              fontWeight: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.fontWeight,
                                              letterSpacing: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.letterSpacing,
                                              decoration: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.decoration,
                                            ),
                                            textAlign: TextAlign.center,
                                          ))
                                    ],
                                  )
                              )
                          )
                      )
                  )
              );
            }
        );
      }
    );
  }
}
