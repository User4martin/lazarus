{
  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}

// Original version made by Bart Broersma

unit pocheckermain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, LCLProc, CheckLst, Buttons, ExtCtrls, ComCtrls, Types,
  LCLType, Translations,
  {$IFnDEF POCHECKERSTANDALONE}
  IDEIntf, MenuIntf,
  {$ENDIF}
  PoFamilies, ResultDlg, pocheckerconsts, PoCheckerSettings,
  PoFamilyLists, PoCheckerMemoDlg;

type

  { TPoCheckerForm }

  TPoCheckerForm = class(TForm)
    SelectAllMasterFilesBtn: TButton;
    SelectDirectoryDialog: TSelectDirectoryDialog;
    UnselectAllMasterFilesBtn: TButton;
    ClearMasterFilesBtn: TButton;
    LangFilter: TComboBox;
    MasterPoListBox: TListBox;
    ScanDirBtn: TBitBtn;
    StatusBar: TStatusBar;
    procedure MasterPoListBoxResize(Sender: TObject);
    procedure ClearMasterFilesBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LangFilterChange(Sender: TObject);
    procedure MasterPoListBoxDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure MasterPoListBoxSelectionChange(Sender: TObject; User: boolean);
    procedure ScanDirBtnClick(Sender: TObject);
    procedure SelectAllMasterFilesBtnClick(Sender: TObject);
    procedure UnselectAllMasterFilesBtnClick(Sender: TObject);
  private
    //PoFamily: TPoFamily;
    PoFamilyList: TPoFamilyList;
    FPoCheckerSettings: TPoCheckerSettings;
    procedure OnTestStart(const ATestName, APoFileName: string);
    procedure OnTestEnd(const {%H-}ATestName: string; const {%H-}ErrorCount: integer);
    procedure FillTestListBox;
    function GetTestTypesFromListBox: TPoTestTypes;
    function GetTestOptions: TPoTestOptions;
    procedure SetTestTypeCheckBoxes(TestTypes: TPoTestTypes);
    procedure SetTestOptionCheckBoxes(TestOptions: TPoTestOptions);
    procedure ShowError(const Msg: string);
    function TrySelectFile(out Filename: String): Boolean;
    procedure ScanDirectory(ADir: String);
    function TryCreatepoFamilyList(MasterList: TStrings; const LangID: TLangID): Boolean;
    procedure RunSelectedTests;
    procedure ClearStatusBar;
    procedure UpdateGUI(HasSelection: Boolean);
    function GetSelectedMasterFiles: TStringList;
    procedure AddToMasterPoList(Fn: String);
    procedure AddToMasterPoList(S: TStrings);
    procedure SetSelectedMasterFiles(S: TStrings);
    procedure ApplyConfig;
    procedure SaveConfig;
    function LangFilterIndexToLangID(Index: Integer): TLangID;
    function LangIdToLangFilterIndex(LangID: TLangID): Integer;
    procedure PopulateLangFilter;
    {$IFDEF POCHECKERSTANDALONE}
    procedure GetTranslations;
    function GetTranslationsSearchPath: String;
    procedure FindTranslationFiles(const SearchPath, Lang: String; out PoCheckPo, LclPo: String);
    {$ENDIF}
    procedure ApplyTranslations;
  published
    IgnoreFuzzyCheckBox: TCheckBox;
    UnselectAllTestsBtn: TButton;
    SelectAllTestsBtn: TButton;
    SelectBasicTestsBtn: TButton;
    NoErrLabel: TLabel;
    RunBtn: TBitBtn;
    OpenBtn: TBitBtn;
    Button3: TButton;
    SelectTestLabel: TLabel;
    OpenDialog: TOpenDialog;
    TestListBox: TCheckListBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure OpenBtnClick(Sender: TObject);
    procedure RunBtnClick(Sender: TObject);
    procedure SelectAllTestsBtnClick(Sender: TObject);
    procedure SelectBasicTestsBtnClick(Sender: TObject);
    procedure UnselectAllTestsBtnClick(Sender: TObject);
  end;

var
  PoCheckerForm: TPoCheckerForm;

procedure Register;

implementation

{$R *.lfm}


procedure ShowPoCheckerForm();
begin
  if not Assigned(PoCheckerForm) then
    PoCheckerForm := TPoCheckerForm.Create(Application);
  PoCheckerForm.Show;
