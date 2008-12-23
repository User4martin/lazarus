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
    This unit defines a dialog for the lazarus environment options.

}
unit EnvironmentOpts_Dlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, LResources, ComCtrls, ButtonPanel,
  EnvironmentOpts, LazarusIDEStrConsts, IDEWindowIntf;

type
  { TEnvironmentOptionsDialog }

  TEnvironmentOptionsDialog = class(TForm)
    ButtonPanel: TButtonPanel;
    CategoryTree: TTreeView;

    procedure CategoryTreeChange(Sender: TObject; Node: TTreeNode);
    procedure HelpButtonClick(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private
    FOnLoadEnvironmentSettings: TOnLoadEnvironmentSettings;
    FOnSaveEnvironmentSettings: TOnSaveEnvironmentSettings;
    PrevNode: TTreeNode;
    FEditors: TList;

    function CheckValues: boolean;
    procedure LoadEnvironmentSettings(Sender: TObject; AOptions: TEnvironmentOptions);
    procedure SaveEnvironmentSettings(Sender: TObject; AOptions: TEnvironmentOptions);
    procedure CreateEditors(AEditor: TAbstractOptionsFrameClass);
  published
    property OnSaveEnvironmentSettings: TOnSaveEnvironmentSettings
      read FOnSaveEnvironmentSettings write FOnSaveEnvironmentSettings;
    property OnLoadEnvironmentSettings: TOnLoadEnvironmentSettings
      read FOnLoadEnvironmentSettings write FOnLoadEnvironmentSettings;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure OpenEditor(AEditor: TAbstractOptionsFrameClass);
    procedure ReadSettings(AnEnvironmentOptions: TEnvironmentOptions);
    procedure WriteSettings(AnEnvironmentOptions: TEnvironmentOptions);
  end;

implementation

uses
  IDEContextHelpEdit;

{ TEnvironmentOptionsDialog }

constructor TEnvironmentOptionsDialog.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  PrevNode := nil;

  IDEDialogLayoutList.ApplyLayout(Self, Width, Height);
  Caption := lisMenuGeneralOptions;

  FEditors := TList.Create;
  EnumEnvironmentOptionsEditors(@CreateEditors);
  ButtonPanel.OKButton.OnClick := @OKButtonClick;
  ButtonPanel.CancelButton.OnClick := @CancelButtonClick;
  ButtonPanel.HelpButton.OnClick := @HelpButtonClick;

  if CategoryTree.Items.Count > 0 then
    CategoryTree.Selected := CategoryTree.Items.GetFirstNode;
end;

destructor TEnvironmentOptionsDialog.Destroy;
begin
  FEditors.Free;
  inherited Destroy;
end;

procedure TEnvironmentOptionsDialog.HelpButtonClick(Sender: TObject);
begin
  ShowContextHelpForIDE(Self);
end;

procedure TEnvironmentOptionsDialog.CategoryTreeChange(Sender: TObject;
  Node: TTreeNode);
var
  AFrame: TAbstractOptionsFrame;
begin
  if PrevNode <> nil then
    TAbstractOptionsFrame(PrevNode.Data).Parent := nil;

  if Node <> nil then
  begin
    AFrame := TAbstractOptionsFrame(Node.Data);

    AFrame.Parent := Self;
    AFrame.Anchors := [akLeft, akTop, akRight, akBottom];
    AFrame.AnchorSideLeft.Side := asrBottom;
    AFrame.AnchorSideLeft.Control := CategoryTree;
    AFrame.AnchorSideTop.Control := Self;
    AFrame.AnchorSideRight.Side := asrBottom;
    AFrame.AnchorSideRight.Control := Self;
    AFrame.AnchorSideBottom.Side := asrTop;
    AFrame.AnchorSideBottom.Control := ButtonPanel;
    AFrame.BorderSpacing.Around := 6;
    AFrame.Visible := True;
  end;
  PrevNode := Node;
end;

procedure TEnvironmentOptionsDialog.OkButtonClick(Sender: TObject);
begin
  if not CheckValues then
    Exit;
  IDEDialogLayoutList.SaveLayout(Self);
  ModalResult := mrOk;
end;

procedure TEnvironmentOptionsDialog.CancelButtonClick(Sender: TObject);
begin
  IDEDialogLayoutList.SaveLayout(Self);
  ModalResult := mrCancel;
end;

procedure TEnvironmentOptionsDialog.ReadSettings(AnEnvironmentOptions: TEnvironmentOptions);
var
  i: integer;
begin
  for i := 0 to FEditors.Count - 1 do
    TAbstractOptionsFrame(FEditors[i]).ReadSettings(AnEnvironmentOptions);
end;

procedure TEnvironmentOptionsDialog.WriteSettings(AnEnvironmentOptions: TEnvironmentOptions);
var
  i: integer;
begin
  for i := 0 to FEditors.Count - 1 do
    TAbstractOptionsFrame(FEditors[i]).WriteSettings(AnEnvironmentOptions);
end;

function TEnvironmentOptionsDialog.CheckValues: boolean;
var
  i: integer;
begin
  Result := True;
  for i := 0 to FEditors.Count - 1 do
  begin
    Result := TAbstractOptionsFrame(FEditors[i]).Check;
    if not Result then
      break;
  end;
end;

procedure TEnvironmentOptionsDialog.LoadEnvironmentSettings(Sender: TObject;
  AOptions: TEnvironmentOptions);
begin
  if Assigned(OnLoadEnvironmentSettings) then
    OnLoadEnvironmentSettings(Self, AOptions);
  ReadSettings(AOptions);
end;

procedure TEnvironmentOptionsDialog.SaveEnvironmentSettings(Sender: TObject;
  AOptions: TEnvironmentOptions);
begin
  WriteSettings(AOptions);
  if Assigned(OnSaveEnvironmentSettings) then
    OnSaveEnvironmentSettings(Self, AOptions);
end;

procedure TEnvironmentOptionsDialog.CreateEditors(AEditor: TAbstractOptionsFrameClass);
var
  Instance: TAbstractOptionsFrame;
  ANode: TTreeNode;
begin
  Instance := AEditor.Create(Self);
  Instance.OnLoadEnvironmentSettings := @LoadEnvironmentSettings;
  Instance.OnSaveEnvironmentSettings := @SaveEnvironmentSettings;
  Instance.Setup;
  FEditors.Add(Instance);

  ANode := CategoryTree.Items.AddChild(nil, Instance.GetTitle);
  ANode.Data := Instance;
end;

procedure TEnvironmentOptionsDialog.OpenEditor(AEditor: TAbstractOptionsFrameClass);
  function Traverse(ANode: TTreeNode): TTreeNode;
  begin
    Result := nil;
    if ANode <> nil then
    begin
      if (ANode.Data <> nil) and (TObject(ANode.Data).ClassType = AEditor) then
        Result := ANode;
      if Result = nil then
        Result := Traverse(ANode.GetFirstChild);
      if Result = nil then
        Result := Traverse(ANode.GetNextSibling);
    end;
  end;
var
  Node: TTreeNode;
begin
  Node := Traverse(CategoryTree.Items.GetFirstNode);
  if Node <> nil then
    CategoryTree.Selected := Node;
end;

initialization
  {$I environmentopts_dlg.lrs}

end.

