/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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

import 'dart:math';

import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/models/constraints/canvas_size_constraints.dart';
import 'package:kpix/util/helpers/format_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/callback_typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/controls/kpix_text_field.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';
import 'package:material_ui/material_ui.dart';


class _Dimension
{
  final int x;
  final int y;
  final String? label;
  const _Dimension({required this.x, required this.y, this.label});
}

enum _AspectRatioPreset
{
  ar1to1(
    label: "1:1",
    dimensions: <_Dimension>[
      _Dimension(x: 16, y: 16),
      _Dimension(x: 32, y: 32),
      _Dimension(x: 64, y: 64),
      _Dimension(x: 100, y: 100),
      _Dimension(x: 128, y: 128),
      _Dimension(x: 256, y: 256),
      _Dimension(x: 512, y: 512),
    ],
  ),
  ar4to3(
    label: "4:3",
    dimensions: <_Dimension>[
      _Dimension(x: 96, y: 72),
      _Dimension(x: 128, y: 96),
      _Dimension(x: 160, y: 120),
      _Dimension(x: 192, y: 144),
      _Dimension(x: 256, y: 192),
      _Dimension(x: 320, y: 240),
      _Dimension(x: 480, y: 360),
    ],
  ),
  ar16to9(
    label: "16:9",
    dimensions: <_Dimension>[
      _Dimension(x: 128, y: 72),
      _Dimension(x: 160, y: 90),
      _Dimension(x: 192, y: 108),
      _Dimension(x: 256, y: 144),
      _Dimension(x: 320, y: 180),
      _Dimension(x: 384, y: 216),
      _Dimension(x: 480, y: 270),
    ],
  ),
  arHandheld(
    icon: TablerIcons.device_gamepad,
    dimensions: <_Dimension>[
      _Dimension(x: 160, y: 144, label: "GB"),
      _Dimension(x: 240, y: 160, label: "GBA"),
      _Dimension(x: 256, y: 192, label: "NDS"),
      _Dimension(x: 224, y: 144, label: "WSC"),
      _Dimension(x: 480, y: 272, label: "PSP"),
      _Dimension(x: 160, y: 152, label: "NGPC"),
      _Dimension(x: 160, y: 102, label: "LYNX"),
    ],
  );

  const _AspectRatioPreset({this.label, this.icon, required this.dimensions});
  final String? label;
  final IconData? icon;
  final List<_Dimension> dimensions;
}


/// Screen for showing the options when creating a new file.
class NewProjectWidget extends StatefulWidget
{
  final Function()? dismiss;
  final NewFileFn accept;
  final Function() open;
  const NewProjectWidget({super.key, this.dismiss, required this.accept, required this.open});

  @override
  State<NewProjectWidget> createState() => NewProjectWidgetState();
}

class NewProjectWidgetState extends State<NewProjectWidget>
{
  //500 px for the content, plus the dialog's padding and border
  static const double _maxHeight = 500.0 + 2 * (OverlayEntryAlertDialogOptions.padding + OverlayEntryAlertDialogOptions.borderWidth);
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final ValueNotifier<int> _width = ValueNotifier<int>(64);
  final ValueNotifier<int> _height = ValueNotifier<int>(64);
  final ValueNotifier<_AspectRatioPreset> _ar = ValueNotifier<_AspectRatioPreset>(_AspectRatioPreset.ar1to1);
  static const double _maxPreviewHeight = 128;
  static const double _maxPreviewWidth = 224;
  final ValueNotifier<bool> _locked = ValueNotifier<bool>(false);
  double _aspectRatio = 1.0;
  final TextEditingController _textWidthController = TextEditingController();
  final TextEditingController _textHeightController = TextEditingController();

