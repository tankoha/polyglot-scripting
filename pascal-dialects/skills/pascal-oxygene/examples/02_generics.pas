namespace GenericsDemo;
{ 未検証 (コンパイラなし。公式ドキュメントの構文に基づく)。対象: .NET (Echoes)
  Oxygene: ジェネリクスは <T> だけ (generic / specialize は書かない)。生成は new List<Integer>。
  ジェネリックメソッドの制約は Delphi 式ではなく where (例: where T is IComparable) }

interface

uses
  System.Collections.Generic;

type
  ArrayHelpers = public class
  public
    class method FindIndex<T>(list: array of T; item: T): Integer;
  end;

  Program = class
  public
    class method Main(args: array of String): Int32;
  end;

implementation

class method ArrayHelpers.FindIndex<T>(list: array of T; item: T): Integer;
begin
  for i: Integer := 0 to list.Length - 1 do
    if list[i] = item then
      exit i;
  exit -1;
end;

class method Program.Main(args: array of String): Int32;
begin
  var numbers := new List<Integer>;
  numbers.Add(3);
  numbers.Add(5);
  numbers.Add(7);
  var sum := 0;
  for each n in numbers do
    sum := sum + n;
  writeLn($'sum={sum}');

  var ages := new Dictionary<String, Integer>;
  ages['ann'] := 30;
  var annAge := ages['ann'];
  writeLn($'ann={annAge}');

  var letters: array of String := ['a', 'b', 'c'];
  var idx := ArrayHelpers.FindIndex<String>(letters, 'b');
  writeLn($'index={idx}');
end;

end.
