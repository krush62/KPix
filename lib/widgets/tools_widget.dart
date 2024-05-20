import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/models.dart';


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
        required this.appState,
        required this.options,
        required this.changeToolFn,
        super.key
      }
      );

  @override
  State<ToolsWidget> createState() => _ToolsWidgetState();

  final AppState appState;
  final ToolsWidgetOptions options;
  final ChangeToolFn changeToolFn;
}

class _ToolsWidgetState extends State<ToolsWidget>
{
  void _selectionChanged(ToolType tool)
  {
    widget.appState.setToolSelection(tool);
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
        isSelected: widget.appState.toolIsSelected(tooltype),
        color: widget.appState.toolIsSelected(tooltype) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
        tooltip: toolList[tooltype]?.title,
        icon:  FaIcon(
          toolList[tooltype]!.icon,
          size: widget.options.iconSize,
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

      final int rowCount = (iconButtons.length - 1) ~/ widget.options.colCount + 1;
      return Container(
        width: double.infinity,
        height: (rowCount * widget.options.buttonSize + rowCount * widget.options.padding) + widget.options.padding,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.all(widget.options.padding),
          child: GridView.count(
            crossAxisCount: widget.options.colCount,
            crossAxisSpacing: widget.options.padding,
            mainAxisSpacing: widget.options.padding,
            childAspectRatio: (constraints.maxWidth / widget.options.colCount) / (widget.options.buttonSize) ,
            children: [
              ...iconButtons
            ],
          ),
        ),
      );
    });
  }
}