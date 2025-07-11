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
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/dither_layer/dither_layer_state.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/grid_layer/grid_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/models/app_state.dart';

class Frame with ChangeNotifier
{
  final ValueNotifier<int> fps = ValueNotifier<int>(0);
  final ValueNotifier<List<LayerState>> layerList = ValueNotifier<List<LayerState>>(<LayerState>[]);
  final ValueNotifier<int> selectedLayerIndex = ValueNotifier<int>(0);

  int get frameTime => (1000.0 / fps.value.toDouble()).toInt();

  void selectionChanged()
  {
    notifyListeners();
  }
}

class Timeline
{
  Frame? _selectedFrame;
  final ValueNotifier<int> selectedFrameIndex = ValueNotifier<int>(0);
  final ValueNotifier<List<Frame>> frames = ValueNotifier<List<Frame>>(<Frame>[]);
  final ValueNotifier<int> totalFrameTime = ValueNotifier<int>(0);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<int> loopStartIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> loopEndIndex = ValueNotifier<int>(0);
  final AppState _appState = GetIt.I.get<AppState>();

  Timeline()
  {
    //TODO TEMP
    final List<Frame> frameList = [];
    final Random rand = Random();
    for (int i = 0; i < 1; i++)
    {
      final Frame f = Frame();
      final int layerCount = rand.nextInt(13) + 1;
      for (int j = 0; j < layerCount; j++)
      {
        final int layerRand = rand.nextInt(4);
        final LayerState ls = layerRand == 0 ? ShadingLayerState() : DrawingLayerState(size: _appState.canvasSize, ramps: _appState.colorRamps);
        f.layerList.value.add(ls);
      }
      f.fps.value = rand.nextInt(60) + 1;
      f.selectedLayerIndex.value = rand.nextInt(f.layerList.value.length);
      f.fps.addListener(() => calculateTotalFrameTime());
      frameList.add(f);
    }
    _selectedFrame = frameList[0];
    frames.value = frameList;
    calculateTotalFrameTime();
    selectedFrameIndex.addListener(() {
      _selectedFrame?.selectionChanged();
      _selectedFrame = frames.value[selectedFrameIndex.value];
      _selectedFrame?.selectionChanged();
    },);
    loopStartIndex.value = 0;
    loopEndIndex.value = frames.value.length - 1;

    isPlaying.addListener(() {
      _playChanged();
    },);

  }

  void _playChanged()
  {
    if (isPlaying.value)
    {
      if (loopEndIndex.value - loopStartIndex.value > 0)
      {
        selectedFrameIndex.value = loopStartIndex.value;
        _play();
      }
      else
      {
        isPlaying.value = false;
      }

    }
  }

  void selectNextFrame()
  {
    final int newIndex = selectedFrameIndex.value + 1;
    if (newIndex > loopEndIndex.value)
    {
      selectedFrameIndex.value = loopStartIndex.value;
    }
    else
    {
      selectedFrameIndex.value = newIndex;
    }
  }

  void selectPreviousFrame()
  {
    final int newIndex = selectedFrameIndex.value - 1;
    if (newIndex < 0)
    {
      selectedFrameIndex.value = frames.value.length - 1;
    }
    else
    {
      selectedFrameIndex.value = newIndex;
    }
  }

  void selectFirstFrame()
  {
    selectedFrameIndex.value = 0;
  }

  void selectLastFrame()
  {
    selectedFrameIndex.value = frames.value.length - 1;
  }

  Future<void> _play() async
  {
    while(isPlaying.value)
    {
      await Future.delayed(Duration(milliseconds: _selectedFrame!.frameTime));
      if (isPlaying.value)
      {
        selectNextFrame();
      }
    }
  }

  void moveFrameLeft() {
    if (selectedFrameIndex.value > 0) {
      final List<Frame> newFrames = [];
      newFrames.addAll(frames.value);
      final Frame f = newFrames[selectedFrameIndex.value];
      newFrames.removeAt(selectedFrameIndex.value);
      newFrames.insert(selectedFrameIndex.value - 1, f);
      frames.value = newFrames;
      selectedFrameIndex.value--;
    }
  }

