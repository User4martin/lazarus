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
    Standard Quick Fixes - tools to help fixing (compiler) messages.

  ToDo:
    - cant find unit: duplicate include file, e.g. control.inc
    - TQuickFixIdentifierNotFoundAddLocal: extend with add private/public
    - local var not used: remove declaration and all assignments
    - There is no method in an ancestor class to be overriden:
      1. option: if the ancestor has a function with the same name: update the parameter list
      2. option: remove the method
      3. option: add a virtual method to the ancestor
    - function header doesn't match any method: update from interface/class
    - function header doesn't match any method: update interface/class
    - complete function implementation with missing parameters
    - private variable not used => remove
    - Hint/Warning: (5036) Local variable "Path" does not seem to be initialized
         auto add begin+end
         Pointer:=nil
         integer:=0
         string:=''
         record: FillByte(p %H-,SizeOf(p),0)
         set:=[]
         enum:=low(enum);
         default()
    - Hint: function result does not seem to be initialized, see above for local var
}
unit etQuickFixes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  LazLogger, AvgLvlTree, LazFileUtils, LazUTF8,
  Menus, Dialogs, Controls,
  CodeToolManager, CodeCache, CodeTree, CodeAtom, BasicCodeTools,
  KeywordFuncLists,
  IDEExternToolIntf, IDEMsgIntf, LazIDEIntf, IDEDialogs, MenuIntf,
  ProjectIntf, PackageIntf, CompOptsIntf,
  LazarusIDEStrConsts,
  etFPCMsgParser, AbstractsMethodsDlg, QFInitLocalVarDlg;

type

  { TQuickFixIdentifierNotFoundAddLocal }

  TQuickFixIdentifierNotFoundAddLocal = class(TMsgQuickFix)
  public
    function IsApplicable(Msg: TMessageLine; out Identifier: string): boolean;
    procedure CreateMenuItems(Fixes: TMsgQuickFixes); override;
    procedure QuickFix({%H-}Fixes: TMsgQuickFixes; Msg: TMessageLine); override;
  end;

  { TQuickFixLocalVariableNotUsed_Remove }

  TQuickFixLocalVariableNotUsed_Remove = class(TMsgQuickFix)
  public
    function IsApplicable(Msg: TMessageLine; out Identifier: string): boolean;
    procedure CreateMenuItems(Fixes: TMsgQuickFixes); override;
    procedure QuickFix({%H-}Fixes: TMsgQuickFixes; Msg: TMessageLine); override;
  end;

  { TQuickFixLocalVarNotInitialized_AddAssignment }

  TQuickFixLocalVarNotInitialized_AddAssignment = class(TMsgQuickFix)
  public
    function IsApplicable(Msg: TMessageLine; out Identifier: string): boolean;
    procedure CreateMenuItems(Fixes: TMsgQuickFixes); override;
    procedure QuickFix({%H-}Fixes: TMsgQuickFixes; Msg: TMessageLine); override;
  end;

  { TQuickFixUnitNotFound_Remove }

  TQuickFixUnitNotFound_Remove = class(TMsgQuickFix)
  public
    function IsApplicable(Msg: TMessageLine;
      out MissingUnitName, UsedByUnit: string): boolean;
    procedure CreateMenuItems(Fixes: TMsgQuickFixes); override;
    procedure QuickFix({%H-}Fixes: TMsgQuickFixes; Msg: TMessageLine); override;
  end;

  { TQuickFixClassWithAbstractMethods
    Quick fix for example:
    Warning: Constructing a class "TClassA" with abstract methods }

  TQuickFixClassWithAbstractMethods = class(TMsgQuickFix)
  public
    function IsApplicable(Msg: TMessageLine; out aClassName: string): boolean;
    procedure CreateMenuItems(Fixes: TMsgQuickFixes); override;
    procedure QuickFix({%H-}Fixes: TMsgQuickFixes; Msg: TMessageLine); override;
  end;

  { TQuickFixSrcPathOfPkgContains_OpenPkg
    QuickFix for IDE warning "other sources path of package %s contains directory "%s", ..."
    Open Package
    }

  TQuickFixSrcPathOfPkgContains_OpenPkg = class(TMsgQuickFix)
  public
    function IsApplicable(Msg: TMessageLine; out PkgName: string): boolean;
    procedure CreateMenuItems(Fixes: TMsgQuickFixes); override;
    procedure QuickFix({%H-}Fixes: TMsgQuickFixes; Msg: TMessageLine); override;
  end;

  { TQuickFix_HideWithIDEDirective - hide with IDE directive %H- }

  TQuickFix_HideWithIDEDirective = class(TMsgQuickFix)
  public
    function IsApplicable(Msg: TMessageLine): boolean;
    procedure CreateMenuItems(Fixes: TMsgQuickFixes); override;
    procedure QuickFix(Fixes: TMsgQuickFixes; Msg: TMessageLine); override;
  end;

  { TQuickFix_HideWithCompilerOption - hide with compiler option -vm<id> }

  TQuickFix_HideWithCompilerOption = class(TMsgQuickFix)
  public
    function IsApplicable(Msg: TMessageLine; out ToolData: TIDEExternalToolData;
      out IDETool: TObject): boolean;
    procedure CreateMenuItems(Fixes: TMsgQuickFixes); override;
    procedure QuickFix({%H-}Fixes: TMsgQuickFixes; Msg: TMessageLine); override;
  end;

  { TIDEQuickFixes }

  TIDEQuickFixes = class(TMsgQuickFixes)
  private
    FParentMenuItem: TIDEMenuSection;
    fMenuItemToInfo: TPointerToPointerTree; // TIDEMenuCommand to TMenuItemInfo
    procedure MenuItemClick(Sender: TObject);
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure ClearLines;
    procedure SetMsgLines(aMsg: TMessageLine);
    procedure AddMsgLine(aMsg: TMessageLine);
    procedure OnPopupMenu(aParentMenuItem: TIDEMenuSection);
    function AddMenuItem(Fix: TMsgQuickFix; Msg: TMessageLine; aCaption: string;
      aTag: PtrInt=0): TIDEMenuCommand; override;
    function OpenMsg(Msg: TMessageLine): boolean;
    property ParentMenuItem: TIDEMenuSection read FParentMenuItem write FParentMenuItem;
  end;

