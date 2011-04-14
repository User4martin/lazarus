unit TestBase;

{$mode objfpc}{$H+}
{ $DEFINE WITH_APPMSG}

interface

uses
  Classes, SysUtils, Forms, fpcunit, SynEdit, LCLType, LCLProc, math,
  SynEditTypes, SynEditPointClasses, Clipbrd;

type

  TStringArray = array of string;

  { TTestSynEdit }

  TTestSynEdit = class(TSynEdit)
  public
    procedure TestKeyPress(Key: Word; Shift: TShiftState);
    function  TestFullText: String;
    procedure TestSetSelText(Value: String; PasteMode: TSynSelectionMode = smNormal);
    procedure SimulatePaintText;
    property ViewedTextBuffer;
    property TextBuffer;
    property TextView; // foldedview
    property CaretObj: TSynEditCaret read GetCaretObj;
  end;

  { TTestBase }

  TTestBase = class(TTestCase)
  private
    FBaseTestName: String;
    FBaseTestNames: Array of String;
    FFixedBaseTestNames: Integer;
    FForm : TForm;
    function GetClipBoardText: String;
    procedure SetBaseTestName(const AValue: String);
    procedure SetClipBoardText(const AValue: String);
  protected
    FSynEdit : TTestSynEdit;
    function  LinesToText(Lines: Array of String; Separator: String = LineEnding;
                          SeparatorAtEnd: Boolean = False): String;
    (* Relpl,must be an alteration of LineNum, LineText+
      [ 3, 'a' ] => replace line 3 with 'a' (old line 3 is deleted)
      [ 3, 'a', 'b' ] => replace line 3 with 2 new lines 'a', 'b' (only one old line is deleted)
      [ 3 ] => replace line 3 with nothing => delete line 3
      [ -3, 'a' ] => insert a line 'a', at line 3 (current line 3 becomes line 4)
    *)
    function  LinesReplace(Lines: Array of String; Repl: Array of const): TStringArray;
    function  LinesReplaceText(Lines: Array of String; Repl: Array of const): String;
  protected
    procedure ReCreateEdit;
    procedure SetLines(Lines: Array of String);
    (* Setting selection, with one X/Y pair having negative values, will set caret to other X/Y pair and clear selection *)
    // Locical Caret
    procedure SetCaret(X, Y: Integer);
    procedure SetCaretAndSel(X1, Y1, X2, Y2: Integer; DoLock: Boolean = False;
      AMode: TSynSelectionMode = smCurrent);
    procedure SetCaretAndSelBackward(X1, Y1, X2, Y2: Integer; DoLock: Boolean = False;
      AMode: TSynSelectionMode = smCurrent);
    // Physical Caret
    procedure SetCaretPhys(X, Y: Integer);
    procedure SetCaretAndSelPhys(X1, Y1, X2, Y2: Integer; DoLock: Boolean = False;
      AMode: TSynSelectionMode = smCurrent);
    procedure SetCaretAndSelPhysBackward(X1, Y1, X2, Y2: Integer;
      DoLock: Boolean = False; AMode: TSynSelectionMode = smCurrent);
    procedure DoKeyPress(Key: Word; Shift: TShiftState = []);
    procedure DoKeyPressAtPos(X, Y: Integer; Key: Word; Shift: TShiftState = []);

    procedure TestFail(Name, Func, Expect, Got: String; Result: Boolean = False);
    procedure PushBaseName(Add: String);
    procedure PopPushBaseName(Add: String);
    procedure PopBaseName;
    property  BaseTestName: String read FBaseTestName write SetBaseTestName;
    procedure IncFixedBaseTestNames;
    procedure DecFixedBaseTestNames;
    property  SynEdit: TTestSynEdit read FSynEdit;
    property  Form: TForm read FForm;
    procedure ClearClipBoard;
    property  ClipBoardText: String read GetClipBoardText write SetClipBoardText;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  public
    procedure TestIsCaret(Name: String; X, Y: Integer); // logical caret
    procedure TestIsCaretPhys(Name: String; X, Y: Integer);
    procedure TestIsCaretAndSel(Name: String; LogX1, LogY1, LogX2, LogY2: Integer); // logical caret
    procedure TestIsCaretAndSelBackward(Name: String; LogX1, LogY1, LogX2, LogY2: Integer); // logical caret

    procedure TestCompareString(Name, Expect, Value: String; DbgInfo: String = '');
    procedure TestCompareString(Name: String; Expect, Value: Array of String; DbgInfo: String = '');
    procedure TestCompareString(Name, Expect: String; Value: Array of String; DbgInfo: String = '');
    procedure TestCompareString(Name: String; Expect: Array of String; Value: String; DbgInfo: String = '');
    // exclude trimspaces, as seen by other objects
    procedure TestIsText(Name, Text: String; FullText: Boolean = False);
    procedure TestIsText(Name: String; Lines: Array of String);
    procedure TestIsText(Name: String; Lines: Array of String; Repl: Array of const);
    // include trim-spaces
    procedure TestIsFullText(Name, Text: String);
    procedure TestIsFullText(Name: String; Lines: Array of String);
    procedure TestIsFullText(Name: String; Lines: Array of String; Repl: Array of const);

  end;

  function MyDbg(t: String): String;

