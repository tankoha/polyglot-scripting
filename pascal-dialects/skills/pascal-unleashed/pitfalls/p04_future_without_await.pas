program p04;
{ 誤り: async の結果 (future) を await せずに使う。正しくは await f
  expect-error: future value used without `await` }
{$mode unleashed}
uses {$ifdef UNIX}cthreads,{$endif} SysUtils;
function Twice(n: Integer): Integer;
begin
  Result := n * 2;
end;
begin
  var f := async Twice(21);
  WriteLn('f = ', f);
end.
