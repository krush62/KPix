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

part of 'kpal_widget.dart';

class KPalSliderConstraints
{
  final int minHue;
  final int minSat;
  final int minVal;

  final int maxHue;
  final int maxSat;
  final int maxVal;

  final int defaultHue;
  final int defaultSat;
  final int defaultVal;

  KPalSliderConstraints({
    required this.minHue,
    required this.minSat,
    required this.minVal,
    required this.maxHue,
    required this.maxSat,
    required this.maxVal,
    required this.defaultHue,
    required this.defaultSat,
    required this.defaultVal,
  });
}

class KPalVerticalSliderWidget extends StatefulWidget
{
  final String name;
  final int maxVal;
  final int minVal;
  final ValueNotifier<int> valueNotifier;

  const KPalVerticalSliderWidget({super.key, required this.name, required this.minVal, required this.maxVal, required this.valueNotifier});


  @override
  State<KPalVerticalSliderWidget> createState() => _KPalVerticalSliderWidgetState();
}

class _KPalVerticalSliderWidgetState extends State<KPalVerticalSliderWidget> {
  @override
  Widget build(final BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          widget.name,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            shadows: <Shadow>[
              Shadow(
                offset: const Offset(0.0, 1.0),
                blurRadius: 2.0,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: Theme.of(context).sliderTheme.copyWith(overlayShape: SliderComponentShape.noThumb),
              child: ValueListenableBuilder<int>(
                valueListenable: widget.valueNotifier,
                builder: (final BuildContext context, final int value, final Widget? child) {
                  return PhysicalModel(
                    color: Colors.transparent,
                    elevation: 10,
                    shadowColor: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Slider(
                      value: value.toDouble(),
                      min: widget.minVal.toDouble(),
                      max: widget.maxVal.toDouble(),
                      onChanged: (final double newValue) {
                        widget.valueNotifier.value = newValue.round();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: widget.valueNotifier,
          builder: (final BuildContext context, final int value, final Widget? child) {
            final String prefix  = (value > 0) ? "+" : "";
            return Text(
              prefix + value.toString(),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                shadows: <Shadow>[
                  Shadow(
                    offset: const Offset(0.0, 1.0),
                    blurRadius: 2.0,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
