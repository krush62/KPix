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
{final ValueNotifier<IdColor> colorNotifier;
  final bool isLast;

  const KPalColorCardWidget({
    super.key,
    required this.colorNotifier,
    this.isLast = false,
  });

  @override
  State<KPalColorCardWidget> createState() => _KPalColorCardWidgetState();


}

class _KPalColorCardWidgetState extends State<KPalColorCardWidget>
{
  final KPalColorCardWidgetOptions options = GetIt.I.get<PreferenceManager>().kPalWidgetOptions.rampOptions.colorCardWidgetOptions;
  final ColorNames colorNames = GetIt.I.get<PreferenceManager>().colorNames;


  @override
  Widget build(BuildContext context) {
   return Expanded(
       child: Padding(
         //padding: EdgeInsets.all(widget.options.outsidePadding),
         padding: EdgeInsets.only(
           left: options.outsidePadding,
           right: widget.isLast ? options.outsidePadding : 0.0,
           top: options.outsidePadding,
           bottom: options.outsidePadding,
         ),
         child: Container(
           decoration: BoxDecoration(
             color: Theme.of(context).primaryColor,
             borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
             border: Border.all(
               width: options.borderWidth,
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
                       flex: options.colorNameFlex,
                       child: Center(
                         child: Text(
                           colorNames.getColorName(currentColor.color.red, currentColor.color.green, currentColor.color.blue)
                         ),
                       )
                   ),
                   Divider(
                     color: Theme.of(context).primaryColorLight,
                     thickness: options.borderWidth,
                     height: options.borderWidth,
                   ),
                   Expanded(
                       flex: options.colorFlex,
                       child: Container(color: currentColor.color)
                   ),
                   Divider(
                     color: Theme.of(context).primaryColorLight,
                     thickness: options.borderWidth,
                     height: options.borderWidth,
                   ),
                   Expanded(
                       flex: options.colorNumbersFlex,
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