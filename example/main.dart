import 'package:isoworker/isoworker.dart';

/// Method to be called when `IsoWorker` is initialized.
/// Provide a top-level or static method with `Stream<WorkerData>` as an argument.
void workerMethod(Stream<WorkerData> message) {
  final _map = {
    'key_1': 'val_1',
    'key_2': 'val_2',
  };
  // Receive messages (WorkerData) to a worker
  message.listen((data) {
    // `WorkerData.value` to receive data from the `exec` runtime.
    final command = data.value['command'];
    switch (command) {
      case 'get':
        // Execute heavy processing, etc. and return the result as `WorkerData.callback`.
        data.callback(_map[data.value['key']]);
        break;
      default:
        // Be sure to call `callback` even if there is nothing there.
        data.callback(null);
    }
  });
}

void main() async {
  // Initialization
  final worker = await IsoWorker.init(workerMethod);
  // Execute the task
  final res = await worker.exec({
    'command': 'get',
    'key': 'key_1',
  });
  print(res);
  // Destroy the Worker
  await worker.dispose();
  await Future.delayed(Duration(milliseconds: 100));
}
