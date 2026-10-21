/*
 * KPix
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/export_shader.dart';
import 'package:kpix/util/export_shader_renderer.dart';
import 'package:logger/logger.dart';

abstract final class ShaderPreviewWidgetOptions
{
  /// Output pixels per physical pixel; below 1 the preview is only an approximation.
  static const List<double> zoomLevels = <double>[0.25, 1.0 / 3.0, 0.5, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0];
  static const int renderIntervalMs = 100;
  static const int maxRegionSize = 4096;
  /// Outputs up to this many pixels are rendered as a whole, so moving and zooming never waits for a render.
  static const int fullRenderPixels = 2048 * 2048;
  static const double padding = 8.0;
  static const double borderRadius = 8.0;
  static const double checkerboardCellSize = 8.0;
  static const Color checkerboardLight = Color(0xFF9A9A9A);
  static const Color checkerboardDark = Color(0xFF6A6A6A);
}

/// Shows the visible part of the shaded output at its real resolution; drag to move, scroll or pinch to zoom.
class ShaderPreviewWidget extends StatefulWidget
{
  /// The image at 1:1, null while it is still being rendered.
  final ui.Image? source;
  final ExportShaderValues values;
  final int scaling;

  const ShaderPreviewWidget({super.key, required this.source, required this.values, required this.scaling});

  @override
  State<ShaderPreviewWidget> createState() => _ShaderPreviewWidgetState();
}

class _RenderedRegion
{
  final ui.Image image;
  final ExportShaderRegion region;
  final int scaling;
  const _RenderedRegion({required this.image, required this.region, required this.scaling});
}

class _ShaderPreviewWidgetState extends State<ShaderPreviewWidget>
{
  static final int _oneToOneIndex = ShaderPreviewWidgetOptions.zoomLevels.indexOf(1.0);

  final ValueNotifier<_RenderedRegion?> _rendered = ValueNotifier<_RenderedRegion?>(null);
  final ValueNotifier<int> _zoomIndex = ValueNotifier<int>(_oneToOneIndex);
  /// The output pixel shown in the middle of the preview.
  final ValueNotifier<Offset> _center = ValueNotifier<Offset>(Offset.zero);
  late final ui.Image _checkerboard;
  late final Timer _renderTimer;
  final List<ui.Image> _imagesToRetire = <ui.Image>[];
  Size _viewportSize = Size.zero;
  double _pixelRatio = 1.0;
  bool _isFitted = false;
  /// The output itself changed: values, scaling or source.
  bool _hasContentChanges = true;
  /// Only the view changed: moved, zoomed or resized.
  bool _hasViewChanges = false;
  bool _isRendering = false;
  bool _isDisposed = false;
  int _pinchStartZoomIndex = 0;

  double get _zoom => ShaderPreviewWidgetOptions.zoomLevels[_zoomIndex.value];
  int get _outputWidth => (widget.source?.width ?? 0) * widget.scaling;
  int get _outputHeight => (widget.source?.height ?? 0) * widget.scaling;

  @override
  void initState()
  {
    super.initState();
    _checkerboard = _createCheckerboard();
    widget.values.addListener(_contentChanged);
    _zoomIndex.addListener(_viewChanged);
    _center.addListener(_viewChanged);
    _renderTimer = Timer.periodic(const Duration(milliseconds: ShaderPreviewWidgetOptions.renderIntervalMs), (final Timer t) {_renderCheck();});
  }

  ui.Image _createCheckerboard()
  {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint light = Paint()..color = ShaderPreviewWidgetOptions.checkerboardLight;
    final Paint dark = Paint()..color = ShaderPreviewWidgetOptions.checkerboardDark;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), light);
    canvas.drawRect(const Rect.fromLTWH(1, 0, 1, 1), dark);
    canvas.drawRect(const Rect.fromLTWH(0, 1, 1, 1), dark);
    canvas.drawRect(const Rect.fromLTWH(1, 1, 1, 1), light);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = picture.toImageSync(2, 2);
    picture.dispose();
    return image;
  }

  @override
  void didUpdateWidget(covariant final ShaderPreviewWidget oldWidget)
  {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values)
    {
      oldWidget.values.removeListener(_contentChanged);
      widget.values.addListener(_contentChanged);
    }
    if (oldWidget.scaling != widget.scaling && oldWidget.source != null)
    {
      //keeps the same part of the image in the middle
      _center.value = _center.value * (widget.scaling / oldWidget.scaling);
    }
    if (oldWidget.source == null && widget.source != null)
    {
      _isFitted = false;
    }
    if (oldWidget.values != widget.values || oldWidget.scaling != widget.scaling || oldWidget.source != widget.source)
    {
      _hasContentChanges = true;
    }
  }

  void _contentChanged()
  {
    _hasContentChanges = true;
  }

  void _viewChanged()
  {
    _hasViewChanges = true;
  }

  /// Like the palette adjustment preview: an image may only be released once the frame that dropped it was drawn.
  void _retireImage({required final ui.Image image})
  {
    _imagesToRetire.add(image);
    if (_imagesToRetire.length > 1)
    {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      final List<ui.Image> images = List<ui.Image>.of(_imagesToRetire);
      _imagesToRetire.clear();
      for (final ui.Image image in images)
      {
        image.dispose();
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void deactivate()
  {
    super.deactivate();
    _renderTimer.cancel();
  }

  @override
  void dispose()
  {
    _isDisposed = true;
    _renderTimer.cancel();
    widget.values.removeListener(_contentChanged);
    final _RenderedRegion? last = _rendered.value;
    _rendered.dispose();
    _zoomIndex.dispose();
    _center.dispose();
    if (last != null)
    {
      _retireImage(image: last.image);
    }
    _retireImage(image: _checkerboard);
    super.dispose();
  }

  /// Where output pixel (0, 0) lands, in physical pixels of the preview.
  ///
  /// Snapped to the pixel grid of the screen, not of the preview: the dialog can sit at a fraction of a pixel,
  /// and at 1:1 that puts every sample on a texel edge, which drops and doubles rows and columns.
  Offset _originPhysical()
  {
    Offset screenOffset = Offset.zero;
    final RenderObject? box = context.findRenderObject();
    if (box is RenderBox && box.hasSize && box.attached)
    {
      screenOffset = box.localToGlobal(Offset.zero) * _pixelRatio;
    }
    return Offset(
      (screenOffset.dx + _viewportSize.width * _pixelRatio / 2 - _center.value.dx * _zoom).roundToDouble() - screenOffset.dx,
      (screenOffset.dy + _viewportSize.height * _pixelRatio / 2 - _center.value.dy * _zoom).roundToDouble() - screenOffset.dy,
    );
  }

  ExportShaderRegion? _visibleRegion()
  {
    final Offset origin = _originPhysical();
    final double zoom = _zoom;
    final (int, int)? xRange = _visibleRange(origin: origin.dx, viewport: _viewportSize.width * _pixelRatio, zoom: zoom, size: _outputWidth);
    final (int, int)? yRange = _visibleRange(origin: origin.dy, viewport: _viewportSize.height * _pixelRatio, zoom: zoom, size: _outputHeight);
    if (xRange == null || yRange == null)
    {
      return null;
    }
    return ExportShaderRegion(x: xRange.$1, y: yRange.$1, width: xRange.$2 - xRange.$1, height: yRange.$2 - yRange.$1);
  }

  (int, int)? _visibleRange({required final double origin, required final double viewport, required final double zoom, required final int size})
  {
    int start = max(0, (-origin / zoom).floor());
    int end = min(size, ((viewport - origin) / zoom).ceil());
    if (end <= start)
    {
      return null;
    }
    if (end - start > ShaderPreviewWidgetOptions.maxRegionSize)
    {
      final int middle = ((viewport / 2 - origin) / zoom).round();
      start = max(0, middle - ShaderPreviewWidgetOptions.maxRegionSize ~/ 2);
      end = min(size, start + ShaderPreviewWidgetOptions.maxRegionSize);
    }
    return (start, end);
  }

  /// The part of the output to render: all of it when that is affordable, else the visible part with half a view more on each side.
  ExportShaderRegion? _wantedRegion()
  {
    if (_outputWidth * _outputHeight <= ShaderPreviewWidgetOptions.fullRenderPixels)
    {
      return ExportShaderRegion(x: 0, y: 0, width: _outputWidth, height: _outputHeight);
    }
    final ExportShaderRegion? visible = _visibleRegion();
    if (visible == null)
    {
      return null;
    }
    final (int, int) xRange = _withMargin(start: visible.x, length: visible.width, size: _outputWidth);
    final (int, int) yRange = _withMargin(start: visible.y, length: visible.height, size: _outputHeight);
    return ExportShaderRegion(x: xRange.$1, y: yRange.$1, width: xRange.$2 - xRange.$1, height: yRange.$2 - yRange.$1);
  }

  (int, int) _withMargin({required final int start, required final int length, required final int size})
  {
    final int length2 = min(length * 2, ShaderPreviewWidgetOptions.maxRegionSize);
    final int first = (start + length ~/ 2 - length2 ~/ 2).clamp(0, max(0, size - length2));
    return (first, min(size, first + length2));
  }

  bool _covers({required final ExportShaderRegion outer, required final ExportShaderRegion inner})
  {
    return inner.x >= outer.x && inner.y >= outer.y && inner.x + inner.width <= outer.x + outer.width && inner.y + inner.height <= outer.y + outer.height;
  }

  void _renderCheck()
  {
    final ui.Image? source = widget.source;
    if (_isRendering || source == null || _viewportSize.isEmpty)
    {
      return;
    }
    if (!_hasContentChanges)
    {
      if (!_hasViewChanges)
      {
        return;
      }
      _hasViewChanges = false;
      final _RenderedRegion? current = _rendered.value;
      final ExportShaderRegion? visible = _visibleRegion();
      if (visible == null || (current != null && current.scaling == widget.scaling && _covers(outer: current.region, inner: visible)))
      {
        return;
      }
    }
    _hasContentChanges = false;
    _hasViewChanges = false;
    final ExportShaderRegion? region = _wantedRegion();
    if (region == null)
    {
      return;
    }
    final int scaling = widget.scaling;
    _isRendering = true;
    renderExportShaderRegion(values: widget.values, source: source, scaling: scaling, region: region).then((final ui.Image image) {
      _isRendering = false;
      if (_isDisposed)
      {
        image.dispose();
        return;
      }
      final _RenderedRegion? previous = _rendered.value;
      _rendered.value = _RenderedRegion(image: image, region: region, scaling: scaling);
      if (previous != null)
      {
        _retireImage(image: previous.image);
      }
    }, onError: (final Object e, final StackTrace s) {
      _isRendering = false;
      GetIt.I.get<Logger>().w("Rendering the shader preview failed.", error: e, stackTrace: s);
    },);
  }

  void _fit()
  {
    if (widget.source == null || _viewportSize.isEmpty)
    {
      return;
    }
    final double width = _viewportSize.width * _pixelRatio;
    final double height = _viewportSize.height * _pixelRatio;
    int index = 0;
    for (int i = 0; i < ShaderPreviewWidgetOptions.zoomLevels.length; i++)
    {
      final double zoom = ShaderPreviewWidgetOptions.zoomLevels[i];
      if (_outputWidth * zoom <= width && _outputHeight * zoom <= height)
      {
        index = i;
      }
    }
    _zoomIndex.value = index;
    _center.value = Offset(_outputWidth / 2, _outputHeight / 2);
  }

  void _setZoomIndex({required final int index})
  {
    _zoomIndex.value = index.clamp(0, ShaderPreviewWidgetOptions.zoomLevels.length - 1);
  }

  void _moveBy({required final Offset logicalDelta})
  {
    final Offset moved = _center.value - logicalDelta * (_pixelRatio / _zoom);
    _center.value = Offset(moved.dx.clamp(0, _outputWidth.toDouble()), moved.dy.clamp(0, _outputHeight.toDouble()));
  }

  void _pointerSignal(final PointerSignalEvent event)
  {
    if (event is PointerScrollEvent && event.scrollDelta.dy != 0)
    {
      _setZoomIndex(index: _zoomIndex.value + (event.scrollDelta.dy < 0 ? 1 : -1));
    }
  }

  void _scaleStart(final ScaleStartDetails details)
  {
    _pinchStartZoomIndex = _zoomIndex.value;
  }

  void _scaleUpdate(final ScaleUpdateDetails details)
  {
    _moveBy(logicalDelta: details.focalPointDelta);
    if (details.pointerCount > 1)
    {
      final double target = ShaderPreviewWidgetOptions.zoomLevels[_pinchStartZoomIndex] * details.scale;
      int nearest = 0;
      for (int i = 1; i < ShaderPreviewWidgetOptions.zoomLevels.length; i++)
      {
        if ((log(ShaderPreviewWidgetOptions.zoomLevels[i]) - log(target)).abs() < (log(ShaderPreviewWidgetOptions.zoomLevels[nearest]) - log(target)).abs())
        {
          nearest = i;
        }
      }
      _setZoomIndex(index: nearest);
    }
  }

  Widget _zoomControls({required final AppLocalizations l10n})
  {
    final ButtonStyle style = IconButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return ValueListenableBuilder<int>(
      valueListenable: _zoomIndex,
      builder: (final BuildContext context, final int zoomIndex, final Widget? child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: const BorderRadius.all(Radius.circular(ShaderPreviewWidgetOptions.borderRadius)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton.outlined(
                tooltip: l10n.zoomOut,
                style: style,
                onPressed: zoomIndex > 0 ? () {_setZoomIndex(index: zoomIndex - 1);} : null,
                icon: const Icon(TablerIcons.zoom_out),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ShaderPreviewWidgetOptions.padding / 2),
                child: Text("${(ShaderPreviewWidgetOptions.zoomLevels[zoomIndex] * 100).round()}%", style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton.outlined(
                tooltip: l10n.zoomIn,
                style: style,
                onPressed: zoomIndex < ShaderPreviewWidgetOptions.zoomLevels.length - 1 ? () {_setZoomIndex(index: zoomIndex + 1);} : null,
                icon: const Icon(TablerIcons.zoom_in),
              ),
              const SizedBox(width: ShaderPreviewWidgetOptions.padding / 2),
              IconButton.outlined(
                tooltip: l10n.zoomToFit,
                style: style,
                onPressed: _fit,
                icon: const Icon(TablerIcons.arrows_maximize),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
    if (pixelRatio != _pixelRatio)
    {
      _pixelRatio = pixelRatio;
      _hasViewChanges = true;
    }
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(ShaderPreviewWidgetOptions.borderRadius)),
      child: ColoredBox(
        color: Theme.of(context).primaryColorDark,
        child: LayoutBuilder(
          builder: (final BuildContext context, final BoxConstraints constraints) {
            final Size size = constraints.biggest;
            if (size != _viewportSize)
            {
              _viewportSize = size;
              _hasViewChanges = true;
            }
            if (!_isFitted && widget.source != null && !size.isEmpty)
            {
              _isFitted = true;
              WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
                if (!_isDisposed)
                {
                  _fit();
                }
              });
            }
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Listener(
                    onPointerSignal: _pointerSignal,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: _scaleStart,
                      onScaleUpdate: _scaleUpdate,
                      child: CustomPaint(
                        painter: _ShaderPreviewPainter(
                          rendered: _rendered,
                          zoomIndex: _zoomIndex,
                          center: _center,
                          checkerboard: _checkerboard,
                          originPhysical: _originPhysical,
                          pixelRatio: _pixelRatio,
                          scaling: widget.scaling,
                          outputSize: Size(_outputWidth.toDouble(), _outputHeight.toDouble()),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.source == null)
                  const Center(child: CircularProgressIndicator()),
                Positioned(
                  right: ShaderPreviewWidgetOptions.padding,
                  bottom: ShaderPreviewWidgetOptions.padding,
                  child: _zoomControls(l10n: l10n),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShaderPreviewPainter extends CustomPainter
{
  final ValueNotifier<_RenderedRegion?> rendered;
  final ValueNotifier<int> zoomIndex;
  final ValueNotifier<Offset> center;
  final ui.Image checkerboard;
  final Offset Function() originPhysical;
  final double pixelRatio;
  final int scaling;
  final Size outputSize;

  _ShaderPreviewPainter({
    required this.rendered,
    required this.zoomIndex,
    required this.center,
    required this.checkerboard,
    required this.originPhysical,
    required this.pixelRatio,
    required this.scaling,
    required this.outputSize,
  }) : super(repaint: Listenable.merge(<Listenable>[rendered, zoomIndex, center]));

  @override
  void paint(final Canvas canvas, final Size size)
  {
    if (outputSize.isEmpty)
    {
      return;
    }
    final double zoom = ShaderPreviewWidgetOptions.zoomLevels[zoomIndex.value];
    //logical pixels per output pixel
    final double scale = zoom / pixelRatio;
    final Offset origin = originPhysical() / pixelRatio;
    final Rect outputRect = origin & (outputSize * scale);

    const double cell = ShaderPreviewWidgetOptions.checkerboardCellSize;
    canvas.drawRect(outputRect, Paint()
      ..shader = ImageShader(checkerboard, TileMode.repeated, TileMode.repeated, (Matrix4.diagonal3Values(cell, cell, 1)..setTranslationRaw(origin.dx, origin.dy, 0)).storage, filterQuality: FilterQuality.none,),
    );

    final _RenderedRegion? current = rendered.value;
    if (current != null)
    {
      //an older render made at another scaling is stretched until the next one arrives
      final double regionScale = scale * scaling / current.scaling;
      final ExportShaderRegion region = current.region;
      final Rect target = Rect.fromLTWH(origin.dx + region.x * regionScale, origin.dy + region.y * regionScale, region.width * regionScale, region.height * regionScale);
      canvas.save();
      canvas.clipRect(outputRect);
      canvas.drawImageRect(
        current.image,
        Rect.fromLTWH(0, 0, current.image.width.toDouble(), current.image.height.toDouble()),
        target,
        Paint()..filterQuality = zoom >= 1.0 ? FilterQuality.none : FilterQuality.medium,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant final _ShaderPreviewPainter oldDelegate)
  {
    return oldDelegate.pixelRatio != pixelRatio || oldDelegate.scaling != scaling || oldDelegate.outputSize != outputSize || oldDelegate.rendered != rendered;
  }
}