end;


{ TPoCheckerForm }

procedure TPoCheckerForm.FormCreate(Sender: TObject);
begin
  FPoCheckerSettings := TPoCheckerSettings.Create;
  FPoCheckerSettings.LoadConfig;
  //debugln('TPoCheckerForm.FormCreate A:');
  {$IFDEF POCHECKERSTANDALONE}
  //Initializing translation
  GetTranslations;
  {$ENDIF}
  ApplyTranslations;
  FillTestListBox;
  ClearStatusBar;
  NoErrLabel.Visible := False;
  PopulateLangFilter;
  ApplyConfig;
  LangFilter.Invalidate; //Items[0] may have been changed
end;


procedure TPoCheckerForm.FormDestroy(Sender: TObject);
begin
  if Assigned(PoFamilyList) then
    PoFamilyList.Free;
  SaveConfig;
  if Assigned(FPoCheckerSettings) then
    FPoCheckerSettings.Free;
end;


procedure TPoCheckerForm.OpenBtnClick(Sender: TObject);
var
  Fn,Mn: String;
  Idx: Integer;
  ALang: TLangID;
begin
  if TrySelectFile(Fn) then
  begin
    if IsMasterPoName(Fn) then
    begin
      AddToMasterPoList(Fn);
      Idx := MasterPoListBox.Items.IndexOf(Fn);
      if (Idx <> -1) then
        MasterPoListBox.Selected[Idx] := True;
    end
    else
    begin
      Mn := ExtractMasterNameFromChildName(Fn);
      if Mn <> '' then
      begin
        AddToMasterPoList(Mn);
        Idx := MasterPoListBox.Items.IndexOf(Mn);
        if (Idx <> -1) then
          MasterPoListBox.Selected[Idx] := True;
        ALang := ExtractLanguageFromChildName(Fn);
        Idx := LangIdToLangFilterIndex(ALang);
        if (Idx <> -1) then
          LangFilter.ItemIndex := Idx;
      end;
    end;
    UpdateGUI(MasterPoListBox.SelCount > 0);
  end;
end;


procedure TPoCheckerForm.RunBtnClick(Sender: TObject);
var
  AMasterList: TStringList;
  LangIdx: Integer;
  ALangID: TLangID;
begin
  LangIdx := LangFilter.ItemIndex;
  ALangID := LangFilterIndexToLangID(LangIdx);
  AMasterList := GetSelectedMasterFiles;
  try
    if TryCreatePoFamilyList(AMasterList, ALangID) then
      RunSelectedTests
    else
    begin
      if Assigned(PoFamilyList) then FreeAndNil(PoFamilyList);
    end;
  finally
    AMasterList.Free;
  end;
end;

procedure TPoCheckerForm.SelectAllTestsBtnClick(Sender: TObject);
begin
  TestListBox.CheckAll(cbChecked, False, False);
end;


procedure TPoCheckerForm.SelectBasicTestsBtnClick(Sender: TObject);
var
  i: integer;
begin
  // Set / reset "basic" CheckListBox items.
  for i := 0 to TestListBox.Count - 3 do
    TestListBox.Checked[i] := True;
end;

procedure TPoCheckerForm.UnselectAllTestsBtnClick(Sender: TObject);
begin
  TestListBox.CheckAll(cbUnchecked, False, False);
end;

procedure TPoCheckerForm.LangFilterChange(Sender: TObject);
begin
  //This looks silly, but it makes that ItemIndex has the right value
  //in OnDestroy when you dropdown and change the filter, and then close
  //the form and no call to ItemIndex was made after changing the filter....
  //If someone figures out why, or has a better solution: please implement that
  LangFilter.ItemIndex;
end;


procedure TPoCheckerForm.MasterPoListBoxResize(Sender: TObject);
var
  ATop: Integer;
begin
  //Can't seem to get this to work with just Anchors
  ATop := MasterPoListBox.Top + MasterPoListBox.Height;
  LangFilter.Top := ATop + 5;
end;


procedure TPoCheckerForm.ClearMasterFilesBtnClick(Sender: TObject);
begin
  MasterPoListBox.Clear;
  UpdateGUI(False);
end;

