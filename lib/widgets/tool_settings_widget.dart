import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models.dart';
import 'package:kpix/tool_options.dart';


class ToolSettingsWidgetOptions
{
  final int columnWidthRatio;
  final double padding;
  const ToolSettingsWidgetOptions({required this.columnWidthRatio, required this.padding});
}


class ToolSettingsWidget extends StatefulWidget
{
  final AppState appState;
  final ToolOptions toolOptions;
  final ToolSettingsWidgetOptions toolSettingsWidgetOptions;

  const ToolSettingsWidget({super.key, required this.appState, required this.toolSettingsWidgetOptions, required this.toolOptions});

  @override
  State<StatefulWidget> createState() => _ToolSettingsWidgetState();
  
}

class _ToolSettingsWidgetState extends State<ToolSettingsWidget>
{
  String _getToolTitle()
  {
    String toolName = toolList[widget.appState.selectedTool.value]!.title;
    return "Settings for $toolName";
  }

  //PENCIL
  void _pencilSizeChanged(final double newVal)
  {
    setState(() {
      widget.toolOptions.pencilOptions.size = newVal.round();
    });
  }

  void _pencilShapeChanged(final PencilShape newShape)
  {
    setState(() {
      widget.toolOptions.pencilOptions.shape = newShape;
    });
  }

  void _pencilPixelPerfectChanged(final bool newVal)
  {
    setState(() {
      widget.toolOptions.pencilOptions.pixelPerfect = newVal;
    });
  }


  //SHAPE
  void _shapeShapeChanged(final ShapeShape newShape)
  {
    setState(() {
      widget.toolOptions.shapeOptions.shape = newShape;
    });
  }

  void _shapeKeepAspectRatioChanged(final bool newVal)
  {
    setState(() {
      widget.toolOptions.shapeOptions.keepRatio = newVal;
    });
  }

  void _shapeStrokOnlyChanged(final bool newVal)
  {
    setState(() {
      widget.toolOptions.shapeOptions.strokeOnly = newVal;
    });
  }

  void _shapeStrokeSizeChanged(final double newVal)
  {
    setState(() {
      widget.toolOptions.shapeOptions.strokeWidth = newVal.round();
    });
  }

