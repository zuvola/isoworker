@TestOn('vm')

import 'dart:async';
import 'dart:isolate';

import 'package:isoworker/isoworker.dart';
import 'package:test/test.dart';

class TerminatingWorker extends WorkerClass<Object, Map> {
  @override
  Future<Object?> execute(Map data) async {
    switch (data['command']) {
      case 'wait':
        return Completer<Object?>().future;
      case 'exit':
        Isolate.exit();
      case 'crash':
        // An uncaught asynchronous error must terminate the isolate.
        Future<void>.microtask(() => throw StateError('Uncaught worker failure'));
        return Completer<Object?>().future;
      default:
        return 'ok';
    }
  }
}

void main() {
  test('pending requests fail when the isolate exits unexpectedly', () async {
    final worker = await IsoWorker.create(TerminatingWorker());
    try {
      final pending = worker.exec({'command': 'wait'});
      final exiting = worker.exec({'command': 'exit'});

      await Future.wait([
        expectLater(
          pending.timeout(const Duration(seconds: 3)),
          throwsA(isA<StateError>()),
        ),
        expectLater(
          exiting.timeout(const Duration(seconds: 3)),
          throwsA(isA<StateError>()),
        ),
      ]);

      expect(worker.inProgress, isFalse);
      await expectLater(
        worker.exec({'command': 'ping'}),
        throwsA(isA<StateError>()),
      );
      await worker.dispose().timeout(const Duration(seconds: 3));
    } finally {
      await worker.dispose();
    }
  });

  test('uncaught isolate errors fail outstanding requests', () async {
    final worker = await IsoWorker.create(TerminatingWorker());
    try {
      final pending = worker.exec({'command': 'wait'});
      final crashing = worker.exec({'command': 'crash'});

      await Future.wait([
        expectLater(
          pending.timeout(const Duration(seconds: 3)),
          throwsA(anyOf(isA<RemoteError>(), isA<StateError>())),
        ),
        expectLater(
          crashing.timeout(const Duration(seconds: 3)),
          throwsA(anyOf(isA<RemoteError>(), isA<StateError>())),
        ),
      ]);

      expect(worker.inProgress, isFalse);
      await expectLater(
        worker.exec({'command': 'ping'}),
        throwsA(isA<StateError>()),
      );
    } finally {
      await worker.dispose();
    }
  });

  test('normal disposal does not report unexpected termination', () async {
    final worker = await IsoWorker.create(TerminatingWorker());
    expect(await worker.exec({'command': 'ping'}), 'ok');
    await worker.dispose();
    await expectLater(
      worker.exec({'command': 'ping'}),
      throwsA(isA<StateError>()),
    );
  });
}
