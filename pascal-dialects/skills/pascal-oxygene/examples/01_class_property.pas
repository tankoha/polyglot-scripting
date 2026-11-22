namespace ClassProperty;
{ Elements 14.0.0.3157 (EBuild、.NET Core) で検証済み。対象: .NET (Echoes)
  Oxygene: unit ではなく namespace。メソッドは method、コンストラクタは名前なしの constructor、
  生成は new。GC なので destructor と Free はない }

interface

type
  Counter = public class
  private
    fName: String;
  public
    constructor(aName: String);
    method Increment;
    property Name: String read fName;
    property Count: Integer;              { 自動プロパティ (裏のフィールドを自動生成) }
  end;

  Program = class
  public
    class method Main(args: array of String): Int32;
  end;

implementation

constructor Counter(aName: String);
begin
  fName := aName;
end;

method Counter.Increment;
begin
  Count := Count + 1;
end;

class method Program.Main(args: array of String): Int32;
begin
  var c := new Counter('clicks');
  c.Increment;
  c.Increment;
  writeLn($'{c.Name}={c.Count}');
end;

end.
