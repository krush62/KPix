import 'package:flutter/material.dart';
import 'package:kpix/font_manager.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/typedefs.dart';
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

  int size = 1;
  late PixelFontType font;
  String text = "Text";


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
    size = sizeDefault;
    font = pixelFontIndexMap[fontDefault]!;
    text = textDefault;
  }

  static Column getWidget({
    required BuildContext context,
    required ToolSettingsWidgetOptions toolSettingsWidgetOptions,
    required TextOptions textOptions,
    TextTextChanged? textTextChanged,
    TextSizeChanged? textSizeChanged,
    TextFontChanged? textFontChanged,
  })
  {
    TextEditingController controller = TextEditingController(text: textOptions.text);
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
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
                child: DropdownButton(
                  value: textOptions.font,
                  dropdownColor: Theme.of(context).primaryColorDark,
                  focusColor: Theme.of(context).primaryColor,
                  isExpanded: true,
                  onChanged: (PixelFontType? type) {textFontChanged!(type!);},
                  items: textOptions.fontManager.kFontMap.keys.map<DropdownMenuItem<PixelFontType>>((PixelFontType value) {
                    return DropdownMenuItem<PixelFontType>(
                      value: value,
                      child: Text(FontManager.getFontName(value), style: Theme.of(context).textTheme.bodyLarge?.apply(fontFamily: FontManager.getFontName(value)),),
                    );
                  }).toList(),
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
              child: Slider(
                value: textOptions.size.toDouble(),
                min: textOptions.sizeMin.toDouble(),
                max: textOptions.sizeMax.toDouble(),
                divisions: textOptions.sizeMax - textOptions.sizeMin,
                onChanged: textSizeChanged,
                label: textOptions.size.round().toString(),
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
              child: TextField(
                controller: controller,
                onChanged: textTextChanged,
                maxLength: textOptions.maxLength,
              )
            ),
          ],
        ),
      ],
    );
  }
}