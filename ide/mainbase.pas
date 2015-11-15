{
 /***************************************************************************
                    mainbase.pas  -  the "integrated" in IDE
                    ----------------------------------------
  TMainIDEBase is the ancestor of TMainIDE. The various top level parts of the
  IDE (called bosses/managers) access the TMainIDE via TMainIDEBase.


  main.pp      - TMainIDE = class(TMainIDEBase)
                   The highest manager/boss of the IDE. Only lazarus.pp uses
                   this unit.
  mainbase.pas - TMainIDEBase = class(TMainIDEInterface)
                   The ancestor class used by (and only by) the other
                   bosses/managers like debugmanager, pkgmanager.
  mainintf.pas - TMainIDEInterface = class(TLazIDEInterface)
                   The interface class of the top level functions of the IDE.
                   TMainIDEInterface is used by functions/units, that uses
                   several different parts of the IDE (designer, source editor,
                   codetools), so they can't be added to a specific boss and
                   which are yet too small to become a boss of their own.
  lazideintf.pas - TLazIDEInterface = class(TComponent)
                   For designtime packages, this is the interface class of the
                   top level functions of the IDE.

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
}
unit MainBase;

{$mode objfpc}{$H+}

interface

{$I ide.inc}

uses
{$IFDEF IDE_MEM_CHECK}
  MemCheck,
{$ENDIF}
  Math, Classes, LCLType, LCLProc, LCLIntf, Buttons, Menus, ComCtrls,
  SysUtils, types, Controls, Graphics, ExtCtrls, Dialogs, LazFileUtils, Forms,
  CodeToolManager, AVL_Tree, SynEditKeyCmds, PackageIntf,
  // IDEIntf
  IDEImagesIntf, SrcEditorIntf, LazIDEIntf, MenuIntf, NewItemIntf,
  IDECommands, IDEWindowIntf, ProjectIntf, ToolBarIntf,
  // IDE
  LazConf, LazarusIDEStrConsts, ProjectDefs, Project, IDEDialogs,
  TransferMacros, ObjectInspector, PropEdits, BuildManager,
  EnvironmentOpts, EditorOptions, CompilerOptions, KeyMapping, IDEProcs,
  Debugger, IDEOptionDefs, Splash, Designer,
  SourceEditor, FindInFilesDlg,
  MainBar, MainIntf, SourceSynEditor, PseudoTerminalDlg,
  DesktopManager;

type
  TResetToolFlag = (
    rfInteractive,
    rfCloseOnDone,
    rfSuccessOnTrigger
  );
  TResetToolFlags = set of TResetToolFlag;

  { TMainIDEBase }

  TMainIDEBase = class(TMainIDEInterface)
  private
    FWindowMenuActiveForm: TCustomForm;
    FDisplayState: TDisplayState;
    procedure SetDisplayState(AValue: TDisplayState);
  protected
    FNeedUpdateHighlighters: boolean;

    function CreateMenuSeparator : TMenuItem;
    procedure CreateMenuItem(Section: TIDEMenuSection;
                             var MenuCommand: TIDEMenuCommand;
                             const MenuItemName, MenuItemCaption: String;
                             const bmpName: String = '';
                             mnuEnabled: Boolean = true;
                             mnuChecked: Boolean = false;
                             mnuVisible: Boolean = true);
    procedure CreateMenuSeparatorSection(ParentSection: TIDEMenuSection;
                             var Section: TIDEMenuSection; const AName: String);
    procedure CreateMenuSubSection(ParentSection: TIDEMenuSection;
                             var Section: TIDEMenuSection;
                             const AName, ACaption: String;
                             const bmpName: String = '');
    procedure CreateMainMenuItem(var Section: TIDEMenuSection;
                                 const MenuItemName, MenuItemCaption: String);
    procedure SetupMainMenu; virtual;
    procedure SetupFileMenu; virtual;
    procedure SetupEditMenu; virtual;
    procedure SetupSearchMenu; virtual;
    procedure SetupViewMenu; virtual;
    procedure SetupSourceMenu; virtual;
    procedure SetupProjectMenu; virtual;
    procedure SetupRunMenu; virtual;
    procedure SetupPackageMenu; virtual;
    procedure SetupToolsMenu; virtual;
    procedure SetupWindowsMenu; virtual;
    procedure SetupHelpMenu; virtual;

    procedure LoadMenuShortCuts; virtual;
    procedure SetToolStatus(const AValue: TIDEToolStatus); override;

    procedure DoMnuWindowClicked(Sender: TObject);
    procedure mnuOpenProjectClicked(Sender: TObject); virtual; abstract;
    procedure mnuOpenRecentClicked(Sender: TObject); virtual; abstract;
    procedure mnuWindowItemClick(Sender: TObject); virtual;
    procedure mnuCenterWindowItemClick(Sender: TObject); virtual;
    procedure mnuWindowSourceItemClick(Sender: TObject); virtual;

    procedure UpdateWindowMenu;

  public
    function DoResetToolStatus(AFlags: TResetToolFlags): boolean; virtual; abstract;

    constructor Create(TheOwner: TComponent); override;
    procedure StartIDE; virtual; abstract;
    destructor Destroy; override;
    procedure CreateOftenUsedForms; virtual; abstract;
    function GetMainBar: TComponent; override;
    procedure SetRecentProjectFilesMenu;
    procedure SetRecentFilesMenu;
    function BeginCodeTool(var ActiveSrcEdit: TSourceEditor;
                           out ActiveUnitInfo: TUnitInfo;
                           Flags: TCodeToolsFlags): boolean;
    function BeginCodeTool(ADesigner: TDesigner;
                           var ActiveSrcEdit: TSourceEditor;
                           out ActiveUnitInfo: TUnitInfo;
                           Flags: TCodeToolsFlags): boolean;
    procedure ActivateCodeToolAbortableMode;
    function OnCodeToolBossCheckAbort: boolean;
    procedure DoShowDesignerFormOfCurrentSrc(AComponentPaletteClassSelected: Boolean); virtual; abstract;
    function CreateDesignerForComponent(AnUnitInfo: TUnitInfo;
                        AComponent: TComponent): TCustomForm; virtual; abstract;
    procedure UpdateSaveMenuItemsAndButtons(UpdateSaveAll: boolean); virtual; abstract;

    procedure DoMergeDefaultProjectOptions(AProject: TProject);
    procedure DoSwitchToFormSrc(var ActiveSourceEditor:TSourceEditor;
      var ActiveUnitInfo:TUnitInfo);
    procedure DoSwitchToFormSrc(ADesigner: TIDesigner;
      var ActiveSourceEditor:TSourceEditor; var ActiveUnitInfo:TUnitInfo);

    procedure GetUnitInfoForDesigner(ADesigner: TIDesigner;
                              out ActiveSourceEditor: TSourceEditorInterface;
                              out ActiveUnitInfo: TUnitInfo); override;
    procedure GetCurrentUnitInfo(out ActiveSourceEditor: TSourceEditorInterface;
                              out ActiveUnitInfo: TUnitInfo); override;
    procedure GetCurrentUnit(out ActiveSourceEditor: TSourceEditor;
                             out ActiveUnitInfo: TUnitInfo); virtual; abstract;
    procedure GetDesignerUnit(ADesigner: TDesigner;
          out ActiveSourceEditor: TSourceEditor; out ActiveUnitInfo: TUnitInfo); virtual; abstract;
    procedure GetObjectInspectorUnit(
          out ActiveSourceEditor: TSourceEditor; out ActiveUnitInfo: TUnitInfo); virtual; abstract;
    procedure GetUnitWithForm(AForm: TCustomForm;
          out ActiveSourceEditor: TSourceEditor; out ActiveUnitInfo: TUnitInfo); virtual; abstract;
    procedure GetUnitWithPersistent(APersistent: TPersistent;
          out ActiveSourceEditor: TSourceEditor; out ActiveUnitInfo: TUnitInfo); virtual; abstract;
    procedure DoShowComponentList(State: TIWGetFormState = iwgfShowOnTop); virtual; abstract;

    function DoOpenMacroFile(Sender: TObject; const AFilename: string): TModalResult; override;

    procedure SetRecentSubMenu(Section: TIDEMenuSection; FileList: TStringList;
                               OnClickEvent: TNotifyEvent); override;
    procedure UpdateHighlighters(Immediately: boolean = false); override;

    procedure FindInFilesPerDialog(AProject: TProject); override;
    procedure FindInFiles(AProject: TProject; const FindText: string); override;

    procedure SelComponentPageButtonMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual; abstract;
    procedure SelComponentPageButtonClick(Sender: TObject); virtual; abstract;
  public
    property WindowMenuActiveForm: TCustomForm read FWindowMenuActiveForm write FWindowMenuActiveForm;
    property DisplayState: TDisplayState read FDisplayState write SetDisplayState;
  end;

  { TJumpToSectionToolButton }

  TJumpToSectionToolButton = class(TIDEToolButton)
  private
    procedure AddMenuItem(aCmd: TIDEMenuCommand);
  public
    procedure DoOnAdded; override;
    procedure RefreshMenu;
  end;

  { TSetBuildModeToolButton }

  TSetBuildModeToolButton = class(TIDEToolButton)
  private
    procedure RefreshMenu(Sender: TObject);
    procedure mnuSetBuildModeClick(Sender: TObject);
  public
    procedure DoOnAdded; override;

    class procedure UpdateHints;
  end;

  { TOpenFileToolButton }

  TOpenFileToolButton = class(TIDEToolButton)
  private
    procedure RefreshMenu(Sender: TObject);
    procedure mnuOpenFile(Sender: TObject);
    procedure mnuProjectFile(Sender: TObject);
  public
    procedure DoOnAdded; override;
  end;

  { TOpenFileMenuItem }

  TOpenFileMenuItem = class(TMenuItem)
  public
    FileName: string;
  end;

  { TNewFormUnitToolButton }

  TNewFormUnitToolButton = class(TIDEToolButton)
  private
    SetDefaultMenuItem: TMenuItem;

    procedure RefreshMenu(Sender: TObject);
    procedure mnuSetFormUnitTemplate(Sender: TObject);
  protected
    class function FindDefaultTemplateName(Category: TNewIDEItemCategory): string; virtual; abstract;
    class procedure SetTemplateName(const TemplateName: string); virtual; abstract;
    class procedure UpdateHint(const AHint: string); virtual; abstract;
  public
    procedure DoOnAdded; override;

    class procedure UpdateHints;
  end;

  { TNewUnitToolButton }

  TNewUnitToolButton = class(TNewFormUnitToolButton)
  protected
    class function FindDefaultTemplateName(Category: TNewIDEItemCategory): string; override;
    class procedure SetTemplateName(const TemplateName: string); override;
    class procedure UpdateHint(const AHint: string); override;
  end;

  { TNewFormToolButton }

  TNewFormToolButton = class(TNewFormUnitToolButton)
  protected
    class function FindDefaultTemplateName(Category: TNewIDEItemCategory): string; override;
    class procedure SetTemplateName(const TemplateName: string); override;
    class procedure UpdateHint(const AHint: string); override;
  end;

  { TNewFormUnitMenuItem }

  TNewFormUnitMenuItem = class(TMenuItem)
  public
    TemplateName: string;
  end;

function  GetMainIde: TMainIDEBase;

property MainIDE: TMainIDEBase read GetMainIde;

  { Normally the IDE builds itself with packages named in config files.
    When the IDE should keep the packages installed in the current executable
    set KeepInstalledPackages to true. }
var KeepInstalledPackages: boolean = false;

implementation

function GetMainIde: TMainIDEBase;
begin
  Result := TMainIDEBase(MainIDEInterface)
end;

{ TNewFormUnitToolButton }

procedure TNewFormUnitToolButton.DoOnAdded;
begin
  inherited DoOnAdded;

  PopupMenu := TPopupMenu.Create(Self);
  PopupMenu.OnPopup := @RefreshMenu;

  SetDefaultMenuItem:=TMenuItem.Create(PopupMenu);
  SetDefaultMenuItem.Caption:=lisSetDefault;
  PopupMenu.Items.Add(SetDefaultMenuItem);

  UpdateHints;
end;

procedure TNewFormUnitToolButton.mnuSetFormUnitTemplate(Sender: TObject);
begin
  SetTemplateName((Sender as TNewFormUnitMenuItem).TemplateName);
  EnvironmentOptions.Save(False);

  UpdateHints;
end;

procedure TNewFormUnitToolButton.RefreshMenu(Sender: TObject);
var
  TemplateName: String;
  Category: TNewIDEItemCategory;
  i: Integer;
  CurTemplate: TNewIDEItemTemplate;
  TheIndex: Integer;
  xItem: TNewFormUnitMenuItem;
begin
  Category:=NewIDEItems.FindCategoryByPath(FileDescGroupName,true);
  TemplateName:=FindDefaultTemplateName(Category);

  // create menu items
  TheIndex:=0;
  for i:=0 to Category.Count-1 do begin
    CurTemplate:=Category[i];
    if not CurTemplate.VisibleInNewDialog then continue;
    if TheIndex<SetDefaultMenuItem.Count then
      xItem:=SetDefaultMenuItem[TheIndex] as TNewFormUnitMenuItem
    else begin
      xItem:=TNewFormUnitMenuItem.Create(SetDefaultMenuItem);
      SetDefaultMenuItem.Add(xItem);
    end;
    xItem.OnClick:=@mnuSetFormUnitTemplate;
    xItem.Caption:=CurTemplate.LocalizedName;
    xItem.TemplateName:=CurTemplate.Name;
    xItem.ShowAlwaysCheckable:=true;
    xItem.Checked:=CompareText(TemplateName,CurTemplate.Name)=0;
    inc(TheIndex);
  end;
  // remove unneeded items
  while SetDefaultMenuItem.Count>TheIndex do
    SetDefaultMenuItem.Items[SetDefaultMenuItem.Count-1].Free;
end;

class procedure TNewFormUnitToolButton.UpdateHints;
var
  Category: TNewIDEItemCategory;
  TemplateName: String;
  Template: TNewIDEItemTemplate;
begin
  if not Assigned(NewIDEItems) then
    Exit;
  Category:=NewIDEItems.FindCategoryByPath(FileDescGroupName,true);
  TemplateName:=FindDefaultTemplateName(Category);
  if TemplateName<>'' then  //try to get the LocalizedName
  begin
    Template:=Category.FindTemplateByName(TemplateName);
    if Assigned(Template) then
      TemplateName := Template.LocalizedName;
  end;
  UpdateHint(Format(lisMenuNewCustom, [TemplateName]));
end;

{ TNewFormToolButton }

class function TNewFormToolButton.FindDefaultTemplateName(
  Category: TNewIDEItemCategory): string;
begin
  Result:=EnvironmentOptions.NewFormTemplate;
  if (Result='') or (Category.FindTemplateByName(Result)=nil) then
    Result:=FileDescNameLCLForm;
end;

class procedure TNewFormToolButton.SetTemplateName(const TemplateName: string);
begin
  EnvironmentOptions.NewFormTemplate:=TemplateName;
end;

class procedure TNewFormToolButton.UpdateHint(const AHint: string);
begin
  MainIDEBar.itmFileNewForm.Hint := AHint;
end;

{ TNewUnitToolButton }

class function TNewUnitToolButton.FindDefaultTemplateName(
  Category: TNewIDEItemCategory): string;
begin
  Result:=EnvironmentOptions.NewUnitTemplate;
  if (Result='') or (Category.FindTemplateByName(Result)=nil) then
    Result:=FileDescNamePascalUnit;
end;

class procedure TNewUnitToolButton.SetTemplateName(const TemplateName: string);
begin
  EnvironmentOptions.NewUnitTemplate:=TemplateName;
end;

class procedure TNewUnitToolButton.UpdateHint(const AHint: string);
begin
  MainIDEBar.itmFileNewUnit.Hint := AHint;
end;

{ TOpenFileToolButton }

procedure TOpenFileToolButton.DoOnAdded;
begin
  inherited DoOnAdded;

  DropdownMenu := TPopupMenu.Create(Self);
  DropdownMenu.OnPopup := @RefreshMenu;
  Style := tbsDropDown;
end;

procedure TOpenFileToolButton.mnuOpenFile(Sender: TObject);
begin
  if MainIDE.DoOpenEditorFile((Sender as TOpenFileMenuItem).FileName,-1,-1,
    [ofAddToRecent])=mrOk then
  begin
    MainIDE.SetRecentFilesMenu;
    MainIDE.SaveEnvironment;
  end;
end;

procedure TOpenFileToolButton.mnuProjectFile(Sender: TObject);
begin
  MainIDE.DoOpenProjectFile((Sender as TOpenFileMenuItem).FileName,[ofAddToRecent]);
end;

procedure TOpenFileToolButton.RefreshMenu(Sender: TObject);
  procedure AddFile(const AFileName: string; const AOnClick: TNotifyEvent);
  var
    AMenuItem: TOpenFileMenuItem;
  begin
    AMenuItem := TOpenFileMenuItem.Create(DropdownMenu);
    AMenuItem.OnClick := AOnClick;
    AMenuItem.FileName := AFileName;
    DropdownMenu.Items.Add(AMenuItem);
    AMenuItem.Caption := AFilename;
  end;

  procedure AddFiles(List: TStringList; MaxCount: integer; const AOnClick: TNotifyEvent);
  var
    i: integer;
  begin
    i := 0;
    while (i < List.Count) and (i < MaxCount) do
    begin
      AddFile(List[i], AOnClick);
      inc(i);
    end;
  end;

begin
  DropdownMenu.Items.Clear;

  // first add 8 recent projects
  AddFiles(EnvironmentOptions.RecentProjectFiles, 8, @mnuProjectFile);
  // add a separator
  DropdownMenu.Items.AddSeparator;
  // add 12 recent files
  AddFiles(EnvironmentOptions.RecentOpenFiles, 12, @mnuOpenFile);
end;

{ TSetBuildModeToolButton }

procedure TSetBuildModeToolButton.DoOnAdded;
begin
  inherited DoOnAdded;

  DropdownMenu := TPopupMenu.Create(Self);
  DropdownMenu.OnPopup := @RefreshMenu;
  Style := tbsDropDown;
  UpdateHints;
end;

procedure TSetBuildModeToolButton.mnuSetBuildModeClick(Sender: TObject);
var
  TheMenuItem: TMenuItem;
  TheIndex: LongInt;
  NewMode: TProjectBuildMode;
begin
  TheMenuItem := (Sender as TMenuItem);
  if TheMenuItem.Caption = '-' then exit;
  TheIndex := TheMenuItem.MenuIndex;
  if (TheIndex < 0) or (TheIndex >= Project1.BuildModes.Count) then exit;
  NewMode := Project1.BuildModes[TheIndex];
  if NewMode = Project1.ActiveBuildMode then exit;
  if not (MainIDE.ToolStatus in [itNone,itDebugger]) then begin
    IDEMessageDialog('Error','You can not change the build mode while compiling.',
      mtError,[mbOk]);
    exit;
  end;

  Project1.ActiveBuildMode := NewMode;
  MainBuildBoss.SetBuildTargetProject1(false);
  MainIDE.UpdateCaption;
end;

procedure TSetBuildModeToolButton.RefreshMenu(Sender: TObject);
var
  aMenu: TPopupMenu;
  CurIndex: Integer;
  i: Integer;

  procedure AddMode(CurMode: TProjectBuildMode);
  var
    AMenuItem: TMenuItem;
  begin
    if aMenu.Items.Count > CurIndex then
      AMenuItem := aMenu.Items[CurIndex]
    else
    begin
      AMenuItem := TMenuItem.Create(DropdownMenu);
      AMenuItem.Name := aMenu.Name + 'Mode' + IntToStr(CurIndex);
      AMenuItem.OnClick := @mnuSetBuildModeClick;
      aMenu.Items.Add(AMenuItem);
    end;
    AMenuItem.Caption := CurMode.GetCaption;
    AMenuItem.Checked := (Project1<>nil) and (Project1.ActiveBuildMode=CurMode);
    AMenuItem.ShowAlwaysCheckable:=true;
    inc(CurIndex);
  end;

begin
  // fill the PopupMenu:
  CurIndex := 0;
  aMenu := DropdownMenu;
  if Project1<>nil then
    for i:=0 to Project1.BuildModes.Count-1 do
      AddMode(Project1.BuildModes[i]);
  // remove unused menuitems
  while aMenu.Items.Count > CurIndex do
    aMenu.Items[aMenu.Items.Count - 1].Free;
end;

class procedure TSetBuildModeToolButton.UpdateHints;
const
  cActiveBuildMode = '[%s]';
begin
  if Assigned(Project1) then
    MainIDEBar.itmProjectBuildMode.Hint :=
      lisChangeBuildMode + MainIDEBar.itmProjectBuildMode.GetShortcut + sLineBreak +
      Format(cActiveBuildMode, [Project1.ActiveBuildMode.GetCaption]);
end;

{ TJumpToSectionToolButton }

procedure TJumpToSectionToolButton.DoOnAdded;
begin
  inherited DoOnAdded;
  RefreshMenu;
end;

procedure TJumpToSectionToolButton.AddMenuItem(aCmd: TIDEMenuCommand);
var
  xItem: TMenuItem;
begin
  xItem := TMenuItem.Create(DropdownMenu);
  DropdownMenu.Items.Add(xItem);
  xItem.Caption := aCmd.Caption;
  xItem.OnClick := aCmd.OnClick;
  xItem.ImageIndex := aCmd.ImageIndex;
end;

procedure TJumpToSectionToolButton.RefreshMenu;
begin
  if DropdownMenu = nil then
  begin
    DropdownMenu := TPopupMenu.Create(Self);
    if Assigned(FToolBar) then
      DropdownMenu.Images := FToolBar.Images;
    Style := tbsDropDown;
  end;
  DropdownMenu.Items.Clear;
  AddMenuItem(MainIDEBar.itmJumpToInterface);
  AddMenuItem(MainIDEBar.itmJumpToInterfaceUses);
  AddMenuItem(MainIDEBar.itmJumpToImplementation);
  AddMenuItem(MainIDEBar.itmJumpToImplementationUses);
  AddMenuItem(MainIDEBar.itmJumpToInitialization);
end;

//{$IFDEF LCLCarbon}
//var
//  mnuApple: TIDEMenuSection = nil;
//{$ENDIF}

{ TMainIDEBase }

procedure TMainIDEBase.mnuWindowItemClick(Sender: TObject);
var
  i: Integer;
  Form: TCustomForm;
  nfd: Boolean;
begin
  i:=Screen.CustomFormCount-1;
  while (i>=0) do begin
    Form:=Screen.CustomForms[i];
    nfd := EnvironmentOptions.Desktop.IDENameForDesignedFormList;
    if (nfd and (Form.Name=(Sender as TIDEMenuCommand).Caption))
    or ((not nfd) and (Form.Caption=(Sender as TIDEMenuCommand).Caption)) then
      begin
        IDEWindowCreators.ShowForm(Form,true);
        break;
      end;
    dec(i);
  end;
end;

procedure TMainIDEBase.mnuCenterWindowItemClick(Sender: TObject);
var
  i: Integer;
  Form: TCustomForm;
  r, NewBounds: TRect;
  nfd: Boolean;
begin
  i:=Screen.CustomFormCount-1;
  while (i>=0) do begin
    Form:=Screen.CustomForms[i];
    nfd := EnvironmentOptions.Desktop.IDENameForDesignedFormList;
    if (nfd and (Form.Name=(Sender as TIDEMenuCommand).Caption))
    or ((not nfd) and (Form.Caption=(Sender as TIDEMenuCommand).Caption)) then
    begin
      // show
      if not Form.IsVisible then
        IDEWindowCreators.ShowForm(Form,true);
      // move to monitor of main IDE bar
      Form:=GetParentForm(Form);
      if Form<>MainIDEBar then begin
        // center on main IDE
        Form.MakeFullyVisible(MainIDEBar.Monitor,true);
        debugln(['TMainIDEBase.mnuCenterWindowItemClick ',DbgSName(Form),' ',dbgs(Form.BoundsRect)]);
        r:=MainIDEBar.BoundsRect;
        if Form.Width<MainIDEBar.Width then
          NewBounds.Left:=(r.Left+r.Right-Form.Width) div 2
        else
          NewBounds.Left:=r.Left+50;
        if Form.Height<MainIDEBar.Height then
          NewBounds.Top:=(r.Top+r.Bottom-Form.Height) div 2
        else
          NewBounds.Top:=r.Top+50;
        NewBounds.Right:=NewBounds.Left+Max(70,Form.Width);
        NewBounds.Bottom:=NewBounds.Top+Max(70,Form.Height);
        debugln(['TMainIDEBase.mnuCenterWindowItemClick New=',dbgs(NewBounds)]);
        Form.BoundsRect:=NewBounds;
        Form.WindowState:=wsNormal;
        Form.BringToFront;
      end;
      break;
    end;
    dec(i);
  end;
end;

procedure TMainIDEBase.mnuWindowSourceItemClick(Sender: TObject);
var
  i: LongInt;
begin
  if SourceEditorManager = nil then exit;
  i:=(sender as TIDEMenuCommand).tag;
  if (i<0) or (i>=SourceEditorManager.SourceEditorCount) then exit;
  SourceEditorManager.ActiveEditor := SourceEditorManager.SourceEditors[i];
  SourceEditorManager.ShowActiveWindowOnTop(True);
end;

procedure TMainIDEBase.SetToolStatus(const AValue: TIDEToolStatus);
begin
  if ToolStatus=AValue then exit;
  inherited SetToolStatus(AValue);
  UpdateCaption;
end;

constructor TMainIDEBase.Create(TheOwner: TComponent);
begin
  // Do not own everything in one big component hierachy. Otherwise the
  // notifications slow down everything
  fOwningComponent:=TComponent.Create(nil);
  inherited Create(TheOwner);
end;

destructor TMainIDEBase.Destroy;
begin
  FreeThenNil(fOwningComponent);
  inherited Destroy;
end;

procedure TMainIDEBase.GetUnitInfoForDesigner(ADesigner: TIDesigner;
  out ActiveSourceEditor: TSourceEditorInterface; out ActiveUnitInfo: TUnitInfo);
var
  SrcEdit: TSourceEditor;
begin
  ActiveSourceEditor:=nil;
  ActiveUnitInfo:=nil;
  if ADesigner is TDesigner then begin
    GetDesignerUnit(TDesigner(ADesigner),SrcEdit,ActiveUnitInfo);
    ActiveSourceEditor:=SrcEdit;
  end;
end;

procedure TMainIDEBase.GetCurrentUnitInfo(
  out ActiveSourceEditor: TSourceEditorInterface; out ActiveUnitInfo: TUnitInfo);
var
  ASrcEdit: TSourceEditor;
  AnUnitInfo: TUnitInfo;
begin
  GetCurrentUnit(ASrcEdit, AnUnitInfo);
  ActiveSourceEditor:=ASrcEdit;
  ActiveUnitInfo:=AnUnitInfo;
end;

function TMainIDEBase.GetMainBar: TComponent;
begin
  Result:=MainIDEBar;
end;

procedure TMainIDEBase.SetRecentProjectFilesMenu;
begin
  SetRecentSubMenu(itmProjectRecentOpen,
                   EnvironmentOptions.RecentProjectFiles,
                   @mnuOpenProjectClicked);
end;

procedure TMainIDEBase.SetRecentFilesMenu;
begin
  SetRecentSubMenu(itmFileRecentOpen,
                   EnvironmentOptions.RecentOpenFiles,
                   @mnuOpenRecentClicked);
end;

function TMainIDEBase.BeginCodeTool(var ActiveSrcEdit: TSourceEditor;
  out ActiveUnitInfo: TUnitInfo; Flags: TCodeToolsFlags): boolean;
begin
  Result:=BeginCodeTool(nil,ActiveSrcEdit,ActiveUnitInfo,Flags);
end;

function TMainIDEBase.BeginCodeTool(ADesigner: TDesigner;
  var ActiveSrcEdit: TSourceEditor; out ActiveUnitInfo: TUnitInfo;
  Flags: TCodeToolsFlags): boolean;
var
  Edit: TIDESynEditor;
begin
  Result:=false;
  if (ctfUseGivenSourceEditor in Flags) and (Project1<>nil)
  and (ActiveSrcEdit<>nil) then begin
    ActiveUnitInfo := Project1.EditorInfoWithEditorComponent(ActiveSrcEdit).UnitInfo;
  end
  else begin
    ActiveSrcEdit:=nil;
    ActiveUnitInfo:=nil;
  end;

  // check global stati
  if (ToolStatus in [itCodeTools,itCodeToolAborting]) then begin
    debugln('TMainIDEBase.BeginCodeTool impossible ',dbgs(ord(ToolStatus)));
    exit;
  end;
  if (not (ctfSourceEditorNotNeeded in Flags)) and (SourceEditorManager.SourceEditorCount=0)
  then begin
    //DebugLn('TMainIDEBase.BeginCodeTool no source editor');
    exit;
  end;

  // check source editor
  if not (ctfUseGivenSourceEditor in Flags) then begin
    if ctfSwitchToFormSource in Flags then
      DoSwitchToFormSrc(ADesigner,ActiveSrcEdit,ActiveUnitInfo)
    else if ADesigner<>nil then
      GetDesignerUnit(ADesigner,ActiveSrcEdit,ActiveUnitInfo)
    else
      GetCurrentUnit(ActiveSrcEdit,ActiveUnitInfo);
  end;
  if (not (ctfSourceEditorNotNeeded in Flags)) and
     ((ActiveSrcEdit=nil) or (ActiveUnitInfo=nil))
  then exit;

  // init codetools
  SaveSourceEditorChangesToCodeCache(nil);
  if ActiveSrcEdit<>nil then begin
    Edit:=ActiveSrcEdit.EditorComponent;
    CodeToolBoss.VisibleEditorLines:=Edit.LinesInWindow;
    CodeToolBoss.TabWidth:=Edit.TabWidth;
    CodeToolBoss.IndentSize:=Edit.BlockIndent+Edit.BlockTabIndent*Edit.TabWidth;
    CodeToolBoss.UseTabs:=Edit.BlockTabIndent>0;
  end else begin
    CodeToolBoss.VisibleEditorLines:=25;
    CodeToolBoss.TabWidth:=EditorOpts.TabWidth;
    CodeToolBoss.IndentSize:=EditorOpts.BlockIndent+EditorOpts.BlockTabIndent*EditorOpts.TabWidth;
    CodeToolBoss.UseTabs:=EditorOpts.BlockTabIndent>0;
  end;

  if ctfActivateAbortMode in Flags then
    ActivateCodeToolAbortableMode;

  Result:=true;
end;

procedure TMainIDEBase.ActivateCodeToolAbortableMode;
begin
  if ToolStatus=itNone then
    RaiseException('TMainIDEBase.ActivateCodeToolAbortableMode Error 1');
  ToolStatus:=itCodeTools;
  CodeToolBoss.OnCheckAbort:=@OnCodeToolBossCheckAbort;
  CodeToolBoss.Abortable:=true;
end;

function TMainIDEBase.OnCodeToolBossCheckAbort: boolean;
begin
  Result:=true;
  if ToolStatus<>itCodeTools then exit;
  Application.ProcessMessages;
  Result:=ToolStatus<>itCodeTools;
end;

procedure TMainIDEBase.DoMergeDefaultProjectOptions(AProject: TProject);
var
  AFilename: String;
  ShortFilename: String;
begin
  // load default project options if exists
  AFilename:=AppendPathDelim(GetPrimaryConfigPath)+DefaultProjectOptionsFilename;
  if not FileExistsUTF8(AFilename) then
    CopySecondaryConfigFile(DefaultProjectOptionsFilename);
  if FileExistsUTF8(AFilename) then begin
    if AProject.ReadProject(AFilename,nil,True)<>mrOk then
      DebugLn(['TMainIDEBase.DoLoadDefaultCompilerOptions failed']);
  end else begin
    // old way (<0.9.31)
    // load default compiler options if exists
    AFilename:=AppendPathDelim(GetPrimaryConfigPath)+DefaultProjectCompilerOptionsFilename;
    if not FileExistsUTF8(AFilename) then
      CopySecondaryConfigFile(DefaultProjectCompilerOptionsFilename);
    if not FileExistsUTF8(AFilename) then exit;
    if AProject.CompilerOptions.LoadFromFile(AFilename)<>mrOk then
      DebugLn(['TMainIDEBase.DoLoadDefaultCompilerOptions failed']);
  end;

  // change target file name
  AFilename:=ExtractFileName(AProject.CompilerOptions.TargetFilename);
  if AFilename='' then
    exit; // using default -> ok
  if CompareFilenames(AFilename,ExtractFilename(AProject.ProjectInfoFile))=0
  then exit; // target file name and project name fit -> ok

  // change target file to project name
  ShortFilename:=ExtractFileNameOnly(AProject.ProjectInfoFile);
  if ShortFilename<>'' then
    AProject.CompilerOptions.TargetFilename:=
      ExtractFilePath(AProject.CompilerOptions.TargetFilename)
        +ShortFilename+ExtractFileExt(AFilename);
  AProject.CompilerOptions.Modified:=false;
end;

procedure TMainIDEBase.DoSwitchToFormSrc(var ActiveSourceEditor: TSourceEditor;
  var ActiveUnitInfo: TUnitInfo);
begin
  DoSwitchToFormSrc(nil,ActiveSourceEditor,ActiveUnitInfo);
end;

procedure TMainIDEBase.DoSwitchToFormSrc(ADesigner: TIDesigner;
  var ActiveSourceEditor: TSourceEditor; var ActiveUnitInfo: TUnitInfo);
begin
  if (ADesigner<>nil) then
    ActiveUnitInfo:=Project1.UnitWithComponent(ADesigner.LookupRoot)
  else if (GlobalDesignHook.LookupRoot<>nil)
  and (GlobalDesignHook.LookupRoot is TComponent) then
    ActiveUnitInfo:=Project1.UnitWithComponent(TComponent(GlobalDesignHook.LookupRoot))
  else
    ActiveUnitInfo:=nil;
  if (ActiveUnitInfo<>nil) and (ActiveUnitInfo.OpenEditorInfoCount > 0) then begin
    ActiveSourceEditor := TSourceEditor(ActiveUnitInfo.OpenEditorInfo[0].EditorComponent);
    SourceEditorManagerIntf.ActiveEditor := ActiveSourceEditor;
  end
  else
    ActiveSourceEditor:=nil;
end;

procedure TMainIDEBase.DoMnuWindowClicked(Sender: TObject);
begin
  UpdateWindowMenu;
end;

procedure TMainIDEBase.SetDisplayState(AValue: TDisplayState);
begin
  if FDisplayState=AValue then Exit;
  FDisplayState:=AValue;
  {$IFDEF VerboseIDEDisplayState}
  debugln(['TMainIDEBase.SetDisplayState ',dbgs(DisplayState)]);
  {$ENDIF}
end;

function TMainIDEBase.CreateMenuSeparator : TMenuItem;
begin
  Result := TMenuItem.Create(MainIDEBar);
  Result.Caption := '-';
end;

procedure TMainIDEBase.CreateMenuItem(Section: TIDEMenuSection;
  var MenuCommand: TIDEMenuCommand; const MenuItemName, MenuItemCaption: String;
  const bmpName: String; mnuEnabled: Boolean; mnuChecked: Boolean;
  mnuVisible: Boolean);
begin
  MenuCommand:=RegisterIDEMenuCommand(Section,MenuItemName,MenuItemCaption);
  MenuCommand.Enabled:=mnuEnabled;
  MenuCommand.Checked:=mnuChecked;
  MenuCommand.Visible:=mnuVisible;
  if bmpName<>'' then
    MenuCommand.ImageIndex := IDEImages.LoadImage(16, bmpName);
end;

procedure TMainIDEBase.CreateMenuSeparatorSection(
  ParentSection: TIDEMenuSection; var Section: TIDEMenuSection;
  const AName: String);
begin
  Section:=RegisterIDEMenuSection(ParentSection,AName);
  Section.ChildsAsSubMenu := false;
end;

procedure TMainIDEBase.CreateMenuSubSection(ParentSection: TIDEMenuSection;
  var Section: TIDEMenuSection; const AName, ACaption: String;
  const bmpName: String = '');
begin
  Section:=RegisterIDESubMenu(ParentSection,AName,ACaption);
  if bmpName<>'' then
    Section.ImageIndex := IDEImages.LoadImage(16, bmpName);
end;

procedure TMainIDEBase.CreateMainMenuItem(var Section: TIDEMenuSection;
  const MenuItemName, MenuItemCaption: String);
begin
  Section:=RegisterIDESubMenu(mnuMain,MenuItemName,MenuItemCaption);
end;

procedure TMainIDEBase.SetupMainMenu;
begin
  MainIDEBar.mnuMainMenu := TMainMenu.Create(MainIDEBar);
  MainIDEBar.mnuMainMenu.Images := IDEImages.Images_16;
  with MainIDEBar do begin
    mnuMain:=RegisterIDEMenuRoot('IDEMainMenu',nil);
    {$ifdef LCLCarbon}
    // Under Apple there is a special policy: every application should create
    // a special Apple menu and put Quit, About there.
    // See issue: http://bugs.freepascal.org/view.php?id=12294
    // See http://lists.apple.com/archives/carbon-development/2002/Apr/msg01183.html, for details
    //CreateMainMenuItem(mnuApple,'AppleApplication','');
    {$endif}
    CreateMainMenuItem(mnuFile,'File',lisMenuFile);
    CreateMainMenuItem(mnuEdit,'Edit',lisMenuEdit);
    CreateMainMenuItem(mnuSearch,'Search',lisMenuSearch);
    CreateMainMenuItem(mnuView,'View',lisMenuView);
    CreateMainMenuItem(mnuSource,'Source',lisMenuSource);
    CreateMainMenuItem(mnuProject,'Project',lisMenuProject);
    CreateMainMenuItem(mnuRun,'Run',lisMenuRun);
    CreateMainMenuItem(mnuPackage,'Package',lisMenuPackage);
    mnuComponent:=mnuPackage;
    CreateMainMenuItem(mnuTools,'Tools',lisMenuTools);
    CreateMainMenuItem(mnuWindow,'Window',lisMenuWindow);
    mnuWindow.OnClick  := @DoMnuWindowClicked;
    CreateMainMenuItem(mnuHelp,'Help',lisMenuHelp);
  end;
end;

procedure TMainIDEBase.SetupFileMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuFile,itmFileNew,'itmFileNew');
    ParentMI:=itmFileNew;
    CreateMenuItem(ParentMI,itmFileNewUnit,'itmFileNewUnit',lisMenuNewUnit,'item_unit');
    CreateMenuItem(ParentMI,itmFileNewForm,'itmFileNewForm',lisMenuNewForm,'item_form');
    CreateMenuItem(ParentMI,itmFileNewOther,'itmFileNewOther',lisMenuNewOther,'menu_new');

    CreateMenuSeparatorSection(mnuFile,itmFileOpenSave,'itmFileOpenSave');
    ParentMI:=itmFileOpenSave;
    CreateMenuItem(ParentMI, itmFileOpen, 'itmFileOpen', lisMenuOpen, 'laz_open');
    CreateMenuItem(ParentMI,itmFileRevert,'itmFileRevert',lisMenuRevert, 'menu_file_revert');
    CreateMenuSubSection(ParentMI,itmFileRecentOpen,'itmFileRecentOpen',lisMenuOpenRecent);
    CreateMenuItem(ParentMI,itmFileSave,'itmFileSave',lisMenuSave,'laz_save');
    CreateMenuItem(ParentMI,itmFileSaveAs,'itmFileSaveAs',lisMenuSaveAs,'menu_saveas');
    CreateMenuItem(ParentMI,itmFileSaveAll,'itmFileSaveAll',lisSaveAll,'menu_save_all');
    CreateMenuItem(ParentMI,itmFileExportHtml,'itmFileExportHtml',lisExportHtml);
    CreateMenuItem(ParentMI,itmFileClose,'itmFileClose',lisMenuCloseEditorFile,'menu_close',false);
    CreateMenuItem(ParentMI,itmFileCloseAll,'itmFileCloseAll',lisMenuCloseAll,'menu_close_all',false);

    CreateMenuSeparatorSection(mnuFile,itmFileDirectories,'itmFileDirectories');
    ParentMI:=itmFileDirectories;
    CreateMenuItem(ParentMI,itmFileCleanDirectory,'itmFileCleanDirectory',lisMenuCleanDirectory, 'menu_clean');

    CreateMenuSeparatorSection(mnuFile,itmFileIDEStart,'itmFileIDEStart');
    ParentMI:=itmFileIDEStart;
    CreateMenuItem(ParentMI,itmFileRestart,'itmFileRestart',lisRestart, 'laz_refresh');
    CreateMenuItem(ParentMI,itmFileQuit,'itmFileQuit',lisBtnQuit, 'menu_exit');
  end;
end;

procedure TMainIDEBase.SetupEditMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuEdit,itmEditReUndo,'itmEditReUndo');
    ParentMI:=itmEditReUndo;
    CreateMenuItem(ParentMI,itmEditUndo,'itmEditUndo',lisUndo,'menu_undo');
    CreateMenuItem(ParentMI,itmEditRedo,'itmEditRedo',lisRedo,'menu_redo');

    CreateMenuSeparatorSection(mnuEdit,itmEditClipboard,'itmEditClipboard');
    ParentMI:=itmEditClipboard;
    CreateMenuItem(ParentMI,itmEditCut,'itmEditCut',lisCut,'laz_cut');
    CreateMenuItem(ParentMI,itmEditCopy,'itmEditCopy',lisCopy,'laz_copy');
    CreateMenuItem(ParentMI,itmEditPaste,'itmEditPaste',lisPaste,'laz_paste');

    // "Select" menu items
    CreateMenuSeparatorSection(mnuEdit,itmEditSelect,'itmEditSelect');
    ParentMI:=itmEditSelect;
    CreateMenuItem(ParentMI,itmEditSelectAll,'itmEditSelectAll',lisMenuSelectAll, 'menu_select_all');
    CreateMenuItem(ParentMI,itmEditSelectToBrace,'itmEditSelectToBrace',lisMenuSelectToBrace);
    CreateMenuItem(ParentMI,itmEditSelectCodeBlock,'itmEditSelectCodeBlock',lisMenuSelectCodeBlock);
    CreateMenuItem(ParentMI,itmEditSelectWord,'itmEditSelectWord',lisMenuSelectWord);
    CreateMenuItem(ParentMI,itmEditSelectLine,'itmEditSelectLine',lisMenuSelectLine);
    CreateMenuItem(ParentMI,itmEditSelectParagraph,'itmEditSelectParagraph',lisMenuSelectParagraph);

    // "Char Conversion" menu items
    CreateMenuSeparatorSection(mnuEdit,itmEditBlockActions,'itmEditBlockActions');
    ParentMI:=itmEditBlockActions;
    CreateMenuItem(ParentMI,itmEditIndentBlock,'itmEditIndentBlock',lisMenuIndentSelection,'menu_indent');
    CreateMenuItem(ParentMI,itmEditUnindentBlock,'itmEditUnindentBlock',lisMenuUnindentSelection,'menu_unindent');
    CreateMenuItem(ParentMI,itmEditUpperCaseBlock,'itmEditUpperCaseBlock',lisMenuUpperCaseSelection, 'menu_edit_uppercase');
    CreateMenuItem(ParentMI,itmEditLowerCaseBlock,'itmEditLowerCaseBlock',lisMenuLowerCaseSelection, 'menu_edit_lowercase');
    CreateMenuItem(ParentMI,itmEditSwapCaseBlock,'itmEditSwapCaseBlock',lisMenuSwapCaseSelection, 'menu_edit_uppercase');
    CreateMenuItem(ParentMI,itmEditSortBlock,'itmEditSortBlock',lisMenuSortSelection, 'menu_edit_sort');
    CreateMenuItem(ParentMI,itmEditTabsToSpacesBlock,'itmEditTabsToSpacesBlock',lisMenuTabsToSpacesSelection);
    CreateMenuItem(ParentMI,itmEditSelectionBreakLines,'itmEditSelectionBreakLines',lisMenuBeakLinesInSelection);

    // *** insert text ***:
    CreateMenuSeparatorSection(mnuEdit,itmEditInsertions,'itmEditInsertions');
    ParentMI:=itmEditInsertions;
    CreateMenuItem(ParentMI,itmEditInsertCharacter,'itmEditInsertCharacter',lisMenuInsertCharacter);
  end;
end;

procedure TMainIDEBase.SetupSearchMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuSearch,itmSearchFindReplace,'itmSearchFindReplace');
    ParentMI:=itmSearchFindReplace;

    CreateMenuItem(ParentMI,itmSearchFind, 'itmSearchFind', lisMenuFind2, 'menu_search_find');
    CreateMenuItem(ParentMI,itmSearchFindNext,'itmSearchFindNext',lisMenuFindNext, 'menu_search_find_next');
    CreateMenuItem(ParentMI,itmSearchFindPrevious,'itmSearchFindPrevious',lisMenuFindPrevious, 'menu_search_find_previous');
    CreateMenuItem(ParentMI,itmSearchFindInFiles,'itmSearchFindInFiles',lisMenuFindInFiles, 'menu_search_files');
    CreateMenuItem(ParentMI, itmSearchReplace, 'itmSearchReplace', lisBtnDlgReplace, 'menu_search_replace');
    CreateMenuItem(ParentMI,itmIncrementalFind,'itmIncrementalFind',lisMenuIncrementalFind, 'menu_search_incremental');

    CreateMenuSeparatorSection(mnuSearch,itmJumpings,'itmJumpings');
    ParentMI:=itmJumpings;

    CreateMenuItem(ParentMI,itmGotoLine,'itmGotoLine',lisMenuGotoLine, 'menu_goto_line');
    CreateMenuItem(ParentMI,itmJumpBack,'itmJumpBack',lisMenuJumpBack, 'menu_search_jumpback');
    CreateMenuItem(ParentMI,itmJumpForward,'itmJumpForward',lisMenuJumpForward, 'menu_search_jumpforward');
    CreateMenuItem(ParentMI,itmAddJumpPoint,'itmAddJumpPoint',lisMenuAddJumpPointToHistory);
    CreateMenuItem(ParentMI,itmJumpToNextError,'itmJumpToNextError',lisMenuJumpToNextError);
    CreateMenuItem(ParentMI,itmJumpToPrevError,'itmJumpToPrevError',lisMenuJumpToPrevError);

    CreateMenuSubSection(ParentMI,itmJumpToSection,'itmJumpToSection',lisMenuJumpTo);
    ParentMI:=itmJumpToSection;

    CreateMenuItem(ParentMI,itmJumpToInterface,'itmJumpToInterface',lisMenuJumpToInterface, 'menu_jumpto_interface');
    CreateMenuItem(ParentMI,itmJumpToInterfaceUses,'itmJumpToInterfaceUses',lisMenuJumpToInterfaceUses, 'menu_jumpto_interfaceuses');
    CreateMenuItem(ParentMI,itmJumpToImplementation,'itmJumpToImplementation',lisMenuJumpToImplementation, 'menu_jumpto_implementation');
    CreateMenuItem(ParentMI,itmJumpToImplementationUses,'itmJumpToImplementationUses',lisMenuJumpToImplementationUses, 'menu_jumpto_implementationuses');
    CreateMenuItem(ParentMI,itmJumpToInitialization,'itmJumpToInitialization',lisMenuJumpToInitialization, 'menu_jumpto_initialization');

    CreateMenuSeparatorSection(mnuSearch,itmBookmarks,'itmBookmarks');
    ParentMI:=itmBookmarks;

    CreateMenuItem(ParentMI,itmSetFreeBookmark,'itmSetFreeBookmark',lisMenuSetFreeBookmark, 'menu_search_set_bookmark');
    CreateMenuItem(ParentMI,itmJumpToNextBookmark,'itmJumpToNextBookmark',lisMenuJumpToNextBookmark, 'menu_search_next_bookmark');
    CreateMenuItem(ParentMI,itmJumpToPrevBookmark,'itmJumpToPrevBookmark',lisMenuJumpToPrevBookmark, 'menu_search_previous_bookmark');

    CreateMenuSeparatorSection(mnuSearch,itmCodeToolSearches,'itmCodeToolSearches');
    ParentMI:=itmCodeToolSearches;

    CreateMenuItem(ParentMI,itmFindBlockOtherEnd,'itmFindBlockOtherEnd',lisMenuFindBlockOtherEndOfCodeBlock);
    CreateMenuItem(ParentMI,itmFindBlockStart,'itmFindBlockStart',lisMenuFindCodeBlockStart);
    CreateMenuItem(ParentMI,itmFindDeclaration,'itmFindDeclaration',lisMenuFindDeclarationAtCursor);
    CreateMenuItem(ParentMI,itmOpenFileAtCursor,'itmOpenFileAtCursor',lisMenuOpenFilenameAtCursor,'menu_search_openfile_atcursor');
    CreateMenuItem(ParentMI,itmGotoIncludeDirective,'itmGotoIncludeDirective',lisMenuGotoIncludeDirective);
    CreateMenuItem(ParentMI,itmSearchFindIdentifierRefs,'itmSearchFindIdentifierRefs',lisMenuFindIdentifierRefs);
    CreateMenuItem(ParentMI,itmSearchProcedureList,'itmSearchProcedureList',lisMenuProcedureList);
  end;
end;

procedure TMainIDEBase.SetupViewMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuView,itmViewMainWindows,'itmViewMainWindows');
    ParentMI:=itmViewMainWindows;
    CreateMenuItem(ParentMI,itmViewToggleFormUnit,'itmViewToggleFormUnit',lisMenuViewToggleFormUnit, 'menu_view_toggle_form_unit');
    CreateMenuItem(ParentMI,itmViewInspector,'itmViewInspector',lisMenuViewObjectInspector, 'menu_view_inspector');
    CreateMenuItem(ParentMI,itmViewSourceEditor,'itmViewSourceEditor',lisMenuViewSourceEditor, 'menu_view_source_editor');
    CreateMenuItem(ParentMI,itmViewMessage,'itmViewMessage',lisMenuViewMessages);
    CreateMenuItem(ParentMI,itmViewCodeExplorer,'itmViewCodeExplorer',lisMenuViewCodeExplorer, 'menu_view_code_explorer');
    CreateMenuItem(ParentMI,itmViewFPDocEditor,'itmViewFPDocEditor',lisFPDocEditor);
    CreateMenuItem(ParentMI,itmViewCodeBrowser,'itmViewCodeBrowser',lisMenuViewCodeBrowser, 'menu_view_code_browser');
    CreateMenuItem(ParentMI,itmSourceUnitDependencies,'itmSourceUnitDependencies',lisMenuViewUnitDependencies);
    CreateMenuItem(ParentMI,itmViewRestrictionBrowser,'itmViewRestrictionBrowser',lisMenuViewRestrictionBrowser, 'menu_view_rectriction_browser');
    CreateMenuItem(ParentMI,itmViewComponents,'itmViewComponents',lisMenuViewComponents);
    CreateMenuItem(ParentMI,itmJumpHistory,'itmJumpHistory',lisMenuViewJumpHistory);
    CreateMenuItem(ParentMI,itmMacroListView,'itmMacroListView',lisMenuMacroListView);

    CreateMenuSeparatorSection(mnuView,itmViewDesignerWindows,'itmViewDesignerWindows');
    ParentMI:=itmViewDesignerWindows;
    CreateMenuItem(ParentMI,itmViewAnchorEditor,'itmViewAnchorEditor',lisMenuViewAnchorEditor,'menu_view_anchor_editor');
    CreateMenuItem(ParentMI,itmViewTabOrder,'itmViewTabOrder',lisMenuViewTabOrder,'tab_order');

    CreateMenuSeparatorSection(mnuView,itmViewSecondaryWindows,'itmViewSecondaryWindows');
    ParentMI:=itmViewSecondaryWindows;
    CreateMenuItem(ParentMI,itmViewSearchResults,'itmViewSearchResults',lisMenuViewSearchResults);
    CreateMenuSubSection(ParentMI,itmViewDebugWindows,'itmViewDebugWindows',lisMenuDebugWindows,'debugger');
    begin
      CreateMenuItem(itmViewDebugWindows,itmViewWatches,'itmViewWatches',lisMenuViewWatches,'debugger_watches');
      CreateMenuItem(itmViewDebugWindows,itmViewBreakPoints,'itmViewBreakPoints',lisMenuViewBreakPoints,'debugger_breakpoints');
      CreateMenuItem(itmViewDebugWindows,itmViewLocals,'itmViewLocals',lisMenuViewLocalVariables);
      if HasConsoleSupport then
        CreateMenuItem(itmViewDebugWindows,itmViewPseudoTerminal,'itmViewPseudoTerminal',lisMenuViewPseudoTerminal)
      else
        itmViewPseudoTerminal := nil;
      CreateMenuItem(itmViewDebugWindows,itmViewRegisters,'itmViewRegisters',lisMenuViewRegisters);
      CreateMenuItem(itmViewDebugWindows,itmViewCallStack,'itmViewCallStack',lisMenuViewCallStack,'debugger_call_stack');
      CreateMenuItem(itmViewDebugWindows,itmViewThreads,'itmViewThreads',lisMenuViewThreads);
      CreateMenuItem(itmViewDebugWindows,itmViewAssembler,'itmViewAssembler',lisMenuViewAssembler);
      CreateMenuItem(itmViewDebugWindows,itmViewDebugEvents,'itmViewDebugEvents',lisMenuViewDebugEvents,'debugger_event_log');
      CreateMenuItem(itmViewDebugWindows,itmViewDebugOutput,'itmViewDebugOutput',lisMenuViewDebugOutput,'debugger_output');
      CreateMenuItem(itmViewDebugWindows,itmViewDbgHistory,'itmViewDbgHistory',lisMenuViewHistory);
    end;
    CreateMenuSubSection(ParentMI, itmViewIDEInternalsWindows, 'itmViewIDEInternalsWindows', lisMenuIDEInternals);
    begin
      CreateMenuItem(itmViewIDEInternalsWindows, itmViewFPCInfo, 'itmViewFPCInfo', lisMenuAboutFPC);
      CreateMenuItem(itmViewIDEInternalsWindows, itmViewIDEInfo, 'itmViewIDEInfo', lisAboutIDE);
      CreateMenuItem(itmViewIDEInternalsWindows, itmViewNeedBuild, 'itmViewNeedBuild', lisMenuWhatNeedsBuilding);
      {$IFDEF EnableFPDocSearch}
      CreateMenuItem(itmViewIDEInternalsWindows, itmSearchInFPDocFiles,'itmSearchInFPDocFiles','Search in FPDoc files');
      {$ENDIF}
    end;
  end;
end;

procedure TMainIDEBase.SetupSourceMenu;
var
  ParentMI, SubParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuSource,itmSourceBlockActions,'itmSourceBlockActions');
    ParentMI:=itmSourceBlockActions;
    CreateMenuItem(ParentMI,itmSourceCommentBlock,'itmSourceCommentBlock',lisMenuCommentSelection, 'menu_comment');
    CreateMenuItem(ParentMI,itmSourceUncommentBlock,'itmSourceUncommentBlock',lisMenuUncommentSelection, 'menu_uncomment');
    CreateMenuItem(ParentMI,itmSourceToggleComment,'itmSourceToggleComment',lisMenuToggleComment, 'menu_comment');
    CreateMenuItem(ParentMI,itmSourceEncloseBlock,'itmSourceEncloseBlock',lisMenuEncloseSelection);
    CreateMenuItem(ParentMI,itmSourceEncloseInIFDEF,'itmSourceEncloseInIFDEF',lisMenuEncloseInIFDEF);
    CreateMenuItem(ParentMI,itmSourceCompleteCode,'itmSourceCompleteCode',lisMenuCompleteCode);
    CreateMenuItem(ParentMI,itmRefactorInvertAssignment,'itmInvertAssignment',uemInvertAssignment);
    CreateMenuItem(ParentMI,itmSourceUseUnit,'itmSourceUseUnit',lisMenuUseUnit);
    // Refactor
    CreateMenuSeparatorSection(mnuSource,itmSourceRefactor,'itmSourceRefactor');
    CreateMenuSubSection(ParentMI,itmSourceRefactor,'itmSourceRefactor',uemRefactor);
    SubParentMI:=itmSourceRefactor;
      CreateMenuSeparatorSection(SubParentMI,itmRefactorCodeTools,'itmRefactorCodeTools');
      ParentMI:=itmRefactorCodeTools;
      CreateMenuItem(ParentMI,itmRefactorRenameIdentifier,'itmRefactorRenameIdentifier',lisMenuRenameIdentifier);
      CreateMenuItem(ParentMI,itmRefactorExtractProc,'itmRefactorExtractProc',lisMenuExtractProc);

      CreateMenuSeparatorSection(SubParentMI,itmRefactorAdvanced,'itmRefactorAdvanced');
      ParentMI:=itmRefactorAdvanced;
      CreateMenuItem(ParentMI,itmRefactorShowAbstractMethods,'itmShowAbstractMethods',srkmecAbstractMethods);
      CreateMenuItem(ParentMI,itmRefactorShowEmptyMethods,'itmShowEmptyMethods',srkmecEmptyMethods);
      CreateMenuItem(ParentMI,itmRefactorShowUnusedUnits,'itmShowUnusedUnits',srkmecUnusedUnits);
      {$IFDEF EnableFindOverloads}
      CreateMenuItem(ParentMI,itmRefactorFindOverloads,'itmFindOverloads',srkmecFindOverloadsCapt);
      {$ENDIF}

      CreateMenuSeparatorSection(SubParentMI,itmRefactorTools,'itmRefactorTools');
      ParentMI:=itmRefactorTools;
      CreateMenuItem(ParentMI,itmRefactorMakeResourceString,'itmRefactorMakeResourceString',
                     lisMenuMakeResourceString,'menu_tool_make_resourcestring');
    // CodeToolChecks
    CreateMenuSeparatorSection(mnuSource,itmSourceCodeToolChecks,'itmSourceCodeToolChecks');
    ParentMI:=itmSourceCodeToolChecks;
    CreateMenuItem(ParentMI,itmSourceSyntaxCheck,'itmSourceSyntaxCheck',lisMenuQuickSyntaxCheck, 'menu_tool_syntax_check');
    CreateMenuItem(ParentMI,itmSourceGuessUnclosedBlock,'itmSourceGuessUnclosedBlock',lisMenuGuessUnclosedBlock);
    CreateMenuItem(ParentMI,itmSourceGuessMisplacedIFDEF,'itmSourceGuessMisplacedIFDEF',lisMenuGuessMisplacedIFDEF);

    CreateMenuSeparatorSection(mnuSource,itmSourceInsertions,'itmSourceInsertions');
    ParentMI:=itmSourceInsertions;
    // *** insert text ***:
    CreateMenuSubSection(ParentMI,itmSourceInsertCVSKeyWord,'itmSourceInsertCVSKeyWord',lisMenuInsertCVSKeyword);
    SubParentMI:=itmSourceInsertCVSKeyWord;
      // insert CVS keyword sub menu items
      CreateMenuItem(SubParentMI,itmSourceInsertCVSAuthor,'itmSourceInsertCVSAuthor','Author');
      CreateMenuItem(SubParentMI,itmSourceInsertCVSDate,'itmSourceInsertCVSDate','Date');
      CreateMenuItem(SubParentMI,itmSourceInsertCVSHeader,'itmSourceInsertCVSHeader','Header');
      CreateMenuItem(SubParentMI,itmSourceInsertCVSID,'itmSourceInsertCVSID','ID');
      CreateMenuItem(SubParentMI,itmSourceInsertCVSLog,'itmSourceInsertCVSLog','Log');
      CreateMenuItem(SubParentMI,itmSourceInsertCVSName,'itmSourceInsertCVSName','Name');
      CreateMenuItem(SubParentMI,itmSourceInsertCVSRevision,'itmSourceInsertCVSRevision','Revision');
      CreateMenuItem(SubParentMI,itmSourceInsertCVSSource,'itmSourceInsertCVSSource','Source');

    CreateMenuSubSection(ParentMI,itmSourceInsertGeneral,'itmSourceInsertGeneral',lisMenuInsertGeneral);
    SubParentMI:=itmSourceInsertGeneral;
      // insert general text sub menu items
      CreateMenuItem(SubParentMI,itmSourceInsertGPLNotice,'itmSourceInsertGPLNotice',lisMenuInsertGPLNotice);
      CreateMenuItem(SubParentMI,itmSourceInsertGPLNoticeTranslated,'itmSourceInsertGPLNoticeTranslated',lisMenuInsertGPLNoticeTranslated);
      CreateMenuItem(SubParentMI,itmSourceInsertLGPLNotice,'itmSourceInsertLGPLNotice',lisMenuInsertLGPLNotice);
      CreateMenuItem(SubParentMI,itmSourceInsertLGPLNoticeTranslated,'itmSourceInsertLGPLNoticeTranslated',lisMenuInsertLGPLNoticeTranslated);
      CreateMenuItem(SubParentMI,itmSourceInsertModifiedLGPLNotice,'itmSourceInsertModifiedLGPLNotice',lisMenuInsertModifiedLGPLNotice);
      CreateMenuItem(SubParentMI,itmSourceInsertModifiedLGPLNoticeTranslated,'itmSourceInsertModifiedLGPLNoticeTranslated',lisMenuInsertModifiedLGPLNoticeTranslated);
      CreateMenuItem(SubParentMI,itmSourceInsertMITNotice,'itmSourceInsertMITNotice',lisMenuInsertMITNotice);
      CreateMenuItem(SubParentMI,itmSourceInsertMITNoticeTranslated,'itmSourceInsertMITNoticeTranslated',lisMenuInsertMITNoticeTranslated);
      CreateMenuItem(SubParentMI,itmSourceInsertUsername,'itmSourceInsertUsername',lisMenuInsertUsername);
      CreateMenuItem(SubParentMI,itmSourceInsertDateTime,'itmSourceInsertDateTime',lisMenuInsertDateTime);
      CreateMenuItem(SubParentMI,itmSourceInsertChangeLogEntry,'itmSourceInsertChangeLogEntry',lisMenuInsertChangeLogEntry);
      CreateMenuItem(SubParentMI,itmSourceInsertGUID,'itmSourceInsertGUID',srkmecInsertGUID);

    CreateMenuItem(itmSourceInsertions,itmSourceInsertFilename,'itmSourceInsertFilename',lisMenuInsertFilename);

    CreateMenuSeparatorSection(mnuSource,itmSourceTools,'itmSourceTools');
    ParentMI:=itmSourceTools;
    CreateMenuItem(ParentMI,itmSourceUnitInfo,'itmViewUnitInfo',lisMenuViewUnitInfo, 'menu_view_unit_info');
  end;
end;

procedure TMainIDEBase.SetupProjectMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuProject,itmProjectNewSection,'itmProjectNewSection');
    ParentMI:=itmProjectNewSection;
    CreateMenuItem(ParentMI,itmProjectNew,'itmProjectNew',lisMenuNewProject, 'item_project');
    CreateMenuItem(ParentMI,itmProjectNewFromFile,'itmProjectNewFromFile',lisMenuNewProjectFromFile, 'menu_project_from_file');

    CreateMenuSeparatorSection(mnuProject,itmProjectOpenSection,'itmProjectOpenSection');
    ParentMI:=itmProjectOpenSection;
    CreateMenuItem(ParentMI,itmProjectOpen,'itmProjectOpen',lisMenuOpenProject,'menu_project_open');
    CreateMenuSubSection(ParentMI,itmProjectRecentOpen,'itmProjectRecentOpen',lisMenuOpenRecentProject);
    CreateMenuItem(ParentMI,itmProjectClose,'itmProjectClose',lisMenuCloseProject, 'menu_project_close');

    CreateMenuSeparatorSection(mnuProject,itmProjectSaveSection,'itmProjectSaveSection');
    ParentMI:=itmProjectSaveSection;
    CreateMenuItem(ParentMI,itmProjectSave,'itmProjectSave',lisMenuSaveProject, 'menu_project_save');
    CreateMenuItem(ParentMI,itmProjectSaveAs,'itmProjectSaveAs',lisMenuSaveProjectAs, 'menu_project_saveas');
    CreateMenuItem(ParentMI,itmProjectPublish,'itmProjectPublish',lisMenuPublishProject);

    CreateMenuSeparatorSection(mnuProject,itmProjectWindowSection,'itmProjectWindowSection');
    ParentMI:=itmProjectWindowSection;
    CreateMenuItem(ParentMI,itmProjectInspector,'itmProjectInspector',lisMenuProjectInspector+' ...','menu_project_inspector');
    CreateMenuItem(ParentMI,itmProjectOptions,'itmProjectOptions',lisMenuProjectOptions,'menu_project_options');

    CreateMenuSeparatorSection(mnuProject,itmProjectAddRemoveSection,'itmProjectAddRemoveSection');
    ParentMI:=itmProjectAddRemoveSection;
    CreateMenuItem(ParentMI,itmProjectAddTo,'itmProjectAddTo',lisMenuAddToProject, 'menu_project_add');
    CreateMenuItem(ParentMI,itmProjectRemoveFrom,'itmProjectRemoveFrom',lisMenuRemoveFromProject, 'menu_project_remove');
    CreateMenuItem(ParentMI,itmProjectViewUnits,'itmProjectViewUnits',lisMenuViewUnits, 'menu_view_units');
    CreateMenuItem(ParentMI,itmProjectViewForms,'itmProjectViewForms',lisMenuViewForms, 'menu_view_forms');
    CreateMenuItem(ParentMI,itmProjectViewSource,'itmProjectViewSource',lisMenuViewProjectSource, 'menu_project_viewsource');
    CreateMenuItem(ParentMI,itmProjectBuildMode,'itmProjectBuildMode',lisChangeBuildMode+' ...', 'menu_compiler_options');
  end;
end;

procedure TMainIDEBase.SetupRunMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuRun,itmRunBuilding,'itmRunBuilding');
    ParentMI:=itmRunBuilding;
    CreateMenuItem(ParentMI,itmRunMenuCompile,'itmRunMenuCompile',lisCompile,'menu_build');
    CreateMenuItem(ParentMI,itmRunMenuBuild,'itmRunMenuBuild',lisBuild,'menu_build_all');
    CreateMenuItem(ParentMI,itmRunMenuQuickCompile,'itmRunMenuQuickCompile',lisMenuQuickCompile,'menu_quick_compile');
    CreateMenuItem(ParentMI,itmRunMenuCleanUpAndBuild,'itmRunMenuCleanUpAndBuild',lisMenuCleanUpAndBuild,'menu_build');
    CreateMenuItem(ParentMI,itmRunMenuBuildManyModes,'itmRunMenuBuildManyModes',lisMenuBuildManyModes,'menu_build_all');
    CreateMenuItem(ParentMI,itmRunMenuAbortBuild,'itmRunMenuAbortBuild',lisMenuAbortBuild,'menu_abort_build');

    CreateMenuSeparatorSection(mnuRun,itmRunnning,'itmRunnning');
    ParentMI:=itmRunnning;
    CreateMenuItem(ParentMI,itmRunMenuRun,'itmRunMenuRun',lisMenuProjectRun,'menu_run');
    CreateMenuItem(ParentMI,itmRunMenuPause,'itmRunMenuPause',lisPause,'menu_pause', False);
    CreateMenuItem(ParentMI,itmRunMenuShowExecutionPoint,'itmRunMenuShowExecutionPoint',
                   lisMenuShowExecutionPoint,'debugger_show_execution_point', False);
    CreateMenuItem(ParentMI,itmRunMenuStepInto,'itmRunMenuStepInto',lisMenuStepInto,'menu_stepinto');
    CreateMenuItem(ParentMI,itmRunMenuStepOver,'itmRunMenuStepOver',lisMenuStepOver,'menu_stepover');
    CreateMenuItem(ParentMI,itmRunMenuStepOut,'itmRunMenuStepOut',lisMenuStepOut,'menu_stepout');
    CreateMenuItem(ParentMI,itmRunMenuRunToCursor,'itmRunMenuRunToCursor',lisMenuRunToCursor,'menu_run_cursor');
    CreateMenuItem(ParentMI,itmRunMenuStop,'itmRunMenuStop',lisStop,'menu_stop', False);

    CreateMenuItem(ParentMI,itmRunMenuAttach,'itmRunMenuAttach',srkmecAttach,'', False);
    CreateMenuItem(ParentMI,itmRunMenuDetach,'itmRunMenuDetach',srkmecDetach,'', False);

    CreateMenuItem(ParentMI,itmRunMenuRunParameters,'itmRunMenuRunParameters',lisMenuRunParameters, 'menu_run_parameters');
    CreateMenuItem(ParentMI,itmRunMenuResetDebugger,'itmRunMenuResetDebugger',lisMenuResetDebugger, 'menu_reset_debugger');

    CreateMenuSeparatorSection(mnuRun,itmRunBuildingFile,'itmRunBuildingFile');
    ParentMI:=itmRunBuildingFile;
    CreateMenuItem(ParentMI,itmRunMenuBuildFile,'itmRunMenuBuildFile',lisMenuBuildFile, 'menu_build_file');
    CreateMenuItem(ParentMI,itmRunMenuRunFile,'itmRunMenuRunFile',lisMenuRunFile,'menu_run_file');
    CreateMenuItem(ParentMI,itmRunMenuConfigBuildFile,'itmRunMenuConfigBuildFile',lisMenuConfigBuildFile, 'menu_build_run_file');

    CreateMenuSeparatorSection(mnuRun,itmRunDebugging,'itmRunDebugging');
    ParentMI:=itmRunDebugging;
    CreateMenuItem(ParentMI,itmRunMenuInspect,'itmRunMenuInspect',lisMenuInspect, 'debugger_inspect', False);
    CreateMenuItem(ParentMI,itmRunMenuEvaluate,'itmRunMenuEvaluate',lisMenuEvaluate, 'debugger_modify', False);
    CreateMenuItem(ParentMI,itmRunMenuAddWatch,'itmRunMenuAddWatch',lisMenuAddWatch, '', False);
    CreateMenuSubSection(ParentMI,itmRunMenuAddBreakpoint,'itmRunMenuAddBreakpoint',lisMenuAddBreakpoint, '');
    CreateMenuItem(itmRunMenuAddBreakpoint,itmRunMenuAddBPSource,'itmRunMenuAdddBPSource',lisSourceBreakpoint, '', False);
    CreateMenuItem(itmRunMenuAddBreakpoint,itmRunMenuAddBPAddress,'itmRunMenuAddBPAddress',lisAddressBreakpoint, '', False);
    CreateMenuItem(itmRunMenuAddBreakpoint,itmRunMenuAddBpWatchPoint,'itmRunMenuAddBpWatchPoint',lisWatchPointBreakpoint, '', False);
  end;
end;

procedure TMainIDEBase.SetupPackageMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuComponent,itmPkgOpening,'itmPkgOpening');
    ParentMI:=itmPkgOpening;
    CreateMenuItem(ParentMI,itmPkgNewPackage,'itmPkgNewPackage',lisMenuNewPackage);
    CreateMenuItem(ParentMI,itmPkgOpenLoadedPackage,'itmPkgOpenPackage',lisMenuOpenPackage,'pkg_installed');
    CreateMenuItem(ParentMI,itmPkgOpenPackageFile,'itmPkgOpenPackageFile',lisMenuOpenPackageFile,'pkg_open');
    CreateMenuItem(ParentMI,itmPkgOpenPackageOfCurUnit,'itmPkgOpenPackageOfCurUnit',lisMenuOpenPackageOfCurUnit);
    CreateMenuSubSection(ParentMI,itmPkgOpenRecent,'itmPkgOpenRecent',lisMenuOpenRecentPkg);

    CreateMenuSeparatorSection(mnuComponent,itmPkgUnits,'itmPkgUnits');
    ParentMI:=itmPkgUnits;
    CreateMenuItem(ParentMI,itmPkgAddCurFileToPkg,'itmPkgAddCurFileToPkg',lisMenuAddCurFileToPkg,'pkg_add');
    CreateMenuItem(ParentMI, itmPkgAddNewComponentToPkg, 'itmPkgAddNewComponentToPkg', lisMenuNewComponent, 'pkg_add');

    CreateMenuSeparatorSection(mnuComponent,itmPkgGraphSection,'itmPkgGraphSection');
    ParentMI:=itmPkgGraphSection;
    CreateMenuItem(ParentMI,itmPkgPkgGraph,'itmPkgPkgGraph',lisMenuPackageGraph+' ...','pkg_graph');
    CreateMenuItem(ParentMI,itmPkgPackageLinks,'itmPkgPackageLinks',lisMenuPackageLinks);
    CreateMenuItem(ParentMI,itmPkgEditInstallPkgs,'itmPkgEditInstallPkgs',lisMenuEditInstallPkgs,'pkg_properties');

    {$IFDEF CustomIDEComps}
    CreateMenuItem(ParentMI,itmCompsConfigCustomComps,'itmCompsConfigCustomComps',lisMenuConfigCustomComps);
    {$ENDIF}
  end;
end;

procedure TMainIDEBase.SetupToolsMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuTools,itmOptionsDialogs,'itmOptionsDialogs');
    ParentMI:=itmOptionsDialogs;
    CreateMenuItem(ParentMI,itmEnvGeneralOptions,'itmEnvGeneralOptions',
                   lisMenuGeneralOptions,'menu_environment_options');
    CreateMenuItem(ParentMI,itmToolRescanFPCSrcDir,'itmToolRescanFPCSrcDir',
                   lisMenuRescanFPCSourceDirectory);
    CreateMenuItem(ParentMI,itmEnvCodeTemplates,'itmEnvCodeTemplates',lisMenuEditCodeTemplates,'');
    CreateMenuItem(ParentMI,itmEnvCodeToolsDefinesEditor,'itmEnvCodeToolsDefinesEditor',
                   lisMenuCodeToolsDefinesEditor,'menu_codetoolsdefineseditor');

    CreateMenuSeparatorSection(mnuTools,itmCustomTools,'itmCustomTools');
    ParentMI:=itmCustomTools;
    CreateMenuItem(ParentMI,itmToolConfigure,'itmToolConfigure',lisMenuConfigExternalTools);

    CreateMenuSeparatorSection(mnuTools,itmSecondaryTools,'itmSecondaryTools');
    ParentMI:=itmSecondaryTools;
    CreateMenuItem(ParentMI,itmToolManageDesktops,'itmToolManageDesktops', lisDesktops, 'menu_manage_desktops');
    CreateMenuItem(ParentMI,itmToolManageExamples,'itmToolManageExamples',lisMenuExampleProjects, 'camera');
    CreateMenuItem(ParentMI,itmToolDiff,'itmToolDiff',lisMenuCompareFiles, 'menu_tool_diff');

    CreateMenuSeparatorSection(mnuTools,itmConversion,'itmConversion');
    ParentMI:=itmConversion;
    CreateMenuItem(ParentMI,itmToolConvertEncoding,'itmToolConvertEncoding',lisMenuConvertEncoding);
    CreateMenuItem(ParentMI,itmToolCheckLFM,'itmToolCheckLFM',lisMenuCheckLFM, 'menu_tool_check_lfm');

    CreateMenuSubSection(mnuTools,itmDelphiConversion,'itmDelphiConversion',lisMenuDelphiConversion,'menu_tool_dfm_to_lfm');
    ParentMI:=itmDelphiConversion;
    CreateMenuItem(ParentMI,itmToolConvertDelphiUnit,'itmToolConvertDelphiUnit',lisMenuConvertDelphiUnit,'menu_tool_dfm_to_lfm');
    CreateMenuItem(ParentMI,itmToolConvertDelphiProject,'itmToolConvertDelphiProject',lisMenuConvertDelphiProject,'menu_tool_dfm_to_lfm');
    CreateMenuItem(ParentMI,itmToolConvertDelphiPackage,'itmToolConvertDelphiPackage',lisMenuConvertDelphiPackage,'menu_tool_dfm_to_lfm');
    CreateMenuItem(ParentMI,itmToolConvertDFMtoLFM,'itmToolConvertDFMtoLFM',lisMenuConvertDFMtoLFM,'menu_tool_dfm_to_lfm');

    CreateMenuSeparatorSection(mnuTools,itmBuildingLazarus,'itmBuildingLazarus');
    ParentMI:=itmBuildingLazarus;
    CreateMenuItem(ParentMI,itmToolBuildLazarus,'itmToolBuildLazarus',lisMenuBuildLazarus,'menu_build_lazarus');
    CreateMenuItem(ParentMI,itmToolConfigureBuildLazarus,'itmToolConfigureBuildLazarus',
                   lisMenuConfigureBuildLazarus, 'menu_configure_build_lazarus');
  end;
end;

procedure TMainIDEBase.SetupWindowsMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuWindow,itmWindowManagers,'itmWindowManagers');
    ParentMI:=itmWindowManagers;
    CreateMenuItem(ParentMI,itmWindowManager,'itmWindowManager', lisManageSourceEditors, 'pkg_files');
    // Populated later with a list of editor names
    CreateMenuSeparatorSection(mnuWindow,itmWindowLists,'itmWindowLists');
    CreateMenuSeparatorSection(mnuWindow,itmCenterWindowLists,'itmCenterWindowLists');
    itmCenterWindowLists.ChildsAsSubMenu:=true;
    itmCenterWindowLists.Caption:=lisCenterALostWindow;
    CreateMenuSeparatorSection(mnuWindow,itmTabLists,'itmTabLists');
    CreateMenuSubSection(itmTabLists,itmTabListProject,'itmTabListProject', dlgEnvProject);
    CreateMenuSeparatorSection(itmTabLists, itmTabListPackage, 'itmTabListPackage');
    CreateMenuSubSection(itmTabLists,itmTabListOther,'itmTabListOther', lisMEOther);
  end;
end;

procedure TMainIDEBase.SetupHelpMenu;
var
  ParentMI: TIDEMenuSection;
begin
  with MainIDEBar do begin
    CreateMenuSeparatorSection(mnuHelp,itmOnlineHelps,'itmOnlineHelps');
    ParentMI:=itmOnlineHelps;

    CreateMenuItem(ParentMI,itmHelpOnlineHelp,'itmHelpOnlineHelp',
                   lisMenuOnlineHelp, 'menu_help');
    CreateMenuItem(ParentMI,itmHelpReportingBug,'itmHelpReportingBug',
                   lisMenuReportingBug, 'menu_reportingbug');

    // old behavior restored, until Tiger issue is fixed.
    // http://bugs.freepascal.org/view.php?id=14411
    (*
   {$ifdef LCLCarbon}
    // under Carbon: add About item to the Apple menu
    CreateMenuItem(mnuApple, itmHelpAboutLazarus,'itmHelpAboutLazarus',
                   lisAboutLazarus, 'menu_information');
    
    CreateMenuSeparatorSection(mnuHelp,itmInfoHelps,'itmInfoHelps');
    {$else}*)
    // otherwise: add About item to the Help menu
    CreateMenuSeparatorSection(mnuHelp,itmInfoHelps,'itmInfoHelps');
    ParentMI:=itmInfoHelps;
    CreateMenuItem(ParentMI,itmHelpAboutLazarus,'itmHelpAboutLazarus',
                 lisAboutLazarus, 'menu_information');
    //{$endif}

    CreateMenuSeparatorSection(mnuHelp,itmHelpTools,'itmHelpTools');
    ParentMI:=itmHelpTools;
  end;
end;

procedure TMainIDEBase.LoadMenuShortCuts;

  function GetCmdAndBtn(ACommand: word; out ToolButton: TIDEButtonCommand): TIDECommand;
  begin
    Result:=IDECommandList.FindIDECommand(ACommand);
    if Result<>nil then
      ToolButton := RegisterIDEButtonCommand(Result)
    else
      ToolButton := nil;
  end;

  function GetCommand(ACommand: word): TIDECommand;
  var
    ToolButton: TIDEButtonCommand;
  begin
    Result:=GetCmdAndBtn(ACommand, ToolButton);
  end;

  function GetCommand(ACommand: word; ToolButtonClass: TIDEToolButtonClass): TIDECommand;
  var
    ToolButton: TIDEButtonCommand;
  begin
    Result:=GetCmdAndBtn(ACommand, ToolButton);
    if ToolButton<>nil then
      ToolButton.ToolButtonClass := ToolButtonClass;
  end;

var
  xBtnItem: TIDEButtonCommand;
begin
  with MainIDEBar do begin
    // file menu
    itmFileNewUnit.Command:=GetCommand(ecNewUnit, TNewUnitToolButton);
    itmFileNewForm.Command:=GetCommand(ecNewForm, TNewFormToolButton);
    itmFileNewOther.Command:=GetCommand(ecNew);
    itmFileOpen.Command:=GetCommand(ecOpen, TOpenFileToolButton);
    itmFileRevert.Command:=GetCommand(ecRevert);
    itmFileSave.Command:=GetCommand(ecSave);
    itmFileSaveAs.Command:=GetCommand(ecSaveAs);
    itmFileSaveAll.Command:=GetCommand(ecSaveAll);
    itmFileClose.Command:=GetCommand(ecClose);
    itmFileCloseAll.Command:=GetCommand(ecCloseAll);
    itmFileCleanDirectory.Command:=GetCommand(ecCleanDirectory);
    itmFileQuit.Command:=GetCommand(ecQuit);

    // edit menu
    itmEditUndo.Command:=GetCommand(ecUndo);
    itmEditRedo.Command:=GetCommand(ecRedo);
    itmEditCut.Command:=GetCommand(ecCut);
    itmEditCopy.Command:=GetCommand(ecCopy);
    itmEditPaste.Command:=GetCommand(ecPaste);

    itmEditSelectAll.Command:=GetCommand(ecSelectAll);
    itmEditSelectToBrace.Command:=GetCommand(ecSelectToBrace);
    itmEditSelectCodeBlock.Command:=GetCommand(ecSelectCodeBlock);
    itmEditSelectWord.Command:=GetCommand(ecSelectWord);
    itmEditSelectLine.Command:=GetCommand(ecSelectLine);
    itmEditSelectParagraph.Command:=GetCommand(ecSelectParagraph);

    itmEditIndentBlock.Command:=GetCommand(ecBlockIndent);
    itmEditUnindentBlock.Command:=GetCommand(ecBlockUnindent);
    itmEditUpperCaseBlock.Command:=GetCommand(ecSelectionUpperCase);
    itmEditLowerCaseBlock.Command:=GetCommand(ecSelectionLowerCase);
    itmEditSwapCaseBlock.Command:=GetCommand(ecSelectionSwapCase);
    itmEditSortBlock.Command:=GetCommand(ecSelectionSort);
    itmEditTabsToSpacesBlock.Command:=GetCommand(ecSelectionTabs2Spaces);
    itmEditSelectionBreakLines.Command:=GetCommand(ecSelectionBreakLines);

    itmEditInsertCharacter.Command:=GetCommand(ecInsertCharacter);

    // search menu
    itmSearchFind.Command:=GetCommand(ecFind);
    itmSearchFindNext.Command:=GetCommand(ecFindNext);
    itmSearchFindPrevious.Command:=GetCommand(ecFindPrevious);
    itmSearchFindInFiles.Command:=GetCommand(ecFindInFiles);
    itmSearchFindIdentifierRefs.Command:=GetCommand(ecFindIdentifierRefs);
    itmSearchReplace.Command:=GetCommand(ecReplace);
    itmIncrementalFind.Command:=GetCommand(ecIncrementalFind);
    itmGotoLine.Command:=GetCommand(ecGotoLineNumber);
    itmJumpBack.Command:=GetCommand(ecJumpBack);
    itmJumpForward.Command:=GetCommand(ecJumpForward);
    itmAddJumpPoint.Command:=GetCommand(ecAddJumpPoint);
    itmJumpToNextError.Command:=GetCommand(ecJumpToNextError);
    itmJumpToPrevError.Command:=GetCommand(ecJumpToPrevError);
    itmSetFreeBookmark.Command:=GetCommand(ecSetFreeBookmark);
    itmJumpToNextBookmark.Command:=GetCommand(ecNextBookmark);
    itmJumpToPrevBookmark.Command:=GetCommand(ecPrevBookmark);
    itmJumpToInterface.Command:=GetCommand(ecJumpToInterface, TJumpToSectionToolButton);
    itmJumpToInterfaceUses.Command:=GetCommand(ecJumpToInterfaceUses, TJumpToSectionToolButton);
    itmJumpToImplementation.Command:=GetCommand(ecJumpToImplementation, TJumpToSectionToolButton);
    itmJumpToImplementationUses.Command:=GetCommand(ecJumpToImplementationUses, TJumpToSectionToolButton);
    itmJumpToInitialization.Command:=GetCommand(ecJumpToInitialization, TJumpToSectionToolButton);
    GetCmdAndBtn(ecJumpToProcedureHeader, xBtnItem);
    xBtnItem.OnClick := @SourceEditorManager.JumpToProcedureHeaderClicked;
    xBtnItem.ImageIndex := IDEImages.LoadImage(16, 'menu_jumpto_procedureheader');
    GetCmdAndBtn(ecJumpToProcedureBegin, xBtnItem);
    xBtnItem.ImageIndex := IDEImages.LoadImage(16, 'menu_jumpto_procedurebegin');
    xBtnItem.OnClick := @SourceEditorManager.JumpToProcedureBeginClicked;
    itmFindBlockOtherEnd.Command:=GetCommand(ecFindBlockOtherEnd);
    itmFindBlockStart.Command:=GetCommand(ecFindBlockStart);
    itmFindDeclaration.Command:=GetCommand(ecFindDeclaration);
    itmOpenFileAtCursor.Command:=GetCommand(ecOpenFileAtCursor);
    itmGotoIncludeDirective.Command:=GetCommand(ecGotoIncludeDirective);
    itmSearchProcedureList.Command:=GetCommand(ecProcedureList);

    // view menu
    itmViewToggleFormUnit.Command:=GetCommand(ecToggleFormUnit);
    itmViewInspector.Command:=GetCommand(ecToggleObjectInsp);
    itmViewSourceEditor.Command:=GetCommand(ecToggleSourceEditor);
    itmViewCodeExplorer.Command:=GetCommand(ecToggleCodeExpl);
    itmViewFPDocEditor.Command:=GetCommand(ecToggleFPDocEditor);
    itmViewCodeBrowser.Command:=GetCommand(ecToggleCodeBrowser);
    itmViewRestrictionBrowser.Command:=GetCommand(ecToggleRestrictionBrowser);
    itmViewComponents.Command:=GetCommand(ecViewComponents);
    itmMacroListView.Command:=GetCommand(ecViewMacroList);
    itmJumpHistory.Command:=GetCommand(ecViewJumpHistory);
    itmViewMessage.Command:=GetCommand(ecToggleMessages);
    itmViewSearchResults.Command:=GetCommand(ecToggleSearchResults);
    itmViewAnchorEditor.Command:=GetCommand(ecViewAnchorEditor);
    itmViewTabOrder.Command:=GetCommand(ecViewTabOrder);
    //itmPkgPackageLinks.Command:=GetCommand(ec?);

    // source menu
    itmSourceCommentBlock.Command:=GetCommand(ecSelectionComment);
    itmSourceUncommentBlock.Command:=GetCommand(ecSelectionUncomment);
    itmSourceToggleComment.Command:=GetCommand(ecToggleComment);
    itmSourceEncloseBlock.Command:=GetCommand(ecSelectionEnclose);
    itmSourceEncloseInIFDEF.Command:=GetCommand(ecSelectionEncloseIFDEF);
    itmSourceCompleteCode.Command:=GetCommand(ecCompleteCode);
    itmSourceUseUnit.Command:=GetCommand(ecUseUnit);

    itmSourceSyntaxCheck.Command:=GetCommand(ecSyntaxCheck);
    itmSourceGuessUnclosedBlock.Command:=GetCommand(ecGuessUnclosedBlock);
    itmSourceGuessMisplacedIFDEF.Command:=GetCommand(ecGuessMisplacedIFDEF);

    itmSourceInsertCVSAuthor.Command:=GetCommand(ecInsertCVSAuthor);
    itmSourceInsertCVSDate.Command:=GetCommand(ecInsertCVSDate);
    itmSourceInsertCVSHeader.Command:=GetCommand(ecInsertCVSHeader);
    itmSourceInsertCVSID.Command:=GetCommand(ecInsertCVSID);
    itmSourceInsertCVSLog.Command:=GetCommand(ecInsertCVSLog);
    itmSourceInsertCVSName.Command:=GetCommand(ecInsertCVSName);
    itmSourceInsertCVSRevision.Command:=GetCommand(ecInsertCVSRevision);
    itmSourceInsertCVSSource.Command:=GetCommand(ecInsertCVSSource);

    itmSourceInsertGPLNotice.Command:=GetCommand(ecInsertGPLNotice);
    itmSourceInsertGPLNoticeTranslated.Command:=GetCommand(ecInsertGPLNoticeTranslated);
    itmSourceInsertLGPLNotice.Command:=GetCommand(ecInsertLGPLNotice);
    itmSourceInsertLGPLNoticeTranslated.Command:=GetCommand(ecInsertLGPLNoticeTranslated);
    itmSourceInsertModifiedLGPLNotice.Command:=GetCommand(ecInsertModifiedLGPLNotice);
    itmSourceInsertModifiedLGPLNoticeTranslated.Command:=GetCommand(ecInsertModifiedLGPLNoticeTranslated);
    itmSourceInsertMITNotice.Command:=GetCommand(ecInsertMITNotice);
    itmSourceInsertMITNoticeTranslated.Command:=GetCommand(ecInsertMITNoticeTranslated);
    itmSourceInsertUsername.Command:=GetCommand(ecInsertUserName);
    itmSourceInsertDateTime.Command:=GetCommand(ecInsertDateTime);
    itmSourceInsertChangeLogEntry.Command:=GetCommand(ecInsertChangeLogEntry);
    itmSourceInsertGUID.Command:=GetCommand(ecInsertGUID);
    itmSourceInsertFilename.Command:=GetCommand(ecInsertFilename);

    itmSourceUnitInfo.Command:=GetCommand(ecViewUnitInfo);
    itmSourceUnitDependencies.Command:=GetCommand(ecViewUnitDependencies);

    // refactor menu
    itmRefactorRenameIdentifier.Command:=GetCommand(ecRenameIdentifier);
    itmRefactorExtractProc.Command:=GetCommand(ecExtractProc);
    itmRefactorInvertAssignment.Command:=GetCommand(ecInvertAssignment);

    itmRefactorShowAbstractMethods.Command:=GetCommand(ecShowAbstractMethods);
    itmRefactorShowEmptyMethods.Command:=GetCommand(ecRemoveEmptyMethods);
    itmRefactorShowUnusedUnits.Command:=GetCommand(ecRemoveUnusedUnits);
    {$IFDEF EnableFindOverloads}
    itmRefactorFindOverloads.Command:=GetCommand(ecFindOverloads);
    {$ENDIF}
    itmRefactorMakeResourceString.Command:=GetCommand(ecMakeResourceString);

    // project menu
    itmProjectNew.Command:=GetCommand(ecNewProject);
    itmProjectNewFromFile.Command:=GetCommand(ecNewProjectFromFile);
    itmProjectOpen.Command:=GetCommand(ecOpenProject);
    itmProjectClose.Command:=GetCommand(ecCloseProject);
    itmProjectSave.Command:=GetCommand(ecSaveProject);
    itmProjectSaveAs.Command:=GetCommand(ecSaveProjectAs);
    itmProjectPublish.Command:=GetCommand(ecPublishProject);
    itmProjectInspector.Command:=GetCommand(ecProjectInspector);
    itmProjectOptions.Command:=GetCommand(ecProjectOptions);
    itmProjectAddTo.Command:=GetCommand(ecAddCurUnitToProj);
    itmProjectRemoveFrom.Command:=GetCommand(ecRemoveFromProj);
    itmProjectViewUnits.Command:=GetCommand(ecViewProjectUnits);
    itmProjectViewForms.Command:=GetCommand(ecViewProjectForms);
    itmProjectViewSource.Command:=GetCommand(ecViewProjectSource);
    itmProjectBuildMode.Command:=GetCommand(ecProjectChangeBuildMode,TSetBuildModeToolButton);

    // run menu
    itmRunMenuCompile.Command:=GetCommand(ecCompile);
    itmRunMenuBuild.Command:=GetCommand(ecBuild);
    itmRunMenuQuickCompile.Command:=GetCommand(ecQuickCompile);
    itmRunMenuCleanUpAndBuild.Command:=GetCommand(ecCleanUpAndBuild);
    itmRunMenuBuildManyModes.Command:=GetCommand(ecBuildManyModes);
    itmRunMenuAbortBuild.Command:=GetCommand(ecAbortBuild);
    itmRunMenuRun.Command:=GetCommand(ecRun);
    itmRunMenuPause.Command:=GetCommand(ecPause);
    itmRunMenuStepInto.Command:=GetCommand(ecStepInto);
    itmRunMenuStepOver.Command:=GetCommand(ecStepOver);
    itmRunMenuStepOut.Command:=GetCommand(ecStepOut);
    itmRunMenuRunToCursor.Command:=GetCommand(ecRunToCursor);
    itmRunMenuStop.Command:=GetCommand(ecStopProgram);
    itmRunMenuAttach.Command:=GetCommand(ecAttach);
    itmRunMenuDetach.Command:=GetCommand(ecDetach);
    itmRunMenuResetDebugger.Command:=GetCommand(ecResetDebugger);
    itmRunMenuRunParameters.Command:=GetCommand(ecRunParameters);
    itmRunMenuBuildFile.Command:=GetCommand(ecBuildFile);
    itmRunMenuRunFile.Command:=GetCommand(ecRunFile);
    itmRunMenuConfigBuildFile.Command:=GetCommand(ecConfigBuildFile);

    // package menu
    itmPkgNewPackage.Command:=GetCommand(ecNewPackage);
    itmPkgOpenLoadedPackage.Command:=GetCommand(ecOpenPackage);
    itmPkgOpenPackageFile.Command:=GetCommand(ecOpenPackageFile);
    itmPkgOpenPackageOfCurUnit.Command:=GetCommand(ecOpenPackageOfCurUnit);
    itmPkgAddCurFileToPkg.Command:=GetCommand(ecAddCurFileToPkg);
    itmPkgAddNewComponentToPkg.Command:=GetCommand(ecNewPkgComponent);
    itmPkgPkgGraph.Command:=GetCommand(ecPackageGraph);
    itmPkgPackageLinks.Command:=GetCommand(ecPackageLinks);
    itmPkgEditInstallPkgs.Command:=GetCommand(ecEditInstallPkgs);
    {$IFDEF CustomIDEComps}
    itmCompsConfigCustomComps.Command:=GetCommand(ecConfigCustomComps);
    {$ENDIF}

    // tools menu
    itmEnvGeneralOptions.Command:=GetCommand(ecEnvironmentOptions);
    itmToolRescanFPCSrcDir.Command:=GetCommand(ecRescanFPCSrcDir);
    itmEnvCodeTemplates.Command:=GetCommand(ecEditCodeTemplates);
    itmEnvCodeToolsDefinesEditor.Command:=GetCommand(ecCodeToolsDefinesEd);

    itmToolConfigure.Command:=GetCommand(ecExtToolSettings);

    itmToolManageDesktops.Command:=GetCommand(ecManageDesktops, TShowDesktopsToolButton);
    itmToolManageExamples.Command:=GetCommand(ecManageExamples);
    itmToolDiff.Command:=GetCommand(ecDiff);

    itmToolConvertDFMtoLFM.Command:=GetCommand(ecConvertDFM2LFM);
    itmToolCheckLFM.Command:=GetCommand(ecCheckLFM);
    itmToolConvertDelphiUnit.Command:=GetCommand(ecConvertDelphiUnit);
    itmToolConvertDelphiProject.Command:=GetCommand(ecConvertDelphiProject);
    itmToolConvertDelphiPackage.Command:=GetCommand(ecConvertDelphiPackage);
    itmToolConvertEncoding.Command:=GetCommand(ecConvertEncoding);
    itmToolBuildLazarus.Command:=GetCommand(ecBuildLazarus);
    itmToolConfigureBuildLazarus.Command:=GetCommand(ecConfigBuildLazarus);

    // window menu
    itmWindowManager.Command:=GetCommand(ecManageSourceEditors);

    // help menu
    itmHelpAboutLazarus.Command:=GetCommand(ecAboutLazarus);
    itmHelpOnlineHelp.Command:=GetCommand(ecOnlineHelp);
    itmHelpReportingBug.Command:=GetCommand(ecReportingBug);
  end;
end;

function TMainIDEBase.DoOpenMacroFile(Sender: TObject; const AFilename: string
  ): TModalResult;
begin
  Result:=DoOpenEditorFile(AFilename,-1,-1,
                  [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofConvertMacros]);
end;

procedure TMainIDEBase.UpdateWindowMenu;

  function GetMenuItem(Index: Integer; ASection: TIDEMenuSection): TIDEMenuItem; inline;
  begin
    if ASection.Count > Index then
      Result := ASection.Items[Index]
    else
    begin
      Result := RegisterIDEMenuCommand(ASection.GetPath,'Window'+IntToStr(Index)+ASection.Name,'');
      Result.CreateMenuItem;
    end;
  end;

  procedure ClearMenuItem(ARemainCount: Integer; ASection: TIDEMenuSection); inline;
  begin
    with ASection do
      while Count > ARemainCount do
        Items[Count-1].Free;
  end;

var
  WindowsList: TFPList;
  i, j, ItemCount, ItemCountProject, ItemCountOther: Integer;
  CurMenuItem: TIDEMenuItem;
  AForm: TForm;
  EdList: TStringList;
  EditorCur: TSourceEditor;
  P: TIDEPackage;
  M: TIDEMenuSection;
  s: String;
begin
  //DebugLn('TMainIDEBase.UpdateWindowMenu: enter');
  WindowsList:=TFPList.Create;
  // add typical IDE windows at the start of the list
  for i := 0 to SourceEditorManager.SourceWindowCount - 1 do
    WindowsList.Add(SourceEditorManager.SourceWindows[i]);
  if (ObjectInspector1<>nil) and (ObjectInspector1.Visible) then
    WindowsList.Add(ObjectInspector1);
  // add special IDE windows
  for i:=0 to Screen.FormCount-1 do begin
    AForm:=Screen.Forms[i];
    //debugln(['TMainIDEBase.UpdateWindowMenu ',DbgSName(AForm),' Vis=',AForm.IsVisible,' Des=',DbgSName(AForm.Designer)]);
    if (not AForm.IsVisible) or (AForm=MainIDEBar) or (AForm=SplashForm)
    or IsFormDesign(AForm) or (WindowsList.IndexOf(AForm)>=0) then
      continue;
    if IDEDockMaster<>nil then
    begin
      if not IDEDockMaster.AddableInWindowMenu(AForm) then continue;
    end else begin
      if AForm.Parent<>nil then continue;
    end;
    WindowsList.Add(AForm);
  end;
  // add designer forms and datamodule forms
  for i:=0 to Screen.FormCount-1 do begin
    AForm:=Screen.Forms[i];
    if (AForm.Designer<>nil) and (WindowsList.IndexOf(AForm)<0) then
      WindowsList.Add(AForm);
  end;
  // create menuitems for all windows
  ItemCount := WindowsList.Count;
  for i:=0 to WindowsList.Count-1 do
  begin
    // in the 'bring to front' list
    CurMenuItem := GetMenuItem(i, itmWindowLists);
    if EnvironmentOptions.Desktop.IDENameForDesignedFormList
    and IsFormDesign(TWinControl(WindowsList[i])) then
      CurMenuItem.Caption:=TCustomForm(WindowsList[i]).Name
    else
       CurMenuItem.Caption:=TCustomForm(WindowsList[i]).Caption;
    CurMenuItem.MenuItem.Checked := WindowMenuActiveForm = TCustomForm(WindowsList[i]);
    CurMenuItem.OnClick:=@mnuWindowItemClick;
    // in the 'center' list
    CurMenuItem := GetMenuItem(i, itmCenterWindowLists);
    if EnvironmentOptions.Desktop.IDENameForDesignedFormList
    and IsFormDesign(TWinControl(WindowsList[i])) then
      CurMenuItem.Caption:=TCustomForm(WindowsList[i]).Name
    else
      CurMenuItem.Caption:=TCustomForm(WindowsList[i]).Caption;
    CurMenuItem.OnClick:=@mnuCenterWindowItemClick;
  end;
  //create source page menuitems
  itmTabListProject.Visible := False;
  itmTabListOther.Visible := False;
  itmTabListProject.MenuItem.Checked := False;
  itmTabListOther.MenuItem.Checked := False;
  itmTabListPackage.Clear;

  if SourceEditorManager.SourceEditorCount > 0 then begin
    ItemCountProject := 0;
    ItemCountOther := 0;
    EdList := TStringList.Create;
    EdList.OwnsObjects := False;
    EdList.Sorted := True;
    // sort
    for i := 0 to SourceEditorManager.SourceEditorCount - 1 do begin
      EdList.AddObject(SourceEditorManager.SourceEditors[i].PageName+' '
                       +SourceEditorManager.SourceEditors[i].FileName
                       +SourceEditorManager.SourceEditors[i].Owner.Name,
                       TObject(PtrUInt(i))
                      );
    end;
    for i := 0 to EdList.Count - 1 do
    begin
      j := PtrUInt(EdList.Objects[i]);
      EditorCur := SourceEditorManager.SourceEditors[j];
      if (EditorCur.GetProjectFile <> nil) and (EditorCur.GetProjectFile.IsPartOfProject) then begin
        M := itmTabListProject;
        CurMenuItem := GetMenuItem(ItemCountProject, M);
        inc(ItemCountProject);
      end else begin
        SourceEditorManager.OnPackageForSourceEditor(P, EditorCur);
        if P <> nil then begin
          s := Format(lisTabsFor, [p.Name]);
          if itmTabListPackage.FindByName(S) is TIDEMenuSection then
            M := TIDEMenuSection(itmTabListPackage.FindByName(S))
          else
            M := RegisterIDESubMenu(itmTabListPackage, S, S);
          CurMenuItem := GetMenuItem(M.Count, M);
        end else begin
          M := itmTabListOther;
          CurMenuItem := GetMenuItem(ItemCountOther, M);
          inc(ItemCountOther);
        end;
      end;
      M.Visible := True;
      if EditorCur.SharedEditorCount > 1 then
        CurMenuItem.Caption := EditorCur.PageName + ' ('+TForm(EditorCur.Owner).Caption+')'
        //CurMenuItem.Caption := EditorCur.PageName
        //  + ' ('+IntToStr(1+SourceEditorManager.IndexOfSourceWindow(TSourceEditorWindowInterface(EditorCur.Owner)))+')'
      else
        CurMenuItem.Caption := EditorCur.PageName;
      if CurMenuItem.MenuItem <> nil then
        CurMenuItem.MenuItem.Checked := SourceEditorManager.ActiveEditor = EditorCur;
      if (SourceEditorManager.ActiveEditor = EditorCur) and (M.MenuItem <> nil) then
        M.MenuItem.Checked := true;
      CurMenuItem.OnClick := @mnuWindowSourceItemClick;
      CurMenuItem.Tag := j;
    end;
    EdList.Free;
    ClearMenuItem(ItemCountProject, itmTabListProject);
    ClearMenuItem(ItemCountOther, itmTabListOther);
    for i := 0 to itmTabListPackage.Count - 1 do begin
      if itmTabListPackage.Items[i] is TIDEMenuSection then begin
        M := itmTabListPackage.Items[i] as TIDEMenuSection;
        M.Caption := M.Caption +  Format(' (%d)', [M.Count]);
      end;
    end;
    itmTabListProject.Caption := dlgEnvProject +  Format(' (%d)', [itmTabListProject.Count]);
    itmTabListOther.Caption := lisMEOther +  Format(' (%d)', [itmTabListOther.Count]);
    if itmTabListPackage.TopSeparator <> nil then
      itmTabListPackage.TopSeparator.Visible := False;
    if itmTabListOther.TopSeparator <> nil then
      itmTabListOther.TopSeparator.Visible := False;
  end;
  // remove unused menuitems
  ClearMenuItem(ItemCount, itmWindowLists);
  ClearMenuItem(ItemCount, itmCenterWindowLists);
  WindowsList.Free;           // clean up
end;

procedure TMainIDEBase.SetRecentSubMenu(Section: TIDEMenuSection;
  FileList: TStringList; OnClickEvent: TNotifyEvent);
var
  i: integer;
  AMenuItem: TIDEMenuItem;
begin
  // create enough menuitems
  while Section.Count<FileList.Count do begin
    AMenuItem:=RegisterIDEMenuCommand(Section.GetPath,
                              Section.Name+'Recent'+IntToStr(Section.Count),'');
  end;
  // delete unused menuitems
  while Section.Count>FileList.Count do
    Section.Items[Section.Count-1].Free;
  Section.Enabled:=(Section.Count>0);
  // set captions and event
  for i:=0 to FileList.Count-1 do begin
    AMenuItem:=Section.Items[i];
    AMenuItem.Caption := FileList[i];
    AMenuItem.OnClick := OnClickEvent;
  end;
end;

procedure TMainIDEBase.UpdateHighlighters(Immediately: boolean = false);
var
  ASrcEdit: TSourceEditor;
  h: TLazSyntaxHighlighter;
  i: Integer;
  AnEditorInfo: TUnitEditorInfo;
begin
  if Immediately then begin
    FNeedUpdateHighlighters:=false;
    for h := Low(TLazSyntaxHighlighter) to High(TLazSyntaxHighlighter) do
      if Highlighters[h]<>nil then begin
        Highlighters[h].BeginUpdate;
        EditorOpts.GetHighlighterSettings(Highlighters[h]);
        Highlighters[h].EndUpdate;
      end;
    if Project1<>nil then begin
      for i := 0 to SourceEditorManager.SourceEditorCount - 1 do begin
        ASrcEdit := SourceEditorManager.SourceEditors[i];
        AnEditorInfo:=Project1.EditorInfoWithEditorComponent(ASrcEdit);
        if AnEditorInfo <> nil then
          ASrcEdit.SyntaxHighlighterType := AnEditorInfo.SyntaxHighlighter;
      end;
    end;
  end else begin
    FNeedUpdateHighlighters:=true;
  end;
end;

procedure TMainIDEBase.FindInFilesPerDialog(AProject: TProject);
begin
  FindInFilesDialog.FindInFilesPerDialog(AProject);
end;

procedure TMainIDEBase.FindInFiles(AProject: TProject; const FindText: string);
begin
  FindInFilesDialog.FindInFiles(AProject, FindText);
end;

end.


