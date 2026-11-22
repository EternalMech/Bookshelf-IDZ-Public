import 'package:shared_preferences/shared_preferences.dart';

abstract interface class DemoSessionStore {
  Future<bool> load();
  Future<void> save(bool signedIn);
}

class PreferencesDemoSessionStore implements DemoSessionStore {
  final _preferences = SharedPreferencesAsync();
  static const storageKey = 'between_lines.demo_session.v1';

  @override
  Future<bool> load() async => await _preferences.getBool(storageKey) ?? false;

  @override
  Future<void> save(bool signedIn) =>
      _preferences.setBool(storageKey, signedIn);
}
