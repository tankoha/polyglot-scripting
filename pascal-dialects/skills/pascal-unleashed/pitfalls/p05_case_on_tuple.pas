program p05;
{ 誤り: タプルに case を使う。タプルは順序型でも文字列でもないので match を使う
  expect-error: Ordinal or string expression expected }
{$mode unleashed}
begin
  var t := (1, 2);
  case t of
    (1, 2): WriteLn('one-two');
  end;
end.
