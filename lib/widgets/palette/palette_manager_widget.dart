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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/palette/palette_manager_entry_widget.dart';
import 'package:path/path.dart' as p;

class PaletteManagerOptions
{
  final int colCount;
  final double entryAspectRatio;
  PaletteManagerOptions({required this.colCount, required this.entryAspectRatio});
}

class PaletteManagerWidget extends StatefulWidget
{
  final Function() dismiss;
  const PaletteManagerWidget({super.key, required this.dismiss});

  @override
  State<PaletteManagerWidget> createState() => _PaletteManagerWidgetState();
}

class _PaletteManagerWidgetState extends State<PaletteManagerWidget>
{
  final OverlayEntryAlertDialogOptions _alertOptions = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final PaletteManagerOptions _options = GetIt.I.get<PreferenceManager>().paletteManagerOptions;
  final ValueNotifier<List<PaletteManagerEntryWidget>> _paletteEntries = ValueNotifier<List<PaletteManagerEntryWidget>>(<PaletteManagerEntryWidget>[]);
  final ValueNotifier<PaletteManagerEntryWidget?> _selectedWidget = ValueNotifier<PaletteManagerEntryWidget?>(null);

  late KPixOverlay _paletteWarningDialog;
  late KPixOverlay _addPaletteDialog;
  late KPixOverlay _deleteWarningDialog;

  @override
  void initState()
  {
    super.initState();
    _paletteWarningDialog = getThreeButtonDialog(
        onYes: _paletteWarningYes,
        onNo: _paletteWarningNo,
        onCancel: _closeWarning,
        outsideCancelable: false,
        message: "Do you want to remap the existing colors (all pixels will be deleted otherwise)?",);
    _addPaletteDialog = getPaletteSaveDialog(
      onAccept: _acceptAddPalette,
      onDismiss: _dismissAddPalette,
    );
    _deleteWarningDialog = getTwoButtonDialog(
        message: "Do you really want to delete this palette?",
        onNo: _deleteWarningNo,
        onYes: _deleteWarningYes,
        outsideCancelable: false,
    );


    _createWidgetList().then((final List<PaletteManagerEntryWidget> pList) {
      _paletteEntries.value = pList;
    });
  }

  void _acceptAddPalette({required final PaletteExportData saveData, required final PaletteExportType paletteType})
  {
    saveCurrentPalette(fileName: saveData.fileName, directory: saveData.directory, extension: saveData.extension).then((final String? fileName) {

      if (fileName == null)
      {
        GetIt.I.get<AppState>().showMessage(text: "Error saving palette!");
      }
      else
      {
        GetIt.I.get<AppState>().showMessage(text: "Palette saved successfully at $fileName.");
        _createWidgetList().then((final List<PaletteManagerEntryWidget> pList) {
          _paletteEntries.value = pList;
        });
      }
    });
    _dismissAddPalette();
  }


  void _dismissAddPalette()
  {
    _addPaletteDialog.hide();
  }

  void _closeWarning()
  {
    _paletteWarningDialog.hide();
  }

  void _paletteWarningYes()
  {
    GetIt.I.get<AppState>().replacePalette(loadPaletteSet: LoadPaletteSet(status: "loading okay", rampData: _selectedWidget.value!.entryData.rampDataList), paletteReplaceBehavior: PaletteReplaceBehavior.remap);
    _closeWarning();
    widget.dismiss();
  }

  void _paletteWarningNo()
  {
    GetIt.I.get<AppState>().replacePalette(loadPaletteSet: LoadPaletteSet(status: "loading okay", rampData: _selectedWidget.value!.entryData.rampDataList), paletteReplaceBehavior: PaletteReplaceBehavior.replace);
    _closeWarning();
    widget.dismiss();
  }

