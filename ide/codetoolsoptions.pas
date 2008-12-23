{ /***************************************************************************
                 codetoolsoptions.pas  -  Lazarus IDE unit
                 -----------------------------------------

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

  Author: Mattias Gaertner

  Abstract:
    - TCodeToolsOptions
}
unit CodeToolsOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazConf, Laz_XMLCfg, FileUtil,
  LResources, Forms, Controls, Buttons, LclProc, ExtCtrls, StdCtrls, ComCtrls,
  Dialogs, CodeToolManager, DefineTemplates, SourceChanger, SynEdit,
  IDEWindowIntf, IDEOptionsIntf, IDEContextHelpEdit,
  IDEOptionDefs, EditDefineTree, LazarusIDEStrConsts, IDEProcs, ButtonPanel;

type

  { TCodeToolsOptions }

  TCodeToolsOptions = class(TAbstractIDEOptions)
  private
    FClassHeaderComments: boolean;
    FFilename: string;
    FIdentComplAddAssignOperator: Boolean;

    // General
    FSrcPath: string;
    FAdjustTopLineDueToComment: boolean;
    FJumpCentered: boolean;
    FCursorBeyondEOL: boolean;
    
    // Define Templates
    FGlobalDefineTemplates: TDefineTemplate;
    FDefinesEditMainSplitterTop: integer;
    FDefinesPreviewMainSplitterPos: integer;
    FDefinesPreviewTemplSplitterPos: integer;

    // CodeCreation
    FAddInheritedCodeToOverrideMethod: boolean;
    FCompleteProperties: boolean;
    FLineLength: integer;
    FClassPartInsertPolicy: TClassPartInsertPolicy;
    FMixMethodsAndProperties: boolean;
    FForwardProcBodyInsertPolicy: TForwardProcBodyInsertPolicy;
    FKeepForwardProcOrder: boolean;
    FMethodInsertPolicy: TMethodInsertPolicy;
    FKeyWordPolicy : TWordPolicy;
    FIdentifierPolicy: TWordPolicy;
    FDoNotSplitLineInFront: TAtomTypes;
    FDoNotSplitLineAfter: TAtomTypes;
    FDoInsertSpaceInFront: TAtomTypes;
    FDoInsertSpaceAfter: TAtomTypes;
    FPropertyReadIdentPrefix: string;
    FPropertyWriteIdentPrefix: string;
    FPropertyStoredIdentPostfix: string;
    FPrivateVariablePrefix: string;
    FSetPropertyVariablename: string;

    // identifier completion
    FIdentComplAddSemicolon: Boolean;
    procedure SetFilename(const AValue: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure ClearGlobalDefineTemplates;
    procedure Load;
    procedure Save;
    procedure AssignGlobalDefineTemplatesToTree(Tree: TDefineTree);
    property Filename: string read FFilename write SetFilename;
    procedure SetLazarusDefaultFilename;
    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;
    function IsEqual(CodeToolsOpts: TCodeToolsOptions): boolean;
    function CreateCopy: TCodeToolsOptions;
    procedure ReadGlobalDefinesTemplatesFromTree(Tree: TDefineTree);
    
    // General
    property SrcPath: string read FSrcPath write FSrcPath;
    property AdjustTopLineDueToComment: boolean
      read FAdjustTopLineDueToComment write FAdjustTopLineDueToComment;
    property JumpCentered: boolean read FJumpCentered write FJumpCentered;
    property CursorBeyondEOL: boolean
      read FCursorBeyondEOL write FCursorBeyondEOL;

    // Define Templates
    property GlobalDefineTemplates: TDefineTemplate read FGlobalDefineTemplates;
    property DefinesEditMainSplitterTop: integer read FDefinesEditMainSplitterTop
                                              write FDefinesEditMainSplitterTop;
    property DefinesPreviewMainSplitterPos: integer
       read FDefinesPreviewMainSplitterPos write FDefinesPreviewMainSplitterPos;
    property DefinesPreviewTemplSplitterPos: integer
       read FDefinesPreviewTemplSplitterPos write FDefinesPreviewTemplSplitterPos;

    // CodeCreation
    property CompleteProperties: boolean
      read FCompleteProperties write FCompleteProperties;
    property AddInheritedCodeToOverrideMethod: boolean
      read FAddInheritedCodeToOverrideMethod write FAddInheritedCodeToOverrideMethod;
    property LineLength: integer read FLineLength write FLineLength;
    property ClassPartInsertPolicy: TClassPartInsertPolicy
      read FClassPartInsertPolicy write FClassPartInsertPolicy;
    property MixMethodsAndProperties: boolean
      read FMixMethodsAndProperties write FMixMethodsAndProperties;
    property ForwardProcBodyInsertPolicy: TForwardProcBodyInsertPolicy
      read FForwardProcBodyInsertPolicy write FForwardProcBodyInsertPolicy;
    property KeepForwardProcOrder: boolean
      read FKeepForwardProcOrder write FKeepForwardProcOrder;
    property ClassHeaderComments: boolean
      read FClassHeaderComments write FClassHeaderComments;
    property MethodInsertPolicy: TMethodInsertPolicy
      read FMethodInsertPolicy write FMethodInsertPolicy;
    property KeyWordPolicy : TWordPolicy
      read FKeyWordPolicy write FKeyWordPolicy;
    property IdentifierPolicy: TWordPolicy
      read FIdentifierPolicy write FIdentifierPolicy;
    property DoNotSplitLineInFront: TAtomTypes
      read FDoNotSplitLineInFront write FDoNotSplitLineInFront;
    property DoNotSplitLineAfter: TAtomTypes
      read FDoNotSplitLineAfter write FDoNotSplitLineAfter;
    property DoInsertSpaceInFront: TAtomTypes
      read FDoInsertSpaceInFront write FDoInsertSpaceInFront;
    property DoInsertSpaceAfter: TAtomTypes
      read FDoInsertSpaceAfter write FDoInsertSpaceAfter;
    property PropertyReadIdentPrefix: string
      read FPropertyReadIdentPrefix write FPropertyReadIdentPrefix;
    property PropertyWriteIdentPrefix: string
      read FPropertyWriteIdentPrefix write FPropertyWriteIdentPrefix;
    property PropertyStoredIdentPostfix: string
      read FPropertyStoredIdentPostfix write FPropertyStoredIdentPostfix;
    property PrivateVariablePrefix: string
      read FPrivateVariablePrefix write FPrivateVariablePrefix;
    property SetPropertyVariablename: string
      read FSetPropertyVariablename write FSetPropertyVariablename;
      
    // identifier completion
    property IdentComplAddSemicolon: Boolean read FIdentComplAddSemicolon
                                             write FIdentComplAddSemicolon;
    property IdentComplAddAssignOperator: Boolean read FIdentComplAddAssignOperator
                                             write FIdentComplAddAssignOperator;
  end;

var
  CodeToolsOpts: TCodeToolsOptions = nil;

function GetTranslatedAtomTypes(a: TAtomType): string;
function TranslatedAtomToType(const s: string): TAtomType;
function ReadIdentifier(const s, DefaultIdent: string): string;

implementation


const
  CodeToolsOptionsVersion = 1;
  DefaultCodeToolsOptsFile = 'codetoolsoptions.xml';
  
function GetTranslatedAtomTypes(a: TAtomType): string;
begin
  case a of
  atNone: Result:=lisCodeToolsOptsNone;
  atKeyword: Result:=lisCodeToolsOptsKeyword;
  atIdentifier: Result:=lisCodeToolsOptsIdentifier;
  atColon: Result:=lisCodeToolsOptsColon;
  atSemicolon: Result:=lisCodeToolsOptsSemicolon;
  atComma: Result:=lisCodeToolsOptsComma;
  atPoint: Result:=lisCodeToolsOptsPoint;
  atAt: Result:=lisCodeToolsOptsAt;
  atNumber: Result:=lisCodeToolsOptsNumber;
  atStringConstant: Result:=lisCodeToolsOptsStringConst;
  atNewLine: Result:=lisCodeToolsOptsNewLine;
  atSpace: Result:=lisCodeToolsOptsSpace;
  atSymbol: Result:=lisCodeToolsOptsSymbol;
  else
    Result:='???';
  end;
end;

function TranslatedAtomToType(const s: string): TAtomType;
begin
  for Result:=Low(TAtomType) to High(TAtomType) do
    if s=GetTranslatedAtomTypes(Result) then exit;
  Result:=atNone;
end;

function ReadAtomTypesFromXML(XMLConfig: TXMLConfig; const Path: string;
  DefaultValues: TAtomTypes): TAtomTypes;
var a: TAtomType;
begin
  Result:=[];
  for a:=Low(TAtomType) to High(TAtomType) do begin
    if (a<>atNone)
    and (XMLConfig.GetValue(Path+AtomTypeNames[a]+'/Value',a in DefaultValues))
    then
      Include(Result,a);
  end;
end;

procedure WriteAtomTypesToXML(XMLConfig: TXMLConfig; const Path: string;
  NewValues, DefaultValues: TAtomTypes);
var a: TAtomType;
begin
  for a:=Low(TAtomType) to High(TAtomType) do begin
    if (a<>atNone) then
      XMLConfig.SetDeleteValue(Path+AtomTypeNames[a]+'/Value',
                               a in NewValues,a in DefaultValues);
  end;
end;


function IsIdentifier(const s: string): boolean;
var i: integer;
begin
  Result:=false;
  if (s='') then exit;
  for i:=1 to length(s) do begin
    if not (s[i] in ['_','A'..'Z','a'..'z']) then exit;
  end;
  Result:=true;
end;

function ReadIdentifier(const s, DefaultIdent: string): string;
begin
  if IsIdentifier(s) then
    Result:=s
  else
    Result:=DefaultIdent;
end;

{ TCodeToolsOptions }

constructor TCodeToolsOptions.Create;
begin
  inherited Create;
  FFilename:='';
  Clear;
end;

destructor TCodeToolsOptions.Destroy;
begin
  ClearGlobalDefineTemplates;
  inherited Destroy;
end;

procedure TCodeToolsOptions.Load;
var
  XMLConfig: TXMLConfig;
  FileVersion: integer;
  
  procedure LoadGlobalDefineTemplates;
  begin
    // delete old one
    ClearGlobalDefineTemplates;
    // create empty one
    FGlobalDefineTemplates:=TDefineTemplate.Create;
    FGlobalDefineTemplates.Name:='';
    // load
    FGlobalDefineTemplates.LoadFromXMLConfig(XMLConfig,'CodeToolsGlobalDefines/',
      true,true);
    // delete if still empty
    if FGlobalDefineTemplates.Name='' then begin
      ClearGlobalDefineTemplates;
    end else begin
      FGlobalDefineTemplates.SetDefineOwner(Self,true);
    end;
  end;
  
begin
  try
    XMLConfig:=TXMLConfig.Create(FFileName);
    FileVersion:=XMLConfig.GetValue('CodeToolsOptions/Version/Value',0);
    if (FileVersion<>0) and (FileVersion<CodeToolsOptionsVersion) then
      debugln(lisCompilerNOTELoadingOldCodetoolsOptionsFile, FFileName);

    // General
    FSrcPath:=XMLConfig.GetValue('CodeToolsOptions/SrcPath/Value','');
    FAdjustTopLineDueToComment:=XMLConfig.GetValue(
      'CodeToolsOptions/AdjustTopLineDueToComment/Value',true);
    FJumpCentered:=XMLConfig.GetValue('CodeToolsOptions/JumpCentered/Value',
      true);
    FCursorBeyondEOL:=XMLConfig.GetValue(
      'CodeToolsOptions/CursorBeyondEOL/Value',true);
      
    // Define templates
    LoadGlobalDefineTemplates;
    FDefinesEditMainSplitterTop:=XMLConfig.GetValue(
      'CodeToolsOptions/DefinesEditMainSplitter/Top',100);
    FDefinesPreviewMainSplitterPos:=XMLConfig.GetValue(
      'CodeToolsOptions/DefinesPreviewMainSplitter/Position',280);
    FDefinesPreviewTemplSplitterPos:=XMLConfig.GetValue(
      'CodeToolsOptions/DefinesPreviewTemplSplitter/Position',100);

    // CodeCreation
    FAddInheritedCodeToOverrideMethod:=XMLConfig.GetValue(
      'CodeToolsOptions/AddInheritedCodeToOverrideMethod/Value',true);
    FCompleteProperties:=XMLConfig.GetValue(
      'CodeToolsOptions/CompleteProperties/Value',true);
    FLineLength:=XMLConfig.GetValue(
      'CodeToolsOptions/LineLengthXMLConfig/Value',80);
    FClassPartInsertPolicy:=ClassPartPolicyNameToPolicy(XMLConfig.GetValue(
      'CodeToolsOptions/ClassPartInsertPolicy/Value',
      ClassPartInsertPolicyNames[cpipAlphabetically]));
    FMixMethodsAndProperties:=XMLConfig.GetValue(
      'CodeToolsOptions/MixMethodsAndProperties/Value',false);
    FForwardProcBodyInsertPolicy:=ForwardProcBodyInsertPolicyNameToPolicy(
      XMLConfig.GetValue('CodeToolsOptions/ForwardProcBodyInsertPolicy/Value',
        ForwardProcBodyInsertPolicyNames[fpipInFrontOfMethods]));
    FKeepForwardProcOrder:=XMLConfig.GetValue(
      'CodeToolsOptions/KeepForwardProcOrder/Value',true);
    FClassHeaderComments:=XMLConfig.GetValue(
      'CodeToolsOptions/ClassHeaderComments/Value',true);

    FMethodInsertPolicy:=MethodInsertPolicyNameToPolicy(XMLConfig.GetValue(
      'CodeToolsOptions/MethodInsertPolicy/Value',
      MethodInsertPolicyNames[mipClassOrder]));
    FKeyWordPolicy:=WordPolicyNameToPolicy(XMLConfig.GetValue(
      'CodeToolsOptions/KeyWordPolicy/Value',
      WordPolicyNames[wpLowerCase]));
    FIdentifierPolicy:=WordPolicyNameToPolicy(XMLConfig.GetValue(
      'CodeToolsOptions/IdentifierPolicy/Value',
      WordPolicyNames[wpNone]));
    FDoNotSplitLineInFront:=ReadAtomTypesFromXML(XMLConfig,
      'CodeToolsOptions/DoNotSplitLineInFront/',DefaultDoNotSplitLineInFront);
    FDoNotSplitLineAfter:=ReadAtomTypesFromXML(XMLConfig,
      'CodeToolsOptions/DoNotSplitLineAfter/',DefaultDoNotSplitLineAfter);
    FDoInsertSpaceInFront:=ReadAtomTypesFromXML(XMLConfig,
      'CodeToolsOptions/DoInsertSpaceInFront/',DefaultDoInsertSpaceInFront);
    FDoInsertSpaceAfter:=ReadAtomTypesFromXML(XMLConfig,
      'CodeToolsOptions/DoInsertSpaceAfter/',DefaultDoInsertSpaceAfter);
    FPropertyReadIdentPrefix:=ReadIdentifier(XMLConfig.GetValue(
      'CodeToolsOptions/PropertyReadIdentPrefix/Value',''),'Get');
    FPropertyWriteIdentPrefix:=ReadIdentifier(XMLConfig.GetValue(
      'CodeToolsOptions/PropertyWriteIdentPrefix/Value',''),'Set');
    FPropertyStoredIdentPostfix:=ReadIdentifier(XMLConfig.GetValue(
      'CodeToolsOptions/PropertyStoredIdentPostfix/Value',''),'IsStored');
    FPrivateVariablePrefix:=ReadIdentifier(XMLConfig.GetValue(
      'CodeToolsOptions/PrivateVariablePrefix/Value',''),'F');
    FSetPropertyVariablename:=ReadIdentifier(XMLConfig.GetValue(
      'CodeToolsOptions/SetPropertyVariablename/Value',''),'AValue');
      
    // identifier completion
    FIdentComplAddSemicolon:=XMLConfig.GetValue(
      'CodeToolsOptions/IdentifierCompletion/AddSemicolon',true);
    FIdentComplAddAssignOperator:=XMLConfig.GetValue(
      'CodeToolsOptions/IdentifierCompletion/AddAssignOperator',true);

    XMLConfig.Free;
  except
    on E: Exception do begin
      DebugLn('[TCodeToolsOptions.Load]  error reading "',FFilename,'": ',E.Message);
    end;
  end;
end;

procedure TCodeToolsOptions.Save;
var
  XMLConfig: TXMLConfig;
  
  procedure SaveGlobalDefineTemplates;
  begin
    if FGlobalDefineTemplates<>nil then
      FGlobalDefineTemplates.SaveToXMLConfig(XMLConfig,
        'CodeToolsGlobalDefines/',true,false,true,false);
  end;
  
begin
  try
    InvalidateFileStateCache;
    XMLConfig:=TXMLConfig.CreateClean(FFileName);
    XMLConfig.SetValue('CodeToolsOptions/Version/Value',
      CodeToolsOptionsVersion);

    // General
    XMLConfig.SetDeleteValue('CodeToolsOptions/SrcPath/Value',FSrcPath,'');
    XMLConfig.SetDeleteValue('CodeToolsOptions/AdjustTopLineDueToComment/Value',
                             FAdjustTopLineDueToComment,true);
    XMLConfig.SetDeleteValue('CodeToolsOptions/JumpCentered/Value',
                             FJumpCentered,true);
    XMLConfig.SetDeleteValue('CodeToolsOptions/CursorBeyondEOL/Value',
                             FCursorBeyondEOL,true);

    // Define templates
    SaveGlobalDefineTemplates;
    XMLConfig.SetDeleteValue('CodeToolsOptions/DefinesEditMainSplitter/Top',
                             FDefinesEditMainSplitterTop,100);
    XMLConfig.SetDeleteValue('CodeToolsOptions/DefinesPreviewMainSplitter/Position',
                             FDefinesPreviewMainSplitterPos,280);
    XMLConfig.SetDeleteValue('CodeToolsOptions/DefinesPreviewTemplSplitter/Position',
                             FDefinesPreviewTemplSplitterPos,100);

    // CodeCreation
    XMLConfig.SetDeleteValue(
      'CodeToolsOptions/AddInheritedCodeToOverrideMethod/Value',
      AddInheritedCodeToOverrideMethod,true);
    XMLConfig.SetDeleteValue(
      'CodeToolsOptions/CompleteProperties/Value',CompleteProperties,true);
    XMLConfig.SetDeleteValue(
      'CodeToolsOptions/LineLengthXMLConfig/Value',FLineLength,80);
    XMLConfig.SetDeleteValue('CodeToolsOptions/ClassPartInsertPolicy/Value',
      ClassPartInsertPolicyNames[FClassPartInsertPolicy],
      ClassPartInsertPolicyNames[cpipAlphabetically]);
    XMLConfig.SetDeleteValue(
      'CodeToolsOptions/MixMethodsAndProperties/Value',FMixMethodsAndProperties,
      false);
    XMLConfig.SetDeleteValue('CodeToolsOptions/ForwardProcBodyInsertPolicy/Value',
      ForwardProcBodyInsertPolicyNames[FForwardProcBodyInsertPolicy],
      ForwardProcBodyInsertPolicyNames[fpipInFrontOfMethods]);
    XMLConfig.SetDeleteValue(
      'CodeToolsOptions/KeepForwardProcOrder/Value',FKeepForwardProcOrder,true);
    XMLConfig.SetDeleteValue(
      'CodeToolsOptions/ClassHeaderComments/Value',FClassHeaderComments,true);
    XMLConfig.SetDeleteValue('CodeToolsOptions/MethodInsertPolicy/Value',
      MethodInsertPolicyNames[FMethodInsertPolicy],
      MethodInsertPolicyNames[mipClassOrder]);
    XMLConfig.SetDeleteValue('CodeToolsOptions/KeyWordPolicy/Value',
      WordPolicyNames[FKeyWordPolicy],
      WordPolicyNames[wpLowerCase]);
    XMLConfig.SetDeleteValue('CodeToolsOptions/IdentifierPolicy/Value',
      WordPolicyNames[FIdentifierPolicy],
      WordPolicyNames[wpNone]);
    WriteAtomTypesToXML(XMLConfig,'CodeToolsOptions/DoNotSplitLineInFront/',
      FDoNotSplitLineInFront,DefaultDoNotSplitLineInFront);
    WriteAtomTypesToXML(XMLConfig,'CodeToolsOptions/DoNotSplitLineAfter/',
      FDoNotSplitLineAfter,DefaultDoNotSplitLineAfter);
    WriteAtomTypesToXML(XMLConfig,'CodeToolsOptions/DoInsertSpaceInFront/',
      FDoInsertSpaceInFront,DefaultDoInsertSpaceInFront);
    WriteAtomTypesToXML(XMLConfig,'CodeToolsOptions/DoInsertSpaceAfter/',
      FDoInsertSpaceAfter,DefaultDoInsertSpaceAfter);
    XMLConfig.SetDeleteValue('CodeToolsOptions/PropertyReadIdentPrefix/Value',
      FPropertyReadIdentPrefix,'Get');
    XMLConfig.SetDeleteValue('CodeToolsOptions/PropertyWriteIdentPrefix/Value',
      FPropertyWriteIdentPrefix,'Set');
    XMLConfig.SetDeleteValue('CodeToolsOptions/PropertyStoredIdentPostfix/Value',
      FPropertyStoredIdentPostfix,'IsStored');
    XMLConfig.SetDeleteValue('CodeToolsOptions/PrivateVariablePrefix/Value',
      FPrivateVariablePrefix,'F');
    XMLConfig.SetDeleteValue('CodeToolsOptions/SetPropertyVariablename/Value',
      FSetPropertyVariablename,'AValue');

    // identifier completion
    XMLConfig.SetDeleteValue('CodeToolsOptions/IdentifierCompletion/AddSemicolon',
      FIdentComplAddSemicolon,true);
    XMLConfig.SetDeleteValue('CodeToolsOptions/IdentifierCompletion/AddAssignOperator',
      FIdentComplAddAssignOperator,true);

    XMLConfig.Flush;
    XMLConfig.Free;
  except
    on E: Exception do begin
      DebugLn('[TCodeToolsOptions.Save]  error writing "',FFilename,'": ',E.Message);
    end;
  end;
end;

procedure TCodeToolsOptions.SetFilename(const AValue: string);
begin
  FFilename:=AValue;
end;

procedure TCodeToolsOptions.SetLazarusDefaultFilename;
var
  ConfFileName: string;
begin
  ConfFileName:=SetDirSeparators(
                             GetPrimaryConfigPath+'/'+DefaultCodeToolsOptsFile);
  CopySecondaryConfigFile(DefaultCodeToolsOptsFile);
  if (not FileExistsUTF8(ConfFileName)) then begin
    debugln(lisCompilerNOTECodetoolsConfigFileNotFoundUsingDefaults);
  end;
  FFilename:=ConfFilename;
end;

procedure TCodeToolsOptions.Assign(Source: TPersistent);
var
  CodeToolsOpts: TCodeToolsOptions absolute Source;
begin
  if not ((Source = nil) or (Source is TCodeToolsOptions)) then
  begin
    inherited Assign(Source);
    Exit;
  end;

  if CodeToolsOpts <> nil then
  begin
    // General
    FSrcPath:=CodeToolsOpts.FSrcPath;
    FAdjustTopLineDueToComment:=CodeToolsOpts.FAdjustTopLineDueToComment;
    FJumpCentered:=CodeToolsOpts.FJumpCentered;
    FCursorBeyondEOL:=CodeToolsOpts.FCursorBeyondEOL;
    FAddInheritedCodeToOverrideMethod:=CodeToolsOpts.AddInheritedCodeToOverrideMethod;
    FCompleteProperties:=CodeToolsOpts.CompleteProperties;

    // define templates
    ClearGlobalDefineTemplates;
    FGlobalDefineTemplates:=
      CodeToolsOpts.FGlobalDefineTemplates.CreateCopy(false,true,true);
    if FGlobalDefineTemplates<>nil then
      FGlobalDefineTemplates.SetDefineOwner(Self,true);
    FDefinesEditMainSplitterTop:=CodeToolsOpts.DefinesEditMainSplitterTop;
    FDefinesPreviewMainSplitterPos:=CodeToolsOpts.DefinesPreviewMainSplitterPos;
    FDefinesPreviewTemplSplitterPos:=CodeToolsOpts.DefinesPreviewTemplSplitterPos;

    // CodeCreation
    FLineLength:=CodeToolsOpts.FLineLength;
    FClassPartInsertPolicy:=CodeToolsOpts.FClassPartInsertPolicy;
    FMixMethodsAndProperties:=CodeToolsOpts.MixMethodsAndProperties;
    FForwardProcBodyInsertPolicy:=CodeToolsOpts.ForwardProcBodyInsertPolicy;
    FKeepForwardProcOrder:=CodeToolsOpts.KeepForwardProcOrder;
    FClassHeaderComments:=CodeToolsOpts.ClassHeaderComments;
    FMethodInsertPolicy:=CodeToolsOpts.FMethodInsertPolicy;
    FKeyWordPolicy:=CodeToolsOpts.FKeyWordPolicy;
    FIdentifierPolicy:=CodeToolsOpts.FIdentifierPolicy;
    FDoNotSplitLineInFront:=CodeToolsOpts.FDoNotSplitLineInFront;
    FDoNotSplitLineAfter:=CodeToolsOpts.FDoNotSplitLineAfter;
    FDoInsertSpaceInFront:=CodeToolsOpts.FDoInsertSpaceInFront;
    FDoInsertSpaceAfter:=CodeToolsOpts.FDoInsertSpaceAfter;
    FPropertyReadIdentPrefix:=CodeToolsOpts.FPropertyReadIdentPrefix;
    FPropertyWriteIdentPrefix:=CodeToolsOpts.FPropertyWriteIdentPrefix;
    FPropertyStoredIdentPostfix:=CodeToolsOpts.FPropertyStoredIdentPostfix;
    FPrivateVariablePrefix:=CodeToolsOpts.FPrivateVariablePrefix;
    FSetPropertyVariablename:=CodeToolsOpts.FSetPropertyVariablename;
    
    // identifier completion
    FIdentComplAddSemicolon:=CodeToolsOpts.FIdentComplAddSemicolon;
    FIdentComplAddAssignOperator:=CodeToolsOpts.FIdentComplAddAssignOperator;
  end
  else
    Clear;
end;

procedure TCodeToolsOptions.Clear;
// !!! Does not reset Filename !!!
begin
  // General
  FSrcPath:='';
  FAdjustTopLineDueToComment:=true;
  FJumpCentered:=true;
  FCursorBeyondEOL:=true;
  
  // define templates
  ClearGlobalDefineTemplates;
  FDefinesEditMainSplitterTop:=100;
  FDefinesPreviewMainSplitterPos:=280;
  FDefinesPreviewTemplSplitterPos:=100;

  // CodeCreation
  FAddInheritedCodeToOverrideMethod:=true;
  FCompleteProperties:=true;
  FLineLength:=80;
  FClassPartInsertPolicy:=cpipLast;
  FMixMethodsAndProperties:=false;
  FForwardProcBodyInsertPolicy:=fpipInFrontOfMethods;
  FKeepForwardProcOrder:=true;
  FClassHeaderComments:=true;
  FMethodInsertPolicy:=mipClassOrder;
  FKeyWordPolicy:=wpLowerCase;
  FIdentifierPolicy:=wpNone;
  FDoNotSplitLineInFront:=DefaultDoNotSplitLineInFront;
  FDoNotSplitLineAfter:=DefaultDoNotSplitLineAfter;
  FDoInsertSpaceInFront:=DefaultDoInsertSpaceInFront;
  FDoInsertSpaceAfter:=DefaultDoInsertSpaceAfter;
  FPropertyReadIdentPrefix:='Get';
  FPropertyWriteIdentPrefix:='Set';
  FPropertyStoredIdentPostfix:='IsStored';
  FPrivateVariablePrefix:='f';
  FSetPropertyVariablename:='AValue';
  
  // identifier completion
  FIdentComplAddSemicolon:=true;
  FIdentComplAddAssignOperator:=true;
end;

procedure TCodeToolsOptions.ClearGlobalDefineTemplates;
begin
  if FGlobalDefineTemplates<>nil then begin
    FGlobalDefineTemplates.Clear(true);
    FGlobalDefineTemplates.Free;
    FGlobalDefineTemplates:=nil;
  end;
end;

function TCodeToolsOptions.IsEqual(CodeToolsOpts: TCodeToolsOptions): boolean;
begin
  Result:=
    // General
        (FSrcPath=CodeToolsOpts.FSrcPath)
    and (FAdjustTopLineDueToComment=CodeToolsOpts.FAdjustTopLineDueToComment)
    and (FJumpCentered=CodeToolsOpts.FJumpCentered)
    and (FCursorBeyondEOL=CodeToolsOpts.FCursorBeyondEOL)
    and (AddInheritedCodeToOverrideMethod=CodeToolsOpts.AddInheritedCodeToOverrideMethod)
    and (CompleteProperties=CodeToolsOpts.CompleteProperties)
    
    // define templates
    and (FGlobalDefineTemplates.IsEqual(
                                CodeToolsOpts.FGlobalDefineTemplates,true,true))
    and (FDefinesEditMainSplitterTop=CodeToolsOpts.fDefinesEditMainSplitterTop)
    and (FDefinesPreviewMainSplitterPos=CodeToolsOpts.FDefinesPreviewMainSplitterPos)
    and (FDefinesPreviewTemplSplitterPos=CodeToolsOpts.FDefinesPreviewTemplSplitterPos)

    // CodeCreation
    and (FLineLength=CodeToolsOpts.FLineLength)
    and (FClassPartInsertPolicy=CodeToolsOpts.FClassPartInsertPolicy)
    and (FMixMethodsAndProperties=CodeToolsOpts.MixMethodsAndProperties)
    and (FForwardProcBodyInsertPolicy=CodeToolsOpts.ForwardProcBodyInsertPolicy)
    and (FKeepForwardProcOrder=CodeToolsOpts.KeepForwardProcOrder)
    and (FClassHeaderComments=CodeToolsOpts.ClassHeaderComments)
    and (FMethodInsertPolicy=CodeToolsOpts.FMethodInsertPolicy)
    and (FKeyWordPolicy=CodeToolsOpts.FKeyWordPolicy)
    and (FIdentifierPolicy=CodeToolsOpts.FIdentifierPolicy)
    and (FDoNotSplitLineInFront=CodeToolsOpts.FDoNotSplitLineInFront)
    and (FDoNotSplitLineAfter=CodeToolsOpts.FDoNotSplitLineAfter)
    and (FDoInsertSpaceInFront=CodeToolsOpts.FDoInsertSpaceInFront)
    and (FDoInsertSpaceAfter=CodeToolsOpts.FDoInsertSpaceAfter)
    and (FPropertyReadIdentPrefix=CodeToolsOpts.FPropertyReadIdentPrefix)
    and (FPropertyWriteIdentPrefix=CodeToolsOpts.FPropertyWriteIdentPrefix)
    and (FPropertyStoredIdentPostfix=CodeToolsOpts.FPropertyStoredIdentPostfix)
    and (FPrivateVariablePrefix=CodeToolsOpts.FPrivateVariablePrefix)
    and (FSetPropertyVariablename=CodeToolsOpts.FSetPropertyVariablename)
   ;
end;

function TCodeToolsOptions.CreateCopy: TCodeToolsOptions;
begin
  Result:=TCodeToolsOptions.Create;
  Result.Assign(Self);
  Result.Filename:=Filename;
end;

procedure TCodeToolsOptions.ReadGlobalDefinesTemplatesFromTree(Tree: TDefineTree
  );
begin
  ClearGlobalDefineTemplates;
  FGlobalDefineTemplates:=
    Tree.ExtractTemplatesOwnedBy(Self,[],[dtfAutoGenerated]);
  if FGlobalDefineTemplates<>nil then begin
    FGlobalDefineTemplates.SetDefineOwner(Self,true);
  end;
end;

procedure TCodeToolsOptions.AssignTo(Dest: TPersistent);
var
  Boss: TCodeToolManager absolute Dest;
  BeautifyCodeOptions: TBeautifyCodeOptions absolute Dest;
begin
  if Dest is TCodeToolManager then
  begin
    // General - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    SetAdditionalGlobalSrcPathToCodeToolBoss(SrcPath);
    Boss.AdjustTopLineDueToComment:=AdjustTopLineDueToComment;
    Boss.JumpCentered:=JumpCentered;
    Boss.CursorBeyondEOL:=CursorBeyondEOL;
    Boss.AddInheritedCodeToOverrideMethod:=AddInheritedCodeToOverrideMethod;
    Boss.CompleteProperties:=CompleteProperties;

    // CreateCode - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    AssignTo(Boss.SourceChangeCache.BeautifyCodeOptions);
    Boss.SetPropertyVariablename:=SetPropertyVariablename;
  end
  else
  if Dest is TBeautifyCodeOptions then
  begin
    BeautifyCodeOptions.LineLength:=LineLength;
    BeautifyCodeOptions.ClassPartInsertPolicy:=ClassPartInsertPolicy;
    BeautifyCodeOptions.MixMethodsAndProperties:=MixMethodsAndProperties;
    BeautifyCodeOptions.ForwardProcBodyInsertPolicy:=ForwardProcBodyInsertPolicy;
    BeautifyCodeOptions.KeepForwardProcOrder:=KeepForwardProcOrder;
    BeautifyCodeOptions.ClassHeaderComments:=ClassHeaderComments;
    BeautifyCodeOptions.MethodInsertPolicy:=MethodInsertPolicy;
    BeautifyCodeOptions.KeyWordPolicy:=KeyWordPolicy;
    BeautifyCodeOptions.IdentifierPolicy:=IdentifierPolicy;
    BeautifyCodeOptions.DoNotSplitLineInFront:=DoNotSplitLineInFront;
    BeautifyCodeOptions.DoNotSplitLineAfter:=DoNotSplitLineAfter;
    BeautifyCodeOptions.DoInsertSpaceInFront:=DoInsertSpaceInFront;
    BeautifyCodeOptions.DoInsertSpaceAfter:=DoInsertSpaceAfter;
    BeautifyCodeOptions.PropertyReadIdentPrefix:=PropertyReadIdentPrefix;
    BeautifyCodeOptions.PropertyWriteIdentPrefix:=PropertyWriteIdentPrefix;
    BeautifyCodeOptions.PropertyStoredIdentPostfix:=PropertyStoredIdentPostfix;
    BeautifyCodeOptions.PrivateVariablePrefix:=PrivateVariablePrefix;
  end
  else
    inherited AssignTo(Dest);
end;

procedure TCodeToolsOptions.AssignGlobalDefineTemplatesToTree(Tree: TDefineTree);
begin
  // Define templates - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // remove old custom define templates
  Tree.RemoveTemplatesOwnedBy(Self,[],[dtfAutoGenerated]);
  // merge current custom define templates
  if FGlobalDefineTemplates<>nil then
    Tree.MergeDefineTemplates(FGlobalDefineTemplates,'');
end;

initialization
  RegisterIDEOptionsGroup(GroupCodetools, dlgGroupCodetools);
end.

