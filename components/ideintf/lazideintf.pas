{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Author: Mattias Gaertner

  Abstract:
    Interface to the general IDE functions.
}
unit LazIDEIntf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, Forms, Controls, Dialogs, PropEdits, LazHelpHTML,
  IDEOptionsIntf, CompOptsIntf, ProjectIntf,
  IDEExternToolIntf, SrcEditorIntf, IDEWindowIntf;

type
  // open file flags
  // Normally you don't need to pass any flags.
  TOpenFlag = (
    ofProjectLoading,// this open is part of opening a whole project
    ofOnlyIfExists,  // do not auto create non existing files
    ofRevert,        // reload file if already open, any user changes are lost without question
    ofQuiet,         // less messages
    ofAddToRecent,   // add file to recent files
    ofRegularFile,   // open as regular file (e.g. do not open projects/packages)
    ofVirtualFile,   // open the virtual file
    ofConvertMacros, // replace macros in filename
    ofUseCache,      // do not update file from disk
    ofMultiOpen,     // set during loading multiple files
    ofDoNotLoadResource,// do not open form, datamodule, ... (overriding default)
    ofDoLoadResource,// do open form, datamodule, ... (overriding default)
    ofLoadHiddenResource,// load component hidden
    ofAddToProject,  // add file to project (if exists)
    ofInternalFile   // opening data from an internal source (e.g. an editor macro (pascal script) from memory)
    );
  TOpenFlags = set of TOpenFlag;

const
  OpnFlagsPlainFile = [ofOnlyIfExists,ofQuiet,ofRegularFile,ofVirtualFile,ofDoNotLoadResource];
