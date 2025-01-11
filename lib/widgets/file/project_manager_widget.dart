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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/file/project_manager_entry_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class ProjectManagerOptions
{
  final int colCount;
  final double entryAspectRatio;
  final double maxWidth;
  final double maxHeight;
  ProjectManagerOptions({required this.colCount, required this.entryAspectRatio, required this.maxWidth, required this.maxHeight});
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
  final ValueNotifier<List<ProjectManagerEntryWidget>> _fileEntries = ValueNotifier<List<ProjectManagerEntryWidget>>(<ProjectManagerEntryWidget>[]);
  final ValueNotifier<ProjectManagerEntryWidget?> _selectedWidget = ValueNotifier<ProjectManagerEntryWidget?>(null);
  final ValueNotifier<ProjectViewOrder> _projectViewOrder = ValueNotifier<ProjectViewOrder>(ProjectViewOrder.lastModifiedDesc);

  late KPixOverlay _saveBeforeLoadWarningDialog;
  late KPixOverlay _deleteWarningDialog;

  @override
  void initState()
  {
    super.initState();
    _saveBeforeLoadWarningDialog = getThreeButtonDialog(
        onYes: _saveBeforeLoadWarningYes,
        onNo: _saveBeforeLoadWarningNo,
        onCancel: _closeSaveBeforeLoadWarning,
        outsideCancelable: false,
        message: "There are unsaved changes, do you want to save first?",
    );
    _deleteWarningDialog = getTwoButtonDialog(
      message: "Do you really want to delete this project?",
      onNo: _deleteWarningNo,
      onYes: _deleteWarningYes,
      outsideCancelable: false,
    );

    _createWidgetList().then((final List<ProjectManagerEntryWidget> pList) {
      _fileEntries.value = pList;
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
    loadKPixFile(
      fileData: null,
      constraints: GetIt.I.get<PreferenceManager>().kPalConstraints,
      path: _selectedWidget.value!.entryData.path,
      sliderConstraints: GetIt.I.get<PreferenceManager>().kPalSliderConstraints,
      referenceLayerSettings: GetIt.I.get<PreferenceManager>().referenceLayerSettings,
      gridLayerSettings: GetIt.I.get<PreferenceManager>().gridLayerSettings,
      drawingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints,
      shadingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().shadingLayerSettingsConstraints,
    ).then((final LoadFileSet loadFileSet){fileLoaded(loadFileSet: loadFileSet, finishCallback: null);});
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
      _createWidgetList().then((final List<ProjectManagerEntryWidget> fList) {
        _selectedWidget.value = null;
        _fileEntries.value = fList;
      });
    }
  }

  Future<List<ProjectManagerEntryWidget>> _createWidgetList() async
  {
    final List<ProjectManagerEntryWidget> fList = <ProjectManagerEntryWidget>[];
    if (!kIsWeb)
    {
      final List<ProjectManagerEntryData> internalFiles = await loadProjectsFromInternal();
      for (final ProjectManagerEntryData fileData in internalFiles)
      {
        fList.add(ProjectManagerEntryWidget(selectedWidget: _selectedWidget, entryData: fileData));
      }
    }
    _sortWidgetEntries(fList: fList, order: _projectViewOrder.value);

    return fList;
  }

  static void _sortWidgetEntries({required final ProjectViewOrder order, required final List<ProjectManagerEntryWidget> fList})
  {
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
      fList.sort((final ProjectManagerEntryWidget a, final ProjectManagerEntryWidget b) => a.entryData.name.compareTo(b.entryData.name));
    }
    else if (order == ProjectViewOrder.nameDesc)
    {
      fList.sort((final ProjectManagerEntryWidget a, final ProjectManagerEntryWidget b) => b.entryData.name.compareTo(a.entryData.name));
    }
  }

  void changeOrder({required final ProjectViewOrder newOrder})
  {
    final List<ProjectManagerEntryWidget> fList = _fileEntries.value;
    _fileEntries.value = <ProjectManagerEntryWidget>[];
    _sortWidgetEntries(fList: fList, order: newOrder);
    _fileEntries.value = fList;
    _projectViewOrder.value = newOrder;
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
      //
    });
  }

  void _importFileCompleted({required final bool success})
  {
    final AppState appState = GetIt.I.get<AppState>();
    if (success)
    {
      _createWidgetList().then((final List<ProjectManagerEntryWidget> pList) {
        _fileEntries.value = pList;
      });
      appState.showMessage(text: "Project imported successfully!");
    }
  }

  @override
  Widget build(final BuildContext context) {
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
          ValueListenableBuilder<ProjectViewOrder>(
            valueListenable: _projectViewOrder,
            builder: (final BuildContext context, final ProjectViewOrder viewOrder, final Widget? child) {
              return SegmentedButton<ProjectViewOrder>(
                segments: const <ButtonSegment<ProjectViewOrder>>[
                  ButtonSegment<ProjectViewOrder>(
                    value: ProjectViewOrder.nameAsc,
                    label: Tooltip(
                      message: "Order by file name (ascending)",
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                          FontAwesomeIcons.arrowDownAZ,
                      ),
                    ),
                  ),
                  ButtonSegment<ProjectViewOrder>(
                    value: ProjectViewOrder.nameDesc,
                    label: Tooltip(
                      message: "Order by file name (descending)",
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                          FontAwesomeIcons.arrowDownZA,
                      ),
                    ),
                  ),
                  ButtonSegment<ProjectViewOrder>(
                    value: ProjectViewOrder.lastModifiedAsc,
                    label: Tooltip(
                      message: "Order by last modification (ascending)",
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                          FontAwesomeIcons.arrowDown19,
                      ),
                    ),
                  ),
                  ButtonSegment<ProjectViewOrder>(
                    value: ProjectViewOrder.lastModifiedDesc,
                    label: Tooltip(
                      message: "Order by last modification (descending)",
                      waitDuration: AppState.toolTipDuration,
                      child: FaIcon(
                          FontAwesomeIcons.arrowDown91,
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
                  return GridView.extent(
                    maxCrossAxisExtent: _options.maxWidth / _options.colCount,
                    padding: EdgeInsets.all(_alertOptions.padding),
                    childAspectRatio: _options.entryAspectRatio,
                    mainAxisSpacing: _alertOptions.padding,
                    crossAxisSpacing: _alertOptions.padding,
                    children: pList.toList(),
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
                  message: "Close",
                  waitDuration: AppState.toolTipDuration,
                  child: Padding(
                    padding: EdgeInsets.all(_alertOptions.padding),
                    child: IconButton.outlined(
                      icon: FaIcon(
                        FontAwesomeIcons.xmark,
                        size: _alertOptions.iconSize,
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
                      icon: FaIcon(
                        FontAwesomeIcons.fileImport,
                        size: _alertOptions.iconSize,
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
                          icon: FaIcon(
                            FontAwesomeIcons.trashCan,
                            size: _alertOptions.iconSize,
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
                          icon: FaIcon(
                            FontAwesomeIcons.check,
                            size: _alertOptions.iconSize,
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
