import 'dart:async';

import 'logging.dart';
import 'worker_data.dart';

/// Manages the lifecycle of worker requests, including creation, tracking,
/// completion, and disposal. Handles the mapping between requests and their
/// asynchronous results, and provides utility methods for cleanup and status checks.
class WorkerRequestManager {
  // Stores all active worker requests.
  final Set<WorkerRequest> _data = {};

  /// Returns true if there are any requests in progress.
  bool get inProgress => _data.isNotEmpty;

  /// Creates a new WorkerRequest for the given data and adds it to the set.
  /// Returns the created WorkerRequest instance.
  WorkerRequest<T, U> create<T, U>(T data) {
    Logging.d(this, 'create: $data');
    final req = WorkerRequest.gen<T, U>(data);
    _data.add(req);
    return req;
  }

  /// Removes a completed WorkerRequest based on the WorkerData's id,
  /// and completes its completer with the result or error.
  void remove<T>(WorkerData<T> data) {
    Logging.d(this, 'remove: $data');
    final wd = _data.firstWhere((e) => e.data.id == data.id);
    _data.remove(wd);
    final completer = wd.completer;
    if (!completer.isCompleted) {
      if (data.error != null) {
        completer.completeError(data.error!);
      } else {
        completer.complete(data.value);
      }
    }
  }

  /// Clears all pending requests, completing their completers with an optional error reason.
  /// If a reason is provided, all pending requests are completed with an error.
  /// Otherwise, they are completed normally.
  void clear(String? reason) {
    Logging.d(this, 'clear: $reason');
    for (var data in _data) {
      final completer = data.completer;
      if (!completer.isCompleted) {
        if (reason == null) {
          completer.complete();
        } else {
          completer.completeError(reason);
        }
      }
    }
    _data.clear();
  }

  /// Waits for all requests to complete or until a timeout is reached.
  /// Checks the set of requests periodically and returns when all are done or the retry limit is hit.
  Future<void> waitForDone() async {
    Logging.d(this, 'waitForDone');
    int retry = 0;
    const maxRetry = 50;
    while (_data.isNotEmpty && retry < maxRetry) {
      await Future.delayed(Duration(milliseconds: 100));
      retry++;
    }
  }

  /// Disposes the manager by waiting for all requests to finish,
  /// then clearing any remaining requests with a dispose timeout error.
  Future<void> dispose() async {
    Logging.d(this, 'dispose');
    await waitForDone();
    clear('Dispose timeout.');
  }
}
