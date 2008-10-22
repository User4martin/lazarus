{***************************************************************************
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
 
  Command line utility to compile lazarus projects and packages.
}
program lazbuild;


{$mode objfpc}{$H+}

{$IFDEF WINDOWS}
  {$R lazbuild.rc}
{$ENDIF}

uses
  Classes, SysUtils, CustApp, LCLProc, Dialogs, Forms, Controls, FileUtil,
  InterfaceBase, Process, AsyncProcess,
  // codetools
  CodeToolManager, DefineTemplates, Laz_XMLCfg,
  // IDEIntf
  MacroIntf, PackageIntf, IDEDialogs, ProjectIntf, IDEExternToolIntf,
  // IDE
  IDEProcs, InitialSetupDlgs, OutputFilter, CompilerOptions,
  TransferMacros, EnvironmentOpts, IDETranslations, LazarusIDEStrConsts,
  MiscOptions, Project, LazConf, PackageDefs, PackageLinks, PackageSystem,
  BuildLazDialog, BuildManager, BaseBuildManager;
  
type

  { TLazBuildApplication }

  TLazBuildApplication = class(TCustomApplication)
  private
    FBuildAll: boolean;
    FBuildIDE: boolean;
    FBuildIDEOptions: string;
    FBuildRecursive: boolean;
    fCompilerOverride: String;
    fCPUOverride: String;
    fOSOverride: String;
    FSkipDependencies: boolean;
    fInitialized: boolean;
    fInitResult: boolean;
    fWidgetsetOverride: String;
    // external tools
    procedure OnExtToolFreeOutputFilter(OutputFilter: TOutputFilter;
                                        ErrorOccurred: boolean);
    procedure OnExtToolNeedsOutputFilter(var OutputFilter: TOutputFilter;
                                         var Abort: boolean);

    // global package functions
    procedure GetDependencyOwnerDescription(Dependency: TPkgDependency;
                                            out Description: string);
    procedure GetDependencyOwnerDirectory(Dependency: TPkgDependency;
                                          out Directory: string);
    procedure GetWritablePkgOutputDirectory(APackage: TLazPackage;
                                            var AnOutDirectory: string);
    // package graph
    procedure PackageGraphAddPackage(Pkg: TLazPackage);
    
    // project
    procedure OnProjectChangeInfoFile(TheProject: TProject);
    procedure OnProjectGetTestDirectory(TheProject: TProject; out
      TestDir: string);

    // dialogs
    function OnIDEMessageDialog(const aCaption, aMsg: string;
                                DlgType: TMsgDlgType; Buttons: TMsgDlgButtons;
                                const HelpKeyword: string): Integer;
    function OnIDEQuestionDialog(const aCaption, aMsg: string;
                                 DlgType: TMsgDlgType; Buttons: array of const;
                                 const HelpKeyword: string): Integer;
  protected
    function BuildFile(Filename: string): boolean;

    // packages
    function BuildPackage(const AFilename: string): boolean;
    function LoadPackage(const AFilename: string): TLazPackage;
    procedure CompilePackage(APackage: TLazPackage; Flags: TPkgCompileFlags);
    procedure CheckPackageGraphForCompilation(APackage: TLazPackage;
                                 FirstDependency: TPkgDependency);

    // projects
    function BuildProject(const AFilename: string): boolean;
    function LoadProject(const AFilename: string): TProject;
    procedure CloseProject(var AProject: TProject);

    // IDE
    function BuildLazarusIDE: boolean;
    function CompileAutoInstallPackages: boolean;

    function Init: boolean;
    procedure LoadEnvironmentOptions;
    procedure LoadMiscellaneousOptions;
    procedure SetupOutputFilter;
    procedure SetupMacros;
    procedure SetupPackageSystem;
    procedure SetupDialogs;
    function RepairedCheckOptions(Const ShortOptions : String;
                   Const Longopts : TStrings; Opts,NonOpts : TStrings) : String;
  public
    Files: TStringList;
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;

    procedure Run;
    function ParseParameters: boolean;
    procedure WriteUsage;
    procedure Error(ErrorCode: Byte; const ErrorMsg: string);
    function OnRunExternalTool(Tool: TIDEExternalToolOptions): TModalResult;

    property BuildAll: boolean read FBuildAll write FBuildAll;// build all files of project/package
    property BuildRecursive: boolean read FBuildRecursive // apply BuildAll flag to dependencies
                                     write FBuildRecursive;
    property SkipDependencies: boolean read FSkipDependencies
                                            write FSkipDependencies;
    property BuildIDE: boolean read FBuildIDE write FBuildIDE;
    property BuildIDEOptions: string read FBuildIDEOptions write FBuildIDEOptions;
    property WidgetSetOverride: String read fWidgetsetOverride
                                            write fWidgetsetOverride;
    property OSOverride: String read fOSOverride write fOSOverride;
    property CPUOverride: String read fCPUOverride write fCPUOverride;
    property CompilerOverride: String read fCompilerOverride write fCompilerOverride;
  end;

var
  Application: TLazBuildApplication = nil;

const
  ErrorFileNotFound = 1;
  ErrorBuildFailed = 2;
  ErrorLoadPackageFailed = 3;
  ErrorPackageNameInvalid = 4;
  ErrorLoadProjectFailed = 5;
  VersionStr = {$I version.inc};

