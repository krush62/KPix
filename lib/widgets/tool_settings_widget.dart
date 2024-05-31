import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/font_manager.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/tool_options/color_pick_options.dart';
import 'package:kpix/tool_options/curve_options.dart';
import 'package:kpix/tool_options/eraser_options.dart';
import 'package:kpix/tool_options/fill_options.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/shape_options.dart';
import 'package:kpix/tool_options/spray_can_options.dart';
import 'package:kpix/tool_options/text_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/tool_options/wand_options.dart';
import 'package:kpix/typedefs.dart';


class ToolSettingsWidgetOptions
{
  final int columnWidthRatio;
  final double padding;
  const ToolSettingsWidgetOptions({required this.columnWidthRatio, required this.padding});
}


class ToolSettingsWidget extends StatefulWidget
{
  const ToolSettingsWidget({super.key});

  @override
  State<StatefulWidget> createState() => _ToolSettingsWidgetState();
  
}

class _ToolSettingsWidgetState extends State<ToolSettingsWidget>
{
  final AppState appState = GetIt.I.get<AppState>();
  final ToolOptions toolOptions = GetIt.I.get<PreferenceManager>().toolOptions;
  final ToolSettingsWidgetOptions toolSettingsWidgetOptions = GetIt.I.get<PreferenceManager>().toolSettingsWidgetOptions;

  String _getToolTitle()
  {
    String toolName = toolList[appState.selectedTool.value]!.title;
    return "Settings for $toolName";
  }

  // PENCIL CALLBACKS
  void _pencilSizeChanged(final double newVal)
  {
    setState(() {
      toolOptions.pencilOptions.size = newVal.round();
    });
  }

  void _pencilShapeChanged(final PencilShape newShape)
  {
    setState(() {
      toolOptions.pencilOptions.shape = newShape;
    });
  }

  void _pencilPixelPerfectChanged(final bool newVal)
  {
    setState(() {
      toolOptions.pencilOptions.pixelPerfect = newVal;
    });
  }



  // SHAPE CALLBACKS
  void _shapeShapeChanged(final ShapeShape newShape)
  {
    setState(() {
      toolOptions.shapeOptions.shape = newShape;
    });
  }

  void _shapeKeepAspectRatioChanged(final bool newVal)
  {
    setState(() {
      toolOptions.shapeOptions.keepRatio = newVal;
    });
  }

  void _shapeStrokeOnlyChanged(final bool newVal)
  {
    setState(() {
      toolOptions.shapeOptions.strokeOnly = newVal;
    });
  }

  void _shapeStrokeSizeChanged(final double newVal)
  {
    setState(() {
      toolOptions.shapeOptions.strokeWidth = newVal.round();
    });
  }

  void _shapeCornerRadiusChanged(final double newVal)
  {
    setState(() {
      toolOptions.shapeOptions.cornerRadius = newVal.round();
    });
  }


  // FILL CALLBACKS
  void _fillAdjacentChanged(final bool newVal)
  {
    setState(() {
      toolOptions.fillOptions.fillAdjacent = newVal;
    });
  }


  // SELECT CALLBACKS
  void _selectModeChanged(final SelectionMode newMode)
  {
    setState(() {
      toolOptions.selectOptions.mode = newMode;
    });
  }

  void _selectKeepAspectRatio(final bool newVal)
  {
    setState(() {
      toolOptions.selectOptions.keepAspectRatio = newVal;
    });
  }

  void _selectShapeChanged(final SelectShape newShape)
  {
    setState(() {
      toolOptions.selectOptions.shape = newShape;
    });
  }


  // ERASE CALLBACKS
  void _eraserSizeChanged(final double newVal)
  {
    setState(() {
      toolOptions.eraserOptions.size = newVal.round();
    });
  }

  void _eraserShapeChanged(final EraserShape newShape)
  {
    setState(() {
      toolOptions.eraserOptions.shape = newShape;
    });
  }

  // TEXT CALLBACKS
  void _textFontChanged(final PixelFontType newFont)
  {
    setState(() {
      toolOptions.textOptions.font = newFont;
    });
  }

  void _textSizeChanged(final double newSize)
  {
    setState(() {
      toolOptions.textOptions.size = newSize.round();
    });
  }

  void _textTextChanged(final String newText)
  {
    setState(() {
      toolOptions.textOptions.text = newText;
    });
  }


  // SPRAY CAN CALLBACKS
  void _sprayCanBlobSizeChanged(final double newSize)
  {
    setState(() {
      toolOptions.sprayCanOptions.blobSize = newSize.round();
    });
  }

  void _sprayCanIntensityChanged(final double newVal)
  {
    setState(() {
      toolOptions.sprayCanOptions.intensity = newVal.round();
    });
  }

  void _sprayCanRadiusChanged(final double newVal)
  {
    setState(() {
      toolOptions.sprayCanOptions.radius = newVal.round();
    });
  }


  // LINE CALLBACKS
  void _lineWidthChanged(final double newVal)
  {
    setState(() {
      toolOptions.lineOptions.width = newVal.round();
    });
  }

