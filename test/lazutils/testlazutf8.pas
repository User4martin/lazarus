{
 Test all with:
     ./runtests --format=plain --suite=TTestLazUTF8

 Test specific with:
     ./runtests --format=plain --suite=TestUTF8Trim
     ./runtests --format=plain --suite=TestUTF8Pos
}
unit TestLazUTF8;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testglobals, LazUTF8;

type

  { TTestLazUTF8 }

  TTestLazUTF8 = class(TTestCase)
  public
  published
    procedure TestUTF8Trim;
    procedure TestUTF8Pos;
  end;

implementation

{ TTestLazUTF8 }

procedure TTestLazUTF8.TestUTF8Trim;
begin
  AssertEquals('Empty string','',UTF8Trim(''));
  AssertEquals('Single space string','',UTF8Trim(' '));
  AssertEquals('Single char string','a',UTF8Trim('a'));
  AssertEquals('Space at start','a',UTF8Trim(' a'));
  AssertEquals('Space at end','a',UTF8Trim('a '));
  AssertEquals('Space at start and end','a',UTF8Trim(' a '));
  AssertEquals('Tabs','a',UTF8Trim(#9'a'#9));
  AssertEquals('Line breaks 1','a',UTF8Trim(#10'a'#13#10));
  AssertEquals('Line breaks 2','',UTF8Trim(#10#13#13));
  AssertEquals('Control characters 1','a',UTF8Trim(#0'a'#0));
  AssertEquals('left-to-right','a',UTF8Trim(#$E2#$80#$8E'a'));
  AssertEquals('right-to-left mark','a',UTF8Trim('a'#$E2#$80#$8F));
  AssertEquals('left-to-right, right-to-left mark','a',UTF8Trim(#$E2#$80#$8E'a'#$E2#$80#$8F));
end;

procedure TTestLazUTF8.TestUTF8Pos;
begin
  AssertEquals('Skip first occurence',4,UTF8Pos('ab','abcabc',2));
  AssertEquals('Not found',0,UTF8Pos('abc'#0,'abcabc'));
  AssertEquals('Check #0',2,UTF8Pos('bc'#0,'abc'#0'abc'));
end;

initialization
  AddToLazUtilsTestSuite(TTestLazUTF8);

end.

