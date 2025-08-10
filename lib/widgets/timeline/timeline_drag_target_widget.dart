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

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/widgets/timeline/timeline_widget.dart';

class TimeLineDragTargetWidget extends StatefulWidget
{
  final double collapsedHeight;
  final double cellHeight;
  final double cellWidth;
  final int delayMs;
  final Frame frame;
  final int layerIndex;

  final Function(LayerState layer, int newPosition) changeLayerOrderFn;
  final Function(Frame targetFrame, LayerState sourceLayer) copyLayerToOtherFrameFn;
  final Function(Frame targetFrame, LayerState sourceLayer) linkLayerToOtherFrameFn;
  const TimeLineDragTargetWidget({
    super.key,
    required this.cellHeight,
    required this.cellWidth,
    required this.delayMs,
    required this.collapsedHeight,
    required this.frame,
    required this.layerIndex,
    required this.changeLayerOrderFn,
    required this.copyLayerToOtherFrameFn,
    required this.linkLayerToOtherFrameFn,
  });

  @override
  State<TimeLineDragTargetWidget> createState() => _TimeLineDragTargetWidgetState();
}

enum DragType {
  moveInsideFrame,
  copyOnly,
  copyAndLink,
}

class _TimeLineDragTargetWidgetState extends State<TimeLineDragTargetWidget>
{
  final ValueNotifier<bool> isDraggingOver = ValueNotifier<bool>(false);
  final ValueNotifier<DragType?> dragType = ValueNotifier<DragType?>(null);
  final GlobalKey _dropZoneKey = GlobalKey();
  final ValueNotifier<bool?> linkButtonChosen = ValueNotifier<bool?>(null);


  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<DragType?>(
      valueListenable: dragType,
      builder: (final BuildContext context, final DragType? dragTypeValue, final Widget? child) {
        return DragTarget<LayerFrameDragData>(
          key: _dropZoneKey,
          onWillAcceptWithDetails: (final DragTargetDetails<LayerFrameDragData> details) {
            isDraggingOver.value = true;
            if (widget.frame == details.data.frame)
            {
              dragType.value = DragType.moveInsideFrame;
            }
            else if (widget.frame.layerList.contains(layer: details.data.layer))
            {
              dragType.value = DragType.copyOnly;
            }
            else
            {
              dragType.value = DragType.copyAndLink;
            }
            return true;
          },

          onMove: (final DragTargetDetails<LayerFrameDragData> details)
          {
            final Offset? localOffset = _getLocalOffset(details.offset);
            if (dragTypeValue == DragType.copyAndLink && localOffset != null)
            {
              final RenderBox? box = _dropZoneKey.currentContext
                  ?.findRenderObject() as RenderBox?;
              final double width = box?.size.width ?? 1.0;
              final bool doLink = localOffset.dx > width / 2;
              linkButtonChosen.value = doLink;
            }
            else if (dragTypeValue == DragType.copyOnly)
            {
              linkButtonChosen.value = false;
            }
            else
            {
              linkButtonChosen.value = null;
            }
          },
          onLeave: (final LayerFrameDragData? data) {
            isDraggingOver.value = false;
            dragType.value = null;
            linkButtonChosen.value = null;
          },
          onAcceptWithDetails: (final DragTargetDetails<LayerFrameDragData> details)
          {
            final Offset? localOffset = _getLocalOffset(details.offset);

            if (dragTypeValue == DragType.copyOnly)
            {
              widget.copyLayerToOtherFrameFn(widget.frame, details.data.layer);
            }
            else if (dragTypeValue == DragType.copyAndLink && localOffset != null)
            {
              final RenderBox? box = _dropZoneKey.currentContext?.findRenderObject() as RenderBox?;
              final double width = box?.size.width ?? 0;
              if (localOffset.dx < width / 2)
              {
                widget.copyLayerToOtherFrameFn(widget.frame, details.data.layer);
              }
              else
              {
                widget.linkLayerToOtherFrameFn(widget.frame, details.data.layer);
              }
            } else
            {
              widget.changeLayerOrderFn(details.data.layer, widget.layerIndex);
            }

            isDraggingOver.value = false;
            dragType.value = null;
            linkButtonChosen.value = null;
          },
          builder: (final BuildContext context, final List<LayerFrameDragData?> candidateData, final List<dynamic> rejectedData) {
            return ValueListenableBuilder<bool>(
              valueListenable: isDraggingOver,
              builder: (final BuildContext context, final bool isDraggingOverValue, final Widget? child) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: widget.delayMs),
                  height: isDraggingOverValue ? widget.cellHeight : widget.collapsedHeight,
                  width: widget.cellWidth,
                  color: dragTypeValue == DragType.moveInsideFrame ? Theme.of(context).primaryColorLight : Colors.transparent,
                  child: _buildInnerContent(),
                );
              },
            );
          },
        );
      },
    );
  }

  Offset? _getLocalOffset(final Offset globalOffset) {
    final RenderBox? box =_dropZoneKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(globalOffset);
  }

  Widget _buildInnerContent() {
    if (!isDraggingOver.value) return const SizedBox();

    if (dragType.value == DragType.copyOnly)
    {
      return Icon(FontAwesomeIcons.copy, color: Theme.of(context).primaryColorLight, size: widget.cellHeight / 2);
    }

    if (dragType.value == DragType.copyAndLink)
    {
      return ValueListenableBuilder<bool?>(
        valueListenable: linkButtonChosen,
        builder: (final BuildContext context, final bool? linkButtonChosenValue, final Widget? child) {
          return Row(
            children: <Widget>[
              Expanded(
                child: Icon(FontAwesomeIcons.copy, color: linkButtonChosen.value == false ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor, size: widget.cellHeight / 2),
              ),
              Expanded(
                child: Icon(FontAwesomeIcons.link, color: linkButtonChosen.value == true ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor, size: widget.cellHeight / 2),
              ),
            ],
          );
        },
      );
    }

    return const SizedBox();
  }
}
