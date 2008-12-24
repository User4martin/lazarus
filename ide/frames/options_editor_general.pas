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
}
unit options_editor_general;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Graphics, LCLProc, LCLType,
  StdCtrls, SynEdit, Controls, ExtCtrls,
  EditorOptions, LazarusIDEStrConsts, IDEProcs, IDEOptionsIntf;

type
  TPreviewEditor = TSynEdit;
  { TEditorGeneralOptionsFrame }

  TEditorGeneralOptionsFrame = class(TAbstractIDEOptionsEditor)
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    Bevel5: TBevel;
    BlockIndentComboBox: TComboBox;
    BlockIndentLabel: TLabel;
    AutoIndentCheckBox: TCheckBox;
    KeepCursorXCheckBox: TCheckBox;
    PersistentCursorCheckBox: TCheckBox;
    AlwaysVisibleCursorCheckBox: TCheckBox;
    CursorSkipsSelectionCheckBox: TCheckBox;
    RightMouseMovesCursorCheckBox: TCheckBox;
    HomeKeyJumpsToNearestStartCheckBox: TCheckBox;
    DoubleClickLineCheckBox: TCheckBox;
    CursorGroupLabel: TLabel;
    MouseLinksCheckBox: TCheckBox;
    DragDropEdCheckBox: TCheckBox;
    DropFilesCheckBox: TCheckBox;
    MouseGroupLabel: TLabel;
    TabIndentBlocksCheckBox: TCheckBox;
    SmartTabsCheckBox: TCheckBox;
    TabsToSpacesCheckBox: TCheckBox;
    HalfPageScrollCheckBox: TCheckBox;
    ScrollPastEndFileCheckBox: TCheckBox;
    ScrollPastEndLineCheckBox: TCheckBox;
    ScrollByOneLessCheckBox: TCheckBox;
    UndoGroupLabel: TLabel;
    UndoAfterSaveCheckBox: TCheckBox;
    GroupUndoCheckBox: TCheckBox;
    TabWidthsComboBox: TComboBox;
    TabWidthsLabel: TLabel;
    ScrollGroupLabel: TLabel;
    IndentsTabsGroupLabel: TLabel;
    UndoLimitComboBox: TComboBox;
    UndoLimitLabel: TLabel;
    procedure AlwaysVisibleCursorCheckBoxChange(Sender: TObject);
    procedure AutoIndentCheckBoxChange(Sender: TObject);
    procedure ComboboxOnChange(Sender: TObject);
    procedure ComboboxOnKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CursorSkipsSelectionCheckBoxChange(Sender: TObject);
    procedure DoubleClickLineCheckBoxChange(Sender: TObject);
    procedure DragDropEdCheckBoxChange(Sender: TObject);
    procedure DropFilesCheckBoxChange(Sender: TObject);
    procedure ComboBoxOnExit(Sender: TObject);
    procedure GroupUndoCheckBoxChange(Sender: TObject);
    procedure HalfPageScrollCheckBoxChange(Sender: TObject);
    procedure HomeKeyJumpsToNearestStartCheckBoxChange(Sender: TObject);
    procedure KeepCursorXCheckBoxChange(Sender: TObject);
    procedure MouseLinksCheckBoxChange(Sender: TObject);
    procedure PersistentCursorCheckBoxChange(Sender: TObject);
    procedure RightMouseMovesCursorCheckBoxChange(Sender: TObject);
    procedure ScrollByOneLessCheckBoxChange(Sender: TObject);
    procedure ScrollPastEndFileCheckBoxChange(Sender: TObject);
    procedure ScrollPastEndLineCheckBoxChange(Sender: TObject);
    procedure SmartTabsCheckBoxChange(Sender: TObject);
    procedure TabIndentBlocksCheckBoxChange(Sender: TObject);
    procedure TabsToSpacesCheckBoxChange(Sender: TObject);
  public
    PreviewEdits: array of TPreviewEditor;
    procedure SetPreviewOption(AValue: Boolean; AnOption: TSynEditorOption); overload;
    procedure SetPreviewOption(AValue: Boolean; AnOption: TSynEditorOption2); overload;

    constructor Create(AOwner: TComponent); override;
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{ TEditorGeneralOptionsFrame }

