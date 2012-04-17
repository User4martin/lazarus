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
  Converted to lfm by: Matthijs Willemstein
  Quickoptions added by: Giuliano Colla
  Then extensively modified by: Juha Manninen
   - added support for Build Profiles which extend the idea of Quick Options.
   - changed UI to be less weird and comply better with UI design norms.
   - changed object structure to keep it logical and to avoid duplicate data.

  Abstract:
    Defines settings for the "Build Lazarus" function of the IDE.
    TConfigureBuildLazarusDlg is used to edit the build options.

    The BuildLazarus function will build the lazarus parts.

    Building occurs only with options defined in the Detail Page.
    Profiles are just used to set options there. Therefore beginners can
    use default profiles and don't need to touch the Detail Page.
    Advanced users can define their own profiles for example for cross compiling.
}
unit BuildLazDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LConvEncoding, Forms, Controls, LCLType, LCLIntf,
  Graphics, GraphType, StdCtrls, ExtCtrls, Buttons, FileUtil, LazUTF8, Dialogs,
  InterfaceBase, Themes, CheckLst, Menus, ComCtrls, DividerBevel,
  DefineTemplates,
  // IDEIntf
  LazIDEIntf, IDEMsgIntf, IDEHelpIntf, IDEImagesIntf, IDEWindowIntf, IDEDialogs,
  // IDE
  LazarusIDEStrConsts, TransferMacros, LazConf, IDEProcs, DialogProcs, MainBar,
  InputHistory, ExtToolDialog, ExtToolEditDlg, EnvironmentOpts,
  {$IFDEF win32}
  CodeToolManager, // added for windres workaround
  {$ENDIF}
  ApplicationBundle, CompilerOptions, BuildProfileManager,
  GenericListEditor, GenericCheckList, PackageSystem, PackageDefs;

type

  TBuildLazarusFlag = (
    blfDontBuild,           // skip all building, only cleaning
    blfOnlyIDE,             // skip all but IDE (for example build IDE, but not packages, not lazbuild, ...)
    blfDontClean,           // ignore clean up option in profile
    blfUseMakeIDECfg,       // append @idemake.cfg
    blfReplaceExe           // ignore OSLocksExecutables and do not create lazarus.new.exe
    );
  TBuildLazarusFlags = set of TBuildLazarusFlag;

  { TConfigureBuildLazarusDlg }

  TConfigureBuildLazarusDlg = class(TForm)
    CleanAllRadioButton: TRadioButton;
    CleanAutoRadioButton: TRadioButton;
    CleanCommonRadioButton: TRadioButton;
    CleanOnceCheckBox: TCheckBox;
    CommonsDividerBevel: TDividerBevel;
    ConfirmBuildCheckBox: TCheckBox;
    DefinesButton: TButton;
    DefinesLabel: TLabel;
    DefinesListBox: TCheckListBox;
    CancelButton: TBitBtn;
    CBLDBtnPanel: TPanel;
    BuildProfileComboBox: TComboBox;
    CompileButton: TBitBtn;
    CompileAdvancedButton: TBitBtn;
    InhTreeView: TTreeView;
    InhNoteLabel: TLabel;
    LCLWidgetTypeLabel: TLabel;
    LCLWidgetTypeComboBox: TComboBox;
    OptionsLabel: TLabel;
    OptionsMemo: TMemo;
    CleanUpGroupBox: TGroupBox;
    PageControl1: TPageControl;
    RestartAfterBuildCheckBox: TCheckBox;
    ShowOptsMenuItem: TMenuItem;
    DetailsPanel: TPanel;
    HelpButton: TBitBtn;
    BuildProfileLabel: TLabel;
    OptionsPopupMenu: TPopupMenu;
    Panel2: TPanel;
    SaveSettingsButton: TBitBtn;
    BuildProfileButton: TButton;
    BuildTabSheet: TTabSheet;
    InfoTabSheet: TTabSheet;
    TargetCPUComboBox: TComboBox;
    TargetCPULabel: TLabel;
    TargetDirectoryButton: TButton;
    TargetDirectoryComboBox: TComboBox;
    TargetDirectoryLabel: TLabel;
    TargetOSComboBox: TComboBox;
    TargetOSLabel: TLabel;
    UpdateRevisionIncCheckBox: TCheckBox;
    procedure BuildProfileButtonClick(Sender: TObject);
    procedure BuildProfileComboBoxSelect(Sender: TObject);
    procedure CompileAdvancedButtonClick(Sender: TObject);
    procedure CompileButtonClick(Sender: TObject);
    procedure DefinesButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var {%H-}CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);
    procedure ShowOptsMenuItemClick(Sender: TObject);
    procedure SaveSettingsButtonClick(Sender: TObject);
    procedure TargetDirectoryButtonClick(Sender: TObject);
  private
    // Data is copied by caller before and after opening this dialog.
    fProfiles: TBuildLazarusProfiles;
    fUpdatingProfileCombo: Boolean;
    fImageIndexPackage: Integer;
    fImageIndexRequired: Integer;
    fImageIndexInherited: Integer;
    procedure PrepareClose;
    procedure SetupInfoPage;
    procedure UpdateInheritedTree;
  public
    constructor Create(TheOwner: TComponent); overload; reintroduce;
    destructor Destroy; override;
    procedure CopyProfileToUI(AProfile: TBuildLazarusProfile);
    procedure CopyUIToProfile(AProfile: TBuildLazarusProfile);
    procedure UpdateProfileNamesUI;
  public
    property  Profiles: TBuildLazarusProfiles read fProfiles;
  end;

function ShowConfigureBuildLazarusDlg(AProfiles: TBuildLazarusProfiles): TModalResult;

{ Clean all
  clean ide
  ide
  clean ide + ide
}
function MakeLazarus(Profile: TBuildLazarusProfile;
  ExternalTools: TBaseExternalToolList; Macros: TTransferMacroList;
  const PackageOptions, CompilerPath, MakePath: string;
  Flags: TBuildLazarusFlags; var ProfileChanged: boolean): TModalResult;

