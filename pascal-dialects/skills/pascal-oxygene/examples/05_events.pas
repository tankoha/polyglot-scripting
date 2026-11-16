namespace EventsDemo;
{ 未検証 (コンパイラなし。公式ドキュメントの構文に基づく)。対象: .NET (Echoes)
  Oxygene: event 名前: block(引数); で宣言し、購読は += @メソッド、解除は -= @メソッド。
  ラムダ (引数) -> 式 も購読できる。未購読のまま呼ぶと例外なので assigned() で確かめてから呼ぶ }

interface

type
  Button = public class
  public
    event Clicked: block(aMessage: String);
    method Click;
  end;

  Form = public class
  public
    method HandleClick(aMessage: String);
  end;

  Program = class
  public
    class method Main(args: array of String): Int32;
  end;

implementation

method Button.Click;
begin
  if assigned(Clicked) then
    Clicked('clicked');
end;

method Form.HandleClick(aMessage: String);
begin
  writeLn($'form got: {aMessage}');
end;

class method Program.Main(args: array of String): Int32;
begin
  var btn := new Button;
  var frm := new Form;
  btn.Clicked += @frm.HandleClick;
  btn.Clicked += (msg) -> writeLn($'lambda got: {msg}');
  btn.Click;
  btn.Clicked -= @frm.HandleClick;
end;

end.
