// Copyright 2025 zuvola. All rights reserved.

library isoworker;

export 'src/io_worker.dart' if (dart.library.html) 'src/web_worker.dart';
export 'src/worker_class.dart';
