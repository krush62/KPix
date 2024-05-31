import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models.dart';
import 'package:kpix/painting/kpix_painter.dart';
import 'package:kpix/preference_manager.dart';


class CursorCoordinates
{
  double x = 0;
  double y = 0;

  CursorCoordinates({required this.x, required this.y});
}


class CanvasOptions
{
  final int stylusPollRate;
  final int longPressDuration;
  final double longPressCancelDistance;
  final double stylusZoomStepDistance;
  final double touchZoomStepDistance;

  CanvasOptions({
    required this.stylusPollRate,
    required this.longPressDuration,
    required this.longPressCancelDistance,
    required this.stylusZoomStepDistance,
    required this.touchZoomStepDistance});
}

class TouchPointerStatus
{
  final Offset startPos;
  Offset currentPos;
  TouchPointerStatus({required this.startPos, required this.currentPos});
}



class ListenerExample extends StatefulWidget {
  const ListenerExample(
      {
        super.key
      });

  @override
  State<ListenerExample> createState() => _ListenerExampleState();
}

class _ListenerExampleState extends State<ListenerExample> {
  CanvasOptions options = GetIt.I.get<PreferenceManager>().canvasWidgetOptions;
  AppState appState = GetIt.I.get<AppState>();
  
  
  
  //TODO privatize members and methods
  int pressTime = 0;
  ValueNotifier<CursorCoordinates?> cursorPos = ValueNotifier(null);
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
  bool stylusHoverDetected = false;
  bool stylusButtonDown = false;
  bool stylusButtonLongDown = false;

  late Offset dragStartLoc;
  late Offset oldCanvasOffset;
  bool isDragging = false;

  ValueNotifier<Offset> canvasOffset = ValueNotifier(const Offset(0.0, 0.0));

  ValueNotifier<MouseCursor> mouseCursor = ValueNotifier(SystemMouseCursors.none);
  bool mouseIsInside = false;
  Map<int, TouchPointerStatus> touchPointers = {};
  double initialTouchZoomDistance = 0.0;
  int touchZoomStartLevel = 100;

  @override
  void initState() {
    super.initState();
    timerStylusBtnPoll = Timer.periodic(Duration(milliseconds: options.stylusPollRate), _stylusBtnTimeout);
    timeoutLongPress = Duration(milliseconds: options.longPressDuration);
    maxLongPressDistance = options.longPressCancelDistance;
  }


  void handleTimeoutLongPress() {
    timerRunning = false;
    print("LONG PRESS PRIMARY");
  }

  void _buttonDown(PointerDownEvent details)
  {
    if (details.kind == PointerDeviceKind.touch)
    {
      touchPointers[details.pointer] = TouchPointerStatus(startPos: details.localPosition, currentPos: details.localPosition);
      if (touchPointers.length == 2)
      {
        dragStartLoc = Offset((touchPointers.values.elementAt(0).currentPos.dx + touchPointers.values.elementAt(1).currentPos.dx) / 2, (touchPointers.values.elementAt(0).currentPos.dy + touchPointers.values.elementAt(1).currentPos.dy) / 2);
        isDragging = true;
        initialTouchZoomDistance = (touchPointers.values.elementAt(0).currentPos - touchPointers.values.elementAt(1).currentPos).distance;
        touchZoomStartLevel = appState.getZoomLevel();
        setMouseCursor(SystemMouseCursors.move);
      }
    }


    if (details.buttons == kPrimaryButton && touchPointers.length < 2)
    {
      pressStartLoc = details.localPosition;
      primaryIsDown = true;
      if (!timerRunning) {
        timerRunning = true;
        timerLongPress = Timer(timeoutLongPress, handleTimeoutLongPress);
      }
      //_updateLocation(details);

      print("PRIMARY DOWN");
    }
    else if (details.buttons == kSecondaryButton && details.kind == PointerDeviceKind.mouse)
    {
      //NOT USED ATM
      secondaryIsDown = true;
    }
    else if (details.buttons == kTertiaryButton && details.kind == PointerDeviceKind.mouse)
    {
      dragStartLoc = details.localPosition;
      isDragging = true;
      setMouseCursor(SystemMouseCursors.move);
    }
  }

  void _buttonUp(PointerEvent details)
  {
    if (details.kind == PointerDeviceKind.touch)
    {
      touchPointers.remove(details.pointer);
      if (touchPointers.length != 2)
      {
        isDragging = false;
      }
    }

    if (primaryIsDown)
    {
      print("PRIMARY UP");
      appState.hideStatusBarToolDimension();
      appState.hideStatusBarToolDiagonal();
      appState.hideStatusBarToolAngle();
      appState.hideStatusBarToolAspectRatio();
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
      setMouseCursor(SystemMouseCursors.none);
    }
    timerRunning = false;
  }



