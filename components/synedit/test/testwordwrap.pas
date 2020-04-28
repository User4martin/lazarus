unit TestWordWrap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, math, TestBase, SynEditViewedLineMap, SynEditMiscClasses,
  SynEditTypes, SynEditWrappedView, SynHighlighterPas,
  LazSynEditText, LazLoggerBase, Forms, testregistry;

type
  TIntArray = Array of integer;

  { TExpWraps }

  TExpWraps = object
    w: Array of Integer;
    len: Integer;
    function Init(const a: array of integer): TExpWraps;
    procedure SetCapacity(l: Integer);
    procedure Fill(AFrom, ATo: integer; AIncrease: Integer = 1);
    procedure Join(const a: TExpWraps; AInsertPos: Integer = -1);
    procedure Join(const a: array of integer; AInsertPos: Integer = -1);
    procedure SpliceArray(ADelFrom, ADelCount: integer);
  end;

  { TTestWordWrap }

  TTestWordWrap = class(TTestBase)
  private
    FTree: TSynLineMapAVLTree;
    procedure AssertRealToWrapOffsets(const AName: String; ALine: TSynWordWrapLineMap;
      const ExpWrapOffsets: TExpWraps; AStartOffs: Integer = 0);
    procedure AssertWrapToRealOffset(const AName: String; ALine: TSynWordWrapLineMap;
      const ExpRealAndSubOffsets: TExpWraps; AStartOffs: Integer = 0);
    procedure AssertLineForWraps(const AName: String; ALine: TSynWordWrapLineMap;
      const ExpWrapForEachLine: TExpWraps; AnExpAllValid: Boolean = False);
    procedure InitLine(ALine: TSynWordWrapLineMap;
      const AWrapValues: TExpWraps);
    function OnPageNeeded(AMapTree: TSynLineMapAVLTree): TSynEditLineMapPage;
    procedure ValidateWraps(ALine: TSynWordWrapLineMap;
      const AWrapValues: TExpWraps; AStartOffs: Integer = 0; ABackward: Boolean = False);
    procedure ValidateNeededWraps(ALine: TSynWordWrapLineMap; const AWrapValues: TExpWraps);

    procedure ValidateTreeWraps(const AWrapValues: TExpWraps; AStartOffs: Integer = 0);
    procedure AssertTreeForWraps(const AName: String; const ExpWrapForEachLine: TExpWraps; AStartOffs: Integer = 0);

    function CreateTree(APageJoinSize, APageSplitSize, APageJoinDistance: Integer): TSynLineMapAVLTree;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestWordWrapLineMap;
    procedure TestWordWrapLineMapInvalidate;
    procedure TestWordWrapLineMapValidate;
    procedure TestWordWrapLineMapMerge;
    procedure TestWordWrapLineMapMergeInvalidate;

    procedure TestWordWrapTreeInsertThenDelete;
    procedure TestWordWrapTreeDeleteThenInsert;
  end;

  { TTestWordWrapPluginBase }

  TTestWordWrapPluginBase = class(TTestBase)
  protected
    FWordWrap: TLazSynEditLineWrapPlugin;
    procedure AddLines(AFirstLineIdx, ACount, ALen: Integer; AnID: String; SkipBeginUpdate: Boolean = False);
    procedure InternalCheckLine(AName: String; dsp: TLazSynDisplayView; ALine: TLineIdx; AExpTextStart: String);
    procedure CheckLine(AName: String; ALine: TLineIdx; AExpTextStart: String);
    procedure CheckLines(AName: String; AStartLine: TLineIdx; AExpTextStart: array of String);

    procedure SetUp; override;
    procedure TearDown; override;
  end;

  TTestWordWrapPlugin = class(TTestWordWrapPluginBase)
  published
    procedure TestEditorWrap;
  end;

implementation

function FillArray(AFrom, ATo: integer; AIncrease: Integer = 1): TIntArray;
var
  i: Integer;
begin
  SetLength(Result, ATo - AFrom + 1);
  for i := 0 to high(Result) do
    Result[i] := AFrom + i * AIncrease;
end;

{ TExpWraps }

function TExpWraps.Init(const a: array of integer): TExpWraps;
begin
  len := Length(a);
  if len > 0 then begin
    SetCapacity(len);
    move(a[0], w[0], SizeOf(w[0]) * len);
  end;
  Result := self;
end;

procedure TExpWraps.SetCapacity(l: Integer);
begin
  if Length(w) < l then
    SetLength(w, l*2);
end;

procedure TExpWraps.Fill(AFrom, ATo: integer; AIncrease: Integer);
var
  p: PLongInt;
  i: Integer;
begin
  len := ATo - AFrom + 1;
  SetCapacity(len);
  p := @w[0];
  for i := 0 to len - 1 do begin
    p^ := AFrom;
    inc(p);
    inc(AFrom, AIncrease);
  end;
end;

procedure TExpWraps.Join(const a: TExpWraps; AInsertPos: Integer);
var
  i, old: Integer;
begin
  if AInsertPos < 0 then
    AInsertPos := Len;

  i := (Len-AInsertPos);
  old := len;
  len := len + a.len;
  if i < 0 then
    len := len - i;
  SetCapacity(len);

  if i > 0 then begin
    move(w[AInsertPos], w[AInsertPos+a.len], sizeof(w[0]) * i);
  end
  else
  if i < 0 then begin
    FillDWord(w[old], -i, 1);
  end;
  move(a.w[0], w[AInsertPos], sizeof(w[0]) * a.len);
end;

procedure TExpWraps.Join(const a: array of integer; AInsertPos: Integer);
var
  i, la, old: Integer;
begin
  if AInsertPos < 0 then
    AInsertPos := Len;

  i := (Len-AInsertPos);
  la := Length(a);
  old := len;
  len := len + la;
  if i < 0 then
    len := len - i;
  SetCapacity(len);

  if i > 0 then begin
    move(w[AInsertPos], w[AInsertPos+la], sizeof(w[0]) * i);
  end
  else
  if i < 0 then begin
    FillDWord(w[old], -i, 1);
  end;
  move(a[0], w[AInsertPos], sizeof(w[0]) * la);
