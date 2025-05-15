import 'dart:async';
import 'dart:isolate';
import 'worker_data.dart';
import 'worker_entry.dart';

/// A wrapping of the `Isolate` class to make it easier to write parallel processes.
class IsoWorker {
  final _receivePort = ReceivePort();
  final _errorPort = ReceivePort();
  late final Isolate _isolate;
  late final SendPort _sendPort;
  late final StreamSubscription _subscription;
  final Map<int, Completer> _completers = {};
  bool _disposed = false;

  // Whether it is being processed or not.
  bool get inProgress => _completers.isNotEmpty;

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
      workerEntryPoint,
      WorkerConfig(_receivePort.sendPort, func),
      onError: _errorPort.sendPort,
      errorsAreFatal: false,
    );
    final port = _receivePort.asBroadcastStream();
    _sendPort = await port.first as SendPort;
    _subscription = port.cast<WorkerData>().listen((data) {
      final completer = _completers.remove(data.id);
      if (completer != null) {
        completer.complete(data.value);
      }
    });
    _errorPort.listen((errorData) {
      if (errorData is List && errorData.length >= 2) {
        final exception = errorData[0];
        final stack = StackTrace.fromString(errorData[1].toString());
        _completers.forEach((i, v) => v.completeError(exception, stack));
      } else {
        _completers.forEach(
            (i, v) => v.completeError('Unknown error', StackTrace.current));
      }
      _completers.clear();
    });
  }

  /// Destroying object.
  Future<void> dispose() async {
    if (_disposed) return;
    // wait until all is complete
    int retry = 0;
    const maxRetry = 50;
    while (_completers.isNotEmpty && retry < maxRetry) {
      await Future.delayed(Duration(milliseconds: 100));
      retry++;
    }
    if (_completers.isNotEmpty) {
      _completers.forEach((i, v) => v.completeError('Dispose timeout.'));
      _completers.clear();
    }
    await _subscription.cancel();
    _receivePort.close();
    _errorPort.close();
    _isolate.kill(priority: Isolate.immediate);
    _disposed = true;
  }

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
}
