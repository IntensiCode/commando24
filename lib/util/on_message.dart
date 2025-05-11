import 'package:commando24/core/common.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/messaging.dart';

extension AutoDisposeComponentExtensions on AutoDispose {
  void on_message<T extends Message>(void Function(T) callback) {
    auto_dispose('listen-$T', messaging.listen<T>(callback));
  }
}
