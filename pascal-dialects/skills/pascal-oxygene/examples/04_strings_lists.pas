namespace StringsLists;
{ 未検証 (コンパイラなし。公式ドキュメントの構文に基づく)。対象: .NET (Echoes)
  Oxygene: String はプラットフォームの文字列 (.NET なら System.String)。不変で 0 始まり。
  nil と '' は別物。文字列リテラルは '...' でも "..." でもよい。補間は $'...{式}...' }

interface

uses
  System.Collections.Generic;

type
  Program = class
  public
    class method Main(args: array of String): Int32;
  end;

implementation

class method Program.Main(args: array of String): Int32;
begin
  var fruits := new List<String>;
  fruits.Add('banana');
  fruits.Add('apple');
  fruits.Add("cherry");
  fruits.Sort;
  for each s in fruits index i do
    writeLn($'{i}: {s} len={s.Length}');
  writeLn(String.Join(',', fruits));
  var first := fruits[0];
  writeLn($'upper={first.ToUpper} first char={first[0]}');   { 0 始まり }
end;

end.
