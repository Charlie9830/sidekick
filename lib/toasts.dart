import 'package:shadcn_flutter/shadcn_flutter.dart';

void showFileSaveSuccessToast({required BuildContext context}) {
  showGenericSuccessToast(
      context: context, title: "File Saved", icon: const Icon(Icons.save));
}

void showGenericSuccessToast({
  required BuildContext context,
  required String title,
  Icon icon = const Icon(Icons.check_circle),
  String? subtitle,
  final String? extendedMessage,
  ToastLocation location = ToastLocation.topRight,
}) async {
  showToast(
      context: context,
      builder: (context, overlay) => SurfaceCard(
              child: Basic(
            leading: icon,
            title: Text(title),
            subtitle: subtitle != null ? Text(subtitle) : null,
            trailing: extendedMessage != null
                ? Button.text(
                    child: const Text('More'),
                    onPressed: () => _showMoreDialog(context, extendedMessage),
                  )
                : null,
          )));
}

void showGenericErrorToast(
    {required BuildContext context,
    required String title,
    String? subtitle,
    final String? extendedMessage,
    ToastLocation location = ToastLocation.topRight}) async {
  showToast(
      context: context,
      builder: (context, overlay) => SurfaceCard(
              child: Basic(
            leading: const Icon(Icons.error),
            title: Text(title),
            subtitle: subtitle != null ? Text(subtitle) : null,
            trailing: extendedMessage != null
                ? Button.text(
                    child: const Text('More'),
                    onPressed: () => _showMoreDialog(context, extendedMessage),
                  )
                : null,
          )));
}

void _showMoreDialog(BuildContext context, String message) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
              title: const Text('More Info'),
              content: Text(message),
              actions: [
                PrimaryButton(
                  child: const Text('Okay'),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ]));
}
