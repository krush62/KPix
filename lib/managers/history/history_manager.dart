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

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:logger/logger.dart';


class HistoryManager
{
  final ValueNotifier<bool> hasUndo = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasRedo = ValueNotifier<bool>(false);
  final int _minEntries = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent.undoStepsMin;
  int _maxEntries;
  int _curPos = -1;

  final List<HistoryState> _states = <HistoryState>[];
  int _lastCompressedIndex = -1;

  HistoryManager({required final int maxEntries}) : _maxEntries = maxEntries;

  void clear()
  {
    _curPos = -1;
    _lastCompressedIndex = -1;
    _states.clear();
    hasUndo.value = false;
    hasRedo.value = false;
  }

  String getCurrentDescription()
  {
    if (_curPos < 0 || _curPos >= _states.length) return '';
    return _states[_curPos].type.description;
  }

  void changeMaxEntries({required final int maxEntries})
  {
    if (maxEntries < _maxEntries && _states.length > maxEntries)
    {
      _removeFutureEntries();
      final int deleteCount = _states.length - maxEntries;

      _states.removeRange(0, deleteCount);
      _curPos -= deleteCount;
      if (_curPos < 0) _curPos = 0;

      _lastCompressedIndex = (_lastCompressedIndex - deleteCount).clamp(-1, _states.length - 1);
    }
    _maxEntries = maxEntries;
    _updateNotifiers();
  }

  void _removeFutureEntries()
  {
    if (_curPos >= 0 && _curPos < _states.length - 1)
    {
      _states.removeRange(_curPos + 1, _states.length);
    }
  }

  void addState({required final AppState appState, required final HistoryStateTypeIdentifier identifier, final bool setHasChanges = true, final LayerState? originLayer})
  {
    if (!appState.timeline.isPlaying.value)
    {
      GetIt.I.get<Logger>().i("Adding history state: $identifier.");
      try
      {
        _removeFutureEntries();
        _states.add(HistoryState.fromAppState(
          appState: appState,
          identifier: identifier,
          originLayer: originLayer,
          previousState: identifier == HistoryStateTypeIdentifier.initial ? null : getCurrentState(),
        ));
        _curPos++;

        final int excess = _states.length - _maxEntries;
        if (excess > 0)
        {
          _states.removeRange(0, excess);
          _curPos -= excess;

          _lastCompressedIndex = (_lastCompressedIndex - excess).clamp(-1, _states.length - 1);
        }

        _compressHistory();
        _updateNotifiers();
      }
      catch (e, s)
      {
        GetIt.I.get<Logger>().e("Error adding history state: $identifier.", error: e, stackTrace: s);
      }
    }
    appState.hasChanges.value = setHasChanges;
  }

  HistoryState? undo()
  {
    HistoryState? hState;
    if (_curPos > 0)
    {
      GetIt.I.get<Logger>().i("Performing undo.");
      _curPos--;
      hState = _states[_curPos];
      _updateNotifiers();
    }
    return hState;
  }

  HistoryState? redo()
  {
    HistoryState? hState;
    if (_curPos < _states.length - 1)
    {
      GetIt.I.get<Logger>().i("Performing redo.");
      _curPos++;
      hState = _states[_curPos];
      _updateNotifiers();
    }
    return hState;
  }

  HistoryState? getCurrentState()
  {
    if (_curPos >= 0 && _curPos < _states.length)
    {
      return _states[_curPos];
    }
    return null;
  }

  void _updateNotifiers()
  {
    hasUndo.value = _curPos > 0;
    hasRedo.value = _curPos < _states.length - 1;
  }

  void _compressHistory()
  {
    final int maxIndex = min(_curPos - 1, _states.length - 1 - _minEntries);
    if (maxIndex < 0 || maxIndex <= _lastCompressedIndex) return;

    final int scanFrom = _lastCompressedIndex + 1;

    HistoryState? previousMergeState;
    int?          previousMergeStateIndex;
    if (scanFrom > 0)
    {
      final HistoryState boundary = _states[scanFrom - 1];
      if (boundary.type.isMergeCompression)
      {
        previousMergeState      = boundary;
        previousMergeStateIndex = scanFrom - 1;
      }
    }

    int localMax = maxIndex;
    int i        = scanFrom;

    while (i <= localMax)
    {
      final HistoryState state = _states[i];

      if (state.type.isMergeCompression)
      {
        if (previousMergeState != null &&
            previousMergeState.type.identifier == state.type.identifier)
        {
          final int removeIdx = previousMergeStateIndex!;
          _states.removeAt(removeIdx);

          i--;
          localMax--;
          _curPos--;

          if (removeIdx <= _lastCompressedIndex) _lastCompressedIndex--;
        }
        previousMergeState      = state;
        previousMergeStateIndex = i;
        i++;
      }
      else
      {
        previousMergeState      = null;
        previousMergeStateIndex = null;

        if (state.type.isDeleteCompression)
        {
          _states.removeAt(i);
          localMax--;
          _curPos--;
          if (i <= _lastCompressedIndex) _lastCompressedIndex--;
        }
        else
        {
          i++;
        }
      }
    }

    _lastCompressedIndex = localMax;
  }
}
