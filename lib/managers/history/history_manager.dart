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

import 'dart:collection';
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
  final Queue<HistoryState> _states = Queue<HistoryState>();

  HistoryManager({required final int maxEntries}) : _maxEntries = maxEntries;

  void clear()
  {
    _curPos = -1;
    _states.clear();
    hasUndo.value = false;
    hasRedo.value = false;
  }

  String getCurrentDescription()
  {
    if (_curPos < 0 || _curPos >= _states.length) return '';
    return _states.elementAt(_curPos).type.description;
  }

  void changeMaxEntries({required final int maxEntries})
  {
    if (maxEntries < _maxEntries && _states.length > maxEntries)
    {
      _removeFutureEntries();
      final int deleteCount = _states.length - maxEntries;
      for (int i = 0; i < deleteCount; i++)
      {
        _states.removeFirst();
      }
      _curPos -= deleteCount;
      if (_curPos < 0)
      {
        _curPos = 0;
      }

    }
    _maxEntries = maxEntries;
    _updateNotifiers();
  }

  void _removeFutureEntries()
  {
    if (_curPos >= 0 && _curPos < _states.length - 1)
    {
      final int removeCount = _states.length - (_curPos + 1);
      for (int i = 0; i < removeCount; i++)
      {
        _states.removeLast();
      }
      _curPos = _states.length - 1;
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
        _states.add(HistoryState.fromAppState(appState: appState, identifier: identifier, originLayer: originLayer, previousState: identifier == HistoryStateTypeIdentifier.initial ? null : getCurrentState()));
        _curPos++;
        final int entriesLeft = _maxEntries - _states.length;

        if (entriesLeft < 0)
        {
          for (int i = 0; i < -entriesLeft; i++)
          {
            _states.removeFirst();
            _curPos--;
          }
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
       hState = _states.elementAt(_curPos);
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
      hState = _states.elementAt(_curPos);
      _updateNotifiers();
    }
    return hState;
  }

  HistoryState? getCurrentState()
  {
    if (_curPos >= 0 && _curPos < _states.length)
    {
      return _states.elementAt(_curPos);
    }
    else
    {
      return null;
    }
  }

  void _updateNotifiers()
  {
    hasUndo.value = _curPos > 0;
    hasRedo.value = _curPos < _states.length - 1;
  }

  void _compressHistory()
  {
    final int maxIndex = min(_curPos - 1, _states.length - 1 - _minEntries);
    if (maxIndex < 0) return;
    int index = 0;
    int deleteCount = 0;
    HistoryState? previousMergeState;
    final Queue<HistoryState> rebuilt = Queue<HistoryState>();

    for (final HistoryState state in _states)
    {
      if (index <= maxIndex)
      {
        if (state.type.isMergeCompression)
        {
          if (previousMergeState != null &&
              previousMergeState.type.identifier == state.type.identifier)
          {
            rebuilt.removeLast();
            deleteCount++;
          }
          previousMergeState = state;
          rebuilt.addLast(state);
        }
        else
        {
          previousMergeState = null;
          if (state.type.isDeleteCompression)
          {
            deleteCount++;
          }
          else
          {
            rebuilt.addLast(state);
          }
        }
      }
      else
      {
        rebuilt.addLast(state);
      }
      index++;
    }

    if (deleteCount > 0)
    {
      _states
        ..clear()
        ..addAll(rebuilt);
      _curPos -= deleteCount;
    }
  }
}
