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
    Browser for packages, classes, methods, functions.
    Scope:
      Browse units of IDE, or a project or a package.
      Browse with required packages or without.
    Sort:
      Owner, unit, class, visibility, type (procedure, var, const, ...), identifier

  Notes:
    The codetools provides TCodeTree of every unit.

  ToDo:
    - at the moment editing the filter texts only update on editing done
      Update after some idle time
    - double click on package: open package editor
    - double click on project: open project inspector
    - add package to project
    - add package to package of editor unit
    - add package+unit to editor unit
    - add package+unit+identifier to editor caret
    - scan recently used packages
    - scan packages in global links
}
unit CodeBrowser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, Forms, Controls, Graphics, Dialogs,
  Clipbrd, LCLIntf, AVL_Tree, StdCtrls, ExtCtrls, ComCtrls, Buttons,
  // codetools
  CodeAtom, BasicCodeTools, DefineTemplates, CodeTree, CodeCache,
  CodeToolManager, PascalParserTool, LinkScanner, FileProcs, CodeIndex,
  StdCodeTools,
  // IDEIntf
  IDEDialogs, LazConfigStorage, Project, PackageIntf, IDECommands, LazIDEIntf,
  DialogProcs,
  // IDE
  PackageSystem, PackageDefs, LazarusIDEStrConsts, IDEOptionDefs,
  EnvironmentOpts, Menus;


type
  TCodeBrowserLevel = (
    cblPackages,
    cblUnits,
    cblIdentifiers
    );
    
  TCodeBrowserTextFilter = (
    cbtfBegins,
    cbtfContains
    );
    
const
  CodeBrowserLevelNames: array[TCodeBrowserLevel] of string = (
    'Packages',
    'Units',
    'Identifiers'
    );
    
  CodeBrowserTextFilterNames: array[TCodeBrowserTextFilter] of string = (
    'Begins',
    'Contains'
    );

  CodeBrowserIDEName     = ' '+'Lazarus IDE';// Note: space is needed to avoid name clashing
  CodeBrowserProjectName = ' '+'Project';
  CodeBrowserHidden = ' ';

