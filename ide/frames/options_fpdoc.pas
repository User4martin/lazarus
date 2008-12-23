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
unit options_fpdoc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Dialogs, StdCtrls,
  EnvironmentOpts, LazarusIDEStrConsts, IDEProcs, IDEOptionsIntf;

type

  { TFpDocOptionsFrame }

  TFpDocOptionsFrame = class(TAbstractIDEOptionsEditor)
    LazDocAddPathButton: TButton;
    LazDocBrowseButton: TButton;
    LazDocDeletePathButton: TButton;
    LazDocListBox: TListBox;
    LazDocPathEdit: TEdit;
    LazDocPathsGroupBox: TGroupBox;
    SelectDirectoryDialog: TSelectDirectoryDialog;
    procedure LazDocDeletePathButtonClick(Sender: TObject);
    procedure LazDocAddPathButtonClick(Sender: TObject);
    procedure LazDocBrowseButtonClick(Sender: TObject);
  private
  public
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{ TFpDocOptionsFrame }

function TFpDocOptionsFrame.GetTitle: String;
begin
  Result := lisFPDocEditor;
end;

procedure TFpDocOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  LazDocPathsGroupBox.Caption := lisCodeHelpPathsGroupBox;
  LazDocAddPathButton.Caption := lisCodeHelpAddPathButton;
  LazDocDeletePathButton.Caption := lisCodeHelpDeletePathButton;

  LazDocPathEdit.Clear;
end;

procedure TFpDocOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEnvironmentOptions do
    SplitString(LazDocPaths, ';', LazDocListBox.Items);
end;

procedure TFpDocOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEnvironmentOptions do
    LazDocPaths := StringListToText(LazDocListBox.Items, ';', true);
end;

procedure TFpDocOptionsFrame.LazDocAddPathButtonClick(Sender: TObject);
begin
  if LazDocPathEdit.Text <> '' then
    LazDocListBox.Items.Add(LazDocPathEdit.Text);
end;

procedure TFpDocOptionsFrame.LazDocBrowseButtonClick(Sender: TObject);
begin
  if SelectDirectoryDialog.Execute then
    LazDocPathEdit.Text := SelectDirectoryDialog.FileName;
end;

procedure TFpDocOptionsFrame.LazDocDeletePathButtonClick(Sender: TObject);
begin
  LazDocListBox.Items.Delete(LazDocListBox.ItemIndex);
end;

class function TFpDocOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEnvironmentOptions;
end;

initialization
  {$I options_fpdoc.lrs}
  RegisterIDEOptionsEditor(GroupEnvironment, TFpDocOptionsFrame, EnvOptionsFpDoc);
end.