end;

procedure TExpWraps.SpliceArray(ADelFrom, ADelCount: integer);
var
  i: Integer;
begin
  len := len - ADelCount;

  i := Length(w) - ADelFrom - ADelCount;
  if i > 0 then
    move(w[ADelFrom+ADelCount], w[ADelFrom], sizeof(w[0]) * (i));
end;

{ TTestWordWrap }

procedure TTestWordWrap.AssertRealToWrapOffsets(const AName: String;
  ALine: TSynWordWrapLineMap; const ExpWrapOffsets: TExpWraps;
  AStartOffs: Integer);
var
  i: Integer;
begin
  for i := 0 to ExpWrapOffsets.len - 1 do
    AssertEquals(format('%s: RealToWrap Idx %d StartOffs: %d ', [AName, i, AStartOffs]),
      ExpWrapOffsets.w[i], ALine.WrappedOffsetFor[AStartOffs + i]);
end;

procedure TTestWordWrap.AssertWrapToRealOffset(const AName: String;
  ALine: TSynWordWrapLineMap; const ExpRealAndSubOffsets: TExpWraps;
  AStartOffs: Integer);
var
  i, sub, r: Integer;
begin
  for i := 0 to ExpRealAndSubOffsets.len div 2 - 1 do begin
    r := ALine.GetOffsetForWrap(AStartOffs + i, sub);
    AssertEquals(format('%s: WrapToReal Idx %d StartOffs: %d ', [AName, i, AStartOffs]),
      ExpRealAndSubOffsets.w[i*2], r);
    AssertEquals(format('%s: WrapToReal(SUB) Idx %d StartOffs: %d ', [AName, i, AStartOffs]),
      ExpRealAndSubOffsets.w[i*2+1], sub);
  end;
end;

procedure TTestWordWrap.AssertLineForWraps(const AName: String;
  ALine: TSynWordWrapLineMap; const ExpWrapForEachLine: TExpWraps;
  AnExpAllValid: Boolean);
var
  i, j, ExpWrap, TestWrapToReal, GotReal, sub: Integer;
begin
  if AnExpAllValid then
    AssertTrue(AName + ' - all lines valid', ALine.FirstInvalidLine < 0);
  i := 0;
  while (i < ExpWrapForEachLine.len) and (ExpWrapForEachLine.w[i] = 1) do
    inc(i);
  if i = ExpWrapForEachLine.len then
    i := 0;
  AssertEquals(Format('%s: Offset', [AName]), i, ALine.Offset);

  j := ExpWrapForEachLine.len - 1;
  while (j >= 0) and (ExpWrapForEachLine.w[j] = 1) do
    dec(j);
  AssertEquals(Format('%s: RealCount', [AName]), j + 1 - i, ALine.RealCount);

  ExpWrap := 0;
  TestWrapToReal := 0;
  for i := 0 to ExpWrapForEachLine.len - 1 do begin
    AssertEquals(Format('%s: RealToWrap Idx %d', [AName, i]), ExpWrap, ALine.WrappedOffsetFor[i]);
    ExpWrap := ExpWrap + ExpWrapForEachLine.w[i];

    for j := 0 to ExpWrapForEachLine.w[i] - 1 do begin
      GotReal := ALine.GetOffsetForWrap(TestWrapToReal, sub);
      AssertEquals(Format('%s: WrapToReal Idx %d', [AName, TestWrapToReal]), i, GotReal);
      AssertEquals(Format('%s: WrapToReal Idx %d SUB', [AName, TestWrapToReal]), j, sub);
      inc(TestWrapToReal);
    end;
  end;
end;

procedure TTestWordWrap.InitLine(ALine: TSynWordWrapLineMap;
  const AWrapValues: TExpWraps);
begin
  ALine.DeleteLinesAtOffset(0, ALine.RealCount + ALine.Offset);
  if AWrapValues.len > 0 then begin
    ALine.InsertLinesAtOffset(0, AWrapValues.len);
    ValidateWraps(ALine, AWrapValues);
  end;
  AssertEquals('all valid', -1, ALine.FirstInvalidLine);
end;

function TTestWordWrap.OnPageNeeded(AMapTree: TSynLineMapAVLTree
  ): TSynEditLineMapPage;
begin
  Result := TSynWordWrapIndexPage.Create(AMapTree);
  //TSynWordWrapIndexPage(Result).FSynEditWrappedPlugin := Self;
end;

procedure TTestWordWrap.ValidateWraps(ALine: TSynWordWrapLineMap;
  const AWrapValues: TExpWraps; AStartOffs: Integer; ABackward: Boolean);
var
  i: Integer;
begin
  if ABackward then begin
    for i := AWrapValues.len - 1 downto 0 do
      ALine.ValidateLine(AStartOffs + i, AWrapValues.w[i]);
  end
  else begin
    for i := 0 to AWrapValues.len - 1 do
      ALine.ValidateLine(AStartOffs + i, AWrapValues.w[i]);
  end;
end;

procedure TTestWordWrap.ValidateNeededWraps(ALine: TSynWordWrapLineMap;
  const AWrapValues: TExpWraps);
var
  i: Integer;
begin
  i := ALine.FirstInvalidLine;
  while i >= 0 do begin
    ALine.ValidateLine(i, AWrapValues.w[i]);
    i := ALine.FirstInvalidLine;
  end;
end;

procedure TTestWordWrap.ValidateTreeWraps(const AWrapValues: TExpWraps;
  AStartOffs: Integer);
var
  i: Integer;
  LowLine, HighLine: TLineIdx;
begin
debuglnEnter(['> TTestWordWrap.ValidateTreeWraps ' ]); try
  while FTree.NextBlockForValidation(LowLine, HighLine) do begin
DebugLn([LowLine,' .. ',HighLine]);
    for i := LowLine to HighLine do begin
      AssertTrue(i-AStartOffs < AWrapValues.len);
      FTree.ValidateLine(i, AWrapValues.w[i-AStartOffs]);
    end;
  end;
