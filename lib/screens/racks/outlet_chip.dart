import 'package:shadcn_flutter/shadcn_flutter.dart';

class OutletChip extends StatelessWidget {
  final String outletName;
  final Color? primaryLocationColor;

  const OutletChip({
    super.key,
    required this.outletName,
    this.primaryLocationColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(4.0),
      filled: true,
      fillColor: primaryLocationColor?.withAlpha(100),
      child: Text(outletName, style: Theme.of(context).typography.mono),
    );
  }
}
