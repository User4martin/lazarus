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

  Author: Ondrej Pokorny

  Abstract:
    Replacement of source editor tabs/pages with buttons sorted by package and name.
}
unit packagetabs_impl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Contnrs, Controls, SrcEditorIntf, StdCtrls, Buttons,
  ComCtrls, Forms, LazFileUtils, PackageIntf, Graphics, Menus, LazIDEIntf,
  ExtCtrls, IDEImagesIntf, LMessages, Math, Laz2_XMLCfg, IDECommands, LCLIntf,
  IDEOptionsIntf;

type
  TPackageTabButton = class(TSpeedButton)
  public
    Editor: TSourceEditorInterface;
    IsOtherFile: Boolean;
  protected
    procedure CalculatePreferredSize(var PreferredWidth,
      PreferredHeight: integer; WithThemeSpace: Boolean); override;
  public
    constructor Create(aOwner: TComponent); override;
  end;

  TPackageTabLabel = class(TLabel)
  private
    FLeftClickPopupBlock: QWord;
  public
    Package: TIDEPackage;
  protected
    procedure CalculatePreferredSize(var PreferredWidth,
      PreferredHeight: integer; WithThemeSpace: Boolean); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
  public
    constructor Create(aOwner: TComponent); override;
  end;

  TPackageTabScrollBox = class(TScrollBox)
  protected
    procedure WMMouseWheel(var Message: TLMMouseEvent); message LM_MOUSEWHEEL;
    procedure DoAlignControls;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TPackageTabFlowPanel = class(TFlowPanel)
  public
    constructor Create(aOwner: TComponent); override;
  end;

  TPackageItem = class
  public
    Package: TIDEPackage;
    Files: TStringList;

    constructor Create(APackage: TIDEPackage);
    destructor Destroy; override;
  end;

  TMenuItemCommand = class(TMenuItem)
  public
    IDECommand: Word;
    NeedsActiveEditor: Boolean;
  end;

  TMenuItemWindow = class(TMenuItem)
  public
    WindowIndex: Integer;
  end;

  TRecreateToolBarStamps = class
  private
    FCurProjectChangeStamp: Int64;
    FPackagesChangeStamp: Int64;
    FInternalChangeStamp: Int64;
    FLastInternalChangeStamp: Int64;
    FLastFiles: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
  public
    function Changed: Boolean;
    function PanelChanged(AWindow: TSourceEditorWindowInterface): Boolean;

    procedure IncInternalStamp;
  end;

  TPackageTabPanel = class(TComponent)
  private
    FTabPosition: TTabPosition;
    FPanel: TWinControl;
    FSplitter: TSplitter;
    FWindow: TSourceEditorWindowInterface;
    FNoteBook: TPageControl;
    FRecreateToolBar: TRecreateToolBarStamps;
    FSetActiveEditor: Boolean;
    FAppIdleLocked: Boolean;
    FTabLabelMenu: TPopupMenu;
    FTabLabelMenuCloseAllGroup: TMenuItem;
    FTabLabelMenuPkgSep: TMenuItem;
    FTabLabelMenuOpenPackage: TMenuItem;
    FTabButtonMenu: TPopupMenu;
    FTabButtonMenuClose: TMenuItem;
    FTabButtonMenuLock: TMenuItemCommand;
    FTabButtonMenuProjSep: TMenuItem;
    FTabButtonMenuAddToProject: TMenuItem;
    FTabButtonMenuMoveCloneSep: TMenuItem;
    FTabButtonMenuMoveTo: TMenuItem;
    FTabButtonMenuCloneTo: TMenuItem;
    FTabButtonMenuFindIn: TMenuItem;
    FTabButtonMenuMoveToNew: TMenuItemCommand;
    FTabButtonMenuCloneToNew: TMenuItemCommand;

    procedure RecreatePanel;
    procedure DoEditorPageUpdated(Sender: TObject);
    procedure RecreateToolBar;
    procedure SetActiveEditor;
    procedure AppOnIdle(Sender: TObject; var {%H-}Done: Boolean);
    function FindEditorInWindow(AEditor: TSourceEditorInterface): Integer;

    procedure EditorActivated;
    procedure EditorCreated;
    procedure EditorDestroyed;

    procedure LoadConfig(ACfg: TXMLConfig; APath: string);
    procedure SaveConfig(ACfg: TXMLConfig; APath: string);

    procedure TabButtonMenuAddToProjectClick(Sender: TObject);
    procedure MenuItemCommandClick(Sender: TObject);
    procedure TabButtonMenuCloneToClick(Sender: TObject);
    procedure TabButtonMenuCloseClick(Sender: TObject);
    procedure TabButtonMenuMoveToClick(Sender: TObject);
    procedure TabButtonMenuFindInClick(Sender: TObject);
    procedure TabButtonMenuPopup(Sender: TObject);
    procedure TabButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
    procedure TabLabelCloseAllGroupClick(Sender: TObject);
    procedure TabLabelMenuOpenPackageClick(Sender: TObject);
    procedure TabLabelMenuPopup(Sender: TObject);
  public
    constructor Create(AParentWindow: TSourceEditorWindowInterface); reintroduce;
    destructor Destroy; override;
  end;

  TPackageTabPanels = class(TComponent)
  private
    FTabPanels: TObjectList;
    FConfig: TXMLConfig;
    function GetTabPanel(Index: Integer): TPackageTabPanel;
    function GetTabPanelCount: Integer;
    procedure EditorActivated(Sender: TObject);
    procedure EditorCreated(Sender: TObject);
    procedure EditorDestroyed(Sender: TObject);
    procedure WindowCreated(Sender: TObject);
    procedure WindowDestroyed(Sender: TObject);
  public
    property TabPanels[Index: Integer]: TPackageTabPanel read GetTabPanel;
    property TabPanelCount: Integer read GetTabPanelCount;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TSourceEditorWindowInterfaceHelper = class helper for TSourceEditorWindowInterface
  public
    function GetNotebook: TPageControl;
    function FindSourceEditorWithPageIndex(APageIndex:integer;
      ANoteBook: TPageControl): TSourceEditorInterface;
    function FindPageWithEditor(ASourceEditor: TSourceEditorInterface;
      ANoteBook: TPageControl):integer;
  end;

