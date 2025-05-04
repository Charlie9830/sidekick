import 'package:flutter/material.dart';

class HybridTag extends StatelessWidget {
  final List<String> otherLocationNames;
  const HybridTag({
    super.key,
    required this.otherLocationNames,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _resolveOtherLocationsText(otherLocationNames),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.grey[600], borderRadius: BorderRadius.circular(4.0)),
        padding: const EdgeInsets.all(4.0),
        child: Text('Hybrid', style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }

  String _resolveOtherLocationsText(List<String> otherLocationNames) {
    return otherLocationNames.join(', ');
  }
}
