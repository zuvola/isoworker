// Copyright 2022 zuvola. All rights reserved.

library isoworker;

export 'src/io_worker.dart' if (dart.library.html) 'src/web.dart';
export 'src/worker_data.dart';
