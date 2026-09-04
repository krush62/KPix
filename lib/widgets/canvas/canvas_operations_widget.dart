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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/canvas_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/canvas/canvas_size_constraints.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// Layout options for the [CanvasOperationsWidget].
abstract final class _CanvasOperationsWidgetOptions
{
  static const double iconHeight = 20.0;
  static const double buttonHeight = 36.0;
  static const double padding = 4.0;
}

/// Available canvas transformations.
enum CanvasTransformation
{
  rotate,
  flipH,
  flipV
}

/// Descriptions for the available canvas operations.
const Map<CanvasTransformation, String> transformationDescriptions =
<CanvasTransformation, String>{
  CanvasTransformation.rotate: "Rotate Canvas",
  CanvasTransformation.flipH: "Flip Canvas Horizontally",
  CanvasTransformation.flipV: "Flip Canvas Vertically",
};

/// Widget for applying canvas-level transformations.
///
/// This includes rotation, flipping and cropping.
class CanvasOperationsWidget extends StatefulWidget
{
  const CanvasOperationsWidget({super.key});

  @override
  State<CanvasOperationsWidget> createState() => _CanvasOperationsWidgetState();

}

class _CanvasOperationsWidgetState extends State<CanvasOperationsWidget>
{
  final AppState _appState = GetIt.I.get<AppState>();
  final CanvasState _canvasState = GetIt.I.get<CanvasState>();
  late KPixOverlay _canvasSizeOverlay;

  @override
  void initState()
  {
    super.initState();
    _canvasSizeOverlay = getCanvasSizeDialog(onDismiss: _hideOverlays, onAccept: _sizeChangeAccepted);
  }

  void _hideOverlays()
  {
    _canvasSizeOverlay.hide();
  }

  void _crop()
  {
    _canvasState.cropToSelection();
  }

  void _setSize()
  {
    _canvasSizeOverlay.show(context: context);
  }

  void _sizeChangeAccepted({required final CoordinateSetI size, required final CoordinateSetI offset})
  {
    _canvasState.changeCanvasSize(newSize: size, offset: offset);
    _hideOverlays();
  }


  @override
  Widget build(final BuildContext context)
  {
    return Material(
      color: Theme.of(context).primaryColor,
      child: SizedBox(
        height: _CanvasOperationsWidgetOptions.buttonHeight,
        child: Padding(
          padding: const EdgeInsets.only(top: _CanvasOperationsWidgetOptions.padding, bottom: _CanvasOperationsWidgetOptions.padding, right: _CanvasOperationsWidgetOptions.padding * 2, left: _CanvasOperationsWidgetOptions.padding * 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Expanded(
                child: Tooltip(
                  message: transformationDescriptions[CanvasTransformation.rotate],
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: (){_canvasState.canvasTransform(transformation: CanvasTransformation.rotate);},
                    icon: const Icon(
                      TablerIcons.rotate_clockwise_2,
                      size: _CanvasOperationsWidgetOptions.iconHeight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _CanvasOperationsWidgetOptions.padding),
              Expanded(
                child: Tooltip(
                  message: transformationDescriptions[CanvasTransformation.flipH],
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: (){_canvasState.canvasTransform(transformation: CanvasTransformation.flipH);},
                    icon: const Icon(
                      TablerIcons.flip_vertical,
                      size: _CanvasOperationsWidgetOptions.iconHeight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _CanvasOperationsWidgetOptions.padding),
              Expanded(
                child: Tooltip(
                  message: transformationDescriptions[CanvasTransformation.flipV],
                  child: IconButton.outlined(
                    onPressed: (){_canvasState.canvasTransform(transformation: CanvasTransformation.flipV);},
                    icon: const Icon(
                      TablerIcons.flip_horizontal,
                      size: _CanvasOperationsWidgetOptions.iconHeight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _CanvasOperationsWidgetOptions.padding),
              Expanded(
                child: ListenableBuilder(
                  listenable: _appState.selectionState,
                  builder: (final BuildContext context, final Widget? child) {
                    bool cropEnabled = false;

                    if (!_appState.selectionState.selection.isEmpty)
                    {
                      final (CoordinateSetI?, CoordinateSetI?) selectionSize = _appState.selectionState.selection.getBoundingBox(canvasSize: _canvasState.canvasSize);
                      final CoordinateSetI? topLeft = selectionSize.$1;
                      final CoordinateSetI? bottomRight = selectionSize.$2;
                      if (topLeft != null && bottomRight != null && (bottomRight.x - topLeft.x + 1) >= CanvasSizeConstraints.sizeMin && (bottomRight.y - topLeft.y + 1) >= CanvasSizeConstraints.sizeMin)
                      {
                        cropEnabled = true;
                      }
                    }
                    return Tooltip(
                      message: "Crop To Selection",
                      waitDuration: AppState.toolTipDuration,
                      child: IconButton.outlined(
                        onPressed: cropEnabled ? _crop : null,
                        icon: const Icon(
                          TablerIcons.crop,
                          size: _CanvasOperationsWidgetOptions.iconHeight,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: _CanvasOperationsWidgetOptions.padding),
              Expanded(
                child: Tooltip(
                  message: "Set Size",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    onPressed: _setSize,
                    icon: const Icon(
                      TablerIcons.resize,
                      size: _CanvasOperationsWidgetOptions.iconHeight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