implementation

function MyDbg(t: String): String;
begin
  Result := '';
  while(pos(LineEnding, t) > 0) do begin
    Result := Result +  '"' + copy(t, 1, pos(LineEnding, t)-1) + '"   Len='+IntTostr(pos(LineEnding, t)-1) + DbgStr(copy(t, 1, pos(LineEnding, t)-1)) + LineEnding;
    system.Delete(t, 1, pos(LineEnding, t)-1+length(LineEnding));
  end;
  Result := Result + '"' + t + '"   Len='+IntTostr(length(t)) + DbgStr(t);
end;

{ TTestSynEdit }

procedure TTestSynEdit.TestKeyPress(Key: Word; Shift: TShiftState);
var
  c: TUTF8Char;
begin
  KeyDown(Key, Shift);
  c := '';
  if Shift = [] then
    case Key of
      VK_A..VK_Z:  c := chr(Key - VK_A + ord('a'));
      VK_0..VK_9:  c := chr(Key - VK_0 + ord('0'));
      VK_RETURN:   c := #13;
      VK_TAB:      c := #9;
      VK_ESCAPE:   c := #27;
    end
  else
  if Shift = [ssShift] then
    case Key of
      VK_A..VK_Z:  c := chr(Key - VK_A + ord('A'));
    end
  else
  if Shift - [ssShift] = [ssCtrl] then
    case Key of
      VK_A..VK_Z:  c := chr(Key - VK_A + 1);
    end;
  if c <> '' then
    UTF8KeyPress(c);
  KeyUp(Key, Shift);
  {$IFDEF WITH_APPMSG}Application.ProcessMessages;{$ENDIF}
end;

function TTestSynEdit.TestFullText: String;
begin
  Result := ViewedTextBuffer.Text;
end;

procedure TTestSynEdit.TestSetSelText(Value: String; PasteMode: TSynSelectionMode);
begin
  BeginUndoBlock;
  SetSelTextPrimitive(PasteMode, PChar(Value), True);
  EndUndoBlock;
end;

procedure TTestSynEdit.SimulatePaintText;
begin
  PaintTextLines(Rect(0,0,1000,1000), 0, Lines.Count - 1, 1, 100);
end;

{ TTestBase }

procedure TTestBase.SetUp;
begin
  inherited SetUp;
  Clipboard.Open;

  FForm := TForm.Create(nil);
  ReCreateEdit;
  FForm.Show;
  FFixedBaseTestNames := 0;
end;

