import 'package:kpix/util/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/widgets/canvas_size_widget.dart';
import 'package:kpix/widgets/export_widget.dart';
import 'package:kpix/widgets/layer_widget.dart';

typedef ChangeToolFn = void Function(ToolType toolType);
typedef IdColorSelectedFn = void Function(IdColor uuid);
typedef ColorReferenceSelectedFn = void Function(ColorReference uuid);
typedef RampOptionsFn = void Function(KPalRampData? data);
typedef AddNewRampFn = void Function();
typedef ColorRampFn = void Function({required KPalRampData ramp, bool addToHistoryStack});
typedef ColorRampUpdateFn = void Function({required KPalRampData ramp, required KPalRampData originalData, bool addToHistoryStack});
typedef ChangeLayerPositionFn = void Function(LayerState state, int newPosition);
typedef AddNewLayerFn = void Function();
typedef LayerSelectedFn = void Function(LayerState state);
typedef LayerDeleteFn = void Function(LayerState state);
typedef LayerMergeDownFn = void Function(LayerState state);
typedef LayerDuplicateFn = void Function(LayerState state);
typedef ExportDataFn = void Function(ExportData exportData, ExportTypeEnum exportType);
typedef CanvasSizeFn = void Function(CoordinateSetI size, CoordinateSetI offset);

