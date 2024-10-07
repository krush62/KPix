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

  KPalColorCardWidgetOptions({
    required this.borderRadius,
    required this.borderWidth,
    required this.outsidePadding,
    required this.colorFlex,
    required this.colorNameFlex,
    required this.colorNumbersFlex,
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
    required ValueNotifier<IdColor> colorNotifier,
    bool isLast = false,
  }) : _isLast = isLast, _colorNotifier = colorNotifier;

  @override
  State<KPalColorCardWidget> createState() => _KPalColorCardWidgetState();
}

class _KPalColorCardWidgetState extends State<KPalColorCardWidget>
{
  final KPalColorCardWidgetOptions _options = GetIt.I.get<PreferenceManager>().kPalWidgetOptions.rampOptions.colorCardWidgetOptions;
  final KPalSliderConstraints _constraints = GetIt.I.get<PreferenceManager>().kPalSliderConstraints;
  final ColorNames _colorNames = GetIt.I.get<PreferenceManager>().colorNames;
  final ValueNotifier<bool> _shouldShowSliders = ValueNotifier(false);
  late KPalVerticalSliderWidget _hueSlider;
  late KPalVerticalSliderWidget _satSlider;
  late KPalVerticalSliderWidget _valSlider;

  @override
  void initState()
  {
    super.initState();
    _hueSlider = KPalVerticalSliderWidget(name: "hue", minVal: _constraints.minHue, maxVal: _constraints.maxHue, valueNotifier: widget.shiftSet.hueShiftNotifier);
    _satSlider = KPalVerticalSliderWidget(name: "sat", minVal: _constraints.minSat, maxVal: _constraints.maxSat, valueNotifier: widget.shiftSet.satShiftNotifier);
    _valSlider = KPalVerticalSliderWidget(name: "val", minVal: _constraints.minVal, maxVal: _constraints.maxVal, valueNotifier: widget.shiftSet.valShiftNotifier);
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
       child: Container(
         decoration: BoxDecoration(
           color: Theme.of(context).primaryColor,
           borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
           border: Border.all(
             width: _options.borderWidth,
             color: Theme.of(context).primaryColorLight,
           )
         ),

         child: ValueListenableBuilder<IdColor>(
           valueListenable: widget._colorNotifier,
           builder: (final BuildContext context, final IdColor currentColor, final Widget? child)
           {
             return Column(
               children: [
                 Expanded(
                   flex: _options.colorNameFlex,
                   child: Center(
                     child: Text(
                       textAlign: TextAlign.center,
                       widget.showName ? _colorNames.getColorName(r: currentColor.color.red, g: currentColor.color.green, b: currentColor.color.blue) : ""
                     ),
                   )
                 ),
                 Divider(
                   color: Theme.of(context).primaryColorLight,
                   thickness: _options.borderWidth,
                   height: _options.borderWidth,
                 ),
                 Expanded(
                   flex: _options.colorFlex,
                   child: MouseRegion(
                     onEnter: (final PointerEnterEvent? event) {
                       _shouldShowSliders.value = true;
                     },
                     onExit: (final PointerExitEvent? event) {
                       _shouldShowSliders.value = false;
                     },
                     child: Stack(
                       children: [
                         Container(
                           color: currentColor.color
                         ),
                         ValueListenableBuilder<bool>(
                           valueListenable: _shouldShowSliders,
                           builder: (final BuildContext context1, final bool shouldShow, final Widget? child1) {
                             return AnimatedOpacity(
                               duration: const Duration(milliseconds: 250), //TODO magic number
                               curve: Curves.easeInOut,
                               opacity: shouldShow ? 1 : 0,
                               child: Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                 children: [
                                   _hueSlider,
                                   _satSlider,
                                   _valSlider
                                 ],
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
                                           duration: const Duration(milliseconds: 250), //TODO magic number
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
                         )
                       ]
                     ),
                   )
                 ),
                 Divider(
                   color: Theme.of(context).primaryColorLight,
                   thickness: _options.borderWidth,
                   height: _options.borderWidth,
                 ),
                 Expanded(
                   flex: _options.colorNumbersFlex,
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     crossAxisAlignment: CrossAxisAlignment.center,
                     mainAxisSize: MainAxisSize.max,
                     children: [
                       Text("${currentColor.hsvColor.hue.round()}°"),
                       Text("${(currentColor.hsvColor.saturation * 100).round()}%"),
                       Text("${(currentColor.hsvColor.value * 100).round()}%"),
                     ]
                   )
                 )
               ],
             );
           },
         )
       ),
     )
   );
  }
}