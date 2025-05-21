import 'dart:isolate';

import 'package:isoworker/isoworker.dart';

class MyWorkerClass extends WorkerClass<Object, Map> {
  final Map<String, Object> _sampleMap = {
    'key_1': 'val_1',
    'key_2': 1,
  };
  @override
  Future<Object?> execute(Map data) async {
    final command = data['command'];
    switch (command) {
      case 'get':
        return _sampleMap[data['key']];
      case 'set':
        _sampleMap[data['key']] = data['val'];
        return null;
      case 'wait':
        Future.delayed(Duration(milliseconds: 200)).then((_) {
          return _sampleMap[data['key']];
        });
        break;
      default:
        return null;
    }
    return null;
  }
}

// For Isolate.run
String? workerMethod(String key) {
  final sampleMap = {
    'key_1': 'val_1',
    'key_2': 'val_2',
  };
  return sampleMap[key];
}

void main() async {
  // Initialization
  final worker = await IsoWorker.create(MyWorkerClass());
  // Execute tasks
  final exec1 = worker.exec({
    'command': 'wait',
  });
  final exec2 = worker.exec({
    'command': 'set',
    'key': 'key_2',
    'val': 3,
  });
  final exec3 = worker.exec({
    'command': 'get',
    'key': 'key_2',
  });
  final res = await Future.wait([exec1, exec2, exec3]);
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
    await Isolate.run(() => workerMethod('key_1'));
  }
  stopWatch.stop();
  print('Isolate.run:${stopWatch.elapsedMilliseconds}ms');

  // Destroy the Worker
  await worker.dispose();
}
