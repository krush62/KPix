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
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';

class FrameConstraints
{
  final int minFps;
  final int maxFps;
  final int defaultFps;
  const FrameConstraints({required this.minFps, required this.maxFps, required this.defaultFps});
}

class Frame
{
  final ValueNotifier<int> fps;
  final LayerCollection layerList;

  int get frameTime => (1000.0 / fps.value.toDouble()).toInt();

  Frame({required this.layerList, required final int fps}) : fps = ValueNotifier<int>(fps);

  Frame.empty({required final int fps}) : layerList = LayerCollection.empty(), fps = ValueNotifier<int>(fps);
}

class LayerChangeNotifier with ChangeNotifier
{
  void reportChange()
  {
    notifyListeners();
  }
}

class Timeline
{
  static const int maxFrames = 256;
  final ValueNotifier<int> _selectedFrameIndex;
  final ValueNotifier<List<Frame>> frames;
  final ValueNotifier<bool> isPlaying;
  final ValueNotifier<int> loopStartIndex;
  final ValueNotifier<int> loopEndIndex;
  final LayerChangeNotifier layerChangeNotifier = LayerChangeNotifier();

  Timeline({required final int selectedFrameIndex, required final List<Frame> frames, required final int loopStartIndex, required final int loopEndIndex})
  : frames = ValueNotifier<List<Frame>>(frames),
    _selectedFrameIndex = ValueNotifier<int>(selectedFrameIndex),
    loopStartIndex = ValueNotifier<int>(loopStartIndex),
    loopEndIndex = ValueNotifier<int>(loopEndIndex),
    isPlaying = ValueNotifier<bool>(false)
  {
    isPlaying.addListener(() {
      _playChanged();
    },);
  }

  Timeline.empty()
  : frames = ValueNotifier<List<Frame>>(<Frame>[]),
    _selectedFrameIndex = ValueNotifier<int>(-1),
    loopStartIndex = ValueNotifier<int>(-1),
    loopEndIndex = ValueNotifier<int>(-1),
    isPlaying = ValueNotifier<bool>(false)
  {
    isPlaying.addListener(() {
      _playChanged();
    },);
  }

  void setData({required final int selectedFrameIndex, required final List<Frame> frames, required final int loopStartIndex, required final int loopEndIndex})
  {
    this.frames.value = frames;
    this.loopStartIndex.value = loopStartIndex;
    this.loopEndIndex.value = loopEndIndex;
    _selectedFrameIndex.value = selectedFrameIndex;
  }

  void init({required final AppState appState})
  {
    final FrameConstraints constraints = GetIt.I.get<PreferenceManager>().frameConstraints;
    final List<Frame> frameList = <Frame>[];
    final Frame f = Frame.empty(fps: constraints.defaultFps);
    f.layerList.addNewDrawingLayer(canvasSize: appState.canvasSize, ramps: appState.colorRamps);
    f.fps.value = constraints.defaultFps;
    frameList.add(f);
    frames.value = frameList;
    loopStartIndex.value = 0;
    loopEndIndex.value = frames.value.length - 1;
    selectFrame(index: 0);
  }

  int get selectedFrameIndex => _selectedFrameIndex.value;

  Frame? get selectedFrame
  {
    if (_selectedFrameIndex.value >= 0 && _selectedFrameIndex.value < frames.value.length)
    {
      return frames.value[_selectedFrameIndex.value];
    }
    else
    {
      return null;
    }
  }

  ValueNotifier<int> get selectedFrameIndexNotifier => _selectedFrameIndex;

  LayerState? getCurrentLayer()
  {
    return selectedFrame?.layerList.currentLayer;
  }

  void selectFrame({required final int index, final int? layerIndex})
  {
    if (index >= 0 && index < frames.value.length)
    {
      final LayerState? oldLayer = selectedFrame?.layerList.getSelectedLayer();
      _selectedFrameIndex.value = index;
      LayerState? layerToSelect;
      if (layerIndex != null)
      {
        layerToSelect = frames.value[index].layerList.getLayer(index: layerIndex);
      }
      else
      {
        layerToSelect = frames.value[index].layerList.getSelectedLayer();

      }

      if (layerToSelect != null)
      {
        GetIt.I.get<AppState>().selectLayer(newLayer: layerToSelect, oldLayer: oldLayer);
      }
    }
  }

  void togglePlaying()
  {
    if (loopStartIndex.value != loopEndIndex.value || isPlaying.value)
    {
      isPlaying.value = !isPlaying.value;
    }
  }


