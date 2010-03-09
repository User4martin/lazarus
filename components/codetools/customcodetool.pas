{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

  Author: Mattias Gaertner

  Abstract:
    TCustomCodeTool is the ancestor class for code tools which parses code
    beginning with the Main Source code. It can parse atoms, the smallest code
    elements in source code, create new code tree nodes and provides several
    useful functions for parsing and changing code.

}
unit CustomCodeTool;

{$ifdef FPC}{$mode objfpc}{$endif}{$H+}
{$inline on}

interface

{$I codetools.inc}

{ $DEFINE ShowIgnoreError}
{$DEFINE ShowDirtySrc}
{ $DEFINE VerboseUpdateNeeded}

uses
  {$IFDEF MEM_CHECK}
  MemCheck,
  {$ENDIF}
  Classes, SysUtils, FileProcs, CodeToolsStrConsts, CodeTree, CodeAtom,
  KeywordFuncLists, BasicCodeTools, LinkScanner, CodeCache,
  AVL_Tree;

const
  CodeToolPhaseNone  = 0;
  CodeToolPhaseScan  = 1;
  CodeToolPhaseParse = 2;
  CodeToolPhaseTool  = 3; // or higher

type
  TCustomCodeTool = class;


  // types for errors
  ECodeToolError = class(Exception)
    Sender: TCustomCodeTool;
    constructor Create(ASender: TCustomCodeTool; const AMessage: string);
  end;
  
  ECodeToolErrors = class of ECodeToolError;
  
  ECodeToolFileNotFound = class(ECodeToolError)
    Filename: string;
    constructor Create(ASender: TCustomCodeTool;
      const AMessage, AFilename: string);
  end;
  
  
  { TDirtySource - class to store a dirty source }

  TDirtySource = class
  public
    CursorPos: TCodeXYPosition;
    Src: string;
    GapSrc: string;
    Code: TCodeBuffer;
    Valid: boolean;
    CurPos: TAtomPosition;
    StartPos: integer;
    GapStart: integer;
    GapEnd: integer;
    LockCount: integer;
    Owner: TCustomCodeTool;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure SetGap(const NewCursorPos: TCodeXYPosition;
                   NewDirtyStartPos, NewDirtyGapStart, NewDirtyGapEnd: integer);
    constructor Create(TheOwner: TCustomCodeTool);
    procedure Clear;
    procedure SetCursorToIdentStartEndAtPosition;
    function GetCursorSrcPos: PChar;
    function IsPCharInSrc(p: PChar): boolean;
    procedure MoveCursorToPos(APos: integer);
    procedure MoveCursorToPos(APos: PChar);
    function CalcMemSize: PtrUInt;
  end;
  
  THybridCursorType = (
    hcClean,
    hcDirty
    );


  // types for user aborts
  TOnParserProgress = function(Tool: TCustomCodeTool): boolean of object;
  TCodeTreeChangeEvent = procedure(Tool: TCustomCodeTool;
                                   NodesDeleting: boolean) of object;
  TGetChangeStepEvent = procedure(out ChangeStep: integer) of object;

  EParserAbort = class(ECodeToolError)
  end;
  
  { TCustomCodeTool }

  TCustomCodeTool = class(TObject)
  private
    FLastProgressPos: integer;
    FLastScannerChangeStep: integer;
    FNodesDeletedChangeStep: integer;
    FOnGetGlobalWriteLockInfo: TOnGetWriteLockInfo;
    FOnParserProgress: TOnParserProgress;
    FOnSetGlobalWriteLock: TOnSetWriteLock;
    FScanner: TLinkScanner;
    FOnTreeChange: TCodeTreeChangeEvent;
    FTreeChangeStep: integer;
  protected
    FIgnoreErrorAfter: TCodePosition;
    KeyWordFuncList: TKeyWordFunctionList;
    WordIsKeyWordFuncList: TKeyWordFunctionList;
    FForceUpdateNeeded: boolean;
    function DefaultKeyWordFunc: boolean;
    procedure BuildDefaultKeyWordFunctions; virtual;
    procedure SetScanner(NewScanner: TLinkScanner); virtual;
    procedure DoDeleteNodes; virtual;
    procedure RaiseIdentExpectedButAtomFound;
    procedure RaiseBracketOpenExpectedButAtomFound;
    procedure RaiseBracketCloseExpectedButAtomFound;
    procedure RaiseUndoImpossible;
    procedure SetIgnoreErrorAfter(const AValue: TCodePosition); virtual;
    procedure IncreaseTreeChangeStep(NodesDeleting: boolean);
  protected
    LastErrorMessage: string;
    LastErrorCurPos: TAtomPosition;
    LastErrorPhase: integer;
    LastErrorValid: boolean;
    LastErrorBehindIgnorePosition: boolean;
    LastErrorCheckedForIgnored: boolean;
    LastErrorNicePosition: TCodeXYPosition;
    CurrentPhase: integer;
    procedure ClearLastError;
    procedure RaiseLastError;
    procedure DoProgress; inline;
    procedure NotifyAboutProgress;
    // dirty/dead source
    procedure LoadDirtySource(const CursorPos: TCodeXYPosition);
  public
    Tree: TCodeTree;

    // current Values, Position, Node ...
    CurPos: TAtomPosition;
    Src: string;
    SrcLen: integer;
    CurNode: TCodeTreeNode;
    LastAtoms: TAtomRing;
    NextPos: TAtomPosition;
    
    CheckFilesOnDisk: boolean;
    IndentSize: integer;
    VisibleEditorLines: integer;
    JumpCentered: boolean;
    CursorBeyondEOL: boolean;
    
    DirtySrc: TDirtySource;
    HybridCursorType: THybridCursorType;

    ErrorPosition: TCodeXYPosition;
    ErrorNicePosition: TCodeXYPosition;// if NiceErrorPosition is set, then it is in front of ErrorPosition

    property Scanner: TLinkScanner read FScanner write SetScanner;
    function MainFilename: string;
    property TreeChangeStep: integer read FTreeChangeStep;
    property NodesDeletedChangeStep: integer read FNodesDeletedChangeStep;
    property OnTreeChange: TCodeTreeChangeEvent read FOnTreeChange
                                                write FOnTreeChange;
    
    function FindDeepestNodeAtPos(P: integer;
      ExceptionOnNotFound: boolean): TCodeTreeNode; {$IFDEF UseInline}inline;{$ENDIF}
    function FindDeepestNodeAtPos(StartNode: TCodeTreeNode; P: integer;
      ExceptionOnNotFound: boolean): TCodeTreeNode;
    function CaretToCleanPos(Caret: TCodeXYPosition;
        out CleanPos: integer): integer;  // 0=valid CleanPos
                          //-1=CursorPos was skipped, CleanPos between two links
                          // 1=CursorPos beyond scanned code
                          //-2=X,Y beyond source
    function CleanPosToCodePos(CleanPos: integer;
        out CodePos:TCodePosition): boolean; // true=ok, false=invalid CleanPos
    function CleanPosToCaret(CleanPos: integer;
        out Caret:TCodeXYPosition): boolean; // true=ok, false=invalid CleanPos
    function CleanPosToCaretAndTopLine(CleanPos: integer;
        out Caret:TCodeXYPosition; out NewTopLine: integer): boolean; // true=ok, false=invalid CleanPos
    function CleanPosToStr(CleanPos: integer; WithFilename: boolean = false): string;
    procedure GetCleanPosInfo(CodePosInFront, CleanPos: integer;
        ResolveComments: boolean; out SameArea: TAtomPosition);
    procedure GetLineInfo(ACleanPos: integer;
        out ALineStart, ALineEnd, AFirstAtomStart, ALastAtomEnd: integer);
    function FindLineEndOrCodeAfterPosition(StartPos: integer;
        SkipEmptyLines: boolean = false): integer;
    function FindLineEndOrCodeInFrontOfPosition(StartPos: integer): integer;
    function FindLineEndOrCodeInFrontOfPosition(StartPos: integer;
        StopAtDirectives: boolean): integer;

    function UpdateNeeded(OnlyInterfaceNeeded: boolean): boolean;
    procedure BeginParsing(DeleteNodes, OnlyInterfaceNeeded: boolean); virtual;
    procedure BeginParsingAndGetCleanPos(DeleteNodes,
        OnlyInterfaceNeeded: boolean; CursorPos: TCodeXYPosition;
        out CleanCursorPos: integer);
    function IsDirtySrcValid: boolean;

    function StringIsKeyWord(const Word: string): boolean;
    
    // cursor moving
    procedure MoveCursorToNodeStart(ANode: TCodeTreeNode); {$IFDEF UseInline}inline;{$ENDIF}
    procedure MoveCursorToCleanPos(ACleanPos: integer);
    procedure MoveCursorToCleanPos(ACleanPos: PChar);
    procedure MoveCursorToAtomPos(const AnAtomPos: TAtomPosition);
    procedure MoveCursorToNearestAtom(ACleanPos: integer);
    procedure MoveCursorToLastNodeAtom(ANode: TCodeTreeNode);
    function IsPCharInSrc(ACleanPos: PChar): boolean;
    procedure MoveHybridCursorToPos(DirtyPos: PChar);
    function GetHybridCursorStart: integer;
    
    // read atoms
    procedure ReadNextAtom;
    procedure UndoReadNextAtom;
    procedure ReadPriorAtom;

    // read blocks
    function ReadTilBracketClose(ExceptionOnNotFound: boolean): boolean;
    function ReadBackTilBracketOpen(ExceptionOnNotFound: boolean): boolean;
    procedure ReadTillCommentEnd;
    
    // read atoms
    function AtomIs(const AnAtom: shortstring): boolean;
    function UpAtomIs(const AnAtom: shortstring): boolean;
    function ReadNextAtomIs(const AnAtom: shortstring): boolean; {$IFDEF UseInline}inline;{$ENDIF}
    function ReadNextUpAtomIs(const AnAtom: shortstring): boolean; {$IFDEF UseInline}inline;{$ENDIF}
    function ReadNextAtomIsChar(const c: char): boolean; {$IFDEF UseInline}inline;{$ENDIF}
    function AtomIsChar(const c: char): boolean; {$IFDEF UseInline}inline;{$ENDIF}
    function AtomIsKeyWord: boolean;
    function AtomIsNumber: boolean; {$IFDEF UseInline}inline;{$ENDIF}
    function AtomIsRealNumber: boolean;
    function AtomIsStringConstant: boolean; {$IFDEF UseInline}inline;{$ENDIF}
    function AtomIsCharConstant: boolean;
    function AtomIsEmptyStringConstant: boolean;
    function AtomIsIdentifier(ExceptionOnNotFound: boolean): boolean;
    function LastAtomIs(BackIndex: integer;
        const AnAtom: shortstring): boolean; // 0=current, 1=prior current, ...
    function LastUpAtomIs(BackIndex: integer;
        const AnAtom: shortstring): boolean; // 0=current, 1=prior current, ...
    function GetAtom: string;
    function GetUpAtom: string;
    function GetAtom(const Atom: TAtomPosition): string;
    function GetUpAtom(const Atom: TAtomPosition): string;
    function FreeUpAtomIs(const FreeAtomPos: TAtomPosition;
        const AnAtom: shortstring): boolean;
    
    // identifiers
    function CompareNodeIdentChars(ANode: TCodeTreeNode;
        const AnUpperIdent: string): integer;
    function CompareSrcIdentifiers(
      CleanStartPos1, CleanStartPos2: integer): boolean;
    function CompareSrcIdentifiers(Identifier1, Identifier2: PChar): boolean;
    function CompareSrcIdentifiers(CleanStartPos: integer;
      AnIdentifier: PChar): boolean;
    function CompareSrcIdentifiersMethod(Identifier1, Identifier2: Pointer): integer;
    function ExtractIdentifier(CleanStartPos: integer): string;

    procedure CreateChildNode;
    procedure EndChildNode; {$IFDEF UseInline}inline;{$ENDIF}
    function DoAtom: boolean; virtual;

    // write lock
    procedure ActivateGlobalWriteLock; virtual;
    procedure DeactivateGlobalWriteLock; virtual;
    property OnGetGlobalWriteLockInfo: TOnGetWriteLockInfo
      read FOnGetGlobalWriteLockInfo write FOnGetGlobalWriteLockInfo;
    property OnSetGlobalWriteLock: TOnSetWriteLock
      read FOnSetGlobalWriteLock write FOnSetGlobalWriteLock;
      
    // error handling
    procedure RaiseExceptionInstance(TheException: ECodeToolError;
      ClearNicePos: boolean = true); virtual;
    procedure RaiseExceptionClass(const AMessage: string;
      ExceptionClass: ECodeToolErrors; ClearNicePos: boolean); virtual;
    procedure RaiseException(const AMessage: string;
      ClearNicePos: boolean = true); virtual;
    procedure RaiseExceptionFmt(const AMessage: string;
      const args: array of const; ClearNicePos: boolean = true);
    procedure SaveRaiseException(const AMessage: string;
      ClearNicePos: boolean = true); virtual;
    procedure SaveRaiseExceptionFmt(const AMessage: string;
      const args: array of const; ClearNicePos: boolean = true);
    procedure SetNiceErrorPos(CleanPos: integer);
    property IgnoreErrorAfter: TCodePosition
      read FIgnoreErrorAfter write SetIgnoreErrorAfter;
    procedure ClearIgnoreErrorAfter;
    function IgnoreErrorAfterPositionIsInFrontOfLastErrMessage: boolean;
    function IgnoreErrorAfterValid: boolean;
    function IgnoreErrorAfterCleanedPos: integer;
    function CleanPosIsAfterIgnorePos(CleanPos: integer): boolean;
    function LastErrorIsInFrontOfCleanedPos(ACleanedPos: integer): boolean;
    procedure RaiseLastErrorIfInFrontOfCleanedPos(ACleanedPos: integer);
    property OnParserProgress: TOnParserProgress
      read FOnParserProgress write FOnParserProgress;

    // debugging
    procedure Clear; virtual;
    function NodeDescToStr(Desc: integer): string;
    function NodeSubDescToStr(Desc, SubDesc: integer): string;
    procedure ConsistencyCheck; virtual;
    procedure WriteDebugTreeReport;
    procedure CalcMemSize(Stats: TCTMemStats); virtual;
    procedure CheckNodeTool(Node: TCodeTreeNode);
    constructor Create;
    destructor Destroy; override;
  end;
  
