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
(* some parts (AdjustBalance...) of this unit are based on the AVLTree unit *)
(* TODO: Implement node.eof / node.bof *)
unit SynEditFoldedView;

{$mode objfpc}{$H+}
{$IFDEF CPUPOWERPC} {$INLINE OFF} {$ENDIF} (* Workaround for bug 12576 (fpc) see bugs.freepascal.org/view.php?id=12576 *)

interface

uses
LCLProc,
  Classes, SysUtils, SynEditTypes, SynEditTextBuffer, SynEditTextBase,
  SynEditMiscClasses, SynEditPointClasses;

type

  TReplacedChildSite = (rplcLeft, rplcRight);

  { TSynTextFoldAVLNodeData }

  TSynTextFoldAVLNodeData = Class
  public
    Parent, Left, Right : TSynTextFoldAVLNodeData;    (* AVL Links *)
    Balance : shortint;                               (* AVL Balance *)
    Nested : TSynTextFoldAVLNodeData; (* Nested folds (folds within this fold) do not need to be part of the searchable tree
                             They will be restored, if the outer fold (this fold) is unfolded
                             Nested points to a standalone tree, the root node in the nested tree, does *not* point back to this node *)
    LineOffset : Integer; (* Line-Number Offset to parent node
                             All line numbers are stored as offsets, for faster updates if lines are inserted/deleted *)
    LeftCount : Integer;  (* Lines folded in left tree. Used to calculate how many lines are folded up to a specified line *)
    LineCount : Integer;  (* Amount of lines covered by this fold only *)

    function TreeDepth: integer;           (* longest WAY down. Only one node => 1! *)
    function RecursiveFoldCount : Integer; (* Amount of lines covered by this and all child nodes *)

    procedure SetLeftChild(ANode : TSynTextFoldAVLNodeData); overload; inline;
    procedure SetLeftChild(ANode : TSynTextFoldAVLNodeData; anAdjustChildLineOffset : Integer); overload; inline;
    procedure SetLeftChild(ANode : TSynTextFoldAVLNodeData; anAdjustChildLineOffset, aLeftCount : Integer); overload; inline;

    procedure SetRightChild(ANode : TSynTextFoldAVLNodeData); overload; inline;
    procedure SetRightChild(ANode : TSynTextFoldAVLNodeData; anAdjustChildLineOffset : Integer); overload; inline;

    function ReplaceChild(OldNode, ANode : TSynTextFoldAVLNodeData) : TReplacedChildSite; overload; inline;
    function ReplaceChild(OldNode, ANode : TSynTextFoldAVLNodeData; anAdjustChildLineOffset : Integer) : TReplacedChildSite; overload; inline;

    procedure AdjustLeftCount(AValue : Integer);
    procedure AdjustParentLeftCount(AValue : Integer);

    function Precessor : TSynTextFoldAVLNodeData;
    function Successor : TSynTextFoldAVLNodeData;
    function Precessor(var aStartLine, aLinesBefore : Integer) : TSynTextFoldAVLNodeData;
    function Successor(var aStartLine, aLinesBefore : Integer) : TSynTextFoldAVLNodeData;
  end;

  { TSynTextFoldAVLNode }

  TSynTextFoldAVLNode = object
  private
    function GetLineCount : Integer;
  protected
    fData : TSynTextFoldAVLNodeData; // nil if unfolded
    fStartLine : Integer;            // start of folded
    fFoldedBefore : Integer;
  public
    function IsInFold : Boolean;
    function Next : TSynTextFoldAVLNode;
    function Prev : TSynTextFoldAVLNode;
    property LineCount : Integer read GetLineCount; // Zero, if Not in a fold
    property StartLine : Integer read fStartLine;   // 1st Line of Current Fold
    property FoldedBefore : Integer read fFoldedBefore;  // Count of Lines folded before Startline
  end;
  
  { TSynTextFoldAVLTree
    Nodes in the tree cover the folded lines only
    the cfCollapsed line at the start of a fold, is *not* part of a node.
    RemoveFoldForline has special precaution for this.
  }

  TSynTextFoldAVLTree = class
  protected
    fRoot: TSynTextFoldAVLNodeData;
    fNestParent: TSynTextFoldAVLNodeData;
    fNestedNodesTree: TSynTextFoldAVLTree; // FlyWeight Tree used for any nested subtree.
    fRootOffset : Integer;

    function NewNode : TSynTextFoldAVLNodeData; inline;
    procedure DisposeNode(var ANode : TSynTextFoldAVLNodeData); inline;
    Function RemoveFoldForNodeAtLine(ANode: TSynTextFoldAVLNode; ALine : Integer;
      IgnoreFirst : Boolean = False) : Integer; overload; // Line is for Nested Nodes

    procedure SetRoot(ANode : TSynTextFoldAVLNodeData); overload; inline;
    procedure SetRoot(ANode : TSynTextFoldAVLNodeData; anAdjustChildLineOffset : Integer); overload; inline;

    Function  InsertNode(ANode : TSynTextFoldAVLNodeData) : Integer; // returns FoldedBefore // ANode may not have children
    procedure RemoveNode(ANode: TSynTextFoldAVLNodeData);
    procedure BalanceAfterInsert(ANode: TSynTextFoldAVLNodeData);
    procedure BalanceAfterDelete(ANode: TSynTextFoldAVLNodeData);
    function TreeForNestedNode(ANode: TSynTextFoldAVLNodeData; aOffset : Integer) : TSynTextFoldAVLTree;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    (* Find Fold by Line in Real Text *)
    Function FindFoldForLine(ALine : Integer; FindNextNode : Boolean = False) : TSynTextFoldAVLNode;
    (* Find Fold by Line in Folded Text // always returns unfolded, unless next=true *)
    Function FindFoldForFoldedLine(ALine : Integer; FindNextNode : Boolean = False) : TSynTextFoldAVLNode;
    Function InsertNewFold(ALine, ACount : Integer) : TSynTextFoldAVLNode;
    (* This will unfold the block which either contains tALine, or has Aline as its cgColapsed line
       If IgnoreFirst, the cfCollapsed will *not* unfold => Hint: IgnoreFirst = Make folded visible
       Returns the pos(1-based) of the cfCollapsed Line that was expanded; or ALine, if nothing was done
    *)
    Function RemoveFoldForLine(ALine : Integer;
      IgnoreFirst : Boolean = False) : Integer; overload;
    Procedure AdjustForLinesInserted(AStartLine, ALineCount : Integer);
    Procedure AdjustForLinesDeleted(AStartLine, ALineCount : Integer);
    Function FindLastFold : TSynTextFoldAVLNode;
    Function FindFirstFold : TSynTextFoldAVLNode;
    procedure debug;
  end;

  TSynEditCodeFoldType = (
    cfNone,       // line is not in a block
    cfCollapsed,  // line is start of collapsed block
    cfExpanded,   // line is start of expanded block
    cfContinue,   // line is middle part of block(s)
    cfEnd         // line is end of block(s)
    );
  TFoldChangedEvent = procedure(aLine: Integer) of object;
const
  SynEditCodeFoldTypeNames: array[TSynEditCodeFoldType] of string = (
    'cfNone',
    'cfCollapsed',
    'cfExpanded',
    'cfContinue',
    'cfEnd'
    );

type
  { TSynTextFoldedView
      *Line      = Line (0-based) on Screen (except TopLine which should be TopViewPos)
      *ViewPos   = Line (1-based) in the array of viewable/visible lines
      *TextIndex = Line (0-based) in the complete text(folded and unfolded)
  }
  
  { TSynEditFoldedView }

  TSynEditFoldedView = class {TODO: Make a base class, that just maps everything one to one}
  private
    fCaret: TSynEditCaret;
    fLines : TSynEditStrings;
    fFoldTree : TSynTextFoldAVLTree;   // Folds are stored 1-based (the 1st line is 1)
    fTopLine : Integer;
    fLinesInWindow : Integer;          // there may be an additional part visible line
    fTextIndexList : Array of integer;   (* Map each Screen line into a line in textbuffer *)
    fFoldTypeList : Array of TSynEditCodeFoldType;
    fOnFoldChanged : TFoldChangedEvent;
    fCFDividerDrawLevel: Integer;
    fLockCount : Integer;
    fNeedFixFrom, fNeedFixMinEnd : Integer;
    fNeedCaretCheck : Boolean;

    function GetCount : integer;
    function GetDrawDivider(Index : integer) : Boolean;
    function GetLines(index : Integer) : String;
    function GetDisplayNumber(index : Integer) : Integer;
    function GetRange(Index : integer) : TSynEditRange;
    function GetTextIndex(index : Integer) : Integer;
    function GetFoldType(index : Integer) : TSynEditCodeFoldType;
    function IsFolded(index : integer) : Boolean;  // TextIndex
    procedure PutRange(Index : integer; const AValue : TSynEditRange);
    procedure SetTopLine(const ALine : integer);
    function  GetTopTextIndex : integer;
    procedure SetTopTextIndex(const AIndex : integer);
    procedure SetLinesInWindow(const AValue : integer);
  protected
    Procedure CalculateMaps;
    function  LengthForFoldAtTextIndex(ALine : Integer) : Integer;
    function FixFolding(AStart : Integer; AMinEnd : Integer; aFoldTree : TSynTextFoldAVLTree) : Boolean;

    procedure DoCaretChanged(Sender : TObject);
    Procedure LineCountChanged(AIndex, ACount : Integer);
    Procedure LinesInsertedAtTextIndex(AStartIndex, ALineCount : Integer;
                                       SkipFixFolding : Boolean = False);
    Procedure LinesInsertedAtViewPos(AStartPos, ALineCount : Integer;
                                     SkipFixFolding : Boolean = False);
    Procedure LinesDeletedAtTextIndex(AStartIndex, ALineCount : Integer;
                                      SkipFixFolding : Boolean = False);
    Procedure LinesDeletedAtViewPos(AStartPos, ALineCount : Integer;
                                    SkipFixFolding : Boolean = False);
  public
    constructor Create(aTextBuffer : TSynEditStringList; aTextView : TSynEditStrings; ACaret: TSynEditCaret);
    destructor Destroy; override;
    
    // Converting between Folded and Unfolded Lines/Indexes
    function TextIndexToViewPos(aTextIndex : Integer) : Integer;    (* Convert TextIndex (0-based) to ViewPos (1-based) *)
    function TextIndexToScreenLine(aTextIndex : Integer) : Integer; (* Convert TextIndex (0-based) to Screen (0-based) *)
    function ViewPosToTextIndex(aViewPos : Integer) : Integer;      (* Convert ViewPos (1-based) to TextIndex (0-based) *)
    function ScreenLineToTextIndex(aLine : Integer) : Integer;      (* Convert Screen (0-based) to TextIndex (0-based) *)

    function TextIndexAddLines(aTextIndex, LineOffset : Integer) : Integer;     (* Add/Sub to/from TextIndex (0-based) skipping folded *)
    function TextPosAddLines(aTextpos, LineOffset : Integer) : Integer;     (* Add/Sub to/from TextPos (1-based) skipping folded *)

    // Attributes for Visible-Lines-On-screen
    property Lines[index : Integer] : String            (* Lines on screen / 0 = TopLine *)
      read GetLines; default;
    property Ranges[Index: integer]: TSynEditRange
      read GetRange write PutRange;
    property DisplayNumber[index : Integer] : Integer   (* LineNumber for display in Gutter / result is 1-based *)
      read GetDisplayNumber;
    property FoldType[index : Integer] : TSynEditCodeFoldType (* FoldIcon / State *)
      read GetFoldType;
    property DrawDivider[Index: integer]: Boolean
      read GetDrawDivider;
    property TextIndex[index : Integer] : Integer       (* Position in SynTextBuffer / result is 0-based *)
      read GetTextIndex; // maybe writable

    // Define Visible Area
    property TopLine : integer                          (* refers to visible (unfolded) lines / 1-based *)
      read fTopLine write SetTopLine;
    property TopTextIndex : integer                     (* refers to TextIndex (folded + unfolded lines) / 1-based *)
      read GetTopTextIndex write SetTopTextIndex;
    property LinesInWindow : integer                    (* Fully Visible lines in Window; There may be one half visible line *)
      read fLinesInWindow write SetLinesInWindow;

    property Count : integer read GetCount;             (* refers to visible (unfolded) lines *)

    property CFDividerDrawLevel: Integer read fCFDividerDrawLevel write fCFDividerDrawLevel;

  public
    procedure Lock;
    procedure UnLock;
    procedure debug;
    // Action Fold/Unfold
    procedure FoldAtLine(AStartLine: Integer);       (* Folds at ScreenLine / 0-based *)
    procedure FoldAtViewPos(AStartPos: Integer);     (* Folds at nth visible/unfolded Line / 1-based *)
    procedure FoldAtTextIndex(AStartIndex: Integer); (* Folds at nth TextIndex (all lines in buffer) / 1-based *)
    procedure UnFoldAtLine(AStartLine: Integer; IgnoreFirst : Boolean = False);       (* UnFolds at ScreenLine / 0-based *)
    procedure UnFoldAtViewPos(AStartPos: Integer; IgnoreFirst : Boolean = False);     (* UnFolds at nth visible/unfolded Line / 1-based *)
    procedure UnFoldAtTextIndex(AStartIndex: Integer; IgnoreFirst : Boolean = False); (* UnFolds at nth TextIndex (all lines in buffer) / 1-based *)

    procedure UnfoldAll;
    procedure FoldAll(StartLevel : Integer = 0; IgnoreNested : Boolean = False);
    procedure FixFoldingAtTextIndex(AStartIndex: Integer; AMinEndLine: Integer = 0); // Real/All lines
    
    // Find the visible first line of the fold at ALine. Returns -1 if Aline is not folded
    function CollapsedLineForFoldAtLine(ALine : Integer) : Integer;
    function ExpandedLineForBlockAtLine(ALine : Integer) : Integer;

    property FoldedAtTextIndex [index : integer] : Boolean read IsFolded;

    property OnFoldChanged: TFoldChangedEvent  (* reports 1-based line *) {TODO: synedit expects 0 based }
      read fOnFoldChanged write fOnFoldChanged;
  end;

  
implementation
uses
  SynEditMiscProcs;

{ TSynTextFoldAVLNodeData }

function TSynTextFoldAVLNodeData.TreeDepth : integer;
var t: integer;
begin
  Result := 1;
  if Left<>nil  then Result := Left.TreeDepth+1;
  if Right<>nil then t := Right.TreeDepth+1 else t := 0;
  if t> Result then Result := t;
end;

function TSynTextFoldAVLNodeData.RecursiveFoldCount : Integer;
var ANode : TSynTextFoldAVLNodeData;
begin
  Result := 0;
  ANode := self;
  while ANode <> nil do begin
    Result := Result + ANode.LineCount + ANode.LeftCount;
    ANode := ANode.Right;
  end;
end;

procedure TSynTextFoldAVLNodeData.SetLeftChild(ANode : TSynTextFoldAVLNodeData); inline;
begin
  Left := ANode;
  if ANode <> nil then ANode.Parent := self;
end;

procedure TSynTextFoldAVLNodeData.SetLeftChild(ANode : TSynTextFoldAVLNodeData; anAdjustChildLineOffset : Integer); inline;
begin
  Left := ANode;
  if ANode <> nil then begin
    ANode.Parent := self;
    ANode.LineOffset := ANode.LineOffset + anAdjustChildLineOffset;
  end;
end;

procedure TSynTextFoldAVLNodeData.SetLeftChild(ANode : TSynTextFoldAVLNodeData; anAdjustChildLineOffset, aLeftCount : Integer); inline;
begin
  Left := ANode;
  LeftCount := aLeftCount;
  if ANode <> nil then begin
    ANode.Parent := self;
    ANode.LineOffset := ANode.LineOffset + anAdjustChildLineOffset;
  end
end;

procedure TSynTextFoldAVLNodeData.SetRightChild(ANode : TSynTextFoldAVLNodeData); inline;
begin
  Right := ANode;
  if ANode <> nil then ANode.Parent := self;
end;

procedure TSynTextFoldAVLNodeData.SetRightChild(ANode : TSynTextFoldAVLNodeData; anAdjustChildLineOffset : Integer); inline;
begin
  Right := ANode;
  if ANode <> nil then begin
    ANode.Parent := self;
    ANode.LineOffset := ANode.LineOffset + anAdjustChildLineOffset;
  end;
end;

function TSynTextFoldAVLNodeData.ReplaceChild(OldNode, ANode : TSynTextFoldAVLNodeData) : TReplacedChildSite; inline;
begin
  if Left = OldNode then begin
    SetLeftChild(ANode);
    exit(rplcLeft);
  end;
  SetRightChild(ANode);
  result := rplcRight;
end;

function TSynTextFoldAVLNodeData.ReplaceChild(OldNode, ANode : TSynTextFoldAVLNodeData; anAdjustChildLineOffset : Integer) : TReplacedChildSite;
  inline;
begin
  if Left = OldNode then begin
    SetLeftChild(ANode, anAdjustChildLineOffset);
    exit(rplcLeft);
  end;
  SetRightChild(ANode, anAdjustChildLineOffset);
  result := rplcRight;
end;

procedure TSynTextFoldAVLNodeData.AdjustLeftCount(AValue : Integer);
begin
  LeftCount := LeftCount + AValue;
  AdjustParentLeftCount(AValue);
end;

procedure TSynTextFoldAVLNodeData.AdjustParentLeftCount(AValue : Integer);
var
  node, pnode : TSynTextFoldAVLNodeData;
begin
  node := self;
  pnode := node.Parent;
  while pnode <> nil do begin
    if node = pnode.Left
    then pnode.LeftCount := pnode.LeftCount + AValue;
    node := pnode;
    pnode := node.Parent;
  end;
end;

function TSynTextFoldAVLNodeData.Precessor : TSynTextFoldAVLNodeData;
begin
  Result := Left;
  if Result<>nil then begin
    while (Result.Right<>nil) do Result := Result.Right;
  end else begin
    Result := self;
    while (Result.Parent<>nil) and (Result.Parent.Left=Result) do
      Result := Result.Parent;
    Result := Result.Parent;
  end;
end;

function TSynTextFoldAVLNodeData.Successor : TSynTextFoldAVLNodeData;
begin
  Result := Right;
  if Result<>nil then begin
    while (Result.Left<>nil) do Result := Result.Left;
  end else begin
    Result := self;
    while (Result.Parent<>nil) and (Result.Parent.Right=Result) do
      Result := Result.Parent;
    Result := Result.Parent;
  end;
end;

function TSynTextFoldAVLNodeData.Precessor(var aStartLine, aLinesBefore : Integer) : TSynTextFoldAVLNodeData;
begin
  Result := Left;
  if Result<>nil then begin
    aStartLine := aStartLine + Result.LineOffset;
    while (Result.Right<>nil) do begin
      Result := Result.Right;
      aStartLine := aStartLine + Result.LineOffset;
    end;
  end else begin
    Result := self;
    while (Result.Parent<>nil) and (Result.Parent.Left=Result) do begin
      aStartLine := aStartLine - Result.LineOffset;
      Result := Result.Parent;
    end;
    // result is now a right son
    aStartLine := aStartLine - Result.LineOffset;
    Result := Result.Parent;
  end;
  if result <> nil then
    aLinesBefore := aLinesBefore - result.LineCount
  else
    aLinesBefore := 0;
end;

function TSynTextFoldAVLNodeData.Successor(var aStartLine, aLinesBefore : Integer) : TSynTextFoldAVLNodeData;
begin
  aLinesBefore := aLinesBefore + LineCount;
  Result := Right;
  if Result<>nil then begin
    aStartLine := aStartLine + Result.LineOffset;
    while (Result.Left<>nil) do begin
      Result := Result.Left;
      aStartLine := aStartLine + Result.LineOffset;
    end;
  end else begin
    Result := self;
    while (Result.Parent<>nil) and (Result.Parent.Right=Result) do begin
      aStartLine := aStartLine - Result.LineOffset;
      Result := Result.Parent;
    end;
    // Result is now a left son; result has a negative LineOffset
    aStartLine := aStartLine - Result.LineOffset;
    Result := Result.Parent;
  end;
end;

{ TSynTextFoldAVLNode }

function TSynTextFoldAVLNode.GetLineCount : Integer;
begin
  if fData = nil
  then Result := 0
  else Result := fData.LineCount;
end;

function TSynTextFoldAVLNode.IsInFold : Boolean;
begin
  Result := fData <> nil;
end;

function TSynTextFoldAVLNode.Next : TSynTextFoldAVLNode;
var aStart, aBefore : Integer;
begin
  if fData <> nil then begin
    aStart := StartLine;
    aBefore := FoldedBefore;
    Result.fData := fData.Successor(aStart, aBefore);
    Result.fStartLine := aStart;
    Result.fFoldedBefore := aBefore;
  end
  else Result.fData := nil;
end;

function TSynTextFoldAVLNode.Prev : TSynTextFoldAVLNode;
var aStart, aBefore : Integer;
begin
  if fData <> nil then begin
    aStart := StartLine;
    aBefore := FoldedBefore;
    Result.fData := fData.Precessor(aStart, aBefore);
    Result.fStartLine := aStart;
    Result.fFoldedBefore := aBefore;
  end
  else Result.fData := nil;
end;

{ TSynTextFoldAVLTree }

function TSynTextFoldAVLTree.NewNode : TSynTextFoldAVLNodeData;
begin
  Result := TSynTextFoldAVLNodeData.Create;
end;

procedure TSynTextFoldAVLTree.DisposeNode(var ANode : TSynTextFoldAVLNodeData);
begin
  FreeAndNil(ANode);
end;

destructor TSynTextFoldAVLTree.Destroy;
begin
  Clear;
  if fNestedNodesTree <> nil then begin
    fNestedNodesTree.fRoot := nil; //was freed in self.Clear
    fNestedNodesTree.fNestParent := nil; // Or Destroy will access invalid memory
    fNestedNodesTree.Free;
  end;
  inherited Destroy;
end;

procedure TSynTextFoldAVLTree.Clear;
  procedure DeleteNode(var ANode: TSynTextFoldAVLNodeData);
  begin
    if ANode.Left <>nil   then DeleteNode(ANode.Left);
    if ANode.Right <>nil  then DeleteNode(ANode.Right);
    if ANode.Nested <>nil then DeleteNode(ANode.Nested);
    DisposeNode(ANode);
  end;
begin
  if fRoot <> nil then DeleteNode(fRoot);
  SetRoot(nil);
end;

procedure TSynTextFoldAVLTree.SetRoot(ANode : TSynTextFoldAVLNodeData); inline;
begin
  fRoot := ANode;
  if fNestParent <> nil then fNestParent.Nested := ANode;
  if ANode <> nil then ANode.Parent := nil;
end;

procedure TSynTextFoldAVLTree.SetRoot(ANode : TSynTextFoldAVLNodeData; anAdjustChildLineOffset : Integer);
  inline;
begin
  fRoot := ANode;
  if fNestParent <> nil then fNestParent.Nested := ANode;
  if ANode <> nil then begin
    ANode.Parent := nil;
    ANode.LineOffset := ANode.LineOffset + anAdjustChildLineOffset;
  end;
end;

function TSynTextFoldAVLTree.FindFoldForLine(ALine : Integer; FindNextNode : Boolean = False) : TSynTextFoldAVLNode;
var
  r : TSynTextFoldAVLNodeData;
  rStartLine : Integer;
  rFoldedBefore : Integer;
begin
  r := fRoot;
  rStartLine := fRootOffset;
  rFoldedBefore := 0;
  while (r <> nil) do begin
    rStartLine := rStartLine + r.LineOffset;
    
    if ALine < rStartLine then begin
      if FindNextNode and (r.Left = nil) then break;
      r := r.Left; // rStartLine points to r, so if r.Left is nil then it is pointing to the next fold;
      continue;
    end;

    rFoldedBefore := rFoldedBefore + r.LeftCount;
    if ALine < rStartLine + r.LineCount
    then break;

    if FindNextNode and (r.Right = nil) then begin
      r := r.Successor(rStartLine, rFoldedBefore);
      break;
    end;

    rFoldedBefore := rFoldedBefore + r.LineCount;
    r := r.Right; // rStartLine points to r, which now is the start of the previous fold;
  end;

  Result.fData := r;
  Result.fStartLine := rStartLine; // only IF r <> nil
  Result.fFoldedBefore := rFoldedBefore; // always ok
end;

function TSynTextFoldAVLTree.FindFoldForFoldedLine(ALine : Integer; FindNextNode : Boolean) : TSynTextFoldAVLNode;
var
  r : TSynTextFoldAVLNodeData;
  rStartLine : Integer;
  rFoldedBefore : Integer;
begin
  r := fRoot;
  rStartLine := fRootOffset;
  rFoldedBefore := 0;
  while (r <> nil) do begin
    rStartLine := rStartLine + r.LineOffset;

    if ALine + r.LeftCount < rStartLine then begin
      if FindNextNode and (r.Left = nil) then break;
      r := r.Left; // rStartLine points to r, so if r.Left is nil then it is pointing to the next fold;
      continue;
    end;

    ALine := ALine + r.LeftCount + r.LineCount;
    rFoldedBefore := rFoldedBefore + r.LeftCount;

    if FindNextNode and (r.Right = nil) then begin
      r := r.Successor(rStartLine, rFoldedBefore);
      break;
    end;

    rFoldedBefore := rFoldedBefore + r.LineCount;
    r := r.Right; // rStartLine points to r, which now is the start of the previous fold;
  end;

  Result.fData := r;
  Result.fStartLine := rStartLine; // only IF r <> nil
  Result.fFoldedBefore := rFoldedBefore; // always ok
end;

procedure TSynTextFoldAVLTree.AdjustForLinesInserted(AStartLine, ALineCount : Integer);
var
  Current : TSynTextFoldAVLNodeData;
  CurrentLine : Integer;
begin
  Current := fRoot;
  CurrentLine := fRootOffset;
  
  while (Current <> nil) do begin
    CurrentLine := CurrentLine + Current.LineOffset;

    if AStartLine < CurrentLine then begin
      // move current node
      Current.LineOffset := Current.LineOffset + ALineCount;
      CurrentLine := CurrentLine + ALineCount;
      if Current.Left <> nil then
        Current.Left.LineOffset := Current.Left.LineOffset - ALineCount;
      Current := Current.Left;
    end
    else if AStartLine > CurrentLine + Current.LineCount - 1 then begin
      // The new lines are entirly behind the current node
      Current := Current.Right;
    end
    else begin
      // grow current node
      Current.LineCount := Current.LineCount + ALineCount;
      Current.AdjustParentLeftCount(ALineCount);
      TreeForNestedNode(Current, CurrentLine).AdjustForLinesInserted(AStartLine, ALineCount);
      if Current.Right <> nil then // and move entire right
        Current.Right.LineOffset := Current.Right.LineOffset + ALineCount;
      break;
    end;
  end;
end;

procedure TSynTextFoldAVLTree.AdjustForLinesDeleted(AStartLine, ALineCount : Integer);
  Procedure UnfoldForRange(Current : TSynTextFoldAVLNodeData; CurrentLine, StartLine, LineCount : Integer);
  begin
    // unfold any node, that has either start or end line in the range
  end;
  
  Procedure AdjustNodeForLinesDeleted(Current : TSynTextFoldAVLNodeData; CurrentLine, StartLine, LineCount : Integer);
  var
    EndLine, LinesBefore, LinesInside, LinesAfter, t : Integer;
  begin
    EndLine := StartLine + LineCount - 1; // only valid for delete; LineCount < 0

    while (Current <> nil) do begin
      CurrentLine := CurrentLine + Current.LineOffset;

      if StartLine < CurrentLine then begin
        // move current node
        if EndLine >= CurrentLine then begin
          // overlap => shrink
          LinesBefore := CurrentLine - StartLine;
          LinesInside := LineCount - LinesBefore;
          // shrink
          t := Current.LineCount;
          Current.LineCount := Max(Current.LineCount - LinesInside, -1);
          Current.AdjustParentLeftCount(Current.LineCount - t); // If LineCount = -1; LeftCount will be correctd on delete node
          TreeForNestedNode(Current, CurrentLine).AdjustForLinesDeleted(CurrentLine, LinesInside);

          if (Current.Right <> nil) and (LinesInside > 0) then begin
            // move right // Calculate from the new curent.LineOffset, as below
            AdjustNodeForLinesDeleted(Current.Right, CurrentLine - LinesBefore,
                                      StartLine, LinesInside);
          end;
        end
        else LinesBefore := LineCount;

        // move current node (includes right subtree / left subtree needs eval)
        Current.LineOffset := Current.LineOffset - LinesBefore;
        CurrentLine := CurrentLine - LinesBefore;
        if Current.Left <> nil then
          Current.Left.LineOffset := Current.Left.LineOffset + LinesBefore;
        Current := Current.Left;
      end
      else if StartLine > CurrentLine + Current.LineCount - 1 then begin
        // The deleted lines are entirly behind the current node
        Current := Current.Right;
      end
      else begin // (StartLine >= CurrentLine) AND (StartLine < CurrentLine - Current.LineCount);
        LinesAfter  := EndLine - (CurrentLine + Current.LineCount - 1);
        if LinesAfter < 0 then LinesAfter := 0;
        LinesInside := LineCount - LinesAfter;
        // shrink current node
        t := Current.LineCount;
        Current.LineCount := Current.LineCount - LinesInside;
        Current.AdjustParentLeftCount(Current.LineCount - t);
        TreeForNestedNode(Current, CurrentLine).AdjustForLinesDeleted(StartLine, LinesInside);

        Current := Current.Right;
      end;

    end;
  end;

begin
  AdjustNodeForLinesDeleted(fRoot, fRootOffset, AStartLine, ALineCount);
end;

function TSynTextFoldAVLTree.FindLastFold : TSynTextFoldAVLNode;
var
  r : TSynTextFoldAVLNodeData;
  rStartLine : Integer;
  rFoldedBefore : Integer;
begin
  r := fRoot;
  rStartLine := fRootOffset;
  rFoldedBefore := 0;
  while (r <> nil) do begin
    rStartLine := rStartLine + r.LineOffset;
    rFoldedBefore := rFoldedBefore + r.LeftCount + r.LineCount;
    if r.Right = nil then break;
    r := r.Right; // rStartLine points to r, which now is the start of the previous fold;
  end;

  Result.fData := r;
  Result.fStartLine := rStartLine; // only IF r <> nil
  Result.fFoldedBefore := rFoldedBefore; // always ok
end;

function TSynTextFoldAVLTree.FindFirstFold : TSynTextFoldAVLNode;
var
  r : TSynTextFoldAVLNodeData;
  rStartLine : Integer;
begin
  r := fRoot;
  rStartLine := fRootOffset;
  while (r <> nil) do begin
    rStartLine := rStartLine + r.LineOffset;
    if r.Left = nil then break;
    r := r.Left;
  end;

  Result.fData := r;
  Result.fStartLine := rStartLine; // only IF r <> nil
  Result.fFoldedBefore := 0; // first fold
end;

procedure TSynTextFoldAVLTree.debug;
  function debug2(ind, typ : String; ANode, AParent : TSynTextFoldAVLNodeData; offset : integer) :integer;
  begin
    result := 0;
    if ANode = nil then exit;
    with ANode do
      DebugLn([ind,typ,' LineOffset: ',LineOffset,',  LineCount: ', LineCount,',  LeftCount: ',LeftCount,',  Balance: ',Balance,'    ##Line=', offset+LineOffset]);
    if ANode.Parent <> AParent then DebugLn([ind,'* Bad parent']);
    Result := debug2(ind+'   ', 'L', ANode.Left, ANode, offset+ANode.LineOffset);
    If Result <> ANode.LeftCount then  debugln([ind,'   ***** Leftcount was ',Result, ' but should be ', ANode.LeftCount]);
    Result += debug2(ind+'   ', 'R', ANode.Right, ANode, offset+ANode.LineOffset);
    debug2(ind+'  #', 'N', ANode.Nested, nil, offset+ANode.LineOffset);
    Result += ANode.LineCount;
  end;
begin
  debug2('', '-', fRoot, nil, 0);
end;

function TSynTextFoldAVLTree.InsertNewFold(ALine, ACount : Integer) : TSynTextFoldAVLNode;
var
  r : TSynTextFoldAVLNodeData;
begin
  r := NewNode;
  r.LineOffset := ALine;
  r.LineCount  := ACount;
  r.LeftCount  := 0;
  Result.fData  := r;
  Result.fStartLine := ALine;

  Result.fFoldedBefore := InsertNode(r);
end;

function TSynTextFoldAVLTree.RemoveFoldForLine(ALine : Integer; IgnoreFirst : Boolean = False) : Integer;
var
  OldFold : TSynTextFoldAVLNode;
begin
  Result := ALine;
  OldFold := FindFoldForLine(ALine, true);
  if (not OldFold.IsInFold) // behind last node
  or (IgnoreFirst and (OldFold.StartLine > ALine))
  or ((not IgnoreFirst) and (OldFold.StartLine > ALine+1))
  then exit;
  RemoveFoldForNodeAtLine(OldFold, ALine, IgnoreFirst);
end;

function TSynTextFoldAVLTree.RemoveFoldForNodeAtLine(ANode : TSynTextFoldAVLNode;
  ALine : Integer; IgnoreFirst : Boolean = False) : Integer;
var
  NestedNode, MergeNode : TSynTextFoldAVLNodeData;
  NestedLine : LongInt;
begin
  // The cfCollapsed line is one line before the fold
  Result := ANode.StartLine-1;  // Return the cfcollapsed that was unfolded
  RemoveNode(ANode.fData);

  If ANode.fData.Nested <> nil then
  begin
    (*Todo: should we mark the tree as NO balancing needed ???*)
    TreeForNestedNode(ANode.fData, ANode.StartLine).RemoveFoldForLine(ALine, IgnoreFirst);

    // merge the remaining nested into current
    NestedNode := ANode.fData.Nested;
    if NestedNode <> nil
    then NestedLine := ANode.fStartLine + NestedNode.LineOffset;
    
    while NestedNode <> nil do begin
      while NestedNode.Left <> nil do begin
        NestedNode := NestedNode.Left;
        NestedLine := NestedLine + NestedNode.LineOffset;
      end;

      if NestedNode.Right <> nil then begin
        NestedNode := NestedNode.Right;
        NestedLine := NestedLine + NestedNode.LineOffset;
        continue;
      end;

      // leaf node
      // Anything that is still nested (MergeNode.Nested), will stay nested
      MergeNode := NestedNode;

      NestedLine := NestedLine - NestedNode.LineOffset;
      NestedNode := NestedNode.Parent;

      MergeNode.LineOffset := MergeNode.LineOffset + NestedLine;
      if NestedNode <> nil then begin
        NestedNode.ReplaceChild(MergeNode, nil);
        MergeNode.Parent := nil;
      end;
      MergeNode.LeftCount := 0;
      MergeNode.Balance   := 0;
      InsertNode(MergeNode);
    end;
    
  end;
  
  DisposeNode(ANode.fData);
end;

function TSynTextFoldAVLTree.InsertNode(ANode : TSynTextFoldAVLNodeData) : Integer;
var
  rStartLine, NestStartLine : Integer;
  rFoldedBefore, NestFoldedBefore : Integer;

  current, Nest : TSynTextFoldAVLNodeData;
  ALine, AEnd, ACount : Integer;
  
  procedure NestCurrentIntoNewBlock; inline;
  var
    diff, start2, before2 : Integer;
    p : TSynTextFoldAVLNodeData;
  begin
    // TODO => Check if LineCount needs to be extended (part overlap/nesting)
    //         include extension in below AdjustParentLeftCount
    current.AdjustParentLeftCount(ACount-current.LineCount); // -RecursiveFoldCount(current));
    rStartLine := rStartLine - current.LineOffset;  // rStarteLine is now current.Parent
    p := current.Parent;
    if p <> nil
    then p.ReplaceChild(current, ANode, -rStartLine)
    else SetRoot(ANode, -rStartLine);

    diff := current.LineOffset - ANode.LineOffset;
    ANode.Nested  := current;
    ANode.Balance := current.Balance;
    current.LineOffset := diff; // offset to ANode (via Nested)
    current.Parent := nil;
    current.Balance := 0;
    
    ANode.SetLeftChild(current.Left, diff, current.LeftCount);
    current.Left := nil;
    current.LeftCount := 0;
    ANode.SetRightChild(current.Right, diff);
    current.Right := nil;

    start2 := ALine; before2 := rFoldedBefore;
    p := ANode.Successor(start2, before2);
    while (p <> nil) and (start2 <= AEnd) do begin
      RemoveNode(p);
      p.LineOffset := start2- ALine;
      TreeForNestedNode(Anode, 0).InsertNode(p);

      start2 := ALine; before2 := rFoldedBefore;
      p := ANode.Successor(start2, before2);
    end;
  end;

  procedure NestNewBlockIntoCurrent; inline;
  begin
    // Check if current.LineCount needs extension
    ANode.LineOffset := ALine - rStartLine;
    if current.Nested <> nil
    then TreeForNestedNode(current, 0).InsertNode(ANode)
    else current.Nested := ANode;
    // TODO => Find More Nodes (only if acount extended), that need to be nested => May include LineCount/LeftCount Adjustment
    // TODO => BalanceAfterInsert (only if more nodes)
  end;

begin
  if fRoot = nil then begin
    SetRoot(ANode);
    Result := 0;
    exit;
  end;
  ALine := ANode.LineOffset;
  ACount := ANode.LineCount;
  AEnd := ALine + ACount - 1;
  current := fRoot;
  rStartLine := fRootOffset;
  rFoldedBefore := 0;
  Nest := nil;
  NestFoldedBefore := 0;
  NestStartLine := 0;

  while (current <> nil) do begin
    rStartLine := rStartLine + current.LineOffset;
    
    if ALine < rStartLine then begin
      (* *** New block goes to the left *** *)
      // remember possible nesting, continue scan for nesting with precessor
      if (AEnd >= rStartLine) then begin
        Nest := current;
        NestFoldedBefore := rFoldedBefore;
        NestStartLine := rStartLine;
      end;

      if current.Left <> nil Then begin
        current := current.Left;
        continue;
      end
      else if Nest = nil then begin // insert as Left - no nesting
        current.AdjustParentLeftCount(ACount);
        current.SetLeftChild(ANode, -rStartLine, ANode.LineCount);
        BalanceAfterInsert(ANode);
      end
      else begin // nest
        current := Nest;
        rStartLine := NestStartLine;
        rFoldedBefore := NestFoldedBefore;
        NestCurrentIntoNewBlock;
      end;
      break;
    end;

    rFoldedBefore := rFoldedBefore + current.LeftCount;
    if ALine = rStartLine then begin
      if ACount < current.LineCount then
        (* *** New Block will be nested in current *** *)
        NestNewBlockIntoCurrent
      else
      if ACount > current.LineCount then
        (* *** current will be nested in New Block *** *)
        NestCurrentIntoNewBlock
      else begin
        debugln(['Droping Foldnode / Already exists. Startline=', rStartLine,' LineCount=',ACount]);
        ANode.Free;
      end;
    end
    else begin
      If ALine <= rStartLine + current.LineCount - 1
      (* *** New Block will be nested in current *** *)
      then NestNewBlockIntoCurrent
      (* *** New block goes to the right *** *)
      else begin
        rFoldedBefore := rFoldedBefore + current.LineCount;
        if current.Right <> nil then begin
          current := current.Right;
          continue;
        end
        else if Nest=nil then Begin  // insert to the right - no nesting
          current.AdjustParentLeftCount(ACount);
          current.SetRightChild(ANode, -rStartLine);
          BalanceAfterInsert(ANode);
        end
        else begin // nest
          current := Nest;
          rStartLine := NestStartLine;
          rFoldedBefore := NestFoldedBefore;
          NestCurrentIntoNewBlock;
        end;

      end;
    end;
    
    break;
  end; // while

  Result := rFoldedBefore;
end;

procedure TSynTextFoldAVLTree.RemoveNode(ANode: TSynTextFoldAVLNodeData);
var OldParent, Precessor, PrecOldParent, PrecOldLeft,
  OldSubTree: TSynTextFoldAVLNodeData;
  OldBalance, PrecOffset, PrecLeftCount: integer;

begin
  if ((ANode.Left<>nil) and (ANode.Right<>nil)) then begin
    PrecOffset := 0;
//    PrecOffset := ANode.LineOffset;
    Precessor := ANode.Left;
    while (Precessor.Right<>nil) do begin
      PrecOffset := PrecOffset + Precessor.LineOffset;
      Precessor := Precessor.Right;
    end;
(*                            *OR*
 PnL              PnL
   \               \
   Precessor       Anode
   /               /
  *               *                     PnL             PnL
 /               /                        \               \
AnL   AnR       AnL      AnR        Precessor   AnR       AnL      AnR
  \   /           \      /                  \   /           \      /
   Anode          Precessor()               Anode          Precessor()
*)
    OldBalance := ANode.Balance;
    ANode.Balance     := Precessor.Balance;
    Precessor.Balance := OldBalance;

    // Successor.Left = nil
    PrecOldLeft   := Precessor.Left;
    PrecOldParent := Precessor.Parent;

    if (ANode.Parent<>nil)
    then ANode.Parent.ReplaceChild(ANode, Precessor, PrecOffset + ANode.LineOffset)
    else SetRoot(Precessor, PrecOffset + ANode.LineOffset);

    Precessor.SetRightChild(ANode.Right,
                           +ANode.LineOffset-Precessor.LineOffset);

    PrecLeftCount := Precessor.LeftCount;
    // ANode.Right will be empty  // ANode.Left will be Succesor.Left
    if (PrecOldParent = ANode) then begin
      // Precessor is left son of ANode
      // set ANode.LineOffset=0 => LineOffset for the Prec-Children is already correct;
      Precessor.SetLeftChild(ANode, -ANode.LineOffset,
                             PrecLeftCount + ANode.LineCount);
      ANode.SetLeftChild(PrecOldLeft, 0, PrecLeftCount);
    end else begin
      // at least one node between ANode and Precessor ==> Precessor = PrecOldParent.Right
      Precessor.SetLeftChild(ANode.Left, +ANode.LineOffset - Precessor.LineOffset,
                             ANode.LeftCount + ANode.LineCount - Precessor.LineCount);
      PrecOffset:=PrecOffset + ANode.LineOffset - Precessor.LineOffset;
      // Set Anode.LineOffset, so ANode movesinto position of Precessor;
      PrecOldParent.SetRightChild(ANode, - ANode.LineOffset -  PrecOffset);
      ANode.SetLeftChild(PrecOldLeft, 0, PrecLeftCount);
    end;

    ANode.Right := nil;
  end;

  if (ANode.Right<>nil) then begin
    OldSubTree := ANode.Right;
    ANode.Right := nil;
  end
  else if (ANode.Left<>nil) then begin
    OldSubTree := ANode.Left;
    ANode.Left := nil;
  end
  else OldSubTree := nil;

  OldParent := ANode.Parent;
  ANode.Parent := nil;
  ANode.Left := nil;
  ANode.Right := nil;
  ANode.Balance := 0;
  ANode.LeftCount := 0;
  // nested???

  if (OldParent<>nil) then begin      // Node has parent
    if OldParent.ReplaceChild(ANode, OldSubTree, ANode.LineOffset) = rplcLeft
    then begin
      Inc(OldParent.Balance);
      OldParent.AdjustLeftCount(-ANode.LineCount);
    end
    else begin
      Dec(OldParent.Balance);
      OldParent.AdjustParentLeftCount(-ANode.LineCount);
    end;
    BalanceAfterDelete(OldParent);
  end
  else SetRoot(OldSubTree, ANode.LineOffset);
end;


procedure TSynTextFoldAVLTree.BalanceAfterInsert(ANode : TSynTextFoldAVLNodeData);
var OldParent, OldParentParent, OldRight, OldRightLeft, OldRightRight, OldLeft,
   OldLeftLeft, OldLeftRight: TSynTextFoldAVLNodeData;
   tmp : integer;
begin
  OldParent := ANode.Parent;
  if (OldParent=nil) then exit;

  if (OldParent.Left=ANode) then begin
    (* *** Node is left son *** *)
    dec(OldParent.Balance);
    if (OldParent.Balance=0) then exit;
    if (OldParent.Balance=-1) then begin
      BalanceAfterInsert(OldParent);
      exit;
    end;

    // OldParent.Balance=-2
    if (ANode.Balance=-1) then begin
      (* ** single rotate ** *)
      (*  []
           \
           []  ORight                     []    ORight    []
            \   /                          \      \       /
            ANode(-1)  []        =>        []     OldParent(0)
               \       /                    \     /
               OldParent(-2)                 ANode(0)
      *)
      OldRight := ANode.Right;
      OldParentParent := OldParent.Parent;
      (* ANode moves into position of OldParent *)
      if (OldParentParent<>nil)
      then OldParentParent.ReplaceChild(OldParent, ANode, OldParent.LineOffset)
      else SetRoot(ANode, OldParent.LineOffset);

      (* OldParent moves under ANode, replacing Anode.Right, which moves under OldParent *)
      ANode.SetRightChild(OldParent, -ANode.LineOffset );
      OldParent.SetLeftChild(OldRight, -OldParent.LineOffset, OldParent.LeftCount - ANode.LineCount - ANode.LeftCount);

      ANode.Balance := 0;
      OldParent.Balance := 0;
      (* ** END single rotate ** *)
    end
    else begin  // ANode.Balance = +1
      (* ** double rotate ** *)
      OldParentParent := OldParent.Parent;
      OldRight := ANode.Right;
      OldRightLeft := OldRight.Left;
      OldRightRight := OldRight.Right;

      (* OldRight moves into position of OldParent *)
      if (OldParentParent<>nil)
      then OldParentParent.ReplaceChild(OldParent, OldRight, OldParent.LineOffset + ANode.LineOffset)
      else SetRoot(OldRight, OldParent.LineOffset + ANode.LineOffset);        // OldParent was root node. new root node
      
      OldRight.SetRightChild(OldParent, -OldRight.LineOffset);
      OldRight.SetLeftChild(ANode, OldParent.LineOffset, OldRight.LeftCount + ANode.LeftCount + ANode.LineCount);
      ANode.SetRightChild(OldRightLeft, -ANode.LineOffset);
      OldParent.SetLeftChild(OldRightRight, -OldParent.LineOffset, OldParent.LeftCount - OldRight.LeftCount - OldRight.LineCount);

      // balance
      if (OldRight.Balance<=0)
      then ANode.Balance := 0
      else ANode.Balance := -1;
      if (OldRight.Balance=-1)
      then OldParent.Balance := 1
      else OldParent.Balance := 0;
      OldRight.Balance := 0;
      (* ** END double rotate ** *)
    end;
    (* *** END Node is left son *** *)
  end
  else begin
    (* *** Node is right son *** *)
    Inc(OldParent.Balance);
    if (OldParent.Balance=0) then exit;
    if (OldParent.Balance=+1) then begin
      BalanceAfterInsert(OldParent);
      exit;
    end;

    // OldParent.Balance = +2
    if(ANode.Balance=+1) then begin
      (* ** single rotate ** *)
      OldLeft := ANode.Left;
      OldParentParent := OldParent.Parent;
      
      if (OldParentParent<>nil)
      then  OldParentParent.ReplaceChild(OldParent, ANode, OldParent.LineOffset)
      else SetRoot(ANode, OldParent.LineOffset);

      (* OldParent moves under ANode, replacing Anode.Left, which moves under OldParent *)
      ANode.SetLeftChild(OldParent, -ANode.LineOffset, ANode.LeftCount + OldParent.LineCount + OldParent.LeftCount);
      OldParent.SetRightChild(OldLeft, -OldParent.LineOffset);
      
      ANode.Balance := 0;
      OldParent.Balance := 0;
      (* ** END single rotate ** *)
    end
    else begin  // Node.Balance = -1
      (* ** double rotate ** *)
      OldLeft := ANode.Left;
      OldParentParent := OldParent.Parent;
      OldLeftLeft := OldLeft.Left;
      OldLeftRight := OldLeft.Right;

      (* OldLeft moves into position of OldParent *)
      if (OldParentParent<>nil)
      then  OldParentParent.ReplaceChild(OldParent, OldLeft, OldParent.LineOffset + ANode.LineOffset)
      else SetRoot(OldLeft, OldParent.LineOffset + ANode.LineOffset);

      tmp := OldLeft.LeftCount;
      OldLeft.SetLeftChild (OldParent, -OldLeft.LineOffset, tmp + OldParent.LeftCount + OldParent.LineCount);
      OldLeft.SetRightChild(ANode, OldParent.LineOffset);

      OldParent.SetRightChild(OldLeftLeft, -OldParent.LineOffset);
      ANode.SetLeftChild(OldLeftRight, -ANode.LineOffset, ANode.LeftCount - tmp - OldLeft.LineCount);

      // Balance
      if (OldLeft.Balance>=0)
      then ANode.Balance := 0
      else ANode.Balance := +1;
      if (OldLeft.Balance=+1)
      then OldParent.Balance := -1
      else OldParent.Balance := 0;
      OldLeft.Balance := 0;
      (* ** END double rotate ** *)
    end;
  end;
end;

procedure TSynTextFoldAVLTree.BalanceAfterDelete(ANode : TSynTextFoldAVLNodeData);
var OldParent, OldRight, OldRightLeft, OldLeft, OldLeftRight,
  OldRightLeftLeft, OldRightLeftRight, OldLeftRightLeft, OldLeftRightRight
  : TSynTextFoldAVLNodeData;
  tmp : integer;
begin
  if (ANode=nil) then exit;
  if ((ANode.Balance=+1) or (ANode.Balance=-1)) then exit;
  OldParent := ANode.Parent;
  if (ANode.Balance=0) then begin
    // Treeheight has decreased by one
    if (OldParent<>nil) then begin
      if(OldParent.Left=ANode) then
        Inc(OldParent.Balance)
      else
        Dec(OldParent.Balance);
      BalanceAfterDelete(OldParent);
    end;
    exit;
  end;

  if (ANode.Balance=-2) then begin
    // Node.Balance=-2
    // Node is overweighted to the left
    (*
          OLftRight
           /
        OLeft(<=0)
           \
             ANode(-2)
    *)
    OldLeft := ANode.Left;
    if (OldLeft.Balance<=0) then begin
      // single rotate left
      OldLeftRight := OldLeft.Right;
      
      if (OldParent<>nil)
      then OldParent.ReplaceChild(ANode, OldLeft, ANode.LineOffset)
      else SetRoot(OldLeft, ANode.LineOffset);

      OldLeft.SetRightChild(ANode, -OldLeft.LineOffset);
      ANode.SetLeftChild(OldLeftRight, -ANode.LineOffset, ANode.LeftCount - OldLeft.LineCount - OldLeft.LeftCount);

      ANode.Balance := (-1-OldLeft.Balance);
      Inc(OldLeft.Balance);

      BalanceAfterDelete(OldLeft);
    end else begin
      // OldLeft.Balance = 1
      // double rotate left left
      OldLeftRight := OldLeft.Right;
      OldLeftRightLeft := OldLeftRight.Left;
      OldLeftRightRight := OldLeftRight.Right;
      
(*
 OLR-Left   OLR-Right
      \     /
      OldLeftRight          OLR-Left    OLR-Right
       /                       /            \
   OldLeft                 OldLeft         ANode
      \                         \           /
     ANode                       OldLeftRight
       |                            |
     OldParent                   OldParent  (or root)
*)
      if (OldParent<>nil)
      then OldParent.ReplaceChild(ANode, OldLeftRight, ANode.LineOffset + OldLeft.LineOffset)
      else SetRoot(OldLeftRight, ANode.LineOffset + OldLeft.LineOffset);

      OldLeftRight.SetRightChild(ANode, -OldLeftRight.LineOffset);
      OldLeftRight.SetLeftChild(OldLeft, ANode.LineOffset, OldLeftRight.LeftCount + OldLeft.LeftCount + OldLeft.LineCount);
      OldLeft.SetRightChild(OldLeftRightLeft, -OldLeft.LineOffset);
      ANode.SetLeftChild(OldLeftRightRight,  -ANode.LineOffset, ANode.LeftCount - OldLeftRight.LeftCount - OldLeftRight.LineCount);

      if (OldLeftRight.Balance<=0)
      then OldLeft.Balance := 0
      else OldLeft.Balance := -1;
      if (OldLeftRight.Balance>=0)
      then ANode.Balance := 0
      else ANode.Balance := +1;
      OldLeftRight.Balance := 0;
      
      BalanceAfterDelete(OldLeftRight);
    end;
  end else begin
    // Node is overweighted to the right
    OldRight := ANode.Right;
    if (OldRight.Balance>=0) then begin
      // OldRight.Balance=={0 or -1}
      // single rotate right
      OldRightLeft := OldRight.Left;
      
      if (OldParent<>nil)
      then OldParent.ReplaceChild(ANode, OldRight, ANode.LineOffset)
      else SetRoot(OldRight, ANode.LineOffset);
      
      OldRight.SetLeftChild(ANode, -OldRight.LineOffset, OldRight.LeftCount + ANode.LineCount + ANode.LeftCount);
      ANode.SetRightChild(OldRightLeft, -ANode.LineOffset);

      ANode.Balance := (1-OldRight.Balance);
      Dec(OldRight.Balance);

      BalanceAfterDelete(OldRight);
    end else begin
      // OldRight.Balance=-1
      // double rotate right left
      OldRightLeft := OldRight.Left;
      OldRightLeftLeft := OldRightLeft.Left;
      OldRightLeftRight := OldRightLeft.Right;
      if (OldParent<>nil)
      then OldParent.ReplaceChild(ANode, OldRightLeft, ANode.LineOffset + OldRight.LineOffset)
      else SetRoot(OldRightLeft, ANode.LineOffset + OldRight.LineOffset);
      
      tmp := OldRightLeft.LeftCount;
      OldRightLeft.SetLeftChild(ANode, -OldRightLeft.LineOffset, tmp + ANode.LeftCount + ANode.LineCount);
      OldRightLeft.SetRightChild(OldRight, ANode.LineOffset);

      ANode.SetRightChild(OldRightLeftLeft, -ANode.LineOffset);
      OldRight.SetLeftChild(OldRightLeftRight, -OldRight.LineOffset, OldRight.LeftCount - tmp - OldRightLeft.LineCount);
        
      if (OldRightLeft.Balance<=0)
      then ANode.Balance := 0
      else ANode.Balance := -1;
      if (OldRightLeft.Balance>=0)
      then OldRight.Balance := 0
      else OldRight.Balance := +1;
      OldRightLeft.Balance := 0;
      BalanceAfterDelete(OldRightLeft);
    end;
  end;

end;

function TSynTextFoldAVLTree.TreeForNestedNode(ANode: TSynTextFoldAVLNodeData; aOffset : Integer) : TSynTextFoldAVLTree;
begin
  if fNestedNodesTree = nil then fNestedNodesTree := TSynTextFoldAVLTree.Create;
  Result := fNestedNodesTree;
  Result.fRoot := ANode.Nested;
  Result.fNestParent := ANode; // TODO: this is dangerous, this is never cleaned up, even if ANode is Destroyed
  Result.fRootOffset := aOffset;
end;

constructor TSynTextFoldAVLTree.Create;
begin
  fRoot := nil;
  fRootOffset := 0;
  fNestParent := nil;
  fNestedNodesTree := nil;
end;

{ TSynEditFoldedView }

constructor TSynEditFoldedView.Create(aTextBuffer : TSynEditStringList; aTextView : TSynEditStrings; ACaret: TSynEditCaret);
begin
  fCaret := ACaret;
  fCaret.AddChangeHandler(@DoCaretChanged);
  fLines := aTextView;
  fFoldTree := TSynTextFoldAVLTree.Create;
  fTopLine := 0;
  fLinesInWindow := -1;
  aTextBuffer.OnLineCountChanged := {$IFDEF FPC}@{$ENDIF}LineCountChanged;
end;

destructor TSynEditFoldedView.Destroy;
begin
  fCaret.RemoveChangeHandler(@DoCaretChanged);
  fFoldTree.Free;
  fTextIndexList := nil;
  fFoldTypeList := nil;
  inherited Destroy;
end;

procedure TSynEditFoldedView.LinesInsertedAtTextIndex(AStartIndex, ALineCount : Integer; SkipFixFolding : Boolean);
var top : Integer;
begin
  top := TopTextIndex;
  fFoldTree.AdjustForLinesInserted(AStartIndex+1, ALineCount);
  if AStartIndex < top then
    TopTextIndex := top + ALineCount;
  if not(SkipFixFolding) then FixFoldingAtTextIndex(AStartIndex, AStartIndex+ALineCount+1)
  else
  if AStartIndex < top + ALineCount then CalculateMaps;
end;

procedure TSynEditFoldedView.LinesInsertedAtViewPos(AStartPos, ALineCount : Integer; SkipFixFolding : Boolean);
begin
  LinesInsertedAtTextIndex(ViewPosToTextIndex(AStartPos), ALineCount, SkipFixFolding);
end;

procedure TSynEditFoldedView.LinesDeletedAtTextIndex(AStartIndex, ALineCount : Integer; SkipFixFolding : Boolean);
var top : Integer;
begin
  top := TopTextIndex;
  fFoldTree.AdjustForLinesDeleted(AStartIndex+1, ALineCount);
  if AStartIndex < top then
    TopTextIndex := top - ALineCount; {TODO: this may be to much, if topline is in the middle of the block}
  if not(SkipFixFolding) then FixFoldingAtTextIndex(AStartIndex, AStartIndex+ALineCount+1)
  else
  if AStartIndex < top - ALineCount then CalculateMaps;
end;

procedure TSynEditFoldedView.LinesDeletedAtViewPos(AStartPos, ALineCount : Integer; SkipFixFolding : Boolean);
begin
  LinesDeletedAtTextIndex(ViewPosToTextIndex(AStartPos), ALineCount, SkipFixFolding);
end;

function TSynEditFoldedView.TextIndexToViewPos(aTextIndex : Integer) : Integer;
begin
  result := aTextIndex + 1 - fFoldTree.FindFoldForLine(aTextIndex+1).FoldedBefore;
end;

function TSynEditFoldedView.TextIndexToScreenLine(aTextIndex : Integer) : Integer;
begin
  Result := TextIndexToViewPos(aTextIndex) - TopLine;
end;

function TSynEditFoldedView.ViewPosToTextIndex(aViewPos : Integer) : Integer;
begin
  if aViewPos > Count then
    aViewPos := Count;
  result := aViewPos - 1 + fFoldTree.FindFoldForFoldedLine(aViewPos).FoldedBefore;
end;

function TSynEditFoldedView.ScreenLineToTextIndex(aLine : Integer) : Integer;
begin
  Result := ViewPosToTextIndex(aLine + TopLine);
end;

function TSynEditFoldedView.TextIndexAddLines(aTextIndex, LineOffset : Integer) : Integer;
var
  node : TSynTextFoldAVLNode;
  cnt : integer;
begin
  node := fFoldTree.FindFoldForLine(aTextIndex+1, True);
  result := aTextIndex;
  if LineOffset < 0 then begin
    if node.IsInFold
    then node := node.Prev
    else node := fFoldTree.FindLastFold;
    while LineOffset < 0 do begin
      if Result <= 0 then exit(0);
      dec(Result);
      if node.IsInFold and (Result+1 < node.StartLine + node.LineCount) then begin
        Result := Result - node.LineCount;
        node := node.Prev;
      end;
      inc(LineOffset);
    end;
  end else begin
    cnt := fLines.Count;
    while LineOffset > 0 do begin
      if Result >= cnt then exit(cnt);
      inc(Result);
      if node.IsInFold and (Result+1 >= node.StartLine) then begin
        Result := Result + node.LineCount;
        if Result >= cnt then exit(cnt-node.LineCount-1);
        node := node.Next;
      end;
      dec(LineOffset);
    end;
  end;
end;

function TSynEditFoldedView.TextPosAddLines(aTextpos, LineOffset : Integer) : Integer;
begin
  Result := TextIndexAddLines(aTextpos-1, LineOffset)+1;
end;

procedure TSynEditFoldedView.Lock;
begin
  if fLockCount=0 then begin
    fNeedFixFrom := -1;
    fNeedFixMinEnd := -1;
    fNeedCaretCheck := false;
  end;;
  inc(fLockCount);
end;

procedure TSynEditFoldedView.UnLock;
begin
  dec(fLockCount);
  if (fLockCount=0) then begin
    if (fNeedFixFrom >= 0) then
      FixFolding(fNeedFixFrom, fNeedFixMinEnd, fFoldTree);
    if fNeedCaretCheck then
      DoCaretChanged(fCaret);
  end;
end;

(* Count *)
function TSynEditFoldedView.GetCount : integer;
begin
  Result := fLines.Count - fFoldTree.FindLastFold.FoldedBefore;
end;

function TSynEditFoldedView.GetDrawDivider(Index : integer) : Boolean;
begin
  result := (FoldType[Index] in [cfEnd])
    and (fLines.FoldEndLevel[TextIndex[index]] < CFDividerDrawLevel);
end;

(* Topline *)
procedure TSynEditFoldedView.SetTopLine(const ALine : integer);
begin
  if fTopLine = ALine then exit;
  fTopLine := ALine;
  CalculateMaps;
end;

function TSynEditFoldedView.GetTopTextIndex : integer;
begin
  Result := fTopLine + fFoldTree.FindFoldForFoldedLine(fTopLine).FoldedBefore - 1;
end;

procedure TSynEditFoldedView.SetTopTextIndex(const AIndex : integer);
begin
  TopLine := AIndex + 1 - fFoldTree.FindFoldForLine(AIndex+1).FoldedBefore;
end;

(* LinesInWindow*)
procedure TSynEditFoldedView.SetLinesInWindow(const AValue : integer);
begin
  if fLinesInWindow = AValue then exit;
  fLinesInWindow := AValue;
  SetLength(fTextIndexList, AValue + 1);
  SetLength(fFoldTypeList, AValue + 1);
  CalculateMaps;
end;

procedure TSynEditFoldedView.CalculateMaps;
var
  i, tpos, cnt  : Integer;
  node : TSynTextFoldAVLNode;
begin
  node := fFoldTree.FindFoldForFoldedLine(fTopLine, true);
  // ftopline is not a folded line
  // so node.FoldedBefore(next node after ftopl) does apply
  tpos  := fTopLine + node.FoldedBefore;
  cnt := fLines.Count;
  for i := 0 to fLinesInWindow do begin
    if tpos > cnt then begin
      fTextIndexList[i] := -1;
      fFoldTypeList[i] := cfNone;
    end else begin
      fTextIndexList[i] := tpos - 1; // TextIndex is 0-based

      if (node.IsInFold) and (tpos+1 = node.StartLine)
      then fFoldTypeList[i] := cfCollapsed
      else
      if fLines.FoldEndLevel[tpos-1] > fLines.FoldMinLevel[tpos-1]
      then fFoldTypeList[i] := cfExpanded
      else
      if (tpos > 1) and (fLines.FoldEndLevel[tpos-2] > fLines.FoldMinLevel[tpos-1])
      then fFoldTypeList[i] := cfEnd
      else
      if fLines.FoldEndLevel[tpos-1] > 0
      then fFoldTypeList[i] := cfContinue
      else fFoldTypeList[i] := cfNone;

      inc(tpos);
      if (node.IsInFold) and (tpos >= node.StartLine) then begin
        tpos := tpos + node.LineCount;
        node := node.Next;
      end;
    end;
  end;
end;

(* Lines *)
function TSynEditFoldedView.GetLines(index : Integer) : String;
begin
  if (index < 0) or (index > fLinesInWindow) then exit('');
  Result := fLines[fTextIndexList[index]];
end;

function TSynEditFoldedView.GetDisplayNumber(index : Integer) : Integer;
begin
  if (index < 0) or (index > fLinesInWindow)
  or (fTextIndexList[index] < 0) then exit(-1);
  Result := fTextIndexList[index]+1;
end;

function TSynEditFoldedView.GetRange(Index : integer) : TSynEditRange;
begin
  if (index < 0) or (index > fLinesInWindow) then exit(nil);
  Result := fLines.Ranges[fTextIndexList[index]];
end;

function TSynEditFoldedView.GetTextIndex(index : Integer) : Integer;
begin
  if (index < 0) or (index > fLinesInWindow) then exit(-1);
  Result := fTextIndexList[index];
end;

function TSynEditFoldedView.GetFoldType(index : Integer) : TSynEditCodeFoldType;
begin
  if (index < 0) or (index > fLinesInWindow) then exit(cfNone);
  Result := fFoldTypeList[index];
end;

function TSynEditFoldedView.IsFolded(index : integer) : Boolean;
begin
  Result := fFoldTree.FindFoldForLine(index+1).IsInFold;
end;

procedure TSynEditFoldedView.PutRange(Index : integer; const AValue : TSynEditRange);
begin
  if (index < 0) or (index > fLinesInWindow) then exit;
  fLines.Ranges[fTextIndexList[index]] := AValue;
end;

(* Folding *)
procedure TSynEditFoldedView.FoldAtLine(AStartLine : Integer);
begin
  FoldAtViewPos(AStartLine + fTopLine);
end;

procedure TSynEditFoldedView.FoldAtViewPos(AStartPos : Integer);
begin
  FoldAtTextIndex(AStartPos - 1 + fFoldTree.FindFoldForFoldedLine(AStartPos).FoldedBefore);
end;

function TSynEditFoldedView.LengthForFoldAtTextIndex(ALine : Integer) : Integer;
var
  i, lvl, cnt : Integer;
begin
  cnt := fLines.Count;
  // AStartLine is 1-based // FoldEndLevel is 0-based
  lvl := fLines.FoldEndLevel[ALine];
  i := ALine+1;
  while (i < cnt)  and (fLines.FoldMinLevel[i] >= lvl) do inc(i);
  // check if fold last line of block (not mixed "end begin")
  if (i < cnt) and (fLines.FoldEndLevel[i] <= fLines.FoldMinLevel[i]) then inc(i);
  Result := i-ALine-1;
end;

procedure TSynEditFoldedView.FoldAtTextIndex(AStartIndex : Integer);
var
  top : Integer;
begin
  top := TopTextIndex;
  // AStartIndex is 0-based
  // FoldTree is 1-based AND first line remains visble
  fFoldTree.InsertNewFold(AStartIndex+2, LengthForFoldAtTextIndex(AStartIndex));
  fTopLine := -1;  // make sure seting TopLineTextIndex, will do CalculateMaps;
  TopTextIndex := top;
  if Assigned(fOnFoldChanged) then
    fOnFoldChanged(AStartIndex);
end;

procedure TSynEditFoldedView.UnFoldAtLine(AStartLine : Integer; IgnoreFirst : Boolean = False);
begin
  UnFoldAtViewPos(AStartLine + fTopLine, IgnoreFirst);
end;

procedure TSynEditFoldedView.UnFoldAtViewPos(AStartPos : Integer; IgnoreFirst : Boolean = False);
begin
  UnFoldAtTextIndex(AStartPos - 1 + fFoldTree.FindFoldForFoldedLine(AStartPos).FoldedBefore, IgnoreFirst);
end;

procedure TSynEditFoldedView.UnFoldAtTextIndex(AStartIndex : Integer; IgnoreFirst : Boolean = False);
var
  top : Integer;
begin
  top := TopTextIndex;
  // Foldtree needs 1-based
  AStartIndex := fFoldTree.RemoveFoldForLine(AStartIndex+1, IgnoreFirst) - 1;
  fTopLine := -1;  // make sure seting TopLineTextIndex, will do CalculateMaps;
  TopTextIndex := top;
  if Assigned(fOnFoldChanged) then
    fOnFoldChanged(AStartIndex);
end;

procedure TSynEditFoldedView.UnfoldAll;
var
  top : Integer;
begin
  top := TopTextIndex;
  fFoldTree.Clear;
  fTopLine := -1;  // make sure seting TopLineTextIndex, will do CalculateMaps;
  TopTextIndex := top;
  if Assigned(fOnFoldChanged) then
    fOnFoldChanged(0);
end;

procedure TSynEditFoldedView.FoldAll(StartLevel : Integer = 0; IgnoreNested : Boolean = False);
var
  i, l, top: Integer;
begin
  top := TopTextIndex;
  fFoldTree.Clear;
  i := 0;
  while i < fLines.Count do begin
    if (fLines.FoldEndLevel[i] > fLines.FoldMinLevel[i])
    and (fLines.FoldEndLevel[i] > StartLevel) then begin
      l := LengthForFoldAtTextIndex(i);
      // i is 0-based
      // FoldTree is 1-based AND first line remains visble
      fFoldTree.InsertNewFold(i+2, l);
      if IgnoreNested then
        i := i + l;
    end;
    inc(i);
  end;
  fTopLine := -1;
  TopTextIndex := top;
  if Assigned(fOnFoldChanged) then
    fOnFoldChanged(0);
end;

function TSynEditFoldedView.FixFolding(AStart : Integer; AMinEnd : Integer; aFoldTree : TSynTextFoldAVLTree) : Boolean;
var
  line, cnt, a: Integer;
  LastStart, LastCount: Integer;
  node, tmpnode: TSynTextFoldAVLNode;
begin
  Result := false;
  if fLockCount > 0 then begin
    fNeedCaretCheck := true; // We may be here as a result of lines deleted/inserted
    if fNeedFixFrom < 0 then fNeedFixFrom := AStart
    else fNeedFixFrom := Min(fNeedFixFrom, AStart);
    fNeedFixMinEnd := Max(fNeedFixMinEnd, AMinEnd);
    exit;
  end;

  node := aFoldTree.FindFoldForLine(AStart, true);
  if not node.IsInFold then node:= aFoldTree.FindLastFold;
  if not node.IsInFold then Begin
    CalculateMaps;
    exit;
  end;
  If AMinEnd < node.StartLine then AMinEnd := node.StartLine;

  // LineCount is allowed to be -1
  while node.IsInFold and (node.StartLine + node.LineCount + 1 >= AStart) do begin
    tmpnode := node.Prev;
    if tmpnode.IsInFold then
      node := tmpnode
    else
      break; // first node
  end;

  LastStart := -1;
  LastCount := -2;
  while node.IsInFold do begin
    line := node.StartLine - 1; // the 1-based cfCollapsed (last visible) Line
    cnt := node.LineCount;
    if ((LastStart = line) and (LastCount = cnt)) or (cnt < 0) then begin
      // Same node as previous or fully deleted
      tmpnode := node.Prev;
      aFoldTree.RemoveFoldForNodeAtLine(node, -1); // Don't touch any nested node
      if tmpnode.IsInFold then node := tmpnode.Next
      else node := aFoldTree.FindFirstFold;
      continue;
    end;
    LastStart := line;
    LastCount := cnt;

    // look at the 0-based cfCollapsed (visible) Line
    if not(fLines.FoldEndLevel[line -1] > fLines.FoldMinLevel[line - 1]) then begin
      // the Fold-Begin of this node has gone
      tmpnode := node.Prev;
      aFoldTree.RemoveFoldForNodeAtLine(node, -1); // Don't touch any nested node
      if tmpnode.IsInFold then node := tmpnode.Next
      else node := aFoldTree.FindFirstFold;
      continue; // catch nested nodes (now unfolded)
    end;

    a:= LengthForFoldAtTextIndex(line-1);
    if not(cnt = a) then begin
      // the Fold-End of this node has gone or moved
      tmpnode := node.Prev;
      aFoldTree.RemoveFoldForNodeAtLine(node, -1); // Don't touch any nested node
      if tmpnode.IsInFold then node := tmpnode.Next
      else node := aFoldTree.FindFirstFold; // firstnode
      continue; // catch nested nodes (now unfolded)
    end;

    if (node.fData.Nested <> nil)
    and (FixFolding(line, line+1+node.LineCount, aFoldTree.TreeForNestedNode(node.fData.Nested, line+1)))
    then continue;

    // the node was ok
    if node.StartLine >= AMinEnd then break;

    node := node.Next;
  end;
  CalculateMaps;
end;

procedure TSynEditFoldedView.DoCaretChanged(Sender : TObject);
var i : Integer;
begin
  if fLockCount > 0 then begin
    fNeedCaretCheck := true;
    exit;
  end;
  i := TSynEditCaret(Sender).LinePos-1;
  if FoldedAtTextIndex[i] then
    UnFoldAtTextIndex(i, true);
end;

procedure TSynEditFoldedView.LineCountChanged(AIndex, ACount : Integer);
begin
  // no need for fix folding => synedit will be called, and scanlines will call fixfolding
  {TODO: a "need fix folding" flag => to ensure it will be called if synedit doesnt}
  if (fLockCount > 0) and (AIndex < max(fNeedFixFrom, fNeedFixMinEnd)) then begin
    // adapt the fixfold range. Could be done smarter, but it doesn't matter if the range gets bigger than needed.
    if (ACount < 0) and (AIndex < fNeedFixFrom) then inc(fNeedFixFrom, ACount);
    if (ACount > 0) and (AIndex < fNeedFixMinEnd) then inc(fNeedFixMinEnd, ACount);
  end;
  if ACount<0
  then LinesDeletedAtTextIndex(AIndex, -ACount, true)
  else LinesInsertedAtTextIndex(AIndex, ACount, true);
end;

procedure TSynEditFoldedView.FixFoldingAtTextIndex(AStartIndex: Integer; AMinEndLine : Integer);
begin
  FixFolding(AStartIndex + 1, AMinEndLine, fFoldTree);
end;

function TSynEditFoldedView.ExpandedLineForBlockAtLine(ALine : Integer) : Integer;
var
  i, l : Integer;
  node: TSynTextFoldAVLNode;
begin
  Result := -1;
  i := ALine-1;

  if (i>0) and (fLines.FoldMinLevel[i] < fLines.FoldEndLevel[i-1])then begin
    if fLines.FoldMinLevel[i] < fLines.FoldEndLevel[i] then begin
      // this is a combined "end begin" line
      node := fFoldTree.FindFoldForLine(ALine, true);
      if node.IsInFold and (node.StartLine = ALine +1) then
        dec(i);
      if i < 0 then exit;
    end else begin
      // this is a "end" line
      dec(i);
    end;
    l := fLines.FoldEndLevel[i];
  end else if fLines.FoldEndLevel[i] = 0 then
    exit
  else begin
    // check if current line is cfCollapsed
    node := fFoldTree.FindFoldForLine(ALine, true);
    if node.IsInFold and (node.StartLine = ALine +1) then
      dec(i);
    if i < 0 then exit;
    l := fLines.FoldEndLevel[i]
  end;

  while (i > 0) and (fLines.FoldMinLevel[i] >= l) do
    dec(i);
  if (fLines.FoldEndLevel[i] > 0) then // TODO, check for collapsed at index = 0
    Result := i + 1;
end;

function TSynEditFoldedView.CollapsedLineForFoldAtLine(ALine : Integer) : Integer;
var
  node: TSynTextFoldAVLNode;
begin
  Result := -1;
  node := fFoldTree.FindFoldForLine(ALine, false);
  if node.IsInFold then Result := node.StartLine-1;
end;

procedure TSynEditFoldedView.debug;
begin
  fFoldTree.debug;
end;


end.

