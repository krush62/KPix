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
import 'package:kpix/layer_states/drawing_layer_settings_widget.dart';
import 'package:kpix/layer_states/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/shading_layer_settings_widget.dart';
import 'package:kpix/layer_states/shading_layer_state.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/preferences/behavior_preferences.dart';
import 'package:kpix/widgets/canvas/canvas_operations_widget.dart';
import 'package:kpix/widgets/main/layer_widget.dart';
import 'package:kpix/widgets/main/main_button_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

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
    _createWidgetList();
    addLayerMenu = getAddLayerMenu(
      onDismiss: _closeLayerMenu,
      layerLink: _layerLink,
      onNewDrawingLayer: _newDrawingLayerPressed,
      onNewReferenceLayer: _newReferenceLayerPressed,
      onNewGridLayer: _newGridLayerPressed,
      onNewShadingLayer: _newShadingLayerPressed,
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

  void _newGridLayerPressed()
  {
    _appState.addNewGridLayer(select: _behaviorOptions.selectLayerAfterInsert.value);
    _closeLayerMenu();
  }

  void _newShadingLayerPressed()
  {
    _appState.addNewShadingLayer(select: _behaviorOptions.selectLayerAfterInsert.value);
    _closeLayerMenu();
  }

  void _createWidgetList()
  {
    _widgetList = <Widget>[];
    for (int i = 0; i < _appState.layerCount; i++)
    {
      _widgetList.add(DragTarget<LayerState>(
        builder: (final BuildContext context, final List<LayerState?> candidateItems, final List<dynamic> rejectedItems) {
          return AnimatedContainer(
            height: candidateItems.isEmpty ? _layerWidgetOptions.outerPadding : _layerWidgetOptions.dragTargetHeight,
            color: candidateItems.isEmpty ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight,
            duration: Duration(milliseconds: _layerWidgetOptions.dragTargetShowDuration),
          );
        },
        onAcceptWithDetails: (final DragTargetDetails<LayerState> details) {
          _appState.changeLayerOrder(state: details.data, newPosition: i);
        },
      ),);

      _widgetList.add(LayerWidget(
        layerState: _appState.getLayerAt(index: i),
      ),);
    }
    _widgetList.add(DragTarget<LayerState>(
      builder: (final BuildContext context, final List<LayerState?> candidateItems, final List<dynamic> rejectedItems) {
        return Divider(
          height: candidateItems.isEmpty ? _layerWidgetOptions.outerPadding : _layerWidgetOptions.dragTargetHeight,
          thickness: candidateItems.isEmpty ? _layerWidgetOptions.outerPadding : _layerWidgetOptions.dragTargetHeight,
          color: candidateItems.isEmpty ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight,
        );
      },
      onAcceptWithDetails: (final DragTargetDetails<LayerState> details) {
        _appState.changeLayerOrder(state: details.data, newPosition: _appState.layerCount);
      },
    ),);
  }


  @override
  Widget build(final BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,

      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              const MainButtonWidget(
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorDark,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(_layerWidgetOptions.borderRadius), bottomLeft: Radius.circular(_layerWidgetOptions.borderRadius)),
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _appState.hasProjectNotifier,
                    builder: (final BuildContext context, final bool hasProject, final Widget? child) {
                      return hasProject ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
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
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ListenableBuilder(
                              listenable: _appState.layerListChangeNotifier,
                              builder: (final BuildContext context, final Widget? child)
                              {
                                _createWidgetList();
                                return Column(children: _widgetList);
                              },
                            ),
                          ],
                        ),
                      ) : const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              const CanvasOperationsWidget(),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _appState.hasProjectNotifier,
            builder: (final BuildContext context, final bool hasProject, final Widget? child) {
              return hasProject ? ValueListenableBuilder<bool>(
                valueListenable: _appState.layerSettingsVisibleNotifier,
                builder: (final BuildContext contextS, final bool showLayerOptions, final Widget? childS) {
                  Widget settingsWidget = const SizedBox.shrink();
                  final LayerState? currentLayer = _appState.getSelectedLayer();
                  if (currentLayer != null)
                  {
                    if (currentLayer.runtimeType == DrawingLayerState)
                    {
                      final DrawingLayerState drawingLayer = currentLayer as DrawingLayerState;
                      drawingLayer.settings.editStarted = true;
                      drawingLayer.settings.hasChanges = false;
                      settingsWidget = DrawingLayerSettingsWidget(layer: drawingLayer,);
                    }
                    else if (currentLayer.runtimeType == ShadingLayerState)
                    {
                      final ShadingLayerState shadingLayer = currentLayer as ShadingLayerState;
                      shadingLayer.settings.editStarted = true;
                      shadingLayer.settings.hasChanges = false;
                      settingsWidget = ShadingLayerSettingsWidget(settings: shadingLayer.settings);
                    }
                  }

                  return IgnorePointer(
                    ignoring: !showLayerOptions,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      offset: !showLayerOptions ? const Offset(1.0, 0.0) : Offset.zero,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            border: Border(
                              left: BorderSide(color: Theme.of(context).primaryColorLight, width: _layerWidgetOptions.borderWidth,),
                              bottom: BorderSide(color: Theme.of(context).primaryColorLight, width: _layerWidgetOptions.borderWidth,),
                              top: BorderSide(color: Theme.of(context).primaryColorLight, width: _layerWidgetOptions.borderWidth,),

                            ),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(_layerWidgetOptions.borderRadius), bottomLeft: Radius.circular(_layerWidgetOptions.borderRadius)),
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("LAYER SETTINGS", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center,),
                              ),
                              settingsWidget,
                              Tooltip(
                                waitDuration: AppState.toolTipDuration,
                                message: "Close",
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: IconButton.outlined(
                                    onPressed: () {
                                      _appState.layerSettingsVisible = false;
                                      if (currentLayer != null)
                                      {
                                        if (currentLayer.runtimeType == DrawingLayerState)
                                        {
                                          final DrawingLayerState drawingLayer = currentLayer as DrawingLayerState;
                                          drawingLayer.settings.editStarted = false;
                                          if (drawingLayer.settings.hasChanges)
                                          {
                                            GetIt.I.get<HistoryManager>().addState(appState: _appState, identifier: HistoryStateTypeIdentifier.layerSettingsChange);
                                            drawingLayer.settings.hasChanges = false;
                                          }
                                        }
                                        else if (currentLayer.runtimeType == ShadingLayerState)
                                        {
                                          final ShadingLayerState shadingLayer = currentLayer as ShadingLayerState;
                                          shadingLayer.settings.editStarted = false;
                                          if (shadingLayer.settings.hasChanges)
                                          {
                                            GetIt.I.get<HistoryManager>().addState(appState: _appState, identifier: HistoryStateTypeIdentifier.layerSettingsChange);
                                            shadingLayer.settings.hasChanges = false;
                                          }
                                        }
                                      }
                                    },
                                    icon: const FaIcon(FontAwesomeIcons.arrowRightLong,),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ) : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

}
