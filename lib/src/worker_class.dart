import 'dart:async';

/// Abstract class for user-defined worker logic.
/// T: The result type, U: The input data type.
class WorkerClass<T, U> {
  /// Override this method to implement the worker's task.
  Future<T?> execute(U data) async {
    return null;
  }
}
