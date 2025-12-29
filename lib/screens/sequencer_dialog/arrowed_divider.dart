import 'package:shadcn_flutter/shadcn_flutter.dart';

class ArrowedDivider extends StatelessWidget {
  const ArrowedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: VerticalDivider()),
        Icon(Icons.arrow_right, size: 72, color: Colors.gray),
        Expanded(child: VerticalDivider()),
      ],
    );
  }
}
