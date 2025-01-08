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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/layer_states/drawing_layer_settings.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlay_entries.dart';


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

class DrawingLayerSettingsWidget extends StatefulWidget
{
  final DrawingLayerSettings settings;
  const DrawingLayerSettingsWidget({super.key, required this.settings});

  @override
  State<DrawingLayerSettingsWidget> createState() => _DrawingLayerSettingsWidgetState();
}

class _DrawingLayerSettingsWidgetState extends State<DrawingLayerSettingsWidget>
{
  final double generalPadding = 8.0;
  late KPixOverlay _colorPickDialog;


  void onOuterColorSelected({required final ColorReference? color})
  {
    if (color != null)
    {
      _colorPickDialog.hide();
      widget.settings.outerColorReference.value = color;
    }
  }

  void onInnerColorSelected({required final ColorReference? color})
  {
    if (color != null)
    {
      _colorPickDialog.hide();
      widget.settings.innerColorReference.value = color;
    }
  }

  void onDropShadowColorSelected({required final ColorReference? color})
  {
    if (color != null)
    {
      _colorPickDialog.hide();
      widget.settings.dropShadowColorReference.value = color;
    }
  }

  void closeDialog()
  {
    _colorPickDialog.hide();
  }


  @override
  Widget build(final BuildContext context)
  {
    return Padding(
      padding: EdgeInsets.all(generalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[

          Divider(height: 2.0, thickness: 2.0, color: Theme.of(context).primaryColorLight,),
          SizedBox(height: generalPadding),


          //OUTER STROKE
          Text("OUTER STROKE", style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
          SizedBox(height: generalPadding),
          //outer stroke style
          ValueListenableBuilder<OuterStrokeStyle>(
            valueListenable: widget.settings.outerStrokeStyle,
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
                segments: outerStrokeButtons,
                selected: <OuterStrokeStyle>{outerStrokeStyle},
                showSelectedIcon: false,
                onSelectionChanged: (final Set<OuterStrokeStyle> values) {
                  widget.settings.outerStrokeStyle.value = values.first;
                },
              );
            },
          ),
          SizedBox(height: generalPadding),
          SizedBox(
            height: 100,
            child: ValueListenableBuilder<OuterStrokeStyle>(
              valueListenable: widget.settings.outerStrokeStyle,
              builder: (final BuildContext context, final OuterStrokeStyle outerStrokeStyle, final Widget? child)
              {
                return Row(
                  children: <Widget>[
                    if (outerStrokeStyle != OuterStrokeStyle.off)
                      Expanded(
                        flex: 2,
                        child: ValueListenableBuilder<HashMap<Alignment, bool>>(
                          valueListenable: widget.settings.outerSelectionMap,
                          builder: (final BuildContext context, final HashMap<Alignment, bool> outerMap, final Widget? child) {
                            return KPixDirectionWidget(
                              selectionMap: outerMap,
                              onChange: (final HashMap<Alignment, bool> directionMap) {
                                widget.settings.outerSelectionMap.value = directionMap;
                              },
                              isExclusive: false,
                            );
                          },
                        ),
                      ),
                    SizedBox(width: generalPadding),
                    if (outerStrokeStyle == OuterStrokeStyle.solid)
                      Expanded(
                        flex: 7,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: ValueListenableBuilder<ColorReference>(
                                  valueListenable: widget.settings.outerColorReference,
                                  builder: (final BuildContext context, final ColorReference outerColor, final Widget? child)
                                  {
                                    return IconButton.outlined(
                                      onPressed: () {
                                        _colorPickDialog = getColorPickerDialog(
                                          title: "SELECT OUTER STROKE COLOR",
                                          ramps: GetIt.I.get<AppState>().colorRamps,
                                          onColorSelected: onOuterColorSelected,
                                          onDismiss: closeDialog,);
                                        _colorPickDialog.show(context: context);
                                      },
                                      icon: const FaIcon(FontAwesomeIcons.palette),
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll<Color?>(outerColor.getIdColor().color),
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
                            ),
                            SizedBox(width: generalPadding),
                            Expanded(
                              flex: 2,
                              child: Tooltip(
                                message: "Raster Solid Outline",
                                waitDuration: AppState.toolTipDuration,
                                child: IconButton.outlined(
                                  onPressed: () {
                                    print("OUTER RASTER SOLID OUTLINE");
                                  },
                                  icon: const FaIcon(FontAwesomeIcons.paintbrush),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (outerStrokeStyle == OuterStrokeStyle.relative || outerStrokeStyle == OuterStrokeStyle.shade)
                      Expanded(
                        flex: 7,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text("Darken/Brighten"),
                            ValueListenableBuilder<int>(
                              valueListenable: widget.settings.outerDarkenBrighten,
                              builder: (final BuildContext context, final int value, final Widget? child)
                              {
                                return KPixSlider(
                                  value: value.toDouble(),
                                  min: widget.settings.constraints.darkenBrightenMin.toDouble(),
                                  max: widget.settings.constraints.darkenBrightenMax.toDouble(),
                                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                                  showPlusSignForPositive: true,
                                  onChanged: (final double value) {
                                    widget.settings.outerDarkenBrighten.value = value.round();
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
                            const Text("Direction"),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                const Text("<"),
                                ValueListenableBuilder<bool>(
                                  valueListenable: widget.settings.outerGlowDirection,
                                  builder: (final BuildContext context, final bool glowDir, final Widget? child) {
                                    return Switch(
                                      value: glowDir,
                                      onChanged: (final bool value) {
                                        widget.settings.outerGlowDirection.value = value;
                                      },
                                    );
                                  },
                                ),
                                const Text(">"),
                              ],
                            ),
                            ValueListenableBuilder<int>(
                              valueListenable: widget.settings.outerGlowDepth,
                              builder: (final BuildContext context, final int value, final Widget? child) {
                                return KPixSlider(
                                  value: value.toDouble(),
                                  min: widget.settings.constraints.glowDepthMin.toDouble(),
                                  max: widget.settings.constraints.glowDepthMax.toDouble(),
                                  label: "$value steps",
                                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                                  onChanged: (final double value) {
                                    widget.settings.outerGlowDepth.value = value.round();
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




          Divider(height: 2.0, thickness: 2.0, color: Theme.of(context).primaryColorLight,),
          SizedBox(height: generalPadding),



          //INNER STROKE
          Text("INNER STROKE", style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
          SizedBox(height: generalPadding),
          //inner stroke style
          ValueListenableBuilder<InnerStrokeStyle>(
            valueListenable: widget.settings.innerStrokeStyle,
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
                segments: innerStrokeButtons,
                selected: <InnerStrokeStyle>{innerStrokeStyle},
                showSelectedIcon: false,
                onSelectionChanged: (final Set<InnerStrokeStyle> values) {
                  widget.settings.innerStrokeStyle.value = values.first;
                },
              );
            },
          ),
          SizedBox(height: generalPadding),
          SizedBox(
            height: 100,
            child: ValueListenableBuilder<InnerStrokeStyle>(
                valueListenable: widget.settings.innerStrokeStyle,
                builder: (final BuildContext context, final InnerStrokeStyle innerStrokeStyle, final Widget? child)
                {
                  return Row(
                    children: <Widget>[
                      if (innerStrokeStyle != InnerStrokeStyle.off)
                        Expanded(
                          flex: 2,
                          child: ValueListenableBuilder<HashMap<Alignment, bool>>(
                            valueListenable: widget.settings.innerSelectionMap,
                            builder: (final BuildContext context, final HashMap<Alignment, bool> innerMap, final Widget? child) {
                              return KPixDirectionWidget(
                                selectionMap: innerMap,
                                onChange: (final HashMap<Alignment, bool> directionMap) {
                                  widget.settings.innerSelectionMap.value = directionMap;
                                },
                                isExclusive: innerStrokeStyle == InnerStrokeStyle.bevel,
                              );
                            },
                          ),
                        ),
                      SizedBox(width: generalPadding),
                      if (innerStrokeStyle == InnerStrokeStyle.solid)
                        Expanded(
                          flex: 7,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ValueListenableBuilder<ColorReference>(
                                    valueListenable: widget.settings.innerColorReference,
                                    builder: (final BuildContext context, final ColorReference innerColor, final Widget? child)
                                    {
                                      return IconButton.outlined(
                                        onPressed: () {
                                          _colorPickDialog = getColorPickerDialog(
                                            title: "SELECT INNER STROKE COLOR",
                                            ramps: GetIt.I.get<AppState>().colorRamps,
                                            onColorSelected: onInnerColorSelected,
                                            onDismiss: closeDialog,);
                                          _colorPickDialog.show(context: context);
                                        },
                                        icon: const FaIcon(FontAwesomeIcons.palette),
                                        style: ButtonStyle(
                                          backgroundColor: WidgetStatePropertyAll<Color?>(innerColor.getIdColor().color),
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
                              ),
                              SizedBox(width: generalPadding),
                              Expanded(
                                flex: 2,
                                child: Tooltip(
                                  message: "Raster Solid Inline",
                                  waitDuration: AppState.toolTipDuration,
                                  child: IconButton.outlined(
                                    onPressed: () {
                                      print("RASTER INNER SOLID STROKE");
                                    },
                                    icon: const FaIcon(FontAwesomeIcons.paintbrush),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (innerStrokeStyle == InnerStrokeStyle.shade)
                        Expanded(
                          flex: 7,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Text("Darken/Brighten"),
                              ValueListenableBuilder<int>(
                                valueListenable: widget.settings.innerDarkenBrighten,
                                builder: (final BuildContext context, final int value, final Widget? child) {
                                  return KPixSlider(
                                    value: value.toDouble(),
                                    min: widget.settings.constraints.darkenBrightenMin.toDouble(),
                                    max: widget.settings.constraints.darkenBrightenMax.toDouble(),
                                    textStyle: Theme.of(context).textTheme.bodyMedium!,
                                    showPlusSignForPositive: true,
                                    onChanged: (final double value) {
                                      widget.settings.innerDarkenBrighten.value = value.round();
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
                              const Text("Depth"),
                              ValueListenableBuilder<int>(
                                valueListenable: widget.settings.innerGlowDepth,
                                builder: (final BuildContext context, final int value, final Widget? child) {
                                  return KPixSlider(
                                    value: value.toDouble(),
                                    min: widget.settings.constraints.glowDepthMin.toDouble(),
                                    max: widget.settings.constraints.glowDepthMax.toDouble(),
                                    textStyle: Theme.of(context).textTheme.bodyMedium!,
                                    onChanged: (final double value) {
                                      widget.settings.innerGlowDepth.value = value.round();
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
                              const Text("Distance"),
                              ValueListenableBuilder<int>(
                                valueListenable: widget.settings.bevelDistance,
                                builder: (final BuildContext context, final int value, final Widget? child) {
                                  return KPixSlider(
                                    value: value.toDouble(),
                                    min: widget.settings.constraints.bevelDistanceMin.toDouble(),
                                    max: widget.settings.constraints.bevelDistanceMax.toDouble(),
                                    textStyle: Theme.of(context).textTheme.bodyMedium!,
                                    onChanged: (final double value) {
                                      widget.settings.bevelDistance.value = value.round();
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


          Divider(height: 2.0, thickness: 2.0, color: Theme.of(context).primaryColorLight,),
          SizedBox(height: generalPadding),



          //DROP SHADOW
          Text("DROP SHADOW", style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
          SizedBox(height: generalPadding),
          //inner stroke style
          ValueListenableBuilder<DropShadowStyle>(
            valueListenable: widget.settings.dropShadowStyle,
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
                segments: dropShadowButtons,
                selected: <DropShadowStyle>{dropShadowStyle},
                showSelectedIcon: false,
                onSelectionChanged: (final Set<DropShadowStyle> values) {
                  widget.settings.dropShadowStyle.value = values.first;
                },
              );
            },
          ),
          SizedBox(height: generalPadding),
          ValueListenableBuilder<DropShadowStyle>(
            valueListenable: widget.settings.dropShadowStyle,
            builder: (final BuildContext context, final DropShadowStyle dropShadowStyle, final Widget? child)
            {
              return Visibility(
                visible: dropShadowStyle != DropShadowStyle.off,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: ValueListenableBuilder<CoordinateSetI>(
                  valueListenable: widget.settings.dropShadowOffset,
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
                                min: widget.settings.constraints.dropShadowOffsetMin.toDouble(),
                                max: widget.settings.constraints.dropShadowOffsetMax.toDouble(),
                                showPlusSignForPositive: true,
                                onChanged: (final double value) {
                                  widget.settings.dropShadowOffset.value = CoordinateSetI(x: value.round(), y: offset.y);
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
                                min: widget.settings.constraints.dropShadowOffsetMin.toDouble(),
                                max: widget.settings.constraints.dropShadowOffsetMax.toDouble(),
                                showPlusSignForPositive: true,
                                onChanged: (final double value) {
                                  widget.settings.dropShadowOffset.value = CoordinateSetI(x: offset.x, y: value.round());
                                },
                                textStyle: Theme.of(context).textTheme.bodyMedium!,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 100,
                          child: Row(
                            children: <Widget>[
                              SizedBox(width: generalPadding),
                              if (dropShadowStyle == DropShadowStyle.solid)
                                Expanded(
                                  flex: 7,
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: ValueListenableBuilder<ColorReference>(
                                            valueListenable: widget.settings.dropShadowColorReference,
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
                                                icon: const FaIcon(FontAwesomeIcons.palette),
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
                                      ),
                                      SizedBox(width: generalPadding),
                                      Expanded(
                                        flex: 2,
                                        child: Tooltip(
                                          message: "Raster Solid Drop Shadow",
                                          waitDuration: AppState.toolTipDuration,
                                          child: IconButton.outlined(
                                            onPressed: () {
                                              print("RASTER INNER SOLID STROKE");
                                            },
                                            icon: const FaIcon(FontAwesomeIcons.paintbrush),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (dropShadowStyle == DropShadowStyle.shade)
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      const Text("Darken/Brighten"),
                                      ValueListenableBuilder<int>(
                                        valueListenable: widget.settings.dropShadowDarkenBrighten,
                                        builder: (final BuildContext context, final int value, final Widget? child) {
                                          return KPixSlider(
                                            value: value.toDouble(),
                                            min: widget.settings.constraints.darkenBrightenMin.toDouble(),
                                            max: widget.settings.constraints.darkenBrightenMax.toDouble(),
                                            showPlusSignForPositive: true,
                                            textStyle: Theme.of(context).textTheme.bodyMedium!,
                                            onChanged: (final double value) {
                                              widget.settings.dropShadowDarkenBrighten.value = value.round();
                                            },
                                          );
                                        },
                                      ),
                                    ],
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

          Divider(height: 2.0, thickness: 2.0, color: Theme.of(context).primaryColorLight,),
          SizedBox(height: generalPadding),

        ],
      ),
    );
  }
}
