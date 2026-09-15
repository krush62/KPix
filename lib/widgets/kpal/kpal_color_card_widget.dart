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


abstract final class _KPalColorCardWidgetOptions
{
  static const double borderRadius = 8.0;
  static const double borderWidth = 2.0;
  static const double outsidePadding = 8.0;
  static const int colorNameFlex = 3;
  static const int colorFlex = 9;
  static const int colorNumbersFlex = 3;
  static const int editAnimationDuration = 250;
  static const int touchTimeout = 1500;
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
  final ColorNames _colorNames = GetIt.I.get<PreferenceManager>().colorNames;
  final ValueNotifier<bool> _shouldShowSliders = ValueNotifier<bool>(false);
  KPalVerticalSliderWidget? _hueSlider;
  KPalVerticalSliderWidget? _satSlider;
  KPalVerticalSliderWidget? _valSlider;
  Timer? pressTimer;
  bool _isInside = false;

  @override
  void initState()
  {
    super.initState();
  }

  void _showSliders()
  {
    _shouldShowSliders.value = true;
    if (pressTimer != null)
    {
      pressTimer!.cancel();
    }
    pressTimer = Timer(const Duration(milliseconds: _KPalColorCardWidgetOptions.touchTimeout), _hide);
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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (_hueSlider == null)
    {
      _hueSlider = KPalVerticalSliderWidget(name: l10n.hueAbb, minVal: KPalSliderConstraints.minHue, maxVal: KPalSliderConstraints.maxHue, valueNotifier: widget.shiftSet.hueShiftNotifier);
      _hueSlider!.valueNotifier.addListener(_showSliders);

    }
    if (_satSlider == null)
    {
      _satSlider = KPalVerticalSliderWidget(name: l10n.satAbb, minVal: KPalSliderConstraints.minSat, maxVal: KPalSliderConstraints.maxSat, valueNotifier: widget.shiftSet.satShiftNotifier);
      _satSlider!.valueNotifier.addListener(_showSliders);
    }
    if (_valSlider == null)
    {
      _valSlider = KPalVerticalSliderWidget(name: l10n.valAbb, minVal: KPalSliderConstraints.minVal, maxVal: KPalSliderConstraints.maxVal, valueNotifier: widget.shiftSet.valShiftNotifier);
      _valSlider!.valueNotifier.addListener(_showSliders);
    }



   return Expanded(
     child: Padding(
       padding: EdgeInsets.only(
         left: _KPalColorCardWidgetOptions.outsidePadding,
         right: widget._isLast ? _KPalColorCardWidgetOptions.outsidePadding : 0.0,
         top: _KPalColorCardWidgetOptions.outsidePadding,
         bottom: _KPalColorCardWidgetOptions.outsidePadding,
       ),
       child: DecoratedBox(
         decoration: BoxDecoration(
           color: Theme.of(context).primaryColor,
           borderRadius: const BorderRadius.all(Radius.circular(_KPalColorCardWidgetOptions.borderRadius)),
         ),

         child: ValueListenableBuilder<IdColor>(
           valueListenable: widget._colorNotifier,
           builder: (final BuildContext context, final IdColor currentColor, final Widget? child)
           {
             return Column(
               mainAxisAlignment: MainAxisAlignment.end,
               children: <Widget>[
                 Expanded(
                   flex: _KPalColorCardWidgetOptions.colorNameFlex,
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: <Widget>[
                       Text(
                         textAlign: TextAlign.center,
                         widget.showName ? _colorNames.getColorName(r: currentColor.color.r, g: currentColor.color.g, b: currentColor.color.b) : "",
                         style: Theme.of(context).textTheme.titleSmall,
                       ),
                       Text(
                         textAlign: TextAlign.center,
                         widget.showName ? colorToHexString(color: currentColor.color, toUpper: true) : "",
                         style: Theme.of(context).textTheme.bodySmall,
                       ),
                     ],
                   ),
                 ),
                 Divider(
                   color: Theme.of(context).primaryColorDark,
                   thickness: _KPalColorCardWidgetOptions.borderWidth,
                   height: _KPalColorCardWidgetOptions.borderWidth,
                 ),
                 Expanded(
                   flex: _KPalColorCardWidgetOptions.colorFlex,
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
                                 duration: const Duration(milliseconds: _KPalColorCardWidgetOptions.editAnimationDuration),
                                 curve: Curves.easeInOut,
                                 opacity: shouldShow ? 1 : 0,
                                 child: IgnorePointer(
                                   ignoring: !shouldShow,
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                     children: <Widget>[
                                       _hueSlider!,
                                       _satSlider!,
                                       _valSlider!,
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
                                           final bool editIsVisible = !shouldShow && (hueShift != KPalSliderConstraints.defaultHue || satShift != KPalSliderConstraints.defaultSat || valShift != KPalSliderConstraints.defaultVal);
                                           return AnimatedOpacity(
                                             duration: const Duration(milliseconds: _KPalColorCardWidgetOptions.editAnimationDuration),
                                             curve: Curves.easeInOut,
                                             opacity: editIsVisible ? 1 : 0,
                                             child: Padding(
                                               padding:  const EdgeInsets.all(_KPalColorCardWidgetOptions.outsidePadding),
                                               child: Icon(
                                                 TablerIcons.pencil,
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
                   thickness: _KPalColorCardWidgetOptions.borderWidth,
                   height: _KPalColorCardWidgetOptions.borderWidth,
                 ),
                 Expanded(
                   flex: _KPalColorCardWidgetOptions.colorNumbersFlex,
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: <Widget>[
                       Text("${currentColor.hsv.h.round()}°"),
                       Text("${(currentColor.hsv.s * 100).round()}%"),
                       Text("${(currentColor.hsv.v * 100).round()}%"),
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
