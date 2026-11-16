namespace ExceptionsDemo;
{ 未検証 (コンパイラなし。公式ドキュメントの構文に基づく)。対象: .NET (Echoes)
  Oxygene: raise new 例外クラス(...)。except の中は on E: 型 do の並び (where で絞り込みも可)。
  再送出は raise; (raise E にすると呼び出し履歴が失われる) }

interface

type
  ValidationException = public class(Exception)
  public
    constructor(aMessage: String); empty;   { 同じ引数の基底コンストラクタが自動で呼ばれる }
  end;

  Program = class
  public
    class method CheckAge(age: Integer);
    class method Try1(age: Integer);
    class method Main(args: array of String): Int32;
  end;

implementation

class method Program.CheckAge(age: Integer);
begin
  if (age < 0) or (age > 150) then
    raise new ValidationException($'invalid age: {age}');
end;

class method Program.Try1(age: Integer);
begin
  try
    CheckAge(age);
    writeLn($'ok {age}');
  except
    on E: ValidationException do
      writeLn($'validation: {E.Message}');
    on E: Exception do
      writeLn($'other: {E.GetType.Name}');
  end;
end;

class method Program.Main(args: array of String): Int32;
begin
  Try1(30);
  Try1(-1);
end;

end.
