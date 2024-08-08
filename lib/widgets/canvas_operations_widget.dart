import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';

class CanvasOperationsWidgetOptions
{
  final double iconHeight;
  final double padding;

  CanvasOperationsWidgetOptions({required this.iconHeight, required this.padding});
}


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

  void _rotate()
  {
    //TODO call directly
    _appState.canvasRotate();
  }

  void _hFlip()
  {
    //TODO
  }

  void _vFlip()
  {
    //TODO
  }

  void _crop()
  {
    //TODO
  }

  void _setSize()
  {
    //TODO
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
                    tooltip: "Rotate",
                    onPressed: _rotate,
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
                    tooltip: "Horizontal Flip",
                    onPressed: _hFlip,
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
                    tooltip: "Vertical Flip",
                    onPressed: _vFlip,
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