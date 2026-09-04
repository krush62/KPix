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
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/managers/project_manager.dart';
import 'package:kpix/models/project_manager_data.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/messages.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/file/project_manager_entry_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// Layout options for [ProjectManagerWidget].
abstract final class _ProjectManagerOptions
{
  static const int colCount = 5;
  static const double entryAspectRatio = 0.75;
  static const double maxWidth = 800.0;
  static const double maxHeight = 600.0;
  static const int maxFilterTextLength = 16;
  static const double busyIndicatorSize = 16.0;
  static const double busyIndicatorStrokeWidth = 2.0;
}

/// Displays all project files and gives filter and sorting options.
///
/// The list itself is owned by [ProjectManager], which indexes and watches the
/// project directory in the background. This widget only filters and sorts what
/// the cache already holds, so opening it does not touch the file system.
class ProjectManagerWidget extends StatefulWidget
{
  final Function() dismiss;
  final Function() fileLoad;
  final SaveKnownFileFn saveKnownFileFn;
  const ProjectManagerWidget({super.key, required this.dismiss, required this.saveKnownFileFn, required this.fileLoad});

  @override
  State<ProjectManagerWidget> createState() => _ProjectManagerWidgetState();
}

/// Available sorting options.
enum ProjectViewOrder
{
  nameAsc,
  nameDesc,
  lastModifiedAsc,
  lastModifiedDesc,
}

class _ProjectManagerWidgetState extends State<ProjectManagerWidget>
{
  final ProjectManager _projectManager = GetIt.I.get<ProjectManager>();
  final ValueNotifier<ProjectViewOrder> _projectViewOrder = ValueNotifier<ProjectViewOrder>(ProjectViewOrder.lastModifiedDesc);
  final ValueNotifier<String> _filterText = ValueNotifier<String>("");
  final TextEditingController _filterController = TextEditingController();
  late final Listenable _listListenable;

  late KPixOverlay _saveBeforeLoadWarningDialog;
  late KPixOverlay _deleteWarningDialog;
  late KPixOverlay _loadingDialog;

  @override
  void initState()
  {
    super.initState();
    _listListenable = Listenable.merge(<Listenable>[
      _projectManager.projects,
      _projectManager.indexState,
      _projectViewOrder,
      _filterText,
    ],);
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

    //keeps the cache fresh while this view is open and re-scans once now, since
    //a directory watch can miss what other applications did to the directory
    _projectManager.retain();
  }

  @override
  void dispose()
  {
    _projectManager.release();
    _filterController.dispose();
    _projectViewOrder.dispose();
    _filterText.dispose();
    super.dispose();
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
    final String? selectedPath = _projectManager.selectedPath.value;
    if (selectedPath == null)
    {
      _closeSaveBeforeLoadWarning();
      return;
    }
    _loadingDialog.show(context: context);
    loadKPixFile(
      fileData: null,
      path: selectedPath,
      drawingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().drawingLayerSettingsConstraints,
      shadingLayerSettingsConstraints: GetIt.I.get<PreferenceManager>().shadingLayerSettingsConstraints,
      frameConstraints: GetIt.I.get<PreferenceManager>().frameConstraints,
    ).then((final LoadFileSet loadFileSet){fileLoaded(loadFileSet: loadFileSet, finishCallback: _loadingDialog.hide);});
    _closeSaveBeforeLoadWarning();
    //report the load before dismissing, so the dismiss handler can drop any
    //pending callback without discarding one that is still owed a call
    widget.fileLoad();
    widget.dismiss();
  }

  void _dismissPressed()
  {
    widget.dismiss();
  }

  void _loadProject()
  {
    if (GetIt.I.get<ProjectSession>().hasChanges.value)
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
    final String? selectedPath = _projectManager.selectedPath.value;
    if (selectedPath != null)
    {
      //the cache drops the entry and the selection with it once the file is gone
      deleteProject(fullProjectPath: selectedPath);
    }
    _deleteWarningDialog.hide();
  }

  void _deleteWarningNo()
  {
    _deleteWarningDialog.hide();
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
    if (success)
    {
      //the imported file is picked up by the cache on its own
      showMessage(text: "Project imported successfully!");
    }
  }

  void _retryPressed()
  {
    _projectManager.reindex();
  }