function TEditorGeneralOptionsFrame.GetTitle: String;
begin
  Result := lisMenuInsertGeneral;
end;

procedure TEditorGeneralOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  BlockIndentLabel.Caption := dlgBlockIndent;
  TabWidthsLabel.Caption := dlgTabWidths;

  // undo
  UndoGroupLabel.Caption := dlgUndoGroupOptions;
  UndoAfterSaveCheckBox.Caption := dlgUndoAfterSave;
  GroupUndoCheckBox.Caption := dlgGroupUndo;
  UndoLimitLabel.Caption := dlgUndoLimit;

  // scroll
  ScrollGroupLabel.Caption := dlgScrollGroupOptions;
  HalfPageScrollCheckBox.Caption := dlgHalfPageScroll;
  ScrollByOneLessCheckBox.Caption := dlgScrollByOneLess;
  ScrollPastEndFileCheckBox.Caption := dlgScrollPastEndFile;
  ScrollPastEndLineCheckBox.Caption := dlgScrollPastEndLine;

  // indents, tabs
  IndentsTabsGroupLabel.Caption := dlgIndentsTabsGroupOptions;
  AutoIndentCheckBox.Caption := dlgAutoIndent;
  TabIndentBlocksCheckBox.Caption := dlgTabIndent;
  SmartTabsCheckBox.Caption := dlgSmartTabs;
  TabsToSpacesCheckBox.Caption := dlgTabsToSpaces;

  // mouse, drag&drop
  MouseGroupLabel.Caption := dlgMouseGroupOptions;
  DoubleClickLineCheckBox.Caption := dlgDoubleClickLine;
  MouseLinksCheckBox.Caption := dlgMouseLinks;
  DragDropEdCheckBox.Caption := dlgDragDropEd;
  DropFilesCheckBox.Caption := dlgDropFiles;

  // caret + key navigation
  CursorGroupLabel.Caption := dlgCursorGroupOptions;
  KeepCursorXCheckBox.Caption := dlgKeepCursorX;
  PersistentCursorCheckBox.Caption := dlgPersistentCursor;
  AlwaysVisibleCursorCheckBox.Caption := dlgAlwaysVisibleCursor;
  CursorSkipsSelectionCheckBox.Caption := dlgCursorSkipsSelection;
  RightMouseMovesCursorCheckBox.Caption := dlgRightMouseMovesCursor;
  HomeKeyJumpsToNearestStartCheckBox.Caption := dlgHomeKeyJumpsToNearestStart;
end;

procedure TEditorGeneralOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
var
  i: integer;
begin
  with AOptions as TEditorOptions do
  begin
    SetComboBoxText(BlockIndentComboBox, IntToStr(BlockIndent));
    SetComboBoxText(TabWidthsComboBox, IntToStr(TabWidth));

    // undo
    UndoAfterSaveCheckBox.Checked := UndoAfterSave;
    GroupUndoCheckBox.Checked := eoGroupUndo in SynEditOptions;
    SetComboBoxText(UndoLimitComboBox, IntToStr(UndoLimit));

    // scroll
    HalfPageScrollCheckBox.Checked := eoHalfPageScroll in SynEditOptions;
    ScrollByOneLessCheckBox.Checked := eoScrollByOneLess in SynEditOptions;
    ScrollPastEndFileCheckBox.Checked := eoScrollPastEoF in SynEditOptions;
    ScrollPastEndLineCheckBox.Checked := eoScrollPastEoL in SynEditOptions;

    // tabs, indents
    AutoIndentCheckBox.Checked := eoAutoIndent in SynEditOptions;
    TabIndentBlocksCheckBox.Checked := eoTabIndent in SynEditOptions;
    SmartTabsCheckBox.Checked := eoSmartTabs in SynEditOptions;
    TabsToSpacesCheckBox.Checked := eoTabsToSpaces in SynEditOptions;

    // mouse
    DoubleClickLineCheckBox.Checked := eoDoubleClickSelectsLine in SynEditOptions;
    MouseLinksCheckBox.Checked := CtrlMouseLinks;
    DragDropEdCheckBox.Checked := eoDragDropEditing in SynEditOptions;
    DropFilesCheckBox.Checked := eoDropFiles in SynEditOptions;

    // cursor
    KeepCursorXCheckBox.Checked := eoKeepCaretX in SynEditOptions;
    PersistentCursorCheckBox.Checked := eoPersistentCaret in SynEditOptions;
    AlwaysVisibleCursorCheckBox.Checked := eoAlwaysVisibleCaret in SynEditOptions2;
    CursorSkipsSelectionCheckBox.Checked := eoCaretSkipsSelection in SynEditOptions2;
    RightMouseMovesCursorCheckBox.Checked := eoRightMouseMovesCursor in SynEditOptions;
    HomeKeyJumpsToNearestStartCheckBox.Checked := eoEnhanceHomeKey in SynEditOptions;

    for i := Low(PreviewEdits) to High(PreviewEdits) do
      if PreviewEdits[i] <> nil then
        GetSynEditPreviewSettings(PreviewEdits[i]);
  end;