type
  // new file flags
  // Normally you don't need to pass any flags.
  TNewFlag = (
    nfIsPartOfProject, // force IsPartOfProject,
                       //   default is to use a heuristic
    nfIsNotPartOfProject,// forbid IsPartOfProject
    nfOpenInEditor,    // open in editor
    nfSave,            // save file instantly
    nfAddToRecent,     // add file to recent files
    nfQuiet,           // less messages
    nfConvertMacros,   // replace macros in filename
    nfBeautifySrc,     // beautify custom source
    nfCreateDefaultSrc,// create initial source based on the type
    nfAskForFilename   // ask for filename
    );
  TNewFlags = set of TNewFlag;

  // save file flags
  // Normally you don't need to pass any flags.
  TSaveFlag = (
    sfSaveAs,
    sfSaveToTestDir,
    sfProjectSaving,
    sfCheckAmbiguousFiles,
    sfSaveNonProjectFiles,
    sfDoNotSaveVirtualFiles,
    sfCanAbort,  // show 'Cancel all' button in error messages
    sfSaveMainSourceAs,  // on sfSaveAs use .lpr file instead of .lpi file
    sfQuietUnitCheck     // don't ask questions when adding unit dependency.
    );
  TSaveFlags = set of TSaveFlag;
  
  // close file flags
  // Normally you don't need to pass any flags.
  TCloseFlag = (
    cfSaveFirst, // check if modified and save
    cfQuiet,
    cfProjectClosing,
    cfCloseDependencies,
    cfSaveDependencies // set cfSaveFirst to close the dependencies
    );
  TCloseFlags = set of TCloseFlag;

  // build project flags
  // Normally you don't need to pass any flags.
  TProjectBuildFlag = (
    pbfCleanCompile,  // append -B to the compiler options
    pbfDoNotCompileDependencies,
    pbfDoNotCompileProject,
    pbfCompileDependenciesClean,
    pbfOnlyIfNeeded,
    pbfDoNotSaveEditorFiles,
    pbfSkipLinking,
    pbfSkipAssembler,
    pbfSkipTools,
    pbfCreateMakefile
    );
  TProjectBuildFlags = set of TProjectBuildFlag;
  
  TScanModeFPCSources = (
    smsfsSkip,
    smsfsWaitTillDone, // scan now and wait till finished
    smsfsBackground    // start in background
    );

  // new filename flags
  // Normally you don't need to pass any flags.
  TSearchIDEFileFlag = (
    siffDoNotCheckAllPackages, // do not search filename in unrelated packages (e.g. installed but not used by project)
    siffCheckAllProjects, // search filename in all loaded projects
    siffCaseSensitive,  // check case sensitive
    siffDoNotCheckOpenFiles,  // do not search in files opened in source editor
    siffIgnoreExtension  // compare only filename, ignore file extension
    );
  TSearchIDEFileFlags = set of TSearchIDEFileFlag;

  // find unit flags
  // Normally you don't need to pass any flags.
  TFindUnitFileFlag = (
    fuffIgnoreUninstallPackages
    );
  TFindUnitFileFlags = set of TFindUnitFileFlag;

  // selected part of IDE
  TTabDisplayState = (
    tdsNone,
    tdsCode,     // focussing sourcenotebook or source tab
    tdsDesign,   // focussing designer form/design tab
    tdsOther     // focussing other (user defined) tab assigned to module (like History Tab)
    );

  // find source flags
  // Normally you don't need to pass any flags.
  TFindSourceFlag = (
    fsfSearchForProject,
    fsfUseIncludePaths,
    fsfUseDebugPath,
    fsfMapTempToVirtualFiles,
    fsfSkipPackages
    );
  TFindSourceFlags = set of TFindSourceFlag;
  
  TModalResultFunction = function(Sender: TObject): TModalResult of object;
  TLazProjectChangedFunction = function(Sender: TObject;
                                 AProject: TLazProject): TModalResult of object;
  TModalHandledFunction = function(Sender: TObject; var Handled: boolean
                              ): TModalResult of object;
  TGetFPCFrontEndParams = function(Sender: TObject;
    var Params: string // these parameters are passed to fpc.
      // Global options should be prependended, project options should be appended.
    ): boolean of object;
  // DaThoX
  TShowDesignerFormOfSourceFunction = procedure(Sender: TObject; AEditor: TSourceEditorInterface;
                                 AComponentPaletteClassSelected: Boolean) of object;
  TShowDesignerFormOfSourceFunction = procedure(Sender: TObject; AEditor: TSourceEditorInterface;
                                 AComponentPaletteClassSelected: Boolean) of object;
  TGetFPCFrontEndPath = function(Sender: TObject;
    var Path: string // this path is prepended to fpc.
    ): boolean of object;

  TLazarusIDEHandlerType = (
    lihtSavingAll, // called before IDE saves everything
    lihtSavedAll,  // called after IDE saved everything
    lihtIDERestoreWindows, // called when IDE is restoring the windows (before opening the first project)
    lihtIDEClose, // called when IDE is shutting down (after closequery, so no more interactivity)
    lihtProjectOpened,// called after IDE opened a project
    lihtProjectClose, // called before IDE closes a project
    lihtProjectBuilding, // called before IDE builds the project
    lihtProjectDependenciesCompiling, // called before IDE compiles dependencies of project
    lihtProjectDependenciesCompiled, // called after IDE compiled dependencies of project
    lihtQuickSyntaxCheck,  // called when quick syntax check is clicked (menu item or shortcut)
    lihtGetFPCFrontEndParams, // called when the IDE gets the parameters of the 'fpc' front end tool
    lihtGetFPCFrontEndPath, // called when the IDE gets the path of the 'fpc' front end tool
    lihtShowDesignerFormOfSource, // called when showed a designer form for code editor (AEditor can be nil!)
    lihtShowSourceOfActiveDesignerForm, // called when showed a code of designer form
    lihtUpdateIDEComponentPalette,
    lihtUpdateComponentPageControl
    );
    
  { TLazIDEInterface }

  TLazIDEInterface = class(TComponent)
  private
    FMainBarSubTitle: string;
    FOpenEditorsOnCodeToolChange: boolean;
    FOpenMainSourceOnCodeToolChange: boolean;
    FSaveClosedSourcesOnCodeToolChange: boolean;
    procedure AddHandler(HandlerType: TLazarusIDEHandlerType;
                         const AMethod: TMethod; AsLast: boolean = false);
    procedure RemoveHandler(HandlerType: TLazarusIDEHandlerType;
                            const AMethod: TMethod);
  protected
    FLazarusIDEHandlers: array[TLazarusIDEHandlerType] of TMethodList;
    FOwningComponent: TComponent;
    FIDEStarted: boolean;
    FLastActivatedWindows: TFPList;
    // used to find the last form so you can display the correct tab
    FLastFormActivated: TCustomForm;

    function GetActiveProject: TLazProject; virtual; abstract;
    procedure DoCallNotifyHandler(HandlerType: TLazarusIDEHandlerType); overload;
    function DoCallModalFunctionHandler(HandlerType: TLazarusIDEHandlerType
                                        ): TModalResult;
    function DoCallModalHandledHandler(HandlerType: TLazarusIDEHandlerType;
                                       var Handled: boolean): TModalResult;
    procedure DoCallNotifyHandler(HandlerType: TLazarusIDEHandlerType;
                                  Sender: TObject); overload;
    procedure DoCallShowDesignerFormOfSourceHandler(
      HandlerType: TLazarusIDEHandlerType;
      Sender: TObject; AEditor: TSourceEditorInterface;
      AComponentPaletteClassSelected: Boolean);

    procedure SetMainBarSubTitle(const AValue: string); virtual;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property OwningComponent: TComponent read FOwningComponent;
    
    // the main window with the IDE menu
    function GetMainBar: TComponent; virtual; abstract;
    property MainBarSubTitle: string read FMainBarSubTitle write SetMainBarSubTitle;

    // find file
    function FindUnitFile(const AFilename: string; TheOwner: TObject = nil;
                          Flags: TFindUnitFileFlags = []): string; virtual; abstract;
    function FindSourceFile(const AFilename, BaseDirectory: string;
                            Flags: TFindSourceFlags): string; virtual; abstract;

    // file
    function DoNewEditorFile(NewFileDescriptor: TProjectFileDescriptor;
                             NewFilename: string; const NewSource: string;
                             NewFlags: TNewFlags): TModalResult;
    function DoNewFile(NewFileDescriptor: TProjectFileDescriptor;
                       var NewFilename: string; NewSource: string;
                       NewFlags: TNewFlags; NewOwner: TObject): TModalResult; virtual; abstract;
    function DoSaveEditorFile(AEditor: TSourceEditorInterface;
                              Flags: TSaveFlags): TModalResult; virtual; abstract;
    function DoSaveEditorFile(const Filename: string;
                              Flags: TSaveFlags): TModalResult; virtual; abstract;
    function DoSaveAll(Flags: TSaveFlags): TModalResult; virtual; abstract;
    function DoCloseEditorFile(AEditor: TSourceEditorInterface;
                               Flags: TCloseFlags):TModalResult; virtual; abstract;
    function DoCloseEditorFile(const Filename: string;
                               Flags: TCloseFlags): TModalResult; virtual; abstract;
    function DoOpenEditorFile(AFileName:string; PageIndex, WindowIndex: integer;
                              Flags: TOpenFlags): TModalResult; virtual; abstract;
    function DoOpenFileAndJumpToIdentifier(const AFilename, AnIdentifier: string;
                       PageIndex, WindowIndex: integer; Flags: TOpenFlags): TModalResult; virtual; abstract;
    function DoOpenFileAndJumpToPos(const AFilename: string;
                       const CursorPosition: TPoint; TopLine: integer;
                       PageIndex, WindowIndex: integer; Flags: TOpenFlags): TModalResult; virtual; abstract;
    function DoRevertEditorFile(const Filename: string): TModalResult; virtual; abstract;
    function DoOpenComponent(const UnitFilename: string; OpenFlags: TOpenFlags;
                       CloseFlags: TCloseFlags;
                       out Component: TComponent): TModalResult; virtual; abstract;
    procedure DoDropFiles(Sender: TObject; const FileNames: array of String;
      WindowIndex: integer = -1); virtual; abstract;

    // project
    property ActiveProject: TLazProject read GetActiveProject;
    function DoNewProject(ProjectDesc: TProjectDescriptor): TModalResult; virtual; abstract;
    function DoSaveProject(Flags: TSaveFlags): TModalResult; virtual; abstract;
    function DoCloseProject: TModalResult; virtual; abstract;
    function DoOpenProjectFile(AFileName: string;
                               Flags: TOpenFlags): TModalResult; virtual; abstract;
    function DoPublishProject(Flags: TSaveFlags;
                              ShowDialog: boolean): TModalResult; virtual; abstract;
    function DoBuildProject(const AReason: TCompileReason;
                            Flags: TProjectBuildFlags;
                            FinalizeResources: boolean = True): TModalResult; virtual; abstract;
    function GetProjectFileForProjectEditor(AEditor: TSourceEditorInterface): TLazProjectFile; virtual; abstract;
    function DoCallProjectChangedHandler(HandlerType: TLazarusIDEHandlerType;
                                         AProject: TLazProject): TModalResult;

    // configs
    class function GetPrimaryConfigPath: String; virtual; abstract;
    class function GetSecondaryConfigPath: String; virtual; abstract;
    procedure CopySecondaryConfigFile(const AFilename: String); virtual; abstract;
    procedure DoOpenIDEOptions(AEditor: TAbstractIDEOptionsEditorClass = nil;
      ACaption: String = ''); overload;
    procedure DoOpenIDEOptions(AEditor: TAbstractIDEOptionsEditorClass;
      ACaption: String;
      AOptionsFilter: array of TAbstractIDEOptionsClass;
      ASettings: TIDEOptionsEditorSettings); overload; virtual; abstract;

    // filenames, paths
    function CreateNewUniqueFilename(const Prefix, Ext: string;
                          NewOwner: TObject; Flags: TSearchIDEFileFlags;
                          TryWithoutNumber: boolean): string; virtual; abstract;
    function GetTestBuildDirectory: string; virtual; abstract;
    function GetFPCompilerFilename: string; virtual; abstract;
    function GetFPCFrontEndOptions: string; virtual; abstract;

    // codetools
    function BeginCodeTools: boolean; virtual; abstract;
    function DoShowCodeToolBossError: TMessageLine; virtual; abstract;
    procedure DoJumpToCodeToolBossError; virtual; abstract;

    function NeedSaveSourceEditorChangesToCodeCache(AEditor: TSourceEditorInterface): boolean; virtual; abstract;
    function SaveSourceEditorChangesToCodeCache(AEditor: TSourceEditorInterface): boolean; virtual; abstract; // true if something was saved

    property OpenEditorsOnCodeToolChange: boolean read FOpenEditorsOnCodeToolChange
                                             write FOpenEditorsOnCodeToolChange;
    property SaveClosedSourcesOnCodeToolChange: boolean read FSaveClosedSourcesOnCodeToolChange
                                             write FSaveClosedSourcesOnCodeToolChange;
    property OpenMainSourceOnCodeToolChange: boolean read FOpenMainSourceOnCodeToolChange
                                             write FOpenMainSourceOnCodeToolChange;

    // progress and error messages
    function ShowProgress(const SomeText: string;
      Step, MaxStep: integer): boolean; virtual; abstract; // False if canceled by user
    function DoJumpToCompilerMessage(FocusEditor: boolean;
                              Msg: TMessageLine = nil // if nil then it jumps to first message
                              ): boolean; virtual; abstract;
    procedure DoJumpToNextError(DirectionDown: boolean); virtual; abstract;
    procedure DoShowMessagesView(BringToFront: boolean = true); virtual; abstract;
    function DoCheckFilesOnDisk(Instantaneous: boolean = false): TModalResult; virtual; abstract;
    // call this after changing TargetOS/TargetCPU of the ActiveProject
    procedure PrepareBuildTarget(Quiet: boolean;
                     ScanFPCSrc: TScanModeFPCSources = smsfsBackground); virtual; abstract;
    procedure AbortBuild; virtual; abstract;

    // search results
    procedure DoShowSearchResultsView(Show: boolean; BringToFront: boolean = False); deprecated;
    procedure DoShowSearchResultsView(State: TIWGetFormState = iwgfShowOnTop); virtual; abstract;

    // designer
    function GetDesignerForProjectEditor(AEditor: TSourceEditorInterface;
                              LoadForm: boolean): TIDesigner; virtual; abstract;
    function GetDesignerWithProjectFile(AFile: TLazProjectFile;
                              LoadForm: boolean): TIDesigner; virtual; abstract;
    function GetProjectFileWithRootComponent(AComponent: TComponent): TLazProjectFile; virtual; abstract;
    function GetProjectFileWithDesigner(ADesigner: TIDesigner): TLazProjectFile; virtual; abstract;

    procedure DoShowDesignerFormOfSrc(AEditor: TSourceEditorInterface); virtual; abstract; overload;
    procedure DoShowMethod(AEditor: TSourceEditorInterface; const AMethodName: String); virtual; abstract;
    procedure DoShowDesignerFormOfSrc(AEditor: TSourceEditorInterface; out AForm: TCustomForm); virtual; abstract; overload;

    // events
    procedure RemoveAllHandlersOfObject(AnObject: TObject);
    procedure AddHandlerOnSavingAll(const OnSaveAllEvent: TModalResultFunction;
                                    AsLast: boolean = false);
    procedure RemoveHandlerOnSavingAll(const OnSaveAllEvent: TModalResultFunction);
    procedure AddHandlerOnSavedAll(const OnSaveAllEvent: TModalResultFunction;
                                   AsLast: boolean = false);
    procedure RemoveHandlerOnSavedAll(const OnSaveAllEvent: TModalResultFunction);
    procedure AddHandlerOnIDERestoreWindows(const OnIDERestoreWindowsEvent: TNotifyEvent;
                                   AsLast: boolean = false);
    procedure RemoveHandlerOnIDERestoreWindows(
                                  const OnIDERestoreWindowsEvent: TNotifyEvent);
    procedure AddHandlerOnIDEClose(const OnIDECloseEvent: TNotifyEvent;
                                   AsLast: boolean = false);
    procedure RemoveHandlerOnIDEClose(const OnIDECloseEvent: TNotifyEvent);
    procedure AddHandlerOnProjectOpened(
                         const OnProjectOpenedEvent: TLazProjectChangedFunction;
                         AsLast: boolean = false);
    procedure RemoveHandlerOnProjectOpened(
                        const OnProjectOpenedEvent: TLazProjectChangedFunction);
    procedure AddHandlerOnProjectClose(
                          const OnProjectCloseEvent: TLazProjectChangedFunction;
                          AsLast: boolean = false);
    procedure RemoveHandlerOnProjectClose(
                         const OnProjectCloseEvent: TLazProjectChangedFunction);
    procedure AddHandlerOnProjectBuilding(
                                const OnProjBuildingEvent: TModalResultFunction;
                                AsLast: boolean = false);
    procedure RemoveHandlerOnProjectBuilding(
                                const OnProjBuildingEvent: TModalResultFunction);
    procedure AddHandlerOnProjectDependenciesCompiling(
                   const OnProjDependenciesCompilingEvent: TModalResultFunction;
                   AsLast: boolean = false);
    procedure RemoveHandlerOnProjectDependenciesCompiling(
                  const OnProjDependenciesCompilingEvent: TModalResultFunction);
    procedure AddHandlerOnProjectDependenciesCompiled(
                    const OnProjDependenciesCompiledEvent: TModalResultFunction;
                    AsLast: boolean = false);
    procedure RemoveHandlerOnProjectDependenciesCompiled(
                   const OnProjDependenciesCompiledEvent: TModalResultFunction);
    procedure AddHandlerOnQuickSyntaxCheck(
                           const OnQuickSyntaxCheckEvent: TModalHandledFunction;
                           AsLast: boolean = false);
    procedure RemoveHandlerOnQuickSyntaxCheck(
                          const OnQuickSyntaxCheckEvent: TModalHandledFunction);
    procedure AddHandlerGetFPCFrontEndParams(
                 const Handler: TGetFPCFrontEndParams; AsLast: boolean = false);
    procedure RemoveHandlerGetFPCFrontEndParams(
                                          const Handler: TGetFPCFrontEndParams);
    function CallHandlerGetFPCFrontEndParams(Sender: TObject; var Params: string): boolean;
    procedure AddHandlerGetFPCFrontEndPath(
                 const Handler: TGetFPCFrontEndPath; AsLast: boolean = false);
    procedure RemoveHandlerGetFPCFrontEndPath(
                                          const Handler: TGetFPCFrontEndPath);
    function CallHandlerGetFPCFrontEndPath(Sender: TObject; var Path: string): boolean;
    procedure AddHandlerOnUpdateIDEComponentPalette(
                           const OnUpdateIDEComponentPaletteEvent: TNotifyEvent;
                           AsLast: boolean = false);
    procedure RemoveHandlerOnUpdateIDEComponentPalette(
                               const OnUpdateIDEComponentPaletteEvent: TNotifyEvent);
    procedure AddHandlerOnUpdateComponentPageControl(
                           const OnUpdateComponentPageControlEvent: TNotifyEvent;
                           AsLast: boolean = false);
    procedure RemoveHandlerOnUpdateComponentPageControl(
                               const OnUpdateComponentPageControlEvent: TNotifyEvent);
    procedure AddHandlerOnShowDesignerFormOfSource(
                           const OnShowDesignerFormOfSourceEvent: TShowDesignerFormOfSourceFunction;
                           AsLast: boolean = false);
    procedure RemoveHandlerOnShowDesignerFormOfSource(
                               const OnShowDesignerFormOfSourceEvent: TShowDesignerFormOfSourceFunction);
    procedure AddHandlerOnShowSourceOfActiveDesignerForm(
                           const OnShowSourceOfActiveDesignerForm: TNotifyEvent;
                           AsLast: boolean = false);
    procedure RemoveHandlerOnShowSourceOfActiveDesignerForm(
                               const OnShowSourceOfActiveDesignerForm: TNotifyEvent);

    property IDEStarted: boolean read FIDEStarted;
    property LastActivatedWindows: TFPList read FLastActivatedWindows;
    property LastFormActivated: TCustomForm read FLastFormActivated write FLastFormActivated;
    // DaThoX begin
    procedure AddHandlerOnUpdateIDEComponentPalette(
                           const OnUpdateIDEComponentPaletteEvent: TNotifyEvent;
                           AsLast: boolean = false);
    procedure RemoveHandlerOnUpdateIDEComponentPalette(
                               const OnUpdateIDEComponentPaletteEvent: TNotifyEvent);
    procedure AddHandlerOnUpdateComponentPageControl(
                           const OnUpdateComponentPageControlEvent: TNotifyEvent;
                           AsLast: boolean = false);
    procedure RemoveHandlerOnUpdateComponentPageControl(
                               const OnUpdateComponentPageControlEvent: TNotifyEvent);
    procedure AddHandlerOnShowDesignerFormOfSource(
                           const OnShowDesignerFormOfSourceEvent: TShowDesignerFormOfSourceFunction;
                           AsLast: boolean = false);
    procedure RemoveHandlerOnShowDesignerFormOfSource(
                               const OnShowDesignerFormOfSourceEvent: TShowDesignerFormOfSourceFunction);
    procedure AddHandlerOnShowSourceOfActiveDesignerForm(
                           const OnShowSourceOfActiveDesignerForm: TNotifyEvent;
                           AsLast: boolean = false);
    procedure RemoveHandlerOnShowSourceOfActiveDesignerForm(
                               const OnShowSourceOfActiveDesignerForm: TNotifyEvent);
    // DaThoX end
  end;

  TIDETabMaster = class
  protected
    function GetTabDisplayState: TTabDisplayState; virtual; abstract;
    function GetTabDisplayStateEditor(Index: TSourceEditorInterface): TTabDisplayState; virtual; abstract;
  public
    procedure ToggleFormUnit; virtual; abstract;
    procedure JumpToCompilerMessage(ASourceEditor: TSourceEditorInterface); virtual; abstract;

    property TabDisplayState: TTabDisplayState read GetTabDisplayState;
    property TabDisplayStateEditor[Index: TSourceEditorInterface]: TTabDisplayState read GetTabDisplayStateEditor;

    procedure ShowCode(ASourceEditor: TSourceEditorInterface); virtual; abstract;
    procedure ShowDesigner(ASourceEditor: TSourceEditorInterface; AIndex: Integer = 0); virtual; abstract;
    procedure ShowForm(AForm: TCustomForm); virtual; abstract;
  end;

