{
  Copyright (C) 2007 Graeme Geldenhuys (graemeg@gmail.com)
  Modified by Giuliano Colla and Juha Manninen

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}

unit EditorToolbarStatic;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Forms, ComCtrls, Controls, ExtCtrls, fgl,
  MenuIntf, IDEImagesIntf, SrcEditorIntf, BaseIDEIntf, LazIDEIntf,
  LazarusIDEStrConsts, LazConfigStorage, Laz2_XMLCfg, LCLProc, ToolbarConfig;

type

  { TEditorToolBarOptions }

  TEditorToolBarOptions = class
  private
    FVisible: Boolean;
    FPosition: string;
    FButtonNames: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Equals(Opts: TEditorToolBarOptions): boolean; overload;
    procedure Assign(Source: TEditorToolBarOptions);
    procedure CreateDefaults;
    procedure Load(XMLConfig: TXMLConfig; Path: String);
    procedure Save(XMLConfig: TXMLConfig; Path: String);
  published
    property Visible: Boolean read FVisible write FVisible;
    property Position: string read FPosition write FPosition;
    property ButtonNames: TStringList read FButtonNames write FButtonNames;
  end;

  TAllEditorToolbars = class;

  { TEditorToolbar }

  TEditorToolbar = class(TIDEToolbarBase)
  private
    FCollection: TAllEditorToolbars;
    FWindow: TSourceEditorWindowInterface;
    CfgButton: TToolButton;
    procedure SetTbPos;
    procedure AddStaticItems;
    procedure InitEditorToolBar;
    procedure ClearToolbar;
    procedure CopyFromOptions(Options: TEditorToolBarOptions);
  public
    constructor Create(AOwner: TComponent; ACollection: TAllEditorToolbars); overload;
    destructor Destroy; override;
    property OwnerWindow: TSourceEditorWindowInterface read FWindow;
  end;
  

  TEditorToolbarList = specialize TFPGList<TEditorToolbar>;

  { TAllEditorToolbars }

  TAllEditorToolbars = class
  private
    FToolBars: TEditorToolbarList;
    FConfigEvent: TNotifyEvent;
    procedure SourceWindowCreated(Sender: TObject);
    procedure SourceWindowDestroyed(Sender: TObject);
    procedure DoConfigureEditorToolbar(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    procedure ReloadAll;
  end;

procedure CreateEditorToolBar(aConfigEvent: TNotifyEvent);

var
  uAllEditorToolbars: TAllEditorToolbars;
  EditorMenuCommand: TIDEMenuCommand;

implementation

uses EnvironmentOpts;

const
  BasePath = 'EditorToolBarOptions/';
  cSettingsFile = 'editortoolbar.xml';


procedure ToggleToolbar (Sender:TObject);
var
  ToolBarVisible: Boolean;
begin
  ToolBarVisible := not EnvironmentOptions.Desktop.EditorToolBarOptions.Visible;
  EditorMenuCommand.Checked := ToolBarVisible;
  EnvironmentOptions.Desktop.EditorToolBarOptions.Visible := ToolBarVisible;
  uAllEditorToolbars.ReloadAll;
end;

{ TEditorToolBarOptions }

constructor TEditorToolBarOptions.Create;
begin
  inherited Create;
  ButtonNames := TStringList.Create;
  FVisible := True;
end;

destructor TEditorToolBarOptions.Destroy;
begin
  ButtonNames.Free;
  inherited Destroy;
end;

procedure TEditorToolBarOptions.Clear;
begin
  ButtonNames.Clear;
  FVisible := True;
end;

function TEditorToolBarOptions.Equals(Opts: TEditorToolBarOptions): boolean;
begin
  Result := (FVisible = Opts.FVisible) and (FPosition = Opts.FPosition)
    and FButtonNames.Equals(Opts.FButtonNames);
end;

procedure TEditorToolBarOptions.Assign(Source: TEditorToolBarOptions);
begin
  FVisible := Source.FVisible;
  FPosition := Source.FPosition;
  FButtonNames.Assign(Source.FButtonNames);
end;

procedure TEditorToolBarOptions.CreateDefaults;
begin
  FButtonNames.Clear;
  FButtonNames.Add('IDEMainMenu/Search/itmJumpings/itmJumpToSection/itmJumpToImplementation');
  FButtonNames.Add('IDEMainMenu/Search/itmJumpings/itmJumpBack');
  FButtonNames.Add('IDEMainMenu/Search/itmJumpings/itmJumpForward');
  FButtonNames.Add(cIDEToolbarDivider);
end;

procedure TEditorToolBarOptions.Load(XMLConfig: TXMLConfig; Path: String);
var
  ButtonCount: Integer;
  ButtonName: string;
  I: Integer;
  cfg: TConfigStorage;
begin
  Path := Path + BasePath;
  if XMLConfig.HasPath(Path + 'Count', True) then
  begin
    FVisible := XMLConfig.GetValue(Path + 'Visible', True);
    FPosition := XMLConfig.GetValue(Path + 'Position', 'Top');
    ButtonCount := XMLConfig.GetValue(Path + 'Count', 0);
    for I := 1 to ButtonCount do
    begin
      ButtonName := XMLConfig.GetValue(Path + 'Button' + IntToStr(I) + '/Name', '');
      if ButtonName = '' then  // Old format
        ButtonName := XMLConfig.GetValue(Path + 'Buttons/Name' + IntToStr(I) + '/Value', '');
      if ButtonName <> '' then
        FButtonNames.Add(ButtonName);
    end;
  end
  else begin
    // Plan B: Load the old configuration. User settings are not lost.
    cfg := GetIDEConfigStorage(cSettingsFile, True);
    try
      FVisible := cfg.GetValue('Visible',True);
      FPosition := cfg.GetValue('Position','Top');
      ButtonCount := cfg.GetValue('Count', 0);
      if ButtonCount > 0 then
      begin
        DebugLn('TEditorToolBarOptions.Load: Using old configuration in editortoolbar.xml.');
        // This used to be hard-coded in old version, add it now.
        FButtonNames.Add('IDEMainMenu/Search/itmJumpings/itmJumpToSection/itmJumpToImplementation');
        for I := 1 to ButtonCount do
        begin
          ButtonName := Trim(cfg.GetValue('Button' + Format('%2.2d', [I]) + '/Value', ''));
          if ButtonName <> '' then
            FButtonNames.Add(ButtonName);
        end;
      end
      else   // No old configuration, use defaults.
        CreateDefaults;
    finally
      cfg.Free;
    end;
  end;
end;

procedure TEditorToolBarOptions.Save(XMLConfig: TXMLConfig; Path: String);
var
  I: Integer;
begin
  Path := Path + BasePath;
  XMLConfig.SetDeleteValue(Path + 'Visible', FVisible, True);
  XMLConfig.SetDeleteValue(Path + 'Position', FPosition, 'Top');
  XMLConfig.SetDeleteValue(Path + 'Count', ButtonNames.Count, 0);
  for I := 0 to ButtonNames.Count-1 do
    XMLConfig.SetDeleteValue(Path + 'Button' + IntToStr(I+1) + '/Name', ButtonNames[I], '');
end;

{ TEditorToolbar }

constructor TEditorToolbar.Create(AOwner: TComponent; ACollection: TAllEditorToolbars);
begin
  inherited Create(AOwner);
  Assert(not Assigned(FToolBar), 'TEditorToolbar.Create: FToolBar is assigned');
  FCollection := ACollection;
  FWindow := TSourceEditorWindowInterface(AOwner);

  // Toolbar must be created with Align = alTop, then initial positioning of buttons is correct.
  FToolBar := TToolbar.Create(FWindow);
  FToolBar.Parent   := FWindow;
  FToolBar.Height   := 26;
  FToolBar.Align    := alTop;
  FToolBar.Flat     := True;
  FToolBar.Images   := IDEImages.Images_16;
  FToolBar.ShowHint := True;
  FToolBar.Hint     := lisEditorToolbarHint;

  AddStaticItems;
end;

destructor TEditorToolbar.Destroy;
begin
  uAllEditorToolbars.FToolBars.Remove(Self);
  inherited Destroy;
end;

procedure TEditorToolbar.InitEditorToolBar;
begin
  FToolBar := nil;
  CfgButton := nil;
end;

procedure TEditorToolbar.SetTbPos;
begin
  case EnvironmentOptions.Desktop.EditorToolBarOptions.Position of
    'Top': begin
      FToolBar.Align:= alTop;
      FToolBar.Height:= 26;
      end;
    'Bottom': begin
      FToolBar.Align:= alBottom;
      FToolBar.Height:= 26;
      end;
    'Left': begin
      FToolBar.Align:= alLeft;
      FToolBar.Width:= 26;
      end;
    'Right': begin
      FToolBar.Align:= alRight;
      FToolBar.Width:= 26;
      end;
  end;
end;

procedure TEditorToolbar.AddStaticItems;
begin
  FToolBar.BeginUpdate;
  try
    // Config Button
    if CfgButton = nil then
      CfgButton := TToolbutton.Create(FToolBar);
    CfgButton.Caption     := lisConfigureEditorToolbar;
    CfgButton.Hint        := CfgButton.Caption;
    CfgButton.ImageIndex  := IDEImages.LoadImage(16, 'preferences');
    CfgButton.Style       := tbsButton;
    CfgButton.OnClick     := @FCollection.DoConfigureEditorToolbar;
    PositionAtEnd(FToolBar, CfgButton);
    AddDivider;
  finally
    FToolBar.EndUpdate;
  end;
end;

procedure TEditorToolbar.ClearToolbar;
var
  i: integer;
begin
  FToolBar.BeginUpdate;
  try
    for i := FToolBar.ButtonCount - 1 downto 0 do
      if FToolBar.Buttons[i] <> CfgButton then
        FToolBar.Buttons[i].Free
      else
        FToolBar.Buttons[i].Parent := nil;
  finally
    FToolBar.EndUpdate;
  end;
end;

procedure TEditorToolbar.CopyFromOptions(Options: TEditorToolBarOptions);
var
  mi: TIDEMenuItem;
  ButtonName: string;
  i: Integer;
begin
  FToolBar.BeginUpdate;
  try
    for i := 0 to Options.ButtonNames.Count-1 do
    begin
      ButtonName := Options.ButtonNames[i];
      if ButtonName = cIDEToolbarDivider then
        AddDivider
      else
      begin
        mi := IDEMenuRoots.FindByPath(ButtonName,false);
        if Assigned(mi) then
          AddButton(mi as TIDEMenuCommand);
      end;
    end;
    SetTbPos;
    EditorMenuCommand.Checked := Options.Visible;
  finally
    FToolBar.EndUpdate;
  end;
  FToolBar.Visible := Options.Visible;
end;

procedure CreateEditorToolBar(aConfigEvent: TNotifyEvent);
var
  MenuIcon: string;
begin
  uAllEditorToolbars := TAllEditorToolbars.Create;
  uAllEditorToolbars.FConfigEvent := aConfigEvent;
  EditorMenuCommand := RegisterIDEMenuCommand(itmViewSecondaryWindows,'EditorToolBar',
    lisEditorToolbar,nil,@ToggleToolbar);
  EditorMenuCommand.Checked := True;
  EditorMenuCommand.Enabled := True;
  MenuIcon:= 'menu_editor_options';
  //MenuIcon:= 'menu_editor_toolbar'; TODO!
  EditorMenuCommand.ImageIndex := IDEImages.LoadImage(16, MenuIcon);
end;

{ TAllEditorToolbars }

constructor TAllEditorToolbars.Create;
begin
  inherited;
  FToolBars := TEditorToolbarList.Create;
  if SourceEditorManagerIntf <> nil then
  begin
    SourceEditorManagerIntf.RegisterChangeEvent(semWindowCreate, @SourceWindowCreated);
    SourceEditorManagerIntf.RegisterChangeEvent(semWindowDestroy,@SourceWindowDestroyed);
  end;
end;

destructor TAllEditorToolbars.Destroy;
begin
  while FToolBars.Count > 0 do
    FToolBars[0].Free;
  FreeAndNil(FToolBars);
  inherited Destroy;
end;

procedure TAllEditorToolbars.SourceWindowCreated(Sender: TObject);
var
  ETB: TEditorToolbar;
  i: Integer;
begin
  ETB := TEditorToolbar.Create(Sender as TSourceEditorWindowInterface, Self);
  i := FToolBars.Add(ETB);
  FToolBars[i].AddStaticItems;
  FToolBars[i].CopyFromOptions(EnvironmentOptions.Desktop.EditorToolBarOptions);
end;

procedure TAllEditorToolbars.SourceWindowDestroyed(Sender: TObject);
var
  i: integer;
  aBar: TEditorToolbar;
begin
  // Let's remove from our list the destroyed window and then destroy the ToolBar
  for i:= 0 to FToolBars.Count -1 do begin
    aBar := FToolBars[i];
    if aBar.OwnerWindow = TSourceEditorWindowInterface(Sender) then
    begin
      FToolBars.Remove(aBar);
      aBar.Free;
      exit;
    end;
  end;
end;

procedure TAllEditorToolbars.DoConfigureEditorToolbar(Sender: TObject);
begin
  if Assigned(FConfigEvent) then
    FConfigEvent(Sender);
end;

procedure TAllEditorToolbars.ReloadAll;
var
  i: Integer;
begin
  for i := 0 to FToolBars.Count-1 do
  begin
    FToolBars[i].ClearToolbar;
    FToolBars[i].AddStaticItems;
    FToolBars[i].CopyFromOptions(EnvironmentOptions.Desktop.EditorToolBarOptions);
  end;
end;


initialization
  //CreateEditorToolBar;

finalization
  uAllEditorToolbars.Free;

end.

