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
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/models/constraints/tool_stamp_constraints.dart';
import 'package:kpix/models/stamp_manager_data.dart';
import 'package:kpix/tool_options/tool_gui.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';


class StampOptions extends IToolOptions
{
  final ValueNotifier<int> scale = ValueNotifier<int>(StampConstraints.scaleDefault);
  final ValueNotifier<bool> flipH = ValueNotifier<bool>(StampConstraints.flipHDefault);
  final ValueNotifier<bool> flipV = ValueNotifier<bool>(StampConstraints.flipVDefault);
  final ValueNotifier<bool> gridAlign = ValueNotifier<bool>(StampConstraints.gridAlignDefault);
  final ValueNotifier<bool> unmodifiedGridAlign = ValueNotifier<bool>(StampConstraints.gridAlignDefault);
  final ValueNotifier<int> gridOffsetX = ValueNotifier<int>(StampConstraints.gridOffsetDefault);
  final ValueNotifier<int> gridOffsetY = ValueNotifier<int>(StampConstraints.gridOffsetDefault);

  /// The offsets have to stay within the stamp, so a smaller one can lower them.
  void clampGridOffsets({required final StampManagerEntryData stamp})
  {
    gridOffsetX.value = gridOffsetX.value.clamp(0, stamp.width - 1);
    gridOffsetY.value = gridOffsetY.value.clamp(0, stamp.height - 1);
  }

  static Column getWidget({
    required final BuildContext context,
    required final StampOptions stampOptions,
    required final Function() showStampManager,
  }) {
    final HotkeyManager hotkeyManager = GetIt.I.get<HotkeyManager>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 80,
                child: OutlinedButton(
                  style: Theme.of(context).outlinedButtonTheme.style!.copyWith(
                    shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
                    side: WidgetStateProperty.all(BorderSide(width: 4.0, color: Theme.of(context).primaryColorLight)),
                  ),
                  onPressed: () {
                    showStampManager();
                  },
                  child: _getStampPreview(stampOptions: stampOptions),
                ),
              ),
            ),
            const SizedBox(width: ToolSettingsWidgetOptions.padding),
            Expanded(
              child: Column(
                children: <Widget>[
                  _getFlipRow(context: context, icon: TablerIcons.flip_vertical, notifier: stampOptions.flipH),
                  _getFlipRow(context: context, icon: TablerIcons.flip_horizontal, notifier: stampOptions.flipV),
                ],
              ),
            ),
          ],
        ),
        Visibility(
          visible: false,
          child: ToolSliderRow<int>(
            label: AppLocalizations.of(context)!.scale,
            notifier: stampOptions.scale,
            minVal: StampConstraints.scaleMin.toDouble(),
            maxVal: StampConstraints.scaleMax.toDouble(),
          ),
        ),
        ToolModifierSwitchRow(
          notifier: stampOptions.gridAlign,
          unmodifiedNotifier: stampOptions.unmodifiedGridAlign,
          label: AppLocalizations.of(context)!.gridAlign,
            defaultState: StampConstraints.gridAlignDefault,
          modifierNotifier: hotkeyManager.controlNotifier,
        ),
        _getOffsetRow(
          label: AppLocalizations.of(context)!.offsetX,
          notifier: stampOptions.gridOffsetX,
          gridAlign: stampOptions.gridAlign,
          stampSize: (final StampManagerEntryData stamp) => stamp.width,
        ),
        _getOffsetRow(
          label: AppLocalizations.of(context)!.offsetY,
          notifier: stampOptions.gridOffsetY,
          gridAlign: stampOptions.gridAlign,
          stampSize: (final StampManagerEntryData stamp) => stamp.height,
        ),
      ],
    );
  }

  static Widget _getStampPreview({required final StampOptions stampOptions})
  {
    return ValueListenableBuilder<StampManagerEntryData?>(
      valueListenable: GetIt.I.get<StampManager>().selectedStamp,
      builder: (final BuildContext context, final StampManagerEntryData? stampData, final Widget? child)
      {
        if (stampData != null)
        {
          if (stampData.thumbnail != null)
          {
            return Padding(
              padding: const EdgeInsets.all(ToolSettingsWidgetOptions.padding),
              child: ListenableBuilder(
                listenable: Listenable.merge(<Listenable>[stampOptions.flipH, stampOptions.flipV]),
                builder: (final BuildContext context, final Widget? child) {
                  return Transform.flip(
                    flipX: stampOptions.flipH.value,
                    flipY: stampOptions.flipV.value,
                    child: RawImage(image: stampData.thumbnail, fit: BoxFit.contain, filterQuality: FilterQuality.none, scale: 0.1,),
                  );
                },
              ),
            );
          }
          else
          {
            return Text(stampData.name);
          }
        }
        else
        {
          return Text("<${AppLocalizations.of(context)!.noStamp.toUpperCase()}>");
        }
      },
    );
  }

  static Widget _getFlipRow({required final BuildContext context, required final IconData icon, required final ValueNotifier<bool> notifier})
  {
    return Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Icon(
              color: Theme.of(context).primaryColorLight,
              icon,
            ),
          ),
        ),
        const SizedBox(width: ToolSettingsWidgetOptions.padding),
        ValueListenableBuilder<bool>(
          valueListenable: notifier,
          builder: (final BuildContext context, final bool value, final Widget? child){
            return Switch(
              onChanged: (final bool newVal) {notifier.value = newVal;},
              value: value,
            );
          },
        ),
      ],
    );
  }

  static Widget _getOffsetRow({
    required final String label,
    required final ValueNotifier<int> notifier,
    required final ValueNotifier<bool> gridAlign,
    required final int Function(StampManagerEntryData stamp) stampSize,
  })
  {
    final ValueNotifier<StampManagerEntryData?> selectedStamp = GetIt.I.get<StampManager>().selectedStamp;
    return ValueListenableBuilder<bool>(
      valueListenable: gridAlign,
      builder: (final BuildContext context, final bool align, final Widget? child) {
        if (align)
        {
          return Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              Expanded(
                flex: ToolSettingsWidgetOptions.columnWidthRatio,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ListenableBuilder(
                    listenable: Listenable.merge(<Listenable>[selectedStamp, notifier]),
                    builder: (final BuildContext context, final Widget? child)
                    {
                      final StampManagerEntryData? stampData = selectedStamp.value;
                      if (stampData != null)
                      {
                        return KPixSlider(
                          value: notifier.value.toDouble(),
                          max: stampSize(stampData) - 1,
                          onChanged: (final double newVal) {notifier.value = newVal.round();},
                          textStyle: Theme.of(context).textTheme.bodyLarge!,
                        );
                      }
                      else
                      {
                        return const SizedBox();
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        }
        else
        {
          return const SizedBox();
        }
      },
    );
  }

  @override
  void changeSize({required final int steps, required final int originalValue})
  {
    scale.value = (originalValue + steps).clamp(StampConstraints.scaleMin, StampConstraints.scaleMax);
  }

  @override
  int getSize()
  {
    return scale.value;
  }

}