var
  LazarusIDE: TLazIDEInterface = nil; // will be set by the IDE
  IDETabMaster: TIDETabMaster = nil;

type
  TLazarusIDEBootHandlerType = (
    libhTransferMacrosCreated,  // called after IDEMacros were created
    libhEnvironmentOptionsLoaded  // called after IDE loaded environment options
    );

procedure AddBootHandler(ht: TLazarusIDEBootHandlerType; const OnBoot: TProcedure);
procedure RunBootHandlers(ht: TLazarusIDEBootHandlerType);

implementation

type
  TArrayOfProc = array of TProcedure;
var
  BootHandlers: array[TLazarusIDEBootHandlerType] of TArrayOfProc;

procedure AddBootHandler(ht: TLazarusIDEBootHandlerType; const OnBoot: TProcedure);
var
  l: Integer;
begin
  l:=length(BootHandlers[ht]);
  SetLength(BootHandlers[ht],l+1);
  BootHandlers[ht][l]:=OnBoot;
end;

procedure RunBootHandlers(ht: TLazarusIDEBootHandlerType);
var
  i: Integer;
begin
  for i:=0 to length(BootHandlers[ht])-1 do
    BootHandlers[ht][i]();
end;

{ TLazIDEInterface }

procedure TLazIDEInterface.AddHandler(HandlerType: TLazarusIDEHandlerType;
  const AMethod: TMethod; AsLast: boolean);
