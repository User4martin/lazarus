{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/
Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynEditHighlighter.pas, released 2000-04-07.

The Original Code is based on mwHighlighter.pas by Martin Waldenburg, part of
the mwEdit component suite.
Portions created by Martin Waldenburg are Copyright (C) 1998 Martin Waldenburg.
All Rights Reserved.

Contributors to the SynEdit and mwEdit projects are listed in the
Contributors.txt file.

$Id: synedithighlighter.pp 19051 2009-03-21 00:47:33Z martin $

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

-------------------------------------------------------------------------------}

(* Naming Conventions:
   -  FoldBlock:
     A continuous range of lines, that can (optional) be folded.
     Which Foldblocks can be folded is decided by the Highlighter. It may be
     configurable.
     A Foldblock can contain other Foldbloccks (nested), but two Foldblocks can
     not overlap.
   -  FoldBlockLevel (FoldBlockNestLevel):
     The amount of FoldBlocks in which a line (or a point of text) is.
   -  FoldGroup:
     An independent set of FoldBlocks. FoldBlocks in different Groups may overlap.
     (e.g. IFDEF/REGION in the SynPasSyn allow for overlaps, rather than strict nesting)
     Some older code use "FoldType" instead
   -  FoldNode
     Start or End of a FoldBlock
*)

(* TODO : Workaround for bug #20850
   Remove when FPC 2.6.2 is out
*)
{$IFDEF CPU64}
{$IF (FPC_FULLVERSION = 20600) or (FPC_FULLVERSION = 20501)}
  {$DEFINE ISSUE_20850 }
{$ENDIF}
{$ENDIF}

unit SynEditHighlighterFoldBase;

{$I synedit.inc}

interface

uses
  SysUtils, Classes, math, LCLProc, SynEditHighlighter, SynEditTypes,
  AvgLvlTree;

const
  NullRange = TSynEditRange(nil);

type

  TSynFoldAction = (sfaOpen,     // At this node a new Fold can start
                    sfaClose,    // At this node a fold ends
                    sfaMarkup,   // This node can be highlighted, by the matching Word-Pair Markup
                    sfaFold,     // Part of a fold- or hide-able block (FoldConf.Enabled = True)           - excludes one=liners for FoldFold
                    sfaFoldFold, // Part of a fold-able block (FoldConf.Enabled = True / smFold in Modes)  - includes one=liners / only opening node (todo: maybe both?)
                    sfaFoldHide, // Part of a hide-able block (FoldConf.Enabled = True / smHide in Modes)  - includes one=liners / only opening node (todo: maybe both?)
                    sfaInvalid,  // Wrong Index
                    sfaDefaultCollapsed,
                    sfaOneLineOpen,  // Open, but closes on same line; *only* if hide-able has [sfaOpen, sfaFold]; always has [sfaFoldFold, sfaFoldHide]
                    sfaOneLineClose, // Open, but closes on same line;
                    sfaLastLineClose // Fold is incomplete, and closed at last line of file
                   );
  TSynFoldActions = set of TSynFoldAction;

  (* TSynFoldBlockFilter
     used to specify which folds to include for:
     - FoldOpenCount, FoldCloseCount, FoldNestCount
     - maybe in future TLazSynFoldNodeInfoList
       TLazSynFoldNodeInfoList has additional filters
       TLazSynFoldNodeInfoList always uses the full set (sfbIncludeDisabled)

     A Highlighter is not required to implement this, or can choose to implement
     a subset only. For any field/value a Highlighter may simple assume default.
     - Highlighter that have only one "FoldGroup" do not require this.
     - Highlighter that do not store foldblocks that are unavailable (e.g. off by
       config) always return the same set

     Using a record, as argument is the virtual methods, allows to add further
     fields/values, without breaking inheritance.
     New fields values are expected to be ignored (handled as default) by existing
     highlighter.

     Callers of the method can:
     - use InitFoldBlockFilter to make sure all fields are set to default
     - use (none virtual) wrapper methods
  *)
  TSynFoldBlockFilterFlag = (
    sfbIncludeDisabled // Foldable by config = off
  );
  TSynFoldBlockFilterFlags = set of TSynFoldBlockFilterFlag;
  TSynFoldBlockFilter = record
    FoldGroup: integer;
    Flags: TSynFoldBlockFilterFlags;
  end;

procedure InitFoldBlockFilter(out AFilter: TSynFoldBlockFilter;
                              AFoldGroup: Integer = 0; AFlag: TSynFoldBlockFilterFlags = []);

