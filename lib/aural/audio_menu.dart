import 'package:commando24/aural/audio_system.dart';
import 'package:commando24/aural/volume_component.dart';
import 'package:commando24/core/atlas.dart';
import 'package:commando24/core/common.dart';
import 'package:commando24/core/screens.dart';
import 'package:commando24/input/keys.dart';
import 'package:commando24/ui/basic_menu.dart';
import 'package:commando24/ui/fonts.dart';
import 'package:commando24/util/extensions.dart';
import 'package:commando24/util/game_script.dart';
import 'package:commando24/util/log.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

enum AudioMenuEntry {
  music_and_sound,
  music_only,
  sound_only,
  silent_mode,
  master_volume,
  music_volume,
  sound_volume,
  back,
}

class AudioMenu extends GameScriptComponent {
  final _keys = Keys();

  late final BasicMenu<AudioMenuEntry> menu;

  static AudioMenuEntry? _preselected;

  @override
  onLoad() {
    add(_keys);

    font_select(tiny_font, scale: 2);
    textXY('Audio Mode', game_center.x, 20, scale: 2, anchor: Anchor.topCenter);

    menu = added(BasicMenu<AudioMenuEntry>(
      keys: _keys,
      font: mini_font,
      onSelected: _selected,
      spacing: 10,
    )
      ..addEntry(AudioMenuEntry.music_and_sound, 'Music & Sound')
      ..addEntry(AudioMenuEntry.music_only, 'Music Only')
      ..addEntry(AudioMenuEntry.sound_only, 'Sound Only')
      ..addEntry(AudioMenuEntry.silent_mode, 'Silent Mode'));

    menu.position.setValues(game_center.x, 64);
    menu.anchor = Anchor.topCenter;

    menu.onPreselected = (it) => _preselected = it;

    _add_volume_controls(menu);

    add(menu.addEntry(AudioMenuEntry.back, 'Back', size: Vector2(80, 24))
      ..auto_position = false
      ..position.setValues(8, game_size.y - 8)
      ..anchor = Anchor.bottomLeft);

    menu.preselectEntry(_preselected ?? AudioMenuEntry.master_volume);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_keys.check_and_consume(GameKey.soft1)) pop_screen();
  }

  void _add_volume_controls(BasicMenu<AudioMenuEntry> menu) {
    void change_master(double volume) => audio.master = volume;
    double read_master() => audio.master;
    void change_music(double volume) => audio.music = volume;
    double read_music() => audio.music;
    void change_sound(double volume) => audio.sound = volume;
    double read_sound() => audio.sound;

    final positions = [
      Vector2(game_center.x, game_center.y),
      Vector2(game_center.x, game_center.y + 64),
      Vector2(game_center.x, game_center.y + 128),
    ];

    add(_master = _volume_control('Master Volume - / +', '-', '+',
        position: positions[0], anchor: Anchor.center, change: change_master, volume: read_master));
    add(_music = _volume_control('Music Volume [ / ]', '[', ']',
        position: positions[1], anchor: Anchor.center, change: change_music, volume: read_music));
    add(_sound = _volume_control('Sound Volume { / }', '{', '}',
        position: positions[2], anchor: Anchor.center, change: change_sound, volume: read_sound));

    menu.addCustom(AudioMenuEntry.master_volume, _master);
    menu.addCustom(AudioMenuEntry.music_volume, _music);
    menu.addCustom(AudioMenuEntry.sound_volume, _sound);
  }

  late final VolumeComponent _master;
  late final VolumeComponent _music;
  late final VolumeComponent _sound;

  void _selected(AudioMenuEntry it) {
    log_verbose('audio menu selected: $it');
    switch (it) {
      case AudioMenuEntry.music_and_sound:
        audio.audio_mode = AudioMode.music_and_sound;
        _make_sound();
      case AudioMenuEntry.music_only:
        audio.audio_mode = AudioMode.music_only;
      case AudioMenuEntry.sound_only:
        audio.audio_mode = AudioMode.sound_only;
        _make_sound();
      case AudioMenuEntry.silent_mode:
        audio.audio_mode = AudioMode.silent;
      case AudioMenuEntry.back:
        pop_screen();
      case _:
        break;
    }
  }

  int _last_sound_at = 0;

  void _make_sound() {
    final now = DateTime.timestamp().millisecondsSinceEpoch;
    if (_last_sound_at + 100 > now) return;
    _last_sound_at = now;
    final which = Sound.values.random().name;
    audio.play_one_shot_sample('sound/$which.ogg');
  }

  VolumeComponent _volume_control(
    String label,
    String increase_shortcut,
    String decrease_shortcut, {
    required Vector2 position,
    Anchor? anchor,
    Vector2? size,
    required double Function() volume,
    required void Function(double) change,
  }) =>
      VolumeComponent(
        bg_nine_patch: atlas.sprite('button_plain.png'),
        label: label,
        position: position,
        anchor: anchor ?? Anchor.topLeft,
        size: size ?? Vector2(192, 64),
        key_down: decrease_shortcut,
        key_up: increase_shortcut,
        change: change,
        volume: volume,
        keys: _keys,
      );
}
