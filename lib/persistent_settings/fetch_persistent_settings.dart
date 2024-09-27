import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidekick/persistent_settings/persistent_settings_model.dart';

const String kPersistentSettingsStorageKey = 'persistent-settings';

Future<PersistentSettingsModel> fetchPersistentSettings() async {
  final instance = await SharedPreferences.getInstance();

  final contents = instance.getString(kPersistentSettingsStorageKey);

  if (contents == null || contents.isEmpty) {
    return PersistentSettingsModel(fileVersion: kPersistentSettingsFileVersion);
  }

  return PersistentSettingsModel.fromJson(contents)
      .copyWith(fileVersion: kPersistentSettingsFileVersion);
}
