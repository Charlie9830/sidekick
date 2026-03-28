import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/widgets/blur_listener.dart';
import 'package:sidekick/widgets/property_field.dart';

class EditableTextField extends StatefulWidget {
  final String value;
  final String? hintText;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final String? prefix;
  final String? suffix;
  final TextAlign? textAlign;
  final double? cursorHeight;
  final bool selectAllOnFocus;
  final void Function(String newValue)? onChanged;
  final List<TextInputFormatter> inputFormatters;
  final bool enabled;
  final ScrollController? scrollController;
  final FocusNode? focusNode;
  final PropertyFieldSubmitAction submitAction;

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
    this.hintStyle,
    this.scrollController,
    this.focusNode,
    this.submitAction = PropertyFieldSubmitAction.unfocus,
  });

  @override
  State<EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  String? _lastNotifiedValue;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);

    _scrollController = widget.scrollController ??
        ScrollController(
            keepScrollOffset:
                false); // Stops the TextField trying to re establish it's scroll position from an ancestor PageStorage.
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
  void didUpdateWidget(covariant EditableTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value;
      _lastNotifiedValue = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlurListener(
      onBlur: _handleBlur,
      onFocus: () {
        if (widget.selectAllOnFocus) {
          _controller.selection = TextSelection(
              baseOffset: 0, extentOffset: _controller.text.length);
        }
      },
      child: TextField(
        key: widget.key,
        focusNode: _focusNode,
        enabled: widget.enabled,
        controller: _controller,
        scrollController: _scrollController,
        autocorrect: false,
        textAlign: widget.textAlign ?? TextAlign.start,
        style: widget.style,
        inputFormatters: widget.inputFormatters,
        cursorHeight: widget.cursorHeight,
        hintText: widget.hintText,
        decoration: _defaultDecoration(),
        onEditingComplete: _handleSubmit,
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        features: [
          // Prefix
          if (widget.prefix != null)
            InputFeature.leading(
              Text(widget.prefix!,
                  style: Theme.of(context)
                      .typography
                      .normal
                      .copyWith(color: Colors.gray)),
              skipFocusTraversal: true,
              visibility: InputFeatureVisibility.always,
            ),

          // Suffix
          if (widget.suffix != null)
            InputFeature.trailing(
                Text(widget.suffix!,
                    style: Theme.of(context)
                        .typography
                        .normal
                        .copyWith(color: Colors.gray)),
                skipFocusTraversal: true,
                visibility: InputFeatureVisibility.always)
        ],
      ),
    );
  }

  void _notifyIfChanged() {
    final newValue = _controller.text;
    // Only notify if the value is different from the initial value AND different from what we last sent.
    if (newValue != widget.value && newValue != _lastNotifiedValue) {
      _lastNotifiedValue = newValue;
      widget.onChanged?.call(newValue);
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

  BoxDecoration _defaultDecoration() {
    return const BoxDecoration(
      border: BoxBorder.fromBorderSide(BorderSide.none),
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    if (widget.scrollController == null) {
      // Only dispose of the Scroll controller if it has not been provided externally.
      _scrollController.dispose();
    }

    if (widget.focusNode == null) {
      // Only dispose of the FocusNode if it has not been provided externally.
      _focusNode.dispose();
    }

    super.dispose();
  }
}
