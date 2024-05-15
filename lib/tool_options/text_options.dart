import 'package:flutter/material.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';

enum TextFont
{
  font1,
  font2,
  font3,
  font4
}

const List<TextFont> textFontList =
[
  TextFont.font1,
  TextFont.font2,
  TextFont.font3,
  TextFont.font4
];

const Map<int, TextFont> _textFontIndexMap =
{
  0: TextFont.font1,
  1: TextFont.font2,
  2: TextFont.font3,
  3: TextFont.font4
};

const Map<TextFont, String> textFontStringMap =
{
  TextFont.font1: "Font 1",
  TextFont.font2: "Font 2",
  TextFont.font3: "Font 3",
  TextFont.font4: "Font 4"
};

class TextOptions
{
  final int fontDefault;
  final int sizeMin;
  final int sizeMax;
  final int sizeDefault;
  final String textDefault;
  final int maxLength;

  TextFont font = TextFont.font1;
  int size = 1;
  String text = "Text";

  TextOptions({
    required this.fontDefault,
    required this.sizeMin,
    required this.sizeMax,
    required this.sizeDefault,
    required this.textDefault,
    required this.maxLength
  })
  {
    font = textFontList[fontDefault] ?? TextFont.font1;
    size = sizeDefault;
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
                  onChanged: (TextFont? tFont) {textFontChanged!(tFont!);},
                  items: textFontList.map<DropdownMenuItem<TextFont>>((TextFont value) {
                    return DropdownMenuItem<TextFont>(
                      value: value,
                      child: Text(textFontStringMap[value]!),
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