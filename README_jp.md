# isoworker

[![pub package](https://img.shields.io/pub/v/isoworker.svg)](https://pub.dartlang.org/packages/isoworker)

**[English](https://github.com/zuvola/isoworker/blob/master/README.md), [日本語](https://github.com/zuvola/isoworker/blob/master/README_jp.md)**

`isoworker`は`Isolate`クラスを使いやすくラップし、並列処理をより簡単に記述できるようにしたものです。  


## Features

- Flutterの`compute`とは異なりタスク実行時に`Isolate`オブジェクトを作成せずに使い回すのでオーバーヘッドが少ないです。
- タスクを`Future`でパイプライン化する事が出来ます。


## Usage

```dart
import 'package:isoworker/isoworker.dart';

/// `IsoWorker`が初期化された時に呼ばれるメソッド。
/// `Stream<WorkerData>`を引数にもつトップレベルかStaticメソッドを用意してください。
void workerMethod(Stream<WorkerData> message) {
  final _map = {
    'key_1': 'val_1',
    'key_2': 'val_2',
  };
  // Workerへのメッセージ(WorkerData)を受信します
  message.listen((data) {
    // `WorkerData.value`で`exec`実行時のデータを受け取ります
    final command = data.value['command'];
    switch (command) {
      case 'get':
        // 重い処理などを実行し結果を`WorkerData.callback`で返します
        data.callback(_map[data.value['key']]);
        break;
      default:
        // 何もなくても必ず`callback`は呼び出してください
        data.callback(null);
    }
  });
}

void main() async {
  // 初期化
  final worker = await IsoWorker.init(workerMethod);
  // タスクの実行
  final res = await worker.exec({
    'command': 'get',
    'key': 'key_1',
  });
  print(res);
  // Workerの破棄
  await worker.dispose();
}
```

## Note

Workerメソッド内でExceptionが発生した場合は全ての未実行のタスクに対してExceptionが通知されます。
