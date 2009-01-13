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
unit options_editor_display;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Graphics, Dialogs, StdCtrls,
  Spin, LCLType, SynEdit, Controls,
  EditorOptions, LazarusIDEStrConsts, IDEOptionsIntf, SynEditMiscClasses,
  options_editor_general, IDEProcs;

type
  { TEditorDisplayOptionsFrame }

  TEditorDisplayOptionsFrame = class(TAbstractIDEOptionsEditor)
    DisableAntialiasingCheckBox: TCheckBox;
    DisplayPreview: TSynEdit;
    EditorFontButton: TButton;
    EditorFontComboBox: TComboBox;
    EditorFontGroupBox: TGroupBox;
    EditorFontHeightComboBox: TComboBox;
    EditorFontHeightLabel: TLabel;
    ExtraCharSpacingComboBox: TComboBox;
    ExtraCharSpacingLabel: TLabel;
    ExtraLineSpacingComboBox: TComboBox;
    ExtraLineSpacingLabel: TLabel;
    GutterSeparatorIndexLabel: TLabel;
    MarginAndGutterGroupBox: TGroupBox;
    RightMarginComboBox: TComboBox;
    RightMarginLabel: TLabel;
    ShowLineNumbersCheckBox: TCheckBox;
    ShowOnlyLineNumbersMultiplesOfLabel: TLabel;
    ShowOnlyLineNumbersMultiplesOfSpinEdit: TSpinEdit;
    GutterSeparatorIndexSpinBox: TSpinEdit;
    VisibleGutterCheckBox: TCheckBox;
    VisibleRightMarginCheckBox: TCheckBox;
    procedure EditorFontButtonClick(Sender: TObject);
    procedure EditorFontComboBoxEditingDone(Sender: TObject);
    procedure ComboboxOnExit(Sender: TObject);
    procedure ComboBoxOnKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ComboboxOnChange(Sender: TObject);
    procedure GeneralCheckBoxOnChange(Sender: TObject);
    procedure ShowLineNumbersCheckBoxClick(Sender: TObject);
  private
    FDialog: TAbstractOptionsEditorDialog;
    function GeneralPage: TEditorGeneralOptionsFrame; inline;

    procedure FontDialogApplyClicked(Sender: TObject);
  public
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

procedure TEditorDisplayOptionsFrame.FontDialogApplyClicked(Sender: TObject);
var
  a: Integer;
begin
  with GeneralPage do
    for a := Low(PreviewEdits) to High(PreviewEdits) do
      if PreviewEdits[a] <> nil then
        PreviewEdits[a].Font.Assign(TFontDialog(Sender).Font);

  SetComboBoxText(EditorFontComboBox, DisplayPreview.Font.Name);
  SetComboBoxText(EditorFontHeightComboBox, IntToStr(DisplayPreview.Font.Height));
end;

procedure TEditorDisplayOptionsFrame.EditorFontButtonClick(Sender: TObject);
var
  FontDialog: TFontDialog;
  NewHeight: LongInt;
begin
  FontDialog := TFontDialog.Create(nil);
  try
    with FontDialog do
    begin
      Font.Name := EditorFontComboBox.Text;
      NewHeight := StrToIntDef(EditorFontHeightComboBox.Text, DisplayPreview.Font.Height);
      RepairEditorFontHeight(NewHeight);
      Font.Height := NewHeight;
      Options := Options + [fdApplyButton];
      OnApplyClicked := @FontDialogApplyClicked;
      if Execute then
        FontDialogApplyClicked(FontDialog);
    end;
  finally
    FontDialog.Free;
  end;
end;

procedure TEditorDisplayOptionsFrame.EditorFontComboBoxEditingDone(Sender: TObject);
var
  i: Integer;
begin
  with GeneralPage do
    for i := Low(PreviewEdits) to High(PreviewEdits) do
      if PreviewEdits[i] <> nil then
        PreviewEdits[i].Font.Name := EditorFontComboBox.Text;
end;

procedure TEditorDisplayOptionsFrame.ComboboxOnExit(Sender: TObject);
var
  NewVal, a: Integer;