procedure Register;

implementation

var
  xPackageTabPanels: TPackageTabPanels = nil;

procedure Register;
begin
  xPackageTabPanels := TPackageTabPanels.Create(nil);
end;

{ TSourceEditorWindowInterfaceHelper }

function TSourceEditorWindowInterfaceHelper.FindPageWithEditor(
  ASourceEditor: TSourceEditorInterface; ANoteBook: TPageControl): integer;
var
  LParent: TWinControl;
  LTabSheet: TWinControl;
begin
  if (ASourceEditor.EditorControl.Parent is TTabSheet) then
  begin
    LParent := ASourceEditor.EditorControl.Parent.Parent;
    LTabSheet := ASourceEditor.EditorControl.Parent;
    while (LParent <> ANoteBook) and (LParent <> nil) do
    begin
      LTabSheet := LParent;
      LParent := LParent.Parent;
    end;

    if (LParent <> nil) and (LTabSheet is TTabSheet) then
      Result:=TTabSheet(LTabSheet).PageIndex
    else
      Result:=-1;
  end
  else
    Result:=-1;
end;

function TSourceEditorWindowInterfaceHelper.FindSourceEditorWithPageIndex(
  APageIndex: integer; ANoteBook: TPageControl): TSourceEditorInterface;

var
  I: integer;
  xPage: TCustomPage;
begin
  Result := nil;
  if (APageIndex < 0) or (APageIndex >= ANoteBook.PageCount) then exit;

  xPage := ANoteBook.Page[APageIndex];

  for I := 0 to Count-1 do
  begin
    Result := Items[I];

    if xPage.IsParentOf(Result.EditorControl) then
      Exit;
  end;

  Result := nil;
end;

function TSourceEditorWindowInterfaceHelper.GetNotebook: TPageControl;
  function _Find(AParent: TWinControl): TPageControl;
  var
    I: Integer;
  begin
    for I := 0 to AParent.ControlCount-1 do
    begin
      if AParent.Controls[I] is TPageControl then
        Exit(TPageControl(Controls[I]));
    end;

    for I := 0 to AParent.ControlCount-1 do
      if AParent.Controls[I] is TWinControl then
      begin
        Result := _Find(TWinControl(Controls[I]));
        if Result <> nil then
          Exit;
      end;

    Result := nil;
  end;
begin
  Result := _Find(Self);
end;

{ TRecreateToolBarStamps }

constructor TRecreateToolBarStamps.Create;
begin
  FLastFiles := TStringList.Create;
end;

function TRecreateToolBarStamps.Changed: Boolean;
begin
  Result := not(
        (LazarusIDE.ActiveProject <> nil)
    and (FCurProjectChangeStamp = LazarusIDE.ActiveProject.ChangeStamp)
    and (FPackagesChangeStamp = PackageGraphInterface.ChangeStamp)
    and (FInternalChangeStamp = FLastInternalChangeStamp)
    );

  if not Result then Exit;

  FCurProjectChangeStamp := LazarusIDE.ActiveProject.ChangeStamp;
  FPackagesChangeStamp := PackageGraphInterface.ChangeStamp;
  FLastInternalChangeStamp := FInternalChangeStamp;
end;

destructor TRecreateToolBarStamps.Destroy;
begin
  FLastFiles.Free;
  inherited Destroy;
end;

procedure TRecreateToolBarStamps.IncInternalStamp;
begin
  {$push}{$R-}  // range check off
  Inc(FInternalChangeStamp);
  {$pop}
end;

function TRecreateToolBarStamps.PanelChanged(
  AWindow: TSourceEditorWindowInterface): Boolean;
var
  I: Integer;
begin
  if AWindow.Count <> FLastFiles.Count then
    Exit(True);

  for I := 0 to AWindow.Count-1 do
    if AWindow[I].FileName <> FLastFiles[I] then
      Exit(True);

  Result := False;