type

  TSynFoldNodeInfo = record
    LineIndex: Integer;
    NodeIndex: Integer;          // Indicates the position within the list of info nodes (depends on search-Filter)
    LogXStart, LogXEnd: Integer; // -1 previous line
    FoldLvlStart, FoldLvlEnd: Integer; // FoldLvl within each FoldGroup
    NestLvlStart, NestLvlEnd: Integer; // include disabled nodes, e.g markup (within each FoldGroup)
    FoldAction: TSynFoldActions;
    FoldType: Pointer;           // e.g.cfbtBeginEnd, cfbtProcedure ...
    FoldTypeCompatible: Pointer; // map outer and inner begin, and other exchangeable types
    FoldGroup: Integer;          // independend/overlapping folds, e.g begin/end; ifdef, region
  end;
  PSynFoldNodeInfo = ^TSynFoldNodeInfo;

  { TLazSynFoldNodeInfoList }

  TLazSynFoldNodeInfoList = class
  private
    FValid: Boolean;
    FActionFilter: TSynFoldActions;
    FGroupFilter: Integer;
    FLine: TLineIdx;
    FNodeCount: Integer;
    FFilteredCount, FFilteredProgress: Integer;
    FNodeInfoList: Array of TSynFoldNodeInfo;
    FFilteredList: Array of TSynFoldNodeInfo;
    function  GetItem(Index: Integer): TSynFoldNodeInfo;
    procedure SetActionFilter(AValue: TSynFoldActions);
    procedure SetGroupFilter(AValue: Integer);
    function  GetItemPointer(AnIndex: Integer): PSynFoldNodeInfo;
    function  GetLastItemPointer: PSynFoldNodeInfo;
  protected
    procedure Invalidate;
    procedure Clear;
    procedure ClearFilteredList;
    procedure DoFilter(MinIndex: Integer = -1);
    procedure SetLine(ALine: TLineIdx);
    procedure Add(const AnInfo: TSynFoldNodeInfo);
    procedure Delete(AnIndex: Integer = -1);
    function  CountAll: Integer;
    property  ItemPointer[AnIndex: Integer]: PSynFoldNodeInfo read GetItemPointer;
    property  LastItemPointer: PSynFoldNodeInfo read GetLastItemPointer;
  protected
    function  DefaultGroup: Integer; virtual;
    function  MinCapacity: Integer; virtual;
    procedure InvalidateNode(out AnInfo: TSynFoldNodeInfo);
    function  Match(const AnInfo: TSynFoldNodeInfo;
                    AnActionFilter: TSynFoldActions; AGroupFilter: Integer = 0): Boolean; virtual;
  public
    // filtered items
    procedure ClearFilter;
    function Count: Integer;
    property Item[Index: Integer]: TSynFoldNodeInfo read GetItem; default;
    property ActionFilter: TSynFoldActions read FActionFilter write SetActionFilter;
    property GroupFilter: Integer read FGroupFilter write SetGroupFilter;
  public
    // all items / filtered on the fly
    function CountEx   (AnActionFilter: TSynFoldActions; AGroupFilter: Integer = 0): Integer;
    function NodeInfoEx(Index: Integer; AnActionFilter: TSynFoldActions; AGroupFilter: Integer = 0): TSynFoldNodeInfo; virtual;
  public
    property Line: TLineIdx read FLine;
  end;

  TSynCustomFoldConfigMode = (fmFold, fmHide);
  TSynCustomFoldConfigModes = set of TSynCustomFoldConfigMode;

  { TSynCustomFoldConfig }

  TSynCustomFoldConfig = class(TPersistent)
  private
    FEnabled: Boolean;
    FFoldActions: TSynFoldActions;
    FModes: TSynCustomFoldConfigModes;
    FOnChange: TNotifyEvent;
    FSupportedModes: TSynCustomFoldConfigModes;
    procedure SetFEnabled(const AValue: Boolean);
    procedure SetModes(const AValue: TSynCustomFoldConfigModes);
  protected
    procedure DoOnChange;
  public
    constructor Create;
    procedure Assign(Src: TSynCustomFoldConfig); reintroduce; virtual;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property SupportedModes: TSynCustomFoldConfigModes
             read FSupportedModes write FSupportedModes;
    // Actions representing the modes
    property FoldActions: TSynFoldActions read FFoldActions;
  published
    property Enabled: Boolean read FEnabled write SetFEnabled;
    property Modes: TSynCustomFoldConfigModes read FModes write SetModes default [fmFold];
  end;

  { TSynCustomCodeFoldBlock }

  TSynCustomCodeFoldBlock = class
  private
    FBlockType: Pointer;
    FParent, FChildren: TSynCustomCodeFoldBlock;
    FRight, FLeft: TSynCustomCodeFoldBlock;
    FBalance: Integer;
    function GetChild(ABlockType: Pointer): TSynCustomCodeFoldBlock;
  protected
    function GetOrCreateSibling(ABlockType: Pointer): TSynCustomCodeFoldBlock;
    property Right: TSynCustomCodeFoldBlock read FRight;
    property Left: TSynCustomCodeFoldBlock read FLeft;
    property Children: TSynCustomCodeFoldBlock read FChildren;
  public
    destructor Destroy; override;
    procedure WriteDebugReport;
  public
    procedure InitRootBlockType(AType: Pointer);
    property BlockType: Pointer read FBlockType;
    property Parent: TSynCustomCodeFoldBlock read FParent;
    property Child[ABlockType: Pointer]: TSynCustomCodeFoldBlock read GetChild;
  end;

  { TSynCustomHighlighterRange }

  TSynCustomHighlighterRange = class
  private
    FCodeFoldStackSize: integer; // EndLevel
    FMinimumCodeFoldBlockLevel: integer;
    FRangeType: Pointer;
    FTop: TSynCustomCodeFoldBlock;
  public
    constructor Create(Template: TSynCustomHighlighterRange); virtual;
    destructor Destroy; override;
    function Compare(Range: TSynCustomHighlighterRange): integer; virtual;
    function Add(ABlockType: Pointer = nil; IncreaseLevel: Boolean = True):
        TSynCustomCodeFoldBlock; virtual;
    procedure Pop(DecreaseLevel: Boolean = True); virtual;
    function MaxFoldLevel: Integer; virtual;
    procedure Clear; virtual;
    procedure Assign(Src: TSynCustomHighlighterRange); virtual;
    procedure WriteDebugReport;
    property FoldRoot: TSynCustomCodeFoldBlock read FTop write FTop;
  public
    property RangeType: Pointer read FRangeType write FRangeType;
    property CodeFoldStackSize: integer read FCodeFoldStackSize;
    property MinimumCodeFoldBlockLevel: integer
      read FMinimumCodeFoldBlockLevel write FMinimumCodeFoldBlockLevel;
    property Top: TSynCustomCodeFoldBlock read FTop;
  end;
  TSynCustomHighlighterRangeClass = class of TSynCustomHighlighterRange;

  TSynCustomHighlighterRanges = class;

  { TSynCustomFoldHighlighter }

  TSynCustomFoldHighlighter = class(TSynCustomHighlighter)
  protected
    // Fold Config
    FFoldConfig: Array of TSynCustomFoldConfig;
    function GetFoldConfig(Index: Integer): TSynCustomFoldConfig; virtual;
    procedure SetFoldConfig(Index: Integer; const AValue: TSynCustomFoldConfig); virtual;
    function GetFoldConfigCount: Integer; virtual;
    function GetFoldConfigInternalCount: Integer; virtual;
    function GetFoldConfigInstance(Index: Integer): TSynCustomFoldConfig; virtual;
    procedure InitFoldConfig;
    procedure DestroyFoldConfig;
    procedure DoFoldConfigChanged(Sender: TObject); virtual;
  private
    FCodeFoldRange: TSynCustomHighlighterRange;
    fRanges: TSynCustomHighlighterRanges;
    FRootCodeFoldBlock: TSynCustomCodeFoldBlock;
    FFoldNodeInfoList: TLazSynFoldNodeInfoList;
  protected
    // "Range"
    function GetRangeClass: TSynCustomHighlighterRangeClass; virtual;
    procedure CreateRootCodeFoldBlock; virtual; // set RootCodeFoldBlock
    property CodeFoldRange: TSynCustomHighlighterRange read FCodeFoldRange;
    function TopCodeFoldBlockType(DownIndex: Integer = 0): Pointer;
    property RootCodeFoldBlock: TSynCustomCodeFoldBlock read FRootCodeFoldBlock
      write FRootCodeFoldBlock;

    // Open/Close Folds
    function StartCodeFoldBlock(ABlockType: Pointer;
              IncreaseLevel: Boolean = true): TSynCustomCodeFoldBlock; virtual;
    procedure EndCodeFoldBlock(DecreaseLevel: Boolean = True); virtual;

    // Info about Folds
    function CreateFoldNodeInfoList: TLazSynFoldNodeInfoList; virtual;
    function GetFoldNodeInfo(Line: TLineIdx): TLazSynFoldNodeInfoList;
    procedure InitFoldNodeInfo(AList: TLazSynFoldNodeInfoList; Line: TLineIdx); virtual;

    // Info about Folds, on currently set line/range (simply forwarding to range
    function MinimumCodeFoldBlockLevel: integer; virtual;
    function CurrentCodeFoldBlockLevel: integer; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetRange: Pointer; override;

    // Info about Folds
    function FoldBlockOpeningCount(ALineIndex: TLineIdx;
                                   const AFilter: TSynFoldBlockFilter): integer; virtual; overload;
    function FoldBlockClosingCount(ALineIndex: TLineIdx;
                                   const AFilter: TSynFoldBlockFilter): integer; virtual; overload;
    function FoldBlockEndLevel(ALineIndex: TLineIdx;
                               const AFilter: TSynFoldBlockFilter): integer; virtual; overload;
    function FoldBlockMinLevel(ALineIndex: TLineIdx;
                               const AFilter: TSynFoldBlockFilter): integer; virtual; overload;
    (* All nested FoldType (cfbtBegin) if available. Similar to TopCodeFoldBlockType
       - Index=0 is most outer / Index=FoldBlockEndLevel is most inner (TopCodeFoldBlockType 0=inner)
       - False, if it can not be determined for the filter settings
    *)
    function FoldBlockNestedTypes(ALineIndex: TLineIdx; ANestIndex: Integer; out AType: Pointer;
                                  const AFilter: TSynFoldBlockFilter): boolean; virtual; overload;

    function FoldBlockOpeningCount(ALineIndex: TLineIdx; AFoldGroup: integer = 0;
                                   AFlags: TSynFoldBlockFilterFlags = []): integer; overload;
    function FoldBlockClosingCount(ALineIndex: TLineIdx; AFoldGroup: integer = 0;
                                   AFlags: TSynFoldBlockFilterFlags = []): integer; overload;
    function FoldBlockEndLevel(ALineIndex: TLineIdx; AFoldGroup: integer = 0;
                               AFlags: TSynFoldBlockFilterFlags = []): integer; overload;
    function FoldBlockMinLevel(ALineIndex: TLineIdx; AFoldGroup: integer = 0;
                               AFlags: TSynFoldBlockFilterFlags = []): integer; overload;
    function FoldBlockNestedTypes(ALineIndex: TLineIdx; ANestIndex: Integer; out AType: Pointer;
                                  AFoldGroup: integer = 0;
                                  AFlags: TSynFoldBlockFilterFlags = []): boolean; virtual; overload;

    function FoldOpenCount(ALineIndex: Integer; AType: Integer = 0): integer;  deprecated;
    function FoldCloseCount(ALineIndex: Integer; AType: Integer = 0): integer; deprecated;
    function FoldNestCount(ALineIndex: Integer; AType: Integer = 0): integer; deprecated;

    function FoldTypeCount: integer; virtual;
    function FoldTypeAtNodeIndex(ALineIndex, FoldIndex: Integer;
             UseCloseNodes: boolean = false): integer; virtual; // TODO: could be deprecated ./ only child-classes
    function FoldLineLength(ALineIndex, FoldIndex: Integer): integer; virtual;
    function FoldEndLine(ALineIndex, FoldIndex: Integer): integer; virtual;     // FoldEndLine, can be more than given by FoldLineLength, since Length my cut off early

    // All fold-nodes
    property FoldNodeInfo[Line: TLineIdx]: TLazSynFoldNodeInfoList read GetFoldNodeInfo;

    procedure SetRange(Value: Pointer); override;
    procedure ResetRange; override;
    procedure SetLine({$IFDEF FPC}const {$ENDIF}NewValue: String;
                      LineNumber:Integer // 0 based
                      ); override;
  public
    property FoldConfig[Index: Integer]: TSynCustomFoldConfig
      read GetFoldConfig write SetFoldConfig;
    property FoldConfigCount: Integer read GetFoldConfigCount;

  end;

  { TSynCustomHighlighterRanges }

  TSynCustomHighlighterRanges = class
  private
    FAllocatedCount: integer;
    FHighlighterClass: TSynCustomHighlighterClass;
    FItems: TAvgLvlTree;
  public
    constructor Create(TheHighlighterClass: TSynCustomHighlighterClass);
    destructor Destroy; override;
    function GetEqual(Range: TSynCustomHighlighterRange
                      ): TSynCustomHighlighterRange;
    procedure Allocate;
    procedure Release;
    property HighlighterClass: TSynCustomHighlighterClass read FHighlighterClass;
    property AllocatedCount: integer read FAllocatedCount;
  end;

