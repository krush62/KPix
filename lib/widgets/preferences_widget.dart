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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/preferences/behavior_preferences.dart';
import 'package:kpix/preferences/gui_preferences.dart';
import 'package:kpix/widgets/overlay_entries.dart';

enum PreferenceSectionType
{
  gui,
  behavior,
  controlsPC,
  controlsStylus,
}

class PreferenceSection
{
  final String title;
  final IconData icon;
  const PreferenceSection({required this.title, required this.icon});
}

const Map<PreferenceSectionType, PreferenceSection> preferenceMap =
{
  PreferenceSectionType.gui: PreferenceSection(title: "GUI", icon: FontAwesomeIcons.tv),
  PreferenceSectionType.behavior: PreferenceSection(title: "Behavior", icon: FontAwesomeIcons.gears),
  PreferenceSectionType.controlsPC: PreferenceSection(title: "Controls PC", icon: FontAwesomeIcons.keyboard),
  PreferenceSectionType.controlsStylus: PreferenceSection(title: "Controls Stylus", icon: FontAwesomeIcons.pen),
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
  final ValueNotifier<PreferenceSectionType> _prefSection = ValueNotifier(PreferenceSectionType.gui);


  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: _options.elevation,
      shadowColor: Theme.of(context).primaryColorDark,
      borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
      child: Container(
        constraints: BoxConstraints(
          minHeight: _options.minHeight,
          minWidth: _options.minWidth,
          maxHeight: _options.maxHeight,
          maxWidth: _options.maxWidth,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          border: Border.all(
            color: Theme.of(context).primaryColorLight,
            width: _options.borderWidth,
          ),
          borderRadius: BorderRadius.all(Radius.circular(_options.borderRadius)),
        ),
        child: Padding(
          padding: EdgeInsets.all(_options.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ValueListenableBuilder<PreferenceSectionType>(
                valueListenable: _prefSection,
                builder: (final BuildContext context, final PreferenceSectionType pref, final Widget? child) {
                  return SegmentedButton<PreferenceSectionType>(
                    segments: [
                      ButtonSegment(
                        value: PreferenceSectionType.gui,
                        label: Tooltip(
                          message: preferenceMap[PreferenceSectionType.gui]!.title,
                          waitDuration: AppState.toolTipDuration,
                          child: Icon(
                            preferenceMap[PreferenceSectionType.gui]!.icon
                          )
                        )
                      ),
                      ButtonSegment(
                        value: PreferenceSectionType.behavior,
                        label: Tooltip(
                          message: preferenceMap[PreferenceSectionType.behavior]!.title,
                          waitDuration: AppState.toolTipDuration,
                          child: Icon(
                            preferenceMap[PreferenceSectionType.behavior]!.icon
                          )
                        )
                      ),
                      ButtonSegment(
                        value: PreferenceSectionType.controlsPC,
                        label: Tooltip(
                          message: preferenceMap[PreferenceSectionType.controlsPC]!.title,
                          waitDuration: AppState.toolTipDuration,
                          child: Icon(
                            preferenceMap[PreferenceSectionType.controlsPC]!.icon
                          )
                        )
                      ),
                      ButtonSegment(
                        value: PreferenceSectionType.controlsStylus,
                        label: Tooltip(
                          message: preferenceMap[PreferenceSectionType.controlsStylus]!.title,
                          waitDuration: AppState.toolTipDuration,
                          child: Icon(
                            preferenceMap[PreferenceSectionType.controlsStylus]!.icon,
                          )
                        )
                      ),
                    ],
                    selected: <PreferenceSectionType>{pref},
                    emptySelectionAllowed: false,
                    multiSelectionEnabled: false,
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
                      case PreferenceSectionType.controlsPC:
                      case PreferenceSectionType.controlsStylus:
                      default:
                        return const Placeholder();
                    }
                  }
                )
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
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.all(_options.padding),
                      child: IconButton.outlined(
                        icon: FaIcon(
                          FontAwesomeIcons.thumbsUp,
                          size: _options.iconSize,
                        ),
                        onPressed: widget.accept,
                      ),
                    )
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.all(_options.padding),
                      child: IconButton.outlined(
                        icon: FaIcon(
                          FontAwesomeIcons.thumbsDown,
                          size: _options.iconSize,
                        ),
                        onPressed: widget.dismiss,
                      ),
                    )
                  ),
                ]
              ),
            ],
          )
        )
      )
    );
  }
}