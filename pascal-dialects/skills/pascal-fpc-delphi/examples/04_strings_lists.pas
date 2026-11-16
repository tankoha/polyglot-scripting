program strings_lists;
{ delphi モード: string は既定で AnsiString ({$H+} 不要)。TStringList、Format、文字列ヘルパー }
{$mode delphi}

uses
  SysUtils, Classes;

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
      WriteLn(Format('%-6s len=%d', [S, Length(S)]));
    WriteLn(SL.CommaText);
    WriteLn('upper=', UpperCase(SL[0]), ' starts=', BoolToStr(SL[1].StartsWith('ban'), True));
  finally
    SL.Free;
  end;
end.
