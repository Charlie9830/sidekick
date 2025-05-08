import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:sidekick/extension_methods/queue_pop.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/loom_stock_model.dart';

const String kSocaSlug = 'Soca';
const String kWielandSlug = '6way';

// ignore: non_constant_identifier_names
final Set<double> _2wayLengths = {20, 30, 40, 50};
// ignore: non_constant_identifier_names
final Set<double> _3and5wayLengths = {25, 30, 35, 40, 45, 50};

class PermanentLoomComposition {
  final int socaWays;
  final int wieland6Ways;
  final int dmxWays;
  final int sneakWays;
  final Set<double> validLengths;

  const PermanentLoomComposition._({
    required this.socaWays,
    required this.wieland6Ways,
    required this.dmxWays,
    required this.sneakWays,
    required this.validLengths,
  });

  const PermanentLoomComposition.none()
      : socaWays = 0,
        wieland6Ways = 0,
        dmxWays = 0,
        sneakWays = 0,
        validLengths = const {};

  String get uid => name;

  String get name => _buildName();

  int get powerWays => socaWays != 0 ? socaWays : wieland6Ways;

  bool isValidComposition(List<CableModel> cables) {
    final incomingSoca =
        cables.where((cable) => cable.type == CableType.socapex).length;
    final incomingWieland6way =
        cables.where((cable) => cable.type == CableType.wieland6way).length;
    final incomingDmx =
        cables.where((cable) => cable.type == CableType.dmx).length;
    final incomingSneak =
        cables.where((cable) => cable.type == CableType.sneak).length;

    return incomingSoca == socaWays &&
        incomingWieland6way == wieland6Ways &&
        incomingSneak == sneakWays &&
        incomingDmx == dmxWays;
  }

  LoomSatisfactionResult satisfied(List<CableModel> cables) {
    if (cables.isEmpty) {
      return LoomSatisfactionResult(
        satisfied: false,
        satisfiedAtLength: 0,
        error: UnsatisfiedError.noCables,
      );
    }

    final incomingSoca =
        cables.where((cable) => cable.type == CableType.socapex).length;
    final incomingWieland6way =
        cables.where((cable) => cable.type == CableType.wieland6way).length;
    final incomingDmx =
        cables.where((cable) => cable.type == CableType.dmx).length;
    final incomingSneak =
        cables.where((cable) => cable.type == CableType.sneak).length;

    final socaSatisfied =
        incomingWieland6way > 0 ? false : incomingSoca <= socaWays;
    final wieland6Satisfied =
        incomingSoca > 0 ? false : incomingWieland6way <= wieland6Ways;
    final dmxSatisfied = incomingSneak > 0 ? false : incomingDmx <= dmxWays;
    final sneakSatisfied = incomingDmx > 0 ? false : incomingSneak <= sneakWays;

    final compositionSatisfied = (socaSatisfied || wieland6Satisfied) &&
        (sneakSatisfied || dmxSatisfied);

    if (compositionSatisfied == false) {
      return LoomSatisfactionResult(
          satisfied: false,
          satisfiedAtLength: 0,
          error: UnsatisfiedError.noSuitableComposition);
    }

    final suitableLength = _matchSuitableLength(cables);

    if (suitableLength == null) {
      return LoomSatisfactionResult(
        satisfied: false,
        satisfiedAtLength: 0,
        error: UnsatisfiedError.noSuitableLength,
      );
    }

    return LoomSatisfactionResult(
        satisfied: true, satisfiedAtLength: suitableLength, error: null);
  }

  double? _matchSuitableLength(List<CableModel> cables) {
    final longestCandidateCableLength = cables
        .map((cable) => cable.length)
        .sorted((a, b) => a.ceil() - b.ceil())
        .last;
    final longestValidLength =
        validLengths.toList().sorted((a, b) => a.ceil() - b.ceil()).last;

    if (longestCandidateCableLength > longestValidLength) {
      return null;
    }

    return _roundUpToLength(longestCandidateCableLength, validLengths);
  }

  double _roundUpToNearestRadix(double number, double radix) {
    double a = number % radix;

    if (a > 0) {
      return (number ~/ radix) * radix + radix;
    }

    return number;
  }

  double? _roundUpToLength(double candidate, Set<double> lengths) {
    double radixedCandidate = _roundUpToNearestRadix(candidate, 5);

    while (radixedCandidate <= 50.0) {
      if (lengths.contains(radixedCandidate)) {
        return radixedCandidate;
      }

      radixedCandidate += 5.0;
    }

    return null;
  }

  String _buildName() {
    String name = '';

    if (socaWays > 0) {
      name = '$name${socaWays}way $kSocaSlug ';
    }

    if (wieland6Ways > 0) {
      name = '$name${wieland6Ways}way $kWielandSlug ';
    }

    if (dmxWays > 0) {
      name = '$name+ $dmxWays XLR';
    }

    if (sneakWays > 0) {
      if (sneakWays == 1) {
        name = '$name+ Sneak';
      } else {
        name = '$name+ $sneakWays Sneak';
      }
    }

    return name;
  }

