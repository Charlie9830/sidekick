class CompiledModePredicate {
  final String name;
  final List<RegExp> positiveExps;
  final List<RegExp> negativeExps;

  CompiledModePredicate({
    required this.name,
    required this.positiveExps,
    required this.negativeExps,
  });

  bool hasModeMatch(String source) {
    return positiveExps.any((regex) => regex.hasMatch(source) == true) &&
        negativeExps.every((regex) => regex.hasMatch(source) == false);
  }
}
