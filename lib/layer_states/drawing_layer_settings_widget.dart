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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kpix/layer_states/drawing_layer_settings.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/controls/kpix_direction_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';


const Map<OuterStrokeStyle, String> _outerStrokeStyleNames =
<OuterStrokeStyle, String>{
  OuterStrokeStyle.off: "OFF",
  OuterStrokeStyle.solid: "SOLID",
  OuterStrokeStyle.relative: "RELATE",
  OuterStrokeStyle.shade: "SHADE",
};

const Map<InnerStrokeStyle, String> _innerStrokeStyleNames =
<InnerStrokeStyle, String>{
  InnerStrokeStyle.off: "OFF",
  InnerStrokeStyle.solid: "SOLID",
  InnerStrokeStyle.glow: "GLOW",
  InnerStrokeStyle.shade: "SHADE",
};

const Map<DropShadowStyle, String> _dropShadowStyleNames =
<DropShadowStyle, String>{
  DropShadowStyle.off: "OFF",
  DropShadowStyle.solid: "SOLID",
  DropShadowStyle.shade: "SHADE",
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

  @override
  Widget build(final BuildContext context)
  {
    return Padding(
      padding: EdgeInsets.all(generalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[

          Divider(height: 2.0, thickness: 2.0, color: Theme.of(context).primaryColor,),
          SizedBox(height: generalPadding),


          //OUTER STROKE
          Text("OUTER STROKE", style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
          SizedBox(height: generalPadding),
          //outer stroke style
          ValueListenableBuilder<OuterStrokeStyle>(
            valueListenable: widget.settings.outerStrokeStyle,
            builder: (final BuildContext context, final OuterStrokeStyle outerStrokeStyle, final Widget? child)
            {
              return SegmentedButton<OuterStrokeStyle>(
                segments: <ButtonSegment<OuterStrokeStyle>>[
                  ButtonSegment<OuterStrokeStyle>(
                    value: OuterStrokeStyle.off,
                    label: Text(_outerStrokeStyleNames[OuterStrokeStyle.off]!, style: Theme.of(context).textTheme.bodySmall!.apply(color: outerStrokeStyle == OuterStrokeStyle.off ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)),
                  ),
                  ButtonSegment<OuterStrokeStyle>(
                    value: OuterStrokeStyle.solid,
                    label: Text(_outerStrokeStyleNames[OuterStrokeStyle.solid]!, style: Theme.of(context).textTheme.bodySmall!.apply(color: outerStrokeStyle == OuterStrokeStyle.solid ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)),
                  ),
                  ButtonSegment<OuterStrokeStyle>(
                    value: OuterStrokeStyle.relative,
                    label: Text(_outerStrokeStyleNames[OuterStrokeStyle.relative]!, style: Theme.of(context).textTheme.bodySmall!.apply(color: outerStrokeStyle == OuterStrokeStyle.relative ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)),
                  ),
                  ButtonSegment<OuterStrokeStyle>(
                    value: OuterStrokeStyle.shade,
                    label: Text(_outerStrokeStyleNames[OuterStrokeStyle.shade]!, style: Theme.of(context).textTheme.bodySmall!.apply(color: outerStrokeStyle == OuterStrokeStyle.shade ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)),
                  ),
                ],
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
                        child: KPixDirectionWidget(
                          selectionMap: widget.settings.outerSelectionMap,
                          isExclusive: false, onChange: (
                            final Set<Alignment> directions) {
                            print(directions.length);
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
                                child: IconButton.outlined(
                                  onPressed: () {
                                    print("PRESSY MC PRESS");
                                  },
                                  icon: const FaIcon(FontAwesomeIcons.palette),
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll<Color?>(Colors.red),
                                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4.0),
                                        )
                                    ),
                                  ),
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
                                    print("PRESSY MC PRESS");
                                  },
                                  icon: const FaIcon(FontAwesomeIcons.paintbrush),
                                ),
                              ),
                            ),
                          ]
                        ),
                      ),
                    if (outerStrokeStyle == OuterStrokeStyle.relative || outerStrokeStyle == OuterStrokeStyle.shade)
                      Expanded(
                        flex: 7,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text("Darken/Brighten"),
                            KPixSlider(
                              value: 0.0,
                              textStyle: Theme.of(context).textTheme.bodySmall!,
                              onChanged: (double value) {
                                print("BLA");
                              },
                            )
                          ],
                        ),
                      )
                  ],
                );
              }
            ),
          ),




          Divider(height: 2.0, thickness: 2.0, color: Theme.of(context).primaryColor,),
          SizedBox(height: generalPadding),



          //INNER STROKE
          Text("INNER STROKE", style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
          SizedBox(height: generalPadding),
          //inner stroke style
          ValueListenableBuilder<InnerStrokeStyle>(
            valueListenable: widget.settings.innerStrokeStyle,
            builder: (final BuildContext context, final InnerStrokeStyle innerStrokeStyle, final Widget? child)
            {
              return SegmentedButton<InnerStrokeStyle>(
                segments: <ButtonSegment<InnerStrokeStyle>>[
                  ButtonSegment<InnerStrokeStyle>(
                    value: InnerStrokeStyle.off,
                    label: Text(_innerStrokeStyleNames[InnerStrokeStyle.off]!, style: Theme.of(context).textTheme.bodySmall!.apply(color: innerStrokeStyle == InnerStrokeStyle.off ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)),
                  ),
                  ButtonSegment<InnerStrokeStyle>(
                    value: InnerStrokeStyle.solid,
                    label: Text(_innerStrokeStyleNames[InnerStrokeStyle.solid]!, style: Theme.of(context).textTheme.bodySmall!.apply(color: innerStrokeStyle == InnerStrokeStyle.solid ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)),
                  ),
                  ButtonSegment<InnerStrokeStyle>(
                    value: InnerStrokeStyle.glow,
                    label: Text(_innerStrokeStyleNames[InnerStrokeStyle.glow]!, style: Theme.of(context).textTheme.bodySmall!.apply(color: innerStrokeStyle == InnerStrokeStyle.glow ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)),
                  ),
                  ButtonSegment<InnerStrokeStyle>(
                    value: InnerStrokeStyle.shade,
                    label: Text(_innerStrokeStyleNames[InnerStrokeStyle.shade]!, style: Theme.of(context).textTheme.bodySmall!.apply(color: innerStrokeStyle == InnerStrokeStyle.shade ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)),
                  ),
                ],
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
                          child: KPixDirectionWidget(
                            selectionMap: widget.settings.innerSelectionMap,
                            isExclusive: false, onChange: (
                              final Set<Alignment> directions) {
                            print(directions.length);
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
                                  child: IconButton.outlined(
                                    onPressed: () {
                                      print("PRESSY MC PRESS");
                                    },
                                    icon: const FaIcon(FontAwesomeIcons.palette),
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll<Color?>(Colors.red),
                                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4.0),
                                        )
                                      ),
                                    ),
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
                                      print("PRESSY MC PRESS");
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
                              KPixSlider(
                                value: 0.0,
                                textStyle: Theme.of(context).textTheme.bodySmall!,
                                onChanged: (double value) {
                                  print("BLA");
                                },
                              )
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
                              KPixSlider(
                                value: 0.0,
                                textStyle: Theme.of(context).textTheme.bodySmall!,
                                onChanged: (double value) {
                                  print("BLA");
                                },
                              )
                            ],
                          ),
                        ),
                    ],
                  );
                }
            ),
          ),


          Divider(height: 2.0, thickness: 2.0, color: Theme.of(context).primaryColor,),
          SizedBox(height: generalPadding),



          //DROP SHADOW
          Text("DROP SHADOW", style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,),
          SizedBox(height: generalPadding),
          //inner stroke style
          ValueListenableBuilder<DropShadowStyle>(
            valueListenable: widget.settings.dropShadowStyle,
            builder: (final BuildContext context, final DropShadowStyle dropShadowStyle, final Widget? child)
            {
              return SegmentedButton<DropShadowStyle>(
                segments: <ButtonSegment<DropShadowStyle>>[
                  ButtonSegment<DropShadowStyle>(
                    value: DropShadowStyle.off,
                    label: Text(_dropShadowStyleNames[DropShadowStyle.off]!, style: Theme.of(context).textTheme.bodySmall!.apply(color: dropShadowStyle == DropShadowStyle.off ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)),
                  ),
                  ButtonSegment<DropShadowStyle>(
                    value: DropShadowStyle.solid,
                    label: Text(_dropShadowStyleNames[DropShadowStyle.solid]!, style: Theme.of(context).textTheme.bodySmall!.apply(color: dropShadowStyle == DropShadowStyle.solid ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)),
                  ),
                  ButtonSegment<DropShadowStyle>(
                    value: DropShadowStyle.shade,
                    label: Text(_dropShadowStyleNames[DropShadowStyle.shade]!, style: Theme.of(context).textTheme.bodySmall!.apply(color: dropShadowStyle == DropShadowStyle.shade ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight)),
                  ),
                ],
                selected: <DropShadowStyle>{dropShadowStyle},
                showSelectedIcon: false,
                onSelectionChanged: (final Set<DropShadowStyle> values) {
                  widget.settings.dropShadowStyle.value = values.first;
                },
              );
            },
          ),
          SizedBox(height: generalPadding),
          SizedBox(
            height: 100,
            child: ValueListenableBuilder<DropShadowStyle>(
              valueListenable: widget.settings.dropShadowStyle,
              builder: (final BuildContext context, final DropShadowStyle dropShadowStyle, final Widget? child)
              {
                if (dropShadowStyle != DropShadowStyle.off)
                {
                  return Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: Text("Horizontal")),
                          Expanded(
                            flex: 2,
                            child: KPixSlider(
                              value: 0.0,
                              onChanged: (double value) {
                                print("AOEIGBNA");
                              },
                              textStyle: Theme.of(context).textTheme.bodyMedium!,
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: Text("Vertical")),
                          Expanded(
                            flex: 2,
                            child: KPixSlider(
                              value: 0.0,
                              onChanged: (double value) {
                                print("AOEIGBNA");
                              },
                              textStyle: Theme.of(context).textTheme.bodyMedium!,
                            ),
                          )
                        ],
                      ),
                    ],
                  );
                }
                else
                {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),

          Divider(height: 2.0, thickness: 2.0, color: Theme.of(context).primaryColor,),
          SizedBox(height: generalPadding),

        ],
      ),
    );
  }
}
