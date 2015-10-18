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
  
  Abstract:
    This unit defines a class to store the options in a xml file.

}
unit EnvironmentOpts;

{$mode objfpc}{$H+}

interface

uses
{$IFDEF IDE_MEM_CHECK}
  MemCheck,
{$ENDIF}
{$ifdef Windows}
  ShlObj,
{$endif}
  Classes, SysUtils, TypInfo, contnrs, Graphics, Controls, Forms, Dialogs,
  LCLProc, FileProcs, LazFileUtils, LazFileCache, LazConfigStorage,
  Laz2_XMLCfg, LazUTF8,
  // IDEIntf
  ProjectIntf, ObjectInspector, IDEWindowIntf, IDEOptionsIntf,
  ComponentReg, IDEExternToolIntf, MacroDefIntf, DbgIntfDebuggerBase,
  // IDE
  IDEProcs, DialogProcs, LazarusIDEStrConsts, IDETranslations, LazConf,
  IDEOptionDefs, TransferMacros, ModeMatrixOpts, Debugger,
  IdeCoolbarData, EditorToolbarStatic;

const
  EnvOptsVersion: integer = 109;
  // 107 added Lazarus version
  // 108 added LastCalledByLazarusFullPath
  // 109 changed paths for desktop settings, supporting multiple desktops.

  {$IFDEF Windows}
  DefaultMakefilename = '$Path($(CompPath))make.exe';
  {$ELSE}
    {$IFDEF FreeBSD}
    DefaultMakefilename = 'gmake';
    {$ELSE}
    DefaultMakefilename = 'make';
    {$ENDIF}
  {$ENDIF}

  RestoreProjectClosed = '-';
  DefaultMaxRecentOpenFiles = 10;
  DefaultMaxRecentProjectFiles = 5;
  DefaultMaxRecentPackageFiles = 10;

  DefaultAutoSaveIntervalInSecs = 300;

  DefaultRubberbandSelectsGrandChilds = false;
  DefaultGridColor = clBlack;
  DefaultGridSize = 8;
  DefaultGuideLineColorLeftTop = clBlue;
  DefaultGuideLineColorRightBottom = clGreen;

  //----------------------------------------------------------------------------
  
  { Backup }
type
  TBackupType = (
     bakNone,             // no backup files
     bakSymbolInFront,    // .~pp
     bakSymbolBehind,     // .pp~
     bakCounter,          // .pp;1
     bakUserDefinedAddExt,// .pp.xxx
     bakSameName          // .pp  only available if backuping into subdirectory
   );

  TBackupInfo = record
    BackupType: TBackupType;
    AdditionalExtension:string;  // for bakUserDefinedAddExt
    MaxCounter: integer;         // for bakCounter
    SubDirectory: string;
  end;
  
  
  { Debugging }

type
  TDebuggerEventLogColor = record
    Foreground: TColor;
    Background: TColor;
  end;

const
  DebuggerDefaultColors: array[TDBGEventType] of TDebuggerEventLogColor = (
{ etDefault              } (Foreground: clWindowText; Background: clWindow),
{ etBreakpointEvaluation } (Foreground: $8080FF;      Background: clWindow),
{ etBreakpointHit        } (Foreground: clRed;        Background: clWindow),
{ etBreakpointMessage    } (Foreground: $0000D9;      Background: clWindow),
{ etBreakpointStackDump  } (Foreground: $2080FF;      Background: clWindow),
{ etExceptionRaised      } (Foreground: clTeal;       Background: clWindow),
{ etModuleLoad           } (Foreground: clBlue;       Background: clWindow),
{ etModuleUnload         } (Foreground: clBlue;       Background: clWindow),
{ etOutputDebugString    } (Foreground: clNavy;       Background: clWindow),
{ etProcessExit          } (Foreground: clGray;       Background: clWindow),
{ etProcessStart         } (Foreground: clGray;       Background: clWindow),
{ etThreadExit           } (Foreground: clMaroon;     Background: clWindow),
{ etThreadStart          } (Foreground: clMaroon;     Background: clWindow),
{ etWindowsMessagePosted } (Foreground: clWhite;      Background: clGray),
{ etWindowsMessageSent   } (Foreground: clSkyBlue;    Background: clWindow)
  );

{ Naming }

type
  TPascalExtType = (petNone, petPAS, petPP, petP);

const
  PascalExtension: array[TPascalExtType] of string = ('', '.pas', '.pp', '.p');


  { Ambiguous files }
type
  TAmbiguousFileAction = (
      afaAsk,
      afaAutoDelete,
      afaAutoRename,
      afaWarnOnCompile,
      afaIgnore
    );
  TAmbiguousFileActions = set of TAmbiguousFileAction;
  
const
  AmbiguousFileActionNames: array[TAmbiguousFileAction] of string = (
      'Ask',
      'AutoDelete',
      'AutoRename',
      'WarnOnCompile',
      'Ignore'
    );

type
  TCharCaseFileAction = (
      ccfaAsk,
      ccfaAutoRename,
      ccfaIgnore
    );
  TCharCaseFileActions = set of TCharCaseFileAction;

const
  CharCaseFileActionNames: array[TCharCaseFileAction] of string = (
      'Ask',
      'AutoRename',
      'Ignore'
    );

type
  TUnitRenameReferencesAction = (
    urraAlways, // update references in other files
    urraAsk,    // scan, then ask, then update
    urraNever   // don't scan, don't ask, don't update
    );
  TUnitRenameReferencesActions = set of TUnitRenameReferencesAction;

const
  UnitRenameReferencesActionNames: array[TUnitRenameReferencesAction] of string = (
      'Always',
      'Ask',
      'Never'
    );

type
  TIDEMultipleInstancesOption = (mioAlwaysStartNew, mioOpenFilesInRunning, mioForceSingleInstance);
const
  IDEMultipleInstancesOptionNames: array[TIDEMultipleInstancesOption] of string = (
    'AlwaysStartNew',      // mioAlwaysStartNew
    'OpenFilesInRunning',  // mioOpenFilesInRunning
    'ForceSingleInstance'  // mioForceSingleInstance
    );
  DefaultIDEMultipleInstancesOption = mioOpenFilesInRunning;

  { Messages window }
type
  TMsgWndFileNameStyle = (
    mwfsShort,    // = ExtractFilename
    mwfsRelative, // = CreateRelativePath
    mwfsFull
    );
  TMsgWndFileNameStyles = set of TMsgWndFileNameStyle;
const
  MsgWndFileNameStyleNames: array[TMsgWndFileNameStyle] of string = (
    'Short',    // mwfsShort
    'Relative', // mwfsRelative
    'Full'      // mwfsFull
    );
type
  TMsgWndColor = (
    mwBackground,
    mwRunning,
    mwSuccess,
    mwFailed,
    mwAutoHeader,
    mwTextColor
    );
const
  MsgWndDefBackgroundColor = clWindow;
  MsgWndDefHeaderBackgroundRunning = clYellow;
  MsgWndDefHeaderBackgroundSuccess = TColor($60FF60); // light green
  MsgWndDefHeaderBackgroundFailed = TColor($6060FF); // light red
  MsgWndDefAutoHeaderBackground = clSkyBlue;
  MsgWndDefTextColor = clDefault;

  MsgWndDefaultColors: array[TMsgWndColor] of TColor = (
    MsgWndDefBackgroundColor,         // mwBackground
    MsgWndDefHeaderBackgroundRunning, // mwRunning
    MsgWndDefHeaderBackgroundSuccess, // mwSuccess
    MsgWndDefHeaderBackgroundFailed,  // mwFailed
    MsgWndDefAutoHeaderBackground,    // mwAutoHeader
    MsgWndDefTextColor
    );
  MsgWndColorNames: array[TMsgWndColor] of string = (
    'Background',
    'Running',
    'Success',
    'Failed',
    'AutoHeader',
    'TextColor'
    );

  { External Tools - the user menu items in the Tools menu }
type
  TBaseExternalUserTools = class
  public
    constructor Create; virtual; abstract;
    function Load(Config: TConfigStorage; const Path: string): TModalResult; virtual; abstract;
    function Save(Config: TConfigStorage; const Path: string): TModalResult; virtual; abstract;
  end;
  TExternalUserToolsClass = class of TBaseExternalUserTools;
var
  ExternalUserToolsClass: TExternalUserToolsClass; // set by ExtToolEditDlg to TExternalUserTools

type
  TEnvOptParseType = (
    eopLazarusDirectory,
    eopCompilerFilename,
    eopFPCSourceDirectory,
    eopTestBuildDirectory,
    eopMakeFilename,
    eopFPDocPaths,
    eopCompilerMessagesFilename,
    eopDebuggerFilename,
    eopDebuggerSearchPath
    );
  TEnvOptParseTypes = set of TEnvOptParseType;

