import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/file_handler.dart';
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
  late OverlayEntry _saveWarningDialog;
  late OverlayEntry _paletteWarningDialog;
  final LayerLink _loadMenuLayerLink = LayerLink();
  final LayerLink _saveMenuLayerLink = LayerLink();
  bool _loadMenuVisible = false;
  bool _saveMenuVisible = false;
  bool _saveWarningVisible = false;
  bool _paletteWarningVisible = false;
  final MainButtonWidgetOptions _options = GetIt.I.get<PreferenceManager>().mainButtonWidgetOptions;

  @override
  void initState()
  {
    super.initState();
    _loadMenu = OverlayEntries.getLoadMenu(
      onDismiss: _closeAllMenus,
      layerLink: _loadMenuLayerLink,
      onLoadFile: _loadFile,
      onLoadPalette: _loadPalette,
    );
    _saveMenu = OverlayEntries.getSaveMenu(
      onDismiss: _closeAllMenus,
      layerLink: _saveMenuLayerLink,
      onSaveFile: _saveFile,
      onSaveAsFile: _saveAsFile,
      onExportFile: _exportFile,
      onSavePalette: _savePalette,
    );
    _saveWarningDialog = OverlayEntries.getThreeButtonDialog(
        onYes: _saveWarningYes,
        onNo: _saveWarningNo,
        onCancel: _closeAllMenus,
        outsideCancelable: false,
        message: "There are unsaved changes, do you want to save first?"
    );
    _paletteWarningDialog = OverlayEntries.getThreeButtonDialog(
        onYes: _paletteWarningYes,
        onNo: _paletteWarningNo,
        onCancel: _closeAllMenus,
        outsideCancelable: false,
        message: "Do you want to remap the existing colors (all pixels will be deleted otherwise)?");
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

    if (_saveWarningVisible)
    {
      _saveWarningDialog.remove();
      _saveWarningVisible = false;
    }
    if (_paletteWarningVisible)
    {
      _paletteWarningDialog.remove();
      _paletteWarningVisible = false;
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

  void _loadFile()
  {
    if (_appState.hasChanges.value)
    {
      if (!_saveWarningVisible)
      {
        Overlay.of(context).insert(_saveWarningDialog);
        _saveWarningVisible = true;
      }
    }
    else
    {
      FileHandler.loadFilePressed();
      _closeAllMenus();
    }
  }

  void _saveWarningYes()
  {
    FileHandler.saveFilePressed(finishCallback: _saveBeforeLoadFinished);

  }

  void _saveWarningNo()
  {
    FileHandler.loadFilePressed();
    _closeAllMenus();
  }

  void _saveBeforeLoadFinished()
  {
    FileHandler.loadFilePressed();
    _closeAllMenus();
  }


  void _loadPalette()
  {
    if (!_paletteWarningVisible)
    {
      Overlay.of(context).insert(_paletteWarningDialog);
      _paletteWarningVisible = true;
    }
  }

  void _paletteWarningYes()
  {
    FileHandler.loadPalettePressed(paletteReplaceBehavior: PaletteReplaceBehavior.remap);
    _closeAllMenus();
  }

  void _paletteWarningNo()
  {
    FileHandler.loadPalettePressed(paletteReplaceBehavior: PaletteReplaceBehavior.replace);
    _closeAllMenus();
  }


  void _savePressed()
  {
    if (!_saveMenuVisible)
    {
      Overlay.of(context).insert(_saveMenu);
      _saveMenuVisible = true;
    }
  }

  void _saveFile()
  {
    FileHandler.saveFilePressed();
    _closeAllMenus();
  }

  void _saveAsFile()
  {
    FileHandler.saveFilePressed(forceSaveAs: true);
    _closeAllMenus();
  }

  void _exportFile()
  {
    print("EXPORT");
  }


  void _savePalette()
  {
    FileHandler.savePalettePressed();
    _closeAllMenus();
  }

  //TODO
  void _settingsPressed()
  {
    print("SHOW SETTINGS");
  }

  //TODO
  void _questionPressed()
  {
    print("SHOW QUESTION");
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
                        link: _loadMenuLayerLink,
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
                        link: _saveMenuLayerLink,
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
                Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.only(left: _options.padding / 2.0),
                      child: IconButton.outlined(
                        color: Theme.of(context).primaryColorLight,
                        icon:  FaIcon(
                          FontAwesomeIcons.question,
                          size: _options.menuIconSize,
                        ),
                        onPressed: _questionPressed,
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