var
  IDEQuickFixes: TIDEQuickFixes = nil;

function GetMsgCodetoolPos(Msg: TMessageLine; out Code: TCodeBuffer;
  out Tool: TCodeTool; out CleanPos: integer; out Node: TCodeTreeNode): boolean;
function GetMsgSrcPosOfIdentifier(Msg: TMessageLine; out Identifier: string;
  out Code: TCodeBuffer; out Tool: TCodeTool; out CleanPos: integer;
  out Node: TCodeTreeNode): boolean;
function GetMsgSrcPosOfThisIdentifier(Msg: TMessageLine; const Identifier: string;
  out Code: TCodeBuffer; out Tool: TCodeTool; out CleanPos: integer;
  out Node: TCodeTreeNode): boolean;

implementation

type
  TMenuItemInfo = class
  public
    MenuItem: TIDEMenuCommand;
    Fix: TMsgQuickFix;
    Msg: TMessageLine;
  end;

procedure ShowError(Msg: string);
begin
  IDEMessageDialog(lisQuickFixError, Msg, mtError, [mbCancel]);
end;

function IsIdentifierInCode(Code: TCodeBuffer; X,Y: integer;
  Identifier, ErrorMsg: string): boolean;
var
  p: integer;
  IdentStart: integer;
  IdentEnd: integer;
begin
  Result:=false;
  if Code=nil then begin
    ShowError(ErrorMsg+' (Code=nil)');
    exit;
  end;
  Code.LineColToPosition(Y,X,p);
  if p<1 then begin
    ShowError(Format(lisPositionOutsideOfSource, [ErrorMsg]));
    exit;
  end;
  GetIdentStartEndAtPosition(Code.Source,p,IdentStart,IdentEnd);
  if SysUtils.CompareText(Identifier,copy(Code.Source,IdentStart,IdentEnd-IdentStart))<>0
  then begin
    ShowError(ErrorMsg);
    exit;
  end;
  Result:=true;
end;

function GetMsgCodetoolPos(Msg: TMessageLine; out Code: TCodeBuffer;
  out Tool: TCodeTool; out CleanPos: integer; out Node: TCodeTreeNode): boolean;
var
  Filename: String;
begin
  Result:=false;
  Tool:=nil;
  CleanPos:=0;
  Node:=nil;
  Filename:=TrimFilename(Msg.GetFullFilename);
  if not FilenameIsAbsolute(Filename) then exit;
  Code:=CodeToolBoss.LoadFile(Filename,true,false);
  if Code=nil then exit;
  CodeToolBoss.Explore(Code,Tool,false);
  if Tool=nil then exit;
  if Tool.CaretToCleanPos(CodeXYPosition(Msg.Column,Msg.Line,Code),CleanPos)<>0 then exit;
  Node:=Tool.FindDeepestNodeAtPos(CleanPos,false);
  Result:=Node<>nil;
end;

function GetMsgSrcPosOfIdentifier(Msg: TMessageLine; out Identifier: string;
  out Code: TCodeBuffer; out Tool: TCodeTool; out CleanPos: integer; out
  Node: TCodeTreeNode): boolean;
begin
  Result:=false;
  Code:=nil;
  Tool:=nil;
  CleanPos:=0;
  Node:=nil;
  // check if message position is at end of identifier
  // (FPC gives position of start or end of identifier)
  if not GetMsgCodetoolPos(Msg,Code,Tool,CleanPos,Node) then exit;
  Tool.MoveCursorToCleanPos(CleanPos);
  if (CleanPos>Tool.SrcLen) or (not IsIdentChar[Tool.Src[CleanPos]]) then
    Tool.ReadPriorAtom
  else
    Tool.ReadNextAtom;
  Identifier:=Tool.GetAtom;
  CleanPos:=Tool.CurPos.StartPos;
  Result:=(Identifier<>'') and IsValidIdent(Identifier);
end;

function GetMsgSrcPosOfThisIdentifier(Msg: TMessageLine; const Identifier: string;
  out Code: TCodeBuffer; out Tool: TCodeTool; out CleanPos: integer;
  out Node: TCodeTreeNode): boolean;
