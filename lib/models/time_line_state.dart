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
  final ValueNotifier<int> _selectedFrameIndex = ValueNotifier<int>(-1);
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
    _selectedFrameIndex.addListener(() {
      _selectedFrame!.selectionChanged();
      _selectedFrame = frames.value[_selectedFrameIndex.value];
      _selectedFrame!.selectionChanged();
    },);
    _selectedFrameIndex.value = 0;
    loopStartIndex.value = 0;
    loopEndIndex.value = frames.value.length - 1;

    isPlaying.addListener(() {
      _playChanged();
    },);
  }

  int get selectedFrameIndex => _selectedFrameIndex.value;

  Frame? get selectedFrame => _selectedFrame;

  ValueNotifier<int> get selectedFrameIndexNotifier => _selectedFrameIndex;

  void selectFrame({required final int index, final int? layerIndex})
  {
    if (index >= 0 && index < frames.value.length)
    {
      final LayerState? oldLayer = _selectedFrame!.layerList.value.getSelectedLayer();
      _selectedFrameIndex.value = index;
      LayerState? layerToSelect;
      if (layerIndex != null)
      {
        layerToSelect = _selectedFrame!.layerList.value.getLayer(index: layerIndex);
      }
      else if (selectedFrame != null)
      {
        layerToSelect = _selectedFrame!.layerList.value.getSelectedLayer();

      }

      if (layerToSelect != null)
      {
        GetIt.I.get<AppState>().selectLayer(newLayer: layerToSelect, oldLayer: oldLayer);
      }

    }
  }

  void _playChanged()
  {
    if (isPlaying.value)
    {
      if (loopEndIndex.value - loopStartIndex.value > 0)
      {
        selectFrame(index: loopStartIndex.value);
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
    final int newIndex = selectedFrameIndex + 1;
    if (newIndex > loopEndIndex.value)
    {
      selectFrame(index: loopStartIndex.value);
    }
    else
    {
      selectFrame(index: newIndex);
    }
  }

  void selectPreviousFrame()
  {
    final int newIndex = selectedFrameIndex - 1;
    if (newIndex < 0)
    {
      selectFrame(index: frames.value.length - 1);
    }
    else
    {
      selectFrame(index: newIndex);
    }
  }

  void selectFirstFrame()
  {
    selectFrame(index: 0);
  }

  void selectLastFrame()
  {
    selectFrame(index: frames.value.length - 1);
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
    if (selectedFrameIndex > 0) {
      final List<Frame> newFrames = <Frame>[];
      newFrames.addAll(frames.value);
      final Frame f = newFrames[selectedFrameIndex];
      newFrames.removeAt(selectedFrameIndex);
      newFrames.insert(selectedFrameIndex - 1, f);
      frames.value = newFrames;
      selectFrame(index: selectedFrameIndex - 1);
    }
  }

  void moveFrameRight()
  {
    if (selectedFrameIndex < frames.value.length - 1)
    {
      final List<Frame> newFrames = <Frame>[];
      newFrames.addAll(frames.value);
      final Frame f = newFrames[selectedFrameIndex];
      newFrames.removeAt(selectedFrameIndex);
      newFrames.insert(selectedFrameIndex + 1, f);
      frames.value = newFrames;
      selectFrame(index: selectedFrameIndex + 1);
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
      final Frame cf = frames.value[selectedFrameIndex];
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
      newFrames.insert(selectedFrameIndex + 1, f);
    }
    else
    {
      newFrames.insert(selectedFrameIndex, f);
    }
    frames.value = newFrames;
    final int originalIndex = selectedFrameIndex;
    selectFrame(index: selectedFrameIndex + 1);
    if (!right)
    {
      selectFrame(index: selectedFrameIndex - 1);
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
    newFrames.removeAt(selectedFrameIndex);

    if (selectedFrameIndex <= loopStartIndex.value)
    {
      loopStartIndex.value = max(loopStartIndex.value - 1, 0);
    }
    if (selectedFrameIndex <= loopEndIndex.value)
    {
      loopEndIndex.value = max(loopEndIndex.value - 1, loopStartIndex.value);
    }

    if (selectedFrameIndex == 0)
    {
      selectFrame(index: 1);
      selectFrame(index: 0);
    }
    else
    {
      selectFrame(index: selectedFrameIndex - 1);
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
