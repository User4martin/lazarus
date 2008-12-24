{ $Id$ }
{               ----------------------------------------------  
                 callstackdlg.pp  -  Overview of the callstack 
                ---------------------------------------------- 
 
 @created(Sun Apr 28th WET 2002)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@dommelstein.net>)                       

 This unit contains the Call Stack debugger dialog.
 
 
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
unit CallStackDlg;

{$mode objfpc}{$H+}

interface

uses
  LResources, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, Debugger, DebuggerDlg, Menus, ClipBrd, ExtCtrls, StdCtrls, Spin,
  ActnList, MainBase;

type

  { TCallStackDlg }

  TCallStackDlg = class(TDebuggerDlg)
    aclActions: TActionList;
    actCopyAll: TAction;
    actViewBottom: TAction;
    actViewTop: TAction;
    actViewLimit: TAction;
    actViewGoto: TAction;
    actViewMore: TAction;
    actSetCurrent: TAction;
    actShow: TAction;
    ImageList1: TImageList;
    ToolButtonTop: TToolButton;
    ToolButtonBottom: TToolButton;
    ToolButtonCopyAll: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    txtGoto: TEdit;
    lvCallStack: TListView;
    Panel1: TPanel;
    popLimit50: TMenuItem;
    popLimit25: TMenuItem;
    popLimit10: TMenuItem;
    popCopyAll: TMenuItem;
    N1: TMenuItem;
    popSetAsCurrent: TMenuItem;
    popShow: TMenuItem;
    mnuPopup: TPopupMenu;
    mnuLimit: TPopupMenu;
    ToolBar1: TToolBar;
    ToolButtonShow: TToolButton;
    ToolButtonCurrent: TToolButton;
    ToolButton4: TToolButton;
    ToolButtonMore: TToolButton;
    ToolButtonMax: TToolButton;
    ToolButtonGoto: TToolButton;
    procedure actViewBottomExecute(Sender: TObject);
    procedure actViewGotoExecute(Sender: TObject);
    procedure actViewMoreExecute(Sender: TObject);
    procedure actViewLimitExecute(Sender: TObject);
    procedure actViewTopExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure popCountClick(Sender: TObject);
    procedure txtGotoKeyPress(Sender: TObject; var Key: char);
    procedure lvCallStackDBLCLICK(Sender: TObject);
    procedure actCopyAllClick(Sender: TObject);
    procedure actSetAsCurrentClick(Sender : TObject);
    procedure actShowClick(Sender: TObject);
  private
    FCallStack: TIDECallStack;
    FCallStackNotification: TIDECallStackNotification;
    FViewCount: Integer;
    FViewLimit: Integer;
    FViewStart: Integer;
    procedure InitImageList;
    procedure SetViewLimit(const AValue: Integer);
    procedure SetViewStart(AStart: Integer);
    procedure SetViewMax;
    procedure CallStackChanged(Sender: TObject);
    procedure CallStackCurrent(Sender: TObject);
    procedure GotoIndex(AIndex: Integer);
    function  GetCurrentEntry: TCallStackEntry;
    function  GetFunction(const Entry: TCallStackEntry): string;
    procedure SetCallStack(const AValue: TIDECallStack);
    procedure UpdateView;
    procedure JumpToSource;
    procedure CopyToClipBoard;
  protected
    procedure DoBeginUpdate; override;
    procedure DoEndUpdate; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property CallStack: TIDECallStack read FCallStack write SetCallStack;
    property ViewLimit: Integer read FViewLimit write SetViewLimit;
  end;


implementation

uses
  BaseDebugManager, LCLProc, LazarusIDEStrConsts;

{ TCallStackDlg }

constructor TCallStackDlg.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCallStackNotification := TIDECallStackNotification.Create;
  FCallStackNotification.AddReference;
  FCallStackNotification.OnChange := @CallStackChanged;
  FCallStackNotification.OnCurrent := @CallStackCurrent;
  FViewLimit := 10;
  FViewCount := 10;
  FViewStart := 0;
  actViewLimit.Caption := popLimit10.Caption;
end;

procedure TCallStackDlg.CallStackChanged(Sender: TObject);
begin
  if FViewStart = 0
  then UpdateView
  else SetViewStart(0);
  SetViewMax;
end;

procedure TCallStackDlg.CallStackCurrent(Sender: TObject);
begin
  UpdateView;
end;

procedure TCallStackDlg.UpdateView;
var
  n: Integer;
  Item: TListItem;
  Entry: TCallStackEntry;
  First, Count: Integer;
