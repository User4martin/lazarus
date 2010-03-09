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
    TIdentCompletionTool enhances the TFindDeclarationTool with the ability
    to create lists of valid identifiers at a specific code position.
}
unit IdentCompletionTool;

{$mode objfpc}{$H+}

interface

{$I codetools.inc}

// activate for debug:

// mem check
{ $DEFINE MEM_CHECK}

// verbosity
{ $DEFINE CTDEBUG}
{ $DEFINE ShowFoundIdents}
{ $DEFINE ShowFilteredIdents}
{ $DEFINE ShowHistory}

// new features
{ $DEFINE DisableIgnoreErrorAfter}


uses
  {$IFDEF MEM_CHECK}
  MemCheck,
  {$ENDIF}
  Classes, SysUtils, FileProcs, CodeTree, CodeAtom, CustomCodeTool,
  CodeToolsStrConsts, KeywordFuncLists, BasicCodeTools, LinkScanner,
  AVL_Tree, CodeToolMemManager, DefineTemplates,
  SourceChanger, FindDeclarationTool, PascalParserTool;
  

type
  TIdentCompletionTool = class;
  TIdentifierHistoryList = class;

  //----------------------------------------------------------------------------
  // gathered identifier list

  TIdentifierCompatibility = (
    icompExact,
    icompCompatible,
    icompUnknown,
    icompIncompatible
    );
  TIdentifierCompatibilities = set of TIdentifierCompatibility;
  
  TIdentListItemFlag = (
    iliHasChilds,
    iliBaseExprTypeValid,
    iliIsFunction,
    iliIsFunctionValid,
    iliIsAbstractMethod,
    iliIsAbstractMethodValid,
    iliParamTypeListValid,
    iliParamNameListValid,
    iliNodeValid,
    iliNodeHashValid,
    iliIsConstructor,
    iliIsConstructorValid,
    iliIsDestructor,
    iliIsDestructorValid,
    iliKeyword,
    iliResultTypeValid
    );
  TIdentListItemFlags = set of TIdentListItemFlag;
  
  { TIdentifierListSearchItem }

  TIdentifierListSearchItem = class
  public
    Identifier: PChar;
    ParamList: string;
    function CalcMemSize: PtrUInt;
  end;

  { TIdentifierListItem }

  TIdentifierListItem = class
  private
    FNext: TIdentifierListItem;
    FParamTypeList: string;
    FParamNameList: string;
    FNode: TCodeTreeNode;
    FResultType: string;
    FToolNodesDeletedStep: integer;// only valid if iliNodeValid
    FNodeStartPos: integer;
    FNodeDesc: TCodeTreeNodeDesc;
    FNodeHash: string;
    function GetNode: TCodeTreeNode;
    function GetParamTypeList: string;
    function GetParamNameList: string;
    procedure SetNode(const AValue: TCodeTreeNode);
    procedure SetParamTypeList(const AValue: string);
    procedure SetParamNameList(const AValue: string);
    procedure SetResultType(const AValue: string);
  public
    Compatibility: TIdentifierCompatibility;
    HistoryIndex: integer;
    Identifier: string;
    Level: integer;
    Tool: TFindDeclarationTool;
    DefaultDesc: TCodeTreeNodeDesc;
    Flags: TIdentListItemFlags;
    BaseExprType: TExpressionType;
    function AsString: string;
    function GetDesc: TCodeTreeNodeDesc;
    constructor Create(NewCompatibility: TIdentifierCompatibility;
                       NewHasChilds: boolean; NewHistoryIndex: integer;
                       NewIdentifier: PChar; NewLevel: integer;
                       NewNode: TCodeTreeNode; NewTool: TFindDeclarationTool;
                       NewDefaultDesc: TCodeTreeNodeDesc);
    function IsProcNodeWithParams: boolean;
    function IsPropertyWithParams: boolean;
    function CheckHasChilds: boolean;
    function CanBeAssigned: boolean;
    procedure UpdateBaseContext;
    function HasChilds: boolean;
    function IsFunction: boolean;
    function IsContructor: boolean;
    function IsDestructor: boolean;
    function IsAbstractMethod: boolean;
    function TryIsAbstractMethod: boolean;
    procedure Clear;
    procedure UnbindNode;
    procedure StoreNodeHash;
    function RestoreNode: boolean;
    function GetNodeHash(ANode: TCodeTreeNode): string;
    function CompareParamList(CompareItem: TIdentifierListItem): integer;
    function CompareParamList(CompareItem: TIdentifierListSearchItem): integer;
    function CalcMemSize: PtrUInt;
  public
    property ParamTypeList: string read GetParamTypeList write SetParamTypeList;
    property ParamNameList: string read GetParamNameList write SetParamNameList;
    property ResultType: string read FResultType write SetResultType;
    property Node: TCodeTreeNode read GetNode write SetNode;
  end;
  
  TIdentifierListFlag = (ilfFilteredListNeedsUpdate);
  TIdentifierListFlags = set of TIdentifierListFlag;
  
  TIdentifierListContextFlag = (
    ilcfStartInStatement,  // context starts in statements. e.g. between begin..end
    ilcfStartOfStatement,  // atom is start of statement. e.g. 'A|:=' or 'A|;', does not check if A can be assigned
    ilcfStartOfOperand,    // atom is start of an operand. e.g. 'A|.B'
    ilcfStartIsSubIdent,   // atom in front is point
    ilcfNeedsEndSemicolon, // after context a semicolon is needed. e.g. 'A| end'
    ilcfNoEndSemicolon,    // no semicolon after. E.g. 'A| else'
    ilcfNeedsEndComma,     // after context a comma is needed. e.g. 'sysutil| classes'
    ilcfIsExpression,      // is expression part of statement. e.g. 'if expr'
    ilcfCanProcDeclaration,// context allows to declare a procedure/method
    ilcfEndOfLine          // atom at end of line
    );
  TIdentifierListContextFlags = set of TIdentifierListContextFlag;
  
  TIdentifierList = class
  private
    FContext: TFindContext;
    FContextFlags: TIdentifierListContextFlags;
    FStartAtomBehind: TAtomPosition;
    FStartAtomInFront: TAtomPosition;
    FStartBracketLvl: integer;
    FStartContextPos: TCodeXYPosition;
    FCreatedIdentifiers: TFPList; // list of PChar
    FFilteredList: TFPList; // list of TIdentifierListItem
    FFlags: TIdentifierListFlags;
    FHistory: TIdentifierHistoryList;
    FItems: TAVLTree; // tree of TIdentifierListItem (completely sorted)
    FIdentView: TAVLTree; // tree of TIdentHistListItem sorted for identifiers
    FIdentSearchItem: TIdentifierListSearchItem;
    FPrefix: string;
    FStartContext: TFindContext;
    procedure SetContextFlags(const AValue: TIdentifierListContextFlags);
    procedure SetHistory(const AValue: TIdentifierHistoryList);
    procedure UpdateFilteredList;
    function GetFilteredItems(Index: integer): TIdentifierListItem;
    procedure SetPrefix(const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(NewItem: TIdentifierListItem);
    function Count: integer;
    function GetFilteredCount: integer;
    function HasIdentifier(Identifier: PChar; const ParamList: string): boolean;
    function FindIdentifier(Identifier: PChar; const ParamList: string): TIdentifierListItem;
    function FindCreatedIdentifier(const Ident: string): integer;
    function CreateIdentifier(const Ident: string): PChar;
    function StartUpAtomInFrontIs(const s: string): boolean;
    function StartUpAtomBehindIs(const s: string): boolean;
    function CompletePrefix(const OldPrefix: string): string;
    procedure ToolTreeChange(Tool: TCustomCodeTool; NodesDeleting: boolean);
    function CalcMemSize: PtrUInt;
  public
    property Context: TFindContext read FContext write FContext;
    property ContextFlags: TIdentifierListContextFlags
                                       read FContextFlags write SetContextFlags;
    property FilteredItems[Index: integer]: TIdentifierListItem
                                                          read GetFilteredItems;
    property History: TIdentifierHistoryList read FHistory write SetHistory;
    property Prefix: string read FPrefix write SetPrefix;
    property StartAtomInFront: TAtomPosition
                                 read FStartAtomInFront write FStartAtomInFront;
    property StartAtomBehind: TAtomPosition
                                   read FStartAtomBehind write FStartAtomBehind;
    property StartBracketLvl: integer
                                   read FStartBracketLvl write FStartBracketLvl;
    property StartContext: TFindContext read FStartContext write FStartContext;
    property StartContextPos: TCodeXYPosition
                                   read FStartContextPos write FStartContextPos;
  end;
  
  //----------------------------------------------------------------------------
  // history list

  { TIdentHistListItem }

  TIdentHistListItem = class
  public
    Identifier: string;
    NodeDesc: TCodeTreeNodeDesc;
    ParamList: string;
    HistoryIndex: integer;
    function CalcMemSize: PtrUInt;
  end;

  { TIdentifierHistoryList }

  TIdentifierHistoryList = class
  private
    FCapacity: integer;
    FItems: TAVLTree; // tree of TIdentHistListItem
    procedure SetCapacity(const AValue: integer);
    function FindItem(NewItem: TIdentifierListItem): TAVLTreeNode;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(NewItem: TIdentifierListItem);
    function GetHistoryIndex(AnItem: TIdentifierListItem): integer;
    function Count: integer;
    function CalcMemSize: PtrUInt;
  public
    property Capacity: integer read FCapacity write SetCapacity;
  end;


  //----------------------------------------------------------------------------
  { TCodeContextInfo }

  { TCodeContextInfoItem }

  TCodeContextInfoItem = class
  public
    Expr: TExpressionType;
    // compiler predefined proc
    ProcName: string;
    Params: TStringList;
    ResultType: string;
    destructor Destroy; override;
  end;

  TCodeContextInfo = class
  private
    FEndPos: integer;
    FItems: TFPList; // list of TCodeContextInfoItem
    FParameterIndex: integer;
    FProcName: string;
    FProcNameAtom: TAtomPosition;
    FStartPos: integer;
    FTool: TFindDeclarationTool;
    function GetItems(Index: integer): TCodeContextInfoItem;
  public
    constructor Create;
    destructor Destroy; override;
    function Count: integer;
    property Items[Index: integer]: TCodeContextInfoItem read GetItems; default;
    function Add(const Context: TExpressionType): integer;
    function AddCompilerProc: integer;
    procedure Clear;
    property Tool: TFindDeclarationTool read FTool write FTool;
    property ParameterIndex: integer read FParameterIndex write FParameterIndex;// 1 based
    property ProcName: string read FProcName write FProcName;
    property ProcNameAtom: TAtomPosition read FProcNameAtom write FProcNameAtom;
    property StartPos: integer read FStartPos write FStartPos;// context is valid from StartPos to EndPos
    property EndPos: integer read FEndPos write FEndPos;

    function CalcMemSize: PtrUInt;
  end;

  //----------------------------------------------------------------------------
  // TIdentCompletionTool

  TIdentCompletionTool = class(TFindDeclarationTool)
  private
    LastGatheredIdentParent: TCodeTreeNode;
    LastGatheredIdentLevel: integer;
    ClassAndAncestors: TFPList;// list of PCodeXYPosition
    FoundPublicProperties: TAVLTree;// tree of PChar (pointing to the
                                    // property names in source)
    FoundMethods: TAVLTree;// tree of TCodeTreeNodeExtension Txt=clean text
  protected
    CurrentIdentifierList: TIdentifierList;
    CurrentContexts: TCodeContextInfo;
    function CollectAllIdentifiers(Params: TFindDeclarationParams;
      const FoundContext: TFindContext): TIdentifierFoundResult;
    procedure GatherPredefinedIdentifiers(CleanPos: integer;
      const Context: TFindContext; BeautifyCodeOptions: TBeautifyCodeOptions);
    procedure GatherUsefulIdentifiers(CleanPos: integer;
      const Context: TFindContext; BeautifyCodeOptions: TBeautifyCodeOptions);
    procedure GatherUnitnames(CleanPos: integer;
      const Context: TFindContext; BeautifyCodeOptions: TBeautifyCodeOptions);
    procedure GatherSourceNames(const Context: TFindContext);
    procedure GatherContextKeywords(const Context: TFindContext; CleanPos: integer);
    procedure InitCollectIdentifiers(const CursorPos: TCodeXYPosition;
      var IdentifierList: TIdentifierList);
    procedure ParseSourceTillCollectionStart(const CursorPos: TCodeXYPosition;
      out CleanCursorPos: integer; out CursorNode: TCodeTreeNode;
      out IdentStartPos, IdentEndPos: integer);
    function FindIdentifierStartPos(const CursorPos: TCodeXYPosition
                                      ): TCodeXYPosition;
    procedure FindCollectionContext(Params: TFindDeclarationParams;
      IdentStartPos: integer; CursorNode: TCodeTreeNode;
      out GatherContext: TFindContext; out ContextExprStartPos: LongInt;
      out StartInSubContext: Boolean);
    function CollectAllContexts(Params: TFindDeclarationParams;
      const FoundContext: TFindContext): TIdentifierFoundResult;
    procedure AddCollectionContext(Tool: TFindDeclarationTool;
      Node: TCodeTreeNode);
    procedure InitFoundMethods;
    procedure ClearFoundMethods;
    function CollectMethods(Params: TFindDeclarationParams;
      const FoundContext: TFindContext): TIdentifierFoundResult;
  public
    function GatherIdentifiers(const CursorPos: TCodeXYPosition;
                            var IdentifierList: TIdentifierList;
                            BeautifyCodeOptions: TBeautifyCodeOptions): boolean;
    function FindCodeContext(const CursorPos: TCodeXYPosition;
                             out CodeContexts: TCodeContextInfo): boolean;
    function FindAbstractMethods(const CursorPos: TCodeXYPosition;
                                 out ListOfPCodeXYPosition: TFPList;
                                 SkipAbstractsInStartClass: boolean = false): boolean;
    function GetValuesOfCaseVariable(const CursorPos: TCodeXYPosition;
                                     List: TStrings): boolean;

    procedure CalcMemSize(Stats: TCTMemStats); override;
  end;
  
const
  IdentifierCompatibilityNames: array[TIdentifierCompatibility] of string = (
    'icompExact',
    'icompCompatible',
    'icompUnknown',
    'icompIncompatible'
    );

implementation

function CompareIdentListItems(Data1, Data2: Pointer): integer;
var
  Item1: TIdentifierListItem;
  Item2: TIdentifierListItem;
begin
  Item1:=TIdentifierListItem(Data1);
  Item2:=TIdentifierListItem(Data2);
  
  // first sort for Compatibility  (lower is better)
  if ord(Item1.Compatibility)<ord(Item2.Compatibility) then begin
    Result:=-1;
    exit;
  end else if ord(Item1.Compatibility)>ord(Item2.Compatibility) then begin
    Result:=1;
    exit;
  end;
  
  // then sort for History (lower is better)
  if Item1.HistoryIndex<Item2.HistoryIndex then begin
    Result:=-1;
    exit;
  end else if Item1.HistoryIndex>Item2.HistoryIndex then begin
    Result:=1;
    exit;
  end;

  // then sort for Level (lower is better)
  if Item1.Level<Item2.Level then begin
    Result:=-1;
    exit;
  end else if Item1.Level>Item2.Level then begin
    Result:=1;
    exit;
  end;

  // then sort alpabetically (lower is better)
  Result:=CompareIdentifierPtrs(Pointer(Item2.Identifier),Pointer(Item1.Identifier));
  if Result<>0 then exit;
  
  // then sort for ParamList (lower is better)
  Result:=Item2.CompareParamList(Item1);
end;

function CompareIdentListItemsForIdents(Data1, Data2: Pointer): integer;
var
  Item1: TIdentifierListItem;
  Item2: TIdentifierListItem;
begin
  Item1:=TIdentifierListItem(Data1);
  Item2:=TIdentifierListItem(Data2);

  // sort alpabetically (lower is better)
  Result:=CompareIdentifierPtrs(Pointer(Item2.Identifier),Pointer(Item1.Identifier));
  if Result<>0 then exit;

  // then sort for ParamList (lower is better)
  Result:=Item2.CompareParamList(Item1);
end;

function CompareIdentListSearchWithItems(SearchItem, Item: Pointer): integer;
var
  TheSearchItem: TIdentifierListSearchItem;
  TheItem: TIdentifierListItem;
begin
  TheSearchItem:=TIdentifierListSearchItem(SearchItem);
  TheItem:=TIdentifierListItem(Item);

  // sort alpabetically (lower is better)
  Result:=CompareIdentifierPtrs(Pointer(TheItem.Identifier),TheSearchItem.Identifier);
  if Result<>0 then exit;

  // then sort for ParamList (lower is better)
  Result:=TheItem.CompareParamList(TheSearchItem);
end;

function CompareIdentHistListItem(Data1, Data2: Pointer): integer;
var
  Item1: TIdentHistListItem;
  Item2: TIdentHistListItem;
begin
  Item1:=TIdentHistListItem(Data1);
  Item2:=TIdentHistListItem(Data2);

  Result:=CompareIdentifiers(PChar(Pointer(Item2.Identifier)),
                             PChar(Pointer(Item1.Identifier)));
  if Result<>0 then exit;

  //debugln('CompareIdentHistListItem ',Item2.Identifier,'=',Item1.Identifier);
  Result:=CompareIdentifiers(PChar(Pointer(Item2.ParamList)),
                             PChar(Pointer(Item1.ParamList)));
end;

function CompareIdentItemWithHistListItem(Data1, Data2: Pointer): integer;
var
  IdentItem: TIdentifierListItem;
  HistItem: TIdentHistListItem;
begin
  IdentItem:=TIdentifierListItem(Data1);
  HistItem:=TIdentHistListItem(Data2);

  Result:=CompareIdentifierPtrs(Pointer(HistItem.Identifier),
                                Pointer(IdentItem.Identifier));
  if Result<>0 then exit;

  //debugln('CompareIdentItemWithHistListItem ',HistItem.Identifier,'=',GetIdentifier(IdentItem.Identifier));
  Result:=SysUtils.CompareText(HistItem.ParamList,IdentItem.ParamTypeList);
end;

type
  TIdentifierListItemMemManager = class(TCodeToolMemManager)
  protected
    procedure FreeFirstItem; override;
  public
    procedure DisposeIdentListItem(IdentListItem: TIdentifierListItem);
    function NewIdentListItem(NewCompatibility: TIdentifierCompatibility;
      NewHasChilds: boolean; NewHistoryIndex: integer;
      NewIdentifier: PChar; NewLevel: integer;
      NewNode: TCodeTreeNode; NewTool: TFindDeclarationTool;
      NewDefaultDesc: TCodeTreeNodeDesc): TIdentifierListItem;
  end;
  
var
  IdentifierListItemMemManager: TIdentifierListItemMemManager;

{ TIdentifierListItemMemManager }

procedure TIdentifierListItemMemManager.FreeFirstItem;
var Item: TIdentifierListItem;
begin
  Item:=TIdentifierListItem(FFirstFree);
  TIdentifierListItem(FFirstFree):=Item.FNext;
  Item.Free;
end;

procedure TIdentifierListItemMemManager.DisposeIdentListItem(
  IdentListItem: TIdentifierListItem);
begin
  if (FFreeCount<FMinFree) or (FFreeCount<((FCount shr 3)*FMaxFreeRatio)) then
  begin
    // add IdentListItem to Free list
    IdentListItem.FNext:=TIdentifierListItem(FFirstFree);
    TIdentifierListItem(FFirstFree):=IdentListItem;
    inc(FFreeCount);
  end else begin
    // free list full -> free IdentListItem
    IdentListItem.Free;
    {$IFDEF DebugCTMemManager}
    inc(FFreedCount);
    {$ENDIF}
  end;
  dec(FCount);
end;

function TIdentifierListItemMemManager.NewIdentListItem(
  NewCompatibility: TIdentifierCompatibility;
  NewHasChilds: boolean; NewHistoryIndex: integer;
  NewIdentifier: PChar; NewLevel: integer;
  NewNode: TCodeTreeNode; NewTool: TFindDeclarationTool;
  NewDefaultDesc: TCodeTreeNodeDesc): TIdentifierListItem;
begin
  if FFirstFree<>nil then begin
    // take from free list
    Result:=TIdentifierListItem(FFirstFree);
    // ToDo: set values
    TIdentifierListItem(FFirstFree):=Result.FNext;
    Result.FNext:=nil;
    dec(FFreeCount);
  end else begin
    // free list empty -> create new node
    Result:=TIdentifierListItem.Create(NewCompatibility,
      NewHasChilds,NewHistoryIndex,NewIdentifier,NewLevel,
      NewNode,NewTool,
      NewDefaultDesc);
    {$IFDEF DebugCTMemManager}
    inc(FAllocatedCount);
    {$ENDIF}
  end;
  inc(FCount);
end;

{ TIdentifierList }

procedure TIdentifierList.SetPrefix(const AValue: string);
begin
  if FPrefix=AValue then exit;
  FPrefix:=AValue;
  Include(FFlags,ilfFilteredListNeedsUpdate);
end;

procedure TIdentifierList.UpdateFilteredList;
var
  AnAVLNode: TAVLTreeNode;
  CurItem: TIdentifierListItem;
begin
  if not (ilfFilteredListNeedsUpdate in FFlags) then exit;
  if FFilteredList=nil then FFilteredList:=TFPList.Create;
  FFilteredList.Count:=0;
  FFilteredList.Capacity:=FItems.Count;
  {$IFDEF CTDEBUG}
  DebugLn(['TIdentifierList.UpdateFilteredList Prefix="',Prefix,'"']);
  {$ENDIF}
  AnAVLNode:=FItems.FindLowest;
  while AnAVLNode<>nil do begin
    CurItem:=TIdentifierListItem(AnAVLNode.Data);
    if (CurItem.Identifier<>'')
    and ComparePrefixIdent(PChar(Pointer(Prefix)),PChar(Pointer(CurItem.Identifier)))
    then begin
      {$IFDEF ShowFilteredIdents}
      DebugLn(['::: FILTERED ITEM ',FFilteredList.Count,' ',CurItem.Identifier]);
      {$ENDIF}
      if length(Prefix)=length(CurItem.Identifier) then
        // put exact matches at the beginning
        FFilteredList.Insert(0,CurItem)
      else
        FFilteredList.Add(CurItem);
    end;
    AnAVLNode:=FItems.FindSuccessor(AnAVLNode);
  end;
  {$IFDEF CTDEBUG}
  DebugLn(['TIdentifierList.UpdateFilteredList ',dbgs(FFilteredList.Count),' of ',dbgs(FItems.Count)]);
  {$ENDIF}
  Exclude(FFlags,ilfFilteredListNeedsUpdate);
end;

procedure TIdentifierList.SetHistory(const AValue: TIdentifierHistoryList);
begin
  if FHistory=AValue then exit;
  FHistory:=AValue;
end;

procedure TIdentifierList.SetContextFlags(
  const AValue: TIdentifierListContextFlags);
begin
  if FContextFlags=AValue then exit;
  FContextFlags:=AValue;
end;

function TIdentifierList.GetFilteredItems(Index: integer): TIdentifierListItem;
begin
  UpdateFilteredList;
  if (Index<0) or (Index>=FFilteredList.Count) then
    Result:=nil
  else
    Result:=TIdentifierListItem(FFilteredList[Index]);
end;

constructor TIdentifierList.Create;
begin
  FFlags:=[ilfFilteredListNeedsUpdate];
  FItems:=TAVLTree.Create(@CompareIdentListItems);
  FIdentView:=TAVLTree.Create(@CompareIdentListItemsForIdents);
  FIdentSearchItem:=TIdentifierListSearchItem.Create;
  FCreatedIdentifiers:=TFPList.Create;
end;

destructor TIdentifierList.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  FreeAndNil(FIdentView);
  FreeAndNil(FFilteredList);
  FreeAndNil(FIdentSearchItem);
  FreeAndNil(FCreatedIdentifiers);
  inherited Destroy;
end;

procedure TIdentifierList.Clear;
var
  i: Integer;
  p: Pointer;
begin
  fContextFlags:=[];
  fContext:=CleanFindContext;
  FStartBracketLvl:=0;
  fStartContext:=CleanFindContext;
  fStartContextPos.Code:=nil;
  fStartContextPos.X:=1;
  fStartContextPos.Y:=1;
  for i:=0 to FCreatedIdentifiers.Count-1 do begin
    p:=FCreatedIdentifiers[i];
    FreeMem(p);
  end;
  FCreatedIdentifiers.Clear;
  FItems.FreeAndClear;
  FIdentView.Clear;
  Include(FFlags,ilfFilteredListNeedsUpdate);
end;

procedure TIdentifierList.Add(NewItem: TIdentifierListItem);
var
  AnAVLNode: TAVLTreeNode;
begin
  AnAVLNode:=FIdentView.FindKey(NewItem,@CompareIdentListItemsForIdents);
  if AnAVLNode=nil then begin
    if History<>nil then
      NewItem.HistoryIndex:=History.GetHistoryIndex(NewItem);
    FItems.Add(NewItem);
    FIdentView.Add(NewItem);
    Include(FFlags,ilfFilteredListNeedsUpdate);
  end else begin
    // redefined identifier -> ignore
    //DebugLn('TIdentifierList.Add redefined: ',NewItem.AsString);
    NewItem.Free;
  end;
end;

function TIdentifierList.Count: integer;
begin
  Result:=FItems.Count;
end;

function TIdentifierList.GetFilteredCount: integer;
begin
  UpdateFilteredList;
  Result:=FFilteredList.Count;
end;

function TIdentifierList.HasIdentifier(Identifier: PChar;
  const ParamList: string): boolean;
begin
  FIdentSearchItem.Identifier:=Identifier;
  FIdentSearchItem.ParamList:=ParamList;
  Result:=FIdentView.FindKey(FIdentSearchItem,
                             @CompareIdentListSearchWithItems)<>nil;
end;

function TIdentifierList.FindIdentifier(Identifier: PChar;
  const ParamList: string): TIdentifierListItem;
var
  AVLNode: TAVLTreeNode;
begin
  FIdentSearchItem.Identifier:=Identifier;
  FIdentSearchItem.ParamList:=ParamList;
  AVLNode:=FIdentView.FindKey(FIdentSearchItem,@CompareIdentListSearchWithItems);
  if AVLNode<>nil then
    Result:=TIdentifierListItem(AVLNode.Data)
  else
    Result:=nil;
end;

function TIdentifierList.FindCreatedIdentifier(const Ident: string): integer;
begin
  if Ident<>'' then begin
    Result:=FCreatedIdentifiers.Count-1;
    while (Result>=0)
    and (CompareIdentifiers(PChar(Pointer(Ident)),
                            PChar(Pointer(FCreatedIdentifiers[Result])))<>0)
    do
      dec(Result);
  end else begin
    Result:=-1;
  end;
end;

function TIdentifierList.CreateIdentifier(const Ident: string): PChar;
var
  i: Integer;
begin
  if Ident<>'' then begin
    i:=FindCreatedIdentifier(Ident);
    if i>=0 then
      Result:=PChar(Pointer(FCreatedIdentifiers[i]))
    else begin
      GetMem(Result,length(Ident)+1);
      Move(Ident[1],Result^,length(Ident)+1);
      FCreatedIdentifiers.Add(Result);
    end;
  end else
    Result:=nil;
end;

function TIdentifierList.StartUpAtomInFrontIs(const s: string): boolean;
begin
  Result:=StartContext.Tool.FreeUpAtomIs(StartAtomInFront,s);
end;

function TIdentifierList.StartUpAtomBehindIs(const s: string): boolean;
begin
  Result:=StartContext.Tool.FreeUpAtomIs(StartAtomBehind,s);
end;

function TIdentifierList.CompletePrefix(const OldPrefix: string): string;
// search all identifiers beginning with Prefix
// and return the biggest prefix of all of them
var
  AnAVLNode: TAVLTreeNode;
  CurItem: TIdentifierListItem;
  FoundFirst: Boolean;
  SamePos: Integer;
begin
  Result:=Prefix;
  FoundFirst:=false;
  AnAVLNode:=FItems.FindLowest;
  while AnAVLNode<>nil do begin
    CurItem:=TIdentifierListItem(AnAVLNode.Data);
    if (CurItem.Identifier<>'')
    and ComparePrefixIdent(PChar(Pointer(Prefix)),PChar(Pointer(CurItem.Identifier)))
    then begin
      if not FoundFirst then begin
        Result:=CurItem.Identifier;
        FoundFirst:=true;
      end else begin
        SamePos:=length(Prefix)+1;
        while (SamePos<=length(Result))
        and (UpChars[CurItem.Identifier[SamePos]]=UpChars[Result[SamePos]])
        do
          inc(SamePos);
        if SamePos<=length(Result) then begin
          Result:=copy(Result,1,SamePos-1);
          if length(Result)=length(Prefix) then exit;
        end;
      end;
    end;
    AnAVLNode:=FItems.FindSuccessor(AnAVLNode);
  end;
end;

procedure TIdentifierList.ToolTreeChange(Tool: TCustomCodeTool;
  NodesDeleting: boolean);
var
  AVLNode: TAVLTreeNode;
  Item: TIdentifierListItem;
  RootNode: TCodeTreeNode;
begin
  if (Tool.Tree=nil) then exit;
  RootNode:=Tool.Tree.Root;
  if RootNode=nil then exit;
  //DebugLn(['TIdentifierList.ToolTreeChange START ',Tool.MainFilename]);
  if FIdentView.Count=0 then exit;
  //DebugLn(['TIdentifierList.ToolTreeChange ',Tool.MainFilename]);
  AVLNode:=FIdentView.FindLowest;
  while AVLNode<>nil do begin
    Item:=TIdentifierListItem(AVLNode.Data);
    if (Item.FNode<>nil) and (Item.Tool=Tool) then begin
      //DebugLn(['TIdentifierList.ToolTreeChange ',Item.Identifier]);
      Item.UnbindNode;
    end;
    AVLNode:=FIdentView.FindSuccessor(AVLNode);
  end;
end;

function TIdentifierList.CalcMemSize: PtrUInt;
var
  i: Integer;
  Node: TAVLTreeNode;
  li: TIdentifierListItem;
  hli: TIdentHistListItem;
begin
  Result:=PtrUInt(InstanceSize)
    +MemSizeString(FPrefix);
  if FCreatedIdentifiers<>nil then begin
    inc(Result,MemSizeFPList(FCreatedIdentifiers));
    for i:=0 to FCreatedIdentifiers.Count-1 do
      inc(Result,GetIdentLen(PChar(FCreatedIdentifiers[i])));
  end;
  if FFilteredList<>nil then begin
    inc(Result,MemSizeFPList(FFilteredList));
    for i:=0 to FFilteredList.Count-1 do
      inc(Result,TIdentifierListItem(FFilteredList[i]).CalcMemSize);
  end;
  if FHistory<>nil then begin
    inc(Result,FHistory.CalcMemSize);
  end;
  if FItems<>nil then begin
    inc(Result,FItems.Count*SizeOf(TAVLTreeNode));
    Node:=FItems.FindLowest;
    while Node<>nil do begin
      li:=TIdentifierListItem(Node.Data);
      inc(Result,li.CalcMemSize);
      Node:=FItems.FindSuccessor(Node);
    end;
  end;
  if FIdentView<>nil then begin
    inc(Result,FIdentView.Count*SizeOf(TAVLTreeNode));
    Node:=FIdentView.FindLowest;
    while Node<>nil do begin
      hli:=TIdentHistListItem(Node.Data);
      inc(Result,hli.CalcMemSize);
      Node:=FIdentView.FindSuccessor(Node);
    end;
  end;
  if FIdentSearchItem<>nil then
    inc(Result,FIdentSearchItem.CalcMemSize);
end;

{ TIdentCompletionTool }

function TIdentCompletionTool.CollectAllIdentifiers(
  Params: TFindDeclarationParams; const FoundContext: TFindContext
  ): TIdentifierFoundResult;
var
  Ident: PChar;
  CurContextParent: TCodeTreeNode;

  function ProtectedNodeIsInAllowedClass: boolean;
  var
    CurClassNode: TCodeTreeNode;
    p: TFindContext;
  begin
    if ClassAndAncestors<>nil then begin
      // start of the identifier completion is in a method or class
      // => all protected ancestor classes are allowed as well.
      CurClassNode:=FoundContext.Node;
      while (CurClassNode<>nil)
      and (not (CurClassNode.Desc in AllClasses)) do
        CurClassNode:=CurClassNode.Parent;
      if CurClassNode=nil then exit;
      p:=CreateFindContext(Params.NewCodeTool,CurClassNode);
      if IndexOfFindContext(ClassAndAncestors,@p)>=0 then begin
        // this class node is the class or one of the ancestors of the class
        // of the start context of the identifier completion
        exit(true);
      end;
    end;
    //DebugLn(['ProtectedNodeIsInAllowedClass hidden: ',FindContextToString(FoundContext)]);

    Result:=false;
  end;
  
  function PropertyIsOverridenPublicPublish: boolean;
  begin
    // protected properties can be made public in child classes.
    //debugln('PropertyIsOverridenPublicPublish Identifier=',GetIdentifier(Ident),' Find=',dbgs((FoundPublicProperties<>nil) and (FoundPublicProperties.Find(Ident)<>nil)));
    if FoundPublicProperties<>nil then begin
      if FoundPublicProperties.Find(Ident)<>nil then begin
        // there is a public/published property with the same name
        exit(true);
      end;
    end;
    Result:=false;
  end;
  
  procedure SavePublicPublishedProperty;
  begin
    if FoundPublicProperties=nil then begin
      // create tree
      FoundPublicProperties:=
                         TAVLTree.Create(TListSortCompare(@CompareIdentifiers))
    end else if FoundPublicProperties.Find(Ident)<>nil then begin
      // identifier is already public
      exit;
    end;
    FoundPublicProperties.Add(Ident);
    //debugln('SavePublicPublishedProperty Identifier=',GetIdentifier(Ident),' Find=',dbgs(FoundPublicProperties.Find(Ident)<>nil));
  end;
  
var
  NewItem: TIdentifierListItem;
  Node: TCodeTreeNode;
  ProtectedForeignClass: Boolean;
begin
  // proceed searching ...
  Result:=ifrProceedSearch;

  {$IFDEF ShowFoundIdents}
  if FoundContext.Tool=Self then
  DebugLn('::: COLLECT IDENT ',FoundContext.Node.DescAsString,
    ' "',StringToPascalConst(copy(FoundContext.Tool.Src,FoundContext.Node.StartPos,50)),'"'
    ,' '+dbgs(fdfIgnoreUsedUnits in Params.Flags));
  {$ENDIF}

  CurContextParent:=FoundContext.Node.GetFindContextParent;
  if LastGatheredIdentParent<>CurContextParent then begin
    // new context level
    LastGatheredIdentParent:=CurContextParent;
    inc(LastGatheredIdentLevel);
  end;

  ProtectedForeignClass:=false;
  if FoundContext.Tool=Self then begin
    // identifier is in the same unit
    //DebugLn('::: COLLECT IDENT in SELF ',FoundContext.Node.DescAsString,
    //  ' "',StringToPascalConst(copy(FoundContext.Tool.Src,FoundContext.Node.StartPos,50)),'"'
    //  ,' fdfIgnoreUsedUnits='+dbgs(fdfIgnoreUsedUnits in Params.Flags));
  end else begin
    // identifier is in another unit
    if (FoundContext.Node.Parent<>nil) then begin
      case FoundContext.Node.Parent.Desc of
      ctnClassPrivate:
        begin
          // skip private definitions in other units
          if (FoundContext.Node.Desc=ctnProperty) then begin
            // private property: maybe the visibility was raised => continue
            //debugln('TIdentCompletionTool.CollectAllIdentifiers MAYBE Private made Public '+StringToPascalConst(copy(FoundContext.Tool.Src,FoundContext.Node.StartPos,50)));
          end;
          exit;
        end;
      ctnClassProtected:
        begin
          // protected definitions are only accessible from descendants
          // or if visibility was raised (e.g. property)
          if ProtectedNodeIsInAllowedClass then begin
            // protected node in an ancestor => allowed
            //debugln('TIdentCompletionTool.CollectAllIdentifiers ALLOWED Protected in ANCESTOR '+StringToPascalConst(copy(FoundContext.Tool.Src,FoundContext.Node.StartPos,50)));
          end else if (FoundContext.Node.Desc=ctnProperty) then begin
            // protected property: maybe the visibility was raised => continue
            ProtectedForeignClass:=true;
            //debugln('TIdentCompletionTool.CollectAllIdentifiers MAYBE Protected made Public '+StringToPascalConst(copy(FoundContext.Tool.Src,FoundContext.Node.StartPos,50)));
          end else begin
            // otherwise: treat as private
            //debugln('TIdentCompletionTool.CollectAllIdentifiers FORBIDDEN Protected '+StringToPascalConst(copy(FoundContext.Tool.Src,FoundContext.Node.StartPos,50)));
            exit;
          end;
        end;
      end;
    end;
  end;

  Ident:=nil;
  case FoundContext.Node.Desc of
  
  ctnTypeDefinition,ctnGenericType:
    begin
      Node:=FoundContext.Node.FirstChild;
      if FoundContext.Node.Desc=ctnTypeDefinition then
        Ident:=@FoundContext.Tool.Src[FoundContext.Node.StartPos]
      else begin
        // generic
        if Node=nil then exit;
        Ident:=@FoundContext.Tool.Src[Node.StartPos];
      end;
      if (Node<>nil)
      and (Node.Desc in AllClasses)
      and ((ctnsForwardDeclaration and Node.SubDesc)>0)
      then begin
        // forward definition of a class
        if CurrentIdentifierList.FindIdentifier(Ident,'')<>nil then begin
          // the real class is already in the list => skip forward
          exit;
        end;
      end;
    end;
  
  ctnVarDefinition,ctnConstDefinition,ctnEnumIdentifier:
    Ident:=@FoundContext.Tool.Src[FoundContext.Node.StartPos];
    
  ctnProcedure,ctnProcedureHead:
    Ident:=FoundContext.Tool.GetProcNameIdentifier(FoundContext.Node);
    
  ctnProperty:
    begin
      Ident:=FoundContext.Tool.GetPropertyNameIdentifier(FoundContext.Node);
      if FoundContext.Tool.PropNodeIsTypeLess(FoundContext.Node) then begin
        if FoundContext.Node.Parent.Desc in [ctnClassPublic,ctnClassPublished]
        then
          SavePublicPublishedProperty;
        // do not show properties without types (e.g. property Color;)
        // only show the real definition, which will follow in the ancestor
        exit;
      end;
      if (FoundContext.Node.Parent.Desc=ctnClassPrivate)
      and (FoundContext.Tool<>Self)
      and (not PropertyIsOverridenPublicPublish) then begin
        // a private property in another unit, that was not
        // made public/publish later
        // => skip
        exit;
      end;
      if (FoundContext.Node.Parent.Desc=ctnClassProtected)
      and ProtectedForeignClass
      and (not PropertyIsOverridenPublicPublish) then begin
        // a protected property in another unit, that was not
        // made public/publish later
        // => skip
        exit;
      end;
    end;
    
  ctnRecordCase:
    Ident:=@FoundContext.Tool.Src[Params.NewCleanPos];

  end;
  if Ident=nil then exit;

  NewItem:=TIdentifierListItem.Create(
                            icompUnknown,
                            false,
                            0,
                            Ident,
                            LastGatheredIdentLevel,
                            FoundContext.Node,
                            FoundContext.Tool,
                            ctnNone);
  
  {$IFDEF ShowFoundIdents}
  DebugLn('  IDENT COLLECTED: ',NewItem.AsString);
  {$ENDIF}
  
  CurrentIdentifierList.Add(NewItem);
end;

procedure TIdentCompletionTool.GatherPredefinedIdentifiers(CleanPos: integer;
  const Context: TFindContext; BeautifyCodeOptions: TBeautifyCodeOptions);
// Add predefined identifiers
const
  CompilerFuncHistoryIndex = 10;
  CompilerFuncLevel = 10;

  function StatementLevel: integer;
  var
    ANode: TCodeTreeNode;
  begin
    Result:=0;
    ANode:=Context.Node;
    while (ANode<>nil) and (not (ANode.Desc in [ctnBeginBlock,ctnAsmBlock])) do
    begin
      ANode:=ANode.Parent;
      inc(Result);
    end;
    if ANode=nil then Result:=0;
  end;
  
  procedure AddCompilerProcedure(const AProcName, AParameterList: PChar);
  var
    NewItem: TIdentifierListItem;
  begin
    //DebugLn(['AddCompilerProcedure ',AProcName,' ',ilcfStartOfStatement in CurrentIdentifierList.ContextFlags]);
    if not (ilcfStartOfStatement in CurrentIdentifierList.ContextFlags) then exit;
    if not (ilcfStartOfOperand in CurrentIdentifierList.ContextFlags) then exit;

    NewItem:=TIdentifierListItem.Create(
        icompUnknown,
        false,
        CompilerFuncHistoryIndex,
        AProcName,
        CompilerFuncLevel,
        nil,
        nil,
        ctnProcedure);
    NewItem.ParamTypeList:=AParameterList;
    NewItem.ParamNameList:=AParameterList;
    NewItem.Flags:=NewItem.Flags+[iliParamTypeListValid,iliParamNameListValid];
    CurrentIdentifierList.Add(NewItem);
  end;
  
  procedure AddCompilerFunction(const AProcName, AParameterList,
    AResultType: PChar);
  var
    NewItem: TIdentifierListItem;
  begin
    if not (ilcfStartOfOperand in CurrentIdentifierList.ContextFlags) then exit;

    NewItem:=TIdentifierListItem.Create(
        icompUnknown,
        false,
        CompilerFuncHistoryIndex,
        AProcName,
        CompilerFuncLevel,
        nil,
        nil,
        ctnProcedure);
    NewItem.ParamTypeList:=AParameterList;
    NewItem.ParamNameList:=AParameterList;
    NewItem.ResultType:=AResultType;
    NewItem.Flags:=NewItem.Flags+[iliParamTypeListValid,iliParamNameListValid,
                           iliIsFunction,iliIsFunctionValid,iliResultTypeValid];
    CurrentIdentifierList.Add(NewItem);
  end;

var
  NewItem: TIdentifierListItem;
  ProcNode: TCodeTreeNode;
begin
  if Context.Node.Desc in AllPascalStatements then begin
    // see fpc/compiler/psystem.pp
    AddCompilerProcedure('Assert','Condition:Boolean;const Message:String');
    AddCompilerFunction('Assigned','P:Pointer','Boolean');
    AddCompilerFunction('Addr','var X','Pointer');
    AddCompilerFunction('BitSizeOf','Identifier','Integer');
    AddCompilerProcedure('Break','');
    AddCompilerFunction('Concat','S1:String;S2:String[...;Sn:String]', 'String');
    AddCompilerProcedure('Continue','');
    AddCompilerFunction('Copy','const S:String;FromPosition,Count:Integer', 'String');
    AddCompilerProcedure('Dec','var X:Ordinal;N:Integer=1');
    AddCompilerProcedure('Dispose','var X:Pointer');
    AddCompilerProcedure('Exclude','var S:Set;X:Ordinal');
    AddCompilerProcedure('Exit','');
    AddCompilerProcedure('Finalize','var X');
    AddCompilerFunction('get_frame','','Pointer');
    AddCompilerFunction('High','Arg:TypeOrVariable','Ordinal');
    AddCompilerProcedure('Inc','var X:Ordinal;N:Integer=1');
    AddCompilerProcedure('Include','var S:Set;X:Ordinal');
    AddCompilerProcedure('Initialize','var X');
    AddCompilerFunction('Length','S:String','Ordinal');
    AddCompilerFunction('Length','A:Array','Ordinal');
    AddCompilerFunction('Low','Arg:TypeOrVariable','Ordinal');
    AddCompilerProcedure('New','var X:Pointer');
    AddCompilerFunction('ObjCSelector','String','SEL');
    AddCompilerFunction('Ofs','var X','LongInt');
    AddCompilerFunction('Ord','X:Ordinal', 'Integer');
    AddCompilerProcedure('Pack','A:Array;N:Integer;var A:Array');
    AddCompilerFunction('Pred','X:Ordinal', 'Ordinal');
    AddCompilerProcedure('Read','');
    AddCompilerProcedure('ReadLn','');
    AddCompilerProcedure('ReadStr','S:String;var Args:Arguments');
    AddCompilerFunction('Seg','var X','LongInt');
    AddCompilerProcedure('SetLength','var S:String;NewLength:Integer');
    AddCompilerProcedure('SetLength','var A:Array;NewLength:Integer');
    AddCompilerFunction('SizeOf','Identifier','Integer');
    AddCompilerFunction('Slice','var A:Array;Count:Integer','Array');
    AddCompilerProcedure('Str','const X[:Width[:Decimals]];var S:String');
    AddCompilerFunction('Succ','X:Ordinal', 'Ordinal');
    AddCompilerFunction('TypeInfo','Identifier', 'Pointer');
    AddCompilerFunction('TypeOf','Identifier', 'Pointer');
    AddCompilerProcedure('Val','S:String;var V;var Code:Integer');
    AddCompilerFunction('Unaligned','var X','var'); // Florian declaration :)
    AddCompilerProcedure('Unpack','A:Array;var A:Array;N:Integer');
    AddCompilerProcedure('Write','Args:Arguments');
    AddCompilerProcedure('WriteLn','Args:Arguments');
    AddCompilerProcedure('WriteStr','var S:String;Args:Arguments');

    if (ilcfStartOfOperand in CurrentIdentifierList.ContextFlags)
    and Context.Tool.NodeIsInAMethod(Context.Node)
    and (not CurrentIdentifierList.HasIdentifier('Self','')) then begin
      // method body -> add 'Self'
      NewItem:=TIdentifierListItem.Create(
          icompUnknown,
          true,
          1,
          'Self',
          StatementLevel,
          nil,
          nil,
          ctnVarDefinition);
      CurrentIdentifierList.Add(NewItem);
    end;
    ProcNode:=Context.Node.GetNodeOfType(ctnProcedure);
    if (ilcfStartOfOperand in CurrentIdentifierList.ContextFlags)
    and Context.Tool.NodeIsFunction(ProcNode)
    and (not CurrentIdentifierList.HasIdentifier('Result','')) then begin
      // function body -> add 'Result'
      NewItem:=TIdentifierListItem.Create(
          icompUnknown,
          true,
          1,
          'Result',
          StatementLevel,
          nil,
          nil,
          ctnVarDefinition);
      CurrentIdentifierList.Add(NewItem);
    end;
  end;
end;

procedure TIdentCompletionTool.GatherUsefulIdentifiers(CleanPos: integer;
  const Context: TFindContext; BeautifyCodeOptions: TBeautifyCodeOptions);
var
  NewItem: TIdentifierListItem;
  PropertyName: String;
begin
  while (CleanPos>1) and (IsIdentChar[Src[CleanPos-1]]) do dec(CleanPos);
  GatherPredefinedIdentifiers(CleanPos,Context,BeautifyCodeOptions);
  if Context.Node.Desc=ctnProperty then begin
    PropertyName:=ExtractPropName(Context.Node,false);
    //debugln('TIdentCompletionTool.GatherUsefulIdentifiers Property ',PropertyName);
    MoveCursorToCleanPos(CleanPos);
    ReadPriorAtom;
    if UpAtomIs('READ') then begin
      // add the default class completion 'read' specifier function
      NewItem:=TIdentifierListItem.Create(
          icompUnknown,true,0,
          CurrentIdentifierList.CreateIdentifier(
            BeautifyCodeOptions.PropertyReadIdentPrefix+PropertyName),
          0,nil,nil,ctnProcedure);
      CurrentIdentifierList.Add(NewItem);
    end;
    if UpAtomIs('WRITE') then begin
      // add the default class completion 'write' specifier function
      NewItem:=TIdentifierListItem.Create(
          icompUnknown,true,0,
          CurrentIdentifierList.CreateIdentifier(
            BeautifyCodeOptions.PropertyWriteIdentPrefix+PropertyName),
          0,nil,nil,ctnProcedure);
      CurrentIdentifierList.Add(NewItem);
    end;
    if (UpAtomIs('READ') or UpAtomIs('WRITE'))
    and (Context.Node.GetNodeOfTypes([ctnClass,ctnObject,ctnObjCClass])<>nil)
    then begin
      // add the default class completion 'read'/'write' specifier variable
      NewItem:=TIdentifierListItem.Create(
          icompUnknown,true,0,
          CurrentIdentifierList.CreateIdentifier(
            BeautifyCodeOptions.PrivateVariablePrefix+PropertyName),
          0,nil,nil,ctnVarDefinition);
      CurrentIdentifierList.Add(NewItem);
    end;
    if UpAtomIs('STORED') then begin
      // add the default class completion 'stored' specifier function
      NewItem:=TIdentifierListItem.Create(
          icompUnknown,true,0,
          CurrentIdentifierList.CreateIdentifier(
            PropertyName+BeautifyCodeOptions.PropertyStoredIdentPostfix),
          0,nil,nil,ctnProcedure);
      CurrentIdentifierList.Add(NewItem);
    end;
  end;
end;

procedure TIdentCompletionTool.GatherUnitnames(CleanPos: integer;
  const Context: TFindContext; BeautifyCodeOptions: TBeautifyCodeOptions);
var
  TreeOfUnitFiles: TAVLTree;

  procedure GatherUnitsFromUnitLinks;
  var
    UnitLinks: string;
    UnitLinkStart: Integer;
    UnitLinkEnd: LongInt;
    UnitLinkLen: Integer;
    Filename: String;
  begin
    UnitLinks:=Scanner.Values[ExternalMacroStart+'UnitLinks'];
    UnitLinkStart:=1;
    while UnitLinkStart<=length(UnitLinks) do begin
      while (UnitLinkStart<=length(UnitLinks))
      and (UnitLinks[UnitLinkStart] in [#10,#13]) do
        inc(UnitLinkStart);
      UnitLinkEnd:=UnitLinkStart;
      while (UnitLinkEnd<=length(UnitLinks)) and (UnitLinks[UnitLinkEnd]<>' ')
      do
        inc(UnitLinkEnd);
      UnitLinkLen:=UnitLinkEnd-UnitLinkStart;
      if UnitLinkLen>0 then begin
        Filename:=copy(UnitLinks,UnitLinkStart,UnitLinkEnd-UnitLinkStart);
        AddToTreeOfUnitFiles(TreeOfUnitFiles,Filename,false);
      end;
      UnitLinkStart:=UnitLinkEnd+1;
      while (UnitLinkStart<=length(UnitLinks))
      and (not (UnitLinks[UnitLinkStart] in [#10,#13])) do
        inc(UnitLinkStart);
    end;
  end;
  
var
  UnitPath, SrcPath: string;
  BaseDir: String;
  ANode: TAVLTreeNode;
  UnitFileInfo: TUnitFileInfo;
  NewItem: TIdentifierListItem;
  UnitExt: String;
  SrcExt: String;
  CurSourceName: String;
begin
  UnitPath:='';
  SrcPath:='';
  GatherUnitAndSrcPath(UnitPath,SrcPath);
  //DebugLn('TIdentCompletionTool.GatherUnitnames UnitPath="',UnitPath,'" SrcPath="',SrcPath,'"');
  BaseDir:=ExtractFilePath(MainFilename);
  TreeOfUnitFiles:=nil;
  try
    // search in unitpath
    UnitExt:='pp;pas;ppu';
    GatherUnitFiles(BaseDir,UnitPath,UnitExt,false,true,TreeOfUnitFiles);
    // search in srcpath
    SrcExt:='pp;pas';
    GatherUnitFiles(BaseDir,SrcPath,SrcExt,false,true,TreeOfUnitFiles);
    // add unitlinks
    GatherUnitsFromUnitLinks;
    // create list
    CurSourceName:=GetSourceName;
    ANode:=TreeOfUnitFiles.FindLowest;
    while ANode<>nil do begin
      UnitFileInfo:=TUnitFileInfo(ANode.Data);
      if CompareIdentifiers(PChar(Pointer(UnitFileInfo.UnitName)),
                            PChar(Pointer(CurSourceName)))<>0
      then begin
        NewItem:=TIdentifierListItem.Create(
            icompCompatible,true,0,
            CurrentIdentifierList.CreateIdentifier(UnitFileInfo.UnitName),
            0,nil,nil,ctnUnit);
        CurrentIdentifierList.Add(NewItem);
      end;
      ANode:=TreeOfUnitFiles.FindSuccessor(ANode);
    end;
  finally
    FreeTreeOfUnitFiles(TreeOfUnitFiles);
  end;
end;

procedure TIdentCompletionTool.GatherSourceNames(const Context: TFindContext);

  procedure Add(const SrcName: string);
  var
    NewItem: TIdentifierListItem;
  begin
    NewItem:=TIdentifierListItem.Create(
        icompExact,true,0,
        CurrentIdentifierList.CreateIdentifier(SrcName),
        0,nil,nil,Context.Node.Desc);
    CurrentIdentifierList.Add(NewItem);
  end;

var
  NewSourceName: String;
  FileSourceName: String;
begin
  // add the unitname as in the filename and as in the source
  FileSourceName:=ExtractFilenameOnly(MainFilename);
  NewSourceName:=GetSourceName(false);
  //DebugLn('TIdentCompletionTool.GatherSourceNames FileSourceName=',FileSourceName,' NewSourceName=',NewSourceName);
  if (FileSourceName<>lowercase(FileSourceName)) then begin
    // the file is not written lowercase => case is important, ignore source name
    Add(FileSourceName);
  end else if (SysUtils.CompareText(NewSourceName,FileSourceName)<>0) then begin
    // source name is not correct => only use file name
    Add(FileSourceName);
  end else if NewSourceName=FileSourceName then begin
    // both are the same => add only one
    Add(FileSourceName);
  end else begin
    // both are valid, just different in case
    // the filename is written lowercase
    // => prefer the source name
    Add(NewSourceName);
  end;
end;

procedure TIdentCompletionTool.GatherContextKeywords(const Context: TFindContext;
   CleanPos: integer);

  procedure Add(const Keyword: string);
  var
    NewItem: TIdentifierListItem;
  begin
    NewItem:=TIdentifierListItem.Create(
        icompExact,false,0,
        CurrentIdentifierList.CreateIdentifier(Keyword),
        0,nil,nil,ctnNone);
    include(NewItem.Flags,iliKeyword);
    CurrentIdentifierList.Add(NewItem);
  end;

var
  Node: TCodeTreeNode;
begin
  Node:=Context.Node;
  case Node.Desc of
  ctnClass,ctnObject,ctnObjCClass,
  ctnClassPrivate,ctnClassProtected,ctnClassPublic,ctnClassPublished:
    begin
      Add('public');
      Add('private');
      Add('protected');
      Add('published');
      Add('procedure');
      Add('function');
      Add('property');
      Add('constructor');
      Add('destructor');
    end;

  ctnClassInterface,ctnObjCProtocol:
    begin
      Add('procedure');
      Add('function');
    end;

  ctnInterface,ctnImplementation:
    begin
      if (Node.FirstChild=nil)
      or ((Node.FirstChild.Desc<>ctnUsesSection)
        and (Node.FirstChild.StartPos>=CleanPos))
      then
        Add('uses');
      Add('type');
      Add('var');
      Add('const');
      Add('procedure');
      Add('function');
      Add('resourcestring');
      if Node.Desc=ctnInterface then
        Add('property');
    end;

  ctnProcedure:
    begin
      Add('begin');
      Add('type');
      Add('var');
      Add('const');
      Add('procedure');
      Add('function');
    end;
  end;
end;

procedure TIdentCompletionTool.InitCollectIdentifiers(
  const CursorPos: TCodeXYPosition; var IdentifierList: TIdentifierList);
var
  StartContext: TFindContext;
begin
  if IdentifierList=nil then IdentifierList:=TIdentifierList.Create;
  CurrentIdentifierList:=IdentifierList;
  CurrentIdentifierList.Clear;
  LastGatheredIdentParent:=nil;
  LastGatheredIdentLevel:=0;
  CurrentIdentifierList.StartContextPos:=CursorPos;
  StartContext := CurrentIdentifierList.StartContext;
  StartContext.Tool := Self;
  CurrentIdentifierList.StartContext:=StartContext;
end;

procedure TIdentCompletionTool.ParseSourceTillCollectionStart(
  const CursorPos: TCodeXYPosition; out CleanCursorPos: integer;
  out CursorNode: TCodeTreeNode; out IdentStartPos, IdentEndPos: integer);
var
  StartContext: TFindContext;
begin
  CleanCursorPos:=0;
  CursorNode:=nil;
  IdentStartPos:=0;
  IdentEndPos:=0;

  // build code tree
  {$IFDEF CTDEBUG}
  DebugLn('TIdentCompletionTool.ParseSourceTillCollectionStart A CursorPos=',dbgs(CursorPos.X),',',dbgs(CursorPos.Y),' ',DbgsCXY(IdentStartXYPos));
  {$ENDIF}
  BuildTreeAndGetCleanPos(trTillCursor,CursorPos,CleanCursorPos,
                [{$IFNDEF DisableIgnoreErrorAfter}btSetIgnoreErrorPos{$ENDIF}]);

  // find node at position
  CursorNode:=BuildSubTreeAndFindDeepestNodeAtPos(CleanCursorPos,true);
  if CurrentIdentifierList<>nil then begin
    StartContext:=CurrentIdentifierList.StartContext;
    StartContext.Node:=CursorNode;
    CurrentIdentifierList.StartContext:=StartContext;
  end;
  
  // get identifier position
  GetIdentStartEndAtPosition(Src,CleanCursorPos,IdentStartPos,IdentEndPos);
end;

function TIdentCompletionTool.FindIdentifierStartPos(
  const CursorPos: TCodeXYPosition): TCodeXYPosition;
var
  p: integer;
  IdentStartPos, IdentEndPos: integer;
begin
  CursorPos.Code.LineColToPosition(CursorPos.Y,CursorPos.X,p);
  if p<1 then
    RaiseException(ctsCursorPosOutsideOfCode);
  GetIdentStartEndAtPosition(CursorPos.Code.Source,p,IdentStartPos,IdentEndPos);
  Result:=CursorPos;
  if IdentStartPos>0 then
    dec(Result.X,p-IdentStartPos);
end;

procedure TIdentCompletionTool.FindCollectionContext(
  Params: TFindDeclarationParams; IdentStartPos: integer;
  CursorNode: TCodeTreeNode;
  out GatherContext: TFindContext;
  out ContextExprStartPos: LongInt;
  out StartInSubContext: Boolean);

  function GetContextExprStartPos(IdentStartPos: integer;
    ContextNode: TCodeTreeNode): integer;
  begin
    MoveCursorToCleanPos(IdentStartPos);
    ReadPriorAtom;
    if (CurPos.Flag=cafPoint)
    or (UpAtomIs('INHERITED')) then begin
      Result:=FindStartOfTerm(IdentStartPos,NodeTermInType(ContextNode));
      if Result<ContextNode.StartPos then
        Result:=ContextNode.StartPos;
    end else
      Result:=IdentStartPos;
    MoveCursorToCleanPos(Result);
    ReadNextAtom;
    case ContextNode.Desc of
    ctnProperty:
      // check for special property keywords
      if WordIsPropertySpecifier.DoItCaseInsensitive(Src,
          CurPos.StartPos,CurPos.EndPos-CurPos.StartPos)
      then
        // do not resolve property specifiers
        Result:=IdentStartPos;
    end;
  end;

var
  ExprType: TExpressionType;
  IgnoreCurContext: Boolean;
begin
  GatherContext:=CreateFindContext(Self,CursorNode);

  IgnoreCurContext:=false;
  ContextExprStartPos:=GetContextExprStartPos(IdentStartPos,CursorNode);
  if GatherContext.Node.Desc=ctnWithVariable then begin
    if GatherContext.Node.PriorBrother<>nil then
      GatherContext.Node:=GatherContext.Node.PriorBrother
    else
      GatherContext.Node:=GatherContext.Node.Parent;
  end
  else if (GatherContext.Node.Desc=ctnClassInheritance)
  or ((GatherContext.Node.Parent<>nil)
     and (GatherContext.Node.Parent.Desc=ctnClassInheritance))
  then begin
    while not (GatherContext.Node.Desc in AllClasses) do
      GatherContext.Node:=GatherContext.Node.Parent;
    GatherContext.Node:=GatherContext.Node.Parent;
    IgnoreCurContext:=true;
  end;

  StartInSubContext:=false;
  //DebugLn(['TIdentCompletionTool.FindCollectionContext ContextExprStartPos=',ContextExprStartPos,' "',dbgstr(copy(Src,ContextExprStartPos,20)),'" IdentStartPos="',dbgstr(copy(Src,IdentStartPos,20)),'"']);
  if ContextExprStartPos<IdentStartPos then begin
    MoveCursorToCleanPos(IdentStartPos);
    Params.ContextNode:=CursorNode;
    Params.SetIdentifier(Self,nil,nil);
    Params.Flags:=[fdfExceptionOnNotFound,
                   fdfSearchInParentNodes,fdfSearchInAncestors];
    if IgnoreCurContext then
      Params.Flags:=Params.Flags+[fdfIgnoreCurContextNode];
    ExprType:=FindExpressionTypeOfTerm(ContextExprStartPos,IdentStartPos,
                                       Params,false);
    //DebugLn(['TIdentCompletionTool.FindCollectionContext ',ExprTypeToString(ExprType)]);
    if (ExprType.Desc=xtContext) then begin
      GatherContext:=ExprType.Context;
      StartInSubContext:=true;
    end;
  end;
end;

function TIdentCompletionTool.CollectAllContexts(
  Params: TFindDeclarationParams; const FoundContext: TFindContext
  ): TIdentifierFoundResult;
begin
  Result:=ifrProceedSearch;
  if FoundContext.Node=nil then exit;
  //DebugLn(['TIdentCompletionTool.CollectAllContexts ',FoundContext.Node.DescAsString]);
  case FoundContext.Node.Desc of
  ctnProcedure:
    begin
      //DebugLn('TIdentCompletionTool.CollectAllContexts CurrentContexts.ProcNameAtom.StartPos=',dbgs(CurrentContexts.ProcNameAtom.StartPos));
      if (CurrentContexts.ProcName='') then exit;
      FoundContext.Tool.MoveCursorToProcName(FoundContext.Node,true);
      //DebugLn(['TIdentCompletionTool.CollectAllContexts ProcName=',GetIdentifier(@FoundContext.Tool.Src[FoundContext.Tool.CurPos.StartPos])]);
      if not FoundContext.Tool.CompareSrcIdentifiers(
        FoundContext.Tool.CurPos.StartPos,
        PChar(CurrentContexts.ProcName))
      then exit;
    end;
  ctnProperty:
    begin
      if (CurrentContexts.ProcName='') then exit;
      FoundContext.Tool.MoveCursorToPropName(FoundContext.Node);
      if not FoundContext.Tool.CompareSrcIdentifiers(
        FoundContext.Tool.CurPos.StartPos,
        PChar(CurrentContexts.ProcName))
      then exit;
    end;
  ctnVarDefinition:
    begin
      if (CurrentContexts.ProcName='') then exit;
      if not FoundContext.Tool.CompareSrcIdentifiers(
        FoundContext.Node.StartPos,
        PChar(CurrentContexts.ProcName))
      then exit;
    end;
  else
    exit;
  end;
  AddCollectionContext(FoundContext.Tool,FoundContext.Node);
end;

procedure TIdentCompletionTool.AddCollectionContext(Tool: TFindDeclarationTool;
  Node: TCodeTreeNode);
begin
  if CurrentContexts=nil then
    CurrentContexts:=TCodeContextInfo.Create;
  CurrentContexts.Add(CreateExpressionType(xtContext,xtNone,
                                           CreateFindContext(Tool,Node)));
  //DebugLn('TIdentCompletionTool.AddCollectionContext ',Node.DescAsString,' ',ExtractNode(Node,[]));
end;

procedure TIdentCompletionTool.InitFoundMethods;
begin
  if FoundMethods<>nil then ClearFoundMethods;
  FoundMethods:=TAVLTree.Create(@CompareCodeTreeNodeExt);
end;

procedure TIdentCompletionTool.ClearFoundMethods;
begin
  if FoundMethods=nil then exit;
  NodeExtMemManager.DisposeAVLTree(FoundMethods);
  FoundMethods:=nil;
end;

function TIdentCompletionTool.CollectMethods(
  Params: TFindDeclarationParams; const FoundContext: TFindContext
  ): TIdentifierFoundResult;
var
  ProcText: String;
  AVLNode: TAVLTreeNode;
  NodeExt: TCodeTreeNodeExtension;
begin
  // proceed searching ...
  Result:=ifrProceedSearch;

  {$IFDEF ShowFoundIdents}
  //if FoundContext.Tool=Self then
  DebugLn('::: COLLECT IDENT ',FoundContext.Node.DescAsString,
    ' "',StringToPascalConst(copy(FoundContext.Tool.Src,FoundContext.Node.StartPos,50)),'"');
  {$ENDIF}
  
  if FoundContext.Node.Desc=ctnProcedure then begin
    ProcText:=FoundContext.Tool.ExtractProcHead(FoundContext.Node,
                              [phpWithoutClassKeyword,phpWithHasDefaultValues]);
    AVLNode:=FindCodeTreeNodeExtAVLNode(FoundMethods,ProcText);
    if AVLNode<>nil then begin
      // method is overriden => ignore
    end else begin
      // new method
      NodeExt:=NodeExtMemManager.NewNode;
      NodeExt.Node:=FoundContext.Node;
      NodeExt.Data:=FoundContext.Tool;
      NodeExt.Txt:=ProcText;
      FoundMethods.Add(NodeExt);
    end;
  end;
end;

function TIdentCompletionTool.GatherIdentifiers(
  const CursorPos: TCodeXYPosition; var IdentifierList: TIdentifierList;
  BeautifyCodeOptions: TBeautifyCodeOptions): boolean;
var
  CleanCursorPos, IdentStartPos, IdentEndPos: integer;
  CursorNode: TCodeTreeNode;
  Params: TFindDeclarationParams;
  GatherContext: TFindContext;
  ContextExprStartPos: Integer;
  StartInSubContext: Boolean;
  StartPosOfVariable: LongInt;
  CursorContext: TFindContext;
  IdentStartXY: TCodeXYPosition;
  
  procedure CheckProcedureDeclarationContext;
  var
    Node: TCodeTreeNode;
    Can: Boolean;
  begin
    //DebugLn(['CheckProcedureDeclarationContext ',CursorNode.DescAsString]);
    Node:=CursorNode;
    Can:=false;
    if (Node.Parent<>nil)
    and (Node.Parent.Desc in (AllClassBaseSections+AllClassVarSections))
    and (Node.Desc=ctnVarDefinition)
    and (CurrentIdentifierList.StartAtomBehind.Flag<>cafColon) then begin
      { cursor is at a class variable definition without type
        for example:
        
        public
          MouseM|
        end;
      }
      Can:=true;
    end
    else if (((Node.Desc=ctnProcedure) and (not NodeIsMethodBody(Node)))
    or ((Node.Desc=ctnProcedureHead) and (not NodeIsMethodBody(Node.Parent))))
    and (not (CurrentIdentifierList.StartAtomBehind.Flag
              in [cafEdgedBracketOpen,cafRoundBracketOpen]))
    then begin
      // for example: procedure DoSomething|
      Can:=true;
    end
    else if Node.Desc in (AllClassBaseSections+AllSourceTypes
                     +[ctnInterface,ctnImplementation])
    then begin
      //DebugLn(['TIdentCompletionTool.CheckProcedureDeclarationContext ilcfCanProcDeclaration']);
      Can:=true;
    end;
    if Can then
      CurrentIdentifierList.ContextFlags:=
        CurrentIdentifierList.ContextFlags+[ilcfCanProcDeclaration];
  end;
  
begin
  Result:=false;

  ActivateGlobalWriteLock;
  Params:=TFindDeclarationParams.Create;
  try
    InitCollectIdentifiers(CursorPos,IdentifierList);
    IdentStartXY:=FindIdentifierStartPos(CursorPos);
    ParseSourceTillCollectionStart(IdentStartXY,CleanCursorPos,CursorNode,
                                   IdentStartPos,IdentEndPos);
    if CleanCursorPos=0 then ;

    // find context
    {$IFDEF CTDEBUG}
    DebugLn('TIdentCompletionTool.GatherIdentifiers B',
      ' CleanCursorPos=',dbgs(CleanCursorPos),
      ' IdentStartPos=',dbgs(IdentStartPos),' IdentEndPos=',dbgs(IdentEndPos),
      ' Ident=',copy(Src,IdentStartPos,IdentEndPos-IdentStartPos));
    {$ENDIF}
    GatherContext:=CreateFindContext(Self,CursorNode);
    if CursorNode.Desc in [ctnUsesSection,ctnUseUnit] then begin
      GatherUnitNames(IdentStartPos,GatherContext,BeautifyCodeOptions);
      MoveCursorToCleanPos(IdentEndPos);
      ReadNextAtom;
      if (CurPos.Flag=cafWord) and (not UpAtomIs('IN')) then begin
        // add comma
        CurrentIdentifierList.ContextFlags:=
          CurrentIdentifierList.ContextFlags+[ilcfNeedsEndComma];
      end;
    end else if CursorNode.Desc in AllSourceTypes then begin
      GatherSourceNames(GatherContext);
    end else begin
      // find class and ancestors if existing (needed for protected identifiers)
      FindContextClassAndAncestors(IdentStartXY,ClassAndAncestors);

      FindCollectionContext(Params,IdentStartPos,CursorNode,
                           GatherContext,ContextExprStartPos,StartInSubContext);
      if ContextExprStartPos=0 then ;

      CursorContext:=CreateFindContext(Self,CursorNode);
      GatherContextKeywords(CursorContext,IdentStartPos);

      // search and gather identifiers in context
      if (GatherContext.Tool<>nil) and (GatherContext.Node<>nil) then begin
        {$IFDEF CTDEBUG}
        DebugLn('TIdentCompletionTool.GatherIdentifiers D CONTEXT: ',
          GatherContext.Tool.MainFilename,
          ' ',GatherContext.Node.DescAsString,
          ' "',StringToPascalConst(copy(GatherContext.Tool.Src,GatherContext.Node.StartPos,50)),'"');
        {$ENDIF}

        // gather all identifiers in context
        Params.ContextNode:=GatherContext.Node;
        Params.SetIdentifier(Self,nil,@CollectAllIdentifiers);
        Params.Flags:=[fdfSearchInAncestors,fdfCollect,fdfFindVariable];
        if not StartInSubContext then
          Include(Params.Flags,fdfSearchInParentNodes);
        if Params.ContextNode.Desc in AllClasses then
          Exclude(Params.Flags,fdfSearchInParentNodes);
        {$IFDEF CTDEBUG}
        DebugLn('TIdentCompletionTool.GatherIdentifiers F');
        {$ENDIF}
        CurrentIdentifierList.Context:=GatherContext;
        GatherContext.Tool.FindIdentifierInContext(Params);
      end;

      // check for incomplete context
      
      // context bracket level
      CurrentIdentifierList.StartBracketLvl:=
        GetBracketLvl(Src,CursorNode.StartPos,IdentStartPos,
                      Scanner.NestedComments);
      if CursorNode.Desc in AllPascalStatements then begin
        CurrentIdentifierList.ContextFlags:=
          CurrentIdentifierList.ContextFlags+[ilcfStartInStatement];
      end;

      // context in front of
      StartPosOfVariable:=FindStartOfTerm(IdentStartPos,NodeTermInType(CursorNode));
      if StartPosOfVariable>0 then begin
        if StartPosOfVariable=IdentStartPos then begin
          // cursor is at start of an operand
          CurrentIdentifierList.ContextFlags:=
            CurrentIdentifierList.ContextFlags+[ilcfStartOfOperand];
        end else begin
          MoveCursorToCleanPos(IdentStartPos);
          ReadPriorAtom;
          if CurPos.Flag=cafPoint then
            // cursor is behind a point
            CurrentIdentifierList.ContextFlags:=
              CurrentIdentifierList.ContextFlags+[ilcfStartIsSubIdent];
        end;
        MoveCursorToCleanPos(StartPosOfVariable);
        ReadPriorAtom;
        CurrentIdentifierList.StartAtomInFront:=CurPos;
        if (ilcfStartInStatement in CurrentIdentifierList.ContextFlags) then
        begin
          // check if LValue
          if (CurPos.Flag in [cafSemicolon,cafBegin,cafEnd])
          or UpAtomIs('TRY') or UpAtomIs('FINALLY') or UpAtomIs('EXCEPT')
          or UpAtomIs('FOR') or UpAtomIs('DO')
          or UpAtomIs('REPEAT') or UpAtomIs('ASM') or UpAtomIs('ELSE')
          then begin
            CurrentIdentifierList.ContextFlags:=
              CurrentIdentifierList.ContextFlags+[ilcfStartOfStatement];
          end;
          // check if expression
          if UpAtomIs('IF') or UpAtomIs('CASE') or UpAtomIs('WHILE')
          or UpAtomIs('UNTIL')
          then begin
            // todo: check at start of expression, not only in front of variable
            CurrentIdentifierList.ContextFlags:=
              CurrentIdentifierList.ContextFlags+[ilcfIsExpression];
          end;
        end;
      end;
      // context behind
      if IdentEndPos<SrcLen then begin
        MoveCursorToCleanPos(IdentEndPos);
        ReadNextAtom;

        // check end of line
        if not PositionsInSameLine(Src,IdentEndPos,CurPos.StartPos) then
          CurrentIdentifierList.ContextFlags:=
            CurrentIdentifierList.ContextFlags+[ilcfEndOfLine];

        CurrentIdentifierList.StartAtomBehind:=CurPos;
        // check if a semicolon is needed or forbidden at the end
        if (CurrentIdentifierList.StartBracketLvl>0)
        or (CurPos.Flag in [cafSemicolon, cafEqual, cafColon, cafComma,
                   cafPoint, cafRoundBracketOpen, cafRoundBracketClose,
                   cafEdgedBracketOpen, cafEdgedBracketClose])
        or ((CurPos.Flag in [cafWord,cafNone])
            and (UpAtomIs('ELSE')
                 or UpAtomIs('THEN')
                 or UpAtomIs('DO')
                 or UpAtomIs('TO')
                 or UpAtomIs('OF')
                 or WordIsBinaryOperator.DoItCaseInsensitive(Src,
                          CurPos.StartPos,CurPos.EndPos-CurPos.StartPos)))
        then begin
          // do not add semicolon
          CurrentIdentifierList.ContextFlags:=
            CurrentIdentifierList.ContextFlags+[ilcfNoEndSemicolon];
        end;
        // check if in statement
        if (ilcfStartInStatement in CurrentIdentifierList.ContextFlags) then
        begin
          // check if a semicolon is needed at the end
          if (not (ilcfNoEndSemicolon in CurrentIdentifierList.ContextFlags))
          and (not (ilcfStartOfStatement in CurrentIdentifierList.ContextFlags))
          then begin
            // check if a semicolon is needed at the end
            if (CurPos.Flag in [cafEnd,cafBegin])
            or WordIsBlockKeyWord.DoItCaseInsensitive(Src,
                                  CurPos.StartPos,CurPos.EndPos-CurPos.StartPos)
            or ((CurPos.Flag=cafWord)
                and (not PositionsInSameLine(Src,IdentEndPos,CurPos.StartPos)))
            then begin
              // add semicolon
              CurrentIdentifierList.ContextFlags:=
                CurrentIdentifierList.ContextFlags+[ilcfNeedsEndSemicolon];
            end;
          end;
        end;
      end else begin
        // end of source
        CurrentIdentifierList.ContextFlags:=
          CurrentIdentifierList.ContextFlags+[ilcfEndOfLine];
      end;

      // check for procedure/method declaration context
      CheckProcedureDeclarationContext;

      // add useful identifiers
      {$IFDEF CTDEBUG}
      DebugLn('TIdentCompletionTool.GatherIdentifiers G');
      {$ENDIF}
      GatherUsefulIdentifiers(IdentStartPos,CursorContext,BeautifyCodeOptions);
    end;

    Result:=true;
  finally
    FreeListOfPFindContext(ClassAndAncestors);
    FreeAndNil(FoundPublicProperties);
    Params.Free;
    ClearIgnoreErrorAfter;
    DeactivateGlobalWriteLock;
    CurrentIdentifierList:=nil;
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TIdentCompletionTool.GatherIdentifiers END');
  {$ENDIF}
end;

function TIdentCompletionTool.FindCodeContext(const CursorPos: TCodeXYPosition;
  out CodeContexts: TCodeContextInfo): boolean;
var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
  Params: TFindDeclarationParams;

  procedure AddPredefinedProcs(CurrentContexts: TCodeContextInfo;
    ProcNameAtom: TAtomPosition);

    procedure AddCompilerProc(const AProcName: string;
      const Params: string; const ResultType: string = '');
    var
      i: LongInt;
      Item: TCodeContextInfoItem;
    begin
      if CompareIdentifiers(PChar(AProcName),@Src[ProcNameAtom.StartPos])<>0
      then exit;
      i:=CurrentContexts.AddCompilerProc;
      Item:=CurrentContexts[i];
      Item.ProcName:=AProcName;
      Item.ResultType:=ResultType;
      Item.Params:=TStringList.Create;
      Item.Params.Delimiter:=';';
      Item.Params.StrictDelimiter:=true;
      Item.Params.DelimitedText:=Params;
    end;

  begin
    MoveCursorToAtomPos(ProcNameAtom);
    ReadPriorAtom;
    if (CurPos.Flag in [cafEnd,cafSemicolon,cafBegin,cafColon,
      cafRoundBracketOpen,cafEdgedBracketOpen])
    or UpAtomIs('TRY') or UpAtomIs('FINALLY') or UpAtomIs('EXCEPT')
    or UpAtomIs('REPEAT') or UpAtomIs('ASM') then begin
      // see fpc/compiler/psystem.pp
      AddCompilerProc('Assert','Condition:Boolean;const Message:String');
      AddCompilerProc('Assigned','P:Pointer','Boolean');
      AddCompilerProc('Addr','var X','Pointer');
      AddCompilerProc('BitSizeOf','Identifier','Integer');
      AddCompilerProc('Concat','S1:String;S2:String[...;Sn:String]', 'String');
      AddCompilerProc('Copy','const S:String;FromPosition,Count:Integer', 'String');
      AddCompilerProc('Dec','var X:Ordinal;N:Integer=1');
      AddCompilerProc('Dispose','var X:Pointer');
      AddCompilerProc('Exclude','var S:Set;X:Ordinal');
      AddCompilerProc('Exit','ResultValue:Ordinal=Result');
      AddCompilerProc('Finalize','var X');
      AddCompilerProc('get_frame','','Pointer');
      AddCompilerProc('High','Arg:TypeOrVariable','Ordinal');
      AddCompilerProc('Inc','var X:Ordinal;N:Integer=1');
      AddCompilerProc('Include','var S:Set;X:Ordinal');
      AddCompilerProc('Initialize','var X');
      AddCompilerProc('Length','S:String','Integer');
      AddCompilerProc('Length','A:Array','Integer');
      AddCompilerProc('Low','Arg:TypeOrVariable','Ordinal');
      AddCompilerProc('New','var X:Pointer');
      AddCompilerProc('Ofs','var X','LongInt');
      AddCompilerProc('Ord','X:Ordinal', 'Integer');
      AddCompilerProc('Pack','A:Array;N:Integer;var A:Array');
      AddCompilerProc('Pred','X:Ordinal', 'Ordinal');
      AddCompilerProc('Read','');
      AddCompilerProc('ReadLn','');
      AddCompilerProc('ReadStr','S:String;var Args:Arguments');
      AddCompilerProc('Seg','var X','LongInt');
      AddCompilerProc('SetLength','var S:String;NewLength:Integer');
      AddCompilerProc('SetLength','var A:Array;NewLength:Integer');
      AddCompilerProc('SizeOf','Identifier','Integer');
      AddCompilerProc('Slice','var A:Array;Count:Integer','Array');
      AddCompilerProc('Str','const X[:Width[:Decimals]];var S:String');
      AddCompilerProc('Succ','X:Ordinal', 'Ordinal');
      AddCompilerProc('TypeInfo','Identifier', 'Pointer');
      AddCompilerProc('TypeOf','Identifier', 'Pointer');
      AddCompilerProc('Val','S:String;var V;var Code:Integer');
      AddCompilerProc('Unaligned','var X','var');
      AddCompilerProc('Unpack','A:Array;var A:Array;N:Integer');
      AddCompilerProc('Write','Args:Arguments');
      AddCompilerProc('WriteLn','Args:Arguments');
      AddCompilerProc('WriteStr','var S:String;Args:Arguments');
    end;
  end;

  function CheckContextIsParameter(var Ok: boolean): boolean;
  // returns true, on error or context is parameter
  var
    VarNameAtom, ProcNameAtom: TAtomPosition;
    ParameterIndex: integer;
    GatherContext: TFindContext;
    ContextExprStartPos: LongInt;
    StartInSubContext: Boolean;
  begin
    Result:=false;
    // check if in a begin..end block
    if (CursorNode.Desc<>ctnBeginBlock)
    and (not CursorNode.HasParentOfType(ctnBeginBlock)) then begin
      DebugLn(['TIdentCompletionTool.FindCodeContext.CheckContextIsParameter not in a begin block']);
      exit;
    end;
    // check if cursor is in a parameter list
    if not CheckParameterSyntax(CursorNode, CleanCursorPos,
                                VarNameAtom, ProcNameAtom, ParameterIndex)
    then begin
      if VarNameAtom.StartPos=0 then ;
      //DebugLn(['TIdentCompletionTool.FindCodeContext.CheckContextIsParameter not in a parameter list']);
      exit;
    end;
    //DebugLn('CheckContextIsParameter Variable=',GetAtom(VarNameAtom),' Proc=',GetAtom(ProcNameAtom),' ParameterIndex=',dbgs(ParameterIndex));
    
    // it is a parameter -> create context
    Result:=true;
    if CurrentContexts=nil then
      CurrentContexts:=TCodeContextInfo.Create;
    CurrentContexts.Tool:=Self;
    CurrentContexts.ParameterIndex:=ParameterIndex+1;
    CurrentContexts.ProcNameAtom:=ProcNameAtom;
    CurrentContexts.ProcName:=GetAtom(ProcNameAtom);

    AddPredefinedProcs(CurrentContexts,ProcNameAtom);

    MoveCursorToAtomPos(ProcNameAtom);
    ReadNextAtom; // read opening bracket
    CurrentContexts.StartPos:=CurPos.EndPos;
    // read closing bracket
    if ReadTilBracketClose(false) then
      CurrentContexts.EndPos:=CurPos.StartPos
    else
      CurrentContexts.EndPos:=SrcLen+1;

    FindCollectionContext(Params,ProcNameAtom.StartPos,CursorNode,
                          GatherContext,ContextExprStartPos,StartInSubContext);
    if ContextExprStartPos=0 then ;
    //DebugLn(['CheckContextIsParameter StartInSubContext=',StartInSubContext,' ',GatherContext.Node.DescAsString,' "',copy(GatherContext.Tool.Src,GatherContext.Node.StartPos-20,25),'"']);

    // gather declarations of all parameter lists
    Params.ContextNode:=GatherContext.Node;
    Params.SetIdentifier(Self,@Src[ProcNameAtom.StartPos],@CollectAllContexts);
    Params.Flags:=[fdfSearchInAncestors,fdfCollect,fdfFindVariable];
    if not StartInSubContext then
      Include(Params.Flags,fdfSearchInParentNodes);
    CurrentIdentifierList.Context:=GatherContext;
    //DebugLn('CheckContextIsParameter searching procedure ...');
    GatherContext.Tool.FindIdentifierInContext(Params);
    //DebugLn('CheckContextIsParameter END');
    Ok:=true;
  end;

var
  IdentifierList: TIdentifierList;
  IdentStartPos, IdentEndPos: integer;
begin
  CodeContexts:=nil;
  Result:=false;

  IdentifierList:=nil;
  CurrentContexts:=CodeContexts;

  ActivateGlobalWriteLock;
  Params:=TFindDeclarationParams.Create;
  try
    InitCollectIdentifiers(CursorPos,IdentifierList);
    ParseSourceTillCollectionStart(CursorPos,CleanCursorPos,CursorNode,
                                   IdentStartPos,IdentEndPos);
    if IdentStartPos=0 then ;
    if IdentEndPos=0 then ;

    // find class and ancestors if existing (needed for protected identifiers)
    FindContextClassAndAncestors(CursorPos,ClassAndAncestors);

    if CursorNode<>nil then begin
      if not CheckContextIsParameter(Result) then begin
        //DebugLn(['TIdentCompletionTool.FindCodeContext cursor not at parameter']);
        exit;
      end;
    end;

    if CurrentContexts=nil then begin
      // create default
      AddCollectionContext(Self,CursorNode);
    end;

    Result:=true;
  finally
    if Result then begin
      CodeContexts:=CurrentContexts;
      CurrentContexts:=nil;
    end else begin
      FreeAndNil(CurrentContexts);
    end;
    FreeListOfPFindContext(ClassAndAncestors);
    FreeAndNil(FoundPublicProperties);
    Params.Free;
    ClearIgnoreErrorAfter;
    DeactivateGlobalWriteLock;
    FreeAndNil(CurrentIdentifierList);
  end;
end;

function TIdentCompletionTool.FindAbstractMethods(
  const CursorPos: TCodeXYPosition; out ListOfPCodeXYPosition: TFPList;
  SkipAbstractsInStartClass: boolean): boolean;
var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
  Params: TFindDeclarationParams;
  AVLNode: TAVLTreeNode;
  NodeExt: TCodeTreeNodeExtension;
  ATool: TFindDeclarationTool;
  ANode: TCodeTreeNode;
  ProcXYPos: TCodeXYPosition;
  Skip: Boolean;
  ClassNode: TCodeTreeNode;
begin
  Result:=false;
  ListOfPCodeXYPosition:=nil;
  ActivateGlobalWriteLock;
  Params:=nil;
  try
    BuildTreeAndGetCleanPos(trTillCursor,CursorPos,CleanCursorPos,
                  [{$IFNDEF DisableIgnoreErrorAfter}btSetIgnoreErrorPos{$ENDIF}]);

    // find node at position
    CursorNode:=BuildSubTreeAndFindDeepestNodeAtPos(CleanCursorPos,true);

    // if cursor is on type node, find class node
    if CursorNode.Desc=ctnTypeDefinition then
      CursorNode:=CursorNode.FirstChild
    else if CursorNode.Desc=ctnGenericType then
      CursorNode:=CursorNode.LastChild
    else
      CursorNode:=CursorNode.GetNodeOfTypes(
           [ctnClass,ctnClassInterface,ctnObject,ctnObjCClass,ctnObjCProtocol]);
    if (CursorNode=nil)
    or (not (CursorNode.Desc in [ctnClass,ctnObject,ctnObjCClass]))
    or ((CursorNode.SubDesc and ctnsForwardDeclaration)>0) then begin
      MoveCursorToCleanPos(CleanCursorPos);
      RaiseException('TIdentCompletionTool.FindAbstractMethods cursor is not in a class');
    end;
    ClassNode:=CursorNode;

    Params:=TFindDeclarationParams.Create;
    // gather all identifiers in context
    Params.ContextNode:=ClassNode;
    Params.SetIdentifier(Self,nil,@CollectMethods);
    Params.Flags:=[fdfSearchInAncestors,fdfCollect,fdfFindVariable];
    InitFoundMethods;
    FindIdentifierInContext(Params);

    if FoundMethods<>nil then begin
      AVLNode:=FoundMethods.FindLowest;
      while AVLNode<>nil do begin
        NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
        ANode:=NodeExt.Node;
        ATool:=TFindDeclarationTool(NodeExt.Data);
        //DebugLn(['TIdentCompletionTool.FindAbstractMethods ',NodeExt.Txt,' ',ATool.ProcNodeHasSpecifier(ANode,psABSTRACT)]);
        Skip:=false;
        if not ATool.ProcNodeHasSpecifier(ANode,psABSTRACT) then
          Skip:=true;
        if SkipAbstractsInStartClass and (ANode.HasAsParent(ClassNode)) then
          Skip:=true;
        if not Skip then begin
          if not ATool.CleanPosToCaret(ANode.StartPos,ProcXYPos) then
            raise Exception.Create('TIdentCompletionTool.FindAbstractMethods inconsistency');
          AddCodePosition(ListOfPCodeXYPosition,ProcXYPos);
        end;
        AVLNode:=FoundMethods.FindSuccessor(AVLNode);
      end;
    end;

    Result:=true;
  finally
    Params.Free;
    ClearFoundMethods;
    DeactivateGlobalWriteLock;
  end;
end;

function TIdentCompletionTool.GetValuesOfCaseVariable(
  const CursorPos: TCodeXYPosition; List: TStrings): boolean;
var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
  CaseAtom: TAtomPosition;
  Params: TFindDeclarationParams;
  EndPos: LongInt;
  ExprType: TExpressionType;
  Node: TCodeTreeNode;
  Tool: TFindDeclarationTool;
begin
  Result:=false;
  ActivateGlobalWriteLock;
  Params:=nil;
  try
    BuildTreeAndGetCleanPos(trTillCursor,CursorPos,CleanCursorPos,
                  [{$IFNDEF DisableIgnoreErrorAfter}btSetIgnoreErrorPos{$ENDIF}]);

    // find node at position
    CursorNode:=BuildSubTreeAndFindDeepestNodeAtPos(CleanCursorPos,true);

    // find keyword case
    MoveCursorToNodeStart(CursorNode);
    CaseAtom:=CleanAtomPosition;
    repeat
      ReadNextAtom;
      if UpAtomIs('CASE') then
        CaseAtom:=CurPos
    until (CurPos.EndPos>SrcLen) or (CurPos.EndPos>CleanCursorPos);
    if CaseAtom.StartPos<1 then exit;

    // find case variable
    EndPos:=FindEndOfExpression(CaseAtom.EndPos);
    if EndPos>CleanCursorPos then
      EndPos:=CleanCursorPos;
    //DebugLn(['TIdentCompletionTool.GetValuesOfCaseVariable Expr=',dbgstr(copy(Src,CaseAtom.EndPos,EndPos-CaseAtom.EndPos))]);

    Params:=TFindDeclarationParams.Create;
    Params.ContextNode:=CursorNode;
    Params.Flags:=fdfGlobals+fdfDefaultForExpressions;
    ExprType:=FindExpressionTypeOfTerm(CaseAtom.EndPos,EndPos,Params,true);
    //DebugLn(['TIdentCompletionTool.GetValuesOfCaseVariable Type=',ExprTypeToString(ExprType)]);

    if ExprType.Desc=xtContext then begin
      // resolve aliases and properties
      Params.Clear;
      Params.Flags:=fdfGlobals+fdfDefaultForExpressions;
      ExprType.Context:=ExprType.Context.Tool.FindBaseTypeOfNode(Params,
                                 ExprType.Context.Node);
    end;

    case ExprType.Desc of

    xtBoolean,xtByteBool,xtLongBool:
      begin
        List.Add('True');
        List.Add('False');
      end;

    xtContext:
      begin
        Node:=ExprType.Context.Node;
        Tool:=ExprType.Context.Tool;
        if Node=nil then exit;
        case Node.Desc of

        ctnEnumerationType:
          begin
            Node:=Node.FirstChild;
            while Node<>nil do begin
              List.Add(GetIdentifier(@Tool.Src[Node.StartPos]));
              Node:=Node.NextBrother;
            end;
          end;

        else
          debugln(['TIdentCompletionTool.GetValuesOfCaseVariable not an enum: ',Node.DescAsString]);
          exit;
        end;
      end;
    else
      exit;
    end;

    Result:=true;
  finally
    Params.Free;
    DeactivateGlobalWriteLock;
  end;
end;

procedure TIdentCompletionTool.CalcMemSize(Stats: TCTMemStats);
var
  Node: TAVLTreeNode;
  Ext: TCodeTreeNodeExtension;
  m: PtrUint;
begin
  inherited CalcMemSize(Stats);
  if ClassAndAncestors<>nil then
    Stats.Add('TIdentCompletionTool.ClassAndAncestors',
        ClassAndAncestors.Count*(SizeOf(TAVLTreeNode)+SizeOf(TCodeXYPosition)));
  if FoundPublicProperties<>nil then
    Stats.Add('TIdentCompletionTool.FoundPublicProperties',
              FoundPublicProperties.COunt*SizeOf(TAVLTreeNode));
  if FoundMethods<>nil then begin
    m:=PtrUint(FoundMethods.Count)*SizeOf(TAVLTreeNode);
    Node:=FoundMethods.FindLowest;
    while Node<>nil do begin
      Ext:=TCodeTreeNodeExtension(Node.Data);
      inc(m,Ext.CalcMemSize);
      Node:=FoundMethods.FindSuccessor(Node);
    end;
    STats.Add('TIdentCompletionTool.FoundMethods',m);
  end;
  if CurrentIdentifierList<>nil then
    Stats.Add('TIdentCompletionTool.CurrentIdentifierList',
      CurrentIdentifierList.CalcMemSize);
  if CurrentContexts<>nil then
    Stats.Add('TIdentCompletionTool.CurrentContexts',
              CurrentContexts.CalcMemSize);
end;

{ TIdentifierListItem }

function TIdentifierListItem.GetParamTypeList: string;
var
  ANode: TCodeTreeNode;
begin
  if not (iliParamTypeListValid in Flags) then begin
    // Note: if you implement param lists for other than ctnProcedure, check
    //       CompareParamList
    ANode:=Node;
    if (ANode<>nil) and (ANode.Desc=ctnProcedure) then begin
      FParamTypeList:=Tool.ExtractProcHead(ANode,
         [phpWithoutClassKeyword,phpWithoutClassName,
          phpWithoutName,phpInUpperCase]);
      //debugln('TIdentifierListItem.GetParamTypeList A ',GetIdentifier(Identifier),' ',Tool.MainFilename,' ',dbgs(CurNode.StartPos));
    end else
      FParamTypeList:='';
    Include(Flags,iliParamTypeListValid);
  end;
  Result:=FParamTypeList;
end;

function TIdentifierListItem.GetParamNameList: string;
var
  ANode: TCodeTreeNode;
begin
  if not (iliParamNameListValid in Flags) then begin
    // Note: if you implement param lists for other than ctnProcedure, check
    //       CompareParamList
    ANode:=Node;
    if (ANode<>nil) and (ANode.Desc=ctnProcedure) then begin
      FParamNameList:=Tool.ExtractProcHead(ANode,
         [phpWithoutClassKeyword,phpWithoutClassName,
          phpWithoutName,phpInUpperCase,phpWithParameterNames]);
      //debugln('TIdentifierListItem.GetParamNameList A ',GetIdentifier(Identifier),' ',Tool.MainFilename,' ',dbgs(CurNode.StartPos));
    end else
      FParamNameList:='';
    Include(Flags,iliParamNameListValid);
  end;
  Result:=FParamNameList;
end;

function TIdentifierListItem.GetNode: TCodeTreeNode;
begin
  Result:=nil;
  if Tool=nil then
    exit;
  if (not (iliNodeValid in Flags)) then begin
    if iliNodeHashValid in Flags then begin
      RestoreNode;
      if (iliNodeValid in Flags) then begin
        Result:=FNode;
      end;
    end;
    exit;
  end else begin
    if FToolNodesDeletedStep=Tool.NodesDeletedChangeStep then begin
      Result:=FNode;
    end else begin
      DebugLn(['TIdentifierListItem.GetNode node ',Identifier,' is gone from ',Tool.MainFilename]);
      FNode:=nil;
    end;
  end;
end;

procedure TIdentifierListItem.SetNode(const AValue: TCodeTreeNode);

  procedure RaiseToolMissing;
  begin
    raise Exception.Create('TIdentifierListItem.SetNode Node without Tool');
  end;

begin
  FNode:=AValue;
  Include(Flags,iliNodeValid);
  Exclude(Flags,iliNodeHashValid);
  if (FNode<>nil) and (Tool=nil) then
    RaiseToolMissing;
  if (Tool<>nil) then
    FToolNodesDeletedStep:=Tool.NodesDeletedChangeStep;
end;

procedure TIdentifierListItem.SetParamTypeList(const AValue: string);
begin
  FParamTypeList:=AValue;
  Include(Flags,iliParamTypeListValid);
end;

procedure TIdentifierListItem.SetParamNameList(const AValue: string);
begin
  FParamNameList:=AValue;
  Include(Flags,iliParamNameListValid);
end;

procedure TIdentifierListItem.SetResultType(const AValue: string);
begin
  FResultType := AValue;
  Include(Flags, iliResultTypeValid);
end;

function TIdentifierListItem.AsString: string;
var
  ANode: TCodeTreeNode;
begin
  Result:=IdentifierCompatibilityNames[Compatibility];
  if HasChilds then
    Result:=Result+' HasChilds'
  else
    Result:=Result+' HasNoChilds';
  Result:=Result+' History='+IntToStr(HistoryIndex);
  Result:=Result+' Ident='+Identifier;
  Result:=Result+' Lvl='+IntToStr(Level);
  if Tool<>nil then
    Result:=Result+' File='+Tool.MainFilename;
  ANode:=Node;
  if ANode<>nil then
    Result:=Result+' Node='+ANode.DescAsString
      +' "'+StringToPascalConst(copy(Tool.Src,ANode.StartPos,50))+'"';
end;

function TIdentifierListItem.GetDesc: TCodeTreeNodeDesc;
var
  ANode: TCodeTreeNode;
begin
  ANode:=Node;
  if ANode<>nil then
    Result:=ANode.Desc
  else
    Result:=DefaultDesc;
end;

constructor TIdentifierListItem.Create(
  NewCompatibility: TIdentifierCompatibility; NewHasChilds: boolean;
  NewHistoryIndex: integer; NewIdentifier: PChar; NewLevel: integer;
  NewNode: TCodeTreeNode; NewTool: TFindDeclarationTool;
  NewDefaultDesc: TCodeTreeNodeDesc);
begin
  Compatibility:=NewCompatibility;
  if NewHasChilds then Include(FLags,iliHasChilds);
  HistoryIndex:=NewHistoryIndex;
  Identifier:=GetIdentifier(NewIdentifier);
  Level:=NewLevel;
  Tool:=NewTool;
  Node:=NewNode;
  DefaultDesc:=NewDefaultDesc;
  BaseExprType:=CleanExpressionType;
end;

function TIdentifierListItem.IsProcNodeWithParams: boolean;
var
  ANode: TCodeTreeNode;
  StartPos: Integer;
begin
  Result:=(GetDesc=ctnProcedure);
  if not Result then exit;
  if (iliParamNameListValid in Flags) then begin
    StartPos:=1;
    while (StartPos<=length(FParamTypeList))
    and (FParamTypeList[StartPos] in [' ',#9,'(','[']) do
      inc(StartPos);
    if (StartPos<=length(FParamTypeList))
    and (FParamTypeList[StartPos] in [')',']',';']) then
      exit(false)
    else
      exit(true);
  end else if (iliParamTypeListValid in Flags) then begin
    // the type list does not contain names
    // so a () could be empty or (var buf)
    StartPos:=1;
    while (StartPos<=length(FParamTypeList))
    and (FParamTypeList[StartPos] in [' ',#9,'(','[']) do
      inc(StartPos);
    if (StartPos<=length(FParamTypeList))
    and (not (FParamTypeList[StartPos] in [')',']',';'])) then
      exit(true);
  end;
  ANode:=Node;
  Result:=(ANode<>nil) and Tool.ProcNodeHasParamList(ANode);
end;

function TIdentifierListItem.IsPropertyWithParams: boolean;
var
  ANode: TCodeTreeNode;
begin
  ANode:=Node;
  Result:=(ANode<>nil) and Tool.PropertyNodeHasParamList(ANode);
end;

function TIdentifierListItem.CheckHasChilds: boolean;
// returns true if test was successful
var
  ANode: TCodeTreeNode;
begin
  Result:=false;
  if GetDesc in (AllClasses+[ctnRecordType]) then begin
    Result:=true;
    exit;
  end;
  ANode:=Node;
  if ANode=nil then exit;
  UpdateBaseContext;
  if (BaseExprType.Desc=xtContext)
    and (BaseExprType.Context.Node<>nil)
    and (BaseExprType.Context.Node.Desc in (AllClasses+[ctnRecordType]))
  then
    Include(Flags,iliHasChilds);
end;

function TIdentifierListItem.CanBeAssigned: boolean;
var
  ANode: TCodeTreeNode;
begin
  Result:=false;
  ANode:=Node;
  if (ANode=nil) then exit;
  if (GetDesc=ctnVarDefinition) then
    Result:=true;
  if (ANode.Desc in [ctnProperty,ctnGlobalProperty]) then begin
    if Tool.PropertyHasSpecifier(ANode,'write') then exit(true);
    if Tool.PropNodeIsTypeLess(ANode) then begin
      exit(true);// ToDo: search the real property definition
    end;
  end;
end;

procedure TIdentifierListItem.UpdateBaseContext;
var
  Params: TFindDeclarationParams;
  ANode: TCodeTreeNode;
begin
  if (iliBaseExprTypeValid in Flags) then exit;
  BaseExprType:=CleanExpressionType;
  BaseExprType.Desc:=xtNone;
  ANode:=Node;
  if (ANode<>nil) and (Tool<>nil) then begin
    Tool.ActivateGlobalWriteLock;
    Params:=TFindDeclarationParams.Create;
    try
      BaseExprType.Context:=Tool.FindBaseTypeOfNode(Params,ANode);
      if (BaseExprType.Context.Node<>nil) then
        BaseExprType.Desc:=xtContext;
    finally
      Params.Free;
      Tool.DeactivateGlobalWriteLock;
    end;
  end;
  Include(Flags,iliBaseExprTypeValid);
end;

function TIdentifierListItem.HasChilds: boolean;
begin
  Result:=iliHasChilds in Flags;
end;

function TIdentifierListItem.IsFunction: boolean;
var
  ANode: TCodeTreeNode;
begin
  if not (iliIsFunctionValid in Flags) then
  begin
    ANode := Node;
    if (ANode <> nil) and Tool.NodeIsFunction(ANode) then
      Include(Flags, iliIsFunction);
    Include(Flags, iliIsFunctionValid);
  end;
  Result := iliIsFunction in Flags;
end;

function TIdentifierListItem.IsContructor: boolean;
var
  ANode: TCodeTreeNode;
begin
  if not (iliIsConstructorValid in Flags) then
  begin
    ANode := Node;
    if (ANode <> nil) and Tool.NodeIsConstructor(ANode) then
      Include(Flags, iliIsConstructor);
    Include(Flags, iliIsConstructorValid);
  end;
  Result := iliIsConstructor in Flags;
end;

function TIdentifierListItem.IsDestructor: boolean;
var
  ANode: TCodeTreeNode;
begin
  if not (iliIsDestructorValid in Flags) then
  begin
    ANode := Node;
    if (ANode <> nil) and Tool.NodeIsDestructor(ANode) then
      Include(Flags, iliIsDestructor);
    Include(Flags, iliIsDestructorValid);
  end;
  Result := iliIsDestructor in Flags;
end;

function TIdentifierListItem.IsAbstractMethod: boolean;
var
  ANode: TCodeTreeNode;
begin
  if not (iliIsAbstractMethodValid in Flags) then begin
    ANode:=Node;
    if (ANode<>nil)
    and Tool.ProcNodeHasSpecifier(ANode,psABSTRACT) then
      Include(Flags,iliIsAbstractMethod);
    Include(Flags,iliIsAbstractMethodValid);
  end;
  Result:=iliIsAbstractMethod in Flags;
end;

function TIdentifierListItem.TryIsAbstractMethod: boolean;
begin
  try
    Result:=IsAbstractMethod;
  except
    Result:=false;
  end;
end;

procedure TIdentifierListItem.Clear;
begin
  FParamTypeList:='';
  FResultType:='';
  Compatibility:=icompUnknown;
  HistoryIndex:=0;
  Identifier:='';
  Level:=0;
  FNode:=nil;
  Tool:=nil;
  DefaultDesc:=ctnNone;
  Flags:=[];
  BaseExprType:=CleanExpressionType;
end;

procedure TIdentifierListItem.UnbindNode;
begin
  if FNode=nil then exit;
  StoreNodeHash;
  Exclude(Flags,iliNodeValid);
  FNode:=nil;
end;

procedure TIdentifierListItem.StoreNodeHash;
begin
  Include(Flags,iliNodeHashValid);
  FNodeStartPos:=FNode.StartPos;
  FNodeDesc:=FNode.Desc;
  FNodeHash:=GetNodeHash(FNode);
  //DebugLn(['TIdentifierListItem.StoreNodeHash ',Identifier,' Pos=',FNodeStartPos,' Hash=',FNodeHash]);
end;

function TIdentifierListItem.RestoreNode: boolean;
var
  NewNode: TCodeTreeNode;
  NewHash: String;
begin
  if not (iliNodeHashValid in Flags) then exit(true);
  //DebugLn(['TIdentifierListItem.RestoreNode ',Identifier]);
  NewNode:=Tool.BuildSubTreeAndFindDeepestNodeAtPos(FNodeStartPos,false);
  Result:=false;
  if (NewNode=nil) or (NewNode.StartPos<>FNodeStartPos)
  or (NewNode.Desc<>FNodeDesc) then begin
    DebugLn(['TIdentifierListItem.RestoreNode not found: ',Identifier]);
    Exclude(Flags,iliNodeHashValid);
    exit;
  end;
  NewHash:=GetNodeHash(NewNode);
  if NewHash<>FNodeHash then begin
    DebugLn(['TIdentifierListItem.RestoreNode hash changed: ',Identifier]);
    Exclude(Flags,iliNodeHashValid);
    exit;
  end;
  //DebugLn(['TIdentifierListItem.RestoreNode Success ',Identifier]);
  Node:=NewNode;
  Result:=true;
end;

function TIdentifierListItem.GetNodeHash(ANode: TCodeTreeNode): string;
var
  StartPos: LongInt;
  EndPos: LongInt;
begin
  case ANode.Desc of
  ctnVarDefinition,ctnConstDefinition,ctnTypeDefinition,ctnGenericType:
    Result:=Tool.ExtractDefinitionName(ANode)
  else
    StartPos:=ANode.StartPos;
    EndPos:=StartPos+20;
    if EndPos>ANode.EndPos then EndPos:=ANode.EndPos;
    Result:=copy(Tool.Src,StartPos,EndPos);
  end;
end;

function TIdentifierListItem.CompareParamList(CompareItem: TIdentifierListItem
  ): integer;
var
  ANode: TCodeTreeNode;
  CmpNode: TCodeTreeNode;
begin
  Result:=0;
  if Self=CompareItem then exit;
  ANode:=Node;
  CmpNode:=CompareItem.Node;
  if (ANode=CmpNode) then exit;
  if (ANode=nil) or (CmpNode=nil) then exit;
  if (ANode.Desc<>ctnProcedure) or (CmpNode.Desc<>ctnProcedure) then
    exit;
  {DbgOut('TIdentifierListItem.CompareParamList ',GetIdentifier(Identifier),'=',GetIdentifier(CompareItem.Identifier));
  if Node<>nil then
    DbgOut(' Self=',Tool.MainFilename,' ',dbgs(Node.StartPos));
  if CompareItem.Node<>nil then
    DbgOut(' Other=',CompareItem.Tool.MainFilename,' ',dbgs(CompareItem.Node.StartPos));
  debugln('');}
  Result:=CompareTextIgnoringSpace(ParamTypeList,CompareItem.ParamTypeList,false);
end;

function TIdentifierListItem.CompareParamList(
  CompareItem: TIdentifierListSearchItem): integer;
begin
  if (ParamTypeList='') and (CompareItem.ParamList='') then
    exit(0);
  Result:=CompareTextIgnoringSpace(ParamTypeList,CompareItem.ParamList,false);
end;

function TIdentifierListItem.CalcMemSize: PtrUInt;
begin
  Result:=PtrUInt(InstanceSize)
    +MemSizeString(FParamTypeList)
    +MemSizeString(FNodeHash)
    +MemSizeString(Identifier);
end;

{ TIdentifierHistoryList }

procedure TIdentifierHistoryList.SetCapacity(const AValue: integer);
begin
  if FCapacity=AValue then exit;
  FCapacity:=AValue;
  if FCapacity<1 then FCapacity:=1;
  while (FItems.Count>0) and (FItems.Count>=FCapacity) do
    FItems.FreeAndDelete(FItems.FindHighest);
end;

function TIdentifierHistoryList.FindItem(NewItem: TIdentifierListItem
  ): TAVLTreeNode;
begin
  if NewItem<>nil then
    Result:=FItems.FindKey(NewItem,@CompareIdentItemWithHistListItem)
  else
    Result:=nil;
end;

constructor TIdentifierHistoryList.Create;
begin
  FItems:=TAVLTree.Create(@CompareIdentHistListItem);
  FCapacity:=30;
end;

destructor TIdentifierHistoryList.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TIdentifierHistoryList.Clear;
begin
  FItems.FreeAndClear;
end;

procedure TIdentifierHistoryList.Add(NewItem: TIdentifierListItem);
var
  OldAVLNode: TAVLTreeNode;
  NewHistItem: TIdentHistListItem;
  AnAVLNode: TAVLTreeNode;
  AdjustIndex: Integer;
  AnHistItem: TIdentHistListItem;
begin
  if NewItem=nil then exit;
  OldAVLNode:=FindItem(NewItem);
  {$IFDEF ShowHistory}
  DebugLn('TIdentifierHistoryList.Add Count=',Count,' Found=',OldAVLNode<>nil,
    ' ITEM: ',NewItem.AsString);
  {$ENDIF}
  if OldAVLNode<>nil then begin
    // already in tree
    NewHistItem:=TIdentHistListItem(OldAVLNode.Data);
    if NewHistItem.HistoryIndex=0 then exit;
    // must be moved -> remove it from the tree
    AdjustIndex:=NewHistItem.HistoryIndex;
    FItems.Delete(OldAVLNode);
  end else begin
    // create a new history item
    NewHistItem:=TIdentHistListItem.Create;
    NewHistItem.Identifier:=NewItem.Identifier;
    NewHistItem.NodeDesc:=NewItem.GetDesc;
    NewHistItem.ParamList:=NewItem.ParamTypeList;
    AdjustIndex:=0;
  end;
  NewHistItem.HistoryIndex:=0;
  // adjust all other HistoryIndex
  AnAVLNode:=Fitems.FindLowest;
  while AnAVLNode<>nil do begin
    AnHistItem:=TIdentHistListItem(AnAVLNode.Data);
    if AnHistItem.HistoryIndex>=AdjustIndex then
      inc(AnHistItem.HistoryIndex);
    AnAVLNode:=FItems.FindSuccessor(AnAVLNode);
  end;
  if (FItems.Count>0) and (FItems.Count>=FCapacity) then
    FItems.FreeAndDelete(FItems.FindHighest);
  FItems.Add(NewHistItem);
  {$IFDEF ShowHistory}
  DebugLn('TIdentifierHistoryList.Added Count=',Count);
  {$ENDIF}
end;

function TIdentifierHistoryList.GetHistoryIndex(AnItem: TIdentifierListItem
  ): integer;
var
  AnAVLNode: TAVLTreeNode;
begin
  AnAVLNode:=FindItem(AnItem);
  if AnAVLNode=nil then
    Result:=33333333  // a very high value
  else
    Result:=TIdentHistListItem(AnAVLNode.Data).HistoryIndex;
end;

function TIdentifierHistoryList.Count: integer;
begin
  Result:=FItems.Count;
end;

function TIdentifierHistoryList.CalcMemSize: PtrUInt;
var
  Node: TAVLTreeNode;
  Item: TIdentHistListItem;
begin
  Result:=PtrUInt(InstanceSize);
  if FItems<>nil then begin
    inc(Result,FItems.Count*SizeOf(TAVLTreeNode));
    Node:=FItems.FindLowest;
    while Node<>nil do begin
      Item:=TIdentHistListItem(Node.Data);
      inc(Result,Item.CalcMemSize);
      Node:=FItems.FindSuccessor(Node);
    end;
  end;
end;

{ TCodeContextInfo }

function TCodeContextInfo.GetItems(Index: integer): TCodeContextInfoItem;
begin
  Result:=TCodeContextInfoItem(FItems[Index]);
end;

constructor TCodeContextInfo.Create;
begin
  FItems:=TFPList.Create;
end;

destructor TCodeContextInfo.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited Destroy;
end;

function TCodeContextInfo.Count: integer;
begin
  Result:=FItems.Count;
end;

function TCodeContextInfo.Add(const Context: TExpressionType): integer;
var
  Item: TCodeContextInfoItem;
begin
  Item:=TCodeContextInfoItem.Create;
  Item.Expr:=Context;
  Result:=FItems.Add(Item);
end;

function TCodeContextInfo.AddCompilerProc: integer;
var
  Item: TCodeContextInfoItem;
begin
  Item:=TCodeContextInfoItem.Create;
  Result:=FItems.Add(Item);
end;

procedure TCodeContextInfo.Clear;
var
  i: Integer;
begin
  for i:=0 to FItems.Count-1 do
    TObject(FItems[i]).Free;
  FItems.Clear;
end;

function TCodeContextInfo.CalcMemSize: PtrUInt;
begin
  Result:=PtrUInt(InstanceSize)
    +PtrUInt(TCodeContextInfoItem)*SizeOf(FItems.Count)
    +MemSizeString(FProcName);
end;

{ TIdentifierListSearchItem }

function TIdentifierListSearchItem.CalcMemSize: PtrUInt;
begin
  Result:=PtrUInt(InstanceSize)
    +MemSizeString(ParamList);
end;

{ TIdentHistListItem }

function TIdentHistListItem.CalcMemSize: PtrUInt;
begin
  Result:=PtrUInt(InstanceSize)
    +MemSizeString(Identifier)
    +MemSizeString(ParamList);
end;

{ TCodeContextInfoItem }

destructor TCodeContextInfoItem.Destroy;
begin
  FreeAndNil(Params);
  inherited Destroy;
end;

initialization
  IdentifierListItemMemManager:=TIdentifierListItemMemManager.Create;
  
finalization
  IdentifierListItemMemManager.Free;
  IdentifierListItemMemManager:=nil;

end.

