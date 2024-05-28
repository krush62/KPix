import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/layer_widget.dart';
import 'package:kpix/widgets/main_button_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class RightBarWidget extends StatefulWidget
{
  final MainButtonWidgetOptions mainButtonWidgetOptions;
  final OverlayEntrySubMenuOptions overlayEntrySubMenuOptions;
  final LayerWidgetOptions layerWidgetOptions;
  final ValueNotifier<List<LayerState>> layerList;
  final ChangeLayerPositionFn changeLayerPositionFn;
  final AddNewLayerFn addNewLayerFn;
  final LayerDuplicateFn layerDuplicateFn;
  final LayerDeleteFn layerDeleteFn;
  final LayerMergeDownFn layerMergeDownFn;
  final LayerSelectedFn layerSelectedFn;
  const RightBarWidget({
    super.key,
    required this.overlayEntrySubMenuOptions,
    required this.mainButtonWidgetOptions,
    required this.layerWidgetOptions,
    required this.layerList,
    required this.changeLayerPositionFn,
    required this.addNewLayerFn,
    required this.layerDeleteFn,
    required this.layerMergeDownFn,
    required this.layerDuplicateFn,
    required this.layerSelectedFn,
  });

  @override
  State<RightBarWidget> createState() => _RightBarWidgetState();

}

class _RightBarWidgetState extends State<RightBarWidget>
{
  late List<Widget> widgetList;

  @override
  void initState() {
    super.initState();
    _createWidgetList(widget.layerList.value);
  }

  void _createWidgetList(final List<LayerState> states)
  {
    widgetList = [];
    for (int i = 0; i < states.length; i++)
    {
      widgetList.add(DragTarget<LayerState>(
        builder: (context, candidateItems, rejectedItems) {
          return AnimatedContainer(
            height: candidateItems.isEmpty ? widget.layerWidgetOptions.outerPadding : widget.layerWidgetOptions.dragTargetHeight,
            color: candidateItems.isEmpty ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight,
            duration: Duration(milliseconds: widget.layerWidgetOptions.dragTargetShowDuration)
          );
        },
        onAcceptWithDetails: (details) {
          widget.changeLayerPositionFn(details.data, i);
        },
      ));

      widgetList.add(LayerWidget(
        layerState: states[i],
        options: widget.layerWidgetOptions,
        layerSelectedFn: widget.layerSelectedFn,
        menuOptions: widget.overlayEntrySubMenuOptions,
        layerDeleteFn: widget.layerDeleteFn,
        layerDuplicateFn: widget.layerDuplicateFn,
        layerMergeDownFn: widget.layerMergeDownFn,
      ));
    }
    widgetList.add(DragTarget<LayerState>(
      builder: (context, candidateItems, rejectedItems) {
        return Divider(
          height: candidateItems.isEmpty ? widget.layerWidgetOptions.outerPadding : widget.layerWidgetOptions.dragTargetHeight,
          thickness: candidateItems.isEmpty ? widget.layerWidgetOptions.outerPadding : widget.layerWidgetOptions.dragTargetHeight,
          color: candidateItems.isEmpty ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight,
        );
      },
      onAcceptWithDetails: (details) {
        widget.changeLayerPositionFn(details.data, states.length);
      },
    ));
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,

      child: Column(
        children: [
          MainButtonWidget(
            options: widget.mainButtonWidgetOptions,
            overlayEntrySubMenuOptions: widget.overlayEntrySubMenuOptions,
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
                      padding: EdgeInsets.only(top: widget.layerWidgetOptions.outerPadding, left: widget.layerWidgetOptions.outerPadding, right: widget.layerWidgetOptions.outerPadding),
                      child: IconButton(
                        onPressed: widget.addNewLayerFn,
                        icon: const FaIcon(FontAwesomeIcons.plus)
                      ),
                    ),
                    ValueListenableBuilder<List<LayerState>>(
                      valueListenable: widget.layerList,
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