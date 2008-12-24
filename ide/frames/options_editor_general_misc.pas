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
unit options_editor_general_misc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Graphics, LCLProc, LCLType,
  StdCtrls, SynEdit, Controls, ExtCtrls,
  EditorOptions, LazarusIDEStrConsts, IDEProcs, IDEOptionsIntf, options_editor_general;

type
  { TEditorGeneralMiscOptionsFrame }

  TEditorGeneralMiscOptionsFrame = class(TAbstractIDEOptionsEditor)
    EditorOptionsGroupBox: TCheckGroup;
    procedure EditorOptionsGroupBoxItemClick(Sender: TObject; Index: integer);
  private
    FDialog: TAbstractOptionsEditorDialog;
    function GeneralPage: TEditorGeneralOptionsFrame; inline;
  public
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{ TEditorGeneralMiscOptionsFrame }

function TEditorGeneralMiscOptionsFrame.GetTitle: String;
begin
  Result := dlgEdMisc;
end;

procedure TEditorGeneralMiscOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  FDialog := ADialog;
  EditorOptionsGroupBox.Caption := lismenueditoroptions;
  with EditorOptionsGroupBox do
  begin
    // selections
    Items.Add(dlgAltSetClMode);
    // visual effects
    Items.Add(dlgShowGutterHints);
    Items.Add(lisShowSpecialCharacters);
    // spaces
    Items.Add(dlgTrimTrailingSpaces);
    // mouse
    Items.Add(dlgCloseButtonsNotebook);
    // copying
    Items.Add(dlgFindTextatCursor);
    Items.Add(dlgCopyWordAtCursorOnCopyNone);
  end;
end;

procedure TEditorGeneralMiscOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEditorOptions do
  begin
    with EditorOptionsGroupBox do
    begin
      Checked[Items.IndexOf(dlgAltSetClMode)] := eoAltSetsColumnMode in SynEditOptions;
      Checked[Items.IndexOf(lisShowSpecialCharacters)] := eoShowSpecialChars in SynEditOptions;
      Checked[Items.IndexOf(dlgTrimTrailingSpaces)] := eoTrimTrailingSpaces in SynEditOptions;
      Checked[Items.IndexOf(dlgCloseButtonsNotebook)] := ShowTabCloseButtons;
      Checked[Items.IndexOf(dlgShowGutterHints)] := ShowGutterHints;
      Checked[Items.IndexOf(dlgFindTextatCursor)] := FindTextAtCursor;
      Checked[Items.IndexOf(dlgCopyWordAtCursorOnCopyNone)] := CopyWordAtCursorOnCopyNone;
    end;
  end;
end;

procedure TEditorGeneralMiscOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);

  procedure UpdateOptionFromBool(AValue: Boolean; AnOption: TSynEditorOption); overload;
  begin
    if AValue then
      TEditorOptions(AOptions).SynEditOptions := TEditorOptions(AOptions).SynEditOptions + [AnOption]
    else
      TEditorOptions(AOptions).SynEditOptions := TEditorOptions(AOptions).SynEditOptions - [AnOption];
  end;

  procedure UpdateOption(const CheckBoxName: String; AnOption: TSynEditorOption);
  var
    i: integer;
  begin
    i := EditorOptionsGroupBox.Items.IndexOf(CheckBoxName);
    UpdateOptionFromBool(EditorOptionsGroupBox.Checked[i], AnOption);
  end;

begin
  with AOptions as TEditorOptions do
  begin
    UpdateOption(dlgAltSetClMode, eoAltSetsColumnMode);
    UpdateOption(lisShowSpecialCharacters, eoShowSpecialChars);
    UpdateOption(dlgTrimTrailingSpaces, eoTrimTrailingSpaces);
    ShowTabCloseButtons := CheckGroupItemChecked(EditorOptionsGroupBox, dlgCloseButtonsNotebook);
    CopyWordAtCursorOnCopyNone := CheckGroupItemChecked(EditorOptionsGroupBox, dlgCopyWordAtCursorOnCopyNone);
    ShowGutterHints := CheckGroupItemChecked(EditorOptionsGroupBox, dlgShowGutterHints);
    FindTextAtCursor := CheckGroupItemChecked(EditorOptionsGroupBox, dlgFindTextatCursor);
  end;
end;

class function TEditorGeneralMiscOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEditorOptions;
end;

procedure TEditorGeneralMiscOptionsFrame.EditorOptionsGroupBoxItemClick(
  Sender: TObject; Index: integer);

  procedure SetOption(const CheckBoxName: String; AnOption: TSynEditorOption);
  var
    i: LongInt;
    a: Integer;
  begin
    i := EditorOptionsGroupBox.Items.IndexOf(CheckBoxName);
    if i < 0 then
      Exit;

    with GeneralPage do
      for a := Low(PreviewEdits) to High(PreviewEdits) do
      begin
        if PreviewEdits[a] <> nil then
          if EditorOptionsGroupBox.Checked[i] then
            PreviewEdits[a].Options := PreviewEdits[a].Options + [AnOption]
          else
            PreviewEdits[a].Options := PreviewEdits[a].Options - [AnOption];
      end;
  end;

begin
  SetOption(dlgAltSetClMode, eoAltSetsColumnMode);
  SetOption(lisShowSpecialCharacters, eoShowSpecialChars);
  SetOption(dlgTrimTrailingSpaces, eoTrimTrailingSpaces);
end;

function TEditorGeneralMiscOptionsFrame.GeneralPage: TEditorGeneralOptionsFrame;
  inline;
begin
  Result := TEditorGeneralOptionsFrame(FDialog.FindEditor(TEditorGeneralOptionsFrame));
end;

initialization
  {$I options_editor_general_misc.lrs}
  RegisterIDEOptionsEditor(GroupEditor, TEditorGeneralMiscOptionsFrame, EdtOptionsGeneralMisc, EdtOptionsGeneral);
end.

