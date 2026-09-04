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
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/models/constraints/tool_text_constraints.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/platform_helper.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';

class TextOptions extends IToolOptions
{

  final FontManager fontManager;

  final ValueNotifier<int> size = ValueNotifier<int>(1);
  final ValueNotifier<PixelFontType?> font = ValueNotifier<PixelFontType?>(null);
  final ValueNotifier<String> text = ValueNotifier<String>("Text");


  TextOptions({
    required this.fontManager,
  })
  {
    size.value = TextConstraints.sizeDefault;
    font.value = pixelFontIndexMap[TextConstraints.fontIndexDefault];
    text.value = TextConstraints.textDefault;
  }

  static KPixOverlay? _changeTextDialog;

  static Column getWidget({
    required final BuildContext context,
    required final TextOptions textOptions,
  })
  {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExcludeFocus(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Font",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              Expanded(
                flex: ToolSettingsWidgetOptions.columnWidthRatio,
                child: ValueListenableBuilder<PixelFontType?>(
                  valueListenable: textOptions.font,
                  builder: (final BuildContext context, final PixelFontType? font, final Widget? child)
                  {
                    return DropdownButton<PixelFontType>(
                      value: font,
                      dropdownColor: Theme.of(context).primaryColorDark,
                      focusColor: Theme.of(context).primaryColor,
                      isExpanded: true,
                      onChanged: (final PixelFontType? type) {textOptions.font.value = type;},
                      items: textOptions.fontManager.kFontMap.keys.map<DropdownMenuItem<PixelFontType>>((final PixelFontType typeValue) {
                        return DropdownMenuItem<PixelFontType>(
                          value: typeValue,
                          child: Text(FontManager.getFontName(type: typeValue), style: Theme.of(context).textTheme.bodyLarge?.apply(fontFamily: FontManager.getFontName(type: typeValue)),),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ExcludeFocus(
          child: ToolSliderRow<int>(
            label: "Scale",
            notifier: textOptions.size,
            flex: ToolSettingsWidgetOptions.columnWidthRatio,
            minVal: TextConstraints.sizeMin.toDouble(),
            maxVal: TextConstraints.sizeMax.toDouble(),
            //divisions: textOptions.sizeMax - textOptions.sizeMin,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Text",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            if (isDesktop(includingWeb: true))
              Expanded(
                flex: ToolSettingsWidgetOptions.columnWidthRatio,
                child: ValueListenableBuilder<String>(
                  valueListenable: textOptions.text,
                  builder: (final BuildContext context, final String text, final Widget? child)
                  {
                    final TextEditingController controller = TextEditingController(text: textOptions.text.value);
                    controller.selection = TextSelection.collapsed(offset: controller.text.length);
                    return TextField(
                      controller: controller,
                      focusNode: hotkeyManager.getFocusNode(id: FocusNodeEntry.textOptionsTextFocus),
                      onChanged: (final String newText) {textOptions.text.value = newText;},
                      maxLength: TextConstraints.maxLength,
                    );
                  },
                ),
              )
            else
              Expanded(
                flex: ToolSettingsWidgetOptions.columnWidthRatio,
                child: ValueListenableBuilder<String>(
                valueListenable: textOptions.text,
                builder: (final BuildContext context, final String text, final Widget? child)
                {
                    return OutlinedButton(
                      
                      child: Padding(
                        padding: const EdgeInsets.all(ToolSettingsWidgetOptions.padding),
                        child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
                      ),
                      onPressed: () {
                        _changeTextDialog = getChangeTextToolDialog(
                          onAccept: ({required final String newText}) {textOptions.text.value = newText; _changeTextDialog?.hide();},
                          onDismiss: () {_changeTextDialog?.hide();},
                          initialText: textOptions.text.value,
                          maxLength: TextConstraints.maxLength,
                        );
                        _changeTextDialog!.show(context: context);
                      },
                    );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    size.value = (originalValue + steps).clamp(TextConstraints.sizeMin, TextConstraints.sizeMax);
  }

  @override
  int getSize()
  {
    return size.value;
  }

}
