{ $Id$ }
{                  -------------------------------------------
                    DebuggerBase.pp  -  Debugger base classes
                   -------------------------------------------

 @author(Marc Weustink <marc@@dommelstein.net>)
 @author(Martin Friebe)

 This unit contains the base class definitions of the debugger. These
 classes are only definitions. Implemented debuggers should be
 derived from these.

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
unit DbgIntfDebuggerBase;

{$mode objfpc}{$H+}

interface

uses DbgIntfBaseTypes, DbgIntfMiscClasses, LazClasses, LazLoggerBase, FileUtil,
  maps, LCLProc, Classes, sysutils, math, contnrs, LazMethodList;

const
  DebuggerIntfVersion = 0;

type
  EDebuggerException = class(Exception);
  EDBGExceptions = class(EDebuggerException);

  TDBGCommand = (
    dcRun,
    dcPause,
    dcStop,
    dcStepOver,
    dcStepInto,
    dcStepOut,
    dcRunTo,
    dcJumpto,
    dcAttach,
    dcDetach,
    dcBreak,
    dcWatch,
    dcLocal,
    dcEvaluate,
    dcModify,
    dcEnvironment,
    dcSetStackFrame,
    dcDisassemble,
    dcStepOverInstr,
    dcStepIntoInstr,
    dcSendConsoleInput
    );
  TDBGCommands = set of TDBGCommand;

  { Debugger states
    --------------------------------------------------------------------------
    dsNone:
      The debug object is created, but no instance of an external debugger
      exists.
      Initial state, leave with Init, enter with Done

    dsIdle:
      The external debugger is started, but no filename (or no other params
      required to start) were given.

    dsStop:
      (Optional) The execution of the target is stopped
      The external debugger is loaded and ready to (re)start the execution
      of the target.
      Breakpoints, watches etc can be defined

    dsPause:
      The debugger has paused the target. Target variables can be examined

    dsInternalPause:
      Pause, not visible to user.
      For examble auto continue breakpoint: Allow collection of Snapshot data

    dsInit:
      (Optional, Internal) The debugger is about to run

    dsRun:
      The target is running.

    dsError:
      Something unforseen has happened. A shutdown of the debugger is in
      most cases needed.

    -dsDestroying
      The debugger is about to be destroyed.
      Should normally happen immediate on calling Release.
      But the debugger may be in nested calls, and has to exit them first.
    --------------------------------------------------------------------------
  }
  TDBGState = (
    dsNone,
    dsIdle,
    dsStop,
    dsPause,
    dsInternalPause,
    dsInit,
    dsRun,
    dsError,
    dsDestroying
    );

  TDBGLocationRec = record
    Address: TDBGPtr;
    FuncName: String;
    SrcFile: String;
    SrcFullName: String;
    SrcLine: Integer;
  end;

  TDBGExceptionType = (
    deInternal,
    deExternal,
    deRunError
  );

  TDebuggerDataState = (ddsUnknown,                    //
                        ddsRequested, ddsEvaluating,   //
                        ddsValid,                      // Got a valid value
                        ddsInvalid,                    // Does not have a value
                        ddsError                       // Error, but got some Value to display (e.g. error msg)
                       );

  (* TValidState: State for breakpoints *)
  TValidState = (vsUnknown, vsValid, vsInvalid);

  TDBGEvaluateFlag =
    (defNoTypeInfo,        // No Typeinfo object will be returned
     defSimpleTypeInfo,    // Returns: Kind (skSimple, skClass, ..); TypeName (but does make no attempt to avoid an alias)
     defFullTypeInfo,      // Get all typeinfo, resolve all anchestors
     defClassAutoCast      // Find real class of instance, and use, instead of declared class of variable
    );
  TDBGEvaluateFlags = set of TDBGEvaluateFlag;

  { TRunningProcessInfo
    Used to enumerate running processes.
  }

  TRunningProcessInfo = class
  public
    PID: Cardinal;
    ImageName: string;
    constructor Create(APID: Cardinal; const AImageName: string);
  end;

  TRunningProcessInfoList = TObjectList;

  (* TDebuggerDataMonitor / TDebuggerDataSupplier
     - TDebuggerDataMonitor
       used by the IDE to receive/request updates on all data objects
     - TDebuggerDataSupplier
       used by the debugger to provide updates on all data objects
  *)

  TDebuggerIntf = class;
  TDebuggerDataSupplier = class;

  { TDebuggerDataHandler }

  TDebuggerDataHandler = class
  private
    FNotifiedState: TDBGState;
    FOldState: TDBGState;
    FUpdateCount: Integer;
  protected
    //procedure DoModified; virtual;                                              // user-modified / xml-storable data modified
    procedure DoStateEnterPause; virtual;
    procedure DoStateLeavePause; virtual;
    procedure DoStateLeavePauseClean; virtual;
    procedure DoStateChangeEx(const AOldState, ANewState: TDBGState); virtual;
    property  NotifiedState: TDBGState read FNotifiedState;                     // The last state seen by DoStateChange
    property  OldState: TDBGState read FOldState;                               // The state before last DoStateChange

    procedure DoBeginUpdate; virtual;
    procedure DoEndUpdate; virtual;
  public
    //destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    function  IsUpdating: Boolean;
  end;

  { TDebuggerDataMonitor }

  TDebuggerDataMonitor = class(TDebuggerDataHandler)
  private
    FSupplier: TDebuggerDataSupplier;
    procedure SetSupplier(const AValue: TDebuggerDataSupplier);
  protected
    procedure DoModified; virtual;                                              // user-modified / xml-storable data modified
    procedure DoNewSupplier; virtual;
    property  Supplier: TDebuggerDataSupplier read FSupplier write SetSupplier;
  public
    destructor Destroy; override;
  end;

  { TDebuggerDataSupplier }

  TDebuggerDataSupplier = class(TDebuggerDataHandler)
  private
    FDebugger: TDebuggerIntf;
    FMonitor: TDebuggerDataMonitor;
    procedure SetMonitor(const AValue: TDebuggerDataMonitor);
  protected
    procedure DoNewMonitor; virtual;
    property  Debugger: TDebuggerIntf read FDebugger write FDebugger;
  protected
    property  Monitor: TDebuggerDataMonitor read FMonitor write SetMonitor;

    procedure DoStateLeavePauseClean; override;
    procedure DoStateChange(const AOldState: TDBGState); virtual;

    property  NotifiedState: TDBGState read FNotifiedState;                     // The last state seen by DoStateChange
    property  OldState: TDBGState read FOldState;                               // The state before last DoStateChange
    procedure DoBeginUpdate; override;
    procedure DoEndUpdate; override;
  public
    constructor Create(const ADebugger: TDebuggerIntf);
    destructor  Destroy; override;
  end;

{$region Breakpoints **********************************************************}
(******************************************************************************)
(**                                                                          **)
(**   B R E A K P O I N T S                                                  **)
(**                                                                          **)
(** Note: This part of the interface may/will still change to the            **)
(**       monitor/supplier concept                                         **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

  TDBGBreakPointKind = (
    bpkSource,  // source breakpoint
    bpkAddress, // address breakpoint
    bpkData     // data/watchpoint
  );

  TDBGWatchPointScope = (
    wpsLocal,
    wpsGlobal
  );

  TDBGWatchPointKind = (
    wpkWrite,
    wpkRead,
    wpkReadWrite
  );

  { TBaseBreakPoint }

  TBaseBreakPoint = class(TRefCountedColectionItem)
  protected
    FAddress: TDBGPtr;
    FWatchData: String;
    FEnabled: Boolean;
    FExpression: String;
    FHitCount: Integer;      // Current counter
    FBreakHitCount: Integer; // The user configurable value
    FKind: TDBGBreakPointKind;
    FLine: Integer;
    FWatchScope: TDBGWatchPointScope;
    FWatchKind: TDBGWatchPointKind;
    FSource: String;
    FValid: TValidState;
    FInitialEnabled: Boolean;
  protected
    procedure AssignLocationTo(Dest: TPersistent); virtual;
    procedure AssignTo(Dest: TPersistent); override;
    procedure DoBreakHitCountChange; virtual;
    procedure DoExpressionChange; virtual;
    procedure DoEnableChange; virtual;
    procedure DoHit(const ACount: Integer; var {%H-}AContinue: Boolean); virtual;
    procedure SetHitCount(const AValue: Integer);
    procedure DoKindChange; virtual;
    procedure SetValid(const AValue: TValidState);
  protected
    // virtual properties
    function GetAddress: TDBGPtr; virtual;
    function GetBreakHitCount: Integer; virtual;
    function GetEnabled: Boolean; virtual;
    function GetExpression: String; virtual;
    function GetHitCount: Integer; virtual;
    function GetKind: TDBGBreakPointKind; virtual;
    function GetLine: Integer; virtual;
    function GetSource: String; virtual;
    function GetWatchData: String; virtual;
    function GetWatchScope: TDBGWatchPointScope; virtual;
    function GetWatchKind: TDBGWatchPointKind; virtual;
    function GetValid: TValidState; virtual;

    procedure SetAddress(const AValue: TDBGPtr); virtual;
    procedure SetBreakHitCount(const AValue: Integer); virtual;
    procedure SetEnabled(const AValue: Boolean); virtual;
    procedure SetExpression(const AValue: String); virtual;
    procedure SetInitialEnabled(const AValue: Boolean); virtual;
    procedure SetKind(const AValue: TDBGBreakPointKind); virtual;
  public
    constructor Create(ACollection: TCollection); override;
    // PublicProtectedFix ide/debugmanager.pas(867,32) Error: identifier idents no member "SetLocation"
    property BreakHitCount: Integer read GetBreakHitCount write SetBreakHitCount;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property Expression: String read GetExpression write SetExpression;
    property HitCount: Integer read GetHitCount;
    property InitialEnabled: Boolean read FInitialEnabled write SetInitialEnabled;
    property Kind: TDBGBreakPointKind read GetKind write SetKind;
    property Valid: TValidState read GetValid;
  public
    procedure SetLocation(const ASource: String; const ALine: Integer); virtual;
    procedure SetWatch(const AData: String; const AScope: TDBGWatchPointScope;
                       const AKind: TDBGWatchPointKind); virtual;
    // bpkAddress
    property Address: TDBGPtr read GetAddress write SetAddress;
    // bpkSource
    //   TDBGBreakPoint: Line is the line-number as stored in the debug info
    //   TIDEBreakPoint: Line is the location in the Source (potentially modified Source)
    property Line: Integer read GetLine;
    property Source: String read GetSource;
    // bpkData
    property WatchData: String read GetWatchData;
    property WatchScope: TDBGWatchPointScope read GetWatchScope;
    property WatchKind: TDBGWatchPointKind read GetWatchKind;
  end;
  TBaseBreakPointClass = class of TBaseBreakPoint;

  { TDBGBreakPoint }

  TDBGBreakPoint = class(TBaseBreakPoint)
  private
    FSlave: TBaseBreakPoint;
    function GetDebugger: TDebuggerIntf;
    procedure SetSlave(const ASlave : TBaseBreakPoint);
  protected
    procedure SetEnabled(const AValue: Boolean); override;
    procedure DoChanged; override;
    procedure DoStateChange(const AOldState: TDBGState); virtual;
    property  Debugger: TDebuggerIntf read GetDebugger;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Hit(var ACanContinue: Boolean);
    property Slave: TBaseBreakPoint read FSlave write SetSlave;

    procedure DoLogMessage(const AMessage: String); virtual;
    procedure DoLogCallStack(const {%H-}Limit: Integer); virtual;
    procedure DoLogExpression(const {%H-}AnExpression: String); virtual; // implemented in TGDBMIBreakpoint
  end;
  TDBGBreakPointClass = class of TDBGBreakPoint;

  { TBaseBreakPoints }

  TBaseBreakPoints = class(TCollection)
  private
  protected
  public
    constructor Create(const ABreakPointClass: TBaseBreakPointClass);
    destructor Destroy; override;
    procedure Clear; reintroduce;
    function Add(const ASource: String; const ALine: Integer): TBaseBreakPoint; overload;
    function Add(const AAddress: TDBGPtr): TBaseBreakPoint; overload;
    function Add(const AData: String; const AScope: TDBGWatchPointScope;
                 const AKind: TDBGWatchPointKind): TBaseBreakPoint; overload;
    function Find(const ASource: String; const ALine: Integer): TBaseBreakPoint; overload;
    function Find(const ASource: String; const ALine: Integer; const AIgnore: TBaseBreakPoint): TBaseBreakPoint; overload;
    function Find(const AAddress: TDBGPtr): TBaseBreakPoint; overload;
    function Find(const AAddress: TDBGPtr; const AIgnore: TBaseBreakPoint): TBaseBreakPoint; overload;
    function Find(const AData: String; const AScope: TDBGWatchPointScope;
                  const AKind: TDBGWatchPointKind): TBaseBreakPoint; overload;
    function Find(const AData: String; const AScope: TDBGWatchPointScope;
                  const AKind: TDBGWatchPointKind; const AIgnore: TBaseBreakPoint): TBaseBreakPoint; overload;
    // no items property needed, it is "overridden" anyhow
  end;

  { TDBGBreakPoints }

  TDBGBreakPoints = class(TBaseBreakPoints)
  private
    FDebugger: TDebuggerIntf;  // reference to our debugger
    function GetItem(const AnIndex: Integer): TDBGBreakPoint;
    procedure SetItem(const AnIndex: Integer; const AValue: TDBGBreakPoint);
  protected
    procedure DoStateChange(const AOldState: TDBGState); virtual;
    property  Debugger: TDebuggerIntf read FDebugger write FDebugger;
  public
    constructor Create(const ADebugger: TDebuggerIntf;
                       const ABreakPointClass: TDBGBreakPointClass);
    function Add(const ASource: String; const ALine: Integer): TDBGBreakPoint; overload;
    function Add(const AAddress: TDBGPtr): TDBGBreakPoint; overload;
    function Add(const AData: String; const AScope: TDBGWatchPointScope;
                 const AKind: TDBGWatchPointKind): TDBGBreakPoint; overload;
    function Find(const ASource: String; const ALine: Integer): TDBGBreakPoint; overload;
    function Find(const ASource: String; const ALine: Integer; const AIgnore: TDBGBreakPoint): TDBGBreakPoint; overload;
    function Find(const AAddress: TDBGPtr): TDBGBreakPoint; overload;
    function Find(const AAddress: TDBGPtr; const {%H-}AIgnore: TDBGBreakPoint): TDBGBreakPoint; overload;
    function Find(const AData: String; const AScope: TDBGWatchPointScope;
                  const AKind: TDBGWatchPointKind): TDBGBreakPoint; overload;
    function Find(const AData: String; const AScope: TDBGWatchPointScope;
                  const AKind: TDBGWatchPointKind; const AIgnore: TDBGBreakPoint): TDBGBreakPoint; overload;

    property Items[const AnIndex: Integer]: TDBGBreakPoint read GetItem write SetItem; default;
  end;

{%endregion   ^^^^^  Breakpoints  ^^^^^   }

{$region Debug Info ***********************************************************}
(******************************************************************************)
(**                                                                          **)
(**   D E B U G   I N F O R M A T I O N                                      **)
(**                                                                          **)
(** Note: This part of the interface may/will still change.                  **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

  TDBGSymbolAttribute = (saRefParam,        // var, const, constref passed by reference
                         saInternalPointer, // PointerToObject
                         saArray, saDynArray
                        );
  TDBGSymbolAttributes = set of TDBGSymbolAttribute;
  TDBGFieldLocation = (flPrivate, flProtected, flPublic, flPublished);
  TDBGFieldFlag = (ffVirtual,ffConstructor,ffDestructor);
  TDBGFieldFlags = set of TDBGFieldFlag;

  TDBGType = class;

  TDBGValue = record
    AsString: ansistring;
    case integer of
      0: (As8Bits: BYTE);
      1: (As16Bits: WORD);
      2: (As32Bits: DWORD);
      3: (As64Bits: QWORD);
      4: (AsSingle: Single);
      5: (AsDouble: Double);
      6: (AsPointer: Pointer);
  end;

  { TDBGField }

  TDBGField = class(TObject)
  private
    FRefCount: Integer;
  protected
    FName: String;
    FFlags: TDBGFieldFlags;
    FLocation: TDBGFieldLocation;
    FDBGType: TDBGType;
    FClassName: String;
    procedure IncRefCount;
    procedure DecRefCount;
    property RefCount: Integer read FRefCount;
  public
    constructor Create(const AName: String; ADBGType: TDBGType;
                       ALocation: TDBGFieldLocation; AFlags: TDBGFieldFlags = [];
                       AClassName: String = '');
    destructor Destroy; override;
    property Name: String read FName;
    property DBGType: TDBGType read FDBGType;
    property Location: TDBGFieldLocation read FLocation;
    property Flags: TDBGFieldFlags read FFlags;
    property ClassName: String read FClassName; // the class in which the field was declared
  end;

  { TDBGFields }

  TDBGFields = class(TObject)
  private
    FList: TList;
    function GetField(const AIndex: Integer): TDBGField;
    function GetCount: Integer;
  protected
  public
    constructor Create;
    destructor Destroy; override;
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TDBGField read GetField; default;
    procedure Add(const AField: TDBGField);
  end;

  TDBGTypes = class(TObject)
  private
    function GetType(const AIndex: Integer): TDBGType;
    function GetCount: Integer;
  protected
    FList: TList;
  public
    constructor Create;
    destructor Destroy; override;
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TDBGType read GetType; default;
  end;

  { TDBGType }

  TDBGType = class(TObject)
  private
    function GetFields: TDBGFields;
  protected
    FAncestor: String;
    FResult: TDBGType;
    FResultString: String;
    FArguments: TDBGTypes;
    FAttributes: TDBGSymbolAttributes;
    FFields: TDBGFields;
    FKind: TDBGSymbolKind;
    FMembers: TStrings;
    FTypeName: String;
    FTypeDeclaration: String;
    FDBGValue: TDBGValue;
    FBoundHigh: Integer;
    FBoundLow: Integer;
    FLen: Integer;
    procedure Init; virtual;
  public
    Value: TDBGValue;
    constructor Create(AKind: TDBGSymbolKind; const ATypeName: String);
    constructor Create(AKind: TDBGSymbolKind; const AArguments: TDBGTypes; AResult: TDBGType = nil);
    destructor Destroy; override;
    property Ancestor: String read FAncestor write FAncestor;
    property Arguments: TDBGTypes read FArguments;
    property Fields: TDBGFields read GetFields;
    property Kind: TDBGSymbolKind read FKind;
    property Attributes: TDBGSymbolAttributes read FAttributes;
    property TypeName: String read FTypeName;               // Name/Alias as in type section. One pascal token, or empty
    property TypeDeclaration: String read FTypeDeclaration; // Declaration (for array, set, enum, ..)
    property Members: TStrings read FMembers;               // Set & ENUM
    property Len: Integer read FLen;                        // Array
    property BoundLow: Integer read FBoundLow;              // Array
    property BoundHigh: Integer read FBoundHigh;            // Array
    property Result: TDBGType read FResult;
  end;

{%endregion   ^^^^^  Debug Info  ^^^^^   }

{%region Watches **************************************************************
 ******************************************************************************
 **                                                                          **
 **   W A T C H E S                                                          **
 **                                                                          **
 ******************************************************************************
 ******************************************************************************}

  TWatchDisplayFormat =
    (wdfDefault,
     wdfStructure,
     wdfChar, wdfString,
     wdfDecimal, wdfUnsigned, wdfFloat, wdfHex,
     wdfPointer,
     wdfMemDump
    );

  TWatch = class;
  TWatchesMonitor = class;

  { TWatchValue }

  TWatchValue = class(TFreeNotifyingObject)
  private
    FTypeInfo: TDBGType;
    FValue: String;
    FValidity: TDebuggerDataState;
    FWatch: TWatch;

    procedure SetValidity(AValue: TDebuggerDataState); virtual;
    procedure SetValue(AValue: String);
    procedure SetTypeInfo(AValue: TDBGType);
    function GetWatch: TWatch;
  protected
    FDisplayFormat: TWatchDisplayFormat;
    FEvaluateFlags: TDBGEvaluateFlags;
    FRepeatCount: Integer;
    FStackFrame: Integer;
    FThreadId: Integer;
    procedure DoDataValidityChanged({%H-}AnOldValidity: TDebuggerDataState); virtual;

    function GetExpression: String; virtual;
    function GetTypeInfo: TDBGType; virtual;
    function GetValue: String; virtual;
  public
    constructor Create(AOwnerWatch: TWatch);
    destructor Destroy; override;
    procedure Assign(AnOther: TWatchValue); virtual;
    property DisplayFormat: TWatchDisplayFormat read FDisplayFormat;
    property EvaluateFlags: TDBGEvaluateFlags read FEvaluateFlags;
    property RepeatCount: Integer read FRepeatCount;
    property ThreadId: Integer read FThreadId;
    property StackFrame: Integer read FStackFrame;
    property Expression: String read GetExpression;
    property Watch: TWatch read GetWatch;
  public
    property Validity: TDebuggerDataState read FValidity write SetValidity;
    property Value: String read GetValue write SetValue;
    property TypeInfo: TDBGType read GetTypeInfo write SetTypeInfo;
  end;

  { TWatchValueList }

  TWatchValueList = class
  private
    FList: TList;
    FWatch: TWatch;
    function GetEntry(const AThreadId: Integer; const AStackFrame: Integer): TWatchValue;
    function GetEntryByIdx(AnIndex: integer): TWatchValue;
  protected
    function CreateEntry(const {%H-}AThreadId: Integer; const {%H-}AStackFrame: Integer): TWatchValue; virtual;
    function CopyEntry(AnEntry: TWatchValue): TWatchValue; virtual;
  public
    procedure Assign(AnOther: TWatchValueList);
    constructor Create(AOwnerWatch: TWatch);
    destructor Destroy; override;
    procedure Add(AnEntry: TWatchValue);
    procedure Clear;
    function Count: Integer;
    property EntriesByIdx[AnIndex: integer]: TWatchValue read GetEntryByIdx;
    property Entries[const AThreadId: Integer; const AStackFrame: Integer]: TWatchValue
             read GetEntry; default;
    property Watch: TWatch read FWatch;
  end;

  { TWatch }

  TWatch = class(TDelayedUdateItem)
  private

    procedure SetDisplayFormat(AValue: TWatchDisplayFormat);
    procedure SetEnabled(AValue: Boolean);
    procedure SetEvaluateFlags(AValue: TDBGEvaluateFlags);
    procedure SetExpression(AValue: String);
    procedure SetRepeatCount(AValue: Integer);
    function GetValue(const AThreadId: Integer; const AStackFrame: Integer): TWatchValue;
  protected
    FEnabled: Boolean;
    FEvaluateFlags: TDBGEvaluateFlags;
    FExpression: String;
    FDisplayFormat: TWatchDisplayFormat;
    FRepeatCount: Integer;
    FValueList: TWatchValueList;

    procedure DoModified; virtual;  // user-storable data: expression, enabled, display-format
    procedure DoEnableChange; virtual;
    procedure DoExpressionChange; virtual;
    procedure DoDisplayFormatChanged; virtual;
    procedure AssignTo(Dest: TPersistent); override;
    function CreateValueList: TWatchValueList; virtual;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure ClearValues; virtual;
  public
    property Enabled: Boolean read FEnabled write SetEnabled;
    property Expression: String read FExpression write SetExpression;
    property DisplayFormat: TWatchDisplayFormat read FDisplayFormat write SetDisplayFormat;
    property EvaluateFlags: TDBGEvaluateFlags read FEvaluateFlags write SetEvaluateFlags;
    property RepeatCount: Integer read FRepeatCount write SetRepeatCount;
    property Values[const AThreadId: Integer; const AStackFrame: Integer]: TWatchValue
             read GetValue;
  end;
  TWatchClass = class of TWatch;

  { TWatches }

  TWatches = class(TCollection)
  protected
    function GetItemBase(const AnIndex: Integer): TWatch;
    procedure SetItemBase(const AnIndex: Integer; const AValue: TWatch);
    function WatchClass: TWatchClass; virtual;
  public
    constructor Create;
    procedure ClearValues;
    function Find(const AExpression: String): TWatch;
    property Items[const AnIndex: Integer]: TWatch read GetItemBase write SetItemBase; default;
  end;

  { TWatchesSupplier }

  TWatchesSupplier = class(TDebuggerDataSupplier)
  private
    function GetCurrentWatches: TWatches;
    function GetMonitor: TWatchesMonitor;
    procedure SetMonitor(AValue: TWatchesMonitor);
  protected
    procedure DoStateChange(const AOldState: TDBGState); override; // workaround for state changes during TWatchValue.GetValue
    procedure InternalRequestData(AWatchValue: TWatchValue); virtual;
  public
    constructor Create(const ADebugger: TDebuggerIntf);
    procedure RequestData(AWatchValue: TWatchValue);
    property CurrentWatches: TWatches read GetCurrentWatches;
    property Monitor: TWatchesMonitor read GetMonitor write SetMonitor;
  end;

  { TWatchesMonitor }

  TWatchesMonitor = class(TDebuggerDataMonitor)
  private
    FWatches: TWatches;
    function GetSupplier: TWatchesSupplier;
    procedure SetSupplier(AValue: TWatchesSupplier);
  protected
    function CreateWatches: TWatches; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    property Watches: TWatches read FWatches;
    property Supplier: TWatchesSupplier read GetSupplier write SetSupplier;
  end;

{%endregion   ^^^^^  Watches  ^^^^^   }

{%region Locals ***************************************************************
 ******************************************************************************
 **                                                                          **
 **   L O C A L S                                                            **
 **                                                                          **
 ******************************************************************************
 ******************************************************************************}

    // TODO: a more watch-like value object
    TLocalsMonitor = class;

   { TLocalsValue }

   TLocalsValue = class(TDbgEntityValue)
   private
     FName: String;
     FValue: String;
   protected
     procedure DoAssign(AnOther: TDbgEntityValue); override;
   public
     property Name: String read FName;
     property Value: String read FValue;
   end;

 { TLocals }

  TLocals = class(TDbgEntityValuesList)
  private
    function GetEntry(AnIndex: Integer): TLocalsValue;
    function GetName(const AnIndex: Integer): String;
    function GetValue(const AnIndex: Integer): String;
  protected
    function CreateEntry: TDbgEntityValue; override;
  public
    procedure Add(const AName, AValue: String);
    procedure SetDataValidity({%H-}AValidity: TDebuggerDataState); virtual;
  public
    function Count: Integer;reintroduce; virtual;
    property Entries[AnIndex: Integer]: TLocalsValue read GetEntry;
    property Names[const AnIndex: Integer]: String read GetName;
    property Values[const AnIndex: Integer]: String read GetValue;
  end;

  { TLocalsList }

  TLocalsList = class(TDbgEntitiesThreadStackList)
  private
    function GetEntry(AThreadId, AStackFrame: Integer): TLocals;
    function GetEntryByIdx(AnIndex: Integer): TLocals;
  protected
    //function CreateEntry(AThreadId, AStackFrame: Integer): TDbgEntityValuesList; override;
  public
    property EntriesByIdx[AnIndex: Integer]: TLocals read GetEntryByIdx;
    property Entries[AThreadId, AStackFrame: Integer]: TLocals read GetEntry; default;
  end;

  { TLocalsSupplier }

  TLocalsSupplier = class(TDebuggerDataSupplier)
  private
    function GetCurrentLocalsList: TLocalsList;
    function GetMonitor: TLocalsMonitor;
    procedure SetMonitor(AValue: TLocalsMonitor);
  protected
  public
    procedure RequestData(ALocals: TLocals); virtual;
    property  CurrentLocalsList: TLocalsList read GetCurrentLocalsList;
    property  Monitor: TLocalsMonitor read GetMonitor write SetMonitor;
  end;

  { TLocalsMonitor }

  TLocalsMonitor = class(TDebuggerDataMonitor)
  private
    FLocalsList: TLocalsList;
    function GetSupplier: TLocalsSupplier;
    procedure SetSupplier(AValue: TLocalsSupplier);
  protected
    function CreateLocalsList: TLocalsList; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    property LocalsList: TLocalsList read FLocalsList;
    property Supplier: TLocalsSupplier read GetSupplier write SetSupplier;
  end;

{%endregion   ^^^^^  Locals  ^^^^^   }

{%region Line Info ************************************************************
 ******************************************************************************
 **                                                                          **
 **   L I N E   I N F O                                                      **
 **                                                                          **
 ******************************************************************************
 ******************************************************************************}

  TIDELineInfoEvent = procedure(const ASender: TObject; const ASource: String) of object;

  { TBaseLineInfo }

  TBaseLineInfo = class(TObject)
  protected
    function GetSource(const {%H-}AnIndex: integer): String; virtual;
  public
    constructor Create;
    function Count: Integer; virtual;
    function GetAddress(const {%H-}AIndex: Integer; const {%H-}ALine: Integer): TDbgPtr; virtual;
    function GetAddress(const ASource: String; const ALine: Integer): TDbgPtr;
    function GetInfo({%H-}AAddress: TDbgPtr; out {%H-}ASource, {%H-}ALine, {%H-}AOffset: Integer): Boolean; virtual;
    function IndexOf(const {%H-}ASource: String): integer; virtual;
    procedure Request(const {%H-}ASource: String); virtual;
    procedure Cancel(const {%H-}ASource: String); virtual;
  public
    property Sources[const AnIndex: Integer]: String read GetSource;
  end;

  { TDBGLineInfo }

  TDBGLineInfo = class(TBaseLineInfo)
  private
    FDebugger: TDebuggerIntf;  // reference to our debugger
    FOnChange: TIDELineInfoEvent;
  protected
    procedure Changed(ASource: String); virtual;
    procedure DoChange(ASource: String);
    procedure DoStateChange(const {%H-}AOldState: TDBGState); virtual;
    property Debugger: TDebuggerIntf read FDebugger write FDebugger;
  public
    constructor Create(const ADebugger: TDebuggerIntf);
    property OnChange: TIDELineInfoEvent read FOnChange write FOnChange;
  end;

{%endregion   ^^^^^  Line Info  ^^^^^   }

{%region Register *************************************************************
 ******************************************************************************
 **                                                                          **
 **   R E G I S T E R S                                                      **
 **                                                                          **
 ******************************************************************************
 ******************************************************************************}

  TRegisterDisplayFormat = (rdDefault, rdHex, rdBinary, rdOctal, rdDecimal, rdRaw);
  TRegisterDisplayFormats = set of TRegisterDisplayFormat;
  TRegistersMonitor = class;

   { TRegisterDisplayValue }

   TRegisterDisplayValue = class // Only created if ddsValid
   private
     FStringValue: String; // default, rdRaw is always in FStringValue
     FNumValue: QWord;
     FSize: Integer;   // 2, 4 or 8 bytes
     FFlags: set of (rdvHasNum); // Calculate numeric values.
     FSupportedDispFormats: TRegisterDisplayFormats;
     function  GetValue(ADispFormat: TRegisterDisplayFormat): String;
   public
     procedure Assign(AnOther: TRegisterDisplayValue);
     procedure SetAsNum(AValue: QWord; ASize: Integer);
     procedure SetAsText(AValue: String);
     procedure AddFormats(AFormats: TRegisterDisplayFormats);
     property SupportedDispFormats: TRegisterDisplayFormats read FSupportedDispFormats;
     property Value[ADispFormat: TRegisterDisplayFormat]: String read GetValue;
   end;

   { TRegisterValue }

   TRegisterValue = class(TDbgEntityValue)
   private
     FDataValidity: TDebuggerDataState;
     FDisplayFormat: TRegisterDisplayFormat;
     FModified: Boolean;
     FName: String;
     FValues: Array of TRegisterDisplayValue;
     function GetHasValue: Boolean;
     function GetHasValueFormat(ADispFormat: TRegisterDisplayFormat): Boolean;
     function GetValue: String;
     function GetValueObj: TRegisterDisplayValue;
     function GetValueObjFormat(ADispFormat: TRegisterDisplayFormat): TRegisterDisplayValue;
     procedure SetDisplayFormat(AValue: TRegisterDisplayFormat);
     procedure SetValue(AValue: String);
     function GetValueObject(ACreateNew: Boolean = False): TRegisterDisplayValue;
     function GetValueObject(ADispFormat: TRegisterDisplayFormat; ACreateNew: Boolean = False): TRegisterDisplayValue;
     procedure SetDataValidity(AValidity: TDebuggerDataState);
     procedure ClearDispValues;
   protected
     procedure DoAssign(AnOther: TDbgEntityValue); override;
     procedure DoDataValidityChanged({%H-}AnOldValidity: TDebuggerDataState); virtual;
     procedure DoDisplayFormatChanged({%H-}AnOldFormat: TRegisterDisplayFormat); virtual;
     procedure DoValueNotEvaluated; virtual;
   public
     destructor Destroy; override;
     property Name: String read FName;
     property Value: String read GetValue write SetValue;
     property DisplayFormat: TRegisterDisplayFormat read FDisplayFormat write SetDisplayFormat;
     property Modified: Boolean read FModified write FModified;
     property DataValidity: TDebuggerDataState read FDataValidity write SetDataValidity;
     property ValueObj: TRegisterDisplayValue read GetValueObj; // Will create the object for current DispFormat. Only use for setting data.
     property HasValue: Boolean read GetHasValue;
     property ValueObjFormat[ADispFormat: TRegisterDisplayFormat]: TRegisterDisplayValue read GetValueObjFormat; // Will create the object for current DispFormat. Only use for setting data.
     property HasValueFormat[ADispFormat: TRegisterDisplayFormat]: Boolean read GetHasValueFormat;
   end;

  { TRegisters }

  TRegisters = class(TDbgEntityValuesList)
  private
    FDataValidity: TDebuggerDataState;
    function GetEntry(AnIndex: Integer): TRegisterValue;
    function GetEntryByName(const AName: String): TRegisterValue;
    procedure SetDataValidity(AValue: TDebuggerDataState);
  protected
    function CreateEntry: TDbgEntityValue; override;
     procedure DoDataValidityChanged({%H-}AnOldValidity: TDebuggerDataState); virtual;
  public
    function Count: Integer; reintroduce; virtual;
    property Entries[AnIndex: Integer]: TRegisterValue read GetEntry; default;
    property EntriesByName[const AName: String]: TRegisterValue read GetEntryByName; // autocreate
    property DataValidity: TDebuggerDataState read FDataValidity write SetDataValidity;
  end;

  { TRegistersList }

  TRegistersList = class(TDbgEntitiesThreadStackList)
  private
    function GetEntry(AThreadId, AStackFrame: Integer): TRegisters;
    function GetEntryByIdx(AnIndex: Integer): TRegisters;
  protected
  public
    property EntriesByIdx[AnIndex: Integer]: TRegisters read GetEntryByIdx;
    property Entries[AThreadId, AStackFrame: Integer]: TRegisters read GetEntry; default;
  end;

  { TRegisterSupplier }

  TRegisterSupplier = class(TDebuggerDataSupplier)
  private
    function GetCurrentRegistersList: TRegistersList;
    function GetMonitor: TRegistersMonitor;
    procedure SetMonitor(AValue: TRegistersMonitor);
  protected
  public
    procedure RequestData(ARegisters: TRegisters); virtual;
    property  CurrentRegistersList: TRegistersList read GetCurrentRegistersList;
    property  Monitor: TRegistersMonitor read GetMonitor write SetMonitor;
  end;

  { TRegistersMonitor }

  TRegistersMonitor = class(TDebuggerDataMonitor)
  private
    FRegistersList: TRegistersList;
    function GetSupplier: TRegisterSupplier;
    procedure SetSupplier(AValue: TRegisterSupplier);
  protected
    function CreateRegistersList: TRegistersList; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    property RegistersList: TRegistersList read FRegistersList;
    property Supplier: TRegisterSupplier read GetSupplier write SetSupplier;
  end;

{%endregion   ^^^^^  Register  ^^^^^   }

{%region Callstack ************************************************************
 ******************************************************************************
 **                                                                          **
 **   C A L L S T A C K                                                      **
 **                                                                          **
 ******************************************************************************
 ******************************************************************************
 * The entries for the callstack are created on demand. This way when the     *
 * first entry is needed, it isn't required to create the whole stack         *
 *                                                                            *
 * TCallStackEntry needs to stay a readonly object so its data can be shared  *
 ******************************************************************************}

  TCallStackMonitor = class;

  { TCallStackEntryBase }

  TCallStackEntry = class(TObject)
  private
    FValidity: TDebuggerDataState;
    FIndex: Integer;
    FAddress: TDbgPtr;
    FFunctionName: String;
    FLine: Integer;
    FArguments: TStrings;
  protected
    //// for use in TThreadEntry ONLY
    //function GetThreadId: Integer; virtual; abstract;
    //function GetThreadName: String; virtual; abstract;
    //function GetThreadState: String; virtual; abstract;
    //procedure SetThreadState(AValue: String); virtual; abstract;
    function GetArgumentCount: Integer;
    function GetArgumentName(const AnIndex: Integer): String;
    function GetArgumentValue(const AnIndex: Integer): String;
  protected
    property Arguments: TStrings read FArguments;
    function GetFunctionName: String; virtual;
    function GetSource: String; virtual;
    function GetValidity: TDebuggerDataState; virtual;
    procedure SetValidity(AValue: TDebuggerDataState); virtual;
    procedure InitFields(const AIndex:Integer; const AnAddress: TDbgPtr;
                         const AnArguments: TStrings; const AFunctionName: String;
                         const ALine: Integer; AValidity: TDebuggerDataState);
  public
    constructor Create;
    function CreateCopy: TCallStackEntry; virtual;
    destructor Destroy; override;
    procedure Assign(AnOther: TCallStackEntry); virtual;
    procedure Init(const AnAddress: TDbgPtr;
                   const AnArguments: TStrings; const AFunctionName: String;
                   const {%H-}AUnitName, {%H-}AClassName, {%H-}AProcName, {%H-}AFunctionArgs: String;
                   const ALine: Integer; AState: TDebuggerDataState = ddsValid); virtual;
    procedure Init(const AnAddress: TDbgPtr;
                   const AnArguments: TStrings; const AFunctionName: String;
                   const {%H-}FileName, {%H-}FullName: String;
                   const ALine: Integer; AState: TDebuggerDataState = ddsValid); virtual;
    procedure ClearLocation; virtual; // TODO need a way to call Changed on TCallStack or TThreads // corrently done in SetThreadState
    function GetFunctionWithArg: String;
    //function IsCurrent: Boolean;
    //procedure MakeCurrent;
    property Address: TDbgPtr read FAddress;
    property ArgumentCount: Integer read GetArgumentCount;
    property ArgumentNames[const AnIndex: Integer]: String read GetArgumentName;
    property ArgumentValues[const AnIndex: Integer]: String read GetArgumentValue;
    property FunctionName: String read FFunctionName;
    property Index: Integer read FIndex;
    property Line: Integer read FLine;
    property Source: String read GetSource;
    property Validity: TDebuggerDataState read GetValidity write SetValidity;
  public
    //// for use in TThreadEntry ONLY
    //property ThreadId: Integer read GetThreadId;
    //property ThreadName: String read GetThreadName;
    //property ThreadState: String read GetThreadState write SetThreadState;
  end;

  { TCallStackBase }

  TCallStackBase = class(TFreeNotifyingObject)
  protected
    FCurrent: Integer;
    FThreadId: Integer;
    function GetNewCurrentIndex: Integer; virtual;
    function GetEntryBase(AIndex: Integer): TCallStackEntry; virtual; abstract;
    function GetCount: Integer; virtual;
    procedure SetCount(AValue: Integer); virtual; abstract;
    function GetCurrent: Integer; virtual;
    procedure SetCurrent(AValue: Integer); virtual;
    function GetHighestUnknown: Integer; virtual;
    function GetLowestUnknown: Integer; virtual;
    function GetRawEntries: TMap; virtual; abstract;
  public
    constructor Create;
    function CreateCopy: TCallStackBase; virtual;
    procedure Assign(AnOther: TCallStackBase); virtual;

    procedure PrepareRange({%H-}AIndex, {%H-}ACount: Integer); virtual; abstract;
    procedure DoEntriesCreated; virtual; abstract;
    procedure DoEntriesUpdated; virtual; abstract;
    procedure SetCountValidity({%H-}AValidity: TDebuggerDataState); virtual;
    procedure SetHasAtLeastCountInfo({%H-}AValidity: TDebuggerDataState; {%H-}AMinCount: Integer = -1); virtual;
    procedure SetCurrentValidity({%H-}AValidity: TDebuggerDataState); virtual;
    function CountLimited(ALimit: Integer): Integer; virtual; abstract;
    property Count: Integer read GetCount write SetCount;
    property CurrentIndex: Integer read GetCurrent write SetCurrent;
    property Entries[AIndex: Integer]: TCallStackEntry read GetEntryBase;
    property ThreadId: Integer read FThreadId write FThreadId;
    property NewCurrentIndex: Integer read GetNewCurrentIndex;

    property RawEntries: TMap read GetRawEntries;
    property LowestUnknown: Integer read GetLowestUnknown;
    property HighestUnknown: Integer read GetHighestUnknown;
  end;

  { TCallStackListBase }

  TCallStackList = class
  private
    FList: TList;
    function GetEntry(const AIndex: Integer): TCallStackBase;
    function GetEntryForThread(const AThreadId: Integer): TCallStackBase;
  protected
    function NewEntryForThread(const {%H-}AThreadId: Integer): TCallStackBase; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(AnOther: TCallStackList); virtual;
    procedure Add(ACallStack: TCallStackBase);
    procedure Clear; virtual;
    function Count: Integer; virtual;    // Count of already requested CallStacks (via ThreadId)
    property Entries[const AIndex: Integer]: TCallStackBase read GetEntry; default;
    property EntriesForThreads[const AThreadId: Integer]: TCallStackBase read GetEntryForThread;
  end;

  { TCallStackSupplier }

  TCallStackSupplier = class(TDebuggerDataSupplier)
  private
    function GetCurrentCallStackList: TCallStackList;
    function GetMonitor: TCallStackMonitor;
    procedure SetMonitor(AValue: TCallStackMonitor);
  protected
    //procedure CurrentChanged;
    procedure Changed;
  public
    procedure RequestCount(ACallstack: TCallStackBase); virtual;
    procedure RequestAtLeastCount(ACallstack: TCallStackBase; {%H-}ARequiredMinCount: Integer); virtual;
    procedure RequestCurrent(ACallstack: TCallStackBase); virtual;
    procedure RequestEntries(ACallstack: TCallStackBase); virtual;
    procedure UpdateCurrentIndex; virtual;
    property CurrentCallStackList: TCallStackList read GetCurrentCallStackList;
    property Monitor: TCallStackMonitor read GetMonitor write SetMonitor;
  end;

  { TCallStackMonitor }

  TCallStackMonitor = class(TDebuggerDataMonitor)
  private
    FCallStackList: TCallStackList;
    function GetSupplier: TCallStackSupplier;
    procedure SetSupplier(AValue: TCallStackSupplier);
  protected
    function CreateCallStackList: TCallStackList; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    property CallStackList: TCallStackList read FCallStackList;
    property Supplier: TCallStackSupplier read GetSupplier write SetSupplier;
  end;

{%endregion   ^^^^^  Callstack  ^^^^^   }

{%region      *****  Disassembler  *****   }
(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   D I S A S S E M B L E R                                                **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

  PDisassemblerEntry = ^TDisassemblerEntry;
  TDisassemblerEntry = record
    Addr: TDbgPtr;                   // Address
    Dump: String;                    // Raw Data
    Statement: String;               // Asm
    FuncName: String;                // Function, if avail
    Offset: Integer;                 // Byte-Offest in Fonction
    SrcFileName: String;             // SrcFile if avail
    SrcFileLine: Integer;            // Line in SrcFile
    SrcStatementIndex: SmallInt;     // Index of Statement, within list of Stmnt of the same SrcLine
    SrcStatementCount: SmallInt;     // Count of Statements for this SrcLine
  end;

  { TBaseDisassembler }

  TBaseDisassembler = class(TObject)
  private
    FBaseAddr: TDbgPtr;
    FCountAfter: Integer;
    FCountBefore: Integer;
    FChangedLockCount: Integer;
    FIsChanged: Boolean;
    function GetEntryPtr(AIndex: Integer): PDisassemblerEntry;
    procedure IndexError(AIndex: Integer);
    function GetEntry(AIndex: Integer): TDisassemblerEntry;
  protected
    function  InternalGetEntry({%H-}AIndex: Integer): TDisassemblerEntry; virtual;
    function  InternalGetEntryPtr({%H-}AIndex: Integer): PDisassemblerEntry; virtual;
    procedure DoChanged; virtual;
    procedure Changed;
    procedure LockChanged;
    procedure UnlockChanged;
    procedure InternalIncreaseCountBefore(ACount: Integer);
    procedure InternalIncreaseCountAfter(ACount: Integer);
    procedure SetCountBefore(ACount: Integer);
    procedure SetCountAfter(ACount: Integer);
    procedure SetBaseAddr(AnAddr: TDbgPtr);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; virtual;
    // Returns "True", if the range is valid, if not a ChangeNotification will be triggered later
    function PrepareRange({%H-}AnAddr: TDbgPtr; {%H-}ALinesBefore, {%H-}ALinesAfter: Integer): Boolean; virtual;
    property BaseAddr: TDbgPtr read FBaseAddr;
    property CountAfter: Integer read FCountAfter;
    property CountBefore: Integer read FCountBefore;
    property Entries[AIndex: Integer]: TDisassemblerEntry read GetEntry;
    property EntriesPtr[Index: Integer]: PDisassemblerEntry read GetEntryPtr;
  end;

  { TDBGDisassemblerEntryRange }

  TDBGDisassemblerEntryRange = class
  private
    FCount: Integer;
    FEntries: array of TDisassemblerEntry;
    FLastEntryEndAddr: TDBGPtr;
    FRangeEndAddr: TDBGPtr;
    FRangeStartAddr: TDBGPtr;
    function GetCapacity: Integer;
    function GetEntry(Index: Integer): TDisassemblerEntry;
    function GetEntryPtr(Index: Integer): PDisassemblerEntry;
    procedure SetCapacity(const AValue: Integer);
    procedure SetCount(const AValue: Integer);
  public
    procedure Clear;
    function Append(const AnEntryPtr: PDisassemblerEntry): Integer;
    procedure Merge(const AnotherRange: TDBGDisassemblerEntryRange);
    // Actual addresses on the ranges
    function FirstAddr: TDbgPtr;
    function LastAddr: TDbgPtr;
    function ContainsAddr(const AnAddr: TDbgPtr; IncludeNextAddr: Boolean = False): Boolean;
    function IndexOfAddr(const AnAddr: TDbgPtr): Integer;
    function IndexOfAddrWithOffs(const AnAddr: TDbgPtr): Integer;
    function IndexOfAddrWithOffs(const AnAddr: TDbgPtr; out AOffs: Integer): Integer;
    property Count: Integer read FCount write SetCount;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Entries[Index: Integer]: TDisassemblerEntry read GetEntry;
    property EntriesPtr[Index: Integer]: PDisassemblerEntry read GetEntryPtr;
    // The first address behind last entry
    property LastEntryEndAddr: TDBGPtr read FLastEntryEndAddr write FLastEntryEndAddr;
    // The addresses for which the range was requested
    // The range may bo more, than the entries, if there a gaps that cannot be retrieved.
    property RangeStartAddr: TDBGPtr read FRangeStartAddr write FRangeStartAddr;
    property RangeEndAddr: TDBGPtr read FRangeEndAddr write FRangeEndAddr;
  end;

  { TDBGDisassemblerEntryMap }

  TDBGDisassemblerEntryMapMergeEvent
    = procedure(MergeReceiver, MergeGiver: TDBGDisassemblerEntryRange) of object;

  { TDBGDisassemblerEntryMapIterator }
  TDBGDisassemblerEntryMap = class;

  TDBGDisassemblerEntryMapIterator = class(TMapIterator)
  public
    function GetRangeForAddr(AnAddr: TDbgPtr; IncludeNextAddr: Boolean = False): TDBGDisassemblerEntryRange;
    function NextRange: TDBGDisassemblerEntryRange;
    function PreviousRange: TDBGDisassemblerEntryRange;
  end;

  TDBGDisassemblerEntryMap = class(TMap)
  private
    FIterator: TDBGDisassemblerEntryMapIterator;
    FOnDelete: TNotifyEvent;
    FOnMerge: TDBGDisassemblerEntryMapMergeEvent;
    FFreeItemLock: Boolean;
  protected
    procedure ReleaseData(ADataPtr: Pointer); override;
  public
    constructor Create(AIdType: TMapIdType; ADataSize: Cardinal);
    destructor Destroy; override;
    // AddRange, may destroy the object
    procedure AddRange(const ARange: TDBGDisassemblerEntryRange); // Arange may be freed
    function GetRangeForAddr(AnAddr: TDbgPtr; IncludeNextAddr: Boolean = False): TDBGDisassemblerEntryRange;
    property OnDelete: TNotifyEvent read FOnDelete write FOnDelete;
    property OnMerge: TDBGDisassemblerEntryMapMergeEvent
             read FOnMerge write FOnMerge;
  end;

  { TDBGDisassembler }

  TDBGDisassembler = class(TBaseDisassembler)
  private
    FDebugger: TDebuggerIntf;
    FOnChange: TNotifyEvent;

    FEntryRanges: TDBGDisassemblerEntryMap;
    FCurrentRange: TDBGDisassemblerEntryRange;
    procedure EntryRangesOnDelete(Sender: TObject);
    procedure EntryRangesOnMerge(MergeReceiver, MergeGiver: TDBGDisassemblerEntryRange);
    function FindRange(AnAddr: TDbgPtr; ALinesBefore, ALinesAfter: Integer): Boolean;
  protected
    procedure DoChanged; override;
    procedure DoStateChange(const AOldState: TDBGState); virtual;
    function  InternalGetEntry(AIndex: Integer): TDisassemblerEntry; override;
    function  InternalGetEntryPtr(AIndex: Integer): PDisassemblerEntry; override;
    // PrepareEntries returns True, if it already added some entries
    function  PrepareEntries({%H-}AnAddr: TDbgPtr; {%H-}ALinesBefore, {%H-}ALinesAfter: Integer): boolean; virtual;
    function  HandleRangeWithInvalidAddr(ARange: TDBGDisassemblerEntryRange;{%H-}AnAddr:
                 TDbgPtr; var {%H-}ALinesBefore, {%H-}ALinesAfter: Integer): boolean; virtual;
    property Debugger: TDebuggerIntf read FDebugger write FDebugger;
    property EntryRanges: TDBGDisassemblerEntryMap read FEntryRanges;
  public
    constructor Create(const ADebugger: TDebuggerIntf);
    destructor Destroy; override;
    procedure Clear; override;
    function PrepareRange(AnAddr: TDbgPtr; ALinesBefore, ALinesAfter: Integer): Boolean; override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

{%endregion   ^^^^^  Disassembler  ^^^^^   }

{%region Threads **************************************************************
 ******************************************************************************
 **                                                                          **
 **   T H R E A D S                                                          **
 **                                                                          **
 ******************************************************************************
 ******************************************************************************}

 TThreadsMonitor = class;

  { TThreadEntry }

  TThreadEntry = class(TObject)
  private
    FTopFrame: TCallStackEntry;
  protected
    FThreadId: Integer;
    FThreadName: String;
    FThreadState: String;
    procedure SetThreadState(AValue: String); virtual;
    function CreateStackEntry: TCallStackEntry; virtual;
  public
    constructor Create;
    constructor Create(const AnAdress: TDbgPtr;
                       const AnArguments: TStrings; const AFunctionName: String;
                       const FileName, FullName: String;
                       const ALine: Integer;
                       const AThreadId: Integer; const AThreadName: String;
                       const AThreadState: String;
                       AState: TDebuggerDataState = ddsValid);
    function CreateCopy: TThreadEntry; virtual;
    destructor Destroy; override;
    procedure Assign(AnOther: TThreadEntry); virtual;
  published
    property ThreadId: Integer read FThreadId;
    property ThreadName: String read FThreadName;
    property ThreadState: String read FThreadState write SetThreadState;
    property TopFrame: TCallStackEntry read FTopFrame;
 end;

  { TThreadsBase }

  TThreads = class(TObject)
  private
    FCurrentThreadId: Integer;
    FList: TList;
    function GetEntry(const AnIndex: Integer): TThreadEntry;
    function GetEntryById(const AnID: Integer): TThreadEntry;
  protected
    procedure SetCurrentThreadId(AValue: Integer); virtual;
    property List: TList read FList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(AnOther: TThreads); virtual;
    function Count: Integer; virtual;
    procedure Clear; virtual;
    procedure Add(AThread: TThreadEntry); virtual;
    procedure Remove(AThread: TThreadEntry); virtual;
    function  CreateEntry(const AnAdress: TDbgPtr;
                       const AnArguments: TStrings; const AFunctionName: String;
                       const FileName, FullName: String;
                       const ALine: Integer;
                       const AThreadId: Integer; const AThreadName: String;
                       const AThreadState: String;
                       AState: TDebuggerDataState = ddsValid): TThreadEntry; virtual;
    procedure SetValidity({%H-}AValidity: TDebuggerDataState); virtual;
    property Entries[const AnIndex: Integer]: TThreadEntry read GetEntry; default;
    property EntryById[const AnID: Integer]: TThreadEntry read GetEntryById;
    property CurrentThreadId: Integer read FCurrentThreadId write SetCurrentThreadId;
  end;

  { TThreadsSupplier }

  TThreadsSupplier = class(TDebuggerDataSupplier)
  private
    function GetCurrentThreads: TThreads;
    function GetMonitor: TThreadsMonitor;
    procedure SetMonitor(AValue: TThreadsMonitor);
  protected
    procedure DoStateChange(const AOldState: TDBGState); override;
    procedure DoStateLeavePauseClean; override;
    procedure DoCleanAfterPause; virtual;
  public
    procedure RequestMasterData; virtual;
    procedure ChangeCurrentThread({%H-}ANewId: Integer); virtual;
    procedure Changed; // TODO: needed because entries can not notify the monitor
    property  CurrentThreads: TThreads read GetCurrentThreads;
    property  Monitor: TThreadsMonitor read GetMonitor write SetMonitor;
  end;

  { TThreadsMonitor }

  TThreadsMonitor = class(TDebuggerDataMonitor)
  private
    FThreads: TThreads;
    function GetSupplier: TThreadsSupplier;
    procedure SetSupplier(AValue: TThreadsSupplier);
  protected
    function CreateThreads: TThreads; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    property Threads: TThreads read FThreads;
    property Supplier: TThreadsSupplier read GetSupplier write SetSupplier;
  end;

{%endregion   ^^^^^  Threads  ^^^^^   }

{%region Signals / Exceptions *************************************************}
(******************************************************************************)
(**                                                                          **)
(**   S I G N A L S  and  E X C E P T I O N S                                **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

  { TBaseSignal }

  TBaseSignal = class(TDelayedUdateItem)
  private
    FHandledByDebugger: Boolean;
    FID: Integer;
    FName: String;
    FResumeHandled: Boolean;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    procedure SetHandledByDebugger(const AValue: Boolean); virtual;
    procedure SetID(const AValue: Integer); virtual;
    procedure SetName(const AValue: String); virtual;
    procedure SetResumeHandled(const AValue: Boolean); virtual;
  public
    constructor Create(ACollection: TCollection); override;
    property ID: Integer read FID write SetID;
    property Name: String read FName write SetName;
    property HandledByDebugger: Boolean read FHandledByDebugger write SetHandledByDebugger;
    property ResumeHandled: Boolean read FResumeHandled write SetResumeHandled;
  end;
  TBaseSignalClass = class of TBaseSignal;

  { TDBGSignal }

  TDBGSignal = class(TBaseSignal)
  private
    function GetDebugger: TDebuggerIntf;
  protected
    property Debugger: TDebuggerIntf read GetDebugger;
  public
  end;
  TDBGSignalClass = class of TDBGSignal;

  { TBaseSignals }
  TBaseSignals = class(TCollection)
  private
  protected
  public
    constructor Create(const AItemClass: TBaseSignalClass);
    procedure Reset; virtual;
    function Add(const AName: String; AID: Integer): TBaseSignal;
    function Find(const AName: String): TBaseSignal;
  end;

  { TDBGSignals }

  TDBGSignals = class(TBaseSignals)
  private
    FDebugger: TDebuggerIntf;  // reference to our debugger
    function GetItem(const AIndex: Integer): TDBGSignal;
    procedure SetItem(const AIndex: Integer; const AValue: TDBGSignal);
  protected
  public
    constructor Create(const ADebugger: TDebuggerIntf;
                       const ASignalClass: TDBGSignalClass);
    function Add(const AName: String; AID: Integer): TDBGSignal;
    function Find(const AName: String): TDBGSignal;
  public
    property Items[const AIndex: Integer]: TDBGSignal read GetItem
                                                      write SetItem; default;
  end;



  { TBaseException }
  TBaseException = class(TDelayedUdateItem)
  private
    procedure SetEnabled(AValue: Boolean);
  protected
    FEnabled: Boolean;
    FName: String;
    procedure AssignTo(Dest: TPersistent); override;
    procedure SetName(const AValue: String); virtual;
  public
    constructor Create(ACollection: TCollection); override;
  public
    property Name: String read FName write SetName;
    property Enabled: Boolean read FEnabled write SetEnabled; // ignored if enabled
  end;
  TBaseExceptionClass = class of TBaseException;

  { TDBGException }
  TDBGException = class(TBaseException)
  private
  protected
  public
  end;
  TDBGExceptionClass = class of TDBGException;

  { TBaseExceptions }
  TBaseExceptions = class(TCollection)
  private
    function GetItem(const AIndex: Integer): TBaseException;
    procedure SetItem(const AIndex: Integer; AValue: TBaseException);
  protected
    FIgnoreAll: Boolean;
    procedure AssignTo(Dest: TPersistent); override;
    procedure ClearExceptions; virtual;
    procedure SetIgnoreAll(const AValue: Boolean); virtual;
  public
    constructor Create(const AItemClass: TBaseExceptionClass);
    destructor Destroy; override;
    procedure Reset; virtual;
    function Add(const AName: String): TBaseException;
    function Find(const AName: String): TBaseException;
    property IgnoreAll: Boolean read FIgnoreAll write SetIgnoreAll;
    property Items[const AIndex: Integer]: TBaseException read GetItem
                                                        write SetItem; default;
  end;


{%endregion   ^^^^^  Signals / Exceptions  ^^^^^   }

(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   D E B U G G E R                                                        **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

  TDBGEventCategory = (
    ecBreakpoint, // Breakpoint hit
    ecProcess,    // Process start, process stop
    ecThread,     // Thread creation, destruction, start, etc.
    ecModule,     // Library load and unload
    ecOutput,     // DebugOutput calls
    ecWindows,    // Windows events
    ecDebugger);  // debugger errors and warnings
  TDBGEventCategories = set of TDBGEventCategory;

  TDBGEventType = (
    etDefault,
    // ecBreakpoint category
    etBreakpointEvaluation,
    etBreakpointHit,
    etBreakpointMessage,
    etBreakpointStackDump,
    etExceptionRaised,
    // ecModule category
    etModuleLoad,
    etModuleUnload,
    // ecOutput category
    etOutputDebugString,
    // ecProcess category
    etProcessExit,
    etProcessStart,
    // ecThread category
    etThreadExit,
    etThreadStart,
    // ecWindows category
    etWindowsMessagePosted,
    etWindowsMessageSent
  );

  TDBGFeedbackType = (ftInformation, ftWarning, ftError);
  TDBGFeedbackResult = (frOk, frStop);
  TDBGFeedbackResults = set of TDBGFeedbackResult;

  TDBGEventNotify = procedure(Sender: TObject;
                              const ACategory: TDBGEventCategory;
                              const AEventType: TDBGEventType;
                              const AText: String) of object;

  TDebuggerStateChangedEvent = procedure(ADebugger: TDebuggerIntf;
                                         AOldState: TDBGState) of object;
  TDebuggerBreakPointHitEvent = procedure(ADebugger: TDebuggerIntf; ABreakPoint: TBaseBreakPoint;
                                          var ACanContinue: Boolean) of object;
  TDBGOutputEvent = procedure(Sender: TObject; const AText: String) of object;
  TDBGCurrentLineEvent = procedure(Sender: TObject;
                                   const ALocation: TDBGLocationRec) of object;
  TDBGExceptionEvent = procedure(Sender: TObject; const AExceptionType: TDBGExceptionType;
                                 const AExceptionClass: String;
                                 const AExceptionLocation: TDBGLocationRec;
                                 const AExceptionText: String;
                                 out AContinue: Boolean) of object;

  TDBGFeedbackEvent = function(Sender: TObject; const AText, AInfo: String;
                               AType: TDBGFeedbackType; AButtons: TDBGFeedbackResults
                              ): TDBGFeedbackResult of object;


  TDebuggerNotifyReason = (dnrDestroy);

  { TDebuggerProperties }

  TDebuggerProperties = class(TPersistent)
  private
  public
    constructor Create; virtual;
    procedure Assign({%H-}Source: TPersistent); override;
  published
  end;
  TDebuggerPropertiesClass= class of TDebuggerProperties;


  { TDebuggerIntf }

  TDebuggerIntf = class
  private
    FArguments: String;
    FBreakPoints: TDBGBreakPoints;
    FDebuggerEnvironment: TStrings;
    FCurEnvironment: TStrings;
    FDisassembler: TDBGDisassembler;
    FEnvironment: TStrings;
    FErrorStateInfo: String;
    FErrorStateMessage: String;
    FExceptions: TBaseExceptions;
    FExitCode: Integer;
    FExternalDebugger: String;
    FFileName: String;
    FLocals: TLocalsSupplier;
    FLineInfo: TDBGLineInfo;
    //FUnitInfoProvider, FInternalUnitInfoProvider: TDebuggerUnitInfoProvider;
    FOnBeforeState: TDebuggerStateChangedEvent;
    FOnConsoleOutput: TDBGOutputEvent;
    FOnFeedback: TDBGFeedbackEvent;
    FOnIdle: TNotifyEvent;
    FRegisters: TRegisterSupplier;
    FShowConsole: Boolean;
    FSignals: TDBGSignals;
    FState: TDBGState;
    FCallStack: TCallStackSupplier;
    FWatches: TWatchesSupplier;
    FThreads: TThreadsSupplier;
    FOnCurrent: TDBGCurrentLineEvent;
    FOnException: TDBGExceptionEvent;
    FOnOutput: TDBGOutputEvent;
    FOnDbgOutput: TDBGOutputEvent;
    FOnDbgEvent: TDBGEventNotify;
    FOnState: TDebuggerStateChangedEvent;
    FOnBreakPointHit: TDebuggerBreakPointHitEvent;
    FWorkingDir: String;
    FDestroyNotificationList: array [TDebuggerNotifyReason] of TMethodList;
    procedure DebuggerEnvironmentChanged(Sender: TObject);
    procedure EnvironmentChanged(Sender: TObject);
    //function GetUnitInfoProvider: TDebuggerUnitInfoProvider;
    function  GetState: TDBGState;
    function  ReqCmd(const ACommand: TDBGCommand;
                     const AParams: array of const): Boolean;
    procedure SetDebuggerEnvironment (const AValue: TStrings );
    procedure SetEnvironment(const AValue: TStrings);
    procedure SetFileName(const AValue: String);
  protected
    procedure ResetStateToIdle; virtual;
    function  CreateBreakPoints: TDBGBreakPoints; virtual;
    function  CreateLocals: TLocalsSupplier; virtual;
    function  CreateLineInfo: TDBGLineInfo; virtual;
    function  CreateRegisters: TRegisterSupplier; virtual;
    function  CreateCallStack: TCallStackSupplier; virtual;
    function  CreateDisassembler: TDBGDisassembler; virtual;
    function  CreateWatches: TWatchesSupplier; virtual;
    function  CreateThreads: TThreadsSupplier; virtual;
    function  CreateSignals: TDBGSignals; virtual;
    procedure DoCurrent(const ALocation: TDBGLocationRec);
    procedure DoDbgOutput(const AText: String);
    procedure DoDbgEvent(const ACategory: TDBGEventCategory; const AEventType: TDBGEventType; const AText: String);
    procedure DoException(const AExceptionType: TDBGExceptionType;
                          const AExceptionClass: String;
                          const AExceptionLocation: TDBGLocationRec;
                          const AExceptionText: String;
                          out AContinue: Boolean);
    procedure DoOutput(const AText: String);
    procedure DoBreakpointHit(const ABreakPoint: TBaseBreakPoint; var ACanContinue: Boolean);
    procedure DoBeforeState(const OldState: TDBGState); virtual;
    procedure DoState(const OldState: TDBGState); virtual;
    function  ChangeFileName: Boolean; virtual;
    function  GetCommands: TDBGCommands; virtual;
    function  GetSupportedCommands: TDBGCommands; virtual;
    function  GetTargetWidth: Byte; virtual;
    function  GetWaiting: Boolean; virtual;
    function  GetIsIdle: Boolean; virtual;
    function  RequestCommand(const ACommand: TDBGCommand;
                             const AParams: array of const): Boolean;
                             virtual; abstract; // True if succesful
    procedure SetExitCode(const AValue: Integer);
    procedure SetState(const AValue: TDBGState);
    procedure SetErrorState(const AMsg: String; const AInfo: String = '');
    procedure DoRelease; virtual;
  public
    class function Caption: String; virtual;         // The name of the debugger as shown in the debuggeroptions
    class function ExePaths: String; virtual;        // The default locations of the exe
    class function HasExePath: boolean; virtual; deprecated; // use NeedsExePath instead
    class function NeedsExePath: boolean; virtual;        // If the debugger needs to have an exe path
    class function CanExternalDebugSymbolsFile: boolean; virtual; // If the debugger support the -Xg compiler option to store the debug info in an external file

    // debugger properties
    class function CreateProperties: TDebuggerProperties; virtual;         // Creates debuggerproperties
    class function GetProperties: TDebuggerProperties;                     // Get the current properties
    class procedure SetProperties(const AProperties: TDebuggerProperties); // Set the current properties

    (* TODO:
       This method is a workaround for http://bugs.freepascal.org/view.php?id=21834
       See main.pp 12188 function TMainIDE.DoInitProjectRun: TModalResult;
       See debugmanager function TDebugManager.InitDebugger: Boolean;
       Checks could be performed in SetFileName, invalidating debuggerstate
       Errors should also be reported by debugger
    *)
    class function  RequiresLocalExecutable: Boolean; virtual;
  public
    constructor Create(const AExternalDebugger: String); virtual;
    destructor Destroy; override;

    procedure Init; virtual;                         // Initializes the debugger
    procedure Done; virtual;                         // Kills the debugger
    procedure Release;                               // Free/Destroy self
    procedure Run;                                   // Starts / continues debugging
    procedure Pause;                                 // Stops running
    procedure Stop;                                  // quit debugging
    procedure StepOver;
    procedure StepInto;
    procedure StepOverInstr;
    procedure StepIntoInstr;
    procedure StepOut;
    procedure RunTo(const ASource: String; const ALine: Integer);                // Executes til a certain point
    procedure JumpTo(const ASource: String; const ALine: Integer);               // No execute, only set exec point
    procedure Attach(AProcessID: String);
    procedure Detach;
    procedure SendConsoleInput(AText: String);
    function  Evaluate(const AExpression: String; var AResult: String;
                       var ATypeInfo: TDBGType;
                       EvalFlags: TDBGEvaluateFlags = []): Boolean;                     // Evaluates the given expression, returns true if valid
    function GetProcessList({%H-}AList: TRunningProcessInfoList): boolean; virtual;
    function  Modify(const AExpression, AValue: String): Boolean;                // Modifies the given expression, returns true if valid
    function  Disassemble(AAddr: TDbgPtr; ABackward: Boolean; out ANextAddr: TDbgPtr;
                          out ADump, AStatement, AFile: String; out ALine: Integer): Boolean; deprecated;
    function GetLocation: TDBGLocationRec; virtual;
    procedure LockCommandProcessing; virtual;
    procedure UnLockCommandProcessing; virtual;
    function  NeedReset: Boolean; virtual;
    procedure AddNotifyEvent(AReason: TDebuggerNotifyReason; AnEvent: TNotifyEvent);
    procedure RemoveNotifyEvent(AReason: TDebuggerNotifyReason; AnEvent: TNotifyEvent);
  public
    property Arguments: String read FArguments write FArguments;                 // Arguments feed to the program
    property BreakPoints: TDBGBreakPoints read FBreakPoints;                     // list of all breakpoints
    property CallStack: TCallStackSupplier read FCallStack;
    property Disassembler: TDBGDisassembler read FDisassembler;
    property Commands: TDBGCommands read GetCommands;                            // All current available commands of the debugger
    property DebuggerEnvironment: TStrings read FDebuggerEnvironment
                                           write SetDebuggerEnvironment;         // The environment passed to the debugger process
    property Environment: TStrings read FEnvironment write SetEnvironment;       // The environment passed to the debuggee
    property Exceptions: TBaseExceptions read FExceptions write FExceptions;      // A list of exceptions we should ignore
    property ExitCode: Integer read FExitCode;
    property ExternalDebugger: String read FExternalDebugger;                    // The name of the debugger executable
    property FileName: String read FFileName write SetFileName;                  // The name of the exe to be debugged
    property Locals: TLocalsSupplier read FLocals;                                    // list of all localvars etc
    property LineInfo: TDBGLineInfo read FLineInfo;                              // list of all source LineInfo
    property Registers: TRegisterSupplier read FRegisters;                           // list of all registers
    property Signals: TDBGSignals read FSignals;                                 // A list of actions for signals we know
    property ShowConsole: Boolean read FShowConsole write FShowConsole;          // Indicates if the debugger should create a console for the debuggee
    property State: TDBGState read FState;                                       // The current state of the debugger
    property SupportedCommands: TDBGCommands read GetSupportedCommands;          // All available commands of the debugger
    property TargetWidth: Byte read GetTargetWidth;                              // Currently only 32 or 64
    property Waiting: Boolean read GetWaiting;                                   // Set when the debugger is wating for a command to complete
    property Watches: TWatchesSupplier read FWatches;                                 // list of all watches etc
    property Threads: TThreadsSupplier read FThreads;
    property WorkingDir: String read FWorkingDir write FWorkingDir;              // The working dir of the exe being debugged
    property IsIdle: Boolean read GetIsIdle;                                     // Nothing queued
    property ErrorStateMessage: String read FErrorStateMessage;
    property ErrorStateInfo: String read FErrorStateInfo;
    //property UnitInfoProvider: TDebuggerUnitInfoProvider                        // Provided by DebugBoss, to map files to packages or project
    //         read GetUnitInfoProvider write FUnitInfoProvider;
    // Events
    property OnCurrent: TDBGCurrentLineEvent read FOnCurrent write FOnCurrent;   // Passes info about the current line being debugged
    property OnDbgOutput: TDBGOutputEvent read FOnDbgOutput write FOnDbgOutput;  // Passes all debuggeroutput
    property OnDbgEvent: TDBGEventNotify read FOnDbgEvent write FOnDbgEvent;     // Passes recognized debugger events, like library load or unload
    property OnException: TDBGExceptionEvent read FOnException write FOnException;  // Fires when the debugger received an exeption
    property OnOutput: TDBGOutputEvent read FOnOutput write FOnOutput;           // Passes all output of the debugged target
    property OnBeforeState: TDebuggerStateChangedEvent read FOnBeforeState write FOnBeforeState;   // Fires when the current state of the debugger changes
    property OnState: TDebuggerStateChangedEvent read FOnState write FOnState;   // Fires when the current state of the debugger changes
    property OnBreakPointHit: TDebuggerBreakPointHitEvent read FOnBreakPointHit write FOnBreakPointHit;   // Fires when the program is paused at a breakpoint
    property OnConsoleOutput: TDBGOutputEvent read FOnConsoleOutput write FOnConsoleOutput;  // Passes Application Console Output
    property OnFeedback: TDBGFeedbackEvent read FOnFeedback write FOnFeedback;
    property OnIdle: TNotifyEvent read FOnIdle write FOnIdle;                    // Called if all outstanding requests are processed (queue empty)
  end;
  TDebuggerClass = class of TDebuggerIntf;

  TBaseDebugManagerIntf = class(TComponent)
  protected
    function GetDebuggerClass(const AIndex: Integer): TDebuggerClass;
    function FindDebuggerClass(const Astring: String): TDebuggerClass;
  public
    function DebuggerCount: Integer;
  end;

procedure RegisterDebugger(const ADebuggerClass: TDebuggerClass);

function dbgs(AState: TDBGState): String; overload;
function dbgs(ADataState: TDebuggerDataState): String; overload;
function dbgs(AKind: TDBGSymbolKind): String; overload;
function dbgs(AnAttribute: TDBGSymbolAttribute): String; overload;
function dbgs(AnAttributes: TDBGSymbolAttributes): String; overload;
function dbgs(ADisassRange: TDBGDisassemblerEntryRange): String; overload;
function dbgs(ACategory: TDBGEventCategory): String; overload;
function dbgs(AFlag: TDBGEvaluateFlag): String; overload;
function dbgs(AFlags: TDBGEvaluateFlags): String; overload;
function dbgs(AName: TDBGCommand): String; overload;

var
  DbgStateChangeCounter: Integer = 0;  // workaround for state changes during TWatchValue.GetValue

implementation

var
  DBG_STATE, DBG_EVENTS, DBG_STATE_EVENT, DBG_DATA_MONITORS,
  DBG_VERBOSE, DBG_WARNINGS, DBG_DISASSEMBLER: PLazLoggerLogGroup;

const
  COMMANDMAP: array[TDBGState] of TDBGCommands = (
  {dsNone } [],
  {dsIdle } [dcEnvironment],
  {dsStop } [dcRun, dcStepOver, dcStepInto, dcStepOverInstr, dcStepIntoInstr,
             dcAttach, dcBreak, dcWatch, dcEvaluate, dcEnvironment,
             dcSendConsoleInput],
  {dsPause} [dcRun, dcStop, dcStepOver, dcStepInto, dcStepOverInstr, dcStepIntoInstr,
             dcStepOut, dcRunTo, dcJumpto, dcDetach, dcBreak, dcWatch, dcLocal, dcEvaluate, dcModify,
             dcEnvironment, dcSetStackFrame, dcDisassemble, dcSendConsoleInput],
  {dsInternalPause} // same as run, so not really used
            [dcStop, dcBreak, dcWatch, dcEnvironment, dcSendConsoleInput],
  {dsInit } [],
  {dsRun  } [dcPause, dcStop, dcDetach, dcBreak, dcWatch, dcEnvironment, dcSendConsoleInput],
  {dsError} [dcStop],
  {dsDestroying} []
  );

var
  MDebuggerPropertiesList: TStringlist = nil;
  MDebuggerClasses: TStringList;

procedure RegisterDebugger(const ADebuggerClass: TDebuggerClass);
begin
  MDebuggerClasses.AddObject(ADebuggerClass.ClassName, TObject(Pointer(ADebuggerClass)));
end;

procedure DoFinalization;
var
  n: Integer;
begin
  if MDebuggerPropertiesList <> nil
  then begin
    for n := 0 to MDebuggerPropertiesList.Count - 1 do
      MDebuggerPropertiesList.Objects[n].Free;
    FreeAndNil(MDebuggerPropertiesList);
  end;
end;

function dbgs(AState: TDBGState): String; overload;
begin
  Result := '';
  WriteStr(Result, AState);
end;

function dbgs(ADataState: TDebuggerDataState): String;
begin
  writestr(Result{%H-}, ADataState);
end;

function dbgs(AKind: TDBGSymbolKind): String;
begin
  writestr(Result{%H-}, AKind);
end;

function dbgs(AnAttribute: TDBGSymbolAttribute): String;
begin
  writestr(Result{%H-}, AnAttribute);
end;

function dbgs(AnAttributes: TDBGSymbolAttributes): String;
var
  i: TDBGSymbolAttribute;
begin
  Result:='';
  for i := low(TDBGSymbolAttributes) to high(TDBGSymbolAttributes) do
    if i in AnAttributes then begin
      if Result <> '' then Result := Result + ', ';
      Result := Result + dbgs(i);
    end;
  if Result <> '' then Result := '[' + Result + ']';
end;

function dbgs(ACategory: TDBGEventCategory): String;
begin
  writestr(Result{%H-}, ACategory);
end;

function dbgs(AFlag: TDBGEvaluateFlag): String;
begin
  Result := '';
  WriteStr(Result, AFlag);
end;

function dbgs(AFlags: TDBGEvaluateFlags): String;
var
  i: TDBGEvaluateFlag;
begin
  Result:='';
  for i := low(TDBGEvaluateFlags) to high(TDBGEvaluateFlags) do
    if i in AFlags then begin
      if Result <> '' then Result := Result + ', ';
      Result := Result + dbgs(i);
    end;
  Result := '[' + Result + ']';
end;

function dbgs(AName: TDBGCommand): String;
begin
  Result := '';
  WriteStr(Result, AName);
end;

function dbgs(ADisassRange: TDBGDisassemblerEntryRange): String; overload;
var
  fo: Integer;
begin
  if (ADisassRange = nil)
  then begin
    Result := 'Range(nil)'
  end
  else begin
    if (ADisassRange.Count > 0)
    then fo := ADisassRange.EntriesPtr[0]^.Offset
    else fo := 0;
    {$PUSH}{$RANGECHECKS OFF}
    with ADisassRange do
      Result := Format('Range(%u)=[[ Cnt=%d, Capac=%d, [0].Addr=%u, RFirst=%u, [Cnt].Addr=%u, RLast=%u, REnd=%u, FirstOfs=%d ]]',
        [PtrUInt(ADisassRange), Count, Capacity, FirstAddr, RangeStartAddr, LastAddr, RangeEndAddr, LastEntryEndAddr, fo]);
    {$POP}
  end;
end;

{ TThreadEntry }

procedure TThreadEntry.SetThreadState(AValue: String);
begin
  if FThreadState = AValue then Exit;
  FThreadState := AValue;
end;

function TThreadEntry.CreateStackEntry: TCallStackEntry;
begin
  Result := TCallStackEntry.Create;
end;

constructor TThreadEntry.Create;
begin
  FTopFrame := CreateStackEntry;
  inherited Create;
end;

constructor TThreadEntry.Create(const AnAdress: TDbgPtr; const AnArguments: TStrings;
  const AFunctionName: String; const FileName, FullName: String; const ALine: Integer;
  const AThreadId: Integer; const AThreadName: String; const AThreadState: String;
  AState: TDebuggerDataState);
begin
  Create;
  TopFrame.Init(AnAdress, AnArguments, AFunctionName, FileName, FullName, ALine, AState);
  FThreadId    := AThreadId;
  FThreadName  := AThreadName;
  FThreadState := AThreadState;
end;

function TThreadEntry.CreateCopy: TThreadEntry;
begin
  Result := TThreadEntry.Create;
  Result.Assign(Self);
end;

destructor TThreadEntry.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FTopFrame);
end;

procedure TThreadEntry.Assign(AnOther: TThreadEntry);
begin
  FTopFrame.Free;
  FTopFrame    := AnOther.TopFrame.CreateCopy;
  FThreadId    := AnOther.FThreadId;
  FThreadName  := AnOther.FThreadName;
  FThreadState := AnOther.FThreadState;
end;

{ TThreads }

function TThreads.GetEntry(const AnIndex: Integer): TThreadEntry;
begin
  if (AnIndex < 0) or (AnIndex >= Count) then exit(nil);
  Result := TThreadEntry(FList[AnIndex]);
end;

function TThreads.GetEntryById(const AnID: Integer): TThreadEntry;
var
  i: Integer;
begin
  i := Count - 1;
  while i >= 0 do begin
    Result := Entries[i];
    if Result.ThreadId = AnID then
      exit;
    dec(i);
  end;
  Result := nil;
end;

procedure TThreads.SetCurrentThreadId(AValue: Integer);
begin
  if FCurrentThreadId = AValue then exit;
  FCurrentThreadId := AValue;
end;

constructor TThreads.Create;
begin
  FList := TList.Create;
end;

destructor TThreads.Destroy;
begin
  Clear;
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TThreads.Assign(AnOther: TThreads);
var
  i: Integer;
begin
  Clear;
  FCurrentThreadId := AnOther.FCurrentThreadId;
  for i := 0 to AnOther.FList.Count-1 do
    FList.Add(TThreadEntry(AnOther.FList[i]).CreateCopy);
end;

function TThreads.Count: Integer;
begin
  Result := FList.Count;
end;

procedure TThreads.Clear;
begin
  while FList.Count > 0 do begin
    TThreadEntry(Flist[0]).Free;
    FList.Delete(0);
  end;
end;

procedure TThreads.Add(AThread: TThreadEntry);
begin
  FList.Add(AThread.CreateCopy);
  if FList.Count = 1 then
    FCurrentThreadId := AThread.ThreadId;
end;

procedure TThreads.Remove(AThread: TThreadEntry);
begin
  FList.Remove(AThread);
  if FCurrentThreadId = AThread.ThreadId then begin
    if FList.Count > 0 then
      FCurrentThreadId := Entries[0].ThreadId
    else
      FCurrentThreadId := 0;
  end;
  AThread.Free;
end;

function TThreads.CreateEntry(const AnAdress: TDbgPtr; const AnArguments: TStrings;
  const AFunctionName: String; const FileName, FullName: String; const ALine: Integer;
  const AThreadId: Integer; const AThreadName: String; const AThreadState: String;
  AState: TDebuggerDataState): TThreadEntry;
begin
  Result := TThreadEntry.Create(AnAdress, AnArguments, AFunctionName, FileName,
    FullName, ALine, AThreadId, AThreadName, AThreadState, AState);
end;

procedure TThreads.SetValidity(AValidity: TDebuggerDataState);
begin
  //
end;

{ TThreadsMonitor }

function TThreadsMonitor.GetSupplier: TThreadsSupplier;
begin
  Result := TThreadsSupplier(inherited Supplier);
end;

procedure TThreadsMonitor.SetSupplier(AValue: TThreadsSupplier);
begin
  inherited Supplier := AValue;
end;

function TThreadsMonitor.CreateThreads: TThreads;
begin
  Result := TThreads.Create;
end;

constructor TThreadsMonitor.Create;
begin
  FThreads := CreateThreads;
  inherited Create;
end;

destructor TThreadsMonitor.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FThreads);
end;

{ TRegistersMonitor }

function TRegistersMonitor.GetSupplier: TRegisterSupplier;
begin
  Result := TRegisterSupplier(inherited Supplier);
end;

procedure TRegistersMonitor.SetSupplier(AValue: TRegisterSupplier);
begin
  inherited Supplier := AValue;
end;

function TRegistersMonitor.CreateRegistersList: TRegistersList;
begin
  Result := TRegistersList.Create;
end;

constructor TRegistersMonitor.Create;
begin
  inherited Create;
  FRegistersList := CreateRegistersList;
  FRegistersList.AddReference;
end;

destructor TRegistersMonitor.Destroy;
begin
  inherited Destroy;
  ReleaseRefAndNil(FRegistersList);
end;

{ TDebuggerDataHandler }

procedure TDebuggerDataHandler.DoStateEnterPause;
begin
  //
end;

procedure TDebuggerDataHandler.DoStateLeavePause;
begin
  //
end;

procedure TDebuggerDataHandler.DoStateLeavePauseClean;
begin
  //
end;

procedure TDebuggerDataHandler.DoStateChangeEx(const AOldState, ANewState: TDBGState);
begin
  FNotifiedState := ANewState;
  FOldState := AOldState;
  DebugLnEnter(DBG_DATA_MONITORS, [ClassName, ': >>ENTER: ', ClassName, '.DoStateChange  New-State=', dbgs(FNotifiedState)]);

  if FNotifiedState in [dsPause, dsInternalPause]
  then begin
    // typical: Clear and reload data
    if not(AOldState  in [dsPause, dsInternalPause] )
    then DoStateEnterPause;
  end
  else
  if (AOldState  in [dsPause, dsInternalPause, dsNone] )
  then begin
    // dsIdle happens after dsStop
    if (FNotifiedState  in [dsRun, dsInit, dsIdle]) or (AOldState = dsNone)
    then begin
      // typical: finalize snapshot and clear data.
      DoStateLeavePauseClean;
    end
    else begin
      // typical: finalize snapshot
      //          Do *not* clear data. Objects may be in use (e.g. dsError)
      DoStateLeavePause;
    end;
  end
  else
  if (AOldState  in [dsStop]) and (FNotifiedState = dsIdle)
  then begin
    // stopped // typical: finalize snapshot and clear data.
    DoStateLeavePauseClean;
  end;
  DebugLnExit(DBG_DATA_MONITORS, [ClassName, ': <<EXIT: ', ClassName, '.DoStateChange']);
end;

procedure TDebuggerDataHandler.DoBeginUpdate;
begin
  //
end;

procedure TDebuggerDataHandler.DoEndUpdate;
begin
  //
end;

procedure TDebuggerDataHandler.BeginUpdate;
begin
  inc(FUpdateCount);
  if FUpdateCount = 1 then
    DoBeginUpdate;
end;

procedure TDebuggerDataHandler.EndUpdate;
begin
  assert(FUpdateCount > 0, 'TDebuggerDataMonitor.EndUpdate: FUpdateCount > 0');
  dec(FUpdateCount);
  if FUpdateCount = 0 then
    DoEndUpdate;
end;

function TDebuggerDataHandler.IsUpdating: Boolean;
begin
  Result := FUpdateCount > 0;
end;

{ TWatchValue }

procedure TWatchValue.SetValidity(AValue: TDebuggerDataState);
var
  OldValidity: TDebuggerDataState;
begin
  if FValidity = AValue then exit;
  //DebugLn(DBG_DATA_MONITORS, ['DebugDataMonitor: TWatchValue.SetValidity: FThreadId=', FThreadId, '  FStackFrame=',FStackFrame, ' Expr=', Expression, ' AValidity=',dbgs(AValue)]);
  DebugLn(DBG_DATA_MONITORS, ['DebugDataMonitor: TWatchValue.SetValidity:  Expr=', Expression, ' AValidity=',dbgs(AValue)]);
  OldValidity := FValidity;
  FValidity := AValue;
  DoDataValidityChanged(OldValidity);
end;

procedure TWatchValue.SetValue(AValue: String);
begin
  if FValue = AValue then exit;
  //asser not immutable
  FValue := AValue;
end;

procedure TWatchValue.SetTypeInfo(AValue: TDBGType);
begin
  //assert(Self is TCurrentWatchValue, 'TWatchValue.SetTypeInfo');
  FreeAndNil(FTypeInfo);
  FTypeInfo := AValue;
end;

procedure TWatchValue.DoDataValidityChanged(AnOldValidity: TDebuggerDataState);
begin

end;

function TWatchValue.GetExpression: String;
begin
  Result := FWatch.Expression;
end;

function TWatchValue.GetTypeInfo: TDBGType;
begin
  Result := FTypeInfo;
end;

function TWatchValue.GetValue: String;
begin
  Result := FValue;
end;

constructor TWatchValue.Create(AOwnerWatch: TWatch);
begin
  FWatch := AOwnerWatch;
  inherited Create;
end;

function TWatchValue.GetWatch: TWatch;
begin
  Result := FWatch;
end;

destructor TWatchValue.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FTypeInfo);
end;

procedure TWatchValue.Assign(AnOther: TWatchValue);
begin
  FreeAndNil(FTypeInfo);
  //FTypeInfo    := TWatchValue(AnOther).FTypeInfo.cre;
  FValue         := AnOther.FValue;
  FValidity      := AnOther.FValidity;
end;

{ TWatch }

procedure TWatch.SetDisplayFormat(AValue: TWatchDisplayFormat);
begin
  if AValue = FDisplayFormat then exit;
  FDisplayFormat := AValue;
  DoDisplayFormatChanged;
end;

procedure TWatch.SetEnabled(AValue: Boolean);
begin
  if FEnabled <> AValue
  then begin
    FEnabled := AValue;
    DoEnableChange;
  end;
end;

procedure TWatch.SetEvaluateFlags(AValue: TDBGEvaluateFlags);
begin
  if FEvaluateFlags = AValue then Exit;
  FEvaluateFlags := AValue;
  Changed;
  DoModified;
end;

procedure TWatch.SetExpression(AValue: String);
begin
  if AValue <> FExpression
  then begin
    FExpression := AValue;
    FValueList.Clear;
    DoExpressionChange;
  end;
end;

procedure TWatch.SetRepeatCount(AValue: Integer);
begin
  if FRepeatCount = AValue then Exit;
  FRepeatCount := AValue;
  Changed;
  DoModified;
end;

function TWatch.GetValue(const AThreadId: Integer;
  const AStackFrame: Integer): TWatchValue;
begin
  Result := FValueList[AThreadId, AStackFrame];
end;

procedure TWatch.DoModified;
begin
  //
end;

procedure TWatch.DoEnableChange;
begin
  //
end;

procedure TWatch.DoExpressionChange;
begin
  //
end;

procedure TWatch.DoDisplayFormatChanged;
begin
  //
end;

procedure TWatch.AssignTo(Dest: TPersistent);
begin
  if Dest is TWatch
  then begin
    TWatch(Dest).FExpression    := FExpression;
    TWatch(Dest).FEnabled       := FEnabled;
    TWatch(Dest).FDisplayFormat := FDisplayFormat;
    TWatch(Dest).FRepeatCount   := FRepeatCount;
    TWatch(Dest).FEvaluateFlags := FEvaluateFlags;
    TWatch(Dest).FValueList.Assign(FValueList);
  end
  else inherited;
end;

function TWatch.CreateValueList: TWatchValueList;
begin
  Result := TWatchValueList.Create(Self);
end;

constructor TWatch.Create(ACollection: TCollection);
begin
  FEnabled := False;
  FValueList := CreateValueList;
  inherited Create(ACollection);
end;

destructor TWatch.Destroy;
begin
  FValueList.Clear;
  inherited Destroy;
  FreeAndNil(FValueList);
end;

procedure TWatch.ClearValues;
begin
  FValueList.Clear;
end;

{ TWatchValueList }

function TWatchValueList.GetEntry(const AThreadId: Integer;
  const AStackFrame: Integer): TWatchValue;
var
  i: Integer;
begin
  i := FList.Count - 1;
  while i >= 0 do begin
    Result := TWatchValue(FList[i]);
    if (Result.ThreadId = AThreadId) and (Result.StackFrame = AStackFrame) and
       (Result.DisplayFormat = FWatch.DisplayFormat) and
       (Result.RepeatCount = FWatch.RepeatCount) and
       (Result.EvaluateFlags = FWatch.EvaluateFlags)
    then
      exit;
    dec(i);
  end;
  Result := CreateEntry(AThreadId, AStackFrame);
end;

function TWatchValueList.GetEntryByIdx(AnIndex: integer): TWatchValue;
begin
  Result := TWatchValue(FList[AnIndex]);
end;

function TWatchValueList.CreateEntry(const AThreadId: Integer;
  const AStackFrame: Integer): TWatchValue;
begin
  Result := nil;
end;

function TWatchValueList.CopyEntry(AnEntry: TWatchValue): TWatchValue;
begin
  Result := TWatchValue.Create(FWatch);
  Result.Assign(AnEntry);
end;

procedure TWatchValueList.Assign(AnOther: TWatchValueList);
var
  i: Integer;
begin
  Clear;
  for i := 0 to AnOther.FList.Count - 1 do begin
    FList.Add(CopyEntry(TWatchValue(AnOther.FList[i])));
  end;
end;

constructor TWatchValueList.Create(AOwnerWatch: TWatch);
begin
  assert(AOwnerWatch <> nil, 'TWatchValueList.Create without owner');
  FList := TList.Create;
  FWatch := AOwnerWatch;
  inherited Create;
end;

destructor TWatchValueList.Destroy;
begin
  Clear;
  inherited Destroy;
  FreeAndNil(FList);
end;

procedure TWatchValueList.Add(AnEntry: TWatchValue);
begin
  Flist.Add(AnEntry);
end;

procedure TWatchValueList.Clear;
begin
  while FList.Count > 0 do begin
    TObject(FList[0]).Free;
    FList.Delete(0);
  end;
end;

function TWatchValueList.Count: Integer;
begin
  Result := FList.Count;
end;

{ TRegisterSupplier }

function TRegisterSupplier.GetCurrentRegistersList: TRegistersList;
begin
  Result := nil;
  if Monitor <> nil then
    Result := Monitor.RegistersList;
end;

function TRegisterSupplier.GetMonitor: TRegistersMonitor;
begin
  Result := TRegistersMonitor(inherited Monitor);
end;

procedure TRegisterSupplier.SetMonitor(AValue: TRegistersMonitor);
begin
  inherited Monitor := AValue;
end;

procedure TRegisterSupplier.RequestData(ARegisters: TRegisters);
begin
  ARegisters.SetDataValidity(ddsInvalid);
end;

{ TLocalsValue }

procedure TLocalsValue.DoAssign(AnOther: TDbgEntityValue);
begin
  inherited DoAssign(AnOther);
  FName := TLocalsValue(AnOther).FName;
  FValue := TLocalsValue(AnOther).FValue;
end;

{ TLocalsListBase }

function TLocalsList.GetEntry(AThreadId, AStackFrame: Integer): TLocals;
begin
  Result := TLocals(inherited Entries[AThreadId, AStackFrame]);
end;

function TLocalsList.GetEntryByIdx(AnIndex: Integer): TLocals;
begin
  Result := TLocals(inherited EntriesByIdx[AnIndex]);
end;

{ TLocalsBase }

function TLocals.GetEntry(AnIndex: Integer): TLocalsValue;
begin
  Result := TLocalsValue(inherited Entries[AnIndex]);
end;

function TLocals.GetName(const AnIndex: Integer): String;
begin
  Result := Entries[AnIndex].Name;
end;

function TLocals.GetValue(const AnIndex: Integer): String;
begin
  Result := Entries[AnIndex].Value;
end;

function TLocals.CreateEntry: TDbgEntityValue;
begin
  Result := TLocalsValue.Create;
end;

procedure TLocals.Add(const AName, AValue: String);
var
  v: TLocalsValue;
begin
  assert(not Immutable, 'TLocalsBase.Add Immutable');
  v := TLocalsValue(CreateEntry);
  v.FName := AName;
  v.FValue := AValue;
  inherited Add(v);
end;

procedure TLocals.SetDataValidity(AValidity: TDebuggerDataState);
begin
  //
end;

function TLocals.Count: Integer;
begin
  Result := inherited Count;
end;

{ TRegisterDisplayValue }

function TRegisterDisplayValue.GetValue(ADispFormat: TRegisterDisplayFormat): String;
const Digits = '01234567';
  function IntToBase(Val, Base: Integer): String;
  var
    M: Integer;
  begin
    Result := '';
    case Base of
      2: M := 1;
      8: M := 7;
    end;
    while Val > 0 do begin
      Result := Digits[1 + (Val and m)] + Result;
      Val := Val div Base;
    end;
  end;
begin
  Result := '';
  if not(ADispFormat in FSupportedDispFormats) then exit;
  if (ADispFormat in [rdDefault, rdRaw]) or not (rdvHasNum in FFlags) then begin
    Result := FStringValue;
    exit;
  end;
  case ADispFormat of
    rdHex:    Result := IntToHex(FNumValue, FSize * 2);
    rdBinary: Result := IntToBase(FNumValue, 2);
    rdOctal:  Result := IntToBase(FNumValue, 8);
    rdDecimal: Result := IntToStr(FNumValue);
  end;
end;

procedure TRegisterDisplayValue.Assign(AnOther: TRegisterDisplayValue);
begin
  FStringValue          := AnOther.FStringValue;
  FNumValue             := AnOther.FNumValue;
  FFlags                := AnOther.FFlags;
  FSize                 := AnOther.FSize;
  FSupportedDispFormats := AnOther.FSupportedDispFormats;
end;

procedure TRegisterDisplayValue.SetAsNum(AValue: QWord; ASize: Integer);
begin
  if FNumValue = AValue then Exit;
  FNumValue := AValue;
  FSize := ASize;
  Include(FFlags, rdvHasNum);
end;

procedure TRegisterDisplayValue.SetAsText(AValue: String);
begin
  FStringValue := AValue;
end;

procedure TRegisterDisplayValue.AddFormats(AFormats: TRegisterDisplayFormats);
begin
  FSupportedDispFormats := FSupportedDispFormats + AFormats;
end;

{ TRegisterValue }

function TRegisterValue.GetValue: String;
var
  v: TRegisterDisplayValue;
begin
  v :=  GetValueObject();
  if v <> nil then begin
    Result := v.Value[FDisplayFormat];
    exit;
  end;

  Result := '';
  DoValueNotEvaluated;
end;

function TRegisterValue.GetHasValue: Boolean;
begin
  Result := GetValueObject <> nil;
end;

function TRegisterValue.GetHasValueFormat(ADispFormat: TRegisterDisplayFormat): Boolean;
begin
  Result := GetValueObject(ADispFormat) <> nil;
end;

function TRegisterValue.GetValueObj: TRegisterDisplayValue;
begin
  Result := GetValueObject(True);
end;

function TRegisterValue.GetValueObjFormat(ADispFormat: TRegisterDisplayFormat): TRegisterDisplayValue;
begin
  Result := GetValueObject(ADispFormat, True);
end;

procedure TRegisterValue.SetDisplayFormat(AValue: TRegisterDisplayFormat);
var
  Old: TRegisterDisplayFormat;
begin
  assert(not Immutable, 'TRegisterValue.SetDisplayFormat: not Immutable');
  if FDisplayFormat = AValue then Exit;
  Old := FDisplayFormat;
  FDisplayFormat := AValue;
  DoDisplayFormatChanged(Old);
end;

procedure TRegisterValue.SetValue(AValue: String);
var
  v: TRegisterDisplayValue;
begin
  assert(not Immutable, 'TRegisterValue.SetValue: not Immutable');
  v :=  GetValueObject(True);
  v.FStringValue := AValue;
end;

function TRegisterValue.GetValueObject(ACreateNew: Boolean): TRegisterDisplayValue;
begin
  Result := GetValueObject(FDisplayFormat, ACreateNew);
end;

function TRegisterValue.GetValueObject(ADispFormat: TRegisterDisplayFormat;
  ACreateNew: Boolean): TRegisterDisplayValue;
var
  i: Integer;
begin
  for i := 0 to length(FValues) - 1 do
    if ADispFormat in FValues[i].SupportedDispFormats then begin
      Result := FValues[i];
      exit;
    end;

  if not ACreateNew then begin
    Result := nil;
    exit;
  end;

  assert(not Immutable, 'TRegisterValue.GetValueObject: not Immutable');
  Result := TRegisterDisplayValue.Create;
  Result.FSupportedDispFormats := [ADispFormat];
  i := length(FValues);
  SetLength(FValues, i + 1);
  FValues[i] := Result;
end;

procedure TRegisterValue.SetDataValidity(AValidity: TDebuggerDataState);
var
  Old: TDebuggerDataState;
begin
  assert(not Immutable, 'TRegisterValue.SetDataValidity: not Immutable');
  if FDataValidity = AValidity then exit;
  Old := FDataValidity;
  FDataValidity := AValidity;
  DoDataValidityChanged(Old);
end;

procedure TRegisterValue.ClearDispValues;
var
  i: Integer;
begin
  for i := 0 to Length(FValues) - 1 do
    FValues[i].Free;
  FValues := nil;
end;

procedure TRegisterValue.DoAssign(AnOther: TDbgEntityValue);
var
  i: Integer;
begin
  inherited DoAssign(AnOther);
  FDataValidity  :=  TRegisterValue(AnOther).FDataValidity;
  FDisplayFormat :=  TRegisterValue(AnOther).FDisplayFormat;
  FName          :=  TRegisterValue(AnOther).FName;
  SetLength(FValues, length(TRegisterValue(AnOther).FValues));
  for i := 0 to length(TRegisterValue(AnOther).FValues) - 1 do begin
    FValues[i] := TRegisterDisplayValue.Create;
    FValues[i].Assign(TRegisterValue(AnOther).FValues[i]);
  end;
end;

procedure TRegisterValue.DoDataValidityChanged(AnOldValidity: TDebuggerDataState);
begin
  //
end;

procedure TRegisterValue.DoDisplayFormatChanged(AnOldFormat: TRegisterDisplayFormat);
begin
  //
end;

procedure TRegisterValue.DoValueNotEvaluated;
begin
  //
end;

destructor TRegisterValue.Destroy;
begin
  inherited Destroy;
  ClearDispValues;
end;

{ TRegisters }

function TRegisters.GetEntry(AnIndex: Integer): TRegisterValue;
begin
  Result := TRegisterValue(inherited Entries[AnIndex]);
end;

function TRegisters.GetEntryByName(const AName: String): TRegisterValue;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do begin
    Result := Entries[i];
    if Result.Name = AName then
      exit;
  end;

  assert(not Immutable, 'TRegisters.GetEntryByName: not Immutable');
  Result := TRegisterValue(CreateEntry);
  Result.FName := AName;
  Add(Result);
end;

procedure TRegisters.SetDataValidity(AValue: TDebuggerDataState);
var
  Old: TDebuggerDataState;
begin
  assert(not Immutable, 'TRegisters.SetDataValidity: not Immutable');
  if FDataValidity = AValue then Exit;
  Old := FDataValidity;
  FDataValidity := AValue;
  DoDataValidityChanged(Old);
end;

function TRegisters.CreateEntry: TDbgEntityValue;
begin
  assert(not Immutable, 'TRegisters.CreateEntry: not Immutable');
  Result := TRegisterValue.Create;
end;

procedure TRegisters.DoDataValidityChanged(AnOldValidity: TDebuggerDataState);
begin
  //
end;

function TRegisters.Count: Integer;
begin
  if FDataValidity = ddsValid then
    Result := inherited Count
  else
    Result := 0;
end;

{ TRegistersList }

function TRegistersList.GetEntry(AThreadId, AStackFrame: Integer): TRegisters;
begin
  Result := TRegisters(inherited Entries[AThreadId, AStackFrame]);
end;

function TRegistersList.GetEntryByIdx(AnIndex: Integer): TRegisters;
begin
  Result := TRegisters(inherited EntriesByIdx[AnIndex]);
end;

{ TWatchesBase }

function TWatches.GetItemBase(const AnIndex: Integer): TWatch;
begin
  Result := TWatch(inherited Items[AnIndex]);
end;

procedure TWatches.SetItemBase(const AnIndex: Integer; const AValue: TWatch);
begin
  inherited Items[AnIndex] := AValue;
end;

function TWatches.WatchClass: TWatchClass;
begin
  Result := TWatch;
end;

constructor TWatches.Create;
begin
  inherited Create(WatchClass);
end;

procedure TWatches.ClearValues;
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
    Items[n].ClearValues;
end;

function TWatches.Find(const AExpression: String): TWatch;
var
  n: Integer;
  S: String;
begin
  S := UpperCase(AExpression);
  for n := 0 to Count - 1 do
  begin
    Result := TWatch(GetItem(n));
    if UpperCase(Result.Expression) = S
    then Exit;
  end;
  Result := nil;
end;

{ TCallStackBase }

function TCallStackBase.GetNewCurrentIndex: Integer;
begin
  Result := 0;
end;

function TCallStackBase.GetCount: Integer;
begin
  Result := 0;
end;

function TCallStackBase.GetCurrent: Integer;
begin
  Result := FCurrent;
end;

procedure TCallStackBase.SetCurrent(AValue: Integer);
begin
  FCurrent := AValue;
end;

function TCallStackBase.GetHighestUnknown: Integer;
begin
  Result := -1;
end;

function TCallStackBase.GetLowestUnknown: Integer;
begin
  Result := 0;
end;

constructor TCallStackBase.Create;
begin
  FThreadId := -1;
  FCurrent := -1;
  inherited;
end;

function TCallStackBase.CreateCopy: TCallStackBase;
begin
  Result := TCallStackBase.Create;
  Result.Assign(Self);
end;

procedure TCallStackBase.Assign(AnOther: TCallStackBase);
begin
  ThreadId := AnOther.ThreadId;
  FCurrent := AnOther.FCurrent;
end;

procedure TCallStackBase.SetCountValidity(AValidity: TDebuggerDataState);
begin
  //
end;

procedure TCallStackBase.SetHasAtLeastCountInfo(AValidity: TDebuggerDataState;
  AMinCount: Integer);
begin
  //
end;

procedure TCallStackBase.SetCurrentValidity(AValidity: TDebuggerDataState);
begin
  //
end;

{ TRunningProcessInfo }

constructor TRunningProcessInfo.Create(APID: Cardinal; const AImageName: string);
begin
  self.PID := APID;
  self.ImageName := AImageName;
end;

{ TDebuggerDataMonitor }

procedure TDebuggerDataMonitor.SetSupplier(const AValue: TDebuggerDataSupplier);
begin
  if FSupplier = AValue then exit;
  Assert((FSupplier=nil) or (AValue=nil), 'TDebuggerDataMonitor.Supplier already set');
  if FSupplier <> nil then FSupplier.Monitor := nil;
  FSupplier := AValue;
  if FSupplier <> nil then FSupplier.Monitor:= self;

  DoNewSupplier;
end;

procedure TDebuggerDataMonitor.DoModified;
begin
  //
end;

procedure TDebuggerDataMonitor.DoNewSupplier;
begin
  //
end;

destructor TDebuggerDataMonitor.Destroy;
begin
  Supplier := nil;
  inherited Destroy;
end;

{ TDebuggerDataSupplier }

procedure TDebuggerDataSupplier.SetMonitor(const AValue: TDebuggerDataMonitor);
begin
  if FMonitor = AValue then exit;
  Assert((FMonitor=nil) or (AValue=nil), 'TDebuggerDataSupplier.Monitor already set');
  FMonitor := AValue;
  DoNewMonitor;
end;

procedure TDebuggerDataSupplier.DoNewMonitor;
begin
  //
end;

procedure TDebuggerDataSupplier.DoStateLeavePauseClean;
begin
  DoStateLeavePause;
end;

procedure TDebuggerDataSupplier.DoStateChange(const AOldState: TDBGState);
begin
  if (Debugger = nil) then Exit;
  DoStateChangeEx(AOldState, Debugger.State);
  if Monitor <> nil then
    Monitor.DoStateChangeEx(AOldState, FDebugger.State);
end;

constructor TDebuggerDataSupplier.Create(const ADebugger: TDebuggerIntf);
begin
  FDebugger := ADebugger;
  inherited Create;
end;

destructor TDebuggerDataSupplier.Destroy;
begin
  if FMonitor <> nil then FMonitor.Supplier := nil;
  inherited Destroy;
end;

procedure TDebuggerDataSupplier.DoBeginUpdate;
begin
  FMonitor.BeginUpdate;
end;

procedure TDebuggerDataSupplier.DoEndUpdate;
begin
  FMonitor.EndUpdate;
end;

{ ===========================================================================
  TBaseBreakPoint
  =========================================================================== }

function TBaseBreakPoint.GetAddress: TDBGPtr;
begin
  Result := FAddress;
end;

function TBaseBreakPoint.GetKind: TDBGBreakPointKind;
begin
  Result := FKind;
end;

procedure TBaseBreakPoint.SetKind(const AValue: TDBGBreakPointKind);
begin
  if FKind <> AValue
  then begin
    FKind := AValue;
    DoKindChange;
  end;
end;

procedure TBaseBreakPoint.SetAddress(const AValue: TDBGPtr);
begin
  if FAddress <> AValue then
  begin
    FAddress := AValue;
    Changed;
  end;
end;

function TBaseBreakPoint.GetWatchData: String;
begin
  Result := FWatchData;
end;

function TBaseBreakPoint.GetWatchScope: TDBGWatchPointScope;
begin
  Result := FWatchScope;
end;

function TBaseBreakPoint.GetWatchKind: TDBGWatchPointKind;
begin
  Result := FWatchKind;
end;

procedure TBaseBreakPoint.AssignLocationTo(Dest: TPersistent);
var
  DestBreakPoint: TBaseBreakPoint absolute Dest;
begin
  DestBreakPoint.SetLocation(FSource, FLine);
end;

procedure TBaseBreakPoint.AssignTo(Dest: TPersistent);
var
  DestBreakPoint: TBaseBreakPoint absolute Dest;
begin
  // updatelock is set in source.assignto
  if Dest is TBaseBreakPoint
  then begin
    DestBreakPoint.SetKind(FKind);
    DestBreakPoint.SetWatch(FWatchData, FWatchScope, FWatchKind);
    DestBreakPoint.SetAddress(FAddress);
    AssignLocationTo(DestBreakPoint);
    DestBreakPoint.SetBreakHitCount(FBreakHitCount);
    DestBreakPoint.SetExpression(FExpression);
    DestBreakPoint.SetEnabled(FEnabled);
    DestBreakPoint.InitialEnabled := FInitialEnabled;
  end
  else inherited;
end;

constructor TBaseBreakPoint.Create(ACollection: TCollection);
begin
  FAddress := 0;
  FSource := '';
  FLine := -1;
  FValid := vsUnknown;
  FEnabled := False;
  FHitCount := 0;
  FBreakHitCount := 0;
  FExpression := '';
  FInitialEnabled := False;
  FKind := bpkSource;
  inherited Create(ACollection);
  AddReference;
end;

procedure TBaseBreakPoint.DoBreakHitCountChange;
begin
  Changed;
end;

procedure TBaseBreakPoint.DoEnableChange;
begin
  Changed;
end;

procedure TBaseBreakPoint.DoExpressionChange;
begin
  Changed;
end;

procedure TBaseBreakPoint.DoHit(const ACount: Integer; var AContinue: Boolean );
begin
  SetHitCount(ACount);
end;

function TBaseBreakPoint.GetBreakHitCount: Integer;
begin
  Result := FBreakHitCount;
end;

function TBaseBreakPoint.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TBaseBreakPoint.GetExpression: String;
begin
  Result := FExpression;
end;

function TBaseBreakPoint.GetHitCount: Integer;
begin
  Result := FHitCount;
end;

function TBaseBreakPoint.GetLine: Integer;
begin
  Result := FLine;
end;

function TBaseBreakPoint.GetSource: String;
begin
  Result := FSource;
end;

function TBaseBreakPoint.GetValid: TValidState;
begin
  Result := FValid;
end;

procedure TBaseBreakPoint.SetBreakHitCount(const AValue: Integer);
begin
  if FBreakHitCount <> AValue
  then begin
    FBreakHitCount := AValue;
    DoBreakHitCountChange;
  end;
end;

procedure TBaseBreakPoint.SetEnabled (const AValue: Boolean );
begin
  if FEnabled <> AValue
  then begin
    FEnabled := AValue;
    DoEnableChange;
  end;
end;

procedure TBaseBreakPoint.SetExpression (const AValue: String );
begin
  if FExpression <> AValue
  then begin
    FExpression := AValue;
    DoExpressionChange;
  end;
end;

procedure TBaseBreakPoint.SetHitCount (const AValue: Integer );
begin
  if FHitCount <> AValue
  then begin
    FHitCount := AValue;
    Changed;
  end;
end;

procedure TBaseBreakPoint.DoKindChange;
begin
  Changed;
end;

procedure TBaseBreakPoint.SetInitialEnabled(const AValue: Boolean);
begin
  if FInitialEnabled=AValue then exit;
  FInitialEnabled:=AValue;
end;

procedure TBaseBreakPoint.SetLocation (const ASource: String; const ALine: Integer );
begin
  if (FSource = ASource) and (FLine = ALine) then exit;
  FSource := ASource;
  FLine := ALine;
  Changed;
end;

procedure TBaseBreakPoint.SetWatch(const AData: String; const AScope: TDBGWatchPointScope;
  const AKind: TDBGWatchPointKind);
begin
  if (AData = FWatchData) and (AScope = FWatchScope) and (AKind = FWatchKind) then exit;
  FWatchData := AData;
  FWatchScope := AScope;
  FWatchKind := AKind;
  Changed;
end;

procedure TBaseBreakPoint.SetValid(const AValue: TValidState );
begin
  if FValid <> AValue
  then begin
    FValid := AValue;
    Changed;
  end;
end;

{ =========================================================================== }
{ TDBGBreakPoint }
{ =========================================================================== }

constructor TDBGBreakPoint.Create (ACollection: TCollection );
begin
  FSlave := nil;
  inherited Create(ACollection);
end;

destructor TDBGBreakPoint.Destroy;
var
  SBP: TBaseBreakPoint;
begin
  SBP := FSlave;
  FSlave := nil;
  if SBP <> nil
  then SBP.DoChanged;   // In case UpdateCount  0

  inherited Destroy;
end;

procedure TDBGBreakPoint.Hit(var ACanContinue: Boolean);
var
  cnt: Integer;
begin
  cnt := HitCount + 1;
  if BreakHitcount > 0
  then ACanContinue := cnt < BreakHitcount;
  DoHit(cnt, ACanContinue);
  if Assigned(FSlave)
  then FSlave.DoHit(cnt, ACanContinue);
  Debugger.DoBreakpointHit(Self, ACanContinue)
end;

procedure TDBGBreakPoint.DoChanged;
begin
  inherited DoChanged;
  if FSlave <> nil
  then FSlave.Changed;
end;

procedure TDBGBreakPoint.DoStateChange(const AOldState: TDBGState);
begin
  if Debugger.State <> dsStop then Exit;
  if not (AOldState in [dsIdle, dsNone]) then Exit;

  BeginUpdate;
  try
    SetLocation(FSource, Line);
    Enabled := InitialEnabled;
    SetHitCount(0);
  finally
    EndUpdate;
  end;
end;

procedure TDBGBreakPoint.DoLogMessage(const AMessage: String);
begin
  Debugger.DoDbgEvent(ecBreakpoint, etBreakpointMessage, 'Breakpoint Message: ' + AMessage);
end;

procedure TDBGBreakPoint.DoLogCallStack(const Limit: Integer);
const
  Spacing = '    ';
var
  CallStack: TCallStackBase;
  I, Count: Integer;
  Entry: TCallStackEntry;
  StackString: String;
begin
  Debugger.SetState(dsInternalPause);
  CallStack := Debugger.CallStack.CurrentCallStackList.EntriesForThreads[Debugger.Threads.CurrentThreads.CurrentThreadId];
  if Limit = 0 then
  begin
    Debugger.DoDbgEvent(ecBreakpoint, etBreakpointMessage, 'Breakpoint Call Stack: Log all stack frames');
    Count := CallStack.Count;
    CallStack.PrepareRange(0, Count);
  end
  else
  begin
    Debugger.DoDbgEvent(ecBreakpoint, etBreakpointMessage, Format('Breakpoint Call Stack: Log %d stack frames', [Limit]));
    Count := CallStack.CountLimited(Limit);
    CallStack.PrepareRange(0, Count);
  end;

  for I := 0 to Count - 1 do
  begin
    Entry := CallStack.Entries[I];
    StackString := Spacing + Entry.Source;
    if Entry.Source = '' then // we do not have a source file => just show an adress
      StackString := Spacing + ':' + IntToHex(Entry.Address, 8);
    StackString := StackString + ' ' + Entry.GetFunctionWithArg;
    if line > 0 then
      StackString := StackString + ' line ' + IntToStr(Entry.Line);

    Debugger.DoDbgEvent(ecBreakpoint, etBreakpointStackDump, StackString);
  end;
end;

procedure TDBGBreakPoint.DoLogExpression(const AnExpression: String);
begin
  // will be called while Debgger.State = dsRun => can not call Evaluate
end;

function TDBGBreakPoint.GetDebugger: TDebuggerIntf;
begin
  Result := TDBGBreakPoints(Collection).FDebugger;
end;

procedure TDBGBreakPoint.SetSlave(const ASlave : TBaseBreakPoint);
begin
  Assert((FSlave = nil) or (ASlave = nil), 'TDBGBreakPoint.SetSlave already has a slave');
  FSlave := ASlave;
end;

procedure TDBGBreakPoint.SetEnabled(const AValue: Boolean);
begin
  if Enabled = AValue then exit;
  inherited SetEnabled(AValue);
  // feedback to IDEBreakPoint
  if FSlave <> nil then FSlave.Enabled := AValue;
end;

{ =========================================================================== }
{ TBaseBreakPoints }
{ =========================================================================== }

function TBaseBreakPoints.Add(const ASource: String; const ALine: Integer): TBaseBreakPoint;
begin
  Result := TBaseBreakPoint(inherited Add);
  Result.SetKind(bpkSource);
  Result.SetLocation(ASource, ALine);
end;

function TBaseBreakPoints.Add(const AAddress: TDBGPtr): TBaseBreakPoint;
begin
  Result := TBaseBreakPoint(inherited Add);
  Result.SetKind(bpkAddress);
  Result.SetAddress(AAddress);
end;

function TBaseBreakPoints.Add(const AData: String; const AScope: TDBGWatchPointScope;
  const AKind: TDBGWatchPointKind): TBaseBreakPoint;
begin
  Result := TBaseBreakPoint(inherited Add);
  Result.SetKind(bpkData);
  Result.SetWatch(AData, AScope, AKind);
end;

constructor TBaseBreakPoints.Create(const ABreakPointClass: TBaseBreakPointClass);
begin
  inherited Create(ABreakPointClass);
end;

destructor TBaseBreakPoints.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TBaseBreakPoints.Clear;
begin
  while Count > 0 do TBaseBreakPoint(GetItem(0)).ReleaseReference;
end;

function TBaseBreakPoints.Find(const ASource: String; const ALine: Integer): TBaseBreakPoint;
begin
  Result := Find(ASource, ALine, nil);
end;

function TBaseBreakPoints.Find(const ASource: String; const ALine: Integer; const AIgnore: TBaseBreakPoint): TBaseBreakPoint;
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
  begin
    Result := TBaseBreakPoint(GetItem(n));
    if  (Result.Kind = bpkSource)
    and (Result.Line = ALine)
    and (AIgnore <> Result)
    and (CompareFilenames(Result.Source, ASource) = 0)
    then Exit;
  end;
  Result := nil;
end;

function TBaseBreakPoints.Find(const AAddress: TDBGPtr): TBaseBreakPoint;
begin
  Result := Find(AAddress, nil);
end;

function TBaseBreakPoints.Find(const AAddress: TDBGPtr; const AIgnore: TBaseBreakPoint): TBaseBreakPoint;
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
  begin
    Result := TBaseBreakPoint(GetItem(n));
    if  (Result.Kind = bpkAddress)
    and (Result.Address = AAddress)
    and (AIgnore <> Result)
    then Exit;
  end;
  Result := nil;
end;

function TBaseBreakPoints.Find(const AData: String; const AScope: TDBGWatchPointScope;
  const AKind: TDBGWatchPointKind): TBaseBreakPoint;
begin
  Result := Find(AData, AScope, AKind, nil);
end;

function TBaseBreakPoints.Find(const AData: String; const AScope: TDBGWatchPointScope;
  const AKind: TDBGWatchPointKind; const AIgnore: TBaseBreakPoint): TBaseBreakPoint;
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
  begin
    Result := TBaseBreakPoint(GetItem(n));
    if  (Result.Kind = bpkData)
    and (Result.WatchData = AData)
    and (Result.WatchScope = AScope)
    and (Result.WatchKind = AKind)
    and (AIgnore <> Result)
    then Exit;
  end;
  Result := nil;
end;

{ =========================================================================== }
{ TDBGBreakPoints }
{ =========================================================================== }

function TDBGBreakPoints.Add (const ASource: String; const ALine: Integer ): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Add(ASource, ALine));
end;

function TDBGBreakPoints.Add(const AAddress: TDBGPtr): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Add(AAddress));
end;

function TDBGBreakPoints.Add(const AData: String; const AScope: TDBGWatchPointScope;
  const AKind: TDBGWatchPointKind): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Add(AData, AScope, AKind));
