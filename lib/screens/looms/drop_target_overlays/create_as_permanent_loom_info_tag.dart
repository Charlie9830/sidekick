import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:material_ui/material_ui.dart' show Icons;

class CreateAsPermanentLoomInfoTag extends StatelessWidget {
  const CreateAsPermanentLoomInfoTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.all_inclusive,
      size: 20,
      color: Theme.of(context).colorScheme.secondary,
    );
  }
}