procedure TPoCheckerForm.FormShow(Sender: TObject);
begin
  WindowState := FPoCheckerSettings.MainFormWindowState;
end;

procedure TPoCheckerForm.MasterPoListBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  LB: TListBox;
  AText: String;
begin
  LB := TListBox(Control);
  with LB.Canvas do
  begin
    //if odSelected in State then Brush.Color := $00FFD2A6;
    FillRect(ARect);
    AText := ExtractFilename(LB.Items[Index]);
    TextOut(ARect.Left, ARect.Top, AText);
    if (odFocused in State) then
    begin
      Brush.Color := LB.Color;
      DrawFocusRect(ARect);
    end;
  end;
end;

procedure TPoCheckerForm.MasterPoListBoxSelectionChange(Sender: TObject;
  User: boolean);
begin
  //debugln('TPoCheckerForm.MasterPoListBoxSelectionChange: User = ',DbgS(User));
  if User then
  begin
    UpdateGUI(MasterPoListBox.SelCount > 0);
  end;
  UnselectAllMasterFilesBtn.Enabled := (MasterPoListBox.SelCount <> 0);
  SelectAllMasterFilesBtn.Enabled := (MasterPoListBox.Items.Count > 0);
end;

procedure TPoCheckerForm.ScanDirBtnClick(Sender: TObject);
begin
  if SelectDirectoryDialog.Execute then
  begin
    ScanDirectory(SelectDirectoryDialog.FileName);
  end;
end;

procedure TPoCheckerForm.SelectAllMasterFilesBtnClick(Sender: TObject);
begin
  MasterPoListBox.SelectAll;
  UpdateGUI(MasterPoListBox.SelCount > 0);
end;

procedure TPoCheckerForm.UnselectAllMasterFilesBtnClick(Sender: TObject);
begin
  MasterPoListBox.ClearSelection;
  UpdateGUI(False);
end;

procedure TPoCheckerForm.OnTestStart(const ATestName, APoFileName: string);
begin
  //debugln('OnTestStart: ATestName = "',AtestName,'" APoFileName = "',APoFileName);
  StatusBar.SimplePanel := True;
  StatusBar.SimpleText := Format(sCurrentTest,[ATestName,APoFileName]);
  Application.ProcessMessages;
end;


procedure TPoCheckerForm.OnTestEnd(const ATestName: string; const ErrorCount: integer);
begin
  //CurTestLabel.Caption := '';
  //CurPoLabel.Caption :=  '';
  //debugln('OnTestEnd [', ATestName, ']: ErrorCount = ', DbgS(ErrorCount));
  //Application.ProcessMessages;
end;


procedure TPoCheckerForm.FillTestListBox;
var
  Typ: TPoTestType;
begin
  TestListBox.Items.Clear;
  for Typ := Low(PoTestTypeNames) to High(PoTestTypeNames) do
    TestListBox.Items.Add(PoTestTypeNames[Typ]);
end;


function TPoCheckerForm.GetTestTypesFromListBox: TPoTestTypes;
var
  Typ: TPoTestType;
  Index: integer;
begin
  Result := [];
  for Typ := Low(TPoTestType) to High(TPoTestType) do
  begin
    Index := Ord(Typ);
    if (Index < TestListBox.Count) then
    begin
      if TestListBox.Checked[Index] then
        Result := Result + [Typ];
    end;
  end;
end;

function TPoCheckerForm.GetTestOptions: TPoTestOptions;
begin
  Result := [];
  //if FindAllPOsCheckBox.Checked then
  //  Result := Result + [ptoFindAllChildren];
  if IgnoreFuzzyCheckBox.Checked then
    Result := Result + [ptoIgnoreFuzzyStrings];
end;

procedure TPoCheckerForm.SetTestTypeCheckBoxes(TestTypes: TPoTestTypes);
var
  Typ: TPoTestType;
  Index: integer;
begin
  for Typ := Low(TPoTestType) to High(TPoTestType) do
  begin
    Index := Ord(Typ);
    if (Index < TestListBox.Count) then
    begin
      TestListBox.Checked[Index] := (Typ in TestTypes)
    end;
  end;
end;

