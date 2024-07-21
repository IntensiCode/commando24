final configuration = GameConfiguration.instance;

class GameConfiguration {
  static final instance = GameConfiguration._();

  GameConfiguration._();

  int enemy_score = 200;

  double level_time = 60;

  double mode_time = 30;
  double expand_time = 30;
  double slow_down_time = 30;
  double disruptor_time = 10;

  double force_hold_timeout = 1.0;
  double plasma_cool_down = 1.0;
  double plasma_disruptor = 1.0;

  final max_ball_speed = 155.0;
  final opt_ball_speed = 100.0;
  final min_ball_speed = 25.0;
  final min_ball_y_speed = 15.0;
  final min_ball_x_speed_after_brick_hit = 10;

  int extra_life_base = 3000;
  int extra_life_mod = 500;
  int eog_blast_bonus = 111;
  int eog_life_bonus = 222;
}