  void _playChanged()
  {
    if (isPlaying.value)
    {
      if (loopEndIndex.value != loopStartIndex.value)
      {
        _play(startIndex: loopStartIndex.value);
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

  Future<void> _play({required final int startIndex}) async
  {
    if (selectedFrame != null)
    {
      while(isPlaying.value)
      {
        await Future<void>.delayed(Duration(milliseconds: selectedFrame!.frameTime));
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
      GetIt.I.get<AppState>().frameMoved();
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
      GetIt.I.get<AppState>().frameMoved();
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
    final AppState appState = GetIt.I.get<AppState>();
    if (frames.value.length >= maxFrames)
    {
      appState.showMessage(text: "Cannot add more frames.");
      return;
    }
    else
    {
      final FrameConstraints constraints = GetIt.I.get<PreferenceManager>().frameConstraints;
      final Frame f = Frame.empty(fps: constraints.defaultFps);
      if (copy)
      {
        final Frame cf = frames.value[selectedFrameIndex];
        LayerState? layerToSelect;
        for (int i = 0; i < cf.layerList.length; i++)
        {
          final LayerState l = cf.layerList.getLayer(index: i);
          final LayerState? addedLayer = f.layerList.duplicateLayer(duplicateLayer: l, insertAtEnd: true);
          if (l.isSelected.value)
          {
            layerToSelect = addedLayer;
          }
        }

        if (layerToSelect != null)
        {
          f.layerList.selectLayer(newLayer: layerToSelect);
        }
        else
        {
          f.layerList.selectLayer(newLayer: f.layerList.getLayer(index: 0));
        }


        f.fps.value = cf.fps.value;
      }
      else
      {
        f.layerList.addNewDrawingLayer(canvasSize: appState.canvasSize, ramps: appState.colorRamps);
        f.fps.value = constraints.defaultFps;
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
      GetIt.I.get<AppState>().newFrameAdded();
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

    GetIt.I.get<AppState>().frameDeleted();
  }

  void resetStartMarker()
  {
    if (loopStartIndex.value != 0)
    {
      loopStartIndex.value = 0;
      GetIt.I.get<AppState>().loopMarkerChanged();
    }
  }

  void resetEndMarker()
  {
    final int lastPosition = frames.value.length - 1;
    if (loopEndIndex.value != lastPosition)
    {
      loopEndIndex.value = frames.value.length - 1;
      GetIt.I.get<AppState>().loopMarkerChanged();
    }
  }

  void setLoopStartMarker({required final int index})
  {
    if (index >= 0 && index < frames.value.length)
    {
      loopStartIndex.value = index;
      GetIt.I.get<AppState>().loopMarkerChanged();
    }
  }

  void setLoopEndMarker({required final int index})
  {
    if (index >= 0 && index < frames.value.length)
    {
      loopEndIndex.value = index;
      GetIt.I.get<AppState>().loopMarkerChanged();
    }
  }

  void setFrameTimingSingle({required final Frame frame, required final int fps})
  {
    final FrameConstraints constraints = GetIt.I.get<PreferenceManager>().frameConstraints;
    if (frame.fps.value != fps && fps >= constraints.minFps && fps <= constraints.maxFps)
    {
      frame.fps.value = fps;
      GetIt.I.get<AppState>().frameTimingChanged();
    }
  }

  void setFrameTimingAll({required final int fps})
  {
    final FrameConstraints constraints = GetIt.I.get<PreferenceManager>().frameConstraints;
    if (fps >= constraints.minFps && fps <= constraints.maxFps)
    {
      bool hasChanges = false;
      for (final Frame f in frames.value)
      {
        if (f.fps.value != fps)
        {
          f.fps.value = fps;
          hasChanges = true;
        }
      }
      if (hasChanges)
      {
        GetIt.I.get<AppState>().frameTimingChanged();
      }
    }
  }

  Frame? getFrameForLayer({required final LayerState layer})
  {
    for (final Frame f in frames.value)
    {
      if (f.layerList.contains(layer: layer))
      {
        return f;
      }
    }
    return null;
  }

  List<LayerCollection> findCollectionsForLayer({required final LayerState? layer})
  {
    final List<LayerCollection> list = <LayerCollection>[];
    if (layer != null)
    {
      for (final Frame f in frames.value)
      {
        if (f.layerList.contains(layer: layer))
        {
          list.add(f.layerList);
          break;
        }
      }
    }
    return list;
  }


  int calculateTotalFrameTime({required final bool sectionOnly})
  {
    int totalTime = 0;
    int index = 0;
    for (final Frame f in frames.value)
    {
      if (!sectionOnly || index >= loopStartIndex.value && index <= loopEndIndex.value)
      {
        totalTime += f.frameTime;
      }
      index++;
    }
    return totalTime;
  }
}
