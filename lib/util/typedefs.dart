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

import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/file/export_palette_widget.dart';

typedef IdColorSelectedFn = void Function({required IdColor newColor});
typedef ColorReferenceSelectedFn = void Function({required ColorReference? color});
typedef ColorRampFn = void Function({required KPalRampData ramp, bool addToHistoryStack});
typedef ColorRampUpdateFn = void Function({required KPalRampData ramp, required KPalRampData originalData, bool addToHistoryStack});
typedef ExportDataFn = void Function({required ExportData exportData, required ExportType exportType});
typedef PaletteDataFn = void Function({required PaletteExportData saveData, required PaletteType paletteType});
typedef CanvasSizeFn = void Function({required CoordinateSetI size, required CoordinateSetI offset});
typedef NewFileFn = void Function({required CoordinateSetI size});
typedef SaveFileFn = void Function({required String fileName, required Function()? callback});

typedef CoordinateColorMap = HashMap<CoordinateSetI, ColorReference>;
typedef CoordinateColorMapNullable = HashMap<CoordinateSetI, ColorReference?>;
typedef CoordinateColor = MapEntry<CoordinateSetI, ColorReference>;
typedef CoordinateColorNullable = MapEntry<CoordinateSetI, ColorReference?>;