import 'dart:collection';

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
  CanvasTransformation.rotate: "rotate canvas",
  CanvasTransformation.flipH: "flip canvas horizontally",
  CanvasTransformation.flipV: "flip canvas vertically"
};


class CanvasOperationsWidget extends StatefulWidget
{
  const CanvasOperationsWidget({super.key});

  @override
  State<CanvasOperationsWidget> createState() => CanvasOperationsWidgetState();

}

class CanvasOperationsWidgetState extends State<CanvasOperationsWidget>
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
    _canvasSizeOverlay.show(context);
  }

  void _sizeChangeAccepted(final CoordinateSetI size, final CoordinateSetI offset)
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
                  child: IconButton.outlined(
                    tooltip: transformationDescriptions[CanvasTransformation.rotate],
                    onPressed: (){_appState.canvasTransform(CanvasTransformation.rotate);},
                    icon: FaIcon(
                      FontAwesomeIcons.rotate,
                      size: _options.iconHeight
                    )
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: _options.padding / 2, right: _options.padding / 2),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: IconButton.outlined(
                    tooltip: transformationDescriptions[CanvasTransformation.flipH],
                    onPressed: (){_appState.canvasTransform(CanvasTransformation.flipH);},
                    icon: FaIcon(
                      FontAwesomeIcons.arrowsLeftRight,
                      size: _options.iconHeight
                    )
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: _options.padding / 2, right: _options.padding / 2),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: IconButton.outlined(
                    tooltip: transformationDescriptions[CanvasTransformation.flipV],
                    onPressed: (){_appState.canvasTransform(CanvasTransformation.flipV);},
                    icon: FaIcon(
                      FontAwesomeIcons.arrowsUpDown,
                      size: _options.iconHeight
                    )
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
                      return IconButton.outlined(
                        tooltip: "Crop To Selection",
                        onPressed: _appState.selectionState.selection.isEmpty()? null : _crop,
                        icon: FaIcon(
                          FontAwesomeIcons.cropSimple,
                          size: _options.iconHeight
                        )
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
                  child: IconButton.outlined(
                    tooltip: "Set Size",
                    onPressed: _setSize,
                    icon: FaIcon(
                      FontAwesomeIcons.rulerCombined,
                      size: _options.iconHeight
                    )
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