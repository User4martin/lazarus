{
  LazReport matrix for export reports

 Copyright (C) 2014-2015 alexs alexs75.at.yandex.ru

 The module is designed to create an image of the report with the exact
 positioning of objects and subsequent binding to the worksheet

 This library is free software; you can redistribute it and/or modify it
 under the terms of the GNU Library General Public License as published by
 the Free Software Foundation; either version 2 of the License, or (at your
 option) any later version with the following modification:

 As a special exception, the copyright holders of this library give you
 permission to link this library with independent modules to produce an
 executable, regardless of the license terms of these independent modules,and
 to copy and distribute the resulting executable under terms of your choice,
 provided that you also meet, for each linked independent module, the terms
 and conditions of the license of that module. An independent module is a
 module which is not derived from or based on this library. If you modify
 this library, you may extend this exception to your version of the library,
 but you are not obligated to do so. If you do not wish to do so, delete this
 exception statement from your version.

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
 for more details.

 You should have received a copy of the GNU Library General Public License
 along with this library; if not, write to the Free Software Foundation,
 Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}

unit le_e_spreadsheet_params;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel,
  ComCtrls, ExtCtrls, StdCtrls, Spin;

type

  { TleSpreadsheetParamsForm }

  TleSpreadsheetParamsForm = class(TForm)
    ButtonPanel1: TButtonPanel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    Edit1: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    PageControl1: TPageControl;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    RadioButton4: TRadioButton;
    RadioButton5: TRadioButton;
    RadioButton6: TRadioButton;
    SpinEdit1: TSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure FormCreate(Sender: TObject);
  private
    procedure Localize;
  public
    { public declarations }
  end;

var
  leSpreadsheetParamsForm: TleSpreadsheetParamsForm;

implementation
uses le_e_spreadsheet_consts;

{$R *.lfm}

{ TleSpreadsheetParamsForm }

procedure TleSpreadsheetParamsForm.FormCreate(Sender: TObject);
begin
  PageControl1.ActivePageIndex:=0;
  Localize;
end;

procedure TleSpreadsheetParamsForm.Localize;
begin
  Caption:=sExportToSpreadsheet;
  TabSheet1.Caption:=sGeneral;
  TabSheet2.Caption:=sExportSettings;
  GroupBox2.Caption:=sDataGrouping;
  RadioButton4.Caption:=sLikeTheReport;
  RadioButton5.Caption:=sAllInOnePage;
  RadioButton6.Caption:=sChunksEach;
  CheckBox4.Caption:=sOpenAfterExport;
  CheckBox5.Caption:=sAutoCreateFile;
  GroupBox1.Caption:=sPageRange;
  RadioButton1.Caption:=sAllPages;
  RadioButton2.Caption:=sCurrentPage;
  RadioButton3.Caption:=sPages;
  Label1.Caption:=sEnterPageNumbers;

  CheckBox1.Caption:=sExportPictures;
  CheckBox2.Caption:=sMergeCells;
  CheckBox3.Caption:=sPageBreaks;
  CheckBox6.Caption:=sDeleteEmptyRows;
end;

end.

