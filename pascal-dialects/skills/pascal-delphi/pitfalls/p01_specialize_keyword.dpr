program P01;
{ 誤り: FPC objfpc の specialize を書く。Delphi では TList<Integer> と書く
  expect-error: Identifier not found "specialize" }
{$APPTYPE CONSOLE}
uses
  System.Generics.Collections;
type
  TIntList = specialize TList<Integer>;
begin
end.