end;

procedure TEditorGeneralOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);

  procedure UpdateOptionFromBool(AValue: Boolean; AnOption: TSynEditorOption); overload;
  begin
    if AValue then
      TEditorOptions(AOptions).SynEditOptions := TEditorOptions(AOptions).SynEditOptions + [AnOption]
    else
      TEditorOptions(AOptions).SynEditOptions := TEditorOptions(AOptions).SynEditOptions - [AnOption];
  end;

  procedure UpdateOptionFromBool(AValue: Boolean; AnOption: TSynEditorOption2); overload;
  begin
    if AValue then
      TEditorOptions(AOptions).SynEditOptions2 := TEditorOptions(AOptions).SynEditOptions2 + [AnOption]
    else
      TEditorOptions(AOptions).SynEditOptions2 := TEditorOptions(AOptions).SynEditOptions2 - [AnOption];
  end;

var
  i: integer;
begin
  with AOptions as TEditorOptions do
  begin
    // undo
    UndoAfterSave := UndoAfterSaveCheckBox.Checked;
    UpdateOptionFromBool(GroupUndoCheckBox.Checked, eoGroupUndo);
    i := StrToIntDef(UndoLimitComboBox.Text, 32767);
    if i < 1 then
      i := 1;
    if i > 32767 then
      i := 32767;
    UndoLimit := i;

    // scroll
    UpdateOptionFromBool(HalfPageScrollCheckBox.Checked, eoHalfPageScroll);
    UpdateOptionFromBool(ScrollByOneLessCheckBox.Checked, eoScrollByOneLess);
    UpdateOptionFromBool(ScrollPastEndFileCheckBox.Checked, eoScrollPastEoF);
    UpdateOptionFromBool(ScrollPastEndLineCheckBox.Checked, eoScrollPastEoL);

    // tabs, indents
    UpdateOptionFromBool(AutoIndentCheckBox.Checked, eoAutoIndent);
    UpdateOptionFromBool(TabIndentBlocksCheckBox.Checked, eoTabIndent);
    UpdateOptionFromBool(SmartTabsCheckBox.Checked, eoSmartTabs);
    UpdateOptionFromBool(TabsToSpacesCheckBox.Checked, eoTabsToSpaces);

    i := StrToIntDef(TabWidthsComboBox.Text, 2);
    if i < 1 then
      i := 1;
    if i > 20 then
      i := 20;
    TabWidth := i;

    i := StrToIntDef(BlockIndentComboBox.Text, 2);
    if i < 1 then
      i := 1;
    if i > 20 then
      i := 20;
    BlockIndent := i;

    // mouse
    UpdateOptionFromBool(DoubleClickLineCheckBox.Checked, eoDoubleClickSelectsLine);
    CtrlMouseLinks := MouseLinksCheckBox.Checked;
    UpdateOptionFromBool(DragDropEdCheckBox.Checked, eoDragDropEditing);
    UpdateOptionFromBool(DropFilesCheckBox.Checked, eoDropFiles);

    // cursor
    UpdateOptionFromBool(KeepCursorXCheckBox.Checked, eoKeepCaretX);
    UpdateOptionFromBool(PersistentCursorCheckBox.Checked, eoPersistentCaret);
    UpdateOptionFromBool(AlwaysVisibleCursorCheckBox.Checked, eoAlwaysVisibleCaret);
    UpdateOptionFromBool(CursorSkipsSelectionCheckBox.Checked, eoCaretSkipsSelection);
    UpdateOptionFromBool(RightMouseMovesCursorCheckBox.Checked, eoRightMouseMovesCursor);
    UpdateOptionFromBool(HomeKeyJumpsToNearestStartCheckBox.Checked, eoEnhanceHomeKey);
  end;