  void moveFrameRight()
  {
    if (selectedFrameIndex.value < frames.value.length - 1)
    {
      final List<Frame> newFrames = [];
      newFrames.addAll(frames.value);
      final Frame f = newFrames[selectedFrameIndex.value];
      newFrames.removeAt(selectedFrameIndex.value);
      newFrames.insert(selectedFrameIndex.value + 1, f);
      frames.value = newFrames;
      selectedFrameIndex.value++;
    }
  }

  void addNewFrameLeft()
  {
    _addNewFrame(right: false, copy: false);
  }

  void addNewFrameRight()
  {
    _addNewFrame(right: true, copy: false);
  }

  void copyFrameLeft()
  {
    _addNewFrame(right: false, copy: true);
  }

  void copyFrameRight()
  {
    _addNewFrame(right: true, copy: true);
  }

  void _addNewFrame({required final bool right, required final bool copy})
  {
    final Frame f = Frame();
    if (copy)
    {
      final Frame cf = frames.value[selectedFrameIndex.value];
      for (final LayerState l in cf.layerList.value)
      {
        if (l.runtimeType == DrawingLayerState)
        {
          f.layerList.value.add(DrawingLayerState.from(other: l as DrawingLayerState));
        }
        else if (l.runtimeType == GridLayerState)
        {
          f.layerList.value.add(GridLayerState.from(other: l as GridLayerState));
        }
        else if (l.runtimeType == ShadingLayerState)
        {
          f.layerList.value.add(ShadingLayerState.from(other: l as ShadingLayerState));
        }
        else if (l.runtimeType == DitherLayerState)
        {
          f.layerList.value.add(DitherLayerState.from(other: l as DitherLayerState));
        }
        else if (l.runtimeType == ReferenceLayerState)
        {
          f.layerList.value.add(ReferenceLayerState.from(other: l as ReferenceLayerState));
        }
      }
      f.fps.value = cf.fps.value;
      f.fps.addListener(() => calculateTotalFrameTime());
      f.selectedLayerIndex.value = cf.selectedLayerIndex.value;
    }
    else
    {
      f.layerList.value.add(DrawingLayerState(size: _appState.canvasSize, ramps: _appState.colorRamps));
      f.fps.value = 20;
      f.fps.addListener(() => calculateTotalFrameTime());
    }
    final List<Frame> newFrames = [];
    newFrames.addAll(frames.value);
    if (right)
    {
      newFrames.insert(selectedFrameIndex.value + 1, f);
    }
    else
    {
      newFrames.insert(selectedFrameIndex.value, f);
    }
    frames.value = newFrames;
    final int originalIndex = selectedFrameIndex.value;
    selectedFrameIndex.value++;
    if (!right)
    {
      selectedFrameIndex.value--;
    }

    if (originalIndex <= loopEndIndex.value)
    {
      loopEndIndex.value++;

    }

    if (originalIndex < loopStartIndex.value)
    {
      loopStartIndex.value++;
    }

  }

  void deleteFrame()
  {
    final List<Frame> newFrames = [];
    newFrames.addAll(frames.value);
    newFrames.removeAt(selectedFrameIndex.value);

    if (selectedFrameIndex.value <= loopStartIndex.value)
    {
      loopStartIndex.value = max(loopStartIndex.value - 1, 0);
    }
    if (selectedFrameIndex.value <= loopEndIndex.value)
    {
      loopEndIndex.value = max(loopEndIndex.value - 1, loopStartIndex.value);
    }

    if (selectedFrameIndex.value == 0)
    {
      selectedFrameIndex.value = 1;
      selectedFrameIndex.value = 0;
    }
    else
    {
      selectedFrameIndex.value--;
    }

    frames.value = newFrames;

  }

  void resetStartMarker()
  {
    loopStartIndex.value = 0;
  }

  void resetEndMarker()
  {
    loopEndIndex.value = frames.value.length - 1;
  }


  void calculateTotalFrameTime()
  {
    int totalTime = 0;
    for (final Frame f in frames.value)
    {
      totalTime += f.frameTime;
    }
    totalFrameTime.value = totalTime;
  }
}