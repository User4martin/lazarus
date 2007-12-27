{  $Id: componentpalette.pas 9311 2006-05-19 21:56:07Z mattias $  }
{
 /***************************************************************************
                          componentpalette.pas
                          --------------------


 ***************************************************************************/

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

  Author: Mattias Gaertner

  Abstract:
    A dialog to search a component.
}
unit FindPaletteComp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, FormEditingIntf,
  LazarusIDEStrConsts, ComponentReg, PackageDefs;

type

  { TFindPaletteComponentDlg }

  TFindPaletteComponentDlg = class(TForm)
    ComponentsGroupBox: TGroupBox;
    ComponentsListBox: TListBox;
    SelectButton: TButton;
    CancelButton: TButton;
    PatternEdit: TEdit;
    SearchPatternGroupBox: TGroupBox;
    procedure ComponentsListBoxDblClick(Sender: TObject);
    procedure ComponentsListBoxDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PatternEditChange(Sender: TObject);
  private
    fSelectedComponents: TFPList;// list of TRegisteredComponent
    procedure UpdateComponentSelection;
  public
    function GetSelectedComponent: TRegisteredComponent;
  end;

function ShowFindPaletteComponentDlg(
  out AComponent: TRegisteredComponent): TModalResult;

implementation

function ShowFindPaletteComponentDlg(out AComponent: TRegisteredComponent
  ): TModalResult;
var
  FindPaletteComponentDlg: TFindPaletteComponentDlg;
begin
  FindPaletteComponentDlg:=TFindPaletteComponentDlg.Create(nil);
  Result:=FindPaletteComponentDlg.ShowModal;
  AComponent:=FindPaletteComponentDlg.GetSelectedComponent;
  if AComponent=nil then Result:=mrCancel;
  FindPaletteComponentDlg.Free;
end;

{ TFindPaletteComponentDlg }

procedure TFindPaletteComponentDlg.FormCreate(Sender: TObject);
begin
  Caption:=lisFPFindPaletteComponent;
  ComponentsGroupBox.Caption:=lisFPComponents;
  SelectButton.Caption:=lisMenuSelect;
  CancelButton.Caption:=dlgCancel;
  PatternEdit.Text:='';
  SearchPatternGroupBox.Caption:=lisMenuFind;
  ComponentsListBox.ItemHeight:=ComponentPaletteBtnWidth;
  
  UpdateComponentSelection;
end;

procedure TFindPaletteComponentDlg.ComponentsListBoxDrawItem(
  Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  CurComponent: TRegisteredComponent;
  CurStr: string;
  TxtH: Integer;
  CurIcon: TBitmap;
  IconWidth: Integer;
  IconHeight: Integer;
begin
  if fSelectedComponents=nil then exit;
  if (Index<0) or (Index>=fSelectedComponents.Count) then exit;
  // draw registered component
  CurComponent:=TRegisteredComponent(fSelectedComponents[Index]);
  with ComponentsListBox.Canvas do begin
    CurStr:=Format(lisPckEditPage, [CurComponent.ComponentClass.ClassName,
      CurComponent.Page.PageName]);
    TxtH:=TextHeight(CurStr);
    FillRect(ARect);
    CurIcon:=nil;
    if CurComponent is TPkgComponent then
      CurIcon:=TPkgComponent(CurComponent).Icon;
    if CurIcon<>nil then begin
      IconWidth:=CurIcon.Width;
      IconHeight:=CurIcon.Height;
      Draw(ARect.Left+(25-IconWidth) div 2,
           ARect.Top+(ARect.Bottom-ARect.Top-IconHeight) div 2,
           CurIcon);
    end;
    TextOut(ARect.Left+25,
            ARect.Top+(ARect.Bottom-ARect.Top-TxtH) div 2,
            CurStr);
  end;
end;

procedure TFindPaletteComponentDlg.ComponentsListBoxDblClick(Sender: TObject);
begin
  ModalResult:=mrOk;
end;

procedure TFindPaletteComponentDlg.FormDestroy(Sender: TObject);
begin
  fSelectedComponents.Free;
end;

procedure TFindPaletteComponentDlg.PatternEditChange(Sender: TObject);
begin
  UpdateComponentSelection;
end;

procedure TFindPaletteComponentDlg.UpdateComponentSelection;
var
  p: Integer;
  Page: TBaseComponentPage;
  c: Integer;
  AComponent: TRegisteredComponent;
begin
  if fSelectedComponents=nil then
    fSelectedComponents:=TFPList.Create;
  fSelectedComponents.Clear;
  if IDEComponentPalette=nil then exit;
  for p:=0 to IDEComponentPalette.Count-1 do begin
    Page:=IDEComponentPalette.Pages[p];
    if not Page.Visible then continue;
    for c:=0 to Page.Count-1 do begin
      AComponent:=Page.Items[c];
      if not AComponent.Visible then continue;
      if (PatternEdit.Text='')
      or (System.Pos(UpperCase(PatternEdit.Text),
                    UpperCase(AComponent.ComponentClass.ClassName))>0)
      then
        fSelectedComponents.Add(AComponent);
    end;
  end;
  while ComponentsListBox.Items.Count<fSelectedComponents.Count do
    ComponentsListBox.Items.Add('');
  while ComponentsListBox.Items.Count>fSelectedComponents.Count do
    ComponentsListBox.Items.Delete(ComponentsListBox.Items.Count-1);
  ComponentsListBox.Invalidate;
end;

function TFindPaletteComponentDlg.GetSelectedComponent: TRegisteredComponent;
var
  i: Integer;
begin
  if (fSelectedComponents=nil) or (fSelectedComponents.Count=0) then exit(nil);
  i:=ComponentsListBox.ItemIndex;
  if (i>=fSelectedComponents.Count) or (i<0) then
    i:=0;
  Result:=TRegisteredComponent(fSelectedComponents[i]);
end;

initialization
  {$I findpalettecomp.lrs}

end.