end;

class function TEditorGeneralOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEditorOptions;
end;

procedure TEditorGeneralOptionsFrame.SetPreviewOption(AValue: Boolean; AnOption: TSynEditorOption);
var
  a: Integer;
begin
  for a := Low(PreviewEdits) to High(PreviewEdits) do
  begin
    if PreviewEdits[a] <> nil then
      if AValue then
        PreviewEdits[a].Options := PreviewEdits[a].Options + [AnOption]
      else
        PreviewEdits[a].Options := PreviewEdits[a].Options - [AnOption];
  end;
end;

procedure TEditorGeneralOptionsFrame.SetPreviewOption(AValue: Boolean; AnOption: TSynEditorOption2);
var
  a: Integer;
begin
  for a := Low(PreviewEdits) to High(PreviewEdits) do
  begin
    if PreviewEdits[a] <> nil then
      if AValue then
        PreviewEdits[a].Options2 := PreviewEdits[a].Options2 + [AnOption]
      else
        PreviewEdits[a].Options2 := PreviewEdits[a].Options2 - [AnOption];
  end;
end;

procedure TEditorGeneralOptionsFrame.ComboboxOnChange(Sender: TObject);
var
  ComboBox: TComboBox absolute Sender;
begin
  if ComboBox.Items.IndexOf(ComboBox.Text) >= 0 then
    ComboBoxOnExit(Sender);
end;

procedure TEditorGeneralOptionsFrame.AutoIndentCheckBoxChange(Sender: TObject);
begin
  SetPreviewOption(AutoIndentCheckBox.Checked, eoAutoIndent);
end;

procedure TEditorGeneralOptionsFrame.AlwaysVisibleCursorCheckBoxChange(
  Sender: TObject);
begin
  SetPreviewOption(AlwaysVisibleCursorCheckBox.Checked, eoAlwaysVisibleCaret);
end;

procedure TEditorGeneralOptionsFrame.ComboboxOnKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = VK_S) then
    ComboBoxOnExit(Sender);
end;

procedure TEditorGeneralOptionsFrame.CursorSkipsSelectionCheckBoxChange(
  Sender: TObject);
begin
  SetPreviewOption(CursorSkipsSelectionCheckBox.Checked, eoCaretSkipsSelection);
end;

procedure TEditorGeneralOptionsFrame.DoubleClickLineCheckBoxChange(
  Sender: TObject);
begin
  SetPreviewOption(DoubleClickLineCheckBox.Checked, eoDoubleClickSelectsLine);
end;

procedure TEditorGeneralOptionsFrame.DragDropEdCheckBoxChange(Sender: TObject);
begin
  SetPreviewOption(DragDropEdCheckBox.Checked, eoDragDropEditing);
end;

procedure TEditorGeneralOptionsFrame.DropFilesCheckBoxChange(Sender: TObject);
begin
  SetPreviewOption(DropFilesCheckBox.Checked, eoDropFiles);
end;

procedure TEditorGeneralOptionsFrame.ComboBoxOnExit(Sender: TObject);
var
  NewVal, a: Integer;
