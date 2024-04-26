import 'package:flutter/material.dart';

class PaletteWidget extends StatefulWidget
{
  const PaletteWidget({super.key});

  @override
  State<PaletteWidget> createState() => _PaletteWidgetState();
  
}

class _PaletteWidgetState extends State<PaletteWidget>
{
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .secondaryHeaderColor,
            ),
          child:  const Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: IconButton(
                  icon:  Icon(
                    Icons.open_in_browser_outlined,
                    size: 36,
                  ),
                  onPressed: null,
                )
              ),
              Expanded(
                  flex: 1,
                  child: IconButton(
                    icon:  Icon(
                      Icons.save_alt,
                      size: 36,
                    ),
                    onPressed: null,
                  )
              ),
              Expanded(
                  flex: 1,
                  child: IconButton(
                    icon:  Icon(
                      Icons.lock,
                      size: 36,
                    ),
                    onPressed: null,
                  )
              ),
            ],
          )
        )
      ],
    );
  }
  
}