end;

constructor TDBGBreakPoints.Create(const ADebugger: TDebuggerIntf;
  const ABreakPointClass: TDBGBreakPointClass);
begin
  FDebugger := ADebugger;
  inherited Create(ABreakPointClass);
end;

procedure TDBGBreakPoints.DoStateChange(const AOldState: TDBGState);
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
    GetItem(n).DoStateChange(AOldState);
end;

function TDBGBreakPoints.Find(const ASource: String; const ALine: Integer): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Find(Asource, ALine, nil));
end;

function TDBGBreakPoints.Find (const ASource: String; const ALine: Integer; const AIgnore: TDBGBreakPoint ): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Find(ASource, ALine, AIgnore));
end;

function TDBGBreakPoints.Find(const AAddress: TDBGPtr): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Find(AAddress));
end;

function TDBGBreakPoints.Find(const AAddress: TDBGPtr; const AIgnore: TDBGBreakPoint): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Find(AAddress, nil));
end;

function TDBGBreakPoints.Find(const AData: String; const AScope: TDBGWatchPointScope;
  const AKind: TDBGWatchPointKind): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Find(AData, AScope, AKind, nil));
end;

function TDBGBreakPoints.Find(const AData: String; const AScope: TDBGWatchPointScope;
  const AKind: TDBGWatchPointKind; const AIgnore: TDBGBreakPoint): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited Find(AData, AScope, AKind, AIgnore));
