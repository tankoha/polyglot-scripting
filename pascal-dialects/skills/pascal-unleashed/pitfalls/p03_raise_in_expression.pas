program p03;
{ 誤り: 式の分岐に raise を書く。分岐は値を返す式 1 つだけ。値を返さないなら文の case を使う
  expect-error: Illegal expression }
{$mode unleashed}
uses SysUtils;
var n: Integer;
begin
  n := 3;
  var s := case n of
    1: 'one';
    2: 'two';
  else
    raise Exception.Create('bad n')
  end;
  WriteLn(s);
end.
