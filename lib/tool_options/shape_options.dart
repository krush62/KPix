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

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/models/constraints/tool_shape_constraints.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';




class ShapeOptions extends IToolOptions
{
  final ValueNotifier<DrawingShape> shape = ValueNotifier<DrawingShape>(ToolShapeConstraints.shapeDefault);
  final ValueNotifier<bool> keepRatio = ValueNotifier<bool>(ToolShapeConstraints.keepRatioDefault);
  final ValueNotifier<bool> unmodifiedKeepRatio = ValueNotifier<bool>(ToolShapeConstraints.keepRatioDefault);
  final ValueNotifier<bool> strokeOnly = ValueNotifier<bool>(ToolShapeConstraints.strokeOnlyDefault);
  final ValueNotifier<int> strokeWidth = ValueNotifier<int>(ToolShapeConstraints.strokeWidthDefault);
  final ValueNotifier<int> cornerRadius = ValueNotifier<int>(ToolShapeConstraints.cornerRadiusDefault);
  final ValueNotifier<int> cornerCount= ValueNotifier<int>(ToolShapeConstraints.cornerCountDefault);
  final ValueNotifier<int> ellipseAngle = ValueNotifier<int>(ToolShapeConstraints.ellipseAngleDefault);

  static Column getWidget(
  {   required final BuildContext context,
      required final ShapeOptions shapeOptions,})
  {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ToolSegmentedIconButtonRow<DrawingShape>(
          label: "Shape",
          notifier: shapeOptions.shape,
          iconData: DrawingShape.getLabelIconMap(),
          iconSize: ToolSettingsWidgetOptions.smallIconSize,
          hideLabel: true,
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
              flex: ToolSettingsWidgetOptions.columnWidthRatio,
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
              flex: ToolSettingsWidgetOptions.columnWidthRatio,
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
                              min: ToolShapeConstraints.strokeWidthMin.toDouble(),
                              max: ToolShapeConstraints.strokeWidthMax.toDouble(),
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
        ValueListenableBuilder<DrawingShape>(
          valueListenable: shapeOptions.shape,
          builder: (final BuildContext context, final DrawingShape shape, final Widget? child){
            return Stack(
              children: <Widget>[
                Visibility(
                  //TODO this might be an option for triangle and diamond as well
                  visible: shape == DrawingShape.rectangle,
                  child: ToolSliderRow<int>(
                    label: "Corner Radius",
                    notifier: shapeOptions.cornerRadius,
                    flex: ToolSettingsWidgetOptions.columnWidthRatio,
                    minVal: ToolShapeConstraints.cornerRadiusMin.toDouble(),
                    maxVal: ToolShapeConstraints.cornerRadiusMax.toDouble(),
                  ),
                ),
                Visibility(
                  //TODO this is a feature for the future
                  /*visible: (shape == ShapeShape.ellipse),*/
                  visible: false,
                  child: ToolSliderRow<int>(
                    notifier: shapeOptions.ellipseAngle,
                    label: "Angle",
                    flex: ToolSettingsWidgetOptions.columnWidthRatio,
                    minVal: ToolShapeConstraints.ellipseAngleMin.toDouble(),
                    maxVal: ToolShapeConstraints.ellipseAngleMax.toDouble(),
                    //divisions: (shapeOptions.ellipseAngleMax - shapeOptions.ellipseAngleMin) ~/ shapeOptions.ellipseAngleSteps,
                  ),
                ),
                Visibility(
                  visible: shape == DrawingShape.ngon || shape == DrawingShape.star,
                  child: ToolSliderRow<int>(
                    notifier: shapeOptions.cornerCount,
                    label: "Corner Count",
                    flex: ToolSettingsWidgetOptions.columnWidthRatio,
                    minVal: ToolShapeConstraints.cornerCountMin.toDouble(),
                    maxVal: ToolShapeConstraints.cornerCountMax.toDouble(),
                    //divisions: shapeOptions.cornerCountMax - shapeOptions.cornerCountMin,
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
    strokeWidth.value = (originalValue + steps).clamp(ToolShapeConstraints.strokeWidthMin, ToolShapeConstraints.strokeWidthMax);
  }

  @override
  int getSize()
  {
    return strokeWidth.value;
  }

}
