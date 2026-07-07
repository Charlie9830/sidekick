import 'package:sidekick/redux/models/fixture_model.dart';
import 'package:sidekick/redux/models/fixture_type_pool_model.dart';

class ReorderFixtureTypePools {
  final int oldIndex;
  final int newIndex;

  ReorderFixtureTypePools({required this.oldIndex, required this.newIndex});
}

class DeleteFixtureTypePool {
  final String poolId;

  DeleteFixtureTypePool(this.poolId);
}

class RemoveFixtureTypePoolEntry {
  final String poolId;
  final String typeId;

  RemoveFixtureTypePoolEntry({required this.poolId, required this.typeId});
}

class UpdateFixtureTypePoolEntryQty {
  final String poolId;
  final String typeId;
  final String newValue;

  UpdateFixtureTypePoolEntryQty({
    required this.poolId,
    required this.typeId,
    required this.newValue,
  });
}

class AddFixtureTypesToPool {
  final String poolId;
  final List<String> typeIds;

  AddFixtureTypesToPool({required this.poolId, required this.typeIds});
}

class UpdateFixtureTypePoolName {
  final String poolId;
  final String newValue;

  UpdateFixtureTypePoolName(this.poolId, this.newValue);
}

class SetFixtureTypePools {
  final Map<String, FixtureTypePoolModel> value;

  SetFixtureTypePools(this.value);
}

class SetSelectedFixtureTypeIds {
  final Set<String> value;

  SetSelectedFixtureTypeIds(this.value);
}

class SetFixtureTypesTabIndex {
  final int value;

  SetFixtureTypesTabIndex(this.value);
}

class SetShowAllFixtureTypes {
  final bool value;

  SetShowAllFixtureTypes(this.value);
}

class UpdateFixtureTypeMaxPiggybacks {
  final String id;
  final String newValue;

  UpdateFixtureTypeMaxPiggybacks(this.id, this.newValue);
}

class UpdateFixtureTypeShortName {
  final String id;
  final String newValue;

  UpdateFixtureTypeShortName(this.id, this.newValue);
}

class SetSelectedFixtureIds {
  final Set<String> ids;

  SetSelectedFixtureIds(this.ids);
}

class SetFixtures {
  final Map<String, FixtureModel> fixtures;
  SetFixtures(this.fixtures);
}
