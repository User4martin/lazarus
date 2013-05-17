{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

-------------------------------------------------------------------------------}

unit SynEditTextTrimmer;

{$I synedit.inc}

interface

uses
LCLProc,
  Classes, SysUtils, LazSynEditText, SynEditTextBase, SynEditTypes, SynEditHighlighter,
  SynEditPointClasses, SynEditMiscProcs;

type

  TSynEditStringTrimmingType = (settLeaveLine, settEditLine, settMoveCaret,
                                settIgnoreAll);

  TSynEditStringTrimmingList = class;

  { TLazSynDisplayTrim }

  TLazSynDisplayTrim = class(TLazSynDisplayViewEx)
  private
    FTrimer: TSynEditStringTrimmingList;
    FTempLineStringForPChar: String;
    FAtLineStart: Boolean;
  public
    constructor Create(ATrimer: TSynEditStringTrimmingList);
    procedure FinishHighlighterTokens; override;
    procedure SetHighlighterTokensLine(ALine: TLineIdx; out ARealLine: TLineIdx); override;
    function  GetNextHighlighterToken(out ATokenInfo: TLazSynDisplayTokenInfo): Boolean; override;
  end;

  { TSynEditStringTrimmingList }

  TSynEditStringTrimmingList = class(TSynEditStringsLinked)
  private
    fCaret: TSynEditCaret;
    FIsTrimming: Boolean;
    FTrimType: TSynEditStringTrimmingType;
    fSpaces: String;
    fLineText: String;
    fLineIndex: Integer;
    fEnabled: Boolean;
    FUndoTrimmedSpaces: Boolean;
    fLockCount: Integer;
    fLockList : TStringList;
    FLineEdited: Boolean;
    FTempLineStringForPChar: String; // experimental; used by GetPChar;
    FViewChangeStamp: int64;
    FDisplayView: TLazSynDisplayTrim;
    procedure MaybeAddUndoForget(APosY: Integer; AText: String);
    procedure DoCaretChanged(Sender : TObject);
    procedure ListCleared(Sender: TObject);
    Procedure LinesChanged(Sender: TSynEditStrings; AIndex, ACount : Integer);
    Procedure LineCountChanged(Sender: TSynEditStrings; AIndex, ACount : Integer);
    procedure DoLinesChanged(Index, N: integer);
    procedure SetEnabled(const AValue : Boolean);
    procedure SetTrimType(const AValue: TSynEditStringTrimmingType);
    function  TrimLine(const S : String; Index: Integer; RealUndo: Boolean = False) : String;
    procedure StoreSpacesForLine(const Index: Integer; const SpaceStr, LineStr: String);
    function  Spaces(Index: Integer) : String;
    procedure TrimAfterLock;
    procedure EditInsertTrim(LogX, LogY: Integer; AText: String);
    function  EditDeleteTrim(LogX, LogY, ByteLen: Integer): String;
    procedure EditMoveToTrim(LogY, Len: Integer);
    procedure EditMoveFromTrim(LogY, Len: Integer);
    procedure UpdateLineText(LogY: Integer);
    procedure IncViewChangeStamp;
  protected
    function GetViewChangeStamp: int64; override;
    function  GetExpandedString(Index: integer): string; override;
    function  GetLengthOfLongestLine: integer; override;
    function  Get(Index: integer): string; override;
    function  GetObject(Index: integer): TObject; override;
    procedure Put(Index: integer; const S: string); override;
    procedure PutObject(Index: integer; AObject: TObject); override;
    function  GetPCharSpaces(ALineIndex: Integer; out ALen: Integer): PChar; // experimental
    function GetDisplayView: TLazSynDisplayView; override;
  public
    constructor Create(ASynStringSource: TSynEditStrings; ACaret: TSynEditCaret);
    destructor Destroy; override;

    function Add(const S: string): integer; override;
    procedure AddStrings(AStrings: TStrings); override;
    procedure Clear; override;
    procedure Delete(Index: integer); override;
    procedure DeleteLines(Index, NumLines: integer);  override;
    procedure Insert(Index: integer; const S: string); override;
    procedure InsertLines(Index, NumLines: integer); override;
    procedure InsertStrings(Index: integer; NewStrings: TStrings); override;
    function  GetPChar(ALineIndex: Integer; out ALen: Integer): PChar; override; // experimental
    procedure Exchange(Index1, Index2: integer); override;
    property LengthOfLongestLine: integer read GetLengthOfLongestLine;
  public
    procedure Lock;
    procedure UnLock;
    procedure ForceTrim; // for redo; redo can not wait for UnLock
    property Enabled : Boolean read fEnabled write SetEnabled;
    property UndoTrimmedSpaces: Boolean read FUndoTrimmedSpaces write FUndoTrimmedSpaces; // deprecated 'not implemented';

    property IsTrimming: Boolean read FIsTrimming;
    property TrimType: TSynEditStringTrimmingType read FTrimType write SetTrimType;
  public
    procedure EditInsert(LogX, LogY: Integer; AText: String); override;
    Function  EditDelete(LogX, LogY, ByteLen: Integer): String; override;
    procedure EditLineBreak(LogX, LogY: Integer); override;
    procedure EditLineJoin(LogY: Integer; FillText: String = ''); override;
    procedure EditLinesInsert(LogY, ACount: Integer; AText: String = ''); override;
    procedure EditLinesDelete(LogY, ACount: Integer); override;
    procedure EditUndo(Item: TSynEditUndoItem); override;
    procedure EditRedo(Item: TSynEditUndoItem); override;
  end;

implementation

{off $Define SynTrimUndoDebug}
{off $Define SynTrimDebug}
{$IFDEF SynUndoDebug}
  {$Define SynUndoDebugItems}
  {$Define SynTrimUndoDebug}
{$ENDIF}

