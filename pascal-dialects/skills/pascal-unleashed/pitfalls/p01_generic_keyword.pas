program p01;
{ 誤り: unleashed で objfpc 式の generic / specialize を書く (implicitgenerics が既定)。正しくは TBox<T>
  expect-error: "=" expected but "identifier TBOX" found }
{$mode unleashed}
type
  generic TBox<T> = record V: T; end;
begin
end.
