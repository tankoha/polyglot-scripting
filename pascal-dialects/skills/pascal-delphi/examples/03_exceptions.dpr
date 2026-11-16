program ExceptionsDemo;
{ Delphi: 独自例外、raise、try/except の on E: 型 do }
{$APPTYPE CONSOLE}

uses
  System.SysUtils;

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
    Writeln('ok ', Age);
  except
    on E: EValidation do
      Writeln('validation: ', E.Message);
    on E: Exception do
      Writeln('other: ', E.ClassName);
  end;
end;

begin
  Try1(30);
  Try1(-1);
end.
