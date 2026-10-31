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

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/layer_image.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/models/constraints/canvas_size_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/callback_typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/controls/kpix_text_field.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';


/// Widget for changing the size of the canvas.
class CanvasSizeWidget extends StatefulWidget
{
  final Function() dismiss;
  final CanvasSizeFn accept;
  const CanvasSizeWidget({required this.dismiss, required this.accept, super.key});

  @override
  State<StatefulWidget> createState() => CanvasSizeWidgetState();
}

class CanvasSizeWidgetState extends State<CanvasSizeWidget>
{
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final DocumentState _documentState = GetIt.I.get<DocumentState>();
  final CanvasState _canvasState = GetIt.I.get<CanvasState>();
  final ValueNotifier<int> _width = ValueNotifier<int>(0);
  final ValueNotifier<int> _height = ValueNotifier<int>(0);
  final ValueNotifier<int> _offsetX = ValueNotifier<int>(0);
  final ValueNotifier<int> _offsetY = ValueNotifier<int>(0);
  final ValueNotifier<int> _minOffsetX = ValueNotifier<int>(0);
  final ValueNotifier<int> _maxOffsetX = ValueNotifier<int>(0);
  final ValueNotifier<int> _minOffsetY = ValueNotifier<int>(0);
  final ValueNotifier<int> _maxOffsetY = ValueNotifier<int>(0);
  final ValueNotifier<int> _minSize = ValueNotifier<int>(CanvasSizeConstraints.sizeMin);
  final ValueNotifier<int> _maxSize = ValueNotifier<int>(CanvasSizeConstraints.sizeMax);
  double _scalingFactor = 1.0;
  final ValueNotifier<ui.Image?> _image = ValueNotifier<ui.Image?>(null);
  final TextEditingController _textControllerWidth = TextEditingController();
  final TextEditingController _textControllerHeight = TextEditingController();
  final TextEditingController _textControllerOffsetX = TextEditingController();
  final TextEditingController _textControllerOffsetY = TextEditingController();

