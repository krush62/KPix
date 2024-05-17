import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/models.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:kpix/widgets/color_chooser_widget.dart';
import 'package:kpix/widgets/color_ramp_row_widget.dart';

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
  final AppState appState;
  final PaletteWidgetOptions paletteOptions;
  final OverlayEntrySubMenuOptions overlayEntryOptions;
  final ColorChooserWidgetOptions colorChooserWidgetOptions;

  const PaletteWidget(
    {
      super.key,
      required this.appState,
      required this.paletteOptions,
      required this.overlayEntryOptions,
      required this.colorChooserWidgetOptions,
    }
  );

  @override
  State<PaletteWidget> createState() => _PaletteWidgetState();
}

class _PaletteWidgetState extends State<PaletteWidget>
{
  late OverlayEntry loadMenu;
  late OverlayEntry saveMenu;
  late OverlayEntry colorChooser;
  final LayerLink loadMenulayerLink = LayerLink();
  final LayerLink saveMenulayerLink = LayerLink();
  bool loadMenuVisible = false;
  bool saveMenuVisible = false;
  bool colorChooserVisible = false;

  @override
  void initState()
  {
    super.initState();
    loadMenu = OverlayEntries.getLoadMenu(
        onDismiss: _closeAllMenus,
        layerLink: loadMenulayerLink,
        options: widget.overlayEntryOptions,
        onLoadFile: _loadFile,
        onLoadPalette: _loadPalette,
    );
    saveMenu = OverlayEntries.getSaveMenu(
      onDismiss: _closeAllMenus,
      layerLink: saveMenulayerLink,
      options: widget.overlayEntryOptions,
      onSaveFile: _saveFile,
      onSavePalette: _savePalette,
    );

    colorChooser = OverlayEntries.getColorChooser(
        onDismiss: _closeAllMenus,
        onSelected: _colorSelected,
        options: widget.colorChooserWidgetOptions,
    );

  }


  void _colorSelected(final Color c)
  {
    print("COLOR SELCTED: " + c.toString());
  }

  void _closeAllMenus()
  {
    if (loadMenuVisible)
    {
      loadMenu.remove();
      loadMenuVisible = false;
    }

    if (saveMenuVisible)
    {
      saveMenu.remove();
      saveMenuVisible = false;
    }

    if (colorChooserVisible)
    {
      colorChooser.remove();
      colorChooserVisible = false;
    }

  }

  void _loadPressed()
  {
    if (!loadMenuVisible)
    {
      Overlay.of(context).insert(loadMenu);
      loadMenuVisible = true;
    }
  }

  void _loadFile()
  {
    print("Load File");
    _closeAllMenus();
  }

  void _loadPalette()
  {
    print("Load Palette");
    _closeAllMenus();
}

  void _savePressed()
  {
    if (!saveMenuVisible)
    {
      Overlay.of(context).insert(saveMenu);
      saveMenuVisible = true;
    }
  }

  void _saveFile()
  {
    print("Save File");
    _closeAllMenus();
  }

  void _savePalette()
  {
    print("Save Palette");
    _closeAllMenus();
  }

  void _settingsPressed()
  {
    if(!colorChooserVisible)
    {
      Overlay.of(context).insert(colorChooser);
      colorChooserVisible = true;
    }
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
          padding: EdgeInsets.all(widget.paletteOptions.padding),
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
                  padding: EdgeInsets.only(right: widget.paletteOptions.padding / 2.0),
                  child: CompositedTransformTarget(
                    link: loadMenulayerLink,
                    child: IconButton.outlined(
                      color: Theme.of(context).primaryColorLight,
                      icon:  FaIcon(
                        FontAwesomeIcons.folderOpen,
                        size: widget.paletteOptions.topIconSize,
                      ),
                      onPressed: _loadPressed,
                    ),
                  ),
                )
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.only(left: widget.paletteOptions.padding / 2.0, right: widget.paletteOptions.padding / 2.0),
                  child: CompositedTransformTarget(
                    link: saveMenulayerLink,
                    child: IconButton.outlined(
                      color: Theme.of(context).primaryColorLight,
                      icon:  FaIcon(
                        FontAwesomeIcons.floppyDisk,
                        size: widget.paletteOptions.topIconSize,
                      ),
                      onPressed: _savePressed,
                    ),
                  ),
                )
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.only(left: widget.paletteOptions.padding / 2.0),
                  child: IconButton.outlined(
                    color: Theme.of(context).primaryColorLight,
                    icon:  FaIcon(
                      FontAwesomeIcons.gear,
                      size: widget.paletteOptions.topIconSize,
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
                      padding: EdgeInsets.all(widget.paletteOptions.padding / 2.0),
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
                padding: EdgeInsets.all(widget.paletteOptions.padding,),
                color: Theme.of(context).primaryColor,
                child: Column(
                  children: [
                    Container (
                      constraints: BoxConstraints(
                        minHeight: widget.paletteOptions.selectedColorHeightMin,
                        maxHeight: widget.paletteOptions.selectedColorHeightMax
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).primaryColorLight,
                          width: widget.paletteOptions.padding / 4,
                        ),
                        color: color,
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            widget.paletteOptions.padding
                          )
                        )
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: widget.paletteOptions.padding),
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