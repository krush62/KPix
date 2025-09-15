/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/layer_color_supplier.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/timeline/frame_blending_widget.dart';
import 'package:kpix/widgets/timeline/frame_time_widget.dart';
import 'package:kpix/widgets/timeline/timeline_drag_target_widget.dart';

const Map<Type, IconData> layerIconMap = <Type, IconData>{
  ReferenceLayerState: TablerIcons.photo,
  GridLayerState: TablerIcons.grid_4x4,
  ShadingLayerState: TablerIcons.exposure,
  DitherLayerState: Icons.gradient,
  DrawingLayerState: TablerIcons.brush,
};

class LayerFrameDragData
{
  final LayerState layer;
  final Frame frame;
  const LayerFrameDragData({required this.layer, required this.frame});
}

class TimeLineWidget extends StatefulWidget {
  const TimeLineWidget({super.key, required this.timeline, this.height = 36, this.expandedHeight = 400, this.animationDuration = const Duration(milliseconds: 200), this.padding = 8.0, this.framePadding = 2.0});
  final Timeline timeline;
  final double height;
  final double expandedHeight;
  final Duration animationDuration;
  final double padding;
  final double framePadding;

  @override
  State<TimeLineWidget> createState() => _TimeLineWidgetState();
}

class _TimeLineWidgetState extends State<TimeLineWidget> with SingleTickerProviderStateMixin
{
  final FrameBlendingOptions frameBlendingOptions = GetIt.I.get<PreferenceManager>().frameBlendingOptions;
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final ValueNotifier<bool> isExpanded = ValueNotifier<bool>(false);
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState()
  {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (isExpanded.value) {
      _animationController.forward();
    }

    _hotkeyManager.addListener(func: () {widget.timeline.togglePlaying();}, action: HotkeyAction.timelinePlay);
    _hotkeyManager.addListener(func: () {widget.timeline.selectNextFrame();}, action: HotkeyAction.timelineNextFrame);
    _hotkeyManager.addListener(func: () {widget.timeline.selectPreviousFrame();}, action: HotkeyAction.timelinePreviousFrame);
    _hotkeyManager.addListener(func: () {if (!widget.timeline.isPlaying.value && widget.timeline.frames.value.length > 1 && widget.timeline.selectedFrameIndex > 0) widget.timeline.moveFrameLeft();}, action: HotkeyAction.timelineMoveFrameLeft);
    _hotkeyManager.addListener(func: () {if (!widget.timeline.isPlaying.value && widget.timeline.frames.value.length > 1 && widget.timeline.selectedFrameIndex < widget.timeline.frames.value.length - 1) widget.timeline.moveFrameRight();}, action: HotkeyAction.timelineMoveFrameRight);
    _hotkeyManager.addListener(func: () {_toggleFrameBlending();}, action: HotkeyAction.timelineToggleFrameBlending);
    _hotkeyManager.addListener(func: () {_expandView();}, action: HotkeyAction.timelineExpand);
    _hotkeyManager.addListener(func: () {_collapseView();}, action: HotkeyAction.timelineCollapse);


  }

  void _expandView()
  {
    if (!isExpanded.value)
    {
      isExpanded.value = true;
      _animationController.forward();
    }
  }

  void _collapseView()
  {
    if (isExpanded.value)
    {
      isExpanded.value = false;
      _animationController.reverse();
    }
  }

  void _toggleExpand()
  {
    isExpanded.value = !isExpanded.value;
    if (isExpanded.value)
    {
      _animationController.forward();
    }
    else
    {
      _animationController.reverse();
    }
  }