  /// The cached projects, reduced to what the filter allows and put in order.
  List<ProjectManagerEntryData> _filteredAndSorted()
  {
    final String filterText = _filterText.value.toLowerCase();
    final ProjectViewOrder order = _projectViewOrder.value;
    final List<ProjectManagerEntryData> fList = _projectManager.projects.value
        .where((final ProjectManagerEntryData element) => element.name.toLowerCase().contains(filterText))
        .toList();
    if (order == ProjectViewOrder.lastModifiedAsc)
    {
      fList.sort((final ProjectManagerEntryData a, final ProjectManagerEntryData b) => a.dateTime.compareTo(b.dateTime));
    }
    else if (order == ProjectViewOrder.lastModifiedDesc)
    {
      fList.sort((final ProjectManagerEntryData a, final ProjectManagerEntryData b) => b.dateTime.compareTo(a.dateTime));
    }
    else if (order == ProjectViewOrder.nameAsc)
    {
      fList.sort((final ProjectManagerEntryData a, final ProjectManagerEntryData b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    else if (order == ProjectViewOrder.nameDesc)
    {
      fList.sort((final ProjectManagerEntryData a, final ProjectManagerEntryData b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }
    return fList;
  }

  Widget _buildContent({required final BuildContext context})
  {
    final ProjectIndexState indexState = _projectManager.indexState.value;
    final bool cacheIsEmpty = _projectManager.projects.value.isEmpty;

    //a spinner is only shown while there is nothing to look at yet, so a
    //background re-scan never blanks a list that is already on screen
    if (cacheIsEmpty && indexState == ProjectIndexState.indexing)
    {
      return SizedBox.expand(
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColorLight,
          ),
        ),
      );
    }

    if (cacheIsEmpty && indexState == ProjectIndexState.error)
    {
      return SizedBox.expand(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "Could not read the project directory!",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
              IconButton.outlined(
                icon: const Icon(TablerIcons.refresh),
                onPressed: _retryPressed,
              ),
            ],
          ),
        ),
      );
    }

    final List<ProjectManagerEntryData> pList = _filteredAndSorted();
    if (pList.isEmpty)
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

    return GridView.builder(
      padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _ProjectManagerOptions.maxWidth / _ProjectManagerOptions.colCount,
        childAspectRatio: _ProjectManagerOptions.entryAspectRatio,
        mainAxisSpacing: OverlayEntryAlertDialogOptions.padding,
        crossAxisSpacing: OverlayEntryAlertDialogOptions.padding,
      ),
      itemCount: pList.length,
      itemBuilder: (final BuildContext context, final int index) {
        final ProjectManagerEntryData entryData = pList[index];
        return ProjectManagerEntryWidget(
          key: ValueKey<String>(entryData.path),
          entryData: entryData,
          selectedPath: _projectManager.selectedPath,
        );
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    return KPixAnimationWidget(
      constraints: const BoxConstraints(
        minHeight: OverlayEntryAlertDialogOptions.minHeight,
        minWidth: OverlayEntryAlertDialogOptions.minWidth,
        maxHeight: _ProjectManagerOptions.maxHeight,
        maxWidth: _ProjectManagerOptions.maxWidth,
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("PROJECT MANAGER", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: OverlayEntryAlertDialogOptions.padding),
              //an unobtrusive hint that the cache is catching up, used instead of
              //the full spinner whenever there are already entries on screen
              SizedBox(
                width: _ProjectManagerOptions.busyIndicatorSize,
                height: _ProjectManagerOptions.busyIndicatorSize,
                child: ValueListenableBuilder<ProjectIndexState>(
                  valueListenable: _projectManager.indexState,
                  builder: (final BuildContext context, final ProjectIndexState indexState, final Widget? child) {
                    if (indexState != ProjectIndexState.indexing)
                    {
                      return const SizedBox.shrink();
                    }
                    return CircularProgressIndicator(
                      color: Theme.of(context).primaryColorLight,
                      strokeWidth: _ProjectManagerOptions.busyIndicatorStrokeWidth,
                    );
                  },
                ),
              ),
            ],
          ),
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
                        child: TextField(
                          controller: _filterController,
                          focusNode: hotkeyManager.getFocusNode(id: FocusNodeEntry.projectFilterTextFocus),
                          onChanged: (final String newText) {_filterText.value = newText;},
                          maxLength: _ProjectManagerOptions.maxFilterTextLength,
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
                              waitDuration: toolTipDuration,
                              child: Icon(
                                  TablerIcons.sort_ascending_letters,
                              ),
                            ),
                          ),
                          ButtonSegment<ProjectViewOrder>(
                            value: ProjectViewOrder.nameDesc,
                            label: Tooltip(
                              message: "Order by file name (descending)",
                              waitDuration: toolTipDuration,
                              child: Icon(
                                  TablerIcons.sort_descending_letters,
                              ),
                            ),
                          ),
                          ButtonSegment<ProjectViewOrder>(
                            value: ProjectViewOrder.lastModifiedAsc,
                            label: Tooltip(
                              message: "Order by last modification (ascending)",
                              waitDuration: toolTipDuration,
                              child: Icon(
                                  TablerIcons.sort_ascending_numbers,
                              ),
                            ),
                          ),
                          ButtonSegment<ProjectViewOrder>(
                            value: ProjectViewOrder.lastModifiedDesc,
                            label: Tooltip(
                              message: "Order by last modification (descending)",
                              waitDuration: toolTipDuration,
                              child: Icon(
                                  TablerIcons.sort_descending_numbers,
                              ),
                            ),
                          ),
                        ],
                        selected: <ProjectViewOrder>{viewOrder},
                        showSelectedIcon: false,
                        onSelectionChanged: (final Set<ProjectViewOrder> newOrders){_projectViewOrder.value = newOrders.first;},
                      );
                    },
                  ),
                ),


              ],
            ),
          ),
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark,
                borderRadius: const BorderRadius.all(Radius.circular(OverlayEntryAlertDialogOptions.borderRadius)),
              ),
              child: ListenableBuilder(
                listenable: _listListenable,
                builder: (final BuildContext context, final Widget? child) {
                  return _buildContent(context: context);
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
                  waitDuration: toolTipDuration,
                  child: Padding(
                    padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
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
                  waitDuration: toolTipDuration,
                  child: Padding(
                    padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
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
                  waitDuration: toolTipDuration,
                  child: Padding(
                    padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                    child: ValueListenableBuilder<String?>(
                      valueListenable: _projectManager.selectedPath,
                      builder: (final BuildContext context, final String? selectedPath, final Widget? child) {
                        return IconButton.outlined(
                          icon: const Icon(
                            TablerIcons.trash,
                          ),
                          onPressed: (selectedPath != null) ? _deleteProjectPressed : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Tooltip(
                  message: "Load Selected Project",
                  waitDuration: toolTipDuration,
                  child: Padding(
                    padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                    child: ValueListenableBuilder<String?>(
                      valueListenable: _projectManager.selectedPath,
                      builder: (final BuildContext context, final String? selectedPath, final Widget? child) {
                        return IconButton.outlined(
                          icon: const Icon(
                            TablerIcons.check,
                          ),
                          onPressed: selectedPath != null ? _loadProject : null,
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
