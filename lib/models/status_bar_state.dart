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
import 'package:kpix/util/helper.dart';
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

  void setStatusBarDimensions({required final int width, required final int height})
  {
    statusBarDimensionString.value = "$width,$height";
  }

  void hideStatusBarDimension()
  {
    statusBarDimensionString.value = null;
  }

  void setStatusBarCursorPosition({required final CoordinateSetI coords})
  {
    statusBarCursorPositionString.value = "${coords.x.toString()},${coords.y.toString()}";
  }

  void hideStatusBarCursorPosition()
  {
    statusBarCursorPositionString.value = null;
  }

  void setStatusBarZoomFactor({required final int val})
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

  void setStatusBarToolDimension({required final int width, required final int height})
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

  void setStatusBarToolAspectRatio({required final int width, required final int height})
  {
    final int divisor = Helper.gcd(a: width, b: height);
    final int reducedWidth = divisor != 0 ? width ~/ divisor : 0;
    final int reducedHeight = divisor != 0 ? height ~/ divisor : 0;
    statusBarToolAspectRatioString.value = '$reducedWidth:$reducedHeight';
  }

  void hideStatusBarToolAspectRatio()
  {
    statusBarToolAspectRatioString.value = null;
  }

  void setStatusBarToolAngle({required final CoordinateSetI startPos, required final CoordinateSetI endPos})
  {
    double angle = Helper.calculateAngle(startPos: startPos, endPos: endPos);
    statusBarToolAngleString.value = "${angle.toStringAsFixed(1)}°";
  }

  void hideStatusBarToolAngle()
  {
    statusBarToolAngleString.value = null;
  }

  void updateFromPaint({required final StatusBarData statusBarData})
  {
    if (statusBarData.cursorPos != null)
    {
      setStatusBarCursorPosition(coords: statusBarData.cursorPos!);
    }
    else
    {
      hideStatusBarCursorPosition();
    }

    if (statusBarData.dimension != null)
    {
      setStatusBarToolDimension(width: statusBarData.dimension!.x, height: statusBarData.dimension!.y);
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
      setStatusBarToolAspectRatio(width: statusBarData.aspectRatio!.x, height: statusBarData.aspectRatio!.y);
    }
    else
    {
      hideStatusBarToolAspectRatio();
    }

    if (statusBarData.angle != null && statusBarData.cursorPos != null)
    {
      setStatusBarToolAngle(startPos: statusBarData.angle!, endPos: statusBarData.cursorPos!);
    }
    else
    {
      hideStatusBarToolAngle();
    }
  }
}