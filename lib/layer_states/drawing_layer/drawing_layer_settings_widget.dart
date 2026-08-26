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
import 'package:kpix/managers/history/history_manager.dart';
import 'package:kpix/managers/history/history_state_type.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

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
  static const double _styleRowHeight = 80.0;
  static const double _colorButtonHeight = 48.0;
  static const double _shadowRowHeight = 32.0;
  static const double _colorButtonRadius = 4.0;

  late KPixOverlay _colorPickDialog;
  late List<int> _darkenBrightenValues;
  late List<int> _glowDepthValues;

  DrawingLayerSettings get _settings => widget.layer.settings;

  @override
  void initState()
  {
    super.initState();
    _darkenBrightenValues = _stepValues(min: _settings.constraints.darkenBrightenMin, max: _settings.constraints.darkenBrightenMax);
    _glowDepthValues = _stepValues(min: _settings.constraints.glowDepthMin, max: _settings.constraints.glowDepthMax);
  }

  /// All steps from [min] to [max], leaving out zero.
  /// [min] needs to be smaller than 0.
  /// [max] needs to be bigger than 0.
  static List<int> _stepValues({required final int min, required final int max})
  {
    assert(min < 0);
    assert(max > 0);
    final List<int> values = <int>[];
    for (int i = min; i < 0; i++)
    {
      values.add(i);
    }
    for (int i = 1; i <= max; i++)
    {
      values.add(i);
    }
    return values;
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


  /// The heading above a settings section.
  List<Widget> _sectionHeader({required final BuildContext context, required final String title})
  {
    return <Widget>[
      Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
      const SizedBox(height: _generalPadding),
    ];
  }

  /// The rule between two settings sections.
  List<Widget> _sectionDivider({required final BuildContext context})
  {
    return <Widget>[
      const SizedBox(height: _generalPadding),
      Divider(height: _dividerHeight, thickness: _dividerHeight, color: Theme.of(context).primaryColorLight,),
      const SizedBox(height: _generalPadding),
    ];
  }

  /// The segmented button that picks the style of a section.
  Widget _styleSelector<T extends StyleOption>({
    required final ValueNotifier<T> notifier,
    required final List<T> values,
  })
  {
    return ValueListenableBuilder<T>(
      valueListenable: notifier,
      builder: (final BuildContext context, final T selected, final Widget? child)
      {
        final List<ButtonSegment<T>> segments = <ButtonSegment<T>>[];
        for (final T option in values)
        {
          segments.add(
            ButtonSegment<T>(
              value: option,
              label: Tooltip(
                waitDuration: AppState.toolTipDuration,
                message: option.desc,
                child: Text(
                  option.label,
                  style: Theme.of(context).textTheme.bodySmall!.apply(color: selected == option ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight),
                ),
              ),
            ),
          );
        }

        return SegmentedButton<T>(
          style: Theme.of(context).segmentedButtonTheme.style!.copyWith(visualDensity: const VisualDensity(vertical: _visualDensityVert)),
          segments: segments,
          selected: <T>{selected},
          showSelectedIcon: false,
          onSelectionChanged: (final Set<T> newValues) {
            notifier.value = newValues.first;
          },
        );
      },
    );
  }

  /// The direction picker that limits a stroke to certain edges.
  Widget _directionSelector({
    required final ValueNotifier<HashMap<Alignment, bool>> notifier,
    required final bool isExclusive,
  })
  {
    return ValueListenableBuilder<HashMap<Alignment, bool>>(
      valueListenable: notifier,
      builder: (final BuildContext context, final HashMap<Alignment, bool> selectionMap, final Widget? child) {
        return KPixDirectionWidget(
          selectionMap: selectionMap,
          onChange: (final HashMap<Alignment, bool> directionMap) {
            notifier.value = directionMap;
          },
          isExclusive: isExclusive,
        );
      },
    );
  }

  /// A slider over [values], which skip zero and are therefore not contiguous.
  ///
  /// The slider runs over the indices of [values] and maps back through the list,
  /// falling back to the middle entry when the current value is not in there.
  Widget _indexedSlider({
    required final ValueNotifier<int> notifier,
    required final List<int> values,
    final bool showPlusSignForPositive = false,
  })
  {
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (final BuildContext context, final int value, final Widget? child)
      {
        int valueIndex = values.indexOf(value);
        if (valueIndex == -1)
        {
          valueIndex = values.length ~/ 2;
        }
        return KPixSlider(
          value: valueIndex.toDouble(),
          max: values.length.toDouble() - 1,
          showPlusSignForPositive: showPlusSignForPositive,
          textStyle: Theme.of(context).textTheme.bodyMedium!,
          label: _getStepSliderLabel(value: value),
          onChanged: (final double newValue) {
            notifier.value = values[newValue.toInt()];
          },
        );
      },
    );
  }

  /// A button showing the current color of [notifier], opening a picker for it.
  Widget _colorButton({
    required final String dialogTitle,
    required final ValueNotifier<ColorReference> notifier,
  })
  {
    return ValueListenableBuilder<ColorReference>(
      valueListenable: notifier,
      builder: (final BuildContext context, final ColorReference currentColor, final Widget? child)
      {
        return IconButton.outlined(
          onPressed: () {
            _colorPickDialog = getColorPickerDialog(
              title: dialogTitle,
              ramps: GetIt.I.get<AppState>().colorRamps,
              onColorSelected: ({required final ColorReference? color}) {
                if (color != null)
                {
                  _colorPickDialog.hide();
                  notifier.value = color;
                }
              },
              onDismiss: closeDialog,
            );
            _colorPickDialog.show(context: context);
          },
          icon: const Icon(Icons.palette),
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color?>(currentColor.getIdColor().color),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_colorButtonRadius),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The "recursive" switch and the depth slider shared by both glow styles.
  List<Widget> _glowControls({
    required final ValueNotifier<bool> recursiveNotifier,
    required final ValueNotifier<int> depthNotifier,
  })
  {
    return <Widget>[
      Row(
        children: <Widget>[
          const Expanded(child: Text("Recursive", textAlign: TextAlign.end,)),
          ValueListenableBuilder<bool>(
            valueListenable: recursiveNotifier,
            builder: (final BuildContext context, final bool glowRec, final Widget? child) {
              return Switch(
                value: glowRec,
                onChanged: (final bool value) {
                  recursiveNotifier.value = value;
                },
              );
            },
          ),
        ],
      ),
      _indexedSlider(notifier: depthNotifier, values: _glowDepthValues),
    ];
  }

  /// The button that bakes a section's effect into the layer's pixels.
  ///
  /// Hidden while the style is [offValue] and disabled unless [canApply] accepts
  /// the current style. Applying calls [raster], resets the style and records a
  /// history state.
  Widget _applyButton<T>({
    required final String tooltip,
    required final ValueNotifier<T> notifier,
    required final T offValue,
    required final bool Function(T style) canApply,
    required final void Function(Frame frame) raster,
  })
  {
    return Tooltip(
      message: tooltip,
      waitDuration: AppState.toolTipDuration,
      child: SizedBox(
        height: _buttonHeight,
        child: ValueListenableBuilder<T>(
          valueListenable: notifier,
          builder: (final BuildContext context, final T style, final Widget? child) {
            if (style == offValue)
            {
              return const SizedBox(height: _buttonHeight);
            }
            else
            {
              return IconButton.outlined(
                padding: EdgeInsets.zero,
                iconSize: _iconSize,
                onPressed: canApply(style) ? () {
                  final Frame? frame = GetIt.I.get<AppState>().timeline.selectedFrame;
                  if (frame != null)
                  {
                    raster(frame);
                    notifier.value = offValue;
                    GetIt.I.get<HistoryManager>().addState(appState: GetIt.I.get<AppState>(), identifier: HistoryStateTypeIdentifier.layerSettingsRaster, originLayer: widget.layer);
                  }
                } : null,
                icon: const Icon(Icons.brush),
              );
            }
          },
        ),
      ),
    );
  }


  //=========================== SECTIONS ===========================

  List<Widget> _outerStrokeSection({required final BuildContext context})
  {
    return <Widget>[
      ..._sectionHeader(context: context, title: "OUTER STROKE"),
      _styleSelector<OuterStrokeStyle>(
        notifier: _settings.outerStrokeStyle,
        values: OuterStrokeStyle.values,
      ),
      const SizedBox(height: _generalPadding),
      SizedBox(
        height: _styleRowHeight,
        child: ValueListenableBuilder<OuterStrokeStyle>(
          valueListenable: _settings.outerStrokeStyle,
          builder: (final BuildContext context, final OuterStrokeStyle outerStrokeStyle, final Widget? child)
          {
            return Row(
              children: <Widget>[
                if (outerStrokeStyle != OuterStrokeStyle.off)
                  Expanded(
                    flex: 2,
                    child: _directionSelector(notifier: _settings.outerSelectionMap, isExclusive: false),
                  ),
                const SizedBox(width: _generalPadding),
                if (outerStrokeStyle == OuterStrokeStyle.solid)
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Text("Color", textAlign: TextAlign.center,),
                        SizedBox(
                          height: _colorButtonHeight,
                          child: _colorButton(
                            dialogTitle: "SELECT OUTER STROKE COLOR",
                            notifier: _settings.outerColorReference,
                          ),
                        ),
                        const Spacer(),
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
                        _indexedSlider(notifier: _settings.outerDarkenBrighten, values: _darkenBrightenValues),
                      ],
                    ),
                  ),
                if (outerStrokeStyle == OuterStrokeStyle.glow)
                  Expanded(
                    flex: 7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _glowControls(
                        recursiveNotifier: _settings.outerGlowRecursive,
                        depthNotifier: _settings.outerGlowDepth,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      const SizedBox(width: _generalPadding),
      _applyButton<OuterStrokeStyle>(
        tooltip: "Apply Outline",
        notifier: _settings.outerStrokeStyle,
        offValue: OuterStrokeStyle.off,
        canApply: (final OuterStrokeStyle style) => style == OuterStrokeStyle.solid || style == OuterStrokeStyle.relative,
        raster: (final Frame frame) => widget.layer.rasterOutline(layers: frame.layerList.getAllLayers()),
      ),
    ];
  }

  List<Widget> _innerStrokeSection({required final BuildContext context})
  {
    return <Widget>[
      ..._sectionHeader(context: context, title: "INNER STROKE"),
      _styleSelector<InnerStrokeStyle>(
        notifier: _settings.innerStrokeStyle,
        values: InnerStrokeStyle.values,
      ),
      const SizedBox(height: _generalPadding),
      SizedBox(
        height: _styleRowHeight,
        child: ValueListenableBuilder<InnerStrokeStyle>(
          valueListenable: _settings.innerStrokeStyle,
          builder: (final BuildContext context, final InnerStrokeStyle innerStrokeStyle, final Widget? child)
          {
            return Row(
              children: <Widget>[
                if (innerStrokeStyle != InnerStrokeStyle.off)
                  Expanded(
                    flex: 2,
                    child: _directionSelector(
                      notifier: _settings.innerSelectionMap,
                      isExclusive: innerStrokeStyle == InnerStrokeStyle.bevel,
                    ),
                  ),
                const SizedBox(width: _generalPadding),
                if (innerStrokeStyle == InnerStrokeStyle.solid)
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Text("Color", textAlign: TextAlign.center,),
                        SizedBox(
                          height: _colorButtonHeight,
                          child: _colorButton(
                            dialogTitle: "SELECT INNER STROKE COLOR",
                            notifier: _settings.innerColorReference,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                if (innerStrokeStyle == InnerStrokeStyle.shade)
                  Expanded(
                    flex: 7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Spacer(),
                        const Text("Darken/Brighten"),
                        _indexedSlider(notifier: _settings.innerDarkenBrighten, values: _darkenBrightenValues),
                      ],
                    ),
                  ),
                if (innerStrokeStyle == InnerStrokeStyle.glow)
                  Expanded(
                    flex: 7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _glowControls(
                        recursiveNotifier: _settings.innerGlowRecursive,
                        depthNotifier: _settings.innerGlowDepth,
                      ),
                    ),
                  ),
                if (innerStrokeStyle == InnerStrokeStyle.bevel)
                  Expanded(
                    flex: 7,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ValueListenableBuilder<int>(
                          valueListenable: _settings.bevelDistance,
                          builder: (final BuildContext context, final int distance, final Widget? child) {
                            return KPixSlider(
                              value: distance.toDouble(),
                              min: _settings.constraints.bevelDistanceMin.toDouble(),
                              max: _settings.constraints.bevelDistanceMax.toDouble(),
                              textStyle: Theme.of(context).textTheme.bodyMedium!,
                              label: "$distance px",
                              onChanged: (final double value) {
                                _settings.bevelDistance.value = value.round();
                              },
                            );
                          },
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: _settings.bevelStrength,
                          builder: (final BuildContext context, final int strength, final Widget? child) {
                            return KPixSlider(
                              value: strength.toDouble(),
                              min: _settings.constraints.bevelStrengthMin.toDouble(),
                              max: _settings.constraints.bevelStrengthMax.toDouble(),
                              textStyle: Theme.of(context).textTheme.bodyMedium!,
                              label: "$strength steps",
                              onChanged: (final double value) {
                                _settings.bevelStrength.value = value.round();
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
      _applyButton<InnerStrokeStyle>(
        tooltip: "Apply Inline",
        notifier: _settings.innerStrokeStyle,
        offValue: InnerStrokeStyle.off,
        canApply: (final InnerStrokeStyle style) => style != InnerStrokeStyle.off,
        raster: (final Frame frame) => widget.layer.rasterInline(layers: frame.layerList.getAllLayers(), frameIsSelected: true),
      ),
    ];
  }

  List<Widget> _dropShadowSection({required final BuildContext context})
  {
    return <Widget>[
      ..._sectionHeader(context: context, title: "DROP SHADOW"),
      _styleSelector<DropShadowStyle>(
        notifier: _settings.dropShadowStyle,
        values: DropShadowStyle.values,
      ),
      const SizedBox(height: _generalPadding),
      ValueListenableBuilder<DropShadowStyle>(
        valueListenable: _settings.dropShadowStyle,
        builder: (final BuildContext context, final DropShadowStyle dropShadowStyle, final Widget? child)
        {
          return Visibility(
            visible: dropShadowStyle != DropShadowStyle.off,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: ValueListenableBuilder<CoordinateSetI>(
              valueListenable: _settings.dropShadowOffset,
              builder: (final BuildContext context, final CoordinateSetI offset, final Widget? child) {
                return Column(
                  children: <Widget>[
                    _offsetRow(
                      context: context,
                      label: "Horizontal",
                      value: offset.x,
                      onChanged: (final int value) {
                        _settings.dropShadowOffset.value = CoordinateSetI(x: value, y: offset.y);
                      },
                    ),
                    _offsetRow(
                      context: context,
                      label: "Vertical",
                      value: offset.y,
                      onChanged: (final int value) {
                        _settings.dropShadowOffset.value = CoordinateSetI(x: offset.x, y: value);
                      },
                    ),
                    if (dropShadowStyle == DropShadowStyle.shade)
                      SizedBox(
                        height: _shadowRowHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Expanded(child: Text("Darken /\nBrighten")),
                            Expanded(
                              flex: 2,
                              child: _indexedSlider(
                                notifier: _settings.dropShadowDarkenBrighten,
                                values: _darkenBrightenValues,
                                showPlusSignForPositive: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (dropShadowStyle == DropShadowStyle.solid)
                      SizedBox(
                        height: _shadowRowHeight,
                        child: Row(
                          children: <Widget>[
                            const Expanded(child: Text("Color")),
                            Expanded(
                              flex: 2,
                              child: _colorButton(
                                dialogTitle: "SELECT DROP SHADOW COLOR",
                                notifier: _settings.dropShadowColorReference,
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
      _applyButton<DropShadowStyle>(
        tooltip: "Apply Drop Shadow",
        notifier: _settings.dropShadowStyle,
        offValue: DropShadowStyle.off,
        canApply: (final DropShadowStyle style) => style == DropShadowStyle.solid,
        raster: (final Frame frame) => widget.layer.rasterDropShadow(layers: frame.layerList.getAllLayers()),
      ),
    ];
  }

  /// One axis of the drop shadow offset.
  Widget _offsetRow({
    required final BuildContext context,
    required final String label,
    required final int value,
    required final void Function(int value) onChanged,
  })
  {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(child: Text(label)),
        Expanded(
          flex: 2,
          child: KPixSlider(
            value: value.toDouble(),
            min: _settings.constraints.dropShadowOffsetMin.toDouble(),
            max: _settings.constraints.dropShadowOffsetMax.toDouble(),
            showPlusSignForPositive: true,
            onChanged: (final double newValue) {
              onChanged(newValue.round());
            },
            textStyle: Theme.of(context).textTheme.bodyMedium!,
          ),
        ),
      ],
    );
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
          ..._outerStrokeSection(context: context),
          ..._sectionDivider(context: context),
          ..._innerStrokeSection(context: context),
          ..._sectionDivider(context: context),
          ..._dropShadowSection(context: context),
          const SizedBox(height: _generalPadding),
        ],
      ),
    );
  }
}
