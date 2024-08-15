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
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/widgets/color_ramp_row_widget.dart';

class PaletteWidgetOptions
{
  final double padding;

  PaletteWidgetOptions({
    required this.padding,
  });

}

class PaletteWidget extends StatefulWidget
{
  const PaletteWidget(
    {
      super.key,
    }
  );

  @override
  State<PaletteWidget> createState() => _PaletteWidgetState();
}

class _PaletteWidgetState extends State<PaletteWidget>
{
  final ValueNotifier<List<ColorRampRowWidget>> _colorRampWidgetList = ValueNotifier([]);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder<List<KPalRampData>>(
        valueListenable: GetIt.I.get<AppState>().colorRampNotifier,
        builder: (final BuildContext context, final List<KPalRampData> rampDataSet, final Widget? child){

          final List<ColorRampRowWidget> widgetList = [];
          for (KPalRampData rampData in rampDataSet)
          {
            widgetList.add(
                ColorRampRowWidget(
                  rampData: rampData,
                  colorSelectedFn: GetIt.I.get<AppState>().colorSelected,
                  colorsUpdatedFn: GetIt.I.get<AppState>().updateRamp,
                  deleteRowFn: GetIt.I.get<AppState>().deleteRamp,
                )
            );
          }
          widgetList.add(ColorRampRowWidget(
            addNewRampFn: GetIt.I.get<AppState>().addNewRamp,
          ));
          _colorRampWidgetList.value = widgetList;
          return ValueListenableBuilder<List<ColorRampRowWidget>>(
            valueListenable: _colorRampWidgetList,
            builder: (final BuildContext context, final List<ColorRampRowWidget> widgetRows, final Widget? child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorDark,
                ),

                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: EdgeInsets.all(GetIt.I.get<PreferenceManager>().paletteWidgetOptions.padding / 2.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ...widgetRows
                      ],
                    )
                  ),
                )
              );
            }
          );
        }
      )
    );
  }
}