var
  RaiseUnhandableExceptions: boolean;

implementation

{ TCustomCodeTool }

constructor TCustomCodeTool.Create;
begin
  inherited Create;
  Tree:=TCodeTree.Create;
  KeyWordFuncList:=TKeyWordFunctionList.Create;
  BuildDefaultKeyWordFunctions;
  WordIsKeyWordFuncList:=WordIsKeyWord;
  LastAtoms:=TAtomRing.Create;
  IndentSize:=2;
  VisibleEditorLines:=20;
  CursorBeyondEOL:=true;
  FForceUpdateNeeded:=false;
  Clear;
end;

destructor TCustomCodeTool.Destroy;
begin
  Clear;
  FreeAndNil(LastAtoms);
  FreeAndNil(Tree);
  FreeAndNil(KeyWordFuncList);
  FreeAndNil(DirtySrc);
  inherited Destroy;
end;

procedure TCustomCodeTool.Clear;
begin
  if Tree<>nil then DoDeleteNodes;
  CurPos:=StartAtomPosition;
  LastAtoms.Clear;
  NextPos.StartPos:=-1;
  ClearLastError;
end;

procedure TCustomCodeTool.RaiseException(const AMessage: string;
  ClearNicePos: boolean);
begin
  RaiseExceptionClass(AMessage,ECodeToolError,ClearNicePos);
end;

procedure TCustomCodeTool.RaiseExceptionFmt(const AMessage: string;
  const args: array of const; ClearNicePos: boolean);
begin
  RaiseException(Format(AMessage,args),ClearNicePos);
end;

procedure TCustomCodeTool.SaveRaiseException(const AMessage: string;
  ClearNicePos: boolean);
begin
  LastErrorMessage:=AMessage;
  LastErrorCurPos:=CurPos;
  LastErrorPhase:=CurrentPhase;
  LastErrorValid:=true;
  if ClearNicePos then begin
    LastErrorNicePosition.Code:=nil;
    LastErrorNicePosition.Y:=-1;
  end else begin
    LastErrorNicePosition:=ErrorNicePosition;
  end;
  RaiseException(AMessage,ClearNicePos);
end;

procedure TCustomCodeTool.SaveRaiseExceptionFmt(const AMessage: string;
  const args: array of const; ClearNicePos: boolean);
begin
  SaveRaiseException(Format(AMessage,args),ClearNicePos);
end;

procedure TCustomCodeTool.SetNiceErrorPos(CleanPos: integer);
var
  CaretXY: TCodeXYPosition;
begin
  // convert cleanpos to caret pos, which is more human readable
  if (CleanPos>SrcLen) and (SrcLen>0) then CleanPos:=SrcLen;
  if (CleanPosToCaret(CleanPos,CaretXY))
  and (CaretXY.Code<>nil) then begin
    ErrorNicePosition:=CaretXY;
  end else if (Scanner<>nil) and (Scanner.MainCode<>nil) then begin
    ErrorNicePosition.Code:=TCodeBuffer(Scanner.MainCode);
    ErrorNicePosition.Y:=-1;
  end else begin
    ErrorNicePosition.Code:=nil;
    ErrorNicePosition.Y:=-1;
  end;
end;

procedure TCustomCodeTool.ClearLastError;
begin
  LastErrorPhase:=CodeToolPhaseNone;
  LastErrorValid:=false;
  LastErrorCheckedForIgnored:=false;
  LastErrorNicePosition.Code:=nil;
  ErrorNicePosition.Code:=nil;
end;

procedure TCustomCodeTool.RaiseLastError;
begin
  CurPos:=LastErrorCurPos;
  CurNode:=nil;
  CurrentPhase:=LastErrorPhase;
  ErrorNicePosition:=LastErrorNicePosition;
  SaveRaiseException(LastErrorMessage,false);
end;

procedure TCustomCodeTool.DoProgress;
begin
  // Check every 1.000.000 chars
  if (FLastProgressPos-CurPos.StartPos)<1000000 then exit;
  NotifyAboutProgress;
end;

procedure TCustomCodeTool.NotifyAboutProgress;
begin
  FLastProgressPos:=CurPos.StartPos;

  if Assigned(OnParserProgress) then begin
    if OnParserProgress(Self) then exit;
    // abort the parsing process
    // mark parsing results as invalid
    FForceUpdateNeeded:=true;
    // raise the abort exception to stop the parsing
    RaiseExceptionClass('Abort',EParserAbort,true);
  end;
end;

procedure TCustomCodeTool.LoadDirtySource(const CursorPos: TCodeXYPosition);
// - create the DirtySrc object
// - load the unparsed source at CursorPos
// - find the gap bounds
var
  NewDirtyStartPos: integer;
  NewDirtyGapStart: integer;
  NewDirtyGapEnd: integer;
  CursorInLink: Boolean;
  BestLinkIndex: Integer;
  BestLink: TSourceLink;
begin
  DebugLn('TCustomCodeTool.LoadDirtySource X=',dbgs(CursorPos.X),' Y=',dbgs(CursorPos.Y),
    ' ',ExtractFilename(CursorPos.Code.Filename));
  if DirtySrc=nil then DirtySrc:=TDirtySource.Create(Self);
  CursorPos.Code.LineColToPosition(CursorPos.Y,CursorPos.X,NewDirtyStartPos);
  if NewDirtyStartPos<1 then
    RaiseCatchableException('NewDirtyStartPos<1');
  CursorInLink:=false;
  BestLinkIndex:=Scanner.LinkIndexNearCursorPos(NewDirtyStartPos,
                                                CursorPos.Code,CursorInLink);
  if BestLinkIndex<0 then
    RaiseCatchableException('BestLinkIndex<0');
  if CursorInLink then
    RaiseCatchableException('CursorInLink');
  BestLink:=Scanner.Links[BestLinkIndex];
  NewDirtyGapStart:=BestLink.SrcPos+Scanner.LinkSize(BestLinkIndex);
  if BestLinkIndex<Scanner.LinkCount then
    NewDirtyGapEnd:=Scanner.Links[BestLinkIndex+1].SrcPos
  else
    NewDirtyGapEnd:=CursorPos.Code.SourceLength;
  DirtySrc.SetGap(CursorPos,NewDirtyStartPos,NewDirtyGapStart,NewDirtyGapEnd);
end;

procedure TCustomCodeTool.RaiseUndoImpossible;
begin
  RaiseException('TCustomCodeTool.UndoReadNextAtom impossible',true);
end;

procedure TCustomCodeTool.SetScanner(NewScanner: TLinkScanner);
begin
  if NewScanner=FScanner then exit;
  LastErrorCheckedForIgnored:=false;
  Clear;
  FScanner:=NewScanner;
  if Scanner<>nil then begin
    FLastScannerChangeStep:=Scanner.ChangeStep;
    Scanner.SetIgnoreErrorAfter(IgnoreErrorAfter.P,IgnoreErrorAfter.Code);
  end;
  {$IFDEF VerboseUpdateNeeded}
  DebugLn(['TCustomCodeTool.SetScanner FForceUpdateNeeded:=true ',MainFilename]);
  {$ENDIF}
  FForceUpdateNeeded:=true;
end;

function TCustomCodeTool.NodeDescToStr(Desc: integer): string;
begin
  Result:=NodeDescriptionAsString(TCodeTreeNodeDesc(Desc));
end;

function TCustomCodeTool.NodeSubDescToStr(Desc, SubDesc: integer): string;
begin
  if SubDesc<>0 then
    Result:=Format(ctsUnknownSubDescriptor,[IntToStr(SubDesc)])
  else
    Result:='';
  case Desc of
  ctnProcedure:
    begin
      if (SubDesc and ctnsForwardDeclaration)>0 then Result:=ctsForward;
    end;
  ctnProcedureHead, ctnBeginBlock:
    begin
      if (SubDesc and ctnsNeedJITParsing)>0 then Result:=ctsUnparsed;
    end;
  ctnClass,ctnObject,ctnObjCClass,ctnClassInterface,ctnObjCProtocol:
    begin
      Result:='';
      if (SubDesc and ctnsForwardDeclaration)>0 then Result:=ctsForward;
      if (SubDesc and ctnsNeedJITParsing)>0 then Result:=Result+ctsUnparsed;
    end;
  end;
end;

function TCustomCodeTool.AtomIs(const AnAtom: shortstring): boolean;
var AnAtomLen,i : integer;
begin
  Result:=false;
  if (CurPos.StartPos<=SrcLen) and (CurPos.EndPos<=SrcLen+1)
  and (CurPos.StartPos>=1) then begin
    AnAtomLen:=length(AnAtom);
    if AnAtomLen=CurPos.EndPos-CurPos.StartPos then begin
      for i:=1 to AnAtomLen do
        if AnAtom[i]<>Src[CurPos.StartPos-1+i] then exit;
      Result:=true;
    end;
  end;
end;

function TCustomCodeTool.UpAtomIs(const AnAtom: shortstring): boolean;
var
  AnAtomLen, i: integer;
  p: PChar;
begin
  Result:=false;
  AnAtomLen:=length(AnAtom);
  if AnAtomLen<>CurPos.EndPos-CurPos.StartPos then exit;
  if (CurPos.EndPos<=SrcLen+1) and (CurPos.StartPos>=1) then begin
    p:=@Src[CurPos.StartPos];
    for i:=1 to AnAtomLen do begin
      if AnAtom[i]<>UpChars[p^] then exit;
      inc(p);
    end;
    Result:=true;
  end;
end;

function TCustomCodeTool.ReadNextAtomIs(const AnAtom: shortstring): boolean;
begin
  ReadNextAtom;
  Result:=AtomIs(AnAtom);
end;

function TCustomCodeTool.ReadNextAtomIsChar(const c: char): boolean;
begin
  ReadNextAtom;
  Result:=AtomIsChar(c);
end;

function TCustomCodeTool.ReadNextUpAtomIs(const AnAtom: shortstring): boolean;
begin
  ReadNextAtom;
  Result:=UpAtomIs(AnAtom);
end;

function TCustomCodeTool.CompareNodeIdentChars(ANode: TCodeTreeNode;
  const AnUpperIdent: string): integer;
var
  AnIdentLen, i, NodeSrcLen, MinLen: integer;
  p: PChar;
begin
  {$IFDEF CheckNodeTool}CheckNodeTool(ANode);{$ENDIF}
  if (ANode.StartPos<=SrcLen) and (ANode.EndPos<=SrcLen+1)
  and (ANode.StartPos>=1) then begin
    AnIdentLen:=length(AnUpperIdent);
    NodeSrcLen:=ANode.EndPos-ANode.StartPos;
    if AnIdentLen<NodeSrcLen then
      MinLen:=AnIdentLen
    else
      MinLen:=NodeSrcLen;
    i:=1;
    p:=@Src[ANode.StartPos];
    while (i<=MinLen) and (IsIdentChar[p^]) do begin
      if AnUpperIdent[i]<>UpChars[p^] then begin
        // identifiers different in one letter
        if UpChars[p^]>AnUpperIdent[i] then
          Result:=-1
        else
          Result:=1;
        exit;
      end;
      inc(i);
      inc(p);
    end;
    if (i>MinLen) and (i>AnIdentLen) then begin
      // node is longer than AnUpperIdent
      if (i>NodeSrcLen) or (not IsIdentChar[p^]) then
        // node identifier is equal to AnUpperIdent
        Result:=0
      else
        // node Identifier is longer than AnUpperIdent
        Result:=-1;
    end else
      // node identifier is shorter than AnUpperIdent
      Result:=1
  end else
    Result:=1;
