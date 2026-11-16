program p02;
{ 誤り: inline var の初期化に = を使う。begin..end の中の inline var は := (var 節では =)
  expect-error: ";" expected but "=" found }
{$mode unleashed}
begin
  var x: Integer = 1;
  WriteLn(x);
end.
