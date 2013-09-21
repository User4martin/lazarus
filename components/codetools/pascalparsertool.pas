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
    TPascalParserTool enhances TMultiKeyWordListCodeTool.
    This tool parses the pascal code, makes simple syntax checks and provides
    a lot of useful parsing functions. It can either parse complete sources
    or parts of it.
    
}
unit PascalParserTool;

{$ifdef FPC}{$mode objfpc}{$endif}{$H+}

interface

{$I codetools.inc}

{ $DEFINE ShowIgnoreErrorAfter}
{ $DEFINE VerboseUpdateNeeded}

uses
  {$IFDEF MEM_CHECK}
  MemCheck,
  {$ENDIF}
  Classes, SysUtils, FileProcs, CodeToolsStrConsts, CodeTree, CodeAtom,
  CustomCodeTool, MultiKeyWordListTool, KeywordFuncLists, BasicCodeTools,
  CodeToolsStructs, LinkScanner, CodeCache, AVL_Tree;

type
  TProcHeadAttribute = (
    // extract attributes:
    phpWithStart,          // proc keyword e.g. 'function', 'class procedure'
    phpWithoutClassKeyword,// without 'class' proc keyword
    phpAddClassName,       // extract/add 'ClassName.'
    phpWithoutClassName,   // skip classname
    phpWithoutName,        // skip function name
    phpWithoutGenericParams,// skip <> after proc name
    phpWithoutParamList,   // skip param list
    phpWithVarModifiers,   // extract 'var', 'out', 'const'
    phpWithParameterNames, // extract parameter names
    phpWithoutParamTypes,  // skip colon, param types and default values
    phpWithHasDefaultValues,// extract the equal sign of default values
    phpWithDefaultValues,  // extract default values
    phpWithResultType,     // extract colon + result type
    phpWithOfObject,       // extract 'of object'
    phpWithCallingSpecs,   // extract cdecl; extdecl; popstack;
    phpWithProcModifiers,  // extract forward; alias; external; ...
    phpWithComments,       // extract comments and spaces
    phpInUpperCase,        // turn to uppercase
    phpCommentsToSpace,    // replace comments with a single space
                           //  (default is to skip unnecessary space,
                           //    e.g 'Do   ;' normally becomes 'Do;'
                           //    with this option you get 'Do ;')
    phpWithoutBrackets,    // skip start- and end-bracket of parameter list
    phpWithoutSemicolon,   // skip semicolon at end
    phpDoNotAddSemicolon,  // do not add missing semicolon at end
    // search attributes:
    phpIgnoreForwards,     // skip forward procs
    phpIgnoreProcsWithBody,// skip procs with begin..end
    phpIgnoreMethods,      // skip method bodies and definitions
    phpOnlyWithClassname,  // skip procs without the right classname
    phpFindCleanPosition,  // read til ExtractSearchPos
    // parse attributes:
    phpCreateNodes         // create nodes during reading
    );
  TProcHeadAttributes = set of TProcHeadAttribute;
  
  TParseProcHeadAttribute = (pphIsMethod, pphIsFunction, pphIsType,
     pphIsOperator, pphCreateNodes);
  TParseProcHeadAttributes =  set of TParseProcHeadAttribute;
  
  TProcHeadExtractPos = (phepNone, phepStart, phepName, phepParamList,
    phepResultType, phepSpecifiers);

  TSkipBracketCheck = (
    sbcStopOnRecord,
    sbcStopOnSemicolon
    );
  TSkipBracketChecks = set of TSkipBracketCheck;
const
  sbcStopOnAll = [sbcStopOnRecord,sbcStopOnSemicolon];

type

  TTreeRange = (trTillRange, trTillCursor, trTillCursorSection);

  TBuildTreeFlag = (
    btSetIgnoreErrorPos,
    btKeepIgnoreErrorPos,
    btCursorPosOutAllowed
    );
  TBuildTreeFlags = set of TBuildTreeFlag;

  { TPascalParserTool }
  
  TPascalParserTool = class(TMultiKeyWordListCodeTool)
  private
  protected
    // often used errors
    procedure SaveRaiseCharExpectedButAtomFound(c: char);
    procedure RaiseCharExpectedButAtomFound(c: char);
    procedure SaveRaiseStringExpectedButAtomFound(const s: string);
    procedure RaiseStringExpectedButAtomFound(const s: string);
    procedure SaveRaiseUnexpectedKeyWord;
    procedure RaiseUnexpectedKeyWord;
    procedure SaveRaiseIllegalQualifier;
    procedure RaiseIllegalQualifier;
    procedure SaveRaiseEndOfSourceExpected;
  protected
    // code extraction
    ExtractMemStream: TMemoryStream;
    ExtractSearchPos: integer;
    ExtractFoundPos: integer;
    ExtractProcHeadPos: TProcHeadExtractPos;
    procedure InitExtraction;
    function GetExtraction(InUpperCase: boolean): string;
    function ExtractStreamEndIsIdentChar: boolean;
    procedure ExtractNextAtom(AddAtom: boolean; Attr: TProcHeadAttributes);
  protected
    // parsing
    FLastCompilerMode: TCompilerMode;
    FLastCompilerModeSwitches: TCompilerModeSwitches;
    procedure FetchScannerSource(Range: TLinkScannerRange); override;
    // sections
    function KeyWordFuncSection: boolean;
    function KeyWordFuncEndPoint: boolean;
    // type/var/const/resourcestring
    function KeyWordFuncType: boolean;
    function KeyWordFuncVar: boolean;
    function KeyWordFuncConst: boolean;
    function KeyWordFuncResourceString: boolean;
    function KeyWordFuncExports: boolean;
    function KeyWordFuncLabel: boolean;
    function KeyWordFuncProperty: boolean;
    procedure ReadConst;
    procedure ReadConstExpr;
    // types
    procedure ReadTypeNameAndDefinition;
    procedure ReadGenericParamList;
    procedure ReadTypeReference;
    function KeyWordFuncTypeClass: boolean;
    function KeyWordFuncTypeClassInterface: boolean;
    function KeyWordFuncTypePacked: boolean;
    function KeyWordFuncTypeBitPacked: boolean;
    function KeyWordFuncSpecialize: boolean;
    function KeyWordFuncTypeArray: boolean;
    function KeyWordFuncTypeProc: boolean;
    function KeyWordFuncTypeSet: boolean;
    function KeyWordFuncTypeLabel: boolean;
    function KeyWordFuncTypeType: boolean;
    function KeyWordFuncTypeFile: boolean;
    function KeyWordFuncTypePointer: boolean;
    function KeyWordFuncTypeRecordCase: boolean;
    function KeyWordFuncTypeDefault: boolean;
    // procedures/functions/methods
    function KeyWordFuncProc: boolean;
    function KeyWordFuncBeginEnd: boolean;
    // class/object elements
    function KeyWordFuncClassSection: boolean;
    function KeyWordFuncClassConstSection: boolean;
    function KeyWordFuncClassTypeSection: boolean;
    function KeyWordFuncClassVarSection: boolean;
    function KeyWordFuncClassClass: boolean;
    function KeyWordFuncClassFinal: boolean;
    function KeyWordFuncClassMethod: boolean;
    function KeyWordFuncClassProperty: boolean;
    function KeyWordFuncClassIdentifier: boolean;
    // keyword lists
    procedure BuildDefaultKeyWordFunctions; override;
    function ParseType(StartPos, WordLen: integer): boolean;
    function ParseInnerClass(StartPos, WordLen: integer): boolean;
    function UnexpectedKeyWord: boolean;
    function EndOfSourceExpected: boolean;
    // read functions
    procedure ReadGenericParam;
    function ReadTilProcedureHeadEnd(ParseAttr: TParseProcHeadAttributes;
        var HasForwardModifier: boolean): boolean;
    function ReadConstant(ExceptionOnError, Extract: boolean;
        const Attr: TProcHeadAttributes): boolean;
    function ReadParamType(ExceptionOnError, Extract: boolean;
        const Attr: TProcHeadAttributes): boolean;
    function ReadParamList(ExceptionOnError, Extract: boolean;
        const Attr: TProcHeadAttributes): boolean;
    function ReadUsesSection(ExceptionOnError: boolean): boolean;
    function ReadRequiresSection(ExceptionOnError: boolean): boolean;
    function ReadContainsSection(ExceptionOnError: boolean): boolean;
    function ReadSubRange(ExceptionOnError: boolean): boolean;
    function ReadTilBracketCloseOrUnexpected(ExceptionOnNotFound: boolean;
      Flags: TSkipBracketChecks): boolean;
    function ReadTilBlockEnd(StopOnBlockMiddlePart,
        CreateNodes: boolean): boolean;
    function ReadTilBlockStatementEnd(ExceptionOnNotFound: boolean): boolean;
    function ReadBackTilBlockEnd(StopOnBlockMiddlePart: boolean): boolean;
    function ReadTilVariableEnd(ExceptionOnError, WithAsOperator: boolean): boolean;
    function ReadTilStatementEnd(ExceptionOnError,
        CreateNodes: boolean): boolean;
    function ReadWithStatement(ExceptionOnError, CreateNodes: boolean): boolean;
    function ReadOnStatement(ExceptionOnError, CreateNodes: boolean): boolean;
    procedure ReadVariableType;
    procedure ReadHintModifiers;
    function ReadTilTypeOfProperty(PropertyNode: TCodeTreeNode): boolean;
    function ReadTilGetterOfProperty(PropertyNode: TCodeTreeNode): boolean;
    procedure ReadGUID;
    procedure ReadClassInheritance(CreateChildNodes: boolean);
    procedure ReadSpecialize(CreateChildNodes: boolean);
    function WordIsPropertyEnd: boolean;
  public
    CurSection: TCodeTreeNodeDesc;

    ScannedRange: TLinkScannerRange; // excluding the section with a syntax error
    ScanTill: TLinkScannerRange;

    procedure ValidateToolDependencies; virtual;
    procedure BuildTree(Range: TLinkScannerRange);
    procedure BuildTree(OnlyInterface: boolean); deprecated;
    procedure BuildTreeAndGetCleanPos(TreeRange: TTreeRange;
        ScanRange: TLinkScannerRange;
        const CursorPos: TCodeXYPosition; out CleanCursorPos: integer;
        BuildTreeFlags: TBuildTreeFlags = []);
    procedure BuildTreeAndGetCleanPos(const CursorPos: TCodeXYPosition;
        out CleanCursorPos: integer; BuildTreeFlags: TBuildTreeFlags = []);
    procedure BuildSubTreeForBeginBlock(BeginNode: TCodeTreeNode); virtual;
    procedure BuildSubTreeForProcHead(ProcNode: TCodeTreeNode); virtual;
    procedure BuildSubTreeForProcHead(ProcNode: TCodeTreeNode;
        out FunctionResult: TCodeTreeNode);
    procedure BuildSubTree(CleanCursorPos: integer); virtual;
    procedure BuildSubTree(ANode: TCodeTreeNode); virtual;
    function NodeNeedsBuildSubTree(ANode: TCodeTreeNode): boolean; virtual;
    function BuildSubTreeAndFindDeepestNodeAtPos(
      P: integer; ExceptionOnNotFound: boolean): TCodeTreeNode;
    function BuildSubTreeAndFindDeepestNodeAtPos(StartNode: TCodeTreeNode;
      P: integer; ExceptionOnNotFound: boolean): TCodeTreeNode;

    function DoAtom: boolean; override;

    function FindFirstNodeOnSameLvl(StartNode: TCodeTreeNode): TCodeTreeNode;
    function FindNextNodeOnSameLvl(StartNode: TCodeTreeNode): TCodeTreeNode;
    function FindPrevNodeOnSameLvl(StartNode: TCodeTreeNode): TCodeTreeNode;

    // sections / scan range
    function FindRootNode(Desc: TCodeTreeNodeDesc): TCodeTreeNode;
    function FindInterfaceNode: TCodeTreeNode;
    function FindImplementationNode: TCodeTreeNode;
    function FindInitializationNode: TCodeTreeNode;
    function FindFinalizationNode: TCodeTreeNode;
    function FindMainBeginEndNode: TCodeTreeNode;
    function FindFirstSectionChild: TCodeTreeNode;
    function FindSectionNodeAtPos(P: integer): TCodeTreeNode;
    function FindScanRangeNode(Range: TLinkScannerRange): TCodeTreeNode;
    function FindScanRangeNodeAtPos(P: integer): TCodeTreeNode;

    function NodeHasParentOfType(ANode: TCodeTreeNode;
        NodeDesc: TCodeTreeNodeDesc): boolean;

    constructor Create;
    destructor Destroy; override;
    procedure CalcMemSize(Stats: TCTMemStats); override;
  end;
  
function ProcHeadAttributesToStr(Attr: TProcHeadAttributes): string;
function dbgs(Attr: TProcHeadAttributes): string; overload;


implementation


type
  TEndBlockType = (ebtBegin, ebtAsm, ebtTry, ebtCase, ebtRepeat, ebtIf,
    ebtRecord, ebtClass, ebtObject);
  TTryType = (ttNone, ttFinally, ttExcept);
  TIfType = (itNone, itThen, itElse);

function ProcHeadAttributesToStr(Attr: TProcHeadAttributes): string;
var
  a: TProcHeadAttribute;
  s: string;
begin
  Result:='';
  for a:=Low(TProcHeadAttribute) to High(TProcHeadAttribute) do begin
    if a in Attr then begin
      WriteStr(s, a);
      if Result<>'' then
        Result:=Result+',';
      Result:=Result+s;
    end;
  end;
end;

function dbgs(Attr: TProcHeadAttributes): string;
begin
  Result:=ProcHeadAttributesToStr(Attr);
end;

{ TPascalParserTool }

constructor TPascalParserTool.Create;
begin
  inherited Create;
end;

destructor TPascalParserTool.Destroy;
begin
  if ExtractMemStream<>nil then
    ExtractMemStream.Free;
  inherited Destroy;
end;

procedure TPascalParserTool.CalcMemSize(Stats: TCTMemStats);
begin
  inherited CalcMemSize(Stats);
  if ExtractMemStream<>nil then
    Stats.Add('TPascalParserTool.ExtractMemStream',
      ExtractMemStream.InstanceSize+ExtractMemStream.Size);
end;

procedure TPascalParserTool.BuildDefaultKeyWordFunctions;
begin
  inherited BuildDefaultKeyWordFunctions;
  with KeyWordFuncList do begin
    Add('PROGRAM',@KeyWordFuncSection);
    Add('LIBRARY',@KeyWordFuncSection);
    Add('PACKAGE',@KeyWordFuncSection);
    Add('UNIT',@KeyWordFuncSection);
    Add('INTERFACE',@KeyWordFuncSection);
    Add('IMPLEMENTATION',@KeyWordFuncSection);
    Add('INITIALIZATION',@KeyWordFuncSection);
    Add('FINALIZATION',@KeyWordFuncSection);

    Add('END',@KeyWordFuncEndPoint);
    Add('.',@KeyWordFuncEndPoint);

    Add('TYPE',@KeyWordFuncType);
    Add('VAR',@KeyWordFuncVar);
    Add('THREADVAR',@KeyWordFuncVar);
    Add('CONST',@KeyWordFuncConst);
    Add('RESOURCESTRING',@KeyWordFuncResourceString);
    Add('EXPORTS',@KeyWordFuncExports);
    Add('LABEL',@KeyWordFuncLabel);
    Add('PROPERTY',@KeyWordFuncProperty);

    Add('PROCEDURE',@KeyWordFuncProc);
    Add('FUNCTION',@KeyWordFuncProc);
    Add('CONSTRUCTOR',@KeyWordFuncProc);
    Add('DESTRUCTOR',@KeyWordFuncProc);
    Add('OPERATOR',@KeyWordFuncProc);
    Add('CLASS',@KeyWordFuncProc);

    Add('BEGIN',@KeyWordFuncBeginEnd);
    Add('ASM',@KeyWordFuncBeginEnd);
    
    DefaultKeyWordFunction:=@EndOfSourceExpected;
  end;
end;

function TPascalParserTool.ParseType(StartPos, WordLen: integer): boolean;
// KeyWordFunctions for parsing types
// after parsing CurPos is on atom behind type
var
  p: PChar;
begin
  if StartPos>SrcLen then exit(false);
  p:=@Src[StartPos];
  case UpChars[p^] of
  'A':
    if CompareSrcIdentifiers('ARRAY',p) then exit(KeyWordFuncTypeArray);
  'B':
    if CompareSrcIdentifiers('BITPACKED',p) then exit(KeyWordFuncTypeBitPacked);
  'C':
    case UpChars[p[1]] of
    'L': if CompareSrcIdentifiers('CLASS',p) then exit(KeyWordFuncTypeClass);
    'P': if CompareSrcIdentifiers('CPPCLASS',p) then exit(KeyWordFuncTypeClass);
    end;
  'D':
    if CompareSrcIdentifiers('DISPINTERFACE',p) then exit(KeyWordFuncTypeClassInterface);
  'F':
    case UpChars[p[1]] of
    'I': if CompareSrcIdentifiers('FILE',p) then exit(KeyWordFuncTypeFile);
    'U': if CompareSrcIdentifiers('FUNCTION',p) then exit(KeyWordFuncTypeProc);
    end;
  'I':
    if CompareSrcIdentifiers('INTERFACE',p) then exit(KeyWordFuncTypeClassInterface);
  'L':
    if CompareSrcIdentifiers('LABEL',p) then exit(KeyWordFuncTypeLabel);
  'O':
    if CompareSrcIdentifiers('OBJECT',p)
    or CompareSrcIdentifiers('OBJCCLASS',p)
    or CompareSrcIdentifiers('OBJCCATEGORY',p) then
      exit(KeyWordFuncTypeClass)
    else if CompareSrcIdentifiers('OBJCPROTOCOL',p) then
      exit(KeyWordFuncTypeClassInterface);
  'P':
    case UpChars[p[1]] of
    'A': if CompareSrcIdentifiers('PACKED',p) then exit(KeyWordFuncTypePacked);
    'R': if CompareSrcIdentifiers('PROCEDURE',p) then exit(KeyWordFuncTypeProc);
    end;
  'R':
    if CompareSrcIdentifiers('RECORD',p) then exit(KeyWordFuncTypeClass);
  'S':
    case UpChars[p[1]] of
    'E': if CompareSrcIdentifiers('SET',p) then exit(KeyWordFuncTypeSet);
    'P': if CompareSrcIdentifiers('SPECIALIZE',p) then exit(KeyWordFuncSpecialize);
    end;
  'T':
    if CompareSrcIdentifiers('TYPE',p) then exit(KeyWordFuncTypeType);
  '^': if WordLen=1 then exit(KeyWordFuncTypePointer);
  end;
  Result:=KeyWordFuncTypeDefault;
end;

function TPascalParserTool.ParseInnerClass(StartPos, WordLen: integer
  ): boolean;
// KeyWordFunctions for parsing in a class/object/record/interface
var
  p: PChar;
begin
  if StartPos>SrcLen then exit(false);
  p:=@Src[StartPos];
  case UpChars[p^] of
  'C':
    case UpChars[p[1]] of
    'A': if CompareSrcIdentifiers(p,'CASE') then exit(KeyWordFuncTypeRecordCase);
    'L': if CompareSrcIdentifiers(p,'CLASS') then exit(KeyWordFuncClassClass);
    'O': if CompareSrcIdentifiers(p,'CONSTRUCTOR') then exit(KeyWordFuncClassMethod)
         else if CompareSrcIdentifiers(p,'CONST') then exit(KeyWordFuncClassConstSection);
    end;
  'D':
    if CompareSrcIdentifiers(p,'DESTRUCTOR') then exit(KeyWordFuncClassMethod);
  'E':
    if CompareSrcIdentifiers(p,'END') then exit(false);
  'F':
    case UpChars[p[1]] of
    'U': if CompareSrcIdentifiers(p,'FUNCTION') then exit(KeyWordFuncClassMethod);
    'I': if CompareSrcIdentifiers(p,'FINAL') and Scanner.Values.IsDefined('CPUJVM')
         then exit(KeyWordFuncClassFinal);
    end;
  'P':
    case UpChars[p[1]] of
    'R':
      case UpChars[p[2]] of
      'I': if CompareSrcIdentifiers(p,'PRIVATE') then exit(KeyWordFuncClassSection);
      'O':
        case UpChars[p[3]] of
        'C': if CompareSrcIdentifiers(p,'PROCEDURE') then exit(KeyWordFuncClassMethod);
        'P': if CompareSrcIdentifiers(p,'PROPERTY') then exit(KeyWordFuncClassProperty);
        'T': if CompareSrcIdentifiers(p,'PROTECTED') then exit(KeyWordFuncClassSection);
        end;
      end;
    'U':
      if (UpChars[p[2]]='B') and (UpChars[p[3]]='L') and (UpChars[p[4]]='I') then
        case UpChars[p[5]] of
        'C': if CompareSrcIdentifiers(p,'PUBLIC') then exit(KeyWordFuncClassSection);
        'S': if CompareSrcIdentifiers(p,'PUBLISHED') then exit(KeyWordFuncClassSection);
        end;
    end;
  'R':
    if CompareSrcIdentifiers(p,'REQUIRED')
    and (CurNode.Parent.Desc=ctnObjCProtocol)
    then exit(KeyWordFuncClassSection);
  'S':
    if CompareSrcIdentifiers(p,'STATIC')
    and (CurNode.Parent.Desc=ctnObject) and (Scanner.Values.IsDefined('STATIC'))
    then
      exit(KeyWordFuncClassMethod)
    else if CompareSrcIdentifiers(p,'STRICT') then exit(KeyWordFuncClassSection);
  'T':
    if CompareSrcIdentifiers(p,'TYPE') then exit(KeyWordFuncClassTypeSection);
  'O':
    if CompareSrcIdentifiers(p,'OPTIONAL')
    and (CurNode.Parent.Desc=ctnObjCProtocol)
    then exit(KeyWordFuncClassSection);
  'V':
    if CompareSrcIdentifiers(p,'VAR') then exit(KeyWordFuncClassVarSection);
  '(','[':
    begin
      ReadTilBracketClose(true);
      exit(true);
    end;
  ';': exit(true);
  end;
  Result:=KeyWordFuncClassIdentifier;
end;

function TPascalParserTool.UnexpectedKeyWord: boolean;
begin
  Result:=false;
  SaveRaiseExceptionFmt(ctsUnexpectedKeyword,[GetAtom]);
end;

function TPascalParserTool.EndOfSourceExpected: boolean;
begin
  Result:=false;
  SaveRaiseEndOfSourceExpected;
end;

procedure TPascalParserTool.BuildTree(Range: TLinkScannerRange);
var
  Node: TCodeTreeNode;
  p: PChar;
  HasSourceType: Boolean;
  ok: Boolean;
  OldLastNode: TCodeTreeNode;
  OldLastPos: Integer;
