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
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/file_helper.dart';
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

abstract final class _StampManagerOptions
{
  static const int colCount = 6;
  static const double entryAspectRatio = 0.75;
  static const double maxWidth = 800.0;
  static const double maxHeight = 600.0;
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

  void _loadStampPressed()
  {
    final StampManagerEntryWidget? selectedStamp = _selectedWidget.value;
    if (selectedStamp != null)
    {
      widget.fileLoad(data: selectedStamp.entryData);
    }

  }

  Expanded _createExpandedButton({required final String tooltip, required final IconData icon, required final void Function() onPressedFunc, final bool isEnabled = true})
  {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        waitDuration: toolTipDuration,
        child: Padding(
          padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
          child: IconButton.outlined(
            icon: Icon(icon),
            onPressed: isEnabled ? onPressedFunc : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context)
  {
    return KPixAnimationWidget(
      constraints: const BoxConstraints(
        minHeight: OverlayEntryAlertDialogOptions.minHeight,
        minWidth: OverlayEntryAlertDialogOptions.minWidth,
        maxHeight: _StampManagerOptions.maxHeight,
        maxWidth: _StampManagerOptions.maxWidth,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
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
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark,
                borderRadius: const BorderRadius.all(Radius.circular(OverlayEntryAlertDialogOptions.borderRadius)),
              ),
              child: ValueListenableBuilder<List<StampManagerEntryWidget>>(
                valueListenable: _fileEntries,
                builder: (final BuildContext context, final List<StampManagerEntryWidget> sList, final Widget? child) {
                  return GridView.extent(
                    maxCrossAxisExtent: _StampManagerOptions.maxWidth / _StampManagerOptions.colCount,
                    padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                    childAspectRatio: _StampManagerOptions.entryAspectRatio,
                    mainAxisSpacing: OverlayEntryAlertDialogOptions.padding,
                    crossAxisSpacing: OverlayEntryAlertDialogOptions.padding,
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
              _createExpandedButton(tooltip: "Close", icon: TablerIcons.x, onPressedFunc: _dismissPressed),
              ValueListenableBuilder<StampManagerEntryWidget?>(
                valueListenable: _selectedWidget,
                builder: (final BuildContext context, final StampManagerEntryWidget? selWidget, final Widget? child) {
                  return _createExpandedButton(tooltip: "Delete Selected Stamp", icon: TablerIcons.trash, onPressedFunc: _deleteStampPressed, isEnabled: selWidget != null && !selWidget.entryData.isLocked);
                },
              ),
              ValueListenableBuilder<StampManagerEntryWidget?>(
                valueListenable: _selectedWidget,
                builder: (final BuildContext context, final StampManagerEntryWidget? selWidget, final Widget? child) {
                  return _createExpandedButton(tooltip: "Load Selected Stamp", icon: TablerIcons.check, onPressedFunc: _loadStampPressed, isEnabled: selWidget != null);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
