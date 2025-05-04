import 'package:flutter/material.dart';
import 'package:sidekick/view_models/import_view_model.dart';

class Import extends StatelessWidget {
  final ImportViewModel vm;
  const Import({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton(
              onPressed: () => vm.onImportManagerButtonPressed(),
              child: const Text('Start Patch Import')),
        ],
      ),
    );
  }
}
