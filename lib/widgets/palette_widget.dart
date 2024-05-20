import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/color_names.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:kpix/widgets/color_chooser_widget.dart';
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
  final AppState appState;
  final PaletteWidgetOptions paletteOptions;
  final OverlayEntrySubMenuOptions overlayEntryOptions;
  final ColorChooserWidgetOptions colorChooserWidgetOptions;
  final ColorEntryWidgetOptions colorEntryWidgetOptions;
  final ColorNames colorNames;
  final OverlayEntryAlertDialogOptions alertDialogOptions;
  final KPalConstraints kPalConstraints;
  final KPalWidgetOptions kPalWidgetOptions;
  final ColorSelectedFn colorSelectedFn;
  final ColorRampFn updateRampFn;
  final ColorRampFn deleteRampFn;
  final AddNewRampFn addNewRampFn;


  const PaletteWidget(
    {
      super.key,
      required this.appState,
      required this.paletteOptions,
      required this.overlayEntryOptions,
      required this.colorChooserWidgetOptions,
      required this.colorNames,
      required this.colorEntryWidgetOptions,
      required this.alertDialogOptions,
      required this.kPalConstraints,
      required this.kPalWidgetOptions,
      required this.colorSelectedFn,
      required this.addNewRampFn,
      required this.deleteRampFn,
      required this.updateRampFn
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
  final ValueNotifier<List<ColorRampRowWidget>> colorRampWidgetList = ValueNotifier([]);

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
    print("COLOR SELECTED: " + c.toString());
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
          child: ValueListenableBuilder<List<KPalRampData>>(
            valueListenable: widget.appState.colorRamps,
            builder: (BuildContext context, List<KPalRampData> rampDataSet, child)
            {
              colorRampWidgetList.value = [];
              for (KPalRampData rampData in rampDataSet)
              {
                colorRampWidgetList.value.add(
                    ColorRampRowWidget(
                      rampData: rampData,
                      colorSelectedFn: widget.colorSelectedFn,
                      colorsUpdatedFn: widget.updateRampFn,
                      deleteRowFn: widget.deleteRampFn,
                      colorNames: widget.colorNames,
                      colorEntryWidgetOptions: widget.colorEntryWidgetOptions,
                      appState: widget.appState,
                      alertDialogOptions: widget.alertDialogOptions,
                      kPalConstraints: widget.kPalConstraints,
                      kPalWidgetOptions: widget.kPalWidgetOptions,
                    )
                );
              }
              colorRampWidgetList.value.add(ColorRampRowWidget(
                addNewRampFn: widget.addNewRampFn,
                colorEntryWidgetOptions: widget.colorEntryWidgetOptions,
              ));



              return ValueListenableBuilder<List<ColorRampRowWidget>>(
                  valueListenable: colorRampWidgetList,
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
              );
            }
          )
        ),
      ],
    );
  }
  
}