  @override
  void initState()
  {
    super.initState();
    _width.value = _canvasState.canvasSize.x;
    _height.value = _canvasState.canvasSize.y;
    _setSize();
    final Frame frame = _documentState.timeline.selectedFrame!;
    getImageFromLayers(canvasSize: _canvasState.canvasSize, layerCollection: frame.layerList, selection: _documentState.selectionState.selection, frame: frame).then((final ui.Image img){_image.value = img;});
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeWidthTextFocus).addListener(_widthFocusChanged);
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeHeightTextFocus).addListener(_heightFocusChanged);
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeOffsetXTextFocus).addListener(_offsetXFocusChanged);
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeOffsetYTextFocus).addListener(_offsetYFocusChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeWidthTextFocus).removeListener(_widthFocusChanged);
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeHeightTextFocus).removeListener(_heightFocusChanged);
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeOffsetXTextFocus).removeListener(_offsetXFocusChanged);
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeOffsetYTextFocus).removeListener(_offsetYFocusChanged);
    _textControllerWidth.dispose();
    _textControllerHeight.dispose();
    _textControllerOffsetX.dispose();
    _textControllerOffsetY.dispose();
  }

  void _widthFocusChanged()
  {
    if (!_hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeWidthTextFocus).hasFocus)
    {
      _textControllerWidth.text = _width.value.toString();
    }
  }

  void _heightFocusChanged()
  {
    if (!_hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeHeightTextFocus).hasFocus)
    {
      _textControllerHeight.text = _height.value.toString();
    }
  }

  void _offsetXFocusChanged()
  {
    if (!_hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeOffsetXTextFocus).hasFocus)
    {
      _textControllerOffsetX.text = _offsetX.value.toString();
    }
  }

  void _offsetYFocusChanged()
  {
    if (!_hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeOffsetYTextFocus).hasFocus)
    {
      _textControllerOffsetY.text = _offsetY.value.toString();
    }
  }


  void _sizeXSliderChanged({required final double newVal})
  {
    _width.value = newVal.round();
    _setSize();
  }

  void _sizeXInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null && parsedVal >= CanvasSizeConstraints.sizeMin && parsedVal <= CanvasSizeConstraints.sizeMax)
    {
      final int val = parsedVal.clamp(CanvasSizeConstraints.sizeMin, CanvasSizeConstraints.sizeMax);
      _width.value = val;

    }
    _setSize();
  }

  void _sizeYSliderChanged({required final double newVal})
  {
    _height.value = newVal.round();
    _setSize();
  }

  void _sizeYInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null && parsedVal >= CanvasSizeConstraints.sizeMin && parsedVal <= CanvasSizeConstraints.sizeMax)
    {
      final int val = parsedVal.clamp(CanvasSizeConstraints.sizeMin, CanvasSizeConstraints.sizeMax);
      _height.value = val;
    }
    _setSize();
  }

  void _setSize()
  {
    _calculateOffset();
    final int xExp = max(_width.value, _canvasState.canvasSize.x);
    final int yExp = max(_height.value, _canvasState.canvasSize.y);
    _scalingFactor = CanvasSizeConstraints.previewSize / max(xExp, yExp);
  }

  void _calculateOffset()
  {
    final CoordinateSetI oMin = CoordinateSetI.zero();
    final CoordinateSetI oMax = CoordinateSetI.zero();

    if (_width.value < _canvasState.canvasSize.x)
    {
      oMin.x = _width.value - _canvasState.canvasSize.x;
      oMax.x = 0;
    }
    else
    {
      oMin.x = 0;
      oMax.x = _width.value - _canvasState.canvasSize.x;
    }

    if (_height.value < _canvasState.canvasSize.y)
    {
      oMin.y = _height.value - _canvasState.canvasSize.y;
      oMax.y = 0;
    }
    else
    {
      oMin.y = 0;
      oMax.y = _height.value - _canvasState.canvasSize.y;
    }
    _minOffsetX.value = oMin.x;
    _minOffsetY.value = oMin.y;
    _maxOffsetX.value = oMax.x;
    _maxOffsetY.value = oMax.y;

    _offsetX.value = _offsetX.value.clamp(_minOffsetX.value, _maxOffsetX.value);
    _offsetY.value = _offsetY.value.clamp(_minOffsetY.value, _maxOffsetY.value);

  }

  void _offsetXSliderChanged({required final double newVal})
  {
    _offsetX.value = newVal.round();
  }

  void _offsetXInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null && parsedVal >= _minOffsetX.value && parsedVal <= _maxOffsetX.value)
    {
      _offsetX.value = parsedVal.clamp(_minOffsetX.value, _maxOffsetX.value);
    }
  }

  void _offsetYSliderChanged({required final double newVal})
  {
    _offsetY.value = newVal.round();
  }

  void _offsetYInputChanged({required final String newVal})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null && parsedVal >= _minOffsetY.value && parsedVal <= _maxOffsetY.value)
    {
      _offsetY.value = parsedVal.clamp(_minOffsetY.value, _maxOffsetY.value);
    }
  }

  void _centerH()
  {
    _offsetX.value = (_minOffsetX.value + _maxOffsetX.value) ~/ 2;
  }

  void _centerV()
  {
    _offsetY.value = (_minOffsetY.value + _maxOffsetY.value) ~/ 2;
  }

  Row _getValueRow({
    required final String title,
    required final ValueNotifier<int> notifier,
    required final ValueNotifier<int> minNotifier,
    required final ValueNotifier<int> maxNotifier,
    required final Function({required double newVal}) sliderFunc,
    required final Function({required String newVal}) changeFunc,
    required final FocusNode focusNode,
    required final TextEditingController textController,
  })
  {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(title),
        ),
        Expanded(
          flex: 7,
          child: ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[notifier, minNotifier, maxNotifier]),
            builder: (final BuildContext context, final Widget? child) {
              return KPixSlider(
                onChanged: (final double newVal) {sliderFunc(newVal: newVal);},
                value: notifier.value.toDouble(),
                min: minNotifier.value.toDouble(),
                max: maxNotifier.value.toDouble(),
                textStyle: Theme.of(context).textTheme.bodyLarge!,
              );
            },
          ),
        ),
        const SizedBox(width: OverlayEntryAlertDialogOptions.padding),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (final BuildContext context, final int value, final Widget? child) {
              showTextInController(controller: textController, text: value.toString());
              return TextField(
                focusNode: focusNode,
                textAlign: TextAlign.end,
                controller: textController,
                onChanged: (final String newVal) {changeFunc(newVal: newVal);},
              );
            },
          ),
        ),
      ],
    );
  }

  Positioned _getPreviewBorder({required final CoordinateSetD size, required final CoordinateSetI offset, required final CoordinateSetD canvasSize, final double width = 1.0, required final Color color})
  {
    return Positioned(
      left: (CanvasSizeConstraints.previewSize / 2) - (size.x / 2) + (offset.x * _scalingFactor),
      top: (CanvasSizeConstraints.previewSize / 2) - (size.y / 2) + (offset.y * _scalingFactor),
      width: canvasSize.x,
      height: canvasSize.y,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: width),
        ),
      ),
    );
  }

  Widget _getPreview()
  {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[_width, _height, _offsetX, _offsetY]),
      builder: (final BuildContext context, final Widget? child) {
        final CoordinateSetD scaledCanvasSize = CoordinateSetD(x: _canvasState.canvasSize.x * _scalingFactor, y: _canvasState.canvasSize.y * _scalingFactor);
        final CoordinateSetD scaledNewSize = CoordinateSetD(x: _width.value * _scalingFactor, y: _height.value * _scalingFactor);

        return Stack(
          children: <Widget>[
            SizedBox(
              width: CanvasSizeConstraints.previewSize.toDouble(),
              height: CanvasSizeConstraints.previewSize.toDouble(),
            ),
            Positioned(
              left: (CanvasSizeConstraints.previewSize / 2) - (scaledNewSize.x / 2) + (_offsetX.value * _scalingFactor),
              top: (CanvasSizeConstraints.previewSize / 2) - (scaledNewSize.y / 2) + (_offsetY.value * _scalingFactor),
              width: scaledCanvasSize.x,
              height: scaledCanvasSize.y,
              child: ValueListenableBuilder<ui.Image?>(
                valueListenable: _image,
                builder: (final BuildContext context, final ui.Image? img, final Widget? child) {
                  return RawImage(
                    fit: BoxFit.fill,
                    filterQuality: ui.FilterQuality.none,
                    image: img,
                  );
                },
              ),
            ),
            _getPreviewBorder(size: scaledNewSize, offset: CoordinateSetI(x: _offsetX.value, y: _offsetY.value), canvasSize: scaledCanvasSize, width: 4, color: Theme.of(context).primaryColorLight),
            _getPreviewBorder(size: scaledNewSize, offset: CoordinateSetI.zero(), canvasSize: scaledNewSize, width: 3, color: Theme.of(context).primaryColorDark),
            _getPreviewBorder(size: scaledNewSize, offset: CoordinateSetI.zero(), canvasSize: scaledNewSize, color: Theme.of(context).primaryColorLight),
          ],
        );
      },
    );
  }

  void accept()
  {
    widget.accept(size: CoordinateSetI(x: _width.value, y: _height.value), offset: CoordinateSetI(x: _offsetX.value, y: _offsetY.value));
  }

  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return KPixAnimationWidget(
      constraints: const BoxConstraints(
        minHeight: OverlayEntryAlertDialogOptions.minHeight,
        minWidth: OverlayEntryAlertDialogOptions.minWidth,
        maxHeight: OverlayEntryAlertDialogOptions.maxHeight * 1.5,
        maxWidth: OverlayEntryAlertDialogOptions.maxWidth * 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(l10n.canvasSize, style: Theme.of(context).textTheme.titleLarge),
                      _getValueRow(
                        title: l10n.width,
                        notifier: _width,
                        minNotifier: _minSize,
                        maxNotifier: _maxSize,
                        sliderFunc: _sizeXSliderChanged,
                        changeFunc: _sizeXInputChanged,
                        focusNode: _hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeWidthTextFocus),
                        textController: _textControllerWidth,
                      ),
                      _getValueRow(
                        title: l10n.height,
                        notifier: _height,
                        minNotifier: _minSize,
                        maxNotifier: _maxSize,
                        sliderFunc: _sizeYSliderChanged,
                        changeFunc: _sizeYInputChanged,
                        focusNode: _hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeHeightTextFocus),
                        textController: _textControllerHeight,
                      ),
                      const SizedBox(height: OverlayEntryAlertDialogOptions.padding,),
                      Text(l10n.offset, style: Theme.of(context).textTheme.titleLarge),
                      _getValueRow(
                        title: "X",
                        notifier: _offsetX,
                        minNotifier: _minOffsetX,
                        maxNotifier: _maxOffsetX,
                        sliderFunc: _offsetXSliderChanged,
                        changeFunc: _offsetXInputChanged,
                        focusNode: _hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeOffsetXTextFocus),
                        textController: _textControllerOffsetX,
                      ),
                      _getValueRow(
                        title: "Y",
                        notifier: _offsetY,
                        minNotifier: _minOffsetY,
                        maxNotifier: _maxOffsetY,
                        sliderFunc: _offsetYSliderChanged,
                        changeFunc: _offsetYInputChanged,
                        focusNode: _hotkeyManager.getFocusNode(id: FocusNodeEntry.canvasSizeOffsetYTextFocus),
                        textController: _textControllerOffsetY,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: OverlayEntryAlertDialogOptions.padding * 2,
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _getPreview(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          DialogActionButton(
                            tooltip: l10n.centerHorizontally,
                            icon: TablerIcons.layout_align_middle,
                            iconSize: OverlayEntryAlertDialogOptions.iconSize,
                            onPressed: _centerH,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                              child: IconButton.outlined(
                                tooltip: l10n.centerVertically,
                                icon: Transform.rotate(
                                  angle: pi / 2,
                                  child: const Icon(
                                    TablerIcons.layout_align_middle,
                                    size: OverlayEntryAlertDialogOptions.iconSize,
                                  ),
                                ),
                                onPressed: _centerV,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: OverlayEntryAlertDialogOptions.padding,),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              DialogActionButton(
                tooltip: l10n.cancel,
                icon: TablerIcons.x,
                iconSize: OverlayEntryAlertDialogOptions.iconSize,
                onPressed: () {
                  widget.dismiss();
                },
              ),
              DialogActionButton(
                tooltip: l10n.apply,
                icon: TablerIcons.check,
                iconSize: OverlayEntryAlertDialogOptions.iconSize,
                onPressed: accept,
              ),
            ],
          ),
        ],
      ),
    );
  }

}