function CreateIDEMakeOptions(Profile: TBuildLazarusProfile;
  Macros: TTransferMacroList; const PackageOptions: string;
  Flags: TBuildLazarusFlags; var AExOptions: string;
  out UpdateRevisionInc: boolean; out OutputDirRedirected: boolean): TModalResult;

function SaveIDEMakeOptions(Profile: TBuildLazarusProfile;
  Macros: TTransferMacroList;
  const PackageOptions: string; Flags: TBuildLazarusFlags): TModalResult;

function GetMakeIDEConfigFilename: string;


implementation

{$R *.lfm}

const
  DefaultIDEMakeOptionFilename = 'idemake.cfg';

function ShowConfigureBuildLazarusDlg(AProfiles: TBuildLazarusProfiles): TModalResult;
// mrOk=save
// mrYes=save and compile
// mrAll=save and compile all selected profiles
var
  ConfigBuildLazDlg: TConfigureBuildLazarusDlg;
begin
  Result := mrCancel;
  ConfigBuildLazDlg := TConfigureBuildLazarusDlg.Create(nil);
  try
    ConfigBuildLazDlg.Profiles.Assign(AProfiles); // Copy profiles to dialog.
    Result := ConfigBuildLazDlg.ShowModal;
    if Result in [mrOk,mrYes,mrAll] then
      AProfiles.Assign(ConfigBuildLazDlg.Profiles); // Copy profiles back from dialog.
  finally
    ConfigBuildLazDlg.Free;
  end;
end;

