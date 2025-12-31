import 'package:shadcn_flutter/shadcn_flutter.dart';

Future<T?> openShadSheet<T>(
    {required BuildContext context, required WidgetBuilder builder}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor:
        const Color.fromARGB(128, 0, 0, 0), // The dimmed background (scrim)
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Card(
          borderRadius: const BorderRadius.all(Radius.zero),
          child: Builder(builder: builder),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Slide animation from right (Offset 1.0) to current position (Offset 0.0)
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    },
  );
}
