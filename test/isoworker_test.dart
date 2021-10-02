import 'package:test/test.dart';

import 'package:isoworker/isoworker.dart';

void workerMethod(Stream<WorkerData> message) {
  final _map = {
    'key_1': 'val_1',
    'key_2': 'val_2',
  };
  message.listen((data) {
    final command = data.value['command'];
    switch (command) {
      case 'get':
        data.callback(_map[data.value['key']]);
        break;
      case 'set':
        _map[data.value['key']] = data.value['val'];
        data.callback(null);
        break;
      case 'wait':
        Future.delayed(Duration(milliseconds: 100)).then((_) {
          data.callback(null);
        });
        break;
      case 'nocallback':
        break;
      case 'error':
        throw Exception('error');
      default:
        data.callback(null);
    }
  });
}

void main() {
  late IsoWorker worker;
  setUp(() async {
    worker = await IsoWorker.init(workerMethod);
  });
  tearDown(() async {
    await Future.delayed(Duration(milliseconds: 200));
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
    worker.exec({
      'command': 'wait',
    });
    final res = await worker.exec({
      'command': 'get',
      'key': 'key_1',
    });
    expect(res, 'val_1');
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

  test('error', () async {
    final worker = await IsoWorker.init(workerMethod);
    Object? exception;
    StackTrace? stack;
    worker.exec({
      'command': 'wait',
    }).onError((e, s) {
      exception = e;
      stack = s;
      expect(exception, isNotNull);
      expect(stack, isNotNull);
    });
    try {
      await worker.exec({
        'command': 'error',
      });
    } catch (e, s) {
      exception = e;
      stack = s;
    }
    expect(exception, isNotNull);
    expect(stack, isNotNull);
    final res = await worker.exec({
      'command': 'get',
      'key': 'key_1',
    });
    expect(res, 'val_1');
  });
}
