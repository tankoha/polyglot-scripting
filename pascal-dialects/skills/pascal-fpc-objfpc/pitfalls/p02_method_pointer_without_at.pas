program p02;
{ 誤り: objfpc でメソッドポインタに @ を付けずに代入する。正しくは P := @A.Handler
  expect-error: Incompatible types }
{$mode objfpc}{$H+}
type
  TProc = procedure of object;
  TA = class procedure Handler; end;
procedure TA.Handler; begin end;
var P: TProc; A: TA;
begin
  A := TA.Create;
  P := A.Handler;
  A.Free;
end.
