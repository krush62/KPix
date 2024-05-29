import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models.dart';
import 'package:kpix/typedefs.dart';

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

class ColorEntryWidget extends StatefulWidget {
  final ValueNotifier<IdColor> colorData;
  final ColorSelectedFn? colorSelectedFn;
  final ColorEntryWidgetOptions options;
  final AppState appState;

  const ColorEntryWidget._({
    required this.colorData,
    required this.colorSelectedFn,
    required this.options,
    required this.appState

  });

  factory ColorEntryWidget({
    required IdColor color,
    required ColorEntryWidgetOptions options,
    required ColorSelectedFn? colorSelectedFn,
    required AppState appState,
})
  {

    ValueNotifier<IdColor> colorData = ValueNotifier(color);
    return ColorEntryWidget._(
      options: options,
      colorData: colorData,
      appState: appState,
      colorSelectedFn: colorSelectedFn,
    );

  }

  @override
  State<ColorEntryWidget> createState() => _ColorEntryWidgetState();


  void setColorHSV(final double hue, final double saturation, final double value, final String uuid) {
    assert(hue >= 0.0 && hue <= 1.0, 'hue must be in range 0.0-1.0');
    assert(saturation >= 0.0 && saturation <= 1.0,
        'saturation must be in range 0.0-1.0');
    assert(value >= 0.0 && value <= 1.0, 'value must be in range 0.0-1.0');
    colorData.value = IdColor(color: HSVColor.fromAHSV(1.0, hue, saturation, value).toColor(), uuid: uuid);

  }

  void setColorRGB(final int r, final int g, final int b, final String uuid) {
    assert(r >= 0 && r < 256, 'red value must be in range 0-255');
    assert(g >= 0 && g < 256, 'green value must be in range 0-255');
    assert(b >= 0 && b < 256, 'blue value must be in range 0-255');
    colorData.value = IdColor(color: Color.fromRGBO(r, g, b, 1.0), uuid: uuid);
  }

}

class _ColorEntryWidgetState extends State<ColorEntryWidget> {

  @override
  void initState() {
    super.initState();
  }

  void _colorPressed(final PointerDownEvent? event)
  {
    widget.colorSelectedFn!(widget.colorData.value);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IdColor>(
      valueListenable: widget.colorData,
      builder: (BuildContext context, IdColor value, child) {

        return ValueListenableBuilder<IdColor?>(
            valueListenable: widget.appState.selectedColor,
            builder: (BuildContext context2, IdColor? selectedColor, child2)
            {
              return Expanded(
                  child: Listener(
                    onPointerDown: _colorPressed,
                    child: Container(
                        constraints: BoxConstraints(
                            minHeight: widget.options.minSize,
                            minWidth: widget.options.minSize,
                            maxHeight: widget.options.maxSize,
                            maxWidth: widget.options.maxSize
                        ),
                        margin: EdgeInsets.all(widget.colorData.value == selectedColor
                            ? widget.options.selectedMargin
                            : widget.options.unselectedMargin),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: widget.colorData.value == selectedColor
                                    ? Theme.of(context).primaryColorLight
                                    : Colors.transparent,
                                width: (widget
                                    .options.unselectedMargin -
                                    widget.options.selectedMargin)),
                            color: value.color,
                            borderRadius: BorderRadius.all(
                                Radius.circular(
                                    widget.options.roundRadius))),
                    ),
                  )
              );
            }
        );
      }
    );
  }
}
