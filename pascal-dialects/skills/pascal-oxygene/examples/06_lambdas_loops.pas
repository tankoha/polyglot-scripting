namespace LambdasLoops;
{ Elements 14.0.0.3157 (EBuild、.NET Core) で検証済み。対象: .NET (Echoes)
  Oxygene: ラムダは 引数 -> 式 (引数が 2 つ以上なら括弧、なしなら () ->)。型は代入先から推論。
  無名メソッドは method(引数); begin ... end。for は step / downto / for each ... index / for parallel がある }

interface

type
  Program = class
  public
    class method RunThree(aAction: block(aValue: Integer));
    class method Main(args: array of String): Int32;
  end;

implementation

class method Program.RunThree(aAction: block(aValue: Integer));
begin
  for i: Integer := 1 to 3 do
    aAction(i);
end;

class method Program.Main(args: array of String): Int32;
begin
  RunThree(a -> writeLn($'lambda {a}'));

  var total := 0;
  RunThree(method(a: Integer); begin
    total := total + a;
  end);
  writeLn($'total={total}');

  for i := 0 to 10 step 5 do
    writeLn($'step {i}');
  for i := 3 downto 1 do
    writeLn($'down {i}');
end;

end.
