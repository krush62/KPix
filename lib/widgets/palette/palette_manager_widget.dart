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
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:kpix/widgets/palette/palette_manager_entry_widget.dart';

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
  final ValueNotifier<List<PaletteManagerEntryWidget>> _paletteEntries = ValueNotifier([]);
  final ValueNotifier<PaletteManagerEntryWidget?> _selectedWidget = ValueNotifier(null);

  late KPixOverlay _paletteWarningDialog;

  @override
  void initState()
  {
    super.initState();
    _createWidgetList();
    _paletteWarningDialog = OverlayEntries.getThreeButtonDialog(
        onYes: _paletteWarningYes,
        onNo: _paletteWarningNo,
        onCancel: _closeWarning,
        outsideCancelable: false,
        message: "Do you want to remap the existing colors (all pixels will be deleted otherwise)?");
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

  void _createWidgetList()
  {
    final List<PaletteManagerEntryWidget> pList = [];
    pList.add(PaletteManagerEntryWidget(selectedWidget: _selectedWidget, entryData: PaletteManagerEntryData(rampDataList: KPalRampData.getDefaultPalette(constraints: GetIt.I.get<PreferenceManager>().kPalConstraints ), isLocked: true, name: "Default")));
    _paletteEntries.value = pList;
    FileHandler.loadPalettesFromInternal().then((List<PaletteManagerEntryData> palList)
    {
      final List<PaletteManagerEntryWidget> pList = [];
      pList.addAll(_paletteEntries.value);
      for (final PaletteManagerEntryData palData in palList)
      {
        pList.add(PaletteManagerEntryWidget(selectedWidget: _selectedWidget, entryData: palData));
      }
      _paletteEntries.value = pList;
    });
  }

  void _addCurrentPalette()
  {
    //TODO show (new) dialog to select name (including overwrite indicator)
    print("ADD CURRENT PALETTE");
  }

  void _applyPalette()
  {
    _paletteWarningDialog.show(context: context);
  }

  void _dismissPressed()
  {
    widget.dismiss();
  }

  @override
  Widget build(BuildContext context)
  {
    return Material(
      elevation: _alertOptions.elevation,
      shadowColor: Theme.of(context).primaryColorDark,
      borderRadius: BorderRadius.all(Radius.circular(_alertOptions.borderRadius)),
      child: Container(
        constraints: BoxConstraints(
          minHeight: _alertOptions.minHeight,
          minWidth: _alertOptions.minWidth,
          maxHeight: _alertOptions.maxHeight,
          maxWidth: _alertOptions.maxWidth,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          border: Border.all(
            color: Theme.of(context).primaryColorLight,
            width: _alertOptions.borderWidth,
          ),
          borderRadius: BorderRadius.all(Radius.circular(_alertOptions.borderRadius)),
        ),
        child: Column(
          children: [
            SizedBox(height: _alertOptions.padding),
            Text("PALETTE MANAGER", style: Theme.of(context).textTheme.titleLarge),
            Expanded(
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
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.all(_alertOptions.padding),
                    child: IconButton.outlined(
                      icon: FaIcon(
                        FontAwesomeIcons.xmark,
                        size: _alertOptions.iconSize,
                      ),
                      onPressed: _dismissPressed,
                    ),
                  )
                ),
                Expanded(
                  flex: 1,
                  child: Tooltip(
                    message: "Save Current Palette",
                    waitDuration: AppState.toolTipDuration,
                    child: Padding(
                      padding: EdgeInsets.all(_alertOptions.padding),
                      child: IconButton.outlined(
                        icon: FaIcon(
                          FontAwesomeIcons.plus,
                          size: _alertOptions.iconSize,
                        ),
                        onPressed: _addCurrentPalette,
                      ),
                    ),
                  )
                ),
                Expanded(
                  flex: 1,
                  child: Tooltip(
                    message: "Apply Selected Palette",
                    waitDuration: AppState.toolTipDuration,
                    child: Padding(
                      padding: EdgeInsets.all(_alertOptions.padding),
                      child: ValueListenableBuilder<PaletteManagerEntryWidget?>(
                        valueListenable: _selectedWidget,
                        builder: (final BuildContext context, final PaletteManagerEntryWidget? selWidget, final Widget? child) {
                          return IconButton.outlined(
                            icon: FaIcon(
                              FontAwesomeIcons.fileImport,
                              size: _alertOptions.iconSize,
                            ),
                            onPressed: selWidget != null ? _applyPalette : null,
                          );
                        },
                      ),
                    ),
                  )
                ),
              ]
            ),
          ],
        )
      )
    );
  }
}