end;

{ TPackageTabFlowPanel }

constructor TPackageTabFlowPanel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  BevelInner := bvNone;
  BevelOuter := bvNone;
end;

{ TPackageTabScrollBox }

constructor TPackageTabScrollBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  BorderStyle := bsNone;
  HorzScrollBar.Smooth := False;
  VertScrollBar.Smooth := False;
  HorzScrollBar.Tracking := True;
  VertScrollBar.Tracking := True;
  HorzScrollBar.Increment := TPackageTabButton.GetControlClassDefaultSize.cy;
  VertScrollBar.Increment := TPackageTabButton.GetControlClassDefaultSize.cy;
  HorzScrollBar.Visible := False;
end;

procedure TPackageTabScrollBox.DoAlignControls;
var
  xNextY, I: Integer;
  xControl: TControl;
  xClientRect: TRect;
  xBS: TControlBorderSpacing;
begin
  xClientRect := GetClientRect;
  AdjustClientRect(xClientRect);
  DisableAlign;
  try
    xNextY := 0;
    for I := 0 to ControlCount-1 do
    begin
      xControl := Controls[I];

      xControl.Anchors := [akLeft, akRight, akTop];
      xBS := xControl.BorderSpacing;
      xControl.SetBounds(
        xBS.Left+xBS.Around, xNextY+xBS.Top+xBS.Around,
        xClientRect.Right-xClientRect.Left-xBS.Left-xBS.Right-xBS.Around*2,
        xBS.ControlHeight);
      Inc(xNextY, xControl.Height);
    end;
  finally
    EnableAlign;
  end;
end;

procedure TPackageTabScrollBox.WMMouseWheel(var Message: TLMMouseEvent);
begin
  if Mouse.WheelScrollLines > 0 then
  begin
    Message.WheelDelta := (Min(High(Message.WheelDelta), Max(Low(Message.WheelDelta), (VertScrollBar.Increment * Message.WheelDelta))) div 120) * 120;
  end;

  inherited WMMouseWheel(Message);
end;

{ TPackageTabButton }

constructor TPackageTabButton.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  Transparent := True;
  Flat := True;
  AutoSize := True;
  GroupIndex := 1;
  AllowAllUp := False;
end;

procedure TPackageTabButton.CalculatePreferredSize(var PreferredWidth,
  PreferredHeight: integer; WithThemeSpace: Boolean);
begin
  inherited CalculatePreferredSize(PreferredWidth, PreferredHeight,
    WithThemeSpace);

  PreferredHeight := Height; // ignore PreferredHeight
  PreferredWidth := PreferredWidth + 6;
end;

{ TPackageTabLabel }

constructor TPackageTabLabel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  AutoSize := True;
  Font.Style := Font.Style + [fsBold];
  Layout := tlCenter;
  Alignment := taCenter;
  Cursor := crHandPoint;
end;

procedure TPackageTabLabel.CalculatePreferredSize(var PreferredWidth,
  PreferredHeight: integer; WithThemeSpace: Boolean);
begin
  inherited CalculatePreferredSize(PreferredWidth, PreferredHeight,
    WithThemeSpace);

  PreferredHeight := Height; // ignore PreferredHeight
  PreferredWidth := PreferredWidth + 8;
end;

procedure TPackageTabLabel.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  xPt: Types.TPoint;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if (Button = mbLeft) and (GetTickCount64 > FLeftClickPopupBlock) then
  begin
    xPt := ClientToScreen(Point(0, Height));
    PopupMenu.PopupComponent := Self;
    PopupMenu.PopUp(xPt.X, xPt.Y);
    FLeftClickPopupBlock := GetTickCount64 + 10;
  end;
end;

procedure TPackageTabLabel.MouseEnter;
begin
  inherited MouseEnter;

  Font.Style := Font.Style + [fsUnderline];
end;

procedure TPackageTabLabel.MouseLeave;
begin
  inherited MouseLeave;

  Font.Style := Font.Style - [fsUnderline];
end;

{ TPackageItem }

constructor TPackageItem.Create(APackage: TIDEPackage);
begin
  Package := APackage;
  Files := TStringList.Create;
  Files.Sorted := True;
  Files.Duplicates := dupAccept;
end;

destructor TPackageItem.Destroy;
begin
  Files.Free;
  inherited Destroy;
end;

{ TPackageTabPanel }

constructor TPackageTabPanel.Create(AParentWindow: TSourceEditorWindowInterface
  );
