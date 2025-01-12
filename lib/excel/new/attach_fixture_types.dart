import 'package:collection/collection.dart';
import 'package:sidekick/excel/new/raw_row_data.dart';
import 'package:sidekick/excel/patch_data_item_error.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';

List<RawRowData> attachFixtureTypes(
    List<RawRowData> rawRows, Map<String, FixtureTypeModel> fixtureTypes) {
  final fixtureTypesByShortName =
      fixtureTypes.values.groupListsBy((element) => element.shortName);

  return rawRows.map((row) {
    if (fixtureTypesByShortName.containsKey(row.fixtureType)) {
      return row.copyWith(
          attachedFixtureTypeId:
              fixtureTypesByShortName[row.fixtureType]!.first.uid);
    } else {
      return row.copyWithError(NoMatchingFixtureTypeError(row.fixtureType));
    }
  }).toList();
}