var
  CurIdentifier: string;
begin
  Result:=GetMsgSrcPosOfIdentifier(Msg,CurIdentifier,Code,Tool,CleanPos,Node)
     and (CompareIdentifiers(PChar(CurIdentifier),PChar(Identifier))=0);
end;

{ TQuickFixLocalVarNotInitialized_AddAssignment }

function TQuickFixLocalVarNotInitialized_AddAssignment.IsApplicable(
  Msg: TMessageLine; out Identifier: string): boolean;
var
  Tool: TCodeTool;
  CleanPos: integer;
  Node: TCodeTreeNode;
  Code: TCodeBuffer;
begin
  Result:=false;
  if (Msg=nil) or (Msg.SubTool<>SubToolFPC) or (Msg.MsgID<1)
  or (not Msg.HasSourcePosition) then exit;

  // Check: Local variable "$1" does not seem to be initialized
  case Msg.MsgID of
  5036, // W_Local variable "$1" does not seem to be initialized
  5037, // W_Variable "$1" does not seem to be initialized
  5057, // H_Local variable "$1" does not seem to be initialized
  5058, // H_Variable "$1" does not seem to be initialized
  5089, // W_Local variable "$1" of a managed type does not seem to be initialized
  5090, // W_Variable "$1" of a managed type does not seem to be initialized
  5091, // H_Local variable "$1" of a managed type does not seem to be initialized
  5092: // H_Variable "$1" of a managed type does not seem to be initialized
    begin
      Identifier:=TIDEFPCParser.GetFPCMsgValue1(Msg);
      // check if message position is at end of identifier
      if not GetMsgSrcPosOfThisIdentifier(Msg,Identifier,Code,Tool,CleanPos,Node)
      then exit;
    end;
  5059, // W_Function result variable does not seem to initialized
  5060, // H_Function result variable does not seem to be initialized
  5093, // W_function result variable of a managed type does not seem to initialized
  5094: // H_Function result variable of a managed type does not seem to be initialized
    begin
      if not GetMsgSrcPosOfIdentifier(Msg,Identifier,Code,Tool,CleanPos,Node)
      then exit;
    end;
  else
    exit;
  end;
  if not IsValidIdent(Identifier) then exit;

  // check if identifier is in statement and start of expression
  if not (Node.Desc in AllPascalStatements) then exit;
  if (Tool.CurPos.Flag in [cafPoint,cafRoundBracketClose,cafEdgedBracketClose,
                           cafEnd])
  then exit;
  Result:=true;
end;

procedure TQuickFixLocalVarNotInitialized_AddAssignment.CreateMenuItems(
  Fixes: TMsgQuickFixes);
var
  Msg: TMessageLine;
  Identifier: String;
  i: Integer;
begin
  for i:=0 to Fixes.LineCount-1 do begin
    Msg:=Fixes.Lines[i];
    if not IsApplicable(Msg,Identifier) then continue;
    Fixes.AddMenuItem(Self, Msg, Format(lisInsertAssignment, [Identifier]));
    exit;
  end;
end;

procedure TQuickFixLocalVarNotInitialized_AddAssignment.QuickFix(
  Fixes: TMsgQuickFixes; Msg: TMessageLine);
var
  Identifier: String;
  Code: TCodeBuffer;
begin
  if not IsApplicable(Msg,Identifier) then exit;

  if not LazarusIDE.BeginCodeTools then begin
    DebugLn(['TQuickFixLocalVarNotInitialized_AddAssignment failed because IDE busy']);
    exit;
  end;

  Code:=CodeToolBoss.LoadFile(Msg.GetFullFilename,true,false);
  if Code=nil then exit;

  if QuickFixLocalVarNotInitialized(Code, Msg.Column, Msg.Line) then
    Msg.MarkFixed;
end;

{ TQuickFixSrcPathOfPkgContains_OpenPkg }

function TQuickFixSrcPathOfPkgContains_OpenPkg.IsApplicable(Msg: TMessageLine;
  out PkgName: string): boolean;
var
  Dir: string;
  Pattern: String;
  p: SizeInt;
begin
  Result:=false;
  if Msg=nil then exit;
  if Msg.MsgID<>0 then exit;

  Pattern:=lisOtherSourcesPathOfPackageContainsDirectoryWhichIsA;
  p:=Pos('%s',Pattern);
  if p<1 then begin
    debugln(['TQuickFixSrcPathOfPkgContains_OpenPkg.IsApplicable resourcestring misses %s: lisOtherSourcesPathOfPackageContainsDirectoryWhichIsA=',lisOtherSourcesPathOfPackageContainsDirectoryWhichIsA]);
    exit;
  end;
  ReplaceSubstring(Pattern,p,2,'$1');
  p:=Pos('%s',Pattern);
  if p<1 then begin
    debugln(['TQuickFixSrcPathOfPkgContains_OpenPkg.IsApplicable resourcestring misses %s: lisOtherSourcesPathOfPackageContainsDirectoryWhichIsA=',lisOtherSourcesPathOfPackageContainsDirectoryWhichIsA]);
    exit;
  end;
  ReplaceSubstring(Pattern,p,2,'$2');

  if not GetFPCMsgValues2(Msg.Msg,Pattern,PkgName,Dir) then exit;
  if PkgName='' then exit;
  PkgName:=GetIdentifier(PChar(PkgName));
  Result:=IsValidIdent(PkgName);