begin
  if FLazarusIDEHandlers[HandlerType]=nil then
    FLazarusIDEHandlers[HandlerType]:=TMethodList.Create;
  FLazarusIDEHandlers[HandlerType].Add(AMethod,AsLast);
end;

procedure TLazIDEInterface.RemoveHandler(HandlerType: TLazarusIDEHandlerType;
  const AMethod: TMethod);
begin
  FLazarusIDEHandlers[HandlerType].Remove(AMethod);
end;

procedure TLazIDEInterface.SetMainBarSubTitle(const AValue: string);
begin
  if FMainBarSubTitle=AValue then exit;
  FMainBarSubTitle:=AValue;
end;

procedure TLazIDEInterface.DoCallNotifyHandler(
  HandlerType: TLazarusIDEHandlerType);
begin
  FLazarusIDEHandlers[HandlerType].CallNotifyEvents(Self);
end;

function TLazIDEInterface.DoCallModalFunctionHandler(
  HandlerType: TLazarusIDEHandlerType): TModalResult;
var
  i: Integer;
  CurResult: TModalResult;
begin
  Result:=mrOk;
  i:=FLazarusIDEHandlers[HandlerType].Count;
  while FLazarusIDEHandlers[HandlerType].NextDownIndex(i) do begin
    CurResult:=TModalResultFunction(FLazarusIDEHandlers[HandlerType][i])(Self);
    if CurResult=mrAbort then exit(mrAbort);
    if CurResult<>mrOk then Result:=mrCancel;
  end;
