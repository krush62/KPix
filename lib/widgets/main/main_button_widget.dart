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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/main.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/image_importer.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/file/import_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

class MainButtonWidgetOptions
{
  final double padding;
  final double menuIconSize;
  final double dividerSize;

  MainButtonWidgetOptions({
    required this.padding ,
    required this.menuIconSize,
    required this.dividerSize,
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
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  late KPixOverlay _loadMenu;
  late KPixOverlay _saveMenu;
  late KPixOverlay _saveLoadWarningDialog;
  late KPixOverlay _saveImportWarningDialog;
  late KPixOverlay _exportDialog;
  late KPixOverlay _aboutDialog;
  late KPixOverlay _preferencesDialog;
  late KPixOverlay _saveAsDialog;
  late KPixOverlay _projectManagerDialog;
  late KPixOverlay _importDialog;
  late KPixOverlay _importLoadingDialog;
  late KPixOverlay _exportLoadingDialog;
  final LayerLink _loadMenuLayerLink = LayerLink();
  final LayerLink _saveMenuLayerLink = LayerLink();
  final MainButtonWidgetOptions _options = GetIt.I.get<PreferenceManager>().mainButtonWidgetOptions;

  @override
  void initState()
  {
    super.initState();
    _loadMenu = getLoadMenu(
      onDismiss: _closeAllMenus,
      layerLink: _loadMenuLayerLink,
      onNewFile: _newFile,
      onLoadFile: _loadFile,
      onImportFile: _importFile,
    );
    _saveMenu = getSaveMenu(
      onDismiss: _closeAllMenus,
      layerLink: _saveMenuLayerLink,
      onSaveFile: _saveFile,
      onSaveAsFile: _saveAsFile,
      onExportFile: _exportFile,
    );
    _saveLoadWarningDialog = getThreeButtonDialog(
      onYes: _saveLoadWarningYes,
      onNo: _saveLoadWarningNo,
      onCancel: _closeAllMenus,
      outsideCancelable: false,
      message: "There are unsaved changes, do you want to save first?",
    );
    _saveImportWarningDialog = getThreeButtonDialog(
        onYes: _saveImportWarningYes,
        onNo: _saveImportWarningNo,
        onCancel: _closeAllMenus,
        outsideCancelable: false,
        message: "There are unsaved changes, do you want to save first?",
    );
    _projectManagerDialog = getProjectManagerDialog(
      onDismiss: _closeAllMenus,
      onSave: _saveFile,
      onLoad: _fileLoaded,
    );
    _exportDialog = getExportDialog(
      onDismiss: _closeAllMenus,
      onAcceptImage: _exportImagePressed,
      onAcceptAnimation: _exportAnimationPressed,
      onAcceptPalette: _paletteSavePressed,);
    _aboutDialog = getAboutDialog(
      onDismiss: _closeAllMenus,
      canvasSize: _appState.canvasSize,);
    _preferencesDialog = getPreferencesDialog(
      onDismiss: _reloadPreferences,
      onAccept: _savePreferencesPressed,
    );
    _saveAsDialog = getSaveAsDialog(
        onDismiss: _closeAllMenus,
        onAccept: ({required final Function()? callback, required final String fileName}) {
          _closeAllMenus();
          saveFilePressed(fileName: fileName, finishCallback: callback);
        },
    );
    _importDialog = getImportDialog(
      onDismiss: _closeAllMenus,
      onAcceptImage: _importImage,
    );

    _importLoadingDialog = getLoadingDialog(message: "Importing Image...");
    _exportLoadingDialog = getLoadingDialog(message: "Exporting...");


    _hotkeyManager.addListener(func: _loadFile, action: HotkeyAction.generalOpen);
    _hotkeyManager.addListener(func: _saveFile, action: HotkeyAction.generalSave);
    _hotkeyManager.addListener(func: _saveAsFile, action: HotkeyAction.generalSaveAs);
    _hotkeyManager.addListener(func: _newFile, action: HotkeyAction.generalNew);
    _hotkeyManager.addListener(func: _undoPressed, action: HotkeyAction.generalUndo);
    _hotkeyManager.addListener(func: _redoPressed, action: HotkeyAction.generalRedo);
    _hotkeyManager.addListener(func: _exportFile, action: HotkeyAction.generalExport);

    KPixApp.saveCallbackFunc = _saveFile;
    KPixApp.openCallbackFunc = _loadFile;

  }

  void _exportImagePressed({required final ImageExportData exportData, required final ImageExportType exportType})
  {
    _exportLoadingDialog.show(context: context);
    exportImage(exportData: exportData, exportType: exportType).then((final String? fName) {_exportFinished(fileName: fName);});
  }

  void _exportAnimationPressed({required final AnimationExportData exportData, required final AnimationExportType exportType})
  {
    _exportLoadingDialog.show(context: context);
    exportAnimation(exportData: exportData, exportType: exportType).then((final String? fName) {_exportFinished(fileName: fName);});
  }

  void _exportFinished({required final String? fileName})
  {
    if (fileName != null && fileName.isNotEmpty)
    {
      _appState.showMessage(text: "Exported to: $fileName");
      if (!kIsWeb && Platform.isAndroid)
      {
        const MethodChannel channel = MethodChannel('media_scanner');
        channel.invokeMethod('refreshGallery', <String, String>{"path": fileName});
      }
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
    _exportDialog.hide();
    _aboutDialog.hide();
    _preferencesDialog.hide();
    _saveAsDialog.hide();
    _projectManagerDialog.hide();
    _saveImportWarningDialog.hide();
    _importDialog.hide();
    _importLoadingDialog.hide();
    _exportLoadingDialog.hide();
  }

  void _newFile()
  {
    _appState.hasProjectNotifier.value = false;
    _closeAllMenus();
  }

  void _newOpenPressed()
  {
    _loadMenu.show(context: context);
  }

  void _loadFile({final Function()? callback})
  {
    if (kIsWeb)
    {
      if (_appState.hasChanges.value)
      {
        _saveLoadWarningDialog.show(context: context);
      }
      else
      {
        loadFilePressed(finishCallback: callback);
        _closeAllMenus();
      }
    }
    else
    {
      _projectManagerDialog.show(context: context, callbackFunction: callback);
    }
  }

  void _importFile()
  {
    if (_appState.hasChanges.value)
    {
      _saveImportWarningDialog.show(context: context);
    }
    else
    {
      _saveBeforeImportFinished();
    }
  }

  void _saveImportWarningYes()
  {
    _saveFile(callback: _saveBeforeImportFinished);
  }

  void _saveImportWarningNo()
  {
    _saveBeforeImportFinished();
  }

  void _saveBeforeImportFinished()
  {
    _importDialog.show(context: context);
  }

  void _saveLoadWarningYes()
  {
    _saveFile(callback: _saveBeforeLoadFinished);
  }

  void _saveLoadWarningNo()
  {
    _saveBeforeLoadFinished();
  }

  void _saveBeforeLoadFinished()
  {
    loadFilePressed();
    _closeAllMenus();
  }

  void _fileLoaded()
  {
    if (_projectManagerDialog.closeCallback != null)
    {
      _projectManagerDialog.closeCallback!();
      _projectManagerDialog.closeCallback = null;
    }
  }

  void _savePressed()
  {
    _saveMenu.show(context: context);
  }

  void _saveFile({final Function()? callback})
  {
    if (_appState.projectName.value == null)
    {
      _saveAsFile(callback: callback);
    }
    else
    {
      saveFilePressed(fileName: _appState.projectName.value!, finishCallback: callback);
      _closeAllMenus();
    }
  }

  void _saveAsFile({final Function()? callback})
  {
    _saveAsDialog = getSaveAsDialog(
        onDismiss: _closeAllMenus,
        onAccept: ({required final Function()? callback, required final String fileName}) {
          _closeAllMenus();
          saveFilePressed(fileName: fileName, finishCallback: callback);
        },
        callback: callback,
    );
    _saveAsDialog.show(context: context);
  }

  void _exportFile()
  {
    _exportDialog.show(context: context);
  }


  void _paletteSavePressed({required final PaletteExportData saveData, required final PaletteExportType paletteType})
  {
    exportPalettePressed(saveData: saveData, paletteType: paletteType);
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
    GetIt.I.get<PreferenceManager>().saveUserPrefs().then((final void _){
      _reloadPreferences();
      _closeAllMenus();
    });
  }

  void _reloadPreferences()
  {
    GetIt.I.get<PreferenceManager>().updatePreferences().then((final void _){
      _closeAllMenus();
      _appState.repaintNotifier.repaint();
    });
  }

  void _importImage({required final ImportData importData})
  {
    _importLoadingDialog.show(context: context);
    import(importData: importData, currentRamps: _appState.colorRamps).then((final ImportResult result)
    {
      _appState.importFile(importResult: result);
      GetIt.I.get<HotkeyManager>().triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
      _appState.rasterLayersFrame();
      _appState.timeline.layerChangeNotifier.reportChange();
      _closeAllMenus();
    });
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_options.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: CompositedTransformTarget(
                  link: _loadMenuLayerLink,
                  child: Tooltip(
                    message: "New/Open...",
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      icon: const Icon(
                        TablerIcons.folder_open,
                        //size: _options.menuIconSize,
                      ),
                      onPressed: _newOpenPressed,
                    ),
                  ),
                ),
              ),
              SizedBox(width: _options.padding,),
              Expanded(
                child: CompositedTransformTarget(
                  link: _saveMenuLayerLink,
                  child: Tooltip(
                    message: "Save...",
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      icon: const Icon(
                        TablerIcons.device_floppy,
                        //size: _options.menuIconSize,
                      ),
                      onPressed: _savePressed,
                    ),
                  ),
                ),
              ),
              SizedBox(width: _options.padding,),
              Expanded(
                child: Tooltip(
                  message: "Preferences",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    icon: const Icon(
                      TablerIcons.settings,
                      //size: _options.menuIconSize,
                    ),
                    onPressed: _settingsPressed,
                  ),
                ),
              ),
              SizedBox(width: _options.padding,),
              Expanded(
                child: Tooltip(
                  message: "About",
                  waitDuration: AppState.toolTipDuration,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    fit: StackFit.passthrough,
                    children: <Widget>[
                      IconButton.outlined(
                        icon: const Icon(
                          TablerIcons.question_mark,
                          //size: _options.menuIconSize,
                        ),
                        onPressed: _questionPressed,
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _appState.hasUpdateNotifier,
                        builder: (final BuildContext context, final bool hasUpdate, final Widget? child)
                        {
                          if (hasUpdate)
                          {
                            return Align(
                              alignment: Alignment.topRight,
                              child: Text("⬤", textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodySmall!.apply(color: notificationGreen)),
                            );
                          }
                          else
                          {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                  ),
                ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: _options.padding / 2.0),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _historyManager.hasUndo,
                    builder: (final BuildContext context, final bool hasUndo, final Widget? child) {
                      return Tooltip(
                        message: "Undo${_hotkeyManager.getShortcutString(action: HotkeyAction.generalUndo)}",
                        waitDuration: AppState.toolTipDuration,
                        child: IconButton.outlined(
                          icon: const Icon(
                            TablerIcons.arrow_back_up,
                            //size: _options.menuIconSize,
                          ),
                          onPressed: hasUndo ? _undoPressed : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: _options.padding / 2.0),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _historyManager.hasRedo,
                    builder: (final BuildContext context, final bool hasRedo, final Widget? child) {
                      return Tooltip(
                        message: "Redo${_hotkeyManager.getShortcutString(action: HotkeyAction.generalRedo)}",
                        waitDuration: AppState.toolTipDuration,
                        child: IconButton.outlined(
                          icon: const Icon(
                            TablerIcons.arrow_forward_up,
                            //size: _options.menuIconSize,
                          ),
                          onPressed: hasRedo ? _redoPressed : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
