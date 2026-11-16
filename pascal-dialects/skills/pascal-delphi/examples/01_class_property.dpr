program ClassProperty;
{ Delphi: クラス、プロパティ、コンストラクタ/デストラクタ、try/finally での解放。
  string は UnicodeString。ユニット名は System.SysUtils のように名前空間付きで書く }
{$APPTYPE CONSOLE}

uses
  System.SysUtils;

type
  TCounter = class
  private
    FName: string;
    FCount: Integer;
    procedure SetCount(AValue: Integer);
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    procedure Increment;
    property Name: string read FName;
    property Count: Integer read FCount write SetCount;
  end;

constructor TCounter.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

destructor TCounter.Destroy;
begin
  Writeln('destroy ', FName);
  inherited;
end;

procedure TCounter.SetCount(AValue: Integer);
begin
  if AValue < 0 then
    raise EArgumentOutOfRangeException.Create('Count must be >= 0');
  FCount := AValue;
end;

procedure TCounter.Increment;
begin
  Inc(FCount);
end;

var
  C: TCounter;
begin
  C := TCounter.Create('clicks');
  try
    C.Increment;
    C.Increment;
    Writeln(C.Name, '=', C.Count);
  finally
    C.Free;
  end;
end.