  static List<PermanentLoomComposition> matchToPermanents(
      List<CableModel> cables) {
    final singleMatchResult = matchSuitablePermanent(cables);

    if (singleMatchResult.error != null) {
      // A suitable match was found that covers all provided Cables.
      return [singleMatchResult.composition];
    }

    final powerWayQueue = Queue<CableModel>.from(cables.where((cable) =>
        cable.type == CableType.socapex ||
        cable.type == CableType.wieland6way));

    final dataWayQueue = Queue<CableModel>.from(cables.where((cable) =>
        cable.type == CableType.dmx || cable.type == CableType.sneak));

    final matches = <PermanentLoomComposition>[];

    while (powerWayQueue.isNotEmpty && dataWayQueue.isNotEmpty) {
      final powerWays = powerWayQueue.pop(5);
      final dataWays = dataWayQueue.pop(2);

      final candidate = matchSuitablePermanent([...powerWays, ...dataWays]);

      if (candidate.error != null) {
        matches.add(candidate.composition);
      }
    }

    return matches;
  }

  static PermanentLoomCompositionResult matchSuitablePermanent(
      List<CableModel> cables) {
    if (cables.isEmpty) {
      return PermanentLoomCompositionResult(
          composition: const PermanentLoomComposition.none(),
          length: 0,
          error: 'No suitable candidate cables provided.');
    }

    if (cables.any((cable) =>
            cable.type == CableType.socapex ||
            cable.type == CableType.wieland6way) ==
        false) {
      // Shouldn't return a Permanent if there are no suitable power ways.
      return PermanentLoomCompositionResult(
          composition: const PermanentLoomComposition.none(),
          length: 0,
          error:
              "Provided cables did not include any Socapex or 6way's. Consider using a Custom sneak or DMX loom, or create spare Socapex or 6way.");
    }

    final compositionResults =
        validCompositions.map((comp) => (comp.satisfied(cables), comp));

    final firstValidResult =
        compositionResults.firstWhereOrNull((result) => result.$1.satisfied);

    if (firstValidResult != null) {
      final (result, composition) = firstValidResult;

      return PermanentLoomCompositionResult(
        composition: composition,
        length: result.satisfiedAtLength,
        error: null,
      );
    }

    return PermanentLoomCompositionResult(
        composition: const PermanentLoomComposition.none(),
        length: 0,
        error:
            'This could be caused by a cable being longer then 50m, or trying to convert too many cables at once.');
  }

  static List<PermanentLoomComposition> validCompositions = [
    // 2 way Socapex + 2 DMX.
    PermanentLoomComposition._(
      socaWays: 2,
      wieland6Ways: 0,
      dmxWays: 2,
      sneakWays: 0,
      validLengths: _2wayLengths,
    ),

    // 3 way Socapex + Sneak.
    PermanentLoomComposition._(
      socaWays: 3,
      wieland6Ways: 0,
      dmxWays: 0,
      sneakWays: 1,
      validLengths: _3and5wayLengths,
    ),

    // 5 way Socapex + Sneak.
    PermanentLoomComposition._(
        socaWays: 5,
        wieland6Ways: 0,
        dmxWays: 0,
        sneakWays: 1,
        validLengths: _3and5wayLengths),

    // 2 way 6way + 2 DMX.
    PermanentLoomComposition._(
      socaWays: 0,
      wieland6Ways: 2,
      dmxWays: 2,
      sneakWays: 0,
      validLengths: _2wayLengths,
    ),

    // 3 way 6way + Sneak.
    PermanentLoomComposition._(
      socaWays: 0,
      wieland6Ways: 3,
      dmxWays: 0,
      sneakWays: 1,
      validLengths: _3and5wayLengths,
    ),

    // 5 way 6way + Sneak.
    PermanentLoomComposition._(
      socaWays: 0,
      wieland6Ways: 5,
      dmxWays: 0,
      sneakWays: 2,
      validLengths: _3and5wayLengths,
    ),
  ];

  static Map<String, PermanentLoomComposition> byName =
      Map<String, PermanentLoomComposition>.fromEntries(
    validCompositions.map(
      (comp) => MapEntry(comp.name, comp),
    ),
  );

  static List<LoomStockModel> buildAllLoomQuantities() => validCompositions
      .expand(
        (comp) => comp.validLengths.map(
          (length) => LoomStockModel(
              compositionName: comp.name,
              length: length,
              qty: _getDefaultStockQtyOfComposition(comp)),
        ),
      )
      .toList();

  static int _getDefaultStockQtyOfComposition(PermanentLoomComposition comp) {
    if (comp.socaWays == 2 || comp.wieland6Ways == 2) {
      return 4;
    }

    if (comp.socaWays == 3 || comp.socaWays == 5) {
      return 4;
    }

    return 2;
  }

  @override
  String toString() {
    return name;
  }
}

class PermanentLoomCompositionResult {
  final PermanentLoomComposition composition;
  final double length;
  final String? error;

  PermanentLoomCompositionResult({
    required this.composition,
    required this.length,
    required this.error,
  });
}

enum UnsatisfiedError {
  noSuitableComposition,
  noSuitableLength,
  noCables,
}

class LoomSatisfactionResult {
  final bool satisfied;
  final double satisfiedAtLength;
  final UnsatisfiedError? error;

  LoomSatisfactionResult({
    required this.satisfied,
    required this.satisfiedAtLength,
    required this.error,
  });
}
