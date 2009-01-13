{
/***************************************************************************
                             sourceeditprocs.pas
                             -------------------

 ***************************************************************************/

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

  Support functions and types for the source editor.

}
unit SourceEditProcs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LCLType, GraphType, Graphics, Controls,
  SynEdit, SynEditHighlighter, SynRegExpr, SynCompletion,
  BasicCodeTools, CodeTree, CodeAtom, CodeCache, SourceChanger, CodeToolManager,
  PascalParserTool, KeywordFuncLists, FileProcs, IdentCompletionTool,
  LazIDEIntf, TextTools, IDETextConverter,
  DialogProcs, MainIntf, EditorOptions, CodeToolsOptions;

type

  { TLazTextConverterToolClasses }

  TLazTextConverterToolClasses = class(TTextConverterToolClasses)
  public
    function GetTempFilename: string; override;
    function SupportsType(aTextType: TTextConverterType): boolean; override;
    function LoadFromFile(Converter: TIDETextConverter; const AFilename: string;
                          UpdateFromDisk, Revert: Boolean): Boolean; override;
    function SaveCodeBufferToFile(Converter: TIDETextConverter;
                           const AFilename: string): Boolean; override;
    function GetCodeBufferSource(Converter: TIDETextConverter;
                                 out Source: string): boolean; override;
    function CreateCodeBuffer(Converter: TIDETextConverter;
                              const Filename, NewSource: string;
                              out CodeBuffer: Pointer): boolean; override;
    function LoadCodeBufferFromFile(Converter: TIDETextConverter;
                                   const Filename: string;
                                   UpdateFromDisk, Revert: Boolean;
                                   out CodeBuffer: Pointer): boolean; override;
    procedure AssignCodeToolBossError(Target: TCustomTextConverterTool); override;
  end;
  
procedure SetupTextConverters;
procedure FreeTextConverters;

type
  TCompletionType = (
    ctNone, ctWordCompletion, ctTemplateCompletion, ctIdentCompletion);
  TIdentComplValue = (
    icvIdentifier,
    icvProcWithParams,
    icvIndexedProp,
    icvCompleteProcDeclaration,
    icvUnitName
    );

// completion form and functions
function PaintCompletionItem(const AKey: string; ACanvas: TCanvas;
  X, Y, MaxX: integer; ItemSelected: boolean; Index: integer;
  aCompletion : TSynCompletion; CurrentCompletionType: TCompletionType;
  Highlighter: TSrcIDEHighlighter; MeasureOnly: Boolean = False): TPoint;

function GetIdentCompletionValue(aCompletion : TSynCompletion;
  AddChar: TUTF8Char;
  out ValueType: TIdentComplValue; out CursorToLeft: integer): string;
function BreakLinesInText(const s: string; MaxLineLength: integer): string;

implementation

var
  SynREEngine: TRegExpr;

procedure SetupTextConverters;
begin
  TextConverterToolClasses:=TLazTextConverterToolClasses.Create;
  TextConverterToolClasses.RegisterClass(TTextReplaceTool);
end;

procedure FreeTextConverters;
begin
  FreeAndNil(TextConverterToolClasses);
end;

function PaintCompletionItem(const AKey: string; ACanvas: TCanvas;
  X, Y, MaxX: integer; ItemSelected: boolean; Index: integer;
  aCompletion : TSynCompletion; CurrentCompletionType: TCompletionType;
  Highlighter: TSrcIDEHighlighter; MeasureOnly: Boolean): TPoint;
