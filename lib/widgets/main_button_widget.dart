import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class MainButtonWidgetOptions
{
  final double padding;
  final double menuIconSize;
  final double dividerSize;

  MainButtonWidgetOptions({
   required this.padding ,
    required this.menuIconSize,
    required this.dividerSize
  });
}

class MainButtonWidget extends StatefulWidget
{
  const MainButtonWidget({
    super.key,
  });

  @override
  State<MainButtonWidget> createState() => _MainButtonWidgetState();

}

class _MainButtonWidgetState extends State<MainButtonWidget>
{
  late OverlayEntry loadMenu;
  late OverlayEntry saveMenu;
  final LayerLink loadMenulayerLink = LayerLink();
  final LayerLink saveMenulayerLink = LayerLink();
  bool loadMenuVisible = false;
  bool saveMenuVisible = false;
  MainButtonWidgetOptions options = GetIt.I.get<PreferenceManager>().mainButtonWidgetOptions;

  @override
  void initState()
  {
    super.initState();
    loadMenu = OverlayEntries.getLoadMenu(
      onDismiss: _closeAllMenus,
      layerLink: loadMenulayerLink,
      onLoadFile: _loadFile,
      onLoadPalette: _loadPalette,
    );
    saveMenu = OverlayEntries.getSaveMenu(
      onDismiss: _closeAllMenus,
      layerLink: saveMenulayerLink,
      onSaveFile: _saveFile,
      onSavePalette: _savePalette,
    );
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
  }

  void _loadPressed()
  {
    if (!loadMenuVisible)
    {
      Overlay.of(context).insert(loadMenu);
      loadMenuVisible = true;
    }
  }

  //TODO
  void _loadFile()
  {
    print("Load File");
    _closeAllMenus();
  }

  //TODO
  void _loadPalette()
  {
    print("Load Palette");
    _closeAllMenus();
  }

  //TODO
  void _savePressed()
  {
    if (!saveMenuVisible)
    {
      Overlay.of(context).insert(saveMenu);
      saveMenuVisible = true;
    }
  }

  //TODO
  void _saveFile()
  {
    print("Save File");
    _closeAllMenus();
  }

  //TODO
  void _savePalette()
  {
    print("Save Palette");
    _closeAllMenus();
  }

  //TODO
  void _settingsPressed()
  {
    print("SHOW SETTINGS");
  }

  //TODO
  void _undoPressed()
  {

  }

  //TODO
  void _redoPressed()
  {

  }


  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(options.padding),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
        ),
        child:  Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(right: options.padding / 2.0),
                      child: CompositedTransformTarget(
                        link: loadMenulayerLink,
                        child: IconButton.outlined(
                          color: Theme.of(context).primaryColorLight,
                          icon:  FaIcon(
                            FontAwesomeIcons.folderOpen,
                            size: options.menuIconSize,
                          ),
                          onPressed: _loadPressed,
                        ),
                      ),
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(left: options.padding / 2.0, right: options.padding / 2.0),
                      child: CompositedTransformTarget(
                        link: saveMenulayerLink,
                        child: IconButton.outlined(
                          color: Theme.of(context).primaryColorLight,
                          icon:  FaIcon(
                            FontAwesomeIcons.floppyDisk,
                            size: options.menuIconSize,
                          ),
                          onPressed: _savePressed,
                        ),
                      ),
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(left: options.padding / 2.0),
                      child: IconButton.outlined(
                        color: Theme.of(context).primaryColorLight,
                        icon:  FaIcon(
                          FontAwesomeIcons.gear,
                          size: options.menuIconSize,
                        ),
                        onPressed: _settingsPressed,
                      ),
                    )
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: options.padding, bottom: options.padding),
              child: Divider(
                color: Theme.of(context).primaryColorDark,
                height: options.dividerSize,
                thickness: options.dividerSize,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(right: options.padding / 2.0),
                      child: IconButton.outlined(
                        color: Theme.of(context).primaryColorLight,
                        icon:  FaIcon(
                          FontAwesomeIcons.rotateLeft,
                          size: options.menuIconSize,
                        ),
                        onPressed: _undoPressed,
                      ),
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(left: options.padding / 2.0),
                      child: IconButton.outlined(
                        color: Theme.of(context).primaryColorLight,
                        icon:  FaIcon(
                          FontAwesomeIcons.rotateRight,
                          size: options.menuIconSize,
                        ),
                        onPressed: _redoPressed,
                      ),
                    )
                ),
              ],
            )
          ],
        )
    );
  }

}