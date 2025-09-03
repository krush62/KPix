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
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

enum ShapeShape
{
  triangle,
  rectangle,
  diamond,
  ellipse,
  ngon,
  star
}

const List<ShapeShape> shapeShapeList =
<ShapeShape>[
  ShapeShape.triangle,
  ShapeShape.rectangle,
  ShapeShape.diamond,
  ShapeShape.ellipse,
  ShapeShape.ngon,
  ShapeShape.star,

];

const Map<int, ShapeShape> _shapeShapeIndexMap =
<int, ShapeShape>{
  0: ShapeShape.triangle,
  1: ShapeShape.rectangle,
  2: ShapeShape.diamond,
  3: ShapeShape.ellipse,
  4: ShapeShape.ngon,
  5: ShapeShape.star,
};


class ShapeOptions extends IToolOptions
{
  final int shapeDefault;
  final bool keepRatioDefault;
  final bool strokeOnlyDefault;
  final int strokeWidthMin;
  final int strokeWidthMax;
  final int strokeWidthDefault;
  final int cornerRadiusMin;
  final int cornerRadiusMax;
  final int cornerRadiusDefault;
  final int ellipseAngleMin;
  final int ellipseAngleMax;
  final int ellipseAngleDefault;
  final int ellipseAngleSteps;
  final int cornerCountMin;
  final int cornerCountMax;
  final int cornerCountDefault;


  final ValueNotifier<ShapeShape> shape = ValueNotifier<ShapeShape>(ShapeShape.rectangle);
  final ValueNotifier<bool> keepRatio = ValueNotifier<bool>(false);
  final ValueNotifier<bool> unmodifiedKeepRatio = ValueNotifier<bool>(false);
  final ValueNotifier<bool> strokeOnly = ValueNotifier<bool>(false);
  final ValueNotifier<int> strokeWidth = ValueNotifier<int>(1);
  final ValueNotifier<int> cornerRadius = ValueNotifier<int>(0);
  final ValueNotifier<int> cornerCount= ValueNotifier<int>(5);
  final ValueNotifier<int> ellipseAngle = ValueNotifier<int>(0);

  ShapeOptions({
    required this.shapeDefault,
    required this.keepRatioDefault,
    required this.strokeOnlyDefault,
    required this.strokeWidthMin,
    required this.strokeWidthMax,
    required this.strokeWidthDefault,
    required this.cornerRadiusMin,
    required this.cornerRadiusMax,
    required this.cornerRadiusDefault,
    required this.cornerCountMin,
    required this.cornerCountMax,
    required this.cornerCountDefault,
    required this.ellipseAngleMin,
    required this.ellipseAngleMax,
    required this.ellipseAngleDefault,
    required this.ellipseAngleSteps,
  }) {
    shape.value = _shapeShapeIndexMap[shapeDefault] ?? ShapeShape.rectangle;
    keepRatio.value = keepRatioDefault;
    unmodifiedKeepRatio.value = keepRatioDefault;
    strokeOnly.value = strokeOnlyDefault;
    strokeWidth.value = strokeWidthDefault;
    cornerRadius.value = cornerRadiusDefault;
    cornerCount.value = cornerCountDefault;
    ellipseAngle.value = ellipseAngleDefault;
  }

