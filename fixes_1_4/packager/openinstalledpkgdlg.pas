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

  Author: Mattias Gaertner

  Abstract:
    Defines TOpenLoadedPackagesDlg - The dialog let the user choose one of
    the loaded packages.
}
unit OpenInstalledPkgDlg;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Forms, Controls, ComCtrls, StdCtrls, ExtCtrls, LCLProc, ButtonPanel,
  IDEHelpIntf, IDEWindowIntf, PackageIntf, ListViewFilterEdit,
  PackageDefs, LazarusIDEStrConsts, PackageSystem;

type

  { TOpenLoadedPackagesDlg }

  TOpenLoadedPackagesDlg = class(TForm)
    ButtonPanel1: TButtonPanel;
    FilterEdit: TListViewFilterEdit;
    PkgListView: TListView;
    HintMemo: TMemo;
    Splitter1: TSplitter;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);
    procedure OpenButtonClick(Sender: TObject);
    procedure PkgListViewDblClick(Sender: TObject);
    procedure PkgListViewSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
  private
  public
    Package: TLazPackage;
    procedure UpdateSelection;
    procedure UpdatePackageList;
  end;
  
function ShowOpenLoadedPkgDlg(out OpenPackage: TLazPackage): TModalResult;

implementation

{$R *.lfm}

function ShowOpenLoadedPkgDlg(out OpenPackage: TLazPackage): TModalResult;
var
  Dlg: TOpenLoadedPackagesDlg;
begin
  OpenPackage:=nil;
  Dlg:=TOpenLoadedPackagesDlg.Create(nil);
  try
    Dlg.UpdatePackageList;
    Dlg.UpdateSelection;
    Result:=Dlg.ShowModal;
    if (Result=mrOK) and (Dlg.Package<>nil) then
      OpenPackage:=Dlg.Package
    else
      OpenPackage:=nil;
  finally
    Dlg.Free;
  end;
end;

{ TOpenLoadedPackagesDlg }

procedure TOpenLoadedPackagesDlg.PkgListViewDblClick(Sender: TObject);
begin
  OpenButtonClick(Sender);
end;

procedure TOpenLoadedPackagesDlg.PkgListViewSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  UpdateSelection;
end;

procedure TOpenLoadedPackagesDlg.UpdateSelection;
var
  CurPkg: TLazPackage;
  LI: TListItem;
  HintStr: String;
begin
  LI:=PkgListView.Selected;
  ButtonPanel1.OKButton.Enabled:=Assigned(LI);
  if Assigned(LI) then begin
    CurPkg:=PackageGraph.FindPackageWithName(LI.Caption,nil);
    if CurPkg=nil then
      HintMemo.Text:='Package "'+LI.Caption+'" was already closed'
    else begin
      HintStr:=Format(lisOIPFilename, [CurPkg.Filename]);
      if CurPkg.Missing then
        HintStr:=Format(lisOIPThisPackageIsInstalledButTheLpkFileWasNotFound,[HintStr+LineEnding]);
      HintStr:=Format(lisOIPDescriptionDescription, [HintStr+LineEnding,
        BreakString(CurPkg.Description, 60, length(lisOIPDescription))]);
      if CurPkg.License<>'' then //use same indent as previous entry
        HintStr:=Format(lisOIPLicenseLicense, [HintStr+LineEnding,
        BreakString(CurPkg.License, 60, length(lisOIPDescription))]);
      HintMemo.Text:=HintStr;
    end;
  end else begin
    HintMemo.Text:=lisOIPPleaseSelectAPackage;
  end;
end;

procedure TOpenLoadedPackagesDlg.OpenButtonClick(Sender: TObject);
begin
  if PkgListView.Selected=nil then exit;
  Package:=PackageGraph.FindPackageWithName(PkgListView.Selected.Caption,nil);
  if Package=nil then
    ModalResult:=mrCancel
  else
    ModalResult:=mrOk;
end;

procedure TOpenLoadedPackagesDlg.FormCreate(Sender: TObject);
var
  NewColumn: TListColumn;
begin
  Caption:=lisOIPOpenLoadedPackage;
  IDEDialogLayoutList.ApplyLayout(Self,450,450);

  with PkgListView do begin
    NewColumn:=Columns.Add;
    NewColumn.Caption:=lisOIPPackageName;
    NewColumn.Width:=150;
    NewColumn:=Columns.Add;
    NewColumn.Caption:=lisVersion;
    NewColumn.Width:=80;
    NewColumn:=Columns.Add;
    NewColumn.Caption:=lisOIPState;
    NewColumn.Width:=300;
  end;
  ButtonPanel1.OKButton.Caption:=lisOpen;
  ButtonPanel1.OKButton.Enabled:=False;
end;

procedure TOpenLoadedPackagesDlg.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  IDEDialogLayoutList.SaveLayout(Self);
end;

procedure TOpenLoadedPackagesDlg.HelpButtonClick(Sender: TObject);
begin
  LazarusHelp.ShowHelpForIDEControl(Self);
end;

function PkgStateToString(APackage: TLazPackage): string;
  
  procedure AddState(const s: string);
  begin
    if Result='' then
      Result:=Result+s
    else
      Result:=Result+', '+s;
  end;
  
begin
  Result:='';
  if APackage.Modified then AddState(lisOIPmodified);
  if APackage.Missing then AddState(lisOIPmissing);
  case APackage.Installed of
  pitStatic: AddState(lisOIPinstalledStatic);
  pitDynamic: AddState(lisOIPinstalledDynamic);
  end;
  case APackage.AutoInstall of
  pitStatic: AddState(lisOIPautoInstallStatic);
  pitDynamic: AddState(lisOIPautoInstallDynamic);
  end;
  if APackage.ReadOnly then AddState(lisOIPreadonly);
end;

procedure TOpenLoadedPackagesDlg.UpdatePackageList;

  procedure UpdateOnePackage(aPkg: TLazPackage);
  var
    Data: TStringArray;
  begin
    SetLength(Data, 3);
    Data[0] := aPkg.Name;
    Data[1] := aPkg.Version.AsString;
    Data[2] := PkgStateToString(aPkg);
    FilterEdit.Items.Add(Data);
  end;

var
  i: Integer;
begin
  FilterEdit.Items.Clear;
  for i:=0 to PackageGraph.Count-1 do
    UpdateOnePackage(PackageGraph[i]);
  FilterEdit.InvalidateFilter;
  //PkgListView.BeginUpdate;
  //PkgListView.AlphaSort;
  //PkgListView.EndUpdate;
end;

//if PkgListView.Items.Count>i then begin
//  CurListItem:=PkgListView.Items[i];
//  CurListItem.SubItems[0]:=CurPkg.Version.AsString;
//  CurListItem.SubItems[1]:=PkgStateToString(CurPkg);
//end else begin
  //CurListItem:=PkgListView.Items.Add;
  //CurListItem.SubItems.Add(CurPkg.Version.AsString);
  //CurListItem.SubItems.Add(PkgStateToString(CurPkg));
//end;
//CurListItem.Caption:=CurPkg.Name;


end.

