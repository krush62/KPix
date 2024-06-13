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

  @override
  Widget build(BuildContext context) {
    return Padding (
      padding: EdgeInsets.all(shaderWidgetOptions.outSidePadding),
      child: ValueListenableBuilder<bool>(
        valueListenable: shaderOptions.isEnabled,
        builder: (BuildContext context, bool isEnabled, child)
        {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    //TODO magic
                    flex: 3,
                    child: GestureDetector(
                      onTap: () {shaderOptions.isEnabled.value = !isEnabled;},
                      child: Text("Shading",
                          textAlign: TextAlign.start, style: isEnabled ? widget.titleStyle?.apply(color: Theme.of(context).primaryColorLight) : widget.titleStyle?.apply(color: Theme.of(context).primaryColorDark)),
                    ),
                  ),
                  Expanded(
                    //TODO magic
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.only(right: shaderWidgetOptions.outSidePadding),
                      child: Text("Enabled",
                          textAlign: TextAlign.end, style: widget.labelStyle),
                    ),
                  ),
                  Expanded(
                    //TODO magic
                    flex: 1,
                    child: Switch(
                      onChanged: (bool newState) {
                        shaderOptions.isEnabled.value = newState;
                      },
                      value: isEnabled,
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
                      child: ValueListenableBuilder<bool>(
                        valueListenable: shaderOptions.onlyCurrentRampEnabled,
                        builder: (BuildContext context, bool onlyCurrentRampEnabled, child)
                        {
                          return Switch(
                            onChanged: isEnabled
                                ? (bool newState) { shaderOptions.onlyCurrentRampEnabled.value = newState;}
                                : null,
                            value: onlyCurrentRampEnabled,
                          );
                        },

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
                    child: ValueListenableBuilder<ShaderDirection>(
                      valueListenable: shaderOptions.shaderDirection,
                      builder: (BuildContext context, ShaderDirection direction, child)
                      {
                        return Switch(
                          onChanged: isEnabled
                              ? (bool newState) {shaderOptions.shaderDirection.value = newState ? ShaderDirection.right : ShaderDirection.left;}
                              : null,
                          value: direction == ShaderDirection.right,
                        );
                      },
                    )
                  ),
                ],
              ),
            ],
          );
        },
      )
    );
  }
}