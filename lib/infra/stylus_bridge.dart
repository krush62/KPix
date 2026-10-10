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

import 'package:flutter/services.dart';

/// Android stylus events that Flutter does not forward itself, sent by MainActivity.
class StylusBridge
{
  static const MethodChannel _channel = MethodChannel('app.channel.stylus');

  //set by the canvas widget
  //a hover exit is also sent right before the stylus touches the screen,
  //its time stamp uses the same clock as PointerEvent.timeStamp
  void Function({required Duration timeStamp})? onHoverExit;
  void Function({required bool pressed})? onButton;

  StylusBridge()
  {
    _channel.setMethodCallHandler(_handleCall);
  }

  Future<void> _handleCall(final MethodCall call) async
  {
    switch (call.method)
    {
      case 'hoverExit':
        onHoverExit?.call(timeStamp: Duration(milliseconds: call.arguments as int));
      case 'buttonPress':
        onButton?.call(pressed: true);
      case 'buttonRelease':
        onButton?.call(pressed: false);
    }
  }
}
