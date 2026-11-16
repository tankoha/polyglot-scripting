program P02;
{ 誤り: FPC objfpc の generic を書く。Delphi では TBox<T> = record ... end;
  expect-error: "=" expected but "identifier TBOX" found }
{$APPTYPE CONSOLE}
type
  generic TBox<T> = record V: T; end;
begin
end.
