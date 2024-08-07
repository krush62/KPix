
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreenWidget extends StatefulWidget
{
  final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final PackageInfo pInfo = GetIt.I.get<PackageInfo>();

  @override
  State<AboutScreenWidget> createState() => _AboutScreenWidgetState();

}

class _AboutScreenWidgetState extends State<AboutScreenWidget>
{
  late OverlayEntry _licenseScreen;
  bool _licenseScreenVisible = false;

  @override
  void initState()
  {
    super.initState();
    _licenseScreen = OverlayEntries.getLicensesDialog(onDismiss: _dismissDialogs);
  }

  void _licensesPressed()
  {
    if (!_licenseScreenVisible)
    {
      Overlay.of(context).insert(_licenseScreen);
      _licenseScreenVisible = true;
    }
  }

  void _creditsPressed()
  {
    //TODO
  }

  void _dismissDialogs()
  {
    if (_licenseScreenVisible)
    {
      _licenseScreen.remove();
      _licenseScreenVisible = false;
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Material(
        elevation: widget.options.elevation,
        shadowColor: Theme.of(context).primaryColorDark,
        borderRadius: BorderRadius.all(Radius.circular(widget.options.borderRadius)),
        child: Container(
            constraints: BoxConstraints(
              minHeight: widget.options.minHeight,
              minWidth: widget.options.minWidth,
              maxHeight: widget.options.minHeight,
              maxWidth: widget.options.maxWidth,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              border: Border.all(
                color: Theme.of(context).primaryColorLight,
                width: widget.options.borderWidth,
              ),
              borderRadius: BorderRadius.all(Radius.circular(widget.options.borderRadius)),
            ),
            child: Padding(
              padding: EdgeInsets.all(widget.options.padding),
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
                        padding: EdgeInsets.only(left: widget.options.padding),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("KPix ${widget.pInfo.version}", style: Theme.of(context).textTheme.titleLarge),
                            Text("A Pixel Art Creation Tool", style: Theme.of(context).textTheme.titleSmall),
                            Text("This is free software licensed under GNU AGPLv3", style: Theme.of(context).textTheme.bodyMedium),
                            SizedBox(height: widget.options.padding,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(flex: 1, child: OutlinedButton(onPressed: _creditsPressed, child: const Text("Credits"))),
                                SizedBox(width: widget.options.padding),
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