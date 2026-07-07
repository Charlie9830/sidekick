import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/screens/sequencer_dialog/fixture_spatial_sort.dart';

FixtureModel _fixture(
  String uid, {
  double x = 0,
  double y = 0,
  bool hasMatrixData = true,
}) =>
    FixtureModel(uid: uid, x: x, y: y, hasMatrixData: hasMatrixData);

List<String> _uids(List<FixtureModel> fixtures) =>
    fixtures.map((f) => f.uid).toList();

void main() {
  group('hasUsableCoords', () {
    test('is false when no fixture has matrix data', () {
      final fixtures = [
        _fixture('a', hasMatrixData: false),
        _fixture('b', hasMatrixData: false),
      ];

      expect(hasUsableCoords(fixtures), isFalse);
    });

    test('is true when any fixture has matrix data', () {
      final fixtures = [
        _fixture('a', hasMatrixData: false),
        _fixture('b', hasMatrixData: true),
      ];

      expect(hasUsableCoords(fixtures), isTrue);
    });
  });

  group('sortFixturesSpatially', () {
    test('X axis orders left to right', () {
      // Arrange
      final fixtures = [
        _fixture('right', x: 300),
        _fixture('left', x: 100),
        _fixture('middle', x: 200),
      ];

      // Act
      final sorted = sortFixturesSpatially(fixtures, FixtureSortAxis.x);

      // Assert
      expect(_uids(sorted), ['left', 'middle', 'right']);
    });

    test('Y axis orders top to bottom (higher world-Y first)', () {
      // The plan projection negates world Y, so the largest Y sorts first.
      final fixtures = [
        _fixture('low', y: 0),
        _fixture('high', y: 500),
        _fixture('mid', y: 250),
      ];

      final sorted = sortFixturesSpatially(fixtures, FixtureSortAxis.y);

      expect(_uids(sorted), ['high', 'mid', 'low']);
    });

    test('descending reverses the axis order', () {
      final fixtures = [
        _fixture('a', x: 100),
        _fixture('b', x: 200),
        _fixture('c', x: 300),
      ];

      final sorted =
          sortFixturesSpatially(fixtures, FixtureSortAxis.x, descending: true);

      expect(_uids(sorted), ['c', 'b', 'a']);
    });

    test('uses the other axis as a stable tie-break', () {
      final fixtures = [
        _fixture('shareX_lowY', x: 100, y: 0),
        _fixture('shareX_highY', x: 100, y: 400),
      ];

      final sorted = sortFixturesSpatially(fixtures, FixtureSortAxis.x);

      // Same X → tie-break on projected Y (-worldY), so higher world-Y first.
      expect(_uids(sorted), ['shareX_highY', 'shareX_lowY']);
    });

    test('selectionOrder preserves original order', () {
      final fixtures = [
        _fixture('c', x: 300),
        _fixture('a', x: 100),
        _fixture('b', x: 200),
      ];

      final sorted =
          sortFixturesSpatially(fixtures, FixtureSortAxis.selectionOrder);

      expect(_uids(sorted), ['c', 'a', 'b']);
    });

    test('selectionOrder descending reverses selection', () {
      final fixtures = [
        _fixture('c'),
        _fixture('a'),
        _fixture('b'),
      ];

      final sorted = sortFixturesSpatially(
          fixtures, FixtureSortAxis.selectionOrder,
          descending: true);

      expect(_uids(sorted), ['b', 'a', 'c']);
    });
  });
}
