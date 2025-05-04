import 'package:sidekick/persistent_settings/fetch_persistent_settings.dart';
import 'package:sidekick/persistent_settings/persistent_settings_model.dart';
import 'package:sidekick/persistent_settings/save_persistent_settings.dart';

Future<void> updatePersistentSettings(
    PersistentSettingsModel Function(PersistentSettingsModel existing)
        update) async {
  final existingSettings = await fetchPersistentSettings();

  final updatedSettings = update(existingSettings);

  await savePersistentSettings(
      updatedSettings.copyWith(fileVersion: kPersistentSettingsFileVersion));
}
