{
 /***************************************************************************
                          mainbar.pp  -  Toolbar
                          ----------------------
  TMainIDEBar is the main window of the IDE, containing the menu and the
  component palette.

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
  Classes, SysUtils, Math, Forms, Controls, Buttons, Menus,
  ComCtrls, ExtCtrls, LMessages, LCLIntf, LCLType, LCLProc,
  // IDEIntf
  ProjectIntf, MenuIntf, LazIDEIntf, IDEWindowIntf, IDEImagesIntf,
  LazFileCache, EnvironmentOpts, LazarusIDEStrConsts, ComponentReg, IdeCoolbarData;

type
  { TMainIDEBar }

  TMainIDEBar = class(TForm)
  private
    OptionsPopupMenu: TPopupMenu;
    FMainOwningComponent: TComponent;
    FOldWindowState: TWindowState;
    FOnActive: TNotifyEvent;
    procedure CreatePopupMenus(TheOwner: TComponent);
    function CalcMainIDEHeight: Integer;
    function CalcNonClientHeight: Integer;
  protected
    procedure DoActive;
    procedure DoShow; override;
    procedure WndProc(var Message: TLMessage); override;
    procedure Resizing(State: TWindowState); override;
  public
    ApplicationIsActivate: boolean;
    LastCompPaletteForm: TCustomForm;
    //Coolbar and PopUpMenus
    CoolBar: TCoolBar;
    OptionsMenuItem: TMenuItem;
    NewUFSetDefaultMenuItem: TMenuItem;
    ComponentPageControl: TPageControl; // component palette
    //GlobalMouseSpeedButton: TSpeedButton; <- what is this
    MainSplitter: TSplitter;        // splitter between the Coolbar and MainMenu
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
        itmFileExportHtml: TIDEMenuCommand;
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
      //itmEditSelect: TIDEMenuSection;
        itmEditSelectAll: TIDEMenuCommand;
        itmEditSelectToBrace: TIDEMenuCommand;
        itmEditSelectCodeBlock: TIDEMenuCommand;
        itmEditSelectWord: TIDEMenuCommand;
        itmEditSelectLine: TIDEMenuCommand;
        itmEditSelectParagraph: TIDEMenuCommand;
      //itmEditBlockActions: TIDEMenuSection;
        itmEditIndentBlock: TIDEMenuCommand;
        itmEditUnindentBlock: TIDEMenuCommand;
        itmEditUpperCaseBlock: TIDEMenuCommand;
        itmEditLowerCaseBlock: TIDEMenuCommand;
        itmEditSwapCaseBlock: TIDEMenuCommand;
        itmEditSortBlock: TIDEMenuCommand;
        itmEditTabsToSpacesBlock: TIDEMenuCommand;
        itmEditSelectionBreakLines: TIDEMenuCommand;
      //itmEditInsertions: TIDEMenuSection;
        itmEditInsertCharacter: TIDEMenuCommand;

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
        itmJumpToInterface: TIDEMenuCommand;
        itmJumpToInterfaceUses: TIDEMenuCommand;
        itmJumpToImplementation: TIDEMenuCommand;
        itmJumpToImplementationUses: TIDEMenuCommand;
        itmJumpToInitialization: TIDEMenuCommand;
        itmJumpToProcedureHeader: TIDEMenuCommand;
        itmJumpToProcedureBegin: TIDEMenuCommand;
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
        itmSearchProcedureList: TIDEMenuCommand;

    // view menu
    //mnuView: TIDEMenuSection;
      //itmViewMainWindows: TIDEMenuSection;
        itmViewToggleFormUnit: TIDEMenuCommand;
        itmViewInspector: TIDEMenuCommand;
        itmViewSourceEditor: TIDEMenuCommand;
        itmViewCodeExplorer: TIDEMenuCommand;
        itmViewFPDocEditor: TIDEMenuCommand;
        itmViewCodeBrowser: TIDEMenuCommand;
        itmSourceUnitDependencies: TIDEMenuCommand;
        itmViewRestrictionBrowser: TIDEMenuCommand;
        itmViewComponents: TIDEMenuCommand;
        itmJumpHistory: TIDEMenuCommand;
        itmMacroListView: TIDEMenuCommand;
      //itmViewSecondaryWindows: TIDEMenuSection;
        itmViewAnchorEditor: TIDEMenuCommand;
        itmViewTabOrder: TIDEMenuCommand;
        itmViewComponentPalette: TIDEMenuCommand;
        itmViewIDESpeedButtons: TIDEMenuCommand;
        itmViewMessage: TIDEMenuCommand;
        itmViewSearchResults: TIDEMenuCommand;
        //itmViewDebugWindows: TIDEMenuSection;
          itmViewWatches: TIDEMenuCommand;
          itmViewBreakpoints: TIDEMenuCommand;
          itmViewLocals: TIDEMenuCommand;
          itmViewRegisters: TIDEMenuCommand;
          itmViewCallStack: TIDEMenuCommand;
          itmViewThreads: TIDEMenuCommand;
          itmViewAssembler: TIDEMenuCommand;
          itmViewDebugOutput: TIDEMenuCommand;
          itmViewDebugEvents: TIDEMenuCommand;
          itmViewPseudoTerminal: TIDEMenuCommand;
          itmViewDbgHistory: TIDEMenuCommand;
        //itmViewIDEInternalsWindows: TIDEMenuSection;
          itmViewFPCInfo: TIDEMenuCommand;
          itmViewIDEInfo: TIDEMenuCommand;
          itmViewNeedBuild: TIDEMenuCommand;
          itmSearchInFPDocFiles: TIDEMenuCommand;

    // source menu
    //mnuSource: TIDEMenuSection;
      //itmSourceBlockActions: TIDEMenuSection;
        itmSourceCommentBlock: TIDEMenuCommand;
        itmSourceUncommentBlock: TIDEMenuCommand;
        itmSourceToggleComment: TIDEMenuCommand;
        itmSourceEncloseBlock: TIDEMenuCommand;
        itmSourceEncloseInIFDEF: TIDEMenuCommand;
        itmSourceCompleteCode: TIDEMenuCommand;
        itmSourceUseUnit: TIDEMenuCommand;
      //itmSourceCodeToolChecks: TIDEMenuSection;
        itmSourceSyntaxCheck: TIDEMenuCommand;
        itmSourceGuessUnclosedBlock: TIDEMenuCommand;
        itmSourceGuessMisplacedIFDEF: TIDEMenuCommand;
      //itmSourceInsertCVSKeyWord: TIDEMenuSection;
        itmSourceInsertCVSAuthor: TIDEMenuCommand;
        itmSourceInsertCVSDate: TIDEMenuCommand;
        itmSourceInsertCVSHeader: TIDEMenuCommand;
        itmSourceInsertCVSID: TIDEMenuCommand;
        itmSourceInsertCVSLog: TIDEMenuCommand;
        itmSourceInsertCVSName: TIDEMenuCommand;
        itmSourceInsertCVSRevision: TIDEMenuCommand;
        itmSourceInsertCVSSource: TIDEMenuCommand;
      //itmSourceInsertGeneral: TIDEMenuSection;
        itmSourceInsertGPLNotice: TIDEMenuCommand;
        itmSourceInsertGPLNoticeTranslated: TIDEMenuCommand;
        itmSourceInsertLGPLNotice: TIDEMenuCommand;
        itmSourceInsertLGPLNoticeTranslated: TIDEMenuCommand;
        itmSourceInsertModifiedLGPLNotice: TIDEMenuCommand;
        itmSourceInsertModifiedLGPLNoticeTranslated: TIDEMenuCommand;
        itmSourceInsertMITNotice: TIDEMenuCommand;
        itmSourceInsertMITNoticeTranslated: TIDEMenuCommand;
        itmSourceInsertUsername: TIDEMenuCommand;
        itmSourceInsertDateTime: TIDEMenuCommand;
        itmSourceInsertChangeLogEntry: TIDEMenuCommand;
        itmSourceInsertGUID: TIDEMenuCommand;
        itmSourceInsertTodo: TIDEMenuCommand;
      itmSourceInsertFilename: TIDEMenuCommand;
    // itmSourceTools
      itmSourceUnitInfo: TIDEMenuCommand;

    // refactor menu
    //mnuRefactor: TIDEMenuSection;
      //itmRefactorCodeTools: TIDEMenuSection;
        itmRefactorRenameIdentifier: TIDEMenuCommand;
        itmRefactorExtractProc: TIDEMenuCommand;
        itmRefactorInvertAssignment: TIDEMenuCommand;
      //itmRefactorAdvanced: TIDEMenuSection;
        itmRefactorShowAbstractMethods: TIDEMenuCommand;
        itmRefactorShowEmptyMethods: TIDEMenuCommand;
        itmRefactorShowUnusedUnits: TIDEMenuCommand;
        itmRefactorFindOverloads: TIDEMenuCommand;
      //itmRefactorTools: TIDEMenuSection;
        itmRefactorMakeResourceString: TIDEMenuCommand;

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
        //itmProjectCompilerOptions: TIDEMenuCommand;
      //itmProjectAddRemoveSection: TIDEMenuSection;
        itmProjectAddTo: TIDEMenuCommand;
        itmProjectRemoveFrom: TIDEMenuCommand;
        itmProjectViewUnits: TIDEMenuCommand;
        itmProjectViewForms: TIDEMenuCommand;
        itmProjectViewSource: TIDEMenuCommand;
        itmProjectBuildMode: TIDEMenuCommand;

    // run menu
    //mnuRun: TIDEMenuSection;
      //itmRunBuilding: TIDEMenuSection;
        itmRunMenuCompile: TIDEMenuCommand;
        itmRunMenuBuild: TIDEMenuCommand;
        itmRunMenuQuickCompile: TIDEMenuCommand;
        itmRunMenuCleanUpAndBuild: TIDEMenuCommand;
        itmRunMenuBuildManyModes: TIDEMenuCommand;
        itmRunMenuAbortBuild: TIDEMenuCommand;
      //itmRunnning: TIDEMenuSection;
        itmRunMenuRun: TIDEMenuCommand;
        itmRunMenuPause: TIDEMenuCommand;
        itmRunMenuShowExecutionPoint: TIDEMenuCommand;
        itmRunMenuStepInto: TIDEMenuCommand;
        itmRunMenuStepOver: TIDEMenuCommand;
        itmRunMenuStepOut: TIDEMenuCommand;
        itmRunMenuRunToCursor: TIDEMenuCommand;
        itmRunMenuStop: TIDEMenuCommand;
        itmRunMenuAttach: TIDEMenuCommand;
        itmRunMenuDetach: TIDEMenuCommand;
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
          itmRunMenuAddBpAddress: TIDEMenuCommand;
          itmRunMenuAddBpWatchPoint: TIDEMenuCommand;

    // packages menu
    //mnuComponents: TIDEMenuSection;
      //itmPkgOpening: TIDEMenuSection;
        itmPkgNewPackage: TIDEMenuCommand;
        itmPkgOpenPackage: TIDEMenuCommand;
        itmPkgOpenPackageFile: TIDEMenuCommand;
        itmPkgOpenPackageOfCurUnit: TIDEMenuCommand;
        //itmPkgOpenRecent: TIDEMenuSection;
      //itmPkgUnits: TIDEMenuSection;
        itmPkgAddCurFileToPkg: TIDEMenuCommand;
        itmPkgAddNewComponentToPkg: TIDEMenuCommand;
      //itmPkgGraphSection: TIDEMenuSection;
        itmPkgPkgGraph: TIDEMenuCommand;
        itmPkgPackageLinks: TIDEMenuCommand;
        itmPkgEditInstallPkgs: TIDEMenuCommand;
        {$IFDEF CustomIDEComps}
        itmCompsConfigCustomComps: TIDEMenuCommand;
        {$ENDIF}

    // tools menu
    //mnuTools: TIDEMenuSection;
      //itmOptionsDialogs: TIDEMenuSection;
        itmEnvGeneralOptions: TIDEMenuCommand;
        itmToolRescanFPCSrcDir: TIDEMenuCommand;
        itmEnvCodeTemplates: TIDEMenuCommand;
        itmEnvCodeToolsDefinesEditor: TIDEMenuCommand;
      //itmCustomTools: TIDEMenuSection;
        itmToolConfigure: TIDEMenuCommand;
      //itmSecondaryTools: TIDEMenuSection;
        itmToolManageDesktops: TIDEMenuCommand;
        itmToolManageExamples: TIDEMenuCommand;
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

    // windows menu
    //mnuWindow: TIDEMenuSection;
      //itmWindowManagers: TIDEMenuSection;
        itmWindowManager: TIDEMenuCommand;

    // help menu
    //mnuHelp: TIDEMenuSection;
      //itmOnlineHelps: TIDEMenuSection;
        itmHelpOnlineHelp: TIDEMenuCommand;
        itmHelpReportingBug: TIDEMenuCommand;
        //itmHelpConfigureHelp: TIDEMenuCommand;
      //itmInfoHelps: TIDEMenuSection;
        itmHelpAboutLazarus: TIDEMenuCommand;
      //itmHelpTools: TIDEMenuSection;

    constructor Create(TheOwner: TComponent); override;
    procedure MainIDEBarDropFiles(Sender: TObject; const FileNames: array of String);
    procedure CoolBarOnChange(Sender: TObject);
    procedure MainSplitterMoved(Sender: TObject);
    procedure SetMainIDEHeightEvent(Sender: TObject);
    procedure OnMainBarActive(Sender: TObject);
    procedure Setup(TheOwner: TComponent);
    procedure SetupHints;
    procedure UpdateIDEComponentPalette(IfFormChanged: boolean);
    procedure HideIDE;
    procedure UnhideIDE;
    property OnActive: TNotifyEvent read FOnActive write FOnActive;
    procedure UpdateDockCaption({%H-}Exclude: TControl); override;
    procedure RefreshCoolbar;
    procedure SetMainIDEHeight;
    procedure DoSetMainIDEHeight(const AIDEIsMaximized: Boolean; ANewHeight: Integer = 0);
    procedure DoSetViewComponentPalette(aVisible: Boolean);
    procedure DoToggleViewComponentPalette;
    procedure DoToggleViewIDESpeedButtons;
    procedure AllowCompilation(aAllow: Boolean);
  end;

var
  MainIDEBar: TMainIDEBar = nil;

implementation

{ TMainIDEBar }

procedure TMainIDEBar.MainIDEBarDropFiles(Sender: TObject;
  const FileNames: array of String);
begin
  // the Drop event comes before the Application activate event
  // => invalidate file state
  InvalidateFileStateCache;
  LazarusIDE.DoDropFiles(Sender,FileNames);
end;

procedure TMainIDEBar.DoActive;
begin
  if Assigned(FOnActive) then
    FOnActive(Self);
end;

procedure TMainIDEBar.DoSetMainIDEHeight(const AIDEIsMaximized: Boolean;
  ANewHeight: Integer);
begin
  if not Showing then
    Exit;

  if ANewHeight <= 0 then
    ANewHeight := CalcMainIDEHeight;

  if Assigned(IDEDockMaster) then
  begin
    if EnvironmentOptions.Desktop.AutoAdjustIDEHeight then
      IDEDockMaster.AdjustMainIDEWindowHeight(Self, True, ANewHeight)
    else
      IDEDockMaster.AdjustMainIDEWindowHeight(Self, False, 0);
  end else
  begin
    if (AIDEIsMaximized or EnvironmentOptions.Desktop.AutoAdjustIDEHeight) then
    begin
      ANewHeight := ANewHeight + CalcNonClientHeight;
      if ANewHeight <> Constraints.MaxHeight then
      begin
        Constraints.MaxHeight := ANewHeight;
        Constraints.MinHeight := ANewHeight;
        ClientHeight := ANewHeight;
      end else if ClientHeight <> ANewHeight then
        ClientHeight := ANewHeight;
    end else
    if Constraints.MaxHeight <> 0 then
    begin
      Constraints.MaxHeight := 0;
      Constraints.MinHeight := 0;
    end;
  end;
end;

procedure TMainIDEBar.DoShow;
begin
  inherited DoShow;
  RefreshCoolbar;
  ComponentPageControl.OnChange(Self);//refresh component palette with button reposition
end;

function TMainIDEBar.CalcNonClientHeight: Integer;
{$IF DEFINED(LCLWin32) OR DEFINED(LCLGtk2) OR DEFINED(LCLQt)}
var
  WindowRect, WindowClientRect: TRect;
{$ENDIF}
begin
  {
    This function is a bug-workaround for various LCL widgetsets.
    Every widgetset handles constrained height differently.
    In an ideal word (when the bugs are fixed), this function shouldn't be
    needed at all - it should return always 0.

    Currently tested: Win32, Gtk2, Carbon, Qt.

    List of bugs related to this workaround:
      http://bugs.freepascal.org/view.php?id=28033
      http://bugs.freepascal.org/view.php?id=28034
      http://bugs.freepascal.org/view.php?id=28036

  }

  if not Showing then
    Exit(0);

  {$IF DEFINED(LCLWin32) OR DEFINED(LCLGtk2) OR DEFINED(LCLQt)}
  //Gtk2 + Win32 + Qt
  //retrieve real main menu height because
  // - Win32: multi-line is possible (SM_CYMENU reflects only single line)
  // - Gtk2, Qt:  SM_CYMENU does not work
  LclIntf.GetWindowRect(Handle, WindowRect{%H-});
  LclIntf.GetClientRect(Handle, WindowClientRect{%H-});
  LclIntf.ClientToScreen(Handle, WindowClientRect.TopLeft);

  Result := WindowClientRect.Top - WindowRect.Top;

  {$IFDEF LCLWin32}
  //Win32 the constrained height has to be without SM_CYSIZEFRAME and SM_CYMENU
  Result := Result - (LCLIntf.GetSystemMetrics(SM_CYSIZEFRAME) + LCLIntf.GetSystemMetrics(SM_CYMENU));
  {$ENDIF LCLWin32}
  {$ELSE}
  //other widgetsets
  //Carbon tested - behaves correctly
  Result := 0;
  {$ENDIF}
end;

procedure TMainIDEBar.SetMainIDEHeightEvent(Sender: TObject);
begin
  SetMainIDEHeight;
end;

procedure TMainIDEBar.OnMainBarActive(Sender: TObject);
var
  i, FormCount: integer;
  AForm: TCustomForm;
begin
  if EnvironmentOptions.Desktop.SingleTaskBarButton and not ApplicationIsActivate
  and (WindowState=wsNormal) then
  begin
    ApplicationIsActivate:=true;
    FormCount:=0;
    for i:=Screen.CustomFormCount-1 downto 0 do
    begin
      AForm:=Screen.CustomForms[i];
      if (AForm.Parent=nil) and (AForm<>Self) and (AForm.IsVisible)
      and (AForm.Designer=nil) and (not (csDesigning in AForm.ComponentState))
      and not (fsModal in AForm.FormState) then
        inc(FormCount);
    end;
    while LazarusIDE.LastActivatedWindows.Count>0 do
    begin
      AForm:=TCustomForm(LazarusIDE.LastActivatedWindows[0]);
      if Assigned(AForm) and (not (CsDestroying in AForm.ComponentState)) and
      AForm.IsVisible then
        AForm.BringToFront;
      LazarusIDE.LastActivatedWindows.Delete(0);
    end;
    Self.BringToFront;
  end;
end;

procedure TMainIDEBar.WndProc(var Message: TLMessage);
begin
  inherited WndProc(Message);
  if (Message.Msg=LM_ACTIVATE) and (Message.Result=0) then
    DoActive;
end;

procedure TMainIDEBar.UpdateDockCaption(Exclude: TControl);
begin
  // keep IDE caption
end;

constructor TMainIDEBar.Create(TheOwner: TComponent);
begin
  // This form has no resource => must be constructed using CreateNew
  inherited CreateNew(TheOwner, 1);
  AllowDropFiles:=true;
  OnDropFiles:=@MainIDEBarDropFiles;
  try
    Icon.LoadFromResourceName(HInstance, 'WIN_MAIN');
  except
  end;
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
  OptionsPopupMenu := TPopupMenu.Create(TheOwner);
  OptionsPopupMenu.Images := IDEImages.Images_16;
  OptionsMenuItem := TMenuItem.Create(TheOwner);
  OptionsMenuItem.Name := 'miToolbarOption';
  OptionsMenuItem.Caption := lisOptions;
  OptionsMenuItem.Enabled := True;
  OptionsMenuItem.Visible := True;
  OptionsMenuItem.ImageIndex := IDEImages.LoadImage(16, 'menu_environment_options');
  OptionsPopupMenu.Items.Add(OptionsMenuItem);
end;

procedure TMainIDEBar.Setup(TheOwner: TComponent);
begin
  FMainOwningComponent := TheOwner;
  OnActive:=@OnMainBarActive;

  MainSplitter := TSplitter.Create(TheOwner);
  MainSplitter.Parent := Self;
  MainSplitter.Align := alLeft;
  MainSplitter.MinSize := 50;
  MainSplitter.OnMoved := @MainSplitterMoved;

  // IDE Coolbar
  CoolBar := TCoolBar.Create(TheOwner);
  CoolBar.Parent := Self;
  if EnvironmentOptions.Desktop.ComponentPaletteOptions.Visible then
  begin
    CoolBar.Align := alLeft;
    CoolBar.Width := EnvironmentOptions.Desktop.IDECoolBarOptions.Width;
  end
  else
    CoolBar.Align := alClient;

  // IDE Coolbar object wraps the actual CoolBar.
  IDECoolBar := TIDECoolBar.Create(CoolBar);
  IDECoolBar.IsVisible := EnvironmentOptions.Desktop.IDECoolBarOptions.Visible;
  CoolBar.OnChange := @CoolBarOnChange;
  CreatePopupMenus(TheOwner);
  CoolBar.PopupMenu := OptionsPopupMenu;

  // Component palette
  ComponentPageControl := TPageControl.Create(TheOwner);
  ComponentPageControl.Name := 'ComponentPageControl';
  ComponentPageControl.Align := alClient;
  ComponentPageControl.Visible := EnvironmentOptions.Desktop.ComponentPaletteOptions.Visible;
  ComponentPageControl.Parent := Self;
end;

procedure TMainIDEBar.SetupHints;
var
  CurShowHint: boolean;
  AControl: TControl;
  i, j: integer;
begin
  if EnvironmentOptions=nil then exit;
  // update all hints in the component palette
  CurShowHint:=EnvironmentOptions.ShowHintsForComponentPalette;
  for i:=0 to ComponentPageControl.PageCount-1 do begin
    for j:=0 to ComponentPageControl.Page[i].ControlCount-1 do begin
      AControl:=ComponentPageControl.Page[i].Controls[j];
      AControl.ShowHint:=CurShowHint;
    end;
  end;
  // update all hints in main ide toolbars
  //??? CurShowHint:=EnvironmentOptions.ShowHintsForMainSpeedButtons;
end;

procedure TMainIDEBar.UpdateIDEComponentPalette(IfFormChanged: boolean);
var
  OldLastCompPaletteForm, LastActiveForm: TCustomForm;
  AResult: Boolean;
begin
  // Package manager updates the palette initially.
  LastActiveForm := LazarusIDE.LastFormActivated;
  if not LazarusIDE.IDEStarted
  or (IfFormChanged and (LastCompPaletteForm=LastActiveForm)) then
    exit;
  OldLastCompPaletteForm:=LastCompPaletteForm;
  LastCompPaletteForm:=LastActiveForm;
  AResult:=(LastActiveForm<>nil) and (LastActiveForm.Designer<>nil)
    and (LastActiveForm.Designer.LookupRoot<>nil)
    and not (LastActiveForm.Designer.LookupRoot is TControl);
  IDEComponentPalette.HideControls:=AResult;
  // Don't update palette at the first time if not hiding controls.
  if (OldLastCompPaletteForm = Nil) and not IDEComponentPalette.HideControls then
    exit;
  {$IFDEF VerboseComponentPalette}
  DebugLn(['* TMainIDEBar.UpdateIDEComponentPalette: Updating palette *',
           ', HideControls=', IDEComponentPalette.HideControls]);
  {$ENDIF}
  IDEComponentPalette.Update(False);
  SetupHints;
end;

procedure TMainIDEBar.RefreshCoolbar;
var
  I, J: Integer;
  CoolBand: TCoolBand;
  CoolBarOpts: TIDECoolBarOptions;
begin
  CoolBarOpts := EnvironmentOptions.Desktop.IDECoolBarOptions;
  //read general settings
  if not (CoolBarOpts.GrabStyle in [0..5]) then
    CoolBarOpts.GrabStyle := 4;
  Coolbar.GrabStyle := TGrabStyle(CoolBarOpts.GrabStyle);
  if not (CoolBarOpts.GrabWidth in [1..50]) then
    CoolBarOpts.GrabWidth := 5;
  Coolbar.GrabWidth := CoolBarOpts.GrabWidth;
  Coolbar.BandBorderStyle := TBorderStyle(CoolBarOpts.BorderStyle);
  Coolbar.Width := CoolBarOpts.Width;
  //read toolbars
  CoolBar.Bands.Clear;
  IDECoolBar.CopyFromOptions(CoolBarOpts);
  IDECoolBar.Sort;
  for I := 0 to IDECoolBar.ToolBars.Count - 1 do
  begin
    CoolBand := CoolBar.Bands.Add;
    CoolBand.Break := IDECoolBar.ToolBars[I].Break;
    CoolBand.Control := IDECoolBar.ToolBars[I].ToolBar;
    CoolBand.MinWidth := 25;
    CoolBand.MinHeight := 22;
    CoolBand.FixedSize := True;
    IDECoolBar.ToolBars[I].ClearToolbar;
    for J := 0 to IDECoolBar.ToolBars[I].ButtonNames.Count - 1 do
      IDECoolBar.ToolBars[I].AddCustomItems(J);
  end;
  CoolBar.AutosizeBands;

  CoolBar.Visible := CoolBarOpts.Visible;
  itmViewIDESpeedButtons.Checked := CoolBar.Visible;
  MainSplitter.Align := alLeft;
  MainSplitter.Visible := Coolbar.Visible and ComponentPageControl.Visible;
end;

procedure TMainIDEBar.Resizing(State: TWindowState);
begin
  case State of
    wsMaximized, wsNormal: DoSetMainIDEHeight(State = wsMaximized);
  end;

  inherited Resizing(State);
end;

procedure TMainIDEBar.MainSplitterMoved(Sender: TObject);
begin
  EnvironmentOptions.Desktop.IDECoolBarOptions.Width := CoolBar.Width;
  SetMainIDEHeight;
end;

function TMainIDEBar.CalcMainIDEHeight: Integer;
var
  NewHeight: Integer;
  I: Integer;
  ComponentScrollBox: TScrollBox;
  SBControl: TControl;
begin
  Result := 0;
  if not (Assigned(EnvironmentOptions) and Assigned(CoolBar) and Assigned(ComponentPageControl)) then
    Exit;

  if EnvironmentOptions.Desktop.IDECoolBarOptions.Visible then
  begin
    for I := 0 to CoolBar.Bands.Count-1 do
    begin
      NewHeight := CoolBar.Bands[I].Top + CoolBar.Bands[I].Height;
      Result := Max(Result, NewHeight);
    end;
  end;

  if EnvironmentOptions.Desktop.ComponentPaletteOptions.Visible
  and Assigned(ComponentPageControl.ActivePage) then
  begin
    ComponentScrollBox := nil;
    for I := 0 to ComponentPageControl.ActivePage.ControlCount-1 do
    if (ComponentPageControl.ActivePage.Controls[I] is TScrollBox) then
    begin
      ComponentScrollBox := TScrollBox(ComponentPageControl.ActivePage.Controls[I]);
      Break;
    end;

    if Assigned(ComponentScrollBox) then
    for I := 0 to ComponentScrollBox.ControlCount-1 do
    begin
      SBControl := ComponentScrollBox.Controls[I];
      NewHeight :=
        SBControl.Top + SBControl.Height +  //button height
        ComponentPageControl.Height - ComponentScrollBox.ClientHeight;  //page control non-client height (tabs, borders).
      Result := Max(Result, NewHeight);

      if not EnvironmentOptions.Desktop.AutoAdjustIDEHeightFullCompPal then
        Break;  //we need only one button (we calculate one line only)
    end;
  end;
end;

procedure TMainIDEBar.CoolBarOnChange(Sender: TObject);
var
  I, J: Integer;
  ToolBar: TToolBar;
begin
  for I := 0 to Coolbar.Bands.Count - 1 do
  begin
    if Coolbar.Bands[I].Control = nil then
      Continue;
    ToolBar := (Coolbar.Bands[I].Control as TToolBar);
    J := IDECoolBar.FindByToolBar(ToolBar);
    if J <> -1 then
    begin
      IDECoolBar.ToolBars[J].Position := Coolbar.Bands[I].Index;
      IDECoolBar.ToolBars[J].Break := Coolbar.Bands[I].Break;
    end
  end;
  IDECoolBar.Sort;
  IDECoolBar.CopyToOptions(EnvironmentOptions.Desktop.IDECoolBarOptions);
  SetMainIDEHeight;
end;

procedure TMainIDEBar.SetMainIDEHeight;
begin
  DoSetMainIDEHeight(WindowState = wsMaximized);
end;

procedure TMainIDEBar.DoSetViewComponentPalette(aVisible: Boolean);
begin
  if aVisible = ComponentPageControl.Visible then Exit;
  ComponentPageControl.Visible := aVisible;
  itmViewComponentPalette.Checked := aVisible;
  EnvironmentOptions.Desktop.ComponentPaletteOptions.Visible := aVisible;
  if aVisible then
  begin
    if CoolBar.Align = alClient then
    begin
      CoolBar.Width := 230;
      EnvironmentOptions.Desktop.IDECoolBarOptions.Width := 230;
    end;
    CoolBar.Align := alLeft;
    CoolBar.Vertical := False;
    MainSplitter.Align := alLeft;
  end
  else
    CoolBar.Align := alClient;
  MainSplitter.Visible := Coolbar.Visible and aVisible;

  if aVisible then//when showing component palette, it must be visible to calculate it correctly
    DoSetMainIDEHeight(WindowState = wsMaximized, 55);//it will cause the IDE to flicker, but it's better than to have wrongly calculated IDE height
  SetMainIDEHeight;
end;

procedure TMainIDEBar.DoToggleViewComponentPalette;
begin
  DoSetViewComponentPalette(not ComponentPageControl.Visible);
end;

procedure TMainIDEBar.DoToggleViewIDESpeedButtons;
var
  SpeedButtonsVisible: boolean;
begin
  SpeedButtonsVisible := not CoolBar.Visible;
  itmViewIDESpeedButtons.Checked := SpeedButtonsVisible;
  CoolBar.Visible := SpeedButtonsVisible;
  MainSplitter.Visible := SpeedButtonsVisible;
  EnvironmentOptions.Desktop.IDECoolBarOptions.Visible := SpeedButtonsVisible;
  MainSplitter.Visible := Coolbar.Visible and ComponentPageControl.Visible;
  SetMainIDEHeight;
end;

procedure TMainIDEBar.AllowCompilation(aAllow: Boolean);
// Enables or disables IDE GUI controls associated with compiling and building.
// Does it interfere with DebugBoss.UpdateButtonsAndMenuItems? Maybe should be refactored and combined.
begin
  itmRunMenuRun.Enabled:=aAllow;
  itmRunMenuCompile.Enabled:=aAllow;
  itmRunMenuBuild.Enabled:=aAllow;
  itmRunMenuQuickCompile.Enabled:=aAllow;
  itmRunMenuCleanUpAndBuild.Enabled:=aAllow;
  itmPkgEditInstallPkgs.Enabled:=aAllow;
  itmToolRescanFPCSrcDir.Enabled:=aAllow;
  itmToolBuildLazarus.Enabled:=aAllow;
  //itmToolConfigureBuildLazarus.Enabled:=aAllow;
end;

end.

