import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart' show Scene, SceneView;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/theme/sidekick_colors.dart';
import 'package:sidekick/widgets/rig_viewer/camera/rig_camera.dart';
import 'package:sidekick/widgets/rig_viewer/camera/rig_camera_state.dart';
import 'package:sidekick/widgets/rig_viewer/chrome/label_layer.dart';
import 'package:sidekick/widgets/rig_viewer/chrome/tool_bar.dart';
import 'package:sidekick/widgets/rig_viewer/scene/picking.dart';
import 'package:sidekick/widgets/rig_viewer/scene/rig_scene_model.dart';
import 'package:sidekick/widgets/rig_viewer/scene/rig_scene_renderer.dart';
import 'package:sidekick/widgets/rig_viewer/scene/world_space.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Pointer travel (px) after which a press counts as a drag, not a click.
const double _kDragSlop = 4;

/// Radians of orbit per pixel dragged.
const double _kOrbitRate = 0.008;

/// Zoom factor per pixel of scroll (or of drag in Zoom mode).
const double _kZoomRate = 0.0015;

const Duration _kFlightDuration = Duration(milliseconds: 250);

/// Furthest the floor may be, as a multiple of the target distance, and still
/// be what a zoom heads for; beyond it zooms aim at the target's depth.
const double _kMaxFloorFocusRatio = 3;

/// How close (px) the pointer must be to a line to show its tooltip.
const double _kLineHoverSlop = 6;

/// A 3D view of the rig modelled on the grandMA3 3D window.
///
/// Draws [scene] with flutter_scene and navigates like the console: a left
/// drag follows the active [RigToolMode] (Move, Rotate Center, Zoom, Rotate
/// Selection...), a right drag always orbits the selection, a middle drag
/// always moves, and the scroll wheel (or a trackpad's two-finger scroll and
/// pinch) zooms toward whatever is under the pointer. The
/// selection is [focusIds]; with nothing selected, orbits turn around the
/// centre of the view. F fits the rig and Shift+F fits the selection.
///
/// Pages describe what to draw as a [RigSceneModel] and react to clicks via
/// [onFixtureTap]; [overlays] are screen-fixed widgets (legends, filters)
/// stacked above the view.
class RigViewer extends StatefulWidget {
  final RigSceneModel scene;

  /// Called when a fixture is clicked in [RigToolMode.select].
  final ValueChanged<String>? onFixtureTap;

  /// Called when the fixture under the pointer changes (null when none).
  final ValueChanged<String?>? onFixtureHover;

  /// The selection: framed by Fit Selected and orbited by Rotate Selection.
  /// Empty disables Fit Selected.
  final Set<String> focusIds;

  final RigViewPreset initialPreset;
  final RigToolMode initialMode;

  /// Whether connector boxes start visible; the toolbar toggles them.
  final bool initialShowConnectors;
  final List<Widget> overlays;

  const RigViewer({
    super.key,
    required this.scene,
    this.onFixtureTap,
    this.onFixtureHover,
    this.focusIds = const {},
    this.initialPreset = RigViewPreset.perspective,
    this.initialMode = RigToolMode.rotateSelection,
    this.initialShowConnectors = true,
    this.overlays = const [],
  });

  @override
  State<RigViewer> createState() => _RigViewerState();
}

