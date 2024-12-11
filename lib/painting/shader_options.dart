/*
 * KPix
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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

  ValueNotifier<ShaderDirection> shaderDirection = ValueNotifier<ShaderDirection>(ShaderDirection.left);
  ValueNotifier<bool> onlyCurrentRampEnabled = ValueNotifier<bool>(false);
  ValueNotifier<bool> isEnabled = ValueNotifier<bool>(true);

  ShaderOptions({required this.shaderDirectionDefault, required this.onlyCurrentRampEnabledDefault, required this.isEnabledDefault})
  {
    shaderDirection.value = shaderDirectionDefault ? ShaderDirection.right : ShaderDirection.left;
    onlyCurrentRampEnabled.value = onlyCurrentRampEnabledDefault;
    isEnabled.value = isEnabledDefault;
  }

}
