program p02;
{ 誤り: delphi モードで specialize を書く。正しくは TIntList = TList<Integer>;
  expect-error: Identifier not found "specialize" }
{$mode delphi}
uses Generics.Collections;
type
  TIntList = specialize TList<Integer>;
begin
end.
