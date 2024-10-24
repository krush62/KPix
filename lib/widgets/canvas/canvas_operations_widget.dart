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
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class CanvasOperationsWidgetOptions
{
  final double iconHeight;
  final double padding;

  CanvasOperationsWidgetOptions({required this.iconHeight, required this.padding});
}

enum CanvasTransformation
{
  rotate,
  flipH,
  flipV
}

const Map<CanvasTransformation, String> transformationDescriptions =
{
  CanvasTransformation.rotate: "Rotate Canvas",
  CanvasTransformation.flipH: "Flip Canvas Horizontally",
  CanvasTransformation.flipV: "Flip Canvas Vertically"
};


class CanvasOperationsWidget extends StatefulWidget
{
  const CanvasOperationsWidget({super.key});

  @override
  State<CanvasOperationsWidget> createState() => _CanvasOperationsWidgetState();

}

class _CanvasOperationsWidgetState extends State<CanvasOperationsWidget>
{
  final CanvasOperationsWidgetOptions _options = GetIt.I.get<PreferenceManager>().canvasOperationsWidgetOptions;
  final AppState _appState = GetIt.I.get<AppState>();
  late KPixOverlay _canvasSizeOverlay;

  @override
  void initState()
  {
    super.initState();
    _canvasSizeOverlay = OverlayEntries.getCanvasSizeDialog(onDismiss: _hideOverlays, onAccept: _sizeChangeAccepted);
  }

  void _hideOverlays()
  {
    _canvasSizeOverlay.hide();
  }

  void _crop()
  {
    _appState.cropToSelection();
  }

  void _setSize()
  {
    _canvasSizeOverlay.show(context: context);
  }

  void _sizeChangeAccepted({required final CoordinateSetI size, required final CoordinateSetI offset})
  {
    _appState.changeCanvasSize(newSize: size, offset: offset);
    _hideOverlays();
  }


  @override
  Widget build(BuildContext context)
  {
    return Material(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: EdgeInsets.only(top: _options.padding, bottom: _options.padding, left: _options.padding / 2, right: _options.padding / 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: _options.padding / 2, right: _options.padding / 2),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Tooltip(
                    message: transformationDescriptions[CanvasTransformation.rotate],
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      onPressed: (){_appState.canvasTransform(transformation: CanvasTransformation.rotate);},
                      icon: FaIcon(
                        FontAwesomeIcons.rotate,
                        size: _options.iconHeight
                      )
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: _options.padding / 2, right: _options.padding / 2),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Tooltip(
                    message: transformationDescriptions[CanvasTransformation.flipH],
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      onPressed: (){_appState.canvasTransform(transformation: CanvasTransformation.flipH);},
                      icon: FaIcon(
                        FontAwesomeIcons.arrowsLeftRight,
                        size: _options.iconHeight
                      )
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: _options.padding / 2, right: _options.padding / 2),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Tooltip(
                    message: transformationDescriptions[CanvasTransformation.flipV],
                    child: IconButton.outlined(
                      onPressed: (){_appState.canvasTransform(transformation: CanvasTransformation.flipV);},
                      icon: FaIcon(
                        FontAwesomeIcons.arrowsUpDown,
                        size: _options.iconHeight
                      )
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: _options.padding / 2, right: _options.padding / 2),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ListenableBuilder(
                    listenable: _appState.selectionState,
                    builder: (context, child) {
                      return Tooltip(
                        message: "Crop To Selection",
                        waitDuration: AppState.toolTipDuration,
                        child: IconButton.outlined(
                          onPressed: _appState.selectionState.selection.isEmpty ? null : _crop,
                          icon: FaIcon(
                            FontAwesomeIcons.cropSimple,
                            size: _options.iconHeight
                          )
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: _options.padding / 2, right: _options.padding / 2),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Tooltip(
                    message: "Set Size",
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      onPressed: _setSize,
                      icon: FaIcon(
                        FontAwesomeIcons.rulerCombined,
                        size: _options.iconHeight
                      )
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}