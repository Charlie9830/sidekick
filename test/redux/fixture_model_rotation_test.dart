import 'package:flutter_test/flutter_test.dart';
import 'package:mvr/mvr.dart';
import 'package:sidekick/extension_methods/mvr_matrix_extensions.dart';
import 'package:sidekick/redux/models/fixture_model.dart';

/// 90° about Z: local X points along world Y, local Y along world -X.
final _yaw90 = MVRMatrix([
  [0.0, 1.0, 0.0],
  [-1.0, 0.0, 0.0],
  [0.0, 0.0, 1.0],
  [0.0, 0.0, 0.0],
]);

void main() {
  test('rotation and position survive a toMap/fromMap round trip', () {
    final fixture = FixtureModel(uid: 'f', x: 1, y: 2, z: 3, rotation: _yaw90);

    final restored = FixtureModel.fromMap(fixture.toMap());

    expect(restored.rotation.matrix, _yaw90.matrix);
    expect((restored.x, restored.y, restored.z), (1.0, 2.0, 3.0));
  });

  test('files without a rotation load with no rotation', () {
    final map = FixtureModel(uid: 'f').toMap()..remove('rotation');

    expect(
      FixtureModel.fromMap(map).rotation.matrix,
      const MVRMatrix.identity().matrix,
    );
  });

  test('Euler getters are derived from the rotation', () {
    final fixture = FixtureModel(rotation: _yaw90);

    expect(fixture.rotationZ, closeTo(90, 1e-9));
    expect(fixture.rotationX, closeTo(0, 1e-9));
    expect(fixture.rotationY, closeTo(0, 1e-9));
  });

  test('transform maps fixture-local points into the world', () {
    final fixture = FixtureModel(x: 1000, rotation: _yaw90);

    // A connector 500 mm along the fixture's own X axis.
    final world = fixture.transform.transform(MVRVector3(500, 0, 0));

    expect((world.x, world.y, world.z), (1000.0, 500.0, 0.0));
  });

  test('rotationOnly strips the translation from an imported matrix', () {
    final imported = _yaw90.withTranslation(10, 20, 30);

    expect(imported.rotationOnly.matrix, _yaw90.matrix);
  });
}
