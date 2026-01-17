import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/redux/models/location_model.dart';
import 'package:sidekick/screens/locations/color_select_dialog.dart';
import 'package:sidekick/screens/locations/multi_color_chit.dart';
import 'package:sidekick/widgets/property_field.dart';

class AddOrEditRiggingLocation extends StatefulWidget {
  final LocationModel? existingLocation;
  const AddOrEditRiggingLocation({super.key, this.existingLocation});

  @override
  State<AddOrEditRiggingLocation> createState() =>
      _AddOrEditRiggingLocationState();
}

class _AddOrEditRiggingLocationState extends State<AddOrEditRiggingLocation> {
  late LabelColorModel _labelColor;

  late final TextEditingController _nameController;
  late final TextEditingController _prefixController;
  late final TextEditingController _delimiterController;

  @override
  void initState() {
    _labelColor =
        widget.existingLocation?.color ?? const LabelColorModel.none();

    _nameController =
        TextEditingController(text: widget.existingLocation?.name ?? '');
    _prefixController =
        TextEditingController(text: widget.existingLocation?.multiPrefix ?? '');

    _delimiterController =
        TextEditingController(text: widget.existingLocation?.delimiter ?? '');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (e) => _handleKeyEvent(e),
      child: SizedBox(
        width: 240,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rigging Locations').medium,
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
                width: 120,
                child: PropertyField(
                  label: 'Cable Delimiter',
                  controller: _delimiterController,
                ),
              ),
              CardButton(
                  onPressed: _handleColorSelect,
                  leading: MultiColorChit(
                    value: _labelColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: Text('Colour',
                        style: Theme.of(context)
                            .typography
                            .xSmall
                            .copyWith(color: Colors.gray)),
                  )),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton.secondary(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    trailing: Text(
                        widget.existingLocation == null ? 'Create' : 'Update'),
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
    if (Navigator.of(context).canPop() == true) {
      Navigator.of(context).pop(AddRiggingLocationDialogResult(
        name: _nameController.text,
        prefix: _prefixController.text,
        labelColor: _labelColor,
        delimiter: _delimiterController.text,
      ));
    }
  }
}

class AddRiggingLocationDialogResult {
  final String name;
  final String prefix;
  final LabelColorModel labelColor;
  final String delimiter;

  AddRiggingLocationDialogResult({
    required this.name,
    required this.prefix,
    required this.labelColor,
    required this.delimiter,
  });
}
