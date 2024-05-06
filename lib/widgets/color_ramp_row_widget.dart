import 'package:flutter/material.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/color_entry_widget.dart';

class ColorRampRowWidget extends StatefulWidget {
  final List<IdColor>? colorList;
  final ColorSelectedFn colorSelectedFn;
  final AddNewColorFn addNewColorFn;
  final ColorEntryWidgetOptions colorEntryWidgetOptions;
  final AppState appState;
  final List<Widget> widgetList;
  final ColorMovedFn colorMovedFn;

  @override
  State<ColorRampRowWidget> createState() => _ColorRampRowWidgetState();

  const ColorRampRowWidget._(
      {required this.colorList,
      required this.colorSelectedFn,
      required this.addNewColorFn,
      required this.colorEntryWidgetOptions,
      required this.appState,
      required this.colorMovedFn,
      required this.widgetList});

  factory ColorRampRowWidget(
      List<IdColor>? tempColorList,
      ColorSelectedFn tempColorSelectedFn,
      AddNewColorFn tempAddNewColorFn,
      ColorEntryWidgetOptions tempColorEntryWidgetOptions,
      AppState tempAppState,
      ColorMovedFn tempColorMovedFn) {
    List<Widget> tempWidgetList = [];
    if (tempColorList != null) {
      for (IdColor color in tempColorList) {
        tempWidgetList.add(
            ColorEntryDropTargetWidget(
                minSize: tempColorEntryWidgetOptions.minSize,
                maxSize: tempColorEntryWidgetOptions.maxSize,
                width: tempColorEntryWidgetOptions.dragTargetWidth,
                colorMovedFn: tempColorMovedFn));
        tempWidgetList.add(ColorEntryWidget(color, tempAppState,
            tempColorSelectedFn, tempColorEntryWidgetOptions));
      }

      tempWidgetList.add(
          ColorEntryDropTargetWidget(
              minSize: tempColorEntryWidgetOptions.minSize,
              maxSize: tempColorEntryWidgetOptions.maxSize,
              width: tempColorEntryWidgetOptions.dragTargetWidth,
              colorMovedFn: tempColorMovedFn));

      tempWidgetList.add(IconButton(
        icon: Icon(
          Icons.add,
          size: tempColorEntryWidgetOptions.addIconSize,
        ),
        onPressed: () {
          tempAddNewColorFn(tempColorList);
        },
      ));
    } else {
      tempWidgetList.add(Expanded(
          child: Padding(
              padding:
                  EdgeInsets.all(tempColorEntryWidgetOptions.buttonPadding),
              child: IconButton(
                  icon: Icon(
                    Icons.add,
                    size: tempColorEntryWidgetOptions.addIconSize,
                  ),
                  onPressed: () {
                    tempAddNewColorFn(tempColorList);
                  }))));
    }
    return ColorRampRowWidget._(
        colorList: tempColorList,
        colorSelectedFn: tempColorSelectedFn,
        addNewColorFn: tempAddNewColorFn,
        colorEntryWidgetOptions: tempColorEntryWidgetOptions,
        appState: tempAppState,
        colorMovedFn: tempColorMovedFn,
        widgetList: tempWidgetList);
  }

  List<Widget> getChildren() {
    return widgetList;
  }

  void _buildWidgets() {}
}

class _ColorRampRowWidgetState extends State<ColorRampRowWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget._buildWidgets();
    return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widget.widgetList);
  }
}



class ColorEntryDropTargetWidget extends StatefulWidget {
  final double minSize;
  final double maxSize;
  final double width;
  final ColorMovedFn colorMovedFn;

  const ColorEntryDropTargetWidget(
      {super.key,
      required this.minSize,
      required this.maxSize,
      required this.width,
      required this.colorMovedFn});

  @override
  State<ColorEntryDropTargetWidget> createState() =>
      _ColorEntryDropTargetWidgetState();
}

class _ColorEntryDropTargetWidgetState
    extends State<ColorEntryDropTargetWidget> {
  bool _itemIsAbove = false;

  void _updateItemIsAbove(final bool isAbove) {
    setState(() {
      _itemIsAbove = isAbove;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<IdColor>(
      builder: (BuildContext context, List<dynamic> accepted,
          List<dynamic> rejected) {
        return _itemIsAbove
            ? Container(
                color: Theme.of(context).primaryColor,
                width: widget.width,
                constraints: BoxConstraints(
                    minHeight: widget.minSize, maxHeight: widget.maxSize))
            : Container(
                color: Colors.transparent,
                width: widget.width,
                constraints: BoxConstraints(
                    minHeight: widget.minSize, maxHeight: widget.maxSize));
      },
      onWillAcceptWithDetails: (value) {
        _updateItemIsAbove(true);
        return true;
      },
      onLeave: (value) {
        _updateItemIsAbove(false);
      },
      onAcceptWithDetails: (value) {
        _updateItemIsAbove(false);
        widget.colorMovedFn(value.data, widget);
      },
    );
  }
}
