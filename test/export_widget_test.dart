/*
 * KPix
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/l10n/app_localizations.dart';
import 'package:kpix/layer_states/layer_state.dart';
import 'package:kpix/models/app_paths.dart';
import 'package:kpix/models/document_state.dart';
import 'package:kpix/models/export_types.dart';
import 'package:kpix/models/file_constants.dart';
import 'package:kpix/models/time_line_state.dart';
import 'package:kpix/util/file_name_check.dart';
import 'package:kpix/util/helpers/format_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:kpix/widgets/controls/kpix_slider.dart';
import 'package:kpix/widgets/file/export_widget.dart';
import 'package:path/path.dart' as p;
import 'package:toastification/toastification.dart';

import 'support/selection_harness.dart';

/// What the dialog handed over when it was accepted.
class _Export
{
  final Object type;
  final String extension;
  final String fileName;
  final int? scaling;
  final bool? loopOnly;
  const _Export({required this.type, required this.extension, required this.fileName, this.scaling, this.loopOnly});
}

final CoordinateSetI _canvasSize = CoordinateSetI(x: 16, y: 9);

Timeline get _timeline => GetIt.I.get<DocumentState>().timeline;

AppLocalizations _l10n(final WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(ExportWidget)))!;

Finder _button(final String tooltip) => find.byWidgetPredicate((final Widget w) => w is IconButton && w.tooltip == tooltip);

bool _canAccept(final WidgetTester tester) => tester.widget<IconButton>(_button(_l10n(tester).exportFile)).onPressed != null;

Finder _selector<T>() => find.byType(SegmentedButton<T>);

Future<void> _settleDown(final WidgetTester tester) async
{
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tap(final WidgetTester tester, final Finder finder) async
{
  await tester.tap(finder);
  await _settleDown(tester);
}

Future<void> _enterName(final WidgetTester tester, final String name) async
{
  await tester.enterText(find.byType(TextField), name);
  await _settleDown(tester);
}

Future<void> _accept(final WidgetTester tester) => _tap(tester, _button(_l10n(tester).exportFile));

/// A dialog over a booted project, which records what it hands over.
class _Dialog
{
  final List<_Export> exports = <_Export>[];
  final GlobalKey<ExportWidgetState> key = GlobalKey<ExportWidgetState>();
  int dismissed = 0;

  Future<void> pump({required final WidgetTester tester}) async
  {
    await tester.pumpWidget(ToastificationWrapper(child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(child: Center(child: ExportWidget(
        key: key,
        dismiss: () => dismissed++,
        acceptFile: ({required final ImageExportData exportData, required final ImageExportType exportType}) =>
            exports.add(_Export(type: exportType, extension: exportData.extension, fileName: exportData.fileName, scaling: exportData.scaling)),
        acceptPalette: ({required final PaletteExportData saveData, required final PaletteExportType paletteType}) =>
            exports.add(_Export(type: paletteType, extension: saveData.extension, fileName: saveData.fileName)),
        acceptAnimation: ({required final AnimationExportData exportData, required final AnimationExportType exportType}) =>
            exports.add(_Export(type: exportType, extension: exportData.extension, fileName: exportData.fileName, scaling: exportData.scaling, loopOnly: exportData.loopOnly)),
      ),),),
    ),),);
    await _settleDown(tester);
  }
}

Future<_Dialog> _pumpDialog(final WidgetTester tester, {final int frameCount = 1, final int? loopEnd}) async
{
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await bootProject(canvasSize: _canvasSize);
  });

  final Directory directory = Directory.systemTemp.createTempSync("kpix_export_test");
  addTearDown(() => directory.deleteSync(recursive: true));
  for (final String extension in <String>["png", "gif", fileExtensionKpal, fileExtensionKpix])
  {
    File(p.join(directory.path, "existing.$extension")).writeAsStringSync("x");
  }
  GetIt.I.get<AppPaths>().exportDir = directory.path;

  for (int i = 1; i < frameCount; i++)
  {
    _timeline.addNewFrameRight();
  }
  if (loopEnd != null)
  {
    _timeline.setLoopEndMarker(index: loopEnd);
  }
  final _Dialog dialog = _Dialog();
  await dialog.pump(tester: tester);
  return dialog;
}

Future<void> _close(final WidgetTester tester) async
{
  await tester.pumpWidget(const SizedBox.shrink());
  for (final Frame frame in _timeline.frames.value)
  {
    for (int i = 0; i < frame.layerList.length; i++)
    {
      frame.layerList.getLayer(index: i).dispose();
    }
  }
  await tester.pump(const Duration(seconds: 1));
}

/// Switching sections trips an assertion inside Flutter's semantics code, so
/// these tests run without semantics.
void _testDialog(final String description, final Future<void> Function(WidgetTester tester) body)
{
  testWidgets(description, body, semanticsEnabled: false);
}

void main()
{
  group("sections", () {
    _testDialog("one frame starts on the image section and cannot pick animation", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      expect(_selector<ImageExportType>(), findsOneWidget);
      await _tap(tester, find.byTooltip(_l10n(tester).animation));
      expect(_selector<ImageExportType>(), findsOneWidget);
      expect(_selector<AnimationExportType>(), findsNothing);
      await _close(tester);
    });

    _testDialog("several frames start on the animation section", (final WidgetTester tester) async {
      await _pumpDialog(tester, frameCount: 2);
      expect(_selector<AnimationExportType>(), findsOneWidget);
      expect(_selector<ImageExportType>(), findsNothing);
      await _close(tester);
    });

    _testDialog("each section shows its own title and formats", (final WidgetTester tester) async {
      await _pumpDialog(tester, frameCount: 2);
      final AppLocalizations l10n = _l10n(tester);
      final Map<String, Finder> sections = <String, Finder>{
        l10n.image: _selector<ImageExportType>(),
        l10n.palette: _selector<PaletteExportType>(),
        l10n.kpixProject: _selector<KPixExportType>(),
        l10n.animation: _selector<AnimationExportType>(),
      };
      for (final MapEntry<String, Finder> section in sections.entries)
      {
        await _tap(tester, find.byTooltip(section.key));
        expect(section.value, findsOneWidget, reason: section.key);
        expect(find.text("${l10n.export.toUpperCase()} ${section.key.toUpperCase()}"), findsOneWidget, reason: section.key);
        for (final Finder other in sections.values)
        {
          if (other != section.value)
          {
            expect(other, findsNothing, reason: section.key);
          }
        }
      }
      await _close(tester);
    });
  });

  group("formats", () {
    _testDialog("each image format is handed over as itself", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester);
      final AppLocalizations l10n = _l10n(tester);
      await _enterName(tester, "out");
      expect(tester.widget<SegmentedButton<ImageExportType>>(_selector<ImageExportType>()).segments.map((final ButtonSegment<ImageExportType> s) => s.value), <ImageExportType>[ImageExportType.png, ImageExportType.webp, ImageExportType.aseprite, ImageExportType.photoshop, ImageExportType.gimp, ImageExportType.pixelorama]);
      for (final ImageExportType type in <ImageExportType>[ImageExportType.webp, ImageExportType.aseprite, ImageExportType.photoshop, ImageExportType.gimp, ImageExportType.pixelorama, ImageExportType.png])
      {
        await _tap(tester, find.text(getImageExportTypeLabel(type: type, l10n: l10n)));
        await _accept(tester);
        expect(dialog.exports.last.type, type);
        expect(dialog.exports.last.extension, ImageExportData.exportTypeMap[type]!.extension);
        expect(dialog.exports.last.fileName, "out");
        expect(find.text(".${ImageExportData.exportTypeMap[type]!.extension}"), findsOneWidget);
      }
      await _close(tester);
    });

    _testDialog("each animation format is handed over as itself", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester, frameCount: 2);
      final AppLocalizations l10n = _l10n(tester);
      await _enterName(tester, "out");
      expect(tester.widget<SegmentedButton<AnimationExportType>>(_selector<AnimationExportType>()).segments.map((final ButtonSegment<AnimationExportType> s) => s.value), <AnimationExportType>[AnimationExportType.gif, AnimationExportType.apng, AnimationExportType.webp, AnimationExportType.zippedPng]);
      for (final AnimationExportType type in <AnimationExportType>[AnimationExportType.apng, AnimationExportType.webp, AnimationExportType.zippedPng, AnimationExportType.gif])
      {
        await _tap(tester, find.text(getAnimationExportTypeLabel(type: type, l10n: l10n)));
        await _accept(tester);
        expect(dialog.exports.last.type, type);
        expect(dialog.exports.last.extension, AnimationExportData.exportTypeMap[type]!.extension);
        expect(find.text(".${AnimationExportData.exportTypeMap[type]!.extension}"), findsOneWidget);
      }
      await _close(tester);
    });

    _testDialog("each palette format is handed over as itself", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester);
      await _enterName(tester, "out");
      await _tap(tester, find.byTooltip(_l10n(tester).palette));
      for (final PaletteExportType type in PaletteExportType.values.reversed)
      {
        await _tap(tester, find.text(PaletteExportData.exportTypeMap[type]!.name));
        await _accept(tester);
        expect(dialog.exports.last.type, type);
        expect(dialog.exports.last.extension, PaletteExportData.exportTypeMap[type]!.extension);
        expect(find.text(".${PaletteExportData.exportTypeMap[type]!.extension}"), findsOneWidget);
      }
      await _close(tester);
    });

    _testDialog("the project formats are handed over as images or animations", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester, frameCount: 2);
      final AppLocalizations l10n = _l10n(tester);
      await _enterName(tester, "out");
      await _tap(tester, find.byTooltip(l10n.kpixProject));

      await _accept(tester);
      expect(dialog.exports.last.type, ImageExportType.kpix);
      expect(find.text(".$fileExtensionKpix"), findsOneWidget);

      await _tap(tester, find.text(l10n.texturePack.toUpperCase()));
      await _accept(tester);
      expect(dialog.exports.last.type, ImageExportType.texturePack);
      expect(find.text(".${ImageExportData.exportTypeMap[ImageExportType.texturePack]!.extension}"), findsOneWidget);

      await _tap(tester, find.text(l10n.texturePackAnimation.toUpperCase()));
      await _accept(tester);
      expect(dialog.exports.last.type, AnimationExportType.texturePack);
      await _close(tester);
    });

    _testDialog("the selected format is the one drawn in the dark color", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      final AppLocalizations l10n = _l10n(tester);
      final ThemeData theme = Theme.of(tester.element(find.byType(ExportWidget)));
      Color? colorOf(final ImageExportType type) => tester.widget<Text>(find.text(getImageExportTypeLabel(type: type, l10n: l10n))).style!.color;
      expect(colorOf(ImageExportType.png), theme.primaryColorDark);
      expect(colorOf(ImageExportType.webp), theme.primaryColorLight);
      await _tap(tester, find.text(getImageExportTypeLabel(type: ImageExportType.webp, l10n: l10n)));
      expect(colorOf(ImageExportType.png), theme.primaryColorLight);
      expect(colorOf(ImageExportType.webp), theme.primaryColorDark);
      await _close(tester);
    });

    _testDialog("the extension belongs to the section", (final WidgetTester tester) async {
      await _pumpDialog(tester, frameCount: 2);
      final AppLocalizations l10n = _l10n(tester);
      expect(find.text(".gif"), findsOneWidget);
      await _tap(tester, find.byTooltip(l10n.image));
      expect(find.text(".png"), findsOneWidget);
      await _tap(tester, find.byTooltip(l10n.palette));
      expect(find.text(".$fileExtensionKpal"), findsOneWidget);
      await _tap(tester, find.byTooltip(l10n.kpixProject));
      expect(find.text(".$fileExtensionKpix"), findsOneWidget);
      await _close(tester);
    });
  });

  group("scaling", () {
    String dimension(final int factor) => formatDimension(width: _canvasSize.x * factor, height: _canvasSize.y * factor);

    _testDialog("a scalable image follows the slider, in the row and in the export", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester);
      await _enterName(tester, "out");
      expect(find.text(dimension(1)), findsOneWidget);
      await tester.drag(find.byType(KPixSlider), const Offset(60, 0));
      await _settleDown(tester);

      final KPixSlider slider = tester.widget<KPixSlider>(find.byType(KPixSlider));
      final int factor = exportScalingValues[slider.value.round()];
      expect(factor, greaterThan(1));
      expect(slider.label, "$factor:1");
      expect(find.text(dimension(factor)), findsOneWidget);
      await _accept(tester);
      expect(dialog.exports.last.scaling, factor);
      await _close(tester);
    });

    _testDialog("a format that cannot scale locks the slider and shows the plain size", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      final AppLocalizations l10n = _l10n(tester);
      await tester.drag(find.byType(KPixSlider), const Offset(60, 0));
      await _settleDown(tester);
      final double scaled = tester.widget<KPixSlider>(find.byType(KPixSlider)).value;
      expect(scaled, greaterThan(0));

      await _tap(tester, find.text(getImageExportTypeLabel(type: ImageExportType.aseprite, l10n: l10n)));
      KPixSlider slider = tester.widget<KPixSlider>(find.byType(KPixSlider));
      expect(slider.onChanged, isNull);
      expect(slider.value, 0);
      expect(find.text(dimension(1)), findsOneWidget);

      await _tap(tester, find.text(getImageExportTypeLabel(type: ImageExportType.png, l10n: l10n)));
      slider = tester.widget<KPixSlider>(find.byType(KPixSlider));
      expect(slider.onChanged, isNotNull);
      expect(slider.value, scaled);
      await _close(tester);
    });

    _testDialog("an animation follows the slider as well", (final WidgetTester tester) async {
      await _pumpDialog(tester, frameCount: 2);
      await tester.drag(find.byType(KPixSlider), const Offset(60, 0));
      await _settleDown(tester);
      final KPixSlider slider = tester.widget<KPixSlider>(find.byType(KPixSlider));
      expect(slider.onChanged, isNotNull);
      expect(find.text(dimension(exportScalingValues[slider.value.round()])), findsOneWidget);
      await _close(tester);
    });

    _testDialog("the row only shows for images and animations", (final WidgetTester tester) async {
      await _pumpDialog(tester, frameCount: 2);
      final AppLocalizations l10n = _l10n(tester);
      double opacity() => tester.widget<Opacity>(find.ancestor(of: find.text(l10n.scaling), matching: find.byType(Opacity))).opacity;
      expect(opacity(), 1.0);
      await _tap(tester, find.byTooltip(l10n.image));
      expect(opacity(), 1.0);
      await _tap(tester, find.byTooltip(l10n.palette));
      expect(opacity(), 0.0);
      await _tap(tester, find.byTooltip(l10n.kpixProject));
      expect(opacity(), 0.0);
      await _close(tester);
    });
  });

  group("selection only", () {
    bool canSwitch(final WidgetTester tester) => tester.widget<Switch>(find.byType(Switch)).onChanged != null;

    _testDialog("needs a loop of several frames that is not the whole timeline", (final WidgetTester tester) async {
      await _pumpDialog(tester, frameCount: 3);
      expect(canSwitch(tester), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());

      _timeline.setLoopEndMarker(index: 1);
      await _Dialog().pump(tester: tester);
      expect(canSwitch(tester), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());

      _timeline.setLoopEndMarker(index: 0);
      await _Dialog().pump(tester: tester);
      expect(canSwitch(tester), isFalse);
      await _close(tester);
    });

    _testDialog("changes the frame count and what is handed over", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester, frameCount: 3, loopEnd: 1);
      final AppLocalizations l10n = _l10n(tester);
      await _enterName(tester, "out");
      expect(find.textContaining(l10n.nFrames(3)), findsOneWidget);
      await _accept(tester);
      expect(dialog.exports.last.loopOnly, isFalse);

      await _tap(tester, find.byType(Switch));
      expect(find.textContaining(l10n.nFrames(2)), findsOneWidget);
      await _accept(tester);
      expect(dialog.exports.last.loopOnly, isTrue);
      await _close(tester);
    });

    _testDialog("only shows for animations and animated texture packs", (final WidgetTester tester) async {
      await _pumpDialog(tester, frameCount: 2);
      final AppLocalizations l10n = _l10n(tester);
      double opacity() => tester.widget<Opacity>(find.ancestor(of: find.text(l10n.selectionOnly), matching: find.byType(Opacity))).opacity;
      expect(opacity(), 1.0);
      await _tap(tester, find.byTooltip(l10n.image));
      expect(opacity(), 0.0);
      await _tap(tester, find.byTooltip(l10n.kpixProject));
      expect(opacity(), 0.0);
      await _tap(tester, find.text(l10n.texturePackAnimation.toUpperCase()));
      expect(opacity(), 1.0);
      await _tap(tester, find.text(l10n.texturePack.toUpperCase()));
      expect(opacity(), 0.0);
      await _close(tester);
    });

    _testDialog("decides whether an animated texture pack is possible", (final WidgetTester tester) async {
      await _pumpDialog(tester, frameCount: 3, loopEnd: 1);
      final AppLocalizations l10n = _l10n(tester);
      Map<KPixExportType, bool> usable() => <KPixExportType, bool>{
        for (final ButtonSegment<KPixExportType> s in tester.widget<SegmentedButton<KPixExportType>>(_selector<KPixExportType>()).segments) s.value: s.enabled,
      };
      await tester.pumpWidget(const SizedBox.shrink());
      //the hidden layer is on a frame outside of the loop
      _timeline.frames.value[2].layerList.getLayer(index: 0).visibilityState.value = LayerVisibilityState.hidden;
      _timeline.selectFrameByIndex(index: 0);
      await _Dialog().pump(tester: tester);
      await _tap(tester, find.byTooltip(l10n.kpixProject));
      expect(usable(), <KPixExportType, bool>{KPixExportType.kpix: true, KPixExportType.texturePack: true, KPixExportType.texturePackAnimated: false});

      await _tap(tester, find.byType(Switch));
      expect(usable()[KPixExportType.texturePackAnimated], isTrue);
      await _tap(tester, find.byType(Switch));
      expect(usable()[KPixExportType.texturePackAnimated], isFalse);
      await _close(tester);
    });

    _testDialog("a project with one frame has no animated texture pack", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      await _tap(tester, find.byTooltip(_l10n(tester).kpixProject));
      final Iterable<ButtonSegment<KPixExportType>> segments = tester.widget<SegmentedButton<KPixExportType>>(_selector<KPixExportType>()).segments;
      expect(segments.map((final ButtonSegment<KPixExportType> s) => s.enabled), <bool>[true, true, false]);
      await _close(tester);
    });

    _testDialog("a hidden layer on the selected frame locks the texture pack", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      final AppLocalizations l10n = _l10n(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      _timeline.selectedFrame!.layerList.getLayer(index: 0).visibilityState.value = LayerVisibilityState.hidden;
      await _Dialog().pump(tester: tester);
      await _tap(tester, find.byTooltip(l10n.kpixProject));
      final Iterable<ButtonSegment<KPixExportType>> segments = tester.widget<SegmentedButton<KPixExportType>>(_selector<KPixExportType>()).segments;
      expect(segments.elementAt(1).enabled, isFalse);
      await _close(tester);
    });
  });

  group("file name", () {
    String statusTooltip(final WidgetTester tester, final FileNameStatus status) => status.label(_l10n(tester));

    _testDialog("an unusable name locks the accept button, an existing file does not", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester);
      expect(_canAccept(tester), isFalse);
      expect(find.byTooltip(statusTooltip(tester, FileNameStatus.forbidden)), findsOneWidget);

      await _enterName(tester, "fresh");
      expect(_canAccept(tester), isTrue);
      expect(find.byTooltip(statusTooltip(tester, FileNameStatus.available)), findsOneWidget);

      await _enterName(tester, "existing");
      expect(_canAccept(tester), isTrue);
      expect(find.byTooltip(statusTooltip(tester, FileNameStatus.overwrite)), findsOneWidget);

      await _enterName(tester, "bad:name");
      expect(_canAccept(tester), isFalse);
      expect(dialog.exports, isEmpty);
      await _close(tester);
    });

    _testDialog("the status follows the extension of section and format", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      final AppLocalizations l10n = _l10n(tester);
      await _enterName(tester, "existing");
      expect(find.byTooltip(statusTooltip(tester, FileNameStatus.overwrite)), findsOneWidget);

      await _tap(tester, find.text(getImageExportTypeLabel(type: ImageExportType.webp, l10n: l10n)));
      expect(find.byTooltip(statusTooltip(tester, FileNameStatus.available)), findsOneWidget);

      await _tap(tester, find.byTooltip(l10n.palette));
      expect(find.byTooltip(statusTooltip(tester, FileNameStatus.overwrite)), findsOneWidget);

      await _tap(tester, find.text(PaletteExportData.exportTypeMap[PaletteExportType.gimp]!.name));
      expect(find.byTooltip(statusTooltip(tester, FileNameStatus.available)), findsOneWidget);
      await _close(tester);
    });

    _testDialog("Enter leaves an existing file alone, the button replaces it", (final WidgetTester tester) async {
      final _Dialog dialog = await _pumpDialog(tester);
      await _enterName(tester, "existing");
      dialog.key.currentState!.accept(allowOverwrite: false);
      expect(dialog.exports, isEmpty);
      await _accept(tester);
      expect(dialog.exports, hasLength(1));

      await _enterName(tester, "fresh");
      dialog.key.currentState!.accept(allowOverwrite: false);
      expect(dialog.exports, hasLength(2));
      await _close(tester);
    });

    _testDialog("the directory follows the export directory", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      final AppPaths paths = GetIt.I.get<AppPaths>();
      expect(find.text(paths.exportDir), findsOneWidget);
      paths.exportDir = "${paths.exportDir}${Platform.pathSeparator}";
      await tester.pump();
      expect(find.text(paths.exportDir), findsOneWidget);
      await _close(tester);
    });
  });

  group("rebuilds", () {
    _testDialog("toggling the selection leaves the animation formats alone", (final WidgetTester tester) async {
      await _pumpDialog(tester, frameCount: 3, loopEnd: 1);
      final Widget before = tester.widget(_selector<AnimationExportType>());
      await _tap(tester, find.byType(Switch));
      expect(identical(tester.widget(_selector<AnimationExportType>()), before), isTrue);
      await _close(tester);
    });

    _testDialog("the accept button only rebuilds for the file name status", (final WidgetTester tester) async {
      await _pumpDialog(tester);
      final AppLocalizations l10n = _l10n(tester);
      await _enterName(tester, "fresh");
      Widget accept() => tester.widget(_button(l10n.exportFile));
      final Widget before = accept();
      await _tap(tester, find.byTooltip(l10n.palette));
      expect(identical(accept(), before), isTrue);
      await _enterName(tester, "");
      expect(identical(accept(), before), isFalse);
      await _close(tester);
    });
  });

  _testDialog("the close button dismisses the dialog", (final WidgetTester tester) async {
    final _Dialog dialog = await _pumpDialog(tester);
    await _tap(tester, find.byTooltip(_l10n(tester).close));
    expect(dialog.dismissed, 1);
    await _close(tester);
  });
}