  void _lineIntegerAspectRatioChanged(final bool newVal)
  {
    setState(() {
      toolOptions.lineOptions.integerAspectRatio = newVal;
    });
  }


  // WAND CALLBACK
  void _wandSelectFromWholeRampChanged(final bool newVal)
  {
    setState(() {
      toolOptions.wandOptions.selectFromWholeRamp = newVal;
    });
  }


  // CURVE CALLBACK
  void _curveWidthChanged(final double newVal)
  {
    setState(() {
      toolOptions.curveOptions.width = newVal.round();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget toolWidget;
    switch(appState.selectedTool.value )
    {
      case ToolType.shape:
        toolWidget = ShapeOptions.getWidget(
            context: context,
            toolSettingsWidgetOptions: toolSettingsWidgetOptions,
            shapeOptions: toolOptions.shapeOptions,
            shapeShapeChanged: _shapeShapeChanged,
            shapeKeepAspectRatioChanged: _shapeKeepAspectRatioChanged,
            shapeStrokeOnlyChanged: _shapeStrokeOnlyChanged,
            shapeStrokeSizeChanged: _shapeStrokeSizeChanged,
            shapeCornerRadiusChanged: _shapeCornerRadiusChanged);
        break;
      case ToolType.pencil:
        toolWidget = PencilOptions.getWidget(
            context: context,
            toolSettingsWidgetOptions: toolSettingsWidgetOptions,
            pencilOptions: toolOptions.pencilOptions,
            pencilPixelPerfectChanged: _pencilPixelPerfectChanged,
            pencilShapeChanged: _pencilShapeChanged,
            pencilSizeChanged: _pencilSizeChanged);
        break;
      case ToolType.fill:
        toolWidget = FillOptions.getWidget(
            context: context,
            toolSettingsWidgetOptions: toolSettingsWidgetOptions,
            fillOptions: toolOptions.fillOptions,
            fillAdjacentChanged: _fillAdjacentChanged);
        break;
      case ToolType.select:
        toolWidget = SelectOptions.getWidget(
            context: context,
            toolSettingsWidgetOptions: toolSettingsWidgetOptions,
            selectOptions: toolOptions.selectOptions,
            selectionModeChanged: _selectModeChanged,
            selectKeepAspectRatioChanged: _selectKeepAspectRatio,
            selectShapeChanged: _selectShapeChanged);
        break;
      case ToolType.pick:
        toolWidget = ColorPickOptions.getWidget(
            context: context,
            toolSettingsWidgetOptions: toolSettingsWidgetOptions,
            colorPickOptions: toolOptions.colorPickOptions);
        break;
      case ToolType.erase:
        toolWidget = EraserOptions.getWidget(
            context: context,
            toolSettingsWidgetOptions: toolSettingsWidgetOptions,
            eraserOptions: toolOptions.eraserOptions,
            eraserShapeChanged: _eraserShapeChanged,
            eraserSizeChanged: _eraserSizeChanged);
        break;
      case ToolType.font:
        toolWidget = TextOptions.getWidget(
            context: context,
            toolSettingsWidgetOptions: toolSettingsWidgetOptions,
            textOptions: toolOptions.textOptions,
            textFontChanged: _textFontChanged,
            textSizeChanged: _textSizeChanged,
            textTextChanged: _textTextChanged);
        break;
      case ToolType.spraycan:
        toolWidget = SprayCanOptions.getWidget(
            context: context,
            toolSettingsWidgetOptions: toolSettingsWidgetOptions,
            sprayCanOptions: toolOptions.sprayCanOptions,
            sprayCanBlobSizeChanged: _sprayCanBlobSizeChanged,
            sprayCanIntensityChanged: _sprayCanIntensityChanged,
            sprayCanRadiusChanged: _sprayCanRadiusChanged);
        break;
      case ToolType.line:
        toolWidget = LineOptions.getWidget(
            context: context,
            toolSettingsWidgetOptions: toolSettingsWidgetOptions,
            lineOptions: toolOptions.lineOptions,
            lineWidthChanged: _lineWidthChanged,
            lineIntegerAspectRatioChanged: _lineIntegerAspectRatioChanged);
        break;
      case ToolType.wand:
        toolWidget = WandOptions.getWidget(
            context: context,
            toolSettingsWidgetOptions: toolSettingsWidgetOptions,
            wandOptions: toolOptions.wandOptions,
            wandSelectFromWholeRampChanged: _wandSelectFromWholeRampChanged);
        break;
      case ToolType.curve:
        toolWidget = CurveOptions.getWidget(
            context: context,
            toolSettingsWidgetOptions: toolSettingsWidgetOptions,
            curveOptions: toolOptions.curveOptions,
            curveWidthChanged: _curveWidthChanged);
        break;

      default: toolWidget = const SizedBox(width: double.infinity, child: Text("Not Implemented"));
    }


    return Material(
      color: Theme.of(context).primaryColor,
      
      child: Padding(
        padding: EdgeInsets.all(toolSettingsWidgetOptions.padding),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: toolWidget,
            ),
          )
    );
  }
  
}