finally debugln(['=>']); FTree.DebugDump; debuglnExit(['< TTestWordWrap.ValidateTreeWraps ' ]); end;
end;

procedure TTestWordWrap.AssertTreeForWraps(const AName: String;
  const ExpWrapForEachLine: TExpWraps; AStartOffs: Integer);
var
  i, w: Integer;
  sub: TLineIdx;
begin
  w := AStartOffs;
  for i := 0 to (ExpWrapForEachLine.len - 1) do begin
    AssertEquals(Format('%s // l=%d getWrap', [AName, i]),
      w,
      FTree.GetWrapLineForForText(AStartOffs + i)
    );
    w := w + ExpWrapForEachLine.w[i];
    AssertEquals(Format('%s // l=%d getLine', [AName, i]),
      i,
      FTree.GetLineForForWrap(w-1, sub)
    );
    AssertEquals(Format('%s // l=%d sub', [AName, i]),
      ExpWrapForEachLine.w[i]-1,
      sub
    );
  end;
end;

function TTestWordWrap.CreateTree(APageJoinSize, APageSplitSize,
  APageJoinDistance: Integer): TSynLineMapAVLTree;
begin
  Result := TSynLineMapAVLTree.Create(APageJoinSize, APageSplitSize, APageJoinDistance);
  Result.PageCreatorProc := @OnPageNeeded;
end;

procedure TTestWordWrap.SetUp;
begin
  FTree := CreateTree(15, 60, 20);
  inherited SetUp;
end;

procedure TTestWordWrap.TearDown;
begin
  inherited TearDown;
  FTree.Free;
end;

procedure TTestWordWrap.TestWordWrapLineMap;
var
  ALine: TSynWordWrapLineMap;
  ANode: TSynEditLineMapPage;
  i: Integer;
  ATestName: String;
  w: TExpWraps;
