# instantfpc (Free Pascal) スクリプト

性能重視の処理、低レイヤ操作、バイナリ/ファイル操作に使う。

## テンプレート

すべてのスクリプトはこの形から始める。

```pascal
#!/usr/bin/env instantfpc
{$mode objfpc}{$H+}
program ScriptName;

uses
  SysUtils;

begin
end.
```

- `{$mode objfpc}` — Object Pascal モード。`{$mode delphi}` に勝手に変えない。
- `{$H+}` — 文字列を `AnsiString` にする。これが無いと `ShortString`（255 文字上限）になり、
  長い行を扱った瞬間に黙って切れる。省略しないこと。
- `program` 名はファイル名と揃える必要はないが、揃えておくと診断が読みやすい。

## 実行とキャッシュ

```bash
chmod +x script.pas && ./script.pas    # shebang 経由
instantfpc script.pas                  # 明示実行
```

初回は fpc でコンパイルされ、以降はキャッシュされたバイナリが使われる。
つまり**起動コストは2回目以降ほぼゼロ**で、ここが bb との性能差の出どころになる。
逆に言えば、1回しか走らないスクリプトで instantfpc を選ぶ理由は薄い。

想定バージョンは instantfpc 1.3。ただし環境ごとに異なるので、セッション開始時に注入される
実測値を優先する。未検出と報告された環境では instantfpc 経路を提案しないこと。

## よく使う uses

| 目的 | unit |
|---|---|
| `IntToStr`, `Format`, `FileExists`, 例外 | `SysUtils` |
| `TStringList`, `TFileStream`, `TMemoryStream` | `Classes` |
| `ParamStr` / `ParamCount` | （組み込み。uses 不要） |

## 定型

引数と終了コード:

```pascal
if ParamCount < 1 then
begin
  WriteLn(StdErr, 'usage: ', ExtractFileName(ParamStr(0)), ' <path>');
  Halt(2);
end;
```

行単位のファイル読み（`Classes` が要る）:

```pascal
var
  Lines: TStringList;
  I: Integer;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(ParamStr(1));
    for I := 0 to Lines.Count - 1 do
      WriteLn(Lines[I]);
  finally
    Lines.Free;
  end;
end.
```

バイナリ:

```pascal
var
  Stream: TFileStream;
  Buf: array[0..4095] of Byte;
  N: LongInt;
begin
  Stream := TFileStream.Create(ParamStr(1), fmOpenRead or fmShareDenyNone);
  try
    repeat
      N := Stream.Read(Buf, SizeOf(Buf));
    until N = 0;
  finally
    Stream.Free;
  end;
end.
```

## 注意点

- `try..finally` で必ず解放する。スクリプトでも例外は飛ぶ。
- `Halt(n)` で終了コードを返す。`ExitCode := n` でも良いが、途中脱出には `Halt`。
- 文字列の添字は 1 始まり（`S[1]` が先頭）。0 始まりの配列と混ぜると事故る。
- `WriteLn(StdErr, ...)` でエラー出力。標準出力に混ぜない。
- 環境に `rawpaco` があれば、`.pas` を書いた時点で PostToolUse フックが静的解析をかけ、
  指摘を文脈に返す。返ってきたら直してから次に進むこと。
