import 'package:flutter/material.dart';
import 'package:kpix/oss_licenses.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class LicensesWidget extends StatelessWidget
{
  final List<Package> _licenses = allDependencies;
  final OverlayEntryAlertDialogOptions options;
  const LicensesWidget({super.key, required this.options});


  @override
  Widget build(BuildContext context)
  {
    return Material(
      elevation: options.elevation,
      shadowColor: Theme.of(context).primaryColorDark,
      borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
      child: Container(
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
      child: ListView.separated(
        itemCount: _licenses.length,
        padding: EdgeInsets.all(options.padding),

        itemBuilder: (final BuildContext context, final int index) {
          return ListTile(

            isThreeLine: true,
            title: Text(_licenses[index].description, style: Theme.of(context).textTheme.titleMedium),
            leading: Text(_licenses[index].name, style: Theme.of(context).textTheme.headlineMedium),
            subtitle: Text(_licenses[index].license!, style: Theme.of(context).textTheme.bodySmall),
            trailing: Text(_licenses[index].version, style: Theme.of(context).textTheme.headlineMedium),
          );
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),
    )
  );
  }
}