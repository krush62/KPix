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
  final bool showName;
  final bool _isLast;

  const KPalColorCardWidget({
    super.key,
    required this.showName,
    required ValueNotifier<IdColor> colorNotifier,
    bool isLast = false,
  }) : _isLast = isLast, _colorNotifier = colorNotifier;

  @override
  State<KPalColorCardWidget> createState() => _KPalColorCardWidgetState();
}

class _KPalColorCardWidgetState extends State<KPalColorCardWidget>
{
  final KPalColorCardWidgetOptions _options = GetIt.I.get<PreferenceManager>().kPalWidgetOptions.rampOptions.colorCardWidgetOptions;
  final ColorNames _colorNames = GetIt.I.get<PreferenceManager>().colorNames;


  @override
  Widget build(final BuildContext context) {
   return Expanded(
     child: Padding(
       //padding: EdgeInsets.all(widget.options.outsidePadding),
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
             final HSVColor hsvColor =  HSVColor.fromColor(currentColor.color);
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
                   child: Container(color: currentColor.color)
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
                       Text("${hsvColor.hue.round()}°"),
                       Text("${(hsvColor.saturation * 100).round()}%"),
                       Text("${(hsvColor.value * 100).round()}%"),
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