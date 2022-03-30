/// Signature for the callback passed to [IsoWorker.init].
typedef IsoFunction = void Function(Stream<WorkerData> message);

/// Message class for send to the Worker.
class WorkerData {
  static int _count = 0;
  final int id;
  final dynamic value;
  late Function callback;
  bool done = false;

  /// Create an object by specifying its [id] and [value]
  WorkerData(this.id, this.value);

  /// Create an object by automatically generating its [id]
  factory WorkerData.gen(dynamic value) {
    return WorkerData(_count++, value);
  }
}
