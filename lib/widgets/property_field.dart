import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

typedef OnBlurCallback = void Function(String newValue);

enum LabelAlign {
  start,
  center,
  end,
}

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
  final ScrollController? scrollController;
  final bool enabled;
  final LabelAlign labelAlign;
  final String? error;

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
    this.enabled = true,
    this.scrollController,
    this.labelAlign = LabelAlign.start,
    this.error,
  }) : super(key: key);

  @override
  PropertyFieldState createState() => PropertyFieldState();
}

class PropertyFieldState extends State<PropertyField> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.value);

    _scrollController = _scrollController = widget.scrollController ??
        ScrollController(
            keepScrollOffset:
                false); // Stops the TextField trying to re establish it's scroll position from an ancestor PageStorage.
    // When this happens, it triggers funky animations.

    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
        _handleSubmit();
      }

      return KeyEventResult.ignored;
    };
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
        label: widget.label,
        labelPosition: widget.labelAlign,
        error: widget.error,
        child: TextField(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
          controller: _controller,
          scrollController: _scrollController,
          autocorrect: widget.autofocus,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          focusNode: _focusNode,
          inputFormatters: widget.inputFormatters,
          hintText: widget.hintText,
          textAlign: widget.textAlign,
          border: widget.error != null
              ? Border.all(
                  color: Colors.red, style: BorderStyle.solid, width: 2)
              : null,
          onEditingComplete: () => _handleSubmit(),
          onTapOutside: (e) => _handleSubmit(),
          features: [
            // Suffix
            if (widget.suffix.isNotEmpty)
              InputFeature.trailing(
                  Text(widget.suffix,
                      style: Theme.of(context)
                          .typography
                          .normal
                          .copyWith(color: Colors.gray)),
                  skipFocusTraversal: true,
                  visibility: InputFeatureVisibility.always)
          ],
        ));
  }

  void _handleSubmit() {
    widget.onBlur?.call(_controller.text);

    //_focusNode.nextFocus();
  }

  @override
  void dispose() {
    // Dispose of the controller only when one has not been provided by the option [controller] property.
    // If an external controller has been provided, the responsibility is on the caller to dispose of it.
    if (widget.controller == null) {
      _controller.dispose();
    }

    // Dispose of the controller only when one has not been provided by the option [scrollController] property.
    // If an external controller has been provided, the responsibility is on the caller to dispose of it.
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }

    // Dispose of the focus node only when one has not been provided by the option [focusNode] property.
    // If an external controller has been provided, the responsibility is on the caller to dispose of it.
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    super.dispose();
  }
}

/// The Styling and layout is shared with [AutocompleteTextField]. Hence the Static Methods.
Widget layoutInput(
    {required BuildContext context,
    required Widget child,
    required String label,
    required String? error,
    required LabelAlign labelPosition}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: switch (labelPosition) {
      LabelAlign.start => CrossAxisAlignment.start,
      LabelAlign.center => CrossAxisAlignment.center,
      LabelAlign.end => CrossAxisAlignment.end,
    },
    children: [
      child,
      if (label.isNotEmpty)
        Text(label,
            style: Theme.of(context)
                .typography
                .xSmall
                .copyWith(color: Colors.gray)),
      if (error != null)
        Text(error,
            style:
                Theme.of(context).typography.xSmall.copyWith(color: Colors.red))
    ],
  );
}