function CompareSynHighlighterRanges(Data1, Data2: Pointer): integer;
function AllocateHighlighterRanges(
     HighlighterClass: TSynCustomHighlighterClass): TSynCustomHighlighterRanges;

function dbgs(AFoldActions: TSynFoldActions): String; overload;
function dbgs(ANode: TSynFoldNodeInfo):string; overload;

implementation

procedure InitFoldBlockFilter(out AFilter: TSynFoldBlockFilter; AFoldGroup: Integer;
  AFlag: TSynFoldBlockFilterFlags = []);
begin
  AFilter.FoldGroup := AFoldGroup;
  AFilter.Flags     := AFlag;
end;

function CompareSynHighlighterRanges(Data1, Data2: Pointer): integer;
var
  Range1: TSynCustomHighlighterRange;
  Range2: TSynCustomHighlighterRange;
begin
  Range1:=TSynCustomHighlighterRange(Data1);
  Range2:=TSynCustomHighlighterRange(Data2);
  Result:=Range1.Compare(Range2);
end;

var
  HighlighterRanges: TFPList = nil;

function IndexOfHighlighterRanges(
  HighlighterClass: TSynCustomHighlighterClass): integer;
begin
  if HighlighterRanges=nil then
    Result:=-1
  else begin
    Result:=HighlighterRanges.Count-1;
    while (Result>=0)
    and (TSynCustomHighlighterRanges(HighlighterRanges[Result]).HighlighterClass
      <>HighlighterClass)
    do
      dec(Result);
  end;
end;

function AllocateHighlighterRanges(
  HighlighterClass: TSynCustomHighlighterClass): TSynCustomHighlighterRanges;
var
  i: LongInt;
begin
  if HighlighterRanges=nil then HighlighterRanges:=TFPList.Create;
  i:=IndexOfHighlighterRanges(HighlighterClass);
  if i>=0 then begin
    Result:=TSynCustomHighlighterRanges(HighlighterRanges[i]);
    Result.Allocate;
  end else begin
    Result:=TSynCustomHighlighterRanges.Create(HighlighterClass);
    HighlighterRanges.Add(Result);
  end;
end;

function dbgs(AFoldActions: TSynFoldActions): String;
var
  i: TSynFoldAction;
  s: string;
begin
  Result:='';
  for i := low(TSynFoldAction) to high(TSynFoldAction) do
    if i in AFoldActions then begin
      WriteStr(s{%H-}, i);
      Result := Result + s + ',';
    end;
  if Result <> '' then Result := '[' + copy(Result, 1, Length(Result)-1) + ']';
end;

