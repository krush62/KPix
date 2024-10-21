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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/managers/preference_manager.dart';

class StatusBarWidgetOptions
{
  final double height;
  final double padding;
  final double dividerWidth;


  StatusBarWidgetOptions({
    required this.height,
    required this.padding,
    required this.dividerWidth,
  });
}

class StatusBarWidget extends StatefulWidget
{
  final ValueNotifier<String?> dimensionString;
  final ValueNotifier<String?> cursorPositionString;
  final ValueNotifier<String?> zoomFactorString;
  final ValueNotifier<String?> toolDimensionString;
  final ValueNotifier<String?> toolDiagonalString;
  final ValueNotifier<String?> toolAspectRatioString;
  final ValueNotifier<String?> toolAngleString;

  final double iconSize;

  final StatusBarWidgetOptions options;
  @override
  State<StatusBarWidget> createState() => _StatusBarWidgetState();

  const StatusBarWidget._({
    super.key,
    required this.options,
    required this.dimensionString,
    required this.cursorPositionString,
    required this.zoomFactorString,
    required this.toolAngleString,
    required this.toolAspectRatioString,
    required this.toolDiagonalString,
    required this.toolDimensionString,
    required this.iconSize});

  factory StatusBarWidget({
    Key? key,
  })
  {
    StatusBarWidgetOptions options = GetIt.I.get<PreferenceManager>().statusBarWidgetOptions;
    AppState appState = GetIt.I.get<AppState>();
    double fIconSize = options.height - 2 * options.padding;
    return StatusBarWidget._(
        key: key,
        options: options,
        dimensionString: appState.statusBarState.statusBarDimensionString,
        cursorPositionString: appState.statusBarState.statusBarCursorPositionString,
        zoomFactorString: appState.statusBarState.statusBarZoomFactorString,
        toolAngleString: appState.statusBarState.statusBarToolAngleString,
        toolAspectRatioString: appState.statusBarState.statusBarToolAspectRatioString,
        toolDiagonalString: appState.statusBarState.statusBarToolDiagonalString,
        toolDimensionString: appState.statusBarState.statusBarToolDimensionString,
        iconSize: fIconSize,);
  }
}

class _StatusBarWidgetState extends State<StatusBarWidget>
{
  void _zoomPressed()
  {
    GetIt.I.get<HotkeyManager>().triggerShortcut(action: HotkeyAction.panZoomOptimalZoom);
  }

  @override
  Widget build(final BuildContext context) {
    return Column(
      children: [
        Container(
          height: widget.options.padding,
          color: Theme.of(context).primaryColor
        ),
        ColoredBox(
          color: Theme.of(context).primaryColorDark,
          child: Padding(
            padding: EdgeInsets.all(widget.options.padding),
            child: LimitedBox(
              maxHeight: widget.options.height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    flex: 1,
                    child: _StatusBarWidgetEntry(
                      listenable: widget.dimensionString,
                      icon: FontAwesomeIcons.arrowsUpDownLeftRight,
                      iconSize: widget.iconSize,
                      padding: widget.options.padding,
                    )
                  ),
                  VerticalDivider(
                    width: widget.options.dividerWidth,
                    thickness: widget.options.dividerWidth,
                  ),
                  Expanded(
                    flex: 1,
                    child: _StatusBarWidgetEntry(
                      listenable: widget.cursorPositionString,
                      icon: FontAwesomeIcons.locationCrosshairs,
                      iconSize: widget.iconSize,
                      padding: widget.options.padding,
                    )
                  ),
                  VerticalDivider(
                    width: widget.options.dividerWidth,
                    thickness: widget.options.dividerWidth,
                  ),
                  Expanded(
                    flex: 1,
                    child: _StatusBarWidgetEntry(
                      listenable: widget.toolDimensionString,
                      icon: FontAwesomeIcons.rulerCombined,
                      iconSize: widget.iconSize,
                      padding: widget.options.padding,
                    )
                  ),
                  VerticalDivider(
                    width: widget.options.dividerWidth,
                    thickness: widget.options.dividerWidth,
                  ),
                  Expanded(
                    flex: 1,
                    child: _StatusBarWidgetEntry(
                      listenable: widget.toolDiagonalString,
                      icon: FontAwesomeIcons.slash,
                      iconSize: widget.iconSize,
                      padding: widget.options.padding,
                    )
                  ),
                  VerticalDivider(
                    width: widget.options.dividerWidth,
                    thickness: widget.options.dividerWidth,
                  ),
                  Expanded(
                    flex: 1,
                    child: _StatusBarWidgetEntry(
                      listenable: widget.toolAspectRatioString,
                      icon: FontAwesomeIcons.percent,
                      iconSize: widget.iconSize,
                      padding: widget.options.padding,
                    )
                  ),
                  VerticalDivider(
                    width: widget.options.dividerWidth,
                    thickness: widget.options.dividerWidth,
                  ),
                  Expanded(
                    flex: 1,
                    child: _StatusBarWidgetEntry(
                      listenable: widget.toolAngleString,
                      icon: FontAwesomeIcons.lessThan,
                      iconSize: widget.iconSize,
                      padding: widget.options.padding,
                    )
                  ),
                  VerticalDivider(
                    width: widget.options.dividerWidth,
                    thickness: widget.options.dividerWidth,
                  ),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: _zoomPressed,
                      child: _StatusBarWidgetEntry(
                        listenable: widget.zoomFactorString,
                        icon: FontAwesomeIcons.magnifyingGlass,
                        iconSize: widget.iconSize,
                        padding: widget.options.padding,
                      ),
                    )
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBarWidgetEntry extends StatefulWidget
{
  final ValueListenable<String?> listenable;
  final IconData icon;
  final double iconSize;
  final double padding;
  const _StatusBarWidgetEntry({
    required this.listenable,
    required this.icon,
    required this.iconSize,
    required this.padding,
  });

  @override
  State<_StatusBarWidgetEntry> createState() => _StatusBarWidgetEntryState();
}

class _StatusBarWidgetEntryState extends State<_StatusBarWidgetEntry>
{
  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: widget.padding, right: widget.padding, bottom: widget.padding),
      child: ValueListenableBuilder<String?>(
        valueListenable: widget.listenable,
        builder: (final BuildContext context, final String? value, final Widget? child){
            return Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: widget.padding, top: widget.padding),
                  child: Visibility(
                    visible: value != null,
                    child: FaIcon(
                      widget.icon,
                      size: widget.iconSize,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: widget.padding),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      value ?? "",
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).primaryColor),
                    ),
                  ),
                )
              ]
            );
          }
        )
    );
  }
}