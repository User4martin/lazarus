{ ListFilterEdit

  Copyright (C) 2012 Lazarus team

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.

}
unit ListFilterEdit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, LResources, Graphics, Controls, StdCtrls,
  LCLProc, LCLType, EditBtn, CheckLst, LazFileUtils, LazUTF8, AvgLvlTree,
  Math;

type

  TImageIndexEvent = function (Str: String; Data: TObject;
                               var IsEnabled: Boolean): Integer of object;

  { TListFilterEdit }

  TListFilterEdit = class(TCustomControlFilterEdit)
  private
    fFilteredListbox: TCustomListbox; // A control showing the (filtered) data.
    fSelectionList: TStringList;      // Store/restore the old selections here.
    // Data supplied by caller through Data property.
    fOriginalData: TStringList;
    // Data sorted for viewing.
    fSortedData: TStringList;
    fCheckedItems: TStringMap;         // Only needed for TCheckListBox
    function CompareFNs(AFilename1,AFilename2: string): integer;
    procedure SetFilteredListbox(const AValue: TCustomListBox);
  protected
    procedure EditEnter; override;
    procedure MoveTo(AIndex: Integer; ASelect: Boolean);
    procedure MoveNext(ASelect: Boolean = False); override;
    procedure MovePrev(ASelect: Boolean = False); override;
    procedure MovePageUp(ASelect: Boolean = False); override;
    procedure MovePageDown(ASelect: Boolean = False); override;
    procedure MoveHome(ASelect: Boolean = False); override;
    procedure MoveEnd(ASelect: Boolean = False); override;
    function ReturnKeyHandled: Boolean; override;
    procedure SortAndFilter; override;
    procedure ApplyFilterCore; override;
    function GetDefaultGlyph: TBitmap; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RemoveItem(AItem: string);
    procedure ItemWasClicked(AItem: string; IsChecked: Boolean);
    procedure StoreSelection; override;
    procedure RestoreSelection; override;
  public
    property SelectionList: TStringList read fSelectionList;
    property Items: TStringList read fOriginalData;
  published
    property FilteredListbox: TCustomListBox read fFilteredListbox write SetFilteredListbox;
  end;

var
  ListFilterGlyph: TBitmap;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('LazControls',[TListFilterEdit]);
end;

{ TListBoxFilterEdit }

constructor TListFilterEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fOriginalData:=TStringList.Create;
  fSelectionList:=TStringList.Create;
  fSortedData:=TStringList.Create;
  if Assigned(fFilteredListbox) and (fFilteredListbox is TCustomCheckListBox) then
    Assert(Assigned(fCheckedItems), 'TListFilterEdit.Create: fCheckedItems=nil');
end;

destructor TListFilterEdit.Destroy;
begin
  fCheckedItems.Free;
  fSortedData.Free;
  fSelectionList.Free;
  fOriginalData.Free;
  inherited Destroy;
end;

procedure TListFilterEdit.EditEnter;
begin
  inherited EditEnter;
  Exit;
  if (fFilteredListbox.SelCount = 0) and (fFilteredListbox.Count > 0) then
    fFilteredListbox.Selected[0] := True;
end;

procedure TListFilterEdit.RemoveItem(AItem: string);
var
  i: Integer;
begin
  i:=fOriginalData.IndexOf(AItem);
  if i>-1 then begin
    fOriginalData.Delete(i);
    if Assigned(fCheckedItems) then
      fCheckedItems.Remove(AItem);
  end;
end;

procedure TListFilterEdit.ItemWasClicked(AItem: string; IsChecked: Boolean);
begin
  if IsChecked then
    fCheckedItems.Add(AItem)
  else
    fCheckedItems.Remove(AItem);
end;

procedure TListFilterEdit.MoveEnd(ASelect: Boolean);
begin
  if fFilteredListbox.Items.Count > 0 then
    MoveTo(fFilteredListbox.Items.Count-1, ASelect);
end;

procedure TListFilterEdit.MoveHome(ASelect: Boolean);
begin
  if fFilteredListbox.Items.Count > 0 then
    MoveTo(0, ASelect);
