import 'package:shadcn_flutter/shadcn_flutter.dart';

Future<V?> showDialog<V>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool fullScreen = false,
  bool barrierDismissible = true,
  Color? barrierColor,
}) async {
  return showOverlay<V>(
    context,
    builder: builder,
    DialogConfiguration(
      fullScreen: fullScreen,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
    ),
  ).future;
}
