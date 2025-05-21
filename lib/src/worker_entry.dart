import 'dart:isolate';
import 'worker_data.dart';

/// Configuration object passed to the isolate entry point.
/// Contains the SendPort for communication and the function to execute.
class WorkerConfig {
  final SendPort port;
  final Future<Object?> Function(Object data) func;

  const WorkerConfig(this.port, this.func);
}

/// Entry point function for the spawned isolate.
/// Sets up communication and listens for incoming WorkerData tasks.
void workerEntryPoint(WorkerConfig config) {
  final receivePort = ReceivePort();
  config.port.send(receivePort.sendPort);

  // Listen for incoming WorkerData tasks and execute the provided function.
  final stream = receivePort.cast<WorkerData>();
  stream.listen((data) async {
    try {
      final ret = await config.func(data.value); // Execute the worker function.
      config.port.send(WorkerData(data.id, ret, null, null));
    } catch (e, s) {
      config.port.send(WorkerData(data.id, null, e, s));
    }
  });
}
