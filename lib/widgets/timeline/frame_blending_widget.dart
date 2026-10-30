/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/constraints/frame_blending_constraints.dart';
import 'package:kpix/models/frame_blending_options.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';

class FrameBlendingWidget extends StatefulWidget
{
  final Function()? onDismiss;
  final FrameBlendingOptions options;
  const FrameBlendingWidget({super.key, required this.options, this.onDismiss});

  @override
  State<FrameBlendingWidget> createState() => _FrameBlendingWidgetState();
}

class _FrameBlendingWidgetState extends State<FrameBlendingWidget>
{
  static const double _padding = 8.0;
  static const double _maxWidth = 800.0;
  static const double _minWidth = 600.0;
  static const int _expansion1 = 1;
  static const int _expansion2 = 2;
  static const int _expansion3 = 3;
  static const int _expansion4 = 2;
  static const int _expansion5 = 1;

  Widget _label({required final String text})
  {
    return Expanded(
      flex: _expansion2,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: _padding / 2.0),
          child: Text(text),
        ),
      ),
    );
  }

  /// A switch usable while blending is enabled and, if given, [frames] is not zero.
  Widget _optionSwitch({required final ValueNotifier<bool> option, final ValueListenable<int>? frames})
  {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable?>[widget.options.enabled, option, frames]),
      builder: (final BuildContext context, final Widget? child) {
        final bool isEnabled = widget.options.enabled.value && (frames == null || frames.value > 0);
        return Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: option.value,
            onChanged: isEnabled ? (final bool newValue) {
              option.value = newValue;
              GetIt.I.get<ViewState>().repaintNotifier.repaint();
            } : null,
          ),
        );
      },
    );
  }

  Widget _optionSlider({required final ValueListenable<num> option, required final double min, required final double max, final int decimals = 0, required final ValueChanged<double> onChanged})
  {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[widget.options.enabled, option]),
      builder: (final BuildContext context, final Widget? child) {
        return KPixSlider(
          textStyle: Theme.of(context).textTheme.bodyMedium!,
          value: option.value.toDouble(),
          min: min,
          max: max,
          decimals: decimals,
          onChanged: widget.options.enabled.value ? (final double newValue) {
            onChanged(newValue);
            GetIt.I.get<ViewState>().repaintNotifier.repaint();
          } : null,
        );
      },
    );
  }

  Widget _framesSlider({required final ValueNotifier<int> frames})
  {
    return _optionSlider(
      option: frames,
      min: FrameBlendingConstraints.frameOffsetMin.toDouble(),
      max: FrameBlendingConstraints.frameOffsetMax.toDouble(),
      onChanged: (final double newFrames) {
        frames.value = newFrames.toInt();
      },
    );
  }

  Widget _sliderRow({required final String label, required final Widget slider, required final String switchLabel, required final Widget optionSwitch})
  {
    return Row(
      children: <Widget>[
        const Spacer(
          // ignore: avoid_redundant_argument_values
          flex: _expansion1,
        ),
        _label(text: label),
        Expanded(
          flex: _expansion3,
          child: Align(
            alignment: Alignment.centerLeft,
            child: slider,
          ),
        ),
        Expanded(
          flex: _expansion4,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(switchLabel),
          ),
        ),
        Expanded(
          // ignore: avoid_redundant_argument_values
          flex: _expansion5,
          child: optionSwitch,
        ),
      ],
    );
  }

  Widget _switchRow({required final String label, required final ValueNotifier<bool> option})
  {
    return Row(
      children: <Widget>[
        const Spacer(
          // ignore: avoid_redundant_argument_values
          flex: _expansion1,
        ),
        _label(text: label),
        Expanded(
          flex: _expansion3 + _expansion4 + _expansion5,
          child: _optionSwitch(option: option),
        ),
      ],
    );
  }

  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final FrameBlendingOptions options = widget.options;
    return Column(
      children: <Widget>[
        KPixAnimationWidget(
          constraints: const BoxConstraints(maxWidth: _maxWidth, minWidth: _minWidth),
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(child: Text(l10n.frameBlending.toUpperCase(), style: Theme.of(context).textTheme.headlineMedium,)),
                Divider(color: Theme.of(context).primaryColorLight,),

                //ENABLED
                Row(
                  children: <Widget>[
                    Expanded(
                      // ignore: avoid_redundant_argument_values
                      flex: _expansion1,
                      child: Text(l10n.enabled),
                    ),
                    Expanded(
                      flex: _expansion2 + _expansion3 + _expansion4 + _expansion5,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: options.enabled,
                        builder: (final BuildContext context, final bool enabled, final Widget? child)
                        {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Switch(
                              value: enabled,
                              onChanged: (final bool newEnabled)
                              {
                                options.enabled.value = newEnabled;
                                GetIt.I.get<ViewState>().repaintNotifier.repaint();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                _sliderRow(
                  label: l10n.framesBefore,
                  slider: _framesSlider(frames: options.framesBefore),
                  switchLabel: l10n.wrapAround,
                  optionSwitch: _optionSwitch(option: options.wrapAroundBefore, frames: options.framesBefore),
                ),
                _sliderRow(
                  label: l10n.framesAfter,
                  slider: _framesSlider(frames: options.framesAfter),
                  switchLabel: l10n.wrapAround,
                  optionSwitch: _optionSwitch(option: options.wrapAroundAfter, frames: options.framesAfter),
                ),
                _sliderRow(
                  label: l10n.opacity,
                  slider: _optionSlider(
                    option: options.opacity,
                    min: FrameBlendingConstraints.opacityMin,
                    max: FrameBlendingConstraints.opacityMax,
                    decimals: 1,
                    onChanged: (final double newOpacity) {
                      options.opacity.value = newOpacity;
                    },
                  ),
                  switchLabel: l10n.gradual,
                  optionSwitch: _optionSwitch(option: options.gradualOpacity),
                ),
                _switchRow(label: l10n.tinting, option: options.tinting),
                _switchRow(label: l10n.activeLayerOnly, option: options.activeLayerOnly),
                const SizedBox(height: _padding,),
                IconButton(
                  tooltip: l10n.close,
                  onPressed: () {widget.onDismiss?.call();},
                  icon: const Icon(TablerIcons.check),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
