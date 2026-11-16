program p01;
{ 誤り: objfpc でジェネリクスを specialize なしで使う。正しくは specialize TList<Integer>
  expect-error: Generics without specialization }
{$mode objfpc}{$H+}
uses Generics.Collections;
var L: TList<Integer>;
begin
end.
