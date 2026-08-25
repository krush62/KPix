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

import 'package:flutter/foundation.dart';
import 'package:kpix/util/helpers/system_info_helper.dart';
import 'package:kpix/util/logging_extensions.dart';
import 'package:logger/logger.dart';

class KPixLogger extends Logger {
  KPixLogger()
      : super(
    printer: _createPrinter(),
    level: Level.info,
    output: _createOutput(),
  );

  static LogPrinter _createPrinter() {
    final SimplePrinter defaultPrinter = SimplePrinter(
      printTime: true,
      colors: false,
    );

    final PrettyPrinter warningPrinter = PrettyPrinter(
      methodCount: 3,
      errorMethodCount: 10,
      printEmojis: false,
      colors: false,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    );

    return HybridPrinter(
      defaultPrinter,
      warning: warningPrinter,
      error: warningPrinter,
      fatal: warningPrinter,
    );
  }

  static LogOutput? _createOutput() {
    if (kIsWeb) {
      return null;
    }

    return MultiOutput(<LogOutput?>[
      FileLogOutput(),
      ThresholdOutput(
        ConsoleOutput(),
        minLevel: Level.warning,
      ),
    ]);
  }

  Future<void> logSystemInfo() async
  {
    final Map<String, String> info = await readableDeviceInfo();
    for (final MapEntry<String, String> entry in info.entries)
    {
      i("${entry.key}: ${entry.value}");
    }
  }
}