  Future<List<PaletteManagerEntryWidget>> _createWidgetList() async
  {
    final List<PaletteManagerEntryWidget> pList = <PaletteManagerEntryWidget>[];
    //Default Palette
    pList.add(PaletteManagerEntryWidget(selectedWidget: _selectedWidget, entryData: PaletteManagerEntryData(rampDataList: KPalRampData.getDefaultPalette(constraints: GetIt.I.get<PreferenceManager>().kPalConstraints), isLocked: true, path: null, name: "Default")));

    //Asset Palettes
    final List<PaletteManagerEntryData> assetPalettes = await loadPalettesFromAssets();
    for (final PaletteManagerEntryData palData in assetPalettes)
    {
      pList.add(PaletteManagerEntryWidget(selectedWidget: _selectedWidget, entryData: palData));
    }

    //Internal Palettes
    if (!kIsWeb)
    {
      final List<PaletteManagerEntryData> internalPalettes = await loadPalettesFromInternal();
      for (final PaletteManagerEntryData palData in internalPalettes)
      {
        pList.add(PaletteManagerEntryWidget(selectedWidget: _selectedWidget, entryData: palData));
      }
    }

    return pList;
  }

  void _addCurrentPalette()
  {
    _addPaletteDialog.show(context: context);
  }

  void _applyPalette()
  {
    _paletteWarningDialog.show(context: context);
  }

  void _appendPalette()
  {
    GetIt.I.get<AppState>().appendPalette(loadPaletteSet: LoadPaletteSet(status: "loading okay", rampData: _selectedWidget.value!.entryData.rampDataList));
    _closeWarning();
    widget.dismiss();
  }

  void _deletePalettePressed()
  {
    _deleteWarningDialog.show(context: context);
  }

  void _deleteWarningYes()
  {
    if (_selectedWidget.value != null && _selectedWidget.value!.entryData.path != null)
    {
      deleteFile(path: _selectedWidget.value!.entryData.path!).then((final bool success) {
        _fileDeleted(success: success);
      });
    }
    _deleteWarningDialog.hide();
  }

  void _deleteWarningNo()
  {
    _deleteWarningDialog.hide();
  }

  void _fileDeleted({required final bool success})
  {
    if (success)
    {
      _createWidgetList().then((final List<PaletteManagerEntryWidget> pList) {
        _selectedWidget.value = null;
        _paletteEntries.value = pList;
      });
    }
  }

  void _dismissPressed()
  {
    widget.dismiss();
  }

  void _importPalettePressed()
  {
    getPathForKPalFile().then((final String? loadPath) {
      _importFileChosen(path: loadPath);
    });
  }

  void _importFileChosen({required final String? path})
  {
    final AppState appState = GetIt.I.get<AppState>();
    if (path != null && path.isNotEmpty)
    {
      if (path.endsWith(fileExtensionKpal))
      {
        final String fileName = extractFilenameFromPath(path: path);
        final String targetPath = p.join(appState.internalDir, palettesSubDirName, fileName);
        if (!File(targetPath).existsSync())
        {
          File(path).copy(targetPath).then((final File newFile) {
            _importFinished(newFile: newFile);
          });
        }
        else
        {
          appState.showMessage(text: "A palette with the same name already exists!");
        }
      }
      else
      {
        appState.showMessage(text: "Please select a KPal file!");
      }
    }
  }

  void _importFinished({required final File newFile})
  {
    final AppState appState = GetIt.I.get<AppState>();
    if (newFile.existsSync())
    {
      _createWidgetList().then((final List<PaletteManagerEntryWidget> pList) {
        _paletteEntries.value = pList;
      });
      appState.showMessage(text: "Import successful!");
    }
    else
    {
      appState.showMessage(text: "Import failed!");
    }
  }

