program P03;
{ 誤り: inline var を = で初期化する。begin の中の inline var は := (var 節の初期化は =)
  expect-error: ";" expected but "=" found }
{$APPTYPE CONSOLE}
begin
  var X: Integer = 1;
  Writeln(X);
end.
