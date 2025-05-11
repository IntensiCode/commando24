import 'package:collection/collection.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/game_data.dart';
import 'package:commando24/core/storage.dart';
import 'package:commando24/input/game_keys.dart';
import 'package:commando24/input/game_pads.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/log.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:kart/kart.dart';
import 'package:supercharged/supercharged.dart';

final configuration = Configuration._();

class Configuration with HasGameData {
  Configuration._() {
    on_debug_change = (it) => _save_if(_data['debug'] != it);
  }

  bool _loading = false;

  void _save_if(bool changed) {
    if (_loading) return;
    if (changed) save_to_storage('configuration', this);
  }

  Future<void> load() async {
    await load_from_storage('configuration', this);
    log_verbose(known_hw_mappings.entries.firstWhereOrNull((it) => it.value.deepEquals(hw_mapping))?.key ?? 'CUSTOM');
  }

  void save() => save_to_storage('configuration', this);

  // HasGameData

  var _data = <String, dynamic>{};

  @override
  void load_state(Map<String, dynamic> data) {
    try {
      _loading = true;
      _load_state(data);
    } catch (it, trace) {
      log_error('Failed to load configuration: $it', trace);
    } finally {
      _loading = false;
    }
  }

  void _load_state(Map<String, dynamic> data) {
    _data = data;
    if (dev) log_verbose(data);
    debug = data['debug'] ?? debug;
    prefer_x_over_y = data['prefer_x_over_y'] ?? prefer_x_over_y;
    hw_mapping = (data['hw_mapping'] as Map<String, dynamic>? ?? {}).entries.mapNotNull((e) {
      final k = e?.key.toIntOrNull();
      if (k == null) return null;
      final v = GamePadControl.values.firstWhereOrNull((it) => it.name == e?.value);
      if (v == null) return null;
      return MapEntry(k, v);
    }).toMap();
  }

  @override
  GameData save_state(Map<String, dynamic> data) => data
    ..['debug'] = debug
    ..['prefer_x_over_y'] = prefer_x_over_y
    ..['hw_mapping'] = hw_mapping.map((k, v) => MapEntry(k.toString(), v.name));
}
