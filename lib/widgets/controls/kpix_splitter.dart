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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class KPixSplitter extends StatefulWidget {
  final Widget left;
  final Widget right;
  final Widget center;
  final double ratioLeft;
  final double ratioRight;
  final double minRatioLeft;
  final double maxRatioLeft;
  final double minRatioRight;
  final double maxRatioRight;
  final double dividerWidth;

  const KPixSplitter({super.key, required this.left, required this.right, required this.center, this.ratioLeft = 0.3, this.ratioRight = 0.3, this.minRatioLeft = 0.05, this.maxRatioLeft = 0.45, this.minRatioRight = 0.05, this.maxRatioRight = 0.45, this.dividerWidth = 8.0})
  : assert(minRatioLeft < maxRatioLeft),
    assert(minRatioLeft >= 0.0),
    assert(maxRatioLeft <= 1.0),
    assert(minRatioLeft <= ratioLeft),
    assert(ratioLeft <= maxRatioLeft),
    assert(minRatioRight >= 0.0),
    assert(maxRatioRight <= 1.0),
    assert(minRatioRight <= ratioRight),
    assert(ratioRight <= maxRatioRight),
    assert(maxRatioLeft + maxRatioLeft <= 1.0)
    ;


  @override
  _KPixSplitterState createState() => _KPixSplitterState();
}

class _KPixSplitterState extends State<KPixSplitter> {
  final ValueNotifier<double> _ratioLeft = ValueNotifier<double>(0.3);
  final ValueNotifier<double> _ratioRight = ValueNotifier<double>(0.3);

  @override
  void initState() {
    super.initState();
    _ratioLeft.value = widget.ratioLeft;
    _ratioRight.value = widget.ratioRight;
  }

  void _panUpdateLeft({required final DragUpdateDetails details, required final double maxWidth})
  {
    final double curVal = _ratioLeft.value + details.delta.dx / maxWidth;
    _ratioLeft.value = curVal.clamp(widget.minRatioLeft, widget.maxRatioLeft);
  }

  void _panUpdateRight({required final DragUpdateDetails details, required final double maxWidth})
  {
    final double curVal =  _ratioRight.value - details.delta.dx / maxWidth;
    _ratioRight.value = curVal.clamp(widget.minRatioRight, widget.maxRatioRight);
  }

  @override
  Widget build(final BuildContext context)
  {
    return ValueListenableBuilder<double>(
      valueListenable: _ratioLeft,
      builder: (final BuildContext context, final double ratioLeft, final Widget? child)
      {
        return ValueListenableBuilder<double>(
          valueListenable: _ratioRight,
          builder: (final BuildContext context, final double ratioRight, final Widget? child)
          {
            return LayoutBuilder(builder: (final BuildContext context, final BoxConstraints constraints)
            {
              final double maxWidth = constraints.maxWidth - widget.dividerWidth;
              return SizedBox(
                width: constraints.maxWidth,
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: ratioLeft * maxWidth,
                      child: widget.left,
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          color: Theme.of(context).primaryColor,
                          width: widget.dividerWidth,
                          height: constraints.maxHeight,
                          child: Center(child: FaIcon(FontAwesomeIcons.ellipsisVertical, color: Theme.of(context).primaryColorLight, size: widget.dividerWidth * 2,),),
                        ),

                        onPanUpdate: (final DragUpdateDetails details) {
                          _panUpdateLeft(details: details, maxWidth: maxWidth);
                        },
                      ),
                    ),
                    Expanded(child: ClipRect(child: widget.center)),
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          color: Theme.of(context).primaryColor,
                          width: widget.dividerWidth,
                          height: constraints.maxHeight,
                          child: Center(child: FaIcon(FontAwesomeIcons.ellipsisVertical, color: Theme.of(context).primaryColorLight, size: widget.dividerWidth * 2,),),
                        ),
                        onPanUpdate: (final DragUpdateDetails details) {
                          _panUpdateRight(details: details, maxWidth: maxWidth);
                        },
                      ),
                    ),
                    SizedBox(
                      width: ratioRight * maxWidth,
                      child: widget.right,
                    ),
                  ],
                ),
              );
            },);
          },
        );
      },
    );
  }
}