type

  { TCodeBrowserViewOptions }

  TCodeBrowserViewOptions = class
  private
    FChangeStamp: integer;
    FModified: boolean;
    FScope: string;
    FLevels: TStrings;
    FShowEmptyNodes: boolean;
    FShowPrivate: boolean;
    FShowProtected: boolean;
    FWithRequiredPackages: boolean;
    FLevelFilterText: array[TCodeBrowserLevel] of string;
    FLevelFilterType: array[TCodeBrowserLevel] of TCodeBrowserTextFilter;
    function GetLevelFilterText(Level: TCodeBrowserLevel): string;
    function GetLevelFilterType(Level: TCodeBrowserLevel
      ): TCodeBrowserTextFilter;
    procedure SetLevelFilterText(Level: TCodeBrowserLevel; const AValue: string
      );
    procedure SetLevelFilterType(Level: TCodeBrowserLevel;
      const AValue: TCodeBrowserTextFilter);
    procedure SetModified(const AValue: boolean);
    procedure SetScope(const AValue: string);
    procedure SetLevels(const AValue: TStrings);
    procedure SetShowEmptyNodes(const AValue: boolean);
    procedure SetShowPrivate(const AValue: boolean);
    procedure SetShowProtected(const AValue: boolean);
    procedure SetWithRequiredPackages(const AValue: boolean);
    procedure IncreaseChangeStamp;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromConfig(ConfigStore: TConfigStorage; const Path: string);
    procedure SaveToConfig(ConfigStore: TConfigStorage; const Path: string);
    function HasLevel(Level: TCodeBrowserLevel): boolean;
  public
    property Scope: string read FScope write SetScope;
    property WithRequiredPackages: boolean read FWithRequiredPackages write SetWithRequiredPackages;
    property Levels: TStrings read FLevels write SetLevels;
    property ShowPrivate: boolean read FShowPrivate write SetShowPrivate;
    property ShowProtected: boolean read FShowProtected write SetShowProtected;
    property ShowEmptyNodes: boolean read FShowEmptyNodes write SetShowEmptyNodes;
    property LevelFilterText[Level: TCodeBrowserLevel]: string read GetLevelFilterText write SetLevelFilterText;
    property LevelFilterType[Level: TCodeBrowserLevel]: TCodeBrowserTextFilter read GetLevelFilterType write SetLevelFilterType;
    property Modified: boolean read FModified write SetModified;
    property ChangeStamp: integer read FChangeStamp;
  end;


  TCodeBrowserWorkStage = (
    cbwsGetScopeOptions,
    cbwsGatherPackages,
    cbwsFreeUnusedPackages,
    cbwsAddNewPackages,
    cbwsGatherFiles,
    cbwsGatherOutdatedFiles,
    cbwsUpdateUnits,
    cbwsGetViewOptions,
    cbwsUpdateTreeView,
    cbwsFinished
    );
    
  TExpandableNodeType = (
    entPackage,
    entUnit,
    entClass
    );
    
  TCopyNodeType = (
    cntIdentifier,
    cntDescription
    );

  { TCodeBrowserView }

  TCodeBrowserView = class(TForm)
    AllClassesSeparatorMenuItem: TMenuItem;
    AllPackagesSeparatorMenuItem: TMenuItem;
    AllUnitsSeparatorMenuItem: TMenuItem;
    BrowseTreeView: TTreeView;
    ShowEmptyNodesCheckBox: TCheckBox;
    CollapseAllClassesMenuItem: TMenuItem;
    CollapseAllPackagesMenuItem: TMenuItem;
    CollapseAllUnitsMenuItem: TMenuItem;
    CopyDescriptionMenuItem: TMenuItem;
    CopyIdentifierMenuItem: TMenuItem;
    CopySeparatorMenuItem: TMenuItem;
    ExpandAllClassesMenuItem: TMenuItem;
    ExpandAllPackagesMenuItem: TMenuItem;
    ExpandAllUnitsMenuItem: TMenuItem;
    ExportMenuItem: TMenuItem;
    IdentifierFilterBeginsSpeedButton: TSpeedButton;
    IdentifierFilterContainsSpeedButton: TSpeedButton;
    IdentifierFilterEdit: TEdit;
    ImageList1: TImageList;
    LevelsGroupBox: TGroupBox;
    OptionsGroupBox: TGroupBox;
    PackageFilterBeginsSpeedButton: TSpeedButton;
    PackageFilterContainsSpeedButton: TSpeedButton;
    PackageFilterEdit: TEdit;
    PopupMenu1: TPopupMenu;
    ProgressBar1: TProgressBar;
    ScopeComboBox: TComboBox;
    ScopeGroupBox: TGroupBox;
    ScopeWithRequiredPackagesCheckBox: TCheckBox;
    ShowIdentifiersCheckBox: TCheckBox;
    ShowPackagesCheckBox: TCheckBox;
    ShowPrivateCheckBox: TCheckBox;
    ShowProtectedCheckBox: TCheckBox;
    ShowUnitsCheckBox: TCheckBox;
    StatusBar1: TStatusBar;
    UnitFilterBeginsSpeedButton: TSpeedButton;
    UnitFilterContainsSpeedButton: TSpeedButton;
    UnitFilterEdit: TEdit;
    procedure BrowseTreeViewMouseDown(Sender: TOBject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BrowseTreeViewShowHint(Sender: TObject; HintInfo: PHintInfo);
    procedure CollapseAllPackagesMenuItemClick(Sender: TObject);
    procedure CollapseAllUnitsMenuItemClick(Sender: TObject);
    procedure CollapseAllClassesMenuItemClick(Sender: TObject);
    procedure CopyDescriptionMenuItemClick(Sender: TObject);
    procedure CopyIdentifierMenuItemClick(Sender: TObject);
    procedure ExpandAllClassesMenuItemClick(Sender: TObject);
    procedure ExpandAllPackagesMenuItemClick(Sender: TObject);
    procedure ExpandAllUnitsMenuItemClick(Sender: TObject);
    procedure ExportMenuItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PackageFilterEditEditingDone(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure ScopeComboBoxGetItems(Sender: TObject);
    procedure ScopeComboBoxEditingDone(Sender: TObject);
    procedure ScopeWithRequiredPackagesCheckBoxChange(Sender: TObject);
    procedure OnIdle(Sender: TObject; var Done: Boolean);
    procedure ShowIdentifiersCheckBoxChange(Sender: TObject);
    procedure ShowPackagesCheckBoxChange(Sender: TObject);
    procedure ShowPrivateCheckBoxChange(Sender: TObject);
    procedure ShowUnitsCheckBoxChange(Sender: TObject);
  private
    FIDEDescription: string;
    FOptions: TCodeBrowserViewOptions;
    FOptionsChangeStamp: integer;
    FProjectDescription: string;
    FParserRoot: TCodeBrowserUnitList;
    FScannedBytes: PtrInt;
    FScannedIdentifiers: PtrInt;
    FScannedLines: PtrInt;
    FScannedPackages: integer;
    FScannedUnits: integer;
    FUpdateNeeded: boolean;
    FViewRoot: TCodeBrowserUnitList;
    FVisibleIdentifiers: PtrInt;
    FVisiblePackages: integer;
    FVisibleUnits: integer;
    FWorkingParserRoot: TCodeBrowserUnitList;
    fUpdateCount: integer;
    fStage: TCodeBrowserWorkStage;
    fOutdatedFiles: TAVLTree;// tree of TCodeBrowserUnit
    fLastStatusBarUpdate: TDateTime;
    ImgIDDefault: integer;
    ImgIDProgramCode: Integer;
    ImgIDUnitCode: Integer;
    ImgIDInterfaceSection: Integer;
    ImgIDImplementation: Integer;
    ImgIDInitialization: Integer;
    ImgIDFinalization: Integer;
    ImgIDTypeSection: Integer;
    ImgIDType: Integer;
    ImgIDVarSection: Integer;
    ImgIDVariable: Integer;
    ImgIDConstSection: Integer;
    ImgIDConst: Integer;
    ImgIDClass: Integer;
    ImgIDProc: Integer;
    ImgIDProperty: Integer;
    ImgIDPackage: Integer;
    ImgIDProject: Integer;
    procedure LoadOptions;
    procedure LoadLevelsGroupBox;
    procedure LoadFilterGroupbox;
    procedure FillScopeComboBox;
    procedure SetScannedBytes(const AValue: PtrInt);
    procedure SetScannedIdentifiers(const AValue: PtrInt);
    procedure SetScannedLines(const AValue: PtrInt);
    procedure SetScannedPackages(const AValue: integer);
    procedure SetScannedUnits(const AValue: integer);
    procedure SetUpdateNeeded(const AValue: boolean);
    procedure SetVisibleIdentifiers(const AValue: PtrInt);
    procedure SetVisiblePackages(const AValue: integer);
    procedure SetVisibleUnits(const AValue: integer);
    procedure Work(var Done: Boolean);
    procedure WorkGetScopeOptions;
    procedure WorkGatherPackages;
    procedure WorkFreeUnusedPackages;
    procedure WorkAddNewUnitLists;
    procedure WorkGatherFileLists;
    procedure WorkUpdateFileList(List: TCodeBrowserUnitList);
    procedure WorkGatherOutdatedFiles;
    procedure WorkUpdateUnits;
    procedure WorkUpdateUnit(AnUnit: TCodeBrowserUnit);
    procedure WorkGetViewOptions;
    procedure WorkUpdateTreeView;
    procedure FreeUnitList(List: TCodeBrowserUnitList);
    procedure UpdateStatusBar(Lazy: boolean);
    procedure RemoveUnit(AnUnit: TCodeBrowserUnit);
    function CountIdentifiers(Tool: TCodeTool): integer;
    procedure UpdateTreeView;
    procedure ClearTreeView;
    procedure InitTreeView;
    function ListOwnerToText(const ListOwner: string): string;
    procedure InitImageList;
    function GetNodeImage(CodeNode: TObject): integer;
    function GetTVNodeHint(TVNode: TTreeNode): string;
    procedure ExpandCollapseAllNodesInTreeView(NodeType: TExpandableNodeType;
                                               Expand: boolean);
    procedure CopyNode(TVNode: TTreeNode; NodeType: TCopyNodeType);
    procedure InvalidateStage(AStage: TCodeBrowserWorkStage);
  public
    procedure BeginUpdate;
    procedure EndUpdate;
    function ExportTree: TModalResult;
    function ExportTreeAsText(Filename: string): TModalResult;
    property ParserRoot: TCodeBrowserUnitList read FParserRoot;
    property WorkingParserRoot: TCodeBrowserUnitList read FWorkingParserRoot;
    property ViewRoot: TCodeBrowserUnitList read FViewRoot;
    property Options: TCodeBrowserViewOptions read FOptions;
    property IDEDescription: string read FIDEDescription;
    property ProjectDescription: string read FProjectDescription;
    property ScannedPackages: integer read FScannedPackages write SetScannedPackages;
    property ScannedUnits: integer read FScannedUnits write SetScannedUnits;
    property ScannedLines: PtrInt read FScannedLines write SetScannedLines;
    property ScannedBytes: PtrInt read FScannedBytes write SetScannedBytes;
    property ScannedIdentifiers: PtrInt read FScannedIdentifiers write SetScannedIdentifiers;
    property VisiblePackages: integer read FVisiblePackages write SetVisiblePackages;
    property VisibleUnits: integer read FVisibleUnits write SetVisibleUnits;
    property VisibleIdentifiers: PtrInt read FVisibleIdentifiers write SetVisibleIdentifiers;
    property UpdateNeeded: boolean read FUpdateNeeded write SetUpdateNeeded;
  end;
  
var
  CodeBrowserView: TCodeBrowserView = nil;
  
function StringToCodeBrowserTextFilter(const s: string): TCodeBrowserTextFilter;

implementation

const
  ProgressGetScopeStart=0;
  ProgressGetScopeSize=10;
  ProgressGatherPackagesStart=ProgressGetScopeStart+ProgressGetScopeSize;
  ProgressGatherPackagesSize=30;
  ProgressFreeUnusedPkgStart=ProgressGatherPackagesStart+ProgressGatherPackagesSize;
  ProgressFreeUnusedPkgSize=100;
  ProgressAddNewUnitListsStart=ProgressFreeUnusedPkgStart+ProgressFreeUnusedPkgSize;
  ProgressAddNewUnitListsSize=300;
  ProgressGatherFileListsStart=ProgressAddNewUnitListsStart+ProgressAddNewUnitListsSize;
  ProgressGatherFileListsSize=300;
  ProgressGatherOutdatedFilesStart=ProgressGatherFileListsStart+ProgressGatherFileListsSize;
  ProgressGatherOutdatedFilesSize=300;
  ProgressUpdateUnitsStart=ProgressGatherOutdatedFilesStart+ProgressGatherOutdatedFilesSize;
  ProgressUpdateUnitsSize=3000;
  ProgressGetViewOptionsStart=ProgressUpdateUnitsStart+ProgressUpdateUnitsSize;
  ProgressGetViewOptionsSize=10;
  ProgressUpdateTreeViewStart=ProgressGetViewOptionsStart+ProgressGetViewOptionsSize;
  ProgressUpdateTreeViewSize=1000;
  ProgressTotal=ProgressUpdateTreeViewStart+ProgressUpdateTreeViewSize;

function StringToCodeBrowserTextFilter(const s: string): TCodeBrowserTextFilter;
begin
  for Result:=Low(TCodeBrowserTextFilter) to High(TCodeBrowserTextFilter) do
    if SysUtils.CompareText(CodeBrowserTextFilterNames[Result],s)=0 then exit;
  Result:=cbtfBegins;
end;


{ TCodeBrowserView }

procedure TCodeBrowserView.FormCreate(Sender: TObject);
begin
  FOptions:=TCodeBrowserViewOptions.Create;
  
  FIDEDescription:=lisLazarusIDE;
  FProjectDescription:=dlgEnvProject;

  Name:=NonModalIDEWindowNames[nmiwCodeBrowser];
  Caption := lisCodeBrowser;
  EnvironmentOptions.IDEWindowLayoutList.Apply(Self,Name);
  
  ScopeGroupBox.Caption:=dlgScope;
  ScopeWithRequiredPackagesCheckBox.Caption:=lisWithRequiredPackages;
  LevelsGroupBox.Caption:=lisLevels;
  ShowPackagesCheckBox.Caption:=lisShowPackages;
  ShowUnitsCheckBox.Caption:=lisShowUnits;
  ShowIdentifiersCheckBox.Caption:=lisShowIdentifiers;

  OptionsGroupBox.Caption:=lisFilter;
  ShowPrivateCheckBox.Caption:=lisPrivate;
  ShowProtectedCheckBox.Caption:=lisProtected;
  ShowEmptyNodesCheckBox.Caption:=lisShowEmptyUnitsPackages;

  ExpandAllPackagesMenuItem.Caption:=lisExpandAllPackages;
  CollapseAllPackagesMenuItem.Caption:=lisCollapseAllPackages;
  ExpandAllUnitsMenuItem.Caption:=lisExpandAllUnits;
  CollapseAllUnitsMenuItem.Caption:=lisCollapseAllUnits;
  ExpandAllClassesMenuItem.Caption:=lisExpandAllClasses;
  CollapseAllClassesMenuItem.Caption:=lisCollapseAllClasses;
  ExportMenuItem.Caption:=lisExport;
  
  PackageFilterBeginsSpeedButton.Caption:=lisBegins;
  PackageFilterBeginsSpeedButton.Hint:=lisPackageNameBeginsWith;
  PackageFilterContainsSpeedButton.Caption:=lisContains;
  PackageFilterContainsSpeedButton.Hint:=lisPackageNameContains;
  UnitFilterBeginsSpeedButton.Caption:=lisBegins;
  UnitFilterBeginsSpeedButton.Hint:=lisUnitNameBeginsWith;
  UnitFilterContainsSpeedButton.Caption:=lisContains;
  UnitFilterContainsSpeedButton.Hint:=lisUnitNameContains;
  IdentifierFilterBeginsSpeedButton.Caption:=lisBegins;
  IdentifierFilterBeginsSpeedButton.Hint:=lisIdentifierBeginsWith;
  IdentifierFilterContainsSpeedButton.Caption:=lisContains;
  IdentifierFilterContainsSpeedButton.Hint:=lisIdentifierContains;
  
  ProgressBar1.Max:=ProgressTotal;

  InitImageList;
  LoadOptions;
  
  UpdateNeeded:=true;
  Application.AddOnIdleHandler(@OnIdle);
end;

procedure TCodeBrowserView.FormDestroy(Sender: TObject);
begin
  ClearTreeView;
  FreeAndNil(fOutdatedFiles);
  FreeAndNil(FViewRoot);
  FreeAndNil(FParserRoot);
  FreeAndNil(FWorkingParserRoot);
  FreeAndNil(FOptions);
end;

procedure TCodeBrowserView.PackageFilterEditEditingDone(Sender: TObject);
begin
  InvalidateStage(cbwsGetViewOptions);
end;

procedure TCodeBrowserView.PopupMenu1Popup(Sender: TObject);
var
  TVNode: TTreeNode;
  Node: TObject;
  Identifier: String;
begin
  ExpandAllPackagesMenuItem.Visible:=Options.HasLevel(cblPackages);
  CollapseAllPackagesMenuItem.Visible:=ExpandAllPackagesMenuItem.Visible;
  AllPackagesSeparatorMenuItem.Visible:=ExpandAllPackagesMenuItem.Visible;
  
  ExpandAllUnitsMenuItem.Visible:=Options.HasLevel(cblUnits);
  CollapseAllUnitsMenuItem.Visible:=ExpandAllUnitsMenuItem.Visible;
  AllUnitsSeparatorMenuItem.Visible:=ExpandAllUnitsMenuItem.Visible;

  ExpandAllClassesMenuItem.Visible:=Options.HasLevel(cblIdentifiers);
  CollapseAllClassesMenuItem.Visible:=ExpandAllClassesMenuItem.Visible;
  AllClassesSeparatorMenuItem.Visible:=ExpandAllClassesMenuItem.Visible;

  TVNode:=BrowseTreeView.Selected;
  Node:=nil;
  if TVNode<>nil then
    Node:=TOBject(TVNode.Data);
  if Node<>nil then begin
    if Node is TCodeBrowserNode then
      Identifier:=TCodeBrowserNode(Node).Identifier
    else
      Identifier:='';
    CopyDescriptionMenuItem.Caption:=lisCopyDescription;
    CopyIdentifierMenuItem.Caption:=Format(lisCopyIdentifier, ['"', Identifier,
     '"']);
    CopyDescriptionMenuItem.Visible:=true;
    CopyIdentifierMenuItem.Visible:=Identifier<>'';
    CopySeparatorMenuItem.Visible:=true;
  end else begin
    CopyDescriptionMenuItem.Visible:=false;
    CopyIdentifierMenuItem.Visible:=false;
    CopySeparatorMenuItem.Visible:=false;
  end;
end;

procedure TCodeBrowserView.ScopeComboBoxGetItems(Sender: TObject);
begin
  FillScopeComboBox;
end;

procedure TCodeBrowserView.ScopeComboBoxEditingDone(Sender: TObject);
begin
  InvalidateStage(cbwsGetScopeOptions);
end;

procedure TCodeBrowserView.ScopeWithRequiredPackagesCheckBoxChange(
  Sender: TObject);
begin
  InvalidateStage(cbwsGetScopeOptions);
end;

procedure TCodeBrowserView.OnIdle(Sender: TObject; var Done: Boolean);
var
  AControl: TWinControl;
begin
  AControl:=FindOwnerControl(GetFocus);
  if (AControl=nil) or (GetFirstParentForm(AControl)<>Self) then exit;
  // this form is focused -> let's work
  Work(Done);
end;

procedure TCodeBrowserView.ShowIdentifiersCheckBoxChange(Sender: TObject);
begin
  InvalidateStage(cbwsGetViewOptions);
end;

procedure TCodeBrowserView.ShowPackagesCheckBoxChange(Sender: TObject);
begin
  //DebugLn(['TCodeBrowserView.ShowPackagesCheckBoxChange ']);
  InvalidateStage(cbwsGetViewOptions);
end;

procedure TCodeBrowserView.ShowPrivateCheckBoxChange(Sender: TObject);
begin
  InvalidateStage(cbwsGetViewOptions);
end;

procedure TCodeBrowserView.ShowUnitsCheckBoxChange(Sender: TObject);
begin
  InvalidateStage(cbwsGetViewOptions);
end;

procedure TCodeBrowserView.LoadOptions;
begin
  BeginUpdate;
  ScopeWithRequiredPackagesCheckBox.Checked:=Options.WithRequiredPackages;
  ScopeComboBox.Text:=Options.Scope;
  LoadLevelsGroupBox;
  LoadFilterGroupbox;
  EndUpdate;
end;

procedure TCodeBrowserView.LoadLevelsGroupBox;
begin
  ShowPackagesCheckBox.Checked:=Options.HasLevel(cblPackages);
  ShowUnitsCheckBox.Checked:=Options.HasLevel(cblUnits);
  ShowIdentifiersCheckBox.Checked:=Options.HasLevel(cblIdentifiers);
end;

procedure TCodeBrowserView.LoadFilterGroupbox;
begin
  ShowPrivateCheckBox.Checked:=Options.ShowPrivate;
  ShowProtectedCheckBox.Checked:=Options.ShowProtected;
  ShowEmptyNodesCheckBox.Checked:=Options.ShowEmptyNodes;

  PackageFilterEdit.Text:=Options.LevelFilterText[cblPackages];
  case Options.LevelFilterType[cblPackages] of
  cbtfBegins:   PackageFilterBeginsSpeedButton.Down:=true;
  cbtfContains: PackageFilterContainsSpeedButton.Down:=true;
  end;

  UnitFilterEdit.Text:=Options.LevelFilterText[cblUnits];
  case Options.LevelFilterType[cblUnits] of
  cbtfBegins:   UnitFilterBeginsSpeedButton.Down:=true;
  cbtfContains: UnitFilterContainsSpeedButton.Down:=true;
  end;

  IdentifierFilterEdit.Text:=Options.LevelFilterText[cblIdentifiers];
  case Options.LevelFilterType[cblIdentifiers] of
  cbtfBegins:   IdentifierFilterBeginsSpeedButton.Down:=true;
  cbtfContains: IdentifierFilterContainsSpeedButton.Down:=true;
  end;
end;

procedure TCodeBrowserView.FillScopeComboBox;
var
  sl: TStringList;
  i: Integer;
begin
  sl:=TStringList.Create;
  if PackageGraph<>nil then begin
    for i:=0 to PackageGraph.Count-1 do
      sl.Add(PackageGraph.Packages[i].Name);
  end;
  sl.Sort;
  sl.Insert(0,IDEDescription);
  sl.Insert(1,ProjectDescription);
  ScopeComboBox.Items.Assign(sl);
  sl.Free;
end;

procedure TCodeBrowserView.InitImageList;

  procedure AddResImg(ImgList: TImageList; const ResName: string;
    out ImgID: integer);
  var
    Bitmap: TCustomBitmap;
    Resource: TLResource;
  begin
    //TODO: use ImgList.AddLazarusResource
    Resource:=LazarusResources.Find(ResName);
    if Resource=nil then
      DebugLn('TCodeExplorerView.CodeExplorerViewCREATE: ',
        ' WARNING: icon not found: "',ResName,'"');
    if SysUtils.CompareText(Resource.ValueType,'xpm')=0 then begin
      Bitmap:=TPixmap.Create;
    end else if SysUtils.CompareText(Resource.ValueType,'png')=0 then begin
      Bitmap:=TPortableNetworkGraphic.Create;
    end else
      DebugLn('TCodeExplorerView.CodeExplorerViewCREATE: ',
        ' WARNING: wrong icon format: "',ResName,'"="',Resource.ValueType,'"');
    Bitmap.LoadFromLazarusResource(ResName);
    //DebugLn(['AddResImg ',ResName,' ',Bitmap.Width,' ',Bitmap.Height]);
    ImgID:=ImgList.Add(Bitmap,nil);
    Bitmap.Free;
  end;

begin
  ImgIDDefault := Imagelist1.AddLazarusResource('ce_default');
  ImgIDProgramCode := Imagelist1.AddLazarusResource('ce_program');
  ImgIDUnitCode := Imagelist1.AddLazarusResource('ce_unit');
  ImgIDInterfaceSection := Imagelist1.AddLazarusResource('ce_interface');
  ImgIDImplementation := Imagelist1.AddLazarusResource('ce_implementation');
  ImgIDInitialization := Imagelist1.AddLazarusResource('ce_initialization');
  ImgIDFinalization := Imagelist1.AddLazarusResource('ce_finalization');
  ImgIDTypeSection := Imagelist1.AddLazarusResource('ce_type');
  ImgIDType := Imagelist1.AddLazarusResource('ce_type');
  ImgIDVarSection := Imagelist1.AddLazarusResource('ce_variable');
  ImgIDVariable := Imagelist1.AddLazarusResource('ce_variable');
  ImgIDConstSection := Imagelist1.AddLazarusResource('ce_const');
  ImgIDConst := Imagelist1.AddLazarusResource('ce_const');
  ImgIDClass := Imagelist1.AddLazarusResource('ce_class');
  ImgIDProc := Imagelist1.AddLazarusResource('ce_procedure');
  ImgIDProperty := Imagelist1.AddLazarusResource('ce_property');
  ImgIDPackage := Imagelist1.AddLazarusResource('item_package');
  ImgIDProject := Imagelist1.AddLazarusResource('item_project');
end;

procedure TCodeBrowserView.SetScannedBytes(const AValue: PtrInt);
begin
  if FScannedBytes=AValue then exit;
  FScannedBytes:=AValue;
end;

procedure TCodeBrowserView.SetScannedIdentifiers(const AValue: PtrInt);
begin
  if FScannedIdentifiers=AValue then exit;
  FScannedIdentifiers:=AValue;
end;

procedure TCodeBrowserView.SetScannedLines(const AValue: PtrInt);
begin
  if FScannedLines=AValue then exit;
  FScannedLines:=AValue;
end;

procedure TCodeBrowserView.SetScannedPackages(const AValue: integer);
begin
  if FScannedPackages=AValue then exit;
  FScannedPackages:=AValue;
end;

procedure TCodeBrowserView.SetScannedUnits(const AValue: integer);
begin
  if FScannedUnits=AValue then exit;
  FScannedUnits:=AValue;
end;

procedure TCodeBrowserView.SetUpdateNeeded(const AValue: boolean);
begin
  if FUpdateNeeded=AValue then exit;
  FUpdateNeeded:=AValue;
  if FUpdateNeeded then
    InvalidateStage(cbwsGetScopeOptions);
end;

procedure TCodeBrowserView.SetVisibleIdentifiers(const AValue: PtrInt);
begin
  if FVisibleIdentifiers=AValue then exit;
  FVisibleIdentifiers:=AValue;
end;

procedure TCodeBrowserView.SetVisiblePackages(const AValue: integer);
begin
  if FVisiblePackages=AValue then exit;
  FVisiblePackages:=AValue;
end;

procedure TCodeBrowserView.SetVisibleUnits(const AValue: integer);
begin
  if FVisibleUnits=AValue then exit;
  FVisibleUnits:=AValue;
end;

procedure TCodeBrowserView.Work(var Done: Boolean);
// do some work
// This is called during OnIdle, so progress in small steps
var
  OldStage: TCodeBrowserWorkStage;
begin
  OldStage:=fStage;
  case fStage of
  cbwsGetScopeOptions:     WorkGetScopeOptions;
  cbwsGatherPackages:      WorkGatherPackages;
  cbwsFreeUnusedPackages:  WorkFreeUnusedPackages;
  cbwsAddNewPackages:      WorkAddNewUnitLists;
  cbwsGatherFiles:         WorkGatherFileLists;
  cbwsGatherOutdatedFiles: WorkGatherOutdatedFiles;
  cbwsUpdateUnits:         WorkUpdateUnits;
  cbwsGetViewOptions:      WorkGetViewOptions;
  cbwsUpdateTreeView:      WorkUpdateTreeView;
  else
    FOptionsChangeStamp:=Options.ChangeStamp;
    UpdateNeeded:=false;
    Done:=true;
    ProgressBar1.Position:=ProgressTotal;
    exit;
  end;
  if ord(OldStage)<ord(cbwsFinished) then begin
    Done:=false;
    UpdateStatusBar(fStage<cbwsFinished);
  end;
  //if fStage=cbwsFinished then CodeToolBoss.WriteMemoryStats;
end;

procedure TCodeBrowserView.WorkGetScopeOptions;
begin
  DebugLn(['TCodeBrowserView.WorkGetScopeOptions START']);
  ProgressBar1.Position:=ProgressGetScopeStart;
  Options.WithRequiredPackages:=ScopeWithRequiredPackagesCheckBox.Checked;
  Options.Scope:=ScopeComboBox.Text;

  // this stage finished -> next stage
  if UpdateNeeded or Options.Modified then
    fStage:=cbwsGatherPackages
  else
    fStage:=cbwsGetViewOptions;
  ProgressBar1.Position:=ProgressGetScopeStart+ProgressGetScopeSize;
end;

procedure TCodeBrowserView.WorkGatherPackages;

  procedure AddPackage(APackage: TLazPackage);
  begin
    TCodeBrowserUnitList.Create(APackage.Name,FWorkingParserRoot);
  end;
  
  procedure AddPackages(FirstDependency: TPkgDependency);
  var
    List: TFPList;
    i: Integer;
  begin
    List:=nil;
    try
      PackageGraph.GetAllRequiredPackages(FirstDependency,List);
      if (List=nil) then exit;
      for i:=0 to List.Count-1 do begin
        if TObject(List[i]) is TLazPackage then
          AddPackage(TLazPackage(List[i]));
      end;
    finally
      List.Free;
    end;
  end;

var
  APackage: TLazPackage;
  RootOwner: string;
  i: Integer;
begin
  // clean up
  if fOutdatedFiles<>nil then fOutdatedFiles.Clear;

  // find ParserRoot
  RootOwner:='';
  if Options.Scope=IDEDescription then begin
    RootOwner:=CodeBrowserIDEName;
  end else if Options.Scope=ProjectDescription then begin
    RootOwner:=CodeBrowserProjectName;
  end else begin
    APackage:=PackageGraph.FindAPackageWithName(Options.Scope,nil);
    if APackage<>nil then
      RootOwner:=APackage.Name;
  end;
  DebugLn(['TCodeBrowserView.WorkGatherPackages RootOwner="',RootOwner,'"']);
  FreeAndNil(FWorkingParserRoot);
  FWorkingParserRoot:=TCodeBrowserUnitList.Create(RootOwner,nil);
  
  // find required packages
  if Options.WithRequiredPackages then begin
    if SysUtils.CompareText(FWorkingParserRoot.Owner,CodeBrowserIDEName)=0 then begin
      for i:=0 to PackageGraph.Count-1 do
        AddPackage(PackageGraph[i]);
    end else if SysUtils.CompareText(FWorkingParserRoot.Owner,CodeBrowserProjectName)=0
    then begin
      AddPackages(Project1.FirstRequiredDependency);
    end else if FWorkingParserRoot.Owner<>'' then begin
      APackage:=PackageGraph.FindAPackageWithName(FWorkingParserRoot.Owner,nil);
      if APackage<>nil then
        AddPackages(APackage.FirstRequiredDependency);
    end;
  end;
  
  // update ParserRoot item (childs will be updated on next Idle)
  if FParserRoot=nil then begin
    FParserRoot:=TCodeBrowserUnitList.Create(FWorkingParserRoot.Owner,nil);
    inc(FScannedPackages);
  end else begin
    FParserRoot.Owner:=FWorkingParserRoot.Owner;
  end;
  
  // this stage finished -> next stage
  fStage:=cbwsFreeUnusedPackages;
  ProgressBar1.Position:=ProgressGatherPackagesStart+ProgressGatherPackagesSize;
end;

procedure TCodeBrowserView.WorkFreeUnusedPackages;

  function FindUnusedUnitList: TCodeBrowserUnitList;
  var
    Node: TAVLTreeNode;
    UnusedPackage: TCodeBrowserUnitList;
    PackageName: String;
  begin
    // find an unused package (a package in ParserRoot but not in WorkingParserRoot)
    Result:=nil;
    if (FParserRoot=nil) or (FParserRoot.UnitLists=nil) then exit;
    Node:=FParserRoot.UnitLists.FindLowest;
    while Node<>nil do begin
      UnusedPackage:=TCodeBrowserUnitList(Node.Data);
      PackageName:=UnusedPackage.Owner;
      if (FWorkingParserRoot=nil)
      or (FWorkingParserRoot.UnitLists=nil)
      or (FWorkingParserRoot.UnitLists.FindKey(@PackageName,
         @ComparePAnsiStringWithUnitListOwner)=nil)
      then begin
        Result:=UnusedPackage;
        exit;
      end;
      Node:=FParserRoot.UnitLists.FindSuccessor(Node);
    end;
  end;
  
var
  UnusedPackage: TCodeBrowserUnitList;
begin
  DebugLn(['TCodeBrowserView.WorkFreeUnusedPackages START']);

  // find an unused package
  UnusedPackage:=FindUnusedUnitList;
  if UnusedPackage=nil then begin
    // this stage finished -> next stage
    fStage:=cbwsAddNewPackages;
    ProgressBar1.Position:=ProgressFreeUnusedPkgStart+ProgressFreeUnusedPkgSize;
    exit;
  end;

  // free the unused package
  FreeUnitList(UnusedPackage);
end;

procedure TCodeBrowserView.WorkAddNewUnitLists;
var
  Node: TAVLTreeNode;
  List: TCodeBrowserUnitList;
begin
  ProgressBar1.Position:=ProgressAddNewUnitListsStart;
  if (FWorkingParserRoot<>nil) and (FWorkingParserRoot.UnitLists<>nil)
  and (FParserRoot<>nil) then begin
    Node:=FWorkingParserRoot.UnitLists.FindLowest;
    while Node<>nil do begin
      List:=TCodeBrowserUnitList(Node.Data);
      if FParserRoot.FindUnitList(List.Owner)=nil then begin
        // new unit list
        TCodeBrowserUnitList.Create(List.Owner,FParserRoot);
        inc(FScannedPackages);
      end;
      Node:=FWorkingParserRoot.UnitLists.FindSuccessor(Node);
    end;
  end;
  
  // this stage finished -> next stage
  fStage:=cbwsGatherFiles;
  ProgressBar1.Position:=ProgressAddNewUnitListsStart+ProgressAddNewUnitListsSize;
end;

procedure TCodeBrowserView.WorkGatherFileLists;

  function ListFilesAreValid(List: TCodeBrowserUnitList): boolean;
  begin
    Result:=List.UnitsValid;
  end;

  function FindListWithInvalidFileList(StartList: TCodeBrowserUnitList
    ): TCodeBrowserUnitList;
  var
    APackage: TCodeBrowserUnitList;
    Node: TAVLTreeNode;
  begin
    Result:=nil;
    if StartList=nil then exit;
    if not ListFilesAreValid(StartList) then begin
      Result:=StartList;
      exit;
    end;
    if (StartList.UnitLists=nil) then exit;
    Node:=StartList.UnitLists.FindLowest;
    while Node<>nil do begin
      APackage:=TCodeBrowserUnitList(Node.Data);
      Result:=FindListWithInvalidFileList(APackage);
      if Result<>nil then exit;
      Node:=StartList.UnitLists.FindSuccessor(Node);
    end;
  end;

var
  List: TCodeBrowserUnitList;
begin
  DebugLn(['TCodeBrowserView.WorkGatherFiles START']);
  // find a unit list which needs update
  List:=FindListWithInvalidFileList(FParserRoot);
  if List=nil then begin
    // this stage finished -> next stage
    fStage:=cbwsGatherOutdatedFiles;
    ProgressBar1.Position:=ProgressGatherFileListsStart+ProgressGatherFileListsSize;
    exit;
  end;
  
  WorkUpdateFileList(List);
end;

procedure TCodeBrowserView.WorkUpdateFileList(List: TCodeBrowserUnitList);
var
  NewFileList: TAVLTree;

  procedure AddFile(const Filename: string; ClearIncludedByInfo: boolean);
  begin
    //DebugLn(['AddFile Filename="',Filename,'"']);
    if Filename='' then exit;
    if System.Pos('$',Filename)>0 then begin
      DebugLn(['WARNING: TCodeBrowserView.WorkUpdateFiles Macros in filename ',Filename]);
      exit;
    end;
    if NewFileList.FindKey(@Filename,@ComparePAnsiStringWithUnitFilename)<>nil
    then exit;
    //DebugLn(['TCodeBrowserView.WorkUpdateFiles AddFile ',Filename]);
    NewFileList.Add(TCodeBrowserUnit.Create(Filename));
    if ClearIncludedByInfo then begin
      CodeToolBoss.SourceCache.ClearIncludedByEntry(Filename);
    end;
  end;
  
  procedure AddFilesOfProject(AProject: TProject);
  var
    AnUnitInfo: TUnitInfo;
  begin
    if AProject=nil then exit;
    AnUnitInfo:=AProject.FirstPartOfProject;
    //DebugLn(['AddFilesOfProject ',AnUnitInfo<>nil]);
    while AnUnitInfo<>nil do begin
      //DebugLn(['AddFilesOfProject ',AnUnitInfo.Filename]);
      if FilenameIsPascalUnit(AnUnitInfo.Filename)
      or (AnUnitInfo=aProject.MainUnitInfo) then
        AddFile(AnUnitInfo.Filename,false);
      AnUnitInfo:=AnUnitInfo.NextPartOfProject;
    end;
  end;
  
  procedure AddFilesOfPackageFCL;
  var
    LazDir: String;
    UnitLinks: String;
    SpacePos: LongInt;
    Filename: String;
    StartPos: Integer;
    EndPos: LongInt;
  begin
    // use unitlinks of the lazarus source directory
    LazDir:=AppendPathDelim(EnvironmentOptions.LazarusDirectory);
    if (LazDir='') or (not FilenameIsAbsolute(LazDir)) then exit;
    UnitLinks:=CodeToolBoss.GetUnitLinksForDirectory(LazDir);
    StartPos:=1;
    while StartPos<=length(UnitLinks) do begin
      EndPos:=StartPos;
      while (EndPos<=length(UnitLinks))
      and (not (UnitLinks[EndPos] in [#10,#13])) do
        inc(EndPos);
      if EndPos>StartPos then begin
        SpacePos:=StartPos;
        while (SpacePos<=length(UnitLinks)) and (UnitLinks[SpacePos]<>' ') do
          inc(SpacePos);
        if (SpacePos>StartPos) and (SpacePos<EndPos) then begin
          Filename:=copy(UnitLinks,SpacePos+1,EndPos-SpacePos-1);
          AddFile(Filename,true);
        end;
      end;
      StartPos:=EndPos;
      while (StartPos<=length(UnitLinks))
      and (UnitLinks[StartPos] in [#10,#13]) do
        inc(StartPos);
    end;
  end;
  
  procedure AddFilesOfPackage(APackage: TLazPackage);
  var
    i: Integer;
    PkgFile: TPkgFile;
  begin
    if APackage=nil then exit;
    for i:=0 to APackage.FileCount-1 do begin
      PkgFile:=APackage.Files[i];
      if (PkgFile.FileType in PkgFileUnitTypes) then
        AddFile(PkgFile.GetFullFilename,true);
    end;
    if APackage.Name='FCL' then begin
      AddFilesOfPackageFCL;
    end;
  end;
  
  procedure AddFilesOfDirectory(const Directory: string;
    ClearIncludedByInfo: boolean);
  // ! needs ending PathDelim !
  var
    FileInfo: TSearchRec;
  begin
    //DebugLn(['AddFilesOfDirectory Directory="',Directory,'"']);
    if (not FilenameIsAbsolute(Directory))
    or (not DirectoryExistsUTF8(Directory)) then begin
      DebugLn(['AddFilesOfDirectory WARNING: does not exist: "',Directory,'"']);
      exit;
    end;
    if FindFirstUTF8(Directory+FileMask,faAnyFile,FileInfo)=0 then begin
      repeat
        // check if special file
        if (FileInfo.Name='.') or (FileInfo.Name='..') or (FileInfo.Name='')
        then
          continue;
        if FilenameIsPascalUnit(FileInfo.Name) then
          AddFile(Directory+FileInfo.Name,ClearIncludedByInfo);
      until FindNextUTF8(FileInfo)<>0;
    end;
    FindCloseUTF8(FileInfo);
  end;
  
  procedure AddFilesOfSearchPath(const SrcPath, BaseDir: string;
    ClearIncludedByInfo: boolean);
  var
    Dir: String;
    p: Integer;
  begin
    //DebugLn(['AddFilesOfSearchPath SrcPath="',SrcPath,'" BaseDir="',BaseDir,'"']);
    p:=1;
    while (p<=length(SrcPath)) do begin
      Dir:=GetNextDelimitedItem(SrcPath,';',p);
      if Dir<>'' then begin
        if not FilenameIsAbsolute(Dir) then
          Dir:=BaseDir+PathDelim+Dir;
        Dir:=CleanAndExpandDirectory(Dir);
        AddFilesOfDirectory(Dir,ClearIncludedByInfo);
      end;
    end;
  end;
  
  procedure AddFilesOfIDE;
  var
    LazDefines: TDefineTemplate;
    LazSrcDir: TDefineTemplate;
    LazIDEDir: TDefineTemplate;
    LazIDESrcPath: TDefineTemplate;
    SrcPath: String;
    LazDir: String;
  begin
    LazDir:=AppendPathDelim(EnvironmentOptions.LazarusDirectory);
    if not DirectoryExistsUTF8(LazDir) then begin
      DebugLn(['AddFilesOfIDE WARNING: lazarus directory not found: "',LazDir,'"']);
      exit;
    end;
    // get the SrcPath template of the lazarus/ide directory
    LazDefines:=CodeToolBoss.DefineTree
                      .FindDefineTemplateByName(StdDefTemplLazarusSources,true);
    if LazDefines=nil then begin
      DebugLn(['AddFilesOfIDE WARNING: codetools define templates for lazarus not found']);
      exit;
    end;
    LazSrcDir:=LazDefines.FindChildByName(StdDefTemplLazarusSrcDir);
    if LazSrcDir=nil then begin
      DebugLn(['AddFilesOfIDE WARNING: codetools define templates for lazarus directory not found']);
      exit;
    end;
    LazIDEDir:=LazSrcDir.FindChildByName('ide');
    if LazIDEDir=nil then begin
      DebugLn(['AddFilesOfIDE WARNING: codetools define templates for lazarus ide directory not found']);
      exit;
    end;
    LazIDESrcPath:=LazIDEDir.FindChildByName('IDE path addition');
    if LazIDESrcPath=nil then begin
      DebugLn(['AddFilesOfIDE WARNING: codetools define templates for src path of lazarus ide directory not found']);
      exit;
    end;
    SrcPath:=LazIDESrcPath.Value;
    AddFilesOfSearchPath(SrcPath+';.',LazDir+'ide'+PathDelim,true);
  end;

  procedure DeleteUnusedFiles;
  var
    Node: TAVLTreeNode;
    CurUnit: TCodeBrowserUnit;
    NextNode: TAVLTreeNode;
  begin
    if List.Units=nil then exit;
    Node:=List.Units.FindLowest;
    while Node<>nil do begin
      NextNode:=List.Units.FindSuccessor(Node);
      CurUnit:=TCodeBrowserUnit(Node.Data);
      if NewFileList.FindKey(@CurUnit.Filename,
        @ComparePAnsiStringWithUnitFilename)=nil
      then begin
        // this unit is not part of List anymore -> delete
        RemoveUnit(CurUnit);
        List.DeleteUnit(CurUnit);
      end;
      Node:=NextNode;
    end;
  end;
  
  procedure AddNewFiles;
  var
    Node: TAVLTreeNode;
    AnUnit: TCodeBrowserUnit;
  begin
    Node:=NewFileList.FindLowest;
    while Node<>nil do begin
      AnUnit:=TCodeBrowserUnit(Node.Data);
      //DebugLn(['AddNewFiles ',AnUnit.Filename,' exists=',List.FindUnit(AnUnit.Filename)<>nil]);
      if List.FindUnit(AnUnit.Filename)=nil then begin
        // this unit was not part of List -> add
        //DebugLn(['AddNewFiles "',List.Owner,'" "',AnUnit.Filename,'"']);
        List.AddUnit(AnUnit.Filename);
      end;
      Node:=NewFileList.FindSuccessor(Node);
    end;
  end;

var
  APackage: TLazPackage;
begin
  DebugLn(['TCodeBrowserView.WorkUpdateFiles ',List.Owner]);
  NewFileList:=TAVLTree.Create(@CompareUnitFilenames);
  try
    // get new list of files
    if List.Owner=CodeBrowserIDEName then begin
      AddFilesOfIDE;
    end else if List.Owner=CodeBrowserProjectName then begin
      AddFilesOfProject(Project1);
    end else begin
      APackage:=PackageGraph.FindAPackageWithName(List.Owner,nil);
      AddFilesOfPackage(APackage);
    end;
    
    // update file list
    DeleteUnusedFiles;
    AddNewFiles;
    
    List.UnitsValid:=true;
  finally
    NewFileList.FreeAndClear;
    NewFileList.Free;
  end;
end;

procedure TCodeBrowserView.WorkGatherOutdatedFiles;
// add all files to fOutdatedFiles

  procedure AddFile(AnUnit: TCodeBrowserUnit);
  begin
    if fOutdatedFiles=nil then
      fOutdatedFiles:=TAVLTree.Create(@CompareUnitFilenames);
    if fOutdatedFiles.Find(AnUnit)<>nil then exit;
    fOutdatedFiles.Add(AnUnit);
  end;

  procedure AddFiles(List: TCodeBrowserUnitList);
  var
    Node: TAVLTreeNode;
  begin
    if List.Units<>nil then begin
      Node:=List.Units.FindLowest;
      while Node<>nil do begin
        AddFile(TCodeBrowserUnit(Node.Data));
        Node:=List.Units.FindSuccessor(Node);
      end;
    end;
    if List.UnitLists<>nil then begin
      Node:=List.UnitLists.FindLowest;
      while Node<>nil do begin
        AddFiles(TCodeBrowserUnitList(Node.Data));
        Node:=List.UnitLists.FindSuccessor(Node);
      end;
    end;
  end;

begin
  if fOutdatedFiles<>nil then
    fOutdatedFiles.Clear;
  AddFiles(ParserRoot);
  
  // this stage finished -> next stage
  fStage:=cbwsUpdateUnits;
  ProgressBar1.Position:=ProgressGatherOutdatedFilesStart+ProgressGatherOutdatedFilesSize;
end;

procedure TCodeBrowserView.WorkUpdateUnits;

  function FindOutdatedUnit: TCodeBrowserUnit;
  var
    Node: TAVLTreeNode;
  begin
    Result:=nil;
    if fOutdatedFiles=nil then exit;
    Node:=fOutdatedFiles.FindLowest;
    if Node=nil then exit;
    Result:=TCodeBrowserUnit(Node.Data);
  end;

const
  SmallTimeStep = (1/86400)/5;
var
  AnUnit: TCodeBrowserUnit;
  StartTime: TDateTime;
begin
  //DebugLn(['TCodeBrowserView.WorkUpdateUnits START']);
  CodeToolBoss.ActivateWriteLock;
  try
    // parse units
    StartTime:=Now;
    repeat
      AnUnit:=FindOutdatedUnit;
      if AnUnit=nil then begin
        // this stage finished -> next stage
        fStage:=cbwsGetViewOptions;
        ProgressBar1.Position:=ProgressUpdateUnitsStart+ProgressUpdateUnitsSize;
        exit;
      end;

      WorkUpdateUnit(AnUnit);
    until Abs(Now-StartTime)>SmallTimeStep;
  finally
    CodeToolBoss.DeactivateWriteLock;
  end;
end;

procedure TCodeBrowserView.WorkUpdateUnit(AnUnit: TCodeBrowserUnit);

  procedure UpdateScannedCounters(Tool: TCodeTool);
  var
    LineCnt: Integer;
    ByteCnt: Integer;
    i: Integer;
    Link: TSourceLink;
    CodeBuf: TCodeBuffer;
    LastCode: TCodeBuffer;
  begin
    if (Tool=nil) or (Tool.Scanner=nil) then exit;
    LineCnt:=0;
    ByteCnt:=0;
    LastCode:=nil;
    for i:=0 to Tool.Scanner.LinkCount-1 do begin
      Link:=Tool.Scanner.Links[i];
      CodeBuf:=TCodeBuffer(Link.Code);
      if CodeBuf<>LastCode then begin
        inc(LineCnt,LineEndCount(CodeBuf.Source));
        inc(ByteCnt,length(CodeBuf.Source));
        LastCode:=CodeBuf;
      end;
    end;
    AnUnit.ScannedBytes:=ByteCnt;
    AnUnit.ScannedLines:=LineCnt;
    AnUnit.ScannedIdentifiers:=CountIdentifiers(Tool);
    AnUnit.CodeTool:=Tool;
    inc(FScannedBytes,AnUnit.ScannedBytes);
    inc(FScannedLines,AnUnit.ScannedLines);
    inc(FScannedIdentifiers,AnUnit.ScannedIdentifiers);
    //DebugLn(['UpdateScannedCounters ',ExtractFileName(AnUnit.Filename),' LineCnt=',LineCnt,' ByteCnt=',ByteCnt,' ',DbgSName(AnUnit.CodeTool)]);
  end;

var
  MainCodeBuf: TCodeBuffer;
  Tool: TCodeTool;
begin
  //DebugLn(['TCodeBrowserView.WorkUpdateUnit START ',AnUnit.Filename]);
  // mark as updated
  fOutdatedFiles.Remove(AnUnit);
  // reset scanning counters
  if AnUnit.Scanned then begin
    dec(FScannedBytes,AnUnit.ScannedBytes);
    dec(FScannedLines,AnUnit.ScannedLines);
    dec(FScannedIdentifiers,AnUnit.ScannedIdentifiers);
    AnUnit.ScannedBytes:=0;
    AnUnit.ScannedLines:=0;
    AnUnit.ScannedIdentifiers:=0;
    dec(FScannedUnits);
  end;
  AnUnit.Scanned:=true;
  inc(FScannedUnits);
  // load the file
  AnUnit.CodeBuffer:=CodeToolBoss.LoadFile(AnUnit.Filename,false,false);
  if AnUnit.CodeBuffer=nil then exit;
  // check if this is a unit
  MainCodeBuf:=CodeToolBoss.GetMainCode(AnUnit.CodeBuffer);
  if MainCodeBuf<>AnUnit.CodeBuffer then begin
    // this file was used as an include file
    DebugLn(['TCodeBrowserView.WorkUpdateUnit HINT: this is not a unit: ',AnUnit.Filename,
      ' (it was included by ',MainCodeBuf.Filename,')']);
    exit;
  end;
  // scan
  CodeToolBoss.Explore(AnUnit.CodeBuffer,Tool,false,true);
  UpdateScannedCounters(Tool);
  //DebugLn(['TCodeBrowserView.WorkUpdateUnit END ',AnUnit.Filename]);
end;

procedure TCodeBrowserView.WorkGetViewOptions;
var
  NewLevels: TStringList;
begin
  //DebugLn(['TCodeBrowserView.WorkGetViewOptions START']);
  Options.ShowPrivate:=ShowPrivateCheckBox.Checked;
  Options.ShowProtected:=ShowProtectedCheckBox.Checked;
  Options.ShowEmptyNodes:=ShowEmptyNodesCheckBox.Checked;

  // levels
  NewLevels:=TStringList.Create;
  if ShowPackagesCheckBox.Checked then
    NewLevels.Add(CodeBrowserLevelNames[cblPackages]);
  if ShowUnitsCheckBox.Checked then
    NewLevels.Add(CodeBrowserLevelNames[cblUnits]);
  if ShowIdentifiersCheckBox.Checked then
    NewLevels.Add(CodeBrowserLevelNames[cblIdentifiers]);
  Options.Levels:=NewLevels;
  NewLevels.Free;

  // level filter
  Options.LevelFilterText[cblPackages]:=PackageFilterEdit.Text;
  if PackageFilterBeginsSpeedButton.Down then
    Options.LevelFilterType[cblPackages]:=cbtfBegins;
  if PackageFilterContainsSpeedButton.Down then
    Options.LevelFilterType[cblPackages]:=cbtfContains;

  Options.LevelFilterText[cblUnits]:=UnitFilterEdit.Text;
  //DebugLn(['TCodeBrowserView.WorkGetOptions UnitFIlter=',Options.LevelFilterText[cblUnits],' Edit=',UnitFilterEdit.Text]);
  if UnitFilterBeginsSpeedButton.Down then
    Options.LevelFilterType[cblUnits]:=cbtfBegins;
  if UnitFilterContainsSpeedButton.Down then
    Options.LevelFilterType[cblUnits]:=cbtfContains;

  Options.LevelFilterText[cblIdentifiers]:=IdentifierFilterEdit.Text;
  if IdentifierFilterBeginsSpeedButton.Down then
    Options.LevelFilterType[cblIdentifiers]:=cbtfBegins;
  if IdentifierFilterContainsSpeedButton.Down then
    Options.LevelFilterType[cblIdentifiers]:=cbtfContains;

  DebugLn(['TCodeBrowserView.WorkGetViewOptions UpdateNeeded=',UpdateNeeded,' ChangeStamp=',Options.ChangeStamp<>FOptionsChangeStamp]);

  // this stage finished -> next stage
  if UpdateNeeded or (Options.ChangeStamp<>FOptionsChangeStamp) then
    fStage:=cbwsUpdateTreeView
  else
    fStage:=cbwsFinished;
  ProgressBar1.Position:=ProgressGetViewOptionsStart+ProgressGetViewOptionsSize;
end;

procedure TCodeBrowserView.WorkUpdateTreeView;
begin
  ProgressBar1.Position:=ProgressUpdateTreeViewStart;
  UpdateTreeView;
  // this stage finished -> next stage
  fStage:=cbwsFinished;
  ProgressBar1.Position:=ProgressUpdateTreeViewStart+ProgressUpdateTreeViewSize;
end;

procedure TCodeBrowserView.FreeUnitList(List: TCodeBrowserUnitList);
var
  Node: TAVLTreeNode;
  AnUnit: TCodeBrowserUnit;
begin
  //DebugLn(['TCodeBrowserView.FreeUnitList ',List.Owner]);
  dec(FScannedPackages);
  if List.Units<>nil then begin
    Node:=List.Units.FindLowest;
    while Node<>nil do begin
      AnUnit:=TCodeBrowserUnit(Node.Data);
      RemoveUnit(AnUnit);
      Node:=List.Units.FindSuccessor(Node);
    end;
  end;
  List.Free;
end;

procedure TCodeBrowserView.UpdateStatusBar(Lazy: boolean);
const
  SmallTimeStep = 1/86400;

  function BigIntToStr(i: integer): string;
  var
    p: Integer;
  begin
    if i=0 then begin
      Result:='0';
      exit;
    end;
    Result:='';
    if i>=100000 then begin
      i:=i div 1000;
      Result:='k';
      if i>=100000 then begin
        i:=i div 1000;
        Result:='m';
        if i>=100000 then begin
          i:=i div 1000;
          Result:='g';
          if i>=100000 then begin
            i:=i div 1000;
            Result:='t';
          end;
        end;
      end;
    end;

    p:=0;
    while i>0 do begin
      if p=3 then begin
        Result:=DefaultFormatSettings.ThousandSeparator+Result;
        p:=0;
      end;
      Result:=chr((i mod 10)+ord('0'))+Result;
      i:=i div 10;
      inc(p);
    end;
  end;
var
  s: String;
begin
  if Lazy and (Abs(Now-fLastStatusBarUpdate)<SmallTimeStep) then begin
    // the last update is not long ago
    // => skip update
    exit;
  end;
  fLastStatusBarUpdate:=Now;
  s:='packages='+BigIntToStr(VisiblePackages)+'/'+BigIntToStr(ScannedPackages)
    +' units='+BigIntToStr(VisibleUnits)+'/'+BigIntToStr(ScannedUnits)
    +' identifiers='+BigIntToStr(VisibleIdentifiers)+'/'+BigIntToStr(ScannedIdentifiers)
    +' lines='+BigIntToStr(ScannedLines)
    +' bytes='+BigIntToStr(ScannedBytes);
  if fStage<>cbwsFinished then
    s:=s+'. Scanning ...';
  StatusBar1.SimpleText:=s;
end;

procedure TCodeBrowserView.UpdateTreeView;
var
  ShowPackages: boolean;
  ShowUnits: boolean;
  ShowIdentifiers: boolean;
  ShowPrivate: boolean;
  ShowProtected: boolean;
  ShowEmptyNodes: boolean;
  NewPackageCount: integer;
  NewUnitCount: integer;
  NewIdentifierCount: PtrInt;
  
  LevelFilterText: array[TCodeBrowserLevel] of string;
  LevelFilterType: array[TCodeBrowserLevel] of TCodeBrowserTextFilter;

  function GetCodeTool(AnUnit: TCodeBrowserUnit): TStandardCodeTool;
  begin
    //DebugLn(['GetCodeTool ',AnUnit.CodeTool<>nil,' ',AnUnit.CodeBuffer<>nil]);
    Result:=AnUnit.CodeTool;
    if Result<>nil then exit;
    if AnUnit.CodeBuffer=nil then exit;
    Result:=CodeToolBoss.GetCodeToolForSource(AnUnit.CodeBuffer,true,false)
                as TCodeTool;
    //DebugLn(['GetCodeTool END ',Result<>nil]);
  end;
  
  function IdentifierFitsFilter(LvlType: TCodeBrowserLevel;
    const Identifier: string): boolean;
  begin
    //DebugLn(['IdentifierFitsFilter Identifier=',Identifier,' Filter=',LevelFilterText[LvlType]]);
    if (LevelFilterText[LvlType]='') then exit(true);
    if Identifier='' then exit(false);

    case LevelFilterType[LvlType] of
    cbtfBegins:
      Result:=ComparePrefixIdent(PChar(Pointer(LevelFilterText[LvlType])),
                                 PChar(Pointer(Identifier)));
    cbtfContains:
      Result:=IdentifierPos(PChar(Pointer(LevelFilterText[LvlType])),
                            PChar(Pointer(Identifier)))>=0;
    else
      Result:=true;
    end;
  end;

  procedure AddUnitNodes(SrcUnit: TCodeBrowserUnit; var DestUnit: TObject);
  var
    Tool: TStandardCodeTool;
    
    procedure AddUnit;
    begin
      if DestUnit=nil then
        DestUnit:=TCodeBrowserUnit.Create('');
    end;
    
    function Shorten(const s: string): string;
    begin
      Result:=DbgStr(s);
      if length(Result)>100 then Result:=copy(Result,1,100)+' ...';
    end;

    procedure GetNodeDescription(CTNode: TCodeTreeNode;
      out Description, Identifier: string);
    const
      ProcDescFlags = [phpWithStart,phpWithParameterNames,
                       phpWithVarModifiers,phpWithResultType,phpWithoutSemicolon];
      ProcIdentifierFlags = [phpWithoutClassKeyword,phpWithParameterNames,
                       phpWithoutSemicolon];
      PropDescFlags = [phpWithoutClassKeyword,phpWithParameterNames,
                       phpWithVarModifiers,phpWithResultType];
      NodeFlags = [];
    var
      Inheritance: String;
    begin
      case CTNode.Desc of
      ctnProcedure:
        begin
          Identifier:=Tool.ExtractProcHead(CTNode,ProcIdentifierFlags);
          Description:=Tool.ExtractProcHead(CTNode,ProcDescFlags);
        end;
      ctnVarDefinition:
        begin
          Identifier:=Tool.ExtractDefinitionName(CTNode);
          Description:='var '+Identifier
                     +' : '+Shorten(Tool.ExtractDefinitionNodeType(CTNode));
        end;
      ctnConstDefinition:
        begin
          Identifier:=Tool.ExtractDefinitionName(CTNode);
          Description:='const '+Shorten(Tool.ExtractNode(CTNode,NodeFlags));
        end;
      ctnTypeDefinition:
        begin
          Identifier:=Tool.ExtractDefinitionName(CTNode);
          Description:='type '+Identifier;
          if CTNode.FirstChild<>nil then begin
            case CTNode.FirstChild.Desc of
            ctnClass,ctnClassInterface:
              begin
                Description:=Description+' = class';
                Inheritance:=Tool.ExtractClassInheritance(CTNode.FirstChild,[]);
                if Inheritance<>'' then
                  Description:=Description+'('+Inheritance+')';
              end;
            ctnRecordType:
              Description:=Description+' = record';
            end;
          end;
        end;
      ctnProperty:
        begin
          Identifier:=Tool.ExtractPropName(CTNode,false);
          Description:='property '+Shorten(Tool.ExtractProperty(CTNode,PropDescFlags));
        end;
      ctnEnumIdentifier:
        begin
          Identifier:=Tool.ExtractIdentifier(CTNode.StartPos);
          Description:='enum '+Identifier;
        end;
      end;
    end;
    
    procedure AddIdentifierNode(CTNode: TCodeTreeNode);
    var
      NewNode: TCodeBrowserNode;
      ChildCTNode: TCodeTreeNode;

      procedure AddChildNode;
      var
        NewChildNode: TCodeBrowserNode;
        ChildDescription, ChildIdentifier: string;
        NewCodePos: TCodePosition;
      begin
        //DebugLn(['AddChildNode ',ChildCTNode.DescAsString,' ',ChildDescription]);
        if (ChildCTNode.Parent.Desc=ctnClassPrivate) and (not ShowPrivate) then
          exit;
        if (ChildCTNode.Parent.Desc=ctnClassProtected) and (not ShowProtected)
        then
          exit;
        GetNodeDescription(ChildCTNode,ChildDescription,ChildIdentifier);
        
        if IdentifierFitsFilter(cblIdentifiers,ChildIdentifier) then begin
          NewChildNode:=NewNode.AddNode(ChildDescription,ChildIdentifier);
          if NewChildNode<>nil then begin
            NewChildNode.Desc:=ChildCTNode.Desc;
            Tool.CleanPosToCodePos(ChildCTNode.StartPos,NewCodePos);
            NewChildNode.CodePos:=NewCodePos;
          end;
        end;
      end;
      
    var
      Description, Identifier: string;
      CurUnit: TCodeBrowserUnit;
      NewCodePos: TCodePosition;
    begin
      if not ShowIdentifiers then exit;
      AddUnit;
      CurUnit:=TCodeBrowserUnit(DestUnit);
      //DebugLn(['AddIdentifierNode ',CTNode.DescAsString,' Description="',Description,'"']);
      GetNodeDescription(CTNode,Description,Identifier);
      NewNode:=CurUnit.AddNode(Description,Identifier);
      NewNode.Desc:=CTNode.Desc;
      Tool.CleanPosToCodePos(CTNode.StartPos,NewCodePos);
      NewNode.CodePos:=NewCodePos;
      //DebugLn(['AddIdentifierNode Code=',NewNode.FCodePos.Code<>nil,' P=',NewNode.FCodePos.P]);
      
      if (CTNode.Desc=ctnTypeDefinition)
      and (CTNode.FirstChild<>nil)
      and (CTNode.FirstChild.Desc in [ctnClass,ctnClassInterface,ctnRecordType,
         ctnEnumerationType])
      then begin
        // add child nodes
        ChildCTNode:=CTNode.FirstChild;
        while (ChildCTNode<>nil) and (ChildCTNode.StartPos<CTNode.EndPos) do
        begin
          if ChildCTNode.Desc in
          [ctnProcedure,ctnVarDefinition,ctnProperty,ctnEnumIdentifier]
          then begin
            AddChildNode;
          end;
          if ChildCTNode.Desc=ctnProcedureHead then
            ChildCTNode:=ChildCTNode.NextSkipChilds
          else
            ChildCTNode:=ChildCTNode.Next;
        end;
      end;
      
      if (NewNode.ChildNodes=nil)
      and (not IdentifierFitsFilter(cblIdentifiers,Identifier)) then begin
        // identifier is not needed -> remove
        CurUnit.DeleteNode(NewNode);
      end;
    end;
    
  var
    CTNode: TCodeTreeNode;
  begin
    if SrcUnit=nil then exit;
    //DebugLn(['AddUnitNodes SrcUnit.Filename="',SrcUnit.Filename,'"']);
    Tool:=GetCodeTool(SrcUnit);
    if Tool=nil then exit;
    if Tool.Tree=nil then exit;
    
    CTNode:=Tool.Tree.Root;
    while CTNode<>nil do begin
      //DebugLn(['AddUnitNodes ',CTNode.DescAsString]);
      case CTNode.Desc of
      ctnProcedure:
        if not Tool.NodeIsMethodBody(CTNode) then
          AddIdentifierNode(CTNode);
      ctnVarDefinition,ctnConstDefinition,ctnTypeDefinition:
        if not Tool.NodeIsForwardDeclaration(CTNode) then
          AddIdentifierNode(CTNode);
      end;

      // go to next node
      case CTNode.Desc of
      ctnProgram,ctnLibrary,ctnPackage,ctnUnit,ctnInterface,
      ctnTypeSection,ctnConstSection,ctnVarSection,ctnResStrSection:
        // go into child nodes
        CTNode:=CTNode.Next;
      ctnImplementation, ctnBeginBlock, ctnAsmBlock: break;
      else
        // skip childs and go to next sibling or parent
        CTNode:=CTNode.NextSkipChilds;
      end;
    end;
  end;
  
  procedure AddUnits(SrcList: TCodeBrowserUnitList;
    var DestParentList: TCodeBrowserUnitList);
    
    procedure RaiseParentNotUnitList;
    begin
      raise Exception.Create('TCodeBrowserView.UpdateTreeView.AddUnits.RaiseParentNotUnitList');
    end;
    
  var
    Node: TAVLTreeNode;
    CurUnit: TCodeBrowserUnit;
    NewUnit: TCodeBrowserUnit;
    List: TCodeBrowserUnitList;
    OldDestParentList: TObject;
  begin
    if SrcList=nil then exit;
    //DebugLn(['AddUnits SrcList.Owner="',SrcList.Owner,'" HasUnits=',SrcList.Units<>nil]);
    if SrcList.Units=nil then exit;
    OldDestParentList:=DestParentList;
    Node:=SrcList.Units.FindLowest;
    NewUnit:=nil;
    while Node<>nil do begin
      CurUnit:=TCodeBrowserUnit(Node.Data);
      if (CurUnit.Filename='')
      or IdentifierFitsFilter(cblUnits,ExtractFileNameOnly(CurUnit.Filename))
      then begin
        if DestParentList=nil then begin
          DestParentList:=TCodeBrowserUnitList.Create(CodeBrowserHidden,nil);
        end else if not (DestParentList is TCodeBrowserUnitList) then
          RaiseParentNotUnitList;
        List:=TCodeBrowserUnitList(DestParentList);
        if ShowUnits then begin
          // create a unit node
          NewUnit:=List.AddUnit(CurUnit.Filename);
          NewUnit.CodeBuffer:=CurUnit.CodeBuffer;
          NewUnit.CodeTool:=CurUnit.CodeTool;
        end else if NewUnit=nil then begin
          // create a dummy unit node to add all identifiers
          NewUnit:=List.FindUnit('');
          if NewUnit=nil then
            NewUnit:=List.AddUnit('');
        end;
        //DebugLn(['AddUnits AddUnitNodes ',CurUnit.Filename]);
        AddUnitNodes(CurUnit,TObject(NewUnit));
        if (not ShowEmptyNodes) and (NewUnit.ChildNodeCount=0) then begin
          // remove empty unit
          List.DeleteUnit(NewUnit);
          if OldDestParentList=nil then begin
            DestParentList.Free;
            DestParentList:=nil;
          end;
        end;
      end;
      Node:=SrcList.Units.FindSuccessor(Node);
    end;
  end;

  procedure AddUnitLists(SrcList: TCodeBrowserUnitList;
    var DestParentList: TCodeBrowserUnitList);
  var
    Node: TAVLTreeNode;
    SubList: TCodeBrowserUnitList;
    NewList: TCodeBrowserUnitList;
    OldDestParentList: TCodeBrowserUnitList;
    NewListCreated: Boolean;
    CreateNode: Boolean;
  begin
    if SrcList=nil then exit;
    //DebugLn(['AddUnitLists SrcList.Owner="',SrcList.Owner,'"']);

    OldDestParentList:=DestParentList;
    
    // check filter
    CreateNode:=IdentifierFitsFilter(cblPackages,SrcList.Owner);
    
    // create node
    NewListCreated:=false;
    if CreateNode then begin
      if ShowPackages then begin
        if DestParentList=nil then begin
          DestParentList:=TCodeBrowserUnitList.Create(CodeBrowserHidden,nil);
        end;
        NewList:=TCodeBrowserUnitList.Create(SrcList.Owner,DestParentList);
        NewListCreated:=true;
      end else begin
        NewList:=DestParentList;
      end;
    end;
    // create nodes for unitlists
    if SrcList.UnitLists<>nil then begin
      Node:=SrcList.UnitLists.FindLowest;
      while Node<>nil do begin
        SubList:=TCodeBrowserUnitList(Node.Data);
        AddUnitLists(SubList,DestParentList);// DestParentList because: as sibling not child!
        Node:=SrcList.UnitLists.FindSuccessor(Node);
      end;
    end;
    if CreateNode then begin
      // create nodes for units
      AddUnits(SrcList,NewList);
      // remove empty unit lists
      if (not ShowEmptyNodes) and NewListCreated and (NewList.IsEmpty) then begin
        //DebugLn(['AddUnitLists EMPTY ',NewList.Owner,' ',NewList.UnitListCount,' ',NewList.UnitCount]);
        if DestParentList=NewList then
          DestParentList:=nil;
        NewList.Free;
        NewList:=nil;
        if (OldDestParentList=nil) and (DestParentList<>nil)
        and DestParentList.IsEmpty then begin
          DestParentList.Free;
          DestParentList:=nil;
        end;
      end;
      // update DestParentList
      if (DestParentList=nil) then
        DestParentList:=NewList;
    end;
  end;

  procedure AddTreeNodes(CodeNode: TObject; ParentViewNode: TTreeNode);
  // create visual nodes (TTreeNode)
  {off $DEFINE DisableTreeViewNodes}
  var
    List: TCodeBrowserUnitList;
    ListName: String;
    Node: TAVLTreeNode;
    TVNode: TTreeNode;
    CurUnit: TCodeBrowserUnit;
    CurUnitName: String;
    CurTool: TStandardCodeTool;
    CurNode: TCodeBrowserNode;
    ExpandParent: Boolean;
  begin
    if CodeNode=nil then exit;
    ExpandParent:=true;
    //DebugLn(['AddTreeNodes ',DbgSName(CodeNode)]);
    TVNode:=ParentViewNode;
    if CodeNode is TCodeBrowserUnitList then begin
      // unit list
      List:=TCodeBrowserUnitList(CodeNode);
      //DebugLn(['AddTreeNodes ',List.Owner]);
      if List.Owner=CodeBrowserHidden then begin
        TVNode:=ParentViewNode;
      end else begin
        ListName:=ListOwnerToText(List.Owner);
        inc(NewPackageCount);
        {$IFNDEF DisableTreeViewNodes}
        TVNode:=BrowseTreeView.Items.AddChildObject(
                                              ParentViewNode,ListName,CodeNode);
        TVNode.ImageIndex:=GetNodeImage(CodeNode);
        TVNode.SelectedIndex:=TVNode.ImageIndex;
        {$ENDIF}
      end;
      if List.UnitLists<>nil then begin
        Node:=List.UnitLists.FindLowest;
        while Node<>nil do begin
          AddTreeNodes(TObject(Node.Data),TVNode);
          Node:=List.UnitLists.FindSuccessor(Node);
        end;
      end;
      if List.Units<>nil then begin
        Node:=List.Units.FindLowest;
        while Node<>nil do begin
          AddTreeNodes(TObject(Node.Data),TVNode);
          Node:=List.Units.FindSuccessor(Node);
        end;
      end;
    end
    else if CodeNode is TCodeBrowserUnit then begin
      // unit
      CurUnit:=TCodeBrowserUnit(CodeNode);
      CurTool:=nil;
      if CurUnit.Filename<>'' then
        CurTool:=GetCodeTool(CurUnit);
      if CurTool<>nil then begin
        // add a treenode for this unit
        CurUnitName:=TCodeTool(CurTool).GetCachedSourceName;
        if CurUnitName='' then
          CurUnitName:=ExtractFileNameOnly(CurTool.MainFilename);
        inc(NewUnitCount);
        {$IFNDEF DisableTreeViewNodes}
        TVNode:=BrowseTreeView.Items.AddChildObject(ParentViewNode,
                                                    CurUnitName,CodeNode);
        TVNode.ImageIndex:=GetNodeImage(CodeNode);
        TVNode.SelectedIndex:=TVNode.ImageIndex;
        {$ENDIF}
      end else begin
        // do not add a tree node for this unit
        TVNode:=ParentViewNode;
      end;
      // create tree nodes for code nodes
      if CurUnit.ChildNodes<>nil then begin
        Node:=CurUnit.ChildNodes.FindLowest;
        while Node<>nil do begin
          AddTreeNodes(TObject(Node.Data),TVNode);
          Node:=CurUnit.ChildNodes.FindSuccessor(Node);
        end;
      end;
    end
    else if CodeNode is TCodeBrowserNode then begin
      // code node
      CurNode:=TCodeBrowserNode(CodeNode);
      if CurNode.Description<>'' then begin
        inc(NewIdentifierCount);
        //if (NewIdentifierCount mod 100)=0 then
        //  DebugLn(['AddTreeNodes ',NewIdentifierCount,' ',CurNode.Description]);
        {$IFNDEF DisableTreeViewNodes}
        TVNode:=BrowseTreeView.Items.AddChildObject(ParentViewNode,
                                                  CurNode.Description,CodeNode);
        TVNode.ImageIndex:=GetNodeImage(CodeNode);
        TVNode.SelectedIndex:=TVNode.ImageIndex;
        {$ENDIF}

        // create tree nodes for child code nodes
        if CurNode.ChildNodes<>nil then begin
          Node:=CurNode.ChildNodes.FindLowest;
          while Node<>nil do begin
            AddTreeNodes(TObject(Node.Data),TVNode);
            Node:=CurNode.ChildNodes.FindSuccessor(Node);
          end;
        end;

        // do not expand unit nodes
        if (TObject(ParentViewNode.Data) is TCodeBrowserUnit) then
          ExpandParent:=false;
      end;
    end;
    if ParentViewNode<>nil then
      ParentViewNode.Expanded:=ExpandParent;
  end;

var
  lvl: TCodeBrowserLevel;
begin
  ShowPackages:=Options.HasLevel(cblPackages);
  ShowUnits:=Options.HasLevel(cblUnits);
  ShowIdentifiers:=Options.HasLevel(cblIdentifiers);
  ShowPrivate:=Options.ShowPrivate;
  ShowProtected:=Options.ShowProtected;
  ShowEmptyNodes:=Options.ShowEmptyNodes;
  NewPackageCount:=0;
  NewUnitCount:=0;
  NewIdentifierCount:=0;

  for lvl:=Low(TCodeBrowserLevel) to High(TCodeBrowserLevel) do begin
    LevelFilterText[lvl]:=Options.LevelFilterText[lvl];
    LevelFilterType[lvl]:=Options.LevelFilterType[lvl];
  end;
  DebugLn(['TCodeBrowserView.UpdateTreeView UnitFilter=',LevelFilterText[cblUnits]]);
  
  //DebugLn(['TCodeBrowserView.UpdateTreeView ShowPackages=',ShowPackages,' ShowUnits=',ShowUnits,' ShowIdentifiers=',ShowIdentifiers]);

  BrowseTreeView.Cursor:=crHourGlass;
  BrowseTreeView.BeginUpdate;
  CodeToolBoss.ActivateWriteLock;
  try
    InitTreeView;

    // create internal nodes
    AddUnitLists(ParserRoot,fViewRoot);

    // create treeview nodes
    AddTreeNodes(ViewRoot,nil);
  finally
    CodeToolBoss.DeactivateWriteLock;
    //DebugLn(['TCodeBrowserView.UpdateTreeView EndUpdate']);
    BrowseTreeView.EndUpdate;
    //DebugLn(['TCodeBrowserView.UpdateTreeView AFER ENDUPDATE']);
    BrowseTreeView.Cursor:=crDefault;
  end;
  VisiblePackages:=NewPackageCount;
  VisibleUnits:=NewUnitCount;
  VisibleIdentifiers:=NewIdentifierCount;
  UpdateStatusBar(false);
end;

procedure TCodeBrowserView.RemoveUnit(AnUnit: TCodeBrowserUnit);
begin
  if AnUnit.Scanned then begin
    dec(FScannedUnits);
    dec(FScannedLines,AnUnit.ScannedLines);
    dec(FScannedBytes,AnUnit.ScannedBytes);
    dec(FScannedIdentifiers,AnUnit.ScannedIdentifiers);
    AnUnit.Scanned:=false;
    if fOutdatedFiles<>nil then
      fOutdatedFiles.Remove(AnUnit);
  end;
end;

function TCodeBrowserView.CountIdentifiers(Tool: TCodeTool): integer;
var
  Node: TCodeTreeNode;
begin
  Result:=0;
  if (Tool=nil) or (Tool.Tree=nil) then exit;
  Node:=Tool.Tree.Root;
  while Node<>nil do begin
    if Node.Desc=ctnImplementation then break;
    if (Node.Desc in (AllIdentifierDefinitions+[ctnProcedure,ctnProperty]))
    and (not Tool.NodeIsForwardDeclaration(Node)) then
      inc(Result);
    if not (Node.Desc in [ctnProcedure,ctnBeginBlock,ctnAsmBlock]) then
      Node:=Node.Next
    else
      Node:=Node.NextSkipChilds;
  end;
end;

procedure TCodeBrowserView.ClearTreeView;
begin
  BrowseTreeView.Items.Clear;
  FreeAndNil(FViewRoot);
end;

procedure TCodeBrowserView.InitTreeView;
begin
  ClearTreeView;
end;

function TCodeBrowserView.ListOwnerToText(const ListOwner: string): string;
begin
  if ListOwner=CodeBrowserIDEName then
    Result:=IDEDescription
  else if ListOwner=CodeBrowserProjectName then
    Result:=ProjectDescription
  else
    Result:=ListOwner;
end;

function TCodeBrowserView.GetNodeImage(CodeNode: TObject): integer;
var
  List: TCodeBrowserUnitList;
  Node: TCodeBrowserNode;
begin
  Result:=ImgIDDefault;
  
  if CodeNode is TCodeBrowserUnit then begin
    Result:=ImgIDUnitCode;
  end else if CodeNode is TCodeBrowserUnitList then begin
    List:=TCodeBrowserUnitList(CodeNode);
    if List.Owner=IDEDescription then
      Result:=ImgIDProject
    else if List.Owner=ProjectDescription then
      Result:=ImgIDProject
    else
      Result:=ImgIDPackage;
  end else if CodeNode is TCodeBrowserNode then begin
    Node:=TCodeBrowserNode(CodeNode);
    case Node.Desc of
    ctnProgram,ctnLibrary,ctnPackage:
      Result:=ImgIDProgramCode;
    ctnUnit:
      Result:=ImgIDUnitCode;
    ctnInterface:
      Result:=ImgIDInterfaceSection;
    ctnImplementation:
      Result:=ImgIDImplementation;
    ctnInitialization:
      Result:=ImgIDInitialization;
    ctnFinalization:
      Result:=ImgIDFinalization;
    ctnTypeSection:
      Result:=ImgIDTypeSection;
    ctnTypeDefinition:
      Result:=ImgIDType;
    ctnVarSection:
      Result:=ImgIDVarSection;
    ctnVarDefinition:
      Result:=ImgIDVariable;
    ctnConstSection,ctnResStrSection:
      Result:=ImgIDConstSection;
    ctnConstDefinition:
      Result:=ImgIDConst;
    ctnClass:
      Result:=ImgIDClass;
    ctnProcedure:
      Result:=ImgIDProc;
    ctnProperty:
      Result:=ImgIDProperty;
    end;
  end;
end;

function TCodeBrowserView.GetTVNodeHint(TVNode: TTreeNode): string;
var
  NodeData: TObject;
  CurUnit: TCodeBrowserUnit;
  Node: TCodeBrowserNode;
  Line, Column: integer;
begin
  Result:='';
  if (TVNode=nil) or (TVNode.Data=nil) then exit;
  NodeData:=TObject(TVNode.Data);
  //DebugLn(['TCodeBrowserView.GetTVNodeHint ',DbgSName(NodeData)]);
  if NodeData is TCodeBrowserUnitList then begin

  end else if NodeData is TCodeBrowserUnit then begin
    CurUnit:=TCodeBrowserUnit(NodeData);
    if CurUnit.Filename<>'' then
      Result:=TVNode.Text+#13+CurUnit.Filename;
  end else if NodeData is TCodeBrowserNode then begin
    Node:=TCodeBrowserNode(NodeData);
    if Node.CodePos.Code<>nil then begin
      Result:=TVNode.Text+#13+Node.CodePos.Code.Filename;
      Node.CodePos.Code.AbsoluteToLineCol(Node.CodePos.P,Line,Column);
      if Line>0 then
        Result:=Result+' ('+IntToStr(Line)+','+IntToStr(Column)+')';
    end;
  end;
end;

procedure TCodeBrowserView.ExpandCollapseAllNodesInTreeView(
  NodeType: TExpandableNodeType; Expand: boolean);
var
  Node: TTreeNode;
begin
  BrowseTreeView.BeginUpdate;
  Node:=BrowseTreeView.Items.GetFirstNode;
  while Node<>nil do begin
    if (Node.Data<>nil) then begin
      case NodeType of
      entPackage:
        if  TObject(Node.Data) is TCodeBrowserUnitList then
          Node.Expanded:=Expand;
      entUnit:
        if  TObject(Node.Data) is TCodeBrowserUnit then
          Node.Expanded:=Expand;
      entClass:
        if  (TObject(Node.Data) is TCodeBrowserNode) then
          Node.Expanded:=Expand;
      end;
    end;
    Node:=Node.GetNext;
  end;
  BrowseTreeView.EndUpdate;
end;

procedure TCodeBrowserView.CopyNode(TVNode: TTreeNode; NodeType: TCopyNodeType
  );
var
  Node: TCodeBrowserNode;
  s: string;
begin
  if (TVNode=nil) or (TVNode.Data=nil) then exit;
  s:='';
  if  TObject(TVNode.Data) is TCodeBrowserUnitList then begin
    s:=TVNode.Text;
  end;
  if  TObject(TVNode.Data) is TCodeBrowserUnit then begin
    s:=TVNode.Text;
  end;
  if  (TObject(TVNode.Data) is TCodeBrowserNode) then begin
    Node:=TCodeBrowserNode(TVNode.Data);
    if NodeType=cntIdentifier then
      s:=Node.Identifier
    else
      s:=Node.Description;
  end;
  Clipboard.AsText:=s;
end;

procedure TCodeBrowserView.InvalidateStage(AStage: TCodeBrowserWorkStage);
begin
  if ord(fStage)>ord(AStage) then
    fStage:=AStage;
end;

procedure TCodeBrowserView.BeginUpdate;
begin
  inc(fUpdateCount);
  BrowseTreeView.BeginUpdate;
end;

procedure TCodeBrowserView.EndUpdate;
begin
  dec(fUpdateCount);
  BrowseTreeView.EndUpdate;
end;

function TCodeBrowserView.ExportTree: TModalResult;
var
  SaveDialog: TSaveDialog;
begin
  SaveDialog:=TSaveDialog.Create(nil);
  try
    InitIDEFileDialog(SaveDialog);
    SaveDialog.Title:='Save tree as text (*.txt) ...';
    SaveDialog.FileName:='identifiers.txt';
    SaveDialog.DefaultExt:='txt';
    if not SaveDialog.Execute then exit(mrCancel);
    Result:=ExportTreeAsText(SaveDialog.FileName);
  finally
    StoreIDEFileDialog(SaveDialog);
    SaveDialog.Free;
  end;
end;

function TCodeBrowserView.ExportTreeAsText(Filename: string): TModalResult;

  procedure WriteNode(List: TStrings; const Prefix: string; Node: TTreeNode);
  var
    Child: TTreeNode;
    NewPrefix: String;
    s: String;
  begin
    if Node=nil then exit;
    NewPrefix:=Prefix;
    if Node.Data<>nil then begin
      s:=Node.Text;
      if TObject(Node.Data) is TCodeBrowserUnitList then begin
        List.Add(Prefix+s);
        NewPrefix:=Prefix+'  ';
      end else if TObject(Node.Data) is TCodeBrowserUnit then begin
        List.Add(Prefix+s);
        NewPrefix:=Prefix+'  ';
      end else if TObject(Node.Data) is TCodeBrowserNode then begin
        List.Add(Prefix+s);
        NewPrefix:=Prefix+'  ';
      end;
    end;
    Child:=Node.GetFirstChild;
    while Child<>nil do begin
      WriteNode(List,NewPrefix,Child);
      Child:=Child.GetNextSibling;
    end;
  end;

var
  List: TStringList;
  Node: TTreeNode;
begin
  Filename:=CleanAndExpandFilename(Filename);
  Result:=CheckCreatingFile(Filename,true,true,true);
  if Result<>mrOk then exit;
  
  List:=TStringList.Create;
  try
    Node:=BrowseTreeView.Items.GetFirstNode;
    WriteNode(List,'',Node);
    Result:=SaveStringToFile(Filename,List.Text,[],
      'exporting identifiers as text');
  finally
    List.Free;
  end;
end;

procedure TCodeBrowserView.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin

end;

procedure TCodeBrowserView.BrowseTreeViewShowHint(Sender: TObject;
  HintInfo: PHintInfo);
var
  TVNode: TTreeNode;
  HintStr: String;
  MousePos: TPoint;
begin
  //DebugLn(['TCodeBrowserView.BrowseTreeViewShowHint ',dbgs(HintInfo^.CursorPos)]);
  HintStr:='';
  MousePos:=HintInfo^.CursorPos;
  TVNode:=BrowseTreeView.GetNodeAt(MousePos.X,MousePos.Y);
  if TVNode<>nil then begin
    HintStr:=GetTVNodeHint(TVNode);
    //DebugLn(['TCodeBrowserView.BrowseTreeViewShowHint HintStr="',HintStr,'"']);
  end;
  HintInfo^.HintStr:=HintStr;
end;

procedure TCodeBrowserView.CollapseAllPackagesMenuItemClick(Sender: TObject);
begin
  ExpandCollapseAllNodesInTreeView(entPackage,false);
end;

procedure TCodeBrowserView.CollapseAllUnitsMenuItemClick(Sender: TObject);
begin
  ExpandCollapseAllNodesInTreeView(entUnit,false);
end;

procedure TCodeBrowserView.CollapseAllClassesMenuItemClick(Sender: TObject);
begin
  ExpandCollapseAllNodesInTreeView(entClass,false);
end;

procedure TCodeBrowserView.CopyDescriptionMenuItemClick(Sender: TObject);
begin
  CopyNode(BrowseTreeView.Selected,cntDescription);
end;

procedure TCodeBrowserView.CopyIdentifierMenuItemClick(Sender: TObject);
begin
  CopyNode(BrowseTreeView.Selected,cntIdentifier);
end;

procedure TCodeBrowserView.ExpandAllClassesMenuItemClick(Sender: TObject);
begin
  ExpandCollapseAllNodesInTreeView(entClass,true);
end;

procedure TCodeBrowserView.ExpandAllPackagesMenuItemClick(Sender: TObject);
begin
  ExpandCollapseAllNodesInTreeView(entPackage,true);
end;

procedure TCodeBrowserView.ExpandAllUnitsMenuItemClick(Sender: TObject);
begin
  ExpandCollapseAllNodesInTreeView(entUnit,true);
end;

procedure TCodeBrowserView.ExportMenuItemClick(Sender: TObject);
begin
  ExportTree;
end;

procedure TCodeBrowserView.BrowseTreeViewMouseDown(Sender: TOBject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  NodeData: TObject;
  Node: TCodeBrowserNode;
  CurUnit: TCodeBrowserUnit;
  Line, Column: integer;
  TVNode: TTreeNode;
  List: TCodeBrowserUnitList;
  APackage: TLazPackage;
begin
  if ssDouble in Shift then begin
    TVNode:=BrowseTreeView.GetNodeAt(X,Y);
    if (TVNode=nil) or (TVNode.Data=nil) then exit;
    NodeData:=TObject(TVNode.Data);
    if NodeData is TCodeBrowserUnitList then begin
      List:=TCodeBrowserUnitList(NodeData);
      DebugLn(['TCodeBrowserView.BrowseTreeViewMouseDown "',List.Owner,'=',CodeBrowserProjectName,'"']);
      if List.Owner=CodeBrowserProjectName then begin
        // open project inspector
        DebugLn(['TCodeBrowserView.BrowseTreeViewMouseDown open project inspector']);
        ExecuteIDECommand(Self,ecProjectInspector);
      end else if List.Owner=CodeBrowserIDEName then begin
        // open the IDE -> already open
      end else if List.Owner=CodeBrowserHidden then begin
        // nothing
      end else begin
        // open package
        APackage:=PackageGraph.FindAPackageWithName(List.Owner,nil);
        if APackage<>nil then begin
          PackageEditingInterface.DoOpenPackageWithName(List.Owner,[],false);
        end;
      end;
    end else if NodeData is TCodeBrowserUnit then begin
      CurUnit:=TCodeBrowserUnit(NodeData);
      if CurUnit.Filename<>'' then begin
        LazarusIDE.DoOpenEditorFile(CurUnit.Filename,-1,[ofOnlyIfExists]);
      end;
    end else if NodeData is TCodeBrowserNode then begin
      Node:=TCodeBrowserNode(NodeData);
      if (Node.CodePos.Code<>nil)
      and (Node.CodePos.Code.Filename<>'') then begin
        Node.CodePos.Code.AbsoluteToLineCol(Node.CodePos.P,Line,Column);
        LazarusIDE.DoOpenFileAndJumpToPos(Node.CodePos.Code.Filename,
          Point(Column,Line),-1,-1,[ofOnlyIfExists]);
      end;
    end;
  end;
end;

{ TCodeBrowserViewOptions }

procedure TCodeBrowserViewOptions.SetModified(const AValue: boolean);
begin
  if AValue then
    IncreaseChangeStamp;
  if FModified=AValue then exit;
  FModified:=AValue;
end;

function TCodeBrowserViewOptions.GetLevelFilterText(Level: TCodeBrowserLevel
  ): string;
begin
  Result:=FLevelFilterText[Level];
end;

function TCodeBrowserViewOptions.GetLevelFilterType(Level: TCodeBrowserLevel
  ): TCodeBrowserTextFilter;
begin
  Result:=FLevelFilterType[Level];
end;

procedure TCodeBrowserViewOptions.SetLevelFilterText(Level: TCodeBrowserLevel;
  const AValue: string);
begin
  if FLevelFilterText[Level]=AValue then exit;
  FLevelFilterText[Level]:=AValue;
  Modified:=true;
end;

procedure TCodeBrowserViewOptions.SetLevelFilterType(Level: TCodeBrowserLevel;
  const AValue: TCodeBrowserTextFilter);
begin
  if FLevelFilterType[Level]=AValue then exit;
  FLevelFilterType[Level]:=AValue;
  Modified:=true;
end;

procedure TCodeBrowserViewOptions.SetScope(const AValue: string);
begin
  if FScope=AValue then exit;
  FScope:=AValue;
  Modified:=true;
end;

procedure TCodeBrowserViewOptions.SetLevels(const AValue: TStrings);
begin
  if FLevels=AValue then exit;
  if FLevels.Text=AValue.Text then exit;
  FLevels.Assign(AValue);
  Modified:=true;
end;

procedure TCodeBrowserViewOptions.SetShowEmptyNodes(const AValue: boolean);
begin
  if FShowEmptyNodes=AValue then exit;
  FShowEmptyNodes:=AValue;
  Modified:=true;
end;

procedure TCodeBrowserViewOptions.SetShowPrivate(const AValue: boolean);
begin
  if FShowPrivate=AValue then exit;
  FShowPrivate:=AValue;
  Modified:=true;
end;

procedure TCodeBrowserViewOptions.SetShowProtected(const AValue: boolean);
begin
  if FShowProtected=AValue then exit;
  FShowProtected:=AValue;
  Modified:=true;
end;

procedure TCodeBrowserViewOptions.SetWithRequiredPackages(const AValue: boolean
  );
begin
  if FWithRequiredPackages=AValue then exit;
  FWithRequiredPackages:=AValue;
  Modified:=true;
end;

procedure TCodeBrowserViewOptions.IncreaseChangeStamp;
begin
  if FChangeStamp<High(FChangeStamp) then
    inc(FChangeStamp)
  else
    FChangeStamp:=Low(FChangeStamp);
end;

constructor TCodeBrowserViewOptions.Create;
begin
  FLevels:=TStringList.Create;
  Clear;
end;

destructor TCodeBrowserViewOptions.Destroy;
begin
  FreeAndNil(FLevels);
  inherited Destroy;
end;

procedure TCodeBrowserViewOptions.Clear;
var
  l: TCodeBrowserLevel;
begin
  FLevels.Clear;
  FLevels.Text:=CodeBrowserLevelNames[cblPackages]+#13
               +CodeBrowserLevelNames[cblUnits]+#13
               +CodeBrowserLevelNames[cblIdentifiers];
  WithRequiredPackages:=false;
  ShowPrivate:=false;
  ShowProtected:=true;
  Scope:='Project';
  for l:=Low(TCodeBrowserLevel) to High(TCodeBrowserLevel) do begin
    FLevelFilterType[l]:=cbtfContains;
    FLevelFilterText[l]:='';
  end;
  IncreaseChangeStamp;
  Modified:=false;
end;

procedure TCodeBrowserViewOptions.LoadFromConfig(ConfigStore: TConfigStorage;
  const Path: string);
var
  l: TCodeBrowserLevel;
  SubPath: String;
begin
  Clear;
  WithRequiredPackages:=
                  ConfigStore.GetValue(Path+'WithRequiredPackages/Value',false);
  Scope:=ConfigStore.GetValue(Path+'Scope/Value','Project');
  ShowPrivate:=ConfigStore.GetValue(Path+'ShowPrivate/Value',false);
  ShowProtected:=ConfigStore.GetValue(Path+'ShowProtected/Value',true);
  ShowEmptyNodes:=ConfigStore.GetValue(Path+'ShowEmptyNodes/Value',true);
  ConfigStore.GetValue(Path+'Levels/',FLevels);
  for l:=Low(TCodeBrowserLevel) to High(TCodeBrowserLevel) do begin
    SubPath:=Path+'LevelFilter/'+CodeBrowserLevelNames[l];
    FLevelFilterType[l]:=StringToCodeBrowserTextFilter(
      ConfigStore.GetValue(SubPath+'/Type',''));
    FLevelFilterText[l]:=ConfigStore.GetValue(SubPath+'/Text','');
  end;
  Modified:=false;
end;

procedure TCodeBrowserViewOptions.SaveToConfig(ConfigStore: TConfigStorage;
  const Path: string);
var
  l: TCodeBrowserLevel;
  SubPath: String;
begin
  ConfigStore.SetDeleteValue(Path+'WithRequiredPackages/Value',
                             WithRequiredPackages,false);
  ConfigStore.SetDeleteValue(Path+'Scope/Value',Scope,'Project');
  ConfigStore.SetDeleteValue(Path+'ShowPrivate/Value',ShowPrivate,false);
  ConfigStore.SetDeleteValue(Path+'ShowProtected/Value',ShowProtected,true);
  ConfigStore.SetDeleteValue(Path+'ShowEmptyNodes/Value',ShowEmptyNodes,true);
  ConfigStore.SetValue(Path+'Levels/',FLevels);
  for l:=Low(TCodeBrowserLevel) to High(TCodeBrowserLevel) do begin
    SubPath:=Path+'LevelFilter/'+CodeBrowserLevelNames[l];
    ConfigStore.SetDeleteValue(SubPath+'/Type',
      CodeBrowserTextFilterNames[FLevelFilterType[l]],
      CodeBrowserTextFilterNames[cbtfBegins]);
    ConfigStore.SetDeleteValue(SubPath+'/Text',FLevelFilterText[l],'');
  end;
  Modified:=false;
end;

function TCodeBrowserViewOptions.HasLevel(Level: TCodeBrowserLevel): boolean;
begin
  Result:=Levels.IndexOf(CodeBrowserLevelNames[Level])>=0;
end;

initialization
  {$I codebrowser.lrs}

end.

