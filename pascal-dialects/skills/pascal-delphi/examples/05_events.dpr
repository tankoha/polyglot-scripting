program EventsDemo;
{ Delphi: メソッドポインタ・手続き型変数への代入に @ を付けない }
{$APPTYPE CONSOLE}

uses
  System.SysUtils;

type
  TNotify = procedure(Sender: TObject; const Msg: string) of object;
  TCalc = function(A, B: Integer): Integer;

  TButton = class
  public
    OnClick: TNotify;
    procedure Click;
  end;

  TForm = class
  public
    procedure HandleClick(Sender: TObject; const Msg: string);
  end;

procedure TButton.Click;
begin
  if Assigned(OnClick) then
    OnClick(Self, 'clicked');
end;

procedure TForm.HandleClick(Sender: TObject; const Msg: string);
begin
  Writeln('form got: ', Msg, ' from ', Sender.ClassName);
end;

function Add(A, B: Integer): Integer;
begin
  Result := A + B;
end;

var
  Btn: TButton;
  Frm: TForm;
  Calc: TCalc;
begin
  Btn := TButton.Create;
  Frm := TForm.Create;
  try
    Btn.OnClick := Frm.HandleClick;
    Btn.Click;
    Calc := Add;
    Writeln('calc=', Calc(2, 3));
  finally
    Frm.Free;
    Btn.Free;
  end;
end.
