program async_parallel;
{ unleashed: async/await と for parallel、共有状態は lock。Unix では cthreads を uses の先頭に }
{$mode unleashed}

uses
  {$ifdef UNIX}cthreads,{$endif} SysUtils;

function Fib(n: Integer): Int64;
begin
  Result := if n < 2 then n else Fib(n - 1) + Fib(n - 2);
end;

var
  hits: Integer;

begin
  var f := async Fib(25);          { 別スレッドで実行。値は await で読む }
  hits := 0;
  for parallel var i := 1 to 100 do
    if Fib(10) = 55 then
      lock(hits) do hits += 1;
  WriteLn($'fib(25)={await f} hits={hits}');
end.
