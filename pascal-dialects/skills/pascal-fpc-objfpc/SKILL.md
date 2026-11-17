---
name: pascal-fpc-objfpc
description: Free Pascal 3.2 の {$mode objfpc} でコードを書くときの要点、他方言との違い、検証済みの例
version: 1.1.0
metadata:
  hermes:
    tags: [pascal, fpc, objfpc]
    category: software-development
---

# Free Pascal {$mode objfpc}

## When to Use
- `{$mode objfpc}` のソース (.pas / .pp / .lpr) を書く・直すとき
- Lazarus 既定の形式で新しくユニットやプログラムを作るとき

コンパイラは標準の FPC 3.2.2 (`/usr/bin/fpc`)。Unleashed Pascal の構文は使えない。

## 必ず守ること
1. ファイル先頭に `{$mode objfpc}{$H+}` を書く。`{$H+}` がないと `string` が ShortString (255 文字) になる。
2. ジェネリクスは宣言に `generic`、利用に `specialize` を付ける。
   `type TIntList = specialize TList<Integer>;`、`specialize MaxOf<Integer>(4, 9)`
3. メソッドポインタ・手続き型変数への代入は `@` を付ける。`Btn.OnClick := @Frm.HandleClick;`
4. 変数は `var` 節で宣言する。`begin` の中の `var x := 1;` (inline var) は FPC 3.2 にはない。
5. 生成したオブジェクトは `try ... finally X.Free; end;` で解放する。
6. 環境変数は main で一度だけ `GetEnvironmentVariable` で読み、値を引数で渡す。`GetEnvironmentVariable` は
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
(Claude Code: スキルのベースディレクトリからの相対パスで Read。Hermes: `skill_view(name="pascal-fpc-objfpc", file_path="examples/<ファイル>")`)。

| ファイル | 内容 |
|---|---|
| `examples/01_class_property.pas` | クラス、プロパティ、setter での検査、try/finally |
| `examples/02_generics.pas` | generic レコード、specialize、generic 関数、Generics.Collections |
| `examples/03_exceptions.pas` | 独自例外、CreateFmt、on E: 型 do |
| `examples/04_strings_lists.pas` | TStringList、Format、文字列ヘルパー |
| `examples/05_events.pas` | `of object` イベントと手続き型変数への `@` 代入 |
| `examples/06_environment.pas` | 環境変数: `setenv` の値が `GetEnvironmentVariable` に見えない罠と、値で渡す形 |

## 落とし穴 (コンパイルが失敗することを検証済み)

| ファイル | 誤り | エラー |
|---|---|---|
| `pitfalls/p01_generic_without_specialize.pas` | `TList<Integer>` をそのまま型に使う | Generics without specialization |
| `pitfalls/p02_method_pointer_without_at.pas` | `P := A.Handler` (@ なし) | Incompatible types |
| `pitfalls/p03_inline_var.pas` | `begin` 内の `var x := 1;` | Illegal expression |

## Verification
- `fpc -vew -l- -FE<一時ディレクトリ> <ファイル>` でエラーが出ない。
- `rawpaco <ファイル>` で指摘が出ない (存在しない API、`{$mode}` の混在、解放漏れなど)。
