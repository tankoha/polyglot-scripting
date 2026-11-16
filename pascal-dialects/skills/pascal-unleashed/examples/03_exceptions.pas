program exceptions_demo;
{ unleashed: 文の try/except は従来どおり。値が欲しいときは try 式 (on を使うなら else 必須) }
{$mode unleashed}

uses
  SysUtils;

type
  EValidation = class(Exception);

procedure CheckAge(Age: Integer);
begin
  if (Age < 0) or (Age > 150) then
    raise EValidation.CreateFmt('invalid age: %d', [Age]);
end;

procedure Try1(Age: Integer);
begin
  try
    CheckAge(Age);
    WriteLn($'ok {Age}');
  except
    on E: EValidation do
      WriteLn($'validation: {E.Message}');
  end;
end;

begin
  Try1(30);
  Try1(-1);
  var n := try StrToInt('12x') except on E: EConvertError do -1 else -2 end;
  WriteLn($'parsed={n}');
end.
