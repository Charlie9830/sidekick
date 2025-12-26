import 'package:shadcn_flutter/shadcn_flutter.dart';

class FileValidIcon extends StatelessWidget {
  final bool isValid;
  const FileValidIcon({super.key, required this.isValid});

  @override
  Widget build(BuildContext context) {
    return isValid
        ? const Icon(Icons.check_circle, color: Colors.green)
        : const Icon(Icons.clear_rounded, color: Colors.red);
  }
}
