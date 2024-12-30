
import 'package:sidekick/diffing/union_proxy.dart';
import 'package:sidekick/redux/models/cable_model.dart';
import 'package:sidekick/redux/models/loom_model.dart';
import 'package:sidekick/redux/state/fixture_state.dart';

class DiffingState {
  final FixtureState original;
  final Set<UnionProxy<CableModel>> cablesUnion;
  final Set<UnionProxy<LoomModel>> loomsUnion;

  DiffingState({
    required this.original,
    required this.cablesUnion,
    required this.loomsUnion,
  });

  DiffingState.initial()
      : original = FixtureState.initial(),
        cablesUnion = const {},
        loomsUnion = const {};

  DiffingState copyWith({
    FixtureState? original,
    Set<UnionProxy<CableModel>>? cablesUnion,
    Set<UnionProxy<LoomModel>>? loomsUnion,
  }) {
    return DiffingState(
      original: original ?? this.original,
      cablesUnion: cablesUnion ?? this.cablesUnion,
      loomsUnion: loomsUnion ?? this.loomsUnion,
    );
  }
}
