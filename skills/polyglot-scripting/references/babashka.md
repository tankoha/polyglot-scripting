<!-- 自動生成: bb scripts/gen-reference.clj -->
<!-- 正本は data/babashka-namespaces.edn。このファイルを直接編集しないこと -->

# Babashka 組み込み名前空間

追加依存なし・ワンファイルで書くこと。以下の 40 個のみ使用可能（1.13.222 で確認）。

ここに無い名前空間を `require` すると PostToolUse フックがブロックする。
外部 pod や JVM 専用ライブラリが必要な場合は、勝手に `require` せず利用者に申告して確認を取る。

### ファイル・パス操作

- `babashka.fs`
- `clojure.java.io`

### プロセス・シェル・CLI

- `babashka.cli`
- `babashka.process`
- `babashka.signal`
- `babashka.terminal`
- `clojure.java.process`
- `clojure.java.shell`
- `clojure.tools.cli`

### HTTP 通信・Web

- `babashka.curl`
- `babashka.http-client`
- `org.httpkit.client`
- `org.httpkit.server`

### データフォーマット (JSON/YAML/CSV/XML/Transit/EDN)

- `cheshire.core` (JSON)
- `clj-yaml.core` (YAML)
- `clojure.data.csv`
- `clojure.data.xml`
- `clojure.edn`
- `cognitect.transit`

### HTML / テンプレート / Markdown

- `hiccup.core` (HTML 生成)
- `hiccup2.core` (HTML 生成)
- `nextjournal.markdown` (Markdown パース)
- `selmer.parser` (Django 風テンプレートエンジン)

### データ構造・操作・ユーティリティ

- `clojure.core.async` (非同期処理)
- `clojure.core.match` (パターンマッチング)
- `clojure.math`
- `clojure.set`
- `clojure.string`
- `clojure.walk`
- `clojure.zip`
- `flatland.ordered.map`
- `flatland.ordered.set`

### ログ・デバッグ・テスト

- `clojure.pprint` (整形出力)
- `clojure.test`
- `clojure.test.check`
- `clojure.tools.logging`
- `taoensso.timbre` (ロギング)

### コードパース・SCI

- `edamame.core`
- `rewrite-clj.zip`
- `sci.core`

## 確認方法

ある名前空間がその環境で使えるかは、実際に試すのが確実:

```bash
bb -e "(require '[babashka.fs])" && echo ok
```

## 書き方

```clojure
#!/usr/bin/env bb
(require '[babashka.fs :as fs]
         '[cheshire.core :as json])

(->> (fs/glob "." "**/*.json")
     (map (comp json/parse-string slurp fs/file))
     (run! prn))
```

- 標準入力は `*in*`、`(slurp *in*)` で読む
- 終了コードは `(System/exit n)`
- 引数は `*command-line-args*`。オプション解析が要るなら `babashka.cli`
