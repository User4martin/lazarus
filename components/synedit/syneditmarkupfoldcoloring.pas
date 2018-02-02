{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynEditMarkupFoldColoring.pas, released 2015-12-07.
Copyleft (c) 2015-2016 x2nie - Fathony Luth.

The Original SynEdit Project is based on mwCustomEdit.pas by Martin Waldenburg,
part of the mwEdit component suite.
Portions created by Martin Waldenburg are Copyright (C) 1998 Martin Waldenburg.
All Rights Reserved.

Contributors to the SynEdit and mwEdit projects are listed in the
Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.



Features:
  - paint keywords in multiple colors, depends on fold block level or by config
  - paint vertical line between paired open~close fold
  - vertical line and/or keyword can be disabled
  - independent, can be used for any SynHighlighter
  - many features are well tested for PasSynPas.pas
  - only active when SynEdit.Highlighter is TSynCustomFoldHighlighter

-------------------------------------------------------------------------------}
unit SynEditMarkupFoldColoring;

{$mode objfpc}{$H+}
{ $define SynEditMarkupFoldColoringDebug}

interface

uses
  Classes, SysUtils,Graphics, SynEditMarkup, SynEditMiscClasses, Controls,
  LCLProc, SynEditFoldedView, SynEditHighlighter, SynEditHighlighterFoldBase,
  LazSynEditText;

type

  PMarkupFoldColorInfo = ^TMarkupFoldColorInfo;
  TMarkupFoldColorInfo = record
    Y, X, X2: Integer;
    ColorIdx: Integer;
    Border  : Boolean;
    Ignore  : Boolean; //no color no line
    SrcNode : TSynFoldNodeInfo;
    LevelBefore, Level, LevelAfter : integer; //needed by non nest nodes
  end;

  TMarkupFoldColorInfos = array of TMarkupFoldColorInfo;
  TSynFoldNodeInfos     = array of TSynFoldNodeInfo; //for quick compare detection

  { TSynEditMarkupFoldColors }

  TSynEditMarkupFoldColors = class(TSynEditMarkup)
  private
    fUpdateColors: Boolean;
    function GetFirstCharacterColumn(index: Integer): Byte;
    procedure TextBufferChanged(Sender: TObject);
  private
    FHighlighter: TSynCustomFoldHighlighter;
    FMarkupColors: array of TSynSelectedColor;
    FNestList: TLazSynEditNestedFoldsList;

    // cache
    FFirstCharacterColumnCache: Array of Byte;
    FEndLineCache: Array of Integer;
    FCacheCount,
    FCacheCapacity,
    FFoldColorInfosCount,
    FFoldColorInfosCapacity: Integer;

    FDefaultGroup: integer;
    FFoldColorInfos: TMarkupFoldColorInfos;

    FColors : array of TColor;
    FPreparedRow: integer;
    FLastNode: TSynFoldNodeInfo;
    FLastEnabled: Boolean;

    procedure DoMarkupParentFoldAtRow(aRow: Integer);
    procedure DoMarkupParentCloseFoldAtRow(aRow: Integer);
    function GetColor(pIndex: Integer): TSynSelectedColor;
    procedure SetDefaultGroup(AValue: integer);
    procedure SetCacheCount(pNewCount: Integer);
    procedure SetFoldColorInfosCount(pNewCount: Integer);
    procedure InitCache;
    procedure ClearCache;
    procedure UpdateColors;
    property FirstCharacterColumn[index: Integer]: Byte read GetFirstCharacterColumn;
  protected
    // Notifications about Changes to the text
    procedure DoTextChanged({%H-}StartLine, EndLine, {%H-}ACountDiff: Integer); override; // 1 based
    procedure SetLines(const AValue: TSynEditStrings); override;
    procedure LinesChanged(Sender: TSynEditStrings; aIndex, aCount: Integer);
    procedure HighlightChanged(Sender: TSynEditStrings; aIndex, aCount: Integer);
    procedure DoEnabledChanged(Sender: TObject); override;
    procedure ColorChanged(AMarkup: TObject);
  public
    constructor Create(ASynEdit : TSynEditBase);
    destructor Destroy; override;
    procedure BeginMarkup; override;
    function GetMarkupAttributeAtRowCol(const aRow: Integer;
                                        const aStartCol: TLazSynDisplayTokenBound;
                                        const {%H-}AnRtlInfo: TLazSynDisplayRtlInfo): TSynSelectedColor; override;
    procedure GetNextMarkupColAfterRowCol(const aRow: Integer;
                                         const aStartCol: TLazSynDisplayTokenBound;
                                         const {%H-}AnRtlInfo: TLazSynDisplayRtlInfo;
                                         out   ANextPhys, ANextLog: Integer); override;

    procedure PrepareMarkupForRow(aRow : Integer); override;
    property DefaultGroup : integer read FDefaultGroup write SetDefaultGroup;
    property Color[pIndex: Integer]: TSynSelectedColor read GetColor;
  end;

implementation
uses
  SynEdit,
  SynEditTypes,
  SynEditMiscProcs,
  {$IFDEF SynEditMarkupFoldColoringDebug}
  SynHighlighterPas,
  strutils,
  {$endif}
  Dialogs;


{$IFDEF SynEditMarkupFoldColoringDebug}
function FoldTypeToStr(p_FoldType: Pointer): String;
begin
  WriteStr(Result, TPascalCodeFoldBlockType(PtrUInt(p_FoldType)));
  while length(Result) < 17 do Result := Result + ' ';