end;

function TDBGBreakPoints.GetItem (const AnIndex: Integer ): TDBGBreakPoint;
begin
  Result := TDBGBreakPoint(inherited GetItem(AnIndex));
end;

procedure TDBGBreakPoints.SetItem (const AnIndex: Integer; const AValue: TDBGBreakPoint );
begin
  inherited SetItem(AnIndex, AValue);
end;

{ TDBGField }

procedure TDBGField.IncRefCount;
begin
  inc(FRefCount);
end;

procedure TDBGField.DecRefCount;
begin
  dec(FRefCount);
  if FRefCount <= 0
  then Self.Free;
end;

constructor TDBGField.Create(const AName: String; ADBGType: TDBGType;
  ALocation: TDBGFieldLocation; AFlags: TDBGFieldFlags; AClassName: String = '');
begin
  inherited Create;
  FName := AName;
  FLocation := ALocation;
  FDBGType := ADBGType;
  FFlags := AFlags;
  FRefCount := 0;
  FClassName := AClassName;
end;

destructor TDBGField.Destroy;
begin
  FreeAndNil(FDBGType);
  inherited Destroy;
end;

{ TDBGFields }

constructor TDBGFields.Create;
begin
  FList := TList.Create;
  inherited;
end;

destructor TDBGFields.Destroy;
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
    Items[n].DecRefCount;

  FreeAndNil(FList);
  inherited;
