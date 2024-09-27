import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';

class BalancerFixtureModel {
  final String uid;
  final int fid;
  final int sequence;
  final FixtureTypeModel type;
  final String locationId;

  BalancerFixtureModel({
    this.fid = 0,
    this.uid = '',
    this.sequence = 0,
    this.type = const FixtureTypeModel.blank(),
    this.locationId = '',
  });

  BalancerFixtureModel.fromFixture(
      {required FixtureModel fixture, required this.type})
      : uid = fixture.uid,
        fid = fixture.fid,
        sequence = fixture.sequence,
        locationId = fixture.locationId;

  BalancerFixtureModel copyWith({
    String? uid,
    int? fid,
    int? sequence,
    FixtureTypeModel? type,
    String? locationId,
  }) {
    return BalancerFixtureModel(
      uid: uid ?? this.uid,
      fid: fid ?? this.fid,
      sequence: sequence ?? this.sequence,
      type: type ?? this.type,
      locationId: locationId ?? this.locationId,
    );
  }
}
