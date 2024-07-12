
import 'package:flutter/material.dart';

enum ShaderDirection
{
  left,
  right
}

class ShaderOptions
{
  final bool shaderDirectionDefault;
  final bool onlyCurrentRampEnabledDefault;
  final bool isEnabledDefault;

  ValueNotifier<ShaderDirection> shaderDirection = ValueNotifier(ShaderDirection.left);
  ValueNotifier<bool> onlyCurrentRampEnabled = ValueNotifier(false);
  ValueNotifier<bool> isEnabled = ValueNotifier(true);

  ShaderOptions({required this.shaderDirectionDefault, required this.onlyCurrentRampEnabledDefault, required this.isEnabledDefault})
  {
    shaderDirection.value = shaderDirectionDefault ? ShaderDirection.right : ShaderDirection.left;
    onlyCurrentRampEnabled.value = onlyCurrentRampEnabledDefault;
    isEnabled.value = isEnabledDefault;
  }

}