end;

procedure TDBGFields.Add(const AField: TDBGField);
begin
  AField.IncRefCount;
  FList.Add(AField);
end;

function TDBGFields.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TDBGFields.GetField(const AIndex: Integer): TDBGField;
begin
  Result := TDBGField(FList[AIndex]);
end;

{ TDBGPTypes }

constructor TDBGTypes.Create;
begin
  FList := TList.Create;
  inherited;
end;

destructor TDBGTypes.Destroy;
var
  n: Integer;
begin
  for n := 0 to Count - 1 do
    Items[n].Free;

  FreeAndNil(FList);
  inherited;
end;

function TDBGTypes.GetCount: Integer;
begin
  Result := Flist.Count;
end;

function TDBGTypes.GetType(const AIndex: Integer): TDBGType;
begin
  Result := TDBGType(FList[AIndex]);
end;

{ TDBGPType }

function TDBGType.GetFields: TDBGFields;
begin
  if FFields = nil then
    FFields := TDBGFields.Create;
  Result := FFields;
end;

procedure TDBGType.Init;
begin
  //
end;

constructor TDBGType.Create(AKind: TDBGSymbolKind; const ATypeName: String);
begin
  FKind := AKind;
  FTypeName := ATypeName;
  Init;
  inherited Create;
end;

