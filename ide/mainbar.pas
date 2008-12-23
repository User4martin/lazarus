{  $Id$  }
{
 /***************************************************************************
                          mainbar.pp  -  Toolbar
                          ----------------------
  TMainIDEBar is main window of the IDE, containing the menu and the component
  palette.

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
unit MainBar;

{$mode objfpc}{$H+}

interface

{$I ide.inc}

uses
{$IFDEF IDE_MEM_CHECK}
  MemCheck,
{$ENDIF}
  Classes, SysUtils, LCLProc, StdCtrls, Forms, Controls, Buttons, Menus,
  ComCtrls, ExtCtrls, Dialogs, LDockCtrl,
  // IDEIntf
  ProjectIntf, NewItemIntf, MenuIntf, LazIDEIntf,
  EnvironmentOpts, LazarusIDEStrConsts;

type
  { TMainIDEBar }

  TMainIDEBar = class(TForm)
  
    // the speedbuttons panel for frequently used IDE functions
    pnlSpeedButtons      : TPanel;
    ViewUnitsSpeedBtn    : TSpeedButton;
    ViewFormsSpeedBtn    : TSpeedButton;
    NewUnitSpeedBtn      : TSpeedButton;
    OpenFileSpeedBtn     : TSpeedButton;
    OpenFileArrowSpeedBtn: TSpeedButton;
    OpenFilePopUpMenu    : TPopupMenu;
    SaveSpeedBtn         : TSpeedButton;
    SaveAllSpeedBtn      : TSpeedButton;
    ToggleFormSpeedBtn   : TSpeedButton;
    NewFormSpeedBtn      : TSpeedButton;
    RunSpeedButton       : TSpeedButton;
    PauseSpeedButton     : TSpeedButton;
    StepIntoSpeedButton  : TSpeedButton;
    StepOverSpeedButton  : TSpeedButton;
    NewUnitFormPopupMenu : TPopupMenu;
      NewUFSetDefaultMenuItem: TMenuItem;

    // MainMenu
    mnuMainMenu: TMainMenu;

    //mnuMain: TIDEMenuSection;

    // file menu
    //mnuFile: TIDEMenuSection;
      //itmFileNew: TIDEMenuSection;
        itmFileNewUnit: TIDEMenuCommand;
        itmFileNewForm: TIDEMenuCommand;
        itmFileNewOther: TIDEMenuCommand;
      //itmFileOpenSave: TIDEMenuSection;
        itmFileOpen: TIDEMenuCommand;
        itmFileRevert: TIDEMenuCommand;
        //itmFileRecentOpen: TIDEMenuSection;
        itmFileSave: TIDEMenuCommand;
        itmFileSaveAs: TIDEMenuCommand;
        itmFileSaveAll: TIDEMenuCommand;
        itmFileClose: TIDEMenuCommand;
        itmFileCloseAll: TIDEMenuCommand;
      //itmFileDirectories: TIDEMenuSection;
        itmFileCleanDirectory: TIDEMenuCommand;
      //itmFileIDEStart: TIDEMenuSection;
        itmFileRestart: TIDEMenuCommand;
        itmFileQuit: TIDEMenuCommand;

    // edit menu
    //mnuEdit: TIDEMenuSection;
      //itmEditReUndo: TIDEMenuSection;
        itmEditUndo: TIDEMenuCommand;
        itmEditRedo: TIDEMenuCommand;
      //itmEditClipboard: TIDEMenuSection;
        itmEditCut: TIDEMenuCommand;
        itmEditCopy: TIDEMenuCommand;
        itmEditPaste: TIDEMenuCommand;
      //itmEditBlockIndentation: TIDEMenuSection;
        itmEditIndentBlock: TIDEMenuCommand;
        itmEditUnindentBlock: TIDEMenuCommand;
        itmEditEncloseBlock: TIDEMenuCommand;
        itmEditCommentBlock: TIDEMenuCommand;
        itmEditUncommentBlock: TIDEMenuCommand;
        itmEditConditionalBlock: TIDEMenuCommand;
        itmEditSortBlock: TIDEMenuCommand;
      //itmEditBlockCharConversion: TIDEMenuSection;
        itmEditUpperCaseBlock: TIDEMenuCommand;
        itmEditLowerCaseBlock: TIDEMenuCommand;
        itmEditTabsToSpacesBlock: TIDEMenuCommand;
        itmEditSelectionBreakLines: TIDEMenuCommand;
      //itmEditSelect: TIDEMenuSection;
        itmEditSelectAll: TIDEMenuCommand;
        itmEditSelectToBrace: TIDEMenuCommand;
        itmEditSelectCodeBlock: TIDEMenuCommand;
        itmEditSelectLine: TIDEMenuCommand;
        itmEditSelectParagraph: TIDEMenuCommand;
      //itmEditInsertions: TIDEMenuSection;
        itmEditInsertCharacter: TIDEMenuCommand;
        //itmEditInsertText: TIDEMenuSection;
          //itmEditInsertCVSKeyWord: TIDEMenuSection;
            itmEditInsertCVSAuthor: TIDEMenuCommand;
            itmEditInsertCVSDate: TIDEMenuCommand;
            itmEditInsertCVSHeader: TIDEMenuCommand;
            itmEditInsertCVSID: TIDEMenuCommand;
            itmEditInsertCVSLog: TIDEMenuCommand;
            itmEditInsertCVSName: TIDEMenuCommand;
            itmEditInsertCVSRevision: TIDEMenuCommand;
            itmEditInsertCVSSource: TIDEMenuCommand;
          //itmEditInsertGeneral: TIDEMenuSection;
            itmEditInsertGPLNotice: TIDEMenuCommand;
            itmEditInsertLGPLNotice: TIDEMenuCommand;
            itmEditInsertModifiedLGPLNotice: TIDEMenuCommand;
            itmEditInsertUsername: TIDEMenuCommand;
            itmEditInsertDateTime: TIDEMenuCommand;
            itmEditInsertChangeLogEntry: TIDEMenuCommand;
            itmEditInsertGUID: TIDEMenuCommand;
            itmEditInsertTodo: TIDEMenuCommand;
      //itmEditMenuCodeTools: TIDEMenuSection;
        itmEditCompleteCode: TIDEMenuCommand;
        itmEditExtractProc: TIDEMenuCommand;

    // search menu
    //mnuSearch: TIDEMenuSection;
      //itmSearchFindReplace: TIDEMenuSection;
        itmSearchFind: TIDEMenuCommand;
        itmSearchFindNext: TIDEMenuCommand;
        itmSearchFindPrevious: TIDEMenuCommand;
        itmSearchFindInFiles: TIDEMenuCommand;
        itmSearchReplace: TIDEMenuCommand;
        itmIncrementalFind: TIDEMenuCommand;
      //itmJumpings: TIDEMenuSection;
        itmGotoLine: TIDEMenuCommand;
        itmJumpBack: TIDEMenuCommand;
        itmJumpForward: TIDEMenuCommand;
        itmAddJumpPoint: TIDEMenuCommand;
        itmJumpToNextError: TIDEMenuCommand;
        itmJumpToPrevError: TIDEMenuCommand;
      //itmBookmarks: TIDEMenuSection;
        itmSetFreeBookmark: TIDEMenuCommand;
        itmJumpToNextBookmark: TIDEMenuCommand;
        itmJumpToPrevBookmark: TIDEMenuCommand;
      //itmCodeToolSearches: TIDEMenuSection;
        itmFindDeclaration: TIDEMenuCommand;
        itmFindBlockOtherEnd: TIDEMenuCommand;
        itmFindBlockStart: TIDEMenuCommand;
        itmOpenFileAtCursor: TIDEMenuCommand;
        itmGotoIncludeDirective: TIDEMenuCommand;
        itmSearchFindIdentifierRefs: TIDEMenuCommand;
        itmSearchRenameIdentifier: TIDEMenuCommand;
        itmSearchProcedureList: TIDEMenuCommand;

    // view menu
    //mnuView: TIDEMenuSection;
      //itmViewMainWindows: TIDEMenuSection;
        itmViewInspector: TIDEMenuCommand;
        itmViewSourceEditor: TIDEMenuCommand;
        itmViewCodeExplorer: TIDEMenuCommand;
        itmViewFPDocEditor: TIDEMenuCommand;
        itmViewCodeBrowser: TIDEMenuCommand;
        itmViewRestrictionBrowser: TIDEMenuCommand;
        itmViewComponents: TIDEMenuCommand;
        itmViewToDoList: TIDEMenuCommand;
        itmJumpHistory: TIDEMenuCommand;
      //itmViewUnitWindows: TIDEMenuSection;
        itmViewUnits: TIDEMenuCommand;
        itmViewForms: TIDEMenuCommand;
        itmViewUnitDependencies: TIDEMenuCommand;
        itmViewUnitInfo: TIDEMenuCommand;
        itmViewToggleFormUnit: TIDEMenuCommand;
      //itmViewSecondaryWindows: TIDEMenuSection;
        itmViewAnchorEditor: TIDEMenuCommand;
        itmViewComponentPalette: TIDEMenuCommand;
        itmViewIDESpeedButtons: TIDEMenuCommand;
        itmViewMessage: TIDEMenuCommand;
        itmViewSearchResults: TIDEMenuCommand;
        //itmViewDebugWindows: TIDEMenuSection;
          itmViewWatches: TIDEMenuCommand;
          itmViewBreakpoints: TIDEMenuCommand;
          itmViewLocals: TIDEMenuCommand;
          itmViewCallStack: TIDEMenuCommand;
          itmViewDebugOutput: TIDEMenuCommand;
        //itmViewIDEInternalsWindows: TIDEMenuSection;
          itmViewPackageLinks: TIDEMenuCommand;

    // project menu
    //mnuProject: TIDEMenuSection;
      //itmProjectNewSection: TIDEMenuSection;
        itmProjectNew: TIDEMenuCommand;
        itmProjectNewFromFile: TIDEMenuCommand;
      //itmProjectOpenSection: TIDEMenuSection;
        itmProjectOpen: TIDEMenuCommand;
        //itmProjectRecentOpen: TIDEMenuSection;
        itmProjectClose: TIDEMenuCommand;
      //itmProjectSaveSection: TIDEMenuSection;
        itmProjectSave: TIDEMenuCommand;
        itmProjectSaveAs: TIDEMenuCommand;
        itmProjectPublish: TIDEMenuCommand;
      //itmProjectWindowSection: TIDEMenuSection;
        itmProjectInspector: TIDEMenuCommand;
        itmProjectOptions: TIDEMenuCommand;
        itmProjectCompilerOptions: TIDEMenuCommand;
      //itmProjectAddRemoveSection: TIDEMenuSection;
        itmProjectAddTo: TIDEMenuCommand;
        itmProjectRemoveFrom: TIDEMenuCommand;
        itmProjectViewSource: TIDEMenuCommand;

    // run menu
    //mnuRun: TIDEMenuSection;
      //itmRunBuilding: TIDEMenuSection;
        itmRunMenuBuild: TIDEMenuCommand;
        itmRunMenuBuildAll: TIDEMenuCommand;
        itmRunMenuQuickCompile: TIDEMenuCommand;
        itmRunMenuAbortBuild: TIDEMenuCommand;
      //itmRunnning: TIDEMenuSection;
        itmRunMenuRun: TIDEMenuCommand;
        itmRunMenuPause: TIDEMenuCommand;
        itmRunMenuStepInto: TIDEMenuCommand;
        itmRunMenuStepOver: TIDEMenuCommand;
        itmRunMenuRunToCursor: TIDEMenuCommand;
        itmRunMenuStop: TIDEMenuCommand;
        itmRunMenuRunParameters: TIDEMenuCommand;
        itmRunMenuResetDebugger: TIDEMenuCommand;
      //itmRunBuildingFile: TIDEMenuSection;
        itmRunMenuBuildFile: TIDEMenuCommand;
        itmRunMenuRunFile: TIDEMenuCommand;
        itmRunMenuConfigBuildFile: TIDEMenuCommand;
      //itmRunDebugging: TIDEMenuSection;
        itmRunMenuInspect: TIDEMenuCommand;
        itmRunMenuEvaluate: TIDEMenuCommand;
        itmRunMenuAddWatch: TIDEMenuCommand;
        //itmRunMenuAddBreakpoint: TIDEMenuSection;
          itmRunMenuAddBpSource: TIDEMenuCommand;

    // components menu
    //mnuComponents: TIDEMenuSection;
      //itmPkgOpening: TIDEMenuSection;
        itmPkgNewPackage: TIDEMenuCommand;
        itmPkgOpenPackage: TIDEMenuCommand;
        itmPkgOpenPackageFile: TIDEMenuCommand;
        itmPkgOpenPackageOfCurUnit: TIDEMenuCommand;
        //itmPkgOpenRecent: TIDEMenuSection;
      //itmPkgUnits: TIDEMenuSection;
        itmPkgAddCurUnitToPkg: TIDEMenuCommand;
      //itmPkgGraphSection: TIDEMenuSection;
        itmPkgPkgGraph: TIDEMenuCommand;
        itmPkgEditInstallPkgs: TIDEMenuCommand;
        {$IFDEF CustomIDEComps}
        itmCompsConfigCustomComps: TIDEMenuCommand;
        {$ENDIF}

    // tools menu
    //mnuTools: TIDEMenuSection;
      //itmCustomTools: TIDEMenuSection;
        itmToolConfigure: TIDEMenuCommand;
      //itmCodeToolChecks: TIDEMenuSection;
        itmToolSyntaxCheck: TIDEMenuCommand;
        itmToolGuessUnclosedBlock: TIDEMenuCommand;
        itmToolGuessMisplacedIFDEF: TIDEMenuCommand;
      //itmSecondaryTools: TIDEMenuSection;
        itmToolMakeResourceString: TIDEMenuCommand;
        itmToolDiff: TIDEMenuCommand;
      //itmDelphiConversion: TIDEMenuSection;
        itmToolCheckLFM: TIDEMenuCommand;
        itmToolConvertDelphiUnit: TIDEMenuCommand;
        itmToolConvertDelphiProject: TIDEMenuCommand;
        itmToolConvertDelphiPackage: TIDEMenuCommand;
        itmToolConvertDFMtoLFM: TIDEMenuCommand;
        itmToolConvertEncoding: TIDEMenuCommand;
      //itmBuildingLazarus: TIDEMenuSection;
        itmToolBuildLazarus: TIDEMenuCommand;
        itmToolConfigureBuildLazarus: TIDEMenuCommand;

    // environment menu
    //mnuEnvironment: TIDEMenuSection;
      //itmOptionsDialogs: TIDEMenuSection;
        itmEnvGeneralOptions: TIDEMenuCommand;
      //itmEnvEditorOptions: TIDEMenuCommand;
        itmEnvCodeTemplates: TIDEMenuCommand;
        itmEnvDebuggerOptions: TIDEMenuCommand;
      //itmEnvCodeToolsOptions: TIDEMenuCommand;
        itmEnvCodeToolsDefinesEditor: TIDEMenuCommand;
      //itmIDECacheSection: TIDEMenuSection;
        itmEnvRescanFPCSrcDir: TIDEMenuCommand;

    // windows menu
    //mnuWindow: TIDEMenuSection;

    // help menu
    //mnuHelp: TIDEMenuSection;
      //itmOnlineHelps: TIDEMenuSection;
        itmHelpOnlineHelp: TIDEMenuCommand;
        itmHelpReportingBug: TIDEMenuCommand;
        itmHelpConfigureHelp: TIDEMenuCommand;
      //itmInfoHelps: TIDEMenuSection;
        itmHelpAboutLazarus: TIDEMenuCommand;
      //itmHelpTools: TIDEMenuSection;

    // component palette
    ComponentNotebook : TNotebook;
    GlobalMouseSpeedButton: TSpeedButton;
  private
    FOldWindowState: TWindowState;
    procedure NewUFDefaultClick(Sender: TObject);
    procedure NewUnitFormPopupMenuPopup(Sender: TObject);
  public
    ControlDocker: TLazControlDocker;
    constructor Create(TheOwner: TComponent); override;
    procedure HideIDE;
    procedure UnhideIDE;
    procedure CreatePopupMenus(TheOwner: TComponent);
  end;

var
  MainIDEBar: TMainIDEBar;

implementation

{ TMainIDEBar }

procedure TMainIDEBar.NewUFDefaultClick(Sender: TObject);
var
  Category: TNewIDEItemCategory;
  i: Integer;
  Item: TMenuItem;
  Template: TNewIDEItemTemplate;
begin
  Item:=Sender as TMenuItem;
  Category:=NewIDEItems.FindCategoryByPath(FileDescGroupName,true);
  i:=Item.MenuIndex;
  if (i<0) or (i>=Category.Count) then exit;
  Template:=Category[i];
  if NewUnitFormPopupMenu.Tag=1 then
    EnvironmentOptions.NewUnitTemplate:=Template.Name
  else
    EnvironmentOptions.NewFormTemplate:=Template.Name;
  //DebugLn(['TMainIDEBar.NewUFDefaultClick ',Template.Name]);
  EnvironmentOptions.Save(False);
end;

procedure TMainIDEBar.NewUnitFormPopupMenuPopup(Sender: TObject);
var
  TemplateName: String;
  Category: TNewIDEItemCategory;
  i: Integer;
  CurTemplate: TNewIDEItemTemplate;
  Index: Integer;
  Item: TMenuItem;
begin
  Category:=NewIDEItems.FindCategoryByPath(FileDescGroupName,true);
  // find default template name
  if NewUnitFormPopupMenu.PopupComponent=NewUnitSpeedBtn then begin
    TemplateName:=EnvironmentOptions.NewUnitTemplate;
    if (TemplateName='') or (Category.FindTemplateByName(TemplateName)=nil) then
      TemplateName:=FileDescNamePascalUnit;
    NewUnitFormPopupMenu.Tag:=1;
  end else begin
    TemplateName:=EnvironmentOptions.NewFormTemplate;
    if (TemplateName='') or (Category.FindTemplateByName(TemplateName)=nil) then
      TemplateName:=FileDescNameLCLForm;
    NewUnitFormPopupMenu.Tag:=2;
  end;
  // create menu items
  Index:=0;
  for i:=0 to Category.Count-1 do begin
    CurTemplate:=Category[i];
    if not CurTemplate.VisibleInNewDialog then continue;
    if Index<NewUFSetDefaultMenuItem.Count then
      Item:=NewUFSetDefaultMenuItem[Index]
    else begin
      Item:=TMenuItem.Create(NewUFSetDefaultMenuItem);
      Item.Name:='NewUFSetDefaultMenuItem'+IntToStr(Index);
      Item.OnClick:=@NewUFDefaultClick;
      NewUFSetDefaultMenuItem.Add(Item);
    end;
    Item.Caption:=CurTemplate.LocalizedName;
    Item.ShowAlwaysCheckable:=true;
    Item.Checked:=SysUtils.CompareText(TemplateName,CurTemplate.Name)=0;
    inc(Index);
  end;
  // remove unneeded items
  while NewUFSetDefaultMenuItem.Count>Index do
    NewUFSetDefaultMenuItem.Items[NewUFSetDefaultMenuItem.Count-1].Free;
end;

constructor TMainIDEBar.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);

  ControlDocker:=TLazControlDocker.Create(Self);
  ControlDocker.Name:='MainIDEBar';
  {$IFDEF EnableIDEDocking}
  ControlDocker.Manager:=LazarusIDE.DockingManager;
  {$ENDIF}
end;

procedure TMainIDEBar.HideIDE;
begin
  if WindowState=wsMinimized then exit;
  FOldWindowState:=WindowState;
  WindowState:=wsMinimized;
end;

procedure TMainIDEBar.UnhideIDE;
begin
  WindowState:=FOldWindowState;
end;

procedure TMainIDEBar.CreatePopupMenus(TheOwner: TComponent);
begin
  // create the popupmenu for the MainIDEBar.OpenFileArrowSpeedBtn
  OpenFilePopUpMenu := TPopupMenu.Create(TheOwner);
  OpenFilePopupMenu.Name:='OpenFilePopupMenu';
  OpenFilePopupMenu.AutoPopup := False;

  NewUnitFormPopupMenu:=TPopupMenu.Create(TheOwner);
  NewUnitFormPopupMenu.Name:='NewUnitFormPopupMenu';
  NewUnitFormPopupMenu.OnPopup:=@NewUnitFormPopupMenuPopup;
  NewUnitSpeedBtn.PopupMenu := NewUnitFormPopupMenu;
  NewFormSpeedBtn.PopupMenu := NewUnitFormPopupMenu;
  NewUFSetDefaultMenuItem:=TMenuItem.Create(TheOwner);
  NewUFSetDefaultMenuItem.Name:='NewUFSetDefaultMenuItem';
  NewUFSetDefaultMenuItem.Caption:=lisSetDefault;
  NewUnitFormPopupMenu.Items.Add(NewUFSetDefaultMenuItem);
end;

end.

