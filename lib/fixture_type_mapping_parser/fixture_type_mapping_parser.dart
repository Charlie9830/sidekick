import 'dart:io';

import 'package:collection/collection.dart';
import 'package:xml/xml.dart';


class FixtureTypeMappingParser {
  Future<List<FixtureMatchModel>> parseMappingFile(File sourceFile) async {
    final document = XmlDocument.parse(await sourceFile.readAsString());
    final root = document.rootElement;

    return root.childElements
        .map((element) => FixtureMatchModel.fromXMlElement(element))
        .toList();
  }
}

class DictionaryAttributeNames {
  static const String fixtureName = "name";
  static const String modeName = "name";
  static const String matchPattern = "pattern";
}

class DictionaryTagNames {
  static const String fixtureMap = "FixtureMap";
  static const String fixture = "Fixture";
  static const String ma2 = "MA2";
  static const String mvr = "MVR";
  static const String match = "Match";
  static const String mode = "Mode";
  static const String ignore = "Ignore";
}

class FixtureMatchModel {
  final String name;
  final MatchPatternModel fixturePattern;
  final List<ModeMatchModel> modePatterns;

  FixtureMatchModel({
    required this.name,
    required this.fixturePattern,
    required this.modePatterns,
  });

  factory FixtureMatchModel.fromXMlElement(XmlElement fixtureElement) {
    final String name = fixtureElement.getAttribute('name') ?? "";
    return FixtureMatchModel(
      name: name,
      fixturePattern: MatchPatternModel.fromElements(
          elements: fixtureElement.childElements, fallbackPattern: name),
      modePatterns: _extractModePatterns(fixtureElement),
    );
  }

  static List<ModeMatchModel> _extractModePatterns(XmlElement fixtureElement) {
    final modeElements = fixtureElement.childElements
        .where((element) => element.localName == DictionaryTagNames.mode);

    if (modeElements.isEmpty) {
      return [
        const ModeMatchModel.noMode(),
      ];
    }

    return modeElements.map((modeElement) {
      final name = modeElement.getAttribute('name') ?? "";
      return ModeMatchModel(
          name: name,
          patterns: MatchPatternModel.fromElements(
              elements: modeElement.childElements, fallbackPattern: name));
    }).toList();
  }

  @override
  String toString() =>
      '=====\n$name\nFixture Patterns: \n$fixturePattern, \n\n Mode Patterns:\n$modePatterns)\n=====\n';
}

enum MappingFlavour {
  ma2,
  mvr,
}

/// Represents the enumeration of <Match/> tags from the Fixture Dictionary. Stores the value of each pattern attribute
/// grouped by console type.
class MatchPatternModel {
  final PatternCollection ma2;
  final PatternCollection mvr;

  MatchPatternModel({
    required this.ma2,
    required this.mvr,
  });

  const MatchPatternModel.wildcard()
      : ma2 = const PatternCollection.wildcard(),
        mvr = const PatternCollection.wildcard();

  factory MatchPatternModel.fromElements(
      {required Iterable<XmlElement> elements,
      required String fallbackPattern}) {
    return MatchPatternModel(
      ma2: _findPatterns(
          tagName: DictionaryTagNames.ma2,
          elements: elements,
          fallbackPattern: fallbackPattern),
      mvr: _findPatterns(
          tagName: DictionaryTagNames.mvr,
          elements: elements,
          fallbackPattern: fallbackPattern),
    );
  }

  /// Find and extract the Pattern string(s) from the element referenced by [tagName].
  /// There can be 1 or multiple child patterns associated with the element.
  /// For example:
  /// <MA2>
  ///   <Match pattern="hello"/>
  ///   <Match pattern="World"/>
  /// </MA2>
  /// Match patterns are optional, in the case where the <Fixture> element name is the same
  /// as the pattern elements. Therefore if no Match Elements are found, the [fallbackPattern]
  /// is used instead.
  static PatternCollection _findPatterns(
      {required String tagName,
      required Iterable<XmlElement> elements,
      required String fallbackPattern}) {
    // First find the console element, usually a <MA2> or <MVR> element.
    final consoleElement =
        elements.firstWhereOrNull((element) => element.name.local == tagName);

    if (consoleElement == null) {
      // Console Element may be ommited if the Pattern matches the Fixture name, therefore return the [fallbackPattern]
      // if it is not empty.
      return PatternCollection(positive: [
        if (fallbackPattern.isNotEmpty) fallbackPattern,
      ], negative: []);
    }

    // Once we have found the console element, iterate through its children to extract the patterns from the <Match> elements.
    final positivePatterns = consoleElement.childElements
        .where((element) => element.localName == DictionaryTagNames.match)
        .map((element) =>
            element.getAttribute(DictionaryAttributeNames.matchPattern) ?? '')
        .toList();

    if (positivePatterns.isEmpty) {
      // Append the [fallbackPattern].
      positivePatterns.add(fallbackPattern);
    }

    final negativePatterns = consoleElement.childElements
        .where((element) => element.localName == DictionaryTagNames.ignore)
        .map((element) =>
            element.getAttribute(DictionaryAttributeNames.matchPattern) ?? '')
        .toList();

    return PatternCollection(
        positive: positivePatterns, negative: negativePatterns);
  }

  PatternCollection getPredicates(MappingFlavour console) {
    switch (console) {
      case MappingFlavour.ma2:
        return ma2;
      case MappingFlavour.mvr:
        return mvr;
    }
  }

  @override
  String toString() => '<MA2> $ma2\n<MVR>: $mvr';
}

class ModeMatchModel {
  final String name;
  final MatchPatternModel patterns;

  ModeMatchModel({
    required this.name,
    required this.patterns,
  });

  // Represents when a fixture has no Mode, eg a VL3500.
  const ModeMatchModel.noMode()
      : name = "n/a",
        patterns = const MatchPatternModel.wildcard();

  @override
  String toString() {
    return 'ModeMatchModel name=$name\nPatterns:\n$patterns';
  }
}

/// Represents the collection of <Match/> and <Ignore/> element patterns.
class PatternCollection {
  final List<String> positive;
  final List<String> negative;

  PatternCollection({
    required this.positive,
    required this.negative,
  });

  const PatternCollection.wildcard()
      : positive = const ["."],
        negative = const [];

  @override
  String toString() {
    return 'positive: $positive\nnegative: $negative';
  }
}