type

  { TSynEditUndoTrimMoveTo }

  TSynEditUndoTrimMoveTo = class(TSynEditUndoItem)
  private
    FPosY, FLen: Integer;
  protected
    function DebugString: String; override;
  public
    constructor Create(APosY, ALen: Integer);
    function PerformUndo(Caller: TObject): Boolean; override;
  end;

  { TSynEditUndoTrimMoveFrom }

  TSynEditUndoTrimMoveFrom = class(TSynEditUndoItem)
  private
    FPosY, FLen: Integer;
  protected
    function DebugString: String; override;
  public
    constructor Create(APosY, ALen: Integer);
    function PerformUndo(Caller: TObject): Boolean; override;
  end;

  { TSynEditUndoTrimInsert }

  TSynEditUndoTrimInsert = class(TSynEditUndoItem)
  private
    FPosX, FPosY, FLen: Integer;
  protected
    function DebugString: String; override;
  public
    constructor Create(APosX, APosY, ALen: Integer);
    function PerformUndo(Caller: TObject): Boolean; override;
  end;

  { TSynEditUndoTrimDelete }

  TSynEditUndoTrimDelete = class(TSynEditUndoItem)
  private
    FPosX, FPosY: Integer;
    FText: String;
  protected
    function DebugString: String; override;
  public
    constructor Create(APosX, APosY: Integer; AText: String);
    function PerformUndo(Caller: TObject): Boolean; override;
  end;

  { TSynEditUndoTrimForget }

  TSynEditUndoTrimForget = class(TSynEditUndoItem)
  private
    FPosY: Integer;
    FText: String;
  protected
    function DebugString: String; override;
  public
    constructor Create(APosY: Integer; AText: String);
    function PerformUndo(Caller: TObject): Boolean; override;
  end;

{ TLazSynDisplayTrim }

constructor TLazSynDisplayTrim.Create(ATrimer: TSynEditStringTrimmingList);
begin
  inherited Create;
  FTrimer := ATrimer;
end;

procedure TLazSynDisplayTrim.FinishHighlighterTokens;
begin
  inherited FinishHighlighterTokens;
  FTempLineStringForPChar := '';
end;

procedure TLazSynDisplayTrim.SetHighlighterTokensLine(ALine: TLineIdx; out ARealLine: TLineIdx);
begin
  CurrentTokenLine := ALine;
  FAtLineStart := True;
  inherited SetHighlighterTokensLine(ALine, ARealLine);
end;

function TLazSynDisplayTrim.GetNextHighlighterToken(out ATokenInfo: TLazSynDisplayTokenInfo): Boolean;
begin
  Result := False;
  if not Initialized then exit;

  if (CurrentTokenHighlighter = nil) and (FTrimer.Spaces(CurrentTokenLine) <> '') then begin
    Result := FAtLineStart;
    if not Result then exit;

    FTempLineStringForPChar := FTrimer[CurrentTokenLine];
    ATokenInfo.TokenStart := PChar(FTempLineStringForPChar);
    ATokenInfo.TokenLength := length(FTempLineStringForPChar);
    ATokenInfo.TokenAttr := nil;
    FAtLineStart := False;
    exit;
  end;

  // highlighter currently includes trimed spaces
  Result := inherited GetNextHighlighterToken(ATokenInfo);
end;

{ TSynEditUndoTrimMoveTo }

function TSynEditUndoTrimMoveTo.DebugString: String;
begin
  Result := 'FPosY='+IntToStr(FPosY)+' FLen='+IntToStr(FLen);
end;

constructor TSynEditUndoTrimMoveTo.Create(APosY, ALen: Integer);
begin
  FPosY := APosY;
  FLen :=  ALen;
  {$IFDEF SynTrimUndoDebug}debugln(['--- Trimmer Undo Insert ',DbgSName(self), ' ', dbgs(Self), ' - ', DebugString]);{$ENDIF}
end;

function TSynEditUndoTrimMoveTo.PerformUndo(Caller: TObject): Boolean;
begin
  Result := Caller is TSynEditStringTrimmingList;
  if Result then begin
  {$IFDEF SynTrimUndoDebug}debugln(['--- Trimmer Undo Perform ',DbgSName(self), ' ', dbgs(Self), ' - ', DebugString]);{$ENDIF}
    with TSynEditStringTrimmingList(Caller) do begin
      EditMoveFromTrim(FPosY, FLen);
      SendNotification(senrLineChange, TSynEditStringTrimmingList(Caller),
                       FPosY - 1, 1);
    end;
  end;
end;

{ TSynEditUndoTrimMoveFrom }

function TSynEditUndoTrimMoveFrom.DebugString: String;
begin
  Result := 'FPosY='+IntToStr(FPosY)+' FLen='+IntToStr(FLen);
end;

constructor TSynEditUndoTrimMoveFrom.Create(APosY, ALen: Integer);
begin
  FPosY := APosY;
  FLen :=  ALen;
  {$IFDEF SynTrimUndoDebug}debugln(['--- Trimmer Undo Insert ',DbgSName(self), ' ', dbgs(Self), ' - ', DebugString]);{$ENDIF}
end;

function TSynEditUndoTrimMoveFrom.PerformUndo(Caller: TObject): Boolean;
begin
  Result := Caller is TSynEditStringTrimmingList;
  if Result then begin
  {$IFDEF SynTrimUndoDebug}debugln(['--- Trimmer Undo Perform ',DbgSName(self), ' ', dbgs(Self), ' - ', DebugString]);{$ENDIF}
    with TSynEditStringTrimmingList(Caller) do begin
      EditMoveToTrim(FPosY, FLen);
      SendNotification(senrLineChange, TSynEditStringTrimmingList(Caller),
                       FPosY - 1, 1);
    end;
  end;
