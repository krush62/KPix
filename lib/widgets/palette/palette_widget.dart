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
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/palette/color_ramp_row_widget.dart';

class PaletteWidgetOptions
{
  final double padding;
  final double managerButtonSize;
  final double borderRadius;
  final double dropTargetHeight;
  final int dropTargetAnimationLength;

  PaletteWidgetOptions({
    required this.padding,
    required this.managerButtonSize,
    required this.borderRadius,
    required this.dropTargetHeight,
    required this.dropTargetAnimationLength,
  });

}

class PaletteWidget extends StatefulWidget
{
  const PaletteWidget(
    {
      super.key,
    }
  );

  @override
  State<PaletteWidget> createState() => _PaletteWidgetState();
}

class _PaletteWidgetState extends State<PaletteWidget>
{
  final AppState _appState = GetIt.I.get<AppState>();
  late KPixOverlay _paletteManager;
  late KPixOverlay _kPal;

  @override
  void initState()
  {
    super.initState();
    _paletteManager = getPaletteManagerDialog(
        onDismiss: _paletteManagerClosed,);
  }

  void _paletteManagerPressed()
  {
    _paletteManager.show(context: context);
  }

  void _paletteManagerClosed()
  {
    _paletteManager.hide();
  }


  void _colorRampUpdate({required final KPalRampData ramp, required final KPalRampData originalData, final bool addToHistoryStack = true})
  {
    _kPal.hide();
    _appState.updateRamp(ramp: ramp, originalData: originalData, addToHistoryStack: addToHistoryStack);
  }

  void _colorRampDelete({required final KPalRampData ramp, final bool addToHistoryStack = true})
  {
    _kPal.hide();
    _appState.deleteRamp(ramp: ramp, addToHistoryStack: addToHistoryStack);
  }

  void _createKPal({required final KPalRampData ramp, final bool addToHistoryStack = true})
  {
    _kPal = getKPal(
      onAccept: _colorRampUpdate,
      onDelete: _colorRampDelete,
      colorRamp: ramp,
      usedPixels: _appState.getPixelCountForRamp(ramp: ramp),
    );
    _kPal.show(context: context);
  }

  Widget _getDropContainer({required final PaletteWidgetOptions paletteWidgetOptions, required final int index})
  {
    return DragTarget<KPalRampData>(
      builder: (final BuildContext context, final List<KPalRampData?> candidateItems, final List<dynamic> rejectedItems)
      {
        return AnimatedContainer(
          height: candidateItems.isEmpty ? paletteWidgetOptions.padding / 2 : paletteWidgetOptions.dropTargetHeight,
          color: candidateItems.isEmpty ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight,
          duration: Duration(milliseconds: paletteWidgetOptions.dropTargetAnimationLength),
        );
      },
      onAcceptWithDetails: (final DragTargetDetails<KPalRampData> details) {
        _appState.changeColorOrder(ramp: details.data, newPosition: index);
      },
    );
  }


  @override
  Widget build(final BuildContext context) {
    final AppState appState = GetIt.I.get<AppState>();
    final PaletteWidgetOptions paletteWidgetOptions = GetIt.I.get<PreferenceManager>().paletteWidgetOptions;
    return Expanded(
      child: ValueListenableBuilder<List<KPalRampData>>(
        valueListenable: appState.colorRampNotifier,
        builder: (final BuildContext context, final List<KPalRampData> rampDataSet, final Widget? child)
        {
          int dropTargetIndex = 0;
          final List<Widget> widgetList = <Widget>[];
          widgetList.add(_getDropContainer(paletteWidgetOptions: paletteWidgetOptions, index: dropTargetIndex++));
          for (final KPalRampData rampData in rampDataSet)
          {
            widgetList.add(
                ColorRampRowWidget(
                  rampData: rampData,
                  colorSelectedFn: appState.colorSelected,
                  showKPalFn: _createKPal,
                ),
            );
            widgetList.add(_getDropContainer(paletteWidgetOptions: paletteWidgetOptions, index: dropTargetIndex++));
          }
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorDark,
              borderRadius: BorderRadius.only(topRight: Radius.circular(paletteWidgetOptions.borderRadius), bottomRight: Radius.circular(paletteWidgetOptions.borderRadius)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Tooltip(
                  message: "Palette Manager",
                  waitDuration: AppState.toolTipDuration,
                  child: Padding(
                    padding: EdgeInsets.only(top: paletteWidgetOptions.padding, left: paletteWidgetOptions.padding, right: paletteWidgetOptions.padding),
                    child: IconButton.outlined(
                      onPressed: _paletteManagerPressed,
                      icon: const Icon(Icons.palette),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size(paletteWidgetOptions.managerButtonSize, paletteWidgetOptions.managerButtonSize),
                        maximumSize: Size(paletteWidgetOptions.managerButtonSize, paletteWidgetOptions.managerButtonSize),
                        iconSize: paletteWidgetOptions.managerButtonSize - paletteWidgetOptions.padding,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(GetIt.I.get<PreferenceManager>().paletteWidgetOptions.padding / 2.0),
                      child: Column(
                        children: <Widget>[
                          ...widgetList,
                        ],
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: "Add New Color Ramp",
                  waitDuration: AppState.toolTipDuration,
                  child: Padding(
                    padding: EdgeInsets.all(paletteWidgetOptions.padding),
                    child: IconButton.outlined(
                      onPressed: () {
                        appState.addNewRamp().then
                          ((final KPalRampData? ramp) {
                            if (ramp != null)
                            {
                              _createKPal(ramp: ramp);
                            }
                        }
                        );
                      },
                      icon: const Icon(TablerIcons.plus),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size(paletteWidgetOptions.managerButtonSize, paletteWidgetOptions.managerButtonSize),
                        maximumSize: Size(paletteWidgetOptions.managerButtonSize, paletteWidgetOptions.managerButtonSize),
                        iconSize: paletteWidgetOptions.managerButtonSize - paletteWidgetOptions.padding,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
