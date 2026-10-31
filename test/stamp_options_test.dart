import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/kpix_constants.dart';
import 'package:kpix/kpix_theme.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/managers/stamp_manager.dart';
import 'package:kpix/models/constraints/tool_stamp_constraints.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/stamp_manager_data.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/models/tool_state.dart';
import 'package:kpix/models/tool_type.dart';
import 'package:kpix/tool_options/stamp_options.dart';
import 'package:kpix/tool_options/tool_options.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/stamps/stamp_manager_widget.dart';
import 'package:kpix/widgets/tools/tool_settings_widget.dart';
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

class _Scene
{
  final WidgetTester tester;
  final StampOptions options;
  final StampManager manager;
  final HotkeyManager hotkeys;
  final ui.Image thumbnail;
  int managerShown = 0;

  _Scene({required this.tester, required this.options, required this.manager, required this.hotkeys, required this.thumbnail});

  AppLocalizations get l10n => AppLocalizations.of(tester.element(find.byType(OutlinedButton)))!;

  Future<void> settle() async
  {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tapSwitch(final int index) async
  {
    await tester.tap(find.byType(Switch).at(index));
    await settle();
  }

  Future<void> select(final StampManagerEntryData? stamp) async
  {
    manager.selectedStamp.value = stamp;
    await settle();
  }

  Future<void> alignOn() async
  {
    options.gridAlign.value = true;
    await settle();
  }

  Switch switchAt(final int index) => tester.widget<Switch>(find.byType(Switch).at(index));
  KPixSlider sliderAt(final int index) => tester.widget<KPixSlider>(find.byType(KPixSlider).at(index));
  RawImage get image => tester.widget<RawImage>(find.byType(RawImage));
  Transform get flip => tester.widget<Transform>(find.ancestor(of: find.byType(RawImage), matching: find.byType(Transform)).first);
}

StampManagerEntryData _stamp({final String name = "stamp", final int width = 8, final int height = 4, final ui.Image? thumbnail, final bool isLocked = false})
{
  return StampManagerEntryData(path: "", thumbnail: thumbnail, name: name, isLocked: isLocked, data: HashMap<CoordinateSetI, int>(), width: width, height: height);
}

Future<ui.Image> _image() async
{
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 8, 4), Paint()..color = const Color(0xFFCC3333));
  return recorder.endRecording().toImage(8, 4);
}