procedure TTestBase.TearDown;
begin
  inherited TearDown;
  Clipboard.Close;
  FreeAndNil(FSynEdit);
  FreeAndNil(FForm);
end;

procedure TTestBase.TestIsCaret(Name: String; X, Y: Integer);
begin
  if (SynEdit.LogicalCaretXY.X <> X) or (SynEdit.LogicalCaretXY.Y <> Y) then
    TestFail(Name, 'IsCaret',
             Format('X/Y=(%d, %d)', [X, Y]),
             Format('X/Y=(%d, %d)', [SynEdit.LogicalCaretXY.X, SynEdit.LogicalCaretXY.Y]));
end;

procedure TTestBase.TestIsCaretPhys(Name: String; X, Y: Integer);
begin
  if (SynEdit.CaretXY.X <> X) or (SynEdit.CaretXY.Y <> Y) then
    TestFail(Name, 'IsCaret(Phys)',
             Format('X/Y=(%d, %d)', [X, Y]),
             Format('X/Y=(%d, %d)', [SynEdit.CaretXY.X, SynEdit.CaretXY.Y]));
end;

procedure TTestBase.TestIsCaretAndSel(Name: String; LogX1, LogY1, LogX2, LogY2: Integer);
begin
  TestIsCaret(Name, LogX2, LogY2);
  if (SynEdit.BlockBegin.X <> LogX1) or (SynEdit.BlockBegin.Y <> LogY1) then
    TestFail(Name, 'IsBlockBegin(Log)',
             Format('X/Y=(%d, %d)', [LogX1, LogY1]),
             Format('X/Y=(%d, %d)', [SynEdit.BlockBegin.X, SynEdit.BlockBegin.Y]));
  if (SynEdit.BlockEnd.X <> LogX2) or (SynEdit.BlockEnd.Y <> LogY2) then
    TestFail(Name, 'IsBlockEnd(Log)',
             Format('X/Y=(%d, %d)', [LogX2, LogY2]),
             Format('X/Y=(%d, %d)', [SynEdit.BlockEnd.X, SynEdit.BlockEnd.Y]));
end;

procedure TTestBase.TestIsCaretAndSelBackward(Name: String; LogX1, LogY1, LogX2,
  LogY2: Integer);
begin
  TestIsCaret(Name, LogX1, LogY1);
  if (SynEdit.BlockBegin.X <> LogX1) or (SynEdit.BlockBegin.Y <> LogY1) then
    TestFail(Name, 'IsBlockBegin(Log)',
             Format('X/Y=(%d, %d)', [LogX1, LogY1]),
             Format('X/Y=(%d, %d)', [SynEdit.BlockBegin.X, SynEdit.BlockBegin.Y]));
  if (SynEdit.BlockEnd.X <> LogX2) or (SynEdit.BlockEnd.Y <> LogY2) then
    TestFail(Name, 'IsBlockEnd(Log)',
             Format('X/Y=(%d, %d)', [LogX2, LogY2]),
             Format('X/Y=(%d, %d)', [SynEdit.BlockEnd.X, SynEdit.BlockEnd.Y]));
end;

procedure TTestBase.TestCompareString(Name, Expect, Value: String; DbgInfo: String);
var
  i, j, x, y: Integer;
  s: String;
begin
  if Value = Expect then exit;

  i := 1; j := 1; x:= 1; y:= 1;
  while i <= Min(length(Value), length(Expect)) do begin
    if Value[i] <> Expect[i] then break;
    if copy(Expect, i, length(LineEnding)) = LineEnding then begin
      inc(y);
      x := 1;
      j := i + length(lineEnding);
      inc(i, length(LineEnding));
    end
    else
      inc(i);
  end;

  Debugln([DbgInfo,' - Failed at x/y=(',x,', ',y,') Expected: ',LineEnding, MyDbg(Expect), LineEnding,
           'Got: ',LineEnding, MyDbg(Value), LineEnding ]);
  TestFail(Name, Format('IsText - Failed at x/y=(%d, %d)%sExpected: "%s"...%sGot: "%s"%s%s ',
                        [x, y, LineEnding,
                         DbgStr(copy(Expect,j, i-j+5)), LineEnding,
                         DbgStr(copy(Value,j, i-j+5)), LineEnding, LineEnding]),
           '"'+DbgStr(Expect)+'"', '"'+DbgStr(Value)+'"');