function dbgs(ANode: TSynFoldNodeInfo): string;
begin
  with ANode do
    if sfaInvalid in FoldAction then
      Result := Format('L=%3d I=%d  X=%2d-%2d  Fld=%d-%d Nst=%d-%d  FT=%d FTC=%d  Grp=%d  A=%s',
                       [LineIndex, NodeIndex, 0, 0, 0, 0, 0, 0, 0, 0, 0, dbgs(FoldAction)])
    else
      Result := Format('L=%3d I=%d  X=%2d-%2d  Fld=%d-%d Nst=%d-%d  FT=%d FTC=%d  Grp=%d  A=%s',
                       [LineIndex, NodeIndex, LogXStart, LogXEnd,
                        FoldLvlStart, FoldLvlEnd, NestLvlStart, NestLvlEnd,
                        PtrUInt(FoldType), PtrUInt(FoldTypeCompatible), FoldGroup,
                        dbgs(FoldAction)]);
end;

{ TLazSynFoldNodeInfoList }

function TLazSynFoldNodeInfoList.GetItem(Index: Integer): TSynFoldNodeInfo;
begin
  DoFilter(Index);
  if (Index >= FFilteredCount) or (Index < 0) or (not FValid) then
    InvalidateNode(Result)
  else begin
    Result := FFilteredList[Index];
    Result.NodeIndex := Index; // only set copy on result
  end;
end;

procedure TLazSynFoldNodeInfoList.SetActionFilter(AValue: TSynFoldActions);
begin
  if FActionFilter=AValue then Exit;
  FActionFilter:=AValue;
  ClearFilteredList;
end;

procedure TLazSynFoldNodeInfoList.SetGroupFilter(AValue: Integer);
begin
  if FGroupFilter=AValue then Exit;
  FGroupFilter:=AValue;
  ClearFilteredList;
end;

procedure TLazSynFoldNodeInfoList.Clear;
var
  c: Integer;
begin
  FValid := True;
  ClearFilter;
  FLine := -1;
  c := MinCapacity;
  FNodeCount := 0;
  if Length(FNodeInfoList) > c then
    SetLength(FNodeInfoList, c);
end;

procedure TLazSynFoldNodeInfoList.ClearFilteredList;
begin
  SetLength(FFilteredList, 0);
  FFilteredCount := 0;
  FFilteredProgress := 0; // next to be filtered
end;

procedure TLazSynFoldNodeInfoList.ClearFilter;
begin
  ClearFilteredList;
  FGroupFilter := 0;
  FActionFilter := [];
end;

procedure TLazSynFoldNodeInfoList.DoFilter(MinIndex: Integer = -1);
begin
  if FFilteredProgress = FNodeCount then exit;
  if (MinIndex >= 0) and (FFilteredCount > MinIndex) or (not FValid) then exit;

  if (FActionFilter = []) and (FGroupFilter = DefaultGroup) then begin
    FFilteredList := FNodeInfoList;
    FFilteredCount := FNodeCount;
    FFilteredProgress := FNodeCount;
    exit;
  end;

  if Length(FFilteredList) < Length(FNodeInfoList) then
    SetLength(FFilteredList, Length(FNodeInfoList));

  while FFilteredProgress < FNodeCount do begin
    if Match(FNodeInfoList[FFilteredProgress], FActionFilter, FGroupFilter)
    then begin
      FFilteredList[FFilteredCount] := FNodeInfoList[FFilteredProgress];
      inc(FFilteredCount);
    end;
    inc(FFilteredProgress);
    if (MinIndex >= 0) and (FFilteredCount > MinIndex) then break;
  end;
end;

procedure TLazSynFoldNodeInfoList.SetLine(ALine: TLineIdx);
begin
  if FLine = ALine then exit;
  Clear;
  FLine := ALine;
end;

function TLazSynFoldNodeInfoList.MinCapacity: Integer;
begin
  Result := 8;
end;

procedure TLazSynFoldNodeInfoList.InvalidateNode(out AnInfo: TSynFoldNodeInfo);
begin
  AnInfo.FoldAction := [sfaInvalid];
  AnInfo.LineIndex := Line;
  AnInfo.NodeIndex := -1;
end;

procedure TLazSynFoldNodeInfoList.Add(const AnInfo: TSynFoldNodeInfo);
var
  c: Integer;
begin
  if FNodeCount >= Length(FNodeInfoList) - 1 then begin
    c := MinCapacity;
    if c <= 0 then c := 8;
    SetLength(FNodeInfoList, Max(Length(FNodeInfoList) * 2, c));
  end;
  FNodeInfoList[FNodeCount] := AnInfo;
  inc(FNodeCount);
end;

procedure TLazSynFoldNodeInfoList.Delete(AnIndex: Integer = -1);
begin
  if AnIndex > 0 then begin
    while (AnIndex < FNodeCount) do begin
      FNodeInfoList[AnIndex] := FNodeInfoList[AnIndex + 1];
      inc(AnIndex);
    end;
  end;
  if FNodeCount > 0 then
    dec(FNodeCount);
end;

function TLazSynFoldNodeInfoList.CountAll: Integer;
begin
  if FValid then
    Result := FNodeCount
  else
    Result := -1;
end;

function TLazSynFoldNodeInfoList.GetItemPointer(AnIndex: Integer
  ): PSynFoldNodeInfo;
begin
  if (AnIndex >= FNodeCount) or (AnIndex < 0) then
    Result := nil
  else
    Result := @FNodeInfoList[AnIndex];
end;

function TLazSynFoldNodeInfoList.GetLastItemPointer: PSynFoldNodeInfo;
begin
  if FNodeCount < 0 then
    Result := nil
  else
    Result := @FNodeInfoList[FNodeCount-1];
end;

procedure TLazSynFoldNodeInfoList.Invalidate;
begin
  Clear;
  FValid := False;
end;

function TLazSynFoldNodeInfoList.Match(const AnInfo: TSynFoldNodeInfo;
  AnActionFilter: TSynFoldActions; AGroupFilter: Integer): Boolean;
begin
  Result := (AnActionFilter = []) and (AGroupFilter = DefaultGroup);
end;

function TLazSynFoldNodeInfoList.DefaultGroup: Integer;
begin
  Result := 0;
end;

function TLazSynFoldNodeInfoList.Count: Integer;
begin
  if not FValid then exit(-1);

  DoFilter(-1);
  Result := FFilteredCount;
end;

function TLazSynFoldNodeInfoList.CountEx(AnActionFilter: TSynFoldActions;
  AGroupFilter: Integer): Integer;
var
  i: Integer;
begin
  if not FValid then exit(-1);
  if (AnActionFilter = []) and (AGroupFilter = DefaultGroup) then begin
    Result := FNodeCount;
    exit;
  end;

  Result := 0;
  for i := 0 to FNodeCount - 1 do
    if Match(FNodeInfoList[i], AnActionFilter, AGroupFilter) then inc(Result);
