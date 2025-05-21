import 'dart:async';
import 'dart:isolate';

import 'worker_class.dart';
import 'worker_data.dart';
import 'worker_entry.dart';
import 'worker_request_manager.dart';

/// A wrapper around Dart's `Isolate` class for easier parallel processing.
class IsoWorker {
  // The port to receive messages from the isolate.
  final _receivePort = ReceivePort();
  // The spawned isolate instance.
  late final Isolate _isolate;
  // The port to send messages to the isolate.
  late final SendPort _sendPort;
  // Subscription to the receive port's stream.
  late final StreamSubscription _subscription;
  // Whether this worker has been disposed.
  bool _disposed = false;
  // Manages requests and their completion.
  final _dataManager = WorkerRequestManager();

  /// Returns true if there are any pending tasks.
  bool get inProgress => _dataManager.inProgress;

  /// Private constructor.
  IsoWorker._();

  /// Factory method to create and initialize an IsoWorker.
  static Future<IsoWorker> create(WorkerClass workerObj) async {
    final instance = IsoWorker._();
    await instance._create(workerObj);
    return instance;
  }

  /// Internal method to spawn the isolate and set up communication.
  Future<void> _create(WorkerClass workerObj) async {
    _isolate = await Isolate.spawn(
      workerEntryPoint,
      WorkerConfig(_receivePort.sendPort, workerObj.execute),
    );
    final port = _receivePort.asBroadcastStream();
    _sendPort = await port.first as SendPort;
    _subscription = port.cast<WorkerData>().listen((data) {
      _dataManager.remove(data);
    });
  }

  /// Disposes the worker and cleans up resources.
  Future<void> dispose() async {
    if (_disposed) return;
    await _dataManager.dispose();
    try {
      await _subscription.cancel();
    } catch (_) {}
    try {
      _receivePort.close();
    } catch (_) {}
    try {
      _isolate.kill(priority: Isolate.immediate);
    } catch (_) {}
    _disposed = true;
  }

  /// Sends a task to the isolate and returns the result asynchronously.
  /// Throws if the worker has already been disposed.
  Future<U> exec<T, U>(T data) async {
    if (_disposed) {
      throw StateError('IsoWorker has already been disposed.');
    }
    final req = _dataManager.create<T, U>(data);
    _sendPort.send(req.data);
    return req.completer.future;
  }
}
