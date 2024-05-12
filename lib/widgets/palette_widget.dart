import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models.dart';
import 'package:kpix/shader_options.dart';
import 'package:kpix/widgets/color_ramp_row_widget.dart';
import 'package:kpix/widgets/shader_widget.dart';

class PaletteWidgetOptions
{
  final double padding;
  final double columnCountResizeFactor;
  final double topIconSize;
  final double selectedColorHeightMin;
  final double selectedColorHeightMax;

  PaletteWidgetOptions({
    required this.padding,
    required this.columnCountResizeFactor,
    required this.topIconSize,
    required this.selectedColorHeightMin,
    required this.selectedColorHeightMax
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

  void _loadPressed()
  {

  }

  void _savePressed()
  {

  }

  void _settingsPressed()
  {

  }

  String _getColorString(final Color c)
  {
    return "${Helper.colorToHSVString(c)}   ${Helper.colorToRGBString(c)}   ${Helper.colorToHexString(c)}";
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: EdgeInsets.only(right: widget.options.padding / 2.0),
                  child: IconButton.outlined(
                    color: Theme.of(context).primaryColorLight,
                    icon:  FaIcon(
                      FontAwesomeIcons.folderOpen,
                      size: widget.options.topIconSize,
                    ),
                    onPressed: _loadPressed,
                  ),
                )
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.only(left: widget.options.padding / 2.0, right: widget.options.padding / 2.0),
                  child: IconButton.outlined(
                    color: Theme.of(context).primaryColorLight,
                    icon:  FaIcon(
                      FontAwesomeIcons.floppyDisk,
                      size: widget.options.topIconSize,
                    ),
                    onPressed: _savePressed,
                  ),
                )
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.only(left: widget.options.padding / 2.0),
                  child: IconButton.outlined(
                    color: Theme.of(context).primaryColorLight,
                    icon:  FaIcon(
                      FontAwesomeIcons.sliders,
                      size: widget.options.topIconSize,
                    ),
                    onPressed: _settingsPressed,
                  ),
                )
              ),
            ],
          )
        ),
        //COLORS
        Expanded(
          child: ValueListenableBuilder<List<ColorRampRowWidget>>(
            valueListenable: widget.appState.colorRampWidgetList,
            builder: (BuildContext context, List<ColorRampRowWidget> widgetRows, child)
            {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorDark,
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
        ),
        
        
        
        
        
        
        ValueListenableBuilder<Color>(
          valueListenable: widget.appState.selectedColor,
          builder: (BuildContext context, Color color, child)
          {
            return Container(
                padding: EdgeInsets.all(widget.options.padding,),
                color: Theme.of(context).primaryColor,
                child: Column(
                  children: [
                    Container (
                      constraints: BoxConstraints(
                        minHeight: widget.options.selectedColorHeightMin,
                        maxHeight: widget.options.selectedColorHeightMax
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).primaryColorLight,
                          width: widget.options.padding / 4,
                        ),
                        color: color,
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            widget.options.padding
                          )
                        )
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: widget.options.padding),
                      child: Text(
                        _getColorString(color),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                )
              );

          }
        ),
      ],
    );
  }
  
}