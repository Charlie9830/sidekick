import 'package:flutter/material.dart';

class RiggingOnlyTag extends StatelessWidget {
  const RiggingOnlyTag({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Location intended to represent "Rigging Only" locations without any Fixtures, EG: Cable Bridge, Mothergrid',
      child: Container(
        decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(4.0)),
        padding: const EdgeInsets.all(4.0),
        child: Text('Rigging', style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
