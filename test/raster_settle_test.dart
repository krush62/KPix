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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/models/history/history_layer.dart';
import 'package:kpix/models/history/history_ramp_data.dart';

/// The smallest possible layer, so the settling logic can be exercised without
/// the service locator that the real layer types need.
class _FakeLayer extends LayerState
{
  bool pending = false;

  @override
  bool get hasPendingRaster => pending;

  @override
  IconData get icon => Icons.circle;

  @override
  LayerMenuKind get menuKind => LayerMenuKind.raster;

  @override
  void dispose()
  {
    markDisposed();
    settleRaster();
  }

  @override
  LayerState copy({final List<RasterableLayerState>? layerStack}) => _FakeLayer();

  @override
  HistoryLayer toHistoryLayer({required final List<HistoryRampData> ramps, final HistoryLayer? previousLayer})
  {
    throw UnimplementedError("not needed for settling tests");
  }

  void request() => requestRaster();
  void settle() => settleRaster();
}

/// Whether [future] has resolved by the time the event loop next drains.
Future<bool> _hasResolved(final Future<void> future) async
{
  bool resolved = false;
  future.then((final void _) {resolved = true;}).ignore();
  await Future<void>.delayed(Duration.zero);
  return resolved;
}

void main()
{
  test("an idle layer is already settled", () async {
    final _FakeLayer layer = _FakeLayer();

    //awaiting an idle layer has to be free, otherwise every caller would need to
    //know whether a raster was ever requested
    expect(await _hasResolved(layer.rasterizationComplete), isTrue);
  });

  test("a waiter registered before the raster runs still resolves", () async {
    final _FakeLayer layer = _FakeLayer();

    //this is the case the old code slept 150ms to paper over: the request is in,
    //but the work has not started yet
    layer.request();
    final Future<void> waiter = layer.rasterizationComplete;
    expect(await _hasResolved(waiter), isFalse);

    layer.settle();
    expect(await _hasResolved(waiter), isTrue);
  });

  test("settling does not release while more work is queued", () async {
    final _FakeLayer layer = _FakeLayer();

    layer.request();
    final Future<void> waiter = layer.rasterizationComplete;

    //a second request arrived while the first raster was running
    layer.pending = true;
    layer.settle();
    expect(await _hasResolved(waiter), isFalse);

    layer.pending = false;
    layer.settle();
    expect(await _hasResolved(waiter), isTrue);
  });

  test("disposal releases waiters even with work still queued", () async {
    final _FakeLayer layer = _FakeLayer();

    layer.request();
    layer.pending = true;
    final Future<void> waiter = layer.rasterizationComplete;
    expect(await _hasResolved(waiter), isFalse);

    //a disposed layer will never raster again, so parking a caller for good would
    //be the hang this whole mechanism exists to remove
    layer.dispose();
    expect(await _hasResolved(waiter), isTrue);
  });

  test("settling twice is harmless", () async {
    final _FakeLayer layer = _FakeLayer();

    layer.request();
    layer.settle();
    layer.settle();

    expect(await _hasResolved(layer.rasterizationComplete), isTrue);
  });

  test("a fresh request after settling parks callers again", () async {
    final _FakeLayer layer = _FakeLayer();

    layer.request();
    layer.settle();
    expect(await _hasResolved(layer.rasterizationComplete), isTrue);

    layer.request();
    expect(await _hasResolved(layer.rasterizationComplete), isFalse);

    layer.settle();
    expect(await _hasResolved(layer.rasterizationComplete), isTrue);
  });
}