begin
  {$IFDEF MEM_CHECK}CheckHeap('TPascalParserTool.BuildTree A '+IntToStr(MemCheck_GetMem_Cnt));{$ENDIF}
  {$IFDEF CTDEBUG}
  DebugLn('TPascalParserTool.BuildTree START ',MainFilename,' Range=',dbgs(Range),' ScannedRange=',dbgs(ScannedRange));
  {$ENDIF}
  ValidateToolDependencies;
  if not UpdateNeeded(Range) then begin
    // input is the same as last time -> output is the same
    // => if there was an error, raise it again
    //debugln(['TPascalParserTool.BuildTree no update needed, IgnoreErrorAfterValid=',IgnoreErrorAfterValid]);
    if LastErrorValid then begin
      // last time a parsing error occurred
      if IgnoreErrorAfterValid
      and IgnoreErrorAfterPositionIsInFrontOfLastErrMessage
      then begin
        // last error is behind needed code
        // => ignore
        exit;
      end;
      Node:=FindScanRangeNode(Range);
      if (Node<>nil) and not LastErrorIsInFrontOfCleanedPos(Node.StartPos)
      then begin
        // last error was after needed range
        // => ignore
        exit;
      end;
      // last error is in needed range => reraise
      RaiseLastError;
    end;
    exit;
  end;

  // an update is needed

  // The last error was in the area to be update.
  ClearLastError;
  //DebugLn('TPascalParserTool.BuildTree LINKSCANNING ... ',MainFilename,' Range=',dbgs(Range));
  //CheckHeap('TPascalParserTool.BuildTree B '+IntToStr(MemCheck_GetMem_Cnt));
  
  // scan code
  BeginParsing(Range);
  {$IFDEF VerboseUpdateNeeded}
  DebugLn(['TPascalParserTool.BuildTree PARSING ... LastScannedRange=',dbgs(ScannedRange),' new Range=',dbgs(Range),' ',MainFilename]);
  {$ENDIF}
  //debugln(['TPascalParserTool.BuildTree "',Src,'"']);

  // parse code and build codetree
  if Scanner.CompilerMode=cmDELPHI then
    WordIsKeyWordFuncList:=WordIsDelphiKeyWord
  else if Scanner.CompilerMode=cmMacPas then
    WordIsKeyWordFuncList:=WordIsMacPasKeyWord
  else
    WordIsKeyWordFuncList:=WordIsKeyWord;

  ok:=false;
  OldLastNode:=Tree.GetLastNode;
  OldLastPos:=0;
  if OldLastNode<>nil then
    OldLastPos:=OldLastNode.EndPos;
  try
    try
      ScanTill:=Range;
      ScannedRange:=lsrInit;
      if ord(Range)<=ord(ScannedRange) then exit;

      //WriteDebugTreeReport;
      //debugln(['TPascalParserTool.BuildTree Src=',Src]);

      // skip existing nodes
      CurNode:=Tree.Root;
      if CurNode<>nil then
        while CurNode.NextBrother<>nil do CurNode:=CurNode.NextBrother;
      //debugln(['TPascalParserTool.BuildTree CurNode=',CurNode.DescAsString]);
      if (CurNode=nil)
      or ((CurNode.Desc in AllSourceTypes) and (CurNode.FirstChild=nil)) then begin
        // parse source from the beginning

        if (CurPos.StartPos=1) and (Src<>'') then begin
          // skip shebang
          p:=PChar(Src);
          if (p[0]=#$EF) and (p[1]=#$BB) and (p[2]=#$BF) then begin
            // UTF-8 BOM
            inc(p,3);
          end;
          if (p[0]='#') and (p[1]='!') then begin
            // shebang
            while not (p^ in [#0,#10,#13]) do inc(p);
          end;
          CurPos.StartPos:=p-PChar(Src)+1;
          CurPos.EndPos:=CurPos.StartPos;
        end;

        // read source type and name
        HasSourceType:=true;
        ReadNextAtom;
        if UpAtomIs('UNIT') then
          CurSection:=ctnUnit
        else if UpAtomIs('PROGRAM') then
          CurSection:=ctnProgram
        else if UpAtomIs('PACKAGE') then
          CurSection:=ctnPackage
        else if UpAtomIs('LIBRARY') then
          CurSection:=ctnLibrary
        else begin
          // the source type is missing
          // this is allowed for program
          if UpAtomIs('USES') or UpAtomIs('TYPE') or UpAtomIs('VAR')
          or UpAtomIs('CONST') or UpAtomIs('RESOURCESTRING')
          or UpAtomIs('BEGIN') or UpAtomIs('PROCEDURE') or UpAtomIs('FUNCTION')
          or UpAtomIs('OPERATOR') then begin
            CurSection:=ctnProgram;
            HasSourceType:=false;
            CurPos.EndPos:=CurPos.StartPos;
          end else
            SaveRaiseExceptionFmt(ctsNoPascalCodeFound,[GetAtom]);
        end;
        if CurNode=nil then
          CreateChildNode;
        CurNode.Desc:=CurSection;
        ScannedRange:=lsrSourceType;
        if ord(Range)<=ord(ScannedRange) then exit;
        if HasSourceType then begin
          repeat
            ReadNextAtom; // read source name
            // program and library can use keywords
            if (CurPos.Flag<>cafWord)
            or (CurSection in [ctnUnit,ctnPackage]) then
              AtomIsIdentifierSaveE;
            ReadNextAtom; // read ';' (or 'platform;' or 'unimplemented;')
          until CurPos.Flag<>cafPoint;
        end;
        ScannedRange:=lsrSourceName;
        if ord(Range)<=ord(ScannedRange) then exit;
        if HasSourceType then begin
          if (CurSection=ctnProgram)
          and (CurPos.Flag=cafRoundBracketOpen) then begin
            repeat
              ReadNextAtom;
              if CurPos.Flag<>cafWord then
                AtomIsIdentifierSaveE;
              ReadNextAtom; // should be ',' or ')'
              if not (CurPos.Flag in [cafComma,cafRoundBracketClose]) then
                RaiseCharExpectedButAtomFound(')');
            until CurPos.Flag=cafRoundBracketClose;
            ReadNextAtom;
          end;
          if UpAtomIs('PLATFORM') then
            ReadNextAtom;
          if UpAtomIs('UNIMPLEMENTED') then
            ReadNextAtom;
          if UpAtomIs('LIBRARY') then
            ReadNextAtom;
          if UpAtomIs('EXPERIMENTAL') then
            ReadNextAtom;
          if UpAtomIs('DEPRECATED') then begin
            ReadNextAtom;
            if CurPos.Flag<>cafSemicolon then
              ReadConstant(true,false,[]);
          end;
          if (CurPos.Flag<>cafSemicolon) then
            SaveRaiseCharExpectedButAtomFound(';');
        end;
        if CurSection=ctnUnit then begin
          ReadNextAtom;
          CurNode.EndPos:=CurPos.StartPos;
          EndChildNode;
          if not UpAtomIs('INTERFACE') then
            SaveRaiseStringExpectedButAtomFound('"interface"');
          CreateChildNode;
          CurSection:=ctnInterface;
          CurNode.Desc:=CurSection;
        end;
        ScannedRange:=lsrInterfaceStart;
        if ord(Range)<=ord(ScannedRange) then exit;
      end else if CurNode.Desc=ctnEndPoint then begin
        // all parts were already parsed
        ScannedRange:=lsrEnd;
        ok:=true;
        //debugln(['TPascalParserTool.BuildTree ALL nodes were already parsed. Change was behind pascal source.']);
        exit;
      end else begin
        // some parts were already parsed
        CurSection:=CurNode.Desc;
        Node:=CurNode;
        case Node.Desc of
        ctnInterface: ScannedRange:=lsrInterfaceStart;
        ctnImplementation: ScannedRange:=lsrImplementationStart;
        ctnInitialization: ScannedRange:=lsrInitializationStart;
        ctnFinalization: ScannedRange:=lsrFinalizationStart;
        end;
        if ord(Range)<=ord(ScannedRange) then exit;

        //debugln(['TPascalParserTool.BuildTree SOME parts were already parsed Node=',Node.DescAsString]);
        Node.EndPos:=-1;
        if (Node.LastChild=nil) then begin
          // section was not parsed => reopen it
          MoveCursorToCleanPos(Node.StartPos);
          // skip keyword starting the section
          if Node.Desc in [ctnInterface,ctnImplementation]
          then
            ReadNextAtom;
          {$IFDEF VerboseUpdateNeeded}
          debugln(['TPascalParserTool.BuildTree scan section ',Node.DescAsString,' from start. First atom=',GetAtom]);
          {$ENDIF}
        end else begin
          // half parsed section
          //debugln(['TPascalParserTool.BuildTree scan a section from middle ...']);
          if (Node.LastChild.Desc=ctnUsesSection)
          and (Node.LastChild.FirstChild=nil) then begin
            // uses section was not parsed completely => reopen it
            {$IFDEF VerboseUpdateNeeded}
            debugln(['TPascalParserTool.BuildTree REOPEN uses section in ',Node.DescAsString]);
            {$ENDIF}
            Node:=Node.LastChild;
            Node.EndPos:=-1;
            MoveCursorToCleanPos(Node.StartPos);
          end else begin
            if Node.FirstChild.Desc=ctnUsesSection then begin
              // uses section is already parsed
              if Node.FirstChild.FirstChild=nil then
                RaiseException('TPascalParserTool.BuildTree inconsistency: uses section was not scanned completely and was not deleted');
              if ScannedRange<lsrMainUsesSectionEnd then
                ScannedRange:=lsrMainUsesSectionEnd
              else if ScannedRange=lsrImplementationStart then
                ScannedRange:=lsrImplementationUsesSectionEnd;
              if ord(Range)<=ord(ScannedRange) then exit;
            end;

            // for example: Node=ctnInterface, Node.LastChild=ctnTypeSection
            // Note: the half parsed section was behind this one and was deleted
            if Node.LastChild<>nil then begin
              {$IFDEF VerboseUpdateNeeded}
              debugln(['TPascalParserTool.BuildTree scan after ',Node.LastChild.DescAsString]);
              {$ENDIF}
              MoveCursorToCleanPos(Node.LastChild.EndPos);
            end else begin
              {$IFDEF VerboseUpdateNeeded}
              debugln(['TPascalParserTool.BuildTree scan at start of ',Node.DescAsString]);
              {$ENDIF}
              MoveCursorToCleanPos(Node.StartPos);
              ReadNextAtom;
            end;
          end;
        end;
        CurNode:=Node;
        {$IFDEF VerboseUpdateNeeded}
        debugln(['TPascalParserTool.BuildTree CurNode=',CurNode.DescAsString,' cursor="',dbgstr(copy(Src,CurPos.StartPos,40)),'"']);
        {$ENDIF}
        if not (CurNode.Desc in (AllCodeSections+[ctnUsesSection]))
        then
          // FetchScannerSource failed
          RaiseCatchableException('TPascalParserTool.BuildTree inconsistency');
      end;

      ReadNextAtom;
      {$IFDEF VerboseUpdateNeeded}
      debugln(['TPascalParserTool.BuildTree ScannedRange=',dbgs(ScannedRange),' CurNode=',CurNode.DescAsString,' first atom=',GetAtom,' Range=',dbgs(Range)]);
      {$ENDIF}

      if (CurNode.Desc in (AllSourceTypes+[ctnInterface]))
      or ((CurNode.Desc=ctnUsesSection) and (CurNode.Parent.Desc<>ctnImplementation))
      then begin
        // read main uses section
        if UpAtomIs('USES') then
          ReadUsesSection(true);
        //debugln(['TPascalParserTool.BuildTree AFTER reading main uses section Atom="',GetAtom,'"']);
        if ord(Range)<=ord(ScannedRange) then exit;
        ScannedRange:=lsrMainUsesSectionEnd;
        if ord(Range)<=ord(ScannedRange) then exit;
      end;

      if (CurNode.Desc=ctnPackage)
      and ((CurNode.FirstChild=nil) or (CurNode.LastChild.Desc=ctnUsesSection))
      then begin
        // read package requires and contains section
        if UpAtomIs('REQUIRES') then
          ReadRequiresSection(true);
        if UpAtomIs('CONTAINS') then
          ReadContainsSection(true);
        //debugln(['TPascalParserTool.BuildTree AFTER reading package requires+contains sections Atom="',GetAtom,'"']);
      end;

      if CurNode.GetNodeOfType(ctnImplementation)<>nil then begin
        {$IFDEF VerboseUpdateNeeded}
        debugln(['TPascalParserTool.BuildTree CONTINUE implementation ...']);
        {$ENDIF}
        ScannedRange:=lsrImplementationStart;
        if ord(Range)<=ord(ScannedRange) then exit;

        if (CurNode.Desc=ctnUsesSection)
        or ((CurNode.Desc=ctnImplementation) and (CurNode.FirstChild=nil)) then
        begin
          // read implementation uses section
          if UpAtomIs('USES') then
            ReadUsesSection(true);
          //debugln(['TPascalParserTool.BuildTree AFTER reading implementation uses section Atom="',GetAtom,'"']);
          if ord(Range)<=ord(ScannedRange) then exit;
        end;
        ScannedRange:=lsrImplementationUsesSectionEnd;
        if ord(Range)<=ord(ScannedRange) then exit;
      end;

      repeat
        //DebugLn('[TPascalParserTool.BuildTree] ALL ',GetAtom);
        if not DoAtom then break;
        if CurSection=ctnNone then
          break;
        ReadNextAtom;
      until (CurPos.StartPos>SrcLen);

      if (Range=lsrEnd) and (CurSection<>ctnNone) then
        SaveRaiseException(ctsEndOfSourceNotFound);

      ok:=true;
    finally
      FRangeValidTill:=ScannedRange;
      if not ok then begin
        if ord(Range)<=ord(ScannedRange) then
          ok:=true;
        // range reached or t here is an error in the next scan range
      end;
      Node:=Tree.GetLastNode;
      {$IFDEF VerboseUpdateNeeded}
      dbgout(['TPascalParserTool.BuildTree scanned ',
        BoolToStr(ok ,'till ','without error till '),
        dbgs(FRangeValidTill),' (wanted:',dbgs(ScanTill),')',
        ' Atom="',dbgstr(GetAtom),'" at ',CurPos.StartPos,'=',CleanPosToStr(CurPos.StartPos)]);
      if (Node<>nil) then
        dbgout([' LastNode=',Node.DescAsString,',Start=',Node.StartPos]);
      debugln;
      {$ENDIF}
      ScanTill:=lsrEnd;
      CloseUnfinishedNodes;
      if (OldLastNode<>Node) or ((Node<>nil) and (OldLastPos<>Node.EndPos)) then
        IncreaseTreeChangeStep(false);
    end;
  except
    {$IFDEF ShowIgnoreErrorAfter}
    DebugLn('TPascalParserTool.BuildTree ',MainFilename,' ERROR: ',LastErrorMessage);
    {$ENDIF}
    if (not IgnoreErrorAfterValid)
    or (not IgnoreErrorAfterPositionIsInFrontOfLastErrMessage) then
      raise;
    {$IFDEF ShowIgnoreErrorAfter}
    DebugLn('TPascalParserTool.BuildTree ',MainFilename,' IGNORING ERROR: ',LastErrorMessage);
    {$ENDIF}
  end;
  {$IFDEF CTDEBUG}
  DebugLn('[TPascalParserTool.BuildTree] END');
  {$ENDIF}
  {$IFDEF MEM_CHECK}
  CheckHeap('TPascalParserTool.BuildTree END '+IntToStr(MemCheck_GetMem_Cnt));
  {$ENDIF}
end;

procedure TPascalParserTool.BuildTree(OnlyInterface: boolean);
begin
  if OnlyInterface then
    BuildTree(lsrImplementationStart)
  else
    BuildTree(lsrEnd);
end;

procedure TPascalParserTool.BuildSubTreeForBeginBlock(BeginNode: TCodeTreeNode);
// reparse a quick parsed begin..end block and build the child nodes
//   create nodes for 'with' and 'case' statements

  procedure RaiseBeginExpected;
  begin
    SaveRaiseException(
       'TPascalParserTool.BuildSubTreeForBeginBlock: begin expected, but '
       +GetAtom+' found');
  end;

var
  MaxPos: integer;
begin
  if BeginNode=nil then
    RaiseException(
       'TPascalParserTool.BuildSubTreeForBeginBlock: BeginNode=nil');
  if BeginNode.Desc<>ctnBeginBlock then
    RaiseException(
       'TPascalParserTool.BuildSubTreeForBeginBlock: BeginNode.Desc='
       +BeginNode.DescAsString);
  if (BeginNode.SubDesc and ctnsNeedJITParsing)=0 then begin
    // block already parsed
    if (ctnsHasParseError and BeginNode.SubDesc)>0 then
      RaiseNodeParserError(BeginNode);
    exit;
  end;

  try
    BeginNode.SubDesc:=BeginNode.SubDesc and (not ctnsNeedJITParsing);
    // set CursorPos on 'begin'
    MoveCursorToNodeStart(BeginNode);
    ReadNextAtom;
    if not UpAtomIs('BEGIN') then
      RaiseBeginExpected;
    if BeginNode.EndPos<SrcLen then
      Maxpos:=BeginNode.EndPos
    else
      MaxPos:=SrcLen;
    repeat
      ReadNextAtom;
      if CurPos.StartPos>=MaxPos then break;
      if BlockStatementStartKeyWordFuncList.DoIdentifier(@Src[CurPos.StartPos])
      then begin
        if not ReadTilBlockEnd(false,true) then SaveRaiseEndOfSourceExpected;
      end else if UpAtomIs('WITH') then
        ReadWithStatement(true,true);
    until false;
  except
    {$IFDEF ShowIgnoreErrorAfter}
    DebugLn('TPascalParserTool.BuildSubTreeForBeginBlock ',MainFilename,' ERROR: ',LastErrorMessage);
    {$ENDIF}
    if (not IgnoreErrorAfterValid)
    or (not IgnoreErrorAfterPositionIsInFrontOfLastErrMessage) then begin
      raise;
    end;
    {$IFDEF ShowIgnoreErrorAfter}
    DebugLn('TPascalParserTool.BuildSubTreeForBeginBlock ',MainFilename,' IGNORING ERROR: ',LastErrorMessage);
    {$ENDIF}
  end;
end;

function TPascalParserTool.KeyWordFuncClassIdentifier: boolean;
{ parse class variable or type or const

  examples for variables:
    Name: TypeName;
    Name: UnitName.TypeName;
    i, j: integer;
    MyArray: array of array[EnumType] of array [Range] of TypeName;
    MyRecord: record
              i: packed record
                   j: integer;
                   k: record end;
                   case integer of
                     0: (a: integer);
                     1,2,3: (b: array[char] of char; c: char);
                     3: ( d: record
                               case byte of
                                 10: (i: integer; );
                                 11: (y: byte);
                             end;
                 end;
            end;
    MyPointer: ^integer;
    MyEnum: (MyEnumm1, MyEnumm2 := 2, MyEnummy3);
    MySet: set of (MyEnummy4 := 4 , MyEnummy5);
    MyRange: 3..5;
  examples for type:
    TCompareFunc = function(const Item1, Item2: T): Integer;
}
begin
  if CurNode.Desc = ctnTypeSection then begin
    // create type definition node
    ReadTypeNameAndDefinition;
  end else if CurNode.Desc = ctnConstSection then begin
    // create const definition node
    CreateChildNode;
    CurNode.Desc:=ctnConstDefinition;
    ReadConst;
    CurNode.EndPos:=CurPos.EndPos;
    EndChildNode;
  end else begin
    // create variable definition node
    CreateChildNode;
    CurNode.Desc:=ctnVarDefinition;
    ReadNextAtom;
    while CurPos.Flag=cafComma do begin
      // end variable definition
      CurNode.EndPos:=CurPos.StartPos;
      EndChildNode;
      // read next variable name
      ReadNextAtom;
      AtomIsIdentifierSaveE;
      // create variable definition node
      CreateChildNode;
      CurNode.Desc:=ctnVarDefinition;
      ReadNextAtom;
    end;
    if CurPos.Flag<>cafColon then
      SaveRaiseCharExpectedButAtomFound(':');
    // read type
    ReadVariableType;
  end;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncClassSection: boolean;
// change section in a class (public, private, protected, published, optional, required)
var
  OldSubSection: TCodeTreeNodeDesc;
  NewSection: TCodeTreeNodeDesc;
  SectionStart: Integer;
begin
  SectionStart:=CurPos.StartPos;
  NewSection:=ctnNone;
  if UpAtomIs('STRICT') then ReadNextAtom;
  if UpAtomIs('PUBLIC') then
    NewSection:=ctnClassPublic
  else if UpAtomIs('PRIVATE') then
    NewSection:=ctnClassPrivate
  else if UpAtomIs('PROTECTED') then
    NewSection:=ctnClassProtected
  else if UpAtomIs('PUBLISHED') then
    NewSection:=ctnClassPublished
  else if UpAtomIs('REQUIRED') then
    NewSection:=ctnClassRequired
  else if UpAtomIs('OPTIONAL') then
    NewSection:=ctnClassOptional
  else
    SaveRaiseStringExpectedButAtomFound('public');
  OldSubSection:=ctnNone;
  if CurNode.Desc in AllClassSubSections then begin
    // end sub section
    OldSubSection:=CurNode.Desc;
    CurNode.EndPos:=SectionStart;
    EndChildNode;
  end;
  // end last section
  CurNode.EndPos:=SectionStart;
  EndChildNode;
  // start new section
  CreateChildNode;
  CurNode.Desc:=NewSection;
  if (OldSubSection<>ctnNone)
  and (Scanner.CompilerMode=cmOBJFPC)
  and (Scanner.Values.IsDefined('VER2_4')) then begin
    // fpc 2.4.x did not reset sub section
    CreateChildNode;
    CurNode.Desc:=OldSubSection;
  end;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncClassConstSection: boolean;
begin
  if CurNode.Desc in AllClassSubSections then begin
    // end last sub section
    CurNode.EndPos:=CurPos.StartPos;
    EndChildNode;
  end;
  // start new section
  CreateChildNode;
  CurNode.Desc:=ctnConstSection;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncClassTypeSection: boolean;
begin
  if CurNode.Desc in AllClassSubSections then begin
    // end last sub section
    CurNode.EndPos:=CurPos.StartPos;
    EndChildNode;
  end;
  // start new section
  CreateChildNode;
  CurNode.Desc:=ctnTypeSection;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncClassVarSection: boolean;
{
  var
  class var
}
begin
  if CurNode.Desc in AllClassSubSections then begin
    // end last sub section
    CurNode.EndPos:=CurPos.StartPos;
    EndChildNode;
  end;
  // start new section
  CreateChildNode;
  if UpAtomIs('CLASS') then 
  begin
    CurNode.Desc:=ctnClassClassVar;
    ReadNextAtom;
  end
  else
    CurNode.Desc:=ctnVarSection;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncClassClass: boolean;
{ parse
    class procedure
    class property
    class constructor
    class destructor
    class operator
    class var
}
begin
  ReadNextAtom;
  if UpAtomIs('PROCEDURE') or UpAtomIs('FUNCTION') or UpAtomIs('CONSTRUCTOR')
  or UpAtomIs('DESTRUCTOR') or UpAtomIs('OPERATOR') then begin
    UndoReadNextAtom;
    Result:=KeyWordFuncClassMethod;
  end else if UpAtomIs('PROPERTY') then begin
    UndoReadNextAtom;
    Result:=KeyWordFuncClassProperty;
  end else if UpAtomIs('VAR') then begin
    UndoReadNextAtom;
    Result:=KeyWordFuncClassVarSection;
  end else
    SaveRaiseStringExpectedButAtomFound('procedure');
end;

function TPascalParserTool.KeyWordFuncClassFinal: boolean;
{ parse
    final var
    final class var
}
begin
  if CurNode.Desc in AllClassSubSections then begin
    // end last sub section
    CurNode.EndPos:=CurPos.StartPos;
    EndChildNode;
  end;
  // start new section
  CreateChildNode;
  CurNode.Desc:=ctnVarSection;
  ReadNextAtom;
  if UpAtomIs('CLASS') then
  begin
    CurNode.Desc:=ctnClassClassVar;
    ReadNextAtom;
  end;
  if not UpAtomIs('VAR') then
    SaveRaiseStringExpectedButAtomFound('var');
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncClassMethod: boolean;
{ parse class method

 examples:
   procedure ProcName;  virtual; abstract;
   function FuncName(Parameter1: Type1; Parameter2: Type2): ResultType;
   constructor Create;
   destructor Destroy;  override;
   class function X: integer;
   static function X: uNameSpace.Storage.Folders.PItem;
   function Intf.Method = ImplementingMethodName;
   class operator Inc(Rec: TRec1): TRec1;

 proc specifiers without parameters:
   stdcall, virtual, abstract, dynamic, overload, override, cdecl, inline,
   compilerproc, rtlproc

 proc specifiers with parameters:
   message <id or number>
   dispid <id>
   enumerator <id>
   }
var IsFunction, HasForwardModifier: boolean;
  ParseAttr: TParseProcHeadAttributes;
  IsOperator: Boolean;
begin
  if (CurNode.Desc in AllClassSubSections)
  and (CurNode.Parent.Desc in (AllClassBaseSections+AllClassInterfaces)) then begin
    CurNode.EndPos:=CurPos.StartPos;
    EndChildNode;
  end else if not (CurNode.Desc in (AllClassBaseSections+AllClassInterfaces))
  then begin
    //debugln(['TPascalParserTool.KeyWordFuncClassMethod ',CurNode.Parent.DescAsString,' ',CurNode.DescAsString]);
    SaveRaiseIdentExpectedButAtomFound;
  end;

  HasForwardModifier:=false;
  // create class method node
  CreateChildNode;
  CurNode.Desc:=ctnProcedure;
  // read method keyword
  if UpAtomIs('CLASS') or (UpAtomIs('STATIC')) then begin
    ReadNextAtom;
    if (not UpAtomIs('PROCEDURE')) and (not UpAtomIs('FUNCTION'))
    and (not UpAtomIs('CONSTRUCTOR')) and (not UpAtomIs('DESTRUCTOR'))
    and (not UpAtomIs('OPERATOR'))
    then begin
      SaveRaiseStringExpectedButAtomFound(ctsProcedureOrFunctionOrConstructorOrDestructor);
    end;
  end;
  // read procedure head
  IsFunction:=UpAtomIs('FUNCTION');
  IsOperator:=(not IsFunction) and UpAtomIs('OPERATOR');
  // read name
  ReadNextAtom;
  if IsOperator then
    AtomIsCustomOperator(true,true,true)
  else
    AtomIsIdentifierSaveE;
  // create node for procedure head
  CreateChildNode;
  CurNode.Desc:=ctnProcedureHead;
  ReadNextAtom;
  if (CurPos.Flag<>cafPoint) then begin
    // read rest
    CurNode.SubDesc:=ctnsNeedJITParsing;
    ParseAttr:=[pphIsMethod];
    if IsFunction then Include(ParseAttr,pphIsFunction);
    if IsOperator then Include(ParseAttr,pphIsOperator);
    ReadTilProcedureHeadEnd(ParseAttr,HasForwardModifier);
  end else begin
    // Method resolution clause (e.g. function Intf.Method = Method_Name)
    CurNode.Parent.Desc:=ctnMethodMap;
    // read Method name of interface
    ReadNextAtom;
    AtomIsIdentifierSaveE;
    //DebugLn(['TPascalParserTool.KeyWordFuncClassMethod ',GetAtom,' at ',CleanPosToStr(CurPos.StartPos,true)]);
    // read '='
    ReadNextAtomIsChar('=');
    // read implementing method name
    ReadNextAtom;
    AtomIsIdentifierSaveE;
    ReadNextAtom;
    if CurPos.Flag<>cafSemicolon then
      UndoReadNextAtom;
  end;
  // close procedure header
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  // close procedure / method map
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.ReadParamList(ExceptionOnError, Extract: boolean;
  const Attr: TProcHeadAttributes): boolean;
{ parse parameter list

 examples:
   procedure ProcName;  virtual; abstract;
   function FuncName(Parameter1: Type1; Parameter2: Type2): ResultType;
   constructor Create;
   destructor Destroy;  override;
   class function X: integer;
   function QWidget_mouseGrabber(): QWidgetH; cdecl;
   procedure Intf.Method = ImplementingMethodName;
   function CommitUrlCacheEntry; // only Delphi
   procedure MacProcName(c: char; ...); external;
}
var CloseBracket: char;
  Node: TCodeTreeNode;

  procedure ReadPrefixModifier;
  begin
    // read parameter prefix modifier
    if UpAtomIs('VAR') or UpAtomIs('CONST') or UpAtomIs('CONSTREF')
    or (UpAtomIs('OUT') and (cmsOut in Scanner.CompilerModeSwitches))
    then begin
      if not Extract then
        ReadNextAtom
      else
        ExtractNextAtom(phpWithVarModifiers in Attr,Attr);
    end;
  end;
  
  procedure ReadDefaultValue;
  begin
    // read =
    if not Extract then
      ReadNextAtom
    else
      ExtractNextAtom([phpWithDefaultValues,phpWithHasDefaultValues]*Attr<>[],Attr);
    ReadConstant(ExceptionOnError,
      Extract and (phpWithDefaultValues in Attr),Attr);
    if (phpCreateNodes in Attr) then begin
      Node:=CurNode;
      Node.SubDesc:=Node.SubDesc+ctnsHasDefaultValue;
      Node:=Node.PriorBrother;
      while (Node<>nil) and (Node.FirstChild=nil) do begin
        Node.SubDesc:=Node.SubDesc+ctnsHasDefaultValue;
        Node:=Node.PriorBrother;
      end;
    end;
  end;

begin
  Result:=false;
  if CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen] then begin
    if CurPos.Flag=cafRoundBracketOpen then
      CloseBracket:=')'
    else
      CloseBracket:=']';
    if (phpCreateNodes in Attr) then begin
      CreateChildNode;
      CurNode.Desc:=ctnParameterList;
    end;
    if not Extract then
      ReadNextAtom
    else begin
      ExtractNextAtom(not (phpWithoutBrackets in Attr),Attr);
      if (CurPos.Flag in [cafRoundBracketClose,cafEdgedBracketClose])
      and (Src[CurPos.StartPos] = CloseBracket)
      then begin
        // chomp empty brackets
        ExtractMemStream.Position := ExtractMemStream.Position - 1;
        ReadNextAtom;
        exit(true);
      end;
    end;
  end else
    CloseBracket:=#0;
  if not (CurPos.Flag in [cafRoundBracketClose,cafEdgedBracketClose]) then begin
    repeat
      if AtomIs('...') then begin
        // MacPas '...' VarArgs parameter
        if (Scanner.CompilerMode<>cmMacPas) then begin
          if ExceptionOnError then
            SaveRaiseIdentExpectedButAtomFound
          else
            exit;
        end;
        CreateChildNode;
        CurNode.Desc:=ctnVarArgs;
        CurNode.EndPos:=CurPos.EndPos;
        EndChildNode;
        ReadNextAtom;
        // parse end of parameter list
        if (CurPos.StartPos>SrcLen)
        or (Src[CurPos.StartPos]<>CloseBracket) then
          if ExceptionOnError then
            SaveRaiseCharExpectedButAtomFound(CloseBracket)
          else exit;
        break;
      end else begin
        ReadPrefixModifier;
        // read parameter name(s)
        repeat
          if not AtomIsIdentifier then begin
            if ExceptionOnError then
              AtomIsIdentifierSaveE;
            exit;
          end;
          if (phpCreateNodes in Attr) then begin
            CreateChildNode;
            CurNode.Desc:=ctnVarDefinition;
          end;
          if not Extract then
            ReadNextAtom
          else
            ExtractNextAtom(phpWithParameterNames in Attr,Attr);
          if CurPos.Flag<>cafComma then
            break
          else begin
            if (phpCreateNodes in Attr) then begin
              CurNode.EndPos:=LastAtoms.GetValueAt(0).EndPos;
              EndChildNode;
            end;
            if not Extract then
              ReadNextAtom
            else
              ExtractNextAtom(not (phpWithoutParamList in Attr),Attr);
          end;
        until false;
        if CurPos.Flag=cafColon then begin
          // read parameter type
          if not Extract then
            ReadNextAtom
          else
            // extract the colon if parameter names and types are requested
            ExtractNextAtom(
              [phpWithoutParamList,phpWithoutParamTypes,phpWithParameterNames]*Attr
              =[phpWithParameterNames],
              Attr);
          if not ReadParamType(ExceptionOnError,Extract,Attr) then exit;
          if CurPos.Flag=cafEqual then begin
            // read default value
            ReadDefaultValue;
          end;
        end else if (CurPos.Flag in [cafSemicolon,cafRoundBracketClose,
          cafEdgedBracketClose])
        then begin
          // no type -> variant
          if (phpCreateNodes in Attr) then begin
            CreateChildNode;
            CurNode.Desc:=ctnVariantType;
            CurNode.EndPos:=CurNode.StartPos;
            EndChildNode;
          end;
        end else
          RaiseCharExpectedButAtomFound(':');
        if (phpCreateNodes in Attr) then begin
          CurNode.EndPos:=CurPos.StartPos;
          EndChildNode;
        end;
      end;
      // read next parameter
      if (CurPos.StartPos>SrcLen) then
        if ExceptionOnError then
          SaveRaiseCharExpectedButAtomFound(CloseBracket)
        else exit;
      if (CurPos.Flag in [cafRoundBracketClose,cafEdgedBracketClose]) then
        break;
      if (CurPos.Flag<>cafSemicolon) then
        if ExceptionOnError then
          SaveRaiseCharExpectedButAtomFound(';')
        else exit;
      if not Extract then
        ReadNextAtom
      else
        ExtractNextAtom(not (phpWithoutParamList in Attr),Attr);
    until false;
  end;
  if (CloseBracket<>#0) then begin
    if Src[CurPos.StartPos]<>CloseBracket then begin
      if ExceptionOnError then
        SaveRaiseCharExpectedButAtomFound(CloseBracket)
      else
        exit;
    end;
    if (phpCreateNodes in Attr) then begin
      CurNode.EndPos:=CurPos.EndPos;
      EndChildNode;
    end;
    if not Extract then
      ReadNextAtom
    else
      ExtractNextAtom(not (phpWithoutBrackets in Attr),Attr);
  end;
  Result:=true;
end;

// Support generics in methods parameters and return types
procedure TPascalParserTool.ReadGenericParam;
// example:  <a,b<c.d.e>>
var
  Level: Integer;
begin
  Level:=0;
  repeat
    if CurPos.Flag in [cafPoint, cafComma] then begin
      ReadNextAtom;
      AtomIsIdentifierSaveE;
    end
    else if AtomIsChar('<') then begin
      inc(Level);
      ReadNextAtom;
      AtomIsIdentifierSaveE;
    end
    else if AtomIsChar('>') then begin
      dec(Level);
      if Level=0 then break;
    end else
      SaveRaiseCharExpectedButAtomFound('>');
    ReadNextAtom;
  until false;
  ReadNextAtom;
end;

function TPascalParserTool.ReadParamType(ExceptionOnError, Extract: boolean;
  const Attr: TProcHeadAttributes): boolean;
// after reading, CurPos is the atom after the type
var
  copying: boolean;
  IsArrayType: Boolean;
  IsFileType: Boolean;
  NeedIdentifier: boolean;
begin
  copying:=[phpWithoutParamList,phpWithoutParamTypes]*Attr=[];
  Result:=false;
  if (Scanner.CompilerMode=cmMacPas) and UpAtomIs('UNIV') then
    ReadNextAtom;
  if CurPos.Flag in AllCommonAtomWords then begin
    NeedIdentifier:=true;
    IsArrayType:=UpAtomIs('ARRAY');
    if IsArrayType then begin
      //DebugLn(['TPascalParserTool.ReadParamType is array ',MainFilename,' ',CleanPosToStr(curPos.StartPos)]);
      if (phpCreateNodes in Attr) then begin
        CreateChildNode;
        CurNode.Desc:=ctnOpenArrayType;
      end;
      if not Extract then ReadNextAtom else ExtractNextAtom(copying,Attr);
      if not UpAtomIs('OF') then begin
        if ExceptionOnError then
          SaveRaiseStringExpectedButAtomFound('"of"')
        else
          exit;
      end;
      if not Extract then ReadNextAtom else ExtractNextAtom(copying,Attr);
      if UpAtomIs('CONST') then begin
        if (phpCreateNodes in Attr) then begin
          CreateChildNode;
          CurNode.Desc:=ctnOfConstType;
        end;
        if not Extract then ReadNextAtom else ExtractNextAtom(copying,Attr);
        if (phpCreateNodes in Attr) then begin
          CurNode.EndPos:=CurPos.EndPos;
          EndChildNode;
          // close ctnOpenArrayType
          CurNode.EndPos:=CurPos.EndPos;
          EndChildNode;
        end;
        Result:=true;
        exit;
      end;
    end;
    IsFileType:=UpAtomIs('FILE');
    if IsFileType then begin
      if (phpCreateNodes in Attr) then begin
        CreateChildNode;
        CurNode.Desc:=ctnFileType;
      end;
      if not Extract then ReadNextAtom else ExtractNextAtom(copying,Attr);
      if UpAtomIs('OF') then begin
        if not Extract then ReadNextAtom else ExtractNextAtom(copying,Attr);
      end else begin
        NeedIdentifier:=false;
      end;
    end;
    if NeedIdentifier then begin
      if not AtomIsIdentifier then begin
        if ExceptionOnError then
          AtomIsIdentifierSaveE;
        exit;
      end;
      if (phpCreateNodes in Attr) then begin
        CreateChildNode;
        CurNode.Desc:=ctnIdentifier;
        CurNode.EndPos:=CurPos.EndPos;
      end;
      if not Extract then ReadNextAtom else ExtractNextAtom(copying,Attr);
      while CurPos.Flag=cafPoint do begin
        if not Extract then ReadNextAtom else ExtractNextAtom(copying,Attr);
        if not AtomIsIdentifier then begin
          if ExceptionOnError then
            AtomIsIdentifierSaveE;
          exit;
        end;
        if (phpCreateNodes in Attr) then
          CurNode.EndPos:=CurPos.EndPos;
        if not Extract then ReadNextAtom else ExtractNextAtom(copying,Attr);
      end;
      if (phpCreateNodes in Attr) then begin
        EndChildNode;
      end;
    end;
    if (phpCreateNodes in Attr) then begin
      if IsFileType then begin
        CurNode.EndPos:=CurPos.StartPos;
        EndChildNode;
      end;
      if IsArrayType then begin
        CurNode.EndPos:=CurPos.StartPos;
        EndChildNode;
      end;
    end;
  end else begin
    if ExceptionOnError then
      SaveRaiseStringExpectedButAtomFound(ctsIdentifier)
    else exit;
  end;
  if AtomIsChar('<') then
    ReadGenericParam;
  Result:=true;
end;

function TPascalParserTool.ReadTilProcedureHeadEnd(
  ParseAttr: TParseProcHeadAttributes;
  var HasForwardModifier: boolean): boolean;
{ parse parameter list, result type, of object, method specifiers

 examples:
   procedure ProcName;  virtual; abstract;
   function FuncName(Parameter1: Type1; Parameter2: Type2): ResultType;
   constructor Create;
   destructor Destroy;  override;
   class function X: integer;
   function QWidget_mouseGrabber(): QWidgetH; cdecl;
   procedure Intf.Method = ImplementingMethodName;
   function CommitUrlCacheEntry; // only Delphi
   procedure MacProcName(c: char; ...); external;
   operator + (dp1: TPoint; dp2: TPoint) dps: TPoint;
   Add('Inc(Rec: TRec1): TRec1;

   Delphi mode:
   Function TPOSControler.Logout; // missing function type
   function SomeMethod: IDictionary<string, IDictionary<K, V>>; // generics

 proc specifiers without parameters:
   stdcall, virtual, abstract, dynamic, overload, override, cdecl, inline

 proc specifiers with parameters:
   message <id or number>;
   external;
   external <id>;
   external name <id> delayed;
   external <id or number> name <id>;
   external <id or number> index <id>;
   [alias: <string constant>]
   [external name <string constant>]
   [internconst:in_const_round, external name 'FPC_ROUND'];
   dispid <id>;
   enumerator <id>
}

  procedure RaiseKeyWordExampleExpected;
  begin
    SaveRaiseExceptionFmt(
      ctsKeywordExampleExpectedButAtomFound,['alias',GetAtom]);
  end;

var IsSpecifier: boolean;
  Attr: TProcHeadAttributes;
begin
  //DebugLn('[TPascalParserTool.ReadTilProcedureHeadEnd] ',
  //'Method=',IsMethod,', Function=',IsFunction,', Type=',IsType);
  Result:=true;
  HasForwardModifier:=false;
  if CurPos.Flag=cafRoundBracketOpen then begin
    Attr:=[];
    if pphCreateNodes in ParseAttr then
      Include(Attr,phpCreateNodes);
    ReadParamList(true,false,Attr);
  end;
  if (pphIsOperator in ParseAttr) and (CurPos.Flag<>cafColon) then begin
    // read operator result identifier
    // example: operator =()IsEqual:boolean;
    AtomIsIdentifierSaveE;
    if (pphCreateNodes in ParseAttr) then begin
      CreateChildNode;
      CurNode.Desc:=ctnVarDefinition;
      CurNode.EndPos:=CurPos.EndPos;
      EndChildNode;
    end;
    ReadNextAtom;
  end;

  if ([pphIsFunction,pphIsOperator]*ParseAttr<>[]) then begin
    // read function result type
    if CurPos.Flag=cafColon then begin
      ReadNextAtom;
      if UpAtomIs('SPECIALIZE') then
        ReadSpecialize(pphCreateNodes in ParseAttr)
      else begin
        AtomIsIdentifierSaveE;
        if (pphCreateNodes in ParseAttr) then begin
          CreateChildNode;
          CurNode.Desc:=ctnIdentifier;
          CurNode.EndPos:=CurPos.EndPos;
        end;
        repeat
          ReadNextAtom;
          if AtomIsChar('<') then
            ReadGenericParam;
          if CurPos.Flag<>cafPoint then break;
          //  unitname.classname<T>.identifier
          ReadNextAtom;
          AtomIsIdentifierSaveE;
          if (pphCreateNodes in ParseAttr) then
            CurNode.EndPos:=CurPos.EndPos;
        until false;
        if (pphCreateNodes in ParseAttr) then
          EndChildNode;
      end;
    end
    else begin
      if (Scanner.CompilerMode<>cmDelphi) then
        SaveRaiseCharExpectedButAtomFound(':')
      else begin
        // Delphi Mode
        if CurPos.Flag=cafEqual then begin
          // read interface alias
          ReadNextAtom;
          AtomIsIdentifierSaveE;
          ReadNextAtom;
        end;
      end;
    end;
  end;
  if UpAtomIs('OF') then begin
    // read 'of object'
    if not (pphIsType in ParseAttr) then
      SaveRaiseCharExpectedButAtomFound(';');
    ReadNextAtom;
    if not UpAtomIs('OBJECT') then
      SaveRaiseStringExpectedButAtomFound('"object"');
    ReadNextAtom;
  end;
  // read procedures/method specifiers
  if CurPos.Flag=cafEND then begin
    UndoReadNextAtom;
    exit;
  end;
  if CurPos.Flag=cafSemicolon then
    ReadNextAtom;
  if (CurPos.StartPos>SrcLen) then
    SaveRaiseException(ctsSemicolonNotFound);
  repeat
    if CurPos.StartPos<=SrcLen then begin
      if pphIsMethod in ParseAttr then
        IsSpecifier:=IsKeyWordMethodSpecifier.DoIdentifier(@Src[CurPos.StartPos])
      else if pphIsType in ParseAttr then
        IsSpecifier:=IsKeyWordProcedureTypeSpecifier.DoIdentifier(@Src[CurPos.StartPos])
      else
        IsSpecifier:=IsKeyWordProcedureSpecifier.DoItCaseInsensitive(
                             Src,CurPos.StartPos,CurPos.EndPos-CurPos.StartPos);
    end else
      IsSpecifier:=false;
    if not IsSpecifier then begin
      // current atom does not belong to procedure/method declaration
      UndoReadNextAtom; // unread unknown atom
      break;
    end;
    // read specifier
    if UpAtomIs('MESSAGE') or UpAtomIs('DISPID') or UpAtomIs('ENUMERATOR')
    or UpAtomIs('DEPRECATED')
    then begin
      ReadNextAtom;
      if not (CurPos.Flag in [cafSemicolon,cafEND]) then
        ReadConstant(true,false,[]);
    end else if UpAtomIs('IS') then begin
      ReadNextAtom;
      if not UpAtomIs('NESTED') then
        SaveRaiseStringExpectedButAtomFound('nested');
      ReadNextAtom;
    end else if UpAtomIs('EXTERNAL') or UpAtomIs('WEAKEXTERNAL') or UpAtomIs('PUBLIC') then begin
      HasForwardModifier:=UpAtomIs('EXTERNAL') or UpAtomIs('WEAKEXTERNAL');
      ReadNextAtom;
      if CurPos.Flag<>cafSemicolon then begin
        if not UpAtomIs('NAME') then
          ReadConstant(true,false,[]);
        if UpAtomIs('NAME') or UpAtomIs('INDEX') then begin
          ReadNextAtom;
          ReadConstant(true,false,[]);
        end;
        if UpAtomIs('DELAYED') then
          ReadNextAtom;
      end;
    end else if UpAtomIs('ALIAS') then begin
      if not ReadNextAtomIsChar(':') then
        SaveRaiseCharExpectedButAtomFound(':');
      ReadNextAtom;
      ReadConstant(true,false,[]);
    end else if UpAtomIs('SYSCALL') then begin
      ReadNextAtom;
      AtomIsIdentifierSaveE;
      ReadNextAtom;
    end else if CurPos.Flag=cafEdgedBracketOpen then begin
      // read assembler alias   [public,alias: 'alternative name'],
      // internproc, internconst, external
      repeat
        ReadNextAtom;
        if not (CurPos.Flag in AllCommonAtomWords) then
          SaveRaiseStringExpectedButAtomFound(ctsKeyword);
        if not IsKeyWordProcedureBracketSpecifier.DoIdentifier(@Src[CurPos.StartPos])
        then
          RaiseKeyWordExampleExpected;
        if UpAtomIs('INTERNPROC') then
          HasForwardModifier:=true;

        if UpAtomIs('INTERNCONST') then begin
          ReadNextAtom;
          if AtomIsChar(':') then begin
            ReadNextAtom;
            AtomIsIdentifierSaveE;
            ReadNextAtom;
          end;
        end else if UpAtomIs('EXTERNAL') then begin
          HasForwardModifier:=true;
          ReadNextAtom;
          if not (CurPos.Flag in [cafComma,cafEdgedBracketClose]) then begin
            if not UpAtomIs('NAME') then
              ReadConstant(true,false,[]);
            if UpAtomIs('NAME') or UpAtomIs('INDEX') then begin
              ReadNextAtom;
              ReadConstant(true,false,[]);
            end;
          end;
        end else
          ReadNextAtom;
        if CurPos.Flag in [cafColon,cafEdgedBracketClose] then
          break;
        if CurPos.Flag<>cafComma then
          SaveRaiseCharExpectedButAtomFound(']');
      until false;
      if CurPos.Flag=cafColon then begin
        ReadNextAtom;
        if (not AtomIsStringConstant) and (not AtomIsIdentifier) then
          SaveRaiseStringExpectedButAtomFound(ctsStringConstant);
        ReadConstant(true,false,[]);
      end;
      if CurPos.Flag<>cafEdgedBracketClose then
        SaveRaiseCharExpectedButAtomFound(']');
      ReadNextAtom;
      if CurPos.Flag=cafEND then begin
        UndoReadNextAtom;
        exit;
      end;
    end else begin
      // read specifier without parameters
      if UpAtomIs('FORWARD') then HasForwardModifier:=true;
      ReadNextAtom;
      if CurPos.Flag=cafEND then begin
        UndoReadNextAtom;
        exit;
      end;
    end;
    // check semicolon
    if CurPos.Flag=cafSemicolon then begin
      ReadNextAtom;
    end else begin
      // Delphi/FPC allow procs without ending semicolon
    end;
  until false;
end;

function TPascalParserTool.ReadConstant(ExceptionOnError, Extract: boolean;
  const Attr: TProcHeadAttributes): boolean;
// after reading, the CurPos will be on the atom after the constant

 procedure RaiseConstantExpected;
 begin
   if ExceptionOnError then
     SaveRaiseStringExpectedButAtomFound(ctsConstant);
 end;

var
  BracketType: TCommonAtomFlag;
  p: PChar;
begin
  Result:=false;
  repeat
    // read unary operators
    repeat
      if (CurPos.StartPos>SrcLen) then begin
        RaiseConstantExpected;
        exit;
      end;
      p:=@Src[CurPos.StartPos];
      case p^ of
        '-','+','@':
          if CurPos.EndPos-CurPos.StartPos<>1 then break;
        'n','N':
          if not UpAtomIs('NOT') then break;
        'i','I':
          if not UpAtomIs('INHERITED') then break;
      else
        break;
      end;
      if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
    until false;
    // read operand
    if CurPos.Flag in AllCommonAtomWords then begin
      // word (identifier or keyword)
      if AtomIsKeyWord
      and (not IsKeyWordInConstAllowed.DoIdentifier(@Src[CurPos.StartPos])) then
      begin
        if ExceptionOnError then
          SaveRaiseUnexpectedKeyWord
        else exit;
      end;
      if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
      while CurPos.Flag=cafPoint do begin
        // Unitname.Constant
        if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
        if AtomIsKeyWord
        and (not IsKeyWordInConstAllowed.DoIdentifier(@Src[CurPos.StartPos]))
        then begin
          if ExceptionOnError then
            SaveRaiseUnexpectedKeyWord
          else exit;
        end;
        if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
      end;
      if CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen] then
      begin
        // type cast or constant array
        BracketType:=CurPos.Flag;
        if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
        if not ReadConstant(ExceptionOnError,Extract,Attr) then exit;
        if (BracketType=cafRoundBracketOpen)
        and (CurPos.Flag<>cafRoundBracketClose) then
          if ExceptionOnError then
            SaveRaiseCharExpectedButAtomFound(')')
          else exit;
        if (BracketType=cafEdgedBracketOpen)
        and (CurPos.Flag<>cafEdgedBracketClose) then
          if ExceptionOnError then
            SaveRaiseCharExpectedButAtomFound(']')
          else exit;
        if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
      end;
    end else if AtomIsNumber or AtomIsStringConstant then begin
      // number or '...' or #...
      if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
    end else begin
      if CurPos.Flag=cafRoundBracketOpen then begin
        // open bracket + ? + close bracket
        if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
        if not ReadConstant(ExceptionOnError,Extract,Attr) then exit;
        if (CurPos.Flag<>cafRoundBracketClose) then
          if ExceptionOnError then
            SaveRaiseCharExpectedButAtomFound(')')
          else exit;
        if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
      end else if CurPos.Flag=cafEdgedBracketOpen then begin
        // open bracket + ? + close bracket
        if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
        repeat
          if (CurPos.Flag=cafEdgedBracketClose) then break;
          // read
          if not ReadConstant(ExceptionOnError,Extract,Attr) then exit;
          if (CurPos.Flag=cafComma) or AtomIs('..') then begin
            // continue
            if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
          end else if (CurPos.Flag<>cafEdgedBracketClose) then begin
            if ExceptionOnError then
              SaveRaiseCharExpectedButAtomFound(']')
            else exit;
          end;
        until false;
        if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
      end else begin
        // syntax error
        RaiseConstantExpected;
        exit;
      end;
    end;
    if CurPos.StartPos>SrcLen then break;
    if not WordIsTermOperator.DoItCaseInsensitive(Src,CurPos.StartPos,
      CurPos.EndPos-CurPos.StartPos)
    then begin
      // not a operator
      break;
    end;
    // operator => read further
    if not Extract then ReadNextAtom else ExtractNextAtom(true,Attr);
  until false;
  Result:=true;
end;

function TPascalParserTool.ReadUsesSection(ExceptionOnError: boolean): boolean;
{ parse uses section

  examples:
    uses name1, name2 in '', name3.dot;
}
var
  IsUses: Boolean;
begin
  Result:=false;
  IsUses:=CurNode.Desc=ctnUsesSection;
  if (not IsUses) and (CurNode.Desc<>ctnContainsSection) then begin
    CreateChildNode;
    CurNode.Desc:=ctnUsesSection;
    IsUses:=true;
  end;
  if IsUses then begin
    if ord(ScannedRange)<ord(lsrMainUsesSectionStart) then
      ScannedRange:=lsrMainUsesSectionStart
    else if ord(ScannedRange)<ord(lsrImplementationUsesSectionStart) then
      ScannedRange:=lsrImplementationUsesSectionStart;
    if ord(ScanTill)<=ord(ScannedRange) then exit;
  end;
  repeat
    ReadNextAtom;  // read name
    if CurPos.Flag=cafSemicolon then break;
    AtomIsIdentifierSaveE;
    CreateChildNode;
    CurNode.Desc:=ctnUseUnit;
    repeat
      CurNode.EndPos:=CurPos.EndPos;
      ReadNextAtom;
      if CurPos.Flag<>cafPoint then break;
      ReadNextAtom;
      AtomIsIdentifierSaveE;
    until false;
    if UpAtomIs('IN') then begin
      ReadNextAtom;
      if not AtomIsStringConstant then
        if ExceptionOnError then
          SaveRaiseStringExpectedButAtomFound(ctsStringConstant)
        else exit;
      CurNode.EndPos:=CurPos.EndPos;
      ReadNextAtom;
    end;
    EndChildNode;
    if CurPos.Flag=cafSemicolon then break;
    if CurPos.Flag<>cafComma then
      if ExceptionOnError then
        SaveRaiseCharExpectedButAtomFound(';')
      else exit;
  until (CurPos.StartPos>SrcLen);
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;

  if IsUses then begin
    if ScannedRange=lsrMainUsesSectionStart then
      ScannedRange:=lsrMainUsesSectionEnd
    else if ScannedRange=lsrImplementationUsesSectionStart then
      ScannedRange:=lsrImplementationUsesSectionEnd;
    if ord(ScanTill)<=ord(ScannedRange) then exit;
  end;

  ReadNextAtom;
end;

function TPascalParserTool.ReadRequiresSection(ExceptionOnError: boolean): boolean;
{ parse requires section

  examples:
    requires name1, name2, name3;
}
begin
  CreateChildNode;
  CurNode.Desc:=ctnRequiresSection;
  repeat
    ReadNextAtom;  // read name
    if CurPos.Flag=cafSemicolon then break;
    AtomIsIdentifierSaveE;
    ReadNextAtom;
    if CurPos.Flag=cafSemicolon then break;
    if CurPos.Flag<>cafComma then
      if ExceptionOnError then
        SaveRaiseCharExpectedButAtomFound(';')
      else exit;
  until (CurPos.StartPos>SrcLen);
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  ReadNextAtom;
  Result:=true;
end;

function TPascalParserTool.ReadContainsSection(ExceptionOnError: boolean): boolean;
{ parse contains section
  The uses section of a Delphi package

  examples:
    contains name1, name2 in '', name3;
}
begin
  CreateChildNode;
  CurNode.Desc:=ctnContainsSection;
  Result:=ReadUsesSection(ExceptionOnError);
end;

function TPascalParserTool.ReadSubRange(ExceptionOnError: boolean): boolean;
{ parse subrange till ',' ';' ':' ']' or ')'

  examples:
    number..number
    identifier
    Low(identifier)..High(identifier)
    Pred(identifier)..Succ(identifier)
}
var RangeOpFound: boolean;
begin
  RangeOpFound:=false;
  repeat
    if CurPos.Flag in [cafSemicolon,cafColon,cafComma,cafRoundBracketClose,
                       cafEdgedBracketClose]
    then
      break;
    if CurPos.StartPos>SrcLen then
      SaveRaiseCharExpectedButAtomFound(';');
    if AtomIs('..') then begin
      if RangeOpFound then
        SaveRaiseCharExpectedButAtomFound(';');
      RangeOpFound:=true;
    end else if CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen] then
      ReadTilBracketClose(ExceptionOnError);
    ReadNextAtom;
  until false;
  Result:=true;
end;

function TPascalParserTool.ReadTilBracketCloseOrUnexpected(
  ExceptionOnNotFound: boolean; Flags: TSkipBracketChecks): boolean;
{ Cursor must be on round/edged bracket open
  After parsing cursor will be on closing bracket or on the unexpected atom
}
type
  TStackItemType = (
    siNone,
    siRoundBracketOpen,
    siEdgedBracketOpen,
    siRecord
    );
  TStackItem = record
    Typ: TStackItemType;
    StartPos: integer;
  end;
  PStackItem = ^TStackItem;
var
  Stack: array[0..16] of TStackItem;
  ExtStack: PStackItem;
  ExtStackCapacity: integer;
  Ptr: integer;
  Top: TStackItemType;
  p: PChar;

  procedure Push(Item: TStackItemType);
  var
    p: Integer;
  begin
    inc(Ptr);
    if Ptr<=High(Stack) then begin
      Stack[Ptr].Typ:=Item;
      Stack[Ptr].StartPos:=CurPos.StartPos;
    end else begin
      // need ExStack
      if (ExtStack=nil) then begin
        ExtStackCapacity:=10;
        GetMem(ExtStack,SizeOf(TStackItem)*ExtStackCapacity);
      end else begin
        ExtStackCapacity:=ExtStackCapacity*2;
        ReAllocMem(ExtStack,SizeOf(TStackItem)*ExtStackCapacity);
      end;
      p:=Ptr-High(Stack)-1;
      ExtStack[p].Typ:=Item;
      ExtStack[p].StartPos:=CurPos.StartPos;
    end;
    Top:=Item;
  end;

  procedure Pop;
  begin
    dec(Ptr);
    if Ptr<0 then
      Top:=siNone
    else if Ptr<=High(Stack) then
      Top:=Stack[Ptr].Typ
    else
      Top:=ExtStack[Ptr-High(Stack)-1].Typ;
  end;

  function GetTopPos: integer;
  begin
    if Ptr<0 then
      Result:=0
    else if Ptr<=High(Stack) then
      Result:=Stack[Ptr].StartPos
    else
      Result:=ExtStack[Ptr-High(Stack)-1].StartPos;
  end;

  procedure Unexpected;
  var
    p: LongInt;
    Msg: String;
    f: String;
  begin
    ReadTilBracketCloseOrUnexpected:=false;
    if not ExceptionOnNotFound then exit;
    // the unexpected keyword is wrong, but probably the closing bracket is
    // missing and the method has read too far
    p:=GetTopPos;
    CleanPosToCaret(p,ErrorNicePosition);
    case Top of
    siNone: Msg:=crsClosingBracketNotFound;
    siRoundBracketOpen: Msg:=crsBracketNotFound;
    siEdgedBracketOpen: Msg:=crsBracketNotFound2;
    siRecord: Msg:=crsRecordEndNotFound;
    end;
    if CurPos.StartPos<=SrcLen then begin
      if ErrorNicePosition.Code<>nil then
        f:=ErrorNicePosition.Code.Filename
      else
        f:='';
      Msg:=Format(crsFoundUnexpectedAt, [Msg, GetAtom, CleanPosToRelativeStr(
        CurPos.StartPos, f)]);
    end;
    SaveRaiseException(Msg,not CleanPosToCaret(p,ErrorNicePosition));
  end;

begin
  Result:=true;
  Ptr:=-1;
  ExtStack:=nil;
  if CurPos.Flag=cafRoundBracketOpen then
    Push(siRoundBracketOpen)
  else if CurPos.Flag=cafEdgedBracketOpen then
    Push(siEdgedBracketOpen)
  else
    SaveRaiseBracketOpenExpectedButAtomFound;
  try
    repeat
      ReadNextAtom;
      //debugln(['TPascalParserTool.ReadTilBracketCloseOrUnexpected ',GetAtom]);
      case CurPos.Flag of

      cafNone:
        if CurPos.StartPos>SrcLen then Unexpected;

      cafSemicolon:
        if sbcStopOnSemicolon in Flags then Unexpected;

      cafRoundBracketOpen:
        Push(siRoundBracketOpen);

      cafRoundBracketClose:
        if Top=siRoundBracketOpen then begin
          if Ptr=0 then exit(true);
          Pop;
        end else
          Unexpected;

      cafEdgedBracketOpen:
        Push(siEdgedBracketOpen);

      cafEdgedBracketClose:
        if Top=siEdgedBracketOpen then begin
          if Ptr=0 then exit(true);
          Pop;
        end else
          Unexpected;

      cafWord:
        begin
          p:=@Src[CurPos.StartPos];
          case UpChars[p^] of
          'A':
            case UpChars[p[1]] of
            'S': if UpAtomIs('ASM') then Unexpected;
            end;
          'B':
            case UpChars[p[1]] of
            'E': if UpAtomIs('BEGIN') then Unexpected;
            end;
          'C':
            case UpChars[p[1]] of
            'O': if UpAtomIs('CONST') then Unexpected;
            end;
          'D':
            case UpChars[p[1]] of
            'O': if UpAtomIs('DO') then Unexpected;
            end;
          'E':
            if UpAtomIs('END') then begin
              if Top=siRecord then
                Pop
              else
                Unexpected;
            end;
          'I':
            case UpChars[p[1]] of
            'N':
              case UpChars[p[2]] of
              'I': if UpAtomIs('INITIALIZATION') then Unexpected;
              'T': if UpAtomIs('INTERFACE') then Unexpected;
              end;
            'M': if UpAtomIs('IMPLEMENTATION') then Unexpected;
            end;
          'F':
            case UpChars[p[1]] of
            'I':
              if UpAtomIs('FINALIZATION')
              or UpAtomIs('FINALLY')
              then Unexpected;
            'O': if UpAtomIs('FOR') then Unexpected;
            end;
          'L':
            case UpChars[p[1]] of
            'A': if UpAtomIs('LABEL') then Unexpected;
            end;
          'P':
            case UpChars[p[1]] of
            'U':
              case UpChars[p[2]] of
              'B':
                if UpAtomIs('PUBLIC')
                or UpAtomIs('PUBLISHED') then Unexpected;
              end;
            'R':
              case UpChars[p[2]] of
              'I': if UpAtomIs('PRIVATE') then Unexpected;
              'O': if UpAtomIs('PROTECTED') then Unexpected;
              end;
            end;
          'R':
            case UpChars[p[1]] of
            'E':
              case UpChars[p[2]] of
              'C':
                if UpAtomIs('RECORD') then begin
                  if sbcStopOnRecord in Flags then
                    Unexpected
                  else
                    Push(siRecord);
                end;
              'P': if UpAtomIs('REPEAT') then Unexpected;
              'S': if UpAtomIs('RESOURCESTRING') then Unexpected;
              end;
            end;
          'T':
            case UpChars[p[1]] of
            'R': if UpAtomIs('TRY') then Unexpected;
            end;
          'V':
            case UpChars[p[1]] of
            'A': if UpAtomIs('VAR') then Unexpected;
            end;
          'W':
            case UpChars[p[1]] of
            'H': if UpAtomIs('WHILE') then Unexpected;
            end;
          end;
        end;
      end;
    until false;
  finally
    if ExtStack<>nil then FreeMem(ExtStack);
  end;
end;

function TPascalParserTool.KeyWordFuncClassProperty: boolean;
{ parse class/object property

 examples:
   property Visible;
   property Count: integer;
   property Color: TColor read FColor write SetColor;
   property Items[Index1, Index2: integer]: integer read GetItems; default;
   property X: integer index 1 read GetCoords write SetCoords stored IsStored; deprecated;
   property Col8: ICol8 read FCol8 write FCol8 implements ICol8, IColor;
   property Value: Integer read FCurrent; enumerator Current;
   property Visible: WordBool readonly dispid 401; experimental; platform;

   property specifiers before semicolon:
     index <id or number>, read <id>, write <id>, stored <id>, default <constant>,
     implements <id>[,<id>...], nodefault
   for dispinterfaces:
     dispid <number>, readonly, writeonly
   property modifiers after semicolon:
     default, deprecated, enumerator <id>
}

  procedure RaiseSemicolonAfterPropSpecMissing(const s: string);
  begin
    SaveRaiseExceptionFmt(ctsSemicolonAfterPropSpecMissing,[s,GetAtom]);
  end;

begin
  if (CurNode.Desc in AllClassSubSections)
  and (CurNode.Parent.Desc in AllClassBaseSections) then begin
    CurNode.EndPos:=CurPos.StartPos;
    EndChildNode;
  end else if not (CurNode.Desc in (AllClassBaseSections+AllClassInterfaces)) then
    SaveRaiseIdentExpectedButAtomFound;
  // create class method node
  CreateChildNode;
  CurNode.Desc:=ctnProperty;
  // read property Name
  if UpAtomIs('CLASS') then begin
    ReadNextAtom;
    if not UpAtomIs('PROPERTY') then
      SaveRaiseStringExpectedButAtomFound('property');
  end;
  ReadNextAtom;
  AtomIsIdentifierSaveE;
  ReadNextAtom;
  if CurPos.Flag=cafEdgedBracketOpen then begin
    // read parameter list
    ReadTilBracketClose(true);
    ReadNextAtom;
  end;
  while (CurPos.StartPos<=SrcLen) do begin
    case CurPos.Flag of
    cafSemicolon: break;
    cafEnd:       break;
    cafWord:  if WordIsPropertyEnd then break;
    end;
    ReadNextAtom;
  end;
  if CurPos.Flag=cafSemicolon then begin
    // read modifiers
    ReadNextAtom;
    if UpAtomIs('DEFAULT') then begin
      ReadNextAtom;
      if CurPos.Flag<>cafSemicolon then
        RaiseSemicolonAfterPropSpecMissing('default');
    end else if UpAtomIs('NODEFAULT') then begin
      ReadNextAtom;
      if CurPos.Flag<>cafSemicolon then
        RaiseSemicolonAfterPropSpecMissing('nodefault');
    end else if UpAtomIs('ENUMERATOR') then begin
      ReadNextAtom;
      AtomIsIdentifierSaveE;
      ReadNextAtom;
      if CurPos.Flag<>cafSemicolon then
        RaiseSemicolonAfterPropSpecMissing('enumerator');
    end else
      UndoReadNextAtom;

    if CurPos.Flag=cafSemicolon then
      ReadHintModifiers;

  end else
    UndoReadNextAtom;
  // close property
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.DoAtom: boolean;
begin
  //DebugLn('[TPascalParserTool.DoAtom] A ',DbgS(CurKeyWordFuncList));
  if (CurPos.StartPos<=SrcLen) and (CurPos.EndPos>CurPos.StartPos) then begin
    if IsIdentStartChar[Src[CurPos.StartPos]] then
      Result:=KeyWordFuncList.DoItCaseInsensitive(Src,CurPos.StartPos,
                                                  CurPos.EndPos-CurPos.StartPos)
    else begin
      if Src[CurPos.StartPos] in ['(','['] then
        ReadTilBracketClose(true);
      Result:=true;
    end;
  end else
    Result:=false;
end;

function TPascalParserTool.KeyWordFuncSection: boolean;
// parse section keywords (program, unit, interface, implementation, ...)

  procedure RaiseUnexpectedSectionKeyWord;
  begin
    SaveRaiseExceptionFmt(ctsUnknownSectionKeyword,[GetAtom]);
  end;

begin
  Result:=false;
  if UpAtomIs('IMPLEMENTATION') then begin
    if not (CurSection in [ctnInterface,ctnUnit,ctnLibrary,ctnPackage]) then
      RaiseUnexpectedSectionKeyWord;
    // close section node
    CurNode.EndPos:=CurPos.StartPos;
    EndChildNode;
    // start implementation section node
    CreateChildNode;
    CurNode.Desc:=ctnImplementation;
    CurSection:=ctnImplementation;

    ScannedRange:=lsrImplementationStart;
    if ord(ScanTill)<=ord(ScannedRange) then exit;

    ReadNextAtom;

    if UpAtomIs('USES') then begin
      ReadUsesSection(true);
      if CurPos.Flag<>cafSemicolon then
        UndoReadNextAtom;
      if ord(ScanTill)<=ord(ScannedRange) then exit;
    end else
      UndoReadNextAtom;
    ScannedRange:=lsrImplementationUsesSectionEnd;
    if ord(ScanTill)<=ord(ScannedRange) then exit;

    Result:=true;
  end else if (UpAtomIs('INITIALIZATION') or UpAtomIs('FINALIZATION')) then
  begin
    if UpAtomIs('INITIALIZATION') then begin
      if (not CurSection in [ctnInterface,ctnImplementation,
                            ctnUnit,ctnLibrary,ctnPackage])
      then
        RaiseUnexpectedSectionKeyWord;
    end;
    if UpAtomIs('FINALIZATION') then begin
      if (not CurSection in [ctnInterface,ctnImplementation,ctnInitialization,
                            ctnUnit,ctnLibrary,ctnPackage])
      then
        RaiseUnexpectedSectionKeyWord;
    end;
    // close section node
    CurNode.EndPos:=CurPos.StartPos;
    EndChildNode;
    // start initialization / finalization section node
    CreateChildNode;
    if UpAtomIs('INITIALIZATION') then begin
      CurNode.Desc:=ctnInitialization;
      ScannedRange:=lsrInitializationStart;
    end else begin
      CurNode.Desc:=ctnFinalization;
      ScannedRange:=lsrFinalizationStart;
    end;
    CurSection:=CurNode.Desc;
    if ord(ScanTill)<=ord(ScannedRange) then exit;

    repeat
      ReadNextAtom;
      if (CurPos.StartPos>SrcLen) then break;
      if CurPos.Flag=cafEND then begin
        Result:=KeyWordFuncEndPoint;
        break;
      end else if (CurSection=ctnInitialization) and UpAtomIs('FINALIZATION') then
      begin
        CurNode.EndPos:=CurPos.EndPos;
        EndChildNode;
        CreateChildNode;
        CurNode.Desc:=ctnFinalization;
        CurSection:=CurNode.Desc;
        ScannedRange:=lsrFinalizationStart;
        if ord(ScanTill)<=ord(ScannedRange) then exit;
      end else if BlockStatementStartKeyWordFuncList.DoIdentifier(@Src[CurPos.StartPos])
      then begin
        if not ReadTilBlockEnd(false,true) then SaveRaiseEndOfSourceExpected;
      end else if UpAtomIs('WITH') then begin
        ReadWithStatement(true,true);
      end;
    until false;
    Result:=true;
  end else begin
    RaiseUnexpectedSectionKeyWord;
  end;
end;

function TPascalParserTool.KeyWordFuncEndPoint: boolean;
// keyword 'end' or '.'  (source end.)
var
  LastNodeEnd: LongInt;
begin
  if CurPos.Flag=cafPoint then begin
    if not LastUpAtomIs(0,'END') then
      SaveRaiseIllegalQualifier;
    UndoReadNextAtom;
    if CurNode.Desc in [ctnInterface] then
      SaveRaiseStringExpectedButAtomFound('"implementation"');
    if not (CurNode.Desc in [ctnImplementation,ctnInitialization,
      ctnFinalization,ctnProgram,ctnLibrary])
    then begin
      ReadNextAtom;
      SaveRaiseException(ctsUnexpectedEndOfSource+' 1');
    end;
  end else if CurPos.Flag=cafEND then begin
    if LastAtomIs(0,'@') then
      SaveRaiseStringExpectedButAtomFound(ctsIdentifier);
    if LastAtomIs(0,'@@') then begin
      // for Delphi compatibility @@end is allowed
      Result:=true;
      exit;
    end;
  end else
    SaveRaiseException('[TPascalParserTool.KeyWordFuncEndPoint] internal error');
  if CurNode.Desc in [ctnBeginBlock] then
    CurNode.EndPos:=CurPos.EndPos
  else
    CurNode.EndPos:=CurPos.StartPos;
  LastNodeEnd:=CurNode.EndPos;
  // end section (ctnBeginBlock, ctnInitialization, ...)
  EndChildNode;
  CreateChildNode;
  CurNode.Desc:=ctnEndPoint;
  CurNode.StartPos:=LastNodeEnd;
  ReadNextAtom;
  if CurPos.Flag<>cafPoint then
    SaveRaiseCharExpectedButAtomFound('.');
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  CurSection:=ctnNone;
  ScannedRange:=lsrEnd;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncProc: boolean;
// procedure, function, constructor, destructor, operator
var ChildCreated: boolean;
  IsFunction, HasForwardModifier, IsClassProc, IsOperator, IsMethod: boolean;
  ProcNode: TCodeTreeNode;
  ParseAttr: TParseProcHeadAttributes;
begin
  if UpAtomIs('CLASS') then begin
    if not (CurSection in [ctnImplementation]+AllSourceTypes) then
      SaveRaiseStringExpectedButAtomFound(ctsIdentifier);
    ReadNextAtom;
    if UpAtomIs('PROCEDURE') or UpAtomIs('FUNCTION') or UpAtomIs('CONSTRUCTOR')
    or UpAtomIs('DESTRUCTOR') or UpAtomIs('OPERATOR') then
      IsClassProc:=true
    else
      SaveRaiseStringExpectedButAtomFound(ctsProcedureOrFunctionOrConstructorOrDestructor);
  end else
    IsClassProc:=false;
  ChildCreated:=true;
  if ChildCreated then begin
    // create node for procedure
    CreateChildNode;
    if IsClassProc then
      CurNode.StartPos:=LastAtoms.GetValueAt(0).StartPos;
    ProcNode:=CurNode;
    ProcNode.Desc:=ctnProcedure;
    if CurSection=ctnInterface then
      ProcNode.SubDesc:=ctnsForwardDeclaration;
  end;
  IsFunction:=UpAtomIs('FUNCTION');
  IsOperator:=(not IsFunction) and UpAtomIs('OPERATOR');
  IsMethod:=False;
  ReadNextAtom;// read first atom of head (= name/operator + parameterlist + resulttype;)
  if IsOperator then
    AtomIsCustomOperator(true,true,true)
  else
    AtomIsIdentifierSaveE;
  if ChildCreated then begin
    // create node for procedure head
    CreateChildNode;
    CurNode.Desc:=ctnProcedureHead;
    CurNode.SubDesc:=ctnsNeedJITParsing;
  end;
  ReadNextAtom;
  if (CurSection<>ctnInterface) then begin
    if (Scanner.CompilerMode = cmDELPHI) and AtomIsChar('<') then
    begin
      repeat
        ReadNextAtom;
        if CurPos.Flag <> cafWord then
          RaiseExceptionFmt(ctsIdentExpectedButAtomFound, [GetAtom]);
        ReadNextAtom;
        if AtomIsChar('>') then Break;
        if CurPos.Flag <> cafComma then
          SaveRaiseCharExpectedButAtomFound(',');
      until False;
      ReadNextAtom;
    end;
    while (CurPos.Flag=cafPoint) do begin
      // read procedure name of a class method (the name after the . )
      IsMethod:=True;
      ReadNextAtom;
      if IsOperator then
        AtomIsCustomOperator(true,true,true)
      else
        AtomIsIdentifierSaveE;
      ReadNextAtom;
    end;
  end;
  // read rest of procedure head
  HasForwardModifier:=false;
  ParseAttr:=[];
  if IsFunction then Include(ParseAttr,pphIsFunction);
  if IsOperator then Include(ParseAttr,pphIsOperator);
  if IsMethod then Include(ParseAttr,pphIsMethod);
  ReadTilProcedureHeadEnd(ParseAttr,HasForwardModifier);
  if ChildCreated then begin
    if HasForwardModifier then
      ProcNode.SubDesc:=ctnsForwardDeclaration;
    // close head
    CurNode.EndPos:=CurPos.EndPos;
    EndChildNode;
  end;
  if ChildCreated and ((ProcNode.SubDesc and ctnsForwardDeclaration)>0) then
  begin
    // close method
    CurNode.EndPos:=CurPos.EndPos;
    EndChildNode;
  end;
  Result:=true;
end;

function TPascalParserTool.ReadTilBlockEnd(
  StopOnBlockMiddlePart, CreateNodes: boolean): boolean;
// after reading cursor will be on the atom ending the block (e.g. 'end', 'until', ';')
var BlockType: TEndBlockType;
  TryType: TTryType;
  BlockStartPos: integer;
  Desc: TCodeTreeNodeDesc;
  IfType: TIfType;

  procedure SaveRaiseExceptionWithBlockStartHint(const AMessage: string);
  var CaretXY: TCodeXYPosition;
  begin
    if (CleanPosToCaret(BlockStartPos,CaretXY))
    and (CaretXY.Code<>nil) then begin
      if CaretXY.Code=TCodeBuffer(Scanner.MainCode) then
        SaveRaiseException(AMessage+ctsPointStartAt
          +'('+IntToStr(CaretXY.Y)+','+IntToStr(CaretXY.X)+')')
      else
        SaveRaiseException(AMessage+ctsPointStartAt
          +TCodeBuffer(CaretXY.Code).Filename
          +'('+IntToStr(CaretXY.Y)+','+IntToStr(CaretXY.X)+')');
    end else if (Scanner<>nil) and (Scanner.MainCode<>nil) then begin
      SaveRaiseException(AMessage);
    end;
  end;
  
  procedure RaiseUnknownBlockType;
  begin
    SaveRaiseException('internal codetool error in '
      +'TPascalParserTool.ReadTilBlockEnd: unknown block type: '+GetAtom);
  end;
  
  procedure RaiseStrExpectedWithBlockStartHint(const Msg: string);
  begin
    SaveRaiseExceptionWithBlockStartHint(
      Format(ctsStrExpectedButAtomFound,[Msg,GetAtom]));
  end;
  
  procedure SaveRaiseUnexpectedKeyWordInAsmBlock;
  begin
    SaveRaiseExceptionFmt(ctsUnexpectedKeywordInAsmBlock,[GetAtom]);
  end;
  
  procedure SaveRaiseUnexpectedKeyWordInBeginEndBlock;
  begin
    SaveRaiseExceptionWithBlockStartHint(
      Format(ctsUnexpectedKeywordInBeginEndBlock,[GetAtom]));
  end;

  procedure CloseNode; inline;
  begin
    if Desc<>ctnNone then begin
      CurNode.EndPos:=CurPos.EndPos;
      EndChildNode;
    end;
  end;

  function AutomaticallyEnded: boolean;
  begin
    if BlockType=ebtIf then begin
      CloseNode;
      UndoReadNextAtom;
      Result:=true;
    end else
      Result:=false;
  end;
  
begin
  Result:=true;
  TryType:=ttNone;
  IfType:=itNone;
  Desc:=ctnNone;
  //debugln(['TPascalParserTool.ReadTilBlockEnd START ',GetAtom]);
  if UpAtomIs('BEGIN') then begin
    BlockType:=ebtBegin;
    Desc:=ctnBeginBlock;
  end else if UpAtomIs('REPEAT') then
    BlockType:=ebtRepeat
  else if UpAtomIs('TRY') then
    BlockType:=ebtTry
  else if UpAtomIs('IF') then
    BlockType:=ebtIf
  else if UpAtomIs('CASE') then
    BlockType:=ebtCase
  else if UpAtomIs('ASM') then
    BlockType:=ebtAsm
  else if UpAtomIs('RECORD') then
    BlockType:=ebtRecord
  else
    RaiseUnknownBlockType;
  if (Desc<>ctnNone) then begin
    if CreateNodes then begin
      CreateChildNode;
      CurNode.Desc:=Desc;
    end else
      Desc:=ctnNone;
  end;
  BlockStartPos:=CurPos.StartPos;
  repeat
    ReadNextAtom;
    //debugln(['TPascalParserTool.ReadTilBlockEnd next=',GetAtom]);
    if (CurPos.StartPos>SrcLen) then
      SaveRaiseExceptionWithBlockStartHint(ctsUnexpectedEndOfSource);
      
    if (CurPos.Flag=cafEND) then begin
      // end
      if (BlockType<>ebtAsm) or (CurPos.StartPos=1) or (Src[CurPos.StartPos-1]<>'@')
      then begin
        if AutomaticallyEnded then break;
        if BlockType=ebtRepeat then
          RaiseStrExpectedWithBlockStartHint('"until"');
        if (BlockType=ebtTry) and (TryType=ttNone) then
          RaiseStrExpectedWithBlockStartHint('"finally"');
        CloseNode;
        ReadNextAtom;
        if (CurPos.Flag=cafPoint) and (BlockType<>ebtBegin) then begin
          SaveRaiseCharExpectedButAtomFound(';');
        end;
        UndoReadNextAtom;
        break;
      end;
    end else if CurPos.Flag=cafSemicolon then begin
      // ;
      if BlockType=ebtIf then begin
        CloseNode;
        break;
      end;
    end else if CurPos.Flag<>cafWord then begin
      continue;
    end else if BlockStatementStartKeyWordFuncList.DoIdentifier(@Src[CurPos.StartPos])
    then begin
      if BlockType=ebtAsm then
        SaveRaiseUnexpectedKeyWordInAsmBlock;
      if (BlockType<>ebtRecord) then begin
        ReadTilBlockEnd(false,CreateNodes);
        if (BlockType=ebtIf) and (CurPos.Flag in [cafSemicolon]) then
          break;
      end;
    end else if UpAtomIs('UNTIL') then begin
      if AutomaticallyEnded then break;
      if BlockType<>ebtRepeat then
        RaiseStrExpectedWithBlockStartHint('"end"');
      CloseNode;
      break;
    end else if UpAtomIs('FINALLY') then begin
      if AutomaticallyEnded then break;
      if (BlockType=ebtTry) and (TryType=ttNone) then begin
        if StopOnBlockMiddlePart then break;
        TryType:=ttFinally;
      end else
        RaiseStrExpectedWithBlockStartHint('"end"');
    end else if UpAtomIs('EXCEPT') then begin
      if AutomaticallyEnded then break;
      if (BlockType=ebtTry) and (TryType=ttNone) then begin
        if StopOnBlockMiddlePart then break;
        TryType:=ttExcept;
      end else
        RaiseStrExpectedWithBlockStartHint('"end"');
    end else if UpAtomIs('THEN') then begin
      if (BlockType=ebtIf) and (IfType=itNone) then begin
        IfType:=itThen;
      end;
    end else if UpAtomIs('ELSE') then begin
      if (BlockType=ebtIf) then begin
        if (IfType=itThen) then
          IfType:=itElse
        else begin
          // e.g. if then if then else |else ;
          CloseNode;
          UndoReadNextAtom;
          break;
        end;
      end else if BlockType=ebtCase then begin
      end;
    end else if CreateNodes and UpAtomIs('WITH') then begin
      ReadWithStatement(true,CreateNodes);
    end else if UpAtomIs('ON') and (BlockType=ebtTry)
    and (TryType=ttExcept) then begin
      ReadOnStatement(true,CreateNodes);
    end else begin
      // check for unexpected keywords
      case BlockType of
      
      ebtBegin,ebtTry,ebtIf,ebtCase,ebtRepeat:
        if UnexpectedKeyWordInBeginBlock.DoIdentifier(@Src[CurPos.StartPos]) then
          SaveRaiseUnexpectedKeyWordInBeginEndBlock;
          
      ebtAsm:
        if UnexpectedKeyWordInAsmBlock.DoIdentifier(@Src[CurPos.StartPos]) then
          SaveRaiseUnexpectedKeyWordInBeginEndBlock;

      end;
    end;
  until false;
  //debugln(['TPascalParserTool.ReadTilBlockEnd end=',GetAtom]);
end;

function TPascalParserTool.ReadTilBlockStatementEnd(
  ExceptionOnNotFound: boolean): boolean;
begin
  if CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen] then
    Result:=ReadTilBracketClose(ExceptionOnNotFound)
  else if WordIsBlockStatementStart.DoItCaseInsensitive(Src,CurPos.StartPos,
    CurPos.EndPos-CurPos.StartPos)
  then
    Result:=ReadTilBlockEnd(false,false)
  else
    Result:=false;
end;

function TPascalParserTool.ReadBackTilBlockEnd(
  StopOnBlockMiddlePart: boolean): boolean;
// read begin..end, try..finally, case..end, repeat..until, asm..end blocks
// backwards
var BlockType: TEndBlockType;

  procedure RaiseBlockError;
  begin
    case BlockType of
      ebtBegin:
        SaveRaiseExceptionFmt(ctsStrExpectedButAtomFound,['"begin"',GetAtom]);
      ebtTry:
        SaveRaiseExceptionFmt(ctsStrExpectedButAtomFound,['"try"',GetAtom]);
      ebtRepeat:
        SaveRaiseExceptionFmt(ctsStrExpectedButAtomFound,['"repeat"',GetAtom]);
    else
      SaveRaiseExceptionFmt(ctsUnexpectedKeywordWhileReadingBackwards,[GetAtom]);
    end;
  end;
  
  procedure RaiseUnknownBlockType;
  begin
    SaveRaiseException('internal codetool error in '
      +'TPascalParserTool.ReadBackTilBlockEnd: unknown block type: '+GetAtom);
  end;

var OldAtom: TAtomPosition;
begin
  Result:=true;
  if CurPos.Flag=cafEND then
    BlockType:=ebtBegin
  else if UpAtomIs('UNTIL') then
    BlockType:=ebtRepeat
  else if UpAtomIs('FINALLY') or UpAtomIs('EXCEPT') then
    BlockType:=ebtTry
  else
    RaiseUnknownBlockType;
  repeat
    ReadPriorAtom;
    if (CurPos.StartPos<1) then begin
      SaveRaiseExceptionFmt(ctsWordNotFound,['begin']);
    end else if WordIsBlockKeyWord.DoIdentifier(@Src[CurPos.StartPos]) then begin
      if (CurPos.Flag=cafEND) or (UpAtomIs('UNTIL')) then begin
        ReadBackTilBlockEnd(false);
      end else if UpAtomIs('BEGIN') or UpAtomIs('RECORD') or UpAtomIs('ASM')
      then begin
        if BlockType=ebtBegin then
          break
        else
          RaiseBlockError;
      end else if UpAtomIs('OBJECT') then begin
        if BlockType=ebtBegin then begin
          // could also be 'of object'
          ReadPriorAtom;
          if not UpAtomIs('OF') then begin
            CurPos:=NextPos;
            NextPos.StartPos:=-1;
            break;
          end;
        end else
          RaiseBlockError;
      end else if UpAtomIs('CLASS') then begin
        ReadNextAtom;
        if UpAtomIs('FUNCTION') or UpAtomIs('PROCEDURE')
        or (CurPos.Flag=cafSemicolon) or UpAtomIs('OF') then
          UndoReadNextAtom
        else begin
          UndoReadNextAtom;
          break;
        end;
      end else if UpAtomIs('CASE') then begin
        // case could also be in a record, then it should not close the block
        if BlockType=ebtBegin then begin
          // check if case in a record
          OldAtom:=CurPos;
          repeat
            ReadPriorAtom;
            if (CurPos.StartPos<1) then break;
            if WordIsBlockKeyWord.DoIdentifier(@Src[CurPos.StartPos]) then begin
              if UpAtomIs('CASE') then begin
                // could be another variant record, -> read further ...
              end else if UpAtomIs('RECORD') then begin
                // record start found -> the case is a variant record
                // block start found
                break;
              end else begin
                // this is not a variant record
                MoveCursorToCleanPos(OldAtom.StartPos);
                ReadNextAtom;
                break;
              end;
            end;
          until false;
          break;
        end else
          RaiseBlockError;
      end else if UpAtomIs('REPEAT') then begin
        if BlockType=ebtRepeat then
          break
        else
          RaiseBlockError;
      end else if UpAtomIs('FINALLY') or UpAtomIs('EXCEPT') then begin
        if BlockType=ebtBegin then begin
          if StopOnBlockMiddlePart then break;
          BlockType:=ebtTry;
        end else
          RaiseBlockError;
      end else if UpAtomIs('TRY') then begin
        if BlockType=ebtTry then
          break
        else
          RaiseBlockError;
      end;
    end;
  until false;
end;

function TPascalParserTool.ReadTilVariableEnd(
  ExceptionOnError, WithAsOperator: boolean): boolean;
{ Examples:
    A
    A.B^.C[...].D(...).E
    (...).A
    @B
    inherited A
    A as B
}
begin
  while AtomIsChar('@') do
    ReadNextAtom;
  while UpAtomIs('INHERITED') do
    ReadNextAtom;
  Result:=AtomIsIdentifier
          or (CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen]);
  if not Result then exit;
  repeat
    if AtomIsIdentifier then
      ReadNextAtom;
    repeat
      if (CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen]) then begin
        Result:=ReadTilBracketClose(ExceptionOnError);
        if not Result then exit;
        ReadNextAtom;
      end else if AtomIsChar('^') then begin
        ReadNextAtom;
      end else
        break;
    until false;
    if (CurPos.Flag=cafPoint)
    or (WithAsOperator and UpAtomIs('AS')) then
      ReadNextAtom
    else
      break;
  until false;
