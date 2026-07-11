import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/cable_graph.dart';
import 'package:sidekick/cable_graph/viewport_transformer.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/screens/breakout_cabling/route_tuning_control.dart';
import 'package:sidekick/screens/breakout_cabling/visibility_control.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/view_models/breakout_cabling_view_model.dart';
import 'package:sidekick/widgets/connector_painters.dart';
import 'package:sidekick/widgets/rig_viewer/rig_fixture_node.dart';
import 'package:sidekick/widgets/rig_viewer/rig_viewer.dart';

/// The breakout cabling graph: trusses, fixtures, headers and cables drawn in
/// a shared [RigViewer].
class CableView extends StatefulWidget {
  final CableViewViewModel vm;

  const CableView({super.key, required this.vm});

  @override
  State<CableView> createState() => _CableViewState();
}

class _CableViewState extends State<CableView> {
  CableRouteTuning _tuning = const CableRouteTuning();

  @override
  Widget build(BuildContext context) {
    if (widget.vm.elements.isEmpty) {
      return const SizedBox.shrink();
    }

    // Fit the viewport over every projected point — fixtures, headers
    // and truss outlines alike — so nothing is clipped or offset.
    final fitPoints = <Offset>[
      for (final element in widget.vm.elements)
        Offset(element.screenX, element.screenY),
      for (final truss in widget.vm.trusses) ...truss.hull,
    ];

    return RigViewer(
      fitPoints: fitPoints,
      trussHulls: [for (final truss in widget.vm.trusses) truss.hull],
      underlayBuilder: (context, viewport, labelOpacity) => [
        for (final edge in widget.vm.edges) _buildEdge(edge, viewport),
      ],
      nodesBuilder: (context, viewport, labelOpacity) => [
        for (final node in widget.vm.elements)
          _buildNode(node, viewport, labelOpacity),
      ],
      overlays: [
        Positioned(
          top: 8,
          left: 8,
          width: 164,
          child: VisibilityControl(
            state: widget.vm.cableVisibility,
            onVisibilityChanged: widget.vm.onVisibilityChanged,
          ),
        ),
        const Positioned(
          bottom: 8,
          left: 8,
          child: _Legend(),
        ),
        Positioned(
          top: 8,
          right: 8,
          width: 200,
          child: RouteTuningControl(
            tuning: _tuning,
            onChanged: (tuning) => setState(() => _tuning = tuning),
          ),
        ),
      ],
    );
  }

  Widget _buildEdge(EdgeElement edge, ViewportTransformer viewport) {
    final fromElement = edge.fromElement;
    final toElement = edge.toElement;
    final fromOffset = viewport.transform(
      fromElement.screenX,
      fromElement.screenY,
    );
    final toOffset = viewport.transform(
      toElement.screenX,
      toElement.screenY,
    );

    return Positioned.fill(
      child: switch (edge) {
        PsuedoEdgeElement() => const SizedBox(),
        CableEdgeElement() => switch (edge.type) {
          CableType.unknown => throw UnimplementedError(),
          CableType.wieland6way => throw UnimplementedError(),
          CableType.sneak => throw UnimplementedError(),
          CableType.hoist => throw UnimplementedError(),
          CableType.hoistMulti => throw UnimplementedError(),
          CableType.true1 => throw UnimplementedError(),
          CableType.dmx => _buildDataCableEdge(
            edge: edge,
            fromOffset: fromOffset,
            toOffset: toOffset,
          ),
          CableType.au10a || CableType.socapex => _buildPowerCableEdge(
            edge: edge,
            fromOffset: fromOffset,
            toOffset: toOffset,
          ),
          CableType.socapexToAu10ALampHeader => throw UnimplementedError(),
          CableType.socapexToTrue1LampHeader => throw UnimplementedError(),
          CableType.wieland6WayLampHeader => throw UnimplementedError(),
          CableType.sneakLampHeader => throw UnimplementedError(),
          CableType.hoistMultiLampHeader => throw UnimplementedError(),
          CableType.hoistMultiRackHeader => throw UnimplementedError(),
        },
      },
    );
  }

  Positioned _buildNode(
    NodeElement node,
    ViewportTransformer viewport,
    double labelOpacity,
  ) {
    final origin = viewport.transform(node.screenX, node.screenY);
    return switch (node) {
      LocationElement() => Positioned(
        width: 10,
        height: 10,
        left: origin.dx,
        top: origin.dy,
        child: const FractionalTranslation(
          translation: Offset(-0.5, -0.5),
          child: _LocationNode(),
        ),
      ),
      FixtureElement() => RigFixtureNode.positioned(
        diagramPosition: Offset(node.screenX, node.screenY),
        viewport: viewport,
        fallbackSize: 16,
        geometry: node.fixtureVm.geometry,
        rotationZ: node.fixtureVm.fixture.rotationZ,
        label: node.fixtureVm.fixture.fid.toString(),
        subLabel: node.fixtureVm.fixtureType.shortName,
        labelOpacity: labelOpacity,
      ),
      PowerMultiHeaderElement() => Positioned(
        width: 16,
        height: 16,
        left: origin.dx,
        top: origin.dy,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: _PowerMultiNode(vm: node.powerMultiVm),
        ),
      ),
      DataMultiHeaderElement() => Positioned(
        width: 16,
        height: 16,
        left: origin.dx,
        top: origin.dy,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: _DataMultiNode(outletName: node.outletName),
        ),
      ),
      DataPatchHeaderElement() => Positioned(
        width: 16,
        height: 16,
        left: origin.dx,
        top: origin.dy,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: _DataPatchNode(
            outletName: node.outletName,
            universe: node.universe,
          ),
        ),
      ),
      TrussBreakElement() => Positioned(
        width: 6,
        height: 6,
        left: origin.dx,
        top: origin.dy,
        child: const FractionalTranslation(
          translation: Offset(-0.5, -0.5),
          child: _TrussBreakNode(),
        ),
      ),
    };
  }

  Widget _buildDataCableEdge({
    required CableEdgeElement edge,
    required Offset fromOffset,
    required Offset toOffset,
  }) {
    if (widget.vm.cableVisibility.dataState.contains(edge.runType) == false) {
      return const SizedBox();
    }

    return _DataCableEdge(
      from: fromOffset,
      to: toOffset,
      runType: edge.runType,
      label: _formatLength(edge.length),
      tuning: _tuning,
    );
  }

  Widget _buildPowerCableEdge({
    required CableEdgeElement edge,
    required Offset fromOffset,
    required Offset toOffset,
  }) {
    if (widget.vm.cableVisibility.powerState.contains(edge.runType) == false) {
      return const SizedBox();
    }

    return _PowerCableEdge(
      from: fromOffset,
      to: toOffset,
      label: _formatLength(edge.length),
      runType: edge.runType,
      tuning: _tuning,
    );
  }

  String _formatLength(double length) {
    return length.remainder(1) == 0
        ? '${length.toStringAsFixed(0)}m'
        : '${length.toStringAsFixed(1)}m';
  }
}

