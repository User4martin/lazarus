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
unit options_codetools_codecreation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, ExtCtrls, StdCtrls,
  SourceChanger, CodeToolsOptions, LazarusIDEStrConsts, IDEOptionsIntf;

type

  { TCodetoolsCodeCreationOptionsFrame }

  TCodetoolsCodeCreationOptionsFrame = class(TAbstractIDEOptionsEditor)
    ClassHeaderCommentsCheckBox: TCheckBox;
    ClassPartInsertPolicyRadioGroup: TRadioGroup;
    ForwardProcsInsertPolicyRadioGroup: TRadioGroup;
    ForwardProcsKeepOrderCheckBox: TCheckBox;
    MethodInsertPolicyRadioGroup: TRadioGroup;
    MixMethodsAndPropertiesCheckBox: TCheckBox;
    PrivateVariablePrefixEdit: TEdit;
    PrivateVariablePrefixLabel: TLabel;
    PropertyCompletionCheckBox: TCheckBox;
    PropertyCompletionGroupBox: TGroupBox;
    PropertyReadIdentPrefixEdit: TEdit;
    PropertyReadIdentPrefixLabel: TLabel;
    PropertyStoredIdentPostfixEdit: TEdit;
    PropertyStoredIdentPostfixLabel: TLabel;
    PropertyWriteIdentPrefixEdit: TEdit;
    PropertyWriteIdentPrefixLabel: TLabel;
    SetPropertyVariablenameEdit: TEdit;
    SetPropertyVariablenameLabel: TLabel;
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

{ TCodetoolsCodeCreationOptionsFrame }

function TCodetoolsCodeCreationOptionsFrame.GetTitle: String;
begin
  Result := dlgCodeCreation;
end;

procedure TCodetoolsCodeCreationOptionsFrame.Setup(
  ADialog: TAbstractOptionsEditorDialog);
begin
  with ClassPartInsertPolicyRadioGroup do begin
    Caption:=dlgClassInsertPolicy;
    with Items do begin
      BeginUpdate;
      Add(dlgAlphabetically);
      Add(dlgCDTLast);
      EndUpdate;
    end;
  end;

  with MixMethodsAndPropertiesCheckBox do
    Caption:=dlgMixMethodsAndProperties;

  with MethodInsertPolicyRadioGroup do begin
    Caption:=dlgMethodInsPolicy;
    with Items do begin
      BeginUpdate;
      Add(dlgAlphabetically);
      Add(dlgCDTLast);
      Add(dlgCDTClassOrder);
      EndUpdate;
    end;
  end;

  with ForwardProcsInsertPolicyRadioGroup do begin
    Caption:=dlgForwardProcsInsertPolicy;
    with Items do begin
      BeginUpdate;
      Add(dlgLast);
      Add(dlgInFrontOfMethods);
      Add(dlgBehindMethods);
      EndUpdate;
    end;
  end;

  with ForwardProcsKeepOrderCheckBox do
    Caption:=dlgForwardProcsKeepOrder;

  with ClassHeaderCommentsCheckBox do
    Caption:=lisHeaderCommentForClass;

  with PropertyCompletionGroupBox do
    Caption:=dlgPropertyCompletion;

  with PropertyCompletionCheckBox do
    Caption:=dlgCompleteProperties;

  with PropertyReadIdentPrefixLabel do
    Caption:=dlgCDTReadPrefix;

  with PropertyWriteIdentPrefixLabel do
    Caption:=dlgCDTWritePrefix;

  with PropertyStoredIdentPostfixLabel do
    Caption:=dlgCDTStoredPostfix;

  with PrivateVariablePrefixLabel do
    Caption:=dlgCDTVariablePrefix;

  with SetPropertyVariablenameLabel do
    Caption:=dlgSetPropertyVariable;
end;

procedure TCodetoolsCodeCreationOptionsFrame.ReadSettings(
  AOptions: TAbstractIDEOptions);
