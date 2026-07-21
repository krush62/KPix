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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/file/project_manager_entry_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

class ProjectManagerOptions
{
  final int colCount;
  final double entryAspectRatio;
  final double maxWidth;
  final double maxHeight;
  final int maxFilterTextLength;
  ProjectManagerOptions({required this.colCount, required this.entryAspectRatio, required this.maxWidth, required this.maxHeight, required this.maxFilterTextLength});
}

class ProjectManagerWidget extends StatefulWidget
{
  final Function() dismiss;
  final Function() fileLoad;
  final SaveKnownFileFn saveKnownFileFn;
  const ProjectManagerWidget({super.key, required this.dismiss, required this.saveKnownFileFn, required this.fileLoad});

  @override
  State<ProjectManagerWidget> createState() => _ProjectManagerWidgetState();
}

enum ProjectViewOrder
{
  nameAsc,
  nameDesc,
  lastModifiedAsc,
  lastModifiedDesc,
}

class _ProjectManagerWidgetState extends State<ProjectManagerWidget>
{
  final OverlayEntryAlertDialogOptions _alertOptions = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ProjectManagerOptions _options = GetIt.I.get<PreferenceManager>().projectManagerOptions;
  final List<ProjectManagerEntryWidget> _allFileEntries = <ProjectManagerEntryWidget>[];
  final ValueNotifier<List<ProjectManagerEntryWidget>> _fileEntries = ValueNotifier<List<ProjectManagerEntryWidget>>(<ProjectManagerEntryWidget>[]);
  final ValueNotifier<ProjectManagerEntryWidget?> _selectedWidget = ValueNotifier<ProjectManagerEntryWidget?>(null);
  final ValueNotifier<ProjectViewOrder> _projectViewOrder = ValueNotifier<ProjectViewOrder>(ProjectViewOrder.lastModifiedDesc);
  bool _isLoading = false;

  late KPixOverlay _saveBeforeLoadWarningDialog;
  late KPixOverlay _deleteWarningDialog;
  late KPixOverlay _loadingDialog;

  final ValueNotifier<String> _filterText = ValueNotifier<String>("");
  @override
  void initState()
  {
    super.initState();
    _isLoading = true;
    _saveBeforeLoadWarningDialog = getThreeButtonDialog(
        onYes: _saveBeforeLoadWarningYes,
        onNo: _saveBeforeLoadWarningNo,
        onCancel: _closeSaveBeforeLoadWarning,
        outsideCancelable: false,
        message: "There are unsaved changes, do you want to save first?",
    );
    _loadingDialog = getLoadingDialog(message: "Opening Image...");
    _deleteWarningDialog = getTwoButtonDialog(
      message: "Do you really want to delete this project?",
      onNo: _deleteWarningNo,
      onYes: _deleteWarningYes,
      outsideCancelable: false,
    );

    _createWidgetList().then((final void nothing) {
      _filterAndSort(filterText: _filterText.value, order: _projectViewOrder.value);
      _isLoading = false;
    });
  }

  void _closeSaveBeforeLoadWarning()
  {
    _saveBeforeLoadWarningDialog.hide();
  }

  void _saveBeforeLoadWarningYes()
  {
    widget.saveKnownFileFn(callback: _saveBeforeLoadWarningNo);
  }

  void _saveBeforeLoadWarningNo()
  {
    _loadingDialog.show(context: context);
    loadKPixFile(
      fileData: null,
      constraints: GetIt.I.get<PreferenceManager>().kPalConstraints,
      path: _selectedWidget.value!.entryData.path,
      sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints,
      referenceLayerSettings: GetIt.I.get<PreferenceManager>().referenceLayerSettings,
      gridLayerSettings: GetIt.I.get<PreferenceManager>().gridLayerSettings,
      drawingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints,
      shadingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().shadingLayerSettingsConstraints,
    ).then((final LoadFileSet loadFileSet){fileLoaded(loadFileSet: loadFileSet, finishCallback: _loadingDialog.hide);});
    _closeSaveBeforeLoadWarning();
    widget.dismiss();
    widget.fileLoad();
  }

  void _dismissPressed()
  {
    widget.dismiss();
  }

  void _loadProject()
  {
    if (GetIt.I.get<AppState>().hasChanges.value)
    {
      _saveBeforeLoadWarningDialog.show(context: context);
    }
    else
    {
      _saveBeforeLoadWarningNo();
    }
  }

  void _deleteProjectPressed()
  {
    _deleteWarningDialog.show(context: context);
  }