constructor TDBGType.Create(AKind: TDBGSymbolKind; const AArguments: TDBGTypes; AResult: TDBGType);
begin
  FKind := AKind;
  FArguments := AArguments;
  FResult := AResult;
  Init;
  inherited Create;
end;

destructor TDBGType.Destroy;
begin
  FreeAndNil(FResult);
  FreeAndNil(FArguments);
  FreeAndNil(FFields);
  FreeAndNil(FMembers);
  inherited;
end;

{ TWatchesSupplier }

procedure TWatchesSupplier.RequestData(AWatchValue: TWatchValue);
begin
  if FNotifiedState  in [dsPause, dsInternalPause]
  then InternalRequestData(AWatchValue)
  else AWatchValue.SetValidity(ddsInvalid);
end;

function TWatchesSupplier.GetCurrentWatches: TWatches;
begin
  Result := Nil;
  if Monitor <> nil then
    Result := Monitor.Watches;
end;

function TWatchesSupplier.GetMonitor: TWatchesMonitor;
begin
  Result := TWatchesMonitor(inherited Monitor);
end;

procedure TWatchesSupplier.SetMonitor(AValue: TWatchesMonitor);
begin
  inherited Monitor := AValue;
end;

procedure TWatchesSupplier.DoStateChange(const AOldState: TDBGState);
begin
  // workaround for state changes during TWatchValue.GetValue
  inc(DbgStateChangeCounter);
  if DbgStateChangeCounter = high(DbgStateChangeCounter) then DbgStateChangeCounter := 0;
  inherited DoStateChange(AOldState);
