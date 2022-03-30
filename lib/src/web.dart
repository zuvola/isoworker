import 'dart:async';

import 'common.dart';

class IsoWorker {
  final _stream = StreamController<WorkerData>();
  final Map<int, Completer> _completers = {};
  bool _disposed = false;

  IsoWorker._();

  /// Initialization.
  /// Provide a top-level or static method with [Stream<WorkerData>] as an argument.
  static Future<IsoWorker> init(IsoFunction func) async {
    final instance = IsoWorker._();
    await instance._init(func);
    return instance;
  }

  Future<void> _init<T>(IsoFunction func) async {
    runZonedGuarded(() {
      func(_stream.stream);
    }, ((e, s) {
      _completers.forEach((i, v) => v.completeError(e, s));
      _completers.clear();
    }));
  }

  /// Destroying object.
  Future<void> dispose() async {
    if (_disposed) return;
    _completers.forEach((i, v) => v.completeError('Already disposed.'));
    _completers.clear();
    _disposed = true;
  }

  /// Execute the task with [data].
  Future<T> exec<T>(dynamic data) async {
    if (_disposed) {
      throw Exception('Already disposed.');
    }
    final completer = Completer<T>();
    final wd = WorkerData.gen(data);
    _completers[wd.id] = completer;
    wd.callback = (data) {
      if (!completer.isCompleted) {
        _completers.remove(wd.id);
        completer.complete(data);
      }
    };
    _stream.add(wd);
    return completer.future;
  }
}
