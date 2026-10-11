import 'dart:async';
import 'dart:isolate';

import 'worker_class.dart';
import 'worker_data.dart';
import 'worker_entry.dart';
import 'worker_request_manager.dart';

/// A wrapper around Dart's `Isolate` class for easier parallel processing.
class IsoWorker {
  // Receives worker responses, startup messages, and lifecycle notifications.
  final _receivePort = ReceivePort();
  Isolate? _isolate;
  SendPort? _sendPort;
  late final StreamSubscription _subscription;
  bool _disposed = false;
  bool _disposing = false;
  Object? _terminationError;
  Future<void>? _disposeFuture;

  // Manages requests and their completion.
  final _dataManager = WorkerRequestManager();

  /// Returns true if there are any pending tasks.
  bool get inProgress => _dataManager.inProgress;

  IsoWorker._();

  /// Creates an isolate worker and waits for its communication port.
  static Future<IsoWorker> create(WorkerClass workerObj) async {
    final instance = IsoWorker._();
    try {
      await instance._create(workerObj);
      return instance;
    } catch (_) {
      await instance._subscription.cancel();
      instance._receivePort.close();
      instance._isolate?.kill(priority: Isolate.immediate);
      rethrow;
    }
  }

  /// Starts the isolate with lifecycle listeners installed before it runs.
  Future<void> _create(WorkerClass workerObj) async {
    final ready = Completer<SendPort>();

    _subscription = _receivePort.listen((dynamic message) {
      if (message is SendPort) {
        if (!ready.isCompleted) ready.complete(message);
      } else if (message is WorkerData) {
        if (_terminationError == null) {
          _dataManager.remove(message);
        }
      } else if (message is List && message.length == 2) {
        // Uncaught isolate errors arrive as [description, stack trace].
        final error = RemoteError(
          message[0].toString(),
          message[1]?.toString() ?? '',
        );
        _handleWorkerTermination(error, error.stackTrace);
        if (!ready.isCompleted) {
          ready.completeError(error, error.stackTrace);
        }
      } else if (message == null) {
        // The exit message is null and is not a normal worker response.
        final error = StateError('Worker isolate exited unexpectedly.');
        _handleWorkerTermination(error);
        if (!ready.isCompleted) ready.completeError(error);
      }
    });

    _isolate = await Isolate.spawn(
      workerEntryPoint,
      WorkerConfig(_receivePort.sendPort, workerObj.execute),
      paused: true,
      onError: _receivePort.sendPort,
      onExit: _receivePort.sendPort,
      errorsAreFatal: true,
    );
    _isolate!.resume(_isolate!.pauseCapability!);
    _sendPort = await ready.future;
  }

  void _handleWorkerTermination(Object error, [StackTrace? stackTrace]) {
    if (_disposed || _terminationError != null) return;
    _terminationError = error;
    _dataManager.clear(error, stackTrace);
  }

  /// Disposes the worker after outstanding requests have completed.
  Future<void> dispose() => _disposeFuture ??= _dispose();

  Future<void> _dispose() async {
    _disposing = true;
    try {
      await _dataManager.dispose();
    } finally {
      // Stop observing lifecycle events before intentionally killing the isolate.
      await _subscription.cancel();
      _receivePort.close();
      _isolate?.kill(priority: Isolate.immediate);
      _disposed = true;
    }
  }

  /// Executes a task on the worker.
  ///
  /// Throws if the worker is closing, disposed, or has terminated.
  Future<U> exec<T, U>(T data) async {
    if (_disposed || _disposing) {
      throw StateError('IsoWorker has already been disposed.');
    }
    if (_terminationError != null) {
      throw StateError('Worker isolate is no longer running: $_terminationError');
    }
    final req = _dataManager.create<T, U>(data);
    _sendPort!.send(req.data);
    return req.completer.future;
  }
}
