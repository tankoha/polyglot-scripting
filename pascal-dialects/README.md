# pascal-dialects

Free Pascal の `{$mode objfpc}` / `{$mode delphi}`、Unleashed Pascal (`{$mode unleashed}`)、
Delphi (Embarcadero)、Oxygene (RemObjects) を、方言ごとの知識 (スキル) と、
読ませる強制・コンパイル検証 (フック) で書き分けさせる Claude Code プラグイン。

スキルは Hermes Agent と共用している (Hermes 側のフックは
[hermes-agent-setup](https://github.com/tankoha/hermes-agent-setup) の `pascal/`)。
SKILL.md の中の例の読み方は、両方の書き方を併記している。

| 層 | 置き場所 | 中身 |
|---|---|---|
| 知識 (RAG / few-shot) | `skills/pascal-*/` | 方言の要点、5 方言の対比表、例 (`examples/`) と誤りの例 (`pitfalls/`) |
| 読ませる強制 | `hooks/pascal-guard.clj guard` (PreToolUse) | 方言が判断できないソースと、方言のスキルを読む前の書き込みを止める |
| 検証 | `hooks/pascal-guard.clj verify` (PostToolUse) | 書いたソースを方言に合うコンパイラでコンパイルし、エラーを返す |

rawpaco による lint は polyglot-scripting の `lint-script.clj` が `.pas` / `.pp` に対して行うので、ここでは呼ばない。

## 導入

polyglot-scripting とは別のプラグインなので、Pascal を書く環境でだけ入れればよい。

marketplace から (Claude Code 内で):

```
/plugin install pascal-dialects --marketplace tankoha/polyglot-scripting
```

bootstrap.sh で入れる環境では、`PASCAL_DIALECTS=1 ./polyglot-scripting/bootstrap.sh` とすると
`~/.claude/skills/pascal-dialects` にシンボリックリンクを張り、`pascal-dialects@skills-dir` として自動ロードされる。
Releases の `pascal-dialects-<version>.plugin` はデスクトップ版のアップロード用。

フックは `bb` を使う。コンパイル検証には FPC (Unleashed の例には Unleashed の fpc) が要る。なければ検証だけ飛ばす。

## スキル

| スキル | 例の検証 | 例 | 誤りの例 |
|---|---|---|---|
| `pascal-fpc-objfpc` | `/usr/bin/fpc` (3.2.2) | 5 | 3 |
| `pascal-fpc-delphi` | `/usr/bin/fpc` (3.2.2) | 5 | 3 |
| `pascal-unleashed` | `~/unleashed/fpc/bin/fpc` (3.3.1 フォーク) | 8 | 7 |
| `pascal-delphi` | 近似: Unleashed の fpc で `-Mdelphiunicode` + inline var・無名メソッド | 7 | 3 |
| `pascal-oxygene` | なし (コンパイラがない。公式ドキュメントの構文に基づき「未検証」と明記) | 6 | 0 |

例 01〜05 は全方言で同じお題 (クラスとプロパティ、ジェネリクス、例外、文字列とリスト、イベント)。
並べると違いが分かる対比例になっている。

Unleashed Pascal の機能別の公式ドキュメント (`~/unleashed/fpcsrc/unleashed/docs/`) は写さず、
スキルに索引だけを置いて、必要な 1 ファイルを読ませる。Unleashed のソースツリーがない環境では索引は使えない。

試作中に分かった、モデルが間違えやすい点:
- Unleashed は objfpc ベースだが、ジェネリクスは Delphi 式 (`generic` / `specialize` を書くとエラー)。
  一方でメソッドポインタの代入は objfpc と同じく `@` が必要。
- 文字列補間の `{...}` の中は普通の式なので、文字列の引用符は二重にしない。
- Delphi はグローバルなジェネリック関数を書けない (FPC の delphi モードは書ける)。
- Delphi の管理レコードは `Initialize(out ...)`、FPC は `Initialize(var ...)`。

### Delphi の近似検証の限界
本物の Delphi はこの環境にない。例は純粋な Delphi の書き方 (`System.SysUtils` などの名前空間付きユニット、
`{$APPTYPE CONSOLE}`) で書き、検証時だけ名前空間を FPC のユニット名に置き換えた写しを FPC でコンパイルする。
FPC と Delphi で結果が違う書き方は、例や誤りの例に入れていない:
- `TProc<T>` / `TFunc<T, TResult>` (FPC の SysUtils にない) → 例では自前の `reference to` 型を使い、SKILL.md に知識として書く
- `TStringBuilder` (FPC では `TAnsiStringBuilder` の別名でクラス名が違う) → 例では使わない
- 管理レコード、グローバルなジェネリック関数 → SKILL.md に知識として書くだけ

## 方言の判定 (フック)

1. `{$mode X}` があれば X (objfpc / delphi / delphiunicode / unleashed)。
   ソースになければ、`{$I file}` / `{$INCLUDE file}` で取り込むファイル (ソースと同じディレクトリから解決できるもの) も見る
2. `namespace X;` で始まれば Oxygene
3. 拡張子が `.dpr` / `.dpk`、またはファイルのディレクトリか 4 階層上までに `.dproj` があれば Delphi (Embarcadero)
4. どれでもなければ書き込みを止めて、方言を明示させる

`#!` で始まるソース (instantfpc のスクリプト) は polyglot-scripting の管轄なので、判定も検証もしない。

`verify` の振る舞い:
- Delphi と Oxygene はコンパイルしない (スキルを読ませる強制だけ)。
- コンパイラがない環境では何もしない。
- エラーが「ユニットが見つからない」だけのときは黙る (プロジェクトの検索パスはフックからは分からないため)。
- `PASCAL_DIALECTS_VERIFY=0` で止められる。

## 設定 (環境変数)

| 変数 | 既定値 |
|---|---|
| `PASCAL_FPC_STOCK` | `/usr/bin/fpc` |
| `PASCAL_FPC_UNLEASHED` | `~/unleashed/fpc/bin/fpc` |
| `PASCAL_DIALECTS_VERIFY` | (未設定。`0` でコンパイル検証を止める) |

スキルを読んだかの記録はセッション単位で、`$CLAUDE_PLUGIN_DATA` (なければ `~/.claude/pascal-dialects/`) の
`skills-loaded.tsv` に残す。サブエージェントのセッションは、親とは別に自分で読む必要がある。

## 試験

```bash
tests/check-examples.sh   # 全スキル。例はコンパイル・実行・出力比較、誤りの例は想定のエラーで失敗すること
tests/hooks.sh            # フックを合成ペイロードで試す
```

例を足すときは `examples/NN_名前.pas` (Delphi は `.dpr`) と期待出力 `NN_名前.expected`、
誤りの例は `pitfalls/pNN_名前.pas` (コメントに `expect-error: <エラー文の一部>`) を置き、`check-examples.sh` が通ることを確認する。

## 制約

- `.inc` そのものの編集は対象外。
- コンパイル検証はファイルのあるディレクトリだけを `-Fu` / `-Fi` に入れる。
- Delphi と Oxygene のコードはコンパイルで検証されない。それぞれの環境でビルドして確かめること。
- Bash の heredoc などでファイルを書くと、フックを通らない。
