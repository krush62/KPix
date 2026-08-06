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

/// Marks the widget a popup menu is anchored to.
///
/// The [anchorKey] is handed to the corresponding [AnchoredOverlayBox], which
/// looks up the position of this widget to place itself.
class OverlayAnchor extends StatelessWidget
{
  final GlobalKey anchorKey;
  final Widget child;
  const OverlayAnchor({super.key, required this.anchorKey, required this.child});

  @override
  Widget build(final BuildContext context)
  {
    return KeyedSubtree(key: anchorKey, child: child);
  }
}

/// Positions [child] inside an overlay [Stack] relative to the [OverlayAnchor]
/// carrying [anchorKey].
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
  final GlobalKey anchorKey;
  final Offset offset;
  final double? width;
  final double? height;
  final Widget child;

  const AnchoredOverlayBox({
    super.key,
    required this.anchorKey,
    required this.child,
    this.offset = Offset.zero,
    this.width,
    this.height,
  });

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

  Offset? _getAnchorOffset()
  {
    final RenderObject? anchorObject = widget.anchorKey.currentContext?.findRenderObject();
    final RenderObject? overlayObject = Overlay.of(context).context.findRenderObject();
    if (anchorObject is! RenderBox || overlayObject is! RenderBox || !anchorObject.attached || !anchorObject.hasSize || !overlayObject.hasSize)
    {
      return null;
    }
    return anchorObject.localToGlobal(Offset.zero, ancestor: overlayObject);
  }

  @override
  Widget build(final BuildContext context)
  {
    final Offset? anchorOffset = _getAnchorOffset();
    if (anchorOffset == null)
    {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: anchorOffset.dx + widget.offset.dx,
      top: anchorOffset.dy + widget.offset.dy,
      width: widget.width,
      height: widget.height,
      child: widget.child,
    );
  }
}
