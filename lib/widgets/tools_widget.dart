import 'package:flutter/material.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/models.dart';


class ToolsWidgetOptions
{
  final double padding;
  final double buttonResizeFactor;
  final double spacingFactor;
  final double iconSize;

  ToolsWidgetOptions(this.padding, this.buttonResizeFactor, this.spacingFactor, this.iconSize);

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
  late ChangeToolFn _changeToolFn;
  late ToolsWidgetOptions _options;
  late AppState _appState;


  void _selectionChanged(ToolType tool)
  {
    _appState.setToolSelection(tool);
    _changeToolFn(tool);
  }


  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _changeToolFn = widget.changeToolFn;
    _appState = widget.appState;
  }

  @override
  Widget build(BuildContext context) {
    print("BUILD TOOLS");
    return LayoutBuilder(
        builder: (context, BoxConstraints constraints)
    {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme
              .of(context)
              .secondaryHeaderColor,
        ),
        child: Align(
          alignment: const AlignmentDirectional(0.0, 0.0),
          child: Padding(
            padding: EdgeInsetsDirectional.all(_options.padding),
            child: GridView.count(
              crossAxisCount: (constraints.maxWidth / _options.buttonResizeFactor).round(),
              crossAxisSpacing: constraints.maxWidth / _options.spacingFactor,
              mainAxisSpacing: constraints.maxWidth / _options.spacingFactor,
              childAspectRatio: 1,
              padding: const EdgeInsets.all(0.0),
              children: [
                IconButton.outlined(
                  isSelected: _appState.toolIsSelected(ToolType.Pencil),
                  icon:  Icon(
                    Icons.edit,
                    size: _options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.Pencil);
                  },
                ),
                IconButton.outlined(
                  isSelected: _appState.toolIsSelected(ToolType.Brush),
                  icon: Icon(
                    Icons.brush,
                    size: _options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.Brush);
                  },
                ),
                IconButton.outlined(
                  isSelected: _appState.toolIsSelected(ToolType.Shape),
                  icon: Icon(
                    Icons.details,
                    size: _options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.Shape);
                  },
                ),
                IconButton.outlined(
                  isSelected: _appState.toolIsSelected(ToolType.Gradient),
                  icon: Icon(
                    Icons.gradient,
                    size: _options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.Gradient);
                  },
                ),
                IconButton.outlined(
                  isSelected: _appState.toolIsSelected(ToolType.Fill),
                  icon: Icon(
                    Icons.format_color_fill,
                    size: _options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.Fill);
                  },
                ),
                IconButton.outlined(
                  isSelected: _appState.toolIsSelected(ToolType.Select),
                  icon: Icon(
                    Icons.select_all,
                    size: _options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.Select);
                  },
                ),
                IconButton.outlined(
                  isSelected: _appState.toolIsSelected(ToolType.Pick),
                  icon: Icon(
                    Icons.colorize,
                    size: _options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged((ToolType.Pick));
                  },
                ),
                IconButton.outlined(
                  isSelected: _appState.toolIsSelected(ToolType.Erase),
                  icon: Icon(
                    Icons.delete,
                    size: _options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.Erase);
                  },
                ),
                IconButton.outlined(
                  isSelected: _appState.toolIsSelected(ToolType.Font),
                  icon: Icon(
                    Icons.font_download,
                    size: _options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.Font);
                  },
                ),
                IconButton.outlined(
                  isSelected: _appState.toolIsSelected(ToolType.ColorSelect),
                  icon: Icon(
                    Icons.blur_on,
                    size: _options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.ColorSelect);
                  },
                ),
                IconButton.outlined(
                  isSelected: _appState.toolIsSelected(ToolType.Line),
                  icon: Icon(
                    Icons.multiline_chart,
                    size: _options.iconSize,
                  ),
                  onPressed: () {
                    _selectionChanged(ToolType.Line);
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