end;

function TPascalParserTool.ReadTilStatementEnd(ExceptionOnError,
  CreateNodes: boolean): boolean;
// after reading the current atom will be on the last atom of the statement
begin
  Result:=true;
  while CurPos.StartPos<=SrcLen do begin
    if BlockStatementStartKeyWordFuncList.DoIdentifier(@Src[CurPos.StartPos])
    then begin
      if not ReadTilBlockEnd(false,CreateNodes) then exit(false);
      ReadNextAtom;
      if CurPos.Flag<>cafSemicolon then UndoReadNextAtom;
      exit;
    end else if UpAtomIs('WITH') then begin
      Result:=ReadWithStatement(ExceptionOnError,CreateNodes);
      exit;
    end else begin
      case CurPos.Flag of
      cafEND:
        begin
          UndoReadNextAtom;
          exit;
        end;
      cafSemicolon: exit;
      else
        if CurPos.StartPos>SrcLen then exit;
        ReadNextAtom;
      end;
    end;
  end;
end;

function TPascalParserTool.ReadWithStatement(ExceptionOnError,
  CreateNodes: boolean): boolean;
  
  procedure CloseNodes;
  var WithVarNode: TCodeTreeNode;
    EndPos: LongInt;
  begin
    if CreateNodes then begin
      EndPos:=CurPos.EndPos;
      if CurNode.Desc=ctnWithStatement then begin
        if not (CurPos.Flag in [cafSemicolon,cafEnd]) then begin
          // the with statement is valid until the next atom
          // this is important for context when cursor is behind last atom of the
          // with statement, but in front of the next atom
          ReadNextAtom;
          EndPos:=CurPos.StartPos;
          UndoReadNextAtom;
        end;
        CurNode.EndPos:=EndPos;
        //DebugLn(['CloseNodes "',copy(Src,CurNode.StartPos,CurNode.EndPos-CurNode.STartPos),'"']);
        EndChildNode; // ctnWithStatement
      end;
      WithVarNode:=CurNode;
      CurNode.EndPos:=EndPos;
      EndChildNode; // ctnWithVariable
      // set all with variable ends
      repeat
        WithVarNode:=WithVarNode.PriorBrother;
        if (WithVarNode=nil) or (WithVarNode.Desc<>ctnWithVariable)
        or (WithVarNode.EndPos>0) then break;
        WithVarNode.EndPos:=EndPos;
      until false;
    end;
  end;
  
