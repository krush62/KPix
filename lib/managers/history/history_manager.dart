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

import 'package:flutter/material.dart';
import 'package:kpix/managers/history/history_state.dart';
import 'package:kpix/models/app_state.dart';


class HistoryManager
{
  final ValueNotifier<bool> hasUndo = ValueNotifier(false);
  final ValueNotifier<bool> hasRedo = ValueNotifier(false);
  int _maxEntries;
  int _curPos = -1;
  final Queue<HistoryState> _states = Queue();

  HistoryManager({required int maxEntries}) : _maxEntries = maxEntries;

  void clear()
  {
    _curPos = -1;
    _states.clear();
    hasUndo.value = false;
    hasRedo.value = false;
  }

  String getCurrentDescription()
  {
    return _states.elementAt(_curPos).description;
  }

  void changeMaxEntries({required int maxEntries})
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

  void addState({required final AppState appState, required final String description, final setHasChanges = true})
  {
    _removeFutureEntries();
    _states.add(HistoryState.fromAppState(appState: appState, description: description));
    _curPos++;
    final int entriesLeft = (_maxEntries - _states.length);

    if (entriesLeft < 0)
    {
      for (int i = 0; i < -entriesLeft; i++)
      {
        _states.removeFirst();
        _curPos--;
      }
    }
    _updateNotifiers();
    appState.hasChanges.value = setHasChanges;
  }


  HistoryState? undo()
  {
    HistoryState? hState;
    if (_curPos > 0)
    {
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
      _curPos++;
      hState = _states.elementAt(_curPos);
      _updateNotifiers();
    }
    return hState;
  }

  void _updateNotifiers()
  {
    hasUndo.value = (_curPos > 0);
    hasRedo.value = (_curPos < _states.length - 1);
  }
}
