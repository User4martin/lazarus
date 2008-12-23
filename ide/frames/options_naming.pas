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
unit options_naming;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, ExtCtrls,
  EnvironmentOpts, LazarusIDEStrConsts, IDEOptionsIntf;

type

  { TNamingOptionsFrame }

  TNamingOptionsFrame = class(TAbstractIDEOptionsEditor)
    AmbiguousFileActionRadioGroup: TRadioGroup;
    CharcaseFileActionRadioGroup: TRadioGroup;
    PascalFileExtRadiogroup: TRadioGroup;
  private
  public
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{ TNamingOptionsFrame }

function TNamingOptionsFrame.GetTitle: String;
begin
  Result := dlgNaming;
end;

procedure TNamingOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
var
  pe: TPascalExtType;
begin
  with PascalFileExtRadiogroup do
  begin
    Caption:=dlgPasExt;
    with Items do
    begin
      BeginUpdate;
      for pe:=Low(TPascalExtType) to High(TPascalExtType) do
        if pe<>petNone then
          Add(PascalExtension[pe]);
      EndUpdate;
    end;
    PascalFileExtRadiogroup.Columns:=PascalFileExtRadiogroup.Items.Count;
  end;

  with CharcaseFileActionRadioGroup do
  begin
    Caption:=dlgCharCaseFileAct;
    with Items do
    begin
      BeginUpdate;
      Add(dlgEnvAsk);
      Add(dlgAutoRen);
      Add(dlgnoAutomaticRenaming);
      EndUpdate;
    end;
  end;

  with AmbiguousFileActionRadioGroup do
  begin
    Caption:=dlgAmbigFileAct;
    with Items do
    begin
      BeginUpdate;
      Add(dlgEnvAsk);
      Add(dlgAutoDel);
      Add(dlgAutoRen);
      Add(dlgAmbigWarn);
      Add(dlgIgnoreVerb);
      EndUpdate;
    end;
  end;
end;

procedure TNamingOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
var
  i: integer;
begin
  with AOptions as TEnvironmentOptions do
  begin
    for i := 0 to PascalFileExtRadiogroup.Items.Count-1 do
      if PascalFileExtRadiogroup.Items[i] = PascalExtension[PascalFileExtension] then
        PascalFileExtRadiogroup.ItemIndex := i;

    CharCaseFileActionRadioGroup.ItemIndex  := ord(CharCaseFileAction);
    AmbiguousFileActionRadioGroup.ItemIndex := ord(AmbiguousFileAction);
  end;
end;

procedure TNamingOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEnvironmentOptions do
  begin
    if PascalFileExtRadiogroup.ItemIndex >= 0 then
      PascalFileExtension := PascalExtToType(PascalFileExtRadiogroup.Items[PascalFileExtRadiogroup.ItemIndex])
    else
      PascalFileExtension := petPAS;
    CharcaseFileAction  := TCharCaseFileAction(CharcaseFileActionRadioGroup.ItemIndex);
    AmbiguousFileAction := TAmbiguousFileAction(AmbiguousFileActionRadioGroup.ItemIndex);
  end;
end;

class function TNamingOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEnvironmentOptions;
end;

initialization
  {$I options_naming.lrs}
  RegisterIDEOptionsEditor(GroupEnvironment, TNamingOptionsFrame, EnvOptionsNaming);
end.