end;

function TListFilterEdit.GetDefaultGlyph: TBitmap;
begin
  Result := ListFilterGlyph;
end;

procedure TListFilterEdit.SetFilteredListbox(const AValue: TCustomListBox);
begin
  if fFilteredListbox = AValue then Exit;
  fFilteredListbox:=AValue;
  if Assigned(fFilteredListbox) then begin
    fOriginalData.Assign(fFilteredListbox.Items);
    if (fFilteredListbox is TCustomCheckListBox) and not Assigned(fCheckedItems) then
      fCheckedItems:=TStringMap.Create(False);
  end;
end;

function TListFilterEdit.CompareFNs(AFilename1,AFilename2: string): integer;
begin
  if SortData then
    Result:=CompareFilenames(AFilename1, AFilename2)
  else
    Result:=0;
end;

procedure TListFilterEdit.SortAndFilter;
// Copy data from fOriginalData to fSortedData in sorted order
var
  Origi, i: Integer;
  s, FilterLC: string;
  Pass, Done: Boolean;
begin
  Done:=False;
  fSortedData.Clear;
  FilterLC := UTF8LowerCase(Filter);
  for Origi:=0 to fOriginalData.Count-1 do begin
    s:=fOriginalData[Origi];
    // Filter with event handler if there is one.
    if Assigned(OnFilterItem) then
      Pass:=OnFilterItem(fOriginalData.Objects[Origi], Done)
    else
      Pass:=False;
    // Filter by item's title text if needed.
    if not (Pass or Done) then
      Pass:=(FilterLC='') or (Pos(FilterLC,UTF8LowerCase(s))>0);
    if Pass then begin
      i:=fSortedData.Count-1;       // Always sort the data.
      while i>=0 do begin
        if CompareFNs(s,fSortedData[i])>=0 then break;
        dec(i);
      end;
      fSortedData.InsertObject(i+1, s, fOriginalData.Objects[Origi]);
    end;
  end;
end;

procedure TListFilterEdit.ApplyFilterCore;
var
  i, ListInd: Integer;
  s: string;
  clb: TCustomCheckListBox;
begin
  if fFilteredListbox = nil then
    exit;
  clb:=Nil;
  if fFilteredListbox is TCustomCheckListBox then
    clb:=TCustomCheckListBox(fFilteredListbox);
  fFilteredListbox.Clear;
  fFilteredListbox.Items.BeginUpdate;
  for i:=0 to fSortedData.Count-1 do begin
    s:=fSortedData[i];
    ListInd:=fFilteredListbox.Items.AddObject(s, fSortedData.Objects[i]);
    if Assigned(fSelectedPart) then
      fFilteredListbox.Selected[i]:=fSelectedPart=fSortedData.Objects[i];
    if Assigned(clb) then begin
      if Assigned(OnCheckItem) then
        clb.Checked[ListInd]:=OnCheckItem(fSortedData.Objects[i])
      else
        clb.Checked[ListInd]:=fCheckedItems.Contains(s);
    end;
  end;
  fFilteredListbox.Items.EndUpdate;
end;

procedure TListFilterEdit.StoreSelection;
var
  i: Integer;
begin
  if fFilteredListbox = nil then
    exit;
  fSelectionList.Clear;
  if fFilteredListbox.SelCount > 0 then
    for i := 0 to fFilteredListbox.Count-1 do
      if fFilteredListbox.Selected[i] then
        fSelectionList.Add(fFilteredListbox.Items[i]);
end;

procedure TListFilterEdit.RestoreSelection;
var
  i: Integer;
  clb: TCustomCheckListBox;
begin
  if fSelectionList.Count > 0 then
    for i := 0 to fFilteredListbox.Count-1 do
      if fSelectionList.IndexOf(fFilteredListbox.Items[i]) > -1 then
        fFilteredListbox.Selected[i]:=True;
  // Notify the CheckListBox that checked state may have changed.
  if fFilteredListbox is TCustomCheckListBox then begin
    clb:=TCustomCheckListBox(fFilteredListbox);
    if Assigned(clb.OnItemClick) then
      clb.OnItemClick(clb, -1);  // The handler must not use the index -1 directly
  end;
