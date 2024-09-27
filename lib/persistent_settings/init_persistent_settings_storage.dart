import 'package:shared_preferences/shared_preferences.dart';

Future<bool> initPersistentSettingsStorage() async {
  await SharedPreferences.getInstance();

  return true;
}
