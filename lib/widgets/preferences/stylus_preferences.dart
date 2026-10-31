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
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/preferences/preference_values.dart';
import 'package:kpix/widgets/preferences/preference_gui.dart';

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
            notifier: widget.prefs.stylusLongPressDelay,
          ),
        ),
        Tooltip(
          message: l10n.distanceThatMustBeMoved,
          child: PrefSliderRow<double>(
            text: l10n.longPressCancelDistance,
            notifier: widget.prefs.stylusLongPressCancelDistance,
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
            notifier: widget.prefs.stylusPickMaxDuration,
          ),
        ),
      ],
    );
  }
}
