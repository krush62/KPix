import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/color_names.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:kpix/widgets/color_chooser_widget.dart';
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
  final AppState appState;
  final PaletteWidgetOptions paletteOptions;
  final OverlayEntrySubMenuOptions overlayEntryOptions;
  final ColorChooserWidgetOptions colorChooserWidgetOptions;
  final ColorEntryWidgetOptions colorEntryWidgetOptions;
  final ColorNames colorNames;
  final OverlayEntryAlertDialogOptions alertDialogOptions;
  final KPalConstraints kPalConstraints;
  final KPalWidgetOptions kPalWidgetOptions;
  final ColorSelectedFn colorSelectedFn;
  final ColorRampFn updateRampFn;
  final ColorRampFn deleteRampFn;
  final AddNewRampFn addNewRampFn;


  const PaletteWidget(
    {
      super.key,
      required this.appState,
      required this.paletteOptions,
      required this.overlayEntryOptions,
      required this.colorChooserWidgetOptions,
      required this.colorNames,
      required this.colorEntryWidgetOptions,
      required this.alertDialogOptions,
      required this.kPalConstraints,
      required this.kPalWidgetOptions,
      required this.colorSelectedFn,
      required this.addNewRampFn,
      required this.deleteRampFn,
      required this.updateRampFn
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
        valueListenable: widget.appState.colorRamps,
        builder: (BuildContext context, List<KPalRampData> rampDataSet, child)
        {
          colorRampWidgetList.value = [];
          for (KPalRampData rampData in rampDataSet)
          {
            colorRampWidgetList.value.add(
                ColorRampRowWidget(
                  rampData: rampData,
                  colorSelectedFn: widget.colorSelectedFn,
                  colorsUpdatedFn: widget.updateRampFn,
                  deleteRowFn: widget.deleteRampFn,
                  colorNames: widget.colorNames,
                  colorEntryWidgetOptions: widget.colorEntryWidgetOptions,
                  appState: widget.appState,
                  alertDialogOptions: widget.alertDialogOptions,
                  kPalConstraints: widget.kPalConstraints,
                  kPalWidgetOptions: widget.kPalWidgetOptions,
                )
            );
          }
          colorRampWidgetList.value.add(ColorRampRowWidget(
            addNewRampFn: widget.addNewRampFn,
            colorEntryWidgetOptions: widget.colorEntryWidgetOptions,
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
                          padding: EdgeInsets.all(widget.paletteOptions.padding / 2.0),
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