class _LocationNode extends StatelessWidget {
  const _LocationNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: SidekickColors.locationMarker,
      ),
    );
  }
}

class _TrussBreakNode extends StatelessWidget {
  const _TrussBreakNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.background,
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
    );
  }
}

/// A compact key explaining the graph's colour (cable type) and line-weight
/// (run type) encodings.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.typography.xSmall
        .copyWith(color: theme.colorScheme.mutedForeground);

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
          Text('Legend', style: theme.typography.xSmall.copyWith(
              color: theme.colorScheme.foreground,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _LegendSwatch(
              color: SidekickColors.powerRun, label: 'Power', style: labelStyle),
          _LegendSwatch(
              color: SidekickColors.dataRun, label: 'Data', style: labelStyle),
          _LegendSwatch(
              color: SidekickColors.dataMultiNode,
              label: 'Data multi',
              style: labelStyle),
          _LegendSwatch(
              color: SidekickColors.locationMarker,
              label: 'Location',
              style: labelStyle),
          const SizedBox(height: 8),
          _LegendLine(weight: 1, label: 'Link', style: labelStyle),
          _LegendLine(weight: 2, label: 'Fixture run', style: labelStyle),
          _LegendLine(weight: 3, label: 'Home run', style: labelStyle),
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

class _PowerMultiNode extends StatelessWidget {
  final PowerMultiHeaderViewModel vm;
  const _PowerMultiNode({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SidekickColors.powerMultiNode,
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: Text(
        vm.name,
        style: Theme.of(context).typography.mono.copyWith(fontSize: 6),
        textAlign: TextAlign.center,
        overflow: TextOverflow.clip,
      ),
    );
  }
}

class _DataMultiNode extends StatelessWidget {
  final String outletName;

  const _DataMultiNode({required this.outletName});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: SidekickColors.dataMultiNode,
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: Text(
        outletName,
        style: Theme.of(context).typography.mono.copyWith(fontSize: 6),
        textAlign: TextAlign.center,
        overflow: TextOverflow.clip,
      ),
    );
  }
}

class _DataPatchNode extends StatelessWidget {
  final String outletName;
  final int universe;

  const _DataPatchNode({required this.outletName, required this.universe});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SidekickColors.dataMultiNode,
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: Text(
        'U$universe',
        style: Theme.of(context).typography.mono.copyWith(fontSize: 6),
        textAlign: TextAlign.center,
        overflow: TextOverflow.clip,
      ),
    );
  }
}

class _PowerCableEdge extends StatelessWidget {
  final Offset from;
  final Offset to;
  final String? label;
  final CableRunType runType;
  final CableRouteTuning tuning;

  const _PowerCableEdge({
    required this.from,
    required this.to,
    required this.runType,
    required this.tuning,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ChannelConnector(
      start: from,
      end: to,
      color: switch (runType) {
        CableRunType.link => SidekickColors.powerLink,
        CableRunType.fixtureRun => SidekickColors.powerRun,
        CableRunType.homeRun => SidekickColors.powerHome,
      },
      width: switch (runType) {
        CableRunType.link => 1,
        CableRunType.fixtureRun => 1,
        CableRunType.homeRun => 2,
      },
      label: label,
      riser: tuning.powerRiser((to.dx - from.dx).abs()),
      cornerRadius: tuning.cornerRadius,
      directionUp: CableRouteTuning.directionUpFor(runType),
    );
  }
}

class _DataCableEdge extends StatelessWidget {
  final Offset from;
  final Offset to;
  final String? label;
  final CableRunType runType;
  final CableRouteTuning tuning;

  const _DataCableEdge({
    required this.from,
    required this.to,
    required this.runType,
    required this.tuning,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ChannelConnector(
      start: from,
      end: to,
      color: switch (runType) {
        CableRunType.link => SidekickColors.dataLink,
        CableRunType.fixtureRun => SidekickColors.dataRun,
        CableRunType.homeRun => SidekickColors.dataHome,
      },
      label: label,
      width: switch (runType) {
        CableRunType.link => 1,
        CableRunType.fixtureRun => 1,
        CableRunType.homeRun => 2,
      },
      riser: tuning.dataRiser((to.dx - from.dx).abs()),
      cornerRadius: tuning.cornerRadius,
      directionUp: CableRouteTuning.directionUpFor(runType),
    );
  }
}
