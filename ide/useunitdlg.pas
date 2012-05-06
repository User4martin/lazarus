{ Copyright (C) 2011,

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

  Original version by Juha Manninen
  Icons added by Marcelo B Paula
  All available units added to the list by Anton Panferov
}
unit UseUnitDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ComCtrls, StdCtrls, ExtCtrls, Buttons,
  ButtonPanel, Dialogs, LCLProc, FileProcs, Graphics, LCLType, EditBtn, StrUtils,
  SourceEditor, LazIDEIntf, IDEImagesIntf, LazarusIDEStrConsts, ProjectIntf,
  Project, CodeCache, CodeToolManager, IdentCompletionTool, CodeAtom, CodeTree,
  PascalParserTool, ListFilterEdit, LinkScanner;

type

  { TUseUnitDialog }

  TUseUnitDialog = class(TForm)
    ButtonPanel1: TButtonPanel;
    AllUnitsCheckBox: TCheckBox;
    FilterEdit: TListFilterEdit;
    UnitsListBox: TListBox;
    SectionRadioGroup: TRadioGroup;
    procedure AllUnitsCheckBoxChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SectionRadioGroupClick(Sender: TObject);
    procedure UnitsListBoxDblClick(Sender: TObject);
    procedure UnitsListBoxDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure UnitsListBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    UnitImgInd: Integer;
    FMainUsedUnits: TStrings;
    FImplUsedUnits: TStrings;
    FProjUnits, FOtherUnits: TStringList;
    procedure AddImplUsedUnits;
    function GetProjUnits(SrcEdit: TSourceEditor): Boolean;
    procedure CreateOtherUnitsList;
    function SelectedUnit: string;
    function InterfaceSelected: Boolean;
    procedure DetermineUsesSection(ACode: TCodeBuffer; ACursorPos: TPoint);
    procedure FillAvailableUnitsList;
  public

  end; 

function ShowUseUnitDialog: TModalResult;

implementation

{$R *.lfm}

function ShowUseUnitDialog: TModalResult;
var
  UseUnitDlg: TUseUnitDialog;
  SrcEdit: TSourceEditor;
  s: String;
  CTRes: Boolean;
begin
  Result:=mrOk;
  if not LazarusIDE.BeginCodeTools then exit;
  // get cursor position
  SrcEdit:=SourceEditorManager.ActiveEditor;
  UseUnitDlg:=TUseUnitDialog.Create(nil);
  try
    if not UseUnitDlg.GetProjUnits(SrcEdit) then Exit(mrCancel);
    UseUnitDlg.FillAvailableUnitsList;
    // there is only main uses section in program/library/package
    if SrcEdit.GetProjectFile=Project1.MainUnitInfo then
      // only main (interface) section is available
      UseUnitDlg.SectionRadioGroup.Enabled := False
    else
      // automatic choice of dest uses-section by cursor position
      UseUnitDlg.DetermineUsesSection(SrcEdit.CodeBuffer, SrcEdit.GetCursorTextXY);

    if UseUnitDlg.FilterEdit.Data.Count = 0 then
      // no available units from current project => turn on "all units"
      UseUnitDlg.AllUnitsCheckBox.Checked := True;

    if UseUnitDlg.FilterEdit.Data.Count = 0 then begin
      // No available units. This may not be a pascal source file.
      ShowMessage(dlgNoAvailableUnits);
      Exit(mrCancel);
    end;

    // Show the dialog.
    if UseUnitDlg.ShowModal=mrOk then begin
      s:=UseUnitDlg.SelectedUnit;
      if s <> '' then begin
        if UseUnitDlg.InterfaceSelected then begin
          if UseUnitDlg.FImplUsedUnits.IndexOf(s) >= 0 then
            CTRes := CodeToolBoss.RemoveUnitFromAllUsesSections(SrcEdit.CodeBuffer, s);
          if CTRes then
            CTRes := CodeToolBoss.AddUnitToMainUsesSection(SrcEdit.CodeBuffer, s, '');
        end else
          CTRes:=CodeToolBoss.AddUnitToImplementationUsesSection(SrcEdit.CodeBuffer, s, '');
        if not CTRes then begin
          LazarusIDE.DoJumpToCodeToolBossError;
          exit(mrCancel);
        end;
      end;
    end;
  finally
    UseUnitDlg.Free;
    CodeToolBoss.SourceCache.ClearAllSourceLogEntries;
  end;
