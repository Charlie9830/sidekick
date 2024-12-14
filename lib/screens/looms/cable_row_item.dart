import 'package:flutter/material.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/screens/looms/cable_flag.dart';
import 'package:sidekick/screens/looms/editable_text_field.dart';

class CableRowItem extends StatelessWidget {
  final CableModel cable;
  final String labelColor;
  final bool showTopBorder;
  final bool isSelected;
  final bool hideLength;
  final int dmxUniverse;
  final String label;
  final void Function(String newValue)? onLengthChanged;

  const CableRowItem({
    super.key,
    required this.cable,
    required this.labelColor,
    this.showTopBorder = false,
    this.isSelected = false,
    this.hideLength = false,
    this.dmxUniverse = 0,
    this.label = '',
    this.onLengthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String length = cable.length.floor().toString();

    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        border: Border(
          bottom: const BorderSide(color: Colors.grey),
          top: showTopBorder
              ? const BorderSide(color: Colors.grey)
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: IntrinsicHeight(
          child: SizedBox(
            height: 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Length
                if (hideLength == false) ...[
                  SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: length.length >= 3 ? 42 : 36,
                            child: EditableTextField(
                              onChanged: (newValue) =>
                                  onLengthChanged?.call(newValue),
                              selectAllOnFocus: true,
                              style: Theme.of(context).textTheme.bodyMedium,
                              value: cable.length.floor().toString(),
                              suffix: 'm',
                            ),
                          ),
                          if (cable.length == 0)
                            const Tooltip(
                              waitDuration: Duration(milliseconds: 500),
                              message: 'Invalid Length',
                              child:
                                  Icon(Icons.error, color: Colors.orangeAccent),
                            )
                        ],
                      )),
                  const VerticalDivider(
                    color: Colors.grey,
                  ),
                ],

                // Cable Type
                SizedBox(
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Multi Cable Child Offset.
                            if (cable.parentMultiId.isNotEmpty)
                              const SizedBox(width: 16),

                            switch (cable.type) {
                              CableType.socapex => const Icon(
                                  Icons.electric_bolt,
                                  size: 16,
                                  color: Colors.grey),
                              CableType.wieland6way => const Icon(Icons.power,
                                  size: 16, color: Colors.grey),
                              CableType.sneak => const Icon(
                                  Icons.settings_ethernet,
                                  size: 16,
                                  color: Colors.grey),
                              CableType.dmx => Icon(
                                  cable.parentMultiId.isEmpty
                                      ? Icons.settings_input_svideo
                                      : Icons.subdirectory_arrow_right,
                                  size: 16,
                                  color: Colors.grey),
                              CableType.unknown => const SizedBox(),
                            },
                            const SizedBox(width: 8),
                            Text(_humanFriendlyType(cable.type,
                                isSneakChild: cable.parentMultiId.isNotEmpty)),
                          ],
                        ),
                      ],
                    )),
                const VerticalDivider(
                  color: Colors.grey,
                ),

                // Label
                SizedBox(
                    width: 300,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(label),
                        if (dmxUniverse != 0)
                          Text('  -  U$dmxUniverse',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(color: Colors.grey)),
                        const Spacer(),
                        if (cable.isSpare)
                          const CableFlag(
                            text: 'Spare',
                            color: Colors.pink,
                          )
                      ],
                    )),
                const VerticalDivider(
                  color: Colors.grey,
                ),
                SizedBox(width: 300, child: Text(labelColor)),
                const VerticalDivider(
                  color: Colors.grey,
                ),
                Expanded(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cable.notes),
                    if (cable.loomId.isEmpty)
                      const Tooltip(
                          message: 'Unloomed Cable',
                          child: Icon(
                            Icons.error,
                            color: Colors.orangeAccent,
                          ))
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color? _getBackgroundColor(BuildContext context) {
    if (isSelected) {
      return Theme.of(context).focusColor.withAlpha(60);
    }

    return null;
  }
}

String _humanFriendlyType(CableType type, {bool isSneakChild = false}) {
  if (isSneakChild) {
    return 'Data';
  }

  return switch (type) {
    CableType.dmx => 'DMX',
    CableType.socapex => 'Soca',
    CableType.sneak => 'Sneak',
    CableType.wieland6way => '6way',
    CableType.unknown => "Unknown",
  };
}
