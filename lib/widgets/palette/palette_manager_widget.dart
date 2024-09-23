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
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:kpix/widgets/palette/palette_manager_entry_widget.dart';

class PaletteManagerWidget extends StatefulWidget
{
  final Function() dismiss;
  const PaletteManagerWidget({super.key, required this.dismiss});

  @override
  State<PaletteManagerWidget> createState() => _PaletteManagerWidgetState();
}

class _PaletteManagerWidgetState extends State<PaletteManagerWidget>
{
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<List<PaletteManagerEntryWidget>> _paletteEntries = ValueNotifier([]);
  @override
  void initState()
  {
    super.initState();
    _createWidgetList();
  }

  void _createWidgetList()
  {
    final List<PaletteManagerEntryWidget> pList = [];
    pList.add(PaletteManagerEntryWidget(entryData: PaletteManagerEntryData(rampDataList: KPalRampData.getDefaultPalette(constraints: GetIt.I.get<PreferenceManager>().kPalConstraints ), isLocked: true, name: "KPix Default")));
    //TODO add saved palettes

    _paletteEntries.value = pList;

  }

  @override
  Widget build(BuildContext context)
  {
    return Material(
      elevation: _options.elevation,
      shadowColor: Theme.of(context).primaryColorDark,
      borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
      child: Container(
        constraints: BoxConstraints(
          minHeight: _options.minHeight,
          minWidth: _options.minWidth,
          maxHeight: _options.maxHeight,
          maxWidth: _options.maxWidth,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          border: Border.all(
            color: Theme.of(context).primaryColorLight,
            width: _options.borderWidth,
          ),
          borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12,), //TODO magic
            Text("PALETTE MANAGER", style: Theme.of(context).textTheme.titleLarge),
            Expanded(
              child: ValueListenableBuilder<List<PaletteManagerEntryWidget>>(
                valueListenable: _paletteEntries,
                builder: (final BuildContext context, final List<PaletteManagerEntryWidget> pList, Widget? child) {
                  return GridView.extent(
                    maxCrossAxisExtent: _options.maxWidth / 4, //TODO (4) think of padding
                    padding: EdgeInsets.all(12), //TODO
                    childAspectRatio: 0.5, //TODO
                    mainAxisSpacing: 8, //TODO
                    crossAxisSpacing: 8, //TODO
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
                        padding: EdgeInsets.all(_options.padding),
                        child: IconButton.outlined(
                          icon: FaIcon(
                            FontAwesomeIcons.xmark,
                            size: _options.iconSize,
                          ),
                          onPressed: () {
                            widget.dismiss();
                          },
                        ),
                      )
                  ),
                  Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.all(_options.padding),
                        child: IconButton.outlined(
                          icon: FaIcon(
                            FontAwesomeIcons.folderOpen,
                            size: _options.iconSize,
                          ),
                          onPressed: null,
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