var
  BGRed: Integer;
  BGGreen: Integer;
  BGBlue: Integer;
  TokenStart: Integer;
  BackgroundColor: TColor;

  procedure SetFontColor(NewColor: TColor);
  
    {procedure IncreaseDiff(var Value: integer; BaseValue: integer);
    begin
      if Value<BaseValue then begin
        dec(Value,$80);
      end else begin
        inc(Value,$80);
      end;
      if (Value<0) or (Value>$ff) then begin
        if BaseValue<$80 then
          Value:=$ff
        else
          Value:=0;
      end;
    end;}
  
  var
    FGRed: Integer;
    FGGreen: Integer;
    FGBlue: Integer;
    RedDiff: integer;
    GreenDiff: integer;
    BlueDiff: integer;
  begin
    FGRed:=(NewColor shr 16) and $ff;
    FGGreen:=(NewColor shr 8) and $ff;
    FGBlue:=NewColor and $ff;
    RedDiff:=Abs(FGRed-BGRed);
    GreenDiff:=Abs(FGGreen-BGGreen);
    BlueDiff:=Abs(FGBlue-BGBlue);
    if RedDiff*RedDiff + GreenDiff*GreenDiff + BlueDiff*BlueDiff<70000 then
    begin
      NewColor:=InvertColor(NewColor);
      {IncreaseDiff(FGRed,BGRed);
      IncreaseDiff(FGGreen,BGGreen);
      IncreaseDiff(FGBlue,BGBlue);
      NewColor:=(FGRed shl 16) or (FGGreen shl 8) or FGBlue;}
    end;
    ACanvas.Font.Color:=NewColor;
  end;
  
  procedure WriteToken(var TokenStart, TokenEnd: integer);
  var
    CurToken: String;
  begin
    if TokenStart>=1 then begin
      CurToken:=copy(AKey,TokenStart,TokenEnd-TokenStart);
      if MeasureOnly then
        Inc(Result.X, ACanvas.TextWidth(CurToken))
      else
        ACanvas.TextOut(x+1, y, CurToken);
      x := x + ACanvas.TextWidth(CurToken);
      //debugln('Paint A Text="',CurToken,'" x=',dbgs(x),' y=',dbgs(y),' "',ACanvas.Font.Name,'" ',dbgs(ACanvas.Font.Height),' ',dbgs(ACanvas.TextWidth(CurToken)));
      TokenStart:=0;
    end;
  end;

  procedure PaintHighlighted(s: string);
  var
    sToken: PChar;
    nTokenLen: integer;
    Attr: TSynHighlightElement;
    CurForeground: Integer;
    CurBackground: Integer;
  begin
    if MeasureOnly then begin
      Inc(Result.X,ACanvas.TextWidth(s));
      exit;
    end;
    if (Highlighter<>nil) and (not ItemSelected) then begin
      Highlighter.ResetRange;
      Highlighter.SetLine(s,0);
      while not Highlighter.GetEol do begin
        Highlighter.GetTokenEx(sToken,nTokenLen);
        SetLength(s,nTokenLen);
        if nTokenLen>0 then begin
          System.Move(sToken^,s[1],nTokenLen);
          attr := Highlighter.GetTokenAttribute;
          CurForeground:=Attr.Foreground;
          CurBackground:=Attr.Background;
          if CurForeground=clNone then CurForeground:=clBlack;
          if CurBackground=clNone then CurBackground:=BackgroundColor;
          ACanvas.Font.Color:=CurForeground;
          ACanvas.Brush.Color:=CurBackground;
          ACanvas.TextOut(x,y,s);
          inc(x,ACanvas.TextWidth(s));
        end;
        Highlighter.Next;
      end;
    end else begin
      SetFontColor(clBlack);
      ACanvas.TextOut(x+1,y,s);
    end;
  end;

var
  i: Integer;
  s: string;
  IdentItem: TIdentifierListItem;
  AColor: TColor;
  ANode: TCodeTreeNode;
  ItemNode: TCodeTreeNode;