procedure GetDescriptionOfDependencyOwner(Dependency: TPkgDependency;
  out Description: string);
var
  DepOwner: TObject;
begin
  DepOwner:=Dependency.Owner;
  if (DepOwner<>nil) then begin
    if DepOwner is TLazPackage then begin
      Description:=Format(lisPkgMangPackage, [TLazPackage(DepOwner).IDAsString]
        );
    end else if DepOwner is TProject then begin
      Description:=Format(lisPkgMangProject, [ExtractFileNameOnly(TProject(
        DepOwner).ProjectInfoFile)]);
    end else begin
      Description:=dbgsName(DepOwner)
    end;
  end else begin
    Description:=Format(lisPkgMangDependencyWithoutOwner, [Dependency.AsString]
      );
  end;
end;

procedure GetDirectoryOfDependencyOwner(Dependency: TPkgDependency;
  out Directory: string);
var
  DepOwner: TObject;
begin
  DepOwner:=Dependency.Owner;
  if (DepOwner<>nil) then begin
    if DepOwner is TLazPackage then begin
      Directory:=TLazPackage(DepOwner).Directory;
    end else if DepOwner is TProject then begin
      Directory:=TProject(DepOwner).ProjectDirectory;
    end else begin
      Directory:=''
    end;
  end else begin
    Directory:=''
  end;
end;

{ TLazBuildApplication }

procedure TLazBuildApplication.OnExtToolFreeOutputFilter(
  OutputFilter: TOutputFilter; ErrorOccurred: boolean);
begin
  if ErrorOccurred then Error(ErrorBuildFailed,'tool reported error');
end;

procedure TLazBuildApplication.OnExtToolNeedsOutputFilter(
  var OutputFilter: TOutputFilter; var Abort: boolean);
begin
  OutputFilter:=TheOutputFilter;
end;

procedure TLazBuildApplication.GetDependencyOwnerDescription(
  Dependency: TPkgDependency; out Description: string);
begin
  GetDescriptionOfDependencyOwner(Dependency,Description);
end;

procedure TLazBuildApplication.GetDependencyOwnerDirectory(
  Dependency: TPkgDependency; out Directory: string);
begin
  GetDirectoryOfDependencyOwner(Dependency,Directory);
end;

procedure TLazBuildApplication.GetWritablePkgOutputDirectory(
  APackage: TLazPackage; var AnOutDirectory: string);
var
  NewOutDir: String;
begin
  if DirectoryIsWritableCached(AnOutDirectory) then exit;

  ForceDirectory(AnOutDirectory);
  InvalidateFileStateCache;
  if DirectoryIsWritableCached(AnOutDirectory) then exit;
  //debugln('TPkgManager.GetWritablePkgOutputDirectory AnOutDirectory=',AnOutDirectory,' ',dbgs(DirectoryIsWritable(AnOutDirectory)));

  // output directory is not writable
  // -> redirect to config directory
  NewOutDir:=SetDirSeparators('/$(TargetCPU)-$(TargetOS)');
  IDEMacros.SubstituteMacros(NewOutDir);
  NewOutDir:=TrimFilename(GetPrimaryConfigPath+PathDelim+'lib'+PathDelim
                          +APackage.Name+NewOutDir);
  AnOutDirectory:=NewOutDir;
  //debugln('TPkgManager.GetWritablePkgOutputDirectory APackage=',APackage.IDAsString,' AnOutDirectory="',AnOutDirectory,'"');
end;

procedure TLazBuildApplication.PackageGraphAddPackage(Pkg: TLazPackage);
begin
  if FileExists(Pkg.FileName) then PkgLinks.AddUserLink(Pkg);
end;

procedure TLazBuildApplication.OnProjectChangeInfoFile(TheProject: TProject);
begin
  if TheProject<>Project1 then exit;
  if TheProject.IsVirtual then
    CodeToolBoss.SetGlobalValue(ExternalMacroStart+'ProjPath',VirtualDirectory)
  else
    CodeToolBoss.SetGlobalValue(ExternalMacroStart+'ProjPath',
                                Project1.ProjectDirectory)
end;

procedure TLazBuildApplication.OnProjectGetTestDirectory(TheProject: TProject;
  out TestDir: string);
begin
  TestDir:=BuildBoss.GetTestBuildDirectory;
end;

function TLazBuildApplication.OnIDEMessageDialog(const aCaption, aMsg: string;
  DlgType: TMsgDlgType; Buttons: TMsgDlgButtons; const HelpKeyword: string
  ): Integer;
