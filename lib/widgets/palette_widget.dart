import 'package:flutter/material.dart';
import 'package:kpix/models.dart';

class PaletteWidgetOptions
{
  final double padding;
  final double columnCountResizeFactor;
  final double topiconSize;
  final double addIconSize;

  PaletteWidgetOptions({
    required this.padding,
    required this.columnCountResizeFactor,
    required this.topiconSize,
    required this.addIconSize
  });



//PaletteWidgetOptions(this.padding, this.columnCountResizeFactor, this.topiconSize, this.addIconSize);

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
                color: Theme
                    .of(context)
                    .secondaryHeaderColor,
              ),
            child:  Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 1,
                  child: IconButton.outlined(
                    icon:  Icon(
                      Icons.open_in_browser_outlined,
                      size: widget.options.topiconSize,
                    ),
                    onPressed: _loadPalettePressed,
                  )
                ),
                Expanded(
                    flex: 1,
                    child: IconButton.outlined(
                      icon:  Icon(
                        Icons.save_alt,
                        size: widget.options.topiconSize,
                      ),
                      onPressed: _savePalettePressed,
                    )
                ),
                Expanded(
                    flex: 1,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: widget._indexed,
                      builder: (BuildContext context, bool value, child)
                      {
                        return IconButton.outlined(
                          isSelected: value,
                          icon:  Icon(
                            Icons.lock,
                            size: widget.options.topiconSize,
                          ),
                          onPressed: _switchIndexedPressed,
                        );
                      })

                ),
              ],
            )
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
              ),
              child: Padding(
                padding: EdgeInsets.all(widget.options.padding / 2.0),
                child: GridView.count(
                  padding: EdgeInsets.zero,
                  crossAxisCount: (constraints.maxWidth / widget.options.columnCountResizeFactor).round(),
                  crossAxisSpacing: widget.options.padding / 2.0,
                  mainAxisSpacing: widget.options.padding / 2.0,
                  childAspectRatio: 1,
                  scrollDirection: Axis.vertical,
                  children: [
                    ...widget.appState.colorList.value,
                     IconButton(
                      icon: Icon(
                        Icons.add,
                        size: widget.options.addIconSize,
                      ),
                      onPressed: null,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      );
    });
  }
  
}