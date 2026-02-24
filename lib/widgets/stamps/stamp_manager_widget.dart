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
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/stamps/stamp_manager_entry_widget.dart';


class StampManager
{
  final ValueNotifier<StampMap> stampMap = ValueNotifier<StampMap>(<String, List<StampManagerEntryData>>{});
  final ValueNotifier<StampManagerEntryData?> selectedStamp = ValueNotifier<StampManagerEntryData?>(null);
  final ValueNotifier<String?> selectedFolder = ValueNotifier<String?>(null);

  Future<void> loadAllStamps() async
  {
    stampMap.value = await loadStamps(loadUserStamps: !kIsWeb);
    for (final MapEntry<String, List<StampManagerEntryData>> stampList in stampMap.value.entries)
    {
      if (stampList.value.isNotEmpty)
      {
        selectedFolder.value = stampList.key;
        selectedStamp.value = stampList.value.first;
      }
    }
  }


}

class StampManagerOptions
{
  final int colCount;
  final double entryAspectRatio;
  final double maxWidth;
  final double maxHeight;
  StampManagerOptions({required this.colCount, required this.entryAspectRatio, required this.maxWidth, required this.maxHeight});
}

class StampManagerWidget extends StatefulWidget
{
  final Function() dismiss;
  final StampEntryDataFn fileLoad;
  const StampManagerWidget({super.key, required this.dismiss, required this.fileLoad});

  @override
  State<StampManagerWidget> createState() => _StampManagerWidgetState();
}

class _StampManagerWidgetState extends State<StampManagerWidget>
{
  final OverlayEntryAlertDialogOptions _alertOptions = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final StampManagerOptions _options = GetIt.I.get<PreferenceManager>().stampManagerOptions;
  final StampManager _stampManager = GetIt.I.get<StampManager>();
  final ValueNotifier<List<StampManagerEntryWidget>> _fileEntries = ValueNotifier<List<StampManagerEntryWidget>>(<StampManagerEntryWidget>[]);
  final ValueNotifier<StampManagerEntryWidget?> _selectedWidget = ValueNotifier<StampManagerEntryWidget?>(null);
  late KPixOverlay _deleteWarningDialog;

  @override
  void initState()
  {
    super.initState();
    _deleteWarningDialog = getTwoButtonDialog(
      message: "Do you really want to delete this stamp?",
      onNo: _deleteWarningNo,
      onYes: _deleteWarningYes,
      outsideCancelable: false,
    );

    _createWidgetList();
  }

  Future<void> _createWidgetList() async
  {
    final String? sectionName = _stampManager.selectedFolder.value;
    final List<StampManagerEntryWidget> fList = <StampManagerEntryWidget>[];
    if (sectionName != null && !kIsWeb)
    {
      final StampMap stamps = _stampManager.stampMap.value;
      if (stamps.containsKey(sectionName))
      {
        final List<StampManagerEntryData> stampList = stamps[sectionName]!;
        for (final StampManagerEntryData fileData in stampList)
        {
          final StampManagerEntryWidget entryWidget = StampManagerEntryWidget(selectedWidget: _selectedWidget, entryData: fileData);
          fList.add(entryWidget);
          if (fileData == _stampManager.selectedStamp.value)
          {
            _selectedWidget.value = entryWidget;
          }
        }
        _fileEntries.value = fList;
      }
    }
  }

  void _deleteWarningYes()
  {
    if (_selectedWidget.value != null)
    {
      deleteFile(path: _selectedWidget.value!.entryData.path).then((final bool success) {
        _fileDeleted(success: success);
      });
    }
    _deleteWarningDialog.hide();
  }

  void _fileDeleted({required final bool success})
  {
    if (success)
    {
      _createWidgetList();
    }
  }

  void _deleteWarningNo()
  {
    _deleteWarningDialog.hide();
  }

  void _dismissPressed()
  {
    widget.dismiss();
  }

  void _deleteStampPressed()
  {
    _deleteWarningDialog.show(context: context);
  }

  @override
  Widget build(final BuildContext context)
  {
    return KPixAnimationWidget(
      constraints: BoxConstraints(
        minHeight: _alertOptions.minHeight,
        minWidth: _alertOptions.minWidth,
        maxHeight: _options.maxHeight,
        maxWidth: _options.maxWidth,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(height: _alertOptions.padding),
          Center(child: Text("STAMP MANAGER", style: Theme.of(context).textTheme.titleLarge)),
          ValueListenableBuilder<StampMap>(
            valueListenable: _stampManager.stampMap,
            builder: (final BuildContext context1, final StampMap stampMap, final Widget? child1) {
              return ValueListenableBuilder<String?>(
                valueListenable: _stampManager.selectedFolder,
                builder: (final BuildContext context2, final String? section, final Widget? child2) {
                  if (section != null)
                  {
                    final List<ButtonSegment<String>> segments = <ButtonSegment<String>>[];
                    for (final String stampSection in stampMap.keys)
                    {
                      segments.add(
                        ButtonSegment<String>(
                          value: stampSection,
                          label: Text(stampSection),
                        ),
                      );

                    }
                    return SegmentedButton<String>(
                      segments: segments,
                      selected: <String>{section},
                      showSelectedIcon: false,
                      onSelectionChanged: (final Set<String> newSelection) {
                        _stampManager.selectedFolder.value = newSelection.first;
                        _createWidgetList();
                      },
                    );
                  }
                  else
                  {
                    return const SizedBox();
                  }
              },);
            },
          ),
          SizedBox(height: _alertOptions.padding),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark,
                borderRadius: BorderRadius.all(Radius.circular(_alertOptions.borderRadius)),
              ),
              child: ValueListenableBuilder<List<StampManagerEntryWidget>>(
                valueListenable: _fileEntries,
                builder: (final BuildContext context, final List<StampManagerEntryWidget> sList, final Widget? child) {
                  return GridView.extent(
                    maxCrossAxisExtent: _options.maxWidth / _options.colCount,
                    padding: EdgeInsets.all(_alertOptions.padding),
                    childAspectRatio: _options.entryAspectRatio,
                    mainAxisSpacing: _alertOptions.padding,
                    crossAxisSpacing: _alertOptions.padding,
                    children: sList.toList(),
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
                  message: "Delete Selected Stamp",
                  waitDuration: AppState.toolTipDuration,
                  child: Padding(
                    padding: EdgeInsets.all(_alertOptions.padding),
                    child: ValueListenableBuilder<StampManagerEntryWidget?>(
                      valueListenable: _selectedWidget,
                      builder: (final BuildContext context, final StampManagerEntryWidget? selWidget, final Widget? child) {
                        return IconButton.outlined(
                          icon: const Icon(
                            TablerIcons.trash,
                          ),
                          onPressed: (selWidget != null && !selWidget.entryData.isLocked) ? _deleteStampPressed : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Tooltip(
                  message: "Load Selected Stamp",
                  waitDuration: AppState.toolTipDuration,
                  child: Padding(
                    padding: EdgeInsets.all(_alertOptions.padding),
                    child: ValueListenableBuilder<StampManagerEntryWidget?>(
                      valueListenable: _selectedWidget,
                      builder: (final BuildContext context, final StampManagerEntryWidget? selWidget, final Widget? child) {
                        return IconButton.outlined(
                          icon: const Icon(
                            TablerIcons.check,
                          ),
                          onPressed: selWidget != null ? () {
                            widget.fileLoad(data: selWidget.entryData);
                          } : null,
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
