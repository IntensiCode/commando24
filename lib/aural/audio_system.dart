import 'dart:async';

import 'package:commando24/aural/audio_soloud.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/game_data.dart';
import 'package:commando24/core/storage.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/log.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flutter/foundation.dart';

enum Sound {
  burst_machine_gun,
  collect,
  empty_click,
  explosion_1,
  explosion_2,
  explosion_hollow,
  flamethrower(limit: 1),
  hit_crack,
  hit_metal,
  prisoner_death,
  prisoner_freed,
  prisoner_ouch,
  prisoner_oh_oh,
  shot_assault_rifle,
  shot_assault_rifle_real,
  shot_bazooka,
  shot_machine_gun,
  shot_machine_gun_real,
  shot_nine_mm,
  shot_shotgun,
  shot_shotgun_real,
  shot_smg,
  shot_smg_real,
  ;

  final int? limit;

  const Sound({this.limit});
}

final audio = PlatformAudioSystem();

AudioSystem get soundboard => audio; // legacy

enum AudioMode {
  music_and_sound('Music & Sound'),
  music_only('Music Only'),
  silent('Silent'),
  sound_only('Sound Only'),
  ;

  final String label;

  const AudioMode(this.label);

  static AudioMode from_name(String name) => AudioMode.values.firstWhere((it) => it.name == name);
}

abstract class AudioSystem extends Component {
  Future _save() async => await save_data('audio', save_state());

  AudioMode get guess_audio_mode {
    if (muted) return AudioMode.silent;
    if (_music > 0 && _sound > 0) return AudioMode.music_and_sound;
    if (_music > 0) return AudioMode.music_only;
    if (_sound > 0) return AudioMode.sound_only;
    return AudioMode.silent;
  }

  set audio_mode(AudioMode mode) {
    log_info('Change audio mode: $mode');
    _update_volumes(mode);
    _save();
    do_update_volume();
  }

  void _update_volumes(AudioMode mode) {
    switch (mode) {
      case AudioMode.music_and_sound:
        _music = 0.4;
        _sound = 0.6;
        _muted = false;
      case AudioMode.music_only:
        _music = 0.6;
        _sound = 0.0;
        _muted = false;
      case AudioMode.silent:
        _music = 0.0;
        _sound = 0.0;
        _muted = true;
      case AudioMode.sound_only:
        _music = 0.0;
        _sound = 0.6;
        _muted = false;
    }
  }

  double _master = 0.5;

  double get master => _master;

  set master(double value) {
    if (_master == value) return;
    _master = value;
    _save();
    do_update_volume();
  }

  double _music = 0.4;

  double get music => _music;

  set music(double value) {
    if (_music == value) return;
    _music = value;
    _save();
    do_update_volume();
  }

  double _sound = 0.6;

  double get sound => _sound;

  set sound(double value) {
    if (_sound == value) return;
    _sound = value;
    _save();
  }

  bool _muted = false;

  bool get muted => _muted;

  set muted(bool value) {
    if (_muted == value) return;
    _muted = value;
    _save();
  }

  // flag used during initialization
  Future? _preloading;

  // used by [trigger] to play every sound only once per tick
  final _triggered = <Sound>{};

  String? active_music_name;
  (String, bool, Hook?)? pending_music;
  double? fade_out_volume;

  void update_paused(bool paused) {}

  @protected
  double? get active_music_volume;

  set active_music_volume(double? it);

  @protected
  void do_update_volume();

  @protected
  Future do_preload();

  @protected
  Future do_play(Sound sound, double volume_factor);

  @protected
  Future do_preload_one_shot_sample(String filename);

  @protected
  Future<Disposable> do_play_one_shot_sample(
    String filename, {
    required double volume_factor,
    required bool cache,
    required bool loop,
  });

  @protected
  Future do_play_music(String filename, {bool loop = true, Hook? on_end});

  @protected
  void do_stop_active_music();

  void toggleMute() => muted = !muted;

  Future preload() async {
    if (_preloading != null) {
      log_debug('Preloading already in progress');
      return _preloading!;
    }
    _preloading = do_preload();
    await _preloading;
    _preloading = null;
  }

  void trigger(Sound sound) => _triggered.add(sound);

  Future play(Sound sound, {double volume_factor = 1}) async {
    if (_muted) return;
    if (_preloading != null) return;
    await do_play(sound, volume_factor);
  }

  Future<void> preload_one_shot(String filename) async => await do_preload_one_shot_sample(filename);

  Future<Disposable> play_one_shot_sample(
    String filename, {
    double volume_factor = 1,
    bool cache = true,
    bool loop = false,
  }) async {
    if (_muted) return Disposable.disposed;
    return await do_play_one_shot_sample(filename, volume_factor: volume_factor, cache: cache, loop: loop);
  }

  Future play_music(String filename, {bool loop = true, Hook? on_end}) async {
    if (fade_out_volume != null) {
      log_info('Schedule music $filename');
      pending_music = (filename, loop, on_end);
    } else if (active_music_name == filename) {
      log_info('Music already playing: $filename');
    } else {
      log_info('Play music $filename loop=$loop');
      do_stop_active_music();
      active_music_name = filename;
      await do_play_music(filename, loop: loop, on_end: on_end);
    }
  }

  void stop_active_music() {
    log_info('Stop active music $active_music_name');
    fade_out_volume = null;
    active_music_name = null;
    do_stop_active_music();
  }

  void fade_out_music() {
    log_info('Fade out music $active_music_volume');
    fade_out_volume = active_music_volume;
  }

  // Component

  @override
  Future onLoad() async {
    super.onLoad();
    final data = await load_data('audio');
    if (data != null) load_state(data);
  }

  @override
  void onMount() {
    super.onMount();
    if (dev && !kIsWeb && !kIsWasm) preload();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _fade_music(dt);

    if (_triggered.isEmpty) return;
    for (final it in _triggered) {
      play(it);
    }
    _triggered.clear();
  }

  void _fade_music(double dt) {
    double? fov = fade_out_volume;
    if (fov == null) return;

    fov -= dt;
    if (fov <= 0) {
      stop_active_music();
      fade_out_volume = null;
      final pending = pending_music;
      if (pending != null) {
        pending_music = null;
        play_music(pending.$1, loop: pending.$2, on_end: pending.$3);
      }
    } else {
      active_music_volume = fov;
      fade_out_volume = fov;
    }
  }

  void load_state(Map<String, dynamic> data) {
    log_debug('Loading audio: $data');
    _master = data['master'] ?? _master;
    _music = data['music'] ?? _music;
    _muted = data['muted'] ?? _muted;
    _sound = data['sound'] ?? _sound;
  }

  GameData save_state() => {}
    ..['master'] = _master
    ..['music'] = _music
    ..['muted'] = _muted
    ..['sound'] = _sound;
}
