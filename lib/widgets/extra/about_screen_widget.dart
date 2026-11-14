
/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/update_state.dart';
import 'package:kpix/util/helpers/update_helper.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget that shows information about the application.
class AboutScreenWidget extends StatefulWidget
{
  final Function() onDismiss;
  const AboutScreenWidget({super.key, required this.onDismiss});
  @override
  State<AboutScreenWidget> createState() => _AboutScreenWidgetState();
}

class _AboutScreenWidgetState extends State<AboutScreenWidget>
{
  static const double _height = 210.0;
  final PackageInfo _pInfo = GetIt.I.get<PackageInfo>();

  late KPixOverlay _licenseScreen;
  late KPixOverlay _creditsScreen;
  late KPixOverlay _controlsScreen;

  void _dismissPressed()
  {
    widget.onDismiss();
  }

  @override
  void initState()
  {
    super.initState();
    _licenseScreen = getLicensesDialog(onDismiss: _dismissDialogs);
    _creditsScreen = getCreditsDialog(onDismiss: _dismissDialogs);
    _controlsScreen = getControlsDialog(onDismiss: _dismissDialogs);
  }

  void _licensesPressed()
  {
    _licenseScreen.show(context: context);
  }

  void _controlsPressed()
  {
    _controlsScreen.show(context: context);
  }

  void _creditsPressed()
  {
    _creditsScreen.show(context: context);
  }

  void _dismissDialogs()
  {
    _licenseScreen.hide();
    _creditsScreen.hide();
    _controlsScreen.hide();
  }

  /// Launches a URL in the default browser.
  Future<void> launchURL({required final String url}) async
  {
    if (!await launchUrl(Uri.parse(url)))
    {
      throw Exception("Could not launch");
    }
  }

  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TextStyle textStyle = Theme.of(context).textTheme.labelMedium!;
    final TextStyle linkStyle = textStyle.apply(decoration: TextDecoration.underline, decorationColor: Theme.of(context).primaryColorLight);
    return KPixAnimationWidget(
      constraints: const BoxConstraints(
        minHeight: _height,
        minWidth: OverlayEntryAlertDialogOptions.minWidth,
        maxHeight: _height,
        maxWidth: OverlayEntryAlertDialogOptions.maxWidth,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(
            child: Image.asset(PreferenceManager.ASSET_ICON),
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text("$windowTitle ${_pInfo.version}", style: Theme.of(context).textTheme.titleLarge),
                    const Expanded(child: SizedBox(width: OverlayEntryAlertDialogOptions.padding)),
                    ValueListenableBuilder<bool>(
                      valueListenable: GetIt.I.get<UpdateState>().hasUpdateNotifier,
                      builder: (final BuildContext context, final bool hasUpdate, final Widget? child)
                      {
                        final UpdateInfoPackage? updateInfo = GetIt.I.get<UpdateState>().updatePackage;
                        if (hasUpdate && updateInfo != null)
                        {
                          return RichText(
                            textAlign: TextAlign.right,
                            text: TextSpan(
                              text: "${l10n.newVersionAvailable} (${updateInfo.version}).\n",
                              style: Theme.of(context).textTheme.bodySmall!.apply(color: notificationGreen),
                              children: <InlineSpan>[
                                TextSpan(
                                  text: l10n.downloadFromGithub,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      if (GetIt.I.get<UpdateState>().updatePackage != null)
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

                Text(l10n.aPixelArtCreationTool, style: textStyle),
                Text("© $firstCopyrightYear–${DateTime.now().year} $copyrightHolder", style: textStyle),
                RichText(
                  text: TextSpan(
                    text: "${l10n.thisIsFreeSoftwareLicensed} ",
                    style: textStyle,
                    children: <InlineSpan>[
                      TextSpan(
                        text: l10n.gnuAGPLv3,
                        recognizer: TapGestureRecognizer()..onTap = () => launchURL(url: licenseUrl),
                        style: linkStyle,
                      ),
                      TextSpan(text: ". ${l10n.noWarranty}"),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: "${l10n.sourceCode} ",
                    style: textStyle,
                    children: <InlineSpan>[
                      TextSpan(
                        text: sourceCodeUrl.replaceFirst("https://", ""),
                        recognizer: TapGestureRecognizer()..onTap = () => launchURL(url: sourceCodeUrl),
                        style: linkStyle,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DialogActionButton(tooltip: l10n.credits, icon: TablerIcons.users, onPressed: _creditsPressed),
                    DialogActionButton(tooltip: l10n.licenses, icon: TablerIcons.license, onPressed: _licensesPressed),
                    DialogActionButton(tooltip: l10n.controlsShortcuts, icon: TablerIcons.keyboard, onPressed: _controlsPressed),
                    DialogActionButton.close(l10n: l10n, onPressed: _dismissPressed),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
