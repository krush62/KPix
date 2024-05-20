import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:kpix/color_names.dart';
import 'package:kpix/helper.dart';
import 'package:kpix/kpal/kpal_widget.dart';
import 'package:kpix/models.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/typedefs.dart';
import 'package:kpix/widgets/color_entry_widget.dart';
import 'package:kpix/widgets/overlay_entries.dart';
import 'package:kpix/widgets/color_chooser_widget.dart';
import 'package:kpix/widgets/palette_widget.dart';
import 'package:kpix/widgets/tool_settings_widget.dart';
import 'package:kpix/widgets/tools_widget.dart';
import 'package:kpix/widgets/shader_widget.dart';
import 'package:kpix/shader_options.dart';

class MainToolbarWidgetOptions {
  final int paletteFlex;
  final int toolSettingsFlex;
  final double dividerHeight;
  final double dividerPadding;

  const MainToolbarWidgetOptions({
    required this.paletteFlex,
    required this.dividerPadding,
    required this.toolSettingsFlex,
    required this.dividerHeight});
}


class MainToolbarWidget extends StatelessWidget
{
  final AppState appState;
  final PaletteWidgetOptions paletteWidgetOptions;
  final ToolsWidgetOptions toolsWidgetOptions;
  final ToolSettingsWidgetOptions toolSettingsWidgetOptions;
  final ToolOptions toolOptions;
  final MainToolbarWidgetOptions mainToolbarWidgetOptions;
  final ShaderWidgetOptions shaderWidgetOptions;
  final ShaderOptions shaderOptions;
  final OverlayEntrySubMenuOptions overlayEntryOptions;
  final ColorChooserWidgetOptions colorChooserWidgetOptions;
  final ColorNames colorNames;
  final OverlayEntryAlertDialogOptions alertDialogOptions;
  final KPalConstraints kPalConstraints;
  final KPalWidgetOptions kPalWidgetOptions;
  final ColorEntryWidgetOptions colorEntryWidgetOptions;
  final ColorSelectedFn colorSelectedFn;
  final ColorRampFn updateRampFn;
  final ColorRampFn deleteRampFn;
  final AddNewRampFn addNewRampFn;