begin
  BeginUpdate;
  try
    if (CallStack = nil) or (CallStack.Count=0)
    then begin
      txtGoto.Text:= '0';
      lvCallStack.Items.Clear;
      exit;
    end;

    First := FViewStart;
    if First + FViewLimit <= CallStack.Count
    then Count := FViewLimit
    else Count := CallStack.Count - First;

    // Reuse entries, so add and remove only
    // Remove unneded
    for n := lvCallStack.Items.Count - 1 downto Count do
      lvCallStack.Items.Delete(n);

    // Add needed
    for n := lvCallStack.Items.Count to Count - 1 do
    begin
      Item := lvCallStack.Items.Add;
      Item.SubItems.Add('');
      Item.SubItems.Add('');
      Item.SubItems.Add('');
      Item.SubItems.Add('');
    end;

    CallStack.PrepareRange(First, Count);
    for n := 0 to Count - 1 do
    begin
      Item := lvCallStack.Items[n];
      Entry := CallStack.Entries[First + n];
      if Entry = nil
      then begin
        Item.Caption := '';
        Item.SubItems[0] := '????';
        Item.SubItems[1] := '';
        Item.SubItems[2] := '';
        Item.SubItems[3] := '';
      end
      else begin
        if Entry.Current
        then Item.Caption := '>'
        else Item.Caption := ' ';
        Item.SubItems[0] := IntToStr(Entry.Index);
        Item.SubItems[1] := Entry.Source;
        Item.SubItems[2] := IntToStr(Entry.Line);
        Item.SubItems[3] := GetFunction(Entry);
      end;
    end;
    
  finally
    EndUpdate;
  end;
end;

destructor TCallStackDlg.Destroy;
begin
  SetCallstack(nil);
  FCallStackNotification.OnChange := nil;
  FCallStackNotification.ReleaseReference;
  inherited Destroy;
end;

procedure TCallStackDlg.DoBeginUpdate;
begin
  lvCallStack.BeginUpdate;
end;

procedure TCallStackDlg.DoEndUpdate;
begin
  lvCallStack.EndUpdate;
end;

function TCallStackDlg.GetCurrentEntry: TCallStackEntry;
var
  CurItem: TListItem;
  idx: Integer;
begin
  Result := nil;
  if Callstack = nil then Exit;
  
  CurItem := lvCallStack.Selected;
  if CurItem = nil then Exit;

  idx := FViewStart + CurItem.Index;
  if idx >= CallStack.Count then Exit;

  Result := CallStack.Entries[idx];
end;

procedure TCallStackDlg.JumpToSource;
var
  Entry: TCallStackEntry;
  Filename: String;
begin
  Entry := GetCurrentEntry;
  if Entry = nil then Exit;

  Filename := Entry.Source;
  if DebugBoss.GetFullFilename(Filename, true)
  then MainIDE.DoJumpToSourcePosition(Filename, 0, Entry.Line, 0, True);
end;

procedure TCallStackDlg.CopyToClipBoard;
var
  n: integer;
  Entry: TCallStackEntry;
  S: String;
begin
  Clipboard.Clear;
  
  if (CallStack=nil) or (CallStack.Count=0) then exit;
  
  S := '';
  for n:= 0 to CallStack.Count-1 do
  begin
    Entry:=CallStack.Entries[n];
    if Entry <> nil
    then S := S + format('#%d %s at %s:%d', [n, GetFunction(Entry), Entry.Source, Entry.Line])
    else S := S + format('#%d ????', [n]);
    S := S + LineEnding;
  end;
  ClipBoard.AsText := S;
end;

procedure TCallStackDlg.lvCallStackDBLCLICK(Sender: TObject);
begin
  JumpToSource;
end;

procedure TCallStackDlg.popCountClick(Sender: TObject);
begin
  if FViewCount = TMenuItem(Sender).Tag then Exit;
  FViewCount := TMenuItem(Sender).Tag;
  ViewLimit := FViewCount;
  actViewLimit.Caption := TMenuItem(Sender).Caption;
end;

procedure TCallStackDlg.txtGotoKeyPress(Sender: TObject; var Key: char);
begin
  case Key of
    '0'..'9', #8 : ;
    #13 : SetViewStart(StrToIntDef(txtGoto.Text, 0));
  else
    Key := #0;
  end;
end;

procedure TCallStackDlg.actCopyAllClick(Sender: TObject);
begin
  CopyToClipBoard;
end;

procedure TCallStackDlg.actSetAsCurrentClick(Sender : TObject);
var
  Entry: TCallStackEntry;
begin
  Entry := GetCurrentEntry;
  if Entry = nil then Exit;

  CallStack.Current := Entry;
end;

