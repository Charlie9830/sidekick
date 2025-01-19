import 'package:flutter/material.dart';

class TableHeaderCard extends StatelessWidget {
  final Widget child;

  const TableHeaderCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: Padding(padding: const EdgeInsets.all(8.0), child: child),
    );
  }
}
