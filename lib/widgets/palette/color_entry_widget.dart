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
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';

class ColorEntryWidgetOptions {
  final double unselectedMargin;
  final double selectedMargin;
  final double roundRadius;
  final double settingsIconSize;
  final double addIconSize;
  final double buttonPadding;
  final double minSize;
  final double maxSize;

  ColorEntryWidgetOptions({
    required this.unselectedMargin,
    required this.selectedMargin,
    required this.roundRadius,
    required this.settingsIconSize,
    required this.addIconSize,
    required this.buttonPadding,
    required this.minSize,
    required this.maxSize,
  });
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
  final ColorEntryWidgetOptions _options = GetIt.I.get<PreferenceManager>().colorEntryOptions;
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
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: _options.minSize,
                    minWidth: _options.minSize,
                    maxHeight: _options.maxSize,
                    maxWidth: _options.maxSize,
                  ),
                  margin: EdgeInsets.all(widget.colorData.value.uuid == selectedColor?.getIdColor().uuid
                      ? _options.selectedMargin
                      : _options.unselectedMargin,),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.colorData.value.uuid == selectedColor?.getIdColor().uuid
                        ? Theme.of(context).primaryColorLight
                        : Colors.transparent,
                      width: _options.unselectedMargin -_options.selectedMargin,),
                    color: value.color,
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                          _options.roundRadius,
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