end;

procedure TWatchesSupplier.InternalRequestData(AWatchValue: TWatchValue);
begin
  AWatchValue.SetValidity(ddsInvalid);
end;

constructor TWatchesSupplier.Create(const ADebugger: TDebuggerIntf);
begin
  inherited Create(ADebugger);
  FNotifiedState := dsNone;
end;

{ TWatchesMonitor }

function TWatchesMonitor.GetSupplier: TWatchesSupplier;
begin
  Result := TWatchesSupplier(inherited Supplier);
end;

procedure TWatchesMonitor.SetSupplier(AValue: TWatchesSupplier);
begin
  inherited Supplier := AValue;
end;

function TWatchesMonitor.CreateWatches: TWatches;
begin
  Result := TWatches.Create;
end;

constructor TWatchesMonitor.Create;
begin
  FWatches := CreateWatches;
  inherited Create;
end;

destructor TWatchesMonitor.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FWatches);
end;

{ TLocalsSupplier }

function TLocalsSupplier.GetCurrentLocalsList: TLocalsList;
begin
  Result := nil;
  if Monitor <> nil then
    Result := Monitor.LocalsList;
end;

function TLocalsSupplier.GetMonitor: TLocalsMonitor;
begin
  Result := TLocalsMonitor(inherited Monitor);
end;

procedure TLocalsSupplier.SetMonitor(AValue: TLocalsMonitor);
begin
  inherited Monitor := AValue;
end;

procedure TLocalsSupplier.RequestData(ALocals: TLocals);
begin
  ALocals.SetDataValidity(ddsInvalid)
end;

{ TLocalsMonitor }

function TLocalsMonitor.GetSupplier: TLocalsSupplier;
begin
  Result := TLocalsSupplier(inherited Supplier);
end;

procedure TLocalsMonitor.SetSupplier(AValue: TLocalsSupplier);
begin
  inherited Supplier := AValue;
end;

function TLocalsMonitor.CreateLocalsList: TLocalsList;
begin
  Result := TLocalsList.Create;
end;

constructor TLocalsMonitor.Create;
begin
  FLocalsList := CreateLocalsList;
  FLocalsList.AddReference;
  inherited Create;
end;

destructor TLocalsMonitor.Destroy;
begin
  inherited Destroy;
  ReleaseRefAndNil(FLocalsList);
end;

{ TBaseLineInfo }

function TBaseLineInfo.GetSource(const AnIndex: integer): String;
begin
  Result := '';
end;

function TBaseLineInfo.IndexOf(const ASource: String): integer;
begin
  Result := -1;
end;

constructor TBaseLineInfo.Create;
begin
  inherited Create;
end;

function TBaseLineInfo.GetAddress(const AIndex: Integer; const ALine: Integer): TDbgPtr;
begin
  Result := 0;
end;

function TBaseLineInfo.GetAddress(const ASource: String; const ALine: Integer): TDbgPtr;
var
  idx: Integer;
begin
  idx := IndexOf(ASource);
  if idx = -1
  then Result := 0
  else Result := GetAddress(idx, ALine);
end;

function TBaseLineInfo.GetInfo(AAddress: TDbgPtr; out ASource, ALine, AOffset: Integer): Boolean;
begin
  Result := False;
end;

procedure TBaseLineInfo.Request(const ASource: String);
begin
end;

procedure TBaseLineInfo.Cancel(const ASource: String);
begin

end;

function TBaseLineInfo.Count: Integer;
begin
  Result := 0;
end;

{ TDBGLineInfo }

procedure TDBGLineInfo.Changed(ASource: String);
begin
  DoChange(ASource);
end;

procedure TDBGLineInfo.DoChange(ASource: String);
begin
  if Assigned(FOnChange) then FOnChange(Self, ASource);
end;

procedure TDBGLineInfo.DoStateChange(const AOldState: TDBGState);
begin
end;

constructor TDBGLineInfo.Create(const ADebugger: TDebuggerIntf);
begin
  inherited Create;
  FDebugger := ADebugger;
end;

{ TCallStackEntry }

function TCallStackEntry.GetArgumentCount: Integer;
begin
  Result := FArguments.Count;
end;

function TCallStackEntry.GetArgumentName(const AnIndex: Integer): String;
begin
  Result := FArguments.Names[AnIndex];
end;

function TCallStackEntry.GetArgumentValue(const AnIndex: Integer): String;
begin
  Result := FArguments[AnIndex];
  Result := GetPart('=', '', Result);
end;

function TCallStackEntry.GetFunctionName: String;
begin
  Result := FFunctionName;
end;

function TCallStackEntry.GetSource: String;
begin
  Result := '';
end;

function TCallStackEntry.GetValidity: TDebuggerDataState;
begin
  Result := FValidity;
end;

procedure TCallStackEntry.SetValidity(AValue: TDebuggerDataState);
begin
  FValidity := AValue;
end;

procedure TCallStackEntry.ClearLocation;
begin
  InitFields(0, 0, nil, '', 0, Validity);
  if Arguments <> nil then
    Arguments.Clear;
end;

procedure TCallStackEntry.InitFields(const AIndex: Integer; const AnAddress: TDbgPtr;
  const AnArguments: TStrings; const AFunctionName: String; const ALine: Integer;
  AValidity: TDebuggerDataState);
begin
  FIndex        := AIndex;
  FAddress      := AnAddress;
  if AnArguments <> nil
  then FArguments.Assign(AnArguments);
  FFunctionName := AFunctionName;
  FLine         := ALine;
  FValidity     := AValidity;
end;

constructor TCallStackEntry.Create;
begin
  inherited Create;
  FArguments := TStringlist.Create;
end;

function TCallStackEntry.CreateCopy: TCallStackEntry;
begin
  Result := TCallStackEntry.Create;
  Result.Assign(Self);
end;

destructor TCallStackEntry.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FArguments);
end;

procedure TCallStackEntry.Assign(AnOther: TCallStackEntry);
begin
  FValidity     := AnOther.FValidity;
  FIndex        := AnOther.FIndex;
  FAddress      := AnOther.FAddress;
  FFunctionName := AnOther.FFunctionName;
  FLine         := AnOther.FLine;
  FArguments.Assign(AnOther.FArguments);
end;

procedure TCallStackEntry.Init(const AnAddress: TDbgPtr; const AnArguments: TStrings;
  const AFunctionName: String; const AUnitName, AClassName, AProcName, AFunctionArgs: String;
  const ALine: Integer; AState: TDebuggerDataState);
begin
  InitFields(FIndex, AnAddress, AnArguments, AFunctionName, ALine, AState);
end;

procedure TCallStackEntry.Init(const AnAddress: TDbgPtr; const AnArguments: TStrings;
  const AFunctionName: String; const FileName, FullName: String; const ALine: Integer;
  AState: TDebuggerDataState);
begin
  InitFields(FIndex, AnAddress, AnArguments, AFunctionName, ALine, AState);
end;

function TCallStackEntry.GetFunctionWithArg: String;
var
  S: String;
  m: Integer;
begin
  S := '';
  for m := 0 to ArgumentCount - 1 do
  begin
    if S <> '' then
      S := S + ', ';
    S := S + ArgumentValues[m];
  end;
  if S <> '' then
    S := '(' + S + ')';
  Result := FunctionName + S;
end;

{ TCallStackList }

function TCallStackList.GetEntry(const AIndex: Integer): TCallStackBase;
begin
  Result := TCallStackBase(FList[AIndex]);
end;

function TCallStackList.GetEntryForThread(const AThreadId: Integer): TCallStackBase;
var
  i: Integer;
begin
  i := Count - 1;
  while (i >= 0) and (TCallStackBase(FList[i]).ThreadId <> AThreadId) do dec(i);
  if i >= 0
  then Result := TCallStackBase(FList[i])
  else Result := NewEntryForThread(AThreadId);
end;

function TCallStackList.NewEntryForThread(const AThreadId: Integer): TCallStackBase;
begin
  Result := nil;
end;

constructor TCallStackList.Create;
begin
  FList := TList.Create;
end;

destructor TCallStackList.Destroy;
begin
  inherited Destroy;
  Clear;
  FreeAndNil(FList);
end;

procedure TCallStackList.Assign(AnOther: TCallStackList);
var
  i: Integer;
begin
  Clear;
  for i := 0 to AnOther.FList.Count-1 do
    FList.Add(TCallStackBase(AnOther.FList[i]).CreateCopy);
end;

procedure TCallStackList.Add(ACallStack: TCallStackBase);
begin
  FList.Add(ACallStack);
end;

procedure TCallStackList.Clear;
begin
  while FList.Count > 0 do begin
    TObject(FList[0]).Free;
    FList.Delete(0);
  end;
end;

function TCallStackList.Count: Integer;
begin
  Result := FList.Count;
end;

{ TCallStackSupplier }

procedure TCallStackSupplier.Changed;
begin
  DebugLn(DBG_DATA_MONITORS, ['DebugDataMonitor: TCallStackSupplier.Changed']);
  Monitor.DoModified;
end;

function TCallStackSupplier.GetCurrentCallStackList: TCallStackList;
begin
  Result := nil;
  if Monitor <> nil then
    Result := Monitor.CallStackList;
end;

function TCallStackSupplier.GetMonitor: TCallStackMonitor;
begin
  Result := TCallStackMonitor(inherited Monitor);
end;

procedure TCallStackSupplier.SetMonitor(AValue: TCallStackMonitor);
begin
  inherited Monitor := AValue;
end;

procedure TCallStackSupplier.RequestCount(ACallstack: TCallStackBase);
begin
  ACallstack.SetCountValidity(ddsInvalid);
end;

procedure TCallStackSupplier.RequestAtLeastCount(ACallstack: TCallStackBase;
  ARequiredMinCount: Integer);
begin
  RequestCount(ACallstack);
end;

procedure TCallStackSupplier.RequestCurrent(ACallstack: TCallStackBase);
begin
  ACallstack.SetCurrentValidity(ddsInvalid);
end;

procedure TCallStackSupplier.RequestEntries(ACallstack: TCallStackBase);
var
  e: TCallStackEntry;
  It: TMapIterator;
begin
  DebugLn(DBG_DATA_MONITORS, ['DebugDataMonitor: TCallStackSupplier.RequestEntries']);
  It := TMapIterator.Create(ACallstack.RawEntries);

  if not It.Locate(ACallstack.LowestUnknown )
  then if not It.EOM
  then It.Next;

  while (not IT.EOM) and (TCallStackEntry(It.DataPtr^).Index < ACallstack.HighestUnknown)
  do begin
    e := TCallStackEntry(It.DataPtr^);
    if e.Validity = ddsRequested then e.Validity := ddsInvalid;
    It.Next;
  end;
  It.Free;

  if Monitor <> nil
  then Monitor.DoModified;
end;

//procedure TCallStackSupplier.CurrentChanged;
//begin
//  DebugLn(DBG_DATA_MONITORS, ['DebugDataMonitor: TCallStackSupplier.CurrentChanged']);
//  if Monitor <> nil
//  then Monitor.NotifyCurrent;
//end;

procedure TCallStackSupplier.UpdateCurrentIndex;
begin
  //
end;

{ TCallStackMonitor }

function TCallStackMonitor.GetSupplier: TCallStackSupplier;
begin
  Result := TCallStackSupplier(inherited Supplier);
end;

procedure TCallStackMonitor.SetSupplier(AValue: TCallStackSupplier);
begin
  inherited Supplier := AValue;
end;

function TCallStackMonitor.CreateCallStackList: TCallStackList;
begin
  Result := TCallStackList.Create;
end;

constructor TCallStackMonitor.Create;
begin
  FCallStackList := CreateCallStackList;
  inherited Create;
end;

destructor TCallStackMonitor.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FCallStackList);
end;

{ TThreadsSupplier }

procedure TThreadsSupplier.Changed;
begin
  if Monitor <> nil
  then Monitor.DoModified;
end;

function TThreadsSupplier.GetCurrentThreads: TThreads;
begin
  Result := nil;
  if Monitor <> nil then
    Result := Monitor.Threads;
end;

function TThreadsSupplier.GetMonitor: TThreadsMonitor;
begin
  Result := TThreadsMonitor(inherited Monitor);
end;

procedure TThreadsSupplier.SetMonitor(AValue: TThreadsMonitor);
begin
  inherited Monitor := AValue;
end;

procedure TThreadsSupplier.ChangeCurrentThread(ANewId: Integer);
begin
  //
end;

procedure TThreadsSupplier.RequestMasterData;
begin
  //
end;

procedure TThreadsSupplier.DoStateChange(const AOldState: TDBGState);
begin
  if (Debugger.State = dsStop) and (CurrentThreads <> nil) then
    CurrentThreads.Clear;
  inherited DoStateChange(AOldState);
end;

procedure TThreadsSupplier.DoStateLeavePauseClean;
begin
  DoCleanAfterPause;
end;

procedure TThreadsSupplier.DoCleanAfterPause;
begin
  if CurrentThreads <> nil then
    CurrentThreads.Clear;
  if Monitor <> nil then
    Monitor.DoModified;
end;

{ =========================================================================== }
{ TBaseSignal }
{ =========================================================================== }

procedure TBaseSignal.AssignTo(Dest: TPersistent);
begin
  if Dest is TBaseSignal
  then begin
    TBaseSignal(Dest).Name := FName;
    TBaseSignal(Dest).ID := FID;
    TBaseSignal(Dest).HandledByDebugger := FHandledByDebugger;
    TBaseSignal(Dest).ResumeHandled := FResumeHandled;
  end
  else inherited AssignTo(Dest);
end;

constructor TBaseSignal.Create(ACollection: TCollection);
begin
  FID := 0;
  FHandledByDebugger := False;
  FResumeHandled := True;
  inherited Create(ACollection);
end;

procedure TBaseSignal.SetHandledByDebugger(const AValue: Boolean);
begin
  if AValue = FHandledByDebugger then Exit;
  FHandledByDebugger := AValue;
  Changed;
end;

procedure TBaseSignal.SetID (const AValue: Integer );
begin
  if FID = AValue then Exit;
  FID := AValue;
  Changed;
end;

procedure TBaseSignal.SetName (const AValue: String );
begin
  if FName = AValue then Exit;
  FName := AValue;
  Changed;
end;

procedure TBaseSignal.SetResumeHandled(const AValue: Boolean);
begin
  if FResumeHandled = AValue then Exit;
  FResumeHandled := AValue;
  Changed;
end;

{ =========================================================================== }
{ TDBGSignal }
{ =========================================================================== }

function TDBGSignal.GetDebugger: TDebuggerIntf;
begin
  Result := TDBGSignals(Collection).FDebugger;
end;

{ =========================================================================== }
{ TBaseSignals }
{ =========================================================================== }

function TBaseSignals.Add (const AName: String; AID: Integer ): TBaseSignal;
begin
  Result := TBaseSignal(inherited Add);
  Result.BeginUpdate;
  try
    Result.Name := AName;
    Result.ID := AID;
  finally
    Result.EndUpdate;
  end;
end;

constructor TBaseSignals.Create (const AItemClass: TBaseSignalClass );
begin
  inherited Create(AItemClass);
end;

procedure TBaseSignals.Reset;
begin
  Clear;
end;

function TBaseSignals.Find(const AName: String): TBaseSignal;
var
  n: Integer;
  S: String;
begin
  S := UpperCase(AName);
  for n := 0 to Count - 1 do
  begin
    Result := TBaseSignal(GetItem(n));
    if UpperCase(Result.Name) = S
    then Exit;
  end;
  Result := nil;
end;