  const MainToolbarWidget({
    required this.appState,
    required this.paletteWidgetOptions,
    required this.toolsWidgetOptions,
    required this.toolSettingsWidgetOptions,
    required this.toolOptions,
    required this.mainToolbarWidgetOptions,
    required this.shaderWidgetOptions,
    required this.shaderOptions,
    required this.overlayEntryOptions,
    required this.colorChooserWidgetOptions,
    required this.colorNames,
    required this.alertDialogOptions,
    required this.kPalConstraints,
    required this.kPalWidgetOptions,
    required this.colorEntryWidgetOptions,
    required this.addNewRampFn,
    required this.updateRampFn,
    required this.deleteRampFn,
    required this.colorSelectedFn,
    super.key
});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,
      child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ValueListenableBuilder<ToolType>(
                valueListenable: appState.selectedTool,
                builder: (BuildContext context, ToolType value, child) {
                  return PaletteWidget(
                    paletteOptions: paletteWidgetOptions,
                    appState: appState,
                    overlayEntryOptions: overlayEntryOptions,
                    colorChooserWidgetOptions: colorChooserWidgetOptions,
                    colorNames: colorNames,
                    alertDialogOptions: alertDialogOptions,
                    kPalConstraints: kPalConstraints,
                    kPalWidgetOptions: kPalWidgetOptions,
                    colorEntryWidgetOptions: colorEntryWidgetOptions,
                    colorSelectedFn: colorSelectedFn,
                    addNewRampFn: addNewRampFn,
                    deleteRampFn: deleteRampFn,
                    updateRampFn: updateRampFn,
                  );
                }
              ),
            ),
            Divider(
              color: Theme.of(context).primaryColorDark,
              endIndent: mainToolbarWidgetOptions.dividerPadding,
              indent: mainToolbarWidgetOptions.dividerPadding,
              thickness: mainToolbarWidgetOptions.dividerHeight,
              height: mainToolbarWidgetOptions.dividerHeight,
            ),
            ShaderWidget(
            titleStyle: Theme.of(context).textTheme.titleLarge,
            labelStyle: Theme.of(context).textTheme.bodySmall,
            shaderWidgetOptions: shaderWidgetOptions,
            shaderOptions: shaderOptions),
            Divider(
              color: Theme.of(context).primaryColorDark,
              endIndent: mainToolbarWidgetOptions.dividerPadding,
              indent: mainToolbarWidgetOptions.dividerPadding,
              thickness: mainToolbarWidgetOptions.dividerHeight,
              height: mainToolbarWidgetOptions.dividerHeight,
            ),
            ValueListenableBuilder<ToolType>(
              valueListenable: appState.selectedTool,
              builder: (BuildContext context, ToolType value,
                  child) {
                return ToolsWidget(
                  options: toolsWidgetOptions,
                  changeToolFn: appState.changeTool,
                  appState: appState,
                );
                //return ColorEntryWidget();
              }
            ),
            Divider(
              color: Theme.of(context).primaryColorDark,
              endIndent: mainToolbarWidgetOptions.dividerPadding,
              indent: mainToolbarWidgetOptions.dividerPadding,
              thickness: mainToolbarWidgetOptions.dividerHeight,
              height: mainToolbarWidgetOptions.dividerHeight,
            ),
            SizedBox(
              width: double.infinity,
              //TODO MAGIC NUMBER
              height: 200,
              child: ValueListenableBuilder<ToolType>(
                valueListenable: appState.selectedTool,
                builder: (BuildContext context, ToolType value,child) {
                  return ToolSettingsWidget(
                    appState: appState,
                    toolSettingsWidgetOptions: toolSettingsWidgetOptions,
                    toolOptions: toolOptions,
                  );
                }
                           ),
            ),




            //PALETTE WIDGET
            /*Expanded(
              flex: mainToolbarWidgetOptions.paletteFlex,
              child: ValueListenableBuilder<ToolType>(
                  valueListenable: appState.selectedTool,
                  builder: (BuildContext context, ToolType value,
                      child) {
                    return PaletteWidget(
                      paletteOptions: paletteWidgetOptions,
                      appState: appState,
                      overlayEntryOptions: overlayEntryOptions,
                      colorChooserWidgetOptions: colorChooserWidgetOptions,
                      colorNames: colorNames,
                      alertDialogOptions: alertDialogOptions,
                      kPalConstraints: kPalConstraints,
                      kPalWidgetOptions: kPalWidgetOptions,
                      colorEntryWidgetOptions: colorEntryWidgetOptions,
                      colorSelectedFn: colorSelectedFn,
                      addNewRampFn: addNewRampFn,
                      deleteRampFn: deleteRampFn,
                      updateRampFn: updateRampFn,
                    );
                  }),
            ),
            Divider(
              color: Theme.of(context).primaryColorDark,
              endIndent: mainToolbarWidgetOptions.dividerPadding,
              indent: mainToolbarWidgetOptions.dividerPadding,
              thickness: mainToolbarWidgetOptions.dividerHeight,
              height: mainToolbarWidgetOptions.dividerHeight,
            ),

            Material(
              color: Theme.of(context).primaryColor,
                child: ShaderWidget(
                  titleStyle: Theme.of(context).textTheme.titleLarge,
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                  shaderWidgetOptions: shaderWidgetOptions,
                  shaderOptions: shaderOptions),
              ),
            Divider(
              color: Theme.of(context).primaryColorDark,
              endIndent: mainToolbarWidgetOptions.dividerPadding,
              indent: mainToolbarWidgetOptions.dividerPadding,
              thickness: mainToolbarWidgetOptions.dividerHeight,
              height: mainToolbarWidgetOptions.dividerHeight,
            ),
            //TOOLS WIDGET
            ValueListenableBuilder<ToolType>(
                valueListenable: appState.selectedTool,
                builder: (BuildContext context, ToolType value,
                    child) {
                  return ToolsWidget(
                    options: toolsWidgetOptions,
                    changeToolFn: appState.changeTool,
                    appState: appState,
                  );
                  //return ColorEntryWidget();
                }),
            Divider(
              color: Theme.of(context).primaryColorDark,
              endIndent: mainToolbarWidgetOptions.dividerPadding,
              indent: mainToolbarWidgetOptions.dividerPadding,
              thickness: mainToolbarWidgetOptions.dividerHeight,
              height: mainToolbarWidgetOptions.dividerHeight,
            ),

            //TOOL OPTIONS
            Expanded(
                flex: mainToolbarWidgetOptions.toolSettingsFlex,
                child: ValueListenableBuilder<ToolType>(
                    valueListenable: appState.selectedTool,
                    builder: (BuildContext context, ToolType value,
                        child) {
                      return ToolSettingsWidget(appState: appState, toolSettingsWidgetOptions: toolSettingsWidgetOptions, toolOptions: toolOptions,);
                    }
                )
            )*/
          ]
      ),
    );
  }

}