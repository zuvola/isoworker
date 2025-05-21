# isoworker

[![pub package](https://img.shields.io/pub/v/isoworker.svg)](https://pub.dartlang.org/packages/isoworker)

**[English](https://github.com/zuvola/isoworker/blob/master/README.md), [日本語](https://github.com/zuvola/isoworker/blob/master/README_jp.md)**

> **⚠️ Version 2.0 Notice:**  
> This release introduces breaking changes.  
> The usage and API have changed significantly from previous versions.  
> Please read the updated documentation and usage examples below.

`isoworker` provides a simple and unified API for parallel processing using Isolates (native) and Streams (web) in Dart.

**Effortlessly harness the power of parallelism in your Dart and Flutter apps!**  
With isoworker, you can easily offload heavy computations to background workers, keeping your UI smooth and responsive.  
Whether you're building for native or web, isoworker gives you a consistent, easy-to-use interface for running tasks in parallel.

## Features

- Lower overhead than Flutter's `compute` by reusing Isolate/Stream workers.
- Supports both native and web platforms with a unified interface.
- Tasks can be pipelined with `Future`.
- Simple, extensible API for defining your own worker logic.
- Great for CPU-intensive tasks, parsing, encoding, or any async workload.

## Usage

```dart
import 'package:isoworker/isoworker.dart';

// Define your worker logic by extending WorkerClass.
class MyWorker extends WorkerClass<String, String> {
  @override
  Future<String> execute(String data) async {
    // Simulate heavy processing or any async task.
    await Future.delayed(Duration(milliseconds: 100));
    return 'Hello, $data!';
  }
}

void main() async {
  // Create and initialize the worker.
  final worker = await IsoWorker.create(MyWorker());

  // Execute a task.
  final result = await worker.exec<String, String>('World');
  print(result); // Output: Hello, World!

  // Dispose the worker when done.
  await worker.dispose();
}
```

