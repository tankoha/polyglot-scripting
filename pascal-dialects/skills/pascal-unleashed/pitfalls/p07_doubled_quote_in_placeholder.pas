program p07;
{ 誤り: 補間の波括弧の中で文字列の引用符を二重にする。中は普通の式なので 'abc' と書く
  expect-error: ")" expected but "identifier ABC" found }
{$mode unleashed}
uses SysUtils;
begin
  WriteLn($'upper={UpperCase(''abc'')}');
end.
