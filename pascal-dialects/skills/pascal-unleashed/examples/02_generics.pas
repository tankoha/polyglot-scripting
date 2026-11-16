program generics_demo;
{ unleashed: implicitgenerics が既定。Delphi 式に <T> だけで書き、generic / specialize は書かない
  (objfpc ベースのモードだが、ここは objfpc と違う)。ジェネリック関数の型引数は推論されない }
{$mode unleashed}

uses
  SysUtils, Generics.Collections;

type
  TPair<TKey, TValue> = record
    Key: TKey;
    Value: TValue;
  end;

  TNamedInt = TPair<string, Integer>;
  TIntList = TList<Integer>;

function MaxOf<T>(const A, B: T): T;
begin
  Result := if A > B then A else B;
end;

begin
  var l := autofree TIntList.Create;
  l.Add(3);
  l.Add(5);
  l.Add(7);
  var sum := 0;
  for var i in l do
    sum += i;
  var p: TNamedInt;
  p.Key := 'sum';
  p.Value := sum;
  WriteLn($'{p.Key}={p.Value}');
  WriteLn($'max={MaxOf<Integer>(4, 9)}');
end.
