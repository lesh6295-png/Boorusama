// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:hive/hive.dart';

// Project imports:
import 'package:boorusama/core/domain/settings/setting_repository.dart';
import 'package:boorusama/core/domain/settings/settings.dart';

class SettingRepositoryHive implements SettingRepository {
  SettingRepositoryHive(
    this._prefs,
    this._defaultSetting,
  );
  final Future<Box> _prefs;
  final Settings _defaultSetting;

  @override
  Future<Settings> load() async {
    final prefs = await _prefs;
    final jsonString = prefs.get('settings');

    if (jsonString == null) {
      return _defaultSetting;
    }

    final json = jsonDecode(jsonString);
    try {
      return Settings.fromJson(json);
    } catch (e) {
      return Settings.defaultSettings;
    }
  }

  @override
  Future<bool> save(Settings setting) async {
    final prefs = await _prefs;
    final json = jsonEncode(setting.toJson());

    //TODO: should make general name instead
    await prefs.put('settings', json);

    return true;
  }
}
