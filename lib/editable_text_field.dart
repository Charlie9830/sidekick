import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/widgets/blur_listener.dart';

class EditableTextField extends StatefulWidget {
  final String value;
  final String? hintText;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final TextAlign? textAlign;
  final double? cursorHeight;
  final bool selectAllOnFocus;
  final void Function(String newValue)? onChanged;
  final List<TextInputFormatter> inputFormatters;
  final bool enabled;

  const EditableTextField({
    super.key,
    this.value = '',
    this.hintText,
    this.onChanged,
    this.style,
    this.prefix,
    this.suffix,
    this.textAlign,
    this.cursorHeight,
    this.selectAllOnFocus = false,
    this.inputFormatters = const [],
    this.enabled = true,
  });

  @override
  State<EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.value);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant EditableTextField oldWidget) {
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return BlurListener(
      onBlur: () => widget.onChanged?.call(_controller.text),
      onFocus: () {
        if (widget.selectAllOnFocus) {
          _controller.selection =
              TextSelection(baseOffset: 0, extentOffset: widget.value.length);
        }
      },
      child: TextField(
        enabled: widget.enabled,
        controller: _controller,
        textAlign: widget.textAlign ?? TextAlign.start,
        style: widget.style,
        inputFormatters: widget.inputFormatters,
        cursorHeight: widget.cursorHeight,
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.grey),
          enabledBorder: InputBorder.none,
          prefixText: widget.prefix,
          suffixText: widget.suffix,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