end;

function TLazIDEInterface.DoCallProjectChangedHandler(
  HandlerType: TLazarusIDEHandlerType; AProject: TLazProject): TModalResult;
var
  i: Integer;
  CurResult: TModalResult;
begin
  Result:=mrOk;
  LastActivatedWindows.Clear;               // IDE windows may change.
  i:=FLazarusIDEHandlers[HandlerType].Count;
  while FLazarusIDEHandlers[HandlerType].NextDownIndex(i) do begin
    CurResult:=TLazProjectChangedFunction(FLazarusIDEHandlers[HandlerType][i])(Self,AProject);
    if CurResult=mrAbort then exit(mrAbort);
    if CurResult<>mrOk then Result:=mrCancel;
  end;
end;

function TLazIDEInterface.DoCallModalHandledHandler(
  HandlerType: TLazarusIDEHandlerType; var Handled: boolean): TModalResult;
var
  i: longint;
begin
  i:=FLazarusIDEHandlers[HandlerType].Count;
  while FLazarusIDEHandlers[HandlerType].NextDownIndex(i) do
  begin
    Handled:=false;
    Result:=TModalHandledFunction(FLazarusIDEHandlers[HandlerType][i])(Self,Handled);
    if Handled then exit;
  end;
  Result:=mrOk;
