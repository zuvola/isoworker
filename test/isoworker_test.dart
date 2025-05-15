import 'package:test/test.dart';

import 'package:isoworker/isoworker.dart';

void workerMethod(Stream<WorkerData> message) {
  final testMap = {
    'key_1': 'val_1',
    'key_2': 'val_2',
  };
  message.listen((data) {
    final command = data.value['command'];
    switch (command) {
      case 'get':
        data.callback(testMap[data.value['key']]);
        break;
      case 'set':
        testMap[data.value['key']] = data.value['val'];
        data.callback(null);
        break;
      case 'wait':
        Future.delayed(Duration(milliseconds: 200)).then((_) {
          data.callback(null);
        });
        break;
      case 'waitset':
        Future.delayed(Duration(milliseconds: 200)).then((_) {
          testMap[data.value['key']] = data.value['val'];
          data.callback(null);
        });
        break;
      case 'twocallbacks':
        data.callback(1);
        data.callback(2);
        break;
      case 'error':
        throw Exception('error');
      default:
        data.callback(null);
    }
  }, onError: (e) => print('error: $e\nstack: ${e.stackTrace}'));
}

void main() {
  late IsoWorker worker;
  setUp(() async {
    worker = await IsoWorker.init(workerMethod);
  });
  tearDown(() async {
    await worker.dispose();
  });

  test('exec', () async {
    final res = await worker.exec({
      'command': 'get',
      'key': 'key_1',
    });
    expect(res, 'val_1');
  });

  test('wait', () async {
    expect(worker.inProgress, false);
    worker.exec({
      'command': 'waitset',
      'key': 'key_1',
      'val': 'val_1+',
    });
    final res = await worker.exec({
      'command': 'get',
      'key': 'key_1',
    });
    expect(worker.inProgress, true);
    expect(res, 'val_1');
    await Future.delayed(Duration(milliseconds: 300));
    final res2 = await worker.exec({
      'command': 'get',
      'key': 'key_1',
    });
    expect(worker.inProgress, false);
    expect(res2, 'val_1+');
  });

  test('no await', () async {
    worker.exec({
      'command': 'set',
      'key': 'key_1',
      'val': 'val_1+',
    });
    final res = await worker.exec({
      'command': 'get',
      'key': 'key_1',
    });
    expect(res, 'val_1+');
  });

  test('dispose', () async {
    await worker.dispose();
    expect(
        worker.exec({
          'command': 'get',
          'key': 'key_1',
        }),
        throwsA(isA<Exception>()));
  });

  test('dispose2', () async {
    expect(worker.inProgress, false);
    worker.exec({
      'command': 'wait',
    });
    expect(worker.inProgress, true);
    await worker.dispose();
  });

  test('error', () async {
    final worker = await IsoWorker.init(workerMethod);
    Object? exception;
    StackTrace? stack;
    final waitFuture = worker.exec({
      'command': 'wait',
    }).onError((e, s) {
      exception = e;
      stack = s;
      expect(exception, isNotNull);
      expect(stack, isNotNull);
    });
    expect(worker.inProgress, true);
    try {
      await worker.exec({
        'command': 'error',
      });
    } catch (e, s) {
      exception = e;
      stack = s;
    }
    expect(worker.inProgress, false);
    expect(exception, isNotNull);
    expect(stack, isNotNull);
    final res = await worker.exec({
      'command': 'get',
      'key': 'key_1',
    });
    expect(res, 'val_1');
    await waitFuture;
    await worker.dispose();
  });

  test('two callbacks', () async {
    await worker.exec({
      'command': 'twocallbacks',
    });
  });
}
