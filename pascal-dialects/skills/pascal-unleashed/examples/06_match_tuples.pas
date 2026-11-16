program match_tuples;
{ unleashed: タプルの戻り値と分割代入、match 文と match 式 (式は _ / else / otherwise 必須) }
{$mode unleashed}

function MinMax(const a: array of Integer): (lo, hi: Integer);
begin
  Result := (a[0], a[0]);
  for var v in a do
  begin
    if v < Result.lo then Result.lo := v;
    if v > Result.hi then Result.hi := v;
  end;
end;

procedure Dispatch(const cmd: string);
begin
  match cmd of
    'go', 'run': WriteLn('running');
    'stop':      WriteLn('stopping');
    _:           WriteLn($'unknown: {cmd}');
  end;
end;

begin
  var (lo, hi) := MinMax([34, 7, 23, 62, 5]);
  WriteLn($'lo={lo} hi={hi}');
  var size := match
    hi > 50: 'big';
    hi > 10: 'medium';
    _:       'small';
  end;
  WriteLn($'size={size}');
  Dispatch('run');
  Dispatch('fly');
end.