begin
  if Sender = EditorFontHeightComboBox then
  begin
    NewVal := StrToIntDef(EditorFontHeightComboBox.Text, DisplayPreview.Font.Height);
    RepairEditorFontHeight(NewVal);
    SetComboBoxText(EditorFontHeightComboBox, IntToStr(NewVal));
    with GeneralPage do
      for a := Low(PreviewEdits) to High(PreviewEdits) do
        if PreviewEdits[a] <> nil then
          PreviewEdits[a].Font.Height := NewVal;
  end
  else
  if Sender = ExtraCharSpacingComboBox then
  begin
    NewVal := StrToIntDef(ExtraCharSpacingComboBox.Text, DisplayPreview.ExtraCharSpacing);
    SetComboBoxText(ExtraCharSpacingComboBox, IntToStr(NewVal));
    with GeneralPage do
      for a := Low(PreviewEdits) to High(PreviewEdits) do
        if PreviewEdits[a] <> Nil then
          PreviewEdits[a].ExtraCharSpacing := NewVal;
  end
  else
  if Sender = ExtraLineSpacingComboBox then
  begin
    NewVal := StrToIntDef(ExtraLineSpacingComboBox.Text, DisplayPreview.ExtraLineSpacing);
    SetComboBoxText(ExtraLineSpacingComboBox, IntToStr(NewVal));
    with GeneralPage do
      for a := Low(PreviewEdits) to High(PreviewEdits) do
        if PreviewEdits[a] <> Nil then
          PreviewEdits[a].ExtraLineSpacing := NewVal;
  end
  else
  if Sender = RightMarginComboBox then
  begin
    NewVal := StrToIntDef(RightMarginComboBox.Text, DisplayPreview.RightEdge);
    SetComboBoxText(RightMarginComboBox, IntToStr(NewVal));
    with GeneralPage do
      for a := Low(PreviewEdits) to High(PreviewEdits) do
        if PreviewEdits[a] <> nil then
        begin
          if VisibleRightMarginCheckBox.Checked then
            PreviewEdits[a].RightEdge := NewVal
          else
            PreviewEdits[a].RightEdge := 0;
        end;
  end;
end;

procedure TEditorDisplayOptionsFrame.ComboBoxOnKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = VK_S) then
    ComboBoxOnExit(Sender);
end;

procedure TEditorDisplayOptionsFrame.ComboboxOnChange(Sender: TObject);
var
  ComboBox: TComboBox absolute Sender;
begin
  if ComboBox.Items.IndexOf(ComboBox.Text) >= 0 then
    ComboBoxOnExit(Sender);
end;

procedure TEditorDisplayOptionsFrame.GeneralCheckBoxOnChange(Sender: TObject);
var
  a: integer;
  AGeneralPage: TEditorGeneralOptionsFrame;
begin
  AGeneralPage := GeneralPage;

  if AGeneralPage = nil then
    Exit;

  with AGeneralPage do
    for a := Low(PreviewEdits) to High(PreviewEdits) do
      if PreviewEdits[a] <> nil then
      begin
        PreviewEdits[a].Gutter.Visible := VisibleGutterCheckBox.Checked;
        PreviewEdits[a].Gutter.ShowLineNumbers  := ShowLineNumbersCheckBox.Checked;
        PreviewEdits[a].Gutter.ShowOnlyLineNumbersMultiplesOf := ShowOnlyLineNumbersMultiplesOfSpinEdit.Value;
        PreviewEdits[a].Gutter.SeparatorIndex := GutterSeparatorIndexSpinBox.Value;
        if VisibleRightMarginCheckBox.Checked then
          PreviewEdits[a].RightEdge := StrToIntDef(RightMarginComboBox.Text, 80)
        else
          PreviewEdits[a].RightEdge := 0;
        if DisableAntialiasingCheckBox.Checked then
          PreviewEdits[a].Font.Quality := fqNonAntialiased
        else
          PreviewEdits[a].Font.Quality := fqDefault;
      end;
end;

procedure TEditorDisplayOptionsFrame.ShowLineNumbersCheckBoxClick(Sender: TObject);
begin
  ShowOnlyLineNumbersMultiplesOfSpinEdit.Enabled := ShowLineNumbersCheckBox.Checked;
  ShowOnlyLineNumbersMultiplesOfLabel.Enabled := ShowLineNumbersCheckBox.Checked;
end;