end;

procedure TQuickFixSrcPathOfPkgContains_OpenPkg.CreateMenuItems(
  Fixes: TMsgQuickFixes);
var
  i: Integer;
  Msg: TMessageLine;
  PkgName: string;
begin
  for i:=0 to Fixes.LineCount-1 do begin
    Msg:=Fixes.Lines[i];
    if not IsApplicable(Msg,PkgName) then continue;
    Fixes.AddMenuItem(Self, Msg, 'Open package "'+PkgName+'"');
    exit;
  end;
end;

procedure TQuickFixSrcPathOfPkgContains_OpenPkg.QuickFix(Fixes: TMsgQuickFixes;
  Msg: TMessageLine);
var
  PkgName: string;
begin
  if not IsApplicable(Msg,PkgName) then exit;
  PackageEditingInterface.DoOpenPackageWithName(PkgName,[pofAddToRecent],false);
end;

{ TQuickFix_HideWithCompilerOption }

function TQuickFix_HideWithCompilerOption.IsApplicable(Msg: TMessageLine; out
  ToolData: TIDEExternalToolData; out IDETool: TObject): boolean;
begin
  Result:=false;
  ToolData:=nil;
  IDETool:=nil;
  if (Msg.Urgency>=mluError)
  or (Msg.SubTool<>SubToolFPC)
  or (Msg.MsgID=0)
  then exit;
  ToolData:=Msg.GetToolData;
  if ToolData=nil then exit;
  IDETool:=ExternalToolList.GetIDEObject(ToolData);
  Result:=IDETool<>nil;
end;

procedure TQuickFix_HideWithCompilerOption.CreateMenuItems(Fixes: TMsgQuickFixes
  );
var
  i: Integer;
  Msg: TMessageLine;
  IDETool: TObject;
  s: String;
  ToolData: TIDEExternalToolData;
  CompOpts: TLazCompilerOptions;
begin
  for i:=0 to Fixes.LineCount-1 do begin
    Msg:=Fixes.Lines[i];
    if not IsApplicable(Msg,ToolData,IDETool) then continue;
    if IDETool is TLazProject then begin
      CompOpts:=TLazProject(IDETool).LazCompilerOptions;
      if CompOpts.MessageFlags[Msg.MsgID]=cfvHide then exit;
      s:=Format(lisHideWithProjectOptionVm, [IntToStr(Msg.MsgID)])
    end else if IDETool is TIDEPackage then begin
      CompOpts:=TIDEPackage(IDETool).LazCompilerOptions;
      if CompOpts.MessageFlags[Msg.MsgID]=cfvHide then exit;
      s:=Format(lisHideWithPackageOptionVm, [IntToStr(Msg.MsgID)]);
    end else
      continue;
    Fixes.AddMenuItem(Self,Msg,s);
  end;
  inherited CreateMenuItems(Fixes);
end;

procedure TQuickFix_HideWithCompilerOption.QuickFix(Fixes: TMsgQuickFixes;
  Msg: TMessageLine);
var
  IDETool: TObject;
  CompOpts: TLazCompilerOptions;
  Pkg: TIDEPackage;
  ToolData: TIDEExternalToolData;
  i: Integer;
  CurMsg: TMessageLine;
begin
  if not IsApplicable(Msg,ToolData,IDETool) then exit;
  if IDETool is TLazProject then begin
    CompOpts:=TLazProject(IDETool).LazCompilerOptions;
    CompOpts.MessageFlags[Msg.MsgID]:=cfvHide;
  end else if IDETool is TIDEPackage then begin
    if PackageEditingInterface.DoOpenPackageFile(ToolData.Filename,
                                        [pofAddToRecent],false)<>mrOk then exit;
    Pkg:=PackageEditingInterface.FindPackageWithName(ToolData.ModuleName);
    if Pkg=nil then exit;
    CompOpts:=Pkg.LazCompilerOptions;
    CompOpts.MessageFlags[Msg.MsgID]:=cfvHide;
  end else
    exit;
  Msg.MarkFixed;
  // mark all lines of the View with the same message type
  for i:=0 to Msg.Lines.Count-1 do begin
    CurMsg:=Msg.Lines[i];
    if (CurMsg.MsgID<>Msg.MsgID)
    or (CurMsg.Urgency>=mluError)
    or (CurMsg.SubTool<>SubToolFPC)
    then continue;
    CurMsg.MarkFixed;
  end;
end;

{ TQuickFixLocalVariableNotUsed_Remove }

function TQuickFixLocalVariableNotUsed_Remove.IsApplicable(Msg: TMessageLine;
  out Identifier: string): boolean;
var
  Tool: TCodeTool;
  CleanPos: integer;
  Node: TCodeTreeNode;
  Dummy: string;
  Code: TCodeBuffer;
