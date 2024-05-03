import 'package:kpix/models.dart';

typedef ChangeToolFn = void Function(ToolType toolType);
typedef ColorSelectedFn = void Function(String uuid);
//typedef ColorChangedFn = void Function(String uuid);
typedef AddNewColorFn = void Function(List<IdColor>? ramp);