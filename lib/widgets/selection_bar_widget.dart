import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/selection_state.dart';
import 'package:kpix/preference_manager.dart';

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
  SelectionBarWidgetOptions options = GetIt.I.get<PreferenceManager>().selectionBarWidgetOptions;
  SelectionState selectionState = GetIt.I.get<AppState>().selectionState;
  AppState appState = GetIt.I.get<AppState>();


  void _pasteNewPressed()
  {
    appState.addNewLayer(select: true, content: appState.selectionState.clipboard);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: selectionState,
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
                  padding: EdgeInsets.all(options.padding),
                  child: IconButton.outlined(
                      tooltip: "Select All",
                      onPressed: selectionState.selectAll,
                      icon: FaIcon(
                          FontAwesomeIcons.objectGroup,
                          size: options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: IconButton.outlined(
                      tooltip: "Deselect",
                      onPressed: selectionState.selection.isEmpty() ? null : (){return selectionState.deselect(addToHistoryStack: true);},
                      icon: FaIcon(
                          FontAwesomeIcons.objectUngroup,
                          size: options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: IconButton.outlined(
                      tooltip: "Inverse Selection",
                      onPressed: selectionState.selection.isEmpty() ? null : selectionState.inverse,
                      icon: FaIcon(
                          FontAwesomeIcons.circleHalfStroke,
                          size: options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: IconButton.outlined(
                      tooltip: "Copy",
                      onPressed: selectionState.selection.isEmpty() ? null : selectionState.copy,
                      icon: FaIcon(
                          FontAwesomeIcons.copy,
                          size: options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: IconButton.outlined(
                      tooltip: "Copy Merged",
                      onPressed: selectionState.selection.isEmpty() ? null : selectionState.copyMerged,
                      icon: FaIcon(
                          FontAwesomeIcons.clone,
                          size: options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: IconButton.outlined(
                      tooltip: "Cut",
                      onPressed: selectionState.selection.isEmpty() ? null : selectionState.cut,
                      icon: FaIcon(
                          FontAwesomeIcons.scissors,
                          size: options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: IconButton.outlined(
                      tooltip: "Paste",
                      onPressed: selectionState.clipboard == null ? null : selectionState.paste,
                      icon: FaIcon(
                          FontAwesomeIcons.paste,
                          size: options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: IconButton.outlined(
                      tooltip: "Paste As New Layer",
                      onPressed: selectionState.clipboard == null ? null : _pasteNewPressed,
                      icon: FaIcon(
                          FontAwesomeIcons.layerGroup,
                          size: options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: IconButton.outlined(
                      tooltip: "Flip Horizontal",
                      onPressed: selectionState.selection.isEmpty() ? null : selectionState.flipH,
                      icon: FaIcon(
                          FontAwesomeIcons.arrowsLeftRight,
                          size: options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: IconButton.outlined(
                      tooltip: "Flip Vertical",
                      onPressed: selectionState.selection.isEmpty() ? null : selectionState.flipV,
                      icon: FaIcon(
                          FontAwesomeIcons.arrowsUpDown,
                          size: options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: IconButton.outlined(
                      tooltip: "Rotate 90°",
                      onPressed: selectionState.selection.isEmpty() ? null : selectionState.rotate,
                      icon: FaIcon(
                          FontAwesomeIcons.rotateRight,
                          size: options.iconHeight
                      )
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: IconButton.outlined(
                      tooltip: "Delete",
                      onPressed: selectionState.selection.isEmpty() ? null : selectionState.delete,
                      icon: FaIcon(
                          FontAwesomeIcons.ban,
                          size: options.iconHeight
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