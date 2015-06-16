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
unit codetools_codecreation_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, ExtCtrls, StdCtrls, Dialogs,
  SourceChanger, CodeToolsOptions, LazarusIDEStrConsts, IDEOptionsIntf,
  IDEDialogs;

type

  { TCodetoolsCodeCreationOptionsFrame }

  TCodetoolsCodeCreationOptionsFrame = class(TAbstractIDEOptionsEditor)
    ForwardProcsInsertPolicyRadioGroup: TRadioGroup;
    ForwardProcsKeepOrderCheckBox: TCheckBox;
    TemplateFileBrowseButton: TButton;
    TemplateFileEdit: TEdit;
    TemplateFileLabel: TLabel;
    UpdateMultiProcSignaturesCheckBox: TCheckBox;
    UpdateOtherProcSignaturesCaseCheckBox: TCheckBox;
    UsesInsertPolicyRadioGroup: TRadioGroup;
    procedure TemplateFileBrowseButtonClick(Sender: TObject);
  private
  public
    function GetTitle: String; override;
    procedure Setup({%H-}ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{$R *.lfm}

{ TCodetoolsCodeCreationOptionsFrame }

procedure TCodetoolsCodeCreationOptionsFrame.TemplateFileBrowseButtonClick(
  Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    InitIDEFileDialog(OpenDialog);
    OpenDialog.Title:=lisChooseAFileWithCodeToolsTemplates;
    OpenDialog.Options:=OpenDialog.Options+[ofFileMustExist];
    OpenDialog.Filter:=dlgFilterCodetoolsTemplateFile+' (*.xml)|*.xml|'+dlgFilterAll+
      '|'+GetAllFilesMask;
    if OpenDialog.Execute then
      TemplateFileEdit.Text:=OpenDialog.FileName;
  finally
    StoreIDEFileDialog(OpenDialog);
    OpenDialog.Free;
  end;
end;

function TCodetoolsCodeCreationOptionsFrame.GetTitle: String;
begin
  Result := dlgCodeCreation;
end;

procedure TCodetoolsCodeCreationOptionsFrame.Setup(
  ADialog: TAbstractOptionsEditorDialog);
begin
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

  ForwardProcsKeepOrderCheckBox.Caption:=dlgForwardProcsKeepOrder;

  with UsesInsertPolicyRadioGroup do begin
    Caption:=lisNewUnitsAreAddedToUsesSections;
    with Items do begin
      BeginUpdate;
      Add(lisFirst);
      Add(lisInFrontOfRelated);
      Add(lisBehindRelated);
      Add(dlgCDTLast);
      Add(dlgAlphabetically);
      EndUpdate;
    end;
  end;

  UpdateMultiProcSignaturesCheckBox.Caption:=
    lisCTOUpdateMultipleProcedureSignatures;
  UpdateOtherProcSignaturesCaseCheckBox.Caption:=
    lisUpdateOtherProcedureSignaturesWhenOnlyLetterCaseHa;

  TemplateFileLabel.Caption:=lisTemplateFile;
  {$IFNDEF EnableCodeCompleteTemplates}
  TemplateFileLabel.Enabled:=false;
  TemplateFileEdit.Enabled:=false;
  TemplateFileBrowseButton.Enabled:=false;
  {$ENDIF}
end;

procedure TCodetoolsCodeCreationOptionsFrame.ReadSettings(
  AOptions: TAbstractIDEOptions);
begin
  with AOptions as TCodetoolsOptions do
  begin
    case ForwardProcBodyInsertPolicy of
      fpipLast: ForwardProcsInsertPolicyRadioGroup.ItemIndex:=0;
      fpipInFrontOfMethods: ForwardProcsInsertPolicyRadioGroup.ItemIndex:=1;
    else
      // fpipBehindMethods
      ForwardProcsInsertPolicyRadioGroup.ItemIndex:=2;
    end;

    ForwardProcsKeepOrderCheckBox.Checked := KeepForwardProcOrder;

    case UsesInsertPolicy of
    uipFirst:             UsesInsertPolicyRadioGroup.ItemIndex:=0;
    uipInFrontOfRelated:  UsesInsertPolicyRadioGroup.ItemIndex:=1;
    uipBehindRelated:     UsesInsertPolicyRadioGroup.ItemIndex:=2;
    uipLast:              UsesInsertPolicyRadioGroup.ItemIndex:=3;
    else
      //uipAlphabetically:
                          UsesInsertPolicyRadioGroup.ItemIndex:=4;
    end;

    UpdateMultiProcSignaturesCheckBox.Checked:=UpdateMultiProcSignatures;
    UpdateOtherProcSignaturesCaseCheckBox.Checked:=UpdateOtherProcSignaturesCase;

    TemplateFileEdit.Text:=CodeCompletionTemplateFileName;
  end;
end;

procedure TCodetoolsCodeCreationOptionsFrame.WriteSettings(
  AOptions: TAbstractIDEOptions);
begin
  with AOptions as TCodetoolsOptions do
  begin
    case ForwardProcsInsertPolicyRadioGroup.ItemIndex of
      0: ForwardProcBodyInsertPolicy := fpipLast;
      1: ForwardProcBodyInsertPolicy := fpipInFrontOfMethods;
      2: ForwardProcBodyInsertPolicy := fpipBehindMethods;
    end;

    KeepForwardProcOrder := ForwardProcsKeepOrderCheckBox.Checked;

    case UsesInsertPolicyRadioGroup.ItemIndex of
    0: UsesInsertPolicy:=uipFirst;
    1: UsesInsertPolicy:=uipInFrontOfRelated;
    2: UsesInsertPolicy:=uipBehindRelated;
    3: UsesInsertPolicy:=uipLast;
    else UsesInsertPolicy:=uipAlphabetically;
    end;

    UpdateMultiProcSignatures:=UpdateMultiProcSignaturesCheckBox.Checked;
    UpdateOtherProcSignaturesCase:=UpdateOtherProcSignaturesCaseCheckBox.Checked;

    CodeCompletionTemplateFileName:=TemplateFileEdit.Text;
  end;
end;

class function TCodetoolsCodeCreationOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TCodeToolsOptions;
end;

initialization
  RegisterIDEOptionsEditor(GroupCodetools, TCodetoolsCodeCreationOptionsFrame, CdtOptionsCodeCreation);
end.