begin
  inherited Create(nil);

  FWindow := AParentWindow;
  FNoteBook := FWindow.GetNotebook;

  FTabPosition := IDEEditorOptions.TabPosition;
  FRecreateToolBar := TRecreateToolBarStamps.Create;

  FWindow.AddUpdateEditorPageCaptionHandler(@DoEditorPageUpdated);

  RecreatePanel;

  FTabLabelMenu := TPopupMenu.Create(Self);
  FTabLabelMenu.Images := IDEImages.Images_16;
  FTabLabelMenu.OnPopup := @TabLabelMenuPopup;
  FTabLabelMenuCloseAllGroup := TMenuItem.Create(Self);
  FTabLabelMenuCloseAllGroup.Caption := 'Close all'; // ToDo: localize
  FTabLabelMenuCloseAllGroup.OnClick := @TabLabelCloseAllGroupClick;
  FTabLabelMenuCloseAllGroup.ImageIndex := IDEImages.LoadImage(16, 'menu_close_all');
  FTabLabelMenu.Items.Add(FTabLabelMenuCloseAllGroup);
  FTabLabelMenuPkgSep := TMenuItem.Create(Self);
  FTabLabelMenuPkgSep.Caption := '-';
  FTabLabelMenu.Items.Add(FTabLabelMenuPkgSep);
  FTabLabelMenuOpenPackage := TMenuItem.Create(Self);
  FTabLabelMenuOpenPackage.Caption := 'Open package'; // ToDo: localize
  FTabLabelMenuOpenPackage.OnClick := @TabLabelMenuOpenPackageClick;
  FTabLabelMenuOpenPackage.ImageIndex := IDEImages.LoadImage(16, 'pkg_open');
  FTabLabelMenu.Items.Add(FTabLabelMenuOpenPackage);

  FTabButtonMenu := TPopupMenu.Create(Self);
  FTabButtonMenu.Images := IDEImages.Images_16;
  FTabButtonMenu.OnPopup := @TabButtonMenuPopup;
  FTabButtonMenuClose := TMenuItem.Create(Self);
  FTabButtonMenuClose.Caption := 'Close'; // ToDo: localize
  FTabButtonMenuClose.OnClick := @TabButtonMenuCloseClick;
  FTabButtonMenuClose.ImageIndex := IDEImages.LoadImage(16, 'menu_close');
  FTabButtonMenu.Items.Add(FTabButtonMenuClose);
  FTabButtonMenuLock := TMenuItemCommand.Create(Self);
  FTabButtonMenuLock.Caption := 'Lock Editor'; // ToDo: localize
  FTabButtonMenuLock.IDECommand := ecLockEditor;
  FTabButtonMenuLock.OnClick := @MenuItemCommandClick;
  FTabButtonMenu.Items.Add(FTabButtonMenuLock);

  FTabButtonMenuProjSep := TMenuItem.Create(Self);
  FTabButtonMenuProjSep.Caption := '-';
  FTabButtonMenu.Items.Add(FTabButtonMenuProjSep);
  FTabButtonMenuAddToProject := TMenuItem.Create(Self);
  FTabButtonMenuAddToProject.Caption := 'Add to project'; // ToDo: localize
  FTabButtonMenuAddToProject.OnClick := @TabButtonMenuAddToProjectClick;
  FTabButtonMenuAddToProject.ImageIndex := IDEImages.LoadImage(16, 'menu_project_add');
  FTabButtonMenu.Items.Add(FTabButtonMenuAddToProject);

  FTabButtonMenuMoveCloneSep := TMenuItem.Create(Self);
  FTabButtonMenuMoveCloneSep.Caption := '-';
  FTabButtonMenu.Items.Add(FTabButtonMenuMoveCloneSep);
  FTabButtonMenuMoveTo := TMenuItem.Create(Self);
  FTabButtonMenuMoveTo.Caption := 'Move To'; // ToDo: localize
  FTabButtonMenu.Items.Add(FTabButtonMenuMoveTo);
  FTabButtonMenuMoveToNew := TMenuItemCommand.Create(Self);
  FTabButtonMenuMoveToNew.Caption := 'New Window'; // ToDo: localize
  FTabButtonMenuMoveToNew.IDECommand := ecMoveEditorNewWindow;
  FTabButtonMenuMoveToNew.NeedsActiveEditor := True;
  FTabButtonMenuMoveToNew.OnClick := @MenuItemCommandClick;
  FTabButtonMenuMoveTo.Add(FTabButtonMenuMoveToNew);
  FTabButtonMenuCloneTo := TMenuItem.Create(Self);
  FTabButtonMenuCloneTo.Caption := 'Clone To'; // ToDo: localize
  FTabButtonMenu.Items.Add(FTabButtonMenuCloneTo);
  FTabButtonMenuCloneToNew := TMenuItemCommand.Create(Self);
  FTabButtonMenuCloneToNew.Caption := 'New Window'; // ToDo: localize
  FTabButtonMenuCloneToNew.IDECommand := ecCopyEditorNewWindow;
  FTabButtonMenuCloneToNew.NeedsActiveEditor := True;
  FTabButtonMenuCloneToNew.OnClick := @MenuItemCommandClick;
  FTabButtonMenuCloneTo.Add(FTabButtonMenuCloneToNew);
  FTabButtonMenuFindIn := TMenuItem.Create(Self);
  FTabButtonMenuFindIn.Caption := 'Find In Other Window'; // ToDo: localize
  FTabButtonMenu.Items.Add(FTabButtonMenuFindIn);

  Application.AddOnIdleHandler(@AppOnIdle, False);
