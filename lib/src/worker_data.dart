import 'dart:isolate';

/// Signature for the callback passed to [IsoWorker.init].
typedef IsoFunction = void Function(Stream<WorkerData>);

/// Message class for send to the Worker.
class WorkerData {
  final int id;
  final dynamic value;
  bool done = false;
  late void Function(dynamic data) callback;

  WorkerData(this.id, this.value);

  static WorkerData gen(dynamic value) {
    return WorkerData(DateTime.now().microsecondsSinceEpoch, value);
  }
}
