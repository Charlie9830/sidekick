import 'package:collection/collection.dart';
import 'package:flutter_scene/scene.dart' show Camera;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/cable_graph/vector3.dart';
import 'package:sidekick/widgets/rig_viewer/scene/world_space.dart';

/// Most labels drawn at once. Like the console's "Max Label Count", the ones
/// nearest the camera win, so a zoomed-out rig stays legible.
const int kMaxRigLabels = 150;

/// A piece of text pinned to a world position.
typedef RigLabel = ({Vector3 anchor, String text, bool emphasised});

/// Draws [labels] over the 3D view at their projected screen positions.
///
/// Purely visual: it ignores pointer input so the scene beneath keeps every
/// gesture.
class RigLabelLayer extends StatelessWidget {
  final List<RigLabel> labels;
  final Camera camera;
  final Size viewSize;

  const RigLabelLayer({
    super.key,
    required this.labels,
    required this.camera,
    required this.viewSize,
  });

  @override
  Widget build(BuildContext context) {
    final eye = camera.position;
    final visible = <(RigLabel, Offset, double)>[];
    for (final label in labels) {
      final scene = WorldSpace.toScene(label.anchor);
      final screen = camera.worldToScreen(scene, viewSize);
      if (screen == null || !_onScreen(screen)) continue;
      visible.add((label, screen, scene.distanceToSquared(eye)));
    }

    final nearest = visible
        .sortedBy<num>((entry) => entry.$3)
        .take(kMaxRigLabels);

    return IgnorePointer(
      child: Stack(
        children: [
          for (final (label, screen, _) in nearest)
            Positioned(
              left: screen.dx,
              top: screen.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: _LabelChip(
                  text: label.text,
                  emphasised: label.emphasised,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _onScreen(Offset p) =>
      p.dx >= 0 &&
      p.dy >= 0 &&
      p.dx <= viewSize.width &&
      p.dy <= viewSize.height;
}

class _LabelChip extends StatelessWidget {
  final String text;
  final bool emphasised;

  const _LabelChip({required this.text, required this.emphasised});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: emphasised ? 0.85 : 0.55),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: theme.typography.mono.copyWith(
          fontSize: 10,
          color: Colors.white,
          fontWeight: emphasised ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}
