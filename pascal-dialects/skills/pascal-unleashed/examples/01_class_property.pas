program class_property;
{ unleashed: 自動プロパティ、autofree (try/finally 不要)、inline var、文字列補間 }
{$mode unleashed}

uses
  SysUtils;

type
  TCounter = class
  public
    property Name: string; readonly;   { 裏の Fname を自動生成。readonly で書き込み不可 }
    property Count: Integer;           { read FCount write FCount を自動生成 }
    constructor Create(const AName: string);
    destructor Destroy; override;
    procedure Increment;
  end;

constructor TCounter.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

destructor TCounter.Destroy;
begin
  WriteLn($'destroy {FName}');
  inherited Destroy;
end;

procedure TCounter.Increment;
begin
  FCount += 1;
end;

begin
  begin
    var c := autofree TCounter.Create('clicks');   { ブロックを抜けるときに解放 }
    c.Increment;
    c.Increment;
    WriteLn($'{c.Name}={c.Count}');
  end;
end.
