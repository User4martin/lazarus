{
 /***************************************************************************
                            pkgmanager.pas
                            --------------


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
    TPkgManager is the class for the global PkgBoss variable, which controls
    the whole package system in the IDE.
}
unit PkgManager;

{$mode objfpc}{$H+}

interface

{$I ide.inc}

uses
  {$IFDEF IDE_MEM_CHECK}
  MemCheck,
  {$ENDIF}
  // FCL, LCL
  TypInfo, Classes, SysUtils, LCLProc, Forms, Controls, Dialogs, Menus,
  StringHashList, Translations,
  // codetools
  CodeToolManager, CodeCache, NonPascalCodeTools, BasicCodeTools,
  DefineTemplates, FileProcs, AVL_Tree, Laz_XMLCfg,
  // IDE Interface
  SrcEditorIntf, IDEExternToolIntf, NewItemIntf, ProjectIntf, PackageIntf, MenuIntf,
  PropEdits, IDEMsgIntf, MacroIntf, LazIDEIntf,
  // IDE
  LazConf, LazarusIDEStrConsts, IDEProcs, ObjectLists, DialogProcs, IDECommands,
  EnvironmentOpts, MiscOptions, InputHistory, ProjectDefs, Project,
  ComponentReg, UComponentManMain, PackageEditor, AddToPackageDlg, PackageDefs,
  PackageLinks, PackageSystem, OpenInstalledPkgDlg, PkgGraphExplorer,
  BrokenDependenciesDlg, CompilerOptions, ExtToolEditDlg, IDETranslations,
  TransferMacros, MsgView, BuildLazDialog, NewDialog, IDEDialogs, TodoList,
  ProjectInspector, ComponentPalette, SourceEditor, AddFileToAPackageDlg,
  LazarusPackageIntf, PublishProjectDlg, PkgLinksDlg, InstallPkgSetDlg,
  // bosses
  BaseBuildManager, BasePkgManager,
  MainBar, MainIntf, MainBase;

type
  { TPkgManager }

  TPkgManager = class(TBasePkgManager)
    // events - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // package editor
    function OnPackageEditorCompilePackage(Sender: TObject;
                          APackage: TLazPackage;
                          CompileClean, CompileRequired: boolean): TModalResult;
    function OnPackageEditorCreateMakefile(Sender: TObject;
                                           APackage: TLazPackage): TModalResult;
    function OnPackageEditorCreateFile(Sender: TObject;
                                       Params: TAddToPkgResult): TModalResult;
    function OnPackageEditorDeleteAmbiguousFiles(Sender: TObject;
      APackage: TLazPackage; const Filename: string): TModalResult;
    function OnPackageEditorAddToProject(Sender: TObject; APackage: TLazPackage;
                                     OnlyTestIfPossible: boolean): TModalResult;
    function OnPackageEditorInstallPackage(Sender: TObject;
                                           APackage: TLazPackage): TModalResult;
    function OnPackageEditorPublishPackage(Sender: TObject;
      APackage: TLazPackage): TModalResult;
    function OnPackageEditorRevertPackage(Sender: TObject; APackage: TLazPackage
      ): TModalResult;
    function OnPackageEditorUninstallPackage(Sender: TObject;
                                           APackage: TLazPackage): TModalResult;
    function OnPackageEditorOpenPkgFile(Sender: TObject; PkgFile: TPkgFile
                                        ): TModalResult;
    function OnPackageEditorOpenPackage(Sender: TObject; APackage: TLazPackage
                                        ): TModalResult;
    function OnPackageEditorSavePackage(Sender: TObject; APackage: TLazPackage;
                                        SaveAs: boolean): TModalResult;
    function OnPackageEditorViewPkgSource(Sender: TObject;
                                          APackage: TLazPackage): TModalResult;
    function OnPackageEditorViewPkgToDos(Sender: TObject;
                                         APackage: TLazPackage): TModalResult;
    procedure OnPackageEditorFreeEditor(APackage: TLazPackage);
    procedure OnPackageEditorGetUnitRegisterInfo(Sender: TObject;
                              const AFilename: string; var TheUnitName: string;
                              var HasRegisterProc: boolean);
    procedure OnPackageEditorImExportCompilerOptions(Sender: TObject);
    // package graph
    function PackageGraphExplorerOpenPackage(Sender: TObject;
                                           APackage: TLazPackage): TModalResult;
    function PackageGraphExplorerOpenProject(Sender: TObject;
                                             AProject: TProject): TModalResult;
    function PackageGraphExplorerUninstallPackage(Sender: TObject;
                                           APackage: TLazPackage): TModalResult;
    procedure PackageGraphAddPackage(Pkg: TLazPackage);
    procedure PackageGraphBeginUpdate(Sender: TObject);
    procedure PackageGraphChangePackageName(APackage: TLazPackage;
                                            const OldName: string);
    procedure PackageGraphDeletePackage(APackage: TLazPackage);
    procedure PackageGraphDependencyModified(ADependency: TPkgDependency);
    procedure PackageGraphEndUpdate(Sender: TObject; GraphChanged: boolean);
    procedure PackageGraphFindFPCUnit(const UnitName, Directory: string;
                                      var Filename: string);

    // menu
    procedure MainIDEitmPkgOpenPackageFileClick(Sender: TObject);
    procedure MainIDEitmPkgPkgGraphClick(Sender: TObject);
    procedure MainIDEitmPkgEditInstallPkgsClick(Sender: TObject);
    procedure MainIDEitmPkgAddCurUnitToPkgClick(Sender: TObject);
    procedure MainIDEitmPkgOpenPackageOfCurUnitClicked(Sender: TObject);
    procedure MainIDEitmConfigCustomCompsClicked(Sender: TObject);
    procedure MainIDEitmOpenRecentPackageClicked(Sender: TObject);
    procedure MainIDEitmPkgOpenPackageClicked(Sender: TObject);
    procedure MainIDEitmPkgNewPackageClick(Sender: TObject);
    procedure MainIDEViewPackageLinksClicked(Sender: TObject);

    // component palette
    procedure IDEComponentPaletteEndUpdate(Sender: TObject;
                                           PaletteChanged: boolean);
    procedure IDEComponentPaletteOpenPackage(Sender: TObject);
    procedure IDEComponentPaletteOpenUnit(Sender: TObject);

    // LCL
    procedure OnApplicationIdle(Sender: TObject; var Done: Boolean);

    // package links
    function PkgLinksDependencyOwnerGetPkgFilename(PkgLinks: TPackageLinks;
      Dependency: TPkgDependency): boolean;

    // misc
    procedure GetDependencyOwnerDescription(Dependency: TPkgDependency;
                                            out Description: string);
    procedure GetDependencyOwnerDirectory(Dependency: TPkgDependency;
                                          out Directory: string);
    procedure GetWritablePkgOutputDirectory(APackage: TLazPackage;
                                            var AnOutDirectory: string);
    procedure OnCheckInstallPackageList(PkgIDList: TFPList; var Ok: boolean);
    function LoadDependencyList(FirstDependency: TPkgDependency): TModalResult;
    procedure OnOpenPackageForCurrentSrcEditFile(Sender: TObject);
  private
    // helper functions
    function DoShowSavePackageAsDialog(APackage: TLazPackage): TModalResult;
    function DoWriteMakefile(APackage: TLazPackage): TModalResult;
    function CheckPackageGraphForCompilation(APackage: TLazPackage;
                                 FirstDependency: TPkgDependency;
                                 const Directory: string): TModalResult;
    function DoGetUnitRegisterInfo(const AFilename: string;
                          var TheUnitName: string; var HasRegisterProc: boolean;
                          IgnoreErrors: boolean): TModalResult;
    procedure SaveAutoInstallDependencies(SetWithStaticPcksFlagForIDE: boolean);
    procedure LoadStaticCustomPackages;
    function LoadInstalledPackage(const PackageName: string;
                    AddToAutoInstall: boolean; var Quiet: boolean): TLazPackage;
    procedure LoadAutoInstallPackages;
    procedure AddUnitToProjectMainUsesSection(AProject: TProject;
                                    const AnUnitName, AnUnitInFilename: string);
                                    
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;

    // initialization and menu
    procedure ConnectMainBarEvents; override;
    procedure ConnectSourceNotebookEvents; override;
    procedure SetupMainBarShortCuts; override;
    procedure SetRecentPackagesMenu; override;
    procedure AddFileToRecentPackages(const Filename: string);
    procedure SaveSettings; override;
    procedure UpdateVisibleComponentPalette; override;
    procedure ProcessCommand(Command: word; var Handled: boolean); override;
    procedure OnSourceEditorPopupMenu(const AddMenuItemProc: TAddMenuItemProc); override;
    procedure TranslateResourceStrings; override;

    // files
    function GetDefaultSaveDirectoryForFile(const Filename: string): string; override;
    function GetPublishPackageDir(APackage: TLazPackage): string;
    function OnRenameFile(const OldFilename, NewFilename: string;
                          IsPartOfProject: boolean): TModalResult; override;
    function FindIncludeFileInProjectDependencies(Project1: TProject;
                          const Filename: string): string; override;
    function AddUnitDependenciesForComponentClasses(const UnitFilename: string;
                         ComponentClassnames: TStrings;
                         Quiet: boolean = false): TModalResult; override;
    function GetMissingDependenciesForUnit(const UnitFilename: string;
                         ComponentClassnames: TStrings;
                         var List: TObjectArray): TModalResult;
    function GetOwnersOfUnit(const UnitFilename: string): TFPList; override;
    procedure ExtendOwnerListWithUsedByOwners(OwnerList: TFPList); override;
    function GetSourceFilesOfOwners(OwnerList: TFPList): TStrings; override;
    function GetPossibleOwnersOfUnit(const UnitFilename: string;
                                     Flags: TPkgIntfOwnerSearchFlags): TFPList; override;
    function GetPackageOfCurrentSourceEditor: TPkgFile;
    function AddDependencyToOwners(OwnerList: TFPList; APackage: TLazPackage;
                   OnlyTestIfPossible: boolean = false): TModalResult; override;
    function DoOpenPkgFile(PkgFile: TPkgFile): TModalResult;
    function FindVirtualUnitSource(PkgFile: TPkgFile): string;
    function SearchFile(const AFilename: string;
                        SearchFlags: TSearchIDEFileFlags;
                        InObject: TObject): TPkgFile; override;
    function SearchUnitInDesigntimePackages(const AnUnitName: string;
                        InObject: TObject): TPkgFile; override;
    function AddDependencyToUnitOwners(const OwnedFilename,
                              RequiredUnitname: string): TModalResult; override;
    procedure GetPackagesChangedOnDisk(var ListOfPackages: TFPList); override;
    function RevertPackages(APackageList: TFPList): TModalResult; override;

    // package graph
    function AddPackageToGraph(APackage: TLazPackage; Replace: boolean): TModalResult;
    function DoShowPackageGraph: TModalResult;
    procedure DoShowPackageGraphPathList(PathList: TFPList); override;
    function ShowBrokenDependenciesReport(Dependencies: TFPList): TModalResult;
    procedure RebuildDefineTemplates; override;
    procedure LazarusSrcDirChanged; override;

    // project
    function OpenProjectDependencies(AProject: TProject;
                                ReportMissing: boolean): TModalResult; override;
    function CheckProjectHasInstalledPackages(AProject: TProject; 
                                  Interactive: boolean): TModalResult; override;
    function CanOpenDesignerForm(AnUnitInfo: TUnitInfo; 
                                 Interactive: boolean): TModalResult; override;
    procedure AddDefaultDependencies(AProject: TProject); override;
    function AddProjectDependency(AProject: TProject; APackage: TLazPackage;
                                  OnlyTestIfPossible: boolean = false): TModalResult; override;
    function AddProjectDependency(AProject: TProject;
                                  ADependency: TPkgDependency): TModalResult;
    procedure AddProjectRegCompDependency(AProject: TProject;
                          ARegisteredComponent: TRegisteredComponent); override;
    procedure AddProjectLCLDependency(AProject: TProject); override;
    function AddProjectDependencies(AProject: TProject; const Packages: string;
                                  OnlyTestIfPossible: boolean = false): TModalResult; override;
    function OnProjectInspectorOpen(Sender: TObject): boolean; override;
    function OnProjectInspectorAddDependency(Sender: TObject;
                           ADependency: TPkgDependency): TModalResult; override;
    function OnProjectInspectorRemoveDependency(Sender: TObject;
                           ADependency: TPkgDependency): TModalResult; override;
    function OnProjectInspectorReAddDependency(Sender: TObject;
                           ADependency: TPkgDependency): TModalResult; override;

    // package editors
    function DoNewPackage: TModalResult; override;
    function DoShowOpenInstalledPckDlg: TModalResult; override;
    function DoOpenPackage(APackage: TLazPackage; Flags: TPkgOpenFlags;
                           ShowAbort: boolean): TModalResult; override;
    function DoOpenPackageWithName(const APackageName: string;
                         Flags: TPkgOpenFlags; ShowAbort: boolean): TModalResult; override;
    function DoOpenPackageFile(AFilename: string;
                         Flags: TPkgOpenFlags;
                         ShowAbort: boolean): TModalResult; override;
    function DoSavePackage(APackage: TLazPackage;
                           Flags: TPkgSaveFlags): TModalResult; override;
    function DoSaveAllPackages(Flags: TPkgSaveFlags): TModalResult; override;
    function DoClosePackageEditor(APackage: TLazPackage): TModalResult; override;
    function DoCloseAllPackageEditors: TModalResult; override;
    function DoAddActiveUnitToAPackage: TModalResult;
    function WarnAboutMissingPackageFiles(APackage: TLazPackage): TModalResult;

    // package compilation
    function DoCompileProjectDependencies(AProject: TProject;
                               Flags: TPkgCompileFlags): TModalResult; override;
    function DoCompilePackage(APackage: TLazPackage; Flags: TPkgCompileFlags;
                              Globals: TGlobalCompilerOptions = nil): TModalResult; override;
    function DoCreatePackageMakefile(APackage: TLazPackage): TModalResult;

    // package installation
    procedure LoadInstalledPackages; override;
    procedure UnloadInstalledPackages;
    function ShowConfigureCustomComponents: TModalResult; override;
    function DoInstallPackage(APackage: TLazPackage): TModalResult;
    function DoUninstallPackage(APackage: TLazPackage;
                                Flags: TPkgUninstallFlags): TModalResult;
    procedure DoTranslatePackage(APackage: TLazPackage);
    function DoOpenPackageSource(APackage: TLazPackage): TModalResult;
    function DoViewPackageToDos(APackage: TLazPackage): TModalResult;
    function DoCompileAutoInstallPackages(Flags: TPkgCompileFlags
                                          ): TModalResult; override;
    function DoSaveAutoInstallConfig: TModalResult; override;
    function DoGetIDEInstallPackageOptions(
                           var InheritedOptionStrings: TInheritedCompOptsStrings
                           ): string; override;
    function DoPublishPackage(APackage: TLazPackage; Flags: TPkgSaveFlags;
                              ShowDialog: boolean): TModalResult;
                              
    // components
    function GetUsableComponentUnits(CurRoot: TPersistent): TFPList; override; // list of TUnitInfo
    procedure IterateComponentNames(CurRoot: TPersistent; TypeData: PTypeData;
                                    Proc: TGetStringProc); override;
    function FindUsableComponent(CurRoot: TPersistent;
                        const ComponentPath: string): TComponent; override;
    function FindReferencedRootComponent(CurRoot: TPersistent; 
         const ComponentName: string): TComponent; override;
  end;


  { TLazPackageDescriptors }

  TLazPackageDescriptors = class(TPackageDescriptors)
  private
    fDestroying: boolean;
    fItems: TFPList; // list of TProjectDescriptor
  protected
    function GetItems(Index: integer): TPackageDescriptor; override;
  public
    constructor Create;
    destructor Destroy; override;
    function Count: integer; override;
    function GetUniqueName(const Name: string): string; override;
    function IndexOf(const Name: string): integer; override;
    function FindByName(const Name: string): TPackageDescriptor; override;
    procedure RegisterDescriptor(Descriptor: TPackageDescriptor); override;
    procedure UnregisterDescriptor(Descriptor: TPackageDescriptor); override;
    procedure AddDefaultPackageDescriptors;
  public
    property Items[Index: integer]: TPackageDescriptor read GetItems; default;
  end;
  
  
  { TPackageDescriptorStd }
  
  TPackageDescriptorStd = class(TPackageDescriptor)
  public
    constructor Create; override;
    function GetLocalizedName: string; override;
    function GetLocalizedDescription: string; override;
  end;

var
  LazPackageDescriptors: TLazPackageDescriptors;

implementation

{ TPkgManager }

procedure TPkgManager.MainIDEitmPkgOpenPackageFileClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  AFilename: string;
  I: Integer;
  OpenFlags: TPkgOpenFlags;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    InputHistories.ApplyFileDialogSettings(OpenDialog);
    OpenDialog.Title:=lisOpenPackageFile;
    OpenDialog.Options:=OpenDialog.Options+[ofAllowMultiSelect];
    OpenDialog.Filter:=lisLazarusPackage+' (*.lpk)|*.lpk'
                     +'|'+dlgAllFiles+' ('+FileMask+')|'+FileMask;
    if OpenDialog.Execute and (OpenDialog.Files.Count>0) then begin
      OpenFlags:=[pofAddToRecent];
      For I := 0 to OpenDialog.Files.Count-1 do
        Begin
          AFilename:=CleanAndExpandFilename(OpenDialog.Files.Strings[i]);
          if i<OpenDialog.Files.Count-1 then
            Include(OpenFlags,pofMultiOpen)
          else
            Exclude(OpenFlags,pofMultiOpen);
          if DoOpenPackageFile(AFilename,OpenFlags,true)=mrAbort then begin
            break;
          end;
        end;
    end;
    InputHistories.StoreFileDialogSettings(OpenDialog);
  finally
    OpenDialog.Free;
  end;
end;

procedure TPkgManager.MainIDEitmPkgPkgGraphClick(Sender: TObject);
begin
  DoShowPackageGraph;
end;

procedure TPkgManager.MainIDEitmPkgEditInstallPkgsClick(Sender: TObject);

  function CreateChangeReport(OldDependencyList,
    NewDependencyList: TPkgDependency): string;
  var
    CurDependency: TPkgDependency;
    OldDependency: TPkgDependency;
    NewDependency: TPkgDependency;
  begin
    Result:='';

    // list all packages, that will be installed
    CurDependency:=NewDependencyList;
    while CurDependency<>nil do begin
      Result:=Result+CurDependency.AsString;
      OldDependency:=FindDependencyByNameInList(OldDependencyList,pdlRequires,
                                                CurDependency.PackageName);
      if OldDependency<>nil then begin
        // stay installed
        if CurDependency.AsString<>OldDependency.AsString then
          Result:=Result+' ('+lisOld+': '+OldDependency.AsString+')';
      end else begin
        // newly installed
        Result:=Result+' ('+lisNew+')';
      end;
      Result:=Result+#13;
      CurDependency:=CurDependency.NextRequiresDependency;
    end;

    // list all packages, that will be removed
    CurDependency:=OldDependencyList;
    while CurDependency<>nil do begin
      NewDependency:=FindDependencyByNameInList(NewDependencyList,pdlRequires,
                                                CurDependency.PackageName);
      if NewDependency=nil then begin
        // this package will be removed
        Result:=Result+CurDependency.AsString+' ('+lisRemove+')'#13;
      end;
      CurDependency:=CurDependency.NextRequiresDependency;
    end;
  end;

var
  RebuildIDE: Boolean;
  PkgIDList: TFPList;
  NewFirstAutoInstallDependency: TPkgDependency;
  BuildIDEFlags: TBuildLazarusFlags;
  ok: boolean;
  Report: String;
  PkgList: TFPList;
  RequiredPackage: TLazPackage;
  i: Integer;
  CurDependency: TPkgDependency;
begin
  RebuildIDE:=false;
  PkgIDList:=nil;
  NewFirstAutoInstallDependency:=nil;
  PkgList:=nil;
  try
    if ShowEditInstallPkgsDialog(PackageGraph.FirstAutoInstallDependency,
      @OnCheckInstallPackageList,PkgIDList,RebuildIDE)<>mrOk
    then exit;
    
    OnCheckInstallPackageList(PkgIDList,ok);
    if not ok then exit;

    // create new auto install dependency PkgIDList
    ListPkgIDToDependencyList(PkgIDList,NewFirstAutoInstallDependency,
      pdlRequires,Self,true);

    PackageGraph.SortDependencyListTopologically(NewFirstAutoInstallDependency,
                                                 false);

    // tell the user, which packages will stay, which will be removed and
    // which will be newly installed
    Report:=CreateChangeReport(PackageGraph.FirstAutoInstallDependency,
                               NewFirstAutoInstallDependency);
    if IDEMessageDialog(lisConfirmNewPackageSetForTheIDE,
      Format(lisThisWillHappenContinue, [#13#13, Report, #13]), mtConfirmation,
        [mbYes, mbNo])<>mrYes then exit;

    // try to commit changes -> replace install list
    PackageGraph.BeginUpdate(true);
    try
      // get all required packages
      //debugln('TPkgManager.MainIDEitmPkgEditInstallPkgsClick GetAllRequiredPackages for ',DependencyListAsString(NewFirstAutoInstallDependency,pdlRequires));
      if LoadDependencyList(NewFirstAutoInstallDependency)<>mrOk then exit;
      PackageGraph.GetAllRequiredPackages(NewFirstAutoInstallDependency,PkgList);
      
      // mark packages for installation
      //debugln('TPkgManager.MainIDEitmPkgEditInstallPkgsClick mark packages for installation');
      for i:=0 to PkgList.Count-1 do begin
        RequiredPackage:=TLazPackage(PkgList[i]);
        if RequiredPackage.AutoInstall=pitNope then begin
          RequiredPackage.AutoInstall:=pitStatic;
        end;
      end;

      // mark packages for uninstall
      //debugln('TPkgManager.MainIDEitmPkgEditInstallPkgsClick mark packages for uninstall');
      CurDependency:=PackageGraph.FirstAutoInstallDependency;
      while CurDependency<>nil do begin
        if (CurDependency.RequiredPackage<>nil)
        and (not CurDependency.RequiredPackage.AutoCreated) then
          CurDependency.RequiredPackage.AutoInstall:=pitNope;
        CurDependency:=CurDependency.NextRequiresDependency;
      end;

      // replace install list
      //debugln('TPkgManager.MainIDEitmPkgEditInstallPkgsClick replace install list');
      FreeDependencyList(PackageGraph.FirstAutoInstallDependency,pdlRequires);
      PackageGraph.FirstAutoInstallDependency:=NewFirstAutoInstallDependency;
      NewFirstAutoInstallDependency:=nil;
    finally
      PackageGraph.EndUpdate;
    end;

    // save package list
    //debugln('TPkgManager.MainIDEitmPkgEditInstallPkgsClick save package list');
    PackageGraph.SortAutoInstallDependencies;
    SaveAutoInstallDependencies(true);

    // save IDE build configs, so user can build IDE on command line
    BuildIDEFlags:=[blfWithStaticPackages,blfDontClean,blfOnlyIDE,
                    blfWithoutCompilingIDE];
    if MainIDE.DoSaveBuildIDEConfigs(BuildIDEFlags)<>mrOk then exit;

    if RebuildIDE then begin
      // rebuild Lazarus
      if MainIDE.DoBuildLazarus(BuildIDEFlags)<>mrOk then exit;
    end;

  finally
    if PkgIDList<>nil then FreeListObjects(PkgIDList,true);
    FreeDependencyList(NewFirstAutoInstallDependency,pdlRequires);
    PkgList.Free;
  end;
end;

procedure TPkgManager.IDEComponentPaletteEndUpdate(Sender: TObject;
  PaletteChanged: boolean);
begin
  UpdateVisibleComponentPalette;
end;

procedure TPkgManager.IDEComponentPaletteOpenPackage(Sender: TObject);
begin
  if (Sender=nil) or (not (Sender is TLazPackage)) then exit;
  DoOpenPackage(TLazPackage(Sender),[],false);
end;

procedure TPkgManager.IDEComponentPaletteOpenUnit(Sender: TObject);
var
  PkgComponent: TPkgComponent;
  PkgFile: TPkgFile;
  Filename: String;
begin
  if (Sender=nil) then exit;
  if (Sender is TPkgFile) then
    DoOpenPkgFile(TPkgFile(Sender))
  else if (Sender is TPkgComponent) then begin
    PkgComponent:=TPkgComponent(Sender);
    PkgFile:=PkgComponent.PkgFile;
    if PkgFile=nil then exit;
    Filename:='';
    if PkgFile.FileType=pftVirtualUnit then
      Filename:=FindVirtualUnitSource(PkgFile);
    if Filename='' then
      Filename:=PkgFile.Filename;
    MainIDE.DoOpenFileAndJumpToIdentifier(
      Filename,PkgComponent.ComponentClass.ClassName,
      -1, // open page somewhere
      [ofOnlyIfExists,ofAddToRecent,ofRegularFile,ofConvertMacros]);
  end;
end;

procedure TPkgManager.GetDependencyOwnerDescription(
  Dependency: TPkgDependency; out Description: string);
begin
  GetDescriptionOfDependencyOwner(Dependency,Description);
end;

procedure TPkgManager.GetDependencyOwnerDirectory(Dependency: TPkgDependency;
  out Directory: string);
begin
  GetDirectoryOfDependencyOwner(Dependency,Directory);
end;

procedure TPkgManager.GetWritablePkgOutputDirectory(APackage: TLazPackage;
  var AnOutDirectory: string);
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
  debugln('TPkgManager.GetWritablePkgOutputDirectory APackage=',APackage.IDAsString,' AnOutDirectory="',AnOutDirectory,'"');
end;

procedure TPkgManager.OnCheckInstallPackageList(PkgIDList: TFPList;
  var Ok: boolean);
var
  NewFirstAutoInstallDependency: TPkgDependency;
  PkgList: TFPList;
  i: Integer;
  APackage: TLazPackage;
  CurResult: TModalResult;
begin
  Ok:=false;
  PkgList:=nil;
  try
    // create new auto install dependency PkgIDList
    ListPkgIDToDependencyList(PkgIDList,NewFirstAutoInstallDependency,
                              pdlRequires,Self,true);

    // get all required packages
    if LoadDependencyList(NewFirstAutoInstallDependency)<>mrOk then exit;
    PackageGraph.GetAllRequiredPackages(NewFirstAutoInstallDependency,PkgList);

    // check if any package is a runtime package, that is not needed
    for i:=0 to PkgList.Count-1 do begin
      APackage:=TLazPackage(PkgList[i]);
      if (APackage.PackageType=lptRunTime)
      and (APackage.FirstUsedByDependency=nil) then begin
        // this is a runtime only package, not needed by any other package
        CurResult:=IDEQuestionDialog(lisPkgMangPackageIsNoDesigntimePackage,
          Format(lisPkgMangThePackageIsARuntimeOnlyPackageRuntimeOnlyPackages, [
            APackage.IDAsString, #13]),
          mtWarning, [mrIgnore, mrYesToAll, lisIgnoreAll, mrCancel]);
        case CurResult of
        mrIgnore: ;
        mrYesToAll: break;
        else exit;
        end;
      end;
    end;

    // try save all modified packages
    for i:=0 to PkgList.Count-1 do begin
      APackage:=TLazPackage(PkgList[i]);
      if (not APackage.AutoCreated)
      and (APackage.IsVirtual or APackage.Modified) then begin
        if DoSavePackage(APackage,[])<>mrOk then exit;
      end;
    end;

    Ok:=true;
  finally
    FreeDependencyList(NewFirstAutoInstallDependency,pdlRequires);
    PkgList.Free;
  end;
end;

function TPkgManager.LoadDependencyList(FirstDependency: TPkgDependency
  ): TModalResult;
var
  CurDependency: TPkgDependency;
  OpenResult: TLoadPackageResult;
begin
  Result:=mrCancel;
  // load all packages
  CurDependency:=FirstDependency;
  while CurDependency<>nil do begin
    OpenResult:=PackageGraph.OpenDependency(CurDependency,false);
    if OpenResult<>lprSuccess then begin
      IDEMessageDialog(lisCCOErrorCaption,
        Format(lisUnableToLoadPackage, ['"', CurDependency.AsString, '"']),
        mtError,[mbCancel]);
      exit;
    end;
    CurDependency:=CurDependency.NextRequiresDependency;
  end;
  Result:=mrOk;
end;

procedure TPkgManager.OnOpenPackageForCurrentSrcEditFile(Sender: TObject);
var
  PkgFile: TPkgFile;
begin
  PkgFile:=GetPackageOfCurrentSourceEditor;
  if PkgFile<>nil then
    DoOpenPackage(PkgFile.LazPackage,[],false);
end;

procedure TPkgManager.MainIDEitmPkgAddCurUnitToPkgClick(Sender: TObject);
begin
  DoAddActiveUnitToAPackage;
end;

procedure TPkgManager.MainIDEitmPkgOpenPackageOfCurUnitClicked(Sender: TObject);
var
  ActiveSourceEditor: TSourceEditorInterface;
  ActiveUnitInfo: TUnitInfo;
  PkgFile: TPkgFile;
  Filename: String;
begin
  MainIDE.GetCurrentUnitInfo(ActiveSourceEditor,ActiveUnitInfo);
  if ActiveSourceEditor=nil then exit;

  Filename:=ActiveUnitInfo.Filename;

  PkgFile:=PackageGraph.FindFileInAllPackages(Filename,true,
                                            not ActiveUnitInfo.IsPartOfProject);
  if PkgFile=nil then begin
    IDEMessageDialog(lisProjAddPackageNotFound,
      lisPkgThisFileIsNotInAnyLoadedPackage, mtInformation,
      [mbCancel]);
    exit;
  end;
  DoOpenPackageFile(PkgFile.LazPackage.Filename,[pofAddToRecent],false)
end;

function TPkgManager.OnPackageEditorCompilePackage(Sender: TObject;
  APackage: TLazPackage; CompileClean, CompileRequired: boolean): TModalResult;
var
  Flags: TPkgCompileFlags;
  Globals: TGlobalCompilerOptions;
begin
  Flags:=[];
  if CompileClean then Include(Flags,pcfCleanCompile);
  if CompileRequired then Include(Flags,pcfCompileDependenciesClean);
  if Project1<>nil then
    Globals:=Project1.CompilerOptions.Globals
  else
    Globals:=nil;
  //debugln('TPkgManager.OnPackageEditorCompilePackage OS=',Globals.TargetOS);
  Result:=DoCompilePackage(APackage,Flags,Globals);
end;

function TPkgManager.OnPackageEditorCreateMakefile(Sender: TObject;
  APackage: TLazPackage): TModalResult;
begin
  Result:=DoCreatePackageMakefile(APackage);
end;

function TPkgManager.OnPackageEditorCreateFile(Sender: TObject;
  Params: TAddToPkgResult): TModalResult;
var
  LE: String;
  UsesLine: String;
  NewSource: String;
begin
  Result:=mrCancel;
  // create sourcecode
  LE:=LineEnding;
  UsesLine:='Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs';
  if (System.Pos(Params.UsedUnitname,UsesLine)<1)
  and (Params.UsedUnitname<>'') then
    UsesLine:=UsesLine+', '+Params.UsedUnitname;
  NewSource:=
     'unit '+Params.UnitName+';'+LE
    +LE
    +'{$mode objfpc}{$H+}'+LE
    +LE
    +'interface'+LE
    +LE
    +'uses'+LE
    +'  '+UsesLine+';'+LE
    +LE
    +'type'+LE
    +'  '+Params.NewClassName+' = class('+Params.AncestorType+')'+LE
    +'  private'+LE
    +'    { Private declarations }'+LE
    +'  protected'+LE
    +'    { Protected declarations }'+LE
    +'  public'+LE
    +'    { Public declarations }'+LE
    +'  published'+LE
    +'    { Published declarations }'+LE
    +'  end;'+LE
    +LE
    +'procedure Register;'+LE
    +LE
    +'implementation'+LE
    +LE
    +'procedure Register;'+LE
    +'begin'+LE
    +'  RegisterComponents('''+Params.PageName+''',['+Params.NewClassName+']);'+LE
    +'end;'+LE
    +LE
    +'end.'+LE;

  Result:=MainIDE.DoNewEditorFile(FileDescriptorUnit,
     Params.UnitFilename,NewSource,
     [nfOpenInEditor,nfIsNotPartOfProject,nfSave,nfAddToRecent]);
end;

function TPkgManager.OnPackageEditorDeleteAmbiguousFiles(Sender: TObject;
  APackage: TLazPackage; const Filename: string): TModalResult;
begin
  Result:=BuildBoss.DeleteAmbiguousFiles(Filename);
end;

function TPkgManager.OnPackageEditorAddToProject(Sender: TObject;
  APackage: TLazPackage; OnlyTestIfPossible: boolean): TModalResult;
begin
  Result:=AddProjectDependency(Project1,APackage,OnlyTestIfPossible);
end;

function TPkgManager.OnPackageEditorInstallPackage(Sender: TObject;
  APackage: TLazPackage): TModalResult;
begin
  Result:=DoInstallPackage(APackage);
end;

function TPkgManager.OnPackageEditorPublishPackage(Sender: TObject;
  APackage: TLazPackage): TModalResult;
begin
  Result:=DoPublishPackage(APackage,[],true);
end;

function TPkgManager.OnPackageEditorRevertPackage(Sender: TObject;
  APackage: TLazPackage): TModalResult;
begin
  if APackage.AutoCreated or (not FilenameIsAbsolute(APackage.Filename))
  or (not FileExistsUTF8(APackage.Filename)) then
    exit(mrCancel);
  Result:=DoOpenPackageFile(APackage.Filename,[pofRevert],false);
end;

function TPkgManager.OnPackageEditorUninstallPackage(Sender: TObject;
  APackage: TLazPackage): TModalResult;
begin
  Result:=DoUninstallPackage(APackage,[]);
end;

function TPkgManager.OnPackageEditorOpenPkgFile(Sender: TObject;
  PkgFile: TPkgFile): TModalResult;
begin
  Result:=DoOpenPkgFile(PkgFile);
end;

procedure TPkgManager.OnPackageEditorFreeEditor(APackage: TLazPackage);
begin
  APackage.Editor:=nil;
  PackageGraph.ClosePackage(APackage);
end;

procedure TPkgManager.OnPackageEditorGetUnitRegisterInfo(Sender: TObject;
  const AFilename: string; var TheUnitName: string; var HasRegisterProc: boolean
  );
begin
  DoGetUnitRegisterInfo(AFilename,TheUnitName,HasRegisterProc,true);
end;

procedure TPkgManager.OnPackageEditorImExportCompilerOptions(Sender: TObject);
begin
  MainIDE.DoImExportCompilerOptions(Sender);
end;

function TPkgManager.OnPackageEditorOpenPackage(Sender: TObject;
  APackage: TLazPackage): TModalResult;
begin
  Result:=DoOpenPackage(APackage,[],false);
end;

function TPkgManager.OnPackageEditorSavePackage(Sender: TObject;
  APackage: TLazPackage; SaveAs: boolean): TModalResult;
begin
  if SaveAs then
    Result:=DoSavePackage(APackage,[psfSaveAs])
  else
    Result:=DoSavePackage(APackage,[]);
end;

function TPkgManager.OnPackageEditorViewPkgSource(Sender: TObject;
  APackage: TLazPackage): TModalResult;
begin
  Result:=DoOpenPackageSource(APackage);
end;

function TPkgManager.OnPackageEditorViewPkgToDos(Sender: TObject;
  APackage: TLazPackage): TModalResult;
begin
  Result:=DoViewPackageToDos(APackage);
end;

procedure TPkgManager.PackageGraphBeginUpdate(Sender: TObject);
begin
  if PackageGraphExplorer<>nil then PackageGraphExplorer.BeginUpdate;
end;

procedure TPkgManager.PackageGraphChangePackageName(APackage: TLazPackage;
  const OldName: string);
begin
  if PackageGraphExplorer<>nil then
    PackageGraphExplorer.UpdatePackageName(APackage,OldName);
end;

procedure TPkgManager.PackageGraphDeletePackage(APackage: TLazPackage);
begin
  if APackage.Editor<>nil then begin
    APackage.Editor.Hide;
    APackage.Editor.Free;
  end;
end;

procedure TPkgManager.PackageGraphDependencyModified(ADependency: TPkgDependency
  );
var
  DepOwner: TObject;
begin
  DepOwner:=ADependency.Owner;
  if DepOwner is TLazPackage then
    TLazPackage(DepOwner).Modified:=true
  else if DepOwner is TProject then
    TProject(DepOwner).Modified:=true;
end;

function TPkgManager.PackageGraphExplorerOpenPackage(Sender: TObject;
  APackage: TLazPackage): TModalResult;
begin
  Result:=DoOpenPackage(APackage,[pofAddToRecent],false);
end;

function TPkgManager.PackageGraphExplorerOpenProject(Sender: TObject;
  AProject: TProject): TModalResult;
begin
  if AProject<>Project1 then exit(mrCancel);
  Result:=MainIDE.DoShowProjectInspector;
end;

procedure TPkgManager.PackageGraphAddPackage(Pkg: TLazPackage);
begin
  if FileExistsUTF8(Pkg.FileName) then PkgLinks.AddUserLink(Pkg);
  if PackageGraphExplorer<>nil then
    PackageGraphExplorer.UpdatePackageAdded(Pkg);
end;

procedure TPkgManager.PackageGraphEndUpdate(Sender: TObject;
  GraphChanged: boolean);
begin
  if GraphChanged then IncreaseCompilerParseStamp;
  if PackageGraphExplorer<>nil then begin
    if GraphChanged then PackageGraphExplorer.UpdateAll;
    PackageGraphExplorer.EndUpdate;
  end;
  if GraphChanged then begin
    if PackageEditors<>nil then
      PackageEditors.UpdateAllEditors;
    if ProjInspector<>nil then
      ProjInspector.UpdateItems;
  end;
end;

procedure TPkgManager.PackageGraphFindFPCUnit(const UnitName,
  Directory: string; var Filename: string);
begin
  if (Directory<>'') and not FilenameIsAbsolute(Directory) then
    RaiseGDBException(Directory);
  //DebugLn('TPkgManager.PackageGraphFindFPCUnit "',Directory,'"');
  Filename:=CodeToolBoss.DirectoryCachePool.FindUnitInUnitLinks(Directory,
                                                                UnitName);
end;

function TPkgManager.PackageGraphExplorerUninstallPackage(Sender: TObject;
  APackage: TLazPackage): TModalResult;
begin
  Result:=DoUninstallPackage(APackage,[]);
end;

function TPkgManager.PkgLinksDependencyOwnerGetPkgFilename(
  PkgLinks: TPackageLinks; Dependency: TPkgDependency): boolean;
begin
  Result:=false;
  // TODO search in Project/Package history list of dependencies
  
end;

procedure TPkgManager.MainIDEitmConfigCustomCompsClicked(Sender: TObject);
begin
  ShowConfigureCustomComponents;
end;

procedure TPkgManager.MainIDEitmPkgNewPackageClick(Sender: TObject);
begin
  DoNewPackage;
end;

procedure TPkgManager.MainIDEitmPkgOpenPackageClicked(Sender: TObject);
begin
  DoShowOpenInstalledPckDlg;
end;

procedure TPkgManager.MainIDEViewPackageLinksClicked(Sender: TObject);
begin
  ShowPackageLinks;
end;

procedure TPkgManager.MainIDEitmOpenRecentPackageClicked(Sender: TObject);

  procedure UpdateEnvironment;
  begin
    SetRecentPackagesMenu;
    MainIDE.SaveEnvironment;
  end;

var
  AFilename: string;
begin
  AFileName:=ExpandFileNameUTF8((Sender as TIDEMenuItem).Caption);
  if DoOpenPackageFile(AFilename,[pofAddToRecent],false)=mrOk then begin
    UpdateEnvironment;
  end else begin
    // open failed
    if not FileExistsUTF8(AFilename) then begin
      // file does not exist -> delete it from recent file list
      RemoveFromRecentList(AFilename,EnvironmentOptions.RecentPackageFiles);
      UpdateEnvironment;
    end;
  end;
end;

procedure TPkgManager.OnApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  if (Screen.ActiveCustomForm<>nil)
  and (fsModal in Screen.ActiveCustomForm.FormState) then exit;
  if PackageGraph = nil then Exit;
  PackageGraph.CloseUnneededPackages;
end;

function TPkgManager.DoShowSavePackageAsDialog(
  APackage: TLazPackage): TModalResult;
var
  OldPkgFilename: String;
  SaveDialog: TSaveDialog;
  NewFileName: String;
  NewPkgName: String;
  ConflictPkg: TLazPackage;
  PkgFile: TPkgFile;
  LowerFilename: String;
  BrokenDependencies: TFPList;
  RenameDependencies: Boolean;
  OldPkgName: String;
  
  procedure RenamePackageInProject;
  var
    AProject: TProject;
    OldUnitName: String;
    NewUnitName: String;
  begin
    AProject:=Project1;
    if (pfMainUnitHasUsesSectionForAllUnits in AProject.Flags)
    and (AProject.MainUnitInfo<>nil) then begin
      OldUnitName:=OldPkgName;
      NewUnitName:=APackage.Name;
      if (OldUnitName<>NewUnitName) then begin
        MainIDEInterface.SaveSourceEditorChangesToCodeCache(-1);
        if CodeToolBoss.RenameUsedUnit(
          AProject.MainUnitInfo.Source,OldUnitName,NewUnitName,'')
        then
          AProject.MainUnitInfo.Modified:=true;
      end;
    end;
  end;
  
begin
  OldPkgFilename:=APackage.Filename;
  OldPkgName:=APackage.Name;

  SaveDialog:=TSaveDialog.Create(nil);
  try
    InputHistories.ApplyFileDialogSettings(SaveDialog);
    SaveDialog.Title:=Format(lisPkgMangSavePackageLpk, [APackage.IDAsString]);
    if APackage.HasDirectory then
      SaveDialog.InitialDir:=APackage.Directory;

    // build a nice package filename suggestion
    NewFileName:=APackage.Name+'.lpk';
    SaveDialog.FileName:=NewFileName;

    repeat
      Result:=mrCancel;

      if not SaveDialog.Execute then begin
        // user cancels
        Result:=mrCancel;
        exit;
      end;
      NewFileName:=CleanAndExpandFilename(SaveDialog.Filename);
      NewPkgName:=ExtractFileNameOnly(NewFilename);
      
      // check file extension
      if ExtractFileExt(NewFilename)='' then begin
        // append extension
        NewFileName:=NewFileName+'.lpk';
      end else if ExtractFileExt(NewFilename)<>'.lpk' then begin
        Result:=IDEMessageDialog(lisPkgMangInvalidPackageFileExtension,
          lisPkgMangPackagesMustHaveTheExtensionLpk,
          mtInformation,[mbRetry,mbAbort]);
        if Result=mrAbort then exit;
        continue; // try again
      end;

      // check filename
      if (NewPkgName='') or (not IsValidIdent(NewPkgName)) then begin
        Result:=IDEMessageDialog(lisPkgMangInvalidPackageName,
          Format(lisPkgMangThePackageNameIsNotAValidPackageNamePleaseChooseAn, [
            '"', NewPkgName, '"', #13]),
          mtInformation,[mbRetry,mbAbort]);
        if Result=mrAbort then exit;
        continue; // try again
      end;

      // apply naming conventions
      
      if lowercase(NewPkgName) <> NewPkgName then
      begin
        LowerFilename:=ExtractFilePath(NewFilename)+lowercase(ExtractFileName(NewFilename));
        if EnvironmentOptions.CharcaseFileAction = ccfaAsk then
        begin
          if IDEMessageDialog(lisPkgMangRenameFileLowercase,
            Format(lisPkgMangShouldTheFileRenamedLowercaseTo, [#13, '"',
              LowerFilename, '"']),
            mtConfirmation,[mbYes,mbNo])=mrYes
          then
            NewFileName:=LowerFilename;
        end
        else
        begin
          if EnvironmentOptions.CharcaseFileAction = ccfaAutoRename then NewFileName:=LowerFilename;
        end;
      end;
      
      // check unit name conflict
      PkgFile:=APackage.FindUnit(NewPkgName);
      if PkgFile<>nil then begin
        Result:=IDEMessageDialog(lisNameConflict,
          lisThePackageAlreadyContainsAUnitWithThisName,
          mtWarning,[mbRetry,mbAbort]);
        if Result=mrAbort then exit;
        continue; // try again
      end;

      // check package name conflict
      ConflictPkg:=PackageGraph.FindAPackageWithName(NewPkgName,APackage);
      if ConflictPkg<>nil then begin
        Result:=IDEMessageDialog(lisPkgMangPackageNameAlreadyExists,
          Format(lisPkgMangThereIsAlreadyAnotherPackageWithTheName, ['"',
            NewPkgName, '"', #13, '"', ConflictPkg.IDAsString, '"', #13, '"',
            ConflictPkg.Filename, '"']),
          mtInformation,[mbRetry,mbAbort,mbIgnore]);
        if Result=mrAbort then exit;
        if Result<>mrIgnore then continue; // try again
      end;
      
      // check file name conflict with project
      if Project1.ProjectUnitWithFilename(NewFilename)<>nil then begin
        Result:=IDEMessageDialog(lisPkgMangFilenameIsUsedByProject,
          Format(lisPkgMangTheFileNameIsPartOfTheCurrentProject, ['"',
            NewFilename, '"', #13]),
          mtInformation,[mbRetry,mbAbort]);
        if Result=mrAbort then exit;
        continue; // try again
      end;
      
      // check file name conflicts with files in other packages
      PkgFile:=PackageGraph.FindFileInAllPackages(NewFilename,true,false);
      if PkgFile<>nil then begin
        Result:=IDEMessageDialog(lisPkgMangFilenameIsUsedByOtherPackage,
          Format(lisPkgMangTheFileNameIsUsedByThePackageInFile, ['"',
            NewFilename, '"', #13, '"', PkgFile.LazPackage.IDAsString, '"',
            #13, '"', PkgFile.LazPackage.Filename, '"']),
          mtWarning,[mbRetry,mbAbort]);
        if Result=mrAbort then exit;
        continue; // try again
      end;
      
      // check for broken dependencies
      BrokenDependencies:=PackageGraph.GetBrokenDependenciesWhenChangingPkgID(
        APackage,NewPkgName,APackage.Version);
      RenameDependencies:=false;
      try
        if BrokenDependencies.Count>0 then begin
          Result:=ShowBrokenDependencies(BrokenDependencies,
                                         DefaultBrokenDepButtons);
          if Result=mrAbort then exit;
          if Result=mrRetry then continue;
          if Result=mrYes then RenameDependencies:=true;
        end;
      finally
        BrokenDependencies.Free;
      end;
      
      // check existing file
      if (CompareFilenames(NewFileName,OldPkgFilename)<>0)
      and FileExistsUTF8(NewFileName) then begin
        Result:=IDEMessageDialog(lisPkgMangReplaceFile,
          Format(lisPkgMangReplaceExistingFile, ['"', NewFilename, '"']),
          mtConfirmation,[mbOk,mbCancel]);
        if Result<>mrOk then exit;
      end;
      
      // check if new file is read/writable
      Result:=CheckCreatingFile(NewFileName,true);
      if Result=mrAbort then exit;

    until Result<>mrRetry;
  finally
    InputHistories.StoreFileDialogSettings(SaveDialog);
    SaveDialog.Free;
  end;
  
  // set filename
  APackage.Filename:=NewFilename;
  
  // rename package
  PackageGraph.ChangePackageID(APackage,NewPkgName,APackage.Version,
                               RenameDependencies);
  SaveAutoInstallDependencies(false);
  RenamePackageInProject;

  // clean up old package file to reduce ambiguousities
  if FileExistsUTF8(OldPkgFilename)
  and (CompareFilenames(OldPkgFilename,NewFilename)<>0) then begin
    if IDEMessageDialog(lisPkgMangDeleteOldPackageFile,
      Format(lisPkgMangDeleteOldPackageFile2, ['"', OldPkgFilename, '"']),
      mtConfirmation,[mbOk,mbCancel])=mrOk
    then begin
      if DeleteFileUTF8(OldPkgFilename) then begin
        RemoveFromRecentList(OldPkgFilename,
                             EnvironmentOptions.RecentPackageFiles);
      end else begin
        IDEMessageDialog(lisPkgMangDeleteFailed,
          Format(lisPkgMangUnableToDeleteFile, ['"', OldPkgFilename, '"']),
            mtError, [mbOk]);
      end;
    end;
  end;

  // success
  Result:=mrOk;
end;

function TPkgManager.DoWriteMakefile(APackage: TLazPackage): TModalResult;
var
  PathDelimNeedsReplace: Boolean;

  procedure Replace(var s: string; const SearchTxt, ReplaceTxt: string);
  var
    p: LongInt;
  begin
    repeat
      p:=Pos(SearchTxt,s);
      if p<=1 then break;
      s:=copy(s,1,p-1)+ReplaceTxt+copy(s,p+length(SearchTxt),length(s));
    until false;
  end;
  
  function ConvertPIMacrosToMakefileMacros(const s: string): string;
  begin
    Result:=s;
    Replace(Result,'%(','$(');
  end;

  function ConvertLazarusToMakefileSearchPath(const s: string): string;
  begin
    Result:=ConvertPIMacrosToMakefileMacros(s);
    Result:=CreateRelativeSearchPath(TrimSearchPath(Result,''),APackage.Directory);
    Replace(Result,';',' ');
    if PathDelimNeedsReplace then
      Replace(Result,PathDelim,'/');
  end;

  function ConvertLazarusToMakefileDirectory(const s: string): string;
  begin
    Result:=ConvertPIMacrosToMakefileMacros(s);
    Result:=CreateRelativePath(TrimFilename(Result),APackage.Directory);
    if PathDelimNeedsReplace then
      Replace(Result,PathDelim,'/');
    // trim trailing PathDelim, as windows does not like it
    Result:=ChompPathDelim(Result);
  end;
  
  function ConvertLazarusOptionsToMakefileOptions(const s: string): string;
  begin
    Result:=ConvertPIMacrosToMakefileMacros(s);
    if PathDelimNeedsReplace then
      Replace(Result,PathDelim,'/');
  end;

var
  s: String;
  e: string;
  SrcFilename: String;
  MainUnitName: String;
  MakefileFPCFilename: String;
  UnitOutputPath: String;
  UnitPath: String;
  FPCMakeTool: TIDEExternalToolOptions;
  CodeBuffer: TCodeBuffer;
  MainSrcFile: String;
  CustomOptions: String;
  IncPath: String;
begin
  Result:=mrCancel;
  PathDelimNeedsReplace:=PathDelim<>'/';

  MakefileFPCFilename:=AppendPathDelim(APackage.Directory)+'Makefile.fpc';
  if not DirectoryIsWritableCached(APackage.Directory) then begin
    // the Makefile.fpc is only needed for custom building
    // if the package directory is not writable, then the user don't want to
    // custom build
    // => silently skip
    DebugLn(['TPkgManager.DoWriteMakefile Skipping, because package directory is not writable: ',APackage.Directory]);
    Result:=mrOk;
    exit;
  end;

  SrcFilename:=APackage.GetSrcFilename;
  MainUnitName:=lowercase(ExtractFileNameOnly((SrcFilename)));
  UnitPath:=APackage.CompilerOptions.GetUnitPath(true,
                                                 coptParsedPlatformIndependent);
  IncPath:=APackage.CompilerOptions.GetIncludePath(true,
                                                 coptParsedPlatformIndependent);
  UnitOutputPath:=APackage.CompilerOptions.GetUnitOutPath(true,
                                                 coptParsedPlatformIndependent);
  CustomOptions:=APackage.CompilerOptions.GetCustomOptions(
                                                 coptParsedPlatformIndependent);
  s:=APackage.CompilerOptions.GetSyntaxOptionsString;
  if s<>'' then
    CustomOptions:=CustomOptions+' '+s;
  // TODO: other options

  //DebugLn('TPkgManager.DoWriteMakefile ',APackage.Name,' makefile UnitPath="',UnitPath,'"');
  UnitPath:=ConvertLazarusToMakefileSearchPath(UnitPath);
  IncPath:=ConvertLazarusToMakefileSearchPath(IncPath);
  // remove path delimiter at the end, or else it will fail on windows
  UnitOutputPath:=ConvertLazarusToMakefileDirectory(
                                                ChompPathDelim(UnitOutputPath));
  MainSrcFile:=CreateRelativePath(SrcFilename,APackage.Directory);
  CustomOptions:=ConvertLazarusOptionsToMakefileOptions(CustomOptions);
  

  e:=LineEnding;
  s:='';
  s:=s+'#   File generated automatically by Lazarus Package Manager'+e;
  s:=s+'#'+e;
  s:=s+'#   Makefile.fpc for '+APackage.IDAsString+e;
  s:=s+'#'+e;
  s:=s+'#   This file was generated on '+DateToStr(Now)+''+e;
  s:=s+''+e;
  s:=s+'[package]'+e;
  s:=s+'name='+lowercase(APackage.Name)+e;
  s:=s+'version='+APackage.Version.AsString+e;
  s:=s+''+e;
  s:=s+'[compiler]'+e;
  s:=s+'unittargetdir='+UnitOutputPath+e;
  if UnitPath<>'' then
    s:=s+'unitdir='+UnitPath+e;
  if IncPath<>'' then
    s:=s+'includedir='+IncPath+e;
  s:=s+'options='+CustomOptions+e; // ToDo do the other options
  s:=s+''+e;
  s:=s+'[target]'+e;
  s:=s+'units='+MainSrcFile+e;
  //s:=s+'implicitunits=syntextdrawer'+e; // TODO list all unit names
  s:=s+''+e;
  s:=s+'[clean]'+e;
  s:=s+'files=$(wildcard $(COMPILER_UNITTARGETDIR)/*$(OEXT)) \'+e;
  s:=s+'      $(wildcard $(COMPILER_UNITTARGETDIR)/*$(PPUEXT)) \'+e;
  s:=s+'      $(wildcard $(COMPILER_UNITTARGETDIR)/*$(RSTEXT)) \'+e;
  s:=s+'      $(wildcard $(COMPILER_UNITTARGETDIR)/*.compiled) \'+e;
  s:=s+'      $(wildcard *$(OEXT)) $(wildcard *$(PPUEXT)) $(wildcard *$(RSTEXT))'+e;
  s:=s+'[prerules]'+e;
  s:=s+'# LCL Platform'+e;
  s:=s+'ifndef LCL_PLATFORM'+e;
  s:=s+'ifeq ($(OS_TARGET),win32)'+e;
  s:=s+'LCL_PLATFORM=win32'+e;
  s:=s+'else'+e;
  s:=s+'ifeq ($(OS_TARGET),win64)'+e;
  s:=s+'LCL_PLATFORM=win32'+e;
  s:=s+'else'+e;
  s:=s+'ifeq ($(OS_TARGET),darwin)'+e;
  s:=s+'LCL_PLATFORM=carbon'+e;
  s:=s+'else'+e;
  s:=s+'LCL_PLATFORM=gtk2'+e;
  s:=s+'endif'+e;
  s:=s+'endif'+e;
  s:=s+'endif'+e;
  s:=s+'endif'+e;
  s:=s+'export LCL_PLATFORM'+e;

  s:=s+''+e;
  s:=s+'[rules]'+e;
  s:=s+'.PHONY: cleartarget all'+e;
  s:=s+''+e;
  s:=s+'cleartarget:'+e;
  s:=s+'        -$(DEL) $(COMPILER_UNITTARGETDIR)/'+MainUnitName+'$(PPUEXT)'+e;
  s:=s+''+e;
  s:=s+'all: cleartarget $(COMPILER_UNITTARGETDIR) '+MainUnitName+'$(PPUEXT)'+e;
  
  //DebugLn('TPkgManager.DoWriteMakefile [',s,']');

  CodeBuffer:=CodeToolBoss.LoadFile(MakefileFPCFilename,true,true);
  if CodeBuffer=nil then begin
    CodeBuffer:=CodeToolBoss.CreateFile(MakefileFPCFilename);
    if CodeBuffer=nil then begin
      if not DirectoryIsWritableCached(ExtractFilePath(MakefileFPCFilename))
      then begin
        // the package source is read only => no problem
        exit(mrOk);
      end;
      exit(mrCancel);
    end;
  end;

  if ExtractCodeFromMakefile(CodeBuffer.Source)=ExtractCodeFromMakefile(s)
  then begin
    // Makefile.fpc not changed
    Result:=mrOk;
    exit;
  end;
  CodeBuffer.Source:=s;

  //debugln('TPkgManager.DoWriteMakefile MakefileFPCFilename="',MakefileFPCFilename,'"');
  Result:=SaveCodeBufferToFile(CodeBuffer,MakefileFPCFilename);
  if Result<>mrOk then begin
    if not DirectoryIsWritableCached(ExtractFilePath(MakefileFPCFilename)) then
    begin
      // the package source is read only => no problem
      Result:=mrOk;
    end;
    exit;
  end;
  
  // call fpcmake to create the Makefile
  FPCMakeTool:=TIDEExternalToolOptions.Create;
  try
    FPCMakeTool.Title:='Creating Makefile for package '+APackage.IDAsString;
    FPCMakeTool.WorkingDirectory:=APackage.Directory;
    FPCMakeTool.Filename:=FindFPCTool('fpcmake'+GetExecutableExt,
                                      EnvironmentOptions.CompilerFilename);
    FPCMakeTool.CmdLineParams:='-q -TAll';
    FPCMakeTool.EnvironmentOverrides.Add(
                            'FPCDIR='+EnvironmentOptions.GetFPCSourceDirectory);

    // clear old errors
    SourceNotebook.ClearErrorLines;

    // compile package
    Result:=RunExternalTool(FPCMakeTool);
    if Result<>mrOk then begin
      Result:=IDEMessageDialog(lisFpcmakeFailed,
        Format(lisCallingToCreateMakefileFromFailed, [FPCMakeTool.Filename,
          MakefileFPCFilename]),
        mtError,[mbCancel]);
      exit;
    end;
  finally
    // clean up
    FPCMakeTool.Free;
  end;
  
  Result:=mrOk;
end;

function TPkgManager.CheckPackageGraphForCompilation(APackage: TLazPackage;
  FirstDependency: TPkgDependency; const Directory: string): TModalResult;
var
  PathList: TFPList;
  Dependency: TPkgDependency;
  PkgFile1,PkgFile2: TPkgFile;
  ConflictPkg: TLazPackage;
  s: String;
begin
  {$IFDEF VerbosePkgCompile}
  debugln('TPkgManager.CheckPackageGraphForCompilation A');
  {$ENDIF}
  PathList:=nil;
  try
    // check for unsaved packages
    PathList:=PackageGraph.FindUnsavedDependencyPath(APackage,FirstDependency);
    if PathList<>nil then begin
      DoShowPackageGraphPathList(PathList);
      Result:=IDEMessageDialog(lisPkgMangUnsavedPackage,
        lisPkgMangThereIsAnUnsavedPackageInTheRequiredPackages,
        mtError,[mbCancel,mbAbort]);
      exit;
    end;

    // check for broken dependencies
    PathList:=PackageGraph.FindBrokenDependencyPath(APackage,FirstDependency);
    if PathList<>nil then begin
      if (PathList.Count=1) then begin
        Dependency:=TPkgDependency(PathList[0]);
        if Dependency is TPkgDependency then begin
          // check if project
          if Dependency.Owner is TProject then begin
            MainIDE.DoShowProjectInspector;
            Result:=IDEMessageDialog(lisPkgMangBrokenDependency,
              Format(lisPkgMangTheProjectRequiresThePackageButItWasNotFound, [
                '"', Dependency.AsString, '"', #13]),
              mtError,[mbCancel,mbAbort]);
            exit;
          end;
        end;
      end;
      DoShowPackageGraphPathList(PathList);
      Result:=IDEMessageDialog(lisPkgMangBrokenDependency,
        lisPkgMangARequiredPackagesWasNotFound,
        mtError,[mbCancel,mbAbort]);
      exit;
    end;

    // check for circle dependencies
    PathList:=PackageGraph.FindCircleDependencyPath(APackage,FirstDependency);
    if PathList<>nil then begin
      DoShowPackageGraphPathList(PathList);
      Result:=IDEMessageDialog(lisPkgMangCircleInPackageDependencies,
        lisPkgMangThereIsACircleInTheRequiredPackages,
        mtError,[mbCancel,mbAbort]);
      exit;
    end;

    // check for ambiguous units between packages
    if PackageGraph.FindAmbiguousUnits(APackage,FirstDependency,
      PkgFile1,PkgFile2,ConflictPkg)
    then begin
      if (PkgFile1<>nil) and (PkgFile2<>nil) then begin
        s:=Format(lisPkgMangThereAreTwoUnitsWithTheSameName1From2From, [#13,
          #13, '"', PkgFile1.Filename, '"', PkgFile1.LazPackage.IDAsString,
          #13, '"', PkgFile2.Filename, '"', PkgFile2.LazPackage.IDAsString,
          #13, #13]);
      end else if (PkgFile1<>nil) and (ConflictPkg<>nil) then begin
        s:=Format(lisPkgMangThereIsAUnitWithTheSameNameAsAPackage1From2, [#13,
          #13, '"', PkgFile1.Filename, '"', PkgFile1.LazPackage.IDAsString,
          #13, '"', ConflictPkg.IDAsString, #13, #13]);
      end else
        s:='Internal inconsistency FindAmbiguousUnits: '
          +'Please report this bug and how you got here.'#13;
      Result:=IDEMessageDialog(lisPkgMangAmbiguousUnitsFound, Format(
        lisPkgMangBothPackagesAreConnectedThisMeansEitherOnePackageU, [s]),
          mtError,[mbCancel,mbAbort]);
      exit;
    end;

    // check for ambiguous units between packages and FPC units
    if PackageGraph.FindFPCConflictUnit(APackage,FirstDependency,Directory,
      @PackageGraphFindFPCUnit,PkgFile1,ConflictPkg)
    then begin
      if (ConflictPkg<>nil) then begin
        s:=Format(lisPkgMangThereIsAFPCUnitWithTheSameNameAsAPackage, [#13,
          #13, '"', ConflictPkg.IDAsString, #13, #13]);
      end else if (PkgFile1<>nil) then begin
        s:=Format(lisPkgMangThereIsAFPCUnitWithTheSameNameFrom, [#13, #13, '"',
          PkgFile1.Filename, '"', PkgFile1.LazPackage.IDAsString, #13, #13]);
      end else
        s:='Internal inconsistency FindFPCConflictUnits: '
          +'Please report this bug and how you got here.'#13;
      Result:=IDEMessageDialog(lisPkgMangAmbiguousUnitsFound, s,
          mtError,[mbCancel,mbAbort]);
      exit;
    end;

  finally
    PathList.Free;
  end;
  
  {$IFDEF VerbosePkgCompile}
  debugln('TPkgManager.CheckPackageGraphForCompilation END');
  {$ENDIF}
  Result:=mrOk;
end;

function TPkgManager.DoGetUnitRegisterInfo(const AFilename: string;
  var TheUnitName: string; var HasRegisterProc: boolean; IgnoreErrors: boolean
  ): TModalResult;
  
  function ErrorsHandled: boolean;
  begin
    if (CodeToolBoss.ErrorMessage='') or IgnoreErrors then exit(true);
    MainIDE.DoJumpToCodeToolBossError;
    Result:=false;
  end;
  
var
  ExpFilename: String;
  CodeBuffer: TCodeBuffer;
begin
  Result:=mrCancel;
  ExpFilename:=CleanAndExpandFilename(AFilename);
  // create default values
  TheUnitName:='';
  HasRegisterProc:=false;
  MainIDE.SaveSourceEditorChangesToCodeCache(-1);
  CodeBuffer:=CodeToolBoss.LoadFile(ExpFilename,true,false);
  if CodeBuffer<>nil then begin
    TheUnitName:=CodeToolBoss.GetSourceName(CodeBuffer,false);
    if not ErrorsHandled then exit;
    CodeToolBoss.HasInterfaceRegisterProc(CodeBuffer,HasRegisterProc);
    if not ErrorsHandled then exit;
  end;
  if TheUnitName='' then
    TheUnitName:=ExtractFileNameOnly(ExpFilename);
  Result:=mrOk;
end;

procedure TPkgManager.SaveAutoInstallDependencies(
  SetWithStaticPcksFlagForIDE: boolean);
var
  Dependency: TPkgDependency;
  sl: TStringList;
begin
  if SetWithStaticPcksFlagForIDE then begin
    MiscellaneousOptions.BuildLazOpts.WithStaticPackages:=true;
  end;

  sl:=TStringList.Create;
  Dependency:=PackageGraph.FirstAutoInstallDependency;
  while Dependency<>nil do begin
    if (Dependency.LoadPackageResult=lprSuccess)
    and (not Dependency.RequiredPackage.AutoCreated)
    and (not Dependency.RequiredPackage.Missing) then begin
      if sl.IndexOf(Dependency.PackageName)<0 then begin
        sl.Add(Dependency.PackageName);
        DebugLn('TPkgManager.SaveAutoInstallDependencies A ',Dependency.PackageName);
      end;
    end;
    Dependency:=Dependency.NextRequiresDependency;
  end;
  MiscellaneousOptions.BuildLazOpts.StaticAutoInstallPackages.Assign(sl);
  MiscellaneousOptions.Save;
  sl.Free;
end;

procedure TPkgManager.LoadStaticCustomPackages;
var
  StaticPackages: TFPList;
  StaticPackage: PRegisteredPackage;
  i: Integer;
  APackage: TLazPackage;
  Quiet: Boolean;
begin
  StaticPackages:=LazarusPackageIntf.RegisteredPackages;
  if StaticPackages=nil then exit;
  Quiet:=false;
  for i:=0 to StaticPackages.Count-1 do begin
    StaticPackage:=PRegisteredPackage(StaticPackages[i]);
    
    // check package name
    if (StaticPackage^.Name='') or (not IsValidIdent(StaticPackage^.Name))
    then begin
      DebugLn('TPkgManager.LoadStaticCustomPackages Invalid Package Name: "',
        BinaryStrToText(StaticPackage^.Name),'"');
      continue;
    end;
    
    // check register procedure
    if (StaticPackage^.RegisterProc=nil) then begin
      DebugLn('TPkgManager.LoadStaticCustomPackages',
        ' Package "',StaticPackage^.Name,'" has no register procedure.');
      continue;
    end;
    
    // load package
    APackage:=LoadInstalledPackage(StaticPackage^.Name,KeepInstalledPackages,
                                   Quiet);
    
    // register
    PackageGraph.RegisterStaticPackage(APackage,StaticPackage^.RegisterProc);
  end;
  PackageGraph.SortAutoInstallDependencies;
  ClearRegisteredPackages;
end;

function TPkgManager.LoadInstalledPackage(const PackageName: string;
  AddToAutoInstall: boolean; var Quiet: boolean): TLazPackage;
var
  NewDependency: TPkgDependency;
  PackageList: TStringList;
begin
  //DebugLn('TPkgManager.LoadInstalledPackage PackageName="',PackageName,'" Quiet=',Quiet);
  NewDependency:=TPkgDependency.Create;
  NewDependency.Owner:=Self;
  NewDependency.PackageName:=PackageName;
  PackageGraph.OpenInstalledDependency(NewDependency,pitStatic,Quiet);
  Result:=NewDependency.RequiredPackage;
  if AddToAutoInstall and (Result<>nil) then begin
    NewDependency.AddToList(PackageGraph.FirstAutoInstallDependency,pdlRequires);
    PackageList:=MiscellaneousOptions.BuildLazOpts.StaticAutoInstallPackages;
    if PackageList.IndexOf(NewDependency.PackageName)<0 then
      PackageList.Add(NewDependency.PackageName);
    NewDependency.RequiredPackage.AutoInstall:=pitStatic;
  end else begin
    NewDependency.Free;
  end;
end;

procedure TPkgManager.LoadAutoInstallPackages;
begin
  PackageGraph.LoadAutoInstallPackages(
    MiscellaneousOptions.BuildLazOpts.StaticAutoInstallPackages);
end;

procedure TPkgManager.AddUnitToProjectMainUsesSection(AProject: TProject;
  const AnUnitName, AnUnitInFilename: string);
begin
  // add unit to project main source file
  if (pfMainUnitHasUsesSectionForAllUnits in AProject.Flags)
  and (AProject.MainUnitInfo<>nil) then begin
    //debugln('TPkgManager.AddUnitToProjectMainUsesSection B ',AnUnitName);
    if (AnUnitName<>'') then begin
      MainIDEInterface.SaveSourceEditorChangesToCodeCache(-1);
      if CodeToolBoss.AddUnitToMainUsesSection(
        AProject.MainUnitInfo.Source,AnUnitName,AnUnitInFilename)
      then
        AProject.MainUnitInfo.Modified:=true;
    end;
  end;
end;

constructor TPkgManager.Create(TheOwner: TComponent);
var
  CompPalette: TComponentPalette;
begin
  inherited Create(TheOwner);
  OnGetDependencyOwnerDescription:=@GetDependencyOwnerDescription;
  OnGetDependencyOwnerDirectory:=@GetDependencyOwnerDirectory;
  OnGetWritablePkgOutputDirectory:=@GetWritablePkgOutputDirectory;

  // componentpalette
  IDEComponentPalette:=TComponentPalette.Create;
  CompPalette:=TComponentPalette(IDEComponentPalette);
  if CompPalette=nil then ;
  CompPalette.OnEndUpdate:=@IDEComponentPaletteEndUpdate;
  CompPalette.OnOpenPackage:=@IDEComponentPaletteOpenPackage;
  CompPalette.OnOpenUnit:=@IDEComponentPaletteOpenUnit;

  // package links
  PkgLinks:=TPackageLinks.Create;
  PkgLinks.UpdateAll;
  PkgLinks.DependencyOwnerGetPkgFilename:=@PkgLinksDependencyOwnerGetPkgFilename;

  // package graph
  PackageGraph:=TLazPackageGraph.Create;
  PackageGraph.OnChangePackageName:=@PackageGraphChangePackageName;
  PackageGraph.OnAddPackage:=@PackageGraphAddPackage;
  PackageGraph.OnDeletePackage:=@PackageGraphDeletePackage;
  PackageGraph.OnDependencyModified:=@PackageGraphDependencyModified;
  PackageGraph.OnBeginUpdate:=@PackageGraphBeginUpdate;
  PackageGraph.OnEndUpdate:=@PackageGraphEndUpdate;
  PackageGraph.OnDeleteAmbiguousFiles:=@BuildBoss.DeleteAmbiguousFiles;
  PackageGraph.OnWriteMakeFile:=@DoWriteMakefile;
  PackageGraph.OnUninstallPackage:=@DoUninstallPackage;
  PackageGraph.OnTranslatePackage:=@DoTranslatePackage;

  // package editors
  PackageEditors:=TPackageEditors.Create;
  PackageEditors.OnOpenFile:=@MainIDE.DoOpenMacroFile;
  PackageEditors.OnOpenPkgFile:=@OnPackageEditorOpenPkgFile;
  PackageEditors.OnOpenPackage:=@OnPackageEditorOpenPackage;
  PackageEditors.OnCreateNewFile:=@OnPackageEditorCreateFile;
  PackageEditors.OnGetIDEFileInfo:=@MainIDE.GetIDEFileState;
  PackageEditors.OnGetUnitRegisterInfo:=@OnPackageEditorGetUnitRegisterInfo;
  PackageEditors.OnFreeEditor:=@OnPackageEditorFreeEditor;
  PackageEditors.OnSavePackage:=@OnPackageEditorSavePackage;
  PackageEditors.OnRevertPackage:=@OnPackageEditorRevertPackage;
  PackageEditors.OnPublishPackage:=@OnPackageEditorPublishPackage;
  PackageEditors.OnCompilePackage:=@OnPackageEditorCompilePackage;
  PackageEditors.OnAddToProject:=@OnPackageEditorAddToProject;
  PackageEditors.OnInstallPackage:=@OnPackageEditorInstallPackage;
  PackageEditors.OnUninstallPackage:=@OnPackageEditorUninstallPackage;
  PackageEditors.OnViewPackageSource:=@OnPackageEditorViewPkgSource;
  PackageEditors.OnViewPackageToDos:=@OnPackageEditorViewPkgToDos;
  PackageEditors.OnDeleteAmbiguousFiles:=@OnPackageEditorDeleteAmbiguousFiles;
  PackageEditors.OnImExportCompilerOptions:=@OnPackageEditorImExportCompilerOptions;
  PackageEditors.OnCreateMakefile:=@OnPackageEditorCreateMakefile;

  // package macros
  CodeToolBoss.DefineTree.MacroFunctions.AddExtended(
    'PKGDIR',nil,@PackageGraph.MacroFunctionCTPkgDir);
  CodeToolBoss.DefineTree.MacroFunctions.AddExtended(
    'PKGSRCPATH',nil,@PackageGraph.MacroFunctionCTPkgSrcPath);
  CodeToolBoss.DefineTree.MacroFunctions.AddExtended(
    'PKGUNITPATH',nil,@PackageGraph.MacroFunctionCTPkgUnitPath);
  CodeToolBoss.DefineTree.MacroFunctions.AddExtended(
    'PKGINCPATH',nil,@PackageGraph.MacroFunctionCTPkgIncPath);
    
  LazPackageDescriptors:=TLazPackageDescriptors.Create;
  LazPackageDescriptors.AddDefaultPackageDescriptors;

  // idle handler
  Application.AddOnIdleHandler(@OnApplicationIdle,true);
end;

destructor TPkgManager.Destroy;
var
  Dependency: TPkgDependency;
begin
  if IDEComponentPalette<>nil then
    TComponentPalette(IDEComponentPalette).Notebook:=nil;
  FreeThenNil(LazPackageDescriptors);
  while PackageGraph.FirstAutoInstallDependency<>nil do begin
    Dependency:=PackageGraph.FirstAutoInstallDependency;
    Dependency.RequiredPackage:=nil;
    Dependency.RemoveFromList(PackageGraph.FirstAutoInstallDependency,pdlRequires);
    Dependency.Free;
  end;
  FreeThenNil(PackageGraphExplorer);
  FreeThenNil(PackageEditors);
  FreeThenNil(PackageGraph);
  FreeThenNil(PkgLinks);
  FreeThenNil(IDEComponentPalette);
  FreeThenNil(PackageDependencies);
  inherited Destroy;
end;

procedure TPkgManager.ConnectMainBarEvents;
begin
  with MainIDEBar do begin
    itmPkgNewPackage.OnClick :=@MainIDEitmPkgNewPackageClick;
    itmPkgOpenPackage.OnClick :=@MainIDEitmPkgOpenPackageClicked;
    itmPkgOpenPackageFile.OnClick:=@MainIDEitmPkgOpenPackageFileClick;
    itmPkgOpenPackageOfCurUnit.OnClick :=@MainIDEitmPkgOpenPackageOfCurUnitClicked;
    itmPkgAddCurUnitToPkg.OnClick:=@MainIDEitmPkgAddCurUnitToPkgClick;
    itmPkgPkgGraph.OnClick:=@MainIDEitmPkgPkgGraphClick;
    itmPkgEditInstallPkgs.OnClick:=@MainIDEitmPkgEditInstallPkgsClick;
    {$IFDEF CustomIDEComps}
    itmCompsConfigCustomComps.OnClick :=@MainIDEitmConfigCustomCompsClicked;
    {$ENDIF}
    
    itmViewPackageLinks.OnClick := @MainIDEViewPackageLinksClicked;
  end;
  
  SetRecentPackagesMenu;
end;

procedure TPkgManager.ConnectSourceNotebookEvents;
begin

end;

procedure TPkgManager.SetupMainBarShortCuts;
begin

end;

procedure TPkgManager.SetRecentPackagesMenu;
begin
  MainIDE.SetRecentSubMenu(itmPkgOpenRecent,
     EnvironmentOptions.RecentPackageFiles,@MainIDEitmOpenRecentPackageClicked);
end;

procedure TPkgManager.AddFileToRecentPackages(const Filename: string);
begin
  AddToRecentList(Filename,EnvironmentOptions.RecentPackageFiles,
                  EnvironmentOptions.MaxRecentPackageFiles);
  SetRecentPackagesMenu;
  MainIDE.SaveEnvironment;
end;

procedure TPkgManager.SaveSettings;
begin
  PackageEditors.SaveLayouts;
end;

function TPkgManager.GetDefaultSaveDirectoryForFile(const Filename: string
  ): string;
var
  APackage: TLazPackage;
  PkgFile: TPkgFile;
begin
  Result:='';
  PkgFile:=PackageGraph.FindFileInAllPackages(Filename,true,true);
  if PkgFile=nil then exit;
  APackage:=PkgFile.LazPackage;
  if APackage.AutoCreated or (not APackage.HasDirectory) then exit;
  Result:=APackage.Directory;
end;

function TPkgManager.GetPublishPackageDir(APackage: TLazPackage): string;
begin
  Result:=APackage.PublishOptions.DestinationDirectory;
  if IDEMacros.SubstituteMacros(Result) then begin
    if FilenameIsAbsolute(Result) then begin
      Result:=AppendPathDelim(TrimFilename(Result));
    end else begin
      Result:='';
    end;
  end else begin
    Result:='';
  end;
end;

procedure TPkgManager.LoadInstalledPackages;
begin
  IDEComponentPalette.BeginUpdate(true);
  try
    PackageGraph.LoadStaticBasePackages;
    LoadStaticCustomPackages;
    LoadAutoInstallPackages;
  finally
    IDEComponentPalette.EndUpdate;
  end;
end;

procedure TPkgManager.UnloadInstalledPackages;
var
  Dependency: TPkgDependency;
begin
  // break and free auto installed packages
  while PackageGraph.FirstAutoInstallDependency<>nil do begin
    Dependency:=PackageGraph.FirstAutoInstallDependency;
    Dependency.RequiredPackage:=nil;
    Dependency.RemoveFromList(PackageGraph.FirstAutoInstallDependency,pdlRequires);
    Dependency.Free;
  end;
end;

procedure TPkgManager.UpdateVisibleComponentPalette;
begin
  TComponentPalette(IDEComponentPalette).NoteBook:=MainIDEBar.ComponentNotebook;
  TComponentPalette(IDEComponentPalette).UpdateNoteBookButtons;
end;

procedure TPkgManager.ProcessCommand(Command: word; var Handled: boolean);
begin
  Handled:=true;
  case Command of
  ecOpenPackage: MainIDEitmPkgOpenPackageClicked(Self);
  ecOpenPackageFile: MainIDEitmPkgOpenPackageFileClick(Self);
  ecOpenPackageOfCurUnit: MainIDEitmPkgOpenPackageOfCurUnitClicked(Self);
  ecAddCurUnitToPkg: MainIDEitmPkgAddCurUnitToPkgClick(Self);
  ecPackageGraph: MainIDEitmPkgPkgGraphClick(Self);
  ecEditInstallPkgs: MainIDEitmPkgEditInstallPkgsClick(Self);
  else
    Handled:=false;
  end;
end;

procedure TPkgManager.OnSourceEditorPopupMenu(
  const AddMenuItemProc: TAddMenuItemProc);
var
  PkgFile: TPkgFile;
begin
  PkgFile:=GetPackageOfCurrentSourceEditor;
  if PkgFile<>nil then
    AddMenuItemProc(Format(lisOpenPackage2, [PkgFile.LazPackage.Name]), true,
                    @OnOpenPackageForCurrentSrcEditFile);
end;

procedure TPkgManager.TranslateResourceStrings;
var
  PkgList: TFPList;
  i: Integer;
begin
  PkgList:=nil;
  OnGetAllRequiredPackages(PackageGraph.FirstAutoInstallDependency,PkgList);
  if PkgList=nil then exit;
  for i:=0 to PkgList.Count-1 do
    if TObject(PkgList[i]) is TLazPackage then
      DoTranslatePackage(TLazPackage(PkgList[i]));
  PkgList.Free;
end;

procedure TPkgManager.DoTranslatePackage(APackage: TLazPackage);
var
  TranslatedUnits: TStringHashList;
  
  function UnitTranslated(const AnUnitName: string): boolean;
  begin
    Result:=(TranslatedUnits<>nil) and (TranslatedUnits.Find(AnUnitName)>=0);
  end;
  
  procedure TranslateUnit(const AFilename, AnUnitName: string);
  begin
    //DebugLn(['TranslateUnit AFilename="',AFilename,'" AnUnitName="',AnUnitName,'"']);
    if TranslatedUnits=nil then
      TranslatedUnits:=TStringHashList.Create(false);
    TranslatedUnits.Add(AnUnitName);
    TranslateUnitResourceStrings(AnUnitName,AFilename);
  end;

  function GetPOFilenameParts(const Filename: string;
    var UnitName, Language: string): boolean;
  var
    UnitNameEnd: Integer;
    LangEnd: Integer;
  begin
    Result:=false;
    UnitNameEnd:=1;
    while (UnitNameEnd<=length(Filename)) and (Filename[UnitNameEnd]<>'.') do
      inc(UnitNameEnd);
    if (UnitNameEnd=1) then exit;
    LangEnd:=UnitNameEnd+1;
    while (LangEnd<=length(Filename)) and (Filename[LangEnd]<>'.') do
      inc(LangEnd);
    if LangEnd<>length(Filename)-2 then exit;
    UnitName:=copy(Filename,1,UnitNameEnd-1);
    Language:=copy(Filename,UnitNameEnd+1,LangEnd-UnitNameEnd-1);
    Result:=IsValidIdent(UnitName) and (Language<>'');
    //DebugLn(['GetPOFilenameParts UnitName=',UnitName,' Language=',Language,' Result=',Result]);
  end;
  
  procedure TranslateWithFileMask(APackage: TLazPackage;
    const Directory, Language: string);
  var
    FileInfo: TSearchRec;
    CurUnitName: string;
    CurLang: string;
    FileMask: String;
  begin
    if Language='' then exit;
    FileMask:=Directory+'*.'+Language+'.po';
    //DebugLn(['TranslateWithFileMask APackage=',APackage.IDAsString,' FileMask="',FileMask,'"']);
    if FindFirstUTF8(FileMask,faAnyFile,FileInfo)=0
    then begin
      repeat
        // check if special file
        if (FileInfo.Name='.') or (FileInfo.Name='..') or (FileInfo.Name='') then
          continue;
        if GetPOFilenameParts(FileInfo.Name,CurUnitName,CurLang)
        and (CurLang=Language)
        and (APackage.FindUnit(CurUnitName)<>nil)
        and not UnitTranslated(CurUnitName) then begin
          TranslateUnit(Directory+FileInfo.Name,CurUnitName);
        end;
      until FindNextUTF8(FileInfo)<>0;
    end;
    FindCloseUTF8(FileInfo);
  end;

var
  Directory: String;
  Lang: String;
  FallbackLang: String;
  Language: String;
begin
  //DebugLn(['TPkgManager.DoTranslatePackage ', APackage.Name, 'from ', APackage.POOutputDirectory]);
  if (APackage.POOutputDirectory='') then exit;
  Directory:=AppendPathDelim(APackage.GetPOOutDirectory);

  Language:=EnvironmentOptions.LanguageID;
  if Language='' then begin
    Lang:=SystemLanguageID1;
    FallbackLang:=SystemLanguageID2;
  end else begin
    Lang:=Language;
    FallbackLang:='';
  end;
  
  if APackage.Translated=Lang then exit;
  APackage.Translated:=Lang;
  
  TranslatedUnits:=nil;
  try
    //DebugLn(['TPkgManager.DoTranslatePackage ',APackage.Name,' Directory=',Directory,' Lang=',Lang,' FallbackLang=',FallbackLang]);
    TranslateWithFileMask(APackage,Directory,Lang);
    TranslateWithFileMask(APackage,Directory,FallbackLang);
  finally
    TranslatedUnits.Free;
  end;
end;

function TPkgManager.AddPackageToGraph(APackage: TLazPackage;
  Replace: boolean): TModalResult;
var
  ConflictPkg: TLazPackage;
begin
  // check Package Name
  if (APackage.Name='') or (not IsValidIdent(APackage.Name)) then begin
    Result:=IDEMessageDialog(lisPkgMangInvalidPackageName2,
      Format(lisPkgMangThePackageNameOfTheFileIsInvalid, ['"', APackage.Name,
        '"', #13, '"', APackage.Filename, '"']),
      mtError,[mbCancel,mbAbort]);
    exit;
  end;

  // check if Package with same name is already loaded
  ConflictPkg:=PackageGraph.FindAPackageWithName(APackage.Name,nil);
  if ConflictPkg<>nil then begin
    if not PackageGraph.PackageCanBeReplaced(ConflictPkg,APackage) then begin
      Result:=IDEMessageDialog(lisPkgMangPackageConflicts,
        Format(lisPkgMangThereIsAlreadyAPackageLoadedFromFile, ['"',
          ConflictPkg.IDAsString, '"', #13, '"', ConflictPkg.Filename, '"',
          #13, #13]),
        mtError,[mbCancel,mbAbort]);
      exit;
    end;
    
    if ConflictPkg.Modified and (not ConflictPkg.ReadOnly) then begin
      Result:=IDEMessageDialog(lisPkgMangSavePackage,
        Format(lisPkgMangLoadingPackageWillReplacePackage, [
          APackage.IDAsString, ConflictPkg.IDAsString, #13,
          ConflictPkg.Filename, #13, #13, #13, ConflictPkg.Filename]),
        mtConfirmation,[mbYes,mbNo,mbCancel,mbAbort]);
      if Result=mrNo then Result:=mrOk;
      if Result=mrYes then begin
        Result:=DoSavePackage(ConflictPkg,[]);
      end;
      if Result<>mrOk then exit;
    end;
    
    // replace package
    PackageGraph.ReplacePackage(ConflictPkg,APackage);
  end else begin
    // add to graph
    PackageGraph.AddPackage(APackage);
  end;

  // save package file links
  DebugLn(['TPkgManager.AddPackageToGraph ',APackage.Name]);
  PkgLinks.SaveUserLinks;

  Result:=mrOk;
end;

function TPkgManager.OpenProjectDependencies(AProject: TProject;
  ReportMissing: boolean): TModalResult;
var
  BrokenDependencies: TFPList;
begin
  PackageGraph.OpenRequiredDependencyList(AProject.FirstRequiredDependency);
  if ReportMissing then begin
    BrokenDependencies:=PackageGraph.FindAllBrokenDependencies(nil,
                                             AProject.FirstRequiredDependency);
    if BrokenDependencies<>nil then begin
      Result:=ShowBrokenDependenciesReport(BrokenDependencies);
      BrokenDependencies.Free;
    end;
  end else
    Result:=mrOk;
  PkgLinks.SaveUserLinks;
end;

procedure TPkgManager.AddDefaultDependencies(AProject: TProject);
begin
  OpenProjectDependencies(AProject,true);
end;

function TPkgManager.AddProjectDependency(AProject: TProject;
  APackage: TLazPackage; OnlyTestIfPossible: boolean): TModalResult;
var
  NewDependency: TPkgDependency;
  ProvidingAPackage: TLazPackage;
  ConflictDependency: TPkgDependency;
begin
  Result:=mrCancel;

  // check if there is dependency, that requires another version
  ConflictDependency:=PackageGraph.FindConflictRecursively(
    AProject.FirstRequiredDependency,APackage);
  if ConflictDependency<>nil then begin
    DebugLn(['TPkgManager.AddProjectDependency ',APackage.IDAsString,' conflicts with ',ConflictDependency.AsString]);
    Result:=mrCancel;
    exit;
  end;

  // check if the dependency is already there
  if FindDependencyByNameInList(AProject.FirstRequiredDependency,pdlRequires,
    APackage.Name)<>nil
  then begin
    // package already there
    Result:=mrCancel;
    exit;
  end;
  ProvidingAPackage:=PackageGraph.FindPackageProvidingName(
    AProject.FirstRequiredDependency,APackage.Name);
  if ProvidingAPackage<>nil then
  begin
    // package is already provided by another package
    DebugLn(['TPkgManager.AddProjectDependency ',APackage.Name,' is already provided by ',ProvidingAPackage.IDAsString]);
    Result:=mrCancel;
    exit;
  end;

  if OnlyTestIfPossible then
    exit(mrOk);
  // add a dependency for the package to the project
  NewDependency:=APackage.CreateDependencyWithOwner(AProject);
  Result:=AddProjectDependency(AProject,NewDependency);
end;

function TPkgManager.AddProjectDependency(AProject: TProject;
  ADependency: TPkgDependency): TModalResult;
begin
  Result:=mrOk;
  AProject.AddRequiredDependency(ADependency);
  PackageGraph.OpenDependency(ADependency,false);
  if (ADependency.RequiredPackage<>nil)
  and (not ADependency.RequiredPackage.AutoCreated)
  and ADependency.RequiredPackage.AddToProjectUsesSection
  then begin
    AddUnitToProjectMainUsesSection(AProject,ADependency.PackageName,'');
  end;
end;

procedure TPkgManager.AddProjectRegCompDependency(AProject: TProject;
  ARegisteredComponent: TRegisteredComponent);
var
  PkgFile: TPkgFile;
begin
  if not (ARegisteredComponent is TPkgComponent) then exit;
  
  PkgFile:=TPkgComponent(ARegisteredComponent).PkgFile;
  if (PkgFile=nil) or (PkgFile.LazPackage=nil) then exit;
  AddProjectDependency(AProject,PkgFile.LazPackage);
end;

procedure TPkgManager.AddProjectLCLDependency(AProject: TProject);
begin
  AddProjectDependency(AProject,PackageGraph.LCLPackage);
end;

function TPkgManager.AddProjectDependencies(AProject: TProject;
  const Packages: string; OnlyTestIfPossible: boolean): TModalResult;
var
  RequiredPackages: TStrings;
  i: Integer;
  PkgName: string;
  APackage: TLazPackage;
begin
  RequiredPackages:=SplitString(Packages,';');
  for i:=0 to RequiredPackages.Count-1 do begin
    PkgName:=Trim(RequiredPackages[i]);
    if (PkgName='') or (not IsValidIdent(PkgName)) then continue;
    APackage:=PackageGraph.FindAPackageWithName(PkgName,nil);
    if APackage=nil then begin
      DebugLn(['TPkgManager.AddProjectDependencies package not found: ',PkgName]);
      continue;
    end;
    AddProjectDependency(AProject,APackage);
  end;
  RequiredPackages.Free;
  Result:=mrOk;
end;

function TPkgManager.CheckProjectHasInstalledPackages(AProject: TProject; 
  Interactive: boolean): TModalResult;
var
  MissingUnits: TFPList;
  i: Integer;
  PkgFile: TPkgFile;
  Msg: String;
begin
  Result:=mrOk;
  MissingUnits:=PackageGraph.FindNotInstalledRegisterUnits(nil,
                                              AProject.FirstRequiredDependency);
  if MissingUnits<>nil then begin
    if Interactive then begin 
      Msg:=Format(lisProbablyYouNeedToInstallSomePackagesForBeforeConti, [#13,
        #13, #13, #13, #13, #13, #13, #13, #13]);
      for i:=0 to MissingUnits.Count-1 do begin
        PkgFile:=TPkgFile(MissingUnits[i]);
        Msg:=Format(lisUnitInPackage, [Msg, PkgFile.UnitName,
          PkgFile.LazPackage.IDAsString, #13]);
      end;
      Result:=IDEMessageDialog(lisPackageNeedsInstallation,
        Msg,mtWarning,[mbIgnore,mbCancel]);
      if Result<>mrIgnore then
        AProject.AutoOpenDesignerFormsDisabled:=true;
    end else
      Result:=mrCancel;    
    MissingUnits.Free;
  end;
end;

function TPkgManager.ShowConfigureCustomComponents: TModalResult;
begin
  Result:=ShowConfigureCustomComponentDlg(EnvironmentOptions.LazarusDirectory);
end;

function TPkgManager.DoNewPackage: TModalResult;
var
  NewPackage: TLazPackage;
  CurEditor: TPackageEditorForm;
begin
  // create a new package with standard dependencies
  NewPackage:=PackageGraph.CreateNewPackage(NameToValidIdentifier(lisPkgMangNewPackage));
  PackageGraph.AddDependencyToPackage(NewPackage,
                PackageGraph.FCLPackage.CreateDependencyWithOwner(NewPackage));
  NewPackage.Modified:=false;

  // open a package editor
  CurEditor:=PackageEditors.OpenEditor(NewPackage);
  CurEditor.Show;
  Result:=mrOk;
end;

function TPkgManager.DoShowOpenInstalledPckDlg: TModalResult;
var
  APackage: TLazPackage;
begin
  Result:=ShowOpenInstalledPkgDlg(APackage);
  if (Result<>mrOk) then exit;
  Result:=DoOpenPackage(APackage,[],false);
end;

function TPkgManager.DoOpenPackage(APackage: TLazPackage;
  Flags: TPkgOpenFlags; ShowAbort: boolean): TModalResult;
var
  CurEditor: TPackageEditorForm;
  AFilename: String;
begin
  AFilename:=APackage.Filename;
  
  // revert: if possible and wanted
  if (pofRevert in Flags) and (FileExistsCached(AFilename)) then begin
    Result:=DoOpenPackageFile(AFilename,Flags,ShowAbort);
    exit;
  end;

  // open a package editor
  CurEditor:=PackageEditors.OpenEditor(APackage);
  CurEditor.ShowOnTop;
  
  // add to recent packages
  if (pofAddToRecent in Flags) then begin
    AFilename:=APackage.Filename;
    if FileExistsCached(AFilename) then begin
      AddToRecentList(AFilename,EnvironmentOptions.RecentPackageFiles,
                      EnvironmentOptions.MaxRecentPackageFiles);
      SetRecentPackagesMenu;
    end;
  end;

  Result:=mrOk;
end;

function TPkgManager.DoOpenPackageWithName(const APackageName: string;
  Flags: TPkgOpenFlags; ShowAbort: boolean): TModalResult;
var
  APackage: TLazPackage;
begin
  APackage:=PackageGraph.FindAPackageWithName(APackageName,nil);
  if APackage=nil then
    Result:=mrCancel
  else
    Result:=DoOpenPackage(APackage,Flags,ShowAbort);
end;

function TPkgManager.DoOpenPackageFile(AFilename: string; Flags: TPkgOpenFlags;
  ShowAbort: boolean): TModalResult;
var
  APackage: TLazPackage;
  XMLConfig: TXMLConfig;
  AlternativePkgName: String;
  Code: TCodeBuffer;
  OpenEditor: Boolean;
  
  procedure DoQuestionDlg(const Caption, Message: string);
  begin
    if pofMultiOpen in Flags then
      Result:=IDEQuestionDialog(Caption, Message,
        mtError, [mrIgnore, lisPkgMangSkipThisPackage, mrAbort])
    else
      Result:=IDEQuestionDialog(Caption, Message,
        mtError,[mrAbort])
  end;
begin
  // replace macros
  if pofConvertMacros in Flags then begin
    if not GlobalMacroList.SubstituteStr(AFilename) then exit(mrCancel);
  end;

  AFilename:=CleanAndExpandFilename(AFilename);
  
  // check file extension
  if (CompareFileExt(AFilename,'.lpk',false)<>0)
  and (not (pofRevert in Flags)) then begin
    DoQuestionDlg(lisPkgMangInvalidFileExtension,
      Format(lisPkgMangTheFileIsNotALazarusPackage, ['"', AFilename, '"']));
    RemoveFromRecentList(AFilename,EnvironmentOptions.RecentPackageFiles);
    SetRecentPackagesMenu;
    exit;
  end;
  
  // check filename
  AlternativePkgName:=ExtractFileNameOnly(AFilename);
  if (not (pofRevert in Flags))
  and ((AlternativePkgName='') or (not IsValidIdent(AlternativePkgName)))
  then begin
    DoQuestionDlg(lisPkgMangInvalidPackageFilename,
      Format(lisPkgMangThePackageFileNameInIsNotAValidLazarusPackageName, ['"',
        AlternativePkgName, '"', #13, '"', AFilename, '"']));
    RemoveFromRecentList(AFilename,EnvironmentOptions.RecentPackageFiles);
    SetRecentPackagesMenu;
    exit;
  end;

  // add to recent packages
  if pofAddToRecent in Flags then begin
    AddToRecentList(AFilename,EnvironmentOptions.RecentPackageFiles,
                    EnvironmentOptions.MaxRecentPackageFiles);
    SetRecentPackagesMenu;
  end;

  OpenEditor:=true;

  // check if package is already loaded
  APackage:=PackageGraph.FindPackageWithFilename(AFilename);
  if (APackage=nil) or (pofRevert in Flags) then begin
    // package not yet loaded or it should be reloaded
    
    if (pofRevert in Flags) and (APackage.Editor=nil) then
      OpenEditor:=false;
    
    if not FileExistsUTF8(AFilename) then begin
      IDEMessageDialog(lisFileNotFound,
        Format(lisPkgMangFileNotFound, ['"', AFilename, '"']),
        mtError,[mbCancel]);
      RemoveFromRecentList(AFilename,EnvironmentOptions.RecentPackageFiles);
      SetRecentPackagesMenu;
      Result:=mrCancel;
      exit;
    end;

    // create a new package
    Result:=mrCancel;
    APackage:=TLazPackage.Create;
    try

      // load the package file
      try
        XMLConfig:=TXMLConfig.Create(nil);
        try
          APackage.Filename:=AFilename;
          Result:=LoadXMLConfigFromCodeBuffer(AFilename,XMLConfig,
                               Code,[lbfUpdateFromDisk,lbfRevert],ShowAbort);
          if Result<>mrOk then exit;
          APackage.LPKSource:=Code;
          APackage.LoadFromXMLConfig(XMLConfig,'Package/');
        finally
          XMLConfig.Free;
        end;
      except
        on E: Exception do begin
          DoQuestionDlg(lisPkgMangErrorReadingPackage,
            Format(lisPkgUnableToReadPackageFileError, ['"', AFilename, '"',
              #13, E.Message]));
          exit;
        end;
      end;

      // newly loaded is not modified
      APackage.Modified:=false;

      // check if package name and file name correspond
      if (SysUtils.CompareText(AlternativePkgName,APackage.Name)<>0) then begin
        Result:=IDEMessageDialog(lisPkgMangFilenameDiffersFromPackagename,
          Format(lisPkgMangTheFilenameDoesNotCorrespondToThePackage, ['"',
            ExtractFileName(AFilename), '"', '"', APackage.Name, '"', #13, '"',
            AlternativePkgName, '"']),
          mtConfirmation,[mbYes,mbCancel,mbAbort]);
        if Result<>mrYes then exit;
        APackage.Name:=AlternativePkgName;
      end;
      
      // integrate it into the graph
      Result:=AddPackageToGraph(APackage,pofRevert in Flags);
    finally
      if Result<>mrOk then APackage.Free;
    end;
  end;

  if OpenEditor then
    Result:=DoOpenPackage(APackage,[],ShowAbort)
  else
    Result:=mrOk;

  PkgLinks.SaveUserLinks;

  // the source editor highlighting depends on the compiler mode
  MainIDEInterface.UpdateHighlighters;
end;

function TPkgManager.DoSavePackage(APackage: TLazPackage;
  Flags: TPkgSaveFlags): TModalResult;
var
  XMLConfig: TXMLConfig;
  PkgLink: TPackageLink;
  Code: TCodeBuffer;
begin
  // do not save during compilation
  if not (MainIDE.ToolStatus in [itNone,itDebugger]) then begin
    Result:=mrAbort;
    exit;
  end;
  
  if APackage.IsVirtual then Include(Flags,psfSaveAs);

  // check if package needs saving
  if (not (psfSaveAs in Flags))
  and (not APackage.ReadOnly) and (not APackage.Modified)
  and FileExistsUTF8(APackage.Filename) then begin
    Result:=mrOk;
    exit;
  end;

  // ask user if package should be saved
  if psfAskBeforeSaving in Flags then begin
    Result:=IDEMessageDialog(lisPkgMangSavePackage2,
               Format(lisPkgMangPackageChangedSave, ['"', APackage.IDAsString,
                 '"']),
               mtConfirmation,[mbYes,mbNo,mbAbort]);
    if (Result=mrNo) then Result:=mrIgnore;
    if Result<>mrYes then exit;
  end;
  
  // warn about missing files
  Result:=WarnAboutMissingPackageFiles(APackage);
  if Result<>mrOk then exit;

  // save editor files to codetools
  MainIDE.SaveSourceEditorChangesToCodeCache(-1);

  // save package
  if (psfSaveAs in Flags) then begin
    Result:=DoShowSavePackageAsDialog(APackage);
    if Result<>mrOk then exit;
  end;
  
  // backup old file
  Result:=BuildBoss.BackupFile(APackage.Filename);
  if Result=mrAbort then exit;

  // delete ambiguous files
  Result:=BuildBoss.DeleteAmbiguousFiles(APackage.Filename);
  if Result=mrAbort then exit;

  // save
  try
    XMLConfig:=TXMLConfig.Create(nil);
    try
      XMLConfig.Clear;
      APackage.SaveToXMLConfig(XMLConfig,'Package/');
      Code:=nil;
      Result:=SaveXMLConfigToCodeBuffer(APackage.Filename,XMLConfig,Code);
      if Result<>mrOk then exit;
      APackage.LPKSource:=Code;
      PkgLink:=PkgLinks.AddUserLink(APackage);
      if PkgLink<>nil then begin
        PkgLink.FileDate:=FileDateToDateTime(FileAgeUTF8(APackage.Filename));
        PkgLink.FileDateValid:=true;
        PkgLinks.SaveUserLinks;
      end;
    finally
      XMLConfig.Free;
    end;
  except
    on E: Exception do begin
      Result:=IDEMessageDialog(lisPkgMangErrorWritingPackage,
        Format(lisPkgMangUnableToWritePackageToFileError, ['"',
          APackage.IDAsString, '"', #13, '"', APackage.Filename, '"', #13,
          E.Message]),
        mtError,[mbAbort,mbCancel]);
      exit;
    end;
  end;

  // success
  APackage.Modified:=false;
  // add to recent
  if (psfSaveAs in Flags) then begin
    AddFileToRecentPackages(APackage.Filename);
  end;

  if APackage.Editor<>nil then APackage.Editor.UpdateAll;
  Result:=mrOk;
end;

function TPkgManager.DoShowPackageGraph: TModalResult;
begin
  if PackageGraphExplorer=nil then begin
    PackageGraphExplorer:=TPkgGraphExplorerDlg.Create(Application);
    PackageGraphExplorer.OnOpenPackage:=@PackageGraphExplorerOpenPackage;
    PackageGraphExplorer.OnOpenProject:=@PackageGraphExplorerOpenProject;
    PackageGraphExplorer.OnUninstallPackage:=@PackageGraphExplorerUninstallPackage;
  end;
  PackageGraphExplorer.ShowOnTop;
  Result:=mrOk;
end;

function TPkgManager.DoCloseAllPackageEditors: TModalResult;
var
  APackage: TLazPackage;
begin
  while PackageEditors.Count>0 do begin
    APackage:=PackageEditors.Editors[PackageEditors.Count-1].LazPackage;
    Result:=DoClosePackageEditor(APackage);
    if Result<>mrOk then exit;
  end;
  Result:=mrOk;
end;

procedure TPkgManager.DoShowPackageGraphPathList(PathList: TFPList);
begin
  if DoShowPackageGraph<>mrOk then exit;
  PackageGraphExplorer.ShowPath(PathList);
end;

function TPkgManager.ShowBrokenDependenciesReport(Dependencies: TFPList
  ): TModalResult;
var
  Msg: String;
  i: Integer;
  ADependency: TPkgDependency;
begin
  Result:=mrOk;
  if (Dependencies=nil) or (Dependencies.Count=0) then exit;
  if Dependencies.Count=1 then
    Msg:=lisPkgMangTheFollowingPackageFailedToLoad
  else
    Msg:=lisPkgMangTheFollowingPackagesFailedToLoad;
  Msg:=Msg+#13#13;
  for i:=0 to Dependencies.Count-1 do begin
    ADependency:=TPkgDependency(Dependencies[i]);
    Msg:=Msg+ADependency.AsString+#13;
  end;
  
  // give some hints
  ADependency:=TPkgDependency(Dependencies[0]);
  if (ADependency.Owner is TProject) then begin
    // broken dependency used by project -> show project inspector
    if ADependency.Owner=Project1 then begin
      Result:=MainIDE.DoShowProjectInspector;
      Msg:=Format(lisSeeProjectProjectInspector, [Msg]);
    end;
  end;
  
  Result:=IDEMessageDialog(lisMissingPackages, Msg, mtError, [mbOk]);
end;

procedure TPkgManager.RebuildDefineTemplates;
begin
  PackageGraph.RebuildDefineTemplates;
end;

procedure TPkgManager.LazarusSrcDirChanged;
begin
  if PackageGraph=nil then exit;

end;

function TPkgManager.DoCompileProjectDependencies(AProject: TProject;
  Flags: TPkgCompileFlags): TModalResult;
begin
  // check graph for circles and broken dependencies
  if not (pcfDoNotCompileDependencies in Flags) then begin
    Result:=CheckPackageGraphForCompilation(nil,
                                            AProject.FirstRequiredDependency,
                                            AProject.ProjectDirectory);
    if Result<>mrOk then exit;
  end;
  
  // save all open files
  if not (pcfDoNotSaveEditorFiles in Flags) then begin
    Result:=MainIDE.DoSaveForBuild;
    if Result<>mrOk then exit;
  end;

  PackageGraph.BeginUpdate(false);
  try
    // automatically compile required packages
    if not (pcfDoNotCompileDependencies in Flags) then begin
      Result:=PackageGraph.CompileRequiredPackages(nil,
                                      AProject.FirstRequiredDependency,
                                      AProject.CompilerOptions.Globals,
                                      [pupAsNeeded]);
      if Result<>mrOk then exit;
    end;
  finally
    PackageGraph.EndUpdate;
  end;
  
  Result:=mrOk;
end;

function TPkgManager.DoCompilePackage(APackage: TLazPackage;
  Flags: TPkgCompileFlags; Globals: TGlobalCompilerOptions): TModalResult;
begin
  Result:=mrCancel;
  
  DebugLn('TPkgManager.DoCompilePackage A ',APackage.IDAsString,' Flags=',PkgCompileFlagsToString(Flags));
  
  if APackage.AutoCreated then exit;

  Result:=MainIDE.PrepareForCompile;
  if Result<>mrOk then exit;
  
  // check graph for circles and broken dependencies
  if not (pcfDoNotCompileDependencies in Flags) then begin
    Result:=CheckPackageGraphForCompilation(APackage,nil,APackage.Directory);
    if Result<>mrOk then exit;
  end;
  
  // save all open files
  {$IFDEF VerboseSaveForBuild}
  DebugLn('TPkgManager.DoCompilePackage  ',APackage.IDAsString,' Flags=',PkgCompileFlagsToString(Flags));
  {$ENDIF}
  if not (pcfDoNotSaveEditorFiles in Flags) then begin
    Result:=MainIDE.DoSaveForBuild;
    if Result<>mrOk then exit;
  end;
  
  Result:=WarnAboutMissingPackageFiles(APackage);
  if Result<>mrOk then exit;

  Result:=PackageGraph.CompilePackage(APackage,Flags,false,Globals);
end;

function TPkgManager.DoCreatePackageMakefile(APackage: TLazPackage
  ): TModalResult;
begin
  Result:=DoCompilePackage(APackage,[pcfDoNotCompileDependencies,
                           pcfDoNotCompilePackage,pcfCreateMakefile],nil);
end;

function TPkgManager.OnRenameFile(const OldFilename, NewFilename: string;
  IsPartOfProject: boolean): TModalResult;
var
  OldPackage: TLazPackage;
  OldPkgFile: TPkgFile;
  NewPkgFile: TPkgFile;
begin
  Result:=mrOk;
  if (OldFilename=NewFilename) then
    exit;
  //debugln('TPkgManager.OnRenameFile A OldFilename="',OldFilename,'" New="',NewFilename,'"');
  OldPkgFile:=PackageGraph.FindFileInAllPackages(OldFilename,true,
                                                 not IsPartOfProject);
  if (OldPkgFile=nil) or (OldPkgFile.LazPackage.ReadOnly) then
    exit;
  OldPackage:=OldPkgFile.LazPackage;
  debugln('TPkgManager.OnRenameFile A OldPackage="',OldPackage.Name);
  NewPkgFile:=PackageGraph.FindFileInAllPackages(NewFilename,true,false);
  if (NewPkgFile<>nil) and (OldPackage<>NewPkgFile.LazPackage) then exit;

  Result:=IDEMessageDialog(lisPkgMangRenameFileInPackage,
    Format(lisPkgMangThePackageOwnsTheFileShouldTheFileBeRenamed, [
      OldPackage.IDAsString, #13, '"', OldFilename, '"', #13]),
    mtConfirmation,[mbYes,mbNo,mbAbort]);
  if Result=mrNo then begin
    Result:=mrOk;
    exit;
  end;
  if Result<>mrYes then exit;
  
  OldPkgFile.Filename:=NewFilename;
  if OldPackage.Editor<>nil then OldPackage.Editor.UpdateAll;
  OldPackage.Modified:=true;

  Result:=mrOk;
end;

{------------------------------------------------------------------------------
  function TPkgManager.FindIncludeFileInProjectDependencies(Project1: TProject;
    const Filename: string): string;
    
  Search filename in the include paths of all required packages
------------------------------------------------------------------------------}
function TPkgManager.FindIncludeFileInProjectDependencies(Project1: TProject;
  const Filename: string): string;
var
  APackage: TLazPackage;
  IncPath: String;
  PkgList: TFPList;
  i: Integer;
begin
  Result:='';
  if FilenameIsAbsolute(Filename) then begin
    Result:=Filename;
    exit;
  end;
  PkgList:=nil;
  PackageGraph.GetAllRequiredPackages(Project1.FirstRequiredDependency,PkgList);
  if PkgList=nil then exit;
  try
    for i:=0 to PkgList.Count-1 do begin
      APackage:=TLazPackage(PkgList[i]);
      IncPath:=APackage.CompilerOptions.GetIncludePath(false);
      Result:=SearchFileInPath(Filename,APackage.Directory,IncPath,';',
                               ctsfcDefault);
      if Result<>'' then exit;
    end;
  finally
    PkgList.Free;
  end;
end;

function TPkgManager.AddUnitDependenciesForComponentClasses(
  const UnitFilename: string; ComponentClassnames: TStrings;
  Quiet: boolean): TModalResult;
var
  UnitBuf: TCodeBuffer;
  UnitNames: TStringList;
  Packages: TFPList;
  MissingDependencies: TObjectArray;
  
  function LoadAndParseUnitBuf: TModalResult;
  begin
    if not CodeToolBoss.GatherExternalChanges then begin
      Result:=mrCancel;
      MainIDE.DoJumpToCodeToolBossError;
      exit;
    end;
    UnitBuf:=CodeToolBoss.LoadFile(UnitFilename,false,false);
    if UnitBuf=nil then begin
      Result:=IDEMessageDialog(lisErrorLoadingFile,
        Format(lisLoadingFailed, [UnitFilename]),
        mtError,[mbCancel,mbAbort]);
      exit;
    end;
    Result:=mrOk;
  end;

  function CollectNeededUnitnamesAndPackages: TModalResult;
  var
    i: Integer;
    RegComp: TRegisteredComponent;
    NewUnitName: String;
    PkgFile: TPkgFile;
    ClassUnitInfo: TUnitInfo;
  begin
    for i:=0 to ComponentClassnames.Count-1 do begin
      //DebugLn(['CollectNeededUnitnamesAndPackages ComponentClassnames[i]=',ComponentClassnames[i]]);
      RegComp:=IDEComponentPalette.FindComponent(ComponentClassnames[i]);
      NewUnitName:='';
      if (RegComp<>nil) then begin
        if RegComp.ComponentClass<>nil then
          NewUnitName:=GetClassUnitName(RegComp.ComponentClass);
        //DebugLn(['CollectNeededUnitnamesAndPackages AAA1 NewUnitName=',NewUnitName]);
        if NewUnitName='' then
          NewUnitName:=RegComp.GetUnitName;
      end else begin
        ClassUnitInfo:=Project1.UnitWithComponentClassName(ComponentClassnames[i]);
        if ClassUnitInfo<>nil then
          NewUnitName:=ClassUnitInfo.UnitName;
      end;
      if (NewUnitName<>'') and (UnitNames.IndexOf(NewUnitName)<0) then begin
        // new needed unit
        UnitNames.Add(NewUnitName);
        // find package
        PkgFile:=PackageGraph.FindUnitInAllPackages(NewUnitName,true);
        //DebugLn(['CollectNeededUnitnamesAndPackages AAA2 PkgFile=',PkgFile<>nil]);
        if (PkgFile=nil) and (RegComp is TPkgComponent) then begin
          PkgFile:=TPkgComponent(RegComp).PkgFile;
          if (PkgFile<>nil) and (PkgFile.LazPackage<>nil)
          and (Packages.IndexOf(PkgFile.LazPackage)<0) then
            Packages.Add(PkgFile.LazPackage);
        end;
      end;
    end;
    Result:=mrOk;
  end;

  function RemoveExistingUnitnames: TModalResult;
  var
    ImplementationUsesSection: TStrings;
    MainUsesSection: TStrings;
    j: LongInt;
    i: Integer;
  begin
    Result:=LoadAndParseUnitBuf;
    if Result<>mrOk then exit;
    if not CodeToolBoss.FindUsedUnitNames(UnitBuf,MainUsesSection,
      ImplementationUsesSection)
    then begin
      MainIDE.DoJumpToCodeToolBossError;
      exit;
    end;
    for i:=0 to MainUsesSection.Count-1 do begin
      j:=UnitNames.IndexOf(MainUsesSection[i]);
      if j>=0 then UnitNames.Delete(j);
    end;
    MainUsesSection.Free;
    ImplementationUsesSection.Free;
    Result:=mrOk;
  end;
  
  function AskUser: TModalResult;
  var
    UsesAdditions: String;
    UnitOwner: TObject;
    RequiredPackage: TLazPackage;
    i: Integer;
    PackageAdditions: String;
    Msg: String;
  begin
    UsesAdditions:='';
    for i:=0 to UnitNames.Count-1 do begin
      if UsesAdditions<>'' then UsesAdditions:=UsesAdditions+', ';
      UsesAdditions:=UsesAdditions+UnitNames[i];
    end;
    //DebugLn('TPkgManager.AddUnitDependenciesForComponentClasses UsesAdditions=',UsesAdditions);
    PackageAdditions:='';
    if MissingDependencies<>nil then begin
      for i:=0 to MissingDependencies.Count-1 do begin
        UnitOwner:=TObject(MissingDependencies[i]);
        RequiredPackage:=TLazPackage(MissingDependencies.Objects[i]);
        if UnitOwner is TProject then begin
          PackageAdditions:=Format(
            lisPkgMangAddingNewDependencyForProjectPackage, [PackageAdditions,
            TProject(UnitOwner).Title, RequiredPackage.Name, #13#13]);
        end else if UnitOwner is TLazPackage then begin
          PackageAdditions:=Format(
            lisPkgMangAddingNewDependencyForPackagePackage, [PackageAdditions,
            TLazPackage(UnitOwner).Name, RequiredPackage.Name, #13#13]);
        end;
      end;
    end;
    //DebugLn('TPkgManager.AddUnitDependenciesForComponentClasses PackageAdditions=',PackageAdditions);
    Msg:='';
    if UsesAdditions<>'' then begin
      Msg:=Format(lisPkgMangTheFollowingUnitsWillBeAddedToTheUsesSectionOf, [
        Msg, #13, UnitFilename, #13, UsesAdditions, #13#13]);
    end;
    if PackageAdditions<>'' then begin
      Msg:=Msg+PackageAdditions;
    end;
    if Msg<>'' then begin
      Result:=IDEMessageDialog(lisConfirmChanges,
        Msg,mtConfirmation,[mbOk,mbAbort]);
      exit;
    end;
    Result:=mrOk;
  end;
  
  function AddDependencies: TModalResult;
  var
    i: Integer;
    UnitOwner: TObject;
    RequiredPackage: TLazPackage;
  begin
    if MissingDependencies<>nil then begin
      for i:=0 to MissingDependencies.Count-1 do begin
        UnitOwner:=TObject(MissingDependencies[i]);
        RequiredPackage:=TLazPackage(MissingDependencies.Objects[i]);
        if UnitOwner is TProject then begin
          DebugLn('TPkgManager.AddUnitDependenciesForComponentClasses Adding Project Dependency ',TProject(UnitOwner).Title,' -> ',RequiredPackage.Name);
          AddProjectDependency(TProject(UnitOwner),RequiredPackage);
        end else if UnitOwner is TLazPackage then begin
          DebugLn('TPkgManager.AddUnitDependenciesForComponentClasses Adding Package Dependency ',TLazPackage(UnitOwner).Name,' -> ',RequiredPackage.Name);
          PackageGraph.AddDependencyToPackage(TLazPackage(UnitOwner),
                                              RequiredPackage);
        end;
      end;
    end;
    Result:=mrOk;
  end;

  function AddUsedUnits: TModalResult;
  var
    i: Integer;
  begin
    Result:=LoadAndParseUnitBuf;
    if Result<>mrOk then exit;
    for i:=0 to UnitNames.Count-1 do begin
      DebugLn('TPkgManager.AddUnitDependenciesForComponentClasses Extending Uses ',UnitBuf.Filename,' ',UnitNames[i]);
      if not CodeToolBoss.AddUnitToMainUsesSection(UnitBuf,UnitNames[i],'') then
        MainIDE.DoJumpToCodeToolBossError;
    end;
    Result:=mrOk;
  end;

begin
  Result:=mrCancel;
  UnitNames:=TStringList.Create;
  Packages:=TFPList.Create;
  MissingDependencies:=nil;
  try
  
    Result:=CollectNeededUnitnamesAndPackages;
    if Result<>mrOk then exit;
    
    Result:=RemoveExistingUnitnames;
    if Result<>mrOk then exit;
    
    Result:=GetMissingDependenciesForUnit(UnitFilename,ComponentClassnames,
                                          MissingDependencies);
    if Result<>mrOk then exit;
    if (UnitNames.Count=0)
    and ((MissingDependencies=nil) or (MissingDependencies.Count=0)) then begin
      // no change needed
      Result:=mrOk;
      exit;
    end;

    if not Quiet then begin
      Result:=AskUser;
      if Result<>mrOk then exit;
    end;
    
    Result:=AddDependencies;
    if Result<>mrOk then exit;

    Result:=AddUsedUnits;
    if Result<>mrOk then exit;

    Result:=mrOk;
  finally
    UnitNames.Free;
    Packages.Free;
    MissingDependencies.Free;
  end;
end;

function TPkgManager.GetMissingDependenciesForUnit(
  const UnitFilename: string; ComponentClassnames: TStrings;
  var List: TObjectArray): TModalResult;
// returns a list of packages needed to use the Component in the unit
var
  UnitOwners: TFPList;
  UnitOwner: TObject;
  FirstDependency: TPkgDependency;
  CurClassID: Integer;
  CurOwnerID: Integer;
  CurCompClass: string;
  CurRegisteredComponent: TRegisteredComponent;
  PkgFile: TPkgFile;
  RequiredPackage: TLazPackage;
  CurUnitName: String;
begin
  Result:=mrCancel;
  List:=nil;
  UnitOwners:=GetOwnersOfUnit(UnitFilename);
  if (UnitOwners<>nil) then begin
    for CurOwnerID:=0 to UnitOwners.Count-1 do begin
      UnitOwner:=TObject(UnitOwners[CurOwnerID]);
      if UnitOwner is TProject then
        FirstDependency:=TProject(UnitOwner).FirstRequiredDependency
      else if UnitOwner is TLazPackage then
        FirstDependency:=TLazPackage(UnitOwner).FirstRequiredDependency
      else
        FirstDependency:=nil;
      for CurClassID:=0 to ComponentClassnames.Count-1 do begin
        CurCompClass:=ComponentClassnames[CurClassID];
        CurRegisteredComponent:=IDEComponentPalette.FindComponent(CurCompClass);
        if CurRegisteredComponent is TPkgComponent then begin
          CurUnitName:='';
          if CurRegisteredComponent.ComponentClass<>nil then
            CurUnitName:=GetClassUnitName(CurRegisteredComponent.ComponentClass);
          //DebugLn(['TPkgManager.GetMissingDependenciesForUnit AAA1 CurUnitName=',CurUnitName]);
          if CurUnitName='' then
            CurUnitName:=CurRegisteredComponent.GetUnitName;
          PkgFile:=PackageGraph.FindUnitInAllPackages(CurUnitName,true);
          //DebugLn(['TPkgManager.GetMissingDependenciesForUnit AAA2 PkgFile=',PkgFile<>nil]);
          if PkgFile=nil then
            PkgFile:=TPkgComponent(CurRegisteredComponent).PkgFile;
          if PkgFile<>nil then begin
            RequiredPackage:=PkgFile.LazPackage;
            if (RequiredPackage<>nil)
            and (RequiredPackage<>UnitOwner)
            and (FindCompatibleDependencyInList(FirstDependency,pdlRequires,
              RequiredPackage)=nil)
            and (PackageGraph.FindPackageProvidingName(FirstDependency,
              RequiredPackage.Name)=nil)
            then begin
              if List=nil then List:=TObjectArray.Create;
              List.AddObject(UnitOwner,RequiredPackage);
              //debugln(['TPkgManager.GetMissingDependenciesForUnit A ',UnitOwner.ClassName,' ',RequiredPackage.Name]);
              //if TObject(List[List.Count-1])<>UnitOwner then RaiseException('A');
              //if TObject(List.Objects[List.Count-1])<>RequiredPackage then RaiseException('B');
            end;
          end;
        end;
      end;
    end;
    UnitOwners.Free;
  end else begin
    DebugLn(['TPkgManager.GetMissingDependenciesForUnit WARNING: unit has no owner: ',UnitFilename]);
  end;
  Result:=mrOk;
end;

function TPkgManager.GetOwnersOfUnit(const UnitFilename: string): TFPList;
begin
  Result:=GetPossibleOwnersOfUnit(UnitFilename,[]);
end;

procedure TPkgManager.ExtendOwnerListWithUsedByOwners(OwnerList: TFPList);
// use items (packages and projects) in OwnerList as leaves and create the
// list of all packages and projects using them.
// The result will be the topologically sorted list of projects and packages
// using the projects/packages in OwnerList, beginning with the top levels.
var
  AddedNonPackages: TFPList;

  procedure AddUsedByOwners(ADependenyOwner: TObject);
  var
    LazPackage: TLazPackage;
    Dependency: TPkgDependency;
  begin
    if ADependenyOwner is TProject then begin
      if AddedNonPackages.IndexOf(ADependenyOwner)>=0 then exit;
      AddedNonPackages.Add(ADependenyOwner);
      OwnerList.Add(ADependenyOwner);
    end else if ADependenyOwner is TLazPackage then begin
      LazPackage:=TLazPackage(ADependenyOwner);
      if lpfVisited in LazPackage.Flags then exit;
      LazPackage.Flags:=LazPackage.Flags+[lpfVisited];
      Dependency:=LazPackage.FirstUsedByDependency;
      while Dependency<>nil do begin
        AddUsedByOwners(Dependency.Owner);
        Dependency:=Dependency.NextUsedByDependency;
      end;
      OwnerList.Add(LazPackage);
    end;
  end;
  
var
  i: Integer;
  OldOwnerList: TFPList;
begin
  OldOwnerList:=TFPList.Create;
  for i:=0 to OwnerList.Count-1 do
    OldOwnerList.Add(OwnerList[i]);
  OwnerList.Clear;
  AddedNonPackages:=TFPList.Create;
  PackageGraph.MarkAllPackagesAsNotVisited;
  for i:=0 to OldOwnerList.Count-1 do
    AddUsedByOwners(TObject(OldOwnerList[i]));
  AddedNonPackages.Free;
  OldOwnerList.Free;
end;

function TPkgManager.GetSourceFilesOfOwners(OwnerList: TFPList): TStrings;

  procedure AddFile(TheOwner: TObject; const Filename: string);
  begin
    if Result=nil then Result:=TStringList.Create;
    Result.AddObject(Filename,TheOwner);
  end;

var
  CurOwner: TObject;
  CurPackage: TLazPackage;
  CurPkgFile: TPkgFile;
  CurProject: TProject;
  CurUnit: TUnitInfo;
  i: Integer;
  j: Integer;
begin
  Result:=nil;
  if OwnerList=nil then exit;
  for i:=0 to OwnerList.Count-1 do begin
    CurOwner:=TObject(OwnerList[i]);
    if CurOwner is TLazPackage then begin
      CurPackage:=TLazPackage(CurOwner);
      for j:=0 to CurPackage.FileCount-1 do begin
        CurPkgFile:=CurPackage.Files[j];
        if CurPkgFile.FileType in PkgFileUnitTypes then
          AddFile(CurOwner,CurPkgFile.Filename);
      end;
    end else if CurOwner is TProject then begin
      CurProject:=TProject(CurOwner);
      CurUnit:=CurProject.FirstPartOfProject;
      while CurUnit<>nil do begin
        if FilenameIsPascalSource(CurUnit.Filename) then
          AddFile(CurOwner,CurUnit.Filename);
        CurUnit:=CurUnit.NextPartOfProject;
      end;
    end;
  end;
end;

function TPkgManager.GetPossibleOwnersOfUnit(const UnitFilename: string;
  Flags: TPkgIntfOwnerSearchFlags): TFPList;
var
  SrcDir: String;// ExtractFilePath(UnitFilename);

  procedure SearchInProject(AProject: TProject);
  var
    BaseDir: String;
    ProjectDirs: String;
    Add: Boolean;
  begin
    if AProject=nil then exit;
    Add:=false;
    if not (piosfExcludeOwned in Flags) then begin
      //DebugLn(['SearchInProject ',AProject.ProjectInfoFile,' UnitFilename=',UnitFilename]);
      if AProject.UnitInfoWithFilename(UnitFilename,
        [pfsfResolveFileLinks,pfsfOnlyProjectFiles])<>nil
      then
        Add:=true;
    end;
    if (piosfIncludeSourceDirectories in Flags)
    and FilenameIsAbsolute(UnitFilename) then begin
      // search in project source directories
      BaseDir:=ExtractFilePath(AProject.ProjectInfoFile);
      if BaseDir<>'' then begin
        ProjectDirs:=AProject.LazCompilerOptions.OtherUnitFiles+';.';
        if not IDEMacros.CreateAbsoluteSearchPath(ProjectDirs,BaseDir) then exit;
        if FindPathInSearchPath(PChar(SrcDir),length(SrcDir),
          PChar(ProjectDirs),length(ProjectDirs))<>nil
        then
          Add:=true;
      end;
    end;
    if Add then
      Result.Add(AProject);
  end;

var
  PkgFile: TPkgFile;
  CurPackage: TLazPackage;
  i: Integer;
begin
  //DebugLn(['TPkgManager.GetPossibleOwnersOfUnit ',UnitFilename]);
  Result:=TFPList.Create;

  SrcDir:=ExtractFilePath(UnitFilename);

  SearchInProject(Project1);
  
  // find all packages owning file
  if piosfIncludeSourceDirectories in Flags then begin
    PackageGraph.FindPossibleOwnersOfUnit(UnitFilename,Result);
  end else if not (piosfExcludeOwned in Flags) then begin
    PkgFile:=PackageGraph.FindFileInAllPackages(UnitFilename,true,true);
    if (PkgFile<>nil) and (PkgFile.LazPackage<>nil) then
      Result.Add(PkgFile.LazPackage);
    // check package source files (they usually do not have a TPkgFile)
    for i:=0 to PackageGraph.Count-1 do begin
      CurPackage:=PackageGraph.Packages[i];
      if (CompareFilenames(UnitFilename,CurPackage.GetSrcFilename)=0)
      and (Result.IndexOf(CurPackage)<0) then
        Result.Add(CurPackage);
    end;
  end;

  // clean up
  if Result.Count=0 then
    FreeThenNil(Result);
end;

function TPkgManager.GetPackageOfCurrentSourceEditor: TPkgFile;
var
  SrcEdit: TSourceEditor;
begin
  SrcEdit:=SourceNotebook.GetActiveSE;
  if SrcEdit<>nil then begin
    Result:=SearchFile(SrcEdit.Filename,[],nil);
  end else
    SrcEdit:=nil;
end;

function TPkgManager.AddDependencyToOwners(OwnerList: TFPList;
  APackage: TLazPackage; OnlyTestIfPossible: boolean): TModalResult;
var
  i: Integer;
  Item: TObject;
  NewDependency: TPkgDependency;
  ADependency: TPkgDependency;
begin
  if not OnlyTestIfPossible then begin
    Result:=AddDependencyToOwners(OwnerList,APackage,true);
    if Result<>mrOk then exit;
  end;

  Result:=mrCancel;
  for i:=0 to OwnerList.Count-1 do begin
    Item:=TObject(OwnerList[i]);
    if Item=APackage then continue;
    if Item is TProject then begin
      Result:=AddProjectDependency(TProject(Item),APackage,OnlyTestIfPossible);
      if Result<>mrOk then exit;
    end else if Item is TLazPackage then begin
      NewDependency:=TPkgDependency.Create;
      try
        NewDependency.PackageName:=APackage.Name;
        if not CheckAddingDependency(TLazPackage(Item),NewDependency) then
          exit;
        if not OnlyTestIfPossible then begin
          ADependency:=NewDependency;
          NewDependency:=nil;
          PackageGraph.AddDependencyToPackage(TLazPackage(Item),ADependency);
        end;
      finally
        NewDependency.Free;
      end;
    end;
  end;
  Result:=mrOk;
end;

function TPkgManager.DoOpenPkgFile(PkgFile: TPkgFile): TModalResult;
var
  Filename: String;
begin
  if (PkgFile.FileType=pftVirtualUnit) then begin
    Filename:=FindVirtualUnitSource(PkgFile);
    if Filename<>'' then begin
      Result:=MainIDE.DoOpenEditorFile(Filename,-1,
                                  [ofOnlyIfExists,ofAddToRecent,ofRegularFile]);
      exit;
    end;
  end;
  Result:=MainIDE.DoOpenMacroFile(Self,PkgFile.Filename);
end;

function TPkgManager.FindVirtualUnitSource(PkgFile: TPkgFile): string;
begin
  Result:='';
  if (PkgFile.FileType=pftVirtualUnit)
  and (PkgFile.LazPackage<>nil)
  and (not FileExistsUTF8(PkgFile.Filename)) then begin
    Result:=MainIDE.FindSourceFile(PkgFile.GetShortFilename(false),
                                     PkgFile.LazPackage.Directory,[]);
  end;
end;

function TPkgManager.SearchFile(const AFilename: string;
  SearchFlags: TSearchIDEFileFlags; InObject: TObject): TPkgFile;
var
  i: Integer;
  APackage: TLazPackage;
  CurFilename: String;
begin
  if InObject is TLazPackage then begin
    APackage:=TLazPackage(InObject);
    CurFilename:=AFilename;
    APackage.ShortenFilename(CurFilename,true);
    Result:=APackage.SearchShortFilename(CurFilename,SearchFlags);
    if Result<>nil then exit;
  end;
  if not (siffDoNotCheckAllPackages in SearchFlags) then begin
    for i:=0 to PackageGraph.Count-1 do begin
      APackage:=PackageGraph[i];
      CurFilename:=AFilename;
      APackage.ShortenFilename(CurFilename,true);
      Result:=APackage.SearchShortFilename(CurFilename,SearchFlags);
      //debugln(['TPkgManager.SearchFile Pkg=',APackage.Filename,' CurFilename="',CurFilename,'" ',Result<>nil]);
      if Result<>nil then exit;
    end;
  end;
  Result:=nil;
end;

function TPkgManager.SearchUnitInDesigntimePackages(const AnUnitName: string;
  InObject: TObject): TPkgFile;
var
  i: Integer;
  APackage: TLazPackage;
begin
  if InObject is TLazPackage then begin
    APackage:=TLazPackage(InObject);
    Result:=APackage.FindUnit(AnUnitName);
    if Result<>nil then exit;
  end;
  for i:=0 to PackageGraph.Count-1 do begin
    APackage:=PackageGraph[i];
    if APackage.Installed=pitNope then continue;
    Result:=APackage.FindUnit(AnUnitName);
    if Result<>nil then exit;
  end;
  Result:=nil;
end;

function TPkgManager.AddDependencyToUnitOwners(const OwnedFilename,
  RequiredUnitname: string): TModalResult;
var
  OwnersList: TFPList;
  RequiredPkgFile: TPkgFile;
  RequiredPkg: TLazPackage;
begin
  Result:=mrCancel;
  //DebugLn(['TPkgManager.AddDependencyToUnitOwners RequiredUnitname=',RequiredUnitname,' OwnedFilename=',OwnedFilename]);

  // find needed package
  RequiredPkgFile:=SearchUnitInDesigntimePackages(RequiredUnitName,nil);
  if RequiredPkgFile=nil then begin
    DebugLn(['TPkgManager.AddDependencyToUnitOwners unit not in designtime package: ',RequiredUnitName]);
    exit;
  end;
  RequiredPkg:=RequiredPkgFile.LazPackage;

  // find owners of unit (package or project)
  OwnersList:=GetOwnersOfUnit(OwnedFilename);
  try
    if (OwnersList=nil) or (OwnersList.Count=0) then begin
      DebugLn(['TPkgManager.AddDependencyToUnitOwners Owner not found of unit ',OwnedFilename]);
      exit;
    end;
    // add package dependency
    //DebugLn(['TPkgManager.AddDependencyToUnitOwners ',dbgsName(TObject(OwnersList[0])),' ',RequiredPkg.IDAsString]);
    Result:=AddDependencyToOwners(OwnersList,RequiredPkg,false);
  finally
    OwnersList.Free;
  end;
end;

procedure TPkgManager.GetPackagesChangedOnDisk(var ListOfPackages: TFPList);
begin
  if PackageGraph=nil then exit;
  PackageGraph.GetPackagesChangedOnDisk(ListOfPackages);
end;

function TPkgManager.RevertPackages(APackageList: TFPList): TModalResult;
var
  i: Integer;
  APackage: TLazPackage;
begin
  if APackageList=nil then exit(mrOk);
  for i:=0 to APackageList.Count-1 do begin
    APackage:=TLazPackage(APackageList[i]);
    Result:=DoOpenPackageFile(APackage.Filename,[pofRevert],true);
    if Result=mrAbort then exit;
  end;
  Result:=mrOk;
end;

function TPkgManager.DoAddActiveUnitToAPackage: TModalResult;
var
  ActiveSourceEditor: TSourceEditorInterface;
  ActiveUnitInfo: TUnitInfo;
  PkgFile: TPkgFile;
  Filename: String;
  TheUnitName: String;
  HasRegisterProc: Boolean;
begin
  MainIDE.GetCurrentUnitInfo(ActiveSourceEditor,ActiveUnitInfo);
  if ActiveSourceEditor=nil then exit;

  Filename:=ActiveUnitInfo.Filename;
  
  // check if filename is absolute
  if ActiveUnitInfo.IsVirtual or (not FileExistsUTF8(Filename)) then begin
    Result:=IDEMessageDialog(lisPkgMangFileNotSaved,
      lisPkgMangPleaseSaveTheFileBeforeAddingItToAPackage,
      mtWarning,[mbCancel]);
    exit;
  end;
  
  // check if file is part of project
  if ActiveUnitInfo.IsPartOfProject then begin
    Result:=IDEMessageDialog(lisPkgMangFileIsInProject,
      Format(lisPkgMangWarningTheFileBelongsToTheCurrentProject, ['"',
        Filename, '"', #13])
      ,mtWarning,[mbIgnore,mbCancel,mbAbort]);
    if Result<>mrIgnore then exit;
  end;
  
  // check if file is already in a package
  PkgFile:=PackageGraph.FindFileInAllPackages(Filename,true,true);
  if PkgFile<>nil then begin
    Result:=IDEMessageDialog(lisPkgMangFileIsAlreadyInPackage,
      Format(lisPkgMangTheFileIsAlreadyInThePackage, ['"', Filename, '"', #13,
        PkgFile.LazPackage.IDAsString]),
      mtWarning,[mbIgnore,mbCancel,mbAbort]);
    if Result<>mrIgnore then exit;
  end;
  
  TheUnitName:='';
  HasRegisterProc:=false;
  if FilenameIsPascalUnit(Filename) then begin
    Result:=DoGetUnitRegisterInfo(Filename,TheUnitName,HasRegisterProc,false);
    if Result<>mrOk then begin
      debugln(['TPkgManager.DoAddActiveUnitToAPackage DoGetUnitRegisterInfo failed']);
      exit;
    end;
  end;
  
  Result:=ShowAddFileToAPackageDlg(Filename,TheUnitName,HasRegisterProc);
end;

function TPkgManager.WarnAboutMissingPackageFiles(APackage: TLazPackage
  ): TModalResult;
var
  i: Integer;
  AFile: TPkgFile;
  AFilename: String;
begin
  Result:=mrOk;
  for i:=0 to APackage.FileCount-1 do begin
    AFile:=APackage.Files[i];
    if AFile.FileType=pftVirtualUnit then continue;
    AFilename:=AFile.Filename;
    if System.Pos('$(',AFilename)>0 then begin
      // filename contains macros -> skip
    end;
    if (not APackage.IsVirtual) and FilenameIsAbsolute(AFilename) then
      APackage.LongenFilename(AFilename);
    if FilenameIsAbsolute(AFilename) then begin
      if not FileExistsCached(AFilename) then begin
        if not APackage.IsVirtual then
          AFilename:=CreateRelativePath(AFilename,APackage.Directory);
        Result:=IDEQuestionDialog(lisPkgMangPackageFileMissing,
          Format(lisPkgMangTheFileOfPackageIsMissing, ['"', AFilename, '"',
            #13, APackage.IDAsString]),
          mtWarning,[mrIgnore,mrAbort]);
        if Result<>mrAbort then
          Result:=mrOk;
        // one warning is enough
        exit;
      end;
    end else begin
      if not APackage.IsVirtual then begin
        // an unsaved file
        Result:=IDEQuestionDialog(lisPkgMangPackageFileNotSaved,
          Format(lisPkgMangTheFileOfPackageNeedsToBeSavedFirst, ['"',
            AFilename, '"', #13, APackage.IDAsString]),
          mtWarning, [mrIgnore, lisPkgMangIgnoreAndSavePackageNow, mrAbort]);
        if Result<>mrAbort then
          Result:=mrOk;
      end;
    end;
  end;
end;

function TPkgManager.DoInstallPackage(APackage: TLazPackage): TModalResult;
var
  PkgList: TFPList;
  
  function GetPkgListIndex(APackage: TLazPackage): integer;
  begin
    Result:=PkgList.Count-1;
    while (Result>=0) and (TLazPackage(PkgList[Result])<>APackage) do
      dec(Result);
  end;
  
var
  Dependency: TPkgDependency;
  i: Integer;
  s: String;
  NeedSaving: Boolean;
  RequiredPackage: TLazPackage;
  BuildIDEFlags: TBuildLazarusFlags;
  Msg: string;
begin
  if not MainIDE.DoResetToolStatus([rfInteractive]) then exit(mrCancel);

  PackageGraph.BeginUpdate(true);
  PkgList:=nil;
  try
    // check if package is designtime package
    if APackage.PackageType=lptRunTime then begin
      Result:=IDEMessageDialog(lisPkgMangPackageIsNoDesigntimePackage,
        Format(lisPkgMangThePackageIsARuntimeOnlyPackageRuntimeOnlyPackages, [
          APackage.IDAsString, #13]),
        mtError,[mbIgnore,mbAbort]);
      if Result<>mrIgnore then exit;
    end;
  
    // save package
    if APackage.IsVirtual or APackage.Modified then begin
      Result:=DoSavePackage(APackage,[]);
      if Result<>mrOk then exit;
    end;

    // check consistency
    Result:=CheckPackageGraphForCompilation(APackage,nil,
                                           EnvironmentOptions.LazarusDirectory);
    if Result<>mrOk then exit;
    
    // get all required packages, which will also be auto installed
    APackage.GetAllRequiredPackages(PkgList);
    if PkgList=nil then PkgList:=TFPList.Create;
    
    // remove packages already marked for installation
    for i:=PkgList.Count-1 downto 0 do begin
      RequiredPackage:=TLazPackage(PkgList[i]);
      if (RequiredPackage.AutoInstall<>pitNope) then
        PkgList.Delete(i);
    end;
    
    // now PkgList contains only the required packages that were added to the
    // list of installation packages
    // => show the user the list
    if PkgList.Count>0 then begin
      s:='';
      for i:=0 to PkgList.Count-1 do begin
        RequiredPackage:=TLazPackage(PkgList[i]);
        s:=s+RequiredPackage.IDAsString+#13;
      end;
      if PkgList.Count=0 then
        Msg:=Format(
          lisPkgMangInstallingThePackageWillAutomaticallyInstallThePac, [
          APackage.IDAsString])
      else
        Msg:=Format(
          lisPkgMangInstallingThePackageWillAutomaticallyInstallThePac2, [
          APackage.IDAsString]);
      Result:=IDEMessageDialog(lisPkgMangAutomaticallyInstalledPackages,
        Msg+#13+s,mtConfirmation,[mbOk,mbCancel,mbAbort]);
      if Result<>mrOk then exit;
    end;

    // add packages to auto installed packages
    if GetPkgListIndex(APackage)<0 then
      PkgList.Add(APackage);
    NeedSaving:=false;
    for i:=0 to PkgList.Count-1 do begin
      RequiredPackage:=TLazPackage(PkgList[i]);
      if RequiredPackage.AutoInstall=pitNope then begin
        RequiredPackage.AutoInstall:=pitStatic;
        Dependency:=RequiredPackage.CreateDependencyWithOwner(Self);
        Dependency.AddToList(PackageGraph.FirstAutoInstallDependency,pdlRequires);
        PackageGraph.OpenDependency(Dependency,false);
        NeedSaving:=true;
      end;
    end;
  finally
    PackageGraph.EndUpdate;
    PkgList.Free;
  end;

  if NeedSaving then begin
    PackageGraph.SortAutoInstallDependencies;
    SaveAutoInstallDependencies(true);
  end;

  // save IDE build configs, so user can build IDE on command line
  BuildIDEFlags:=[blfWithStaticPackages,blfDontClean,blfOnlyIDE];
  Result:=MainIDE.DoSaveBuildIDEConfigs(BuildIDEFlags);
  if Result<>mrOk then exit;

  // ask user to rebuilt Lazarus now
  Result:=IDEMessageDialog(lisPkgMangRebuildLazarus,
    Format(lisPkgMangThePackageWasMarkedForInstallationCurrentlyLazarus, [
      '"', APackage.IDAsString, '"', #13, #13, #13]),
    mtConfirmation,[mbYes,mbNo]);
  if Result<>mrYes then begin
    Result:=mrOk;
    exit;
  end;
  
  // rebuild Lazarus
  Result:=MainIDE.DoBuildLazarus(BuildIDEFlags);
  if Result<>mrOk then exit;

  Result:=mrOk;
end;

function TPkgManager.DoUninstallPackage(APackage: TLazPackage;
  Flags: TPkgUninstallFlags): TModalResult;
var
  DependencyPath: TFPList;
  ParentPackage: TLazPackage;
  Dependency: TPkgDependency;
  BuildIDEFlags: TBuildLazarusFlags;
begin
  if (APackage.Installed=pitNope) and (APackage.AutoInstall=pitNope) then exit;
  
  // check if package is required by auto install package
  DependencyPath:=PackageGraph.FindAutoInstallDependencyPath(APackage);
  if DependencyPath<>nil then begin
    DoShowPackageGraphPathList(DependencyPath);
    ParentPackage:=TLazPackage(DependencyPath[0]);
    Result:=IDEMessageDialog(lisPkgMangPackageIsRequired,
      Format(lisPkgMangThePackageIsRequiredByWhichIsMarkedForInstallation, [
        APackage.IDAsString, ParentPackage.IDAsString, #13]),
      mtError,[mbCancel,mbAbort]);
    exit;
  end;

  // confirm uninstall package
  if not (puifDoNotConfirm in Flags) then begin
    Result:=IDEMessageDialog(lisPkgMangUninstallPackage,
      Format(lisPkgMangUninstallPackage2, [APackage.IDAsString]),
      mtConfirmation,[mbYes,mbCancel,mbAbort]);
    if Result<>mrYes then exit;
  end;
  
  PackageGraph.BeginUpdate(true);
  try
    // save package
    if APackage.IsVirtual or APackage.Modified then begin
      Result:=DoSavePackage(APackage,[]);
      if Result<>mrOk then exit;
    end;

    // remove package from auto installed packages
    if APackage.AutoInstall<>pitNope then begin
      APackage.AutoInstall:=pitNope;
      Dependency:=FindCompatibleDependencyInList(PackageGraph.FirstAutoInstallDependency,
                                                 pdlRequires,APackage);
      if Dependency<>nil then begin
        Dependency.RemoveFromList(PackageGraph.FirstAutoInstallDependency,pdlRequires);
        Dependency.Free;
        PackageGraph.SortAutoInstallDependencies;
      end;
      SaveAutoInstallDependencies(true);
    end;

    // save IDE build configs, so user can build IDE on command line
    BuildIDEFlags:=[blfWithStaticPackages,blfDontClean,blfOnlyIDE];
    Result:=MainIDE.DoSaveBuildIDEConfigs(BuildIDEFlags);
    if Result<>mrOk then exit;

    if not (puifDoNotBuildIDE in Flags) then begin
      // ask user to rebuilt Lazarus now
      Result:=IDEMessageDialog(lisPkgMangRebuildLazarus,
        Format(lisPkgMangThePackageWasMarkedCurrentlyLazarus, ['"',
          APackage.IDAsString, '"', #13, #13, #13]),
        mtConfirmation,[mbYes,mbNo]);
      if Result=mrNo then begin
        Result:=mrOk;
        exit;
      end;

      // rebuild Lazarus
      Result:=MainIDE.DoBuildLazarus(BuildIDEFlags);
      if Result<>mrOk then exit;
    end;
  finally
    PackageGraph.EndUpdate;
  end;
  Result:=mrOk;
end;

function TPkgManager.DoOpenPackageSource(APackage: TLazPackage): TModalResult;
var
  Filename: String;
begin
  Result:=mrCancel;
  if APackage.IsVirtual then begin
    IDEMessageDialog(lisCCOErrorCaption,
      lisPkgMangThisIsAVirtualPackageItHasNoSourceYetPleaseSaveThe,
      mtError, [mbCancel]);
    exit;
  end;
  Filename:=APackage.GetSrcFilename;
  if (not FilenameIsAbsolute(Filename)) or (not FileExistsUTF8(Filename)) then begin
    IDEMessageDialog(lisCCOErrorCaption, lisPkgMangPleaseSaveThePackageFirst,
      mtError,[mbCancel]);
    exit;
  end;
  Result:=MainIDE.DoOpenEditorFile(Filename,-1,[ofRegularFile]);
end;

function TPkgManager.DoViewPackageToDos(APackage: TLazPackage): TModalResult;
begin
  Result:=mrOk;
  if not Assigned(frmToDo) then begin
    frmToDo:=TfrmToDo.Create(LazarusIDE.OwningComponent);
  end;
  if APackage.GetSrcFilename<>'' then
    frmToDo.MainSourceFilename:=APackage.GetSrcFilename
  else
    frmToDo.MainSourceFilename:='';

  frmToDo.ShowOnTop;
  Result:=mrOk;
end;

function TPkgManager.DoCompileAutoInstallPackages(
  Flags: TPkgCompileFlags): TModalResult;
var
  Dependency: TPkgDependency;
  OldDependency: TPkgDependency;
begin
  PackageGraph.BeginUpdate(false);
  try
    Dependency:=PackageGraph.FirstAutoInstallDependency;
    while Dependency<>nil do begin
      OldDependency:=Dependency;
      Dependency:=Dependency.NextRequiresDependency;
      if OldDependency.LoadPackageResult<>lprSuccess then begin
        Result:=IDEMessageDialog(lisProjAddPackageNotFound,
          Format(lisPkgMangThePackageIsMarkedForInstallationButCanNotBeFound, [
            '"', OldDependency.AsString, '"', #13]),
          mtError,[mbYes,mbNo,mbAbort]);
        if Result=mrNo then Result:=mrCancel;
        if Result<>mrYes then exit;
        OldDependency.RemoveFromList(PackageGraph.FirstAutoInstallDependency,pdlRequires);
        OldDependency.Free;
        SaveAutoInstallDependencies(true);
      end;
    end;
    
    // check consistency
    Result:=CheckPackageGraphForCompilation(nil,
                                PackageGraph.FirstAutoInstallDependency,
                                EnvironmentOptions.LazarusDirectory);
    if Result<>mrOk then exit;
    //DebugLn(['TPkgManager.DoCompileAutoInstallPackages LCLUnitPath=',PackageGraph.LCLPackage.CompilerOptions.GetUnitPath(true)]);

    // save all open files
    if not (pcfDoNotSaveEditorFiles in Flags) then begin
      Result:=MainIDE.DoSaveForBuild;
      if Result<>mrOk then exit;
    end;
    
    // compile all auto install dependencies
    Result:=PackageGraph.CompileRequiredPackages(nil,
                       PackageGraph.FirstAutoInstallDependency,
                       MiscellaneousOptions.BuildLazOpts.Globals,[pupAsNeeded]);
    if Result<>mrOk then exit;
    
  finally
    PackageGraph.EndUpdate;
  end;
  Result:=mrOk;
end;

function TPkgManager.DoSaveAutoInstallConfig: TModalResult;
var
  TargetDir: String;
begin
  TargetDir:=MiscellaneousOptions.BuildLazOpts.TargetDirectory;
  IDEMacros.SubstituteMacros(TargetDir);
  TargetDir:=TrimFilename(TargetDir);
  if not ForceDirectory(TargetDir) then begin
    Result:=IDEMessageDialog(lisPkgMangUnableToCreateDirectory,
      Format(lisPkgMangUnableToCreateTargetDirectoryForLazarus, [#13, '"',
        TargetDir, '"', #13]),
      mtError,[mbCancel,mbAbort]);
    exit;
  end;

  Result:=PackageGraph.SaveAutoInstallConfig;
end;

function TPkgManager.DoGetIDEInstallPackageOptions(
  var InheritedOptionStrings: TInheritedCompOptsStrings): string;
begin
  Result:=PackageGraph.GetIDEInstallPackageOptions(InheritedOptionStrings);
end;

function TPkgManager.DoPublishPackage(APackage: TLazPackage;
  Flags: TPkgSaveFlags; ShowDialog: boolean): TModalResult;
begin
  // show the publish dialog
  if ShowDialog then begin
    Result:=ShowPublishProjectDialog(APackage.PublishOptions);
    if Result<>mrOk then exit;
  end;

  // save package
  Result:=DoSavePackage(APackage,Flags);
  if Result<>mrOk then exit;

  // publish package
  Result:=MainIDE.DoPublishModule(APackage.PublishOptions,APackage.Directory,
                                  GetPublishPackageDir(APackage));
end;

function TPkgManager.GetUsableComponentUnits(CurRoot: TPersistent): TFPList;
var
  FMainUnitInfo: TUnitInfo;
  FMainUnitInfoValid: boolean;
  FMainOwner: TObject;
  FMainOwnerValid: boolean;
  FForms: TStrings; // list of VarName:ClassName
  
  function ComponentIsAutoCreated(AComponent: TComponent): boolean;
  var
    i: Integer;
    ID: String;
  begin
    Result:=false;
    if AComponent=nil then exit;
    ID:=AComponent.Name+':'+AComponent.ClassName;
    for i:=0 to FForms.Count-1 do
      if SysUtils.CompareText(ID,FForms[i])=0 then exit(true);
  end;

  function GatherCreateFormStatements: boolean;
  // returns true if CurRoot is listed in the projects CreateForm statements
  begin
    Result:=false;
    if (Project1=nil)
    or (not (pfMainUnitHasCreateFormStatements in Project1.Flags))
    or (Project1.MainUnitInfo=nil) or (Project1.MainUnitInfo.Source=nil)
    then
      exit;
    FForms:=CodeToolBoss.ListAllCreateFormStatements(
                                               Project1.MainUnitInfo.Source);
    if (FForms=nil) or (FForms.Count=0) then exit;
    Result:=true;
  end;

  function MainUnitInfo: TUnitInfo;
  begin
    if not FMainUnitInfoValid then
    begin
      if CurRoot is TComponent then
        FMainUnitInfo := Project1.UnitWithComponentName(TComponent(CurRoot).Name);
      FMainUnitInfoValid := True;
    end;
    Result := FMainUnitInfo;
  end;

  function MainOwner: TObject;
  var
    Owners: TFPList;
  begin
    if not FMainOwnerValid then
    begin
      if MainUnitInfo <> nil then
      begin
        if MainUnitInfo.IsPartOfProject then
          FMainOwner := Project1
        else
        begin
          Owners := GetOwnersOfUnit(MainUnitInfo.Filename);
          if (Owners <> nil) and (Owners.Count > 0) then
            FMainOwner := TObject(Owners[0]);
          Owners.Free;
        end;
      end;
      FMainOwnerValid := True;
    end;
    Result := FMainOwner;
  end;

  procedure CheckUnit(AnUnitInfo: TUnitInfo);
  var
    Owners: TFPList;
    OtherOwner: TObject;
    APackage: TLazPackage;
    ConflictDependency: TPkgDependency;
    FirstDependency: TPkgDependency;
  begin
    if (AnUnitInfo.Component=nil)
    or (AnUnitInfo.Component=CurRoot)
    or (MainOwner=nil)
    or (not ComponentIsAutoCreated(AnUnitInfo.Component)) then
      exit;
    // check if the component can be used
    // A component can only be used, if it has a CreateForm statement in the lpr
    // A unit can not be used, if it has no owner (project/package).
    // And a unit can not be used, if it belongs to a higher level package.
    // For example: Package A uses Package B.
    // A can use units of B, but B can not use units of A.
    if AnUnitInfo.IsPartOfProject and MainUnitInfo.IsPartOfProject then
    begin
      // both units belong to the project => ok
    end else if AnUnitInfo.IsPartOfProject then
    begin
      // AnUnitInfo belongs to Project, but MainUnitInfo does not
      // A project unit can only be used by the project => not allowed
      exit;
    end else
    begin
      Owners:=GetOwnersOfUnit(AnUnitInfo.Filename);
      if (Owners=nil) or (Owners.Count=0) then begin
        // AnUnitInfo does not belong to a project or package
        // => this unit can not be used
        Owners.Free;
        exit;
      end;
      OtherOwner:=TObject(Owners[0]);
      Owners.Free;
      if OtherOwner=MainOwner then begin
        // both units belong to the same owner => ok
      end else if (OtherOwner is TLazPackage) then begin
        // check if MainOwner can use the package
        APackage:=TLazPackage(OtherOwner);
        if MainOwner is TProject then
          FirstDependency:=TProject(MainOwner).FirstRequiredDependency
        else if MainOwner is TLazPackage then
          FirstDependency:=TLazPackage(MainOwner).FirstRequiredDependency
        else
          exit;
        ConflictDependency:=PackageGraph.FindConflictRecursively(
          FirstDependency,APackage);
        if ConflictDependency<>nil then exit;
        if MainOwner is TLazPackage then begin
          // check if package already uses MainOwner
          ConflictDependency:=PackageGraph.FindDependencyRecursively(
            APackage.FirstRequiredDependency,TLazPackage(MainOwner).Name);
          if ConflictDependency<>nil then exit;
        end;
      end else begin
        // AnUnitInfo does not belong to a Package => can not be used
        exit;
      end;
    end;
    // this unit can be used -> add components
    if Result=nil then
      Result:=TFPList.Create;
    Result.Add(AnUnitInfo);
  end;
  
var
  AnUnitInfo: TUnitInfo;
begin
  Result:=nil;
  if not (CurRoot is TComponent) then exit;
  {$IFDEF DisableMultiFormProperties}
  exit;
  {$ENDIF}
  FMainOwner:=nil;
  FMainOwnerValid:=false;
  FMainUnitInfo:=nil;
  FMainUnitInfoValid:=false;
  FForms:=nil;
  try
    // check CreateForm statements in lpr file
    if not GatherCreateFormStatements then exit;

    // search all open designer forms (can be hidden)
    AnUnitInfo:=Project1.FirstUnitWithComponent;
    while AnUnitInfo<>nil do begin
      CheckUnit(AnUnitInfo);
      AnUnitInfo:=AnUnitInfo.NextUnitWithComponent;
    end;
  finally
    FForms.Free;
  end;
end;

procedure TPkgManager.IterateComponentNames(CurRoot: TPersistent;
  TypeData: PTypeData; Proc: TGetStringProc);

  procedure CheckComponent(aRoot: TComponent);
  var
    i: integer;
    CurName: String;
  begin
    if aRoot=nil then exit;
    for i := 0 to aRoot.ComponentCount - 1 do
      if (aRoot.Components[i] is TypeData^.ClassType) then
      begin
        CurName:=aRoot.Components[i].Name;
        if aRoot<>CurRoot then
          CurName:=aRoot.Name+'.'+CurName;
        Proc(CurName);
      end;
  end;

var
  UnitList: TFPList;
  i: Integer;
begin
  if not (CurRoot is TComponent) then exit;
  CheckComponent(TComponent(CurRoot));
  {$IFDEF DisableMultiFormProperties}
  exit;
  {$ENDIF}
  UnitList:=GetUsableComponentUnits(CurRoot);
  if UnitList=nil then exit;
  try
    for i:=0 to UnitList.Count-1 do
      CheckComponent(TUnitInfo(UnitList[i]).Component);
  finally
    UnitList.Free;
  end;
end;

function TPkgManager.FindReferencedRootComponent(CurRoot: TPersistent;
  const ComponentName: string): TComponent;
var
  UnitList: TFPList;
  ARoot: TComponent;
  i: integer;
begin
  //DebugLn(['search ', ComponentName, ' CurRoot = ', dbgsName(CurRoot)]);
  Result := nil;
  UnitList := GetUsableComponentUnits(CurRoot);
  if UnitList = nil then 
    Exit;
  try
    for i := 0 to UnitList.Count - 1 do 
    begin
      ARoot := TUnitInfo(UnitList[i]).Component;
      DebugLn(['TPkgManager.FindReferencedRootComponent Root=',dbgsName(CurRoot),' Searched="',ComponentName,'" other root=',dbgsName(ARoot)]);
      if (ARoot <> nil) and (SysUtils.CompareText(ComponentName, ARoot.Name) = 0) then
      begin
        Result := ARoot;
        break;
      end;
    end;
  finally
    UnitList.Free;
  end;
  //DebugLn('search end');
end;

function TPkgManager.FindUsableComponent(CurRoot: TPersistent;
  const ComponentPath: string): TComponent;

  procedure CheckComponent(const RootName, SubPath: string; aRoot: TComponent);
  var
    i: integer;
  begin
    if aRoot=nil then exit;
    if (SysUtils.CompareText(RootName,aRoot.Name)<>0) then exit;
    for i := 0 to aRoot.ComponentCount - 1 do
      if SysUtils.CompareText(aRoot.Components[i].Name,SubPath)=0 then begin
        Result:=aRoot.Components[i];
        exit;
      end;
  end;

var
  UnitList: TFPList;
  SubPath: String;
  p: LongInt;
  RootName: String;
  i: Integer;
begin
  Result:=nil;
  if not (CurRoot is TComponent) then exit;
  SubPath:=ComponentPath;
  p:=System.Pos('.',SubPath);
  if p<1 then
    RootName:=''
  else begin
    RootName:=copy(ComponentPath,1,p-1);
    SubPath:=copy(SubPath,p+1,length(SubPath));
  end;
  if (RootName='') or (SysUtils.CompareText(RootName,TComponent(CurRoot).Name)=0)
  then
    CheckComponent(TComponent(CurRoot).Name,SubPath,TComponent(CurRoot));
  {$IFDEF DisableMultiFormProperties}
  exit;
  {$ENDIF}
  if p<1 then exit;
  UnitList:=GetUsableComponentUnits(CurRoot);
  if UnitList=nil then exit;
  try
    for i:=0 to UnitList.Count-1 do begin
      CheckComponent(RootName,SubPath,TUnitInfo(UnitList[i]).Component);
      if Result<>nil then exit;
    end;
  finally
    UnitList.Free;
  end;
end;

function TPkgManager.OnProjectInspectorOpen(Sender: TObject): boolean;
var
  Dependency: TPkgDependency;
begin
  Result:=false;
  if (Sender=nil) or (not (Sender is TProjectInspectorForm)) then exit;
  Dependency:=TProjectInspectorForm(Sender).GetSelectedDependency;
  if Dependency=nil then exit;
  // user has selected a dependency -> open package
  Result:=true;
  if PackageGraph.OpenDependency(Dependency,false)<>lprSuccess then
    exit;
  DoOpenPackage(Dependency.RequiredPackage,[],false);
end;

function TPkgManager.OnProjectInspectorAddDependency(Sender: TObject;
  ADependency: TPkgDependency): TModalResult;
begin
  Result:=AddProjectDependency(Project1,ADependency);
end;

function TPkgManager.OnProjectInspectorRemoveDependency(Sender: TObject;
  ADependency: TPkgDependency): TModalResult;
var
  ShortUnitName: String;
  Dummy: Boolean;
begin
  Result:=mrOk;
  Project1.RemoveRequiredDependency(ADependency);
  //debugln('TPkgManager.OnProjectInspectorRemoveDependency A');
  if (Project1.MainUnitID>=0)
  and (pfMainUnitHasUsesSectionForAllUnits in Project1.Flags)
  then begin
    MainIDEInterface.SaveSourceEditorChangesToCodeCache(-1);
    ShortUnitName:=ADependency.PackageName;
    //debugln('TPkgManager.OnProjectInspectorRemoveDependency B ShortUnitName="',ShortUnitName,'"');
    if (ShortUnitName<>'') then begin
      Dummy:=CodeToolBoss.RemoveUnitFromAllUsesSections(
                                    Project1.MainUnitInfo.Source,ShortUnitName);
      if Dummy then
        Project1.MainUnitInfo.Modified:=true
      else begin
        MainIDEInterface.DoJumpToCodeToolBossError;
        Result:=mrCancel;
        exit;
      end;
    end;
  end;
end;

function TPkgManager.OnProjectInspectorReAddDependency(Sender: TObject;
  ADependency: TPkgDependency): TModalResult;
begin
  Result:=mrOk;
  Project1.ReaddRemovedDependency(ADependency);
  PackageGraph.OpenDependency(ADependency,false);
  if (ADependency.RequiredPackage<>nil)
  and (not ADependency.RequiredPackage.AutoCreated) then begin
    AddUnitToProjectMainUsesSection(Project1,ADependency.PackageName,'');
  end;
end;

function TPkgManager.CanOpenDesignerForm(AnUnitInfo: TUnitInfo;
  Interactive: boolean): TModalResult;
var
  AProject: TProject;
begin
  Result:=mrCancel;
  if AnUnitInfo=nil then exit;
  AProject:=AnUnitInfo.Project;
  if AProject=nil then exit;
  Result:=CheckProjectHasInstalledPackages(AProject,Interactive);
end;

function TPkgManager.DoClosePackageEditor(APackage: TLazPackage): TModalResult;
begin
  if APackage.Editor<>nil then begin
    APackage.Editor.Free;
  end;
  Result:=mrOk;
end;

function TPkgManager.DoSaveAllPackages(Flags: TPkgSaveFlags): TModalResult;
var
  AllSaved: Boolean;
  i: Integer;
  CurPackage: TLazPackage;
begin
  try
    repeat
      AllSaved:=true;
      i:=0;
      while i<PackageGraph.Count do begin
        CurPackage:=PackageGraph[i];
        if CurPackage.Modified and (not CurPackage.ReadOnly)
        and (not (lpfSkipSaving in CurPackage.Flags)) then begin
          Result:=DoSavePackage(CurPackage,Flags);
          if Result=mrIgnore then begin
            CurPackage.Flags:=CurPackage.Flags+[lpfSkipSaving];
            Result:=mrOk;
          end;
          if Result<>mrOk then exit;
          AllSaved:=false;
        end;
        inc(i);
      end;
    until AllSaved;
  finally
    // clear all lpfSkipSaving flags
    for i:=0 to PackageGraph.Count-1 do begin
      CurPackage:=PackageGraph[i];
      CurPackage.Flags:=CurPackage.Flags-[lpfSkipSaving];
    end;
  end;
  Result:=mrOk;
end;

{ TLazPackageDescriptors }

function TLazPackageDescriptors.GetItems(Index: integer): TPackageDescriptor;
begin
  Result:=TPackageDescriptor(FItems[Index]);
end;

constructor TLazPackageDescriptors.Create;
begin
  PackageDescriptors:=Self;
  FItems:=TFPList.Create;
end;

destructor TLazPackageDescriptors.Destroy;
var
  i: Integer;
begin
  fDestroying:=true;
  for i:=Count-1 downto 0 do Items[i].Release;
  FItems.Free;
  FItems:=nil;
  PackageDescriptors:=nil;
  inherited Destroy;
end;

function TLazPackageDescriptors.Count: integer;
begin
  Result:=FItems.Count;
end;

function TLazPackageDescriptors.GetUniqueName(const Name: string): string;
var
  i: Integer;
begin
  Result:=Name;
  if IndexOf(Result)<0 then exit;
  i:=0;
  repeat
    inc(i);
    Result:=Name+IntToStr(i);
  until IndexOf(Result)<0;
end;

function TLazPackageDescriptors.IndexOf(const Name: string): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (AnsiCompareText(Name,Items[Result].Name)<>0) do
    dec(Result);
end;

function TLazPackageDescriptors.FindByName(const Name: string
  ): TPackageDescriptor;
var
  i: LongInt;
begin
  i:=IndexOf(Name);
  if i>=0 then
    Result:=Items[i]
  else
    Result:=nil;
end;

procedure TLazPackageDescriptors.RegisterDescriptor(
  Descriptor: TPackageDescriptor);
begin
  if Descriptor.Name='' then
    raise Exception.Create('TLazPackageDescriptors.RegisterDescriptor Descriptor.Name empty');
  Descriptor.Name:=GetUniqueName(Descriptor.Name);
  FItems.Add(Descriptor);
end;

procedure TLazPackageDescriptors.UnregisterDescriptor(
  Descriptor: TPackageDescriptor);
var
  i: LongInt;
begin
  if fDestroying then exit;
  i:=FItems.IndexOf(Descriptor);
  if i<0 then
    raise Exception.Create('TLazPackageDescriptors.UnregisterDescriptor');
  FItems.Delete(i);
  Descriptor.Release;
end;

procedure TLazPackageDescriptors.AddDefaultPackageDescriptors;
begin
  NewIDEItems.Add(TNewLazIDEItemCategoryPackage.Create(PkgDescGroupName));
  RegisterPackageDescriptor(TPackageDescriptorStd.Create);
end;

{ TPackageDescriptorStd }

constructor TPackageDescriptorStd.Create;
begin
  inherited Create;
  Name:=PkgDescNameStandard;
end;

function TPackageDescriptorStd.GetLocalizedName: string;
begin
  Result:=lisPackage;
end;

function TPackageDescriptorStd.GetLocalizedDescription: string;
begin
  Result:=Format(lisNewDlgCreateANewStandardPackageAPackageIsACollectionOfUn,
                 [#13]);
end;

end.

