import 'package:test/test.dart';

import 'package:isoworker/isoworker.dart';

class TestWorkerClass extends WorkerClass<Object, Map> {
  final Map<String, Object> _storage = {
    'key_1': 'val_1',
    'key_2': 2,
  };
  @override
  Future<Object?> execute(Map data) async {
    final command = data['command'];
    switch (command) {
      case 'get':
        return _storage[data['key']];
      case 'set':
        _storage[data['key']] = data['val'];
        break;
      case 'wait':
        await Future.delayed(Duration(milliseconds: 200));
        return _storage[data['key']];
      case 'waitset':
        await Future.delayed(Duration(milliseconds: 200));
        _storage[data['key']] = data['val'];
        break;
      case 'error':
        throw Exception('error');
      default:
        return null;
    }
    return null;
  }
}

void main() {
  late IsoWorker worker;
  setUp(() async {
    worker = await IsoWorker.create(TestWorkerClass());
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
    await worker.exec({
      'command': 'waitset',
      'key': 'key_1',
      'val': 'val_1+',
    });
    final res = await worker.exec({
      'command': 'get',
      'key': 'key_1',
    });
    expect(res, 'val_1+');
  });

  test('inProgress', () async {
    expect(worker.inProgress, false);
    worker.exec({
      'command': 'waitset',
      'key': 'key_1',
      'val': 'val_1+',
    });
    expect(worker.inProgress, true);
    final res = await worker.exec({
      'command': 'get',
      'key': 'key_1',
    });
    expect(res, 'val_1');
    await Future.delayed(Duration(milliseconds: 300));
    final res2 = await worker.exec({
      'command': 'get',
      'key': 'key_1',
    });
    expect(worker.inProgress, false);
    expect(res2, 'val_1+');
  });

  test('dispose', () async {
    await worker.dispose();
    expect(
        worker.exec({
          'command': 'get',
          'key': 'key_1',
        }),
        throwsA(isA<StateError>()));
  });

  test('dispose2', () async {
    expect(worker.inProgress, false);
    worker.exec({
      'command': 'wait',
    });
    expect(worker.inProgress, true);
    await worker.dispose();
    expect(worker.inProgress, false);
  });

  test('dispose3', () async {
    final waitFuture = worker.exec({
      'command': 'wait',
    });
    worker.dispose();
    expect(worker.inProgress, true);
    await waitFuture;
    expect(worker.inProgress, false);
  });

  test('error', () async {
    final worker = await IsoWorker.create(TestWorkerClass());
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
    expect(exception, isNotNull);
    expect(stack, isNotNull);
    final res = await worker.exec({
      'command': 'get',
      'key': 'key_1',
    });
    expect(res, 'val_1');
    await waitFuture;
    expect(worker.inProgress, false);
    await worker.dispose();
  });
}
