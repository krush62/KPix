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

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_settings_widget.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';


const Map<OuterStrokeStyle, String> _outerStrokeStyleButtonLabelMap =
<OuterStrokeStyle, String>{
  OuterStrokeStyle.off: "OFF",
  OuterStrokeStyle.solid: "SLD",
  OuterStrokeStyle.relative: "RLT",
  OuterStrokeStyle.shade: "SHD",
  OuterStrokeStyle.glow: "GLW",
};

const Map<OuterStrokeStyle, String> _outerStrokeStyleTooltipMap =
<OuterStrokeStyle, String>{
  OuterStrokeStyle.off: "No outer stroke",
  OuterStrokeStyle.solid: "Solid color outer stroke",
  OuterStrokeStyle.relative: "Color relative outer stroke",
  OuterStrokeStyle.shade: "Shaded outer stroke",
  OuterStrokeStyle.glow: "Glowing outer stroke",
};

const Map<InnerStrokeStyle, String> _innerStrokeStyleButtonLabelMap =
<InnerStrokeStyle, String>{
  InnerStrokeStyle.off: "OFF",
  InnerStrokeStyle.solid: "SLD",
  InnerStrokeStyle.glow: "GLW",
  InnerStrokeStyle.shade: "SHD",
  InnerStrokeStyle.bevel: "BVL",
};

const Map<InnerStrokeStyle, String> _innerStrokeStyleTooltipMap =
<InnerStrokeStyle, String>{
  InnerStrokeStyle.off: "No inner stroke",
  InnerStrokeStyle.solid: "Solid color inner stroke",
  InnerStrokeStyle.glow: "Glowing inner stroke",
  InnerStrokeStyle.shade: "Shaded inner stroke",
  InnerStrokeStyle.bevel: "Beveled inner stroke",
};

const Map<DropShadowStyle, String> _dropShadowStyleButtonLabelMap =
<DropShadowStyle, String>{
  DropShadowStyle.off: "OFF",
  DropShadowStyle.solid: "SLD",
  DropShadowStyle.shade: "SHD",
};

const Map<DropShadowStyle, String> _dropShadowStyleTooltipMap =
<DropShadowStyle, String>{
  DropShadowStyle.off: "No drop shadow",
  DropShadowStyle.solid: "Solid color drop shadow",
  DropShadowStyle.shade: "Shaded drop shadow",
};

class DrawingLayerSettingsWidget extends LayerSettingsWidget
{
  final DrawingLayerState layer;

  const DrawingLayerSettingsWidget({super.key, required this.layer});

  @override
  State<DrawingLayerSettingsWidget> createState() => _DrawingLayerSettingsWidgetState();
}

class _DrawingLayerSettingsWidgetState extends State<DrawingLayerSettingsWidget>
{
  static const double _generalPadding = 8.0;
  static const double _buttonHeight = 24;
  static const double _iconSize = 16;
  static const double _dividerHeight = 2.0;
  static const double _visualDensityVert = -3.0;
  late KPixOverlay _colorPickDialog;
  late List<int> _darkenBrightenValues;
  late List<int> _glowDepthValues;

  @override
  void initState()
  {
    super.initState();
    _darkenBrightenValues = <int>[];
    for (int i = widget.layer.settings.constraints.darkenBrightenMin; i < 0; i++)
    {
      _darkenBrightenValues.add(i);
    }
    for (int i = 1; i <= widget.layer.settings.constraints.darkenBrightenMax; i++)
    {
      _darkenBrightenValues.add(i);
    }
    _glowDepthValues = <int>[];
    for (int i = widget.layer.settings.constraints.glowDepthMin; i < 0; i++)
    {
      _glowDepthValues.add(i);
    }
    for (int i = 1; i <= widget.layer.settings.constraints.glowDepthMax; i++)
    {
      _glowDepthValues.add(i);
    }
  }


  void onOuterColorSelected({required final ColorReference? color})
  {
    if (color != null)
    {
      _colorPickDialog.hide();
      widget.layer.settings.outerColorReference.value = color;
    }
  }