end;

function TLazSynFoldNodeInfoList.NodeInfoEx(Index: Integer;
  AnActionFilter: TSynFoldActions; AGroupFilter: Integer): TSynFoldNodeInfo;
var
  i, j: Integer;
begin
  if (Index < 0) or (not FValid) then begin
    InvalidateNode(Result);
    exit;
  end;

  if (AnActionFilter = []) and (AGroupFilter = DefaultGroup) then begin
    if (Index >= FNodeCount) then
      InvalidateNode(Result)
    else
      Result := FNodeInfoList[Index];
    Result.NodeIndex := Index; // only set copy on result
    exit;
  end;

  i := 0;
  j := Index;
  while i < FNodeCount do begin
    if Match(FNodeInfoList[i], AnActionFilter, AGroupFilter) then dec(j);
    if j < 0 then begin;
      Result := FNodeInfoList[i];
      Result.NodeIndex := Index; // only set copy on result
      exit;
    end;
    inc(i);
  end;

  InvalidateNode(Result);
end;

{ TSynCustomFoldHighlighter }

constructor TSynCustomFoldHighlighter.Create(AOwner: TComponent);
begin
  SetLength(FFoldConfig, GetFoldConfigInternalCount);
  InitFoldConfig;
  fRanges:=AllocateHighlighterRanges(TSynCustomHighlighterClass(ClassType));
  CreateRootCodeFoldBlock;
  inherited Create(AOwner);
  FCodeFoldRange:=GetRangeClass.Create(nil);
  FCodeFoldRange.FoldRoot := FRootCodeFoldBlock;
  FFoldNodeInfoList := nil;;
end;

destructor TSynCustomFoldHighlighter.Destroy;
begin
  inherited Destroy;
  DestroyFoldConfig;
  FreeAndNil(FCodeFoldRange);
  FreeAndNil(FRootCodeFoldBlock);
  FreeAndNil(FFoldNodeInfoList);
  fRanges.Release;
  FFoldConfig := nil;
end;

function TSynCustomFoldHighlighter.GetRange: pointer;
begin
  // FCodeFoldRange is the working range and changed steadily
  // => return a fixed copy of the current CodeFoldRange instance,
  //    that can be stored by other classes (e.g. TSynEdit)
  Result:=fRanges.GetEqual(FCodeFoldRange);
end;

function TSynCustomFoldHighlighter.FoldBlockOpeningCount(ALineIndex: TLineIdx;
  const AFilter: TSynFoldBlockFilter): integer;
{$IFDEF ISSUE_20850}
var x : integer;
{$ENDIF}
begin
  if (ALineIndex < 0) or (ALineIndex >= CurrentLines.Count) then
    exit(0);
  {$IFDEF ISSUE_20850}
  x      := FoldBlockEndLevel(ALineIndex, AFilter);
  Result := FoldBlockMinLevel(ALineIndex, AFilter);
  Result := x - Result;
  {$ELSE}
  Result := FoldBlockEndLevel(ALineIndex, AFilter) - FoldBlockMinLevel(ALineIndex, AFilter);
  {$ENDIF}
end;

function TSynCustomFoldHighlighter.FoldBlockClosingCount(ALineIndex: TLineIdx;
  const AFilter: TSynFoldBlockFilter): integer;
{$IFDEF ISSUE_20850}
var x : integer;
{$ENDIF}
begin
  if (ALineIndex < 0) or (ALineIndex >= CurrentLines.Count) then
    exit(0);
  {$IFDEF ISSUE_20850}
  x      := FoldBlockEndLevel(ALineIndex - 1, AFilter);
  Result := FoldBlockMinLevel(ALineIndex, AFilter);
  Result := x - Result;
  {$ELSE}
  Result := FoldBlockEndLevel(ALineIndex - 1, AFilter) - FoldBlockMinLevel(ALineIndex, AFilter);
  {$ENDIF}
end;

function TSynCustomFoldHighlighter.FoldBlockEndLevel(ALineIndex: TLineIdx;
  const AFilter: TSynFoldBlockFilter): integer;
var
  r: Pointer;
begin
  Assert(CurrentRanges <> nil, 'TSynCustomFoldHighlighter.FoldBlockEndLevel requires CurrentRanges');
  if (ALineIndex < 0) or (ALineIndex >= CurrentLines.Count) then
    exit(0);
  r := CurrentRanges[ALineIndex];
  if (r <> nil) and (r <> NullRange) then
    Result := TSynCustomHighlighterRange(r).CodeFoldStackSize
  else
    Result:=0;
end;

function TSynCustomFoldHighlighter.FoldBlockMinLevel(ALineIndex: TLineIdx;
  const AFilter: TSynFoldBlockFilter): integer;
var
  r: Pointer;
begin
  Assert(CurrentRanges <> nil, 'TSynCustomFoldHighlighter.FoldBlockMinLevelrequires CurrentRanges');
  if (ALineIndex < 0) or (ALineIndex >= CurrentLines.Count) then
    exit(0);
  r := CurrentRanges[ALineIndex];
  if (r <> nil) and (r <> NullRange) then
    Result := TSynCustomHighlighterRange(r).MinimumCodeFoldBlockLevel
  else
    Result:=0;
end;

function TSynCustomFoldHighlighter.FoldBlockNestedTypes(ALineIndex: TLineIdx;
  ANestIndex: Integer; out AType: Pointer; const AFilter: TSynFoldBlockFilter): boolean;
begin
  Result := False;
end;

function TSynCustomFoldHighlighter.FoldBlockOpeningCount(ALineIndex: TLineIdx;
  AFoldGroup: integer; AFlags: TSynFoldBlockFilterFlags): integer;
var
  Filter: TSynFoldBlockFilter;
begin
  Filter.FoldGroup := AFoldGroup;
  Filter.Flags := AFlags;
  Result := FoldBlockOpeningCount(ALineIndex, Filter);
end;

function TSynCustomFoldHighlighter.FoldBlockClosingCount(ALineIndex: TLineIdx;
  AFoldGroup: integer; AFlags: TSynFoldBlockFilterFlags): integer;
var
  Filter: TSynFoldBlockFilter;
begin
  Filter.FoldGroup := AFoldGroup;
  Filter.Flags := AFlags;
  Result := FoldBlockClosingCount(ALineIndex, Filter);
end;

function TSynCustomFoldHighlighter.FoldBlockEndLevel(ALineIndex: TLineIdx;
  AFoldGroup: integer; AFlags: TSynFoldBlockFilterFlags): integer;
var
  Filter: TSynFoldBlockFilter;
begin
  Filter.FoldGroup := AFoldGroup;
  Filter.Flags := AFlags;
  Result := FoldBlockEndLevel(ALineIndex, Filter);
end;

function TSynCustomFoldHighlighter.FoldBlockMinLevel(ALineIndex: TLineIdx;
  AFoldGroup: integer; AFlags: TSynFoldBlockFilterFlags): integer;
