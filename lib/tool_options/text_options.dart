import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kpix/managers/font_manager.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

class TextOptions extends IToolOptions
{
  final int fontDefault;
  final int sizeMin;
  final int sizeMax;
  final int sizeDefault;
  final String textDefault;
  final int maxLength;
  final FontManager fontManager;

  final ValueNotifier<int> size = ValueNotifier(1);
  final ValueNotifier<PixelFontType?> font = ValueNotifier(null);
  final ValueNotifier<String> text = ValueNotifier("Text");


  TextOptions({
    required this.fontDefault,
    required this.sizeMin,
    required this.sizeMax,
    required this.sizeDefault,
    required this.textDefault,
    required this.maxLength,
    required this.fontManager
  })
  {
    size.value = sizeDefault;
    font.value = pixelFontIndexMap[fontDefault]!;
    text.value = textDefault;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required TextOptions textOptions,
  })
  {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Font",
                    style: Theme.of(context).textTheme.labelLarge,
                  )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<PixelFontType?>(
                valueListenable: textOptions.font,
                builder: (BuildContext context, PixelFontType? font, child)
                {
                  return DropdownButton(
                    value: font,
                    dropdownColor: Theme.of(context).primaryColorDark,
                    focusColor: Theme.of(context).primaryColor,
                    isExpanded: true,
                    onChanged: (PixelFontType? type) {textOptions.font.value = type;},
                    items: textOptions.fontManager.kFontMap.keys.map<DropdownMenuItem<PixelFontType>>((PixelFontType value) {
                      return DropdownMenuItem<PixelFontType>(
                        value: value,
                        child: Text(FontManager.getFontName(value), style: Theme.of(context).textTheme.bodyLarge?.apply(fontFamily: FontManager.getFontName(value)),),
                      );
                    }).toList(),
                  );
                },
              )
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Scale",
                    style: Theme.of(context).textTheme.labelLarge,
                  )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<int>(
                valueListenable: textOptions.size,
                builder: (BuildContext context, int size, child)
                {
                  return Slider(
                    value: size.toDouble(),
                    min: textOptions.sizeMin.toDouble(),
                    max: textOptions.sizeMax.toDouble(),
                    divisions: textOptions.sizeMax - textOptions.sizeMin,
                    onChanged: (double newVal) {textOptions.size.value = newVal.round();},
                    label: size.round().toString(),
                  );
                },
              ),
            ),

          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Text",
                    style: Theme.of(context).textTheme.labelLarge,
                  )
              ),
            ),
            Expanded(
              flex: toolSettingsWidgetOptions.columnWidthRatio,
              child: ValueListenableBuilder<String>(
                valueListenable: textOptions.text,
                builder: (BuildContext context, String text, child)
                {
                  final TextEditingController controller = TextEditingController(text: textOptions.text.value);
                  controller.selection = TextSelection.collapsed(offset: controller.text.length);
                  return TextField(
                    controller: controller,
                    onChanged: (String newText) {textOptions.text.value = newText;},
                    maxLength: textOptions.maxLength,
                  );
                },
              )
            ),
          ],
        ),
      ],
    );
  }

  @override
  void changeSize(int steps, int originalValue)
  {
    size.value = min(max(originalValue + steps, sizeMin), sizeMax);
  }

  @override
  int getSize()
  {
    return size.value;
  }

}