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
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

class CreditsWidget extends StatefulWidget
{
  final Function() onDismiss;
  const CreditsWidget({super.key, required this.onDismiss});
  @override
  State<CreditsWidget> createState() => _CreditsWidgetState();
}

class _CreditsWidgetState extends State<CreditsWidget>
{
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<String> _creditsContent = ValueNotifier<String>("");


  @override
  void initState()
  {
    super.initState();
    _loadCreditsContent().then((final String content) {
      _creditsContent.value = content;
    });
  }

  Future<String> _loadCreditsContent() async
  {
    return await rootBundle.loadString(PreferenceManager.ASSET_CREDITS);
  }

  void _dismissPressed()
  {
    widget.onDismiss();
  }

  @override
  Widget build(final BuildContext context)
  {
    return KPixAnimationWidget(
      constraints: BoxConstraints(
        minHeight: _options.minHeight,
        minWidth: _options.minWidth,
        maxHeight: _options.maxHeight * 2,
        maxWidth: _options.maxWidth * 2,
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _creditsContent,
              builder: (final BuildContext context1, final String content, final Widget? child) {
                return Markdown(data: content);
              },
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Tooltip(
                  message: "Close",
                  waitDuration: AppState.toolTipDuration,
                  child: IconButton.outlined(
                    icon: const Icon(
                      TablerIcons.x,
                      //size: _options.iconSize,
                    ),
                    onPressed: _dismissPressed,
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
