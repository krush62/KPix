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
  final ValueNotifier<List<StampManagerEntryData>> stampList = ValueNotifier<List<StampManagerEntryData>>(<StampManagerEntryData>[]);
  final ValueNotifier<StampManagerEntryData?> selectedStamp = ValueNotifier<StampManagerEntryData?>(null);

  Future<void> loadAllStamps() async
  {
    stampList.value = await loadStamps(loadUserStamps: !kIsWeb);
    if (stampList.value.isNotEmpty)
    {
      selectedStamp.value = stampList.value.first;
    }
    else
    {
      selectedStamp.value = null;
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

    _createWidgetList().then((final List<StampManagerEntryWidget> pList) {
      _fileEntries.value = pList;
    });
  }

  Future<List<StampManagerEntryWidget>> _createWidgetList() async
  {
    final List<StampManagerEntryWidget> fList = <StampManagerEntryWidget>[];
    if (!kIsWeb)
    {
      final List<StampManagerEntryData> stamps = _stampManager.stampList.value;
      for (final StampManagerEntryData fileData in stamps)
      {
        final StampManagerEntryWidget entryWidget = StampManagerEntryWidget(selectedWidget: _selectedWidget, entryData: fileData);
        fList.add(entryWidget);
        if (fileData == _stampManager.selectedStamp.value)
        {
          _selectedWidget.value = entryWidget;
        }
      }
    }

    return fList;
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
      _createWidgetList().then((final List<StampManagerEntryWidget> fList) {
        _selectedWidget.value = null;
        _fileEntries.value = fList;
      });
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
        children: <Widget>[
          SizedBox(height: _alertOptions.padding),
          Text("STAMP MANAGER", style: Theme.of(context).textTheme.titleLarge),
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