end;

procedure TTestBase.TestCompareString(Name: String; Expect, Value: array of String;
  DbgInfo: String);
begin
  TestCompareString(Name, LinesToText(Expect), LinesToText(Value), DbgInfo);
end;

procedure TTestBase.TestCompareString(Name, Expect: String; Value: array of String;
  DbgInfo: String);
begin
  TestCompareString(Name, Expect, LinesToText(Value), DbgInfo);
end;

procedure TTestBase.TestCompareString(Name: String; Expect: array of String; Value: String;
  DbgInfo: String);
begin
  TestCompareString(Name, LinesToText(Expect), Value, DbgInfo);
end;

procedure TTestBase.TestIsText(Name, Text: String; FullText: Boolean = False);
var
  s: String;
begin
  if FullText then
    s := SynEdit.TestFullText
  else
    s := SynEdit.Text;

  TestCompareString(Name, Text, s, 'IsText');
end;

procedure TTestBase.TestIsText(Name: String; Lines: array of String);
begin
  TestIsText(Name, LinesToText(Lines));
end;

procedure TTestBase.TestIsText(Name: String; Lines: Array of String; Repl: array of const);
begin
  TestIsText(Name, LinesToText(LinesReplace(Lines, Repl)));
end;

procedure TTestBase.TestIsFullText(Name, Text: String);
begin
  TestIsText(Name, Text, True);
end;

procedure TTestBase.TestIsFullText(Name: String; Lines: array of String);
begin
  TestIsFullText(Name, LinesToText(Lines));
end;

procedure TTestBase.TestIsFullText(Name: String; Lines: array of String;
  Repl: array of const);
begin
  TestIsFullText(Name, LinesToText(LinesReplace(Lines, Repl)));
end;

procedure TTestBase.TestFail(Name, Func, Expect, Got: String; Result: Boolean = False);
begin
  if Result then exit;
  DebugLn(DbgStr(SynEdit.Text));
  if BaseTestName <> '' then
    Fail(Format('%s: %s (%s)%sExpected: %s%s     Got: %s', [BaseTestName, Name, Func, LineEnding, Expect, LineEnding, Got]))
  else
    Fail(Format('%s (%s)%sExpected: %s%s     Got: %s', [Name, Func, LineEnding, Expect, LineEnding, Got]));
end;

procedure TTestBase.SetBaseTestName(const AValue: String);
begin
  SetLength(FBaseTestNames, FFixedBaseTestNames);
  PushBaseName(AValue);
end;

function TTestBase.GetClipBoardText: String;
begin
  Result := Clipboard.AsText;
end;

procedure TTestBase.SetClipBoardText(const AValue: String);
begin
  Clipboard.AsText := AValue;
end;

function TTestBase.LinesToText(Lines: array of String; Separator: String = LineEnding;
  SeparatorAtEnd: Boolean = False): String;
var
  i: Integer;
begin
  Result := '';
  for i := low(Lines) to high(Lines) do begin
    Result := Result + Lines[i];
    if (i <> high(Lines)) or SeparatorAtEnd then
      Result := Result + Separator;
  end;
end;

function TTestBase.LinesReplace(Lines: Array of String; Repl: array of const): TStringArray;
var
  i, j, k: Integer;
  s: String;