end;


{ TUseUnitDialog }

procedure TUseUnitDialog.FormCreate(Sender: TObject);
begin
  // Internationalization
  Caption := dlgUseUnitCaption;
  AllUnitsCheckBox.Caption := dlgShowAllUnits;
  SectionRadioGroup.Caption := dlgInsertSection;
  SectionRadioGroup.Items.Clear;
  SectionRadioGroup.Items.Add(dlgInsertInterface);
  SectionRadioGroup.Items.Add(dlgInsertImplementation);
  SectionRadioGroup.ItemIndex:=0;
  ButtonPanel1.OKButton.Caption:=lisMenuOk;
  ButtonPanel1.CancelButton.Caption:=lisCancel;
  UnitImgInd := IDEImages.LoadImage(16, 'item_unit');
  FProjUnits:=TStringList.Create;
end;

procedure TUseUnitDialog.FormDestroy(Sender: TObject);
begin
  FOtherUnits.Free;
  FProjUnits.Free;
  FImplUsedUnits.Free;
  FMainUsedUnits.Free;
end;

procedure TUseUnitDialog.SectionRadioGroupClick(Sender: TObject);
var
  i: Integer;
begin
  if not Assigned(FImplUsedUnits) then Exit;
  if InterfaceSelected then
    AddImplUsedUnits
  else
    for i := FilterEdit.Data.Count - 1 downto 0 do
      if FilterEdit.Data.Objects[i] is TCodeTreeNode then
        FilterEdit.Data.Delete(i);
  FilterEdit.InvalidateFilter;
  if Visible then
    FilterEdit.SetFocus;
end;

procedure TUseUnitDialog.AllUnitsCheckBoxChange(Sender: TObject);
var
  i: Integer;
begin
  if not (Assigned(FMainUsedUnits) and Assigned(FImplUsedUnits)) then Exit;
  if AllUnitsCheckBox.Checked then begin    // Add other units
    if not Assigned(FOtherUnits) then
      CreateOtherUnitsList;
    FilterEdit.Data.AddStrings(FOtherUnits);
  end
  else
    for i := FilterEdit.Data.Count-1 downto 0 do
      if FilterEdit.Data.Objects[i] is TIdentifierListItem then
        FilterEdit.Data.Delete(i);
  if Visible then
    FilterEdit.SetFocus;
  FilterEdit.InvalidateFilter;
end;

procedure TUseUnitDialog.UnitsListBoxDblClick(Sender: TObject);
begin
  if UnitsListBox.ItemIndex >= 0 then
    ModalResult := mrOK;
end;

procedure TUseUnitDialog.UnitsListBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  ena: Boolean;
begin
  if Index < 0 then Exit;
  with UnitsListBox do
  begin
    Canvas.FillRect(ARect);
    ena := not Assigned(Items.Objects[Index]) or (Items.Objects[Index] is TCodeTreeNode);
    if not (ena or (odSelected in State)) then
      Canvas.Font.Color := clGreen;
    IDEImages.Images_16.Draw(Canvas, 1, ARect.Top, UnitImgInd, ena);
    if Items.Objects[Index] is TCodeTreeNode then
    begin
      // unit for moving: implementation->interface
      Canvas.Pen.Color := clBlue;
      Canvas.Pen.Width := 2;
      Canvas.MoveTo(ARect.Left + 13, ARect.Top + 16);
      Canvas.LineTo(ARect.Left + 13, ARect.Top + 8);
      Canvas.LineTo(ARect.Left + 10, ARect.Top + 11);
      Canvas.MoveTo(ARect.Left + 13, ARect.Top + 8);
      Canvas.LineTo(ARect.Left + 15, ARect.Top + 11);
    end;
    Canvas.TextRect(ARect, ARect.Left + 20, ARect.Top, Items[Index]);
  end;
