# isoworker

[![pub package](https://img.shields.io/pub/v/isoworker.svg)](https://pub.dartlang.org/packages/isoworker)

**[日本語](https://github.com/zuvola/isoworker/blob/master/README_jp.md), [English](https://github.com/zuvola/isoworker/blob/master/README.md)**

> **⚠️ バージョン2.0のお知らせ:**  
> このリリースでは破壊的な変更が含まれています。  
> 以前のバージョンから使い方やAPIが大きく変更されています。  
> 必ず最新のドキュメントと使用例をご確認ください。

`isoworker`は、DartのIsolate（ネイティブ）とStream（Web）を利用した並列処理を、シンプルかつ統一的なAPIで提供します。

**DartやFlutterアプリで手軽に並列処理を活用！**  
isoworkerを使えば、重い計算処理を簡単にバックグラウンドワーカーへオフロードでき、UIを滑らかに保つことができます。  
ネイティブでもWebでも、isoworkerは一貫した使いやすいインターフェースで並列タスクを実行できます。

## 特長

- Isolate/Streamワーカーの再利用により、Flutterの`compute`よりも低オーバーヘッド
- ネイティブ・Web両対応の統一インターフェース
- タスクを`Future`でパイプライン処理可能
- 独自のワーカーロジックを簡単に拡張できるAPI
- CPU負荷の高い処理、パース、エンコード、非同期処理全般に最適

## 使い方

```dart
import 'package:isoworker/isoworker.dart';

// WorkerClassを継承してワーカーロジックを定義
class MyWorker extends WorkerClass<String, String> {
  @override
  Future<String> execute(String data) async {
    // 重い処理や非同期処理をここで実行
    await Future.delayed(Duration(milliseconds: 100));
    return 'Hello, $data!';
  }
}

void main() async {
  // ワーカーの生成と初期化
  final worker = await IsoWorker.create(MyWorker());

  // タスクの実行
  final result = await worker.exec<String, String>('World');
  print(result); // 出力: Hello, World!

  // 使い終わったらワーカーを破棄
  await worker.dispose();
}
```

