import 'package:flutter/material.dart';
import 'package:kpix/models.dart';
import 'package:kpix/widgets/color_ramp_row_widget.dart';

class PaletteWidgetOptions
{
  final double padding;
  final double columnCountResizeFactor;
  final double topIconSize;

  PaletteWidgetOptions({
    required this.padding,
    required this.columnCountResizeFactor,
    required this.topIconSize,
  });

}

class PaletteWidget extends StatefulWidget
{
  final ValueNotifier<bool> _indexed = ValueNotifier(true);
  PaletteWidget(
      {
        required this.appState,
        required this.options,
        super.key
      }
  );



  @override
  State<PaletteWidget> createState() => _PaletteWidgetState();
  final AppState appState;
  final PaletteWidgetOptions options;
}

class _PaletteWidgetState extends State<PaletteWidget>
{
  @override
  void initState()
  {
    super.initState();
  }

  void _loadPalettePressed()
  {

  }

  void _savePalettePressed()
  {

  }

  void _switchIndexedPressed()
  {
    widget._indexed.value = !widget._indexed.value;
  }

  @override
  Widget build(BuildContext context) {

    return LayoutBuilder(
        builder: (context, BoxConstraints constraints)
    {
      return Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(widget.options.padding),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            child:  Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, widget.options.padding / 2.0, 0.0),
                    child: IconButton.outlined(
                      color: Theme.of(context).primaryColorLight,
                      icon:  Icon(
                        Icons.open_in_browser_outlined,
                        size: widget.options.topIconSize,
                      ),
                      onPressed: _loadPalettePressed,
                    ),
                  )
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(widget.options.padding / 2.0, 0.0, widget.options.padding / 2.0, 0.0),
                    child: IconButton.outlined(
                      color: Theme.of(context).primaryColorLight,
                      icon:  Icon(
                        Icons.save_alt,
                        size: widget.options.topIconSize,
                      ),
                      onPressed: _savePalettePressed,
                    ),
                  )
                ),
                Expanded(
                  flex: 1,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: widget._indexed,
                    builder: (BuildContext context, bool value, child)
                    {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(widget.options.padding / 2.0, 0.0, widget.options.padding / 2.0, 0.0),
                        child: IconButton.outlined(
                          color: value ? Theme.of(context).primaryColor : Theme.of(context).primaryColorLight,
                          isSelected: value,
                          icon:  Icon(
                            Icons.lock,
                            size: widget.options.topIconSize,
                          ),
                          onPressed: _switchIndexedPressed,
                        ),
                      );
                    }
                  )
                ),
              ],
            )
          ),
          Expanded(
            child: ValueListenableBuilder<List<ColorRampRowWidget>>(
              valueListenable: widget.appState.colorRampWidgetList,
              builder: (BuildContext context, List<ColorRampRowWidget> widgetRows, child)
              {
                String? s = widgetRows[0].colorList?.length.toString();
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                  ),

                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Padding(
                        padding: EdgeInsets.all(widget.options.padding / 2.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ...widgetRows
                          ],
                        )
                    ),
                  )






                );
              }
            )

          )
        ],
      );
    });
  }
  
}