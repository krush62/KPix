import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models.dart';
import 'package:kpix/tool_options.dart';


class ToolSettingsWidgetOptions
{
  final int columnWidthRatio;
  final double padding;
  final int crossFadeDuration;
  const ToolSettingsWidgetOptions({required this.columnWidthRatio, required this.padding, required this.crossFadeDuration});
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
    String toolName = toolNameMap[widget.appState.selectedTool.value] ?? "<empty>";
    return "Settings for $toolName";
  }

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

  void _pencilPixelPerfectChanged(bool newVal)
  {
    setState(() {
      widget.toolOptions.pencilOptions.pixelPerfect = newVal;
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
              child: Stack(
                alignment: Alignment.topCenter,
                children: [

                  //PENCIL
                  AnimatedOpacity(
                    duration: Duration(milliseconds: widget.toolSettingsWidgetOptions.crossFadeDuration),
                    opacity: widget.appState.selectedTool.value == ToolType.pencil ? 1.0 : 0.0,
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
                                    "Pixel Perfect",
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
                  AnimatedOpacity(
                    child: Text("BRUSH STUFF YEAH"),
                    duration: Duration(milliseconds: widget.toolSettingsWidgetOptions.crossFadeDuration),
                    opacity: widget.appState.selectedTool.value == ToolType.brush ? 1.0 : 0.0,
                  )
              
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  
}