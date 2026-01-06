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


import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileLogOutput extends LogOutput
{
  IOSink? _sink;
  Future<bool>? _initFuture;
  Future<void> _writeQueue = Future<void>.value();
  String? _logPath;
  String? get logPath => _logPath;

  Future<bool> _ensureReady() async
  {
    final Future<bool>? existing = _initFuture;
    if (existing != null) return existing;

    final Future<bool> future = () async
    {
      try
      {
        final Directory dir = await getApplicationSupportDirectory();
        final File file = File(p.join(dir.path, 'kpix.log'));
        if (kDebugMode)
        {
          print("Logging started using file ${file.path}.");
        }
        _logPath = file.path;

        await file.create(recursive: true);

        final bool exists = await file.exists();
        if (!exists)
        {
          return false;
        }
        _sink = file.openWrite(); // TRUNCATE/WRITE MODE

        _sink!.writeln('===== Log started at ${DateTime.now().toIso8601String()} =====');
        await _sink!.flush();

        return true;
      }
      catch (e, s)
      {
        if (kDebugMode)
        {
          print('FileLogOutput init failed: $e\n$s');
        }
        _sink = null;
        return false;
      }
    }();

    _initFuture = future;
    return future;
  }



  @override
  void output(final OutputEvent event)
  {
    _writeQueue = _writeQueue.then((_) async
    {
      final bool ready = await _ensureReady();
      if (!ready)
      {
        if (kDebugMode)
        {
          print('FileLogOutput not ready!');
        }
        return;
      }

      final IOSink? sink = _sink;
      if (sink == null) return;

      try
      {
        for (final String line in event.lines)
        {
          sink.writeln(line);
        }
        await sink.flush();
      }
      catch (e)
      {
        if (kDebugMode)
        {
          print('FileLogOutput write failed! $e');
        }
      }
    });
  }

  @override
  Future<void> destroy() async
  {
    try
    {
      await _writeQueue;
    }
    catch (_) {}

    try
    {
      await _sink?.flush();
    }
    catch (_) {}

    try
    {
      await _sink?.close();
    }
    catch (_) {}

    _sink = null;
    _initFuture = null;

    return super.destroy();
  }
}



class ThresholdOutput extends LogOutput {
  ThresholdOutput(this.inner, {required this.minLevel});

  final LogOutput inner;
  final Level minLevel;

  bool _allows(final Level level) {
    // Adjust order to match your logger version (trace/debug/info/warning/error/fatal)
    final Map<Level, int> order = <Level, int>{
      Level.trace: 0,
      Level.debug: 1,
      Level.info: 2,
      Level.warning: 3,
      Level.error: 4,
      Level.fatal: 5,
    };
    return order[level]! >= order[minLevel]!;
  }

  @override
  void output(final OutputEvent event) {
    if (_allows(event.level)) {
      inner.output(event); // inner handles its own queuing
    }
  }

  @override
  Future<void> destroy() async {
    await inner.destroy();
    return super.destroy();
  }
}


