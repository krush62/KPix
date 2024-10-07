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
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/palette/color_entry_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class ColorRampRowWidget extends StatefulWidget {
  final KPalRampData? rampData;
  final ColorReferenceSelectedFn? colorSelectedFn;
  final ColorRampUpdateFn? colorsUpdatedFn;
  final ColorRampFn? deleteRowFn;
  final Function()? addNewRampFn;
  final List<Widget> widgetList;

  @override
  State<ColorRampRowWidget> createState() => _ColorRampRowWidgetState();

  const ColorRampRowWidget._({
    super.key,
    this.rampData,
    this.colorSelectedFn,
    this.addNewRampFn,
    this.deleteRowFn,
    this.colorsUpdatedFn,
    required this.widgetList,
  });

  factory ColorRampRowWidget({
    KPalRampData? rampData,
    ColorReferenceSelectedFn? colorSelectedFn,
    Function()? addNewRampFn,
    ColorRampFn? deleteRowFn,
    ColorRampUpdateFn? colorsUpdatedFn,
    Key? key,
  }){
    List<Widget> widgetList = [];
    return ColorRampRowWidget._(
      addNewRampFn: addNewRampFn,
      widgetList: widgetList,
      colorSelectedFn: colorSelectedFn,
      rampData: rampData,
      colorsUpdatedFn: colorsUpdatedFn,
      deleteRowFn: deleteRowFn,
      key: key
    );
  }

  void colorSelected({required final IdColor newColor})
  {
    if (colorSelectedFn != null && rampData != null)
    {
      int index = -1;
      for (int i = 0; i < rampData!.shiftedColors.length; i++)
      {
        if (rampData!.shiftedColors[i].value == newColor)
        {
          index = i;
          break;
        }
      }
      if (index != -1)
      {
        colorSelectedFn!(color: rampData!.references[index]);
      }
    }
  }

  void _createWidgetList({required ColorRampFn createKPal})
  {
    widgetList.clear();
    if (rampData != null)
    {
      for (ValueNotifier<IdColor> color in rampData!.shiftedColors)
      {
        widgetList.add(
          ColorEntryWidget(
            color: color.value,
            colorSelectedFn: colorSelected,
          )
        );
      }
      widgetList.add(
        Tooltip(
          message: "Edit Color Ramp",
          waitDuration: AppState.toolTipDuration,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: FaIcon(
              FontAwesomeIcons.sliders,
              size: GetIt.I.get<PreferenceManager>().colorEntryOptions.settingsIconSize,
            ),
            onPressed: () {createKPal(ramp: rampData!);
            },
            style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          ),
        )
      );
    } else {
      widgetList.add(
        Expanded(
          child: Tooltip(
            message: "Add New Color Ramp",
            waitDuration: AppState.toolTipDuration,
            child: IconButton(
              padding: EdgeInsets.all(GetIt.I.get<PreferenceManager>().colorEntryOptions.buttonPadding),
              icon: FaIcon(
                FontAwesomeIcons.plus,
                size: GetIt.I.get<PreferenceManager>().colorEntryOptions.addIconSize,
              ),
              onPressed: () {addNewRampFn!.call();}
            ),
          )
        )
      );
    }
  }
}

class _ColorRampRowWidgetState extends State<ColorRampRowWidget> 
{
  late KPixOverlay kPal;

  @override
  void initState()
  {
    super.initState();

  }

  void _createKPal({required final KPalRampData ramp, final bool addToHistoryStack = true})
  {
    kPal = OverlayEntries.getKPal(
      onDismiss: _closeKPal,
      onAccept: _colorRampUpdate,
      onDelete: _colorRampDelete,
      colorRamp: ramp,
    );
    kPal.show(context: context);
  }

  void _colorRampUpdate({required final KPalRampData ramp, required final KPalRampData originalData, final bool addToHistoryStack = true})
  {
    _closeKPal();
    widget.colorsUpdatedFn!(ramp: ramp, originalData: originalData, addToHistoryStack: addToHistoryStack);
  }

  void _colorRampDelete({required final KPalRampData ramp, final bool addToHistoryStack = true})
  {
    _closeKPal();
    widget.deleteRowFn!(ramp: ramp, addToHistoryStack: addToHistoryStack);
  }

  void _closeKPal()
  {
    kPal.hide();
  }

   @override
  Widget build(final BuildContext context) {
    widget._createWidgetList(createKPal: _createKPal);
    return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widget.widgetList);
  }
}