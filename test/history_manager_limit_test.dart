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

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_state.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';

import 'support/selection_harness.dart';

HistoryManager get _history => GetIt.I.get<HistoryManager>();

void _test(final String description, final void Function() body, {final bool skip = false})
{
  testWidgets(description, (final WidgetTester tester) async
  {
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 2, y: 2), body: (final ProjectSession projectSession) async
    {
      _history.clear();
      body();
    },);
  }, skip: skip,);
}

void _addStates({required final int count})
{
  for (int i = 0; i < count; i++)
  {
    _history.addState(identifier: HistoryStateTypeIdentifier.generic);
  }
}

int _undoStepsLeft()
{
  int steps = 0;
  while (_history.undo() != null)
  {
    steps++;
  }
  return steps;
}

void main()
{
  group("lowering the undo steps", ()
  {
    _test("drops the oldest and stays on the current one", ()
    {
      _addStates(count: 6);
      final HistoryState? current = _history.getCurrentState();

      _history.changeMaxEntries(maxEntries: 3);

      expect(_history.getCurrentState(), same(current));
      expect(_history.hasUndo.value, isTrue);
      expect(_history.hasRedo.value, isFalse);
      expect(_undoStepsLeft(), 2);
    });

    _test("holds for what comes later", ()
    {
      _addStates(count: 2);
      _history.changeMaxEntries(maxEntries: 3);

      _addStates(count: 5);

      expect(_undoStepsLeft(), 2);
    });

    _test("leaves a history alone that still fits, including what can be redone", ()
    {
      _addStates(count: 3);
      _history.undo();

      _history.changeMaxEntries(maxEntries: 5);

      expect(_history.hasRedo.value, isTrue);
      expect(_history.redo(), isNotNull);
      expect(_undoStepsLeft(), 2);
    });

    _test("gives up what can be redone when there are too many", ()
    {
      _addStates(count: 6);
      _history.undo();
      final HistoryState? current = _history.getCurrentState();

      _history.changeMaxEntries(maxEntries: 3);

      expect(_history.getCurrentState(), same(current));
      expect(_history.hasRedo.value, isFalse);
      expect(_undoStepsLeft(), 2);
    });

    //BUG: changeMaxEntries drops the redo states first and then removes a negative count: RangeError
    _test("copes with a history that fits once the redo states are gone", skip: true, ()
    {
      _addStates(count: 6);
      for (int i = 0; i < 4; i++)
      {
        _history.undo();
      }
      final HistoryState? current = _history.getCurrentState();

      _history.changeMaxEntries(maxEntries: 3);

      expect(_history.getCurrentState(), same(current));
      expect(_history.hasRedo.value, isFalse);
      expect(_undoStepsLeft(), 1);
    });
  });

  group("raising the undo steps", ()
  {
    _test("keeps everything and leaves room for more", ()
    {
      _history.changeMaxEntries(maxEntries: 3);
      _addStates(count: 5);

      _history.changeMaxEntries(maxEntries: 6);
      _addStates(count: 2);

      expect(_undoStepsLeft(), 4);
    });
  });
}
