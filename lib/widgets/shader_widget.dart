import 'package:flutter/material.dart';
import 'package:kpix/shader_options.dart';

class ShaderWidgetOptions {
  final double outSidePadding;
  const ShaderWidgetOptions({required this.outSidePadding});
}

class ShaderWidget extends StatefulWidget {
  final TextStyle? titleStyle;
  final TextStyle? labelStyle;
  final ShaderWidgetOptions shaderWidgetOptions;
  final ShaderOptions shaderOptions;

  const ShaderWidget(
      {super.key,
        required this.titleStyle,
        required this.labelStyle,
        required this.shaderWidgetOptions,
        required this.shaderOptions});

  @override
  State<ShaderWidget> createState() => _ShaderWidgetState();
}

class _ShaderWidgetState extends State<ShaderWidget> {
  void _enableSwitchChanged(bool newVal) {
    setState(() {
      widget.shaderOptions.isEnabled = newVal;
    });
  }

  void _currentRampSwitchChanged(bool newVal) {
    setState(() {
      widget.shaderOptions.onlyCurrentRampEnabled = newVal;
    });
  }

  void _directionSwitchChanged(bool newVal) {
    setState(() {
      widget.shaderOptions.shaderDirection = newVal ? ShaderDirection.right : ShaderDirection.left;
    });
  }

  void _tempPress()
  {
    print("SHADE PRESS");
  }

  @override
  Widget build(BuildContext context) {
    return Padding (
        padding: EdgeInsets.all(widget.shaderWidgetOptions.outSidePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 3,
                  child: Text("Shading",
                      textAlign: TextAlign.start, style: widget.shaderOptions.isEnabled ? widget.titleStyle?.apply(color: Theme.of(context).primaryColorLight) : widget.titleStyle?.apply(color: Theme.of(context).primaryColorDark)),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(right: widget.shaderWidgetOptions.outSidePadding),
                    child: Text("Enabled",
                        textAlign: TextAlign.end, style: widget.labelStyle),
                  ),
                ),
                Expanded(
                    flex: 1,
                    child: Switch(
                      onChanged: _enableSwitchChanged,
                      value: widget.shaderOptions.isEnabled,
                    )
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(right: widget.shaderWidgetOptions.outSidePadding),
                    child: Text("Current Ramp Only",
                        textAlign: TextAlign.start, style: widget.labelStyle),
                  ),
                ),
                Expanded(
                    flex: 1,
                    child: Switch(
                      onChanged: widget.shaderOptions.isEnabled
                          ? _currentRampSwitchChanged
                          : null,
                      value: widget.shaderOptions.onlyCurrentRampEnabled,
                    )
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(right: widget.shaderWidgetOptions.outSidePadding),
                    child: Text("Direction",
                        textAlign: TextAlign.end, style: widget.labelStyle),
                  ),
                ),
                Expanded(
                    flex: 1,
                    child: Switch(
                      onChanged: widget.shaderOptions.isEnabled
                          ? _directionSwitchChanged
                          : null,
                      value: widget.shaderOptions.shaderDirection == ShaderDirection.right,
                    )
                ),
              ],
            ),
          ],
        )
    );
  }
}