import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/widgets/hover_region.dart';

/// Tunable geometry for the orthogonal cable channels.
///
/// The perpendicular riser scales with a cable's horizontal span so longer runs
/// plateau higher and nest, mirroring the old arcs. Data and power obey the same
/// up/down rules (home runs rise, links and fixture runs descend) and are told
/// apart by colour and by their own base/growth values.
@immutable
class CableRouteTuning {
  final double powerBaseRiser;
  final double powerRiserGrowth;
  final double dataBaseRiser;
  final double dataRiserGrowth;
  final double cornerRadius;

  const CableRouteTuning({
    this.powerBaseRiser = 20,
    this.powerRiserGrowth = 0.15,
    this.dataBaseRiser = 30,
    this.dataRiserGrowth = 0.15,
    this.cornerRadius = 8,
  });

  /// Perpendicular plateau distance for a cable spanning [span] pixels.
  double powerRiser(double span) => powerBaseRiser + span * powerRiserGrowth;
  double dataRiser(double span) => dataBaseRiser + span * dataRiserGrowth;

  /// Home runs rise above the truss; links and fixture runs descend below it.
  static bool directionUpFor(CableRunType runType) =>
      runType == CableRunType.homeRun;

  CableRouteTuning copyWith({
    double? powerBaseRiser,
    double? powerRiserGrowth,
    double? dataBaseRiser,
    double? dataRiserGrowth,
    double? cornerRadius,
  }) {
    return CableRouteTuning(
      powerBaseRiser: powerBaseRiser ?? this.powerBaseRiser,
      powerRiserGrowth: powerRiserGrowth ?? this.powerRiserGrowth,
      dataBaseRiser: dataBaseRiser ?? this.dataBaseRiser,
      dataRiserGrowth: dataRiserGrowth ?? this.dataRiserGrowth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }
}

/// Overlay panel with sliders for tuning the cable channel geometry live.
class RouteTuningControl extends StatelessWidget {
  final CableRouteTuning tuning;
  final ValueChanged<CableRouteTuning> onChanged;

  const RouteTuningControl({
    super.key,
    required this.tuning,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return HoverRegionBuilder(builder: (context, isHovering) {
      return Opacity(
        opacity: isHovering ? 1 : 0.25,
        child: Card(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 24, child: Text('Power riser')),
              _TuningSlider(
                label: 'Base',
                value: tuning.powerBaseRiser,
                min: 0,
                max: 120,
                onChanged: (v) =>
                    onChanged(tuning.copyWith(powerBaseRiser: v)),
              ),
              _TuningSlider(
                label: 'Growth',
                value: tuning.powerRiserGrowth,
                min: 0,
                max: 1,
                onChanged: (v) =>
                    onChanged(tuning.copyWith(powerRiserGrowth: v)),
              ),
              const Divider(height: 24, child: Text('Data riser')),
              _TuningSlider(
                label: 'Base',
                value: tuning.dataBaseRiser,
                min: 0,
                max: 120,
                onChanged: (v) => onChanged(tuning.copyWith(dataBaseRiser: v)),
              ),
              _TuningSlider(
                label: 'Growth',
                value: tuning.dataRiserGrowth,
                min: 0,
                max: 1,
                onChanged: (v) =>
                    onChanged(tuning.copyWith(dataRiserGrowth: v)),
              ),
              const Divider(height: 24, child: Text('Corner')),
              _TuningSlider(
                label: 'Radius',
                value: tuning.cornerRadius,
                min: 0,
                max: 40,
                onChanged: (v) => onChanged(tuning.copyWith(cornerRadius: v)),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _TuningSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _TuningSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.typography.xSmall),
              Text(
                value.toStringAsFixed(2),
                style: theme.typography.xSmall.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: SliderValue.single(value),
            min: min,
            max: max,
            onChanged: (v) => onChanged(v.value),
          ),
        ],
      ),
    );
  }
}
