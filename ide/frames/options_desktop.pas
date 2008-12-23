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
unit options_desktop;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, StdCtrls, Dialogs, LCLProc,
  EnvironmentOpts, LazarusIDEStrConsts, IDETranslations, InputHistory, IDEProcs, IDEOptionsIntf;

type

  { TDesktopOptionsFrame }

  TDesktopOptionsFrame = class(TAbstractIDEOptionsEditor)
    AutoSaveEditorFilesCheckBox: TCheckBox;
    AutoSaveGroupBox: TGroupBox;
    AutoSaveIntervalInSecsComboBox: TComboBox;
    AutoSaveIntervalInSecsLabel: TLabel;
    AutoSaveProjectCheckBox: TCheckBox;
    CheckDiskChangesWithLoadingCheckBox: TCheckBox;
    DesktopFilesGroupBox: TGroupBox;
    LanguageComboBox: TComboBox;
    LanguageGroupBox: TGroupBox;
    LoadDesktopSettingsFromFileButton: TButton;
    MsgViewDblClickJumpsCheckBox: TCheckBox;
    MsgViewFocusCheckBox: TCheckBox;
    SaveDesktopSettingsToFileButton: TButton;
    ShowHintsForComponentPaletteCheckBox: TCheckBox;
    ShowHintsForMainSpeedButtonsCheckBox: TCheckBox;
    procedure SaveDesktopSettingsToFileButtonClick(Sender: TObject);
    procedure LoadDesktopSettingsFromFileButtonClick(Sender: TObject);
  private
    function LangIDToCaption(const LangID: string): string;
    function CaptionToLangID(const ACaption: string): string;

    procedure DoLoadSettings(AOptions: TAbstractIDEOptions);
    procedure DoSaveSettings(AOptions: TAbstractIDEOptions);
  public
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end;

implementation

{ TDesktopOptionsFrame }

function TDesktopOptionsFrame.GetTitle: String;
begin
  Result := dlgDesktop;
end;

procedure TDesktopOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
var
  i: Integer;
  LangID: String;
  sl: TStringList;
begin
  // language
  LanguageGroupBox.Caption:=dlgEnvLanguage;

  // languages: first the automatic, then sorted the rest
  sl:=TStringList.Create;
  for i:=0 to LazarusTranslations.Count-1 do
  begin
    LangID:=LazarusTranslations[i].ID;
    if LangID<>'' then
      sl.Add(LangIDToCaption(LangID));
  end;
  sl.Sort;
  sl.Insert(0,GetLazarusLanguageLocalizedName(''));
  LanguageComboBox.Items.Assign(sl);
  sl.Free;

  // auto save
  AutoSaveGroupBox.Caption:=dlgAutoSave;
  AutoSaveEditorFilesCheckBox.Caption:=dlgEdFiles;
  AutoSaveProjectCheckBox.Caption:=dlgEnvProject;
  AutoSaveIntervalInSecsLabel.Caption:=dlgIntvInSec;

  // desktop files
  DesktopFilesGroupBox.Caption:=dlgDesktopFiles;
  SaveDesktopSettingsToFileButton.Caption:=dlgSaveDFile;
  LoadDesktopSettingsFromFileButton.Caption:=dlgLoadDFile;

  // hints
  CheckDiskChangesWithLoadingCheckBox.Caption:=lisCheckChangesOnDiskWithLoading;
  ShowHintsForComponentPaletteCheckBox.Caption:=dlgPalHints;
  ShowHintsForMainSpeedButtonsCheckBox.Caption:=dlgSpBHints;

  // messages view
  MsgViewDblClickJumpsCheckBox.Caption:=lisEnvDoubleClickOnMessagesJumpsOtherwiseSingleClick;
  MsgViewFocusCheckBox.Caption:=dlgEOFocusMessagesAfterCompilation;
end;

procedure TDesktopOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEnvironmentOptions do
  begin
    // language
    LanguageComboBox.Text:=LangIDToCaption(LanguageID);
    //debugln('TEnvironmentOptionsDialog.ReadSettings LanguageComboBox.ItemIndex=',dbgs(LanguageComboBox.ItemIndex),' LanguageID="',LanguageID,'" LanguageComboBox.Text="',LanguageComboBox.Text,'"');

    // auto save
    AutoSaveEditorFilesCheckBox.Checked:=AutoSaveEditorFiles;
    AutoSaveProjectCheckBox.Checked:=AutoSaveProject;
    SetComboBoxText(AutoSaveIntervalInSecsComboBox
       ,IntToStr(AutoSaveIntervalInSecs));

    // hints
    CheckDiskChangesWithLoadingCheckBox.Checked:=
      CheckDiskChangesWithLoading;
    ShowHintsForComponentPaletteCheckBox.Checked:=
      ShowHintsForComponentPalette;
    ShowHintsForMainSpeedButtonsCheckBox.Checked:=
      ShowHintsForMainSpeedButtons;
      
    // messages view
    MsgViewDblClickJumpsCheckBox.Checked:=MsgViewDblClickJumps;
    MsgViewFocusCheckBox.Checked:=MsgViewFocus;
  end;
end;

