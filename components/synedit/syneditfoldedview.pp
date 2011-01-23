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
{$coperators on}
{$IFDEF CPUPOWERPC} {$INLINE OFF} {$ENDIF} (* Workaround for bug 12576 (fpc) see bugs.freepascal.org/view.php?id=12576 *)

{$IFDEF SynFoldDebug}
  {$DEFINE SynDebug}
  {$DEFINE SynFoldSaveDebug}
{$ENDIF}
{$IFDEF SynFoldSaveDebug}
  {$DEFINE SynDebug}
{$ENDIF}

interface

uses
  LCLProc, Graphics,
  Classes, SysUtils, SynEditTextBase, SynEditTypes, SynEditMiscClasses,
  SynEditMiscProcs, SynEditPointClasses,
  SynEditHighlighter, SynEditHighlighterFoldBase;

type

  { TSynTextFoldAVLNodeData }

  TSynTextFoldAVLNodeData = class(TSynSizedDifferentialAVLNode)
  protected
    function Left: TSynTextFoldAVLNodeData;
    function Parent: TSynTextFoldAVLNodeData;
    function Right: TSynTextFoldAVLNodeData;
  public    (* Position / Size *)
    (* FullCount:  Amount of lines in source for this fold only
                   (excluding overlaps) *)
    FullCount : Integer;
    (* LineOffset: Line-Number Offset to parent node
                   All line numbers are stored as offsets,
                   for faster updates if lines are inserted/deleted *)
    property LineOffset: Integer read FPositionOffset write FPositionOffset;
    (* LeftCount:  Lines folded in left tree.
                   Used to calculate how many lines are folded up to a specified line *)
    property LeftCount: Integer read FLeftSizeSum write FLeftSizeSum;
    (* MergedLineCount: Amount of lines folded away by this fold,
                        FullCount + Lines covered by overlaps *)
    property MergedLineCount: Integer read FSize write FSize;
  public
    (* Sub-Tree  *)
    Nested : TSynTextFoldAVLNodeData; (* Nested folds (folds within this fold) do not need to be part of the searchable tree
                             They will be restored, if the outer fold (this fold) is unfolded
                             Nested points to a standalone tree, the root node in the nested tree, does *not* point back to this node *)


    (* Source Info *)
    FoldIndex: Integer;    (* Index of fold in line; if a line has more than one fold starting *)
    VisibleLines: Integer; (* Visible Source lines, containing the "fold keyword"
                              0: Hiden block (the fold-keyword is inside the fold)
                              1: Normal fold (There is *1* visible line with the fold-keyword)
                            *)


    function RecursiveFoldCount : Integer; (* Amount of lines covered by this and all child nodes *)
    function Precessor : TSynTextFoldAVLNodeData; reintroduce;
    function Successor : TSynTextFoldAVLNodeData; reintroduce;
    function Precessor(var aStartPosition, aSizesBeforeSum : Integer) : TSynTextFoldAVLNodeData; reintroduce;
    function Successor(var aStartPosition, aSizesBeforeSum : Integer) : TSynTextFoldAVLNodeData; reintroduce;
  end;

  { TSynTextFoldAVLNode }

  TSynTextFoldAVLNode = object
  private
    function GetFoldIndex: Integer;
    function GetMergedLineCount : Integer;
    function GetFullCount : Integer;
    function GetSourceLine: integer;
    function GetSourceLineOffset: integer;
  protected
    fData : TSynTextFoldAVLNodeData; // nil if unfolded
    fStartLine : Integer;            // start of folded
    fFoldedBefore : Integer;
  public
    procedure Init(aData : TSynTextFoldAVLNodeData; aStartLine, aFoldedBefore: Integer);
    function IsInFold : Boolean;
    function Next : TSynTextFoldAVLNode;
    function Prev : TSynTextFoldAVLNode;

    property MergedLineCount: Integer read GetMergedLineCount; // Zero, if Not in a fold
    property FullCount: Integer read GetFullCount; // Zero, if Not in a fold
    property StartLine: Integer read fStartLine;   // 1st Line of Current Fold
    property FoldedBefore: Integer read fFoldedBefore;  // Count of Lines folded before Startline

    function IsHide: Boolean;
    property FoldIndex: Integer read GetFoldIndex;
    property SourceLine: integer read GetSourceLine;    // The SourceLine with the fold-keyword
    property SourceLineOffset: integer read GetSourceLineOffset;    // The SourceLine with the fold-keyword
  end;

  { TSynTextFoldAVLNodeNestedIterator:
    Iterates included nested nodes
    FoldedBefore is not valid in nested nodes
  }

  TSynTextFoldAVLNodeNestedIterator = class
  private
    FCurrentNode: TSynTextFoldAVLNode;
    FOuterNodes: Array of TSynTextFoldAVLNode;
  public
    constructor Create(ANode: TSynTextFoldAVLNode);
    destructor Destroy; override;
    function Next: TSynTextFoldAVLNode;
    function Prev: TSynTextFoldAVLNode;
    function EOF: Boolean;
    function BOF: Boolean;
    function IsInFold: Boolean;
    property Node: TSynTextFoldAVLNode read FCurrentNode;
  end;

  { TSynTextFoldAVLTree
    - Nodes in the tree cover the folded lines only.
      The (visible) cfCollapsed line at the start of a fold, is *not* part of a node.
    - In the public methods "ALine" indicates the first invisible/hidden line
    - TSynEditFoldedView uses this with 1-based lines (ToDo: make 0-based)
  }

  TSynTextFoldAVLTree = class(TSynSizedDifferentialAVLTree)
  protected
    fNestParent: TSynTextFoldAVLNodeData;
    fNestedNodesTree: TSynTextFoldAVLTree; // FlyWeight Tree used for any nested subtree.

    function NewNode : TSynTextFoldAVLNodeData; inline;
    Function RemoveFoldForNodeAtLine(ANode: TSynTextFoldAVLNode;
                                     ALine : Integer) : Integer; overload; // Line is for Nested Nodes

    // SetRoot, does not obbey fRootOffset => use SetRoot(node, -fRootOffset)
    procedure SetRoot(ANode : TSynSizedDifferentialAVLNode); overload; override;
    procedure SetRoot(ANode : TSynSizedDifferentialAVLNode; anAdjustChildLineOffset : Integer); overload; override;

    Function  InsertNode(ANode : TSynTextFoldAVLNodeData) : Integer; reintroduce; // returns FoldedBefore // ANode may not have children
    function TreeForNestedNode(ANode: TSynTextFoldAVLNodeData; aOffset : Integer) : TSynTextFoldAVLTree;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; override;

    (* Find Fold by Line in Real Text *)
    Function FindFoldForLine(ALine : Integer; FindNextNode : Boolean = False) : TSynTextFoldAVLNode;
    (* Find Fold by Line in Folded Text // always returns unfolded, unless next=true *)
    Function FindFoldForFoldedLine(ALine : Integer; FindNextNode: Boolean = False) : TSynTextFoldAVLNode;
    Function InsertNewFold(ALine, AColumn, ACount, AVisibleLines: Integer) : TSynTextFoldAVLNode;
    (* This will unfold the block which either contains tALine, or has Aline as its cgColapsed line
       If IgnoreFirst, the cfCollapsed will *not* unfold => Hint: IgnoreFirst = Make folded visible
       Returns the pos(1-based) of the cfCollapsed Line that was expanded; or ALine, if nothing was done
    *)
    Function RemoveFoldForLine(ALine : Integer; OnlyCol: Integer = -1) : Integer; overload;
    Procedure AdjustForLinesInserted(AStartLine, ALineCount : Integer);
    Procedure AdjustForLinesDeleted(AStartLine, ALineCount : Integer);
    Function FindLastFold : TSynTextFoldAVLNode;
    Function FindFirstFold : TSynTextFoldAVLNode;
    Function LastFoldedLine : integer; // The actual line; LastNode.StartLine + LastNode.LineCount - 1
    {$IFDEF SynDebug}
    procedure Debug; reintroduce;
    {$ENDIF}
  end;

  { TSynFoldNodeInfoHelper }

  TSynFoldNodeInfoHelper = class
    FCurInfo: TSynFoldNodeInfo;
    FActions: TSynFoldActions;
    FHighlighter: TSynCustomFoldHighlighter;
  protected
    procedure Invalidate;
  public
    constructor Create(AHighlighter: TSynCustomFoldHighlighter);

    function FirstOpen: TSynFoldNodeInfo;
    function Next: TSynFoldNodeInfo;
    function Prev: TSynFoldNodeInfo;
    function FindClose: TSynFoldNodeInfo;
    function GotoOpenPos(aLineIdx, aNodeIdx: integer): TSynFoldNodeInfo;
    function GotoOpenAtChar(aLineIdx, aXPos: integer): TSynFoldNodeInfo;
    function GotoNodeOpenPos(ANode : TSynTextFoldAVLNode): TSynFoldNodeInfo;
    function GotoNodeClosePos(ANode : TSynTextFoldAVLNode): TSynFoldNodeInfo;
    function IsAtNodeOpenPos(ANode : TSynTextFoldAVLNode): Boolean;
    function IsValid: Boolean;
    function Equals(AnInfo: TSynFoldNodeInfo): Boolean;
    function Equals(AHelper: TSynFoldNodeInfoHelper): Boolean;

    property Info: TSynFoldNodeInfo read FCurInfo write FCurInfo;
    property Actions: TSynFoldActions read FActions write FActions;
  end;

  TFoldChangedEvent = procedure(aLine: Integer) of object;

  TFoldViewNodeInfo = record
    HNode: TSynFoldNodeInfo;    // Highlighter Node
    FNode: TSynTextFoldAVLNode; // AvlFoldNode
    Text, Keyword: String;
    LineNum, ColIndex: Integer;
    OpenCount: Integer;
  end;

  TSynEditFoldLineCapability = (
    // Capabilities of Line
    cfFoldStart, cfHideStart,
    cfFoldBody,
    cfFoldEnd,
    // State indicators
    cfCollapsedFold,
    cfCollapsedHide,   // lines hidden, after this line
    // Special flags
    cfSingleLineHide,
    cfNone
  );
  TSynEditFoldLineCapabilities = set of TSynEditFoldLineCapability;
  TSynEditFoldType = (scftOpen, scftFold, scftHide, scftAll, scftInvalid);
  {$IFDEF SynFoldSaveDebug}
const
  SynEditFoldTypeNames: Array [TSynEditFoldType] of string =
    ('scftOpen', 'scftFold', 'scftHide', 'scftAll', 'scftInvalid');
type
  {$ENDIF}

  { TSynEditFoldProvider }

  TSynEditFoldProvider = class
  private
    FHighlighter: TSynCustomFoldHighlighter;
    function GetLineCapabilities(ALineIdx: Integer): TSynEditFoldLineCapabilities;
    procedure SetHighLighter(const AValue: TSynCustomFoldHighlighter);
  public
    function FoldOpenCount(ALineIdx: Integer; AType: Integer = 0): Integer;
    function FoldOpenInfo(ALineIdx, AFoldIdx: Integer; AType: Integer = 0): TSynFoldNodeInfo;
    //property FoldOpenInfo[ALineIdx, AColumnIdx: Integer]: Integer read GetFoldOpenInfo;
    //property FoldInfoCount[ALineIdx: Integer]: Integer read GetFoldInfoCount;
    //property FoldInfo[ALineIdx, AColumnIdx: Integer]: Integer read GetFoldInfo;
    property LineCapabilities[ALineIdx: Integer]: TSynEditFoldLineCapabilities
             read GetLineCapabilities;
    property HighLighter: TSynCustomFoldHighlighter read FHighlighter write SetHighLighter;
  end;

  { TSynTextFoldedView
      *Line      = Line (0-based) on Screen (except TopLine which should be TopViewPos)
      *ViewPos   = Line (1-based) in the array of viewable/visible lines
      *TextIndex = Line (0-based) in the complete text(folded and unfolded)
  }

  { TSynEditFoldedView }

  TSynEditFoldedView = class // TODO: class(TSynEditStringsLinked)
  private
    fCaret: TSynEditCaret;
    FFoldProvider: TSynEditFoldProvider;
    FHighLighter: TSynCustomFoldHighlighter;
    fLines : TSynEditStrings;
    fFoldTree : TSynTextFoldAVLTree;   // Folds are stored 1-based (the 1st line is 1)
    FMarkupInfoFoldedCode: TSynSelectedColor;
    fTopLine : Integer;
    fLinesInWindow : Integer;          // there may be an additional part visible line
    fTextIndexList : Array of integer;   (* Map each Screen line into a line in textbuffer *)
    fFoldTypeList : Array of TSynEditFoldLineCapabilities;
    fOnFoldChanged : TFoldChangedEvent;
    fLockCount : Integer;
    fNeedFixFrom, fNeedFixMinEnd : Integer;
    fNeedCaretCheck : Boolean;

    function GetCount : integer;
    function GetHighLighter: TSynCustomHighlighter;
    function GetLines(index : Integer) : String;
    function GetDisplayNumber(index : Integer) : Integer;
    function GetTextIndex(index : Integer) : Integer;
    function GetFoldType(index : Integer) : TSynEditFoldLineCapabilities;
    function IsFolded(index : integer) : Boolean;  // TextIndex
    procedure SetHighLighter(AValue: TSynCustomHighlighter);
    procedure SetTopLine(const ALine : integer);
    function  GetTopTextIndex : integer;
    procedure SetTopTextIndex(const AIndex : integer);
    procedure SetLinesInWindow(const AValue : integer);
  protected
    Procedure CalculateMaps;
    function  LengthForFoldAtTextIndex(ALine, AFoldIndex : Integer; HideLen: Boolean = False) : Integer;
    function  FoldNodeAtTextIndex(AStartIndex, ColIndex: Integer): TSynTextFoldAVLNode; (* Returns xth Fold at nth TextIndex (all lines in buffer) / 1-based *)
    function  FixFolding(AStart : Integer; AMinEnd : Integer; aFoldTree : TSynTextFoldAVLTree) : Boolean;

    procedure DoCaretChanged(Sender : TObject);
    Procedure LineCountChanged(Sender: TSynEditStrings; AIndex, ACount : Integer);
    Procedure LinesInsertedAtTextIndex(AStartIndex, ALineCount : Integer;
                                       SkipFixFolding : Boolean = False);
    Procedure LinesInsertedAtViewPos(AStartPos, ALineCount : Integer;
                                     SkipFixFolding : Boolean = False);
    Procedure LinesDeletedAtTextIndex(AStartIndex, ALineCount : Integer;
                                      SkipFixFolding : Boolean = False);
    Procedure LinesDeletedAtViewPos(AStartPos, ALineCount : Integer;
                                    SkipFixFolding : Boolean = False);
  public
    constructor Create(aTextView : TSynEditStrings; ACaret: TSynEditCaret);
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
    property DisplayNumber[index : Integer] : Integer   (* LineNumber for display in Gutter / result is 1-based *)
      read GetDisplayNumber;
    property FoldType[index : Integer] : TSynEditFoldLineCapabilities (* FoldIcon / State *)
      read GetFoldType;
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

    property MarkupInfoFoldedCode: TSynSelectedColor read FMarkupInfoFoldedCode;
  public
    procedure Lock;
    procedure UnLock;
    {$IFDEF SynDebug}
    procedure debug;
    {$ENDIF}
    (* Arguments for (Un)FoldAt* (Line, ViewPos, TextIndex):
       - ColumnIndex (0-based)
           Can be negative, to access the highest(-1) available, 2nd highest(-2) ...
           If negative, count points downward
       - ColCount = 0 => all
       - Skip => Do not count nodes that are already in the desired state
           (or can not archive the desired state: e.g. can not hide)
       - AVisibleLines: 0 = Hide / 1 = Fold
    *)
    procedure FoldAtLine(AStartLine: Integer; ColIndex : Integer = -1;          (* Folds at ScreenLine / 0-based *)
                         ColCount : Integer = 1; Skip: Boolean = False;
                         AVisibleLines: Integer = 1);
    procedure FoldAtViewPos(AStartPos: Integer; ColIndex : Integer = -1;        (* Folds at nth visible/unfolded Line / 1-based *)
                            ColCount : Integer = 1; Skip: Boolean = False;
                            AVisibleLines: Integer = 1);
    procedure FoldAtTextIndex(AStartIndex: Integer; ColIndex : Integer = -1;    (* Folds at nth TextIndex (all lines in buffer) / 1-based *)
                              ColCount : Integer = 1; Skip: Boolean = False;
                              AVisibleLines: Integer = 1);
    procedure UnFoldAtLine(AStartLine: Integer; ColIndex : Integer = -1;        (* UnFolds at ScreenLine / 0-based *)
                         ColCount : Integer = 0; Skip: Boolean = False;
                         AVisibleLines: Integer = 1);
    procedure UnFoldAtViewPos(AStartPos: Integer; ColIndex : Integer = -1;      (* UnFolds at nth visible/unfolded Line / 1-based *)
                         ColCount : Integer = 0; Skip: Boolean = False;
                         AVisibleLines: Integer = 1);
    procedure UnFoldAtTextIndex(AStartIndex: Integer; ColIndex : Integer = -1;  (* UnFolds at nth TextIndex (all lines in buffer) / 1-based *)
                         ColCount : Integer = 0; Skip: Boolean = False;
                         AVisibleLines: Integer = 1);
    procedure UnFoldAtTextIndexCollapsed(AStartIndex: Integer);   (* UnFolds only if Index is in the fold, ignores cfcollapsed line, if unfolded / 1-based *)

    function LogicalPosToNodeIndex(AStartIndex: Integer; LogX: Integer;         (* Returns the index of the node, at the logical char pos *)
                                   Previous: Boolean = False): Integer;

    procedure CollapseDefaultFolds;
    // Load/Save folds to string
    // AStartIndex, AEndIndex: (0 based) First/last line (EndIndex = -1 = open end)
    // AStartCol, AEndCol: (1 based) Logical text pos in Line. (AEndCol = -1 = full line)
    function  GetFoldDescription(AStartIndex, AStartCol, AEndIndex,
                                 AEndCol: Integer; AsText: Boolean = False;
                                 Extended: Boolean = False) :String;
    procedure ApplyFoldDescription(AStartIndex, AStartCol, AEndIndex,
                                   AEndCol: Integer; FoldDesc: PChar;
                                   FoldDescLen: Integer; IsText: Boolean = False);

    procedure UnfoldAll;
    procedure FoldAll(StartLevel : Integer = 0; IgnoreNested : Boolean = False);
    procedure FixFoldingAtTextIndex(AStartIndex: Integer; AMinEndLine: Integer = 0); // Real/All lines
  public
    function OpenFoldCount(aStartIndex: Integer): Integer;
    function OpenFoldInfo(aStartIndex, ColIndex: Integer): TFoldViewNodeInfo;

  public
    // Find the visible first line of the fold at ALine. Returns -1 if Aline is not folded
    function CollapsedLineForFoldAtLine(ALine : Integer) : Integer;
    function ExpandedLineForBlockAtLine(ALine : Integer; HalfExpanded: Boolean = True) : Integer;

    function GetPhysicalCharWidths(Index: Integer): TPhysicalCharWidths;

    function  IsFoldedAtTextIndex(AStartIndex, ColIndex: Integer): Boolean;      (* Checks xth Fold at nth TextIndex (all lines in buffer) / 1-based *)
    property FoldedAtTextIndex [index : integer] : Boolean read IsFolded;

    property OnFoldChanged: TFoldChangedEvent  (* reports 1-based line *) {TODO: synedit expects 0 based }
      read fOnFoldChanged write fOnFoldChanged;
    property HighLighter: TSynCustomHighlighter read GetHighLighter
                                                write SetHighLighter;
    property FoldProvider: TSynEditFoldProvider read FFoldProvider;
  end;
  
implementation

type
  TFoldExportEntry = Record
    // Lines and Pos (o 1st line) are relative to Scan-Start
    Line, LogX, LogX2: Integer;     // StartLine and Pos
    ELine, ELogX, ELogX2: Integer;  // EndLine and pos
    FType: Integer;                 // e.g ord(cfbtBeginEnd)
    LinesFolded: Integer;          // Lines Folded according to AVL-Node
  end;

  { TSynEditFoldExportStream }

  TSynEditFoldExportStream = class
  private
    FData: String;
    FLen, FPos: Integer;
    FMem: PChar;
    function  GetLen: Integer;
    procedure SetLen(const AValue: Integer);
    function  GetMem: PChar;
    procedure SetMem(const AValue: PChar);
    function  GetText: String;
    procedure SetText(const AValue: String);
  protected
    function GrowData(AppendSize: Integer): PChar;
    function EncodeIntEx(Anum: Integer): String;  // base 43, with leading continue bit
    function EncodeIntEx2(Anum: Integer): String; // for numbers expected below 467; specially 0..80
    function InternalReadNum(var APos: Integer): Integer;
    function InternalReadNumEx(var APos: Integer): Integer;
  public
    constructor Create;
    procedure Compress;
    procedure Decompress;

    procedure AddChecksum;
    function  VerifyChecksum: Boolean;

    // see notes for Compression
    Procedure AppendMem(AMem: Pointer; ALen: Integer);
    Procedure AppendString(ATxt: String);
    Procedure AppendNum(ANum: Integer);
    Procedure AppendNumEx(ANum: Integer);

    Procedure Reset;
    Procedure Clear;
    function ReadMem(AMem: Pointer; ALen: Integer): Boolean;
    function PeakString(ALen: Integer): String;
    function FindChar(AChar: Char): Integer; // 0 based
    function ReadString(ALen: Integer): String;
    function ReadNum: Integer;
    function ReadNumEx: Integer;
    function EOF: Boolean;

    property Text: String read GetText write SetText;
    property Mem: PChar read GetMem write SetMem;
    property Len: Integer read GetLen write SetLen;
    property Pos: Integer read FPos;
  end;

  TSynEditFoldExportCoderEntry = record
    aX, aY, aLen: Integer;
    aFoldType: TSynEditFoldType;
  end;
  TSynEditFoldExportCoderStates =
    (sfecAtBegin, sfecAtPoint, sfecInRepeatCount, sfecInvalid, sfecAtEOF);
  {$IFDEF SynFoldSaveDebug}
const
  SynEditFoldExportCoderStates: Array [TSynEditFoldExportCoderStates] of String =
    ('sfecAtBegin', 'sfecAtPoint', 'sfecInRepeatCount', 'sfecInvalid', 'sfecAtEOF');
type
  {$ENDIF}

  { TSynEditFoldExportCoder }

  TSynEditFoldExportCoder = class
  private
    FExportStream: TSynEditFoldExportStream;
    FFoldType: Pointer;

    FReadY, FReadLastY, FReadX, FReadSumLen, FReadCount: Integer;
    FReadType: TSynEditFoldType;
    FReadDefaultType: TSynEditFoldType;
    FReadState: TSynEditFoldExportCoderStates;

    FWriteCache: Array of TSynEditFoldExportCoderEntry;
    FWriteCacheLen: Integer;
    FWriteCacheTypes: set of TSynEditFoldType;
    function GetReadIsValid: Boolean;
  public
    constructor Create(AFoldType: Pointer);
    constructor Create(AStream: TSynEditFoldExportStream);
    destructor Destroy; override;

    procedure AddNode(aX, aY, aLen: Integer; aFoldType: TSynEditFoldType);
    procedure Finish;

    function ReadNode(aX, aY: Integer; aLen: Integer): TSynEditFoldType;
    function EOF: Boolean;
    procedure Reset;
    property ReadIsValid: Boolean read GetReadIsValid;

    property FoldType: Pointer read FFoldType;
    property Stream: TSynEditFoldExportStream read FExportStream;
  end;

const
  // use only xml encode-able ascii
  // do not use [ or ], they are reserved for compression
  // space can be used a special indicator
  NumEncode86Chars: string[86] = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-+;:,.@=*/\!?$%()''^{}~_#';

  NumEncodeAsOneMax = 80;                        // Maximum Value to encode as 1 char
  NumEncodeAsTwoMax = 81 + 4*86 + 43;            // =  467; Maximum Value to encode as 2 char
  NumEncodeAsThreeMax = 81 + 4*86 + 43 * 43 - 1; // = 2273  Maximum Value to encode as 3 char


  SEQMaxNodeCount     = 75;  // New Full entry at least every 75 folds
  SEQMaxLineDistEach  = 500;  //  New Full entry, if folds startlines are more than 500 appart
  SEQMaxLineDistTotal = 2500; // New Full entry at least every 2500; check position

var
  NumEncode86Values: Array [Char] of integer;

procedure InitNumEncodeValues;
var
  i: integer;
  c : Char;
begin
  for c := low(Char) to high(Char) do begin
    NumEncode86Values[c] := -1;
  end;
  for i := 1 to length(NumEncode86Chars) do
    NumEncode86Values[NumEncode86Chars[i]] := i - 1;
end;

{ TSynEditFoldExportStream }

constructor TSynEditFoldExportStream.Create;
begin
  inherited;
  FPos := 0;
  FLen := 0;
  FMem := nil;
end;


function TSynEditFoldExportStream.GetLen: Integer;
begin
  Result := FLen;
end;

procedure TSynEditFoldExportStream.SetLen(const AValue: Integer);
begin
  FPos := 0;
  FLen:= AValue;
end;

function TSynEditFoldExportStream.GetMem: PChar;
begin
  if FData <> '' then
    Result := @FData[1]
  else
    Result := FMem;
end;

procedure TSynEditFoldExportStream.SetMem(const AValue: PChar);
begin
  FData := '';
  FMem := AValue;
  FPos := 0;
end;

function TSynEditFoldExportStream.GetText: String;
begin
  // only valid for FData
  SetLength(FData, FLen);
  Result := FData;
end;

procedure TSynEditFoldExportStream.SetText(const AValue: String);
begin
  FData := AValue;
  FMem := nil;
  FPos := 0;
end;

function TSynEditFoldExportStream.GrowData(AppendSize: Integer): PChar;
var
  l: integer;
begin
  l := length(FData);
  if l < FLen + AppendSize then
    SetLength(FData, l + AppendSize + Max((l+AppendSize) div 4, 1024));
  Result := @FData[FLen + 1];
  inc(FLen, AppendSize);
end;

function TSynEditFoldExportStream.EncodeIntEx(Anum: Integer): String;
var
  n: integer;
begin
  //    0 -   42 => 1 byte
  //   43 - 1848 => 2 byte
  // 1849 - .... => 3 and more
  Result := '';
  if ANum = 0 then Result := NumEncode86Chars[1];
  n := 0;
  while ANum > 0 do begin
    Result := NumEncode86Chars[1 + (Anum mod 43) + n] + Result;
    ANum := ANum div 43;
    n := 43;
  end;
end;

function TSynEditFoldExportStream.EncodeIntEx2(Anum: Integer): String;
var
  n: Integer;
begin
  //   0 -   80 => 1 char
  //  81 -  424 => 2 char   (80 + 4 * 86)
  // 425 -  467 => 2 char (len(EncodeIntEx) = 1)
  // 468 - 2272 => 3 and more char
  //2273 - .... => 4 and more char
  Result := '';
  if Anum <= 80 then
    Result := NumEncode86Chars[1 + Anum]
  else
  begin
    n := (Anum-81) div 86;
    if n <= 3 then
      Result := NumEncode86Chars[1 + 81 + n] + NumEncode86Chars[1 + (Anum - 81) mod 86]
    else
      Result := NumEncode86Chars[1 + 85] + EncodeIntEx(Anum - 81 - 4*86);
  end;
end;

function TSynEditFoldExportStream.InternalReadNum(var APos: Integer): Integer;
var
  n: Integer;
begin
  Result := 0;
  while True do begin
    if FPos >= FLen then exit(-1);
    n := NumEncode86Values[(FMem + APos)^];
    if n < 43 then break;
    dec(n, 43);
    Result := Result * 43 + n;
    inc(APos);
  end;
  Result := Result * 43 + n;
  inc(APos);
end;

function TSynEditFoldExportStream.InternalReadNumEx(var APos: Integer): Integer;
begin
  if FPos >= FLen then exit(-1);
  Result := NumEncode86Values[(FMem + APos)^];
  inc(APos);
  if Result <= 80 then
    exit;
  if FPos >= FLen then exit(-1);
  if Result < 85 then begin
    Result := 81 + (Result-81)*86 +  NumEncode86Values[(FMem + APos)^];
    inc(APos);
    exit;
  end;
  Result := 81 + 4*86 + InternalReadNum(APos);
end;

procedure TSynEditFoldExportStream.Compress;
(* Known Sequences: XX = Enc64Num (copy sequence from XX chars before)
                    NN = ENc22 Num / n = enc22digit (copy n bytes)
     [XXn     (up to 21 bytes, from up to 64*64 back)
     [NNXX[   (more then 21 bytes, from up to 64*64 back)
     ]X       (3 bytes from max 64 back)
     ]nx      ( reocurring space,x times, ever n pos)
*)
const
  max_single_len = 22 - 1;
var
  CurPos, EndPos, SearchPos: Integer;
  FndLen, FndPos, FndPos2: Integer;
  BestLen, BestPos, BestPos2: Integer;
  s: string;
begin
  AppendString(#0);
  dec(FLen);

  EndPos := FLen;
  CurPos := FLen - 3;
  while CurPos >= 4 do begin
    SearchPos := CurPos - 3;
    BestLen := 0;
    while (SearchPos >= 1) do begin
      if CompareMem(@FData[CurPos], @FData[SearchPos], 3) then begin
        FndLen := 3;
        FndPos := SearchPos;
        FndPos2 := CurPos;
        while (SearchPos + FndLen < FndPos2) and
              (FndPos2 + FndLen < EndPos - 1) and
              (FData[SearchPos + FndLen] = FData[CurPos + FndLen])
        do
          inc(FndLen);
        while (FndPos > 1) and (FndPos + FndLen < FndPos2) and
              (FData[FndPos - 1] = FData[FndPos2 - 1]) do
        begin
          dec(FndPos);
          dec(FndPos2);
          inc(FndLen);
        end;

        if (FndLen > BestLen) and
           ((FndPos2 - FndPos <= NumEncodeAsOneMax) or (FndLen >= 4)) and
           ((FndPos2 - FndPos <= NumEncodeAsTwoMax) or (FndLen >= 5)) and
           ((FndPos2 - FndPos <= NumEncodeAsThreeMax) or (FndLen >= 6))
        then begin
          BestLen := FndLen;
          BestPos := FndPos;
          BestPos2 := FndPos2;
        end;
      end;
      dec(SearchPos);
    end;

    s := '';
    if (BestLen >= 4) then
      s := '[' + EncodeIntEx2(BestPos2 - BestPos) + EncodeIntEx2(BestLen)
    else
    if (BestLen = 3) and (BestPos2 - BestPos <= NumEncodeAsOneMax) then
      s := ']' + EncodeIntEx2(BestPos2 - BestPos);
    if (s<>'') and (length(s) < BestLen) then begin
      System.Move(s[1], FData[BestPos2], length(s));
      System.Move(FData[BestPos2 + BestLen], FData[BestPos2 + length(s)], FLen + 1 - (BestPos2 + BestLen));
      dec(FLen, BestLen - length(s));
      EndPos := BestPos;
      CurPos := BestPos2 - 3;
    end
    else
      dec(CurPos);
  end;
end;

procedure TSynEditFoldExportStream.Decompress;
var
  i, j, n: Integer;
  p, p2: PChar;
  NewLen: Integer;
begin
  // curently assumes that FMem points NOT at FData
  if FLen = 0 then
    exit;
  NewLen := 0;
  i := 0;
  while i < Flen do begin
    case (FMem+i)^ of
      '[' :
        begin
          inc(i);
          j := InternalReadNumEx(i);
          n := InternalReadNumEx(i);
          if (j < n) or (j > NewLen) then raise ESynEditError.Create('fold format error');
          inc(NewLen, n);
        end;
      ']' :
        begin
          inc(i, 1);
          j := InternalReadNumEx(i);
          if (j < 3) or (j > NewLen) then raise ESynEditError.Create('fold format error');
          inc(NewLen, 3);
        end;
      else
        begin
          inc(NewLen);
          inc(i);
        end;
    end;
  end;
  SetLength(FData, NewLen);

  i := 0;
  p := PChar(FData);
  while i < Flen do begin
    case (FMem+i)^ of
      '[' :
        begin
          inc(i);
          j := InternalReadNumEx(i);
          n := InternalReadNumEx(i);
          p2 := p;
          while n > 0 do begin
            p^ := (p2 - j)^;
            inc(p);
            dec(j);
            dec(n);
          end;
        end;
      ']' :
        begin
          inc(i);
          j := InternalReadNumEx(i);
          p2 := p;
          for n := 0 to 2 do begin
            p^ := (p2 - j)^;
            inc(p);
            dec(j);
          end;
        end;
      else
        begin
          p^ := (FMem + i)^;
          inc(p);
          inc(i);
        end;
    end;
  end;

  FLen := NewLen;
  FMem := PChar(FData);
  FPos := 0;
end;

procedure TSynEditFoldExportStream.AddChecksum;
var
  i, c: Integer;
begin
  if FLen = 0 then
    exit;
  if FMem = nil then
    FMem := @FData[1];
  c := 0;
  for i := 0 to FLen - 1 do
    c := c xor (ord((FMem + i)^) * (i+1));
  c := (c mod 256) xor ((c div 256) mod 256) xor ((c div 65536) mod 256);
  AppendString(NumEncode86Chars[1 + (c mod 86)]);
end;

function TSynEditFoldExportStream.VerifyChecksum: Boolean;
var
  i, c: Integer;
begin
  if FLen = 0 then
    exit(True);
  if FMem = nil then
    FMem := @FData[1];
  dec(Flen);
  c := 0;
  for i := 0 to FLen - 1 do
    c := c xor (ord((FMem + i)^) * (i+1));
  c := (c mod 256) xor ((c div 256) mod 256) xor ((c div 65536) mod 256);
  Result := (FMem + FLen)^ = NumEncode86Chars[1 + (c mod 86)];
end;

procedure TSynEditFoldExportStream.AppendMem(AMem: Pointer; ALen: Integer);
begin
  {$IFDEF SynFoldSaveDebug}
  DebugLn(['TSynEditFoldExportStream.AppendMem len=', ALen]);
  {$ENDIF}
  FMem := nil;
  if ALen > 0 then
    System.Move(AMem^, GrowData(ALen)^, ALen);
end;

procedure TSynEditFoldExportStream.AppendString(ATxt: String);
var
  l: Integer;
begin
  {$IFDEF SynFoldSaveDebug}
  DebugLn(['TSynEditFoldExportStream.AppendString ', ATxt]);
  {$ENDIF}
  FMem := nil;
  l := length(ATxt);
  if l > 0 then
    System.Move(ATxt[1], GrowData(l)^, l);
end;

procedure TSynEditFoldExportStream.AppendNum(ANum: Integer);
begin
  {$IFDEF SynFoldSaveDebug}
  DebugLn(['TSynEditFoldExportStream.AppendNum ', ANum]);
  {$ENDIF}
  FMem := nil;
  AppendString(EncodeIntEx(ANum));
end;

procedure TSynEditFoldExportStream.AppendNumEx(ANum: Integer);
begin
  {$IFDEF SynFoldSaveDebug}
  DebugLn(['TSynEditFoldExportStream.AppendNumEx ', ANum]);
  {$ENDIF}
  FMem := nil;
  AppendString(EncodeIntEx2(ANum));
end;

procedure TSynEditFoldExportStream.Reset;
begin
  FPos := 0;
  if (FMem = nil) and (FData <> '') then
    FMem := @FData[1];
end;

procedure TSynEditFoldExportStream.Clear;
begin
  FLen := 0;
  FMem := nil;
  FPos := 0;
  SetLength(FData, 0);
end;

function TSynEditFoldExportStream.ReadMem(AMem: Pointer; ALen: Integer): Boolean;
begin
  Result := FPos+ ALen <= FLen;
  If not Result then
    exit;
  System.Move((FMem + FPos)^, AMem^, ALen);
  inc(FPos, ALen);
end;

function TSynEditFoldExportStream.PeakString(ALen: Integer): String;
begin
  If not(FPos+ ALen <= FLen) then
    exit('');
  SetLength(Result, ALen);
  if ALen > 0 then
    System.Move((FMem + FPos)^, Result[1], ALen);
end;

function TSynEditFoldExportStream.FindChar(AChar: Char): Integer;
begin
  Result := 0;
  While (FPos + Result < FLen) and ((FMem + FPos + Result)^ <> AChar) do
    inc(Result);
  if FPos + Result = FLen then
    Result := -1;
end;

function TSynEditFoldExportStream.ReadString(ALen: Integer): String;
begin
  If not(FPos+ ALen <= FLen) then
    exit('');
  SetLength(Result, ALen);
  if ALen > 0 then
    System.Move((FMem + FPos)^, Result[1], ALen);
  inc(FPos, ALen);
end;

function TSynEditFoldExportStream.ReadNum: Integer;
begin
  Result := InternalReadNum(FPos);
  {$IFDEF SynFoldSaveDebug}
  DebugLn(['TSynEditFoldExportStream.ReadNum ', Result]);
  {$ENDIF}
end;

function TSynEditFoldExportStream.ReadNumEx: Integer;
begin
  Result := InternalReadNumEx(FPos);
  {$IFDEF SynFoldSaveDebug}
  DebugLn(['TSynEditFoldExportStream.ReadNumEx ', Result]);
  {$ENDIF}
end;

function TSynEditFoldExportStream.EOF: Boolean;
begin
  Result := FPos >= FLen;
end;

{ TSynEditFoldExportCoder }

function TSynEditFoldExportCoder.GetReadIsValid: Boolean;
begin
  Result := FReadState <> sfecInvalid;
end;

constructor TSynEditFoldExportCoder.Create(AFoldType: Pointer);
begin
  inherited Create;
  FExportStream := TSynEditFoldExportStream.Create;
  FExportStream.AppendString(' T');                // Type Marker
  FExportStream.AppendNum(PtrUInt(AFoldType));
  FFoldType := AFoldType;
  FWriteCacheLen := 0;
  FWriteCache := nil;
  FWriteCacheTypes := [];
end;

constructor TSynEditFoldExportCoder.Create(AStream: TSynEditFoldExportStream);
var
  i: Integer;
begin
  inherited Create;
  FExportStream := TSynEditFoldExportStream.Create;
  FReadState := sfecInvalid;
  if AStream.PeakString(2) <> ' T' then exit;

  AStream.ReadString(2);

  FFoldType := Pointer(PtrUInt(AStream.ReadNum));
  while(true) do begin
    i := AStream.FindChar(' ');
    if i < 0 then i := AStream.Len - AStream.Pos;
    FExportStream.AppendString(AStream.ReadString(i));
    if AStream.EOF or (AStream.PeakString(2) = ' T') then
      break;
    FExportStream.AppendString(AStream.ReadString(2));
  end;
  {$IFDEF SynFoldSaveDebug}
  DebugLn(['TSynEditFoldExportCoder.Create(<from input-stream> FType=', dbgs(FFoldType), '  txtLen=', FExportStream.Len, ' Txt="', FExportStream.Text, '"']);
  {$ENDIF}
  Reset;
end;

destructor TSynEditFoldExportCoder.Destroy;
begin
  FreeAndNil(FExportStream);
  Inherited;
end;

procedure TSynEditFoldExportCoder.AddNode(aX, aY, aLen: Integer; aFoldType: TSynEditFoldType);
(* Format:  [Num] <NumEX>
  ' T' [type] [yo] <X> <len> ( <c>* ' p' [sum]  [yo] <X> <len> )* <c>* (' P' [sum] [yo] <X> <len>)?

  //////////////////////////
  // Version info
  V1 - no entries
  V2  July 2010  0.9.29
     - added fold-hide <HideInfo>

  //////////////////////////

  <Stream> = { <TypeStream> };

  <TypeStream> = " T" <TypeId>  <TypeData>;        [* Stores all folds for the given type (eg cfbtBeginEnd) *]

  <TypeId>   = ord(cfbtBeginEnd) or similar
  <TypeData> = [<HideInfo>],
               <NodePos>,
               [ [<FoldList>,]  [{ <FoldListEndCont>, <NodePos>, [<FoldList>] }] ],
               [ <FoldListEnd> ];


  <FoldList> = [{ <ConsecutiveFoldedCount>,  <ConsecutiveUnFoldedCount> }],
               <ConsecutiveFoldedCount>,
               ;
  [* NodePos: is the  position of a folded node (of the type matching the current stream)
     ConsecutiveFoldedCount: more folded nodes of the same type, without any
                             unfolded node (of this type) inbetween.
     ConsecutiveUnFoldedCount: amount of unfolded nodes (of this type) before the next folded node.
  *]

  <NodePos> =  <YOffset> <XPos> <len>;
  <YOffset>                  = <Number>
  <XPos>                     = <ExNumber>
  <len>                      = <ExNumber>
  <ConsecutiveFoldedCount>   = <ExNumber>
  <ConsecutiveUnFoldedCount> = <ExNumber>

  <FoldListEndCont> = ' p', <SumFoldedLines>;
    [* FoldListEndCont is mandotory, if another block of <NodePos>, <FoldList> is coming *]
  <FoldListEnd>     = ' P'  <SumFoldedLines>, <EndY>, <EndX>;
    [* FoldListEnd is optional. It is expected if the previous <FoldList> has more than 10 folded lines*]

  <SumFoldedLines> = <Number>
  [* The sum of all lines folded by folds in <ConsecutiveFoldedCount>.
     Not including the fold in <NodePos>, which has it's own len.
  *]

  <Number> = bigger numbers
  <ExNumber> = for numbers expected below 467; specially 0..80

  <HideInfo> = ' h' | ' H'
    not present: all folds, no hides (default)
    ' H': all hides, no folds
    ' h': mixed hides and folds
      For mixed lists the following applies:
      - XPos is doubled; bit 0 (odd <number>) indicates the first node is a hide
      - ConsecutiveFoldedCount, ConsecutiveUnFoldedCount are doubled;
        bit 0 indicates:
          If last was fold: 1-odd = hide  /  0-even = open
          If last was hide: 1-odd = fold  /  0-even = open
          If last was open: 1-odd = hide  /  0-even = fold
        In the first <ConsecutiveFoldedCount> after <NodePos> the bit is unused, since nodepos is continued.
*)
begin
  {$IFDEF SynFoldSaveDebug}
  debugln(['TSynEditFoldExportCoder.AddNode FType=', dbgs(FFoldType),'   X=', aX, ' Y=', aY, 'Len=', aLen, 'FType=', SynEditFoldTypeNames[aFoldType], ' WCacheLen=', FWriteCacheLen]);
  {$ENDIF}
  if (FWriteCacheLen = 0) and (aFoldType = scftOpen) then
    exit;
  if FWriteCacheLen >= length(FWriteCache) then
    SetLength(FWriteCache, Max(1000, FWriteCacheLen*2));
  FWriteCache[FWriteCacheLen].aY := aY;
  FWriteCache[FWriteCacheLen].aX := aX;
  FWriteCache[FWriteCacheLen].aLen := aLen;
  FWriteCache[FWriteCacheLen].aFoldType := aFoldType;
  inc(FWriteCacheLen);
  include(FWriteCacheTypes, aFoldType);
end;

procedure TSynEditFoldExportCoder.Finish;
var
  FirstLine, HideFactor, HideBit: Integer;
  CntSum, LinesSum: Integer;
  LastFoldType: TSynEditFoldType;

  procedure WriteCachedNode(AIndex: Integer);
  begin
    HideBit := 0;
    LastFoldType := FWriteCache[AIndex].aFoldType;
    if (HideFactor = 2) and (LastFoldType = scftHide) then
      HideBit := 1;
    FExportStream.AppendNum  (FWriteCache[AIndex].aY - FirstLine);
    FExportStream.AppendNumEx(FWriteCache[AIndex].aX * HideFactor + HideBit);
    FExportStream.AppendNumEx(FWriteCache[AIndex].aLen);
    FirstLine := FWriteCache[AIndex].aY;
  end;

  function CountConsecutiveNodes(var AStartIndex: Integer; out ACount, ALines: Integer;
    ASkipFirst: Boolean = True): Boolean;
  var l1, l2: Integer;
      t: TSynEditFoldType;
  begin
    // reset counters for following <FoldList>
    CntSum := 0;
    LinesSum := 0;

    HideBit := 0;;
    case LastFoldType of
      scftOpen: if scftHide = FWriteCache[AStartIndex].aFoldType then HideBit := 1;
      scftFold: if scftHide = FWriteCache[AStartIndex].aFoldType then HideBit := 1;
      scftHide: if scftFold = FWriteCache[AStartIndex].aFoldType then HideBit := 1;
    end;
    LastFoldType := FWriteCache[AStartIndex].aFoldType;

    Result := False;
    ACount := 0;
    ALines := 0;

    l2 := FirstLine;
    t := FWriteCache[AStartIndex].aFoldType;
    Repeat
      if (AStartIndex >= FWriteCacheLen) then
        exit;
      l1 := FWriteCache[AStartIndex].aY;
      if (ACount         > SEQMaxNodeCount) or
         (ALines         > SEQMaxNodeCount) or
         (l1 - l2        > SEQMaxLineDistEach) or
         (l1 - FirstLine > SEQMaxLineDistTotal)
      then
        exit;

      if not ASkipFirst then begin
        ALines := ALines + FWriteCache[AStartIndex].aLen;
        inc(ACount);
      end;
      inc(AStartIndex);
      l2 := l1;
      ASkipFirst := False;
    until FWriteCache[AStartIndex].aFoldType <> t;
    Result := True;
  end;

  var DeferredZero: Boolean;
  procedure WriteNodeCount(ACount, ALines: Integer; AState: TSynEditFoldType);
  begin
    inc(CntSum, ACount);
    inc(LinesSum, ALines); // non folds are always 0
    if ACount = 0 then begin
      DeferredZero := True;
      exit;
    end;
    if DeferredZero then
      FExportStream.AppendNumEx(0);
    DeferredZero := False;
    FExportStream.AppendNumEx(ACount * HideFactor + HideBit);
  end;

  function ScanForFold(var AIndex: Integer): Boolean;
  begin
    Result := True;
    while AIndex < FWriteCacheLen do begin
      if FWriteCache[AIndex].aFoldType in [scftFold, scftHide] then exit;
      inc(AIndex);
    end;
    Result := False;
  end;
var
  i, i2, CntF, CntNF, LinesF, LinesNF: Integer;
  r: boolean;
begin
  if (FWriteCacheLen = 0) or (FWriteCacheTypes * [scftFold, scftHide] = []) then begin
    FExportStream.Clear;
    exit;
  end;
  {$IFDEF SynFoldSaveDebug}
  DebugLnEnter(['TSynEditFoldExportCoder.Finish FType=', dbgs(FFoldType)]);
  {$ENDIF}

  FirstLine := 0;
  if (FWriteCacheTypes * [scftFold, scftHide] = [scftFold, scftHide]) then begin
    HideFactor := 2;
    FExportStream.AppendString(' h');
  end
  else begin
    HideFactor := 1; // no bit for hide/fold differentation needed
    if scftHide in FWriteCacheTypes then
      FExportStream.AppendString(' H');
  end;
  i := 0;
  while i < FWriteCacheLen do begin
    WriteCachedNode(i);

    DeferredZero := False;   // special case at start, there may be 0 more folded nodes
    r := CountConsecutiveNodes(i, cntF, linesF, True);
    WriteNodeCount(CntF, LinesF, scftFold); // or hide, no matter here
    while r do begin
      r := CountConsecutiveNodes(i, cntNF, linesNF, False);
      if not r then break;
      r := CountConsecutiveNodes(i, cntF, linesF, False);
      WriteNodeCount(CntNF, LinesNF, scftOpen);
      WriteNodeCount(CntF, LinesF, scftFold); // or hide, no matter here
    end;

    i2 := i;
    ScanForFold(i);
    if (i < FWriteCacheLen) then begin
      // another node will follow, must insert ' p' marker
      FExportStream.AppendString(' p');      // point marker (no marker needed for first entry)
      FExportStream.AppendNum(LinesSum);   // Start with sum from last sequence
    end;
  end;

  if LinesSum > 10 then begin
    // end of data; write ' P' marker if needed
    FExportStream.AppendString(' P');      // point marker (no marker needed for first entry)
    FExportStream.AppendNum  (LinesSum);   // Start with sum from last sequence
    FExportStream.AppendNum  (FWriteCache[i2-1].aY - FirstLine);  // Last folded Coords
    FExportStream.AppendNumEx(FWriteCache[i2-1].aX);
  end;
  {$IFDEF SynFoldSaveDebug}
  DebugLnExit(['TSynEditFoldExportCoder.Finish FType=', dbgs(FFoldType), '  txtLen=', FExportStream.Len, ' Txt="', FExportStream.Text, '"']);
  {$ENDIF}
end;

function TSynEditFoldExportCoder.ReadNode(aX, aY: Integer; aLen: Integer): TSynEditFoldType;
(* Format:  [Num] <NumEX>
  ' T' [type]
   [yo] <X> <len> ( <c>* ' p' [sum]  [yo] <X> <len> )* <c>* (' P' [sum] [yo] <X>)?
*)
  function GetCommand: Char;
  begin
    Result := #0;
    if (FExportStream.PeakString(1) = ' ') and (FExportStream.Len > FExportStream.Pos+1) then
      Result := FExportStream.ReadString(2)[2];
  end;
  function Invalidate: TSynEditFoldType;
  begin
    {$IFDEF SynFoldSaveDebug}
    DebugLn(['Invalidate']);
    {$ENDIF}
    FReadState := sfecInvalid;
    Result := scftInvalid;
  end;
var
  i: Integer;
begin
  {$IFDEF SynFoldSaveDebug}
  DebugLnEnter(['TSynEditFoldExportCoder.Readnode  X=', aX, ' Y=', aY, ' Len=',aLen,
                '   ReadState=',SynEditFoldExportCoderStates[FReadState],
                ' FReadCount=', FReadCount, ' FReadY=', FReadY, ' FReadX=', FReadX,
                ' FReadSumLen=', FReadSumLen, ' FReadType=', SynEditFoldTypeNames[FReadType]
                 ]);
  try
  {$ENDIF}
  case FReadState of
    sfecAtBegin, sfecAtPoint:
      begin
        if (FReadState = sfecAtBegin) then begin
          case GetCommand of
            'H': begin
                FReadDefaultType := scftHide;
                FReadType := scftHide;
              end;
            'h': begin
                FReadDefaultType := scftAll;
              end;
          end;
          FReadState := sfecAtPoint;
        end;

        if FReadCount = 0 then begin
          FReadCount  := 1;
          FReadY      := FExportStream.ReadNum + FReadLastY;
          FReadX      := FExportStream.ReadNumEx;
          FReadSumLen := FExportStream.ReadNumEx;
          if FReadSumLen < 0 then exit(Invalidate);

          if FReadDefaultType = scftAll then begin
            if (FReadX and 1) = 1 then
              FReadType := scftHide
            else
              FReadType := scftFold;
            FReadX := FReadX div 2;
          end
          else
            FReadType := FReadDefaultType;
        end;

        if ((aY < FReadY) or ((aY = FReadY) and (aX < FReadX))) then
          exit(scftOpen);  // actually, read before point

        i := 0;
        if FReadType = scftHide then i := 1; // fold one more than len
        if (aY <> FReadY) or (aX <> FReadX) or (aLen + i <> FReadSumLen) then
          exit(Invalidate);

        FReadLastY := FReadY;
        FReadSumLen := 0; // was len of current fold, no len remaining => prepare for counting consecutive folds
        Result := FReadType;

        if FExportStream.EOF then
          FReadState := sfecAtEOF
        else case GetCommand of
          'p':
            begin
              FExportStream.ReadNum;  // skip len (must be 0) since there was no <ConsecutiveFoldedCount>
              FReadCount := 0;
              FReadState := sfecAtPoint;
            end;
          'P':
            begin
              // end marker isnt expected? there were no <ConsecutiveFoldedCount>
              FReadState := sfecAtEOF;
            end;
          else
            begin
              FReadState := sfecInRepeatCount;
              FReadCount := FExportStream.ReadNumEx;  // count up and check at end
            end;
        end;
      end;

    sfecInRepeatCount:
      begin
        if FReadCount = 0 then begin
          if FExportStream.EOF then begin
            FReadState := sfecAtEOF;
            exit(scftOpen);
          end
          else case GetCommand of
            'p':
              begin
                if FReadSumLen <> FExportStream.ReadNum then
                  exit(Invalidate);
                FReadCount := 0;
                FReadState := sfecAtPoint;
                exit(ReadNode(aX, aY, aLen));
              end;
            'P':
              begin
                if (FReadSumLen <> FExportStream.ReadNum) or
                   (FReadY <> FExportStream.ReadNum + FReadLastY) or
                   (FReadX <> FExportStream.ReadNumEx)
                then
                  exit(Invalidate);
                FReadState := sfecAtEOF;
                exit(scftOpen);
              end;
            else
              begin
                FReadCount := FExportStream.ReadNumEx;  // count up and check at end
                if FReadDefaultType = scftAll then begin
                  if (FReadCount and 1) = 1 then begin
                    case FReadType of
                      scftOpen: FReadType := scftHide;
                      scftFold: FReadType := scftHide;
                      scftHide: FReadType := scftFold;
                    end;
                  end else begin
                    case FReadType of
                      scftOpen: FReadType := scftFold;
                      scftFold: FReadType := scftOpen;
                      scftHide: FReadType := scftOpen;
                    end;
                  end;
                  FReadCount := FReadCount div 2;
                end
                else begin
                  if FReadType = scftOpen then
                    FReadType := FReadDefaultType
                  else
                    FReadType := scftOpen;
                end;
              end;
          end;
        end;
        dec(FReadCount);
        inc(FReadSumLen, aLen);
        Result := FReadType;
      end;

    sfecAtEOF:
      begin
        exit(scftOpen);
      end;
    sfecInvalid:
      begin
        exit(scftInvalid);
      end;
  end;
  {$IFDEF SynFoldSaveDebug}
  finally
    DebugLnExit(['TSynEditFoldExportCoder.Readnode << ']);
  end;
  {$ENDIF}
end;

function TSynEditFoldExportCoder.EOF: Boolean;
begin
  Result := FExportStream.EOF;
end;

procedure TSynEditFoldExportCoder.Reset;
begin
  FExportStream.Reset;
  FReadY := -1;
  FReadX := -1;
  FReadLastY := 0;
  FReadCount := 0;
  FReadSumLen := 0;
  FReadState := sfecAtBegin;
  if FExportStream.Len = 0 then
    FReadState := sfecInvalid;
  FReadDefaultType := scftFold;
  FReadType := scftFold;
end;

{ TSynTextFoldAVLNodeData }

function TSynTextFoldAVLNodeData.Left: TSynTextFoldAVLNodeData;
begin
  Result := TSynTextFoldAVLNodeData(FLeft);
end;

function TSynTextFoldAVLNodeData.Parent: TSynTextFoldAVLNodeData;
begin
  Result := TSynTextFoldAVLNodeData(FParent);
end;

function TSynTextFoldAVLNodeData.Right: TSynTextFoldAVLNodeData;
begin
  Result := TSynTextFoldAVLNodeData(FRight);
end;

function TSynTextFoldAVLNodeData.RecursiveFoldCount : Integer;
var
  ANode: TSynTextFoldAVLNodeData;
begin
  Result := 0;
  ANode := self;
  while ANode <> nil do begin
    Result := Result + ANode.MergedLineCount + ANode.LeftCount;
    ANode := ANode.Right;
  end;
end;

function TSynTextFoldAVLNodeData.Precessor: TSynTextFoldAVLNodeData;
begin
  Result := TSynTextFoldAVLNodeData(inherited Precessor);
end;

function TSynTextFoldAVLNodeData.Successor: TSynTextFoldAVLNodeData;
begin
  Result := TSynTextFoldAVLNodeData(inherited Successor);
end;

function TSynTextFoldAVLNodeData.Precessor(var aStartPosition,
  aSizesBeforeSum: Integer): TSynTextFoldAVLNodeData;
begin
  Result := TSynTextFoldAVLNodeData(inherited Precessor(aStartPosition, aSizesBeforeSum));
end;

function TSynTextFoldAVLNodeData.Successor(var aStartPosition,
  aSizesBeforeSum: Integer): TSynTextFoldAVLNodeData;
begin
  Result := TSynTextFoldAVLNodeData(inherited Successor(aStartPosition, aSizesBeforeSum));
end;

{ TSynTextFoldAVLNode }

function TSynTextFoldAVLNode.GetFoldIndex: Integer;
begin
  if fData = nil
  then Result := -1
  else Result := fData.FoldIndex;
end;

function TSynTextFoldAVLNode.GetMergedLineCount : Integer;
begin
  if fData = nil
  then Result := 0
  else Result := fData.MergedLineCount;
end;

function TSynTextFoldAVLNode.GetFullCount: Integer;
begin
  if fData = nil
  then Result := -1
  else Result := fData.FullCount;
end;

function TSynTextFoldAVLNode.GetSourceLine: integer;
begin
  if fData = nil then
    Result := -1
  else
    Result := StartLine - fData.VisibleLines;
end;

function TSynTextFoldAVLNode.GetSourceLineOffset: integer;
begin
  if fData = nil then
    Result := 0
  else
    Result := fData.VisibleLines;
end;

procedure TSynTextFoldAVLNode.Init(aData: TSynTextFoldAVLNodeData; aStartLine,
  aFoldedBefore: Integer);
begin
  fData := aData;
  fStartLine :=  aStartLine;
  fFoldedBefore := aFoldedBefore;
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

function TSynTextFoldAVLNode.IsHide: Boolean;
begin
  Result := (fData <> nil) and (fData.VisibleLines = 0);
end;

{ TSynTextFoldAVLNodeNestedIterator }

constructor TSynTextFoldAVLNodeNestedIterator.Create(ANode: TSynTextFoldAVLNode);
begin
  SetLength(FOuterNodes, 0);
  FCurrentNode := ANode;
end;

destructor TSynTextFoldAVLNodeNestedIterator.Destroy;
begin
  SetLength(FOuterNodes, 0);
  inherited Destroy;
end;

function TSynTextFoldAVLNodeNestedIterator.Next: TSynTextFoldAVLNode;
var
  NewData: TSynTextFoldAVLNodeData;
  i: Integer;
  PNode: TSynTextFoldAVLNode;
begin
  i := length(FOuterNodes);
  if FCurrentNode.fData.Nested = nil then begin
    FCurrentNode := FCurrentNode.Next;
    while (not FCurrentNode.IsInFold) and (i > 0) do begin
      dec(i);
      FCurrentNode := FOuterNodes[i];
      SetLength(FOuterNodes, i);
      FCurrentNode := FCurrentNode.Next;
    end;
  end else begin
    SetLength(FOuterNodes, i + 1);
    FOuterNodes[i] := FCurrentNode;
    NewData := FCurrentNode.fData.Nested;
    FCurrentNode.fData := NewData;
    FCurrentNode.FStartLine := FCurrentNode.FStartLine + NewData.LineOffset;

    PNode := FCurrentNode.Prev;
    while PNode.IsInFold do begin
      FCurrentNode := PNode;
      PNode := FCurrentNode.Prev;
    end;
  end;
  Result := FCurrentNode;
end;

function TSynTextFoldAVLNodeNestedIterator.Prev: TSynTextFoldAVLNode;
var
  i: Integer;
  NewData: TSynTextFoldAVLNodeData;
  PNode: TSynTextFoldAVLNode;
begin
  FCurrentNode := FCurrentNode.Prev;
  i := length(FOuterNodes);
  if FCurrentNode.IsInFold then begin
    while (FCurrentNode.fData.Nested <> nil) do begin
      SetLength(FOuterNodes, i + 1);
      FOuterNodes[i] := FCurrentNode;
      NewData := FCurrentNode.fData.Nested;
      FCurrentNode.fData := NewData;
      FCurrentNode.FStartLine := FCurrentNode.FStartLine + NewData.LineOffset;

      PNode := FCurrentNode.Next;
      while PNode.IsInFold do begin
        FCurrentNode := PNode;
        PNode := FCurrentNode.Next;
      end;
    end;
  end
  else // not IsInFold
  if (i > 0) then begin
    dec(i);
    FCurrentNode := FOuterNodes[i];
    SetLength(FOuterNodes, i);
  end;
  Result := FCurrentNode;
end;

function TSynTextFoldAVLNodeNestedIterator.EOF: Boolean;
begin
  Result := not FCurrentNode.Next.IsInFold;
end;

function TSynTextFoldAVLNodeNestedIterator.BOF: Boolean;
begin
  Result := not FCurrentNode.Prev.IsInFold;
end;

function TSynTextFoldAVLNodeNestedIterator.IsInFold: Boolean;
begin
  Result := FCurrentNode.IsInFold;
end;

{ TSynFoldNodeInfoHelper }

constructor TSynFoldNodeInfoHelper.Create(AHighlighter: TSynCustomFoldHighlighter);
begin
  inherited Create;
  FHighlighter := AHighlighter;
  Invalidate;
end;

function TSynFoldNodeInfoHelper.FirstOpen: TSynFoldNodeInfo;
begin
  FActions := [sfaOpen, sfaFold];
  FCurInfo.NodeIndex := -1;
  FCurInfo.LineIndex := 0;
  Result := Next;
end;

procedure TSynFoldNodeInfoHelper.Invalidate;
begin
  FCurInfo.FoldAction := [sfaInvalid];
end;

function TSynFoldNodeInfoHelper.Next: TSynFoldNodeInfo;
var
  Cnt, Line, Idx: LongInt;
begin
  Idx := FCurInfo.NodeIndex + 1;
  Line := FCurInfo.LineIndex;
  Cnt := FHighlighter.FoldNodeInfoCount[Line, FActions];
  if Idx >= Cnt then begin
    Idx := 0;
    inc(Line);
    while (Line < FHighlighter.CurrentLines.Count) and
          (FHighlighter.FoldNodeInfoCount[Line, FActions] = 0)
    do
      inc(Line);
  end;
  if (Line < FHighlighter.CurrentLines.Count) then
    FCurInfo := FHighlighter.FoldNodeInfo[Line, Idx, FActions]
  else
    Invalidate;
  Result := FCurInfo;
end;

function TSynFoldNodeInfoHelper.Prev: TSynFoldNodeInfo;
var
  Line, Idx: LongInt;
begin
  Idx := FCurInfo.NodeIndex - 1;
  Line := FCurInfo.LineIndex;
  if Idx < 0 then begin
    dec(Line);
    while (Line >= 0) and
          (FHighlighter.FoldNodeInfoCount[Line, FActions] = 0)
    do
      dec(Line);
    Idx := FHighlighter.FoldNodeInfoCount[Line, FActions] - 1;
  end;
  if (Line >= 0) then
    FCurInfo := FHighlighter.FoldNodeInfo[Line, Idx, FActions]
  else
    Invalidate;
  Result := FCurInfo;
end;

function TSynFoldNodeInfoHelper.FindClose: TSynFoldNodeInfo;
var
  Line, EndLine, Cnt: Integer;
  NdInfo: TSynFoldNodeInfo;
begin
  Line := FCurInfo.LineIndex;
  EndLine := FHighlighter.FoldEndLine(Line, FCurInfo.NodeIndex);
  FActions := [sfaClose, sfaFold];
  Cnt := FHighlighter.FoldNodeInfoCount[EndLine, FActions] - 1;
  while Cnt >= 0 do begin
    NdInfo := FHighlighter.FoldNodeInfo[EndLine, Cnt, FActions];
    if (NdInfo.FoldLvlStart = FCurInfo.FoldLvlEnd) and
       (NdInfo.FoldType = FCurInfo.FoldType)
    then
      break;
    dec(Cnt);
  end;
  if Cnt < 0 then
    Invalidate
  else
    FCurInfo := NdInfo;
  Result := FCurInfo;
end;

function TSynFoldNodeInfoHelper.GotoOpenPos(aLineIdx, aNodeIdx: integer): TSynFoldNodeInfo;
begin
  FActions := [sfaOpen, sfaFold];
  FCurInfo := FHighlighter.FoldNodeInfo[aLineIdx, aNodeIdx, FActions];
  Result := FCurInfo;
end;

function TSynFoldNodeInfoHelper.GotoOpenAtChar(aLineIdx, aXPos: integer): TSynFoldNodeInfo;
var
  Cnt: Integer;
begin
  FActions := [sfaOpen, sfaFold];
  Cnt := FHighlighter.FoldNodeInfoCount[aLineIdx, FActions] - 1;
  while Cnt >= 0 do begin
    FCurInfo := FHighlighter.FoldNodeInfo[aLineIdx, Cnt, FActions];
    if FCurInfo.LogXStart = aXPos then break;
    dec(Cnt);
  end;
  if Cnt < 0 then
    Invalidate;
  Result := FCurInfo;
end;

function TSynFoldNodeInfoHelper.GotoNodeOpenPos(ANode: TSynTextFoldAVLNode): TSynFoldNodeInfo;
begin
  FActions := [sfaOpen, sfaFold];
  FCurInfo := FHighlighter.FoldNodeInfo[ANode.StartLine - ANode.SourceLineOffset - 1,
                                        ANode.FoldIndex, FActions];
  Result := FCurInfo;
end;

function TSynFoldNodeInfoHelper.GotoNodeClosePos(ANode: TSynTextFoldAVLNode): TSynFoldNodeInfo;
var
  NdInfo, NdInfo2: TSynFoldNodeInfo;
  Cnt, EndCol, EndLineIdx: Integer;
begin
  FActions := [sfaClose, sfaFold];
  NdInfo := FHighlighter.FoldNodeInfo[ANode.StartLine - ANode.SourceLineOffset - 1,
                                      ANode.FoldIndex, [sfaOpen, sfaFold]];

  EndLineIdx := FHighlighter.FoldEndLine(ANode.StartLine - ANode.SourceLineOffset - 1,
                                        ANode.FoldIndex);
  Cnt := FHighlighter.FoldNodeInfoCount[EndLineIdx, [sfaClose, sfaFold]];
  EndCol := 0;
  while EndCol < Cnt do begin
    NdInfo2 := FHighlighter.FoldNodeInfo[EndLineIdx, EndCol, [sfaClose, sfaFold]];
    if (NdInfo2.FoldLvlStart = NdInfo.FoldLvlEnd) and
       (NdInfo2.FoldType = NdInfo.FoldType) then break;
    inc(EndCol);
  end;
  if (EndCol = Cnt) or (sfaInvalid in NdInfo2.FoldAction) then
    Invalidate
  else
    FCurInfo := NdInfo2;
  Result := FCurInfo;
end;

function TSynFoldNodeInfoHelper.IsAtNodeOpenPos(ANode: TSynTextFoldAVLNode): Boolean;
begin
  Result := (not (sfaInvalid in FCurInfo.FoldAction)) and
            (ANode.IsInFold) and
            (FCurInfo.LineIndex = ANode.StartLine - ANode.SourceLineOffset - 1) and
            (FCurInfo.NodeIndex = ANode.FoldIndex);
end;

function TSynFoldNodeInfoHelper.IsValid: Boolean;
begin
  Result := (not (sfaInvalid in FCurInfo.FoldAction));
end;

function TSynFoldNodeInfoHelper.Equals(AnInfo: TSynFoldNodeInfo): Boolean;
begin
  Result := (FCurInfo.LineIndex = AnInfo.LineIndex) and
            (FCurInfo.NodeIndex = AnInfo.NodeIndex) and
            (FCurInfo.LogXStart = AnInfo.LogXStart) and
            (FCurInfo.LogXEnd   = AnInfo.LogXEnd) and
            (FCurInfo.FoldLvlStart = AnInfo.FoldLvlStart) and
            (FCurInfo.FoldLvlEnd   = AnInfo.FoldLvlEnd) and
            (FCurInfo.FoldAction = AnInfo.FoldAction) and
            (FCurInfo.FoldType   = AnInfo.FoldType) and
            (FCurInfo.FoldGroup  = AnInfo.FoldGroup);
end;

function TSynFoldNodeInfoHelper.Equals(AHelper: TSynFoldNodeInfoHelper): Boolean;
begin
  Result := Equals(AHelper.Info);
end;

{ TSynTextFoldAVLTree }

function TSynTextFoldAVLTree.NewNode : TSynTextFoldAVLNodeData;
begin
  Result := TSynTextFoldAVLNodeData.Create;
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
  procedure DeleteNode({var} ANode: TSynTextFoldAVLNodeData);
  begin
    if ANode.Left <>nil   then DeleteNode(ANode.Left);
    if ANode.Right <>nil  then DeleteNode(ANode.Right);
    if ANode.Nested <>nil then DeleteNode(ANode.Nested);
    DisposeNode(TSynSizedDifferentialAVLNode(ANode));
  end;
begin
  if fRoot <> nil then DeleteNode(TSynTextFoldAVLNodeData(fRoot));
  SetRoot(nil);
end;

procedure TSynTextFoldAVLTree.SetRoot(ANode : TSynSizedDifferentialAVLNode);
begin
  inherited;;
  if fNestParent <> nil then fNestParent.Nested := TSynTextFoldAVLNodeData(ANode);
end;

procedure TSynTextFoldAVLTree.SetRoot(ANode : TSynSizedDifferentialAVLNode; anAdjustChildLineOffset : Integer);
begin
  inherited;;
  if fNestParent <> nil then fNestParent.Nested := TSynTextFoldAVLNodeData(ANode);
end;

(* Find Fold by Line in Real Text *)
function TSynTextFoldAVLTree.FindFoldForLine(ALine : Integer;
  FindNextNode : Boolean = False) : TSynTextFoldAVLNode;
var
  r : TSynTextFoldAVLNodeData;
  rStartLine : Integer;
  rFoldedBefore : Integer;
begin
  r := TSynTextFoldAVLNodeData(fRoot);
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
    if ALine < rStartLine + r.MergedLineCount
    then break;

    if FindNextNode and (r.Right = nil) then begin
      r := r.Successor(rStartLine, rFoldedBefore);
      break;
    end;

    rFoldedBefore := rFoldedBefore + r.MergedLineCount;
    r := r.Right; // rStartLine points to r, which now is the start of the previous fold;
  end;

  Result.Init(r, rStartLine, rFoldedBefore);
end;

(* Find Fold by Line in Folded Text // always returns unfolded, unless next=true *)
function TSynTextFoldAVLTree.FindFoldForFoldedLine(ALine : Integer;
  FindNextNode : Boolean) : TSynTextFoldAVLNode;
var
  r : TSynTextFoldAVLNodeData;
  rStartLine : Integer;
  rFoldedBefore : Integer;
begin
  r := TSynTextFoldAVLNodeData(fRoot);
  rStartLine := fRootOffset;
  rFoldedBefore := 0;
  while (r <> nil) do begin
    rStartLine := rStartLine + r.LineOffset;

    // r.LeftCount => "FoldedBefore"
    if ALine + r.LeftCount < rStartLine then begin
      if FindNextNode and (r.Left = nil) then break;
      r := r.Left; // rStartLine points to r, so if r.Left is nil then it is pointing to the next fold;
      continue;
    end;

    ALine := ALine + r.LeftCount + r.MergedLineCount;
    rFoldedBefore := rFoldedBefore + r.LeftCount;

    if FindNextNode and (r.Right = nil) then begin
      r := r.Successor(rStartLine, rFoldedBefore);
      break;
    end;

    rFoldedBefore := rFoldedBefore + r.MergedLineCount;
    r := r.Right; // rStartLine points to r, which now is the start of the previous fold;
  end;

  Result.Init(r, rStartLine, rFoldedBefore);
end;

procedure TSynTextFoldAVLTree.AdjustForLinesInserted(AStartLine, ALineCount : Integer);
  Procedure DoAdjustForLinesInserted(Current : TSynTextFoldAVLNodeData;
    CurrentLine : Integer);
  var
    t: LongInt;
  begin
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
      else if AStartLine > CurrentLine + Current.MergedLineCount- 1 then begin
        // The new lines are entirly behind the current node
        Current := Current.Right;
      end
      else begin
        // grow current node
        // CurrentLine <= AStartLine  <= CurrentLine + Current.FullCount - 1
        t := Current.FullCount;
        if AStartLine <= CurrentLine + t - 1 then
          Current.FullCount := t + ALineCount;
        Current.MergedLineCount:= Current.MergedLineCount+ ALineCount;
        Current.AdjustParentLeftCount(ALineCount);
        TreeForNestedNode(Current, CurrentLine).AdjustForLinesInserted(AStartLine, ALineCount);

        if Current.Right <> nil then // and move entire right
          Current.Right.LineOffset := Current.Right.LineOffset + ALineCount;
        break;
      end;
    end;
  end;

begin
  DoAdjustForLinesInserted(TSynTextFoldAVLNodeData(fRoot), fRootOffset);
end;

procedure TSynTextFoldAVLTree.AdjustForLinesDeleted(AStartLine,
  ALineCount : Integer);
  Procedure AdjustNodeForLinesDeleted(Current : TSynTextFoldAVLNodeData;
    CurrentLine, FirstLineToDelete, CountLinesToDelete : Integer);
  var
    LastLineToDelete, LinesBefore, LinesInside, LinesAfter, t : Integer;
  begin
    LastLineToDelete := FirstLineToDelete + CountLinesToDelete - 1; // only valid for delete; CountLinesToDelete < 0

    while (Current <> nil) do begin
      CurrentLine := CurrentLine + Current.LineOffset;

      if FirstLineToDelete < CurrentLine then begin
        // move current node
        if LastLineToDelete >= CurrentLine then begin
          // overlap => shrink
          LinesBefore := CurrentLine - FirstLineToDelete;
          LinesInside := CountLinesToDelete - LinesBefore;
          // shrink
          t := Current.MergedLineCount;
          Current.FullCount := Max(Current.FullCount - LinesInside, -1);
          Current.MergedLineCount := Max(Current.MergedLineCount - LinesInside, 0);
          Current.AdjustParentLeftCount(Current.MergedLineCount - t); // If LineCount = -1; LeftCount will be correctd on delete node
          TreeForNestedNode(Current, CurrentLine).AdjustForLinesDeleted(CurrentLine, LinesInside);

          if (Current.Right <> nil) then begin
            // move right // Calculate from the new curent.LineOffset, as below
            AdjustNodeForLinesDeleted(Current.Right, CurrentLine - LinesBefore,
                                      FirstLineToDelete, LinesInside);
          end;
        end
        else LinesBefore := CountLinesToDelete;

        // move current node (includes right subtree / left subtree needs eval)
        Current.LineOffset := Current.LineOffset - LinesBefore;
        CurrentLine := CurrentLine - LinesBefore;
        if Current.Left <> nil then
          Current.Left.LineOffset := Current.Left.LineOffset + LinesBefore;
        Current := Current.Left;
      end
      else if FirstLineToDelete > CurrentLine + Current.MergedLineCount - 1 then begin
        // The deleted lines are entirly behind the current node
        Current := Current.Right;
      end
      else begin
        // (FirstLineToDelete >= CurrentLine) AND (FirstLineToDelete < CurrentLine + Current.LineCount);
        LinesAfter  := LastLineToDelete - (CurrentLine + Current.MergedLineCount - 1);
        if LinesAfter < 0 then LinesAfter := 0;
        LinesInside := CountLinesToDelete - LinesAfter;

        // shrink current node
        t := Current.MergedLineCount;
        Current.MergedLineCount := Current.MergedLineCount- LinesInside;
        if Current.FullCount > Current.MergedLineCount then
          Current.FullCount := Current.MergedLineCount;
        Current.AdjustParentLeftCount(Current.MergedLineCount - t); // If MergedLineCount = -1; LeftCount will be correctd on delete node

        TreeForNestedNode(Current, CurrentLine).AdjustForLinesDeleted(FirstLineToDelete, LinesInside);
        Current := Current.Right;
      end;

    end;
  end;

begin
  AdjustNodeForLinesDeleted(TSynTextFoldAVLNodeData(fRoot), fRootOffset, AStartLine, ALineCount);
end;

function TSynTextFoldAVLTree.FindLastFold : TSynTextFoldAVLNode;
var
  r : TSynTextFoldAVLNodeData;
  rStartLine : Integer;
  rFoldedBefore : Integer;
begin
  r := TSynTextFoldAVLNodeData(fRoot);
  rStartLine := fRootOffset;
  rFoldedBefore := 0;
  while (r <> nil) do begin
    rStartLine := rStartLine + r.LineOffset;
    rFoldedBefore := rFoldedBefore + r.LeftCount + r.MergedLineCount;
    if r.Right = nil then break;
    r := r.Right; // rStartLine points to r, which now is the start of the previous fold;
  end;

  Result.Init(r, rStartLine, rFoldedBefore);
end;

function TSynTextFoldAVLTree.FindFirstFold : TSynTextFoldAVLNode;
var
  r : TSynTextFoldAVLNodeData;
  rStartLine : Integer;
begin
  r := TSynTextFoldAVLNodeData(fRoot);
  rStartLine := fRootOffset;
  while (r <> nil) do begin
    rStartLine := rStartLine + r.LineOffset;
    if r.Left = nil then break;
    r := r.Left;
  end;

  Result.Init(r, rStartLine, 0);
end;

function TSynTextFoldAVLTree.LastFoldedLine: integer;
var
  n: TSynTextFoldAVLNode;
begin
  n := FindFirstFold;
  if not n.IsInFold then exit(0);
  Result := n.StartLine + n.MergedLineCount - 1;
end;

{$IFDEF SynDebug}
procedure TSynTextFoldAVLTree.debug;
  function debug2(ind, typ : String; ANode, AParent : TSynTextFoldAVLNodeData; offset : integer) :integer;
  begin
    result := 0;
    if ANode = nil then exit;
    with ANode do
      DebugLn([Format('Lines=%3d-%3d (e=%3d / idx=%d):  Lcnt=%2d / Fcnt=%2d  | ',
                      [offset + ANode.LineOffset, offset + ANode.LineOffset + ANode.FullCount -1,
                       offset + ANode.LineOffset + ANode.MergedLineCount-1, ANode.FoldIndex,
                       MergedLineCount, FullCount]),
               ind, typ, ' (',LineOffset, ')  LeftCount: ', LeftCount,
               '     Balance: ',FBalance]);
    if ANode.Parent <> AParent then DebugLn([ind,'* Bad parent']);
    Result := debug2(ind+'   ', 'L', ANode.Left, ANode, offset+ANode.LineOffset);
    If Result <> ANode.LeftCount then  debugln([ind,'   ***** Leftcount was ',Result, ' but should be ', ANode.LeftCount]);
    Result := Result + debug2(ind+'   ', 'R', ANode.Right, ANode, offset+ANode.LineOffset);
    debug2(ind+'  #', 'N', ANode.Nested, nil, offset+ANode.LineOffset);
    Result := Result + ANode.MergedLineCount;
  end;
begin
  debug2('', ' -', TSynTextFoldAVLNodeData(fRoot), nil, 0);
end;
{$ENDIF}

function TSynTextFoldAVLTree.InsertNewFold(ALine, AColumn, ACount, AVisibleLines: Integer) : TSynTextFoldAVLNode;
var
  r : TSynTextFoldAVLNodeData;
begin
  {$IFDEF SynFoldDebug}debugln(['FOLD-- InsertNewFold ALine:=', ALine, '  AColumn=', AColumn]);{$ENDIF}
  r := NewNode;
  r.LineOffset := ALine; // 1-based
  r.FoldIndex := AColumn;
  r.MergedLineCount := ACount;
  r.FullCount  := ACount;
  r.LeftCount  := 0;
  r.VisibleLines := AVisibleLines;

  Result.Init(r, ALine, 0);
  Result.fFoldedBefore := InsertNode(r);
end;

function TSynTextFoldAVLTree.RemoveFoldForLine(ALine : Integer;
  OnlyCol: Integer = -1) : Integer;
var
  OldFold : TSynTextFoldAVLNode;
  lcount: Integer;
begin
  {$IFDEF SynFoldDebug}debugln(['FOLD-- RemoveFoldForLine ALine:=', ALine, '  OnlyCol=',OnlyCol]);{$ENDIF}
  Result := ALine; // - 1; // Return index
  OldFold := FindFoldForLine(ALine, False);
  if OldFold.StartLine < Result then
    Result := OldFold.StartLine;

  if (not OldFold.IsInFold) then exit;

  if OnlyCol < 0 then
    RemoveFoldForNodeAtLine(OldFold, ALine)
  else
  if OldFold.FoldIndex = OnlyCol then
    RemoveFoldForNodeAtLine(OldFold, -1)
  else
  if OldFold.fData.Nested <> nil then begin
    TreeForNestedNode(OldFold.fData, OldFold.StartLine).RemoveFoldForLine
      (ALine, OnlyCol);
    lcount := max(OldFold.FullCount,
                  TreeForNestedNode(OldFold.fData, 0).LastFoldedLine + 1);
    if lcount <> OldFold.MergedLineCount then begin
      OldFold.fData.MergedLineCount := lcount;
      OldFold.fData.AdjustParentLeftCount(OldFold.MergedLineCount - lcount);
    end;
  end;
end;

function TSynTextFoldAVLTree.RemoveFoldForNodeAtLine(ANode : TSynTextFoldAVLNode;
  ALine : Integer) : Integer;
var
  NestedNode, MergeNode : TSynTextFoldAVLNodeData;
  NestedLine, offs, lcount : Integer;
  OnlyNested: Boolean;
  Nested: TSynTextFoldAVLNode;
begin
  {$IFDEF SynFoldDebug}debugln(['FOLD-- RemoveFoldForNodeAtLine: ALine:=', ALine, ' ANode.StartLine=', ANode.StartLine]);{$ENDIF}
  OnlyNested := ALine >= ANode.StartLine + ANode.FullCount;
  // The cfCollapsed line is one line before the fold
  Result := ANode.StartLine-1;  // Return the cfcollapsed that was unfolded
  if not OnlyNested then
    RemoveNode(ANode.fData);

  If ANode.fData.Nested <> nil then
  begin
    (*Todo: should we mark the tree as NO balancing needed ???*)
    TreeForNestedNode(ANode.fData, ANode.StartLine).RemoveFoldForLine(ALine);

    if OnlyNested then begin
      NestedLine := ANode.StartLine + ANode.FullCount;
      Nested := TreeForNestedNode(ANode.fData, ANode.StartLine).FindLastFold;
      while Nested.IsInFold and (Nested.StartLine >= NestedLine) do begin
        NestedNode := Nested.fData;
        offs := Nested.StartLine;
        Nested := Nested.Prev;

        lcount := ANode.fData.MergedLineCount;
        ANode.fData.MergedLineCount := max(ANode.FullCount,
                         Nested.StartLine + Nested.MergedLineCount - ANode.StartLine);
        ANode.fData.AdjustParentLeftCount(ANode.MergedLineCount - lcount);

        TreeForNestedNode(ANode.fData, ANode.StartLine).RemoveNode(NestedNode);
        NestedNode.LineOffset := offs;
        InsertNode(NestedNode);
      end;
      lcount := max(ANode.FullCount,
                TreeForNestedNode(ANode.fData, ANode.StartLine).LastFoldedLine
                - ANode.StartLine + 1);
      if lcount <> ANode.MergedLineCount then begin
        ANode.fData.MergedLineCount := lcount;
        ANode.fData.AdjustParentLeftCount(ANode.MergedLineCount - lcount);
      end;
    end
    else begin
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
          MergeNode.FParent := nil;
        end;
        MergeNode.LeftCount := 0;
        MergeNode.FBalance   := 0;
        InsertNode(MergeNode);
      end;
    end;

  end;

  if not OnlyNested then
    DisposeNode(TSynSizedDifferentialAVLNode(ANode.fData));
end;

function TSynTextFoldAVLTree.InsertNode(ANode : TSynTextFoldAVLNodeData) : Integer;
var
  rStartLine, NestStartLine : Integer;
  rFoldedBefore, NestFoldedBefore : Integer;

  current, Nest : TSynTextFoldAVLNodeData;
  ALine, AEnd, ACount : Integer;

  (* ANode.StartLine < Current.StartLine // ANode goes into tree  *)
  procedure NestCurrentIntoNewBlock; inline;
  var
    diff, start2, before2 : Integer;
    p : TSynTextFoldAVLNodeData;
  begin
    current.AdjustParentLeftCount(ACount-current.MergedLineCount); // -RecursiveFoldCount(current));
    rStartLine := rStartLine - current.LineOffset;  // rStarteLine is now current.Parent
    p := current.Parent;
    if p <> nil
    then p.ReplaceChild(current, ANode, -rStartLine)
    else SetRoot(ANode, -rStartLine);

    diff := current.LineOffset - ANode.LineOffset;
    ANode.Nested  := current;
    ANode.FBalance := current.FBalance;
    current.LineOffset := diff; // offset to ANode (via Nested)
    current.FParent := nil;
    current.FBalance := 0;
    
    ANode.SetLeftChild(current.Left, diff, current.LeftCount);
    current.FLeft := nil;
    current.LeftCount := 0;
    ANode.SetRightChild(current.Right, diff);
    current.FRight := nil;

    start2 := ALine; before2 := rFoldedBefore;
    p := ANode.Successor(start2, before2);
    while (p <> nil) and (start2 <= AEnd) do begin
      RemoveNode(p);
      p.LineOffset := start2- ALine;
      TreeForNestedNode(Anode, 0).InsertNode(p);

      start2 := ALine; before2 := rFoldedBefore;
      p := ANode.Successor(start2, before2);
    end;
    // check only after loop, if we gre, we did so by existing nodes, so no new overlaps
    start2 := TreeForNestedNode(Anode, 0).LastFoldedLine;
    if start2 > ANode.FullCount - 1 then begin
      ANode.AdjustParentLeftCount(start2 + 1 - ANode.MergedLineCount);
      ANode.MergedLineCount := start2 + 1;
    end;
  end;

  (* ANode.StartLine > Current.StartLine // Current remains in tree  *)
  procedure NestNewBlockIntoCurrent; //inline;
  var
    end2, start2, before2: Integer;
    p: TSynTextFoldAVLNodeData;
  begin
    // Check if current.LineCount needs extension
    ANode.LineOffset := ALine - rStartLine;
    if current.Nested <> nil
    then TreeForNestedNode(current, 0).InsertNode(ANode)
    else current.Nested := ANode;

    end2 := TreeForNestedNode(current, 0).LastFoldedLine;
    if end2 > current.FullCount -1 then begin
      end2 := rStartLine + end2;

      start2 := rStartLine; before2 := rFoldedBefore;
      p := current.Successor(start2, before2);
      while (p <> nil) and (start2 <= end2) do begin
        RemoveNode(p);
        p.LineOffset := start2 - rStartLine;
        TreeForNestedNode(current, 0).InsertNode(p);

        start2 := rStartLine; before2 := rFoldedBefore;
        p := current.Successor(start2, before2);
      end;
      end2 := TreeForNestedNode(current, 0).LastFoldedLine;
      if end2 > current.FullCount -1 then begin
        current.AdjustParentLeftCount(end2 + 1 - current.MergedLineCount);
        current.MergedLineCount := end2 + 1;
      end;
    end;
  end;

begin
  if fRoot = nil then begin
    SetRoot(ANode, -fRootOffset);
    Result := 0;
    exit;
  end;
  ALine := ANode.LineOffset;
  ACount := ANode.MergedLineCount;
  AEnd := ALine + ACount - 1;
  current := TSynTextFoldAVLNodeData(fRoot);
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
        current.SetLeftChild(ANode, -rStartLine, ANode.MergedLineCount);
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
      if ANode.FoldIndex > current.FoldIndex then
        (* *** New Block will be nested in current *** *)
        NestNewBlockIntoCurrent
      else
      if ANode.FoldIndex < current.FoldIndex then
        (* *** current will be nested in New Block *** *)
        NestCurrentIntoNewBlock
      else begin
        debugln(['Droping Foldnode / Already exists. Startline=', rStartLine,' LineCount=',ACount]);
        FreeAndNil(ANode);
      end;
    end
    else begin
      If ALine <= rStartLine + current.MergedLineCount - 1
      (* *** New Block will be nested in current *** *)
      then NestNewBlockIntoCurrent
      (* *** New block goes to the right *** *)
      else begin
        rFoldedBefore := rFoldedBefore + current.MergedLineCount;
        if current.Right <> nil then begin
          current := current.Right;
          continue;
        end
        else  if Nest=nil then Begin  // insert to the right - no nesting
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
  inherited;
  fNestParent := nil;
  fNestedNodesTree := nil;
end;

{ TSynEditFoldProvider }

function TSynEditFoldProvider.GetLineCapabilities(ALineIdx: Integer): TSynEditFoldLineCapabilities;
var
  c: Integer;
begin
  Result := [];
  if (FHighlighter = nil) or (ALineIdx < 0) then exit;
  if FHighlighter.FoldNestCount(ALineIdx - 1) > 0 then Result := Result + [cfFoldBody];
  if FHighlighter.FoldCloseCount(ALineIdx) > 0    then Result := Result + [cfFoldEnd, cfFoldBody];

  c := FHighlighter.FoldNodeInfoCount[ALineIdx, []];
  if c > 0 then begin
    c := FHighlighter.FoldNodeInfoCount[ALineIdx, [sfaOpen, sfaFoldFold]];
    if c > 0 then
      include(Result, cfFoldStart);
    c := FHighlighter.FoldNodeInfoCount[ALineIdx, [sfaOpen, sfaFoldHide]];
    if c > 0 then
      include(Result, cfHideStart);
    c := FHighlighter.FoldNodeInfoCount[ALineIdx, [sfaOneLineOpen, sfaFoldHide]]; // TODO: Include scftFoldEnd ?
    // Todo: cfSingleLineHide only, if there is no other hide
    if c > 0 then
      Result := Result + [cfHideStart, cfSingleLineHide];
  end
  else
    if FHighlighter.FoldOpenCount(ALineIdx) > 0 then include(Result, cfFoldStart);
end;

procedure TSynEditFoldProvider.SetHighLighter(const AValue: TSynCustomFoldHighlighter);
begin
  if FHighlighter = AValue then exit;
  FHighlighter := AValue;
end;

function TSynEditFoldProvider.FoldOpenCount(ALineIdx: Integer; AType: Integer = 0): Integer;
var
  i: Integer;
begin
  if (FHighlighter = nil) or (ALineIdx < 0) then exit(0);

  Result := FHighlighter.FoldNodeInfoCount[ALineIdx, [sfaOpen, sfaFold]];
  if (result > 0) and (AType > 0) then begin
    i := Result ;
    Result := 0;
    while i > 0 do begin
      dec(i);
      if FHighlighter.FoldNodeInfo[ALineIdx, i, [sfaOpen, sfaFold]].FoldGroup = AType then
        inc(Result);
    end;
  end
  //Result := Result + FHighlighter.FoldNodeInfoCount[ALineIdx, [sfaOpen, sfaFoldHide]];
  //Result := Result + FHighlighter.FoldNodeInfoCount[ALineIdx, [sfaOneLineOpen, sfaFoldHide]];
  else
  if Result < 0 then
    Result := FHighlighter.FoldOpenCount(ALineIdx, AType);
end;

function TSynEditFoldProvider.FoldOpenInfo(ALineIdx, AFoldIdx: Integer;
  AType: Integer = 0): TSynFoldNodeInfo;
var
  i, x: Integer;
begin
  Result.FoldAction := [sfaInvalid];
  if (FHighlighter = nil) or (ALineIdx < 0) then exit;

  if AType = 0 then
    Result := FHighlighter.FoldNodeInfo[ALineIdx, AFoldIdx, [sfaOpen, sfaFold]]
  else begin
    x := FHighlighter.FoldNodeInfoCount[ALineIdx, [sfaOpen, sfaFold]];
    i := 0;
    while i < x do begin
      Result := FHighlighter.FoldNodeInfo[ALineIdx, i, [sfaOpen, sfaFold]];
      if (Result.FoldGroup = AType) then begin
        if AFoldIdx = 0 then
          exit;
        dec(AFoldIdx);
      end;
      inc(i);
    end;
    Result.FoldAction := [sfaInvalid];
  end;
end;

{ TSynEditFoldedView }

constructor TSynEditFoldedView.Create(aTextView : TSynEditStrings; ACaret: TSynEditCaret);
begin
  FFoldProvider := TSynEditFoldProvider.Create;
  fLines := aTextView;
  fCaret := ACaret;
  fCaret.AddChangeHandler({$IFDEF FPC}@{$ENDIF}DoCaretChanged);
  fFoldTree := TSynTextFoldAVLTree.Create;
  fTopLine := 0;
  fLinesInWindow := -1;

  FMarkupInfoFoldedCode := TSynSelectedColor.Create;
  FMarkupInfoFoldedCode.Background := clNone;
  FMarkupInfoFoldedCode.Foreground := clDkGray;
  FMarkupInfoFoldedCode.FrameColor := clDkGray;

  fLines.AddChangeHandler(senrLineCount, {$IFDEF FPC}@{$ENDIF}LineCountChanged);
end;

destructor TSynEditFoldedView.Destroy;
begin
  fLines.RemoveChangeHandler(senrLineCount, {$IFDEF FPC}@{$ENDIF}LineCountChanged);
  fCaret.RemoveChangeHandler({$IFDEF FPC}@{$ENDIF}DoCaretChanged);
  fFoldTree.Free;
  fTextIndexList := nil;
  fFoldTypeList := nil;
  FMarkupInfoFoldedCode.Free;
  FreeAndNil(FFoldProvider);
  inherited Destroy;
end;

procedure TSynEditFoldedView.LinesInsertedAtTextIndex(AStartIndex, ALineCount : Integer; SkipFixFolding : Boolean);
var top : Integer;
begin
  if ALineCount = 0 then exit;
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
  // topline may get out of sync => synedit is always going to chnage it back
  fFoldTree.AdjustForLinesDeleted(AStartIndex+1, ALineCount);
  if not(SkipFixFolding) then
    FixFoldingAtTextIndex(AStartIndex, AStartIndex+ALineCount+1)
  else
  if AStartIndex < top - ALineCount then CalculateMaps;
end;

procedure TSynEditFoldedView.LinesDeletedAtViewPos(AStartPos, ALineCount : Integer; SkipFixFolding : Boolean);
begin
  LinesDeletedAtTextIndex(ViewPosToTextIndex(AStartPos), ALineCount, SkipFixFolding);
end;

function TSynEditFoldedView.TextIndexToViewPos(aTextIndex : Integer) : Integer;
var
  n: TSynTextFoldAVLNode;
begin
  n := fFoldTree.FindFoldForLine(aTextIndex + 1);
  if n.IsInFold then
    Result := n.StartLine - 1 - n.FoldedBefore
  else
    Result := aTextIndex + 1 - n.FoldedBefore;
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
  boundary : integer;
begin
  node := fFoldTree.FindFoldForLine(aTextIndex+1, True);
  result := aTextIndex;
  if LineOffset < 0 then begin
    boundary := Max(0, ViewPosToTextIndex(1));
    if node.IsInFold
    then node := node.Prev
    else node := fFoldTree.FindLastFold;
    while LineOffset < 0 do begin
      if Result <= boundary then exit(boundary);
      dec(Result);
      if node.IsInFold and (Result+1 < node.StartLine + node.MergedLineCount) then begin
        Result := Result - node.MergedLineCount;
        node := node.Prev;
      end;
      inc(LineOffset);
    end;
  end else begin
    boundary := fLines.Count;
    while LineOffset > 0 do begin
      if Result >= boundary then exit(boundary);
      inc(Result);
      if node.IsInFold and (Result+1 >= node.StartLine) then begin
        Result := Result + node.MergedLineCount;
        if Result >= boundary then exit(boundary-node.MergedLineCount-1);
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

function TSynEditFoldedView.GetHighLighter: TSynCustomHighlighter;
begin
  Result := FHighLighter;
  if assigned(Result) then
    Result.CurrentLines := fLines;
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
  SetLength(fTextIndexList, AValue + 3);
  SetLength(fFoldTypeList, AValue + 3); // start 1 before topline
  CalculateMaps;
end;

procedure TSynEditFoldedView.CalculateMaps;
var
  i, tpos, cnt  : Integer;
  node, tmpnode: TSynTextFoldAVLNode;
  hl: TSynCustomFoldHighlighter;
begin
  if fLinesInWindow < 0 then exit;
  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then begin
    for i := 0 to fLinesInWindow+2 do begin
      fTextIndexList[i] := fTopLine + i - 2;
      fFoldTypeList[i] := [];
    end;
    exit;
  end;

  node := fFoldTree.FindFoldForFoldedLine(fTopLine, true);
  // ftopline is not a folded line
  // so node.FoldedBefore(next node after ftopl) does apply
  tpos  := fTopLine + node.FoldedBefore - 1;
  if node.IsInFold then
    tmpnode := node.Prev
  else
    tmpnode := fFoldTree.FindLastFold;
  if tmpnode.IsInFold and (tmpnode.StartLine + tmpnode.MergedLineCount = tpos + 1) then begin
    node := tmpnode;
    tpos := tpos - node.MergedLineCount;
  end;
  {$IFDEF SynFoldDebug}debugln(['FOLD-- CalculateMaps fTopLine:=', fTopLine, '  tpos=',tpos]);{$ENDIF}
  cnt := fLines.Count;
  for i := 0 to fLinesInWindow + 2 do begin
    if (tpos > cnt) or (tpos < 0) then begin
      // Past end of Text
      fTextIndexList[i] := -1;
      fFoldTypeList[i] := [];
    end else begin
      fTextIndexList[i] := tpos - 1; // TextIndex is 0-based
      fFoldTypeList[i] := FFoldProvider.LineCapabilities[tpos - 1];
      if (node.IsInFold) then begin
        if (tpos = node.SourceLine) then
          include(fFoldTypeList[i], cfCollapsedFold)
        else if node.IsHide and (tpos + 1 = node.SourceLine) then
          include(fFoldTypeList[i], cfCollapsedHide);
      end;

      inc(tpos);
      while (node.IsInFold) and (tpos >= node.StartLine) do begin
        tpos := tpos + node.MergedLineCount;
        node := node.Next;
      end;
    end;
  end;
end;

(* Lines *)
function TSynEditFoldedView.GetLines(index : Integer) : String;
begin
  if (index < -1) or (index > fLinesInWindow + 1) then
    exit(fLines[ScreenLineToTextIndex(Index)]);
  Result := fLines[fTextIndexList[index+1]];
end;

function TSynEditFoldedView.GetDisplayNumber(index : Integer) : Integer;
begin
  if (index < -1) or (index > fLinesInWindow + 1)
  or (fTextIndexList[index+1] < 0) then exit(-1);
  Result := fTextIndexList[index+1]+1;
end;

function TSynEditFoldedView.GetTextIndex(index : Integer) : Integer;
begin
  if (index < -1) or (index > fLinesInWindow + 1) then
    exit(ScreenLineToTextIndex(Index));
  Result := fTextIndexList[index+1];
end;

function TSynEditFoldedView.GetFoldType(index : Integer) : TSynEditFoldLineCapabilities;
begin
  if (index < -1) or (index > fLinesInWindow + 1) then exit([]);
  Result := fFoldTypeList[index+1];
end;

function TSynEditFoldedView.IsFolded(index : integer) : Boolean;
begin
  Result := fFoldTree.FindFoldForLine(index+1).IsInFold;
end;

procedure TSynEditFoldedView.SetHighLighter(AValue: TSynCustomHighlighter
  );
begin
  if not(AValue is TSynCustomFoldHighlighter) then
    AValue := nil;
  if FHighLighter = AValue then exit;
  FHighLighter := TSynCustomFoldHighlighter(AValue);
  FFoldProvider.HighLighter := FHighLighter;
  UnfoldAll;
end;

(* Folding *)

procedure TSynEditFoldedView.FoldAtLine(AStartLine : Integer;
  ColIndex : Integer = -1; ColCount : Integer = 1; Skip: Boolean = False;
  AVisibleLines: Integer = 1);
begin
  FoldAtViewPos(AStartLine + fTopLine, ColIndex, ColCount, Skip, AVisibleLines);
end;

procedure TSynEditFoldedView.FoldAtViewPos(AStartPos : Integer;
  ColIndex : Integer = -1; ColCount : Integer = 1; Skip: Boolean = False;
  AVisibleLines: Integer = 1);
begin
  FoldAtTextIndex(AStartPos - 1 + fFoldTree.FindFoldForFoldedLine(AStartPos).FoldedBefore,
                  ColIndex, ColCount, Skip, AVisibleLines);
end;

function TSynEditFoldedView.LengthForFoldAtTextIndex(ALine, AFoldIndex: Integer;
  HideLen: Boolean = False) : Integer;
var
  hl: TSynCustomFoldHighlighter;
begin
  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then
    exit(0);
  Result := hl.FoldLineLength(ALine, AFoldIndex);
  if HideLen then
    inc(Result);
end;

function TSynEditFoldedView.FoldNodeAtTextIndex(AStartIndex,
  ColIndex: Integer): TSynTextFoldAVLNode;
var
  tree: TSynTextFoldAVLTree;
begin
  Result := fFoldTree.FindFoldForLine(AStartIndex + 1, True);

  tree := fFoldTree;
  while (not Result.IsInFold) or (Result.SourceLine <> AStartIndex + 1) do begin
    if (not Result.IsInFold) then
      Result := tree.FindLastFold;
    while Result.IsInFold and (Result.SourceLine > AStartIndex + 1) do
      Result := Result.Prev;
    if not Result.IsInFold then break;

    if Result.IsInFold and (Result.SourceLine < AStartIndex + 1) then begin
      if Result.fData.Nested = nil then break;
      tree := fFoldTree.TreeForNestedNode(Result.fData, Result.StartLine);
      Result := tree.FindFirstFold;
      while Result.IsInFold and (Result.SourceLine < AStartIndex + 1) do
        Result := Result.Next;
    end
    else
      break;
  end;

  while Result.IsInFold and (Result.SourceLine = AStartIndex + 1) do begin
    if Result.FoldIndex = ColIndex then
      exit;
    if Result.fData.Nested = nil then break;
    Result := fFoldTree.TreeForNestedNode(Result.fData, Result.StartLine).FindFirstFold;
  end;
  Result.fData := nil;
end;

function TSynEditFoldedView.IsFoldedAtTextIndex(AStartIndex, ColIndex: Integer): Boolean;
begin
  Result := FoldNodeAtTextIndex(AStartIndex, ColIndex).IsInFold;
end;

function TSynEditFoldedView.LogicalPosToNodeIndex(AStartIndex: Integer; LogX: Integer;
  Previous: Boolean): Integer;
var
  hl: TSynCustomFoldHighlighter;
  c, i: Integer;
  nd: TSynFoldNodeInfo;
begin
  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then
    exit(0);
  // AStartIndex is 0-based
  // FoldTree is 1-based AND first line remains visble
  c := hl.FoldNodeInfoCount[AStartIndex, [sfaOpen, sfaFold]];
  if c = 0 then
    exit(-1);
  i := 0;
  while i < c do begin
    nd := hl.FoldNodeInfo[aStartIndex, i, [sfaOpen, sfaFold]];
    if (nd.LogXStart >= LogX) then begin
      dec(i);
      if not Previous then
        i := -1;
      break;
    end;
    if (nd.LogXEnd >= LogX) then
      break;
    inc(i);
  end;
  Result := i;
end;

procedure TSynEditFoldedView.CollapseDefaultFolds;
var
  i, j, c: Integer;
  hl: TSynCustomFoldHighlighter;
  nd: TSynFoldNodeInfo;
begin
  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then
    exit;

  i := 0;
  while i < fLines.Count do begin
     // Todo: Highlighter should return a list of types that can return default folded
     // Currently PascalHl Type 2 = Region
    c := hl.FoldOpenCount(i, 2);
    if c > 0 then begin
      c := hl.FoldNodeInfoCount[i, [sfaOpen, sfaFold]];
      j := 0;
      while j < c do begin
        nd := hl.FoldNodeInfo[i, j, [sfaOpen, sfaFold]];
        if (sfaDefaultCollapsed in nd.FoldAction) and
           (not IsFoldedAtTextIndex(i, j))
        then begin
          // TODO: detect default hide too
          // currently always VisibleLines=1 => since region only folds
          fFoldTree.InsertNewFold(i+2, j, LengthForFoldAtTextIndex(i, j), 1);
          if Assigned(fOnFoldChanged) then
            fOnFoldChanged(i);
        end;
      inc(j);
      end;
    end;
    inc(i);
  end;
  CalculateMaps;
end;

function TSynEditFoldedView.GetFoldDescription(AStartIndex, AStartCol, AEndIndex,
  AEndCol: Integer; AsText: Boolean = False; Extended: Boolean = False): String;
var
  FoldCoders: Array of TSynEditFoldExportCoder;

  function FoldCoderForType(AType: Pointer): TSynEditFoldExportCoder;
  var
    i, j: Integer;
  begin
    i := 0;
    j := length(FoldCoders);
    while (i < j) and (FoldCoders[i].FoldType <> AType) do
      inc(i);
    if (i = j) then begin
      SetLength(FoldCoders, i + 1);
      FoldCoders[i] := TSynEditFoldExportCoder.Create(AType);
    end;
    Result := FoldCoders[i];
  end;

var
  hl: TSynCustomFoldHighlighter;
  FoldHelper: TSynEditFoldExportStream;
  NodeIterator: TSynTextFoldAVLNodeNestedIterator;
  NdiHelper1: TSynFoldNodeInfoHelper;
  Node: TSynTextFoldAVLNode;
  NdInfo, NdInfo2: TSynFoldNodeInfo;
  entry: TFoldExportEntry;
  i: Integer;
  NodeFoldType: TSynEditFoldType;
begin
  Result := '';
  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then exit;

  if AEndIndex < 0 then AEndIndex := MaxInt;
  if AEndCol   < 0 then AEndCol   := MaxInt;

  Node := fFoldTree.FindFoldForLine(AStartIndex + 1, True);
  NodeIterator := TSynTextFoldAVLNodeNestedIterator.Create(Node);
  FoldHelper := TSynEditFoldExportStream.Create;
  NdiHelper1 := TSynFoldNodeInfoHelper.Create(hl);
  try
    if (AStartCol > 1) then
      while Node.IsInFold and (Node.StartLine = AStartIndex + 2) do begin
        NdInfo := NdiHelper1.GotoNodeOpenPos(Node);
        if (sfaInvalid in NdInfo.FoldAction) or (ndinfo.LogXStart >= AStartCol) then
          break;
        Node := NodeIterator.Next;
      end;
    dec(AStartCol);
    if not node.IsInFold then
      exit;

    (* Text stores fold length according to AVLNode
       Binary stores line-diff between highlighter open and close line
    *)
    if AsText then
    begin           (* *** Encode as Text for XML *** *)
      {$IFDEF SynFoldSaveDebug}
      DebugLnEnter(['TSynEditFoldedView.GetFoldDescription as Text']);
      {$ENDIF}
      NdInfo := NdiHelper1.GotoNodeOpenPos(Node);
      while Node.IsInFold and (Node.StartLine-2 <= AEndIndex) do
      begin
        if (node.StartLine > AStartIndex + 2) then AStartCol := 0;

        NodeFoldType := scftFold;
        if Node.SourceLineOffset = 0 then
          NodeFoldType := scftHide;
        if not(sfaDefaultCollapsed in NdInfo.FoldAction) then // Currently skip default nodes
          FoldCoderForType(NdInfo.FoldType).AddNode
                     (NdInfo.LogXStart, NdInfo.LineIndex, Node.FullCount, NodeFoldType);
        Node := NodeIterator.Next;
        if not Node.IsInFold then
          break;

        NdInfo := NdiHelper1.Next;
        while NdiHelper1.IsValid and (not NdiHelper1.IsAtNodeOpenPos(Node)) do begin
          // Add unfolded nodes
          if not(sfaDefaultCollapsed in NdInfo.FoldAction) then // Currently skip default nodes
            FoldCoderForType(NdInfo.FoldType).AddNode
                                 (NdInfo.LogXStart, NdInfo.LineIndex, 0, scftOpen);
          NdInfo := NdiHelper1.Next;
        end;
      end;

      for i := 0 to length(FoldCoders) - 1 do begin
        FoldCoders[i].Finish;
        FoldHelper.AppendMem(FoldCoders[i].Stream.Mem, FoldCoders[i].Stream.Len);
      end;
      FoldHelper.AddChecksum;
      FoldHelper.Compress;
      {$IFDEF SynFoldSaveDebug}
      DebugLnExit(['TSynEditFoldedView.GetFoldDescription as Text']);
      {$ENDIF}
    end             (* *** END: Encode as Text for XML *** *)
    else
    begin           (* *** Encode as Binary *** *)
      while Node.IsInFold and (Node.StartLine-2 <= AEndIndex) do
      begin
        if (node.StartLine > AStartIndex + 2) then
          AStartCol := 0;

        NdInfo2 := NdiHelper1.GotoNodeClosePos(Node);
        if (sfaInvalid in NdInfo2.FoldAction) or
           (NdInfo2.LineIndex > AEndIndex) or
           ((NdInfo2.LineIndex = AEndIndex) and (ndinfo2.LogXEnd > AEndCol))
        then begin
          node := NodeIterator.Next;
          continue;
        end;

        NdInfo := NdiHelper1.GotoNodeOpenPos(Node);

        with entry do begin
          LogX   := NdInfo.LogXStart - AStartCol;
          LogX2  := NdInfo.LogXEnd - ndinfo.LogXStart + (ndinfo.LogXStart - AStartCol);
          Line   := NdInfo.LineIndex - AStartIndex;
          ELogX  := NdInfo2.LogXStart;
          ELogX2 := NdInfo2.LogXEnd;
          ELine  := NdInfo2.LineIndex - AStartIndex;
          //if sfaLastLineClose in NdInfo2.FoldAction then
          //  ELine := -1; // unfinished fold
          FType  := PtrUInt(NdInfo.FoldType);
          LinesFolded := node.FullCount;
        end;
        FoldHelper.AppendMem(@entry, SizeOf(TFoldExportEntry));

        Node := NodeIterator.Next;
      end;
    end;            (* *** END: Encode as Binary *** *)

    Result := FoldHelper.Text;
  finally
    FoldHelper.Free;
    for i := 0 to length(FoldCoders) - 1 do
      FoldCoders[i].Free;
    NodeIterator.Free;
    NdiHelper1.Free;
  end;
end;

procedure TSynEditFoldedView.ApplyFoldDescription(AStartIndex, AStartCol, AEndIndex,
  AEndCol: Integer; FoldDesc: PChar; FoldDescLen: Integer; IsText: Boolean = False);
var
  FoldCoders: Array of TSynEditFoldExportCoder;

  function FoldCoderForType(AType: Pointer): TSynEditFoldExportCoder;
  var
    j: Integer;
  begin
    j := length(FoldCoders) - 1;
    while (j >= 0) and (FoldCoders[j] <> nil) and (FoldCoders[j].FoldType <> AType) do
      dec(j);
    if (j < 0) then
      Result := nil
    else
      Result := FoldCoders[j];
  end;

  procedure RemoveCoderForType(AType: Pointer);
  var
    j: Integer;
  begin
    j := length(FoldCoders) - 1;
    while (j >= 0) and (FoldCoders[j] <> nil) and (FoldCoders[j].FoldType <> AType) do
      dec(j);
    if (j >= 0) then begin
      debugln(['FoldState loading removed data for foldtype: ', PtrUInt(AType)]);
      FreeAndNil(FoldCoders[j]);
    end;
  end;


var
  hl: TSynCustomFoldHighlighter;
  FoldHelper: TSynEditFoldExportStream;
  NdiHelper1: TSynFoldNodeInfoHelper;
  NdInfo, ndinfo2: TSynFoldNodeInfo;
  i: Integer;
  Line, FL: Integer;
  entry: TFoldExportEntry;
  Coder: TSynEditFoldExportCoder;
  IsFold, IsHide: Boolean;
begin
  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then
    exit;
  if (FoldDesc = nil) or (FoldDescLen = 0) then exit;

  NdiHelper1 := TSynFoldNodeInfoHelper.Create(hl);
  FoldHelper := TSynEditFoldExportStream.Create;
  try
    FoldHelper.Mem := FoldDesc;
    FoldHelper.Len := FoldDescLen;

    if IsText then
    begin           (* *** Decode from Text for XML *** *)
      FoldHelper.Decompress;
      if not FoldHelper.VerifyChecksum then
        raise ESynEditError.Create('fold checksum error');

      i := 0;
      while not FoldHelper.EOF do begin
        SetLength(FoldCoders, i + 1);
        FoldCoders[i] := TSynEditFoldExportCoder.Create(FoldHelper);
        if not FoldCoders[i].ReadIsValid then
          break;
        inc(i);
      end;

      NdInfo := NdiHelper1.FirstOpen;

      while NdiHelper1.IsValid do begin
        if (sfaDefaultCollapsed in NdInfo.FoldAction) then begin // Currently skip default nodes
          NdInfo := NdiHelper1.Next;
          continue;
        end;
        Coder := FoldCoderForType(NdInfo.FoldType);
        if coder <> nil then begin
          i := LengthForFoldAtTextIndex(NdInfo.LineIndex, NdInfo.NodeIndex);
          case coder.ReadNode(NdInfo.LogXStart, NdInfo.LineIndex, i) of
            scftFold:  FoldAtTextIndex(NdInfo.LineIndex, NdInfo.NodeIndex);
            scftHide:  FoldAtTextIndex(NdInfo.LineIndex, NdInfo.NodeIndex, 1, False, 0);
            scftInvalid: RemoveCoderForType(NdInfo.FoldType);
          end;
        end;
        NdInfo := NdiHelper1.Next;
      end;
    end             (* *** END: Encode as Text for XML *** *)
    else
    begin           (* *** Decode from Binary *** *)
      entry.Line := 0;
      if AStartCol > 0 then
        dec(AStartCol);
      while not FoldHelper.EOF do begin
        if not FoldHelper.ReadMem(@entry, sizeof(TFoldExportEntry)) then
          break;
        if entry.Line > 0 then AStartCol := 0;

        Line := AStartIndex + entry.Line;
        if Line >= FLines.Count then
          continue;

        ndinfo :=NdiHelper1.GotoOpenAtChar(Line, entry.LogX);
        Fl := LengthForFoldAtTextIndex(Line, ndinfo.NodeIndex);
        IsFold := (sfaFoldFold in NdInfo.FoldAction) and (entry.LinesFolded = FL);
        IsHide := (sfaFoldHide in NdInfo.FoldAction) and (entry.LinesFolded = FL + 1);
        if (sfaInvalid in ndinfo.FoldAction) or
           (ndinfo.LogXStart <> entry.LogX + AStartCol) or
           (ndinfo.LogXEnd <> entry.LogX2 + AStartCol)  or
           //(ndinfo.FoldType <> entry.FType) or
           (not (IsHide or IsFold))
        then
          continue;

        ndinfo2 := NdiHelper1.FindClose;
        if (sfaInvalid in ndinfo2.FoldAction) or
           (ndinfo2.LogXStart <> entry.ELogX) or
           (ndinfo2.LogXEnd <> entry.ELogX2)
        then
          continue;

        i := 1;
        if IsHide then i := 0;;
        FoldAtTextIndex(Line, NdInfo.NodeIndex, 1, False, i);
      end;
    end;            (* *** END: Encode as Binary *** *)
  finally
    for i := 0 to length(FoldCoders) - 1 do
      FoldCoders[i].Free;
    FreeAndNil(FoldHelper);
    FreeAndNil(NdiHelper1);
  end;
end;

procedure TSynEditFoldedView.FoldAtTextIndex(AStartIndex : Integer;
  ColIndex : Integer = -1; ColCount : Integer = 1; Skip: Boolean = False;
  AVisibleLines: Integer = 1);
var
  NodeCount, top: Integer;
  hl: TSynCustomFoldHighlighter;
  down: Boolean;
  NFolded: TSynTextFoldAVLNode;
  IsHide: Boolean;
begin
  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then
    exit;
  top := TopTextIndex;

  // AStartIndex is 0-based
  // FoldTree is 1-based AND first line remains visble
  NodeCount := FoldProvider.FoldOpenCount(AStartIndex);
  if ColCount = 0 then
    ColCount := NodeCount;

  down := ColIndex < 0;
  if down then
    ColIndex := NodeCount + ColIndex;

  IsHide := AVisibleLines = 0;

  while ColCount > 0 do begin
    if (ColIndex < 0) or (ColIndex >= NodeCount) then break;
    NFolded := FoldNodeAtTextIndex(AStartIndex, ColIndex);
    // TODO: Check if position can Hide or fold
    if skip and (   ( (AVisibleLines=0) and NFolded.IsHide  ) or
                    ( (AVisibleLines>0) and NFolded.IsInFold  )   )
    then begin
      if down
      then dec(ColIndex)
      else inc(ColIndex);
      continue;
    end;

    if not NFolded.IsInFold then
      fFoldTree.InsertNewFold(AStartIndex+1+AVisibleLines, ColIndex,
                              LengthForFoldAtTextIndex(AStartIndex, ColIndex, IsHide),
                              AVisibleLines)
    else
    if (AVisibleLines=0) and (not NFolded.IsHide) then begin
      // upgrade to hide
      fFoldTree.RemoveFoldForNodeAtLine(NFolded, -1);
      fFoldTree.InsertNewFold(AStartIndex+1, ColIndex,
                              LengthForFoldAtTextIndex(AStartIndex, ColIndex, IsHide),
                              AVisibleLines);
    end;
    if down
    then dec(ColIndex)
    else inc(ColIndex);
    dec(ColCount);
  end;

  fTopLine := -1;  // make sure seting TopLineTextIndex, will do CalculateMaps;
  TopTextIndex := top;
  if Assigned(fOnFoldChanged) then
    fOnFoldChanged(AStartIndex);
end;

procedure TSynEditFoldedView.UnFoldAtLine(AStartLine : Integer;
  ColIndex : Integer = -1; ColCount : Integer = 0; Skip: Boolean = False;
  AVisibleLines: Integer = 1);
begin
  UnFoldAtViewPos(AStartLine + fTopLine, ColIndex, ColCount, Skip, AVisibleLines);
end;

procedure TSynEditFoldedView.UnFoldAtViewPos(AStartPos : Integer;
  ColIndex : Integer = -1; ColCount : Integer = 0; Skip: Boolean = False;
  AVisibleLines: Integer = 1);
begin
  UnFoldAtTextIndex(AStartPos - 1 + fFoldTree.FindFoldForFoldedLine(AStartPos).FoldedBefore,
                    ColIndex, ColCount, Skip, AVisibleLines);
end;

procedure TSynEditFoldedView.UnFoldAtTextIndex(AStartIndex : Integer;
  ColIndex : Integer = -1; ColCount : Integer = 0; Skip: Boolean = False;
  AVisibleLines: Integer = 1);
var
  top, c, r, r2 : Integer;
  hl: TSynCustomFoldHighlighter;
  down: Boolean;
  NFolded: TSynTextFoldAVLNode;
begin
  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then
    exit;
  top := TopTextIndex;
  c := FoldProvider.FoldOpenCount(AStartIndex);

  r := -1;
  if ColCount = 0 then begin
    r := fFoldTree.RemoveFoldForLine(AStartIndex+AVisibleLines+1); // r is 1-based num of first (ex-)hidden line
  end
  else begin
    down := ColIndex < 0;
    if down then
      ColIndex := c + ColIndex ;
    while ColCount > 0 do begin
      if (ColIndex < 0) or (ColIndex >= c) then break;
      NFolded := FoldNodeAtTextIndex(AStartIndex, ColIndex);
      if skip and (   ( (AVisibleLines=0) and not NFolded.IsHide  ) or
                      ( (AVisibleLines>0) and not NFolded.IsInFold  )   )
      then begin
        if down
        then dec(ColIndex)
        else inc(ColIndex);
        continue;
      end;
      r2 := fFoldTree.RemoveFoldForLine(AStartIndex+1+AVisibleLines, ColIndex);
      if r2 > 0 then dec(r2);
      if (r < 0) or (r2 < r) then r := r2;
      if down
      then dec(ColIndex)
      else inc(ColIndex);
      dec(ColCount);
    end;
  end;

  fTopLine := -1;  // make sure seting TopLineTextIndex, will do CalculateMaps;
  TopTextIndex := top;
  if Assigned(fOnFoldChanged) and (r >= 0) then
    fOnFoldChanged(Max(0, r - 2));
end;

procedure TSynEditFoldedView.UnFoldAtTextIndexCollapsed(AStartIndex: Integer);
var
  top, r: Integer;
begin
  top := TopTextIndex;
  r := fFoldTree.RemoveFoldForLine(AStartIndex+1) - 1;
  fTopLine := -1;  // make sure seting TopLineTextIndex, will do CalculateMaps;
  TopTextIndex := top;
  if Assigned(fOnFoldChanged) then
    fOnFoldChanged(r);
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
  c, i, l, top, t: Integer;
  hl: TSynCustomFoldHighlighter;
begin
  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then
    exit;

  t := 1; // TODO: Highlighter default type; or iterate through all types
  top := TopTextIndex;
  fFoldTree.Clear;
  i := 0;
  while i < fLines.Count do begin
    if (hl.FoldOpenCount(i, t) > 0)
    and (hl.FoldNestCount(i, t) > StartLevel) then begin
      c := hl.FoldOpenCount(i) -1;
      l := LengthForFoldAtTextIndex(i, c);
      // i is 0-based
      // FoldTree is 1-based AND first line remains visble
      fFoldTree.InsertNewFold(i+2, c, l, 1); // TODO: hide too? currently VisibleLines=1
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

function TSynEditFoldedView.FixFolding(AStart: Integer; AMinEnd: Integer;
  aFoldTree: TSynTextFoldAVLTree): Boolean;
var
  hl: TSynCustomFoldHighlighter;
  FirstchangedLine: Integer;

  function DoFixFolding(doStart: Integer; doMinEnd, AtColumn: Integer;
    doFoldTree: TSynTextFoldAVLTree; node: TSynTextFoldAVLNode) : Boolean;

    Procedure DoRemoveNode(var theNode: TSynTextFoldAVLNode);
    var
      tmpnode: TSynTextFoldAVLNode;
      l: Integer;
    begin
      Result := True;
      tmpnode := theNode.Prev;
      l := theNode.SourceLine;
      doFoldTree.RemoveFoldForNodeAtLine(theNode, -1); // Don't touch any nested node
      if tmpnode.IsInFold then theNode := tmpnode.Next
      else theNode := doFoldTree.FindFirstFold;
      if (FirstchangedLine < 0) or (l < FirstchangedLine) then
        FirstchangedLine := l;
    end;

  var
    FldLine, FldIndex, FldLen, FldCol: Integer;
    MaxCol, CurLen: Integer;
    PrevFldLine: Integer;
    SubTree: TSynTextFoldAVLTree;
    IsHide: Boolean;
  begin
    Result := False;
    FldLine := doStart;
    while node.IsInFold do begin
      PrevFldLine := FldLine;
      FldLine := node.SourceLine; // the 1-based cfCollapsed (last visible) Line (or 1st hidden)
      FldIndex := FldLine - 1;
      FldLen := node.FullCount;
      if (FldLen <= 0) then begin
        {$IFDEF SynFoldDebug}debugln(['>>FOLD-- FixFolding: Remove node with len<0 FldLine=', FldLine]);{$ENDIF}
        DoRemoveNode(node);
        continue;
      end;

      if (FldLine > PrevFldLine) then
        AtColumn := 0;
      // check the fold-length
      MaxCol := FoldProvider.FoldOpenCount(FldIndex) - 1;
      FldCol := node.FoldIndex;
      IsHide := node.SourceLineOffset = 0;
      if (FldCol < AtColumn) then FldCol := AtColumn;
      if (FldCol <= MaxCol) and (FldCol >= AtColumn) and
         (FldLen = LengthForFoldAtTextIndex(FldIndex, FldCol, IsHide)) then begin
        CurLen := FldLen;
      end
      else if (FldCol - 1 <= MaxCol) and (FldCol > AtColumn) and (FldCol > 0) and
         (FldLen = LengthForFoldAtTextIndex(FldIndex, FldCol - 1, IsHide)) then begin
        CurLen := FldLen;
        dec(FldCol);
      end
      else if (FldCol + 1 <= MaxCol) and (FldCol + 1 >= AtColumn) and
         (FldLen = LengthForFoldAtTextIndex(FldIndex, FldCol + 1, IsHide)) then begin
        CurLen := FldLen;
        inc(FldCol);
      end
      else
        CurLen := -1;

      if CurLen <> FldLen then begin
        {$IFDEF SynFoldDebug}debugln(['>>FOLD-- FixFolding: Remove node with len<>len FldLine=', FldLine, ' curlen=',CurLen, ' FldLen=',FldLen]);{$ENDIF}
        DoRemoveNode(node);
        continue;
      end;
      node.fData.FoldIndex := FldCol;
      AtColumn := FldCol + 1;

      if (node.fData.Nested <> nil) then begin
        SubTree := doFoldTree.TreeForNestedNode(node.fData, FldLine+1);
        CurLen := node.MergedLineCount;
        if DoFixFolding(FldLine, FldLine + CurLen + 1, AtColumn, SubTree, SubTree.FindFirstFold)
        then begin
          if CurLen > FldLen then begin
            node.fData.MergedLineCount:= max(node.FullCount,
              doFoldTree.TreeForNestedNode(node.fData, 0).LastFoldedLine + 1);
            if CurLen <> node.MergedLineCount then
              node.fData.AdjustParentLeftCount(node.MergedLineCount - CurLen);
          end;
          continue;
        end;
      end;

      // the node was ok
      if node.StartLine >= doMinEnd then break;
      node := node.Next;
    end;
  end;

var
  node, tmpnode: TSynTextFoldAVLNode;
begin
  {$IFDEF SynFoldDebug}debugln(['>>FOLD-- FixFolding: Start=', AStart, '  AMinEnd=',AMinEnd]);{$ENDIF}
  Result := false;
  if fLockCount > 0 then begin
    fNeedCaretCheck := true; // We may be here as a result of lines deleted/inserted
    if fNeedFixFrom < 0 then fNeedFixFrom := AStart
    else fNeedFixFrom := Min(fNeedFixFrom, AStart);
    fNeedFixMinEnd := Max(fNeedFixMinEnd, AMinEnd);
    exit;
  end;

  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then begin
    CalculateMaps;
    exit;
  end;

  node := aFoldTree.FindFoldForLine(aStart, true);
  if not node.IsInFold then node:= aFoldTree.FindLastFold;
  if not node.IsInFold then begin
    CalculateMaps;
    exit;
  end;
  If aMinEnd < node.StartLine then aMinEnd := node.StartLine; // XXX SourceLine

  // FullCount is allowed to be -1
  while node.IsInFold and (node.StartLine + node.FullCount + 1 >= aStart) do begin
    tmpnode := node.Prev;
    if tmpnode.IsInFold
    then node := tmpnode
    else break; // first node
  end;

  FirstchangedLine := -1;
  Result := DoFixFolding(-1, AMinEnd, 0, aFoldTree, node);
  CalculateMaps;
  if Assigned(fOnFoldChanged) and (FirstchangedLine >= 0) then
    fOnFoldChanged(FirstchangedLine);
  {$IFDEF SynFoldDebug}debugln(['<<FOLD-- FixFolding: DONE=', Result]);{$ENDIF}
end;

procedure TSynEditFoldedView.DoCaretChanged(Sender : TObject);
var
  i: Integer;
begin
  if fLockCount > 0 then begin
    fNeedCaretCheck := true;
    exit;
  end;
  i := TSynEditCaret(Sender).LinePos-1;
  {$IFDEF SynFoldDebug}if FoldedAtTextIndex[i] then debugln(['FOLD-- DoCaretChanged  about to unfold at Index=', i]);{$ENDIF}
  if FoldedAtTextIndex[i] then
    UnFoldAtTextIndexCollapsed(i);
end;

procedure TSynEditFoldedView.LineCountChanged(Sender: TSynEditStrings; AIndex, ACount : Integer);
begin
  {$IFDEF SynFoldDebug}debugln(['FOLD-- LineCountChanged AIndex=', AIndex, '  Acount=',ACount]);{$ENDIF}
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

function TSynEditFoldedView.OpenFoldCount(aStartIndex: Integer): Integer;
// Todo: move entirely to FoldProvider
var
  hl: TSynCustomFoldHighlighter;
begin
  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then
    exit(-1);
  Result := hl.FoldNestCount(AStartIndex-1) + FoldProvider.FoldOpenCount(AStartIndex);
end;

function TSynEditFoldedView.OpenFoldInfo(aStartIndex, ColIndex: Integer): TFoldViewNodeInfo;
var
  hl: TSynCustomFoldHighlighter;
  TypeCnt, Lvl: Integer;
  EndLvl, CurLvl: Array of integer;
  i, t, n, o: Integer;
  nd: TSynFoldNodeInfo;
  procedure GetEndLvl(l: Integer);
  var i: integer;
  begin
    for i := 1 to TypeCnt do begin
      EndLvl[i] := hl.FoldNestCount(l-1, i);
      EndLvl[i] := EndLvl[i] + FoldProvider.FoldOpenCount(l, i);
      CurLvl[i] := EndLvl[i];
    end
  end;
begin
  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then
    exit;

  TypeCnt := hl.FoldTypeCount;
  Lvl := hl.FoldNestCount(AStartIndex-1);
  i := 0;
  if ColIndex >= Lvl then begin
    n := ColIndex - Lvl;
    o :=  hl.FoldNodeInfoCount[aStartIndex, [sfaOpen, sfaFold]];
    nd := hl.FoldNodeInfo[aStartIndex, n, [sfaOpen, sfaFold]];
  end
  else begin
    SetLength(EndLvl, TypeCnt+1);
    SetLength(CurLvl, TypeCnt+1);
    GetEndLvl(aStartIndex);
    aStartIndex := aStartIndex + i;
    while (ColIndex < Lvl) and (aStartIndex > 0) do begin
      dec(aStartIndex);
      o := hl.FoldOpenCount(AStartIndex);
      if (o > 0) or (hl.FoldCloseCount(aStartIndex) > 0) then begin
        n := o;
        for i := hl.FoldNodeInfoCount[aStartIndex, []] - 1 downto 0 do begin
          nd := hl.FoldNodeInfo[aStartIndex, i, []];
          if not(sfaFold in nd.FoldAction) then
            continue;
          t := nd.FoldGroup;
          if sfaOpen in nd.FoldAction then begin
            dec(n);
            dec(CurLvl[t]);
            if CurLvl[t] < EndLvl[t] then begin
              dec(EndLvl[t]);
              dec(Lvl);
              if ColIndex = Lvl then begin
                break;
              end;
            end;
          end else
          if sfaClose in nd.FoldAction then begin
            inc(CurLvl[t]);
          end;
        end;
      end
      else
      if hl.FoldNestCount(AStartIndex-1) = 0 then break;
    end;
  end;
  Result.HNode := nd;
  Result.OpenCount := o;
  Result.Text := fLines[aStartIndex];
  if not(sfaInvalid in nd.FoldAction) then
    Result.Keyword := copy(Result.Text, 1 + nd.LogXStart, nd.LogXEnd-nd.LogXStart);
  Result.LineNum := aStartIndex + 1;
  Result.ColIndex := n;
  Result.FNode := FoldNodeAtTextIndex(aStartIndex, n);
end;

function TSynEditFoldedView.ExpandedLineForBlockAtLine(ALine : Integer;
  HalfExpanded: Boolean = True) : Integer;
var
  i, l : Integer;
  node: TSynTextFoldAVLNode;
  hl: TSynCustomFoldHighlighter;
begin
  Result := -1;
  hl := TSynCustomFoldHighlighter(HighLighter);
  if not assigned(hl) then
    exit;

  i := ALine;
  l := hl.FoldOpenCount(i - 1);
  if l > 0 then begin
    node := fFoldTree.FindFoldForLine(ALine, true);
    if node.IsInFold and (node.StartLine = ALine +1) then begin
      dec(l);
      if HalfExpanded then while (l >= 0) do begin
        if not IsFoldedAtTextIndex(ALine-1, l) then exit(ALine);
        dec(l);
      end;
      dec(i);
    end
    else
      exit(ALine);
  end
  else if hl.FoldCloseCount(i - 1) > 0 then
    dec(i);
  if (i < 0) or (hl.FoldNestCount(i-1) = 0) then
    exit;

  l := 0;
  while (i > 0) and (l >= 0) do begin // (FoldMinLevel[i] >= l) do
    dec(i);
    l := l - hl.FoldOpenCount(i);
    if l >= 0 then
      l := l + hl.FoldCloseCount(i);
  end;
  if (hl.FoldNestCount(i) > 0) then // TODO, check for collapsed at index = 0
    Result := i + 1;
end;

function TSynEditFoldedView.GetPhysicalCharWidths(Index: Integer): TPhysicalCharWidths;
begin
  Result := fLines.GetPhysicalCharWidths(ScreenLineToTextIndex(Index));
end;

function TSynEditFoldedView.CollapsedLineForFoldAtLine(ALine : Integer) : Integer;
// for hides => line before the hide
var
  node, tmpnode: TSynTextFoldAVLNode;
begin
  Result := -1;
  node := fFoldTree.FindFoldForLine(ALine, false);
  if node.IsInFold then begin
    tmpnode := node.Prev;
    while tmpnode.IsInFold and
          (tmpnode.StartLine + tmpnode.MergedLineCount = node.StartLine)
    do begin
      node := tmpnode;
      tmpnode := node.Prev;
    end;
    Result := node.StartLine-1;
    // Can be 0, if lines are hiden at begin of file
  end;
end;

{$IFDEF SynDebug}
procedure TSynEditFoldedView.debug;
begin
  fFoldTree.debug;
end;
{$ENDIF}

initialization
  InitNumEncodeValues;

end.

