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
import 'package:kpix/models/constraints/tool_pencil_constraints.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';

class PencilOptions extends IToolOptions
{
  final ValueNotifier<int> size = ValueNotifier<int>(PencilConstraints.sizeDefault);
  final ValueNotifier<PencilShape> shape = ValueNotifier<PencilShape>(PencilConstraints.shapeDefault);
  final ValueNotifier<bool> pixelPerfect = ValueNotifier<bool>(PencilConstraints.pixelPerfectDefault);
  final ValueNotifier<bool> unmodifiedPixelPerfect = ValueNotifier<bool>(PencilConstraints.pixelPerfectDefault);

  static Column getWidget({
    required final BuildContext context,
    required final PencilOptions pencilOptions,
  })
  {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ToolSliderRow<int>(
          label: "Size",
          notifier: pencilOptions.size,
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
          minVal: PencilConstraints.sizeMin.toDouble(),
          maxVal: PencilConstraints.sizeMax.toDouble(),
          //divisions: pencilOptions.sizeMax - pencilOptions.sizeMin,
        ),
        ToolDropdownRow<PencilShape>(
          label: "Shape",
          notifier: pencilOptions.shape,
          valueMap: PencilShape.getLabelMap(),
          flex: ToolSettingsWidgetOptions.columnWidthRatio,
        ),

        Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Smooth",
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
                  valueListenable: pencilOptions.unmodifiedPixelPerfect,
                  builder: (final BuildContext context, final bool pixelPerfect, final Widget? child){
                    bool newMode = pixelPerfect;
                    if (controlPressed)
                    {
                      newMode = false;
                    }
                    pencilOptions.pixelPerfect.value = newMode;
                    return Switch(
                      onChanged: (final bool newVal) {
                        if (!controlPressed)
                        {
                          pencilOptions.unmodifiedPixelPerfect.value = newVal;
                        }
                        pencilOptions.pixelPerfect.value = newVal;
                      },
                      value: pencilOptions.pixelPerfect.value,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ]
      ),



      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    size.value = (originalValue + steps).clamp(PencilConstraints.sizeMin, PencilConstraints.sizeMax);
  }

  @override
  int getSize()
  {
    return size.value;
  }

}
