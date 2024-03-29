import 'dart:isolate';

import 'package:isoworker/isoworker.dart';

/// Method to be called when `IsoWorker` is initialized.
/// Provide a top-level or static method with `Stream<WorkerData>` as an argument.
void workerMethod(Stream<WorkerData> message) {
  final sampleMap = {
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
        data.callback(sampleMap[data.value['key']]);
        break;
      case 'wait':
        Future.delayed(Duration(milliseconds: 200)).then((_) {
          data.callback(sampleMap[data.value['key']]);
        });
        // data.callback(null);
        break;
      default:
        // Be sure to call `callback` even if there is nothing there.
        data.callback(null);
    }
  });
}

// For Isolate.run
String? workerMethod2(String key) {
  final sampleMap = {
    'key_1': 'val_1',
    'key_2': 'val_2',
  };
  return sampleMap[key];
}

void main() async {
  // Initialization
  final worker = await IsoWorker.init(workerMethod);
  // Execute tasks
  final exec1 = worker.exec({
    'command': 'wait',
    'key': 'key_1',
  });
  final exec2 = worker.exec({
    'command': 'get',
    'key': 'key_2',
  });
  final res = await Future.wait([exec1, exec2]);
  print(res);

  // Speed comparison with Isoworker.run.
  // Run with SDK 2.19.0 or higher.
  final stopWatch = Stopwatch();
  stopWatch.start();
  for (var i = 0; i < 100; i++) {
    await worker.exec({
      'command': 'get',
      'key': 'key_1',
    });
  }
  stopWatch.stop();
  print('isoworker:${stopWatch.elapsedMilliseconds}ms');
  stopWatch.start();
  for (var i = 0; i < 100; i++) {
    // ignore: sdk_version_since
    await Isolate.run(() => workerMethod2('key_1'));
  }
  stopWatch.stop();
  print('Isolate.run:${stopWatch.elapsedMilliseconds}ms');

  // Destroy the Worker
  await worker.dispose();
}
