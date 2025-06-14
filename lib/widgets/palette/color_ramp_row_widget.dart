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
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/palette/color_entry_widget.dart';

class ColorRampRowWidgetOptions
{
  final double borderRadius;
  final double borderWidth;
  final double buttonPadding;
  final double buttonScaleFactor;
  final double dragFeedbackSquareSize;
  final double dragFeedbackSquarePadding;

  const ColorRampRowWidgetOptions({
    required this.borderRadius,
    required this.borderWidth,
    required this.buttonPadding,
    required this.buttonScaleFactor,
    required this.dragFeedbackSquareSize,
    required this.dragFeedbackSquarePadding,
  });
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
  final ColorRampRowWidgetOptions _options = GetIt.I.get<PreferenceManager>().colorRampRowOptions;

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
              widgetList.add(Padding(padding: EdgeInsets.all(_options.dragFeedbackSquarePadding), child: FaIcon(FontAwesomeIcons.solidSquare, size: _options.dragFeedbackSquareSize)));
            }
            return Row(children: widgetList,);
          },
        ),
        child: IconButton(
          padding: EdgeInsets.all(_options.buttonPadding),
          iconSize: GetIt.I.get<PreferenceManager>().colorEntryOptions.settingsIconSize * _options.buttonScaleFactor,
          constraints: const BoxConstraints(),
          icon: FaIcon(
            color: Theme.of(context).primaryColor,
            FontAwesomeIcons.gripVertical,
          ),
          onPressed: null,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        child: IconButton(
          padding: EdgeInsets.all(_options.buttonPadding),
          iconSize: GetIt.I.get<PreferenceManager>().colorEntryOptions.settingsIconSize * _options.buttonScaleFactor,
          constraints: const BoxConstraints(),
          icon: FaIcon(
            color: Theme.of(context).primaryColor,
            FontAwesomeIcons.sliders,
          ),
          onPressed: () {createKPal(ramp: widget.rampData);
          },
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorDark,
            borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
            border: Border.all(
              color: selectedColor?.ramp == widget.rampData
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColorDark,
              width: _options.borderWidth,
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
