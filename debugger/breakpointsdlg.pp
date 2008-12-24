{ $Id$ }
{               ----------------------------------------------
                 breakpointsdlg.pp  -  Overview of breakpoints
                ----------------------------------------------

 @created(Fri Dec 14st WET 2001)
 @lastmod($Date$)
 @author(Shane Miller)
 @author(Marc Weustink <marc@@dommelstein.net>)

 This unit contains the Breakpoint dialog.


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

unit BreakPointsDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, LResources, StdCtrls,
  Buttons, Menus, ComCtrls, IDEProcs, Debugger, DebuggerDlg, lclType, MainBase;

type
  TBreakPointsDlgState = (
    bpdsItemsNeedUpdate
    );
  TBreakPointsDlgStates = set of TBreakPointsDlgState;

  { TBreakPointsDlg }

  TBreakPointsDlg = class(TDebuggerDlg)
    lvBreakPoints: TListView;
    N0: TMenuItem;
    popShow: TMenuItem;
    mnuPopup: TPopupMenu;
    popAdd: TMenuItem;
    popAddSourceBP: TMenuItem;
    N1: TMenuItem; //--------------
    popProperties: TMenuItem;
    popEnabled: TMenuItem;
    popDelete: TMenuItem;
    N2: TMenuItem; //--------------
    popDisableAll: TMenuItem;
    popEnableAll: TMenuItem;
    popDeleteAll: TMenuItem;
    N3: TMenuItem; //--------------
    popDisableAllSameSource: TMenuItem;
    popEnableAllSameSource: TMenuItem;
    popDeleteAllSameSource: TMenuItem;
    procedure BreakpointsDlgCREATE(Sender: TObject);
    procedure lvBreakPointsColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvBreakPointsDBLCLICK(Sender: TObject);
    procedure lvBreakPointsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure mnuPopupPopup(Sender: TObject);
    procedure popAddSourceBPClick(Sender: TObject);
    procedure popDeleteAllSameSourceCLICK(Sender: TObject);
    procedure popDisableAllSameSourceCLICK(Sender: TObject);
    procedure popEnableAllSameSourceCLICK(Sender: TObject);
    procedure popPropertiesClick(Sender: TObject);
    procedure popEnabledClick(Sender: TObject);
    procedure popDeleteClick(Sender: TObject);
    procedure popDisableAllClick(Sender: TObject);
    procedure popEnableAllClick(Sender: TObject);
    procedure popDeleteAllClick(Sender: TObject);
    procedure popShowClick(Sender: TObject);
  private
    FBaseDirectory: string;
    FBreakPoints: TIDEBreakPoints;
    FBreakpointsNotification: TIDEBreakPointsNotification;
    FStates: TBreakPointsDlgStates;
    procedure BreakPointAdd(const ASender: TIDEBreakPoints;
                            const ABreakpoint: TIDEBreakPoint);
    procedure BreakPointUpdate(const ASender: TIDEBreakPoints;
                               const ABreakpoint: TIDEBreakPoint);
    procedure BreakPointRemove(const ASender: TIDEBreakPoints;
                               const ABreakpoint: TIDEBreakPoint);
    procedure SetBaseDirectory(const AValue: string);

    procedure SetBreakPoints(const AValue: TIDEBreakPoints);

    procedure UpdateItem(const AnItem: TListItem;
                         const ABreakpoint: TIDEBreakPoint);
    procedure UpdateAll;
    
    procedure DeleteSelectedBreakpoints;
    procedure JumpToCurrentBreakPoint;
    procedure ShowProperties;
  protected
    procedure DoEndUpdate; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    property BaseDirectory: string read FBaseDirectory write SetBaseDirectory;
    property BreakPoints: TIDEBreakPoints read FBreakPoints write SetBreakPoints;
  end;
  
function GetBreakPointStateDescription(ABreakpoint: TBaseBreakpoint): string;
function GetBreakPointActionsDescription(ABreakpoint: TBaseBreakpoint): string;


implementation
uses
  LazarusIDEStrConsts;
function GetBreakPointStateDescription(ABreakpoint: TBaseBreakpoint): string;
const
  //                 enabled  valid
  DEBUG_STATE: array[Boolean, TValidState] of ShortString = (
                {vsUnknown,     vsValid,   vsInvalid}
    {Disabled} (lisOff, lisDisabled, lisInvalidOff),
    {Endabled} (lisOn, lisEnabled, lisInvalidOn));
begin
  Result:=DEBUG_STATE[ABreakpoint.Enabled,ABreakpoint.Valid];
end;

function GetBreakPointActionsDescription(ABreakpoint: TBaseBreakpoint): string;
const
  DEBUG_ACTION: array[TIDEBreakPointAction] of ShortString =
    (lisBreak, lisEnableGroup, lisDisableGroup);

var
  CurBreakPoint: TIDEBreakPoint;
  Action: TIDEBreakPointAction;
begin
  Result := '';
  if ABreakpoint is TIDEBreakPoint then begin
    CurBreakPoint:=TIDEBreakPoint(ABreakpoint);
    for Action := Low(TIDEBreakPointAction) to High(TIDEBreakPointAction) do
      if Action in CurBreakpoint.Actions
      then begin
        if Result <> '' then Result := Result + ', ';
        Result := Result + DEBUG_ACTION[Action]
      end;
  end;
end;

procedure TBreakPointsDlg.BreakPointAdd(const ASender: TIDEBreakPoints;
  const ABreakpoint: TIDEBreakPoint);
var
  Item: TListItem;
  n: Integer;
begin
  Item := lvBreakPoints.Items.FindData(ABreakpoint);
  if Item = nil
  then begin
    Item := lvBreakPoints.Items.Add;
    Item.Data := ABreakPoint;
    for n := 0 to 5 do
      Item.SubItems.Add('');
  end;

  UpdateItem(Item, ABreakPoint);
end;

procedure TBreakPointsDlg.BreakPointUpdate(const ASender: TIDEBreakPoints;
  const ABreakpoint: TIDEBreakPoint);
var
  Item: TListItem;
begin
  if ABreakpoint = nil then Exit;

  Item := lvBreakPoints.Items.FindData(ABreakpoint);
  if Item = nil
  then BreakPointAdd(ASender, ABreakPoint)
  else begin
    if UpdateCount>0 then begin
      Include(FStates,bpdsItemsNeedUpdate);
      exit;
    end;
    UpdateItem(Item, ABreakPoint);
  end;
end;

procedure TBreakPointsDlg.BreakPointRemove(const ASender: TIDEBreakPoints;
  const ABreakpoint: TIDEBreakPoint);
begin
  lvBreakPoints.Items.FindData(ABreakpoint).Free;
end;

procedure TBreakPointsDlg.SetBaseDirectory(const AValue: string);
begin
  if FBaseDirectory=AValue then exit;
  FBaseDirectory:=AValue;
  UpdateAll;
end;

procedure TBreakPointsDlg.SetBreakPoints(const AValue: TIDEBreakPoints);
var
  i: Integer;
begin
  if FBreakPoints = AValue then Exit;

  BeginUpdate;
  try
    lvBreakPoints.Items.Clear;
    if FBreakPoints <> nil
    then begin
      FBreakPoints.RemoveNotification(FBreakpointsNotification);
    end;

    FBreakPoints:=AValue;

    if FBreakPoints <> nil
    then begin
      FBreakPoints.AddNotification(FBreakpointsNotification);

      for i:=0 to FBreakPoints.Count-1 do
        BreakPointUpdate(FBreakPoints, FBreakPoints.Items[i]);
    end;
  finally
    EndUpdate;
  end;
end;

constructor TBreakPointsDlg.Create(AOwner: TComponent);
begin
  inherited;
  Name:='BreakPointsDlg';
  FBreakpointsNotification := TIDEBreakPointsNotification.Create;
  FBreakpointsNotification.AddReference;
  FBreakpointsNotification.OnAdd := @BreakPointAdd;
  FBreakpointsNotification.OnUpdate := @BreakPointUpdate;
  FBreakpointsNotification.OnRemove := @BreakPointRemove;
end;       

destructor TBreakPointsDlg.Destroy;
begin
  SetBreakPoints(nil);
  FBreakpointsNotification.OnAdd := nil;
  FBreakpointsNotification.OnUpdate := nil;
  FBreakpointsNotification.OnRemove := nil;
  FBreakpointsNotification.ReleaseReference;
  inherited;
end;

procedure TBreakPointsDlg.lvBreakPointsColumnClick(Sender: TObject;
  Column: TListColumn);
begin
  lvBreakPoints.SortColumn := Column.Index;
end;

procedure TBreakPointsDlg.BreakpointsDlgCREATE(Sender: TObject);
begin
  Caption:= lisMenuViewBreakPoints;
  lvBreakPoints.Align:=alClient;
  lvBreakPoints.Columns[0].Caption:= lisOIPState;
  lvBreakPoints.Columns[1].Caption:= lisFilenameAddress;
  lvBreakPoints.Columns[2].Caption:= lisLineLength;
  lvBreakPoints.Columns[3].Caption:= lisCondition;
  lvBreakPoints.Columns[4].Caption:= lisLazBuildABOAction;
  lvBreakPoints.Columns[5].Caption:= lisPassCount;
  lvBreakPoints.Columns[6].Caption:= lisGroup;
  popShow.Caption:= lisShow;
  popAdd.Caption:= dlgEdAdd;
  popAddSourceBP.Caption:= lisSourceBreakpoint;
  popProperties.Caption:= liswlProperties;
  popEnabled.Caption:= liswlEnabled;
  popDelete.Caption:= liswlDelete;
  popDisableAll.Caption:= liswlDIsableAll;
  popEnableAll.Caption:= lisEnableAll;
  popDeleteAll.Caption:= lisDeleteAll;
  popDisableAllSameSource.Caption:= lisDisableAllInSameSource;
  popEnableAllSameSource.Caption:= lisEnableAllInSameSource;
  popDeleteAllSameSource.Caption:= lisDeleteAllInSameSource;
end;

procedure TBreakPointsDlg.lvBreakPointsDBLCLICK(Sender: TObject);
begin
  JumpToCurrentBreakPoint;
end;

procedure TBreakPointsDlg.lvBreakPointsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Handled : Boolean;
  xyScreenPos : TPoint;
begin
  Handled := true;

  if shift= [ssAlt] then
  begin
    case key of
      VK_F10:
        begin // <ALT-F10> default behaviour: open context menu
          xyScreenPos.x:=left+width div 2;
          xyScreenPos.y:=top+  height div 2;
          mnuPopup.PopUp(xyScreenPos.x,xyScreenPos.y);
        end;
    else
      Handled := false;
    end;
  end
  else
  if shift=[] then
  begin
    case key of
      VK_RETURN:
        ShowProperties;
      VK_D:
        DeleteSelectedBreakpoints;
    else
      Handled := false;
    end;
  end
  else
    Handled := false;

  if Handled then
    Key := 0;
end;


procedure TBreakPointsDlg.mnuPopupPopup(Sender: TObject);
var
  Enable: Boolean;
  CurBreakPoint: TIDEBreakPoint;
begin
  Enable := lvBreakPoints.Selected <> nil;
  if Enable then
    CurBreakPoint:=TIDEBreakPoint(lvBreakPoints.Selected.Data)
  else
    CurBreakPoint:=nil;
  popProperties.Enabled := Enable;
  popEnabled.Enabled := Enable;
  if CurBreakPoint<>nil then
    popEnabled.Checked := CurBreakPoint.Enabled
  else
    popEnabled.Checked := false;
  popDelete.Enabled := Enable;
  
  // 'All in same source' menuitems
  popDisableAllSameSource.Enabled := Enable;
  popDeleteAllSameSource.Enabled := Enable;
  popEnableAllSameSource.Enabled := Enable;

  // 'All' menuitems
  Enable := lvBreakPoints.Items.Count>0;
  popDisableAll.Enabled := Enable;
  popDeleteAll.Enabled := Enable;
  popEnableAll.Enabled := Enable;
end;

procedure TBreakPointsDlg.popAddSourceBPClick(Sender: TObject);
begin
end;

procedure TBreakPointsDlg.popDeleteAllSameSourceCLICK(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
  CurItem: TListItem;
  CurBreakPoint: TIDEBreakPoint;
  Filename: String;
begin
  CurItem:=lvBreakPoints.Selected;
  if (CurItem=nil) then exit;
  Filename:=TIDEBreakpoint(CurItem.Data).Source;
  if MessageDlg(lisDeleteAllBreakpoints,
    Format(lisDeleteAllBreakpoints2, ['"', Filename, '"']),
    mtConfirmation,[mbYes,mbCancel],0)<>mrYes
  then exit;
  for n := lvBreakPoints.Items.Count - 1 downto 0 do
  begin
    Item := lvBreakPoints.Items[n];
    CurBreakPoint:=TIDEBreakPoint(Item.Data);
    if CompareFilenames(CurBreakPoint.Source,Filename)=0
    then CurBreakPoint.Free;
  end;
end;

procedure TBreakPointsDlg.popDisableAllSameSourceCLICK(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
  CurItem: TListItem;
  CurBreakPoint: TIDEBreakPoint;
  Filename: String;
begin
  CurItem:=lvBreakPoints.Selected;
  if (CurItem=nil) then exit;
  Filename:=TIDEBreakpoint(CurItem.Data).Source;
  for n := 0 to lvBreakPoints.Items.Count - 1 do
  begin
    Item := lvBreakPoints.Items[n];
    CurBreakPoint:=TIDEBreakPoint(Item.Data);
    if CompareFilenames(CurBreakPoint.Source,Filename)=0
    then CurBreakPoint.Enabled := False;
  end;
end;

procedure TBreakPointsDlg.popEnableAllSameSourceCLICK(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
  CurItem: TListItem;
  CurBreakPoint: TIDEBreakPoint;
  Filename: String;
begin
  CurItem:=lvBreakPoints.Selected;
  if (CurItem=nil) then exit;
  Filename:=TIDEBreakpoint(CurItem.Data).Source;
  for n := 0 to lvBreakPoints.Items.Count - 1 do
  begin
    Item := lvBreakPoints.Items[n];
    CurBreakPoint:=TIDEBreakPoint(Item.Data);
    if CompareFilenames(CurBreakPoint.Source,Filename)=0
    then CurBreakPoint.Enabled := True;
  end;
end;

procedure TBreakPointsDlg.popDeleteAllClick(Sender: TObject);
var
  n: Integer;
begin                                    
  if MessageDlg(lisDeleteAllBreakpoints,
    lisDeleteAllBreakpoints,
    mtConfirmation,[mbYes,mbCancel],0)<>mrYes
  then exit;
  lvBreakPoints.BeginUpdate;
  try
    for n := lvBreakPoints.Items.Count - 1 downto 0 do
      TIDEBreakPoint(lvBreakPoints.Items[n].Data).Free;
  finally
    lvBreakPoints.EndUpdate;
  end;
end;

procedure TBreakPointsDlg.popShowClick(Sender: TObject);
begin
  JumpToCurrentBreakPoint;
end;

procedure TBreakPointsDlg.popDeleteClick(Sender: TObject);
begin
  DeleteSelectedBreakpoints
end;

procedure TBreakPointsDlg.popDisableAllClick(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
begin
  for n := 0 to lvBreakPoints.Items.Count - 1 do
  begin
    Item := lvBreakPoints.Items[n];
    if Item.Data <> nil
    then TIDEBreakPoint(Item.Data).Enabled := False;
  end;
end;

procedure TBreakPointsDlg.popEnableAllClick(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
begin
  for n := 0 to lvBreakPoints.Items.Count - 1 do
  begin
    Item := lvBreakPoints.Items[n];
    if Item.Data <> nil
    then TIDEBreakPoint(Item.Data).Enabled := True;
  end;
end;

procedure TBreakPointsDlg.popEnabledClick(Sender: TObject);
var
  n: Integer;
  Item: TListItem;
  Enable: Boolean;
begin
  Item:=lvBreakPoints.Selected;
  if (Item=nil) then exit;

  Enable := not TIDEBreakPoint(Item.Data).Enabled;

  if lvBreakPoints.SelCount > 1
  then begin
    for n := 0 to lvBreakPoints.Items.Count -1 do
    begin
      Item := lvBreakPoints.Items[n];
      if Item.Selected then
        TIDEBreakPoint(Item.Data).Enabled := Enable;
    end;
  end
  else begin
    TIDEBreakPoint(Item.Data).Enabled:= Enable;
  end;
end;

procedure TBreakPointsDlg.popPropertiesClick(Sender: TObject);
begin
  ShowProperties;
end;

procedure TBreakPointsDlg.DoEndUpdate;
begin
  inherited DoEndUpdate;
  if bpdsItemsNeedUpdate in FStates then UpdateAll;
end;

procedure TBreakPointsDlg.UpdateItem(const AnItem: TListItem;
  const ABreakpoint: TIDEBreakPoint);
var
  Filename: String;
begin
  // Filename/Address
  // Line/Length
  // Condition
  // Action
  // Pass Count
  // Group

  // state
  AnItem.Caption := GetBreakPointStateDescription(ABreakpoint);
  
  // filename
  Filename:=ABreakpoint.Source;
  if BaseDirectory<>'' then
    Filename:=CreateRelativePath(Filename,BaseDirectory);
  AnItem.SubItems[0] := Filename;
  
  // line
  if ABreakpoint.Line > 0
  then AnItem.SubItems[1] := IntToStr(ABreakpoint.SourceLine)
  else AnItem.SubItems[1] := '';
  
  // expression
  AnItem.SubItems[2] := ABreakpoint.Expression;
  
  // actions
  AnItem.SubItems[3]  := GetBreakPointActionsDescription(ABreakpoint);
  
  // hitcount
  AnItem.SubItems[4] := IntToStr(ABreakpoint.HitCount);
  
  // group
  if ABreakpoint.Group = nil
  then AnItem.SubItems[5] := ''
  else AnItem.SubItems[5] := ABreakpoint.Group.Name;
end;

procedure TBreakPointsDlg.UpdateAll;
var
  i: Integer;
  CurItem: TListItem;
begin
  if UpdateCount>0 then begin
    Include(FStates,bpdsItemsNeedUpdate);
    exit;
  end;
  Exclude(FStates,bpdsItemsNeedUpdate);
  for i:=0 to lvBreakPoints.Items.Count-1 do begin
    CurItem:=lvBreakPoints.Items[i];
    UpdateItem(CurItem,TIDEBreakPoint(CurItem.Data));
  end;
end;

procedure TBreakPointsDlg.DeleteSelectedBreakpoints;
var
  Item: TListItem;
  CurBreakPoint: TIDEBreakPoint;
  Msg: String;
  List: TList;
  n: Integer;
begin
  Item:=lvBreakPoints.Selected;
  if Item = nil then exit;

  if lvBreakPoints.SelCount = 1 then
  begin
    CurBreakPoint:=TIDEBreakPoint(Item.Data);
    Msg := Format(lisDeleteBreakpointAtLine, [#13, CurBreakPoint.Source,
      CurBreakPoint.Line]);
  end
  else
    Msg := lisDeleteAllSelectedBreakpoints;
  if MessageDlg(Msg, mtConfirmation, [mbYes,mbCancel],0) <> mrYes then exit;

  if lvBreakPoints.SelCount = 1
  then begin
    TObject(Item.Data).Free;
    Exit;
  end;

  List := TList.Create;
  for n := 0 to lvBreakPoints.Items.Count - 1 do
  begin
    Item := lvBreakPoints.Items[n];
    if Item.Selected
    then List.Add(Item.Data);
  end;

  lvBreakPoints.BeginUpdate;
  try
    for n := 0 to List.Count - 1 do
      TObject(List[n]).Free;
  finally
    lvBreakPoints.EndUpdate;
  end;
  List.Free;
end;

procedure TBreakPointsDlg.JumpToCurrentBreakPoint;
var
  CurItem: TListItem;
  CurBreakPoint: TIDEBreakPoint;
begin
  CurItem:=lvBreakPoints.Selected;
  if CurItem=nil then exit;
  CurBreakPoint:=TIDEBreakPoint(CurItem.Data);

  MainIDE.DoJumpToSourcePosition(CurBreakPoint.Source, 0, CurBreakPoint.Line, 0, True);
end;

procedure TBreakPointsDlg.ShowProperties;
begin
  ShowMessage(lisNotImplementedYet2);
end;


initialization
  {$I breakpointsdlg.lrs}

end.

