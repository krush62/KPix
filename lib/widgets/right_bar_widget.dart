import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/main_button_widget.dart';

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
  late List<Widget> widgetList;
  AppState appState = GetIt.I.get<AppState>();
  LayerWidgetOptions layerWidgetOptions = GetIt.I.get<PreferenceManager>().layerWidgetOptions;

  @override
  void initState() {
    super.initState();
    _createWidgetList(appState.layers.value);
  }

  void _createWidgetList(final List<LayerState> layers)
  {
    widgetList = [];
    for (int i = 0; i < layers.length; i++)
    {
      widgetList.add(DragTarget<LayerState>(
        builder: (context, candidateItems, rejectedItems) {
          return AnimatedContainer(
            height: candidateItems.isEmpty ? layerWidgetOptions.outerPadding : layerWidgetOptions.dragTargetHeight,
            color: candidateItems.isEmpty ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight,
            duration: Duration(milliseconds: layerWidgetOptions.dragTargetShowDuration)
          );
        },
        onAcceptWithDetails: (details) {
          appState.changeLayerOrder(state: details.data, newPosition: i);
        },
      ));

      widgetList.add(LayerWidget(
        layerState: layers[i],
      ));
    }
    widgetList.add(DragTarget<LayerState>(
      builder: (context, candidateItems, rejectedItems) {
        return Divider(
          height: candidateItems.isEmpty ? layerWidgetOptions.outerPadding : layerWidgetOptions.dragTargetHeight,
          thickness: candidateItems.isEmpty ? layerWidgetOptions.outerPadding : layerWidgetOptions.dragTargetHeight,
          color: candidateItems.isEmpty ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight,
        );
      },
      onAcceptWithDetails: (details) {
        appState.changeLayerOrder(state: details.data, newPosition: layers.length);
      },
    ));
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,

      child: Column(
        children: [
          const MainButtonWidget(
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).primaryColorDark,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: layerWidgetOptions.outerPadding, left: layerWidgetOptions.outerPadding, right: layerWidgetOptions.outerPadding),
                      child: IconButton(
                        onPressed: () {appState.addNewLayer(select: true);},
                        icon: const FaIcon(FontAwesomeIcons.plus)
                      ),
                    ),
                    ValueListenableBuilder<List<LayerState>>(
                      valueListenable: appState.layers,
                      builder: (BuildContext context, List<LayerState> states, child)
                      {
                        _createWidgetList(states);
                        return Column(children: widgetList);
                      }
                    ),
                  ],
                ),
              ),

            )
          )
        ],
      )
    );
  }

}