type

  TLastOpenPackagesList = class(TStringList)
  public
    function Remove(const aString: string): Boolean;
    constructor Create;
  end;

  { TDesktopOpt }

  TDesktopOpt = class
  private
    FName: String;
    FIsDocked: Boolean;
    FXMLCfg: TRttiXMLConfig;
    FConfigStore: TXMLOptionsStorage;
    // window layout
    FIDEWindowCreatorsLayoutList: TSimpleWindowLayoutList;
    FIDEDialogLayoutList: TIDEDialogLayoutList;
    FSingleTaskBarButton: boolean;
    FHideIDEOnRun: boolean;
    FAutoAdjustIDEHeight: boolean;
    FAutoAdjustIDEHeightFullCompPal: boolean;
    // window menu
    FIDENameForDesignedFormList: boolean;
    // CompletionWindow
    FCompletionWindowWidth: Integer;
    FCompletionWindowHeight: Integer;
    // title
    FIDETitleStartsWithProject: boolean;
    FIDETitleIncludesBuildMode: boolean;
    FIDEProjectDirectoryInIdeTitle: boolean;
    // IDE Coolbar
    FIDECoolBarOptions: TIDECoolBarOptions;
    // Editor Toolbar
    FEditorToolBarOptions: TEditorToolBarOptions;
    // component palette
    FComponentPaletteOptions: TCompPaletteOptions;

    //Docking options
    FDockedOpt: TAbstractDesktopDockingOpt;

    function GetCompatible: Boolean;
    procedure InitLayoutList;
  public
    constructor Create(const aName: String);
    constructor Create(const aName: String; const aIsDocked: Boolean);
    destructor Destroy; override;
    procedure Assign(Source: TDesktopOpt; const AssignName: Boolean = False);
  public
    procedure SetConfig(aXMLCfg: TRttiXMLConfig; aConfigStore: TXMLOptionsStorage);
    procedure Load(Path: String);
    procedure Save(Path: String);
    procedure ImportSettingsFromIDE;
    procedure ExportSettingsToIDE;
    procedure RestoreDesktop;

    property Name: String read FName write FName;
    property IDEWindowCreatorsLayoutList: TSimpleWindowLayoutList read FIDEWindowCreatorsLayoutList write FIDEWindowCreatorsLayoutList;
    property IDEDialogLayoutList: TIDEDialogLayoutList read FIDEDialogLayoutList;
    property SingleTaskBarButton: boolean read FSingleTaskBarButton write FSingleTaskBarButton;
    property HideIDEOnRun: boolean read FHideIDEOnRun write FHideIDEOnRun;
    property AutoAdjustIDEHeight: Boolean read FAutoAdjustIDEHeight write FAutoAdjustIDEHeight;
    property AutoAdjustIDEHeightFullCompPal: Boolean read FAutoAdjustIDEHeightFullCompPal
                                                     write FAutoAdjustIDEHeightFullCompPal;
    property IDENameForDesignedFormList: boolean read FIDENameForDesignedFormList
                                               write FIDENameForDesignedFormList;
    property CompletionWindowWidth: Integer read FCompletionWindowWidth write FCompletionWindowWidth;
    property CompletionWindowHeight: Integer read FCompletionWindowHeight write FCompletionWindowHeight;
    property IDETitleStartsWithProject: boolean read FIDETitleStartsWithProject
                                               write FIDETitleStartsWithProject;
    property IDETitleIncludesBuildMode: boolean read FIDETitleIncludesBuildMode
                                               write FIDETitleIncludesBuildMode;
    property IDEProjectDirectoryInIdeTitle: boolean read FIDEProjectDirectoryInIdeTitle
                                                    write FIDEProjectDirectoryInIdeTitle;
    property IDECoolBarOptions: TIDECoolBarOptions read FIDECoolBarOptions;
    property EditorToolBarOptions: TEditorToolBarOptions read FEditorToolBarOptions;
    property ComponentPaletteOptions: TCompPaletteOptions read FComponentPaletteOptions;
    property IsDocked: Boolean read FIsDocked;
    property Compatible: Boolean read GetCompatible;
  end;

  TEnvironmentOptions = class;

  { TDesktopOptList }

  TDesktopOptList = class(TObjectList)
  private
    FXMLCfg: TRttiXMLConfig;
    FConfigStore: TXMLOptionsStorage;
    FEnvOpts: TEnvironmentOptions;
    function GetItem(Index: Integer): TDesktopOpt;
    procedure SetConfig(aXMLCfg: TRttiXMLConfig; aConfigStore: TXMLOptionsStorage);
  public
    constructor Create(aEnvOpts: TEnvironmentOptions);
    destructor Destroy; override;
    procedure AddFromCfg(Path: String);
    function IndexOf(aName: string): integer;
    function Find(aName: string): TDesktopOpt;
    property Items[Index: Integer]: TDesktopOpt read GetItem; default;
  end;

  { TEnvironmentOptions - class for storing environment options }

  TEnvironmentOptions = class(TAbstractIDEEnvironmentOptions)
  private
    // config file
    FFilename: string;
    FFileAge: longint;
    FFileVersion: integer;
    FFileHasChangedOnDisk: boolean;
    FMaxExtToolsInParallel: integer;
    FOldLazarusVersion: string;
    FXMLCfg: TRttiXMLConfig;
    FConfigStore: TXMLOptionsStorage;
    FDbgConfigStore: TXMLOptionsStorage; // for debugger

    // main buttons
    FShowButtonGlyphs: TApplicationShowGlyphs;
    FShowMenuGlyphs: TApplicationShowGlyphs;

    // auto save
    FAutoSaveEditorFiles: boolean;
    FAutoSaveProject: boolean;
    FAutoSaveIntervalInSecs: integer;
    FLastSavedProjectFile: string;
    FLastOpenPackages: TLastOpenPackagesList;//list of filenames with open packages

    // designer
    FCreateComponentFocusNameProperty: boolean;
    FSwitchToFavoritesOITab: boolean;
    FDesignerPaintLazy: boolean;
    FShowBorderSpacing: boolean;
    FShowGrid: boolean;
    FSnapToGrid: boolean;
    FGridSizeX: integer;
    FGridSizeY: integer;
    FGridColor: TColor;
    FShowGuideLines: boolean;
    FSnapToGuideLines: boolean;
    FGuideLineColorLeftTop: TColor;
    FGuideLineColorRightBottom: TColor;
    FShowComponentCaptions: boolean;
    FShowEditorHints: boolean;
    FAutoCreateFormsOnOpen: boolean;
    FRightClickSelects: boolean;
    FGrabberColor: TColor;
    FMarkerColor: TColor;
    FRubberbandSelectionColor: TColor;
    FRubberbandCreationColor: TColor;
    FRubberbandSelectsGrandChilds: boolean;
    FCheckPackagesOnFormCreate: boolean;

    // object inspector
    FObjectInspectorOptions: TOIOptions;
    // project inspector
    FProjInspSortAlphabetically: boolean;
    FProjInspShowDirHierarchy: boolean;

    // package editor
    FPackageEditorSortAlphabetically: boolean;
    FPackageEditorShowDirHierarchy: boolean;

    // hints
    FAskSaveSessionOnly: boolean;
    FCheckDiskChangesWithLoading: boolean;
    FShowHintsForComponentPalette: boolean;
    FShowHintsForMainSpeedButtons: boolean;
    
    // messages
    fMsgViewDblClickJumps: boolean;
    fMsgViewFocus: boolean;
    FShowMessagesIcons: boolean;
    FMsgViewStayOnTop: boolean;
    FMsgViewShowTranslations: boolean;
    FMsgViewAlwaysDrawFocused: boolean;
    FMsgViewFilenameStyle: TMsgWndFileNameStyle;
    fMsgViewColors: array[TMsgWndColor] of TColor;
    fMsgColors: array[TMessageLineUrgency] of TColor;
    FShowCompileDialog: Boolean;       // show dialog during compile
    FAutoCloseCompileDialog: Boolean;  // auto close dialog after succesed compile
    FMsgViewFilters: TLMsgViewFilters;
    FMsgViewShowFPCMsgLinesCompiled: Boolean;

    // compiler + debugger + lazarus files
    FParseValues: array[TEnvOptParseType] of TParseString;
    FLazarusDirHistory: TStringList;
    FCompilerFileHistory: TStringList;
    FFPCSourceDirHistory: TStringList;
    FMakeFileHistory: TStringList;
    FTestBuildDirHistory: TStringList;
    FCompilerMessagesFileHistory: TStringList;
    FBuildMatrixOptions: TBuildMatrixOptions;
    FUseBuildModes: Boolean;
    FIsGlobalMode: TStrToBoolEvent;

    // Primary-config verification
    FLastCalledByLazarusFullPath: String;

   // TODO: store per debuggerclass options
    // Maybe these should go to a new TDebuggerOptions class
    FDebuggerResetAfterRun: boolean;
    FDebuggerConfig: TDebuggerConfigStore;
    FDebuggerFileHistory: TStringList; // per debugger class
    FDebuggerProperties: TStringList; // per debugger class
    FDebuggerShowStopMessage: Boolean;
    FDebuggerEventLogClearOnRun: Boolean;
    FDebuggerEventLogCheckLineLimit: Boolean;
    FDebuggerEventLogLineLimit: Integer;
    FDebuggerEventLogShowBreakpoint: Boolean;
    FDebuggerEventLogShowDebugger: Boolean;
    FDebuggerEventLogShowModule: Boolean;
    FDebuggerEventLogShowOutput: Boolean;
    FDebuggerEventLogShowProcess: Boolean;
    FDebuggerEventLogShowThread: Boolean;
    FDebuggerEventLogShowWindows: Boolean;
    FDebuggerEventLogUseColors: Boolean;
    FDebuggerEventLogColors: array[TDBGEventType] of TDebuggerEventLogColor;

    // recent files and directories
    FRecentOpenFiles: TStringList;
    FMaxRecentOpenFiles: integer;
    FRecentProjectFiles: TStringList;
    FMaxRecentProjectFiles: integer;
    FRecentPackageFiles: TStringList;
    FMaxRecentPackageFiles: integer;
    FOpenLastProjectAtStart: boolean;
    FMultipleInstances: TIDEMultipleInstancesOption;
    // Prevent repopulating Recent project files menu with example projects if it was already cleared up.
    FAlreadyPopulatedRecentFiles : Boolean;

    // backup
    FBackupInfoProjectFiles: TBackupInfo;
    FBackupInfoOtherFiles: TBackupInfo;
    
    // external tools
    fExternalUserTools: TBaseExternalUserTools; // see ExtToolEditDlg.TExternalUserTools

    // naming conventions
    fPascalFileExtension: TPascalExtType;
    fCharcaseFileAction: TCharCaseFileAction;
    fAmbiguousFileAction: TAmbiguousFileAction;
    FUnitRenameReferencesAction: TUnitRenameReferencesAction;
    FAskForFilenameOnNewFile: boolean;
    FLowercaseDefaultFilename: boolean;

    // language ID (see LazarusTranslations in translations.pas)
    fLanguageID: string;

    // 'new items'
    FNewFormTemplate: string;
    FNewUnitTemplate: string;
    FFileDialogFilter: string;

    // Desktop
    FDesktops: TDesktopOptList;
    FDesktop: TDesktopOpt;
    FLastDesktopBeforeDebug: TDesktopOpt;
    FActiveDesktopName: string;
    FAutoSaveActiveDesktop: Boolean;
    FDebugDesktopName: string;

    function GetActiveDesktop: TDesktopOpt;
    function GetCompilerFilename: string;
    function GetCompilerMessagesFilename: string;
    function GetDebugDesktop: TDesktopOpt;
    function GetDebuggerEventLogColors(AIndex: TDBGEventType): TDebuggerEventLogColor;
    function GetDebuggerFilename: string;
    function GetDebuggerSearchPath: string;
    function GetFPCSourceDirectory: string;
    function GetFPDocPaths: string;
    function GetLazarusDirectory: string;
    function GetMakeFilename: string;
    function GetMsgColors(u: TMessageLineUrgency): TColor;
    function GetMsgViewColors(c: TMsgWndColor): TColor;
    function GetTestBuildDirectory: string;
    procedure LoadNonDesktop(Path: String);
    procedure SaveNonDesktop(Path: String);
    procedure SetCompilerFilename(const AValue: string);
    procedure SetCompilerMessagesFilename(AValue: string);
    procedure SetDebuggerEventLogColors(AIndex: TDBGEventType;
      const AValue: TDebuggerEventLogColor);
    procedure SetDebuggerSearchPath(const AValue: string);
    procedure SetFPDocPaths(const AValue: string);
    procedure SetMakeFilename(const AValue: string);
    procedure SetDebuggerFilename(AValue: string);
    procedure SetFPCSourceDirectory(const AValue: string);
    procedure SetLazarusDirectory(const AValue: string);
    procedure SetMsgColors(u: TMessageLineUrgency; AValue: TColor);
    procedure SetMsgViewColors(c: TMsgWndColor; AValue: TColor);
    procedure SetParseValue(o: TEnvOptParseType; const NewValue: string);

    procedure SetFileName(const NewFilename: string);
    function FileHasChangedOnDisk: boolean;
    procedure InitXMLCfg(CleanConfig: boolean);
    procedure FileUpdated;
    procedure SetTestBuildDirectory(const AValue: string);
  public
    class function GetGroupCaption:string; override;
    class function GetInstance: TAbstractIDEOptions; override;
    procedure DoAfterWrite(Restore: boolean); override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(OnlyDesktop: boolean);
    procedure Save(OnlyDesktop: boolean);
    property IsGlobalMode: TStrToBoolEvent read FIsGlobalMode write FIsGlobalMode;
    property Filename: string read FFilename write SetFilename;
    function GetDefaultConfigFilename: string;
    procedure CreateConfig;
    property OldLazarusVersion: string read FOldLazarusVersion;

    function GetParsedLazarusDirectory: string;
    function GetParsedTestBuildDirectory: string;
    function GetParsedCompilerFilename: string;
    function GetParsedFPCSourceDirectory(FPCVer: string = ''): string;
    function GetParsedMakeFilename: string;
    function GetParsedCompilerMessagesFilename: string;
    function GetParsedFPDocPaths: string;
    function GetParsedDebuggerFilename: string;
    function GetParsedDebuggerSearchPath: string;
    function GetParsedValue(o: TEnvOptParseType): string;

    // macros
    procedure InitMacros(AMacroList: TTransferMacroList);
    function MacroFuncFPCSrcDir(const {%H-}s:string; const {%H-}Data: PtrInt;
                                var {%H-}Abort: boolean): string;
    function MacroFuncLazarusDir(const {%H-}s:string; const {%H-}Data: PtrInt;
                                 var {%H-}Abort: boolean): string;
    function MacroFuncExeExt(const {%H-}s:string; const {%H-}Data: PtrInt;
                                 var {%H-}Abort: boolean): string;
    function MacroFuncLanguageID(const {%H-}s:string; const {%H-}Data: PtrInt;
                                 var {%H-}Abort: boolean): string;
    function MacroFuncLanguageName(const {%H-}s:string; const {%H-}Data: PtrInt;
                                   var {%H-}Abort: boolean): string;
    function MacroFuncTestDir(const {%H-}s:string; const {%H-}Data: PtrInt;
                              var {%H-}Abort: boolean): string;
    function MacroFuncConfDir(const {%H-}s:string; const {%H-}Data: PtrInt;
                              var {%H-}Abort: boolean): string;

    procedure UseDesktop(ADesktop: TDesktopOpt);
    procedure EnableDebugDesktop;
    procedure DisableDebugDesktop;
    class function DesktopCanBeLoaded(const aDockMaster: string): Boolean;

    // auto save
    // ask even if only project session needs saving
    property AskSaveSessionOnly: boolean read FAskSaveSessionOnly write FAskSaveSessionOnly;
    property AutoSaveEditorFiles: boolean read FAutoSaveEditorFiles write FAutoSaveEditorFiles;
    property AutoSaveProject: boolean read FAutoSaveProject write FAutoSaveProject;
    property AutoSaveIntervalInSecs: integer read FAutoSaveIntervalInSecs write FAutoSaveIntervalInSecs;
       
    // form editor
    property ShowBorderSpacing: boolean read FShowBorderSpacing write FShowBorderSpacing;
    property ShowGrid: boolean read FShowGrid write FShowGrid;
    property SnapToGrid: boolean read FSnapToGrid write FSnapToGrid;
    property GridColor: TColor read FGridColor write FGridColor;
    property GridSizeX: integer read FGridSizeX write FGridSizeX;
    property GridSizeY: integer read FGridSizeY write FGridSizeY;
    property ShowGuideLines: boolean read FShowGuideLines write FShowGuideLines;
    property SnapToGuideLines: boolean read FSnapToGuideLines write FSnapToGuideLines;
    property GuideLineColorLeftTop: TColor read FGuideLineColorLeftTop
                                           write FGuideLineColorLeftTop;
    property GuideLineColorRightBottom: TColor read FGuideLineColorRightBottom
                                               write FGuideLineColorRightBottom;
    property ShowComponentCaptions: boolean  read FShowComponentCaptions
                                            write FShowComponentCaptions;
    property ShowEditorHints: boolean read FShowEditorHints
                                      write FShowEditorHints;
    property AutoCreateFormsOnOpen: boolean read FAutoCreateFormsOnOpen
                                            write FAutoCreateFormsOnOpen;
    property CheckPackagesOnFormCreate: boolean read FCheckPackagesOnFormCreate
                                                write FCheckPackagesOnFormCreate;
    property RightClickSelects: boolean read FRightClickSelects
                                        write FRightClickSelects;
    property GrabberColor: TColor read FGrabberColor write FGrabberColor;
    property MarkerColor: TColor read FMarkerColor write FMarkerColor;
    property RubberbandSelectionColor: TColor read FRubberbandSelectionColor
                                              write FRubberbandSelectionColor;
    property RubberbandCreationColor: TColor read FRubberbandCreationColor
                                             write FRubberbandCreationColor;
    property RubberbandSelectsGrandChilds: boolean read FRubberbandSelectsGrandChilds
                                                  write FRubberbandSelectsGrandChilds;
    property DesignerPaintLazy: boolean read FDesignerPaintLazy
                                        write FDesignerPaintLazy;
    property CreateComponentFocusNameProperty: boolean read FCreateComponentFocusNameProperty
                                                      write FCreateComponentFocusNameProperty;
    property SwitchToFavoritesOITab: boolean read FSwitchToFavoritesOITab
                                             write FSwitchToFavoritesOITab;
    // object inspector
    property ObjectInspectorOptions: TOIOptions read FObjectInspectorOptions;

    // project inspector
    property ProjInspSortAlphabetically: boolean read FProjInspSortAlphabetically
                                                write FProjInspSortAlphabetically;
    property ProjInspShowDirHierarchy: boolean read FProjInspShowDirHierarchy
                                              write FProjInspShowDirHierarchy;
    // package editor
    property PackageEditorSortAlphabetically: boolean read FPackageEditorSortAlphabetically
                                                     write FPackageEditorSortAlphabetically;
    property PackageEditorShowDirHierarchy: boolean read FPackageEditorShowDirHierarchy
                                                   write FPackageEditorShowDirHierarchy;
    // hints
    property CheckDiskChangesWithLoading: boolean read FCheckDiskChangesWithLoading
                                                 write FCheckDiskChangesWithLoading;
    property ShowHintsForComponentPalette: boolean read FShowHintsForComponentPalette
                                                  write FShowHintsForComponentPalette;
    property ShowHintsForMainSpeedButtons: boolean read FShowHintsForMainSpeedButtons
                                                  write FShowHintsForMainSpeedButtons;
    // files
    property LazarusDirectory: string read GetLazarusDirectory write SetLazarusDirectory;
    property LazarusDirHistory: TStringList read FLazarusDirHistory write FLazarusDirHistory;
    property CompilerFilename: string read GetCompilerFilename write SetCompilerFilename;
    property CompilerFileHistory: TStringList read FCompilerFileHistory write FCompilerFileHistory;
    property FPCSourceDirectory: string read GetFPCSourceDirectory write SetFPCSourceDirectory;
    property FPCSourceDirHistory: TStringList read FFPCSourceDirHistory;
    property MakeFilename: string read GetMakeFilename write SetMakeFilename;
    property MakeFileHistory: TStringList read FMakeFileHistory;
    property DebuggerFilename: string read GetDebuggerFilename write SetDebuggerFilename;
    property DebuggerFileHistory: TStringList read FDebuggerFileHistory;
    property DebuggerSearchPath: string read GetDebuggerSearchPath write SetDebuggerSearchPath;
    property DebuggerShowStopMessage: boolean read FDebuggerShowStopMessage write FDebuggerShowStopMessage;
    property DebuggerResetAfterRun: boolean read FDebuggerResetAfterRun write FDebuggerResetAfterRun;
    // ShowCompileDialog and AutoCloseCompileDialog are currently not used.
    // But maybe someone will implement them again. Keep them till 1.4.2
    property ShowCompileDialog: boolean read  FShowCompileDialog write FShowCompileDialog;
    property AutoCloseCompileDialog: boolean read  FAutoCloseCompileDialog write FAutoCloseCompileDialog;
    property TestBuildDirectory: string read GetTestBuildDirectory write SetTestBuildDirectory;
    property TestBuildDirHistory: TStringList read FTestBuildDirHistory;
    property CompilerMessagesFilename: string read GetCompilerMessagesFilename
              write SetCompilerMessagesFilename; // non English translation file
    property CompilerMessagesFileHistory: TStringList read FCompilerMessagesFileHistory;

    // Primary-config verification
    property LastCalledByLazarusFullPath: String read FLastCalledByLazarusFullPath write FLastCalledByLazarusFullPath;

    // global build options
    property BuildMatrixOptions: TBuildMatrixOptions read FBuildMatrixOptions;
    property UseBuildModes: Boolean read FUseBuildModes write FUseBuildModes;

    // Debugger
    procedure SaveDebuggerPropertiesList;
    procedure SaveDebuggerProperties(DebuggerClass: String; Properties: TDebuggerProperties);
    procedure LoadDebuggerProperties(DebuggerClass: String; Properties: TDebuggerProperties);
    property  DebuggerConfig: TDebuggerConfigStore read FDebuggerConfig;

    // Debugger event log
    property DebuggerEventLogClearOnRun: Boolean read FDebuggerEventLogClearOnRun write FDebuggerEventLogClearOnRun;
    property DebuggerEventLogCheckLineLimit: Boolean read FDebuggerEventLogCheckLineLimit write FDebuggerEventLogCheckLineLimit;
    property DebuggerEventLogLineLimit: Integer read FDebuggerEventLogLineLimit write FDebuggerEventLogLineLimit;
    property DebuggerEventLogShowBreakpoint: Boolean read FDebuggerEventLogShowBreakpoint write FDebuggerEventLogShowBreakpoint;
    property DebuggerEventLogShowProcess: Boolean read FDebuggerEventLogShowProcess write FDebuggerEventLogShowProcess;
    property DebuggerEventLogShowThread: Boolean read FDebuggerEventLogShowThread write FDebuggerEventLogShowThread;
    property DebuggerEventLogShowModule: Boolean read FDebuggerEventLogShowModule write FDebuggerEventLogShowModule;
    property DebuggerEventLogShowOutput: Boolean read FDebuggerEventLogShowOutput write FDebuggerEventLogShowOutput;
    property DebuggerEventLogShowWindows: Boolean read FDebuggerEventLogShowWindows write FDebuggerEventLogShowWindows;
    property DebuggerEventLogShowDebugger: Boolean read FDebuggerEventLogShowDebugger write FDebuggerEventLogShowDebugger;
    property DebuggerEventLogUseColors: Boolean read FDebuggerEventLogUseColors write FDebuggerEventLogUseColors;
    property DebuggerEventLogColors[AIndex: TDBGEventType]: TDebuggerEventLogColor read GetDebuggerEventLogColors write SetDebuggerEventLogColors;

    // recent files and directories
    property RecentOpenFiles: TStringList read FRecentOpenFiles;
    property MaxRecentOpenFiles: integer read FMaxRecentOpenFiles
                                         write FMaxRecentOpenFiles;
    procedure AddToRecentOpenFiles(const AFilename: string);
    procedure RemoveFromRecentOpenFiles(const AFilename: string);
    property RecentProjectFiles: TStringList read FRecentProjectFiles;
    property MaxRecentProjectFiles: integer read FMaxRecentProjectFiles
                                            write FMaxRecentProjectFiles;
    procedure AddToRecentProjectFiles(const AFilename: string);
    procedure RemoveFromRecentProjectFiles(const AFilename: string);
    property RecentPackageFiles: TStringList read FRecentPackageFiles;
    property MaxRecentPackageFiles: integer read FMaxRecentPackageFiles
                                         write FMaxRecentPackageFiles;
    property LastSavedProjectFile: string read FLastSavedProjectFile
                     write FLastSavedProjectFile; { if empty then create new project,
                                                    if '-' then do not load/create any project }
    property LastOpenPackages: TLastOpenPackagesList read FLastOpenPackages;
    property OpenLastProjectAtStart: boolean read FOpenLastProjectAtStart
                                             write FOpenLastProjectAtStart;
    property MultipleInstances: TIDEMultipleInstancesOption read FMultipleInstances
                                                                write FMultipleInstances;
    property FileDialogFilter: string read FFileDialogFilter write FFileDialogFilter;

    // backup
    property BackupInfoProjectFiles: TBackupInfo read FBackupInfoProjectFiles
                                                 write FBackupInfoProjectFiles;
    property BackupInfoOtherFiles: TBackupInfo read FBackupInfoOtherFiles
                                               write FBackupInfoOtherFiles;
    // external tools
    property ExternalToolMenuItems: TBaseExternalUserTools read fExternalUserTools;
    property MaxExtToolsInParallel: integer read FMaxExtToolsInParallel
                                            write FMaxExtToolsInParallel; // 0=automatic
    // naming conventions
    property PascalFileExtension: TPascalExtType read fPascalFileExtension
                                                 write fPascalFileExtension;
    property AmbiguousFileAction: TAmbiguousFileAction read fAmbiguousFileAction
                                                     write fAmbiguousFileAction;
    property CharcaseFileAction: TCharCaseFileAction read fCharcaseFileAction
                                                     write fCharcaseFileAction;
    property UnitRenameReferencesAction: TUnitRenameReferencesAction
                                              read FUnitRenameReferencesAction
                                              write FUnitRenameReferencesAction;
    property AskForFilenameOnNewFile: boolean read FAskForFilenameOnNewFile
                                              write FAskForFilenameOnNewFile;
    property LowercaseDefaultFilename: boolean read FLowercaseDefaultFilename
                                               write FLowercaseDefaultFilename;
    // fpdoc
    property FPDocPaths: string read GetFPDocPaths write SetFPDocPaths;

    // language
    property LanguageID: string read fLanguageID write fLanguageID;
    
    // messages view
    property MsgViewDblClickJumps: boolean read fMsgViewDblClickJumps
      write fMsgViewDblClickJumps; // true=dbl click jump to error, false=single click jumps
    property MsgViewFocus: boolean read fMsgViewFocus
      write fMsgViewFocus; // when showing the message window, focus it
    property ShowMessagesIcons: boolean read FShowMessagesIcons write FShowMessagesIcons;
    property MsgViewStayOnTop: boolean read FMsgViewStayOnTop write FMsgViewStayOnTop;
    property MsgViewShowTranslations: boolean read FMsgViewShowTranslations
             write FMsgViewShowTranslations;
    property MsgViewAlwaysDrawFocused: boolean read FMsgViewAlwaysDrawFocused
             write FMsgViewAlwaysDrawFocused;
    property MsgViewFilenameStyle: TMsgWndFileNameStyle read FMsgViewFilenameStyle
                       write FMsgViewFilenameStyle;
    property MsgViewColors[c: TMsgWndColor]: TColor read GetMsgViewColors write SetMsgViewColors;
    property MsgViewFilters: TLMsgViewFilters read FMsgViewFilters;
    property MsgColors[u: TMessageLineUrgency]: TColor read GetMsgColors write SetMsgColors;
    property MsgViewShowFPCMsgLinesCompiled: Boolean read FMsgViewShowFPCMsgLinesCompiled write FMsgViewShowFPCMsgLinesCompiled;

    // glyphs
    property ShowButtonGlyphs: TApplicationShowGlyphs read FShowButtonGlyphs write FShowButtonGlyphs;
    property ShowMenuGlyphs: TApplicationShowGlyphs read FShowMenuGlyphs write FShowMenuGlyphs;

    // default template for each 'new item' category: Name=Path, Value=TemplateName
    property NewUnitTemplate: string read FNewUnitTemplate write FNewUnitTemplate;
    property NewFormTemplate: string read FNewFormTemplate write FNewFormTemplate;
    // Desktop
    property Desktops: TDesktopOptList read FDesktops;
    property Desktop: TDesktopOpt read FDesktop;               // the working desktop, standalone
    property DebugDesktopName: string read FDebugDesktopName write FDebugDesktopName;
    property DebugDesktop: TDesktopOpt read GetDebugDesktop;   // debug desktop from Desktops list
    property ActiveDesktopName: string read FActiveDesktopName write FActiveDesktopName;
    property ActiveDesktop: TDesktopOpt read GetActiveDesktop; // active desktop from Desktops list
    property AutoSaveActiveDesktop: Boolean read FAutoSaveActiveDesktop write FAutoSaveActiveDesktop;
  end;

