import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/widgets/layer_widget.dart';

typedef ChangeToolFn = void Function(ToolType toolType);
typedef IdColorSelectedFn = void Function(IdColor uuid);
typedef ColorReferenceSelectedFn = void Function(ColorReference uuid);
typedef RampOptionsFn = void Function(KPalRampData? data);
typedef AddNewRampFn = void Function();
typedef ColorRampFn = void Function(KPalRampData ramp);
typedef ColorRampUpdateFn = void Function(KPalRampData ramp, KPalRampData originalData);
typedef ChangeLayerPositionFn = void Function(LayerState state, int newPosition);
typedef AddNewLayerFn = void Function();
typedef LayerSelectedFn = void Function(LayerState state);
typedef LayerDeleteFn = void Function(LayerState state);
typedef LayerMergeDownFn = void Function(LayerState state);
typedef LayerDuplicateFn = void Function(LayerState state);