  void onInnerColorSelected({required final ColorReference? color})
  {
    if (color != null)
    {
      _colorPickDialog.hide();
      widget.layer.settings.innerColorReference.value = color;
    }
  }

  void onDropShadowColorSelected({required final ColorReference? color})
  {
    if (color != null)
    {
      _colorPickDialog.hide();
      widget.layer.settings.dropShadowColorReference.value = color;
    }
  }

  void closeDialog()
  {
    _colorPickDialog.hide();
  }

  String _getStepSliderLabel({required final int value})
  {
    final String prefix = value > 0 ? "+" : "";
    final String suffix = value == 1 || value == -1 ? " step" : " steps";
    return prefix + value.toString() + suffix;
  }


  @override
  Widget build(final BuildContext context)
  {
    return Padding(
      padding: const EdgeInsets.all(_generalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[

          //OUTER STROKE
          Text("OUTER STROKE", style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
          const SizedBox(height: _generalPadding),
          //outer stroke style
          ValueListenableBuilder<OuterStrokeStyle>(
            valueListenable: widget.layer.settings.outerStrokeStyle,
            builder: (final BuildContext context, final OuterStrokeStyle outerStrokeStyle, final Widget? child)
            {
              final List<ButtonSegment<OuterStrokeStyle>> outerStrokeButtons = <ButtonSegment<OuterStrokeStyle>>[];
              for (final OuterStrokeStyle oss in outerStrokeStyleValueMap.values)
              {
                outerStrokeButtons.add(
                  ButtonSegment<OuterStrokeStyle>(
                    value: oss,
                    label: Tooltip(
                      waitDuration: AppState.toolTipDuration,
                      message: _outerStrokeStyleTooltipMap[oss],
                      child: Text(
                        _outerStrokeStyleButtonLabelMap[oss]!,
                        style: Theme.of(context).textTheme.bodySmall!.apply(color: outerStrokeStyle == oss ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight),
                      ),
                    ),
                  ),
                );
              }

              return SegmentedButton<OuterStrokeStyle>(
                style: Theme.of(context).segmentedButtonTheme.style!.copyWith(visualDensity: const VisualDensity(vertical: _visualDensityVert)),
                segments: outerStrokeButtons,
                selected: <OuterStrokeStyle>{outerStrokeStyle},
                showSelectedIcon: false,
                onSelectionChanged: (final Set<OuterStrokeStyle> values) {
                  widget.layer.settings.outerStrokeStyle.value = values.first;
                },
              );
            },
          ),
          const SizedBox(height: _generalPadding),
          SizedBox(
            height: 80,
            child: ValueListenableBuilder<OuterStrokeStyle>(
              valueListenable: widget.layer.settings.outerStrokeStyle,
              builder: (final BuildContext context, final OuterStrokeStyle outerStrokeStyle, final Widget? child)
              {
                return Row(
                  children: <Widget>[
                    if (outerStrokeStyle != OuterStrokeStyle.off)
                      Expanded(
                        flex: 2,
                        child: ValueListenableBuilder<HashMap<Alignment, bool>>(
                          valueListenable: widget.layer.settings.outerSelectionMap,
                          builder: (final BuildContext context, final HashMap<Alignment, bool> outerMap, final Widget? child) {
                            return KPixDirectionWidget(
                              selectionMap: outerMap,
                              onChange: (final HashMap<Alignment, bool> directionMap) {
                                widget.layer.settings.outerSelectionMap.value = directionMap;
                              },
                              isExclusive: false,
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: _generalPadding),
                    if (outerStrokeStyle == OuterStrokeStyle.solid)...<Widget>[
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const Text("Color", textAlign: TextAlign.center,),
                            ValueListenableBuilder<ColorReference>(
                              valueListenable: widget.layer.settings.outerColorReference,
                              builder: (final BuildContext context, final ColorReference outerColor, final Widget? child)
                              {
                                return SizedBox(
                                  height: 48,
                                  child: IconButton.outlined(
                                    onPressed: () {
                                      _colorPickDialog = getColorPickerDialog(
                                        title: "SELECT OUTER STROKE COLOR",
                                        ramps: GetIt.I.get<AppState>().colorRamps,
                                        onColorSelected: onOuterColorSelected,
                                        onDismiss: closeDialog,);
                                      _colorPickDialog.show(context: context);
                                    },
                                    icon: const Icon(Icons.palette),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll<Color?>(outerColor.getIdColor().color),
                                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ],
                    if (outerStrokeStyle == OuterStrokeStyle.relative || outerStrokeStyle == OuterStrokeStyle.shade)
                      Expanded(
                        flex: 7,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text("Darken/Brighten"),
                            ValueListenableBuilder<int>(
                              valueListenable: widget.layer.settings.outerDarkenBrighten,
                              builder: (final BuildContext context, final int value, final Widget? child)
                              {
                                int valueIndex = _darkenBrightenValues.indexOf(value);
                                if (valueIndex == -1)
                                {
                                  valueIndex = _darkenBrightenValues.length ~/ 2;
                                }
                                return KPixSlider(
                                  value: valueIndex.toDouble(),
                                  max: _darkenBrightenValues.length.toDouble() - 1,
                                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                                  label: _getStepSliderLabel(value: value),
                                  onChanged: (final double value)
                                  {
                                    widget.layer.settings.outerDarkenBrighten.value = _darkenBrightenValues[value.toInt()];
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    if (outerStrokeStyle == OuterStrokeStyle.glow)
                      Expanded(
                        flex: 7,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Expanded(child: Text("Recursive", textAlign: TextAlign.end,)),
                                ValueListenableBuilder<bool>(
                                  valueListenable: widget.layer.settings.outerGlowRecursive,
                                  builder: (final BuildContext context, final bool glowRec, final Widget? child) {
                                    return Switch(
                                      value: glowRec,
                                      onChanged: (final bool value) {
                                        widget.layer.settings.outerGlowRecursive.value = value;
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            ValueListenableBuilder<int>(
                              valueListenable: widget.layer.settings.outerGlowDepth,
                              builder: (final BuildContext context, final int value, final Widget? child)
                              {
                                int valueIndex = _glowDepthValues.indexOf(value);
                                if (valueIndex == -1)
                                {
                                  valueIndex = _glowDepthValues.length ~/ 2;
                                }
                                return KPixSlider(
                                  value: valueIndex.toDouble(),
                                  max: _glowDepthValues.length.toDouble() - 1,
                                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                                  label: _getStepSliderLabel(value: value),
                                  onChanged: (final double value) {
                                    widget.layer.settings.outerGlowDepth.value = _glowDepthValues[value.toInt()];
                                  },
                                );
                              },

                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: _generalPadding),
          Tooltip(
            message: "Apply Outline",
            waitDuration: AppState.toolTipDuration,
            child: SizedBox(
              height: _buttonHeight,
              child: ValueListenableBuilder<OuterStrokeStyle>(
                valueListenable: widget.layer.settings.outerStrokeStyle,
                builder: (final BuildContext context, final OuterStrokeStyle outerStrokeStyle, final Widget? child) {
                  if (outerStrokeStyle == OuterStrokeStyle.off)
                  {
                    return const SizedBox(height: _buttonHeight);
                  }
                  else
                  {
                    return IconButton.outlined(
                      padding: EdgeInsets.zero,
                      iconSize: _iconSize,
                      onPressed: (outerStrokeStyle == OuterStrokeStyle.solid || outerStrokeStyle == OuterStrokeStyle.relative) ? () {
                        final Frame? frame = GetIt.I.get<AppState>().timeline.selectedFrame;
                        if (frame != null)
                        {
                          widget.layer.rasterOutline(layers: frame.layerList.getAllLayers());
                          widget.layer.settings.outerStrokeStyle.value = OuterStrokeStyle.off;
                          GetIt.I.get<HistoryManager>().addState(appState: GetIt.I.get<AppState>(), identifier: HistoryStateTypeIdentifier.layerSettingsRaster, originLayer: widget.layer);
                        }
                      } : null,
                      icon: const Icon(Icons.brush),
                    );
                  }
                },
              ),
            ),
          ),


          const SizedBox(height: _generalPadding),
          Divider(height: _dividerHeight, thickness: _dividerHeight, color: Theme.of(context).primaryColorLight,),
          const SizedBox(height: _generalPadding),

          //INNER STROKE
          Text("INNER STROKE", style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
          const SizedBox(height: _generalPadding),
          //inner stroke style
          ValueListenableBuilder<InnerStrokeStyle>(
            valueListenable: widget.layer.settings.innerStrokeStyle,
            builder: (final BuildContext context, final InnerStrokeStyle innerStrokeStyle, final Widget? child)
            {
              final List<ButtonSegment<InnerStrokeStyle>> innerStrokeButtons = <ButtonSegment<InnerStrokeStyle>>[];
              for (final InnerStrokeStyle iss in innerStrokeStyleValueMap.values)
              {
                innerStrokeButtons.add(
                  ButtonSegment<InnerStrokeStyle>(
                    value: iss,
                    label: Tooltip(
                      waitDuration: AppState.toolTipDuration,
                      message: _innerStrokeStyleTooltipMap[iss],
                      child: Text(
                        _innerStrokeStyleButtonLabelMap[iss]!,
                        style: Theme.of(context).textTheme.bodySmall!.apply(color: innerStrokeStyle == iss ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight),
                      ),
                    ),
                  ),
                );
              }

              return SegmentedButton<InnerStrokeStyle>(
                style: Theme.of(context).segmentedButtonTheme.style!.copyWith(visualDensity: const VisualDensity(vertical: _visualDensityVert)),
                segments: innerStrokeButtons,
                selected: <InnerStrokeStyle>{innerStrokeStyle},
                showSelectedIcon: false,
                onSelectionChanged: (final Set<InnerStrokeStyle> values) {
                  widget.layer.settings.innerStrokeStyle.value = values.first;
                },
              );
            },
          ),
          const SizedBox(height: _generalPadding),
          SizedBox(
            height: 80,
            child: ValueListenableBuilder<InnerStrokeStyle>(
                valueListenable: widget.layer.settings.innerStrokeStyle,
                builder: (final BuildContext context, final InnerStrokeStyle innerStrokeStyle, final Widget? child)
                {
                  return Row(
                    children: <Widget>[
                      if (innerStrokeStyle != InnerStrokeStyle.off)
                        Expanded(
                          flex: 2,
                          child: ValueListenableBuilder<HashMap<Alignment, bool>>(
                            valueListenable: widget.layer.settings.innerSelectionMap,
                            builder: (final BuildContext context, final HashMap<Alignment, bool> innerMap, final Widget? child) {
                              return KPixDirectionWidget(
                                selectionMap: innerMap,
                                onChange: (final HashMap<Alignment, bool> directionMap) {
                                  widget.layer.settings.innerSelectionMap.value = directionMap;
                                },
                                isExclusive: innerStrokeStyle == InnerStrokeStyle.bevel,
                              );
                            },
                          ),
                        ),
                      const SizedBox(width: _generalPadding),
                      if (innerStrokeStyle == InnerStrokeStyle.solid)...<Widget>[
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const Text("Color", textAlign: TextAlign.center,),
                              ValueListenableBuilder<ColorReference>(
                                valueListenable: widget.layer.settings.innerColorReference,
                                builder: (final BuildContext context, final ColorReference innerColor, final Widget? child)
                                {
                                  return SizedBox(
                                    height: 48,
                                    child: IconButton.outlined(
                                      onPressed: () {
                                        _colorPickDialog = getColorPickerDialog(
                                          title: "SELECT INNER STROKE COLOR",
                                          ramps: GetIt.I.get<AppState>().colorRamps,
                                          onColorSelected: onInnerColorSelected,
                                          onDismiss: closeDialog,);
                                        _colorPickDialog.show(context: context);
                                      },
                                      icon: const Icon(Icons.palette),
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll<Color?>(innerColor.getIdColor().color),
                                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ],
                      if (innerStrokeStyle == InnerStrokeStyle.shade)
                        Expanded(
                          flex: 7,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Spacer(),
                              const Text("Darken/Brighten"),
                              ValueListenableBuilder<int>(
                                valueListenable: widget.layer.settings.innerDarkenBrighten,
                                builder: (final BuildContext context, final int value, final Widget? child) {
                                  int valueIndex = _darkenBrightenValues.indexOf(value);
                                  if (valueIndex == -1)
                                  {
                                    valueIndex = _darkenBrightenValues.length ~/ 2;
                                  }
                                  return KPixSlider(
                                    value: valueIndex.toDouble(),
                                    max: _darkenBrightenValues.length.toDouble() - 1,
                                    textStyle: Theme.of(context).textTheme.bodyMedium!,
                                    label: _getStepSliderLabel(value: value),
                                    onChanged: (final double value) {
                                      widget.layer.settings.innerDarkenBrighten.value = _darkenBrightenValues[value.toInt()];
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      if (innerStrokeStyle == InnerStrokeStyle.glow)
                        Expanded(
                          flex: 7,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Expanded(child: Text("Recursive", textAlign: TextAlign.end,)),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: widget.layer.settings.innerGlowRecursive,
                                    builder: (final BuildContext context, final bool glowRec, final Widget? child) {
                                      return Switch(
                                        value: glowRec,
                                        onChanged: (final bool value) {
                                          widget.layer.settings.innerGlowRecursive.value = value;
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable: widget.layer.settings.innerGlowDepth,
                                builder: (final BuildContext context, final int value, final Widget? child)
                                {
                                  int valueIndex = _glowDepthValues.indexOf(value);
                                  if (valueIndex == -1)
                                  {
                                    valueIndex = _glowDepthValues.length ~/ 2;
                                  }
                                  return KPixSlider(
                                    value: valueIndex.toDouble(),
                                    max: _glowDepthValues.length.toDouble() - 1,
                                    textStyle: Theme.of(context).textTheme.bodyMedium!,
                                    label: _getStepSliderLabel(value: value),
                                    onChanged: (final double value) {
                                      widget.layer.settings.innerGlowDepth.value =  _glowDepthValues[value.toInt()];
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      if (innerStrokeStyle == InnerStrokeStyle.bevel)
                        Expanded(
                          flex: 7,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ValueListenableBuilder<int>(
                                valueListenable: widget.layer.settings.bevelDistance,
                                builder: (final BuildContext context, final int distance, final Widget? child) {
                                  return KPixSlider(
                                    value: distance.toDouble(),
                                    min: widget.layer.settings.constraints.bevelDistanceMin.toDouble(),
                                    max: widget.layer.settings.constraints.bevelDistanceMax.toDouble(),
                                    textStyle: Theme.of(context).textTheme.bodyMedium!,
                                    label: "$distance px",
                                    onChanged: (final double value) {
                                      widget.layer.settings.bevelDistance.value = value.round();
                                    },
                                  );
                                },
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable: widget.layer.settings.bevelStrength,
                                builder: (final BuildContext context, final int strength, final Widget? child) {
                                  return KPixSlider(
                                    value: strength.toDouble(),
                                    min: widget.layer.settings.constraints.bevelStrengthMin.toDouble(),
                                    max: widget.layer.settings.constraints.bevelStrengthMax.toDouble(),
                                    textStyle: Theme.of(context).textTheme.bodyMedium!,
                                    label: "$strength steps",
                                    onChanged: (final double value) {
                                      widget.layer.settings.bevelStrength.value = value.round();
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
            ),
          ),

          const SizedBox(width: _generalPadding),
          Tooltip(
            message: "Apply Inline",
            waitDuration: AppState.toolTipDuration,
            child: SizedBox(
              height: _buttonHeight,
              child: ValueListenableBuilder<InnerStrokeStyle>(
                valueListenable: widget.layer.settings.innerStrokeStyle,
                builder: (final BuildContext context, final InnerStrokeStyle innerStrokeStyle, final Widget? child) {
                  if (innerStrokeStyle == InnerStrokeStyle.off)
                  {
                    return const SizedBox(height: _buttonHeight);
                  }
                  else
                  {
                    return IconButton.outlined(
                      padding: EdgeInsets.zero,
                      iconSize: _iconSize,
                      onPressed: (innerStrokeStyle != InnerStrokeStyle.off) ? () {
                        final Frame? frame = GetIt.I.get<AppState>().timeline.selectedFrame;
                        if (frame != null)
                        {
                          widget.layer.rasterInline(layers: frame.layerList.getAllLayers(), frameIsSelected: true);
                          widget.layer.settings.innerStrokeStyle.value = InnerStrokeStyle.off;
                          GetIt.I.get<HistoryManager>().addState(appState: GetIt.I.get<AppState>(), identifier: HistoryStateTypeIdentifier.layerSettingsRaster, originLayer: widget.layer);
                        }
                      } : null,
                      icon: const Icon(Icons.brush),
                    );
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: _generalPadding),
          Divider(height: _dividerHeight, thickness: _dividerHeight, color: Theme.of(context).primaryColorLight,),
          const SizedBox(height: _generalPadding),



          //DROP SHADOW
          Text("DROP SHADOW", style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
          const SizedBox(height: _generalPadding),
          //inner stroke style
          ValueListenableBuilder<DropShadowStyle>(
            valueListenable: widget.layer.settings.dropShadowStyle,
            builder: (final BuildContext context, final DropShadowStyle dropShadowStyle, final Widget? child)
            {
              final List<ButtonSegment<DropShadowStyle>> dropShadowButtons = <ButtonSegment<DropShadowStyle>>[];
              for (final DropShadowStyle dss in dropShadowStyleValueMap.values)
              {
                dropShadowButtons.add(
                  ButtonSegment<DropShadowStyle>(
                    value: dss,
                    label: Tooltip(
                      waitDuration: AppState.toolTipDuration,
                      message: _dropShadowStyleTooltipMap[dss],
                      child: Text(
                        _dropShadowStyleButtonLabelMap[dss]!,
                        style: Theme.of(context).textTheme.bodySmall!.apply(color: dropShadowStyle == dss ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight),
                      ),
                    ),
                  ),
                );
              }


              return SegmentedButton<DropShadowStyle>(
                style: Theme.of(context).segmentedButtonTheme.style!.copyWith(visualDensity: const VisualDensity(vertical: _visualDensityVert)),
                segments: dropShadowButtons,
                selected: <DropShadowStyle>{dropShadowStyle},
                showSelectedIcon: false,
                onSelectionChanged: (final Set<DropShadowStyle> values) {
                  widget.layer.settings.dropShadowStyle.value = values.first;
                },
              );
            },
          ),
          const SizedBox(height: _generalPadding),
          ValueListenableBuilder<DropShadowStyle>(
            valueListenable: widget.layer.settings.dropShadowStyle,
            builder: (final BuildContext context, final DropShadowStyle dropShadowStyle, final Widget? child)
            {
              return Visibility(
                visible: dropShadowStyle != DropShadowStyle.off,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: ValueListenableBuilder<CoordinateSetI>(
                  valueListenable: widget.layer.settings.dropShadowOffset,
                  builder: (final BuildContext context, final CoordinateSetI offset, final Widget? child) {
                    return Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Expanded(child: Text("Horizontal")),
                            Expanded(
                              flex: 2,
                              child: KPixSlider(
                                value: offset.x.toDouble(),
                                min: widget.layer.settings.constraints.dropShadowOffsetMin.toDouble(),
                                max: widget.layer.settings.constraints.dropShadowOffsetMax.toDouble(),
                                showPlusSignForPositive: true,
                                onChanged: (final double value) {
                                  widget.layer.settings.dropShadowOffset.value = CoordinateSetI(x: value.round(), y: offset.y);
                                },
                                textStyle: Theme.of(context).textTheme.bodyMedium!,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Expanded(child: Text("Vertical")),
                            Expanded(
                              flex: 2,
                              child: KPixSlider(
                                value: offset.y.toDouble(),
                                min: widget.layer.settings.constraints.dropShadowOffsetMin.toDouble(),
                                max: widget.layer.settings.constraints.dropShadowOffsetMax.toDouble(),
                                showPlusSignForPositive: true,
                                onChanged: (final double value) {
                                  widget.layer.settings.dropShadowOffset.value = CoordinateSetI(x: offset.x, y: value.round());
                                },
                                textStyle: Theme.of(context).textTheme.bodyMedium!,
                              ),
                            ),
                          ],
                        ),
                        if (dropShadowStyle == DropShadowStyle.shade)
                          SizedBox(
                            height: 32,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Expanded(child: Text("Darken /\nBrighten")),
                                Expanded(
                                  flex: 2,
                                  child: ValueListenableBuilder<int>(
                                    valueListenable: widget.layer.settings.dropShadowDarkenBrighten,
                                    builder: (final BuildContext context, final int value, final Widget? child)
                                    {
                                      int valueIndex = _darkenBrightenValues.indexOf(value);
                                      if (valueIndex == -1)
                                      {
                                        valueIndex = _darkenBrightenValues.length ~/ 2;
                                      }
                                      return KPixSlider(
                                        value: valueIndex.toDouble(),
                                        max: _darkenBrightenValues.length.toDouble() - 1,
                                        showPlusSignForPositive: true,
                                        textStyle: Theme.of(context).textTheme.bodyMedium!,
                                        label: _getStepSliderLabel(value: value),
                                        onChanged: (final double value) {
                                          widget.layer.settings.dropShadowDarkenBrighten.value = _darkenBrightenValues[value.toInt()];
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (dropShadowStyle == DropShadowStyle.solid)
                        SizedBox(
                          height: 32,
                          child: Row(
                            children: <Widget>[
                              const Expanded(child: Text("Color")),
                              Expanded(
                                flex: 2,
                                child: ValueListenableBuilder<ColorReference>(
                                  valueListenable: widget.layer.settings.dropShadowColorReference,
                                  builder: (final BuildContext context, final ColorReference dropShadowColor, final Widget? child)
                                  {
                                    return IconButton.outlined(
                                      onPressed: () {
                                        _colorPickDialog = getColorPickerDialog(
                                          title: "SELECT DROP SHADOW COLOR",
                                          ramps: GetIt.I.get<AppState>().colorRamps,
                                          onColorSelected: onDropShadowColorSelected,
                                          onDismiss: closeDialog,);
                                        _colorPickDialog.show(context: context);
                                      },
                                      icon: const Icon(Icons.palette),
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll<Color?>(dropShadowColor.getIdColor().color),
                                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4.0),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: _generalPadding),
          Tooltip(
            message: "Apply Drop Shadow",
            waitDuration: AppState.toolTipDuration,
            child: SizedBox(
              height: _buttonHeight,
              child: ValueListenableBuilder<DropShadowStyle>(
                valueListenable: widget.layer.settings.dropShadowStyle,
                builder: (final BuildContext context, final DropShadowStyle dropShadowStyle, final Widget? child) {
                  if (dropShadowStyle == DropShadowStyle.off)
                  {
                    return const SizedBox(height: _buttonHeight);
                  }
                  else
                  {
                    return IconButton.outlined(
                      padding: EdgeInsets.zero,
                      iconSize: _iconSize,
                      onPressed: (dropShadowStyle == DropShadowStyle.solid) ? () {
                        final Frame? frame = GetIt.I.get<AppState>().timeline.selectedFrame;
                        if (frame != null)
                        {
                          widget.layer.rasterDropShadow(layers: frame.layerList.getAllLayers());
                          widget.layer.settings.dropShadowStyle.value = DropShadowStyle.off;
                          GetIt.I.get<HistoryManager>().addState(appState: GetIt.I.get<AppState>(), identifier: HistoryStateTypeIdentifier.layerSettingsRaster, originLayer: widget.layer);
                        }
                      } : null,
                      icon: const Icon(Icons.brush),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: _generalPadding),
        ],
      ),
    );
  }
}