begin
  Result.X := 0;
  Result.Y := ACanvas.TextHeight('W');
  if CurrentCompletionType=ctIdentCompletion then begin
    // draw
    IdentItem:=CodeToolBoss.IdentifierList.FilteredItems[Index];
    if IdentItem=nil then begin
      if not MeasureOnly then
        ACanvas.TextOut(x+1, y, 'PaintCompletionItem: BUG in codetools');
      exit;
    end;
    BackgroundColor:=ACanvas.Brush.Color;
    BGRed:=(BackgroundColor shr 16) and $ff;
    BGGreen:=(BackgroundColor shr 8) and $ff;
    BGBlue:=BackgroundColor and $ff;

    // first write the type
    // var, procedure, property, function, type, const
    case IdentItem.GetDesc of

    ctnVarDefinition, ctnRecordCase:
      begin
        AColor:=clMaroon;
        s:='var';
      end;

    ctnTypeDefinition, ctnEnumerationType:
      begin
        AColor:=clLime;
        s:='type';
      end;

    ctnConstDefinition:
      begin
        AColor:=clOlive;
        s:='const';
      end;
      
    ctnProcedure:
      begin
        if IdentItem.IsFunction then begin
          AColor:=clTeal;
          s:='function';
        end else begin
          AColor:=clNavy;
          s:='procedure';
        end;
        if IdentItem.TryIsAbstractMethod then
          AColor:=clRed;
      end;
      
    ctnProperty:
      begin
        AColor:=clPurple;
        s:='property';
      end;
      
    ctnEnumIdentifier:
      begin
        AColor:=clOlive;
        s:='enum';
      end;
      
    ctnUnit:
      begin
        AColor:=clBlack;
        s:='unit';
      end;

    else
      AColor:=clGray;
      s:='';
    end;

    SetFontColor(AColor);
    if MeasureOnly then
      Inc(Result.X, ACanvas.TextWidth('procedure '))
    else
      ACanvas.TextOut(x+1,y,s);
    inc(x,ACanvas.TextWidth('procedure '));
    if x>MaxX then exit;

    // paint the identifier
    SetFontColor(clBlack);
    ACanvas.Font.Style:=ACanvas.Font.Style+[fsBold];
    s:=IdentItem.Identifier;
    if MeasureOnly then
      Inc(Result.X, 1+ACanvas.TextWidth(s))
    else begin
      //DebugLn(['PaintCompletionItem ',x,',',y,' ',s]);
      ACanvas.TextOut(x+1,y,s);
      inc(x,ACanvas.TextWidth(s));
      if x>MaxX then exit;
    end;
    ACanvas.Font.Style:=ACanvas.Font.Style-[fsBold];
    
    // finally paint the type/value/parameters
    s:='';
    ItemNode:=IdentItem.Node;
    if ItemNode<>nil then begin
      case ItemNode.Desc of

      ctnProcedure:
        begin
          s:=IdentItem.Tool.ExtractProcHead(ItemNode,
            [phpWithoutClassName,phpWithoutName,phpWithVarModifiers,
             phpWithParameterNames,phpWithDefaultValues,phpWithResultType,
             phpWithOfObject]);
        end;

      ctnProperty:
        begin
          s:=IdentItem.Tool.ExtractProperty(ItemNode,
            [phpWithoutName,phpWithVarModifiers,
             phpWithParameterNames,phpWithDefaultValues,phpWithResultType]);
        end;

      ctnVarDefinition:
        begin
          ANode:=IdentItem.Tool.FindTypeNodeOfDefinition(ItemNode);
          s:=' : '+IdentItem.Tool.ExtractNode(ANode,[]);
        end;

      ctnTypeDefinition:
        begin
          ANode:=IdentItem.Tool.FindTypeNodeOfDefinition(ItemNode);
          s:=' = '+IdentItem.Tool.ExtractNode(ANode,[]);
        end;

      ctnConstDefinition:
        begin
          ANode:=IdentItem.Tool.FindTypeNodeOfDefinition(ItemNode);
          if ANode<>nil then
            s:=' = '+IdentItem.Tool.ExtractNode(ANode,[])
          else begin
            s:=IdentItem.Tool.ExtractCode(ItemNode.StartPos
                            +GetIdentLen(@IdentItem.Tool.Src[ItemNode.StartPos]),
                            ItemNode.EndPos,[]);
          end;
          s:=copy(s,1,50);
        end;

      ctnRecordCase:
        begin
          s:=' : '+IdentItem.Tool.ExtractRecordCaseType(ItemNode);
        end;

      end;
    end else begin
      // IdentItem.Node=nil
      case IdentItem.GetDesc of
      ctnProcedure:
        begin
          s:=IdentItem.ParamList;
          if s<>'' then
            s:='('+s+')';
          s:=s+';'
        end;
      end;
    end;
    
    if s<>'' then begin
      inc(x);
      PaintHighlighted(s);
    end;

  end else begin
    // parse AKey for text and style
    i := 1;
    TokenStart:=0;
    while i <= Length(AKey) do begin
      case AKey[i] of
      #1, #2:
        begin
          WriteToken(TokenStart,i);
          // set color
          ACanvas.Font.Color := (Ord(AKey[i + 3]) shl 8
                        + Ord(AKey[i + 2])) shl 8
                        + Ord(AKey[i + 1]);
          inc(i, 4);
        end;
      #3:
        begin
          WriteToken(TokenStart,i);
          // set style
          case AKey[i + 1] of
          'B': ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
          'b': ACanvas.Font.Style := ACanvas.Font.Style - [fsBold];
          'U': ACanvas.Font.Style := ACanvas.Font.Style + [fsUnderline];
          'u': ACanvas.Font.Style := ACanvas.Font.Style - [fsUnderline];
          'I': ACanvas.Font.Style := ACanvas.Font.Style + [fsItalic];
          'i': ACanvas.Font.Style := ACanvas.Font.Style - [fsItalic];
          end;
          inc(i, 2);
        end;
      else
        if TokenStart<1 then TokenStart:=i;
        inc(i);
      end;
    end;
    WriteToken(TokenStart,i);
  end;
