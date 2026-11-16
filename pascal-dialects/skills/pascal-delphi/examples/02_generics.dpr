program GenericsDemo;
{ Delphi: ジェネリクスは <T> だけで書く。制約は <T: class, constructor> の形。
  ジェネリックなメソッドはクラスかレコードの中に置く (Delphi はグローバルなジェネリック関数を持てない) }
{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Generics.Collections;

type
  TPair<TKey, TValue> = record
    Key: TKey;
    Value: TValue;
  end;

  TWidget = class
  end;

  TFactory<T: class, constructor> = class
  public
    function Make: T;
  end;

  TMath = class
  public
    class function MaxOf<T>(const A, B: T; const IsGreater: Boolean): T; static;
  end;

function TFactory<T>.Make: T;
begin
  Result := T.Create;
end;

class function TMath.MaxOf<T>(const A, B: T; const IsGreater: Boolean): T;
begin
  if IsGreater then
    Result := A
  else
    Result := B;
end;

var
  L: TList<Integer>;
  P: TPair<string, Integer>;
  F: TFactory<TWidget>;
  W: TWidget;
  I, Sum: Integer;
begin
  L := TList<Integer>.Create;
  F := TFactory<TWidget>.Create;
  try
    L.AddRange([3, 5, 7]);
    Sum := 0;
    for I in L do
      Sum := Sum + I;
    P.Key := 'sum';
    P.Value := Sum;
    Writeln(P.Key, '=', P.Value);
    Writeln('max=', TMath.MaxOf<Integer>(9, 4, 9 > 4));
    W := F.Make;
    try
      Writeln('made ', W.ClassName);
    finally
      W.Free;
    end;
  finally
    F.Free;
    L.Free;
  end;
end.
