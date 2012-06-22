{
 /***************************************************************************
                            dialogprocs.pas
                            ---------------

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
    Common IDE functions with MessageDlg(s) for errors.
}
unit DialogProcs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, Forms, Controls, Dialogs, FileProcs,
  FileUtil, LazFileUtils, Laz2_XMLCfg, lazutf8classes, CodeToolsConfig,
  CodeCache, CodeToolManager, AVL_Tree, LazIDEIntf, IDEProcs,
  LazarusIDEStrConsts, IDEDialogs;

type
  // load buffer flags
  TLoadBufferFlag = (
    lbfUpdateFromDisk,
    lbfRevert,
    lbfCheckIfText,
    lbfQuiet,
    lbfCreateClearOnError,
    lbfIgnoreMissing
    );
  TLoadBufferFlags = set of TLoadBufferFlag;
  
  TOnBackupFileInteractive =
                       function(const Filename: string): TModalResult of object;
                       
var
  OnBackupFileInteractive: TOnBackupFileInteractive = nil;

function BackupFileInteractive(const Filename: string): TModalResult;
function RenameFileWithErrorDialogs(const SrcFilename, DestFilename: string;
                                    ExtraButtons: TMsgDlgButtons): TModalResult;
function CopyFileWithErrorDialogs(const SrcFilename, DestFilename: string;
                                  ExtraButtons: TMsgDlgButtons): TModalResult;
function LoadCodeBuffer(out ACodeBuffer: TCodeBuffer; const AFilename: string;
                        Flags: TLoadBufferFlags; ShowAbort: boolean): TModalResult;
function SaveCodeBuffer(ACodeBuffer: TCodeBuffer): TModalResult;
function SaveCodeBufferToFile(ACodeBuffer: TCodeBuffer;
                         const Filename: string; Backup: boolean = false): TModalResult;
function LoadStringListFromFile(const Filename, ListTitle: string;
                                var sl: TStrings): TModalResult;
function SaveStringListToFile(const Filename, ListTitle: string;
                              var sl: TStrings): TModalResult;
function LoadXMLConfigFromCodeBuffer(const Filename: string; Config: TXMLConfig;
                        out ACodeBuffer: TCodeBuffer; Flags: TLoadBufferFlags;
                        ShowAbort: boolean
                        ): TModalResult;
function SaveXMLConfigToCodeBuffer(const Filename: string; Config: TXMLConfig;
                                   var ACodeBuffer: TCodeBuffer;
                                   KeepFileAttributes: boolean): TModalResult;
function CreateEmptyFile(const Filename: string;
                         ErrorButtons: TMsgDlgButtons): TModalResult;
function CheckCreatingFile(const AFilename: string;
                           CheckReadable: boolean;
                           WarnOverwrite: boolean = false;
                           CreateBackup: boolean = false
                           ): TModalResult;
function CheckFileIsWritable(const Filename: string;
                             ErrorButtons: TMsgDlgButtons): TModalResult;
function ChooseSymlink(var Filename: string): TModalResult;
function CreateSymlinkInteractive(const LinkFilename, TargetFilename: string;
                                  ErrorButtons: TMsgDlgButtons): TModalResult;
function ForceDirectoryInteractive(Directory: string;
                                   ErrorButtons: TMsgDlgButtons): TModalResult;
function CheckDirectoryIsWritable(const Filename: string;
                                  ErrorButtons: TMsgDlgButtons): TModalResult;
function DeleteFileInteractive(const Filename: string;
                               ErrorButtons: TMsgDlgButtons): TModalResult;
function SaveStringToFile(const Filename, Content: string;
                        ErrorButtons: TMsgDlgButtons; const Context: string = ''
                        ): TModalResult;
function ConvertLFMToLRSFileInteractive(const LFMFilename,
                         LRSFilename: string; ShowAbort: boolean): TModalResult;
function IfNotOkJumpToCodetoolErrorAndAskToAbort(Ok: boolean;
                            Ask: boolean; out NewResult: TModalResult): boolean;
function JumpToCodetoolErrorAndAskToAbort(Ask: boolean): TModalResult;
procedure NotImplementedDialog(const Feature: string);

implementation

{$IFDEF Unix}
uses
  baseunix;
{$ENDIF}

function BackupFileInteractive(const Filename: string): TModalResult;
begin
  if Assigned(OnBackupFileInteractive) then
    Result:=OnBackupFileInteractive(Filename)
  else
    Result:=mrOk;
end;

function RenameFileWithErrorDialogs(const SrcFilename, DestFilename: string;
  ExtraButtons: TMsgDlgButtons): TModalResult;
var
  DlgButtons: TMsgDlgButtons;
begin
  if SrcFilename=DestFilename then begin
    Result:=mrOk;
    exit;
  end;
  repeat
    if FileProcs.RenameFileUTF8(SrcFilename,DestFilename) then begin
      break;
    end else begin
      DlgButtons:=[mbCancel,mbRetry]+ExtraButtons;
      Result:=IDEMessageDialog(lisUnableToRenameFile,
        Format(lisUnableToRenameFileTo2, ['"', SrcFilename, '"', #13, '"',
          DestFilename, '"']),
        mtError,DlgButtons);
      if (Result<>mrRetry) then exit;
    end;
  until false;
  Result:=mrOk;
end;

function CopyFileWithErrorDialogs(const SrcFilename, DestFilename: string;
  ExtraButtons: TMsgDlgButtons): TModalResult;
var
  DlgButtons: TMsgDlgButtons;
begin
  if CompareFilenames(SrcFilename,DestFilename)=0 then begin
    Result:=mrAbort;
    IDEMessageDialog(lisUnableToCopyFile,
      Format(lisSourceAndDestinationAreTheSame, [#13, SrcFilename]), mtError, [
        mbAbort]);
    exit;
  end;
  repeat
    if CopyFile(SrcFilename,DestFilename) then begin
      break;
    end else begin
      DlgButtons:=[mbCancel,mbRetry]+ExtraButtons;
      Result:=IDEMessageDialog(lisUnableToCopyFile,
        Format(lisUnableToCopyFileTo2, ['"', SrcFilename, '"', #13, '"',
          DestFilename, '"']),
        mtError,DlgButtons);
      if (Result<>mrRetry) then exit;
    end;
  until false;
  Result:=mrOk;
end;

function LoadCodeBuffer(out ACodeBuffer: TCodeBuffer; const AFilename: string;
  Flags: TLoadBufferFlags; ShowAbort: boolean): TModalResult;
var
  ACaption, AText: string;
  FileReadable: boolean;
begin
  ACodeBuffer:=nil;
  if not FilenameIsAbsolute(AFilename) then
    Flags:=Flags-[lbfUpdateFromDisk,lbfRevert];
  if lbfCreateClearOnError in Flags then
    Exclude(Flags,lbfIgnoreMissing);
  if [lbfUpdateFromDisk,lbfRevert]*Flags=[] then begin
    // can use cache
    ACodeBuffer:=CodeToolBoss.LoadFile(AFilename,false,false);
    if ACodeBuffer<>nil then begin
      // file is in cache
      if (not (lbfCheckIfText in Flags)) or ACodeBuffer.SourceIsText then begin
        Result:=mrOk;
        exit;
      end;
    end;
  end;
  repeat
    FileReadable:=true;
    if (lbfCheckIfText in Flags)
    and (not FileIsText(AFilename,FileReadable)) and FileReadable
    then begin
      if lbfQuiet in Flags then begin
        Result:=mrCancel;
      end else begin
        ACaption:=lisFileNotText;
        AText:=Format(lisFileDoesNotLookLikeATextFileOpenItAnyway2, ['"',
          AFilename, '"', #13, #13]);
        Result:=IDEMessageDialogAb(ACaption, AText, mtConfirmation,
                           [mbOk, mbIgnore],ShowAbort);
      end;
      if Result<>mrOk then break;
    end;
    if FileReadable then
      ACodeBuffer:=CodeToolBoss.LoadFile(AFilename,lbfUpdateFromDisk in Flags,
                                         lbfRevert in Flags)
    else
      ACodeBuffer:=nil;

    if ACodeBuffer<>nil then begin
      Result:=mrOk;
    end else begin
      // read error
      if lbfIgnoreMissing in Flags then begin
        if (FilenameIsAbsolute(AFilename) and not FileExistsCached(AFilename))
        then
          exit(mrIgnore);
      end;
      if lbfQuiet in Flags then
        Result:=mrCancel
      else begin
        ACaption:=lisReadError;
        AText:=Format(lisUnableToReadFile2, ['"', AFilename, '"']);
        Result:=IDEMessageDialogAb(ACaption,AText,mtError,
                                   [mbRetry,mbIgnore],
                                   ShowAbort);
        if Result=mrAbort then exit;
      end;
    end;
  until Result<>mrRetry;
  if (ACodeBuffer=nil) and (lbfCreateClearOnError in Flags) then begin
    ACodeBuffer:=CodeToolBoss.CreateFile(AFilename);
    if ACodeBuffer<>nil then
      Result:=mrOk;
  end;
end;

function SaveCodeBuffer(ACodeBuffer: TCodeBuffer): TModalResult;
begin
  repeat
    if ACodeBuffer.Save then begin
      Result:=mrOk;
    end else begin
      Result:=IDEMessageDialog(lisCodeToolsDefsWriteError,
        Format(lisUnableToWrite2, ['"', ACodeBuffer.Filename, '"']),
        mtError,[mbAbort,mbRetry,mbIgnore]);
    end;
  until Result<>mrRetry;
end;

function SaveCodeBufferToFile(ACodeBuffer: TCodeBuffer; const Filename: string;
  Backup: boolean): TModalResult;
var
  ACaption,AText:string;
begin
  if Backup then begin
    Result:=BackupFileInteractive(Filename);
    if Result<>mrOk then begin
      debugln(['SaveCodeBufferToFile backup failed: "',Filename,'"']);
      exit;
    end;
  end else
    Result:=mrOk;
  repeat
    if ACodeBuffer.SaveToFile(Filename) then begin
      Result:=mrOk;
    end else begin
      ACaption:=lisWriteError;
      AText:=Format(lisUnableToWriteToFile, ['"', Filename, '"']);
      Result:=IDEMessageDialog(ACaption,AText,mtError,
                               [mbAbort, mbRetry, mbIgnore]);
      if Result=mrAbort then exit;
      if Result=mrIgnore then Result:=mrOk;
    end;
  until Result<>mrRetry;
end;

function LoadStringListFromFile(const Filename, ListTitle: string;
  var sl: TStrings): TModalResult;
begin
  Result:=mrCancel;
  if sl=nil then
    sl:=TStringListUTF8.Create;
  try
    LoadStringsFromFileUTF8(sl,Filename);
    Result:=mrOk;
  except
    on E: Exception do begin
      IDEMessageDialog(lisCCOErrorCaption, Format(lisErrorLoadingFrom, [
        ListTitle, #13, Filename, #13#13, E.Message]), mtError, [mbOk]);
    end;
  end;
end;

function SaveStringListToFile(const Filename, ListTitle: string;
  var sl: TStrings): TModalResult;
begin
  Result:=mrCancel;
  if sl=nil then
    sl:=TStringListUTF8.Create;
  try
    sl.SaveToFile(Filename);
    Result:=mrOk;
  except
    on E: Exception do begin
      IDEMessageDialog(lisCCOErrorCaption, Format(lisErrorSavingTo, [ListTitle,
        #13, Filename, #13#13, E.Message]), mtError, [mbOk]);
    end;
  end;
end;

function LoadXMLConfigFromCodeBuffer(const Filename: string;
  Config: TXMLConfig; out ACodeBuffer: TCodeBuffer; Flags: TLoadBufferFlags;
  ShowAbort: boolean): TModalResult;
var
  ms: TMemoryStream;
begin
  Result:=LoadCodeBuffer(ACodeBuffer,Filename,Flags,ShowAbort);
  if Result<>mrOk then begin
    Config.Clear;
    exit;
  end;
  ms:=TMemoryStream.Create;
  try
    ACodeBuffer.SaveToStream(ms);
    ms.Position:=0;
    try
      if Config is TCodeBufXMLConfig then
        TCodeBufXMLConfig(Config).KeepFileAttributes:=true;
      Config.ReadFromStream(ms);
    except
      on E: Exception do begin
        if (lbfQuiet in Flags) then begin
          Result:=mrCancel;
        end else begin
          Result:=MessageDlg(lisXMLError,
            Format(lisXMLParserErrorInFileError, [Filename, #13, E.Message]),
              mtError, [mbCancel], 0);
        end;
      end;
    end;
  finally
    ms.Free;
  end;
end;

function SaveXMLConfigToCodeBuffer(const Filename: string;
  Config: TXMLConfig; var ACodeBuffer: TCodeBuffer; KeepFileAttributes: boolean
  ): TModalResult;
var
  ms: TMemoryStream;
begin
  if ACodeBuffer=nil then begin
    if KeepFileAttributes and FileExistsCached(Filename) then
      ACodeBuffer:=CodeToolBoss.LoadFile(Filename,true,false)
    else
      ACodeBuffer:=CodeToolBoss.CreateFile(Filename);
    if ACodeBuffer=nil then
      exit(mrCancel);
  end;
  ms:=TMemoryStream.Create;
  try
    try
      Config.WriteToStream(ms);
    except
      on E: Exception do begin
        Result:=MessageDlg(lisXMLError,
          Format(lisUnableToWriteXmlStreamToError, [Filename, #13, E.Message]),
            mtError, [mbCancel], 0);
      end;
    end;
    ms.Position:=0;
    ACodeBuffer.LoadFromStream(ms);
    Result:=SaveCodeBuffer(ACodeBuffer);
  finally
    ms.Free;
  end;
end;

function CreateEmptyFile(const Filename: string; ErrorButtons: TMsgDlgButtons
  ): TModalResult;
var
  Buffer: TCodeBuffer;
begin
  repeat
    Buffer:=CodeToolBoss.CreateFile(Filename);
    if Buffer<>nil then begin
      break;
    end else begin
      Result:=IDEMessageDialog(lisUnableToCreateFile,
        Format(lisUnableToCreateFilename, ['"', Filename, '"']),
        mtError,ErrorButtons+[mbCancel]);
      if Result<>mrRetry then exit;
    end;
  until false;
  repeat
    if Buffer.Save then begin
      break;
    end else begin
      Result:=IDEMessageDialog(lisUnableToWriteFile,
        Format(lisUnableToWriteToFile, ['"', Buffer.Filename, '"']),
        mtError,ErrorButtons+[mbCancel]);
      if Result<>mrRetry then exit;
    end;
  until false;
  Result:=mrOk;
end;

function CheckCreatingFile(const AFilename: string;
  CheckReadable: boolean; WarnOverwrite: boolean; CreateBackup: boolean
  ): TModalResult;
var
  fs: TFileStreamUTF8;
  c: char;
begin
  // create if not yet done
  if not FileExistsCached(AFilename) then begin
    try
      InvalidateFileStateCache;
      fs:=TFileStreamUTF8.Create(AFilename,fmCreate);
      fs.Free;
    except
      Result:=IDEMessageDialog(lisUnableToCreateFile,
        Format(lisUnableToCreateFilename, ['"', AFilename, '"']), mtError, [
          mbCancel, mbAbort]);
      exit;
    end;
  end else begin
    // file already exists
    if WarnOverwrite then begin
      Result:=IDEQuestionDialog(lisOverwriteFile,
        Format(lisAFileAlreadyExistsReplaceIt, ['"', AFilename, '"', #13]),
        mtConfirmation,
        [mrYes, lisOverwriteFileOnDisk, mbCancel]);
      if Result=mrCancel then exit;
    end;
    if CreateBackup then begin
      Result:=BackupFileInteractive(AFilename);
      if Result in [mrCancel,mrAbort] then exit;
      Result:=CheckCreatingFile(AFilename,CheckReadable,false,false);
      exit;
    end;
  end;
  // check writable
  try
    if CheckReadable then begin
      InvalidateFileStateCache;
      fs:=TFileStreamUTF8.Create(AFilename,fmOpenWrite)
    end else
      fs:=TFileStreamUTF8.Create(AFilename,fmOpenReadWrite);
    try
      fs.Position:=fs.Size;
      c := ' ';
      fs.Write(c,1);
    finally
      fs.Free;
    end;
  except
    Result:=IDEMessageDialog(lisUnableToWriteFile,
      Format(lisUnableToWriteToFile, ['"', AFilename, '"']), mtError, [
        mbCancel, mbAbort]);
    exit;
  end;
  // check readable
  try
    InvalidateFileStateCache;
    fs:=TFileStreamUTF8.Create(AFilename,fmOpenReadWrite);
    try
      fs.Position:=fs.Size-1;
      fs.Read(c,1);
    finally
      fs.Free;
    end;
  except
    Result:=IDEMessageDialog(lisUnableToReadFile,
      Format(lisUnableToReadFilename, ['"', AFilename, '"']), mtError, [
        mbCancel, mbAbort]);
    exit;
  end;
  Result:=mrOk;
end;

function CheckFileIsWritable(const Filename: string;
  ErrorButtons: TMsgDlgButtons): TModalResult;
begin
  Result:=mrOk;
  while not FileIsWritable(Filename) do begin
    Result:=IDEMessageDialog(lisFileIsNotWritable,
      Format(lisUnableToWriteToFile, ['"', Filename, '"']),
      mtError,ErrorButtons+[mbCancel]);
    if Result<>mrRetry then exit;
  end;
end;

function ChooseSymlink(var Filename: string): TModalResult;
var
  TargetFilename: String;
begin
  if not FileExistsUTF8(Filename) then exit(mrOk);
  Result:=mrCancel;
  try
    TargetFilename:=ReadAllLinks(Filename,true);
    if TargetFilename<>Filename then begin
      case IDEQuestionDialog(lisFileIsSymlink,
        Format(lisTheFileIsASymlinkOpenInstead, ['"', Filename, '"', #13, #13,
          '"', TargetFilename, '"']),
        mtConfirmation, [mbYes, lisOpenTarget, mbNo, lisOpenSymlink, mbCancel])
      of
      mrYes: Filename:=TargetFilename;
      mrNo:  ;
      else   exit;
      end;
    end;
    Result:=mrOk;
  except
    on E: Exception do begin
      IDEMessageDialog(lisFileLinkError,
        E.Message,mtError,[mbCancel]);
    end;
  end;
end;

function CreateSymlinkInteractive(const LinkFilename, TargetFilename: string;
  ErrorButtons: TMsgDlgButtons): TModalResult;
begin
  {$IFDEF Unix}
  if FpReadLink(LinkFilename)=TargetFilename then exit(mrOk);
  while FPSymLink(PChar(TargetFilename),PChar(LinkFilename)) <> 0 do begin
    Result:=IDEMessageDialog(lisCodeToolsDefsWriteError, Format(
      lisUnableToCreateLinkWithTarget, ['"',
      LinkFilename, '"', '"', TargetFilename, '"']),
      mtError,ErrorButtons+[mbCancel],'');
    if Result<>mrRetry then exit;
  end;
  InvalidateFileStateCache;
  Result:=mrOk;
  {$ELSE}
  Result:=mrIgnore;
  {$ENDIF}
end;

function ForceDirectoryInteractive(Directory: string;
  ErrorButtons: TMsgDlgButtons): TModalResult;
var
  i: integer;
  Dir: string;
begin
  DoDirSeparators(Directory);
  Directory:=AppendPathDelim(Directory);
  if DirPathExists(Directory) then exit(mrOk);
  // skip UNC path
  i := Length(ExtractUNCVolume(Directory)) + 1;
  while i <= Length(Directory) do begin
    if Directory[i]=PathDelim then begin
      Dir:=copy(Directory,1,i-1);
      if not DirPathExists(Dir) then begin
        while not CreateDirUTF8(Dir) do begin
          Result:=IDEMessageDialog(lisPkgMangUnableToCreateDirectory,
            Format(lisUnableToCreateDirectory2, ['"', Dir, '"']),
            mtError,ErrorButtons+[mbCancel]);
          if Result<>mrRetry then exit;
        end;
        InvalidateFileStateCache;
      end;
    end;
    inc(i);
  end;
  Result:=mrOk;
end;

function CheckDirectoryIsWritable(const Filename: string;
  ErrorButtons: TMsgDlgButtons): TModalResult;
begin
  Result:=mrOk;
  while not DirectoryIsWritable(Filename) do begin
    Result:=IDEMessageDialog(lisDirectoryNotWritable,
      Format(lisTheDirectoryIsNotWritable, ['"', Filename, '"']),
      mtError,ErrorButtons+[mbCancel]);
    if Result<>mrRetry then exit;
  end;
end;

function DeleteFileInteractive(const Filename: string;
  ErrorButtons: TMsgDlgButtons): TModalResult;
begin
  repeat
    Result:=mrOk;
    if not FileExistsUTF8(Filename) then exit;
    if not DeleteFileUTF8(Filename) then begin
      Result:=IDEMessageDialogAb(lisDeleteFileFailed,
        Format(lisPkgMangUnableToDeleteFile, ['"', Filename, '"']),
        mtError,[mbCancel,mbRetry]+ErrorButtons-[mbAbort],mbAbort in ErrorButtons);
      if Result<>mrRetry then exit;
    end;
  until false;
end;

function SaveStringToFile(const Filename, Content: string;
  ErrorButtons: TMsgDlgButtons; const Context: string): TModalResult;
var
  fs: TFileStreamUTF8;
begin
  try
    InvalidateFileStateCache;
    fs:=TFileStreamUTF8.Create(Filename,fmCreate);
    try
      if Content<>'' then
        fs.Write(Content[1],length(Content));
    finally
      fs.Free;
    end;
    Result:=mrOk;
  except
    on E: Exception do begin
      Result:=IDEMessageDialog(lisCodeToolsDefsWriteError,
         Format(lisWriteErrorFile, [E.Message, #13, Filename, #13, Context]),
         mtError,[mbAbort]+ErrorButtons);
    end;
  end;
end;

function ConvertLFMToLRSFileInteractive(const LFMFilename,
  LRSFilename: string; ShowAbort: boolean): TModalResult;
var
  LFMMemStream, LRSMemStream: TMemoryStream;
  LFMBuffer: TCodeBuffer;
  LRSBuffer: TCodeBuffer;
  FormClassName: String;
  BinStream: TMemoryStream;
begin
  // read lfm file
  Result:=LoadCodeBuffer(LFMBuffer,LFMFilename,[lbfUpdateFromDisk],ShowAbort);
  if Result<>mrOk then exit;
  //debugln(['ConvertLFMToLRSFileInteractive ',LFMBuffer.Filename,' DiskEncoding=',LFMBuffer.DiskEncoding,' MemEncoding=',LFMBuffer.MemEncoding]);
  LFMMemStream:=nil;
  LRSMemStream:=nil;
  try
    LFMMemStream:=TMemoryStream.Create;
    LFMBuffer.SaveToStream(LFMMemStream);
    LFMMemStream.Position:=0;
    LRSMemStream:=TMemoryStream.Create;
    try
      FormClassName:=FindLFMClassName(LFMMemStream);
      //debugln(['ConvertLFMToLRSFileInteractive FormClassName="',FormClassName,'"']);
      BinStream:=TMemoryStream.Create;
      try
        LRSObjectTextToBinary(LFMMemStream,BinStream);
        BinStream.Position:=0;
        BinaryToLazarusResourceCode(BinStream,LRSMemStream,FormClassName,'FORMDATA');
      finally
        BinStream.Free;
      end;
    except
      on E: Exception do begin
        {$IFNDEF DisableChecks}
        DebugLn('LFMtoLRSstream ',E.Message);
        {$ENDIF}
        Result:=IDEMessageDialogAb('Error',
          'Error while converting '+LFMFilename+' to '+LRSFilename+':'#13
          +E.Message,mtError,[mbCancel,mbIgnore],ShowAbort);
        exit;
      end;
    end;
    LRSMemStream.Position:=0;
    // save lrs file
    LRSBuffer:=CodeToolBoss.CreateFile(LRSFilename);
    if (LRSBuffer<>nil) then begin
      LRSBuffer.LoadFromStream(LRSMemStream);
      Result:=SaveCodeBuffer(LRSBuffer);
    end else begin
      Result:=mrCancel;
      debugln('ConvertLFMToLRSFileInteractive unable to create codebuffer ',LRSFilename);
    end;
  finally
    LFMMemStream.Free;
    LRSMemStream.Free;
  end;
end;

function IfNotOkJumpToCodetoolErrorAndAskToAbort(Ok: boolean;
  Ask: boolean; out NewResult: TModalResult): boolean;
begin
  if Ok then begin
    NewResult:=mrOk;
    Result:=true;
  end else begin
    NewResult:=JumpToCodetoolErrorAndAskToAbort(Ask);
    Result:=NewResult<>mrAbort;
  end;
end;

function JumpToCodetoolErrorAndAskToAbort(Ask: boolean): TModalResult;
// returns mrCancel or mrAbort
var
  ErrMsg: String;
begin
  ErrMsg:=CodeToolBoss.ErrorMessage;
  LazarusIDE.DoJumpToCodeToolBossError;
  if Ask then begin
    Result:=IDEQuestionDialog(lisCCOErrorCaption,
      Format(lisTheCodetoolsFoundAnError, [#13, ErrMsg, #13]),
      mtWarning, [mrIgnore, lisIgnoreAndContinue, mrAbort]);
    if Result=mrIgnore then Result:=mrCancel;
  end else begin
    Result:=mrCancel;
  end;
end;

procedure NotImplementedDialog(const Feature: string);
begin
  IDEMessageDialog(lisNotImplemented, Format(lisNotImplementedYet, [#13, Feature]),
                   mtError, [mbCancel]);
end;

end.