begin
  ReadNextAtom; // read start of variable
  if CreateNodes then begin
    CreateChildNode;
    CurNode.Desc:=ctnWithVariable;
  end;
  // read til the end of the variable
  if not ReadTilVariableEnd(ExceptionOnError,true) then begin
    CloseNodes;
    Result:=false;
    exit;
  end;
  // read all other variables
  while CurPos.Flag=cafComma do begin
    if CreateNodes then
      EndChildNode;
    ReadNextAtom;
    if CreateNodes then begin
      CreateChildNode;
      CurNode.Desc:=ctnWithVariable
    end;
    if not ReadTilVariableEnd(ExceptionOnError,true) then begin
      CloseNodes;
      Result:=false;
      exit;
    end;
  end;
  // read DO
  if not UpAtomIs('DO') then begin
    if ExceptionOnError then
      SaveRaiseStringExpectedButAtomFound('"do"')
    else begin
      CloseNodes;
      Result:=false;
      exit;
    end;
  end;
  // read statement
  ReadNextAtom;
  if CreateNodes then begin
    CreateChildNode;
    CurNode.Desc:=ctnWithStatement;
  end;
  Result:=ReadTilStatementEnd(ExceptionOnError,CreateNodes);
  CloseNodes;
end;

function TPascalParserTool.ReadOnStatement(ExceptionOnError,
  CreateNodes: boolean): boolean;
