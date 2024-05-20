import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  final MainButtonWidgetOptions options;
  final OverlayEntrySubMenuOptions overlayEntrySubMenuOptions;
  const MainButtonWidget({
    super.key,
    required this.options,
    required this.overlayEntrySubMenuOptions
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


  @override
  void initState()
  {
    super.initState();
    loadMenu = OverlayEntries.getLoadMenu(
      onDismiss: _closeAllMenus,
      layerLink: loadMenulayerLink,
      options: widget.overlayEntrySubMenuOptions,
      onLoadFile: _loadFile,
      onLoadPalette: _loadPalette,
    );
    saveMenu = OverlayEntries.getSaveMenu(
      onDismiss: _closeAllMenus,
      layerLink: saveMenulayerLink,
      options: widget.overlayEntrySubMenuOptions,
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
    print("SHOW SETTINGS");
  }

  void _undoPressed()
  {

  }

  void _redoPressed()
  {

  }


  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(widget.options.padding),
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
                      padding: EdgeInsets.only(right: widget.options.padding / 2.0),
                      child: CompositedTransformTarget(
                        link: loadMenulayerLink,
                        child: IconButton.outlined(
                          color: Theme.of(context).primaryColorLight,
                          icon:  FaIcon(
                            FontAwesomeIcons.folderOpen,
                            size: widget.options.menuIconSize,
                          ),
                          onPressed: _loadPressed,
                        ),
                      ),
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(left: widget.options.padding / 2.0, right: widget.options.padding / 2.0),
                      child: CompositedTransformTarget(
                        link: saveMenulayerLink,
                        child: IconButton.outlined(
                          color: Theme.of(context).primaryColorLight,
                          icon:  FaIcon(
                            FontAwesomeIcons.floppyDisk,
                            size: widget.options.menuIconSize,
                          ),
                          onPressed: _savePressed,
                        ),
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
                          FontAwesomeIcons.gear,
                          size: widget.options.menuIconSize,
                        ),
                        onPressed: _settingsPressed,
                      ),
                    )
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: widget.options.padding, bottom: widget.options.padding),
              child: Divider(
                color: Theme.of(context).primaryColorDark,
                height: widget.options.dividerSize,
                thickness: widget.options.dividerSize,
              ),
            ),
            Row(
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
                          FontAwesomeIcons.rotateLeft,
                          size: widget.options.menuIconSize,
                        ),
                        onPressed: _undoPressed,
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
                          FontAwesomeIcons.rotateRight,
                          size: widget.options.menuIconSize,
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