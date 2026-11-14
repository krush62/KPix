/*
 * KPix
 * Copyright (C) 2023-2026 krush62 (Andreas Kruschinski)
 *
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

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kpix/infra/hotkey_manager.dart';
import 'package:kpix/models/status_bar_data.dart';
import 'package:kpix/models/status_bar_state.dart';
import 'package:kpix/models/view_state.dart';
import 'package:kpix/util/helpers/format_helper.dart';
import 'package:kpix/util/helpers/geometry_helper.dart';
import 'package:version/version.dart';

void main()
{
  TestWidgetsFlutterBinding.ensureInitialized();

  group("the zoom", ()
  {
    late ViewState view;
    late StatusBarState statusBar;

    setUp(() async
    {
      await GetIt.I.reset();
      statusBar = StatusBarState();
      GetIt.I.registerSingleton<StatusBarState>(statusBar);
      GetIt.I.registerSingleton<HotkeyManager>(HotkeyManager());
      view = ViewState(devicePixelRatio: 1.0);
    });

    test("starts at the first level and says so", ()
    {
      expect(view.zoomFactor, ViewState.zoomLevelMin);
      expect(statusBar.statusBarZoomFactorString.value, "100%");
    });

    test("goes up step by step and stops at the last level", ()
    {
      expect(view.increaseZoomLevel(), isTrue);
      expect(view.zoomFactor, 2);
      expect(statusBar.statusBarZoomFactorString.value, "200%");

      expect(view.setZoomLevel(val: ViewState.zoomLevelMax), isTrue);
      expect(view.increaseZoomLevel(), isFalse);
      expect(view.zoomFactor, ViewState.zoomLevelMax);
    });

    test("goes down step by step and stops at the first level", ()
    {
      view.setZoomLevel(val: 3);

      expect(view.decreaseZoomLevel(), isTrue);
      expect(view.zoomFactor, 2);
      expect(statusBar.statusBarZoomFactorString.value, "200%");

      expect(view.decreaseZoomLevel(), isTrue);
      expect(view.decreaseZoomLevel(), isFalse);
      expect(view.zoomFactor, ViewState.zoomLevelMin);
    });

    test("can be set directly, within its range", ()
    {
      expect(view.setZoomLevel(val: 16), isTrue);
      expect(view.zoomFactor, 16);
      expect(statusBar.statusBarZoomFactorString.value, "1600%");

      expect(view.setZoomLevel(val: 16), isFalse, reason: "nothing changed");
      expect(view.setZoomLevel(val: ViewState.zoomLevelMin - 1), isFalse);
      expect(view.setZoomLevel(val: ViewState.zoomLevelMax + 1), isFalse);
      expect(view.zoomFactor, 16);
    });

    test("follows a pinch from where it started", ()
    {
      expect(view.setZoomLevelByDistance(startZoomLevel: 4, steps: 3), isTrue);
      expect(view.zoomFactor, 7);
      expect(statusBar.statusBarZoomFactorString.value, "700%");

      expect(view.setZoomLevelByDistance(startZoomLevel: 4, steps: -2), isTrue);
      expect(view.zoomFactor, 2);

      expect(view.setZoomLevelByDistance(startZoomLevel: 4, steps: 0), isFalse, reason: "no steps");
      expect(view.setZoomLevelByDistance(startZoomLevel: 1, steps: 1), isFalse, reason: "that is where it is");
      expect(view.setZoomLevelByDistance(startZoomLevel: 2, steps: -2), isFalse, reason: "below the range");
      expect(view.setZoomLevelByDistance(startZoomLevel: ViewState.zoomLevelMax, steps: 1), isFalse, reason: "above the range");
      expect(view.zoomFactor, 2);
    });

    test("is announced to the canvas", ()
    {
      int notifications = 0;
      final ValueListenable<int> listenable = view.zoomFactorNotifier;
      listenable.addListener(() {notifications++;});

      view.increaseZoomLevel();
      view.setZoomLevel(val: 8);

      expect(notifications, 2);
    });

    test("is not the only thing a view holds", ()
    {
      expect(view.layerSettingsVisible, isFalse);

      view.layerSettingsVisible = true;

      expect(view.layerSettingsVisible, isTrue);
      expect(view.layerSettingsVisibleNotifier.value, isTrue);
    });
  });

  group("the status bar", ()
  {
    late StatusBarState state;

    setUp(()
    {
      state = StatusBarState();
    });

    test("shows and hides the document size", ()
    {
      state.setStatusBarDimensions(width: 16, height: 9);
      expect(state.statusBarDimensionString.value, formatDimension(width: 16, height: 9));

      state.hideStatusBarDimension();
      expect(state.statusBarDimensionString.value, isNull);
    });

    test("shows and hides the zoom", ()
    {
      state.setStatusBarZoomFactor(val: 400);
      expect(state.statusBarZoomFactorString.value, "400%");

      state.hideStatusBarZoomFactor();
      expect(state.statusBarZoomFactorString.value, isNull);
    });

    test("reduces the aspect ratio", ()
    {
      state.setStatusBarToolAspectRatio(width: 16, height: 12);
      expect(state.statusBarToolAspectRatioString.value, "4:3");

      state.setStatusBarToolAspectRatio(width: 7, height: 7);
      expect(state.statusBarToolAspectRatioString.value, "1:1");

      state.setStatusBarToolAspectRatio(width: 0, height: 0);
      expect(state.statusBarToolAspectRatioString.value, "0:0");

      state.setStatusBarToolAspectRatio(width: 5, height: 0);
      expect(state.statusBarToolAspectRatioString.value, "1:0");
    });

    test("rounds the diagonal to one digit", ()
    {
      state.setStatusBarToolDiagonal(3, 4);
      expect(state.statusBarToolDiagonalString.value, "5.0");

      state.setStatusBarToolDiagonal(1, 1);
      expect(state.statusBarToolDiagonalString.value, "1.4");
    });

    test("measures the angle from the start to the end", ()
    {
      state.setStatusBarToolAngle(startPos: CoordinateSetI(x: 0, y: 0), endPos: CoordinateSetI(x: 5, y: 0));
      expect(state.statusBarToolAngleString.value, "0.0°");
    });

    group("after a tool has painted", ()
    {
      test("shows all it reported", ()
      {
        final StatusBarData data = StatusBarData()
          ..cursorPos = CoordinateSetI(x: 5, y: 0)
          ..dimension = CoordinateSetI(x: 6, y: 1)
          ..diagonal = CoordinateSetI(x: 3, y: 4)
          ..aspectRatio = CoordinateSetI(x: 4, y: 2)
          ..angle = CoordinateSetI(x: 0, y: 0);

        state.updateFromPaint(statusBarData: data);

        expect(state.statusBarCursorPositionString.value, "5,0");
        expect(state.statusBarToolDimensionString.value, formatDimension(width: 6, height: 1));
        expect(state.statusBarToolDiagonalString.value, "5.0");
        expect(state.statusBarToolAspectRatioString.value, "2:1");
        expect(state.statusBarToolAngleString.value, "0.0°");
      });

      test("hides what it did not report", ()
      {
        state.updateFromPaint(statusBarData: StatusBarData()
          ..cursorPos = CoordinateSetI(x: 5, y: 0)
          ..dimension = CoordinateSetI(x: 6, y: 1)
          ..diagonal = CoordinateSetI(x: 3, y: 4)
          ..aspectRatio = CoordinateSetI(x: 4, y: 2)
          ..angle = CoordinateSetI(x: 0, y: 0),);

        state.updateFromPaint(statusBarData: StatusBarData());

        expect(state.statusBarCursorPositionString.value, isNull);
        expect(state.statusBarToolDimensionString.value, isNull);
        expect(state.statusBarToolDiagonalString.value, isNull);
        expect(state.statusBarToolAspectRatioString.value, isNull);
        expect(state.statusBarToolAngleString.value, isNull);
      });

      test("has no angle without a cursor", ()
      {
        state.updateFromPaint(statusBarData: StatusBarData()..angle = CoordinateSetI(x: 0, y: 0));

        expect(state.statusBarToolAngleString.value, isNull);
      });
    });
  });

  group("a version from text", ()
  {
    for (final (String, List<int>) valid in <(String, List<int>)>[
      ("1.2.3", <int>[1, 2, 3]),
      ("v1.2.3", <int>[1, 2, 3]),
      ("10.20.30", <int>[10, 20, 30]),
      ("1.2.3.4", <int>[1, 2, 3]),
    ])
    {
      test("reads ${valid.$1}", ()
      {
        final Version? version = convertStringToVersion(version: valid.$1);

        expect(version, isNotNull);
        expect(version!.major, valid.$2[0]);
        expect(version.minor, valid.$2[1]);
        expect(version.patch, valid.$2[2]);
      });
    }

    for (final String invalid in <String>["", "1", "1.2", "1.2.3.4.5", "1.2.x", "V1.2.3", "1.2.3-beta", " 1.2.3", "latest"])
    {
      test("refuses '$invalid'", ()
      {
        expect(convertStringToVersion(version: invalid), isNull);
      });
    }
  });
}
