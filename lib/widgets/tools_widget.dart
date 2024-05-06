import 'package:flutter/material.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/models.dart';


class ToolsWidgetOptions
{
  final double padding;
  final double buttonResizeFactor;
  final double spacingFactor;
  final double iconSize;

  ToolsWidgetOptions({required this.padding, required this.buttonResizeFactor, required this.spacingFactor, required this.iconSize});

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
    return LayoutBuilder(
        builder: (context, BoxConstraints constraints)
    {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
        ),
        child: Align(
          alignment: const AlignmentDirectional(0.0, 0.0),
          child: Padding(
            padding: EdgeInsetsDirectional.all(widget.options.padding),
            child: GridView.count(
              crossAxisCount: (constraints.maxWidth / widget.options.buttonResizeFactor).round(),
              crossAxisSpacing: widget.options.padding,
              mainAxisSpacing: widget.options.padding,
              childAspectRatio: 1,
              padding: const EdgeInsets.all(0.0),
              children: [
                IconButton.outlined(
                  isSelected: widget.appState.toolIsSelected(ToolType.pencil),
                  color: widget.appState.toolIsSelected(ToolType.pencil) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                  icon:  Icon(
                    Icons.edit,
                    size: widget.options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.pencil);
                  },
                ),
                IconButton.outlined(
                  isSelected: widget.appState.toolIsSelected(ToolType.brush),
                  color: widget.appState.toolIsSelected(ToolType.brush) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                  icon: Icon(
                    Icons.brush,
                    size: widget.options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.brush);
                  },
                ),
                IconButton.outlined(
                  isSelected: widget.appState.toolIsSelected(ToolType.shape),
                  color: widget.appState.toolIsSelected(ToolType.shape) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                  icon: Icon(
                    Icons.details,
                    size: widget.options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.shape);
                  },
                ),
                IconButton.outlined(
                  isSelected: widget.appState.toolIsSelected(ToolType.gradient),
                  color: widget.appState.toolIsSelected(ToolType.gradient) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                  icon: Icon(
                    Icons.gradient,
                    size: widget.options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.gradient);
                  },
                ),
                IconButton.outlined(
                  isSelected: widget.appState.toolIsSelected(ToolType.fill),
                  color: widget.appState.toolIsSelected(ToolType.fill) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                  icon: Icon(
                    Icons.format_color_fill,
                    size: widget.options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.fill);
                  },
                ),
                IconButton.outlined(
                  isSelected: widget.appState.toolIsSelected(ToolType.select),
                  color: widget.appState.toolIsSelected(ToolType.select) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                  icon: Icon(
                    Icons.select_all,
                    size: widget.options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.select);
                  },
                ),
                IconButton.outlined(
                  isSelected: widget.appState.toolIsSelected(ToolType.pick),
                  color: widget.appState.toolIsSelected(ToolType.pick) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                  icon: Icon(
                    Icons.colorize,
                    size: widget.options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged((ToolType.pick));
                  },
                ),
                IconButton.outlined(
                  isSelected: widget.appState.toolIsSelected(ToolType.erase),
                  color: widget.appState.toolIsSelected(ToolType.erase) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                  icon: Icon(
                    Icons.delete,
                    size: widget.options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.erase);
                  },
                ),
                IconButton.outlined(
                  isSelected: widget.appState.toolIsSelected(ToolType.font),
                  color: widget.appState.toolIsSelected(ToolType.font) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                  icon: Icon(
                    Icons.font_download,
                    size: widget.options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.font);
                  },
                ),
                IconButton.outlined(
                  isSelected: widget.appState.toolIsSelected(ToolType.colorSelect),
                  color: widget.appState.toolIsSelected(ToolType.colorSelect) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                  icon: Icon(
                    Icons.blur_on,
                    size: widget.options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.colorSelect);
                  },
                ),
                IconButton.outlined(
                  isSelected: widget.appState.toolIsSelected(ToolType.line),
                  color: widget.appState.toolIsSelected(ToolType.line) ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                  icon: Icon(
                    Icons.multiline_chart,
                    size: widget.options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.line);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}