end;

function FindUnitName(IdentList: TIdentifierList;
  IdentItem: TIdentifierListItem): string;
var
  CodeBuf: TCodeBuffer;
begin
  Result:=IdentItem.Identifier;
  CodeBuf:=CodeToolBoss.FindUnitSource(IdentList.StartContextPos.Code,Result,'');
  if CodeBuf=nil then exit;
  Result:=CodeToolBoss.GetSourceName(CodeBuf,true);
  if Result='' then
    Result:=IdentItem.Identifier;
end;

function GetIdentCompletionValue(aCompletion : TSynCompletion;
  AddChar: TUTF8Char;
  out ValueType: TIdentComplValue; out CursorToLeft: integer): string;
var
  Index: Integer;
  IdentItem: TIdentifierListItem;
  IdentList: TIdentifierList;
  CursorAtEnd: boolean;
  ProcModifierPos: LongInt;
  ProcHeadFlags: TProcHeadAttributes;
  CanAddSemicolon: Boolean;
  CanAddComma: Boolean;
begin
  Result:='';
  CursorToLeft:=0;
  CursorAtEnd:=true;
  ValueType:=icvIdentifier;
  Index:=aCompletion.Position;
  IdentList:=CodeToolBoss.IdentifierList;
  CanAddSemicolon:=CodeToolsOpts.IdentComplAddSemicolon and (AddChar<>';');
  CanAddComma:=(AddChar<>',');

  IdentItem:=IdentList.FilteredItems[Index];
  if IdentItem=nil then exit;

  if not CodeToolBoss.IdentItemCheckHasChilds(IdentItem) then begin
    MainIDEInterface.DoJumpToCodeToolBossError;
    exit;
  end;

  Result:=IdentItem.Identifier;

  //DebugLn(['GetIdentCompletionValue ',NodeDescriptionAsString(IdentItem.GetDesc)]);
  case IdentItem.GetDesc of

    ctnProcedure:
      if (ilcfCanProcDeclaration in IdentList.ContextFlags)
      and (IdentItem.Node<>nil) then begin
        //DebugLn(['GetIdentCompletionValue icvCompleteProcDeclaration']);
        ValueType:=icvCompleteProcDeclaration;
      end else if IdentItem.IsProcNodeWithParams then
        ValueType:=icvProcWithParams;

    ctnProperty:
      if IdentItem.IsPropertyWithParams then
        ValueType:=icvIndexedProp;

    ctnUnit, ctnPackage, ctnLibrary:
      ValueType:=icvUnitName;
  end;

  case ValueType of
  
    icvProcWithParams:
      // add brackets for parameter lists
      if (AddChar='')
      and (ilcfStartInStatement in IdentList.ContextFlags)
      and (not IdentList.StartUpAtomBehindIs('('))
      and (not IdentList.StartUpAtomInFrontIs('@')) then begin
        Result:=Result+'()';
        inc(CursorToLeft);
        CursorAtEnd:=false;
      end;

    icvIndexedProp:
      // add brackets for parameter lists
      if (AddChar='')
      and (ilcfStartInStatement in IdentList.ContextFlags)
      and (not IdentList.StartUpAtomBehindIs('[')) then begin
        Result:=Result+'[]';
        inc(CursorToLeft);
        CursorAtEnd:=false;
      end;
      
    icvCompleteProcDeclaration:
      // create complete procedure declaration
      if (AddChar='')
      and (not (IdentList.StartAtomBehind.Flag
               in [cafEdgedBracketOpen,cafRoundBracketOpen]))
      and (IdentItem.Node<>nil) then begin
        ProcHeadFlags:=[phpWithStart,phpWithVarModifiers,phpWithParameterNames,
           phpWithDefaultValues,phpWithResultType,phpWithCallingSpecs,
           phpWithProcModifiers];
        if IdentList.StartUpAtomInFrontIs('PROCEDURE')
        or IdentList.StartUpAtomInFrontIs('FUNCTION')
        or IdentList.StartUpAtomInFrontIs('CONSTRUCTOR')
        or IdentList.StartUpAtomInFrontIs('DESTRUCTOR')
        then
          Exclude(ProcHeadFlags,phpWithStart);
        Result:=IdentItem.Tool.ExtractProcHead(IdentItem.Node,ProcHeadFlags);
        // replace virtual and dynamic with override
        ProcModifierPos:=System.Pos('VIRTUAL;',UpperCaseStr(Result));
        if ProcModifierPos<1 then
          ProcModifierPos:=System.Pos('DYNAMIC;',UpperCaseStr(Result));
        if ProcModifierPos>0 then
          Result:=copy(Result,1,ProcModifierPos-1)+'override;'
                  +copy(Result,ProcModifierPos+8,length(Result));
        // remove abstract
        ProcModifierPos:=System.Pos('ABSTRACT;',UpperCaseStr(Result));
        if ProcModifierPos>0 then
          Result:=copy(Result,1,ProcModifierPos-1)
                  +copy(Result,ProcModifierPos+9,length(Result));
        Result:=TrimLeft(CodeToolBoss.SourceChangeCache
          .BeautifyCodeOptions.BeautifyProc(
                   Result,CodeToolBoss.IdentifierList.StartContextPos.X,false));
        CanAddSemicolon:=false;
      end;

    icvUnitName:
      begin
        Result:=FindUnitName(IdentList,IdentItem);
      end;
  end;

  if CursorAtEnd then ;

  // add assignment operator :=
  if (CursorToLeft=0)
  and (AddChar='')
  and (ilcfStartIsLValue in  IdentList.ContextFlags)
  and (not IdentItem.HasChilds)
  and (not IdentList.StartUpAtomBehindIs(':='))
  and (IdentItem.CanBeAssigned)
  and CodeToolsOpts.IdentComplAddAssignOperator then begin
    if (atIdentifier in CodeToolsOpts.DoInsertSpaceAfter)
    or (atSymbol in CodeToolsOpts.DoInsertSpaceInFront) then
      Result:=Result+' ';
    Result:=Result+':=';
    if (atSymbol in CodeToolsOpts.DoInsertSpaceAfter) then
      Result:=Result+' ';
  end;

  // add last typed character (that ended the identifier completion and starts a new token)
  if AddChar<>'' then
    Result:=Result+AddChar;

  // add semicolon for statement ends
  if CanAddSemicolon
  and (not (ilcfNoEndSemicolon in IdentList.ContextFlags))
  then begin
    if (ilcfNeedsEndSemicolon in IdentList.ContextFlags)
    or (IdentItem.GetDesc=ctnProcedure)
    then begin
      Result:=Result+';';
      if (CursorToLeft=0) and (IdentItem.GetDesc=ctnProcedure)
      and (not IdentItem.IsFunction) then begin
        // a procedure call without paramters
        // put cursor behind semicolon
      end else begin
        // keep cursor in front of semicolon
        inc(CursorToLeft);
      end;
    end;
  end;

  if CanAddComma
  and (ilcfNeedsEndComma in IdentList.ContextFlags) then
  begin
    Result:=Result+',';
  end;

  //DebugLn(['GetIdentCompletionValue END Result="',Result,'"']);