procedure TCallStackDlg.actShowClick(Sender: TObject);
begin
  JumpToSource;
end;

procedure TCallStackDlg.InitImageList;
begin
  Imagelist1.AddLazarusResource('callstack_show');
  Imagelist1.AddLazarusResource('callstack_more');
  Imagelist1.AddLazarusResource('callstack_top');
  Imagelist1.AddLazarusResource('callstack_bottom');
  Imagelist1.AddLazarusResource('callstack_goto');
  Imagelist1.AddLazarusResource('laz_copy');
end;

procedure TCallStackDlg.actViewBottomExecute(Sender: TObject);
begin
  if CallStack <> nil
  then SetViewStart(CallStack.Count - FViewLimit)
  else SetViewStart(0);
end;

procedure TCallStackDlg.actViewGotoExecute(Sender: TObject);
begin
  SetViewStart(StrToIntDef(txtGoto.Text, 0));
end;

procedure TCallStackDlg.actViewMoreExecute(Sender: TObject);
begin
  ViewLimit := ViewLimit + FViewCount;
end;

procedure TCallStackDlg.actViewTopExecute(Sender: TObject);
begin
  SetViewStart(0);
end;

procedure TCallStackDlg.FormCreate(Sender: TObject);
var
  i: integer;
begin
  Caption:= lisMenuViewCallStack;
  ToolButtonShow.Caption:= lisShow;
  ToolButtonCurrent.Caption:= lisCurrent;
  for i:= 0 to mnuLimit.Items.Count-1 do
    mnuLimit.Items[i].Caption:= Format(lisMaxS, [mnuLimit.Items[i].Tag]);
  ToolButtonMore.Caption:= lisMore;
  ToolButtonTop.Caption:= lisTop;
  ToolButtonBottom.Caption:= lisBottom;
  ToolButtonGoto.Caption:= lisToDoGoto;
  ToolButtonCopyAll.Caption:= lisCopyAll;
  lvCallStack.Columns[1].Caption:= lisIndex;
  lvCallStack.Columns[2].Caption:= lisCEOModeSource;
  lvCallStack.Columns[3].Caption:= lisToDoLLine;
  lvCallStack.Columns[4].Caption:= lisFunction;
  InitImageList;
end;

procedure TCallStackDlg.actViewLimitExecute(Sender: TObject);
begin
  ViewLimit := FViewCount;
end;

procedure TCallStackDlg.SetViewStart(AStart: Integer);
begin
  if CallStack = nil then Exit;
  
  if (AStart > CallStack.Count - FViewLimit)
  then AStart := CallStack.Count - FViewLimit;
  if AStart < 0 then AStart := 0;
  if FViewStart = AStart then Exit;
  
  FViewStart:= AStart;
  txtGoto.Text:= IntToStr(AStart);
  UpdateView;
end;

procedure TCallStackDlg.SetViewMax;
begin
//  If CallStack = nil
//  then lblViewCnt.Caption:= '0'
//  else lblViewCnt.Caption:= IntToStr(CallStack.Count);
end;

procedure TCallStackDlg.SetCallStack(const AValue: TIDECallStack);
begin
  if FCallStack = AValue then Exit;

  BeginUpdate;
  try
    if FCallStack <> nil
    then begin
      FCallStack.RemoveNotification(FCallStackNotification);
    end;

    FCallStack := AValue;

    if FCallStack <> nil
    then begin
      FCallStack.AddNotification(FCallStackNotification);
    end;

    CallStackChanged(FCallStack);
  finally
    EndUpdate;
  end;
end;

procedure TCallStackDlg.SetViewLimit(const AValue: Integer);
begin
  if FViewLimit = AValue then Exit;
  if (CallStack <> nil)
  and (FViewStart + FViewLimit >= CallStack.Count)
  and (AValue > FViewLimit)
  then begin
    FViewStart := CallStack.Count - AValue;
    if FViewStart < 0 then FViewStart := 0;
  end;
  FViewLimit := AValue;
  UpdateView;
end;

function TCallStackDlg.GetFunction(const Entry: TCallStackEntry): string;
var
  S: String;
  m: Integer;
begin
  S := '';
  for m := 0 to Entry.ArgumentCount - 1 do
  begin
    if S <> '' then
      S := S + ', ';
    S := S + Entry.ArgumentValues[m];
  end;
  if S <> '' then
    S := '(' + S + ')';
  Result := Entry.FunctionName + S;
end;

procedure TCallStackDlg.GotoIndex(AIndex: Integer);
begin
  if AIndex < 0 then Exit;
  if AIndex >= FCallstack.Count then Exit;
  

end;

initialization
  {$I callstackdlg.lrs}

end.