class _RigViewerState extends State<RigViewer>
    with SingleTickerProviderStateMixin {
  static final Future<void> _staticResources =
      Scene.initializeStaticResources();

  final RigSceneRenderer _renderer = RigSceneRenderer();
  final ValueNotifier<RigCameraState?> _camera = ValueNotifier(null);
  final FocusNode _focusNode = FocusNode(debugLabel: 'RigViewer');

  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: _kFlightDuration,
  )..addListener(_handleFlightTick);
  RigCameraState? _flightFrom;
  RigCameraState? _flightTo;

  late RigToolMode _mode = widget.initialMode;
  bool _showLabels = true;
  late bool _showConnectors = widget.initialShowConnectors;
  Size _viewSize = Size.zero;

  Offset? _pressPosition;
  int _pressButtons = 0;
  bool _dragged = false;
  double _lastPanZoomScale = 1;

  String? _hoveredId;
  String? _hoverTooltip;
  Offset? _hoverPosition;

  @override
  void initState() {
    super.initState();
    _renderer.update(widget.scene);
  }

  @override
  void didUpdateWidget(RigViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _renderer.update(widget.scene);
  }

  @override
  void dispose() {
    _flight.dispose();
    _camera.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  RigCameraState get _currentCamera =>
      _camera.value ?? RigCameraState.preset(widget.initialPreset);

  void _setCamera(RigCameraState camera) {
    _flight.stop();
    _camera.value = camera;
  }

  void _flyTo(RigCameraState target) {
    _flightFrom = _currentCamera;
    _flightTo = target;
    _flight.forward(from: 0);
  }

  void _handleFlightTick() {
    final from = _flightFrom;
    final to = _flightTo;
    if (from == null || to == null) return;
    _camera.value = RigCameraState.lerp(
      from,
      to,
      Curves.easeInOut.transform(_flight.value),
    );
  }

  // ── Camera commands ─────────────────────────────────────────────────────

  void _fit() {
    final bounds = _renderer.bounds;
    if (bounds == null || _viewSize.isEmpty) return;
    _flyTo(_currentCamera.framing(bounds, _viewSize));
  }

  void _fitSelected() {
    final bounds = _focusBounds();
    if (bounds == null || _viewSize.isEmpty) return;
    _flyTo(_currentCamera.framing(bounds, _viewSize));
  }

  void _applyPreset(RigViewPreset preset) {
    final turned = _currentCamera.withPreset(preset);
    final bounds = _renderer.bounds;
    _flyTo(
      bounds == null || _viewSize.isEmpty
          ? turned
          : turned.framing(bounds, _viewSize),
    );
  }

  vm.Aabb3? _focusBounds() {
    final points = [
      for (final fixture in widget.scene.fixtures)
        if (widget.focusIds.contains(fixture.id))
          for (final part in fixture.parts)
            for (final corner in part.box.corners) WorldSpace.toScene(corner),
    ];
    if (points.isEmpty) return null;

    final bounds = vm.Aabb3.minMax(points.first.clone(), points.first.clone());
    for (final point in points.skip(1)) {
      bounds.hullPoint(point);
    }
    return bounds;
  }

  // ── Picking ─────────────────────────────────────────────────────────────

  PickHit? _pickAt(Offset position) {
    if (_viewSize.isEmpty) return null;
    final camera = _currentCamera;
    final ray = WorldRay(
      WorldSpace.fromScene(camera.eye),
      WorldSpace.directionFromScene(camera.rayThrough(position, _viewSize)),
    );
    return pick(ray, _renderer.pickTargets);
  }

  // ── Pointer input ───────────────────────────────────────────────────────

  void _handlePointerDown(PointerDownEvent event) {
    _focusNode.requestFocus();
    _flight.stop();
    _pressPosition = event.localPosition;
    _pressButtons = event.buttons;
    _dragged = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final press = _pressPosition;
    if (press == null) return;
    if (!_dragged && (event.localPosition - press).distance < _kDragSlop) {
      return;
    }
    _dragged = true;
    _drag(event.delta, _pressButtons);
  }

  void _drag(Offset delta, int buttons) {
    final camera = _currentCamera;
    final orbitYaw = delta.dx * _kOrbitRate;
    final orbitPitch = delta.dy * _kOrbitRate;

    if (buttons & kSecondaryMouseButton != 0) {
      _setCamera(_orbitSelection(camera, orbitYaw, orbitPitch));
      return;
    }
    if (buttons & kMiddleMouseButton != 0) {
      _setCamera(camera.move(delta, _viewSize));
      return;
    }

    switch (_mode) {
      case RigToolMode.select:
        return;
      case RigToolMode.move:
        _setCamera(camera.move(delta, _viewSize));
      case RigToolMode.rotateCenter:
        _setCamera(camera.orbit(orbitYaw, orbitPitch));
      case RigToolMode.zoom:
        _zoomAt(
          _pressPosition ?? _viewSize.center(Offset.zero),
          math.exp(delta.dy * _kZoomRate * 4),
        );
      case RigToolMode.rotateSelection:
        _setCamera(_orbitSelection(camera, orbitYaw, orbitPitch));
    }
  }

  /// Orbits around the centre of the selection, or around the centre of the
  /// view when nothing is selected.
  RigCameraState _orbitSelection(
    RigCameraState camera,
    double yaw,
    double pitch,
  ) {
    final selection = _focusBounds();
    return selection == null
        ? camera.orbit(yaw, pitch)
        : camera.orbitAround(selection.center, yaw, pitch);
  }

  void _handlePointerUp(PointerUpEvent event) {
    final press = _pressPosition;
    _pressPosition = null;
    if (press == null || _dragged || _pressButtons != kPrimaryMouseButton) {
      return;
    }
    _click(event.localPosition);
  }

  void _click(Offset position) {
    if (_mode != RigToolMode.select) return;
    final hit = _pickAt(position);
    if (hit != null) widget.onFixtureTap?.call(hit.id);
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    _zoomAt(event.localPosition, math.exp(event.scrollDelta.dy * _kZoomRate));
  }

  void _handlePanZoomStart(PointerPanZoomStartEvent event) {
    _flight.stop();
    _lastPanZoomScale = 1;
  }

  /// Trackpads report two-finger scrolling and pinching as one gesture; both
  /// zoom toward the pointer, matching the mouse wheel.
  void _handlePanZoomUpdate(PointerPanZoomUpdateEvent event) {
    var factor = math.exp(-event.panDelta.dy * _kZoomRate * 2);
    if (event.scale > 0 && event.scale != _lastPanZoomScale) {
      factor *= _lastPanZoomScale / event.scale;
      _lastPanZoomScale = event.scale;
    }
    if (factor != 1) _zoomAt(event.localPosition, factor);
  }

  /// Zooms toward whatever is under [position] in the view.
  void _zoomAt(Offset position, double factor) {
    final camera = _currentCamera;
    _setCamera(camera.zoomTowardPoint(_focusUnder(camera, position), factor));
  }

  /// The scene point under [position]: the fixture there, else the floor
  /// (when it is not so far off that one notch would leap toward the
  /// horizon), else the point at the camera target's depth.
  vm.Vector3 _focusUnder(RigCameraState camera, Offset position) {
    final hit = _pickAt(position);
    if (hit != null) return WorldSpace.toScene(hit.point);

    final eye = camera.eye;
    final ray = camera.rayThrough(position, _viewSize);
    if (ray.y.abs() > 1e-6) {
      final toFloor = -eye.y / ray.y;
      if (toFloor > 0 && toFloor < camera.distance * _kMaxFloorFocusRatio) {
        return eye + ray * toFloor;
      }
    }
    return eye + ray * (camera.distance / ray.dot(camera.forward));
  }

  void _handleHover(PointerHoverEvent event) {
    final position = event.localPosition;
    final id = _pickAt(position)?.id;
    final tooltip = id != null
        ? _fixtureById(id)?.tooltip
        : _lineAt(position)?.tooltip;
    if (id == _hoveredId && tooltip == null && _hoverTooltip == null) return;

    final changed = id != _hoveredId;
    setState(() {
      _hoveredId = id;
      _hoverTooltip = tooltip;
      _hoverPosition = position;
    });
    if (changed) widget.onFixtureHover?.call(id);
  }

  void _handleExit(PointerExitEvent event) {
    if (_hoveredId == null && _hoverTooltip == null) return;
    final hadFixture = _hoveredId != null;
    setState(() {
      _hoveredId = null;
      _hoverTooltip = null;
    });
    if (hadFixture) widget.onFixtureHover?.call(null);
  }

  /// The line with a tooltip passing nearest [position] on screen, within
  /// [_kLineHoverSlop] pixels.
  RigLine? _lineAt(Offset position) {
    if (_viewSize.isEmpty) return null;
    final camera = rigCamera(_currentCamera);

    RigLine? nearest;
    var nearestDistance = _kLineHoverSlop;
    for (final line in widget.scene.lines) {
      if (line.tooltip == null) continue;
      Offset? previous;
      for (final point in line.points) {
        final screen = camera.worldToScreen(
          WorldSpace.toScene(point),
          _viewSize,
        );
        if (previous != null && screen != null) {
          final distance = _distanceToSegment(position, previous, screen);
          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearest = line;
          }
        }
        previous = screen;
      }
    }
    return nearest;
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lengthSquared = ab.distanceSquared;
    final t = lengthSquared == 0
        ? 0.0
        : (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / lengthSquared).clamp(
            0.0,
            1.0,
          );
    return (p - (a + ab * t)).distance;
  }

  RigFixture? _fixtureById(String id) =>
      widget.scene.fixtures.where((fixture) => fixture.id == id).firstOrNull;

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _staticResources,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          developer.log(
            '3D rig view failed to initialise',
            name: 'sidekick.rig_viewer',
            level: 1000,
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          return _Unavailable(error: snapshot.error!);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const ColoredBox(
            color: SidekickColors.rigBackground,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildViewer();
      },
    );
  }

  Widget _buildViewer() {
    return Semantics(
      label: '3D rig view',
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF): _fit,
          const SingleActivator(LogicalKeyboardKey.keyF, shift: true):
              _fitSelected,
        },
        child: Focus(
          focusNode: _focusNode,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _viewSize = constraints.biggest;
              _frameInitially();
              return Stack(
                children: [
                  Positioned.fill(child: _buildScene()),
                  Positioned.fill(child: _buildCameraOverlays()),
                  // Scrolls rather than overflows in short panes, such as
                  // the sequencer's top placement.
                  Positioned(
                    left: 8,
                    top: 8,
                    bottom: 8,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SingleChildScrollView(child: _buildToolBar()),
                    ),
                  ),
                  ...widget.overlays,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Frames the whole rig the first time the view has a size.
  void _frameInitially() {
    if (_camera.value != null || _viewSize.isEmpty) return;
    final preset = RigCameraState.preset(widget.initialPreset);
    final bounds = _renderer.bounds;
    _camera.value = bounds == null ? preset : preset.framing(bounds, _viewSize);
  }

  Widget _buildScene() {
    _renderer.showConnectors = _showConnectors;
    return ColoredBox(
      color: SidekickColors.rigBackground,
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerSignal: _handleScroll,
        onPointerPanZoomStart: _handlePanZoomStart,
        onPointerPanZoomUpdate: _handlePanZoomUpdate,
        child: MouseRegion(
          onHover: _handleHover,
          onExit: _handleExit,
          child: SceneView(
            _renderer.scene,
            cameraBuilder: (_) => rigCamera(_currentCamera),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraOverlays() {
    return ValueListenableBuilder<RigCameraState?>(
      valueListenable: _camera,
      builder: (context, state, _) {
        final camera = rigCamera(state ?? _currentCamera);
        final tooltip = _hoverTooltip;
        final hoverPosition = _hoverPosition;

        return Stack(
          children: [
            if (_showLabels)
              Positioned.fill(
                child: RigLabelLayer(
                  labels: _labels(),
                  camera: camera,
                  viewSize: _viewSize,
                ),
              ),
            if (tooltip != null && hoverPosition != null)
              Positioned(
                left: hoverPosition.dx + 14,
                top: hoverPosition.dy + 14,
                child: IgnorePointer(
                  child: SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(tooltip),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<RigLabel> _labels() => [
    for (final fixture in widget.scene.fixtures)
      if (fixture.label != null)
        (
          anchor: fixture.labelAnchor,
          text: fixture.label!,
          emphasised:
              fixture.id == _hoveredId ||
              fixture.color == SidekickColors.rigSelection,
        ),
    for (final marker in widget.scene.markers)
      if (marker.label != null)
        (anchor: marker.position, text: marker.label!, emphasised: false),
  ];

  Widget _buildToolBar() {
    return RigToolBar(
      mode: _mode,
      onModeChanged: (mode) => setState(() => _mode = mode),
      onFit: _fit,
      onFitSelected: widget.focusIds.isEmpty ? null : _fitSelected,
      onPreset: _applyPreset,
      showLabels: _showLabels,
      onShowLabelsChanged: (value) => setState(() => _showLabels = value),
      showConnectors: _showConnectors,
      onShowConnectorsChanged: (value) =>
          setState(() => _showConnectors = value),
    );
  }
}

/// Shown instead of the view when Flutter GPU cannot start, e.g. on a
/// machine whose graphics driver Impeller does not support.
class _Unavailable extends StatelessWidget {
  final Object error;

  const _Unavailable({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            const Icon(LucideIcons.triangleAlert),
            const Text('3D view unavailable').semiBold(),
            Text('$error').muted().small(),
          ],
        ),
      ),
    );
  }
}
