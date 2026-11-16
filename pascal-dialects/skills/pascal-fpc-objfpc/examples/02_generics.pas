program generics_demo;
{ objfpc: ジェネリクスの宣言は generic、利用は specialize が必須 }
{$mode objfpc}{$H+}

uses
  SysUtils, Generics.Collections;

type
  generic TPair<TKey, TValue> = record
    Key: TKey;
    Value: TValue;
  end;

  TNamedInt = specialize TPair<string, Integer>;
  TIntList = specialize TList<Integer>;

generic function MaxOf<T>(const A, B: T): T;
begin
  if A > B then
    Result := A
  else
    Result := B;
end;

var
  L: TIntList;
  P: TNamedInt;
  I, Sum: Integer;
begin
  L := TIntList.Create;
  try
    L.Add(3);
    L.Add(5);
    L.Add(7);
    Sum := 0;
    for I in L do
      Sum := Sum + I;
    P.Key := 'sum';
    P.Value := Sum;
    WriteLn(P.Key, '=', P.Value);
    WriteLn('max=', specialize MaxOf<Integer>(4, 9));
  finally
    L.Free;
  end;
end.
