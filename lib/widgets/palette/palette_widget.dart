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
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/palette/color_ramp_row_widget.dart';

abstract final class _PaletteWidgetOptions
{
  static const double padding = 8.0;
  static const double managerButtonSize = 32.0;
  static const double borderRadius = 8.0;
  static const double dropTargetHeight = 32.0;
  static const int dropTargetAnimationLength = 100;
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
  late KPixOverlay _paletteManager;
  late KPixOverlay _kPal;
  late PaletteState _paletteState;

  @override
  void initState()
  {
    super.initState();
    _paletteState = GetIt.I.get<PaletteState>();
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
    _paletteState.updateRamp(ramp: ramp, originalData: originalData, addToHistoryStack: addToHistoryStack);
  }

  void _colorRampDelete({required final KPalRampData ramp, final bool addToHistoryStack = true})
  {
    _kPal.hide();
    _paletteState.deleteRamp(ramp: ramp, addToHistoryStack: addToHistoryStack);
  }

  void _createKPal({required final KPalRampData ramp, final bool addToHistoryStack = true})
  {
    _kPal = getKPal(
      onAccept: _colorRampUpdate,
      onDelete: _colorRampDelete,
      colorRamp: ramp,
      usedPixels: _paletteState.getPixelCountForRamp(ramp: ramp),
    );
    _kPal.show(context: context);
  }

  Widget _getDropContainer({required final int index})
  {
    return DragTarget<KPalRampData>(
      builder: (final BuildContext context, final List<KPalRampData?> candidateItems, final List<dynamic> rejectedItems)
      {
        return AnimatedContainer(
          height: candidateItems.isEmpty ? _PaletteWidgetOptions.padding / 2 : _PaletteWidgetOptions.dropTargetHeight,
          color: candidateItems.isEmpty ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight,
          duration: const Duration(milliseconds: _PaletteWidgetOptions.dropTargetAnimationLength),
        );
      },
      onAcceptWithDetails: (final DragTargetDetails<KPalRampData> details) {
        _paletteState.changeColorOrder(ramp: details.data, newPosition: index);
      },
    );
  }


  @override
  Widget build(final BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder<List<KPalRampData>>(
        valueListenable: _paletteState.colorRampNotifier,
        builder: (final BuildContext context, final List<KPalRampData> rampDataSet, final Widget? child)
        {
          int dropTargetIndex = 0;
          final List<Widget> widgetList = <Widget>[];
          widgetList.add(_getDropContainer(index: dropTargetIndex++));
          for (final KPalRampData rampData in rampDataSet)
          {
            widgetList.add(
                ColorRampRowWidget(
                  rampData: rampData,
                  colorSelectedFn: _paletteState.colorSelected,
                  showKPalFn: _createKPal,
                ),
            );
            widgetList.add(_getDropContainer(index: dropTargetIndex++));
          }
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorDark,
              borderRadius: const BorderRadius.only(topRight: Radius.circular(_PaletteWidgetOptions.borderRadius), bottomRight: Radius.circular(_PaletteWidgetOptions.borderRadius)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Tooltip(
                  message: "Palette Manager",
                  waitDuration: toolTipDuration,
                  child: Padding(
                    padding: const EdgeInsets.only(top: _PaletteWidgetOptions.padding, left: _PaletteWidgetOptions.padding, right: _PaletteWidgetOptions.padding),
                    child: IconButton.outlined(
                      onPressed: _paletteManagerPressed,
                      icon: const Icon(Icons.palette),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(_PaletteWidgetOptions.managerButtonSize, _PaletteWidgetOptions.managerButtonSize),
                        maximumSize: const Size(_PaletteWidgetOptions.managerButtonSize, _PaletteWidgetOptions.managerButtonSize),
                        iconSize: _PaletteWidgetOptions.managerButtonSize - _PaletteWidgetOptions.padding,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(_PaletteWidgetOptions.padding / 2.0),
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
                  waitDuration: toolTipDuration,
                  child: Padding(
                    padding: const EdgeInsets.all(_PaletteWidgetOptions.padding),
                    child: IconButton.outlined(
                      onPressed: () {
                        _paletteState.addNewRamp().then
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
                        minimumSize: const Size(_PaletteWidgetOptions.managerButtonSize, _PaletteWidgetOptions.managerButtonSize),
                        maximumSize: const Size(_PaletteWidgetOptions.managerButtonSize, _PaletteWidgetOptions.managerButtonSize),
                        iconSize: _PaletteWidgetOptions.managerButtonSize - _PaletteWidgetOptions.padding,
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
