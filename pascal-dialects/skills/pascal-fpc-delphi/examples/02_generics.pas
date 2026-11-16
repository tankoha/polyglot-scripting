program generics_demo;
{ delphi モード: generic / specialize キーワードは書かない。山括弧だけで宣言・利用する }
{$mode delphi}

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
    WriteLn('max=', MaxOf<Integer>(4, 9));
  finally
    L.Free;
  end;
end.