end;

function TCustomCodeTool.CompareSrcIdentifiers(
  CleanStartPos1, CleanStartPos2: integer): boolean;
var
  p1: PChar;
  p2: PChar;
begin
  if (CleanStartPos1<1) or (CleanStartPos1>SrcLen)
     or (CleanStartPos2<1) or (CleanStartPos2>SrcLen)
  then
    exit(false);
  p1:=@Src[CleanStartPos1];
  p2:=@Src[CleanStartPos2];
  while (CleanStartPos1<=SrcLen) and IsIdentChar[p1^] do begin
    if (UpChars[p1^]<>UpChars[p2^]) then
      exit(false);
    inc(CleanStartPos1);
    inc(p1);
    inc(p2);
  end;
  Result:=(not IsIdentChar[p2^]);
end;

function TCustomCodeTool.AtomIsChar(const c: char): boolean;
begin
  Result:=(CurPos.StartPos<=SrcLen)
      and (CurPos.EndPos-CurPos.StartPos=1)
      and (Src[CurPos.StartPos]=c);
end;

function TCustomCodeTool.AtomIsKeyWord: boolean;
begin
  Result:=(CurPos.StartPos<=SrcLen)
      and (IsIdentStartChar[Src[CurPos.StartPos]])
      and (WordIsKeyWordFuncList.DoItCaseInsensitive(Src,CurPos.StartPos,
             CurPos.EndPos-CurPos.StartPos));
end;

function TCustomCodeTool.AtomIsIdentifier(ExceptionOnNotFound: boolean):boolean;

  procedure RaiseIdentExpectedButEOFFound;
  begin
    SaveRaiseException(ctsIdentExpectedButEOFFound,true);
  end;

begin
  if (CurPos.StartPos<=SrcLen)
  and IsIdentStartChar[Src[CurPos.StartPos]]
  and not WordIsKeyWordFuncList.DoItCaseInsensitive(Src,CurPos.StartPos,
             CurPos.EndPos-CurPos.StartPos)
  then
    exit(true);
  if not ExceptionOnNotFound then
    exit(false);
  if CurPos.StartPos>SrcLen then
    RaiseIdentExpectedButEOFFound
  else
    RaiseIdentExpectedButAtomFound;
end;

function TCustomCodeTool.AtomIsNumber: boolean;
begin
  Result:=(CurPos.StartPos<=SrcLen)
      and (Src[CurPos.StartPos] in ['0'..'9','%','$']);
end;

function TCustomCodeTool.AtomIsRealNumber: boolean;
var i: integer;
begin
  Result:=false;
  i:=CurPos.StartPos;
  if (i<=SrcLen) and (IsNumberChar[Src[i]]) then begin
    while (i<=SrcLen) and (IsNumberChar[Src[i]]) do
      inc(i);
    if (i<SrcLen) and (Src[i]='.') and (IsNumberChar[Src[i+1]]) then
      Result:=true;
  end;
end;

