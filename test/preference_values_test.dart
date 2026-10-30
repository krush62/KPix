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
  test("each stylus preference keeps its own limits", ()
  {
    final StylusPreferenceContent prefs = StylusPreferenceContent(
      stylusLongPressDelay: 500,
      stylusLongPressDelayMin: 50,
      stylusLongPressDelayMax: 1000,
      stylusLongPressCancelDistance: 10.0,
      stylusLongPressCancelDistanceMin: 1.0,
      stylusLongPressCancelDistanceMax: 20.0,
      stylusZoomStepDistance: 10.0,
      stylusZoomStepDistanceMin: 1.0,
      stylusZoomStepDistanceMax: 30.0,
      stylusSizeStepDistance: 10.0,
      stylusSizeStepDistanceMin: 1.0,
      stylusSizeStepDistanceMax: 40.0,
      stylusPickMaxDuration: 400,
      stylusPickMaxDurationMin: 100,
      stylusPickMaxDurationMax: 700,
    );

    expect(prefs.stylusLongPressDelayMax, 1000);
    expect(prefs.stylusLongPressCancelDistanceMax, 20.0);
    expect(prefs.stylusZoomStepDistanceMax, 30.0);
    expect(prefs.stylusSizeStepDistanceMax, 40.0);
    expect(prefs.stylusPickMaxDurationMax, 700);
  });
}