end;

procedure TLazIDEInterface.DoCallNotifyHandler(HandlerType: TLazarusIDEHandlerType; Sender: TObject);
begin
  FLazarusIDEHandlers[HandlerType].CallNotifyEvents(Sender);
end;

procedure TLazIDEInterface.DoCallShowDesignerFormOfSourceHandler(
  HandlerType: TLazarusIDEHandlerType; Sender: TObject;
  AEditor: TSourceEditorInterface; AComponentPaletteClassSelected: Boolean);
var
  i: Integer;
begin
  i := FLazarusIDEHandlers[HandlerType].Count;
  while FLazarusIDEHandlers[HandlerType].NextDownIndex(i) do
    TShowDesignerFormOfSourceFunction(FLazarusIDEHandlers[HandlerType][i])(Sender, AEditor,
                                                 AComponentPaletteClassSelected);
end;

constructor TLazIDEInterface.Create(TheOwner: TComponent);
begin
  LazarusIDE:=Self;
  inherited Create(TheOwner);
end;

destructor TLazIDEInterface.Destroy;
var
  HandlerType: TLazarusIDEHandlerType;
begin
  for HandlerType := Low(TLazarusIDEHandlerType) to High(TLazarusIDEHandlerType) do
    FreeAndNil(FLazarusIDEHandlers[HandlerType]);
  inherited Destroy;
  LazarusIDE:=nil;
end;

function TLazIDEInterface.DoNewEditorFile(
  NewFileDescriptor: TProjectFileDescriptor; NewFilename: string;
  const NewSource: string; NewFlags: TNewFlags): TModalResult;
begin
  Result:=DoNewFile(NewFileDescriptor,NewFilename,NewSource,NewFlags,nil);
end;

