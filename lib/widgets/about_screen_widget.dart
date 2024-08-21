
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
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreenWidget extends StatefulWidget
{
  const AboutScreenWidget({super.key});
  @override
  State<AboutScreenWidget> createState() => _AboutScreenWidgetState();
}

class _AboutScreenWidgetState extends State<AboutScreenWidget>
{
  final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final PackageInfo pInfo = GetIt.I.get<PackageInfo>();

  late KPixOverlay _licenseScreen;
  late KPixOverlay _creditsScreen;

  @override
  void initState()
  {
    super.initState();
    _licenseScreen = OverlayEntries.getLicensesDialog(onDismiss: _dismissDialogs);
    _creditsScreen = OverlayEntries.getCreditsDialog(onDismiss: _dismissDialogs);
  }

  void _licensesPressed()
  {
    _licenseScreen.show(context: context);
  }

  void _creditsPressed()
  {
    _creditsScreen.show(context: context);
  }

  void _dismissDialogs()
  {
    _licenseScreen.hide();
    _creditsScreen.hide();

  }

  @override
  Widget build(BuildContext context)
  {
    return Material(
      elevation: options.elevation,
      shadowColor: Theme.of(context).primaryColorDark,
      borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
      child: Container(
        constraints: BoxConstraints(
          minHeight: options.minHeight,
          minWidth: options.minWidth,
          maxHeight: options.minHeight,
          maxWidth: options.maxWidth,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          border: Border.all(
            color: Theme.of(context).primaryColorLight,
            width: options.borderWidth,
          ),
          borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
        ),
        child: Padding(
          padding: EdgeInsets.all(options.padding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 1,
                child: Image.asset("imgs/kpix_icon.png")
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.only(left: options.padding),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("KPix ${pInfo.version}", style: Theme.of(context).textTheme.titleLarge),
                      Text("A Pixel Art Creation Tool", style: Theme.of(context).textTheme.titleSmall),
                      Text("This is free software licensed under GNU AGPLv3", style: Theme.of(context).textTheme.bodyMedium),
                      SizedBox(height: options.padding,),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(flex: 1, child: OutlinedButton(onPressed: _creditsPressed, child: const Text("Credits"))),
                          SizedBox(width: options.padding),
                          Expanded(flex: 1, child: OutlinedButton(onPressed: _licensesPressed, child: const Text("Licenses")))
                        ],
                      )
                    ],
                  ),
                )
              )
            ],
          ),
        )
      )
    );
  }

}