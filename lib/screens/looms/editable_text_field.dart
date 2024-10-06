import 'package:flutter/material.dart';
import 'package:sidekick/widgets/blur_listener.dart';

class EditableTextField extends StatefulWidget {
  final String value;
  final String? hintText;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final TextAlign? textAlign;
  final void Function(String newValue)? onChanged;

  const EditableTextField({
    super.key,
    this.value = '',
    this.hintText,
    this.onChanged,
    this.style,
    this.prefix,
    this.suffix,
    this.textAlign,
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
  Widget build(BuildContext context) {
    return BlurListener(
      onBlur: () => widget.onChanged?.call(_controller.text),
      child: TextField(
        controller: _controller,
        textAlign: widget.textAlign ?? TextAlign.start,
        style: widget.style,
        decoration: InputDecoration(
          hintText: widget.hintText,
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
