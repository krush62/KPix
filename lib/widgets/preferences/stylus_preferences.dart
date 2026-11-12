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


import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/widgets/preferences/preference_gui.dart';
import 'package:material_ui/material_ui.dart';

class StylusPreferences extends StatefulWidget
{
  final StylusPreferenceContent prefs;
  const StylusPreferences({super.key, required this.prefs});

  @override
  State<StylusPreferences> createState() => _StylusPreferencesState();
}

class _StylusPreferencesState extends State<StylusPreferences>
{
  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Tooltip(
          message: l10n.timeThatNeedsToBeHeldDown,
          child: PrefSliderRow<int>(
            text: l10n.longPressDelay,
            minVal: widget.prefs.stylusLongPressDelay.min.toDouble(),
            maxVal: widget.prefs.stylusLongPressDelay.max.toDouble(),
            divisions: (widget.prefs.stylusLongPressDelay.max - widget.prefs.stylusLongPressDelay.min) ~/ 25,
            notifier: widget.prefs.stylusLongPressDelay,
            defaultValue: PreferenceInt.StylusOptions_LongPressDelay.defaultValue,
            labelBuilder: (final int value) => "${value}ms",
          ),
        ),
        Tooltip(
          message: l10n.distanceThatMustBeMoved,
          child: PrefSliderRow<double>(
            text: l10n.longPressCancelDistance,
            notifier: widget.prefs.stylusLongPressCancelDistance,
            defaultValue: PreferenceDouble.StylusOptions_LongPressCancelDistance.defaultValue,
            minVal: widget.prefs.stylusLongPressCancelDistance.min,
            maxVal: widget.prefs.stylusLongPressCancelDistance.max,
            divisions: (widget.prefs.stylusLongPressCancelDistance.max - widget.prefs.stylusLongPressCancelDistance.min).round(),
            labelBuilder: (final double value) => "${value.round()}px",
          ),
        ),
        Tooltip(
          message: l10n.distanceThatNeedsToBeMovedVertically,
          child: PrefSliderRow<double>(
            text: l10n.zoomStepDistance,
            notifier: widget.prefs.stylusZoomStepDistance,
            defaultValue: PreferenceDouble.StylusOptions_ZoomStepDistance.defaultValue,
            minVal: widget.prefs.stylusZoomStepDistance.min,
            maxVal: widget.prefs.stylusZoomStepDistance.max,
            divisions: (widget.prefs.stylusZoomStepDistance.max - widget.prefs.stylusZoomStepDistance.min).round(),
            labelBuilder: (final double value) => "${value.round()}px",
          ),
        ),
        Tooltip(
          message: l10n.distanceThatNeedsToBeMovedHorizontally,
          child: PrefSliderRow<double>(
            text: l10n.toolSizeStepDistance,
            notifier: widget.prefs.stylusSizeStepDistance,
            defaultValue: PreferenceDouble.StylusOptions_SizeStepDistance.defaultValue,
            minVal: widget.prefs.stylusSizeStepDistance.min,
            maxVal: widget.prefs.stylusSizeStepDistance.max,
            divisions: (widget.prefs.stylusSizeStepDistance.max - widget.prefs.stylusSizeStepDistance.min).round(),
            labelBuilder: (final double value) => "${value.round()}px",
          ),
        ),
        Tooltip(
          message: l10n.timeoutForPickingAColor,
          child: PrefSliderRow<int>(
            text: l10n.colorPickTimeout,
            minVal: widget.prefs.stylusPickMaxDuration.min.toDouble(),
            maxVal: widget.prefs.stylusPickMaxDuration.max.toDouble(),
            divisions: (widget.prefs.stylusPickMaxDuration.max - widget.prefs.stylusPickMaxDuration.min) ~/ 25,
            notifier: widget.prefs.stylusPickMaxDuration,
            defaultValue: PreferenceInt.StylusOptions_PickMaxDuration.defaultValue,
            labelBuilder: (final int value) => "${value}ms",
          ),
        ),
      ],
    );
  }
}
