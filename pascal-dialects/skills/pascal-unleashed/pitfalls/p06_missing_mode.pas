program p06;
{ 誤り: {$mode unleashed} を書き忘れる (objfpc のまま Unleashed の構文を使う)
  expect-error: Parser - Syntax Error }
{$mode objfpc}{$H+}
begin
  var x := 1;
  WriteLn(x);
end.