var
  OverrideFPCVer: string = '';
  EnvironmentOptions: TEnvironmentOptions = nil;

function PascalExtToType(const Ext: string): TPascalExtType;
function AmbiguousFileActionNameToType(const Action: string): TAmbiguousFileAction;
function CharCaseFileActionNameToType(const Action: string): TCharCaseFileAction;
function UnitRenameReferencesActionNameToType(const Action: string): TUnitRenameReferencesAction;
function StrToMsgWndFilenameStyle(const s: string): TMsgWndFileNameStyle;
function StrToIDEMultipleInstancesOption(const s: string): TIDEMultipleInstancesOption;

function SimpleDirectoryCheck(const OldDir, NewDir,
  NotFoundErrMsg: string; out StopChecking: boolean): boolean;

const
  DefaultMsgViewFocus = {$IFDEF Windows}true{$ELSE}false{$ENDIF};
  MaxComboBoxCount: integer = 20;
  EnvOptsConfFileName = 'environmentoptions.xml';
  BakMaxCounterInfiniteTxt = 'infinite';

  EnvOptParseTypeNames: array[TEnvOptParseType] of string = (
    'LazarusDir', // eopLazarusDirectory
    'CompPath', // eopCompilerFilename
    'FPCSrcDir', // eopFPCSourceDirectory
    'TestDir', // eopTestBuildDirectory
    'Make', // eopMakeFilename
    'FPDocPath', // eopFPDocPaths
    'CompMsgFile', // eopCompilerMessagesFilename
    'Debugger', // eopDebuggerFilename
    'DebugPath' // eopDebuggerSearchPath
  );

function dbgs(o: TEnvOptParseType): string; overload;
function dbgs(u: TMessageLineUrgency): string; overload;

implementation

function PascalExtToType(const Ext: string): TPascalExtType;
begin
  if Ext<>'' then
    for Result:=Low(TPascalExtType) to High(TPascalExtType) do
      if CompareFilenames(Ext,PascalExtension[Result])=0 then exit;
  Result:=petNone;
end;

function AmbiguousFileActionNameToType(
  const Action: string): TAmbiguousFileAction;
begin
  for Result:=Low(TAmbiguousFileAction) to High(TAmbiguousFileAction) do
    if CompareText(AmbiguousFileActionNames[Result],Action)=0 then
      exit;
  Result:=afaAsk;
end;

function CharCaseFileActionNameToType(
  const Action: string): TCharCaseFileAction;
begin
  for Result:=Low(TCharCaseFileAction) to High(TCharCaseFileAction) do
    if CompareText(CharCaseFileActionNames[Result],Action)=0 then
      exit;
  Result:=ccfaAutoRename;
end;

function UnitRenameReferencesActionNameToType(const Action: string
  ): TUnitRenameReferencesAction;
begin
  for Result:=Low(TUnitRenameReferencesAction) to High(TUnitRenameReferencesAction) do
    if CompareText(UnitRenameReferencesActionNames[Result],Action)=0 then
      exit;
  Result:=urraAsk;
end;

function StrToMsgWndFilenameStyle(const s: string): TMsgWndFileNameStyle;
begin
  for Result in TMsgWndFileNameStyle do
    if CompareText(s,MsgWndFileNameStyleNames[Result])=0 then exit;
  Result:=mwfsShort;
end;

function StrToIDEMultipleInstancesOption(const s: string): TIDEMultipleInstancesOption;
begin
  for Result in TIDEMultipleInstancesOption do
    if CompareText(s,IDEMultipleInstancesOptionNames[Result])=0 then exit;
  Result:=DefaultIDEMultipleInstancesOption;
end;

function SimpleDirectoryCheck(const OldDir, NewDir,
  NotFoundErrMsg: string; out StopChecking: boolean): boolean;
var
  SubResult: TModalResult;
begin
  StopChecking:=true;
  if OldDir=NewDir then begin
    Result:=true;
    exit;
  end;
  SubResult:=CheckDirPathExists(NewDir,lisEnvOptDlgDirectoryNotFound,
                                NotFoundErrMsg);
  if SubResult=mrIgnore then begin
    Result:=true;
    exit;
  end;
  if SubResult=mrCancel then begin
    Result:=false;
    exit;
  end;
  StopChecking:=false;
  Result:=true;
end;

function dbgs(o: TEnvOptParseType): string;
begin
  Result:=EnvOptParseTypeNames[o];
end;

function dbgs(u: TMessageLineUrgency): string;
begin
  WriteStr(Result, u);
end;

{ TLastOpenPackagesList }

constructor TLastOpenPackagesList.Create;
begin
  inherited Create;
  Sorted:=true;
  Duplicates:=dupIgnore;
end;

function TLastOpenPackagesList.Remove(const aString: string): Boolean;
var
  xIndex: Integer;
begin
  xIndex := IndexOf(aString);
  Result := xIndex >= 0;
  if Result then
    Delete(xIndex);
end;

{ TDesktopOptList }

constructor TDesktopOptList.Create(aEnvOpts: TEnvironmentOptions);
begin
  inherited Create;
  FEnvOpts := aEnvOpts;
end;

destructor TDesktopOptList.Destroy;
begin
  inherited Destroy;
end;

procedure TDesktopOptList.SetConfig(aXMLCfg: TRttiXMLConfig; aConfigStore: TXMLOptionsStorage);
begin
  FXMLCfg := aXMLCfg;
  FConfigStore := aConfigStore;
end;

procedure TDesktopOptList.AddFromCfg(Path: String);
var
  dsk: TDesktopOpt;
  dskName, dskDockMaster: String;
begin
  dskName := FXMLCfg.GetValue(Path+'Name', 'default');
  dskDockMaster := FXMLCfg.GetValue(Path+'DockMaster', '');

  if not EnvironmentOptions.DesktopCanBeLoaded(dskDockMaster) or (IndexOf(dskName) >= 0) then
    Exit;

  dsk := TDesktopOpt.Create(dskName, dskDockMaster<>'');
  dsk.SetConfig(FXMLCfg, FConfigStore);
  dsk.Load(Path);
  Add(dsk);
end;

function TDesktopOptList.IndexOf(aName: string): integer;
begin
  Result:=Count-1;
  while (Result>=0)
  and (CompareText(aName, Items[Result].Name)<>0) do
    dec(Result);
end;

function TDesktopOptList.Find(aName: string): TDesktopOpt;
var
  i: LongInt;
begin
  i:=IndexOf(aName);
  if i>=0 then
    Result:=Items[i]
  else
    Result:=nil;
end;

function TDesktopOptList.GetItem(Index: Integer): TDesktopOpt;
begin
  Result := TDesktopOpt(inherited Items[Index]);
end;

{ TDesktopOpt }

constructor TDesktopOpt.Create(const aName: String);
begin
  Create(aName, Assigned(IDEDockMaster));
end;

constructor TDesktopOpt.Create(const aName: String; const aIsDocked: Boolean);
begin
  if aIsDocked and not Assigned(IDEDockMaster) then
    raise Exception.Create('Internal error: TEnvironmentOptions.CreateDesktop cannot create docked desktop in undocked environment.');

  inherited Create;

  FName:=aName;
  FIsDocked := aIsDocked;
  if aIsDocked then
    FDockedOpt := IDEDockMaster.DockedDesktopOptClass.Create;
  FSingleTaskBarButton:=false;
  FHideIDEOnRun:=false;
  FAutoAdjustIDEHeight:=true;
  FAutoAdjustIDEHeightFullCompPal := true;
  // window menu
  FIDENameForDesignedFormList:=false;
  // CompletionWindow
  FCompletionWindowWidth := 320;
  FCompletionWindowHeight := 6;
  // title
  FIDETitleStartsWithProject:=false;
  FIDETitleIncludesBuildMode:=false;
  FIDEProjectDirectoryInIdeTitle:=false;
  // IDE Coolbar
  FIDECoolBarOptions:=TIDECoolBarOptions.Create;
  // Editor Toolbar
  FEditorToolBarOptions:=TEditorToolBarOptions.Create;
  // component palette
  FComponentPaletteOptions:=TCompPaletteOptions.Create;
  // Windows layout
  InitLayoutList;

  FIDEDialogLayoutList:=TIDEDialogLayoutList.Create;
  FIDEWindowCreatorsLayoutList:=TSimpleWindowLayoutList.Create(False);
  FIDEDialogLayoutList.Assign(IDEWindowIntf.IDEDialogLayoutList);
  FIDEWindowCreatorsLayoutList.CopyItemsFrom(IDEWindowIntf.IDEWindowCreators.SimpleLayoutStorage);
end;

destructor TDesktopOpt.Destroy;
begin
  FreeAndNil(FComponentPaletteOptions);
  FreeAndNil(FEditorToolBarOptions);
  FreeAndNil(FIDECoolBarOptions);
  FreeAndNil(FDockedOpt);

  FreeAndNil(FIDEDialogLayoutList);
  FreeAndNil(FIDEWindowCreatorsLayoutList);

  inherited Destroy;
end;

function TDesktopOpt.GetCompatible: Boolean;
begin
  Result := (IsDocked = Assigned(IDEDockMaster));
end;

procedure TDesktopOpt.Assign(Source: TDesktopOpt; const AssignName: Boolean);
begin
  if AssignName then
    FName := Source.FName;

  if Assigned(FDockedOpt) <> Assigned(Source.FDockedOpt) then
    raise Exception.Create('Internal error: TDesktopOpt.Assign mixed docked/undocked desktops.');

  // window layout
  FIDEWindowCreatorsLayoutList.CopyItemsFrom(Source.FIDEWindowCreatorsLayoutList);
  FIDEDialogLayoutList.Assign(Source.FIDEDialogLayoutList);
  FSingleTaskBarButton := Source.FSingleTaskBarButton;
  FHideIDEOnRun := Source.FHideIDEOnRun;
  FAutoAdjustIDEHeight := Source.FAutoAdjustIDEHeight;
  FAutoAdjustIDEHeightFullCompPal := Source.FAutoAdjustIDEHeightFullCompPal;
  // window menu
  FIDENameForDesignedFormList := Source.FIDENameForDesignedFormList;
  // CompletionWindow
  FCompletionWindowWidth := Source.FCompletionWindowWidth;
  FCompletionWindowHeight := Source.FCompletionWindowHeight;
  // title
  FIDETitleStartsWithProject := Source.FIDETitleStartsWithProject;
  FIDETitleIncludesBuildMode := Source.FIDETitleIncludesBuildMode;
  FIDEProjectDirectoryInIdeTitle := Source.FIDEProjectDirectoryInIdeTitle;
  // IDE Coolbar
  FIDECoolBarOptions.Assign(Source.FIDECoolBarOptions);
  // Editor Toolbar
  FEditorToolBarOptions.Assign(Source.FEditorToolBarOptions);
  // component palette
  FComponentPaletteOptions.Assign(Source.FComponentPaletteOptions);

  if Assigned(FDockedOpt) then
    FDockedOpt.Assign(Source.FDockedOpt);