end;

procedure TUseUnitDialog.UnitsListBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // A hack to prevent 'O' working as shortcut for OK-button.
  // Should be removed when issue #20599 is resolved.
  if (Key = VK_O) and (Shift = []) then
    Key:=VK_UNKNOWN;
end;

procedure TUseUnitDialog.AddImplUsedUnits;
var
  i, j: Integer;
  newUnit: string;
  ImplNode: TObject;
begin
  if FImplUsedUnits.Count = 0 then Exit;
  i := 0; j := 0;
  ImplNode := FImplUsedUnits.Objects[0];
  newUnit := FImplUsedUnits[j];
  with FilterEdit.Data do
  begin
    BeginUpdate;
    try
      while i <= Count - 1 do
      begin
        if Assigned(Objects[i]) then Break;
        if CompareStr(FImplUsedUnits[j], Strings[i]) <= 0 then
        begin
          InsertObject(i, newUnit, ImplNode);
          Inc(j);
          if j >= FImplUsedUnits.Count then Exit;
          newUnit := FImplUsedUnits[j];
        end;
        Inc(i);
      end;
      if j < FImplUsedUnits.Count then
        for j := j to FImplUsedUnits.Count - 1 do
          if i < Count then
            InsertObject(i, FImplUsedUnits[j], ImplNode)
          else
            AddObject(FImplUsedUnits[j], ImplNode);
    finally
      EndUpdate;
    end;
  end;
end;

function TUseUnitDialog.GetProjUnits(SrcEdit: TSourceEditor): Boolean;
var
  ProjFile: TUnitInfo;
  CurrentUnitName, s: String;
begin
  Result := False;
  FMainUsedUnits := nil;
  FImplUsedUnits := nil;
  if SrcEdit = nil then Exit;
  Assert(Assigned(SrcEdit.CodeBuffer));
  if not CodeToolBoss.FindUsedUnitNames(SrcEdit.CodeBuffer,
                                        FMainUsedUnits,FImplUsedUnits)
  then begin
    DebugLn(['ShowUseProjUnitDialog CodeToolBoss.FindUsedUnitNames failed']);
    LazarusIDE.DoJumpToCodeToolBossError;
    Exit;
  end;
  Result := True;
  TStringList(FMainUsedUnits).CaseSensitive := False;
  TStringList(FImplUsedUnits).CaseSensitive := False;
  if SrcEdit.GetProjectFile is TUnitInfo then
    CurrentUnitName := TUnitInfo(SrcEdit.GetProjectFile).Unit_Name
  else
    CurrentUnitName := '';
  // Add available unit names to list
  ProjFile:=Project1.FirstPartOfProject;
  while ProjFile <> nil do begin
    s := ProjFile.Unit_Name;
    if s = CurrentUnitName then       // current unit
      s := '';
    if (ProjFile <> Project1.MainUnitInfo) and (s <> '') then
      if FMainUsedUnits.IndexOf(s) < 0 then
        FProjUnits.Add(s);
    ProjFile := ProjFile.NextPartOfProject;
  end;
  FProjUnits.Sorted := True;
end;

procedure TUseUnitDialog.CreateOtherUnitsList;
var
  i: Integer; curUnit: string;
  SrcEdit: TSourceEditor;
