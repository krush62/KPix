import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/reference_image_manager.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/reference_layer/reference_layer_state.dart';
import 'package:kpix/models/constraints/reference_layer_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/history/history_manager.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/tools/reference_layer_options_widget.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

class _Scene
{
  final WidgetTester tester;
  final ReferenceLayerState reference;
  final ui.Image picture;
  _Scene(this.tester, this.reference, this.picture);

  AppLocalizations get l10n => AppLocalizations.of(tester.element(find.byType(ReferenceLayerOptionsWidget)))!;
  bool get committed => GetIt.I.get<HistoryManager>().hasUndo.value;

  Future<void> settle() async
  {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> addImage() async
  {
    reference.imageNotifier.value = ReferenceImage(path: "folder/picture.png", image: picture);
    await settle();
  }

  /// The slider that sits next to [label], so a mixed up row is noticed.
  KPixSlider slider(final String label) => tester.widget<KPixSlider>(find.descendant(of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first, matching: find.byType(KPixSlider)));
}

void main()
{
  void referenceTest(final String description, final Future<void> Function(_Scene scene) body)
  {
    testWidgets(description, (final WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      late ui.Image picture;
      await tester.runAsync(() async {
        await bootProject(canvasSize: CoordinateSetI(x: 8, y: 8));
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 16, 8), Paint()..color = const Color(0xFFCC3333));
        picture = await recorder.endRecording().toImage(16, 8);
      });
      GetIt.I.registerSingleton<ReferenceImageManager>(ReferenceImageManager());
      final ReferenceLayerState reference = GetIt.I.get<DocumentState>().timeline.selectedFrame!.layerList.addNewReferenceLayer(select: true).$2!;
      await tester.pumpWidget(ToastificationWrapper(child: MaterialApp(
        theme: monochromeTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(child: Center(child: SizedBox(width: 400, height: 800, child: ReferenceLayerOptionsWidget(referenceState: reference)))),
      ),),);
      final _Scene scene = _Scene(tester, reference, picture);
      await scene.settle();

      await body(scene);

      await tester.pumpWidget(const SizedBox.shrink());
      for (final Frame frame in GetIt.I.get<DocumentState>().timeline.frames.value)
      {
        for (int i = 0; i < frame.layerList.length; i++)
        {
          frame.layerList.getLayer(index: i).dispose();
        }
      }
      await tester.pump(const Duration(seconds: 1));
    });
  }

  group("the file row", () {
    referenceTest("shows a placeholder without an image", (final _Scene scene) async {
      expect(find.text("<${scene.l10n.noFileLoaded.toUpperCase()}>"), findsOneWidget);
    });

    referenceTest("shows the name of the image next to its label", (final _Scene scene) async {
      final AppLocalizations l10n = scene.l10n;
      await scene.addImage();
      expect(find.text("picture.png"), findsOneWidget);
      expect(find.text("<${l10n.noFileLoaded.toUpperCase()}>"), findsNothing);
      expect(find.descendant(of: find.ancestor(of: find.text(l10n.file), matching: find.byType(Row)).first, matching: find.text("picture.png")), findsOneWidget);
      expect(find.descendant(of: find.ancestor(of: find.text(l10n.file), matching: find.byType(Row)).first, matching: find.byTooltip(l10n.openReferenceImage)), findsOneWidget);
    });

    referenceTest("gives the controls the wide column", (final _Scene scene) async {
      final AppLocalizations l10n = scene.l10n;
      final Finder fileRow = find.ancestor(of: find.text(l10n.file), matching: find.byType(Row)).first;
      final List<Expanded> columns = scene.tester.widgetList<Expanded>(find.descendant(of: fileRow, matching: find.byType(Expanded))).toList();
      expect(columns[0].flex, 1);
      expect(columns[1].flex, ToolSettingsWidgetOptions.columnWidthRatio);
    });
  });

  group("opacity", () {
    referenceTest("shows, follows and writes its value", (final _Scene scene) async {
      await scene.addImage();
      final String label = scene.l10n.opacity;
      expect(scene.slider(label).min, ReferenceLayerConstraints.opacityMin.toDouble());
      expect(scene.slider(label).max, ReferenceLayerConstraints.opacityMax.toDouble());
      scene.reference.opacityNotifier.value = 42;
      await scene.settle();
      expect(scene.slider(label).value, 42.0);
      expect(scene.slider(label).label, "42%");

      scene.slider(label).onChanged!(50.6);
      expect(scene.reference.opacityNotifier.value, 51);
    });

    referenceTest("commits at the end of a change", (final _Scene scene) async {
      await scene.addImage();
      expect(scene.committed, false);
      scene.slider(scene.l10n.opacity).onChangedEnd!(50);
      expect(scene.committed, true);
    });

    referenceTest("cannot be used without an image", (final _Scene scene) async {
      expect(scene.slider(scene.l10n.opacity).onChanged, isNull);
      await scene.addImage();
      expect(scene.slider(scene.l10n.opacity).onChanged, isNotNull);
      scene.reference.imageNotifier.value = null;
      await scene.settle();
      expect(scene.slider(scene.l10n.opacity).onChanged, isNull);
    });
  });

  group("zoom", () {
    referenceTest("shows, follows and writes its value", (final _Scene scene) async {
      await scene.addImage();
      final String label = scene.l10n.zoom;
      expect(scene.slider(label).min, ReferenceLayerConstraints.zoomMin.toDouble());
      expect(scene.slider(label).max, ReferenceLayerConstraints.zoomMax.toDouble());
      scene.reference.zoomNotifier.value = ReferenceLayerConstraints.zoomMin + 123;
      await scene.settle();
      expect(scene.slider(label).value, ReferenceLayerConstraints.zoomMin + 123.0);
      expect(scene.slider(label).label, "${((ReferenceLayerConstraints.zoomMin + 123) / 10.0).toStringAsFixed(1)}%");

      scene.slider(label).onChanged!(ReferenceLayerConstraints.zoomMin + 7.6);
      expect(scene.reference.zoomNotifier.value, ReferenceLayerConstraints.zoomMin + 8);
    });

    referenceTest("commits at the end of a change", (final _Scene scene) async {
      await scene.addImage();
      expect(scene.committed, false);
      scene.slider(scene.l10n.zoom).onChangedEnd!(50);
      expect(scene.committed, true);
    });

    referenceTest("cannot be used without an image", (final _Scene scene) async {
      expect(scene.slider(scene.l10n.zoom).onChanged, isNull);
      await scene.addImage();
      expect(scene.slider(scene.l10n.zoom).onChanged, isNotNull);
    });
  });

  group("the decimal rows", () {
    referenceTest("keep their value, limits and precision", (final _Scene scene) async {
      await scene.addImage();
      final String label = scene.l10n.aspectRatio;
      expect(scene.slider(label).min, ReferenceLayerConstraints.aspectRatioMin);
      expect(scene.slider(label).max, ReferenceLayerConstraints.aspectRatioMax);
      expect(scene.slider(label).decimals, 2);
      scene.slider(label).onChanged!(1.25);
      expect(scene.reference.aspectRatioNotifier.value, 1.25);
      await scene.settle();
      expect(scene.slider(label).value, 1.25);
    });

    referenceTest("reset to their default and commit", (final _Scene scene) async {
      await scene.addImage();
      final AppLocalizations l10n = scene.l10n;
      scene.reference.brightnessNotifier.value = ReferenceLayerConstraints.brightnessMin;
      await scene.settle();
      expect(scene.committed, false);
      await scene.tester.tap(find.byTooltip(l10n.resetSetting(l10n.brightness)));
      await scene.settle();
      expect(scene.reference.brightnessNotifier.value, ReferenceLayerConstraints.brightnessDefault);
      expect(scene.committed, true);
    });
  });

  group("rebuilds", () {
    referenceTest("a value only touches its own row", (final _Scene scene) async {
      await scene.addImage();
      final AppLocalizations l10n = scene.l10n;
      final KPixSlider opacity = scene.slider(l10n.opacity);
      final KPixSlider zoom = scene.slider(l10n.zoom);

      scene.reference.opacityNotifier.value = 12;
      await scene.settle();
      expect(identical(scene.slider(l10n.opacity), opacity), false);
      expect(identical(scene.slider(l10n.zoom), zoom), true);
    });
  });
}