  @override
  void initState()
  {
    super.initState();
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.newProjectWidthTextFocus).addListener(_widthFocusChanged);
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.newProjectHeightTextFocus).addListener(_heightFocusChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.newProjectWidthTextFocus).removeListener(_widthFocusChanged);
    _hotkeyManager.getFocusNode(id: FocusNodeEntry.newProjectHeightTextFocus).removeListener(_heightFocusChanged);
    _textWidthController.dispose();
    _textHeightController.dispose();
  }

  void _widthFocusChanged()
  {
    if (!_hotkeyManager.getFocusNode(id: FocusNodeEntry.newProjectWidthTextFocus).hasFocus)
    {
      _textWidthController.text = _width.value.toString();
    }
  }

  void _heightFocusChanged()
  {
    if (!_hotkeyManager.getFocusNode(id: FocusNodeEntry.newProjectHeightTextFocus).hasFocus)
    {
      _textHeightController.text = _height.value.toString();
    }
  }

  void _setAspectRatio()
  {
    _aspectRatio = _width.value.toDouble() / _height.value.toDouble();
  }
  void _sizeInputChanged({required final String newVal, required final Function({required int newVal}) changeFunc})
  {
    final int? parsedVal = int.tryParse(newVal);
    if (parsedVal != null && parsedVal >= CanvasSizeConstraints.sizeMin && parsedVal <= CanvasSizeConstraints.sizeMax)
    {
      changeFunc(newVal: parsedVal);
    }
  }

  void _setResolutionViaButton({required final int width, required final int height})
  {
    _width.value = width.clamp(CanvasSizeConstraints.sizeMin, CanvasSizeConstraints.sizeMax);
    _height.value = height.clamp(CanvasSizeConstraints.sizeMin, CanvasSizeConstraints.sizeMax);
    _setAspectRatio();
  }

  void _changeWidth({required final int newVal})
  {
    _width.value = newVal.clamp(CanvasSizeConstraints.sizeMin, CanvasSizeConstraints.sizeMax);
    if (_locked.value)
    {
      _height.value = (_width.value / _aspectRatio).toInt().clamp(CanvasSizeConstraints.sizeMin, CanvasSizeConstraints.sizeMax);
    }
  }

  void _changeHeight({required final int newVal})
  {
    _height.value = newVal.clamp(CanvasSizeConstraints.sizeMin, CanvasSizeConstraints.sizeMax);
    if (_locked.value)
    {
      _width.value = (_height.value * _aspectRatio).toInt().clamp(CanvasSizeConstraints.sizeMin, CanvasSizeConstraints.sizeMax);
    }
  }

  List<ButtonSegment<_AspectRatioPreset>> _getAspectRatioButtons()
  {
    final List<ButtonSegment<_AspectRatioPreset>> arList = <ButtonSegment<_AspectRatioPreset>>[];

    for (final _AspectRatioPreset ar in _AspectRatioPreset.values)
    {
      Widget? indicatorWidget;
      final IconData? icon = ar.icon;
      final String? label = ar.label;
      final Color labelColor = ar == _ar.value ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight;
      if (icon != null)
      {
        indicatorWidget = Icon(icon, color: labelColor, size: 24,);
      }
      else if (label != null)
      {
        indicatorWidget = Text(label, style: Theme.of(context).textTheme.titleMedium!.apply(color: labelColor),);
      }
      arList.add(ButtonSegment<_AspectRatioPreset>(
        value: ar,
        label: indicatorWidget),
      );
    }
    return arList;
  }

  Row _getDimensionRow({required final List<_Dimension> dimensions, required final double padding})
  {
    final List<Widget> items = <Widget>[];
    bool isFirst = true;
    for (final _Dimension dimension in dimensions)
    {
      if (isFirst)
      {
        isFirst = false;
      }
      else
      {
        items.add(SizedBox(width: padding));
      }
      final String text = dimension.label ?? formatDimension(width: dimension.x, height: dimension.y);
      items.add(Expanded(child: OutlinedButton(onPressed: (){_setResolutionViaButton(width: dimension.x, height: dimension.y);}, child: Text(text))));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, mainAxisSize: MainAxisSize.min, children: items);
  }

  Row _getInputRow({
    required final String title,
    required final ValueNotifier<int> notifier,
    required final TextEditingController controller,
    required final FocusNode focusNode,
    required final Function({required int newVal}) changeFunc,
  })
  {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
        ),
        Expanded(
          flex: 4,
          child: ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (final BuildContext context, final int val, final Widget? child) {
              return KPixSlider(
                value: val.toDouble(),
                min: CanvasSizeConstraints.sizeMin.toDouble(),
                max: CanvasSizeConstraints.sizeMax.toDouble(),
                onChanged: (final double newVal) {changeFunc(newVal: newVal.toInt());},
                textStyle: Theme.of(context).textTheme.bodyLarge!,
              );
            },
          ),
        ),
        const SizedBox(
          width: OverlayEntryAlertDialogOptions.padding * 2,
        ),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (final BuildContext context, final int val, final Widget? child) {
              showTextInController(controller: controller, text: val.toString());
              return TextField(
                focusNode: focusNode,
                textAlign: TextAlign.end,
                controller: controller,
                onChanged: (final String newVal) {_sizeInputChanged(newVal: newVal, changeFunc: changeFunc);},
              );
            },
          ),
        ),
      ],
    );
  }

  void accept()
  {
    widget.accept(size: CoordinateSetI(x: _width.value, y: _height.value));
  }

  @override
  Widget build(final BuildContext context)
  {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return KPixAnimationWidget(
      constraints: const BoxConstraints(
        minHeight: OverlayEntryAlertDialogOptions.minHeight,
        minWidth: OverlayEntryAlertDialogOptions.minWidth,
        maxHeight: _maxHeight,
        maxWidth: OverlayEntryAlertDialogOptions.maxWidth * 1.2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(l10n.createNewProject, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding / 2),
          Divider(height: OverlayEntryAlertDialogOptions.padding / 4, thickness: OverlayEntryAlertDialogOptions.padding / 4, color: Theme.of(context).primaryColorLight,),
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding / 2),
          Text(l10n.presets, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding / 2),
          ValueListenableBuilder<_AspectRatioPreset>(
            valueListenable: _ar,
            builder: (final BuildContext context, final _AspectRatioPreset ar, final Widget? child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SegmentedButton<_AspectRatioPreset>(
                    segments: _getAspectRatioButtons(),
                    showSelectedIcon: false,
                    selected: <_AspectRatioPreset>{ar},
                    onSelectionChanged: (final Set<_AspectRatioPreset> selection)
                    {
                      _ar.value = selection.first;
                    },
                  ),
                  const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
                  _getDimensionRow(dimensions: ar.dimensions, padding: OverlayEntryAlertDialogOptions.padding)
                ],
              );
            },

          ),

          const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
          Divider(height: OverlayEntryAlertDialogOptions.padding / 4, thickness: OverlayEntryAlertDialogOptions.padding / 4, color: Theme.of(context).primaryColorLight,),
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: _maxPreviewHeight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _getInputRow(title: l10n.width, notifier: _width, controller: _textWidthController, focusNode: _hotkeyManager.getFocusNode(id: FocusNodeEntry.newProjectWidthTextFocus), changeFunc: _changeWidth),
                      _getInputRow(title: l10n.height, notifier: _height, controller: _textHeightController, focusNode: _hotkeyManager.getFocusNode(id: FocusNodeEntry.newProjectHeightTextFocus), changeFunc: _changeHeight),
                    ],
                  ),
                ),
              ),
              /*const SizedBox(width: OverlayEntryAlertDialogOptions.padding),
              ValueListenableBuilder<bool>(
                valueListenable: _locked,
                builder: (final BuildContext context, final bool locked, final Widget? child)
                {
                  return IconButton.outlined(
                    tooltip: l10n.lockAspectRatio,
                    constraints: const BoxConstraints(
                      minHeight: OverlayEntryAlertDialogOptions.iconSize * 2.5,
                      minWidth: OverlayEntryAlertDialogOptions.iconSize,
                      maxHeight: OverlayEntryAlertDialogOptions.iconSize * 2.5,
                      maxWidth: OverlayEntryAlertDialogOptions.iconSize,
                    ),
                    icon: Icon(
                      locked ? TablerIcons.lock : TablerIcons.lock_open_2,
                      size: OverlayEntryAlertDialogOptions.iconSize / 2,
                    ),
                    style: ButtonStyle(
                      tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: locked
                          ? WidgetStatePropertyAll<Color?>(
                        Theme.of(context)
                            .primaryColorLight,)
                          : null,
                      iconColor: locked
                          ? WidgetStatePropertyAll<Color?>(
                        Theme.of(context)
                            .primaryColor,)
                          : null,
                    ),
                    onPressed: () {
                      _locked.value = !_locked.value;
                      _setAspectRatio();
                    },
                  );
                },
              ),*/
              Expanded(
                child: Center(
                  child: ListenableBuilder(
                    listenable: Listenable.merge(<Listenable>[_width, _height]),
                    builder: (final BuildContext context, final Widget? child) {
                      final int width = _width.value;
                      final int height = _height.value;
                      final double scaledWidth = _maxPreviewWidth / width;
                      final double scaledHeight = _maxPreviewHeight / height;
                      final double scale = min(scaledWidth, scaledHeight);
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight,
                          border: Border.all(
                            color: Theme.of(context).primaryColorDark,
                            width: OverlayEntryAlertDialogOptions.borderWidth,
                          ),
                        ),
                        width: width * scale,
                        height: height * scale,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding / 2),
          Divider(height: OverlayEntryAlertDialogOptions.padding / 4, thickness: OverlayEntryAlertDialogOptions.padding / 4, color: Theme.of(context).primaryColorLight,),
          const SizedBox(height: OverlayEntryAlertDialogOptions.padding),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              if (widget.dismiss != null) ...<Widget>[
                DialogActionButton(tooltip: l10n.exitApplication, icon: TablerIcons.power, onPressed: widget.dismiss, padding: OverlayEntryAlertDialogOptions.padding / 2),
              ],
              DialogActionButton(tooltip: l10n.openProjectManager, icon: TablerIcons.folder_open, onPressed: widget.open, padding: OverlayEntryAlertDialogOptions.padding / 2),
              DialogActionButton(tooltip: l10n.createProject, icon: TablerIcons.check, onPressed: accept, padding: OverlayEntryAlertDialogOptions.padding / 2),
            ],
          ),
        ],
      ),
    );
  }
}
