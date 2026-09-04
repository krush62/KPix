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
import 'package:kpix/models/constraints/tool_stamp_constraints.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/stamps/stamp_manager_entry_widget.dart';
import 'package:kpix/widgets/stamps/stamp_manager_widget.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';


class StampOptions extends IToolOptions
{
  final ValueNotifier<int> scale = ValueNotifier<int>(StampConstraints.scaleDefault);
  final ValueNotifier<bool> flipH = ValueNotifier<bool>(StampConstraints.flipHDefault);
  final ValueNotifier<bool> flipV = ValueNotifier<bool>(StampConstraints.flipVDefault);
  final ValueNotifier<bool> gridAlign = ValueNotifier<bool>(StampConstraints.gridAlignDefault);
  final ValueNotifier<int> gridOffsetX = ValueNotifier<int>(StampConstraints.gridOffsetDefault);
  final ValueNotifier<int> gridOffsetY = ValueNotifier<int>(StampConstraints.gridOffsetDefault);

  static Column getWidget({
    required final BuildContext context,
    required final StampOptions stampOptions,
    required final Function() showStampManager,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 80,
                child: OutlinedButton(
                  style: Theme.of(context).outlinedButtonTheme.style!.copyWith(
                    shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
                    side: WidgetStateProperty.all(BorderSide(width: 4.0, color: Theme.of(context).primaryColorLight)),
                  ),
                  onPressed: () {
                    showStampManager();
                  },
                  child: ValueListenableBuilder<StampManagerEntryData?>(
                    valueListenable: GetIt.I.get<StampManager>().selectedStamp,
                    builder: (final BuildContext context, final StampManagerEntryData? stampData, final Widget? child)
                    {
                      if (stampData != null)
                      {
                        if (stampData.thumbnail != null)
                        {
                          return Padding(
                            padding: const EdgeInsets.all(ToolSettingsWidgetOptions.padding),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: stampOptions.flipH,
                              builder: (final BuildContext contextH, final bool flipH, final Widget? childH) {
                                return ValueListenableBuilder<bool>(
                                  valueListenable: stampOptions.flipV,
                                  builder: (final BuildContext contextV, final bool flipV, final Widget? childV) {
                                    return Transform.flip(
                                      flipX: flipH,
                                      flipY: flipV,
                                      child: RawImage(image: stampData.thumbnail, fit: BoxFit.contain, filterQuality: FilterQuality.none, scale: 0.1,),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        }
                        else
                        {
                          return Text(stampData.name);
                        }
                      }
                      else
                      {
                        return const Text("<NO STAMP>");
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: ToolSettingsWidgetOptions.padding),
            Expanded(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            color: Theme.of(context).primaryColorLight,
                            TablerIcons.flip_vertical,
                          ),
                        ),
                      ),
                      const SizedBox(width: ToolSettingsWidgetOptions.padding),
                      ValueListenableBuilder<bool>(
                        valueListenable: stampOptions.flipH,
                        builder: (final BuildContext context, final bool flipH, final Widget? child){
                          return Switch(
                            onChanged: (final bool newVal) {stampOptions.flipH.value = newVal;},
                            value: flipH,
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded
                        (
                        child: Align
                          (
                          alignment: Alignment.centerRight,
                          child: Icon(
                            color: Theme.of(context).primaryColorLight,
                            TablerIcons.flip_horizontal,
                          ),
                        ),
                      ),
                      const SizedBox(width: ToolSettingsWidgetOptions.padding),
                      ValueListenableBuilder<bool>(
                        valueListenable: stampOptions.flipV,
                        builder: (final BuildContext context, final bool flipV, final Widget? child){
                          return Switch(
                            onChanged: (final bool newVal) {stampOptions.flipV.value = newVal;},
                            value: flipV,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Visibility(
          visible: false,
          child: ToolSliderRow<int>(
            label: "Scale",
            notifier: stampOptions.scale,
            flex: ToolSettingsWidgetOptions.columnWidthRatio,
            minVal: StampConstraints.scaleMin.toDouble(),
            maxVal: StampConstraints.scaleMax.toDouble(),
            //divisions: stampOptions.scaleMax - stampOptions.scaleMin,
          ),
        ),
        ToolSwitchRow(
          notifier: stampOptions.gridAlign,
          label: "Grid Align",
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: stampOptions.gridAlign,
          builder: (final BuildContext context, final bool gridAlign, final Widget? child) {
            if (gridAlign)
            {
              return Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Offset X",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: ToolSettingsWidgetOptions.columnWidthRatio,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ValueListenableBuilder<StampManagerEntryData?>(
                        valueListenable: GetIt.I.get<StampManager>().selectedStamp,
                        builder: (final BuildContext context, final StampManagerEntryData? stampData, final Widget? child)
                        {
                          if (stampData != null)
                          {
                            return ValueListenableBuilder<int>(
                              valueListenable: stampOptions.gridOffsetX,
                              builder: (final BuildContext context, final int offsetX, final Widget? child)
                              {
                                return KPixSlider(
                                  value: offsetX.toDouble(),
                                  max: stampData.width - 1,
                                  //divisions: stampOptions.scaleMax - stampOptions.scaleMin,
                                  onChanged: (final double newVal) {stampOptions.gridOffsetX.value = newVal.round();},
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                );
                              },
                            );
                          }
                          else
                          {
                            return const SizedBox();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
            }
            else
            {
              return const SizedBox();
            }
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: stampOptions.gridAlign,
          builder: (final BuildContext context, final bool gridAlign, final Widget? child) {
            if (gridAlign)
            {
              return Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Offset Y",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: ToolSettingsWidgetOptions.columnWidthRatio,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ValueListenableBuilder<StampManagerEntryData?>(
                        valueListenable: GetIt.I.get<StampManager>().selectedStamp,
                        builder: (final BuildContext context, final StampManagerEntryData? stampData, final Widget? child)
                        {
                          if (stampData != null)
                          {
                            return ValueListenableBuilder<int>(
                              valueListenable: stampOptions.gridOffsetY,
                              builder: (final BuildContext context, final int offsetY, final Widget? child) {


                                return KPixSlider(
                                  value: offsetY.toDouble(),
                                  max: stampData.height - 1,
                                  //divisions: stampOptions.scaleMax - stampOptions.scaleMin,
                                  onChanged: (final double newVal) {stampOptions.gridOffsetY.value = newVal.round();},
                                  textStyle: Theme.of(context).textTheme.bodyLarge!,
                                );
                              },
                            );
                          }
                          else
                          {
                            return const SizedBox();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
            }
            else
            {
              return const SizedBox();
            }
          },
        ),
      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    scale.value = (originalValue + steps).clamp(StampConstraints.scaleMin, StampConstraints.scaleMax);
  }

  @override
  int getSize()
  {
    return scale.value;
  }

}
