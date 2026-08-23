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


import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/kpix_icons.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/layer_states/rasterable_layer_state.dart';
import 'package:kpix/layer_states/shading_layer/shading_layer_state.dart';
import 'package:kpix/managers/history/history_shift_set.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/util/color_names.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_range_slider.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:uuid/uuid.dart';

part '../../util/kpal_ramp_data.dart';
part 'kpal_color_card_widget.dart';
part 'kpal_ramp_widget.dart';
part 'kpal_vertical_slider_widget.dart';

class KPalWidgetOptions
{
  final KPalRampWidgetOptions rampOptions;
  final double borderWidth;
  final double outsidePadding;
  final double insidePadding;
  final double borderRadius;
  final int smokeOpacity;
  final double iconSize;

  KPalWidgetOptions({
    required this.borderWidth,
    required this.outsidePadding,
    required this.smokeOpacity,
    required this.rampOptions,
    required this.borderRadius,
    required this.insidePadding,
    required this.iconSize,
  });
}

class KPal extends StatefulWidget
{
  final KPalRampData _colorRamp;
  final ColorRampUpdateFn _accept;
  final ColorRampFn _delete;
  final int _usedPixels;

  const KPal({
    super.key,
    required final KPalRampData colorRamp,
    required final void Function({bool addToHistoryStack, required KPalRampData originalData, required KPalRampData ramp}) accept,
    required final void Function({bool addToHistoryStack, required KPalRampData ramp}) delete,
    required final int usedPixels,
  }) : _delete = delete, _accept = accept, _colorRamp = colorRamp, _usedPixels = usedPixels;

  @override
  State<KPal> createState() => _KPalState();
}

class _KPalState extends State<KPal>
{
  late KPixOverlay _alertDialog;
  final KPalWidgetOptions _options = GetIt.I.get<PreferenceManager>().kPalWidgetOptions;
  late KPalRampData _originalData;

  @override
  void initState() {
    super.initState();
    _originalData = KPalRampData.from(other: widget._colorRamp);
    _alertDialog = getTwoButtonDialog(
        onNo: _dismissAlertDialog,
        onYes: _acceptDeletion,
        outsideCancelable: false,
        message: "Do you really want to delete this color ramp?\n${widget._usedPixels} pixel(s) will be deleted.",
      );
  }

  void _acceptChange()
  {
    widget._accept(ramp: widget._colorRamp, originalData: _originalData);
  }

  void _discardChange()
  {
    widget._colorRamp.updateFromOther(other: _originalData);
    widget._accept(ramp: widget._colorRamp, originalData: _originalData);
  }

  void _acceptDeletion()
  {
    _dismissAlertDialog();
    widget._delete(ramp: widget._colorRamp);
  }

  void _dismissAlertDialog()
  {
    _alertDialog.hide();
  }

  void _showDeleteDialog()
  {
    _alertDialog.show(context: context);
  }

  @override
  Widget build(final BuildContext context)
  {
    return Center(
      child: KPixAnimationWidget(
        constraints: const BoxConstraints(
          maxHeight: 1000,
          maxWidth: 1600,
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: KPalRamp(
                rampData: widget._colorRamp,
                originalRampData: _originalData,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(_options.insidePadding),
                    child: IconButton.outlined(
                      icon: const Icon(
                        TablerIcons.x,
                        //size: _options.iconSize,
                      ),
                      onPressed: _discardChange,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(_options.insidePadding),
                    child: IconButton.outlined(
                      icon: const Icon(
                        TablerIcons.trash,
                        //size: _options.iconSize,
                      ),
                      onPressed: () {
                        _showDeleteDialog();
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(_options.insidePadding),
                    child: IconButton.outlined(
                      icon: const Icon(
                        TablerIcons.check,
                        //size: _options.iconSize,
                      ),
                      onPressed: _acceptChange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