begin
  if Sender = BlockIndentComboBox then
  begin
    NewVal := StrToIntDef(BlockIndentComboBox.Text, PreviewEdits[1].BlockIndent);
    SetComboBoxText(BlockIndentComboBox, IntToStr(NewVal));
    for a := Low(PreviewEdits) to High(PreviewEdits) do
      if PreviewEdits[a] <> nil then
        PreviewEdits[a].BlockIndent := NewVal;
  end
  else
  if Sender = TabWidthsComboBox then
  begin
    NewVal := StrToIntDef(TabWidthsComboBox.Text, PreviewEdits[1].TabWidth);
    SetComboBoxText(TabWidthsComboBox, IntToStr(NewVal));
    for a := Low(PreviewEdits) to High(PreviewEdits) do
      if PreviewEdits[a] <> nil then
        PreviewEdits[a].TabWidth := NewVal;
  end
end;

procedure TEditorGeneralOptionsFrame.GroupUndoCheckBoxChange(Sender: TObject);
begin
  SetPreviewOption(GroupUndoCheckBox.Checked, eoGroupUndo);
end;

procedure TEditorGeneralOptionsFrame.HalfPageScrollCheckBoxChange(
  Sender: TObject);
begin
  SetPreviewOption(HalfPageScrollCheckBox.Checked, eoHalfPageScroll);
end;

procedure TEditorGeneralOptionsFrame.HomeKeyJumpsToNearestStartCheckBoxChange(
  Sender: TObject);
begin
  SetPreviewOption(HomeKeyJumpsToNearestStartCheckBox.Checked, eoEnhanceHomeKey);
end;

procedure TEditorGeneralOptionsFrame.KeepCursorXCheckBoxChange(Sender: TObject);
begin
  SetPreviewOption(KeepCursorXCheckBox.Checked, eoKeepCaretX);
end;

procedure TEditorGeneralOptionsFrame.MouseLinksCheckBoxChange(Sender: TObject);
begin
  SetPreviewOption(HalfPageScrollCheckBox.Checked, eoShowCtrlMouseLinks);
end;

procedure TEditorGeneralOptionsFrame.PersistentCursorCheckBoxChange(
  Sender: TObject);
begin
  SetPreviewOption(PersistentCursorCheckBox.Checked, eoPersistentCaret);
end;

procedure TEditorGeneralOptionsFrame.RightMouseMovesCursorCheckBoxChange(
  Sender: TObject);
begin
  SetPreviewOption(RightMouseMovesCursorCheckBox.Checked, eoRightMouseMovesCursor);
end;

procedure TEditorGeneralOptionsFrame.ScrollByOneLessCheckBoxChange(
  Sender: TObject);
begin
  SetPreviewOption(ScrollByOneLessCheckBox.Checked, eoScrollByOneLess);
end;

procedure TEditorGeneralOptionsFrame.ScrollPastEndFileCheckBoxChange(
  Sender: TObject);
begin
  SetPreviewOption(ScrollPastEndFileCheckBox.Checked, eoScrollPastEoF);
end;

procedure TEditorGeneralOptionsFrame.ScrollPastEndLineCheckBoxChange(
  Sender: TObject);
begin
  SetPreviewOption(ScrollPastEndLineCheckBox.Checked, eoScrollPastEoL);
end;

procedure TEditorGeneralOptionsFrame.SmartTabsCheckBoxChange(Sender: TObject);
begin
  SetPreviewOption(SmartTabsCheckBox.Checked, eoSmartTabs);
end;

procedure TEditorGeneralOptionsFrame.TabIndentBlocksCheckBoxChange(
  Sender: TObject);
begin
  SetPreviewOption(TabIndentBlocksCheckBox.Checked, eoTabIndent);
end;

procedure TEditorGeneralOptionsFrame.TabsToSpacesCheckBoxChange(Sender: TObject
  );
begin
  SetPreviewOption(TabsToSpacesCheckBox.Checked, eoTabsToSpaces);
end;

constructor TEditorGeneralOptionsFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  PreviewEdits := nil;
end;

initialization
  {$I options_editor_general.lrs}
  RegisterIDEOptionsEditor(GroupEditor, TEditorGeneralOptionsFrame, EdtOptionsGeneral);
end.

