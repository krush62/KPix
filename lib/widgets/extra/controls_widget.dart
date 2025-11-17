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

class ControlsWidget extends StatefulWidget {
  final Function() onDismiss;
  const ControlsWidget({super.key, required this.onDismiss});
  @override
  State<ControlsWidget> createState() => _ControlsWidgetState();
}

class _ControlsWidgetState extends State<ControlsWidget>
{
  final ValueNotifier<String> _controlsContent = ValueNotifier<String>("");

  @override
  void initState()
  {
    super.initState();
    _loadControlsContent().then((final String content) {
      _controlsContent.value = content;
    });
  }

  Future<String> _loadControlsContent() async
  {
    return await rootBundle.loadString("docs/controls.md");
  }

  @override
  void dispose()
  {
    _controlsContent.dispose();
    super.dispose();
  }


  @override
  Widget build(final BuildContext context) {
    final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
    return KPixAnimationWidget(
      constraints: BoxConstraints(
        minHeight: options.minHeight,
        minWidth: options.minWidth,
        maxHeight: options.maxHeight * 2,
        maxWidth: options.maxWidth * 2,
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _controlsContent,
              builder: (final BuildContext context, final String content, final Widget? child) {
                return Markdown(data: content);
              },
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(options.padding),
                  child: Tooltip(
                    message: "Close",
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      icon: const Icon(
                        TablerIcons.x,
                      ),
                      onPressed: widget.onDismiss,
                    ),
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
