import 'dart:collection';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
// ignore: implementation_imports
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/stylus_bridge.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_settings.dart';
import 'package:kpix/layer_states/drawing_layer/drawing_layer_state.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/models/color_types.dart';
import 'package:kpix/models/constraints/kpal_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/export_shader.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/models/io_types.dart';
import 'package:kpix/models/palette_state.dart';
import 'package:kpix/models/project_session.dart';
import 'package:kpix/models/stamp_manager_data.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/tool_type.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/painting/shader_options.dart';
import 'package:kpix/util/helpers/color_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/canvas/canvas_widget.dart';
import 'package:kpix/widgets/canvas/selection_bar_widget.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/controls/kpix_splitter.dart';
import 'package:kpix/widgets/file/import_widget.dart';
import 'package:kpix/widgets/file/new_project_widget.dart';
import 'package:kpix/widgets/file/shader_export_widget.dart';
import 'package:kpix/widgets/file/shader_preview_widget.dart';
import 'package:kpix/widgets/layer_settings/drawing_layer_settings_widget.dart';
import 'package:kpix/widgets/main/layer_widget.dart';
import 'package:kpix/widgets/main/right_bar_widget.dart';
import 'package:kpix/widgets/palette/color_entry_widget.dart';
import 'package:kpix/widgets/palette/palette_adjustment_widget.dart';
import 'package:kpix/widgets/stamps/stamp_manager_widget.dart';
import 'package:kpix/widgets/tools/shader_widget.dart';
import 'package:kpix/widgets/tools/tools_widget.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

Timeline get _timeline => GetIt.I.get<DocumentState>().timeline;

class _FakePicker extends FilePickerPlatform
{
  final FilePickerResult result;
  _FakePicker(this.result);

  @override
  Future<FilePickerResult?> pickFiles({
    final String? dialogTitle,
    final String? initialDirectory,
    final FileType type = FileType.any,
    final List<String>? allowedExtensions,
    final Function(FilePickerStatus)? onFileLoading,
    final int compressionQuality = 0,
    final bool allowMultiple = false,
    final bool withData = false,
    final bool withReadStream = false,
    final bool lockParentWindow = false,
    final bool readSequential = false,
    final bool cancelUploadOnWindowBlur = true,
  }) async => result;
}

