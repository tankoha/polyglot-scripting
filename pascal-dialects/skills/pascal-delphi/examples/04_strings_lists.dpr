program StringsLists;
{ Delphi: string は UnicodeString (1 始まり)。TStringList、Format、文字列ヘルパー }
{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes;

var
  SL: TStringList;
  S: string;
begin
  SL := TStringList.Create;
  try
    SL.Delimiter := ',';
    SL.StrictDelimiter := True;
    SL.DelimitedText := 'banana,apple,cherry';
    SL.Sort;
    for S in SL do
      Writeln(Format('%-6s len=%d', [S, S.Length]));
    Writeln(SL.CommaText);
    Writeln('upper=', SL[0].ToUpper, ' starts=', BoolToStr(SL[1].StartsWith('ban'), True));
  finally
    SL.Free;
  end;
end.
