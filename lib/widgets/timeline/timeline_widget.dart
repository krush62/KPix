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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/timeline/frame_time_widget.dart';

const Map<Type, IconData> layerIconMap = <Type, IconData>{
  ReferenceLayerState: FontAwesomeIcons.image,
  GridLayerState: FontAwesomeIcons.tableCells,
  ShadingLayerState: Icons.exposure,
  DitherLayerState: Icons.gradient,
  DrawingLayerState: Icons.brush,
};

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
                            onPressed: () {
                              _toggleExpand();
                            },
                            icon: FaIcon(isExpanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown, size: widget.height / 2,),
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

  @override
  State<TimeLineMiniWidget> createState() => _TimeLineMiniWidgetState();
}

class _TimeLineMiniWidgetState extends State<TimeLineMiniWidget>
{

  List<Widget> _createRowWidgets() {
    final List<Frame> frames = widget.timeline.frames.value;
    final List<Widget> rowWidgets = <Widget>[];

    final bool showMarkers = widget.timeline.loopStartIndex.value != 0 && widget.timeline.loopEndIndex.value != widget.timeline.frames.value.length - 1;

    for (int i = 0; i < frames.length; i++) {
      final Frame currentFrame = frames[i];

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
          child: ListenableBuilder(
            listenable: currentFrame,
            builder: (final BuildContext context, final Widget? child) {
              final bool isSelected = (i == widget.timeline.selectedFrameIndex.value);
              return InkWell(
                onTap: () {
                  widget.timeline.selectedFrameIndex.value = i;
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor,
                    ),
                    borderRadius: BorderRadius.circular(widget.buttonWidth / 10),
                  ),
                  child: Center(
                    child: Text(
                      (i + 1).toString(),
                      style: isSelected ? null : Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).primaryColorDark) ,
                    ),
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
                        return SizedBox(
                          width: widget.buttonWidth,
                          child: IconButton(
                            onPressed: (loopEndIndex == loopStartIndex) ? null : () {
                              widget.timeline.isPlaying.value = !isPlaying;
                            },
                            icon: FaIcon(isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play, size: widget.buttonWidth / 2,),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          ValueListenableBuilder<List<Frame>>(
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
  final Timeline timeline;
  final double ownHeight;
  const TimelineMaxiWidget({super.key, required this.timeline, required this.ownHeight});


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

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ValueNotifier<bool> _autoScroll = ValueNotifier<bool>(true);
  static late KPixOverlay _frameTimeOverlay;

  @override
  void initState()
  {
    super.initState();
    widget.timeline.selectedFrameIndex.addListener(() {
      if (widget.timeline.isPlaying.value && _autoScroll.value)
      {
        final double scrollFactor = widget.timeline.selectedFrameIndex.value / widget.timeline.frames.value.length;
        final double scrollPosition = (_horizontalScrollController.position.maxScrollExtent * scrollFactor).clamp(0, _horizontalScrollController.position.maxScrollExtent);
        _horizontalScrollController.animateTo(
          scrollPosition,
          duration: (widget.timeline.selectedFrameIndex.value == 0) ? const Duration(milliseconds: _scrollTimeMs) : Duration(milliseconds: widget.timeline.frames.value[widget.timeline.selectedFrameIndex.value].fps.value),
          curve: Curves.linear,
        );
      }
    },);
  }


  void _layerSelected({required final Frame frame, required final int layerIndex})
  {
    final LayerState toSelect = frame.layerList.value.getLayer(index: layerIndex);
    frame.layerList.value.selectLayer(newLayer: toSelect);
    widget.timeline.selectedFrameIndex.value = widget.timeline.frames.value.indexOf(frame);
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
              widget.timeline.loopStartIndex.value = i;
            }
            else if (!marker.data.isStart && i >= loopStart)
            {
              widget.timeline.loopEndIndex.value = i;
            }
          },
        ),
      );

      if (loopStart == i || loopEnd == i)
      {
        final FaIcon startIcon = FaIcon(FontAwesomeIcons.caretRight, color: Theme.of(context).primaryColorLight,);
        final FaIcon endIcon = FaIcon(FontAwesomeIcons.caretLeft, color: Theme.of(context).primaryColorLight,);

        final SizedBox stack = SizedBox(
          width: _cellWidth,
          child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
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
      final Frame currentFrame = frames[i];

      if (i == 0)
      {
        headerWidgets.add(Container(color: borderColor, width: _borderWidth, height: _cellHeight,));
      }

      final String indexString = (i + 1).toString();
      final SizedBox hw = SizedBox(
        height: _cellHeight,
        width: _cellWidth,
        child: ListenableBuilder(
          listenable: currentFrame,
          builder: (final BuildContext context, final Widget? child) {
            final bool isSelected = (i == widget.timeline.selectedFrameIndex.value);
            return TextButton(
              onPressed: () {
                widget.timeline.selectedFrameIndex.value = i;
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

  List<Widget> _createLayerWidgets({required final List<Frame> frames, required final double minHeight, required final Color borderColor})
  {
    final List<Widget> layerWidgets = <Widget>[];

    if (frames.isNotEmpty)
    {
      final int highestLayerCount = frames.reduce((final Frame a, final Frame b) => a.layerList.value.length > b.layerList.value.length ? a : b).layerList.value.length;
      final double height = max(highestLayerCount * _cellHeight + _cellPadding, minHeight);

      for (int i = 0; i < frames.length; i++)
      {
        if (i == 0)
        {
          layerWidgets.add(Container(color: borderColor, width: _borderWidth, height: height,));
        }

        layerWidgets.add(
          ListenableBuilder(
            listenable: frames[i],
            builder: (final BuildContext context, final Widget? child) {
              final bool isSelected = (i == widget.timeline.selectedFrameIndex.value);
              return InkWell(
                onTap: () {
                  widget.timeline.selectedFrameIndex.value = i;
                },
                child: Container(
                  height: height,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  child: ListenableBuilder(
                    listenable: frames[i].layerList.value,
                    builder: (final BuildContext context4, final Widget? child4) {
                      return ValueListenableBuilder<LayerCollection>(
                        valueListenable: frames[i].layerList,
                        builder: (final BuildContext context2, final LayerCollection layerCollection, final Widget? child) {
                          final List<Widget> layers = <Widget>[];
                          for (int j = 0; j < layerCollection.length; j++)
                          {
                            final bool layerIsSelected = (j == layerCollection.getSelectedLayerIndex());
                            layers.add(
                              Padding(
                                padding: const EdgeInsets.only(top: _cellPadding, left: _cellPadding, right: _cellPadding),
                                child: InkWell(
                                  onTap: () {
                                    _layerSelected(frame: frames[i], layerIndex: j);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).primaryColorDark,
                                      border: Border.all(
                                        color: isSelected ? (layerIsSelected ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColorDark) : (layerIsSelected ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorDark),
                                        width: _borderWidth,
                                      ),
                                      borderRadius: BorderRadius.circular(_borderRadius / 2),
                                    ),
                                    width: _cellWidth - (_cellPadding * 2),
                                    height: _cellHeight - _cellPadding,
                                    child: Center(child: FaIcon(layerIconMap[layerCollection.getLayer(index: j).runtimeType], size: _layerIconSize, color: isSelected ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor)),
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: layers,
                          );
                        },
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
          return ListenableBuilder(
            listenable: currentFrame,
            builder: (final BuildContext context, final Widget? child) {
              final bool isSelected = (i == widget.timeline.selectedFrameIndex.value);
              return ValueListenableBuilder<bool>(
                valueListenable: widget.timeline.isPlaying,
                builder: (final BuildContext context1, final bool isPlaying, final Widget? child1) {
                  return InkWell(
                    onTap: () {
                      widget.timeline.selectedFrameIndex.value = i;
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
    frame.fps.value = value;
  }

  void _frameTimeOverlayConfirmAll({required final int value})
  {
    _frameTimeOverlayDismiss();
    for (final Frame f in widget.timeline.frames.value)
    {
      f.fps.value = value;
    }
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
                                  return SizedBox(
                                    height: _cellHeight,
                                    child: IconButton.outlined(
                                        onPressed: loopStart == loopEnd ? null : () {
                                          widget.timeline.isPlaying.value = !isPlaying;
                                        },
                                        icon: FaIcon(isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play, size: _transportIconSize,),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      const Spacer(),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: ValueListenableBuilder<int>(
                              valueListenable: widget.timeline.selectedFrameIndex,
                              builder: (final BuildContext context2, final int selectedFrameIndex, final Widget? child2) {
                                return ValueListenableBuilder<List<Frame>>(
                                  valueListenable: widget.timeline.frames,
                                  builder: (final BuildContext context1, final List<Frame> frames, final Widget? child1) {
                                    return ValueListenableBuilder<bool>(
                                      valueListenable: widget.timeline.isPlaying,
                                      builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                                        return SizedBox(
                                          height: _cellHeight,
                                          child: IconButton.outlined(
                                              onPressed: (isPlaying || frames.length <= 1 || selectedFrameIndex <= 0) ? null : () {widget.timeline.moveFrameLeft();},
                                              icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: _transportIconSize),
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
                          FaIcon(FontAwesomeIcons.leftRight, size: _layerIconSize, color: Theme.of(context).primaryColorLight,),
                          const SizedBox(
                            width: _padding / 2,
                          ),
                          Expanded(
                            child: ValueListenableBuilder<int>(
                              valueListenable: widget.timeline.selectedFrameIndex,
                              builder: (final BuildContext context2, final int selectedFrameIndex, final Widget? child2) {
                                return ValueListenableBuilder<List<Frame>>(
                                  valueListenable: widget.timeline.frames,
                                  builder: (final BuildContext context1, final List<Frame> frames, final Widget? child1) {
                                    return ValueListenableBuilder<bool>(
                                      valueListenable: widget.timeline.isPlaying,
                                      builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                                        return SizedBox(
                                          height: _cellHeight,
                                          child: IconButton.outlined(
                                              onPressed: (isPlaying || frames.length <= 1 || selectedFrameIndex >= frames.length - 1) ? null : () {widget.timeline.moveFrameRight();},
                                              icon: const FaIcon(FontAwesomeIcons.chevronRight, size: _transportIconSize),
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
                                return SizedBox(
                                  height: _cellHeight,
                                  child: IconButton.outlined(
                                    onPressed: isPlaying ? null : () {widget.timeline.addNewFrameLeft();},
                                    icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: _transportIconSize),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(
                            width: _padding / 2,
                          ),
                          FaIcon(FontAwesomeIcons.file, size: _layerIconSize, color: Theme.of(context).primaryColorLight,),
                          const SizedBox(
                            width: _padding / 2,
                          ),
                          Expanded(
                            child: ValueListenableBuilder<bool>(
                              valueListenable: widget.timeline.isPlaying,
                              builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                                return SizedBox(
                                  height: _cellHeight,
                                  child: IconButton.outlined(
                                    onPressed: isPlaying ? null : () {widget.timeline.addNewFrameRight();},
                                    icon: const FaIcon(FontAwesomeIcons.chevronRight, size: _transportIconSize),
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
                                  return SizedBox(
                                    height: _cellHeight,
                                    child: IconButton.outlined(
                                        onPressed: isPlaying ? null : () {widget.timeline.copyFrameLeft();},
                                        icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: _transportIconSize),
                                    ),
                                  );
                                },
                            ),
                          ),
                          const SizedBox(
                            width: _padding / 2,
                          ),
                          FaIcon(FontAwesomeIcons.copy, size: _layerIconSize, color: Theme.of(context).primaryColorLight,),
                          const SizedBox(
                            width: _padding / 2,
                          ),
                          Expanded(
                            child: ValueListenableBuilder<bool>(
                              valueListenable: widget.timeline.isPlaying,
                              builder: (final BuildContext context, final bool isPlaying, final Widget? child) {
                                return SizedBox(
                                  height: _cellHeight,
                                  child: IconButton.outlined(
                                      onPressed: isPlaying ? null : () {widget.timeline.copyFrameRight();},
                                      icon: const FaIcon(FontAwesomeIcons.chevronRight, size: _transportIconSize),
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
                              return SizedBox(
                                height: _cellHeight,
                                child: IconButton.outlined(
                                    onPressed: isPlaying || frames.length <= 1 ? null : () { widget.timeline.deleteFrame(); },
                                    icon: const FaIcon(FontAwesomeIcons.trash, size: _transportIconSize),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const Spacer(),
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
                            child: LayoutBuilder(
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
