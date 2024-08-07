
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
    _licenseScreen.show(context);
  }

  void _creditsPressed()
  {
    _creditsScreen.show(context);
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