begin
  with AOptions as TCodetoolsOptions do
  begin
    case ClassPartInsertPolicy of
      cpipAlphabetically:
        ClassPartInsertPolicyRadioGroup.ItemIndex:=0;
    else
      // cpipLast
      ClassPartInsertPolicyRadioGroup.ItemIndex:=1;
    end;

    MixMethodsAndPropertiesCheckBox.Checked := MixMethodsAndProperties;
    case ForwardProcBodyInsertPolicy of
      fpipLast: ForwardProcsInsertPolicyRadioGroup.ItemIndex:=0;
      fpipInFrontOfMethods: ForwardProcsInsertPolicyRadioGroup.ItemIndex:=1;
    else
      // fpipBehindMethods
      ForwardProcsInsertPolicyRadioGroup.ItemIndex:=2;
    end;

    ForwardProcsKeepOrderCheckBox.Checked := KeepForwardProcOrder;
    ClassHeaderCommentsCheckBox.Checked := ClassHeaderComments;
    case MethodInsertPolicy of
      mipAlphabetically:
        MethodInsertPolicyRadioGroup.ItemIndex:=0;
      mipLast:
        MethodInsertPolicyRadioGroup.ItemIndex:=1;
    else
      // mipClassOrder
      MethodInsertPolicyRadioGroup.ItemIndex:=2;
    end;

    PropertyCompletionCheckBox.Checked := CompleteProperties;
    PropertyReadIdentPrefixEdit.Text := PropertyReadIdentPrefix;
    PropertyWriteIdentPrefixEdit.Text := PropertyWriteIdentPrefix;
    PropertyStoredIdentPostfixEdit.Text := PropertyStoredIdentPostfix;
    PrivateVariablePrefixEdit.Text := PrivateVariablePrefix;
    SetPropertyVariablenameEdit.Text := SetPropertyVariablename;
  end;
end;

procedure TCodetoolsCodeCreationOptionsFrame.WriteSettings(
  AOptions: TAbstractIDEOptions);
begin
  with AOptions as TCodetoolsOptions do
  begin
    case ClassPartInsertPolicyRadioGroup.ItemIndex of
      0: ClassPartInsertPolicy := cpipAlphabetically;
      1: ClassPartInsertPolicy := cpipLast;
    end;

    MixMethodsAndProperties := MixMethodsAndPropertiesCheckBox.Checked;
    case ForwardProcsInsertPolicyRadioGroup.ItemIndex of
      0: ForwardProcBodyInsertPolicy := fpipLast;
      1: ForwardProcBodyInsertPolicy := fpipInFrontOfMethods;
      2: ForwardProcBodyInsertPolicy := fpipBehindMethods;
    end;
    KeepForwardProcOrder := ForwardProcsKeepOrderCheckBox.Checked;
    ClassHeaderComments := ClassHeaderCommentsCheckBox.Checked;
    case MethodInsertPolicyRadioGroup.ItemIndex of
      0: MethodInsertPolicy := mipAlphabetically;
      1: MethodInsertPolicy := mipLast;
      2: MethodInsertPolicy := mipClassOrder;
    end;

    CompleteProperties:=PropertyCompletionCheckBox.Checked;
    PropertyReadIdentPrefix :=
      ReadIdentifier(PropertyReadIdentPrefixEdit.Text,'Get');
    PropertyWriteIdentPrefix :=
      ReadIdentifier(PropertyWriteIdentPrefixEdit.Text,'Set');
    PropertyStoredIdentPostfix :=
      ReadIdentifier(PropertyStoredIdentPostfixEdit.Text,'IsStored');
    PrivateVariablePrefix :=
      ReadIdentifier(PrivateVariablePrefixEdit.Text,'F');
    SetPropertyVariablename :=
      ReadIdentifier(SetPropertyVariablenameEdit.Text,'AValue');
  end;
end;

class function TCodetoolsCodeCreationOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TCodeToolsOptions;
end;

initialization
  {$I options_codetools_codecreation.lrs}
  RegisterIDEOptionsEditor(GroupCodetools, TCodetoolsCodeCreationOptionsFrame, CdtOptionsCodeCreation);
end.

