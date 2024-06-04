import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/preference_manager.dart';
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

  final ValueNotifier<List<ColorRampRowWidget>> colorRampWidgetList = ValueNotifier([]);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder<List<KPalRampData>>(
        valueListenable: GetIt.I.get<AppState>().colorRamps,
        builder: (BuildContext context, List<KPalRampData> rampDataSet, child)
        {
          colorRampWidgetList.value = [];
          for (KPalRampData rampData in rampDataSet)
          {
            colorRampWidgetList.value.add(
                ColorRampRowWidget(
                  rampData: rampData,
                  colorSelectedFn: GetIt.I.get<AppState>().colorSelected,
                  colorsUpdatedFn: GetIt.I.get<AppState>().updateRamp,
                  deleteRowFn: GetIt.I.get<AppState>().deleteRamp,
                )
            );
          }
          colorRampWidgetList.value.add(ColorRampRowWidget(
            addNewRampFn: GetIt.I.get<AppState>().addNewRamp,
          ));



          return ValueListenableBuilder<List<ColorRampRowWidget>>(
              valueListenable: colorRampWidgetList,
              builder: (BuildContext context, List<ColorRampRowWidget> widgetRows, child)
              {
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