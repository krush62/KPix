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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/frame_blending_options.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/util/helpers/platform_helper.dart';
import 'package:kpix/util/layer_color_supplier.dart';
import 'package:kpix/widgets/layer_action_messages.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/timeline/frame_blending_widget.dart';
import 'package:kpix/widgets/timeline/frame_time_widget.dart';
import 'package:kpix/widgets/timeline/timeline_drag_target_widget.dart';

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
  final FrameBlendingOptions frameBlendingOptions = GetIt.I.get<FrameBlendingOptions>();
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

    _hotkeyManager.addListener(func: _togglePlayingHotkey, action: HotkeyAction.timelinePlay);
    _hotkeyManager.addListener(func: _nextFrameHotkey, action: HotkeyAction.timelineNextFrame);
    _hotkeyManager.addListener(func: _previousFrameHotkey, action: HotkeyAction.timelinePreviousFrame);
    _hotkeyManager.addListener(func: _moveFrameLeftHotkey, action: HotkeyAction.timelineMoveFrameLeft);
    _hotkeyManager.addListener(func: _moveFrameRightHotkey, action: HotkeyAction.timelineMoveFrameRight);
    _hotkeyManager.addListener(func: _toggleFrameBlending, action: HotkeyAction.timelineToggleFrameBlending);
    _hotkeyManager.addListener(func: _expandView, action: HotkeyAction.timelineExpand);
    _hotkeyManager.addListener(func: _collapseView, action: HotkeyAction.timelineCollapse);
  }

  //the widget is remounted with every new project
  @override
  void dispose()
  {
    _hotkeyManager.removeListener(func: _togglePlayingHotkey, action: HotkeyAction.timelinePlay);
    _hotkeyManager.removeListener(func: _nextFrameHotkey, action: HotkeyAction.timelineNextFrame);
    _hotkeyManager.removeListener(func: _previousFrameHotkey, action: HotkeyAction.timelinePreviousFrame);
    _hotkeyManager.removeListener(func: _moveFrameLeftHotkey, action: HotkeyAction.timelineMoveFrameLeft);
    _hotkeyManager.removeListener(func: _moveFrameRightHotkey, action: HotkeyAction.timelineMoveFrameRight);
    _hotkeyManager.removeListener(func: _toggleFrameBlending, action: HotkeyAction.timelineToggleFrameBlending);
    _hotkeyManager.removeListener(func: _expandView, action: HotkeyAction.timelineExpand);
    _hotkeyManager.removeListener(func: _collapseView, action: HotkeyAction.timelineCollapse);
    _animationController.dispose();
    isExpanded.dispose();
    super.dispose();
  }

  void _togglePlayingHotkey() => widget.timeline.togglePlaying();
  void _nextFrameHotkey() => widget.timeline.selectNextFrame();
  void _previousFrameHotkey() => widget.timeline.selectPreviousFrame();

  void _moveFrameLeftHotkey()
  {
    if (!widget.timeline.isPlaying.value && widget.timeline.frames.value.length > 1 && widget.timeline.selectedFrameIndex > 0)
    {
      widget.timeline.moveFrameLeft();
    }
  }

  void _moveFrameRightHotkey()
  {
    if (!widget.timeline.isPlaying.value && widget.timeline.frames.value.length > 1 && widget.timeline.selectedFrameIndex < widget.timeline.frames.value.length - 1)
    {
      widget.timeline.moveFrameRight();
    }
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
    GetIt.I.get<ViewState>().repaintNotifier.repaint();
  }


  @override
  Widget build(final BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
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
                      return SizedBox(
                        width: widget.height - widget.padding * 2,
                        child: IconButton(
                          tooltip: isExpanded ? l10n.collapseTimeline : l10n.expandTimeline,
                          onPressed: () {
                            _toggleExpand();
                          },
                          icon: Icon(isExpanded ? TablerIcons.chevron_up : TablerIcons.chevron_down, size: widget.height / 2,),
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

class _FrameSelectedNotifier extends ValueNotifier<bool>
{
  final ValueListenable<int> _source;
  final int _frameIndex;

  _FrameSelectedNotifier({required final ValueListenable<int> source, required final int frameIndex})
      : _source = source,
        _frameIndex = frameIndex,
        super(source.value == frameIndex)
  {
    _source.addListener(_sourceChanged);
  }

  void _sourceChanged()
  {
    value = _source.value == _frameIndex;
  }

  @override
  void dispose()
  {
    _source.removeListener(_sourceChanged);
    super.dispose();
  }
}

class _FrameSelectionViews
{
  _FrameSelectionViews({required this.source});

  final ValueListenable<int> source;
  final Map<int, _FrameSelectedNotifier> _views = <int, _FrameSelectedNotifier>{};

  ValueListenable<bool> forIndex({required final int index})
  {
    return _views.putIfAbsent(index, () => _FrameSelectedNotifier(source: source, frameIndex: index));
  }

  void dispose()
  {
    for (final _FrameSelectedNotifier view in _views.values)
    {
      view.dispose();
    }
    _views.clear();
  }
}

class _TimeLineMiniWidgetState extends State<TimeLineMiniWidget>
{
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  late final _FrameSelectionViews _frameSelection =
      _FrameSelectionViews(source: widget.timeline.selectedFrameIndexNotifier);

  @override
  void dispose()
  {
    _frameSelection.dispose();
    super.dispose();
  }

  List<Widget> _createRowWidgets() {
    final List<Frame> frames = widget.timeline.frames.value;
    final int loopStartIndex = widget.timeline.loopStartIndex.value;
    final int loopEndIndex = widget.timeline.loopEndIndex.value;
    final List<Widget> rowWidgets = <Widget>[];

    final bool showMarkers = loopStartIndex != 0 || loopEndIndex != frames.length - 1;

    for (int i = 0; i < frames.length; i++)
    {
      rowWidgets.add(
        Container(
          width: widget.framePadding,
          color: i == loopStartIndex && showMarkers ? Theme.of(context).primaryColorLight : Colors.transparent,
        ),
      );


      rowWidgets.add(Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.padding),
          child: ValueListenableBuilder<bool>(
            valueListenable: _frameSelection.forIndex(index: i),
            builder: (final BuildContext context, final bool isSelected, final Widget? child) {
              return InkWell(
                onTap: () {
                  widget.timeline.selectFrameByIndex(index: i);
                },
                child: Tooltip(
                  message: AppLocalizations.of(context)!.frameNumber(i + 1),
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
        Container(
          width: widget.framePadding,
          color: i == loopEndIndex && showMarkers ? Theme.of(context).primaryColorLight : Colors.transparent,
        ),
      );
    }
    return rowWidgets;
  }

  @override
  Widget build(final BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).primaryColorDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(widget.padding),
            child: ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[widget.timeline.loopEndIndex, widget.timeline.loopStartIndex, widget.timeline.isPlaying]),
              builder: (final BuildContext context, final Widget? child) {
                final bool isPlaying = widget.timeline.isPlaying.value;
                return SizedBox(
                  width: widget.buttonWidth,
                  child: IconButton(
                    tooltip: "${isPlaying ? l10n.pause : l10n.play}${_hotkeyManager.getShortcutString(action: HotkeyAction.timelinePlay, context: context)}",
                    onPressed: (widget.timeline.loopEndIndex.value == widget.timeline.loopStartIndex.value) ? null : () {
                      widget.timeline.togglePlaying();
                    },
                    icon: Icon(isPlaying ? TablerIcons.player_pause_filled : TablerIcons.player_play_filled, size: widget.buttonWidth / 2,),
                  ),
                );
              },
            ),
          ),
          ListenableBuilder(
            listenable: Listenable.merge(<Listenable>[widget.timeline.loopEndIndex, widget.timeline.loopStartIndex, widget.timeline.frames]),
            builder: (final BuildContext context, final Widget? child) {
              return Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _createRowWidgets(),
                ),
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
  late final _FrameSelectionViews _frameSelection =
      _FrameSelectionViews(source: widget.timeline.selectedFrameIndexNotifier);

  @override
  void initState()
  {
    super.initState();
    widget.timeline.selectedFrameIndexNotifier.addListener(_followSelectedFrame);
  }

  void _followSelectedFrame()
  {
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
  }

  @override
  void dispose()
  {
    widget.timeline.selectedFrameIndexNotifier.removeListener(_followSelectedFrame);
    _frameSelection.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _autoScroll.dispose();
    super.dispose();
  }

  List<Widget> _createMarkerWidgets({required final List<Frame> frames, required final int loopStart, required final int loopEnd, required final AppLocalizations l10n})
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
        final Widget startIcon = Tooltip(message: l10n.loopStartMarker, child: ClipRect(child: Align(widthFactor: 0.5, child: Icon(TablerIcons.caret_right_filled, color: Theme.of(context).primaryColorLight,))));
        final Widget endIcon = Tooltip(message: l10n.loopEndMarker, child: ClipRect(child: Align(widthFactor: 0.5, child: Icon(TablerIcons.caret_left_filled, color: Theme.of(context).primaryColorLight,))));

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
        child: ValueListenableBuilder<bool>(
          valueListenable: _frameSelection.forIndex(index: i),
          builder: (final BuildContext context, final bool isSelected, final Widget? child) {
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
      child: Center(child: Icon(layer.icon, size: _layerIconSize, color: frameIsSelected ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor)),
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
          ValueListenableBuilder<bool>(
            valueListenable: _frameSelection.forIndex(index: i),
            builder: (final BuildContext context, final bool frameIsSelected, final Widget? child) {
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



  List<Widget> _createTimingWidgets({required final List<Frame> frames, required final Color borderColor, required final AppLocalizations l10n})
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
      final ValueListenable<bool> isSelected = _frameSelection.forIndex(index: i);
      final Widget w = ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[currentFrame.fps, isSelected]),
        builder: (final BuildContext context, final Widget? child) {
          return Tooltip(
            message: l10n.changeDuration,
            child: InkWell(
              onTap: () {
                widget.timeline.selectFrameByIndex(index: i);
                if (!widget.timeline.isPlaying.value)
                {
                  _showFrameTimeOverlay(frame: currentFrame);
                }
              },
              child: Container(
                height: height,
                width: _cellWidth,
                color: isSelected.value ? Theme.of(context).primaryColor : Colors.transparent,
                child: Center(
                  child: Text(
                    "1/${currentFrame.fps.value}",
                    textAlign: TextAlign.center,
                    style: isSelected.value ? Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold) : Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ),
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
    GetIt.I.get<LayerManager>().changeLayerOrder(state: layer, newPosition: newPosition);
  }

  void _copyLayerToOtherFrame(final Frame targetFrame, final LayerState sourceLayer, final int position)
  {
    final LayerActionResult result = GetIt.I.get<LayerManager>().copyLayerToOtherFrame(targetFrame: targetFrame, sourceLayer: sourceLayer, position: position);
    showMessageForResult(result: result, l10n: AppLocalizations.of(context)!);

  }

  void _linkLayerToOtherFrame(final Frame targetFrame, final LayerState sourceLayer, final int position)
  {
    final LayerActionResult result = GetIt.I.get<LayerManager>().linkLayerToOtherFrame(targetFrame: targetFrame, sourceLayer: sourceLayer, position: position);
    showMessageForResult(result: result, l10n: AppLocalizations.of(context)!);
  }

  OverlayEntry _createDialogEntry({required final Widget dialog})
  {
    return OverlayEntry(
      builder: (final BuildContext context) => Stack(
        children: <Widget>[
          ModalBarrier(
            color: Theme.of(context).primaryColorDark.withAlpha(OverlayEntryAlertDialogOptions.smokeOpacity),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                child: dialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFrameTimeOverlay({required final Frame frame})
  {
    //created once, so Enter reads the value the user picked
    final FrameTimeWidget frameTimeWidget = FrameTimeWidget(frame: frame, onDismiss: _frameTimeOverlayDismiss, onConfirmSingle: _frameTimeOverlayConfirmSingle, onConfirmAll: _frameTimeOverlayConfirmAll,);
    _frameTimeOverlay = KPixOverlay(
      onEscape: _frameTimeOverlayDismiss,
      onEnter: () {_frameTimeOverlayConfirmSingle(frame: frame, value: frameTimeWidget.valueNotifier.value);},
      entry: _createDialogEntry(dialog: frameTimeWidget),
    );
    _frameTimeOverlay.show(context: context);
  }

  void _showFrameBlendingOverlay()
  {
    _frameBlendingOverlay = KPixOverlay(
      onEscape: _frameBlendingOverlayDismiss,
      onEnter: _frameBlendingOverlayDismiss,
      entry: _createDialogEntry(dialog: FrameBlendingWidget(onDismiss: _frameBlendingOverlayDismiss, options: widget.frameBlendingOptions,)),
    );
    _frameBlendingOverlay.show(context: context);
  }

  /// Locked during playback and unless [isAllowed], whose inputs belong in [dependsOn].
  Widget _createFrameButton({
    required final String tooltip,
    final HotkeyAction? hotkey,
    required final IconData icon,
    final List<Listenable> dependsOn = const <Listenable>[],
    final bool Function()? isAllowed,
    required final VoidCallback onPressed,
  })
  {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[widget.timeline.isPlaying, ...dependsOn]),
      builder: (final BuildContext context, final Widget? child) {
        final bool isUsable = !widget.timeline.isPlaying.value && (isAllowed == null || isAllowed());
        return SizedBox(
          height: _cellHeight,
          child: IconButton.outlined(
            tooltip: hotkey == null ? tooltip : tooltip + _hotkeyManager.getShortcutString(action: hotkey, context: context),
            onPressed: isUsable ? onPressed : null,
            icon: Icon(icon),
          ),
        );
      },
    );
  }

  Widget _createFrameChangeButton({required final String tooltip, required final IconData icon, required final LayerActionResult Function() change})
  {
    return _createFrameButton(
      tooltip: tooltip,
      icon: icon,
      onPressed: () {
        showMessageForResult(result: change(), l10n: AppLocalizations.of(context)!);
      },
    );
  }

  Widget _createFrameActionRow({required final String tooltip, required final IconData icon, required final Widget left, required final Widget right})
  {
    return Row(
      children: <Widget>[
        Expanded(child: left),
        const SizedBox(
          width: _padding / 2,
        ),
        Tooltip(
          message: tooltip,
          child: Icon(
            icon,
            color: Theme.of(context).primaryColorLight,
          ),
        ),
        const SizedBox(
          width: _padding / 2,
        ),
        Expanded(child: right),
      ],
    );
  }

  Widget _createTransportPanel({required final AppLocalizations l10n})
  {
    final Timeline timeline = widget.timeline;
    final List<Listenable> moveDependencies = <Listenable>[timeline.selectedFrameIndexNotifier, timeline.frames];
    return Container(
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
            ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[timeline.loopEndIndex, timeline.loopStartIndex, timeline.isPlaying]),
              builder: (final BuildContext context, final Widget? child) {
                final bool isPlaying = timeline.isPlaying.value;
                return SizedBox(
                  height: _cellHeight,
                  child: IconButton.outlined(
                    tooltip: "${isPlaying ? l10n.pause : l10n.play}${_hotkeyManager.getShortcutString(action: HotkeyAction.timelinePlay, context: context)}",
                    onPressed: timeline.loopStartIndex.value == timeline.loopEndIndex.value ? null : () {
                      timeline.togglePlaying();
                    },
                    icon: Icon(isPlaying ? TablerIcons.player_pause_filled : TablerIcons.player_play_filled, size: _transportIconSize,),
                  ),
                );
              },
            ),
            const Spacer(),
            Divider(height: 16, thickness: 2, color: Theme.of(context).primaryColorLight,),
            _createFrameActionRow(
              tooltip: l10n.moveFrame,
              icon: TablerIcons.arrows_left_right,
              left: _createFrameButton(
                tooltip: l10n.moveFrameLeft,
                hotkey: HotkeyAction.timelineMoveFrameLeft,
                icon: TablerIcons.chevron_left,
                dependsOn: moveDependencies,
                isAllowed: () => timeline.frames.value.length > 1 && timeline.selectedFrameIndex > 0,
                onPressed: timeline.moveFrameLeft,
              ),
              right: _createFrameButton(
                tooltip: l10n.moveFrameRight,
                hotkey: HotkeyAction.timelineMoveFrameRight,
                icon: TablerIcons.chevron_right,
                dependsOn: moveDependencies,
                isAllowed: () => timeline.frames.value.length > 1 && timeline.selectedFrameIndex < timeline.frames.value.length - 1,
                onPressed: timeline.moveFrameRight,
              ),
            ),
            const SizedBox(height: _padding),
            _createFrameActionRow(
              tooltip: l10n.addFrame,
              icon: TablerIcons.file,
              left: _createFrameChangeButton(tooltip: l10n.addFrameLeft, icon: TablerIcons.chevron_left, change: timeline.addNewFrameLeft),
              right: _createFrameChangeButton(tooltip: l10n.addFrameRight, icon: TablerIcons.chevron_right, change: timeline.addNewFrameRight),
            ),
            const SizedBox(height: _padding),
            _createFrameActionRow(
              tooltip: l10n.copyFrame,
              icon: TablerIcons.copy,
              left: _createFrameChangeButton(tooltip: l10n.copyFrameLeft, icon: TablerIcons.chevron_left, change: timeline.copyFrameLeft),
              right: _createFrameChangeButton(tooltip: l10n.copyFrameRight, icon: TablerIcons.chevron_right, change: timeline.copyFrameRight),
            ),
            const SizedBox(height: _padding),
            _createFrameActionRow(
              tooltip: l10n.createLinkedFrame,
              icon: TablerIcons.link,
              left: _createFrameChangeButton(tooltip: l10n.createLinkedFrameLeft, icon: TablerIcons.chevron_left, change: timeline.linkFrameLeft),
              right: _createFrameChangeButton(tooltip: l10n.createLinkedFrameRight, icon: TablerIcons.chevron_right, change: timeline.linkFrameRight),
            ),
            const SizedBox(height: _padding),
            _createFrameButton(
              tooltip: l10n.deleteFrame,
              icon: TablerIcons.trash,
              dependsOn: <Listenable>[timeline.frames],
              isAllowed: () => timeline.frames.value.length > 1,
              onPressed: timeline.deleteFrame,
            ),
            Divider(height: 16, thickness: 2, color: Theme.of(context).primaryColorLight,),
            const Spacer(),
            ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[widget.frameBlendingOptions.enabled, timeline.isPlaying]),
              builder: (final BuildContext context, final Widget? child) {
                final bool isPlaying = timeline.isPlaying.value;
                final bool isHighlighted = widget.frameBlendingOptions.enabled.value && !isPlaying;
                return SizedBox(
                  height: _cellHeight,
                  child: IconButton.outlined(
                    tooltip: "${l10n.frameBlending}\n${l10n.toggle}${_hotkeyManager.getShortcutString(action: HotkeyAction.timelineToggleFrameBlending, precededNewLine: false, context: context)}:",
                    style: ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: isHighlighted ? WidgetStatePropertyAll<Color?>(Theme.of(context).primaryColorLight) : null,
                      iconColor: isHighlighted ? WidgetStatePropertyAll<Color?>(Theme.of(context).primaryColor) : null,
                    ),
                    onPressed: isPlaying ? null : _showFrameBlendingOverlay,
                    icon: const Icon(TablerIcons.blend_mode),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).primaryColorDark,
      child: Padding(
        padding: const EdgeInsets.only(top: _padding, left: _padding, right: _padding),
        child: Row(
          children: <Widget>[
            _createTransportPanel(l10n: l10n),

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
                      final List<Widget> timingWidgets = _createTimingWidgets(frames: frames, borderColor: borderColor, l10n: l10n);

                      final double dividerWidth = (frames.length.toDouble() * _cellWidth) + (frames.length.toDouble() * _borderWidth) + _borderWidth;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ListenableBuilder(
                            listenable: Listenable.merge(<Listenable>[widget.timeline.loopStartIndex, widget.timeline.loopEndIndex]),
                            builder: (final BuildContext context, final Widget? child) {
                              return Row(
                                children: _createMarkerWidgets(frames: frames, loopStart: widget.timeline.loopStartIndex.value, loopEnd: widget.timeline.loopEndIndex.value, l10n: l10n),
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
                              listenable: GetIt.I.get<DocumentState>().timeline.layerChangeNotifier,
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