end;

procedure TPackageTabPanel.AppOnIdle(Sender: TObject; var Done: Boolean);
begin
  if FAppIdleLocked then
    Exit;

  if FTabPosition <> IDEEditorOptions.TabPosition then
  begin
    FTabPosition := IDEEditorOptions.TabPosition;
    RecreatePanel;
  end;

  if FRecreateToolBar.Changed then
    RecreateToolBar
  else if FSetActiveEditor then
    SetActiveEditor;
end;

procedure TPackageTabPanel.RecreatePanel;
const
  cSideToAlign: array[TTabPosition] of TAlign = (alTop, alBottom, alLeft, alRight);
begin
  FreeAndNil(FPanel);
  FreeAndNil(FSplitter);
  if FTabPosition in [tpTop, tpBottom] then
  begin
    FPanel := TPackageTabFlowPanel.Create(Self);
    FPanel.Parent := FWindow;
    FPanel.Align := cSideToAlign[FTabPosition];
    FPanel.AutoSize := True;
  end else
  begin
    FPanel := TPackageTabScrollBox.Create(Self);
    FPanel.Parent := FWindow;
    FPanel.Align := cSideToAlign[FTabPosition];
    FPanel.AutoSize := False;

    FSplitter := TSplitter.Create(Self);
    FSplitter.Parent := FWindow;
    FSplitter.Align := FPanel.Align;
    if FTabPosition = tpLeft then
      FSplitter.Left := FPanel.BoundsRect.Right
    else
      FSplitter.Top := FPanel.BoundsRect.Bottom;
  end;
  FRecreateToolBar.IncInternalStamp;
end;

destructor TPackageTabPanel.Destroy;
begin
  Application.RemoveOnIdleHandler(@AppOnIdle);
  FRecreateToolBar.Free;

  inherited Destroy;
end;

procedure TPackageTabPanel.DoEditorPageUpdated(Sender: TObject);
var
  xEditor: TSourceEditorInterface;
  xBtn: TPackageTabButton;
  I: Integer;
begin
  xEditor := (Sender as TSourceEditorInterface);
  for I := 0 to FPanel.ControlCount-1 do
    if (FPanel.Controls[I] is TPackageTabButton) then
    begin
      xBtn := TPackageTabButton(FPanel.Controls[I]);
      if (xBtn.Editor = xEditor) then
      begin
        xBtn.Caption := xBtn.Editor.PageCaption;
        break;
      end;
    end;
end;

procedure TPackageTabPanel.EditorActivated;
begin
  FSetActiveEditor := True;
end;

procedure TPackageTabPanel.EditorCreated;
begin
  FRecreateToolBar.IncInternalStamp;
end;

procedure TPackageTabPanel.EditorDestroyed;
begin
  FRecreateToolBar.IncInternalStamp;
end;

function TPackageTabPanel.FindEditorInWindow(AEditor: TSourceEditorInterface
  ): Integer;
var
  I: Integer;
begin
  for I := 0 to FWindow.Count-1 do
    if FWindow[I] = AEditor then
      Exit(I);
  Result := -1;
end;

procedure TPackageTabPanel.LoadConfig(ACfg: TXMLConfig; APath: string);
begin
  APath := APath+'Panel'+IntToStr(FWindow.WindowID)+'/';

  if FTabPosition in [tpLeft, tpRight] then
    FPanel.Width := ACfg.GetValue(APath+'Panel.Width', FPanel.Width);
end;

procedure TPackageTabPanel.RecreateToolBar;
var
  I, L, xPkgIndex, xNewIndex, xOldIndex: Integer;
  xBtn, xActBtn: TPackageTabButton;
  xPackages: TStringList;
  xPackage: TIDEPackage;
  xEditor, xOldActive: TSourceEditorInterface;
  xLbl: TPackageTabLabel;
  xPkgItem: TPackageItem;
  xPackageName: string;