// for example:
// on E: Exception do ;
// on Exception do ;
// on Unit.Exception do ;
// on Unit.Exception do else ;
// on Unit.Exception do ; else ;
var
  NeedUndo: Boolean;
begin
  if CreateNodes then begin
    CreateChildNode;
    CurNode.Desc:=ctnOnBlock;
  end;
  // read variable name
  ReadNextAtom;
  AtomIsIdentifierSaveE;
  if CreateNodes then begin
    // ctnOnIdentifier for the variable or the type
    CreateChildNode;
    CurNode.Desc:=ctnOnIdentifier;
    CurNode.EndPos:=CurPos.EndPos;
  end;
  ReadNextAtom;
  if CurPos.Flag=cafColon then begin
    // this is for example: on E: Exception do ;
    if CreateNodes then
      CurNode.Desc:=ctnVarDefinition;
    ReadNextAtom;
    AtomIsIdentifierSaveE;
    if CreateNodes then begin
      // ctnIdentifier for the type
      CreateChildNode;
      CurNode.Desc:=ctnIdentifier;
      CurNode.EndPos:=CurPos.EndPos;
    end;
    ReadNextAtom;
  end;
  if CurPos.Flag=cafPoint then begin
    // for example: on Unit.Exception do ;
    // or: on E:Unit.Exception do ;
    ReadNextAtom;
    AtomIsIdentifierSaveE;
    if CreateNodes then begin
      CurNode.EndPos:=CurPos.EndPos;
    end;
    ReadNextAtom;
  end;
  if CreateNodes then begin
    if CurNode.Desc=ctnIdentifier then begin
      // close the type
      CurNode.Parent.EndPos:=CurNode.EndPos;
      EndChildNode;
    end;
    // close ctnVarDefinition or ctnOnIdentifier
    EndChildNode;
  end;
  // read 'do'
  if not UpAtomIs('DO') then
    SaveRaiseStringExpectedButAtomFound('DO');
  // ctnOnStatement
  if CreateNodes then begin
    CreateChildNode;
    CurNode.Desc:=ctnOnStatement;
  end;
  ReadTilStatementEnd(true,CreateNodes);
  if CreateNodes then begin
    CurNode.EndPos:=CurPos.EndPos;
    EndChildNode; // ctnOnStatement
    CurNode.EndPos:=CurPos.EndPos;
    EndChildNode; // ctnOnVariable
  end;
  NeedUndo:=false;
  if CurPos.Flag=cafSemicolon then begin
    // for example: on E: Exception do ; else ;
    ReadNextAtom;
    NeedUndo:=true;
  end;
  if UpAtomIs('ELSE') then begin
    // for example: on E: Exception do else ;
    ReadNextAtom;
    ReadTilStatementEnd(true,CreateNodes);
    NeedUndo:=false;
  end;
  if NeedUndo then
    UndoReadNextAtom;
  Result:=true;
end;

procedure TPascalParserTool.ReadVariableType;
{ creates nodes for variable type

  examples:

    interface
      var a:b;
        a:b; cvar;
        a:b; public name 'string constant' section 'string constant';
        a:b; public name <id>;
        a:b; external name 'string constant';
        a:b; cvar; external;
        a:b; external 'library' name 'avar';

    implementation

    procedure c;
    var d:e;
      f:g=h;
}
begin
  ReadNextAtom;
  // type
  ParseType(CurPos.StartPos,CurPos.EndPos-CurPos.StartPos);

  // optional: absolute
  if UpAtomIs('ABSOLUTE') then begin
    ReadNextAtom;
    ReadConstant(true,false,[]);
  end;

  // optional: initial value
  if CurPos.Flag=cafEqual then
    ReadConstExpr; // read constant

  // optional: hint modifier
  ReadHintModifiers;

  // semicolon and postfix modifiers
  if CurPos.Flag=cafSemicolon then begin
    // read ;
    ReadNextAtom;
    if UpAtomIs('CVAR') then begin
      // for example: 'var a: char; cvar;'
      ReadNextAtom;
      if CurPos.Flag<>cafSemicolon then
        SaveRaiseCharExpectedButAtomFound(';');
      ReadNextAtom;
    end;
    if UpAtomIs('STATIC') and (CurNode.Parent<>nil)
    and (CurNode.Parent.Desc in AllClassSections) then begin
      // 'static' is allowed for class variables
      // for example: 'a: char; static;'
      ReadNextAtom;
      if CurPos.Flag<>cafSemicolon then
        SaveRaiseCharExpectedButAtomFound(';');
      ReadNextAtom;
    end;
    //if UpAtomIs('EXTERNAL') then
    //  debugln(['TPascalParserTool.ReadVariableType ',CurNode.Parent.Parent.DescAsString,' ',CurNode.Parent.DescAsString,' ',CurNode.DescAsString]);
    if (CurNode.Parent.Desc in [ctnVarSection,ctnClassClassVar])
    and ((CurNode.Parent.Parent.Desc in AllCodeSections)
         or ((CurNode.Parent.Parent.Desc in (AllClassBaseSections+AllClassInterfaces))
              and Scanner.Values.IsDefined('CPUJVM')))
    and (UpAtomIs('PUBLIC') or UpAtomIs('EXPORT') or UpAtomIs('EXTERNAL')
      or UpAtomIs('WEAKEXTERNAL') or UpAtomIs('CVAR')) then
    begin
      // examples:
      //   a: b; public;
      //   a: b; external;
      //   a: b; external c;
      //   a: b; external name 'c';
      //   a: b; external 'library' name 'c';
      if UpAtomIs('EXTERNAL') or UpAtomIs('WEAKEXTERNAL') then begin
        // read external identifier
        ReadNextAtom;
        if (CurPos.Flag<>cafSemicolon) and (not UpAtomIs('NAME')) then
          ReadConstant(true,false,[]); // library name
      end else
        ReadNextAtom;
      if UpAtomIs('NAME') then begin
        // for example 'var a: char; public name 'b' ;'
        // for example 'var a: char; public name test;'
        ReadNextAtom;
        if (not AtomIsStringConstant)
        and (not AtomIsIdentifier) then
          SaveRaiseStringExpectedButAtomFound(ctsStringConstant);
        ReadConstant(true,false,[]);
        if UpAtomIs('SECTION') then begin
          // for example FreePascal_TLS_callback : pointer = @Exec_Tls_callback; public name '__FPC_tls_callbacks' section '.CRT$XLFPC'
          ReadNextAtom;
          if (not AtomIsStringConstant)
          and (not AtomIsIdentifier) then
            SaveRaiseStringExpectedButAtomFound(ctsStringConstant);
          ReadConstant(true,false,[]);
        end;
      end;
      if CurPos.Flag<>cafSemicolon then
        SaveRaiseCharExpectedButAtomFound(';');
    end else
      UndoReadNextAtom;
  end else if CurPos.Flag=cafEND then begin
    UndoReadNextAtom;
  end else begin
    SaveRaiseCharExpectedButAtomFound(';');
  end;
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
end;

procedure TPascalParserTool.ReadHintModifiers;
// after reading cursor is at next atom

  function IsModifier: boolean;
  var
    p: PChar;
  begin
    Result:=false;
    if (CurPos.StartPos<1) or (CurPos.StartPos>SrcLen) then exit;
    p:=@Src[CurPos.StartPos];
    case UpChars[p^] of
    'D': Result:=UpAtomIs('DEPRECATED');
    'E': Result:=UpAtomIs('EXPERIMENTAL');
    'L': Result:=UpAtomIs('LIBRARY');
    'P': Result:=UpAtomIs('PLATFORM');
    'U': Result:=UpAtomIs('UNIMPLEMENTED');
    end;
  end;

var
  NeedUndo: boolean;
  CanHaveString: Boolean;
begin
  if CurPos.Flag=cafSemicolon then begin
    ReadNextAtom;
    NeedUndo:=true;
  end else
    NeedUndo:=false;
  while IsModifier do begin
    //debugln(['TPascalParserTool.ReadHintModifier ',CurNode.DescAsString,' ',CleanPosToStr(CurPos.StartPos)]);
    NeedUndo:=false;
    CreateChildNode;
    CurNode.Desc:=ctnHintModifier;
    CurNode.EndPos:=CurPos.EndPos;
    CanHaveString:=UpAtomIs('DEPRECATED');
    ReadNextAtom;
    if CanHaveString and AtomIsStringConstant then begin
      ReadConstant(true,false,[]);
      CurNode.EndPos:=CurPos.StartPos;
    end;
    if not (CurPos.Flag in [cafSemicolon,cafRoundBracketClose]) then
      SaveRaiseCharExpectedButAtomFound(';');
    EndChildNode;
    if CurPos.Flag<>cafSemicolon then
      break;
    ReadNextAtom;
    NeedUndo:=true;
  end;
  if NeedUndo then
    UndoReadNextAtom;
end;

function TPascalParserTool.KeyWordFuncBeginEnd: boolean;
// Keyword: begin, asm

  procedure SaveRaiseExceptionWithHint;
  var CaretXY: TCodeXYPosition;
    AMessage: string;
  begin
    AMessage:=Format(ctsStrExpectedButAtomFound,[';','.']);
    if (CleanPosToCaret(CurNode.StartPos,CaretXY))
    and (CaretXY.Code<>nil) then begin
      if CaretXY.Code=TCodeBuffer(Scanner.MainCode) then
        SaveRaiseException(AMessage+ctsPointHintProcStartAt
          +'('+IntToStr(CaretXY.Y)+','+IntToStr(CaretXY.X)+')')
      else
        SaveRaiseException(AMessage+ctsPointHintProcStartAt
          +TCodeBuffer(CaretXY.Code).Filename
          +'('+IntToStr(CaretXY.Y)+','+IntToStr(CaretXY.X)+')');
    end else if (Scanner<>nil) and (Scanner.MainCode<>nil) then begin
      SaveRaiseException(AMessage);
    end;
  end;

var
  ChildNodeCreated: boolean;
begin
  //DebugLn('TPascalParserTool.KeyWordFuncBeginEnd CurNode=',CurNode.DescAsString);
  if (CurNode<>nil)
  and (not (CurNode.Desc in
    [ctnProcedure,ctnProgram,ctnLibrary,ctnImplementation]))
  then
    SaveRaiseStringExpectedButAtomFound('end');
  ChildNodeCreated:=UpAtomIs('BEGIN') or UpAtomIs('ASM');
  if ChildNodeCreated then begin
    CreateChildNode;
    if UpAtomIs('BEGIN') then
      CurNode.Desc:=ctnBeginBlock
    else
      CurNode.Desc:=ctnAsmBlock;
    CurNode.SubDesc:=ctnsNeedJITParsing;
  end;
  // search "end"
  ReadTilBlockEnd(false,false);
  // close node
  if ChildNodeCreated then begin
    CurNode.EndPos:=CurPos.EndPos;
    EndChildNode;
  end;
  if (CurSection<>ctnInterface)
  and (CurNode<>nil) and (CurNode.Desc=ctnProcedure) then begin
    // close procedure
    CurNode.EndPos:=CurPos.EndPos;
    ReadNextAtom;
    if (CurPos.Flag=cafPoint) then
      SaveRaiseExceptionWithHint;
    UndoReadNextAtom;
    EndChildNode;
  end else if (CurNode.Desc in [ctnProgram,ctnLibrary,ctnImplementation]) then
  begin
    ReadNextAtom;
    if (CurPos.Flag<>cafPoint) then
      SaveRaiseException(ctsMissingPointAfterEnd);
    // close program
    CurNode.EndPos:=CurPos.StartPos;
    EndChildNode;
    // add endpoint node
    CreateChildNode;
    CurNode.Desc:=ctnEndPoint;
    CurNode.EndPos:=CurPos.StartPos;
    EndChildNode;
    ScannedRange:=lsrEnd;
    CurSection:=ctnNone;
  end;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncType: boolean;
{ The 'type' keyword is the start of a type section.
  examples:

    interface
      type
        a=b;
        generic c<> = d;
      
    implementation
    
    procedure c;
    type d=e;
}
begin
  if not (CurSection in [ctnProgram,ctnLibrary,ctnInterface,ctnImplementation])
  then
    SaveRaiseUnexpectedKeyWord;
  CreateChildNode;
  CurNode.Desc:=ctnTypeSection;
  // read all type definitions  Name = Type; or generic Name<List> = Type;
  repeat
    ReadNextAtom;  // name
    if UpAtomIs('GENERIC') or AtomIsIdentifier then begin
      ReadTypeNameAndDefinition;
    end else begin
      UndoReadNextAtom;
      break;
    end;
  until false;
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncVar: boolean;
{
  examples:

    interface
      var a:b;
        a:b; cvar;
        a:b; public name 'string constant';
        a:b; public name <id>;
        a:b; external name 'string constant';
        a:b; cvar; external;
        a:b; external 'library' name 'avar';

    implementation

    procedure c;
    var d:e;
      f:g=h;
}
var
  LastIdentifierEnd: LongInt;
begin
  if not (CurSection in [ctnProgram,ctnLibrary,ctnInterface,ctnImplementation])
  then
    SaveRaiseUnexpectedKeyWord;
  CreateChildNode;
  CurNode.Desc:=ctnVarSection;
  // read all variable definitions  Name : Type; [cvar;] [public [name '']]
  repeat
    ReadNextAtom;  // name
    if AtomIsIdentifier
    and ((not (Scanner.CompilerMode in [cmOBJFPC,cmFPC]))
         or (not UpAtomIs('PROPERTY')))
    then begin
      CreateChildNode;
      CurNode.Desc:=ctnVarDefinition;
      LastIdentifierEnd:=CurPos.EndPos;
      ReadNextAtom;
      while (CurPos.Flag=cafComma) do begin
        CurNode.EndPos:=LastIdentifierEnd;
        EndChildNode; // close variable definition
        ReadNextAtom;
        AtomIsIdentifierSaveE;
        CreateChildNode;
        CurNode.Desc:=ctnVarDefinition;
        LastIdentifierEnd:=CurPos.EndPos;
        ReadNextAtom;
      end;
      if (CurPos.Flag<>cafColon) then begin
        SaveRaiseCharExpectedButAtomFound(':');
      end;
      // read type
      ReadVariableType;
    end else begin
      UndoReadNextAtom;
      break;
    end;
  until false;
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncConst: boolean;
{
  examples:

    interface
      const a:b=3;
      ;
      c =4;
      ErrorBase : Pointer = nil;public name 'FPC_ERRORBASE';

    implementation

    procedure c;
    const d=2;
}
begin
  if not (CurSection in [ctnProgram,ctnLibrary,ctnInterface,ctnImplementation])
  then
    SaveRaiseUnexpectedKeyWord;
  CreateChildNode;
  CurNode.Desc:=ctnConstSection;
  // read all constants  Name = <Const>; or Name : type = <Const>;
  repeat
    ReadNextAtom;  // name
    if CurPos.Flag=cafSemicolon then begin
      // ignore empty semicolons
    end else if AtomIsIdentifier then begin
      CreateChildNode;
      CurNode.Desc:=ctnConstDefinition;
      ReadConst;
      // close ctnConstDefinition node
      CurNode.EndPos:=CurPos.EndPos;
      EndChildNode;
    end else begin
      UndoReadNextAtom;
      break;
    end;
  until false;
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncResourceString: boolean;
{
  examples:

    interface
      ResourceString a='';

    implementation

    procedure c;
    ResourceString b=''; c=d+'';
}
begin
  if not (CurSection in [ctnProgram,ctnLibrary,ctnInterface,ctnImplementation])
  then
    SaveRaiseUnexpectedKeyWord;
  CreateChildNode;
  CurNode.Desc:=ctnResStrSection;
  // read all string constants Name = 'abc';
  repeat
    ReadNextAtom;  // name
    if AtomIsIdentifier
    and ((not (Scanner.CompilerMode in [cmOBJFPC,cmFPC]))
         or (not UpAtomIs('PROPERTY')))
    then begin
      CreateChildNode;
      CurNode.Desc:=ctnConstDefinition;
      ReadNextAtom;
      if (CurPos.Flag<>cafEqual) then
        SaveRaiseCharExpectedButAtomFound('=');
      // read string constant
      ReadNextAtom;
      if (not AtomIsStringConstant) and (not AtomIsIdentifier) then
        SaveRaiseStringExpectedButAtomFound(ctsStringConstant);
      ReadConstant(true,false,[]);
      // read hint modifier
      ReadHintModifiers;
      // read ;
      if CurPos.Flag<>cafSemicolon then
        SaveRaiseCharExpectedButAtomFound(';');
      CurNode.EndPos:=CurPos.EndPos;
      EndChildNode;
    end else begin
      UndoReadNextAtom;
      break;
    end;
  until false;
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncExports: boolean;
{ exports keyword  - only allowed in library

  examples:
  
  exports i, j index 3+4, k name 'StrConst', l index 0 name 's';
  exports unit1.blob;
}

  procedure RaiseExportsOnlyAllowedInLibraries;
  begin
    SaveRaiseException(ctsExportsClauseOnlyAllowedInLibraries);
  end;

