program p03;
{ 誤り: 標準 FPC 3.2 に inline var はない (Delphi 10.3 や Unleashed の構文)。var 節で宣言する
  expect-error: Illegal expression }
{$mode objfpc}{$H+}
begin
  var x := 1;
  WriteLn(x);
end.
