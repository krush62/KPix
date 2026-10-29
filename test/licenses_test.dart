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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/oss_licenses.dart';
import 'package:yaml/yaml.dart';

import '../tool/generate_licenses.dart' show ThirdPartyLicenses, collectThirdPartyLicenses, thirdPartyOutputPath;

const String _regenerate = "run: dart run tool/generate_licenses.dart";

void main()
{
  test("every shipped font, shader and checked asset has a license", ()
  {
    expect(collectThirdPartyLicenses().errors, isEmpty);
  });

  test("$thirdPartyOutputPath is up to date", ()
  {
    final ThirdPartyLicenses licenses = collectThirdPartyLicenses();
    expect(File(thirdPartyOutputPath).readAsStringSync().replaceAll("\r\n", "\n"), licenses.source, reason: _regenerate);
  });

  test("oss_licenses.dart matches pubspec.lock", ()
  {
    final YamlMap pubspec = loadYaml(File("pubspec.yaml").readAsStringSync()) as YamlMap;
    final YamlMap lockPackages = (loadYaml(File("pubspec.lock").readAsStringSync()) as YamlMap)["packages"] as YamlMap;
    expect(thisPackage.version, pubspec["version"].toString().split("+").first, reason: _regenerate);
    for (final Package package in allDependencies)
    {
      final YamlMap? locked = lockPackages[package.name] as YamlMap?;
      expect(locked, isNotNull, reason: "${package.name} is no longer a dependency, $_regenerate");
      if (locked!["source"] == "hosted")
      {
        expect(package.version, locked["version"], reason: "${package.name} changed, $_regenerate");
      }
    }
    final Set<String> listed = allDependencies.map((final Package package) => package.name).toSet();
    for (final Object? name in (pubspec["dependencies"] as YamlMap).keys)
    {
      expect(listed, contains(name), reason: "$name is missing, $_regenerate");
    }
  });
}
