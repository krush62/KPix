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

/// Puts [text] into [controller] with the caret behind it, unless it is already
/// there, so that text being typed keeps its caret.
void showTextInController({required final TextEditingController controller, required final String text})
{
  if (controller.text != text)
  {
    controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// A [TextField] editing the string in [text].
///
/// It keeps one controller for its whole life: a new one per change would lose
/// the caret, the selection and any composing text.
class KPixTextField extends StatefulWidget
{
  final ValueNotifier<String> text;
  final FocusNode? focusNode;
  final TextAlign textAlign;
  final TextStyle? style;
  final int? maxLength;
  /// Called after [text] was updated.
  final ValueChanged<String>? onChanged;

  const KPixTextField({
    super.key,
    required this.text,
    this.focusNode,
    this.textAlign = TextAlign.start,
    this.style,
    this.maxLength,
    this.onChanged,
  });

  @override
  State<KPixTextField> createState() => _KPixTextFieldState();
}

class _KPixTextFieldState extends State<KPixTextField>
{
  final TextEditingController _controller = TextEditingController();

  @override
  void initState()
  {
    super.initState();
    widget.text.addListener(_textChanged);
    _textChanged();
  }

  @override
  void didUpdateWidget(final KPixTextField oldWidget)
  {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text)
    {
      oldWidget.text.removeListener(_textChanged);
      widget.text.addListener(_textChanged);
      _textChanged();
    }
  }

  @override
  void dispose()
  {
    widget.text.removeListener(_textChanged);
    _controller.dispose();
    super.dispose();
  }

  void _textChanged()
  {
    showTextInController(controller: _controller, text: widget.text.value);
  }

  @override
  Widget build(final BuildContext context)
  {
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      textAlign: widget.textAlign,
      style: widget.style,
      maxLength: widget.maxLength,
      onChanged: (final String value) {
        widget.text.value = value;
        widget.onChanged?.call(value);
      },
    );
  }
}