procedure TLazIDEInterface.DoOpenIDEOptions(AEditor: TAbstractIDEOptionsEditorClass; ACaption: String);
begin
  DoOpenIDEOptions(AEditor, ACaption, [], []);
end;

procedure TLazIDEInterface.DoShowSearchResultsView(Show: boolean;
  BringToFront: boolean);
var
  State: TIWGetFormState;
begin
  if Show then begin
    if BringToFront then
      State:=iwgfShowOnTop
    else
      State:=iwgfShow;
  end else begin
    State:=iwgfEnabled;
  end;
  DoShowSearchResultsView(State);
end;

procedure TLazIDEInterface.RemoveAllHandlersOfObject(AnObject: TObject);
var
  HandlerType: TLazarusIDEHandlerType;
begin
  for HandlerType:=Low(HandlerType) to High(HandlerType) do
    FLazarusIDEHandlers[HandlerType].RemoveAllMethodsOfObject(AnObject);
end;

procedure TLazIDEInterface.AddHandlerOnSavingAll(
  const OnSaveAllEvent: TModalResultFunction; AsLast: boolean);
begin
  AddHandler(lihtSavingAll,TMethod(OnSaveAllEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnSavingAll(
  const OnSaveAllEvent: TModalResultFunction);
begin
  RemoveHandler(lihtSavingAll,TMethod(OnSaveAllEvent));
end;

procedure TLazIDEInterface.AddHandlerOnSavedAll(
  const OnSaveAllEvent: TModalResultFunction; AsLast: boolean);
begin
  AddHandler(lihtSavedAll,TMethod(OnSaveAllEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnSavedAll(
  const OnSaveAllEvent: TModalResultFunction);
begin
  RemoveHandler(lihtSavedAll,TMethod(OnSaveAllEvent));
end;

procedure TLazIDEInterface.AddHandlerOnIDERestoreWindows(
  const OnIDERestoreWindowsEvent: TNotifyEvent; AsLast: boolean);
begin
  AddHandler(lihtIDERestoreWindows,TMethod(OnIDERestoreWindowsEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnIDERestoreWindows(
  const OnIDERestoreWindowsEvent: TNotifyEvent);
begin
  RemoveHandler(lihtIDERestoreWindows,TMethod(OnIDERestoreWindowsEvent));
end;

procedure TLazIDEInterface.AddHandlerOnIDEClose(
  const OnIDECloseEvent: TNotifyEvent; AsLast: boolean);
begin
  AddHandler(lihtIDEClose,TMethod(OnIDECloseEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnIDEClose(
  const OnIDECloseEvent: TNotifyEvent);
begin
  RemoveHandler(lihtIDEClose,TMethod(OnIDECloseEvent));
end;

procedure TLazIDEInterface.AddHandlerOnProjectOpened(
  const OnProjectOpenedEvent: TLazProjectChangedFunction; AsLast: boolean);
begin
  AddHandler(lihtProjectOpened,TMethod(OnProjectOpenedEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnProjectOpened(
  const OnProjectOpenedEvent: TLazProjectChangedFunction);
begin
  RemoveHandler(lihtProjectOpened,TMethod(OnProjectOpenedEvent));
end;

procedure TLazIDEInterface.AddHandlerOnProjectClose(
  const OnProjectCloseEvent: TLazProjectChangedFunction; AsLast: boolean);
begin
  AddHandler(lihtProjectClose,TMethod(OnProjectCloseEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnProjectClose(
  const OnProjectCloseEvent: TLazProjectChangedFunction);
begin
  RemoveHandler(lihtProjectClose,TMethod(OnProjectCloseEvent));
end;

procedure TLazIDEInterface.AddHandlerOnProjectBuilding(
  const OnProjBuildingEvent: TModalResultFunction; AsLast: boolean);
begin
  AddHandler(lihtProjectBuilding,TMethod(OnProjBuildingEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnProjectBuilding(
  const OnProjBuildingEvent: TModalResultFunction);
begin
  RemoveHandler(lihtProjectBuilding,TMethod(OnProjBuildingEvent));
end;

procedure TLazIDEInterface.AddHandlerOnProjectDependenciesCompiling(
  const OnProjDependenciesCompilingEvent: TModalResultFunction; AsLast: boolean);
begin
  AddHandler(lihtProjectDependenciesCompiling,
             TMethod(OnProjDependenciesCompilingEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnProjectDependenciesCompiling(
  const OnProjDependenciesCompilingEvent: TModalResultFunction);
begin
  RemoveHandler(lihtProjectDependenciesCompiling,
                TMethod(OnProjDependenciesCompilingEvent));
end;

procedure TLazIDEInterface.AddHandlerOnProjectDependenciesCompiled(
  const OnProjDependenciesCompiledEvent: TModalResultFunction; AsLast: boolean
    );
begin
  AddHandler(lihtProjectDependenciesCompiled,
             TMethod(OnProjDependenciesCompiledEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnProjectDependenciesCompiled(
  const OnProjDependenciesCompiledEvent: TModalResultFunction);
begin
  RemoveHandler(lihtProjectDependenciesCompiled,
                TMethod(OnProjDependenciesCompiledEvent));
end;

procedure TLazIDEInterface.AddHandlerOnQuickSyntaxCheck(
  const OnQuickSyntaxCheckEvent: TModalHandledFunction; AsLast: boolean);
begin
  AddHandler(lihtQuickSyntaxCheck,TMethod(OnQuickSyntaxCheckEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnQuickSyntaxCheck(
  const OnQuickSyntaxCheckEvent: TModalHandledFunction);
begin
  RemoveHandler(lihtQuickSyntaxCheck,TMethod(OnQuickSyntaxCheckEvent));
end;

procedure TLazIDEInterface.AddHandlerGetFPCFrontEndParams(
  const Handler: TGetFPCFrontEndParams; AsLast: boolean);
begin
  AddHandler(lihtGetFPCFrontEndParams,TMethod(Handler),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerGetFPCFrontEndParams(
  const Handler: TGetFPCFrontEndParams);
begin
  RemoveHandler(lihtGetFPCFrontEndParams,TMethod(Handler));
end;

function TLazIDEInterface.CallHandlerGetFPCFrontEndParams(Sender: TObject;
  var Params: string): boolean;
var
  i: longint;
begin
  i:=FLazarusIDEHandlers[lihtGetFPCFrontEndParams].Count;
  while FLazarusIDEHandlers[lihtGetFPCFrontEndParams].NextDownIndex(i) do
  begin
    if not TGetFPCFrontEndParams(FLazarusIDEHandlers[lihtGetFPCFrontEndParams][i])(Self,Params)
    then exit(false);
  end;
  Result:=true;
end;

procedure TLazIDEInterface.AddHandlerGetFPCFrontEndPath(
  const Handler: TGetFPCFrontEndPath; AsLast: boolean);
begin
  AddHandler(lihtGetFPCFrontEndPath,TMethod(Handler),AsLast);
end;


procedure TLazIDEInterface.RemoveHandlerGetFPCFrontEndPath(
  const Handler: TGetFPCFrontEndPath);
begin
  RemoveHandler(lihtGetFPCFrontEndPath,TMethod(Handler));
end;

function TLazIDEInterface.CallHandlerGetFPCFrontEndPath(Sender: TObject;
  var Path: string): boolean;
var
  i: longint;
begin
  i:=FLazarusIDEHandlers[lihtGetFPCFrontEndPath].Count;
  while FLazarusIDEHandlers[lihtGetFPCFrontEndPath].NextDownIndex(i) do
  begin
    if not TGetFPCFrontEndPath(FLazarusIDEHandlers[lihtGetFPCFrontEndPath][i])(Self,Path)
    then exit(false);
  end;
  Result:=true;
end;

procedure TLazIDEInterface.AddHandlerOnUpdateIDEComponentPalette(
  const OnUpdateIDEComponentPaletteEvent: TNotifyEvent; AsLast: boolean);
begin
  AddHandler(lihtUpdateIDEComponentPalette,TMethod(OnUpdateIDEComponentPaletteEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnUpdateIDEComponentPalette(
  const OnUpdateIDEComponentPaletteEvent: TNotifyEvent);
begin
  RemoveHandler(lihtUpdateIDEComponentPalette,TMethod(OnUpdateIDEComponentPaletteEvent));
end;

procedure TLazIDEInterface.AddHandlerOnUpdateComponentPageControl(
  const OnUpdateComponentPageControlEvent: TNotifyEvent; AsLast: boolean);
begin
  AddHandler(lihtUpdateComponentPageControl,TMethod(OnUpdateComponentPageControlEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnUpdateComponentPageControl(
  const OnUpdateComponentPageControlEvent: TNotifyEvent);
begin
  RemoveHandler(lihtUpdateComponentPageControl,TMethod(OnUpdateComponentPageControlEvent));
end;

procedure TLazIDEInterface.AddHandlerOnShowDesignerFormOfSource(
  const OnShowDesignerFormOfSourceEvent: TShowDesignerFormOfSourceFunction; AsLast: boolean);
begin
  AddHandler(lihtShowDesignerFormOfSource,TMethod(OnShowDesignerFormOfSourceEvent),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnShowDesignerFormOfSource(
  const OnShowDesignerFormOfSourceEvent: TShowDesignerFormOfSourceFunction);
begin
  RemoveHandler(lihtShowDesignerFormOfSource,TMethod(OnShowDesignerFormOfSourceEvent));
end;

procedure TLazIDEInterface.AddHandlerOnShowSourceOfActiveDesignerForm(
  const OnShowSourceOfActiveDesignerForm: TNotifyEvent; AsLast: boolean);
begin
  AddHandler(lihtShowSourceOfActiveDesignerForm,TMethod(OnShowSourceOfActiveDesignerForm),AsLast);
end;

procedure TLazIDEInterface.RemoveHandlerOnShowSourceOfActiveDesignerForm(
  const OnShowSourceOfActiveDesignerForm: TNotifyEvent);
begin
  RemoveHandler(lihtShowSourceOfActiveDesignerForm,TMethod(OnShowSourceOfActiveDesignerForm));
end;

initialization
  RegisterPropertyEditor(TypeInfo(AnsiString),
    THTMLBrowserHelpViewer,'BrowserPath',TFileNamePropertyEditor);

end.

