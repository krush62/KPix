import 'package:flutter/material.dart';

class HorizontalSplitView extends StatefulWidget {
  const HorizontalSplitView({
    required this.top,
    required this.bottom,
    this.ratio = 0.5,
    this.minRatioTop = 0.0,
    this.minRatioBottom = 0.0,
    this.dividerHeight = 16.0,
    super.key,
  })  : assert(ratio >= minRatioTop, 'ratio too high'),
        assert(ratio <= (1.0 - minRatioBottom), 'ratio too low');

  final Widget top;
  final Widget bottom;
  final double ratio;
  final double minRatioTop;
  final double minRatioBottom;
  final double dividerHeight;

  @override
  State<HorizontalSplitView> createState() => _HorizontalSplitViewState();
}


class _HorizontalSplitViewState extends State<HorizontalSplitView> {
  //from 0-1
  late double _ratio;
  late double _minRatio;
  late double _maxRatio;
  late double _dividerHeight;
  double? _maxHeight;

  @override
  void initState() {
    super.initState();
    _ratio = widget.ratio;
    _minRatio = widget.minRatioTop;
    _maxRatio = (1.0 - widget.minRatioBottom);
    _dividerHeight = widget.dividerHeight;
  }

  double get _height1 => _ratio * _maxHeight!;

  double get _height2 => (1.0 - _ratio) * _maxHeight!;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        assert(_ratio <= _maxRatio, 'ratio too high');
        assert(_ratio >= _minRatio, 'ratio too low');
        _maxHeight ??= constraints.maxHeight - _dividerHeight;
        if (_maxHeight != constraints.maxHeight) {
          _maxHeight = constraints.maxHeight - _dividerHeight;
        }

        return SizedBox(
          height: constraints.maxHeight,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: _height1,
                child: widget.top,
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: SizedBox(
                  height: _dividerHeight,
                  width: constraints.maxWidth,
                  child: Container (
                      color: Theme.of(context).primaryColor,
                      child: Icon(
                          Icons.drag_handle,
                          color: Theme.of(context).primaryColorLight,)
                  ),
                ),
                onPanUpdate: (DragUpdateDetails details) {
                  setState(
                        () {
                      _ratio += details.delta.dy / _maxHeight!;
                      if (_ratio > _maxRatio) {
                        _ratio = _maxRatio;
                      } else if (_ratio < _minRatio) {
                        _ratio = _minRatio;
                      }
                    },
                  );
                },
              ),
              SizedBox(
                height: _height2,
                child: widget.bottom,
              ),
            ],
          ),
        );
      },
    );
  }
}