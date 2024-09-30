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
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/oss_licenses.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class LicensesWidget extends StatelessWidget
{
  final Function() onDismiss;
  final List<Package> _licenses = allDependencies;
  const LicensesWidget({super.key, required this.onDismiss});


  @override
  Widget build(final BuildContext context)
  {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return Material(
      elevation: options.elevation,
      shadowColor: Theme.of(context).primaryColorDark,
      borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
      child: Container(
        constraints: BoxConstraints(
        minHeight: options.minHeight,
        minWidth: options.minWidth,
        maxHeight: options.maxHeight * 2,
        maxWidth: options.maxWidth * 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        border: Border.all(
          color: Theme.of(context).primaryColorLight,
          width: options.borderWidth,
        ),
        borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _licenses.length,
              padding: EdgeInsets.all(options.padding),

              itemBuilder: (final BuildContext context, final int index) {
                return ListTile(

                  isThreeLine: true,
                  title: Text(_licenses[index].description, style: Theme.of(context).textTheme.titleMedium),
                  leading: Text(_licenses[index].name, style: Theme.of(context).textTheme.headlineMedium),
                  subtitle: Text(_licenses[index].license!, style: Theme.of(context).textTheme.bodySmall),
                  trailing: Text(_licenses[index].version, style: Theme.of(context).textTheme.headlineMedium),
                );
              },
              separatorBuilder: (BuildContext context, int index) => const Divider(),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: Tooltip(
                    message: "Close",
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      icon: FaIcon(
                        FontAwesomeIcons.xmark,
                        size: options.iconSize,
                      ),
                      onPressed: onDismiss,
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    )
  );
  }
}