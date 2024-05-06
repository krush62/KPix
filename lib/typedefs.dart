import 'package:kpix/models.dart';
import 'package:kpix/widgets/color_ramp_row_widget.dart';

typedef ChangeToolFn = void Function(ToolType toolType);
typedef ColorSelectedFn = void Function(String uuid);
//typedef ColorChangedFn = void Function(String uuid);
typedef AddNewColorFn = void Function(List<IdColor>? ramp);
typedef ColorMovedFn = void Function(IdColor color, ColorEntryDropTargetWidget dropTarget);