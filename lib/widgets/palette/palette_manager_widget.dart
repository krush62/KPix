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
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/palette/palette_manager_entry_widget.dart';

class PaletteManagerWidget extends StatefulWidget
{
  const PaletteManagerWidget({super.key});

  @override
  State<PaletteManagerWidget> createState() => _PaletteManagerWidgetState();
}

class _PaletteManagerWidgetState extends State<PaletteManagerWidget>
{
  final List<PaletteManagerEntryData> paletteList = [];
  @override
  void initState()
  {
    super.initState();
    //adding default palette
    paletteList.add(PaletteManagerEntryData(rampDataList: KPalRampData.getDefaultPalette(constraints: GetIt.I.get<PreferenceManager>().kPalConstraints ), isLocked: true, name: "KPix Default"));
  }

  @override
  Widget build(BuildContext context)
  {
    return GridView.extent(
      maxCrossAxisExtent: 8, //TODO prefs

    );
  }
}
