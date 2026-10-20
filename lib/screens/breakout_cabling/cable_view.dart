import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/screens/breakout_cabling/visibility_control.dart';
import 'package:sidekick/screens/looms/cable_type_select.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';
import 'package:sidekick/widgets/rig_viewer/rig_viewer.dart';
import 'package:sidekick/widgets/rig_viewer/scene/oriented_box.dart';
import 'package:sidekick/widgets/rig_viewer/scene/rig_fixture_builder.dart';
import 'package:sidekick/widgets/rig_viewer/scene/rig_scene_model.dart';

/// Height (mm) header and location markers float above their true position,
/// so they stand clear of the fixture bodies they sit among. Presentation
/// only; it never feeds into cable-length calculations.
const double _kMarkerLiftMm = 600;

/// Edge length (mm) of a header or location marker.
const double _kMarkerSizeMm = 200;

/// Edge length (mm) of a truss-break dot.
const double _kBreakSizeMm = 80;

/// Line width (mm) of links and fixture runs; home runs are drawn double.
const double _kCableWidthMm = 15;

/// The breakout cabling graph in the 3D rig viewer: fixtures with their
/// connectors, trusses, header markers and every cable along its routed path.
///
/// Display only: nothing is selectable, and orbits turn around the centre of
/// the view. The visibility filter hides cables by signal and run type.
class CableView extends StatelessWidget {
  final CableViewViewModel vm;

  const CableView({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.elements.isEmpty) {
      return const SizedBox.shrink();
    }

    return RigViewer(
      scene: RigSceneModel(
        fixtures: [
          for (final element in vm.elements)
            if (element is FixtureElement) _buildFixture(element),
        ],
        trusses: [
          for (final truss in vm.trusses)
            if (truss.corners.length == 8)
              OrientedBox.fromCorners(truss.corners),
        ],
        markers: [for (final element in vm.elements) ?_buildMarker(element)],
        lines: [
          for (final edge in vm.edges)
            if (edge is CableEdgeElement) ?_buildCable(edge),
        ],
      ),
      overlays: [
        Positioned(
          top: 8,
          right: 8,
          width: 164,
          child: VisibilityControl(
            state: vm.cableVisibility,
            onVisibilityChanged: vm.onVisibilityChanged,
          ),
        ),
        const Positioned(bottom: 8, right: 8, child: _Legend()),
      ],
    );
  }

  RigFixture _buildFixture(FixtureElement element) {
    final fixtureVm = element.fixtureVm;
    final fixture = fixtureVm.fixture;
    final shortName = fixtureVm.fixtureType.shortName;

    return buildRigFixture(
      fixture: fixture,
      geometry: fixtureVm.geometry,
      fixtureType: fixtureVm.fixtureType,
      color: SidekickColors.rigMesh,
      label: fixture.fid.toString(),
      tooltip: '#${fixture.fid}${shortName.isEmpty ? '' : ' · $shortName'}',
    );
  }

  /// The marker drawn for a non-fixture node, or null for fixtures.
  RigMarker? _buildMarker(NodeElement element) {
    final position = _markerPosition(element);
    return switch (element) {
      FixtureElement() => null,
      LocationElement() => RigMarker(
        position: position,
        color: SidekickColors.locationMarker,
        size: _kMarkerSizeMm,
        shape: RigSolidShape.cylinder,
      ),
      PowerMultiHeaderElement() => RigMarker(
        position: position,
        color: SidekickColors.powerMultiNode,
        size: _kMarkerSizeMm,
        shape: RigSolidShape.cylinder,
        label: element.powerMultiVm.name,
      ),
      DataMultiHeaderElement() => RigMarker(
        position: position,
        color: SidekickColors.dataMultiNode,
        size: _kMarkerSizeMm,
        label: element.outletName,
      ),
      DataPatchHeaderElement() => RigMarker(
        position: position,
        color: SidekickColors.dataMultiNode,
        size: _kMarkerSizeMm,
        shape: RigSolidShape.cylinder,
        label: 'U${element.universe}',
      ),
      TrussBreakElement() => RigMarker(
        position: position,
        color: SidekickColors.rigTruss,
        size: _kBreakSizeMm,
      ),
    };
  }

