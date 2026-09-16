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
import 'package:kpix/kpix_constants.dart';
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
          waitDuration: toolTipDuration,
          message: l10n.pollingTimeToCheck,
          child: PrefSliderRow<int>(
            text: l10n.pollInterval,
            minVal: widget.prefs.stylusPollIntervalMin.toDouble(),
            maxVal: widget.prefs.stylusPollIntervalMax.toDouble(),
            notifier: widget.prefs.stylusPollInterval,
          ),
        ),
        Tooltip(
          waitDuration: toolTipDuration,
          message: l10n.timeThatNeedsToBeHeldDown,
          child: PrefSliderRow<int>(
            text: l10n.longPressDelay,
            minVal: widget.prefs.stylusLongPressDelayMin.toDouble(),
            maxVal: widget.prefs.stylusLongPressDelayMax.toDouble(),
            notifier: widget.prefs.stylusLongPressDelay,
          ),
        ),
        Tooltip(
          waitDuration: toolTipDuration,
          message: l10n.distanceThatMustBeMoved,
          child: PrefSliderRow<double>(
            text: l10n.longPressCancelDistance,
            notifier: widget.prefs.stylusLongPressCancelDistance,
            minVal: widget.prefs.stylusLongPressCancelDistanceMin,
            maxVal: widget.prefs.stylusLongPressCancelDistanceMax,
            divisions: (widget.prefs.stylusLongPressCancelDistanceMax - widget.prefs.stylusLongPressCancelDistanceMin).round(),
            labelBuilder: (final double value) => "${value.round()}px",
          ),
        ),
        Tooltip(
          waitDuration: toolTipDuration,
          message: l10n.distanceThatNeedsToBeMovedVertically,
          child: PrefSliderRow<double>(
            text: l10n.zoomStepDistance,
            notifier: widget.prefs.stylusZoomStepDistance,
            minVal: widget.prefs.stylusZoomStepDistanceMin,
            maxVal: widget.prefs.stylusZoomStepDistanceMax,
            divisions: (widget.prefs.stylusZoomStepDistanceMax - widget.prefs.stylusZoomStepDistanceMin).round(),
            labelBuilder: (final double value) => "${value.round()}px",
          ),
        ),
        Tooltip(
          waitDuration: toolTipDuration,
          message: l10n.distanceThatNeedsToBeMovedHorizontally,
          child: PrefSliderRow<double>(
            text: l10n.toolSizeStepDistance,
            notifier: widget.prefs.stylusSizeStepDistance,
            minVal: widget.prefs.stylusSizeStepDistanceMin,
            maxVal: widget.prefs.stylusSizeStepDistanceMax,
            divisions: (widget.prefs.stylusSizeStepDistanceMax - widget.prefs.stylusSizeStepDistanceMin).round(),
            labelBuilder: (final double value) => "${value.round()}px",
          ),
        ),
        Tooltip(
          waitDuration: toolTipDuration,
          message: l10n.timeoutForPickingAColor,
          child: PrefSliderRow<int>(
            text: l10n.colorPickTimeout,
            minVal: widget.prefs.stylusPickMaxDurationMin.toDouble(),
            maxVal: widget.prefs.stylusPickMaxDurationMax.toDouble(),
            notifier: widget.prefs.stylusPickMaxDuration,
          ),
        ),
      ],
    );
  }
}
