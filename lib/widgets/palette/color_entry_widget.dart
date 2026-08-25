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
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/typedefs.dart';

abstract final class ColorEntryWidgetOptions {
  static const double unselectedMargin = 2.0;
  static const double selectedMargin = 0.0;
  static const double roundRadius = 4.0;
  static const double settingsIconSize = 24.0;
  static const double addIconSize = 24.0;
  static const double buttonPadding = 4.0;
  static const double minSize = 8.0;
  static const double maxSize = 32.0;

}

class ColorEntryWidget extends StatefulWidget
{
  final ValueNotifier<IdColor> colorData;
  final IdColorSelectedFn? colorSelectedFn;

  factory ColorEntryWidget({
    required final IdColor color,
    required final IdColorSelectedFn? colorSelectedFn,
})
  {

    final ValueNotifier<IdColor> colorData = ValueNotifier<IdColor>(color);
    return ColorEntryWidget._(
      colorData: colorData,
      colorSelectedFn: colorSelectedFn,
    );
  }

  const ColorEntryWidget._({
    required this.colorData,
    required this.colorSelectedFn,
  });

  @override
  State<ColorEntryWidget> createState() => _ColorEntryWidgetState();

}

class _ColorEntryWidgetState extends State<ColorEntryWidget>
{
  final AppState _appState = GetIt.I.get<AppState>();

  @override
  void initState() {
    super.initState();
  }

  void _colorPressed(final PointerDownEvent? event)
  {
    widget.colorSelectedFn!(newColor: widget.colorData.value);
  }

  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<IdColor>(
      valueListenable: widget.colorData,
      builder: (final BuildContext context, final IdColor value, final Widget? child) {

        return ValueListenableBuilder<ColorReference?>(
          valueListenable: _appState.selectedColorNotifier,
          builder: (final BuildContext context2, final ColorReference? selectedColor, final Widget? child2)
          {
            return Expanded(
              child: Listener(
                onPointerDown: _colorPressed,
                child: Tooltip(
                  message: value.getTooltipText(),
                  waitDuration: AppState.toolTipDuration,
                  textAlign: TextAlign.center,
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: ColorEntryWidgetOptions.minSize,
                      minWidth: ColorEntryWidgetOptions.minSize,
                      maxHeight: ColorEntryWidgetOptions.maxSize,
                      maxWidth: ColorEntryWidgetOptions.maxSize,
                    ),
                    margin: EdgeInsets.all(widget.colorData.value.uuid == selectedColor?.getIdColor().uuid
                        ? ColorEntryWidgetOptions.selectedMargin
                        : ColorEntryWidgetOptions.unselectedMargin,),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.colorData.value.uuid == selectedColor?.getIdColor().uuid
                          ? Theme.of(context).primaryColorLight
                          : Colors.transparent,
                        width: ColorEntryWidgetOptions.unselectedMargin -ColorEntryWidgetOptions.selectedMargin,),
                      color: value.color,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(
                          ColorEntryWidgetOptions.roundRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
