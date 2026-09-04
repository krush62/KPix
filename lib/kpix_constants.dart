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

import 'dart:collection';

import 'package:flutter/material.dart';

/// Every direction a layer stroke or drop shadow can point.
///
/// Shared by the direction picker, the drawing-layer settings and their history
/// snapshot, so it cannot live in the widget that happens to render it.
final LinkedHashSet<Alignment> allAlignments = LinkedHashSet<Alignment>.from(<Alignment>[Alignment.topLeft, Alignment.topCenter, Alignment.topRight, Alignment.centerRight, Alignment.bottomRight, Alignment.bottomCenter, Alignment.bottomLeft, Alignment.centerLeft]);

/// How long the pointer has to rest on a control before its tooltip appears.
///
/// Used by every widget that shows one, which is why it is a plain constant
/// rather than a member of any state object.
const Duration toolTipDuration = Duration(seconds: 1);

/// Layout of the tool settings column.
///
/// Every tool's options widget lays itself out against these, which is why they
/// are not a member of the widget that hosts them.
abstract final class ToolSettingsWidgetOptions
{
  static const int columnWidthRatio = 2;
  static const double padding = 8.0;
  static const double smallButtonSize = 36.0;
  static const double smallIconSize = 20.0;
}
