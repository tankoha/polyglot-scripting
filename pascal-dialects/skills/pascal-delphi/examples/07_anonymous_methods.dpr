program AnonymousMethods;
{ Delphi: 無名メソッドは reference to の型に代入し、外側の変数を捕捉できる。
  System.SysUtils の TProc<T> / TFunc<T, TResult> も同じ reference to 型なので、自前で宣言せずに使ってよい }
{$APPTYPE CONSOLE}

uses
  System.SysUtils;

type
  TIntOp = reference to function(A: Integer): Integer;
  TIntAction = reference to procedure(I: Integer);

function MakeAdder(N: Integer): TIntOp;
begin
  Result :=
    function(A: Integer): Integer
    begin
      Result := A + N;
    end;
end;

procedure Repeat3(const Action: TIntAction);
var
  I: Integer;
begin
  for I := 1 to 3 do
    Action(I);
end;

var
  Add10: TIntOp;
  Square: TIntOp;
  Sum: Integer;
begin
  Add10 := MakeAdder(10);
  Writeln('add10=', Add10(5));
  Square :=
    function(X: Integer): Integer
    begin
      Result := X * X;
    end;
  Writeln('square=', Square(7));
  Sum := 0;
  Repeat3(
    procedure(I: Integer)
    begin
      Sum := Sum + I;
    end);
  Writeln('sum=', Sum);
end.
