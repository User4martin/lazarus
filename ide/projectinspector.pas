{
 /***************************************************************************
                          projectinspector.pas
                          --------------------


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
    TProjectInspectorForm is the form of the project inspector.

  ToDo:
    - show lfm/lrs files as sub items
    - dnd move
    - project groups:
      - activate
   popup menu:
      - copy file name
      - save
      - options
      - activate
      - compile
      - build
      - view source
      - close
      - remove project
      - build sooner Ctrl+Up
      - build later Ctrl+Down
      - compile all from here
      - build all from here
}
unit ProjectInspector;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LCLType, Forms, Controls, Buttons, ComCtrls, Menus,
  Dialogs, FileUtil, ExtCtrls, IDEHelpIntf, IDECommands, IDEDialogs, IDEImagesIntf,
  LazIDEIntf, ProjectIntf, Project, LazarusIDEStrConsts, IDEProcs, IDEOptionDefs,
  AddToProjectDlg, PackageDefs, TreeFilterEdit, EnvironmentOpts;
  
type
  TOnAddUnitToProject =
    function(Sender: TObject; AnUnitInfo: TUnitInfo): TModalresult of object;
  TRemoveProjInspFileEvent =
    function(Sender: TObject; AnUnitInfo: TUnitInfo): TModalResult of object;
  TRemoveProjInspDepEvent = function(Sender: TObject;
                           ADependency: TPkgDependency): TModalResult of object;
  TAddProjInspDepEvent = function(Sender: TObject;
                           ADependency: TPkgDependency): TModalResult of object;

  TProjectInspectorFlag = (
    pifAllChanged,
    pifItemsChanged,
    pifButtonsChanged,
    pifTitleChanged,
    pifWasHidden
    );
  TProjectInspectorFlags = set of TProjectInspectorFlag;

  TProjectNodeType = (pntFile, pntDependency);

  TProjectNodeData = class(TTFENodeData)
  public
    Typ: TProjectNodeType;
    Name: string; // file or package name
    Removed : Boolean;
    Next : TProjectNodeData;
  end;

  { TProjectInspectorForm }

  TProjectInspectorForm = class(TForm)
    BtnPanel: TPanel;
    DirectoryHierarchyButton: TSpeedButton;
    FilterEdit: TTreeFilterEdit;
    OpenButton: TSpeedButton;
    ItemsTreeView: TTreeView;
    ItemsPopupMenu: TPopupMenu;
    SortAlphabeticallyButton: TSpeedButton;
    // toolbar
    ToolBar: TToolBar;
    // toolbuttons
    AddBitBtn: TToolButton;
    RemoveBitBtn: TToolButton;
    OptionsBitBtn: TToolButton;
    HelpBitBtn: TToolButton;
    procedure AddBitBtnClick(Sender: TObject);
    procedure DirectoryHierarchyButtonClick(Sender: TObject);
    procedure ItemsPopupMenuPopup(Sender: TObject);
    procedure ItemsTreeViewDblClick(Sender: TObject);
    procedure ItemsTreeViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ItemsTreeViewSelectionChanged(Sender: TObject);
    procedure MoveDependencyUpClick(Sender: TObject);
    procedure MoveDependencyDownClick(Sender: TObject);
    procedure SetDependencyDefaultFilenameMenuItemClick(Sender: TObject);
    procedure SetDependencyPreferredFilenameMenuItemClick(Sender: TObject);
    procedure ClearDependencyFilenameMenuItemClick(Sender: TObject);
    procedure OpenButtonClick(Sender: TObject);
    procedure OptionsBitBtnClick(Sender: TObject);
    procedure HelpBitBtnClick(Sender: TObject);
    procedure ProjectInspectorFormShow(Sender: TObject);
    procedure ReAddMenuItemClick(Sender: TObject);
    procedure RemoveBitBtnClick(Sender: TObject);
    procedure RemoveNonExistingFilesMenuItemClick(Sender: TObject);
    procedure SortAlphabeticallyButtonClick(Sender: TObject);
    procedure ToggleI18NForLFMMenuItemClick(Sender: TObject);
  private
    FIdleConnected: boolean;
    FOnAddDependency: TAddProjInspDepEvent;
    FOnAddUnitToProject: TOnAddUnitToProject;
    FOnOpen: TNotifyEvent;
    FOnReAddDependency: TAddProjInspDepEvent;
    FOnRemoveDependency: TRemoveProjInspDepEvent;
    FOnRemoveFile: TRemoveProjInspFileEvent;
    FOnShowOptions: TNotifyEvent;
    FShowDirectoryHierarchy: boolean;
    FSortAlphabetically: boolean;
    FUpdateLock: integer;
    FLazProject: TProject;
    FFilesNode: TTreeNode;
    FNextSelectedPart: TObject;// select this file/dependency on next update
    DependenciesNode: TTreeNode;
    RemovedDependenciesNode: TTreeNode;
    ImageIndexFiles: integer;
    ImageIndexRequired: integer;
    ImageIndexConflict: integer;
    ImageIndexRemovedRequired: integer;
    ImageIndexProject: integer;
    ImageIndexUnit: integer;
    ImageIndexRegisterUnit: integer;
    ImageIndexText: integer;
    ImageIndexBinary: integer;
    ImageIndexDirectory: integer;
    FFlags: TProjectInspectorFlags;
    FProjectNodeDataList : array [TProjectNodeType] of TProjectNodeData;
    procedure FreeNodeData(Typ: TProjectNodeType);
    function CreateNodeData(Typ: TProjectNodeType; aName: string; aRemoved: boolean): TProjectNodeData;
    function GetNodeData(TVNode: TTreeNode): TProjectNodeData;
    function GetNodeItem(NodeData: TProjectNodeData): TObject;
    procedure SetDependencyDefaultFilename(AsPreferred: boolean);
    procedure SetIdleConnected(const AValue: boolean);
    procedure SetLazProject(const AValue: TProject);
    procedure SetShowDirectoryHierarchy(const AValue: boolean);
    procedure SetSortAlphabetically(const AValue: boolean);
    procedure SetupComponents;
    function OnTreeViewGetImageIndex(Str: String; Data: TObject; var AIsEnabled: Boolean): Integer;
    procedure UpdateProjectFiles;
    procedure UpdateRequiredPackages;
    procedure OnProjectBeginUpdate(Sender: TObject);
    procedure OnProjectEndUpdate(Sender: TObject; ProjectChanged: boolean);
    procedure OnCloseIDE(Sender: TObject);
  protected
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure IdleHandler(Sender: TObject; var Done: Boolean);
    procedure UpdateShowing; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    function IsUpdateLocked: boolean;
    procedure UpdateAll(Immediately: boolean);
    procedure UpdateTitle;
    procedure UpdateButtons;
    procedure UpdateItems(Immediately: boolean);
    function GetSelectedFile: TUnitInfo;
    function GetSelectedDependency: TPkgDependency;
  public
    property LazProject: TProject read FLazProject write SetLazProject;
    property OnOpen: TNotifyEvent read FOnOpen write FOnOpen;
    property OnShowOptions: TNotifyEvent read FOnShowOptions write FOnShowOptions;
    property OnAddUnitToProject: TOnAddUnitToProject read FOnAddUnitToProject
                                                     write FOnAddUnitToProject;
    property OnAddDependency: TAddProjInspDepEvent
                             read FOnAddDependency write FOnAddDependency;
    property OnRemoveFile: TRemoveProjInspFileEvent read FOnRemoveFile
                                                    write FOnRemoveFile;
    property OnRemoveDependency: TRemoveProjInspDepEvent
                             read FOnRemoveDependency write FOnRemoveDependency;
    property OnReAddDependency: TAddProjInspDepEvent
                             read FOnReAddDependency write FOnReAddDependency;
    property SortAlphabetically: boolean read FSortAlphabetically write SetSortAlphabetically;
    property ShowDirectoryHierarchy: boolean read FShowDirectoryHierarchy write SetShowDirectoryHierarchy;
    property IdleConnected: boolean read FIdleConnected write SetIdleConnected;
  end;

var
  ProjInspector: TProjectInspectorForm = nil;


implementation

{$R *.lfm}

{ TProjectInspectorForm }

procedure TProjectInspectorForm.ItemsTreeViewDblClick(Sender: TObject);
begin
  OpenButtonClick(Self);
end;

procedure TProjectInspectorForm.ItemsTreeViewKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then
  begin
    Key:=0;
    Close;
  end;
end;

procedure TProjectInspectorForm.ItemsTreeViewSelectionChanged(Sender: TObject);
begin
  UpdateButtons;
end;

procedure TProjectInspectorForm.MoveDependencyUpClick(Sender: TObject);
var
  Dependency: TPkgDependency;
begin
  Dependency:=GetSelectedDependency;
  if SortAlphabetically or (Dependency=nil) or Dependency.Removed
  or (Dependency.PrevRequiresDependency=nil) then exit;
  LazProject.MoveRequiredDependencyUp(Dependency);
end;

procedure TProjectInspectorForm.MoveDependencyDownClick(Sender: TObject);
var
  Dependency: TPkgDependency;
begin
  Dependency:=GetSelectedDependency;
  if SortAlphabetically or (Dependency=nil) or Dependency.Removed
  or (Dependency.NextRequiresDependency=nil) then exit;
  LazProject.MoveRequiredDependencyDown(Dependency);
end;

procedure TProjectInspectorForm.SetDependencyDefaultFilenameMenuItemClick(Sender: TObject);
begin
  SetDependencyDefaultFilename(false);
end;

procedure TProjectInspectorForm.SetDependencyPreferredFilenameMenuItemClick(Sender: TObject);
begin
  SetDependencyDefaultFilename(true);
end;

procedure TProjectInspectorForm.ClearDependencyFilenameMenuItemClick(Sender: TObject);
var
  CurDependency: TPkgDependency;
begin
  CurDependency:=GetSelectedDependency;
  if (CurDependency=nil) then exit;
  if CurDependency.RequiredPackage=nil then exit;
  if CurDependency.DefaultFilename='' then exit;
  CurDependency.DefaultFilename:='';
  CurDependency.PreferDefaultFilename:=false;
  LazProject.Modified:=true;
  UpdateRequiredPackages;
  UpdateButtons;
end;

procedure TProjectInspectorForm.AddBitBtnClick(Sender: TObject);
var
  AddResult: TAddToProjectResult;
  i: Integer;
  NewFilename: string;
  NewFile: TUnitInfo;
begin
  if ShowAddToProjectDlg(LazProject,AddResult)<>mrOk then exit;
  
  case AddResult.AddType of
  a2pFiles:
    begin
      BeginUpdate;
      for i:=0 to AddResult.FileNames.Count-1 do begin
        NewFilename:=AddResult.FileNames[i];
        NewFile:=LazProject.UnitInfoWithFilename(NewFilename);
        if NewFile<>nil then begin
          if NewFile.IsPartOfProject then continue;
        end else begin
          NewFile:=TUnitInfo.Create(nil);
          NewFile.Filename:=NewFilename;
          LazProject.AddFile(NewFile,false);
        end;
        NewFile.IsPartOfProject:=true;
        if Assigned(OnAddUnitToProject) then begin
          if OnAddUnitToProject(Self,NewFile)<>mrOk then break;
        end;
        FNextSelectedPart:=NewFile;
      end;
      UpdateAll(false);
      EndUpdate;
    end;
  
  a2pRequiredPkg:
    begin
      BeginUpdate;
      if Assigned(OnAddDependency) then
        OnAddDependency(Self,AddResult.Dependency);
      FNextSelectedPart:=AddResult.Dependency;
      UpdateItems(false);
      EndUpdate;
    end;
  
  end;
  
  AddResult.Free;
end;

procedure TProjectInspectorForm.DirectoryHierarchyButtonClick(Sender: TObject);
begin
  ShowDirectoryHierarchy:=DirectoryHierarchyButton.Down;
end;

procedure TProjectInspectorForm.ItemsPopupMenuPopup(Sender: TObject);
var
  ItemCnt: integer;

  function AddPopupMenuItem(const ACaption: string; AnEvent: TNotifyEvent;
    EnabledFlag: boolean): TMenuItem;
  begin
    if ItemsPopupMenu.Items.Count<=ItemCnt then begin
      Result:=TMenuItem.Create(Self);
      ItemsPopupMenu.Items.Add(Result);
    end else
      Result:=ItemsPopupMenu.Items[ItemCnt];
    Result.Caption:=ACaption;
    Result.OnClick:=AnEvent;
    Result.Enabled:=EnabledFlag;
    Result.Checked:=false;
    Result.ShowAlwaysCheckable:=false;
    Result.Visible:=true;
    Result.RadioItem:=false;
    Result.ImageIndex:=-1;
    inc(ItemCnt);
  end;

var
  CurFile: TUnitInfo;
  CurDependency: TPkgDependency;
  Item: TMenuItem;
begin
  ItemCnt:=0;
  CurFile:=GetSelectedFile;
  if CurFile<>nil then begin
    AddPopupMenuItem(lisOpenFile, @OpenButtonClick, true);
    AddPopupMenuItem(lisPckEditRemoveFile, @RemoveBitBtnClick, RemoveBitBtn.Enabled);
    if FilenameIsPascalSource(CurFile.Filename) then begin
      Item:=AddPopupMenuItem(lisDisableI18NForLFM,
                             @ToggleI18NForLFMMenuItemClick,true);
      Item.Checked:=CurFile.DisableI18NForLFM;
      Item.ShowAlwaysCheckable:=true;
    end;
  end;
  CurDependency:=GetSelectedDependency;
  if CurDependency<>nil then begin
    AddPopupMenuItem(lisMenuOpenPackage, @OpenButtonClick, true);
    if CurDependency.Removed then begin
      AddPopupMenuItem(lisPckEditReAddDependency, @ReAddMenuItemClick,
                       AddBitBtn.Enabled);
    end else begin
      AddPopupMenuItem(lisPckEditRemoveDependency, @RemoveBitBtnClick,
                       RemoveBitBtn.Enabled);
      AddPopupMenuItem(lisPckEditMoveDependencyUp, @MoveDependencyUpClick,
                       (CurDependency.PrevRequiresDependency<>nil));
      AddPopupMenuItem(lisPckEditMoveDependencyDown, @MoveDependencyDownClick,
                       (CurDependency.NextRequiresDependency<>nil));
      AddPopupMenuItem(lisPckEditStoreFileNameAsDefaultForThisDependency,
                       @SetDependencyDefaultFilenameMenuItemClick,
                       (CurDependency.RequiredPackage<>nil));
      AddPopupMenuItem(lisPckEditStoreFileNameAsPreferredForThisDependency,
                       @SetDependencyPreferredFilenameMenuItemClick,
                       (CurDependency.RequiredPackage<>nil));
      AddPopupMenuItem(lisPckEditClearDefaultPreferredFilenameOfDependency,
                       @ClearDependencyFilenameMenuItemClick,
                       (CurDependency.DefaultFilename<>''));
    end;
  end;

  AddPopupMenuItem(lisRemoveNonExistingFiles,@RemoveNonExistingFilesMenuItemClick,
          not LazProject.IsVirtual);

  while ItemsPopupMenu.Items.Count>ItemCnt do
    ItemsPopupMenu.Items.Delete(ItemsPopupMenu.Items.Count-1);
end;

procedure TProjectInspectorForm.OpenButtonClick(Sender: TObject);
begin
  if Assigned(OnOpen) then OnOpen(Self);
end;

procedure TProjectInspectorForm.OptionsBitBtnClick(Sender: TObject);
begin
  if Assigned(OnShowOptions) then OnShowOptions(Self);
end;

procedure TProjectInspectorForm.HelpBitBtnClick(Sender: TObject);
begin
  LazarusHelp.ShowHelpForIDEControl(Self);
end;

procedure TProjectInspectorForm.ProjectInspectorFormShow(Sender: TObject);
begin
  UpdateAll(false);
end;

procedure TProjectInspectorForm.ReAddMenuItemClick(Sender: TObject);
var
  Dependency: TPkgDependency;
begin
  Dependency:=GetSelectedDependency;
  if (Dependency=nil) or (not Dependency.Removed)
  or (not CheckAddingDependency(LazProject,Dependency)) then exit;
  BeginUpdate;
  if Assigned(OnReAddDependency) then OnReAddDependency(Self,Dependency);
  EndUpdate;
end;

procedure TProjectInspectorForm.RemoveBitBtnClick(Sender: TObject);
var
  CurDependency: TPkgDependency;
  CurFile: TUnitInfo;
begin
  CurDependency:=GetSelectedDependency;
  if (CurDependency<>nil) and (not CurDependency.Removed) then begin
    if IDEMessageDialog(lisProjInspConfirmDeletingDependency,
      Format(lisProjInspDeleteDependencyFor, [CurDependency.AsString]),
      mtConfirmation,[mbYes,mbNo])<>mrYes
    then exit;
    if Assigned(OnRemoveDependency) then OnRemoveDependency(Self,CurDependency);
    exit;
  end;
  
  CurFile:=GetSelectedFile;
  if CurFile<>nil then begin
    if (not CurFile.IsPartOfProject) or (CurFile=LazProject.MainUnitInfo)
    then exit;
    if IDEMessageDialog(lisProjInspConfirmRemovingFile,
      Format(lisProjInspRemoveFileFromProject, [CurFile.Filename]),
      mtConfirmation,[mbYes,mbNo])<>mrYes
    then exit;
    if Assigned(OnRemoveFile) then OnRemoveFile(Self,CurFile);
  end;
end;

procedure TProjectInspectorForm.RemoveNonExistingFilesMenuItemClick(Sender: TObject);
var
  AnUnitInfo: TUnitInfo;
  NextUnitInfo: TUnitInfo;
  HasChanged: Boolean;
begin
  if LazProject.IsVirtual then exit;
  HasChanged:=false;
  AnUnitInfo:=LazProject.FirstPartOfProject;
  while AnUnitInfo<>nil do begin
    NextUnitInfo:=AnUnitInfo.NextPartOfProject;
    if not (AnUnitInfo.IsVirtual or FileExistsUTF8(AnUnitInfo.Filename)) then begin
      AnUnitInfo.IsPartOfProject:=false;
      HasChanged:=true;
    end;
    AnUnitInfo:=NextUnitInfo;
  end;
  if HasChanged then begin
    LazProject.Modified:=true;
    UpdateProjectFiles;
  end;
end;

procedure TProjectInspectorForm.SortAlphabeticallyButtonClick(Sender: TObject);
begin
  SortAlphabetically:=SortAlphabeticallyButton.Down;
end;

procedure TProjectInspectorForm.ToggleI18NForLFMMenuItemClick(Sender: TObject);
var
  CurFile: TUnitInfo;
begin
  CurFile:=GetSelectedFile;
  if CurFile=nil then exit;
  CurFile.DisableI18NForLFM:=not CurFile.DisableI18NForLFM;
end;

procedure TProjectInspectorForm.SetLazProject(const AValue: TProject);
begin
  if FLazProject=AValue then exit;
  if FLazProject<>nil then begin
    dec(FUpdateLock,LazProject.UpdateLock);
    FLazProject.OnBeginUpdate:=nil;
    FLazProject.OnEndUpdate:=nil;
  end;
  FLazProject:=AValue;
  if FLazProject<>nil then begin
    inc(FUpdateLock,LazProject.UpdateLock);
    FLazProject.OnBeginUpdate:=@OnProjectBeginUpdate;
    FLazProject.OnEndUpdate:=@OnProjectEndUpdate;
  end;
  UpdateAll(false);
end;

procedure TProjectInspectorForm.SetShowDirectoryHierarchy(const AValue: boolean);
begin
  if FShowDirectoryHierarchy=AValue then exit;
  FShowDirectoryHierarchy:=AValue;
  DirectoryHierarchyButton.Down:=FShowDirectoryHierarchy;
  FilterEdit.ShowDirHierarchy:=FShowDirectoryHierarchy;
  FilterEdit.InvalidateFilter;
end;

procedure TProjectInspectorForm.SetSortAlphabetically(const AValue: boolean);
begin
  if FSortAlphabetically=AValue then exit;
  FSortAlphabetically:=AValue;
  SortAlphabeticallyButton.Down:=FSortAlphabetically;
  FilterEdit.SortData:=FSortAlphabetically;
  FilterEdit.InvalidateFilter;
end;

procedure TProjectInspectorForm.SetDependencyDefaultFilename(AsPreferred: boolean);
var
  NewFilename: String;
  CurDependency: TPkgDependency;
begin
  CurDependency:=GetSelectedDependency;
  if (CurDependency=nil) then exit;
  if CurDependency.RequiredPackage=nil then exit;
  NewFilename:=CurDependency.RequiredPackage.Filename;
  if (NewFilename=CurDependency.DefaultFilename) // do not use CompareFilenames
  and (CurDependency.PreferDefaultFilename=AsPreferred) then exit;
  CurDependency.DefaultFilename:=NewFilename;
  CurDependency.PreferDefaultFilename:=AsPreferred;
  LazProject.Modified:=true;
  UpdateRequiredPackages;
  UpdateButtons;
end;

procedure TProjectInspectorForm.SetIdleConnected(const AValue: boolean);
begin
  if FIdleConnected=AValue then exit;
  FIdleConnected:=AValue;
  if FIdleConnected then
    Application.AddOnIdleHandler(@IdleHandler)
  else
    Application.RemoveOnIdleHandler(@IdleHandler);
end;

procedure TProjectInspectorForm.SetupComponents;

  function CreateToolButton(AName, ACaption, AHint, AImageName: String; AOnClick: TNotifyEvent): TToolButton;
  begin
    Result := TToolButton.Create(Self);
    Result.Name := AName;
    Result.Caption := ACaption;
    Result.Hint := AHint;
    if AImageName <> '' then
      Result.ImageIndex := IDEImages.LoadImage(16, AImageName);
    Result.ShowHint := True;
    Result.OnClick := AOnClick;
    Result.AutoSize := True;
    Result.Parent := ToolBar;
  end;

  function CreateDivider: TToolButton;
  begin
    Result := TToolButton.Create(Self);
    Result.Style := tbsDivider;
    Result.AutoSize := True;
    Result.Parent := ToolBar;
  end;

begin
  ImageIndexFiles           := IDEImages.LoadImage(16, 'pkg_files');
  ImageIndexRequired        := IDEImages.LoadImage(16, 'pkg_required');
  ImageIndexConflict        := IDEImages.LoadImage(16, 'pkg_conflict');
  ImageIndexRemovedRequired := IDEImages.LoadImage(16, 'pkg_removedrequired');
  ImageIndexProject         := IDEImages.LoadImage(16, 'item_project');
  ImageIndexUnit            := IDEImages.LoadImage(16, 'item_unit');
  ImageIndexRegisterUnit    := IDEImages.LoadImage(16, 'pkg_registerunit');
  ImageIndexText            := IDEImages.LoadImage(16, 'pkg_text');
  ImageIndexBinary          := IDEImages.LoadImage(16, 'pkg_binary');
  ImageIndexDirectory       := IDEImages.LoadImage(16, 'pkg_files');

  ItemsTreeView.Images      := IDEImages.Images_16;
  ToolBar.Images            := IDEImages.Images_16;
  FilterEdit.OnGetImageIndex:=@OnTreeViewGetImageIndex;

  AddBitBtn     := CreateToolButton('AddBitBtn', lisAdd, lisPckEditAddAnItem, 'laz_add', @AddBitBtnClick);
  RemoveBitBtn  := CreateToolButton('RemoveBitBtn', lisRemove, lisPckEditRemoveSelectedItem, 'laz_delete', @RemoveBitBtnClick);
  CreateDivider;
  OptionsBitBtn := CreateToolButton('OptionsBitBtn', dlgFROpts, lisPckEditEditGeneralOptions, 'menu_environment_options', @OptionsBitBtnClick);
  HelpBitBtn    := CreateToolButton('HelpBitBtn', GetButtonCaption(idButtonHelp), lisPkgEdThereAreMoreFunctionsInThePopupmenu, 'menu_help', @HelpBitBtnClick);

  OpenButton.LoadGlyphFromLazarusResource('laz_open');
  OpenButton.Caption:='';
  OpenButton.Hint:=lisOpenFile2;
  SortAlphabeticallyButton.Hint:=lisPESortFilesAlphabetically;
  SortAlphabeticallyButton.LoadGlyphFromLazarusResource('pkg_sortalphabetically');
  DirectoryHierarchyButton.Hint:=lisPEShowDirectoryHierarchy;
  DirectoryHierarchyButton.LoadGlyphFromLazarusResource('pkg_hierarchical');

  with ItemsTreeView do begin
    FFilesNode:=Items.Add(nil, dlgEnvFiles);
    FFilesNode.ImageIndex:=ImageIndexFiles;
    FFilesNode.SelectedIndex:=FFilesNode.ImageIndex;
    DependenciesNode:=Items.Add(nil, lisPckEditRequiredPackages);
    DependenciesNode.ImageIndex:=ImageIndexRequired;
    DependenciesNode.SelectedIndex:=DependenciesNode.ImageIndex;
  end;
end;

function TProjectInspectorForm.OnTreeViewGetImageIndex(Str: String; Data: TObject;
                                                var AIsEnabled: Boolean): Integer;
var
  NodeData: TProjectNodeData;
  Item: TObject;
begin
  Result := -1;
  if not (Data is TProjectNodeData) then exit;
  NodeData:=TProjectNodeData(Data);
  Item:=GetNodeItem(NodeData);
  if Item=nil then exit;

  if Item is TUnitInfo then begin
    if FilenameIsPascalUnit(TUnitInfo(Item).Filename) then
      Result:=ImageIndexUnit
    else if (LazProject<>nil) and (LazProject.MainUnitinfo=Item) then
      Result:=ImageIndexProject
    else
      Result:=ImageIndexText;
  end
  else if Item is TPkgDependency then begin
    if TPkgDependency(Item).Removed then
      Result:=ImageIndexRemovedRequired
    else if TPkgDependency(Item).LoadPackageResult=lprSuccess then
      Result:=ImageIndexRequired
    else
      Result:=ImageIndexConflict;
  end;
end;

procedure TProjectInspectorForm.UpdateProjectFiles;
var
  CurFile: TUnitInfo;
  FilesBranch: TTreeFilterBranch;
  Filename: String;
  ANodeData : TProjectNodeData;
begin
  ItemsTreeView.BeginUpdate;
  try
    FilesBranch:=FilterEdit.GetBranch(FFilesNode);
    FilesBranch.Clear;
    FreeNodeData(pntFile);
    if LazProject<>nil then begin
      FilterEdit.SelectedPart:=FNextSelectedPart;
      FilterEdit.ShowDirHierarchy:=ShowDirectoryHierarchy;
      FilterEdit.SortData:=SortAlphabetically;
      FilterEdit.ImageIndexDirectory:=ImageIndexDirectory;
      // collect and sort files
      CurFile:=LazProject.FirstPartOfProject;
      while CurFile<>nil do begin
        Filename:=CurFile.GetShortFilename(true);
        if Filename<>'' then Begin
          ANodeData := CreateNodeData(pntFile, CurFile.Filename, False);
          FilesBranch.AddNodeData(Filename, ANodeData, CurFile.Filename);
        end;
        CurFile:=CurFile.NextPartOfProject;
      end;
    end;
    FilterEdit.InvalidateFilter;            // Data is shown by FilterEdit.
  finally
    ItemsTreeView.EndUpdate;
  end;
end;

procedure TProjectInspectorForm.UpdateRequiredPackages;
var
  Dependency: TPkgDependency;
  RequiredBranch, RemovedBranch: TTreeFilterBranch;
  NodeText, AFilename: String;
  ANodeData : TProjectNodeData;
begin
  ItemsTreeView.BeginUpdate;
  try
    RequiredBranch:=FilterEdit.GetBranch(DependenciesNode);
    RequiredBranch.Clear;
    FreeNodeData(pntDependency);
    Dependency:=Nil;
    if LazProject<>nil then begin
      // required packages
      Dependency:=LazProject.FirstRequiredDependency;
      while Dependency<>nil do begin
        // Figure out the item's caption
        NodeText:=Dependency.AsString;
        if Dependency.DefaultFilename<>'' then begin
          AFilename:=Dependency.MakeFilenameRelativeToOwner(Dependency.DefaultFilename);
          if Dependency.PreferDefaultFilename then
            NodeText:=Format(lisCEIn, [NodeText,AFilename])  // like the 'in' keyword in the uses section
          else
            NodeText:=Format(lisPckEditDefault, [NodeText, AFilename]);
        end;
        // Add the required package under the branch
        ANodeData := CreateNodeData(pntDependency, Dependency.PackageName, False);
        RequiredBranch.AddNodeData(NodeText, ANodeData);
        Dependency:=Dependency.NextRequiresDependency;
      end;

      // removed required packages
      Dependency:=LazProject.FirstRemovedDependency;
      if Dependency<>nil then begin
        // Create root node for removed dependencies if not done yet.
        if RemovedDependenciesNode=nil then begin
          RemovedDependenciesNode:=ItemsTreeView.Items.Add(DependenciesNode,
                                                  lisProjInspRemovedRequiredPackages);
          RemovedDependenciesNode.ImageIndex:=ImageIndexRemovedRequired;
          RemovedDependenciesNode.SelectedIndex:=RemovedDependenciesNode.ImageIndex;
        end;
        RemovedBranch:=FilterEdit.GetBranch(RemovedDependenciesNode);
        // Add all removed dependencies under the branch
        while Dependency<>nil do begin
          ANodeData := CreateNodeData(pntDependency, Dependency.PackageName, True);
          RemovedBranch.AddNodeData(Dependency.AsString, ANodeData);
          Dependency:=Dependency.NextRequiresDependency;
        end;
      end;
    end;

    // Dependency is set to removed required packages if there is active project
    if (Dependency=nil) and (RemovedDependenciesNode<>nil) then begin
      // No removed dependencies -> delete the root node
      FilterEdit.DeleteBranch(RemovedDependenciesNode);
      FreeThenNil(RemovedDependenciesNode);
    end;
    FilterEdit.InvalidateFilter;
  finally
    ItemsTreeView.EndUpdate;
  end;
end;

procedure TProjectInspectorForm.OnProjectBeginUpdate(Sender: TObject);
begin
  BeginUpdate;
end;

procedure TProjectInspectorForm.OnProjectEndUpdate(Sender: TObject;
  ProjectChanged: boolean);
begin
  UpdateAll(false);
  EndUpdate;
end;

procedure TProjectInspectorForm.OnCloseIDE(Sender: TObject);
begin
  EnvironmentOptions.ProjInspSortAlphabetically := SortAlphabetically;
  EnvironmentOptions.ProjInspShowDirHierarchy := ShowDirectoryHierarchy;
end;

procedure TProjectInspectorForm.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  ExecuteIDEShortCut(Self,Key,Shift,nil);
end;

procedure TProjectInspectorForm.IdleHandler(Sender: TObject; var Done: Boolean);
begin
  if not IsVisible then begin
    Include(FFlags,pifWasHidden);
    IdleConnected:=false;
    exit;
  end;
  Exclude(FFlags,pifWasHidden);
  if FUpdateLock>0 then begin
    IdleConnected:=false;
    exit;
  end;
  if pifAllChanged in FFlags then
    UpdateAll(true)
  else if pifItemsChanged in FFlags then
    UpdateItems(true)
  else if pifTitleChanged in FFlags then
    UpdateTitle
  else if pifButtonsChanged in FFlags then
    UpdateButtons
  else
    IdleConnected:=false;
end;

procedure TProjectInspectorForm.UpdateShowing;
begin
  inherited UpdateShowing;
  if IsVisible and (pifWasHidden in FFlags) then begin
    Exclude(FFlags,pifWasHidden);
    if FFlags<>[] then begin
      // the form is visible again and some updates are pending
      IdleConnected:=true;
    end;
  end;
end;

function TProjectInspectorForm.GetSelectedFile: TUnitInfo;
var
  Item: TObject;
begin
  Result:=nil;
  Item:=GetNodeItem(GetNodeData(ItemsTreeView.Selected));
  if Item is TUnitInfo then
    Result:=TUnitInfo(Item);
end;

function TProjectInspectorForm.GetSelectedDependency: TPkgDependency;
var
  Item: TObject;
begin
  Result:=nil;
  Item:=GetNodeItem(GetNodeData(ItemsTreeView.Selected));
  if Item is TPkgDependency then
    Result:=TPkgDependency(Item);
end;

constructor TProjectInspectorForm.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Name:=NonModalIDEWindowNames[nmiwProjectInspector];
  Caption:=lisMenuProjectInspector;
  KeyPreview:=true;
  SetupComponents;
  KeyPreview:=true;
  SortAlphabetically := EnvironmentOptions.ProjInspSortAlphabetically;
  ShowDirectoryHierarchy := EnvironmentOptions.ProjInspShowDirHierarchy;
  LazarusIDE.AddHandlerOnIDEClose(@OnCloseIDE);
end;

destructor TProjectInspectorForm.Destroy;
var
  nt: TProjectNodeType;
begin
  IdleConnected:=false;
  LazProject:=nil;
  inherited Destroy;
  for nt:=Low(TProjectNodeType) to High(TProjectNodeType) do
    FreeNodeData(nt);
  if ProjInspector=Self then
    ProjInspector:=nil;
end;

procedure TProjectInspectorForm.BeginUpdate;
begin
  inc(FUpdateLock);
end;

procedure TProjectInspectorForm.EndUpdate;
begin
  if FUpdateLock=0 then RaiseException('TProjectInspectorForm.EndUpdate');
  dec(FUpdateLock);
end;

function TProjectInspectorForm.IsUpdateLocked: boolean;
begin
  Result:=FUpdateLock>0;
end;

procedure TProjectInspectorForm.UpdateAll(Immediately: boolean);
begin
  if (FUpdateLock>0) or (not Visible) then begin
    Include(FFlags,pifAllChanged);
    IdleConnected:=true;
    exit;
  end;
  Exclude(FFlags,pifAllChanged);
  UpdateTitle;
  UpdateButtons;
  UpdateItems(true);
end;

procedure TProjectInspectorForm.UpdateTitle;
var
  NewCaption: String;
begin
  if (FUpdateLock>0) or (not Visible) then begin
    Include(FFlags,pifTitleChanged);
    IdleConnected:=true;
    exit;
  end;
  Exclude(FFlags,pifTitleChanged);
  if LazProject=nil then
    Caption:=lisMenuProjectInspector
  else begin
    NewCaption:=LazProject.GetTitle;
    if NewCaption='' then
      NewCaption:=ExtractFilenameOnly(LazProject.ProjectInfoFile);
    Caption:=Format(lisProjInspProjectInspector, [NewCaption]);
  end;
end;

procedure TProjectInspectorForm.UpdateButtons;
var
  CurFile: TUnitInfo;
  CurDependency: TPkgDependency;
begin
  if (FUpdateLock>0) or (not Visible) then begin
    Include(FFlags,pifButtonsChanged);
    IdleConnected:=true;
    exit;
  end;
  Exclude(FFlags,pifButtonsChanged);
  if LazProject<>nil then begin
    AddBitBtn.Enabled:=true;
    CurFile:=GetSelectedFile;
    CurDependency:=GetSelectedDependency;
    RemoveBitBtn.Enabled:=((CurFile<>nil) and (CurFile<>LazProject.MainUnitInfo))
                      or ((CurDependency<>nil) and (not CurDependency.Removed));
    OpenButton.Enabled:=((CurFile<>nil)
                     or ((CurDependency<>nil) and (not CurDependency.Removed)));
    OptionsBitBtn.Enabled:=true;
  end else begin
    AddBitBtn.Enabled:=false;
    RemoveBitBtn.Enabled:=false;
    OpenButton.Enabled:=false;
    OptionsBitBtn.Enabled:=false;
  end;
end;

procedure TProjectInspectorForm.UpdateItems(Immediately: boolean);
begin
  if (FUpdateLock>0) or (not Visible) then begin
    Include(FFlags,pifItemsChanged);
    IdleConnected:=true;
    exit;
  end;
  Exclude(FFlags,pifItemsChanged);
  ItemsTreeView.BeginUpdate;
  try
    UpdateProjectFiles;
    UpdateRequiredPackages;
  finally
    ItemsTreeView.EndUpdate;
  end;
end;

procedure TProjectInspectorForm.FreeNodeData(Typ: TProjectNodeType);
var
  NodeData,
  n: TProjectNodeData;
begin
  NodeData:=FProjectNodeDataList[Typ];
  while NodeData<>nil do begin
    n:=NodeData;
    NodeData:=NodeData.Next;
    n.Free;
  end;
  FProjectNodeDataList[Typ]:=nil;
End;

function TProjectInspectorForm.CreateNodeData(Typ: TProjectNodeType; aName: string; aRemoved: boolean): TProjectNodeData;
Begin
  Result := TProjectNodeData.Create;
  Result.Name := aName;
  Result.Typ := Typ;
  Result.Removed := aRemoved;
  Result.Next := FProjectNodeDataList[Typ];
  FProjectNodeDataList[Typ] := Result;
end;

function TProjectInspectorForm.GetNodeData(TVNode: TTreeNode): TProjectNodeData;
var
  o: TObject;
begin
  Result:=nil;
  if (TVNode=nil) then exit;
  o:=TObject(TVNode.Data);
  if o is TFileNameItem then
    o:=TObject(TFileNameItem(o).Data);
  if o is TProjectNodeData then
    Result:=TProjectNodeData(o);
end;

function TProjectInspectorForm.GetNodeItem(NodeData: TProjectNodeData): TObject;
begin
  Result:=nil;
  if (LazProject=nil) or (NodeData=nil) then exit;
  case NodeData.Typ of
  pntFile:
    if NodeData.Removed then
      Result:=nil
    else
      Result:=LazProject.UnitInfoWithFilename(NodeData.Name,[pfsfOnlyProjectFiles]);
  pntDependency:
    if NodeData.Removed then
      Result:=LazProject.FindRemovedDependencyByName(NodeData.Name)
    else
      Result:=LazProject.FindDependencyByName(NodeData.Name);
  end;
end;

end.

