import 'dart:async';

/// Represents a request sent to a worker, containing the data and a completer for the result.
/// T: The type of the input data.
/// U: The type of the result.
class WorkerRequest<T, U> {
  // Static counter to generate unique IDs for each request.
  static int _count = 0;
  // The data associated with this request.
  final WorkerData<T> data;
  // Completer to complete when the result is ready.
  final completer = Completer<U>();

  /// Constructs a WorkerRequest with the given WorkerData.
  WorkerRequest(this.data);

  /// Factory method to generate a new WorkerRequest with a unique ID.
  static WorkerRequest<T, U> gen<T, U>(T value) {
    return WorkerRequest(WorkerData<T>(++_count, value));
  }

  @override
  String toString() => 'WorkerRequest(workerData: $data)';
}

/// Represents the data sent to or from a worker.
/// Contains an ID, the value, and optionally error and stack trace information.
/// T: The type of the value.
class WorkerData<T> {
  // Unique identifier for this data.
  final int id;
  // The value being sent or received.
  final T value;
  // Optional error object if an error occurred.
  final Object? error;
  // Optional stack trace if an error occurred.
  final StackTrace? stackTrace;

  /// Constructs a WorkerData instance.
  WorkerData(this.id, this.value, [this.error, this.stackTrace]);

  @override
  String toString() => 'WorkerData(id: $id, value: $value, error: $error)';
}
