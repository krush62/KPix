class ToolOptions
{
  ToolOptions({required this.pencilOptions, required this.shapeOptions});

  final PencilOptions pencilOptions;
  final ShapeOptions shapeOptions;
}


//TODO these could be put in seperate files

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


//SHAPE
enum ShapeShape
{
  square,
  ellipse,
  triangle,
  pentagon,
  hexagon,
  octagon,
  fiveStar,
  sixStar,
  eightStar,
}

const List<ShapeShape> shapeShapeList =
[
  ShapeShape.square,
  ShapeShape.ellipse,
  ShapeShape.triangle,
  ShapeShape.pentagon,
  ShapeShape.hexagon,
  ShapeShape.octagon,
  ShapeShape.fiveStar,
  ShapeShape.sixStar,
  ShapeShape.eightStar,
];

const Map<int, ShapeShape> _shapeShapeIndexMap =
{
  0: ShapeShape.square,
  1: ShapeShape.ellipse,
  2: ShapeShape.triangle,
  3: ShapeShape.pentagon,
  4: ShapeShape.hexagon,
  5: ShapeShape.octagon,
  6: ShapeShape.fiveStar,
  7: ShapeShape.sixStar,
  8: ShapeShape.eightStar,
};

const Map<ShapeShape, String> shapeShapeStringMap =
{
  ShapeShape.square : "rectangle",
  ShapeShape.ellipse : "ellipse",
  ShapeShape.triangle : "triangle",
  ShapeShape.pentagon : "pentagon",
  ShapeShape.hexagon : "hexagon",
  ShapeShape.octagon : "octagon",
  ShapeShape.fiveStar : "5-star",
  ShapeShape.sixStar : "6-star",
  ShapeShape.eightStar : "8-star",
};

class ShapeOptions
{
  final int shapeDefault;
  final bool keepRatioDefault;
  final bool strokeOnlyDefault;
  final int strokeWidthMin;
  final int strokeWidthMax;
  final int strokeWidthDefault;
  final int cornerRadiusMin;
  final int cornerRadiusMax;
  final int cornerRadiusDefault;


  ShapeShape shape = ShapeShape.square;
  bool keepRatio = false;
  bool strokeOnly = false;
  int strokeWidth = 1;
  int cornerRadius = 0;

  ShapeOptions({
    required this.shapeDefault,
    required this.keepRatioDefault,
    required this.strokeOnlyDefault,
    required this.strokeWidthMin,
    required this.strokeWidthMax,
    required this.strokeWidthDefault,
    required this.cornerRadiusMin,
    required this.cornerRadiusMax,
    required this.cornerRadiusDefault
  })
  {
    shape = _shapeShapeIndexMap[shapeDefault] ?? ShapeShape.square;
    keepRatio = keepRatioDefault;
    strokeOnly = strokeOnlyDefault;
    strokeWidth = strokeWidthDefault;
    cornerRadius = cornerRadiusDefault;
  }



}
