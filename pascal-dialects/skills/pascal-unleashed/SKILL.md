---
name: pascal-unleashed
description: Unleashed Pascal ({$mode unleashed}) でコードを書くときの要点、objfpc/delphi との違い、検証済みの例、公式ドキュメントの索引
version: 1.1.0
metadata:
  hermes:
    tags: [pascal, unleashed, fpc]
    category: software-development
---

# Unleashed Pascal {$mode unleashed}

## When to Use
- `{$mode unleashed}` のソースを書く・直すとき
- inline var、match、タプル、async/await、autofree/defer、文字列補間を使いたいとき

Unleashed Pascal は Free Pascal のフォーク (3.3.1 ベース)。新しい言語なので、学習データの知識を当てにせず、
このスキルと公式ドキュメントで構文を確かめてから書くこと。
コンパイラは `~/unleashed/fpc/bin/fpc`。標準の `/usr/bin/fpc` では通らない。

## 必ず守ること
1. ファイル先頭に `{$mode unleashed}` を書く。書き忘れると objfpc 扱いになり、新しい構文が全部構文エラーになる。
2. ジェネリクスは Delphi 式に `<T>` だけで書く。`generic` / `specialize` は書かない
   (objfpc ベースのモードだが、ここは objfpc と違う)。ジェネリック関数の型引数は推論されないので明示する。
3. メソッドポインタ・手続き型変数への代入は `@` を付ける (ここは objfpc と同じ)。
4. inline var の初期化は `:=`。`var` 節の初期化は `=`。逆にすると構文エラー。
5. `if` / `case` / `match` / `try` を式として使うとき、分岐は値を返す式 1 つだけ。
   `raise`・`exit`・`begin..end`・手続き呼び出しは書けない。値を返さないなら文の形で書く。
   `match` 式と `on` 付きの `try` 式には `_` / `else` などの受け皿が必須。
6. `async` の結果 (future) は `await` して読む。Unix では `cthreads` を `uses` の先頭に置く
   (`async`、`for parallel`、`lock` を使うとき)。
7. `for parallel` のループ変数は inline (`for parallel var i := ...`)。共有状態は `lock` か Interlocked 系で守る。
8. 文字列補間 `$'...{式}...'` の波括弧の中は普通の式。文字列は `'abc'` と書き、引用符を二重にしない。
   外側の地の文で `'` を出すときだけ `''` にする。
9. 解放は `autofree` (ブロック終了時) か `defer X.Free;` を使ってよい。try/finally も使える。
10. 環境変数は main で一度だけ `GetEnvironmentVariable` で読み、値を引数で渡す。`GetEnvironmentVariable` は
    起動時の環境の写しを読むので、libc の `setenv` であとから変えた値は見えない (テストで差し替えられない)。

## 方言の違い (同じことを 5 方言で)

| 項目 | FPC objfpc | FPC delphi モード | Unleashed | Delphi (Embarcadero) | Oxygene |
|---|---|---|---|---|---|
| ファイル先頭 | `{$mode objfpc}{$H+}` | `{$mode delphi}` | `{$mode unleashed}` | なし (`unit` / `program`) | `namespace X;` |
| ジェネリクス宣言 | `generic TBox<T> = ...` | `TBox<T> = ...` | `TBox<T> = ...` | `TBox<T> = ...` | `Box<T> = ...` |
| ジェネリクス利用 | `specialize TList<Integer>` | `TList<Integer>` | `TList<Integer>` | `TList<Integer>` | `new List<Integer>` |
| メソッドポインタ代入 | `@Obj.Method` | `Obj.Method` | `@Obj.Method` | `Obj.Method` | イベントに `+= @obj.Method` |
| string | `{$H+}` が必要 | AnsiString | AnsiString | UnicodeString (1 始まり) | 環境の文字列 (0 始まり、不変) |
| inline var | 不可 | 不可 | `var x := 1;` | `var x := 1;` (10.3 以降) | `var x := 1;` |
| 生成 | `TFoo.Create` | `TFoo.Create` | `TFoo.Create` | `TFoo.Create` | `new Foo(...)` |
| 解放 | `try/finally` で `Free` | `try/finally` で `Free` | `autofree` / `defer` も可 | `try/finally` で `Free` | 不要 (GC / ARC) |
| メソッド宣言 | `procedure` / `function` | 同左 | 同左 | 同左 | `method` |

