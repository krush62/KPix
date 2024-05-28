import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:kpix/models.dart';
import 'package:kpix/painting/kpix_painter.dart';


class CanvasOptions
{
  final int stylusPollRate;
  final int longPressDuration;
  final double longPressCancelDistance;
  final double stylusZoomStepDistance;

  CanvasOptions({
    required this.stylusPollRate,
    required this.longPressDuration,
    required this.longPressCancelDistance,
    required this.stylusZoomStepDistance});
}



class ListenerExample extends StatefulWidget {
  const ListenerExample(
      {
        required this.options,
        required this.appState,
        required this.kPixPainterOptions,
        super.key
      });

  final CanvasOptions options;
  final AppState appState;
  final KPixPainterOptions kPixPainterOptions;
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
  late Offset secondaryStartLoc;
  bool needSecondaryStartLoc = false;
  bool primaryIsDown = false;
  bool secondaryIsDown = false;
  bool stylusZoomStarted = false;
  int stylusZoomStartLevel = 100;

  late Timer timerStylusBtnPoll;
  late Timer timerStylusBtnLongPress;
  bool timerStylusRunning = false;
  bool stylusButtonDetected = false;
  bool stylusButtonDown = false;
  bool stylusButtonLongDown = false;

  late Offset dragStartLoc;
  late Offset oldCanvasOffset;
  bool isDragging = false;

  ValueNotifier<Offset> canvasOffset = ValueNotifier(Offset(0.0, 0.0));


  @override
  void initState() {
    super.initState();
    timerStylusBtnPoll = Timer.periodic(Duration(milliseconds: widget.options.stylusPollRate), _stylusBtnTimeout);
    timeoutLongPress = Duration(milliseconds: widget.options.longPressDuration);
    maxLongPressDistance = widget.options.longPressCancelDistance;
  }

  void updateDetails(String s)
  {
    //setState(() {
      _details = s;
    //});
  }

  void updatePressure(double p)
  {
    //setState(() {
      pressure = p;
    //});
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
    else if (details.buttons == kSecondaryButton && details.kind == PointerDeviceKind.mouse)
    {
        secondaryIsDown = true;
    }
    else if (details.buttons == kTertiaryButton && details.kind == PointerDeviceKind.mouse)
    {
      dragStartLoc = details.localPosition;
      isDragging = true;
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
    else if (secondaryIsDown && details.kind == PointerDeviceKind.mouse)
    {
      secondaryIsDown = false;
    }
    else if (isDragging && details.kind == PointerDeviceKind.mouse)
    {
      isDragging = false;
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

    if (needSecondaryStartLoc)
    {
      secondaryStartLoc = details.localPosition;
      needSecondaryStartLoc = false;
    }

    if (stylusZoomStarted)
    {
      double yOffset = secondaryStartLoc.dy - y;
      int zoomSteps = (yOffset / widget.options.stylusZoomStepDistance).round();
      widget.appState.setZoomLevelByDistance(stylusZoomStartLevel, zoomSteps);
    }

    if (details.kind == PointerDeviceKind.stylus)
    {
      pressure = details.pressure;
    }
    else
    {
      pressure = 0.0;
    }

    //setState(() {

      Offset co = Offset(x, y);
      if (timerRunning && (pressStartLoc - co).distance > maxLongPressDistance)
      {
        timerLongPress.cancel();
        timerRunning = false;
      }
      if (timerStylusRunning && (secondaryStartLoc - co).distance > maxLongPressDistance)
      {
        timerStylusBtnLongPress.cancel();
        timerStylusRunning = false;
        isDragging = true;
        dragStartLoc = co;
      }
    //});

    if (isDragging)
    {
      canvasOffset.value  = canvasOffset.value - (dragStartLoc - co);
      dragStartLoc = co;
    }

  }

  void _hover(PointerHoverEvent details)
  {
    if (details.buttons == kSecondaryButton && !stylusButtonDetected) {
      stylusButtonDetected = true;
    }
    _updateLocation(details);

  }

  void _scroll(PointerSignalEvent ev)
  {
    if (ev is PointerScrollEvent)
    {
      if (ev.scrollDelta.dy < 0.0)
      {
        widget.appState.increaseZoomLevel();
      }
      else if (ev.scrollDelta.dy > 0.0)
      {
        widget.appState.decreaseZoomLevel();
      }
    }
  }

  void _stylusBtnTimeout(Timer t)
  {
    if (stylusButtonDetected && !stylusButtonDown)
    {
      needSecondaryStartLoc = true;
      stylusButtonDown = true;
      stylusBtnDown();
      timerStylusBtnLongPress = Timer(timeoutLongPress, handleTimeoutStylusBtnLongPress);
      timerStylusRunning = true;
    }
    else if (!stylusButtonDetected && stylusButtonDown)
    {
      needSecondaryStartLoc = false;
      stylusBtnUp();
      stylusButtonDown = false;
      timerStylusBtnLongPress.cancel();
      timerStylusRunning = false;
      stylusZoomStarted = false;
      isDragging = false;
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
    timerStylusRunning = false;
    stylusZoomStarted = true;
    stylusZoomStartLevel = widget.appState.getZoomLevel();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Listener(
        onPointerDown: _buttonDown,
        onPointerMove: _updateLocation,
        onPointerUp: _buttonUp,
        onPointerHover: _hover,
        onPointerSignal: _scroll,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).primaryColorDark,
          child: CustomPaint(
            painter: KPixPainter(
              appState: widget.appState,
              offset: canvasOffset,
              options: widget.kPixPainterOptions,
              checkerboardColor1: Theme.of(context).primaryColor,
              checkerboardColor2: Theme.of(context).primaryColorLight,

            )
          )
          /*child: Column(
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
          ),*/
        ),
      ),
    );
  }
}