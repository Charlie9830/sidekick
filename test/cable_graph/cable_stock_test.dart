import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/cable_graph/cabling/cable_stock.dart';

void main() {
  const stock = [1.0, 2.0, 5.0];

  group('roundUpToStock', () {
    test('rounds up to the next stock length', () {
      expect(roundUpToStock(1200, stock), 2);
      expect(roundUpToStock(2001, stock), 5);
    });

    test('an exact stock length is kept', () {
      expect(roundUpToStock(2000, stock), 2);
    });

    test('short and zero lengths use the shortest stock length', () {
      expect(roundUpToStock(0, stock), 1);
      expect(roundUpToStock(300, stock), 1);
    });

    test('lengths beyond the longest stock length are clamped to it', () {
      expect(roundUpToStock(80000, stock), 5);
    });

    test('fractional millimetres round up before converting', () {
      // 1000.4 mm ceils to 1001 mm, which no longer fits a 1 m cable.
      expect(roundUpToStock(1000.4, stock), 2);
    });
  });
}