end;

procedure TDesktopOpt.Load(Path: String);
begin
  // Windows layout
  FIDEWindowCreatorsLayoutList.LoadFromConfig(FConfigStore, Path);
  FIDEDialogLayoutList.LoadFromConfig(FConfigStore, Path+'Dialogs/');

  FSingleTaskBarButton:=FXMLCfg.GetValue(Path+'SingleTaskBarButton/Value', False);
  FHideIDEOnRun:=FXMLCfg.GetValue(Path+'HideIDEOnRun/Value',false);
  FAutoAdjustIDEHeight:=FXMLCfg.GetValue(Path+'AutoAdjustIDEHeight/Value',true);
  FAutoAdjustIDEHeightFullCompPal:=FXMLCfg.GetValue(Path+'AutoAdjustIDEHeightFullComponentPalette/Value',true);
  // Window menu
  FIDENameForDesignedFormList:=FXMLCfg.GetValue(Path+'IDENameForDesignedFormList/Value',false);
  // title
  FIDETitleStartsWithProject:=FXMLCfg.GetValue(Path+'IDETitleStartsWithProject/Value',false);
  FIDETitleIncludesBuildMode:=FXMLCfg.GetValue(Path+'IDETitleIncludesBuildMode/Value',false);
  FIDEProjectDirectoryInIdeTitle:=FXMLCfg.GetValue(Path+'IDEProjectDirectoryInIdeTitle/Value',false);
  // CompletionWindow
  FCompletionWindowWidth:=FXMLCfg.GetValue(Path+'CompletionWindowWidth/Value', 320);
  FCompletionWindowHeight:=FXMLCfg.GetValue(Path+'CompletionWindowHeight/Value', 6);

  if not FXMLCfg.HasPath(Path+'IDECoolBarOptions/', True) then
    Path := '';             // Toolbars and palette were at the top level in XML.
  // IDE Coolbar
  FIDECoolBarOptions.Load(FXMLCfg, Path);
  // Editor Toolbar
  FEditorToolBarOptions.Load(FXMLCfg, Path);
  // component palette
  FComponentPaletteOptions.Load(FXMLCfg, Path);

  if Assigned(FDockedOpt) then
    FDockedOpt.Load(Path, FXMLCfg);
end;

procedure TDesktopOpt.RestoreDesktop;
begin
  IDEWindowCreators.RestoreSimpleLayout;
  if Assigned(FDockedOpt) then
    FDockedOpt.RestoreDesktop;
end;

procedure TDesktopOpt.ImportSettingsFromIDE;
begin
  IDEWindowIntf.IDEWindowCreators.SimpleLayoutStorage.StoreWindowPositions;
  FIDEDialogLayoutList.Assign(IDEWindowIntf.IDEDialogLayoutList);
  FIDEWindowCreatorsLayoutList.CopyItemsFrom(IDEWindowIntf.IDEWindowCreators.SimpleLayoutStorage);

  if Assigned(FDockedOpt) then
    FDockedOpt.ImportSettingsFromIDE;
end;

procedure TDesktopOpt.Save(Path: String);
begin
  // windows
  FXMLCfg.SetDeleteValue(Path+'Name', FName, '');
  if Assigned(FDockedOpt) then
    FXMLCfg.SetDeleteValue(Path+'DockMaster', IDEDockMaster.ClassName, '')
  else
    FXMLCfg.DeleteValue(Path+'DockMaster');

  FIDEWindowCreatorsLayoutList.SaveToConfig(FConfigStore, Path);
  FIDEDialogLayoutList.SaveToConfig(FConfigStore,Path+'Dialogs/');

  FXMLCfg.SetDeleteValue(Path+'SingleTaskBarButton/Value',FSingleTaskBarButton, False);
  FXMLCfg.SetDeleteValue(Path+'HideIDEOnRun/Value',FHideIDEOnRun,false);
  FXMLCfg.SetDeleteValue(Path+'AutoAdjustIDEHeight/Value',FAutoAdjustIDEHeight,true);
  FXMLCfg.SetDeleteValue(Path+'AutoAdjustIDEHeightFullComponentPalette/Value',
                           FAutoAdjustIDEHeightFullCompPal,true);
  // Window menu
  FXMLCfg.SetDeleteValue(Path+'IDENameForDesignedFormList/Value',FIDENameForDesignedFormList,false);
  // title
  FXMLCfg.SetDeleteValue(Path+'IDETitleStartsWithProject/Value',FIDETitleStartsWithProject,false);
  FXMLCfg.SetDeleteValue(Path+'IDETitleIncludesBuildMode/Value',FIDETitleIncludesBuildMode,false);
  FXMLCfg.SetDeleteValue(Path+'IDEProjectDirectoryInIdeTitle/Value',FIDEProjectDirectoryInIdeTitle,false);
  // CompletionWindow
  FXMLCfg.SetDeleteValue(Path+'CompletionWindowWidth/Value',FCompletionWindowWidth, 320);
  FXMLCfg.SetDeleteValue(Path+'CompletionWindowHeight/Value',FCompletionWindowHeight, 6);
  // IDE Coolbar
  FIDECoolBarOptions.Save(FXMLCfg, Path);
  // Editor Toolbar
  FEditorToolBarOptions.Save(FXMLCfg, Path);
  // component palette
  FComponentPaletteOptions.Save(FXMLCfg, Path);

  if Assigned(FDockedOpt) then
    FDockedOpt.Save(Path, FXMLCfg);
end;

procedure TDesktopOpt.ExportSettingsToIDE;
begin
  if Assigned(FDockedOpt) then
    FDockedOpt.ExportSettingsToIDE;

  IDEWindowIntf.IDEDialogLayoutList.Assign(FIDEDialogLayoutList);
  IDEWindowIntf.IDEWindowCreators.SimpleLayoutStorage.CopyItemsFrom(FIDEWindowCreatorsLayoutList);
end;

procedure InitLayoutHelper(const FormID: string);
begin
  with IDEWindowCreators.SimpleLayoutStorage do
    if not Assigned(ItemByFormID(FormID)) then
      CreateWindowLayout(FormID);
end;

procedure TDesktopOpt.SetConfig(aXMLCfg: TRttiXMLConfig; aConfigStore: TXMLOptionsStorage);
begin
  FXMLCfg := aXMLCfg;
  FConfigStore := aConfigStore;
end;

procedure TDesktopOpt.InitLayoutList;
var
  l: TNonModalIDEWindow;
begin
  for l:=Low(TNonModalIDEWindow) to High(TNonModalIDEWindow) do
    if l<>nmiwNone then
      InitLayoutHelper(NonModalIDEWindowNames[l]);
  InitLayoutHelper(DefaultObjectInspectorName);
end;

{ TEnvironmentOptions }

constructor TEnvironmentOptions.Create;
var
  o: TEnvOptParseType;
  c: TMsgWndColor;
  u: TMessageLineUrgency;
begin
  inherited Create;
  for o:=low(FParseValues) to high(FParseValues) do
    FParseValues[o].ParseStamp:=CTInvalidChangeStamp;

  FFilename:='';

  // language
  LanguageID:='';

  // auto save
  FAskSaveSessionOnly:=false;
  FAutoSaveEditorFiles:=true;
  FAutoSaveProject:=true;
  FAutoSaveIntervalInSecs:=DefaultAutoSaveIntervalInSecs;
  FLastSavedProjectFile:='';
  FLastOpenPackages:=TLastOpenPackagesList.Create;

  // EnvironmentOptionsDialog editor
  FShowGrid:=true;
  FShowBorderSpacing:=false;
  FGridColor:=DefaultGridColor;
  FSnapToGrid:=true;
  FGridSizeX:=DefaultGridSize;
  FGridSizeY:=DefaultGridSize;
  FShowGuideLines:=true;
  FSnapToGuideLines:=true;
  FGuideLineColorLeftTop:=DefaultGuideLineColorLeftTop;
  FGuideLineColorRightBottom:=DefaultGuideLineColorRightBottom;
  FShowComponentCaptions:=false;
  FShowEditorHints:=true;
  FAutoCreateFormsOnOpen:=true;
  FCheckPackagesOnFormCreate:=true;
  FRightClickSelects:=true;
  FGrabberColor:=clBlack;
  FMarkerColor:=clDkGray;
  FRubberbandSelectionColor:=clNavy;
  FRubberbandCreationColor:=clMaroon;
  FRubberbandSelectsGrandChilds:=DefaultRubberbandSelectsGrandChilds;
  FDesignerPaintLazy:=true;
  FCreateComponentFocusNameProperty:=false;
  FSwitchToFavoritesOITab:=false;

  // object inspector
  FObjectInspectorOptions:=TOIOptions.Create;

  // project inspector
  FProjInspSortAlphabetically:=false;
  FProjInspShowDirHierarchy:=false;

  // package editor
  FPackageEditorSortAlphabetically:=false;
  FPackageEditorShowDirHierarchy:=false;

  // hints
  FCheckDiskChangesWithLoading:=false;
  FShowHintsForComponentPalette:=true;
  FShowHintsForMainSpeedButtons:=true;
  
  // messages view
  fMsgViewDblClickJumps:=true;
  fMsgViewFocus:=DefaultMsgViewFocus;
  FShowMessagesIcons:=true;
  FMsgViewStayOnTop:=false;
  FMsgViewShowTranslations:=false;
  FMsgViewAlwaysDrawFocused:=false;
  FMsgViewFilenameStyle:=mwfsShort;
  for c:=low(TMsgWndColor) to high(TMsgWndColor) do
    fMsgViewColors[c]:=MsgWndDefaultColors[c];
  for u:=low(TMessageLineUrgency) to high(TMessageLineUrgency) do
    fMsgColors[u] := clDefault;
  FMsgViewFilters:=TLMsgViewFilters.Create(nil);
  FMsgViewShowFPCMsgLinesCompiled:=false;

  // glyphs
  FShowButtonGlyphs := sbgSystem;
  FShowMenuGlyphs := sbgSystem;

  // files
  LazarusDirectory:='';
  FLazarusDirHistory:=TStringList.Create;
  CompilerFilename:='';
  FCompilerFileHistory:=TStringList.Create;
  FPCSourceDirectory:='';
  FFPCSourceDirHistory:=TStringList.Create;
  MakeFilename:=DefaultMakefilename;
  FMakeFileHistory:=TStringList.Create;
  DebuggerFilename:='';
  FDebuggerFileHistory:=TStringList.Create;
  FDebuggerProperties := TStringList.Create;
  FDebuggerEventLogColors:=DebuggerDefaultColors;

  TestBuildDirectory:=GetDefaultTestBuildDirectory;
  FTestBuildDirHistory:=TStringList.Create;
  CompilerMessagesFilename:='';
  FCompilerMessagesFileHistory:=TStringList.Create;

  // recent files and directories
  FRecentOpenFiles:=TStringList.Create;
  FMaxRecentOpenFiles:=DefaultMaxRecentOpenFiles;
  FRecentProjectFiles:=TStringList.Create;
  FMaxRecentProjectFiles:=DefaultMaxRecentProjectFiles;
  FRecentPackageFiles:=TStringList.Create;
  FMaxRecentPackageFiles:=DefaultMaxRecentPackageFiles;
  FOpenLastProjectAtStart:=true;
  FMultipleInstances:=DefaultIDEMultipleInstancesOption;

  // backup
  with FBackupInfoProjectFiles do begin
    BackupType:=bakSameName;
    AdditionalExtension:='bak';  // for bakUserDefinedAddExt
    MaxCounter:=3;               // for bakCounter
    SubDirectory:='';
  end;
  with FBackupInfoOtherFiles do begin
    BackupType:=bakUserDefinedAddExt;
    AdditionalExtension:='bak';  // for bakUserDefinedAddExt
    MaxCounter:=3;               // for bakCounter
    SubDirectory:='';
  end;
  
  // external tools
  fExternalUserTools:=ExternalUserToolsClass.Create;
  FMaxExtToolsInParallel:=0;

  // naming
  fPascalFileExtension:=petPAS;
  fCharcaseFileAction:=ccfaAutoRename;
  FUnitRenameReferencesAction:=urraAsk;
  FAskForFilenameOnNewFile:=false;
  FLowercaseDefaultFilename:=true;

  //debug
  (* TODO: maybe revert relations. Create this in Debugger, and call environmentoptions for the configstore only? *)
  FDebuggerConfig := TDebuggerConfigStore.Create;

  // global build options
  FBuildMatrixOptions:=TBuildMatrixOptions.Create;

  // Desktop collection
  FDesktops := TDesktopOptList.Create(Self);
  // FDesktop points to the IDE properties
  FDesktop := TDesktopOpt.Create('');
  FAutoSaveActiveDesktop := True;
end;

destructor TEnvironmentOptions.Destroy;
var
  i: Integer;
begin
  FreeAndNil(FDesktops);
  FreeAndNil(FDesktop);
  FreeAndNil(FLastDesktopBeforeDebug);
  FreeAndNil(FBuildMatrixOptions);
  FreeAndNil(FMsgViewFilters);
  FreeAndNil(fExternalUserTools);
  FreeAndNil(FRecentOpenFiles);
  FreeAndNil(FRecentProjectFiles);
  FreeAndNil(FRecentPackageFiles);
  FreeAndNil(FObjectInspectorOptions);
  FreeAndNil(FLazarusDirHistory);
  FreeAndNil(FCompilerFileHistory);
  FreeAndNil(FFPCSourceDirHistory);
  FreeAndNil(FMakeFileHistory);
  FreeAndNil(FDebuggerFileHistory);
  for i := 0 to FDebuggerProperties.Count - 1 do
    FDebuggerProperties.Objects[i].Free;
  FreeAndNil(FDebuggerProperties);
  FreeAndNil(FTestBuildDirHistory);
  FreeAndNil(FCompilerMessagesFileHistory);
  FreeAndNil(FDebuggerConfig);
  FreeAndNil(FConfigStore);
  FreeAndNil(FDbgConfigStore);
  FreeAndNil(FXMLCfg);
  FreeAndNil(FLastOpenPackages);
  inherited Destroy;
end;

procedure TEnvironmentOptions.DisableDebugDesktop;
begin
  if (FLastDesktopBeforeDebug=nil) or (FDesktop=nil) then
    Exit;
  try
    if AutoSaveActiveDesktop and Assigned(DebugDesktop) then
    begin
      Desktop.ImportSettingsFromIDE;
      DebugDesktop.Assign(Desktop);
    end;

    UseDesktop(FLastDesktopBeforeDebug);
  finally
    FreeAndNil(FLastDesktopBeforeDebug);
  end;
end;

class function TEnvironmentOptions.GetGroupCaption: string;
begin
  Result := dlgGroupEnvironment;
end;

class function TEnvironmentOptions.GetInstance: TAbstractIDEOptions;
begin
  Result := EnvironmentOptions;
end;

procedure TEnvironmentOptions.DoAfterWrite(Restore: boolean);
begin
  // Note! Data is saved when the IDE is closed.
  //if not Restore then
  //  Save(False);
  inherited DoAfterWrite(Restore);
end;

procedure TEnvironmentOptions.EnableDebugDesktop;
begin
  if not Assigned(FLastDesktopBeforeDebug) and Assigned(DebugDesktop) then
  begin
    FLastDesktopBeforeDebug := TDesktopOpt.Create('');
    FLastDesktopBeforeDebug.Assign(Desktop);
    FLastDesktopBeforeDebug.Name := ActiveDesktopName;
    EnvironmentOptions.UseDesktop(DebugDesktop);
  end;
