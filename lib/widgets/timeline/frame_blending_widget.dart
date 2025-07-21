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

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';

class FrameBlendingOptions
{
  final ValueNotifier<bool> enabled;
  final ValueNotifier<int> framesBefore;
  final ValueNotifier<bool> wrapAroundBefore;
  final ValueNotifier<int> framesAfter;
  final ValueNotifier<bool> wrapAroundAfter;
  final ValueNotifier<double> opacity;
  final ValueNotifier<bool> gradualOpacity;
  final ValueNotifier<bool> tinting;
  final ValueNotifier<bool> activeLayerOnly;
  final int frameMax;
  final int frameMin;
  final double opacityMin;
  final double opacityMax;
  final double opacityStep;

  FrameBlendingOptions({
    required final bool enabled,
    required final int framesBefore,
    required final int framesAfter,
    required final double opacity,
    required final bool gradualOpacity,
    required final bool wrapAroundBefore,
    required final bool wrapAroundAfter,
    required final bool tinting,
    required final bool activeLayerOnly,
    required this.frameMin,
    required this.frameMax,
    required this.opacityMin,
    required this.opacityMax,
    required this.opacityStep,})
      :
    enabled = ValueNotifier<bool>(enabled),
    framesBefore = ValueNotifier<int>(framesBefore),
    wrapAroundBefore = ValueNotifier<bool>(wrapAroundBefore),
    framesAfter = ValueNotifier<int>(framesAfter),
    wrapAroundAfter = ValueNotifier<bool>(wrapAroundAfter),
    opacity = ValueNotifier<double>(opacity),
    gradualOpacity = ValueNotifier<bool>(gradualOpacity),
    tinting = ValueNotifier<bool>(tinting),
    activeLayerOnly = ValueNotifier<bool>(activeLayerOnly);

}


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



  @override
  Widget build(final BuildContext context)
  {
    return Column(
      children: <Widget>[
        KPixAnimationWidget(
          constraints: const BoxConstraints(maxWidth: _maxWidth, minWidth: _minWidth),
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(child: Text("Frame Blending", style: Theme.of(context).textTheme.headlineMedium,)),
                Divider(color: Theme.of(context).primaryColorLight,),

                //ENABLED
                Row(
                  children: <Widget>[
                    const Expanded(
                      // ignore: avoid_redundant_argument_values
                      flex: _expansion1,
                      child: Text("Enabled"),
                    ),
                    Expanded(
                      flex: _expansion2 + _expansion3 + _expansion4 + _expansion5,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: widget.options.enabled,
                        builder: (final BuildContext context, final bool enabled, final Widget? child)
                        {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Switch(
                              value: enabled,
                              onChanged: (final bool newEnabled)
                              {
                                widget.options.enabled.value = newEnabled;
                                GetIt.I.get<AppState>().repaintNotifier.repaint();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                //FRAMES BEFORE
                Row(
                  children: <Widget>[
                   const Spacer(
                     // ignore: avoid_redundant_argument_values
                     flex: _expansion1,
                   ),
                    const Expanded(
                      flex: _expansion2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: _padding / 2.0),
                          child: Text("Frames Before"),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: _expansion3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: widget.options.enabled,
                          builder: (final BuildContext context1, final bool enabled, final Widget? child1) {
                            return ValueListenableBuilder<int>(
                              valueListenable: widget.options.framesBefore,
                              builder: (final BuildContext context, final int framesBefore, final Widget? child)
                              {
                                return KPixSlider(
                                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                                  value: framesBefore.toDouble(),
                                  min: widget.options.frameMin.toDouble(),
                                  max: widget.options.frameMax.toDouble(),
                                  onChanged: enabled ? (final double newFramesBefore)
                                  {
                                    widget.options.framesBefore.value = newFramesBefore.toInt();
                                    GetIt.I.get<AppState>().repaintNotifier.repaint();
                                  } : null,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: _expansion4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text("Wrap Around"),
                      ),
                    ),
                    Expanded(
                      // ignore: avoid_redundant_argument_values
                      flex: _expansion5,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: widget.options.enabled,
                        builder: (final BuildContext context2, final bool enabled, final Widget? child2) {
                          return ValueListenableBuilder<int>(
                            valueListenable: widget.options.framesBefore,
                            builder: (final BuildContext context1, final int framesBefore, final Widget? child1) {
                              return ValueListenableBuilder<bool>(
                                valueListenable: widget.options.wrapAroundBefore,
                                builder: (final BuildContext context, final bool wrapAroundBefore, final Widget? child) {
                                  final bool isEnabled = enabled && framesBefore > 0;
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Switch(
                                      value: wrapAroundBefore,
                                      onChanged: isEnabled ? (final bool newWrapAroundBefore) {
                                        widget.options.wrapAroundBefore.value = newWrapAroundBefore;
                                        GetIt.I.get<AppState>().repaintNotifier.repaint();
                                      } : null,
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                //FRAMES AFTER
                Row(
                  children: <Widget>[

                    const Spacer(
                      // ignore: avoid_redundant_argument_values
                      flex: _expansion1,
                    ),
                    const Expanded(
                      flex: _expansion2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: _padding / 2.0),
                          child: Text("Frames After"),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: _expansion3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: widget.options.enabled,
                          builder: (final BuildContext context1, final bool enabled, final Widget? child1) {
                            return ValueListenableBuilder<int>(
                              valueListenable: widget.options.framesAfter,
                              builder: (final BuildContext context, final int framesAfter, final Widget? child)
                              {
                                return KPixSlider(
                                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                                  value: framesAfter.toDouble(),
                                  min: widget.options.frameMin.toDouble(),
                                  max: widget.options.frameMax.toDouble(),
                                  onChanged: enabled ? (final double newFramesAfter)
                                  {
                                    widget.options.framesAfter.value = newFramesAfter.toInt();
                                    GetIt.I.get<AppState>().repaintNotifier.repaint();
                                  } : null,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: _expansion4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text("Wrap Around"),
                      ),
                    ),
                    Expanded(
                      // ignore: avoid_redundant_argument_values
                      flex: _expansion5,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: widget.options.enabled,
                        builder: (final BuildContext context2, final bool enabled, final Widget? child2) {
                          return ValueListenableBuilder<int>(
                            valueListenable: widget.options.framesAfter,
                            builder: (final BuildContext context1, final int framesAfter, final Widget? child1) {
                              return ValueListenableBuilder<bool>(
                                valueListenable: widget.options.wrapAroundAfter,
                                builder: (final BuildContext context, final bool wrapAroundAfter, final Widget? child) {
                                  final bool isEnabled = enabled && framesAfter > 0;
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Switch(
                                      value: wrapAroundAfter,
                                      onChanged: isEnabled ? (final bool newWrapAroundAfter) {
                                        widget.options.wrapAroundAfter.value = newWrapAroundAfter;
                                        GetIt.I.get<AppState>().repaintNotifier.repaint();
                                      } : null,
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                //Opacity
                Row(
                  children: <Widget>[

                    const Spacer(
                      // ignore: avoid_redundant_argument_values
                      flex: _expansion1,
                    ),
                    const Expanded(
                      flex: _expansion2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: _padding / 2.0),
                          child: Text("Opacity"),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: _expansion3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: widget.options.enabled,
                          builder: (final BuildContext context1, final bool enabled, final Widget? child1) {
                            return ValueListenableBuilder<double>(
                              valueListenable: widget.options.opacity,
                              builder: (final BuildContext context, final double opacity, final Widget? child)
                              {
                                return KPixSlider(
                                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                                  value: opacity,
                                  min: widget.options.opacityMin,
                                  max: widget.options.opacityMax,
                                  decimals: 1,
                                  divisions: ((widget.options.opacityMax - widget.options.opacityMin) / widget.options.opacityStep).toInt(),
                                  onChanged: enabled ? (final double newOpacity)
                                  {
                                    widget.options.opacity.value = newOpacity;
                                    GetIt.I.get<AppState>().repaintNotifier.repaint();
                                  } : null,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: _expansion4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text("Gradual"),
                      ),
                    ),
                    Expanded(
                      // ignore: avoid_redundant_argument_values
                      flex: _expansion5,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: widget.options.enabled,
                        builder: (final BuildContext context2, final bool enabled, final Widget? child2) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: widget.options.gradualOpacity,
                            builder: (final BuildContext context, final bool gradualOpacity, final Widget? child) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Switch(
                                  value: gradualOpacity,
                                  onChanged: enabled ? (final bool newGradualOpacity) {
                                    widget.options.gradualOpacity.value = newGradualOpacity;
                                    GetIt.I.get<AppState>().repaintNotifier.repaint();
                                  } : null,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),


                //Tinting
                Row(
                  children: <Widget>[
                    const Spacer(
                      // ignore: avoid_redundant_argument_values
                      flex: _expansion1,
                    ),
                    const Expanded(
                      flex: _expansion2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: _padding / 2.0),
                          child: Text("Tinting"),
                        ),
                      ),
                    ),
                    Expanded(
                      // ignore: avoid_redundant_argument_values
                      flex: _expansion3 + _expansion4 + _expansion5,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: widget.options.enabled,
                        builder: (final BuildContext context2, final bool enabled, final Widget? child2) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: widget.options.tinting,
                            builder: (final BuildContext context, final bool tinting, final Widget? child) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Switch(
                                  value: tinting,
                                  onChanged: enabled ? (final bool newTintingValue) {
                                    widget.options.tinting.value = newTintingValue;
                                    GetIt.I.get<AppState>().repaintNotifier.repaint();
                                  } : null,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

                //Active Layer Only
                Row(
                  children: <Widget>[
                    const Spacer(
                      // ignore: avoid_redundant_argument_values
                      flex: _expansion1,
                    ),
                    const Expanded(
                      flex: _expansion2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: _padding / 2.0),
                          child: Text("Active Layer Only"),
                        ),
                      ),
                    ),
                    Expanded(
                      // ignore: avoid_redundant_argument_values
                      flex: _expansion3 + _expansion4 + _expansion5,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: widget.options.enabled,
                        builder: (final BuildContext context2, final bool enabled, final Widget? child2) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: widget.options.activeLayerOnly,
                            builder: (final BuildContext context, final bool activeLayerOnly, final Widget? child) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Switch(
                                  value: activeLayerOnly,
                                  onChanged: enabled ? (final bool newActiveLayerOnly) {
                                    widget.options.activeLayerOnly.value = newActiveLayerOnly;
                                    GetIt.I.get<AppState>().repaintNotifier.repaint();
                                  } : null,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _padding,),
                Tooltip(message: "Close", waitDuration: AppState.toolTipDuration, child: IconButton(onPressed: () {widget.onDismiss?.call();}, icon: const Icon(FontAwesomeIcons.check))),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
