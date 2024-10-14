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
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/preferences/behavior_preferences.dart';
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';
import 'package:kpix/widgets/main/layer_widget.dart';
import 'package:kpix/widgets/main/main_button_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class RightBarWidget extends StatefulWidget
{
  const RightBarWidget({
    super.key,
  });

  @override
  State<RightBarWidget> createState() => _RightBarWidgetState();

}

class _RightBarWidgetState extends State<RightBarWidget>
{
  late List<Widget> _widgetList;
  final AppState _appState = GetIt.I.get<AppState>();
  final LayerWidgetOptions _layerWidgetOptions = GetIt.I.get<PreferenceManager>().layerWidgetOptions;
  final BehaviorPreferenceContent _behaviorOptions = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent;

  final LayerLink _layerLink = LayerLink();
  late KPixOverlay addLayerMenu;

  @override
  void initState()
  {
    super.initState();
    _createWidgetList(_appState.layers);
    addLayerMenu = OverlayEntries.getAddLayerMenu(
      onDismiss: _closeLayerMenu,
      layerLink: _layerLink,
      onNewDrawingLayer: _newDrawingLayerPressed,
      onNewReferenceLayer: _newReferenceLayerPressed
    );
  }

  void _closeLayerMenu()
  {
    addLayerMenu.hide();
  }

  void _newDrawingLayerPressed()
  {
    _appState.addNewDrawingLayer(select: _behaviorOptions.selectLayerAfterInsert.value);
    _closeLayerMenu();
  }

  void _newReferenceLayerPressed()
  {
    _appState.addNewReferenceLayer(select: _behaviorOptions.selectLayerAfterInsert.value);
    _closeLayerMenu();
  }

  void _createWidgetList(final List<LayerState> layers)
  {
    _widgetList = [];
    for (int i = 0; i < layers.length; i++)
    {
      _widgetList.add(DragTarget<LayerState>(
        builder: (final BuildContext context, final List<LayerState?> candidateItems, final List<dynamic> rejectedItems) {
          return AnimatedContainer(
            height: candidateItems.isEmpty ? _layerWidgetOptions.outerPadding : _layerWidgetOptions.dragTargetHeight,
            color: candidateItems.isEmpty ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight,
            duration: Duration(milliseconds: _layerWidgetOptions.dragTargetShowDuration)
          );
        },
        onAcceptWithDetails: (details) {
          _appState.changeLayerOrder(state: details.data, newPosition: i);
        },
      ));

      _widgetList.add(LayerWidget(
        layerState: layers[i],
      ));
    }
    _widgetList.add(DragTarget<LayerState>(
      builder: (final BuildContext context, final List<LayerState?> candidateItems, final List<dynamic> rejectedItems) {
        return Divider(
          height: candidateItems.isEmpty ? _layerWidgetOptions.outerPadding : _layerWidgetOptions.dragTargetHeight,
          thickness: candidateItems.isEmpty ? _layerWidgetOptions.outerPadding : _layerWidgetOptions.dragTargetHeight,
          color: candidateItems.isEmpty ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight,
        );
      },
      onAcceptWithDetails: (details) {
        _appState.changeLayerOrder(state: details.data, newPosition: layers.length);
      },
    ));
  }


  @override
  Widget build(final BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,

      child: Column(
        children: [
          const MainButtonWidget(
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).primaryColorDark,
              child: ValueListenableBuilder<bool>(
                valueListenable: _appState.hasProjectNotifier,
                builder: (final BuildContext context, final bool hasProject, final Widget? child) {
                  return hasProject ? SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: _layerWidgetOptions.outerPadding, left: _layerWidgetOptions.outerPadding, right: _layerWidgetOptions.outerPadding),
                          child: CompositedTransformTarget(
                            link: _layerLink,
                            child: Tooltip(
                              message: "Add New Layer...",
                              waitDuration: AppState.toolTipDuration,
                              child: IconButton.outlined(
                                onPressed: () {addLayerMenu.show(context: context);},
                                icon: const FaIcon(FontAwesomeIcons.plus),
                                style: IconButton.styleFrom(
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    minimumSize: Size(_layerWidgetOptions.addButtonSize.toDouble(), _layerWidgetOptions.addButtonSize.toDouble()),
                                    maximumSize: Size(_layerWidgetOptions.addButtonSize.toDouble(), _layerWidgetOptions.addButtonSize.toDouble()),
                                    iconSize: _layerWidgetOptions.addButtonSize.toDouble() - _layerWidgetOptions.innerPadding,
                                    padding: EdgeInsets.zero
                                ),
                              ),
                            ),
                          ),
                        ),
                        ValueListenableBuilder<List<LayerState>>(
                          valueListenable: _appState.layerListNotifier,
                          builder: (final BuildContext context, final List<LayerState> states, final Widget? child)
                          {
                            _createWidgetList(states);
                            return Column(children: _widgetList);
                          }
                        ),
                      ],
                    ),
                  ) : const SizedBox.shrink();
                },
              ),
            )
          ),
          const CanvasOperationsWidget()
        ],
      )
    );
  }

}