begin
  FRecreateToolBar.FLastFiles.Clear;
  FWindow.IncUpdateLock;
  FWindow.DisableAlign;
  try
    xOldActive := FWindow.ActiveEditor;
    for I := FPanel.ControlCount-1 downto 0 do
      FPanel.Controls[I].Free;

    xPackages := TStringList.Create;
    try
      xPackages.Sorted := True;
      xPackages.Duplicates := dupIgnore;
      xPackages.OwnsObjects := True;

      for I := 0 to FWindow.Count-1 do
      begin
        xEditor := FWindow.Items[I];
        FRecreateToolBar.FLastFiles.Add(xEditor.FileName);
        xPackage := nil;
        if xEditor.GetProjectFile.IsPartOfProject then
          xPackageName := Low(Char)+LazarusIDE.ActiveProject.GetTitleOrName // ToDo: better sorting...
        else
        begin
          PackageEditingInterface.GetPackageOfSourceEditor(xPackage, xEditor);
          if (xPackage<>nil) and (xPackage.Name<>'') then
            xPackageName := xPackage.Name
          else
            xPackageName := High(Char)+'Other'; // ToDo: localize, better sorting...
        end;
        xPkgIndex := xPackages.IndexOf(xPackageName);
        if xPkgIndex < 0 then
          xPkgIndex := xPackages.AddObject(xPackageName, TPackageItem.Create(xPackage));
        TPackageItem(xPackages.Objects[xPkgIndex]).Files.AddObject(xEditor.PageCaption, xEditor);
      end;

      xNewIndex := 0;
      for I := 0 to xPackages.Count-1 do
      begin
        xPkgItem := TPackageItem(xPackages.Objects[I]);

        xPackageName := xPackages[I];
        if xPackageName[1] in [Low(Char), High(Char)] then
          Delete(xPackageName, 1, 1);
        xLbl := TPackageTabLabel.Create(Self);
        xLbl.Caption := xPackageName;
        xLbl.Parent := FPanel;
        xLbl.PopupMenu := FTabLabelMenu;
        xLbl.Package := xPkgItem.Package;
        xLbl.Height := TPackageTabButton.GetControlClassDefaultSize.cy;
        if FPanel is TPackageTabScrollBox then
        begin
          xLbl.Alignment := taLeftJustify;
          xLbl.BorderSpacing.Left := 10;
        end
        else if FPanel is TPackageTabFlowPanel then
        begin
          TPackageTabFlowPanel(FPanel).ControlList[TPackageTabFlowPanel(FPanel).ControlList.Count-1].WrapAfter := waAvoid;
        end;
        for L := 0 to xPkgItem.Files.Count-1 do
        begin
          xEditor := TSourceEditorInterface(xPkgItem.Files.Objects[L]);
          if FWindow.FindSourceEditorWithPageIndex(xNewIndex, FNoteBook) <> xEditor then // speed things up - check correct index
          begin
            xOldIndex := FWindow.FindPageWithEditor(xEditor, FNoteBook);
            if (xOldIndex>=0) and (xOldIndex<>xNewIndex) then
              TCustomTabControl(FNotebook).Pages.Move(xOldIndex, xNewIndex);
          end;
          xEditor.UpdateProjectFile; // updates FNewEditorInfo.PageIndex
          Inc(xNewIndex);
          xBtn := TPackageTabButton.Create(Self);
          xBtn.Height := xLbl.Height;
          xBtn.Caption := xEditor.PageCaption;
          xBtn.Hint := xEditor.FileName;
          xBtn.ShowHint := True;
          xBtn.Parent := FPanel;
          xBtn.Editor := xEditor;
          xBtn.OnMouseDown := @TabButtonMouseDown;
          xBtn.PopupMenu := FTabButtonMenu;
          xBtn.Down := xEditor = xOldActive;
          if xBtn.Down then
            xActBtn := xBtn;
          xBtn.IsOtherFile := xPackages[I][1] = High(Char); // ToDo: do it better...
        end;
      end;
    finally
      xPackages.Free;
    end;

    if FPanel is TPackageTabScrollBox then
      TPackageTabScrollBox(FPanel).DoAlignControls;

    if Assigned(xOldActive) and (xOldActive <> FWindow.ActiveEditor) then // the pageorder change could change activeeditor
      FWindow.ActiveEditor := xOldActive;

    if (xActBtn<>nil) and (FPanel is TPackageTabScrollBox) then
      TPackageTabScrollBox(FPanel).ScrollInView(xActBtn);
  finally
    FWindow.EnableAlign;
    FWindow.DecUpdateLock;
  end;

  FRecreateToolBar.Changed; // set changestamps
  FSetActiveEditor := False;
end;

procedure TPackageTabPanel.SaveConfig(ACfg: TXMLConfig; APath: string);
begin
  APath := APath+'Panel'+IntToStr(FWindow.WindowID)+'/';

  if FTabPosition in [tpLeft, tpRight] then
    ACfg.SetValue(APath+'Panel.Width', FPanel.Width)
  else
    ACfg.DeleteValue(APath+'Panel.Width');
end;

procedure TPackageTabPanel.SetActiveEditor;
var
  I: Integer;
  xBtn, xActBtn: TPackageTabButton;
  xActEditor: TSourceEditorInterface;
begin
  if FRecreateToolBar.PanelChanged(FWindow) then
  begin
    RecreateToolBar;
    Exit;
  end;

  xActEditor := FWindow.ActiveEditor;
  xActBtn := nil;

  for I := 0 to FPanel.ControlCount-1 do
    if FPanel.Controls[I] is TPackageTabButton then
    begin
      xBtn := TPackageTabButton(FPanel.Controls[I]);
      xBtn.Down := xBtn.Editor = xActEditor;
      if xBtn.Editor = xActEditor then
        xActBtn := xBtn;
    end;

  if (xActBtn<>nil) and (FPanel is TPackageTabScrollBox) then
    TPackageTabScrollBox(FPanel).ScrollInView(xActBtn);

  FSetActiveEditor := False;
end;

procedure TPackageTabPanel.TabButtonMenuAddToProjectClick(Sender: TObject);
var
  xBtn: TPackageTabButton;