begin
  if not (CurSection in [ctnLibrary,ctnProgram]) then
    RaiseExportsOnlyAllowedInLibraries;
  CreateChildNode;
  CurNode.Desc:=ctnExportsSection;
  repeat
    ReadNextAtom;
    AtomIsIdentifierSaveE;
    ReadNextAtom;
    if CurPos.Flag=cafPoint then begin
      ReadNextAtom;
      AtomIsIdentifierSaveE;
      ReadNextAtom;
    end;
    if UpAtomIs('INDEX') then begin
      ReadNextAtom;
      ReadConstant(true,false,[]);
    end;
    if UpAtomIs('NAME') then begin
      ReadNextAtom;
      ReadConstant(true,false,[]);
    end;
    if (CurPos.Flag=cafSemicolon) then break;
    if (CurPos.Flag<>cafComma) then
      SaveRaiseCharExpectedButAtomFound(';');
  until false;
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncLabel: boolean;
{
  examples:
    label a, 23, b;
}
begin
  if not (CurSection in [ctnProgram,ctnLibrary,ctnInterface,ctnImplementation])
  then
    SaveRaiseUnexpectedKeyWord;
  CreateChildNode;
  CurNode.Desc:=ctnLabelSection;
  // read all constants
  repeat
    ReadNextAtom;  // identifier or number
    if (not AtomIsIdentifier) and (not AtomIsNumber) then begin
      SaveRaiseStringExpectedButAtomFound(ctsIdentifier);
    end;
    CreateChildNode;
    CurNode.Desc:=ctnLabelType;
    CurNode.EndPos:=CurPos.EndPos;
    EndChildNode;
    ReadNextAtom;
    if CurPos.Flag=cafSemicolon then begin
      break;
    end else if (CurPos.Flag<>cafComma) then begin
      SaveRaiseCharExpectedButAtomFound(';');
    end;
  until false;
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncProperty: boolean;
{
  examples:
   property
     errno : cint read fpgeterrno write fpseterrno;
     A2 : Integer Read GetA2 Write SetA2;
}
begin
  if not (CurSection in [ctnProgram,ctnLibrary,ctnInterface,ctnImplementation])
  then
    SaveRaiseUnexpectedKeyWord;
  CreateChildNode;
  CurNode.Desc:=ctnPropertySection;
  // read all global properties
  repeat
    // read property Name
    ReadNextAtom;
    if AtomIsIdentifier then begin
      CreateChildNode;
      CurNode.Desc:=ctnGlobalProperty;
      ReadNextAtom;
      if CurPos.Flag=cafEdgedBracketOpen then begin
        // read parameter list
        ReadTilBracketClose(true);
        ReadNextAtom;
      end;
      while (CurPos.StartPos<=SrcLen) and (CurPos.Flag<>cafSemicolon) do
        ReadNextAtom;
      // close global property
      CurNode.EndPos:=CurPos.EndPos;
      EndChildNode;
    end else begin
      UndoReadNextAtom;
      break;
    end;
  until CurPos.StartPos>SrcLen;
  // close property section
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;
end;

procedure TPascalParserTool.ReadConst;
// ErrorBase : Pointer = nil;public name 'FPC_ERRORBASE';
begin
  ReadNextAtom;
  if (CurPos.Flag=cafColon) then begin
    // read type
    ReadNextAtom;
    ParseType(CurPos.StartPos,CurPos.EndPos-CurPos.StartPos);
  end;
  ReadConstExpr;
  // optional: hint modifier
  ReadHintModifiers;
  if CurPos.Flag=cafSemicolon then begin
    if (CurNode.Parent.Desc=ctnConstSection)
    and (CurNode.Parent.Parent.Desc in AllCodeSections) then begin
      repeat
        ReadNextAtom;
        if UpAtomIs('PUBLIC') then begin
          ReadNextAtom;
          if UpAtomIs('NAME') then begin
            ReadNextAtom;
            if not AtomIsStringConstant then
              SaveRaiseStringExpectedButAtomFound(ctsStringConstant);
            ReadNextAtom;
            if UpAtomIs('SECTION') then begin
              ReadNextAtom;
              if not AtomIsStringConstant then
                SaveRaiseStringExpectedButAtomFound(ctsStringConstant);
              ReadNextAtom;
            end;
          end;
          if CurPos.Flag<>cafSemicolon then
            SaveRaiseStringExpectedButAtomFound(';');
        end else
        if UpAtomIs('CVAR') then begin
          ReadNextAtom;
          if CurPos.Flag<>cafSemicolon then
            SaveRaiseStringExpectedButAtomFound(';');
        end else
        begin
          UndoReadNextAtom;
          break;
        end;
      until false;
    end;
  end;
end;

procedure TPascalParserTool.ReadTypeNameAndDefinition;
{ after parsing CurPos is on semicolon

  examples:
    name = type;
    generic name<> = type;  // fpc style
    generic name<name>=type;  // this is the only case where >= are two operators
    name<name,name> = type;  // delphi style
    TTest19<T1: record; T2,T3: class; T4: constructor; T5: name> = type
}
var
  TypeNode: TCodeTreeNode;
  NamePos: TAtomPosition;
begin
  CreateChildNode;
  TypeNode:=CurNode;
  if (Scanner.CompilerMode in [cmOBJFPC,cmFPC]) and UpAtomIs('GENERIC') then begin
    CurNode.Desc:=ctnGenericType;
    ReadNextAtom;
  end
  else
    CurNode.Desc:=ctnTypeDefinition;
  // read name
  AtomIsIdentifierSaveE;
  ReadNextAtom;
  if (TypeNode.Desc=ctnGenericType) and (not AtomIsChar('<')) then
    SaveRaiseCharExpectedButAtomFound('<');
  if AtomIsChar('<') then begin
    TypeNode.Desc:=ctnGenericType;
    // name
    CreateChildNode;
    NamePos:=LastAtoms.GetValueAt(0);
    CurNode.StartPos:=NamePos.StartPos;
    CurNode.Desc:=ctnGenericName;
    CurNode.EndPos:=NamePos.EndPos;
    //debugln(['TPascalParserTool.ReadTypeNameAndDefinition Name="',copy(Src,NamePos.StartPos,NamePos.EndPos-NamePos.StartPos),'"']);
    EndChildNode;
    // read parameter list
    ReadGenericParamList;
  end;
  // read =
  if (CurPos.Flag<>cafEqual) then
    SaveRaiseCharExpectedButAtomFound('=');
  // read type
  ReadNextAtom;
  ParseType(CurPos.StartPos,CurPos.EndPos-CurPos.StartPos);
  // read hint modifier
  ReadHintModifiers;
  // read ;
  if CurPos.Flag<>cafSemicolon then
    SaveRaiseCharExpectedButAtomFound(';');
  // close ctnTypeDefinition, ctnGenericType
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
end;

procedure TPascalParserTool.ReadGenericParamList;
{ At start cursor is on <
  At end cursor is on atom after >

 Examples:
  <> = type;  // fpc style
  <name>=type;  // this is the only case where >= are two operators
  <name,name> = type;  // delphi style
  <T1: record; T2,T3: class; T4: constructor; T5: name> = type
}
begin
  CreateChildNode;
  CurNode.Desc:=ctnGenericParams;
  ReadNextAtom;
  //debugln(['TPascalParserTool.ReadGenericParamList START ctnGenericParams ',GetAtom]);
  if AtomIsIdentifier then begin
    CreateChildNode;
    CurNode.Desc:=ctnGenericParameter;
    ReadNextAtom;
    repeat
      // read name
      //debugln(['TPascalParserTool.ReadGenericParamList AFTER NAMESTART ctnGenericParams ',GetAtom]);
      if AtomIs('>=') then begin
        // this is the rare case where >= are two separate atoms
        dec(CurPos.EndPos);
      end;
      if CurPos.Flag in [cafComma,cafSemicolon] then begin
        // read next name
        EndChildNode;
        ReadNextAtom;
        AtomIsIdentifierSaveE;
        CreateChildNode;
        CurNode.Desc:=ctnGenericParameter;
        ReadNextAtom;
      end else if AtomIsChar('>') then begin
        break;
      end else if CurPos.Flag=cafColon then begin
        // read constraints
        ReadNextAtom;
        if CurPos.Flag<>cafNone then begin
          CreateChildNode;
          CurNode.Desc:=ctnGenericConstraint;
        end;
        repeat
          CurNode.EndPos:=CurPos.EndPos;
          if UpAtomIs('RECORD') or UpAtomIs('CLASS') or UpAtomIs('CONSTRUCTOR')
          then begin
            // keyword
            ReadNextAtom;
          end else begin
            // a type
            AtomIsIdentifierSaveE;
            ReadNextAtom;
          end;
          if AtomIs('>=') then begin
            // this is the rare case where >= are two separate atoms
            dec(CurPos.EndPos);
          end;
          if (CurPos.Flag=cafSemicolon) or AtomIsChar('>') then begin
            break;
          end else if CurPos.Flag<>cafComma then
            SaveRaiseCharExpectedButAtomFound('>');
          ReadNextAtom;
        until false;
        // close ctnGenericConstraint
        CurNode.EndPos:=LastAtoms.GetValueAt(0).EndPos;
        EndChildNode;
        if AtomIsChar('>') then break;
        // cursor is now on ;
      end else
        SaveRaiseCharExpectedButAtomFound('>');
    until false;
    // close ctnGenericParameter
    CurNode.EndPos:=LastAtoms.GetValueAt(0).EndPos;
    EndChildNode;
  end else begin
    if AtomIs('>=') then
      // this is the rare case where >= are two separate atoms
      dec(CurPos.EndPos);
    if not AtomIsChar('>') then
      SaveRaiseCharExpectedButAtomFound('>');
  end;
  // close ctnGenericParams
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  ReadNextAtom;
end;

procedure TPascalParserTool.ReadTypeReference;
{ after reading CurPos is on atom behind the identifier

  examples:
    TButton
    controls.TButton
    TGenericClass<TypeReference,TypeReference>
}
var SavePos: TAtomPosition;
begin
  SavePos := CurPos;
  ReadNextAtom;
  while CurPos.Flag=cafPoint do begin
    ReadNextAtom;
    AtomIsIdentifierSaveE;
    ReadNextAtom;
  end;
  if not AtomIsChar('<') then exit;
  if Scanner.CompilerMode <> cmDELPHI then
    RaiseException('Unexpected character "<"');
  // read specialization parameters
  CurPos := SavePos;
  ReadPriorAtom; // unread generic name
  CurNode := CurNode.Parent;
  FreeAndNil(CurNode.FirstChild);
  CurNode.LastChild := nil;
  ReadSpecialize(True);
  CurNode.EndPos := CurPos.EndPos;
end;

function TPascalParserTool.KeyWordFuncTypePacked: boolean;
begin
  ReadNextAtom;
  if (CurPos.StartPos>SrcLen)
  or (not PackedTypesKeyWordFuncList.DoIdentifier(@Src[CurPos.StartPos])) then
    SaveRaiseStringExpectedButAtomFound('"record"');
  Result:=ParseType(CurPos.StartPos,CurPos.EndPos-CurPos.StartPos);
end;

function TPascalParserTool.KeyWordFuncTypeBitPacked: boolean;
begin
  ReadNextAtom;
  if (CurPos.StartPos>SrcLen)
  or (not BitPackedTypesKeyWordFuncList.DoIdentifier(@Src[CurPos.StartPos])) then
    SaveRaiseStringExpectedButAtomFound('"array"');
  Result:=ParseType(CurPos.StartPos,CurPos.EndPos-CurPos.StartPos);
end;

function TPascalParserTool.KeyWordFuncSpecialize: boolean;
begin
  ReadSpecialize(true);
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncTypeClass: boolean;
// class, object, record
var
  ClassAtomPos: TAtomPosition;
  ContextDesc: Word;
  IsForward: Boolean;
  ClassDesc: TCodeTreeNodeDesc;
  ClassNode: TCodeTreeNode;
  IsHelper: Boolean;
begin
  //debugln(['TPascalParserTool.KeyWordFuncTypeClass ',GetAtom,' ',CleanPosToStr(CurPos.StartPos)]);
  // class or 'class of' start found
  if UpAtomIs('CLASS') then
    ClassDesc:=ctnClass
  else if UpAtomIs('OBJECT') then
    ClassDesc:=ctnObject
  else if UpAtomIs('RECORD') then
    ClassDesc:=ctnRecordType
  else if UpAtomIs('OBJCCLASS') then
    ClassDesc:=ctnObjCClass
  else if UpAtomIs('OBJCCATEGORY') then
    ClassDesc:=ctnObjCCategory
  else if UpAtomIs('CPPCLASS') then
    ClassDesc:=ctnCPPClass
  else
    SaveRaiseStringExpectedButAtomFound('class');
  ContextDesc:=CurNode.Desc;
  if ClassDesc<>ctnRecordType then begin
    if not (ContextDesc in [ctnTypeDefinition,ctnGenericType])
    then
      SaveRaiseExceptionFmt(ctsAnonymDefinitionsAreNotAllowed,[GetAtom]);
    if CurNode.Parent.Desc<>ctnTypeSection then
      SaveRaiseExceptionFmt(ctsNestedDefinitionsAreNotAllowed,[GetAtom]);
  end;
  // packed class, bitpacked object
  if LastUpAtomIs(0,'PACKED') or LastUpAtomIs(0,'BITPACKED') then begin
    ClassAtomPos:=LastAtoms.GetValueAt(0);
  end else begin
    ClassAtomPos:=CurPos;
  end;
  CreateChildNode;
  ClassNode:=CurNode;
  CurNode.Desc:=ClassDesc;
  CurNode.StartPos:=ClassAtomPos.StartPos;
  IsForward:=true;
  IsHelper:=false;
  ReadNextAtom;
  if (ClassDesc=ctnClass) and UpAtomIs('OF') then begin
    // class of
    IsForward:=false;
    CurNode.Desc:=ctnClassOfType;
    ReadNextAtom;
    AtomIsIdentifierSaveE;
    CreateChildNode;
    CurNode.Desc:=ctnIdentifier;
    CurNode.EndPos:=CurPos.EndPos;
    EndChildNode;
    ReadNextAtom;
    if CurPos.Flag<>cafSemicolon then
      SaveRaiseCharExpectedButAtomFound(';');
  end else begin
    if CurPos.Flag=cafWord then begin
      if UpAtomIs('SEALED') then begin
        while UpAtomIs('SEALED') do begin
          CreateChildNode;
          CurNode.Desc:=ctnClassSealed;
          CurNode.EndPos:=CurPos.EndPos;
          EndChildNode;
          ReadNextAtom;
        end;
      end else if UpAtomIs('ABSTRACT') then begin
        while UpAtomIs('ABSTRACT') do begin
          CreateChildNode;
          CurNode.Desc:=ctnClassAbstract;
          CurNode.EndPos:=CurPos.EndPos;
          EndChildNode;
          ReadNextAtom;
        end;
      end;
      if UpAtomIs('EXTERNAL') then begin
        if (ClassDesc in [ctnObjCClass,ctnObjCCategory])
        or Scanner.Values.IsDefined('CPUJVM') then begin
          // objcclass external [name '']
          // cpujvm: class external '' [name '']
          CreateChildNode;
          CurNode.Desc:=ctnClassExternal;
          ReadNextAtom;
          if Scanner.Values.IsDefined('CPUJVM') then
            ReadConstant(true,false,[]);
          if UpAtomIs('NAME') then begin
            ReadNextAtom;
            ReadConstant(true,false,[]);
          end;
          CurNode.EndPos:=CurPos.StartPos;
          EndChildNode;
        end;
      end else if UpAtomIs('HELPER') then begin
        IsHelper:=true;
        CreateChildNode;
        CurNode.Desc:=ctnClassHelper;
        CurNode.EndPos:=CurPos.EndPos;
        EndChildNode;
        ReadNextAtom;
      end;
    end;
    if (CurPos.Flag=cafRoundBracketOpen) then begin
      // read inheritage brackets
      IsForward:=false;
      ReadClassInheritance(true);
      ReadNextAtom;
    end;
    if IsHelper then begin
      if not UpAtomIs('FOR') then
        SaveRaiseStringExpectedButAtomFound('for');
      CreateChildNode;
      CurNode.Desc:=ctnClassHelperFor;
      repeat
        ReadNextAtom;
        AtomIsIdentifierSaveE;
        CurNode.EndPos:=CurPos.EndPos;
        ReadNextAtom;
      until CurPos.Flag<>cafPoint;
      EndChildNode;
    end;
  end;
  if CurPos.Flag=cafSemicolon then begin
    if (ClassDesc in AllClassObjects) then
    begin
      if IsForward then begin
        // forward class definition found
        ClassNode.SubDesc:=ClassNode.SubDesc or ctnsForwardDeclaration;
      end else begin
        // very short class found e.g. = class(TAncestor);
        CreateChildNode;
        if ClassDesc in [ctnClass,ctnObjCClass] then
          CurNode.Desc:=ctnClassPublished
        else
          CurNode.Desc:=ctnClassPublic;
        EndChildNode;
      end;
    end;
  end else begin
    // start the first class section (the one without a keyword)
    CreateChildNode;
    if ClassDesc in [ctnClass,ctnObjCClass] then
      CurNode.Desc:=ctnClassPublished
    else
      CurNode.Desc:=ctnClassPublic;
    CurNode.StartPos:=LastAtoms.GetValueAt(0).EndPos;
    if CurPos.Flag=cafEdgedBracketOpen then
      ReadGUID;
    // parse till "end" of class/object
    repeat
      //DebugLn(['TPascalParserTool.KeyWordFuncTypeClass Atom=',GetAtom,' ',CurPos.StartPos>=ClassNode.EndPos]);
      if not ParseInnerClass(CurPos.StartPos,CurPos.EndPos-CurPos.StartPos) then
      begin
        if CurPos.Flag<>cafEnd then
          SaveRaiseStringExpectedButAtomFound('end');
        break;
      end;
      ReadNextAtom;
    until false;
    // end last sub section
    if CurNode.Desc in AllClassSubSections then begin
      CurNode.EndPos:=CurPos.StartPos;
      EndChildNode;
    end;
    // end last class section (public, private, ...)
    CurNode.EndPos:=CurPos.StartPos;
    EndChildNode;
  end;
  if CurPos.Flag=cafEND then begin
    // read extra flags
    ReadNextAtom;
  end;
  // read hint modifier
  ReadHintModifiers;
  if CurPos.Flag=cafSemicolon then
    ReadNextAtom;
  // read post modifiers
  if UpAtomIs('EXTERNAL') then begin
    ReadNextAtom;
    if UpAtomIs('NAME') then begin
      ReadNextAtom;
      ReadConstant(true,false,[]);
    end;
  end;
  if CurPos.Flag<>cafSemicolon then
    UndoReadNextAtom;
  // close class
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  // place cursor on atom behind
  if CurPos.Flag<>cafSemicolon then
    ReadNextAtom;
  //debugln(['TPascalParserTool.KeyWordFuncTypeClass END ',GetAtom,' ',CleanPosToStr(CurPos.StartPos),' CurNode=',CurNode.DescAsString]);
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncTypeClassInterface: boolean;
// class interface, dispinterface
var
  IntfAtomPos: TAtomPosition;
  IntfDesc: TCodeTreeNodeDesc;
  IsJVM: Boolean;
begin
  if not (CurNode.Desc in [ctnTypeDefinition,ctnGenericType]) then
    SaveRaiseExceptionFmt(ctsAnonymDefinitionsAreNotAllowed,['interface']);
  if CurNode.Parent.Desc<>ctnTypeSection then
    SaveRaiseExceptionFmt(ctsNestedDefinitionsAreNotAllowed,['interface']);
  IntfAtomPos:=CurPos;
  // class interface start found
  if UpAtomIs('INTERFACE') then
    IntfDesc:=ctnClassInterface
  else if UpAtomIs('DISPINTERFACE') then
    IntfDesc:=ctnDispinterface
  else
    IntfDesc:=ctnObjCProtocol;
  CreateChildNode;
  CurNode.Desc:=IntfDesc;
  CurNode.StartPos:=IntfAtomPos.StartPos;

  // read content
  ReadNextAtom;
  if (CurPos.Flag<>cafSemicolon) then begin
    if CurPos.Flag=cafWord then begin
      if UpAtomIs('EXTERNAL') then begin
        IsJVM:=Scanner.Values.IsDefined('CPUJVM');
        if IsJVM or (IntfDesc=ctnObjCProtocol) then begin
          CreateChildNode;
          CurNode.Desc:=ctnClassExternal;
          ReadNextAtom;
          if IsJVM then
            ReadConstant(true,false,[]);
          if UpAtomIs('NAME') then begin
            ReadNextAtom;
            ReadConstant(true,false,[]);
          end;
          CurNode.EndPos:=CurPos.StartPos;
          EndChildNode;
        end;
      end;
    end;
    if (CurPos.Flag=cafRoundBracketOpen) then begin
      // read inheritage brackets
      ReadClassInheritance(true);
      ReadNextAtom;
    end;
    if IntfDesc=ctnObjCProtocol then begin
      // start the first class section (the one without a keyword)
      CreateChildNode;
      CurNode.Desc:=ctnClassRequired;
    end;
    if CurPos.Flag=cafEdgedBracketOpen then
      ReadGUID;
    if CurPos.Flag<>cafSemicolon then begin
      // parse till "end" of interface/dispinterface/objcprotocol
      repeat
        if not ParseInnerClass(CurPos.StartPos,CurPos.EndPos-CurPos.StartPos) then
        begin
          if CurPos.Flag<>cafEnd then
            SaveRaiseStringExpectedButAtomFound('end');
          break;
        end;
        ReadNextAtom;
      until false;
    end;
    // end last sub section
    if CurNode.Desc in AllClassSubSections then begin
      CurNode.EndPos:=CurPos.StartPos;
      EndChildNode;
    end;
    // end last class section (public, private, ...)
    if CurNode.Desc in AllClassSections then begin
      CurNode.EndPos:=CurPos.StartPos;
      EndChildNode;
    end;
  end else begin
    // forward definition
    CurNode.SubDesc:=CurNode.SubDesc+ctnsForwardDeclaration;
  end;
  if CurPos.Flag=cafEND then begin
    ReadNextAtom;
    if CurPos.Flag=cafSemicolon then
      ReadNextAtom;
    // read post modifiers
    if UpAtomIs('EXTERNAL') then begin
      ReadNextAtom;
      if UpAtomIs('NAME') then begin
        ReadNextAtom;
        ReadConstant(true,false,[]);
      end;
    end;
    // read hint modifier
    ReadHintModifiers;
    if CurPos.Flag<>cafSemicolon then
      UndoReadNextAtom;
  end;
  // close class interface
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncTypeArray: boolean;
{
  examples:
    array of ...
    array[SubRange] of ...
    array[SubRange,SubRange,...] of ...
    array[Subrange];  // without "of" means array of byte
}
begin
  CreateChildNode;
  // first set the type to open array (an array type without brackets)
  CurNode.Desc:=ctnOpenArrayType;
  ReadNextAtom;
  if (CurPos.Flag=cafEdgedBracketOpen) then begin
    repeat
      ReadNextAtom;
      // this is a ranged array -> change type
      CurNode.Desc:=ctnRangedArrayType;
      CreateChildNode;
      CurNode.Desc:=ctnRangeType;
      ReadSubRange(true);
      CurNode.EndPos:=LastAtoms.GetValueAt(0).EndPos;
      EndChildNode; // close ctnRangeType
      if (CurPos.Flag=cafEdgedBracketClose) then break;
      if (CurPos.Flag<>cafComma) then
        SaveRaiseCharExpectedButAtomFound(']');
    until false;
    ReadNextAtom;
    if CurPos.Flag in [cafSemicolon,cafRoundBracketClose,cafEdgedBracketClose]
    then begin
      // array[] without "of" means array[] of byte
      CurNode.EndPos:=CurPos.StartPos;
      EndChildNode; // close array
      exit(true);
    end;
  end;
  if not UpAtomIs('OF') then
    SaveRaiseStringExpectedButAtomFound('"of"');
  ReadNextAtom;
  Result:=ParseType(CurPos.StartPos,CurPos.EndPos-CurPos.StartPos);
  CurNode.EndPos:=CurPos.StartPos;
  EndChildNode; // close array
  //debugln(['TPascalParserTool.KeyWordFuncTypeArray END Atom=',GetAtom,' CurNode=',CurNode.DescAsString]);
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncTypeProc: boolean;
{
  examples:
    procedure;
    procedure of object;
    procedure(ParmList) of object;
    function(ParmList):SimpleType of object;
    procedure; cdecl; popstack; register; pascal; stdcall;
}
var IsFunction, EqualFound: boolean;
begin
  IsFunction:=UpAtomIs('FUNCTION');
  CreateChildNode;
  CurNode.Desc:=ctnProcedureType;
  ReadNextAtom;
  CreateChildNode;
  CurNode.Desc:=ctnProcedureHead;
  CurNode.SubDesc:=ctnsNeedJITParsing;
  if (CurPos.Flag=cafRoundBracketOpen) then begin
    // read parameter list
    ReadParamList(true,false,[]);
  end;
  if IsFunction then begin
    if (CurPos.Flag=cafColon) then begin
      ReadNextAtom;
      AtomIsIdentifierSaveE;
      ReadNextAtom;
      if CurPos.Flag=cafPoint then begin
        ReadNextAtom;
        AtomIsIdentifierSaveE;
        ReadNextAtom;
      end;
    end else begin
      SaveRaiseCharExpectedButAtomFound(':');
    end;
  end;
  if UpAtomIs('OF') then begin
    if not ReadNextUpAtomIs('OBJECT') then
      SaveRaiseStringExpectedButAtomFound('"object"');
    ReadNextAtom;
  end;
  if (CurPos.Flag=cafEqual)
  and (CurNode.Parent.Desc in [ctnConstDefinition,ctnVarDefinition]) then begin
    // for example  'const f: procedure = nil;'
  end else begin
    if CurPos.Flag=cafSemicolon then begin
      ReadNextAtom;
      EqualFound:=false;
    end else if (CurPos.Flag=cafEqual) then begin
      EqualFound:=true;
    end else
      EqualFound:=false;
    if not EqualFound then begin
      // read modifiers
      repeat
        if (CurPos.StartPos>SrcLen)
        or (not IsKeyWordProcedureTypeSpecifier.DoIdentifier(@Src[CurPos.StartPos]))
        then begin
          UndoReadNextAtom;
          break;
        end;
        if UpAtomIs('IS') then begin
          ReadNextAtom;
          if not UpAtomIs('NESTED') then
            SaveRaiseStringExpectedButAtomFound('nested');
        end else if UpAtomIs('OF') then begin
          ReadNextAtom;
          if not UpAtomIs('OBJECT') then
            SaveRaiseStringExpectedButAtomFound('object');
        end;
        ReadNextAtom;
        if CurPos.Flag<>cafSemicolon then begin
          if (CurPos.Flag=cafEqual) then begin
            break;
          end;
          // delphi/fpc allow proc modifiers without semicolons
          if (CurPos.StartPos>SrcLen)
          or (not IsKeyWordProcedureTypeSpecifier.DoIdentifier(@Src[CurPos.StartPos]))
          then
            SaveRaiseCharExpectedButAtomFound(';');
          UndoReadNextAtom;
        end;
        ReadNextAtom;
      until false;
    end;
  end;
  CurNode.EndPos:=CurPos.StartPos;
  EndChildNode;
  CurNode.EndPos:=CurPos.StartPos;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncTypeSet: boolean;
{
  examples:
    set of Identifier;
    set of SubRange;
}
begin
  CreateChildNode;
  CurNode.Desc:=ctnSetType;
  if not ReadNextUpAtomIs('OF') then
    SaveRaiseStringExpectedButAtomFound('"of"');
  ReadNextAtom;
  Result:=KeyWordFuncTypeDefault;
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncTypeLabel: boolean;
// 'label;'
begin
  CreateChildNode;
  CurNode.Desc:=ctnLabelType;
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  ReadNextAtom;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncTypeType: boolean;
// 'type identifier'
begin
  if not LastAtomIs(0,'=') then
    SaveRaiseStringExpectedButAtomFound(ctsIdentifier);
  CreateChildNode;
  CurNode.Desc:=ctnTypeType;
  ReadNextAtom;
  Result:=ParseType(CurPos.StartPos,CurPos.EndPos-CurPos.StartPos);
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
end;

