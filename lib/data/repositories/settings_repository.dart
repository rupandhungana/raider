import 'package:flutter/foundation.dart';

import '../../domain/models/app_settings.dart';
import '../services/local_store.dart';

/// The rider's preferences, saved as they change.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository(this._store) : _settings = _load(_store);

  final LocalStore _store;
  AppSettings _settings;

  static const _key = 'settings';

  static AppSettings _load(LocalStore store) => switch (store.read(_key)) {
    final Map<Object?, Object?> json => AppSettings.fromJson(json.cast<String, Object?>()),
    _ => const AppSettings(),
  };

  AppSettings get settings => _settings;

  void update(AppSettings Function(AppSettings current) change) {
    _settings = change(_settings);
    _store.write(_key, _settings.toJson());
    notifyListeners();
  }
}
