{ $Id$}
{
 *****************************************************************************
 *                             Win32WSDialogs.pp                             *
 *                             -----------------                             *
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit Win32WSDialogs;

{$mode objfpc}{$H+}
{$I win32defines.inc}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
// rtl
  Windows, shlobj, ShellApi, ActiveX, SysUtils, Classes,
  CommDlg,
// lcl
  LCLProc, LCLType, Dialogs, Controls, Graphics, Forms, FileUtil,
// ws
  WSDialogs, WSLCLClasses, Win32Extra, Win32Int, InterfaceBase,
  Win32Proc;

type
  TApplicationState = record
    FocusedWindow: HWND;
    DisabledWindows: TList;
  end;

  TOpenFileDialogRec = record
    Dialog: TFileDialog;
    AnsiFolderName: string;
    AnsiFileNames: string;
    UnicodeFolderName: widestring;
    UnicodeFileNames: widestring
  end;
  POpenFileDialogRec = ^TOpenFileDialogRec;

  { TWin32WSCommonDialog }

  TWin32WSCommonDialog = class(TWSCommonDialog)
  published
    class function CreateHandle(const ACommonDialog: TCommonDialog): THandle; override;
    class procedure DestroyHandle(const ACommonDialog: TCommonDialog); override;
  end;

  { TWin32WSFileDialog }

  TWin32WSFileDialog = class(TWSFileDialog)
  published
  end;

  { TWin32WSOpenDialog }

  TWin32WSOpenDialog = class(TWSOpenDialog)
  published
    class function CreateHandle(const ACommonDialog: TCommonDialog): THandle; override;
    class procedure DestroyHandle(const ACommonDialog: TCommonDialog); override;
    class procedure ShowModal(const ACommonDialog: TCommonDialog); override;
  end;

  { TWin32WSSaveDialog }

  TWin32WSSaveDialog = class(TWSSaveDialog)
  published
    class procedure ShowModal(const ACommonDialog: TCommonDialog); override;
  end;

  { TWin32WSSelectDirectoryDialog }

  TWin32WSSelectDirectoryDialog = class(TWSSelectDirectoryDialog)
  published
    class function CreateHandle(const ACommonDialog: TCommonDialog): THandle; override;
  end;

  { TWin32WSColorDialog }

  TWin32WSColorDialog = class(TWSColorDialog)
  published
    class function CreateHandle(const ACommonDialog: TCommonDialog): THandle; override;
    class procedure ShowModal(const ACommonDialog: TCommonDialog); override;
    class procedure DestroyHandle(const ACommonDialog: TCommonDialog); override;
  end;

  { TWin32WSColorButton }

  TWin32WSColorButton = class(TWSColorButton)
  published
  end;

  { TWin32WSFontDialog }

  TWin32WSFontDialog = class(TWSFontDialog)
  published
    class function CreateHandle(const ACommonDialog: TCommonDialog): THandle; override;
  end;

function OpenFileDialogCallBack(Wnd: HWND; uMsg: UINT; wParam: WPARAM;
  lParam: LPARAM): UINT; stdcall;

function SaveApplicationState: TApplicationState;
procedure RestoreApplicationState(AState: TApplicationState);

implementation

function SaveApplicationState: TApplicationState;
begin
  Result.FocusedWindow := Windows.GetFocus;
  Result.DisabledWindows := Screen.DisableForms(nil);
end;

procedure RestoreApplicationState(AState: TApplicationState);
begin
  Screen.EnableForms(AState.DisabledWindows);
  Windows.SetFocus(AState.FocusedWindow);
end;

// The size of the OPENFILENAME record depends on the windows version
// In the initialization section the correct size is determined.
var
  OpenFileNameSize: integer = 0;

// Returns a new PWideChar containing the string UTF8 string s as widechars
function UTF8StringToPWideChar(const s: string) : PWideChar;
begin
  // a string of widechars will need at most twice the amount of bytes
  // as the corresponding UTF8 string
  Result := GetMem(length(s)*2+2);
  Utf8ToUnicode(Result,length(s)+1,pchar(s),length(s)+1);
end;

// Returns a new PChar containing the string UTF8 string s as ansichars
function UTF8StringToPAnsiChar(const s: string) : PAnsiChar;
var
  AnsiChars: string;
begin
  AnsiChars:= Utf8ToAnsi(s);
  Result := GetMem(length(AnsiChars)+1);
  Move(PChar(AnsiChars)^, Result^, length(AnsiChars)+1);
end;

procedure UpdateFileProperties(OpenFile: LPOPENFILENAME);
var
  DialogRec: POpenFileDialogRec;
  AOpenDialog: TOpenDialog;

  procedure SetFilesPropertyCustomFiles(AFiles:TStrings);

    procedure AddFile(FolderName, FileName: String); inline;
    begin
      if ExtractFilePath(FileName) = '' then
        AFiles.Add(FolderName + FileName)
      else
        AFiles.Add(FileName);
    end;

  var
    i, Start, len: integer;
    FolderName: string;
    FileNames: string;
  begin
    {$ifdef WindowsUnicodeSupport}
    if UnicodeEnabledOS then
    begin
      FolderName := UTF16ToUTF8(DialogRec^.UnicodeFolderName);
      FileNames := UTF16ToUTF8(DialogRec^.UnicodeFileNames);
    end
    else
    begin
      FolderName := AnsiToUtf8(DialogRec^.AnsiFolderName);
      FileNames := AnsiToUtf8(DialogRec^.AnsiFileNames);
    end;
    {$else}
    FolderName:= DialogRec^.AnsiFolderName;
    FileNames := DialogRec^.AnsiFileNames;
    {$endif}
    FolderName := AppendPathDelim(FolderName);
    len := Length(FileNames);
    if (len > 0) and (FileNames[1] = '"') then
    begin
      Start := 1; // first quote is on pos 1
      while (start <= len) and (FileNames[Start] <> #0) do
      begin
        i := Start + 1;
        while FileNames[i] <> '"' do
          inc(i);
        AddFile(FolderName, Copy(FileNames, Start + 1, I - Start - 1));
        Start := i + 1;
        while (Start <= len) and (FileNames[Start] <> #0) and (FileNames[Start] <> '"') do
          inc(Start);
      end;
    end
    else
      AddFile(FolderName, FileNames);
  end;

  procedure SetFilesPropertyForOldStyle(AFiles:TStrings);
  var
    SelectedStr: string;
    FolderName: string;
    I,Start: integer;
  begin
    {$ifdef WindowsUnicodeSupport}
       if UnicodeEnabledOS then
         SelectedStr:=UTF16ToUTF8(widestring(PWideChar(OpenFile^.lpStrFile)))
       else
         SelectedStr:=AnsiToUtf8(OpenFile^.lpStrFile);
    {$else}
    SelectedStr:=OpenFile^.lpStrFile;
    {$endif}
    if not (ofAllowMultiSelect in AOpenDialog.Options) then
      AFiles.Add(SelectedStr)
    else begin
      Start:=Pos(' ',SelectedStr);
      FolderName := copy(SelectedStr,1,start-1);
      SelectedStr:=SelectedStr+' ';
      inc(start);
      for I:= Start to Length(SelectedStr) do
        if SelectedStr[I] =  ' ' then
        begin
          AFiles.Add(ExpandFileNameUTF8(FolderName+Copy(SelectedStr,Start,I - Start)));
          Start:=Succ(I);
        end;
    end;
  end;

begin
  DialogRec := POpenFileDialogRec(OpenFile^.lCustData);
  AOpenDialog := TOpenDialog(DialogRec^.Dialog);
  AOpenDialog.Files.Clear;
  AOpenDialog.FilterIndex := OpenFile^.nFilterIndex;
  if (ofOldStyleDialog in AOpenDialog.Options) then
    SetFilesPropertyForOldStyle(AOpenDialog.Files)
  else
    SetFilesPropertyCustomFiles(AOpenDialog.Files);
  AOpenDialog.FileName := AOpenDialog.Files[0];
end;

{------------------------------------------------------------------------------
  Method: GetOwnerHandle
  Params:  ADialog - dialog to get 'guiding parent' window handle for
  Returns: A window handle

  Returns window handle to be used as 'owner handle', ie. so that the user must
  finish the dialog before continuing
 ------------------------------------------------------------------------------}
function GetOwnerHandle(ADialog : TCommonDialog): HWND;
begin
  with ADialog do
  begin
    if Owner is TWinControl then
      Result := TWinControl(Owner).Handle
    else
      Result := TWin32WidgetSet(WidgetSet).AppHandle;
  end;
end;

procedure SetDialogResult(const ACommonDialog: TCommonDialog; Ret: WINBOOL);
begin
  if Ret then
    ACommonDialog.UserChoice := mrOK
  else
    ACommonDialog.UserChoice := mrCancel;
end;

{ TWin32WSColorDialog }

class function TWin32WSColorDialog.CreateHandle(const ACommonDialog: TCommonDialog): THandle;
var
  CC: PChooseColor;
  ColorDialog: TColorDialog absolute ACommonDialog;

  procedure FillCustomColors;
  var
    i, AIndex: integer;
    AColor: TColor;
  begin
    for i := 0 to ColorDialog.CustomColors.Count - 1 do
      if ExtractColorIndexAndColor(ColorDialog.CustomColors, i, AIndex, AColor) then
      begin
        if AIndex < 16 then
          CC^.lpCustColors[AIndex] := AColor;
      end;
  end;

begin
  CC := AllocMem(SizeOf(TChooseColor));
  with CC^ Do
  begin
    LStructSize := sizeof(TChooseColor);
    HWndOwner := GetOwnerHandle(ACommonDialog);
    RGBResult := ColorToRGB(ColorDialog.Color);
    LPCustColors := AllocMem(16 * SizeOf(DWord));
    FillCustomColors;
    Flags := CC_FULLOPEN or CC_RGBINIT;
  end;
  Result := THandle(CC);
end;

class procedure TWin32WSColorDialog.ShowModal(const ACommonDialog: TCommonDialog);
var
  CC: PChooseColor;
  UserResult: WINBOOL;
  State: TApplicationState;
begin
  if ACommonDialog.Handle <> 0 then
  begin
    State := SaveApplicationState;
    try
      CC := PChooseColor(ACommonDialog.Handle);

      UserResult := ChooseColor(CC);
      SetDialogResult(ACommonDialog, UserResult);
      if UserResult then
        TColorDialog(ACommonDialog).Color := CC^.RGBResult;
    finally
      RestoreApplicationState(State);
    end;
  end;
end;

class procedure TWin32WSColorDialog.DestroyHandle(
  const ACommonDialog: TCommonDialog);
var
  CC: PChooseColor;
begin
  if ACommonDialog.Handle <> 0 then
  begin
    CC := PChooseColor(ACommonDialog.Handle);
    FreeMem(CC^.lpCustColors);
    FreeMem(CC);
  end;
end;

procedure UpdateStorage(Wnd: HWND; OpenFile: LPOPENFILENAME);
var
  FilesSize: SizeInt;
  FolderSize: SizeInt;
  DialogRec: POpenFileDialogRec;
begin
  DialogRec := POpenFileDialogRec(OpenFile^.lCustData);
  {$ifdef WindowsUnicodeSupport}
  if UnicodeEnabledOS then
  begin
    FolderSize := SendMessageW(GetParent(Wnd), CDM_GETFOLDERPATH, 0, LPARAM(nil));
    FilesSize := SendMessageW(GetParent(Wnd), CDM_GETSPEC, 0, LPARAM(nil));
    SetLength(DialogRec^.UnicodeFolderName, FolderSize - 1);
    SendMessageW(GetParent(Wnd), CDM_GETFOLDERPATH, FolderSize,
                 LPARAM(PWideChar(DialogRec^.UnicodeFolderName)));

    SetLength(DialogRec^.UnicodeFileNames, FilesSize - 1);
    SendMessageW(GetParent(Wnd), CDM_GETSPEC, FilesSize,
                 LPARAM(PWideChar(DialogRec^.UnicodeFileNames)));
  end else
  {$endif}
  begin
    FolderSize := CommDlg_OpenSave_GetFolderPath(GetParent(Wnd), nil, 0);
    FilesSize := CommDlg_OpenSave_GetSpec(GetParent(Wnd), nil, 0);
    SetLength(DialogRec^.AnsiFolderName, FolderSize - 1);
    CommDlg_OpenSave_GetFolderPath(GetParent(Wnd),
                        PChar(DialogRec^.AnsiFolderName),
                        FolderSize);

    SetLength(DialogRec^.AnsiFileNames, FilesSize - 1);
    CommDlg_OpenSave_GetSpec(GetParent(Wnd),
      PChar(DialogRec^.AnsiFileNames),
      FilesSize);
  end;
end;

{Common code for OpenDialog and SaveDialog}

{The API of the multiselect open file dialog is a bit problematic.
 Before calling the OpenFile function you must create a buffer (lpStrFile) to
 hold the selected files.

 With a multiselect dialog there is no way to create a buffer with correct size:
 * either it is too small (for example 1 KB), if a lot a files are selected
 * or it wastes a lot of memory (for example 1 MB), and even than you have no
   guarantee, that is big enough.

 The OpenFile API call returns false, if an error has occurred or the user has
 pressed cancel. If there was an error CommDlgExtendedError returns
 FNERR_BUFFERTOOSMALL. But enlarging the buffer at that time is not usefull
 anymore, unless you show the dialog again with a bigger buffer (Sorry, the
 buffer was too small, please select the files again). This is not acceptable.

 It is possible to hook the filedialog, so you get messages, when the selection
 changes. A naive aproach would be to see, if the buffer would be big enough for
 the selected files and create or enlarge the buffer (as described in KB131462).
 Unfortunately, this only works with win9x and the unicode versions of later
 windows versions.

 Therefore in the hook function, if the size of the initial buffer (lpStrFile)
 is not large enough, the selected files are copied into a string. A pointer to
 this string is kept in the lCustData field of the the OpenFileName struct.
 When dialog is closed with a FNERR_BUFFERTOOSMALL error, this string is used to
 get the selected files. If this error did not occur, the normal way of
 retrieving the files is used.
}

function OpenFileDialogCallBack(Wnd: HWND; uMsg: UINT; wParam: WPARAM;
  lParam: LPARAM): UINT; stdcall;

  procedure Reposition(ADialogWnd: Handle);
  var
    Left, Top: Integer;
    DialogRect: TRect;
  begin
    // Btw, setting width and height of dialog doesnot reposition child controls :(
    // So no way to set another height and width at least here

    // do reposition only if dialog has no parent form
    if (GetParent(ADialogWnd) = Win32WidgetSet.AppHandle) then
    begin
      GetWindowRect(ADialogWnd, @DialogRect);

      Left := (GetSystemMetrics(SM_CXSCREEN) - DialogRect.Right + DialogRect.Left) div 2;
      Top := (GetSystemMetrics(SM_CYSCREEN) - DialogRect.Bottom + DialogRect.Top) div 2;
      SetWindowPos(ADialogWnd, HWND_TOP, Left, Top, 0, 0, SWP_NOSIZE);
    end;
  end;

var
  OpenFileNotify: LPOFNOTIFY;
  OpenFileName: Windows.POPENFILENAME;
  DialogRec: POpenFileDialogRec;
begin
  if uMsg = WM_INITDIALOG then
  begin
    // Windows asks us to initialize dialog. At this moment controls are not
    // arranged and this is that moment when we should set bounds of our dialog
    Reposition(GetParent(Wnd));
  end
  else
  if uMsg = WM_NOTIFY then
  begin
    OpenFileNotify := LPOFNOTIFY(lParam);
    if OpenFileNotify = nil then
      Exit;

    OpenFileName := OpenFileNotify^.lpOFN;
    DialogRec := POpenFileDialogRec(OpenFileName^.lCustData);
    UpdateStorage(Wnd, OpenFileName);
    UpdateFileProperties(OpenFileName);

    case OpenFileNotify^.hdr.code of
      CDN_INITDONE:
        TOpenDialog(DialogRec^.Dialog).DoShow;
      CDN_SELCHANGE:
        TOpenDialog(DialogRec^.Dialog).DoSelectionChange;
      CDN_FOLDERCHANGE:
        TOpenDialog(DialogRec^.Dialog).DoFolderChange;
      CDN_TYPECHANGE:
        DialogRec^.Dialog.IntfFileTypeChanged(OpenFileNotify^.lpOFN^.nFilterIndex);
    end;
  end;
  Result := 0;
end;

function CreateFileDialogHandle(AOpenDialog: TOpenDialog): THandle;
  function GetFlagsFromOptions(Options: TOpenOptions): DWord;
  begin
    Result := OFN_ENABLEHOOK;
    if ofAllowMultiSelect in Options then Result := Result or OFN_ALLOWMULTISELECT;
    if ofCreatePrompt in Options then Result := Result or OFN_CREATEPROMPT;
    if not (ofOldStyleDialog in Options) then Result := Result or OFN_EXPLORER;
    if ofExtensionDifferent in Options then Result := Result or OFN_EXTENSIONDIFFERENT;
    if ofFileMustExist in Options then Result := Result or OFN_FILEMUSTEXIST;
    if ofHideReadOnly in Options then Result := Result or OFN_HIDEREADONLY;
    if ofNoChangeDir in Options then Result := Result or OFN_NOCHANGEDIR;
    if ofNoDereferenceLinks in Options then Result := Result or OFN_NODEREFERENCELINKS;
    if ofEnableSizing in Options then Result := Result or OFN_ENABLESIZING;
    if ofNoLongNames in Options then  Result := Result or OFN_NOLONGNAMES;
    if ofNoNetworkButton in Options then Result := Result or OFN_NONETWORKBUTTON;
    if ofNoReadOnlyReturn in  Options then Result := Result or OFN_NOREADONLYRETURN;
    if ofNoTestFileCreate in Options then Result := Result or OFN_NOTESTFILECREATE;
    if ofNoValidate in Options then Result := Result or OFN_NOVALIDATE;
    if ofOverwritePrompt in Options then Result := Result or OFN_OVERWRITEPROMPT;
    if ofPathMustExist in Options then Result := Result or OFN_PATHMUSTEXIST;
    if ofReadOnly in Options then Result := Result or OFN_READONLY;
    if ofShareAware in Options then Result := Result or OFN_SHAREAWARE;
    if ofShowHelp in Options then Result := Result or OFN_SHOWHELP;
  end;

  procedure ReplacePipe(var AFilter:string);
  var i:integer;
  begin
    for i := 1 to length(AFilter) do
      if AFilter[i] = '|' then AFilter[i]:=#0;
    AFilter:=AFilter + #0;
  end;

  function GetDefaultExt: String;
  begin
    Result := AOpenDialog.DefaultExt;
    if UTF8Pos('.', Result) = 1 then
      UTF8Delete(Result, 1, 1);
  end;

const
  FileNameBufferLen = 1000;
var
  DialogRec: POpenFileDialogRec;
  OpenFile: LPOPENFILENAME;
  Filter, FileName, InitialDir, DefaultExt: String;
  FileNameBuffer: PChar;
{$ifdef WindowsUnicodeSupport}
  FileNameWide: WideString;
  FileNameWideBuffer: PWideChar;
  FileNameBufferSize: Integer;
{$endif WindowsUnicodeSupport}
begin
  FileName := AOpenDialog.FileName;
  InitialDir := AOpenDialog.InitialDir;
  if (FileName<>'') and (FileName[length(FileName)]=PathDelim) then
  begin
    // if the filename contains a directory, set the initial directory
    // and clear the filename
    InitialDir := Copy(FileName,1, Length(FileName)-1);
    FileName := '';
  end;

  DefaultExt := GetDefaultExt;

  {$ifdef WindowsUnicodeSupport}
    if UnicodeEnabledOS then
    begin
      FileNameWideBuffer := AllocMem(FileNameBufferLen * 2 + 2);
      FileNameWide := UTF8ToUTF16(FileName);

      if Length(FileNameWide) > FileNameBufferLen then
        FileNameBufferSize := FileNameBufferLen
      else
        FileNameBufferSize := Length(FileNameWide);

      Move(PChar(FileNameWide)^, FileNameWideBuffer^, FileNameBufferSize * 2);
    end
    else begin
      FileNameBuffer := AllocMem(FileNameBufferLen + 1);
      StrLCopy(FileNameBuffer, PChar(UTF8ToAnsi(FileName)), FileNameBufferLen);
    end;
  {$else}
    FileNameBuffer := AllocMem(FileNameBufferLen + 1);
    StrLCopy(FileNameBuffer, PChar(FileName), FileNameBufferLen);
  {$endif}

  if AOpenDialog.Filter <> '' then
  begin
    Filter := AOpenDialog.Filter;
    ReplacePipe(Filter);
  end
  else
    Filter:='All File Types(*.*)'+#0+'*.*'+#0; // Default -> avoid empty combobox

  OpenFile := AllocMem(SizeOf(OpenFileName));
  with OpenFile^ do
  begin
    lStructSize := OpenFileNameSize;
    hWndOwner := GetOwnerHandle(AOpenDialog);
    hInstance := System.hInstance;

    nFilterIndex := AOpenDialog.FilterIndex;

  {$ifdef WindowsUnicodeSupport}
    if UnicodeEnabledOS then
    begin
      lpStrFile := PChar(FileNameWideBuffer);
      lpstrFilter:=PChar(UTF8StringToPWideChar(Filter));
      lpstrTitle:=PChar(UTF8StringToPWideChar(AOpenDialog.Title));
      lpstrInitialDir:=PChar(UTF8StringToPWideChar(InitialDir));
      lpstrDefExt:=PChar(UTF8StringToPWideChar(DefaultExt))
    end
    else
    begin
      lpStrFile := FileNameBuffer;
      lpstrFilter:=UTF8StringToPAnsiChar(Filter);
      lpstrTitle:=UTF8StringToPAnsiChar(AOpenDialog.Title);
      lpstrInitialDir:=UTF8StringToPAnsiChar(InitialDir);
      lpstrDefExt:=UTF8StringToPAnsiChar(DefaultExt);
    end;
  {$else}
    lpStrFile := FileNameBuffer;

    lpStrFilter := GetMem(Length(Filter)+1);
    StrPCopy(lpStrFilter, Filter);

    lpStrTitle := GetMem(Length(AOpenDialog.Title)+1);
    StrPCopy(lpStrTitle, AOpenDialog.Title);

    lpStrInitialDir := GetMem(Length(InitialDir)+1);
    StrPCopy(lpstrInitialDir, InitialDir);

    lpstrDefExt := GetMem(Length(DefaultExt)+1);
    StrPCopy(lpstrDefExt, DefaultExt);
  {$endif}


    nMaxFile := FileNameBufferLen + 1; // Size in TCHARs
    lpfnHook := @OpenFileDialogCallBack;
    Flags := GetFlagsFromOptions(AOpenDialog.Options);
    New(DialogRec);
    // new initializes the filename fields, because ansistring and widestring
    // are automated types.
    DialogRec^.Dialog := AOpenDialog;
    lCustData := LParam(DialogRec);
  end;
  Result := THandle(OpenFile);
end;

procedure ProcessFileDialogResult(AOpenDialog: TOpenDialog; UserResult: WordBool);
var
  OpenFile: LPOPENFILENAME;
begin
  OpenFile := LPOPENFILENAME(AOpenDialog.Handle);
  if not UserResult and (CommDlgExtendedError = FNERR_BUFFERTOOSMALL) then
    UserResult := True;
  SetDialogResult(AOpenDialog, UserResult);
  if UserResult then
  begin
    UpdateFileProperties(OpenFile);
    AOpenDialog.IntfSetOption(ofExtensionDifferent, OpenFile^.Flags and OFN_EXTENSIONDIFFERENT <> 0);
    AOpenDialog.IntfSetOption(ofReadOnly, OpenFile^.Flags and OFN_READONLY <> 0);
  end
  else
  begin
    AOpenDialog.Files.Clear;
    AOpenDialog.FileName := '';
  end;
end;

{ TWin32WSOpenDialog }

class function TWin32WSOpenDialog.CreateHandle(const ACommonDialog: TCommonDialog): THandle;
begin
  Result := CreateFileDialogHandle(TOpenDialog(ACommonDialog));
end;

class procedure TWin32WSOpenDialog.DestroyHandle(const ACommonDialog: TCommonDialog);
var
  OPENFILE: LPOPENFILENAME;
begin
  if ACommonDialog.Handle <> 0 then
  begin
    OPENFILE := LPOPENFILENAME(ACommonDialog.Handle);
    if OPENFILE^.lCustData <> 0 then
      Dispose(POpenFileDialogRec(OPENFILE^.lCustData));

    FreeMem(OpenFile^.lpStrFilter);
    FreeMem(OpenFile^.lpstrInitialDir);
    FreeMem(OpenFile^.lpStrFile);
    FreeMem(OpenFile^.lpStrTitle);
    FreeMem(OpenFile^.lpTemplateName);
    FreeMem(OpenFile^.lpstrDefExt);
    FreeMem(OpenFile);
  end;
end;

class procedure TWin32WSOpenDialog.ShowModal(const ACommonDialog: TCommonDialog);
var
  State: TApplicationState;
begin
  if ACommonDialog.Handle <> 0 then
  begin
    State := SaveApplicationState;
    try
    {$ifdef WindowsUnicodeSupport}
      if UnicodeEnabledOS then
        ProcessFileDialogResult(TOpenDialog(ACommonDialog),
          GetOpenFileNameW(LPOPENFILENAME(ACommonDialog.Handle)))
      else
        ProcessFileDialogResult(TOpenDialog(ACommonDialog),
          GetOpenFileName(LPOPENFILENAME(ACommonDialog.Handle)));
    {$else}
      ProcessFileDialogResult(TOpenDialog(ACommonDialog),
        GetOpenFileName(LPOPENFILENAME(ACommonDialog.Handle)));
    {$endif}
    finally
      RestoreApplicationState(State);
    end;
  end;
end;

{ TWin32WSSaveDialog }

class procedure TWin32WSSaveDialog.ShowModal(const ACommonDialog: TCommonDialog);
var
  State: TApplicationState;
begin
  if ACommonDialog.Handle <> 0 then
  begin
    State := SaveApplicationState;
    try
    {$ifdef WindowsUnicodeSupport}
      if UnicodeEnabledOS then
        ProcessFileDialogResult(TOpenDialog(ACommonDialog),
          GetSaveFileNameW(LPOPENFILENAME(ACommonDialog.Handle)))
      else
        ProcessFileDialogResult(TOpenDialog(ACommonDialog),
          GetSaveFileName(LPOPENFILENAME(ACommonDialog.Handle)));
    {$else}
      ProcessFileDialogResult(TOpenDialog(ACommonDialog),
        GetSaveFileName(LPOPENFILENAME(ACommonDialog.Handle)));
    {$endif}
    finally
      RestoreApplicationState(State);
    end;
  end;
end;

{ TWin32WSFontDialog }

class function TWin32WSFontDialog.CreateHandle(const ACommonDialog: TCommonDialog): THandle;

  function GetFlagsFromOptions(Options : TFontDialogOptions): dword;
  begin
    Result := 0;
    if fdAnsiOnly in Options then Result := Result or CF_ANSIONLY;
    if fdTrueTypeOnly in Options then Result := Result or CF_TTONLY;
    if fdEffects in Options then Result := Result or CF_EFFECTS;
    if fdFixedPitchOnly in Options then Result := Result or CF_FIXEDPITCHONLY;
    if fdForceFontExist in Options then Result := Result or CF_FORCEFONTEXIST;
    if fdNoFaceSel in Options then Result := Result or CF_NOFACESEL;
    if fdNoOEMFonts in Options then Result := Result or CF_NOOEMFONTS;
    if fdNoSimulations in Options then Result := Result or CF_NOSIMULATIONS;
    if fdNoSizeSel in Options then Result := Result or CF_NOSIZESEL;
    if fdNoStyleSel in Options then Result := Result or CF_NOSTYLESEL;
    if fdNoVectorFonts in Options then Result := Result or CF_NOVECTORFONTS;
    if fdShowHelp in Options then Result := Result or CF_SHOWHELP;
    if fdWysiwyg in Options then Result := Result or CF_WYSIWYG;
    if fdLimitSize in Options then Result := Result or CF_LIMITSIZE;
    if fdScalableOnly in Options then Result := Result or CF_SCALABLEONLY;
    if fdApplyButton in Options then Result := Result or CF_APPLY;
  end;

var
{$ifdef WindowsUnicodeSupport}
  CFW: TChooseFontW;
  LFW: LogFontW;
  CF: TChooseFontA absolute CFW;
  LF: LogFontA absolute LFW;
{$else}
  CF: TChooseFont;
  LF: LogFont;
{$endif}
  UserResult: WINBOOL;
begin
  with TFontDialog(ACommonDialog) do
  begin
  {$ifdef WindowsUnicodeSupport}
    ZeroMemory(@CFW, sizeof(TChooseFontW));
    ZeroMemory(@LFW, sizeof(LogFontW));
    if UnicodeEnabledOS then
    begin
      with LFW do
      begin
        LFHeight := Font.Height;
        LFFaceName := UTF8ToUTF16(Font.Name);
        if (fsBold in Font.Style) then LFWeight:= FW_BOLD;
        LFItalic := byte(fsItalic in Font.Style);
        LFStrikeOut := byte(fsStrikeOut in Font.Style);
        LFUnderline := byte(fsUnderline in Font.Style);
        LFCharSet := Font.CharSet;
      end;
      with CFW do
      begin
        LStructSize := sizeof(TChooseFont);
        HWndOwner := GetOwnerHandle(ACommonDialog);
        LPLogFont := commdlg.PLOGFONTW(@LFW);
        Flags := GetFlagsFromOptions(Options);
        Flags := Flags or CF_INITTOLOGFONTSTRUCT or CF_BOTH;
        RGBColors := DWORD(Font.Color);
      end;
      UserResult := ChooseFontW(@CFW);
      // we need to update LF now
      LF.lfFaceName := UTF16ToUTF8(LFW.lfFaceName);
    end
    else
    begin
      with LF do
      begin
        LFHeight := Font.Height;
        LFFaceName := Utf8ToAnsi(Font.Name);
        if (fsBold in Font.Style) then LFWeight:= FW_BOLD;
        LFItalic := byte(fsItalic in Font.Style);
        LFStrikeOut := byte(fsStrikeOut in Font.Style);
        LFUnderline := byte(fsUnderline in Font.Style);
        LFCharSet := Font.CharSet;
      end;
      with CF do
      begin
        LStructSize := sizeof(TChooseFont);
        HWndOwner := GetOwnerHandle(ACommonDialog);
        LPLogFont := commdlg.PLOGFONTA(@LF);
        Flags := GetFlagsFromOptions(Options);
        Flags := Flags or CF_INITTOLOGFONTSTRUCT or CF_BOTH;
        RGBColors := DWORD(Font.Color);
      end;
      UserResult := ChooseFontA(@CF);
    end
  {$else}
    ZeroMemory(@CF, sizeof(TChooseFont));
    ZeroMemory(@LF, sizeof(LogFont));
    with LF do
    begin
      LFHeight := Font.Height;
      LFFaceName := TFontDataName(Font.Name);
      if (fsBold in Font.Style) then LFWeight:= FW_BOLD;
      LFItalic := byte(fsItalic in Font.Style);
      LFStrikeOut := byte(fsStrikeOut in Font.Style);
      LFUnderline := byte(fsUnderline in Font.Style);
      LFCharSet := Font.CharSet;
    end;
    with CF do
    begin
      LStructSize := sizeof(TChooseFont);
      HWndOwner := GetOwnerHandle(ACommonDialog);
      LPLogFont := commdlg.PLOGFONT(@LF);
      Flags := GetFlagsFromOptions(Options);
      Flags := Flags or CF_INITTOLOGFONTSTRUCT or CF_BOTH;
      RGBColors := DWORD(Font.Color);
    end;
    UserResult := ChooseFont(@CF);
  {$endif}
  end;

  SetDialogResult(ACommonDialog, UserResult);
  if UserResult then
  begin
    with TFontDialog(ACommonDialog).Font do
    begin
      Assign(LF);
      Color := CF.RGBColors;
    end;
  end;

  Result := 0;
end;

{ TWin32WSCommonDialog }

class function TWin32WSCommonDialog.CreateHandle(const ACommonDialog: TCommonDialog): THandle;
begin
  DebugLn('TWin32WSCommonDialog.CreateHandle: unhandled dialog!');
  Result := 0;
end;

class procedure TWin32WSCommonDialog.DestroyHandle(const ACommonDialog: TCommonDialog);
begin
  DestroyWindow(ACommonDialog.Handle);
end;

{ TWin32WSSelectDirectoryDialog }

{------------------------------------------------------------------------------
 Function: BrowseForFolderCallback
 Params: Window_hwnd - The window that receives a message for the window
         Msg         - The message received
         LParam      - Long-integer parameter
         lpData      - Data parameter, contains initial path.
  Returns: non-zero long-integer

  Handles the messages sent to the toolbar button by Windows
 ------------------------------------------------------------------------------}
function BrowseForFolderCallback(hwnd : Handle; uMsg : UINT;
  lParam, lpData : LPARAM) : Integer; stdcall;
begin
  case uMsg of
    BFFM_INITIALIZED:
        // Setting root dir
        {$ifdef WindowsUnicodeSupport}
        if UnicodeEnabledOS then
          SendMessageW(hwnd, BFFM_SETSELECTIONW, ULONG(True), lpData)
        else
        {$endif}
          SendMessage(hwnd, BFFM_SETSELECTION, ULONG(True), lpData);
    //BFFM_SELCHANGED
    //  : begin
    //    if Assigned(FOnSelectionChange) then .....
    //    end;
  end;
  Result := 0;
end;

class function TWin32WSSelectDirectoryDialog.CreateHandle(const ACommonDialog: TCommonDialog): THandle;
var
  Options : TOpenOptions;
  InitialDir : string;
  Buffer : PChar;
  bi : TBrowseInfo;
  iidl : PItemIDList;
  {$ifdef WindowsUnicodeSupport}
  biw : TBROWSEINFOW;
  Bufferw : PWideChar absolute Buffer;
  InitialDirW: widestring;
  Title: widestring;
  {$endif}
begin
  InitialDir := TSelectDirectoryDialog(ACommonDialog).FileName;

  Options := TSelectDirectoryDialog(ACommonDialog).Options;

  if length(InitialDir)=0 then
    InitialDir := TSelectDirectoryDialog(ACommonDialog).InitialDir;
  if length(InitialDir)>0 then begin
    // remove the \ at the end.                                                                      
    if Copy(InitialDir,length(InitialDir),1)=PathDelim then
      InitialDir := copy(InitialDir,1, length(InitialDir)-1);
    // if it is a rootdirectory, then the InitialDir must have a \ at the end.
    if Copy(InitialDir,length(InitialDir),1)=DriveDelim then
      InitialDir := InitialDir + PathDelim;
  end;
  {$ifdef WindowsUnicodeSupport}
  if UnicodeEnabledOS then
  begin
    Buffer := CoTaskMemAlloc(MAX_PATH*2);
    InitialDirW:=UTF8ToUTF16(InitialDir);
    with biw do
    begin
      hwndOwner := GetOwnerHandle(ACommonDialog);
      pidlRoot := nil;
      pszDisplayName := BufferW;
      Title :=  UTF8ToUTF16(ACommonDialog.Title);
      lpszTitle := PWideChar(Title);
      ulFlags := BIF_RETURNONLYFSDIRS;
      if not (ofOldStyleDialog in Options) then
         ulFlags := ulFlags + BIF_NEWDIALOGSTYLE;
      lpfn := @BrowseForFolderCallback;
      // this value will be passed to callback proc as lpData
      lParam := Windows.LParam(PWideChar(InitialDirW));
    end;

    iidl := SHBrowseForFolderW(@biw);

    if Assigned(iidl) then
    begin
      SHGetPathFromIDListW(iidl, BufferW);
      CoTaskMemFree(iidl);
      TSelectDirectoryDialog(ACommonDialog).FileName := UTF16ToUTF8(widestring(BufferW));
    end;
  end
  else begin
    Buffer := CoTaskMemAlloc(MAX_PATH);
    InitialDir := Utf8ToAnsi(InitialDir);
    with bi do
    begin
      hwndOwner := GetOwnerHandle(ACommonDialog);
      pidlRoot := nil;
      pszDisplayName := Buffer;
      lpszTitle := PChar(ACommonDialog.Title);
      ulFlags := BIF_RETURNONLYFSDIRS;
      if not (ofOldStyleDialog in Options) then
         ulFlags := ulFlags + BIF_NEWDIALOGSTYLE;
      lpfn := @BrowseForFolderCallback;
      // this value will be passed to callback proc as lpData
      lParam := Windows.LParam(PChar(InitialDir));
    end;

    iidl := SHBrowseForFolder(@bi);

    if Assigned(iidl) then
    begin
      SHGetPathFromIDList(iidl, Buffer);
      CoTaskMemFree(iidl);
      TSelectDirectoryDialog(ACommonDialog).FileName := AnsiToUtf8(Buffer);
    end;
  end;
  {$else}
  Buffer := CoTaskMemAlloc(MAX_PATH);
  with bi do
  begin
    hwndOwner := GetOwnerHandle(ACommonDialog);
    pidlRoot := nil;
    pszDisplayName := Buffer;
    lpszTitle := PChar(ACommonDialog.Title);
    ulFlags := BIF_RETURNONLYFSDIRS;
    if not (ofOldStyleDialog in Options) then
       ulFlags := ulFlags + BIF_NEWDIALOGSTYLE;
    lpfn := @BrowseForFolderCallback;
    // this value will be passed to callback proc as lpData
    lParam := LclType.LParam(PChar(InitialDir));
  end;

  iidl := SHBrowseForFolder(@bi);

  if Assigned(iidl) then
  begin
    SHGetPathFromIDList(iidl, Buffer);
    CoTaskMemFree(iidl);
    TSelectDirectoryDialog(ACommonDialog).FileName := Buffer;
  end;
  {$endif}
  
  SetDialogResult(ACommonDialog, assigned(iidl));

  CoTaskMemFree(Buffer);

  Result := 0;
end;

initialization
  if (Win32MajorVersion = 4) then
    OpenFileNameSize := SizeOf(OPENFILENAME_NT4)
  else
    OpenFileNameSize := SizeOf(OPENFILENAME);
end.
