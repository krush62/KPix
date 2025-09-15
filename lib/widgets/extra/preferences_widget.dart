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
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/preferences/behavior_preferences.dart';
import 'package:kpix/preferences/desktop_preferences.dart';
import 'package:kpix/preferences/gui_preferences.dart';
import 'package:kpix/preferences/stylus_preferences.dart';
import 'package:kpix/preferences/touch_preferences.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

enum PreferenceSectionType
{
  gui,
  behavior,
  controlsPC,
  controlsStylus,
  controlsTouch
}

class PreferenceSection
{
  final String title;
  final IconData icon;
  const PreferenceSection({required this.title, required this.icon});
}

const Map<PreferenceSectionType, PreferenceSection> preferenceMap =
<PreferenceSectionType, PreferenceSection>{
  PreferenceSectionType.gui: PreferenceSection(title: "GUI", icon: TablerIcons.app_window),
  PreferenceSectionType.behavior: PreferenceSection(title: "Behavior", icon: TablerIcons.tools),
  PreferenceSectionType.controlsPC: PreferenceSection(title: "Controls PC", icon: TablerIcons.device_desktop),
  PreferenceSectionType.controlsStylus: PreferenceSection(title: "Controls Stylus", icon: TablerIcons.pencil_bolt),
  PreferenceSectionType.controlsTouch: PreferenceSection(title: "Controls Touch", icon: TablerIcons.hand_click),
};

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
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<PreferenceSectionType> _prefSection = ValueNotifier<PreferenceSectionType>(PreferenceSectionType.gui);


  @override
  Widget build(final BuildContext context) {
    return KPixAnimationWidget(
      constraints: BoxConstraints(
        minHeight: _options.minHeight,
        minWidth: _options.minWidth,
        maxHeight: _options.maxHeight,
        maxWidth: _options.maxWidth,
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
                  ButtonSegment<PreferenceSectionType>(
                    value: PreferenceSectionType.gui,
                    label: Tooltip(
                      message: preferenceMap[PreferenceSectionType.gui]!.title,
                      waitDuration: AppState.toolTipDuration,
                      child: Icon(
                        preferenceMap[PreferenceSectionType.gui]!.icon,
                      ),
                    ),
                  ),
                  ButtonSegment<PreferenceSectionType>(
                    value: PreferenceSectionType.behavior,
                    label: Tooltip(
                      message: preferenceMap[PreferenceSectionType.behavior]!.title,
                      waitDuration: AppState.toolTipDuration,
                      child: Icon(
                        preferenceMap[PreferenceSectionType.behavior]!.icon,
                      ),
                    ),
                  ),
                  //for a future release
                  ButtonSegment<PreferenceSectionType>(
                    value: PreferenceSectionType.controlsPC,
                    label: Tooltip(
                      message: preferenceMap[PreferenceSectionType.controlsPC]!.title,
                      waitDuration: AppState.toolTipDuration,
                      child: Icon(
                        preferenceMap[PreferenceSectionType.controlsPC]!.icon,
                      ),
                    ),
                  ),
                  ButtonSegment<PreferenceSectionType>(
                    value: PreferenceSectionType.controlsStylus,
                    label: Tooltip(
                      message: preferenceMap[PreferenceSectionType.controlsStylus]!.title,
                      waitDuration: AppState.toolTipDuration,
                      child: Icon(
                        preferenceMap[PreferenceSectionType.controlsStylus]!.icon,
                      ),
                    ),
                  ),
                  ButtonSegment<PreferenceSectionType>(
                      value: PreferenceSectionType.controlsTouch,
                      label: Tooltip(
                        message: preferenceMap[PreferenceSectionType.controlsTouch]!.title,
                        waitDuration: AppState.toolTipDuration,
                        child: Icon(preferenceMap[PreferenceSectionType.controlsTouch]!.icon,
                        ),
                    ),
                  ),
                ],
                selected: <PreferenceSectionType>{pref},
                showSelectedIcon: false,
                onSelectionChanged: (final Set<PreferenceSectionType> prefSections) {_prefSection.value = prefSections.first;},
              );
            },
          ),
          Padding(
            padding: EdgeInsets.only(top: _options.padding, bottom: _options.padding),
            child: Divider(
              color: Theme.of(context).primaryColorLight,
              thickness: _options.borderWidth,
              height: _options.borderWidth,
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
            padding: EdgeInsets.only(top: _options.padding, bottom: _options.padding),
            child: Divider(
              color: Theme.of(context).primaryColorLight,
              thickness: _options.borderWidth,
              height: _options.borderWidth,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(_options.padding),
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
                  padding: EdgeInsets.all(_options.padding),
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
