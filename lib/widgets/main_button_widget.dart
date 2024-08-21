/*
 * KPix
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/history_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/widgets/export_widget.dart';
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
  late KPixOverlay _loadMenu;
  late KPixOverlay _saveMenu;
  late KPixOverlay _saveLoadWarningDialog;
  late KPixOverlay _paletteWarningDialog;
  late KPixOverlay _exportDialog;
  late KPixOverlay _aboutDialog;
  late KPixOverlay _preferencesDialog;
  final LayerLink _loadMenuLayerLink = LayerLink();
  final LayerLink _saveMenuLayerLink = LayerLink();
  final MainButtonWidgetOptions _options = GetIt.I.get<PreferenceManager>().mainButtonWidgetOptions;

  @override
  void initState()
  {
    super.initState();
    _loadMenu = OverlayEntries.getLoadMenu(
      onDismiss: _closeAllMenus,
      layerLink: _loadMenuLayerLink,
      onNewFile: _newFile,
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
    _saveLoadWarningDialog = OverlayEntries.getThreeButtonDialog(
      onYes: _saveLoadWarningYes,
      onNo: _saveLoadWarningNo,
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
    _exportDialog = OverlayEntries.getExportDialog(
      onDismiss: _closeAllMenus,
      onAccept: _exportFilePressed,
      canvasSize: _appState.canvasSize);
    _aboutDialog = OverlayEntries.getAboutDialog(
      onDismiss: _closeAllMenus,
      canvasSize: _appState.canvasSize);
    _preferencesDialog = OverlayEntries.getPreferencesDialog(
      onDismiss: _reloadPreferences,
      onAccept: _savePreferencesPressed
    );
  }

  void _exportFilePressed({required final ExportData exportData, required final ExportTypeEnum exportType})
  {
    FileHandler.exportFile(exportData: exportData, exportType: exportType).then((final String? fName) {_exportToTempFinished(fileName: fName);});
  }

  void _exportToTempFinished({required final String? fileName})
  {
    if (fileName != null && fileName.isNotEmpty)
    {
        _appState.showMessage(text: "Exported to: $fileName");
    }
    else
    {
      _appState.showMessage(text: "Error exporting file");
    }
    _closeAllMenus();
  }

  void _closeAllMenus()
  {
    _loadMenu.hide();
    _saveMenu.hide();
    _saveLoadWarningDialog.hide();
    _paletteWarningDialog.hide();
    _exportDialog.hide();
    _aboutDialog.hide();
    _preferencesDialog.hide();
  }

  void _newFile()
  {
    _appState.hasProjectNotifier.value = false;
    _closeAllMenus();
  }

  void _loadPressed()
  {
    _loadMenu.show(context: context);
  }

  void _loadFile()
  {
    if (_appState.hasChanges.value)
    {
      _saveLoadWarningDialog.show(context: context);
    }
    else
    {
      FileHandler.loadFilePressed();
      _closeAllMenus();
    }
  }

  void _saveLoadWarningYes()
  {
    FileHandler.saveFilePressed(finishCallback: _saveBeforeLoadFinished);
  }

  void _saveLoadWarningNo()
  {
    _saveBeforeLoadFinished();
  }

  void _saveBeforeLoadFinished()
  {
    FileHandler.loadFilePressed();
    _closeAllMenus();
  }


  void _loadPalette()
  {
    _paletteWarningDialog.show(context: context);
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
    _saveMenu.show(context: context);
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
    _exportDialog.show(context: context);
  }


  void _savePalette()
  {
    FileHandler.savePalettePressed();
    _closeAllMenus();
  }

  void _settingsPressed()
  {
    _preferencesDialog.show(context: context);
  }

  void _questionPressed()
  {
    _aboutDialog.show(context: context);
  }

  void _undoPressed()
  {
    _appState.undoPressed();
  }

  void _redoPressed()
  {
    _appState.redoPressed();
  }

  void _savePreferencesPressed()
  {
    GetIt.I.get<PreferenceManager>().saveUserPrefs().then((void _){_closeAllMenus();});
  }

  void _reloadPreferences()
  {
    GetIt.I.get<PreferenceManager>().loadPreferences().then((void _){_closeAllMenus();});
  }


  @override
  Widget build(final BuildContext context) {
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
                    child: Tooltip(
                      message: "Open...",
                      waitDuration: AppState.toolTipDuration,
                      child: IconButton.outlined(
                        color: Theme.of(context).primaryColorLight,
                        icon:  FaIcon(
                          FontAwesomeIcons.folderOpen,
                          size: _options.menuIconSize,
                        ),
                        onPressed: _loadPressed,
                      ),
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
                    child: Tooltip(
                      message: "Save...",
                      waitDuration: AppState.toolTipDuration,
                      child: IconButton.outlined(
                        color: Theme.of(context).primaryColorLight,
                        icon:  FaIcon(
                          FontAwesomeIcons.floppyDisk,
                          size: _options.menuIconSize,
                        ),
                        onPressed: _savePressed,
                      ),
                    ),
                  ),
                )
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.only(left: _options.padding / 2.0),
                  child: Tooltip(
                    message: "Preferences",
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      color: Theme.of(context).primaryColorLight,
                      icon:  FaIcon(
                        FontAwesomeIcons.gear,
                        size: _options.menuIconSize,
                      ),
                      onPressed: _settingsPressed,
                    ),
                  ),
                )
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.only(left: _options.padding / 2.0),
                  child: Tooltip(
                    message: "About",
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      color: Theme.of(context).primaryColorLight,
                      icon:  FaIcon(
                        FontAwesomeIcons.question,
                        size: _options.menuIconSize,
                      ),
                      onPressed: _questionPressed,
                    ),
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
                      return Tooltip(
                        message: "Undo",
                        waitDuration: AppState.toolTipDuration,
                        child: IconButton.outlined(
                          color: Theme.of(context).primaryColorLight,
                          icon:  FaIcon(
                            FontAwesomeIcons.rotateLeft,
                            size: _options.menuIconSize,
                          ),
                          onPressed: hasUndo ? _undoPressed : null,
                        ),
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
                      return Tooltip(
                        message: "Redo",
                        waitDuration: AppState.toolTipDuration,
                        child: IconButton.outlined(
                          color: Theme.of(context).primaryColorLight,
                          icon:  FaIcon(
                            FontAwesomeIcons.rotateRight,
                            size: _options.menuIconSize,
                          ),
                          onPressed: hasRedo ? _redoPressed : null,
                        ),
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