end;

{ TSynEditUndoTrimInsert }

function TSynEditUndoTrimInsert.DebugString: String;
begin
  Result := 'FPosY='+IntToStr(FPosY)+' FPosX='+IntToStr(FPosX)+' FLen='+IntToStr(FLen);
end;

constructor TSynEditUndoTrimInsert.Create(APosX, APosY, ALen: Integer);
begin
  FPosX := APosX;
  FPosY := APosY;
  FLen :=  ALen;
  {$IFDEF SynTrimUndoDebug}debugln(['--- Trimmer Undo Insert ',DbgSName(self), ' ', dbgs(Self), ' - ', DebugString]);{$ENDIF}
end;

function TSynEditUndoTrimInsert.PerformUndo(Caller: TObject): Boolean;
begin
  Result := Caller is TSynEditStringTrimmingList;
  if Result then begin
  {$IFDEF SynTrimUndoDebug}debugln(['--- Trimmer Undo Perform ',DbgSName(self), ' ', dbgs(Self), ' - ', DebugString]);{$ENDIF}
    with TSynEditStringTrimmingList(Caller) do begin
      EditDeleteTrim(FPosX, FPosY, FLen);
      SendNotification(senrLineChange, TSynEditStringTrimmingList(Caller),
                       FPosY - 1, 1);
      SendNotification(senrEditAction, TSynEditStringTrimmingList(Caller),
                       FPosY, 0, length(fSynStrings[FPosY-1]) + FPosX - 1, -FLen, '');
    end;
  end;
end;

{ TSynEditUndoTrimDelete }

function TSynEditUndoTrimDelete.DebugString: String;
begin
  Result := 'FPosY='+IntToStr(FPosY)+' FPosX='+IntToStr(FPosX)+' FText="'+FText+'"';
end;

constructor TSynEditUndoTrimDelete.Create(APosX, APosY: Integer; AText: String);
begin
  FPosX := APosX;
  FPosY := APosY;
  FText :=  AText;
  {$IFDEF SynTrimUndoDebug}debugln(['--- Trimmer Undo Insert ',DbgSName(self), ' ', dbgs(Self), ' - ', DebugString]);{$ENDIF}
end;

function TSynEditUndoTrimDelete.PerformUndo(Caller: TObject): Boolean;
begin
  Result := Caller is TSynEditStringTrimmingList;
  if Result then begin
  {$IFDEF SynTrimUndoDebug}debugln(['--- Trimmer Undo Perform ',DbgSName(self), ' ', dbgs(Self), ' - ', DebugString]);{$ENDIF}
    with TSynEditStringTrimmingList(Caller) do begin
      EditInsertTrim(FPosX, FPosY, FText);
      SendNotification(senrLineChange, TSynEditStringTrimmingList(Caller),
                       FPosY - 1, 1);
      SendNotification(senrEditAction, TSynEditStringTrimmingList(Caller),
                       FPosY, 0, length(fSynStrings[FPosY-1]) + FPosX - 1, length(FText), FText);
    end;
  end;
end;

{ TSynEditUndoTrimForget }

function TSynEditUndoTrimForget.DebugString: String;
begin
  Result := 'FPosY='+IntToStr(FPosY)+' FText="'+FText+'"';
end;

constructor TSynEditUndoTrimForget.Create(APosY: Integer; AText: String);
begin
  FPosY := APosY;
  FText :=  AText;
  {$IFDEF SynTrimUndoDebug}debugln(['--- Trimmer Undo Insert ',DbgSName(self), ' ', dbgs(Self), ' - ', DebugString]);{$ENDIF}
end;

function TSynEditUndoTrimForget.PerformUndo(Caller: TObject): Boolean;
begin
  Result := Caller is TSynEditStringTrimmingList;
  if Result then begin
  {$IFDEF SynTrimUndoDebug}debugln(['--- Trimmer Undo Perform ',DbgSName(self), ' ', dbgs(Self), ' - ', DebugString]);{$ENDIF}
    with TSynEditStringTrimmingList(Caller) do begin
      CurUndoList.Lock;
      EditInsertTrim(1, FPosY, FText);
      CurUndoList.Unlock;
      SendNotification(senrLineChange, TSynEditStringTrimmingList(Caller),
                       FPosY - 1, 1);
      SendNotification(senrEditAction, TSynEditStringTrimmingList(Caller),
                       FPosY, 0, length(fSynStrings[FPosY-1]), length(FText), FText);
    end;
  end;
end;



