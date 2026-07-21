import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/diffing/compute_diffs.dart';
import 'package:sidekick/diff_state_overlay.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/label_color_model.dart';
import 'package:sidekick/screens/diffing/property_delta.dart';
import 'package:sidekick/screens/locations/multi_color_chit.dart';
import 'package:sidekick/screens/looms/cable_flag.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/theme/sidekick_colors.dart';

const double kCableRowHeight = SidekickDensity.rowCompact;

class CableRowItem extends StatefulWidget {
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
  State<CableRowItem> createState() => _CableRowItemState();
}

class _CableRowItemState extends State<CableRowItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cable = widget.cable;
    final String length = cable.length.floor().toString();
    const Color borderColor = SidekickColors.gridLine;

    final scheme = Theme.of(context).colorScheme;
    final scaling = Theme.of(context).scaling;
    final typography = Theme.of(context).typography;

    final primaryTypography = typography.base.copyWith(
      color: scheme.foreground,
      fontSize: 14 * scaling,
    );
    final secondaryTypography = typography.base.copyWith(
      color: scheme.mutedForeground,
      fontSize: 14 * scaling,
    );

    final lengthTypography = typography.mono.copyWith(color: scheme.foreground);
    final labelTypography = typography.mono.copyWith(color: scheme.foreground);
    final labelHintTypography = typography.mono.copyWith(
      color: scheme.mutedForeground,
    );
    final typePrimaryTypography = typography.base.copyWith(
      color: scheme.foreground,
    );
    final typeSecondaryTypography = typography.base.copyWith(
      color: scheme.mutedForeground,
    );
    final iconColor = scheme.mutedForeground;

    return DiffStateOverlay(
      diff: widget.cableDelta?.overallDiff,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          height: kCableRowHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            border: Border(
              bottom: const BorderSide(color: borderColor),
              top: widget.showTopBorder
                  ? const BorderSide(color: borderColor)
                  : BorderSide.none,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SidekickDensity.cellPaddingH,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Length
                SizedBox(
                  width: 72,
                  child: widget.disableLength
                      ? Center(child: Text('-', style: secondaryTypography))
                      : DiffStateOverlay(
                          diff: widget.cableDelta?.properties.lookup(
                            PropertyDeltaName.cableLength,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: length.length >= 3 ? 48 : 40,
                                child: Center(
                                  child: EditableTextField(
                                    onChanged: (newValue) =>
                                        widget.onLengthChanged?.call(newValue),
                                    selectAllOnFocus: true,
                                    style: lengthTypography,
                                    value: cable.length.floor().toString(),
                                    suffix: 'm',
                                  ),
                                ),
                              ),
                              if (cable.length == 0)
                                const SimpleTooltip(
                                  waitDuration: Duration(milliseconds: 500),
                                  message: 'Invalid Length',
                                  child: Icon(
                                    Icons.error,
                                    color: SidekickColors.warning,
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
                const VerticalDivider(color: borderColor),

                // Cable Type
                SizedBox(
                  width: 184,
                  child: DiffStateOverlay(
                    diff: widget.cableDelta?.properties.lookup(
                      PropertyDeltaName.cableType,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (cable.parentMultiId.isNotEmpty)
                              const SizedBox(width: SidekickDensity.indent),
                            _getCableTypeIcon(iconColor),
                            const SizedBox(width: SidekickDensity.gap),
                            Text(
                              widget.typeLabel,
                              style: cable.parentMultiId.isEmpty
                                  ? typePrimaryTypography
                                  : typeSecondaryTypography,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(color: borderColor),

                // Label
                SizedBox(
                  width: 264,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: SidekickDensity.gap),
                      DiffStateOverlay(
                        diff: widget.cableDelta?.properties.lookup(
                          PropertyDeltaName.label,
                        ),
                        child: Row(
                          children: [
                            if (cable.parentMultiId.isNotEmpty)
                              const SizedBox(width: SidekickDensity.indent),
                            Text(widget.label, style: labelTypography),
                          ],
                        ),
                      ),
                      if (widget.labelHint.isNotEmpty) ...[
                        const SizedBox(width: 24),
                        DiffStateOverlay(
                          diff: widget.cableDelta?.properties.lookup(
                            PropertyDeltaName.labelHint,
                          ),
                          child: Text(
                            widget.labelHint,
                            style: labelHintTypography,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (widget.isDetached)
                        SimpleTooltip(
                          message:
                              'Detached Outlet:\nThis cable will not appear on the patch sheet',
                          child: Icon(Icons.info, color: iconColor, size: 20),
                        ),
                      if (cable.upstreamId.isNotEmpty)
                        widget.missingUpstreamCable
                            ? const _MissingUpstreamCableIcon()
                            : cable.isDropper
                            ? const CableFlag(
                                text: 'Drop',
                                color: SidekickColors.dropper,
                              )
                            : const CableFlag(
                                text: 'Ext',
                                color: SidekickColors.extension,
                              ),
                      if (cable.isSpare)
                        const CableFlag(
                          text: 'SP',
                          color: SidekickColors.spare,
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(color: borderColor),

                // Color
                SizedBox(
                  width: 64,
                  child: DiffStateOverlay(
                    diff: widget.cableDelta?.properties.lookup(
                      PropertyDeltaName.color,
                    ),
                    child: Center(
                      child: MultiColorChit(
                        value: widget.labelColor,
                        showPickerIcon: false,
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(color: borderColor),

                Expanded(
                  child: DiffStateOverlay(
                    diff: widget.cableDelta?.properties.lookup(
                      PropertyDeltaName.notes,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: EditableTextField(
                            value: cable.notes,
                            style: primaryTypography,
                            onChanged: (newValue) =>
                                widget.onNotesChanged(newValue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCableTypeIcon(Color color) {
    return switch (widget.cable.type) {
      CableType.socapex => Icon(Icons.bolt, size: 16, color: color),
      CableType.wieland6way => Icon(Icons.power, size: 16, color: color),
      CableType.sneak => Icon(Icons.settings_ethernet, size: 16, color: color),
      CableType.dmx => Icon(
        widget.cable.parentMultiId.isEmpty
            ? Icons.settings_input_svideo
            : Icons.subdirectory_arrow_right,
        size: 16,
        color: color,
      ),
      CableType.hoist => Icon(Icons.construction, size: 16, color: color),
      CableType.hoistMulti => Icon(Icons.view_module_outlined, color: color),
      CableType.au10a => const SizedBox(),
      CableType.unknown => const SizedBox(),
      CableType.true1 => const SizedBox(),
      CableType.socapexToAu10ALampHeader => throw UnimplementedError(),
      CableType.socapexToTrue1LampHeader => throw UnimplementedError(),
      CableType.wieland6WayLampHeader => throw UnimplementedError(),
      CableType.sneakLampHeader => throw UnimplementedError(),
      CableType.hoistMultiLampHeader => throw UnimplementedError(),
      CableType.hoistMultiRackHeader => throw UnimplementedError(),
      CableType.socapexTo6wayAdaptor => throw UnimplementedError(),
      CableType.sneakRackHeader => throw UnimplementedError(),
      CableType.nac3Joiner => throw UnimplementedError(),
      CableType.nac3 => throw UnimplementedError(),
      CableType.wilco32a => throw UnimplementedError(),
      CableType.consoleLoom => throw UnimplementedError(),
      CableType.etherconJoiner => throw UnimplementedError(),
      CableType.ethercon => throw UnimplementedError(),
      CableType.wieland6WayRackHeader => throw UnimplementedError(),
    };
  }

  Color? _getBackgroundColor() {
    if (widget.isSelected) {
      return SidekickColors.rowSelected;
    }
    if (_hovered) {
      return SidekickColors.rowHover;
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
      child: Icon(Icons.link_off, color: SidekickColors.error),
    );
  }
}