function MakeLazarus(Profile: TBuildLazarusProfile;
  ExternalTools: TBaseExternalToolList; Macros: TTransferMacroList;
  const PackageOptions, CompilerPath, MakePath: string;
  Flags: TBuildLazarusFlags; var ProfileChanged: boolean): TModalResult;

  procedure ApplyCleanOnce;
  begin
    if not Profile.CleanOnce then exit;
    if Profile.IdeBuildMode=bmBuild then exit;
    Profile.IdeBuildMode:=bmBuild;
    ProfileChanged:=true;
  end;

  function CheckDirectoryWritable(Dir: string): boolean;
  begin
    if DirectoryIsWritableCached(Dir) then exit(true);
    Result:=false;
    IDEMessageDialog(lisBuildingLazarusFailed,
               Format(lisThisSetOfOptionsToBuildLazarusIsNotSupportedByThis,
                      [#13, '"', Dir, '"', #13]),
               mtError,[mbCancel]);
  end;

  procedure CleanLazarusSrcDir(Dir: string; Recursive: boolean = true);
  var
    FileInfo: TSearchRec;
    Ext: String;
    Filename: TFilename;
  begin
    Dir:=AppendPathDelim(TrimFilename(Dir));
    if FindFirstUTF8(Dir+AllFilesMask,faAnyFile,FileInfo)=0 then begin
      repeat
        if (FileInfo.Name='') or (FileInfo.Name='.') or (FileInfo.Name='..')
        or (FileInfo.Name='.svn') or (FileInfo.Name='.git')
        then
          continue;
        Filename:=Dir+FileInfo.Name;
        if faDirectory and FileInfo.Attr>0 then
        begin
          if Recursive then
            CleanLazarusSrcDir(Filename)
        end
        else begin
          Ext:=LowerCase(ExtractFileExt(FileInfo.Name));
          if (Ext='.ppu') or (Ext='.o') or (Ext='.rst') then begin
            if not DeleteFileUTF8(Filename) then
              debugln(['CleanLazarusSrcDir failed to delete file "',Filename,'"']);
          end;
        end;
      until FindNextUTF8(FileInfo)<>0;
    end;
    FindCloseUTF8(FileInfo);
  end;

var
  Tool: TExternalToolOptions;
  ExOptions: String;
  WorkingDirectory: String;
  OutputDirRedirected, UpdateRevisionInc: boolean;
  IdeBuildMode: TIdeBuildMode;
  CmdLineParams: String;
  Dir: String;
begin
  Result:=mrCancel;

  if LazarusIDE<>nil then
    LazarusIDE.MainBarSubTitle:=Profile.Name;
  IdeBuildMode:=Profile.IdeBuildMode;

  Tool:=TExternalToolOptions.Create;
  try
    // setup external tool
    Tool.Filename:=MakePath;
    Tool.EnvironmentOverrides.Values['LCL_PLATFORM']:=
      LCLPlatformDirNames[Profile.TargetPlatform];
    Tool.EnvironmentOverrides.Values['LANG']:= 'en_US';
    if CompilerPath<>'' then
      Tool.EnvironmentOverrides.Values['PP']:=CompilerPath;
    if (Tool.Filename<>'') and (not FileExistsUTF8(Tool.Filename)) then
      Tool.Filename:=FindDefaultExecutablePath(Tool.Filename);
    if (Tool.Filename='') or (not FileExistsUTF8(Tool.Filename)) then begin
      Tool.Filename:=FindDefaultMakePath;
      if (Tool.Filename='') or (not FileExistsUTF8(Tool.Filename)) then begin
        IDEMessageDialog(lisMakeNotFound,
                   Format(lisTheProgramMakeWasNotFoundThisToolIsNeededToBuildLa,
                          ['"', '"', #13, #13]),
                   mtError,[mbCancel]);
        exit;
      end;
    end;
    // add -w option to print leaving/entering messages
    CmdLineParams:=' -w';
    // append target OS
    if Profile.TargetOS<>'' then
      CmdLineParams+=' OS_TARGET='+Profile.FPCTargetOS;
    // append target CPU
    if Profile.TargetCPU<>'' then
      CmdLineParams+=' CPU_TARGET='+Profile.FPCTargetCPU;

    Tool.ScanOutputForFPCMessages:=true;
    Tool.ScanOutputForMakeMessages:=true;

    // clean up
    if (IdeBuildMode<>bmBuild) and (not (blfDontClean in Flags)) then begin
      WorkingDirectory:=EnvironmentOptions.GetParsedLazarusDirectory;
      if not CheckDirectoryWritable(WorkingDirectory) then exit(mrCancel);

      if (IdeBuildMode=bmCleanAllBuild) and (not (blfOnlyIDE in Flags)) then begin
        // clean all lazarus source directories
        // Note: Some installations put the fpc units into the lazarus directory
        //       => clean only the known directories
        CleanLazarusSrcDir(WorkingDirectory,false);
        CleanLazarusSrcDir(WorkingDirectory+PathDelim+'examples');
        CleanLazarusSrcDir(WorkingDirectory+PathDelim+'components');
        CleanLazarusSrcDir(WorkingDirectory+PathDelim+'units');
        CleanLazarusSrcDir(WorkingDirectory+PathDelim+'ide');
        CleanLazarusSrcDir(WorkingDirectory+PathDelim+'packager');
        CleanLazarusSrcDir(WorkingDirectory+PathDelim+'lcl');
        CleanLazarusSrcDir(WorkingDirectory+PathDelim+'ideintf');
        CleanLazarusSrcDir(WorkingDirectory+PathDelim+'tools');
        CleanLazarusSrcDir(WorkingDirectory+PathDelim+'test');

        // clean config directory
        CleanLazarusSrcDir(GetPrimaryConfigPath+PathDelim+'units');

        // clean custom target directory
        if Profile.TargetDirectory<>'' then begin
          Dir:=Profile.GetParsedTargetDirectory(Macros);
          if (Dir<>'') and DirPathExists(Dir) then
            CleanLazarusSrcDir(Dir);
        end;
      end;

      // call make to clean up
      Tool.Title:=lisCleanLazarusSource;
      Tool.WorkingDirectory:=WorkingDirectory;
      if (IdeBuildMode=bmCleanBuild) or (blfOnlyIDE in Flags) then
        Tool.CmdLineParams:='cleanide'
      else
        Tool.CmdLineParams:='cleanlaz';
      Tool.CmdLineParams:=Tool.CmdLineParams+CmdLineParams;
      Result:=ExternalTools.Run(Tool,Macros,false);
      if Result<>mrOk then exit;

      ApplyCleanOnce;
    end;

    // build IDE
    if not (blfDontBuild in Flags) then begin
      WorkingDirectory:=EnvironmentOptions.GetParsedLazarusDirectory;
      if blfDontClean in Flags then
        IdeBuildMode:=bmBuild;
      Tool.Title:=lisIDE;
      Tool.WorkingDirectory:=WorkingDirectory;
      if IdeBuildMode=bmBuild then
        Tool.CmdLineParams:='ide'
      else
        Tool.CmdLineParams:='cleanide ide';
      // append extra Profile
      ExOptions:='';
      Result:=CreateIDEMakeOptions(Profile,Macros,PackageOptions,Flags,
                               ExOptions,UpdateRevisionInc,OutputDirRedirected);
      if Result<>mrOk then exit;

      if (not OutputDirRedirected)
      and (not CheckDirectoryWritable(WorkingDirectory)) then
        exit(mrCancel);

      if ExOptions<>'' then
        Tool.EnvironmentOverrides.Values['OPT'] := ExOptions;
      if not UpdateRevisionInc then
        Tool.EnvironmentOverrides.Values['USESVN2REVISIONINC'] := '0';
      Tool.CmdLineParams:=Tool.CmdLineParams+CmdLineParams;
      // run
      Result:=ExternalTools.Run(Tool,Macros,false);
      if Result<>mrOk then exit;
      ApplyCleanOnce;
    end;
    Result:=mrOk;
  finally
    Tool.Free;
    if LazarusIDE<>nil then
      LazarusIDE.MainBarSubTitle:='';
  end;
end;

function CreateIDEMakeOptions(Profile: TBuildLazarusProfile;
  Macros: TTransferMacroList; const PackageOptions: string;
  Flags: TBuildLazarusFlags; var AExOptions: string;
  out UpdateRevisionInc: boolean; out OutputDirRedirected: boolean): TModalResult;

  procedure AppendExtraOption(const AddOption: string; EncloseIfSpace: boolean);
  begin
    if AddOption='' then exit;
    if AExOptions<>'' then
      AExOptions:=AExOptions+' ';
    if EncloseIfSpace and (Pos(' ',AddOption)>0) then
      AExOptions:=AExOptions+'"'+AddOption+'"'
    else
      AExOptions:=AExOptions+AddOption;
    //DebugLn(['AppendExtraOption ',AExOptions]);
  end;

  procedure AppendExtraOption(const AddOption: string);
  begin
    AppendExtraOption(AddOption,true);
  end;

var
  MakeIDECfgFilename: String;
  NewTargetFilename: String;
  NewTargetDirectory: String;
  NewUnitDirectory: String;
  DefaultTargetOS: string;
  DefaultTargetCPU: string;
  NewTargetOS: String;
  NewTargetCPU: String;
  CrossCompiling: Boolean;
  CurTargetFilename: String;
  BundleDir: String;
  ExeLocked: Boolean;
begin
  Result:=mrOk;
  OutputDirRedirected:=false;
  UpdateRevisionInc:=Profile.UpdateRevisionInc;

  // create extra Profile
  AExOptions:=Profile.ExtraOptions;

  // check for special IDE config file
  if (blfUseMakeIDECfg in Flags) then begin
    MakeIDECfgFilename:=GetMakeIDEConfigFilename;
    //DebugLn(['CreateBuildLazarusOptions MAKE MakeIDECfgFilename=',MakeIDECfgFilename,' ',FileExistsUTF8(MakeIDECfgFilename)]);
    if (FileExistsUTF8(MakeIDECfgFilename)) then begin
      // If a file name contains spaces, a file name whould need to be quoted.
      // Using a single quote is not possible, it is used already in the
      // makefile to group all Profile in OPT='bla bla'.
      // using " implicates that make uses a shell to execute the command of
      // that line. But using shells (i.e. command.com, cmd.exe, etc) is so
      // fragile (see bug 11362), that is better to avoid this.
      // Therefore we use a short 8.3 file and path name, so we don't need to
      // use quotes at all.
      // On platforms other than windows, ExtractShortPathName is implemented
      // too and simply returns the passed file name, so there is no need
      // for $IFDEF.
      if pos(' ',MakeIDECfgFilename)>0 then
        MakeIDECfgFilename:=ExtractShortPathNameUTF8(MakeIDECfgFilename);
      AppendExtraOption('@'+MakeIDECfgFilename);
    end;
  end;

  // set target filename and target directory:
  // 1. the user has set a target directory
  // 2. For crosscompiling the IDE it needs a different directory
  // 3. If lazarus is installed as root/administrator, the lazarus executable
  //    is readonly and needs a different name and directory
  //    (e.g. ~/.lazarus/bin/lazarus).
  // 4. Platforms like windows locks executables, so lazarus can not replace
  //    itself. They need a different name (e.g. lazarus.new.exe).
  //    The target directory is writable, the lazarus.o file can be created.
  // 5. If the user uses the startlazarus utility, then we need a backup.
  //    Under non locking platforms 'make' cleans the lazarus executable, so
  //    the IDE will rename the old file first (e.g. to lazarus.old).
  //    Renaming is not needed.
  // Otherwise: Don't touch the target filename.

  NewTargetFilename:='';
  NewUnitDirectory:='';
  NewTargetDirectory:='';
  DefaultTargetOS:=GetDefaultTargetOS;
  DefaultTargetCPU:=GetDefaultTargetCPU;
  NewTargetOS:=Profile.FPCTargetOS;
  NewTargetCPU:=Profile.FPCTargetCPU;
  if NewTargetOS='' then NewTargetOS:=DefaultTargetOS;
  if NewTargetCPU='' then NewTargetCPU:=DefaultTargetCPU;
  CrossCompiling:=(CompareText(NewTargetOS,DefaultTargetOS)<>0) or (CompareText(NewTargetCPU,DefaultTargetCPU)<>0);
  ExeLocked:=OSLocksExecutables and (not (blfReplaceExe in Flags))
             and (not CrossCompiling);

  //DebugLn(['CreateBuildLazarusOptions NewTargetOS=',NewTargetOS,' NewTargetCPU=',NewTargetCPU]);
  if (Profile.TargetDirectory<>'') then begin
    // Case 1. the user has set a target directory
    NewTargetDirectory:=Profile.GetParsedTargetDirectory(Macros);
    if NewTargetDirectory='' then begin
      debugln('CreateBuildLazarusOptions macro aborted Options.TargetDirectory=',Profile.TargetDirectory);
      Result:=mrAbort;
      exit;
    end;
    NewUnitDirectory:=AppendPathDelim(NewTargetDirectory)+'units';
    debugln('CreateBuildLazarusOptions TargetDirectory=',NewTargetDirectory);
    debugln('CreateBuildLazarusOptions UnitsTargetDirectory=',NewUnitDirectory);
    if ExeLocked then begin
      // Allow for the case where this corresponds to the current executable
      NewTargetFilename:='lazarus'+GetExecutableExt(NewTargetOS);
      if FileExistsUTF8(AppendPathDelim(NewTargetDirectory)+NewTargetFilename) then
        NewTargetFilename:='lazarus.new'+GetExecutableExt(NewTargetOS)
    end;
  end else begin
    // no user defined target directory
    // => find it automatically

    if CrossCompiling then
    begin
      // Case 2. crosscompiling the IDE
      // create directory <primary config dir>/bin/<TargetCPU>-<TargetOS>
      NewTargetDirectory:=AppendPathDelim(GetPrimaryConfigPath)+'bin'
                          +PathDelim+NewTargetCPU+'-'+NewTargetOS;
      NewUnitDirectory:=AppendPathDelim(GetPrimaryConfigPath)+'units'
                      +PathDelim+NewTargetCPU+'-'+NewTargetOS;
      debugln('CreateBuildLazarusOptions Options.TargetOS=',Profile.FPCTargetOS,' Options.TargetCPU=',
              Profile.FPCTargetCPU,' DefaultOS=',DefaultTargetOS,' DefaultCPU=',DefaultTargetCPU);
    end else begin
      // -> normal compile for this platform

      // get lazarus directory
      if Macros<>nil then begin
        NewTargetDirectory:='$(LazarusDir)';
        Macros.SubstituteStr(NewTargetDirectory);
      end;

      if (NewTargetDirectory<>'') and DirPathExists(NewTargetDirectory) then
      begin
        if not DirectoryIsWritableCached(NewTargetDirectory) then begin
          // Case 3. the lazarus directory is not writable
          // create directory <primary config dir>/bin/
          UpdateRevisionInc:=false;
          NewTargetDirectory:=AppendPathDelim(GetPrimaryConfigPath)+'bin';
          debugln('CreateBuildLazarusOptions LazDir readonly NewTargetDirectory=',NewTargetDirectory);
          NewUnitDirectory:=AppendPathDelim(GetPrimaryConfigPath)+'units'
                          +PathDelim+NewTargetCPU+'-'+NewTargetOS;
        end else begin
          // the lazarus directory is writable
          if ExeLocked then begin
            // Case 4. the current executable is locked
            // => use a different output name
            NewTargetFilename:='lazarus.new'+GetExecutableExt(NewTargetOS);
            debugln('CreateBuildLazarusOptions exe locked NewTargetFilename=',NewTargetFilename);
          end else begin
            // Case 5. or else: => just compile to current directory
            NewTargetDirectory:='';
          end;
        end;
      end else begin
        // lazarus dir is not valid (probably someone is experimenting)
        // -> just compile to current directory
        NewTargetDirectory:='';
      end;
    end;
  end;
  // create output directories
  Result:=ForceDirectoryInteractive(NewTargetDirectory,[]);
  if Result<>mrOk then exit;
  Result:=ForceDirectoryInteractive(NewUnitDirectory,[]);
  if Result<>mrOk then exit;

  OutputDirRedirected:=NewTargetDirectory<>'';

  // create apple bundle if needed
  //debugln(['CreateBuildLazarusOptions NewTargetDirectory=',NewTargetDirectory]);
  if (Profile.TargetPlatform in [lpCarbon,lpCocoa])
  and (NewTargetDirectory<>'')
  and (DirectoryIsWritableCached(NewTargetDirectory)) then begin
    CurTargetFilename:=NewTargetFilename;
    if CurTargetFilename='' then
      CurTargetFilename:='lazarus'+GetExecutableExt(NewTargetOS);
    if not FilenameIsAbsolute(CurTargetFilename) then
      CurTargetFilename:=AppendPathDelim(NewTargetDirectory)+CurTargetFilename;
    BundleDir:=ChangeFileExt(CurTargetFilename,'.app');
    //debugln(['CreateBuildLazarusOptions checking bundle ',BundleDir]);
    if not FileExistsCached(BundleDir) then begin
      //debugln(['CreateBuildLazarusOptions CurTargetFilename=',CurTargetFilename]);
      Result:=CreateApplicationBundle(CurTargetFilename, 'Lazarus');
      if not (Result in [mrOk,mrIgnore]) then begin
        debugln(['CreateBuildLazarusOptions CreateApplicationBundle failed']);
        if IDEMessagesWindow<>nil then
          IDEMessagesWindow.AddMsg('Error: failed to create application bundle '+BundleDir,NewTargetDirectory,-1);
        exit;
      end;
      Result:=CreateAppBundleSymbolicLink(CurTargetFilename);
      if not (Result in [mrOk,mrIgnore]) then begin
        debugln(['CreateBuildLazarusOptions CreateAppBundleSymbolicLink failed']);
        if IDEMessagesWindow<>nil then
          IDEMessagesWindow.AddMsg('Error: failed to create application bundle symlink to '+CurTargetFilename,NewTargetDirectory,-1);
        exit;
      end;
    end;
  end;

  if NewUnitDirectory<>'' then
    // FPC interpretes '\ ' as an escape for a space in a path,
    // so make sure the directory doesn't end with the path delimeter.
    AppendExtraOption('-FU'+ChompPathDelim(NewUnitDirectory));

  if NewTargetDirectory<>'' then
    // FPC interpretes '\ ' as an escape for a space in a path,
    // so make sure the directory doesn't end with the path delimeter.
    AppendExtraOption('-FE'+ChompPathDelim(NewTargetDirectory));

  if NewTargetFilename<>'' then begin
    // FPC automatically changes the last extension (append or replace)
    // For example under linux, where executables don't need any extension
    // fpc removes the last extension of the -o option.
    // Trick fpc:
    if GetExecutableExt(NewTargetOS)='' then
      NewTargetFilename:=NewTargetFilename+'.dummy';
    AppendExtraOption('-o'+NewTargetFilename);
  end;

  // add package Profile for IDE
  //DebugLn(['CreateBuildLazarusOptions blfUseMakeIDECfg=',blfUseMakeIDECfg in FLags,' ExtraOptions="',AExOptions,'" ',PackageOptions]);
  if not (blfUseMakeIDECfg in Flags) then
    AppendExtraOption(PackageOptions,false);
  //DebugLn(['CreateBuildLazarusOptions ',MMDef.Name,' ',AExOptions]);
end;

function SaveIDEMakeOptions(Profile: TBuildLazarusProfile;
  Macros: TTransferMacroList;
  const PackageOptions: string; Flags: TBuildLazarusFlags): TModalResult;

  function BreakOptions(const OptionString: string): string;
  var
    StartPos: Integer;
    EndPos: Integer;
    c: Char;
    CurLine: String;
  begin
    Result:='';
    // write each option into a line of its own
    StartPos:=1;
    repeat
      while (StartPos<=length(OptionString)) and (OptionString[StartPos]=' ') do
        inc(StartPos);
      EndPos:=StartPos;
      while EndPos<=length(OptionString) do begin
        c:=OptionString[EndPos];
        case c of
        ' ': break;

        '''','"','`':
          begin
            repeat
              inc(EndPos);
              if (OptionString[EndPos]=c) then begin
                inc(EndPos);
                break;
              end;
            until (EndPos>length(OptionString));
          end;

        else
          inc(EndPos);
        end;
      end;
      if (EndPos>StartPos) then begin
        CurLine:=Trim(copy(OptionString,StartPos,EndPos-StartPos));
        if (length(CurLine)>2) and (CurLine[1] in ['''','"','`'])
        and (CurLine[1]=CurLine[length(CurLine)]) then begin
          // whole line enclosed in quotation marks
          // in fpc config this is forbidden and gladfully unncessary
          CurLine:=copy(CurLine,2,length(CurLine)-2);
        end;
        Result:=Result+CurLine+LineEnding;
      end;
      StartPos:=EndPos;
    until StartPos>length(OptionString);
  end;

var
  ExOptions: String;
  Filename: String;
  fs: TFileStream;
  OptionsAsText: String;
  UpdateRevisionInc: boolean;
  OutputDirRedirected: boolean;
begin
  ExOptions:='';
  Result:=CreateIDEMakeOptions(Profile, Macros, PackageOptions, Flags,
                               ExOptions, UpdateRevisionInc, OutputDirRedirected);
  if Result<>mrOk then exit;
  Filename:=GetMakeIDEConfigFilename;
  try
    InvalidateFileStateCache;
    fs:=TFileStream.Create(UTF8ToSys(Filename),fmCreate);
    try
      if ExOptions<>'' then begin
        OptionsAsText:=BreakOptions(ExOptions);
        fs.Write(OptionsAsText[1],length(OptionsAsText));
      end;
    finally
      fs.Free;
    end;
  except
    on E: Exception do begin
      Result:=IDEMessageDialog(lisLazBuildErrorWritingFile,
        Format(lisLazBuildUnableToWriteFile, [Filename, #13])
        +E.Message,
        mtError,[mbCancel,mbAbort]);
      exit;
    end;
  end;
  Result:=mrOk;
end;

function GetMakeIDEConfigFilename: string;
begin
  Result:=AppendPathDelim(GetPrimaryConfigPath)+DefaultIDEMakeOptionFilename;
end;

{ TConfigureBuildLazarusDlg }

constructor TConfigureBuildLazarusDlg.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  fProfiles:=TBuildLazarusProfiles.Create;
  fUpdatingProfileCombo:=False;
end;

destructor TConfigureBuildLazarusDlg.Destroy;
begin
  fProfiles.Free;
  inherited Destroy;
end;

procedure TConfigureBuildLazarusDlg.FormCreate(Sender: TObject);
var
  LCLInterface: TLCLPlatform;
begin
  IDEDialogLayoutList.ApplyLayout(Self,700,480);

  Caption := Format(lisConfigureBuildLazarus, ['"', '"']);
  PageControl1.ActivePage:=BuildTabSheet;
  BuildTabSheet.Caption:=lisBuildCaption;

  // Show Build target names in combobox.
  LCLWidgetTypeLabel.Caption := lisLCLWidgetType;
  for LCLInterface:=Low(TLCLPlatform) to High(TLCLPlatform) do
    LCLWidgetTypeComboBox.Items.Add(LCLPlatformDisplayNames[LCLInterface]);

  BuildProfileLabel.Caption:=lisLazBuildProfile;
  BuildProfileButton.Hint := lisLazBuildManageProfiles2;
  BuildProfileComboBox.Hint := lisLazBuildNameOfTheActiveProfile;
  OptionsLabel.Caption := lisLazBuildOptions;
  TargetOSLabel.Caption := lisLazBuildTargetOS;
  TargetCPULabel.Caption := lisLazBuildTargetCPU;
  TargetDirectoryLabel.Caption := lisLazBuildTargetDirectory;

  DefinesListBox.Hint := lisLazBuildDefinesWithoutD;
  DefinesLabel.Caption := lisLazBuildDefines;
  DefinesButton.Caption := lisLazBuildEditDefines;
  DefinesButton.Hint := lisLazBuildEditListOfDefinesWhichCanBeUsedByAnyProfile;

  CleanUpGroupBox.Caption:=lisCleanUp;
  CleanAutoRadioButton.Caption:=lisAutomatically;
  CleanCommonRadioButton.Caption:=lisCleanCommonFiles;
  CleanAllRadioButton.Caption:=lisCleanAll;
  CleanOnceCheckBox.Caption:=lisCleanOnlyOnce;
  CleanOnceCheckBox.Hint:=lisAfterCleaningUpSwitchToAutomaticClean;

  UpdateRevisionIncCheckBox.Caption := lisLazBuildUpdateRevInc;
  UpdateRevisionIncCheckBox.Hint := lisLazBuildUpdateRevisionInfoInAboutLazarusDialog;

  CommonsDividerBevel.Caption := lisLazBuildCommonSettings;
  RestartAfterBuildCheckBox.Caption := lisLazBuildRestartAfterBuild;
  RestartAfterBuildCheckBox.Hint := lisLazBuildRestartLazarusAutomatically;
  ConfirmBuildCheckBox.Caption := lisLazBuildConfirmBuild;
  ConfirmBuildCheckBox.Hint := lisLazBuildShowConfirmationDialogWhenBuilding;

  CompileButton.Caption := lisBuild;
  CompileButton.LoadGlyphFromLazarusResource('menu_build');
  CompileAdvancedButton.Caption := lisLazBuildBuildMany;
  CompileAdvancedButton.LoadGlyphFromLazarusResource('menu_build_all');
  SaveSettingsButton.Caption := lisSaveSettings;
  SaveSettingsButton.LoadGlyphFromStock(idButtonSave);
  if SaveSettingsButton.Glyph.Empty then
    SaveSettingsButton.LoadGlyphFromLazarusResource('laz_save');
  CancelButton.Caption := lisCancel;
  HelpButton.Caption := lisMenuHelp;

  OptionsMemo.Hint := lisLazBuildOptionsPassedToCompiler;

  with TargetOSComboBox do
  begin
    with Items do begin
      Add(''); //('+rsiwpDefault+')');
      Add('Darwin');
      Add('FreeBSD');
      Add('Linux');
      Add('NetBSD');
      Add('OpenBSD');
      Add('Solaris');
      Add('Win32');
      Add('Win64');
      Add('WinCE');
      Add('go32v2');
      Add('os2');
      Add('beos');
      Add('haiku');
      Add('qnx');
      Add('netware');
      Add('wdosx');
      Add('emx');
      Add('watcom');
      Add('netwlibc');
      Add('amiga');
      Add('atari');
      Add('palmos');
      Add('gba');
      Add('nds');
      Add('macos');
      Add('morphos');
      Add('embedded');
      Add('symbian');
    end;
    ItemIndex:=0;
  end;

  with TargetCPUComboBox do begin
    with Items do begin
      Add(''); //('+rsiwpDefault+')');
      Add('arm');
      Add('i386');
      Add('m68k');
      Add('powerpc');
      Add('sparc');
      Add('x86_64');
    end;
    ItemIndex:=0;
  end;

  SetupInfoPage;
end;

procedure TConfigureBuildLazarusDlg.FormResize(Sender: TObject);
begin
  LCLWidgetTypeComboBox.Width:=(OptionsMemo.Width - 12) div 3;
  TargetOSComboBox.Width:=LCLWidgetTypeComboBox.Width;
  DefinesListBox.Width:=(OptionsMemo.Width - 6) div 2;
end;

procedure TConfigureBuildLazarusDlg.FormShow(Sender: TObject);
begin
  UpdateProfileNamesUI;
end;

procedure TConfigureBuildLazarusDlg.HelpButtonClick(Sender: TObject);
begin
  LazarusHelp.ShowHelpForIDEControl(Self);
end;

procedure TConfigureBuildLazarusDlg.ShowOptsMenuItemClick(Sender: TObject);
begin
  CopyUIToProfile(Profiles.Current);
  ShowMessage(fProfiles.Current.ExtraOptions);
end;

procedure TConfigureBuildLazarusDlg.TargetDirectoryButtonClick(Sender: TObject);
var
  AFilename: String;
  DirDialog: TSelectDirectoryDialog;
begin
  DirDialog:=TSelectDirectoryDialog.Create(nil);
  try
    DirDialog.Options:=DirDialog.Options+[ofPathMustExist];
    DirDialog.Title:=lisLazBuildABOChooseOutputDir+'(lazarus'+
                      GetExecutableExt(Profiles.Current.FPCTargetOS)+')';
    if DirDialog.Execute then begin
      AFilename:=CleanAndExpandDirectory(DirDialog.Filename);
      TargetDirectoryComboBox.AddHistoryItem(AFilename,10,true,true);
    end;
  finally
    DirDialog.Free;
  end;
end;

procedure TConfigureBuildLazarusDlg.CopyProfileToUI(AProfile: TBuildLazarusProfile);
var
  i: Integer;
begin
  LCLWidgetTypeComboBox.ItemIndex   :=ord(AProfile.TargetPlatform);
  UpdateRevisionIncCheckBox.Checked :=AProfile.UpdateRevisionInc;
  TargetOSComboBox.Text             :=AProfile.TargetOS;
  TargetDirectoryComboBox.Text      :=AProfile.TargetDirectory;
  TargetCPUComboBox.Text            :=AProfile.TargetCPU;
  case AProfile.IdeBuildMode of
  bmBuild: CleanAutoRadioButton.Checked:=true;
  bmCleanBuild: CleanCommonRadioButton.Checked:=true;
  bmCleanAllBuild: CleanAllRadioButton.Checked:=true;
  end;
  CleanOnceCheckBox.Checked:=AProfile.CleanOnce;
  OptionsMemo.Lines.Assign(AProfile.OptionsLines);
  for i:=0 to DefinesListBox.Items.Count-1 do
    DefinesListBox.Checked[i]:=AProfile.Defines.IndexOf(DefinesListBox.Items[i]) > -1;
end;

procedure TConfigureBuildLazarusDlg.CopyUIToProfile(AProfile: TBuildLazarusProfile);
var
  i: Integer;
begin
  AProfile.TargetPlatform    :=TLCLPlatform(LCLWidgetTypeComboBox.ItemIndex);
  AProfile.UpdateRevisionInc :=UpdateRevisionIncCheckBox.Checked;
  AProfile.TargetOS          :=TargetOSComboBox.Text;
  AProfile.TargetDirectory   :=TargetDirectoryComboBox.Text;
  AProfile.TargetCPU         :=TargetCPUComboBox.Text;
  if CleanAllRadioButton.Checked then
    AProfile.IdeBuildMode := bmCleanAllBuild
  else if CleanCommonRadioButton.Checked then
    AProfile.IdeBuildMode := bmCleanBuild
  else
    AProfile.IdeBuildMode := bmBuild;
  AProfile.CleanOnce:=CleanOnceCheckBox.Checked;
  AProfile.OptionsLines.Assign(OptionsMemo.Lines);
  AProfile.Defines.Clear;
  for i:=0 to DefinesListBox.Items.Count-1 do
    if DefinesListBox.Checked[i] then
      AProfile.Defines.Add(DefinesListBox.Items[i]);
end;

procedure TConfigureBuildLazarusDlg.UpdateProfileNamesUI;
var
  i: Integer;
begin
  // List of defines to checklistbox.
  DefinesListBox.Items.Clear;
  for i:=0 to fProfiles.AllDefines.Count-1 do
    DefinesListBox.Items.Add(fProfiles.AllDefines[i]);
  // Update the Profiles ComboBox.
  fUpdatingProfileCombo:=True;
  BuildProfileComboBox.Items.BeginUpdate;
  BuildProfileComboBox.Items.Clear;
  for i:=0 to fProfiles.Count-1 do
    BuildProfileComboBox.Items.Add(fProfiles[i].Name);
  BuildProfileCombobox.ItemIndex:=fProfiles.CurrentIndex;
  CopyProfileToUI(fProfiles.Current); // Copy current selection to UI.
  BuildProfileComboBox.Items.EndUpdate;
  fUpdatingProfileCombo:=False;
  RestartAfterBuildCheckBox.Checked:=fProfiles.RestartAfterBuild;
  ConfirmBuildCheckBox.Checked     :=fProfiles.ConfirmBuild;
end;

procedure TConfigureBuildLazarusDlg.SetupInfoPage;
begin
  InfoTabSheet.Caption:=lisInformation;

  fImageIndexPackage := IDEImages.LoadImage(16, 'item_package');
  fImageIndexRequired := IDEImages.LoadImage(16, 'pkg_required');
  fImageIndexInherited := IDEImages.LoadImage(16, 'pkg_inherited');
  InhNoteLabel.Caption := lisAdditionalCompilerOptionsInheritedFromPackages;
  InhTreeView.Images := IDEImages.Images_16;

  UpdateInheritedTree;
end;

procedure TConfigureBuildLazarusDlg.UpdateInheritedTree;
var
  AncestorNode: TTreeNode;

  procedure AddChildNode(const NewNodeName, Value: string);
  var
    VisibleValue: string;
    ChildNode: TTreeNode;
  begin
    VisibleValue := UTF8Trim(Value);
    if VisibleValue = '' then
      exit;
    ChildNode := InhTreeView.Items.AddChild(AncestorNode,
      NewNodeName + ' = "' + VisibleValue + '"');
    ChildNode.ImageIndex := fImageIndexRequired;
    ChildNode.SelectedIndex := ChildNode.ImageIndex;
  end;

var
  PkgList: TFPList;
  i: Integer;
  Pkg: TLazPackage;
  AncestorOptions: TPkgAdditionalCompilerOptions;
  LazDir: String;
begin
  PkgList:=nil;
  InhTreeView.BeginUpdate;
  LazDir:=EnvironmentOptions.GetParsedLazarusDirectory;
  try
    PackageGraph.GetAllRequiredPackages(PackageGraph.FirstAutoInstallDependency,PkgList);

    // add detail nodes
    if PkgList<>nil then
      for i := 0 to PkgList.Count - 1 do
      begin
        Pkg:=TLazPackage(PkgList[i]);
        AncestorOptions := Pkg.UsageOptions;
        AncestorNode := InhTreeView.Items.Add(nil, '');
        AncestorNode.Text := AncestorOptions.GetOwnerName;
        AncestorNode.ImageIndex := fImageIndexPackage;
        AncestorNode.SelectedIndex := AncestorNode.ImageIndex;
        with AncestorOptions.ParsedOpts do
        begin
          AddChildNode(lisunitPath,
            CreateRelativeSearchPath(GetParsedValue(pcosUnitPath),LazDir));
          AddChildNode(lisincludePath,
            CreateRelativeSearchPath(GetParsedValue(pcosIncludePath),LazDir));
          AddChildNode(lisobjectPath,
            CreateRelativeSearchPath(GetParsedValue(pcosObjectPath),LazDir));
          AddChildNode(lislibraryPath,
            CreateRelativeSearchPath(GetParsedValue(pcosLibraryPath),LazDir));
          AddChildNode(lislinkerOptions, GetParsedValue(pcosLinkerOptions));
          AddChildNode(liscustomOptions, GetParsedValue(pcosCustomOptions));
        end;
        AncestorNode.Expanded := True;
      end;
  finally
    InhTreeView.EndUpdate;
    PkgList.Free;
  end;
end;

procedure TConfigureBuildLazarusDlg.PrepareClose;
begin
  CopyUIToProfile(Profiles.Current);
  fProfiles.RestartAfterBuild :=RestartAfterBuildCheckBox.Checked;
  fProfiles.ConfirmBuild      :=ConfirmBuildCheckBox.Checked;
  MainIDEBar.itmToolBuildLazarus.Caption:=
    Format(lisMenuBuildLazarusProf, [Profiles.Current.Name]);
end;

procedure TConfigureBuildLazarusDlg.CompileAdvancedButtonClick(Sender: TObject);
// mrOk=change selected profiles. Selected profiels will be saved or discarded
// depending on the calling dialog
// mrYes=save and compile
// mrCancel=do nothing
var
  EditForm: TGenericCheckListForm;
  i, ind: Integer;
begin
  PrepareClose;
  EditForm:=TGenericCheckListForm.Create(Nil);
  try
    EditForm.Caption:=lisLazBuildSelectProfilesToBuild;
    // Copy profile names to checkboxlist and check the previously selected ones.
    for i:=0 to fProfiles.Count-1 do begin
      ind:=EditForm.CheckListBox1.Items.Add(fProfiles[i].Name);
      if fProfiles.Selected.IndexOf(fProfiles[i].Name)>-1 then
        EditForm.CheckListBox1.Checked[ind]:=True;
    end;
    // Show the form.
    EditForm.ShowModal;
    if EditForm.ModalResult in [mrOK, mrYes] then begin
      // Copy checked profile names to Selected.
      fProfiles.Selected.Clear;
      for i:=0 to fProfiles.Count-1 do begin      // fProfiles and CheckListBox1
        if EditForm.CheckListBox1.Checked[i] then // indexes match now.
          fProfiles.Selected.Add(fProfiles[i].Name);
      end;
    end;
    if EditForm.ModalResult=mrYes then
      ModalResult:=mrAll;
  finally
    EditForm.Free;
  end;
end;

procedure TConfigureBuildLazarusDlg.CompileButtonClick(Sender: TObject);
begin
  PrepareClose;
  ModalResult:=mrYes;
end;

procedure TConfigureBuildLazarusDlg.SaveSettingsButtonClick(Sender: TObject);
begin
  PrepareClose;
  ModalResult:=mrOk;
end;

procedure TConfigureBuildLazarusDlg.DefinesButtonClick(Sender: TObject);
var
  EditForm: TGenericListEditForm;
  i: Integer;
begin
  EditForm:=TGenericListEditForm.Create(Nil);
  try
    EditForm.Caption:=lisLazBuildEditDefinesDialogCaption;
    EditForm.Memo1.Lines.Assign(fProfiles.AllDefines);
    if EditForm.ShowModal=mrOK then begin
      CopyUIToProfile(Profiles.Current); // Make sure changed fields don't get lost.
      fProfiles.AllDefines.Assign(EditForm.Memo1.Lines);
      DefinesListBox.Items.Clear;
      for i:=0 to fProfiles.AllDefines.Count-1 do
        DefinesListBox.Items.Add(fProfiles.AllDefines[i]);
      for i:=0 to DefinesListBox.Items.Count-1 do // Check the right boxes again.
        DefinesListBox.Checked[i]:=fProfiles.Current.Defines.IndexOf(DefinesListBox.Items[i]) > -1;
    end;
  finally
    EditForm.Free;
  end;
end;

procedure TConfigureBuildLazarusDlg.FormClose(Sender: TObject; var CloseAction:
  TCloseAction);
begin
  IDEDialogLayoutList.SaveLayout(Self);
end;

procedure TConfigureBuildLazarusDlg.BuildProfileButtonClick(Sender: TObject);
var
  Frm: TBuildProfileManagerForm;
begin
  Frm:=TBuildProfileManagerForm.Create(nil);
  try
    CopyUIToProfile(Profiles.Current);     // Make sure changed fields get included.
    Frm.Prepare(fProfiles);                // Copy profiles to dialog.
    if Frm.ShowModal = mrOk then begin
      fProfiles.Assign(Frm.ProfsToManage); // Copy profiles back from dialog.
      UpdateProfileNamesUI;
    end;
  finally
    Frm.Free;
  end;
end;

procedure TConfigureBuildLazarusDlg.BuildProfileComboBoxSelect(Sender: TObject);
begin
  // QT binding calls this also when items are added to list. It shouldn't.
  if (fProfiles.Count>0) and not fUpdatingProfileCombo then
    if (Sender as TComboBox).ItemIndex<>-1 then begin
      CopyUIToProfile(fProfiles.Current);    // Save old selection from UI.
      fProfiles.CurrentIndex:=(Sender as TComboBox).ItemIndex;
      CopyProfileToUI(fProfiles.Current);    // Copy new selection to UI.
    end;
end;

end.

