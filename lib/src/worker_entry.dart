import 'dart:async';
import 'dart:isolate';
import 'worker_data.dart';

void workerEntryPoint(WorkerConfig config) {
  final receivePort = ReceivePort();
  config.port.send(receivePort.sendPort);

  final stream = receivePort.cast<WorkerData>().transform<WorkerData>(
    StreamTransformer.fromHandlers(handleData: (value, sink) {
      value.callback = (data) {
        if (value.done) {
          throw StateError('Do not call the callback twice.');
        }
        value.done = true;
        config.port.send(WorkerData(value.id, data));
      };
      sink.add(value);
    }),
  );
  config.func(stream);
}

class WorkerConfig {
  final SendPort port;
  final IsoFunction func;

  const WorkerConfig(this.port, this.func);
}
