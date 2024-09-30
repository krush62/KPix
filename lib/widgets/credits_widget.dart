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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/models/app_state.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class CreditEntry
{
  String _content = "";
  TextStyle style;
  CreditEntry({required final String content, required this.style, final removeTrailingBackslash = true})
  {
    if (content.endsWith("\\\r") && removeTrailingBackslash)
    {
      _content = content.replaceAll("\\\r", "\r");
    }
    else
    {
      _content = content;
    }
  }
}

class CreditsWidget extends StatefulWidget
{
  final Function() onDismiss;
  const CreditsWidget({super.key, required this.onDismiss});
  @override
  State<CreditsWidget> createState() => _CreditsWidgetState();
}

class _CreditsWidgetState extends State<CreditsWidget>
{
  final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<List<CreditEntry>> _creditEntries = ValueNotifier([]);

  @override
  void initState()
  {
    super.initState();
  }

  void _setCreditEntries({required final List<CreditEntry> entries})
  {
    _creditEntries.value = entries;
  }

  Future<List<CreditEntry>> _createCreditEntries({required final TextStyle headerLarge, required final TextStyle headerMedium, required final TextStyle headerSmall, required final TextStyle textNormal}) async
  {
    final List<CreditEntry> entries = [];
    final String credContent = await rootBundle.loadString("docs/credits.md");
    final List<String> lines = credContent.split('\n');
    for (final String line in lines)
    {
      if (line.startsWith("# "))
      {
        entries.add(CreditEntry(content: line.substring(2), style: headerLarge));
      }
      else if (line.startsWith("## "))
      {
        entries.add(CreditEntry(content: line.substring(3), style: headerMedium));
      }
      else if (line.startsWith("### "))
      {
        entries.add(CreditEntry(content: line.substring(4), style: headerSmall));
      }
      else
      {
        entries.add(CreditEntry(content: line, style: textNormal));
      }
    }

    return entries;
  }


  @override
  Widget build(final BuildContext context)
  {
    if (_creditEntries.value.isEmpty)
    {
      _createCreditEntries(
        headerLarge: Theme.of(context).textTheme.headlineLarge!,
        headerMedium: Theme.of(context).textTheme.headlineMedium!,
        headerSmall: Theme.of(context).textTheme.headlineSmall!,
        textNormal: Theme.of(context).textTheme.bodyMedium!
      ).then((final List<CreditEntry> entries){_setCreditEntries(entries: entries);});
    }
    return Material(      
      elevation: options.elevation,
      shadowColor: Theme.of(context).primaryColorDark,
      borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
      child: Container(
        padding: EdgeInsets.all(options.padding * 2),
        constraints: BoxConstraints(
          minHeight: options.minHeight,
          minWidth: options.minWidth,
          maxHeight: options.maxHeight * 2,
          maxWidth: options.maxWidth * 2,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          border: Border.all(
            color: Theme.of(context).primaryColorLight,
            width: options.borderWidth,
          ),
          borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<List<CreditEntry>>(
                valueListenable: _creditEntries,
                builder: (final BuildContext context1, final List<CreditEntry> entryList, final Widget? child) {
                  return ListView.builder(
                    itemCount: entryList.length,
                    itemBuilder: (final BuildContext context2, final int index)
                    {
                      return Text(entryList[index]._content, style: entryList[index].style);
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: "Close",
                    waitDuration: AppState.toolTipDuration,
                    child: IconButton.outlined(
                      icon: FaIcon(
                        FontAwesomeIcons.xmark,
                        size: options.iconSize,
                      ),
                      onPressed: widget.onDismiss,
                    ),
                  ),
                ),
              ],
            )
          ],
        )
      )
    );
  }
}