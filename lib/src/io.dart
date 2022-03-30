import 'dart:async';
import 'dart:isolate';

import 'common.dart';

/// A wrapping of the `Isolate` class to make it easier to write parallel processes.
class IsoWorker {
  final _receivePort = ReceivePort();
  final _errorPort = ReceivePort();
  late final Isolate _isolate;
  late final SendPort _sendPort;
  late final StreamSubscription _subscription;
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
    _isolate = await Isolate.spawn(
        _entryPoint, _WorkerConfig(_receivePort.sendPort, func),
        onError: _errorPort.sendPort, errorsAreFatal: false);
    final port = _receivePort.asBroadcastStream();
    _sendPort = await port.first as SendPort;
    _subscription = port.cast<WorkerData>().listen((data) {
      _completers[data.id]?.complete(data.value);
      _completers.remove(data.id);
    });
    _errorPort.listen((errorData) {
      final exception = errorData[0];
      final stack = StackTrace.fromString(errorData[1]);
      _completers.forEach((i, v) => v.completeError(exception, stack));
      _completers.clear();
    });
  }

  /// Destroying object.
  Future<void> dispose() async {
    if (_disposed) return;
    _completers.forEach((i, v) => v.completeError('Already disposed.'));
    _completers.clear();
    await _subscription.cancel();
    _receivePort.close();
    _errorPort.close();
    _isolate.kill();
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
    _sendPort.send(wd);
    return completer.future;
  }

  static void _entryPoint(_WorkerConfig config) {
    final receivePort = ReceivePort();
    config.port.send(receivePort.sendPort);

    final stream = receivePort.cast<WorkerData>().transform<WorkerData>(
        StreamTransformer.fromHandlers(handleData: (value, sink) {
      value.callback = (data) {
        final done = value.done;
        assert(!done, 'Do not call the callback twice.');
        if (!done) {
          value.done = true;
          config.port.send(WorkerData(value.id, data));
        }
      };
      sink.add(value);
      // assert(() {
      //   Future.delayed(Duration(seconds: 10)).then((_) {
      //     final done = value._done;
      //     assert(done, 'Callback need to be called.');
      //   });
      //   return true;
      // }());
    }));
    config.func(stream);
  }
}

class _WorkerConfig {
  final SendPort port;
  final IsoFunction func;

  const _WorkerConfig(
    this.port,
    this.func,
  );
}
