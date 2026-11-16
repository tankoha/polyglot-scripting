---
name: pascal-delphi
description: 本物の Delphi (Embarcadero、10.3 以降) でコードを書くときの要点、FPC との違い、近似検証済みの例
version: 1.0.0
metadata:
  hermes:
    tags: [pascal, delphi, embarcadero]
    category: software-development
---

# Delphi (Embarcadero)

## When to Use
- Delphi のプロジェクト (`.dproj` があるディレクトリ、`.dpr` / `.dpk`) のソースを書く・直すとき

FPC の `{$mode delphi}` とは別物。FPC で書くときは pascal-fpc-delphi を使う。
この環境には Delphi がない。例は FPC (Unleashed の fpc、`{$mode delphiunicode}` 相当) で近似検証している。

## 必ず守ること
1. `{$mode ...}` は書かない (FPC のディレクティブ)。コンソールアプリは `{$APPTYPE CONSOLE}`。
2. ユニット名は名前空間付きで書く: `System.SysUtils`, `System.Classes`, `System.Generics.Collections`,
   `Vcl.Forms`, `FMX.Forms` など。FPC のユニット (`fgl`, `LazUTF8` など) は使えない。
3. ジェネリクスは `<T>` だけ。`generic` / `specialize` は書かない。制約は `<T: class, constructor>` の形。
   **グローバルなジェネリック関数は書けない** (FPC と違う)。クラスかレコードの `class function F<T>` にする。
4. メソッドポインタ・手続き型変数への代入に `@` を付けない。
5. `string` は UnicodeString (1 始まり)。文字列ヘルパー (`S.Length`, `S.ToUpper`, `S.StartsWith`) が使える。
6. 10.3 以降は inline var が使える: `var X := 1;`、`for var I := 1 to N do`。初期化は `:=`。
7. 無名メソッドは `reference to` 型に代入する。`System.SysUtils` の `TProc` / `TProc<T>` / `TFunc<T, TResult>` を使ってよい。
8. 生成したオブジェクトは `try ... finally X.Free; end;` で解放する (デスクトップの Delphi は ARC なし)。
9. 管理レコード (10.4 以降): `class operator Initialize(out Dest: TRec);` と
   `class operator Finalize(var Dest: TRec);`。Initialize は `out`、Finalize は `var` (FPC は両方 `var` なので注意)。
   この項目は近似検証できていない。

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

## 例 (FPC で近似検証済み: コンパイル・実行・出力比較)
このスキルのディレクトリの `examples/<ファイル>` から必要なものだけ読む
(Claude Code: スキルのベースディレクトリからの相対パスで Read。Hermes: `skill_view(name="pascal-delphi", file_path="examples/<ファイル>")`)。
01〜05 は他方言の例と同じお題。

| ファイル | 内容 |
|---|---|
| `examples/01_class_property.dpr` | クラス、プロパティ、setter での検査、try/finally |
| `examples/02_generics.dpr` | `<T>` のジェネリクス、`class, constructor` 制約、クラス内のジェネリックメソッド |
| `examples/03_exceptions.dpr` | 独自例外、CreateFmt、on E: 型 do |
| `examples/04_strings_lists.dpr` | TStringList、Format、文字列ヘルパー |
| `examples/05_events.dpr` | `of object` イベントと `@` なしの代入 |
| `examples/06_inline_vars.dpr` | inline var、型推論、for var、TArray、TDictionary |
| `examples/07_anonymous_methods.dpr` | `reference to`、無名メソッド、変数の捕捉 |

## 落とし穴 (FPC で失敗を確認。Delphi でもコンパイルエラーになる誤り)

| ファイル | 誤り |
|---|---|
| `pitfalls/p01_specialize_keyword.dpr` | `specialize TList<Integer>` (FPC objfpc の書き方) |
| `pitfalls/p02_generic_keyword.dpr` | `generic TBox<T> = ...` (FPC objfpc の書き方) |
| `pitfalls/p03_inline_var_with_equals.dpr` | inline var を `=` で初期化 |

## Verification
- この環境では本物の Delphi でコンパイルできない。書いたコードは Delphi の環境でビルドして確かめること。
- 例の近似検証は `tests/check-examples.sh pascal-delphi` (名前空間付きユニット名を FPC の名前に置き換えた写しを、
  Unleashed の fpc の `-Mdelphiunicode` + inline var・無名メソッドの modeswitch でコンパイルする)。