procedure TDesktopOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEnvironmentOptions do
  begin
    // language
    LanguageID:=CaptionToLangID(LanguageComboBox.Text);
    //debugln('TEnvironmentOptionsDialog.WriteSettings A LanguageID="',LanguageID,'" LanguageComboBox.ItemIndex=',dbgs(LanguageComboBox.ItemIndex),' LanguageComboBox.Text=',LanguageComboBox.Text);

    // auto save
    AutoSaveEditorFiles:=AutoSaveEditorFilesCheckBox.Checked;
    AutoSaveProject:=AutoSaveProjectCheckBox.Checked;
    AutoSaveIntervalInSecs:=StrToIntDef(
      AutoSaveIntervalInSecsComboBox.Text,AutoSaveIntervalInSecs);

    // hints
    CheckDiskChangesWithLoading:=CheckDiskChangesWithLoadingCheckBox.Checked;
    ShowHintsForComponentPalette:=ShowHintsForComponentPaletteCheckBox.Checked;
    ShowHintsForMainSpeedButtons:=ShowHintsForMainSpeedButtonsCheckBox.Checked;
    
    // messages view
    MsgViewDblClickJumps:=MsgViewDblClickJumpsCheckBox.Checked;
    MsgViewFocus:=MsgViewFocusCheckBox.Checked;
  end;
end;

procedure TDesktopOptionsFrame.SaveDesktopSettingsToFileButtonClick(Sender: TObject);
var
  AnEnvironmentOptions: TEnvironmentOptions;
  SaveDialog: TSaveDialog;
begin
  //debugln('TEnvironmentOptionsDialog.SaveDesktopSettingsToFileButtonClick A');
  SaveDialog := TSaveDialog.Create(nil);
  try
    try
      InputHistories.ApplyFileDialogSettings(SaveDialog);
      SaveDialog.Filter:=lisLazarusDesktopSettings+' (*.lds)|*.lds'
           +'|'+lisXMLFiles+' (*.xml)|*.xml'
           +'|'+dlgAllFiles+' ('+GetAllFilesMask+')|' + GetAllFilesMask;
      if SaveDialog.Execute then
      begin
        AnEnvironmentOptions := TEnvironmentOptions.Create;
        try
          AnEnvironmentOptions.Filename := SaveDialog.Filename;
          DoSaveSettings(AnEnvironmentOptions);
          AnEnvironmentOptions.Save(true);
        finally
          AnEnvironmentOptions.Free;
        end;
      end;
      InputHistories.StoreFileDialogSettings(SaveDialog);
    except
      on E: Exception do
      begin
        DebugLn('ERROR: [TEnvironmentOptionsDialog.SaveDesktopSettingsToFileButtonClick] ', E.Message);
      end;
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TDesktopOptionsFrame.LoadDesktopSettingsFromFileButtonClick(
  Sender: TObject);
var
  AnEnvironmentOptions: TEnvironmentOptions;
  OpenDialog: TOpenDialog;
begin
  //debugln('TEnvironmentOptionsDialog.LoadDesktopSettingsFromFileButtonClick A');
  OpenDialog := TOpenDialog.Create(nil);
  try
    try
      InputHistories.ApplyFileDialogSettings(OpenDialog);
      OpenDialog.Filter:=lisLazarusDesktopSettings+' (*.lds)|*.lds'
           +'|'+lisXMLFiles+' (*.xml)|*.xml'
           +'|'+dlgAllFiles+' ('+GetAllFilesMask+')|' + GetAllFilesMask;
      if OpenDialog.Execute then
      begin
        AnEnvironmentOptions := TEnvironmentOptions.Create;
        try
          AnEnvironmentOptions.Filename := OpenDialog.Filename;
          AnEnvironmentOptions.Load(true);
          DoLoadSettings(AnEnvironmentOptions);
        finally
          AnEnvironmentOptions.Free;
        end;
      end;
      InputHistories.StoreFileDialogSettings(OpenDialog);
    except
      on E: Exception do
      begin
        // ToDo
        DebugLn('ERROR: [TEnvironmentOptionsDialog.SaveDesktopSettingsToFileButtonClick] ', E.Message);
      end;
    end;
  finally
    OpenDialog.Free;
  end;
end;

function TDesktopOptionsFrame.LangIDToCaption(const LangID: string): string;
begin
  if LangID <> '' then
    Result := GetLazarusLanguageLocalizedName(LangID)+' ['+LangID+']'
  else
    //No [] if automatic
    Result := GetLazarusLanguageLocalizedName(LangID);
end;

function TDesktopOptionsFrame.CaptionToLangID(const ACaption: string): string;
var
  i: Integer;
begin
  for i := 0 to LazarusTranslations.Count-1 do 
  begin
    Result := LazarusTranslations[i].ID;
    if ACaption = LangIDToCaption(Result) then 
      Exit;
  end;
  Result := '';
end;

procedure TDesktopOptionsFrame.DoLoadSettings(AOptions: TAbstractIDEOptions);
begin
  if Assigned(OnLoadIDEOptions) then
    OnLoadIDEOptions(Self, AOptions);
end;

procedure TDesktopOptionsFrame.DoSaveSettings(AOptions: TAbstractIDEOptions);
begin
  if Assigned(OnSaveIDEOptions) then
    OnSaveIDEOptions(Self, AOptions);
end;

class function TDesktopOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEnvironmentOptions;
end;

initialization
  {$I options_desktop.lrs}
  RegisterIDEOptionsEditor(GroupEnvironment, TDesktopOptionsFrame, EnvOptionsDesktop);
end.

