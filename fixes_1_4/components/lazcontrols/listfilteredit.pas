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
  LCLProc, LCLType, EditBtn, CheckLst, FileUtil, LazUTF8, AvgLvlTree;

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
    function GetFirstSelected: Integer;
    procedure SetFilteredListbox(const AValue: TCustomListBox);
    procedure UnselectAll;
  protected
    procedure MoveNext; override;
    procedure MovePrev; override;
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
    property Data: TStringList read fOriginalData; deprecated 'Use property Items instead';
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
  s: string;
  Pass, Done: Boolean;
begin
  Done:=False;
  fSortedData.Clear;
  for Origi:=0 to fOriginalData.Count-1 do begin
    s:=fOriginalData[Origi];
    // Filter with event handler if there is one.
    if Assigned(OnFilterItem) then
      Pass:=OnFilterItem(fOriginalData.Objects[Origi], Done)
    else
      Pass:=False;
    // Filter by item's title text if needed.
    if not (Pass or Done) then
      Pass:=(Filter='') or (Pos(Filter,UTF8LowerCase(s))>0);
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

function TListFilterEdit.GetFirstSelected: Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to fFilteredListbox.Count - 1 do
    if fFilteredListbox.Selected[i] then
      Exit(i);
end;

procedure TListFilterEdit.UnselectAll;
var
  i: Integer;
begin
  for i := 0 to fFilteredListbox.Count - 1 do
    fFilteredListbox.Selected[i] := False;
end;

procedure TListFilterEdit.MoveNext;
var
  i: Integer;
begin
  i := GetFirstSelected + 1;
  if fFilteredListbox.Count > 0 then begin
    UnselectAll;
    if i < fFilteredListbox.Count then
      fFilteredListbox.Selected[i] := True
    else
      fFilteredListbox.Selected[0] := True;
  end;
end;

procedure TListFilterEdit.MovePrev;
var
  i: Integer;
begin
  i := GetFirstSelected - 1;
  if fFilteredListbox.Count > 0 then begin
    UnselectAll;
    if i >= 0 then
      fFilteredListbox.Selected[i] := True
    else
      fFilteredListbox.Selected[fFilteredListbox.Count-1] := True;
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