end;

procedure TEnvironmentOptions.CreateConfig;
var
  ConfFileName: string;
begin
  ConfFileName:=GetDefaultConfigFilename;
  CopySecondaryConfigFile(EnvOptsConfFileName);
  if (not FileExistsUTF8(ConfFileName)) then begin
    //DebugLn('Note: environment config file not found - using defaults');
  end;
  Filename:=ConfFilename;
end;

class function TEnvironmentOptions.DesktopCanBeLoaded(const aDockMaster: string
  ): Boolean;
begin
  Result := (aDockMaster = '') or (
    Assigned(IDEDockMaster) and (IDEDockMaster.ClassName = aDockMaster));
end;

function TEnvironmentOptions.GetParsedLazarusDirectory: string;
begin
  Result:=GetParsedValue(eopLazarusDirectory);
end;

procedure TEnvironmentOptions.SetFileName(const NewFilename: string);
begin
  if FFilename=NewFilename then exit;
  FFilename:=NewFilename;
  FFileHasChangedOnDisk:=true;
end;

procedure TEnvironmentOptions.LoadNonDesktop(Path: String);

  procedure LoadBackupInfo(var BackupInfo: TBackupInfo; const Path:string);
  var i:integer;
  begin
    with BackupInfo do begin
      i:=FXMLCfg.GetValue(Path+'Type',5);
      case i of
       0:BackupType:=bakNone;
       1:BackupType:=bakSymbolInFront;
       2:BackupType:=bakSymbolBehind;
       3:BackupType:=bakCounter;
       4:BackupType:=bakSameName;
      else
        BackupType:=bakUserDefinedAddExt;
      end;
      AdditionalExtension:=FXMLCfg.GetValue(Path+'AdditionalExtension','bak');
      MaxCounter:=FXMLCfg.GetValue(Path+'MaxCounter',9);
      if FFileVersion<101 then
        SubDirectory:=''
      else
        SubDirectory:=FXMLCfg.GetValue(Path+'SubDirectory','backup');
    end;
  end;

var
  EventType: TDBGEventType;
begin
  // files
  LazarusDirectory:=FXMLCfg.GetValue(Path+'LazarusDirectory/Value',LazarusDirectory);
  LoadRecentList(FXMLCfg,FLazarusDirHistory,Path+'LazarusDirectory/History/',rltFile);
  if FLazarusDirHistory.Count=0 then
    FLazarusDirHistory.Add(ProgramDirectory(true));
  CompilerFilename:=TrimFilename(FXMLCfg.GetValue(
                        Path+'CompilerFilename/Value',CompilerFilename));
  LoadRecentList(FXMLCfg,FCompilerFileHistory,Path+'CompilerFilename/History/',rltFile);
  if FCompilerFileHistory.Count=0 then
    GetDefaultCompilerFilenames(FCompilerFileHistory);
  FPCSourceDirectory:=FXMLCfg.GetValue(Path+'FPCSourceDirectory/Value',FPCSourceDirectory);
  LoadRecentList(FXMLCfg,FFPCSourceDirHistory,Path+'FPCSourceDirectory/History/',rltFile);
  MakeFilename:=TrimFilename(FXMLCfg.GetValue(Path+'MakeFilename/Value',MakeFilename));
  LoadRecentList(FXMLCfg,FMakeFileHistory,Path+'MakeFilename/History/',rltFile);
  if FMakeFileHistory.Count=0 then
    GetDefaultMakeFilenames(FMakeFileHistory);

  TestBuildDirectory:=FXMLCfg.GetValue(Path+'TestBuildDirectory/Value',TestBuildDirectory);
  LoadRecentList(FXMLCfg,FTestBuildDirHistory,Path+'TestBuildDirectory/History/',rltFile);
  if FTestBuildDirHistory.Count=0 then
    GetDefaultTestBuildDirs(FTestBuildDirHistory);
  CompilerMessagesFilename:=FXMLCfg.GetValue(Path+'CompilerMessagesFilename/Value',CompilerMessagesFilename);
  LoadRecentList(FXMLCfg,FCompilerMessagesFileHistory,Path+'CompilerMessagesFilename/History/',rltFile);

  // Primary-config verification
  FLastCalledByLazarusFullPath:=FXMLCfg.GetValue(Path+'LastCalledByLazarusFullPath/Value','');

  // global build options, additions and overrides
  FConfigStore.AppendBasePath('BuildMatrix');
  FBuildMatrixOptions.LoadFromConfig(FConfigStore);
  FConfigStore.UndoAppendBasePath;
  FUseBuildModes:=FXMLCfg.GetValue(Path+'Build/UseBuildModes',false);

  // backup
  LoadBackupInfo(FBackupInfoProjectFiles,Path+'BackupProjectFiles/');
  LoadBackupInfo(FBackupInfoOtherFiles,Path+'BackupOtherFiles/');

  // Debugger
  FDebuggerConfig.Load;
  DebuggerFilename:=FXMLCfg.GetValue(Path+'DebuggerFilename/Value','');
  LoadRecentList(FXMLCfg,FDebuggerFileHistory,Path+'DebuggerFilename/History/',rltFile);
  DebuggerSearchPath:=FXMLCfg.GetValue(Path+'DebuggerSearchPath/Value','');
  // Debugger General Options
  DebuggerShowStopMessage:=FXMLCfg.GetValue(Path+'DebuggerOptions/ShowStopMessage/Value', True);
  DebuggerResetAfterRun :=FXMLCfg.GetValue(Path+'DebuggerOptions/DebuggerResetAfterRun/Value', False);
  FDebuggerEventLogClearOnRun := FXMLCfg.GetValue(Path+'Debugger/EventLogClearOnRun', True);
  FDebuggerEventLogCheckLineLimit := FXMLCfg.GetValue(Path+'Debugger/EventLogCheckLineLimit', False);
  FDebuggerEventLogLineLimit := FXMLCfg.GetValue(Path+'Debugger/EventLogLineLimit', 1000);
  FDebuggerEventLogShowBreakpoint := FXMLCfg.GetValue(Path+'Debugger/EventLogShowBreakpoint', False);
  FDebuggerEventLogShowProcess := FXMLCfg.GetValue(Path+'Debugger/EventLogShowProcess', True);
  FDebuggerEventLogShowThread := FXMLCfg.GetValue(Path+'Debugger/EventLogShowThread', True);
  FDebuggerEventLogShowModule := FXMLCfg.GetValue(Path+'Debugger/EventLogShowModule', False);
  FDebuggerEventLogShowOutput := FXMLCfg.GetValue(Path+'Debugger/EventLogShowOutput', True);
  FDebuggerEventLogShowWindows := FXMLCfg.GetValue(Path+'Debugger/EventLogShowWindows', False);
  FDebuggerEventLogShowDebugger := FXMLCfg.GetValue(Path+'Debugger/EventLogShowDebugger', True);
  FDebuggerEventLogUseColors := FXMLCfg.GetValue(Path+'Debugger/EventLogUseColors', True);
  for EventType := Low(TDBGEventType) to High(TDBGEventType) do
  begin
    FDebuggerEventLogColors[EventType].Background :=
      FXMLCfg.GetValue(Path+'Debugger/EventLogColors/' +
      GetEnumName(TypeInfo(EventType), Ord(EventType)) + '/Background',
      DebuggerDefaultColors[EventType].Background);
    FDebuggerEventLogColors[EventType].Foreground :=
      FXMLCfg.GetValue(Path+'Debugger/EventLogColors/' +
      GetEnumName(TypeInfo(EventType), Ord(EventType)) + '/Foreground',
      DebuggerDefaultColors[EventType].Foreground);
  end;
end;

procedure TEnvironmentOptions.Load(OnlyDesktop: boolean);

  procedure AddRecentProjectInitial(aProjPath, aProjFile: string);
  // Add a project to the list of recent projects if the project has write access.
  // The check can be removed when the IDE allows compiling read-only projects.
  var
    WholeFilePath: String;
  begin
    aProjPath:=SwitchPathDelims(aProjPath, True);
    WholeFilePath:=ExtractFilePath(Application.ExeName) + aProjPath + aProjFile;
    if FileIsWritable(aProjPath) and FileIsWritable(WholeFilePath) then
      AddToRecentList(WholeFilePath,FRecentProjectFiles,FMaxRecentProjectFiles,rltFile);
  end;

  procedure LoadPascalFileExt(const Path: string);
  begin
    fPascalFileExtension:=PascalExtToType(FXMLCfg.GetValue(
      Path+'Naming/PascalFileExtension',PascalExtension[petPAS]));
    if fPascalFileExtension=petNone then
      fPascalFileExtension:=petPAS;
  end;
  
var
  Path, CurPath: String;
  i, j: Integer;
  Rec: PIDEOptionsGroupRec;
  NodeName, xFileName: String;
  mwc: TMsgWndColor;
  u: TMessageLineUrgency;