begin
  Result:=false;
  // Check: Local variable "$1" not used
  if not TIDEFPCParser.MsgLineIsId(Msg,5025,Identifier,Dummy) then
    exit;
  if not Msg.HasSourcePosition or not IsValidIdent(Identifier) then exit;

  // check if message position is at end of identifier
  if not GetMsgSrcPosOfThisIdentifier(Msg,Identifier,Code,Tool,CleanPos,Node) then exit;

  // check if identifier is a var definition
  if not (Node.Desc in [ctnVarDefinition]) then exit;
  Tool.ReadPriorAtom;
  if (Tool.CurPos.Flag in [cafPoint,cafRoundBracketClose,cafEdgedBracketClose,
                           cafEnd])
  then exit;
  Result:=true;
end;

procedure TQuickFixLocalVariableNotUsed_Remove.CreateMenuItems(
  Fixes: TMsgQuickFixes);
var
  Msg: TMessageLine;
  Identifier: String;
  i: Integer;
begin
  for i:=0 to Fixes.LineCount-1 do begin
    Msg:=Fixes.Lines[i];
    if not IsApplicable(Msg,Identifier) then continue;
    Fixes.AddMenuItem(Self, Msg, Format(lisRemoveLocalVariable3, [Identifier]));
    exit;
  end;
end;

procedure TQuickFixLocalVariableNotUsed_Remove.QuickFix(Fixes: TMsgQuickFixes;
  Msg: TMessageLine);
var
  Identifier: String;
  Code: TCodeBuffer;
begin
  if not IsApplicable(Msg,Identifier) then exit;

  if not LazarusIDE.BeginCodeTools then begin
    DebugLn(['TQuickFixLocalVariableNotUsed_Remove failed because IDE busy']);
    exit;
  end;

  Code:=CodeToolBoss.LoadFile(Msg.GetFullFilename,true,false);
  if Code=nil then exit;

  if not CodeToolBoss.RemoveIdentifierDefinition(Code,Msg.Column,Msg.Line) then
  begin
    DebugLn(['TQuickFixLocalVariableNotUsed_Remove remove failed']);
    LazarusIDE.DoJumpToCodeToolBossError;
    exit;
  end;

  // message fixed
  Msg.MarkFixed;
end;

{ TQuickFixClassWithAbstractMethods }

function TQuickFixClassWithAbstractMethods.IsApplicable(Msg: TMessageLine; out
  aClassName: string): boolean;
var
  Dummy: string;
  Tool: TCodeTool;
  CleanPos: integer;
  Node: TCodeTreeNode;
  MissingMethod: string;
  Code: TCodeBuffer;
begin
  Result:=false;
  if (not Msg.HasSourcePosition) then exit;
  if IDEFPCParser.MsgLineIsId(Msg,4046,aClassname,Dummy) then begin
    // Constructing a class "$1" with abstract method "$2"
    Result:=true;
  end else if IDEFPCParser.MsgLineIsId(Msg,5042,MissingMethod,Dummy) then begin
    // No matching implementation for interface method "$1" found
    // The position is on the 'class' keyword
    // The MissingMethod is 'interfacename.procname'
    if not GetMsgCodetoolPos(Msg,Code,Tool,CleanPos,Node) then exit;
    if not (Node.Desc in AllClassObjects) then exit;
    aClassName:=Tool.ExtractClassName(Node,false);
    Result:=aClassName<>'';
  end;
end;

procedure TQuickFixClassWithAbstractMethods.CreateMenuItems(
  Fixes: TMsgQuickFixes);
var
  Msg: TMessageLine;
  aClassName: string;
  i: Integer;
begin
  for i:=0 to Fixes.LineCount-1 do begin
    Msg:=Fixes.Lines[i];
    if not IsApplicable(Msg,aClassName) then continue;
    Fixes.AddMenuItem(Self, Msg, Format(lisShowAbstractMethodsOf, [aClassName])
      );
    exit;
  end;
end;

procedure TQuickFixClassWithAbstractMethods.QuickFix(Fixes: TMsgQuickFixes;
  Msg: TMessageLine);
var
  Code: TCodeBuffer;
  aClassName: string;
  Tool: TCodeTool;
  NewCode: TCodeBuffer;
  NewX: integer;
  NewY: integer;
  NewTopLine: integer;
  CleanPos: integer;
  Node: TCodeTreeNode;
begin
  if not IsApplicable(Msg,aClassName) then exit;

  if not LazarusIDE.BeginCodeTools then begin
    DebugLn(['TQuickFixClassWithAbstractMethods failed because IDE busy']);
    exit;
  end;

  if not GetMsgCodetoolPos(Msg,Code,Tool,CleanPos,Node) then begin
    DebugLn(['TQuickFixClassWithAbstractMethods no tool for ',Msg.GetFullFilename]);
    ShowError('QuickFix: ClassWithAbstractMethods no tool for '+Msg.GetFullFilename);
    exit;
  end;

  if not CodeToolBoss.FindDeclarationOfIdentifier(Code,Msg.Column,Msg.Line,
    @aClassName[1],NewCode,NewX,NewY,NewTopLine)
  then begin
    if CodeToolBoss.ErrorMessage<>'' then begin
      LazarusIDE.DoJumpToCodeToolBossError
    end else begin
      IDEMessageDialog(lisClassNotFound,
        Format(lisClassNotFoundAt, [aClassName, Code.Filename, IntToStr(Msg.Line
          ), IntToStr(Msg.Column)]),
        mtError,[mbCancel]);
    end;
    exit;
  end;
  //DebugLn(['TQuickFixClassWithAbstractMethods Declaration at ',NewCode.Filename,' ',NewX,',',NewY]);

  if LazarusIDE.DoOpenFileAndJumpToPos(NewCode.Filename,
    Point(NewX,NewY),NewTopLine,-1,-1,[])<>mrOK
  then begin
    DebugLn(['TQuickFixClassWithAbstractMethods failed opening ',NewCode.Filename]);
    ShowError('QuickFix: ClassWithAbstractMethods failed opening '+NewCode.Filename);
    exit;
  end;

  ShowAbstractMethodsDialog;