## 例 (コンパイルと出力を検証済み)
このスキルのディレクトリの `examples/<ファイル>` から必要なものだけ読む
(Claude Code: スキルのベースディレクトリからの相対パスで Read。Hermes: `skill_view(name="pascal-unleashed", file_path="examples/<ファイル>")`)。
01〜05 は pascal-fpc-objfpc / pascal-fpc-delphi の例と同じお題。

| ファイル | 内容 |
|---|---|
| `examples/01_class_property.pas` | 自動プロパティ (readonly)、autofree、補間 |
| `examples/02_generics.pas` | `<T>` だけのジェネリクス、if 式、for var、`+=` |
| `examples/03_exceptions.pas` | 文の try/except と、`on` + `else` の try 式 |
| `examples/04_strings_lists.pas` | TStringList を autofree で、補間の中の文字列 |
| `examples/05_events.pas` | `@` が必要なメソッドポインタ代入 |
| `examples/06_match_tuples.pas` | タプルの戻り値と分割代入、match 文、条件形式の match 式 |
| `examples/07_async_parallel.pas` | async/await、for parallel、lock、cthreads |
| `examples/08_defer.pas` | defer の LIFO 順と、実行時点の値での評価 |
| `examples/09_environment.pas` | 環境変数: `setenv` の値が `GetEnvironmentVariable` に見えない罠と、値で渡す形 |

## 落とし穴 (コンパイルが失敗することを検証済み)

| ファイル | 誤り | エラー |
|---|---|---|
| `pitfalls/p01_generic_keyword.pas` | objfpc 式の `generic` を書く | "=" expected but "identifier TBOX" found |
| `pitfalls/p02_inline_var_with_equals.pas` | inline var を `=` で初期化 | ";" expected but "=" found |
| `pitfalls/p03_raise_in_expression.pas` | case 式の分岐に `raise` | Illegal expression |
| `pitfalls/p04_future_without_await.pas` | future を await せずに使う | future value used without `await` |
| `pitfalls/p05_case_on_tuple.pas` | タプルに case | Ordinal or string expression expected |
| `pitfalls/p06_missing_mode.pas` | `{$mode unleashed}` の書き忘れ | Parser - Syntax Error |
| `pitfalls/p07_doubled_quote_in_placeholder.pas` | 補間の中で `''abc''` | ")" expected but "identifier ABC" found |

## 公式ドキュメント (機能ごとの詳細)
例で足りないときは、該当する 1 ファイルだけを読む。1 ファイル数千トークンあるので、まとめて読まない。
場所: `~/unleashed/fpcsrc/unleashed/docs/` (Unleashed のソースツリーがない環境では、この索引は使えない)

| 機能 | ファイル |
|---|---|
| 全体の索引・modeswitch 一覧 | `README.md` |
| inline var、型推論、`=` と `:=` | `inline-vars.md` |
| if / case / try 式 | `statement-expressions.md` |
| match | `match.md` |
| タプル | `tuples.md` |
| out 変数 `f(var x)` | `out-var.md` |
| 複数変数の一括初期化 | `multi-var-init.md` |
| `+=` などの複合代入 | `compound-assignment.md` |
| for ... step | `forstep.md` |
| 自動プロパティ | `auto-properties.md` |
| autofree / defer / scoped with | `autofree.md` |
| async / await | `async-await.md` |
| for parallel | `parallelfor.md` |
| lock / trylock | `lock.md` |
| threadstatic / static 変数 | `thread-static.md`, `static-section.md` |
| 文字列補間 | `string-interpolation.md` |
| 複数行文字列 | `multiline-strings.md` |
| 配列の比較 | `array-equality.md` |
| レコードの合成 (embed, union, bitfield) | `composable-records.md` |
| 可変長配列メンバー | `flexible-arrays.md` |
| Int128 | `int128.md` |
| 追加された関数・組み込み | `introduced-functions.md`, `swapvalues.md`, `type-intrinsic.md` |
| 暗黙ジェネリクスなど細かい改善 | `extra-improvements.md`, `tweaks.md` |
| その他 (最適化、埋め込み、RTTI 除去など) | `optimizations.md`, `embed.md`, `strip-rtti.md`, `forced-inline.md`, `zeroinit.md`, `indexed-labels.md`, `binary-metadata.md`, `static-library.md` |

## Verification
- `~/unleashed/fpc/bin/fpc -vew -l- -FE<一時ディレクトリ> <ファイル>` でエラーが出ない。
- `rawpaco <ファイル>` で指摘が出ない。tree-sitter-pascal は新構文を完全には解析できないが、
  空の except などの検出は効く。新構文の行で不自然な指摘が出たら、コンパイル結果を優先する。