procedure TPoCheckerForm.SetTestOptionCheckBoxes(TestOptions: TPoTestOptions);
begin
  //FindAllPOsCheckBox.Checked := (ptoFindAllChildren in TestOptions);
  IgnoreFuzzyCheckBox.Checked := (ptoIgnoreFuzzyStrings in TestOptions);
end;


procedure TPoCheckerForm.ShowError(const Msg: string);
begin
  MessageDlg('Po-checker', Msg, mtError, [mbOK], 0);
end;


function TPoCheckerForm.TrySelectFile(out Filename: String): boolean;
begin
  Result := False;
  Filename := '';
  if OpenDialog.Execute then
  begin
    Filename := OpenDialog.FileName;
    Result := (CompareText(ExtractFileExt(Filename), '.po') = 0);
    if not Result then Filename := '';
  end;
end;

procedure TPoCheckerForm.ScanDirectory(ADir: String);
var
  SL, ML: TStringList;
  i: Integer;
  S: String;
  Cur: TCursor;
begin
  Cur := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  StatusBar.SimpleText := sScanningInProgress;
  try
    SL := FindAllFiles(ADir, '*.po',True);
    try
      ML := TStringList.Create;
      for i := 0 to SL.Count - 1 do
      begin
        S := SL[i];
        //debugln('TPoCheckerForm.ScanDirectory: S = "',ExtractFilename(S),'"');
        if IsMasterPoName(S) then
          ML.Add(S);
      end;
      if (ML.Count > 0) then AddToMasterPoList(ML);
      UpdateGUI(MasterPoListBox.SelCount > 0);
    finally
      SL.Free;
      ML.Free;
    end;
  finally
    StatusBar.SimpleText := '';
    Screen.Cursor := Cur;
  end;
end;


function TPoCheckerForm.TryCreatepoFamilyList(MasterList: TStrings; const LangID: TLangID): Boolean;
var
  Fn, Msg: String;
  i, Cnt: Integer;
begin
  Result := False;
  Msg := '';
  Cnt := MasterList.Count;
  for i := Cnt - 1 downto 0 do
  begin
    Fn := MasterList.Strings[i];
    if not FileExistsUtf8(Fn) then
    begin
      MasterList.Delete(i);
      Msg := Format('"%s"',[Fn]) + LineEnding + Msg;
    end;
  end;
  if (Msg <> '') then
    //MessageDlg('PoChecker',Format(sFilesNotFoundAndRemoved,[Msg]), mtInformation, [mbOk], 0);
    Msg := Format(sFilesNotFoundAndRemoved,[Msg]);
  Cnt := MasterList.Count;
  if (Cnt = 0) then
    Msg := Msg + LineEnding + LineEnding + LineEnding + sNoFilesLeftToCheck;
  if (Msg <> '') then
    MemoDlg('PoChecker',Msg);
  if (Cnt = 0) then
  begin
    //MessageDlg('PoChecker', sNoFilesLeftToCheck, mtInformation, [mbOk], 0);
    Exit;
  end;
  try
    if Assigned(PoFamilyList) then PoFamilyList.Free;
    PoFamilyList := TPoFamilyList.Create(MasterList, LangID, Msg);
    if (Msg <> '') then
    begin
      //MessageDlg('PoChecker',Format(sFilesNotFoundAndRemoved,[Msg]), mtInformation, [mbOk], 0);
      Msg := Format(sFilesNotFoundAndRemoved,[Msg]);
      if (PoFamilyList.Count = 0) then
        Msg := Msg + LineEnding + LineEnding + LineEnding + sNoFilesLeftToCheck;
      if (Msg <> '') then
        MemoDlg('PoChecker',Msg);
      if (PoFamilyList.Count = 0) then
      begin
        //MessageDlg('PoChecker', sNoFilesLeftToCheck, mtInformation, [mbOk], 0);
        FreeAndNil(PoFamilyList);
        Exit;
      end;
    end;
    PoFamilyList.OnTestStart := @OnTestStart;
    PoFamilyList.OnTestEnd := @OnTestEnd;
    Result := True;
  except
    on E: Exception do
    begin
      Result := False;
      ShowError(Format(sErrorOnCreate, [E.Message]));
      if Assigned(PoFamilyList) then
      begin
        try
          FreeAndNil(PoFamilyList);
        except
          on E: Exception do
          begin
            ShowError(Format(sErrorOnCleanUp, [E.Message]));
          end;
        end;
      end;
    end;
  end;