end;

{ TQuickFixUnitNotFound_Remove }

function TQuickFixUnitNotFound_Remove.IsApplicable(Msg: TMessageLine; out
  MissingUnitName, UsedByUnit: string): boolean;
begin
  Result:=false;
  if Msg=nil then exit;
  if (Msg.SubTool<>SubToolFPC)
  or (not Msg.HasSourcePosition)
  or ((Msg.MsgID<>5023) // Unit "$1" not used in $2
  and (Msg.MsgID<>FPCMsgIDCantFindUnitUsedBy) // Can't find unit $1 used by $2
  and (Msg.MsgID<>10023)) // Unit $1 was not found but $2 exists
  then exit;

  MissingUnitName:=Msg.Attribute[FPCMsgAttrMissingUnit];
  UsedByUnit:=Msg.Attribute[FPCMsgAttrUsedByUnit];
  if (MissingUnitName='')
  and not IDEFPCParser.GetFPCMsgValues(Msg,MissingUnitName,UsedByUnit) then begin
    debugln(['TQuickFixUnitNotFound_Remove.IsApplicable failed to extract unit names: ',Msg.Msg]);
    exit;
  end;
  Result:=true;
end;

procedure TQuickFixUnitNotFound_Remove.CreateMenuItems(Fixes: TMsgQuickFixes);
var
  Msg: TMessageLine;
  MissingUnitName: string;
  UsedByUnit: string;
  i: Integer;
begin
  for i:=0 to Fixes.LineCount-1 do begin
    Msg:=Fixes.Lines[i];
    if not IsApplicable(Msg,MissingUnitName,UsedByUnit) then continue;
    Fixes.AddMenuItem(Self, Msg, Format(lisRemoveUses, [MissingUnitName]));
    exit;
  end;
end;

procedure TQuickFixUnitNotFound_Remove.QuickFix(Fixes: TMsgQuickFixes;
  Msg: TMessageLine);
var
  MissingUnitName: string;
  SrcUnitName: string;
  Code: TCodeBuffer;
begin
  if not IsApplicable(Msg,MissingUnitName,SrcUnitName) then begin
    debugln(['TQuickFixUnitNotFound_Remove.QuickFix invalid message ',Msg.Msg]);
    exit;
  end;

  if not LazarusIDE.BeginCodeTools then begin
    DebugLn(['TQuickFixUnitNotFound_Remove failed because IDE busy']);
    exit;
  end;

  Code:=CodeToolBoss.LoadFile(Msg.GetFullFilename,true,false);
  if Code=nil then exit;

  if not CodeToolBoss.RemoveUnitFromAllUsesSections(Code,MissingUnitName) then
  begin
    DebugLn(['TQuickFixUnitNotFound_Remove RemoveUnitFromAllUsesSections failed']);
    LazarusIDE.DoJumpToCodeToolBossError;
    exit;
  end;

  // success
  Msg.MarkFixed;
end;

{ TQuickFixIdentifierNotFoundAddLocal }

function TQuickFixIdentifierNotFoundAddLocal.IsApplicable(Msg: TMessageLine;
  out Identifier: string): boolean;
var
  Code: TCodeBuffer;
  Tool: TCodeTool;
  CleanPos: integer;
  Node: TCodeTreeNode;
  Dummy: string;
begin
  Result:=false;
  Identifier:='';
  // check: identifier not found "$1"
  if not IDEFPCParser.MsgLineIsId(Msg,5000,Identifier,Dummy) then
    exit;
  if not Msg.HasSourcePosition or not IsValidIdent(Identifier) then exit;

  // check if message position is at identifier
  if not GetMsgSrcPosOfThisIdentifier(Msg,Identifier,Code,Tool,CleanPos,Node) then exit;

  // check if identifier is expression start in statement
  if not (Node.Desc in AllPascalStatements) then exit;
  if (Tool.CurPos.Flag in [cafPoint,cafRoundBracketClose,cafEdgedBracketClose,
                           cafEnd])
  then exit;
  Result:=true;
end;

procedure TQuickFixIdentifierNotFoundAddLocal.CreateMenuItems(
  Fixes: TMsgQuickFixes);
var
  Msg: TMessageLine;
  Identifier: String;
  i: Integer;
begin
  for i:=0 to Fixes.LineCount-1 do begin
    Msg:=Fixes.Lines[i];
    if not IsApplicable(Msg,Identifier) then continue;
    Fixes.AddMenuItem(Self, Msg, Format(lisCreateLocalVariable, [Identifier]));
    // ToDo: add private/public variable
    exit;
  end;
end;

