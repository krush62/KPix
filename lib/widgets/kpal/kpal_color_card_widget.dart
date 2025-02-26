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

part of 'kpal_widget.dart';


class KPalColorCardWidgetOptions
{
  final double borderRadius;
  final double borderWidth;
  final double outsidePadding;
  final int colorNameFlex;
  final int colorFlex;
  final int colorNumbersFlex;
  final int editAnimationDuration;
  final int touchTimeout;

  KPalColorCardWidgetOptions({
    required this.borderRadius,
    required this.borderWidth,
    required this.outsidePadding,
    required this.colorFlex,
    required this.colorNameFlex,
    required this.colorNumbersFlex,
    required this.editAnimationDuration,
    required this.touchTimeout,
  });
}


class KPalColorCardWidget extends StatefulWidget
{
  final ValueNotifier<IdColor> _colorNotifier;
  final ShiftSet shiftSet;
  final bool showName;
  final bool _isLast;

  const KPalColorCardWidget({
    super.key,
    required this.showName,
    required this.shiftSet,
    required final ValueNotifier<IdColor> colorNotifier,
    final bool isLast = false,
  }) : _isLast = isLast, _colorNotifier = colorNotifier;

  @override
  State<KPalColorCardWidget> createState() => _KPalColorCardWidgetState();
}

class _KPalColorCardWidgetState extends State<KPalColorCardWidget>
{
  final KPalColorCardWidgetOptions _options = GetIt.I.get<PreferenceManager>().kPalWidgetOptions.rampOptions.colorCardWidgetOptions;
  final KPalSliderConstraints _constraints = GetIt.I.get<PreferenceManager>().kPalSliderConstraints;
  final ColorNames _colorNames = GetIt.I.get<PreferenceManager>().colorNames;
  final ValueNotifier<bool> _shouldShowSliders = ValueNotifier<bool>(false);
  late KPalVerticalSliderWidget _hueSlider;
  late KPalVerticalSliderWidget _satSlider;
  late KPalVerticalSliderWidget _valSlider;
  Timer? pressTimer;
  bool _isInside = false;

  @override
  void initState()
  {
    super.initState();
    _hueSlider = KPalVerticalSliderWidget(name: "hue", minVal: _constraints.minHue, maxVal: _constraints.maxHue, valueNotifier: widget.shiftSet.hueShiftNotifier);
    _satSlider = KPalVerticalSliderWidget(name: "sat", minVal: _constraints.minSat, maxVal: _constraints.maxSat, valueNotifier: widget.shiftSet.satShiftNotifier);
    _valSlider = KPalVerticalSliderWidget(name: "val", minVal: _constraints.minVal, maxVal: _constraints.maxVal, valueNotifier: widget.shiftSet.valShiftNotifier);
    _hueSlider.valueNotifier.addListener(_showSliders);
    _satSlider.valueNotifier.addListener(_showSliders);
    _valSlider.valueNotifier.addListener(_showSliders);
  }

  void _showSliders()
  {
    _shouldShowSliders.value = true;
    if (pressTimer != null)
    {
      pressTimer!.cancel();
    }
    pressTimer = Timer(Duration(milliseconds: _options.touchTimeout), _hide);
  }

  void _hide()
  {
    if (!_isInside)
    {
      _shouldShowSliders.value = false;
    }
  }

