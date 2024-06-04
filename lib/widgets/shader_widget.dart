import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/preference_manager.dart';
import 'package:kpix/shader_options.dart';

class ShaderWidgetOptions {
  final double outSidePadding;
  const ShaderWidgetOptions({required this.outSidePadding});
}

class ShaderWidget extends StatefulWidget {
  final TextStyle? titleStyle;
  final TextStyle? labelStyle;

  const ShaderWidget(
      {super.key,
        required this.titleStyle,
        required this.labelStyle,
});

  @override
  State<ShaderWidget> createState() => _ShaderWidgetState();
}

class _ShaderWidgetState extends State<ShaderWidget> {
  final ShaderOptions shaderOptions = GetIt.I.get<PreferenceManager>().shaderOptions;
  final ShaderWidgetOptions shaderWidgetOptions = GetIt.I.get<PreferenceManager>().shaderWidgetOptions;

  void _enableSwitchChanged(bool newVal) {
    setState(() {
      shaderOptions.isEnabled = newVal;
    });
  }

  void _currentRampSwitchChanged(bool newVal) {
    setState(() {
      shaderOptions.onlyCurrentRampEnabled = newVal;
    });
  }

  void _directionSwitchChanged(bool newVal) {
    setState(() {
      shaderOptions.shaderDirection = newVal ? ShaderDirection.right : ShaderDirection.left;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding (
        padding: EdgeInsets.all(shaderWidgetOptions.outSidePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 3,
                  child: Text("Shading",
                      textAlign: TextAlign.start, style: shaderOptions.isEnabled ? widget.titleStyle?.apply(color: Theme.of(context).primaryColorLight) : widget.titleStyle?.apply(color: Theme.of(context).primaryColorDark)),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(right: shaderWidgetOptions.outSidePadding),
                    child: Text("Enabled",
                        textAlign: TextAlign.end, style: widget.labelStyle),
                  ),
                ),
                Expanded(
                    flex: 1,
                    child: Switch(
                      onChanged: _enableSwitchChanged,
                      value: shaderOptions.isEnabled,
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
                    padding: EdgeInsets.only(right: shaderWidgetOptions.outSidePadding),
                    child: Text("Current Ramp Only",
                        textAlign: TextAlign.start, style: widget.labelStyle),
                  ),
                ),
                Expanded(
                    flex: 1,
                    child: Switch(
                      onChanged: shaderOptions.isEnabled
                          ? _currentRampSwitchChanged
                          : null,
                      value: shaderOptions.onlyCurrentRampEnabled,
                    )
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(right: shaderWidgetOptions.outSidePadding),
                    child: Text("Direction",
                        textAlign: TextAlign.end, style: widget.labelStyle),
                  ),
                ),
                Expanded(
                    flex: 1,
                    child: Switch(
                      onChanged: shaderOptions.isEnabled
                          ? _directionSwitchChanged
                          : null,
                      value: shaderOptions.shaderDirection == ShaderDirection.right,
                    )
                ),
              ],
            ),
          ],
        )
    );
  }
}