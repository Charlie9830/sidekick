import 'package:collection/collection.dart';
import 'package:sidekick/excel/new/raw_row_data.dart';
import 'package:sidekick/excel/patch_data_item_error.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';

List<RawRowData> attachFixtureTypes(
    List<RawRowData> rawRows, Map<String, FixtureTypeModel> fixtureTypes) {
  final fixtureTypesByOriginalShortName =
      fixtureTypes.values.groupListsBy((element) => element.originalShortName);

  return rawRows.map((row) {
    if (fixtureTypesByOriginalShortName.containsKey(row.fixtureType)) {
      return row.copyWith(
          attachedFixtureTypeId:
              fixtureTypesByOriginalShortName[row.fixtureType]!.first.uid);
    } else {
      return row.copyWithError(NoMatchingFixtureTypeError(row.fixtureType));
    }
  }).toList();
}