  @override
  Widget build(final BuildContext context) {
   return Expanded(
     child: Padding(
       padding: EdgeInsets.only(
         left: _options.outsidePadding,
         right: widget._isLast ? _options.outsidePadding : 0.0,
         top: _options.outsidePadding,
         bottom: _options.outsidePadding,
       ),
       child: DecoratedBox(
         decoration: BoxDecoration(
           color: Theme.of(context).primaryColor,
           borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
         ),

         child: ValueListenableBuilder<IdColor>(
           valueListenable: widget._colorNotifier,
           builder: (final BuildContext context, final IdColor currentColor, final Widget? child)
           {
             return Column(
               mainAxisAlignment: MainAxisAlignment.end,
               children: <Widget>[
                 Expanded(
                   flex: _options.colorNameFlex,
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: <Widget>[
                       Text(
                         textAlign: TextAlign.center,
                         widget.showName ? _colorNames.getColorName(r: currentColor.color.red, g: currentColor.color.green, b: currentColor.color.blue) : "",
                         style: Theme.of(context).textTheme.titleSmall,
                       ),
                       Text(
                         textAlign: TextAlign.center,
                         widget.showName ? colorToHexString(c: currentColor.color, toUpper: true) : "",
                         style: Theme.of(context).textTheme.bodySmall,
                       ),
                     ],
                   ),
                 ),
                 Divider(
                   color: Theme.of(context).primaryColorDark,
                   thickness: _options.borderWidth,
                   height: _options.borderWidth,
                 ),
                 Expanded(
                   flex: _options.colorFlex,
                   child: MouseRegion(
                     onEnter: (final PointerEnterEvent? event) {
                       _isInside = true;
                       _shouldShowSliders.value = true;
                     },
                     onExit: (final PointerExitEvent? event) {
                       _isInside = false;
                       _shouldShowSliders.value = false;
                     },
                     child: GestureDetector(
                       onTap: _showSliders,
                       child: Stack(
                         children: <Widget>[
                           Container(
                             color: currentColor.color,
                           ),
                           ValueListenableBuilder<bool>(
                             valueListenable: _shouldShowSliders,
                             builder: (final BuildContext context1, final bool shouldShow, final Widget? child1) {
                               return AnimatedOpacity(
                                 duration: Duration(milliseconds: _options.editAnimationDuration),
                                 curve: Curves.easeInOut,
                                 opacity: shouldShow ? 1 : 0,
                                 child: IgnorePointer(
                                   ignoring: !shouldShow,
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                     children: <Widget>[
                                       _hueSlider,
                                       _satSlider,
                                       _valSlider,
                                     ],
                                   ),
                                 ),
                               );
                             },
                           ),
                           ValueListenableBuilder<bool>(
                             valueListenable: _shouldShowSliders,
                             builder: (final BuildContext context1, final bool shouldShow, final Widget? child1) {
                               return ValueListenableBuilder<int>(
                                 valueListenable: widget.shiftSet.hueShiftNotifier,
                                 builder: (final BuildContext context2, final int hueShift, final Widget? child2) {
                                   return ValueListenableBuilder<int>(
                                     valueListenable: widget.shiftSet.satShiftNotifier,
                                     builder: (final BuildContext context3, final int satShift, final Widget? child3) {
                                       return ValueListenableBuilder<int>(
                                         valueListenable: widget.shiftSet.valShiftNotifier,
                                         builder: (final BuildContext context4, final int valShift, final Widget? child4) {
                                           final bool editIsVisible = !shouldShow && (hueShift != _constraints.defaultHue || satShift != _constraints.defaultSat || valShift != _constraints.defaultVal);
                                           return AnimatedOpacity(
                                             duration: Duration(milliseconds: _options.editAnimationDuration),
                                             curve: Curves.easeInOut,
                                             opacity: editIsVisible ? 1 : 0,
                                             child: Padding(
                                               padding:  EdgeInsets.all(_options.outsidePadding),
                                               child: FaIcon(
                                                 FontAwesomeIcons.pen,
                                                 shadows: <Shadow>[
                                                   Shadow(
                                                     offset: const Offset(0.0, 1.0),
                                                     blurRadius: 2.0,
                                                     color: Theme.of(context).primaryColorDark,
                                                   ),
                                                 ],
                                               ),
                                             ),
                                           );
                                         },
                                       );
                                     },
                                   );
                                 },
                               );
                             },
                           ),
                         ],
                       ),
                     ),
                   ),
                 ),
                 Divider(
                   color: Theme.of(context).primaryColorDark,
                   thickness: _options.borderWidth,
                   height: _options.borderWidth,
                 ),
                 Expanded(
                   flex: _options.colorNumbersFlex,
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: <Widget>[
                       Text("${currentColor.hsvColor.hue.round()}°"),
                       Text("${(currentColor.hsvColor.saturation * 100).round()}%"),
                       Text("${(currentColor.hsvColor.value * 100).round()}%"),
                     ],
                   ),
                 ),
               ],
             );
           },
         ),
       ),
     ),
   );
  }
}
