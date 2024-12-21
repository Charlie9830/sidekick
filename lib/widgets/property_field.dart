import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/widgets/blur_listener.dart';

typedef OnBlurCallback = void Function(String newValue);

class PropertyField extends StatefulWidget {
  final String? value;
  final String label;
  final String suffix;
  final TextAlign textAlign;
  final bool autofocus;
  final List<TextInputFormatter> inputFormatters;
  final OnBlurCallback? onBlur;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;

  const PropertyField({
    Key? key,
    this.value = '',
    this.label = '',
    this.suffix = '',
    this.autofocus = false,
    this.textAlign = TextAlign.left,
    this.inputFormatters = const <TextInputFormatter>[],
    this.onBlur,
    this.controller,
    this.focusNode,
    this.hintText,
  }) : super(key: key);

  @override
  PropertyFieldState createState() => PropertyFieldState();
}

class PropertyFieldState extends State<PropertyField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant PropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return layoutInput(
      context: context,
      child: BlurListener(
        onBlur: () => widget.onBlur?.call(_controller.text),
        child: TextField(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          controller: _controller,
          inputFormatters: widget.inputFormatters,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14),
          textAlignVertical: TextAlignVertical.top,
          textAlign: widget.textAlign,
          decoration: buildInputDecoration(widget.suffix, widget.hintText),
        ),
      ),
      label: widget.label,
    );
  }

  @override
  void dispose() {
    // Dispose of the controller only when one has not been provided by the option [controller] property.
    // If an external controller has been provided, the responsibility is on the caller to dispose of it.
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}

/// The Styling and layout is shared with [AutocompleteTextField]. Hence the Static Methods.
InputDecoration buildInputDecoration(String suffix, String? hintText) {
  return InputDecoration(
    contentPadding: const EdgeInsets.only(left: 12, right: 12),
    suffix: Text(suffix),
    hintText: hintText,
    border: const OutlineInputBorder(
      borderSide: BorderSide(),
    ),
  );
}

/// The Styling and layout is shared with [AutocompleteTextField]. Hence the Static Methods.
Widget layoutInput(
    {required BuildContext context,
    required Widget child,
    required String label}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(height: 28, child: child),
      if (label.isNotEmpty)
        Text(label, style: Theme.of(context).textTheme.bodySmall)
    ],
  );
}
