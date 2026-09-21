---
name: polyglot-scripting
description: bash / Babashka (bb) / instantfpc (Free Pascal) でスクリプトを書くときのテンプレート、利用可能な組み込み名前空間、記述ルール。ワンライナーを超えるスクリプト、JSON/YAML/CSV/XML 処理、HTTP 通信、バイナリ/ファイル操作、性能が問題になる処理のコードを書く前に読む。Python や Node.js で書きたくなった場合の代替を探すときにも読む。
---

# Polyglot Scripting

3つの実行系を使い分ける。迷ったらこの順に降りていく。

## 1. 選択

| 状況 | 使うもの |
|---|---|
| 1行で完結するテキスト処理・パイプライン | bash / grep / sed / awk |
| 構造化データ (JSON/YAML/CSV/XML)、HTTP、複雑なテキスト処理 | Babashka (`bb`) |
| 性能重視、低レイヤ操作、バイナリ/ファイル操作 | instantfpc (Free Pascal) |

Python と Node.js は使わない。`python -c` / `node -e` の類は PreToolUse フックでブロックされる。

**降りる前に一段上を疑うこと。** bb を書き始める前に、その処理が本当に `awk` 1行で書けないか確認する。
このポリシーの主目的は「Python を禁止すること」ではなく「ワンライナーで済むものをスクリプトに
膨らませないこと」にある。

## 2. bash

複数行スクリプトとして書く場合:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- 移植性: `ksh` や標準 POSIX sh で実行される可能性を意識する。`[[ ]]`、`<()`、配列、
  `${var,,}` 等の Bash 専用構文への依存は、必要性を確認してから使う。
- 3行を超え、条件分岐やデータ構造が出てきたら bb への移行を検討する。

## 3. Babashka

詳細は `references/babashka.md`。要点だけ:

- 追加依存なしの**ワンファイル**として書く。組み込み名前空間のみを使う。
- 許可されている名前空間は `${CLAUDE_PLUGIN_ROOT}/data/babashka-namespaces.edn` が正本。
  ここに無い名前空間を `require` すると PostToolUse フックがブロックする。
- 外部 pod や JVM 専用ライブラリが必要になった場合は、勝手に `require` せず利用者に申告して
  確認を取る。
- 環境のバージョンはセッション開始時に実測値が渡されている。固定値を前提にしない。

## 4. instantfpc

詳細は `references/instantfpc.md`。テンプレート:

```pascal
#!/usr/bin/env instantfpc
{$mode objfpc}{$H+}
program ScriptName;

uses
  SysUtils;

begin
end.
```

## 5. 検証

書いたら、その場で実行して確かめる。

```bash
bb script.bb          # 構文エラーは即座に出る
instantfpc script.pas # 初回はコンパイル、以降はキャッシュ
shellcheck script.sh  # 導入されていれば
```

`.pas` を書いた場合、環境に `rawpaco` があれば PostToolUse フックが自動で走り、
指摘があれば文脈に返ってくる。
