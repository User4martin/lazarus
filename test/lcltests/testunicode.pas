unit TestUnicode;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, LCLProc, testglobals;

type

  { TTestUnicode }

  TTestUnicode= class(TTestCase)
  published
    procedure TestUTF8ToUTF16;
    procedure TestUTF16ToUTF8;
    procedure TestUTF16ToUnicode;
    procedure TestUnicodeToUTF16;
  end; 
  
const
  Limits: Array [0..8] of Cardinal =
    (0, $7F, $80, $7FF, $800, $10000, $10FFFF, $1FFFFF, $D7FF);

implementation

{ TTestUnicode }

procedure TTestUnicode.TestUTF8ToUTF16;
var
  U: Cardinal;
  I1, I2: Integer;
  SUTF8, S1UTF8: UTF8String;
  SUTF16, S1UTF16, R: WideString;
begin
  for U := 0 to $1FFFFF do // test each unicode char
  begin
    if (U >= $D800) and (U <= $FFFF) then Continue;
    
    SUTF8 := UnicodeToUTF8(U);
    SUTF16 := UnicodeToUTF16(U);
    R := UTF8ToUTF16(SUTF8);

    AssertEquals('UTF8ToUTF16 of unicode char: ' + IntToHex(U, 6) + ' error! ' + DbgWideStr(SUTF16) + ' ' + DbgWideStr(R),
      SUTF16, R);
  end;
  
  for I1 := 0 to High(Limits) do // test two char string with limit char values
  begin
    S1UTF8 := UnicodeToUTF8(Limits[I1]);
    S1UTF16 := UnicodeToUTF16(Limits[I1]);
    
    for I2 := 0 to High(Limits) do
    begin
      SUTF8 := S1UTF8 + UnicodeToUTF8(Limits[I2]);
      SUTF16 := S1UTF16 + UnicodeToUTF16(Limits[I2]);
      R := UTF8ToUTF16(SUTF8);
      
      AssertEquals('UTF8ToUTF16 of two unicode chars: ' +
        IntToHex(Limits[I1], 6) + IntToHex(Limits[I2], 6) + ' error!',
        SUTF16, R);
    end;
  end;
end;

procedure TTestUnicode.TestUTF16ToUTF8;
var
  U: Cardinal;
  I1, I2: Integer;
  SUTF8, S1UTF8, R: UTF8String;
  SUTF16, S1UTF16: WideString;
begin
  for U := 0 to $1FFFFF do
  begin
    if (U >= $D800) and (U <= $FFFF) then Continue;
    
    SUTF8 := UnicodeToUTF8(U);
    SUTF16 := UnicodeToUTF16(U);
    R := UTF16ToUTF8(SUTF16);

    AssertEquals('UTF16ToUTF8 of unicode char: ' + IntToHex(U, 6) + ' error! ' + DbgStr(SUTF16) + ' ' + DbgStr(R),
      SUTF8, R);
  end;
  
  for I1 := 0 to High(Limits) do
  begin
    S1UTF8 := UnicodeToUTF8(Limits[I1]);
    S1UTF16 := UnicodeToUTF16(Limits[I1]);

    for I2 := 0 to High(Limits) do
    begin
      SUTF8 := S1UTF8 + UnicodeToUTF8(Limits[I2]);
      SUTF16 := S1UTF16 + UnicodeToUTF16(Limits[I2]);
      R := UTF16ToUTF8(SUTF16);

      AssertEquals('UTF16ToUTF8 of two unicode chars: ' +
        IntToHex(Limits[I1], 6) + IntToHex(Limits[I2], 6) + ' error!',
        SUTF8, R);
    end;
  end;
end;

procedure TTestUnicode.TestUTF16ToUnicode;
var
  L: Integer;
begin
  AssertEquals(0, UTF16CharacterToUnicode(#0, L));
  AssertEquals($D7FF, UTF16CharacterToUnicode(#$D7FF, L));
  AssertEquals($10000, UTF16CharacterToUnicode(#$D800#$DC00, L));
  AssertEquals($10001, UTF16CharacterToUnicode(#$D800#$DC01, L));
  AssertEquals($10FFFD, UTF16CharacterToUnicode(#$DBFF#$DFFD, L));
end;

procedure TTestUnicode.TestUnicodeToUTF16;
begin
  AssertEquals(#0, UnicodeToUTF16(0));
  AssertEquals(#$D7FF, UnicodeToUTF16($D7FF));
  AssertEquals(#$D800#$DC00, UnicodeToUTF16($10000));
  AssertEquals(#$D800#$DC01, UnicodeToUTF16($10001));
  AssertEquals(#$DBFF#$DFFD, UnicodeToUTF16($10FFFD));
end;

initialization

  AddToLCLTestSuite(TTestUnicode);
end.