begin
  try
    InitXMLCfg(false);
    // ToDo: Get rid of EnvironmentOptions/ path. The whole file is about
    //  environment options. Many section are not under it any more.
    Path:='EnvironmentOptions/';
    FFileVersion:=FXMLCfg.GetValue(Path+'Version/Value',0);
    FOldLazarusVersion:=FXMLCfg.GetValue(Path+'Version/Lazarus','');
    if FOldLazarusVersion='' then begin
      // 108 added LastCalledByLazarusFullPath
      // 107 added Lazarus version
      // 1.1     r36507  106
      // 0.9.31  r28811  106
      // 0.9.29  r21344  106
      // 0.9.27  r16725  106
      // 0.9.25  r12751  106
      // 0.9.23  r10809  106
    end;

    // language
    fLanguageID:=FXMLCfg.GetValue(Path+'Language/ID','');

    // auto save
    FAskSaveSessionOnly:=FXMLCfg.GetValue(Path+'AutoSave/AskSaveSessionOnly',false);
    FAutoSaveEditorFiles:=FXMLCfg.GetValue(Path+'AutoSave/EditorFiles',true);
    FAutoSaveProject:=FXMLCfg.GetValue(Path+'AutoSave/Project',true);
    FAutoSaveIntervalInSecs:=FXMLCfg.GetValue(Path+'AutoSave/IntervalInSecs',DefaultAutoSaveIntervalInSecs);
    FLastSavedProjectFile:=FXMLCfg.GetValue(Path+'AutoSave/LastSavedProjectFile','');
    FOpenLastProjectAtStart:=FXMLCfg.GetValue(Path+'AutoSave/OpenLastProjectAtStart',true);
    FShowCompileDialog:=FXMLCfg.GetValue(Path+'ShowCompileDialog/Value',false);
    FAutoCloseCompileDialog:=FXMLCfg.GetValue(Path+'AutoCloseCompileDialog/Value',false);
    FAutoSaveActiveDesktop:=FXMLCfg.GetValue(Path+'AutoSave/ActiveDesktop',True);
    FLastOpenPackages.Clear;
    if FOpenLastProjectAtStart then
    begin
      i := 1;
      repeat
        xFileName := FXMLCfg.GetValue(Path+'AutoSave/LastOpenPackages/Package'+IntToStr(i), '');
        if FileExistsCached(xFileName) then
          FLastOpenPackages.Add(xFileName);
        Inc(i);
      until xFileName='';
    end;

    // form editor
    FShowGrid:=FXMLCfg.GetValue(Path+'FormEditor/ShowGrid',true);
    FShowBorderSpacing:=FXMLCfg.GetValue(Path+'FormEditor/ShowBorderSpacing',false);
    FGridColor:=FXMLCfg.GetValue(Path+'FormEditor/GridColor',DefaultGridColor);
    FSnapToGrid:=FXMLCfg.GetValue(Path+'FormEditor/SnapToGrid',true);
    FGridSizeX:=FXMLCfg.GetValue(Path+'FormEditor/GridSizeX',DefaultGridSize);
    FGridSizeY:=FXMLCfg.GetValue(Path+'FormEditor/GridSizeY',DefaultGridSize);
    FShowGuideLines:=FXMLCfg.GetValue(Path+'FormEditor/ShowGuideLines',true);
    FSnapToGuideLines:=FXMLCfg.GetValue(Path+'FormEditor/SnapToGuideLines',true);
    FGuideLineColorLeftTop:=FXMLCfg.GetValue(Path+'FormEditor/GuideLineColorLeftTop',
       DefaultGuideLineColorLeftTop);
    FGuideLineColorRightBottom:=FXMLCfg.GetValue(Path+'FormEditor/GuideLineColorRightBottom',
       DefaultGuideLineColorRightBottom);
    FShowComponentCaptions:=FXMLCfg.GetValue(Path+'FormEditor/ShowComponentCaptions',true);
    FShowEditorHints:=FXMLCfg.GetValue(Path+'FormEditor/ShowEditorHints',true);
    FAutoCreateFormsOnOpen:=FXMLCfg.GetValue(Path+'FormEditor/AutoCreateFormsOnOpen',true);
    FCheckPackagesOnFormCreate:=FXMLCfg.GetValue(Path+'FormEditor/CheckPackagesOnFormCreate',true);
    FRightClickSelects:=FXMLCfg.GetValue(Path+'FormEditor/RightClickSelects',true);
    FGrabberColor:=FXMLCfg.GetValue(Path+'FormEditor/GrabberColor/Value',FGrabberColor);
    FMarkerColor:=FXMLCfg.GetValue(Path+'FormEditor/MarkerColor/Value',FMarkerColor);
    FRubberbandSelectionColor:=FXMLCfg.GetValue(Path+'FormEditor/Rubberband/SelectionColor/Value',
       FRubberbandSelectionColor);
    FRubberbandCreationColor:=FXMLCfg.GetValue(Path+'FormEditor/Rubberband/CreationColor/Value',
       FRubberbandCreationColor);
    FRubberbandSelectsGrandChilds:=FXMLCfg.GetValue(Path+'FormEditor/Rubberband/SelectsGrandChilds/Value',DefaultRubberbandSelectsGrandChilds);
    FDesignerPaintLazy:=FXMLCfg.GetValue(Path+'FormEditor/DesignerPaint/Lazy/Value',true);
    FCreateComponentFocusNameProperty:=FXMLCfg.GetValue(
       Path+'FormEditor/CreateComponentFocusNameProperty/Value',false);
    FSwitchToFavoritesOITab:=FXMLCfg.GetValue(Path+'FormEditor/SwitchToFavoritesOITab/Value',false);

    if not OnlyDesktop then
      LoadNonDesktop(Path);

    // project inspector
    FProjInspSortAlphabetically:=FXMLCfg.GetValue(Path+'ProjInspSortAlphabetically/Value',false);
    FProjInspShowDirHierarchy:=FXMLCfg.GetValue(Path+'ProjInspShowDirHierarchy/Value',false);

    // package editor
    FPackageEditorSortAlphabetically:=FXMLCfg.GetValue(Path+'PackageEditorSortAlphabetically/Value',false);
    FPackageEditorShowDirHierarchy:=FXMLCfg.GetValue(Path+'PackageEditorShowDirHierarchy/Value',false);

    // hints
    FCheckDiskChangesWithLoading:=FXMLCfg.GetValue(Path+'CheckDiskChangesWithLoading/Value',false);
    FShowHintsForComponentPalette:=FXMLCfg.GetValue(Path+'ShowHintsForComponentPalette/Value',true);
    FShowHintsForMainSpeedButtons:=FXMLCfg.GetValue(Path+'ShowHintsForMainSpeedButtons/Value',true);

    // messages view
    fMsgViewDblClickJumps:=FXMLCfg.GetValue(Path+'MsgViewDblClickJumps/Value',false);
    fMsgViewFocus:=FXMLCfg.GetValue(Path+'MsgViewFocus/Value',DefaultMsgViewFocus);
    FShowMessagesIcons:=FXMLCfg.GetValue(Path+'MsgView/ShowMessagesIcons/Value',true);
    FMsgViewStayOnTop:=FXMLCfg.GetValue(Path+'MsgView/StayOnTop/Value',false);
    FMsgViewShowTranslations:=FXMLCfg.GetValue(Path+'MsgView/ShowTranslations/Value',false);
    FMsgViewAlwaysDrawFocused:=FXMLCfg.GetValue(Path+'MsgView/AlwaysDrawFocused/Value',false);
    FMsgViewFilenameStyle:=StrToMsgWndFilenameStyle(FXMLCfg.GetValue(
      Path+'MsgView/Filename/Style',MsgWndFileNameStyleNames[mwfsShort]));
    for mwc:=low(TMsgWndColor) to high(TMsgWndColor) do
      fMsgViewColors[mwc]:=FXMLCfg.GetValue(
        Path+'MsgView/Colors/'+MsgWndColorNames[mwc],MsgWndDefaultColors[mwc]);
    for u:=low(TMessageLineUrgency) to high(TMessageLineUrgency) do
      fMsgColors[u] := FXMLCfg.GetValue(
        Path+'MsgView/MsgColors/'+dbgs(u),clDefault);
    MsgViewFilters.LoadFromXMLConfig(FXMLCfg,'MsgView/Filters/');
    FMsgViewShowFPCMsgLinesCompiled:=FXMLCfg.GetValue(Path+'MsgView/FPCMsg/ShowLinesCompiled',false);

    // glyphs
    FShowButtonGlyphs := TApplicationShowGlyphs(FXMLCfg.GetValue(Path+'ShowButtonGlyphs/Value',
      Ord(sbgSystem)));
    FShowMenuGlyphs := TApplicationShowGlyphs(FXMLCfg.GetValue(Path+'ShowMenuGlyphs/Value',
      Ord(sbgSystem)));

    // recent files and directories
    FMaxRecentOpenFiles:=FXMLCfg.GetValue(Path+'Recent/OpenFiles/Max',DefaultMaxRecentOpenFiles);
    LoadRecentList(FXMLCfg,FRecentOpenFiles,Path+'Recent/OpenFiles/',rltFile);
    FMaxRecentProjectFiles:=FXMLCfg.GetValue(Path+'Recent/ProjectFiles/Max',DefaultMaxRecentProjectFiles);
    LoadRecentList(FXMLCfg,FRecentProjectFiles,Path+'Recent/ProjectFiles/',rltFile);
    FMaxRecentPackageFiles:=FXMLCfg.GetValue(Path+'Recent/PackageFiles/Max',DefaultMaxRecentPackageFiles);
    LoadRecentList(FXMLCfg,FRecentPackageFiles,Path+'Recent/PackageFiles/',rltFile);

    FAlreadyPopulatedRecentFiles := FXMLCfg.GetValue(Path+'Recent/AlreadyPopulated', false);

    // Add example projects to an empty project list if examples have write access
    if (FRecentProjectFiles.count=0) and (not FAlreadyPopulatedRecentFiles) then begin
      AddRecentProjectInitial('examples/jpeg/',          'jpegexample.lpi');
      AddRecentProjectInitial('examples/sprites/',       'spriteexample.lpi');
      AddRecentProjectInitial('examples/openglcontrol/', 'openglcontrol_demo.lpi');
      AddRecentProjectInitial('examples/imagelist/',     'project1.lpi');
      AddRecentProjectInitial('examples/',               'hello.lpi');
      FAlreadyPopulatedRecentFiles := True;
    end;

    // external tools
    fExternalUserTools.Load(FConfigStore,Path+'ExternalTools/');
    FMaxExtToolsInParallel:=FXMLCfg.GetValue(Path+'ExternalTools/MaxInParallel',0);

    // naming
    LoadPascalFileExt(Path+'');
    if FFileVersion>=103 then begin
      fCharcaseFileAction:=CharCaseFileActionNameToType(FXMLCfg.GetValue(
        Path+'CharcaseFileAction/Value',''));
    end else begin
      if FXMLCfg.GetValue(Path+'PascalFileAskLowerCase/Value',true) then
        fCharcaseFileAction:=ccfaAsk
      else if FXMLCfg.GetValue(Path+'PascalFileAutoLowerCase/Value',false)
      then
        fCharcaseFileAction:=ccfaAutoRename
      else
        fCharcaseFileAction:=ccfaIgnore;
    end;
    if FFileVersion>=104 then
      CurPath:=Path+'AmbiguousFileAction/Value'
    else
      CurPath:=Path+'AmbigiousFileAction/Value';
    fAmbiguousFileAction:=AmbiguousFileActionNameToType(FXMLCfg.GetValue(
      CurPath,AmbiguousFileActionNames[fAmbiguousFileAction]));
    FUnitRenameReferencesAction:=UnitRenameReferencesActionNameToType(FXMLCfg.GetValue(
      Path+'UnitRenameReferencesAction/Value',UnitRenameReferencesActionNames[urraAsk]));
    FAskForFilenameOnNewFile:=FXMLCfg.GetValue(Path+'AskForFilenameOnNewFile/Value',false);
    FLowercaseDefaultFilename:=FXMLCfg.GetValue(Path+'LowercaseDefaultFilename/Value',true);
    FMultipleInstances:=StrToIDEMultipleInstancesOption(FXMLCfg.GetValue(Path+'MultipleInstances/Value',''));

    // fpdoc
    FPDocPaths := FXMLCfg.GetValue(Path+'LazDoc/Paths','');
    if FFileVersion<=105 then
      FPDocPaths:=LineBreaksToDelimiter(FPDocPaths,';');

    // 'new items'
    FNewUnitTemplate:=FXMLCfg.GetValue(Path+'New/UnitTemplate/Value',FileDescNamePascalUnit);
    FNewFormTemplate:=FXMLCfg.GetValue(Path+'New/FormTemplate/Value',FileDescNameLCLForm);

    // object inspector
    FObjectInspectorOptions.Load;
    FObjectInspectorOptions.SaveBounds:=false;

    // IDEEditorGroups
    for i := 0 to IDEEditorGroups.Count-1 do
    begin
      Rec := IDEEditorGroups[i];
      NodeName := Rec^.GroupClass.ClassName;
      Rec^.Collapsed := FXMLCfg.GetValue(Path+'OptionDialog/Tree/' + NodeName + '/Value',
                                           Rec^.DefaultCollapsed);
      if Rec^.Items <> nil then begin
        for j := 0 to Rec^.Items.Count-1 do begin
          Rec^.Items[j]^.Collapsed := FXMLCfg.GetValue(Path+'OptionDialog/Tree/' + NodeName
                + '/' + Rec^.Items[j]^.EditorClass.ClassName + '/Value',
                Rec^.Items[j]^.DefaultCollapsed);
        end;
      end;
    end;

    // The user can define many desktops. They are saved under path Desktops/.
    FDesktops.Clear;
    FDesktops.SetConfig(FXMLCfg, FConfigStore);
    FActiveDesktopName := '';

    if FFileVersion<109 then begin
      //load old default desktop - backwards compatibility - or create a new default desktop
      CurPath := 'Desktop/';               // New place: Desktop/
      if not FXMLCfg.HasPath(CurPath, True) then
        CurPath := Path+'Desktop/';        // Old place: EnvironmentOptions/Desktop/
      if FXMLCfg.HasPath(CurPath, True) or//default desktop exists in the settings
         ((ActiveDesktop.IDECoolBarOptions.ToolBars.Count = 0) and
          (ActiveDesktop.FIDEDialogLayoutList.Count = 0))//desktop is empty, load it to recreate!
      then
      begin
        ActiveDesktop.SetConfig(FXMLCfg, FConfigStore);
        ActiveDesktop.Load(CurPath);
      end;
    end else begin
      CurPath := 'Desktops/';
      FDebugDesktopName := FXMLCfg.GetValue(CurPath+'DebugDesktop', '');
      FActiveDesktopName := FXMLCfg.GetValue(CurPath+'ActiveDesktop', '');
      j := FXMLCfg.GetValue(CurPath+'Count', 1);
      for i := 1 to j do
        FDesktops.AddFromCfg(CurPath+'Desktop'+IntToStr(i)+'/');
    end;
    if FFileVersion<=109 then begin
      FXMLCfg.DeletePath('Desktop');
      FXMLCfg.DeletePath(CurPath+'Desktop');
    end;

    Desktop.Assign(ActiveDesktop, False);
    Desktop.ExportSettingsToIDE;

    FileUpdated;
  except
    on E: Exception do
      DebugLn('[TEnvironmentOptions.Load]  error reading "',FFilename,'": '+E.Message);
  end;
end;

procedure TEnvironmentOptions.SaveNonDesktop(Path: String);

  procedure SaveBackupInfo(var BackupInfo: TBackupInfo; Path:string);
  var i:integer;
  begin
    with BackupInfo do begin
      case BackupType of
       bakNone: i:=0;
       bakSymbolInFront: i:=1;
       bakSymbolBehind: i:=2;
       bakCounter: i:=3;
       bakSameName: i:=4;
      else
        i:=5; // bakUserDefinedAddExt;
      end;
      FXMLCfg.SetDeleteValue(Path+'Type',i,5);
      FXMLCfg.SetDeleteValue(Path+'AdditionalExtension',AdditionalExtension,'.bak');
      FXMLCfg.SetDeleteValue(Path+'MaxCounter',MaxCounter,10);
      FXMLCfg.SetDeleteValue(Path+'SubDirectory',SubDirectory,'backup');
    end;
  end;

var
  BaseDir, CurLazDir: String;
  EventType: TDBGEventType;
begin
  // files
  CurLazDir:=ChompPathDelim(LazarusDirectory);
  if not GlobalMacroList.StrHasMacros(CurLazDir) then begin
    BaseDir:=ExtractFilePath(ChompPathDelim(GetPrimaryConfigPath));
    if (CompareFilenames(BaseDir,CurLazDir)=0)
    or FileIsInPath(CurLazDir,BaseDir) then begin
      // the pcp directory is in the lazarus directory
      // or the lazarus directory is a sibling or a sub dir of a sibling of the pcp
      // examples:
      //   pcp=C:\Lazarus\config, lazdir=C:\Lazarus => store '..'
      //   pcp=/home/user/.lazarus, lazdir=/home/user/freepascal/lazarus => store ../freepascal/lazarus
      CurLazDir:=CreateRelativePath(CurLazDir,GetPrimaryConfigPath);
    end;
    FXMLCfg.SetValue(Path+'LazarusDirectory/Value',CurLazDir); // always store, no SetDeleteValue
  end;
  SaveRecentList(FXMLCfg,FLazarusDirHistory,Path+'LazarusDirectory/History/');
  FXMLCfg.SetDeleteValue(Path+'CompilerFilename/Value',CompilerFilename,'');
  SaveRecentList(FXMLCfg,FCompilerFileHistory,Path+'CompilerFilename/History/');
  FXMLCfg.SetDeleteValue(Path+'FPCSourceDirectory/Value',FPCSourceDirectory,'');
  SaveRecentList(FXMLCfg,FFPCSourceDirHistory,Path+'FPCSourceDirectory/History/');
  FXMLCfg.SetDeleteValue(Path+'MakeFilename/Value',MakeFilename,DefaultMakefilename);
  SaveRecentList(FXMLCfg,FMakeFileHistory,Path+'MakeFilename/History/');
  FXMLCfg.SetDeleteValue(Path+'TestBuildDirectory/Value',TestBuildDirectory,'');
  SaveRecentList(FXMLCfg,FTestBuildDirHistory,Path+'TestBuildDirectory/History/');
  FXMLCfg.SetDeleteValue(Path+'CompilerMessagesFilename/Value',CompilerMessagesFilename,'');
  SaveRecentList(FXMLCfg,FCompilerMessagesFileHistory,Path+'CompilerMessagesFilename/History/');

  // Primary-config verification
  FXMLCfg.SetDeleteValue(Path+'LastCalledByLazarusFullPath/Value',FLastCalledByLazarusFullPath,'');

  // global buid options
  FConfigStore.AppendBasePath('BuildMatrix');
  FBuildMatrixOptions.SaveToConfig(FConfigStore,IsGlobalMode);
  FConfigStore.UndoAppendBasePath;
  FXMLCfg.SetDeleteValue(Path+'Build/UseBuildModes',FUseBuildModes,false);

  // backup
  SaveBackupInfo(FBackupInfoProjectFiles,Path+'BackupProjectFiles/');
  SaveBackupInfo(FBackupInfoOtherFiles,Path+'BackupOtherFiles/');

  // debugger
  FDebuggerConfig.Save;
  SaveDebuggerPropertiesList;
  FXMLCfg.SetDeleteValue(Path+'DebuggerFilename/Value',DebuggerFilename,'');
  FXMLCfg.SetDeleteValue(Path+'DebuggerOptions/ShowStopMessage/Value',
      FDebuggerShowStopMessage, True);
  FXMLCfg.SetDeleteValue(Path+'DebuggerOptions/DebuggerResetAfterRun/Value',
      FDebuggerResetAfterRun, False);
  SaveRecentList(FXMLCfg,FDebuggerFileHistory,Path+'DebuggerFilename/History/');
  FXMLCfg.SetDeleteValue(Path+'DebuggerSearchPath/Value',DebuggerSearchPath,'');
  FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogClearOnRun',FDebuggerEventLogClearOnRun, True);
  FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogCheckLineLimit',FDebuggerEventLogCheckLineLimit, False);
  FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogLineLimit',FDebuggerEventLogLineLimit, 1000);
  FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogShowBreakpoint',FDebuggerEventLogShowBreakpoint, False);
  FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogShowProcess',FDebuggerEventLogShowProcess, True);
  FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogShowThread',FDebuggerEventLogShowThread, True);
  FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogShowModule',FDebuggerEventLogShowModule, False);
  FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogShowOutput',FDebuggerEventLogShowOutput, True);
  FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogShowWindows',FDebuggerEventLogShowWindows, False);
  FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogShowDebugger',FDebuggerEventLogShowDebugger, True);
  FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogUseColors',FDebuggerEventLogUseColors, True);
  for EventType := Low(TDBGEventType) to High(TDBGEventType) do
  begin
    FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogColors/' +
      GetEnumName(TypeInfo(EventType), Ord(EventType)) + '/Background',
        FDebuggerEventLogColors[EventType].Background,
        DebuggerDefaultColors[EventType].Background);
    FXMLCfg.SetDeleteValue(Path+'Debugger/EventLogColors/' +
      GetEnumName(TypeInfo(EventType), Ord(EventType)) + '/Foreground',
        FDebuggerEventLogColors[EventType].Foreground,
        DebuggerDefaultColors[EventType].Foreground);
  end;
end;

procedure TEnvironmentOptions.Save(OnlyDesktop: boolean);
var
  Path, CurPath, NodeName: String;
  i, j: Integer;
  Rec: PIDEOptionsGroupRec;
  mwc: TMsgWndColor;
  u: TMessageLineUrgency;
  xSaveDesktop: TDesktopOpt;
  xActiveDesktopName: string;
