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
    TStandardCodeTool enhances TIdentCompletionTool with many standard code
    editing functions for the following categories:
      - source name
      - uses sections
      - lazarus resources
      - Application.CreateForm statements
      - published variables
      - resource strings
      - compiler and IDE directives
      - code exploring
      - code blocks
}
unit StdCodeTools;

{$ifdef FPC}{$mode objfpc}{$endif}{$H+}

interface

{$I codetools.inc}

{ $DEFINE DisableIgnoreErrorAfter}
{ $DEFINE VerboseGetStringConstBounds}

uses
  {$IFDEF MEM_CHECK}
  MemCheck,
  {$ENDIF}
  Classes, SysUtils, TypInfo, CodeToolsStrConsts, FileProcs, CodeTree, CodeAtom,
  FindDeclarationTool, IdentCompletionTool, PascalReaderTool, PascalParserTool,
  ExprEval, KeywordFuncLists, BasicCodeTools, LinkScanner, CodeCache,
  AVL_Tree, LFMTrees, SourceChanger,
  CustomCodeTool, CodeToolsStructs;

type
  TOnFindDefinePropertyForContext = procedure(Sender: TObject;
    const ClassContext, AncestorClassContext: TFindContext;
    LFMNode: TLFMTreeNode;
    const IdentName: string; var IsDefined: boolean) of object;


  { TStandardCodeTool }

  TStandardCodeTool = class(TIdentCompletionTool)
  private
    function ReadTilGuessedUnclosedBlock(MinCleanPos: integer;
      ReadOnlyOneBlock: boolean): boolean;
    function ReadForwardTilAnyBracketClose: boolean;
    function ReadBackwardTilAnyBracketClose: boolean;
  public
    // explore the code
    function Explore(WithStatements: boolean;
      OnlyInterface: boolean = false): boolean;
  
    // source name  e.g. 'unit UnitName;'
    function GetCachedSourceName: string;
    function RenameSource(const NewName: string;
          SourceChangeCache: TSourceChangeCache): boolean;
        
    // uses sections
    function FindUnitInUsesSection(UsesNode: TCodeTreeNode;
          const UpperUnitName: string;
          out NamePos, InPos: TAtomPosition): boolean;
    function FindUnitInAllUsesSections(const UpperUnitName: string;
          out NamePos, InPos: TAtomPosition): boolean;
    function RenameUsedUnit(const OldUpperUnitName, NewUnitName,
          NewUnitInFile: string;
          SourceChangeCache: TSourceChangeCache): boolean;
    function ReplaceUsedUnits(UnitNamePairs: TStringToStringTree;
          SourceChangeCache: TSourceChangeCache): boolean;
    function AddUnitToUsesSection(UsesNode: TCodeTreeNode;
          const NewUnitName, NewUnitInFile: string;
          SourceChangeCache: TSourceChangeCache): boolean;
    function AddUnitToMainUsesSection(const NewUnitName, NewUnitInFile: string;
          SourceChangeCache: TSourceChangeCache): boolean;
    function RemoveUnitFromUsesSection(UsesNode: TCodeTreeNode;
                                const UpperUnitName: string;
                                SourceChangeCache: TSourceChangeCache): boolean;
    function RemoveUnitFromAllUsesSections(const UpperUnitName: string;
                                SourceChangeCache: TSourceChangeCache): boolean;
    function FixUsedUnitCase(SourceChangeCache: TSourceChangeCache): boolean;
    function FixUsedUnitCaseInUsesSection(UsesNode: TCodeTreeNode;
                                SourceChangeCache: TSourceChangeCache): boolean;
    function FindUsedUnitNames(var MainUsesSection,
                               ImplementationUsesSection: TStrings): boolean;
    function FindUsedUnitNames(var List: TStringToStringTree): boolean;
    function FindUsedUnitFiles(var MainUsesSection: TStrings): boolean;
    function FindUsedUnitFiles(var MainUsesSection,
                               ImplementationUsesSection: TStrings): boolean;
    function FindDelphiProjectUnits(var FoundInUnits, MissingInUnits,
                                    NormalUnits: TStrings;
                                    UseContainsSection: boolean = false): boolean;
    function UsesSectionToFilenames(UsesNode: TCodeTreeNode): TStrings;
    function UsesSectionToUnitnames(UsesNode: TCodeTreeNode): TStrings;
    function FindMissingUnits(var MissingUnits: TStrings; FixCase: boolean;
                              SearchImplementation: boolean;
                              SourceChangeCache: TSourceChangeCache): boolean;
    function CommentUnitsInUsesSections(MissingUnits: TStrings;
                                SourceChangeCache: TSourceChangeCache): boolean;

    // lazarus resources
    function FindNextIncludeInInitialization(
          var LinkIndex: integer): TCodeBuffer;
    function FindLazarusResourceInBuffer(ResourceCode: TCodeBuffer;
          const ResourceName: string): TAtomPosition;
    function FindLazarusResource(const ResourceName: string): TAtomPosition;
    function AddLazarusResource(ResourceCode: TCodeBuffer;
          const ResourceName, ResourceData: string;
          SourceChangeCache: TSourceChangeCache): boolean;
    function RemoveLazarusResource(ResourceCode: TCodeBuffer;
          const ResourceName: string;
          SourceChangeCache: TSourceChangeCache): boolean;
    function RenameInclude(LinkIndex: integer; const NewFilename: string;
          KeepPath: boolean;
          SourceChangeCache: TSourceChangeCache): boolean;
    function CheckLFM(LFMBuf: TCodeBuffer; out LFMTree: TLFMTree;
                  const OnFindDefineProperty: TOnFindDefinePropertyForContext;
                  RootMustBeClassInIntf, ObjectsMustExists: boolean): boolean;

    // Application.Createform statements
    function FindCreateFormStatement(StartPos: integer;
          const UpperClassName, UpperVarName: string;
          out Position: TAtomPosition): integer; // 0=found, -1=not found, 1=found, but wrong classname
    function AddCreateFormStatement(const AClassName, AVarName: string;
          SourceChangeCache: TSourceChangeCache): boolean;
    function RemoveCreateFormStatement(const UpperVarName: string;
          SourceChangeCache: TSourceChangeCache): boolean;
    function ChangeCreateFormStatement(StartPos: integer;
          const OldClassName, OldVarName: string;
          const NewClassName, NewVarName: string;
          OnlyIfExists: boolean;
          SourceChangeCache: TSourceChangeCache): boolean;
    function ListAllCreateFormStatements: TStrings;
    function SetAllCreateFromStatements(List: TStrings;
          SourceChangeCache: TSourceChangeCache): boolean;    
          
    // Application.Title:=<string const> statements
    function FindApplicationTitleStatement(out StartPos, StringConstStartPos,
          EndPos: integer): boolean;
    function GetApplicationTitleStatement(StringConstStartPos, EndPos: integer;
          var Title: string): boolean;
    function SetApplicationTitleStatement(const NewTitle: string;
          SourceChangeCache: TSourceChangeCache): boolean;
    function RemoveApplicationTitleStatement(
          SourceChangeCache: TSourceChangeCache): boolean;

    // forms
    function RenameForm(const OldFormName, OldFormClassName: string;
          const NewFormName, NewFormClassName: string;
          SourceChangeCache: TSourceChangeCache): boolean;
    function FindFormAncestor(const UpperClassName: string;
          var AncestorClassName: string): boolean;

    // published variables
    function FindPublishedVariable(const UpperClassName, UpperVarName: string;
          ExceptionOnClassNotFound: boolean): TCodeTreeNode;
    function AddPublishedVariable(const UpperClassName,VarName, VarType: string;
          SourceChangeCache: TSourceChangeCache): boolean; virtual;
    function RemovePublishedVariable(const UpperClassName, UpperVarName: string;
          ExceptionOnClassNotFound: boolean;
          SourceChangeCache: TSourceChangeCache): boolean;
    function RenamePublishedVariable(const UpperClassName,
          UpperOldVarName: string; const NewVarName, VarType: shortstring;
          ExceptionOnClassNotFound: boolean;
          SourceChangeCache: TSourceChangeCache): boolean;
    function GatherPublishedClassElements(const TheClassName: string;
          ExceptionOnClassNotFound, WithVariables, WithMethods,
          WithProperties, WithAncestors: boolean;
          out TreeOfCodeTreeNodeExtension: TAVLTree): boolean;
    function FindDanglingComponentEvents(const TheClassName: string;
          RootComponent: TComponent; ExceptionOnClassNotFound,
          SearchInAncestors: boolean;
          out ListOfPInstancePropInfo: TFPList): boolean;

    // blocks (e.g. begin..end)
    function FindBlockCounterPart(const CursorPos: TCodeXYPosition;
          out NewPos: TCodeXYPosition; out NewTopLine: integer): boolean;
    function FindBlockStart(const CursorPos: TCodeXYPosition;
          out NewPos: TCodeXYPosition; var NewTopLine: integer): boolean;
    function GuessUnclosedBlock(const CursorPos: TCodeXYPosition;
          out NewPos: TCodeXYPosition; out NewTopLine: integer): boolean;
    function FindBlockCleanBounds(const CursorPos: TCodeXYPosition;
          out BlockCleanStart, BlockCleanEnd: integer): boolean;
      
    // compiler directives
    function GuessMisplacedIfdefEndif(const CursorPos: TCodeXYPosition;
          out NewPos: TCodeXYPosition; out NewTopLine: integer): boolean;
    function FindEnclosingIncludeDirective(const CursorPos: TCodeXYPosition;
          out NewPos: TCodeXYPosition; var NewTopLine: integer): boolean;
    function FindModeDirective(DoBuildTree: boolean;
          out ACleanPos: integer): boolean;
    function FindResourceDirective(DoBuildTree: boolean;
          var ACleanPos: integer; const Filename: string = ''): boolean;
    function FindResourceDirective(const CursorPos: TCodeXYPosition;
          out NewPos: TCodeXYPosition; out NewTopLine: integer;
          const Filename: string = ''): boolean;
    function AddResourceDirective(const Filename: string;
          SourceChangeCache: TSourceChangeCache; const NewSrc: string = ''
          ): boolean;
    function FixIncludeFilenames(Code: TCodeBuffer;
          SourceChangeCache: TSourceChangeCache;
          out FoundIncludeFiles: TStrings;
          var MissingIncludeFilesCodeXYPos: TFPList): boolean;

    // search & replace
    function ReplaceWords(IdentList: TStrings; ChangeStrings: boolean;
          SourceChangeCache: TSourceChangeCache): boolean;
    function FindNearestIdentifierNode(const CursorPos: TCodeXYPosition;
          IdentTree: TAVLTree): TAVLTreeNode;
    function ReplaceWord(const OldWord, NewWord: string; ChangeStrings: boolean;
          SourceChangeCache: TSourceChangeCache): boolean;

    // expressions
    function GetStringConstBounds(const CursorPos: TCodeXYPosition;
          out StartPos, EndPos: TCodeXYPosition;
          ResolveComments: boolean): boolean;
    function ReplaceCode(const StartPos, EndPos: TCodeXYPosition;
          const NewCode: string;
          SourceChangeCache: TSourceChangeCache): boolean;
    function GetStringConstAsFormatString(StartPos, EndPos: integer;
          out FormatStringConstant, FormatParameters: string;
          out StartInStringConst, EndInStringConst: boolean): boolean;
    function GetStringConstAsFormatString(StartPos, EndPos: integer;
          out FormatStringConstant, FormatParameters: string): boolean;

    // resource strings
    function GatherResourceStringSections(const CursorPos: TCodeXYPosition;
          PositionList: TCodeXYPositions): boolean;
    function IdentifierExistsInResourceStringSection(
          const CursorPos: TCodeXYPosition;
          const ResStrIdentifier: string): boolean;
    function GatherResourceStringsWithValue(const CursorPos: TCodeXYPosition;
          const StringValue: string;
          PositionList: TCodeXYPositions): boolean;
    function GatherResourceStringIdents(const SectionPos: TCodeXYPosition;
          var IdentTree: TAVLTree): boolean;
    function FindNearestResourceString(const CursorPos,
          SectionPos: TCodeXYPosition;
          var NearestPos: TCodeXYPosition): boolean;
    function AddResourceString(const SectionPos: TCodeXYPosition;
          const NewIdentifier, NewValue: string;
          InsertPolicy: TResourcestringInsertPolicy;
          const NearestPos: TCodeXYPosition;
          SourceChangeCache: TSourceChangeCache): boolean;
    function CreateIdentifierFromStringConst(
          const StartCursorPos, EndCursorPos: TCodeXYPosition;
          out Identifier: string; MaxLen: integer): boolean;
    function StringConstToFormatString(
          const StartCursorPos, EndCursorPos: TCodeXYPosition;
          out FormatStringConstant,FormatParameters: string;
          out StartInStringConst, EndInStringConst: boolean): boolean;
          
    // register procedure
    function HasInterfaceRegisterProc(var HasRegisterProc: boolean): boolean;
    
    // Delphi to Lazarus conversion
    function ConvertDelphiToLazarusSource(AddLRSCode: boolean;
          SourceChangeCache: TSourceChangeCache): boolean;
    
    // IDE % directives
    function GetIDEDirectives(DirectiveList: TStrings): boolean;
    function SetIDEDirectives(DirectiveList: TStrings;
          SourceChangeCache: TSourceChangeCache): boolean;
          
    // comments
    function FindCommentInFront(const StartPos: TCodeXYPosition;
          const CommentText: string; InvokeBuildTree, SearchInParentNode,
          WithCommentBounds, CaseSensitive, IgnoreSpaces,
          CompareOnlyStart: boolean;
          out CommentStart, CommentEnd: TCodeXYPosition): boolean;
    function CommentCode(const StartPos, EndPos: integer;
          SourceChangeCache: TSourceChangeCache; Apply: boolean): boolean;
    function GetPasDocComments(const StartPos: TCodeXYPosition;
                               InvokeBuildTree: boolean;
                               out ListOfPCodeXYPosition: TFPList): boolean;
  end;


implementation


type
  TBlockKeyword = (bkwNone, bkwBegin, bkwAsm, bkwTry, bkwCase, bkwRepeat,
                   bkwRecord, bkwClass, bkwObject, bkwInterface,
                   bkwDispInterface, bkwEnd, bkwUntil, bkwFinally,
                   bkwExcept);

const
  BlockKeywords: array[TBlockKeyword] of string = (
      '(unknown)', 'BEGIN', 'ASM', 'TRY', 'CASE', 'REPEAT', 'RECORD', 'CLASS',
      'OBJECT', 'INTERFACE', 'DISPINTERFACE', 'END', 'UNTIL', 'FINALLY',
      'EXCEPT'
    );

var
  BlockKeywordFuncList: TKeyWordFunctionList;
  
procedure BuildBlockKeyWordFuncList;
var BlockWord: TBlockKeyword;
begin
  if BlockKeywordFuncList=nil then begin
    BlockKeywordFuncList:=TKeyWordFunctionList.Create;
    for BlockWord:=Low(TBlockKeyword) to High(TBlockKeyword) do
      with BlockKeywordFuncList do
        Add(BlockKeywords[BlockWord],{$ifdef FPC}@{$endif}AllwaysTrue);
  end;
end;


{ TStandardCodeTool }

{-------------------------------------------------------------------------------
  function TStandardCodeTool.GetCachedSourceName: string;
  Params: none
  Result: the source name (= e.g. the identifier behind 'program'/'unit' keyword)

  This function does neither check if source needs reparsing, nor does it check
  for errors in code. It simple checks if there is a first node, which is
  typically the source type and name.
  This function can therefore be used as a fast GetSourceName function.
-------------------------------------------------------------------------------}
function TStandardCodeTool.GetCachedSourceName: string;
begin
  if Tree.Root<>nil then begin
    MoveCursorToNodeStart(Tree.Root);
    ReadNextAtom; // read source type 'program', 'unit' ...
    ReadNextAtom; // read name
    if (CurPos.StartPos<=SrcLen) then
      CachedSourceName:=GetAtom;
  end;
  Result:=CachedSourceName;
end;

function TStandardCodeTool.RenameSource(const NewName: string;
  SourceChangeCache: TSourceChangeCache): boolean;
var NamePos: TAtomPosition;
begin
  Result:=false;
  BuildTree(true);
  if (not GetSourceNamePos(NamePos)) or (NamePos.StartPos<1) or (NewName='')
  or (Length(NewName)>255) then exit;
  SourceChangeCache.MainScanner:=Scanner;
  SourceChangeCache.Replace(gtNone,gtNone,NamePos.StartPos,NamePos.EndPos,
    NewName);
  if not SourceChangeCache.Apply then exit;
  CachedSourceName:=NewName;
  Result:=true;
end;

function TStandardCodeTool.FindUnitInUsesSection(UsesNode: TCodeTreeNode;
  const UpperUnitName: string;
  out NamePos, InPos: TAtomPosition): boolean;
begin
  Result:=false;
  NamePos:=CleanAtomPosition;
  InPos:=CleanAtomPosition;
  if (UsesNode=nil) or (UpperUnitName='') or (length(UpperUnitName)>255)
  or (UsesNode.Desc<>ctnUsesSection) then exit;
  MoveCursorToNodeStart(UsesNode);
  ReadNextAtom; // read 'uses'
  repeat
    ReadNextAtom; // read name
    if AtomIsChar(';') then break;
    if UpAtomIs(UpperUnitName) then begin
      NamePos:=CurPos;
      InPos.StartPos:=-1;
      ReadNextAtom;
      if UpAtomIs('IN') then begin
        ReadNextAtom;
        InPos:=CurPos;
      end;
      Result:=true;
      exit;
    end;
    ReadNextAtom;
    if UpAtomIs('IN') then begin
      ReadNextAtom;
      ReadNextAtom;
    end;
    if AtomIsChar(';') then break;
    if not AtomIsChar(',') then break;
  until (CurPos.StartPos>SrcLen);;
end;

function TStandardCodeTool.FindUnitInAllUsesSections(
  const UpperUnitName: string; out NamePos, InPos: TAtomPosition): boolean;
var SectionNode, UsesNode: TCodeTreeNode;
begin
  Result:=false;
  NamePos.StartPos:=-1;
  InPos.StartPos:=-1;
  if (UpperUnitName='') or (length(UpperUnitName)>255) then exit;
  BuildTree(false);
  SectionNode:=Tree.Root;
  while (SectionNode<>nil) and (SectionNode.Desc in [ctnProgram, ctnUnit,
    ctnPackage,ctnLibrary,ctnInterface,ctnImplementation])
  do begin
    UsesNode:=SectionNode.FirstChild;
    if (UsesNode<>nil) and (UsesNode.Desc=ctnUsesSection)
    and FindUnitInUsesSection(UsesNode,UpperUnitName,NamePos,InPos) then begin
      Result:=true;
      exit;
    end;
    SectionNode:=SectionNode.NextBrother;
  end;
end;

function TStandardCodeTool.RenameUsedUnit(const OldUpperUnitName,
  NewUnitName, NewUnitInFile: string;
  SourceChangeCache: TSourceChangeCache): boolean;
var UnitPos, InPos: TAtomPosition;
  NewUsesTerm: string;