end;

function BreakLinesInText(const s: string; MaxLineLength: integer): string;
begin
  Result:=BreakString(s,MaxLineLength,GetLineIndent(s,1));
end;

procedure InitSynREEngine;
begin
  if SynREEngine=nil then
    SynREEngine:=TRegExpr.Create;
end;

function SynREMatches(const TheText, RegExpr, ModifierStr: string;
  StartPos: integer): boolean;
begin
  InitSynREEngine;
  SynREEngine.ModifierStr:=ModifierStr;
  SynREEngine.Expression:=RegExpr;
  SynREEngine.InputString:=TheText;
  Result:=SynREEngine.ExecPos(StartPos);
end;

function SynREVar(Index: Integer): string;
begin
  if SynREEngine<>nil then
    Result:=SynREEngine.Match[Index]
  else
    Result:='';
end;

procedure SynREVarPos(Index: Integer; out MatchStart, MatchLength: integer);
begin
  if SynREEngine<>nil then begin
    MatchStart:=SynREEngine.MatchPos[Index];
    MatchLength:=SynREEngine.MatchLen[Index];
  end else begin
    MatchStart:=-1;
    MatchLength:=-1;
  end;
end;

function SynREVarCount: Integer;
begin
  if SynREEngine<>nil then
    Result:=SynREEngine.SubExprMatchCount
  else
    Result:=0;
