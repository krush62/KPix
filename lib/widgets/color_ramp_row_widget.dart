import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class ColorRampRowWidget extends StatefulWidget {
  final KPalRampData? rampData;
  final ColorReferenceSelectedFn? colorSelectedFn;
  final ColorRampUpdateFn? colorsUpdatedFn;
  final ColorRampFn? deleteRowFn;
  final AddNewRampFn? addNewRampFn;
  final List<Widget> widgetList;

  @override
  State<ColorRampRowWidget> createState() => _ColorRampRowWidgetState();

  const ColorRampRowWidget._({
    super.key,
    this.rampData,
    this.colorSelectedFn,
    this.addNewRampFn,
    this.deleteRowFn,
    this.colorsUpdatedFn,
    required this.widgetList,
  });

  factory ColorRampRowWidget({
    KPalRampData? rampData,
    ColorReferenceSelectedFn? colorSelectedFn,
    AddNewRampFn? addNewRampFn,
    ColorRampFn? deleteRowFn,
    ColorRampUpdateFn? colorsUpdatedFn,
    Key? key,
  }){
    List<Widget> widgetList = [];
    return ColorRampRowWidget._(
      addNewRampFn: addNewRampFn,
      widgetList: widgetList,
      colorSelectedFn: colorSelectedFn,
      rampData: rampData,
      colorsUpdatedFn: colorsUpdatedFn,
      deleteRowFn: deleteRowFn,
      key: key
    );
  }

  void colorSelected(final IdColor newColor)
  {
    if (colorSelectedFn != null && rampData != null)
    {
      int index = -1;
      for (int i = 0; i < rampData!.colors.length; i++)
      {
        if (rampData!.colors[i].value == newColor)
        {
          index = i;
          break;
        }
      }
      if (index != -1)
      {
        colorSelectedFn!(rampData!.references[index]);
      }
    }
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
            colorSelectedFn: colorSelected,
            ));

      }
      widgetList.add(IconButton(
        padding: EdgeInsets.all(GetIt.I.get<PreferenceManager>().colorEntryOptions.buttonPadding),
        constraints: const BoxConstraints(),
        icon: FaIcon(
          FontAwesomeIcons.sliders,
          size: GetIt.I.get<PreferenceManager>().colorEntryOptions.settingsIconSize,
        ),
        onPressed: () {
          createKPal(ramp: rampData!);
        },
      ));
    } else {
      widgetList.add(
        Expanded(
          child: IconButton(
            padding: EdgeInsets.all(GetIt.I.get<PreferenceManager>().colorEntryOptions.buttonPadding),
            icon: FaIcon(
              FontAwesomeIcons.plus,
              size: GetIt.I.get<PreferenceManager>().colorEntryOptions.addIconSize,
            ),
            onPressed: () {

              addNewRampFn!.call();
            }
          )
        )
      );
    }
  }
}

class _ColorRampRowWidgetState extends State<ColorRampRowWidget> 
{
  late KPixOverlay kPal;

  @override
  void initState()
  {
    super.initState();

  }

  void _createKPal({required final KPalRampData ramp, final bool addToHistoryStack = true})
  {
    kPal = OverlayEntries.getKPal(
      onDismiss: _closeKPal,
      onAccept: _colorRampUpdate,
      onDelete: _colorRampDelete,
      colorRamp: ramp,
    );
    kPal.show(context);
  }

  void _colorRampUpdate({required final KPalRampData ramp, required final KPalRampData originalData, final bool addToHistoryStack = true})
  {
    _closeKPal();
    widget.colorsUpdatedFn!(ramp: ramp, originalData: originalData, addToHistoryStack: addToHistoryStack);
  }

  void _colorRampDelete({required final KPalRampData ramp, final bool addToHistoryStack = true})
  {
    _closeKPal();
    widget.deleteRowFn!(ramp: ramp, addToHistoryStack: addToHistoryStack);
  }

  void _closeKPal()
  {
    kPal.hide();
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