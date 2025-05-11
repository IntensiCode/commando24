import 'dart:convert';

import 'package:commando24/core/common.dart';
import 'package:commando24/core/game_data.dart';
import 'package:commando24/util/log.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _prefs = SharedPreferences.getInstance();

late String storage_prefix;

extension on String {
  String get key => '${storage_prefix}_$this';
}

Future clear_storage_entry(String name) async {
  final preferences = await _prefs;
  preferences.remove(name.key);
  log_verbose('Cleared $name data');
}

Future save_to_storage(String name, HasGameData it) async => save_data(name, it.save_state({}));

Future load_from_storage(String name, HasGameData it) async {
  final data = await load_data(name);
  if (data != null) it.load_state(data);
}

Future save_data(String name, GameData data) async {
  try {
    final preferences = await _prefs;
    final json = jsonEncode(data);
    if (dev) log_verbose(json);
    preferences.setString(name.key, json);
    log_verbose('Saved $name data');
  } catch (it, trace) {
    log_error('Failed to store $data in $name: $it', trace);
  }
}

Future<GameData?> load_data(String name) async {
  try {
    final preferences = await _prefs;
    if (!preferences.containsKey(name.key)) {
      log_verbose('No data for $name');
      return null;
    }

    final json = preferences.getString(name.key);
    if (json == null) {
      log_error('Invalid data for $name');
      return null;
    }

    log_verbose('Loaded $name');
    log_verbose(json);
    return jsonDecode(json);
  } catch (it, trace) {
    log_error('Failed to restore $name: $it', trace);
    return null;
  }
}
