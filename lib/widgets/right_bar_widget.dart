import 'package:flutter/material.dart';
import 'package:kpix/widgets/main_button_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';

class RightBarWidget extends StatefulWidget
{
  final MainButtonWidgetOptions mainButtonWidgetOptions;
  final OverlayEntrySubMenuOptions overlayEntrySubMenuOptions;
  const RightBarWidget({
    super.key,
    required this.overlayEntrySubMenuOptions,
    required this.mainButtonWidgetOptions
  });

  @override
  State<RightBarWidget> createState() => _RightBarWidgetState();

}

class _RightBarWidgetState extends State<RightBarWidget>
{
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,

      child: Column(
        children: [
          MainButtonWidget(
            options: widget.mainButtonWidgetOptions,
            overlayEntrySubMenuOptions: widget.overlayEntrySubMenuOptions,
          ),
          Expanded(child: Container(color: Theme.of(context).primaryColorDark))
        ],
      )
    );
  }

}