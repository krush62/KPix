
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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/update_helper.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreenWidget extends StatefulWidget
{
  final Function() onDismiss;
  const AboutScreenWidget({super.key, required this.onDismiss});
  @override
  State<AboutScreenWidget> createState() => _AboutScreenWidgetState();
}

class _AboutScreenWidgetState extends State<AboutScreenWidget>
{
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final PackageInfo _pInfo = GetIt.I.get<PackageInfo>();

  late KPixOverlay _licenseScreen;
  late KPixOverlay _creditsScreen;

  @override
  void initState()
  {
    super.initState();
    _licenseScreen = getLicensesDialog(onDismiss: _dismissDialogs);
    _creditsScreen = getCreditsDialog(onDismiss: _dismissDialogs);
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
  Widget build(final BuildContext context)
  {
    return Material(
      elevation: _options.elevation,
      shadowColor: Theme.of(context).primaryColorDark,
      borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
      child: Container(
        constraints: BoxConstraints(
          minHeight: _options.minHeight,
          minWidth: _options.minWidth,
          maxHeight: _options.minHeight,
          maxWidth: _options.maxWidth,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          border: Border.all(
            color: Theme.of(context).primaryColorLight,
            width: _options.borderWidth,
          ),
          borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
        ),
        child: Padding(
          padding: EdgeInsets.all(_options.padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: Image.asset("imgs/kpix_icon.png"),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.only(left: _options.padding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text("KPix ${_pInfo.version}", style: Theme.of(context).textTheme.headlineLarge),
                          Expanded(child: SizedBox(width: _options.padding)),
                          ValueListenableBuilder<bool>(
                            valueListenable: GetIt.I.get<AppState>().hasUpdateNotifier,
                            builder: (final BuildContext context, final bool hasUpdate, final Widget? child)
                            {
                              final UpdateInfoPackage? updateInfo = GetIt.I.get<AppState>().updatePackage;
                              if (hasUpdate && updateInfo != null)
                              {
                                return RichText(
                                  textAlign: TextAlign.right,
                                  text: TextSpan(
                                    text: "New version available (${updateInfo.version}).\n",
                                    style: Theme.of(context).textTheme.bodySmall!.apply(color: notificationGreen),
                                    children: <InlineSpan>[
                                      TextSpan(
                                          text: "Download from GitHub.",
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              if (GetIt.I.get<AppState>().updatePackage != null)
                                              {
                                                launchURL(url: updateInfo.url);
                                              }
                                            },
                                          style: Theme.of(context).textTheme.bodySmall!.apply(color: notificationGreen, decoration: TextDecoration.underline, decorationColor: notificationGreen),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              else
                              {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ],
                      ),

                      Text("A Pixel Art Creation Tool", style: Theme.of(context).textTheme.labelMedium),
                      Text("This is free software licensed under GNU AGPLv3", style: Theme.of(context).textTheme.labelMedium),
                      SizedBox(height: _options.padding,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Expanded(
                            child: Tooltip(
                              message: "Credits",
                              waitDuration: AppState.toolTipDuration,
                              child: IconButton.outlined(
                                icon: FaIcon(
                                  FontAwesomeIcons.peopleGroup,
                                  size: _options.iconSize,
                                ),
                                onPressed: _creditsPressed,
                              ),
                            ),
                          ),
                          SizedBox(width: _options.padding),
                          Expanded(
                            child: Tooltip(
                              message: "Licenses",
                              waitDuration: AppState.toolTipDuration,
                              child: IconButton.outlined(
                                icon: FaIcon(
                                  FontAwesomeIcons.section,
                                  size: _options.iconSize,
                                ),
                                onPressed: _licensesPressed,
                              ),
                            ),
                          ),
                          SizedBox(width: _options.padding),
                          Expanded(
                            child: Tooltip(
                              message: "Close",
                              waitDuration: AppState.toolTipDuration,
                              child: IconButton.outlined(
                                icon: FaIcon(
                                  FontAwesomeIcons.xmark,
                                  size: _options.iconSize,
                                ),
                                onPressed: widget.onDismiss,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