begin
  Result:=false;
  if (OldUpperUnitName='') or (length(OldUpperUnitName)>255) or (NewUnitName='')
  or (length(NewUnitName)>255) then exit;
  if not FindUnitInAllUsesSections(OldUpperUnitName,UnitPos,InPos) then begin
    //debugln('TStandardCodeTool.RenameUsedUnit not found: ',OldUpperUnitName,' ');
    exit;
  end;
  SourceChangeCache.MainScanner:=Scanner;
  if InPos.StartPos>0 then
    UnitPos.EndPos:=InPos.EndPos;
  // build use unit term
  NewUsesTerm:=NewUnitName;
  if NewUnitInFile<>'' then
    NewUsesTerm:=NewUsesTerm+' in '''+NewUnitInFile+'''';
  // Note: do not use beautifier, unit names are case sensitive
  if ReplacementNeedsLineEnd(Src,UnitPos.StartPos,UnitPos.EndPos,
    length(NewUsesTerm),SourceChangeCache.BeautifyCodeOptions.LineLength) then
  begin
    if not SourceChangeCache.Replace(gtNewLine,gtNone,
      UnitPos.StartPos,UnitPos.EndPos,NewUsesTerm) then exit;
  end else begin
    if not SourceChangeCache.Replace(gtSpace,gtNone,
      UnitPos.StartPos,UnitPos.EndPos,NewUsesTerm) then exit;
  end;
  if not SourceChangeCache.Apply then exit;
  Result:=true;
end;

function TStandardCodeTool.ReplaceUsedUnits(UnitNamePairs: TStringToStringTree;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  ExistingUnits: TStringToStringTree;
  
  procedure CleanNewUnits(const AnUnitName: string; var NewText: string);
  var
    StartPos: Integer;
    EndPos: LongInt;
    CommaBehind: LongInt;
    CommaInFront: Integer;
    NewUnitName: String;
  begin
    // remove all units, that already exists
    StartPos:=1;
    CommaInFront:=-1;
    while StartPos<=length(NewText) do begin
      EndPos:=StartPos;
      while (EndPos<=length(NewText)) and (IsIdentChar[NewText[EndPos]]) do
        inc(EndPos);
      if EndPos<=StartPos then break;
      NewUnitName:=copy(NewText,StartPos,EndPos-StartPos);
      // set EndPos to start of next unit
      CommaBehind:=-1;
      while (EndPos<=length(NewText)) do begin
        if NewText[EndPos]='''' then begin
          inc(EndPos);
          while (EndPos<=length(NewText)) and (NewText[EndPos]<>'''') do
            inc(EndPos);
        end else if NewText[EndPos]=',' then begin
          CommaBehind:=EndPos;
          while (EndPos<=length(NewText))
          and (not IsIdentStartChar[NewText[EndPos]]) do
            inc(EndPos);
          break;
        end;
        inc(EndPos);
      end;
      if (SysUtils.CompareText(AnUnitName,NewUnitName)=0) then begin
        // this is the old unit or
        //DebugLn('Replace: keep old unit "',NewUnitName,'"');
      end else if ExistingUnits.Contains(NewUnitName) then begin
        // this unit already exists and should not be added
        //DebugLn('Replace: already exists: "',NewUnitName,'"="',ExistingUnits[NewUnitName],'" CommaInFront=',dbgs(CommaInFront),' CommaBehind=',dbgs(CommaBehind));
        if CommaBehind>0 then
          System.Delete(NewText,StartPos,EndPos-StartPos)
        else if CommaInFront>0 then
          System.Delete(NewText,CommaInFront,EndPos-CommaInFront)
        else
          System.Delete(NewText,StartPos,EndPos-StartPos);
        EndPos:=StartPos;
        CommaBehind:=-1;
      end else begin
        // this unit does not exist yet
        //DebugLn('Replace new unit with "',NewUnitName,'"');
      end;
      if CommaBehind>0 then
        CommaInFront:=CommaBehind;
      StartPos:=EndPos;
    end;
  end;

  function Replace(UsesNode: TCodeTreeNode): boolean;
  var
    UnitNameAtom: TAtomPosition;
    InAtom: TAtomPosition;
    NewText: string;
    CommaInFront: LongInt;
    FromPos: LongInt;
    ToPos: LongInt;
    CommaBehind: Integer;
    AnUnitName: String;
  begin
    if UsesNode=nil then exit(true);
    MoveCursorToUsesStart(UsesNode);
    CommaInFront:=-1;
    repeat
      // read next unit name
      ReadNextUsedUnit(UnitNameAtom, InAtom);
      if CurPos.Flag=cafComma then
        CommaBehind:=CurPos.StartPos
      else
        CommaBehind:=-1;
      AnUnitName:=GetAtom(UnitNameAtom);
      if UnitNamePairs.Contains(AnUnitName) then begin
        // replace
        NewText:=UnitNamePairs[AnUnitName];
        //DebugLn('Replace Unit="',AnUnitName,'" NewText="',NewText,'"');
        
        CleanNewUnits(AnUnitName,NewText);
        
        if NewText='' then begin
          // comment unit
          if CommaInFront>0 then begin
            // example:  uses a{, b};
            FromPos:=CommaInFront;
            ToPos:=UnitNameAtom.EndPos;
            if InAtom.StartPos>0 then
              ToPos:=InAtom.EndPos;
          end else if CommaBehind>0 then begin
            // example:  uses {a,} b;
            //           uses {a,} {b};
            FromPos:=UnitNameAtom.StartPos;
            ToPos:=CommaBehind+1;
          end else begin
            // examples:  uses {b};
            FromPos:=UnitNameAtom.StartPos;
            ToPos:=UnitNameAtom.EndPos;
            if InAtom.StartPos>0 then
              ToPos:=InAtom.EndPos;
          end;
          if not CommentCode(FromPos,ToPos,SourceChangeCache,false) then
            exit(false);
        end else begin
          // replace
          FromPos:=UnitNameAtom.StartPos;
          ToPos:=UnitNameAtom.EndPos;
          if InAtom.StartPos>0 then
            ToPos:=InAtom.EndPos;
          if not SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,NewText)
          then exit(false);
        end;
      end;

      if CurPos.Flag=cafComma then begin
        // read next unit name
        CommaInFront:=CurPos.StartPos;
        ReadNextAtom;
      end else if CurPos.Flag=cafSemicolon then begin
        break;
      end else
        RaiseExceptionFmt(ctsStrExpectedButAtomFound,[';',GetAtom]);
    until false;
    Result:=true;
  end;
  
begin
  Result:=false;
  BuildTree(false);
  SourceChangeCache.MainScanner:=Scanner;
  ExistingUnits:=nil;
  try
    // first collect all units
    if not FindUsedUnitNames(ExistingUnits) then exit;
    // then change uses sections
    Replace(FindMainUsesSection);
    Replace(FindImplementationUsesSection);
  finally
    ExistingUnits.Free;
  end;
  Result:=SourceChangeCache.Apply;
end;

function TStandardCodeTool.AddUnitToUsesSection(UsesNode: TCodeTreeNode;
  const NewUnitName, NewUnitInFile: string;
  SourceChangeCache: TSourceChangeCache): boolean;
var LineStart, LineEnd, Indent, InsertPos: integer;
  NewUsesTerm: string;
begin
  Result:=false;
  if (UsesNode=nil) or (UsesNode.Desc<>ctnUsesSection) or (NewUnitName='')
  or (length(NewUnitName)>255) or (UsesNode.StartPos<1)
  or (UsesNode.EndPos<1) then exit;
  SourceChangeCache.MainScanner:=Scanner;
  MoveCursorToNodeStart(UsesNode); // for nice error position
  InsertPos:=UsesNode.EndPos-1; // position of semicolon at end of uses section
  // build insert text  "unitname in 'file'"
  NewUsesTerm:=NewUnitName;
  if NewUnitInFile<>'' then
    NewUsesTerm:=NewUsesTerm+' in '''+NewUnitInFile+'''';
  // check if insertion would expand the line over the max LineLength
  GetLineStartEndAtPosition(Src,InsertPos,LineStart,LineEnd);
  if InsertPos-LineStart+length(NewUsesTerm)+2>=
    SourceChangeCache.BeautifyCodeOptions.LineLength then
  begin
    // split line
    // calculate the indent
    Indent:=GetLineIndent(Src,InsertPos);
    // if the 'uses' keyword is not in the same line of the insertion position,
    // then indent the new line
    // else keep the indentation.
    if (UsesNode.StartPos>=LineStart)
    and (UsesNode.StartPos<LineEnd) then
      inc(Indent,SourceChangeCache.BeautifyCodeOptions.Indent);
    NewUsesTerm:=','+SourceChangeCache.BeautifyCodeOptions.LineEnd+
      GetIndentStr(Indent)+NewUsesTerm;
  end else
    // simply insert
    NewUsesTerm:=', '+NewUsesTerm;
  if not SourceChangeCache.Replace(gtNone,gtNone,InsertPos,InsertPos,
                                   NewUsesTerm) then exit;
  if not SourceChangeCache.Apply then exit;
  Result:=true;
end;

function TStandardCodeTool.AddUnitToMainUsesSection(const NewUnitName,
  NewUnitInFile: string; SourceChangeCache: TSourceChangeCache): boolean;
var UsesNode, SectionNode: TCodeTreeNode;
  NewUsesTerm: string;
  InsertPos: integer;
  Junk     : TAtomPosition;
begin
  Result:=false;
  if (NewUnitName='') or (length(NewUnitName)>255) then exit;
  BuildTree(true);
  SourceChangeCache.MainScanner:=Scanner;
  UsesNode:=FindMainUsesSection;
  if UsesNode<>nil then begin
    // add unit to existing uses section
    if not (FindUnitInUsesSection(UsesNode,UpperCaseStr(NewUnitName),Junk,Junk))
    then
      if not AddUnitToUsesSection(UsesNode,NewUnitName,NewUnitInFile,
                                   SourceChangeCache) then exit;
  end else begin
    // create a new uses section
    if Tree.Root=nil then exit;
    SectionNode:=Tree.Root;
    MoveCursorToNodeStart(SectionNode);
    ReadNextAtom;
    if UpAtomIs('UNIT') then begin
      // search interface
      SectionNode:=SectionNode.NextBrother;
      if (SectionNode=nil) or (SectionNode.Desc<>ctnInterface) then exit;
      MoveCursorToNodeStart(SectionNode);
      ReadNextAtom;
    end;
    NewUsesTerm:=SourceChangeCache.BeautifyCodeOptions.BeautifyKeyWord('uses')
         +' '+NewUnitName;
    if NewUnitInFile<>'' then
      NewUsesTerm:=NewUsesTerm+' in '''+NewUnitInFile+''';'
    else
      NewUsesTerm:=NewUsesTerm+';';
    InsertPos:=CurPos.EndPos;
    if not SourceChangeCache.Replace(gtEmptyLine,gtEmptyLine,InsertPos,InsertPos,
      NewUsesTerm) then exit;
    if not SourceChangeCache.Apply then exit;
  end;
  Result:=true;
end;

function TStandardCodeTool.RemoveUnitFromUsesSection(UsesNode: TCodeTreeNode;
  const UpperUnitName: string; SourceChangeCache: TSourceChangeCache): boolean;
var UnitCount, StartPos, EndPos: integer;
begin
  Result:=false;
  if (UsesNode=nil) or (UpperUnitName='') or (length(UpperUnitName)>255) then
    exit;
  MoveCursorToNodeStart(UsesNode);
  ReadNextAtom; // read 'uses'
  UnitCount:=0;
  repeat
    EndPos:=CurPos.StartPos;
    ReadNextAtom; // read name
    if not AtomIsIdentifier(false) then exit;
    inc(UnitCount);
    if UpAtomIs(UpperUnitName) then begin
      // unit found
      SourceChangeCache.MainScanner:=Scanner;
      StartPos:=CurPos.StartPos;
      ReadNextAtom;
      if UpAtomIs('IN') then begin
        ReadNextAtom;
        ReadNextAtom;
      end;
      if UnitCount=1 then begin
        // first unit in uses section
        if AtomIsChar(';') then begin
          // last unit in uses section -> delete whole uses section
          if not SourceChangeCache.Replace(gtNone,gtNone,
            UsesNode.StartPos,UsesNode.EndPos,'') then exit;
        end else begin
          // not last unit -> delete with comma behind
          if not SourceChangeCache.Replace(gtNone,gtNone,
            StartPos,CurPos.EndPos,'') then exit;
        end;
      end else begin
        // not first unit in uses section -> delete with comma in front
        if not SourceChangeCache.Replace(gtNone,gtNone,
          EndPos,CurPos.StartPos,'') then exit;
      end;
      if not SourceChangeCache.Apply then exit;
      Result:=true;
      exit;
    end;
    ReadNextAtom;
    if UpAtomIs('IN') then begin
      ReadNextAtom;
      ReadNextAtom;
    end;
    if AtomIsChar(';') then break;
    if not AtomIsChar(',') then break;
  until (CurPos.StartPos>UsesNode.EndPos) or (CurPos.StartPos>SrcLen);
  Result:=true;
end;

function TStandardCodeTool.RemoveUnitFromAllUsesSections(
  const UpperUnitName: string; SourceChangeCache: TSourceChangeCache): boolean;
var SectionNode: TCodeTreeNode;
begin
  Result:=false;
  if (UpperUnitName='') or (SourceChangeCache=nil) then exit;
  BuildTree(false);
  SectionNode:=Tree.Root;
  while (SectionNode<>nil) do begin
    if (SectionNode.FirstChild<>nil)
    and (SectionNode.FirstChild.Desc=ctnUsesSection) then begin
      if not RemoveUnitFromUsesSection(SectionNode.FirstChild,UpperUnitName,
         SourceChangeCache)
      then begin
        exit;
      end;
    end;
    SectionNode:=SectionNode.NextBrother;
  end;
  Result:=true;
end;

function TStandardCodeTool.FixUsedUnitCase(
  SourceChangeCache: TSourceChangeCache): boolean;
var
  SectionNode: TCodeTreeNode;
begin
  debugln('TStandardCodeTool.FixUsedUnitCase ',MainFilename);
  Result:=false;
  BuildTree(false);
  SectionNode:=Tree.Root;
  while (SectionNode<>nil) do begin
    if (SectionNode.FirstChild<>nil)
    and (SectionNode.FirstChild.Desc=ctnUsesSection) then begin
      if not FixUsedUnitCaseInUsesSection(
        SectionNode.FirstChild,SourceChangeCache)
      then begin
        exit;
      end;
    end;
    SectionNode:=SectionNode.NextBrother;
  end;
  Result:=true;
end;

function TStandardCodeTool.FixUsedUnitCaseInUsesSection(
  UsesNode: TCodeTreeNode; SourceChangeCache: TSourceChangeCache): boolean;
  
  function FindUnit(const AFilename: string): string;
  var
    CurDir: String;
    MainCodeIsVirtual: Boolean;
    FileInfo: TSearchRec;
    CurFilename: String;
  begin
    if FilenameIsAbsolute(AFilename) then
      CurDir:=ExtractFilePath(AFilename)
    else begin
      MainCodeIsVirtual:=TCodeBuffer(Scanner.MainCode).IsVirtual;
      if not MainCodeIsVirtual then begin
        CurDir:=ExtractFilePath(TCodeBuffer(Scanner.MainCode).Filename);
      end else begin
        CurDir:='';
      end;
    end;
    CurFilename:=ExtractFilename(AFilename);
    Result:='';
    if FindFirstUTF8(AppendPathDelim(CurDir)+FileMask,
                          faAnyFile,FileInfo)=0 then
    begin
      repeat
        // check if special file
        if (FileInfo.Name='.') or (FileInfo.Name='..') or (FileInfo.Name='')
        then
          continue;
        if (SysUtils.CompareText(CurFilename,FileInfo.Name)=0)
        then begin
          if (Result='') or (FileInfo.Name=CurFilename) then
            Result:=FileInfo.Name;
        end;
      until FindNextUTF8(FileInfo)<>0;
    end;
    FindCloseUTF8(FileInfo);
  end;
  
var
  UnitInFilename: String;
  Changed: Boolean;
  RealUnitInFilename: String;
begin
  Result:=false;
  if (UsesNode=nil) then exit;
  MoveCursorToNodeStart(UsesNode);
  ReadNextAtom; // read 'uses'
  Changed:=false;
  repeat
    ReadNextAtom; // read name
    if not AtomIsIdentifier(false) then exit;
    ReadNextAtom;
    if UpAtomIs('IN') then begin
      ReadNextAtom;
      UnitInFilename:=GetAtom;
      //debugln('TStandardCodeTool.FixUsedUnitCaseInUsesSection A UnitInFilename="',UnitInFilename,'"');
      if (UnitInFilename<>'') and (UnitInFilename[1]='''') then begin
        UnitInFilename:=copy(UnitInFilename,2,length(UnitInFilename)-2);
        RealUnitInFilename:=FindUnit(UnitInFilename);
        //debugln('TStandardCodeTool.FixUsedUnitCaseInUsesSection B RealUnitInFilename="',RealUnitInFilename,'"');
        if (RealUnitInFilename<>'')
        and (RealUnitInFilename<>UnitInFilename) then begin
          if not Changed then begin
            SourceChangeCache.MainScanner:=Scanner;
            Changed:=true;
          end;
          debugln('TStandardCodeTool.FixUsedUnitCaseInUsesSection Replacing UnitInFilename="',UnitInFilename,'" with "',RealUnitInFilename,'"');
          if not SourceChangeCache.Replace(gtNone,gtNone,
            CurPos.StartPos,CurPos.EndPos,''''+RealUnitInFilename+'''') then exit;
        end;
      end;
      ReadNextAtom;
    end;
    if AtomIsChar(';') then break;
    if not AtomIsChar(',') then exit;
  until (CurPos.StartPos>UsesNode.EndPos) or (CurPos.StartPos>SrcLen);
  if Changed and (not SourceChangeCache.Apply) then exit;
  Result:=true;
end;

function TStandardCodeTool.FindUsedUnitNames(var MainUsesSection,
  ImplementationUsesSection: TStrings): boolean;
var
  MainUsesNode, ImplementatioUsesNode: TCodeTreeNode;
begin
  MainUsesSection:=nil;
  ImplementationUsesSection:=nil;
  // find the uses sections
  BuildTree(false);
  MainUsesNode:=FindMainUsesSection;
  ImplementatioUsesNode:=FindImplementationUsesSection;
  // create lists
  try
    MainUsesSection:=UsesSectionToUnitNames(MainUsesNode);
    ImplementationUsesSection:=UsesSectionToUnitNames(ImplementatioUsesNode);
  except
    FreeAndNil(MainUsesSection);
    FreeAndNil(ImplementationUsesSection);
    raise;
  end;
  Result:=true;
end;

function TStandardCodeTool.FindUsedUnitNames(var List: TStringToStringTree
  ): boolean;
  
  procedure Collect(UsesNode: TCodeTreeNode; const Tag: string);
  var
    UnitNameAtom: TAtomPosition;
    InAtom: TAtomPosition;
    OldTag: string;
    AnUnitName: String;
  begin
    if UsesNode=nil then exit;
    MoveCursorToUsesStart(UsesNode);
    repeat
      // read next unit name
      ReadNextUsedUnit(UnitNameAtom, InAtom);
      AnUnitName:=GetAtom(UnitNameAtom);
      // tag unit in list
      OldTag:=List[AnUnitName];
      if System.Pos(Tag,OldTag)<1 then
        List[AnUnitName]:=OldTag+Tag;
      if CurPos.Flag=cafComma then begin
        // read next unit name
        ReadNextAtom;
      end else if CurPos.Flag=cafSemicolon then begin
        break;
      end else
        RaiseExceptionFmt(ctsStrExpectedButAtomFound,[';',GetAtom]);
    until false;
    Result:=true;
  end;
  
begin
  // find the uses sections
  List:=TStringToStringTree.Create(false);
  BuildTree(false);
  Collect(FindMainUsesSection,'Main');
  Collect(FindMainUsesSection,'Implementation');
  Result:=true;
end;

function TStandardCodeTool.FindUsedUnitFiles(var MainUsesSection: TStrings
  ): boolean;
var
  MainUsesNode: TCodeTreeNode;
begin
  MainUsesSection:=nil;
  // find the uses sections
  BuildTree(true);
  MainUsesNode:=FindMainUsesSection;
  // create lists
  try
    MainUsesSection:=UsesSectionToFilenames(MainUsesNode);
  except
    FreeAndNil(MainUsesSection);
    raise;
  end;
  Result:=true;
end;

function TStandardCodeTool.FindUsedUnitFiles(var MainUsesSection,
  ImplementationUsesSection: TStrings): boolean;
var
  MainUsesNode, ImplementatioUsesNode: TCodeTreeNode;
begin
  MainUsesSection:=nil;
  ImplementationUsesSection:=nil;
  // find the uses sections
  BuildTree(false);
  MainUsesNode:=FindMainUsesSection;
  ImplementatioUsesNode:=FindImplementationUsesSection;
  // create lists
  try
    MainUsesSection:=UsesSectionToFilenames(MainUsesNode);
    ImplementationUsesSection:=UsesSectionToFilenames(ImplementatioUsesNode);
  except
    FreeAndNil(MainUsesSection);
    FreeAndNil(ImplementationUsesSection);
    raise;
  end;
  Result:=true;
end;

{------------------------------------------------------------------------------
  function TStandardCodeTool.FindDelphiProjectUnits(var FoundInUnits,
    MissingInUnits, NormalUnits: TStrings): boolean;

  Reads the main uses section and tries to find each unit file having
  an 'in' modifier.
  The associated objects in the list will be the found codebuffers.
  FoundInUnits returns the list of found 'in' unitnames plus TCodeBuffer
  MissingInUnits returns the list of missing 'in' unitnames
  NormalUnits returns the list of unitnames plus TCodeBuffer (if found)

  If no codebuffer was found/created then the filename will be the unit name
  plus the 'in' extension.
------------------------------------------------------------------------------}
function TStandardCodeTool.FindDelphiProjectUnits(var FoundInUnits,
  MissingInUnits, NormalUnits: TStrings; UseContainsSection: boolean): boolean;
var
  InAtom, UnitNameAtom: TAtomPosition;
  AnUnitName, AnUnitInFilename: string;
  NewCode: TCodeBuffer;
  UsesNode: TCodeTreeNode;
begin
  Result:=false;
  FoundInUnits:=nil;
  MissingInUnits:=nil;
  NormalUnits:=nil;
  DebugLn('TStandardCodeTool.FindDelphiProjectUnits UseContainsSection=',dbgs(UseContainsSection));
  // find the uses sections
  BuildTree(false);
  UsesNode:=FindMainUsesSection(UseContainsSection);
  if UsesNode=nil then exit;
  MoveCursorToUsesStart(UsesNode);
  FoundInUnits:=TStringList.Create;
  MissingInUnits:=TStringList.Create;
  NormalUnits:=TStringList.Create;
  repeat
    // read next unit name
    ReadNextUsedUnit(UnitNameAtom, InAtom);
    AnUnitName:=GetAtom(UnitNameAtom);
    if InAtom.StartPos>0 then begin
      AnUnitInFilename:=copy(Src,InAtom.StartPos+1,
                             InAtom.EndPos-InAtom.StartPos-2);
    end else
      AnUnitInFilename:='';
    // find unit file
    if AnUnitInFilename<>'' then begin
      // An 'in' unit => Delphi project file
      NewCode:=FindUnitSource(AnUnitName,AnUnitInFilename,false);
      if (NewCode=nil) then begin
        // no source found
        MissingInUnits.Add(AnUnitName+' in '+AnUnitInFilename);
      end else begin
        // source found => add filename to list
        FoundInUnits.AddObject(AnUnitName+' in '+AnUnitInFilename,NewCode);
      end;
    end else begin
      // the units without 'in' are 'Forms' or units added by the user
      NewCode:=FindUnitSource(AnUnitName,AnUnitInFilename,false);
      NormalUnits.AddObject(AnUnitName,NewCode);
    end;
    if CurPos.Flag=cafComma then begin
      // read next unit name
      ReadNextAtom;
    end else if CurPos.Flag=cafSemicolon then begin
      break;
    end else
      RaiseExceptionFmt(ctsStrExpectedButAtomFound,[';',GetAtom]);
  until false;
  Result:=true;
end;

{------------------------------------------------------------------------------
  function TStandardCodeTool.UsesSectionToFilenames(UsesNode: TCodeTreeNode
    ): TStrings;

  Reads the uses section backwards and tries to find each unit file.
  The associated objects in the list will be the found codebuffers.
  If no codebuffer was found/created then the filename will be the unit name
  plus the 'in' extension.
------------------------------------------------------------------------------}
function TStandardCodeTool.UsesSectionToFilenames(UsesNode: TCodeTreeNode
  ): TStrings;
var
  InAtom, UnitNameAtom: TAtomPosition;
  AnUnitName, AnUnitInFilename: string;
  NewCode: TCodeBuffer;
  UnitFilename: string;
begin
  Result:=TStringList.Create;
  if UsesNode=nil then exit;
  MoveCursorToUsesEnd(UsesNode);
  repeat
    // read prior unit name
    ReadPriorUsedUnit(UnitNameAtom, InAtom);
    AnUnitName:=GetAtom(UnitNameAtom);
    if InAtom.StartPos>0 then
      AnUnitInFilename:=copy(Src,InAtom.StartPos+1,
                             InAtom.EndPos-InAtom.StartPos-2)
    else
      AnUnitInFilename:='';
    // find unit file
    NewCode:=FindUnitSource(AnUnitName,AnUnitInFilename,false);
    if (NewCode=nil) then begin
      // no source found
      UnitFilename:=AnUnitName;
      if AnUnitInFilename<>'' then
        UnitFilename:=UnitFilename+' in '+AnUnitInFilename;
    end else begin
      // source found
      UnitFilename:=NewCode.Filename;
    end;
    // add filename to list
    Result.AddObject(UnitFilename,NewCode);
    // read keyword 'uses' or comma
    ReadPriorAtom;
  until not AtomIsChar(',');
end;

function TStandardCodeTool.UsesSectionToUnitnames(UsesNode: TCodeTreeNode
  ): TStrings;
var
  InAtom, UnitNameAtom: TAtomPosition;
  AnUnitName: string;
begin
  Result:=TStringList.Create;
  if UsesNode=nil then exit;
  MoveCursorToUsesEnd(UsesNode);
  repeat
    // read prior unit name
    ReadPriorUsedUnit(UnitNameAtom, InAtom);
    AnUnitName:=GetAtom(UnitNameAtom);
    Result.Add(AnUnitName);
    // read keyword 'uses' or comma
    ReadPriorAtom;
  until not AtomIsChar(',');
end;

function TStandardCodeTool.FindMissingUnits(var MissingUnits: TStrings;
  FixCase: boolean; SearchImplementation: boolean;
  SourceChangeCache: TSourceChangeCache): boolean;
  
  function CheckUsesSection(UsesNode: TCodeTreeNode): boolean;
  var
    InAtom, UnitNameAtom: TAtomPosition;
    OldUnitName: String;
    OldInFilename: String;
    AFilename: String;
    s: String;
    NewUnitName: String;
    NewInFilename: String;
    FromPos: LongInt;
    ToPos: LongInt;
  begin
    if UsesNode=nil then exit(true);
    if not CheckDirectoryCache then exit(false);

    MoveCursorToUsesStart(UsesNode);
    repeat
      // read next unit name
      ReadNextUsedUnit(UnitNameAtom, InAtom);
      OldUnitName:=GetAtom(UnitNameAtom);
      if InAtom.StartPos>0 then
        OldInFilename:=copy(Src,InAtom.StartPos+1,
                               InAtom.EndPos-InAtom.StartPos-2)
      else
        OldInFilename:='';
      // find unit file
      NewUnitName:=OldUnitName;
      NewInFilename:=OldInFilename;
      AFilename:=DirectoryCache.FindUnitSourceInCompletePath(
                                                NewUnitName,NewInFilename,true);
      s:=NewUnitName;
      if NewInFilename<>'' then
        s:=s+' in '''+NewInFilename+'''';
      if AFilename<>'' then begin
        // unit found
        if (NewUnitName<>OldUnitName) or (NewInFilename<>OldInFilename) then
        begin
          // fix case
          FromPos:=UnitNameAtom.StartPos;
          if InAtom.StartPos>0 then
            ToPos:=InAtom.EndPos
          else
            ToPos:=UnitNameAtom.EndPos;
          SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,s);
          DebugLn('CheckUsesSection fix case UnitName(',OldUnitName,'->',NewUnitName,') InFile(',OldInFilename,'->',NewInFilename,')');
        end;
      end else begin
        // unit not found
        if MissingUnits=nil then MissingUnits:=TStringList.Create;
        MissingUnits.Add(s);
      end;
      if CurPos.Flag=cafComma then begin
        // read next unit name
        ReadNextAtom;
      end else if CurPos.Flag=cafSemicolon then begin
        break;
      end else
        RaiseExceptionFmt(ctsStrExpectedButAtomFound,[';',GetAtom]);
    until false;
    Result:=true;
  end;
  
begin
  Result:=false;
  BuildTree(false);
  if FixCase then
    SourceChangeCache.MainScanner:=Scanner;
  try
    if not CheckUsesSection(FindMainUsesSection) then exit;
    if SearchImplementation
    and not CheckUsesSection(FindImplementationUsesSection) then exit;
  except
    FreeAndNil(MissingUnits);
    raise;
  end;
  if FixCase then
    Result:=SourceChangeCache.Apply
  else
    Result:=true;
end;

function TStandardCodeTool.CommentUnitsInUsesSections(MissingUnits: TStrings;
  SourceChangeCache: TSourceChangeCache): boolean;
  
  procedure Comment(StartPos, EndPos: integer);
  begin
    CommentCode(StartPos,EndPos,SourceChangeCache,false);
  end;

  function CommentUnitsInUsesSection(UsesNode: TCodeTreeNode): boolean;
  // Examples:
  // 1. uses {a,} b, c;    commenting one unit not at end
  // 2. uses a, {b,} c;    commenting one unit not at end
  // 3. uses {a, b,} c;    commenting several units not at end
  // 4. uses a{, b, c} ;   commenting units at end
  // 5. {uses a, b, c;}    commenting all units
  // 6. uses {a,} b{, c};  commenting several units
  var
    i: Integer;
    CurUnitName: String;
    CommentCurUnit: Boolean;
    FirstCommentUnitStart: Integer;
    LastCommaAfterCommentUnitsStart: Integer;
    LastNormalUnitEnd: Integer;
    LastCommentUnitEnd: Integer;
  begin
    Result:=true;
    if UsesNode=nil then exit;
    MoveCursorToUsesStart(UsesNode);
    FirstCommentUnitStart:=-1;
    LastCommaAfterCommentUnitsStart:=-1;
    LastNormalUnitEnd:=-1;
    LastCommentUnitEnd:=-1;
    repeat
      // check if unit should be commented
      AtomIsIdentifier(true);
      CurUnitName:=GetAtom;
      i:=MissingUnits.Count-1;
      while (i>=0)
      and (CompareIdentifiers(PChar(Pointer(MissingUnits[i])),
                              PChar(Pointer(CurUnitName)))<>0) do
        dec(i);
      CommentCurUnit:=i>=0;
      //debugln('CommentUnitsInUsesSection CurUnitName="',CurUnitName,'" CommentCurUnit=',dbgs(CommentCurUnit));
      
      if CommentCurUnit then begin
        // unit should be commented
        if FirstCommentUnitStart<1 then FirstCommentUnitStart:=CurPos.StartPos;
        LastCommentUnitEnd:=CurPos.EndPos;
      end else begin
        // unit should be kept
        LastNormalUnitEnd:=CurPos.EndPos;
        if FirstCommentUnitStart>=1 then begin
          // there are some units to be commented
          // See examples: 1., 2., 3. and 6.
          Comment(FirstCommentUnitStart,LastCommaAfterCommentUnitsStart);
          FirstCommentUnitStart:=-1;
          LastCommentUnitEnd:=-1;
          LastCommaAfterCommentUnitsStart:=-1;
        end;
      end;
      
      ReadNextAtom;
      if UpAtomIs('IN') then begin
        ReadNextAtom; // read filename
        if not AtomIsStringConstant then
          RaiseExceptionFmt(ctsStrExpectedButAtomFound,[ctsStringConstant,GetAtom]);
        if (not CommentCurUnit) then
          LastNormalUnitEnd:=CurPos.EndPos;
        if CommentCurUnit then
          LastCommentUnitEnd:=CurPos.EndPos;
        ReadNextAtom; // read comma or semicolon
      end;
        
      if CommentCurUnit then
        LastCommaAfterCommentUnitsStart:=CurPos.EndPos;
        
      if CurPos.Flag<>cafComma then begin
        if CommentCurUnit then begin
          // last unit must be commented
          if LastNormalUnitEnd>=1 then begin
            // comment last unit and keep some units in front
            // See example: 4.
            Comment(LastNormalUnitEnd,LastCommentUnitEnd);
          end else begin
            // all units should be commented
            // See example: 5.
            Comment(UsesNode.StartPos,CurPos.EndPos);
          end;
        end;
        break;
      end;
      
      ReadNextAtom;
    until false;
  end;
  
begin
  Result:=false;
  if (MissingUnits=nil) or (MissingUnits.Count=0) then begin
    Result:=true;
    exit;
  end;
  BuildTree(false);
  SourceChangeCache.MainScanner:=Scanner;
  if not CommentUnitsInUsesSection(FindMainUsesSection) then exit;
  if not CommentUnitsInUsesSection(FindImplementationUsesSection) then exit;
  if not SourceChangeCache.Apply then exit;
  Result:=true;
end;

function TStandardCodeTool.FindNextIncludeInInitialization(
  var LinkIndex: integer): TCodeBuffer;
// LinkIndex < 0  ->  search first
var
  InitializationNode: TCodeTreeNode;
  StartCode: TCodeBuffer;
begin
  Result:=nil;
  if LinkIndex<0 then begin
    BuildTree(false);
    InitializationNode:=FindInitializationNode;
    if InitializationNode=nil then exit;
    LinkIndex:=Scanner.LinkIndexAtCleanPos(InitializationNode.StartPos);
  end else
    inc(LinkIndex);
  if (LinkIndex<0) or (LinkIndex>=Scanner.LinkCount) then exit;
  StartCode:=TCodeBuffer(Scanner.Links[LinkIndex].Code);
  while (LinkIndex<Scanner.LinkCount)
  and (Scanner.Links[LinkIndex].CleanedPos<InitializationNode.EndPos) do begin
    Result:=TCodeBuffer(Scanner.Links[LinkIndex].Code);
    if (Result<>StartCode) then
      exit;
    inc(LinkIndex);
  end;
  Result:=nil;
end;

function TStandardCodeTool.FindLazarusResourceInBuffer(
  ResourceCode: TCodeBuffer; const ResourceName: string): TAtomPosition;
var ResNameCode: string;

  function ReadLazResource: boolean;
  begin
    Result:=false;
    if not ReadNextAtomIsChar('.') then exit;
    if not ReadNextUpAtomIs('ADD') then exit;
    if not ReadNextAtomIsChar('(') then exit;
    ReadNextAtom;
    if not AtomIsStringConstant then exit;
    if UpAtomIs(ResNameCode) then
      Result:=true;
    repeat
      ReadNextAtom;
    until (CurPos.StartPos>SrcLen) or (AtomIsChar(')'));
    ReadNextAtom; // read ';'
  end;
  
var CleanPos, MaxCleanPos: integer;
begin
  Result.StartPos:=-1;
  if (ResourceCode=nil) or (ResourceName='') or (length(ResourceName)>255) then
    exit;
  if Scanner.CursorToCleanPos(1,ResourceCode,CleanPos)<>0 then exit;
  if Scanner.CursorToCleanPos(ResourceCode.SourceLength,ResourceCode,
    MaxCleanPos)<>0 then
    MaxCleanPos:=-1;
  MoveCursorToCleanPos(CleanPos);
  ResNameCode:=''''+UpperCaseStr(ResourceName)+'''';
  // search "LazarusResources.Add('<ResourceName>',"
  repeat
    ReadNextAtom; // read 'LazarusResources'
    if UpAtomIs('LAZARUSRESOURCES') then begin
      Result.StartPos:=CurPos.StartPos;
      if ReadLazResource then begin
        Result.EndPos:=CurPos.EndPos;
        exit;
      end;
    end;
  until (CurPos.StartPos>SrcLen) or UpAtomIs('END')
  or ((MaxCleanPos>0) and (CurPos.StartPos>MaxCleanPos));
  Result.StartPos:=-1;
end;

function TStandardCodeTool.FindLazarusResource(
  const ResourceName: string): TAtomPosition;
// search Resource in all include files
var LinkIndex: integer;
  CurCode: TCodeBuffer;
begin
  Result.StartPos:=-1;
  Result.EndPos:=-1;
  Result.Flag:=cafNone;
  LinkIndex:=-1;
  CurCode:=FindNextIncludeInInitialization(LinkIndex);
  while (CurCode<>nil) do begin
    Result:=FindLazarusResourceInBuffer(CurCode,ResourceName);
    if Result.StartPos>0 then exit;
    CurCode:=FindNextIncludeInInitialization(LinkIndex);
  end;
end;

function TStandardCodeTool.AddLazarusResource(ResourceCode: TCodeBuffer;
  const ResourceName, ResourceData: string;
  SourceChangeCache: TSourceChangeCache): boolean;
// ResoureData is the complete LazarusResource Statement
var FromPos, ToPos, i: integer;
  OldPosition: TAtomPosition;
begin
  Result:=false;
  if (ResourceCode=nil) or (ResourceName='') or (length(ResourceName)>255)
  or (ResourceData='') or (SourceChangeCache=nil) then exit;
  BuildTree(false);
  SourceChangeCache.MainScanner:=Scanner;
  OldPosition:=FindLazarusResourceInBuffer(ResourceCode,ResourceName);
  if OldPosition.StartPos>0 then begin
    // replace old resource
    FromPos:=OldPosition.StartPos;
    ToPos:=OldPosition.EndPos;
    if not SourceChangeCache.Replace(gtNewLine,gtNewLine,FromPos,ToPos,
      ResourceData) then exit;
  end else begin
    // insert new resource
    if ResourceCode.SourceLength>0 then begin
      if Scanner.CursorToCleanPos(ResourceCode.SourceLength,ResourceCode,
        FromPos)<>0 then exit;
      inc(FromPos);
    end else begin
      // resource code empty -> can not be found in cleaned code
      // special replace
      i:=0;
      while (i<Scanner.LinkCount) 
      and (Scanner.Links[i].Code<>Pointer(ResourceCode)) do
        inc(i);
      if i>=Scanner.LinkCount then exit;
      FromPos:=Scanner.Links[i].CleanedPos;
    end;
    if not SourceChangeCache.ReplaceEx(gtNewLine,gtNewLine,FromPos,FromPos,
      ResourceCode,ResourceCode.SourceLength+1,ResourceCode.SourceLength+1,
      ResourceData)
    then exit;
  end;
  if not SourceChangeCache.Apply then exit;
  Result:=true;
end;

function TStandardCodeTool.RemoveLazarusResource(ResourceCode: TCodeBuffer;
  const ResourceName: string;
  SourceChangeCache: TSourceChangeCache): boolean;
var OldPosition: TAtomPosition;
begin
  Result:=false;
  if (ResourceCode=nil) or (ResourceName='') or (length(ResourceName)>255)
  or (SourceChangeCache=nil) then exit;
  BuildTree(false);
  SourceChangeCache.MainScanner:=Scanner;
  OldPosition:=FindLazarusResourceInBuffer(ResourceCode,ResourceName);
  if OldPosition.StartPos>0 then begin
    OldPosition.StartPos:=FindLineEndOrCodeInFrontOfPosition(
         OldPosition.StartPos);
    OldPosition.EndPos:=FindLineEndOrCodeAfterPosition(OldPosition.EndPos);
    if not SourceChangeCache.Replace(gtNone,gtNone,
      OldPosition.StartPos,OldPosition.EndPos,'') then exit;
  end;
  if not SourceChangeCache.Apply then exit;
  Result:=true;
end;

function TStandardCodeTool.RenameInclude(LinkIndex: integer;
  const NewFilename: string; KeepPath: boolean;
  SourceChangeCache: TSourceChangeCache): boolean;
{ change filename in an include directive
  if KeepPath is true and the include dircetive contains a path
  (relative or absolute), then this path is kept and only the filename is
  replaced
}
var IncludeStart, IncludeEnd, FileStart, FileNameStart, FileEnd: integer;
begin
  Result:=false;
  if (LinkIndex<0) or (LinkIndex>=Scanner.LinkCount) or (NewFileName='')
  or (KeepPath and (length(NewFilename)>255))
  or (SourceChangeCache=nil) then exit;
  // find include directive
  IncludeEnd:=Scanner.Links[LinkIndex].CleanedPos;
  IncludeStart:=IncludeEnd-1;
  if IncludeStart<1 then exit;
  case Src[IncludeStart] of
    '}':
      begin
        FileEnd:=IncludeStart;
        dec(IncludeStart);
        while (IncludeStart>0) and (Src[IncludeStart]<>'{') do
          dec(IncludeStart);
      end;
    ')':
      begin
        dec(IncludeStart);
        FileEnd:=IncludeStart;
        while (IncludeStart>1)
        and ((Src[IncludeStart]<>'*') or (Src[IncludeStart-1]<>'(')) do
          dec(IncludeStart);
      end;
    #13,#10:
      begin
        FileEnd:=IncludeStart;
        if (FileEnd>0) and (IsLineEndChar[Src[FileEnd]]) then dec(FileEnd);
        dec(IncludeStart);
        while (IncludeStart>1)
        and ((Src[IncludeStart]<>'/') or (Src[IncludeStart-1]<>'/')) do
          dec(IncludeStart);
      end;
  end;
  if IncludeStart<1 then exit;
  FileStart:=IncludeStart;
  while (FileStart<IncludeEnd) and (Src[FileStart]<>'$') do
    inc(FileStart);
  while (FileStart<IncludeEnd) and (not (IsSpaceChar[Src[FileStart]])) do
    inc(FileStart);
  while (FileStart<IncludeEnd) and (IsSpaceChar[Src[FileStart]]) do
    inc(FileStart);
  if FileStart>=IncludeEnd then exit;
  SourceChangeCache.MainScanner:=Scanner;
  if KeepPath then begin
    FileNameStart:=FileEnd;
    while (FileNameStart>FileStart) and (Src[FileNameStart]<>PathDelim) do
      dec(FileNameStart);
    if Src[FileNameStart]=PathDelim then
      FileStart:=FileNameStart+1;
  end;
  if not SourceChangeCache.Replace(gtNone,GtNone,FileStart,FileEnd,
    NewFilename) then exit;
  if not SourceChangeCache.Apply then exit;
  Result:=true;
end;

function TStandardCodeTool.CheckLFM(LFMBuf: TCodeBuffer; out LFMTree: TLFMTree;
  const OnFindDefineProperty: TOnFindDefinePropertyForContext;
  RootMustBeClassInIntf, ObjectsMustExists: boolean): boolean;
var
  RootContext: TFindContext;
  
  function CheckLFMObjectValues(LFMObject: TLFMObjectNode;
    const ClassContext: TFindContext): boolean; forward;

  function FindNonPublishedDefineProperty(LFMNode: TLFMTreeNode;
    DefaultErrorPosition: integer;
    const IdentName: string; const ClassContext: TFindContext): boolean;
  var
    PropertyNode: TLFMPropertyNode;
    ObjectNode: TLFMObjectNode;
    AncestorClassContext: TFindContext;
    Params: TFindDeclarationParams;
    IsDefined: Boolean;
  begin
    Result:=false;
    if (not (LFMNode is TLFMPropertyNode)) then exit;
    PropertyNode:=TLFMPropertyNode(LFMNode);
    if (PropertyNode.Parent=nil)
    or (not (PropertyNode.Parent is TLFMObjectNode)) then exit;
    ObjectNode:=TLFMObjectNode(PropertyNode.Parent);
    // find define property
    IsDefined:=false;
    if Assigned(OnFindDefineProperty) then begin
      AncestorClassContext:=CleanFindContext;
      if ClassContext.Tool=Self then begin
        // the class is defined in this source
        // -> try to find the ancestor class
        if ObjectNode.AncestorContextValid then begin
          AncestorClassContext:=CreateFindContext(
                                  TFindDeclarationTool(ObjectNode.AncestorTool),
                                  TCodeTreeNode(ObjectNode.AncestorNode));
        end else begin
          {$IFDEF VerboseCheckLFM}
          debugln('FindNonPublishedDefineProperty Class is defined in this source: search ancestor ... ');
          {$ENDIF}
          Params:=TFindDeclarationParams.Create;
          try
            Params.Flags:=[fdfSearchInAncestors,fdfExceptionOnNotFound,
                           fdfExceptionOnPredefinedIdent];
            Params.ContextNode:=ClassContext.Node;
            try
              if ClassContext.Tool.FindAncestorOfClass(ClassContext.Node,
                Params,true) then
              begin
                {$IFDEF VerboseCheckLFM}
                debugln('FindNonPublishedDefineProperty Ancestor found');
                {$ENDIF}
                AncestorClassContext:=CreateFindContext(Params);
                ObjectNode.AncestorTool:=AncestorClassContext.Tool;
                ObjectNode.AncestorNode:=AncestorClassContext.Node;
              end;
            except
              // ignore search/parse errors
              on E: ECodeToolError do ;
            end;
          finally
            Params.Free;
          end;
          ObjectNode.AncestorContextValid:=true;
        end;
      end;
      OnFindDefineProperty(Self,ClassContext,AncestorClassContext,LFMNode,
        IdentName,IsDefined);
      if IsDefined then begin
        //debugln('FindNonPublishedDefineProperty Path=',LFMNode.GetPath,' IdentName="',IdentName,'"');
      end else begin
        {$IFDEF VerboseCheckLFM}
        debugln('FindNonPublishedDefineProperty Path=',LFMNode.GetPath,' NO DEFINE PROPERTIES');
        {$ENDIF}
      end;
    end;
    Result:=IsDefined;
  end;

  function FindLFMIdentifier(LFMNode: TLFMTreeNode;
    DefaultErrorPosition: integer;
    const IdentName: string; const ClassContext: TFindContext;
    SearchAlsoInDefineProperties, ErrorOnNotFound: boolean;
    out IdentContext: TFindContext): boolean;
  var
    Params: TFindDeclarationParams;
    IdentifierNotPublished: Boolean;
    IsPublished: Boolean;
  begin
    Result:=false;
    IdentContext:=CleanFindContext;
    IsPublished:=false;
    if (ClassContext.Node=nil) or (ClassContext.Node.Desc<>ctnClass) then begin
      DebugLn('TStandardCodeTool.CheckLFM.FindLFMIdentifier Internal error');
      exit;
    end;
    Params:=TFindDeclarationParams.Create;
    try
      Params.Flags:=[fdfSearchInAncestors,fdfExceptionOnNotFound,
                     fdfExceptionOnPredefinedIdent,fdfIgnoreMissingParams,
                     fdfIgnoreOverloadedProcs];
      Params.ContextNode:=ClassContext.Node;
      Params.SetIdentifier(ClassContext.Tool,PChar(Pointer(IdentName)),nil);
      try
        {DebugLn('FindLFMIdentifier A ',
          ' Ident=',
          '"'+GetIdentifier(Params.Identifier)+'"',
          ' Context="'+ClassContext.Node.DescAsString,'" "',StringToPascalConst(copy(ClassContext.Tool.Src,ClassContext.Node.StartPos,20))+'"',
          ' File="'+ExtractFilename(ClassContext.Tool.MainFilename)+'"',
          ' Flags=['+FindDeclarationFlagsAsString(Params.Flags)+']'
          );}
        if ClassContext.Tool.FindIdentifierInContext(Params) then begin
          Result:=true;
          repeat
            IdentContext:=CreateFindContext(Params);
            if (not IsPublished)
            and (IdentContext.Node.HasParentOfType(ctnClassPublished)) then
              IsPublished:=true;
            
            if (IdentContext.Node<>nil)
            and (IdentContext.Node.Desc=ctnProperty)
            and (IdentContext.Tool.PropNodeIsTypeLess(IdentContext.Node)) then
            begin
              // this is a typeless property -> search further
              Params.Clear;
              Params.Flags:=[fdfSearchInAncestors,
                             fdfIgnoreMissingParams,
                             fdfIgnoreCurContextNode,
                             fdfIgnoreOverloadedProcs];
              Params.ContextNode:=IdentContext.Node.Parent;
              while (Params.ContextNode<>nil)
              and (not (Params.ContextNode.Desc in AllClasses)) do
                Params.ContextNode:=Params.ContextNode.Parent;
              if Params.ContextNode<>nil then begin
                Params.SetIdentifier(ClassContext.Tool,PChar(Pointer(IdentName)),nil);
                if not IdentContext.Tool.FindIdentifierInContext(Params) then
                begin
                  DebugLn(['FindLFMIdentifier ERROR ancestor of property not found: ',FindContextToString(IdentContext),' IdentName=',IdentName]);
                  break;
                end;
              end;
            end else
              break;
          until false;
        end;
      except
        // ignore search/parse errors
        on E: ECodeToolError do ;
      end;
    finally
      Params.Free;
    end;

    IdentifierNotPublished:=not IsPublished;

    if (IdentContext.Node=nil) or IdentifierNotPublished then begin
      // no proper node found
      // -> search in DefineProperties
      if SearchAlsoInDefineProperties then begin
        //debugln('FindLFMIdentifier A SearchAlsoInDefineProperties=',dbgs(SearchAlsoInDefineProperties));
        if FindNonPublishedDefineProperty(LFMNode,DefaultErrorPosition,
          IdentName,ClassContext)
        then begin
          Result:=true;
        end;
      end;
    end;
    if (not Result) and ErrorOnNotFound then begin
      if (IdentContext.Node<>nil) and IdentifierNotPublished then begin
        LFMTree.AddError(lfmeIdentifierNotPublished,LFMNode,
                         'identifier '+IdentName+' is not published in class '
                         +'"'+ClassContext.Tool.ExtractClassName(ClassContext.Node,false)+'"',
                         DefaultErrorPosition);
      end else begin
        LFMTree.AddError(lfmeIdentifierNotFound,LFMNode,
                         'identifier '+IdentName+' not found in class '
                         +'"'+ClassContext.Tool.ExtractClassName(ClassContext.Node,false)+'"',
                         DefaultErrorPosition);
      end;
    end;
  end;
  
  function FindClassNodeForLFMObject(LFMNode: TLFMTreeNode;
    DefaultErrorPosition: integer;
    StartTool: TFindDeclarationTool; DefinitionNode: TCodeTreeNode): TFindContext;
  var
    Params: TFindDeclarationParams;
    Identifier: PChar;
    OldInput: TFindDeclarationInput;
  begin
    Result:=CleanFindContext;
    if (DefinitionNode.Desc=ctnIdentifier) then
      Identifier:=@StartTool.Src[DefinitionNode.StartPos]
    else if DefinitionNode.Desc=ctnProperty then
      Identifier:=StartTool.GetPropertyTypeIdentifier(DefinitionNode)
    else
      Identifier:=nil;
    if Identifier=nil then exit;
    Params:=TFindDeclarationParams.Create;
    try
      Params.Flags:=[fdfSearchInAncestors,fdfExceptionOnNotFound,
        fdfSearchInParentNodes,
        fdfExceptionOnPredefinedIdent,fdfIgnoreMissingParams,
        fdfIgnoreOverloadedProcs];
      Params.ContextNode:=DefinitionNode;
      Params.SetIdentifier(StartTool,Identifier,nil);
      try
        Params.Save(OldInput);
        if StartTool.FindIdentifierInContext(Params) then begin
          Params.Load(OldInput,true);
          Result:=Params.NewCodeTool.FindBaseTypeOfNode(Params,Params.NewNode);
          if (Result.Node=nil) or (Result.Node.Desc<>ctnClass) then
            Result:=CleanFindContext;
        end;
      except
        // ignore search/parse errors
        on E: ECodeToolError do ;
      end;
    finally
      Params.Free;
    end;
    if Result.Node=nil then begin
      // FindClassNodeForLFMObject
      LFMTree.AddError(lfmeIdentifierNotFound,LFMNode,
                       'class '+GetIdentifier(Identifier)+' not found',
                       DefaultErrorPosition);
      exit;
    end;
  end;

  function CreateFootNote(const Context: TFindContext): string;
  var
    Caret: TCodeXYPosition;
  begin
    Result:=' see '+Context.Tool.MainFilename;
    if Context.Tool.CleanPosToCaret(Context.Node.StartPos,Caret) then
      Result:=Result+'('+IntToStr(Caret.Y)+','+IntToStr(Caret.X)+')';
  end;
  
  function FindClassContext(const ClassName: string): TFindContext;
  var
    Params: TFindDeclarationParams;
    Identifier: PChar;
    OldInput: TFindDeclarationInput;
    StartTool: TStandardCodeTool;
  begin
    Result:=CleanFindContext;
    Params:=TFindDeclarationParams.Create;
    StartTool:=Self;
    Identifier:=PChar(Pointer(ClassName));
    try
      Params.Flags:=[fdfExceptionOnNotFound,
        fdfSearchInParentNodes,
        fdfExceptionOnPredefinedIdent,fdfIgnoreMissingParams,
        fdfIgnoreOverloadedProcs];
      Params.ContextNode:=FindInterfaceNode;
      if Params.ContextNode=nil then
        Params.ContextNode:=FindMainUsesSection;
      Params.SetIdentifier(StartTool,Identifier,nil);
      try
        Params.Save(OldInput);
        if FindIdentifierInContext(Params) then begin
          Params.Load(OldInput,true);
          Result:=Params.NewCodeTool.FindBaseTypeOfNode(Params,Params.NewNode);
          if (Result.Node=nil) or (Result.Node.Desc<>ctnClass) then
            Result:=CleanFindContext;
        end;
      except
        // ignore search/parse errors
        on E: ECodeToolError do ;
      end;
    finally
      Params.Free;
    end;
  end;

  procedure CheckLFMChildObject(LFMObject: TLFMObjectNode;
    const ParentContext: TFindContext; SearchAlsoInDefineProperties: boolean);
  var
    LFMObjectName: String;
    ChildContext: TFindContext;
    VariableTypeName: String;
    DefinitionNode: TCodeTreeNode;
    ClassContext: TFindContext;
  begin
    // find variable for object
    
    // find identifier in Lookup Root
    LFMObjectName:=LFMObject.Name;
    //DebugLn('CheckChildObject A LFMObjectName="',LFMObjectName,'"');
    if LFMObjectName='' then begin
      LFMTree.AddError(lfmeObjectNameMissing,LFMObject,'missing object name',
                       LFMObject.StartPos);
      exit;
    end;
    
    if not FindLFMIdentifier(LFMObject,LFMObject.NamePosition,
      LFMObjectName,RootContext,SearchAlsoInDefineProperties,ObjectsMustExists,
      ChildContext)
    then begin
      // object name not found
      if ObjectsMustExists then
        exit;
    end;

    if ObjectsMustExists or (ChildContext.Node<>nil) then begin
      if ChildContext.Node=nil then begin
        // this is an extra entry, created via DefineProperties.
        // There is no generic way to test such things
        exit;
      end;

      // check if identifier is a variable or property
      VariableTypeName:='';
      if (ChildContext.Node.Desc=ctnVarDefinition) then begin
        DefinitionNode:=ChildContext.Tool.FindTypeNodeOfDefinition(
                                                             ChildContext.Node);
        if DefinitionNode=nil then begin
          ChildContext.Node:=DefinitionNode;
          LFMTree.AddError(lfmeObjectIncompatible,LFMObject,
                           LFMObjectName+' is not a variable.'
                           +CreateFootNote(ChildContext),
                           LFMObject.NamePosition);
          exit;
        end;

        VariableTypeName:=ChildContext.Tool.ExtractDefinitionNodeType(
                                                             ChildContext.Node);
      end else if (ChildContext.Node.Desc=ctnProperty) then begin
        DefinitionNode:=ChildContext.Node;
        VariableTypeName:=
               ChildContext.Tool.ExtractPropType(ChildContext.Node,false,false);
      end else begin
        LFMTree.AddError(lfmeObjectIncompatible,LFMObject,
                         LFMObjectName+' is not a variable'
                         +CreateFootNote(ChildContext),
                         LFMObject.NamePosition);
        exit;
      end;
      
      // check if variable/property has a compatible type
      if (VariableTypeName<>'') then begin
        if (LFMObject.TypeName<>'')
        and (CompareIdentifiers(PChar(VariableTypeName),
                                PChar(LFMObject.TypeName))<>0)
        then begin
          ChildContext.Node:=DefinitionNode;
          LFMTree.AddError(lfmeObjectIncompatible,LFMObject,
                         VariableTypeName+' expected, but '+LFMObject.TypeName+' found.'
                         +CreateFootNote(ChildContext),
                         LFMObject.NamePosition);
          exit;
        end;
        
        // check if variable/property type exists
        
      end;


      // find class node
      ClassContext:=FindClassNodeForLFMObject(LFMObject,LFMObject.TypeNamePosition,
                                              ChildContext.Tool,DefinitionNode);
    end else begin
      // try the object type
      ClassContext:=FindClassContext(LFMObject.TypeName);
      if ClassContext.Node=nil then begin
        // object type not found
        LFMTree.AddError(lfmeIdentifierNotFound,LFMObject,
                         'type '+LFMObject.TypeName+' not found',
                         LFMObject.TypeNamePosition);
        exit;
      end;
    end;
    if ClassContext.Node=nil then exit;

    // check child LFM nodes
    CheckLFMObjectValues(LFMObject,ClassContext);
  end;
  
  function FindClassNodeForPropertyType(LFMProperty: TLFMPropertyNode;
    DefaultErrorPosition: integer; const PropertyContext: TFindContext
    ): TFindContext;
  var
    Params: TFindDeclarationParams;
  begin
    Result:=CleanFindContext;
    Params:=TFindDeclarationParams.Create;
    try
      Params.Flags:=[fdfSearchInAncestors,fdfExceptionOnNotFound,
        fdfSearchInParentNodes,
        fdfExceptionOnPredefinedIdent,fdfIgnoreMissingParams,
        fdfIgnoreOverloadedProcs];
      Params.ContextNode:=PropertyContext.Node;
      Params.SetIdentifier(PropertyContext.Tool,nil,nil);
      try
        Result:=PropertyContext.Tool.FindBaseTypeOfNode(Params,
                                                        PropertyContext.Node);
      except
        // ignore search/parse errors
        on E: ECodeToolError do ;
      end;
    finally
      Params.Free;
    end;
    if Result.Node=nil then begin
      LFMTree.AddError(lfmePropertyHasNoSubProperties,LFMProperty,
                       'property has no sub properties',
                       DefaultErrorPosition);
      exit;
    end;
  end;

  procedure CheckLFMProperty(LFMProperty: TLFMPropertyNode;
    const ParentContext: TFindContext);
  // checks properties. For example lines like 'OnShow = FormShow'
  // or 'VertScrollBar.Range = 29'
  // LFMProperty is the property node
  // ParentContext is the context, where properties are searched.
  //               This can be a class or a property.
  var
    i: Integer;
    CurName: string;
    CurPropertyContext: TFindContext;
    SearchContext: TFindContext;
  begin
    // find complete property name
    //DebugLn('CheckLFMProperty A LFMProperty Name="',LFMProperty.CompleteName,'"');

    if LFMProperty.CompleteName='' then begin
      LFMTree.AddError(lfmePropertyNameMissing,LFMProperty,
                       'property without name',LFMProperty.StartPos);
      exit;
    end;
    
    // find every part of the property name
    SearchContext:=ParentContext;
    for i:=0 to LFMProperty.NameParts.Count-1 do begin
      if SearchContext.Node.Desc=ctnProperty then begin
        // get the type of the property and search the class node
        SearchContext:=FindClassNodeForPropertyType(LFMProperty,
          LFMProperty.NameParts.NamePositions[i],SearchContext);
        if SearchContext.Node=nil then exit;
      end;

      CurName:=LFMProperty.NameParts.Names[i];
      if not FindLFMIdentifier(LFMProperty,
                               LFMProperty.NameParts.NamePositions[i],
                               CurName,SearchContext,true,true,
                               CurPropertyContext)
      then
        break;
      if CurPropertyContext.Node=nil then begin
        // this is an extra entry, created via DefineProperties.
        // There is no generic way to test such things
        break;
      end;
      SearchContext:=CurPropertyContext;
    end;
    
    // ToDo: check value
  end;

  function CheckLFMObjectValues(LFMObject: TLFMObjectNode;
    const ClassContext: TFindContext): boolean;
  var
    CurLFMNode: TLFMTreeNode;
  begin
    //DebugLn('TStandardCodeTool.CheckLFM.CheckLFMObjectValues A ',LFMObject.Name,':',LFMObject.TypeName);
    CurLFMNode:=LFMObject.FirstChild;
    while CurLFMNode<>nil do begin
      //DebugLn('TStandardCodeTool.CheckLFM.CheckLFMObjectValues B ',CurLFMNode.ClassName);
      case CurLFMNode.TheType of
      
      lfmnObject:
        CheckLFMChildObject(TLFMObjectNode(CurLFMNode),ClassContext,false);

      lfmnProperty:
        CheckLFMProperty(TLFMPropertyNode(CurLFMNode),ClassContext);

      end;
      CurLFMNode:=CurLFMNode.NextSibling;
    end;
    Result:=true;
  end;
  
  function CheckLFMRoot(RootLFMNode: TLFMTreeNode): boolean;
  var
    LookupRootLFMNode: TLFMObjectNode;
    LookupRootTypeName: String;
    RootClassNode: TCodeTreeNode;
  begin
    Result:=false;
    
    //DebugLn('TStandardCodeTool.CheckLFM.CheckLFMRoot checking root ...');
    // get root object node
    if (RootLFMNode=nil) or (not (RootLFMNode is TLFMObjectNode)) then begin
      LFMTree.AddError(lfmeMissingRoot,nil,'missing root object',1);
      exit;
    end;
    LookupRootLFMNode:=TLFMObjectNode(RootLFMNode);
    
    // get type name of root object
    LookupRootTypeName:=UpperCaseStr(LookupRootLFMNode.TypeName);
    if LookupRootTypeName='' then begin
      LFMTree.AddError(lfmeMissingRoot,nil,'missing type of root object',1);
      exit;
    end;
    
    // find root type
    if RootMustBeClassInIntf then begin
      RootClassNode:=FindClassNodeInInterface(LookupRootTypeName,true,false,false);
      RootContext:=CleanFindContext;
      RootContext.Node:=RootClassNode;
      RootContext.Tool:=Self;
    end else begin
      RootContext:=FindClassContext(LookupRootTypeName);
      RootClassNode:=RootContext.Node;
    end;
    if RootClassNode=nil then begin
      LFMTree.AddError(lfmeMissingRoot,LookupRootLFMNode,
                       'type '+LookupRootLFMNode.TypeName+' not found',
                       LookupRootLFMNode.TypeNamePosition);
      exit;
    end;
    Result:=CheckLFMObjectValues(LookupRootLFMNode,RootContext);
  end;
  
var
  CurRootLFMNode: TLFMTreeNode;
begin
  Result:=false;
  //DebugLn('TStandardCodeTool.CheckLFM A');
  // create tree from LFM file
  LFMTree:=DefaultLFMTrees.GetLFMTree(LFMBuf,true);
  ActivateGlobalWriteLock;
  try
    //DebugLn('TStandardCodeTool.CheckLFM parsing LFM ...');
    if not LFMTree.ParseIfNeeded then exit;
    // parse unit and find LookupRoot
    //DebugLn('TStandardCodeTool.CheckLFM parsing unit ...');
    BuildTree(true);
    // find every identifier
    //DebugLn('TStandardCodeTool.CheckLFM checking identifiers ...');
    CurRootLFMNode:=LFMTree.Root;
    while CurRootLFMNode<>nil do begin
      if not CheckLFMRoot(CurRootLFMNode) then exit;
      CurRootLFMNode:=CurRootLFMNode.NextSibling;
    end;
  finally
    DeactivateGlobalWriteLock;
  end;

  Result:=LFMTree.FirstError=nil;
end;

function TStandardCodeTool.FindCreateFormStatement(StartPos: integer;
  const UpperClassName, UpperVarName: string;
  out Position: TAtomPosition): integer;
// 0=found, -1=not found, 1=found, but wrong classname
var MainBeginNode: TCodeTreeNode;
  ClassNameFits: boolean;
begin
  Result:=-1;
  Position.StartPos:=-1;
  if (UpperClassName='') or (UpperVarName='') or (length(UpperClassName)>255)
  or (length(UpperVarName)>255) then exit;
  if StartPos<1 then begin
    BuildTree(false);
    MainBeginNode:=FindMainBeginEndNode;
    if MainBeginNode=nil then exit;
    StartPos:=MainBeginNode.StartPos;
    if StartPos<1 then exit;
  end;
  MoveCursorToCleanPos(StartPos);
  repeat
    ReadNextAtom;
    if UpAtomIs('APPLICATION') then begin
      Position.StartPos:=CurPos.StartPos;
      if ReadNextAtomIsChar('.') and ReadNextUpAtomIs('CREATEFORM')
      and ReadNextAtomIsChar('(') then begin
        ReadNextAtom;
        ClassNameFits:=UpAtomIs(UpperClassName);
        if ReadNextAtomIsChar(',')
        and (ReadNextUpAtomIs(UpperVarName) or (UpperVarName='*')) then begin
          if ReadNextAtomIsChar(')') then ReadNextAtomIsChar(';');
          Position.EndPos:=CurPos.EndPos;
          if ClassNameFits then
            Result:=0
          else
            Result:=1;
          exit;
        end;
      end;
    end;
  until (CurPos.StartPos>SrcLen);
  Result:=-1;
end;

function TStandardCodeTool.AddCreateFormStatement(const AClassName,
  AVarName: string; SourceChangeCache: TSourceChangeCache): boolean;
var MainBeginNode: TCodeTreeNode;
  OldPosition: TAtomPosition;
  FromPos, ToPos, Indent: integer;
begin
  Result:=false;
  if (AClassName='') or (length(AClassName)>255) or (AVarName='')
  or (length(AVarName)>255) then exit;
  BuildTree(false);
  MainBeginNode:=FindMainBeginEndNode;
  if MainBeginNode=nil then exit;
  FromPos:=-1;
  if FindCreateFormStatement(MainBeginNode.StartPos,UpperCaseStr(AClassName),
    UpperCaseStr(AVarName),OldPosition)=-1 then begin
    // does not exist -> create as last in front of 'Application.Run'
    MoveCursorToCleanPos(MainBeginNode.StartPos);
    repeat
      if ReadNextUpAtomIs('APPLICATION') then begin
        FromPos:=CurPos.StartPos;
        if ReadNextAtomIsChar('.') and ReadNextUpAtomIs('RUN') then begin
          break;
        end;
        FromPos:=-1;
      end;
    until (CurPos.StartPos>SrcLen);
    if FromPos<1 then exit;
    SourceChangeCache.MainScanner:=Scanner;
    Indent:=GetLineIndent(Src,FromPos);
    FromPos:=FindLineEndOrCodeInFrontOfPosition(FromPos);
    SourceChangeCache.Replace(gtNewLine,gtNewLine,FromPos,FromPos,
       SourceChangeCache.BeautifyCodeOptions.BeautifyStatement(
         'Application.CreateForm('+AClassName+','+AVarName+');',Indent));
  end else begin
    // it exists -> replace it
    FromPos:=FindLineEndOrCodeInFrontOfPosition(OldPosition.StartPos);
    ToPos:=FindLineEndOrCodeAfterPosition(OldPosition.EndPos);
    SourceChangeCache.MainScanner:=Scanner;
    SourceChangeCache.Replace(gtNewLine,gtNewLine,FromPos,ToPos,
       SourceChangeCache.BeautifyCodeOptions.BeautifyStatement(
         'Application.CreateForm('+AClassName+','+AVarName+');',
         SourceChangeCache.BeautifyCodeOptions.Indent));
  end;
  Result:=SourceChangeCache.Apply;
end;

function TStandardCodeTool.RemoveCreateFormStatement(const UpperVarName: string;
  SourceChangeCache: TSourceChangeCache): boolean;
var Position: TAtomPosition;
  FromPos, ToPos: integer;
begin
  Result:=false;
  if FindCreateFormStatement(-1,'*',UpperVarName,Position)=-1 then
    exit;
  FromPos:=FindLineEndOrCodeInFrontOfPosition(Position.StartPos);
  ToPos:=FindLineEndOrCodeAfterPosition(Position.EndPos);
  SourceChangeCache.MainScanner:=Scanner;
  SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,'');
  Result:=SourceChangeCache.Apply;
end;

function TStandardCodeTool.ChangeCreateFormStatement(StartPos: integer;
  const OldClassName, OldVarName: string;
  const NewClassName, NewVarName: string;
  OnlyIfExists: boolean; SourceChangeCache: TSourceChangeCache): boolean;
var MainBeginNode: TCodeTreeNode;
  OldPosition: TAtomPosition;
  FromPos, ToPos: integer;
begin
  Result:=false;
  if (OldClassName='') or (length(OldClassName)>255)
  or (OldVarName='') or (length(OldVarName)>255)
  or (NewClassName='') or (length(NewClassName)>255)
  or (NewVarName='') or (length(NewVarName)>255)
  then exit;
  BuildTree(false);
  MainBeginNode:=FindMainBeginEndNode;
  if MainBeginNode=nil then exit;
  FromPos:=-1;
  if FindCreateFormStatement(MainBeginNode.StartPos,UpperCaseStr(OldClassName),
    UpperCaseStr(OldVarName),OldPosition)=-1 then begin
    // does not exist
    if OnlyIfExists then begin
      Result:=true;
      exit;
    end;
    Result:=AddCreateFormStatement(NewClassName,NewVarName,SourceChangeCache);
  end else begin
    // replace
    FromPos:=FindLineEndOrCodeInFrontOfPosition(OldPosition.StartPos);
    ToPos:=FindLineEndOrCodeAfterPosition(OldPosition.EndPos);
    SourceChangeCache.MainScanner:=Scanner;
    SourceChangeCache.Replace(gtNewLine,gtNewLine,FromPos,ToPos,
       SourceChangeCache.BeautifyCodeOptions.BeautifyStatement(
         'Application.CreateForm('+NewClassName+','+NewVarName+');',
         SourceChangeCache.BeautifyCodeOptions.Indent));
    Result:=SourceChangeCache.Apply;
  end;
end;

function TStandardCodeTool.ListAllCreateFormStatements: TStrings;
// list format: VarName:ClassName
var Position: integer;
  StatementPos: TAtomPosition;
  s:string;
  var MainBeginNode: TCodeTreeNode;
begin
  BuildTree(false);
  Result:=TStringList.Create;
  MainBeginNode:=FindMainBeginEndNode;
  if MainBeginNode=nil then exit;
  Position:=MainBeginNode.StartPos;
  repeat
    if FindCreateFormStatement(Position,'*','*',StatementPos)=-1 then
      exit;
    Position:=StatementPos.EndPos;
    MoveCursorToCleanPos(StatementPos.StartPos);
    ReadNextAtom; // read 'Application'
    ReadNextAtom; // read '.'
    ReadNextAtom; // read 'CreateForm'
    ReadNextAtom; // read '('
    ReadNextAtom; // read class name
    s:=GetAtom;
    ReadNextAtom; // read ','
    ReadNextAtom; // read variable name
    s:=GetAtom+':'+s;
    Result.Add(s);
  until false;
end;

function TStandardCodeTool.SetAllCreateFromStatements(List: TStrings;
  SourceChangeCache: TSourceChangeCache): boolean;
{ every string in the list has the format VarName:ClassName
  or simply VarName In the latter case it will be automatically expanded
  to VarName:TVarName
  
  ToDo: do it less destructable
}
var Position, InsertPos, i, ColonPos, Indent: integer;
  StatementPos: TAtomPosition;
  MainBeginNode: TCodeTreeNode;
  AClassName, AVarName: string;
begin
  Result:= false;
  if (List = nil) or (SourceChangeCache = nil) then exit;
  BuildTree(false);

  { first delete all CreateForm Statements }
  SourceChangeCache.MainScanner:= Scanner;
  MainBeginNode:= FindMainBeginEndNode;
  if MainBeginNode = nil then exit;
  Position:= MainBeginNode.StartPos;
  InsertPos:= -1;
  repeat
    if FindCreateFormStatement(Position, '*', '*', StatementPos) = -1 then break;

    Position:= StatementPos.EndPos;
    StatementPos.StartPos:= FindLineEndOrCodeInFrontOfPosition(StatementPos.StartPos);
    if InsertPos < 1 then InsertPos:= StatementPos.StartPos;

    StatementPos.EndPos:= FindLineEndOrCodeAfterPosition(StatementPos.EndPos);

    SourceChangeCache.Replace(gtNone,gtNone, StatementPos.StartPos, StatementPos.EndPos, '');
  until false;

  Result:= SourceChangeCache.Apply;

  { then add all CreateForm Statements }
  if InsertPos < 1 then begin

    { there was no createform statement -> insert in front of Application.Run }
    MoveCursorToCleanPos(MainBeginNode.StartPos);
    repeat
      if ReadNextUpAtomIs('APPLICATION') then begin
        InsertPos:=CurPos.StartPos;
        if ReadNextAtomIsChar('.') and ReadNextUpAtomIs('RUN') then begin
          InsertPos:=FindLineEndOrCodeInFrontOfPosition(InsertPos);
          break;
        end;
        InsertPos:=-1;
      end;
    until (CurPos.StartPos>SrcLen);
    if InsertPos < 1 then exit;
  end;

  for i:= 0 to List.Count - 1 do begin
    if Length(List[i]) <= 1 then continue;

    ColonPos:= Pos(List[i], ':');
    if (ColonPos > 1) then begin
      AVarName:= Copy(List[i], 1, ColonPos);
      AClassName:= Copy(List[i], ColonPos + 1, Length(List[i]) - ColonPos);
    end else begin
      AVarName:= List[i];  
      AClassName:= 'T' + AVarName;
    end;  
    Indent:= GetLineIndent(Src, InsertPos);

    SourceChangeCache.Replace(gtNewLine, gtNewLine, InsertPos, InsertPos,
      SourceChangeCache.BeautifyCodeOptions.BeautifyStatement(
        'Application.CreateForm('+AClassName+','+AVarName+');', Indent));
  end;
  Result:= Result and SourceChangeCache.Apply;
end;

function TStandardCodeTool.FindApplicationTitleStatement(out StartPos,
  StringConstStartPos, EndPos: integer): boolean;
var
  MainBeginNode: TCodeTreeNode;
  Position: Integer;
begin
  Result:=false;
  StartPos:=-1;
  StringConstStartPos:=-1;
  EndPos:=-1;
  BuildTree(false);
  MainBeginNode:=FindMainBeginEndNode;
  if MainBeginNode=nil then exit;
  Position:=MainBeginNode.StartPos;
  if Position<1 then exit;
  MoveCursorToCleanPos(Position);
  repeat
    ReadNextAtom;
    if UpAtomIs('APPLICATION') then begin
      StartPos:=CurPos.StartPos;
      if ReadNextAtomIsChar('.') and ReadNextUpAtomIs('TITLE')
      and ReadNextUpAtomIs(':=') then begin
        // read till semicolon or end
        repeat
          ReadNextAtom;
          if StringConstStartPos<1 then
            StringConstStartPos:=CurPos.StartPos;
          EndPos:=CurPos.EndPos;
          if CurPos.Flag in [cafEnd,cafSemicolon] then begin
            Result:=true;
            exit;
          end;
        until CurPos.StartPos>SrcLen;
      end;
    end;
  until (CurPos.StartPos>SrcLen);
end;

function TStandardCodeTool.GetApplicationTitleStatement(StringConstStartPos,
  EndPos: integer; var Title: string): boolean;
var
  FormatStringParams: string;
begin
  Result:=false;
  Title:='';
  if (StringConstStartPos<1) or (StringConstStartPos>SrcLen) then exit;
  MoveCursorToCleanPos(StringConstStartPos);
  ReadNextAtom;
  if not AtomIsStringConstant then exit;
  Result:=GetStringConstAsFormatString(StringConstStartPos,EndPos,Title,
                                       FormatStringParams);
  if FormatStringParams='' then ;
end;

function TStandardCodeTool.SetApplicationTitleStatement(const NewTitle: string;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  StartPos, StringConstStartPos, EndPos: integer;
  OldExists: Boolean;
  NewStatement: String;
  Indent: Integer;
  MainBeginNode: TCodeTreeNode;
begin
  Result:=false;
  // search old Application.Title:= statement
  OldExists:=FindApplicationTitleStatement(StartPos,StringConstStartPos,EndPos);
  if StringConstStartPos=0 then ;
  if OldExists then begin
    // replace old statement
    Indent:=0;
    Indent:=GetLineIndent(Src,StartPos)
  end else begin
    // insert as first line in program begin..end block
    MainBeginNode:=FindMainBeginEndNode;
    if MainBeginNode=nil then exit;
    MoveCursorToNodeStart(MainBeginNode);
    ReadNextAtom;
    StartPos:=CurPos.EndPos;
    EndPos:=StartPos;
    Indent:=GetLineIndent(Src,StartPos)
            +SourceChangeCache.BeautifyCodeOptions.Indent;
  end;
  // create statement
  NewStatement:='Application.Title:='+StringToPascalConst(NewTitle)+';';
  NewStatement:=SourceChangeCache.BeautifyCodeOptions.BeautifyStatement(
    NewStatement,Indent);
  SourceChangeCache.MainScanner:=Scanner;
  if not SourceChangeCache.Replace(gtNewLine,gtNewLine,StartPos,EndPos,
                                   NewStatement)
  then
    exit;
  if not SourceChangeCache.Apply then exit;
  Result:=true;
end;

function TStandardCodeTool.RemoveApplicationTitleStatement(
  SourceChangeCache: TSourceChangeCache): boolean;
var
  StartPos, StringConstStartPos, EndPos: integer;
  OldExists: Boolean;
  FromPos: Integer;
  ToPos: Integer;
begin
  Result:=false;
  // search old Application.Title:= statement
  OldExists:=FindApplicationTitleStatement(StartPos,StringConstStartPos,EndPos);
  if not OldExists then begin
    Result:=true;
    exit;
  end;
  if StringConstStartPos=0 then ;
  // -> delete whole line
  FromPos:=FindLineEndOrCodeInFrontOfPosition(StartPos);
  ToPos:=FindLineEndOrCodeAfterPosition(EndPos);
  SourceChangeCache.MainScanner:=Scanner;
  if not SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,'') then exit;
  if not SourceChangeCache.Apply then exit;
  Result:=true;
end;

function TStandardCodeTool.RenameForm(const OldFormName,
  OldFormClassName: string; const NewFormName, NewFormClassName: string;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  IdentList: TStringList;
begin
  Result:=false;
  if (OldFormName='') or (OldFormClassName='')
  or (NewFormName='') or (NewFormClassName='')
  or (SourceChangeCache=nil) then exit;
  if (OldFormName=NewFormName)
  and (OldFormClassName=NewFormClassName) then exit;
  IdentList:=TStringList.Create;
  try
    if (OldFormName<>NewFormName) then begin
      IdentList.Add(OldFormName);
      IdentList.Add(NewFormName);
    end;
    if (OldFormClassName<>NewFormClassName) then begin
      IdentList.Add(OldFormClassName);
      IdentList.Add(NewFormClassName);
    end;
    Result:=ReplaceWords(IdentList,false,SourceChangeCache);
  finally
    IdentList.Free;
  end;
end;

function TStandardCodeTool.FindFormAncestor(const UpperClassName: string;
  var AncestorClassName: string): boolean;
var
  ClassNode: TCodeTreeNode;
begin
  Result:=false;
  AncestorClassName:='';
  if UpperClassName='' then exit;
  BuildTree(true);
  ClassNode:=FindClassNodeInInterface(UpperClassName,true,false,false);
  if (ClassNode=nil) then exit;
  // search the ancestor name
  MoveCursorToNodeStart(ClassNode);
  ReadNextAtom; // read keyword 'class', 'object', 'interface', 'dispinterface'
  if UpAtomIs('PACKED') or UpAtomIs('BITPACKED') then ReadNextAtom;
  ReadNextAtom;
  if AtomIsChar('(') then begin
    ReadNextAtom;
    if AtomIsIdentifier(false) then
      AncestorClassName:=GetAtom;
  end;
  if AncestorClassName='' then
    AncestorClassName:='TObject';
  Result:=true;
end;

{-------------------------------------------------------------------------------
  function TStandardCodeTool.ReplaceWords(IdentList: TStrings;
    ChangeStrings: boolean; SourceChangeCache: TSourceChangeCache): boolean;
    
  Search in all used sources (not only the cleaned source) for identifiers.
  It will find all identifiers, except identifiers in compiler directives.
  This includes identifiers in string constants and comments.
  
  ChangeStrings = true, means to replace in string constants too
-------------------------------------------------------------------------------}
function TStandardCodeTool.ReplaceWords(IdentList: TStrings;
  ChangeStrings: boolean; SourceChangeCache: TSourceChangeCache): boolean;
  
  procedure ReplaceWordsInSource(ACode: TCodeBuffer);
  var
    StartPos, EndPos, MaxPos, IdentStart, IdentEnd: integer;
    CurSource: string;
    i: integer;
  begin
    CurSource:=ACode.Source;
    MaxPos:=length(CurSource);
    StartPos:=1;
    // go through all source parts between compiler directives
    //DebugLn('TStandardCodeTool.ReplaceWords ',ACode.Filename);
    repeat
      EndPos:=FindNextCompilerDirective(CurSource,StartPos,
                                        Scanner.NestedComments);
      if EndPos>MaxPos then EndPos:=MaxPos+1;
      // search all identifiers
      repeat
        if ChangeStrings then
          IdentStart:=FindNextIdentifier(CurSource,StartPos,EndPos-1)
        else
          IdentStart:=FindNextIdentifierSkipStrings(CurSource,StartPos,EndPos-1);
        if IdentStart<EndPos then begin
          i:=0;
          while i<IdentList.Count do begin
            if (IdentList[i]<>'')
            and (BasicCodeTools.CompareIdentifiers(PChar(Pointer(IdentList[i])),
                                                   @CurSource[IdentStart])=0)
            and (IdentList[i]<>IdentList[i+1]) then
            begin
              // identifier found -> replace
              IdentEnd:=IdentStart+length(IdentList[i]);
              //DebugLn('TStandardCodeTool.ReplaceWords replacing: ',
              //' "',copy(CurSource,IdentStart,IdentEnd-IdentStart),'" -> "',IdentList[i+1],'" at ',IdentStart
              //);
              SourceChangeCache.ReplaceEx(gtNone,gtNone,1,1,
                ACode,IdentStart,IdentEnd,IdentList[i+1]);
              break;
            end;
            inc(i,2);
          end;
          // skip identifier
          StartPos:=IdentStart;
          while (StartPos<MaxPos) and IsIdentChar[CurSource[StartPos]] do
            inc(StartPos);
        end else begin
          break;
        end;
      until false;
      if EndPos<=MaxPos then begin
        // skip comment
        StartPos:=FindCommentEnd(CurSource,EndPos,Scanner.NestedComments);
        if StartPos>MaxPos then break;
      end else begin
        break;
      end;
    until false;
  end;
  
var
  SourceList: TFPList;
  i: integer;
begin
  Result:=false;
  if (IdentList=nil) or (IdentList.Count=0) or (SourceChangeCache=nil)
  or (Odd(IdentList.Count)) then exit;
  BuildTree(false);
  if Scanner=nil then exit;
  SourceChangeCache.MainScanner:=Scanner;
  SourceList:=TFPList.Create;
  try
    Scanner.FindCodeInRange(1,SrcLen,SourceList);
    for i:=0 to SourceList.Count-1 do begin
      ReplaceWordsInSource(TCodeBuffer(SourceList[i]));
    end;
  finally
    SourceList.Free;
  end;
  if not SourceChangeCache.Apply then exit;
  Result:=true;
end;

function TStandardCodeTool.FindNearestIdentifierNode(
  const CursorPos: TCodeXYPosition; IdentTree: TAVLTree): TAVLTreeNode;
var
  CleanCursorPos: integer;
  BestDiff: Integer;
  CurIdentNode: TAVLTreeNode;
  CurDiff: Integer;
begin
  Result:=nil;
  if IdentTree=nil then exit;
  BuildTreeAndGetCleanPos(trTillCursor,CursorPos,CleanCursorPos,[]);
  BestDiff:=SrcLen+1;
  MoveCursorToCleanPos(1);
  repeat
    ReadNextAtom;
    if AtomIsIdentifier(false) then begin
      CurIdentNode:=
        IdentTree.FindKey(@Src[CurPos.StartPos],
                          TListSortCompare(@CompareIdentifiers));
      if CurIdentNode<>nil then begin
        CurDiff:=CurPos.StartPos-CleanCursorPos;
        if CurDiff<0 then CurDiff:=-CurDiff;
        if (Result=nil) or (CurDiff<BestDiff) then begin
          BestDiff:=CurDiff;
          Result:=CurIdentNode;
        end;
      end;
    end;
  until CurPos.EndPos>SrcLen;
end;

function TStandardCodeTool.ReplaceWord(const OldWord, NewWord: string;
  ChangeStrings: boolean; SourceChangeCache: TSourceChangeCache): boolean;
var
  IdentList: TStringList;
begin
  Result:=false;
  if OldWord='' then exit;
  if OldWord=NewWord then exit(true);
  if (SourceChangeCache=nil) then exit;
  IdentList:=TStringList.Create;
  try
    IdentList.Add(OldWord);
    IdentList.Add(NewWord);
    Result:=ReplaceWords(IdentList,ChangeStrings,SourceChangeCache);
  finally
    IdentList.Free;
  end;
end;

function TStandardCodeTool.GetStringConstBounds(
  const CursorPos: TCodeXYPosition;
  out StartPos, EndPos: TCodeXYPosition; ResolveComments: boolean): boolean;
// examples:
//   's1'+'s2'#13+AFunction(...)+inherited AMethod
{ $DEFINE VerboseGetStringConstBounds}
type
  TStrConstTokenType = (scatNone, scatStrConst, scatPlus, scatIdent,
    scatInherited, scatPoint, scatUp,
    scatEdgedBracketOpen, scatEdgedBracketClose,
    scatRoundBracketOpen, scatRoundBracketClose);

{$IFDEF VerboseGetStringConstBounds}
const
  StrConstTokenTypeName: array[TStrConstTokenType] of string = (
    'scatNone', 'scatStrConst', 'scatPlus', 'scatIdent',
    'scatInherited', 'scatPoint', 'scatUp',
    'scatEdgedBracketOpen', 'scatEdgedBracketClose',
    'scatRoundBracketOpen', 'scatRoundBracketClose');
{$ENDIF}

  function GetCurrentTokenType: TStrConstTokenType;
  begin
    if AtomIsStringConstant then
      Result:=scatStrConst
    else if AtomIsChar('+') then
      Result:=scatPlus
    else if AtomIsIdentifier(false) then
      Result:=scatIdent
    else if UpAtomIs('INHERITED') then
      Result:=scatInherited
    else if CurPos.Flag=cafPoint then
      Result:=scatPoint
    else if AtomIsChar('^') then
      Result:=scatUp
    else if CurPos.Flag=cafRoundBracketOpen then
      Result:=scatRoundBracketOpen
    else if CurPos.Flag=cafRoundBracketClose then
      Result:=scatRoundBracketClose
    else if CurPos.Flag=cafEdgedBracketOpen then
      Result:=scatEdgedBracketOpen
    else if CurPos.Flag=cafEdgedBracketClose then
      Result:=scatEdgedBracketClose
    else
      Result:=scatNone;
  end;

var
  CleanCursorPos: integer;
  SameArea: TAtomPosition;
  LastToken, CurrentToken: TStrConstTokenType;
  StartCleanPos, EndCleanPos: integer;
  StringConstantFound: Boolean;
begin
  StartPos:=CursorPos;
  EndPos:=CursorPos;
  Result:=true;
  BuildTreeAndGetCleanPos(trAll,CursorPos,CleanCursorPos,[]);
  {$IFDEF VerboseGetStringConstBounds}
  DebugLn('TStandardCodeTool.GetStringConstBounds A Start at ',CleanPosToStr(CleanCursorPos),' "',copy(Src,CleanCursorPos-5,5),'" | "',copy(Src,CleanCursorPos,5),'"');
  {$ENDIF}
  GetCleanPosInfo(-1,CleanCursorPos,ResolveComments,SameArea);
  {$IFDEF VerboseGetStringConstBounds}
  DebugLn('TStandardCodeTool.GetStringConstBounds B Same Area: ',CleanPosToStr(SameArea.StartPos),'-',CleanPosToStr(SameArea.EndPos),' "',copy(Src,SameArea.StartPos,SameArea.EndPos-SameArea.StartPos),'"');
  {$ENDIF}
  if (SameArea.EndPos=SameArea.StartPos) or (SameArea.StartPos>SrcLen) then
    exit;

  // read til end of string constant
  MoveCursorToCleanPos(SameArea.StartPos);
  ReadNextAtom;
  {$IFDEF VerboseGetStringConstBounds}
  DebugLn('TStandardCodeTool.GetStringConstBounds read til end of string Atom=',GetAtom);
  {$ENDIF}
  CurrentToken:=GetCurrentTokenType;
  if (CurrentToken=scatNone) then exit;
  StringConstantFound:=(CurrentToken=scatStrConst);
  repeat
    EndCleanPos:=CurPos.EndPos;
    ReadNextAtom;
    LastToken:=CurrentToken;
    CurrentToken:=GetCurrentTokenType;
    {$IFDEF VerboseGetStringConstBounds}
    DebugLn('TStandardCodeTool.GetStringConstBounds Read Forward: ',GetAtom,' EndCleanPos=',dbgs(EndCleanPos),
    ' LastToken=',StrConstTokenTypeName[LastToken],
    ' CurrentToken=',StrConstTokenTypeName[CurrentToken],
    ' ',StrConstTokenTypeName[GetCurrentTokenType]);
    {$ENDIF}
    case CurrentToken of
    scatNone, scatEdgedBracketClose, scatRoundBracketClose:
      if not (LastToken in [scatStrConst,scatIdent,scatUp,
         scatEdgedBracketClose, scatRoundBracketClose])
      then
        exit
      else
        break;

    scatStrConst:
      if not (LastToken in [scatPlus]) then
        exit
      else
        StringConstantFound:=true;
      
    scatPlus:
      if not (LastToken in [scatStrConst, scatIdent, scatUp,
        scatEdgedBracketClose, scatRoundBracketClose]) then exit;

    scatIdent:
      if not (LastToken in [scatPlus, scatPoint, scatInherited]) then exit;

    scatInherited:
      if not (LastToken in [scatPlus, scatPoint]) then exit;

    scatPoint:
      if not (LastToken in [scatIdent, scatUp, scatRoundBracketClose,
                            scatEdgedBracketClose]) then
        exit;

    scatEdgedBracketOpen,scatRoundBracketOpen:
      if not (LastToken in [scatIdent, scatUp]) then
        exit
      else begin
        ReadTilBracketClose(true);
        CurrentToken:=GetCurrentTokenType;
      end;
      
    end;
  until false;

  // read til start of string constant
  MoveCursorToCleanPos(SameArea.StartPos);
  ReadNextAtom;
  {$IFDEF VerboseGetStringConstBounds}
  DebugLn('TStandardCodeTool.GetStringConstBounds Read til start of string ',GetAtom);
  {$ENDIF}
  CurrentToken:=GetCurrentTokenType;
  repeat
    StartCleanPos:=CurPos.StartPos;
    ReadPriorAtom;
    {$IFDEF VerboseGetStringConstBounds}
    DebugLn('TStandardCodeTool.GetStringConstBounds Read backward: ',GetAtom,' StartCleanPos=',dbgs(StartCleanPos));
    {$ENDIF}
    LastToken:=CurrentToken;
    CurrentToken:=GetCurrentTokenType;
    case CurrentToken of
    scatNone, scatEdgedBracketOpen, scatRoundBracketOpen:
      if not (LastToken in [scatStrConst,scatIdent,scatPlus]) then
        exit
      else
        break;

    scatStrConst:
      if not (LastToken in [scatPlus]) then
        exit
      else
        StringConstantFound:=true;

    scatPlus:
      if not (LastToken in [scatStrConst, scatIdent, scatRoundBracketOpen]) then
        exit;

    scatIdent:
      if not (LastToken in [scatPlus, scatPoint, scatUp, scatRoundBracketOpen,
        scatEdgedBracketOpen]) then exit;

    scatInherited:
      if not (LastToken in [scatIdent]) then exit;

    scatPoint:
      if not (LastToken in [scatIdent]) then exit;

    scatEdgedBracketClose,scatRoundBracketClose:
      if not (LastToken in [scatPlus, scatUp, scatPoint]) then
        exit
      else begin
        ReadBackTilBracketOpen(true);
        CurrentToken:=GetCurrentTokenType;
      end;

    end;
  until false;
  
  // convert start and end position
  {$IFDEF VerboseGetStringConstBounds}
  DebugLn('TStandardCodeTool.GetStringConstBounds END "',copy(Src,StartCleanPos,EndCleanPos-StartCleanPos),'" StringConstantFound=',dbgs(StringConstantFound));
  {$ENDIF}
  if not StringConstantFound then begin
    EndCleanPos:=StartCleanPos;
  end;
  if not CleanPosToCaret(StartCleanPos,StartPos) then exit;
  if not CleanPosToCaret(EndCleanPos,EndPos) then exit;

  Result:=true;
end;

function TStandardCodeTool.ReplaceCode(const StartPos, EndPos: TCodeXYPosition;
  const NewCode: string; SourceChangeCache: TSourceChangeCache): boolean;
begin
  Result:=false;
  RaiseException('TStandardCodeTool.ReplaceCode not implemented yet');
end;

function TStandardCodeTool.GetStringConstAsFormatString(StartPos,
  EndPos: integer; out FormatStringConstant, FormatParameters: string;
  out StartInStringConst, EndInStringConst: boolean): boolean;
{ Converts a string constant into the parameters for a Format call of the
  system unit.

  Examples:

  'Hallo'           -> "Hallo", ""
  'A'+IntToStr(1)   -> "A%s", "IntToStr(1)"
  'A%B'#13#10       -> "A%sB%s", "'%', #13#10"
}
  procedure AddChar(c: char);
  begin
    FormatStringConstant:=FormatStringConstant+c;
  end;

  procedure AddParameter(const NewParam: string);
  begin
    FormatStringConstant:=FormatStringConstant+'%s';
    if FormatParameters<>'' then
      FormatParameters:=FormatParameters+',';
    FormatParameters:=FormatParameters+NewParam;
  end;

  procedure AddParameter(ParamStartPos,ParamEndPos: integer);
  begin
    AddParameter(copy(Src,ParamStartPos,ParamEndPos-ParamStartPos));
  end;

  procedure ConvertStringConstant;
  var
    APos: Integer;
    CharConstStart: Integer;
    InRange: Boolean;
  begin
    if (CurPos.StartPos<StartPos) and (CurPos.EndPos>StartPos) then
      StartInStringConst:=true;
    if (CurPos.StartPos<EndPos) and (CurPos.EndPos>EndPos) then
      EndInStringConst:=true;

    APos:=CurPos.StartPos;
    while APos<EndPos do begin
      InRange:=(APos>=StartPos);
      //debugln('ConvertStringConstant InRange=',dbgs(InRange),' Src[APos]=',Src[APos]);
      if Src[APos]='''' then begin
        // read string constant
        inc(APos);
        while APos<EndPos do begin
          InRange:=(APos>=StartPos);
          case Src[APos] of
          '''':
            if (APos<EndPos-1) and (Src[APos+1]='''') then begin
              // a double ' means a single '
              if InRange then begin
                AddChar('''');
                AddChar('''');
              end;
              inc(APos,2);
            end else begin
              // a single ' means end of string constant
              inc(APos);
              break;
            end;
          '"':
            begin
              if InRange then
                AddParameter('''"''');
              inc(APos);
            end;
          else
            begin
              // normal char
              if InRange then
                AddChar(Src[APos]);
              inc(APos);
            end;
          end;
        end;
      end else if Src[APos]='#' then begin
        CharConstStart:=APos;
        InRange:=(APos+1>=StartPos);
        repeat
          // read char constant
          inc(APos);
          if APos<EndPos then begin
            if IsNumberChar[Src[APos]] then begin
              // read decimal number
              while (APos<EndPos) and IsNumberChar[Src[APos]] do
                inc(APos);
            end else if Src[APos]='$' then begin
              // read hexnumber
              while (APos<EndPos) and IsHexNumberChar[Src[APos]] do
                inc(APos);
            end;
          end;
        until (APos>=EndPos) or (Src[APos]<>'#');
        if InRange then
          AddParameter(CharConstStart,APos);
      end else
        break;
    end;
  end;

  procedure ConvertOther;
  var
    ParamStartPos: Integer;
    ParamEndPos: Integer;
  begin
    // read till next string constant
    ParamStartPos:=CurPos.StartPos;
    ParamEndPos:=ParamStartPos;
    while (not AtomIsStringConstant) and (CurPos.EndPos<=EndPos) do begin
      if CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen] then
        ReadTilBracketClose(true);
      if not AtomIsChar('+') then ParamEndPos:=CurPos.EndPos;
      ReadNextAtom;
    end;
    if ParamEndPos>ParamStartPos then
      AddParameter(ParamStartPos,ParamEndPos);
    if AtomIsStringConstant then UndoReadNextAtom;
  end;

var
  ANode: TCodeTreeNode;
  CodePosInFront: LongInt;
begin
  Result:=false;
  // read string constants and convert it
  FormatStringConstant:='';
  FormatParameters:='';
  StartInStringConst:=false;
  EndInStringConst:=false;
  ANode:=FindDeepestNodeAtPos(StartPos,True);
  CodePosInFront:=ANode.StartPos;
  MoveCursorToCleanPos(CodePosInFront);
  if EndPos>SrcLen then EndPos:=SrcLen+1;
  repeat
    ReadNextAtom;
    //debugln('GetStringConstAsFormatString Atom=',GetAtom);
    if (CurPos.StartPos>=EndPos) then break;
    if CurPos.EndPos>StartPos then begin
      //debugln('GetStringConstAsFormatString Parsing...');
      if AtomIsStringConstant then begin
        // a string constant
        ConvertStringConstant;
      end else if AtomIsChar('+') then begin
        // simply ignore
      end else if (CurPos.Flag=cafRoundBracketOpen) or AtomIsIdentifier(false)
      then begin
        // add as parameter
        ConvertOther;
      end else
        // string constant end
        break;
    end;
  until false;
  Result:=FormatStringConstant<>'';
end;

function TStandardCodeTool.GetStringConstAsFormatString(StartPos,
  EndPos: integer; out FormatStringConstant, FormatParameters: string
    ): boolean;
var
  StartInStringConst, EndInStringConstant: boolean;
begin
  Result:=GetStringConstAsFormatString(StartPos,EndPos,FormatStringConstant,
                       FormatParameters,StartInStringConst,EndInStringConstant);
  if StartInStringConst then ;
  if EndInStringConstant then ;
end;

function TStandardCodeTool.GatherResourceStringSections(
  const CursorPos: TCodeXYPosition; PositionList: TCodeXYPositions): boolean;
  
  function SearchInUsesSection(UsesNode: TCodeTreeNode): boolean;
  var
    InAtom, UnitNameAtom: TAtomPosition;
    NewCodeTool: TPascalReaderTool;
    ANode: TCodeTreeNode;
    NewCaret: TCodeXYPosition;
  begin
    Result:=false;
    MoveCursorToUsesEnd(UsesNode);
    repeat
      ReadPriorUsedUnit(UnitNameAtom, InAtom);
      //DebugLn('TStandardCodeTool.GatherResourceStringSections Uses ',GetAtom(UnitNameAtom));
      // open the unit
      NewCodeTool:=OpenCodeToolForUnit(UnitNameAtom,InAtom,false);
      if NewCodeTool=nil then begin
        MoveCursorToAtomPos(UnitNameAtom);
        RaiseException(Format(ctsSourceOfUnitNotFound, [GetAtom]));
      end;
      NewCodeTool.BuildTree(true);
      // search all resource string sections in the interface
      ANode:=NewCodeTool.FindInterfaceNode;
      if (ANode<>nil) and (ANode.LastChild<>nil) then begin
        ANode:=ANode.LastChild;
        while ANode<>nil do begin
          if ANode.Desc=ctnResStrSection then begin
            if not NewCodeTool.CleanPosToCaret(ANode.StartPos,NewCaret) then
              break;
            //DebugLn('TStandardCodeTool.GatherResourceStringSections Found Other ',NewCodeTool.MainFilename,' Y=',NewCaret.Y);
            PositionList.Add(NewCaret);
          end;
          ANode:=ANode.PriorBrother;
        end;
      end;
      // restore the cursor
      MoveCursorToCleanPos(UnitNameAtom.StartPos);
      ReadPriorAtom; // read keyword 'uses' or comma
      //DebugLn('TStandardCodeTool.GatherResourceStringSections Uses B ',GetAtom);
    until not AtomIsChar(',');
    Result:=true;
  end;
  
var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
  NewCaret: TCodeXYPosition;
  ANode: TCodeTreeNode;
begin
  Result:=false;
  //DebugLn('TStandardCodeTool.GatherResourceStringSections A ');
  BuildTreeAndGetCleanPos(trAll,CursorPos,CleanCursorPos,[]);
  CursorNode:=FindDeepestNodeAtPos(CleanCursorPos,true);
  PositionList.Clear;
  ANode:=CursorNode;
  while ANode<>nil do begin
    case ANode.Desc of
    
    ctnResStrSection:
      begin
        if not CleanPosToCaret(ANode.StartPos,NewCaret) then exit;
        //DebugLn('TStandardCodeTool.GatherResourceStringSections Found Same Y=',NewCaret.Y);
        PositionList.Add(NewCaret);
      end;
      
    ctnUsesSection:
      if not SearchInUsesSection(ANode) then break;
      
    end;
    
    // go to next node
    if ANode.PriorBrother<>nil then begin
      ANode:=ANode.PriorBrother;
      if (ANode.Desc=ctnInterface) and (ANode.LastChild<>nil) then
        ANode:=ANode.LastChild;
    end else begin
      ANode:=ANode.Parent;
    end;
  end;
  Result:=true;
end;

function TStandardCodeTool.IdentifierExistsInResourceStringSection(
  const CursorPos: TCodeXYPosition; const ResStrIdentifier: string): boolean;
var
  CleanCursorPos: integer;
  ANode: TCodeTreeNode;
begin
  Result:=false;
  if ResStrIdentifier='' then exit;
  // parse source and find clean positions
  BuildTreeAndGetCleanPos(trAll,CursorPos,CleanCursorPos,[]);
  // find resource string section
  ANode:=FindDeepestNodeAtPos(CleanCursorPos,true);
  if (ANode=nil) then exit;
  ANode:=ANode.GetNodeOfType(ctnResStrSection);
  if ANode=nil then exit;
  // search identifier in section
  ANode:=ANode.FirstChild;
  while ANode<>nil do begin
    if (ANode.Desc=ctnConstDefinition)
    and CompareSrcIdentifier(ANode.StartPos,ResStrIdentifier) then begin
      Result:=true;
      exit;
    end;
    ANode:=ANode.NextBrother;
  end;
end;

function TStandardCodeTool.CreateIdentifierFromStringConst(const StartCursorPos,
  EndCursorPos: TCodeXYPosition; out Identifier: string;
  MaxLen: integer): boolean;
var
  StartPos, EndPos: integer;
  Dummy: Integer;
  IdentStr: String;
  ANode: TCodeTreeNode;
  CodePosInFront: LongInt;
begin
  Result:=false;
  if MaxLen<=0 then exit;
  // parse source and find clean positions
  BuildTreeAndGetCleanPos(trAll,StartCursorPos,StartPos,[]);
  Dummy:=CaretToCleanPos(EndCursorPos, EndPos);
  if (Dummy<>0) and (Dummy<>-1) then exit;
  ANode:=FindDeepestNodeAtPos(StartPos,True);
  CodePosInFront:=ANode.StartPos;
  // read string constants and extract identifier characters
  Identifier:='';
  MoveCursorToCleanPos(CodePosInFront);
  repeat
    ReadNextAtom;
    //debugln('TStandardCodeTool.CreateIdentifierFromStringConst Atom=',GetAtom);
    if (CurPos.StartPos>=EndPos) then break;
    if AtomIsStringConstant then begin
      IdentStr:=ExtractIdentCharsFromStringConstant(CurPos.StartPos,
                                     StartPos,EndPos,MaxLen-length(Identifier));
      //debugln('TStandardCodeTool.CreateIdentifierFromStringConst IdentStr=',IdentStr);
      if (IdentStr<>'') then begin
        IdentStr[1]:=UpChars[IdentStr[1]];
        Identifier:=Identifier+IdentStr;
      end;
    end;
  until length(Identifier)>=MaxLen;
  Result:=Identifier<>'';
end;

function TStandardCodeTool.StringConstToFormatString(const StartCursorPos,
  EndCursorPos: TCodeXYPosition;
  out FormatStringConstant, FormatParameters: string;
  out StartInStringConst, EndInStringConst: boolean): boolean;
var
  StartPos,EndPos,Dummy: Integer;
begin
  Result:=false;
  // parse source and find clean positions
  BuildTreeAndGetCleanPos(trAll,StartCursorPos,StartPos,[]);
  Dummy:=CaretToCleanPos(EndCursorPos, EndPos);
  if (Dummy<>0) and (Dummy<>-1) then exit;
  Result:=GetStringConstAsFormatString(StartPos,EndPos,FormatStringConstant,
                       FormatParameters,StartInStringConst,EndInStringConst);
end;

function TStandardCodeTool.HasInterfaceRegisterProc(var HasRegisterProc: boolean
  ): boolean;
var
  InterfaceNode: TCodeTreeNode;
  ANode: TCodeTreeNode;
begin
  Result:=false;
  HasRegisterProc:=false;
  BuildTree(true);
  InterfaceNode:=FindInterfaceNode;
  if InterfaceNode=nil then exit;
  ANode:=InterfaceNode.FirstChild;
  while ANode<>nil do begin
    if (ANode.Desc=ctnProcedure) then begin
      MoveCursorToNodeStart(ANode);
      if ReadNextUpAtomIs('PROCEDURE')
      and ReadNextUpAtomIs('REGISTER')
      and ReadNextAtomIsChar(';')
      then begin
        HasRegisterProc:=true;
        break;
      end;
    end;
    ANode:=ANode.NextBrother;
  end;
  Result:=true;
end;

function TStandardCodeTool.ConvertDelphiToLazarusSource(AddLRSCode: boolean;
  SourceChangeCache: TSourceChangeCache): boolean;

  function AddModeDelphiDirective: boolean;
  var
    ModeDirectivePos: integer;
    InsertPos: Integer;
  begin
    Result:=false;
    BuildTree(true);
    if not FindModeDirective(false,ModeDirectivePos) then begin
      // add {$MODE Delphi} behind source type
      if Tree.Root=nil then exit;
      MoveCursorToNodeStart(Tree.Root);
      ReadNextAtom; // 'unit', 'program', ..
      ReadNextAtom; // name
      ReadNextAtom; // semicolon
      InsertPos:=CurPos.EndPos;
      SourceChangeCache.Replace(gtEmptyLine,gtEmptyLine,InsertPos,InsertPos,
        '{$MODE Delphi}');
      if not SourceChangeCache.Apply then exit;
    end;
    // changing mode requires rescan
    BuildTree(false);
    Result:=true;
  end;

  function ConvertUsedUnits: boolean;
  // replace unit 'Windows' with 'LCLIntf' and add 'LResources'
  // rename 'in' filenames to case sensitive filename
  var
    NamePos, InPos: TAtomPosition;
  begin
    Result:=false;
    if FindUnitInAllUsesSections('WINDOWS',NamePos,InPos)
    and (InPos.StartPos<1) then begin
      if not SourceChangeCache.Replace(gtNone,gtNone,
                           NamePos.StartPos,NamePos.EndPos,'LCLIntf') then
      begin
        debugln('ConvertUsedUnits Unable to replace Windows with LCLIntf unit');
        exit;
      end;
    end;
    if AddLRSCode then
      if not AddUnitToMainUsesSection('LResources','',SourceChangeCache) then
      begin
        debugln('ConvertUsedUnits Unable to add LResources to main uses section');
        exit;
      end;
    if not RemoveUnitFromAllUsesSections('VARIANTS',SourceChangeCache) then
    begin
      debugln('ConvertUsedUnits Unable to remove Variants from all uses sections');
      exit;
    end;
    if not FixUsedUnitCase(SourceChangeCache) then
    begin
      debugln('ConvertUsedUnits Unable to fix unit filename case sensitivity in all uses sections');
      exit;
    end;
    Result:=true;
  end;

  function RemoveDFMResourceDirective: boolean;
  // remove {$R *.dfm} or {$R *.xfm} directive
  var
    ParamPos: Integer;
    ACleanPos: Integer;
    StartPos: Integer;
  begin
    Result:=false;
    // find $R directive
    ACleanPos:=1;
    repeat
      ACleanPos:=FindNextCompilerDirectiveWithName(Src,ACleanPos,'R',
        Scanner.NestedComments,ParamPos);
      if (ACleanPos<1) or (ACleanPos>SrcLen) or (ParamPos>SrcLen) then break;
      if (Src[ACleanPos]='{')
      and ((copy(UpperSrc,ParamPos,6)='*.DFM}')
        or (copy(UpperSrc,ParamPos,6)='*.XFM}'))
      then begin
        StartPos:=FindLineEndOrCodeInFrontOfPosition(ACleanPos,true);
        if not SourceChangeCache.Replace(gtNone,gtNone,StartPos,ParamPos+6,'')
        then exit;
        break;
      end;
      ACleanPos:=FindCommentEnd(Src,ACleanPos,Scanner.NestedComments);
    until false;
    Result:=true;
  end;

  function AddLRSIncludeDirective: boolean;
  // add initialization and {$i unit.lrs} include directive
  var
    FirstInclude: TCodeBuffer;
    LRSFilename: String;
    InitializationNode: TCodeTreeNode;
    ImplementationNode: TCodeTreeNode;
    NewCode: String;
    InsertPos: Integer;
    LinkIndex: Integer;
  begin
    Result:=false;
    if AddLRSCode then begin
      LRSFilename:=ExtractFilenameOnly(MainFilename)+'.lrs';
      LinkIndex:=-1;
      FirstInclude:=FindNextIncludeInInitialization(LinkIndex);
      if (FirstInclude<>nil)
      and (CompareFilenames(FirstInclude.Filename,LRSFilename)=0) then begin
        // already there
        Result:=true;
        exit;
      end;
      if Tree.Root.Desc=ctnUnit then begin
        InitializationNode:=FindInitializationNode;
        NewCode:=GetIndentStr(SourceChangeCache.BeautifyCodeOptions.Indent)
                 +'{$i '+LRSFilename+'}';
        if InitializationNode=nil then begin
          // add also an initialization section
          ImplementationNode:=FindImplementationNode;
          InsertPos:=ImplementationNode.EndPos;
          NewCode:=SourceChangeCache.BeautifyCodeOptions.BeautifyKeyWord(
                     'initialization')
                   +SourceChangeCache.BeautifyCodeOptions.LineEnd
                   +NewCode;
          if not SourceChangeCache.Replace(gtEmptyLine,gtEmptyLine,
                                           InsertPos,InsertPos,
                                           NewCode) then exit;
        end else begin
          InsertPos:=InitializationNode.StartPos+length('initialization');
          if not SourceChangeCache.Replace(gtNewLine,gtNewLine,
                                           InsertPos,InsertPos,
                                           NewCode) then exit;
        end;
      end else begin
        // only Units supported yet
        exit;
      end;
    end;
    Result:=true;
  end;

begin
  Result:=false;
  if SourceChangeCache=nil then exit;
  SourceChangeCache.MainScanner:=Scanner;
  SourceChangeCache.BeginUpdate;
  try
    DebugLn('ConvertDelphiToLazarusSource AddModeDelphiDirective');
    if not AddModeDelphiDirective then exit;
    DebugLn('ConvertDelphiToLazarusSource RemoveDFMResourceDirective');
    if not RemoveDFMResourceDirective then exit;
    DebugLn('ConvertDelphiToLazarusSource AddLRSIncludeDirective');
    if not AddLRSIncludeDirective then exit;
    DebugLn('ConvertDelphiToLazarusSource ConvertUsedUnits');
    if not ConvertUsedUnits then exit;
    DebugLn('ConvertDelphiToLazarusSource Apply');
    if not SourceChangeCache.Apply then exit;
  finally
    SourceChangeCache.EndUpdate;
  end;
  DebugLn('ConvertDelphiToLazarusSource END');
  Result:=true;
end;

function TStandardCodeTool.GetIDEDirectives(DirectiveList: TStrings): boolean;
var
  StartPos: Integer;
  EndPos: Integer;
begin
  Result:=false;
  DirectiveList.Clear;
  BuildTree(true);
  EndPos:=1;
  repeat
    StartPos:=FindNextIDEDirective(Src,EndPos,Scanner.NestedComments);
    if StartPos<1 then break;
    EndPos:=FindCommentEnd(Src,StartPos,Scanner.NestedComments);
    DirectiveList.Add(copy(Src,StartPos,EndPos-StartPos));
    if EndPos>SrcLen then break;
    StartPos:=EndPos;
  until false;
  Result:=true;
end;

function TStandardCodeTool.SetIDEDirectives(DirectiveList: TStrings;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  InsertPos: Integer;
  EndPos: Integer;
  StartPos: Integer;
  InsertTxt: String;
  ImplementationNode: TCodeTreeNode;
begin
  Result:=false;
  if SourceChangeCache=nil then exit;
  SourceChangeCache.MainScanner:=Scanner;
  BuildTree(false);

  // find first old IDE directive
  InsertPos:=FindNextIDEDirective(Src,1,Scanner.NestedComments);
  if InsertPos<1 then InsertPos:=0;

  // remove all old IDE directives
  if InsertPos>=1 then
    EndPos:=InsertPos
  else
    EndPos:=1;
  repeat
    // find next IDE directive
    StartPos:=FindNextIDEDirective(Src,EndPos,Scanner.NestedComments);
    if StartPos<1 then break;
    EndPos:=FindCommentEnd(Src,StartPos,Scanner.NestedComments);
    // remove also space in front of directive
    while (StartPos>1) and (Src[StartPos-1] in [' ',#9]) do dec(StartPos);
    // remove also space behind directive
    while (EndPos<=SrcLen) and (Src[EndPos] in [' ',#9]) do inc(EndPos);
    if (EndPos<=SrcLen) and (Src[EndPos] in [#10,#13]) then begin
      inc(EndPos);
      if (EndPos<=SrcLen) and (Src[EndPos] in [#10,#13])
      and (Src[EndPos]<>Src[EndPos-1]) then
        inc(EndPos);
    end;
    // remove directive
    SourceChangeCache.Replace(gtNone,gtNone,StartPos,EndPos,'');
    if EndPos>SrcLen then break;
    StartPos:=EndPos;
  until false;
  
  // find a nice insert position
  ImplementationNode:=FindImplementationNode;
  if (ImplementationNode<>nil)
  and (ImplementationNode.StartPos<=InsertPos) then
    InsertPos:=0;
  if InsertPos<1 then begin
    // set default insert position
    InsertPos:=1;
    if (Tree<>nil) and (Tree.Root<>nil) then
      InsertPos:=Tree.Root.StartPos;
  end;
  
  // add directives
  InsertTxt:=ChompLineEndsAtEnd(DirectiveList.Text);
  if not SourceChangeCache.Replace(gtNewLine,gtNewLine,InsertPos,InsertPos,
                            InsertTxt) then exit;
  if not SourceChangeCache.Apply then exit;

  Result:=true;
end;

function TStandardCodeTool.FindCommentInFront(const StartPos: TCodeXYPosition;
  const CommentText: string;
  InvokeBuildTree, SearchInParentNode, WithCommentBounds, CaseSensitive,
  IgnoreSpaces, CompareOnlyStart: boolean;
  out CommentStart, CommentEnd: TCodeXYPosition): boolean;
// searches a comment in front.
var
  FoundStartPos: integer;
  FoundEndPos: integer;

  procedure CompareComment(CStartPos, CEndPos: integer);
  var
    Found: LongInt;
    CompareStartPos: LongInt;
    CompareEndPos: LongInt;
    CompareLen: Integer;
    CompareCommentLength: Integer;
  begin
    //debugln('CompareComment "',copy(Src,CStartPos,CEndPos-CStartPos),'"');

    CompareStartPos:=CStartPos;
    CompareEndPos:=CEndPos;
    if not WithCommentBounds then begin
      // chomp comment boundaries
      case Src[CompareStartPos] of
      '/','(': inc(CompareStartPos,2);
      '{': inc(CompareStartPos,1);
      end;
      case Src[CompareEndPos-1] of
      '}': dec(CompareEndPos);
      ')': dec(CompareEndPos,2);
      #10,#13:
        begin
          dec(CompareEndPos);
          if (Src[CompareEndPos-1] in [#10,#13])
          and (Src[CompareEndPos-1]<>Src[CompareEndPos]) then
            dec(CompareEndPos);
        end;
      end;
    end;
    if IgnoreSpaces then begin
      while (CompareStartPos<=CompareEndPos)
      and IsSpaceChar[Src[CompareStartPos]]
      do
        inc(CompareStartPos);
    end;

    CompareCommentLength:=length(CommentText);
    CompareLen:=CompareEndPos-CompareStartPos;
    if CompareOnlyStart and (CompareLen>CompareCommentLength) then
      CompareLen:=CompareCommentLength;

    //debugln('Compare: "',copy(Src,CompareStartPos,CompareEndPos-CompareStartPos),'"',
    //  ' "',CommentText,'"');
    if IgnoreSpaces then begin
      Found:=CompareTextIgnoringSpace(
                          @Src[CompareStartPos],CompareLen,
                          @CommentText[1],length(CommentText),
                          CaseSensitive);
    end else begin
      Found:=CompareText(@Src[CompareStartPos],CompareLen,
                         @CommentText[1],length(CommentText),
                         CaseSensitive);
    end;
    if Found=0 then begin
      FoundStartPos:=CStartPos;
      FoundEndPos:=CEndPos;
    end;
  end;

var
  CleanCursorPos: integer;
  ANode: TCodeTreeNode;
  p: LongInt;
  CommentLvl: Integer;
  CommentStartPos: LongInt;
begin
  Result:=false;
  if CommentText='' then exit;

  {debugln('TStandardCodeTool.FindCommentInFront A CommentText="',CommentText,'" ',
    ' StartPos=Y='+dbgs(StartPos.Y)+',X='+dbgs(StartPos.X),
    ' InvokeBuildTree='+dbgs(InvokeBuildTree),
    ' SearchInParentNode='+dbgs(SearchInParentNode),
    ' WithCommentBounds='+dbgs(WithCommentBounds),
    ' CaseSensitive='+dbgs(CaseSensitive),
    ' IgnoreSpaces='+dbgs(IgnoreSpaces),
    ' CompareOnlyStart='+dbgs(CompareOnlyStart)); }

  // parse source and find clean positions
  if InvokeBuildTree then
    BuildTreeAndGetCleanPos(trAll,StartPos,CleanCursorPos,[])
  else
    if CaretToCleanPos(StartPos,CleanCursorPos)<>0 then
      exit;

  // find node
  ANode:=FindDeepestNodeAtPos(CleanCursorPos,true);
  if (ANode=nil) then exit;

  { find end of last atom in front of node
    for example:
      uses classes;

      // Comment
      type

    If ANode is the 'type' block, the position after the semicolon is searched
  }

  if SearchInParentNode and (ANode.Parent<>nil) then begin
    // search all siblings in front
    ANode:=ANode.Parent;
    MoveCursorToCleanPos(ANode.Parent.StartPos);
  end else if ANode.PriorBrother<>nil then begin
    // search between prior sibling and this node
    //DebugLn('TStandardCodeTool.FindCommentInFront ANode.Prior=',ANode.Prior.DescAsString);
    MoveCursorToLastNodeAtom(ANode.PriorBrother);
  end else if ANode.Parent<>nil then begin
    // search from start of parent node to this node
    //DebugLn('TStandardCodeTool.FindCommentInFront ANode.Parent=',ANode.Parent.DescAsString);
    MoveCursorToCleanPos(ANode.Parent.StartPos);
  end else begin
    // search in this node
    //DebugLn('TStandardCodeTool.FindCommentInFront Aode=',ANode.DescAsString);
    MoveCursorToCleanPos(ANode.StartPos);
  end;

  //debugln('TStandardCodeTool.FindCommentInFront B Area="',copy(Src,CurPos.StartPos,CleanCursorPos-CurPos.StartPos),'"');

  FoundStartPos:=-1;
  repeat
    p:=CurPos.EndPos;
    //debugln('TStandardCodeTool.FindCommentInFront Atom=',GetAtom);

    // read space and comment till next atom
    CommentLvl:=0;
    while true do begin
      case Src[p] of
      #0:
        if p>SrcLen then
          break
        else
          inc(p);
      #1..#32:
        inc(p);
      '{': // pascal comment
        begin
          CommentLvl:=1;
          CommentStartPos:=p;
          inc(p);
          while true do begin
            case Src[p] of
            #0:  if p>SrcLen then break;
            '{': if Scanner.NestedComments then inc(CommentLvl);
            '}':
              begin
                dec(CommentLvl);
                if CommentLvl=0 then break;
              end;
            end;
            inc(p);
          end;
          inc(p);
          CompareComment(CommentStartPos,p);
        end;
      '/':  // Delphi comment
        if (Src[p+1]<>'/') then begin
          break;
        end else begin
          CommentStartPos:=p;
          inc(p,2);
          while (not (Src[p] in [#10,#13,#0])) do
            inc(p);
          inc(p);
          if (p<=SrcLen) and (Src[p] in [#10,#13])
          and (Src[p-1]<>Src[p]) then
            inc(p);
          CompareComment(CommentStartPos,p);
        end;
      '(': // old turbo pascal comment
        if (Src[p+1]<>'*') then begin
          break;
        end else begin
          CommentStartPos:=p;
          inc(p,3);
          while (p<=SrcLen)
          and ((Src[p-1]<>'*') or (Src[p]<>')')) do
            inc(p);
          inc(p);
          CompareComment(CommentStartPos,p);
        end;
      else
        break;
      end;
    end;
    ReadNextAtom;
    //DebugLn('TStandardCodeTool.FindCommentInFront NextAtom=',GetAtom);
  until (CurPos.EndPos>=CleanCursorPos) or (CurPos.EndPos>=SrcLen);
  
  Result:=(FoundStartPos>=1)
          and CleanPosToCaret(FoundStartPos,CommentStart)
          and CleanPosToCaret(FoundEndPos,CommentEnd);
end;

function TStandardCodeTool.CommentCode(const StartPos, EndPos: integer;
  SourceChangeCache: TSourceChangeCache; Apply: boolean): boolean;
var
  i: LongInt;
  CurStartPos: LongInt;
  CommentNeeded: Boolean;
  CurEndPos: LongInt;
begin
  if StartPos>=EndPos then
    RaiseException('TStandardCodeTool CommentCode');

  Result:=false;
  // comment with curly brackets {}
  i:=StartPos;
  CurStartPos:=i;
  CurEndPos:=CurStartPos;
  CommentNeeded:=false;
  repeat
    if (Src[i]='{') or (i>=EndPos) then begin
      // the area contains a comment -> comment in front
      if CommentNeeded then begin
        if not SourceChangeCache.Replace(gtNone,gtNone,
          CurStartPos,CurStartPos,'{') then exit;
        if not SourceChangeCache.Replace(gtNone,gtNone,
          CurEndPos,CurEndPos,'}') then exit;
        //DebugLn('Comment "',copy(Src,CurStartPos,i-CurStartPos),'"');
        CommentNeeded:=false;
      end;
      if i>=EndPos then break;
      // skip comment
      i:=FindCommentEnd(Src,i,Scanner.NestedComments);
    end else if not IsSpaceChar[Src[i]] then begin
      if not CommentNeeded then begin
        CurStartPos:=i;
        CommentNeeded:=true;
      end;
      CurEndPos:=i+1;
    end;
    inc(i);
  until false;
  if Apply then
    Result:=SourceChangeCache.Apply
  else
    Result:=true;
end;

function TStandardCodeTool.GetPasDocComments(const StartPos: TCodeXYPosition;
  InvokeBuildTree: boolean; out ListOfPCodeXYPosition: TFPList): boolean;
// Comments are normally in front.
// { Description of TMyClass. }
//  TMyClass = class
//
// Comments can be behind in the same line
// property Color; // description of Color
//
// Comments can be in the following line if started with <

  function CommentBelongsToPrior(CommentStart: integer): boolean;
  var
    p: Integer;
  begin
    if (CommentStart<SrcLen) and (Src[CommentStart]='{')
    and (Src[CommentStart+1]='<') then
      Result:=true
    else if (CommentStart+2<=SrcLen) and (Src[CommentStart]='(')
    and (Src[CommentStart+1]='*') and (Src[CommentStart+2]='<') then
      Result:=true
    else if (CommentStart+2<=SrcLen) and (Src[CommentStart]='/')
    and (Src[CommentStart+1]='/') and (Src[CommentStart+2]='<') then
      Result:=true
    else begin
      p:=CommentStart-1;
      while (p>=1) and (Src[p] in [' ',#9]) do dec(p);
      if (p<1) or (Src[p] in [#10,#13]) then
        Result:=false
      else
        Result:=true; // there is code in the same line in front of the comment
    end;
  end;
  
  procedure Add(CleanPos: integer);
  var
    CodePos: TCodeXYPosition;
  begin
    if not CleanPosToCaret(CleanPos,CodePos) then exit;
    AddCodePosition(ListOfPCodeXYPosition,CodePos);
  end;

  function Scan(StartPos, EndPos: integer): boolean;
  var
    p: LongInt;
  begin
    // read comments (start in front of node)
    //DebugLn(['TStandardCodeTool.GetPasDocComments Scan Src=',copy(Src,StartPos,EndPos-StartPos)]);
    p:=FindLineEndOrCodeInFrontOfPosition(StartPos,true);
    while p<EndPos do begin
      p:=FindNextComment(Src,p,EndPos);
      if p>=EndPos then break;
      //debugln(['TStandardCodeTool.GetPasDocComments Comment="',copy(Src,p,FindCommentEnd(Src,p,Scanner.NestedComments)-p),'"']);
      if (p<StartPos) then begin
        // comment in front of node
        if not CommentBelongsToPrior(p) then
          Add(p);
      end else if (p<EndPos) then begin
        // comment in the middle
        Add(p);
      end else begin
        // comment behind
        if CommentBelongsToPrior(p) then
          Add(p);
      end;
      p:=FindCommentEnd(Src,p,Scanner.NestedComments);
    end;
    Result:=true;
  end;

var
  CleanCursorPos: integer;
  ANode: TCodeTreeNode;
  NextNode: TCodeTreeNode;
  EndPos: LongInt;
  TypeNode: TCodeTreeNode;
begin
  ListOfPCodeXYPosition:=nil;
  Result:=false;
  
  // parse source and find clean positions
  if InvokeBuildTree then
    BuildTreeAndGetCleanPos(trAll,StartPos,CleanCursorPos,[])
  else
    if CaretToCleanPos(StartPos,CleanCursorPos)<>0 then
      exit;

  // find node
  ANode:=FindDeepestNodeAtPos(CleanCursorPos,true);
  if (ANode=nil) then exit;
  if (ANode.Desc=ctnProcedureHead)
  and (ANode.Parent<>nil) and (ANode.Parent.Desc=ctnProcedure) then
    ANode:=ANode.Parent;

  // add space behind node to scan range
  NextNode:=ANode.Next;
  if NextNode<>nil then
    EndPos:=NextNode.StartPos
  else
    EndPos:=ANode.EndPos;

  // scan range for comments
  if not Scan(Anode.StartPos,EndPos) then exit;

  if ANode.Desc in AllIdentifierDefinitions then begin
    // scan behind type
    // for example:   i: integer; // comment
    TypeNode:=FindTypeNodeOfDefinition(ANode);
    if TypeNode<>nil then begin
      NextNode:=TypeNode.Next;
      if NextNode<>nil then
        EndPos:=NextNode.StartPos
      else
        EndPos:=ANode.EndPos;
      if not Scan(TypeNode.EndPos,EndPos) then exit;
    end;
  end;
  Result:=true;
end;

function TStandardCodeTool.GatherResourceStringsWithValue(
  const CursorPos: TCodeXYPosition; const StringValue: string;
  PositionList: TCodeXYPositions): boolean;
  
  procedure CompareStringConst(ANode: TCodeTreeNode);
  var
    CurValue: String;
    NewCaret: TCodeXYPosition;
  begin
    MoveCursorToNodeStart(ANode);
    ReadNextAtom; // read identifier
    if not AtomIsIdentifier(false) then exit;
    ReadNextAtom; // read =
    if CurPos.Flag<>cafEqual then exit;
    ReadNextAtom; // read start of string constant
    if not AtomIsStringConstant then exit;
    // extract string constant value
    CurValue:=ReadStringConstantValue(CurPos.StartPos);
    if CurValue<>StringValue then exit;
    // values are the same
    // -> add it to position list
    // get x,y position
    if not CleanPosToCaret(ANode.StartPos,NewCaret) then exit;
    //DebugLn('TStandardCodeTool.GatherResourceStringsWithValue Found ',MainFilename,' Y=',NewCaret.Y);
    PositionList.Add(NewCaret);
  end;
  
var
  CleanCursorPos: integer;
  ANode: TCodeTreeNode;
begin
  Result:=false;
  if PositionList=nil then exit;
  // parse source and find clean positions
  BuildTreeAndGetCleanPos(trAll,CursorPos,CleanCursorPos,[]);
  // find resource string section
  ANode:=FindDeepestNodeAtPos(CleanCursorPos,true);
  if (ANode=nil) then exit;
  ANode:=ANode.GetNodeOfType(ctnResStrSection);
  if ANode=nil then exit;
  // search identifier in section
  ANode:=ANode.FirstChild;
  while ANode<>nil do begin
    if (ANode.Desc=ctnConstDefinition) then begin
      CompareStringConst(ANode);
    end;
    ANode:=ANode.NextBrother;
  end;
end;

function TStandardCodeTool.GatherResourceStringIdents(
  const SectionPos: TCodeXYPosition; var IdentTree: TAVLTree): boolean;
var
  CleanCursorPos: integer;
  ANode: TCodeTreeNode;
begin
  Result:=false;
  IdentTree:=nil;
  // parse source and find clean positions
  BuildTreeAndGetCleanPos(trAll,SectionPos,CleanCursorPos,[]);
  // find resource string section
  ANode:=FindDeepestNodeAtPos(CleanCursorPos,true);
  if (ANode=nil) then exit;
  ANode:=ANode.GetNodeOfType(ctnResStrSection);
  if ANode=nil then exit;
  // search identifier in section
  ANode:=ANode.FirstChild;
  while ANode<>nil do begin
    if (ANode.Desc=ctnConstDefinition) then begin
      if IdentTree=nil then
        IdentTree:=TAVLTree.Create(TListSortCompare(@BasicCodeTools.CompareIdentifiers));
      IdentTree.Add(@Src[ANode.StartPos]);
    end;
    ANode:=ANode.NextBrother;
  end;
  Result:=true;
end;

function TStandardCodeTool.FindNearestResourceString(const CursorPos,
  SectionPos: TCodeXYPosition; var NearestPos: TCodeXYPosition): boolean;
var
  CursorTool, SectionTool: TStandardCodeTool;
  IdentTree: TAVLTree;
  NearestNode: TAVLTreeNode;
  NearestCleanPos: Integer;
begin
  Result:=false;
  NearestPos.Code:=nil;
  // get both codetools
  if not Assigned(OnGetCodeToolForBuffer) then exit;
  CursorTool:=
            TStandardCodeTool(OnGetCodeToolForBuffer(Self,CursorPos.Code,true));
  SectionTool:=
           TStandardCodeTool(OnGetCodeToolForBuffer(Self,SectionPos.Code,true));
  if (CursorTool=nil) or (SectionTool=nil) then exit;
  // get all resourcestring identifiers
  IdentTree:=nil;
  Result:=SectionTool.GatherResourceStringIdents(SectionPos,IdentTree);
  if IdentTree=nil then exit;
  try
    // find nearest resourcestring identifier in the cursor source
    NearestNode:=CursorTool.FindNearestIdentifierNode(CursorPos,IdentTree);
    if NearestNode=nil then exit;
    // convert node to cleanpos
    NearestCleanPos:=PtrUInt(NearestNode.Data)-PtrUInt(@SectionTool.Src[1])+1;
    // convert cleanpos to caret
    CleanPosToCaret(NearestCleanPos,NearestPos);
  finally
    IdentTree.Free;
  end;
  Result:=true;
end;

function TStandardCodeTool.AddResourceString(const SectionPos: TCodeXYPosition;
  const NewIdentifier, NewValue: string;
  InsertPolicy: TResourcestringInsertPolicy;
  const NearestPos: TCodeXYPosition;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  CleanSectionPos: integer;
  ANode, SectionNode: TCodeTreeNode;
  Indent: Integer;
  InsertPos: Integer;
  InsertSrc: String;
  NearestCleanPos: integer;
begin
  Result:=false;
  //DebugLn('TStandardCodeTool.AddResourcestring A ',NewIdentifier,'=',NewValue,' ');
  if (NewIdentifier='') or (length(NewIdentifier)>255) then exit;
  if SourceChangeCache=nil then exit;
  SourceChangeCache.MainScanner:=Scanner;
  // parse source and find clean positions
  //DebugLn('TStandardCodeTool.AddResourcestring B');
  BuildTreeAndGetCleanPos(trAll,SectionPos,CleanSectionPos,[]);
  //DebugLn('TStandardCodeTool.AddResourcestring C');
  // find resource string section
  SectionNode:=FindDeepestNodeAtPos(CleanSectionPos,true);
  if (SectionNode=nil) then exit;
  SectionNode:=SectionNode.GetNodeOfType(ctnResStrSection);
  if SectionNode=nil then exit;
  
  //DebugLn('TStandardCodeTool.AddResourcestring D SectionChilds=',SectionNode.FirstChild<>nil);
  // find insert position
  if SectionNode.FirstChild=nil then begin
    // no resourcestring in this section yet -> append as first child
    Indent:=GetLineIndent(Src,SectionNode.StartPos)
            +SourceChangeCache.BeautifyCodeOptions.Indent;
    InsertPos:=SectionNode.StartPos+length('RESOURCESTRING');
  end else begin
    // search insert position
    case InsertPolicy of
    rsipAlphabetically:
      begin
        // insert new identifier alphabetically
        ANode:=SectionNode.FirstChild;
        while (ANode<>nil) do begin
          if (ANode.Desc=ctnConstDefinition)
          and (CompareIdentifiers(@Src[ANode.StartPos],
            PChar(Pointer(NewIdentifier)))<0)
          then
            break;
          ANode:=ANode.NextBrother;
        end;
        if ANode=nil then begin
          // append new identifier as last
          Indent:=GetLineIndent(Src,SectionNode.LastChild.StartPos);
          InsertPos:=FindLineEndOrCodeAfterPosition(SectionNode.LastChild.EndPos);
        end else begin
          // insert in front of node
          Indent:=GetLineIndent(Src,ANode.StartPos);
          InsertPos:=FindLineEndOrCodeInFrontOfPosition(ANode.StartPos);
        end;
      end;
      
    rsipContext:
      begin
        // find nearest
        ANode:=nil;
        if (NearestPos.Code<>nil)
        and (CaretToCleanPos(NearestPos,NearestCleanPos)=0) then begin
          ANode:=SectionNode.FirstChild;
          while (ANode<>nil) do begin
            if (ANode.Desc=ctnConstDefinition)
            and (ANode.StartPos<=NearestCleanPos)
            and (ANode.EndPos>NearestCleanPos)
            then begin
              break;
            end;
            ANode:=ANode.NextBrother;
          end;
        end;
        if ANode=nil then begin
          // append new identifier as last
          Indent:=GetLineIndent(Src,SectionNode.LastChild.StartPos);
          InsertPos:=FindLineEndOrCodeAfterPosition(SectionNode.LastChild.EndPos);
        end else begin
          // insert behind node
          Indent:=GetLineIndent(Src,ANode.StartPos);
          InsertPos:=FindLineEndOrCodeAfterPosition(ANode.EndPos);
        end;
      end;
      
    else
      begin
        // append new identifier
        Indent:=GetLineIndent(Src,SectionNode.LastChild.StartPos);
        InsertPos:=FindLineEndOrCodeAfterPosition(SectionNode.LastChild.EndPos);
      end;
    end;
  end;

  //DebugLn('TStandardCodeTool.AddResourcestring E Indent=',Indent,' InsertPos=',InsertPos,' ',copy(Src,InsertPos-9,8),'|',copy(Src,InsertPos,8));
  // insert
  InsertSrc:=SourceChangeCache.BeautifyCodeOptions.BeautifyStatement(
                     NewIdentifier+' = '+NewValue+';',Indent);
  //DebugLn('TStandardCodeTool.AddResourcestring F "',InsertSrc,'"');
  SourceChangeCache.Replace(gtNewLine,gtNewLine,InsertPos,InsertPos,InsertSrc);
  SourceChangeCache.Apply;
  Result:=true;
  //DebugLn('TStandardCodeTool.AddResourcestring END ',Result);
end;

function TStandardCodeTool.FindPublishedVariable(const UpperClassName,
  UpperVarName: string; ExceptionOnClassNotFound: boolean): TCodeTreeNode;
var ClassNode, SectionNode: TCodeTreeNode;
begin
  Result:=nil;
  if (UpperClassName='') or (length(UpperClassName)>255) then
    RaiseException(Format(ctsinvalidClassName, ['"', UpperClassName, '"']));
  BuildTree(true);
  ClassNode:=FindClassNodeInInterface(UpperClassName,true,false,false);
  if ClassNode=nil then begin
    if ExceptionOnClassNotFound then
      RaiseException(Format(ctsclassNotFound, ['"', UpperClassName, '"']))
    else
      exit;
  end;
  BuildSubTreeForClass(ClassNode);
  SectionNode:=ClassNode.FirstChild;
  while (SectionNode<>nil) do begin
    if SectionNode.Desc=ctnClassPublished then begin
      Result:=SectionNode.FirstChild;
      while Result<>nil do begin
        if (Result.Desc=ctnVarDefinition) then begin
          MoveCursorToNodeStart(Result);
          if ReadNextUpAtomIs(UpperVarName) then
            exit;
        end;
        Result:=Result.NextBrother;
      end;
    end;
    SectionNode:=SectionNode.NextBrother;
  end;
end;

function TStandardCodeTool.AddPublishedVariable(const UpperClassName,
  VarName, VarType: string; SourceChangeCache: TSourceChangeCache): boolean;
var ClassNode, SectionNode: TCodeTreeNode;
  Indent, InsertPos: integer;
begin
  Result:=false;
  if (UpperClassName='') or (length(UpperClassName)>255) then
    RaiseException(Format(ctsinvalidClassName2, ['"', UpperClassName, '"']));
  if (VarName='') or (length(VarName)>255) then
    RaiseException(Format(ctsinvalidVariableName, ['"', VarName, '"']));
  if (VarType='') or (length(VarType)>255) then
    RaiseException(Format(ctsinvalidVariableType, ['"', VarType, '"']));
  if (SourceChangeCache=nil) then
    RaiseException('missing SourceChangeCache');
  if FindPublishedVariable(UpperClassName,UpperCaseStr(VarName),true)<>nil then
  begin
    Result:=true;
    exit;
  end;
  ClassNode:=FindClassNodeInInterface(UpperClassName,true,false,true);
  if ClassNode=nil then
    RaiseException(Format(ctsclassNotFound, ['"', UpperClassName, '"']));
  BuildSubTreeForClass(ClassNode);
  SectionNode:=ClassNode.FirstChild;
  if (SectionNode.NextBrother<>nil)
  and (SectionNode.NextBrother.Desc=ctnClassPublished) then
    SectionNode:=SectionNode.NextBrother;
  SourceChangeCache.MainScanner:=Scanner;
  if SectionNode.FirstChild<>nil then begin
    Indent:=GetLineIndent(Src,SectionNode.FirstChild.StartPos);
  end else begin
    Indent:=GetLineIndent(Src,SectionNode.StartPos)
              +SourceChangeCache.BeautifyCodeOptions.Indent;
  end;
  InsertPos:=FindLineEndOrCodeInFrontOfPosition(SectionNode.EndPos);
  SourceChangeCache.Replace(gtNewLine,gtNewLine,InsertPos,InsertPos,
          SourceChangeCache.BeautifyCodeOptions.BeautifyStatement(
                     VarName+':'+VarType+';',Indent)
       );
  Result:=SourceChangeCache.Apply;
end;

function TStandardCodeTool.RemovePublishedVariable(const UpperClassName,
  UpperVarName: string; ExceptionOnClassNotFound: boolean;
  SourceChangeCache: TSourceChangeCache): boolean;
var VarNode: TCodeTreeNode;
  FromPos, ToPos: integer;
begin
  Result:=false;
  VarNode:=FindPublishedVariable(UpperClassName,UpperVarName,
                                 ExceptionOnClassNotFound);
  if VarNode=nil then exit;
  if (VarNode.PriorBrother<>nil)
  and (VarNode.PriorBrother.Desc=ctnVarDefinition)
  and (VarNode.PriorBrother.FirstChild=nil) then begin
    // variable definition has the form  'PriorVarName, VarName: VarType;'
    // or 'PriorVarName, VarName, NextVarName: VarType'
    // -> delete only ', VarName'
    MoveCursorToNodeStart(VarNode.PriorBrother);
    ReadNextAtom; // read 'PriorVarName'
    ReadNextAtom; // read ','
    FromPos:=CurPos.StartPos;
    ReadNextAtom; // read 'VarName'
    ReadNextAtom; // read ':'
    ToPos:=CurPos.StartPos;
  end else begin
    if VarNode.FirstChild<>nil then begin
      // variable definition has the form  'VarName: VarType;'
      // -> delete whole line
      FromPos:=FindLineEndOrCodeInFrontOfPosition(VarNode.StartPos);
      ToPos:=FindLineEndOrCodeAfterPosition(VarNode.EndPos);
    end else begin
      // variable definition has the form  'VarName, NextVarName: VarType;'
      // -> delete only 'VarName, '
      FromPos:=VarNode.StartPos;
      ToPos:=VarNode.NextBrother.StartPos;
    end;
  end;
  SourceChangeCache.MainScanner:=Scanner;
  if not SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,'') then exit;
  Result:=SourceChangeCache.Apply;
end;

function TStandardCodeTool.RenamePublishedVariable(const UpperClassName,
  UpperOldVarName: string; const NewVarName, VarType: shortstring;
  ExceptionOnClassNotFound: boolean;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  TypeNode, VarNode: TCodeTreeNode;
  ApplyNeeded: Boolean;
begin
  Result:=false;
  BuildTree(false);
  VarNode:=FindPublishedVariable(UpperClassName,UpperOldVarName,
                                 ExceptionOnClassNotFound);
  if VarNode<>nil then begin
    // old variable found
    // check type
    TypeNode:=FindTypeNodeOfDefinition(VarNode);
    MoveCursorToNodeStart(TypeNode);
    ReadNextAtom;
    SourceChangeCache.MainScanner:=Scanner;
    ApplyNeeded:=false;
    if (not AtomIs(VarType)) then begin
      // change the type
      ApplyNeeded:=true;
      if not SourceChangeCache.Replace(gtNone,gtNone,
        CurPos.StartPos,CurPos.EndPos,VarType)
      then begin
        RaiseException('Unable to replace type');
      end;
    end;
    // rename variable in source
    if not ReplaceWord(UpperOldVarName,NewVarName,false,SourceChangeCache) then
      exit;
    Result:=(not ApplyNeeded) or SourceChangeCache.Apply;
  end else begin
    // old variable not found -> add it
    Result:=AddPublishedVariable(UpperClassName,NewVarName,VarType,
                                 SourceChangeCache);
  end;
end;

function TStandardCodeTool.GatherPublishedClassElements(
  const TheClassName: string;
  ExceptionOnClassNotFound, WithVariables, WithMethods, WithProperties,
  WithAncestors: boolean;
  out TreeOfCodeTreeNodeExtension: TAVLTree): boolean;
  
  function Add(AFindContext: PFindContext): boolean;
  var
    ClassNode: TCodeTreeNode;
    CurTool: TFindDeclarationTool;
    SectionNode: TCodeTreeNode;
    ANode: TCodeTreeNode;
    CurProcName: String;
    NewNodeExt: TCodeTreeNodeExtension;
    CurPropName: String;
    CurVarName: String;
  begin
    Result:=false;
    ClassNode:=AFindContext^.Node;
    if (ClassNode=nil) or (ClassNode.Desc<>ctnClass) then exit;
    CurTool:=AFindContext^.Tool;
    CurTool.BuildSubTreeForClass(ClassNode);
    SectionNode:=ClassNode.FirstChild;
    while (SectionNode<>nil) do begin
      if SectionNode.Desc=ctnClassPublished then begin
        ANode:=SectionNode.FirstChild;
        while ANode<>nil do begin
          if (ANode.Desc=ctnProcedure) and WithMethods then begin
            CurProcName:=CurTool.ExtractProcName(ANode,[]);
            {$IFDEF VerboseDanglingComponentEvents}
            debugln('TStandardCodeTool.GatherPublishedClassElements CurProcName="',CurProcName,'"');
            {$ENDIF}
            NewNodeExt:=NodeExtMemManager.NewNode;
            with NewNodeExt do begin
              Node:=ANode;
              Txt:=CurProcName;
            end;
            TreeOfCodeTreeNodeExtension.Add(NewNodeExt);
          end
          else if (ANode.Desc=ctnVarDefinition) and WithVariables then begin
            CurVarName:=CurTool.ExtractDefinitionName(ANode);
            NewNodeExt:=NodeExtMemManager.NewNode;
            with NewNodeExt do begin
              Node:=ANode;
              Txt:=CurVarName;
            end;
            TreeOfCodeTreeNodeExtension.Add(NewNodeExt);
          end
          else if (ANode.Desc=ctnProperty) and WithProperties then begin
            CurPropName:=CurTool.ExtractPropName(ANode,false);
            NewNodeExt:=NodeExtMemManager.NewNode;
            with NewNodeExt do begin
              Node:=ANode;
              Txt:=CurPropName;
            end;
            TreeOfCodeTreeNodeExtension.Add(NewNodeExt);
          end;
          ANode:=ANode.NextBrother;
        end;
      end;
      SectionNode:=SectionNode.NextBrother;
    end;
    Result:=true;
  end;
  
var
  ClassNode: TCodeTreeNode;
  AncestorList: TFPList;// of PFindContext
  i: Integer;
begin
  Result:=false;
  TreeOfCodeTreeNodeExtension:=nil;
  if (TheClassName='') or (length(TheClassName)>255) then
    RaiseException(Format(ctsInvalidClassName, ['"', TheClassName, '"']));
  {$IFDEF VerboseDanglingComponentEvents}
  DebugLn(['TStandardCodeTool.GatherPublishedClassElements AAA1']);
  {$ENDIF}
  BuildTree(true);
  {$IFDEF VerboseDanglingComponentEvents}
  DebugLn(['TStandardCodeTool.GatherPublishedClassElements AAA2']);
  {$ENDIF}
  ClassNode:=FindClassNodeInInterface(TheClassName,true,false,
    ExceptionOnClassNotFound);
  if ClassNode=nil then exit;
  AncestorList:=nil;
  try
    if WithAncestors then begin
      if not FindClassAndAncestors(ClassNode,AncestorList) then exit;
    end else begin
      AddFindContext(AncestorList,CreateFindContext(Self,ClassNode));
    end;
    TreeOfCodeTreeNodeExtension:=TAVLTree.Create(@CompareCodeTreeNodeExt);
    for i:=0 to AncestorList.Count-1 do begin
      if not Add(PFindContext(AncestorList[i])) then exit;
    end;
    //debugln(['TStandardCodeTool.GatherPublishedClassElements END']);
  finally
    FreeListOfPFindContext(AncestorList);
  end;
  Result:=true;
end;

function TStandardCodeTool.FindDanglingComponentEvents(
  const TheClassName: string; RootComponent: TComponent;
  ExceptionOnClassNotFound, SearchInAncestors: boolean;
  out ListOfPInstancePropInfo: TFPList): boolean;
var
  PublishedMethods: TAVLTree;
  
  procedure AddDanglingEvent(Instance: TPersistent; PropInfo: PPropInfo);
  var
    NewItem: PInstancePropInfo;
  begin
    New(NewItem);
    NewItem^.Instance:=Instance;
    NewItem^.PropInfo:=PropInfo;
    if ListOfPInstancePropInfo=nil then ListOfPInstancePropInfo:=TFPList.Create;
    ListOfPInstancePropInfo.Add(NewItem);
    {$IFDEF VerboseDanglingComponentEvents}
    debugln('AddDanglingEvent ',DbgSName(Instance),' ',PropInfo^.Name);
    {$ENDIF}
  end;

  procedure CheckMethodsInComponent(AComponent: TComponent);
  var
    TypeInfo: PTypeInfo;
    TypeData: PTypeData;
    PropInfo: PPropInfo;
    CurCount: integer;
    PropType: PTypeInfo;
    NodeExt: TCodeTreeNodeExtension;
    CurMethod: TMethod;
    CurMethodName: String;
  begin
    if AComponent=nil then exit;
    {$IFDEF VerboseDanglingComponentEvents}
    debugln('TStandardCodeTool.FindDanglingComponentEvents Checking ',DbgSName(AComponent));
    {$ENDIF}
    // read all properties and remove doubles
    TypeInfo:=AComponent.ClassInfo;
    repeat
      // read all property infos of current class
      TypeData:=GetTypeData(TypeInfo);
      // skip unitname
      PropInfo:=PPropInfo(PByte(@TypeData^.UnitName)+Length(TypeData^.UnitName)+1);
      // read property count
      CurCount:=PWord(PropInfo)^;
      inc(PtrUInt(PropInfo),SizeOf(Word));
      {$IFDEF VerboseDanglingComponentEvents}
      debugln('    UnitName=',TypeData^.UnitName,' Type=',TypeInfo^.Name,' CurPropCount=',dbgs(CurCount));
      {$ENDIF}
      // read properties
      while CurCount>0 do begin
        // point PropInfo to next propinfo record.
        // Located at Name[Length(Name)+1] !
        {$IFDEF VerboseDanglingComponentEvents}
        debugln('      Property ',PropInfo^.Name,' Type=',PropInfo^.PropType^.Name);
        {$ENDIF}
        PropType:=PropInfo^.PropType;
        if PropType^.Kind=tkMethod then begin
          // RTTI property is method
          // -> search method in source
          CurMethod:=GetMethodProp(AComponent,PropInfo);
          CurMethodName:=OnGetMethodName(CurMethod,RootComponent);
          {$IFDEF VerboseDanglingComponentEvents}
          if (CurMethod.Data<>nil) or (CurMethod.COde<>nil) then
            debugln('      Component ',DbgSName(AComponent),' Property ',PropInfo^.Name,' Type=',PropInfo^.PropType^.Name,' CurMethodName="',CurMethodName,'"');
          {$ENDIF}
          if CurMethodName<>'' then begin
            NodeExt:=FindCodeTreeNodeExt(PublishedMethods,CurMethodName);
            if NodeExt=nil then begin
              // method not found -> dangling event
              AddDanglingEvent(AComponent,PropInfo);
            end;
          end;
        end;
        PropInfo:=PPropInfo(pointer(@PropInfo^.Name)+PByte(@PropInfo^.Name)^+1);
        dec(CurCount);
      end;
      TypeInfo:=TypeData^.ParentInfo;
    until TypeInfo=nil;
  end;

var
  i: Integer;
begin
  PublishedMethods:=nil;
  ListOfPInstancePropInfo:=nil;
  try
    // search all available published methods
    {$IFDEF VerboseDanglingComponentEvents}
    debugln('TStandardCodeTool.FindDanglingComponentEvents A ',MainFilename,' ',DbgSName(RootComponent));
    {$ENDIF}
    Result:=GatherPublishedClassElements(TheClassName,ExceptionOnClassNotFound,
                                         false,true,false,SearchInAncestors,
                                         PublishedMethods);
    if not Result then exit;
    // go through all components
    CheckMethodsInComponent(RootComponent);
    for i:=0 to RootComponent.ComponentCount-1 do
      CheckMethodsInComponent(RootComponent.Components[i]);
  finally
    NodeExtMemManager.DisposeAVLTree(PublishedMethods);
  end;
end;

function TStandardCodeTool.FindBlockCounterPart(
  const CursorPos: TCodeXYPosition;
  out NewPos: TCodeXYPosition; out NewTopLine: integer): boolean;
// jump from bracket-open to bracket-close or 'begin' to 'end'
// or 'until' to 'repeat' ...
var CleanCursorPos: integer;
begin
  Result:=false;
  BeginParsingAndGetCleanPos(true,false,CursorPos,CleanCursorPos);
  // read word at cursor
  MoveCursorToCleanPos(CleanCursorPos);
  if Src[CurPos.StartPos] in ['(','[','{'] then begin
    // jump forward to matching bracket
    ReadNextAtom;
    if not ReadForwardTilAnyBracketClose then exit;
  end else if Src[CurPos.StartPos] in [')',']','}'] then begin
    // jump backward to matching bracket
    ReadNextAtom;
    if not ReadBackwardTilAnyBracketClose then exit;
  end else begin
    if Src[CurPos.StartPos] in [';','.'] then dec(CurPos.StartPos);
    while (CurPos.StartPos>2) and IsWordChar[Src[CurPos.StartPos-1]] do
      dec(CurPos.StartPos);
    MoveCursorToCleanPos(CurPos.StartPos);
    ReadNextAtom;
    if CurPos.EndPos=CurPos.StartPos then exit;
    // read till block keyword counterpart
    if UpAtomIs('BEGIN') or UpAtomIs('CASE') or UpAtomIs('ASM')
    or UpAtomIs('RECORD') or UpAtomIs('TRY') or UpAtomIs('REPEAT') then begin
      // read forward till END, FINALLY, EXCEPT
      ReadTilBlockEnd(true,false);
    end else if UpAtomIs('END') or UpAtomIs('FINALLY') or UpAtomIs('EXCEPT')
    or UpAtomIs('UNTIL') then
    begin
      // read backward till BEGIN, CASE, ASM, RECORD, REPEAT
      ReadBackTilBlockEnd(true);
    end else
      exit;
  end;
  // CursorPos now contains the counter block keyword
  Result:=CleanPosToCaretAndTopLine(CurPos.StartPos,NewPos,NewTopLine);
end;

function TStandardCodeTool.FindBlockStart(const CursorPos: TCodeXYPosition;
  out NewPos: TCodeXYPosition; var NewTopLine: integer): boolean;
// jump to beginning of current block
// e.g. bracket open, 'begin', 'repeat', ...
var CleanCursorPos: integer;
begin
  Result:=false;
  // scan code
  BeginParsingAndGetCleanPos(true,false,CursorPos,CleanCursorPos);
  // read word at cursor
  MoveCursorToCleanPos(CleanCursorPos);
  while (CurPos.StartPos>2) and IsWordChar[Src[CurPos.StartPos-1]] do
    dec(CurPos.StartPos);
  MoveCursorToCleanPos(CurPos.StartPos);
  ReadNextAtom;
  try
    repeat
      ReadPriorAtom;
      if (CurPos.StartPos<0) then begin
        // start of source found -> this is always a block start
        CurPos.StartPos:=1;
        Result:=true;
        exit;
      end
      else if Src[CurPos.StartPos] in [')',']','}'] then begin
        // jump backward to matching bracket
        if not ReadBackwardTilAnyBracketClose then exit;
      end
      else if WordIsBlockStatementStart.DoItUpperCase(UpperSrc,
        CurPos.StartPos,CurPos.EndPos-CurPos.StartPos) then
      begin
        // block start found
        Result:=true;
        exit;
      end else if UpAtomIs('END') or UpAtomIs('FINALLY') or UpAtomIs('EXCEPT')
      or UpAtomIs('UNTIL') then
      begin
        // read backward till BEGIN, CASE, ASM, RECORD, REPEAT
        ReadBackTilBlockEnd(true);
      end;
    until false;
  finally
    if Result then begin
      // CursorPos now contains the counter block keyword
      Result:=CleanPosToCaretAndTopLine(CurPos.StartPos,NewPos,NewTopLine);
    end;
  end;
end;

function TStandardCodeTool.GuessUnclosedBlock(const CursorPos: TCodeXYPosition;
  out NewPos: TCodeXYPosition; out NewTopLine: integer): boolean;
{ search a block (e.g. begin..end) that looks unclosed, i.e. 'begin'
  without 'end' or 'begin' with 'end' in a different column.
  This function can be used as GuessNextUnclosedBlock, because it ignores blocks
  in front of CursorPos.
  
  Examples for good blocks:
    
    repeat
    until
    
    begin end           // start and end of block in the same line
    
    if expr then begin  // first char in line is relevant, not the block keyword
    end
    
    class;

        
  Examples for bad blocks:
    
    begin               // block start and end has different indenting
      end
      
    asm                 // 'end.' is source end, never asm end
    end.
    
      try               // different indenting
    finally
    
    repeat              // keywords do not match
    end
    
}
var CleanCursorPos: integer;
begin
  Result:=false;
  BeginParsingAndGetCleanPos(true,false,CursorPos,CleanCursorPos);
  // start reading at beginning of code
  MoveCursorToCleanPos(1);
  BuildBlockKeyWordFuncList;
  if ReadTilGuessedUnclosedBlock(CleanCursorPos,false) then
    Result:=CleanPosToCaretAndTopLine(CurPos.StartPos,NewPos,NewTopLine);
  //WriteDebugTreeReport;
end;

function TStandardCodeTool.FindBlockCleanBounds(
  const CursorPos: TCodeXYPosition; out BlockCleanStart, BlockCleanEnd: integer
  ): boolean;
var
  CleanCursorPos: integer;
  BlockStartFound: Boolean;
begin
  Result:=false;
  BlockCleanStart:=0;
  BlockCleanEnd:=0;
  // scan code
  BeginParsingAndGetCleanPos(true,false,CursorPos,CleanCursorPos);
  // read word at cursor
  MoveCursorToCleanPos(CleanCursorPos);
  while (CurPos.StartPos>2) and IsWordChar[Src[CurPos.StartPos-1]] do
    dec(CurPos.StartPos);
  MoveCursorToCleanPos(CurPos.StartPos);
  ReadNextAtom;
  BlockStartFound:=false;
  repeat
    ReadPriorAtom;
    if (CurPos.StartPos<0) then begin
      // start of source found -> this is always a block start
      CurPos.StartPos:=1;
      BlockStartFound:=true;
      break;
    end
    else if Src[CurPos.StartPos] in [')',']','}'] then begin
      // jump backward to matching bracket
      if not ReadBackwardTilAnyBracketClose then exit;
    end
    else if WordIsBlockStatementStart.DoItUpperCase(UpperSrc,
      CurPos.StartPos,CurPos.EndPos-CurPos.StartPos) then
    begin
      // block start found
      BlockStartFound:=true;
      break;
    end else if UpAtomIs('END') or UpAtomIs('FINALLY') or UpAtomIs('EXCEPT')
    or UpAtomIs('UNTIL') then
    begin
      // read backward till BEGIN, CASE, ASM, RECORD, REPEAT
      ReadBackTilBlockEnd(true);
    end;
  until false;
  if not BlockStartFound then exit;
  BlockCleanStart:=CurPos.StartPos;
  
  // read word at cursor
  MoveCursorToCleanPos(BlockCleanStart);
  if Src[CurPos.StartPos] in ['(','[','{'] then begin
    // jump forward to matching bracket
    ReadNextAtom;
    if not ReadForwardTilAnyBracketClose then exit;
  end else begin
    if Src[CurPos.StartPos] in [';','.'] then dec(CurPos.StartPos);
    while (CurPos.StartPos>2) and IsWordChar[Src[CurPos.StartPos-1]] do
      dec(CurPos.StartPos);
    MoveCursorToCleanPos(CurPos.StartPos);
    ReadNextAtom;
    if CurPos.EndPos=CurPos.StartPos then exit;
    // read till block keyword counterpart
    if UpAtomIs('BEGIN') or UpAtomIs('CASE') or UpAtomIs('ASM')
    or UpAtomIs('RECORD') or UpAtomIs('TRY') or UpAtomIs('REPEAT') then begin
      // read forward till END, FINALLY, EXCEPT
      ReadTilBlockEnd(true,false);
    end else
      exit;
  end;
  BlockCleanEnd:=CurPos.StartPos;
  Result:=true;
end;

function TStandardCodeTool.GuessMisplacedIfdefEndif(
  const CursorPos: TCodeXYPosition;
  out NewPos: TCodeXYPosition; out NewTopLine: integer): boolean;
var
  StartCursorPos, EndCursorPos: integer;
  StartCode, EndCode: Pointer;
begin
  Result:=false;
  try
    BeginParsing(true,false);
  except
    // ignore scanner and parser errors
    on e: ELinkScannerError do ;
    on e: ECodeToolError do ;
  end;
  if Scanner<>nil then begin
    CursorPos.Code.LineColToPosition(CursorPos.Y,CursorPos.X,StartCursorPos);
    StartCode:=CursorPos.Code;
    Result:=Scanner.GuessMisplacedIfdefEndif(StartCursorPos,StartCode,
                                             EndCursorPos,EndCode);
    if Result then begin
      NewPos.Code:=TCodeBuffer(EndCode);
      NewPos.Code.AbsoluteToLineCol(EndCursorPos,NewPos.Y,NewPos.X);
      if JumpCentered then begin
        NewTopLine:=NewPos.Y-(VisibleEditorLines shr 1);
        if NewTopLine<1 then NewTopLine:=1;
      end else
        NewTopLine:=NewPos.Y;
    end;
  end;
end;

function TStandardCodeTool.FindEnclosingIncludeDirective(
  const CursorPos: TCodeXYPosition; out NewPos: TCodeXYPosition;
  var NewTopLine: integer): boolean;
var
  CleanCursorPos, LinkIndex, NewCleanPos: integer;
begin
  Result:=false;
  try
    BuildTreeAndGetCleanPos(trTillCursor,CursorPos,CleanCursorPos,
             [{$IFNDEF DisableIgnoreErrorAfter}btSetIgnoreErrorPos{$ENDIF}]);
    LinkIndex:=Scanner.LinkIndexAtCleanPos(CleanCursorPos);
    LinkIndex:=Scanner.FindParentLink(LinkIndex);
    if LinkIndex<0 then
      // this is no include file
      exit;
    NewPos.Code:=TCodeBuffer(Scanner.Links[LinkIndex].Code);
    // calculate the directive end bracket
    NewCleanPos:=Scanner.Links[LinkIndex].CleanedPos+Scanner.LinkSize(LinkIndex)-1;
    Result:=CleanPosToCaretAndTopLine(NewCleanPos,NewPos,NewTopLine);
  finally
    ClearIgnoreErrorAfter;
  end;
end;

function TStandardCodeTool.FindModeDirective(DoBuildTree: boolean;
  out ACleanPos: integer): boolean;
var
  ParamPos: Integer;
begin
  Result:=false;
  ACleanPos:=0;
  if DoBuildTree then BuildTree(true);
  ACleanPos:=FindNextCompilerDirectiveWithName(Src,1,'Mode',
                                               Scanner.NestedComments,ParamPos);
  if ParamPos=0 then ;
  Result:=(ACleanPos>0) and (ACleanPos<=SrcLen);
end;

function TStandardCodeTool.FindResourceDirective(DoBuildTree: boolean;
  var ACleanPos: integer; const Filename: string): boolean;
var
  ParamPos: Integer;
  FilenameStartPos: Integer;
  FilenameEndPos: LongInt;
begin
  Result:=false;
  if DoBuildTree then BuildTree(true);
  ACleanPos:=1;
  repeat
    ACleanPos:=FindNextCompilerDirectiveWithName(Src,ACleanPos,'R',
      Scanner.NestedComments,ParamPos);
    if ParamPos=0 then ;
    if (ACleanPos<1) or (ACleanPos>SrcLen) then
      exit(false);
    if Filename='' then begin
      // searching any filename -> found
      exit(true);
    end;
    FilenameStartPos:=ACleanPos+length('{$R ');
    FilenameEndPos:=FilenameStartPos;
    while (FilenameEndPos<=SrcLen) and (Src[FilenameEndPos]<>'}') do
      inc(FilenameEndPos);
    if CompareText(PChar(Pointer(Filename)),length(Filename),
                   @Src[FilenameStartPos],FilenameEndPos-FilenameStartPos,
                   true,false)=0
    then begin
      // filename found
      exit(true);
    end;
    ACleanPos:=FilenameEndPos+1;
  until ACleanPos>SrcLen;
end;

function TStandardCodeTool.FindResourceDirective(
  const CursorPos: TCodeXYPosition; out NewPos: TCodeXYPosition;
  out NewTopLine: integer; const Filename: string): boolean;
var
  CleanCursorPos: integer;
begin
  Result:=false;
  BuildTreeAndGetCleanPos(trAll,CursorPos,CleanCursorPos,[]);
  if not FindResourceDirective(false,CleanCursorPos,Filename) then begin
    //DebugLn('TStandardCodeTool.FindResourceDirective resource directive not found');
    exit;
  end;
  Result:=CleanPosToCaretAndTopLine(CleanCursorPos,NewPos,NewTopLine);
end;

function TStandardCodeTool.AddResourceDirective(const Filename: string;
  SourceChangeCache: TSourceChangeCache; const NewSrc: string): boolean;
var
  ANode: TCodeTreeNode;
  Indent: LongInt;
  InsertPos: Integer;
  AddSrc: String;
begin
  Result:=false;
  BuildTree(true);
  // find an insert position
  ANode:=FindImplementationNode;
  if ANode<>nil then begin
    Indent:=GetLineIndent(Src,ANode.StartPos);
    InsertPos:=ANode.StartPos+length('implementation');
  end else begin
    ANode:=FindMainBeginEndNode;
    if ANode<>nil then begin
      Indent:=GetLineIndent(Src,ANode.StartPos);
      InsertPos:=ANode.StartPos;
    end else begin
      ANode:=FindMainUsesSection;
      if ANode<>nil then begin
        Indent:=GetLineIndent(Src,ANode.StartPos);
        InsertPos:=ANode.StartPos;
      end else begin
        Indent:=0;
        InsertPos:=1;
      end;
    end;
  end;

  // insert directive
  SourceChangeCache.MainScanner:=Scanner;
  if NewSrc<>'' then
    AddSrc:=NewSrc
  else
    AddSrc:=GetIndentStr(Indent)+'{$R '+Filename+'}';
  if not SourceChangeCache.Replace(gtEmptyLine,gtEmptyLine,InsertPos,InsertPos,
    AddSrc) then exit;
  if not SourceChangeCache.Apply then exit;

  Result:=true;
end;

function TStandardCodeTool.FixIncludeFilenames(Code: TCodeBuffer;
  SourceChangeCache: TSourceChangeCache;
  out FoundIncludeFiles: TStrings;
  var MissingIncludeFilesCodeXYPos: TFPList): boolean;
var
  ASource: String;
  
  {procedure WriteMissingIncludeFilesCodeXYPos;
  var
    CodePos: PCodeXYPosition;
    i: Integer;
  begin
    if MissingIncludeFilesCodeXYPos<>nil then begin
      for i:=0 to MissingIncludeFilesCodeXYPos.Count-1 do begin
        CodePos:=PCodeXYPosition(MissingIncludeFilesCodeXYPos[i]);
        DebugLn('TStandardCodeTool.FixMissingUnits ',dbgs(CodePos));
        DebugLn('TStandardCodeTool.FixMissingUnits ',CodePos^.Code.Filename);
        debugln(CodePos^.Code.Filename
             +'('+IntToStr(CodePos^.y)+','+IntToStr(CodePos^.x)+')'
             +' missing include file');
      end;
    end;
  end;}
  
  procedure Add(FilenameSrcPos: integer; const AFilename: string;
    Found: boolean);
  var
    NewFilename: String;
    p: PCodeXYPosition;
  begin
    if Found then begin
      if FoundIncludeFiles=nil then
        FoundIncludeFiles:=TStringList.Create;
      NewFilename:=TrimFilename(AFilename);
      if FoundIncludeFiles.IndexOf(NewFilename)<0 then
        FoundIncludeFiles.Add(NewFilename);
    end else begin
      if MissingIncludeFilesCodeXYPos=nil then
        MissingIncludeFilesCodeXYPos:=TFPList.Create;
      New(p);
      p^.Code:=Code;
      Code.AbsoluteToLineCol(FilenameSrcPos,p^.y,p^.x);
      MissingIncludeFilesCodeXYPos.Add(p);
      ///DebugLn('TStandardCodeTool.FixIncludeFilenames.Add "',p^.Code.Filename,'" ',dbgs(p),' X=',dbgs(p^.X),' Y=',dbgs(p^.Y));
      //WriteMissingIncludeFilesCodeXYPos;
    end;
  end;
  
  function SearchIncludeFilename(FilenameSrcPos: integer;
    const AFilename: string): string;
  var
    AFilePath: String;
    BaseDir: String;
    CurFilename: String;
    IncludePath: String;
    PathDivider: String;
    ACodeBuf: TCodeBuffer;
  begin
    Result:=TrimFilename(AFilename);
    if FilenameIsAbsolute(Result) then begin
      Result:=FindDiskFilename(Result);
      Add(FilenameSrcPos,Result,FileExistsCached(Result));
      //DebugLn('SearchIncludeFilename AbsoluteFilename="',Result,'"');
    end else begin
      BaseDir:=ExtractFilePath(MainFilename);
      //DebugLn('SearchIncludeFilename BaseDir="',BaseDir,'"');
      if FilenameIsAbsolute(BaseDir) then begin
        // unit has normal path -> not virtual
        AFilePath:=ExtractFilePath(Result);
        if AFilePath<>'' then begin
          // search relative to unit
          CurFilename:=FindDiskFilename(BaseDir+Result);
          Result:=copy(CurFilename,length(BaseDir)+1,length(CurFilename));
          if FileExistsCached(CurFilename) then
            Add(FilenameSrcPos,CurFilename,true)
          else
            Add(FilenameSrcPos,Result,false);
          //DebugLn('SearchIncludeFilename relative filename="',CurFilename,'"');
        end else begin
          // search in path
          IncludePath:='';
          PathDivider:=':;';
          if (Scanner.Values<>nil) then begin
            IncludePath:=Scanner.Values.Variables[ExternalMacroStart+'INCPATH'];
            if Scanner.Values.IsDefined('DELPHI') then
              PathDivider:=':'
          end;
          CurFilename:=SearchFileInPath(Result,BaseDir,IncludePath,PathDivider,
                                   ctsfcAllCase);
          if CurFilename<>'' then begin
            // found
            Result:=CreateRelativePath(CurFilename,BaseDir);
            Add(FilenameSrcPos,CurFilename,true);
          end else begin
            // not found
            Add(FilenameSrcPos,Result,false);
          end;
          //DebugLn('SearchIncludeFilename search in include path="',IncludePath,'" Result="',Result,'"');
        end;
      end else begin
        // unit has no path -> virtual unit -> search in virtual files
        ACodeBuf:=TCodeBuffer(Scanner.LoadSourceCaseLoUp(Result));
        if ACodeBuf<>nil then begin
          Result:=ACodeBuf.Filename;
          Add(FilenameSrcPos,Result,true);
        end else begin
          Add(FilenameSrcPos,Result,false);
        end;
      end;
    end;
  end;

  procedure FixFilename(StartPos, EndPos: integer);
  var
    OldFilename: String;
    AFilename: String;
  begin
    OldFilename:=SetDirSeparators(copy(ASource,StartPos,EndPos-StartPos));
    //DebugLn('FixFilename ',dbgs(StartPos),' ',dbgs(EndPos),' ',OldFilename);
    AFilename:=OldFilename;
    if ExtractFileExt(AFilename)='' then begin
      // add default extension
      if (Scanner.CompilerMode=cmDELPHI) then
        AFilename:=AFilename+'.pas'
      else
        AFilename:=AFilename+'.pp';
    end;
    AFilename:=SearchIncludeFilename(StartPos,AFilename);
    if OldFilename<>AFilename then begin
      DebugLn('FixFilename replacing in '+Code.Filename+' include directive "',OldFilename,'" with "',AFilename,'"');
      SourceChangeCache.ReplaceEx(gtNone,gtNone,0,0,Code,StartPos,EndPos,AFilename);
    end;
  end;
  
var
  p: Integer;
  NestedComments: Boolean;
  FilenameStartPos, FileNameEndPos, CommentStartPos, CommentEndPos: integer;
begin
  Result:=false;
  FoundIncludeFiles:=nil;
  if (Scanner=nil) or (Scanner.MainCode=nil) then exit;
  ASource:=Code.Source;
  Scanner.Scan(lsrInit,false);
  SourceChangeCache.MainScanner:=Scanner;
  
  Result:=true;
  NestedComments:=Scanner.NestedComments;
  p:=1;
  repeat
    p:=BasicCodeTools.FindNextIncludeDirective(ASource,p,NestedComments,
              FilenameStartPos, FileNameEndPos, CommentStartPos, CommentEndPos);
    if (p<1) or (p>length(ASource)) then break;
    if (CommentStartPos=0) and (CommentEndPos=0) then ;
    FixFilename(FilenameStartPos,FilenameEndPos);
    p:=FindCommentEnd(ASource,p,NestedComments);
    //DebugLn('TStandardCodeTool.FixIncludeFilenames ',dbgs(p));
  until false;
  //WriteMissingIncludeFilesCodeXYPos;

  Result:=SourceChangeCache.Apply;
end;

function TStandardCodeTool.ReadTilGuessedUnclosedBlock(
  MinCleanPos: integer;  ReadOnlyOneBlock: boolean): boolean;
// returns true if unclosed block found
var BlockType, CurBlockWord: TBlockKeyword;
  BlockStart: integer;
begin
  Result:=false;
  BlockType:=bkwNone;
  BlockStart:=-1;
  // read til this block is closed
  while (CurPos.StartPos<=SrcLen) do begin
    if BlockKeywordFuncList.DoItUppercase(UpperSrc,
      CurPos.StartPos,CurPos.EndPos-CurPos.StartPos) then
    begin
      for CurBlockWord:=Low(TBlockKeyword) to High(TBlockKeyword) do
        if UpAtomIs(BlockKeywords[CurBlockWord]) then
          break;
      if (CurBlockWord=bkwInterface) and (not LastAtomIs(0,'=')) then
        CurBlockWord:=bkwNone;

      if (CurBlockWord=bkwEnd) then begin
        ReadNextAtom;
        if AtomIsChar('.') then begin
          // source end found
          if BlockType in [bkwBegin,bkwNone] then begin
            CurPos.StartPos:=SrcLen+1;
            exit;
          end else begin
            MoveCursorToCleanPos(BlockStart);
            Result:=true;
            exit;
          end;
        end else
          UndoReadNextAtom;
      end;
      
      if BlockType=bkwNone then begin
        case CurBlockWord of

        bkwBegin, bkwAsm, bkwRepeat, bkwCase, bkwTry, bkwRecord:
          begin
            BlockType:=CurBlockWord;
            BlockStart:=CurPos.StartPos;
          end;
          
        bkwClass, bkwObject, bkwInterface, bkwDispInterface:
          begin
            ReadNextAtom;
            if AtomIsChar(';') then begin
              // forward class
            end else if ((CurBlockWord=bkwClass) and UpAtomIs('OF')) then begin
              // 'class of'
            end else if ((CurBlockWord=bkwClass)
            and (UpAtomIs('FUNCTION') or UpAtomIs('PROCEDURE'))) then begin
              // 'class procedure'
            end else if ((CurBlockWord=bkwObject) and LastUpAtomIs(0,'OF')) then
            begin
              // or 'of object'
            end else begin
              BlockType:=CurBlockWord;
              BlockStart:=LastAtoms.GetValueAt(0).StartPos;
              // read ancestor list  class(...)
              if CurPos.Flag=cafRoundBracketOpen then begin
                repeat
                  ReadNextAtom;
                  if AtomIsIdentifier(false) then begin
                    ReadNextAtom;
                    if CurPos.Flag=cafPoint then begin
                      ReadNextAtom;
                      AtomIsIdentifier(true);
                    end;
                  end;
                  if CurPos.Flag=cafRoundBracketClose then break;
                  if CurPos.Flag<>cafComma then begin
                    exit(false);
                  end;
                until false;
                ReadNextAtom;
              end;
              // a semicolon directly behind the ancestor list ends the class
              if (CurPos.Flag in [cafEnd,cafSemicolon]) then begin
                // class ends
                BlockType:=bkwNone;
              end else begin
                // class continues
                UndoReadNextAtom;
              end;
            end;
          end;

        bkwEnd, bkwUntil:
          begin
            // close block keywords found, but no block was opened
            //  -> unclosed block found
            Result:=true;
            exit;
          end;
          
        end;
      end
      else
      if ((BlockType in [bkwBegin, bkwAsm, bkwCase, bkwRecord, bkwClass,
        bkwObject, bkwFinally, bkwExcept, bkwInterface, bkwDispInterface])
        and (CurBlockWord=bkwEnd))
      or ((BlockType=bkwRepeat) and (CurBlockWord=bkwUntil)) then begin
        // block end found
        if (MinCleanPos<=CurPos.StartPos)
        and (GetLineIndent(Src,CurPos.StartPos)<>GetLineIndent(Src,BlockStart))
        then begin
          // different indent -> unclosed block found
          if GetLineIndent(Src,BlockStart)>GetLineIndent(Src,CurPos.StartPos)
          then begin
            // the current block is more indented than the next block
            // -> probably the current block misses a block end
            MoveCursorToCleanPos(BlockStart);
          end;
          Result:=true;
          exit;
        end;
        // end block
        if (BlockType=bkwRecord) and (CurBlockWord=bkwCase) then begin
          // the 'end' keyword is the end for the case block and the record block
          UndoReadNextAtom;
        end;
        BlockType:=bkwNone;
        if ReadOnlyOneBlock then break;
      end
      else
      if (BlockType=bkwTry) and (CurBlockWord in [bkwFinally,bkwExcept]) then
      begin
        // try..finally, try..except found
        if (MinCleanPos<=CurPos.StartPos)
        and (GetLineIndent(Src,CurPos.StartPos)<>GetLineIndent(Src,BlockStart))
        then begin
          // different indent -> unclosed block found
          //   probably a block start is missing, so the error position is
          //   here at block end
          Result:=true;
          exit;
        end;
        // change blocktype
        BlockType:=CurBlockWord;
        BlockStart:=CurPos.StartPos;
      end
      else
      if ((BlockType in [bkwBegin,bkwRepeat,bkwTry,bkwFinally,bkwExcept,
          bkwCase])
        and (CurBlockWord in [bkwBegin,bkwRepeat,bkwTry,bkwCase,bkwAsm]))
      or ((BlockType in [bkwClass,bkwInterface,bkwDispInterface,bkwObject,
          bkwRecord])
        and (CurBlockWord in [bkwRecord])) then
      begin
        // sub blockstart found -> read recursively
        Result:=ReadTilGuessedUnclosedBlock(MinCleanPos,true);
        if Result then exit;
      end
      else
      if (BlockType=bkwRecord) and (CurBlockWord=bkwCase) then begin
        // variant record
      end
      else
      if (BlockType=bkwClass) and (CurBlockWord=bkwClass) then begin
        // class method
      end
      else
      begin
        // unexpected keyword found
        if GetLineIndent(Src,BlockStart)>=GetLineIndent(Src,CurPos.StartPos)
        then begin
          // the current block is more or equal indented than the next block
          // -> probably the current block misses a block end
          MoveCursorToCleanPos(BlockStart);
        end;
        Result:=true;
        exit;
      end;
    end;
    ReadNextAtom;
  end;
end;

function TStandardCodeTool.ReadForwardTilAnyBracketClose: boolean;
// this function reads any bracket
// (the ReadTilBracketClose function reads only brackets in code, not comments)
var OpenBracket: char;
  CommentLvl: integer;
begin
  Result:=false;
  OpenBracket:=Src[CurPos.StartPos];
  if OpenBracket='{' then begin
    // read til end of comment
    CommentLvl:=1;
    inc(CurPos.StartPos);
    while (CurPos.StartPos<=SrcLen) and (CommentLvl>0) do begin
      case Src[CurPos.StartPos] of
      '{': if Scanner.NestedComments then inc(CommentLvl);
      '}':
        if CommentLvl=1 then begin
          Result:=true;
          break;
        end else
          dec(CommentLvl);
      end;
      inc(CurPos.StartPos);
    end;
  end else if OpenBracket='(' then begin
    if (CurPos.StartPos<SrcLen) and (Src[CurPos.StartPos+1]='*') then begin
      // read til end of comment
      inc(CurPos.StartPos,3);
      while true do begin
        if (CurPos.StartPos<=SrcLen)
        and ((Src[CurPos.StartPos-1]='*') and (Src[CurPos.StartPos]=')')) then
        begin
          Result:=true;
          exit;
        end;
        inc(CurPos.StartPos);
      end;
    end else begin
      Result:=ReadTilBracketClose(false);
    end;
  end else if OpenBracket='[' then begin
    Result:=ReadTilBracketClose(false);
  end;
end;

function TStandardCodeTool.ReadBackwardTilAnyBracketClose: boolean;
// this function reads any bracket
// (the ReadBackTilBracketClose function reads only brackets in code,
//  not comments)
var OpenBracket: char;
  CommentLvl: integer;
begin
  Result:=false;
  OpenBracket:=Src[CurPos.StartPos];
  if OpenBracket='}' then begin
    // read backwards til end of comment
    CommentLvl:=1;
    dec(CurPos.StartPos);
    while (CurPos.StartPos>=1) and (CommentLvl>0) do begin
      case Src[CurPos.StartPos] of
      '}': if Scanner.NestedComments then inc(CommentLvl);
      '{':
        if CommentLvl=1 then begin
          Result:=true;
          break;
        end else
          dec(CommentLvl);
      end;
      dec(CurPos.StartPos);
    end;
  end else if OpenBracket=')' then begin
    if (CurPos.StartPos>1) and (Src[CurPos.StartPos-1]='*') then begin
      // read til end of comment
      dec(CurPos.StartPos,3);
      while true do begin
        if (CurPos.StartPos>=1)
        and ((Src[CurPos.StartPos+1]='*') and (Src[CurPos.StartPos]='(')) then
        begin
          Result:=true;
          exit;
        end;
        dec(CurPos.StartPos);
      end;
    end else begin
      Result:=ReadBackTilBracketOpen(false);
    end;
  end else if OpenBracket=']' then begin
    Result:=ReadBackTilBracketOpen(false);
  end;
end;

function TStandardCodeTool.Explore(WithStatements: boolean;
  OnlyInterface: boolean): boolean;
var
  Node: TCodeTreeNode;
begin
  Result:=true;
  BuildTree(OnlyInterface);
  Node:=Tree.Root;
  while Node<>nil do begin
    case Node.Desc of
    ctnClass,ctnClassInterface:
      BuildSubTreeForClass(Node);
    ctnProcedure,ctnProcedureHead:
      BuildSubTreeForProcHead(Node);
    ctnBeginBlock:
      if WithStatements then
        BuildSubTreeForBeginBlock(Node);
    ctnImplementation:
      if OnlyInterface then exit;
    end;
    Node:=Node.Next;
  end;
end;

finalization
  FreeAndNil(BlockKeywordFuncList);

end.


