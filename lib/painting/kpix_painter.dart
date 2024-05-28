import 'package:flutter/material.dart';
import 'package:kpix/models.dart';
import 'package:kpix/widgets/layer_widget.dart';


class KPixPainterOptions
{
  final int checkerBoardSize;


  KPixPainterOptions({
    required this.checkerBoardSize
  });
}

class KPixPainter extends CustomPainter
{
  final AppState appState;
  final ValueNotifier<Offset> offset;
  final KPixPainterOptions options;
  final Color checkerboardColor1;
  final Color checkerboardColor2;

  KPixPainter({required this.appState, required this.offset, required this.checkerboardColor1, required this.checkerboardColor2, required this.options});

  @override
  void paint(Canvas canvas, Size size) {
    final int zoomLevelFactor = appState.getZoomLevel() ~/ 100;
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final int scaledCanvasWidth = appState.canvasWidth * zoomLevelFactor;
    final int scaledCanvasHeight = appState.canvasHeight * zoomLevelFactor;

    _drawCheckerboard(canvas: canvas, paint: paint, scaledCanvasWidth: scaledCanvasWidth, scaledCanvasHeight: scaledCanvasHeight);
    _drawLayers(canvas: canvas, paint: paint, pixelSize: zoomLevelFactor);
  }

  void _drawLayers({required final Canvas canvas, required final Paint paint, required final int pixelSize})
  {
    final double pxlSzDbl = pixelSize.toDouble();
    final List<LayerState> layers = appState.layers.value;
    for (int x = 0; x < appState.canvasWidth; x++)
    {
      for (int y = 0; y < appState.canvasHeight; y++)
      {
        for (int i = layers.length - 1; i >= 0; i--)
        {
          if (layers[i].visibilityState.value == LayerVisibilityState.visible) {
            ColorReference? layerColor = layers[i].data[x][y];
            if (layerColor != null) {
              paint.color =
                  layerColor.ramp.colors[layerColor.colorIndex].value.color;
              canvas.drawRect(Rect.fromLTWH(offset.value.dx + (x * pxlSzDbl),
                  offset.value.dy + (y * pxlSzDbl), pxlSzDbl, pxlSzDbl), paint);
              break;
            }
          }
        }
      }
    }


  }

  void _drawCheckerboard({required final Canvas canvas, required final Paint paint, required final int scaledCanvasWidth, required final int scaledCanvasHeight})
  {
    bool rowFlip = false;
    bool colFlip = false;
    final double cbSizeDbl = options.checkerBoardSize.toDouble();
    for (int i = 0; i < scaledCanvasWidth; i += options.checkerBoardSize)
    {
      colFlip = rowFlip;
      for (int j = 0; j < scaledCanvasHeight; j += options.checkerBoardSize)
      {
        paint.color = colFlip ? checkerboardColor1 : checkerboardColor2;
        double width = cbSizeDbl;
        double height = cbSizeDbl;
        if (i + cbSizeDbl > scaledCanvasWidth)
        {
          width = scaledCanvasWidth - i.toDouble();
        }

        if (j + cbSizeDbl > scaledCanvasHeight)
        {
          height = scaledCanvasHeight - j.toDouble();
        }

        canvas.drawRect(
          Rect.fromLTWH(offset.value.dx + i, offset.value.dy + j , width, height),
          paint,
        );

        colFlip = !colFlip;
      }
      rowFlip = !rowFlip;
    }

    /*paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4;
    paint.color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(offset.value.dx - 4, offset.value.dy - 4 , scaledCanvasWidth + 8, scaledCanvasHeight + 6),
      paint,
    );*/
  }



  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

