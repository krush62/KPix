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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kpix/widgets/overlays/overlay_anchor.dart';

const Offset _anchorPosition = Offset(100.0, 50.0);
const Size _anchorSize = Size(40.0, 20.0);
const Offset _menuOffset = Offset(5.0, 20.0);
const String _tooltipMessage = "menu entry";
final GlobalKey _menuKey = GlobalKey();

void main()
{
  testWidgets("menu is placed relative to its anchor", (final WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: _MenuHost()));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byKey(_menuKey)), _anchorPosition + _menuOffset);
  });

  testWidgets("tooltips inside an anchored menu can be shown", (final WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: _MenuHost()));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byIcon(Icons.add)));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text(_tooltipMessage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Shows a popup menu that is anchored to a button, mirroring the structure of
/// the menus in `lib/widgets/overlays`.
class _MenuHost extends StatefulWidget
{
  const _MenuHost();

  @override
  State<_MenuHost> createState() => _MenuHostState();
}

class _MenuHostState extends State<_MenuHost>
{
  final GlobalKey _anchorKey = GlobalKey();
  final OverlayPortalController _controller = OverlayPortalController();

  @override
  Widget build(final BuildContext context)
  {
    return Stack(
      children: <Widget>[
        Positioned(
          left: _anchorPosition.dx,
          top: _anchorPosition.dy,
          width: _anchorSize.width,
          height: _anchorSize.height,
          child: OverlayAnchor(
            anchorKey: _anchorKey,
            child: OverlayPortal(
              controller: _controller,
              overlayChildBuilder: (final BuildContext context) {
                return Stack(
                  children: <Widget>[
                    AnchoredOverlayBox(
                      anchorKey: _anchorKey,
                      offset: _menuOffset,
                      child: Material(
                        key: _menuKey,
                        color: Colors.transparent,
                        child: Tooltip(
                          message: _tooltipMessage,
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              child: ElevatedButton(onPressed: _controller.show, child: const SizedBox()),
            ),
          ),
        ),
      ],
    );
  }
}