function TEditorDisplayOptionsFrame.GeneralPage: TEditorGeneralOptionsFrame; inline;
begin
  Result := TEditorGeneralOptionsFrame(FDialog.FindEditor(TEditorGeneralOptionsFrame));
end;

function TEditorDisplayOptionsFrame.GetTitle: String;
begin
  Result := dlgEdDisplay;
end;

procedure TEditorDisplayOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  FDialog := ADialog;

  MarginAndGutterGroupBox.Caption := dlgMarginGutter;
  VisibleRightMarginCheckBox.Caption := dlgVisibleRightMargin;
  VisibleGutterCheckBox.Caption := dlgVisibleGutter;
  ShowLineNumbersCheckBox.Caption := dlgShowLineNumbers;
  ShowOnlyLineNumbersMultiplesOfLabel.Caption := lisEveryNThLineNumber;
  GutterSeparatorIndexLabel.Caption := dlgGutterSeparatorIndex;
  RightMarginLabel.Caption := dlgRightMargin;
  EditorFontGroupBox.Caption := dlgDefaultEditorFont;
  EditorFontHeightLabel.Caption := dlgEditorFontHeight;
  ExtraCharSpacingLabel.Caption := dlgExtraCharSpacing;
  ExtraLineSpacingLabel.Caption := dlgExtraLineSpacing;
  DisableAntialiasingCheckBox.Caption := dlgDisableAntialiasing;

  with GeneralPage do
    AddPreviewEdit(DisplayPreview);
end;

procedure TEditorDisplayOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEditorOptions do
  begin
    VisibleRightMarginCheckBox.Checked := VisibleRightMargin;
    VisibleGutterCheckBox.Checked := VisibleGutter;
    ShowLineNumbersCheckBox.Checked := ShowLineNumbers;
    ShowOnlyLineNumbersMultiplesOfSpinEdit.Value := ShowOnlyLineNumbersMultiplesOf;
    GutterSeparatorIndexSpinBox.Value := GutterSeparatorIndex;
    VisibleRightMarginCheckBox.Checked := VisibleRightMargin;
    SetComboBoxText(RightMarginComboBox, IntToStr(RightMargin));
    SetComboBoxText(EditorFontComboBox, EditorFont);
    SetComboBoxText(EditorFontHeightComboBox, IntToStr(EditorFontHeight));
    SetComboBoxText(ExtraCharSpacingComboBox, IntToStr(ExtraCharSpacing));
    SetComboBoxText(ExtraLineSpacingComboBox, IntToStr(ExtraLineSpacing));
    DisableAntialiasingCheckBox.Checked := DisableAntialiasing;
  end;

  ShowOnlyLineNumbersMultiplesOfLabel.Enabled := ShowLineNumbersCheckBox.Checked;
  ShowOnlyLineNumbersMultiplesOfSpinEdit.Enabled := ShowLineNumbersCheckBox.Checked;
end;

procedure TEditorDisplayOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEditorOptions do
  begin
    VisibleRightMargin := VisibleRightMarginCheckBox.Checked;
    VisibleGutter := VisibleGutterCheckBox.Checked;
    ShowLineNumbers := ShowLineNumbersCheckBox.Checked;
    ShowOnlyLineNumbersMultiplesOf := ShowOnlyLineNumbersMultiplesOfSpinEdit.Value;
    GutterSeparatorIndex := GutterSeparatorIndexSpinBox.Value;
    VisibleRightMargin := VisibleRightMarginCheckBox.Checked;
    RightMargin := StrToIntDef(RightMarginComboBox.Text, 80);
    EditorFont := EditorFontComboBox.Text;
    EditorFontHeight := StrToIntDef(EditorFontHeightComboBox.Text, EditorFontHeight);
    ExtraCharSpacing := StrToIntDef(ExtraCharSpacingComboBox.Text, ExtraCharSpacing);
    ExtraLineSpacing := StrToIntDef(ExtraLineSpacingComboBox.Text, ExtraLineSpacing);
    DisableAntialiasing := DisableAntialiasingCheckBox.Checked;
  end;
end;

class function TEditorDisplayOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEditorOptions;
end;

initialization
  {$I options_editor_display.lrs}
  RegisterIDEOptionsEditor(GroupEditor, TEditorDisplayOptionsFrame, EdtOptionsDisplay);
end.

