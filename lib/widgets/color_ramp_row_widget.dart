import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/color_names.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class ColorRampRowWidget extends StatefulWidget {
  final KPalRampData? rampData;
  final ColorSelectedFn? colorSelectedFn;
  final ColorRampFn? colorsUpdatedFn;
  final ColorRampFn? deleteRowFn;
  final AddNewRampFn? addNewRampFn;
  final ColorEntryWidgetOptions colorEntryWidgetOptions;
  final AppState? appState;
  final List<Widget> widgetList;
  final KPalWidgetOptions? kPalWidgetOptions;
  final KPalConstraints? kPalConstraints;
  final OverlayEntryAlertDialogOptions? alertDialogOptions;
  final ColorNames? colorNames;

  @override
  State<ColorRampRowWidget> createState() => _ColorRampRowWidgetState();

  const ColorRampRowWidget._({
    super.key,
    this.rampData,
    this.colorSelectedFn,
    this.addNewRampFn,
    this.deleteRowFn,
    this.colorsUpdatedFn,
    required this.colorEntryWidgetOptions,
    this.appState,
    this.kPalConstraints,
    this.kPalWidgetOptions,
    this.alertDialogOptions,
    required this.widgetList,
    this.colorNames,
  });

  factory ColorRampRowWidget({
    KPalRampData? rampData,
    ColorSelectedFn? colorSelectedFn,
    AddNewRampFn? addNewRampFn,
    ColorRampFn? deleteRowFn,
    ColorRampFn? colorsUpdatedFn,
    required ColorEntryWidgetOptions colorEntryWidgetOptions,
    AppState? appState,
    KPalConstraints? kPalConstraints,
    KPalWidgetOptions? kPalWidgetOptions,
    OverlayEntryAlertDialogOptions? alertDialogOptions,
    ColorNames? colorNames,
  }){
    List<Widget> widgetList = [];
    return ColorRampRowWidget._(
      colorEntryWidgetOptions: colorEntryWidgetOptions,
      addNewRampFn: addNewRampFn,
      widgetList: widgetList,
      kPalWidgetOptions: kPalWidgetOptions,
      kPalConstraints: kPalConstraints,
      alertDialogOptions: alertDialogOptions,
      colorSelectedFn: colorSelectedFn,
      appState: appState,
      rampData: rampData,
      colorsUpdatedFn: colorsUpdatedFn,
      deleteRowFn: deleteRowFn,
      colorNames: colorNames,
    );
  }

  void _createWidgetList({
    required ColorRampFn createKPal
})
  {
    widgetList.clear();
    if (rampData != null)
    {
      for (ValueNotifier<IdColor> color in rampData!.colors)
      {
        widgetList.add(ColorEntryWidget(
            color: color.value,
            options: colorEntryWidgetOptions,
            colorSelectedFn: colorSelectedFn,
            appState: appState!));

      }
      widgetList.add(IconButton(
        icon: FaIcon(
          FontAwesomeIcons.sliders,
          size: colorEntryWidgetOptions.settingsIconSize,
        ),
        onPressed: () {
          createKPal(rampData!);
        },
      ));
    } else {
      widgetList.add(
          Expanded(
              child: Padding(
                  padding: EdgeInsets.all(colorEntryWidgetOptions.buttonPadding),
                  child: IconButton(
                      icon: FaIcon(
                        FontAwesomeIcons.plus,
                        size: colorEntryWidgetOptions.addIconSize,
                      ),
                      onPressed: () {

                        addNewRampFn!.call();
                      }
                  )
              )
          )
      );
    }
  }
}

class _ColorRampRowWidgetState extends State<ColorRampRowWidget> 
{
  bool kPalVisible = false;
  late OverlayEntry kPal;

  void _createKPal(final KPalRampData ramp)
  {
    if (kPalVisible)
    {
      kPal.remove();
    }
    kPal = OverlayEntries.getKPal(
      onDismiss: _closeKPal,
      onAccept: _colorRampUpdate,
      onDelete: _colorRampDelete,
      colorNames: widget.colorNames!,
      options: widget.kPalWidgetOptions!,
      constraints: widget.kPalConstraints!,
      alertDialogOptions: widget.alertDialogOptions!,
      colorRamp: ramp,
    );
    if (!kPalVisible)
    {
      Overlay.of(context).insert(kPal);
      kPalVisible = true;
    }
  }

  void _colorRampUpdate(final KPalRampData ramp)
  {
    _closeKPal();
    widget.colorsUpdatedFn!(ramp);
  }

  void _colorRampDelete(final KPalRampData ramp)
  {
    _closeKPal();
    widget.deleteRowFn!(ramp);
  }

  void _closeKPal()
  {
    if (kPalVisible)
    {
      kPal.remove();
      kPalVisible = false;
    }
  }
   @override
  Widget build(BuildContext context) {
    widget._createWidgetList(createKPal: _createKPal);
    return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widget.widgetList);
  }
}