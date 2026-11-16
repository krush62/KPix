/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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

import 'package:material_ui/material_ui.dart';

OutlinedBorder? getSegmentedButtonShape({required final BuildContext context, required final bool isTop})
{
  final ButtonStyle? segmentedStyle = SegmentedButtonTheme.of(context).style;
  final OutlinedBorder? themedShape = segmentedStyle?.shape?.resolve(<WidgetState>{});

  final OutlinedBorder? shape = switch (themedShape) {
    final RoundedRectangleBorder border => border.copyWith(
      borderRadius: border.borderRadius
          .resolve(Directionality.of(context))
          .copyWith(
        bottomLeft: isTop ? Radius.zero : null,
        bottomRight: isTop ? Radius.zero : null,
        topLeft: isTop ? null : Radius.zero,
        topRight: isTop ? null : Radius.zero,
      ),
    ),
    _ => themedShape,
  };
  return shape;
}
