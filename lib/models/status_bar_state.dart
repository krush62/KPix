import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/painting/itool_painter.dart';

class StatusBarState
{
  final ValueNotifier<String?> statusBarDimensionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarCursorPositionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarZoomFactorString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolDimensionString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolDiagonalString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolAspectRatioString = ValueNotifier(null);
  final ValueNotifier<String?> statusBarToolAngleString = ValueNotifier(null);

  double devicePixelRatio = 1.0;

  void setStatusBarDimensions(final int width, final int height)
  {
    statusBarDimensionString.value = "$width,$height";
  }

  void hideStatusBarDimension()
  {
    statusBarDimensionString.value = null;
  }

  void setStatusBarCursorPosition(final CoordinateSetI coords)
  {
    statusBarCursorPositionString.value = "${coords.x.toString()},${coords.y.toString()}";
  }

  void hideStatusBarCursorPosition()
  {
    statusBarCursorPositionString.value = null;
  }

  void setStatusBarZoomFactor(final int val)
  {
    int realVal = (val / devicePixelRatio).round();
    String suffix = "";
    if (realVal % 100 != 0)
    {
      suffix = " *";
    }

    statusBarZoomFactorString.value = "$val%$suffix";
  }

  void hideStatusBarZoomFactor()
  {
    statusBarZoomFactorString.value = null;
  }

  void setStatusBarToolDimension(final int width, final int height)
  {
    statusBarToolDimensionString.value = "$width,$height";
  }

  void hideStatusBarToolDimension()
  {
    statusBarToolDimensionString.value = null;
  }

  void setStatusBarToolDiagonal(final int width, final int height)
  {
    final double result = sqrt((width * width).toDouble() + (height * height).toDouble());
    statusBarToolDiagonalString.value = result.toStringAsFixed(1);  }

  void hideStatusBarToolDiagonal()
  {
    statusBarToolDiagonalString.value = null;
  }

  void setStatusBarToolAspectRatio(final int width, final int height)
  {
    final int divisor = Helper.gcd(width, height);
    final int reducedWidth = divisor != 0 ? width ~/ divisor : 0;
    final int reducedHeight = divisor != 0 ? height ~/ divisor : 0;
    statusBarToolAspectRatioString.value = '$reducedWidth:$reducedHeight';
  }

  void hideStatusBarToolAspectRatio()
  {
    statusBarToolAspectRatioString.value = null;
  }

  void setStatusBarToolAngle(final CoordinateSetI startPos, final CoordinateSetI endPos)
  {
    double angle = Helper.calculateAngle(startPos, endPos);
    statusBarToolAngleString.value = "${angle.toStringAsFixed(1)}°";
  }

  void hideStatusBarToolAngle()
  {
    statusBarToolAngleString.value = null;
  }

  void updateFromPaint(final StatusBarData statusBarData)
  {
    if (statusBarData.cursorPos != null)
    {
      setStatusBarCursorPosition(statusBarData.cursorPos!);
    }
    else
    {
      hideStatusBarCursorPosition();
    }

    if (statusBarData.dimension != null)
    {
      setStatusBarToolDimension(statusBarData.dimension!.x, statusBarData.dimension!.y);
    }
    else
    {
      hideStatusBarToolDimension();
    }

    if (statusBarData.diagonal != null)
    {
      setStatusBarToolDiagonal(statusBarData.diagonal!.x, statusBarData.diagonal!.y);
    }
    else
    {
      hideStatusBarToolDiagonal();
    }

    if (statusBarData.aspectRatio != null)
    {
      setStatusBarToolAspectRatio(statusBarData.aspectRatio!.x, statusBarData.aspectRatio!.y);
    }
    else
    {
      hideStatusBarToolAspectRatio();
    }

    if (statusBarData.angle != null && statusBarData.cursorPos != null)
    {
      setStatusBarToolAngle(statusBarData.angle!, statusBarData.cursorPos!);
    }
    else
    {
      hideStatusBarToolAngle();
    }
  }
}