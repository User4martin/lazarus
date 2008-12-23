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
unit options_codetools_identifiercompletion;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, StdCtrls,
  CodeToolsOptions, LazarusIDEStrConsts, IDEOptionsIntf;

type

  { TCodetoolsIndentifierComplietionOptionsFrame }

  TCodetoolsIndentifierComplietionOptionsFrame = class(TAbstractIDEOptionsEditor)
    ICAddAssignOperatorCheckBox: TCheckBox;
    ICAddSemicolonCheckBox: TCheckBox;
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

{ TCodetoolsIndentifierComplietionOptionsFrame }

function TCodetoolsIndentifierComplietionOptionsFrame.GetTitle: String;
begin
  Result := dlgIdentifierCompletion;
end;

procedure TCodetoolsIndentifierComplietionOptionsFrame.Setup(
  ADialog: TAbstractOptionsEditorDialog);
begin
  with ICAddSemicolonCheckBox do
    Caption:=dlgAddSemicolon;
  with ICAddAssignOperatorCheckBox do
    Caption:=dlgAddAssignmentOperator;
end;

procedure TCodetoolsIndentifierComplietionOptionsFrame.ReadSettings(
  AOptions: TAbstractIDEOptions);
begin
  with AOptions as TCodeToolsOptions do
  begin
    ICAddSemicolonCheckBox.Checked := IdentComplAddSemicolon;
    ICAddAssignOperatorCheckBox.Checked := IdentComplAddAssignOperator;
  end;
end;

procedure TCodetoolsIndentifierComplietionOptionsFrame.WriteSettings(
  AOptions: TAbstractIDEOptions);
begin
  with AOptions as TCodeToolsOptions do
  begin
    IdentComplAddSemicolon := ICAddSemicolonCheckBox.Checked;
    IdentComplAddAssignOperator := ICAddAssignOperatorCheckBox.Checked;
  end;
end;

class function TCodetoolsIndentifierComplietionOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TCodeToolsOptions;
end;

initialization
  {$I options_codetools_identifiercompletion.lrs}
  RegisterIDEOptionsEditor(GroupCodetools, TCodetoolsIndentifierComplietionOptionsFrame, CdtOptionsIdentCompletion);
end.

