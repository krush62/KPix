/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */


import 'package:device_info_plus/device_info_plus.dart';

const String _osWindows = 'Windows';
const String _osLinux = 'Linux';
const String _osMacOs = 'macOS';
const String _osIos = 'iOS';
const String _osAndroid = 'Android';
const String _osWeb = 'Web';
const String _osUnknown = 'Unknown';

class _InfoMap
{
  final Map<String, String> _content = <String, String>{};
  void put(final String key, final Object? value)
  {
    if (value == null) return;
    String s;
    if (value is Iterable)
    {
      s = value.map((final Object? e) => e?.toString() ?? '').where((final String e) => e.isNotEmpty).join(', ');
    }
    else
    {
      s = value.toString();
    }
    if (s.trim().isEmpty) return;
    _content[key] = s;
  }

  bool containsKey(final String key) => _content.containsKey(key);
  
  Map<String, String> get map => _content;
}

Future<Map<String, String>> readableDeviceInfo() async
{
  final DeviceInfoPlugin plugin = DeviceInfoPlugin();
  final BaseDeviceInfo info = await plugin.deviceInfo;
  final Map<String, dynamic> data = info.data;
  final _InfoMap out = _InfoMap();
  final String osName = _osName(info: info);



  out.put('OS', osName);

  switch (osName)
  {
    case _osAndroid:
      out.put('OS Version', _firstOfPaths(candidates:
        <List<String>>[
          <String>['version', 'release'],
        ],
        data: data,),
      );
      out.put('SDK', _firstOfPaths(candidates:
        <List<String>>[
          <String>['version', 'sdkInt'],
        ],
        data: data),
      );
      out.put('Manufacturer', data['manufacturer']);
      out.put('Brand', data['brand']);
      out.put('Model', data['model']);
      out.put('Device', data['device']);
      out.put('Product', data['product']);
      out.put('Hardware', data['hardware']);
      out.put('Supported ABIs', _firstOfPaths(candidates:
        <List<String>>[
          <String>['supportedAbis'],
          <String>['supported64BitAbis'],
          <String>['supported32BitAbis'],
        ],
        data: data,),
      );
      out.put('Is Physical Device', data['isPhysicalDevice']);

    case _osIos:
      out.put('OS Version', data['systemVersion']);
      out.put('Device Name', data['name']);
      out.put('Model', data['model']);
      out.put('Localized Model', data['localizedModel']);
      out.put('Is Physical Device', data['isPhysicalDevice']);
      final Object? machine = _firstOfPaths(candidates:
        <List<String>>[
          <String>['utsname','machine'],
        ],
        data: data,);
      out.put('Hardware', machine);

    case _osMacOs:
      out.put('OS Version', data['osVersion']);
      out.put('Kernel', data['kernelVersion']);
      out.put('Arch', data['arch']);
      out.put('Model', data['model']);
      out.put('Comout.puter Name', data['comout.puterName']);
      out.put('Host Name', data['hostName']);

    case _osWindows:
      out.put('OS Version', data['displayVersion']);
      if (!out.containsKey('OS Version'))
      {
        final dynamic major = data['majorVersion'];
        final dynamic minor = data['minorVersion'];
        final dynamic build = data['buildNumber'];
        final String composed = <dynamic>[
          if (major != null) major,
          if (minor != null) minor,
          if (build != null) build,
        ].join('.');
        if (composed.isNotEmpty) out.put('OS Version', composed);
      }
      out.put('Product Name', data['productName']);
      out.put('Build', data['buildLab']);
      //out.put('Comout.puter Name', data['comout.puterName']);
      out.put('Arch', data['arch']);
      out.put('CPU Cores', data['numberOfCores']);
      final dynamic memMb = data['systemMemoryInMegabytes'];
      if (memMb is int)
      {
        final String gb = (memMb / 1024).toStringAsFixed(1);
        out.put('System Memory (GB)', gb);
      }
      out.put('Is Virtual Machine', data['isVirtualMachine']);

    case _osLinux:
      out.put('Distro', _firstOfPaths(candidates:
        <List<String>>[
          <String>['prettyName'],
          <String>['name'],
        ],
        data: data,),
      );
      out.put('OS Version', _firstOfPaths(candidates:
        <List<String>>[
          <String>['version'],
          <String>['versionCodename'],
        ],
        data: data,),
      );
      out.put('Kernel', data['kernelVersion']);
      out.put('Arch', data['architecture']);
      //out.put('Machine ID', data['machineId']);

    case _osWeb:
      final String? browserName = data['browserName']?.toString().replaceAll('BrowserName.', '').toUpperCase();
      out.put('Browser', browserName);
      out.put('App Version', data['appVersion']);
      out.put('Platform', data['platform']);
      out.put('User Agent', data['userAgent']);
      out.put('Vendor', data['vendor']);

    default:
      for (final MapEntry<String, dynamic> e in data.entries)
      {
        out.put(e.key, e.value);
      }
  }

  out.put('Locale', data['systemLocale'] ?? data['locale']);
  out.put('Time Zone', data['timeZone']);
  out.put('Device Type', data['deviceType']);

  return out.map;
}

Object? _getPath({required final List<String> path, required final Map<String, dynamic> data})
{
  dynamic cur = data;
  for (final String p in path)
  {
    if (cur is Map<String, dynamic> && cur.containsKey(p))
    {
      cur = cur[p];
    }
    else
    {
      return null;
    }
  }
  return cur;
}

Object? _firstOfPaths({required final List<List<String>> candidates, required final Map<String, dynamic> data})
{
  for (final List<String> path in candidates)
  {
    final Object? v = _getPath(path: path, data: data);
    if (v != null && v.toString().trim().isNotEmpty) return v;
  }
  return null;
}

String _osName({required final BaseDeviceInfo info})
{
  if (info is AndroidDeviceInfo) return _osAndroid;
  if (info is IosDeviceInfo) return _osIos;
  if (info is MacOsDeviceInfo) return _osMacOs;
  if (info is WindowsDeviceInfo) return _osWindows;
  if (info is LinuxDeviceInfo) return _osLinux;
  if (info is WebBrowserInfo) return _osWeb;
  return _osUnknown;
}