end;
{$ENDIF}

{ TSynEditMarkupFoldColors }

constructor TSynEditMarkupFoldColors.Create(ASynEdit: TSynEditBase);
var
  i: Integer;
begin
  inherited Create(ASynEdit);

  FCacheCapacity := 0;
  SetCacheCount(100);

  FHighlighter := TSynCustomFoldHighlighter(TCustomSynEdit(SynEdit).Highlighter);
  if Assigned(FHighlighter)
  and not (FHighlighter  is TSynCustomFoldHighlighter) then
    FHighlighter := nil;

  FDefaultGroup := 0;
  FFoldColorInfosCount := 0;
  SetLength(FFoldColorInfos, 50);
  FFoldColorInfosCapacity := 50;

  FNestList := TLazSynEditNestedFoldsList.Create(Lines, FHighlighter);
  FNestList.ResetFilter;
  FNestList.FoldGroup := FDefaultGroup;
  FNestList.FoldFlags := [sfbIncludeDisabled];
  FNestList.IncludeOpeningOnLine := True;

  SetLength(FMarkupColors, 10);
  for i := 0 to length(FMarkupColors) - 1 do begin
    FMarkupColors[i] := TSynSelectedColor.Create;
    FMarkupColors[i].OnChange := @ColorChanged;
  end;

  MarkupInfo.Foreground := clGreen;
  MarkupInfo.Background := clNone;
  MarkupInfo.Style := [];
  MarkupInfo.StyleMask := [];
  MarkupInfo.FrameEdges:= sfeLeft;

  SetLength(FColors, 6);
  FMarkupColors[0].Foreground  := clRed;
  FMarkupColors[1].Foreground  := $000098F7; //orange
  FMarkupColors[2].Foreground  := $0022CC40; //green
  FMarkupColors[3].Foreground  := $00CCCC00;   //cyan
  FMarkupColors[4].Foreground  := $00FF682A; //blue
  FMarkupColors[5].Foreground  := $00CF00C4; //purple
  FMarkupColors[6].Foreground  := clNone;
  FMarkupColors[7].Foreground  := clNone;
  FMarkupColors[8].Foreground  := clNone;
  FMarkupColors[9].Foreground := clNone;

end;

destructor TSynEditMarkupFoldColors.Destroy;
var
  i: Integer;
begin
  for i := 0 to Length(FMarkupColors) - 1 do
    FMarkupColors[i].Free;
  if Assigned(Lines) then begin
    Lines.RemoveChangeHandler(senrLineCount, @LinesChanged);
    Lines.RemoveChangeHandler(senrHighlightChanged, @HighlightChanged);
    Lines.RemoveNotifyHandler(senrTextBufferChanged, @TextBufferChanged);
  end;
  FreeAndNil(FNestList);
  inherited Destroy;
end;

procedure TSynEditMarkupFoldColors.BeginMarkup;
begin
  {$IFDEF SynEditMarkupFoldColoringDebug}
  //DebugLn('BeginMarkup');
  {$ENDIF}
  inherited BeginMarkup;
  if not Assigned(FHighlighter) then
    exit;
  FNestList.Clear; // for next markup start
  if fUpdateColors then
    UpdateColors;
end;

function TSynEditMarkupFoldColors.GetMarkupAttributeAtRowCol(
  const aRow: Integer; const aStartCol: TLazSynDisplayTokenBound;
  const AnRtlInfo: TLazSynDisplayRtlInfo): TSynSelectedColor;
var
  i, x2both: integer;
begin
  Result := nil;
  if not Assigned(FHighlighter) then exit;
  if (FPreparedRow = aRow) then begin
    {$IFDEF SynEditMarkupFoldColoringDebug}
    //DebugLn('   GetMarkupAttributeAtRowCol %d/%d', [aRow, aStartCol.Logical]);
    {$ENDIF}

    x2both := -3;
    for i := 0 to FFoldColorInfosCount - 1 do
      with FFoldColorInfos[i] do
        if not Ignore
        and (X < X2)
        and (ColorIdx >= 0)
        and (aStartCol.Logical >= x)
        and (aStartCol.Logical < X2) then begin
          {$IFDEF SynEditMarkupFoldColoringDebug}
          //DebugLn('      X=%d X2=%d Y=%d, C=%d B=%s I=%s', [X, X2, Y, ColorIdx, IfThen(Border, 'X', '-'), IfThen(Ignore, 'X', '-')]);
          {$ENDIF}
          if x2both = -3 then begin //first call flag
            MarkupInfo.FrameColor:= clNone;
            MarkupInfo.Foreground:= clNone;
            MarkupInfo.Background:= clNone;
            MarkupInfo.FrameEdges:= sfeNone;
            x2both := 0;
          end;

          Result := MarkupInfo;
          x2both := max(x2both, x2);
          MarkupInfo.SetFrameBoundsLog(x, x2both);
          if Border then begin
            MarkupInfo.FrameColor:= FColors[ColorIdx];
            MarkupInfo.FrameEdges:= sfeLeft;
          end else begin
            MarkupInfo.FrameColor:= clNone;
            MarkupInfo.FrameEdges:= sfeNone;
            MarkupInfo.Foreground := FColors[ColorIdx];
          end;
        end;
  end;
end;

