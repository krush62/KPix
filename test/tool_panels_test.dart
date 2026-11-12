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
import 'package:kpix/models/constraints/tool_line_constraints.dart';
import 'package:kpix/models/constraints/tool_shape_constraints.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/tool_type.dart';
import 'package:kpix/tool_options/line_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/tool_geometry_helper.dart';
import 'package:kpix/widgets/controls/kpix_dropdown.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';
import 'package:material_ui/material_ui.dart';

import 'support/widget_harness.dart';

ToolOptions get _options => GetIt.I.get<ToolOptions>();
ToolState get _tools => GetIt.I.get<ToolState>();

Widget _panel() => const Center(child: SizedBox(width: 500, height: 400, child: ToolSettingsWidget()));

Future<void> _select(final WidgetTester tester, final ToolType tool) async
{
  _tools.setToolSelection(tool: tool);
  await tester.pump();
  await tester.pump();
}

void _slide(final WidgetTester tester, {required final int index, required final double to})
{
  tester.widget<KPixSlider>(find.byType(KPixSlider).at(index)).onChanged!(to);
}

void main()
{
  group("every tool", ()
  {
    for (final ToolType tool in ToolType.values)
    {
      projectWidgetTest("shows its panel: ${tool.name}", _panel, (final WidgetTester tester) async
      {
        await _select(tester, tool);

        expect(tester.takeException(), isNull);
        expect(find.byType(ToolSettingsWidget), findsOneWidget);
      });
    }
  });

  group("the size of a tool", ()
  {
    projectWidgetTest("stays within its limits", _panel, (final WidgetTester tester) async
    {
      for (final ToolType tool in <ToolType>[ToolType.pencil, ToolType.erase, ToolType.shape, ToolType.line, ToolType.spraycan])
      {
        final IToolOptions options = _options.toolOptionMap[tool]!;

        options.changeSize(steps: 1000, originalValue: 1);
        final int largest = options.getSize();
        expect(largest, greaterThan(1), reason: tool.name);

        options.changeSize(steps: -1000, originalValue: largest);
        final int smallest = options.getSize();
        expect(smallest, lessThan(largest), reason: tool.name);

        options.changeSize(steps: 1, originalValue: smallest);
        expect(options.getSize(), smallest + 1, reason: tool.name);
      }
    });

    projectWidgetTest("means nothing for tools without one", _panel, (final WidgetTester tester) async
    {
      for (final ToolType tool in <ToolType>[ToolType.fill, ToolType.pick])
      {
        final IToolOptions options = _options.toolOptionMap[tool]!;

        options.changeSize(steps: 5, originalValue: 1);

        expect(options.getSize(), 0, reason: tool.name);
      }
    });
  });

  group("the shape panel", ()
  {
    projectWidgetTest("offers corners for rectangles, and a count for polygons", _panel, (final WidgetTester tester) async
    {
      await _select(tester, ToolType.shape);

      for (final DrawingShape shape in DrawingShape.values)
      {
        _options.shapeOptions.shape.value = shape;
        await tester.pump();

        expect(find.text(testL10n.cornerRadius), shape == DrawingShape.rectangle ? findsOneWidget : findsNothing, reason: shape.name);
        expect(find.text(testL10n.cornerCount), shape == DrawingShape.ngon || shape == DrawingShape.star ? findsOneWidget : findsNothing, reason: shape.name);
      }
    });

    projectWidgetTest("lets the stroke width be changed only for a stroke", _panel, (final WidgetTester tester) async
    {
      await _select(tester, ToolType.shape);
      _options.shapeOptions.shape.value = DrawingShape.ellipse;
      await tester.pump();
      expect(tester.widget<KPixSlider>(find.byType(KPixSlider).first).onChanged, isNull);

      await tester.tap(find.byType(Switch).at(1));
      await tester.pump();

      expect(_options.shapeOptions.strokeOnly.value, isTrue);
      _slide(tester, index: 0, to: 4);
      expect(_options.shapeOptions.strokeWidth.value, 4);
    });

    projectWidgetTest("hands its corner sliders on", _panel, (final WidgetTester tester) async
    {
      await _select(tester, ToolType.shape);
      _options.shapeOptions.shape.value = DrawingShape.rectangle;
      await tester.pump();
      _slide(tester, index: 1, to: 3);
      expect(_options.shapeOptions.cornerRadius.value, 3);

      _options.shapeOptions.shape.value = DrawingShape.star;
      await tester.pump();
      _slide(tester, index: 1, to: ToolShapeConstraints.cornerCountMax.toDouble());
      expect(_options.shapeOptions.cornerCount.value, ToolShapeConstraints.cornerCountMax);
    });

    projectWidgetTest("changes the shape with its buttons", _panel, (final WidgetTester tester) async
    {
      await _select(tester, ToolType.shape);
      final SegmentedButton<DrawingShape> button = tester.widget<SegmentedButton<DrawingShape>>(find.byType(SegmentedButton<DrawingShape>));

      button.onSelectionChanged!(<DrawingShape>{DrawingShape.diamond});

      expect(_options.shapeOptions.shape.value, DrawingShape.diamond);
    });
  });

  group("the line panel", ()
  {
    projectWidgetTest("offers the sort style only while it sorts", _panel, (final WidgetTester tester) async
    {
      await _select(tester, ToolType.line);
      _options.lineOptions.segmentSorting.value = false;
      await tester.pump();
      expect(find.byType(SegmentedButton<SegmentSortStyle>), findsNothing);

      await tester.tap(find.byType(Switch).last);
      await tester.pump();

      expect(_options.lineOptions.segmentSorting.value, isTrue);
      final SegmentSortStyle other = SegmentSortStyle.values.firstWhere((final SegmentSortStyle s) => s != _options.lineOptions.segmentSortStyle.value);
      tester.widget<SegmentedButton<SegmentSortStyle>>(find.byType(SegmentedButton<SegmentSortStyle>)).onSelectionChanged!(<SegmentSortStyle>{other});
      expect(_options.lineOptions.segmentSortStyle.value, other);
    });

    projectWidgetTest("hands its width slider on", _panel, (final WidgetTester tester) async
    {
      await _select(tester, ToolType.line);

      _slide(tester, index: 0, to: LineConstraints.widthMax.toDouble());

      expect(_options.lineOptions.width.value, LineConstraints.widthMax);
    });

    test("snaps to every whole ratio in every direction, each once", ()
    {
      final Set<AngleData> angles = LineOptions().angles;

      //the four axes, the four diagonals, and the ratios 2:1 to 8:1 both ways in all quadrants
      expect(angles, hasLength(4 + 4 + 7 * 8));
      expect(angles, contains(AngleData(x: 1, y: 0)));
      expect(angles, contains(AngleData(x: 0, y: -1)));
      expect(angles, contains(AngleData(x: -8, y: 1)));
      expect(angles, contains(AngleData(x: 1, y: -8)));
    });
  });

  group("the pencil panel", ()
  {
    projectWidgetTest("hands its controls on", _panel, (final WidgetTester tester) async
    {
      await _select(tester, ToolType.pencil);

      _slide(tester, index: 0, to: 6);
      expect(_options.pencilOptions.size.value, 6);

      expect(find.byWidgetPredicate((final Widget w) => w is KPixDropdown), findsOneWidget);
      expect(find.text(testL10n.smooth), findsOneWidget);
    });
  });

  group("the eraser panel", ()
  {
    projectWidgetTest("hands its size on", _panel, (final WidgetTester tester) async
    {
      await _select(tester, ToolType.erase);

      _slide(tester, index: 0, to: 5);

      expect(_options.eraserOptions.size.value, 5);
    });
  });

  group("the fill panel", ()
  {
    projectWidgetTest("hands its switches on", _panel, (final WidgetTester tester) async
    {
      await _select(tester, ToolType.fill);
      final bool wholeRamp = _options.fillOptions.fillWholeRamp.value;

      await tester.tap(find.byType(Switch).last);
      await tester.pump();

      expect(_options.fillOptions.fillWholeRamp.value, !wholeRamp);
      expect(find.text(testL10n.fillAdjacent), findsOneWidget);
    });
  });

  group("the color pick panel", ()
  {
    projectWidgetTest("hands its switch on and explains it", _panel, (final WidgetTester tester) async
    {
      await _select(tester, ToolType.pick);
      final bool raw = _options.colorPickOptions.rawMode.value;

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(_options.colorPickOptions.rawMode.value, !raw);
      expect(find.byTooltip(testL10n.rawModeExplanation), findsOneWidget);
    });
  });

  group("the spray can panel", ()
  {
    projectWidgetTest("hands its sliders on", _panel, (final WidgetTester tester) async
    {
      await _select(tester, ToolType.spraycan);

      _slide(tester, index: 0, to: 7);
      _slide(tester, index: 1, to: 2);
      _slide(tester, index: 2, to: 9);

      expect(_options.sprayCanOptions.radius.value, 7);
      expect(_options.sprayCanOptions.blobSize.value, 2);
      expect(_options.sprayCanOptions.intensity.value, 9);
    });
  });
}