end;


procedure TPoCheckerForm.RunSelectedTests;
var
  TestTypes: TPoTestTypes;
  TestOptions: TPoTestOptions;
  ErrorCount, WarningCount: integer;
  SL: TStrings;
  ResultDlg: TResultDlgForm;
  mr: TModalResult;
begin
  TestTypes := GetTestTypesFromListBox;
  if (TestTypes = []) then
  begin
    ShowError(sNoTestSelected);
    Exit;
  end;
  TestOptions := GetTestOptions;
  NoErrLabel.Visible := False;
  Application.ProcessMessages;
  SL := TStringList.Create;
  mr := mrNone;
  try
    PoFamilyList.TestTypes := TestTypes;
    PoFamilyList.TestOptions := TestOptions;
    PoFamilyList.RunTests(ErrorCount, WarningCount, SL);
    //debugln('RunSelectedTests: ', Format(sTotalErrors, [ErrorCount]));
    //debugln('                  ', Format(sTotalWarnings, [WarningCount]));
    if (ErrorCount > 0) or (WarningCount > 0) or
      (pttCheckStatistics in TestTypes) then
    begin
      SL.Add(Format(sTotalErrors, [ErrorCount]));
      SL.Add(Format(sTotalWarnings, [WarningCount]));
      ResultDlg := TResultDlgForm.Create(nil);
      try
        ResultDlg.Log.Assign(SL);
        FreeAndNil(SL);                 //No need to keep 2 copies of this data
        if (pttCheckStatistics in TestTypes) then
          ResultDlg.PoFamilyStats := PoFamilyList.PoFamilyStats
        else
          ResultDlg.PoFamilyStats := nil;
        ResultDlg.Settings := FPoCheckerSettings;
        mr := ResultDlg.ShowModal;
      finally
        ResultDlg.Free;
      end;
    end;
    NoErrLabel.Visible := (ErrorCount = 0);
  finally
    if Assigned(SL) then
      SL.Free;
    ClearStatusBar;
  end;
  if mr = mrOpenEditorFile then WindowState:= wsMinimized;
end;


procedure TPoCheckerForm.ClearStatusBar;
begin
  StatusBar.SimpleText := '';
end;

procedure TPoCheckerForm.UpdateGUI(HasSelection: Boolean);
begin
  NoErrLabel.Visible := False;
  if HasSelection then
  begin
    RunBtn.Enabled := True;
    TestListBox.Enabled := True;
    SelectAllTestsBtn.Enabled := True;
    SelectBasicTestsBtn.Enabled := True;
    UnselectAllTestsBtn.Enabled := True;
    UnselectAllMasterFilesBtn.Enabled := True;
    IgnoreFuzzyCheckBox.Enabled := True;
  end
  else
  begin
    RunBtn.Enabled := False;
    TestListBox.Enabled := False;
    SelectAllTestsBtn.Enabled := False;
    SelectBasicTestsBtn.Enabled := False;
    UnselectAllTestsBtn.Enabled := False;
    UnselectAllMasterFilesBtn.Enabled := False;
    IgnoreFuzzyCheckBox.Enabled := False;
  end;
  ClearMasterFilesBtn.Enabled := (MasterPoListBox.Items.Count > 0);
  SelectAllMasterFilesBtn.Enabled := (MasterPoListBox.Items.Count > 0);
end;

function TPoCheckerForm.GetSelectedMasterFiles: TStringList;
var
  i: Integer;
  Fn: String;
begin
  Result := TStringList.Create;
  for i := 0 to MasterPoListBox.Items.Count - 1 do
  begin
    Fn := MasterpoListBox.Items[i];
    if MasterPoListBox.Selected[i] then
      Result.Add(Fn);
  end;
end;

procedure TPoCheckerForm.AddToMasterPoList(Fn: String);
var
  Idx: Integer;
begin
  if not FileExistsUtf8(Fn) then Exit;
  Idx := MasterPoListBox.Items.IndexOf(Fn);
  if (Idx = -1) then
  begin
    MasterPoListBox.Items.Add(Fn);
  end;
end;

procedure TPoCheckerForm.AddToMasterPoList(S: TStrings);
var
  i, Idx: Integer;
  Str: String;
