class ToolOptions
{
  ToolOptions({required this.pencilOptions});

  final PencilOptions pencilOptions;
}


//PENCIL

enum PencilShape
{
  round,
  square
}

const List<PencilShape> pencilShapeList = [ PencilShape.round, PencilShape.square];

const Map<int, PencilShape> _pencilShapeIndexMap =
{
  0: PencilShape.round,
  1: PencilShape.square
};

const Map<PencilShape, String> pencilShapeStringMap =
{
  PencilShape.round: "round",
  PencilShape.square: "square"
};

class PencilOptions
{
  final int sizeMin;
  final int sizeMax;
  final int sizeDefault;
  final int shapeDefault;
  final bool pixelPerfectDefault;

  int size = 1;
  PencilShape shape = PencilShape.round;
  bool pixelPerfect = true;

  PencilOptions({
      required this.sizeMin,
      required this.sizeMax,
      required this.sizeDefault,
      required this.shapeDefault,
      required this.pixelPerfectDefault})
  {
    size = sizeDefault;
    shape = _pencilShapeIndexMap[shapeDefault] ?? PencilShape.round;
    pixelPerfect = pixelPerfectDefault;
  }
}

