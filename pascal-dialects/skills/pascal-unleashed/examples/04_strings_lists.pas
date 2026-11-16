program strings_lists;
{ unleashed: 文字列補間。波括弧の中は普通の式なので文字列は '...' (二重にしない)。TStringList は autofree で }
{$mode unleashed}

uses
  SysUtils, Classes;

begin
  var sl := autofree TStringList.Create;
  sl.Delimiter := ',';
  sl.StrictDelimiter := True;
  sl.DelimitedText := 'banana,apple,cherry';
  sl.Sort;
  for var s in sl do
    WriteLn(Format('%-6s len=%d', [s, Length(s)]));
  WriteLn(sl.CommaText);
  WriteLn($'upper={UpperCase(sl[0])} starts={sl[1].StartsWith('ban')}');
end.
