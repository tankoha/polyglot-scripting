program p03;
{ 誤り: delphi モードでメソッドポインタに @ を付ける。正しくは P := A.Handler
  expect-error: Variable identifier expected }
{$mode delphi}
type
  TProc = procedure of object;
  TA = class procedure Handler; end;
procedure TA.Handler; begin end;
var P: TProc; A: TA;
begin
  A := TA.Create;
  P := @A.Handler;
  A.Free;
end.
