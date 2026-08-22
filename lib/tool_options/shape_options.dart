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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/tool_options/tool_gui.dart';
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

const Map<ShapeShape, IconStringData> shapeData = <ShapeShape, IconStringData>{
  ShapeShape.triangle: IconStringData(name: "Triangle", icon: TablerIcons.triangle),
  ShapeShape.rectangle: IconStringData(name: "Rectangle", icon: TablerIcons.square),
  ShapeShape.diamond: IconStringData(name: "Mid-Angle Rectangle", icon: TablerIcons.diamonds),
  ShapeShape.ellipse: IconStringData(name: "Ellipse", icon: TablerIcons.circle),
  ShapeShape.ngon: IconStringData(name: "Regular Polygon", icon: TablerIcons.pentagon),
  ShapeShape.star: IconStringData(name: "Star", icon: TablerIcons.star),
};

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
        ToolSegmentedIconButtonRow<ShapeShape>(
          label: "Test",
          notifier: shapeOptions.shape,
          iconData: shapeData,
          iconSize: toolSettingsWidgetOptions.smallIconSize,
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
                  child: ToolSliderRow<int>(
                    label: "Corner Radius",
                    notifier: shapeOptions.cornerRadius,
                    flex: toolSettingsWidgetOptions.columnWidthRatio,
                    minVal: shapeOptions.cornerRadiusMin.toDouble(),
                    maxVal: shapeOptions.cornerRadiusMax.toDouble(),
                  ),
                ),
                Visibility(
                  //TODO this is a feature for the future
                  /*visible: (shape == ShapeShape.ellipse),*/
                  visible: false,
                  child: ToolSliderRow<int>(
                    notifier: shapeOptions.ellipseAngle,
                    label: "Angle",
                    flex: toolSettingsWidgetOptions.columnWidthRatio,
                    minVal: shapeOptions.ellipseAngleMin.toDouble(),
                    maxVal: shapeOptions.ellipseAngleMax.toDouble(),
                    //divisions: (shapeOptions.ellipseAngleMax - shapeOptions.ellipseAngleMin) ~/ shapeOptions.ellipseAngleSteps,
                  ),
                ),
                Visibility(
                  visible: shape == ShapeShape.ngon || shape == ShapeShape.star,
                  child: ToolSliderRow<int>(
                    notifier: shapeOptions.cornerCount,
                    label: "Corner Count",
                    flex: toolSettingsWidgetOptions.columnWidthRatio,
                    minVal: shapeOptions.cornerCountMin.toDouble(),
                    maxVal: shapeOptions.cornerCountMax.toDouble(),
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
    strokeWidth.value = (originalValue + steps).clamp(strokeWidthMin, strokeWidthMax);
  }

  @override
  int getSize()
  {
    return strokeWidth.value;
  }

}
