program p01;
{ 誤り: delphi モードで generic キーワードを書く。正しくは TBox<T> = record ... end;
  expect-error: "=" expected but "identifier TBOX" found }
{$mode delphi}
type
  generic TBox<T> = record V: T; end;
begin
end.