procedure TQuickFixIdentifierNotFoundAddLocal.QuickFix(Fixes: TMsgQuickFixes;
  Msg: TMessageLine);
var
  Identifier: String;
  Code: TCodeBuffer;
  NewCode: TCodeBuffer;
  NewX: integer;
  NewY: integer;
  NewTopLine: integer;
begin
  if not IsApplicable(Msg,Identifier) then exit;

  if not LazarusIDE.BeginCodeTools then begin
    DebugLn(['TQuickFixIdentifierNotFoundAddLocal.Execute failed because IDE busy']);
    exit;
  end;

  Code:=CodeToolBoss.LoadFile(Msg.GetFullFilename,true,false);
  if Code=nil then exit;

  if not CodeToolBoss.CreateVariableForIdentifier(Code,Msg.Column,Msg.Line,-1,
             NewCode,NewX,NewY,NewTopLine)
  then begin
    LazarusIDE.DoJumpToCodeToolBossError;
    exit;
  end;

  // success
  Msg.MarkFixed;
end;

{ TQuickFix_HideWithIDEDirective }

procedure TQuickFix_HideWithIDEDirective.QuickFix(Fixes: TMsgQuickFixes; Msg: TMessageLine);
var
  Code: TCodeBuffer;

  procedure Fix(CurMsg: TMessageLine);
  var
    p: integer;
    aFilename: String;
  begin
    aFilename:=CurMsg.GetFullFilename;
    if (Code=nil) or (CompareFilenames(aFilename,Code.Filename)<>0) then begin
      Code:=CodeToolBoss.LoadFile(aFilename,true,false);
      if Code=nil then begin
        DebugLn(['TQuickFix_Hide.MenuItemClick ']);
        // ToDo: IDEMessageDialog
        exit;
      end;
    end;
    Code.LineColToPosition(CurMsg.Line,CurMsg.Column,p);
    if p<1 then begin
      DebugLn(['TQuickFix_Hide failed because invalid line, column']);
      {IDEMessageDialog(lisCCOErrorCaption,
        Format(lisInvalidLineColumnInMessage, [LineEnding, Msg.Msg]),
        mtError, [mbCancel]);}
      exit;
    end;

    debugln(['TQuickFix_Hide.MenuItemClick ',Code.Filename,' ',CurMsg.Line,',',CurMsg.Column]);
    Code.Insert(p,'{%H-}');
    CurMsg.Flags:=CurMsg.Flags+[mlfHiddenByIDEDirectiveValid,mlfHiddenByIDEDirective];
    CurMsg.MarkFixed;
  end;

var
  Tree: TAvgLvlTree;
  Node: TAvgLvlTreeNode;
  i: Integer;
begin
  Tree:=TAvgLvlTree.Create(@CompareMsgLinesSrcPos);
  try
    // get all messages to hide and sort them for position
    if Msg=nil then begin
      for i:=0 to Fixes.LineCount-1 do begin
        Msg:=Fixes.Lines[i];
        if not IsApplicable(Msg) then continue;
        Tree.Add(Msg);
      end;
    end else if IsApplicable(Msg) then
      Tree.Add(Msg);
    if Tree.Count=0 then exit;

    {if not LazarusIDE.BeginCodeTools then begin
      DebugLn(['TQuickFix_Hide failed because IDE busy']);
      exit;
    end;}

    // insert marks beginning with the highest line,column
    Code:=nil;
    Node:=Tree.FindHighest;
    while Node<>nil do begin
      Msg:=TMessageLine(Node.Data);
      Fix(Msg);
      Node:=Node.Precessor;
    end;
  finally
    Tree.Free;
  end;
end;

function TQuickFix_HideWithIDEDirective.IsApplicable(Msg: TMessageLine): boolean;
begin
  Result:=false;
  if (Msg.Urgency>=mluError)
  or (Msg.SubTool<>SubToolFPC)
  or (not Msg.HasSourcePosition)
  or (mlfHiddenByIDEDirective in Msg.Flags)
  then exit;
  Result:=true;
end;

procedure TQuickFix_HideWithIDEDirective.CreateMenuItems(Fixes: TMsgQuickFixes);
var
  Msg: TMessageLine;
  i: Integer;
  List: TFPList;
  aCaption: String;
  aFilename: String;
  MultiFile: Boolean;
begin
  List:=TFPList.Create;
  try
    MultiFile:=false;
    aFilename:='';
    for i:=0 to Fixes.LineCount-1 do begin
      Msg:=Fixes.Lines[i];
      if not IsApplicable(Msg) then continue;
      if aFilename='' then
        aFilename:=Msg.GetFullFilename
      else if CompareFilenames(aFilename,Msg.GetFullFilename)<>0 then
        MultiFile:=true;
      List.Add(Msg);
    end;
    if List.Count=0 then exit;
    if List.Count>1 then
      Fixes.AddMenuItem(Self, nil,
        lisHideAllHintsAndWarningsByInsertingIDEDirectivesH);

    for i:=0 to List.Count-1 do begin
      Msg:=TMessageLine(List[i]);
      if MultiFile then
        aCaption:=Msg.GetShortFilename
      else
        aCaption:='';
      if List.Count>1 then
        aCaption+='('+IntToStr(Msg.Line)+','+IntToStr(Msg.Column)+')';
      if aCaption<>'' then
        aCaption:=Format(lisHideMessageAtByInsertingIDEDirectiveH, [aCaption])
      else
        aCaption:=lisHideMessageByInsertingIDEDirectiveH;
      Fixes.AddMenuItem(Self,Msg,aCaption);
    end;
  finally
    List.Free;
  end;