  @override
  Widget build(final BuildContext context)
  {
    return KPixAnimationWidget(
      constraints: BoxConstraints(
        minHeight: _alertOptions.minHeight,
        minWidth: _alertOptions.minWidth,
        maxHeight: _alertOptions.maxHeight,
        maxWidth: _alertOptions.maxWidth,
      ),
      child: Column(
        children: <Widget>[
          SizedBox(height: _alertOptions.padding),
          Text("PALETTE MANAGER", style: Theme.of(context).textTheme.titleLarge),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark,
                borderRadius: BorderRadius.all(Radius.circular(_alertOptions.borderRadius)),
              ),
              child: ValueListenableBuilder<List<PaletteManagerEntryWidget>>(
                valueListenable: _paletteEntries,
                builder: (final BuildContext context, final List<PaletteManagerEntryWidget> pList, final Widget? child) {
                  return GridView.extent(
                    maxCrossAxisExtent: _alertOptions.maxWidth / _options.colCount,
                    padding: EdgeInsets.all(_alertOptions.padding),
                    childAspectRatio: _options.entryAspectRatio,
                    mainAxisSpacing: _alertOptions.padding,
                    crossAxisSpacing: _alertOptions.padding,
                    children: pList,
                  );
                },
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: Tooltip(
                  waitDuration: AppState.toolTipDuration,
                  message: "Close",
                  child: Padding(
                    padding: EdgeInsets.all(_alertOptions.padding),
                    child: IconButton.outlined(
                      icon: const Icon(
                        TablerIcons.x,
                        //size: _alertOptions.iconSize,
                      ),
                      onPressed: _dismissPressed,
                    ),
                  ),
                ),
              ),
              Expanded(
                  child: Tooltip(
                    message: "Import Palette",
                    waitDuration: AppState.toolTipDuration,
                    child: Padding(
                      padding: EdgeInsets.all(_alertOptions.padding),
                      child: IconButton.outlined(
                        icon: const Icon(
                          TablerIcons.file_import,
                          //size: _alertOptions.iconSize,
                        ),
                        onPressed: kIsWeb ? null : _importPalettePressed,
                      ),
                    ),
                  ),
              ),
              Expanded(
                child: Tooltip(
                  message: "Save Current Palette",
                  waitDuration: AppState.toolTipDuration,
                  child: Padding(
                    padding: EdgeInsets.all(_alertOptions.padding),
                    child: IconButton.outlined(
                      icon: const Icon(
                        TablerIcons.device_floppy,
                        //size: _alertOptions.iconSize,
                      ),
                      onPressed: kIsWeb ? null : _addCurrentPalette,
                    ),
                  ),
                ),
              ),
              Expanded(
                  child: Tooltip(
                    message: "Delete Selected Palette",
                    waitDuration: AppState.toolTipDuration,
                    child: Padding(
                      padding: EdgeInsets.all(_alertOptions.padding),
                      child: ValueListenableBuilder<PaletteManagerEntryWidget?>(
                        valueListenable: _selectedWidget,
                        builder: (final BuildContext context, final PaletteManagerEntryWidget? selWidget, final Widget? child) {
                          return IconButton.outlined(
                            icon: const Icon(
                              TablerIcons.trash,
                              //size: _alertOptions.iconSize,
                            ),
                            onPressed: (selWidget != null && !selWidget.entryData.isLocked) ? _deletePalettePressed : null,
                          );
                        },
                      ),
                    ),
                  ),
              ),
              Expanded(
                child: Tooltip(
                  message: "Append to Current Palette",
                  waitDuration: AppState.toolTipDuration,
                  child: Padding(
                    padding: EdgeInsets.all(_alertOptions.padding),
                    child: ValueListenableBuilder<PaletteManagerEntryWidget?>(
                      valueListenable: _selectedWidget,
                      builder: (final BuildContext context, final PaletteManagerEntryWidget? selWidget, final Widget? child) {
                        return IconButton.outlined(
                          icon: const Icon(
                            TablerIcons.plus,
                            //size: _alertOptions.iconSize,
                          ),
                          onPressed: selWidget != null ? _appendPalette : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Tooltip(
                  message: "Apply Selected Palette",
                  waitDuration: AppState.toolTipDuration,
                  child: Padding(
                    padding: EdgeInsets.all(_alertOptions.padding),
                    child: ValueListenableBuilder<PaletteManagerEntryWidget?>(
                      valueListenable: _selectedWidget,
                      builder: (final BuildContext context, final PaletteManagerEntryWidget? selWidget, final Widget? child) {
                        return IconButton.outlined(
                          icon: const Icon(
                            TablerIcons.check,
                            //size: _alertOptions.iconSize,
                          ),
                          onPressed: selWidget != null ? _applyPalette : null,
                        );
                      },
                    ),
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