var
  Filter: TSynFoldBlockFilter;
begin
  Filter.FoldGroup := AFoldGroup;
  Filter.Flags := AFlags;
  Result := FoldBlockMinLevel(ALineIndex, Filter);
end;

function TSynCustomFoldHighlighter.FoldBlockNestedTypes(ALineIndex: TLineIdx;
  ANestIndex: Integer; out AType: Pointer; AFoldGroup: integer;
  AFlags: TSynFoldBlockFilterFlags): boolean;
var
  Filter: TSynFoldBlockFilter;
begin
  Filter.FoldGroup := AFoldGroup;
  Filter.Flags := AFlags;
  Result := FoldBlockNestedTypes(ALineIndex, ANestIndex, AType, Filter);
end;

procedure TSynCustomFoldHighlighter.ResetRange;
begin
  FCodeFoldRange.Clear;
  FCodeFoldRange.FoldRoot := FRootCodeFoldBlock;
end;

function TSynCustomFoldHighlighter.MinimumCodeFoldBlockLevel: integer;
begin
  assert(FCodeFoldRange <> nil, 'MinimumCodeFoldBlockLevel requires FCodeFoldRange');
  Result := FCodeFoldRange.MinimumCodeFoldBlockLevel;
end;

procedure TSynCustomFoldHighlighter.SetRange(Value: Pointer);
begin
  FCodeFoldRange.Assign(TSynCustomHighlighterRange(Value));
  // in case we asigned a null range
  if not assigned(FCodeFoldRange.FoldRoot) then
    FCodeFoldRange.FoldRoot := FRootCodeFoldBlock;
end;

procedure TSynCustomFoldHighlighter.SetLine(const NewValue: String;
  LineNumber: Integer);
begin
  inherited;
  FCodeFoldRange.MinimumCodeFoldBlockLevel := FCodeFoldRange.FCodeFoldStackSize;
end;

function TSynCustomFoldHighlighter.CurrentCodeFoldBlockLevel: integer;
begin
  assert(FCodeFoldRange <> nil, 'MinimumCodeFoldBlockLevel requires FCodeFoldRange');
  Result := FCodeFoldRange.CodeFoldStackSize;
end;

function TSynCustomFoldHighlighter.FoldOpenCount(ALineIndex: Integer; AType: Integer = 0): integer;
begin
  result := FoldBlockOpeningCount(ALineIndex, AType);
end;

function TSynCustomFoldHighlighter.FoldCloseCount(ALineIndex: Integer; AType: Integer = 0): integer;
begin
  result := FoldBlockClosingCount(ALineIndex, AType);
end;

function TSynCustomFoldHighlighter.FoldNestCount(ALineIndex: Integer; AType: Integer = 0): integer;
begin
  Result := FoldBlockEndLevel(ALineIndex, AType);
end;

function TSynCustomFoldHighlighter.FoldTypeCount: integer;
begin
  Result := 1;
end;

function TSynCustomFoldHighlighter.FoldTypeAtNodeIndex(ALineIndex, FoldIndex: Integer;
  UseCloseNodes: boolean): integer;
begin
  Result := 0;
end;

function TSynCustomFoldHighlighter.FoldLineLength(ALineIndex, FoldIndex: Integer): integer;
begin
  Result := FoldEndLine(ALineIndex, FoldIndex);
  // check if fold last line of block (not mixed "end begin")
  if (FoldBlockEndLevel(Result) > FoldBlockMinLevel(Result)) then
    dec(Result);
  // Amount of lines, that will become invisible (excludes the cfCollapsed line)
  Result := Result - ALineIndex;
end;

function TSynCustomFoldHighlighter.FoldEndLine(ALineIndex, FoldIndex: Integer): integer;
var
  lvl, cnt: Integer;
  e, m: Integer;
begin
  cnt := CurrentLines.Count;
  e := FoldBlockEndLevel(ALineIndex);
  m := FoldBlockMinLevel(ALineIndex);
  lvl := Min(m+1+FoldIndex, e);
  Result := ALineIndex + 1;
  while (Result < cnt) and (FoldBlockMinLevel(Result) >= lvl) do inc(Result);
  if (Result = cnt) then
    dec(Result);
end;

function TSynCustomFoldHighlighter.GetFoldConfig(Index: Integer): TSynCustomFoldConfig;
begin
  Result := FFoldConfig[Index];
end;

procedure TSynCustomFoldHighlighter.SetFoldConfig(Index: Integer; const AValue: TSynCustomFoldConfig);
begin
  BeginUpdate;
  FFoldConfig[Index].Assign(AValue);
  EndUpdate;
end;

function TSynCustomFoldHighlighter.GetFoldConfigCount: Integer;
begin
  Result := 0;
end;

function TSynCustomFoldHighlighter.GetFoldConfigInternalCount: Integer;
begin
  Result := 0;
end;

function TSynCustomFoldHighlighter.GetFoldConfigInstance(Index: Integer): TSynCustomFoldConfig;
begin
  Result := TSynCustomFoldConfig.Create;
  Result.OnChange := @DoFoldConfigChanged;
  Result.Enabled := False;
end;

procedure TSynCustomFoldHighlighter.InitFoldConfig;
var
  i: Integer;
begin
  for i := 0 to high(FFoldConfig) do
    FFoldConfig[i] := GetFoldConfigInstance(i);
end;

procedure TSynCustomFoldHighlighter.DestroyFoldConfig;
var
  i: Integer;
begin
  for i := 0 to high(FFoldConfig) do
    FFoldConfig[i].Free;
end;

procedure TSynCustomFoldHighlighter.DoFoldConfigChanged(Sender: TObject);
begin
  FAttributeChangeNeedScan := True;
  DefHighlightChange(self);
end;

function TSynCustomFoldHighlighter.GetFoldNodeInfo(Line: TLineIdx
  ): TLazSynFoldNodeInfoList;
begin
  if FFoldNodeInfoList = nil then
    FFoldNodeInfoList := CreateFoldNodeInfoList;
  Result := FFoldNodeInfoList;
  if Result.Line <> Line then begin
    Result.SetLine(Line);
    InitFoldNodeInfo(Result, Line);
  end;
end;

procedure TSynCustomFoldHighlighter.InitFoldNodeInfo(AList: TLazSynFoldNodeInfoList; Line: TLineIdx);
begin
  AList.Invalidate;
end;

function TSynCustomFoldHighlighter.CreateFoldNodeInfoList: TLazSynFoldNodeInfoList;
begin
  Result := TLazSynFoldNodeInfoList.Create;
end;

function TSynCustomFoldHighlighter.GetRangeClass: TSynCustomHighlighterRangeClass;
begin
  Result:=TSynCustomHighlighterRange;
end;

function TSynCustomFoldHighlighter.TopCodeFoldBlockType(DownIndex: Integer = 0): Pointer;
var
  Fold: TSynCustomCodeFoldBlock;
