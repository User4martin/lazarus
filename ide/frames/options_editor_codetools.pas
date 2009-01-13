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
unit options_editor_codetools;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, StdCtrls, ComCtrls,
  EditorOptions, LazarusIDEStrConsts, IDEOptionsIntf;

type
  { TEditorCodetoolsOptionsFrame }

  TEditorCodetoolsOptionsFrame = class(TAbstractIDEOptionsEditor)
    AutoCodeParametersCheckBox: TCheckBox;
    AutoDelayLabel: TLabel;
    AutoDelayMaxLabel: TLabel;
    AutoDelayMinLabel: TLabel;
    AutoDelayTrackBar: TTrackBar;
    AutoIdentifierCompletionCheckBox: TCheckBox;
    AutoToolTipExprEvalCheckBox: TCheckBox;
    MarkupWordDelayLabel: TLabel;
    MarkupWordFullCheckBox: TCheckBox;
    MarkupWordMaxLabel: TLabel;
    MarkupWordMinLabel: TLabel;
    MarkupWordEnabledCheckBox: TCheckBox;
    MarkupWordTimeTrackBar: TTrackBar;
    AutoToolTipSymbToolsCheckBox: TCheckBox;
    AutoRemoveEmptyMethodsOnSave: TCheckBox;
  private
    { private declarations }
  public
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{ TEditorCodetoolsOptionsFrame }

function TEditorCodetoolsOptionsFrame.GetTitle: String;
begin
  Result := lisAutomaticFeatures;
end;

procedure TEditorCodetoolsOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  AutoIdentifierCompletionCheckBox.Caption := dlgEdIdComlet;
  AutoCodeParametersCheckBox.Caption := dlgEdCodeParams;
  AutoToolTipExprEvalCheckBox.Caption := dlgTooltipEval;
  AutoToolTipSymbToolsCheckBox.Caption := dlgTooltipTools;
  AutoRemoveEmptyMethodsOnSave.Caption := dlgAutoRemoveEmptyMethods;

  AutoDelayLabel.Caption := dlgEdDelay;
  AutoDelayMinLabel.Caption := '0.5 ' + DlgTimeSecondUnit;
  AutoDelayMaxLabel.Caption := '4.0 ' + dlgTimeSecondUnit;

  MarkupWordEnabledCheckBox.Caption := dlgMarkupWordEnabled;
  MarkupWordFullCheckBox.Caption := dlgMarkupWordFull;
  MarkupWordDelayLabel.Caption := dlgEdDelay;
  MarkupWordMinLabel.Caption := '0.5 ' + DlgTimeSecondUnit;;
  MarkupWordMaxLabel.Caption := '4.0 ' + DlgTimeSecondUnit;;
end;

procedure TEditorCodetoolsOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEditorOptions do
  begin
    AutoIdentifierCompletionCheckBox.Checked := AutoIdentifierCompletion;
    AutoCodeParametersCheckBox.Checked := AutoCodeParameters;
    AutoToolTipExprEvalCheckBox.Checked := AutoToolTipExprEval;
    AutoToolTipSymbToolsCheckBox.Checked := AutoToolTipSymbTools;
    AutoDelayTrackBar.Position := AutoDelayInMSec;
    AutoRemoveEmptyMethodsOnSave.Checked := AutoRemoveEmptyMethods;
    MarkupWordEnabledCheckBox.Checked := MarkupCurWordEnabled;
    MarkupWordFullCheckBox.Checked := MarkupCurWordFull;
    MarkupWordTimeTrackBar.Position := MarkupCurWordTime;
  end;
end;

procedure TEditorCodetoolsOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEditorOptions do
  begin
    AutoIdentifierCompletion := AutoIdentifierCompletionCheckBox.Checked;
    AutoCodeParameters := AutoCodeParametersCheckBox.Checked;
    AutoToolTipExprEval := AutoToolTipExprEvalCheckBox.Checked;
    AutoToolTipSymbTools := AutoToolTipSymbToolsCheckBox.Checked;
    AutoDelayInMSec := AutoDelayTrackBar.Position;
    AutoRemoveEmptyMethods := AutoRemoveEmptyMethodsOnSave.Checked;
    MarkupCurWordEnabled := MarkupWordEnabledCheckBox.Checked;
    MarkupCurWordFull := MarkupWordFullCheckBox.Checked;
    MarkupCurWordTime := MarkupWordTimeTrackBar.Position;
  end;
end;

class function TEditorCodetoolsOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEditorOptions;
end;

initialization
  {$I options_editor_codetools.lrs}
  RegisterIDEOptionsEditor(GroupEditor, TEditorCodetoolsOptionsFrame, EdtOptionsCodetools);
end.