  /// Where [element]'s marker is drawn: headers and the location are lifted
  /// clear of the fixtures by [_kMarkerLiftMm]; everything else stays put.
  Vector3 _markerPosition(NodeElement element) => switch (element) {
    LocationElement() ||
    PowerMultiHeaderElement() ||
    DataMultiHeaderElement() ||
    DataPatchHeaderElement() =>
      element.position + const Vector3(0, 0, _kMarkerLiftMm),
    FixtureElement() || TrussBreakElement() => element.position,
  };

  /// The cable as a line along its routed path, or null when it is hidden by
  /// the visibility filter or carries neither power nor data.
  RigLine? _buildCable(CableEdgeElement edge) {
    final visibleRuns = switch (edge.type.signal) {
      CableSignal.power => vm.cableVisibility.powerState,
      CableSignal.data => vm.cableVisibility.dataState,
      CableSignal.network || CableSignal.hoist || CableSignal.none => null,
    };
    if (visibleRuns == null || !visibleRuns.contains(edge.runType)) {
      return null;
    }

    return RigLine(
      points: _cablePoints(edge),
      color: _cableColor(edge),
      width: edge.runType == CableRunType.homeRun
          ? _kCableWidthMm * 2
          : _kCableWidthMm,
      tooltip:
          '${humanFriendlyCableTypeName(edge.type)} · '
          '${_formatLength(edge.length)}',
    );
  }

  /// The cable's routed path, joined up to any lifted marker at its ends.
  /// Cables without a routed path run straight between their end points.
  List<Vector3> _cablePoints(CableEdgeElement edge) {
    final from = edge.fromPoint ?? edge.fromElement.position;
    final to = edge.toPoint ?? edge.toElement.position;
    final path = edge.path.length >= 2 ? edge.path : [from, to];

    final fromMarker = _markerPosition(edge.fromElement);
    final toMarker = _markerPosition(edge.toElement);
    return [
      if (fromMarker != edge.fromElement.position) fromMarker,
      ...path,
      if (toMarker != edge.toElement.position) toMarker,
    ];
  }

  Color _cableColor(CableEdgeElement edge) =>
      switch ((edge.type.signal, edge.runType)) {
        (CableSignal.power, CableRunType.link) => SidekickColors.powerLink,
        (CableSignal.power, CableRunType.fixtureRun) => SidekickColors.powerRun,
        (CableSignal.power, CableRunType.homeRun) => SidekickColors.powerHome,
        (_, CableRunType.link) => SidekickColors.dataLink,
        (_, CableRunType.fixtureRun) => SidekickColors.dataRun,
        (_, CableRunType.homeRun) => SidekickColors.dataHome,
      };

  String _formatLength(double length) {
    return length.remainder(1) == 0
        ? '${length.toStringAsFixed(0)}m'
        : '${length.toStringAsFixed(1)}m';
  }
}

/// A compact key explaining the colour (cable type) and line-weight (run
/// type) encodings.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.typography.xSmall.copyWith(
      color: theme.colorScheme.mutedForeground,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Legend',
            style: theme.typography.xSmall.copyWith(
              color: theme.colorScheme.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _LegendSwatch(
            color: SidekickColors.powerRun,
            label: 'Power',
            style: labelStyle,
          ),
          _LegendSwatch(
            color: SidekickColors.dataRun,
            label: 'Data',
            style: labelStyle,
          ),
          _LegendSwatch(
            color: SidekickColors.dataMultiNode,
            label: 'Data multi',
            style: labelStyle,
          ),
          _LegendSwatch(
            color: SidekickColors.locationMarker,
            label: 'Location',
            style: labelStyle,
          ),
          _LegendSwatch(
            color: SidekickColors.rigConnector,
            label: 'Connector',
            style: labelStyle,
          ),
          const SizedBox(height: 8),
          _LegendLine(weight: 1, label: 'Link', style: labelStyle),
          _LegendLine(weight: 1, label: 'Fixture run', style: labelStyle),
          _LegendLine(weight: 2, label: 'Home run', style: labelStyle),
        ],
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final TextStyle style;

  const _LegendSwatch({
    required this.color,
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: style),
        ],
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  final double weight;
  final String label;
  final TextStyle style;

  const _LegendLine({
    required this.weight,
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            child: Divider(
              thickness: weight,
              color: Theme.of(context).colorScheme.mutedForeground,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: style),
        ],
      ),
    );
  }
}