function TPascalParserTool.KeyWordFuncTypeFile: boolean;
// 'file' or 'file of <type>'
begin
  CreateChildNode;
  CurNode.Desc:=ctnFileType;
  if ReadNextUpAtomIs('OF') then begin
    ReadNextAtom;
    Result:=ParseType(CurPos.StartPos,CurPos.EndPos-CurPos.StartPos);
    if not Result then exit;
  end;
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncTypePointer: boolean;
// '^Identifier'
begin
  CreateChildNode;
  CurNode.Desc:=ctnPointerType;
  ReadNextAtom;
  Result:=ParseType(CurPos.StartPos,CurPos.EndPos-CurPos.StartPos);
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
end;

function TPascalParserTool.KeyWordFuncTypeDefault: boolean;
{ check for enumeration, subrange and identifier types

  examples:
    integer
    1..3
    (a,b:=3,c=4)
    (a)..4
    Low(integer)..High(integer)
    'a'..'z'
}
var SubRangeOperatorFound: boolean;

  procedure ReadTillTypeEnd;
  begin
    // read till ';', ':', ')', '=', 'end'
    while (CurPos.StartPos<=SrcLen) do begin
      if (CurPos.Flag in [cafSemicolon,cafColon,cafRoundBracketClose,
        cafEqual,cafEdgedBracketClose])
      or (AtomIsKeyWord
          and (not IsKeyWordInConstAllowed.DoIdentifier(@Src[CurPos.StartPos])))
      then
        break;
      if (CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen]) then
        ReadTilBracketClose(true)
      else if AtomIs('..') then begin
        if SubRangeOperatorFound then
          SaveRaiseException(ctsUnexpectedSubRangeOperatorFound);
        SubRangeOperatorFound:=true;
      end;
      ReadNextAtom;
    end;
  end;

// TPascalParserTool.KeyWordFuncTypeDefault: boolean
begin
  CreateChildNode;
  SubRangeOperatorFound:=false;
  if CurPos.Flag in AllCommonAtomWords then begin
    AtomIsIdentifierSaveE;
    ReadTypeReference;
    if CurNode.EndPos > 0 then
      Exit(True);
    while (CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen]) do begin
      ReadTilBracketClose(true);
      ReadNextAtom;
    end;
    if AtomIs('..') then begin
      // a subrange
      CurNode.Desc:=ctnRangeType;
      ReadTillTypeEnd;
      if not SubRangeOperatorFound then
        SaveRaiseException(ctsInvalidSubrange);
      CurNode.EndPos:=CurPos.StartPos;
    end else if AtomIsChar('<') and (Scanner.CompilerMode in [cmOBJFPC,cmFPC])
    and (LastUpAtomIs(0,'STRING')) then begin
      // string<   a string with an encoding
      CurNode.Desc:=ctnIdentifier;
      repeat
        ReadNextAtom;
        if AtomIsChar('>') then break;
        case CurPos.Flag of
        cafRoundBracketOpen,cafEdgedBracketOpen: ReadTilBracketClose(true);
        cafNone:
          if (CurPos.StartPos>SrcLen) then
            SaveRaiseCharExpectedButAtomFound('>')
          else if (((CurPos.EndPos-CurPos.StartPos=1)
                and (Src[CurPos.StartPos] in ['+','-','*','&','$'])))
              or AtomIsNumber
          then begin
          end else begin
            SaveRaiseCharExpectedButAtomFound('>')
          end;
        else
          SaveRaiseCharExpectedButAtomFound('>');
        end;
      until false;
      CurNode.EndPos:=CurPos.EndPos;
      ReadNextAtom;
    end else begin
      // an identifier
      CurNode.Desc:=ctnIdentifier;
      CurNode.EndPos:=CurPos.StartPos;
    end;
  end else begin
    // enum or subrange
    ReadTillTypeEnd;
    if SubRangeOperatorFound then begin
      // a subrange
      CurNode.Desc:=ctnRangeType;
      CurNode.EndPos:=CurPos.StartPos;
    end else begin
      // an enum or syntax error
      MoveCursorToNodeStart(CurNode);
      ReadNextAtom;
      if (CurPos.Flag=cafRoundBracketOpen) then begin
        // an enumeration -> read all enums
        CurNode.Desc:=ctnEnumerationType;
        repeat
          ReadNextAtom; // read enum name
          if (CurPos.Flag=cafRoundBracketClose) then break;
          AtomIsIdentifierSaveE;
          CreateChildNode;
          CurNode.Desc:=ctnEnumIdentifier;
          CurNode.EndPos:=CurPos.EndPos;
          EndChildNode; // close enum node
          ReadNextAtom;
          if AtomIs(':=') or (CurPos.Flag=cafEqual) then begin
            // read ordinal value
            ReadNextAtom;
            ReadConstant(true,false,[]);
          end;
          if (CurPos.Flag=cafRoundBracketClose) then break;
          if (CurPos.Flag<>cafComma) then
            SaveRaiseCharExpectedButAtomFound(')');
        until false;
        CurNode.EndPos:=CurPos.EndPos;
        ReadNextAtom;
      end else
        SaveRaiseException(ctsInvalidType);
    end;
  end;
  EndChildNode;
  Result:=true;
end;

function TPascalParserTool.KeyWordFuncTypeRecordCase: boolean;
{ after parsing CurPos is on the 'end' or the ')'

  record
    i: packed record
         j: integer;
         k: record end;
         case y: integer of
           0: (a: integer deprecated);
           1,2,3: (b: array[char] of char; c: char);
           3: ( d: record
                     case byte of
                       10: (i: integer; );
                       11: (y: byte);
                   end; );
           4: (e: integer;
               case enum:(one, two, three) of
                  one:(F: Integer);
                  two:(D: Byte);
                  three:(Z:PChar);
               );
       end;
  end;
}
{off $DEFINE VerboseRecordCase}
  procedure RaiseCaseOnlyAllowedInRecords;
  begin
    //debugln(['RaiseCaseOnlyAllowedInRecords ',CurNode.DescAsString]);
    SaveRaiseException('Case only allowed in records');
  end;

begin
  if not UpAtomIs('CASE') then
    SaveRaiseException('[TPascalParserTool.KeyWordFuncTypeRecordCase] '
      +'internal error');
  if (CurNode.Desc=ctnRecordVariant)
  or ((CurNode.Desc in AllClassSections)
      and (CurNode.Parent.Desc=ctnRecordType))
  then begin
    // ok
  end else begin
    RaiseCaseOnlyAllowedInRecords;
  end;
  CreateChildNode;
  CurNode.Desc:=ctnRecordCase;
  {$IFDEF VerboseRecordCase}
  debugln(['TPascalParserTool.KeyWordFuncTypeRecordCase START case="',GetAtom,'"']);
  {$ENDIF}
  ReadNextAtom; // read ordinal type
  { case a of
    case a:b of
    case a:b.c of
    case a:(b,c) of
  }
  AtomIsIdentifierSaveE;
  CreateChildNode;
  CurNode.Desc:=ctnIdentifier;
  {$IFDEF VerboseRecordCase}
  debugln(['TPascalParserTool.KeyWordFuncTypeRecordCase case name="',GetAtom,'"']);
  {$ENDIF}
  ReadNextAtom;
  if (CurPos.Flag=cafColon) then begin
    // has type
    CurNode.Desc:=ctnVarDefinition;
    ReadNextAtom;
    if CurPos.Flag=cafRoundBracketOpen then begin
      CreateChildNode;
      CurNode.Desc:=ctnEnumerationType;
      ReadNextAtom;
      if CurPos.Flag<>cafRoundBracketClose then begin
        repeat
          // read enum
          AtomIsIdentifierSaveE;
          CreateChildNode;
          CurNode.Desc:=ctnEnumIdentifier;
          CurNode.EndPos:=CurPos.EndPos;
          EndChildNode;
          ReadNextAtom;
          if CurPos.Flag=cafRoundBracketClose then break;
          if CurPos.Flag<>cafComma then
            SaveRaiseCharExpectedButAtomFound(',');
          ReadNextAtom;
        until false;
      end;
      CurNode.EndPos:=CurPos.EndPos;
      EndChildNode; // close ctnEnumerationType
      ReadNextAtom;
    end else begin
      // identifier
      AtomIsIdentifierSaveE;
      CreateChildNode;
      CurNode.Desc:=ctnIdentifier;
      CurNode.EndPos:=CurPos.EndPos;
      ReadNextAtom;
      if CurPos.Flag=cafPoint then begin
        ReadNextAtom; // unit.type
        AtomIsIdentifierSaveE;
        CurNode.EndPos:=CurPos.EndPos;
        ReadNextAtom;
      end;
      EndChildNode; // close ctnIdentifier
    end;
  end else
  if (CurPos.Flag=cafPoint) then // unit.type
    while CurPos.Flag=cafPoint do begin
      ReadNextAtom;
      AtomIsIdentifierSaveE;
      ReadNextAtom;
    end;
  // close ctnIdentifier/ctnVarDefinition
  CurNode.EndPos:=LastAtoms.GetValueAt(0).EndPos;
  EndChildNode;
  if not UpAtomIs('OF') then // read 'of'
    SaveRaiseStringExpectedButAtomFound('"of"');
  // read all variants
  repeat
    // read constant(s) (variant identifier)
    ReadNextAtom;
    {$IFDEF VerboseRecordCase}
    debugln(['TPascalParserTool.KeyWordFuncTypeRecordCase variant start="',GetAtom,'"']);
    {$ENDIF}
    if (CurPos.Flag in [cafRoundBracketClose,cafEnd]) then break;
    CreateChildNode;
    CurNode.Desc:=ctnRecordVariant;
    repeat
      ReadConstant(true,false,[]);
      if (CurPos.Flag=cafColon) then break;
      if (CurPos.Flag<>cafComma) then
        SaveRaiseCharExpectedButAtomFound(':');
      ReadNextAtom;
    until false;
    // read '('
    ReadNextAtom;
    if (CurPos.Flag<>cafRoundBracketOpen) then
      SaveRaiseCharExpectedButAtomFound('(');
    // read all variables
    ReadNextAtom; // read first variable name
    repeat
      {$IFDEF VerboseRecordCase}
      debugln(['TPascalParserTool.KeyWordFuncTypeRecordCase variable="',GetAtom,'"']);
      {$ENDIF}
      if (CurPos.Flag=cafRoundBracketClose) then begin
        // end of variant record
      end else if UpAtomIs('CASE') then begin
        // sub record variant
        KeyWordFuncTypeRecordCase();
        if (CurPos.Flag<>cafRoundBracketClose) then
          SaveRaiseCharExpectedButAtomFound(')');
      end else begin
        // sub identifier
        repeat
          AtomIsIdentifierSaveE;
          CreateChildNode;
          CurNode.Desc:=ctnVarDefinition;
          CurNode.EndPos:=CurPos.EndPos;
          ReadNextAtom;
          if (CurPos.Flag=cafColon) then break;
          if (CurPos.Flag<>cafComma) then
            SaveRaiseCharExpectedButAtomFound(',');
          EndChildNode;
          ReadNextAtom; // read next variable name
        until false;
        ReadNextAtom; // read type
        Result:=ParseType(CurPos.StartPos,CurPos.EndPos-CurPos.StartPos);
        if not Result then begin
          {$IFDEF VerboseRecordCase}
          debugln(['TPascalParserTool.KeyWordFuncTypeRecordCase ParseType failed']);
          {$ENDIF}
          exit;
        end;
        {$IFDEF VerboseRecordCase}
        debugln(['TPascalParserTool.KeyWordFuncTypeRecordCase Hint modifier: "',GetAtom,'"']);
        {$ENDIF}
        ReadHintModifiers;
        CurNode.EndPos:=CurPos.EndPos;
        EndChildNode; // close variable definition
      end;
      {$IFDEF VerboseRecordCase}
      debugln(['TPascalParserTool.KeyWordFuncTypeRecordCase variable end="',GetAtom,'"']);
      {$ENDIF}
      if (CurPos.Flag=cafRoundBracketClose) then begin
        // end of variant record
        ReadNextAtom;
        break;
      end;
      if CurPos.Flag<>cafSemicolon then
        SaveRaiseCharExpectedButAtomFound(';');
      ReadNextAtom;
    until false;
    CurNode.EndPos:=CurPos.StartPos;
    {$IFDEF VerboseRecordCase}
    debugln(['TPascalParserTool.KeyWordFuncTypeRecordCase variant end="',GetAtom,'" ',CurNode.DescAsString,' ',dbgstr(copy(Src,CurNode.StartPos,CurNode.EndPos-CurNode.StartPos))]);
    {$ENDIF}
    EndChildNode; // close variant
    if (CurPos.Flag in [cafEnd,cafRoundBracketClose]) then
      break;
    if CurPos.Flag<>cafSemicolon then
      SaveRaiseCharExpectedButAtomFound(';');
    // read next variant
  until false;
  {$IFDEF VerboseRecordCase}
  debugln(['TPascalParserTool.KeyWordFuncTypeRecordCase CLOSE "',GetAtom,'" at ',CleanPosToStr(CurPos.StartPos)]);
  {$ENDIF}
  if CurPos.Flag=cafEND then
    UndoReadNextAtom;
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode; // close case
  {$IFDEF VerboseRecordCase}
  debugln(['TPascalParserTool.KeyWordFuncTypeRecordCase END CurNode=',CurNode.DescAsString,' Atom="',GetAtom,'" at ',CleanPosToStr(CurPos.StartPos)]);
  {$ENDIF}
  Result:=true;
end;

procedure TPascalParserTool.SaveRaiseCharExpectedButAtomFound(c: char);
var
  a: String;
begin
  a:=GetAtom;
  if a='' then a:=ctsEndOfFile;
  SaveRaiseExceptionFmt(ctsStrExpectedButAtomFound,[c,a]);
end;

procedure TPascalParserTool.RaiseCharExpectedButAtomFound(c: char);
var
  a: String;
begin
  a:=GetAtom;
  if a='' then a:=ctsEndOfFile;
  RaiseExceptionFmt(ctsStrExpectedButAtomFound,[c,a]);
end;

procedure TPascalParserTool.SaveRaiseStringExpectedButAtomFound(const s: string
  );
var
  a: String;
begin
  a:=GetAtom;
  if a='' then a:=ctsEndOfFile;
  SaveRaiseExceptionFmt(ctsStrExpectedButAtomFound,[s,a]);
end;

procedure TPascalParserTool.RaiseStringExpectedButAtomFound(const s: string);
var
  a: String;
begin
  a:=GetAtom;
  if a='' then a:=ctsEndOfFile;
  RaiseExceptionFmt(ctsStrExpectedButAtomFound,[s,a]);
end;

procedure TPascalParserTool.SaveRaiseUnexpectedKeyWord;
begin
  SaveRaiseExceptionFmt(ctsUnexpectedKeyword,[GetAtom]);
end;

procedure TPascalParserTool.RaiseUnexpectedKeyWord;
begin
  RaiseExceptionFmt(ctsUnexpectedKeyword,[GetAtom]);
end;

procedure TPascalParserTool.SaveRaiseIllegalQualifier;
begin
  SaveRaiseExceptionFmt(ctsIllegalQualifier,[GetAtom]);
end;

procedure TPascalParserTool.RaiseIllegalQualifier;
begin
  RaiseExceptionFmt(ctsIllegalQualifier,[GetAtom]);
end;

procedure TPascalParserTool.SaveRaiseEndOfSourceExpected;
begin
  SaveRaiseExceptionFmt(ctsEndofSourceExpectedButAtomFound,[GetAtom]);
end;

procedure TPascalParserTool.ReadConstExpr;
begin
  if (CurPos.Flag <> cafEqual) then
    SaveRaiseCharExpectedButAtomFound('=');
  // read constant
  ReadNextAtom;
  CreateChildNode;
  CurNode.Desc := ctnConstant;
  repeat
    if (CurPos.Flag in [cafRoundBracketOpen, cafEdgedBracketOpen]) then
      ReadTilBracketClose(true);
    if (CurPos.Flag in AllCommonAtomWords)
    and (not IsKeyWordInConstAllowed.DoIdentifier(@Src[CurPos.StartPos]))
    and AtomIsKeyWord then
      SaveRaiseStringExpectedButAtomFound('constant');
    if (CurPos.Flag = cafWord) and
       (UpAtomIs('DEPRECATED') or UpAtomIs('PLATFORM')
       or UpAtomIs('UNIMPLEMENTED') or UpAtomIs('EXPERIMENTAL')) then Break;
    if (CurPos.Flag = cafSemicolon) then break;
    CurNode.EndPos := CurPos.EndPos;
    ReadNextAtom;
  until (CurPos.StartPos > SrcLen);
  // close ctnConstant node
  EndChildNode;
end;

procedure TPascalParserTool.InitExtraction;
begin
  if ExtractMemStream=nil then
    ExtractMemStream:=TMemoryStream.Create;
  ExtractMemStream.Position:=0;
end;

function TPascalParserTool.GetExtraction(InUpperCase: boolean): string;
begin
  SetLength(Result,ExtractMemStream.Position);
  ExtractMemStream.Position:=0;
  if Result<>'' then
    ExtractMemStream.Read(Result[1],length(Result));
  if InUpperCase then
    Result:=UpperCaseStr(Result);
end;

function TPascalParserTool.ExtractStreamEndIsIdentChar: boolean;
var c: char;
begin
  if ExtractMemStream.Position=0 then begin
    Result:=false;
    exit;
  end;
  ExtractMemStream.Position:=ExtractMemStream.Position-1;
  ExtractMemStream.Read(c,1);
  Result:=IsIdentChar[c];
end;

procedure TPascalParserTool.ExtractNextAtom(AddAtom: boolean;
  Attr: TProcHeadAttributes);
// add current atom and text before, then read next atom
// if not phpWithComments in Attr then the text before will be shortened
var
  LastAtomEndPos: integer;
  LastStreamPos: TFPCStreamSeekType;
const
  space: char = ' ';
begin
  LastStreamPos:=ExtractMemStream.Position;
  if LastAtoms.Count>0 then begin
    LastAtomEndPos:=LastAtoms.GetValueAt(0).EndPos;
    if phpWithComments in Attr then begin
      // add space/comment between pascal atoms
      ExtractMemStream.Write(Src[LastAtomEndPos],CurPos.StartPos-LastAtomEndPos);
    end else if (ExtractMemStream.Position>0) then
    begin
      // some space/comments were skipped
      // -> check if a space must be inserted
      if AddAtom
      and ( ((phpCommentsToSpace in Attr) and (CurPos.StartPos>LastAtomEndPos))
         or ((CurPos.StartPos<=SrcLen) and (IsIdentChar[Src[CurPos.StartPos]])
             and ExtractStreamEndIsIdentChar)
         )
      then begin
        ExtractMemStream.Write(space,1);
        LastStreamPos:=ExtractMemStream.Position;
      end;
    end;
  end;
  if AddAtom then begin
    ExtractMemStream.Write(Src[CurPos.StartPos],CurPos.EndPos-CurPos.StartPos);
  end;
  if (ExtractSearchPos>0)
  and (ExtractSearchPos<=ExtractMemStream.Position)
  then begin
    ExtractFoundPos:=ExtractSearchPos-1-LastStreamPos+CurPos.StartPos;
    ExtractSearchPos:=-1;
  end;
  ReadNextAtom;
end;

procedure TPascalParserTool.FetchScannerSource(Range: TLinkScannerRange);
var
  AllChanged: Boolean;
  NewSrc: String;
  NewSrcLen: Integer;
  OldP: PChar;
  NewP: PChar;
  DiffPos: PtrInt;
  Node: TCodeTreeNode;
  DeleteNode: TCodeTreeNode;
