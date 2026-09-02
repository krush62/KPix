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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PreferenceManager> createManager() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return PreferenceManager(prefs);
  }

  group('preference reload', () {
    test('keeps the notifier objects, so listeners survive a reload', () async {
      final PreferenceManager manager = await createManager();
      final GuiPreferenceContent gui = manager.guiPreferenceContent;
      final ValueNotifier<int> toolOpacity = gui.toolOpacity;

      await manager.loadPreferences();

      expect(identical(manager.guiPreferenceContent, gui), isTrue);
      expect(identical(manager.guiPreferenceContent.toolOpacity, toolOpacity), isTrue);
      expect(identical(manager.behaviorPreferenceContent.undoSteps, manager.behaviorPreferenceContent.undoSteps), isTrue);
    });

    test('notifies listeners registered before a save/reload cycle', () async {
      final PreferenceManager manager = await createManager();
      final ValueNotifier<int> toolOpacity = manager.guiPreferenceContent.toolOpacity;

      int notifications = 0;
      void onChange() => notifications++;
      toolOpacity.addListener(onChange);
      addTearDown(() => toolOpacity.removeListener(onChange));

      //first round: change the value, confirm, reload
      final int firstValue = (toolOpacity.value + 10).clamp(opacityMin, opacityMax);
      manager.guiPreferenceContent.toolOpacity.value = firstValue;
      await manager.saveUserPrefs();
      await manager.loadPreferences();

      expect(notifications, 1);
      expect(manager.guiPreferenceContent.toolOpacity.value, firstValue);

      //second round: the dialog writes to whatever the manager exposes now
      final int secondValue = (firstValue + 10).clamp(opacityMin, opacityMax);
      manager.guiPreferenceContent.toolOpacity.value = secondValue;
      await manager.saveUserPrefs();
      await manager.loadPreferences();

      expect(notifications, 2);
      expect(toolOpacity.value, secondValue);
    });

    test('reverts the live notifier when a reload discards unsaved changes', () async {
      final PreferenceManager manager = await createManager();
      final ValueNotifier<int> selectionOpacity = manager.guiPreferenceContent.selectionOpacity;
      final int storedValue = selectionOpacity.value;

      //the dialog changed the value, then it got dismissed
      selectionOpacity.value = (storedValue + 10).clamp(opacityMin, opacityMax);
      await manager.loadPreferences();

      expect(manager.guiPreferenceContent.selectionOpacity.value, storedValue);
      expect(selectionOpacity.value, storedValue);
    });
  });
}