{ =========================================================================== }
{ TDBGSignals }
{ =========================================================================== }

function TDBGSignals.Add(const AName: String; AID: Integer): TDBGSignal;
begin
  Result := TDBGSignal(inherited Add(AName, AID));
end;

constructor TDBGSignals.Create(const ADebugger: TDebuggerIntf;
  const ASignalClass: TDBGSignalClass);
begin
  FDebugger := ADebugger;
  inherited Create(ASignalClass);
end;

function TDBGSignals.Find(const AName: String): TDBGSignal;
begin
  Result := TDBGSignal(inherited Find(ANAme));
end;

function TDBGSignals.GetItem(const AIndex: Integer): TDBGSignal;
begin
  Result := TDBGSignal(inherited GetItem(AIndex));
end;

procedure TDBGSignals.SetItem(const AIndex: Integer; const AValue: TDBGSignal);
begin
  inherited SetItem(AIndex, AValue);
end;

{ =========================================================================== }
{ TBaseException }
{ =========================================================================== }

procedure TBaseException.SetEnabled(AValue: Boolean);
begin
  if FEnabled = AValue then Exit;
  FEnabled := AValue;
  Changed;
end;

procedure TBaseException.AssignTo(Dest: TPersistent);
begin
  if Dest is TBaseException
  then begin
    TBaseException(Dest).Name := FName;
  end
  else inherited AssignTo(Dest);
end;

constructor TBaseException.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
end;

procedure TBaseException.SetName(const AValue: String);
begin
  if FName = AValue then exit;

  if TBaseExceptions(GetOwner).Find(AValue) <> nil
  then raise EDBGExceptions.Create('Duplicate name: ' + AValue);

  FName := AValue;
  Changed;
end;

{ =========================================================================== }
{ TBaseExceptions }
{ =========================================================================== }

function TBaseExceptions.Add(const AName: String): TBaseException;
begin
  Result := TBaseException(inherited Add);
  Result.Name := AName;
end;

constructor TBaseExceptions.Create(const AItemClass: TBaseExceptionClass);
begin
  inherited Create(AItemClass);
  FIgnoreAll := False;
end;

destructor TBaseExceptions.Destroy;
begin
  ClearExceptions;
  inherited Destroy;
end;

procedure TBaseExceptions.Reset;
begin
  ClearExceptions;
  FIgnoreAll := False;
end;

function TBaseExceptions.Find(const AName: String): TBaseException;
var
  n: Integer;
  S: String;
begin
  S := UpperCase(AName);
  for n := 0 to Count - 1 do
  begin
    Result := TBaseException(GetItem(n));
    if UpperCase(Result.Name) = S
    then Exit;
  end;
  Result := nil;
end;

function TBaseExceptions.GetItem(const AIndex: Integer): TBaseException;
begin
  Result := TBaseException(inherited GetItem(AIndex));
end;

procedure TBaseExceptions.SetItem(const AIndex: Integer; AValue: TBaseException);
begin
  inherited SetItem(AIndex, AValue);
end;

procedure TBaseExceptions.ClearExceptions;
begin
  while Count>0 do
    TBaseException(GetItem(Count-1)).Free;
end;

procedure TBaseExceptions.SetIgnoreAll(const AValue: Boolean);
begin
  if FIgnoreAll = AValue then exit;
  FIgnoreAll := AValue;
  Changed;
end;

procedure TBaseExceptions.AssignTo(Dest: TPersistent);
begin
  if Dest is TBaseExceptions
  then begin
    TBaseExceptions(Dest).IgnoreAll := IgnoreAll;
  end
  else inherited AssignTo(Dest);
end;

{ TBaseDisassembler }

procedure TBaseDisassembler.IndexError(AIndex: Integer);
begin
  raise EInvalidOperation.CreateFmt('Index out of range (%d)', [AIndex]);
end;

function TBaseDisassembler.GetEntryPtr(AIndex: Integer): PDisassemblerEntry;
begin
  if (AIndex < -FCountBefore)
  or (AIndex >= FCountAfter) then IndexError(Aindex);

  Result := InternalGetEntryPtr(AIndex);
end;

function TBaseDisassembler.GetEntry(AIndex: Integer): TDisassemblerEntry;
begin
  if (AIndex < -FCountBefore)
  or (AIndex >= FCountAfter) then IndexError(Aindex);

  Result := InternalGetEntry(AIndex);
end;

function TBaseDisassembler.InternalGetEntry(AIndex: Integer): TDisassemblerEntry;
begin
  Result.Addr := 0;
  Result.Offset := 0;
  Result.SrcFileLine := 0;
  Result.SrcStatementIndex := 0;
  Result.SrcStatementCount := 0;
end;

function TBaseDisassembler.InternalGetEntryPtr(AIndex: Integer): PDisassemblerEntry;
begin
  Result := nil;
end;

procedure TBaseDisassembler.DoChanged;
begin
  // nothing
end;

procedure TBaseDisassembler.Changed;
begin
  if FChangedLockCount > 0
  then begin
    FIsChanged := True;
    exit;
  end;
  FIsChanged := False;
  DoChanged;
end;

procedure TBaseDisassembler.LockChanged;
begin
  inc(FChangedLockCount);
end;

procedure TBaseDisassembler.UnlockChanged;
begin
  dec(FChangedLockCount);
  if FIsChanged and (FChangedLockCount = 0)
  then Changed;
end;

procedure TBaseDisassembler.InternalIncreaseCountBefore(ACount: Integer);
begin
  // increase count withou change notification
  if ACount < FCountBefore
  then begin
    debugln(DBG_DISASSEMBLER, ['WARNING: TBaseDisassembler.InternalIncreaseCountBefore will decrease was ', FCountBefore , ' new=',ACount]);
    SetCountBefore(ACount);
  end
  else FCountBefore := ACount;
end;

procedure TBaseDisassembler.InternalIncreaseCountAfter(ACount: Integer);
begin
  // increase count withou change notification
  if ACount < FCountAfter
  then begin
    debugln(DBG_DISASSEMBLER, ['WARNING: TBaseDisassembler.InternalIncreaseCountAfter will decrease was ', FCountAfter , ' new=',ACount]);
    SetCountAfter(ACount)
  end
  else FCountAfter := ACount;
end;

procedure TBaseDisassembler.SetCountBefore(ACount: Integer);
begin
  if FCountBefore = ACount
  then exit;
  FCountBefore := ACount;
  Changed;
end;

procedure TBaseDisassembler.SetCountAfter(ACount: Integer);
begin
  if FCountAfter = ACount
  then exit;
  FCountAfter := ACount;
  Changed;
end;

procedure TBaseDisassembler.SetBaseAddr(AnAddr: TDbgPtr);
begin
  if FBaseAddr = AnAddr
  then exit;
  FBaseAddr := AnAddr;
  Changed;
end;

constructor TBaseDisassembler.Create;
begin
  Clear;
  FChangedLockCount := 0;
end;

destructor TBaseDisassembler.Destroy;
begin
  inherited Destroy;
  Clear;
end;

procedure TBaseDisassembler.Clear;
begin
  FCountAfter := 0;
  FCountBefore := 0;
  FBaseAddr := 0;
end;

function TBaseDisassembler.PrepareRange(AnAddr: TDbgPtr; ALinesBefore,
  ALinesAfter: Integer): Boolean;
begin
  Result := False;
end;

{ TDBGDisassemblerEntryRange }

function TDBGDisassemblerEntryRange.GetEntry(Index: Integer): TDisassemblerEntry;
begin
  if (Index < 0) or (Index >= FCount)
  then raise Exception.Create('Illegal Index');
  Result := FEntries[Index];
end;

function TDBGDisassemblerEntryRange.GetCapacity: Integer;
begin
  Result := length(FEntries);
end;

function TDBGDisassemblerEntryRange.GetEntryPtr(Index: Integer): PDisassemblerEntry;
begin
  if (Index < 0) or (Index >= FCount)
  then raise Exception.Create('Illegal Index');
  Result := @FEntries[Index];
end;

procedure TDBGDisassemblerEntryRange.SetCapacity(const AValue: Integer);
begin
  SetLength(FEntries, AValue);
  if FCount >= AValue
  then FCount := AValue - 1;
end;

procedure TDBGDisassemblerEntryRange.SetCount(const AValue: Integer);
begin
  if FCount = AValue then exit;
  if AValue >= Capacity
  then Capacity := AValue + Max(20, AValue div 4);

  FCount := AValue;
end;

procedure TDBGDisassemblerEntryRange.Clear;
begin
  SetCapacity(0);
  FCount := 0;
end;

function TDBGDisassemblerEntryRange.Append(const AnEntryPtr: PDisassemblerEntry): Integer;
begin
  if FCount >= Capacity
  then Capacity := FCount + Max(20,FCount div 4);

  FEntries[FCount] := AnEntryPtr^;
  Result := FCount;
  inc(FCount);
end;

procedure TDBGDisassemblerEntryRange.Merge(const AnotherRange: TDBGDisassemblerEntryRange);
var
  i, j: Integer;
  a: TDBGPtr;
begin
  if AnotherRange.RangeStartAddr < RangeStartAddr then
  begin
    // merge before
    i := AnotherRange.Count - 1;
    a := FirstAddr;
    while (i >= 0) and (AnotherRange.EntriesPtr[i]^.Addr >= a)
    do dec(i);
    inc(i);
    debugln(DBG_DISASSEMBLER, ['INFO: TDBGDisassemblerEntryRange.Merge: Merged to START:   Other=', dbgs(AnotherRange), '  To other index=', i, ' INTO self=', dbgs(self) ]);
    if Capacity < Count + i
    then Capacity := Count + i;
    for j := Count-1 downto 0 do
      FEntries[j+i] := FEntries[j];
    for j := 0 to i - 1 do
      FEntries[j] := AnotherRange.FEntries[j];
    FCount := FCount + i;
    FRangeStartAddr := AnotherRange.FRangeStartAddr;
  end
  else begin
    // merge after
    a:= LastAddr;
    i := 0;
    while (i < AnotherRange.Count) and (AnotherRange.EntriesPtr[i]^.Addr <= a)
    do inc(i);
    debugln(DBG_DISASSEMBLER, ['INFO: TDBGDisassemblerEntryRange.Merge to END:   Other=', dbgs(AnotherRange), '  From other index=', i, ' INTO self=', dbgs(self) ]);
    if Capacity < Count + AnotherRange.Count - i
    then Capacity := Count + AnotherRange.Count - i;
    for j := 0 to AnotherRange.Count - i - 1 do
      FEntries[Count + j] := AnotherRange.FEntries[i + j];
    FCount := FCount + AnotherRange.Count - i;
    FRangeEndAddr := AnotherRange.FRangeEndAddr;
    FLastEntryEndAddr := AnotherRange.FLastEntryEndAddr;
  end;
  debugln(DBG_DISASSEMBLER, ['INFO: TDBGDisassemblerEntryRange.Merge AFTER MERGE: ', dbgs(self) ]);
end;

function TDBGDisassemblerEntryRange.FirstAddr: TDbgPtr;
begin
  if FCount = 0
  then exit(0);
  Result := FEntries[0].Addr;
end;

function TDBGDisassemblerEntryRange.LastAddr: TDbgPtr;
begin
  if FCount = 0
  then exit(0);
  Result := FEntries[FCount-1].Addr;
end;

function TDBGDisassemblerEntryRange.ContainsAddr(const AnAddr: TDbgPtr;
  IncludeNextAddr: Boolean = False): Boolean;
begin
  if IncludeNextAddr
  then  Result := (AnAddr >= RangeStartAddr) and (AnAddr <= RangeEndAddr)
  else  Result := (AnAddr >= RangeStartAddr) and (AnAddr < RangeEndAddr);
end;

function TDBGDisassemblerEntryRange.IndexOfAddr(const AnAddr: TDbgPtr): Integer;
begin
  Result := FCount - 1;
  while Result >= 0 do begin
    if FEntries[Result].Addr = AnAddr
    then exit;
    dec(Result);
  end;
end;

function TDBGDisassemblerEntryRange.IndexOfAddrWithOffs(const AnAddr: TDbgPtr): Integer;
var
  O: Integer;
begin
  Result := IndexOfAddrWithOffs(AnAddr, O);
end;

function TDBGDisassemblerEntryRange.IndexOfAddrWithOffs(const AnAddr: TDbgPtr; out
  AOffs: Integer): Integer;
begin
  Result := FCount - 1;
  while Result >= 0 do begin
    if FEntries[Result].Addr <= AnAddr
    then break;
    dec(Result);
  end;
  If Result < 0
  then AOffs := 0
  else AOffs := AnAddr - FEntries[Result].Addr;
end;

{ TDBGDisassemblerEntryMapIterator }

function TDBGDisassemblerEntryMapIterator.GetRangeForAddr(AnAddr: TDbgPtr;
  IncludeNextAddr: Boolean): TDBGDisassemblerEntryRange;
begin
  Result := nil;
  if not Locate(AnAddr)
  then if not BOM
  then Previous;

  if BOM
  then exit;

  GetData(Result);
  if not Result.ContainsAddr(AnAddr, IncludeNextAddr)
  then Result := nil;
end;

function TDBGDisassemblerEntryMapIterator.NextRange: TDBGDisassemblerEntryRange;
begin
  Result := nil;
  if EOM
  then exit;

  Next;
  if not EOM
  then GetData(Result);
end;

function TDBGDisassemblerEntryMapIterator.PreviousRange: TDBGDisassemblerEntryRange;
begin
  Result := nil;
  if BOM
  then exit;

  Previous;
  if not BOM
  then GetData(Result);
end;

{ TDBGDisassemblerEntryMap }

procedure TDBGDisassemblerEntryMap.ReleaseData(ADataPtr: Pointer);
type
  PDBGDisassemblerEntryRange = ^TDBGDisassemblerEntryRange;
begin
  if FFreeItemLock
  then exit;
  if Assigned(FOnDelete)
  then FOnDelete(PDBGDisassemblerEntryRange(ADataPtr)^);
  PDBGDisassemblerEntryRange(ADataPtr)^.Free;
end;

constructor TDBGDisassemblerEntryMap.Create(AIdType: TMapIdType; ADataSize: Cardinal);
begin
  inherited;
  FIterator := TDBGDisassemblerEntryMapIterator.Create(Self);
end;

destructor TDBGDisassemblerEntryMap.Destroy;
begin
  FreeAndNil(FIterator);
  inherited Destroy;
end;

procedure TDBGDisassemblerEntryMap.AddRange(const ARange: TDBGDisassemblerEntryRange);
var
  MergeRng, MergeRng2: TDBGDisassemblerEntryRange;
  OldId: TDBGPtr;
begin
  debugln(DBG_DISASSEMBLER, ['INFO: TDBGDisassemblerEntryMap.AddRange ', dbgs(ARange), ' to map with count=', Count ]);
  if ARange.Count = 0 then begin
    ARange.Free;
    exit;
  end;

  MergeRng := GetRangeForAddr(ARange.RangeStartAddr, True);
  if MergeRng <> nil then begin
    // merge to end ( ARange.RangeStartAddr >= MergeRng.RangeStartAddr )
    // MergeRng keeps it's ID;
    MergeRng.Merge(ARange);
    if assigned(FOnMerge)
    then FOnMerge(MergeRng, ARange);
    ARange.Free;

    MergeRng2 := GetRangeForAddr(MergeRng.RangeEndAddr, True);
    if (MergeRng2 <> nil) and (MergeRng2 <> MergeRng) then begin
      // MergeRng is located before MergeRng2
      // MergeRng2 merges to end of MergeRng ( No ID changes )
      MergeRng.Merge(MergeRng2);
      if assigned(FOnMerge)
      then FOnMerge(MergeRng, MergeRng2);
      Delete(MergeRng2.RangeStartAddr);
    end;
    exit;
  end;

  MergeRng := GetRangeForAddr(ARange.RangeEndAddr, True);
  if MergeRng <> nil then begin
    // merge to start ( ARange.RangeEndAddr is in MergeRng )
    if MergeRng.ContainsAddr(ARange.RangeStartAddr)
    then begin
      debugln(['ERROR: New Range is completely inside existing ', dbgs(MergeRng)]);
      exit;
    end;
    // MergeRng changes ID
    OldId := MergeRng.RangeStartAddr;
    MergeRng.Merge(ARange);
    if assigned(FOnMerge)
    then FOnMerge(ARange, MergeRng);
    FFreeItemLock := True; // prevent destruction of MergeRng
    Delete(OldId);
    FFreeItemLock := False;
    Add(MergeRng.RangeStartAddr, MergeRng);
    ARange.Free;
    exit;
  end;

  Add(ARange.RangeStartAddr, ARange);
end;

function TDBGDisassemblerEntryMap.GetRangeForAddr(AnAddr: TDbgPtr;
  IncludeNextAddr: Boolean = False): TDBGDisassemblerEntryRange;
begin
  Result := FIterator.GetRangeForAddr(AnAddr, IncludeNextAddr);
end;

{ TDBGDisassembler }

procedure TDBGDisassembler.EntryRangesOnDelete(Sender: TObject);
begin
  if FCurrentRange <> Sender
  then exit;
  LockChanged;
  FCurrentRange := nil;
  SetBaseAddr(0);
  SetCountBefore(0);
  SetCountAfter(0);
  UnlockChanged;
end;

procedure TDBGDisassembler.EntryRangesOnMerge(MergeReceiver,
  MergeGiver: TDBGDisassemblerEntryRange);
var
  i: LongInt;
  lb, la: Integer;
begin
  // no need to call changed, will be done by whoever triggered this
  if FCurrentRange = MergeGiver
  then FCurrentRange := MergeReceiver;

  if FCurrentRange = MergeReceiver
  then begin
    i := FCurrentRange.IndexOfAddrWithOffs(BaseAddr);
    if i >= 0
    then begin
      InternalIncreaseCountBefore(i);
      InternalIncreaseCountAfter(FCurrentRange.Count - 1 - i);
      exit;
    end
    else if FCurrentRange.ContainsAddr(BaseAddr)
    then begin
      debugln(DBG_DISASSEMBLER, ['WARNING: TDBGDisassembler.OnMerge: Address at odd offset ',BaseAddr, ' before=',CountBefore, ' after=', CountAfter]);
      lb := CountBefore;
      la := CountAfter;
      if HandleRangeWithInvalidAddr(FCurrentRange, BaseAddr, lb, la)
      then begin
        InternalIncreaseCountBefore(lb);
        InternalIncreaseCountAfter(la);
        exit;
      end;
    end;

    LockChanged;
    SetBaseAddr(0);
    SetCountBefore(0);
    SetCountAfter(0);
    UnlockChanged;
  end;
end;

function TDBGDisassembler.FindRange(AnAddr: TDbgPtr; ALinesBefore,
  ALinesAfter: Integer): Boolean;
var
  i: LongInt;
  NewRange: TDBGDisassemblerEntryRange;
begin
  LockChanged;
  try
    Result := False;
    NewRange := FEntryRanges.GetRangeForAddr(AnAddr);

    if (NewRange <> nil)
    and ( (NewRange.RangeStartAddr > AnAddr) or (NewRange.RangeEndAddr < AnAddr) )
    then
      NewRange := nil;

    if NewRange = nil
    then begin
      debugln(DBG_DISASSEMBLER, ['INFO: TDBGDisassembler.FindRange: Address not found ', AnAddr, ' wanted-before=',ALinesBefore,' wanted-after=',ALinesAfter,' in map with count=', FEntryRanges.Count ]);
      exit;
    end;

    i := NewRange.IndexOfAddr(AnAddr);
    if i < 0
    then begin
      // address at incorrect offset
      Result := HandleRangeWithInvalidAddr(NewRange, AnAddr, ALinesBefore, ALinesAfter);
      debugln(DBG_DISASSEMBLER, ['WARNING: TDBGDisassembler.FindRange: Address at odd offset ',AnAddr,'  Result=', dbgs(result), ' before=',CountBefore, ' after=', CountAfter, ' wanted-before=',ALinesBefore,' wanted-after=',ALinesAfter,' in map with count=', FEntryRanges.Count]);
      if Result
      then begin
        FCurrentRange := NewRange;
        SetBaseAddr(AnAddr);
        SetCountBefore(ALinesBefore);
        SetCountAfter(ALinesAfter);
      end;
      exit;
    end;

    FCurrentRange := NewRange;
    SetBaseAddr(AnAddr);
    SetCountBefore(i);
    SetCountAfter(NewRange.Count - 1 - i);
    Result := (i >= ALinesBefore) and (CountAfter >= ALinesAfter);
    debugln(DBG_DISASSEMBLER, ['INFO: TDBGDisassembler.FindRange: Address found ',AnAddr,' Result=', dbgs(result), ' before=',CountBefore, ' after=', CountAfter, ' wanted-before=',ALinesBefore,' wanted-after=',ALinesAfter,' in map with count=', FEntryRanges.Count]);
  finally
    UnlockChanged;
  end;
end;

procedure TDBGDisassembler.DoChanged;
begin
  inherited DoChanged;
  if assigned(FOnChange)
  then FOnChange(Self);
end;

procedure TDBGDisassembler.Clear;
begin
  debugln(DBG_DISASSEMBLER, ['INFO: TDBGDisassembler.Clear:  map had count=', FEntryRanges.Count ]);
  FCurrentRange := nil;
  FEntryRanges.Clear;
  inherited Clear;
  Changed;
end;

procedure TDBGDisassembler.DoStateChange(const AOldState: TDBGState);
begin
  if FDebugger.State = dsPause
  then begin
    Changed;
  end
  else begin
    if (AOldState = dsPause) or (AOldState = dsNone) { Force clear on initialisation }
    then Clear;
  end;
end;

function TDBGDisassembler.InternalGetEntry(AIndex: Integer): TDisassemblerEntry;
begin
  Result := FCurrentRange.Entries[AIndex + CountBefore];
end;

function TDBGDisassembler.InternalGetEntryPtr(AIndex: Integer): PDisassemblerEntry;
begin
  Result := FCurrentRange.EntriesPtr[AIndex + CountBefore];
end;

function TDBGDisassembler.PrepareEntries(AnAddr: TDbgPtr; ALinesBefore,
  ALinesAfter: Integer): boolean;
begin
  Result := False;
end;

function TDBGDisassembler.HandleRangeWithInvalidAddr(ARange: TDBGDisassemblerEntryRange;
  AnAddr: TDbgPtr; var ALinesBefore, ALinesAfter: Integer): boolean;
begin
  Result := False;
  if ARange <> nil then
    FEntryRanges.Delete(ARange.RangeStartAddr);
end;

constructor TDBGDisassembler.Create(const ADebugger: TDebuggerIntf);
begin
  FDebugger := ADebugger;
  FEntryRanges := TDBGDisassemblerEntryMap.Create(itu8, SizeOf(TDBGDisassemblerEntryRange));
  FEntryRanges.OnDelete   := @EntryRangesOnDelete;
  FEntryRanges.OnMerge   := @EntryRangesOnMerge;
  inherited Create;
end;

destructor TDBGDisassembler.Destroy;
begin
  inherited Destroy;
  FEntryRanges.OnDelete := nil;
  Clear;
  FreeAndNil(FEntryRanges);
end;

function TDBGDisassembler.PrepareRange(AnAddr: TDbgPtr; ALinesBefore,
  ALinesAfter: Integer): Boolean;