begin
  // update scanned code
  if FLastScannerChangeStep=Scanner.ChangeStep then begin
    if LastErrorValid then
      RaiseLastError;
    // no change => keep all nodes
    exit;
  end else begin
    // code has changed
    //debugln(['TPascalParserTool.FetchScannerSource link scanner has changed ',MainFilename]);
    FLastScannerChangeStep:=Scanner.ChangeStep;
    AllChanged:=(FLastCompilerMode<>Scanner.CompilerMode)
             or (FLastCompilerModeSwitches<>Scanner.CompilerModeSwitches);
    FLastCompilerMode:=Scanner.CompilerMode;
    FLastCompilerModeSwitches:=Scanner.CompilerModeSwitches;
    NewSrc:=Scanner.CleanedSrc;
    NewSrcLen:=length(NewSrc);
    if AllChanged then begin
      {$IFDEF VerboseUpdateNeeded}
      if Tree.Root<>nil then
        debugln(['TPascalParserTool.FetchScannerSource compiler clean all nodes, because compiler mode/values changed ',MainFilename]);
      {$ENDIF}
    end else begin
      // find the first difference in source
      OldP:=PChar(Src);
      NewP:=PChar(NewSrc);
      if (OldP=nil) or (NewP=nil) then begin
        {$IFDEF VerboseUpdateNeeded}
        if OldP=nil then
          debugln(['TPascalParserTool.FetchScannerSource there is now source ',MainFilename])
        else
          debugln(['TPascalParserTool.FetchScannerSource there is no source anymore ',MainFilename]);
        {$ENDIF}
        AllChanged:=true;
      end
      else begin
        while (NewP^=OldP^) do begin
          if (NewP^=#0) and (NewP-PChar(NewSrc)>=NewSrcLen) then break;
          inc(NewP);
          inc(OldP);
        end;
        DiffPos:=NewP-PChar(NewSrc)+1;
        if DiffPos<=1 then begin
          {$IFDEF VerboseUpdateNeeded}
          debugln(['TPascalParserTool.FetchScannerSource first character changed ',MainFilename]);
          {$ENDIF}
          AllChanged:=true;
        end else if (DiffPos>NewSrcLen) and (SrcLen=NewSrcLen)
        and (not LastErrorValid) then begin
          // no change and no error => keep all nodes
          {$IFDEF VerboseUpdateNeeded}
          debugln(['TPascalParserTool.FetchScannerSource cleansrc has not changed => keep all nodes ',MainFilename]);
          {$ENDIF}
          exit;
        end else begin
          // some parts are the same
          Node:=Tree.Root;
          if (Node=nil) or (DiffPos<=Node.StartPos) then begin
            // difference is in front of first node => all changed
            {$IFDEF VerboseUpdateNeeded}
            debugln(['TPascalParserTool.FetchScannerSource difference is in front of first node => all changed ',MainFilename]);
            {$ENDIF}
            AllChanged:=true;
          end else begin
            while (Node.NextBrother<>nil) and (Node.NextBrother.StartPos<DiffPos) do
              Node:=Node.NextBrother;
            if (Node.Desc=ctnEndPoint) and (not LastErrorValid) then begin
              // difference is behind nodes => keep all nodes
              {$IFDEF VerboseUpdateNeeded}
              debugln(['TPascalParserTool.FetchScannerSource cleansrc was changed after scanned nodes => keep all nodes, last node=',Node.DescAsString,' ',MainFilename]);
              {$ENDIF}
              exit;
            end else begin
              // some nodes can be kept
              {$IFDEF VerboseUpdateNeeded}
              debugln(['TPascalParserTool.FetchScannerSource some nodes can be kept. DiffPos=',DiffPos,' NewSrc="',dbgstr(NewSrc,DiffPos-40,40),'|',dbgstr(NewSrc,DiffPos,40),'", TopNode=',Node.DescAsString,',StartPos=',Node.StartPos,',EndPos=',Node.EndPos,', Node.NextBrother=',Node.NextBrother<>nil,' File=',MainFilename]);
              {$ENDIF}
              // mark section as unfinished
              Node.EndPos:=-1;
              // find first node to delete
              if Node.Desc in [ctnInitialization,ctnFinalization,ctnBeginBlock]
              then begin
                // statement nodes are always parsed completely
                DeleteNode:=Node;
                Node:=Node.PriorBrother;
              end else begin
                DeleteNode:=Node.LastChild;
                if DeleteNode<>nil then begin
                  while (DeleteNode.PriorBrother<>nil)
                  and (DeleteNode.StartPos>=DiffPos) do
                    DeleteNode:=DeleteNode.PriorBrother;
                  if (DeleteNode.Desc=ctnUsesSection)
                  and (DiffPos>=DeleteNode.StartPos+length('uses')) then begin
                    // keep uses section, just delete the used units nodes
                    DeleteNode.EndPos:=-1;
                    DeleteNode:=DeleteNode.Next;
                  end;
                end else
                  DeleteNode:=Node.NextBrother;
              end;
              if DeleteNode<>nil then begin
                {$IFDEF VerboseUpdateNeeded}
                debugln(['TPascalParserTool.FetchScannerSource keep parts, last kept section=',Node.DescAsString,' FirstDeleteNode=',DeleteNode.DescAsString,' ',MainFilename]);
                {$ENDIF}
                if not LastErrorIsInFrontOfCleanedPos(DeleteNode.StartPos) then
                  ClearLastError;
                DoDeleteNodes(DeleteNode);
              end else begin
                {$IFDEF VerboseUpdateNeeded}
                debugln(['TPascalParserTool.FetchScannerSource keep all nodes, open last section=',Node.DescAsString,' ',MainFilename]);
                {$ENDIF}
                if not LastErrorIsInFrontOfCleanedPos(DiffPos) then
                  ClearLastError;
              end;
            end;
          end;
        end;
      end;
    end;
    if AllChanged then begin
      DoDeleteNodes(Tree.Root);
      ClearLastError;
    end;
    Src:=NewSrc;
    SrcLen:=NewSrcLen;
    {$IFDEF VerboseUpdateNeeded}
    DebugLn(['TPascalParserTool.FetchScannerSource source changed ',MainFilename]);
    {$ENDIF}
    FRangeValidTill:=lsrInit;
  end;
end;

function TPascalParserTool.FindFirstNodeOnSameLvl(
  StartNode: TCodeTreeNode): TCodeTreeNode;
begin
  Result:=StartNode;
  if Result=nil then exit;
  if Result.Parent=nil then begin
    while Result.PriorBrother<>nil do
      Result:=Result.PriorBrother;
  end else begin
    Result:=Result.Parent;
    while (Result.Desc in AllCodeSections) and (Result.PriorBrother<>nil) do
      Result:=Result.PriorBrother;
    while (Result<>nil) and (Result.FirstChild=nil) do
      Result:=Result.NextBrother;
    Result:=Result.FirstChild;
  end;
end;

function TPascalParserTool.FindNextNodeOnSameLvl(
  StartNode: TCodeTreeNode): TCodeTreeNode;
begin
  Result:=StartNode;
  if Result=nil then exit;
  if Result.NextBrother<>nil then
    Result:=Result.NextBrother
  else begin
    Result:=Result.Parent;
    if Result=nil then exit;
    Result:=Result.NextBrother;
    while (Result<>nil) and (Result.FirstChild=nil) do
      Result:=Result.NextBrother;
    if Result=nil then exit;
    Result:=Result.FirstChild;
  end;
end;

function TPascalParserTool.FindPrevNodeOnSameLvl(StartNode: TCodeTreeNode
  ): TCodeTreeNode;
begin
  Result:=StartNode;
  if Result=nil then exit;
  if Result.PriorBrother<>nil then
    Result:=Result.PriorBrother
  else begin
    Result:=Result.Parent;
    if Result=nil then exit;
    Result:=Result.PriorBrother;
    while (Result<>nil) and (Result.LastChild=nil) do
      Result:=Result.PriorBrother;
    if Result=nil then exit;
    Result:=Result.LastChild;
  end;
end;

function TPascalParserTool.FindRootNode(Desc: TCodeTreeNodeDesc
  ): TCodeTreeNode;
begin
  Result:=Tree.FindRootNode(Desc);
end;

function TPascalParserTool.NodeHasParentOfType(ANode: TCodeTreeNode;
  NodeDesc: TCodeTreeNodeDesc): boolean;
begin
  if ANode<>nil then begin
    repeat
      ANode:=ANode.Parent;
    until (ANode=nil) or (ANode.Desc=NodeDesc);
  end;
  Result:=(ANode<>nil);
end;

procedure TPascalParserTool.BuildTreeAndGetCleanPos(TreeRange: TTreeRange;
  ScanRange: TLinkScannerRange; const CursorPos: TCodeXYPosition;
  out CleanCursorPos: integer; BuildTreeFlags: TBuildTreeFlags);
var
  CaretType: integer;
  IgnorePos: TCodePosition;
  Node: TCodeTreeNode;
begin
  //DebugLn(['TPascalParserTool.BuildTreeAndGetCleanPos ',MainFilename,' btSetIgnoreErrorPos=',btSetIgnoreErrorPos in BuildTreeFlags,' btKeepIgnoreErrorPos=',btKeepIgnoreErrorPos in BuildTreeFlags,' CursorPos=',dbgs(CursorPos)]);
  if (btSetIgnoreErrorPos in BuildTreeFlags) then begin
    // ignore errors after cursor position
    if (CursorPos.Code<>nil) then begin
      IgnorePos.Code:=CursorPos.Code;
      IgnorePos.Code.LineColToPosition(CursorPos.Y,CursorPos.X,IgnorePos.P);
      if IgnorePos.P<1 then IgnorePos.Code:=nil;
      //debugln(['TPascalParserTool.BuildTreeAndGetCleanPos IgnorePos=',dbgs(IgnorePos),' After=',IgnorePos.P,'=',copy(CursorPos.Code.Source,IgnorePos.P,10)]);
      IgnoreErrorAfter:=IgnorePos;
    end else
      ClearIgnoreErrorAfter;
  end
  else if not (btKeepIgnoreErrorPos in BuildTreeFlags) then
    ClearIgnoreErrorAfter;

  if (TreeRange in [trTillCursor,trTillCursorSection]) then begin
    ScanRange:=lsrEnd;
    // check if cursor position is in scanned range
    if (Tree<>nil) and (Tree.Root<>nil) then begin
      CaretType:=CaretToCleanPos(CursorPos, CleanCursorPos);
      if (CaretType=0) or (CaretType=-1) then begin
        Node:=FindSectionNodeAtPos(CleanCursorPos);
        if (Node<>nil) and (Node.EndPos>CleanCursorPos) then begin
          // cursor in scanned range
          if Node.Desc in (AllSourceTypes+[ctnInterface]) then
            ScanRange:=lsrImplementationStart
          else if Node.Desc=ctnUsesSection then begin
            if Node.Parent.Desc=ctnImplementation then
              ScanRange:=lsrImplementationUsesSectionStart
            else
              ScanRange:=lsrMainUsesSectionStart;
          end else if Node.Desc=ctnImplementation then
            ScanRange:=lsrInitializationStart
          else if Node.Desc=ctnInitialization then
            ScanRange:=lsrFinalizationStart
          else
            ScanRange:=lsrEnd;
          if UpdateNeeded(ScanRange) then
            ScanRange:=lsrEnd;
        end;
      end;
    end;
  end;

  // parse code
  BuildTree(ScanRange);
  // find the CursorPos in cleaned source
  CaretType:=CaretToCleanPos(CursorPos, CleanCursorPos);
  if (CaretType=0) or (CaretType=-1) then begin
    BuildSubTree(CleanCursorPos);
    exit;
  end
  else if (CaretType=-2) or (not (btCursorPosOutAllowed in BuildTreeFlags)) then
    RaiseException(ctsCursorPosOutsideOfCode);
  // cursor outside of clean code
  CleanCursorPos:=-1;
end;

procedure TPascalParserTool.BuildTreeAndGetCleanPos(
  const CursorPos: TCodeXYPosition; out CleanCursorPos: integer;
  BuildTreeFlags: TBuildTreeFlags);
begin
  BuildTreeAndGetCleanPos(trTillRange,lsrEnd,CursorPos,CleanCursorPos,
                          BuildTreeFlags);
end;

function TPascalParserTool.ReadTilTypeOfProperty(
  PropertyNode: TCodeTreeNode): boolean;
begin
  MoveCursorToNodeStart(PropertyNode);
  ReadNextAtom; // read keyword 'property'
  if UpAtomIs('CLASS') then ReadNextAtom;
  ReadNextAtom; // read property name
  AtomIsIdentifierSaveE;
  ReadNextAtom;
  if (CurPos.Flag=cafEdgedBracketOpen) then begin
    // read parameter list
    ReadTilBracketClose(true);
    ReadNextAtom;
  end;
  if (CurPos.Flag<>cafColon) then begin
    Result:=false;
    exit;
  end;
  ReadNextAtom; // read type
  AtomIsIdentifierSaveE;
  Result:=true;
end;

function TPascalParserTool.ReadTilGetterOfProperty(
  PropertyNode: TCodeTreeNode): boolean;
begin
  Result := False;
  if ReadTilTypeOfProperty(PropertyNode) then begin
    ReadNextAtom;
    while CurPos.Flag=cafPoint do begin
      ReadNextAtom;
      if not AtomIsIdentifier then Exit;
      ReadNextAtom;
    end;
    if UpAtomIs('INDEX') then begin
      // read index constant
      ReadNextAtom;
      while CurPos.Flag=cafPoint do begin
        ReadNextAtom;
        if not AtomIsIdentifier then Exit;
        ReadNextAtom;
      end;
    end;
    if not UpAtomIs('READ') then Exit;
    ReadNextAtom;
    Result := CurPos.StartPos < SrcLen;
  end;
end;

procedure TPascalParserTool.ReadGUID;

  procedure RaiseStringConstantExpected;
  begin
    SaveRaiseStringExpectedButAtomFound(ctsStringConstant);
  end;

begin
  CreateChildNode;
  CurNode.Desc:=ctnClassGUID;
  // read GUID
  ReadNextAtom;
  if (not AtomIsStringConstant) and (not AtomIsIdentifier) then
    RaiseStringConstantExpected;
  ReadNextAtom;
  if CurPos.Flag<>cafEdgedBracketClose then
    SaveRaiseCharExpectedButAtomFound(']');
  CurNode.EndPos:=CurPos.EndPos;
  EndChildNode;
  ReadNextAtom;
end;

procedure TPascalParserTool.ReadClassInheritance(CreateChildNodes: boolean);
// cursor must be the round bracket open
// at the end cursor will be on round bracket close
begin
  // read inheritage
  if CreateChildNodes then begin
    CreateChildNode;
    CurNode.Desc:=ctnClassInheritance;
  end;
  // read list of ancestors, interfaces
  ReadNextAtom;
  if CurPos.Flag<>cafRoundBracketClose then begin
    repeat
      if UpAtomIs('SPECIALIZE') then begin
        // specialize Identifier<Identifier>
        ReadSpecialize(CreateChildNodes);
      end else begin
        // read Identifier or Unit.Identifier
        AtomIsIdentifierSaveE;
        if CreateChildNodes then begin
          CreateChildNode;
          CurNode.Desc:=ctnIdentifier;
        end;
        ReadTypeReference;
        if (CurNode.EndPos < 0) and CreateChildNodes then begin
          CurNode.EndPos:=CurPos.EndPos;
          EndChildNode;
        end;
      end;
      // read comma or )
      if CurPos.Flag=cafRoundBracketClose then break;
      if CurPos.Flag<>cafComma then
        SaveRaiseCharExpectedButAtomFound(')');
      ReadNextAtom;
    until false;
  end;
  // close ctnClassInheritance
  if CreateChildNodes then begin
    CurNode.EndPos:=CurPos.EndPos;
    EndChildNode;
  end;
end;

procedure TPascalParserTool.ReadSpecialize(CreateChildNodes: boolean);
// specialize template
// after parsing the cursor is on the atom behind the >
// examples:
//   type TListOfInteger = specialize TGenericList<integer,string>;
//   type TListOfChar = specialize Classes.TGenericList<integer,objpas.integer>;
//   type l = class(specialize TFPGObjectList<TControl>)
begin
  if CreateChildNodes then begin
    CreateChildNode;
    CurNode.Desc:=ctnSpecialize;
  end;
  // read identifier (the name of the generic)
  ReadNextAtom;
  AtomIsIdentifierSaveE;
  if CreateChildNodes then begin
    CreateChildNode;
    CurNode.Desc:=ctnSpecializeType;
    CurNode.EndPos:=CurPos.EndPos;
  end;
  ReadNextAtom;
  if Curpos.Flag=cafPoint then begin
    // first identifier was unitname, now read the type
    ReadNextAtom;
    AtomIsIdentifierSaveE;
    if CreateChildNodes then
      CurNode.EndPos:=CurPos.EndPos;
    ReadNextAtom;
  end;
  if CreateChildNodes then begin
    EndChildNode; // end ctnSpecializeType
  end;
  // read type list
  if not AtomIsChar('<') then
    SaveRaiseCharExpectedButAtomFound('<');
  if CreateChildNodes then begin
    CreateChildNode;
    CurNode.Desc:=ctnSpecializeParams;
  end;
  // read list of types
  repeat
    // read identifier (a parameter of the generic type)
    ReadNextAtom;
    AtomIsIdentifierSaveE;
    ReadNextAtom;
    if Curpos.Flag=cafPoint then begin
      // first identifier was unitname, now read the type
      ReadNextAtom;
      AtomIsIdentifierSaveE;
      ReadNextAtom;
    end;
    if AtomIsChar('>') then
      break
    else if CurPos.Flag=cafComma then begin
      // read next parameter
    end else
      SaveRaiseCharExpectedButAtomFound('>');
  until false;
  if CreateChildNodes then begin
    // close list
    CurNode.EndPos:=CurPos.EndPos;
    EndChildNode; // end ctnSpecializeParams
    // close specialize
    CurNode.EndPos:=CurPos.EndPos;
    EndChildNode; // end ctnSpecialize
  end;
  ReadNextAtom;
end;

function TPascalParserTool.WordIsPropertyEnd: boolean;
var
  p: PChar;
begin
  p:=@Src[CurPos.StartPos];
  case UpChars[p^] of
  'C': if UpAtomIs('CLASS') then exit(true);
  'F': if UpAtomIs('FUNCTION') then exit(true);
  'S': if UpAtomIs('STRICT') then exit(true);
  'P':
    case UpChars[p[1]] of
    'R':
      case UpChars[p[2]] of
      'I': if UpAtomIs('PRIVATE') then exit(true);
      'O': if UpAtomIs('PROTECTED') or UpAtomIs('PROCEDURE') then exit(true);
      end;
    'U': if UpAtomIs('PUBLIC') or UpAtomIs('PUBLISHED') then exit(true);
    end;
  'T': if UpAtomIs('TYPE') then exit(true);
  'V': if UpAtomIs('VAR') then exit(true);
  end;
  Result:=false;
end;

procedure TPascalParserTool.ValidateToolDependencies;
begin

end;

procedure TPascalParserTool.BuildSubTreeForProcHead(ProcNode: TCodeTreeNode);
var HasForwardModifier, IsFunction, IsOperator, IsMethod: boolean;
  ParseAttr: TParseProcHeadAttributes;
  IsProcType: Boolean;
  ProcHeadNode: TCodeTreeNode;
begin
  if ProcNode.Desc=ctnProcedureHead then ProcNode:=ProcNode.Parent;
  if ProcNode.Desc=ctnMethodMap then begin
    exit;
  end;
  if (not (ProcNode.Desc in [ctnProcedure,ctnProcedureType])) then begin
    {$IFDEF CheckNodeTool}
    CTDumpStack;
    {$ENDIF}
    if ProcNode<>nil then begin
      DebugLn(['TPascalParserTool.BuildSubTreeForProcHead Desc=',ProcNode.DescAsString]);
      if ProcNode.FirstChild<>nil then
        DebugLn(['TPascalParserTool.BuildSubTreeForProcHead FirstChild=',ProcNode.FirstChild.DescAsString]);
    end;
    RaiseException('[TPascalParserTool.BuildSubTreeForProcHead] '
      +'internal error: invalid ProcNode');
  end;
  ProcHeadNode:=ProcNode.FirstChild;
  if (ProcHeadNode<>nil)
  and ((ProcHeadNode.SubDesc and ctnsNeedJITParsing)=0) then begin
    // proc head already parsed
    if (ProcHeadNode<>nil) and ((ctnsHasParseError and ProcHeadNode.SubDesc)>0)
    then
      RaiseNodeParserError(ProcHeadNode);
    exit;
  end;
  try
    IsMethod:=ProcNode.Parent.Desc in (AllClasses+AllClassSections);
    MoveCursorToNodeStart(ProcNode);
    ReadNextAtom;
    if UpAtomIs('CLASS') then
      ReadNextAtom;
    IsFunction:=UpAtomIs('FUNCTION');
    IsOperator:=(not IsFunction) and UpAtomIs('OPERATOR');
    IsProcType:=ProcNode.Desc=ctnProcedureType;
    // read procedure head (= [name[<parameters>]] + parameterlist + resulttype;)
    ReadNextAtom;// read first atom of head
    CurNode:=ProcHeadNode;
    if CurNode=nil then
      if ProcNode.Desc=ctnProcedureType then
        SaveRaiseCharExpectedButAtomFound(';')
      else
        SaveRaiseStringExpectedButAtomFound('identifier');
    ProcHeadNode.SubDesc:=ProcHeadNode.SubDesc and (not ctnsNeedJITParsing);

    if not IsProcType then begin
      // read procedure name of a class method (the name after the . )
      repeat
        if IsOperator then
          AtomIsCustomOperator(true,true,true)
        else
          AtomIsIdentifierSaveE;
        ReadNextAtom;
        if AtomIsChar('<') then
          ReadGenericParam;
        if CurPos.Flag<>cafPoint then break;
        ReadNextAtom;
      until false;
    end;
    // read rest of procedure head and build nodes
    HasForwardModifier:=false;
    ParseAttr:=[pphCreateNodes];
    if IsMethod then Include(ParseAttr,pphIsMethod);
    if IsFunction then Include(ParseAttr,pphIsFunction);
    if IsOperator then Include(ParseAttr,pphIsOperator);
    if IsProcType then Include(ParseAttr,pphIsType);
    ReadTilProcedureHeadEnd(ParseAttr,HasForwardModifier);
  except
    {$IFDEF ShowIgnoreErrorAfter}
    DebugLn('TPascalParserTool.BuildSubTreeForProcHead ',MainFilename,' ERROR: ',LastErrorMessage);
    {$ENDIF}
    if (not IgnoreErrorAfterValid)
    or (not IgnoreErrorAfterPositionIsInFrontOfLastErrMessage) then
      raise;
    {$IFDEF ShowIgnoreErrorAfter}
    DebugLn('TPascalParserTool.BuildSubTreeForProcHead ',MainFilename,' IGNORING ERROR: ',LastErrorMessage);
    {$ENDIF}
  end;
end;

procedure TPascalParserTool.BuildSubTreeForProcHead(ProcNode: TCodeTreeNode;
  out FunctionResult: TCodeTreeNode);
begin
  if ProcNode.Desc=ctnProcedureHead then
    ProcNode:=ProcNode.Parent;
  if ProcNode.Desc<>ctnProcedure then
    RaiseException('INTERNAL ERROR: TPascalParserTool.BuildSubTreeForProcHead with FunctionResult');
  BuildSubTreeForProcHead(ProcNode);
  FunctionResult:=ProcNode.FirstChild.FirstChild;
  if (FunctionResult<>nil) and (FunctionResult.Desc=ctnParameterList) then
    FunctionResult:=FunctionResult.NextBrother;
end;

procedure TPascalParserTool.BuildSubTree(CleanCursorPos: integer);
begin
  BuildSubTree(FindDeepestNodeAtPos(CleanCursorPos,false));
end;

procedure TPascalParserTool.BuildSubTree(ANode: TCodeTreeNode);
begin
  if ANode=nil then exit;
  case ANode.Desc of
  ctnProcedure,ctnProcedureHead:
    BuildSubTreeForProcHead(ANode);
  ctnBeginBlock:
    BuildSubTreeForBeginBlock(ANode);
  end;
end;

function TPascalParserTool.NodeNeedsBuildSubTree(ANode: TCodeTreeNode
  ): boolean;
begin
  Result:=false;
  if ANode=nil then exit;
  if ANode.Desc in (AllClasses+[ctnProcedureHead,ctnBeginBlock]) then begin
    Result:=(ANode.SubDesc and ctnsNeedJITParsing)>0;
  end;
end;

function TPascalParserTool.BuildSubTreeAndFindDeepestNodeAtPos(P: integer;
  ExceptionOnNotFound: boolean): TCodeTreeNode;
begin
  Result:=BuildSubTreeAndFindDeepestNodeAtPos(Tree.Root,P,ExceptionOnNotFound);
end;

function TPascalParserTool.BuildSubTreeAndFindDeepestNodeAtPos(
  StartNode: TCodeTreeNode; P: integer; ExceptionOnNotFound: boolean
  ): TCodeTreeNode;
var
  Node: TCodeTreeNode;
begin
  Result:=FindDeepestNodeAtPos(StartNode,P,ExceptionOnNotFound);
  //debugln('TPascalParserTool.BuildSubTreeAndFindDeepestNodeAtPos A ',Result.DescAsString,' ',dbgs(NodeNeedsBuildSubTree(Result)));
  while NodeNeedsBuildSubTree(Result) do begin
    BuildSubTree(Result);
    Node:=FindDeepestNodeAtPos(Result,P,ExceptionOnNotFound);
    if Node=Result then break;
    Result:=Node;
    //debugln('TPascalParserTool.BuildSubTreeAndFindDeepestNodeAtPos B ',Result.DescAsString,' ',dbgs(NodeNeedsBuildSubTree(Result)));
  end;
  // re-raise parse errors
  if (Result<>nil) and ((ctnsHasParseError and Result.SubDesc)>0) then
    RaiseNodeParserError(Result);
end;

function TPascalParserTool.FindInterfaceNode: TCodeTreeNode;
begin
  Result:=FindRootNode(ctnInterface);
end;

function TPascalParserTool.FindImplementationNode: TCodeTreeNode;
begin
  Result:=FindRootNode(ctnImplementation);
end;

function TPascalParserTool.FindInitializationNode: TCodeTreeNode;
begin
  Result:=FindRootNode(ctnInitialization);
end;

function TPascalParserTool.FindFinalizationNode: TCodeTreeNode;
begin
  Result:=FindRootNode(ctnFinalization);
end;

function TPascalParserTool.FindMainBeginEndNode: TCodeTreeNode;
begin
  Result:=Tree.Root;
  if (Result=nil) then exit;
  if (Result.Desc in [ctnProgram,ctnLibrary]) then
    Result:=Result.LastChild
  else begin
    Result:=FindImplementationNode;
    if Result<>nil then
      Result:=Result.LastChild;
  end;
  if Result=nil then exit;
  if Result.Desc<>ctnBeginBlock then Result:=nil;
end;

function TPascalParserTool.FindFirstSectionChild: TCodeTreeNode;
begin
  Result:=Tree.Root;
  while (Result<>nil) and (Result.FirstChild=nil) do
    Result:=Result.NextBrother;
  if (Result=nil) then exit;
  Result:=Result.FirstChild;
end;

function TPascalParserTool.FindSectionNodeAtPos(P: integer): TCodeTreeNode;
begin
  Result:=Tree.Root;
  if Result=nil then exit;
  if Result.StartPos>P then exit(nil);
  while (Result.NextBrother<>nil) and (Result.NextBrother.StartPos<=P) do
    Result:=Result.NextBrother;
end;

function TPascalParserTool.FindScanRangeNode(Range: TLinkScannerRange
  ): TCodeTreeNode;
{ search a node of the Range or higher
  lsrNone and lsrInit are always nil
  lsrSourceType is the unit/program/library node if exists
  Otherwise it is the next node (e.g. in a unit the interface)
}
begin
  Result:=nil;
  // lsrNone, lsrInit
  if (ord(Range)<=ord(lsrInit)) then exit;
  Result:=Tree.Root;
  if Result=nil then exit;
  // lsrSourceType;
  if Range=lsrSourceType then exit;
  // lsrSourceName;
  if Range=lsrSourceName then begin
    // the source name has no node of its own
    exit;
  end;
  if ord(Range)<ord(lsrEnd) then begin
    if Result.Desc=ctnUnit then begin
      Result:=Result.NextBrother;
      if Result=nil then exit;
      if Result.Desc<>ctnInterface then
        RaiseCatchableException('');
      // lsrInterfaceStart in unit
      if Range=lsrInterfaceStart then exit;
      if ord(Range)<ord(lsrImplementationStart) then begin
        if Result.FirstChild=nil then begin
          Result:=Result.NextSkipChilds;
          exit;
        end;
        Result:=Result.FirstChild;
        // lsrMainUsesSectionStart in unit
        if Range=lsrMainUsesSectionStart then exit;
        if Result.Desc=ctnUsesSection then begin
          Result:=Result.NextSkipChilds;
          if Result=nil then exit;
        end;
        // lsrMainUsesSectionEnd in unit
        exit;
      end else if ord(Range)<ord(lsrEnd) then begin
        // search for implementation, initialization or finalization
        // skip interface
        if Result.NextBrother=nil then begin
          Result:=Result.NextSkipChilds;
          exit;
        end;
        Result:=Result.NextBrother;
        if ord(Range)<ord(lsrInitializationStart) then begin
          if Result.Desc<>ctnImplementation then exit;
          // lsrImplementationStart in unit
          if Range=lsrImplementationStart then exit;
          if Result.FirstChild=nil then begin
            Result:=Result.NextSkipChilds;
            exit;
          end;
          Result:=Result.FirstChild;
          // lsrImplementationUsesSectionStart
          if Range=lsrImplementationUsesSectionStart then exit;
          if Result.Desc=ctnUsesSection then begin
            Result:=Result.NextSkipChilds;
            if Result=nil then exit;
          end;
          // lsrImplementationUsesSectionEnd
          exit;
        end;
        // initialization or finalization
        // skip implementation
        if Result.Desc=ctnImplementation then begin
          if Result.NextBrother=nil then begin
            Result:=Result.NextSkipChilds;
            exit;
          end;
          Result:=Result.NextBrother;
        end;
        // lsrInitializationStart in unit;
        if Range=lsrInitializationStart then exit;
        // lsrFinalizationStart
        if (Result.Desc=ctnInitialization) or (Result.Desc=ctnBeginBlock) then begin
          if Result.NextBrother=nil then begin
            Result:=Result.NextSkipChilds;
            exit;
          end;
          Result:=Result.NextBrother;
        end;
        exit;
      end;

    end else begin
      // not unit, but program, library or package
      if Range=lsrInterfaceStart then begin
        Result:=Result.Next;
        exit;
      end;
      if ord(Range)<ord(lsrImplementationStart) then begin
        // lsrMainUsesSectionStart or lsrMainUsesSectionEnd
        if Result.FirstChild=nil then begin
          Result:=Result.Next;
          exit;
        end;
        Result:=Result.FirstChild;
        if Result.Desc<>ctnUsesSection then exit;
        // lsrMainUsesSectionStart in program
        if Range=lsrMainUsesSectionStart then exit;
        // lsrMainUsesSectionEnd;
        Result:=Result.NextSkipChilds;
        exit;
      end else if ord(Range)<ord(lsrInitializationStart) then begin
        // lsrImplementationStart, lsrImplementationUsesSectionStart,
        // lsrImplementationUsesSectionEnd
        // skip uses section
        if Result.FirstChild=nil then begin
          Result:=Result.Next;
          exit;
        end;
        Result:=Result.FirstChild;
        if Result.Desc=ctnUsesSection then
          Result:=Result.NextSkipChilds;
        exit;
      end else if Range=lsrInitializationStart then begin
        // lsrInitializationStart in program
        if (Result.LastChild<>nil)
        and (Result.LastChild.Desc in [ctnBeginBlock,ctnAsmBlock]) then
          Result:=Result.LastChild
        else
          Result:=Result.NextSkipChilds;
      end else
        // lsrFinalizationStart in program
        Result:=Result.NextSkipChilds;
    end;
  end else begin
    // lsrEnd
    while (Result<>nil) and (Result.Desc<>ctnEndPoint) do
      Result:=Result.NextBrother;
  end;
end;

function TPascalParserTool.FindScanRangeNodeAtPos(P: integer): TCodeTreeNode;
var
  UsesNode: TCodeTreeNode;
begin
  Result:=FindSectionNodeAtPos(P);
  if Result=nil then exit;
  if (Result.FirstChild<>nil) and (Result.FirstChild.Desc=ctnUsesSection) then
  begin
    UsesNode:=Result.FirstChild;
    if (UsesNode.StartPos<=P) and (UsesNode.EndPos>P) then
      Result:=UsesNode;
  end;
end;

end.