procedure TSynEditMarkupFoldColors.GetNextMarkupColAfterRowCol(
  const aRow: Integer; const aStartCol: TLazSynDisplayTokenBound;
  const AnRtlInfo: TLazSynDisplayRtlInfo; out ANextPhys, ANextLog: Integer);
var i : integer;
begin
  {$IFDEF SynEditMarkupFoldColoringDebug}
  //DebugLn('GetNextMarkupColAfterRowCol %d/%d', [aRow, aStartCol.Logical]);
  {$ENDIF}
  if not Assigned(FHighlighter)
  or (FPreparedRow <> aRow) then
    exit;

  ANextLog := -1;
  ANextPhys := -1;
  for i := 0 to FFoldColorInfosCount - 1  do
    with FFoldColorInfos[i] do begin
      if not Ignore and (ColorIdx >= 0) and (X < X2) and (aStartCol.Logical < x) and (aStartCol.Logical <= X2) then begin
        ANextLog := FFoldColorInfos[i].X;
        break;
      end;
    end;
end;

function TSynEditMarkupFoldColors.GetFirstCharacterColumn(index: Integer): Byte;
var
  l: String;
  p: Integer;
begin
  l := SynEdit.Lines[index];
  p := 1;
  while not (l[p] in [#13, #10, #0])
  and (l[p] in [#9, #32]) do inc(p);
  if p > 255 then p := 255;
  Result := TCustomSynEdit(SynEdit).LogicalToPhysicalPos(Point(p, toPos(index))).x;
end;

procedure TSynEditMarkupFoldColors.TextBufferChanged(Sender: TObject);
begin
  if not Enabled then
    exit;

  InitCache;
end;

procedure TSynEditMarkupFoldColors.DoMarkupParentFoldAtRow(aRow: Integer);
var
  i,lvl: integer;

  procedure AddVerticalLine( ANode: TSynFoldNodeInfo; ANodeIdx: Integer );
  var
    p, l: integer;
  begin
    // get column of first character in row
    if (FCacheCapacity <= ANode.LineIndex)
    or (FFirstCharacterColumnCache[ANode.LineIndex] = 0) then begin
      p := FirstCharacterColumn[ANode.LineIndex];
      if FCacheCapacity > ANode.LineIndex then begin
        FFirstCharacterColumnCache[ANode.LineIndex] := p;
      end else begin
        DebugLn('!!! TSynEditMarkupFoldColors.DoMarkupParentFoldAtRow: FFirstCharacterColumn-Array too small !!!');
      end;
    end;
    if (FCacheCapacity <= ANode.LineIndex)
    or (FEndLineCache[ANode.LineIndex] = 0) then begin
      l := ToPos(FNestList.NodeEndLine[ANodeIdx]);
      if FCacheCapacity > ANode.LineIndex then begin
        FEndLineCache[ANode.LineIndex] := l;
      end else begin
        DebugLn('!!! TSynEditMarkupFoldColors.DoMarkupParentFoldAtRow: FEndLine-Array too small !!!');
      end;
    end;
    SetFoldColorInfosCount(FFoldColorInfosCount + 1);
    with FFoldColorInfos[FFoldColorInfosCount - 1] do begin

      SrcNode:= ANode; //needed by close node
      Border := ToPos(ANode.LineIndex) <> aRow;
      if FCacheCapacity <= ANode.LineIndex then
        X  := p
      else
        X  := FFirstCharacterColumnCache[ANode.LineIndex];
      X := TCustomSynEdit(SynEdit).PhysicalToLogicalPos(Point(X, aRow)).x;
      Y  := aRow;
      X2 := X + 1;
      Ignore := False;

      if Border and (sfaOutlineNoLine in ANode.FoldAction) then
        Ignore := True;
      if not Border and (sfaOutlineNoColor in ANode.FoldAction) then
        Ignore := True;
      Level := lvl;
      ColorIdx := Max(0, lvl) mod (length(FColors));
    end;
  end;

var
  y, lvlB,lvlA: Integer;
  TmpNode: TSynFoldNodeInfo;
  NestCount : integer;

begin
  y := ToIdx(aRow);
  FNestList.Line := y;
  NestCount := FNestList.Count;
  FHighlighter.CurrentLines := Lines;

  lvl := 0;
  i := 0;
  while i < NestCount do begin
    TmpNode := FNestList.HLNode[i];
    {$IFDEF SynEditMarkupFoldColoringDebug}
    //DebugLn('  O: %s %s %s', [IfThen(sfaOutline in TmpNode.FoldAction, 'X', '-'), IfThen(sfaClose in TmpNode.FoldAction, 'C ', IfThen(sfaOpen in TmpNode.FoldAction, 'O ', '??')),FoldTypeToStr(TmpNode.FoldType)]);
    {$ENDIF}
    if (sfaOutline in TmpNode.FoldAction)
    and not (sfaInvalid in TmpNode.FoldAction) then
      //avoid bug of IncludeOpeningOnLine := False;
      if (sfaOpen in TmpNode.FoldAction)
      and (TmpNode.LineIndex + 1 = aRow) then begin
        {do nothing here}
      end else begin
        lvlB := lvl;

        if ( sfaOutlineForceIndent in TmpNode.FoldAction) then
          inc(lvl)
        else if ( sfaOutlineMergeParent in TmpNode.FoldAction) then
          dec(lvl);
        if (FLastNode.LineIndex >= 0)
        and (sfaOutlineKeepLevel in FLastNode.FoldAction)
        and (FLastNode.LineIndex < TmpNode.LineIndex) then
         inc(lvl);

        AddVerticalLine(TmpNode, i);

        if (FFoldColorInfosCount - 1 > 0)
        and (FFoldColorInfos[FFoldColorInfosCount - 1].X = FFoldColorInfos[FFoldColorInfosCount - 2].X) then begin
          // if child is on same x-pos keep level
          if sfaOutlineKeepLevel in FFoldColorInfos[FFoldColorInfosCount - 2].SrcNode.FoldAction then begin
            lvl := FFoldColorInfos[FFoldColorInfosCount - 2].Level;
            FFoldColorInfos[FFoldColorInfosCount - 1].Level := lvl;
            FFoldColorInfos[FFoldColorInfosCount - 1].ColorIdx := Max(0, lvl) mod (length(FColors));
          end;
        end;

        if not (sfaOutlineKeepLevel in TmpNode.FoldAction)
        {and not (sfaOutlineKeepLevelOnSameLine in TmpNode.FoldAction)} then
          inc(lvl);

        if sfaOpen in TmpNode.FoldAction then
          FLastNode := TmpNode;

        lvlA := lvl;

        with FFoldColorInfos[FFoldColorInfosCount - 1] do begin
          LevelBefore := lvlB;
          LevelAfter  := lvlA;
        end;
      end;
    inc(i);
  end;
end;

procedure TSynEditMarkupFoldColors.DoMarkupParentCloseFoldAtRow(aRow: Integer);
var
  lvl: integer;

  procedure AddHighlight( ANode: TSynFoldNodeInfo );
  var x,j : integer;
  begin
    x  := ANode.LogXStart + 1;
    if ANode.LogXStart < ANode.LogXEnd then begin
      {$IFDEF SynEditMarkupFoldColoringDebug}
      //DebugLn('    %d < %d', [ANode.LogXStart, ANode.LogXEnd]);
      {$ENDIF}
      for j := 0 to FFoldColorInfosCount - 1 do
        if (FFoldColorInfos[j].X = x)
        and (FFoldColorInfos[j].Border)
        and (FFoldColorInfos[j].SrcNode.FoldType = ANode.FoldType )
        and (FFoldColorInfos[j].SrcNode.FoldLvlEnd = ANode.FoldLvlStart ) then begin
          {$IFDEF SynEditMarkupFoldColoringDebug}
          //DebugLn('      X2: %d->%d', [FFoldColorInfos[j].X2, ANode.LogXEnd + 1]);
          {$ENDIF}
          FFoldColorInfos[j].X2 := ANode.LogXEnd + 1;
          FFoldColorInfos[j].Border := False
        end;
    end;


    // ignore implicit close nodes at end of line, especially if line is empty
    // or at least has less characters as vertical line is on
    if not(sfaCloseForNextLine in ANode.FoldAction) then begin
      SetFoldColorInfosCount(FFoldColorInfosCount + 1);
      with FFoldColorInfos[FFoldColorInfosCount - 1] do begin
        Border := False;
        SrcNode:= ANode; //needed by close node
        Y  := ANode.LineIndex + 1;
        X  := ANode.LogXStart + 1;
        X2 := ANode.LogXEnd + 1;
        Level := lvl;
        if not (sfaOutlineNocolor in ANode.FoldAction) then
           ColorIdx := Max(0, lvl) mod (length(FColors))
        else
           ColorIdx := -1;
      end;
    end;
  end;

var
  LineIdx,i,j,lvlB,lvlA : integer;
  NodeList: TLazSynFoldNodeInfoList;
  TmpNode: TSynFoldNodeInfo;
  Found: boolean;
begin
  LineIdx := ToIdx(aRow);

  FHighlighter.CurrentLines := Lines;
  FHighlighter.FoldNodeInfo[LineIdx].ClearFilter; // only needed once, in case the line was already used

  NodeList := FHighlighter.FoldNodeInfo[LineIdx];
  NodeList.AddReference;
  try
    NodeList.ActionFilter := [sfaOutline];
    lvl := 0;
    J := FFoldColorInfosCount - 1;
    if J >=0 then
      lvl := max(0,FFoldColorInfos[J].LevelAfter);
    i := 0;
    repeat
      TmpNode := NodeList[i];

      {$IFDEF SynEditMarkupFoldColoringDebug}
      if not (sfaInvalid in TmpNode.FoldAction) then
        DebugLn('  C: %s %s %s', [IfThen(sfaOutline in TmpNode.FoldAction, 'X', '-'), IfThen(sfaClose in TmpNode.FoldAction, 'C ', IfThen(sfaOpen in TmpNode.FoldAction, 'O ', '??')),FoldTypeToStr(TmpNode.FoldType)]);
      {$ENDIF}

      if not (sfaInvalid in TmpNode.FoldAction)
      and (sfaOutline in TmpNode.FoldAction) then begin
        if sfaOpen in TmpNode.FoldAction then begin
          lvlB := lvl;

          if ( sfaOutlineForceIndent in TmpNode.FoldAction) then
            inc(lvl)
          else if ( sfaOutlineMergeParent in TmpNode.FoldAction) then
            dec(lvl);
          if (FLastNode.LineIndex >= 0)
          and (sfaOutlineKeepLevel in FLastNode.FoldAction)
          and (FLastNode.LineIndex < TmpNode.LineIndex) then
           inc(lvl);

          AddHighlight(TmpNode);

          if (FFoldColorInfosCount - 1 > 0)
          and (FFoldColorInfos[FFoldColorInfosCount - 1].X = FFoldColorInfos[FFoldColorInfosCount - 2].X) then
          begin
            // if child is on same x-pos keep level
            if (sfaClose in FFoldColorInfos[FFoldColorInfosCount - 1].SrcNode.FoldAction)
            or (sfaOutlineKeepLevel in FFoldColorInfos[FFoldColorInfosCount - 2].SrcNode.FoldAction) then begin
              lvl := FFoldColorInfos[FFoldColorInfosCount - 2].Level;
              FFoldColorInfos[FFoldColorInfosCount - 1].Level := lvl;
              FFoldColorInfos[FFoldColorInfosCount - 1].ColorIdx := Max(0, lvl) mod (length(FColors));
            end;
          end;

          if not (sfaOutlineKeepLevel in TmpNode.FoldAction)
          {and not (sfaOutlineKeepLevelOnSameLine in TmpNode.FoldAction)} then
            inc(lvl);

          lvlA := lvl;

          if sfaOpen in TmpNode.FoldAction then
            FLastNode := TmpNode;

          with FFoldColorInfos[FFoldColorInfosCount - 1] do begin
            LevelBefore := lvlB;
            LevelAfter  := lvlA;
          end;
        end else if sfaClose in TmpNode.FoldAction then begin
          Found := False;
          for j := FFoldColorInfosCount - 1 downto 0 do begin
            with FFoldColorInfos[j].SrcNode do begin
              if (FoldType = TmpNode.FoldType)
              and (FoldGroup = TmpNode.FoldGroup)
              and (sfaOpen in FoldAction)
              and (NestLvlEnd = TmpNode.NestLvlStart) then begin
                lvlB := lvl;
                lvl := FFoldColorInfos[j].Level;
                lvlA := FFoldColorInfos[j].LevelAfter;
                FLastNode := TmpNode;
                Found := True;
                break;
              end;
            end;
          end;
          if Found then begin
            AddHighlight(TmpNode);
            with FFoldColorInfos[FFoldColorInfosCount - 1] do begin
              LevelBefore := lvlB;
              LevelAfter  := lvlA;
            end;
            // if found opening position is behind closing position:
            // delete this as it does not have to be drawn
            if FFoldColorInfos[j].X > FFoldColorInfos[FFoldColorInfosCount - 1].X then begin
              for j := j to FFoldColorInfosCount - 1 - 1 do begin
                FFoldColorInfos[j] := FFoldColorInfos[j+1];
              end;
              dec(FFoldColorInfosCount);
            end;
          end;
        end;
      end;
      inc(i);
    until i >= NodeList.Count;
  finally
    NodeList.ReleaseReference;
  end;
end;

function TSynEditMarkupFoldColors.GetColor(pIndex: Integer): TSynSelectedColor;
begin
  Assert((pIndex >= 0) and (pIndex < Length(FMarkupColors)), 'Index out of range');
  Result := FMarkupColors[pIndex];
end;

procedure TSynEditMarkupFoldColors.PrepareMarkupForRow(aRow: Integer);
var
  i, LastX, j: Integer;

begin
  {$IFDEF SynEditMarkupFoldColoringDebug}
  //DebugLn('PrepareMarkupForRow %d', [aRow]);
  {$ENDIF}
  if not Assigned(FHighlighter) then exit;
  FPreparedRow := aRow;
  FFoldColorInfosCount := 0; //reset needed to prevent using of invalid area

  if not (TCustomSynEdit(self.SynEdit).Highlighter is TSynCustomFoldHighlighter) then
    exit;

  // invalidate fLastNode
  FLastNode.LineIndex := -1;

  DoMarkupParentFoldAtRow(aRow);
  DoMarkupParentCloseFoldAtRow(aRow);

  {$IFDEF SynEditMarkupFoldColoringDebug}
  for i := 0 to FFoldColorInfosCount - 1 do with FFoldColorInfos[i] do begin
    DebugLn('  %.5d %.2d-%.2d: %d - %s %s', [y, x, X2, ColorIdx, IfThen(sfaClose in SrcNode.FoldAction, 'C ', IfThen(sfaOpen in SrcNode.FoldAction, 'O ', '??')),FoldTypeToStr(SrcNode.FoldType)]);
  end;
  {$ENDIF}

  // delete parents with bigger x
  // to keep out mis indented blocks
  LastX := MaxInt;
  for i := FFoldColorInfosCount - 1 downto 0 do begin
    if FFoldColorInfos[i].X > LastX then begin
      for j := i to length(FFoldColorInfos) - 2 do begin
        FFoldColorInfos[j] := FFoldColorInfos[j + 1];
      end;
      dec(FFoldColorInfosCount);
    end;
    LastX := FFoldColorInfos[i].X;
  end;
end;

procedure TSynEditMarkupFoldColors.SetDefaultGroup(AValue: integer);
begin
  if FDefaultGroup = AValue then Exit;
  FDefaultGroup := AValue;
  FNestList.FoldGroup := FDefaultGroup;
end;

procedure TSynEditMarkupFoldColors.SetCacheCount(pNewCount: Integer);
var
  i: Integer;
begin
  if pNewCount > FCacheCapacity then begin
    // expand array
    FCacheCapacity := pNewCount + 900;
    SetLength(FFirstCharacterColumnCache, FCacheCapacity);
    SetLength(FEndLineCache, FCacheCapacity);
  end;
  if pNewCount > FCacheCount then begin
    // clear new section
    for i := FCacheCount to pNewCount - 1 do begin
      FFirstCharacterColumnCache[i] := 0;
      FEndLineCache[i] := 0;
    end;
  end;
  FCacheCount := pNewCount;
end;

procedure TSynEditMarkupFoldColors.SetFoldColorInfosCount(pNewCount: Integer);
begin
  if pNewCount > FFoldColorInfosCapacity then begin
    // expand array
    FFoldColorInfosCapacity := pNewCount + 49;
    SetLength(FFoldColorInfos, FFoldColorInfosCapacity);
  end;
  FFoldColorInfosCount := pNewCount;
end;

procedure TSynEditMarkupFoldColors.InitCache;
begin
  if Assigned(FNestList) then
    FNestList.Lines := Lines;
  // set cache size
  SetCacheCount(Lines.Count);
end;

procedure TSynEditMarkupFoldColors.ClearCache;
var
  i: Integer;
begin
  for i := 0 to FCacheCount - 1 do begin
    FFirstCharacterColumnCache[i] := 0;
    FEndLineCache[i] := 0;
  end;
end;

procedure TSynEditMarkupFoldColors.UpdateColors;
var
  c, i: Integer;

  procedure AddColor(pColor: TSynSelectedColor);
  begin
    if pColor.Foreground = clNone then exit;
    fColors[c] := pColor.Foreground;
    inc(c);
  end;

begin
  SetLength(fColors, Length(FMarkupColors));
  c := 0;
  for i := 0 to length(FMarkupColors) -1 do
    AddColor(FMarkupColors[i]);
  if c = 0 then begin
    fColors[c] := $0000FF; // default red
    inc(c);
  end;
  SetLength(fColors, c);
  fUpdateColors := False;
end;

procedure TSynEditMarkupFoldColors.DoTextChanged(StartLine, EndLine,
  ACountDiff: Integer);

  procedure FillNestList(var pList: TSynFoldNodeInfos; pLine: Integer; pNestList: TLazSynEditNestedFoldsList);
  var
    lCount, lLineIdx, i, lAnz: Integer;
    lNode: TSynFoldNodeInfo;
  begin
    lLineIdx := ToIdx(pLine);
    pNestList.Line := lLineIdx;
    lCount := pNestList.Count;
    SetLength(pList, lCount);
    lAnz := 0;
    for i := 0 to lCount - 1 do begin
      lNode := pNestList.HLNode[i];
      if (sfaInvalid in lNode.FoldAction)
      or (
        (sfaOpen in lNode.FoldAction)
        and (lNode.LineIndex = lLineIdx)
      ) then
        Continue;

      // hint: NodeEndLine for node is stored in NodeIndex
      lNode.NodeIndex := pNestList.NodeEndLine[i];
      pList[i] := lNode;
      inc(lAnz);
    end;
    SetLength(pList, lAnz);
  end;

var
  i, lMinAnz, lEndLine, j, l: Integer;
  lStartNestList, lEndNestList: array of TSynFoldNodeInfo;
begin
  if not Enabled then
    exit;

  {$IFDEF SynEditMarkupFoldColoringDebug}
  DebugLn('   DoTextChanged %d-%d: %d', [StartLine, EndLine, ACountDiff]);
  {$ENDIF}

  // lines available?
  if Lines.Count = 0 then
    exit;

  // called by accident
  if StartLine = 0 then
    exit;

  // no TSynCustomFoldHighlighter
  if not Assigned(FHighlighter) then
    exit;

  FHighlighter.CurrentLines := Lines;
  // highlighter still scanning
  if FHighlighter.NeedScan then
    exit;

  FNestList.Clear;

  if EndLine < 0 then
    EndLine := StartLine
  else
    // endline seems to be the first line after the change
    EndLine := EndLine - 1;
  lEndLine := EndLine;

  SetLength(lStartNestList, 0);
  SetLength(lEndNestList, 0);

  FillNestList(lStartNestList, StartLine, FNestList);
  {$IFDEF SynEditMarkupFoldColoringDebug}
  //DebugLn('   Nodes at Start:');
  //for i := 0 to length(lStartNestList) - 1 do with lStartNestList[i] do
  //  DebugLn('      x=%.03d l=%.5d %s %s %s %s lvl=%d/%d endline=%d (cache) -> %d (HL)', [LogXStart, ToPos(LineIndex), IfThen(sfaOpen in FoldAction, 'O', IfThen(sfaClose in FoldAction, 'C', ' ')), IfThen(sfaOutlineKeepLevel{OnSameLine} in FoldAction ,'K', ' '), IfThen(sfaOutlineForceIndent in FoldAction, '+', IfThen(sfaOutlineMergeParent in FoldAction, '-', ' ')) ,FoldTypeToStr(FoldType), FoldLvlStart, FoldLvlEnd, ToPos(NodeIndex), ToPos(FHighlighter.FoldEndLine(LineIndex, 0))]);
  {$ENDIF}

  FillNestList(lEndNestList, EndLine + 1, FNestList);
  {$IFDEF SynEditMarkupFoldColoringDebug}
  //DebugLn('   Nodes at End:');
  //for i := 0 to length(lEndNestList) - 1 do with lEndNestList[i] do
  //  DebugLn('      x=%.03d l=%.5d %s %s %s %s lvl=%d/%d endline=%d (cache) -> %d (HL)', [LogXStart, ToPos(LineIndex), IfThen(sfaOpen in FoldAction, 'O', IfThen(sfaClose in FoldAction, 'C', ' ')), IfThen(sfaOutlineKeepLevel{OnSameLine} in FoldAction ,'K', ' '), IfThen(sfaOutlineForceIndent in FoldAction, '+', IfThen(sfaOutlineMergeParent in FoldAction, '-', ' ')) ,FoldTypeToStr(FoldType), FoldLvlStart, FoldLvlEnd, ToPos(NodeIndex), ToPos(FHighlighter.FoldEndLine(LineIndex, 0))]);
  {$ENDIF}

  // delete all nodes in lEndNodeList which where active at StartLine
  // to get the nodes which reach behind EndLine
  lMinAnz := Min(length(lStartNestList), length(lEndNestList));
  for i := 0 to lMinAnz - 1 do begin
    if (lStartNestList[i].FoldGroup = lEndNestList[0].FoldGroup)
    and (lStartNestList[i].FoldType = lEndNestList[0].FoldType)
    and (lStartNestList[i].LineIndex = lEndNestList[0].LineIndex)
    and (lStartNestList[i].LogXStart = lEndNestList[0].LogXStart)
    and (lStartNestList[i].LogXEnd = lEndNestList[0].LogXEnd) then begin
      for j := 0 to length(lEndNestList) - 2 do
        lEndNestList[j] := lEndNestList[j + 1];
      SetLength(lEndNestList, Length(lEndNestList) - 1);
    end else begin
      break
    end;
  end;

  if (length(lEndNestList) > 0) then with lEndNestList[0] do begin
    // deeper fold group than StartLine: fold group ends after EndLine
    // find real EndLine (end line of first remaining fold node)
    {$IFDEF SynEditMarkupFoldColoringDebug}
    //DebugLn('   Remaining Nodes:');
    //for i := 0 to length(lEndNestList) - 1 do with lEndNestList[i] do
    //  DebugLn('      x=%.03d l=%.5d %s %s %s %s lvl=%d/%d endline=%d (cache) -> %d (HL)', [LogXStart, ToPos(LineIndex), IfThen(sfaOpen in FoldAction, 'O', IfThen(sfaClose in FoldAction, 'C', ' ')), IfThen(sfaOutlineKeepLevel{OnSameLine} in FoldAction ,'K', ' '), IfThen(sfaOutlineForceIndent in FoldAction, '+', IfThen(sfaOutlineMergeParent in FoldAction, '-', ' ')) ,FoldTypeToStr(FoldType), FoldLvlStart, FoldLvlEnd, ToPos(NodeIndex), ToPos(FHighlighter.FoldEndLine(LineIndex, 0))]);
    {$ENDIF}
    // does position of first character change for remaining node?
    if FirstCharacterColumn[lEndNestList[0].LineIndex] <> FFirstCharacterColumnCache[lEndNestList[0].LineIndex] then
      // new: Field NodeIndex is used to store NodeEndLine for node see: FillNestList() above
      lEndLine := ToPos(lEndNestList[0].NodeIndex);
  end;

  // check for changes of endline for node which are active at StartLine
  for i := 0 to length(lStartNestList) - 1 do with lStartNestList[i] do
    if sfaOutline in FoldAction then begin
      FNestList.Line := LineIndex;
      l := ToPos(FNestList.NodeEndLine[FNestList.Count]);
      if l <> FEndLineCache[LineIndex] then begin
        lEndLine := Max(lEndLine, Max(l, FEndLineCache[LineIndex]));
        FEndLineCache[LineIndex] := l;
        {$IFDEF SynEditMarkupFoldColoringDebug}
        //DebugLn('   ** x=%.03d l=%.5d %s %s %s %s lvl=%d/%d endline=%d -> %d', [LogXStart, ToPos(LineIndex), IfThen(sfaOpen in FoldAction, 'O', IfThen(sfaClose in FoldAction, 'C', ' ')), IfThen(sfaOutlineKeepLevel{OnSameLine} in FoldAction ,'K', ' '), IfThen(sfaOutlineForceIndent in FoldAction, '+', IfThen(sfaOutlineMergeParent in FoldAction, '-', ' ')) ,FoldTypeToStr(FoldType), FoldLvlStart, FoldLvlEnd, ToPos(NodeIndex), ToPos(FHighlighter.FoldEndLine(LineIndex, 0))]);
        {$ENDIF}
      end;
    end;

  // invalidate cache
  for i := ToIdx(StartLine) to ToIdx(EndLine) do begin
    FFirstCharacterColumnCache[i] := 0;
    FEndLineCache[i] := 0;
  end;

  if lEndLine > EndLine then begin
    {$IFDEF SynEditMarkupFoldColoringDebug}
    DebugLn('   InvalidateSynLines(%d, %d)', [EndLine + 1, lEndLine]);
    {$ENDIF}
    InvalidateSynLines(EndLine + 1 , lEndLine);
  end;

end;

procedure TSynEditMarkupFoldColors.SetLines(const AValue: TSynEditStrings);
var
  old: TSynEditStrings;
begin
  if Enabled then begin
    old := Lines;
    if Assigned(old)
    and (AValue <> old) then begin
      // change:
      // remove Changehandler
      old.RemoveChangeHandler(senrLineCount, @LinesChanged);
      old.RemoveChangeHandler(senrHighlightChanged, @HighlightChanged);
      old.RemoveNotifyHandler(senrTextBufferChanged, @TextBufferChanged);
      ClearCache;
    end;
  end;
  inherited SetLines(AValue);
  if Enabled then begin
    if (AValue <> old) then begin
      // change:
      if Assigned(AValue) then begin
        // add Changehandler
        AValue.AddChangeHandler(senrLineCount, @LinesChanged);
        AValue.AddChangeHandler(senrHighlightChanged, @HighlightChanged);
        AValue.AddNotifyHandler(senrTextBufferChanged, @TextBufferChanged);
        InitCache;
      end else begin
        // clear cache
        SetCacheCount(0);
        if Assigned(FNestList) then
          FNestList.Lines := nil;
      end;
    end;
  end;
end;

procedure TSynEditMarkupFoldColors.LinesChanged(Sender: TSynEditStrings;
                                        aIndex, aCount: Integer);
var
  absCount,
  idx, i: Integer;
begin
  if not Enabled then
    exit;

  {$IFDEF SynEditMarkupFoldColoringDebug}
  DebugLn('   LinesChanged: aIndex=%d aCount=%d', [aIndex, aCount]);
  {$ENDIF}

  idx := ToIdx(aIndex);
  if (aCount < 0)
  and (idx >= 0) then begin
    // lines deleted
    absCount := Abs(aCount);
    for i := idx to Length(FFirstCharacterColumnCache) - 1 - absCount do begin
      FFirstCharacterColumnCache[i] := FFirstCharacterColumnCache[i + absCount];
      FEndLineCache[i] := FEndLineCache[i + absCount];
    end;
  end;
  SetCacheCount(Sender.Count);
  if (aCount > 0) then begin
    if idx >= 0 then begin
      // lines added
      for i := Length(FFirstCharacterColumnCache) - 1 - aCount downto idx do begin
        FFirstCharacterColumnCache[i + aCount] := FFirstCharacterColumnCache[i];
        FEndLineCache[i + aCount] := FEndLineCache[i];
      end;
      for i := idx to Min(idx + aCount, Length(FFirstCharacterColumnCache) - 1) do begin
        FFirstCharacterColumnCache[i] := 0;
        FEndLineCache[i] := 0;
      end;
    end else begin
      // first lines will be inserted
      for i := 0 to Length(FFirstCharacterColumnCache) - 1 do begin
        FFirstCharacterColumnCache[i] := 0;
        FEndLineCache[i] := 0;
      end;
    end;
  end;
end;

procedure TSynEditMarkupFoldColors.HighlightChanged(Sender: TSynEditStrings;
  aIndex, aCount: Integer);
var
  newHighlighter: TSynCustomHighlighter;
begin
  {$IFDEF SynEditMarkupFoldColoringDebug}
  DebugLn('   HighlightChanged: aIndex=%d aCount=%d', [aIndex, aCount]);
  {$ENDIF}

  if (aIndex <> -1)
  or (aCount <> -1) then
    exit;

  newHighlighter := TCustomSynEdit(self.SynEdit).Highlighter;
  if Assigned(newHighlighter)
  and not (newHighlighter is TSynCustomFoldHighlighter) then
    newHighlighter := nil;

  if (newHighlighter = FHighlighter) then
    exit;

  FHighlighter := TSynCustomFoldHighlighter(newHighlighter);

  FNestList.HighLighter := FHighlighter;

  if not Enabled then
    exit;

  ClearCache;
end;

procedure TSynEditMarkupFoldColors.DoEnabledChanged(Sender: TObject);
begin
  if Enabled = FLastEnabled then
    exit;
  FLastEnabled := Enabled;
  if FLastEnabled then begin
    {$IFDEF SynEditMarkupFoldColoringDebug}
    DebugLn('   *** TSynEditMarkupFoldColors Enabled');
    {$ENDIF}
    if Assigned(Lines) then begin
      // add Changehandler
      Lines.AddChangeHandler(senrLineCount, @LinesChanged);
      Lines.AddChangeHandler(senrHighlightChanged, @HighlightChanged);
      Lines.AddNotifyHandler(senrTextBufferChanged, @TextBufferChanged);
      InitCache;
    end;
  end else begin
    {$IFDEF SynEditMarkupFoldColoringDebug}
    DebugLn('   *** TSynEditMarkupFoldColors Disabled');
    {$ENDIF}
    if Assigned(Lines) then begin
      // remove Changehandler
      Lines.RemoveChangeHandler(senrLineCount, @LinesChanged);
      Lines.RemoveChangeHandler(senrHighlightChanged, @HighlightChanged);
      Lines.RemoveNotifyHandler(senrTextBufferChanged, @TextBufferChanged);
      ClearCache;
    end;
  end;
  if Assigned(Lines) then
    InvalidateSynLines(1, Lines.Count);
end;

procedure TSynEditMarkupFoldColors.ColorChanged(AMarkup: TObject);
begin
  fUpdateColors := True;
  if Assigned(Lines) then
    InvalidateSynLines(1, Lines.Count);
end;

end.


