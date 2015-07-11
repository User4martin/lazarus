{ Lazarus IDE wizard for fpweb package.

  Copyright (C) 2010 Lagunov Aleksey alexs75@hotbox.ru

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
unit fpwebNewHtmlTagTDUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ColorBox, ButtonPanel, Spin;

type

  { TfpwebNewHtmlTagTDForm }

  TfpwebNewHtmlTagTDForm = class(TForm)
    ButtonPanel1: TButtonPanel;
    CBAlign: TComboBox;
    CBClass: TComboBox;
    CBColor: TColorBox;
    CBId: TComboBox;
    CBValign: TComboBox;
    CheckBox1: TCheckBox;
    edtText: TEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    PageControl1: TPageControl;
    edtWidth: TSpinEdit;
    edtCollSpan: TSpinEdit;
    edtHeight: TSpinEdit;
    edtRowSpan: TSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    function HtmlText:string;
  end;

var
  fpwebNewHtmlTagTDForm: TfpwebNewHtmlTagTDForm;

implementation
uses fpWebStrConsts;

{$R *.lfm}

{ TfpwebNewHtmlTagTDForm }

procedure TfpwebNewHtmlTagTDForm.FormCreate(Sender: TObject);
begin
  Caption:=Format(SHTMLTagProperty, ['TD']);
end;

function TfpwebNewHtmlTagTDForm.HtmlText: string;
begin
  Result:='<TD';
  if edtWidth.Value > 0 then
    Result:=Result + Format(' width="%d"', [edtWidth.Value]);

  if edtCollSpan.Value > 0 then
    Result:=Result + Format(' colspan="%d"', [edtCollSpan.Value]);

  if edtHeight.Value > 0 then
    Result:=Result + Format(' height="%d"', [edtHeight.Value]);

  if edtRowSpan.Value > 0 then
    Result:=Result + Format(' rowspan="%d"', [edtRowSpan.Value]);

  if CBAlign.Text<>'' then
    Result:=Result + ' align="'+CBAlign.Text+'"';

  if CBValign.Text<>'' then
    Result:=Result + ' valign="'+CBValign.Text+'"';

  if CBColor.Selected <> CBColor.NoneColorColor then
    Result:=Result + ' bgcolor="#'+IntToHex(CBColor.Selected,6)+'"';

  if CheckBox1.Checked then
    Result:=Result + ' nowrap';
  Result:=Result + '>'+edtText.Text+'</TD>';
end;

end.

