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
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history_controller.dart';
import 'package:kpix/models/layer_manager.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/update_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:kpix/util/image_importer.dart';
import 'package:kpix/util/messages.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/file/import_widget.dart';
import 'package:kpix/widgets/overlays/overlay_anchor.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

abstract final class _MainButtonWidgetOptions
{
  static const double padding = 8.0;
  //static const double menuIconSize = 16.0;
  static const double dividerSize = 2.0;
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
  final DocumentState _documentState = GetIt.I.get<DocumentState>();
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

  /// Run once the project manager reports that a file has been loaded.
  ///
  /// Set when the manager is opened on behalf of a caller that wants to know,
  /// consumed by [_fileLoaded], and dropped again if the manager is dismissed
  /// without loading anything.
  Function()? _pendingLoadCallback;
  late KPixOverlay _importDialog;
  late KPixOverlay _importLoadingDialog;
  late KPixOverlay _exportLoadingDialog;
  late KPixOverlay _openLoadingDialog;
  final GlobalKey _loadMenuAnchorKey = GlobalKey();
  final GlobalKey _saveMenuAnchorKey = GlobalKey();

  @override
  void initState()
  {
    super.initState();
    _loadMenu = getLoadMenu(
      onDismiss: _closeAllMenus,
      anchorKey: _loadMenuAnchorKey,
      onNewFile: _newFile,
      onLoadFile: _loadFile,
      onImportFile: _importFile,
    );
    _saveMenu = getSaveMenu(
      onDismiss: _closeAllMenus,
      anchorKey: _saveMenuAnchorKey,
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
      onDismiss: _projectManagerDismissed,
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
      /*canvasSize: _canvasState.canvasSize,*/);
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
    _openLoadingDialog = getLoadingDialog(message: "Opening Image...");


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
      showMessage(text: "Exported to: $fileName");
      if (!kIsWeb && Platform.isAndroid)
      {
        const MethodChannel channel = MethodChannel('media_scanner');
        channel.invokeMethod('refreshGallery', <String, String>{"path": fileName});
      }
    }
    else
    {
      showMessage(text: "Error exporting file");
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
    _openLoadingDialog.hide();
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
        _loadFileWithLoadingDialog(callback: callback);
        _closeAllMenus();
      }
    }
    else
    {
      _pendingLoadCallback = callback;
      _projectManagerDialog.show(context: context);
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
    _loadFileWithLoadingDialog();
    _closeAllMenus();
  }

  void _loadFileWithLoadingDialog({final Function()? callback})
  {
    loadFilePressed(
      finishCallback: () {
        _openLoadingDialog.hide();
        callback?.call();
      },
      loadStartCallback: () {
        _openLoadingDialog.show(context: context);
      },
    );
  }

  void _fileLoaded()
  {
    final Function()? callback = _pendingLoadCallback;
    _pendingLoadCallback = null;
    callback?.call();
  }

  void _projectManagerDismissed()
  {
    //the manager was closed without loading anything, so nobody is owed a call
    _pendingLoadCallback = null;
    _closeAllMenus();
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
    exportPalettePressed(saveData: saveData, paletteType: paletteType).then((final String? path)
    {
      if (path != null)
      {
        showMessage(text: "Exported palette to: $path.");
      }
      else
      {
        showMessage(text: "Error exporting palette file.");
      }
      _closeAllMenus();
    },);

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
    GetIt.I.get<HistoryController>().undoPressed();
  }

  void _redoPressed()
  {
    GetIt.I.get<HistoryController>().redoPressed();
  }

  void _savePreferencesPressed()
  {
    GetIt.I.get<Logger>().i("Saving user preferences");
    _applyProjectDirectoryChange().then((final void _){
      GetIt.I.get<PreferenceManager>().saveUserPrefs().then((final void _){
        _reloadPreferences();
        _closeAllMenus();
      });
    });
  }

  Future<void> _applyProjectDirectoryChange() async
  {
    if (kIsWeb)
    {
      return;
    }
    final BehaviorPreferenceContent behaviorPrefs = GetIt.I.get<PreferenceManager>().behaviorPreferenceContent;
    final String defaultDir = getDefaultProjectsDir(internalDir: GetIt.I.get<AppPaths>().internalDir);
    final bool useCustom = behaviorPrefs.useCustomProjectDirectory.value && behaviorPrefs.customProjectDirectory.value.isNotEmpty;
    final String targetDir = useCustom ? behaviorPrefs.customProjectDirectory.value : defaultDir;
    final String currentDir = GetIt.I.get<AppPaths>().projectsDir;
    if (p.equals(targetDir, currentDir))
    {
      return;
    }

    final KPixOverlay movingDialog = getLoadingDialog(message: "Moving project files...");
    movingDialog.show(context: context);
    final ProjectDirectoryMoveResult moveResult = await moveProjectFiles(sourceDir: currentDir, targetDir: targetDir);
    movingDialog.hide();
    if (moveResult.success)
    {
      GetIt.I.get<AppPaths>().projectsDir = targetDir;
      showMessage(text: "Changed project directory to $targetDir (moved ${moveResult.projectCount} project file(s)).");
      await _handleAllFilesAccessPermission(switchedToCustomDir: useCustom);
    }
    else
    {
      GetIt.I.get<Logger>().w("Project directory was not changed: ${moveResult.message}");
      final bool currentIsCustom = !p.equals(currentDir, defaultDir);
      behaviorPrefs.useCustomProjectDirectory.value = currentIsCustom;
      if (currentIsCustom)
      {
        behaviorPrefs.customProjectDirectory.value = currentDir;
      }
      late final KPixOverlay errorDialog;
      errorDialog = getSingleButtonDialog(onAction: () {errorDialog.hide();}, message: "The project directory was not changed!\n${moveResult.message}");
      if (mounted)
      {
        errorDialog.show(context: context);
      }
    }
  }

  Future<void> _handleAllFilesAccessPermission({required final bool switchedToCustomDir}) async
  {
    if (kIsWeb || !Platform.isAndroid)
    {
      return;
    }
    final bool allFilesAccess = await hasAllFilesAccess();
    KPixOverlay? permissionDialog;
    if (switchedToCustomDir && !allFilesAccess)
    {
      permissionDialog = getAllFilesAccessDialog(
        message: 'Without the "All files access" permission, KPix cannot see project files that were created by other apps (e.g. sync tools) in this directory.\nDo you want to open the system settings to grant the permission?',
      );
    }
    else if (!switchedToCustomDir && allFilesAccess)
    {
      permissionDialog = getAllFilesAccessDialog(
        message: 'The "All files access" permission is not needed for the default project directory.\nDo you want to open the system settings to revoke the permission?',
      );
    }
    if (permissionDialog != null && mounted)
    {
      permissionDialog.show(context: context);
    }
  }

  void _reloadPreferences()
  {
    GetIt.I.get<PreferenceManager>().loadPreferences().then((final void _){
      _closeAllMenus();
      GetIt.I.get<ViewState>().repaintNotifier.repaint();
    });
  }

  void _importImage({required final ImportData importData})
  {
    _importLoadingDialog.show(context: context);
    try
    {
      import(importData: importData, currentRamps: GetIt.I.get<PaletteState>().colorRamps).then((final ImportResult result)
      {
        _appState.importFile(importResult: result);
        GetIt.I.get<HotkeyManager>().triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
        GetIt.I.get<LayerManager>().rasterLayersFrame();
        _documentState.timeline.layerChangeNotifier.reportChange();
      });
    }
    catch (e, s)
    {
      const String failMsg = "Error importing image.";
      showMessage(text: failMsg);
      GetIt.I.get<Logger>().w(failMsg, error: e, stackTrace: s);
    }
    _closeAllMenus();
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_MainButtonWidgetOptions.padding),
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
                child: OverlayAnchor(
                  anchorKey: _loadMenuAnchorKey,
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
              const SizedBox(width: _MainButtonWidgetOptions.padding,),
              Expanded(
                child: OverlayAnchor(
                  anchorKey: _saveMenuAnchorKey,
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
              const SizedBox(width: _MainButtonWidgetOptions.padding,),
              Expanded(
                child: Tooltip(
                  message: "Preferences",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    icon: const Icon(
                      TablerIcons.settings,
                      //size: _MainButtonWidgetOptions.menuIconSize,
                    ),
                    onPressed: _settingsPressed,
                  ),
                ),
              ),
              const SizedBox(width: _MainButtonWidgetOptions.padding,),
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
                          //size: _MainButtonWidgetOptions.menuIconSize,
                        ),
                        onPressed: _questionPressed,
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: GetIt.I.get<UpdateState>().hasUpdateNotifier,
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
            padding: const EdgeInsets.only(top: _MainButtonWidgetOptions.padding, bottom: _MainButtonWidgetOptions.padding),
            child: Divider(
              color: Theme.of(context).primaryColorDark,
              height: _MainButtonWidgetOptions.dividerSize,
              thickness: _MainButtonWidgetOptions.dividerSize,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: _MainButtonWidgetOptions.padding / 2.0),
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
                  padding: const EdgeInsets.only(left: _MainButtonWidgetOptions.padding / 2.0),
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