  void _updateLocation(PointerEvent details)
  {
    if (details.kind == PointerDeviceKind.touch)
    {
      touchPointers[details.pointer]?.currentPos = details.localPosition;
    }

    if (details.kind == PointerDeviceKind.touch && touchPointers.length == 2)
    {
      cursorPos.value = CursorCoordinates(x: (touchPointers.values.elementAt(0).currentPos.dx + touchPointers.values.elementAt(1).currentPos.dx) / 2, y: (touchPointers.values.elementAt(0).currentPos.dy + touchPointers.values.elementAt(1).currentPos.dy) / 2);
    }
    else
    {
      cursorPos.value = CursorCoordinates(x: details.localPosition.dx, y: details.localPosition.dy);
    }



    appState.setStatusBarCursorPosition(cursorPos.value!);
    if (primaryIsDown)
    {
      appState.setStatusBarToolDimension(pressStartLoc.dx.round(), pressStartLoc.dy.round(), cursorPos.value!.x.round(), cursorPos.value!.y.round());
      appState.setStatusBarToolDiagonal(pressStartLoc.dx.round(), pressStartLoc.dy.round(), cursorPos.value!.x.round(), cursorPos.value!.y.round());
      appState.setStatusBarToolAspectRatio(pressStartLoc.dx.round(), pressStartLoc.dy.round(), cursorPos.value!.x.round(), cursorPos.value!.y.round());
      appState.setStatusBarToolAngle(pressStartLoc.dx.round(), pressStartLoc.dy.round(), cursorPos.value!.x.round(), cursorPos.value!.y.round());

    }

    if (details.kind == PointerDeviceKind.mouse)
    {
      mouseIsInside = true;
    }

    if (needSecondaryStartLoc)
    {
      secondaryStartLoc = details.localPosition;
      needSecondaryStartLoc = false;
    }

    if (stylusZoomStarted)
    {
      double yOffset = secondaryStartLoc.dy - cursorPos.value!.y;
      int zoomSteps = (yOffset / options.stylusZoomStepDistance).round();
      appState.setZoomLevelByDistance(stylusZoomStartLevel, zoomSteps);
    }

    Offset co = Offset(cursorPos.value!.x, cursorPos.value!.y);


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
      setMouseCursor(SystemMouseCursors.move);
      dragStartLoc = co;
    }

    if (isDragging)
    {
      canvasOffset.value  = canvasOffset.value - (dragStartLoc - co);
      dragStartLoc = co;

      if (details.kind == PointerDeviceKind.touch && touchPointers.length == 2)
      {
        final double currentDistance = (touchPointers.values.elementAt(0).currentPos - touchPointers.values.elementAt(1).currentPos).distance;
        final int zoomSteps = ((currentDistance - initialTouchZoomDistance) / options.touchZoomStepDistance).round();
        appState.setZoomLevelByDistance(touchZoomStartLevel, zoomSteps);
      }
    }

  }

  void _hover(PointerHoverEvent details)
  {
    if (details.kind == PointerDeviceKind.stylus)
    {
      if (details.buttons == kSecondaryButton && !stylusButtonDetected)
      {
        stylusButtonDetected = true;
      }
      stylusHoverDetected = true;
    }
    _updateLocation(details);

  }

  void _scroll(PointerSignalEvent ev)
  {
    if (ev is PointerScrollEvent)
    {
      if (ev.scrollDelta.dy < 0.0)
      {
        appState.increaseZoomLevel();
      }
      else if (ev.scrollDelta.dy > 0.0)
      {
        appState.decreaseZoomLevel();
      }
    }
  }

  void _onMouseExit(PointerExitEvent _)
  {
    cursorPos.value = null;
    appState.repaintNotifier.repaint();
    mouseIsInside = false;
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
      setMouseCursor(SystemMouseCursors.none);
    }
    stylusButtonDetected = false;

    if (!stylusHoverDetected && cursorPos.value != null && !mouseIsInside)
    {
      cursorPos.value = null;
      appState.repaintNotifier.repaint();
    }
    else
    {
      stylusHoverDetected = false;
    }

  }

  void stylusBtnDown()
  {
    print("SECONDARY DOWN");
  }

  void stylusBtnUp()
  {
    print("SECONDARY UP");
  }

  void handleTimeoutStylusBtnLongPress()
  {
    print("STYLUS BTN LONG PRESS");
    timerStylusRunning = false;
    stylusZoomStarted = true;
    stylusZoomStartLevel = appState.getZoomLevel();
  }

  void setMouseCursor(final MouseCursor cursor)
  {
    mouseCursor.value = cursor;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: mouseCursor,
        builder: (BuildContext context, MouseCursor cursor, child)
        {
          return MouseRegion(
            onExit: _onMouseExit,
            //TODO this should depend on the tool and if user is above canvas => callback function to painter
            cursor: cursor,
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
                    appState: appState,
                    offset: canvasOffset,
                    checkerboardColor1: Theme.of(context).primaryColor,
                    checkerboardColor2: Theme.of(context).primaryColorLight,
                    coords: cursorPos,
                    options: GetIt.I.get<PreferenceManager>().kPixPainterOptions

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
      ),
    );
  }
}