  void _toggleFrameBlending()
  {
    frameBlendingOptions.enabled.value = !frameBlendingOptions.enabled.value;
    GetIt.I.get<AppState>().repaintNotifier.repaint();
  }


  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizeTransition(
            sizeFactor: _animation,
            child: SizedBox(
                height: widget.expandedHeight,
                child: TimelineMaxiWidget(
                  timeline: widget.timeline,
                  ownHeight: widget.expandedHeight,
                  frameBlendingOptions: frameBlendingOptions,
                ),
            ),
        ),
        SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: TimeLineMiniWidget(timeline: widget.timeline, buttonWidth: widget.height - widget.padding * 2, padding: widget.padding, framePadding: widget.framePadding,)),
              ColoredBox(
                color: Theme.of(context).primaryColorDark,
                child: Padding(
                  padding: EdgeInsets.all(widget.padding),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isExpanded,
                    builder: (final BuildContext context, final bool isExpanded, final Widget? child) {
                      return Tooltip(
                        message: isExpanded ? "Collapse Timeline" : "Expand Timeline",
                        waitDuration: AppState.toolTipDuration,
                        child: SizedBox(
                          width: widget.height - widget.padding * 2,
                          child: IconButton(
                              onPressed: () {
                                _toggleExpand();
                              },
                              icon: Icon(isExpanded ? TablerIcons.chevron_up : TablerIcons.chevron_down, size: widget.height / 2,),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: Theme.of(context).primaryColor, height: 1, thickness: 1),
      ],
    );
  }
}

class TimeLineMiniWidget extends StatefulWidget {
  const TimeLineMiniWidget({super.key, required this.timeline, this.buttonWidth = 40, this.padding = 8.0, this.framePadding = 2.0});
  final Timeline timeline;
  final double buttonWidth;
  final double padding;
  final double framePadding;
  static const int _maxFramesWithLabel = 32;

  @override
  State<TimeLineMiniWidget> createState() => _TimeLineMiniWidgetState();
}

class _TimeLineMiniWidgetState extends State<TimeLineMiniWidget>
{
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  List<Widget> _createRowWidgets() {
    final List<Frame> frames = widget.timeline.frames.value;
    final List<Widget> rowWidgets = <Widget>[];

    final bool showMarkers = widget.timeline.loopStartIndex.value != 0 || widget.timeline.loopEndIndex.value != widget.timeline.frames.value.length - 1;

    for (int i = 0; i < frames.length; i++)
    {
      rowWidgets.add(
        ValueListenableBuilder<int>(
          valueListenable: widget.timeline.loopStartIndex,
          builder: (final BuildContext context, final int loopStartIndex, final Widget? child) {
            return Container(
              width: widget.framePadding,
              color: i == loopStartIndex && showMarkers ? Theme.of(context).primaryColorLight : Colors.transparent,);
          },
        ),
      );


      rowWidgets.add(Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.padding),
          child: ValueListenableBuilder<int>(
            valueListenable: widget.timeline.selectedFrameIndexNotifier,
            builder: (final BuildContext context, final int frameIndex, final Widget? child) {
              final bool isSelected = (i == frameIndex);
              return InkWell(
                onTap: () {
                  widget.timeline.selectFrameByIndex(index: i);
                },
                child: Tooltip(
                  message: "Frame ${i + 1}",
                  waitDuration: AppState.toolTipDuration,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor,
                      ),
                      borderRadius: BorderRadius.circular(widget.buttonWidth / 10),
                    ),
                    child: frames.length <= TimeLineMiniWidget._maxFramesWithLabel ? Center(
                      child: Text(
                        (i + 1).toString(),
                        style: isSelected ? null : Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).primaryColorDark) ,
                      ),
                    ) : null,
                  ),
                ),
              );
            },
          ),
        ),
        ),
      );

      rowWidgets.add(
        ValueListenableBuilder<int>(
          valueListenable: widget.timeline.loopEndIndex,
          builder: (final BuildContext context, final int loopEndIndex, final Widget? child) {
            return Container(
              width: widget.framePadding,
              color: i == loopEndIndex && showMarkers ? Theme.of(context).primaryColorLight : Colors.transparent,);
          },
        ),
      );
    }
    return rowWidgets;
  }

  @override
  Widget build(final BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColorDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(widget.padding),
            child: ValueListenableBuilder<int>(
              valueListenable: widget.timeline.loopEndIndex,
              builder: (final BuildContext context2, final int loopEndIndex, final Widget? child2) {
                return ValueListenableBuilder<int>(
                  valueListenable: widget.timeline.loopStartIndex,
                  builder: (final BuildContext context1, final int loopStartIndex, final Widget? child) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: widget.timeline.isPlaying,
                      builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                        return Tooltip(
                          message: "${isPlaying ? "Pause" : "Play"}${_hotkeyManager.getShortcutString(action: HotkeyAction.timelinePlay)}",
                          waitDuration: AppState.toolTipDuration,
                          child: SizedBox(
                            width: widget.buttonWidth,
                            child: IconButton(
                              onPressed: (loopEndIndex == loopStartIndex) ? null : () {
                                widget.timeline.togglePlaying();
                              },
                              icon: Icon(isPlaying ? TablerIcons.player_pause_filled : TablerIcons.player_play_filled, size: widget.buttonWidth / 2,),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: widget.timeline.loopEndIndex,
            builder: (final BuildContext context2, final int loopEndIndex, final Widget? child2) {
              return ValueListenableBuilder<int>(
                valueListenable: widget.timeline.loopStartIndex,
                builder: (final BuildContext context1, final int loopStartIndex, final Widget? child1) {
                  return ValueListenableBuilder<List<Frame>>(
                    valueListenable: widget.timeline.frames,
                    builder: (final BuildContext context, final List<Frame> frames, final Widget? child) {
                      final List<Widget> rowEntries = _createRowWidgets();
                      return Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: rowEntries,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class TimeLineMarker
{
  final bool isStart;
  const TimeLineMarker({required this.isStart});
}


class TimelineMaxiWidget extends StatefulWidget {
  final FrameBlendingOptions frameBlendingOptions;
  final Timeline timeline;
  final double ownHeight;
  const TimelineMaxiWidget({super.key, required this.timeline, required this.ownHeight, required this.frameBlendingOptions});


  @override
  State<TimelineMaxiWidget> createState() => _TimelineMaxiWidgetState();
}

class _TimelineMaxiWidgetState extends State<TimelineMaxiWidget> {

  static const double _padding = 8.0;
  static const double _borderRadius = 8.0;
  static const double _borderWidth = 2.0;
  static const double _leftSideWidth = 100;
  static const double _cellHeight = 32;
  static const double _cellWidth = 48;
  static const double _cellPadding = 4.0;
  static const double _layerIconSize = 20;
  static const double _transportIconSize = _cellHeight / 2;
  static const int _scrollTimeMs = 50;
  static const double _horizontalScrollHeight = 12;
  static const int _dragTargetDelayMs = 100;

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ValueNotifier<bool> _autoScroll = ValueNotifier<bool>(true);
  static late KPixOverlay _frameTimeOverlay;
  static late KPixOverlay _frameBlendingOverlay;

  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();

  @override
  void initState()
  {
    super.initState();
    widget.timeline.selectedFrameIndexNotifier.addListener(() {
      if (widget.timeline.isPlaying.value && _autoScroll.value && _horizontalScrollController.hasClients && _horizontalScrollController.positions.isNotEmpty)
      {
        final double scrollFactor = widget.timeline.selectedFrameIndex / widget.timeline.frames.value.length;
        final double scrollPosition = (_horizontalScrollController.position.maxScrollExtent * scrollFactor).clamp(0, _horizontalScrollController.position.maxScrollExtent);
        _horizontalScrollController.animateTo(
          scrollPosition,
          duration: (widget.timeline.selectedFrameIndex == 0) ? const Duration(milliseconds: _scrollTimeMs) : Duration(milliseconds: widget.timeline.frames.value[widget.timeline.selectedFrameIndex].fps.value),
          curve: Curves.linear,
        );
      }
    },);
  }

  List<Widget> _createMarkerWidgets({required final List<Frame> frames, required final int loopStart, required final int loopEnd})
  {
    final List<Widget> markerWidgets = <Widget>[];
    markerWidgets.add(const SizedBox(width: _borderWidth));
    for (int i = 0; i < frames.length; i++)
    {
      final Widget dragTarget = Padding(
        padding: const EdgeInsets.all(_cellPadding),
        child: DragTarget<TimeLineMarker>(
          builder: (final BuildContext context, final List<TimeLineMarker?> candidateData, final List<dynamic> rejectedData) {
            return Container(
              color: candidateData.isNotEmpty ? Theme.of(context).primaryColor : Colors.transparent,
              width: _cellWidth - (_cellPadding * 2) + _borderWidth,
              height: _cellHeight / 2,
            );
          },
          onAcceptWithDetails: (final DragTargetDetails<TimeLineMarker> marker) {
            if (marker.data.isStart && i <= loopEnd)
            {
              widget.timeline.setLoopStartMarker(index: i);
            }
            else if (!marker.data.isStart && i >= loopStart)
            {
              widget.timeline.setLoopEndMarker(index: i);
            }
          },
        ),
      );

      if (loopStart == i || loopEnd == i)
      {
        final Widget startIcon = Tooltip(message: "Loop Start Marker", waitDuration: AppState.toolTipDuration, child: ClipRect(child: Align(widthFactor: 0.5, child: Icon(TablerIcons.caret_right_filled, color: Theme.of(context).primaryColorLight,))));
        final Widget endIcon = Tooltip(message: "Loop End Marker", waitDuration: AppState.toolTipDuration, child: ClipRect(child: Align(widthFactor: 0.5, child: Icon(TablerIcons.caret_left_filled, color: Theme.of(context).primaryColorLight,))));

        final SizedBox stack = SizedBox(
          width: _cellWidth,
          child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                dragTarget,
                dragTarget,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    if (loopStart == i) Draggable<TimeLineMarker>(data: const TimeLineMarker(isStart: true), feedback: startIcon, childWhenDragging: const SizedBox.shrink(), child: GestureDetector(onDoubleTap: () {widget.timeline.resetStartMarker();}, child: startIcon)) else const Spacer(),
                    if (loopEnd == i) Draggable<TimeLineMarker>(data: const TimeLineMarker(isStart: false), feedback: endIcon, childWhenDragging: const SizedBox.shrink(), child: GestureDetector(onDoubleTap: () {widget.timeline.resetEndMarker();}, child: endIcon)) else const Spacer(),
                  ],
                ),
              ],
          ),
        );
        markerWidgets.add(stack);
      }
      else
      {
        markerWidgets.add(dragTarget);
      }
    }
    return markerWidgets;
  }


  List<Widget> _createHeaderWidgets({required final List<Frame> frames, required final Color borderColor})
  {
    final List<Widget> headerWidgets = <Widget>[];
    for (int i = 0; i < frames.length; i++)
    {

      if (i == 0)
      {
        headerWidgets.add(Container(color: borderColor, width: _borderWidth, height: _cellHeight,));
      }

      final String indexString = (i + 1).toString();
      final SizedBox hw = SizedBox(
        height: _cellHeight,
        width: _cellWidth,
        child: ValueListenableBuilder<int>(
          valueListenable: widget.timeline.selectedFrameIndexNotifier,
          builder: (final BuildContext context, final int selectedFrameIndex, final Widget? child) {
            final bool isSelected = (i == selectedFrameIndex);
            return TextButton(
              onPressed: () {
                widget.timeline.selectFrameByIndex(index: i);
              },
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.zero),
                backgroundColor: WidgetStateProperty.all(isSelected ? Theme.of(context).primaryColor : Theme.of(context).primaryColorDark),
                foregroundColor: WidgetStateProperty.all(isSelected ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor),
                overlayColor: WidgetStateProperty.all(Theme.of(context).primaryColor.withAlpha(100)),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(0))),
              ),
              child: Text(
                indexString,
                textAlign: TextAlign.center,
                style: isSelected ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.titleMedium,
              ),
            );
          },
        ),
      );
      headerWidgets.add(hw);
      headerWidgets.add(Container(color: borderColor, width: _borderWidth, height: _cellHeight,));
    }
    return headerWidgets;
  }

  Container _createLayerContainer({required final LayerState layer, required final bool frameIsSelected, required final bool layerIsSelected, required final bool isLinkedLayer})
  {
    Color bgColor;
    if (isLinkedLayer)
    {
      bgColor = getColorForLayer(hashCode: layer.hashCode, context: context, selected: frameIsSelected);
    }
    else
    {
      bgColor = frameIsSelected ? Theme.of(context).primaryColor : Theme.of(context).primaryColorDark;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: frameIsSelected ? (layerIsSelected ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColorDark) : (layerIsSelected ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorDark),
          width: _borderWidth,
        ),
        borderRadius: BorderRadius.circular(_borderRadius / 2),
      ),
      width: _cellWidth - (_cellPadding * 2),
      height: _cellHeight - _cellPadding,
      child: Center(child: Icon(layerIconMap[layer.runtimeType], size: _layerIconSize, color: frameIsSelected ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor)),
    );
  }

  List<Widget> _createLayerWidgets({required final List<Frame> frames, required final double minHeight, required final Color borderColor})
  {
    final List<Widget> layerWidgets = <Widget>[];

    if (frames.isNotEmpty)
    {
      final int highestLayerCount = frames.reduce((final Frame a, final Frame b) => a.layerList.length > b.layerList.length ? a : b).layerList.length;
      final double height = max((highestLayerCount + 1) * _cellHeight + _cellPadding, minHeight);

      for (int i = 0; i < frames.length; i++)
      {
        if (i == 0)
        {
          layerWidgets.add(Container(color: borderColor, width: _borderWidth, height: height,));
        }

        layerWidgets.add(
          ValueListenableBuilder<int>(
            valueListenable: widget.timeline.selectedFrameIndexNotifier,
            builder: (final BuildContext context, final int selectedFrameIndex, final Widget? child) {
              final bool frameIsSelected = (i == selectedFrameIndex);
              return InkWell(
                onTap: () {
                  widget.timeline.selectFrameByIndex(index: i);
                },
                child: Container(
                  height: height,
                  color: frameIsSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  child: ListenableBuilder(
                    listenable: frames[i].layerList,
                    builder: (final BuildContext context4, final Widget? child4) {
                      final LayerCollection layerCollection = frames[i].layerList;
                      final List<Widget> layers = <Widget>[];

                      for (int j = 0; j < layerCollection.length; j++)
                      {
                        layers.add(
                          TimeLineDragTargetWidget(
                            cellHeight: _cellHeight,
                            cellWidth: _cellWidth,
                            collapsedHeight: _cellPadding,
                            delayMs: _dragTargetDelayMs,
                            layerIndex: j,
                            frame: frames[i],
                            changeLayerOrderFn: _changeLayerOrder,
                            copyLayerToOtherFrameFn: _copyLayerToOtherFrame,
                            linkLayerToOtherFrameFn: _linkLayerToOtherFrame,
                          ),
                        );
                        final LayerState currentLayer = layerCollection.getLayer(index: j);
                        final bool layerIsSelected = (j == layerCollection.selectedLayerIndex);
                        final bool isLinkLayer = widget.timeline.isLayerLinked(layer: currentLayer);
                        layers.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: _cellPadding),
                            child: InkWell(
                              onTap: () {
                                widget.timeline.selectFrameByIndex(index: i, layerIndex: j);
                              },
                              child: Draggable<LayerFrameDragData>(
                                dragAnchorStrategy: pointerDragAnchorStrategy,
                                data: LayerFrameDragData(frame: frames[i], layer: currentLayer),
                                onDragStarted: () {
                                  widget.timeline.selectFrameByIndex(index: i);
                                },
                                feedback: Container(
                                  width: _cellWidth - (_cellPadding * 2),
                                  height: _cellHeight - _cellPadding,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withAlpha(100),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(_borderRadius),
                                    ),
                                    border: Border.all(
                                      color: Theme.of(context).primaryColorDark,
                                      width: _borderWidth,
                                    ),
                                  ),
                                ),
                                child: _createLayerContainer(layer: currentLayer, frameIsSelected: frameIsSelected, layerIsSelected: layerIsSelected, isLinkedLayer: isLinkLayer),
                              ),
                            ),
                          ),
                        );
                      }
                      layers.add(
                        TimeLineDragTargetWidget(
                          cellHeight: _cellHeight,
                          cellWidth: _cellWidth,
                          collapsedHeight: _cellPadding,
                          delayMs: _dragTargetDelayMs,
                          layerIndex: layerCollection.length,
                          frame: frames[i],
                          changeLayerOrderFn: _changeLayerOrder,
                          copyLayerToOtherFrameFn: _copyLayerToOtherFrame,
                          linkLayerToOtherFrameFn: _linkLayerToOtherFrame,
                        ),
                      );

                      return Column(
                        children: layers,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );

        layerWidgets.add(Container(color: borderColor, width: _borderWidth, height: height,));
      }
      layerWidgets.add(const SizedBox(width: _horizontalScrollHeight + _padding,));


    }
    return layerWidgets;

  }



  List<Widget> _createTimingWidgets({required final List<Frame> frames, required final Color borderColor})
  {
    final List<Widget> timingWidgets = <Widget>[];
    const double height = _cellHeight / 2 + _horizontalScrollHeight + _padding;
    for (int i = 0; i < frames.length; i++)
    {
      final Frame currentFrame = frames[i];
      if (i == 0)
      {
        timingWidgets.add(Container(color: borderColor, width: _borderWidth, height: height));
      }
      final Widget w = ValueListenableBuilder<int>(
        valueListenable: currentFrame.fps,
        builder: (final BuildContext context, final int fps, final Widget? child) {
          return ValueListenableBuilder<int>(
            valueListenable: widget.timeline.selectedFrameIndexNotifier,
            builder: (final BuildContext context, final int selectedFrameIndex, final Widget? child) {
              final bool isSelected = (i == selectedFrameIndex);
              return ValueListenableBuilder<bool>(
                valueListenable: widget.timeline.isPlaying,
                builder: (final BuildContext context1, final bool isPlaying, final Widget? child1) {
                  return Tooltip(
                    message: "Change Duration",
                    waitDuration: AppState.toolTipDuration,
                    child: InkWell(
                      onTap: () {
                        widget.timeline.selectFrameByIndex(index: i);
                        if (!isPlaying)
                        {
                          final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
                          _frameTimeOverlay = KPixOverlay(
                            entry: OverlayEntry(
                              builder: (final BuildContext context) => Stack(
                                children: <Widget>[
                                  ModalBarrier(
                                    color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.all(options.padding),
                                        child: FrameTimeWidget(frame: currentFrame, onDismiss: _frameTimeOverlayDismiss, onConfirmSingle: _frameTimeOverlayConfirmSingle, onConfirmAll: _frameTimeOverlayConfirmAll,),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                          _frameTimeOverlay.show(context: context);
                        }
                      },
                      child: Container(
                        height: height,
                        width: _cellWidth,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                        child: Center(
                          child: Text(
                            "1/$fps",
                            textAlign: TextAlign.center,
                            style: isSelected ? Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold) : Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
      timingWidgets.add(w);
      timingWidgets.add(Container(color: borderColor, width: _borderWidth, height: height,));
    }

    return timingWidgets;
  }

  void _frameTimeOverlayDismiss()
  {
    _frameTimeOverlay.hide();
  }

  void _frameTimeOverlayConfirmSingle({required final Frame frame, required final int value})
  {
    _frameTimeOverlayDismiss();
    widget.timeline.setFrameTimingSingle(frame: frame, fps: value);
    frame.fps.value = value;
  }

  void _frameTimeOverlayConfirmAll({required final int value})
  {
    _frameTimeOverlayDismiss();
    widget.timeline.setFrameTimingAll(fps: value);    
  }

  void _frameBlendingOverlayDismiss()
  {
    _frameBlendingOverlay.hide();
  }

  void _changeLayerOrder(final LayerState layer, final int newPosition)
  {
    GetIt.I.get<AppState>().changeLayerOrder(state: layer, newPosition: newPosition);
  }

  void _copyLayerToOtherFrame(final Frame targetFrame, final LayerState sourceLayer, final int position)
  {
    GetIt.I.get<AppState>().copyLayerToOtherFrame(targetFrame: targetFrame, sourceLayer: sourceLayer, position: position);
  }

  void _linkLayerToOtherFrame(final Frame targetFrame, final LayerState sourceLayer, final int position)
  {
    GetIt.I.get<AppState>().linkLayerToOtherFrame(targetFrame: targetFrame, sourceLayer: sourceLayer, position: position);
  }



  @override
  Widget build(final BuildContext context)
  {
    return Material(
      color: Theme.of(context).primaryColorDark,
      child: Padding(
        padding: const EdgeInsets.only(top: _padding, left: _padding, right: _padding),
        child: Row(
          children: <Widget>[
            Container(
              width: _leftSideWidth,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.all(
                  Radius.circular(_borderRadius),
                ),
                border: Border.all(
                  color: Theme.of(context).primaryColorLight,
                  width: _borderWidth,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(_padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ValueListenableBuilder<int>(
                      valueListenable: widget.timeline.loopEndIndex,
                      builder: (final BuildContext context2, final int loopEnd, final Widget? child2) {
                        return ValueListenableBuilder<int>(
                          valueListenable: widget.timeline.loopStartIndex,
                          builder: (final BuildContext context1, final int loopStart, final Widget? child1) {
                            return ValueListenableBuilder<bool>(
                              valueListenable: widget.timeline.isPlaying,
                              builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                                return Tooltip(
                                  message: "${isPlaying ? "Pause" : "Play"}${_hotkeyManager.getShortcutString(action: HotkeyAction.timelinePlay)}",
                                  waitDuration: AppState.toolTipDuration,
                                  child: SizedBox(
                                    height: _cellHeight,
                                    child: IconButton.outlined(
                                        onPressed: loopStart == loopEnd ? null : () {
                                          widget.timeline.togglePlaying();
                                        },
                                        icon: Icon(isPlaying ? TablerIcons.player_pause_filled : TablerIcons.player_play_filled, size: _transportIconSize,),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const Spacer(),
                    Divider(height: 16, thickness: 2, color: Theme.of(context).primaryColorLight,),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ValueListenableBuilder<int>(
                            valueListenable: widget.timeline.selectedFrameIndexNotifier,
                            builder: (final BuildContext context2, final int selectedFrameIndex, final Widget? child2) {
                              return ValueListenableBuilder<List<Frame>>(
                                valueListenable: widget.timeline.frames,
                                builder: (final BuildContext context1, final List<Frame> frames, final Widget? child1) {
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: widget.timeline.isPlaying,
                                    builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                                      return Tooltip(
                                        message: "Move Frame Left${_hotkeyManager.getShortcutString(action: HotkeyAction.timelineMoveFrameLeft)}",
                                        waitDuration: AppState.toolTipDuration,
                                        child: SizedBox(
                                          height: _cellHeight,
                                          child: IconButton.outlined(
                                              onPressed: (isPlaying || frames.length <= 1 || selectedFrameIndex <= 0) ? null : () {widget.timeline.moveFrameLeft();},
                                              icon: const Icon(TablerIcons.chevron_left),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          width: _padding / 2,
                        ),
                        Tooltip(
                          message: "Move Frame",
                          waitDuration: AppState.toolTipDuration,
                          child: Icon(
                            TablerIcons.arrows_left_right,
                            //size: _layerIconSize,
                            color: Theme.of(context).primaryColorLight,
                          ),
                        ),
                        const SizedBox(
                          width: _padding / 2,
                        ),
                        Expanded(
                          child: ValueListenableBuilder<int>(
                            valueListenable: widget.timeline.selectedFrameIndexNotifier,
                            builder: (final BuildContext context2, final int selectedFrameIndex, final Widget? child2) {
                              return ValueListenableBuilder<List<Frame>>(
                                valueListenable: widget.timeline.frames,
                                builder: (final BuildContext context1, final List<Frame> frames, final Widget? child1) {
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: widget.timeline.isPlaying,
                                    builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                                      return Tooltip(
                                        message: "Move Frame Right${_hotkeyManager.getShortcutString(action: HotkeyAction.timelineMoveFrameRight)}",
                                        waitDuration: AppState.toolTipDuration,
                                        child: SizedBox(
                                          height: _cellHeight,
                                          child: IconButton.outlined(
                                              onPressed: (isPlaying || frames.length <= 1 || selectedFrameIndex >= frames.length - 1) ? null : () {widget.timeline.moveFrameRight();},
                                              icon: const Icon(TablerIcons.chevron_right),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _padding),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: widget.timeline.isPlaying,
                            builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                              return Tooltip(
                                message: "Add Frame Left",
                                waitDuration: AppState.toolTipDuration,
                                child: SizedBox(
                                  height: _cellHeight,
                                  child: IconButton.outlined(
                                    onPressed: isPlaying ? null : () {widget.timeline.addNewFrameLeft();},
                                    icon: const Icon(TablerIcons.chevron_left),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          width: _padding / 2,
                        ),
                        Tooltip(
                          message: "Add Frame",
                          waitDuration: AppState.toolTipDuration,
                          child: Icon(
                            TablerIcons.file,
                            //size: _layerIconSize,
                            color: Theme.of(context).primaryColorLight,
                          ),
                        ),
                        const SizedBox(
                          width: _padding / 2,
                        ),
                        Expanded(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: widget.timeline.isPlaying,
                            builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                              return Tooltip(
                                message: "Add Frame Right",
                                waitDuration: AppState.toolTipDuration,
                                child: SizedBox(
                                  height: _cellHeight,
                                  child: IconButton.outlined(
                                    onPressed: isPlaying ? null : () {widget.timeline.addNewFrameRight();},
                                    icon: const Icon(TablerIcons.chevron_right),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _padding),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: widget.timeline.isPlaying,
                            builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                              return Tooltip(
                                message: "Copy Frame Left",
                                waitDuration: AppState.toolTipDuration,
                                child: SizedBox(
                                  height: _cellHeight,
                                  child: IconButton.outlined(
                                      onPressed: isPlaying ? null : () {widget.timeline.copyFrameLeft();},
                                      icon: const Icon(TablerIcons.chevron_left),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          width: _padding / 2,
                        ),
                        Tooltip(
                          message: "Copy Frame",
                          waitDuration: AppState.toolTipDuration,
                          child: Icon(
                            TablerIcons.copy,
                            //size: _layerIconSize,
                            color: Theme.of(context).primaryColorLight,
                          ),
                        ),
                        const SizedBox(
                          width: _padding / 2,
                        ),
                        Expanded(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: widget.timeline.isPlaying,
                            builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                              return Tooltip(
                                message: "Copy Frame Right",
                                waitDuration: AppState.toolTipDuration,
                                child: SizedBox(
                                  height: _cellHeight,
                                  child: IconButton.outlined(
                                    onPressed: isPlaying ? null : () {widget.timeline.copyFrameRight();},
                                    icon: const Icon(TablerIcons.chevron_right),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _padding),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: widget.timeline.isPlaying,
                            builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                              return Tooltip(
                                message: "Create Linked Frame Left",
                                waitDuration: AppState.toolTipDuration,
                                child: SizedBox(
                                  height: _cellHeight,
                                  child: IconButton.outlined(
                                    onPressed: isPlaying ? null : () {widget.timeline.linkFrameLeft();},
                                    icon: const Icon(TablerIcons.chevron_left),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          width: _padding / 2,
                        ),
                        Tooltip(
                          message: "Create Linked Frame",
                          waitDuration: AppState.toolTipDuration,
                          child: Icon(
                            TablerIcons.link,
                            //size: _layerIconSize,
                            color: Theme.of(context).primaryColorLight,
                          ),
                        ),
                        const SizedBox(
                          width: _padding / 2,
                        ),
                        Expanded(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: widget.timeline.isPlaying,
                            builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                              return Tooltip(
                                message: "Create Linked Frame Right",
                                waitDuration: AppState.toolTipDuration,
                                child: SizedBox(
                                  height: _cellHeight,
                                  child: IconButton.outlined(
                                    onPressed: isPlaying ? null : () {widget.timeline.linkFrameRight();},
                                    icon: const Icon(TablerIcons.chevron_right),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _padding),
                    ValueListenableBuilder<List<Frame>>(
                      valueListenable: widget.timeline.frames,
                      builder: (final BuildContext context1, final List<Frame> frames, final Widget? child) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: widget.timeline.isPlaying,
                          builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                            return Tooltip(
                              message: "Delete Frame",
                              waitDuration: AppState.toolTipDuration,
                              child: SizedBox(
                                height: _cellHeight,
                                child: IconButton.outlined(
                                    onPressed: isPlaying || frames.length <= 1 ? null : () { widget.timeline.deleteFrame(); },
                                    icon: const Icon(TablerIcons.trash),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Divider(height: 16, thickness: 2, color: Theme.of(context).primaryColorLight,),
                    const Spacer(),
                    ValueListenableBuilder<bool>(
                      valueListenable: widget.frameBlendingOptions.enabled,
                      builder: (final BuildContext context, final bool frameBlendingEnabled, final Widget? child) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: widget.timeline.isPlaying,
                          builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                            return Tooltip(
                              message: "Frame Blending\nToggle: ${GetIt.I.get<HotkeyManager>().getShortcutString(action: HotkeyAction.timelineToggleFrameBlending, precededNewLine: false)}",
                              waitDuration: AppState.toolTipDuration,
                              child: SizedBox(
                                height: _cellHeight,
                                child: IconButton.outlined(
                                  style: ButtonStyle(
                                    tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: frameBlendingEnabled && !isPlaying
                                        ? WidgetStatePropertyAll<Color?>(
                                      Theme.of(context)
                                          .primaryColorLight,)
                                        : null,
                                    iconColor: frameBlendingEnabled && !isPlaying
                                        ? WidgetStatePropertyAll<Color?>(
                                      Theme.of(context)
                                          .primaryColor,)
                                        : null,
                                  ),
                                  onPressed: isPlaying ? null : () {
                                    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
                                    _frameBlendingOverlay = KPixOverlay(
                                      entry: OverlayEntry(
                                        builder: (final BuildContext context) => Stack(
                                          children: <Widget>[
                                            ModalBarrier(
                                              color: Theme.of(context).primaryColorDark.withAlpha(options.smokeOpacity),
                                            ),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.all(options.padding),
                                                  child: FrameBlendingWidget(onDismiss: _frameBlendingOverlayDismiss, options: widget.frameBlendingOptions,),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                    _frameBlendingOverlay.show(context: context);
                                  },
                                  icon: const Icon(TablerIcons.blend_mode),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: _padding),

            Expanded(
              child: Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: isDesktop(includingWeb: true),
                thickness: _horizontalScrollHeight,
                radius: const Radius.circular(_borderRadius / 2),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _horizontalScrollController,
                  child: ValueListenableBuilder<List<Frame>>(
                    valueListenable: widget.timeline.frames,
                    builder: (final BuildContext context, final List<Frame> frames, final Widget? child) {

                      final Color borderColor = Theme.of(context).primaryColorLight;
                      final List<Widget> headerWidgets = _createHeaderWidgets(frames: frames, borderColor: borderColor);
                      final List<Widget> timingWidgets = _createTimingWidgets(frames: frames, borderColor: borderColor);

                      final double dividerWidth = (frames.length.toDouble() * _cellWidth) + (frames.length.toDouble() * _borderWidth) + _borderWidth;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ValueListenableBuilder<int>(
                            valueListenable: widget.timeline.loopStartIndex,
                            builder: (final BuildContext context2, final int loopStartIndex, final Widget? child2) {
                              return ValueListenableBuilder<int>(
                                valueListenable: widget.timeline.loopEndIndex,
                                builder: (final BuildContext context3, final int loopEndIndex, final Widget? child) {
                                  return Row(
                                    children: _createMarkerWidgets(frames: frames, loopStart: loopStartIndex, loopEnd: loopEndIndex),
                                  );
                                },
                              );
                            },
                          ),

                          Container(height: _borderWidth, color: borderColor, width: dividerWidth,),

                          Row(
                            children: headerWidgets,
                          ),

                          Container(height: _borderWidth, color: borderColor, width: dividerWidth,),

                          Expanded(
                            child: ListenableBuilder(
                              listenable: GetIt.I.get<AppState>().timeline.layerChangeNotifier,
                              builder: (final BuildContext context, final Widget? child) {
                                return LayoutBuilder(
                                  builder: (final BuildContext context4, final BoxConstraints constraints) {
                                    return Scrollbar(
                                      controller: _verticalScrollController,
                                      thickness: _horizontalScrollHeight,
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        controller: _verticalScrollController,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: _createLayerWidgets(frames: frames, minHeight: constraints.maxHeight, borderColor: borderColor),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          Container(height: _borderWidth, color: borderColor, width: dividerWidth,),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: timingWidgets,
                          ),
                          Container(height: _borderWidth, color: borderColor, width: dividerWidth,),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
