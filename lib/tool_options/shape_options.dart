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
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

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
[
  ShapeShape.triangle,
  ShapeShape.rectangle,
  ShapeShape.diamond,
  ShapeShape.ellipse,
  ShapeShape.ngon,
  ShapeShape.star

];

const Map<int, ShapeShape> _shapeShapeIndexMap =
{
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


  final ValueNotifier<ShapeShape> shape = ValueNotifier(ShapeShape.rectangle);
  final ValueNotifier<bool> keepRatio = ValueNotifier(false);
  final ValueNotifier<bool> strokeOnly = ValueNotifier(false);
  final ValueNotifier<int> strokeWidth = ValueNotifier(1);
  final ValueNotifier<int> cornerRadius = ValueNotifier(0);
  final ValueNotifier<int> cornerCount= ValueNotifier(5);
  final ValueNotifier<int> ellipseAngle = ValueNotifier(0);

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
    strokeOnly.value = strokeOnlyDefault;
    strokeWidth.value = strokeWidthDefault;
    cornerRadius.value = cornerRadiusDefault;
    cornerCount.value = cornerCountDefault;
    ellipseAngle.value = ellipseAngleDefault;
  }

  static Column getWidget(
  {   required BuildContext context,
      required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
      required ShapeOptions shapeOptions})
  {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Size",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<ShapeShape>(
                valueListenable: shapeOptions.shape,
                builder: (final BuildContext context, final ShapeShape shape, final Widget? child)
                {
                  return SegmentedButton<ShapeShape>(
                    segments: [
                      ButtonSegment(
                        value: ShapeShape.triangle,
                        label: Icon(
                          Icons.change_history,
                          size: toolSettingsWidgetOptions.smallIconSize)),
                      ButtonSegment(
                        value: ShapeShape.rectangle,
                        tooltip: "Rectangle",
                        label: Icon(
                          Icons.check_box_outline_blank,
                          size: toolSettingsWidgetOptions.smallIconSize,)),
                      ButtonSegment(
                        value: ShapeShape.diamond,
                        tooltip: "Mid-Angle Rectangle",
                        label: Transform.rotate(
                          angle: -pi / 4,
                          child: Icon(
                            Icons.check_box_outline_blank,
                            size: toolSettingsWidgetOptions.smallIconSize,),)),
                      ButtonSegment(
                        value: ShapeShape.ellipse,
                        tooltip: "Ellipse",
                        label: Icon(
                          Icons.circle_outlined,
                          size: toolSettingsWidgetOptions.smallIconSize,)),
                      ButtonSegment(
                        value: ShapeShape.ngon,
                        tooltip: "Regular Polygon",
                        label: Icon(
                          Icons.hexagon_outlined,
                          size: toolSettingsWidgetOptions.smallIconSize,)),
                      ButtonSegment(
                        value: ShapeShape.star,
                        tooltip: "Star",
                        label: Icon(
                          Icons.star_outline,
                          size: toolSettingsWidgetOptions.smallIconSize,)),
                    ],
                    selected: <ShapeShape>{shape},
                    emptySelectionAllowed: false,
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                    onSelectionChanged: (Set<ShapeShape> shapes) {shapeOptions.shape.value = shapes.first;},
                  );
                },
              ),
            ),

          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Keep 1:1",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<bool>(
                  valueListenable: shapeOptions.keepRatio,
                  builder: (final BuildContext context, final bool keep, final Widget? child)
                  {
                    return Switch(
                      onChanged: (bool newVal) {shapeOptions.keepRatio.value = newVal;},
                      value: keep,
                    );
                  },
                ),
              )
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Stroke Only",
                  style: Theme.of(context).textTheme.labelLarge,
                )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<bool>(
                valueListenable: shapeOptions.strokeOnly,
                builder: (final BuildContext context, final bool strokeOnly, final Widget? child){
                  return Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Switch(
                            onChanged: (bool newVal) {shapeOptions.strokeOnly.value = newVal;},
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
                            return Slider(
                              value: width.toDouble(),
                              min: shapeOptions.strokeWidthMin.toDouble(),
                              max: shapeOptions.strokeWidthMax.toDouble(),
                              divisions: shapeOptions.strokeWidthMax - shapeOptions.strokeWidthMin,
                              onChanged: strokeOnly ? (double newVal) {shapeOptions.strokeWidth.value = newVal.round();} : null,
                              label: width.round().toString(),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              )
            ),
          ],
        ),
        ValueListenableBuilder<ShapeShape>(
          valueListenable: shapeOptions.shape,
          builder: (final BuildContext context, final ShapeShape shape, final Widget? child){
            return Stack(
              children: [
                Visibility(
                  //TODO this might be an option for triangle and diamond as well
                  visible: (shape == ShapeShape.rectangle),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Corner Radius",
                            style: Theme.of(context).textTheme.labelLarge,
                          )
                        ),
                      ),
                      Expanded(
                        flex: toolSettingsWidgetOptions.columnWidthRatio,
                        child: ValueListenableBuilder<int>(
                          valueListenable: shapeOptions.cornerRadius,
                          builder: (final BuildContext context, final int cornerRadius, final Widget? child)
                          {
                            return Slider(
                              value: cornerRadius.toDouble(),
                              min: shapeOptions.cornerRadiusMin.toDouble(),
                              max: shapeOptions.cornerRadiusMax.toDouble(),
                              divisions: shapeOptions.cornerRadiusMax - shapeOptions.cornerRadiusMin,
                              onChanged: (double newVal) {shapeOptions.cornerRadius.value = newVal.round();},
                              label: cornerRadius.round().toString(),
                            );
                          }
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
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Angle",
                            style: Theme.of(context).textTheme.labelLarge,
                          )
                        ),
                      ),
                      Expanded(
                        flex: toolSettingsWidgetOptions.columnWidthRatio,
                        child: ValueListenableBuilder<int>(
                          valueListenable: shapeOptions.ellipseAngle,
                          builder: (final BuildContext context, final int angle, final Widget? child)
                          {
                            return Slider(
                              value: angle.toDouble(),
                              min: shapeOptions.ellipseAngleMin.toDouble(),
                              max: shapeOptions.ellipseAngleMax.toDouble(),
                              divisions: (shapeOptions.ellipseAngleMax - shapeOptions.ellipseAngleMin) ~/ shapeOptions.ellipseAngleSteps,
                              onChanged: (final double newVal) {shapeOptions.ellipseAngle.value = newVal.round();},
                              label: angle.round().toString(),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: (shape == ShapeShape.ngon || shape == ShapeShape.star),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Corner Count",
                            style: Theme.of(context).textTheme.labelLarge,
                          )
                        ),
                      ),
                      Expanded(
                        flex: toolSettingsWidgetOptions.columnWidthRatio,
                        child: ValueListenableBuilder<int>(
                          valueListenable: shapeOptions.cornerCount,
                          builder: (final BuildContext context, final int corners, final Widget? child)
                          {
                            return Slider(
                              value: corners.toDouble(),
                              min: shapeOptions.cornerCountMin.toDouble(),
                              max: shapeOptions.cornerCountMax.toDouble(),
                              divisions: (shapeOptions.cornerCountMax - shapeOptions.cornerCountMin),
                              onChanged: (double newVal) {shapeOptions.cornerCount.value = newVal.round();},
                              label: corners.round().toString(),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        ),
      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    strokeWidth.value = min(max(originalValue + steps, strokeWidthMin), strokeWidthMax);
  }

  @override
  int getSize()
  {
    return strokeWidth.value;
  }

}