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
import 'package:kpix/layer_states/layer_collection.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/app_state.dart';

class Frame with ChangeNotifier
{
  static const int defaultFps = 20;
  final ValueNotifier<int> fps = ValueNotifier<int>(0);
  final ValueNotifier<LayerCollection> layerList = ValueNotifier<LayerCollection>(LayerCollection());

  int get frameTime => (1000.0 / fps.value.toDouble()).toInt();

  void selectionChanged()
  {
    notifyListeners();
  }
}

class Timeline
{
  Frame? _selectedFrame;
  final ValueNotifier<int> selectedFrameIndex = ValueNotifier<int>(-1);
  final ValueNotifier<List<Frame>> frames = ValueNotifier<List<Frame>>(<Frame>[]);
  final ValueNotifier<int> totalFrameTime = ValueNotifier<int>(0);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<int> loopStartIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> loopEndIndex = ValueNotifier<int>(0);


  void init({required final AppState appState})
  {
    final List<Frame> frameList = <Frame>[];
    final Frame f = Frame();
    f.layerList.value.addNewDrawingLayer(canvasSize: appState.canvasSize, ramps: appState.colorRamps);
    f.fps.value = Frame.defaultFps;
    f.fps.addListener(() => calculateTotalFrameTime());
    frameList.add(f);

    _selectedFrame = frameList[0];
    frames.value = frameList;
    calculateTotalFrameTime();
    selectedFrameIndex.addListener(() {
      _selectedFrame!.selectionChanged();
      _selectedFrame = frames.value[selectedFrameIndex.value];
      _selectedFrame!.selectionChanged();
    },);
    selectedFrameIndex.value = 0;
    loopStartIndex.value = 0;
    loopEndIndex.value = frames.value.length - 1;

    isPlaying.addListener(() {
      _playChanged();
    },);
  }

  Frame? get selectedFrame => _selectedFrame;

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
    if (_selectedFrame != null)
    {
      while(isPlaying.value)
      {
        await Future<void>.delayed(Duration(milliseconds: _selectedFrame!.frameTime));
        if (isPlaying.value)
        {
          selectNextFrame();
        }
      }
    }
  }

  void moveFrameLeft() {
    if (selectedFrameIndex.value > 0) {
      final List<Frame> newFrames = <Frame>[];
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
      final List<Frame> newFrames = <Frame>[];
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
    final AppState appState = GetIt.I.get<AppState>();

    if (copy)
    {
      final Frame cf = frames.value[selectedFrameIndex.value];
      LayerState? layerToSelect;
      for (int i = 0; i < cf.layerList.value.length; i++)
      {
        final LayerState l = cf.layerList.value.getLayer(index: i);
        final LayerState? addedLayer = f.layerList.value.duplicateLayer(duplicateLayer: l, insertAtEnd: true);
        if (l.isSelected.value)
        {
          layerToSelect = addedLayer;
        }
      }

      if (layerToSelect != null)
      {
        f.layerList.value.selectLayer(newLayer: layerToSelect);
      }
      else
      {
        f.layerList.value.selectLayer(newLayer: f.layerList.value.getLayer(index: 0));
      }


      f.fps.value = cf.fps.value;
      f.fps.addListener(() => calculateTotalFrameTime());
    }
    else
    {
      f.layerList.value.addNewDrawingLayer(canvasSize: appState.canvasSize, ramps: appState.colorRamps);
      f.fps.value = Frame.defaultFps;
      f.fps.addListener(() => calculateTotalFrameTime());
    }
    final List<Frame> newFrames = <Frame>[];
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
    final List<Frame> newFrames = <Frame>[];
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