begin
  try
    InitXMLCfg(true);
    // ToDo: Get rid of EnvironmentOptions/ path. The whole file is about
    //  environment options. Many section are not under it any more.
    Path:='EnvironmentOptions/';

    FXMLCfg.SetValue(Path+'Version/Value',EnvOptsVersion);
    FXMLCfg.SetValue(Path+'Version/Lazarus',LazarusVersionStr);

    // language
    FXMLCfg.SetDeleteValue(Path+'Language/ID',LanguageID,'');

    // auto save
    FXMLCfg.SetDeleteValue(Path+'AutoSave/AskSaveSessionOnly',FAskSaveSessionOnly,false);
    FXMLCfg.SetDeleteValue(Path+'AutoSave/EditorFiles',FAutoSaveEditorFiles,true);
    FXMLCfg.SetDeleteValue(Path+'AutoSave/Project',FAutoSaveProject,true);
    FXMLCfg.SetDeleteValue(Path+'AutoSave/IntervalInSecs',FAutoSaveIntervalInSecs,DefaultAutoSaveIntervalInSecs);
    FXMLCfg.SetDeleteValue(Path+'AutoSave/LastSavedProjectFile',FLastSavedProjectFile,'');
    FXMLCfg.SetDeleteValue(Path+'AutoSave/OpenLastProjectAtStart',FOpenLastProjectAtStart,true);
    FXMLCfg.SetDeleteValue(Path+'AutoSave/ActiveDesktop', FAutoSaveActiveDesktop, True);
    if FOpenLastProjectAtStart and (FLastOpenPackages.Count > 0) then
    begin
      for i := 0 to FLastOpenPackages.Count-1 do
        FXMLCfg.SetValue(Path+'AutoSave/LastOpenPackages/Package'+IntToStr(i+1), FLastOpenPackages[i]);
    end else
      FXMLCfg.DeletePath(Path+'AutoSave/LastOpenPackages/');

    // form editor
    FXMLCfg.SetDeleteValue(Path+'FormEditor/ShowBorderSpacing',FShowBorderSpacing,false);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/ShowGrid',FShowGrid,true);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/GridColor',FGridColor,DefaultGridColor);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/SnapToGrid',FSnapToGrid,true);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/GridSizeX',FGridSizeX,DefaultGridSize);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/GridSizeY',FGridSizeY,DefaultGridSize);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/ShowGuideLines',FShowGuideLines,true);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/SnapToGuideLines',FSnapToGuideLines,true);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/GuideLineColorLeftTop',FGuideLineColorLeftTop,DefaultGuideLineColorLeftTop);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/GuideLineColorRightBottom',FGuideLineColorRightBottom,DefaultGuideLineColorRightBottom);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/ShowComponentCaptions',FShowComponentCaptions,true);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/ShowEditorHints',FShowEditorHints,true);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/AutoCreateFormsOnOpen',FAutoCreateFormsOnOpen,true);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/CheckPackagesOnFormCreate',FCheckPackagesOnFormCreate,true);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/RightClickSelects',FRightClickSelects,true);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/GrabberColor/Value',FGrabberColor,clBlack);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/MarkerColor/Value',FMarkerColor,clDkGray);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/Rubberband/SelectionColor/Value',
       FRubberbandSelectionColor,clBlack);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/Rubberband/CreationColor/Value',
       FRubberbandCreationColor,clRed);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/Rubberband/SelectsGrandChilds/Value',
       FRubberbandSelectsGrandChilds,DefaultRubberbandSelectsGrandChilds);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/DesignerPaint/Lazy/Value',FDesignerPaintLazy,true);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/CreateComponentFocusNameProperty/Value',
       FCreateComponentFocusNameProperty,false);
    FXMLCfg.SetDeleteValue(Path+'FormEditor/SwitchToFavoritesOITab/Value',FSwitchToFavoritesOITab,false);

    FXMLCfg.SetDeleteValue(Path+'ShowCompileDialog/Value',FShowCompileDialog,False);
    FXMLCfg.SetDeleteValue(Path+'AutoCloseCompileDialog/Value',FAutoCloseCompileDialog,False);

    if not OnlyDesktop then
      SaveNonDesktop(Path);

    // project inspector
    FXMLCfg.SetDeleteValue(Path+'ProjInspSortAlphabetically/Value',FProjInspSortAlphabetically,false);
    FXMLCfg.SetDeleteValue(Path+'ProjInspShowDirHierarchy/Value',FProjInspShowDirHierarchy,false);

    // package editor
    FXMLCfg.SetDeleteValue(Path+'PackageEditorSortAlphabetically/Value',FPackageEditorSortAlphabetically,false);
    FXMLCfg.SetDeleteValue(Path+'PackageEditorShowDirHierarchy/Value',FPackageEditorShowDirHierarchy,false);

    // hints
    FXMLCfg.SetDeleteValue(Path+'CheckDiskChangesWithLoading/Value',FCheckDiskChangesWithLoading,false);
    FXMLCfg.SetDeleteValue(Path+'ShowHintsForComponentPalette/Value',FShowHintsForComponentPalette,true);
    FXMLCfg.SetDeleteValue(Path+'ShowHintsForMainSpeedButtons/Value',FShowHintsForMainSpeedButtons,true);

    // messages view
    FXMLCfg.SetDeleteValue(Path+'MsgViewDblClickJumps/Value',fMsgViewDblClickJumps,false);
    FXMLCfg.SetDeleteValue(Path+'MsgViewFocus/Value',fMsgViewFocus,DefaultMsgViewFocus);
    FXMLCfg.SetDeleteValue(Path+'MsgView/ShowMessagesIcons/Value',FShowMessagesIcons,true);
    FXMLCfg.SetDeleteValue(Path+'MsgView/StayOnTop/Value',FMsgViewStayOnTop,false);
    FXMLCfg.SetDeleteValue(Path+'MsgView/ShowTranslations/Value',FMsgViewShowTranslations,false);
    FXMLCfg.SetDeleteValue(Path+'MsgView/AlwaysDrawFocused/Value',FMsgViewAlwaysDrawFocused,false);
    FXMLCfg.SetDeleteValue(Path+'MsgView/Filename/Style',
      MsgWndFileNameStyleNames[FMsgViewFilenameStyle],
      MsgWndFileNameStyleNames[mwfsShort]);
    for mwc:=low(TMsgWndColor) to high(TMsgWndColor) do
      FXMLCfg.SetDeleteValue(Path+'MsgView/Colors/'+MsgWndColorNames[mwc],
      fMsgViewColors[mwc],MsgWndDefaultColors[mwc]);
    for u:=low(TMessageLineUrgency) to high(TMessageLineUrgency) do
      FXMLCfg.SetDeleteValue(Path+'MsgView/MsgColors/'+dbgs(u),
      fMsgColors[u],clDefault);
    MsgViewFilters.SaveToXMLConfig(FXMLCfg,'MsgView/Filters/');
    FXMLCfg.SetDeleteValue(Path+'MsgView/FPCMsg/ShowLinesCompiled',FMsgViewShowFPCMsgLinesCompiled,false);

    // glyphs
    FXMLCfg.SetDeleteValue(Path+'ShowButtonGlyphs/Value',Ord(FShowButtonGlyphs), Ord(sbgSystem));
    FXMLCfg.SetDeleteValue(Path+'ShowMenuGlyphs/Value',Ord(FShowMenuGlyphs), Ord(sbgSystem));

    // recent files and directories
    FXMLCfg.SetDeleteValue(Path+'Recent/OpenFiles/Max',FMaxRecentOpenFiles,DefaultMaxRecentOpenFiles);
    SaveRecentList(FXMLCfg,FRecentOpenFiles,Path+'Recent/OpenFiles/');
    FXMLCfg.SetDeleteValue(Path+'Recent/ProjectFiles/Max',FMaxRecentProjectFiles,DefaultMaxRecentProjectFiles);
    SaveRecentList(FXMLCfg,FRecentProjectFiles,Path+'Recent/ProjectFiles/');
    FXMLCfg.SetDeleteValue(Path+'Recent/PackageFiles/Max',FMaxRecentPackageFiles,DefaultMaxRecentPackageFiles);
    SaveRecentList(FXMLCfg,FRecentPackageFiles,Path+'Recent/PackageFiles/');

    FXMLCfg.SetDeleteValue(Path+'Recent/AlreadyPopulated', FAlreadyPopulatedRecentFiles, false);

    // external tools
    fExternalUserTools.Save(FConfigStore,Path+'ExternalTools/');
    FXMLCfg.SetDeleteValue(Path+'ExternalTools/MaxInParallel',FMaxExtToolsInParallel,0);

    // naming
    FXMLCfg.SetDeleteValue(Path+'Naming/PascalFileExtension',
                             PascalExtension[fPascalFileExtension],'.pas');
    FXMLCfg.SetDeleteValue(Path+'CharcaseFileAction/Value',
                             CharCaseFileActionNames[fCharcaseFileAction],
                             CharCaseFileActionNames[ccfaAutoRename]);
    FXMLCfg.SetDeleteValue(Path+'AmbiguousFileAction/Value',
      AmbiguousFileActionNames[fAmbiguousFileAction],
      AmbiguousFileActionNames[afaAsk]);
    FXMLCfg.SetDeleteValue(Path+'AskForFilenameOnNewFile/Value',
                             FAskForFilenameOnNewFile,false);
    FXMLCfg.SetDeleteValue(Path+'LowercaseDefaultFilename/Value',
                             FLowercaseDefaultFilename,true);
    if FMultipleInstances = DefaultIDEMultipleInstancesOption then
      FXMLCfg.DeletePath(Path+'MultipleInstances')
    else
      FXMLCfg.SetValue(Path+'MultipleInstances/Value',IDEMultipleInstancesOptionNames[FMultipleInstances]);

    // fpdoc
    FXMLCfg.SetDeleteValue(Path+'LazDoc/Paths',FPDocPaths,'');

    // 'new items'
    FXMLCfg.SetDeleteValue(Path+'New/UnitTemplate/Value',FNewUnitTemplate,FileDescNamePascalUnit);
    FXMLCfg.SetDeleteValue(Path+'New/FormTemplate/Value',FNewFormTemplate,FileDescNameLCLForm);

    // object inspector
    FObjectInspectorOptions.SaveBounds:=false;
    FObjectInspectorOptions.Save;

    // IDEEditorGroups
    for i := 0 to IDEEditorGroups.Count-1 do
    begin
      Rec := IDEEditorGroups[i];
      NodeName := Rec^.GroupClass.ClassName;
      FXMLCfg.SetDeleteValue(Path+'OptionDialog/Tree/' + NodeName + '/Value',
                               Rec^.Collapsed,
                               Rec^.DefaultCollapsed);
      if Rec^.Items <> nil then begin
        for j := 0 to Rec^.Items.Count-1 do begin
          FXMLCfg.SetDeleteValue(Path+'OptionDialog/Tree/' + NodeName
                                   + '/' + Rec^.Items[j]^.EditorClass.ClassName + '/Value',
                                   Rec^.Items[j]^.Collapsed,
                                   Rec^.Items[j]^.DefaultCollapsed);
        end;
      end;
    end;

    //automatically save active desktops
    if AutoSaveActiveDesktop then
    begin
      //save active desktop
      Desktop.ImportSettingsFromIDE;
      ActiveDesktop.Assign(Desktop);

      if Assigned(FLastDesktopBeforeDebug) then//are we in debug session?
      begin
        //save last desktop before the debug desktop
        xSaveDesktop := FDesktops.Find(FLastDesktopBeforeDebug.Name);
        if Assigned(xSaveDesktop) then
          xSaveDesktop.Assign(FLastDesktopBeforeDebug, False);
      end;
    end;
    if Assigned(FLastDesktopBeforeDebug) then
      xActiveDesktopName := FLastDesktopBeforeDebug.Name
    else
      xActiveDesktopName := FActiveDesktopName;

    // The user can define many desktops. They are saved under path Desktops/.
    FXMLCfg.DeletePath('Desktops/');
    CurPath:='Desktops/';
    FXMLCfg.SetDeleteValue(CurPath+'Count', FDesktops.Count, 0);
    FXMLCfg.SetDeleteValue(CurPath+'DebugDesktop', FDebugDesktopName, '');
    FXMLCfg.SetDeleteValue(CurPath+'ActiveDesktop', xActiveDesktopName, '');
    for i := 0 to FDesktops.Count-1 do
    begin
      FDesktops[i].SetConfig(FXMLCfg, FConfigStore);
      FDesktops[i].Save(CurPath+'Desktop'+IntToStr(i+1)+'/');
    end;

    FXMLCfg.Flush;
    FileUpdated;
  except
    on E: Exception do begin
      DebugLn('[TEnvironmentOptions.Save]  error writing "',Filename,'": ',E.Message);
    end;
  end;
end;

function TEnvironmentOptions.GetDefaultConfigFilename: string;
begin
  Result:=TrimFilename(AppendPathDelim(GetPrimaryConfigPath)+EnvOptsConfFileName);
end;

procedure TEnvironmentOptions.AddToRecentOpenFiles(const AFilename: string);
begin
  AddToRecentList(AFilename,FRecentOpenFiles,FMaxRecentOpenFiles,rltFile);
end;

procedure TEnvironmentOptions.RemoveFromRecentOpenFiles(const AFilename: string);
begin
  RemoveFromRecentList(AFilename,FRecentOpenFiles,rltFile);
end;

procedure TEnvironmentOptions.AddToRecentProjectFiles(const AFilename: string);
begin
  AddToRecentList(AFilename,FRecentProjectFiles,FMaxRecentProjectFiles,rltFile);
  {$ifdef Windows}
  SHAddToRecentDocs(SHARD_PATHW, PWideChar(UTF8ToUTF16(AFileName)));
  {$endif}
end;

procedure TEnvironmentOptions.RemoveFromRecentProjectFiles(const AFilename: string);
begin
  RemoveFromRecentList(AFilename,FRecentProjectFiles,rltFile);
end;

function TEnvironmentOptions.GetParsedTestBuildDirectory: string;
begin
  Result:=GetParsedValue(eopTestBuildDirectory);
end;

function TEnvironmentOptions.GetParsedFPCSourceDirectory(FPCVer: string): string;
var
  s: String;
begin
  if (FPCVer<>'') and (Pos('$(',FPCSourceDirectory)>0) then begin
    s:='$(FPCVer)';
    GlobalMacroList.SubstituteStr(s);
    if s<>FPCVer then begin
      // override macro FPCVer
      OverrideFPCVer:=FPCVer;
      IncreaseCompilerParseStamp;
      try
        Result:=GetParsedValue(eopFPCSourceDirectory);
        //debugln(['TEnvironmentOptions.GetParsedFPCSourceDirectory FPCVer=',FPCVer,' FPCSrcDir=',Result]);
      finally
        OverrideFPCVer:='';
        IncreaseCompilerParseStamp;
      end;
      exit;
    end;
  end;
  Result:=GetParsedValue(eopFPCSourceDirectory);
end;

function TEnvironmentOptions.GetParsedMakeFilename: string;
begin
  Result:=GetParsedValue(eopMakeFilename);
end;

function TEnvironmentOptions.GetParsedCompilerMessagesFilename: string;
begin
  Result:=GetParsedValue(eopCompilerMessagesFilename);
end;

function TEnvironmentOptions.GetParsedFPDocPaths: string;
begin
  Result:=GetParsedValue(eopFPDocPaths);
end;

function TEnvironmentOptions.GetParsedDebuggerFilename: string;
begin
  Result:=GetParsedValue(eopDebuggerFilename);
end;

function TEnvironmentOptions.GetParsedDebuggerSearchPath: string;
begin
  Result:=GetParsedValue(eopDebuggerSearchPath);
end;

function TEnvironmentOptions.GetParsedValue(o: TEnvOptParseType): string;
var
  SpacePos: SizeInt;
  CurParams: String;