function LastNoneSpacePos(const s: String): Integer;
begin
  Result := length(s);
  while (Result > 0) and (s[Result] in [#9, ' ']) do dec(Result);
end;

{ TSynEditStringTrimmingList }

constructor TSynEditStringTrimmingList.Create(ASynStringSource : TSynEditStrings; ACaret: TSynEditCaret);
begin
  fCaret := ACaret;
  fCaret.AddChangeHandler(@DoCaretChanged);
  fLockList := TStringList.Create;
  FDisplayView := TLazSynDisplayTrim.Create(Self);
  FDisplayView.NextView := ASynStringSource.DisplayView;
  fLineIndex:= -1;
  fSpaces := '';
  fEnabled:=false;
  FUndoTrimmedSpaces := False;
  FIsTrimming := False;
  FLineEdited := False;
  FTrimType := settLeaveLine;
  Inherited Create(ASynStringSource);
  fSynStrings.AddChangeHandler(senrLineCount, {$IFDEF FPC}@{$ENDIF}LineCountChanged);
  fSynStrings.AddChangeHandler(senrLineChange, {$IFDEF FPC}@{$ENDIF}LinesChanged);
  fSynStrings.AddNotifyHandler(senrCleared, {$IFDEF FPC}@{$ENDIF}ListCleared);
end;

destructor TSynEditStringTrimmingList.Destroy;
begin
  fSynStrings.RemoveChangeHandler(senrLineCount, {$IFDEF FPC}@{$ENDIF}LineCountChanged);
  fSynStrings.RemoveChangeHandler(senrLineChange, {$IFDEF FPC}@{$ENDIF}LinesChanged);
  fSynStrings.RemoveNotifyHandler(senrCleared, {$IFDEF FPC}@{$ENDIF}ListCleared);
  fCaret.RemoveChangeHandler(@DoCaretChanged);
  FreeAndNil(FDisplayView);
  FreeAndNil(fLockList);
  inherited Destroy;
end;

procedure TSynEditStringTrimmingList.MaybeAddUndoForget(APosY: Integer; AText: String);
var
  L: TSynEditUndoItem;
begin
  if (FTrimType = settIgnoreAll) then begin
    L := CurUndoList.GetLastChange;
    if (L <> nil) and (L is TSynEditUndoTrimInsert) and
       (TSynEditUndoTrimInsert(L).FPosY = APosY)
    then begin
      {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- MaybeAddUndoForget - removing last undo']);{$ENDIF}
      CurUndoList.PopLastChange.Free;
      exit;
    end;
  end;

  CurUndoList.AppendToLastChange(TSynEditUndoTrimForget.Create(APosY, AText));
end;

procedure TSynEditStringTrimmingList.DoCaretChanged(Sender : TObject);
var
  s: String;
  i, j: Integer;
begin
  if (not fEnabled) then exit;
  if (fLockCount > 0) or (length(fSpaces) = 0) or
     (fLineIndex < 0) or (fLineIndex >= fSynStrings.Count) or
     ( (fLineIndex = TSynEditCaret(Sender).LinePos - 1) and
       ( (FTrimType in [settLeaveLine]) or
         ((FTrimType in [settEditLine]) and not FLineEdited) ))
  then begin
    if (fLineIndex <> TSynEditCaret(Sender).LinePos - 1) then begin
    {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- CaretChnaged - Clearing 1 ', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces), 'newCaretYPos=',TSynEditCaret(Sender).LinePos]);{$ENDIF}
      if fSpaces <> '' then IncViewChangeStamp;
      fLineIndex := TSynEditCaret(Sender).LinePos - 1;
      fSpaces := '';
    end;
    exit;
  end;

  FIsTrimming := True;
  IncViewChangeStamp;
  if (fLineIndex <> TSynEditCaret(Sender).LinePos - 1) or
     (FTrimType = settIgnoreAll) then
  begin
    {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- CaretChnaged - Trimming,clear 1 ', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces), 'newCaretYPos=',TSynEditCaret(Sender).LinePos]);{$ENDIF}
    MaybeAddUndoForget(FLineIndex+1, FSpaces);
    i := length(FSpaces);
    fSpaces := '';
    //TSynEditCaret(Sender).InvalidateBytePos; // tabs at EOL may now be spaces // Fixes-Merge: caret does not store a permament byte pos in fixes
    SendNotification(senrLineChange, self, fLineIndex, 1);
    SendNotification(senrEditAction, self, FLineIndex+1, 0,
                     1+length(fSynStrings[FLineIndex]), -i, '');
  end else begin
    // same line, only right of caret
    s := fSynStrings[fLineIndex];
    i := TSynEditCaret(Sender).BytePos;
    if i <= length(s) + 1 then
      j := 0
    else
      j := i - length(s) - 1;
    s := copy(FSpaces, j + 1, MaxInt);
    {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- CarteChnaged - Trimming,part to ',length(s),' ', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces), 'newCaretYPos=',TSynEditCaret(Sender).LinePos]);{$ENDIF}
    FSpaces := copy(FSpaces, 1, j);
    i := length(s);
    MaybeAddUndoForget(FLineIndex+1, s);
    SendNotification(senrLineChange, self, fLineIndex, 1);
    SendNotification(senrEditAction, self, FLineIndex+1, 0,
                     1+length(fSynStrings[FLineIndex]) + length(FSpaces), -i, '');
  end;
  FIsTrimming := False;
  FLineEdited := False;
  fLineIndex := TSynEditCaret(Sender).LinePos - 1;
end;

procedure TSynEditStringTrimmingList.ListCleared(Sender: TObject);
begin
    {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- LIST CLEARED ', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces) ]);{$ENDIF}
  if fSpaces <> '' then IncViewChangeStamp;
  fLockList.Clear;
  fLineIndex:= -1;
  fSpaces := '';
end;

procedure TSynEditStringTrimmingList.LinesChanged(Sender: TSynEditStrings; AIndex, ACount: Integer);
begin
  if FIsTrimming then
    exit;
  FLineEdited := true;
  if fLockCount = 0 then
    DoCaretChanged(fCaret);
end;

procedure TSynEditStringTrimmingList.LineCountChanged(Sender: TSynEditStrings;
  AIndex, ACount: Integer);
begin
  DoLinesChanged(AIndex, ACount);
  LinesChanged(Sender, AIndex, ACount);
end;

procedure TSynEditStringTrimmingList.DoLinesChanged(Index, N : integer);
var
  i, j: Integer;
begin
  if (not fEnabled) then exit;
  IncViewChangeStamp;
  if  fLockCount > 0 then begin
    {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- Lines Changed (ins/del)  locked ', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces) ]);{$ENDIF}
    for i := fLockList.Count-1 downto 0 do begin
      j := Integer(PtrUInt(Pointer(fLockList.Objects[i])));
      if (j >= Index) and (j < Index - N) then
        fLockList.Delete(i)
      else if j >= Index then
        fLockList.Objects[i] := TObject(Pointer(j + N));
    end;
  end else begin
    {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- Lines Changed (ins/del) not locked ', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces) ]);{$ENDIF}
    if (fLineIndex >= Index) and (fLineIndex < Index - N) then
      fLineIndex:=-1
    else if fLineIndex > Index then
      inc(fLineIndex, N);
  end;
end;

procedure TSynEditStringTrimmingList.SetEnabled(const AValue : Boolean);
begin
  if fEnabled = AValue then exit;
  fEnabled:=AValue;
  fLockList.Clear;
  fLockCount:=0;
  FSpaces := '';
  FLineIndex := -1;
  FLockList.Clear;
  FIsTrimming := True;
  FLineEdited := False;
  if fEnabled and (fLineIndex >= 0) and (fLineIndex < fSynStrings.Count) then
    fSynStrings[fLineIndex] := TrimLine(fSynStrings[fLineIndex], fLineIndex);
  FIsTrimming := False;
end;

procedure TSynEditStringTrimmingList.SetTrimType(const AValue: TSynEditStringTrimmingType);
begin
  if FTrimType = AValue then exit;
  FTrimType := AValue;
end;

function TSynEditStringTrimmingList.TrimLine(const S: String; Index: Integer;
         RealUndo: Boolean = False): String;
var
  l, i:integer;
  temp: String;
begin
  if (not fEnabled) then exit(s);
    {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- TrimLine ', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces), '  RealUndo=', RealUndo ]);{$ENDIF}
  if RealUndo then begin
    temp := fSynStrings.Strings[Index];
    l := length(temp);
    i := LastNoneSpacePos(temp);
    // Add RealSpaceUndo
    if i < l then
      EditInsertTrim(1, Index + 1,
                     inherited EditDelete(1 + i, Index + 1, l - i));
  end;

  l := length(s);
  i := LastNoneSpacePos(s);
  temp := copy(s, i+1, l-i);
  if i=l then
    result := s   // No need to make a copy
  else
    result := copy(s, 1, i);

  StoreSpacesForLine(Index, temp, Result);
end ;

procedure TSynEditStringTrimmingList.StoreSpacesForLine(const Index: Integer; const SpaceStr, LineStr: String);
var
  i: LongInt;
begin
  {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- StoreSpacesforLine ', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces), '  Index=', Index, ' Spacestr=',length(SpaceStr), ' LineStr=',length(LineStr),  '  fLockCount=',fLockCount]);{$ENDIF}
  if fLockCount > 0 then begin
    i := fLockList.IndexOfObject(TObject(pointer(PtrUInt(Index))));
    if i < 0 then
      fLockList.AddObject(SpaceStr, TObject(pointer(PtrUInt(Index))))
    else
      fLockList[i] := SpaceStr;
  end;
  if (fLineIndex = Index) then begin
    fSpaces := SpaceStr;
    fLineText:= LineStr;
  end;
end;

function TSynEditStringTrimmingList.Spaces(Index : Integer) : String;
var
  i : Integer;
begin
  if (not fEnabled) then exit('');
  if fLockCount > 0 then begin
    i := fLockList.IndexOfObject(TObject(Pointer(PtrUInt(Index))));
    if i < 0 then
      result := ''
    else
      result := fLockList[i];
  //{$IFDEF SynTrimDebug}debugln(['--- Trimmer -- Spaces (for line / locked)', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces), '  Index=', Index, ' Result=',length(Result)]);{$ENDIF}
    exit;
  end;
  if Index <> fLineIndex then exit('');
  if (fLineIndex < 0) or (fLineIndex >= fSynStrings.Count)
    or (fLineText <> fSynStrings[fLineIndex]) then begin
    if fSpaces <> '' then IncViewChangeStamp;
    fSpaces:='';
    fLineText:='';
  end;
  Result:= fSpaces;
  {$IFDEF SynTrimDebug}if length(Result) > 0 then debugln(['--- Trimmer -- Spaces (for line / not locked)', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces), '  Index=', Index, ' Result=',length(Result)]);{$ENDIF}
end;

procedure TSynEditStringTrimmingList.Lock;
begin
  if (fLockCount = 0) and (fLineIndex >= 0) and Enabled then begin
    fLockList.AddObject(Spaces(fLineIndex), TObject(Pointer(PtrUInt(fLineIndex))));
    FLineEdited := False;
  end;
  inc(fLockCount);
end;

procedure TSynEditStringTrimmingList.UnLock;
begin
  dec(fLockCount);
  if (fLockCount = 0) then TrimAfterLock;
  if (FTrimType = settIgnoreAll) then DoCaretChanged(fCaret);
end;

procedure TSynEditStringTrimmingList.TrimAfterLock;
var
  i, index, slen: Integer;
  ltext: String;
begin
  if (not fEnabled) then exit;
  FIsTrimming := True;
  {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- TrimAfterLock', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces), '  Index=', Index, ' LockList=',fLockList.CommaText]);{$ENDIF}
  i := fLockList.IndexOfObject(TObject(Pointer(PtrUInt(fLineIndex))));
  if i >= 0 then begin
    if fSpaces <> fLockList[i] then
      IncViewChangeStamp;
    fSpaces:= fLockList[i];
    if (fLineIndex >= 0) and (fLineIndex < fSynStrings.Count) then
      fLineText := fSynStrings[fLineIndex];
    fLockList.Delete(i);
    DoCaretChanged(fCaret);
  end
  else if fSpaces <> '' then
    IncViewChangeStamp;
  FIsTrimming := True;
  BeginUpdate;
  if fLockList.Count > 0 then
    IncViewChangeStamp;
  try
    for i := 0 to fLockList.Count-1 do begin
      index := Integer(PtrUInt(Pointer(fLockList.Objects[i])));
      slen := length(fLockList[i]);
      if (slen > 0) and (index >= 0) and (index < fSynStrings.Count) then begin
        ltext := fSynStrings[index];
        fSynStrings[index] := ltext;                                            // trigger OnPutted, so the line gets repainted
        MaybeAddUndoForget(Index+1, fLockList[i]);
      end;
    end;
  finally
    EndUpdate;
    FIsTrimming := False;
  end;
  FLineEdited := False;
  fLockList.Clear;
end;

procedure TSynEditStringTrimmingList.ForceTrim;
begin
  FlushNotificationCache;
  DoCaretChanged(fCaret); // Caret May be locked
  TrimAfterLock;
end;

// Lines
function TSynEditStringTrimmingList.GetExpandedString(Index : integer) : string;
begin
  Result:= fSynStrings.ExpandedStrings[Index] + Spaces(Index);
end;

function TSynEditStringTrimmingList.GetLengthOfLongestLine : integer;
var
  i: Integer;
begin
  Result:= fSynStrings.LengthOfLongestLine;
  if (fLineIndex >= 0) and (fLineIndex < Count) then begin
    i:= length(ExpandedStrings[fLineIndex]);
    if (i > Result) then Result := i;
  end;
end;

function TSynEditStringTrimmingList.Get(Index : integer) : string;
begin
  Result:= fSynStrings.Strings[Index] + Spaces(Index);
end;

function TSynEditStringTrimmingList.GetObject(Index : integer) : TObject;
begin
  Result:= fSynStrings.Objects[Index];
end;

procedure TSynEditStringTrimmingList.Put(Index : integer; const S : string);
begin
  FLineEdited := True;
  fSynStrings.Strings[Index]:= TrimLine(S, Index, True);
end;

procedure TSynEditStringTrimmingList.PutObject(Index : integer; AObject : TObject);
begin
  FLineEdited := True;
  fSynStrings.Objects[Index]:= AObject;
end;

function TSynEditStringTrimmingList.Add(const S : string) : integer;
var
  c : Integer;
begin
  FLineEdited := True;
  c := fSynStrings.Count;
  Result := fSynStrings.Add(TrimLine(S, c));
end;

procedure TSynEditStringTrimmingList.AddStrings(AStrings : TStrings);
var
  i, c : Integer;
begin
  c := fSynStrings.Count;
  for i := 0 to AStrings.Count-1 do
    AStrings[i] := TrimLine(AStrings[i], c + i);
  fSynStrings.AddStrings(AStrings);
end;

procedure TSynEditStringTrimmingList.Clear;
begin
  fSynStrings.Clear;
  fLineIndex:=-1;
end;

procedure TSynEditStringTrimmingList.Delete(Index : integer);
begin
  FLineEdited := True;
  TrimLine('', Index, True);
  fSynStrings.Delete(Index);
end;

procedure TSynEditStringTrimmingList.DeleteLines(Index, NumLines : integer);
var
  i: Integer;
begin
  FLineEdited := True;
  for i := 0 to NumLines-1 do
    TrimLine('', Index+i, True);
  fSynStrings.DeleteLines(Index, NumLines);
end;

procedure TSynEditStringTrimmingList.Insert(Index : integer; const S : string);
begin
  FLineEdited := True;
  fSynStrings.Insert(Index, TrimLine(S, Index));
end;

procedure TSynEditStringTrimmingList.InsertLines(Index, NumLines : integer);
begin
  FLineEdited := True;
  fSynStrings.InsertLines(Index, NumLines);
end;

procedure TSynEditStringTrimmingList.InsertStrings(Index : integer; NewStrings : TStrings);
var
  i : Integer;
begin
  FLineEdited := True;
  for i := 0 to NewStrings.Count-1 do
    NewStrings[i] := TrimLine(NewStrings[i], Index+i, True);
  fSynStrings.InsertStrings(Index, NewStrings);
end;

function TSynEditStringTrimmingList.GetPCharSpaces(ALineIndex: Integer; out
  ALen: Integer): PChar;
begin
  FTempLineStringForPChar := Get(ALineIndex);
  ALen := length(FTempLineStringForPChar);
  Result := PChar(FTempLineStringForPChar);
end;

function TSynEditStringTrimmingList.GetDisplayView: TLazSynDisplayView;
begin
  Result := FDisplayView;
end;

function TSynEditStringTrimmingList.GetPChar(ALineIndex: Integer; out ALen: Integer): PChar;
begin
  Result := inherited GetPChar(ALineIndex, ALen);

  // check if we need to apend spaces
  if (not fEnabled) then exit;
  if (fLockCount = 0) and (fLineIndex <> ALineIndex) then exit;
  if (fLockCount > 0) and (fLockList.IndexOfObject(TObject(Pointer(PtrUInt(ALineIndex)))) < 0) then exit;

  Result:= GetPCharSpaces(ALineIndex, ALen);
end;

procedure TSynEditStringTrimmingList.Exchange(Index1, Index2 : integer);
begin
  FLineEdited := True;
  fSynStrings.Exchange(Index1, Index2);
  if fLineIndex = Index1 then
    fLineIndex := Index2
  else if fLineIndex = Index2 then
    fLineIndex := Index1;
end;

procedure TSynEditStringTrimmingList.EditInsertTrim(LogX, LogY: Integer;
  AText: String);
var
  s: string;
begin
  if (AText = '') then
    exit;
  {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- EditInsertTrim', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces), '  X=', LogX, ' Y=',LogY, ' text=',length(AText)]);{$ENDIF}
  s := Spaces(LogY - 1);
  StoreSpacesForLine(LogY - 1,
                     copy(s,1, LogX - 1) + AText + copy(s, LogX, length(s)),
                     fSynStrings.Strings[LogY - 1]);
  CurUndoList.AddChange(TSynEditUndoTrimInsert.Create(LogX, LogY, Length(AText)));
  IncViewChangeStamp;
end;

function TSynEditStringTrimmingList.EditDeleteTrim(LogX, LogY, ByteLen:
  Integer): String;
var
  s: string;
begin
  if (ByteLen <= 0) then
    exit('');
  {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- EditDeleteTrim()', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces), '  X=', LogX, ' Y=',LogY, ' ByteLen=',ByteLen]);{$ENDIF}
  s := Spaces(LogY - 1);
  Result := copy(s, LogX, ByteLen);
  StoreSpacesForLine(LogY - 1,
                     copy(s,1, LogX - 1) + copy(s, LogX +  ByteLen, length(s)),
                     fSynStrings.Strings[LogY - 1]);
  if Result <> '' then
    CurUndoList.AddChange(TSynEditUndoTrimDelete.Create(LogX, LogY, Result));
  IncViewChangeStamp;
end;

procedure TSynEditStringTrimmingList.EditMoveToTrim(LogY, Len: Integer);
var
  t, s: String;
begin
  if Len <= 0 then
    exit;
  {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- EditMoveToTrim()', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces), ' Y=',LogY, '  len=',Len]);{$ENDIF}
  t := fSynStrings[LogY - 1];
  s := copy(t, 1 + length(t) - Len, Len) + Spaces(LogY - 1);
  t := copy(t, 1, length(t) - Len);
  StoreSpacesForLine(LogY - 1, s, t);
  fSynStrings[LogY - 1] := t;
  CurUndoList.AddChange(TSynEditUndoTrimMoveTo.Create(LogY, Len));
  IncViewChangeStamp;
end;

procedure TSynEditStringTrimmingList.EditMoveFromTrim(LogY, Len: Integer);
var
  t, s: String;
begin
  if Len <= 0 then
    exit;
  {$IFDEF SynTrimDebug}debugln(['--- Trimmer -- EditMoveFromTrim()', ' fLineIndex=', fLineIndex, ' fSpaces=',length(fSpaces), ' Y=',LogY, '  len=',Len]);{$ENDIF}
  s := Spaces(LogY - 1);
  t := fSynStrings[LogY - 1] + copy(s, 1, Len);
  s := copy(s, 1 + Len, length(s));
  StoreSpacesForLine(LogY - 1, s, t);
  fSynStrings[LogY - 1] := t;
  CurUndoList.AddChange(TSynEditUndoTrimMoveFrom.Create(LogY, Len));
  IncViewChangeStamp;
end;

procedure TSynEditStringTrimmingList.UpdateLineText(LogY: Integer);
begin
  if LogY - 1 = fLineIndex then
    fLineText := fSynStrings[LogY - 1];
end;

procedure TSynEditStringTrimmingList.IncViewChangeStamp;
begin
  {$PUSH}{$Q-}{$R-}
  FViewChangeStamp := FViewChangeStamp + 1;
  {$POP}
end;

function TSynEditStringTrimmingList.GetViewChangeStamp: int64;
begin
  Result := inherited GetViewChangeStamp;
  {$PUSH}{$Q-}{$R-}
  Result := Result + FViewChangeStamp;
  {$POP}
end;

procedure TSynEditStringTrimmingList.EditInsert(LogX, LogY: Integer; AText: String);
var
  t: String;
  Len, LenNS, SaveLogX: Integer;
  IsSpaces: Boolean;
  SaveText: String;
begin
  if (not fEnabled) then begin
    fSynStrings.EditInsert(LogX, LogY, AText);
    exit;
  end;

  IncIsInEditAction;
  if Count = 0 then fSynStrings.Add('');
  FlushNotificationCache;
  IgnoreSendNotification(senrEditAction, True);
  SaveText := AText;
  SaveLogX := LogX;
  t := Strings[LogY - 1];  // include trailing
  if LogX - 1 > Length(t) then begin
    AText := StringOfChar(' ', LogX - 1 - Length(t)) + AText;
    LogX := 1 + Length(t);
  end;
  IsSpaces := LastNoneSpacePos(AText) = 0;
  t := fSynStrings[LogY - 1];
  Len := length(t);
  LenNS := LastNoneSpacePos(t);
  if (LenNS < LogX - 1) and not IsSpaces then
    LenNs := LogX - 1;

  // Trim any existing (committed/real) spaces // skip if we append none-spaces
  if (LenNS < Len) and (IsSpaces or (LogX <= len)) then
  begin
    EditMoveToTrim(LogY, Len - LenNS);
    Len := LenNS;
  end;

  if LogX > len then begin
    if IsSpaces then begin
      EditInsertTrim(LogX - Len, LogY, AText);
      AText := '';
    end else begin
      // Get Fill Spaces
      EditMoveFromTrim(LogY, LogX - 1 - len);
      // Trim
      Len := length(AText);
      LenNS := LastNoneSpacePos(AText);
      if LenNS < Len then begin
        EditInsertTrim(1, LogY, copy(AText, 1 + LenNS, Len));
        AText := copy(AText, 1, LenNS);
      end;
    end;
  end;

  if AText <> '' then
    inherited EditInsert(LogX, LogY, AText)
  else
    SendNotification(senrLineChange, self, LogY - 1, 1);

  // update spaces
  UpdateLineText(LogY);
  IgnoreSendNotification(senrEditAction, False);
  SendNotification(senrEditAction, self, LogY, 0, SaveLogX, length(SaveText), SaveText);
  DecIsInEditAction;
end;

function TSynEditStringTrimmingList.EditDelete(LogX, LogY, ByteLen: Integer): String;
var
  t: String;
  Len: Integer;
  SaveByteLen: LongInt;
begin
  if (not fEnabled) then begin
    fSynStrings.EditDelete(LogX, LogY, ByteLen);
    exit;
  end;

  IncIsInEditAction;
  FlushNotificationCache;
  SaveByteLen := ByteLen;
  Result := '';
  t := fSynStrings[LogY - 1];
  Len := length(t);

  IgnoreSendNotification(senrEditAction, True);
  // Delete uncommited spaces (could laso be ByteLen too big, due to past EOL)
  if LogX + ByteLen > Len + 1 then begin
    if LogX > Len + 1 then
      ByteLen := ByteLen - (LogX - (Len + 1));
    Result := EditDeleteTrim(max(LogX - Len, 1), LogY, LogX - 1 + ByteLen - Len);
    ByteLen :=  Len + 1 - LogX;
  end;

  if ByteLen > 0 then
    Result := inherited EditDelete(LogX, LogY, ByteLen) + Result
  else
  begin
    SendNotification(senrLineChange, self, LogY - 1, 1);
  end;
  UpdateLineText(LogY);

  // Trim any existing (committed/real) spaces
  t := fSynStrings[LogY - 1];
  EditMoveToTrim(LogY, length(t) - LastNoneSpacePos(t));

  IgnoreSendNotification(senrEditAction, False);
  SendNotification(senrEditAction, self, LogY, 0, LogX, -SaveByteLen, '');
  DecIsInEditAction;
end;

procedure TSynEditStringTrimmingList.EditLineBreak(LogX, LogY: Integer);
var
  s, t: string;
begin
  if (not fEnabled) then begin
    fSynStrings.EditLineBreak(LogX, LogY);
    exit;
  end;

  IncIsInEditAction;
  FlushNotificationCache;
  IgnoreSendNotification(senrEditAction, True);
  s := Spaces(LogY - 1);
  t := fSynStrings[LogY - 1];
  if LogX > length(t) then begin
    fSynStrings.EditLineBreak(1 + length(t), LogY);
    FlushNotificationCache; // senrEditaction is ignored, so we need to flush by hand
    if s <> '' then
      s := EditDeleteTrim(LogX - length(t), LogY, length(s) - (LogX - 1 - length(t)));
  end
  else begin
    s := EditDeleteTrim(1, LogY, length(s));
    fSynStrings.EditLineBreak(LogX, LogY);
    FlushNotificationCache; // senrEditaction is ignored, so we need to flush by hand
  end;
  UpdateLineText(LogY + 1);
  EditInsertTrim(1, LogY + 1, s);
  // Trim any existing (committed/real) spaces
  s := fSynStrings[LogY - 1];
  EditMoveToTrim(LogY, length(s) - LastNoneSpacePos(s));
  s := fSynStrings[LogY];
  EditMoveToTrim(LogY + 1, length(s) - LastNoneSpacePos(s));
  IgnoreSendNotification(senrEditAction, False);
  SendNotification(senrEditAction, self, LogY, 1, LogX, 0, '');
  DecIsInEditAction;
end;

procedure TSynEditStringTrimmingList.EditLineJoin(LogY: Integer;
  FillText: String = '');
var
  s: String;
begin
  if (not fEnabled) then begin
    fSynStrings.EditLineJoin(LogY, FillText);
    exit;
  end;

  IncIsInEditAction;
  FlushNotificationCache;
  EditMoveFromTrim(LogY, length(Spaces(LogY - 1)));

  s := EditDeleteTrim(1, LogY + 1, length(Spaces(LogY))); // next line
  //Todo: if FillText isSpacesOnly AND NextLineIsSpacesOnly => add direct to trailing
  fSynStrings.EditLineJoin(LogY, FillText);
  FlushNotificationCache; // senrEditaction is ignored, so we need to flush by hand
  UpdateLineText(LogY);
  EditInsertTrim(1, LogY, s);

  // Trim any existing (committed/real) spaces
  s := fSynStrings[LogY - 1];
  EditMoveToTrim(LogY, length(s) - LastNoneSpacePos(s));
  DecIsInEditAction;
end;

procedure TSynEditStringTrimmingList.EditLinesInsert(LogY, ACount: Integer;
  AText: String = '');
var
  s: string;
begin
  IncIsInEditAction;
  FlushNotificationCache;
  fSynStrings.EditLinesInsert(LogY, ACount, AText);
  s := fSynStrings[LogY - 1];
  EditMoveToTrim(LogY, length(s) - LastNoneSpacePos(s));
  DecIsInEditAction;
end;

procedure TSynEditStringTrimmingList.EditLinesDelete(LogY, ACount: Integer);
var
  i: Integer;
begin
  IncIsInEditAction;
  FlushNotificationCache;
  for i := LogY to LogY + ACount - 1 do
    EditMoveFromTrim(i, length(Spaces(i - 1)));
  fSynStrings.EditLinesDelete(LogY, ACount);
  DecIsInEditAction;
end;

procedure TSynEditStringTrimmingList.EditUndo(Item: TSynEditUndoItem);
begin
  EditRedo(Item);
end;

procedure TSynEditStringTrimmingList.EditRedo(Item: TSynEditUndoItem);
begin
  IncIsInEditAction; // all undo calls edit actions
  if not Item.PerformUndo(self) then
    inherited EditRedo(Item);
  DecIsInEditAction;
end;

end.

