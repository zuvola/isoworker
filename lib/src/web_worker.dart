import 'dart:async';

import 'worker_data.dart';
import 'worker_request_manager.dart';
import 'worker_class.dart';

/// Signature for the worker function.
/// It receives a stream of WorkerData and should process tasks accordingly.
typedef IsoFunction = void Function(Stream<WorkerData>);

/// A worker implementation for web platforms using Streams instead of Isolates.
class IsoWorker {
  // Stream controller for sending tasks to the worker function.
  final _stream = StreamController<WorkerData>();
  // Manages requests and their completion.
  final WorkerRequestManager _dataManager = WorkerRequestManager();
  // Whether this worker has been disposed.
  bool _disposed = false;

  /// Returns true if there are any tasks in progress.
  bool get inProgress => _dataManager.inProgress;

  IsoWorker._();

  /// Factory method to create and initialize an IsoWorker.
  /// [workerObj] should implement the execute method for processing tasks.
  static Future<IsoWorker> create(WorkerClass workerObj) async {
    final instance = IsoWorker._();
    await instance._create(workerObj);
    return instance;
  }

  /// Internal initialization logic using WorkerClass.
  Future<void> _create(WorkerClass workerObj) async {
    runZonedGuarded(() {
      // Listen to the stream and process WorkerData tasks using workerObj.execute.
      _stream.stream.listen((data) async {
        try {
          final ret = await workerObj.execute(data.value);
          // Send result back to the manager.
          _dataManager.remove(WorkerData(data.id, ret, null, null));
        } catch (e, s) {
          // Send error back to the manager.
          _dataManager.remove(WorkerData(data.id, null, e, s));
        }
      });
    }, (e, s) {
      // Complete all pending tasks with error if an uncaught exception occurs.
      _dataManager.clear(e.toString());
    });
  }

  /// Disposes the worker and completes all pending tasks with an error.
  Future<void> dispose() async {
    if (_disposed) return;
    await _dataManager.dispose();
    await _stream.close();
    _disposed = true;
  }

  /// Sends a task to the worker and returns the result asynchronously.
  /// Throws if the worker has already been disposed.
  Future<U> exec<T, U>(T data) async {
    if (_disposed) {
      throw StateError('IsoWorker has already been disposed.');
    }
    final req = _dataManager.create<T, U>(data);
    _stream.add(req.data);
    return req.completer.future;
  }
}
