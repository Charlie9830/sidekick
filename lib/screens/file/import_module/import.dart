import 'package:shadcn_flutter/shadcn_flutter.dart';
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
          PrimaryButton(
              onPressed: () => vm.onImportManagerButtonPressed(),
              child: const Text('Start Patch Import')),
        ],
      ),
    );
  }
}