  static Column getWidget(
  {   required final BuildContext context,
      required final ToolSettingsWidgetOptions toolSettingsWidgetOptions,
      required final ShapeOptions shapeOptions,})
  {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ValueListenableBuilder<ShapeShape>(
          valueListenable: shapeOptions.shape,
          builder: (final BuildContext context, final ShapeShape shape, final Widget? child)
          {
            return SegmentedButton<ShapeShape>(
              segments: <ButtonSegment<ShapeShape>>[
                ButtonSegment<ShapeShape>(
                  value: ShapeShape.triangle,
                  label: Tooltip(
                    message: "Triangle",
                    waitDuration: AppState.toolTipDuration,
                    child: Icon(
                      Icons.change_history,
                      size: toolSettingsWidgetOptions.smallIconSize,
                    ),
                  ),
                ),
                ButtonSegment<ShapeShape>(
                  value: ShapeShape.rectangle,
                  label: Tooltip(
                    message: "Rectangle",
                    waitDuration: AppState.toolTipDuration,
                    child: Icon(
                      Icons.check_box_outline_blank,
                      size: toolSettingsWidgetOptions.smallIconSize,
                    ),
                  ),
                ),
                ButtonSegment<ShapeShape>(
                  value: ShapeShape.diamond,
                  label: Tooltip(
                    message: "Mid-Angle Rectangle",
                    waitDuration: AppState.toolTipDuration,
                    child: Transform.rotate(
                      angle: -pi / 4,
                      child: Icon(
                        Icons.check_box_outline_blank,
                        size: toolSettingsWidgetOptions.smallIconSize,
                      ),
                    ),
                  ),
                ),
                ButtonSegment<ShapeShape>(
                  value: ShapeShape.ellipse,
                  label: Tooltip(
                    message: "Ellipse",
                    waitDuration: AppState.toolTipDuration,
                    child: Icon(
                      Icons.circle_outlined,
                      size: toolSettingsWidgetOptions.smallIconSize,
                    ),
                  ),
                ),
                ButtonSegment<ShapeShape>(
                  value: ShapeShape.ngon,
                  label: Tooltip(
                    message: "Regular Polygon",
                    waitDuration: AppState.toolTipDuration,
                    child: Icon(
                      Icons.hexagon_outlined,
                      size: toolSettingsWidgetOptions.smallIconSize,
                    ),
                  ),
                ),
                ButtonSegment<ShapeShape>(
                  value: ShapeShape.star,
                  label: Tooltip(
                    message: "Star",
                    waitDuration: AppState.toolTipDuration,
                    child: Icon(
                      Icons.star_outline,
                      size: toolSettingsWidgetOptions.smallIconSize,
                    ),
                  ),
                ),
              ],
              selected: <ShapeShape>{shape},
              showSelectedIcon: false,
              onSelectionChanged: (final Set<ShapeShape> shapes) {shapeOptions.shape.value = shapes.first;},
            );
          },
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Keep 1:1",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<bool>(
                  valueListenable: hotkeyManager.controlNotifier,
                  builder: (final BuildContext _, final bool controlPressed, final Widget? __) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: shapeOptions.unmodifiedKeepRatio,
                      builder: (final BuildContext context, final bool unmodifiedKeep, final Widget? child) {
                        bool newMode = unmodifiedKeep;
                        if (controlPressed)
                        {
                          newMode = true;
                        }
                        shapeOptions.keepRatio.value = newMode;
                        return Switch(
                          onChanged: (final bool newVal) {
                            if (!controlPressed)
                            {
                              shapeOptions.unmodifiedKeepRatio.value = newVal;
                            }
                            shapeOptions.keepRatio.value = newVal;
                            },
                          value: shapeOptions.keepRatio.value,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Stroke Only",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<bool>(
                valueListenable: shapeOptions.strokeOnly,
                builder: (final BuildContext context, final bool strokeOnly, final Widget? child){
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Switch(
                            onChanged: (final bool newVal) {shapeOptions.strokeOnly.value = newVal;},
                            value: strokeOnly,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ValueListenableBuilder<int>(
                          valueListenable: shapeOptions.strokeWidth,
                          builder: (final BuildContext context, final int width, final Widget? child)
                          {
                            return KPixSlider(
                              value: width.toDouble(),
                              min: shapeOptions.strokeWidthMin.toDouble(),
                              max: shapeOptions.strokeWidthMax.toDouble(),
                              //divisions: shapeOptions.strokeWidthMax - shapeOptions.strokeWidthMin,
                              onChanged: strokeOnly ? (final double newVal) {shapeOptions.strokeWidth.value = newVal.round();} : null,
                              textStyle: Theme.of(context).textTheme.bodyLarge!,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        ValueListenableBuilder<ShapeShape>(
          valueListenable: shapeOptions.shape,
          builder: (final BuildContext context, final ShapeShape shape, final Widget? child){
            return Stack(
              children: <Widget>[
                Visibility(
                  //TODO this might be an option for triangle and diamond as well
                  visible: shape == ShapeShape.rectangle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Corner Radius",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: toolSettingsWidgetOptions.columnWidthRatio,
                        child: ValueListenableBuilder<int>(
                          valueListenable: shapeOptions.cornerRadius,
                          builder: (final BuildContext context, final int cornerRadius, final Widget? child)
                          {
                            return KPixSlider(
                              value: cornerRadius.toDouble(),
                              min: shapeOptions.cornerRadiusMin.toDouble(),
                              max: shapeOptions.cornerRadiusMax.toDouble(),
                              //divisions: shapeOptions.cornerRadiusMax - shapeOptions.cornerRadiusMin,
                              onChanged: (final double newVal) {shapeOptions.cornerRadius.value = newVal.round();},
                              textStyle: Theme.of(context).textTheme.bodyLarge!,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  //TODO this is a feature for the future
                  /*visible: (shape == ShapeShape.ellipse),*/
                  visible: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Angle",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: toolSettingsWidgetOptions.columnWidthRatio,
                        child: ValueListenableBuilder<int>(
                          valueListenable: shapeOptions.ellipseAngle,
                          builder: (final BuildContext context, final int angle, final Widget? child)
                          {
                            return KPixSlider(
                              value: angle.toDouble(),
                              min: shapeOptions.ellipseAngleMin.toDouble(),
                              max: shapeOptions.ellipseAngleMax.toDouble(),
                              //divisions: (shapeOptions.ellipseAngleMax - shapeOptions.ellipseAngleMin) ~/ shapeOptions.ellipseAngleSteps,
                              onChanged: (final double newVal) {shapeOptions.ellipseAngle.value = newVal.round();},
                              textStyle: Theme.of(context).textTheme.bodyLarge!,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: shape == ShapeShape.ngon || shape == ShapeShape.star,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Corner Count",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: toolSettingsWidgetOptions.columnWidthRatio,
                        child: ValueListenableBuilder<int>(
                          valueListenable: shapeOptions.cornerCount,
                          builder: (final BuildContext context, final int corners, final Widget? child)
                          {
                            return KPixSlider(
                              value: corners.toDouble(),
                              min: shapeOptions.cornerCountMin.toDouble(),
                              max: shapeOptions.cornerCountMax.toDouble(),
                              //divisions: shapeOptions.cornerCountMax - shapeOptions.cornerCountMin,
                              onChanged: (final double newVal) {shapeOptions.cornerCount.value = newVal.round();},
                              textStyle: Theme.of(context).textTheme.bodyLarge!,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    strokeWidth.value = (originalValue + steps).clamp(strokeWidthMin, strokeWidthMax);
  }

  @override
  int getSize()
  {
    return strokeWidth.value;
  }

}
