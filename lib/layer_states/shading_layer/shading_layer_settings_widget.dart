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
import 'package:kpix/layer_states/layer_settings_widget.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_settings.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';

class ShadingLayerSettingsWidget extends LayerSettingsWidget
{
  final ShadingLayerSettings settings;
  const ShadingLayerSettingsWidget({super.key, required this.settings});

  @override
  State<ShadingLayerSettingsWidget> createState() => _ShadingLayerSettingsWidgetState();
}

class _ShadingLayerSettingsWidgetState extends State<ShadingLayerSettingsWidget> {
  final double generalPadding = 8.0;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(generalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text("SHADING RANGE", style: Theme
              .of(context)
              .textTheme
              .titleMedium, textAlign: TextAlign.center,),
          SizedBox(height: generalPadding),
          Row(
            children: <Widget>[
              const Expanded(child: Text("Max Darken")),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.settings.shadingStepsMinus,
                  builder: (final BuildContext context1, final int shadingLow, final Widget? child1)
                  {
                    return KPixSlider(
                      value: shadingLow.toDouble(),
                      min: widget.settings.constraints.shadingStepsMin.toDouble(),
                      max: widget.settings.constraints.shadingStepsMax.toDouble(),
                      onChanged: (final double value) {
                        widget.settings.shadingStepsMinus.value = value.round();
                      },
                      textStyle: Theme.of(context).textTheme.bodyMedium!,
                    );
                  },
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              const Expanded(child: Text("Max Brighten")),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.settings.shadingStepsPlus,
                  builder: (final BuildContext context1, final int shadingHigh, final Widget? child1)
                  {
                    return KPixSlider(
                      value: shadingHigh.toDouble(),
                      min: widget.settings.constraints.shadingStepsMin.toDouble(),
                      max: widget.settings.constraints.shadingStepsMax.toDouble(),
                      onChanged: (final double value) {
                        widget.settings.shadingStepsPlus.value = value.round();
                      },
                      textStyle: Theme.of(context).textTheme.bodyMedium!,
                    );
                  },
                ),
              ),
            ],
          ),







        ],
      ),
    );
  }
}
