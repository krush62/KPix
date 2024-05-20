part of 'kpal_widget.dart';


class KPalColorCardWidgetOptions
{
  final double borderRadius;
  final double borderWidth;
  final double outsidePadding;
  final int colorNameFlex;
  final int colorFlex;
  final int colorNumbersFlex;

  KPalColorCardWidgetOptions({
    required this.borderRadius,
    required this.borderWidth,
    required this.outsidePadding,
    required this.colorFlex,
    required this.colorNameFlex,
    required this.colorNumbersFlex,
  });
}



class KPalColorCardWidget extends StatefulWidget
{
  final KPalColorCardWidgetOptions options;
  final ColorNames colorNames;
  final ValueNotifier<IdColor> colorNotifier;
  final bool isLast;

  const KPalColorCardWidget({
    super.key,
    required this.options,
    required this.colorNames,
    required this.colorNotifier,
    this.isLast = false,
  });

  @override
  State<KPalColorCardWidget> createState() => _KPalColorCardWidgetState();


}

class _KPalColorCardWidgetState extends State<KPalColorCardWidget>
{
  @override
  Widget build(BuildContext context) {
   return Expanded(
       child: Padding(
         //padding: EdgeInsets.all(widget.options.outsidePadding),
         padding: EdgeInsets.only(
           left: widget.options.outsidePadding,
           right: widget.isLast ? widget.options.outsidePadding : 0.0,
           top: widget.options.outsidePadding,
           bottom: widget.options.outsidePadding,
         ),
         child: Container(
           decoration: BoxDecoration(
             color: Theme.of(context).primaryColor,
             borderRadius: BorderRadius.all(Radius.circular(widget.options.borderRadius)),
             border: Border.all(
               width: widget.options.borderWidth,
               color: Theme.of(context).primaryColorLight,
             )
           ),

           child: ValueListenableBuilder<IdColor>(
             valueListenable: widget.colorNotifier,
             builder: (BuildContext context, IdColor currentColor, child)
             {
               return Column(
                 children: [
                   Expanded(
                       flex: widget.options.colorNameFlex,
                       child: Center(
                         child: Text(
                           widget.colorNames.getColorName(currentColor.color.red, currentColor.color.green, currentColor.color.blue)
                         ),
                       )
                   ),
                   Divider(
                     color: Theme.of(context).primaryColorLight,
                     thickness: widget.options.borderWidth,
                     height: widget.options.borderWidth,
                   ),
                   Expanded(
                       flex: widget.options.colorFlex,
                       child: Container(color: currentColor.color)
                   ),
                   Divider(
                     color: Theme.of(context).primaryColorLight,
                     thickness: widget.options.borderWidth,
                     height: widget.options.borderWidth,
                   ),
                   Expanded(
                       flex: widget.options.colorNumbersFlex,
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                         crossAxisAlignment: CrossAxisAlignment.center,
                         mainAxisSize: MainAxisSize.max,
                         children: [
                           Text(
                             Helper.colorToHSVString(currentColor.color)
                           ),
                         ]
                       )
                   )
                 ],
               );
             },
           )









         ),
       )
   );
  }

}