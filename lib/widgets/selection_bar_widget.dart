import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/managers/preference_manager.dart';

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
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: _selectionState,
        builder: (BuildContext context, child)
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
                  child: IconButton.outlined(
                      tooltip: "Select All",
                      onPressed: _selectionState.selectAll,
                      icon: FaIcon(
                          FontAwesomeIcons.objectGroup,
                          size: _options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                      tooltip: "Deselect",
                      onPressed: _selectionState.selection.isEmpty() ? null : (){return _selectionState.deselect(addToHistoryStack: true);},
                      icon: FaIcon(
                          FontAwesomeIcons.objectUngroup,
                          size: _options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                      tooltip: "Inverse Selection",
                      onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.inverse,
                      icon: FaIcon(
                          FontAwesomeIcons.circleHalfStroke,
                          size: _options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                      tooltip: "Copy",
                      onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.copy,
                      icon: FaIcon(
                          FontAwesomeIcons.copy,
                          size: _options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                      tooltip: "Copy Merged",
                      onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.copyMerged,
                      icon: FaIcon(
                          FontAwesomeIcons.clone,
                          size: _options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                      tooltip: "Cut",
                      onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.cut,
                      icon: FaIcon(
                          FontAwesomeIcons.scissors,
                          size: _options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                      tooltip: "Paste",
                      onPressed: _selectionState.clipboard == null ? null : _selectionState.paste,
                      icon: FaIcon(
                          FontAwesomeIcons.paste,
                          size: _options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                      tooltip: "Paste As New Layer",
                      onPressed: _selectionState.clipboard == null ? null : _pasteNewPressed,
                      icon: FaIcon(
                          FontAwesomeIcons.layerGroup,
                          size: _options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                      tooltip: "Flip Horizontal",
                      onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.flipH,
                      icon: FaIcon(
                          FontAwesomeIcons.arrowsLeftRight,
                          size: _options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                      tooltip: "Flip Vertical",
                      onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.flipV,
                      icon: FaIcon(
                          FontAwesomeIcons.arrowsUpDown,
                          size: _options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                      tooltip: "Rotate 90°",
                      onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.rotate,
                      icon: FaIcon(
                          FontAwesomeIcons.rotateRight,
                          size: _options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(_options.padding),
                  child: IconButton.outlined(
                      tooltip: "Delete",
                      onPressed: _selectionState.selection.isEmpty() ? null : _selectionState.delete,
                      icon: FaIcon(
                          FontAwesomeIcons.ban,
                          size: _options.iconHeight
                      )
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

}