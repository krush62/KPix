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

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

const String manifestPath = "third_party_licenses.yaml";
const String thirdPartyOutputPath = "lib/third_party_licenses.dart";
const String pubOutputPath = "lib/oss_licenses.dart";
const String _licensesDirectory = "LICENSES";
const String _projectLicense = "AGPL-3.0-or-later";
const String _noAssertion = "NOASSERTION";
//the Flutter engine's bundled licenses are megabytes of text
const Set<String> _ignoredPackages = <String>{"sky_engine"};

final RegExp _spdxPattern = RegExp(r"^\s*(?://|\*)?\s*SPDX-(FileCopyrightText|License-Identifier):\s*(.+?)\s*$", multiLine: true);

class ThirdPartyLicenses
{
  final List<String> errors;
  final String source;
  const ThirdPartyLicenses({required this.errors, required this.source});
}

class _Spdx
{
  final List<String> copyright;
  final String? license;
  const _Spdx({required this.copyright, required this.license});
}

class _Entry
{
  final String name;
  final String description;
  final String? url;
  final List<String> copyright;
  final String? license;
  final String? notice;
  final List<String> patterns;
  final List<String> files = <String>[];
  _Entry({required this.name, required this.description, required this.url, required this.copyright, required this.license, required this.notice, required this.patterns});
}

/// Regenerates [pubOutputPath] (runtime dependencies only) and [thirdPartyOutputPath].
///
///     dart run tool/generate_licenses.dart
Future<void> main() async
{
  final ThirdPartyLicenses licenses = collectThirdPartyLicenses();
  if (licenses.errors.isNotEmpty)
  {
    for (final String error in licenses.errors)
    {
      stderr.writeln(error);
    }
    exitCode = 1;
    return;
  }
  if (!await _generatePubLicenses())
  {
    exitCode = 1;
    return;
  }
  File(thirdPartyOutputPath).writeAsStringSync(licenses.source);
  stdout.writeln("Wrote $pubOutputPath and $thirdPartyOutputPath.");
}

