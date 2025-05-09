import 'dart:io';

/// Create a *synchronous*(!) file sink.
file_sink(String filename, {bool truncate = false}) {
  final file = File(filename);
  if (truncate && file.existsSync()) file.deleteSync();
  var parent = Directory(filename).parent;
  if (!parent.existsSync()) parent.createSync();
  final sink = file.openWrite();
  return (e) => sink.writeln(e);
}

/// Define where log messages should go. This can be anything that is a
/// `void Function(Object?)`. If, for example, you need async logging, you could
/// dispatch via a custom sink into some [StreamController] of yours and go
/// from there. Or if you need custom log levels per context, a custom sink can
/// handle this.
var log_sink = print;

var log_level = LogLevel.info;

enum LogLevel { verbose, debug, info, warn, error, none }

extension on LogLevel {
  /// Single uppercase letter representing the log level.
  tag() => name.substring(0, 1).toUpperCase();
}

/// Generic log call. Will use [LogLevel.Info] if [level] is null. Will print
/// the [trace] *after* the message if non-null. If the [message] is `null`,
/// then `null` will be printed. If [message] is a `Function`, it will be
/// evaluate here without arguments. On failure, [log_error] will be called.
log(Object? message, [LogLevel? level, StackTrace? trace]) {
  level ??= LogLevel.info;
  if (level.index < log_level.index) return;

  var (name, where) = StackTrace.current.caller;
  if (message is Function) {
    try {
      message = message();
    } catch (it, trace) {
      log_error(it, trace);
      return;
    }
  }

  log_sink("[${level.tag()}] $message [$name] $where");

  if (trace != null) log_sink(trace.toString());
}

log_error(Object? message, [StackTrace? trace]) => log(message, LogLevel.error, trace);

log_warn(Object? message) => log(message, LogLevel.warn);

log_info(Object? message) => log(message, LogLevel.info);

log_debug(Object? message) => log(message, LogLevel.debug);

log_verbose(Object? message) => log(message, LogLevel.verbose);

extension StackTraceCallerExtension on StackTrace {
  (String function, String location) get caller {
    caller(String it) => !it.contains("log.dart");
    var lines = toString().split("\n");
    var trace = lines.firstWhere(caller, orElse: () => "");
    var parts = trace.replaceAll(RegExp(r"#\d\s+"), "").split(" ");
    return (parts[0], parts[1]);
  }
}
