import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:kpix/models.dart';


class CanvasOptions
{
  final int stylusPollRate;
  final int longPressDuration;
  final double longPressCancelDistance;

  CanvasOptions({required this.stylusPollRate, required this.longPressDuration, required this.longPressCancelDistance});
}



class ListenerExample extends StatefulWidget {
  const ListenerExample(
      {
        required this.options,
        required this.appState,
        super.key
      });

  final CanvasOptions options;
  final AppState appState;
  @override
  State<ListenerExample> createState() => _ListenerExampleState();
}

class _ListenerExampleState extends State<ListenerExample> {
  //TODO privatize members and methods
  String _details = "";
  int pressTime = 0;
  double x = 0.0;
  double y = 0.0;
  double pressure = 0.0;
  bool timerRunning = false;
  late Duration timeoutLongPress;
  late final double maxLongPressDistance;
  late Timer timerLongPress;
  late Offset pressStartLoc;
  bool primaryIsDown = false;
  bool secondaryIsDown = false;

  late Timer timerStylusBtnPoll;
  late Timer timerStylusBtnLongPress;
  bool stylusButtonDetected = false;
  bool stylusButtonDown = false;


  @override
  void initState() {
    super.initState();
    timerStylusBtnPoll = Timer.periodic(Duration(milliseconds: widget.options.stylusPollRate), _stylusBtnTimeout);
    timeoutLongPress = Duration(milliseconds: widget.options.longPressDuration);
    maxLongPressDistance = widget.options.longPressCancelDistance;
  }

  void updateDetails(String s)
  {
    setState(() {
      _details = s;
    });
  }

  void updatePressure(double p)
  {
    setState(() {
      pressure = p;
    });
  }

  void handleTimeoutLongPress() {
    timerRunning = false;
    updateDetails("LONG PRESS PRIMARY");
  }

  void _buttonDown(PointerEvent details)
  {
    pressStartLoc = details.localPosition;
    if (details.buttons == kPrimaryButton)
    {
      primaryIsDown = true;
      if (!timerRunning) {
        timerRunning = true;
        timerLongPress = Timer(timeoutLongPress, handleTimeoutLongPress);
      }
      _updateLocation(details);
      if (details.kind == PointerDeviceKind.stylus)
      {
        updatePressure(details.pressure);
      }
      else
      {
        updatePressure(0.0);
      }

      updateDetails("PRIMARY DOWN");
    }
    else if (details.buttons == kSecondaryButton)
    {
      secondaryIsDown = true;
      stylusBtnDown();
    }
  }

  void _buttonUp(PointerEvent details)
  {
    if (primaryIsDown)
    {
      updateDetails("PRIMARY UP");
      widget.appState.hideStatusBarToolDimension();
      widget.appState.hideStatusBarToolDiagonal();
      widget.appState.hideStatusBarToolAngle();
      widget.appState.hideStatusBarToolAspectRatio();
      timerLongPress.cancel();
      primaryIsDown = false;
    }
    else if (secondaryIsDown)
    {
      stylusBtnUp();
      secondaryIsDown = false;
    }
    timerRunning = false;
  }

  void _updateLocation(PointerEvent details) {
    x = details.localPosition.dx;
    y = details.localPosition.dy;
    widget.appState.setStatusBarCursorPosition(x, y);
    if (primaryIsDown)
    {
      widget.appState.setStatusBarToolDimension(pressStartLoc.dx.round(), pressStartLoc.dy.round(), x.round(), y.round());
      widget.appState.setStatusBarToolDiagonal(pressStartLoc.dx.round(), pressStartLoc.dy.round(), x.round(), y.round());
      widget.appState.setStatusBarToolAspectRatio(pressStartLoc.dx.round(), pressStartLoc.dy.round(), x.round(), y.round());
      widget.appState.setStatusBarToolAngle(pressStartLoc.dx.round(), pressStartLoc.dy.round(), x.round(), y.round());

    }


    setState(() {

      if (details.kind == PointerDeviceKind.stylus)
      {
        pressure = details.pressure;
      }
      else
      {
        pressure = 0.0;
      }

      Offset co = Offset(x, y);
      if (timerRunning) {
        if ((pressStartLoc - co).distance > maxLongPressDistance) {
          timerLongPress.cancel();
          timerRunning = false;
        }
      }
    });
  }

  void _hover(PointerHoverEvent details)
  {
    if (details.buttons == kSecondaryButton && !stylusButtonDetected) {
      stylusButtonDetected = true;
    }
    _updateLocation(details);

  }

  void _stylusBtnTimeout(Timer t)
  {
    if (stylusButtonDetected && !stylusButtonDown)
    {
      stylusButtonDown = true;
      stylusBtnDown();
      timerStylusBtnLongPress = Timer(timeoutLongPress, handleTimeoutStylusBtnLongPress);
    }
    else if (!stylusButtonDetected && stylusButtonDown)
    {
      stylusBtnUp();
      stylusButtonDown = false;
      timerStylusBtnLongPress.cancel();
    }
    stylusButtonDetected = false;
  }

  void stylusBtnDown()
  {
    updateDetails("SECONDARY DOWN");
  }

  void stylusBtnUp()
  {
    updateDetails("SECONDARY UP");
  }

  void handleTimeoutStylusBtnLongPress()
  {
    updateDetails("STYLUS BTN LONG PRESS");
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Listener(
        onPointerDown: _buttonDown,
        onPointerMove: _updateLocation,
        onPointerUp: _buttonUp,
        onPointerHover: _hover,
        child: ColoredBox(
          color: Theme.of(context).primaryColorDark,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pressure: ${pressure.toStringAsFixed((2))}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                _details,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                'Position: (${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}