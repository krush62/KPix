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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_ramp_data.dart';

/// A layer that only records that it was polled, so the scheduling can be
/// exercised without the service locator the real layer types need.
class _PollLayer extends LayerState
{
  bool pending = false;
  int polls = 0;

  @override
  bool get hasPendingRaster => pending;

  @override
  void pollRaster()
  {
    polls++;
  }

  @override
  IconData get icon => Icons.circle;

  @override
  LayerMenuKind get menuKind => LayerMenuKind.raster;

  @override
  void dispose()
  {
    markDisposed();
    stopRasterPolling();
    settleRaster();
  }

  @override
  LayerState copy({final List<RasterableLayerState>? layerStack}) => _PollLayer();

  @override
  HistoryLayer toHistoryLayer({required final List<HistoryRampData> ramps, final HistoryLayer? previousLayer})
  {
    throw UnimplementedError("not needed for scheduling tests");
  }

  void join({required final RasterScheduler scheduler}) => startRasterPolling(scheduler: scheduler);
  void request() => requestRaster();
}

/// Long enough to cross several poll intervals.
const Duration _severalTicks = Duration(milliseconds: 200);

void main()
{
  group('RasterScheduler', () {
    late RasterScheduler scheduler;

    setUp(() {
      scheduler = RasterScheduler();
    });

    testWidgets('registering alone starts no timer', (final WidgetTester tester) async {
      final _PollLayer layer = _PollLayer()..join(scheduler: scheduler);
      expect(scheduler.registeredLayerCount, 1);
      //an idle project must not tick at all
      expect(scheduler.activeTimerCount, 0);
      layer.dispose();
    });

    testWidgets('requesting a raster starts polling', (final WidgetTester tester) async {
      final _PollLayer layer = _PollLayer()..join(scheduler: scheduler);
      layer.pending = true;
      layer.request();
      expect(scheduler.activeTimerCount, 1);

      await tester.pump(_severalTicks);
      expect(layer.polls, greaterThan(1));

      //let it wind down so the test does not end with a live timer
      layer.pending = false;
      await tester.pump(_severalTicks);
      expect(scheduler.activeTimerCount, 0);
      layer.dispose();
    });

    testWidgets('polling stops as soon as nothing is pending', (final WidgetTester tester) async {
      final _PollLayer layer = _PollLayer()..join(scheduler: scheduler);
      //work requested but already satisfied by the time the first tick lands
      layer.request();
      expect(scheduler.activeTimerCount, 1);

      await tester.pump(_severalTicks);
      expect(scheduler.activeTimerCount, 0);
      //exactly one poll: the tick that found nothing to do and stopped
      expect(layer.polls, 1);
      layer.dispose();
    });

    testWidgets('a single timer serves every registered layer', (final WidgetTester tester) async {
      final List<_PollLayer> layers = List<_PollLayer>.generate(
        5,
        (final int _) => _PollLayer()..join(scheduler: scheduler),
      );
      //only one layer has work, but the loop runs for all of them
      layers.first.pending = true;
      layers.first.request();
      expect(scheduler.activeTimerCount, 1);

      await tester.pump(_severalTicks);
      for (final _PollLayer layer in layers) {
        expect(layer.polls, greaterThan(1), reason: 'every registered layer is polled');
      }

      layers.first.pending = false;
      await tester.pump(_severalTicks);
      expect(scheduler.activeTimerCount, 0);
      for (final _PollLayer layer in layers) {
        layer.dispose();
      }
    });

    testWidgets('work arriving later wakes polling again', (final WidgetTester tester) async {
      final _PollLayer layer = _PollLayer()..join(scheduler: scheduler);
      layer.request();
      await tester.pump(_severalTicks);
      expect(scheduler.activeTimerCount, 0);
      final int quiet = layer.polls;

      //this is the path every queue write goes through
      layer.pending = true;
      layer.request();
      expect(scheduler.activeTimerCount, 1);
      await tester.pump(_severalTicks);
      expect(layer.polls, greaterThan(quiet));

      layer.pending = false;
      await tester.pump(_severalTicks);
      layer.dispose();
    });

    testWidgets('disposing the last layer stops the timer', (final WidgetTester tester) async {
      final _PollLayer layer = _PollLayer()..join(scheduler: scheduler);
      layer.pending = true;
      layer.request();
      expect(scheduler.activeTimerCount, 1);

      layer.dispose();
      expect(scheduler.registeredLayerCount, 0);
      expect(scheduler.activeTimerCount, 0);
    });

    testWidgets('a disposed layer is no longer polled', (final WidgetTester tester) async {
      final _PollLayer kept = _PollLayer()..join(scheduler: scheduler);
      final _PollLayer dropped = _PollLayer()..join(scheduler: scheduler);
      kept.pending = true;
      kept.request();

      await tester.pump(_severalTicks);
      dropped.dispose();
      final int frozen = dropped.polls;

      await tester.pump(_severalTicks);
      expect(dropped.polls, frozen, reason: 'a disposed layer must drop out of the loop');
      expect(kept.polls, greaterThan(frozen));

      kept.pending = false;
      await tester.pump(_severalTicks);
      kept.dispose();
    });
  });
}