function TCustomCodeTool.AtomIsStringConstant: boolean;
begin
  Result:=(CurPos.StartPos<=SrcLen)
      and (Src[CurPos.StartPos] in ['''','#']);
end;

function TCustomCodeTool.AtomIsCharConstant: boolean;
var i: integer;
  p: LongInt;
begin
  Result:=false;
  p:=CurPos.StartPos;
  if (p<=SrcLen) then begin
    case Src[p] of
    
    '#':
      begin
        i:=p+1;
        if (i<=SrcLen) then begin
          if IsNumberChar[Src[i]] then begin
            // decimal
            while (i<=SrcLen) and (IsNumberChar[Src[i]]) do
              inc(i);
          end else if Src[i]='$' then begin
            // hexadecimal
            while (i<=SrcLen) and (IsHexNumberChar[Src[i]]) do
              inc(i);
          end;
          if (i<=SrcLen)
          and (not (Src[i] in ['''','#'])) then
            Result:=true;
        end;
      end;

    '''':
      begin
        if (p+2<=SrcLen) and (Src[p+1]<>'''')
        and (Src[p+2]='''') then begin
          // a single char
          if (p+2<SrcLen)
          and (not (Src[p+3] in ['''','#'])) then
            Result:=true;
        end;
      end;
      
    end;
  end;
end;

function TCustomCodeTool.AtomIsEmptyStringConstant: boolean;
var
  p: LongInt;
begin
  p:=CurPos.StartPos;
  while (p<=SrcLen) and (Src[p]='''') do inc(p);
  dec(p,CurPos.StartPos);
  Result:=(p>0) and ((p and 1)=0);
end;

function TCustomCodeTool.LastAtomIs(BackIndex: integer;
  const AnAtom: shortstring): boolean;
var ap: TAtomPosition;
  AnAtomLen: integer;
  i: integer;
begin
  Result:=false;
  if (BackIndex>=0) and (BackIndex<LastAtoms.Count) then begin
    ap:=LastAtoms.GetValueAt(BackIndex);
    Result:=false;
    if (ap.StartPos<SrcLen) and (ap.EndPos<=SrcLen+1)
    and (ap.StartPos>=1) then begin
      AnAtomLen:=length(AnAtom);
      if AnAtomLen=ap.EndPos-ap.StartPos then begin
        for i:=1 to AnAtomLen do
          if AnAtom[i]<>Src[ap.StartPos-1+i] then exit;
        Result:=true;
      end;
    end;
  end;
end;

function TCustomCodeTool.LastUpAtomIs(BackIndex: integer;
  const AnAtom: shortstring): boolean;
var ap: TAtomPosition;
  AnAtomLen: integer;
  i: integer;
  p: PChar;
begin
  Result:=false;
  if (BackIndex<0) or (BackIndex>=LastAtoms.Count) then exit;
  ap:=LastAtoms.GetValueAt(BackIndex);
  AnAtomLen:=length(AnAtom);
  if AnAtomLen<>ap.EndPos-ap.StartPos then exit;
  if (ap.StartPos>SrcLen) or (ap.EndPos>SrcLen+1) or (ap.StartPos<1) then exit;
  p:=@Src[ap.StartPos];
  for i:=1 to AnAtomLen do begin
    if AnAtom[i]<>UpChars[p^] then exit;
    inc(p);
  end;
  Result:=true;
end;

function TCustomCodeTool.GetAtom: string;
begin
  Result:=copy(Src,CurPos.StartPos,CurPos.EndPos-CurPos.StartPos);
end;

function TCustomCodeTool.GetUpAtom: string;
begin
  Result:=UpperCaseStr(copy(Src,CurPos.StartPos,CurPos.EndPos-CurPos.StartPos));
end;

function TCustomCodeTool.GetAtom(const Atom: TAtomPosition): string;
begin
  Result:=copy(Src,Atom.StartPos,Atom.EndPos-Atom.StartPos);
end;

function TCustomCodeTool.GetUpAtom(const Atom: TAtomPosition): string;
begin
  Result:=UpperCaseStr(copy(Src,Atom.StartPos,Atom.EndPos-Atom.StartPos));
end;

function TCustomCodeTool.FreeUpAtomIs(const FreeAtomPos: TAtomPosition;
  const AnAtom: shortstring): boolean;
var AnAtomLen,i : integer;
  p: PChar;
begin
  Result:=false;
  if (FreeAtomPos.StartPos>SrcLen) or (FreeAtomPos.EndPos>SrcLen+1)
  or (FreeAtomPos.StartPos<1) then
    exit;
  AnAtomLen:=length(AnAtom);
  if AnAtomLen<>FreeAtomPos.EndPos-FreeAtomPos.StartPos then exit;
  p:=@Src[FreeAtomPos.StartPos];
  for i:=1 to AnAtomLen do begin
    if AnAtom[i]<>UpChars[p^] then exit;
    inc(p);
  end;
  Result:=true;
end;

procedure TCustomCodeTool.ReadNextAtom;
var c1, c2: char;
  CommentLvl: integer;
begin
  {$IFOPT R+}{$DEFINE RangeChecking}{$ENDIF}
  {$R-}
  if (CurPos.StartPos<CurPos.EndPos) then
    LastAtoms.Add(CurPos);
  if NextPos.StartPos<1 then begin
    CurPos.StartPos:=CurPos.EndPos;
    CurPos.Flag:=cafNone;
    if CurPos.StartPos>SrcLen then
      exit;
    // Skip all spaces and comments
    while true do begin
      case Src[CurPos.StartPos] of
      #0:
        if CurPos.StartPos>SrcLen then
          break
        else
          inc(CurPos.StartPos);
      #1..#32:
        inc(CurPos.StartPos);
      #$EF:
        if (Src[CurPos.StartPos+1]=#$BB)
        and (Src[CurPos.StartPos+2]=#$BF) then begin
          // skip UTF BOM
          inc(CurPos.StartPos,3);
        end else begin
          break;
        end;
      '{': // pascal comment
        begin
          CommentLvl:=1;
          while true do begin
            inc(CurPos.StartPos);
            case Src[CurPos.StartPos] of
            #0:  if CurPos.StartPos>SrcLen then break;
            '{': if Scanner.NestedComments then
              begin
                //debugln('TCustomCodeTool.ReadNextAtom ',copy(Src,CurPos.StartPos,CurPos.StartPos-CurPos.EndPos));
                inc(CommentLvl);
              end;
            '}':
              begin
                dec(CommentLvl);
                if CommentLvl=0 then begin
                  inc(CurPos.StartPos);
                  break;
                end;
              end;
            end;
          end;
        end;
      '/':  // Delphi comment
        if (Src[CurPos.StartPos+1]<>'/') then begin
          break;
        end else begin
          inc(CurPos.StartPos,2);
          while (not (Src[CurPos.StartPos] in [#10,#13,#0])) do
            inc(CurPos.StartPos);
          inc(CurPos.StartPos);
          if (CurPos.StartPos<=SrcLen) and (Src[CurPos.StartPos] in [#10,#13])
          and (Src[CurPos.StartPos-1]<>Src[CurPos.StartPos]) then
            inc(CurPos.StartPos);
        end;
      '(': // old turbo pascal comment
        if (Src[CurPos.StartPos+1]<>'*') then begin
          break;
        end else begin
          inc(CurPos.StartPos,2);
          CommentLvl:=1;
          while true do begin
            case Src[CurPos.StartPos] of
            #0:  if CurPos.StartPos>SrcLen then break;
            '(': if Scanner.NestedComments and (Src[CurPos.StartPos+1]='*') then
              begin
                //debugln('TCustomCodeTool.ReadNextAtom ',copy(Src,CurPos.StartPos,CurPos.StartPos-CurPos.EndPos));
                inc(CommentLvl);
                inc(CurPos.StartPos);
              end;
            '*':
              if (Src[CurPos.StartPos+1]=')') then begin
                dec(CommentLvl);
                if CommentLvl=0 then begin
                  inc(CurPos.StartPos,2);
                  break;
                end;
                inc(CurPos.StartPos);
              end;
            end;
            inc(CurPos.StartPos);
          end;
        end;
      else
        break;
      end;
    end;
    CurPos.EndPos:=CurPos.StartPos;
    // read atom
    c1:=Src[CurPos.EndPos];
    case c1 of
    #0: ;
    '_','A'..'Z','a'..'z':
      begin
        inc(CurPos.EndPos);
        while (IsIdentChar[Src[CurPos.EndPos]]) do
          inc(CurPos.EndPos);
        CurPos.Flag:=cafWord;
        case c1 of
        'b','B':
          if (CurPos.EndPos-CurPos.StartPos=5)
          and UpAtomIs('BEGIN')
          then
            CurPos.Flag:=cafBegin;
        'e','E':
          if (CurPos.EndPos-CurPos.StartPos=3)
          and (Src[CurPos.StartPos+1] in ['n','N'])
          and (Src[CurPos.StartPos+2] in ['d','D'])
          and ((CurPos.StartPos=1) or (Src[CurPos.StartPos-1]<>'@'))
          then
            CurPos.Flag:=cafEnd;
        'r','R':
          if (CurPos.EndPos-CurPos.StartPos=6)
          and UpAtomIs('RECORD')
          then
            CurPos.Flag:=cafRecord;
        end;
      end;
    '''','#':
      begin
        while (CurPos.EndPos<=SrcLen) do begin
          case (Src[CurPos.EndPos]) of
          '#':
            begin
              inc(CurPos.EndPos);
              if (CurPos.EndPos<=SrcLen) then begin
                if (IsNumberChar[Src[CurPos.EndPos]]) then begin
                  // decimal
                  repeat
                    inc(CurPos.EndPos);
                  until (CurPos.EndPos>SrcLen)
                        or (not IsNumberChar[Src[CurPos.EndPos]]);
                end else if Src[CurPos.EndPos]='$' then begin
                  // hexadecimal
                  repeat
                    inc(CurPos.EndPos);
                  until (CurPos.EndPos>SrcLen)
                        or (not IsHexNumberChar[Src[CurPos.EndPos]]);
                end;
              end;
            end;
          '''':
            begin
              inc(CurPos.EndPos);
              while (CurPos.EndPos<=SrcLen) do begin
                case Src[CurPos.EndPos] of

                '''':
                  begin
                    inc(CurPos.EndPos);
                    break;
                  end;

                #10,#13:
                  break;

                else
                  inc(CurPos.EndPos);
                end;
              end;
            end;
          else
            break;
          end;
        end;
      end;
    '0'..'9':
      begin
        inc(CurPos.EndPos);
        while (CurPos.EndPos<=SrcLen) and (IsNumberChar[Src[CurPos.EndPos]]) do
          inc(CurPos.EndPos);
        if (CurPos.EndPos<SrcLen)
        and (Src[CurPos.EndPos]='.')
        and (IsAfterFloatPointChar[Src[CurPos.EndPos+1]])
        then begin
          // real type number
          inc(CurPos.EndPos);
          while (CurPos.EndPos<=SrcLen) and (IsNumberChar[Src[CurPos.EndPos]])
          do
            inc(CurPos.EndPos);
        end;
        if (CurPos.EndPos<=SrcLen) and (Src[CurPos.EndPos] in ['e','E']) then
        begin
          // read exponent
          inc(CurPos.EndPos);
          if (CurPos.EndPos<=SrcLen) and (Src[CurPos.EndPos] in ['-','+'])
          then inc(CurPos.EndPos);
          while (CurPos.EndPos<=SrcLen) and (IsNumberChar[Src[CurPos.EndPos]])
          do
            inc(CurPos.EndPos);
        end;
      end;
    '%':
      begin
        inc(CurPos.EndPos);
        while (CurPos.EndPos<=SrcLen) and (Src[CurPos.EndPos] in ['0'..'1']) do
          inc(CurPos.EndPos);
      end;
    '$':
      begin
        inc(CurPos.EndPos);
        while (CurPos.EndPos<=SrcLen)
        and (IsHexNumberChar[Src[CurPos.EndPos]]) do
          inc(CurPos.EndPos);
      end;
    ';':
      begin
        inc(CurPos.EndPos);
        CurPos.Flag:=cafSemicolon;
      end;
    ',':
      begin
        inc(CurPos.EndPos);
        CurPos.Flag:=cafComma;
      end;
    '=':
      begin
        inc(CurPos.EndPos);
        CurPos.Flag:=cafEqual;
      end;
    '(':
      begin
        inc(CurPos.EndPos);
        CurPos.Flag:=cafRoundBracketOpen;
      end;
    ')':
      begin
        inc(CurPos.EndPos);
        CurPos.Flag:=cafRoundBracketClose;
      end;
    '[':
      begin
        inc(CurPos.EndPos);
        CurPos.Flag:=cafEdgedBracketOpen;
      end;
    ']':
      begin
        inc(CurPos.EndPos);
        CurPos.Flag:=cafEdgedBracketClose;
      end;
    ':':
      begin
        inc(CurPos.EndPos);
        if (Src[CurPos.EndPos]<>'=') then begin
          CurPos.Flag:=cafColon;
        end else begin
          // :=
          inc(CurPos.EndPos);
        end;
      end;
    '.':
      begin
        inc(CurPos.EndPos);
        if (Src[CurPos.EndPos]<>'.') then begin
          // '.'
          CurPos.Flag:=cafPoint;
        end else begin
          inc(CurPos.EndPos);
          if (Src[CurPos.EndPos]<>'.') then begin
            // '..'
          end else begin
            // '...'
            inc(CurPos.EndPos);
          end;
        end;
      end;
    else
      inc(CurPos.EndPos);
      c2:=Src[CurPos.EndPos];
      // test for double char operators :=, +=, -=, /=, *=, <>, <=, >=, **, ><
      if ((c2='=') and  (IsEqualOperatorStartChar[c1]))
        or ((c1='<') and (c2='>')) // not equal
        or ((c1='>') and (c2='<'))
        or ((c1='.') and (c2='.'))
        or ((c1='*') and (c2='*'))
        then begin
          // 2 character operator/symbol
          inc(CurPos.EndPos);
      end
      else if ((c1='@') and (c2='@')) then begin
        // @@ label
        repeat
          inc(CurPos.EndPos);
        until (CurPos.EndPos>SrcLen) or (not IsIdentChar[Src[CurPos.EndPos]]);
      end;
    end;
  end else begin
    CurPos:=NextPos;
    NextPos.StartPos:=-1;
    exit;
  end;
  {$IFDEF RangeChecking}{$R+}{$UNDEF RangeChecking}{$ENDIF}
end;

procedure TCustomCodeTool.ReadPriorAtom;
var
  CommentLvl, PrePos, OldPrePos: integer;
  IsStringConstant: boolean;

  procedure ReadStringConstantBackward;
  var PrePos: integer;
  begin
    while (CurPos.StartPos>1) do begin
      case Src[CurPos.StartPos-1] of
      '''':
        begin
          dec(CurPos.StartPos);
          repeat
            dec(CurPos.StartPos);
          until (CurPos.StartPos<1) or (Src[CurPos.StartPos]='''');
        end;
      '0'..'9','A'..'Z','a'..'z':
        begin
          // test if char constant
          PrePos:=CurPos.StartPos-1;
          while (PrePos>1) and (IsHexNumberChar[Src[PrePos]]) do
            dec(PrePos);
          if (PrePos<1) then break;
          if (Src[PrePos]='$') then begin
            dec(PrePos);
            if (PrePos<1) then break;
          end;
          if (Src[PrePos]='#') then
            CurPos.StartPos:=PrePos
          else
            break;
        end;
      else
        break;
      end;
    end;
  end;
  
  procedure ReadBackTilCodeLineEnd;
  begin
    dec(CurPos.StartPos);
    if (CurPos.StartPos>=1) and (Src[CurPos.StartPos] in [#10,#13])
    and (Src[CurPos.StartPos+1]<>Src[CurPos.StartPos]) then
      dec(CurPos.StartPos);

    // read backwards till line start
    PrePos:=CurPos.StartPos;
    while (PrePos>=1) and (not (Src[PrePos] in [#10,#13])) do
      dec(PrePos);
    // read line forward to find out,
    // if line ends in comment or string constant
    IsStringConstant:=false;
    repeat
      inc(PrePos);
      case Src[PrePos] of

      '/':
        if Src[PrePos+1]='/' then begin
          // this was a delphi comment -> skip comment
          CurPos.StartPos:=PrePos-1;
          break;
        end;

      '{':
        begin
          // skip pascal comment
          CommentLvl:=1;
          inc(PrePos);
          while (PrePos<=CurPos.StartPos) do begin
            case Src[PrePos] of
            '{': if Scanner.NestedComments then inc(CommentLvl);
            '}':
              begin
                dec(CommentLvl);
                if CommentLvl=0 then break;
              end;
            end;
            inc(PrePos);
          end;
        end;

      '(':
        begin
          if Src[PrePos+1]='*' then begin
            // skip turbo pascal comment
            inc(PrePos,2);
            while (PrePos<CurPos.StartPos)
            and ((Src[PrePos]<>'*') or (Src[PrePos+1]<>')')) do
              inc(PrePos);
            inc(PrePos);
          end;
        end;

      '''':
        begin
          // a string constant -> skip it
          OldPrePos:=PrePos;
          repeat
            inc(PrePos);
            case Src[PrePos] of

            '''':
              break;

            #10,#13:
              begin
                // string constant right border is the line end
                // -> last atom of line found
                IsStringConstant:=true;
                break;
              end;

            end;
          until false;
          if IsStringConstant then break;
        end;

      #10,#13:
        // no comment and no string constant found
        break;

      end;
    until PrePos>=CurPos.StartPos;
  end;

type
  TNumberType = (ntDecimal, ntHexadecimal, ntBinary, ntIdentifier,
    ntCharConstant, ntFloat, ntFloatWithExponent);
  TNumberTypes = set of TNumberType;

const
  AllNumberTypes: TNumberTypes = [ntDecimal, ntHexadecimal, ntBinary,
    ntIdentifier, ntCharConstant, ntFloat, ntFloatWithExponent];

var c1, c2: char;
  ForbiddenNumberTypes: TNumberTypes;
begin
  if LastAtoms.Count>0 then begin
    UndoReadNextAtom;
    exit;
  end;
  NextPos:=CurPos;
  // Skip all spaces and comments
  CommentLvl:=0;
  dec(CurPos.StartPos);
  CurPos.Flag:=cafNone;
  IsStringConstant:=false;
  OldPrePos:=0;
  while CurPos.StartPos>=1 do begin
    if IsCommentEndChar[Src[CurPos.StartPos]] then begin
      case Src[CurPos.StartPos] of
      
      '}': // pascal comment
        begin
          CommentLvl:=1;
          dec(CurPos.StartPos);
          while (CurPos.StartPos>=1) and (CommentLvl>0) do begin
            case Src[CurPos.StartPos] of
            '}': if Scanner.NestedComments then inc(CommentLvl);
            '{': dec(CommentLvl);
            end;
            dec(CurPos.StartPos);
          end;
        end;
        
      #10,#13: // possible Delphi comment
        ReadBackTilCodeLineEnd;

      ')': // old turbo pascal comment
        if (CurPos.StartPos>1) and (Src[CurPos.StartPos-1]='*') then begin
          dec(CurPos.StartPos,3);
          while (CurPos.StartPos>=1)
          and ((Src[CurPos.StartPos]<>'(') or (Src[CurPos.StartPos+1]<>'*')) do
            dec(CurPos.StartPos);
          dec(CurPos.StartPos);
        end else
          break;
          
      end;
    end else if IsSpaceChar[Src[CurPos.StartPos]] then begin
      repeat
        dec(CurPos.StartPos);
      until (CurPos.StartPos<1) or (Src[CurPos.StartPos] in [#10,#13])
      or (not (IsSpaceChar[Src[CurPos.StartPos]]));
    end else begin
      break;
    end;
  end;
  // CurPos.StartPos now points to the last char of the prior atom
  CurPos.EndPos:=CurPos.StartPos+1;
  if CurPos.StartPos<1 then
    exit;
  // read atom
  if IsStringConstant then begin
    CurPos.StartPos:=OldPrePos;
    if (CurPos.StartPos>1) and (Src[CurPos.StartPos-1]='''') then begin
      ReadStringConstantBackward;
    end;
    exit;
  end;
  c2:=Src[CurPos.StartPos];
  case c2 of
    '_','A'..'Z','a'..'z':
      begin
        // identifier or keyword or hexnumber
        while (CurPos.StartPos>1) do begin
          if (IsIdentChar[Src[CurPos.StartPos-1]]) then
            dec(CurPos.StartPos)
          else begin
            case UpChars[Src[CurPos.StartPos-1]] of
            '@':
              // assembler label
              if (CurPos.StartPos>2)
              and (Src[CurPos.StartPos-2]='@') then
                dec(CurPos.StartPos,2);
            '$':
              // hex number
              dec(CurPos.StartPos);
            else
              case UpChars[Src[CurPos.StartPos]] of
              'E':
                if CompareSrcIdentifiers(CurPos.StartPos,'END') then
                  CurPos.Flag:=cafEnd
                else
                  CurPos.Flag:=cafWord;
              'B':
                if CompareSrcIdentifiers(CurPos.StartPos,'BEGIN') then
                  CurPos.Flag:=cafBegin
                else
                  CurPos.Flag:=cafWord;
              'R':
                if CompareSrcIdentifiers(CurPos.StartPos,'RECORD') then
                  CurPos.Flag:=cafRecord
                else
                  CurPos.Flag:=cafWord;
              else
                CurPos.Flag:=cafWord;
              end;
            end;
            break;
          end;
        end;
      end;
    '''':
      begin
        inc(CurPos.StartPos);
        ReadStringConstantBackward;
      end;
    '0'..'9':
      begin
        // could be a decimal number, an identifier, a hex number,
        // a binary number, a char constant, a float, a float with exponent
        ForbiddenNumberTypes:=[];
        while true do begin
          case UpChars[Src[CurPos.StartPos]] of
          '0'..'1':
            ;
          '2'..'9':
            ForbiddenNumberTypes:=ForbiddenNumberTypes+[ntBinary];
          'A'..'D','F':
            ForbiddenNumberTypes:=ForbiddenNumberTypes
               +[ntBinary,ntDecimal,ntCharConstant,ntFloat,ntFloatWithExponent];
          'E':
            ForbiddenNumberTypes:=ForbiddenNumberTypes
               +[ntBinary,ntDecimal,ntCharConstant,ntFloat];
          'G'..'Z','_':
            ForbiddenNumberTypes:=AllNumberTypes-[ntIdentifier];
          '.':
            begin
              // could be the point of a float
              if (ntFloat in ForbiddenNumberTypes)
              or (CurPos.StartPos<=1) or (Src[CurPos.StartPos-1]='.') then begin
                inc(CurPos.StartPos);
                break;
              end;
              dec(CurPos.StartPos);
              // this was the part of a float after the point
              //  -> read decimal in front
              ForbiddenNumberTypes:=AllNumberTypes-[ntDecimal];
            end;
          '+','-':
            begin
              // could be part of an exponent
              if (ntFloatWithExponent in ForbiddenNumberTypes)
              or (CurPos.StartPos<=1)
              or (not (Src[CurPos.StartPos-1] in ['e','E']))
              then begin
                inc(CurPos.StartPos);
                break;
              end;
              dec(CurPos.StartPos);
              // this was the exponent of a float -> read the float
              ForbiddenNumberTypes:=AllNumberTypes-[ntFloat];
            end;
          '#': // char constant found
            begin
              if (ntCharConstant in ForbiddenNumberTypes) then
                inc(CurPos.StartPos);
              ReadStringConstantBackward;
              break;
            end;
          '$':
            begin
              // hexadecimal number found
              if (ntHexadecimal in ForbiddenNumberTypes) then
                inc(CurPos.StartPos);
              break;
            end;
          '%':
            begin
              // binary number found
              if (ntBinary in ForbiddenNumberTypes) then
                inc(CurPos.StartPos);
              break;
            end;
          '@':
            begin
              if (CurPos.StartPos=1) or (Src[CurPos.StartPos-1]<>'@')
              or (([ntIdentifier,ntDecimal]*ForbiddenNumberTypes)=[]) then
                // atom start found
                inc(CurPos.StartPos)
              else
                // label found
                dec(CurPos.StartPos);
              break;
            end;
          else
            begin
              inc(CurPos.StartPos);
              break;
            end;
          end;
          if ForbiddenNumberTypes=AllNumberTypes then begin
            inc(CurPos.StartPos);
            break;
          end;
          if CurPos.StartPos<=1 then break;
          dec(CurPos.StartPos);
        end;
        if IsIdentStartChar[Src[CurPos.StartPos]] then begin
          // it is an identifier
          CurPos.Flag:=cafWord;
          case UpChars[Src[CurPos.StartPos]] of
          'E':
            if CompareSrcIdentifiers(CurPos.StartPos,'END') then
              CurPos.Flag:=cafEnd;
          'B':
            if CompareSrcIdentifiers(CurPos.StartPos,'BEGIN') then
              CurPos.Flag:=cafBegin;
          'R':
            if CompareSrcIdentifiers(CurPos.StartPos,'RECORD') then
              CurPos.Flag:=cafRecord;
          end;
        end;
      end;
      
    ';': CurPos.Flag:=cafSemicolon;
    ':': CurPos.Flag:=cafColon;
    ',': CurPos.Flag:=cafComma;
    '(': CurPos.Flag:=cafRoundBracketOpen;
    ')': CurPos.Flag:=cafRoundBracketClose;
    '[': CurPos.Flag:=cafEdgedBracketOpen;
    ']': CurPos.Flag:=cafEdgedBracketClose;

    else
      begin
        if CurPos.StartPos>1 then begin
          c1:=Src[CurPos.StartPos-1];
          // test for double char operators :=, +=, -=, /=, *=, <>, <=, >=, **, ><
          if ((c2='=') and  (IsEqualOperatorStartChar[c1]))
          or ((c1='<') and (c2='>'))
          or ((c1='>') and (c2='<'))
          or ((c1='.') and (c2='.'))
          or ((c1='*') and (c2='*'))
          or ((c1='@') and (c2='@'))
          then begin
            dec(CurPos.StartPos);
            CurPos.Flag:=cafNone;
          end else begin
            case c2 of
            '=': CurPos.Flag:=cafEqual;
            '.': CurPos.Flag:=cafPoint;
            end;
          end;
        end else begin
          case c2 of
          '=': CurPos.Flag:=cafEqual;
          '.': CurPos.Flag:=cafPoint;
          end;
        end;
      end;
  end;
end;

procedure TCustomCodeTool.UndoReadNextAtom;
begin
  if LastAtoms.Count>0 then begin
    NextPos:=CurPos;
    CurPos:=LastAtoms.GetValueAt(0);
    LastAtoms.UndoLastAdd;
  end else
    RaiseUndoImpossible;
end;

function TCustomCodeTool.ReadTilBracketClose(
  ExceptionOnNotFound: boolean): boolean;
// reads code brackets (not comment brackets)
// after call cursor is on the closing bracket
var CloseBracket, AntiCloseBracket: TCommonAtomFlag;
  Start: TAtomPosition;
  
  procedure RaiseBracketNotFound;
  begin
    if CloseBracket=cafRoundBracketClose then
      SaveRaiseExceptionFmt(ctsBracketNotFound,[')'],false)
    else
      SaveRaiseExceptionFmt(ctsBracketNotFound,[']'],false);
  end;
  
begin
  Result:=false;
  if (Curpos.Flag=cafRoundBracketOpen) then begin
    CloseBracket:=cafRoundBracketClose;
    AntiCloseBracket:=cafEdgedBracketClose;
  end else if (Curpos.Flag=cafEdgedBracketOpen) then begin
    CloseBracket:=cafEdgedBracketClose;
    AntiCloseBracket:=cafRoundBracketClose;
  end else begin
    if ExceptionOnNotFound then
      RaiseBracketOpenExpectedButAtomFound;
    exit;
  end;
  Start:=CurPos;
  repeat
    ReadNextAtom;
    if (CurPos.Flag=CloseBracket) then break;
    if (CurPos.StartPos>SrcLen)
    or (CurPos.Flag in [cafEnd,cafRecord,AntiCloseBracket])
    then begin
      SetNiceErrorPos(Start.StartPos);
      if ExceptionOnNotFound then begin
        RaiseBracketNotFound;
      end;
      exit;
    end;
    if (CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen]) then begin
      if not ReadTilBracketClose(ExceptionOnNotFound) then exit;
    end;
  until false;
  Result:=true;
end;

function TCustomCodeTool.ReadBackTilBracketOpen(
  ExceptionOnNotFound: boolean): boolean;
// reads code brackets (not comment brackets)
var OpenBracket, AntiOpenBracket: TCommonAtomFlag;
  Start: TAtomPosition;
  
  procedure RaiseBracketNotFound;
  begin
    if OpenBracket=cafRoundBracketOpen then
      SaveRaiseExceptionFmt(ctsBracketNotFound,['('],true)
    else
      SaveRaiseExceptionFmt(ctsBracketNotFound,['['],true);
  end;
  
begin
  Result:=false;
  if (CurPos.Flag=cafRoundBracketClose) then begin
    OpenBracket:=cafRoundBracketOpen;
    AntiOpenBracket:=cafEdgedBracketOpen;
  end else if (CurPos.Flag=cafEdgedBracketClose) then begin
    OpenBracket:=cafEdgedBracketOpen;
    AntiOpenBracket:=cafRoundBracketOpen;
  end else begin
    if ExceptionOnNotFound then
      RaiseBracketCloseExpectedButAtomFound;
    exit;
  end;
  Start:=CurPos;
  repeat
    ReadPriorAtom;
    if (CurPos.Flag=OpenBracket) then break;
    if (CurPos.StartPos<1)
    or (CurPos.Flag in [AntiOpenBracket,cafEND,cafBegin]) then begin
      CurPos:=Start;
      if ExceptionOnNotFound then
        RaiseBracketNotFound;
      exit;
    end;
    if CurPos.Flag in [cafRoundBracketClose,cafEdgedBracketClose] then begin
      if not ReadBackTilBracketOpen(ExceptionOnNotFound) then exit;
    end;
  until false;
  Result:=true;
end;

procedure TCustomCodeTool.ReadTillCommentEnd;
var
  CommentLvl: Integer;
begin
  {$IFOPT R+}{$DEFINE RangeChecking}{$ENDIF}
  {$R-}
  case Src[CurPos.StartPos] of
  '{': // pascal comment
    begin
      CommentLvl:=1;
      inc(CurPos.StartPos);
      while true do begin
        case Src[CurPos.StartPos] of
        #0:  if CurPos.StartPos>SrcLen then break;
        '{': if Scanner.NestedComments then inc(CommentLvl);
        '}':
          begin
            dec(CommentLvl);
            if CommentLvl=0 then break;
          end;
        end;
        inc(CurPos.StartPos);
      end;
      inc(CurPos.StartPos);
    end;
  '/':  // Delphi comment
    if (Src[CurPos.StartPos+1]='/') then begin
      inc(CurPos.StartPos,2);
      while (not (Src[CurPos.StartPos] in [#10,#13,#0])) do
        inc(CurPos.StartPos);
      inc(CurPos.StartPos);
      if (CurPos.StartPos<=SrcLen) and (Src[CurPos.StartPos] in [#10,#13])
      and (Src[CurPos.StartPos-1]<>Src[CurPos.StartPos]) then
        inc(CurPos.StartPos);
    end;
  '(': // old turbo pascal comment
    if (Src[CurPos.StartPos+1]='*') then begin
      inc(CurPos.StartPos,3);
      while (CurPos.StartPos<=SrcLen)
      and ((Src[CurPos.StartPos-1]<>'*') or (Src[CurPos.StartPos]<>')')) do
        inc(CurPos.StartPos);
      inc(CurPos.StartPos);
    end;
  end;
  {$IFDEF RangeChecking}{$R+}{$UNDEF RangeChecking}{$ENDIF}
end;

procedure TCustomCodeTool.BeginParsing(DeleteNodes,
  OnlyInterfaceNeeded: boolean);
var
  LinkScanRange: TLinkScannerRange;
begin
  // scan
  FLastProgressPos:=0;
  CurrentPhase:=CodeToolPhaseScan;
  try
    if OnlyInterfaceNeeded then
      LinkScanRange:=lsrImplementationStart
    else
      LinkScanRange:=lsrEnd;
    Scanner.Scan(LinkScanRange,CheckFilesOnDisk);
    // update scanned code
    if FLastScannerChangeStep<>Scanner.ChangeStep then begin
      // code has changed
      ClearLastError;
      FLastScannerChangeStep:=Scanner.ChangeStep;
      Src:=Scanner.CleanedSrc;
      SrcLen:=length(Src);
      {$IFDEF VerboseUpdateNeeded}
      DebugLn(['TCustomCodeTool.BeginParsing FForceUpdateNeeded:=true ',MainFilename]);
      {$ENDIF}
      FForceUpdateNeeded:=true;
      DirtySrc.Free;
      DirtySrc:=nil;
    end else begin
      if LastErrorPhase=CodeToolPhaseScan then
        RaiseLastError;
    end;
    
    // delete nodes
    if DeleteNodes then DoDeleteNodes;

    // init parsing values
    CurPos:=StartAtomPosition;
    LastAtoms.Clear;
    NextPos.StartPos:=-1;
    CurNode:=nil;
  finally
    CurrentPhase:=CodeToolPhaseNone;
  end;
end;

procedure TCustomCodeTool.BeginParsingAndGetCleanPos(DeleteNodes,
  OnlyInterfaceNeeded: boolean; CursorPos: TCodeXYPosition;
  out CleanCursorPos: integer);
var Dummy: integer;
begin
  if UpdateNeeded(OnlyInterfaceNeeded) then
    BeginParsing(DeleteNodes,OnlyInterfaceNeeded);
  // find the CursorPos in cleaned source
  Dummy:=CaretToCleanPos(CursorPos, CleanCursorPos);
  if (Dummy<>0) and (Dummy<>-1) then begin
    MoveCursorToCleanPos(1);
    RaiseException(ctsCursorPosOutsideOfCode,true);
  end;
end;

function TCustomCodeTool.IsDirtySrcValid: boolean;
begin
  Result:=(DirtySrc<>nil) and (DirtySrc.Code<>nil);
end;

function TCustomCodeTool.IgnoreErrorAfterPositionIsInFrontOfLastErrMessage: boolean;
var
  IgnoreErrorAfterCleanPos: integer;
begin
  //DebugLn('TCustomCodeTool.IgnoreErrorAfterPositionIsInFrontOfLastErrMessage ',
  //  ' LastErrorCheckedForIgnored='+dbgs(LastErrorCheckedForIgnored),
  //  ' LastErrorBehindIgnorePosition='+dbgs(LastErrorBehindIgnorePosition));
  if LastErrorCheckedForIgnored then begin
    Result:=LastErrorBehindIgnorePosition;
  end else begin
    if (Scanner<>nil) then begin
      IgnoreErrorAfterCleanPos:=Scanner.IgnoreErrorAfterCleanedPos;
      //DebugLn(['  IgnoreErrorAfterCleanPos=',IgnoreErrorAfterCleanPos,' "',copy(Src,IgnoreErrorAfterCleanPos-6,6),'"',
      //  ' LastErrorCurPos.StartPos=',LastErrorCurPos.StartPos,' "',copy(Src,LastErrorCurPos.StartPos-6,6),'"',
      //  ' LastErrorPhase>CodeToolPhaseParse=',LastErrorPhase>CodeToolPhaseParse]);
      if IgnoreErrorAfterCleanPos>0 then begin
        // ignore position in scanned code
        // -> check if last error is behind or equal ignore position
        if (not LastErrorValid)
        or (IgnoreErrorAfterCleanPos<=LastErrorCurPos.StartPos) then
          Result:=true
        else
          Result:=false;
      end else
        Result:=false;
    end else
      Result:=false;
    LastErrorBehindIgnorePosition:=Result;
    LastErrorCheckedForIgnored:=true;
  end;
  {$IFDEF ShowIgnoreErrorAfter}
  DebugLn('TCustomCodeTool.IgnoreErrAfterPositionIsInFrontOfLastErrMessage ',dbgs(Result));
  {$ENDIF}
end;

function TCustomCodeTool.IgnoreErrorAfterValid: boolean;
begin
  Result:=(Scanner<>nil) and (Scanner.IgnoreErrorAfterValid);
  {$IFDEF ShowIgnoreErrorAfter}
  DebugLn('TCustomCodeTool.IgnoreErrorAfterValid ',dbgs(Result));
  {$ENDIF}
end;

function TCustomCodeTool.IgnoreErrorAfterCleanedPos: integer;
begin
  if Scanner<>nil then
    Result:=Scanner.IgnoreErrorAfterCleanedPos
  else
    Result:=-1;
  {$IFDEF ShowIgnoreErrorAfter}
  DebugLn('TCustomCodeTool.IgnoreErrorAfterCleanedPos ',dbgs(Result));
  {$ENDIF}
end;

function TCustomCodeTool.CleanPosIsAfterIgnorePos(CleanPos: integer): boolean;
begin
  Result:=(Scanner<>nil) and Scanner.CleanPosIsAfterIgnorePos(CleanPos);
end;

function TCustomCodeTool.LastErrorIsInFrontOfCleanedPos(ACleanedPos: integer
  ): boolean;
begin
  if (Scanner<>nil) and Scanner.LastErrorIsInFrontOfCleanedPos(ACleanedPos)
  then
    Result:=true
  else if (LastErrorValid)
  and (LastErrorCurPos.StartPos<ACleanedPos) then
    Result:=true
  else
    Result:=false;
  {$IFDEF ShowIgnoreErrorAfter}
  DebugLn('TCustomCodeTool.LastErrorsInFrontOfCleanedPos ACleanedPos=',dbgs(ACleanedPos),' ',dbgs(Result));
  {$ENDIF}
end;

procedure TCustomCodeTool.RaiseLastErrorIfInFrontOfCleanedPos(
  ACleanedPos: integer);
begin
  {$IFDEF ShowIgnoreErrorAfter}
  DebugLn('TCustomCodeTool.RaiseLastErrorIfInFrontOfCleanedPos A ACleanedPos=',dbgs(ACleanedPos));
  {$ENDIF}
  if Scanner<>nil then Scanner.RaiseLastErrorIfInFrontOfCleanedPos(ACleanedPos);
  //DebugLn('TCustomCodeTool.RaiseLastErrorIfInFrontOfCleanedPos B ',LastErrorPhase<CodeToolPhaseTool,' ',LastErrorCurPos.EndPos);
  if LastErrorValid
  and (LastErrorCurPos.StartPos<ACleanedPos) then
    RaiseLastError;
  //DebugLn('TCustomCodeTool.RaiseLastErrorIfInFrontOfCleanedPos END ');
end;

function TCustomCodeTool.StringIsKeyWord(const Word: string): boolean;
begin
  Result:=(Word<>'') and IsIdentStartChar[Word[1]]
                   and WordIsKeyWordFuncList.DoItUpperCase(Word,1,length(Word));
end;

procedure TCustomCodeTool.MoveCursorToNodeStart(ANode: TCodeTreeNode);
begin
  {$IFDEF CheckNodeTool}CheckNodeTool(ANode);{$ENDIF}
  MoveCursorToCleanPos(ANode.StartPos);
  CurNode:=ANode;
end;

procedure TCustomCodeTool.MoveCursorToCleanPos(ACleanPos: integer);
begin
  CurPos.StartPos:=ACleanPos;
  CurPos.EndPos:=ACleanPos;
  CurPos.Flag:=cafNone;
  LastAtoms.Clear;
  NextPos.StartPos:=-1;
  CurNode:=nil;
  HybridCursorType:=hcClean;
end;

procedure TCustomCodeTool.MoveCursorToCleanPos(ACleanPos: PChar);

  procedure RaiseSrcEmpty;
  begin
    RaiseException('[TCustomCodeTool.MoveCursorToCleanPos - PChar] Src empty',true);
  end;
  
  procedure RaiseNotInSrc;
  begin
    RaiseException('[TCustomCodeTool.MoveCursorToCleanPos - PChar] '
      +'CleanPos not in Src',true);
  end;

var NewPos: integer;
begin
  if Src='' then
    RaiseSrcEmpty;
  NewPos:=PtrInt(PtrUInt(ACleanPos))-PtrInt(PtrUInt(@Src[1]))+1;
  if (NewPos<1) or (NewPos>SrcLen) then
    RaiseNotInSrc;
  MoveCursorToCleanPos(NewPos);
end;

procedure TCustomCodeTool.MoveCursorToAtomPos(const AnAtomPos: TAtomPosition);
begin
  MoveCursorToCleanPos(AnAtomPos.StartPos);
  CurPos:=AnAtomPos;
end;

procedure TCustomCodeTool.MoveCursorToNearestAtom(ACleanPos: integer);
var
  ANode: TCodeTreeNode;
  BestPos: Integer;
begin
  ANode:=FindDeepestNodeAtPos(ACleanPos,true);
  if ANode=nil then
    RaiseException('TCustomCodeTool.MoveCursorToNearestAtom internal error',true);
  MoveCursorToNodeStart(ANode);
  BestPos:=CurPos.StartPos;
  while (CurPos.StartPos<=ACleanPos) and (CurPos.StartPos<=SrcLen) do begin
    BestPos:=CurPos.StartPos;
    ReadNextAtom;
  end;
  MoveCursorToCleanPos(BestPos);
end;

procedure TCustomCodeTool.MoveCursorToLastNodeAtom(ANode: TCodeTreeNode);
var
  BestPos: LongInt;
begin
  MoveCursorToNodeStart(ANode);
  BestPos:=CurPos.StartPos;
  while (CurPos.EndPos<=ANode.EndPos) and (CurPos.StartPos<=SrcLen) do begin
    BestPos:=CurPos.StartPos;
    ReadNextAtom;
  end;
  MoveCursorToCleanPos(BestPos);
end;

function TCustomCodeTool.IsPCharInSrc(ACleanPos: PChar): boolean;
var NewPos: integer;
begin
  Result:=false;
  if Src='' then exit;
  NewPos:=PtrInt(PtrUInt(ACleanPos))-PtrInt(PtrUInt(@Src[1]))+1;
  if (NewPos<1) or (NewPos>SrcLen) then exit;
  Result:=true;
end;

procedure TCustomCodeTool.MoveHybridCursorToPos(DirtyPos: PChar);
begin
  if IsDirtySrcValid and (not IsPCharInSrc(DirtyPos)) then begin
    DirtySrc.MoveCursorToPos(DirtyPos);
    HybridCursorType:=hcDirty;
  end else
    MoveCursorToCleanPos(DirtyPos);
end;

function TCustomCodeTool.GetHybridCursorStart: integer;
begin
  if HybridCursorType=hcDirty then
    Result:=DirtySrc.CurPos.StartPos
  else
    Result:=CurPos.StartPos;
end;

procedure TCustomCodeTool.CreateChildNode;
var NewNode: TCodeTreeNode;
begin
  NewNode:=NodeMemManager.NewNode;
  Tree.AddNodeAsLastChild(CurNode,NewNode);
  CurNode:=NewNode;
  CurNode.StartPos:=CurPos.StartPos;
end;

procedure TCustomCodeTool.EndChildNode;
begin
  CurNode:=CurNode.Parent;
end;

procedure TCustomCodeTool.BuildDefaultKeyWordFunctions;
begin
  KeyWordFuncList.Clear;
  KeyWordFuncList.DefaultKeyWordFunction:=
    {$ifdef FPC}@{$endif}DefaultKeyWordFunc;
end;

function TCustomCodeTool.DoAtom: boolean;
begin
  if (CurPos.StartPos>SrcLen) or (CurPos.EndPos<=CurPos.StartPos) then
    Result:=false
  else if IsIdentStartChar[Src[CurPos.StartPos]] then
    Result:=KeyWordFuncList.DoItCaseInsensitive(Src,CurPos.StartPos,
            CurPos.EndPos-CurPos.StartPos)
  else
    Result:=true;
end;

procedure TCustomCodeTool.SetIgnoreErrorAfter(const AValue: TCodePosition);
begin
  if (IgnoreErrorAfter.Code=AValue.Code)
  and (IgnoreErrorAfter.P=AValue.P) then exit;
  FIgnoreErrorAfter:=AValue;
  LastErrorCheckedForIgnored:=false;
  {$IFDEF ShowIgnoreErrorAfter}
  DebugLn('TCustomCodeTool.SetIgnoreErrorAfter FIgnoreErrorAfter=',dbgsCP(FIgnoreErrorAfter));
  {$ENDIF}
  if Scanner<>nil then
    Scanner.SetIgnoreErrorAfter(IgnoreErrorAfter.P,IgnoreErrorAfter.Code);
end;

procedure TCustomCodeTool.IncreaseTreeChangeStep(NodesDeleting: boolean);
begin
  //DebugLn(['TCustomCodeTool.IncreaseTreeChangeStep ',DbgSName(Self),' NodesDeleting=',NodesDeleting]);
  if FTreeChangeStep=High(integer) then
    FTreeChangeStep:=Low(integer)
  else
    inc(FTreeChangeStep);
  if NodesDeleting then begin
    //DebugLn(['TCustomCodeTool.IncreaseTreeChangeStep NodesDeleting ',MainFilename,' ',Tree<>nil,' ',(Tree<>nil) and (Tree.Root<>nil)]);
    if FNodesDeletedChangeStep=High(integer) then
      FNodesDeletedChangeStep:=Low(integer)
    else
      inc(FNodesDeletedChangeStep);
  end;
  if FOnTreeChange<>nil then
    FOnTreeChange(Self,NodesDeleting);
end;

procedure TCustomCodeTool.RaiseExceptionInstance(TheException: ECodeToolError;
  ClearNicePos: boolean);
var
  CaretXY: TCodeXYPosition;
  CursorPos: integer;
  Node: TCodeTreeNode;
begin
  ErrorPosition.Code:=nil;
  CursorPos:=CurPos.StartPos;
  //DebugLn('TCustomCodeTool.RaiseExceptionInstance CursorPos=',dbgs(CursorPos),' "',copy(Src,CursorPos-6,6),'"');
  
  if ClearNicePos then begin
    ErrorNicePosition.Code:=nil;
    ErrorNicePosition.Y:=-1;
  end;

  // close all open nodes, so that FindDeepestNodeAtPos works in the code
  // already parsed
  Node:=CurNode;
  while (Node<>nil) do begin
    if (Node.StartPos>=Node.EndPos) then
      Node.EndPos:=CursorPos;
    Node:=Node.Parent;
  end;
  // convert cursor pos to caret pos, which is more human readable
  if (CursorPos>SrcLen) and (SrcLen>0) then CursorPos:=SrcLen;
  if (CleanPosToCaret(CursorPos,CaretXY))
  and (CaretXY.Code<>nil) then begin
    ErrorPosition:=CaretXY;
  end else if (Scanner<>nil) and (Scanner.MainCode<>nil) then begin
    ErrorPosition.Code:=TCodeBuffer(Scanner.MainCode);
    ErrorPosition.Y:=-1;
  end;
  // raise the exception
  CurrentPhase:=CodeToolPhaseNone;
  if not RaiseUnhandableExceptions then
    raise TheException
  else
    RaiseCatchableException(TheException.Message);
end;

procedure TCustomCodeTool.RaiseExceptionClass(const AMessage: string;
  ExceptionClass: ECodeToolErrors; ClearNicePos: boolean);
begin
  RaiseExceptionInstance(ExceptionClass.Create(Self,AMessage),ClearNicePos);
end;

function TCustomCodeTool.DefaultKeyWordFunc: boolean;
begin
  Result:=true;
end;

procedure TCustomCodeTool.ConsistencyCheck;
begin
  Tree.ConsistencyCheck;
end;

procedure TCustomCodeTool.WriteDebugTreeReport;

  procedure WriteSrcSubString(A,Len: integer);
  var i: integer;
  begin
    DbgOut('"');
    for i:=A to A+Len-1 do begin
      if (i>0) and (i<SrcLen) and (ord(Src[i])>31) then
        DbgOut(Src[i]);
    end;
    DbgOut('"');
  end;

  procedure WriteSubTree(RootNode: TCodeTreeNode; Indent: string);
  begin
    while RootNode<>nil do begin
      DbgOut(Indent);
      with RootNode do begin
        DbgOut(NodeDescToStr(Desc)+'('+NodeSubDescToStr(Desc,SubDesc)+')  ');
        DbgOut(' Start='+DbgS(StartPos),' ');
        WriteSrcSubString(StartPos,5);
        DbgOut(' End='+DbgS(EndPos)+' ');
        WriteSrcSubString(EndPos-5,5);
        {$ifdef fpc}
        DbgOut(' Self=',DbgS(RootNode));
        DbgOut(' P=',DbgS(Parent));
        DbgOut(' NB=',DbgS(NextBrother));
        //write(' PB=',DbgS(PriorBrother));
        //write(' FC=',DbgS(FirstChild));
        //write(' LC=',DbgS(LastChild));
        {$endif}
      end;
      DebugLn('');
      WriteSubTree(RootNode.FirstChild,Indent+'  ');
      RootNode:=RootNode.NextBrother;
    end;
  end;

begin
  DebugLn('[TCustomCodeTool.WriteDebugTreeReport]');
  WriteSubTree(Tree.Root,'  ');
  ConsistencyCheck;
end;

procedure TCustomCodeTool.CalcMemSize(Stats: TCTMemStats);
begin
  Stats.Add(ClassName,InstanceSize);
  Stats.Add('TCustomCodeTool',MemSizeString(LastErrorMessage));
  if FScanner<>nil then
    FScanner.CalcMemSize(Stats);
  if (FScanner=nil) or (Pointer(FScanner.CleanedSrc)<>Pointer(Src)) then
    Stats.Add('TCustomCodeTool.Src',
      MemSizeString(Src));
  if KeyWordFuncList<>nil then
    Stats.Add('TCustomCodeTool.KeyWordFuncList',
      KeyWordFuncList.CalcMemSize);
  // Note: WordIsKeyWordFuncList is using the global list
  if Tree<>nil then
    Stats.Add('TCustomCodeTool.Tree',
      Tree.NodeCount*TCodeTreeNode.InstanceSize);
  if LastAtoms<>nil then
    Stats.Add('TCustomCodeTool.LastAtoms',
      LastAtoms.CalcMemSize);
  if DirtySrc<>nil then
    Stats.Add('TCustomCodeTool.DirtySrc',
      DirtySrc.CalcMemSize);
end;

procedure TCustomCodeTool.CheckNodeTool(Node: TCodeTreeNode);

  procedure RaiseForeignNode;
  begin
    RaiseCatchableException('TCustomCodeTool.CheckNodeTool '+DbgSName(Self)+' '+Node.DescAsString);
  end;

begin
  if Node=nil then exit;
  while Node.Parent<>nil do Node:=Node.Parent;
  while Node.PriorBrother<>nil do Node:=Node.PriorBrother;
  if (Tree=nil) or (Tree.Root<>Node) then
    RaiseForeignNode;
end;

function TCustomCodeTool.FindDeepestNodeAtPos(P: integer;
  ExceptionOnNotFound: boolean): TCodeTreeNode;
begin
  Result:=FindDeepestNodeAtPos(Tree.Root,P,ExceptionOnNotFound);
end;

function TCustomCodeTool.FindDeepestNodeAtPos(StartNode: TCodeTreeNode;
  P: integer; ExceptionOnNotFound: boolean): TCodeTreeNode;
  
  procedure RaiseNoNodeFoundAtCursor;
  begin
    //DebugLn('RaiseNoNodeFoundAtCursor ',MainFilename);
    RaiseException(ctsNoNodeFoundAtCursor,true);
  end;
  
var
  ChildNode: TCodeTreeNode;
  Brother: TCodeTreeNode;
  Node: TCodeTreeNode;
begin
  {$IFDEF CheckNodeTool}CheckNodeTool(StartNode);{$ENDIF}
  Result:=nil;
  Node:=StartNode;
  while Node<>nil do begin
    //DebugLn('SearchInNode ',NodeDescriptionAsString(ANode.Desc),
    //',',ANode.StartPos,',',ANode.EndPos,', p=',p,
    //' "',copy(Src,ANode.StartPos,4),'" - "',copy(Src,ANode.EndPos-5,4),'"');
    if (Node.StartPos<=P)
    and ((Node.EndPos>P) or (Node.EndPos<1)) then begin
      // StartNode contains P
      Result:=Node;
      // -> search for a child that contains P
      Brother:=Node;
      while (Brother<>nil)
      and (Brother.StartPos<=P) do begin
        // brother also contains P
        if Brother.FirstChild<>nil then begin
          ChildNode:=FindDeepestNodeAtPos(Brother.FirstChild,P,false);
          if ChildNode<>nil then begin
            Result:=ChildNode;
            exit;
          end else
            Result:=Brother;
        end;
        Brother:=Brother.NextBrother;
      end;
      break;
    end else begin
      // search in next node
      Node:=Node.NextBrother;
    end;
  end;
  if (Result=nil) and (Tree.Root<>nil) then begin
    Node:=Tree.Root;
    while Node.NextBrother<>nil do
      Node:=Node.NextBrother;
    if (Node<>nil) and (Node.EndPos=p) then begin
      // cursor at end of source
      Result:=Node;
      while (Result.LastChild<>nil) and (Result.LastChild.EndPos=p) do
        Result:=Result.LastChild;
      exit;
    end;
  end;

  if (Result=nil) and ExceptionOnNotFound then begin
    MoveCursorToCleanPos(P);
    RaiseNoNodeFoundAtCursor;
  end;
end;

function TCustomCodeTool.CaretToCleanPos(Caret: TCodeXYPosition;
  out CleanPos: integer): integer;
begin
  CleanPos:=0;
  //DebugLn('TCustomCodeTool.CaretToCleanPos A ',Caret.Code.Filename,' ',Caret.Code.SourceLength);
  Caret.Code.LineColToPosition(Caret.Y,Caret.X,CleanPos);
  //DebugLn('TCustomCodeTool.CaretToCleanPos B ',CleanPos,',',Caret.Y,',',Caret.X);
  if (CleanPos>=1) then
    Result:=Scanner.CursorToCleanPos(CleanPos,Caret.Code,CleanPos)
  else
    Result:=-2; // x,y beyond source
  //DebugLn('TCustomCodeTool.CaretToCleanPos C CleanPos=',CleanPos,' Result=',Result);
end;

function TCustomCodeTool.CleanPosToCodePos(CleanPos: integer;
  out CodePos: TCodePosition): boolean;
var
  ACode: pointer;
begin
  Result:=Scanner.CleanedPosToCursor(CleanPos,CodePos.p,ACode);
  CodePos.Code:=TCodeBuffer(ACode);
end;

function TCustomCodeTool.CleanPosToCaret(CleanPos: integer;
  out Caret:TCodeXYPosition): boolean; // true=ok, false=invalid CleanPos
var p: integer;
  Code: Pointer;
begin
  Caret:=CleanCodeXYPosition;
  Result:=Scanner.CleanedPosToCursor(CleanPos,p,Code);
  if Result then begin
    Caret.Code:=TCodeBuffer(Code);
    if Caret.Code.IsDeleted then exit(false);
    TCodeBuffer(Code).AbsoluteToLineCol(p,Caret.Y,Caret.X);
    Result:=(Caret.Y>=0);
  end;
end;

function TCustomCodeTool.CleanPosToCaretAndTopLine(CleanPos: integer;
  out Caret:TCodeXYPosition; out NewTopLine: integer): boolean;
// true=ok, false=invalid CleanPos
begin
  Caret:=CleanCodeXYPosition;
  NewTopLine:=0;
  Result:=CleanPosToCaret(CleanPos,Caret);
  if Result then begin
    if JumpCentered then begin
      NewTopLine:=Caret.Y-(VisibleEditorLines shr 1);
      if NewTopLine<1 then NewTopLine:=1;
    end else
      NewTopLine:=Caret.Y;
  end;
end;

function TCustomCodeTool.CleanPosToStr(CleanPos: integer;
  WithFilename: boolean): string;
var
  CodePos: TCodeXYPosition;
begin
  if CleanPosToCaret(CleanPos,CodePos) then begin
    if WithFilename then
      Result:=CodePos.Code.Filename+',y='+IntToStr(CodePos.Y)+',x='+IntToStr(CodePos.X)
    else
      Result:='y='+IntToStr(CodePos.Y)+',x='+IntToStr(CodePos.X);
  end else
    Result:='y=?,x=?';
end;

procedure TCustomCodeTool.GetCleanPosInfo(CodePosInFront, CleanPos: integer;
  ResolveComments: boolean; out SameArea: TAtomPosition);
var
  ANode: TCodeTreeNode;
begin
  SameArea:=CleanAtomPosition;
  if CodePosInFront<1 then begin
    ANode:=FindDeepestNodeAtPos(CleanPos,True);
    CodePosInFront:=ANode.StartPos;
  end;
  MoveCursorToCleanPos(CodePosInFront);
  repeat
    ReadNextAtom;
    //DebugLn(['TCustomCodeTool.GetCleanPosInfo A Atom=',GetAtom,' CleanPos=',CleanPos,' CurPos.StartPos=',CurPos.StartPos]);
    if (CleanPos>=CurPos.StartPos) and (CleanPos<CurPos.EndPos) then begin
      // clean pos on token
      SameArea:=CurPos;
      exit;
    end;
    if CleanPos<CurPos.StartPos then begin
      // clean pos between tokens
      SameArea.Flag:=cafNone;
      // get range of space behind last atom
      if LastAtoms.Count>0 then begin
        SameArea.StartPos:=LastAtoms.GetValueAt(0).EndPos;
      end else begin
        SameArea.StartPos:=CodePosInFront;
      end;
      SameArea.EndPos:=SameArea.StartPos;
      repeat
        //DebugLn(['TCustomCodeTool.GetCleanPosInfo B CleanPos=',CleanPos,' SameArea.StartPos=',SameArea.StartPos,' SameArea.EndPos=',SameArea.EndPos]);
        while (SameArea.EndPos<=SrcLen)
        and (IsSpaceChar[Src[SameArea.EndPos]]) do
          inc(SameArea.EndPos);
        if (SameArea.EndPos>CleanPos) or (SameArea.EndPos>SrcLen) then begin
          // cursor is in normal space (i.e. not comment)
          exit;
        end;
        // still between the two tokens, but end of space
        // -> here starts a comment
        SameArea.StartPos:=SameArea.EndPos;
        MoveCursorToCleanPos(SameArea.StartPos);
        ReadTillCommentEnd;
        SameArea.EndPos:=CurPos.StartPos;
        if (SameArea.StartPos=SameArea.EndPos) then
          RaiseException('TCustomCodeTool.GetCleanPosInfo Internal Error A',true);
        if CleanPos<SameArea.EndPos then begin
          // cursor is in comment
          if ResolveComments then begin
            // take comment as normal code and search again
            CodePosInFront:=SameArea.StartPos;
            case Src[CodePosInFront] of
            '{': inc(CodePosInFront);
            '(','/': inc(CodePosInFront,2);
            else
              RaiseException('TCustomCodeTool.GetCleanPosInfo Internal Error B',true);
            end;
            GetCleanPosInfo(CodePosInFront,CleanPos,true,SameArea);
          end;
          exit;
        end;
        SameArea.StartPos:=SameArea.EndPos;
      until false;
    end;
  until (CurPos.EndPos>CleanPos) or (CurPos.StartPos>SrcLen);
  SameArea:=CurPos;
end;

procedure TCustomCodeTool.GetLineInfo(ACleanPos: integer;
  out ALineStart, ALineEnd, AFirstAtomStart, ALastAtomEnd: integer);
begin
  if ACleanPos>=1 then begin
    if ACleanPos<=SrcLen then begin
      // search line start
      ALineStart:=ACleanPos;
      while (ALineStart>1) and (not (Src[ALineStart-1] in [#10,#13])) do
        dec(ALineStart);
      // search line end
      ALineEnd:=ACleanPos;
      while (ALineEnd<=SrcLen) and (not (Src[ALineEnd] in [#10,#13])) do
        inc(ALineEnd);
      // search first atom in line
      MoveCursorToCleanPos(ALineStart);
      ReadNextAtom;
      AFirstAtomStart:=CurPos.StartPos;
      // search last atom in line
      repeat
        ALastAtomEnd:=CurPos.EndPos;
        ReadNextAtom;
      until (CurPos.EndPos>ALineEnd) or (CurPos.StartPos>SrcLen);
    end else begin
      ALineStart:=Srclen+1;
      ALineEnd:=Srclen+1;
      AFirstAtomStart:=Srclen+1;
      ALastAtomEnd:=Srclen+1;
    end;
  end else begin
    ALineStart:=1;
    ALineEnd:=1;
    AFirstAtomStart:=1;
    ALastAtomEnd:=1;
  end;
end;

function TCustomCodeTool.FindLineEndOrCodeAfterPosition(StartPos: integer;
  SkipEmptyLines: boolean): integer;
{ Searches a nice position in the cleaned source after StartPos.
  It will skip any space or comments (not directives) till next
  line end or compiler directive or code or include file end.
}
var
  LinkIndex, LinkEnd: integer;
begin
  LinkIndex:=Scanner.LinkIndexAtCleanPos(StartPos);
  LinkEnd:=Scanner.LinkCleanedEndPos(LinkIndex);
  if LinkEnd>StartPos then
    Result:=BasicCodeTools.FindLineEndOrCodeAfterPosition(Src,
                  StartPos,LinkEnd-1,Scanner.NestedComments,true,SkipEmptyLines)
  else
    Result:=StartPos;
end;

function TCustomCodeTool.FindLineEndOrCodeInFrontOfPosition(StartPos: integer
  ): integer;
begin
  Result:=FindLineEndOrCodeInFrontOfPosition(StartPos,true);
end;

function TCustomCodeTool.FindLineEndOrCodeInFrontOfPosition(StartPos: integer;
  StopAtDirectives: boolean): integer;
{ Searches a nice position in the cleaned source in front of StartPos.
  It will skip any space or comments (not directives) till next
  line end or compiler directive or code or include file end.
}
var
  LinkIndex, LinkStart: integer;
begin
  LinkIndex:=Scanner.LinkIndexAtCleanPos(StartPos);
  LinkStart:=Scanner.Links[LinkIndex].CleanedPos;
  Result:=BasicCodeTools.FindLineEndOrCodeInFrontOfPosition(Src,
                    StartPos,LinkStart,Scanner.NestedComments,StopAtDirectives);
end;

procedure TCustomCodeTool.ClearIgnoreErrorAfter;
begin
  IgnoreErrorAfter:=CodePosition(0,nil);
end;

function TCustomCodeTool.UpdateNeeded(OnlyInterfaceNeeded: boolean): boolean;
var
  LinkScanRange: TLinkScannerRange;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCustomCodeTool.UpdateNeeded A ',dbgs(Scanner<>nil),' FForceUpdateNeeded=',dbgs(FForceUpdateNeeded));
  {$ENDIF}
  if FForceUpdateNeeded then begin
    Result:=true;
    exit;
  end;
  if (FLastScannerChangeStep<>Scanner.ChangeStep) then begin
    {$IFDEF VerboseUpdateNeeded}
    DebugLn(['TCustomCodeTool.UpdateNeeded because FLastScannerChangeStep<>Scanner.ChangeStep ',MainFilename]);
    {$ENDIF}
    Result:=true;
  end else begin
    if OnlyInterfaceNeeded then
      LinkScanRange:=lsrImplementationStart
    else
      LinkScanRange:=lsrEnd;
    Result:=Scanner.UpdateNeeded(LinkScanRange, CheckFilesOnDisk);
    {$IFDEF VerboseUpdateNeeded}
    if Result then
      DebugLn(['TCustomCodeTool.UpdateNeeded because Scanner.UpdateNeeded ',MainFilename]);
    {$ENDIF}
  end;
  FForceUpdateNeeded:=Result;
  {$IFDEF CTDEBUG}
  DebugLn('TCustomCodeTool.UpdateNeeded END  Result=',dbgs(Result));
  {$ENDIF}
end;

function TCustomCodeTool.CompareSrcIdentifiers(Identifier1, Identifier2: PChar
  ): boolean;
begin
  Result:=false;
  if (Identifier1=nil) or (Identifier2=nil) then exit;
  while IsIdentChar[Identifier1^] do begin
    if (UpChars[Identifier1^]=UpChars[Identifier2^]) then begin
      inc(Identifier1);
      inc(Identifier2);
    end else
      exit(false);
  end;
  Result:=not IsIdentChar[Identifier2^];
end;

function TCustomCodeTool.CompareSrcIdentifiers(CleanStartPos: integer;
  AnIdentifier: PChar): boolean;
begin
  Result:=false;
  if (AnIdentifier=nil) or (CleanStartPos<1) or (CleanStartPos>SrcLen) then
    exit;
  while IsIdentChar[AnIdentifier^] do begin
    if (UpChars[AnIdentifier^]=UpChars[Src[CleanStartPos]]) then begin
      inc(AnIdentifier);
      inc(CleanStartPos);
      if CleanStartPos>SrcLen then begin
        Result:=not IsIdentChar[AnIdentifier^];
        exit;
      end;
    end else
      exit(false);
  end;
  Result:=not IsIdentChar[Src[CleanStartPos]];
end;

function TCustomCodeTool.CompareSrcIdentifiersMethod(Identifier1,
  Identifier2: Pointer): integer;
begin
  Result:=CompareIdentifiers(Identifier1,Identifier2);
end;

function TCustomCodeTool.ExtractIdentifier(CleanStartPos: integer): string;
var len: integer;
begin
  if (CleanStartPos>=1) then begin
    len:=0;
    while (CleanStartPos<=SrcLen)
    and (IsIdentChar[Src[CleanStartPos+len]]) do
      inc(len);
    SetLength(Result,len);
    if len>0 then
      Move(Src[CleanStartPos],Result[1],len);
  end else
    Result:='';
end;

procedure TCustomCodeTool.DoDeleteNodes;
begin
  if Tree.Root<>nil then begin
    //DebugLn(['TCustomCodeTool.DoDeleteNodes ',MainFilename]);
    // first notify, so that references could be deleted clean
    IncreaseTreeChangeStep(true);
    // then change
    Tree.Clear;
  end;
end;

procedure TCustomCodeTool.RaiseIdentExpectedButAtomFound;
begin
  SaveRaiseExceptionFmt(ctsIdentExpectedButAtomFound,[GetAtom],true);
end;

procedure TCustomCodeTool.RaiseBracketOpenExpectedButAtomFound;
begin
  SaveRaiseExceptionFmt(ctsBracketOpenExpectedButAtomFound,[GetAtom],true);
end;

procedure TCustomCodeTool.RaiseBracketCloseExpectedButAtomFound;
begin
  SaveRaiseExceptionFmt(ctsBracketCloseExpectedButAtomFound,[GetAtom],true);
end;

procedure TCustomCodeTool.ActivateGlobalWriteLock;
begin
  if Assigned(OnSetGlobalWriteLock) then OnSetGlobalWriteLock(true);
end;

procedure TCustomCodeTool.DeactivateGlobalWriteLock;
begin
  if Assigned(OnSetGlobalWriteLock) then OnSetGlobalWriteLock(false);
end;

function TCustomCodeTool.MainFilename: string;
begin
  if (Scanner<>nil) and (Scanner.MainCode<>nil) then
    Result:=TCodeBuffer(Scanner.MainCode).Filename
  else
    Result:=ctsUnknownMainFilename;
end;

{ ECodeToolError }

constructor ECodeToolError.Create(ASender: TCustomCodeTool;
  const AMessage: string);
begin
  inherited Create(AMessage);
  Sender:=ASender;
end;

{ ECodeToolFileNotFound }

constructor ECodeToolFileNotFound.Create(ASender: TCustomCodeTool;
  const AMessage, AFilename: string);
begin
  inherited Create(ASender,AMessage);
  Filename:=AFilename;
end;

{ TDirtySource }

procedure TDirtySource.BeginUpdate;
begin
  inc(LockCount);
end;

procedure TDirtySource.EndUpdate;
begin
  if LockCount<=0 then
    RaiseCatchableException('TDirtySource.EndUpdate');
  dec(LockCount);
end;

procedure TDirtySource.SetGap(const NewCursorPos: TCodeXYPosition;
  NewDirtyStartPos, NewDirtyGapStart, NewDirtyGapEnd: integer);
begin
  // check for conflicts
  if (LockCount>0) then begin
    if (Code<>nil) and (Code<>NewCursorPos.Code) then
      RaiseCatchableException('TDirtySource.SetGap Code change');
    if (GapStart>0) then
      if (NewDirtyStartPos<>StartPos)
      or (NewDirtyGapStart<>GapStart)
      or (NewDirtyGapEnd<>GapEnd) then
        RaiseCatchableException('TDirtySource.SetGap Gap change');
  end;
  if (NewDirtyGapStart>NewDirtyStartPos)
  or (NewDirtyStartPos>NewDirtyGapEnd) then
    RaiseCatchableException('TDirtySource.SetGap Gap Bounds');

  // set values
  CursorPos:=NewCursorPos;
  Code:=CursorPos.Code;
  StartPos:=NewDirtyStartPos;
  GapStart:=NewDirtyGapStart;
  GapEnd:=NewDirtyGapEnd;
  CurPos.StartPos:=StartPos;
  CurPos.EndPos:=StartPos;
  CurPos.Flag:=cafNone;

  // get source
  if Code<>nil then
    Src:=Code.Source
  else
    Src:='';
  if (GapStart>0) then begin
    GapSrc:=copy(Src,GapStart,GapEnd-GapStart);
    {$IFDEF ShowDirtySrc}
    DebugLn('TDirtySource.SetGap Owner=',ExtractFilename(Owner.MainFilename),
      ' Code=',ExtractFilename(Code.Filename),
      ' Gap('+dbgs(GapStart)+','+dbgs(StartPos)+','+dbgs(GapEnd)+')',
      '"',StringToPascalConst(copy(GapSrc,1,20)),'"..',
      '"',StringToPascalConst(copy(GapSrc,length(GapSrc)-19,20)),'"'
      );
    {$ENDIF}
  end else begin
    GapSrc:='';
  end;
end;

constructor TDirtySource.Create(TheOwner: TCustomCodeTool);
begin
  Owner:=TheOwner;
end;

procedure TDirtySource.Clear;
begin
  SetGap(CodeXYPosition(0,0,nil),0,0,0);
end;

procedure TDirtySource.SetCursorToIdentStartEndAtPosition;
begin
  GetIdentStartEndAtPosition(GapSrc,CurPos.StartPos,
                             CurPos.StartPos,CurPos.EndPos);
end;

function TDirtySource.GetCursorSrcPos: PChar;
begin
  Result:=@Src[CurPos.StartPos];
end;

function TDirtySource.IsPCharInSrc(p: PChar): boolean;
var NewPos: integer;
begin
  Result:=false;
  if Src='' then exit;
  NewPos:=PtrInt(PtrUInt(p))-PtrInt(PtrUInt(@Src[1]))+1;
  if (NewPos<1) or (NewPos>length(Src)) then exit;
  Result:=true;
end;

procedure TDirtySource.MoveCursorToPos(APos: integer);
begin
  CurPos.StartPos:=APos;
  CurPos.EndPos:=APos;
  CurPos.Flag:=cafNone;
end;

procedure TDirtySource.MoveCursorToPos(APos: PChar);

  procedure RaiseSrcEmpty;
  begin
    RaiseCatchableException('[TDirtySource.MoveCursorToPos - PChar] Src empty');
  end;

  procedure RaiseNotInSrc;
  begin
    RaiseCatchableException('[TDirtySource.MoveCursorToPos - PChar] Pos not in Src');
  end;

var NewPos: integer;
begin
  if Src='' then
    RaiseSrcEmpty;
  NewPos:=PtrInt(PtrUInt(APos))-PtrInt(PtrUInt(@Src[1]))+1;
  if (NewPos<1) or (NewPos>length(Src)) then
    RaiseNotInSrc;
  MoveCursorToPos(NewPos);
end;

function TDirtySource.CalcMemSize: PtrUInt;
begin
  Result:=PtrUInt(InstanceSize)
    +MemSizeString(Src)
    +MemSizeString(GapSrc);
end;

initialization
  RaiseUnhandableExceptions:=false;

end.