begin
  xBtn := (FTabButtonMenu.PopupComponent as TPackageTabButton);
  LazarusIDE.DoAddUnitToProject(xBtn.Editor);
end;

procedure TPackageTabPanel.TabButtonMenuCloneToClick(Sender: TObject);
var
  xBtn: TPackageTabButton;
  xToWindow: Integer;
begin
  xBtn := (FTabButtonMenu.PopupComponent as TPackageTabButton);
  xToWindow := (Sender as TMenuItemWindow).WindowIndex;
  xBtn.Editor.CopyToWindow(xToWindow);
end;

procedure TPackageTabPanel.MenuItemCommandClick(Sender: TObject);
var
  xBtn: TPackageTabButton;
  xItem: TMenuItemCommand;
  xOldEditor: TSourceEditorInterface;
  I: Integer;
begin
  xBtn := (FTabButtonMenu.PopupComponent as TPackageTabButton);
  xItem := (Sender as TMenuItemCommand);
  xOldEditor := nil;
  if xItem.NeedsActiveEditor then
  begin
    xOldEditor := FWindow.ActiveEditor;
    FWindow.ActiveEditor := xBtn.Editor;
    xBtn.Editor.EditorControl.SetFocus;
  end;
  xBtn.Editor.DoEditorExecuteCommand(xItem.IDECommand);
  if xOldEditor<>nil then
  begin
    for I := 0 to FWindow.Count-1 do
      if FWindow[I] = xOldEditor then
      begin
        FWindow.ActiveEditor := xOldEditor;
        if GetParentForm(xOldEditor.EditorControl) = Screen.ActiveCustomForm then
          xOldEditor.EditorControl.SetFocus;
        break;
      end;
  end;
end;

procedure TPackageTabPanel.TabButtonMenuCloseClick(Sender: TObject);
var
  xBtn: TPackageTabButton;
begin
  xBtn := (FTabButtonMenu.PopupComponent as TPackageTabButton);
  LazarusIDE.DoCloseEditorFile(xBtn.Editor, [cfSaveFirst]);
end;

procedure TPackageTabPanel.TabButtonMenuFindInClick(Sender: TObject);
var
  TargetIndex, SharedEditorIdx: Integer;
  DestWin: TSourceEditorWindowInterface;
  xBtn: TPackageTabButton;
begin
  xBtn := (FTabButtonMenu.PopupComponent as TPackageTabButton);
  TargetIndex := (Sender as TMenuItemWindow).WindowIndex;
  if (TargetIndex < 0) or (TargetIndex >= SourceEditorManagerIntf.SourceWindowCount) then
    exit;
  DestWin := SourceEditorManagerIntf.SourceWindows[TargetIndex];
  SharedEditorIdx := DestWin.IndexOfEditorInShareWith(xBtn.Editor);
  If SharedEditorIdx < 0 then
    exit;
  SourceEditorManagerIntf.ActiveEditor := DestWin.Items[SharedEditorIdx];
  SourceEditorManagerIntf.ShowActiveWindowOnTop(True);
end;

procedure TPackageTabPanel.TabButtonMenuMoveToClick(Sender: TObject);
var
  xBtn: TPackageTabButton;
  xToWindow: Integer;
begin
  xBtn := (FTabButtonMenu.PopupComponent as TPackageTabButton);
  xToWindow := (Sender as TMenuItemWindow).WindowIndex;
  xBtn.Editor.MoveToWindow(xToWindow);
end;

procedure TPackageTabPanel.TabButtonMenuPopup(Sender: TObject);
var
  xBtn: TPackageTabButton;

  procedure RecreateMoveClone(const aMenuItem: TMenuItem;
    const aOnClickMethod: TNotifyEvent; aWinForFind: Boolean = False);
  var
    I, SharedEditor: Integer;
    xWin: TSourceEditorWindowInterface;
    xNewItem: TMenuItemWindow;
  begin
    for I := aMenuItem.Count-1 downto 0 do
      if aMenuItem[I] is TMenuItemWindow then
        aMenuItem[I].Free;

    for I := 0 to SourceEditorManagerIntf.SourceWindowCount - 1 do
    begin
      xWin := SourceEditorManagerIntf.SourceWindows[I];
      SharedEditor := xWin.IndexOfEditorInShareWith(xBtn.Editor);
      if (xWin <> FWindow) and ((SharedEditor < 0) <> aWinForFind) then
      begin
        xNewItem := TMenuItemWindow.Create(Self);
        xNewItem.Caption := xWin.Caption;
        xNewItem.OnClick := aOnClickMethod;
        xNewItem.WindowIndex := I;
        aMenuItem.Add(xNewItem);
      end;
    end;
  end;
begin
  xBtn := (FTabButtonMenu.PopupComponent as TPackageTabButton);
  FTabButtonMenuProjSep.Visible := xBtn.IsOtherFile;
  FTabButtonMenuAddToProject.Visible := xBtn.IsOtherFile;

  RecreateMoveClone(FTabButtonMenuMoveTo, @TabButtonMenuMoveToClick);
  RecreateMoveClone(FTabButtonMenuCloneTo, @TabButtonMenuCloneToClick);
  RecreateMoveClone(FTabButtonMenuFindIn, @TabButtonMenuFindInClick, True);
  FTabButtonMenuFindIn.Visible := FTabButtonMenuFindIn.Count > 0;
