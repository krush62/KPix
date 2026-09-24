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

import 'package:flutter/material.dart';

/// A marker for the widget a popup menu is anchored to.
///
/// The same [anchorKey] is handed to the [AnchoredOverlayBox] of the menu,
/// which looks up the position of [child] to place itself.
class OverlayAnchor extends StatelessWidget
{
  /// The key under which the position of [child] is published.
  final GlobalKey anchorKey;

  /// The widget a menu is anchored to, usually the button that opens it.
  final Widget child;

  const OverlayAnchor({super.key, required this.anchorKey, required this.child});

  @override
  Widget build(final BuildContext context)
  {
    return KeyedSubtree(key: anchorKey, child: child);
  }
}

/// A [Stack] child that places [child] relative to the [OverlayAnchor] carrying
/// [anchorKey].
///
/// Only usable inside an overlay [Stack], since the anchor position is resolved
/// against the surrounding [Overlay] and handed on to a [Positioned]. Until the
/// anchor has been laid out, nothing is shown.
///
/// This is used instead of [CompositedTransformFollower], because a
/// [RenderFollowerLayer] only establishes its paint transform after the layout
/// phase. [Tooltip] however is laid out via
/// `OverlayPortal.overlayChildLayoutBuilder`, which needs the paint transform
/// of its child while layout is still running. Every tooltip below a follower
/// therefore throws ("The paint transform cannot be reliably computed because
/// of RenderFollowerLayer(s)") instead of showing up.
class AnchoredOverlayBox extends StatefulWidget
{
  /// The key of the [OverlayAnchor] to place [child] relative to.
  final GlobalKey anchorKey;

  /// The distance between the top left corner of the anchor and the top left
  /// corner of [child]; horizontally measured from the centred position when
  /// [centerHorizontally] is set.
  final Offset offset;

  /// Whether [child] is centred horizontally on the anchor, which needs a
  /// [width].
  final bool centerHorizontally;

  /// The width of [child], or `null` to let it size itself.
  final double? width;

  /// The height of [child], or `null` to let it size itself.
  final double? height;

  /// The menu to be placed.
  final Widget child;

  const AnchoredOverlayBox({
    super.key,
    required this.anchorKey,
    required this.child,
    this.offset = Offset.zero,
    this.width,
    this.height,
    this.centerHorizontally = false,
  }) : assert(!centerHorizontally || width != null, "centering needs a width");

  @override
  State<AnchoredOverlayBox> createState() => _AnchoredOverlayBoxState();
}

class _AnchoredOverlayBoxState extends State<AnchoredOverlayBox> with WidgetsBindingObserver
{
  @override
  void initState()
  {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose()
  {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The anchor position is resolved during build, so it has to be refreshed
  /// when the window (and with it the anchor) is resized.
  @override
  void didChangeMetrics()
  {
    setState(() {});
  }

  /// The bounds of the anchor in the coordinate system of the surrounding
  /// [Overlay], or `null` while the anchor is not laid out.
  Rect? _getAnchorRect()
  {
    final RenderObject? anchorObject = widget.anchorKey.currentContext?.findRenderObject();
    final RenderObject? overlayObject = Overlay.of(context).context.findRenderObject();
    if (anchorObject is! RenderBox || overlayObject is! RenderBox || !anchorObject.attached || !anchorObject.hasSize || !overlayObject.hasSize)
    {
      return null;
    }
    return anchorObject.localToGlobal(Offset.zero, ancestor: overlayObject) & anchorObject.size;
  }

  @override
  Widget build(final BuildContext context)
  {
    final Rect? anchorRect = _getAnchorRect();
    if (anchorRect == null)
    {
      return const SizedBox.shrink();
    }
    final double left = widget.centerHorizontally ? anchorRect.center.dx - widget.width! / 2.0 : anchorRect.left;
    return Positioned(
      left: left + widget.offset.dx,
      top: anchorRect.top + widget.offset.dy,
      width: widget.width,
      height: widget.height,
      child: widget.child,
    );
  }
}
