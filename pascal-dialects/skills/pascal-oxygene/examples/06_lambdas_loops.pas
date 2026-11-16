namespace LambdasLoops;
{ 未検証 (コンパイラなし。公式ドキュメントの構文に基づく)。対象: .NET (Echoes)
  Oxygene: ラムダは 引数 -> 式 (引数が 2 つ以上なら括弧、なしなら () ->)。型は代入先から推論。
  無名メソッドは method(引数); begin ... end。for は step / downto / for each ... index / for parallel がある }

interface

type
  Program = class
  public
    class method Loop(aAction: block(aValue: Integer));
    class method Main(args: array of String): Int32;
  end;

implementation

class method Program.Loop(aAction: block(aValue: Integer));
begin
  for i: Integer := 1 to 3 do
    aAction(i);
end;

class method Program.Main(args: array of String): Int32;
begin
  Loop(a -> writeLn($'lambda {a}'));

  var total := 0;
  Loop(method(a: Integer); begin
    total := total + a;
  end);
  writeLn($'total={total}');

  for i := 0 to 10 step 5 do
    writeLn($'step {i}');
  for i := 3 downto 1 do
    writeLn($'down {i}');
end;

end.
