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
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/stamps/stamp_manager_entry_widget.dart';
import 'package:kpix/widgets/stamps/stamp_manager_widget.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';


class StampOptions extends IToolOptions
{
  final int scaleMin;
  final int scaleMax;
  final int scaleDefault;
  final bool flipHDefault;
  final bool flipVDefault;

  final ValueNotifier<int> scale = ValueNotifier<int>(1);
  final ValueNotifier<bool> flipH = ValueNotifier<bool>(false);
  final ValueNotifier<bool> flipV = ValueNotifier<bool>(false);


  StampOptions({
    required this.scaleMin,
    required this.scaleMax,
    required this.scaleDefault,
    required this.flipHDefault,
    required this.flipVDefault,
  })
  {
    scale.value = scaleDefault;
    flipH.value = flipHDefault;
    flipV.value = flipVDefault;
  }

  static Column getWidget({
    required final BuildContext context,
    required final ToolSettingsWidgetOptions toolSettingsWidgetOptions,
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
                            padding: EdgeInsets.all(toolSettingsWidgetOptions.padding),
                            child: RawImage(image: stampData.thumbnail, fit: BoxFit.contain, filterQuality: FilterQuality.none, scale: 0.1,),
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
            SizedBox(
              width: toolSettingsWidgetOptions.padding,
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Flip H",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                      SizedBox(width: toolSettingsWidgetOptions.padding),
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
                          child: Text(
                            "Flip V",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                      SizedBox(width: toolSettingsWidgetOptions.padding),
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
        Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Scale",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded
            (
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<int>(
                  valueListenable: stampOptions.scale,
                  builder: (final BuildContext context, final int scale, final Widget? child)
                  {
                    return KPixSlider(
                      value: scale.toDouble(),
                      min: stampOptions.scaleMin.toDouble(),
                      max: stampOptions.scaleMax.toDouble(),
                      divisions: stampOptions.scaleMax - stampOptions.scaleMin,
                      onChanged: (final double newVal) {stampOptions.scale.value = newVal.round();},
                      textStyle: Theme.of(context).textTheme.bodyLarge!,
                    );
                  },
                ),
              ),
            ),
          ],
        ),

      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    scale.value = (originalValue + steps).clamp(scaleMin, scaleMax);
  }

  @override
  int getSize()
  {
    return scale.value;
  }

}
