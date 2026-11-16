program InlineVars;
{ Delphi 10.3 以降: begin の中の inline var と型推論。初期化は :=。for var でループ変数も宣言できる }
{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Generics.Collections;

begin
  var Total := 0;
  var Names: TArray<string> := ['ann', 'bob', 'cy'];
  for var N in Names do
    Total := Total + N.Length;
  Writeln('total=', Total);
  for var I := 1 to 3 do
  begin
    var Square := I * I;
    Write(Square, ' ');
  end;
  Writeln;
  var Map := TDictionary<string, Integer>.Create;
  try
    Map.Add('x', 10);
    Writeln('x=', Map['x']);
  finally
    Map.Free;
  end;
end.