end;

function SynREReplace(const TheText, FindRegExpr, ReplaceRegExpr: string;
  UseSubstutition: boolean; const ModifierStr: string): string;
begin
  InitSynREEngine;
  SynREEngine.ModifierStr:=ModifierStr;
  SynREEngine.Expression:=FindRegExpr;
  Result:=SynREEngine.Replace(TheText,ReplaceRegExpr,UseSubstutition);
end;

procedure SynRESplit(const TheText, SeparatorRegExpr: string; Pieces: TStrings;
  const ModifierStr: string);
begin
  InitSynREEngine;
  SynREEngine.ModifierStr:=ModifierStr;
  SynREEngine.Expression:=SeparatorRegExpr;
  SynREEngine.Split(TheText,Pieces);
end;

{ TLazTextConverterToolClasses }

function TLazTextConverterToolClasses.GetTempFilename: string;
var
  BaseDir: String;
begin
  BaseDir:='';
  if LazarusIDE.ActiveProject<>nil then
    BaseDir:=ExtractFilePath(LazarusIDE.ActiveProject.ProjectInfoFile);
  if BaseDir='' then
    BaseDir:=LazarusIDE.GetTestBuildDirectory;
  if BaseDir='' then
    BaseDir:=GetCurrentDirUTF8;
  BaseDir:=CleanAndExpandDirectory(BaseDir);
  Result:=FileProcs.GetTempFilename(BaseDir,'convert_');
end;

function TLazTextConverterToolClasses.LoadFromFile(
  Converter: TIDETextConverter; const AFilename: string; UpdateFromDisk,
  Revert: Boolean): Boolean;
var
  TheFilename: String;
  CodeBuf: TCodeBuffer;
  TargetCodeBuffer: TCodeBuffer;
