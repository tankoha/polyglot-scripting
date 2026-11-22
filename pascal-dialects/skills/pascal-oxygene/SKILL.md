---
name: pascal-oxygene
description: RemObjects Oxygene (Elements) でコードを書くときの要点、Delphi との違い、例 (Elements 14 の .NET Core で検証済み)
version: 1.1.0
metadata:
  hermes:
    tags: [pascal, oxygene, remobjects, elements]
    category: software-development
---

# Oxygene (RemObjects Elements)

## When to Use
- `namespace X;` で始まる Oxygene のソース (.pas) を書く・直すとき

Oxygene は Object Pascal 系だが、Delphi・FPC とは別の言語。.NET (Echoes)、Java (Cooper)、
Cocoa (Toffee)、ネイティブ (Island) 向けにコンパイルされる。
**例は Elements 14.0.0.3157 の EBuild で .NET Core (Echoes) 向けにビルドし、実行結果まで確かめてある**
(`tests/check-examples.sh pascal-oxygene`)。他のプラットフォーム (Island 等) では未確認。公式ドキュメント
(https://elements.docs.remobjects.com/Oxygene/) の構文に基づいて書いている。迷ったら公式ドキュメントを確認すること。

## 必ず守ること
1. ファイルは `namespace X;` で始め、`end.` で終える。`unit` は使わない。`uses` は名前空間を取り込む。
   `interface` / `implementation` に分ける書き方と、型の中にメソッド本体を書く書き方 (unified) の両方がある。
2. メソッドは `method`。`procedure` / `function` は非推奨。クラスメソッドは `class method`。
3. コンストラクタは名前なしの `constructor(...)`。実装は `constructor TypeName(...)`。
   生成は `new Foo(...)` (`Foo.Create` は使えない)。基底の呼び出しは `inherited constructor(...)`。
4. GC / ARC なので `destructor` も `Free` も `try/finally` での解放もいらない。必要なら finalizer を使う。
5. 戻り値は `result` に入れるか、`exit 値` で返す。
6. 変数は inline の `var x := 1;` が基本。`for i := 0 to 10 do` の `i` はループ自身が宣言する。
   コレクションは `for each x in list do` (`index i` で番号、`step` / `downto` / `for parallel` もある)。
7. ジェネリクスは `<T>` だけ。制約は Delphi 式ではなく `where` (例: `where T is IFoo`、`T has constructor`)。
8. `String` は環境の文字列 (.NET なら System.String)。不変で **0 始まり**。`nil` と `''` は別物。
   リテラルは `'...'` でも `"..."` でもよい。補間は `$'...{式}...'`。
9. 既定値・初期化は `:=` (`fCount: Integer := 5;`、`b: String := 'x'` の既定引数)。本当の定数だけ `const X = 5;`。
10. `var` / `out` 引数は呼び出し側でも `var` / `out` を付ける: `TryParse(s, out value)`。
11. イベントは `event Clicked: block(aMessage: String);`。購読は `+= @obj.Method`、解除は `-= @obj.Method`。
    呼ぶ前に `assigned(Clicked)` を確かめる (未購読で呼ぶと例外)。
12. 無名メソッドは `method(a: Integer); begin ... end`、ラムダは `a -> 式` / `(a, b) -> 式` / `() -> 式`。
13. Delphi にあって Oxygene にないもの: `destructor`、`initialization` / `finalization` 節、`resourcestring`、
    `published`、`overload` 指定 (常に有効)、`reference to`、`asm`、Delphi 式の `with`。

## コンパイラで確かめた罠 (Elements 14、2026-11-22)
- 制約のない型引数どうしに `=` は使えない (`cannot find operator to evaluate "T" = "T"`)。
  `a.Equals(b)` か `EqualityComparer<T>.Default.Equals(a, b)` を使う。
- `{ ... }` コメントは最初の `}` で閉じる。コメントに `$'{式}'` のような波括弧を書くとそこで閉じ、
  後ろが構文エラーになる (`got two dots (..)` など)。波括弧を含むコメントは `(* ... *)` にする。
- `loop` は予約語 (無限ループの `loop` 文)。メソッド名などに `Loop` を使うと `identifier expected, got "loop"`。
  名前を変えるか `&Loop` と書く。

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

## 例 (Elements 14 の .NET Core で検証済み)
このスキルのディレクトリの `examples/<ファイル>` から必要なものだけ読む
(Claude Code: スキルのベースディレクトリからの相対パスで Read。Hermes: `skill_view(name="pascal-oxygene", file_path="examples/<ファイル>")`)。
01〜05 は他方言の例と同じお題。

| ファイル | 内容 |
|---|---|
| `examples/01_class_property.pas` | namespace、名前なしコンストラクタ、new、自動プロパティ、GC (Free なし) |
| `examples/02_generics.pas` | new List<Integer>、for each、Dictionary、ジェネリックメソッドと exit 値 |
| `examples/03_exceptions.pas` | 独自例外、raise new、on E: 型 do |
| `examples/04_strings_lists.pas` | 0 始まりの String、for each ... index、補間 |
| `examples/05_events.pas` | event と block 型、+= @メソッド、ラムダでの購読、assigned |
| `examples/06_lambdas_loops.pas` | ラムダ、無名メソッド、step / downto |

## Verification
- 例の検証: `tests/check-examples.sh pascal-oxygene` (Earth の flatpak に同梱の EBuild と dotnet を使う)。
- 書いたコードを手で確かめるとき: `.elements` プロジェクト (例は check-examples.sh の oxygene_project) を作り、
  `flatpak run --command=/app/dotnet/dotnet com.remobjects.earth /app/earth/EBuild.dll X.elements` でビルド、
  同じ `--command` で `Bin/X.dll` を実行する。flatpak の中の `/tmp` はホストと別なのでホームの下で作業する。
- 書いたソースはフック (`verify`) ではコンパイルされない。
- 検証していない構文を新たに使うときは、公式ドキュメントで書き方を確認してから使う。