begin
  ANode := FTree.FindPageForLine(0, afmCreate).Page;
  ALine := TSynWordWrapIndexPage(ANode).SynWordWrapLineMapStore;
  ALine.InsertLinesAtOffset(0, 5);
  ALine.InvalidateLines(2,3);
  ValidateWraps(ALine, w.init([1, 1, 3, 3, 1]));
  AssertLineForWraps('', ALine, w.init([1, 1, 3, 3, 1,   1,1]));
  //AssertRealToWrapOffsets('', ALine, [0, 1, 2, 5, 8, 9, 10]);
  //AssertWrapToRealOffset('', ALine, [0,0,  1,0,  2,0, 2,1, 2,2,  3,0, 3,1, 3,2,  4,0,  5,0]);
  AssertEquals('all valid', -1, ALine.FirstInvalidLine);

  for i := 1 to 2 do begin

    // insert into offset
    ATestName := 'Insert at start of "Offset"';
    ALine.InsertLinesAtOffset(0, 2);
    ValidateWraps(ALine, w.init([2, 2]), 0, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([2, 2,   1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(0, 2);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);


    ATestName := 'Insert at middle of "Offset"';
    ALine.InsertLinesAtOffset(1, 2);
    ValidateWraps(ALine, w.init([2, 2]), 1, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1,   2, 2,   1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(1, 2);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);


    ATestName := 'Insert at end of "Offset"';
    ALine.InsertLinesAtOffset(2, 2);
    ValidateWraps(ALine, w.init([2, 2]), 2, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1,   2, 2,   3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(2, 2);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);



    ATestName := 'Insert at start of "Offset" - single lines';
    ALine.InsertLinesAtOffset(0, 2);
    ValidateWraps(ALine, w.init([1, 1]), 0, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1,   1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(0, 2);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);


    ATestName := 'Insert at middle of "Offset" - single lines';
    ALine.InsertLinesAtOffset(1, 2);
    ValidateWraps(ALine, w.init([1, 1]), 1, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1,   1, 1,   1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(1, 2);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);


    ATestName := 'Insert at end of "Offset" - single lines';
    ALine.InsertLinesAtOffset(2, 2);
    ValidateWraps(ALine, w.init([1, 1]), 2, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1,   1, 1,   3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(2, 2);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);



    ATestName := 'Insert at start of "Offset" - single/wrap lines';
    ALine.InsertLinesAtOffset(0, 2);
    ValidateWraps(ALine, w.init([1, 2]), 0, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 2,   1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(1, 1);
    AssertLineForWraps(ATestName, ALine, w.init([1,   1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);
    ALine.DeleteLinesAtOffset(0, 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);


    ATestName := 'Delete mixed offset/data';
    ALine.DeleteLinesAtOffset(1, 2);
    AssertLineForWraps(ATestName, ALine, w.init([1,    3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.InsertLinesAtOffset(1, 2);
    ValidateWraps(ALine, w.init([1, 3]), 1, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);


    // insert into data
    ATestName := 'Insert at middle of Data';
    ALine.InsertLinesAtOffset(3, 2);
    ValidateWraps(ALine, w.init([2, 2]), 3, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3,   2, 2,   3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(3, 2);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);



    ATestName := 'Insert at middle of Data';
    ALine.InsertLinesAtOffset(3, 2);
    ValidateWraps(ALine, w.init([2, 2]), 3, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3,   2, 2,   3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(3, 2);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);



    // insert after data
    ATestName := 'Insert at end of Data';
    ALine.InsertLinesAtOffset(5, 1);
    ValidateWraps(ALine, w.init([4]), 5, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   4,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(5, 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);


    ATestName := 'Insert at end of Data - single line';
    ALine.InsertLinesAtOffset(5, 1);
    ValidateWraps(ALine, w.init([1]), 5, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(5, 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);


    ATestName := 'Insert behind end of Data';
    ALine.InsertLinesAtOffset(6, 1);
    ValidateWraps(ALine, w.init([4]), 6, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1, 4,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(6, 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);


    ATestName := 'Insert behind end of Data - single line';
    ALine.InsertLinesAtOffset(6, 1);
    ValidateWraps(ALine, w.init([1]), 6, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.DeleteLinesAtOffset(6, 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);


    ATestName := 'Delete mixed data/after';
    ALine.DeleteLinesAtOffset(3, 2);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3,    1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

    ALine.InsertLinesAtOffset(3, 2);
    ValidateWraps(ALine, w.init([3, 1]), 3, i mod 1 = 1);
    AssertLineForWraps(ATestName, ALine, w.init([1, 1, 3, 3, 1,   1,1]));
    AssertEquals('all valid', -1, ALine.FirstInvalidLine);

  end;

  ALine.InvalidateLines(0, 4);
  ValidateWraps(ALine, w.init([1,1,1,1,1]), 0, False);
  AssertLineForWraps('', ALine, w.init([1, 1, 1, 1, 1,   1,1]));
  AssertEquals('all valid', -1, ALine.FirstInvalidLine);

  ALine.InsertLinesAtOffset(0, 5);
  ValidateWraps(ALine, w.init([1, 1, 3, 3, 1]));
  AssertLineForWraps('', ALine, w.init([1, 1, 3, 3, 1,   1,1]));
  AssertEquals('all valid', -1, ALine.FirstInvalidLine);

  ALine.InvalidateLines(0, 4);
  ValidateWraps(ALine, w.init([1,1,1,1,1]), 0, True);
  AssertLineForWraps('', ALine, w.init([1, 1, 1, 1, 1,   1,1]));
  AssertEquals('all valid', -1, ALine.FirstInvalidLine);

end;

procedure TTestWordWrap.TestWordWrapLineMapInvalidate;
var
  ANode1: TSynWordWrapIndexPage;
  ALine1: TSynWordWrapLineMap;
  //ATestName: String;
  w: TExpWraps;
begin
  // invalidate and insert/remove lines
  ANode1 := TSynWordWrapIndexPage(FTree.FindPageForLine(0, afmCreate).Page);
  ALine1 := ANode1.SynWordWrapLineMapStore;

  InitLine(ALine1, w.init([1]));
  ALine1.InvalidateLines(3,6);
  AssertEquals('invalid', 3, ALine1.FirstInvalidLine);
  AssertEquals('invalid', 6, ALine1.LastInvalidLine);

  ALine1.DeleteLinesAtOffset(6,2);
  AssertEquals('invalid', 3, ALine1.FirstInvalidLine);
  AssertEquals('invalid', 5, ALine1.LastInvalidLine);

  ALine1.InsertLinesAtOffset(2,1);
  AssertEquals('invalid', 2, ALine1.FirstInvalidLine);
  ValidateWraps(ALine1, w.init([1]), 2);

  AssertEquals('invalid', 4, ALine1.FirstInvalidLine);
  AssertEquals('invalid', 6, ALine1.LastInvalidLine);

  ALine1.InsertLinesAtOffset(5,1);
  AssertEquals('invalid', 4, ALine1.FirstInvalidLine);
  AssertEquals('invalid', 7, ALine1.LastInvalidLine);

  ALine1.DeleteLinesAtOffset(4,1);
  AssertEquals('invalid', 4, ALine1.FirstInvalidLine);
  AssertEquals('invalid', 6, ALine1.LastInvalidLine);

end;

procedure TTestWordWrap.TestWordWrapLineMapValidate;
var
  ANode1: TSynWordWrapIndexPage;
  ALine1: TSynWordWrapLineMap;
  ATestName: String;
  w: TExpWraps;
  i: Integer;
begin
  // invalidate/ re-validate => increase/decrease offset/tail by switching between wrap and one-line lines
  ANode1 := TSynWordWrapIndexPage(FTree.FindPageForLine(0, afmCreate).Page);
  ALine1 := ANode1.SynWordWrapLineMapStore;

  ATestName := 'fill one-lines at start - increasing';
  InitLine(ALine1, w.init(FillArray(10, 19)));
  w.Join([1,1]);
  for i := 0 to 3 do begin
    ALine1.InvalidateLines(0, 3);
    w.w[i] := 1;
    ValidateNeededWraps(ALine1, w);
    AssertLineForWraps(Format('%s %d', [ATestName, i]), ALine1, w, True);
  end;

  ATestName := 'fill one-lines at start - decreasing';
  InitLine(ALine1, w.init(FillArray(10, 19)));
  w.Join([1,1]);
  for i := 3 downto 0 do begin
    ALine1.InvalidateLines(0, 3);
    w.w[i] := 1;
    ValidateNeededWraps(ALine1, w);
    AssertLineForWraps(Format('%s %d', [ATestName, i]), ALine1, w, True);
  end;



  ATestName := 'fill one-lines at end - decreasing';
  InitLine(ALine1, w.init(FillArray(10, 19)));
  w.Join([1,1]);
  for i := 9 downto 7 do begin
    ALine1.InvalidateLines(7, 9);
    w.w[i] := 1;
    ValidateNeededWraps(ALine1, w);
    AssertLineForWraps(Format('%s %d', [ATestName, i]), ALine1, w, True);
  end;

  ATestName := 'fill one-lines at end - increasing';
  InitLine(ALine1, w.init(FillArray(10, 19)));
  w.Join([1,1]);
  for i := 7 to 9 do begin
    ALine1.InvalidateLines(7, 9);
    w.w[i] := 1;
    ValidateNeededWraps(ALine1, w);
    AssertLineForWraps(Format('%s %d', [ATestName, i]), ALine1, w, True);
  end;


  ATestName := 'fill one-lines - all, incr';
  InitLine(ALine1, w.init(FillArray(10, 19)));
  w.Join([1,1]);
  for i := 0 to 9 do begin
    ALine1.InvalidateLines(0, 9);
    w.w[i] := 1;
    ValidateNeededWraps(ALine1, w);
    AssertLineForWraps(Format('%s %d', [ATestName, i]), ALine1, w, True);
  end;

  ATestName := 'fill one-lines - all, decr';
  InitLine(ALine1, w.init(FillArray(10, 19)));
  w.Join([1,1]);
  for i := 9 downto 0 do begin
    ALine1.InvalidateLines(0, 9);
    w.w[i] := 1;
    ValidateNeededWraps(ALine1, w);
    AssertLineForWraps(Format('%s %d', [ATestName, i]), ALine1, w, True);
  end;


  ATestName := 'fill one-lines - all, incr then decr';
  InitLine(ALine1, w.init(FillArray(10, 19)));
  w.Join([1,1]);
  for i := 0 to 4 do begin
    ALine1.InvalidateLines(0, 9);
    w.w[i] := 1;
    ValidateNeededWraps(ALine1, w);
    AssertLineForWraps(Format('%s %d', [ATestName, i]), ALine1, w, True);
  end;
  for i := 9 downto 5 do begin
    ALine1.InvalidateLines(0, 9);
    w.w[i] := 1;
    ValidateNeededWraps(ALine1, w);
    AssertLineForWraps(Format('%s %d', [ATestName, i]), ALine1, w, True);
  end;

  ATestName := 'fill one-lines - all, decr then incr';
  InitLine(ALine1, w.init(FillArray(10, 19)));
  w.Join([1,1]);
  for i := 9 downto 5 do begin
    ALine1.InvalidateLines(0, 9);
    w.w[i] := 1;
    ValidateNeededWraps(ALine1, w);
    AssertLineForWraps(Format('%s %d', [ATestName, i]), ALine1, w, True);
  end;
  for i := 0 to 4 do begin
    ALine1.InvalidateLines(0, 9);
    w.w[i] := 1;
    ValidateNeededWraps(ALine1, w);
    AssertLineForWraps(Format('%s %d', [ATestName, i]), ALine1, w, True);
  end;

end;

procedure TTestWordWrap.TestWordWrapLineMapMerge;
var
  ANode1, ANode2: TSynWordWrapIndexPage;
  ALine1, ALine2: TSynWordWrapLineMap;
  ATestName: String;
  w: TExpWraps;
begin
  ANode1 := TSynWordWrapIndexPage(FTree.FindPageForLine(0, afmCreate).Page);
  ANode2 := TSynWordWrapIndexPage(FTree.FindPageForLine(100, afmCreate).Page);
  ALine1 := ANode1.SynWordWrapLineMapStore;
  ALine2 := ANode2.SynWordWrapLineMapStore;

  ATestName := 'Insert at start: no-offset => no-offset';
  InitLine(ALine1, w.init([2, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine2.MoveLinesAtEndTo(ALine1, 0, 3);
  //ALine1.InsertLinesFromPage(ALine2, 0, 0, 3);
  AssertLineForWraps('', ALine1, w.init([4, 5, 6,   2, 1, 3, 3, 1,   1,1]));

  ATestName := 'Insert at start: no-offset => offset';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine2.MoveLinesAtEndTo(ALine1, 0, 3);
  //ALine1.InsertLinesFromPage(ALine2, 0, 0, 3);
  AssertLineForWraps('', ALine1, w.init([4, 5, 6,   1, 1, 3, 3, 1,   1,1]));

  ATestName := 'Insert at start: offset => no offset';
  InitLine(ALine1, w.init([2, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([1, 5, 6]));
  ALine2.MoveLinesAtEndTo(ALine1, 0, 3);
  //ALine1.InsertLinesFromPage(ALine2, 0, 0, 3);
  AssertLineForWraps('', ALine1, w.init([1, 5, 6,   2, 1, 3, 3, 1,   1,1]));

  ATestName := 'Insert at start: offset => offset';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([1, 5, 6]));
  ALine2.MoveLinesAtEndTo(ALine1, 0, 3);
  //ALine1.InsertLinesFromPage(ALine2, 0, 0, 3);
  AssertLineForWraps('', ALine1, w.init([1, 5, 6,   1, 1, 3, 3, 1,   1,1]));


  ATestName := 'Insert at start: no-offset 2nd => no-offset';
  InitLine(ALine1, w.init([2, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine2.MoveLinesAtEndTo(ALine1, 1, 2);
  //ALine1.InsertLinesFromPage(ALine2, 1, 0, 2);
  AssertLineForWraps('', ALine1, w.init([5, 6,   2, 1, 3, 3, 1,   1,1]));

  ATestName := 'Insert at start: no-offset 2nd => offset';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine2.MoveLinesAtEndTo(ALine1, 1, 2);
  //ALine1.InsertLinesFromPage(ALine2, 1, 0, 2);
  AssertLineForWraps('', ALine1, w.init([5, 6,   1, 1, 3, 3, 1,   1,1]));

  ATestName := 'Insert at start: offset 2nd => no offset';
  InitLine(ALine1, w.init([2, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([1, 5, 6]));
  ALine2.MoveLinesAtEndTo(ALine1, 1, 2);
  //ALine1.InsertLinesFromPage(ALine2, 1, 0, 2);
  AssertLineForWraps('', ALine1, w.init([5, 6,   2, 1, 3, 3, 1,   1,1]));

  ATestName := 'Insert at start: offset 2nd => offset';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([1, 5, 6]));
  ALine2.MoveLinesAtEndTo(ALine1, 1, 2);
  //ALine1.InsertLinesFromPage(ALine2, 1, 0, 2);
  AssertLineForWraps('', ALine1, w.init([5, 6,   1, 1, 3, 3, 1,   1,1]));

  ATestName := 'Insert at start: offset 3rd => no offset';
  InitLine(ALine1, w.init([2, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([1, 5, 6, 7]));
  ALine2.MoveLinesAtEndTo(ALine1, 2, 2);
  //ALine1.InsertLinesFromPage(ALine2, 2, 0, 2);
  AssertLineForWraps('', ALine1, w.init([6, 7,   2, 1, 3, 3, 1,   1,1]));

  ATestName := 'Insert at start: offset 3rd => offset';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([1, 5, 6, 7]));
  ALine2.MoveLinesAtEndTo(ALine1, 2, 2);
  //ALine1.InsertLinesFromPage(ALine2, 2, 0, 2);
  AssertLineForWraps('', ALine1, w.init([6, 7,   1, 1, 3, 3, 1,   1,1]));


  ATestName := 'Insert at start: overlen';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine2.MoveLinesAtEndTo(ALine1, 0, 4);
  //ALine1.InsertLinesFromPage(ALine2, 0, 0, 4);
  AssertLineForWraps(ATestName, ALine1, w.init([4, 5, 6, 1,   1, 1, 3, 3, 1,   1,1]));

  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine2.MoveLinesAtEndTo(ALine1, 1, 4);
  //ALine1.InsertLinesFromPage(ALine2, 1, 0, 4);
  AssertLineForWraps(ATestName, ALine1, w.init([5, 6, 1, 1,   1, 1, 3, 3, 1,   1,1]));

  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([1]));
  ALine2.MoveLinesAtEndTo(ALine1, 1, 4);
  //ALine1.InsertLinesFromPage(ALine2, 1, 0, 4);
  AssertLineForWraps(ATestName, ALine1, w.init([1, 1, 1, 1,   1, 1, 3, 3, 1,   1,1]));



  ATestName := 'Insert at end';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine2.MoveLinesAtStartTo(ALine1, 2, 5);
  //ALine1.InsertLinesFromPage(ALine2, 0, 5, 3);
  AssertLineForWraps(ATestName, ALine1, w.init([1, 1, 3, 3, 1,   4, 5, 6,   1,1]));

  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine2.MoveLinesAtStartTo(ALine1, 2, 6);
  //ALine1.InsertLinesFromPage(ALine2, 0, 6, 3);
  AssertLineForWraps(ATestName, ALine1, w.init([1, 1, 3, 3, 1,   1, 4, 5, 6,   1,1]));


  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([1, 5, 6]));
  ALine2.MoveLinesAtStartTo(ALine1, 2, 5);
  //ALine1.InsertLinesFromPage(ALine2, 0, 5, 3);
  AssertLineForWraps(ATestName, ALine1, w.init([1, 1, 3, 3, 1,   1, 5, 6,   1,1]));

  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([1, 5, 6]));
  ALine2.MoveLinesAtStartTo(ALine1, 2, 6);
  //ALine1.InsertLinesFromPage(ALine2, 0, 6, 3);
  AssertLineForWraps(ATestName, ALine1, w.init([1, 1, 3, 3, 1,   1, 1, 5, 6,   1,1]));

end;

procedure TTestWordWrap.TestWordWrapLineMapMergeInvalidate;
var
  ANode1, ANode2: TSynWordWrapIndexPage;
  ALine1, ALine2: TSynWordWrapLineMap;
  ATestName: String;
  w: TExpWraps;
begin
  ANode1 := TSynWordWrapIndexPage(FTree.FindPageForLine(0, afmCreate).Page);
  ANode2 := TSynWordWrapIndexPage(FTree.FindPageForLine(100, afmCreate).Page);
  ALine1 := ANode1.SynWordWrapLineMapStore;
  ALine2 := ANode2.SynWordWrapLineMapStore;

  ATestName := 'Insert at start: target inval';
  InitLine(ALine1, w.init([2, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine1.InvalidateLines(1, 1);
  ALine2.MoveLinesAtEndTo(ALine1, 0, 3);
  //ALine1.InsertLinesFromPage(ALine2, 0, 0, 3);
  AssertLineForWraps('', ALine1, w.init([4, 5, 6,   2, 1, 3, 3, 1,   1,1]));
  AssertEquals('invalid', 4, ALine1.FirstInvalidLine);
  AssertEquals('invalid', 4, ALine1.LastInvalidLine);

  ATestName := 'Insert at start: source inval';
  InitLine(ALine1, w.init([2, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine2.InvalidateLines(1, 1);
  ALine2.MoveLinesAtEndTo(ALine1, 0, 3);
  //ALine1.InsertLinesFromPage(ALine2, 0, 0, 3);
  AssertLineForWraps('', ALine1, w.init([4, 5, 6,   2, 1, 3, 3, 1,   1,1]));
  AssertEquals('invalid', 1, ALine1.FirstInvalidLine);
  AssertEquals('invalid', 1, ALine1.LastInvalidLine);

  ATestName := 'Insert at start: source inval';
  InitLine(ALine1, w.init([2, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine2.InvalidateLines(0, 1);
  ALine2.MoveLinesAtEndTo(ALine1, 1, 2);
  //ALine1.InsertLinesFromPage(ALine2, 1, 0, 2);
  AssertLineForWraps('', ALine1, w.init([5, 6,   2, 1, 3, 3, 1,   1,1]));
  AssertEquals('invalid', 0, ALine1.FirstInvalidLine);
  AssertEquals('invalid', 0, ALine1.LastInvalidLine);

  ATestName := 'Insert at start: source inval';
  InitLine(ALine1, w.init([2, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine2.InvalidateLines(0, 1);
  ALine2.MoveLinesAtEndTo(ALine1, 2, 1);
  //ALine1.InsertLinesFromPage(ALine2, 2, 0, 1);
  AssertLineForWraps('', ALine1, w.init([6,   2, 1, 3, 3, 1,   1,1]));
  AssertEquals('invalid', -1, ALine1.FirstInvalidLine);
  AssertEquals('invalid', -1, ALine1.LastInvalidLine);

  ATestName := 'Insert at start: both inval';
  InitLine(ALine1, w.init([2, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine1.InvalidateLines(1, 1);
  ALine2.InvalidateLines(2, 2);
  ALine2.MoveLinesAtEndTo(ALine1, 0, 3);
  //ALine1.InsertLinesFromPage(ALine2, 0, 0, 3);
  AssertLineForWraps('', ALine1, w.init([4, 5, 6,   2, 1, 3, 3, 1,   1,1]));
  AssertEquals('invalid', 2, ALine1.FirstInvalidLine);
  AssertEquals('invalid', 4, ALine1.LastInvalidLine);


  ATestName := 'Insert at end: source inval';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([4, 5, 6]));
  ALine2.InvalidateLines(2, 2);
  ALine2.MoveLinesAtStartTo(ALine1, 2, 5);
  //ALine1.InsertLinesFromPage(ALine2, 0, 5, 3);
  AssertLineForWraps(ATestName, ALine1, w.init([1, 1, 3, 3, 1,   4, 5, 6,   1,1]));
  AssertEquals('invalid', 7, ALine1.FirstInvalidLine);
  AssertEquals('invalid', 7, ALine1.LastInvalidLine);



  ATestName := 'Insert from end to empty';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([]));
  ALine1.MoveLinesAtEndTo(ALine2, 3, 3);
  AssertLineForWraps(ATestName, ALine2, w.init([3, 1, 1,  1,1,1]));

  ATestName := 'Insert from end to empty';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([]));
  ALine1.MoveLinesAtEndTo(ALine2, 2, 3);
  AssertLineForWraps(ATestName, ALine2, w.init([3, 3, 1,  1,1,1]));

  ATestName := 'Insert from end to empty';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([]));
  ALine1.MoveLinesAtEndTo(ALine2, 1, 3);
  AssertLineForWraps(ATestName, ALine2, w.init([1, 3, 3,  1,1,1]));

  ATestName := 'Insert from end to empty';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([]));
  ALine1.MoveLinesAtEndTo(ALine2, 1, 4);
  AssertLineForWraps(ATestName, ALine2, w.init([1, 3, 3, 1,  1,1,1]));

  ATestName := 'Insert from after end to empty';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([]));
  ALine1.MoveLinesAtEndTo(ALine2, 6, 3);
  AssertLineForWraps(ATestName, ALine2, w.init([1, 1, 1,  1,1,1]));


  ATestName := 'Insert from start to empty';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([]));
  ALine1.MoveLinesAtStartTo(ALine2, 2, 0);
  AssertLineForWraps(ATestName, ALine2, w.init([1, 1, 3,    1,1,1]));

  ATestName := 'Insert from start to empty';
  InitLine(ALine1, w.init([2, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([]));
  ALine1.MoveLinesAtStartTo(ALine2, 2, 0);
  AssertLineForWraps(ATestName, ALine2, w.init([2, 1, 3,    1,1,1,1]));

  ATestName := 'Insert from start to empty';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([]));
  ALine1.MoveLinesAtStartTo(ALine2, 1, 0);
  AssertLineForWraps(ATestName, ALine2, w.init([1, 1,     1,1,1,1]));

  ATestName := 'Insert from start to empty';
  InitLine(ALine1, w.init([1, 1, 3, 3, 1]));
  InitLine(ALine2, w.init([]));
  ALine1.MoveLinesAtStartTo(ALine2, 2, 3);
  AssertLineForWraps(ATestName, ALine2, w.init([1, 1, 1,  1, 1, 3,    1,1,1]));


end;


procedure TTestWordWrap.TestWordWrapTreeInsertThenDelete;
var
  CurWraps: TExpWraps;
  InsPos, InsLen, DelPos, DelCount: Integer;
begin
  FTree.Free;
  FTree := CreateTree(2, 9, 4);
//  FTree := TSynLineMapAVLTree.Create(TSynWordWrapIndexPage, 2, 11, 4);
  for DelPos := 0 to 26 do
  for DelCount := 1 to Min(5, 27-DelPos) do
  for InsPos := 0 to 29 do
  for InsLen := 1 to 4 do begin
    FTree.Clear;

    // init
    CurWraps.Fill(10, 10+26);
    FTree.AdjustForLinesInserted(0, 27, 0);
    ValidateTreeWraps(CurWraps);
    //FTree.DebugDump;
    AssertTreeForWraps(Format('Before ins at pos %d Len %d', [InsPos, InsLen]), CurWraps);

    // ins
    CurWraps.Join(FillArray(500, 499+InsLen), InsPos);
    FTree.AdjustForLinesInserted(InsPos, InsLen, 0);
    //FTree.DebugDump;
    ValidateTreeWraps(CurWraps);
    //FTree.DebugDump;
    AssertTreeForWraps(Format('After ins at pos %d Len %d ins at pos %d Len %d', [DelPos, DelCount, InsPos, InsLen]), CurWraps);

    // del
    FTree.AdjustForLinesDeleted(DelPos, DelCount, 0);
    CurWraps.SpliceArray(DelPos, DelCount);
    AssertTrue(Format('valid After del at pos %d Len %d ins at pos %d Len %d', [DelPos, DelCount, InsPos, InsLen]),
      not FTree.NeedsValidation);
    AssertTreeForWraps(Format('After del at pos %d Len %d ins at pos %d Len %d', [DelPos, DelCount, InsPos, InsLen]), CurWraps);
  end;
end;

procedure TTestWordWrap.TestWordWrapTreeDeleteThenInsert;
var
  CurWraps: TExpWraps;
  InsPos, InsLen, DelPos, DelCount: Integer;
begin
  FTree.Free;
  FTree := CreateTree(2, 9, 4);
//  FTree := TSynLineMapAVLTree.Create(TSynWordWrapIndexPage, 2, 11, 4);
  for DelPos := 0 to 26 do
  for DelCount := 1 to Min(5, 27-DelPos) do
  for InsPos := 0 to 29 do
  for InsLen := 1 to 4 do begin
//if  (InsPos<>15) or (InsLen<>1) or (DelPos<>0) or (DelCount<>1) then continue;
    FTree.Clear;

    // init
    CurWraps.Fill(10, 10+26);
    FTree.AdjustForLinesInserted(0, 27, 0);
    ValidateTreeWraps(CurWraps);
    //FTree.DebugDump;
    AssertTreeForWraps(Format('Before del at pos %d Len %d ins at pos %d Len %d', [DelPos, DelCount, InsPos, InsLen]), CurWraps);

    // del
    FTree.AdjustForLinesDeleted(DelPos, DelCount, 0);
    CurWraps.SpliceArray(DelPos, DelCount);
    AssertTrue(Format('valid After del at pos %d Len %d ins at pos %d Len %d', [DelPos, DelCount, InsPos, InsLen]),
      not FTree.NeedsValidation);
    AssertTreeForWraps(Format('After del at pos %d Len %d ins at pos %d Len %d', [DelPos, DelCount, InsPos, InsLen]), CurWraps);

    // ins
    FTree.AdjustForLinesInserted(InsPos, InsLen, 0);
    CurWraps.Join(FillArray(500, 499+InsLen), InsPos);
    //FTree.DebugDump;
    ValidateTreeWraps(CurWraps);
    //FTree.DebugDump;
    AssertTreeForWraps(Format('After del/ins : del at pos %d Len %d ins at pos %d Len %d', [DelPos, DelCount, InsPos, InsLen]), CurWraps);
  end;
end;

{ TTestWordWrapPluginBase }

procedure TTestWordWrapPluginBase.AddLines(AFirstLineIdx, ACount,
  ALen: Integer; AnID: String; SkipBeginUpdate: Boolean);
var
  i, j: Integer;
  l: String;
begin
  if not SkipBeginUpdate then SynEdit.BeginUpdate;
  for i := 0 to ACount - 1 do begin
    l := '';
    j := 0;
    while Length(l) < ALen do begin
      l := l + copy(AnID+'_'+IntToStr(i)+'_'+IntToStr(j) + '            ',1,12);
      inc(j);
    end;
    l := copy(l, 1, ALen);
    SynEdit.Lines.Insert(AFirstLineIdx + i, l);
  end;
  if not SkipBeginUpdate then SynEdit.EndUpdate;
end;

procedure TTestWordWrapPluginBase.InternalCheckLine(AName: String;
  dsp: TLazSynDisplayView; ALine: TLineIdx; AExpTextStart: String);
var
  gotRealLine: TLineIdx;
  gotStartPos, GotLineLen: Integer;
  gotTokenOk: Boolean;
  gotToken: TLazSynDisplayTokenInfo;
  gotText: PChar;
begin
  dsp.SetHighlighterTokensLine(ALine, gotRealLine, gotStartPos, GotLineLen);
  gotTokenOk := dsp.GetNextHighlighterToken(gotToken);
  gotText := gotToken.TokenStart;

  if not(AExpTextStart = copy(Trim(gotText), 1, Length(AExpTextStart))) then begin
    debugln(['Failed ', AName, ' ', ALine, ':']);
    DebugLn(['GOT: "', gotText, '"']);
    DebugLn(['EXP: "', AExpTextStart, '"']);
  end;
  AssertEquals(AName, AExpTextStart, copy(Trim(gotText), 1, Length(AExpTextStart)));
end;

procedure TTestWordWrapPluginBase.CheckLine(AName: String; ALine: TLineIdx;
  AExpTextStart: String);
var
  v: TSynEditStringsLinked;
  dsp: TLazSynDisplayView;
begin
  v := SynEdit.TextViewsManager.SynTextView[SynEdit.TextViewsManager.Count - 1];
  dsp := v.DisplayView;
  dsp.InitHighlighterTokens(nil);
  try
    InternalCheckLine(AName, dsp, ALine, AExpTextStart);
  finally
    dsp.FinishHighlighterTokens;
  end;
end;

procedure TTestWordWrapPluginBase.CheckLines(AName: String;
  AStartLine: TLineIdx; AExpTextStart: array of String);
var
  v: TSynEditStringsLinked;
  dsp: TLazSynDisplayView;
  i, gotStartPos, GotLineLen: Integer;
  gotTokenOk: Boolean;
  gotToken: TLazSynDisplayTokenInfo;
  s: String;
  gotRealLine: TLineIdx;
begin
  v := SynEdit.TextViewsManager.SynTextView[SynEdit.TextViewsManager.Count - 1];
  dsp := v.DisplayView;
  dsp.InitHighlighterTokens(nil);
  try
    try
      for i := 0 to Length(AExpTextStart)-1 do
        InternalCheckLine(AName, dsp, AStartLine+i, AExpTextStart[i]);
    except
      dsp.FinishHighlighterTokens;
      dsp.InitHighlighterTokens(nil);
      for i := 0 to Length(AExpTextStart)-1 do begin
        dsp.SetHighlighterTokensLine(AStartLine+i, gotRealLine, gotStartPos, GotLineLen);
        s := '';
        while dsp.GetNextHighlighterToken(gotToken) and (gotToken.TokenLength > 0) do
          s := s + copy(gotToken.TokenStart, 1, gotToken.TokenLength);
        debugln('Line %d (real %d): "%s" %d/%d start %d',
          [AStartLine+i, gotRealLine, s, length(s), GotLineLen, gotStartPos]);
      end;
      raise;
    end;
  finally
    dsp.FinishHighlighterTokens;
  end;
end;

procedure TTestWordWrapPluginBase.SetUp;
begin
  inherited SetUp;
  FWordWrap := TLazSynEditLineWrapPlugin.Create(SynEdit);
end;

procedure TTestWordWrapPluginBase.TearDown;
begin
  inherited TearDown;
end;

{ TTestWordWrapPlugin }

procedure TTestWordWrapPlugin.TestEditorWrap;
begin
  SynEdit.Options := [];
  SynEdit.TabWidth := 4;

  SetLines([
    'abc def ' + 'ABC DEF ' + 'XYZ',
    'A'#9'B'#9'C ' + 'DEF G'#9'H ' + 'xyz',
    'äää ööö ' + 'ÄÄÄ ÖÖÖ ' + 'ÜÜÜ',
    ''
  ]);

  SetSynEditWidth(10);
  CheckLines('', 0, [
    'abc def ',
    'ABC DEF ',
    'XYZ',
    'A'#9'B'#9'C ',
    'DEF G'#9'H ',
    'xyz',
    'äää ööö ',
    'ÄÄÄ ÖÖÖ ',
    'ÜÜÜ'
  ]);




  SetSynEditWidth(65);
  AddLines(0, 6000, 60, 'A');

  CheckLine('', 0, 'A_0_0');
  CheckLine('', 1, 'A_1_0');
  CheckLine('', 2, 'A_2_0');
  CheckLine('', 3, 'A_3_0');

  SetSynEditWidth(35);
  CheckLine('', 0, 'A_0_0');
  CheckLine('', 1, 'A_0_3');
  CheckLine('', 2, 'A_1_0');

end;

initialization

  RegisterTest(TTestWordWrap);
  RegisterTest(TTestWordWrapPluginBase);
end.

