import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ColorEntryWidget extends StatefulWidget
{
  final ValueNotifier<Color> color = ValueNotifier(Colors.red);
  ColorEntryWidget({super.key});

  @override
  State<ColorEntryWidget> createState() => _ColorEntryWidgetState();

  void setColor(Color c)
  {
    color.value = c;
  }

  void setColorHSV(double hue, double saturation, double value)
  {
    assert(hue >= 0.0 && hue <= 1.0, 'hue must be in range 0.0-1.0');
    assert(saturation >= 0.0 && saturation <= 1.0, 'saturation must be in range 0.0-1.0');
    assert(value >= 0.0 && value <= 1.0, 'value must be in range 0.0-1.0');
    Color c = HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
    color.value = c;
  }

  void setColorRGB(int r, int g, int b)
  {
    assert(r >= 0 && r < 256, 'red value must be in range 0-255');
    assert(g >= 0 && g < 256, 'green value must be in range 0-255');
    assert(b >= 0 && b < 256, 'blue value must be in range 0-255');
    Color c = Color.fromRGBO(r, g, b, 1.0);
    color.value = c;
  }


}

class _ColorEntryWidgetState extends State<ColorEntryWidget>
{
  bool _pointerHover = false;
  bool _mouseOver = false;
  bool _textIsVisible = false;
  late Timer _hoverPollTimer;


  @override
  void initState() {
    super.initState();
    //TODO options
    _hoverPollTimer = Timer.periodic(const Duration(milliseconds: 100), _hoverPoll);
  }

  void _hoverPoll(Timer t)
  {
    if ((_pointerHover || _mouseOver) && ! _textIsVisible)
    {
      setState(() {
        _textIsVisible = true;
      });
    }
    else if((!_pointerHover && !_mouseOver) && _textIsVisible)
    {
      setState(() {
        _textIsVisible = false;
      });
    }
    //this should always be true, but was added to get rid of the "unused variable" warning
    if (_hoverPollTimer.isActive)
    {
      _pointerHover = false;
    }
  }

  String _stringFromColor(Color c)
  {
    return "${c.red}\n${c.green}\n${c.blue}";
  }

  void _hover(PointerHoverEvent e)
  {
    _pointerHover = true;
  }

  void _mouseEnter(PointerEnterEvent e)
  {
    _mouseOver = true;
  }

  void _mouseExit(PointerExitEvent e)
  {
    _mouseOver = false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
        valueListenable: widget.color,
        builder: (BuildContext context, Color value, child) {

          return MouseRegion(
            onEnter: _mouseEnter,
            onExit: _mouseExit,
            child: Listener(
                onPointerHover: _hover,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                        color: widget.color.value
                    ),
                    Visibility(
                        visible: _textIsVisible,
                        child: Text(
                          _stringFromColor(widget.color.value),
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodySmall,
                          textAlign: TextAlign.center,
                        )
                    )
                  ],
                )
            )
          );
        }
    );
  }
}