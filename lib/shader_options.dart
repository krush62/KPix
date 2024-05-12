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


  ShaderDirection shaderDirection = ShaderDirection.left;
  bool onlyCurrentRampEnabled = false;
  bool isEnabled = true;

  ShaderOptions({required this.shaderDirectionDefault, required this.onlyCurrentRampEnabledDefault, required this.isEnabledDefault})
  {
    shaderDirection = shaderDirectionDefault ? ShaderDirection.right : ShaderDirection.left;
    onlyCurrentRampEnabled = onlyCurrentRampEnabledDefault;
    isEnabled = isEnabledDefault;
  }

}