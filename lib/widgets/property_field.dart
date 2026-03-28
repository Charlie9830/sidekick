import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/widgets/blur_listener.dart';

typedef OnBlurCallback = void Function(String newValue);

enum PropertyFieldSubmitAction {
  next,
  unfocus,
  none,
}

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
  final PropertyFieldSubmitAction submitAction;

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
    this.submitAction = PropertyFieldSubmitAction.next,
  }) : super(key: key);

  @override
  PropertyFieldState createState() => PropertyFieldState();
}

class PropertyFieldState extends State<PropertyField> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  String? _lastNotifiedValue;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.value);
    _scrollController =
        widget.scrollController ?? ScrollController(keepScrollOffset: false);
    // Stops the TextField trying to re establish it's scroll position from an ancestor PageStorage.
    // When this happens, it triggers funky animations.

    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.onKeyEvent = (node, event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;

      if (event.logicalKey == LogicalKeyboardKey.tab) {
        _handleSubmit();
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _handleSubmit();
        return KeyEventResult.handled;
      }

      return KeyEventResult.ignored;
    };
  }

  @override
  void didUpdateWidget(covariant PropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value ?? '';
      _lastNotifiedValue = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlurListener(
      onBlur: _handleBlur,
      child: layoutInput(
          context: context,
          label: widget.label,
          labelPosition: widget.labelAlign,
          error: widget.error,
          child: TextField(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            controller: _controller,
            scrollController: _scrollController,
            autocorrect: false,
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
            onTapOutside: (e) => _handleBlur(),
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
          )),
    );
  }

  void _notifyIfChanged() {
    final newValue = _controller.text;
    // Only notify if the value is different from the initial value AND different from what we last sent.
    if (newValue != (widget.value ?? '') && newValue != _lastNotifiedValue) {
      _lastNotifiedValue = newValue;
      widget.onBlur?.call(newValue);
    }
  }

  void _handleBlur() {
    _notifyIfChanged();
  }

  void _handleSubmit() {
    _notifyIfChanged();

    if (widget.submitAction == PropertyFieldSubmitAction.next) {
      _focusNode.nextFocus();
    } else if (widget.submitAction == PropertyFieldSubmitAction.unfocus) {
      _focusNode.unfocus();
    }
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
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .typography
                .xSmall
                .copyWith(color: Colors.gray)),
      if (error != null)
        Text(error,
            textAlign: TextAlign.center,
            style:
                Theme.of(context).typography.xSmall.copyWith(color: Colors.red))
    ],
  );
}
