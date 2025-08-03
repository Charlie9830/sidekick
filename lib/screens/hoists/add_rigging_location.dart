import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/screens/locations/color_select_dialog.dart';
import 'package:sidekick/screens/locations/multi_color_chit.dart';
import 'package:sidekick/widgets/property_field.dart';

class AddRiggingLocation extends StatefulWidget {
  const AddRiggingLocation({super.key});

  @override
  State<AddRiggingLocation> createState() => _AddRiggingLocationState();
}

class _AddRiggingLocationState extends State<AddRiggingLocation> {
  LabelColorModel _labelColor = const LabelColorModel.none();

  final _nameController = TextEditingController(text: '');
  final _prefixController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (e) => _handleKeyEvent(e),
      child: SizedBox(
        height: 108,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 8,
                children: [
                  SizedBox(
                    width: 200,
                    child: PropertyField(
                      autofocus: true,
                      controller: _nameController,
                      label: 'Location Name',
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: PropertyField(
                      label: 'Prefix',
                      controller: _prefixController,
                    ),
                  ),
                  SizedBox(
                      width: 100,
                      child: InkWell(
                        onTap: _handleColorSelect,
                        child: MultiColorChit(
                          value: _labelColor,
                          height: 24,
                        ),
                      )),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text('Create'),
                    onPressed: onSubmit,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent e) {
    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.enter) {
      onSubmit();
    }
  }

  void _handleColorSelect() async {
    final result = await showDialog(
        context: context,
        builder: (_) => ColorSelectDialog(color: _labelColor));

    if (result is LabelColorModel) {
      setState(() => _labelColor = result);
    }
  }

  void onSubmit() {
    Navigator.of(context).pop(AddRiggingLocationDialogResult(
      name: _nameController.text,
      prefix: _prefixController.text,
      labelColor: _labelColor,
    ));
  }
}

class AddRiggingLocationDialogResult {
  final String name;
  final String prefix;
  final LabelColorModel labelColor;

  AddRiggingLocationDialogResult({
    required this.name,
    required this.prefix,
    required this.labelColor,
  });
}
