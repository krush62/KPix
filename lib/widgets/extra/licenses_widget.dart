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

import 'package:flutter/foundation.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/oss_licenses.dart';
import 'package:kpix/third_party_licenses.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:material_ui/material_ui.dart';

/// A widget for displaying all the licenses.
class LicensesWidget extends StatelessWidget
{
  final Function() onDismiss;
  static const List<Package> _licenses = <Package>[thisPackage, ...thirdPartyAssets, ...allDependencies];
  static final Future<List<Package>> _engineLicenses = _loadEngineLicenses();
  const LicensesWidget({super.key, required this.onDismiss});

  /// The engine's notices (Skia, ICU, ...) are only in Flutter's bundled NOTICES, not in pub's package list.
  static Future<List<Package>> _loadEngineLicenses() async
  {
    final Set<String> known = <String>{thisPackage.name, ...allDependencies.map((final Package p) => p.name)};
    final Map<String, List<String>> texts = <String, List<String>>{};
    try
    {
      await for (final LicenseEntry entry in LicenseRegistry.licenses)
      {
        final String text = entry.paragraphs.map((final LicenseParagraph p) => "${"  " * p.indent.clamp(0, 8)}${p.text}").join("\n\n");
        for (final String name in entry.packages.where((final String n) => !known.contains(n)))
        {
          texts.putIfAbsent(name, () => <String>[]).add(text);
        }
      }
    }
    catch (_)
    {
      return <Package>[];
    }
    final List<String> names = texts.keys.toList()..sort();
    return names.map((final String name) => Package(
      name: name,
      description: "From the Flutter license notices",
      authors: const <String>[],
      isMarkdown: false,
      isSdk: true,
      dependencies: const <PackageRef>[],
      devDependencies: const <PackageRef>[],
      license: texts[name]!.join("\n\n----------\n\n"),
    ),).toList();
  }

  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return KPixAnimationWidget(
      constraints: const BoxConstraints(
        minHeight: OverlayEntryAlertDialogOptions.minHeight,
        minWidth: OverlayEntryAlertDialogOptions.minWidth,
        maxHeight: OverlayEntryAlertDialogOptions.maxHeight * 2,
        maxWidth: OverlayEntryAlertDialogOptions.maxWidth * 2,
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<List<Package>>(
              future: _engineLicenses,
              builder: (final BuildContext context, final AsyncSnapshot<List<Package>> snapshot)
              {
                final List<Package> licenses = <Package>[..._licenses, ...?snapshot.data];
                return ListView.separated(
                  itemCount: licenses.length,
                  padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),

                  itemBuilder: (final BuildContext context, final int index) {
                    return ListTile(

                      isThreeLine: true,
                      title: Text(licenses[index].description, style: Theme.of(context).textTheme.titleMedium),
                      leading: Text(licenses[index].name, style: Theme.of(context).textTheme.headlineMedium),
                      subtitle: Text(licenses[index].license ?? "", style: Theme.of(context).textTheme.bodySmall),
                      trailing: Text(licenses[index].version ?? "", style: Theme.of(context).textTheme.headlineMedium),
                    );
                  },
                  separatorBuilder: (final BuildContext context, final int index) => const Divider(),
                );
              },
            ),
          ),
          Row(
            children: <Widget>[
              DialogActionButton.close(
                l10n: l10n,
                onPressed: onDismiss,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
