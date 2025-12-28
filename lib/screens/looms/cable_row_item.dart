import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/containers/diffing_screen_container.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/locations/multi_color_chit.dart';
import 'package:sidekick/screens/looms/cable_flag.dart';
import 'package:sidekick/simple_tooltip.dart';

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
  final String labelHint;
  final bool missingUpstreamCable;
  final void Function(String newValue)? onLengthChanged;
  final void Function(String newValue) onNotesChanged;
  final CableDelta? cableDelta;
  final bool isDetached;

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
    this.labelHint = '',
    this.onLengthChanged,
    this.missingUpstreamCable = false,
    required this.onNotesChanged,
    this.isDetached = false,
  });

  @override
  Widget build(BuildContext context) {
    final String length = cable.length.floor().toString();
    final Color borderColor = Colors.gray.shade800;

    final scaling = Theme.of(context).scaling;

    final primaryTypography = Theme.of(context)
        .typography
        .light
        .copyWith(color: Colors.gray.shade300, fontSize: 14 * scaling);
    final secondaryTypography = Theme.of(context)
        .typography
        .light
        .copyWith(color: Colors.gray.shade400, fontSize: 14 * scaling);

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
                width: 72,
                child: disableLength
                    ? Center(child: Text('-', style: secondaryTypography))
                    : DiffStateOverlay(
                        diff: cableDelta?.properties
                            .lookup(PropertyDeltaName.cableLength),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: length.length >= 3 ? 48 : 40,
                              child: Center(
                                child: EditableTextField(
                                  onChanged: (newValue) =>
                                      onLengthChanged?.call(newValue),
                                  selectAllOnFocus: true,
                                  style: primaryTypography,
                                  value: cable.length.floor().toString(),
                                  suffix: 'm',
                                ),
                              ),
                            ),
                            if (cable.length == 0)
                              const SimpleTooltip(
                                waitDuration: Duration(milliseconds: 500),
                                message: 'Invalid Length',
                                child: Icon(Icons.error, color: Colors.orange),
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
                width: 184,
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
                                size: 16, color: Colors.gray),
                            CableType.wieland6way => const Icon(Icons.power,
                                size: 16, color: Colors.gray),
                            CableType.sneak => const Icon(
                                Icons.settings_ethernet,
                                size: 16,
                                color: Colors.gray),
                            CableType.dmx => Icon(
                                cable.parentMultiId.isEmpty
                                    ? Icons.settings_input_svideo
                                    : Icons.subdirectory_arrow_right,
                                size: 16,
                                color: Colors.gray),
                            CableType.hoist => const Icon(Icons.construction,
                                size: 16, color: Colors.gray),
                            CableType.hoistMulti => const Icon(
                                Icons.view_module_outlined,
                                color: Colors.gray),
                            CableType.unknown => const SizedBox(),
                          },
                          const SizedBox(width: 8),
                          Text(
                            typeLabel,
                            style: cable.parentMultiId.isEmpty
                                ? primaryTypography
                                : secondaryTypography,
                          ),
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
                width: 264,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DiffStateOverlay(
                        diff: cableDelta?.properties
                            .lookup(PropertyDeltaName.label),
                        child: Text(label, style: primaryTypography)),
                    if (labelHint.isNotEmpty) ...[
                      const SizedBox(width: 24),
                      DiffStateOverlay(
                        diff: cableDelta?.properties
                            .lookup(PropertyDeltaName.labelHint),
                        child: Text(labelHint, style: secondaryTypography),
                      ),
                    ],
                    const Spacer(),
                    if (isDetached)
                      const SimpleTooltip(
                          message:
                              'Detached Outlet:\nThis cable will not appear on the patch sheet',
                          child:
                              Icon(Icons.info, color: Colors.gray, size: 20)),
                    if (cable.upstreamId.isNotEmpty)
                      missingUpstreamCable
                          ? const _MissingUpstreamCableIcon()
                          : cable.isDropper
                              ? const CableFlag(
                                  text: 'Drop', color: Colors.green)
                              : const CableFlag(
                                  text: 'Ext',
                                  color: Colors.blue,
                                ),
                    if (cable.isSpare)
                      const CableFlag(
                        text: 'SP',
                        color: Colors.pink,
                      ),
                  ],
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
                        style: primaryTypography,
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
      return Theme.of(context).colorScheme.border;
    }

    return null;
  }
}

class _MissingUpstreamCableIcon extends StatelessWidget {
  const _MissingUpstreamCableIcon();

  @override
  Widget build(BuildContext context) {
    return const SimpleTooltip(
        message:
            "The upstream leg of this cable, eg: The feeder, has been deleted.",
        child: Icon(Icons.link_off, color: Colors.red));
  }
}
