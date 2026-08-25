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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/palette/color_entry_widget.dart';

abstract final class _ColorRampRowWidgetOptions
{
  static const double borderRadius = 10.0;
  static const double borderWidth = 2.0;
  static const double buttonPadding = 8.0;
  //static const double buttonScaleFactor = 0.8;
  static const double dragFeedbackSquareSize = 16.0;
  static const double dragFeedbackSquarePadding = 1.0;
}

class ColorRampRowWidget extends StatefulWidget {
  final KPalRampData rampData;
  final ColorReferenceSelectedFn colorSelectedFn;
  final ColorRampFn showKPalFn;


  @override
  State<ColorRampRowWidget> createState() => _ColorRampRowWidgetState();



  const ColorRampRowWidget({
    super.key,
    required this.rampData,
    required this.colorSelectedFn,
    required this.showKPalFn,
  });

  void colorSelected({required final IdColor newColor})
  {
    int index = -1;
    for (int i = 0; i < rampData.shiftedColors.length; i++)
    {
      if (rampData.shiftedColors[i].value == newColor)
      {
        index = i;
        break;
      }
    }
    if (index != -1)
    {
      colorSelectedFn(color: rampData.references[index]);
    }
  }
}

class _ColorRampRowWidgetState extends State<ColorRampRowWidget> 
{
  final List<Widget> _widgetList = <Widget>[];
  final AppState _appState = GetIt.I.get<AppState>();

  @override
  void initState()
  {
    super.initState();
  }

  void _createWidgetList({required final ColorRampFn createKPal})
  {
    _widgetList.clear();
    _widgetList.add(
      Draggable<KPalRampData>(
        data: widget.rampData,
        feedback: Builder(
          builder: (final BuildContext context) {
            final List<Widget> widgetList = <Widget>[];
            for (int i = 0; i < widget.rampData.shiftedColors.length; i++)
            {
              widgetList.add(const Padding(padding: EdgeInsets.all(_ColorRampRowWidgetOptions.dragFeedbackSquarePadding), child: Icon(TablerIcons.square, size: _ColorRampRowWidgetOptions.dragFeedbackSquareSize)));
            }
            return Row(children: widgetList,);
          },
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: _ColorRampRowWidgetOptions.buttonPadding, right: _ColorRampRowWidgetOptions.buttonPadding,),
          child: ClipRect(
            child: Align(
              widthFactor: 0.5,
              child: Icon(
                color: Theme.of(context).primaryColor,
                TablerIcons.grip_vertical,
              ),
            ),
          ),
        ),
      ),
    );
    for (final ValueNotifier<IdColor> color in widget.rampData.shiftedColors)
    {
      _widgetList.add(
        ColorEntryWidget(
          color: color.value,
          colorSelectedFn: widget.colorSelected,
        ),
      );
    }
    _widgetList.add(
      Tooltip(
        message: "Edit Color Ramp",
        waitDuration: AppState.toolTipDuration,
        child: Padding(
          padding: const EdgeInsets.only(left: _ColorRampRowWidgetOptions.buttonPadding / 2, right: _ColorRampRowWidgetOptions.borderWidth) ,
          child: IconButton(
            style: Theme.of(context).iconButtonTheme.style!.copyWith(tapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(_ColorRampRowWidgetOptions.buttonPadding))),
            padding: const EdgeInsets.all(_ColorRampRowWidgetOptions.buttonPadding),
            iconSize: ColorEntryWidgetOptions.settingsIconSize - _ColorRampRowWidgetOptions.buttonPadding,
            constraints: const BoxConstraints(),
            icon: const Icon(TablerIcons.adjustments_horizontal),
            onPressed: () {createKPal(ramp: widget.rampData);
            },
          ),
        ),
      ),
    );
  }


  @override
  Widget build(final BuildContext context) {
    _createWidgetList(createKPal: widget.showKPalFn);
    return ValueListenableBuilder<ColorReference?>(
      valueListenable: _appState.selectedColorNotifier,
      builder: (final BuildContext context, final ColorReference? selectedColor, final Widget? child) {
        final bool isSelected = selectedColor?.ramp == widget.rampData;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(_ColorRampRowWidgetOptions.borderRadius)),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColorDark,
              width: _ColorRampRowWidgetOptions.borderWidth,
            ),
          ),
          child: Row(
            children: _widgetList,
          ),
        );
      },

    );
  }
}