Future<bool> _generatePubLicenses() async
{
  final String dart = Platform.resolvedExecutable;
  final ProcessResult deps = await Process.run(dart, <String>["pub", "deps", "--json"]);
  if (deps.exitCode != 0)
  {
    stderr.write(deps.stderr);
    return false;
  }
  final Map<String, dynamic> graph = jsonDecode(deps.stdout as String) as Map<String, dynamic>;
  final Map<String, List<String>> dependencies = <String, List<String>>{};
  List<String> rootDependencies = <String>[];
  for (final Object? package in graph["packages"] as List<dynamic>)
  {
    final Map<String, dynamic> map = package! as Map<String, dynamic>;
    dependencies[map["name"] as String] = (map["dependencies"] as List<dynamic>).cast<String>();
    if (map["kind"] == "root")
    {
      rootDependencies = (map["directDependencies"] as List<dynamic>).cast<String>();
    }
  }

  //only what ships: the closure of the non-dev dependencies
  final Set<String> runtime = <String>{};
  final List<String> pending = List<String>.of(rootDependencies);
  while (pending.isNotEmpty)
  {
    final String name = pending.removeLast();
    if (runtime.add(name))
    {
      pending.addAll(dependencies[name] ?? <String>[]);
    }
  }
  final List<String> ignored = dependencies.keys.where((final String name) => name != graph["root"] && (!runtime.contains(name) || _ignoredPackages.contains(name))).toList()..sort();

  final ProcessResult result = await Process.run(dart, <String>["run", "dart_pubspec_licenses:generate", "-o", pubOutputPath, "-i", ignored.join(",")]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  return result.exitCode == 0;
}

/// Checks that every shipped font, shader and checked asset is covered by [manifestPath] or its SPDX header
/// and renders [thirdPartyOutputPath].
ThirdPartyLicenses collectThirdPartyLicenses({final String root = "."})
{
  final List<String> errors = <String>[];
  final YamlMap pubspec = loadYaml(File("$root/pubspec.yaml").readAsStringSync()) as YamlMap;
  final YamlMap manifest = loadYaml(File("$root/$manifestPath").readAsStringSync()) as YamlMap;
  final YamlMap flutter = pubspec["flutter"] as YamlMap;

  final List<String> checked = _strings(manifest["checked"]);
  final Set<String> shaders = _strings(flutter["shaders"]).toSet();
  final Set<String> shipped = <String>{...shaders};
  for (final Object? family in (flutter["fonts"] as YamlList?) ?? YamlList())
  {
    for (final Object? font in (family! as YamlMap)["fonts"] as YamlList)
    {
      shipped.add((font! as YamlMap)["asset"] as String);
    }
  }
  for (final String asset in _strings(flutter["assets"]))
  {
    if (!checked.any(asset.startsWith))
    {
      continue;
    }
    if (asset.endsWith("/"))
    {
      for (final FileSystemEntity entity in Directory("$root/$asset").listSync())
      {
        if (entity is File)
        {
          shipped.add("$asset${entity.uri.pathSegments.last}");
        }
      }
    }
    else
    {
      shipped.add(asset);
    }
  }

  final List<String> ownPatterns = _strings(manifest["own"]);
  final List<_Entry> entries = <_Entry>[];
  for (final Object? node in (manifest["third_party"] as YamlList?) ?? YamlList())
  {
    final YamlMap map = node! as YamlMap;
    final String? name = map["name"] as String?;
    final String? description = map["description"] as String?;
    if (name == null || description == null)
    {
      errors.add("$manifestPath: every third_party entry needs a name and a description ($map).");
      continue;
    }
    entries.add(_Entry(
      name: name,
      description: description,
      url: map["url"] as String?,
      copyright: _strings(map["copyright"]),
      license: map["license"] as String?,
      notice: map["notice"] as String?,
      patterns: _strings(map["files"]),),);
  }

  final Map<String, _Spdx> headers = <String, _Spdx>{
    for (final String shader in shaders) shader: _readSpdx(File("$root/$shader").readAsStringSync()),
  };
  final Set<String> usedPatterns = <String>{};
  for (final String file in shipped.toList()..sort())
  {
    final List<String> owners = <String>[];
    for (final String pattern in ownPatterns)
    {
      if (_glob(pattern).hasMatch(file))
      {
        owners.add("own");
        usedPatterns.add(pattern);
      }
    }
    for (final _Entry entry in entries)
    {
      for (final String pattern in entry.patterns)
      {
        if (_glob(pattern).hasMatch(file))
        {
          owners.add(entry.name);
          entry.files.add(file);
          usedPatterns.add(pattern);
          break;
        }
      }
    }

    final _Spdx? header = headers[file];
    if (owners.length > 1)
    {
      errors.add("$file: covered more than once (${owners.join(", ")}).");
    }
    else if (owners.isEmpty && header == null)
    {
      errors.add("$file: not covered, add it to $manifestPath.");
    }
    else if (owners.isEmpty && (header!.license == null || header.copyright.isEmpty))
    {
      errors.add("$file: needs SPDX-FileCopyrightText and SPDX-License-Identifier lines in its header.");
    }
    else if (owners.isEmpty && header!.license != _projectLicense)
    {
      errors.add("$file: ${header.license} is third-party, add a third_party entry to $manifestPath.");
    }
  }
  for (final String pattern in <String>[...ownPatterns, for (final _Entry entry in entries) ...entry.patterns])
  {
    if (!usedPatterns.contains(pattern))
    {
      errors.add("$manifestPath: '$pattern' matches no shipped file.");
    }
  }

  final StringBuffer buffer = StringBuffer()
    ..writeln("// Generated by tool/generate_licenses.dart from $manifestPath, the shader headers and $_licensesDirectory/. Do not edit.")
    ..writeln()
    ..writeln("import 'package:kpix/oss_licenses.dart';")
    ..writeln()
    ..writeln("/// Shipped fonts, shaders and data that are not pub packages.")
    ..writeln("const List<Package> thirdPartyAssets = <Package>[");
  for (final _Entry entry in entries)
  {
    final List<_Spdx> fileHeaders = entry.files.map((final String file) => headers[file]).whereType<_Spdx>().toList();
    final List<String> copyright = <String>{...entry.copyright, for (final _Spdx header in fileHeaders) ...header.copyright}.toList();
    final Set<String?> fileLicenses = fileHeaders.map((final _Spdx header) => header.license).toSet();
    final String? license = entry.license ?? (fileLicenses.length == 1 ? fileLicenses.single : null);
    if (fileHeaders.isNotEmpty && (entry.license != null || entry.copyright.isNotEmpty))
    {
      errors.add("$manifestPath: ${entry.name} takes copyright and license from the SPDX headers of its files, remove them from the entry.");
    }
    if (license == null)
    {
      errors.add("${entry.name}: needs one license, in $manifestPath or in the SPDX headers of all its files.");
      continue;
    }
    final List<String> ids = license.replaceAll("(", " ").replaceAll(")", " ").split(" ").where((final String token) => token.isNotEmpty && !const <String>{"AND", "OR", "WITH"}.contains(token)).toList();
    final List<String> texts = <String>[];
    if (license == _noAssertion)
    {
      if (entry.notice == null)
      {
        errors.add("$manifestPath: ${entry.name} has no license and needs a notice.");
      }
    }
    else
    {
      for (final String id in ids)
      {
        final File text = File("$root/$_licensesDirectory/$id.txt");
        if (text.existsSync())
        {
          texts.add(text.readAsStringSync().replaceAll("\r\n", "\n").trim());
        }
        else
        {
          errors.add("${entry.name}: $_licensesDirectory/$id.txt is missing.");
        }
      }
      if (copyright.isEmpty)
      {
        errors.add("${entry.name}: needs a copyright holder.");
      }
    }
    final String licenseText = <String>[
      if (copyright.isNotEmpty) copyright.map((final String holder) => "Copyright (c) $holder").join("\n"),
      if (entry.notice != null) entry.notice!.trim(),
      ...texts,
    ].join("\n\n");

    buffer
      ..writeln("  Package(")
      ..writeln("    name: ${_literal(entry.name)},")
      ..writeln("    description: ${_literal(entry.description)},")
      ..writeln("    authors: <String>[${copyright.map(_literal).join(", ")}],")
      ..writeln("    isMarkdown: false,")
      ..writeln("    isSdk: false,")
      ..writeln("    dependencies: <PackageRef>[],")
      ..writeln("    devDependencies: <PackageRef>[],");
    if (entry.url != null)
    {
      buffer.writeln("    homepage: ${_literal(entry.url!)},");
    }
    buffer.writeln("    license: ${_literal(licenseText)},");
    if (license != _noAssertion)
    {
      buffer.writeln("    spdxIdentifiers: <String>[${ids.map(_literal).join(", ")}],");
    }
    buffer.writeln("  ),");
  }
  buffer.writeln("];");
  return ThirdPartyLicenses(errors: errors, source: buffer.toString());
}

_Spdx _readSpdx(final String source)
{
  final List<String> copyright = <String>[];
  String? license;
  for (final RegExpMatch match in _spdxPattern.allMatches(source))
  {
    if (match.group(1) == "FileCopyrightText")
    {
      copyright.add(match.group(2)!);
    }
    else
    {
      license = match.group(2);
    }
  }
  return _Spdx(copyright: copyright, license: license);
}

List<String> _strings(final Object? node)
{
  return node == null ? <String>[] : (node as YamlList).map((final Object? value) => value.toString()).toList();
}

RegExp _glob(final String pattern)
{
  return RegExp("^${pattern.split("*").map(RegExp.escape).join("[^/]*")}\$");
}

String _literal(final String value)
{
  final String escaped = value.replaceAll(r"\", r"\\").replaceAll(r"$", r"\$");
  if (value.contains("\n"))
  {
    //inside """ only a run of three quotes or a closing quote needs an escape
    final String quoted = escaped.replaceAll('"""', r'""\"');
    return '"""\n${quoted.endsWith('"') ? '${quoted.substring(0, quoted.length - 1)}\\"' : quoted}"""';
  }
  return value.contains('"') && !value.contains("'") ? "'$escaped'" : '"${escaped.replaceAll('"', r'\"')}"';
}
