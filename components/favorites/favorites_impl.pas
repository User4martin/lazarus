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

  Author: Ondrej Pokorny

  Abstract:
    Adds favorite projects list into the drop-down menu of "Open" toolbar button.
}
unit favorites_impl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ToolBarIntf, IDEImagesIntf, Graphics, PackageIntf,
  Menus, LazIDEIntf, ProjectIntf, Laz2_XMLCfg, IDEOptionsIntf,
  IDECommands, ComCtrls, favoritesstr, ImgList;

type
  TFavoritesHandler = class
  private
    FOldToolButtonClass: TIDEToolButtonClass;
    FFavoriteProjects: TStringList;
    FConfig: TXMLConfig;

    procedure AddToRecentProjectFiles(Sender: TObject; AFileName: string;
      var AAllow: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
  public
    procedure LoadFromConfig;
    procedure SaveToConfig;
    function IsInFavoriteProjects(const aFileName: string): Boolean;
    procedure AddToFavoriteProjects(const aFileName: string);
    procedure RemoveFromFavoriteProjects(const aFileName: string);
  end;

  TFileNameMenuItem = class(TMenuItem)
  public
    FileName: string;
  end;

  TOpenFileFavToolButton = class(TIDEToolButton)
  private
    FOrigButton: TIDEToolButton;
    FOrigOnPopup: TNotifyEvent;
    FIndex: TStringList;
    FAddImageIndex, FRemoveImageIndex: Integer;

    procedure RefreshMenu(Sender: TObject);
    procedure mnuFavoriteFile(Sender: TObject);
    procedure mnuAddRemoveActiveProject(Sender: TObject);
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure DoOnAdded; override;
  end;


procedure Register;

implementation

var
  FavHandler: TFavoritesHandler = nil;

procedure Register;
begin
  FavHandler := TFavoritesHandler.Create;
end;

{ TOpenFileFavToolButton }

constructor TOpenFileFavToolButton.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  FIndex := TStringList.Create;
  FIndex.Sorted := True;
  FIndex.Duplicates := dupIgnore;
  FIndex.CaseSensitive := False;

  if FavHandler.FOldToolButtonClass<>nil then
    FOrigButton := FavHandler.FOldToolButtonClass.Create(Self)
  else
    FOrigButton := TIDEToolButton.Create(Self);
end;

destructor TOpenFileFavToolButton.Destroy;
begin
  FIndex.Free;

  inherited Destroy;
end;

procedure TOpenFileFavToolButton.DoOnAdded;
var
  xImg: TCustomBitmap;
begin
  inherited DoOnAdded;

  FOrigButton.DoOnAdded;

  if FOrigButton.DropdownMenu<>nil then
    DropdownMenu := FOrigButton.DropdownMenu
  else
    DropdownMenu := TPopupMenu.Create(Self);

  if DropdownMenu.Images=nil then
  begin
    DropdownMenu.Images := TCustomImageList.Create(Self);
    DropdownMenu.Images.Width := 16;
    DropdownMenu.Images.Height := 16;
  end;

  xImg := TBitmap.Create;
  try
    IDEImages.Images_16.GetBitmap(IDEImages.LoadImage(16, 'laz_add'), xImg);
    FAddImageIndex := DropdownMenu.Images.Add(xImg, nil);
    IDEImages.Images_16.GetBitmap(IDEImages.LoadImage(16, 'laz_delete'), xImg);
    FRemoveImageIndex := DropdownMenu.Images.Add(xImg, nil);
  finally
    xImg.Free;
  end;

  FOrigOnPopup := DropdownMenu.OnPopup;
  DropdownMenu.OnPopup := @RefreshMenu;
  Style := tbsDropDown;
end;

procedure TOpenFileFavToolButton.mnuAddRemoveActiveProject(Sender: TObject);
var
  xFileName: string;
begin
  xFileName := (Sender as TFileNameMenuItem).FileName;
  if FavHandler.IsInFavoriteProjects(xFileName) then
  begin
    FavHandler.RemoveFromFavoriteProjects(xFileName);
    IDEEnvironmentOptions.AddToRecentProjectFiles(xFileName);
  end else
  begin
    FavHandler.AddToFavoriteProjects(xFileName);
    IDEEnvironmentOptions.RemoveFromRecentProjectFiles(xFileName);
  end;
end;

procedure TOpenFileFavToolButton.mnuFavoriteFile(Sender: TObject);
begin
  LazarusIDE.DoOpenProjectFile((Sender as TFileNameMenuItem).FileName,[ofAddToRecent]);
end;

procedure TOpenFileFavToolButton.RefreshMenu(Sender: TObject);
var
  xM, xSep: TMenuItem;
  xFavoriteFile: string;
  xMI, xAddToFav: TFileNameMenuItem;
  xProj: TLazProject;
  xMIndex: Integer;
  xExt: RawByteString;
begin
  if Assigned(FOrigOnPopup) then
    FOrigOnPopup(Sender);

  xM := DropdownMenu.Items;

  xMIndex := 0;
  for xFavoriteFile in FavHandler.FFavoriteProjects do
  begin
    xMI := TFileNameMenuItem.Create(Self);
    xMI.FileName := xFavoriteFile;
    xMI.Caption := xFavoriteFile;
    xMI.OnClick := @mnuFavoriteFile;
    xExt := ExtractFileExt(xFavoriteFile);
    if SameFileName(xExt, '.lpi') or SameFileName(xExt, '.lpr') then
      xMI.ImageIndex := LoadProjectIconIntoImages(xFavoriteFile, DropdownMenu.Images, FIndex);

    xM.Insert(xMIndex, xMI);
    Inc(xMIndex);
  end;

  xProj := LazarusIDE.ActiveProject;
  if (xProj<>nil) and FileExists(xProj.ProjectInfoFile) then
  begin
    xAddToFav := TFileNameMenuItem.Create(Self);
    xAddToFav.FileName := xProj.ProjectInfoFile;
    if not FavHandler.IsInFavoriteProjects(xProj.ProjectInfoFile) then
    begin
      xAddToFav.Caption := Format(sAddToFavoritesS, [xProj.ProjectInfoFile]);
      xAddToFav.ImageIndex := FAddImageIndex;
    end else
    begin
      xAddToFav.Caption := Format(sRemoveFromFavoritesS, [xProj.ProjectInfoFile]);
      xAddToFav.ImageIndex := FRemoveImageIndex;
    end;
    xAddToFav.OnClick := @mnuAddRemoveActiveProject;
    xM.Insert(xMIndex, xAddToFav);
    Inc(xMIndex);
  end;

  if xMIndex > 0 then
  begin
    xSep := TMenuItem.Create(Self);
    xSep.Caption := '-';
    xM.Insert(xMIndex, xSep);
    Inc(xMIndex);
  end;
end;

{ TFavoritesHandler }

constructor TFavoritesHandler.Create;
var
  I: Integer;
  xToolButton: TIDEButtonCommand;
begin
  IDEEnvironmentOptions.AddHandlerAddToRecentProjectFiles(@AddToRecentProjectFiles);
  FFavoriteProjects := TStringList.Create;
  FFavoriteProjects.Duplicates := dupIgnore;
  FFavoriteProjects.CaseSensitive := False;
  FFavoriteProjects.Sorted := True;
  FConfig := TXMLConfig.Create(LazarusIDE.GetPrimaryConfigPath+'favorites.xml');
  LoadFromConfig;

  xToolButton := IDEToolButtonCategories.FindItemByCommand(ecOpen);
  FOldToolButtonClass := xToolButton.ToolButtonClass;
  xToolButton.ToolButtonClass := TOpenFileFavToolButton;

  for I := 0 to FFavoriteProjects.Count-1 do
    IDEEnvironmentOptions.RemoveFromRecentProjectFiles(FFavoriteProjects[I]);
end;

procedure TFavoritesHandler.AddToFavoriteProjects(const aFileName: string);
begin
  FFavoriteProjects.Add(aFileName);
end;

procedure TFavoritesHandler.AddToRecentProjectFiles(Sender: TObject;
  AFileName: string; var AAllow: Boolean);
begin
  if IsInFavoriteProjects(AFileName) then
    AAllow := False;
end;

destructor TFavoritesHandler.Destroy;
begin
  SaveToConfig;
  FFavoriteProjects.Free;
  FConfig.Free;

  inherited Destroy;
end;

function TFavoritesHandler.IsInFavoriteProjects(const aFileName: string
  ): Boolean;
var
  I: Integer;
begin
  for I := 0 to FFavoriteProjects.Count-1 do
  if SameFileName(aFileName, FFavoriteProjects[I]) then
    Exit(True);
  Result := False;
end;

procedure TFavoritesHandler.LoadFromConfig;
var
  I: Integer;
  xItem: string;
begin
  I := 1;
  while True do
  begin
    xItem := FConfig.GetValue('projects/item'+IntToStr(I), '');
    if xItem = '' then
      Break;
    if FileExists(xItem) then
      FFavoriteProjects.Add(xItem);
    Inc(I);
  end;
end;

procedure TFavoritesHandler.RemoveFromFavoriteProjects(const aFileName: string);
var
  xIndex: Integer;
begin
  xIndex := FFavoriteProjects.IndexOf(aFileName);
  if xIndex >= 0 then
    FFavoriteProjects.Delete(xIndex);
end;

procedure TFavoritesHandler.SaveToConfig;
var
  I: Integer;
  xItem: string;
begin
  I := 1;
  FConfig.DeletePath('projects');
  for xItem in FFavoriteProjects do
  begin
    FConfig.SetValue('projects/item'+IntToStr(I), xItem);
    Inc(I);
  end;
end;

finalization
  FreeAndNil(FavHandler);
end.

