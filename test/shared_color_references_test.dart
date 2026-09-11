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
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/history/history_color_reference.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/history/history_ramp_data.dart';
import 'package:kpix/models/history/history_state_type.dart';
import 'package:kpix/models/history/ramp_resolver.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/util/typedefs.dart';

import 'support/selection_harness.dart';

/// Pixel data refers to palette colors through reference objects, one per
/// pixel. These tests pin down that equal colors share one object instead of
/// each pixel allocating its own, both in history snapshots and in layers
/// rebuilt from them.
void main()
{
  group("HistoryColorReference.of", ()
  {
    test("hands out one instance per color", ()
    {
      final HistoryColorReference first = HistoryColorReference.of(colorIndex: 3, rampIndex: 5);
      expect(HistoryColorReference.of(colorIndex: 3, rampIndex: 5), same(first));
      expect(first, const HistoryColorReference(colorIndex: 3, rampIndex: 5),
          reason: "a shared instance must still equal a freshly constructed one",);
    });

    test("keeps every color of the largest palette apart", ()
    {
      final Set<HistoryColorReference> seen = Set<HistoryColorReference>.identity();
      for (int ramp = 0; ramp < KPalConstraints.rampCountMax; ramp++)
      {
        for (int color = 0; color < KPalConstraints.colorCountMax; color++)
        {
          final HistoryColorReference ref = HistoryColorReference.of(colorIndex: color, rampIndex: ramp);
          expect(ref.rampIndex, ramp);
          expect(ref.colorIndex, color);
          seen.add(ref);
        }
      }
      expect(seen.length, KPalConstraints.rampCountMax * KPalConstraints.colorCountMax,
          reason: "two colors ending up on the same shared instance would repaint pixels",);
    });

    test("still describes a color outside the palette limits", ()
    {
      final HistoryColorReference outside = HistoryColorReference.of(colorIndex: KPalConstraints.colorCountMax, rampIndex: KPalConstraints.rampCountMax);
      expect(outside.colorIndex, KPalConstraints.colorCountMax);
      expect(outside.rampIndex, KPalConstraints.rampCountMax);
    });
  });

  group("RampResolver.byUuid", ()
  {
    final KPalRampData ramp = KPalRampData(uuid: "ramp-a", settings: KPalRampSettings());
    final List<HistoryRampData> historyRamps = <HistoryRampData>[
      HistoryRampData(otherSettings: ramp.settings, notifierShifts: ramp.shifts, uuid: ramp.uuid),
    ];

    test("returns the live ramp's own reference", ()
    {
      final RampResolver resolver = RampResolver(liveRamps: <KPalRampData>[ramp], historyRamps: historyRamps);
      expect(resolver.byUuid(ref: HistoryColorReference.of(colorIndex: 2, rampIndex: 0)), same(ramp.references[2]));
    });

    test("skips a pixel whose ramp is gone", ()
    {
      final RampResolver resolver = RampResolver(liveRamps: <KPalRampData>[], historyRamps: historyRamps);
      expect(resolver.byUuid(ref: HistoryColorReference.of(colorIndex: 2, rampIndex: 0)), isNull);
    });

    test("clamps an index past the end of the ramp", ()
    {
      final RampResolver resolver = RampResolver(liveRamps: <KPalRampData>[ramp], historyRamps: historyRamps);
      expect(resolver.byUuid(ref: HistoryColorReference.of(colorIndex: ramp.references.length + 2, rampIndex: 0)), same(ramp.references.last));
    });
  });

  testWidgets("a full restore gives the layers the palette's own references", (final WidgetTester tester) async
  {
    final CoordinateSetI pixel = CoordinateSetI(x: 1, y: 2);
    await withProject(tester: tester, canvasSize: CoordinateSetI(x: 4, y: 4), body: (final ProjectSession projectSession) async
    {
      final DrawingLayerState layer = layerAt(projectSession: projectSession, index: 0);
      final ColorReference color = GetIt.I.get<PaletteState>().colorRamps.first.references[1];
      layer.setDataAll(list: CoordinateColorMapNullable.from(<CoordinateSetI, ColorReference?>{pixel: color}));
      GetIt.I.get<HistoryManager>().addState(identifier: HistoryStateTypeIdentifier.toolPen, originLayer: layer);
      await settle();

      //adding a layer is a full-group step, so undoing it rebuilds every layer from history
      GetIt.I.get<LayerManager>().addNewLayer(layerType: DrawingLayerState);
      await settle();
      GetIt.I.get<HistoryController>().undoPressed();
      await settle();

      final KPalRampData restoredRamp = GetIt.I.get<PaletteState>().colorRamps.first;
      final DrawingLayerState restored = layerAt(projectSession: projectSession, index: 0);
      expect(restored, isNot(same(layer)), reason: "setup: the undo rebuilt the layer");
      expect(restored.getDataEntry(coord: pixel), same(restoredRamp.references[1]),
          reason: "a rebuilt layer should share the palette's reference instead of holding a copy per pixel",);
    },);
  });
}
