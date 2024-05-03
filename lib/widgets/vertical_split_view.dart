import 'package:flutter/material.dart';

class VerticalSplitView extends StatefulWidget {
  const VerticalSplitView({
    required this.left,
    required this.right,
    this.ratio = 0.5,
    this.minRatioLeft = 0.0,
    this.minRatioRight = 0.0,
    this.dividerWidth = 16.0,
    super.key,
  })  : assert(ratio >= minRatioLeft, 'ratio too high'),
        assert(ratio <= (1.0 - minRatioRight), 'ratio too low');

  final Widget left;
  final Widget right;
  final double ratio;
  final double minRatioLeft;
  final double minRatioRight;
  final double dividerWidth;

  @override
  State<VerticalSplitView> createState() => _VerticalSplitViewState();
}


class _VerticalSplitViewState extends State<VerticalSplitView> {
  //from 0-1
  late double _ratio;
  late double _minRatio;
  late double _maxRatio;
  late double _dividerWidth;
  double? _maxWidth;

  @override
  void initState() {
    super.initState();
    _ratio = widget.ratio;
    _minRatio = widget.minRatioLeft;
    _maxRatio = (1.0 - widget.minRatioRight);
    _dividerWidth = widget.dividerWidth;
  }

  double get _width1 => _ratio * _maxWidth!;

  double get _width2 => (1.0 - _ratio) * _maxWidth!;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        assert(_ratio <= _maxRatio, 'ratio too high');
        assert(_ratio >= _minRatio, 'ratio too low');
        _maxWidth ??= constraints.maxWidth - _dividerWidth;
        if (_maxWidth != constraints.maxWidth) {
          _maxWidth = constraints.maxWidth - _dividerWidth;
        }

        return SizedBox(
          width: constraints.maxWidth,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: _width1,
                child: widget.left,
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: SizedBox(
                  width: _dividerWidth,
                  height: constraints.maxHeight,
                  child: Container(
                  color: Theme.of(context).primaryColor,
                    child: RotationTransition(
                      turns: const AlwaysStoppedAnimation(0.25),
                      child: Icon(
                        Icons.drag_handle,
                        color: Theme.of(context).primaryColorLight,
                      ),
                    ),
                  ),
                ),
                onPanUpdate: (DragUpdateDetails details) {
                  setState(
                        () {
                      _ratio += details.delta.dx / _maxWidth!;
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
                width: _width2,
                child: widget.right,
              ),
            ],
          ),
        );
      },
    );
  }
}