begin
  SetLength(Result, length(Lines));
  for i := low(Lines) to high(Lines) do
    Result[i-low(Lines)] := Lines[i];
  i := low(Repl);
  j := 0;
  while i <= high(Repl) do begin
    case Repl[i].VType of
      vtInteger:
        begin
          j := Repl[i].vinteger - 1;
          if j < 0
          then j := -j-2
          else begin
            for k := j to high(Result) - 1 do
              Result[k] := Result[k+1];
            SetLength(Result, length(Result)-1);
          end;
        end;
      vtString, vtAnsiString, vtChar:
        begin
          case Repl[i].VType of
            vtString:     s := Repl[i].VString^;
            vtAnsiString: s := AnsiString(Repl[i].VAnsiString);
            vtChar:       s := Repl[i].VChar;
          end;
          SetLength(Result, length(Result)+1);
          for k := high(Result) - 1 downto j do
            Result[k+1] := Result[k];
          Result[j] := s;
          inc(j);
        end;
      else Fail('???');
    end;
    inc(i);
  end;
end;

function TTestBase.LinesReplaceText(Lines: array of String;
  Repl: array of const): String;
begin
  Result := LinesToText(LinesReplace(Lines, Repl));
end;

procedure TTestBase.ReCreateEdit;
begin
  FreeAndNil(FSynEdit);
  FSynEdit := TTestSynEdit.Create(FForm);
  FSynEdit.Parent := FForm;
  FSynEdit.Top := 0;
  FSynEdit.Left := 0;
  FSynEdit.Width:= 500;
  FSynEdit.Height := 250; // FSynEdit.Font.Height * 20 + 2;
end;

procedure TTestBase.SetLines(Lines: array of String);
begin
  SynEdit.Text := LinesToText(Lines);
  {$IFDEF WITH_APPMSG}Application.ProcessMessages;{$ENDIF}
end;

procedure TTestBase.SetCaret(X, Y: Integer);
begin
  SynEdit.BlockBegin := Point(X, Y);
  SynEdit.LogicalCaretXY := Point(X, Y);
  {$IFDEF WITH_APPMSG}Application.ProcessMessages;{$ENDIF}
end;

procedure TTestBase.SetCaretAndSel(X1, Y1, X2, Y2: Integer;
  DoLock: Boolean = False; AMode: TSynSelectionMode = smCurrent);
begin
  if (Y1<0) or (X1 < 0) then begin
    SetCaret(X2, Y2);  // clears selection
    exit;
  end;
  if (Y2<0) or (X2 < 0) then begin
    SetCaret(X1, Y1);  // clears selection
    exit;
  end;
  if DoLock then
    SynEdit.BeginUpdate;
  SynEdit.LogicalCaretXY := Point(X2, Y2);
  SynEdit.BlockBegin := Point(X1, Y1);
  SynEdit.BlockEnd   := Point(X2, Y2);
  if AMode <> smCurrent then
    SynEdit.SelectionMode := AMode;
  if DoLock then
    SynEdit.EndUpdate;
  {$IFDEF WITH_APPMSG}Application.ProcessMessages;{$ENDIF}
end;

procedure TTestBase.SetCaretAndSelBackward(X1, Y1, X2, Y2: Integer;
  DoLock: Boolean = False; AMode: TSynSelectionMode = smCurrent);
begin
  if (Y1<0) or (X1 < 0) then begin
    SetCaret(X2, Y2);  // clears selection
    exit;
  end;
  if (Y2<0) or (X2 < 0) then begin
    SetCaret(X1, Y1);  // clears selection
    exit;
  end;
  if DoLock then
    SynEdit.BeginUpdate;
  SynEdit.LogicalCaretXY := Point(X1, Y1);
  SynEdit.BlockBegin := Point(X2, Y2);
  SynEdit.BlockEnd   := Point(X1, Y1);
  if AMode <> smCurrent then
    SynEdit.SelectionMode := AMode;
  if DoLock then
    SynEdit.EndUpdate;
  {$IFDEF WITH_APPMSG}Application.ProcessMessages;{$ENDIF}
end;