  void _shapeCornerRadiusChanged(final double newVal)
  {
    setState(() {
      widget.toolOptions.shapeOptions.cornerRadius = newVal.round();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,
      
      child: Padding(
        padding: EdgeInsets.all(widget.toolSettingsWidgetOptions.padding),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: widget.toolSettingsWidgetOptions.padding),
              child: Text(
                  _getToolTitle(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,

                //TODO Do not use stack, instead, dynamically put the correct AnimatedOpacity here
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [

                    //PENCIL
                    Visibility(
                      visible: widget.appState.selectedTool.value == ToolType.pencil,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Size",
                                      style: Theme.of(context).textTheme.labelLarge,
                                    )
                                ),
                              ),
                              Expanded(
                                flex: widget.toolSettingsWidgetOptions.columnWidthRatio,
                                child: Slider(
                                  value: widget.toolOptions.pencilOptions.size.toDouble(),
                                  min: widget.toolOptions.pencilOptions.sizeMin.toDouble(),
                                  max: widget.toolOptions.pencilOptions.sizeMax.toDouble(),
                                  divisions: widget.toolOptions.pencilOptions.sizeMax - widget.toolOptions.pencilOptions.sizeMin,
                                  onChanged: _pencilSizeChanged,
                                  label: widget.toolOptions.pencilOptions.size.round().toString(),
                                ),
                              ),

                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Shape",
                                      style: Theme.of(context).textTheme.labelLarge,
                                    )
                                ),
                              ),
                              Expanded(
                                flex: widget.toolSettingsWidgetOptions.columnWidthRatio,
                                child: DropdownButton(
                                  value: widget.toolOptions.pencilOptions.shape,
                                  dropdownColor: Theme.of(context).primaryColorDark,
                                  focusColor: Theme.of(context).primaryColor,
                                  isExpanded: true,
                                  onChanged: (PencilShape? pShape) {_pencilShapeChanged(pShape!);},
                                  items: pencilShapeList.map<DropdownMenuItem<PencilShape>>((PencilShape value) {
                                    return DropdownMenuItem<PencilShape>(
                                      value: value,
                                      child: Text(pencilShapeStringMap[value]!),
                                    );
                                  }).toList(),

                                )
                              ),

                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Shape",
                                      style: Theme.of(context).textTheme.labelLarge,
                                    )
                                ),
                              ),
                              Expanded(
                                flex: widget.toolSettingsWidgetOptions.columnWidthRatio,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Switch(
                                    onChanged: _pencilPixelPerfectChanged,
                                    value: widget.toolOptions.pencilOptions.pixelPerfect
                                  ),
                                )
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    //Shape
                    Visibility(
                      visible: widget.appState.selectedTool.value == ToolType.shape,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Size",
                                      style: Theme.of(context).textTheme.labelLarge,
                                    )
                                ),
                              ),
                              Expanded(
                                flex: widget.toolSettingsWidgetOptions.columnWidthRatio,
                                child: DropdownButton(
                                  value: widget.toolOptions.shapeOptions.shape,
                                  dropdownColor: Theme.of(context).primaryColorDark,
                                  focusColor: Theme.of(context).primaryColor,
                                  isExpanded: true,
                                  onChanged: (ShapeShape? pShape) {_shapeShapeChanged(pShape!);},
                                  items: shapeShapeList.map<DropdownMenuItem<ShapeShape>>((ShapeShape value) {
                                    return DropdownMenuItem<ShapeShape>(
                                      value: value,
                                      child: Text(shapeShapeStringMap[value]!),
                                    );
                                  }).toList(),

                                ),
                              ),

                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Keep 1:1",
                                      style: Theme.of(context).textTheme.labelLarge,
                                    )
                                ),
                              ),
                              Expanded(
                                flex: widget.toolSettingsWidgetOptions.columnWidthRatio,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Switch(
                                    onChanged: _shapeKeepAspectRatioChanged,
                                    value: widget.toolOptions.shapeOptions.keepRatio,
                                  ),
                                )
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Stroke Only",
                                    style: Theme.of(context).textTheme.labelLarge,
                                  )
                                ),
                              ),
                              Expanded(
                                flex: widget.toolSettingsWidgetOptions.columnWidthRatio,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Switch(
                                    onChanged: _shapeStrokOnlyChanged,
                                    value: widget.toolOptions.shapeOptions.strokeOnly,
                                  ),
                                )
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Stroke Width",
                                    style: Theme.of(context).textTheme.labelLarge,
                                  )
                                ),
                              ),
                              Expanded(
                                flex: widget.toolSettingsWidgetOptions.columnWidthRatio,
                                child: Slider(
                                  value: widget.toolOptions.shapeOptions.strokeWidth.toDouble(),
                                  min: widget.toolOptions.shapeOptions.strokeWidthMin.toDouble(),
                                  max: widget.toolOptions.shapeOptions.strokeWidthMax.toDouble(),
                                  divisions: widget.toolOptions.shapeOptions.strokeWidthMax - widget.toolOptions.shapeOptions.strokeWidthMin,
                                  onChanged: widget.toolOptions.shapeOptions.strokeOnly ? _shapeStrokeSizeChanged : null,
                                  label: widget.toolOptions.shapeOptions.strokeWidth.round().toString(),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Corner Radius",
                                    style: Theme.of(context).textTheme.labelLarge,
                                  )
                                ),
                              ),
                              Expanded(
                                flex: widget.toolSettingsWidgetOptions.columnWidthRatio,
                                child: Slider(
                                  value: widget.toolOptions.shapeOptions.cornerRadius.toDouble(),
                                  min: widget.toolOptions.shapeOptions.cornerRadiusMin.toDouble(),
                                  max: widget.toolOptions.shapeOptions.cornerRadiusMax.toDouble(),
                                  divisions: widget.toolOptions.shapeOptions.cornerRadiusMax - widget.toolOptions.shapeOptions.cornerRadiusMin,
                                  onChanged: _shapeCornerRadiusChanged,
                                  label: widget.toolOptions.shapeOptions.cornerRadius.round().toString(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  
}