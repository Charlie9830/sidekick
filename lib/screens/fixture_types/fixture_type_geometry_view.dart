import 'package:material_ui/material_ui.dart' show Icons;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/view_models/fixture_types_view_model.dart';
import 'package:sidekick/widgets/rig_viewer/rig_viewer.dart';
import 'package:sidekick/widgets/rig_viewer/scene/rig_fixture_builder.dart';
import 'package:sidekick/widgets/rig_viewer/scene/rig_scene_model.dart';

/// A side panel previewing one fixture type's imported GDTF geometry in 3D.
///
/// The type is drawn on its own at the origin, unrotated and lifted so its
/// lowest part rests on the floor grid, with its wiring objects shown as
/// connector boxes. Types imported without geometry show a notice instead.
class FixtureTypeGeometryView extends StatelessWidget {
  final FixtureTypeViewModel vm;
  final VoidCallback onClose;

  const FixtureTypeGeometryView({
    super.key,
    required this.vm,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final geometry = vm.geometry;
    final hasGeometry = geometry != null && geometry.parts.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(vm: vm, onClose: onClose),
        Expanded(
          child: hasGeometry
              ? _GeometryViewer(vm: vm)
              : const _NoGeometryNotice(),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final FixtureTypeViewModel vm;
  final VoidCallback onClose;

  const _Header({required this.vm, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final partCount = vm.geometry?.parts.length ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vm.type.name, overflow: TextOverflow.ellipsis).semiBold,
                Text(
                  partCount == 0
                      ? 'No geometry'
                      : '$partCount part${partCount == 1 ? '' : 's'}',
                ).muted.small,
              ],
            ),
          ),
          IconButton.ghost(
            icon: const Icon(Icons.close),
            size: ButtonSize.small,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _GeometryViewer extends StatelessWidget {
  final FixtureTypeViewModel vm;

  const _GeometryViewer({required this.vm});

  @override
  Widget build(BuildContext context) {
    final geometry = vm.geometry;
    final fixture = FixtureModel(
      uid: vm.uid,
      typeId: vm.uid,
      z: -(geometry?.boundingBoxMin.z ?? 0),
    );

    // Keyed by type so switching types starts a fresh camera framed on the
    // new geometry.
    return RigViewer(
      key: ValueKey(vm.uid),
      scene: RigSceneModel(
        fixtures: [
          buildRigFixture(
            fixture: fixture,
            geometry: geometry,
            fixtureType: vm.type,
            color: SidekickColors.rigMesh,
            tooltip: vm.type.name,
          ),
        ],
      ),
      focusIds: {vm.uid},
    );
  }
}

class _NoGeometryNotice extends StatelessWidget {
  const _NoGeometryNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Icon(
              Icons.view_in_ar_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.mutedForeground,
            ),
            const Text('No 3D geometry available').semiBold,
            const Text(
              'Geometry is captured from GDTF data when importing an MVR file.',
              textAlign: TextAlign.center,
            ).muted.small,
          ],
        ),
      ),
    );
  }
}
