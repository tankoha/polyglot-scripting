program defer_demo;
{ unleashed: defer はブロック末尾で LIFO 順に実行。引数は実行時点の値で評価される }
{$mode unleashed}

begin
  begin
    var step := 1;
    defer WriteLn($'cleanup A (step={step})');
    defer WriteLn('cleanup B');
    step := 2;
    WriteLn('work');
  end;
  WriteLn('after block');
end.