procedure TTestBase.SetCaretPhys(X, Y: Integer);
begin
  SynEdit.CaretXY := Point(X, Y);
  SynEdit.BlockBegin := SynEdit.LogicalCaretXY;
  {$IFDEF WITH_APPMSG}Application.ProcessMessages;{$ENDIF}
end;

procedure TTestBase.SetCaretAndSelPhys(X1, Y1, X2, Y2: Integer; DoLock: Boolean;
  AMode: TSynSelectionMode = smCurrent);
begin
  if (Y1<0) or (X1 < 0) then begin
    SetCaretPhys(X2, Y2);  // clears selection
    exit;
  end;
  if (Y2<0) or (X2 < 0) then begin
    SetCaretPhys(X1, Y1);  // clears selection
    exit;
  end;
  if DoLock then
    SynEdit.BeginUpdate;
  SynEdit.CaretXY := Point(X2, Y2);
  SynEdit.BlockBegin := SynEdit.PhysicalToLogicalPos(Point(X1, Y1));
  SynEdit.BlockEnd   := SynEdit.PhysicalToLogicalPos(Point(X2, Y2));
  if AMode <> smCurrent then
    SynEdit.SelectionMode := AMode;
  if DoLock then
    SynEdit.EndUpdate;
  {$IFDEF WITH_APPMSG}Application.ProcessMessages;{$ENDIF}
end;

procedure TTestBase.SetCaretAndSelPhysBackward(X1, Y1, X2, Y2: Integer;
  DoLock: Boolean; AMode: TSynSelectionMode = smCurrent);
begin
  if (Y1<0) or (X1 < 0) then begin
    SetCaretPhys(X2, Y2);  // clears selection
    exit;
  end;
  if (Y2<0) or (X2 < 0) then begin
    SetCaretPhys(X1, Y1);  // clears selection
    exit;
  end;
  if DoLock then
    SynEdit.BeginUpdate;
  SynEdit.LogicalCaretXY := Point(X1, Y1);
  SynEdit.BlockBegin := SynEdit.PhysicalToLogicalPos(Point(X1, Y1));
  SynEdit.BlockEnd   := SynEdit.PhysicalToLogicalPos(Point(X2, Y2));
  if AMode <> smCurrent then
    SynEdit.SelectionMode := AMode;
  if DoLock then
    SynEdit.EndUpdate;
  {$IFDEF WITH_APPMSG}Application.ProcessMessages;{$ENDIF}
end;

procedure TTestBase.DoKeyPress(Key: Word; Shift: TShiftState = []);
begin
  SynEdit.TestKeyPress(Key, Shift);
  {$IFDEF WITH_APPMSG}Application.ProcessMessages;{$ENDIF}
end;

procedure TTestBase.DoKeyPressAtPos(X, Y: Integer; Key: Word; Shift: TShiftState = []);
begin
  SetCaret(X, Y);
  DoKeyPress(Key, Shift);
end;

procedure TTestBase.PushBaseName(Add: String);
var
  i: Integer;
begin
  i := length(FBaseTestNames);
  SetLength(FBaseTestNames, i + 1);
  FBaseTestNames[i] := Add;
  FBaseTestName := LinesToText(FBaseTestNames, '; ');
end;

procedure TTestBase.PopPushBaseName(Add: String);
begin
  PopBaseName;
  PushBaseName(Add);
end;

procedure TTestBase.PopBaseName;
begin
  if length(FBaseTestNames) = 0 then exit;
  SetLength(FBaseTestNames, length(FBaseTestNames) - 1);
  FBaseTestName := LinesToText(FBaseTestNames, ' ');
end;

procedure TTestBase.IncFixedBaseTestNames;
begin
  Inc(FFixedBaseTestNames);
end;

procedure TTestBase.DecFixedBaseTestNames;
begin
  Dec(FFixedBaseTestNames);
end;

procedure TTestBase.ClearClipBoard;
begin
  Clipboard.Clear;
end;

end.

