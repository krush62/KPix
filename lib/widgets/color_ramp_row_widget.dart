import 'package:flutter/material.dart';
import 'package:kpix/models.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/color_entry_widget.dart';

class ColorRampRowWidget extends StatefulWidget {

  final List<IdColor>? colorList;
  final ColorSelectedFn colorSelectedFn;
  final AddNewColorFn addNewColorFn;
  final ColorEntryWidgetOptions colorEntryWidgetOptions;
  final AppState appState;
  late List<Widget> widgetList = [];

  @override
  State<ColorRampRowWidget> createState() => _ColorRampRowWidgetState();

  ColorRampRowWidget({super.key, required this.colorList, required this.colorSelectedFn, required this.addNewColorFn, required this.colorEntryWidgetOptions, required this.appState})
  {
    _buildWidgets();
  }

  void _buildWidgets()
  {
    widgetList = [];
    if (colorList != null) {
      for (IdColor color in colorList!) {
        widgetList.add(ColorEntryWidget(
            color, appState, colorSelectedFn, colorEntryWidgetOptions));
      }
      widgetList.add(IconButton (
        icon: Icon(
          Icons.add,
          size: colorEntryWidgetOptions.addIconSize,
        ),
        onPressed: () {
          addNewColorFn(colorList);
        },
      ));
    }
    else
    {
      widgetList.add(Expanded(
        child: Padding(
          padding: EdgeInsets.all(colorEntryWidgetOptions.buttonPadding),
          child: IconButton (
            icon: Icon(
              Icons.add,
              size: colorEntryWidgetOptions.addIconSize,
            ),
            onPressed: () {addNewColorFn(colorList);}
          )
        )
      ));
    }

  }
}

class _ColorRampRowWidgetState extends State<ColorRampRowWidget>
{

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context)
  {
    widget._buildWidgets();
    return Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: widget.widgetList);
  }

}