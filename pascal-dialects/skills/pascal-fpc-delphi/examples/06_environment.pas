program environment;
{ FPC delphi モード: 環境変数の読み方。GetEnvironmentVariable は起動時に受け取った環境の写しを読むので、
  あとから libc の setenv で変えた値は見えない (RTL は objfpc と同じ)。
  テストで環境変数を差し替えようとせず、環境は main で一度だけ読み、値を引数で渡す }
{$mode delphi}
{$linklib c}

uses
  SysUtils;

type
  TConfig = record
    Compiler: string;
    Home: string;
  end;

{ libc の関数。罠を見せるためだけに使う }
function setenv(AName, AValue: PChar; AOverwrite: LongInt): LongInt; cdecl; external 'c';
function getenv(AName: PChar): PChar; cdecl; external 'c';

{ 環境を読まない純粋な関数: 空文字は「未設定」として既定値を入れる。テストは値を渡すだけ }
function MakeConfig(const ACompiler, AHome: string): TConfig;
begin
  if ACompiler <> '' then
    Result.Compiler := ACompiler
  else
    Result.Compiler := 'fpc';
  Result.Home := AHome;
end;

var
  C: TConfig;
begin
  { 罠: setenv の値は GetEnvironmentVariable には見えず、libc の getenv には見える }
  setenv('PASCAL_DIALECTS_ENV_DEMO', 'set-later', 1);
  WriteLn('GetEnvironmentVariable: [', GetEnvironmentVariable('PASCAL_DIALECTS_ENV_DEMO'), ']');
  WriteLn('libc getenv:            [', StrPas(getenv('PASCAL_DIALECTS_ENV_DEMO')), ']');

  { 正しい形: 環境はここで一度だけ読み、以降は値で渡す }
  C := MakeConfig(GetEnvironmentVariable('PASCAL_DIALECTS_ENV_DEMO_FPC'), '/home/demo');
  WriteLn('compiler=', C.Compiler, ' home=', C.Home);
  C := MakeConfig('/opt/fpc/bin/fpc', '/home/demo');
  WriteLn('compiler=', C.Compiler, ' home=', C.Home);
end.