begin
  {
  Idx := MasterPoListBox.ItemIndex;
  if (Idx <> -1) then
    PrevItem := MasterPoListBox.Items[Idx]
  else
    PrevItem := '';
  }
  MasterPoListBox.Items.BeginUpdate;
  try
    for i := 0 to S.Count - 1 do
    begin
      Str := S[i];
      //skip files that do not exist (anymore)
      if FileExistsUtf8(Str) and IsMasterPoName(Str) then
      begin
        Idx := MasterPoListBox.Items.IndexOf(Str);
        if (Idx = -1) then
          MasterPoListBox.Items.Add(Str);
      end
    end;
    {
    if (PrevItem <> '') then
    begin
      Idx := MasterPoListBox.Items.IndexOf(PrevItem);
      MasterPoListBox.ItemIndex := Idx;
    end;
    }
  finally
    MasterPoListBox.Items.EndUpdate;
  end;
end;

procedure TPoCheckerForm.SetSelectedMasterFiles(S: TStrings);
var
  i, Idx: Integer;
  Fn: String;
  HasSelection: Boolean;
begin
  MasterPoListBox.ClearSelection;
  HasSelection := False;
  for i := 0 to S.Count - 1 do
  begin
    Fn := S.Strings[i];
    Idx := MasterPoListBox.Items.IndexOf(Fn);
    if (Idx <> -1) then
    begin
      MasterPoListBox.Selected[Idx] := True;
      HasSelection := True;
    end;
  end;
  //debugln('TPoCheckerForm.SetSelectedMasterFiles: S.Count = ',DbgS(S.Count),' HasSelection = ',DbgS(HasSelection));
  UpdateGUI(HasSelection);
end;


procedure TPoCheckerForm.ApplyConfig;
var
  ARect: TRect;
  Abbr: String;
  ID: TLangID;
begin
  ARect := FPoCheckerSettings.MainFormGeometry;
  if not IsDefaultRect(ARect) and IsValidRect(ARect) then
  begin
    ARect := FitToRect(ARect, Screen.WorkAreaRect);
    BoundsRect := ARect;
  end;
  SetTestTypeCheckBoxes(FPoCheckerSettings.TestTypes);
  SetTestOptionCheckBoxes(FPoCheckerSettings.TestOptions);
  SelectDirectoryDialog.Filename := FPoCheckerSettings.SelectDirectoryFilename;
  OpenDialog.FileName := FPoCheckerSettings.OpenDialogFilename;
  Abbr := FPoCheckerSettings.LangFilterLanguageAbbr;
  ID := LangAbbrToLangId(Abbr);
  LangFilter.ItemIndex := LangIdToLangFilterIndex(ID);
  AddToMasterPoList(FPoCheckerSettings.MasterPoList);
  SetSelectedMasterFiles(FPoCheckerSettings.MasterPoSelList);
end;

procedure TPoCheckerForm.SaveConfig;
var
  SL: TStringList;
  ID: TLangID;
begin
  FPoCheckerSettings.SelectDirectoryFilename := SelectDirectoryDialog.Filename;
  FPoCheckerSettings.OpenDialogFilename := OpenDialog.FileName;
  //FPoCheckerSettings.LangFilterIndex := LangFilter.ItemIndex;
  ID := LangFilterIndexToLangID(LangFilter.ItemIndex);
  FPoCheckerSettings.LangFilterLanguageAbbr := LanguageAbbr[ID];
  FPoCheckerSettings.TestTypes := GetTestTypesFromListBox;
  FPoCheckerSettings.TestOptions := GetTestOptions;
  FPoCheckerSettings.MainFormWindowState := WindowState;
  if (WindowState = wsNormal) then
    FPoCheckerSettings.MainFormGeometry := BoundsRect
  else
    FPoCheckerSettings.MainFormGeometry := Rect(RestoredLeft, RestoredTop, RestoredLeft + RestoredWidth, RestoredTop + RestoredHeight);
  FPoCheckerSettings.MasterPoList := MasterPoListBox.Items;
  SL := GetSelectedMasterFiles;
  try
    FPoCheckerSettings.MasterPoSelList := SL;
  finally
    SL.Free;
  end;
  FPoCheckerSettings.SaveConfig;
