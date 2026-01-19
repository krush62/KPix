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
import 'package:kpix/managers/hotkey_manager.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/controls/kpix_animation_widget.dart';
import 'package:kpix/widgets/overlays/overlay_entries.dart';

class ChangeTextToolWidget extends StatefulWidget
{
  final Function() dismiss;
  final ChangeTextToolFn accept;
  final String? initialText;
  final int? maxStringLength;
  const ChangeTextToolWidget({super.key, required this.accept, required this.dismiss, this.initialText = "", this.maxStringLength = 32});

  @override
  State<ChangeTextToolWidget> createState() => _ChangeTextToolWidgetState();
}

class _ChangeTextToolWidgetState extends State<ChangeTextToolWidget>
{
  final HotkeyManager _hotkeyManager = GetIt.I.get<HotkeyManager>();
  final OverlayEntryAlertDialogOptions _options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<String> _text = ValueNotifier<String>("");


  @override
  void initState()
  {
    super.initState();
    _text.value = widget.initialText ?? "";
    _hotkeyManager.changeTextToolFocus.requestFocus();
  }


  @override
  Widget build(final BuildContext context)
  {
    return KPixAnimationWidget(
      constraints: BoxConstraints(
        minHeight: _options.minHeight,
        minWidth: _options.minWidth,
        maxHeight: _options.maxHeight,
        maxWidth: _options.maxWidth,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text("TEXT TOOL CONTENT", style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: _options.padding),
          Padding(
            padding:  EdgeInsets.all(_options.padding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: Text("Text", style: Theme.of(context).textTheme.titleMedium),
                ),
                Expanded(
                  flex: 3,
                  child: ValueListenableBuilder<String?>(
                    valueListenable: _text,
                    builder: (final BuildContext context, final String? text, final Widget? child) {
                      final TextEditingController controller = TextEditingController(text: text);
                      controller.selection = TextSelection.collapsed(offset: controller.text.length);
                      return TextField(
                        style: Theme.of(context).textTheme.titleLarge,
                        focusNode: _hotkeyManager.changeTextToolFocus,
                        controller: controller,
                        maxLength: widget.maxStringLength,
                        onChanged: (final String value) {
                          _text.value = value;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(_options.padding),
                    child: IconButton.outlined(
                      icon: const Icon(
                        TablerIcons.x,
                      ),
                      onPressed: () {
                        widget.dismiss();
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(_options.padding),
                    child: ValueListenableBuilder<String>(
                      valueListenable: _text,
                      builder: (final BuildContext context, final String text, final Widget? child) {
                        return IconButton.outlined(
                          icon: const Icon(
                            TablerIcons.check,
                          ),
                          onPressed: text.trim() != "" ?
                              () {
                            widget.accept(newText: _text.value);
                          } : null,
                        );
                      },
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
