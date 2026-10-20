import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:sidekick/widgets/rig_viewer/camera/rig_camera_state.dart';

/// Builds the flutter_scene camera for [state].
///
/// The up vector comes from [RigCameraState.up] rather than world Y, so the
/// Top and Bottom views (looking straight down or up) stay well defined.
PerspectiveCamera rigCamera(RigCameraState state) => PerspectiveCamera(
  fovRadiansY: state.fovY,
  position: state.eye,
  target: state.target,
  up: state.up,
  fovNear: math.max(state.distance * 1e-3, 0.01),
  fovFar: math.max(state.distance * 20, 500),
);
