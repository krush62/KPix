import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class CreditEntry
{
  String content;
  TextStyle style;
  CreditEntry({required this.content, required this.style});
}



class CreditsWidget extends StatefulWidget
{
  const CreditsWidget({super.key}); 

  @override
  State<CreditsWidget> createState() => CreditsWidgetState();

}

class CreditsWidgetState extends State<CreditsWidget>
{
  final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<List<CreditEntry>> _creditEntries = ValueNotifier([]);

  @override
  void initState()
  {
    super.initState();
    createCreditEntries(
      headerLarge: Theme.of(context).textTheme.headlineLarge!,
      headerMedium: Theme.of(context).textTheme.headlineMedium!,
      headerSmall: Theme.of(context).textTheme.headlineSmall!,
      textNormal: Theme.of(context).textTheme.bodyMedium!
    ).then(setCreditEntries);
  }

  void setCreditEntries(final List<CreditEntry> entries)
  {
    _creditEntries.value = entries;
  }


  Future<List<CreditEntry>> createCreditEntries({required final TextStyle headerLarge, required final TextStyle headerMedium, required final TextStyle headerSmall, required final TextStyle textNormal}) async
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
  Widget build(BuildContext context)
  {
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
        child: ValueListenableBuilder<List<CreditEntry>>(
          valueListenable: _creditEntries,
          builder: (final BuildContext context1, final List<CreditEntry> entryList, final Widget? child) {
            return ListView.builder(
              itemCount: entryList.length,
              itemBuilder: (final BuildContext context2, final int index)
              {
                return Text(entryList[index].content, style: entryList[index].style);
              },
            );
          },
        )
      )
    );
  }
  
}