begin
  DumpStack;
  Error(ErrorBuildFailed, Format(lisLazbuildIsNonInteractiveAbortingNow, [
    aCaption, #13, aMsg, #13]));
  Result:=mrCancel;
end;

function TLazBuildApplication.OnIDEQuestionDialog(const aCaption, aMsg: string;
  DlgType: TMsgDlgType; Buttons: array of const; const HelpKeyword: string
  ): Integer;
begin
  DumpStack;
  Error(ErrorBuildFailed, Format(lisLazbuildIsNonInteractiveAbortingNow, [
    aCaption, #13, aMsg, #13]));
  Result:=mrCancel;
end;

function TLazBuildApplication.BuildFile(Filename: string): boolean;
begin
  Result:=false;
  Filename:=CleanAndExpandFilename(Filename);
  if not FileExists(Filename) then begin
    Error(ErrorFileNotFound, 'File not found: '+Filename);
    Exit;
  end;
  
  if CompareFileExt(Filename,'.lpk')=0 then
    Result:=BuildPackage(Filename)
  else if CompareFileExt(Filename,'.lpi')=0 then
    Result:=BuildProject(Filename)
  else if CompareFileExt(Filename,'.lpr')=0 then begin
    Filename:=ChangeFileExt(Filename,'.lpi');
    if FileExists(Filename) then
      Result:=BuildProject(Filename)
    else
      Error(ErrorFileNotFound,'file not found: '+Filename);
  end else
    Error(ErrorBuildFailed,'don''t know how to build: '+Filename);
end;

function TLazBuildApplication.BuildPackage(const AFilename: string): boolean;
var
  APackage: TLazPackage;
  Flags: TPkgCompileFlags;
begin
  Result:=false;
  
  Init;
  
  APackage:=LoadPackage(AFilename);
  if APackage=nil then
    Error(ErrorLoadPackageFailed, 'unable to load package "'+AFilename+'"');
    
  Flags:=[];
  if BuildAll then
    Include(Flags,pcfCleanCompile)
  else
    Include(Flags,pcfOnlyIfNeeded);
  if BuildRecursive and BuildAll then
    Include(Flags,pcfCompileDependenciesClean);
  if SkipDependencies then
    Include(Flags,pcfDoNotCompileDependencies);
  CompilePackage(APackage,Flags);
  
  Result:=true;
end;

function TLazBuildApplication.LoadPackage(const AFilename: string): TLazPackage;
var
  XMLConfig: TXMLConfig;
  ConflictPkg: TLazPackage;
begin
  // check if package is already loaded
  Result:=PackageGraph.FindPackageWithFilename(AFilename);
  if (Result<>nil) then exit;
  Result:=TLazPackage.Create;
  // load the package file
  XMLConfig:=TXMLConfig.Create(AFilename);
  try
    Result.Filename:=AFilename;
    Result.LoadFromXMLConfig(XMLConfig,'Package/');
  finally
    XMLConfig.Free;
  end;
  // check Package Name
  if (Result.Name='') or (not IsValidIdent(Result.Name)) then begin
    Error(ErrorPackageNameInvalid,
          Format(lisPkgMangThePackageNameOfTheFileIsInvalid,
           ['"', Result.Name,'"', #13, '"', Result.Filename, '"']));
  end;
  // check if Package with same name is already loaded
  ConflictPkg:=PackageGraph.FindAPackageWithName(Result.Name,nil);
  if ConflictPkg<>nil then begin
    // replace package
    PackageGraph.ReplacePackage(ConflictPkg,Result);
  end else begin
    // add to graph
    PackageGraph.AddPackage(Result);
  end;
  // save package file links
  PkgLinks.SaveUserLinks;
end;

function TLazBuildApplication.BuildLazarusIDE: boolean;
var
  Flags: TBuildLazarusFlags;
  CurResult: TModalResult;
  BuildLazOptions: TBuildLazarusOptions;
  i: Integer;
  CurItem: TBuildLazarusItem;
  MakeMode: TMakeMode;
  PkgOptions: String;
  InheritedOptionStrings: TInheritedCompOptsStrings;
  TargetDir: String;
begin
  Result:=false;

  Init;

  LoadMiscellaneousOptions;
  BuildLazOptions:=MiscellaneousOptions.BuildLazOpts;
  BuildLazOptions.TargetOS:=OSOverride;
  BuildLazOptions.TargetCPU:=CPUOverride;
  if WidgetSetOverride<>'' then
    BuildLazOptions.TargetPlatform:=DirNameToLCLPlatform(WidgetSetOverride)
  else
    BuildLazOptions.TargetPlatform:=GetDefaultLCLWidgetType;
  BuildLazOptions.LCLPlatform:=BuildLazOptions.TargetPlatform;
  BuildLazOptions.IDEPlatform:=BuildLazOptions.TargetPlatform;
  BuildLazOptions.ExtraOptions:=BuildIDEOptions;
  MakeMode:=mmNone;
  if BuildAll then begin
    BuildLazOptions.CleanAll:=true;
    MakeMode:=mmBuild;
  end;
  for i:=0 to BuildLazOptions.Count-1 do begin
    CurItem:=BuildLazOptions.Items[i];
    if (BuildLazOptions.IndexOf(CurItem)<BuildLazOptions.IndexOf(BuildLazOptions.ItemIDE))
    then
      // these items are needed for the IDE
      CurItem.MakeMode:=MakeMode
    else if CurItem=BuildLazOptions.ItemIDE then
      // always build the IDE
      CurItem.MakeMode:=mmBuild
    else
      // these are goodies (examples)
      CurItem.MakeMode:=mmNone;
  end;

  MainBuildBoss.SetBuildTargetIDE;
  Flags:=[];
  
  // try loading install packages
  PackageGraph.LoadStaticBasePackages;
  PackageGraph.LoadAutoInstallPackages(BuildLazOptions.StaticAutoInstallPackages);

  // save target directory
  TargetDir:=MiscellaneousOptions.BuildLazOpts.TargetDirectory;
  IDEMacros.SubstituteMacros(TargetDir);
  if not ForceDirectory(TargetDir) then begin
    DebugLn('TLazBuildApplication.BuildLazarusIDE: failed creating IDE target directory "',TargetDir,'"');
    exit;
  end;

  // save configs for 'make'
  CurResult:=PackageGraph.SaveAutoInstallConfig;
  if CurResult<>mrOk then begin
    DebugLn('TLazBuildApplication.BuildLazarusIDE: failed saving IDE make config files.');
    exit;
  end;

  // first compile all lazarus components (LCL, SynEdit, CodeTools, ...)
  // but not the IDE
  CurResult:=BuildLazarus(MiscellaneousOptions.BuildLazOpts,
                          EnvironmentOptions.ExternalTools,GlobalMacroList,
                          '',EnvironmentOptions.CompilerFilename,
                          EnvironmentOptions.MakeFilename,
                          Flags+[blfWithoutCompilingIDE,blfWithoutLinkingIDE]);
  if CurResult<>mrOk then begin
    DebugLn('TLazBuildApplication.BuildLazarusIDE: Building standard components (LCL, SynEdit, CodeTools) failed.');
    exit;
  end;
  
  // compile auto install static packages
  if not CompileAutoInstallPackages then begin
    DebugLn('TLazBuildApplication.BuildLazarusIDE: Compile AutoInstall Packages failed.');
    exit;
  end;
  
  // create inherited compiler options
  PkgOptions:=PackageGraph.GetIDEInstallPackageOptions(InheritedOptionStrings);

  // save
  CurResult:=SaveIDEMakeOptions(BuildLazOptions,
                                GlobalMacroList,PkgOptions,Flags+[blfOnlyIDE]);
  if CurResult<>mrOk then begin
    DebugLn('TLazBuildApplication.BuildLazarusIDE: failed saving idemake.cfg');
    exit;
  end;

  // compile IDE
  CurResult:=BuildLazarus(BuildLazOptions,
                          EnvironmentOptions.ExternalTools,GlobalMacroList,
                          PkgOptions,EnvironmentOptions.CompilerFilename,
                          EnvironmentOptions.MakeFilename,
                          Flags+[blfUseMakeIDECfg,blfOnlyIDE]
                          );
  if CurResult<>mrOk then begin
    DebugLn('TLazBuildApplication.BuildLazarusIDE: Building IDE failed.');
    exit;
  end;

  Result:=true;
end;

function TLazBuildApplication.CompileAutoInstallPackages: boolean;
var
  Dependency: TPkgDependency;
  OldDependency: TPkgDependency;
  CurResult: TModalResult;
begin
  Result:=false;
  PackageGraph.BeginUpdate(false);
  try
    Dependency:=PackageGraph.FirstAutoInstallDependency;
    while Dependency<>nil do begin
      OldDependency:=Dependency;
      Dependency:=Dependency.NextRequiresDependency;
      if OldDependency.LoadPackageResult<>lprSuccess then begin
        raise Exception.Create(Format(
            lisPkgMangThePackageIsMarkedForInstallationButCanNotBeFound, [
            '"', OldDependency.AsString, '"', #13]));
      end;
    end;

    // check consistency
    CheckPackageGraphForCompilation(nil,
                      PackageGraph.FirstAutoInstallDependency);

    // compile all auto install dependencies
    CurResult:=PackageGraph.CompileRequiredPackages(nil,
                       PackageGraph.FirstAutoInstallDependency,
                       MiscellaneousOptions.BuildLazOpts.Globals,[pupAsNeeded]);
    if CurResult<>mrOk then exit;

  finally
    PackageGraph.EndUpdate;
  end;
  Result:=true;
end;

procedure TLazBuildApplication.CompilePackage(APackage: TLazPackage;
  Flags: TPkgCompileFlags);
begin
  if APackage.AutoCreated then
    Error(ErrorBuildFailed,APackage.IDAsString+' is an auto created package');

  // check graph for circles and broken dependencies
  if not (pcfDoNotCompileDependencies in Flags) then begin
    CheckPackageGraphForCompilation(APackage,nil);
  end;

  if PackageGraph.CompilePackage(APackage,Flags)<>mrOk then
    Error(ErrorBuildFailed,APackage.IDAsString+' compilation failed');
end;

procedure TLazBuildApplication.CheckPackageGraphForCompilation(
  APackage: TLazPackage; FirstDependency: TPkgDependency);
  
  function PathListToString(PathList: TFPList): string;
  var
    i: Integer;
    Item: TObject;
  begin
    Result:='';
    for i:=0 to PathList.Count-1 do begin
      Item:=TObject(PathList[0]);
      if Item is TPkgDependency then begin
        if Result<>'' then
          Result:=Result+'>';
        Result:=Result+TPkgDependency(Item).AsString;
      end else if Item is TProject then begin
        if Result<>'' then
          Result:=Result+'>';
        Result:=Result
                +'Project:'+ExtractFileNameOnly(TProject(Item).ProjectInfoFile);
      end else if Item is TLazPackage then begin
        if Result<>'' then
          Result:=Result+'>';
        Result:=Result+TLazPackage(Item).IDAsString;
      end else begin
        if Result<>'' then
          Result:=Result+'>';
        Result:=Result+'Unknown:'+dbgsName(Item);
      end;
    end;
  end;
  
var
  PathList: TFPList;
begin
  PathList:=nil;
  try
    // check for broken dependencies
    PathList:=PackageGraph.FindBrokenDependencyPath(APackage,FirstDependency);
    if PathList<>nil then
      Error(ErrorLoadPackageFailed,'Broken dependency: '+PathListToString(PathList));

    // check for circle dependencies
    PathList:=PackageGraph.FindCircleDependencyPath(APackage,FirstDependency);
    if PathList<>nil then
      Error(ErrorLoadPackageFailed,'Circle dependency: '+PathListToString(PathList));
  finally
    PathList.Free;
  end;
end;

function TLazBuildApplication.BuildProject(const AFilename: string): boolean;
var
  CompilerFilename: String;
  WorkingDir: String;
  SrcFilename: String;
  CompilerParams: String;
  ToolBefore: TProjectCompilationToolOptions;
  ToolAfter: TProjectCompilationToolOptions;
begin
  Result:=false;
  CloseProject(Project1);

  Init;

  Project1:=LoadProject(AFilename);
  
  if Project1.MainUnitInfo=nil then
    Error(ErrorBuildFailed,'project has no main unit');
    
  Project1.CompilerOptions.TargetOS:=OSOverride;
  Project1.CompilerOptions.TargetCPU:=CPUOverride;
  Project1.CompilerOptions.LCLWidgetType:=WidgetSetOverride;

  if not SkipDependencies then begin
    // compile required packages
    CheckPackageGraphForCompilation(nil,Project1.FirstRequiredDependency);

    PackageGraph.BeginUpdate(false);
    try
      // automatically compile required packages
      if PackageGraph.CompileRequiredPackages(nil,
                                      Project1.FirstRequiredDependency,
                                      Project1.CompilerOptions.Globals,
                                      [pupAsNeeded])<>mrOk
      then
        Error(ErrorBuildFailed,'Project dependencies of '+AFilename);
    finally
      PackageGraph.EndUpdate;
    end;
  end;
  
  // update all lrs files
  MainBuildBoss.UpdateProjectAutomaticFiles;

  WorkingDir:=Project1.ProjectDirectory;
  SrcFilename:=CreateRelativePath(Project1.MainUnitInfo.Filename,WorkingDir);

  if CompilerOverride <> '' then
    CompilerFilename := CompilerOverride
  else
    CompilerFilename:=Project1.GetCompilerFilename;
  //DebugLn(['TMainIDE.DoBuildProject CompilerFilename="',CompilerFilename,'" CompilerPath="',Project1.CompilerOptions.CompilerPath,'"']);

  CompilerParams:=Project1.CompilerOptions.MakeOptionsString(SrcFilename,nil,[])
                  +' '+PrepareCmdLineOption(SrcFilename);

  // execute compilation tool 'Before'
  ToolBefore:=TProjectCompilationToolOptions(
                                    Project1.CompilerOptions.ExecuteBefore);
  if (crCompile in ToolBefore.CompileReasons) then begin
    if ToolBefore.Execute(
                     Project1.ProjectDirectory,lisExecutingCommandBefore)<>mrOk
    then
      Error(ErrorBuildFailed,'failed "tool before" of project '+AFilename);
  end;

  if (crCompile in Project1.CompilerOptions.CompileReasons) then begin
    // compile
    if TheCompiler.Compile(Project1,
                            WorkingDir,CompilerFilename,CompilerParams,
                            BuildAll,false,false)<>mrOk
    then
      Error(ErrorBuildFailed,'failed compiling of project '+AFilename);
    // compilation succeded -> write state file
    if Project1.SaveStateFile(CompilerFilename,CompilerParams)<>mrOk then
      Error(ErrorBuildFailed,'failed saving statefile of project '+AFilename);
  end;

  // execute compilation tool 'After'
  ToolAfter:=TProjectCompilationToolOptions(
                                     Project1.CompilerOptions.ExecuteAfter);
  // no need to check for mrOk, we are exit if it wasn't
  if (crCompile in ToolAfter.CompileReasons) then begin
    if ToolAfter.Execute(
                      Project1.ProjectDirectory,lisExecutingCommandAfter)<>mrOk
    then
      Error(ErrorBuildFailed,'failed "tool after" of project '+AFilename);
  end;

  Result:=true;
end;

function TLazBuildApplication.LoadProject(const AFilename: string): TProject;
var
  ProjectDesc: TProjectDescriptor;
begin
  ProjectDesc:=TProjectDescriptor.Create;
  try
    Result:=TProject.Create(ProjectDesc);
    // custom initialization
    Result.BeginUpdate(true);
    if ProjectDesc.InitProject(Result)<>mrOk then begin
      Result.EndUpdate;
      Result.Free;
      Result:=nil;
    end;
    Result.EndUpdate;

    Result.MainProject:=true;
    Result.OnFileBackup:=@BuildBoss.BackupFile;
    Result.OnGetTestDirectory:=@OnProjectGetTestDirectory;
    Result.OnChangeProjectInfoFile:=@OnProjectChangeInfoFile;

  finally
    ProjectDesc.Free;
  end;

  Result.BeginUpdate(true);
  try
    // read project info file
    if Result.ReadProject(AFilename)<>mrOk then
      Error(ErrorLoadProjectFailed,'Project '+AFilename);
    //BuildBoss.RescanCompilerDefines(true);

    // load required packages
    PackageGraph.OpenRequiredDependencyList(Result.FirstRequiredDependency);

    //Result.DefineTemplates.AllChanged;
    //Result.DefineTemplates.Active:=true;
  finally
    Result.EndUpdate;
  end;
  IncreaseCompilerParseStamp;
end;

procedure TLazBuildApplication.CloseProject(var AProject: TProject);
begin
  // free project, if it is still there
  FreeThenNil(AProject);
end;

function TLazBuildApplication.Init: boolean;
var
  InteractiveSetup: Boolean;
begin
  if fInitialized then exit(fInitResult);
  fInitResult:=false;
  fInitialized:=true;
  
  CreatePrimaryConfigPath;

  MainBuildBoss:=TBuildManager.Create;
  MainBuildBoss.ScanningCompilerDisabled:=true;
  LoadEnvironmentOptions;
  LoadMiscellaneousOptions;
  InteractiveSetup:=false;
  SetupCompilerFilename(InteractiveSetup);
  SetupLazarusDirectory(InteractiveSetup);
  SetupMacros;
  SetupPackageSystem;
  SetupOutputFilter;
  MainBuildBoss.SetupCompilerInterface;

  // create static base packages
  PackageGraph.AddStaticBasePackages;

  MainBuildBoss.SetBuildTarget(OSOverride,CPUOverride,WidgetSetOverride);

  fInitResult:=true;
end;

procedure TLazBuildApplication.LoadEnvironmentOptions;
begin
  if EnvironmentOptions<>nil then exit;
  EnvironmentOptions:=TEnvironmentOptions.Create;
  with EnvironmentOptions do begin
    SetLazarusDefaultFilename;
    Load(false);
    if Application.HasOption('language') then begin
      debugln('TLazBuildApplication.Init overriding language with command line: ',
        Application.GetOptionValue('language'));
      EnvironmentOptions.LanguageID:=Application.GetOptionValue('language');
    end;
    TranslateResourceStrings(EnvironmentOptions.LazarusDirectory,
                             EnvironmentOptions.LanguageID);
    ExternalTools.OnNeedsOutputFilter:=@OnExtToolNeedsOutputFilter;
    ExternalTools.OnFreeOutputFilter:=@OnExtToolFreeOutputFilter;
    if CompilerOverride<>'' then
      CompilerFilename:=CompilerOverride;
  end;
end;

procedure TLazBuildApplication.LoadMiscellaneousOptions;
begin
  if MiscellaneousOptions<>nil then exit;
  MiscellaneousOptions:=TMiscellaneousOptions.Create;
  MiscellaneousOptions.Load;
end;

procedure TLazBuildApplication.SetupOutputFilter;
begin
  TheOutputFilter:=TOutputFilter.Create;
  TheOutputFilter.OnGetIncludePath:=@CodeToolBoss.GetIncludePathForDirectory;
end;

procedure TLazBuildApplication.SetupMacros;
begin
  MainBuildBoss.SetupTransferMacros;
end;

procedure TLazBuildApplication.SetupPackageSystem;
begin
  OnGetDependencyOwnerDescription:=@GetDependencyOwnerDescription;
  OnGetDependencyOwnerDirectory:=@GetDependencyOwnerDirectory;
  OnGetWritablePkgOutputDirectory:=@GetWritablePkgOutputDirectory;

  // package links
  PkgLinks:=TPackageLinks.Create;
  PkgLinks.UpdateAll;

  // package graph
  PackageGraph:=TLazPackageGraph.Create;
  PackageGraph.OnAddPackage:=@PackageGraphAddPackage;
end;

procedure TLazBuildApplication.SetupDialogs;
begin
  IDEMessageDialog:=@OnIDEMessageDialog;
  IDEQuestionDialog:=@OnIDEQuestionDialog;
end;

function TLazBuildApplication.RepairedCheckOptions(const ShortOptions: String;
  const Longopts: TStrings; Opts, NonOpts: TStrings): String;

Var
  I,J,L,P : Integer;
  O,OV : String;
  HaveArg : Boolean;
  NeedArg: Boolean;

  Function FindLongOpt(S : String) : boolean;

  Var
    I : integer;

  begin
    If CaseSensitiveOptions then
      begin
      I:=LongOpts.Count-1;
      While (I>=0) and (LongOpts[i]<>S) do
        Dec(i);
      end
    else
      begin
      S:=UpperCase(S);
      I:=LongOpts.Count-1;
      While (I>=0) and (UpperCase(LongOpts[i])<>S) do
        Dec(i);
      end;
    Result:=(I<>-1);
  end;

begin
  Result:='';
  I:=1;
  While (I<=ParamCount) and (Result='') do
    begin
    O:=Paramstr(I);
    If (Length(O)=0) or (O[1]<>OptionChar) then
      begin
      If Assigned(NonOpts) then
        NonOpts.Add(O)
      end
    else
      begin
      If (Length(O)<2) then
        Result:=Format(lisErrInvalidOption,[i,O])
      else
        begin
        HaveArg:=False;
        OV:='';
        // Long option ?
        If (O[2]=OptionChar) then
          begin
          Delete(O,1,2);
          J:=Pos('=',O);
          If J<>0 then
            begin
            HaveArg:=true;
            OV:=O;
            Delete(OV,1,J);
            O:=Copy(O,1,J-1);
            end;
          // Switch Option
          If FindLongopt(O) then
            begin
            If HaveArg then
              Result:=Format(lisErrNoOptionAllowed,[I,O]);
            end
          else
            begin // Required argument
            If FindLongOpt(O+':') then
              begin
              If Not HaveArg then
                Result:=Format(lisErrOptionNeeded,[I,O]);
              end
            else
              begin // Optional Argument.
              If not FindLongOpt(O+'::') then
                Result:=Format(lisErrInvalidOption,[I,O]);
              end;
            end;
          end
        else // Short Option.
          begin
          HaveArg:=(I<ParamCount) and (Length(ParamStr(I+1))>0)
                   and (ParamStr(I+1)[i]<>OptionChar);
          If HaveArg then
            OV:=Paramstr(I+1);
          If Not CaseSensitiveOptions then
            O:=LowerCase(O);
          L:=Length(O);
          J:=2;
          NeedArg:=false;
          While (result='') and (J<=L) do
            begin
            P:=Pos(O[J],ShortOptions);
            If (P=0) or (O[j]=':') then
              Result:=Format(lisErrInvalidOption,[I,O[J]])
            else
              begin
              If (P<Length(ShortOptions)) and (Shortoptions[P+1]=':') then
                begin
                // Required argument
                NeedArg:=true;
                Writeln('P ',P,' J ',J,' ',O[J],' ',l,' Havearg ',HaveArg);
                If ((P+1)=Length(ShortOptions)) or (Shortoptions[P+2]<>':') Then
                  If (J<L) or not haveArg then // Must be last in multi-opt !!
                    Result:=Format(lisErrOptionNeeded,[I,O[J]]);
                O:=O[j]; // O is added to arguments.
                end;
              end;
            Inc(J);
            end;
          if not NeedArg then HaveArg:=false;
          If HaveArg then
            begin
            Inc(I); // Skip argument.
            O:=O[Length(O)]; // O is added to arguments !
            end;
          end;
        If HaveArg and (Result='') then
          If Assigned(Opts) then
            Opts.Add(O+'='+OV);
        end;
      end;
    Inc(I);
    end;
end;

constructor TLazBuildApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  SetupDialogs;
  TOutputFilterProcess:=TProcessUTF8;
  Files:=TStringList.Create;
  RunExternalTool := @OnRunExternalTool;
end;

destructor TLazBuildApplication.Destroy;
begin
  CloseProject(Project1);

  FreeThenNil(PackageGraph);
  FreeThenNil(PkgLinks);
  FreeThenNil(TheCompiler);
  FreeThenNil(TheOutputFilter);
  FreeThenNil(GlobalMacroList);
  FreeThenNil(IDEMacros);
  FreeThenNil(MiscellaneousOptions);
  FreeThenNil(EnvironmentOptions);
  FreeThenNil(MainBuildBoss);

  FreeAndNil(Files);
  inherited Destroy;
end;

procedure TLazBuildApplication.Run;
var
  i: Integer;
begin
  if not ParseParameters then exit;

  for i:=0 to Files.Count-1 do begin
    if not BuildFile(Files[i]) then begin
      writeln('Failed building ',Files[i]);
      ExitCode := ErrorBuildFailed;
      exit;
    end;
  end;
  
  if BuildIDE then begin
    if not BuildLazarusIDE then begin
      writeln('Failed building Lazarus IDE');
      ExitCode := ErrorBuildFailed;
      exit;
    end;
  end;
end;

function TLazBuildApplication.ParseParameters: boolean;
var
  Options: TStringList;
  NonOptions: TStringList;
  ErrorMsg: String;
  LongOptions: TStringList;
begin
  Result:=false;
  if (ParamCount<=0)
   or (CompareText(ParamStr(1),'--help')=0)
   or (CompareText(ParamStr(1),'-help')=0)
   or (CompareText(ParamStr(1),'-?')=0)
   or (CompareText(ParamStr(1),'-h')=0)
  then begin
    WriteUsage;
    exit;
  end;
  if HasOption('h','help') or HasOption('?') then begin
    WriteUsage;
    exit;
  end;
  if HasOption('v','version') then begin
    writeln(VersionStr);
    exit;
  end;
  Options:=TStringList.Create;
  NonOptions:=TStringList.Create;
  LongOptions:=TStringList.Create;
  try
    LongOptions.Add('primary-config-path:');
    LongOptions.Add('pcp:');
    LongOptions.Add('secondary-config-path:');
    LongOptions.Add('scp:');
    LongOptions.Add('language:');
    LongOptions.Add('build-all');
    LongOptions.Add('build-ide:');
    LongOptions.Add('recursive');
    LongOptions.Add('skip-dependencies');
    LongOptions.Add('widgetset:');
    LongOptions.Add('ws:');
    LongOptions.Add('operating-system:');
    LongOptions.Add('os:');
    LongOptions.Add('cpu:');
    LongOptions.Add('compiler:');
    ErrorMsg:=RepairedCheckOptions('lBrd',LongOptions,Options,NonOptions);
    if ErrorMsg<>'' then begin
      writeln(ErrorMsg);
      writeln('');
      exit;
    end;

    // building IDE
    if HasOption('build-ide') then begin
      BuildIDE:=true;
      BuildIDEOptions:=GetOptionValue('build-ide');
    end;

    // files
    Files.Assign(NonOptions);
    if (Files.Count=0) and (not BuildIDE) then begin
      writeln('Error: missing file');
      WriteUsage;
      exit;
    end;

    // primary config path
    if HasOption('primary-config-path') then
      SetPrimaryConfigPath(GetOptionValue('primary-config-path'))
    else if HasOption('pcp') then
      SetPrimaryConfigPath(GetOptionValue('pcp'));

    // secondary config path
    if HasOption('secondary-config-path') then
      SetPrimaryConfigPath(GetOptionValue('secondary-config-path'))
    else if HasOption('scp') then
      SetSecondaryConfigPath(GetOptionValue('scp'));
      
    // build all
    if HasOption('B','build-all') then
      BuildAll:=true;
    if HasOption('r','recursive') then
      BuildRecursive:=true;
    if HasOption('d','skip-dependencies') then
      SkipDependencies:=true;

    // overides
    // widgetset
    if HasOption('ws') then
      WidgetSetOverride := GetOptionValue('ws')
    else if HasOption('widgetset') then
      WidgetSetOverride := GetOptionValue('widgetset');
      
    // operating system
    if HasOption('os') then
      OSOverride := GetOptionValue('os')
    else if HasOption('operating-system') then
      OSOverride := GetOptionValue('operating-system');

    // cpu
    if HasOption('cpu') then
      CPUOverride := GetOptionValue('cpu');
      
    // compiler
    if HasOption('compiler') then
      CompilerOverride := GetOptionValue('compiler');

  finally
    Options.Free;
    NonOptions.Free;
    LongOptions.Free;
  end;
  Result:=true;
end;

procedure TLazBuildApplication.WriteUsage;
const
  space = '                      ';
begin
  TranslateResourceStrings(ProgramDirectory,'');
  writeln('');
  writeln('lazbuild [options] <project or package-filename>');
  writeln('');
  writeln(UTF8ToConsole(lisEdtExtToolParameters));
  writeln('');
  writeln('--help or -?              ', UTF8ToConsole(listhisHelpMessage));
  writeln('');
  writeln('-B or --build-all         ', UTF8ToConsole(lisBuildAllFilesOfProjectPackageIDE));
  writeln('-r or --recursive         ', UTF8ToConsole(lisApplyBuildFlagsBToDependenciesToo));
  writeln('-d or --skip-dependencies ', UTF8ToConsole(lisDoNotCompileDependencies));
  writeln('--build-ide=<options>     ', UTF8ToConsole(lisBuildIDEWithPackages));
  writeln('-v or --version           ', UTF8ToConsole(lisShowVersionAndExit));
  writeln('');
  writeln(PrimaryConfPathOptLong,'<path>');
  writeln('or ',PrimaryConfPathOptShort,'<path>');
  writeln(UTF8ToConsole(BreakString(space+lisprimaryConfigDirectoryWhereLazarusStoresItsConfig,
                      75, 22)), LazConf.GetPrimaryConfigPath);
  writeln('');
  writeln(SecondaryConfPathOptLong,'<path>');
  writeln('or ',SecondaryConfPathOptShort,'<path>');
  writeln(UTF8ToConsole(BreakString(space+lissecondaryConfigDirectoryWhereLazarusSearchesFor,
                      75, 22)), LazConf.GetSecondaryConfigPath);
  writeln('');
  writeln('--operating-system=<operating-system>');
  writeln('or --os=<operating-system>');
  writeln(UTF8ToConsole(BreakString(Format(
    lisOverrideTheProjectOperatingSystemEGWin32LinuxDefau, [space,
    LazConf.GetDefaultTargetOS]),
                      75, 22)));
  writeln('');
  writeln('--widgetset=<widgetset>');
  writeln('or --ws=<widgetset>');
  writeln(UTF8ToConsole(BreakString(Format(
    lisOverrideTheProjectWidgetsetEGGtkGtk2QtWin32CarbonD, [space,
    LCLPlatformDirNames[LazConf.GetDefaultLCLWidgetType]]) ,
                      75, 22)));
  writeln('');
  writeln('--cpu=<cpu>');
  writeln(UTF8ToConsole(BreakString(Format(
    lisOverrideTheProjectCpuEGI386X86_64PowerpcPowerpc_64, [space,
    LazConf.GetDefaultTargetCPU]),
                      75, 22)));
  writeln('');
  writeln('--compiler=<ppcXXX>');
  writeln(UTF8ToConsole(BreakString(Format(
    lisOverrideTheDefaultCompilerEGPpc386Ppcx64PpcppcEtcD, [space]),
                      75, 22)));
  writeln('');
  writeln(LanguageOpt);
  writeln(UTF8ToConsole(BreakString(space+lisOverrideLanguage,75, 22)));
end;

procedure TLazBuildApplication.Error(ErrorCode: Byte; const ErrorMsg: string);
begin
  writeln('ERROR: ',LineBreaksToSystemLineBreaks(ErrorMsg));
  Halt(ErrorCode);
end;

function TLazBuildApplication.OnRunExternalTool(Tool: TIDEExternalToolOptions
  ): TModalResult;
begin
  Result:=EnvironmentOptions.ExternalTools.Run(Tool,GlobalMacroList);
end;

begin
  // free LCL application
  FreeAndNil(Forms.Application);
  // start our own application
  Application:=TLazBuildApplication.Create(nil);
  Application.Run;
  Application.Free;
end.