begin
  if not (Assigned(FMainUsedUnits) and Assigned(FImplUsedUnits)) then Exit;
  Screen.Cursor:=crHourGlass;
  try
    FOtherUnits := TStringList.Create;
    SrcEdit := SourceEditorManager.ActiveEditor;
    with CodeToolBoss do
      if GatherUnitNames(SrcEdit.CodeBuffer) then
      begin
        IdentifierList.Prefix := '';
        for i := 0 to IdentifierList.GetFilteredCount - 1 do
        begin
          curUnit := IdentifierList.FilteredItems[i].Identifier;
          if (FMainUsedUnits.IndexOf(curUnit) < 0)
          and (FImplUsedUnits.IndexOf(curUnit) < 0)
          and (FOtherUnits.IndexOf(curUnit) < 0) then
            FOtherUnits.AddObject(IdentifierList.FilteredItems[i].Identifier,
                                  IdentifierList.FilteredItems[i]);
        end;
      end;
    FOtherUnits.Sort;
  finally
    Screen.Cursor:=crDefault;
  end;
end;

function TUseUnitDialog.SelectedUnit: string;
var
  IdentItem: TIdentifierListItem;
  CodeBuf: TCodeBuffer;
  s: String;
begin
  with UnitsListBox do
    if ItemIndex >= 0 then
    begin
      if Items.Objects[ItemIndex] is TIdentifierListItem then
      begin
        IdentItem := TIdentifierListItem(Items.Objects[ItemIndex]);
        Result := IdentItem.Identifier;
        CodeBuf := CodeToolBoss.FindUnitSource(SourceEditorManager.ActiveEditor.CodeBuffer, Result, '');
        if Assigned(CodeBuf) then
        begin
          s := CodeToolBoss.GetSourceName(CodeBuf, True);
          if s <> '' then
            Result := s;
        end;
      end else
        Result := Items[ItemIndex];
    end else
      Result := '';
end;

function TUseUnitDialog.InterfaceSelected: Boolean;
begin
  Result:=SectionRadioGroup.ItemIndex=0;
end;

procedure TUseUnitDialog.DetermineUsesSection(ACode: TCodeBuffer; ACursorPos: TPoint);
var
  CursorPos: TCodeXYPosition;
  CleanCursorPos: Integer;
  ImplUsesNode: TCodeTreeNode;
  i: Integer;
  Tool: TCodeTool;
  ImplNode: TCodeTreeNode;
begin
  CodeToolBoss.Explore(ACode,Tool,false);
  if Tool=nil then exit;
  // collect implementation use unit nodes
  ImplUsesNode := Tool.FindImplementationUsesSection;
  if Assigned(ImplUsesNode) then
    for i := 0 to FImplUsedUnits.Count - 1 do
      FImplUsedUnits.Objects[i] := ImplUsesNode;
  // check if cursor is behind interface section
  CursorPos := CodeXYPosition(ACursorPos.X, ACursorPos.Y, ACode);
  Tool.CaretToCleanPos(CursorPos,CleanCursorPos);
  ImplNode:=Tool.FindImplementationNode;
  if (ImplNode<>nil) and (CleanCursorPos>ImplNode.StartPos) then
    SectionRadioGroup.ItemIndex := 1;
  // update
  SectionRadioGroup.OnClick(SectionRadioGroup);
end;

procedure TUseUnitDialog.FillAvailableUnitsList;
var
  curUnit: String;
  i: Integer;
begin
  if not (Assigned(FMainUsedUnits) and Assigned(FImplUsedUnits)) then Exit;
  if not Assigned(FProjUnits) then Exit;
  FilterEdit.Data.Clear;
  for i := 0 to FProjUnits.Count - 1 do
  begin
    curUnit := FProjUnits[i];
    if (FMainUsedUnits.IndexOf(curUnit) < 0)
    and (FImplUsedUnits.IndexOf(curUnit) < 0) then
      FilterEdit.Data.Add(FProjUnits[i]);
  end;
  FilterEdit.InvalidateFilter;
end;

end.

