import 'package:shadcn_flutter/shadcn_flutter.dart';

class BlurListener extends StatelessWidget {
  final Widget child;
  final void Function() onBlur;
  final void Function()? onFocus;

  const BlurListener(
      {Key? key, required this.child, required this.onBlur, this.onFocus})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Focus(
      skipTraversal: true,
      onFocusChange: (hasFocus) {
        hasFocus ? onFocus?.call() : onBlur();
      },
      child: child,
    );
  }
}
