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

import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:kpix/models/project_manager_data.dart';
import 'package:kpix/util/helpers/format_helper.dart';

/// Layout options for [ProjectManagerEntryWidget].
abstract final class _ProjectManagerEntryOptions
{
  static const double borderWidth = 2.0;
  static const double borderRadius = 3.0;
  static const int layoutFlex = 6;
  static const double placeholderIconSize = 32.0;
}

/// Visualization of a project file used for the project manager grid.
///
/// The selection is held as a path in [selectedPath] instead of a reference to
/// this widget, so it survives the list being rebuilt when the cache updates.
class ProjectManagerEntryWidget extends StatefulWidget
{
  final ProjectManagerEntryData entryData;
  final ValueNotifier<String?> selectedPath;
  final Function() onOpen;
  const ProjectManagerEntryWidget({super.key, required this.entryData, required this.selectedPath, required this.onOpen});

  @override
  State<ProjectManagerEntryWidget> createState() => _ProjectManagerEntryWidgetState();
}

class _ProjectManagerEntryWidgetState extends State<ProjectManagerEntryWidget>
{
  DateTime? _lastTap;

  //detected by hand, since onDoubleTap would hold back every single tap
  void _onTap()
  {
    final DateTime now = DateTime.now();
    if (widget.selectedPath.value == widget.entryData.path && _lastTap != null && now.difference(_lastTap!) <= kDoubleTapTimeout)
    {
      _lastTap = null;
      widget.onOpen();
    }
    else
    {
      _lastTap = now;
      widget.selectedPath.value = widget.entryData.path;
    }
  }

  @override
  Widget build(final BuildContext context)
  {
    return ValueListenableBuilder<String?>(
      valueListenable: widget.selectedPath,
      builder: (final BuildContext context, final String? selected, final Widget? child) {
        final bool isSelected = selected == widget.entryData.path;
        return GestureDetector(
          onTap: _onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor,
                width: _ProjectManagerEntryOptions.borderWidth,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(_ProjectManagerEntryOptions.borderRadius)),
            ),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: Text(
                      widget.entryData.name,
                      style: Theme.of(context).textTheme.titleSmall!.apply(color: Theme.of(context).primaryColorLight),
                    ),
                  ),
                ),
                Expanded(
                  flex: _ProjectManagerEntryOptions.layoutFlex,
                  child: Padding(
                    padding: const EdgeInsets.all(_ProjectManagerEntryOptions.borderWidth),
                    child: widget.entryData.thumbnail != null
                        ? RawImage(image: widget.entryData.thumbnail, fit: BoxFit.contain, filterQuality: ui.FilterQuality.none,)
                        : Center(
                            child: Icon(
                              TablerIcons.photo_off,
                              size: _ProjectManagerEntryOptions.placeholderIconSize,
                              color: Theme.of(context).primaryColorLight,
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      formatDateTime(dateTime: widget.entryData.dateTime),
                      style: Theme.of(context).textTheme.titleSmall!.apply(color: Theme.of(context).primaryColorLight),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