begin
  TheFilename:=CleanAndExpandFilename(AFilename);
  CodeBuf:=CodeToolBoss.FindFile(TheFilename);
  if CodeBuf=nil then begin
    // it is not in cache
    // to save memory do not load it into the cache and use the default way
    //DebugLn(['TLazTextConverterToolClasses.LoadFromFile not in cache, using default ...']);
    Result:=Converter.LoadFromFile(AFilename,false,UpdateFromDisk,Revert);
  end else begin
    // use cache
    //DebugLn(['TLazTextConverterToolClasses.LoadFromFile using cache']);
    CodeBuf:=CodeToolBoss.LoadFile(TheFilename,UpdateFromDisk,Revert);
    if CodeBuf=nil then
      exit(false);
    Result:=true;
    //DebugLn(['TLazTextConverterToolClasses.LoadFromFile Converter.CurrentType=',ord(Converter.CurrentType)]);
    case Converter.CurrentType of
    tctSource:
      Converter.Source:=CodeBuf.Source;
    tctFile:
      Result:=SaveStringToFile(Converter.Filename,CodeBuf.Source,[])=mrOk;
    tctStrings:
      CodeBuf.AssignTo(Converter.Strings,true);
    tctCodeBuffer:
      begin
        if Converter.CodeBuffer=nil then
          Converter.CodeBuffer:=CodeBuf
        else begin
          TargetCodeBuffer:=(TObject(Converter.CodeBuffer) as TCodeBuffer);
          if TargetCodeBuffer<>CodeBuf then
            TargetCodeBuffer.Source:=CodeBuf.Source;
        end;
      end;
    end;
  end;
end;

function TLazTextConverterToolClasses.SaveCodeBufferToFile(
  Converter: TIDETextConverter; const AFilename: string): Boolean;
begin
  Result:=(TObject(Converter.CodeBuffer) as TCodeBuffer).SaveToFile(AFilename);
end;

function TLazTextConverterToolClasses.GetCodeBufferSource(
  Converter: TIDETextConverter; out Source: string): boolean;
begin
  Result:=true;
  Source:=(TObject(Converter.CodeBuffer) as TCodeBuffer).Source;
end;

function TLazTextConverterToolClasses.CreateCodeBuffer(
  Converter: TIDETextConverter; const Filename, NewSource: string; out
  CodeBuffer: Pointer): boolean;
begin
  CodeBuffer:=CodeToolBoss.CreateFile(Filename);
  if CodeBuffer<>nil then begin
    TCodeBuffer(CodeBuffer).Source:=NewSource;
    Result:=true;
  end else
    Result:=false;
end;

function TLazTextConverterToolClasses.LoadCodeBufferFromFile(
  Converter: TIDETextConverter; const Filename: string;
  UpdateFromDisk, Revert: Boolean; out CodeBuffer: Pointer): boolean;
begin
  CodeBuffer:=CodeToolBoss.LoadFile(Filename,UpdateFromDisk,Revert);
  Result:=CodeBuffer<>nil;
end;

procedure TLazTextConverterToolClasses.AssignCodeToolBossError(
  Target: TCustomTextConverterTool);
begin
  Target.ErrorMsg:=CodeToolBoss.ErrorMessage;
  Target.ErrorLine:=CodeToolBoss.ErrorLine;
  Target.ErrorColumn:=CodeToolBoss.ErrorColumn;
  Target.ErrorTopLine:=CodeToolBoss.ErrorTopLine;
  if CodeToolBoss.ErrorCode<>nil then
    Target.ErrorFilename:=CodeToolBoss.ErrorCode.Filename
  else
    Target.ErrorFilename:='';
end;

function TLazTextConverterToolClasses.SupportsType(aTextType: TTextConverterType
  ): boolean;
begin
  Result:=true;
end;

initialization
  REException:=ERegExpr;
  REMatchesFunction:=@SynREMatches;
  REVarFunction:=@SynREVar;
  REVarPosProcedure:=@SynREVarPos;
  REVarCountFunction:=@SynREVarCount;
  REReplaceProcedure:=@SynREReplace;
  RESplitFunction:=@SynRESplit;

finalization
  FreeAndNil(SynREEngine);

end.

