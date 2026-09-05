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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Guards the layering described in `docs/dev/import_cycles.md`.
///
/// A library may import anything at its own layer or below, never above. The
/// 23 exceptions below are what was left when that document's phases finished;
/// each is a design question rather than a misplaced declaration, and the list
/// is meant to shrink and never grow.
///
/// If this fails after you added an import, the import is pointing the wrong
/// way. Move the declaration you need down to where its users are, rather than
/// adding a line here.
const List<List<String>> _layers = <List<String>>[
  <String>[ //0 util
    "lib/util/helpers/", "lib/util/typedefs.dart", "lib/util/color_names.dart",
    "lib/util/file_byte_reader.dart", "lib/util/logging_extensions.dart",
    "lib/util/layer_color_supplier.dart", "lib/util/messages.dart",
    "lib/kpix_constants.dart", "lib/kpix_theme.dart", "lib/kpix_icons.dart",
    "lib/kpix_logger.dart", "lib/oss_licenses.dart", "lib/layer_widget_options.dart",
  ],
  <String>["lib/infra/"],                                   //1 infra
  <String>["lib/models/", "lib/layer_states/"],             //2 state
  <String>["lib/managers/", "lib/preferences/"],            //3 services
  <String>["lib/util/"],                                    //4 io
  <String>["lib/painting/", "lib/tool_options/"],           //5 painting
  <String>["lib/widgets/"],                                 //6 widgets
  <String>["lib/main.dart"],                                //7 entry
];

/// Violations that already existed when the guard was added.
///
/// Grouped by why they are still here:
///  * `tool_options/` mixes options data with the widgets that edit them, so the
///    state layer reaches up for the data and the options reach up for controls;
///  * `PreferenceManager` supplies constraint values at runtime;
///  * the layer states build their own settings widgets;
///  * three services legitimately call the file layer.
const Set<String> _allowed = <String>{
  "lib/layer_states/dither_layer/dither_layer_state.dart -> lib/widgets/layer_settings/shading_layer_settings_widget.dart",
  "lib/layer_states/drawing_layer/drawing_layer_state.dart -> lib/managers/preference_manager.dart",
  "lib/layer_states/drawing_layer/drawing_layer_state.dart -> lib/widgets/layer_settings/drawing_layer_settings_widget.dart",
  "lib/layer_states/layer_collection.dart -> lib/util/file_handler.dart",
  "lib/layer_states/shading_layer/shading_layer_state.dart -> lib/managers/preference_manager.dart",
  "lib/layer_states/shading_layer/shading_layer_state.dart -> lib/widgets/layer_settings/shading_layer_settings_widget.dart",
  "lib/managers/project_manager.dart -> lib/util/file_handler.dart",
  "lib/managers/stamp_manager.dart -> lib/util/file_handler.dart",
  "lib/models/document_state.dart -> lib/tool_options/tool_options.dart",
  "lib/models/history/history_manager.dart -> lib/managers/preference_manager.dart",
  "lib/models/project_session.dart -> lib/managers/preference_manager.dart",
  "lib/models/selection_state.dart -> lib/managers/preference_manager.dart",
  "lib/models/selection_state.dart -> lib/preferences/preference_values.dart",
  "lib/models/selection_state.dart -> lib/tool_options/select_options.dart",
  "lib/models/selection_state.dart -> lib/tool_options/tool_options.dart",
  "lib/models/time_line_state.dart -> lib/managers/preference_manager.dart",
  "lib/models/tool_state.dart -> lib/tool_options/select_options.dart",
  "lib/models/tool_state.dart -> lib/tool_options/tool_options.dart",
  "lib/tool_options/shape_options.dart -> lib/widgets/controls/kpix_slider.dart",
  "lib/tool_options/stamp_options.dart -> lib/widgets/controls/kpix_slider.dart",
  "lib/tool_options/text_options.dart -> lib/widgets/overlays/overlay_entries.dart",
  "lib/tool_options/tool_gui.dart -> lib/widgets/controls/kpix_slider.dart",
  "lib/util/helpers/color_helper.dart -> lib/models/color_types.dart",
};

int _layerOf(final String path)
{
  for (int i = 0; i < _layers.length; i++)
  {
    for (final String prefix in _layers[i])
    {
      if (path == prefix || path.startsWith(prefix))
      {
        return i;
      }
    }
  }
  return _layers.length - 1;
}

const String _pkg = "package:kpix/";

void main()
{
  test("no library imports a higher layer", ()
  {
    final Directory lib = Directory("lib");
    expect(lib.existsSync(), isTrue, reason: "run from the repository root");

    //a part shares its library's imports, so it is not a unit of its own
    final Map<String, String> partOf = <String, String>{};
    final Map<String, List<String>> imports = <String, List<String>>{};

    for (final FileSystemEntity e in lib.listSync(recursive: true))
    {
      if (e is! File || !e.path.endsWith(".dart"))
      {
        continue;
      }
      final String self = p.split(e.path).join("/");
      final List<String> found = <String>[];
      for (final String raw in e.readAsLinesSync())
      {
        final String line = raw.trim();
        if (line.startsWith("part of "))
        {
          final List<String> q = line.split("'");
          if (q.length >= 2)
          {
            partOf[self] = q[1].startsWith(_pkg)
                ? "lib/${q[1].substring(_pkg.length)}"
                : p.split(p.normalize(p.join(p.dirname(self), q[1]))).join("/");
          }
        }
        else if (line.startsWith("import '"))
        {
          final List<String> q = line.split("'");
          if (q.length >= 2 && q[1].startsWith(_pkg))
          {
            found.add("lib/${q[1].substring(_pkg.length)}");
          }
        }
      }
      imports[self] = found;
    }

    String libraryOf(final String file)
    {
      String current = file;
      final Set<String> seen = <String>{};
      while (partOf.containsKey(current) && seen.add(current))
      {
        current = partOf[current]!;
      }
      return current;
    }

    final Set<String> violations = <String>{};
    imports.forEach((final String file, final List<String> targets)
    {
      final String from = libraryOf(file);
      for (final String target in targets)
      {
        final String to = libraryOf(target);
        if (to != from && _layerOf(from) < _layerOf(to))
        {
          violations.add("$from -> $to");
        }
      }
    });

    final Set<String> added = violations.difference(_allowed);
    expect(added, isEmpty,
        reason: "these imports point up a layer; move the declaration down "
            "instead of widening the allow-list",);

    final Set<String> fixed = _allowed.difference(violations);
    expect(fixed, isEmpty,
        reason: "these allow-list entries are obsolete - delete them, the "
            "list is only allowed to shrink",);
  });
}