end;

procedure TPackageTabPanel.TabButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  xBtn: TPackageTabButton;
begin
  xBtn := (Sender as TPackageTabButton);
  case Button of
    mbLeft: FWindow.ActiveEditor := xBtn.Editor;
    mbMiddle: LazarusIDE.DoCloseEditorFile(xBtn.Editor, [cfSaveFirst]);
  end;
end;

procedure TPackageTabPanel.TabLabelCloseAllGroupClick(Sender: TObject);
var
  xPopupControl: TControl;
  I: Integer;
  xDelete: Boolean;
  xBtn: TPackageTabButton;
begin
  xPopupControl := FTabLabelMenu.PopupComponent as TControl;

  FAppIdleLocked := True;
  try
    I := 0;
    xDelete := False;
    while I < FPanel.ControlCount do
    begin
      if xDelete then
      begin
        if FPanel.Controls[I] is TPackageTabButton then
        begin
          xBtn := TPackageTabButton(FPanel.Controls[I]);
          LazarusIDE.DoCloseEditorFile(xBtn.Editor, [cfSaveFirst]);
        end else
          Exit; // close only group from label
      end else
      if FPanel.Controls[I] = xPopupControl then
        xDelete := True;

      Inc(I);
    end;
  finally
    FAppIdleLocked := False;
  end;
end;

procedure TPackageTabPanel.TabLabelMenuOpenPackageClick(Sender: TObject);
var
  xLbl: TPackageTabLabel;
begin
  xLbl := (FTabLabelMenu.PopupComponent as TPackageTabLabel);
  PackageEditingInterface.DoOpenPackageFile(xLbl.Package.Filename,[pofAddToRecent],false);
end;

procedure TPackageTabPanel.TabLabelMenuPopup(Sender: TObject);
var
  xLbl: TPackageTabLabel;
begin
  xLbl := (FTabLabelMenu.PopupComponent as TPackageTabLabel);
  FTabLabelMenuPkgSep.Visible := xLbl.Package<>nil;
  FTabLabelMenuOpenPackage.Visible := xLbl.Package<>nil;
end;

{ TPackageTabPanels }

constructor TPackageTabPanels.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  FTabPanels := TObjectList.Create(True);
  FConfig := TXMLConfig.Create(LazarusIDE.GetPrimaryConfigPath+'packagetabs.xml');

  Assert(SourceEditorManagerIntf <> nil);
  SourceEditorManagerIntf.RegisterChangeEvent(semWindowCreate, @WindowCreated);
  SourceEditorManagerIntf.RegisterChangeEvent(semWindowDestroy, @WindowDestroyed);
  SourceEditorManagerIntf.RegisterChangeEvent(semEditorCreate, @EditorCreated);
  SourceEditorManagerIntf.RegisterChangeEvent(semEditorDestroy, @EditorDestroyed);
  SourceEditorManagerIntf.RegisterChangeEvent(semEditorActivate, @EditorActivated);
  SourceEditorManagerIntf.ShowTabs := False;
end;

destructor TPackageTabPanels.Destroy;
begin
  FConfig.Free;
  FTabPanels.Free;
  inherited Destroy;
end;

function TPackageTabPanels.GetTabPanel(Index: Integer): TPackageTabPanel;
begin
  Result := TPackageTabPanel(FTabPanels[Index]);
end;

function TPackageTabPanels.GetTabPanelCount: Integer;
begin
  Result := FTabPanels.Count;
end;

procedure TPackageTabPanels.EditorActivated(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to TabPanelCount-1 do
    TabPanels[I].EditorActivated;
end;

procedure TPackageTabPanels.EditorCreated(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to TabPanelCount-1 do
    TabPanels[I].EditorCreated;
end;

procedure TPackageTabPanels.EditorDestroyed(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to TabPanelCount-1 do
    TabPanels[I].EditorDestroyed;
end;

procedure TPackageTabPanels.WindowCreated(Sender: TObject);
var
  PTP: TPackageTabPanel;
begin
  PTP := TPackageTabPanel.Create(Sender as TSourceEditorWindowInterface);
  FTabPanels.Add(PTP);
  PTP.LoadConfig(FConfig, 'PackageTabs/');
end;

procedure TPackageTabPanels.WindowDestroyed(Sender: TObject);
var
  xWindow: TSourceEditorWindowInterface;
  I: Integer;
begin
  xWindow := Sender as TSourceEditorWindowInterface;
  for I := TabPanelCount-1 downto 0 do
    if TabPanels[I].FWindow = xWindow then
    begin
      TabPanels[I].SaveConfig(FConfig, 'PackageTabs/');
      FTabPanels.Delete(I);
    end;
end;

finalization
  FreeAndNil(xPackageTabPanels);
end.