end;
function ListSortFunc(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := Utf8CompareText(List.Strings[Index1], List.Strings[Index2]);
end;

function TPoCheckerForm.LangFilterIndexToLangID(Index: Integer): TLangID;
//Requires that items for a language end in [%lang_abbr%]
var
  S, Abbr: String;
  p: Integer;
begin
  Result := lang_all;
  S := LangFilter.Items[Index];
  p := Length(S); //no need to use Utf8 functions, we look for lower ASCII
  if (p = 0) or (not (S[p] = ']')) then Exit;
  repeat
    Dec(p);
  until (p = 0) or (S[p] = '[');
  if (p = 0) then Exit;
  Abbr := Copy(S, p+1, Length(S)-p-1);
  //DbgOut('Abbr = ',Abbr);
  Result := LangAbbrToLangID(Abbr);
  //debugln(' ID = ',Result);
end;

function TPoCheckerForm.LangIdToLangFilterIndex(LangID: TLangID): Integer;
//Requires that items for a language end in [%lang_abbr%]
var
  Abbr, S: String;
  p: SizeInt;
  i: Integer;
begin
  Result := 0; // All Languages
  if (LangID = lang_all) then Exit;
  Abbr := LanguageAbbr[LangID];
  for i := 1 to LangFilter.Items.Count - 1 do
  begin
    S := LangFilter.Items[i];
    //no need to use Utf8 functions, we look for lower ASCII
    p := Pos('['+Abbr+']',S);
    if (p > 0) then
      Exit(i);
  end;
end;

procedure TPoCheckerForm.PopulateLangFilter;
var
  ID: TLangID;
  Abbr, LangName, S: String;
  SL: TStringList;
begin
  LangFilter.Items.BeginUpdate;
  SL := TStringList.Create;
  try
    LangFilter.Items.Clear;
    for ID := Succ(Low(TLangID)) to High(TLangID) do
    begin
      Abbr := LanguageAbbr[ID];
      LangName := LanguageNames[ID];
      S := Format('%s [%s]',[LangName, Abbr]);
      SL.Add(S);
      SL.CustomSort(@ListSortFunc);
    end;
    SL.Sorted := False;
    SL.Insert(0, LanguageNames[lang_all]);
    LangFilter.Items.Assign(SL);
    LangFilter.Items.EndUpdate;
    LangFilter.ItemIndex := 0;
  finally
    SL.Free;
    LangFilter.Items.EndUpdate;
  end;
end;

{$IFDEF POCHECKERSTANDALONE}
function TPoCheckerForm.GetTranslationsSearchPath: String;
var
  EnvVar, CfgLocal, CfgGlobal, AppPath: String;
begin
  Result := FPoCheckerSettings.LangPath;
  EnvVar := GetEnvironmentVariableUtf8('pochecker-langpath');
  if (EnvVar <> '') then
    Result := Result + PathSeparator + EnvVar;
  Result := Result + PathSeparator + '.';
  //Make some educated guesses
  //default Lazarus setup, launching the app from project output dir
  Result := Result + PathSeparator + '..' + PathDelim + 'languages';
  Result := Result + PathSeparator + SetDirSeparators('../../../lcl/languages');
  //or from where .lpi resides
  Result := Result + PathSeparator + '.' + PathDelim + 'languages';
  Result := Result + PathSeparator + SetDirSeparators('../../lcl/languages');
  //Look in standard config dirs
  CfgLocal := AppendPathDelim(GetLocalConfigPath);
  CfgGlobal := AppendPathDelim(GetGlobalConfigPath);
  Result := Result + PathSeparator + CfgLocal + PathSeparator + CfgLocal + 'languages';
  Result := Result + PathSeparator + CfgGlobal + PathSeparator + CfgGlobal + 'languages';
  {$if defined(windows) and not defined(wince)}
  AppPath := ExtractFilePath(ParamStr(0));
  Result := Result + PathSeparator + AppPath + PathSeparator + AppPath + 'languages';
  {$endif}
end;

procedure TPoCheckerForm.FindTranslationFiles(const SearchPath, Lang: String; out PoCheckPo, LclPo: String);
var
  SL: TStringList;
  i: Integer;
  LclPoFnOnly, PoCheckPoFnOnly, Path: String;
begin
  PoCheckPo := '';
  LclPo := '';
  PoCheckPoFnOnly := Format('pocheckerconsts.%s.po',[Lang]);
  LclPoFnOnly := Format('lclstrconsts.%s.po',[Lang]);
  //debugln('PoCheckPoFnOnly = "',PoCheckPoFnOnly,'"');
  //debugln('LclPoFnOnly"    = ',LclPoFnOnly,'"');
  SL := TStringList.Create;
  try
    SL.StrictDelimiter := True;
    SL.Delimiter := PathSeparator;
    SL.DelimitedText := SearchPath;
    for i := 0 to SL.Count - 1 do
    begin
      Path := SL.Strings[i];
      if (Path <> '') then
      begin
        //debugln('Path = ',ExpandFileNameUtf8(Path));
        if (Path <> '') then
          Path := AppendPathDelim(Path);
        if (LclPo = '') and FileExistsUtf8(Path + PoCheckPoFnOnly) then
          PoCheckPo := Path + PoCheckPoFnOnly;
        if (LclPo = '') and FileExistsUtf8(Path + LclPoFnOnly) then
          LclPo := Path + LclPoFnOnly;
      end;
      if (LclPo <> '') and (LclPo <> '') then
        Break;
    end;
  finally
    SL.Free;
  end;
end;


procedure TPoCheckerForm.GetTranslations;
var
  Lang, T, SearchPath, PoCheckerPo, LclPo: string;
begin
  Lang := GetEnvironmentVariableUTF8('LANG');
  T := '';
  if Lang = '' then
    LCLGetLanguageIDs(Lang, T);
  if Lang <> '' then
  begin
    //debugln('TPoCheckerForm.GetTranslations: Lang = ',Lang);
    if not ((Lang = 'af_ZA') or (Lang = 'pt_BR') or (Lang = 'zh_CN')) then
      Lang := copy(Lang, 1, 2);
    SearchPath := GetTranslationsSearchPath;
    FindTranslationFiles(SearchPath, Lang, PoCheckerPo, LclPo);
    //debugln('PoCheckerPo = "',PoCheckerPo,'"');
    //debugln('LclPo = "',LclPo,'"');
    Translations.TranslateUnitResourceStrings('PoCheckerConsts', PoCheckerPo);
    Translations.TranslateUnitResourceStrings('LCLStrConsts', LclPo);
  end;
end;
{$ENDIF}

procedure TPoCheckerForm.ApplyTranslations;
begin
  LocalizePoTestTypeNames;
  LocalizeLanguageNames;
  Caption := sGUIPoFileCheckingTool;
  SelectTestLabel.Caption := sSelectTestTypes;
  //FindAllPOsCheckBox.Caption := sFindAllTranslatedPoFiles;
  IgnoreFuzzyCheckBox.Caption := sIgnoreFuzzyTranslations;
  OpenBtn.Caption := sOpenAPoFile;
  ScanDirBtn.Caption := sScanDir;
  RunBtn.Caption := sRunSelectedTests;
  ClearMasterFilesBtn.Caption := sClearListBox;
  UnselectAllMasterFilesBtn.Caption := sUnselectListBox;
  SelectAllMasterFilesBtn.Caption := sSelectAllListBox;
  LangFilter.Items[0] := sAllLanguages;
  NoErrLabel.Caption := sNoErrorsFound;
  SelectAllTestsBtn.Caption := sSelectAllTests;
  SelectBasicTestsBtn.Caption := sSelectBasicTests;
  UnselectAllTestsBtn.Caption := sUnselectAllTests;
end;


function SameItem(Item1, Item2: TPoFileItem): boolean;
begin
  Result := (Item1.IdentifierLow = Item2.IdentifierLow) and
    (Item1.Original = Item2.Original) and (Item1.Context = Item2.Context) and
    (Item1.Flags = Item2.Flags) and (Item1.PreviousID = Item2.PreviousID) and
    (Item1.Translation = Item2.Translation);
end;


procedure IDEMenuClicked(Sender: TObject);
begin
  ShowPoCheckerForm;
end;


procedure Register;
begin
  {$IFNDEF POCHECKERSTANDALONE}
  RegisterIDEMenuCommand(itmSecondaryTools, 'mnuPoChecker',
    rsPoChecker, nil, @IDEMenuClicked);
  {$ENDIF}
end;

end.