  void _deleteWarningYes()
  {
    if (_selectedWidget.value != null)
    {
      deleteProject(fullProjectPath: _selectedWidget.value!.entryData.path).then((final bool success) {
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
      _isLoading = true;
      _createWidgetList().then((final void nothing) {
        _selectedWidget.value = null;
        _filterAndSort(filterText: _filterText.value, order: _projectViewOrder.value);
        _isLoading = false;
      });
    }
  }

  Future<void> _createWidgetList() async
  {
    _allFileEntries.clear();
    if (!kIsWeb)
    {
      final List<ProjectManagerEntryData> internalFiles = await loadProjectsFromInternal();
      for (final ProjectManagerEntryData fileData in internalFiles)
      {
        _allFileEntries.add(ProjectManagerEntryWidget(selectedWidget: _selectedWidget, entryData: fileData));
      }
    }
  }
  void changeOrder({required final ProjectViewOrder newOrder})
  {
    _projectViewOrder.value = newOrder;
    _filterAndSort(filterText: _filterText.value, order: _projectViewOrder.value);
  }

  void _importProjectPressed()
  {
    getPathForKPixFile().then((final String? loadPath)
    {
      importProject(path: loadPath).then(
        (final bool success)
        {
          _importFileCompleted(success: success);
        },
      );
    });
  }

  void _importFileCompleted({required final bool success})
  {
    final AppState appState = GetIt.I.get<AppState>();
    if (success)
    {
      _isLoading = true;
      _createWidgetList().then((final void nothing) {
        _filterAndSort(filterText: _filterText.value, order: _projectViewOrder.value);
        _isLoading = false;
      });
      appState.showMessage(text: "Project imported successfully!");
    }
  }

  void _filterAndSort({required final String filterText, required final ProjectViewOrder order})
  {
    final List<ProjectManagerEntryWidget> fList = _allFileEntries.where((final ProjectManagerEntryWidget element) => element.entryData.name.toLowerCase().contains(filterText.toLowerCase())).toList();
    if (order== ProjectViewOrder.lastModifiedAsc)
    {
      fList.sort((final ProjectManagerEntryWidget a, final ProjectManagerEntryWidget b) => a.entryData.dateTime.compareTo(b.entryData.dateTime));
    }
    else if (order == ProjectViewOrder.lastModifiedDesc)
    {
      fList.sort((final ProjectManagerEntryWidget a, final ProjectManagerEntryWidget b) => b.entryData.dateTime.compareTo(a.entryData.dateTime));
    }
    else if (order == ProjectViewOrder.nameAsc)
    {
      fList.sort((final ProjectManagerEntryWidget a, final ProjectManagerEntryWidget b) => a.entryData.name.toLowerCase().compareTo(b.entryData.name.toLowerCase()));
    }
    else if (order == ProjectViewOrder.nameDesc)
    {
      fList.sort((final ProjectManagerEntryWidget a, final ProjectManagerEntryWidget b) => b.entryData.name.toLowerCase().compareTo(a.entryData.name.toLowerCase()));
    }
    _fileEntries.value = fList;
  }

  void _filterTextChanged({required final String newText})
  {
    _filterText.value = newText;
    _filterAndSort(filterText: _filterText.value, order: _projectViewOrder.value);
  }

  @override
  Widget build(final BuildContext context) {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    return KPixAnimationWidget(
      constraints: BoxConstraints(
        minHeight: _alertOptions.minHeight,
        minWidth: _alertOptions.minWidth,
        maxHeight: _options.maxHeight,
        maxWidth: _options.maxWidth,
      ),
      child: Column(
        children: <Widget>[
          SizedBox(height: _alertOptions.padding),
          Text("PROJECT MANAGER", style: Theme.of(context).textTheme.titleLarge),
          SizedBox(
            height: 48,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Text(
                        "Filter",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: _filterText,
                          builder: (final BuildContext context, final String text, final Widget? child)
                          {
                            final TextEditingController controller = TextEditingController(text: _filterText.value);
                            controller.selection = TextSelection.collapsed(offset: controller.text.length);
                            return TextField(
                              controller: controller,
                              focusNode: hotkeyManager.projectFilterTextFocus,
                              onChanged: (final String newText) {_filterTextChanged(newText: newText);},
                              maxLength: _options.maxFilterTextLength,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  child: VerticalDivider(
                    color: Theme.of(context).primaryColorLight,
                    width: 32,
                    thickness: 1,
                    indent: 8,
                    endIndent: 8,
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<ProjectViewOrder>(
                    valueListenable: _projectViewOrder,
                    builder: (final BuildContext context, final ProjectViewOrder viewOrder, final Widget? child) {
                      return SegmentedButton<ProjectViewOrder>(
                        segments: const <ButtonSegment<ProjectViewOrder>>[
                          ButtonSegment<ProjectViewOrder>(
                            value: ProjectViewOrder.nameAsc,
                            label: Tooltip(
                              message: "Order by file name (ascending)",
                              waitDuration: AppState.toolTipDuration,
                              child: Icon(
                                  TablerIcons.sort_ascending_letters,
                              ),
                            ),
                          ),
                          ButtonSegment<ProjectViewOrder>(
                            value: ProjectViewOrder.nameDesc,
                            label: Tooltip(
                              message: "Order by file name (descending)",
                              waitDuration: AppState.toolTipDuration,
                              child: Icon(
                                  TablerIcons.sort_descending_letters,
                              ),
                            ),
                          ),
                          ButtonSegment<ProjectViewOrder>(
                            value: ProjectViewOrder.lastModifiedAsc,
                            label: Tooltip(
                              message: "Order by last modification (ascending)",
                              waitDuration: AppState.toolTipDuration,
                              child: Icon(
                                  TablerIcons.sort_ascending_numbers,
                              ),
                            ),
                          ),
                          ButtonSegment<ProjectViewOrder>(
                            value: ProjectViewOrder.lastModifiedDesc,
                            label: Tooltip(
                              message: "Order by last modification (descending)",
                              waitDuration: AppState.toolTipDuration,
                              child: Icon(
                                  TablerIcons.sort_descending_numbers,
                              ),
                            ),
                          ),
                        ],
                        selected: <ProjectViewOrder>{viewOrder},
                        showSelectedIcon: false,
                        onSelectionChanged: (final Set<ProjectViewOrder> newOrders){changeOrder(newOrder: newOrders.first);},
                      );
                    },
                  ),
                ),


              ],
            ),
          ),
          SizedBox(height: _alertOptions.padding),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark,
                borderRadius: BorderRadius.all(Radius.circular(_alertOptions.borderRadius)),
              ),
              child: ValueListenableBuilder<List<ProjectManagerEntryWidget>>(
                valueListenable: _fileEntries,
                builder: (final BuildContext context, final List<ProjectManagerEntryWidget> pList, final Widget? child) {
                  if (_isLoading)
                  {
                    return SizedBox.expand(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColorLight,
                        ),
                      ),
                    );
                  }
                  else if (pList.isEmpty)
                  {
                    return SizedBox.expand(
                        child: Center(
                            child: Text(
                              "No files found!",
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                        ),
                    );
                  }
                  else
                  {
                    return GridView.extent(
                      maxCrossAxisExtent: _options.maxWidth / _options.colCount,
                      padding: EdgeInsets.all(_alertOptions.padding),
                      childAspectRatio: _options.entryAspectRatio,
                      mainAxisSpacing: _alertOptions.padding,
                      crossAxisSpacing: _alertOptions.padding,
                      children: pList.toList(),
                    );
                  }

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
                  message: "Close",
                  waitDuration: AppState.toolTipDuration,
                  child: Padding(
                    padding: EdgeInsets.all(_alertOptions.padding),
                    child: IconButton.outlined(
                      icon: const Icon(
                        TablerIcons.x,
                      ),
                      onPressed: _dismissPressed,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Tooltip(
                  message: "Import Project",
                  waitDuration: AppState.toolTipDuration,
                  child: Padding(
                    padding: EdgeInsets.all(_alertOptions.padding),
                    child: IconButton.outlined(
                      icon: const Icon(
                        TablerIcons.file_import,
                      ),
                      onPressed: kIsWeb ? null : _importProjectPressed,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Tooltip(
                  message: "Delete Selected Project",
                  waitDuration: AppState.toolTipDuration,
                  child: Padding(
                    padding: EdgeInsets.all(_alertOptions.padding),
                    child: ValueListenableBuilder<ProjectManagerEntryWidget?>(
                      valueListenable: _selectedWidget,
                      builder: (final BuildContext context, final ProjectManagerEntryWidget? selWidget, final Widget? child) {
                        return IconButton.outlined(
                          icon: const Icon(
                            TablerIcons.trash,
                          ),
                          onPressed: (selWidget != null) ? _deleteProjectPressed : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Tooltip(
                  message: "Load Selected Project",
                  waitDuration: AppState.toolTipDuration,
                  child: Padding(
                    padding: EdgeInsets.all(_alertOptions.padding),
                    child: ValueListenableBuilder<ProjectManagerEntryWidget?>(
                      valueListenable: _selectedWidget,
                      builder: (final BuildContext context, final ProjectManagerEntryWidget? selWidget, final Widget? child) {
                        return IconButton.outlined(
                          icon: const Icon(
                            TablerIcons.check,
                          ),
                          onPressed: selWidget != null ? _loadProject : null,
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