end;

procedure TListFilterEdit.MoveNext(ASelect: Boolean);
var
  i: Integer;
begin
  if fFilteredListbox.Count = 0 then Exit;
  if (fFilteredListbox.ItemIndex=0) and not fFilteredListbox.Selected[0] then
    i := 0
  else
    i := fFilteredListbox.ItemIndex + 1;
  if i >= fFilteredListbox.Count then
    i := fFilteredListbox.Count-1;
  MoveTo(i, ASelect);
end;

procedure TListFilterEdit.MovePageDown(ASelect: Boolean);
var
  I: Integer;
begin
  if fFilteredListbox.Items.Count = 0 then
    Exit;
  I := fFilteredListbox.ItemIndex + Pred(fFilteredListbox.ClientHeight div fFilteredListbox.ItemHeight);
  if (I < 0) or (I >= fFilteredListbox.Items.Count) then
    I := fFilteredListbox.Items.Count-1;

  MoveTo(I, ASelect);
end;

procedure TListFilterEdit.MovePageUp(ASelect: Boolean);
var
  I: Integer;
begin
  if fFilteredListbox.Items.Count = 0 then
    Exit;
  I := fFilteredListbox.ItemIndex - Pred(fFilteredListbox.ClientHeight div fFilteredListbox.ItemHeight);
  if (I < 0) or (I >= fFilteredListbox.Items.Count) then
    I := 0;

  MoveTo(I, ASelect);
end;

procedure TListFilterEdit.MovePrev(ASelect: Boolean);
var
  i: Integer;
begin
  if fFilteredListbox.Count = 0 then Exit;
  i := fFilteredListbox.ItemIndex - 1;
  if i < 0 then
    i := 0;
  MoveTo(i, ASelect);
end;

procedure TListFilterEdit.MoveTo(AIndex: Integer; ASelect: Boolean);
var
  I, xOldItemIndex, xSelStart, xSelEnd: Integer;
begin
  fFilteredListbox.LockSelectionChange;
  fFilteredListbox.Items.BeginUpdate;
  try
    if ASelect and fFilteredListbox.MultiSelect then
    begin
      xOldItemIndex := fFilteredListbox.ItemIndex;
      xSelStart := xOldItemIndex;
      xSelEnd := xOldItemIndex;
      while (xSelStart>=0) and fFilteredListbox.Selected[xSelStart] do
        Dec(xSelStart);
      while (xSelEnd<fFilteredListbox.Count) and fFilteredListbox.Selected[xSelEnd] do
        Inc(xSelEnd);
      fFilteredListbox.ItemIndex := AIndex;
      for I := Min(AIndex+1, xSelStart+1) to Max(AIndex-1, xSelEnd-1) do
        fFilteredListbox.Selected[I] := True;
      //Win32 sets ItemIndex to the last Selected[?] := True - in contrast to Gtk2 -> set selected again to work on all widgetsets
      fFilteredListbox.Selected[AIndex] := True;
    end else
    begin
      fFilteredListbox.ItemIndex := AIndex;
      fFilteredListbox.Selected[AIndex] := True;
    end;

    if not fFilteredListbox.ItemFullyVisible(AIndex) then
    begin
      if fFilteredListbox.TopIndex < AIndex then
        fFilteredListbox.TopIndex := AIndex - Pred(fFilteredListbox.ClientHeight div fFilteredListbox.ItemHeight)
      else
        fFilteredListbox.TopIndex := AIndex;
    end;
  finally
    fFilteredListbox.UnlockSelectionChange;
    fFilteredListbox.Items.EndUpdate;
  end;
end;

function TListFilterEdit.ReturnKeyHandled: Boolean;
// Retuns true if the Return press was forwarded to the ListBox
var
  Key: Char;
begin
  if fFilteredListbox = nil then
    exit(false);
  Key:=Char(VK_RETURN);
  Result:=Assigned(fFilteredListbox.OnKeyPress);
  if Result then
    fFilteredListbox.OnKeyPress(fFilteredListbox, Key);
end;

end.