begin
  Result:=nil;
  if (CodeFoldRange<>nil) then begin
    Fold := CodeFoldRange.Top;
    while (Fold <> nil) and (DownIndex > 0) do begin
      Fold := Fold.Parent;
      dec(DownIndex);
    end;
    if Fold <> nil then
      Result := Fold.BlockType
  end;
end;

function TSynCustomFoldHighlighter.StartCodeFoldBlock(ABlockType: Pointer;
  IncreaseLevel: Boolean = True): TSynCustomCodeFoldBlock;
begin
  Result:=CodeFoldRange.Add(ABlockType, IncreaseLevel);
end;

procedure TSynCustomFoldHighlighter.EndCodeFoldBlock(DecreaseLevel: Boolean = True);
begin
  CodeFoldRange.Pop(DecreaseLevel);
end;

procedure TSynCustomFoldHighlighter.CreateRootCodeFoldBlock;
begin
  FRootCodeFoldBlock := TSynCustomCodeFoldBlock.Create;
end;

{ TSynCustomCodeFoldBlock }

function TSynCustomCodeFoldBlock.GetChild(ABlockType: Pointer): TSynCustomCodeFoldBlock;
begin
  if assigned(FChildren) then
    Result := FChildren.GetOrCreateSibling(ABlockType)
  else begin
    Result := TSynCustomCodeFoldBlock(self.ClassType.Create);
    Result.FBlockType := ABlockType;
    Result.FParent := self;
    FChildren := Result;
  end;
end;

var
  CreateSiblingBalanceList: Array of TSynCustomCodeFoldBlock;

function TSynCustomCodeFoldBlock.GetOrCreateSibling(ABlockType: Pointer): TSynCustomCodeFoldBlock;
  procedure BalanceNode(TheNode: TSynCustomCodeFoldBlock);
  var
    i, l: Integer;
    t: Pointer;
    N, P, C: TSynCustomCodeFoldBlock;
  begin
    l := length(CreateSiblingBalanceList);
    i := 0;
    t := TheNode.FBlockType;
    N := self;
    while N.FBlockType <> t do begin
      if i >= l then begin
        inc(l, 20);
        SetLength(CreateSiblingBalanceList, l);
      end;
      CreateSiblingBalanceList[i] := N; // Record all parents
      inc(i);
      if t < N.FBlockType
      then N := N.FLeft
      else N := N.FRight;
    end;
    if i >= l then begin
      inc(l, 20);
      SetLength(CreateSiblingBalanceList, l);
    end;
    CreateSiblingBalanceList[i] := TheNode;
    while i >= 0 do begin
      if CreateSiblingBalanceList[i].FBalance = 0
        then exit;
      if (CreateSiblingBalanceList[i].FBalance = -1) or
         (CreateSiblingBalanceList[i].FBalance = 1) then begin
        if i = 0 then
          exit;
        dec(i);
        if CreateSiblingBalanceList[i+1] = CreateSiblingBalanceList[i].FLeft
        then dec(CreateSiblingBalanceList[i].FBalance)
        else inc(CreateSiblingBalanceList[i].FBalance);
        continue;
      end;
      // rotate
      P := CreateSiblingBalanceList[i];
      if P.FBalance = -2 then begin
        N := P.FLeft;
        if N.FBalance < 0 then begin
          (* ** single rotate ** *)
          (*  []\[]_     _C                []_      C_    _[]
                    N(-1)_     _[]    =>      []_    _P(0)
                          P(-2)                  N(0)           *)
          C := N.FRight;
          N.FRight := P;
          P.FLeft := C;
          N.FBalance := 0;
          P.FBalance := 0;
        end else begin
          (* ** double rotate ** *)
          (*          x1 x2
               []_     _C                  x1    x2
                  N(+1)_     _[]    =>    N _    _ P
                        P(-2)                 C           *)
          C := N.FRight;
          N.FRight := C.FLeft;
          P.FLeft  := C.FRight;
          C.FLeft  := N;
          C.FRight := P;
          // balance
          if (C.FBalance <= 0)
          then N.FBalance := 0
          else N.FBalance := -1;
          if (C.FBalance = -1)
          then P.FBalance := 1
          else P.FBalance := 0;
          C.FBalance := 0;
          N := C;
        end;
      end else begin // *******************
        N := P.FRight;
        if N.FBalance > 0 then begin
          (* ** single rotate ** *)
          C := N.FLeft;
          N.FLeft := P;
          P.FRight := C;
          N.FBalance := 0;
          P.FBalance := 0;
        end else begin
          (* ** double rotate ** *)
          C := N.FLeft;
          N.FLeft := C.FRight;
          P.FRight  := C.FLeft;
          C.FRight  := N;
          C.FLeft := P;
          // balance
          if (C.FBalance >= 0)
          then N.FBalance := 0
          else N.FBalance := +1;
          if (C.FBalance = +1)
          then P.FBalance := -1
          else P.FBalance := 0;
          C.FBalance := 0;
          N := C;
        end;
      end;
      // update parent
      dec(i);
      if i < 0 then begin
        if assigned(self.FParent) then
          self.FParent.FChildren := N
      end else
        if CreateSiblingBalanceList[i].FLeft = P
        then CreateSiblingBalanceList[i].FLeft := N
        else CreateSiblingBalanceList[i].FRight := N;
      break;
    end
  end;
var
  P: TSynCustomCodeFoldBlock;
begin
  Result := self;
  while (assigned(Result)) do begin
    if Result.FBlockType = ABlockType then
      exit;
    P := Result;
    if ABlockType < Result.FBlockType
    then Result := Result.FLeft
    else Result := Result.FRight;
  end;
  // Not Found
  Result := TSynCustomCodeFoldBlock(self.ClassType.Create);
  Result.FBlockType := ABlockType;
  Result.FParent := self.FParent;

  if ABlockType < P.FBlockType then begin
    P.FLeft := Result;
    dec(P.FBalance);
  end else begin
    P.FRight := Result;
    inc(P.FBalance);
  end;

  // Balance
  if P.FBalance <> 0 then
    BalanceNode(P);

end;

destructor TSynCustomCodeFoldBlock.Destroy;
begin
  FreeAndNil(FRight);
  FreeAndNil(FLeft);
  FreeAndNil(FChildren);
  inherited Destroy;
end;

procedure TSynCustomCodeFoldBlock.WriteDebugReport;
  procedure debugout(n: TSynCustomCodeFoldBlock; s1, s: String; p: TSynCustomCodeFoldBlock);
  begin
    if n = nil then exit;
    if n.FParent <> p then
      DebugLn([s1, 'Wrong Parent for', ' (', PtrInt(n), ')']);
    DebugLn([s1, PtrUInt(n.BlockType), ' (', PtrInt(n), ')']);
    debugout(n.FLeft, s+'L: ', s+'   ', p);
    debugout(n.FRight, s+'R: ', s+'   ', p);
    debugout(n.FChildren, s+'C: ', s+'   ', n);
  end;
