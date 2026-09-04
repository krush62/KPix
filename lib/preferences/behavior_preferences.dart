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


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/preferences/preference_gui.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/util/file_handler.dart';
import 'package:kpix/util/helpers/file_helper.dart';
import 'package:kpix/util/messages.dart';



class BehaviorPreferences extends StatefulWidget
{
  final BehaviorPreferenceContent prefs;
  const BehaviorPreferences({super.key, required this.prefs});

  @override
  State<BehaviorPreferences> createState() => _BehaviorPreferencesState();
}

class _BehaviorPreferencesState extends State<BehaviorPreferences>
{
  void _projectDirectoryModeChanged({required final bool useCustom})
  {
    if (useCustom)
    {
      if (widget.prefs.customProjectDirectory.value.isNotEmpty)
      {
        widget.prefs.useCustomProjectDirectory.value = true;
      }
      else
      {
        _selectCustomProjectDirectory();
      }
    }
    else
    {
      widget.prefs.useCustomProjectDirectory.value = false;
    }
  }

  void _selectCustomProjectDirectory()
  {
    final String startDir = widget.prefs.customProjectDirectory.value.isNotEmpty ? widget.prefs.customProjectDirectory.value : GetIt.I.get<AppPaths>().projectsDir;
    getDirectory(startDir: startDir).then((final String? chosenDir)
    {
      if (chosenDir != null)
      {
        if (hasWriteAccess(directory: chosenDir))
        {
          widget.prefs.customProjectDirectory.value = chosenDir;
          widget.prefs.useCustomProjectDirectory.value = true;
        }
        else
        {
          showMessage(text: "Insufficient permissions for the selected directory!");
        }
      }
    });
  }

  @override
  Widget build(final BuildContext context) {
    return SingleChildScrollView(
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PrefSliderRow<int>(
            text: "Undo Steps",
            minVal: widget.prefs.undoStepsMin.toDouble(),
            maxVal: widget.prefs.undoStepsMax.toDouble(),
            notifier: widget.prefs.undoSteps,
        ),
        /*Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: Text("Select Shape After Insertion", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.prefs.selectShapeAfterInsert,
                builder: (final BuildContext context, final bool select, final Widget? child)
                {
                  return Switch(
                    value: select,
                    onChanged: (final bool newVal){widget.prefs.selectShapeAfterInsert.value = newVal;},
                  );
                },
              ),
            ),
          ],
        ),*/
        PrefSwitchRow(
            label: "Select Inserted Layers",
            notifier: widget.prefs.selectLayerAfterInsert,
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(child: Text("Default Shading Layer Settings", style: Theme.of(context).textTheme.titleSmall)),
            Expanded(
              flex: 2,
              child: Column(
                children: <Widget>[
                  PrefSliderRow<int>(
                    text: "Max Darken",
                    minVal: widget.prefs.shadingConstraints.shadingStepsMin.toDouble(),
                    maxVal: widget.prefs.shadingConstraints.shadingStepsMax.toDouble(),
                    notifier: widget.prefs.shadingStepsMinus,
                    textStyle:  Theme.of(context).textTheme.labelMedium,
                  ),
                  PrefSliderRow<int>(
                    text: "Max Brighten",
                    minVal: widget.prefs.shadingConstraints.shadingStepsMin.toDouble(),
                    maxVal: widget.prefs.shadingConstraints.shadingStepsMax.toDouble(),
                    notifier: widget.prefs.shadingStepsPlus,
                    textStyle:  Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        PrefSliderRow<int>(
            text: "Default Frame Time",
            minVal: widget.prefs.frameConstraints.minFps.toDouble(),
            maxVal: widget.prefs.frameConstraints.maxFps.toDouble(),
            notifier: widget.prefs.fps,
        ),
       PrefSwitchRow(
           label: "Show Reference Layers outside of canvas",
           notifier: widget.prefs.showReferenceOutsideCanvas,
       ),
        if (!kIsWeb)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(child: Text("Project Directory", style: Theme.of(context).textTheme.titleSmall)),
              Expanded(
                flex: 2,
                child: ValueListenableBuilder<bool>(
                  valueListenable: widget.prefs.useCustomProjectDirectory,
                  builder: (final BuildContext context, final bool useCustom, final Widget? child)
                  {
                    return RadioGroup<bool>(
                      groupValue: useCustom,
                      onChanged: (final bool? newVal) {_projectDirectoryModeChanged(useCustom: newVal ?? false);},
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Radio<bool>(
                                value: false,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {_projectDirectoryModeChanged(useCustom: false);},
                                  child: Tooltip(
                                    message: getDefaultProjectsDir(internalDir: GetIt.I.get<AppPaths>().internalDir),
                                    waitDuration: toolTipDuration,
                                    child: const Text("Default"),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              const Radio<bool>(
                                value: true,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              GestureDetector(
                                onTap: () {_projectDirectoryModeChanged(useCustom: true);},
                                child: const Text("Custom"),
                              ),
                              Expanded(
                                child: ValueListenableBuilder<String>(
                                  valueListenable: widget.prefs.customProjectDirectory,
                                  builder: (final BuildContext context, final String customDir, final Widget? child)
                                  {
                                    return Tooltip(
                                      message: customDir,
                                      waitDuration: toolTipDuration,
                                      child: Text(
                                        customDir,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(
                                width: 16,
                              ),
                              Tooltip(
                                message: "Choose Directory",
                                waitDuration: toolTipDuration,
                                child: SizedBox(
                                  height: 32,
                                  width: 32,
                                  child: IconButton.outlined(
                                    constraints: const BoxConstraints(),
                                    onPressed: _selectCustomProjectDirectory,
                                    icon: const Icon(TablerIcons.folder, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
      ),
    );
  }
}
