import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/history_manager.dart';
import 'package:kpix/models/app_state.dart';
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
  final AppState _appState = GetIt.I.get<AppState>();
  final HistoryManager _historyManager = GetIt.I.get<HistoryManager>();
  late OverlayEntry _loadMenu;
  late OverlayEntry _saveMenu;
  final LayerLink _loadMenulayerLink = LayerLink();
  final LayerLink _saveMenulayerLink = LayerLink();
  bool _loadMenuVisible = false;
  bool _saveMenuVisible = false;
  final MainButtonWidgetOptions _options = GetIt.I.get<PreferenceManager>().mainButtonWidgetOptions;

  @override
  void initState()
  {
    super.initState();
    _loadMenu = OverlayEntries.getLoadMenu(
      onDismiss: _closeAllMenus,
      layerLink: _loadMenulayerLink,
      onLoadFile: _loadFile,
      onLoadPalette: _loadPalette,
    );
    _saveMenu = OverlayEntries.getSaveMenu(
      onDismiss: _closeAllMenus,
      layerLink: _saveMenulayerLink,
      onSaveFile: _saveFile,
      onSavePalette: _savePalette,
    );
  }


  void _closeAllMenus()
  {
    if (_loadMenuVisible)
    {
      _loadMenu.remove();
      _loadMenuVisible = false;
    }

    if (_saveMenuVisible)
    {
      _saveMenu.remove();
      _saveMenuVisible = false;
    }
  }

  void _loadPressed()
  {
    if (!_loadMenuVisible)
    {
      Overlay.of(context).insert(_loadMenu);
      _loadMenuVisible = true;
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
    if (!_saveMenuVisible)
    {
      Overlay.of(context).insert(_saveMenu);
      _saveMenuVisible = true;
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

  void _undoPressed()
  {
    _appState.undoPressed();
  }

  void _redoPressed()
  {
    _appState.redoPressed();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(_options.padding),
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
                      padding: EdgeInsets.only(right: _options.padding / 2.0),
                      child: CompositedTransformTarget(
                        link: _loadMenulayerLink,
                        child: IconButton.outlined(
                          color: Theme.of(context).primaryColorLight,
                          icon:  FaIcon(
                            FontAwesomeIcons.folderOpen,
                            size: _options.menuIconSize,
                          ),
                          onPressed: _loadPressed,
                        ),
                      ),
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(left: _options.padding / 2.0, right: _options.padding / 2.0),
                      child: CompositedTransformTarget(
                        link: _saveMenulayerLink,
                        child: IconButton.outlined(
                          color: Theme.of(context).primaryColorLight,
                          icon:  FaIcon(
                            FontAwesomeIcons.floppyDisk,
                            size: _options.menuIconSize,
                          ),
                          onPressed: _savePressed,
                        ),
                      ),
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(left: _options.padding / 2.0),
                      child: IconButton.outlined(
                        color: Theme.of(context).primaryColorLight,
                        icon:  FaIcon(
                          FontAwesomeIcons.gear,
                          size: _options.menuIconSize,
                        ),
                        onPressed: _settingsPressed,
                      ),
                    )
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: _options.padding, bottom: _options.padding),
              child: Divider(
                color: Theme.of(context).primaryColorDark,
                height: _options.dividerSize,
                thickness: _options.dividerSize,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(right: _options.padding / 2.0),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _historyManager.hasUndo,
                        builder: (final BuildContext context, final bool hasUndo, child) {
                          return IconButton.outlined(
                            color: Theme.of(context).primaryColorLight,
                            icon:  FaIcon(
                              FontAwesomeIcons.rotateLeft,
                              size: _options.menuIconSize,
                            ),
                            onPressed: hasUndo ? _undoPressed : null,
                          );
                        },
                      ),
                    )
                ),
                Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(left: _options.padding / 2.0),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _historyManager.hasRedo,
                        builder: (final BuildContext context, final bool hasRedo, child) {
                          return IconButton.outlined(
                            color: Theme.of(context).primaryColorLight,
                            icon:  FaIcon(
                              FontAwesomeIcons.rotateRight,
                              size: _options.menuIconSize,
                            ),
                            onPressed: hasRedo ? _redoPressed : null,
                          );
                        },

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