Future<void> _settle(final WidgetTester tester) async
{
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Boots a project, shows [child] and tears it all down after [body].
void _chainTest(
  final String description,
  final Widget Function() child,
  final Future<void> Function(WidgetTester tester) body, {
  final double width = 400,
  final double height = 500,
  final double? textScale,
  final bool semantics = true,
})
{
  testWidgets(description, (final WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await bootProject(canvasSize: CoordinateSetI(x: 8, y: 8));
      GetIt.I.registerSingleton<StampManager>(StampManager());
      GetIt.I.registerSingleton<StylusBridge>(StylusBridge());
    });
    await tester.pumpWidget(ToastificationWrapper(child: MaterialApp(
      theme: monochromeTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      //the test font is wider than the real one, and the dialogs have a fixed size
      builder: textScale == null ? null : (final BuildContext context, final Widget? app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Material(child: Center(child: SizedBox(width: width, height: height, child: child()))),
    ),),);
    await _settle(tester);

    await body(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    for (final Frame frame in _timeline.frames.value)
    {
      for (int i = 0; i < frame.layerList.length; i++)
      {
        frame.layerList.getLayer(index: i).dispose();
      }
    }
    await tester.pump(const Duration(seconds: 1));
  }, semanticsEnabled: semantics,);
}

void main()
{
  group("the splitter", () {
    double widthOf(final WidgetTester tester, final String text) => tester.getSize(find.ancestor(of: find.text(text), matching: find.byType(SizedBox)).first).width;
    const String handle = ".\n.\n.";
    Widget splitter() => const KPixSplitter(left: Text("L"), center: Text("C"), right: Text("R"));

    _chainTest("follows its left divider", splitter, (final WidgetTester tester) async {
      final double left = widthOf(tester, "L");
      final double right = widthOf(tester, "R");
      await tester.drag(find.text(handle).first, const Offset(60, 0));
      await _settle(tester);
      expect(widthOf(tester, "L"), greaterThan(left));
      expect(widthOf(tester, "R"), right);
    }, width: 1200, height: 300,);

    _chainTest("follows its right divider", splitter, (final WidgetTester tester) async {
      final double left = widthOf(tester, "L");
      final double right = widthOf(tester, "R");
      await tester.drag(find.text(handle).last, const Offset(-60, 0));
      await _settle(tester);
      expect(widthOf(tester, "R"), greaterThan(right));
      expect(widthOf(tester, "L"), left);
    }, width: 1200, height: 300,);
  });

  group("the shader options", () {
    Switch switchAt(final WidgetTester tester, final int index) => tester.widget<Switch>(find.byType(Switch).at(index));
    Widget shader() => const Align(alignment: Alignment.topCenter, child: ShaderWidget(titleStyle: TextStyle(fontSize: 16), labelStyle: TextStyle(fontSize: 12)));

    _chainTest("follow the enabled option", shader, (final WidgetTester tester) async {
      final ShaderOptions options = GetIt.I.get<ShaderOptions>();
      options.isEnabled.value = false;
      await _settle(tester);
      expect(switchAt(tester, 0).value, false);
      expect(switchAt(tester, 2).onChanged, isNull);

      options.isEnabled.value = true;
      await _settle(tester);
      expect(switchAt(tester, 0).value, true);
      expect(switchAt(tester, 2).onChanged, isNotNull);
    });

    _chainTest("follow the type of the current layer", shader, (final WidgetTester tester) async {
      final ShaderOptions options = GetIt.I.get<ShaderOptions>();
      options.isEnabled.value = false;
      await _settle(tester);
      final LayerState drawing = _timeline.getCurrentLayer()!;

      _timeline.selectedFrame!.layerList.addNewShadingLayer(select: true);
      _timeline.layerChangeNotifier.reportChange();
      await _settle(tester);
      expect(switchAt(tester, 0).value, true, reason: "a shading layer is always shaded");
      expect(switchAt(tester, 0).onChanged, isNull);

      options.isEnabled.value = true;
      await _settle(tester);
      _timeline.selectedFrame!.layerList.addNewGridLayer(select: true);
      _timeline.layerChangeNotifier.reportChange();
      await _settle(tester);
      expect(switchAt(tester, 0).value, false, reason: "a grid layer cannot be shaded");
      expect(switchAt(tester, 0).onChanged, isNull);

      _timeline.selectedFrame!.layerList.selectLayer(newLayer: drawing);
      _timeline.layerChangeNotifier.reportChange();
      await _settle(tester);
      expect(switchAt(tester, 0).value, true);
      expect(switchAt(tester, 0).onChanged, isNotNull);
    });
  });

  group("the tools", () {
    List<SegmentedButton<ToolType>> rows(final WidgetTester tester) => tester.widgetList<SegmentedButton<ToolType>>(find.byType(SegmentedButton<ToolType>)).toList();
    Widget tools() => const Align(alignment: Alignment.topCenter, child: ToolsWidget());

    _chainTest("follow the selected tool", tools, (final WidgetTester tester) async {
      GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.font);
      await _settle(tester);
      expect(rows(tester).any((final SegmentedButton<ToolType> row) => row.selected.contains(ToolType.font)), true);

      GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.fill);
      await _settle(tester);
      expect(rows(tester).any((final SegmentedButton<ToolType> row) => row.selected.contains(ToolType.fill)), true);
      expect(rows(tester).any((final SegmentedButton<ToolType> row) => row.selected.contains(ToolType.font)), false);
    }, width: 300, height: 300,);

    _chainTest("follow the type of the current layer", tools, (final WidgetTester tester) async {
      bool selectEnabled() => rows(tester).expand((final SegmentedButton<ToolType> row) => row.segments).firstWhere((final ButtonSegment<ToolType> s) => s.value == ToolType.select).enabled;
      expect(selectEnabled(), true);
      final LayerState drawing = _timeline.getCurrentLayer()!;

      _timeline.selectedFrame!.layerList.addNewShadingLayer(select: true);
      _timeline.layerChangeNotifier.reportChange();
      await _settle(tester);
      expect(selectEnabled(), false);

      _timeline.selectedFrame!.layerList.selectLayer(newLayer: drawing);
      _timeline.layerChangeNotifier.reportChange();
      await _settle(tester);
      expect(selectEnabled(), true);
    }, width: 300, height: 300,);
  });

  group("a color entry", () {
    final List<int> pressed = <int>[];
    late ColorEntryWidget entry;
    late List<KPalRampData> ramps;
    Widget build()
    {
      ramps = GetIt.I.get<PaletteState>().colorRamps;
      entry = ColorEntryWidget(color: ramps[0].references[0].getIdColor(), colorSelectedFn: ({required final IdColor newColor}) {pressed.add(1);});
      return Row(children: <Widget>[entry]);
    }
    BoxDecoration decoration(final WidgetTester tester) => tester.widget<Container>(find.descendant(of: find.byType(ColorEntryWidget), matching: find.byType(Container)).first).decoration! as BoxDecoration;

    _chainTest("shows the color it holds", build, (final WidgetTester tester) async {
      expect(decoration(tester).color, ramps[0].references[0].getIdColor().color);
      entry.colorData.value = ramps[2].references[2].getIdColor();
      await _settle(tester);
      expect(decoration(tester).color, ramps[2].references[2].getIdColor().color);
    }, width: 64, height: 64,);

    _chainTest("marks itself while it is the selected color", build, (final WidgetTester tester) async {
      final PaletteState palette = GetIt.I.get<PaletteState>();
      final Color marked = Theme.of(tester.element(find.byType(ColorEntryWidget))).primaryColorLight;
      palette.selectedColorNotifier.value = ramps[1].references[1];
      await _settle(tester);
      expect((decoration(tester).border! as Border).top.color, Colors.transparent);

      palette.selectedColorNotifier.value = ramps[0].references[0];
      await _settle(tester);
      expect((decoration(tester).border! as Border).top.color, marked);
    }, width: 64, height: 64,);

    _chainTest("reports a press", build, (final WidgetTester tester) async {
      pressed.clear();
      await tester.tap(find.byType(ColorEntryWidget));
      await _settle(tester);
      expect(pressed.length, 1);
    }, width: 64, height: 64,);
  });

  group("the new project preview", () {
    Size preview(final WidgetTester tester) => tester.getSize(find.descendant(of: find.byType(Stack), matching: find.byWidgetPredicate((final Widget w) => w is Container && w.decoration is BoxDecoration)).first);
    Widget build() => NewProjectWidget(open: () {}, accept: ({required final CoordinateSetI size}) {});

    _chainTest("follows the width", build, (final WidgetTester tester) async {
      final Size before = preview(tester);
      await tester.drag(find.byType(KPixSlider).at(0), const Offset(60, 0));
      await _settle(tester);
      expect(preview(tester).width / preview(tester).height, isNot(closeTo(before.width / before.height, 0.001)));
    }, width: 1300, height: 800, textScale: 0.5,);

    _chainTest("follows the height", build, (final WidgetTester tester) async {
      final Size before = preview(tester);
      await tester.drag(find.byType(KPixSlider).at(1), const Offset(60, 0));
      await _settle(tester);
      expect(preview(tester).width / preview(tester).height, isNot(closeTo(before.width / before.height, 0.001)));
    }, width: 1300, height: 800, textScale: 0.5,);

    _chainTest("has the shape of a preset", build, (final WidgetTester tester) async {
      await tester.tap(find.text("320×180"));
      await _settle(tester);
      expect(preview(tester).width / preview(tester).height, closeTo(320 / 180, 0.01));
    }, width: 1300, height: 800, textScale: 0.5,);
  });

  group("the shader export preview", () {
    ShaderPreviewWidget preview(final WidgetTester tester) => tester.widget<ShaderPreviewWidget>(find.byType(ShaderPreviewWidget));
    Widget build() => ShaderExportWidget(dismiss: () {}, accept: ({required final ShaderExportData exportData}) {});

    _chainTest("follows the shader type", build, (final WidgetTester tester) async {
      final ExportShaderValues before = preview(tester).values;
      final ExportShaderType current = tester.widget<SegmentedButton<ExportShaderType>>(find.byType(SegmentedButton<ExportShaderType>)).selected.first;
      tester.widget<SegmentedButton<ExportShaderType>>(find.byType(SegmentedButton<ExportShaderType>)).onSelectionChanged!(<ExportShaderType>{ExportShaderType.values.firstWhere((final ExportShaderType t) => t != current)});
      await _settle(tester);
      expect(identical(preview(tester).values, before), false);
    }, width: 1300, height: 800, textScale: 0.5, semantics: false,);

    _chainTest("follows the scaling", build, (final WidgetTester tester) async {
      final int before = preview(tester).scaling;
      final int count = tester.widgetList(find.byType(KPixSlider)).length;
      await tester.drag(find.byType(KPixSlider).at(count - 1), const Offset(80, 0));
      await _settle(tester);
      expect(preview(tester).scaling, isNot(before));
    }, width: 1300, height: 800, textScale: 0.5, semantics: false,);

    _chainTest("gets the source once it is ready", build, (final WidgetTester tester) async {
      expect(preview(tester).source, isNotNull);
    }, width: 1300, height: 800, textScale: 0.5, semantics: false,);
  });

  group("the import dialog", () {
    Widget build() => ImportWidget(dismiss: () {}, import: ({required final ImportData importData}) {});
    KPixSlider sliderAt(final WidgetTester tester, final int index) => tester.widget<KPixSlider>(find.byType(KPixSlider).at(index));

    Future<void> loadImage(final WidgetTester tester, final int width, final int height) async
    {
      late Uint8List png;
      await tester.runAsync(() async {
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = const Color(0xFFCC3333));
        final ui.Image picture = await recorder.endRecording().toImage(width, height);
        png = (await picture.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      });
      final FilePickerPlatform realPicker = FilePickerPlatform.instance;
      FilePickerPlatform.instance = _FakePicker(FilePickerResult(<PlatformFile>[PlatformFile(name: "picture.png", size: png.length, bytes: png)]));
      await tester.tap(find.byTooltip(AppLocalizations.of(tester.element(find.byType(ImportWidget)))!.chooseImage));
      for (int i = 0; i < 8; i++)
      {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      FilePickerPlatform.instance = realPicker;
      await _settle(tester);
    }

    _chainTest("only offers the scale with an image", build, (final WidgetTester tester) async {
      expect(sliderAt(tester, 0).onChanged, isNull);
      expect(sliderAt(tester, 0).label, "");

      await loadImage(tester, 64, 32);
      expect(sliderAt(tester, 0).onChanged, isNotNull);
      expect(sliderAt(tester, 0).label, contains("->"));
    }, width: 800, height: 700, textScale: 0.5,);

    _chainTest("follows the scale", build, (final WidgetTester tester) async {
      await loadImage(tester, 64, 32);
      final double before = sliderAt(tester, 0).value;
      final String? label = sliderAt(tester, 0).label;
      await tester.drag(find.byType(KPixSlider).at(0), const Offset(100, 0));
      await _settle(tester);
      expect(sliderAt(tester, 0).value, greaterThan(before));
      expect(sliderAt(tester, 0).label, isNot(label));
    }, width: 800, height: 700, textScale: 0.5,);

    _chainTest("sets its palette limits only for a new palette", build, (final WidgetTester tester) async {
      //the switch for a new palette is the first of the dialog
      final bool startsOn = tester.widget<Switch>(find.byType(Switch).at(0)).value;
      expect(sliderAt(tester, 1).onChanged != null, startsOn);
      expect(sliderAt(tester, 2).onChanged != null, startsOn);

      await tester.tap(find.byType(Switch).at(0));
      await _settle(tester);
      expect(sliderAt(tester, 1).onChanged != null, !startsOn);
      expect(sliderAt(tester, 2).onChanged != null, !startsOn);
    }, width: 800, height: 700, textScale: 0.5,);

    _chainTest("keeps the palette limits apart", build, (final WidgetTester tester) async {
      final AppLocalizations l10n = AppLocalizations.of(tester.element(find.byType(ImportWidget)))!;
      if (tester.widget<Switch>(find.byType(Switch).at(0)).onChanged != null && !tester.widget<Switch>(find.byType(Switch).at(0)).value)
      {
        await tester.tap(find.byType(Switch).at(0));
        await _settle(tester);
      }
      Finder rowOf(final String label) => find.descendant(of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first, matching: find.byType(KPixSlider));
      final KPixSlider ramps = tester.widget<KPixSlider>(rowOf(l10n.maxColorRamps));
      final KPixSlider colors = tester.widget<KPixSlider>(rowOf(l10n.maxColorsPerRamp));
      expect(ramps.min, KPalConstraints.rampCountMin.toDouble());
      expect(ramps.max, KPalConstraints.maxClusters.toDouble());
      expect(colors.min, KPalConstraints.colorCountMin.toDouble());
      expect(colors.max, KPalConstraints.colorCountMax.toDouble());

      ramps.onChanged!(KPalConstraints.rampCountMin + 1.6);
      await _settle(tester);
      expect(tester.widget<KPixSlider>(rowOf(l10n.maxColorRamps)).value, KPalConstraints.rampCountMin + 2.0);
      expect(tester.widget<KPixSlider>(rowOf(l10n.maxColorsPerRamp)).value, colors.value);

      colors.onChanged!(KPalConstraints.colorCountMin + 2.4);
      await _settle(tester);
      expect(tester.widget<KPixSlider>(rowOf(l10n.maxColorsPerRamp)).value, KPalConstraints.colorCountMin + 2.0);
      expect(tester.widget<KPixSlider>(rowOf(l10n.maxColorRamps)).value, KPalConstraints.rampCountMin + 2.0);
    }, width: 800, height: 700, textScale: 0.5,);
  });

  group("a layer's settings button", () {
    IconButton button(final WidgetTester tester) => tester.widget<IconButton>(find.ancestor(of: find.byIcon(TablerIcons.settings), matching: find.byType(IconButton)));
    DrawingLayerState layer() => _timeline.selectedFrame!.layerList.getLayer(index: 0) as DrawingLayerState;
    Widget build() => LayerWidget(layerState: layer());

    _chainTest("is off while the layer is locked", build, (final WidgetTester tester) async {
      expect(button(tester).onPressed, isNotNull);
      layer().lockState.value = LayerLockState.locked;
      await _settle(tester);
      expect(button(tester).onPressed, isNull);
      layer().lockState.value = LayerLockState.unlocked;
      await _settle(tester);
      expect(button(tester).onPressed, isNotNull);
    }, width: 240, height: 120,);

    _chainTest("shows active settings", build, (final WidgetTester tester) async {
      expect(button(tester).style!.backgroundColor, isNull);
      final DrawingLayerSettings settings = layer().layerSettings as DrawingLayerSettings;
      settings.innerStrokeStyle.value = InnerStrokeStyle.solid;
      await _settle(tester);
      expect(button(tester).style!.backgroundColor, isNotNull);
      settings.innerStrokeStyle.value = InnerStrokeStyle.off;
      await _settle(tester);
      expect(button(tester).style!.backgroundColor, isNull);
    }, width: 240, height: 120,);
  });

  group("the right bar", () {
    Widget build() => const RightBarWidget();
    int layers(final WidgetTester tester) => tester.widgetList(find.byType(LayerWidget)).length;

    _chainTest("shows the layers of the frame", build, (final WidgetTester tester) async {
      expect(layers(tester), 1);
      _timeline.selectedFrame!.layerList.addNewGridLayer(select: true);
      _timeline.layerChangeNotifier.reportChange();
      await _settle(tester);
      expect(layers(tester), 2);
    }, width: 300, height: 800,);

    _chainTest("follows the selected frame", build, (final WidgetTester tester) async {
      _timeline.selectedFrame!.layerList.addNewGridLayer(select: true);
      _timeline.addNewFrameRight();
      await _settle(tester);
      expect(layers(tester), 1);
      //written directly, since moving between frames also reports a layer change
      _timeline.selectedFrameIndexNotifier.value = 0;
      await _settle(tester);
      expect(layers(tester), 2);
    }, width: 300, height: 800,);

    _chainTest("slides the settings in and out", build, (final WidgetTester tester) async {
      final ViewState view = GetIt.I.get<ViewState>();
      AnimatedSlide slide() => tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(slide().offset, const Offset(1, 0));

      view.layerSettingsVisibleNotifier.value = true;
      await _settle(tester);
      expect(slide().offset, Offset.zero);
      expect((_timeline.getCurrentLayer()! as DrawingLayerState).layerSettings.editStarted, true);

      view.layerSettingsVisibleNotifier.value = false;
      await _settle(tester);
      expect(slide().offset, const Offset(1, 0));
    }, width: 300, height: 800,);

    _chainTest("shows the settings of the frame's layer", build, (final WidgetTester tester) async {
      final DrawingLayerState first = _timeline.getCurrentLayer()! as DrawingLayerState;
      expect(tester.widget<DrawingLayerSettingsWidget>(find.byType(DrawingLayerSettingsWidget, skipOffstage: false)).layer, first);

      _timeline.addNewFrameRight();
      await _settle(tester);
      final DrawingLayerState second = _timeline.getCurrentLayer()! as DrawingLayerState;
      expect(identical(first, second), false);
      expect(tester.widget<DrawingLayerSettingsWidget>(find.byType(DrawingLayerSettingsWidget, skipOffstage: false)).layer, second);
    }, width: 300, height: 800,);

    _chainTest("has no settings without a project", build, (final WidgetTester tester) async {
      expect(find.byType(AnimatedSlide), findsOneWidget);
      GetIt.I.get<ProjectSession>().hasProjectNotifier.value = false;
      await _settle(tester);
      expect(find.byType(AnimatedSlide), findsNothing);
      GetIt.I.get<ProjectSession>().hasProjectNotifier.value = true;
      await _settle(tester);
      expect(find.byType(AnimatedSlide), findsOneWidget);
    }, width: 300, height: 800,);
  });

  group("the palette adjustment preview", () {
    _chainTest("is drawn again while it is pressed", () => PaletteAdjustmentWidget(dismiss: () {}), (final WidgetTester tester) async {
      final Finder image = find.byType(RawImage).first;
      final RawImage before = tester.widget<RawImage>(image);
      final TestGesture gesture = await tester.startGesture(tester.getCenter(image));
      await _settle(tester);
      expect(identical(tester.widget<RawImage>(image), before), false);
      final RawImage pressed = tester.widget<RawImage>(image);
      await gesture.up();
      await _settle(tester);
      expect(identical(tester.widget<RawImage>(image), pressed), false);
    }, width: 1300, height: 800, textScale: 0.5, semantics: false,);
  });

  group("the palette adjustment preview, rendered", () {
    _chainTest("shows the image once it is ready", () => PaletteAdjustmentWidget(dismiss: () {}), (final WidgetTester tester) async {
      final Finder image = find.byType(RawImage).first;
      expect(tester.widget<RawImage>(image).image, isNull);
      for (int i = 0; i < 40 && tester.widget<RawImage>(image).image == null; i++)
      {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.widget<RawImage>(image).image, isNotNull);
    }, width: 1300, height: 800, textScale: 0.5, semantics: false,);
  });

  group("the stamp manager", () {
    StampManagerEntryData stamp(final String name) => StampManagerEntryData(path: "", thumbnail: null, name: name, isLocked: false, data: HashMap<CoordinateSetI, int>(), width: 2, height: 2);
    Widget build() => StampManagerWidget(dismiss: () {}, fileLoad: ({required final StampManagerEntryData data}) {});
    SegmentedButton<String> folders(final WidgetTester tester) => tester.widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));

    _chainTest("follows the selected folder", build, (final WidgetTester tester) async {
      final StampManager manager = GetIt.I.get<StampManager>();
      expect(find.byType(SegmentedButton<String>), findsNothing);
      manager.stampMap.value = <String, List<StampManagerEntryData>>{"one": <StampManagerEntryData>[stamp("a")], "two": <StampManagerEntryData>[stamp("b")]};
      manager.selectedFolder.value = "one";
      await _settle(tester);
      expect(folders(tester).selected, <String>{"one"});

      manager.selectedFolder.value = "two";
      await _settle(tester);
      expect(folders(tester).selected, <String>{"two"});

      manager.selectedFolder.value = null;
      await _settle(tester);
      expect(find.byType(SegmentedButton<String>), findsNothing);
    }, width: 800, height: 600,);

    _chainTest("follows the stamps on disk", build, (final WidgetTester tester) async {
      final StampManager manager = GetIt.I.get<StampManager>();
      manager.stampMap.value = <String, List<StampManagerEntryData>>{"one": <StampManagerEntryData>[stamp("a")]};
      manager.selectedFolder.value = "one";
      await _settle(tester);
      expect(folders(tester).segments.length, 1);

      manager.stampMap.value = <String, List<StampManagerEntryData>>{"one": <StampManagerEntryData>[stamp("a")], "two": <StampManagerEntryData>[stamp("b")]};
      await _settle(tester);
      expect(folders(tester).segments.map((final ButtonSegment<String> s) => s.value), <String>["one", "two"]);
    }, width: 800, height: 600,);
  });

  group("the selection bar of the canvas", () {
    IgnorePointer bar(final WidgetTester tester) => tester.widget<IgnorePointer>(find.byWidgetPredicate((final Widget w) => w is IgnorePointer && w.child is SizeTransition));
    Widget build() => const CanvasWidget();

    _chainTest("shows with the select tool", build, (final WidgetTester tester) async {
      expect(bar(tester).ignoring, true);
      GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.select);
      await _settle(tester);
      expect(bar(tester).ignoring, false);
      GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.pencil);
      await _settle(tester);
      expect(bar(tester).ignoring, true);
    }, width: 800, height: 600,);

    _chainTest("shows with a selection", build, (final WidgetTester tester) async {
      expect(bar(tester).ignoring, true);
      GetIt.I.get<DocumentState>().selectionState.selectAll(addToHistoryStack: false);
      await _settle(tester);
      expect(bar(tester).ignoring, false);
      GetIt.I.get<DocumentState>().selectionState.deselect(addToHistoryStack: false);
      await _settle(tester);
      expect(bar(tester).ignoring, true);
    }, width: 800, height: 600,);

    _chainTest("slides along with what it shows", build, (final WidgetTester tester) async {
      double factor() => tester.widget<SizeTransition>(find.byWidgetPredicate((final Widget w) => w is SizeTransition && w.child is SelectionBarWidget)).sizeFactor.value;
      expect(factor(), 0.0);
      GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.select);
      await _settle(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(factor(), 1.0);
      GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.pencil);
      await _settle(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(factor(), 0.0);
    }, width: 800, height: 600,);
  });

  group("the bevel sliders of the layer settings", () {
    DrawingLayerState layer() => _timeline.selectedFrame!.layerList.getLayer(index: 0) as DrawingLayerState;
    DrawingLayerSettings settings() => layer().layerSettings as DrawingLayerSettings;
    Widget build() => SingleChildScrollView(child: layer().getSettingsWidget());
    Iterable<KPixSlider> sliders(final WidgetTester tester) => tester.widgetList<KPixSlider>(find.byType(KPixSlider));
    AppLocalizations l10nOf(final WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(DrawingLayerSettingsWidget)))!;
    //both have the same limits, so only their labels tell them apart
    KPixSlider distance(final WidgetTester tester) => sliders(tester).firstWhere((final KPixSlider s) => s.label == "${settings().bevelDistance.value} ${l10nOf(tester).pixelsAbbrev}");
    KPixSlider strength(final WidgetTester tester) => sliders(tester).firstWhere((final KPixSlider s) => s.label == l10nOf(tester).stepCount(settings().bevelStrength.value.abs(), "${settings().bevelStrength.value}"));

    void bevelTest(final String description, final Future<void> Function(WidgetTester tester, AppLocalizations l10n) body)
    {
      _chainTest(description, build, (final WidgetTester tester) async {
        //the test font does not fit the fixed rows
        final FlutterExceptionHandler? realHandler = FlutterError.onError;
        FlutterError.onError = (final FlutterErrorDetails details) {
          if (!details.exception.toString().contains('overflowed'))
          {
            realHandler!(details);
          }
        };
        settings().innerStrokeStyle.value = InnerStrokeStyle.bevel;
        await _settle(tester);
        await body(tester, AppLocalizations.of(tester.element(find.byType(DrawingLayerSettingsWidget)))!);
        await tester.pumpWidget(const SizedBox.shrink());
        FlutterError.onError = realHandler;
      }, width: 320, height: 800, textScale: 0.25,);
    }

    bevelTest("show their values with their own labels", (final WidgetTester tester, final AppLocalizations l10n) async {
      final int min = settings().constraints.bevelDistanceMin;
      settings().bevelDistance.value = min + 1;
      await _settle(tester);
      expect(distance(tester).value, min + 1.0);
      expect(distance(tester).min, min.toDouble());
      expect(distance(tester).max, settings().constraints.bevelDistanceMax.toDouble());
      final int value = settings().constraints.bevelStrengthMax;
      settings().bevelStrength.value = value;
      await _settle(tester);
      expect(strength(tester).value, value.toDouble());
      expect(strength(tester).min, settings().constraints.bevelStrengthMin.toDouble());
      expect(strength(tester).max, value.toDouble());
    });

    bevelTest("write their own values", (final WidgetTester tester, final AppLocalizations l10n) async {
      final int strengthBefore = settings().bevelStrength.value;
      final int min = settings().constraints.bevelDistanceMin;
      distance(tester).onChanged!(min + 0.6);
      expect(settings().bevelDistance.value, min + 1);
      expect(settings().bevelStrength.value, strengthBefore);

      final int distanceNow = settings().bevelDistance.value;
      final int strengthMin = settings().constraints.bevelStrengthMin;
      await _settle(tester);
      strength(tester).onChanged!(strengthMin + 1.4);
      expect(settings().bevelStrength.value, strengthMin + 1);
      expect(settings().bevelDistance.value, distanceNow);
    });

    bevelTest("use the medium text style", (final WidgetTester tester, final AppLocalizations l10n) async {
      final TextStyle medium = Theme.of(tester.element(find.byType(DrawingLayerSettingsWidget))).textTheme.bodyMedium!;
      expect(distance(tester).textStyle, medium);
      expect(strength(tester).textStyle, medium);
    });
  });
}
