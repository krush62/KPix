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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/helper.dart';

class SelectionBarWidgetOptions
{
  final double iconHeight;
  final double padding;
  final int opacityDuration;

  SelectionBarWidgetOptions({required this.iconHeight, required this.padding, required this.opacityDuration});


}

class SelectionBarWidget extends StatefulWidget
{
  const SelectionBarWidget({super.key});

  @override
  State<SelectionBarWidget> createState() => _SelectionBarWidgetState();

}

class _SelectionBarWidgetState extends State<SelectionBarWidget>
{
  final SelectionBarWidgetOptions _options = GetIt.I.get<PreferenceManager>().selectionBarWidgetOptions;
  final SelectionState _selectionState = GetIt.I.get<AppState>().selectionState;
  final AppState _appState = GetIt.I.get<AppState>();


  void _pasteNewPressed()
  {
    _appState.addNewLayer(select: true, content: _appState.selectionState.clipboard);
  }

  @override
  Widget build(final BuildContext context) {
    return ListenableBuilder(
      listenable: _selectionState,
      builder: (final BuildContext context, final Widget? child)
      {
        return Material(
          color: Theme.of(context).primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Select All",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selectAll,
                    icon: FaIcon(
                        FontAwesomeIcons.objectGroup,
                        size: _options.iconHeight
                    )
                                ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Deselect",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                      onPressed: _selectionState.selection.isEmpty() ? null : (){return _selectionState.deselect(addToHistoryStack: true);},
                      icon: FaIcon(
                        FontAwesomeIcons.objectUngroup,
                        size: _options.iconHeight
                      )
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Inverse Selection",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                      onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.inverse,
                      icon: FaIcon(
                        FontAwesomeIcons.circleHalfStroke,
                        size: _options.iconHeight
                      )
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Copy",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.copy,
                    icon: FaIcon(
                      FontAwesomeIcons.copy,
                      size: _options.iconHeight
                    )
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Copy Merged",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.copyMerged,
                    icon: FaIcon(
                      FontAwesomeIcons.clone,
                      size: _options.iconHeight
                    )
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Cut",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.cut,
                    icon: FaIcon(
                      FontAwesomeIcons.scissors,
                      size: _options.iconHeight
                    )
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Paste",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.clipboard == null ? null : _selectionState.paste,
                    icon: FaIcon(
                      FontAwesomeIcons.paste,
                      size: _options.iconHeight
                    )
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Paste As New Layer",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.clipboard == null ? null : _pasteNewPressed,
                    icon: FaIcon(
                      FontAwesomeIcons.layerGroup,
                      size: _options.iconHeight
                    )
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Horizontal Flip",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.flipH,
                    icon: FaIcon(
                      FontAwesomeIcons.arrowsLeftRight,
                      size: _options.iconHeight
                    )
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Vertical Flip",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.flipV,
                    icon: FaIcon(
                      FontAwesomeIcons.arrowsUpDown,
                      size: _options.iconHeight
                    )
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Rotate 90° Clockwise",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.rotate,
                    icon: FaIcon(
                      FontAwesomeIcons.rotateRight,
                      size: _options.iconHeight
                    )
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(_options.padding),
                child: Tooltip(
                  message: "Delete",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.delete,
                    icon: FaIcon(
                      FontAwesomeIcons.ban,
                      size: _options.iconHeight
                    )
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}