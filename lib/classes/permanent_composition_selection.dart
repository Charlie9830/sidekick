// ignore_for_file: public_member_api_docs, sort_constructors_first

class PermanentCompositionSelection {
  final String name;
  final bool cutSpares;

  PermanentCompositionSelection({
    required this.name,
    required this.cutSpares,
  });

  PermanentCompositionSelection.asValueSentinel(this.name) : cutSpares = false;

  @override
  int get hashCode => name.hashCode ^ cutSpares.hashCode;

  @override
  bool operator ==(Object other) {
    return other is PermanentCompositionSelection &&
        other.name == name &&
        other.cutSpares == cutSpares;
  }
}
