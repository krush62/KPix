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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/kpal/kpal_widget.dart';

class KPixColorPickerWidget extends StatelessWidget
{
  final double padding;
  final List<KPalRampData> ramps;
  final Function() dismiss;
  final ColorReferenceSelectedFn colorSelected;
  final String title;


  const KPixColorPickerWidget({super.key, required this.ramps, required this.dismiss, required this.colorSelected, this.padding = 4.0, this.title = "SELECT A COLOR"});

  List<Widget> _createRampRows({required final BuildContext context})
  {
    final List<Widget> rows = <Widget>[];
    for (final KPalRampData ramp in ramps)
    {
      final List<Widget> colors = <Widget>[];
      for (final ColorReference color in ramp.references)
      {
        colors.add(
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: FilledButton(
                onPressed: () {
                  colorSelected(color: color);
                },
                style: Theme.of(context).filledButtonTheme.style!.copyWith(
                  backgroundColor: WidgetStateProperty.all(color.getIdColor().color),
                ),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        );
      }

       rows.add(
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: colors,
         ),
       );
    }
    return rows;
  }

  @override
  Widget build(final BuildContext context)
  {
    final List<Widget> rampWidgets = _createRampRows(context: context);
    return Padding(
      padding: EdgeInsets.all(padding * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rampWidgets,
              ),
            ),
          ),
          SizedBox(
            height: padding,
          ),
          IconButton.outlined(
            icon: const Icon(TablerIcons.x,),
            onPressed: () {
              dismiss();
            },
          ),
        ],
      ),
    );
  }
}
