import 'package:flutter/material.dart';
import 'package:kpix/helper.dart';

class ColorChooserWidgetOptions
{
  final double iconButtonSize;
  final double colorContainerBorderRadius;
  final double padding;
  final double height;
  final double width;
  final int smokeOpacity;
  final double dividerThickness;
  final double elevation;
  final double borderWidth;
  final double borderRadius;
  final double outsidePadding;

  const ColorChooserWidgetOptions({
    required this.iconButtonSize,
    required this.colorContainerBorderRadius,
    required this.padding,
    required this.smokeOpacity,
    required this.width,
    required this.height,
    required this.elevation,
    required this.dividerThickness,
    required this.borderWidth,
    required this.borderRadius,
    required this.outsidePadding});
}

enum _SliderType { hue, saturation, value}

class ColorChooserWidget extends StatefulWidget {
  final ColorChooserWidgetOptions options;
  final Color inputColor;
  final Function(Color) colorSelected;
  final Function() dismiss;


  const ColorChooserWidget({ super.key, required this.inputColor, required this.options, required this.colorSelected, required this.dismiss});

  @override
  State<ColorChooserWidget> createState() => _ColorChooserWidgetState();
}

class _ColorChooserWidgetState extends State<ColorChooserWidget>
{
  late HSVColor _hsvColor;
  late Color _rgbColor;

  @override
  void initState() {
    super.initState();
    _rgbColor = widget.inputColor;
    _hsvColor = HSVColor.fromColor(_rgbColor);
  }

  void _sliderChanged(final _SliderType sliderType, final double value) {
    setState(() {
        if (sliderType == _SliderType.hue) {
          _hsvColor = _hsvColor.withHue(value);
        } else if (sliderType == _SliderType.saturation) {
          _hsvColor = _hsvColor.withSaturation(value);
        } else {
          _hsvColor = _hsvColor.withValue(value);
        }
        _rgbColor = _hsvColor.toColor();

    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,
        elevation: widget.options.elevation,
        borderRadius: BorderRadius.all(Radius.circular(widget.options.borderRadius)),
        child: Padding(
            padding: EdgeInsets.all(widget.options.padding),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: widget.options.padding),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                            color: _rgbColor,
                            borderRadius: BorderRadius.all(Radius.circular(widget.options.colorContainerBorderRadius))),
                      ),
                    ),
                  ),
                  Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              "HSV\n${Helper.hsvColorToHSVString(_hsvColor)}",
                              textAlign: TextAlign.center)
                          ),
                          VerticalDivider(
                            color:
                            Theme.of(context).primaryColorDark,
                            width: widget.options.dividerThickness,
                            thickness: widget.options.dividerThickness,
                          ),
                          Expanded(
                              flex: 1,
                              child: Text("RGB\n${Helper.colorToRGBString(_rgbColor)}",
                                  textAlign: TextAlign.center)),
                          VerticalDivider(
                              color: Theme.of(context).primaryColorDark,
                            width: widget.options.dividerThickness,
                            thickness: widget.options.dividerThickness,),
                          Expanded(
                              flex: 1,
                              child: Text("HEX\n${Helper.colorToHexString(_rgbColor)}",
                                  textAlign: TextAlign.center)),
                        ],
                      )),
                  Divider(
                    height: widget.options.dividerThickness,
                    thickness: widget.options.dividerThickness,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  const Expanded(
                    flex: 1,
                    child: Align(
                      alignment: AlignmentDirectional(0, 0),
                      child: Text(
                        'Hue',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Slider(
                      min: 0,
                      max: 360,
                      divisions: 360,
                      label:
                      "${_hsvColor.hue.round().toString()}°",
                      value: _hsvColor.hue,
                      onChanged: (double value) {
                        _sliderChanged(
                            _SliderType.hue, value);
                      },
                    ),
                  ),
                  Divider(
                    height: widget.options.dividerThickness,
                    thickness: widget.options.dividerThickness,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  const Expanded(
                    flex: 1,
                    child: Align(
                      alignment: AlignmentDirectional(0, 0),
                      child: Text(
                        'Saturation',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Slider(
                      min: 0,
                      max: 1,
                      divisions: 100,
                      label:
                      "${(_hsvColor.saturation * 100.0).round().toString()}%",
                      value: _hsvColor.saturation,
                      onChanged: (double value) {
                        _sliderChanged(
                            _SliderType.saturation, value);
                      },
                    ),
                  ),
                  Divider(
                    height: widget.options.dividerThickness, thickness: widget.options.dividerThickness,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  const Expanded(
                    flex: 1,
                    child: Align(
                      alignment: AlignmentDirectional(0, 0),
                      child: Text(
                        'Value',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Slider(
                      min: 0,
                      max: 1,
                      divisions: 100,
                      label:
                      "${(_hsvColor.value * 100.0).round().toString()}%",
                      value: _hsvColor.value,
                      onChanged: (double value) {
                        _sliderChanged(
                            _SliderType.value, value);
                      },
                    ),
                  ),
                  Padding(
                    padding:  EdgeInsets.only(bottom: widget.options.padding),
                    child: Divider(
                      height: widget.options.dividerThickness,
                      thickness: widget.options.dividerThickness,
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),

                  Expanded(
                      flex: 2,
                      child: Row(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                                flex: 1,
                                child: IconButton.outlined(
                                  icon: Icon(
                                    Icons.close,
                                    size: widget.options.iconButtonSize,
                                  ),
                                  onPressed: () {
                                    widget.dismiss();
                                  },
                                )),
                            Expanded(
                                flex: 1,
                                child: IconButton.outlined(
                                  icon: Icon(
                                    Icons.check,
                                    size: widget.options.iconButtonSize,
                                  ),
                                  onPressed: () {
                                    widget.colorSelected(_rgbColor);
                                  },
                                )
                            ),
                          ])),
                ])));
  }
}
