import 'package:flutter/material.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/screens/locations/color_chit.dart';
import 'package:sidekick/screens/looms/cable_flag.dart';

const double kCableRowHeight = 26.0;

class CableRowItem extends StatelessWidget {
  final CableModel cable;
  final LabelColorModel labelColor;
  final bool showTopBorder;
  final bool isSelected;
  final bool disableLength;
  final int dmxUniverse;
  final String label;
  final bool missingUpstreamCable;
  final void Function(String newValue)? onLengthChanged;

  const CableRowItem({
    super.key,
    required this.cable,
    required this.labelColor,
    this.showTopBorder = false,
    this.isSelected = false,
    this.disableLength = false,
    this.dmxUniverse = 0,
    this.label = '',
    this.onLengthChanged,
    this.missingUpstreamCable = false,
  });

  @override
  Widget build(BuildContext context) {
    final String length = cable.length.floor().toString();
    final Color borderColor = Colors.grey.shade800;

    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        border: Border(
          bottom: BorderSide(color: borderColor),
          top: showTopBorder ? BorderSide(color: borderColor) : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: kCableRowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Length
              SizedBox(
                  width: 100,
                  child: disableLength
                      ? const Center(child: Text('-'))
                      : Row(
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
                                child: Icon(Icons.error,
                                    color: Colors.orangeAccent),
                              )
                          ],
                        )),
              VerticalDivider(
                color: borderColor,
              ),

              // Cable Type
              SizedBox(
                  width: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          switch (cable.type) {
                            CableType.socapex => const Icon(Icons.electric_bolt,
                                size: 16, color: Colors.grey),
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
              VerticalDivider(
                color: borderColor,
              ),

              // Label
              SizedBox(
                  width: 200,
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
                      if (cable.upstreamId.isNotEmpty)
                        missingUpstreamCable
                            ? const _MissingUpstreamCableIcon()
                            : const CableFlag(
                                text: 'Ext',
                                color: Colors.blueAccent,
                              ),
                      if (cable.isSpare)
                        const CableFlag(
                          text: 'Spare',
                          color: Colors.pink,
                        ),
                    ],
                  )),
              VerticalDivider(
                color: borderColor,
              ),

              // Color
              //SizedBox(width: 100, child: Text(labelColor.name)),

              // Color
              SizedBox(
                  width: 128,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: labelColor.colors
                        .map((namedColor) => ColorChit(
                              color: namedColor.color,
                              brightness: Brightness.dark,
                            ))
                        .toList(),
                  )),
              VerticalDivider(
                color: borderColor,
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

class _MissingUpstreamCableIcon extends StatelessWidget {
  const _MissingUpstreamCableIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
        message:
            "The upstream leg of this cable, eg: The feeder, has been deleted.",
        child: Icon(Icons.link_off, color: Colors.redAccent));
  }
}
