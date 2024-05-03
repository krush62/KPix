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
  final List<Widget> widgetList;

  @override
  State<ColorRampRowWidget> createState() => _ColorRampRowWidgetState();

  const ColorRampRowWidget._({required this.colorList, required this.colorSelectedFn, required this.addNewColorFn, required this.colorEntryWidgetOptions, required this.appState, required this.widgetList});

  factory ColorRampRowWidget(List<IdColor>? tempColorList, ColorSelectedFn tempColorSelectedFn, AddNewColorFn tempAddNewColorFn, ColorEntryWidgetOptions tempColorEntryWidgetOptions, AppState tempAppState)
  {
    List<Widget> tempWidgetList = [];
    if (tempColorList != null) {
      for (IdColor color in tempColorList) {
        tempWidgetList.add(ColorEntryWidget(
            color, tempAppState, tempColorSelectedFn, tempColorEntryWidgetOptions));
      }
      tempWidgetList.add(IconButton (
        icon: Icon(
          Icons.add,
          size: tempColorEntryWidgetOptions.addIconSize,
        ),
        onPressed: () {
          tempAddNewColorFn(tempColorList);
        },
      ));
    }
    else
    {
      tempWidgetList.add(Expanded(
          child: Padding(
              padding: EdgeInsets.all(tempColorEntryWidgetOptions.buttonPadding),
              child: IconButton (
                  icon: Icon(
                    Icons.add,
                    size: tempColorEntryWidgetOptions.addIconSize,
                  ),
                  onPressed: () {tempAddNewColorFn(tempColorList);}
              )
          )
      ));
    }
    return ColorRampRowWidget._(colorList: tempColorList, colorSelectedFn: tempColorSelectedFn, addNewColorFn: tempAddNewColorFn, colorEntryWidgetOptions: tempColorEntryWidgetOptions, appState: tempAppState, widgetList: tempWidgetList);
  }

  List<Widget> getChildren()
  {
    return widgetList;
  }

  void _buildWidgets()
  {


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