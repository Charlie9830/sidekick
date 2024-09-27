import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidekick/persistent_settings/fetch_persistent_settings.dart';
import 'package:sidekick/persistent_settings/persistent_settings_model.dart';

Future<void> savePersistentSettings(PersistentSettingsModel settings) async {
  final instance = await SharedPreferences.getInstance();

  await instance.setString(kPersistentSettingsStorageKey,
      settings.copyWith(fileVersion: kPersistentSettingsFileVersion).toJson());
}
