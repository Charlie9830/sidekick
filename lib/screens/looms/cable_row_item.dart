import 'package:flutter/material.dart';
import 'package:sidekick/containers/diffing_screen_container.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/locations/multi_color_chit.dart';
import 'package:sidekick/screens/looms/cable_flag.dart';

const double kCableRowHeight = 26.0;

class CableRowItem extends StatelessWidget {
  final CableModel cable;
  final String typeLabel;
  final LabelColorModel labelColor;
  final bool showTopBorder;
  final bool isSelected;
  final bool disableLength;
  final int dmxUniverse;
  final String label;
  final bool missingUpstreamCable;
  final void Function(String newValue)? onLengthChanged;
  final void Function(String newValue) onNotesChanged;
  final CableDelta? cableDelta;

  const CableRowItem({
    super.key,
    required this.cable,
    required this.labelColor,
    this.cableDelta,
    this.typeLabel = '',
    this.showTopBorder = false,
    this.isSelected = false,
    this.disableLength = false,
    this.dmxUniverse = 0,
    this.label = '',
    this.onLengthChanged,
    this.missingUpstreamCable = false,
    required this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String length = cable.length.floor().toString();
    final Color borderColor = Colors.grey.shade800;

    return DiffStateOverlay(
      diff: cableDelta?.overallDiff,
      child: Container(
        height: kCableRowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          border: Border(
            bottom: BorderSide(color: borderColor),
            top: showTopBorder
                ? BorderSide(color: borderColor)
                : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Length
              SizedBox(
                width: 100,
                child: disableLength
                    ? Center(
                        child: Text('-',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: Colors.grey)))
                    : DiffStateOverlay(
                        diff: cableDelta?.properties
                            .lookup(PropertyDeltaName.cableLength),
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
                                child: Icon(Icons.error,
                                    color: Colors.orangeAccent),
                              )
                          ],
                        ),
                      ),
              ),
              VerticalDivider(
                color: borderColor,
              ),

              // Cable Type
              SizedBox(
                width: 120,
                child: DiffStateOverlay(
                  diff: cableDelta?.properties
                      .lookup(PropertyDeltaName.cableType),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          switch (cable.type) {
                            CableType.socapex => const Icon(Icons.bolt,
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
                          Text(typeLabel,
                              style: cable.parentMultiId.isNotEmpty
                                  ? Theme.of(context).textTheme.bodySmall
                                  : null),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              VerticalDivider(
                color: borderColor,
              ),

              // Label
              SizedBox(
                width: 164,
                child: DiffStateOverlay(
                  diff: cableDelta?.properties.lookup(PropertyDeltaName.label),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(label),
                      const Spacer(),
                      if (cable.upstreamId.isNotEmpty)
                        missingUpstreamCable
                            ? const _MissingUpstreamCableIcon()
                            : cable.isDropper
                                ? const CableFlag(
                                    text: 'Drop', color: Colors.green)
                                : const CableFlag(
                                    text: 'Ext',
                                    color: Colors.blueAccent,
                                  ),
                      if (cable.isSpare)
                        const CableFlag(
                          text: 'SP',
                          color: Colors.pink,
                        ),
                    ],
                  ),
                ),
              ),
              VerticalDivider(
                color: borderColor,
              ),

              // Color
              SizedBox(
                width: 64,
                child: DiffStateOverlay(
                  diff: cableDelta?.properties.lookup(PropertyDeltaName.color),
                  child: Center(
                      child: MultiColorChit(
                    value: labelColor,
                    showPickerIcon: false,
                  )),
                ),
              ),
              VerticalDivider(
                color: borderColor,
              ),

              Expanded(
                child: DiffStateOverlay(
                  diff: cableDelta?.properties.lookup(PropertyDeltaName.notes),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: EditableTextField(
                        value: cable.notes,
                        style: Theme.of(context).textTheme.bodySmall,
                        onChanged: (newValue) => onNotesChanged(newValue),
                      )),
                    ],
                  ),
                ),
              ),
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

class _MissingUpstreamCableIcon extends StatelessWidget {
  const _MissingUpstreamCableIcon();

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
        message:
            "The upstream leg of this cable, eg: The feeder, has been deleted.",
        child: Icon(Icons.link_off, color: Colors.redAccent));
  }
}
