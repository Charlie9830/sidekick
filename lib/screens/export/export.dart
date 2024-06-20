import 'package:flutter/material.dart';

import 'package:sidekick/view_models/export_view_model.dart';

class Export extends StatelessWidget {
  final ExportViewModel vm;
  const Export({Key? key, required this.vm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: ElevatedButton(
      onPressed: vm.onExportButtonPressed,
      child: const Text('Export'),
    ));
  }
}
