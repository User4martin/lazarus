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
    IDE Window showing dependencies of units and packages.

  ToDo:
    - show unit selected in TV on units graph
}
unit UnitDependencies;

{$mode objfpc}{$H+}

{$I ide.inc}

interface

uses
  Classes, SysUtils, types, AVL_Tree, LazLogger, LazFileUtils, LazUTF8,
  Forms, Controls, ExtCtrls, ComCtrls, StdCtrls, Buttons, Dialogs, Menus, Clipbrd,
  LvlGraphCtrl,
  LazIDEIntf, ProjectIntf, IDEWindowIntf, PackageIntf, SrcEditorIntf,
  IDEImagesIntf, IDECommands, IDEDialogs, IDEMsgIntf, TextTools,
  CodeToolManager, DefineTemplates, CodeToolsStructs,
  CTUnitGraph, CTUnitGroupGraph, FileProcs, CodeCache,
  LazarusIDEStrConsts, UnusedUnitsDlg;

const
  GroupPrefixProject = '-Project-';
  GroupPrefixFPCSrc = 'FPC:';
  GroupNone = '-None-';
type
  TUDUnit = class(TUGUnit)
  public
  end;

  TUDUses = class(TUGUses)
  public
  end;

  TUDNodeType = (
    udnNone,
    udnGroup,
    udnDirectory,
    udnInterface,
    udnImplementation,
    udnUsedByInterface,
    udnUsedByImplementation,
    udnUnit
    );
  TUDNodeTypes = set of TUDNodeType;

  { TUDBaseNode }

  TUDBaseNode = class
  public
    TVNode: TTreeNode;
    NodeText: string;
    Typ: TUDNodeType;
    Identifier: string; // GroupName, Directory, Filename
    Group: string;
    HasChildren: boolean;
  end;

  { TUDNode }

  TUDNode = class(TUDBaseNode)
  public
    Parent: TUDNode;
    ChildNodes: TAVLTree; // tree of TUDNode sorted for Typ and NodeText
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function GetNode(aTyp: TUDNodeType; const ANodeText: string;
      CreateIfNotExists: boolean = false): TUDNode;
    function FindFirst(aTyp: TUDNodeType): TUDNode;
    function FindUnit(const aUnitName: string): TUDNode;
    function Count: integer;
  end;

  TUDWFlag = (
    udwParsing,
    udwNeedUpdateGroupsLvlGraph, // rebuild GroupsLvlGraph
    udwNeedUpdateUnitsLvlGraph, // rebuild UnitsLvlGraph
    udwNeedUpdateAllUnitsTreeView, // rebuild AllUnitsTreeView
    udwNeedUpdateAllUnitsTVSearch, // update search in AllUnitsTreeView
    udwNeedUpdateSelUnitsTreeView, // rebuild SelUnitsTreeView
    udwNeedUpdateSelUnitsTVSearch // update search in SelUnitsTreeView
    );
  TUDWFlags = set of TUDWFlag;

  { TUnitDependenciesWindow }

  TUnitDependenciesWindow = class(TForm)
    AllUnitsFilterEdit: TEdit;
    AllUnitsSearchEdit: TEdit;
    AllUnitsSearchNextSpeedButton: TSpeedButton;
    AllUnitsSearchPrevSpeedButton: TSpeedButton;
    AllUnitsGroupBox: TGroupBox;
    AllUnitsShowDirsSpeedButton: TSpeedButton;
    AllUnitsShowGroupNodesSpeedButton: TSpeedButton;
    AllUnitsTreeView: TTreeView; // Node.Data is TUDNode
    MainPageControl: TPageControl;
    RefreshButton: TButton;
    StatsLabel: TLabel;
    StatusPanel: TPanel;
    Timer1: TTimer;
    UnitsTVUnusedUnitsMenuItem: TMenuItem;
    UnitsTVCopyFilenameMenuItem: TMenuItem;
    UnitsTVCollapseAllMenuItem: TMenuItem;
    UnitsTVExpandAllMenuItem: TMenuItem;
    ProgressBar1: TProgressBar;
    GroupsTabSheet: TTabSheet;
    GroupsSplitter: TSplitter;
    SearchPkgsCheckBox: TCheckBox;
    SearchSrcEditCheckBox: TCheckBox;
    SelectedUnitsGroupBox: TGroupBox;
    SelUnitsSearchEdit: TEdit;
    SelUnitsSearchNextSpeedButton: TSpeedButton;
    SelUnitsSearchPrevSpeedButton: TSpeedButton;
    SelUnitsTreeView: TTreeView;
    SearchCustomFilesBrowseButton: TButton;
    SearchCustomFilesCheckBox: TCheckBox;
    ScopePanel: TPanel;
    SearchCustomFilesComboBox: TComboBox;
    UnitsSplitter: TSplitter;
    UnitsTabSheet: TTabSheet;
    UnitsTVPopupMenu: TPopupMenu;
    procedure AllUnitsFilterEditChange(Sender: TObject);
    procedure AllUnitsFilterEditEnter(Sender: TObject);
    procedure AllUnitsFilterEditExit(Sender: TObject);
    procedure AllUnitsSearchEditChange(Sender: TObject);
    procedure AllUnitsSearchEditEnter(Sender: TObject);
    procedure AllUnitsSearchEditExit(Sender: TObject);
    procedure AllUnitsSearchNextSpeedButtonClick(Sender: TObject);
    procedure AllUnitsSearchPrevSpeedButtonClick(Sender: TObject);
    procedure AllUnitsShowDirsSpeedButtonClick(Sender: TObject);
    procedure AllUnitsShowGroupNodesSpeedButtonClick(Sender: TObject);
    procedure AllUnitsTreeViewAdvancedCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; {%H-}State: TCustomDrawState; Stage: TCustomDrawStage;
      var {%H-}PaintImages, {%H-}DefaultDraw: Boolean);
    procedure RefreshButtonClick(Sender: TObject);
    procedure SelUnitsTreeViewExpanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
    procedure Timer1Timer(Sender: TObject);
    procedure UnitsLvlGraphMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure UnitsLvlGraphSelectionChanged(Sender: TObject);
    procedure UnitsTreeViewShowHint(Sender: TObject; HintInfo: PHintInfo);
    procedure UnitsTreeViewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure AllUnitsTreeViewSelectionChanged(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure GroupsLvlGraphSelectionChanged(Sender: TObject);
    procedure OnIdle(Sender: TObject; var {%H-}Done: Boolean);
    procedure SearchPkgsCheckBoxChange(Sender: TObject);
    procedure SearchSrcEditCheckBoxChange(Sender: TObject);
    procedure SelUnitsSearchEditChange(Sender: TObject);
    procedure SelUnitsSearchEditEnter(Sender: TObject);
    procedure SelUnitsSearchEditExit(Sender: TObject);
    procedure SelUnitsSearchNextSpeedButtonClick(Sender: TObject);
    procedure SelUnitsSearchPrevSpeedButtonClick(Sender: TObject);
    procedure SearchCustomFilesBrowseButtonClick(Sender: TObject);
    procedure SearchCustomFilesCheckBoxChange(Sender: TObject);
    procedure SearchCustomFilesComboBoxChange(Sender: TObject);
    procedure UnitsTVCollapseAllMenuItemClick(Sender: TObject);
    procedure UnitsTVCopyFilenameMenuItemClick(Sender: TObject);
    procedure UnitsTVExpandAllMenuItemClick(Sender: TObject);
    procedure UnitsTVPopupMenuPopup(Sender: TObject);
    procedure UnitsTVUnusedUnitsMenuItemClick(Sender: TObject);
  private
    FCurrentUnit: TUGUnit;
    FIdleConnected: boolean;
    FPendingUnitDependencyRoute: TStrings;
    FUsesGraph: TUsesGraph;
    FGroups: TUGGroups; // referenced by Nodes.Data of GroupsLvlGraph
    FNewUsesGraph: TUsesGraph; // on idle the units are scanned and this graph
      // is filled up, when parsing is complete it becomes the new UsesGraph
    FNewGroups: TUGGroups;
    FAllUnitsRootUDNode: TUDNode;
    FSelUnitsRootUDNode: TUDNode;
    FFlags: TUDWFlags;
    fImgIndexProject: integer;
    fImgIndexUnit: integer;
    fImgIndexPackage: integer;
    fImgIndexDirectory: integer;
    fImgIndexOverlayImplUses: integer;
    fAllUnitsTVSearchStartNode: TTreeNode;
    fSelUnitsTVSearchStartNode: TTreeNode;
    function CreateAllUnitsTree: TUDNode;
    function CreateSelUnitsTree: TUDNode;
    procedure ExpandPendingUnitDependencyRoute(RootNode: TUDNode);
    procedure ConvertUnitNameRouteToPath(Route: TStrings); // inserts missing links
    procedure AddUsesSubNodes(UDNode: TUDNode);
    procedure CreateTVNodes(TV: TTreeView;
      ParentTVNode: TTreeNode; ParentUDNode: TUDNode; Expand: boolean);
    procedure FreeUsesGraph;
    procedure SelectNextSearchTV(TV: TTreeView; StartTVNode: TTreeNode;
      SearchNext, SkipStart: boolean);
    function FindNextTVNode(StartNode: TTreeNode;
      LowerSearch: string; SearchNext, SkipStart: boolean): TTreeNode;
    function FindUnitTVNodeWithFilename(TV: TTreeView; aFilename: string): TTreeNode;
    function FindUnitTVNodeWithUnitName(TV: TTreeView; aUnitName: string): TTreeNode;
    procedure SetCurrentUnit(AValue: TUGUnit);
    procedure SetIdleConnected(AValue: boolean);
    procedure CreateGroups;
    function CreateProjectGroup(AProject: TLazProject): TUGGroup;
    function CreatePackageGroup(APackage: TIDEPackage): TUGGroup;
    procedure CreateFPCSrcGroups;
    procedure GuessGroupOfUnits;
    procedure MarkCycles;
    procedure SetPendingUnitDependencyRoute(AValue: TStrings);
    procedure StartParsing;
    procedure ScopeChanged;
    procedure AddStartAndTargetUnits;
    procedure AddAdditionalFilesAsStartUnits;
    procedure SetupGroupsTabSheet;
    procedure SetupUnitsTabSheet;
    procedure UpdateUnitsButtons;
    procedure UpdateAll;
    procedure UpdateGroupsLvlGraph;
    procedure UpdateUnitsLvlGraph;
    procedure UpdateAllUnitsTreeView;
    procedure UpdateSelUnitsTreeView;
    procedure UpdateAllUnitsTreeViewSearch;
    procedure UpdateSelUnitsTreeViewSearch;
    function GetImgIndex(Node: TUDNode): integer;
    function NodeTextToUnit(NodeText: string): TUGUnit;
    function UGUnitToNodeText(UGUnit: TUGUnit): string;
    function GetFPCSrcDir: string;
    function IsFPCSrcGroup(Group: TUGGroup): boolean;
    function IsProjectGroup(Group: TUGGroup): boolean;
    function IsProjectGroup(GroupName: string): boolean;
    function GetFilename(UDNode: TUDNode): string;
    function GetAllUnitsFilter(Lower: boolean): string;
    function GetAllUnitsSearch(Lower: boolean): string;
    function GetSelUnitsSearch(Lower: boolean): string;
    function ResStrFilter: string;
    function ResStrSearch: string;
    function NodeTextFitsFilter(const NodeText, LowerFilter: string): boolean;
    procedure CreateUsesGraph(out TheUsesGraph: TUsesGraph; out TheGroups: TUGGroups);
  public
    GroupsLvlGraph: TLvlGraphControl; // Nodes.Data are TUGGroup of Groups
    UnitsLvlGraph: TLvlGraphControl; // Nodes.Data are Units in Groups
  public
    property IdleConnected: boolean read FIdleConnected write SetIdleConnected;
    property UsesGraph: TUsesGraph read FUsesGraph;
    property Groups: TUGGroups read FGroups;
    property CurrentUnit: TUGUnit read FCurrentUnit write SetCurrentUnit;
    property PendingUnitDependencyRoute: TStrings read FPendingUnitDependencyRoute
      write SetPendingUnitDependencyRoute; // list of unit names, missing links are automatically found
  end;

type

  { TQuickFixCircularUnitReference }

  TQuickFixCircularUnitReference = class(TIDEMsgQuickFixItem)
  public
    constructor Create;
    function IsApplicable(Line: TIDEMessageLine): boolean; override;
    procedure Execute(const Msg: TIDEMessageLine; Step: TIMQuickFixStep); override;
  end;

var
  UnitDependenciesWindow: TUnitDependenciesWindow;

procedure ShowUnitDependenciesClicked(Sender: TObject);
procedure ShowUnitDependencies(Show, BringToFront: boolean);
procedure InitUnitDependenciesQuickFixItems;

function CompareUDBaseNodes(UDNode1, UDNode2: Pointer): integer;

implementation

procedure ShowUnitDependenciesClicked(Sender: TObject);
begin
  ShowUnitDependencies(true,true);
end;

procedure ShowUnitDependencies(Show, BringToFront: boolean);
begin
  if UnitDependenciesWindow = Nil then
    Application.CreateForm(TUnitDependenciesWindow, UnitDependenciesWindow);
  if Show then
    IDEWindowCreators.ShowForm(UnitDependenciesWindow,BringToFront);
end;

procedure InitUnitDependenciesQuickFixItems;
begin
  RegisterIDEMsgQuickFix(TQuickFixCircularUnitReference.Create);
end;

function CompareUDBaseNodes(UDNode1, UDNode2: Pointer): integer;
var
  Node1: TUDBaseNode absolute UDNode1;
  Node2: TUDBaseNode absolute UDNode2;
begin
  Result:=ord(Node1.Typ)-ord(Node2.Typ);
  if Result<>0 then exit;
  case Node1.Typ of
  udnDirectory: Result:=CompareFilenames(Node1.NodeText,Node2.NodeText);
  else Result:=SysUtils.CompareText(Node1.NodeText,Node2.NodeText);
  end;
end;

{ TQuickFixCircularUnitReference }

constructor TQuickFixCircularUnitReference.Create;
begin
  Name:='Show unit dependencies';
  Caption:='Show unit dependencies';
  Steps:=[imqfoMenuItem];
end;

function TQuickFixCircularUnitReference.IsApplicable(Line: TIDEMessageLine
  ): boolean;
const
  SearchStr = ') Fatal: Circular unit reference between ';
var
  Msg: String;
  p: integer;
  Code: TCodeBuffer;
  Filename: string;
  Caret: TPoint;
begin
  Result:=false;
  if (Line.Parts=nil) then exit;
  Msg:=Line.Msg;
  p:=System.Pos(SearchStr,Msg);
  if p<1 then exit;
  inc(p,length(SearchStr));
  Line.GetSourcePosition(Filename,Caret.Y,Caret.X);
  if (Filename='') or (Caret.X<1) or (Caret.Y<1) then exit;
  Code:=CodeToolBoss.LoadFile(Filename,true,false);
  if Code=nil then exit;
  Result:=true;
end;

procedure TQuickFixCircularUnitReference.Execute(const Msg: TIDEMessageLine;
  Step: TIMQuickFixStep);
var
  UnitName1: String;
  UnitName2: String;
  Path: TStringList;
begin
  if Step<>imqfoMenuItem then exit;
  if not REMatches(Msg.Msg,'Fatal: Circular unit reference between ([a-z_0-9.]+) and ([a-z_0-9.]+)','I')
  then begin
    debugln(['TQuickFixCircularUnitReference.Execute invalid message ',Msg.Msg]);
    exit;
  end;
  UnitName1:=REVar(1);
  UnitName2:=REVar(2);
  ShowUnitDependencies(true,true);
  Path:=TStringList.Create;
  try
    Path.Add(UnitName1);
    Path.Add(UnitName2);
    Path.Add(UnitName1);
    UnitDependenciesWindow.PendingUnitDependencyRoute:=Path;
  finally
    Path.Free;
  end;
end;

{ TUDNode }

constructor TUDNode.Create;
begin
  ChildNodes:=TAVLTree.Create(@CompareUDBaseNodes);
end;

destructor TUDNode.Destroy;
begin
  Clear;
  FreeAndNil(ChildNodes);
  inherited Destroy;
end;

procedure TUDNode.Clear;
begin
  ChildNodes.FreeAndClear;
end;

function TUDNode.GetNode(aTyp: TUDNodeType; const ANodeText: string;
  CreateIfNotExists: boolean): TUDNode;
var
  Node: TUDBaseNode;
  AVLNode: TAVLTreeNode;
begin
  Node:=TUDBaseNode.Create;
  Node.Typ:=aTyp;
  Node.NodeText:=ANodeText;
  AVLNode:=ChildNodes.Find(Node);
  Node.Free;
  if AVLNode<>nil then begin
    Result:=TUDNode(AVLNode.Data);
  end else if CreateIfNotExists then begin
    Result:=TUDNode.Create;
    Result.Typ:=aTyp;
    Result.NodeText:=ANodeText;
    ChildNodes.Add(Result);
    Result.Parent:=Self;
  end else
    Result:=nil;
end;

function TUDNode.FindFirst(aTyp: TUDNodeType): TUDNode;
var
  AVLNode: TAVLTreeNode;
begin
  AVLNode:=ChildNodes.FindLowest;
  while AVLNode<>nil do begin
    Result:=TUDNode(AVLNode.Data);
    if Result.Typ=aTyp then exit;
    AVLNode:=ChildNodes.FindSuccessor(AVLNode);
  end;
  Result:=nil;
end;

function TUDNode.FindUnit(const aUnitName: string): TUDNode;
var
  AVLNode: TAVLTreeNode;
begin
  AVLNode:=ChildNodes.FindLowest;
  while AVLNode<>nil do begin
    Result:=TUDNode(AVLNode.Data);
    if (Result.Typ=udnUnit)
    and (CompareText(ExtractFileNameOnly(Result.Identifier),aUnitName)=0) then
      exit;
    AVLNode:=ChildNodes.FindSuccessor(AVLNode);
  end;
  Result:=nil;
end;

function TUDNode.Count: integer;
begin
  Result:=ChildNodes.Count;
end;

{ TUnitDependenciesWindow }

procedure TUnitDependenciesWindow.FormCreate(Sender: TObject);
begin
  FPendingUnitDependencyRoute:=TStringList.Create;
  CreateUsesGraph(FUsesGraph,FGroups);

  fImgIndexProject   := IDEImages.LoadImage(16, 'item_project');
  fImgIndexUnit      := IDEImages.LoadImage(16, 'item_unit');
  fImgIndexPackage   := IDEImages.LoadImage(16, 'pkg_required');
  fImgIndexDirectory := IDEImages.LoadImage(16, 'pkg_files');
  fImgIndexOverlayImplUses := IDEImages.LoadImage(16, 'pkg_core_overlay');
  AllUnitsTreeView.Images:=IDEImages.Images_16;
  SelUnitsTreeView.Images:=IDEImages.Images_16;

  Caption:=lisMenuViewUnitDependencies;
  RefreshButton.Caption:=dlgUnitDepRefresh;

  MainPageControl.ActivePage:=UnitsTabSheet;

  SetupUnitsTabSheet;
  SetupGroupsTabSheet;

  StartParsing;
end;

procedure TUnitDependenciesWindow.AllUnitsSearchEditChange(Sender: TObject);
begin
  Include(FFlags,udwNeedUpdateAllUnitsTVSearch);
  IdleConnected:=true;
end;

procedure TUnitDependenciesWindow.AllUnitsSearchEditEnter(Sender: TObject);
begin
  if AllUnitsSearchEdit.Text=ResStrSearch then
    AllUnitsSearchEdit.Text:='';
end;

procedure TUnitDependenciesWindow.AllUnitsSearchEditExit(Sender: TObject);
begin
  if AllUnitsSearchEdit.Text='' then
    AllUnitsSearchEdit.Text:=ResStrSearch;
end;

procedure TUnitDependenciesWindow.AllUnitsSearchNextSpeedButtonClick(
  Sender: TObject);
begin
  SelectNextSearchTV(AllUnitsTreeView,AllUnitsTreeView.Selected,true,true);
  fAllUnitsTVSearchStartNode:=AllUnitsTreeView.Selected;
end;

procedure TUnitDependenciesWindow.AllUnitsSearchPrevSpeedButtonClick(
  Sender: TObject);
begin
  SelectNextSearchTV(AllUnitsTreeView,AllUnitsTreeView.Selected,false,true);
  fAllUnitsTVSearchStartNode:=AllUnitsTreeView.Selected;
end;

procedure TUnitDependenciesWindow.AllUnitsShowDirsSpeedButtonClick(
  Sender: TObject);
begin
  Include(FFlags,udwNeedUpdateAllUnitsTreeView);
  IdleConnected:=true;
end;

procedure TUnitDependenciesWindow.AllUnitsShowGroupNodesSpeedButtonClick(
  Sender: TObject);
begin
  Include(FFlags,udwNeedUpdateAllUnitsTreeView);
  IdleConnected:=true;
end;

procedure TUnitDependenciesWindow.AllUnitsTreeViewAdvancedCustomDrawItem(
  Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState;
  Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
var
  TV: TTreeView;
  NodeRect: Classes.TRect;
  x: Integer;
  UDNode: TUDNode;
  UGUnit: TUGUnit;
  UsesImplCnt: Integer;
  i: Integer;
  y: Integer;
begin
  if Stage<>cdPostPaint then exit;
  TV:=Sender as TTreeView;
  if not (TObject(Node.Data) is TUDNode) then exit;
  UDNode:=TUDNode(Node.Data);
  if UDNode.Typ<>udnUnit then exit;
  UGUnit:=UsesGraph.GetUnit(UDNode.Identifier,false);
  if UGUnit=nil then exit;
  if (UGUnit.UsesUnits=nil) then exit;
  UsesImplCnt:=0;
  for i:=0 to UGUnit.UsesUnits.Count-1 do begin
    if TUGUses(UGUnit.UsesUnits[i]).InImplementation then
      inc(UsesImplCnt);
  end;
  if UsesImplCnt=0 then exit;

  NodeRect:=Node.DisplayRect(False);
  x:=Node.DisplayIconLeft+1;
  y:=(NodeRect.Top+NodeRect.Bottom-TV.Images.Height) div 2;
  TV.Images.Draw(TV.Canvas,x,y,fImgIndexOverlayImplUses);
end;

procedure TUnitDependenciesWindow.RefreshButtonClick(Sender: TObject);
begin
  if udwParsing in FFlags then exit;
  StartParsing;
end;

procedure TUnitDependenciesWindow.SelUnitsTreeViewExpanding(Sender: TObject;
  Node: TTreeNode; var AllowExpansion: Boolean);
var
  UDNode: TUDNode;
begin
  if Node.Count>0 then exit;
  if not (TObject(Node.Data) is TUDNode) then exit;
  UDNode:=TUDNode(Node.Data);
  if UDNode.Typ=udnUnit then begin
    AddUsesSubNodes(UDNode);
    CreateTVNodes(SelUnitsTreeView,Node,UDNode,false);
    AllowExpansion:=true;
  end;
end;

procedure TUnitDependenciesWindow.Timer1Timer(Sender: TObject);
var
  Cnt: Integer;
begin
  if (FNewUsesGraph=nil) then exit;
  Cnt:=0;
  if FNewUsesGraph.FilesTree<>nil then
    Cnt:=FNewUsesGraph.FilesTree.Count;
  StatsLabel.Caption:=Format(lisUDScanningUnits, [IntToStr(Cnt)]);
end;

procedure TUnitDependenciesWindow.UnitsLvlGraphMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  GraphNode: TLvlGraphNode;
  UGUnit: TUGUnit;
begin
  GraphNode:=UnitsLvlGraph.GetNodeAt(X,Y);
  if (Button=mbLeft) and (ssDouble in Shift) then begin
    if (GraphNode<>nil) and (GraphNode.Data<>nil) then begin
      UGUnit:=TUGUnit(GraphNode.Data);
      LazarusIDE.DoOpenEditorFile(UGUnit.Filename,-1,-1,[ofAddToRecent]);
    end;
  end;
end;

procedure TUnitDependenciesWindow.UnitsLvlGraphSelectionChanged(Sender: TObject
  );
var
  GraphNode: TLvlGraphNode;
  UGUnit: TUGUnit;
begin
  GraphNode:=UnitsLvlGraph.Graph.FirstSelected;
  while GraphNode<>nil do begin
    UGUnit:=TUGUnit(GraphNode.Data);
    if UGUnit<>nil then begin

    end;
    GraphNode:=GraphNode.NextSelected;
  end;
end;

procedure TUnitDependenciesWindow.UnitsTreeViewShowHint(Sender: TObject;
  HintInfo: PHintInfo);

  procedure CountUses(List: TFPList; out IntfCnt, ImplCnt: integer);
  var
    i: Integer;
  begin
    IntfCnt:=0;
    ImplCnt:=0;
    if List=nil then exit;
    for i:=0 to List.Count-1 do
      if TUGUses(List[i]).InImplementation then
        inc(ImplCnt)
      else
        inc(IntfCnt);
  end;

var
  TV: TTreeView;
  TVNode: TTreeNode;
  p: types.TPoint;
  UDNode: TUDNode;
  Filename: String;
  s: String;
  UGUnit: TUGUnit;
  UsedByIntf: Integer;
  UsedByImpl: Integer;
  UsesIntf: integer;
  UsesImpl: integer;
begin
  TV:=Sender as TTreeView;
  p:=HintInfo^.CursorPos;
  TVNode:=TV.GetNodeAt(p.X,p.Y);
  if (TVNode=nil) or not (TObject(TVNode.Data) is TUDNode) then exit;
  UDNode:=TUDNode(TVNode.Data);
  Filename:=GetFilename(UDNode);
  if Filename='' then exit;
  s:=Format(lisUDFile, [Filename]);
  if UDNode.Typ=udnUnit then begin
    UGUnit:=UsesGraph.GetUnit(Filename,false);
    if UGUnit<>nil then begin
      CountUses(UGUnit.UsesUnits,UsesIntf,UsesImpl);
      CountUses(UGUnit.UsedByUnits,UsedByIntf,UsedByImpl);
      if UsesIntf>0 then
        s+=LineEnding+Format(lisUDInterfaceUses, [IntToStr(UsesIntf)]);
      if UsesImpl>0 then
        s+=LineEnding+Format(lisUDImplementationUses, [IntToStr(UsesImpl)]);
      if UsedByIntf>0 then
        s+=LineEnding+Format(lisUDUsedByInterfaces, [IntToStr(UsedByIntf)]);
      if UsedByImpl>0 then
        s+=LineEnding+Format(lisUDUsedByImplementations, [IntToStr(UsedByImpl)]
          );
    end;
  end;
  HintInfo^.HintStr:=s;
end;

procedure TUnitDependenciesWindow.UnitsTreeViewMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  TVNode: TTreeNode;
  UDNode: TUDNode;
  UGGroup: TUGGroup;
  TV: TTreeView;
begin
  TV:=Sender as TTreeView;
  TVNode:=TV.GetNodeAt(X,Y);
  if TVNode=nil then exit;
  UDNode:=nil;
  if TObject(TVNode.Data) is TUDNode then
    UDNode:=TUDNode(TVNode.Data);
  if (Button=mbLeft) and (ssDouble in Shift) and (UDNode<>nil) then begin
    if UDNode.Typ=udnUnit then
      // open unit in source editor
      LazarusIDE.DoOpenEditorFile(UDNode.Identifier,-1,-1,[ofAddToRecent])
    else if UDNode.Typ=udnGroup then begin
      UGGroup:=Groups.GetGroup(UDNode.Group,false);
      if UGGroup=nil then exit;
      if IsProjectGroup(UGGroup) then begin
        // open project inspector
        ExecuteIDECommand(Self,ecProjectInspector);
      end else begin
        // open package editor
        PackageEditingInterface.DoOpenPackageWithName(UGGroup.Name,[pofAddToRecent],false);
      end;
    end;
  end;
end;

procedure TUnitDependenciesWindow.AllUnitsTreeViewSelectionChanged(
  Sender: TObject);
begin
  Include(FFlags,udwNeedUpdateSelUnitsTreeView);
  IdleConnected:=true;
end;

procedure TUnitDependenciesWindow.AllUnitsFilterEditChange(Sender: TObject);
begin
  Include(FFlags,udwNeedUpdateAllUnitsTreeView);
  IdleConnected:=true;
end;

procedure TUnitDependenciesWindow.AllUnitsFilterEditEnter(Sender: TObject);
begin
  if AllUnitsFilterEdit.Text=ResStrFilter then
    AllUnitsFilterEdit.Text:='';
end;

procedure TUnitDependenciesWindow.AllUnitsFilterEditExit(Sender: TObject);
begin
  if AllUnitsFilterEdit.Text='' then
    AllUnitsFilterEdit.Text:=ResStrFilter;
end;

procedure TUnitDependenciesWindow.FormDestroy(Sender: TObject);
begin
  IdleConnected:=false;

  FreeUsesGraph;
  FreeAndNil(FNewGroups);
  FreeAndNil(FNewUsesGraph);
  FreeAndNil(FPendingUnitDependencyRoute);
end;

procedure TUnitDependenciesWindow.GroupsLvlGraphSelectionChanged(Sender: TObject
  );
begin
  UpdateUnitsLvlGraph;
end;

procedure TUnitDependenciesWindow.OnIdle(Sender: TObject; var Done: Boolean);
var
  Completed: boolean;
begin
  if udwParsing in FFlags then begin
    fNewUsesGraph.Parse(true,Completed,200);
    if Completed then begin
      Exclude(FFlags,udwParsing);
      // free old uses graph
      FreeUsesGraph;
      // switch to new UsesGraph
      FUsesGraph:=FNewUsesGraph;
      FNewUsesGraph:=nil;
      FGroups:=FNewGroups;
      FNewGroups:=nil;
      // create Groups
      CreateGroups;
      // mark cycles
      MarkCycles;
      // hide progress bar and update stats
      ProgressBar1.Visible:=false;
      ProgressBar1.Style:=pbstNormal;
      RefreshButton.Enabled:=true;
      Timer1.Enabled:=false;
      StatsLabel.Caption:=Format(lisUDUnits2, [IntToStr(
        FUsesGraph.FilesTree.Count)]);
      // update controls
      UpdateAll;
    end;
  end else if udwNeedUpdateGroupsLvlGraph in FFlags then
    UpdateGroupsLvlGraph
  else if udwNeedUpdateUnitsLvlGraph in FFlags then
    UpdateUnitsLvlGraph
  else if udwNeedUpdateAllUnitsTreeView in FFlags then
    UpdateAllUnitsTreeView
  else if udwNeedUpdateAllUnitsTVSearch in FFlags then
    UpdateAllUnitsTreeViewSearch
  else if udwNeedUpdateSelUnitsTreeView in FFlags then
    UpdateSelUnitsTreeView
  else if udwNeedUpdateSelUnitsTVSearch in FFlags then
    UpdateSelUnitsTreeViewSearch
  else
    IdleConnected:=false;
  Done:=not IdleConnected;
end;

procedure TUnitDependenciesWindow.SearchPkgsCheckBoxChange(Sender: TObject);
begin
  ScopeChanged;
end;

procedure TUnitDependenciesWindow.SearchSrcEditCheckBoxChange(Sender: TObject);
begin
  ScopeChanged;
end;

procedure TUnitDependenciesWindow.SelUnitsSearchEditChange(Sender: TObject);
begin
  Include(FFlags,udwNeedUpdateSelUnitsTVSearch);
  IdleConnected:=true;
end;

procedure TUnitDependenciesWindow.SelUnitsSearchEditEnter(Sender: TObject);
begin
  if SelUnitsSearchEdit.Text=ResStrSearch then
    SelUnitsSearchEdit.Text:='';
end;

procedure TUnitDependenciesWindow.SelUnitsSearchEditExit(Sender: TObject);
begin
  if SelUnitsSearchEdit.Text='' then
    SelUnitsSearchEdit.Text:=ResStrSearch;
end;

procedure TUnitDependenciesWindow.SelUnitsSearchNextSpeedButtonClick(
  Sender: TObject);
begin
  SelectNextSearchTV(SelUnitsTreeView,SelUnitsTreeView.Selected,true,true);
  fSelUnitsTVSearchStartNode:=SelUnitsTreeView.Selected;
end;

procedure TUnitDependenciesWindow.SelUnitsSearchPrevSpeedButtonClick(
  Sender: TObject);
begin
  SelectNextSearchTV(SelUnitsTreeView,SelUnitsTreeView.Selected,false,true);
  fSelUnitsTVSearchStartNode:=SelUnitsTreeView.Selected;
end;

procedure TUnitDependenciesWindow.SearchCustomFilesBrowseButtonClick(Sender: TObject);
var
  Dlg: TSelectDirectoryDialog;
  s: TCaption;
  aFilename: String;
  p: Integer;
begin
  Dlg:=TSelectDirectoryDialog.Create(nil);
  try
    InitIDEFileDialog(Dlg);
    Dlg.Options:=Dlg.Options+[ofPathMustExist];
    if not Dlg.Execute then exit;
    aFilename:=TrimFilename(Dlg.FileName);
    s:=SearchCustomFilesComboBox.Text;
    p:=1;
    if FindNextDelimitedItem(s,';',p,aFilename)<>'' then exit;
    if s<>'' then s+=';';
    s+=aFilename;
    SearchCustomFilesComboBox.Text:=s;
    ScopeChanged;
  finally
    Dlg.Free;
  end;
end;

procedure TUnitDependenciesWindow.SearchCustomFilesCheckBoxChange(
  Sender: TObject);
begin
  UpdateUnitsButtons;
  ScopeChanged;
end;

procedure TUnitDependenciesWindow.SearchCustomFilesComboBoxChange(
  Sender: TObject);
begin
  ScopeChanged;
end;

procedure TUnitDependenciesWindow.UnitsTVCollapseAllMenuItemClick(
  Sender: TObject);
var
  TV: TTreeView;
  i: Integer;
begin
  TV:=TTreeView(UnitsTVPopupMenu.PopupComponent);
  if not (TV is TTreeView) then exit;
  TV.BeginUpdate;
  for i:=0 to TV.Items.TopLvlCount-1 do
    TV.Items.TopLvlItems[i].Collapse(true);
  TV.EndUpdate;
end;

procedure TUnitDependenciesWindow.UnitsTVCopyFilenameMenuItemClick(
  Sender: TObject);
var
  TV: TTreeView;
  TVNode: TTreeNode;
begin
  TV:=TTreeView(UnitsTVPopupMenu.PopupComponent);
  if not (TV is TTreeView) then exit;
  TVNode:=TV.Selected;
  if (TVNode=nil) or not (TObject(TVNode.Data) is TUDNode) then exit;
  Clipboard.AsText:=GetFilename(TUDNode(TVNode.Data));
end;

procedure TUnitDependenciesWindow.UnitsTVExpandAllMenuItemClick(Sender: TObject
  );
var
  TV: TTreeView;
  i: Integer;
begin
  TV:=TTreeView(UnitsTVPopupMenu.PopupComponent);
  if not (TV is TTreeView) then exit;
  TV.BeginUpdate;
  for i:=0 to TV.Items.TopLvlCount-1 do
    TV.Items.TopLvlItems[i].Expand(true);
  TV.EndUpdate;
end;

procedure TUnitDependenciesWindow.UnitsTVPopupMenuPopup(Sender: TObject);
var
  TV: TTreeView;
  TVNode: TTreeNode;
  UDNode: TUDNode;
begin
  TV:=UnitsTVPopupMenu.PopupComponent as TTreeView;
  UnitsTVExpandAllMenuItem.Visible:=TV=AllUnitsTreeView;
  TVNode:=TV.Selected;
  if (TVNode<>nil) and (TObject(TVNode.Data) is TUDNode) then begin
    UDNode:=TUDNode(TVNode.Data);
    UnitsTVUnusedUnitsMenuItem.Enabled:=UDNode.Typ=udnUnit;
  end else
    UnitsTVUnusedUnitsMenuItem.Enabled:=false;
end;

procedure TUnitDependenciesWindow.UnitsTVUnusedUnitsMenuItemClick(Sender: TObject
  );
var
  TV: TTreeView;
  TVNode: TTreeNode;
  UDNode: TUDNode;
  Filename: String;
  Code: TCodeBuffer;
begin
  TV:=TTreeView(UnitsTVPopupMenu.PopupComponent);
  if not (TV is TTreeView) then exit;
  TVNode:=TV.Selected;
  if (TVNode=nil) or not (TObject(TVNode.Data) is TUDNode) then exit;
  UDNode:=TUDNode(TVNode.Data);
  if UDNode.Typ<>udnUnit then exit;
  Filename:=GetFilename(UDNode);
  Code:=CodeToolBoss.LoadFile(Filename,true,false);
  ShowUnusedUnitsDialog(Code);
end;

procedure TUnitDependenciesWindow.SetIdleConnected(AValue: boolean);
begin
  if FIdleConnected=AValue then Exit;
  FIdleConnected:=AValue;
  if IdleConnected then
    Application.AddOnIdleHandler(@OnIdle)
  else
    Application.RemoveOnIdleHandler(@OnIdle);
end;

procedure TUnitDependenciesWindow.CreateGroups;
var
  i: Integer;
begin
  if FGroups=nil then
    RaiseCatchableException('');
  CreateProjectGroup(LazarusIDE.ActiveProject);
  for i:=0 to PackageEditingInterface.GetPackageCount-1 do
    CreatePackageGroup(PackageEditingInterface.GetPackages(i));
  CreateFPCSrcGroups;
  GuessGroupOfUnits;
end;

function TUnitDependenciesWindow.CreateProjectGroup(AProject: TLazProject
  ): TUGGroup;
var
  i: Integer;
  Filename: String;
  CurUnit: TUGUnit;
  ProjFile: TLazProjectFile;
begin
  if AProject=nil then exit;
  Result:=Groups.GetGroup(GroupPrefixProject,true);
  Result.BaseDir:=ExtractFilePath(AProject.ProjectInfoFile);
  if not FilenameIsAbsolute(Result.BaseDir) then
    Result.BaseDir:='';
  //debugln(['TUnitDependenciesDialog.CreateProjectGroup ',Result.Name,' FileCount=',AProject.FileCount]);
  for i:=0 to AProject.FileCount-1 do begin
    ProjFile:=AProject.Files[i];
    if not ProjFile.IsPartOfProject then continue;
    Filename:=AProject.Files[i].Filename;
    CurUnit:=UsesGraph.GetUnit(Filename,false);
    if CurUnit=nil then continue;
    if not (CurUnit is TUGGroupUnit) then begin
      debugln(['TUnitDependenciesDialog.CreateProjectGroup WARNING: ',CurUnit.Filename,' ',CurUnit.Classname,' should be TUGGroupUnit']);
      continue;
    end;
    if TUGGroupUnit(CurUnit).Group<>nil then continue;
    Result.AddUnit(TUGGroupUnit(CurUnit));
  end;
end;

function TUnitDependenciesWindow.CreatePackageGroup(APackage: TIDEPackage
  ): TUGGroup;
var
  i: Integer;
  Filename: String;
  CurUnit: TUGUnit;
begin
  if APackage=nil then exit;
  Result:=Groups.GetGroup(APackage.Name,true);
  Result.BaseDir:=APackage.DirectoryExpanded;
  if not FilenameIsAbsolute(Result.BaseDir) then
    Result.BaseDir:='';
  //debugln(['TUnitDependenciesDialog.CreatePackageGroup ',Result.Name]);
  for i:=0 to APackage.FileCount-1 do begin
    Filename:=APackage.Files[i].GetFullFilename;
    CurUnit:=UsesGraph.GetUnit(Filename,false);
    if CurUnit is TUGGroupUnit then begin
      if TUGGroupUnit(CurUnit).Group<>nil then continue;
      Result.AddUnit(TUGGroupUnit(CurUnit));
    end;
  end;
end;

procedure TUnitDependenciesWindow.CreateFPCSrcGroups;

  function ExtractFilePathStart(Filename: string; DirCount: integer): string;
  var
    p: Integer;
  begin
    p:=1;
    while p<=length(Filename) do begin
      if Filename[p]=PathDelim then begin
        DirCount-=1;
        if DirCount=0 then begin
          Result:=LeftStr(Filename,p-1);
          exit;
        end;
      end;
      inc(p);
    end;
    Result:=Filename;
  end;

var
  FPCSrcDir: String;
  Node: TAVLTreeNode;
  CurUnit: TUGGroupUnit;
  Directory: String;
  Grp: TUGGroup;
  BaseDir: String;
begin
  FPCSrcDir:=AppendPathDelim(GetFPCSrcDir);

  // for each unit in the fpc source directory:
  // if in rtl/ put into group GroupPrefixFPCSrc+RTL
  // if in packages/<name>, put in group GroupPrefixFPCSrc+<name>
  Node:=UsesGraph.FilesTree.FindLowest;
  while Node<>nil do begin
    CurUnit:=TUGGroupUnit(Node.Data);
    Node:=UsesGraph.FilesTree.FindSuccessor(Node);
    if TUGGroupUnit(CurUnit).Group<>nil then continue;
    if CompareFilenames(FPCSrcDir,LeftStr(CurUnit.Filename,length(FPCSrcDir)))<>0
    then
      continue;
    // a unit in the FPC sources
    BaseDir:=ExtractFilePath(CurUnit.Filename);
    Directory:=copy(BaseDir,length(FPCSrcDir)+1,length(BaseDir));
    Directory:=ExtractFilePathStart(Directory,2);
    if LeftStr(Directory,length('rtl'))='rtl' then
      Directory:='RTL'
    else if LeftStr(Directory,length('packages'))='packages' then
      System.Delete(Directory,1,length('packages'+PathDelim));
    Grp:=Groups.GetGroup(GroupPrefixFPCSrc+Directory,true);
    if Grp.BaseDir='' then
      Grp.BaseDir:=BaseDir;
    //debugln(['TUnitDependenciesDialog.CreateFPCSrcGroups ',Grp.Name]);
    Grp.AddUnit(TUGGroupUnit(CurUnit));
  end;
end;

procedure TUnitDependenciesWindow.GuessGroupOfUnits;
var
  Node: TAVLTreeNode;
  CurUnit: TUGGroupUnit;
  Filename: String;
  Owners: TFPList;
  i: Integer;
  Group: TUGGroup;
  CurDirectory: String;
  LastDirectory: Char;
begin
  Owners:=nil;
  LastDirectory:='.';
  Node:=UsesGraph.FilesTree.FindLowest;
  while Node<>nil do begin
    CurUnit:=TUGGroupUnit(Node.Data);
    if CurUnit.Group=nil then begin
      Filename:=CurUnit.Filename;
      //debugln(['TUnitDependenciesDialog.GuessGroupOfUnits no group for ',Filename]);
      CurDirectory:=ExtractFilePath(Filename);
      if CompareFilenames(CurDirectory,LastDirectory)<>0 then begin
        FreeAndNil(Owners);
        Owners:=PackageEditingInterface.GetPossibleOwnersOfUnit(Filename,[piosfIncludeSourceDirectories]);
      end;
      Group:=nil;
      if (Owners<>nil) then begin
        for i:=0 to Owners.Count-1 do begin
          if TObject(Owners[i]) is TLazProject then begin
            Group:=Groups.GetGroup(GroupPrefixProject,true);
            //debugln(['TUnitDependenciesDialog.GuessGroupOfUnits ',Group.Name]);
            break;
          end else if TObject(Owners[i]) is TIDEPackage then begin
            Group:=Groups.GetGroup(TIDEPackage(Owners[i]).Name,true);
            //debugln(['TUnitDependenciesDialog.GuessGroupOfUnits ',Group.Name]);
            break;
          end;
        end;
      end;
      if Group=nil then begin
        Group:=Groups.GetGroup(GroupNone,true);
        //debugln(['TUnitDependenciesDialog.GuessGroupOfUnits ',Group.Name]);
      end;
      Group.AddUnit(TUGGroupUnit(CurUnit));
    end;
    Node:=UsesGraph.FilesTree.FindSuccessor(Node);
  end;
  FreeAndNil(Owners);
end;

procedure TUnitDependenciesWindow.MarkCycles;
begin

end;

procedure TUnitDependenciesWindow.SetPendingUnitDependencyRoute(AValue: TStrings
  );
begin
  if FPendingUnitDependencyRoute.Equals(AValue) then Exit;
  FPendingUnitDependencyRoute.Assign(AValue);
  FFlags:=FFlags+[udwNeedUpdateAllUnitsTreeView,udwNeedUpdateSelUnitsTreeView];
  IdleConnected:=true;
end;

procedure TUnitDependenciesWindow.StartParsing;
begin
  if (FNewUsesGraph<>nil) or (udwParsing in FFlags) then
    RaiseCatchableException('');
  Include(FFlags,udwParsing);

  ProgressBar1.Visible:=true;
  ProgressBar1.Style:=pbstMarquee;
  StatsLabel.Caption:=lisUDScanning;
  Timer1.Enabled:=true;
  RefreshButton.Enabled:=false;

  CreateUsesGraph(FNewUsesGraph,FNewGroups);

  LazarusIDE.BeginCodeTools;
  AddStartAndTargetUnits;

  IdleConnected:=true;
end;

procedure TUnitDependenciesWindow.ScopeChanged;
begin
  FreeAndNil(FNewGroups);
  FreeAndNil(FNewUsesGraph);
  Exclude(FFlags,udwParsing);
  StartParsing;
end;

procedure TUnitDependenciesWindow.SetCurrentUnit(AValue: TUGUnit);
begin
  if FCurrentUnit=AValue then Exit;
  FCurrentUnit:=AValue;
end;

function TUnitDependenciesWindow.CreateAllUnitsTree: TUDNode;
var
  Node: TUDNode;
  ParentNode: TUDNode;
  GroupName: String;
  ShowDirectories: Boolean;
  ShowGroups: Boolean;
  NodeText: String;
  RootNode: TUDNode;
  Filter: String;
  UGUnit: TUGGroupUnit;
  AVLNode: TAVLTreeNode;
  Group: TUGGroup;
  GroupNode: TUDNode;
  Filename: String;
  p: Integer;
  Dir: String;
  DirNode: TUDNode;
  BaseDir: String;
  CurDir: String;
begin
  Filter:=GetAllUnitsFilter(true);
  ShowGroups:=AllUnitsShowGroupNodesSpeedButton.Down;
  ShowDirectories:=AllUnitsShowDirsSpeedButton.Down;
  RootNode:=TUDNode.Create;
  for AVLNode in UsesGraph.FilesTree do begin
    UGUnit:=TUGGroupUnit(AVLNode.Data);
    Filename:=UGUnit.Filename;
    NodeText:=ExtractFileName(Filename);
    if (Filter<>'') and (Pos(Filter, UTF8LowerCase(NodeText))<1) then
      continue;
    Group:=UGUnit.Group;
    BaseDir:='';
    if Group=nil then begin
      GroupName:=GroupNone
    end else begin
      GroupName:=Group.Name;
      if FilenameIsAbsolute(Group.BaseDir) then
        BaseDir:=ChompPathDelim(Group.BaseDir);
    end;
    ParentNode:=RootNode;
    if ShowGroups then begin
      // create group nodes
      GroupNode:=ParentNode.GetNode(udnGroup,GroupName,true);
      if GroupNode.Identifier='' then begin
        GroupNode.Identifier:=GroupName;
        GroupNode.Group:=GroupName;
      end;
      ParentNode:=GroupNode;
      if FilenameIsAbsolute(BaseDir) and FilenameIsAbsolute(Filename) then
        Filename:=CreateRelativePath(Filename,BaseDir);
    end;
    if ShowDirectories then begin
      // create directory nodes
      CurDir:=BaseDir;
      p:=1;
      repeat
        Dir:=FindNextDirectoryInFilename(Filename,p);
        if p>length(Filename) then break;
        if Dir<>'' then begin
          DirNode:=ParentNode.GetNode(udnDirectory,Dir,true);
          CurDir+=PathDelim+Dir;
          if DirNode.Identifier='' then begin
            DirNode.Identifier:=CurDir;
          end;
          ParentNode:=DirNode;
        end;
      until false;
    end;
    Node:=ParentNode.GetNode(udnUnit, NodeText, true);
    Node.Identifier:=UGUnit.Filename;
    Node.Group:=GroupName;
  end;
  Result:=RootNode;
end;

function TUnitDependenciesWindow.CreateSelUnitsTree: TUDNode;
var
  RootNode: TUDNode;
  SelTVNode: TTreeNode;
  SelUDNode: TUDNode;
  UDNode: TUDNode;
begin
  RootNode:=TUDNode.Create;
  SelTVNode:=AllUnitsTreeView.GetFirstMultiSelected;
  if SelTVNode=nil then
    SelTVNode:=AllUnitsTreeView.Selected;
  //debugln(['TUnitDependenciesWindow.CreateSelUnitsTree SelTVNode=',SelTVNode<>nil]);
  while SelTVNode<>nil do begin
    if TObject(SelTVNode.Data) is TUDNode then begin
      SelUDNode:=TUDNode(SelTVNode.Data);
      if SelUDNode.Typ=udnUnit then begin
        UDNode:=RootNode.GetNode(udnUnit,SelUDNode.NodeText,true);
        UDNode.Identifier:=SelUDNode.Identifier;
        UDNode.Group:=SelUDNode.Group;
        AddUsesSubNodes(UDNode);
      end;
    end;
    SelTVNode:=SelTVNode.GetNextMultiSelected;
  end;

  ExpandPendingUnitDependencyRoute(RootNode);

  Result:=RootNode;
end;

procedure TUnitDependenciesWindow.ExpandPendingUnitDependencyRoute(
  RootNode: TUDNode);
var
  i: Integer;
  CurUnitName: String;
  UDNode: TUDNode;
  IntfUDNode: TUDNode;
  ParentUDNode: TUDNode;
begin
  if PendingUnitDependencyRoute.Count=0 then exit;
  ConvertUnitNameRouteToPath(PendingUnitDependencyRoute);
  try
    ParentUDNode:=RootNode;
    for i:=0 to PendingUnitDependencyRoute.Count-1 do begin
      CurUnitName:=PendingUnitDependencyRoute[i];
      UDNode:=ParentUDNode.FindUnit(CurUnitName);
      //debugln(['TUnitDependenciesWindow.ExpandPendingUnitDependencyPath CurUnitName="',CurUnitName,'" UDNode=',DbgSName(UDNode)]);
      if UDNode=nil then exit;
      if i=PendingUnitDependencyRoute.Count-1 then exit;
      IntfUDNode:=UDNode.FindFirst(udnInterface);
      if IntfUDNode=nil then begin
        if UDNode.Count>0 then
          exit; // already expanded -> has no interface
        // expand
        AddUsesSubNodes(UDNode);
        IntfUDNode:=UDNode.FindFirst(udnInterface);
        if IntfUDNode=nil then exit;
      end;
      ParentUDNode:=IntfUDNode;
    end;
  finally
    // apply only once => clear pending
    PendingUnitDependencyRoute.Clear;
  end;
end;

procedure TUnitDependenciesWindow.ConvertUnitNameRouteToPath(Route: TStrings);
var
  UGUnitList: TFPList;
  UGUnit: TUGUnit;
  i: Integer;
begin
  if Route.Count<=1 then exit;
  UGUnitList:=TFPList.Create;
  try
    // convert unit names to TUGUnit
    for i:=0 to Route.Count-1 do begin
      UGUnit:=FUsesGraph.FindUnit(Route[i]);
      if UGUnit=nil then continue;
      UGUnitList.Add(UGUnit);
    end;
    // insert missing links
    FUsesGraph.InsertMissingLinks(UGUnitList);
    // convert TUGUnit to unit names
    Route.Clear;
    for i:=0 to UGUnitList.Count-1 do
      Route.Add(ExtractFileNameOnly(TUGUnit(UGUnitList[i]).Filename));
  finally
    UGUnitList.Free;
  end;
end;

procedure TUnitDependenciesWindow.AddUsesSubNodes(UDNode: TUDNode);

  procedure AddUses(ParentUDNode: TUDNode; UsesList: TFPList;
    NodeTyp: TUDNodeType);
  var
    i: Integer;
    UGUses: TUGUses;
    NodeText: String;
    SectionUDNode: TUDNode;
    InImplementation: Boolean;
    UsedBy: Boolean;
    OtherUnit: TUGGroupUnit;
    Filename: String;
    UDNode: TUDNode;
    GroupName: String;
    Cnt: Integer;
  begin
    if ParentUDNode=nil then exit;
    if UsesList=nil then exit;
    if not (NodeTyp in [udnInterface,udnImplementation,udnUsedByInterface,udnUsedByImplementation])
    then exit;
    InImplementation:=(NodeTyp in [udnImplementation,udnUsedByImplementation]);
    UsedBy:=(NodeTyp in [udnUsedByInterface,udnUsedByImplementation]);

    // count the number of uses
    Cnt:=0;
    for i:=0 to UsesList.Count-1 do begin
      UGUses:=TUGUses(UsesList[i]);
      if UGUses.InImplementation<>InImplementation then continue;
      inc(Cnt);
    end;
    if Cnt=0 then exit;

    // create a section node
    NodeText:=IntToStr(Cnt);
    case NodeTyp of
    udnInterface: NodeText:=Format(lisUDInterfaceUses2, [NodeText]);
    udnImplementation: NodeText:=Format(lisUDImplementationUses2, [NodeText]);
    udnUsedByInterface: NodeText:=Format(lisUDUsedByInterfaces2, [NodeText]);
    udnUsedByImplementation: NodeText:=Format(lisUDUsedByImplementations2, [
      NodeText]);
    else exit;
    end;
    SectionUDNode:=ParentUDNode.GetNode(NodeTyp,NodeText,true);

    // create unit nodes
    for i:=0 to UsesList.Count-1 do begin
      UGUses:=TUGUses(UsesList[i]);
      if UGUses.InImplementation<>InImplementation then continue;
      if UsedBy then
        OtherUnit:=TUGGroupUnit(UGUses.Owner)
      else
        OtherUnit:=TUGGroupUnit(UGUses.UsesUnit);
      Filename:=OtherUnit.Filename;
      NodeText:=ExtractFileName(Filename);
      UDNode:=SectionUDNode.GetNode(udnUnit,NodeText,true);
      UDNode.Identifier:=Filename;
      if OtherUnit.Group<>nil then
        GroupName:=OtherUnit.Group.Name
      else
        GroupName:=GroupNone;
      UDNode.Group:=GroupName;
      UDNode.HasChildren:=
         ((OtherUnit.UsedByUnits<>nil) and (OtherUnit.UsedByUnits.Count>0))
         or ((OtherUnit.UsesUnits<>nil) and (OtherUnit.UsesUnits.Count>0));
    end;
  end;

var
  Filename: String;
  UGUnit: TUGGroupUnit;
begin
  // add connected units
  Filename:=UDNode.Identifier;
  UGUnit:=TUGGroupUnit(UsesGraph.GetUnit(Filename,false));
  if UGUnit<>nil then begin
    AddUses(UDNode,UGUnit.UsesUnits,udnInterface);
    AddUses(UDNode,UGUnit.UsesUnits,udnImplementation);
    AddUses(UDNode,UGUnit.UsedByUnits,udnUsedByInterface);
    AddUses(UDNode,UGUnit.UsedByUnits,udnUsedByImplementation);
  end;
end;

procedure TUnitDependenciesWindow.SelectNextSearchTV(TV: TTreeView;
  StartTVNode: TTreeNode; SearchNext, SkipStart: boolean);
var
  TVNode: TTreeNode;
  NextTVNode: TTreeNode;
  PrevTVNode: TTreeNode;
  LowerSearch: String;
begin
  //debugln(['TUnitDependenciesWindow.SelectNextSearchTV START ',DbgSName(TV),' ',StartTVNode<>nil,' SearchNext=',SearchNext,' SkipStart=',SkipStart]);
  TV.BeginUpdate;
  try
    TVNode:=StartTVNode;
    if TVNode=nil then begin
      if SearchNext then
        TVNode:=TV.Items.GetFirstNode
      else
        TVNode:=TV.Items.GetLastNode;
      SkipStart:=false;
    end;
    if TV=AllUnitsTreeView then
      LowerSearch:=GetAllUnitsSearch(true)
    else
      LowerSearch:=GetSelUnitsSearch(true);
    //if TVNode<>nil then debugln(['TUnitDependenciesWindow.SelectNextSearchTV searching "',LowerSearch,'" TVNode=',TVNode.Text,' SearchNext=',SearchNext,' SkipStart=',SkipStart]);
    TVNode:=FindNextTVNode(TVNode,LowerSearch,SearchNext,SkipStart);
    //if TVNode<>nil then debugln(['TUnitDependenciesWindow.SelectNextSearchTV found TVNode=',TVNode.Text]);
    NextTVNode:=nil;
    PrevTVNode:=nil;
    if TVNode<>nil then begin
      TV.Items.ClearMultiSelection(True);
      TV.Selected:=TVNode;
      TV.MakeSelectionVisible;
      NextTVNode:=FindNextTVNode(TVNode,LowerSearch,true,true);
      PrevTVNode:=FindNextTVNode(TVNode,LowerSearch,false,true);
    end;
    if TV=AllUnitsTreeView then begin
      AllUnitsSearchNextSpeedButton.Enabled:=NextTVNode<>nil;
      AllUnitsSearchPrevSpeedButton.Enabled:=PrevTVNode<>nil;
    end else begin
      SelUnitsSearchNextSpeedButton.Enabled:=NextTVNode<>nil;
      SelUnitsSearchPrevSpeedButton.Enabled:=PrevTVNode<>nil;
    end;
  finally
    TV.EndUpdate;
  end;
  //debugln(['TUnitDependenciesWindow.SelectNextSearchTV END']);
end;

procedure TUnitDependenciesWindow.AddStartAndTargetUnits;
var
  aProject: TLazProject;
  i: Integer;
  SrcEdit: TSourceEditorInterface;
  AFilename: String;
  Pkg: TIDEPackage;
  j: Integer;
  PkgFile: TLazPackageFile;
begin
  FNewUsesGraph.TargetAll:=true;

  // project lpr
  aProject:=LazarusIDE.ActiveProject;
  if (aProject<>nil) and (aProject.MainFile<>nil) then
    FNewUsesGraph.AddStartUnit(aProject.MainFile.Filename);

  // add all open packages
  if SearchPkgsCheckBox.Checked then begin
    for i:=0 to PackageEditingInterface.GetPackageCount-1 do begin
      Pkg:=PackageEditingInterface.GetPackages(i);
      if not FilenameIsAbsolute(Pkg.Filename) then continue;
      for j:=0 to Pkg.FileCount-1 do begin
        PkgFile:=Pkg.Files[j];
        if PkgFile.Removed then continue;
        if not (PkgFile.FileType in PkgFileRealUnitTypes) then continue;
        if not PkgFile.InUses then continue;
        aFilename:=PkgFile.GetFullFilename;
        if FilenameIsAbsolute(AFilename)
        and FilenameIsPascalUnit(AFilename) then
          FNewUsesGraph.AddStartUnit(AFilename);
      end;
    end;
  end;

  // add all source editor files
  if SearchSrcEditCheckBox.Checked then begin
    for i:=0 to SourceEditorManagerIntf.SourceEditorCount-1 do begin
      SrcEdit:=SourceEditorManagerIntf.SourceEditors[i];
      AFilename:=SrcEdit.FileName;
      if FilenameIsPascalUnit(AFilename) then
        FNewUsesGraph.AddStartUnit(AFilename);
    end;
  end;

  // additional units and directories
  if SearchCustomFilesCheckBox.Checked then
    AddAdditionalFilesAsStartUnits;
end;

procedure TUnitDependenciesWindow.AddAdditionalFilesAsStartUnits;
var
  List: TCaption;
  aFilename: String;
  Files: TStrings;
  i: Integer;
  p: Integer;
begin
  List:=SearchCustomFilesComboBox.Text;
  p:=1;
  while p<=length(List) do begin
    aFilename:=TrimAndExpandFilename(GetNextDelimitedItem(List,';',p));
    if (AFilename='') then continue;
    if not FileExistsCached(aFilename) then continue;
    if DirPathExistsCached(aFilename) then begin
      aFilename:=AppendPathDelim(aFilename);
      // add all units in directory
      Files:=nil;
      try
        CodeToolBoss.DirectoryCachePool.GetListing(aFilename,Files,false);
        if Files<>nil then begin
          for i:=0 to Files.Count-1 do begin
            if FilenameIsPascalUnit(Files[i]) then
              fNewUsesGraph.AddStartUnit(aFilename+Files[i]);
          end;
        end;
      finally
        Files.Free;
      end;
    end else begin
      // add a single file
      fNewUsesGraph.AddStartUnit(aFilename);
    end;
  end;
end;

procedure TUnitDependenciesWindow.SetupGroupsTabSheet;
begin
  GroupsTabSheet.Caption:=lisUDProjectsAndPackages;

  GroupsLvlGraph:=TLvlGraphControl.Create(Self);
  with GroupsLvlGraph do
  begin
    Name:='GroupsLvlGraph';
    Caption:='';
    Align:=alTop;
    Height:=200;
    NodeStyle.GapBottom:=5;
    Parent:=GroupsTabSheet;
    OnSelectionChanged:=@GroupsLvlGraphSelectionChanged;
  end;

  GroupsSplitter.Top:=GroupsLvlGraph.Height;

  UnitsLvlGraph:=TLvlGraphControl.Create(Self);
  with UnitsLvlGraph do
  begin
    Name:='UnitsLvlGraph';
    Caption:='';
    Align:=alClient;
    NodeStyle.GapBottom:=5;
    Parent:=GroupsTabSheet;
    OnSelectionChanged:=@UnitsLvlGraphSelectionChanged;
    OnMouseDown:=@UnitsLvlGraphMouseDown;
  end;
end;

procedure TUnitDependenciesWindow.SetupUnitsTabSheet;
begin
  UnitsTabSheet.Caption:=lisUDUnits;

  // start searching
  SearchCustomFilesCheckBox.Caption:=lisUDAdditionalDirectories;
  SearchCustomFilesCheckBox.Hint:=
    lisUDByDefaultOnlyTheProjectUnitsAndTheSourceEditorUnit;
  SearchCustomFilesComboBox.Text:='';
  SearchCustomFilesBrowseButton.Caption:=lisPathEditBrowse;

  SearchPkgsCheckBox.Caption:=lisUDAllPackageUnits;
  SearchSrcEditCheckBox.Caption:=lisUDAllSourceEditorUnits;

  // view all units
  AllUnitsGroupBox.Caption:=lisUDAllUnits;

  AllUnitsFilterEdit.Text:=ResStrFilter;
  AllUnitsShowDirsSpeedButton.Hint:=lisUDShowNodesForDirectories;
  AllUnitsShowDirsSpeedButton.LoadGlyphFromLazarusResource('pkg_hierarchical');
  AllUnitsShowDirsSpeedButton.Down:=true;
  AllUnitsShowGroupNodesSpeedButton.Hint:=lisUDShowNodesForProjectAndPackages;
  AllUnitsShowGroupNodesSpeedButton.LoadGlyphFromLazarusResource('pkg_hierarchical');
  AllUnitsShowGroupNodesSpeedButton.Down:=true;

  AllUnitsSearchEdit.Text:=ResStrSearch;
  AllUnitsSearchNextSpeedButton.Hint:=lisUDSearchNextOccurrenceOfThisPhrase;
  AllUnitsSearchNextSpeedButton.LoadGlyphFromLazarusResource('arrow_down');
  AllUnitsSearchPrevSpeedButton.Hint:=lisUDSearchPreviousOccurrenceOfThisPhrase;
  AllUnitsSearchPrevSpeedButton.LoadGlyphFromLazarusResource('arrow_up');

  // selected units
  SelectedUnitsGroupBox.Caption:=lisUDSelectedUnits;
  SelUnitsSearchEdit.Text:=ResStrSearch;
  SelUnitsSearchNextSpeedButton.Hint:=lisUDSearchNextUnitOfThisPhrase;
  SelUnitsSearchNextSpeedButton.LoadGlyphFromLazarusResource('arrow_down');
  SelUnitsSearchPrevSpeedButton.Hint:=lisUDSearchPreviousUnitOfThisPhrase;
  SelUnitsSearchPrevSpeedButton.LoadGlyphFromLazarusResource('arrow_up');

  // popup menu
  UnitsTVCopyFilenameMenuItem.Caption:=uemCopyFilename;
  UnitsTVUnusedUnitsMenuItem.Caption:=lisShowUnusedUnits;
  UnitsTVExpandAllMenuItem.Caption:=lisUDExpandAllNodes;
  UnitsTVCollapseAllMenuItem.Caption:=lisUDCollapseAllNodes;

  UpdateUnitsButtons;
end;

procedure TUnitDependenciesWindow.UpdateUnitsButtons;
begin
  SearchCustomFilesComboBox.Enabled:=SearchCustomFilesCheckBox.Checked;
  SearchCustomFilesBrowseButton.Enabled:=SearchCustomFilesCheckBox.Checked;
end;

procedure TUnitDependenciesWindow.UpdateAll;
begin
  UpdateGroupsLvlGraph;
  UpdateUnitsLvlGraph;
  UpdateAllUnitsTreeView;
end;

procedure TUnitDependenciesWindow.UpdateGroupsLvlGraph;
var
  AVLNode: TAVLTreeNode;
  Group: TUGGroup;
  Graph: TLvlGraph;
  PkgList: TFPList;
  i: Integer;
  RequiredPkg: TIDEPackage;
  GroupObj: TObject;
  GraphGroup: TLvlGraphNode;
  UnitNode: TAVLTreeNode;
  GrpUnit: TUGGroupUnit;
  UsedUnit: TUGGroupUnit;
begin
  Exclude(FFlags,udwNeedUpdateGroupsLvlGraph);
  GroupsLvlGraph.BeginUpdate;
  Graph:=GroupsLvlGraph.Graph;
  Graph.Clear;
  AVLNode:=Groups.Groups.FindLowest;
  while AVLNode<>nil do begin
    Group:=TUGGroup(AVLNode.Data);
    AVLNode:=Groups.Groups.FindSuccessor(AVLNode);
    GraphGroup:=Graph.GetNode(Group.Name,true);
    GraphGroup.Data:=Group;
    GroupObj:=nil;
    if IsProjectGroup(Group) then begin
      // project
      GroupObj:=LazarusIDE.ActiveProject;
      GraphGroup.Selected:=true;
    end else begin
      // package
      GroupObj:=PackageEditingInterface.FindPackageWithName(Group.Name);
    end;
    if GroupObj<>nil then begin
      // add lpk dependencies
      PkgList:=nil;
      try
        PackageEditingInterface.GetRequiredPackages(GroupObj,PkgList,[pirNotRecursive]);
        if (PkgList<>nil) then begin
          // add for each dependency an edge in the Graph
          for i:=0 to PkgList.Count-1 do begin
            RequiredPkg:=TIDEPackage(PkgList[i]);
            Graph.GetEdge(GraphGroup,Graph.GetNode(RequiredPkg.Name,true),true);
          end;
        end;
      finally
        PkgList.Free;
      end;
    end else if IsFPCSrcGroup(Group) then begin
      // add FPC source dependencies
      UnitNode:=Group.Units.FindLowest;
      while UnitNode<>nil do begin
        GrpUnit:=TUGGroupUnit(UnitNode.Data);
        UnitNode:=Group.Units.FindSuccessor(UnitNode);
        if GrpUnit.UsesUnits=nil then continue;
        for i:=0 to GrpUnit.UsesUnits.Count-1 do begin
          UsedUnit:=TUGGroupUnit(TUGUses(GrpUnit.UsesUnits[i]).UsesUnit);
          if (UsedUnit.Group=nil) or (UsedUnit.Group=Group) then continue;
          Graph.GetEdge(GraphGroup,Graph.GetNode(UsedUnit.Group.Name,true),true);
        end;
      end;
    end;
  end;
  GroupsLvlGraph.EndUpdate;
end;

procedure TUnitDependenciesWindow.UpdateUnitsLvlGraph;

  function UnitToCaption(AnUnit: TUGUnit): string;
  begin
    Result:=ExtractFileNameOnly(AnUnit.Filename);
  end;

var
  GraphGroup: TLvlGraphNode;
  NewUnits: TFilenameToPointerTree;
  UnitGroup: TUGGroup;
  AVLNode: TAVLTreeNode;
  GroupUnit: TUGGroupUnit;
  i: Integer;
  HasChanged: Boolean;
  Graph: TLvlGraph;
  CurUses: TUGUses;
  SourceGraphNode: TLvlGraphNode;
  TargetGraphNode: TLvlGraphNode;
  NewGroups: TStringToPointerTree;
  UsedUnit: TUGGroupUnit;
begin
  Exclude(FFlags,udwNeedUpdateUnitsLvlGraph);
  NewGroups:=TStringToPointerTree.Create(false);
  NewUnits:=TFilenameToPointerTree.Create(false);
  try
    // fetch new list of units
    GraphGroup:=GroupsLvlGraph.Graph.FirstSelected;
    while GraphGroup<>nil do begin
      UnitGroup:=TUGGroup(GraphGroup.Data);
      if UnitGroup<>nil then begin
        NewGroups[UnitGroup.Name]:=UnitGroup;
        AVLNode:=UnitGroup.Units.FindLowest;
        while AVLNode<>nil do begin
          GroupUnit:=TUGGroupUnit(AVLNode.Data);
          NewUnits[GroupUnit.Filename]:=GroupUnit;
          AVLNode:=UnitGroup.Units.FindSuccessor(AVLNode);
        end;
      end;
      GraphGroup:=GraphGroup.NextSelected;
    end;

    // check if something changed
    Graph:=UnitsLvlGraph.Graph;
    HasChanged:=false;
    i:=0;
    AVLNode:=NewUnits.Tree.FindLowest;
    while AVLNode<>nil do begin
      GroupUnit:=TUGGroupUnit(NewUnits.GetNodeData(AVLNode)^.Value);
      if (Graph.NodeCount<=i) or (Graph.Nodes[i].Data<>Pointer(GroupUnit)) then
      begin
        HasChanged:=true;
        break;
      end;
      i+=1;
      AVLNode:=NewUnits.Tree.FindSuccessor(AVLNode);
    end;
    if i<Graph.NodeCount then HasChanged:=true;
    if not HasChanged then exit;

    // units changed -> update level graph of units
    UnitsLvlGraph.BeginUpdate;
    Graph.Clear;
    AVLNode:=NewUnits.Tree.FindLowest;
    while AVLNode<>nil do begin
      GroupUnit:=TUGGroupUnit(NewUnits.GetNodeData(AVLNode)^.Value);
      SourceGraphNode:=Graph.GetNode(UnitToCaption(GroupUnit),true);
      SourceGraphNode.Data:=GroupUnit;
      if GroupUnit.UsesUnits<>nil then begin
        for i:=0 to GroupUnit.UsesUnits.Count-1 do begin
          CurUses:=TUGUses(GroupUnit.UsesUnits[i]);
          UsedUnit:=TUGGroupUnit(CurUses.UsesUnit);
          if UsedUnit.Group=nil then continue;
          if not NewGroups.Contains(UsedUnit.Group.Name) then continue;
          TargetGraphNode:=Graph.GetNode(UnitToCaption(UsedUnit),true);
          TargetGraphNode.Data:=UsedUnit;
          Graph.GetEdge(SourceGraphNode,TargetGraphNode,true);
        end;
      end;
      AVLNode:=NewUnits.Tree.FindSuccessor(AVLNode);
    end;

    UnitsLvlGraph.EndUpdate;
  finally
    NewGroups.Free;
    NewUnits.Free;
  end;
end;

procedure TUnitDependenciesWindow.CreateTVNodes(TV: TTreeView;
  ParentTVNode: TTreeNode; ParentUDNode: TUDNode; Expand: boolean);
var
  AVLNode: TAVLTreeNode;
  UDNode: TUDNode;
  TVNode: TTreeNode;
begin
  if ParentUDNode=nil then exit;
  AVLNode:=ParentUDNode.ChildNodes.FindLowest;
  while AVLNode<>nil do begin
    UDNode:=TUDNode(AVLNode.Data);
    TVNode:=TV.Items.AddChild(ParentTVNode,UDNode.NodeText);
    UDNode.TVNode:=TVNode;
    TVNode.Data:=UDNode;
    TVNode.ImageIndex:=GetImgIndex(UDNode);
    TVNode.SelectedIndex:=TVNode.ImageIndex;
    TVNode.HasChildren:=UDNode.HasChildren;
    CreateTVNodes(TV,TVNode,UDNode,Expand);
    TVNode.Expanded:=Expand and (TVNode.Count>0);
    AVLNode:=ParentUDNode.ChildNodes.FindSuccessor(AVLNode);
  end;
end;

procedure TUnitDependenciesWindow.FreeUsesGraph;
begin
  FreeAndNil(FAllUnitsRootUDNode);
  FreeAndNil(FSelUnitsRootUDNode);
  GroupsLvlGraph.Clear;
  UnitsLvlGraph.Clear;
  FreeAndNil(FGroups);
  FreeAndNil(FUsesGraph);
end;

procedure TUnitDependenciesWindow.UpdateAllUnitsTreeView;
var
  TV: TTreeView;
  OldExpanded: TTreeNodeExpandedState;
  SrcEdit: TSourceEditorInterface;
  SelPath: String;
begin
  Exclude(FFlags,udwNeedUpdateAllUnitsTreeView);
  TV:=AllUnitsTreeView;
  TV.BeginUpdate;
  // save old expanded state
  if (TV.Items.Count>1) and (GetAllUnitsFilter(false)='') then
    OldExpanded:=TTreeNodeExpandedState.Create(TV)
  else
    OldExpanded:=nil;
  SelPath:='';
  if TV.Selected<>nil then
    SelPath:=TV.Selected.GetTextPath;
  // clear
  FreeAndNil(FAllUnitsRootUDNode);
  fAllUnitsTVSearchStartNode:=nil;
  TV.Items.Clear;
  // create nodes
  FAllUnitsRootUDNode:=CreateAllUnitsTree;
  CreateTVNodes(TV,nil,FAllUnitsRootUDNode,true);
  // restore old expanded state
  if OldExpanded<>nil then begin
    OldExpanded.Apply(TV);
    OldExpanded.Free;
  end;
  // update search
  UpdateAllUnitsTreeViewSearch;
  // select an unit
  if PendingUnitDependencyRoute.Count>0 then begin
    TV.Selected:=FindUnitTVNodeWithUnitName(TV,PendingUnitDependencyRoute[0]);
  end;
  if (TV.Selected=nil) and (SelPath<>'') then begin
    TV.Selected:=TV.Items.FindNodeWithTextPath(SelPath);
  end;
  if (TV.Selected=nil) then begin
    SrcEdit:=SourceEditorManagerIntf.ActiveEditor;
    if SrcEdit<>nil then
      TV.Selected:=FindUnitTVNodeWithFilename(TV,SrcEdit.FileName);
  end;
  if (TV.Selected=nil) and (LazarusIDE.ActiveProject<>nil)
  and (LazarusIDE.ActiveProject.MainFile<>nil) then
    TV.Selected:=FindUnitTVNodeWithFilename(TV,LazarusIDE.ActiveProject.MainFile.Filename);

  TV.EndUpdate;
end;

procedure TUnitDependenciesWindow.UpdateSelUnitsTreeView;
var
  TV: TTreeView;
begin
  //debugln(['TUnitDependenciesWindow.UpdateSelUnitsTreeView START']);
  Exclude(FFlags,udwNeedUpdateSelUnitsTreeView);
  TV:=SelUnitsTreeView;
  TV.BeginUpdate;
  // clear
  FreeAndNil(FSelUnitsRootUDNode);
  fSelUnitsTVSearchStartNode:=nil;
  TV.Items.Clear;
  // create nodes
  FSelUnitsRootUDNode:=CreateSelUnitsTree;
  CreateTVNodes(TV,nil,FSelUnitsRootUDNode,true);
  // update search
  UpdateSelUnitsTreeViewSearch;
  TV.EndUpdate;
end;

procedure TUnitDependenciesWindow.UpdateAllUnitsTreeViewSearch;
begin
  Exclude(FFlags,udwNeedUpdateAllUnitsTVSearch);
  SelectNextSearchTV(AllUnitsTreeView,fAllUnitsTVSearchStartNode,true,false);
  AllUnitsTreeView.Invalidate;
end;

procedure TUnitDependenciesWindow.UpdateSelUnitsTreeViewSearch;
begin
  Exclude(FFlags,udwNeedUpdateSelUnitsTVSearch);
  SelectNextSearchTV(SelUnitsTreeView,fSelUnitsTVSearchStartNode,true,false);
  SelUnitsTreeView.Invalidate;
end;

function TUnitDependenciesWindow.FindNextTVNode(StartNode: TTreeNode;
  LowerSearch: string; SearchNext, SkipStart: boolean): TTreeNode;
begin
  Result:=StartNode;
  while Result<>nil do begin
    if ((Result<>StartNode) or (not SkipStart))
    and NodeTextFitsFilter(Result.Text,LowerSearch) then
      exit;
    if SearchNext then
      Result:=Result.GetNext
    else
      Result:=Result.GetPrev;
  end;
end;

function TUnitDependenciesWindow.FindUnitTVNodeWithFilename(TV: TTreeView;
  aFilename: string): TTreeNode;
var
  i: Integer;
  UDNode: TUDNode;
begin
  for i:=0 to TV.Items.Count-1 do begin
    Result:=TV.Items[i];
    if TObject(Result.Data) is TUDNode then begin
      UDNode:=TUDNode(Result.Data);
      if (UDNode.Typ in [udnDirectory,udnUnit])
      and (CompareFilenames(UDNode.Identifier,aFilename)=0) then
        exit;
    end;
  end;
  Result:=nil;
end;

function TUnitDependenciesWindow.FindUnitTVNodeWithUnitName(TV: TTreeView;
  aUnitName: string): TTreeNode;
var
  i: Integer;
  UDNode: TUDNode;
begin
  for i:=0 to TV.Items.Count-1 do begin
    Result:=TV.Items[i];
    if TObject(Result.Data) is TUDNode then begin
      UDNode:=TUDNode(Result.Data);
      if (UDNode.Typ in [udnUnit])
      and (CompareText(ExtractFileNameOnly(UDNode.Identifier),aUnitName)=0) then
        exit;
    end;
  end;
  Result:=nil;
end;

function TUnitDependenciesWindow.GetImgIndex(Node: TUDNode): integer;
begin
  case Node.Typ of
  //udnNone: ;
  udnGroup:
    if IsProjectGroup(Node.Group) then
      Result:=fImgIndexProject
    else
      Result:=fImgIndexPackage;
  udnDirectory: Result:=fImgIndexDirectory;
  //udnInterface: ;
  //udnImplementation: ;
  //udnUsedByInterface: ;
  //udnUsedByImplementation: ;
  udnUnit: Result:=fImgIndexUnit;
  else
    Result:=fImgIndexDirectory;
  end;
end;

function TUnitDependenciesWindow.NodeTextToUnit(NodeText: string): TUGUnit;
var
  AVLNode: TAVLTreeNode;
begin
  AVLNode:=UsesGraph.FilesTree.FindLowest;
  while AVLNode<>nil do begin
    Result:=TUGUnit(AVLNode.Data);
    if NodeText=UGUnitToNodeText(Result) then exit;
    AVLNode:=UsesGraph.FilesTree.FindSuccessor(AVLNode);
  end;
  Result:=nil;
end;

function TUnitDependenciesWindow.UGUnitToNodeText(UGUnit: TUGUnit): string;
begin
  Result:=ExtractFileName(UGUnit.Filename);
end;

function TUnitDependenciesWindow.GetFPCSrcDir: string;
var
  UnitSet: TFPCUnitSetCache;
begin
  UnitSet:=CodeToolBoss.GetUnitSetForDirectory('');
  Result:=UnitSet.FPCSourceDirectory;
end;

function TUnitDependenciesWindow.IsFPCSrcGroup(Group: TUGGroup): boolean;
begin
  Result:=(Group<>nil) and (LeftStr(Group.Name,length(GroupPrefixFPCSrc))=GroupPrefixFPCSrc);
end;

function TUnitDependenciesWindow.IsProjectGroup(Group: TUGGroup): boolean;
begin
  Result:=(Group<>nil) and IsProjectGroup(Group.Name);
end;

function TUnitDependenciesWindow.IsProjectGroup(GroupName: string): boolean;
begin
  Result:=(GroupName=GroupPrefixProject);
end;

function TUnitDependenciesWindow.GetFilename(UDNode: TUDNode): string;
var
  Pkg: TIDEPackage;
begin
  Result:='';
  if UDNode.Typ in [udnUnit,udnDirectory] then
    Result:=UDNode.Identifier
  else if UDNode.Typ=udnGroup then begin
    if IsProjectGroup(UDNode.Group) then begin
      if (LazarusIDE.ActiveProject<>nil) then
        Result:=LazarusIDE.ActiveProject.ProjectInfoFile;
    end else begin
      Pkg:=PackageEditingInterface.FindPackageWithName(UDNode.Group);
      if Pkg<>nil then
        Result:=Pkg.Filename;
    end;
  end;
end;

function TUnitDependenciesWindow.GetAllUnitsFilter(Lower: boolean): string;
begin
  Result:=AllUnitsFilterEdit.Text;
  if Result=ResStrFilter then
    Result:=''
  else if Lower then
    Result:=UTF8LowerCase(Result);
end;

function TUnitDependenciesWindow.GetAllUnitsSearch(Lower: boolean): string;
begin
  Result:=AllUnitsSearchEdit.Text;
  if Result=ResStrSearch then
    Result:=''
  else if Lower then
    Result:=UTF8LowerCase(Result);
end;

function TUnitDependenciesWindow.GetSelUnitsSearch(Lower: boolean): string;
begin
  Result:=SelUnitsSearchEdit.Text;
  if Result=ResStrSearch then
    Result:=''
  else if Lower then
    Result:=UTF8LowerCase(Result);
end;

function TUnitDependenciesWindow.ResStrFilter: string;
begin
  Result:=lisUDFilter;
end;

function TUnitDependenciesWindow.ResStrSearch: string;
begin
  Result:=lisUDSearch;
end;

function TUnitDependenciesWindow.NodeTextFitsFilter(const NodeText,
  LowerFilter: string): boolean;
begin
  Result:=Pos(LowerFilter,UTF8LowerCase(NodeText))>0;
end;

procedure TUnitDependenciesWindow.CreateUsesGraph(out TheUsesGraph: TUsesGraph;
  out TheGroups: TUGGroups);
begin
  TheUsesGraph:=CodeToolBoss.CreateUsesGraph;
  TheUsesGraph.UnitClass:=TUDUnit;
  TheUsesGraph.UsesClass:=TUDUses;
  TheGroups:=TUGGroups.Create(TheUsesGraph);
end;

{$R *.lfm}

end.

