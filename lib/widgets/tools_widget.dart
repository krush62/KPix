import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/models/app_state.dart';


class ToolsWidgetOptions
{
  final double padding;
  final double buttonSize;
  final int colCount;
  final double iconSize;

  ToolsWidgetOptions({required this.padding, required this.buttonSize, required this.colCount, required this.iconSize});

}


class ToolsWidget extends StatefulWidget
{
  const ToolsWidget(
      {
        required this.changeToolFn,
        super.key
      }
      );

  @override
  State<ToolsWidget> createState() => _ToolsWidgetState();

  final ChangeToolFn changeToolFn;
}

class _ToolsWidgetState extends State<ToolsWidget>
{
  AppState appState = GetIt.I.get<AppState>();
  ToolsWidgetOptions toolsWidgetOptions = GetIt.I.get<PreferenceManager>().toolsWidgetOptions;

  void _selectionChanged(ToolType tool)
  {
    appState.setToolSelection(tool);
    widget.changeToolFn(tool); //not used
  }


  @override
  void initState()
  {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    List<IconButton> iconButtons = [];
    for (final ToolType tooltype in toolList.keys)
    {
      IconButton i = IconButton.outlined(
        isSelected: appState.toolIsSelected(tooltype),
        color: appState.toolIsSelected(tooltype) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
        tooltip: toolList[tooltype]?.title,
        icon:  FaIcon(
          toolList[tooltype]!.icon,
          size: toolsWidgetOptions.iconSize,
        ),
        onPressed: () {
          tooltype == ToolType.stamp ? null : _selectionChanged(tooltype);
        },
      );
      iconButtons.add(i);
    }



    return LayoutBuilder(
        builder: (context, BoxConstraints constraints)
    {

      final int rowCount = (iconButtons.length - 1) ~/ toolsWidgetOptions.colCount + 1;
      return Container(
        width: double.infinity,
        height: (rowCount * toolsWidgetOptions.buttonSize + rowCount * toolsWidgetOptions.padding) + toolsWidgetOptions.padding,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.all(toolsWidgetOptions.padding),
          child: GridView.count(
            crossAxisCount: toolsWidgetOptions.colCount,
            crossAxisSpacing: toolsWidgetOptions.padding,
            mainAxisSpacing: toolsWidgetOptions.padding,
            childAspectRatio: (constraints.maxWidth / toolsWidgetOptions.colCount) / (toolsWidgetOptions.buttonSize) ,
            children: [
              ...iconButtons
            ],
          ),
        ),
      );
    });
  }
}