begin
  debugout(self, '', '', nil);
end;

procedure TSynCustomCodeFoldBlock.InitRootBlockType(AType: Pointer);
begin
  if assigned(FParent) then
    raise Exception.Create('Attempt to modify a FoldBlock');
  FBlockType := AType;
end;

{ TSynCustomHighlighterRange }

constructor TSynCustomHighlighterRange.Create(
  Template: TSynCustomHighlighterRange);
begin
  if (Template<>nil) and (ClassType<>Template.ClassType) then
    RaiseGDBException('');
  if Template<>nil then
    Assign(Template);
end;

destructor TSynCustomHighlighterRange.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TSynCustomHighlighterRange.Compare(Range: TSynCustomHighlighterRange
  ): integer;
begin
  if RangeType < Range.RangeType then
    Result:=1
  else if RangeType > Range.RangeType then
    Result:=-1
  else if Pointer(FTop) < Pointer(Range.FTop) then
    Result:= -1
  else if Pointer(FTop) > Pointer(Range.FTop) then
    Result:= 1
  else
    Result := FMinimumCodeFoldBlockLevel - Range.FMinimumCodeFoldBlockLevel;
  if Result <> 0 then
    exit;
  Result := FCodeFoldStackSize - Range.FCodeFoldStackSize;
end;

function TSynCustomHighlighterRange.Add(ABlockType: Pointer;
  IncreaseLevel: Boolean = True): TSynCustomCodeFoldBlock;
var
  i: LongInt;
begin
  i := MaxFoldLevel;
  if (i > 0) and (FCodeFoldStackSize >= i) then begin
    //debugln('Reached MaxFoldLevel, ignoring folds');
    exit(nil);
  end;
  Result := FTop.Child[ABlockType];
  if IncreaseLevel then
    inc(FCodeFoldStackSize);
  FTop:=Result;
end;

procedure TSynCustomHighlighterRange.Pop(DecreaseLevel: Boolean = True);
// can be called, even if there is no stack
// because it's normal that sources under development have unclosed blocks
begin
  //debugln('TSynCustomHighlighterRange.Pop');
  if assigned(FTop.Parent) then begin
    FTop := FTop.Parent;
    if DecreaseLevel then
      dec(FCodeFoldStackSize);
    if FMinimumCodeFoldBlockLevel > FCodeFoldStackSize then
      FMinimumCodeFoldBlockLevel := FCodeFoldStackSize;
  end;
end;

function TSynCustomHighlighterRange.MaxFoldLevel: Integer;
begin
  Result := -1;
end;

procedure TSynCustomHighlighterRange.Clear;
begin
  FRangeType:=nil;
  FCodeFoldStackSize := 0;
  FMinimumCodeFoldBlockLevel := 0;
  FTop:=nil;
end;

procedure TSynCustomHighlighterRange.Assign(Src: TSynCustomHighlighterRange);
begin
  if (Src<>nil) and (Src<>TSynCustomHighlighterRange(NullRange)) then begin
    FTop := Src.FTop;
    FCodeFoldStackSize := Src.FCodeFoldStackSize;
    FMinimumCodeFoldBlockLevel := Src.FMinimumCodeFoldBlockLevel;
    FRangeType := Src.FRangeType;
  end
  else begin
    FTop := nil;
    FCodeFoldStackSize := 0;
    FMinimumCodeFoldBlockLevel := 0;
    FRangeType := nil;
  end;
end;

procedure TSynCustomHighlighterRange.WriteDebugReport;
begin
  debugln('TSynCustomHighlighterRange.WriteDebugReport ',DbgSName(Self),
    ' RangeType=',dbgs(RangeType),' StackSize=',dbgs(CodeFoldStackSize));
  debugln(' Block=',dbgs(PtrInt(FTop)));
  FTop.WriteDebugReport;
end;

{ TSynCustomHighlighterRanges }

constructor TSynCustomHighlighterRanges.Create(
  TheHighlighterClass: TSynCustomHighlighterClass);
begin
  Allocate;
  FItems:=TAvgLvlTree.Create(@CompareSynHighlighterRanges);
end;

destructor TSynCustomHighlighterRanges.Destroy;
begin
  if HighlighterRanges<>nil then begin
    HighlighterRanges.Remove(Self);
    if HighlighterRanges.Count=0 then
      FreeAndNil(HighlighterRanges);
  end;
  FItems.FreeAndClear;
  FreeAndNil(FItems);
  inherited Destroy;
end;

function TSynCustomHighlighterRanges.GetEqual(Range: TSynCustomHighlighterRange
  ): TSynCustomHighlighterRange;
var
  Node: TAvgLvlTreeNode;
begin
  if Range=nil then exit(nil);
  Node:=FItems.Find(Range);
  if Node<>nil then begin
    Result:=TSynCustomHighlighterRange(Node.Data);
  end else begin
    // add a copy
    Result:=TSynCustomHighlighterRangeClass(Range.ClassType).Create(Range);
    FItems.Add(Result);
    //if FItems.Count mod 32 = 0 then debugln(['FOLDRANGE Count=', FItems.Count]);
  end;
  //debugln('TSynCustomHighlighterRanges.GetEqual A ',dbgs(Node),' ',dbgs(Result.Compare(Range)),' ',dbgs(Result.CodeFoldStackSize));
end;

procedure TSynCustomHighlighterRanges.Allocate;
begin
  inc(FAllocatedCount);
end;

procedure TSynCustomHighlighterRanges.Release;
begin
  dec(FAllocatedCount);
  if FAllocatedCount=0 then Free;
end;

{ TSynCustomFoldConfig }

procedure TSynCustomFoldConfig.SetFEnabled(const AValue: Boolean);
begin
  if FEnabled = AValue then exit;
  FEnabled := AValue;
  DoOnChange;
end;

procedure TSynCustomFoldConfig.SetModes(const AValue: TSynCustomFoldConfigModes);
begin
  if FModes = AValue then exit;
  FModes := AValue;
  FFoldActions := [];
  if AValue <> [] then FFoldActions := FFoldActions + [sfaFold];
  if fmFold in AValue then FFoldActions := FFoldActions + [sfaFoldFold];
  if fmHide in AValue then FFoldActions := FFoldActions + [sfaFoldHide];
  DoOnChange;
end;

procedure TSynCustomFoldConfig.DoOnChange;
begin
  if assigned(FOnChange) then
    FOnChange(self);
end;

constructor TSynCustomFoldConfig.Create;
begin
  Inherited;
  FSupportedModes := [fmFold];
  Modes := [fmFold];
end;

procedure TSynCustomFoldConfig.Assign(Src: TSynCustomFoldConfig);
begin
  Enabled := Src.Enabled;
  SupportedModes := Src.SupportedModes;
  Modes := Src.Modes;
end;

end.

