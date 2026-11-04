/*
 *
 *  * KPix
 *  * This program is free software: you can redistribute it and/or modify
 *  * it under the terms of the GNU Affero General Public License as published by
 *  * the Free Software Foundation, either version 3 of the License, or
 *  * (at your option) any later version.
 *  *
 *  * This program is distributed in the hope that it will be useful,
 *  * but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  * GNU Affero General Public License for more details.
 *  *
 *  * You should have received a copy of the GNU Affero General Public License
 *  * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'
    show
    DragToMoveArea,
    ListenerId,
    Window,
    WindowEvent,
    WindowManager,
    WindowMaximizedEvent,
    WindowResizedEvent,
    WindowRestoredEvent;

/// Size of a caption button (matches the Windows caption button size).
const Size windowButtonSize = Size(46.0, 32.0);

Window? get _currentWindow => WindowManager.instance.getCurrent();

/// Drop-in replacement for bitsdojo's WindowButtonColors (same field names).
class WindowButtonColors
{
  final Color normal;
  final Color mouseOver;
  final Color mouseDown;
  final Color iconNormal;
  final Color iconMouseOver;
  final Color iconMouseDown;

  WindowButtonColors({
    this.normal = Colors.transparent,
    this.mouseOver = const Color(0x1A000000),
    this.mouseDown = const Color(0x33000000),
    this.iconNormal = const Color(0xFF000000),
    final Color? iconMouseOver,
    final Color? iconMouseDown,
  })  : iconMouseOver = iconMouseOver ?? iconNormal,
        iconMouseDown = iconMouseDown ?? iconNormal;
}

enum _WindowIconType { minimize, maximize, restore, close }

/// Replacement for bitsdojo's `WindowTitleBarBox(child: MoveWindow())`.
/// Dragging moves the window, double-click toggles maximize.
class WindowDragArea extends StatelessWidget
{
  const WindowDragArea({super.key});

  @override
  Widget build(final BuildContext context)
  {
    return SizedBox(
      height: windowButtonSize.height,
      child: DragToMoveArea(window: _currentWindow, child: const SizedBox.expand()),
    );
  }
}


class MinimizeWindowButton extends StatelessWidget
{
  final WindowButtonColors colors;
  final VoidCallback? onPressed;

  const MinimizeWindowButton({super.key, required this.colors, this.onPressed});

  @override
  Widget build(final BuildContext context)
  {
    return _WindowButton(
      type: _WindowIconType.minimize,
      colors: colors,
      onPressed: onPressed ?? () => _currentWindow?.minimize(),
    );
  }
}

class CloseWindowButton extends StatelessWidget
{
  final WindowButtonColors colors;
  final VoidCallback? onPressed;

  const CloseWindowButton({super.key, required this.colors, this.onPressed});

  @override
  Widget build(final BuildContext context)
  {
    return _WindowButton(
      type: _WindowIconType.close,
      colors: colors,
      onPressed: onPressed ?? () => _currentWindow?.close(),
    );
  }
}

/// Shows the maximize or restore icon depending on the actual window state.
class MaximizeWindowButton extends StatefulWidget
{
  final WindowButtonColors colors;
  final VoidCallback? onPressed;

  const MaximizeWindowButton({super.key, required this.colors, this.onPressed});

  @override
  State<MaximizeWindowButton> createState() => _MaximizeWindowButtonState();
}

class _MaximizeWindowButtonState extends State<MaximizeWindowButton>
{
  Window? _window;
  ListenerId? _listenerId;
  bool _isMaximized = false;

  @override
  void initState()
  {
    super.initState();
    _window = _currentWindow;
    final Window? window = _window;
    if (window != null)
    {
      _isMaximized = window.isMaximized;
      _listenerId = window.addListener(_onWindowEvent);
    }
  }

  @override
  void dispose()
  {
    final ListenerId? id = _listenerId;
    if (id != null)
    {
      _window?.removeListener(id);
    }
    super.dispose();
  }

  void _onWindowEvent(final WindowEvent event)
  {
    if (event is WindowMaximizedEvent || event is WindowRestoredEvent || event is WindowResizedEvent)
    {
      final bool maximized = _window?.isMaximized ?? false;
      if (mounted && maximized != _isMaximized)
      {
        setState(() => _isMaximized = maximized);
      }
    }
  }

  void _toggle()
  {
    final Window? window = _window;
    if (window == null) return;
    if (window.isMaximized)
    {
      window.restore();
    }
    else
    {
      window.maximize();
    }
  }

  @override
  Widget build(final BuildContext context)
  {
    return _WindowButton(
      type: _isMaximized ? _WindowIconType.restore : _WindowIconType.maximize,
      colors: widget.colors,
      onPressed: widget.onPressed ?? _toggle,
    );
  }
}

class _WindowButton extends StatefulWidget
{
  final _WindowIconType type;
  final WindowButtonColors colors;
  final VoidCallback onPressed;

  const _WindowButton({required this.type, required this.colors, required this.onPressed});

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton>
{
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(final BuildContext context)
  {
    final WindowButtonColors c = widget.colors;
    final Color background = _pressed ? c.mouseDown : (_hovered ? c.mouseOver : c.normal);
    final Color icon = _pressed ? c.iconMouseDown : (_hovered ? c.iconMouseOver : c.iconNormal);

    return MouseRegion(
      onEnter: (final PointerEnterEvent _) => setState(() => _hovered = true),
      onExit: (final PointerExitEvent _) => setState(()
      {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (final TapDownDetails _) => setState(() => _pressed = true),
        onTapUp: (final TapUpDetails _) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: Container(
          width: windowButtonSize.width,
          height: windowButtonSize.height,
          color: background,
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(10.0, 10.0),
            painter: _WindowIconPainter(type: widget.type, color: icon),
          ),
        ),
      ),
    );
  }
}

/// Thin 10x10 caption icons, similar to bitsdojo's / Windows' style.
class _WindowIconPainter extends CustomPainter
{
  final _WindowIconType type;
  final Color color;

  const _WindowIconPainter({required this.type, required this.color});

  @override
  void paint(final Canvas canvas, final Size size)
  {
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = type == _WindowIconType.close;

    switch (type)
    {
      case _WindowIconType.minimize:
        canvas.drawLine(const Offset(0.0, 5.5), const Offset(10.0, 5.5), p);
      case _WindowIconType.maximize:
        canvas.drawRect(const Rect.fromLTWH(0.5, 0.5, 9.0, 9.0), p);
      case _WindowIconType.restore:
        canvas.drawRect(const Rect.fromLTWH(0.5, 2.5, 7.0, 7.0), p);
        canvas.drawPath(
          Path()
            ..moveTo(2.5, 2.5)
            ..lineTo(2.5, 0.5)
            ..lineTo(9.5, 0.5)
            ..lineTo(9.5, 7.5)
            ..lineTo(7.5, 7.5),
          p,
        );
      case _WindowIconType.close:
        canvas.drawLine(Offset.zero, const Offset(10.0, 10.0), p);
        canvas.drawLine(const Offset(10.0, 0.0), const Offset(0.0, 10.0), p);
    }
  }

  @override
  bool shouldRepaint(final _WindowIconPainter old) => old.type != type || old.color != color;
}