void main()
{
  /// Pumps the options on a booted project, runs [body] and tears it all down.
  /// With [viaSettings] they come from the real tool settings, stamp manager included.
  void stampTest(final String description, final Future<void> Function(_Scene scene) body, {final bool viaSettings = false})
  {
    testWidgets(description, (final WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      late ui.Image thumbnail;
      await tester.runAsync(() async {
        await bootProject(canvasSize: CoordinateSetI(x: 8, y: 8));
        thumbnail = await _image();
      });
      final StampManager manager = StampManager();
      GetIt.I.registerSingleton<StampManager>(manager);
      final _Scene scene = _Scene(tester: tester, options: GetIt.I.get<ToolOptions>().stampOptions, manager: manager, hotkeys: GetIt.I.get<HotkeyManager>(), thumbnail: thumbnail);
      if (viaSettings)
      {
        GetIt.I.get<ToolState>().setToolSelection(tool: ToolType.stamp);
      }

      await tester.pumpWidget(ToastificationWrapper(child: MaterialApp(
        theme: monochromeTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(child: Center(child: SizedBox(
          width: 400,
          height: 500,
          child: viaSettings ? const ToolSettingsWidget() : Builder(builder: (final BuildContext context) => StampOptions.getWidget(context: context, stampOptions: scene.options, showStampManager: () => scene.managerShown++)),
        ),),),
      ),),);

      await body(scene);

      scene.hotkeys.controlNotifier.value = false;
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

  group("the stamp button", () {
    stampTest("shows a placeholder without a stamp", (final _Scene scene) async {
      expect(find.text("<${scene.l10n.noStamp.toUpperCase()}>"), findsOneWidget);
      expect(find.byType(RawImage), findsNothing);
    });

    stampTest("shows the name of a stamp without a thumbnail", (final _Scene scene) async {
      await scene.select(_stamp(name: "plain"));
      expect(find.text("plain"), findsOneWidget);
      expect(find.text("<${scene.l10n.noStamp.toUpperCase()}>"), findsNothing);
      expect(find.byType(RawImage), findsNothing);

      await scene.select(_stamp(name: "locked", isLocked: true));
      expect(find.text("[locked]"), findsOneWidget);
    });

    stampTest("shows a thumbnail instead of the name", (final _Scene scene) async {
      await scene.select(_stamp(name: "picture", thumbnail: scene.thumbnail));
      expect(find.text("picture"), findsNothing);
      expect(identical(scene.image.image, scene.thumbnail), true);
      expect(scene.image.fit, BoxFit.contain);
      expect(scene.image.filterQuality, FilterQuality.none);
      expect(scene.image.scale, 0.1);

      final Padding padding = scene.tester.widget<Padding>(find.ancestor(of: find.byType(RawImage), matching: find.byType(Padding)).first);
      expect(padding.padding, const EdgeInsets.all(ToolSettingsWidgetOptions.padding));
    });

    stampTest("goes back to the placeholder when the stamp goes away", (final _Scene scene) async {
      await scene.select(_stamp(thumbnail: scene.thumbnail));
      await scene.select(null);
      expect(find.text("<${scene.l10n.noStamp.toUpperCase()}>"), findsOneWidget);
      expect(find.byType(RawImage), findsNothing);
    });

    stampTest("opens the stamp manager", (final _Scene scene) async {
      await scene.tester.tap(find.byType(OutlinedButton));
      await scene.settle();
      expect(scene.managerShown, 1);
    });
  });

  group("the preview", () {
    stampTest("follows each flip on its own", (final _Scene scene) async {
      await scene.select(_stamp(thumbnail: scene.thumbnail));
      void expectFlip(final double x, final double y)
      {
        expect(scene.flip.transform.storage[0], x);
        expect(scene.flip.transform.storage[5], y);
      }

      expectFlip(1, 1);
      scene.options.flipH.value = true;
      await scene.settle();
      expectFlip(-1, 1);
      scene.options.flipV.value = true;
      await scene.settle();
      expectFlip(-1, -1);
      scene.options.flipH.value = false;
      await scene.settle();
      expectFlip(1, -1);
      scene.options.flipV.value = false;
      await scene.settle();
      expectFlip(1, 1);
    });

    stampTest("keeps the flips for the next stamp", (final _Scene scene) async {
      scene.options.flipH.value = true;
      await scene.select(_stamp(thumbnail: scene.thumbnail));
      expect(scene.flip.transform.storage[0], -1);
    });
  });

  group("the flip switches", () {
    stampTest("each write their own value", (final _Scene scene) async {
      await scene.tapSwitch(0);
      expect(scene.options.flipH.value, true);
      expect(scene.options.flipV.value, false);
      expect(scene.switchAt(0).value, true);
      expect(scene.switchAt(1).value, false);

      await scene.tapSwitch(1);
      expect(scene.options.flipV.value, true);
      expect(scene.switchAt(1).value, true);

      await scene.tapSwitch(0);
      expect(scene.options.flipH.value, false);
      expect(scene.options.flipV.value, true);
    });

    stampTest("each follow their own value", (final _Scene scene) async {
      scene.options.flipH.value = true;
      await scene.settle();
      expect(scene.switchAt(0).value, true);
      expect(scene.switchAt(1).value, false);

      scene.options.flipH.value = false;
      scene.options.flipV.value = true;
      await scene.settle();
      expect(scene.switchAt(0).value, false);
      expect(scene.switchAt(1).value, true);
    });

    stampTest("sit next to their icons", (final _Scene scene) async {
      final WidgetTester tester = scene.tester;
      expect(tester.getCenter(find.byIcon(TablerIcons.flip_vertical)).dy, closeTo(tester.getCenter(find.byType(Switch).at(0)).dy, 1));
      expect(tester.getCenter(find.byIcon(TablerIcons.flip_horizontal)).dy, closeTo(tester.getCenter(find.byType(Switch).at(1)).dy, 1));
      expect(tester.widget<Icon>(find.byIcon(TablerIcons.flip_vertical)).color, Theme.of(tester.element(find.byType(OutlinedButton))).primaryColorLight);
    });
  });

  group("the offset rows", () {
    stampTest("stay away without grid align", (final _Scene scene) async {
      await scene.select(_stamp());
      expect(find.text(scene.l10n.offsetX), findsNothing);
      expect(find.text(scene.l10n.offsetY), findsNothing);
      expect(find.byType(KPixSlider), findsNothing);
    });

    stampTest("only show their labels without a stamp", (final _Scene scene) async {
      await scene.alignOn();
      expect(find.text(scene.l10n.offsetX), findsOneWidget);
      expect(find.text(scene.l10n.offsetY), findsOneWidget);
      expect(find.byType(KPixSlider), findsNothing);
    });

    stampTest("show a slider per axis with a stamp", (final _Scene scene) async {
      await scene.alignOn();
      await scene.select(_stamp());
      expect(scene.sliderAt(0).min, 0);
      expect(scene.sliderAt(0).max, 7);
      expect(scene.sliderAt(0).value, 0);
      expect(scene.sliderAt(1).min, 0);
      expect(scene.sliderAt(1).max, 3);
      expect(scene.sliderAt(1).value, 0);
    });

    stampTest("put each slider next to its label", (final _Scene scene) async {
      await scene.alignOn();
      await scene.select(_stamp());
      final WidgetTester tester = scene.tester;
      expect(tester.getCenter(find.text(scene.l10n.offsetX)).dy, closeTo(tester.getCenter(find.byType(KPixSlider).at(0)).dy, 1));
      expect(tester.getCenter(find.text(scene.l10n.offsetY)).dy, closeTo(tester.getCenter(find.byType(KPixSlider).at(1)).dy, 1));
      expect(tester.getCenter(find.text(scene.l10n.offsetX)).dy, lessThan(tester.getCenter(find.text(scene.l10n.offsetY)).dy));
    });

    stampTest("give the slider the wide column", (final _Scene scene) async {
      await scene.alignOn();
      await scene.select(_stamp());
      final Expanded column = scene.tester.widget<Expanded>(find.ancestor(of: find.byType(KPixSlider).at(0), matching: find.byType(Expanded)).first);
      expect(column.flex, ToolSettingsWidgetOptions.columnWidthRatio);
    });

    stampTest("each follow their own offset", (final _Scene scene) async {
      await scene.alignOn();
      await scene.select(_stamp());
      scene.options.gridOffsetX.value = 3;
      await scene.settle();
      expect(scene.sliderAt(0).value, 3);
      expect(scene.sliderAt(1).value, 0);

      scene.options.gridOffsetY.value = 2;
      await scene.settle();
      expect(scene.sliderAt(0).value, 3);
      expect(scene.sliderAt(1).value, 2);
    });

    stampTest("each write their own offset", (final _Scene scene) async {
      await scene.alignOn();
      await scene.select(_stamp());
      await scene.tester.drag(find.byType(KPixSlider).at(0), const Offset(500, 0));
      await scene.settle();
      expect(scene.options.gridOffsetX.value, 7);
      expect(scene.options.gridOffsetY.value, 0);

      await scene.tester.drag(find.byType(KPixSlider).at(1), const Offset(500, 0));
      await scene.settle();
      expect(scene.options.gridOffsetX.value, 7);
      expect(scene.options.gridOffsetY.value, 3);
    });

    stampTest("round what the slider reports", (final _Scene scene) async {
      await scene.alignOn();
      await scene.select(_stamp());
      scene.sliderAt(0).onChanged!(2.6);
      expect(scene.options.gridOffsetX.value, 3);
      scene.sliderAt(0).onChanged!(2.4);
      expect(scene.options.gridOffsetX.value, 2);
      scene.sliderAt(1).onChanged!(1.6);
      expect(scene.options.gridOffsetY.value, 2);
      scene.sliderAt(1).onChanged!(1.4);
      expect(scene.options.gridOffsetY.value, 1);
    });

    stampTest("follow the selected stamp", (final _Scene scene) async {
      await scene.alignOn();
      await scene.select(_stamp());
      await scene.select(_stamp(width: 4, height: 8));
      expect(scene.sliderAt(0).max, 3);
      expect(scene.sliderAt(1).max, 7);

      await scene.select(null);
      expect(find.byType(KPixSlider), findsNothing);
      expect(find.text(scene.l10n.offsetX), findsOneWidget);

      await scene.select(_stamp(width: 2, height: 16));
      expect(scene.sliderAt(0).max, 1);
      expect(scene.sliderAt(1).max, 15);
    });

    stampTest("follow grid align", (final _Scene scene) async {
      await scene.select(_stamp());
      await scene.tapSwitch(2);
      expect(scene.options.gridAlign.value, true);
      expect(find.byType(KPixSlider), findsNWidgets(2));

      await scene.tapSwitch(2);
      expect(find.byType(KPixSlider), findsNothing);
      expect(find.text(scene.l10n.offsetX), findsNothing);
    });

    stampTest("show while ctrl switches grid align on", (final _Scene scene) async {
      await scene.select(_stamp());
      scene.hotkeys.controlNotifier.value = true;
      await scene.settle();
      expect(find.byType(KPixSlider), findsNWidgets(2));

      scene.hotkeys.controlNotifier.value = false;
      await scene.settle();
      expect(find.byType(KPixSlider), findsNothing);
      expect(scene.options.unmodifiedGridAlign.value, false);
    });

    stampTest("keep the offsets while hidden", (final _Scene scene) async {
      await scene.select(_stamp());
      scene.options.gridOffsetX.value = 3;
      scene.options.gridOffsetY.value = 2;
      await scene.alignOn();
      expect(scene.sliderAt(0).value, 3);
      expect(scene.sliderAt(1).value, 2);
    });
  });

  group("rebuilds", () {
    Future<void> showAll(final _Scene scene) async
    {
      await scene.alignOn();
      await scene.select(_stamp(thumbnail: scene.thumbnail));
    }

    stampTest("an offset only touches its own slider", (final _Scene scene) async {
      await showAll(scene);
      final KPixSlider x = scene.sliderAt(0);
      final KPixSlider y = scene.sliderAt(1);
      final RawImage image = scene.image;
      final Switch flipH = scene.switchAt(0);

      scene.options.gridOffsetX.value = 1;
      await scene.settle();
      expect(identical(scene.sliderAt(0), x), false);
      expect(identical(scene.sliderAt(1), y), true);
      expect(identical(scene.image, image), true);
      expect(identical(scene.switchAt(0), flipH), true);

      final KPixSlider x2 = scene.sliderAt(0);
      scene.options.gridOffsetY.value = 1;
      await scene.settle();
      expect(identical(scene.sliderAt(0), x2), true);
      expect(identical(scene.sliderAt(1), y), false);
    });

    stampTest("a flip only touches its switch and the preview", (final _Scene scene) async {
      await showAll(scene);
      final Switch flipH = scene.switchAt(0);
      final Switch flipV = scene.switchAt(1);
      final RawImage image = scene.image;
      final KPixSlider x = scene.sliderAt(0);

      scene.options.flipH.value = true;
      await scene.settle();
      expect(identical(scene.switchAt(0), flipH), false);
      expect(identical(scene.switchAt(1), flipV), true);
      expect(identical(scene.image, image), false);
      expect(identical(scene.sliderAt(0), x), true);
    });

    stampTest("a stamp touches the preview and the sliders, not the switches", (final _Scene scene) async {
      await showAll(scene);
      final Switch flipH = scene.switchAt(0);
      final Switch align = scene.switchAt(2);
      final RawImage image = scene.image;
      final KPixSlider x = scene.sliderAt(0);
      final KPixSlider y = scene.sliderAt(1);

      await scene.select(_stamp(thumbnail: scene.thumbnail));
      expect(identical(scene.image, image), false);
      expect(identical(scene.sliderAt(0), x), false);
      expect(identical(scene.sliderAt(1), y), false);
      expect(identical(scene.switchAt(0), flipH), true);
      expect(identical(scene.switchAt(2), align), true);
    });

    stampTest("grid align does not touch the preview", (final _Scene scene) async {
      await showAll(scene);
      final RawImage image = scene.image;
      final Switch flipH = scene.switchAt(0);

      scene.options.gridAlign.value = false;
      await scene.settle();
      expect(identical(scene.image, image), true);
      expect(identical(scene.switchAt(0), flipH), true);
    });
  });

  group("loading a stamp in the manager", () {
    /// Offers a big and a small stamp, with the big one selected and grid align on.
    Future<void> prepare(final _Scene scene, {required final List<StampManagerEntryData> stamps}) async
    {
      scene.manager.stampMap.value = <String, List<StampManagerEntryData>>{"folder": stamps};
      scene.manager.selectedFolder.value = "folder";
      scene.manager.selectedStamp.value = stamps.first;
      await scene.settle();
      await scene.tapSwitch(2);
    }

    Future<void> load(final _Scene scene, {required final String name}) async
    {
      await scene.tester.tap(find.byType(OutlinedButton));
      await scene.settle();
      await scene.settle();
      await scene.tester.tap(find.text(name));
      await scene.settle();
      await scene.tester.tap(find.byTooltip(scene.l10n.loadSelectedStamp));
      await scene.settle();
      await scene.settle();
    }

    stampTest("lowers the offsets that no longer fit", (final _Scene scene) async {
      final StampManagerEntryData small = _stamp(name: "small", width: 4, height: 2);
      await prepare(scene, stamps: <StampManagerEntryData>[_stamp(name: "big"), small]);
      scene.options.gridOffsetX.value = 7;
      scene.options.gridOffsetY.value = 3;
      await scene.settle();

      await load(scene, name: "small");
      expect(identical(scene.manager.selectedStamp.value, small), true);
      expect(find.byType(StampManagerWidget), findsNothing);
      expect(scene.options.gridOffsetX.value, 3);
      expect(scene.options.gridOffsetY.value, 1);
      expect(scene.sliderAt(0).value, 3);
      expect(scene.sliderAt(0).max, 3);
      expect(scene.sliderAt(1).value, 1);
      expect(scene.sliderAt(1).max, 1);
    }, viaSettings: true,);

    stampTest("lowers each axis on its own", (final _Scene scene) async {
      await prepare(scene, stamps: <StampManagerEntryData>[_stamp(name: "big"), _stamp(name: "narrow", width: 2)]);
      scene.options.gridOffsetX.value = 7;
      scene.options.gridOffsetY.value = 3;
      await scene.settle();

      await load(scene, name: "narrow");
      expect(scene.options.gridOffsetX.value, 1);
      expect(scene.options.gridOffsetY.value, 3);
    }, viaSettings: true,);

    stampTest("leaves the offsets that still fit", (final _Scene scene) async {
      await prepare(scene, stamps: <StampManagerEntryData>[_stamp(name: "big"), _stamp(name: "small", width: 4, height: 2)]);
      scene.options.gridOffsetX.value = 3;
      scene.options.gridOffsetY.value = 1;
      await scene.settle();

      await load(scene, name: "small");
      expect(scene.options.gridOffsetX.value, 3);
      expect(scene.options.gridOffsetY.value, 1);
    }, viaSettings: true,);

    stampTest("leaves the offsets for a bigger stamp", (final _Scene scene) async {
      await prepare(scene, stamps: <StampManagerEntryData>[_stamp(name: "small", width: 4, height: 2), _stamp(name: "big")]);
      scene.options.gridOffsetX.value = 3;
      scene.options.gridOffsetY.value = 1;
      await scene.settle();

      await load(scene, name: "big");
      expect(scene.options.gridOffsetX.value, 3);
      expect(scene.options.gridOffsetY.value, 1);
    }, viaSettings: true,);

    stampTest("lowers the offsets to zero for a single pixel", (final _Scene scene) async {
      await prepare(scene, stamps: <StampManagerEntryData>[_stamp(name: "big"), _stamp(name: "pixel", width: 1, height: 1)]);
      scene.options.gridOffsetX.value = 7;
      scene.options.gridOffsetY.value = 3;
      await scene.settle();

      await load(scene, name: "pixel");
      expect(scene.options.gridOffsetX.value, 0);
      expect(scene.options.gridOffsetY.value, 0);
    }, viaSettings: true,);

    stampTest("also lowers offsets that are hidden at the moment", (final _Scene scene) async {
      await prepare(scene, stamps: <StampManagerEntryData>[_stamp(name: "big"), _stamp(name: "small", width: 4, height: 2)]);
      scene.options.gridOffsetX.value = 7;
      scene.options.gridOffsetY.value = 3;
      await scene.tapSwitch(2);
      expect(find.byType(KPixSlider), findsNothing);

      await load(scene, name: "small");
      expect(scene.options.gridOffsetX.value, 3);

      await scene.tapSwitch(2);
      expect(scene.sliderAt(0).value, 3);
      expect(scene.sliderAt(1).value, 1);
    }, viaSettings: true,);

    stampTest("leaves everything when the manager is only closed", (final _Scene scene) async {
      final StampManagerEntryData big = _stamp(name: "big");
      await prepare(scene, stamps: <StampManagerEntryData>[big, _stamp(name: "small", width: 4, height: 2)]);
      scene.options.gridOffsetX.value = 7;
      await scene.settle();

      await scene.tester.tap(find.byType(OutlinedButton));
      await scene.settle();
      await scene.settle();
      await scene.tester.tap(find.text("small"));
      await scene.settle();
      await scene.tester.tap(find.byTooltip(scene.l10n.close));
      await scene.settle();
      await scene.settle();
      expect(identical(scene.manager.selectedStamp.value, big), true);
      expect(scene.options.gridOffsetX.value, 7);
    }, viaSettings: true,);
  });

  group("the size", () {
    stampTest("stays hidden", (final _Scene scene) async {
      expect(find.text(scene.l10n.scale), findsNothing);
    });

    stampTest("changes within its limits", (final _Scene scene) async {
      expect(scene.options.getSize(), StampConstraints.scaleDefault);
      scene.options.changeSize(steps: 2, originalValue: 3);
      expect(scene.options.getSize(), 5);
      scene.options.changeSize(steps: 100, originalValue: 3);
      expect(scene.options.getSize(), StampConstraints.scaleMax);
      scene.options.changeSize(steps: -100, originalValue: 3);
      expect(scene.options.getSize(), StampConstraints.scaleMin);
    });
  });
}
