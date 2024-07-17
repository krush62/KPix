import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/managers/preference_manager.dart';
import 'package:kpix/util/helper.dart';
import 'package:kpix/util/typedefs.dart';
import 'package:kpix/widgets/overlay_entries.dart';


enum ExportTypeEnum
{
  png,
  aseprite,
  photoshop,
  gimp
}

const List<int> exportScalingValues = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

class ExportData
{
  final String name;
  final String extension;
  final int scaling;
  final bool scalable;
  const ExportData({required this.name, required this.extension, required this.scalable, this.scaling = 1});
  factory ExportData.fromWithScaling({required ExportData other, required int scaling})
  {
    return ExportData(name: other.name, extension: other.extension, scalable: other.scalable, scaling: scaling);
  }
}

const Map<ExportTypeEnum, ExportData> exportTypeMap = {
  ExportTypeEnum.png : ExportData(name: "PNG", extension: "png", scalable: true),
  ExportTypeEnum.aseprite : ExportData(name: "ASEPRITE", extension: "aseprite", scalable: false),
  ExportTypeEnum.photoshop : ExportData(name: "PHOTOSHOP", extension: "psd", scalable: false),
  ExportTypeEnum.gimp : ExportData(name: "GIMP", extension: "xcf", scalable: false)
};




class ExportWidget extends StatefulWidget
{
  final Function() dismiss;
  final ExportDataFn accept;
  final CoordinateSetI canvasSize;

  const ExportWidget({
    super.key,
    required this.dismiss,
    required this.accept,
    required this.canvasSize
  });



  @override
  State<ExportWidget> createState() => _ExportWidgetState();
}

class _ExportWidgetState extends State<ExportWidget>
{
  final OverlayEntryAlertDialogOptions options = GetIt.I.get<PreferenceManager>().alertDialogOptions;
  final ValueNotifier<ExportTypeEnum> exportType = ValueNotifier(ExportTypeEnum.png);
  final ValueNotifier<int> scalingIndex = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    return Material(
        elevation: options.elevation,
        shadowColor: Theme.of(context).primaryColorDark,
        borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
        child: Container(
            constraints: BoxConstraints(
              minHeight: options.minHeight,
              minWidth: options.minWidth,
              maxHeight: options.maxHeight,
              maxWidth: options.maxWidth,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              border: Border.all(
                color: Theme.of(context).primaryColorLight,
                width: options.borderWidth,
              ),
              borderRadius: BorderRadius.all(Radius.circular(options.borderRadius)),
            ),
            child: Padding(
              padding: EdgeInsets.all(options.padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("EXPORT PROJECT", style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: options.padding),
                  Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                            flex: 1,
                            child: Text("Format", style: Theme.of(context).textTheme.titleMedium)
                        ),
                        Expanded(
                          flex: 6,
                          child: ValueListenableBuilder<ExportTypeEnum>(
                            valueListenable: exportType,
                            builder: (final BuildContext context, final ExportTypeEnum exportTypeEnum, final Widget? child) {
                              return SegmentedButton<ExportTypeEnum>(
                                selected: <ExportTypeEnum>{exportTypeEnum},
                                multiSelectionEnabled: false,
                                showSelectedIcon: false,
                                onSelectionChanged: (final Set<ExportTypeEnum> types) {exportType.value = types.first;},
                                segments: [
                                  ButtonSegment(
                                      value: ExportTypeEnum.png,
                                      label: Text(exportTypeMap[ExportTypeEnum.png]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == ExportTypeEnum.png ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight))
                                  ),
                                  ButtonSegment(
                                      value: ExportTypeEnum.aseprite,
                                      label: Text(exportTypeMap[ExportTypeEnum.aseprite]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == ExportTypeEnum.aseprite ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight))
                                  ),
                                  ButtonSegment(
                                      value: ExportTypeEnum.photoshop,
                                      label: Text(exportTypeMap[ExportTypeEnum.photoshop]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == ExportTypeEnum.photoshop ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight))
                                  ),
                                  ButtonSegment(
                                      value: ExportTypeEnum.gimp,
                                      label: Text(exportTypeMap[ExportTypeEnum.gimp]!.name, style: Theme.of(context).textTheme.bodyMedium!.apply(color: exportTypeEnum == ExportTypeEnum.gimp ? Theme.of(context).primaryColorDark : Theme.of(context).primaryColorLight))
                                  ),
                                ],
                              );
                            },
                          )
                        ),
                      ]
                  ),
                  Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text("Scaling", style: Theme.of(context).textTheme.titleMedium)
                        ),
                        Expanded(
                          flex: 4,
                          child: ValueListenableBuilder<ExportTypeEnum>(
                            valueListenable: exportType,
                            builder: (final BuildContext context1, final ExportTypeEnum type, final Widget? child1) {
                              return ValueListenableBuilder<int>(
                                valueListenable: scalingIndex,
                                builder: (final BuildContext context2, final int scalingIndexVal, final Widget? child2) {
                                  return Slider(
                                    value: exportTypeMap[type]!.scalable ? scalingIndexVal.toDouble() : 0,
                                    min: 0,
                                    max: exportScalingValues.length.toDouble() - 1,
                                    divisions: exportScalingValues.length,
                                    label: exportScalingValues[scalingIndexVal].toString(),
                                    onChanged: exportTypeMap[type]!.scalable ? (final double newVal){scalingIndex.value = newVal.round();} : null,
                                  );
                                },
                              );
                            },
                          )
                        ),
                        Expanded(
                          flex: 2,
                          child: ValueListenableBuilder<ExportTypeEnum>(
                            valueListenable: exportType,
                            builder: (final BuildContext context1, final ExportTypeEnum type, final Widget? child) {
                              return ValueListenableBuilder<int>(
                                valueListenable: scalingIndex,
                                builder: (final BuildContext context2, final int scalingIndexVal, final Widget? child2) {
                                  return Text( exportTypeMap[type]!.scalable ?
                                      "${widget.canvasSize.x *  exportScalingValues[scalingIndexVal]} x ${widget.canvasSize.y *  exportScalingValues[scalingIndexVal]}" : "${widget.canvasSize.x} x ${widget.canvasSize.y}",
                                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium
                                  );
                                },
                              );
                            },

                          )
                        ),
                      ]
                  ),

                  Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                            flex: 1,
                            child: Padding(
                              padding: EdgeInsets.all(options.padding),
                              child: IconButton.outlined(
                                icon: FaIcon(
                                  FontAwesomeIcons.xmark,
                                  size: options.iconSize,
                                ),
                                onPressed: () {
                                  widget.dismiss();
                                },
                              ),
                            )
                        ),
                        Expanded(
                            flex: 1,
                            child: Padding(
                              padding: EdgeInsets.all(options.padding),
                              child: IconButton.outlined(
                                icon: FaIcon(
                                  FontAwesomeIcons.check,
                                  size: options.iconSize,
                                ),
                                onPressed: () {
                                  widget.accept(ExportData.fromWithScaling(other: exportTypeMap[exportType.value]!, scaling: exportScalingValues[scalingIndex.value]), exportType.value);
                                },
                              ),
                            )
                        ),
                      ]
                  ),
                ],
              ),
            )
        )
    );
  }

}