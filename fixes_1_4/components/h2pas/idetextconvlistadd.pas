{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Author: Mattias Gaertner

  Abstract:
    A dialog to choose a TCustomTextConverterToolClass.
}
unit IDETextConvListAdd;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Buttons,
  StdCtrls, IDETextConverter, h2passtrconsts;

type

  { TIDETextConvListAddDlg }

  TIDETextConvListAddDlg = class(TForm)
    ClassLabel: TLabel;
    ClassComboBox: TComboBox;
    AddButton: TButton;
    CancelButton: TButton;
    procedure AddButtonClick(Sender: TObject);
    procedure ClassComboBoxEditingDone(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FToolClass: TCustomTextConverterToolClass;
    procedure SetToolClass(const AValue: TCustomTextConverterToolClass);
    procedure FillClassComboBox;
  public
    property ToolClass: TCustomTextConverterToolClass read FToolClass write SetToolClass;
  end;


function ShowIDETextConvListAddDlg(out ToolClass: TCustomTextConverterToolClass
  ): TModalResult;

implementation

{$R idetextconvlistadd.lfm}

function ShowIDETextConvListAddDlg(out ToolClass: TCustomTextConverterToolClass
  ): TModalResult;
var
  IDETextConvListAddDlg: TIDETextConvListAddDlg;
begin
  IDETextConvListAddDlg:=TIDETextConvListAddDlg.Create(nil);
  Result:=IDETextConvListAddDlg.ShowModal;
  ToolClass:=IDETextConvListAddDlg.ToolClass;
  IDETextConvListAddDlg.Free;
end;

{ TIDETextConvListAddDlg }

procedure TIDETextConvListAddDlg.FormCreate(Sender: TObject);
begin
  ClassLabel.Caption := h2pSelectAClass;
  AddButton.Caption := h2pAdd;
  CancelButton.Caption := h2pCancel2;
  
  FillClassComboBox;
  ToolClass:=TextConverterToolClasses[0];
end;

procedure TIDETextConvListAddDlg.ClassComboBoxEditingDone(Sender: TObject);
begin
  FToolClass:=TextConverterToolClasses.FindByFirstLineOfClassDescription(
                                                            ClassComboBox.Text);
end;

procedure TIDETextConvListAddDlg.AddButtonClick(Sender: TObject);
begin
  if FToolClass=nil then begin
    MessageDlg(h2pInvalidClass,
      h2pInvalidClass, mtError, [mbCancel], 0);
    exit;
  end;
  ModalResult:=mrOk;
end;

procedure TIDETextConvListAddDlg.SetToolClass(
  const AValue: TCustomTextConverterToolClass);
begin
  if FToolClass=AValue then exit;
  FToolClass:=AValue;
  if FToolClass<>nil then
    ClassComboBox.Text:=FToolClass.FirstLineOfClassDescription;
end;

procedure TIDETextConvListAddDlg.FillClassComboBox;
var
  i: Integer;
begin
  ClassComboBox.Items.BeginUpdate;
  ClassComboBox.Items.Clear;
  for i:=0 to TextConverterToolClasses.Count-1 do begin
    ClassComboBox.Items.Add(
                       TextConverterToolClasses[i].FirstLineOfClassDescription);
  end;
  ClassComboBox.Items.EndUpdate;
end;

end.