begin
  with FParseValues[o] do begin
    if (ParseStamp<>CompilerParseStamp)
    or (CompilerParseStamp=CTInvalidChangeStamp) then begin
      if Parsing then begin
        debugln(['TEnvironmentOptions.GetParsedValue circular macro dependency: ',dbgs(o)]);
        exit('circularmacroerror');
      end;
      Parsing:=true;
      try
        ParsedValue:=UnparsedValue;
        if (ParsedValue='') and (o=eopCompilerMessagesFilename) then
          ParsedValue:=SetDirSeparators('$(FPCSrcDir)/compiler/msg/errore.msg');

        if not GlobalMacroList.SubstituteStr(ParsedValue) then begin
          debugln(['TEnvironmentOptions.GetParsedValue failed for ',dbgs(o),' Value="',UnparsedValue,'"']);
        end;
        ParseStamp:=CompilerParseStamp;

        case o of
        eopLazarusDirectory:
          // lazarus directory
          begin
            ParsedValue:=TrimAndExpandDirectory(ParsedValue,GetPrimaryConfigPath);
            if ParsedValue='' then
              ParsedValue:=TrimFilename(AppendPathDelim(GetCurrentDirUTF8));
          end;
        eopFPCSourceDirectory,eopTestBuildDirectory:
          // directory
          begin
            ParsedValue:=TrimAndExpandDirectory(ParsedValue,GetParsedLazarusDirectory);
            if ParsedValue='' then
              ParsedValue:=GetParsedLazarusDirectory;
          end;
        eopCompilerMessagesFilename:
          // data file
          begin
            ParsedValue:=TrimAndExpandFilename(ParsedValue,GetParsedLazarusDirectory);
            if (UnparsedValue='') and (not FileExistsCached(ParsedValue)) then
            begin
              // the default errore.msg file does not exist in the fpc sources
              // => use the fallback of the codetools
              ParsedValue:=AppendPathDelim(GetParsedLazarusDirectory)
                +SetDirSeparators('components/codetools/fpc.errore.msg');
            end;
          end;
        eopFPDocPaths,eopDebuggerSearchPath:
          // search path
          ParsedValue:=TrimSearchPath(ParsedValue,GetParsedLazarusDirectory,true);
        eopCompilerFilename,eopMakeFilename,eopDebuggerFilename:
          // program
          begin
            ParsedValue:=Trim(ParsedValue);
            CurParams:='';
            if (o in [eopDebuggerFilename]) then begin
              // program + params
              // examples:
              //   gdb -v
              //   "C:\public folder\gdb"
              SpacePos:=1;
              while (SpacePos<=length(ParsedValue)) do begin
                if ParsedValue[SpacePos]='"' then begin
                  System.Delete(ParsedValue,1,1); // delete startng "
                  while (SpacePos<=length(ParsedValue))
                  and (ParsedValue[SpacePos]<>'"') do
                    inc(SpacePos);
                  if SpacePos<=length(ParsedValue) then
                    System.Delete(ParsedValue,1,1); // delete ending "
                end else if ParsedValue[SpacePos]=' ' then
                  break
                else
                  inc(SpacePos);
              end;
              CurParams:=copy(ParsedValue,SpacePos,length(ParsedValue));
              system.Delete(ParsedValue,SpacePos,length(ParsedValue));
            end;
            // program
            ParsedValue:=TrimFilename(ParsedValue);
            if (ParsedValue<>'') and (not FilenameIsAbsolute(ParsedValue)) then
            begin
              if (ExtractFilePath(ParsedValue)='')
              and (not FileExistsCached(GetParsedLazarusDirectory+ParsedValue)) then
                ParsedValue:=FindDefaultExecutablePath(ParsedValue)
              else
                ParsedValue:=TrimFilename(GetParsedLazarusDirectory+ParsedValue);
            end;
            // append parameters
            if CurParams<>'' then begin
              if System.Pos(' ',ParsedValue)>0 then
                ParsedValue:='"'+ParsedValue+'"';
              ParsedValue+=CurParams;
            end;
          end;
        end;
      finally
        Parsing:=false;
      end;
    end;
    Result:=ParsedValue;
  end;
end;

function TEnvironmentOptions.GetParsedCompilerFilename: string;
begin
  Result:=GetParsedValue(eopCompilerFilename);
end;

procedure TEnvironmentOptions.InitMacros(AMacroList: TTransferMacroList);
begin
  AMacroList.Add(TTransferMacro.Create('FPCSrcDir','',
                 lisFreePascalSourceDirectory,@MacroFuncFPCSrcDir,[]));
  AMacroList.Add(TTransferMacro.Create('LazarusDir','',
                 lisLazarusDirectory,@MacroFuncLazarusDir,[]));
  AMacroList.Add(TTransferMacro.Create('ExeExt','',
                 lisFileExtensionOfPrograms, @MacroFuncExeExt, []));
  AMacroList.Add(TTransferMacro.Create('LanguageID','',
                 lisLazarusLanguageID,@MacroFuncLanguageID,[]));
  AMacroList.Add(TTransferMacro.Create('LanguageName','',
                 lisLazarusLanguageName,@MacroFuncLanguageName,[]));
  AMacroList.Add(TTransferMacro.Create('TestDir','',
                 lisTestDirectory,@MacroFuncTestDir,[]));
  AMacroList.Add(TTransferMacro.Create('ConfDir','',
                 lisConfigDirectory,@MacroFuncConfDir,[]));
  AMacroList.Add(TTransferMacro.Create('Home',GetUserDir,
                 lisUserSHomeDirectory, nil, []));
end;

function TEnvironmentOptions.MacroFuncFPCSrcDir(const s: string;
  const Data: PtrInt; var Abort: boolean): string;
begin
  Result:=GetParsedFPCSourceDirectory;
end;

function TEnvironmentOptions.MacroFuncLazarusDir(const s: string;
  const Data: PtrInt; var Abort: boolean): string;
begin
  Result:=GetParsedLazarusDirectory;
end;

function TEnvironmentOptions.MacroFuncExeExt(const s: string;
  const Data: PtrInt; var Abort: boolean): string;
begin
  Result:=GetExecutableExt;
end;

function TEnvironmentOptions.MacroFuncLanguageID(const s: string;
  const Data: PtrInt; var Abort: boolean): string;
begin
  Result:=LanguageID;
end;

function TEnvironmentOptions.MacroFuncLanguageName(const s: string;
  const Data: PtrInt; var Abort: boolean): string;
begin
  Result:=GetLazarusLanguageLocalizedName(LanguageID);
end;

function TEnvironmentOptions.MacroFuncTestDir(const s: string;
  const Data: PtrInt; var Abort: boolean): string;
begin
  Result:=GetParsedTestBuildDirectory;
end;

function TEnvironmentOptions.MacroFuncConfDir(const s: string;
  const Data: PtrInt; var Abort: boolean): string;
begin
  Result:=GetPrimaryConfigPath;
end;

procedure TEnvironmentOptions.SaveDebuggerPropertiesList;
var
  DProp, DDef: TDebuggerProperties;
  i: Integer;
begin
  for i := 0 to FDebuggerProperties.Count - 1 do begin
    DProp := TDebuggerProperties(FDebuggerProperties.Objects[i]);
    DDef := TDebuggerPropertiesClass(DProp.ClassType).Create;
    FXMLCfg.WriteObject(
      'EnvironmentOptions/Debugger/Class' + FDebuggerProperties[i] + '/Properties/',
      DProp, DDef);
    DDef.Free;
  end;
end;

procedure TEnvironmentOptions.SaveDebuggerProperties(DebuggerClass: String;
  Properties: TDebuggerProperties);
var
  i: Integer;
  Prop: TDebuggerProperties;
begin
  i := FDebuggerProperties.IndexOf(DebuggerClass);
  if i < 0 then begin
    Prop := TDebuggerPropertiesClass(Properties.ClassType).Create;
    Prop.Assign(Properties);
    FDebuggerProperties.AddObject(DebuggerClass, Prop);
  end
  else
    TDebuggerProperties(FDebuggerProperties.Objects[i]).Assign(Properties);
end;

procedure TEnvironmentOptions.LoadDebuggerProperties(DebuggerClass: String;
  Properties: TDebuggerProperties);
var
  i: Integer;
  DDef: TDebuggerProperties;
begin
  i := FDebuggerProperties.IndexOf(DebuggerClass);
  if i < 0 then begin
    DDef := TDebuggerPropertiesClass(Properties.ClassType).Create;
    FXMLCfg.ReadObject('EnvironmentOptions/Debugger/Class' + DebuggerClass + '/Properties/',
      Properties, DDef);
    DDef.Free;
  end
  else
    Properties.Assign(TDebuggerProperties(FDebuggerProperties.Objects[i]));
end;

function TEnvironmentOptions.FileHasChangedOnDisk: boolean;
begin
  Result:=FFileHasChangedOnDisk
      or ((FFilename<>'') and (FFileAge<>0) and (FileAgeCached(FFilename)<>FFileAge));
  FFileHasChangedOnDisk:=Result;
end;

procedure TEnvironmentOptions.InitXMLCfg(CleanConfig: boolean);
begin
  if FileHasChangedOnDisk or (FXMLCfg=nil) then begin
    FreeAndNil(FConfigStore);
    FreeAndNil(FDbgConfigStore);
    FreeAndNil(FXMLCfg);
    if CleanConfig then
      FXMLCfg:=TRttiXMLConfig.CreateClean(Filename)
    else
      FXMLCfg:=TRttiXMLConfig.Create(Filename);
    FConfigStore:=TXMLOptionsStorage.Create(FXMLCfg);
    //ComponentPaletteOptions.ConfigStore:=FConfigStore;
    ObjectInspectorOptions.ConfigStore:=FConfigStore;
    FDbgConfigStore:=TXMLOptionsStorage.Create(FXMLCfg, 'EnvironmentOptions/Debugger/');
    FDebuggerConfig.ConfigStore := FDbgConfigStore;
  end;
end;

procedure TEnvironmentOptions.FileUpdated;
begin
  FFileHasChangedOnDisk:=false;
  if FFilename<>'' then
    FFileAge:=FileAgeCached(FFilename)
  else
    FFileAge:=0;
end;

function TEnvironmentOptions.GetActiveDesktop: TDesktopOpt;

  procedure ChooseDefault;
  begin
    //use default desktop name
    if Assigned(IDEDockMaster) then
      FActiveDesktopName := 'default docked'//name for desktop with AnchorDocking
    else
      FActiveDesktopName := 'default';
  end;

begin
  if FActiveDesktopName <> '' then
  begin
    Result := FDesktops.Find(FActiveDesktopName);
    if Assigned(Result) and Result.Compatible then
      Exit;
  end;

  //the selected desktop is unsupported (docked/undocked)
  // -> use default
  ChooseDefault;
  Result := FDesktops.Find(FActiveDesktopName);
  if Assigned(Result) and Result.Compatible then
    Exit;

  //recreate desktop with ActiveDesktopName
  if Assigned(Result) then
    FDesktops.Remove(Result);

  Result := TDesktopOpt.Create(FActiveDesktopName);
  FDesktops.Add(Result);
  Result.Assign(Desktop);
end;

procedure TEnvironmentOptions.SetTestBuildDirectory(const AValue: string);
var
  NewValue: String;
begin
  NewValue:=AppendPathDelim(TrimFilename(AValue));
  SetParseValue(eopTestBuildDirectory,NewValue);
end;

procedure TEnvironmentOptions.UseDesktop(ADesktop: TDesktopOpt);
  function _ContainsControl(const _Parent, _Control: TWinControl): Boolean;
  var
    I: Integer;
  begin
    for I := 0 to _Parent.ControlCount-1 do
    if _Parent.Controls[I] is TWinControl then
    begin
      if (_Parent.Controls[I] = _Control) or
         _ContainsControl(TWinControl(_Parent.Controls[I]), _Control)
      then
        Exit(True);
    end;
    Result := False;
  end;
var
  xLastFocusControl: TWinControl;
  xLastFocusForm: TCustomForm;
begin
  xLastFocusControl := Screen.ActiveControl;
  xLastFocusForm := Screen.ActiveCustomForm;
  DoBeforeWrite(False);  //this is needed to get the EditorToolBar refreshed!!! - needed only here in UseDesktop()
  Desktop.Assign(ADesktop);
  ActiveDesktopName := ADesktop.Name;
  DoAfterWrite(False);  //this is needed to get the EditorToolBar refreshed!!! - needed only here in UseDesktop()
  Desktop.ExportSettingsToIDE;
  Desktop.RestoreDesktop;

  //set focus back to the previously focused control
  if Screen.CustomFormIndex(xLastFocusForm) >= 0 then//check if form hasn't been destroyed
  begin
    if ((xLastFocusForm = xLastFocusControl) or _ContainsControl(xLastFocusForm, xLastFocusControl)) and//check if control hasn't been destroyed
       xLastFocusForm.CanFocus and
       xLastFocusControl.CanFocus
    then
      xLastFocusControl.SetFocus;
  end;
end;

procedure TEnvironmentOptions.SetLazarusDirectory(const AValue: string);
var
  NewValue: String;
begin
  NewValue:=AppendPathDelim(TrimFilename(AValue));
  SetParseValue(eopLazarusDirectory,NewValue);
end;

procedure TEnvironmentOptions.SetMsgColors(u: TMessageLineUrgency; AValue: TColor);
begin
  fMsgColors[u] := AValue;
end;

procedure TEnvironmentOptions.SetMsgViewColors(c: TMsgWndColor; AValue: TColor);
begin
  fMsgViewColors[c]:=AValue;
end;

procedure TEnvironmentOptions.SetParseValue(o: TEnvOptParseType;
  const NewValue: string);
begin
  with FParseValues[o] do begin
    if UnparsedValue=NewValue then exit;
    UnparsedValue:=NewValue;
    ParseStamp:=CTInvalidChangeStamp;
    IncreaseCompilerParseStamp;
  end;
end;

procedure TEnvironmentOptions.SetFPCSourceDirectory(const AValue: string);
begin
  SetParseValue(eopFPCSourceDirectory,AValue);
end;

procedure TEnvironmentOptions.SetCompilerFilename(const AValue: string);
begin
  SetParseValue(eopCompilerFilename,TrimFilename(AValue));
end;

procedure TEnvironmentOptions.SetCompilerMessagesFilename(AValue: string);
begin
  SetParseValue(eopCompilerMessagesFilename,TrimFilename(AValue));
end;

function TEnvironmentOptions.GetDebuggerEventLogColors(AIndex: TDBGEventType): TDebuggerEventLogColor;
begin
  Result := FDebuggerEventLogColors[AIndex];
end;

function TEnvironmentOptions.GetDebuggerFilename: string;
begin
  Result:=FParseValues[eopDebuggerFilename].UnparsedValue;
end;

function TEnvironmentOptions.GetDebuggerSearchPath: string;
begin
  Result:=FParseValues[eopDebuggerSearchPath].UnparsedValue;
end;

function TEnvironmentOptions.GetCompilerFilename: string;
begin
  Result:=FParseValues[eopCompilerFilename].UnparsedValue;
end;

function TEnvironmentOptions.GetCompilerMessagesFilename: string;
begin
  Result:=FParseValues[eopCompilerMessagesFilename].UnparsedValue;
end;

function TEnvironmentOptions.GetDebugDesktop: TDesktopOpt;
begin
  if FDebugDesktopName <> '' then
  begin
    Result := FDesktops.Find(FDebugDesktopName);
    if not(Assigned(Result) and Result.Compatible) then//do not mix docked/undocked desktops
      Result := nil;
  end else
    Result := nil;
end;

function TEnvironmentOptions.GetFPCSourceDirectory: string;
begin
  Result:=FParseValues[eopFPCSourceDirectory].UnparsedValue;
end;

function TEnvironmentOptions.GetFPDocPaths: string;
begin
  Result:=FParseValues[eopFPDocPaths].UnparsedValue;
end;

function TEnvironmentOptions.GetLazarusDirectory: string;
begin
  Result:=FParseValues[eopLazarusDirectory].UnparsedValue;
end;

function TEnvironmentOptions.GetMakeFilename: string;
begin
  Result:=FParseValues[eopMakeFilename].UnparsedValue;
end;

function TEnvironmentOptions.GetMsgColors(u: TMessageLineUrgency): TColor;
begin
  Result:=fMsgColors[u];
end;

function TEnvironmentOptions.GetMsgViewColors(c: TMsgWndColor): TColor;
begin
  Result:=fMsgViewColors[c];
end;

function TEnvironmentOptions.GetTestBuildDirectory: string;
begin
  Result:=FParseValues[eopTestBuildDirectory].UnparsedValue;
end;

procedure TEnvironmentOptions.SetDebuggerEventLogColors(AIndex: TDBGEventType; const AValue: TDebuggerEventLogColor);
begin
  FDebuggerEventLogColors[AIndex] := AValue;
end;

procedure TEnvironmentOptions.SetDebuggerSearchPath(const AValue: string);
begin
  SetParseValue(eopDebuggerSearchPath,TrimSearchPath(AValue,''));
end;

procedure TEnvironmentOptions.SetFPDocPaths(const AValue: string);
begin
  SetParseValue(eopFPDocPaths,TrimSearchPath(AValue,''));
end;

procedure TEnvironmentOptions.SetMakeFilename(const AValue: string);
begin
  SetParseValue(eopMakeFilename,TrimFilename(AValue));
end;

procedure TEnvironmentOptions.SetDebuggerFilename(AValue: string);
begin
  SetParseValue(eopDebuggerFilename,UTF8Trim(AValue));
end;

initialization
  RegisterIDEOptionsGroup(GroupEnvironment, TEnvironmentOptions);
end.

