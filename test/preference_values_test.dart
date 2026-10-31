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

import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/preferences/preference_values.dart';

void main()
{
  group("a ranged preference", ()
  {
    test("keeps a value within its limits", ()
    {
      final RangedPref<int> pref = RangedPref<int>(value: 5, min: 1, max: 9);
      expect(pref.value, 5);
      expect(pref.min, 1);
      expect(pref.max, 9);
    });

    test("pulls a value below its limits up", ()
    {
      expect(RangedPref<int>(value: 0, min: 1, max: 9).value, 1);
      expect(RangedPref<double>(value: 0.5, min: 1.0, max: 9.0).value, 1.0);
    });

    test("pulls a value above its limits down", ()
    {
      expect(RangedPref<int>(value: 10, min: 1, max: 9).value, 9);
      expect(RangedPref<double>(value: 9.5, min: 1.0, max: 9.0).value, 9.0);
    });

    test("keeps its type", ()
    {
      expect(RangedPref<int>(value: 10, min: 1, max: 9).value, isA<int>());
      expect(RangedPref<double>(value: 0.5, min: 1.0, max: 9.0).value, isA<double>());
    });

    test("notifies like any other notifier", ()
    {
      final RangedPref<int> pref = RangedPref<int>(value: 5, min: 1, max: 9);
      int calls = 0;
      pref.addListener(() {calls++;});
      pref.value = 6;
      expect(calls, 1);
    });
  });
}
