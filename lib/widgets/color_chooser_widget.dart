import 'package:flutter/material.dart';
import 'package:kpix/helper.dart';

class ColorChooserWidgetOptions
{
  final double iconButtonSize;
  final double colorContainerBorderRadius;
  final double padding;

  const ColorChooserWidgetOptions({required this.iconButtonSize, required this.colorContainerBorderRadius, required this.padding});
}

enum _SliderType { hue, saturation, value, red, green, blue }

class ColorChooserWidget extends StatefulWidget {
  final ColorChooserWidgetOptions options;
  final Color inputColor;

  //ColorChooserWidget(this.inputColor, this.options, {super.key});
  const ColorChooserWidget({ required this.inputColor, required this.options, super.key});

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
      if (sliderType == _SliderType.hue ||
          sliderType == _SliderType.saturation ||
          sliderType == _SliderType.value) {
        if (sliderType == _SliderType.hue) {
          _hsvColor = _hsvColor.withHue(value);
        } else if (sliderType == _SliderType.saturation) {
          _hsvColor = _hsvColor.withSaturation(value);
        } else {
          _hsvColor = _hsvColor.withValue(value);
        }
        _rgbColor = _hsvColor.toColor();
      } else {
        if (sliderType == _SliderType.red) {
          _rgbColor = _rgbColor.withRed(value.round());
        } else if (sliderType == _SliderType.green) {
          _rgbColor = _rgbColor.withGreen(value.round());
        } else {
          _rgbColor = _rgbColor.withBlue(value.round());
        }
        _hsvColor = HSVColor.fromColor(_rgbColor);
      }
    });
  }



  void _doStuff() {
    print("BUTTON CLICKED!");
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Padding(
            padding: EdgeInsets.all(widget.options.padding),
            child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                          color: _rgbColor,
                          borderRadius: BorderRadius.all(Radius.circular(widget.options.colorContainerBorderRadius))),
                    ),
                  ),
                  Divider(
                    thickness: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                  Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                              flex: 1,
                              child: Text(
                                  "HSV\n${Helper.hsvColorToHSVString(_hsvColor)}",
                                  textAlign: TextAlign.center)),
                          VerticalDivider(
                              color: Theme.of(context).dividerColor, width: 1),
                          Expanded(
                              flex: 1,
                              child: Text("RGB\n${Helper.colorToRGBString(_rgbColor)}",
                                  textAlign: TextAlign.center)),
                          VerticalDivider(
                              color: Theme.of(context).dividerColor, width: 1),
                          Expanded(
                              flex: 1,
                              child: Text("HEX\n${Helper.colorToHexString(_rgbColor)}",
                                  textAlign: TextAlign.center)),
                        ],
                      )),
                  Divider(
                    thickness: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                  DefaultTabController(
                      initialIndex: 0,
                      length: 2,
                      child: Expanded(
                          flex: 8,
                          child: Column(children: [
                            Align(
                              alignment: const Alignment(0, 0),
                              child: TabBar(
                                labelColor: Theme.of(context).primaryColor,
                                unselectedLabelColor:
                                Theme.of(context).secondaryHeaderColor,
                                indicatorColor: Theme.of(context).primaryColor,
                                padding: EdgeInsets.all(widget.options.padding),
                                tabs: const [
                                  Tab(
                                    text: 'HSV',
                                  ),
                                  Tab(
                                    text: 'RGB',
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                                child: TabBarView(children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
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
                                        flex: 1,
                                        child: SliderTheme(
                                          data: const SliderThemeData(
                                            showValueIndicator:
                                            ShowValueIndicator.always,
                                          ),
                                          child: Slider(
                                            activeColor:
                                            Theme.of(context).primaryColor,
                                            inactiveColor:
                                            Theme.of(context).cardColor,
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
                                      ),
                                      Divider(
                                        thickness: 1,
                                        color: Theme.of(context).dividerColor,
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
                                        flex: 1,
                                        child: SliderTheme(
                                          data: const SliderThemeData(
                                            showValueIndicator:
                                            ShowValueIndicator.always,
                                          ),
                                          child: Slider(
                                            activeColor:
                                            Theme.of(context).primaryColor,
                                            inactiveColor:
                                            Theme.of(context).cardColor,
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
                                      ),
                                      Divider(
                                        thickness: 1,
                                        color: Theme.of(context).dividerColor,
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
                                        flex: 1,
                                        child: Slider(
                                          activeColor:
                                          Theme.of(context).primaryColor,
                                          inactiveColor:
                                          Theme.of(context).cardColor,
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
                                    ],
                                  ),
                                  Column(mainAxisSize: MainAxisSize.max, children: [
                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Red',
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Slider(
                                        activeColor: Theme.of(context).primaryColor,
                                        inactiveColor: Theme.of(context).cardColor,
                                        min: 0,
                                        max: 255,
                                        divisions: 255,
                                        label: _rgbColor.red.toString(),
                                        value: _rgbColor.red.toDouble(),
                                        onChanged: (double value) {
                                          _sliderChanged(_SliderType.red, value);
                                        },
                                      ),
                                    ),
                                    Divider(
                                      thickness: 1,
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Green',
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Slider(
                                        activeColor: Theme.of(context).primaryColor,
                                        inactiveColor: Theme.of(context).cardColor,
                                        min: 0,
                                        max: 255,
                                        divisions: 255,
                                        label: _rgbColor.green.toString(),
                                        value: _rgbColor.green.toDouble(),
                                        onChanged: (double value) {
                                          _sliderChanged(_SliderType.green, value);
                                        },
                                      ),
                                    ),
                                    Divider(
                                      thickness: 1,
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        'Blue',
                                      ),
                                    ),
                                    Expanded(
                                        flex: 1,
                                        child: Slider(
                                          activeColor:
                                          Theme.of(context).primaryColor,
                                          inactiveColor:
                                          Theme.of(context).cardColor,
                                          min: 0,
                                          max: 255,
                                          divisions: 255,
                                          label: _rgbColor.blue.toString(),
                                          value: _rgbColor.blue.toDouble(),
                                          onChanged: (double value) {
                                            _sliderChanged(_SliderType.blue, value);
                                          },
                                        ))
                                  ]),
                                ]))
                          ]))),
                  Divider(
                    thickness: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                  Expanded(
                      flex: 1,
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
                                    color: Theme.of(context).primaryColor,
                                    size: widget.options.iconButtonSize,
                                  ),
                                  onPressed: () {
                                    _doStuff();
                                  },
                                )),
                            Expanded(
                                flex: 1,
                                child: IconButton.outlined(
                                  icon: Icon(
                                    Icons.check,
                                    color: Theme.of(context).primaryColor,
                                    size: widget.options.iconButtonSize,
                                  ),
                                  onPressed: () {
                                    _doStuff();
                                  },
                                )
                            ),
                          ])),
                ])));
  }
}
