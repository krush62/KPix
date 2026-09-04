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

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/preferences/behavior_preferences.dart';
import 'package:kpix/preferences/desktop_preferences.dart';
import 'package:kpix/preferences/gui_preferences.dart';
import 'package:kpix/preferences/stylus_preferences.dart';
import 'package:kpix/preferences/touch_preferences.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

/// Different sections of the preferences.
enum PreferenceSectionType
{
  gui,
  behavior,
  controlsPC,
  controlsStylus,
  controlsTouch
}

/// Data struct for a preference section.
class PreferenceSection
{
  final String title;
  final IconData icon;
  const PreferenceSection({required this.title, required this.icon});
}

/// Preference section dictionary.
const Map<PreferenceSectionType, PreferenceSection> preferenceMap =
<PreferenceSectionType, PreferenceSection>{
  PreferenceSectionType.gui: PreferenceSection(title: "GUI", icon: TablerIcons.app_window),
  PreferenceSectionType.behavior: PreferenceSection(title: "Behavior", icon: TablerIcons.tools),
  PreferenceSectionType.controlsPC: PreferenceSection(title: "Controls PC", icon: TablerIcons.device_desktop),
  PreferenceSectionType.controlsStylus: PreferenceSection(title: "Controls Stylus", icon: TablerIcons.pencil_bolt),
  PreferenceSectionType.controlsTouch: PreferenceSection(title: "Controls Touch", icon: TablerIcons.hand_click),
};


/// The preference screen widget.
class PreferencesWidget extends StatefulWidget
{
  final Function() dismiss;
  final Function() accept;
  const PreferencesWidget({super.key, required this.accept, required this.dismiss});

  @override
  State<PreferencesWidget> createState() => _PreferencesWidgetState();
}

class _PreferencesWidgetState extends State<PreferencesWidget>
{
  final ValueNotifier<PreferenceSectionType> _prefSection = ValueNotifier<PreferenceSectionType>(PreferenceSectionType.gui);

  ButtonSegment<PreferenceSectionType> _createSegment({required final PreferenceSectionType section})
  {
    return ButtonSegment<PreferenceSectionType>(
      value: section,
      label: Tooltip(
        message: preferenceMap[section]!.title,
        waitDuration: toolTipDuration,
        child: Icon(
          preferenceMap[section]!.icon,
        ),
      ),
    );
  }


  @override
  Widget build(final BuildContext context) {
    return KPixAnimationWidget(
      constraints: const BoxConstraints(
        minHeight: OverlayEntryAlertDialogOptions.minHeight,
        minWidth: OverlayEntryAlertDialogOptions.minWidth,
        maxHeight: OverlayEntryAlertDialogOptions.maxHeight,
        maxWidth: OverlayEntryAlertDialogOptions.maxWidth,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          ValueListenableBuilder<PreferenceSectionType>(
            valueListenable: _prefSection,
            builder: (final BuildContext context, final PreferenceSectionType pref, final Widget? child) {
              return SegmentedButton<PreferenceSectionType>(
                segments: <ButtonSegment<PreferenceSectionType>>[
                  _createSegment(section: PreferenceSectionType.gui),
                  _createSegment(section: PreferenceSectionType.behavior),
                  _createSegment(section: PreferenceSectionType.controlsPC),
                  _createSegment(section: PreferenceSectionType.controlsStylus),
                  _createSegment(section: PreferenceSectionType.controlsTouch),
                ],
                selected: <PreferenceSectionType>{pref},
                showSelectedIcon: false,
                onSelectionChanged: (final Set<PreferenceSectionType> prefSections) {_prefSection.value = prefSections.first;},
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: OverlayEntryAlertDialogOptions.padding, bottom: OverlayEntryAlertDialogOptions.padding),
            child: Divider(
              color: Theme.of(context).primaryColorLight,
              thickness: OverlayEntryAlertDialogOptions.borderWidth,
              height: OverlayEntryAlertDialogOptions.borderWidth,
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<PreferenceSectionType>(
              valueListenable: _prefSection,
              builder: (final BuildContext context, final PreferenceSectionType pref, final Widget? child) {
                switch(pref)
                {
                  case PreferenceSectionType.gui:
                    return GuiPreferences(prefs: GetIt.I.get<PreferenceManager>().guiPreferenceContent);
                  case PreferenceSectionType.behavior:
                    return BehaviorPreferences(prefs: GetIt.I.get<PreferenceManager>().behaviorPreferenceContent);
                  case PreferenceSectionType.controlsStylus:
                    return StylusPreferences(prefs: GetIt.I.get<PreferenceManager>().stylusPreferenceContent);
                  case PreferenceSectionType.controlsTouch:
                    return TouchPreferences(prefs: GetIt.I.get<PreferenceManager>().touchPreferenceContent);
                  case PreferenceSectionType.controlsPC:
                    return DesktopPreferences(prefs: GetIt.I.get<PreferenceManager>().desktopPreferenceContent);
                  //default:
                    //return const Placeholder();
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: OverlayEntryAlertDialogOptions.padding, bottom: OverlayEntryAlertDialogOptions.padding),
            child: Divider(
              color: Theme.of(context).primaryColorLight,
              thickness: OverlayEntryAlertDialogOptions.borderWidth,
              height: OverlayEntryAlertDialogOptions.borderWidth,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                  child: IconButton.outlined(
                    icon: const Icon(
                      TablerIcons.x,
                      //size: _options.iconSize,
                    ),
                    onPressed: widget.dismiss,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(OverlayEntryAlertDialogOptions.padding),
                  child: IconButton.outlined(
                    icon: const Icon(
                      TablerIcons.check,
                      //size: _options.iconSize,
                    ),
                    onPressed: widget.accept,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