end;

{ TIDEQuickFixes }

procedure TIDEQuickFixes.MenuItemClick(Sender: TObject);
var
  i: Integer;
  Info: TMenuItemInfo;
  ListsMsgLines: TFPList;
  MsgLines: TMessageLines;
  Cmd: TIDEMenuCommand;
begin
  Cmd:=Sender as TIDEMenuCommand;
  Info:=TMenuItemInfo(fMenuItemToInfo[Cmd]);
  if Info=nil then exit;
  try
    Info.Fix.QuickFix(Self,Info.Msg);
  finally
    ListsMsgLines:=TFPList.Create;
    try
      for i:=0 to LineCount-1 do begin
        MsgLines:=Lines[i].Lines;
        if ListsMsgLines.IndexOf(MsgLines)>=0 then continue;
        ListsMsgLines.Add(MsgLines);
      end;
      for i:=0 to ListsMsgLines.Count-1 do
        TMessageLines(ListsMsgLines[i]).ApplyFixedMarks;
    finally
      ListsMsgLines.Free;
    end;
  end;
end;

constructor TIDEQuickFixes.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  IDEQuickFixes:=Self;
  MsgQuickFixes:=Self;
  fMenuItemToInfo:=TPointerToPointerTree.Create;

  // init standard quickfixes
  // add them in the order of usefulness
  IDEQuickFixes.RegisterQuickFix(TQuickFixIdentifierNotFoundAddLocal.Create);
  IDEQuickFixes.RegisterQuickFix(TQuickFixLocalVariableNotUsed_Remove.Create);
  IDEQuickFixes.RegisterQuickFix(TQuickFixLocalVarNotInitialized_AddAssignment.Create);
  IDEQuickFixes.RegisterQuickFix(TQuickFixUnitNotFound_Remove.Create);
  IDEQuickFixes.RegisterQuickFix(TQuickFixClassWithAbstractMethods.Create);
  IDEQuickFixes.RegisterQuickFix(TQuickFixSrcPathOfPkgContains_OpenPkg.Create);

  // add as last (no fix, just hide message)
  IDEQuickFixes.RegisterQuickFix(TQuickFix_HideWithIDEDirective.Create);
  IDEQuickFixes.RegisterQuickFix(TQuickFix_HideWithCompilerOption.Create);
end;

destructor TIDEQuickFixes.Destroy;
begin
  fMenuItemToInfo.ClearWithFree;
  FreeAndNil(fMenuItemToInfo);
  MsgQuickFixes:=nil;
  IDEQuickFixes:=nil;
  inherited Destroy;
end;

procedure TIDEQuickFixes.OnPopupMenu(aParentMenuItem: TIDEMenuSection);
var
  i: Integer;
begin
  ParentMenuItem:=aParentMenuItem;
  try
    if LineCount=0 then exit;
    for i:=0 to Count-1 do
      Items[i].CreateMenuItems(Self);
  finally
    ParentMenuItem:=nil;
  end;
end;

procedure TIDEQuickFixes.SetMsgLines(aMsg: TMessageLine);
begin
  ClearLines;
  if aMsg<>nil then
    fMsg.Add(aMsg);
end;

procedure TIDEQuickFixes.AddMsgLine(aMsg: TMessageLine);
begin
  if (aMsg<>nil) and (fMsg.IndexOf(aMsg)<0) then
    fMsg.Add(aMsg);
end;

procedure TIDEQuickFixes.ClearLines;
var
  i: Integer;
begin
  fMenuItemToInfo.ClearWithFree;
  for i:=ComponentCount-1 downto 0 do
    if Components[i] is TMenuItem then
      Components[i].Free;
  fMsg.Clear;
end;

function TIDEQuickFixes.AddMenuItem(Fix: TMsgQuickFix; Msg: TMessageLine;
  aCaption: string; aTag: PtrInt): TIDEMenuCommand;
var
  Info: TMenuItemInfo;
begin
  if (Fix=nil) then
    raise Exception.Create('missing Fix');
  if (aCaption='') then
    raise Exception.Create('missing Caption');
  if (ParentMenuItem.Count>50) then exit(nil);
  Result:=RegisterIDEMenuCommand(ParentMenuItem,
    'MsgQuickFix'+IntToStr(ParentMenuItem.Count),aCaption,@MenuItemClick);
  Result.Tag:=aTag;
  Info:=TMenuItemInfo.Create;
  Info.Fix:=Fix;
  Info.Msg:=Msg;
  Info.MenuItem:=Result;
  fMenuItemToInfo[Result]:=Info;
end;

function TIDEQuickFixes.OpenMsg(Msg: TMessageLine): boolean;
var
  i: Integer;
begin
  Result:=false;
  if Msg=nil then exit;
  for i:=0 to Count-1 do begin
    Items[i].JumpTo(Msg,Result);
    if Result then exit;
  end;
end;

end.

