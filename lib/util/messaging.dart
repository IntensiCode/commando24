import 'package:commando24/core/common.dart';
import 'package:commando24/util/auto_dispose.dart';
import 'package:commando24/util/log.dart';
import 'package:flame/components.dart';

extension ComponentExtension on Component {
  Messaging get messaging {
    Component? probed = this;
    while (probed is! Messaging) {
      probed = probed?.parent;
      if (probed == null) {
        Component? log = this;
        while (log != null) {
          log_warn('no messaging mixin found in $log');
          log = log.parent;
        }
        log_warn('=> no messaging mixin found in $this');
        throw 'no messaging mixin found';
      }
    }
    return probed;
  }

  void sendMessage<T extends Message>(T message) => messaging.send(message);
}

mixin Messaging on Component {
  final listeners = <Type, List<dynamic>>{};

  Disposable listen<T extends Message>(void Function(T) callback) {
    listeners[T] ??= [];
    listeners[T]!.add(callback);
    return Disposable.wrap(() {
      listeners[T]?.remove(callback);
    });
  }

  void send<T extends Message>(T message) {
    final listener = listeners[message.runtimeType];
    if (listener == null || listener.isEmpty) {
      if (debug) log_warn('no listener for ${message.runtimeType} in $listeners');
    } else {
      log_info('sending ${message.runtimeType} to ${listener.length} listeners');
      listener.forEach((it) => it(message));
    }
  }

  @override
  void onRemove() => listeners.clear();
}