begin
  Result := False;
  if (Debugger = nil) or (Debugger.State <> dsPause) or (AnAddr = 0)
  then exit;
  if (ALinesBefore < 0) or (ALinesAfter < 0)
  then raise Exception.Create('invalid PrepareRange request');

  // Do not LockChange, if FindRange changes something, then notification must be send to syncronize counts on IDE-object
  Result:= FindRange(AnAddr, ALinesBefore, ALinesAfter);
  if result then debugln(DBG_DISASSEMBLER, ['INFO: TDBGDisassembler.PrepareRange  found existing data  Addr=', AnAddr,' before=', ALinesBefore, ' After=', ALinesAfter ]);
  if Result
  then exit;

  if result then debugln(DBG_DISASSEMBLER, ['INFO: TDBGDisassembler.PrepareRange  calling PrepareEntries Addr=', AnAddr,' before=', ALinesBefore, ' After=', ALinesAfter ]);
  if PrepareEntries(AnAddr, ALinesBefore, ALinesAfter)
  then Result:= FindRange(AnAddr, ALinesBefore, ALinesAfter);
  if result then debugln(DBG_DISASSEMBLER, ['INFO: TDBGDisassembler.PrepareRange  found data AFTER PrepareEntries Addr=', AnAddr,' before=', ALinesBefore, ' After=', ALinesAfter ]);
end;

(******************************************************************************)
(******************************************************************************)
(**                                                                          **)
(**   D E B U G G E R                                                        **)
(**                                                                          **)
(******************************************************************************)
(******************************************************************************)

{ TDebuggerProperties }

constructor TDebuggerProperties.Create;
begin
  //
end;

procedure TDebuggerProperties.Assign(Source: TPersistent);
begin
  //
end;

{ =========================================================================== }
{ TDebuggerIntf }
{ =========================================================================== }

class function TDebuggerIntf.Caption: String;
begin
  Result := 'No caption set';
end;

function TDebuggerIntf.ChangeFileName: Boolean;
begin
  Result := True;
end;

constructor TDebuggerIntf.Create(const AExternalDebugger: String);
var
  list: TStringList;
  nr: TDebuggerNotifyReason;
begin
  inherited Create;
  for nr := low(TDebuggerNotifyReason) to high(TDebuggerNotifyReason) do
    FDestroyNotificationList[nr] := TMethodList.Create;
  FOnState := nil;
  FOnCurrent := nil;
  FOnOutput := nil;
  FOnDbgOutput := nil;
  FState := dsNone;
  FArguments := '';
  FFilename := '';
  FExternalDebugger := AExternalDebugger;

  list := TStringList.Create;
  list.OnChange := @DebuggerEnvironmentChanged;
  FDebuggerEnvironment := list;

  list := TStringList.Create;
  list.OnChange := @EnvironmentChanged;
  FEnvironment := list;
  FCurEnvironment := TStringList.Create;
  //FInternalUnitInfoProvider := TDebuggerUnitInfoProvider.Create;

  FBreakPoints := CreateBreakPoints;
  FLocals := CreateLocals;
  FLineInfo := CreateLineInfo;
  FRegisters := CreateRegisters;
  FCallStack := CreateCallStack;
  FDisassembler := CreateDisassembler;
  FWatches := CreateWatches;
  FThreads := CreateThreads;
  FSignals := CreateSignals;
  FExitCode := 0;
end;

function TDebuggerIntf.CreateBreakPoints: TDBGBreakPoints;
begin
  Result := TDBGBreakPoints.Create(Self, TDBGBreakPoint);
end;

function TDebuggerIntf.CreateCallStack: TCallStackSupplier;
begin
  Result := TCallStackSupplier.Create(Self);
end;

function TDebuggerIntf.CreateDisassembler: TDBGDisassembler;
begin
  Result := TDBGDisassembler.Create(Self);
end;

function TDebuggerIntf.CreateLocals: TLocalsSupplier;
begin
  Result := TLocalsSupplier.Create(Self);
end;

function TDebuggerIntf.CreateLineInfo: TDBGLineInfo;
begin
  Result := TDBGLineInfo.Create(Self);
end;

class function TDebuggerIntf.CreateProperties: TDebuggerProperties;
begin
  Result := TDebuggerProperties.Create;
end;

function TDebuggerIntf.CreateRegisters: TRegisterSupplier;
begin
  Result := TRegisterSupplier.Create(Self);
end;

function TDebuggerIntf.CreateSignals: TDBGSignals;
begin
  Result := TDBGSignals.Create(Self, TDBGSignal);
end;

function TDebuggerIntf.CreateWatches: TWatchesSupplier;
begin
  Result := TWatchesSupplier.Create(Self);
end;

function TDebuggerIntf.CreateThreads: TThreadsSupplier;
begin
  Result := TThreadsSupplier.Create(Self);
end;

procedure TDebuggerIntf.DebuggerEnvironmentChanged (Sender: TObject );
begin
end;

destructor TDebuggerIntf.Destroy;
var
  nr: TDebuggerNotifyReason;
begin
  FDestroyNotificationList[dnrDestroy].CallNotifyEvents(Self);
  for nr := low(TDebuggerNotifyReason) to high(TDebuggerNotifyReason) do
    FreeAndNil(FDestroyNotificationList[nr]);
  // don't call events
  FOnState := nil;
  FOnCurrent := nil;
  FOnOutput := nil;
  FOnDbgOutput := nil;

  if FState <> dsNone
  then Done;

  FBreakPoints.Debugger := nil;
  FLocals.Debugger := nil;
  FLineInfo.Debugger := nil;
  FRegisters.Debugger := nil;
  FCallStack.Debugger := nil;
  FDisassembler.Debugger := nil;
  FWatches.Debugger := nil;
  FThreads.Debugger := nil;

  //FreeAndNil(FInternalUnitInfoProvider);
  FreeAndNil(FBreakPoints);
  FreeAndNil(FLocals);
  FreeAndNil(FLineInfo);
  FreeAndNil(FRegisters);
  FreeAndNil(FCallStack);
  FreeAndNil(FDisassembler);
  FreeAndNil(FWatches);
  FreeAndNil(FThreads);
  FreeAndNil(FDebuggerEnvironment);
  FreeAndNil(FEnvironment);
  FreeAndNil(FCurEnvironment);
  FreeAndNil(FSignals);
  inherited;
end;

function TDebuggerIntf.Disassemble(AAddr: TDbgPtr; ABackward: Boolean; out ANextAddr: TDbgPtr; out ADump, AStatement, AFile: String; out ALine: Integer): Boolean;
begin
  Result := ReqCmd(dcDisassemble, [AAddr, ABackward, @ANextAddr, @ADump, @AStatement, @AFile, @ALine]);
end;

function TDebuggerIntf.GetLocation: TDBGLocationRec;
begin
  Result.Address := 0;
  Result.SrcLine := 0;
end;

procedure TDebuggerIntf.LockCommandProcessing;
begin
  // nothing
end;

procedure TDebuggerIntf.UnLockCommandProcessing;
begin
  // nothing
end;

function TDebuggerIntf.NeedReset: Boolean;
begin
  Result := False;
end;

procedure TDebuggerIntf.AddNotifyEvent(AReason: TDebuggerNotifyReason; AnEvent: TNotifyEvent);
begin
  FDestroyNotificationList[AReason].Add(TMethod(AnEvent));
end;

procedure TDebuggerIntf.RemoveNotifyEvent(AReason: TDebuggerNotifyReason; AnEvent: TNotifyEvent);
begin
  FDestroyNotificationList[AReason].Remove(TMethod(AnEvent));
end;

procedure TDebuggerIntf.Done;
begin
  SetState(dsNone);
  FEnvironment.Clear;
  FCurEnvironment.Clear;
end;

procedure TDebuggerIntf.Release;
begin
  if Self <> nil
  then Self.DoRelease;
end;

procedure TDebuggerIntf.DoCurrent(const ALocation: TDBGLocationRec);
begin
  DebugLnEnter(DBG_EVENTS, ['DebugEvent: Enter >> DoCurrent (Location)  >>  State=', dbgs(FState)]);
  if Assigned(FOnCurrent) then FOnCurrent(Self, ALocation);
  DebugLnExit(DBG_EVENTS, ['DebugEvent: Exit  << DoCurrent (Location)  <<']);
end;

procedure TDebuggerIntf.DoDbgOutput(const AText: String);
begin
  // WriteLN(' [TDebuggerIntf] ', AText);
  if Assigned(FOnDbgOutput) then FOnDbgOutput(Self, AText);
end;

procedure TDebuggerIntf.DoDbgEvent(const ACategory: TDBGEventCategory; const AEventType: TDBGEventType; const AText: String);
begin
  DebugLnEnter(DBG_EVENTS, ['DebugEvent: Enter >> DoDbgEvent >>  State=', dbgs(FState), ' Category=', dbgs(ACategory)]);
  if Assigned(FOnDbgEvent) then FOnDbgEvent(Self, ACategory, AEventType, AText);
  DebugLnExit(DBG_EVENTS, ['DebugEvent: Exit  << DoDbgEvent <<']);
end;

procedure TDebuggerIntf.DoException(const AExceptionType: TDBGExceptionType;
  const AExceptionClass: String; const AExceptionLocation: TDBGLocationRec; const AExceptionText: String; out AContinue: Boolean);
begin
  DebugLnEnter(DBG_EVENTS, ['DebugEvent: Enter >> DoException >>  State=', dbgs(FState)]);
  if AExceptionType = deInternal then
    DoDbgEvent(ecDebugger, etExceptionRaised,
               Format('Exception class "%s" at $%.' + IntToStr(TargetWidth div 4) + 'x with message "%s"',
                      [AExceptionClass, AExceptionLocation.Address, AExceptionText]));
  if Assigned(FOnException) then
    FOnException(Self, AExceptionType, AExceptionClass, AExceptionLocation, AExceptionText, AContinue)
  else
    AContinue := True;
  DebugLnExit(DBG_EVENTS, ['DebugEvent: Exit  << DoException <<']);
end;

procedure TDebuggerIntf.DoOutput(const AText: String);
begin
  if Assigned(FOnOutput) then FOnOutput(Self, AText);
end;

procedure TDebuggerIntf.DoBreakpointHit(const ABreakPoint: TBaseBreakPoint; var ACanContinue: Boolean);
begin
  DebugLnEnter(DBG_EVENTS, ['DebugEvent: Enter >> DoBreakpointHit <<  State=', dbgs(FState)]);
  if Assigned(FOnBreakpointHit)
  then FOnBreakpointHit(Self, ABreakPoint, ACanContinue);
  DebugLnExit(DBG_EVENTS, ['DebugEvent: Exit  >> DoBreakpointHit <<']);
end;

procedure TDebuggerIntf.DoBeforeState(const OldState: TDBGState);
begin
  DebugLnEnter(DBG_STATE_EVENT, ['DebugEvent: Enter >> DoBeforeState <<  State=', dbgs(FState)]);
  if Assigned(FOnBeforeState) then FOnBeforeState(Self, OldState);
  DebugLnExit(DBG_STATE_EVENT, ['DebugEvent: Exit  >> DoBeforeState <<']);
end;

procedure TDebuggerIntf.DoState(const OldState: TDBGState);
begin
  DebugLnEnter(DBG_STATE_EVENT, ['DebugEvent: Enter >> DoState <<  State=', dbgs(FState)]);
  if Assigned(FOnState) then FOnState(Self, OldState);
  DebugLnExit(DBG_STATE_EVENT, ['DebugEvent: Exit  >> DoState <<']);
end;

procedure TDebuggerIntf.EnvironmentChanged(Sender: TObject);
var
  n, idx: integer;
  S: String;
  Env: TStringList;
begin
  // Createe local copy
  if FState <> dsNone then
  begin
    Env := TStringList.Create;
    try
      Env.Assign(Environment);

      // Check for nonexisting and unchanged vars
      for n := 0 to FCurEnvironment.Count - 1 do
      begin
        S := FCurEnvironment[n];
        idx := Env.IndexOfName(GetPart([], ['='], S, False, False));
        if idx = -1
        then ReqCmd(dcEnvironment, [S, False])
        else begin
          if Env[idx] = S
          then Env.Delete(idx);
        end;
      end;

      // Set the remaining
      for n := 0 to Env.Count - 1 do
      begin
        S := Env[n];
        //Skip functions etc.
        if Pos('=()', S) <> 0 then Continue;
        ReqCmd(dcEnvironment, [S, True]);
      end;
    finally
      Env.Free;
    end;
  end;
  FCurEnvironment.Assign(FEnvironment);
end;

//function TDebuggerIntf.GetUnitInfoProvider: TDebuggerUnitInfoProvider;
//begin
//  Result := FUnitInfoProvider;
//  if Result = nil then
//    Result := FInternalUnitInfoProvider;
//end;

function TDebuggerIntf.GetIsIdle: Boolean;
begin
  Result := False;
end;

function TDebuggerIntf.Evaluate(const AExpression: String; var AResult: String;
  var ATypeInfo: TDBGType; EvalFlags: TDBGEvaluateFlags = []): Boolean;
begin
  FreeAndNIL(ATypeInfo);
  Result := ReqCmd(dcEvaluate, [AExpression, @AResult, @ATypeInfo, Integer(EvalFlags)]);
end;

function TDebuggerIntf.GetProcessList(AList: TRunningProcessInfoList): boolean;
begin
  result := false;
end;

class function TDebuggerIntf.ExePaths: String;
begin
  Result := '';
end;

class function TDebuggerIntf.HasExePath: boolean;
begin
  Result := NeedsExePath;
end;

class function TDebuggerIntf.NeedsExePath: boolean;
begin
  Result := true; // most debugger are external and have an exe path
end;

class function TDebuggerIntf.CanExternalDebugSymbolsFile: boolean;
begin
  Result := false;
end;

function TDebuggerIntf.GetCommands: TDBGCommands;
begin
  Result := COMMANDMAP[State] * GetSupportedCommands;
end;

class function TDebuggerIntf.GetProperties: TDebuggerProperties;
var
  idx: Integer;
begin
  if MDebuggerPropertiesList = nil
  then MDebuggerPropertiesList := TStringList.Create;
  idx := MDebuggerPropertiesList.IndexOf(ClassName);
  if idx = -1
  then begin
    Result := CreateProperties;
    MDebuggerPropertiesList.AddObject(ClassName, Result)
  end
  else begin
    Result := TDebuggerProperties(MDebuggerPropertiesList.Objects[idx]);
  end;
end;

function TDebuggerIntf.GetState: TDBGState;
begin
  Result := FState;
end;

function TDebuggerIntf.GetSupportedCommands: TDBGCommands;
begin
  Result := [];
end;

function TDebuggerIntf.GetTargetWidth: Byte;
begin
  Result := SizeOf(PtrInt)*8;
end;

function TDebuggerIntf.GetWaiting: Boolean;
begin
  Result := False;
end;

procedure TDebuggerIntf.Init;
begin
  FExitCode := 0;
  FErrorStateMessage := '';
  FErrorStateInfo := '';
  SetState(dsIdle);
end;

procedure TDebuggerIntf.JumpTo(const ASource: String; const ALine: Integer);
begin
  ReqCmd(dcJumpTo, [ASource, ALine]);
end;

procedure TDebuggerIntf.Attach(AProcessID: String);
begin
  if State = dsIdle then SetState(dsStop);  // Needed, because no filename was set
  ReqCmd(dcAttach, [AProcessID]);
end;

procedure TDebuggerIntf.Detach;
begin
  ReqCmd(dcDetach, []);
end;

procedure TDebuggerIntf.SendConsoleInput(AText: String);
begin
  ReqCmd(dcSendConsoleInput, [AText]);
end;

function TDebuggerIntf.Modify(const AExpression, AValue: String): Boolean;
begin
  Result := ReqCmd(dcModify, [AExpression, AValue]);
end;

procedure TDebuggerIntf.Pause;
begin
  ReqCmd(dcPause, []);
end;

function TDebuggerIntf.ReqCmd(const ACommand: TDBGCommand;
  const AParams: array of const): Boolean;
begin
  if FState = dsNone then Init;
  if ACommand in Commands
  then begin
    Result := RequestCommand(ACommand, AParams);
    if not Result then begin
      DebugLn(DBG_WARNINGS, 'TDebuggerIntf.ReqCmd failed: ',dbgs(ACommand));
    end;
  end
  else begin
    DebugLn(DBG_WARNINGS, 'TDebuggerIntf.ReqCmd Command not supported: ',
            dbgs(ACommand),' ClassName=',ClassName);
    Result := False;
  end;
end;

procedure TDebuggerIntf.Run;
begin
  ReqCmd(dcRun, []);
end;

procedure TDebuggerIntf.RunTo(const ASource: String; const ALine: Integer);
begin
  ReqCmd(dcRunTo, [ASource, ALine]);
end;

procedure TDebuggerIntf.SetDebuggerEnvironment (const AValue: TStrings );
begin
  FDebuggerEnvironment.Assign(AValue);
end;

procedure TDebuggerIntf.SetEnvironment(const AValue: TStrings);
begin
  FEnvironment.Assign(AValue);
end;

procedure TDebuggerIntf.SetExitCode(const AValue: Integer);
begin
  FExitCode := AValue;
end;

procedure TDebuggerIntf.SetFileName(const AValue: String);
begin
  if FFileName <> AValue
  then begin
    DebugLn(DBG_VERBOSE, '[TDebuggerIntf.SetFileName] "', AValue, '"');
    if FState in [dsRun, dsPause]
    then begin
      Stop;
      // check if stopped
      if FState <> dsStop
      then SetState(dsError);
    end;

    if FState = dsStop
    then begin
      // Reset state
      FFileName := '';
      ResetStateToIdle;
      ChangeFileName;
    end;

    FFileName := AValue;
    // TODO: Why?
    if  (FFilename <> '') and (FState = dsIdle) and ChangeFileName
    then SetState(dsStop);
  end
  else
  if FileName = '' then
    ResetStateToIdle;
end;

procedure TDebuggerIntf.ResetStateToIdle;
begin
  SetState(dsIdle);
end;

class procedure TDebuggerIntf.SetProperties(const AProperties: TDebuggerProperties);
var
  Props: TDebuggerProperties;
begin
  if AProperties = nil then Exit;
  Props := GetProperties;
  if Props = AProperties then Exit;

  if Props = nil then Exit; // they weren't created ?
  Props.Assign(AProperties);
end;

class function TDebuggerIntf.RequiresLocalExecutable: Boolean;
begin
  Result := True;
end;

procedure TDebuggerIntf.SetState(const AValue: TDBGState);
var
  OldState: TDBGState;
begin
  // dsDestroying is final, do not unset
  if FState = dsDestroying
  then exit;

  // dsDestroying must be silent. The ide believes the debugger is gone already
  if AValue = dsDestroying
  then begin
    FState := AValue;
    exit;
  end;

  if AValue <> FState
  then begin
    DebugLnEnter(DBG_STATE, ['DebuggerState: Setting to ', dbgs(AValue),', from ', dbgs(FState)]);
    OldState := FState;
    FState := AValue;
    LockCommandProcessing;
    try
      DoBeforeState(OldState);
      try
        FThreads.DoStateChange(OldState);
        FCallStack.DoStateChange(OldState);
        FBreakpoints.DoStateChange(OldState);
        FLocals.DoStateChange(OldState);
        FLineInfo.DoStateChange(OldState);
        FRegisters.DoStateChange(OldState);
        FDisassembler.DoStateChange(OldState);
        FWatches.DoStateChange(OldState);
      finally
        DoState(OldState);
      end;
    finally
      UnLockCommandProcessing;
      DebugLnExit(DBG_STATE, ['DebuggerState: Finished ', dbgs(AValue)]);
    end;
  end;
end;

procedure TDebuggerIntf.SetErrorState(const AMsg: String; const AInfo: String = '');
begin
  if FErrorStateMessage = ''
  then FErrorStateMessage := AMsg;
  if FErrorStateInfo = ''
  then FErrorStateInfo := AInfo;
  SetState(dsError);
end;

procedure TDebuggerIntf.DoRelease;
begin
  Self.Free;
end;

procedure TDebuggerIntf.StepInto;
begin
  if ReqCmd(dcStepInto, []) then exit;
  DebugLn(DBG_WARNINGS, 'TDebuggerIntf.StepInto Class=',ClassName,' failed.');
end;

procedure TDebuggerIntf.StepOverInstr;
begin
  if ReqCmd(dcStepOverInstr, []) then exit;
  DebugLn(DBG_WARNINGS, 'TDebuggerIntf.StepOverInstr Class=',ClassName,' failed.');
end;

procedure TDebuggerIntf.StepIntoInstr;
begin
  if ReqCmd(dcStepIntoInstr, []) then exit;
  DebugLn(DBG_WARNINGS, 'TDebuggerIntf.StepIntoInstr Class=',ClassName,' failed.');
end;

procedure TDebuggerIntf.StepOut;
begin
  if ReqCmd(dcStepOut, []) then exit;
  DebugLn(DBG_WARNINGS, 'TDebuggerIntf.StepOut Class=', ClassName, ' failed.');
end;

procedure TDebuggerIntf.StepOver;
begin
  if ReqCmd(dcStepOver, []) then exit;
  DebugLn(DBG_WARNINGS, 'TDebuggerIntf.StepOver Class=',ClassName,' failed.');
end;

procedure TDebuggerIntf.Stop;
begin
  if ReqCmd(dcStop,[]) then exit;
  DebugLn(DBG_WARNINGS, 'TDebuggerIntf.Stop Class=',ClassName,' failed.');
end;

function TBaseDebugManagerIntf.DebuggerCount: Integer;
begin
  Result := MDebuggerClasses.Count;
end;

function TBaseDebugManagerIntf.FindDebuggerClass(const AString: String): TDebuggerClass;
var
  idx: Integer;
begin
  idx := MDebuggerClasses.IndexOf(AString);
  if idx = -1
  then Result := nil
  else Result := TDebuggerClass(MDebuggerClasses.Objects[idx]);
end;

function TBaseDebugManagerIntf.GetDebuggerClass(const AIndex: Integer): TDebuggerClass;
begin
  Result := TDebuggerClass(MDebuggerClasses.Objects[AIndex]);
end;


initialization
  MDebuggerPropertiesList := nil;
  {$IFDEF DBG_STATE}  {$DEFINE DBG_STATE_EVENT} {$ENDIF}
  {$IFDEF DBG_EVENTS} {$DEFINE DBG_STATE_EVENT} {$ENDIF}
  DBG_VERBOSE := DebugLogger.FindOrRegisterLogGroup('DBG_VERBOSE' {$IFDEF DBG_VERBOSE} , True {$ENDIF} );
  DBG_WARNINGS := DebugLogger.FindOrRegisterLogGroup('DBG_WARNINGS' {$IFDEF DBG_WARNINGS} , True {$ENDIF} );
  DBG_STATE       := DebugLogger.FindOrRegisterLogGroup('DBG_STATE' {$IFDEF DBG_STATE} , True {$ENDIF} );
  DBG_EVENTS      := DebugLogger.FindOrRegisterLogGroup('DBG_EVENTS' {$IFDEF DBG_EVENTS} , True {$ENDIF} );
  DBG_STATE_EVENT := DebugLogger.FindOrRegisterLogGroup('DBG_STATE_EVENT' {$IFDEF DBG_STATE_EVENT} , True {$ENDIF} );
  DBG_DATA_MONITORS := DebugLogger.FindOrRegisterLogGroup('DBG_DATA_MONITORS' {$IFDEF DBG_DATA_MONITORS} , True {$ENDIF} );
  DBG_DISASSEMBLER := DebugLogger.FindOrRegisterLogGroup('DBG_DISASSEMBLER' {$IFDEF DBG_DISASSEMBLER} , True {$ENDIF} );

  MDebuggerClasses := TStringList.Create;
  MDebuggerClasses.Sorted := True;
  MDebuggerClasses.Duplicates := dupError;

finalization
  DoFinalization;
  FreeAndNil(MDebuggerClasses);

end.
