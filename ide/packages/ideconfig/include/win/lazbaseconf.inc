{%MainUnit ../win32/lazconf.inc}
// included by win32/lazconf.inc, win64/lazconf.inc
// todo: use $target here ?

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
 *   Inc., 51 Franklin Street - Fifth Floor, Boston, MA 02110-1335, USA.   *
 *                                                                         *
 ***************************************************************************
}

const
  DefaultFPCSrcDirs: array[1..2] of string = (
    '$(LazarusDir)\fpcsrc',  // this value is set in internalinit
    'c:\pp\source'
    );

  DefaultLazarusSrcDirs: array[1..1] of string = (
    'c:\lazarus'
    );

var
  DefaultDrive: String;
  PrimaryConfigPath,
  SecondaryConfigPath: string;
  DefaultFPCTarget,
  DefaultFPCVersion : string;

type
  TGetFileListProc = procedure (List: TStrings);

function FindExecutableInList(GetFileList: TGetFileListProc): string;
var
  FileNames: TStrings;
  i : integer;
begin
  FileNames := TStringList.Create;
  GetFileList(FileNames);
  try
    for i := 0 to FileNames.Count -1 do begin
      Result := FileNames[i];
      if FileExistsUTF8(Result) then exit;
    end;
    Result := '';
  finally
    FileNames.Free;
  end;
end;

function FindDefaultMakePath: string;
begin
  Result := SearchFileInPath('make.exe',
             format('%sfpc\%s\bin\%s',
               [AppendPathDelim(ProgramDirectory), DefaultFPCVersion, DefaultFPCTarget]),
             GetEnvironmentVariableUTF8('PATH'),';',
                            []);
  if Result <> '' then exit;
  Result := FindExecutableInList(@GetDefaultMakeFilenames)
end;

function GetDefaultCompiledUnitExt(FPCVersion, FPCRelease: integer): string;
begin
  Result:='.ppu';
end;

function OSLocksExecutables: boolean;
begin
  Result:=true;
end;

function GetDefaultTestBuildDirectory: string;
begin
  Result := SysUtils.GetTempDir;
  if Result <> '' then exit;
  Result := DefaultDrive + '\temp\';
  if DirPathExists(Result) then exit;
  Result := DefaultDrive + '\windows\temp\';
end;

procedure GetDefaultMakeFilenames(List: TStrings);
begin
  List.Add(DefaultDrive + format('\fpc\%s\bin\%s\make.exe',
    [DefaultFPCVersion, DefaultFPCTarget]));
  List.Add(AppendPathDelim(ProgramDirectory) +
    format('fpc\%s\bin\%s\make.exe',[DefaultFPCVersion, DefaultFPCTarget]));
end;

procedure GetDefaultTestBuildDirs(List: TStrings);
begin
  List.Add(SysUtils.GetTempDir);
  List.Add(DefaultDrive + '\temp\');
  List.Add(DefaultDrive + '\windows\temp\');
end;

procedure GetDefaultBrowser(var Browser, Params: string);
begin
  Browser:= SearchFileInPath('rundll32.exe','',
                           GetEnvironmentVariableUTF8('PATH'),';',
                           [sffDontSearchInBasePath]);
  Params:='url.dll,FileProtocolHandler %s';
end;

{---------------------------------------------------------------------------
  procedure InternalInit;
 ---------------------------------------------------------------------------}
procedure InternalInit;
begin
  DefaultDrive := ExtractFileDrive(ProgramDirectory);
  DefaultFPCTarget:= GetCompiledTargetCPU + '-' + GetCompiledTargetOS;
  DefaultFPCVersion:= {$I %FPCVERSION%};
  // the last part of the path returned by GetAppConfigDir is the application
  // name. Replace that by 'lazarus', to make sure that lazbuild uses
  // the same primary config path
  PrimaryConfigPath:= ExtractFilePath(ChompPathDelim(GetAppConfigDirUTF8(False))) + 'lazarus';
  SecondaryConfigPath:=ChompPathDelim(ProgramDirectory);
  DefaultFPCSrcDirs[1] := AppendPathDelim(ProgramDirectory) + 'fpcsrc';
  DefaultLazarusSrcDirs[1] := DefaultDrive + '\lazarus';
end;

