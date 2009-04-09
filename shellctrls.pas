{
 /***************************************************************************
                                   ShellCtrls.pas
                                   ------------


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit ShellCtrls;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Graphics,
  ComCtrls;

type

  { TObjectTypes }

  TObjectType = (otFolders, otNonFolders, otHidden);

  TObjectTypes = set of TObjectType;

  { Forward declaration of the classes }

  TCustomShellTreeView = class;
  TCustomShellListView = class;

  { TCustomShellTreeView }

  TCustomShellTreeView = class(TCustomTreeView)
  private
    FObjectTypes: TObjectTypes;
    FShellListView: TCustomShellListView;
    { Setters and getters }
    procedure SetShellListView(const Value: TCustomShellListView);
    { Other internal methods }
    procedure HandleOnExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
  protected
  public
    { Basic methods }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Methods specific to Lazarus }
    class procedure GetFilesInDir(const ABaseDir: string;
      AObjectTypes: TObjectTypes; AResult: TStrings);
    function PopulateTreeNodeWithFiles(
      ANode: TTreeNode; ANodePath: string): Boolean;
    procedure PopulateWithBaseFiles;
    function GetPathFromNode(ANode: TTreeNode): string;

    { Properties }
    property ObjectTypes: TObjectTypes read FObjectTypes write FObjectTypes;
    property ShellListView: TCustomShellListView read FShellListView write SetShellListView;
  end;

  { TShellTreeView }

  TShellTreeView = class(TCustomShellTreeView)
  published
    { TCustomTreeView properties }
    property Align;
    property Anchors;
    property AutoExpand;
    property BorderSpacing;
    //property BiDiMode;
    property BackgroundColor;
    property BorderStyle;
    property BorderWidth;
    property Color;
    property Constraints;
    property Enabled;
    property ExpandSignType;
    property Font;
    //property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property RightClickSelect;
    property RowSelect;
    property ScrollBars;
    property SelectionColor;
    property ShowButtons;
    property ShowHint;
    property ShowLines;
    property ShowRoot;
    property TabOrder;
    property TabStop default True;
    property Tag;
    property ToolTips;
    property Visible;
    property OnChange;
    property OnChanging;
    property OnClick;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnSelectionChanged;
    property OnShowHint;
    property OnUTF8KeyPress;
    property Options;
    property TreeLineColor;
    property TreeLinePenStyle;
    property ExpandSignColor;
    { TCustomShellTreeView properties }
    property ObjectTypes;
    property ShellListView;
  end;

  { TCustomShellListView }

  TCustomShellListView = class(TCustomListView)
  private
    FObjectTypes: TObjectTypes;
    FRoot: string;
    FShellTreeView: TCustomShellTreeView;
    { Setters and getters }
    procedure SetShellTreeView(const Value: TCustomShellTreeView);
    { Other internal methods }
  protected
  public
    { Basic methods }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Methods specific to Lazarus }
    procedure PopulateWithRoot();
//    function GetPathFromNode(ANode: TTreeNode): string;

    { Properties }
    property ObjectTypes: TObjectTypes read FObjectTypes write FObjectTypes;
    property Root: string read FRoot write FRoot;
    property ShellTreeView: TCustomShellTreeView read FShellTreeView write SetShellTreeView;
  end;

  { TShellListView }

  TShellListView = class(TCustomShellListView)
  published
    { TCustomListView properties
      The same as TListView excluding data properties }
    property Align;
    property Anchors;
    property BorderSpacing;
    property BorderStyle;
    property BorderWidth;
//    property Checkboxes;
    property Color default clWindow;
//    property Columns;
//    property ColumnClick;
    property Constraints;
    property DragCursor;
    property DragMode;
//    property DefaultItemHeight;
//    property DropTarget;
    property Enabled;
//    property FlatScrollBars;
    property Font;
//    property FullDrag;
//    property GridLines;
    property HideSelection;
//    property HotTrack;
//    property HotTrackStyles;
//    property HoverTime;
//    property Items;
    property LargeImages;
    property MultiSelect;
//    property OwnerData;
//    property OwnerDraw;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property RowSelect;
    property ScrollBars;
    property ShowColumnHeaders;
    property ShowHint;
//    property ShowWorkAreas;
    property SmallImages;
    property SortColumn;
    property SortType;
    property StateImages;
    property TabStop;
    property TabOrder;
    property ToolTips;
    property Visible;
    property ViewStyle;
//    property OnAdvancedCustomDraw;
//    property OnAdvancedCustomDrawItem;
//    property OnAdvancedCustomDrawSubItem;
    property OnChange;
    property OnClick;
    property OnColumnClick;
    property OnCompare;
    property OnContextPopup;
//    property OnCustomDraw;
//    property OnCustomDrawItem;
//    property OnCustomDrawSubItem;
    property OnDblClick;
    property OnDeletion;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnSelectItem;
    property OnStartDrag;
    property OnUTF8KeyPress;
    { TCustomShellListView properties }
    property ObjectTypes;
    property Root;
    property ShellTreeView;
  end;

procedure Register;

implementation

{$ifdef windows}
uses Windows;
{$endif}

{
uses ShlObj;

//  $I shellctrlswin32.inc

procedure PopulateTreeViewWithShell(ATreeView: TCustomShellTreeView);
var
  ShellFolder: IShellFolder = nil;
  Win32ObjectTypes: Integer;
//  pidl: LPITEMIDLIST;
  pidlParent: LPITEMIDLIST;
begin
  SHGetSpecialFolderLocation(0, CSIDL_DESKTOP, @pidl);

  SHGetDesktopFolder(ShellFolder);

  if ShellFolder = nil then Exit;

  // Converts the control data into Windows constants

  Win32ObjectTypes := 0;

  if otFolders in ATreeView.ObjectTypes then
    Win32ObjectTypes := Win32ObjectTypes or SHCONTF_FOLDERS;

  if otNonFolders in ATreeView.ObjectTypes then
    Win32ObjectTypes := Win32ObjectTypes or SHCONTF_NONFOLDERS;

  if otHidden in ATreeView.ObjectTypes then
    Win32ObjectTypes := Win32ObjectTypes or SHCONTF_INCLUDEHIDDEN;

  // Now gets the name of the desktop folder
}

{ TCustomShellTreeView }

procedure TCustomShellTreeView.SetShellListView(
  const Value: TCustomShellListView);
begin
  FShellListView := Value;

  // Update the pair, it will then update itself
  // in the setter of this property
  // Updates only if necessary to avoid circular calls of the setters
  if Value.ShellTreeView <> Self then
    Value.ShellTreeView := Self;
end;

procedure TCustomShellTreeView.HandleOnExpanding(Sender: TObject;
  Node: TTreeNode; var AllowExpansion: Boolean);
begin
  Node.DeleteChildren;
  AllowExpansion := PopulateTreeNodeWithFiles(Node, GetPathFromNode(Node));
end;

constructor TCustomShellTreeView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // Initial property values

  ObjectTypes:= [otFolders];

  // Necessary event handlers

  OnExpanding := @HandleOnExpanding;

  // Populates the base dirs

  PopulateWithBaseFiles();
end;

destructor TCustomShellTreeView.Destroy;
begin
  inherited Destroy;
end;

{ Helper routine.
  Finds all files/directories directly inside a directory.
  Does not recurse inside subdirectories. }
class procedure TCustomShellTreeView.GetFilesInDir(const ABaseDir: string;
  AObjectTypes: TObjectTypes; AResult: TStrings);
var
  DirInfo: TSearchRec;
  FindResult: Integer;
  IsDirectory, IsValidDirectory, IsHidden, AddFile: Boolean;
  ObjectData: TObject;
  SearchStr: string;
begin
  SearchStr := IncludeTrailingPathDelimiter(ABaseDir) + '*.*';

  FindResult := FindFirst(SearchStr, FaDirectory, DirInfo);

  while FindResult = 0 do
  begin
    Application.ProcessMessages;

    IsDirectory := (DirInfo.Attr and FaDirectory = FaDirectory);

    IsValidDirectory := (DirInfo.Name <> '.') and (DirInfo.Name <> '..');

    IsHidden := (DirInfo.Attr and faHidden = faHidden);

    // First check if we show hidden files
    if IsHidden then AddFile := (otHidden in AObjectTypes)
    else AddFile := True;

    // If it is a directory, check if it is a valid one
    if IsDirectory then
      AddFile := AddFile and ((otFolders in AObjectTypes) and IsValidDirectory)
    else
      AddFile := AddFile and (otNonFolders in AObjectTypes);

    // Mark if it is a directory (ObjectData <> nil)
    if IsDirectory then ObjectData := AResult
    else ObjectData := nil;

    // AddFile identifies if the file is valid or not
    if AddFile then AResult.AddObject(DirInfo.Name, ObjectData);

    FindResult := FindNext(DirInfo);
  end;

  SysUtils.FindClose(DirInfo);
end;

{ Returns true if at least one item was added, false otherwise }
function TCustomShellTreeView.PopulateTreeNodeWithFiles(
  ANode: TTreeNode; ANodePath: string): Boolean;
var
  i: Integer;
  Files: TStringList;
  NewNode: TTreeNode;
begin
  Files := TStringList.Create;
  try
    GetFilesInDir(ANodePath, FObjectTypes, Files);

    Result := Files.Count > 0;

    for i := 0 to Files.Count - 1 do
    begin
      NewNode := Items.AddChildObject(ANode, Files.Strings[i], nil); //@Files.Strings[i]);
      NewNode.HasChildren := Files.Objects[i] <> nil; // This marks if the node is a directory
    end;
  finally
    Files.Free;
  end;
end;

procedure TCustomShellTreeView.PopulateWithBaseFiles;
  {$if defined(windows) and not defined(wince)}
const
  DRIVE_UNKNOWN = 0;
  DRIVE_NO_ROOT_DIR = 1;
  DRIVE_REMOVABLE = 2;
  DRIVE_FIXED = 3;
  DRIVE_REMOTE = 4;
  DRIVE_CDROM = 5;
  DRIVE_RAMDISK = 6;
var
  r: LongWord;
  Drives: array[0..128] of char;
  pDrive: PChar;
  NewNode: TTreeNode;
begin
  r := GetLogicalDriveStrings(SizeOf(Drives), Drives);
  if r = 0 then Exit;
  if r > SizeOf(Drives) then Exit;
//    raise Exception.Create(SysErrorMessage(ERROR_OUTOFMEMORY));

  pDrive := Drives;
  while pDrive^ <> #0 do
  begin
//    r := GetDriveType(pDrive);

    NewNode := Items.AddChildObject(nil, pDrive, pDrive);
    NewNode.HasChildren := True;

    Inc(pDrive, 4);
  end;
end;
  {$endif}
  {$ifdef wince}
begin
  PopulateTreeNodeWithFiles(nil, '\');
end;
  {$endif}
  {$ifdef unix}
begin
  PopulateTreeNodeWithFiles(nil, '/');
end;
  {$endif}

function TCustomShellTreeView.GetPathFromNode(ANode: TTreeNode): string;
var
  rootDir : String;
begin
  // In the future use ANode.Data instead of ANode.Text
  rootDir := PChar(ANode.Text);
  while (ANode.Parent <> nil)do
  begin
    ANode := ANode.Parent;
    if( pChar(ANode.Text) <> PathDelim)then
      rootDir := PChar(ANode.Text)+PathDelim+rootDir
    else
      rootDir := PChar(ANode.Text)+rootDir;
  end;
  result:=rootDir;
end;

{ TCustomShellListView }

procedure TCustomShellListView.SetShellTreeView(
  const Value: TCustomShellTreeView);
begin
  FShellTreeView := Value;

{  if Value.Selected <> nil then
  begin
    FRoot := Value.GetPathFromNode(Value.Selected);
    Clear();
    PopulateWithRoot();
  end
  else
  begin
    Clear();
  end;

  // Also update the pair, but only if necessary to avoid circular calls of the setters
  if Value.ShellListView <> Self then
    Value.ShellListView := Self;}
end;

constructor TCustomShellListView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // Initial property values

  ObjectTypes:= [otNonFolders];

  Self.Columns.Add;
  Self.Column[0].Caption := 'Name';
  Self.Columns.Add;
  Self.Column[1].Caption := 'Size';
  Self.Columns.Add;
  Self.Column[2].Caption := 'Type';
end;

destructor TCustomShellListView.Destroy;
begin

  inherited Destroy;
end;

procedure TCustomShellListView.PopulateWithRoot();
{var
  i: Integer;
  Files: TStringList;
  NewItem: TListItem;
}
begin
{  Files := TStringList.Create;
  try
    TCustomShellTreeView.GetFilesInDir(FRoot, FObjectTypes, Files);

    for i := 0 to Files.Count - 1 do
    begin
      NewItem := Items.Add;
      NewItem.Caption := Files.Strings[i];
    end;
  finally
    Files.Free;
  end;}
end;

procedure Register;
begin
  RegisterComponents('Misc',[TShellTreeView, TShellListView]);
end;

end.
