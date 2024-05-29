import 'package:flutter/material.dart';
import 'package:kpix/font_manager.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/tool_options/eraser_options.dart';
import 'package:kpix/tool_options/pencil_options.dart';
import 'package:kpix/tool_options/select_options.dart';
import 'package:kpix/tool_options/shape_options.dart';
import 'package:kpix/widgets/layer_widget.dart';

typedef ChangeToolFn = void Function(ToolType toolType);
typedef ColorSelectedFn = void Function(IdColor uuid);
typedef RampOptionsFn = void Function(KPalRampData? data);
typedef AddNewRampFn = void Function();
typedef ColorRampFn = void Function(KPalRampData ramp);
typedef ChangeLayerPositionFn = void Function(LayerState state, int newPosition);
typedef AddNewLayerFn = void Function();
typedef LayerSelectedFn = void Function(LayerState state);
typedef LayerDeleteFn = void Function(LayerState state);
typedef LayerMergeDownFn = void Function(LayerState state);
typedef LayerDuplicateFn = void Function(LayerState state);


typedef PencilSizeChanged =  void Function(double newVal);
typedef PencilShapeChanged = void Function(PencilShape newShape);
typedef PencilPixelPerfectChanged = void Function(bool newVal);
typedef ShapeShapeChanged =  void Function(ShapeShape newShape);
typedef ShapeKeepAspectRatioChanged = void Function(bool newVal);
typedef ShapeStrokeOnlyChanged = void Function(bool newVal);
typedef ShapeStrokeSizeChanged = void Function(double newVal);
typedef ShapeCornerRadiusChanged = void Function(double newVal);
typedef FillAdjacentChanged = void Function(bool newVal);
typedef SelectShapeChanged =  void Function(SelectShape newShape);
typedef SelectKeepAspectRatioChanged = void Function(bool newVal);
typedef SelectionModeChanged =  void Function(SelectionMode newMode);
typedef EraserSizeChanged =  void Function(double newVal);
typedef EraserShapeChanged = void Function(EraserShape newShape);
typedef TextTextChanged = void Function(String newText);
typedef TextSizeChanged = void Function(double newVal);
typedef TextFontChanged = void Function(PixelFontType newFont);
typedef SprayCanRadiusChanged = void Function(double newVal);
typedef SprayCanBlobSizeChanged = void Function(double newVal);
typedef SprayCanIntensityChanged = void Function(double newVal);
typedef LineWidthChanged = void Function(double newVal);
typedef LineIntegerAspectRatioChanged = void Function(bool newVal);
typedef WandSelectFromWholeRampChanged = void Function(bool newVal);
typedef CurveWidthChanged = void Function(double newVal);