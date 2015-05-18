{ $Id$ }
{
 ---------------------------------------------------------------------------
 fpdbgclasses.pp  -  Native freepascal debugger
 ---------------------------------------------------------------------------

 This unit contains debugger classes for a native freepascal debugger

 ---------------------------------------------------------------------------

 @created(Mon Apr 10th WET 2006)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@dommelstein.nl>)

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
unit FpDbgClasses;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Maps, FpDbgDwarf, FpDbgUtil, FpDbgLoader,
  FpDbgInfo, FpdMemoryTools, LazLoggerBase, LazClasses, DbgIntfBaseTypes, fgl,
  fpDbgSymTableContext,
  FpDbgDwarfDataClasses;

type
  TFPDEvent = (deExitProcess, deBreakpoint, deException, deCreateProcess, deLoadLibrary, deInternalContinue);
  TFPDMode = (dm32, dm64);
  TFPDLogLevel = (dllDebug, dllInfo, dllError);
  TFPDCompareStepInfo = (dcsiNewLine, dcsiSameLine, dcsiNoLineInfo);
  TOnLog = procedure(const AString: string; const ALogLevel: TFPDLogLevel) of object;

  { TDbgRegisterValue }

  TDbgRegisterValue = class
  private
    FDwarfIdx: cardinal;
    FName: string;
    FNumValue: TDBGPtr;
    FSize: byte;
    FStrValue: string;
  public
    constructor Create(AName: String);
    procedure SetValue(ANumValue: TDBGPtr; AStrValue: string; ASize: byte; ADwarfIdx: cardinal);
    procedure Setx86EFlagsValue(ANumValue: TDBGPtr);
    property Name: string read FName;
    property NumValue: TDBGPtr read FNumValue;
    property StrValue: string read FStrValue;
    property Size: byte read FSize;
    property DwarfIdx: cardinal read FDwarfIdx;
  end;

  TGDbgRegisterValueList = specialize TFPGObjectList<TDbgRegisterValue>;

  { TDbgRegisterValueList }

  TDbgRegisterValueList = class(TGDbgRegisterValueList)
  private
    function GetDbgRegister(AName: string): TDbgRegisterValue;
    function GetDbgRegisterAutoCreate(AName: string): TDbgRegisterValue;
  public
    property DbgRegisterAutoCreate[AName: string]: TDbgRegisterValue read GetDbgRegisterAutoCreate;
    function FindRegisterByDwarfIndex(AnIdx: cardinal): TDbgRegisterValue;
  end;

  { TDbgCallstackEntry }
  TDbgThread = class;

  TDbgCallstackEntry = class
  private
    FAnAddress: TDBGPtr;
    FFrameAdress: TDBGPtr;
    FThread: TDbgThread;
    FIsSymbolResolved: boolean;
    FSymbol: TFpDbgSymbol;
    FRegisterValueList: TDbgRegisterValueList;
    function GetFunctionName: string;
    function GetSymbol: TFpDbgSymbol;
    function GetLine: integer;
    function GetSourceFile: string;
  public
    constructor create(AThread: TDbgThread; AFrameAddress, AnAddress: TDBGPtr);
    destructor Destroy; override;
    property AnAddress: TDBGPtr read FAnAddress;
    property FrameAdress: TDBGPtr read FFrameAdress;
    property SourceFile: string read GetSourceFile;
    property FunctionName: string read GetFunctionName;
    property Line: integer read GetLine;
    property RegisterValueList: TDbgRegisterValueList read FRegisterValueList;
  end;

  TDbgCallstackEntryList = specialize TFPGObjectList<TDbgCallstackEntry>;

  TDbgProcess = class;

  { TDbgMemReader }

  TDbgMemReader = class(TFpDbgMemReaderBase)
  protected
    function GetDbgProcess: TDbgProcess; virtual; abstract;
  public
    function ReadRegister(ARegNum: Cardinal; out AValue: TDbgPtr; AContext: TFpDbgAddressContext): Boolean; override;
    function RegisterSize(ARegNum: Cardinal): Integer; override;
  end;

  { TDbgThread }
  TDbgBreakpoint = class;

  TDbgThread = class(TObject)
  private
    FNextIsSingleStep: boolean;
    FProcess: TDbgProcess;
    FID: Integer;
    FHandle: THandle;
    FNeedIPDecrement: boolean;
    function GetRegisterValueList: TDbgRegisterValueList;
  protected
    FCallStackEntryList: TDbgCallstackEntryList;
    FRegisterValueListValid: boolean;
    FRegisterValueList: TDbgRegisterValueList;
    FStoreStepSrcFilename: string;
    FStoreStepSrcLineNo: integer;
    FStoreStepStackFrame: TDBGPtr;
    FStoreStepFuncAddr: TDBGPtr;
    procedure LoadRegisterValues; virtual;
    property Process: TDbgProcess read FProcess;
  public
    constructor Create(const AProcess: TDbgProcess; const AID: Integer; const AHandle: THandle); virtual;
    function ResetInstructionPointerAfterBreakpoint: boolean; virtual; abstract;
    procedure BeforeContinue; virtual;
    function AddWatchpoint(AnAddr: TDBGPtr): integer; virtual;
    function RemoveWatchpoint(AnId: integer): boolean; virtual;
    function DetectHardwareWatchpoint: integer; virtual;
    procedure PrepareCallStackEntryList(AFrameRequired: Integer = -1); virtual;
    procedure ClearCallStack;
    destructor Destroy; override;
    function CompareStepInfo: TFPDCompareStepInfo;
    function IsAtStartOfLine: boolean;
    procedure StoreStepInfo;
    property ID: Integer read FID;
    property Handle: THandle read FHandle;
    property NextIsSingleStep: boolean read FNextIsSingleStep write FNextIsSingleStep;
    property RegisterValueList: TDbgRegisterValueList read GetRegisterValueList;
    property CallStackEntryList: TDbgCallstackEntryList read FCallStackEntryList;
  end;
  TDbgThreadClass = class of TDbgThread;

  TDbgBreakpoint = class(TObject)
  private
    FProcess: TDbgProcess;
    FLocation: TDbgPtr;
  protected
    FOrgValue: Byte;
    property Process: TDbgProcess read FProcess;
  public
    constructor Create(const AProcess: TDbgProcess; const ALocation: TDbgPtr); virtual;
    destructor Destroy; override;
    function Hit(const AThreadID: Integer): Boolean; virtual;
    property Location: TDbgPtr read FLocation;

    procedure SetBreak; virtual;
    procedure ResetBreak; virtual;
  end;
  TDbgBreakpointClass = class of TDbgBreakpoint;

  { TDbgInstance }

  TDbgInstance = class(TObject)
  private
    FMode: TFPDMode;
    FName: String;
    FProcess: TDbgProcess;
    FSymbolTableInfo: TFpSymbolInfo;
    FLoaderList: TDbgImageLoaderList;

  protected
    FDbgInfo: TDbgInfo;
    procedure InitializeLoaders; virtual;
    procedure SetName(const AValue: String);
    property LoaderList: TDbgImageLoaderList read FLoaderList write FLoaderList;
  public
    constructor Create(const AProcess: TDbgProcess); virtual;
    destructor Destroy; override;

    function AddBreak(const AFileName: String; ALine: Cardinal): TDbgBreakpoint; overload;
    function AddrOffset: Int64; virtual;  // gives the offset between  the loaded addresses and the compiled addresses
    function FindSymbol(AAdress: TDbgPtr): TFpDbgSymbol;
    function RemoveBreak(const AFileName: String; ALine: Cardinal): Boolean;
    procedure LoadInfo; virtual;

    property Process: TDbgProcess read FProcess;
    property DbgInfo: TDbgInfo read FDbgInfo;
    property SymbolTableInfo: TFpSymbolInfo read FSymbolTableInfo;
    property Mode: TFPDMode read FMode;
  end;

  { TDbgLibrary }

  TDbgLibrary = class(TDbgInstance)
  private
    FModuleHandle: THandle;
    FBaseAddr: TDBGPtr;
  public
    constructor Create(const AProcess: TDbgProcess; const ADefaultName: String; const AModuleHandle: THandle; const ABaseAddr: TDbgPtr);
    property Name: String read FName;
    property ModuleHandle: THandle read FModuleHandle;
    property BaseAddr: TDBGPtr read FBaseAddr;
  end;

  { TDbgProcess }

  TDbgProcess = class(TDbgInstance)
  private
    FExceptionClass: string;
    FExceptionMessage: string;
    FExitCode: DWord;
    FOnLog: TOnLog;
    FProcessID: Integer;
    FThreadID: Integer;

    procedure ThreadDestroyed(const AThread: TDbgThread);
  protected
    FCurrentBreakpoint: TDbgBreakpoint;  // set if we are executing the code at the break
                                         // if the singlestep is done, set the break again
    FCurrentWatchpoint: integer;
    FReEnableBreakStep: Boolean;         // Set when we are reenabling a breakpoint
                                         // We need a single step, so the IP is after the break to set

    FSymInstances: TList;  // list of dbgInstances with debug info

    FThreadMap: TMap; // map ThreadID -> ThreadObject
    FLibMap: TMap;    // map LibAddr -> LibObject
    FBreakMap: TMap;  // map BreakAddr -> BreakObject

    FMainThread: TDbgThread;
    function GetHandle: THandle; virtual;
    procedure SetExitCode(AValue: DWord);
    function GetLastEventProcessIdentifier: THandle; virtual;
    function DoBreak(BreakpointAddress: TDBGPtr; AThreadID: integer): Boolean;
    procedure MaskBreakpointsInReadData(const AAdress: TDbgPtr; const ASize: Cardinal; var AData);
    // Should create a TDbgThread-instance for the given ThreadIdentifier.
    function CreateThread(AthreadIdentifier: THandle; out IsMainThread: boolean): TDbgThread; virtual; abstract;
    // Should analyse why the debugger has stopped.
    function AnalyseDebugEvent(AThread: TDbgThread): TFPDEvent; virtual; abstract;
  public
    class function StartInstance(AFileName: string; AParams, AnEnvironment: TStrings; AWorkingDirectory, AConsoleTty: string; AOnLog: TOnLog; ReDirectOutput: boolean): TDbgProcess; virtual;
    constructor Create(const AName: string; const AProcessID, AThreadID: Integer; AOnLog: TOnLog); virtual;
    destructor Destroy; override;
    function  AddBreak(const ALocation: TDbgPtr): TDbgBreakpoint; overload;
    function  FindSymbol(const AName: String): TFpDbgSymbol;
    function  FindSymbol(AAdress: TDbgPtr): TFpDbgSymbol;
    function  GetLib(const AHandle: THandle; out ALib: TDbgLibrary): Boolean;
    function  GetThread(const AID: Integer; out AThread: TDbgThread): Boolean;
    function  RemoveBreak(const ALocation: TDbgPtr): Boolean;
    function  HasBreak(const ALocation: TDbgPtr): Boolean;
    procedure RemoveThread(const AID: DWord);
    procedure Log(const AString: string; const ALogLevel: TFPDLogLevel = dllDebug);
    procedure Log(const AString: string; const Options: array of const; const ALogLevel: TFPDLogLevel = dllDebug);
    function FormatAddress(const AAddress): String;
    function  Pause: boolean; virtual;

    function ReadData(const AAdress: TDbgPtr; const ASize: Cardinal; out AData): Boolean; virtual;
    function ReadAddress(const AAdress: TDbgPtr; out AData: TDBGPtr): Boolean; virtual;
    function ReadOrdinal(const AAdress: TDbgPtr; out AData): Boolean; virtual;
    function ReadString(const AAdress: TDbgPtr; const AMaxSize: Cardinal; out AData: String): Boolean; virtual;
    function ReadWString(const AAdress: TDbgPtr; const AMaxSize: Cardinal; out AData: WideString): Boolean; virtual;

    function Continue(AProcess: TDbgProcess; AThread: TDbgThread; SingleStep: boolean): boolean; virtual;
    function WaitForDebugEvent(out ProcessIdentifier, ThreadIdentifier: THandle): boolean; virtual; abstract;
    function ResolveDebugEvent(AThread: TDbgThread): TFPDEvent; virtual;

    function CheckForConsoleOutput(ATimeOutMs: integer): integer; virtual;
    function GetConsoleOutput: string; virtual;
    procedure SendConsoleInput(AString: string); virtual;

    function AddThread(AThreadIdentifier: THandle): TDbgThread;
    procedure LoadInfo; override;

    function WriteData(const AAdress: TDbgPtr; const ASize: Cardinal; const AData): Boolean; virtual;

    function GetInstructionPointerRegisterValue: TDbgPtr; virtual; abstract;
    function GetStackBasePointerRegisterValue: TDbgPtr; virtual; abstract;
    function GetStackPointerRegisterValue: TDbgPtr; virtual; abstract;

    procedure TerminateProcess; virtual; abstract;

    property Handle: THandle read GetHandle;
    property Name: String read FName write SetName;
    property ProcessID: integer read FProcessID;
    property ThreadID: integer read FThreadID;
    property ExitCode: DWord read FExitCode;
    property CurrentBreakpoint: TDbgBreakpoint read FCurrentBreakpoint;
    property CurrentWatchpoint: integer read FCurrentWatchpoint;

    // Properties valid when last event was an deException
    property ExceptionMessage: string read FExceptionMessage write FExceptionMessage;
    property ExceptionClass: string read FExceptionClass write FExceptionClass;

    property LastEventProcessIdentifier: THandle read GetLastEventProcessIdentifier;
    property OnLog: TOnLog read FOnLog;
    property MainThread: TDbgThread read FMainThread;
  end;
  TDbgProcessClass = class of TDbgProcess;

  TOSDbgClasses = class
  public
    DbgThreadClass : TDbgThreadClass;
    DbgBreakpointClass : TDbgBreakpointClass;
    DbgProcessClass : TDbgProcessClass;
  end;

var
  {$ifdef cpui386}
  GMode: TFPDMode = dm32;
  {$else}
  GMode: TFPDMode = dm64;
  {$endif}

const
  DBGPTRSIZE: array[TFPDMode] of Integer = (4, 8);
  FPDEventNames: array[TFPDEvent] of string = ('deExitProcess', 'deBreakpoint', 'deException', 'deCreateProcess', 'deLoadLibrary', 'deInternalContinue');

function OSDbgClasses: TOSDbgClasses;

implementation

{$ifdef windows}
uses
  FpDbgWinClasses;
{$endif}
{$ifdef darwin}
uses
  FpDbgDarwinClasses;
{$endif}
{$ifdef linux}
uses
  FpDbgLinuxClasses;
{$endif}

var
  GOSDbgClasses : TOSDbgClasses;

function OSDbgClasses: TOSDbgClasses;
begin
  if GOSDbgClasses=nil then
    begin
    GOSDbgClasses := TOSDbgClasses.create;
    GOSDbgClasses.DbgThreadClass := TDbgThread;
    GOSDbgClasses.DbgBreakpointClass := TDbgBreakpoint;
    GOSDbgClasses.DbgProcessClass := TDbgProcess;
    {$ifdef windows}
    RegisterDbgClasses;
    {$endif windows}
    {$ifdef darwin}
    RegisterDbgClasses;
    {$endif darwin}
    {$ifdef linux}
    RegisterDbgClasses;
    {$endif linux}
    end;
  result := GOSDbgClasses;
end;

{ TDbgCallstackEntry }

function TDbgCallstackEntry.GetSymbol: TFpDbgSymbol;
begin
  if not FIsSymbolResolved then
    FSymbol := FThread.Process.FindSymbol(FAnAddress);
  result := FSymbol;
end;

function TDbgCallstackEntry.GetFunctionName: string;
var
  Symbol: TFpDbgSymbol;
begin
  Symbol := GetSymbol;
  if assigned(Symbol) then
    result := Symbol.Name
  else
    result := '';
end;

function TDbgCallstackEntry.GetLine: integer;
var
  Symbol: TFpDbgSymbol;
begin
  Symbol := GetSymbol;
  if assigned(Symbol) then
    result := Symbol.Line
  else
    result := -1;
end;

function TDbgCallstackEntry.GetSourceFile: string;
var
  Symbol: TFpDbgSymbol;
begin
  Symbol := GetSymbol;
  if assigned(Symbol) then
    result := Symbol.FileName
  else
    result := '';
end;

constructor TDbgCallstackEntry.create(AThread: TDbgThread; AFrameAddress, AnAddress: TDBGPtr);
begin
  FThread := AThread;
  FFrameAdress:=AFrameAddress;
  FAnAddress:=AnAddress;
  FRegisterValueList := TDbgRegisterValueList.Create;
end;

destructor TDbgCallstackEntry.Destroy;
begin
  FRegisterValueList.Free;
  inherited Destroy;
end;

{ TDbgMemReader }

function TDbgMemReader.ReadRegister(ARegNum: Cardinal; out AValue: TDbgPtr; AContext: TFpDbgAddressContext): Boolean;
var
  ARegister: TDbgRegisterValue;
  StackFrame: Integer;
  AFrame: TDbgCallstackEntry;
begin
  // TODO: Thread with ID
  if AContext <> nil then
    StackFrame := AContext.StackFrame
  else
    StackFrame := 0;
  if StackFrame = 0 then
    begin
    ARegister:=GetDbgProcess.MainThread.RegisterValueList.FindRegisterByDwarfIndex(ARegNum);
    end
  else
    begin
    GetDbgProcess.MainThread.PrepareCallStackEntryList(StackFrame);
    AFrame := GetDbgProcess.MainThread.CallStackEntryList[StackFrame];
    if AFrame <> nil then
      ARegister:=AFrame.RegisterValueList.FindRegisterByDwarfIndex(ARegNum)
    else
      ARegister:=nil;
    end;
  if assigned(ARegister) then
    begin
    AValue := ARegister.NumValue;
    result := true;
    end
  else
    result := false;
end;

function TDbgMemReader.RegisterSize(ARegNum: Cardinal): Integer;
var
  ARegister: TDbgRegisterValue;
begin
  ARegister:=GetDbgProcess.MainThread.RegisterValueList.FindRegisterByDwarfIndex(ARegNum);
  if assigned(ARegister) then
    result := ARegister.Size
  else
    result := sizeof(pointer);
end;

{ TDbgRegisterValueList }

function TDbgRegisterValueList.GetDbgRegister(AName: string): TDbgRegisterValue;
var
  i: integer;
begin
  for i := 0 to Count -1 do
    if Items[i].Name=AName then
      begin
      result := items[i];
      exit;
      end;
  result := nil;
end;

function TDbgRegisterValueList.GetDbgRegisterAutoCreate(AName: string): TDbgRegisterValue;
begin
  result := GetDbgRegister(AName);
  if not Assigned(result) then
    begin
    result := TDbgRegisterValue.Create(AName);
    add(result);
    end;
end;

function TDbgRegisterValueList.FindRegisterByDwarfIndex(AnIdx: cardinal): TDbgRegisterValue;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
    if Items[i].DwarfIdx=AnIdx then
    begin
      result := Items[i];
      exit;
    end;
  result := nil;
end;

{ TDbgRegisterValue }

constructor TDbgRegisterValue.Create(AName: String);
begin
  FName:=AName;
end;

procedure TDbgRegisterValue.SetValue(ANumValue: TDBGPtr; AStrValue: string;
  ASize: byte; ADwarfIdx: Cardinal);
begin
  FStrValue:=AStrValue;
  FNumValue:=ANumValue;
  FSize:=ASize;
  FDwarfIdx:=ADwarfIdx;
end;

procedure TDbgRegisterValue.Setx86EFlagsValue(ANumValue: TDBGPtr);
var
  FlagS: string;
begin
  FlagS := '';
  if ANumValue and (1 shl 0) <> 0 then FlagS := FlagS + 'CF ';
  if ANumValue and (1 shl 2) <> 0 then FlagS := FlagS + 'PF ';
  if ANumValue and (1 shl 4) <> 0 then FlagS := FlagS + 'AF ';
  if ANumValue and (1 shl 6) <> 0 then FlagS := FlagS + 'ZF ';
  if ANumValue and (1 shl 7) <> 0 then FlagS := FlagS + 'SF ';
  if ANumValue and (1 shl 8) <> 0 then FlagS := FlagS + 'TF ';
  if ANumValue and (1 shl 9) <> 0 then FlagS := FlagS + 'IF ';
  if ANumValue and (1 shl 10) <> 0 then FlagS := FlagS + 'DF ';
  if ANumValue and (1 shl 11) <> 0 then FlagS := FlagS + 'OF ';
  if (ANumValue shr 12) and 3 <> 0 then FlagS := FlagS + 'IOPL=' + IntToStr((ANumValue shr 12) and 3);
  if ANumValue and (1 shl 14) <> 0 then FlagS := FlagS + 'NT ';
  if ANumValue and (1 shl 16) <> 0 then FlagS := FlagS + 'RF ';
  if ANumValue and (1 shl 17) <> 0 then FlagS := FlagS + 'VM ';
  if ANumValue and (1 shl 18) <> 0 then FlagS := FlagS + 'AC ';
  if ANumValue and (1 shl 19) <> 0 then FlagS := FlagS + 'VIF ';
  if ANumValue and (1 shl 20) <> 0 then FlagS := FlagS + 'VIP ';
  if ANumValue and (1 shl 21) <> 0 then FlagS := FlagS + 'ID ';

  SetValue(ANumValue, trim(FlagS),4,Cardinal(-1));
end;

{ TDbgInstance }

function TDbgInstance.AddBreak(const AFileName: String; ALine: Cardinal): TDbgBreakpoint;
var
  addr: TDbgPtr;
begin
  Result := nil;
  if not FDbgInfo.HasInfo then Exit;
  addr := FDbgInfo.GetLineAddress(AFileName, ALine);
  if addr = 0 then Exit;
  Result := FProcess.AddBreak(addr - AddrOffset);
end;

function TDbgInstance.AddrOffset: Int64;
begin
  Result := FLoaderList.ImageBase;
end;

constructor TDbgInstance.Create(const AProcess: TDbgProcess);
begin
  FProcess := AProcess;
  FLoaderList := TDbgImageLoaderList.Create(True);

  inherited Create;
end;

destructor TDbgInstance.Destroy;
begin
  FreeAndNil(FDbgInfo);
  FreeAndNil(FSymbolTableInfo);
  FreeAndNil(FLoaderList);
  inherited;
end;

function TDbgInstance.FindSymbol(AAdress: TDbgPtr): TFpDbgSymbol;
begin
  Result := FDbgInfo.FindSymbol(AAdress + AddrOffset);
  if not assigned(Result) then
    result := FSymbolTableInfo.FindSymbol(AAdress + AddrOffset);
end;

procedure TDbgInstance.LoadInfo;
begin
  InitializeLoaders;
  if FLoaderList.Image64Bit then
    FMode:=dm64
  else
    FMode:=dm32;
  FDbgInfo := TFpDwarfInfo.Create(FLoaderList);
  TFpDwarfInfo(FDbgInfo).LoadCompilationUnits;
  FSymbolTableInfo := TFpSymbolInfo.Create(FLoaderList);
end;

function TDbgInstance.RemoveBreak(const AFileName: String; ALine: Cardinal): Boolean;
var
  addr: TDbgPtr;
begin
  Result := False;
  if not FDbgInfo.HasInfo then Exit;
  addr := FDbgInfo.GetLineAddress(AFileName, ALine);
  if addr = 0 then Exit;
  Result := FProcess.RemoveBreak(addr - AddrOffset);
end;

procedure TDbgInstance.SetName(const AValue: String);
begin
  FName := AValue;
end;

procedure TDbgInstance.InitializeLoaders;
begin
  // Do nothing;
end;

{ TDbgLibrary }

constructor TDbgLibrary.Create(const AProcess: TDbgProcess; const ADefaultName: String; const AModuleHandle: THandle; const ABaseAddr: TDbgPtr);

begin
  inherited Create(AProcess);
  FModuleHandle:=AModuleHandle;
  FBaseAddr:=ABaseAddr;
end;

{ TDbgProcess }

function TDbgProcess.AddBreak(const ALocation: TDbgPtr): TDbgBreakpoint;
begin
  if FBreakMap.HasId(ALocation) then begin
    debugln(['TDbgProcess.AddBreak breakpoint already exists at ', dbgs(ALocation)]);
    Result := nil;
    exit;
  end;
  Result := OSDbgClasses.DbgBreakpointClass.Create(Self, ALocation);
  FBreakMap.Add(ALocation, Result);
  if (GetInstructionPointerRegisterValue=ALocation) and not assigned(FCurrentBreakpoint) then
    begin
    FCurrentBreakpoint := Result;
    Result.ResetBreak;
    end;
end;

constructor TDbgProcess.Create(const AName: string; const AProcessID, AThreadID: Integer; AOnLog: TOnLog);
const
  {.$IFDEF CPU64}
  MAP_ID_SIZE = itu8;
  {.$ELSE}
//  MAP_ID_SIZE = itu4;
  {.$ENDIF}
begin
  FOnLog:=AOnLog;
  FProcessID := AProcessID;
  FThreadID := AThreadID;

  FThreadMap := TMap.Create(itu4, SizeOf(TDbgThread));
  FLibMap := TMap.Create(MAP_ID_SIZE, SizeOf(TDbgLibrary));
  FBreakMap := TMap.Create(MAP_ID_SIZE, SizeOf(TDbgBreakpoint));
  FCurrentBreakpoint := nil;
  FCurrentWatchpoint := -1;

  FSymInstances := TList.Create;

  SetName(AName);

  inherited Create(Self);
end;

destructor TDbgProcess.Destroy;

  procedure FreeItemsInMap(AMap: TMap);
  var
    AnObject: TObject;
    Iterator: TMapIterator;
  begin
    iterator := TMapIterator.Create(AMap);
    try
      Iterator.First;
      while not Iterator.EOM do
      begin
        Iterator.GetData(AnObject);
        AnObject.Free;
        iterator.Next;
      end;
    finally
      Iterator.Free;
    end;
  end;

begin
  FProcessID:=0;

  FreeItemsInMap(FBreakMap);
  FreeItemsInMap(FThreadMap);
  FreeItemsInMap(FLibMap);

  FreeAndNil(FBreakMap);
  FreeAndNil(FThreadMap);
  FreeAndNil(FLibMap);
  FreeAndNil(FSymInstances);
  inherited;
end;

function TDbgProcess.FindSymbol(const AName: String): TFpDbgSymbol;
begin
  Result := FDbgInfo.FindSymbol(AName);
end;

function TDbgProcess.FindSymbol(AAdress: TDbgPtr): TFpDbgSymbol;
var
  n: Integer;
  Inst: TDbgInstance;
begin
  for n := 0 to FSymInstances.Count - 1 do
  begin
    Inst := TDbgInstance(FSymInstances[n]);
    Result := Inst.FindSymbol(AAdress);
    if Result <> nil then Exit;
  end;
  Result := nil;
end;

function TDbgProcess.GetLib(const AHandle: THandle; out ALib: TDbgLibrary): Boolean;
var
  Iterator: TMapIterator;
  Lib: TDbgLibrary;
begin
  Result := False;
  Iterator := TMapIterator.Create(FLibMap);
  while not Iterator.EOM do
  begin
    Iterator.GetData(Lib);
    Result := Lib.ModuleHandle = AHandle;
    if Result
    then begin
      ALib := Lib;
      Break;
    end;
    Iterator.Next;
  end;
  Iterator.Free;
end;

function TDbgProcess.GetThread(const AID: Integer; out AThread: TDbgThread): Boolean;
var
  Thread: TDbgThread;
begin
  AThread := nil;
  Result := FThreadMap.GetData(AID, Thread) and (Thread <> nil);
  if Result
  then AThread := Thread;
end;

function TDbgProcess.ReadData(const AAdress: TDbgPtr; const ASize: Cardinal; out AData): Boolean;
begin
  result := false
end;

function TDbgProcess.ReadAddress(const AAdress: TDbgPtr; out AData: TDBGPtr): Boolean;
var
  dw: DWord;
  qw: QWord;
begin
  case Mode of
    dm32:
      begin
        result := ReadData(AAdress, sizeof(dw), dw);
        AData:=dw;
      end;
    dm64:
      begin
        result := ReadData(AAdress, sizeof(qw), qw);
        AData:=qw;
      end;
  end;
end;

function TDbgProcess.ReadOrdinal(const AAdress: TDbgPtr; out AData): Boolean;
begin
  Result := ReadData(AAdress, 4, AData);
end;

function TDbgProcess.ReadString(const AAdress: TDbgPtr; const AMaxSize: Cardinal; out AData: String): Boolean;
begin
  Result := false;
end;

function TDbgProcess.ReadWString(const AAdress: TDbgPtr; const AMaxSize: Cardinal; out AData: WideString): Boolean;
begin
  result := false;
end;

function TDbgProcess.Continue(AProcess: TDbgProcess; AThread: TDbgThread;
  SingleStep: boolean): boolean;
begin
  result := false;
end;

function TDbgProcess.ResolveDebugEvent(AThread: TDbgThread): TFPDEvent;
var
  CurrentAddr: TDBGPtr;
begin
  result := AnalyseDebugEvent(AThread);

  if result = deBreakpoint then
  begin
    if assigned(FCurrentBreakpoint) then
    begin
      // When a breakpoint has been hit, the debugger always continues with
      // a single-step to jump over the breakpoint. Thereafter the breakpoint
      // has to be set again.
      FCurrentBreakpoint.SetBreak;
      if not AThread.NextIsSingleStep then
        // In this case the debugger has to continue. The debugger did only
        // stop to be able to reset the breakpoint again. It was not a 'normal'
        // singlestep.
        result := deInternalContinue;
    end;

    // Determine the address where the execution has stopped
    CurrentAddr:=GetInstructionPointerRegisterValue;
    FCurrentWatchpoint:=AThread.DetectHardwareWatchpoint;
    if not (FMainThread.NextIsSingleStep or assigned(FCurrentBreakpoint) or (FCurrentWatchpoint>-1)) then
    begin
      // The debugger did not stop due to single-stepping or a watchpoint,
      // so a breakpoint has been hit. But breakpoints stop *after* they
      // have been hit. So decrement the CurrentAddr.
      FMainThread.FNeedIPDecrement:=true;
      dec(CurrentAddr);
    end
    else
      FMainThread.FNeedIPDecrement:=false;
    FCurrentBreakpoint:=nil;
    AThread.NextIsSingleStep:=false;

    // Whatever reason there was to change the result to deInternalContinue,
    // if a breakpoint has been hit, always trigger it...
    if DoBreak(CurrentAddr, FMainThread.ID) then
      result := deBreakpoint;
  end
end;

function TDbgProcess.CheckForConsoleOutput(ATimeOutMs: integer): integer;
begin
  result := -1;
end;

function TDbgProcess.GetConsoleOutput: string;
begin
  result := '';
end;

procedure TDbgProcess.SendConsoleInput(AString: string);
begin
  // Do nothing
end;

function TDbgProcess.AddThread(AThreadIdentifier: THandle): TDbgThread;
var
  IsMainThread: boolean;
begin
  result := CreateThread(AthreadIdentifier, IsMainThread);
  if assigned(result) then
  begin
    FThreadMap.Add(AThreadIdentifier, Result);
    if IsMainThread then
    begin
      assert(FMainThread=nil);
      FMainThread := result;
    end;
  end
  else
    Log('Unknown thread ID %u for process %u', [AThreadIdentifier, ProcessID]);
end;

function TDbgProcess.RemoveBreak(const ALocation: TDbgPtr): Boolean;
var
  ABreakPoint: TDbgBreakpoint;
begin
  if FBreakMap = nil
  then Result := False
  else begin
    result := FBreakMap.GetData(ALocation, ABreakPoint);
    if result then begin
      if ABreakPoint=FCurrentBreakpoint then
        FCurrentBreakpoint := nil;
      Result := FBreakMap.Delete(ALocation);
    end;
  end;
end;

function TDbgProcess.HasBreak(const ALocation: TDbgPtr): Boolean;
begin
  if FBreakMap = nil then
    Result := False
  else
    result := FBreakMap.HasId(ALocation);
end;

procedure TDbgProcess.RemoveThread(const AID: DWord);
begin
  if FThreadMap = nil then Exit;
  FThreadMap.Delete(AID);
end;

procedure TDbgProcess.Log(const AString: string; const ALogLevel: TFPDLogLevel);
begin
  if assigned(FOnLog) then
    FOnLog(AString, ALogLevel)
  else
    DebugLn(AString);
end;

procedure TDbgProcess.Log(const AString: string; const Options: array of const; const ALogLevel: TFPDLogLevel);
begin
  Log(Format(AString, Options), ALogLevel);
end;

function TDbgProcess.FormatAddress(const AAddress): String;
begin
  Result := HexValue(AAddress, DBGPTRSIZE[Mode], [hvfIncludeHexchar]);
end;

function TDbgProcess.Pause: boolean;
begin
  result := false;
end;

function TDbgProcess.GetHandle: THandle;
begin
  result := 0;
end;

procedure TDbgProcess.SetExitCode(AValue: DWord);
begin
  FExitCode:=AValue;
end;

resourcestring
  sNoDebugSupport = 'Debug support is not available for this platform .';

class function TDbgProcess.StartInstance(AFileName: string; AParams,
  AnEnvironment: TStrings; AWorkingDirectory, AConsoleTty: string; AOnLog: TOnLog; ReDirectOutput: boolean): TDbgProcess;
begin
  if assigned(AOnLog) then
    AOnLog(sNoDebugSupport, dllError)
  else
    DebugLn(sNoDebugSupport);
  result := nil;
end;

procedure TDbgProcess.ThreadDestroyed(const AThread: TDbgThread);
begin
  if AThread = FMainThread
  then FMainThread := nil;
end;

procedure TDbgProcess.LoadInfo;
begin
  inherited LoadInfo;

  if DbgInfo.HasInfo then
    FSymInstances.Add(Self);
end;

function TDbgProcess.GetLastEventProcessIdentifier: THandle;
begin
  result := 0;
end;

function TDbgProcess.DoBreak(BreakpointAddress: TDBGPtr; AThreadID: integer): Boolean;
begin
  Result := False;
  if not FBreakMap.GetData(BreakpointAddress, FCurrentBreakpoint) then Exit;
  if FCurrentBreakpoint = nil then Exit;

  Result := True;
  if not FCurrentBreakpoint.Hit(AThreadId)
  then FCurrentBreakpoint := nil; // no need for a singlestep if we continue
end;

procedure TDbgProcess.MaskBreakpointsInReadData(const AAdress: TDbgPtr; const ASize: Cardinal; var AData);
var
  BreakLocation: TDBGPtr;
  Bp: TDbgBreakpoint;
  Iterator: TMapIterator;
begin
  iterator := TMapIterator.Create(FBreakMap);
  try
    Iterator.First;
    while not Iterator.EOM do
    begin
      Iterator.GetData(bp);
      BreakLocation := Bp.FLocation;
      if (BreakLocation >= AAdress) and (BreakLocation < (AAdress+ASize)) then
        TByteArray(AData)[BreakLocation-AAdress] := Bp.FOrgValue;
      iterator.Next;
    end;
  finally
    Iterator.Free;
  end;
end;

function TDbgProcess.WriteData(const AAdress: TDbgPtr; const ASize: Cardinal; const AData): Boolean;
begin
  result := false;
end;

{ TDbgThread }

function TDbgThread.GetRegisterValueList: TDbgRegisterValueList;
begin
  if not FRegisterValueListValid then
    LoadRegisterValues;
  result := FRegisterValueList;
end;

function TDbgThread.CompareStepInfo: TFPDCompareStepInfo;
var
  AnAddr: TDBGPtr;
  Sym: TFpDbgSymbol;
begin
  AnAddr := FProcess.GetInstructionPointerRegisterValue;
  sym := FProcess.FindSymbol(AnAddr);
  if assigned(sym) then
  begin
    if (((FStoreStepSrcFilename=sym.FileName) and (FStoreStepSrcLineNo=sym.Line)) {or FStepOut}) and
              (FStoreStepFuncAddr=sym.Address.Address) then
      result := dcsiSameLine
    else if sym.Line = 0 then
      result := dcsiNoLineInfo
    else
      result := dcsiNewLine;
    sym.ReleaseReference;
  end
  else
    result := dcsiNoLineInfo;
end;

function TDbgThread.IsAtStartOfLine: boolean;
var
  AnAddr: TDBGPtr;
  Sym: TFpDbgSymbol;
  CU: TDwarfCompilationUnit;
begin
  result := true;
  AnAddr := FProcess.GetInstructionPointerRegisterValue;
  sym := FProcess.FindSymbol(AnAddr);
  if (sym is TDbgDwarfSymbolBase) then
  begin
    CU := TDbgDwarfSymbolBase(sym).CompilationUnit;
    if cu.GetLineAddress(sym.FileName, sym.Line)<>AnAddr then
      result := false;
  end;
  sym.ReleaseReference;
end;

procedure TDbgThread.StoreStepInfo;
var
  AnAddr: TDBGPtr;
  Sym: TFpDbgSymbol;
begin
  FStoreStepStackFrame := FProcess.GetStackBasePointerRegisterValue;
  AnAddr := FProcess.GetInstructionPointerRegisterValue;
  sym := FProcess.FindSymbol(AnAddr);
  if assigned(sym) then
  begin
    FStoreStepSrcFilename:=sym.FileName;
    FStoreStepSrcLineNo:=sym.Line;
    FStoreStepFuncAddr:=sym.Address.Address;
    sym.ReleaseReference;
  end
  else
    FStoreStepSrcLineNo:=-1;
end;

procedure TDbgThread.LoadRegisterValues;
begin
  // Do nothing
end;

constructor TDbgThread.Create(const AProcess: TDbgProcess; const AID: Integer; const AHandle: THandle);
begin
  FID := AID;
  FHandle := AHandle;
  FProcess := AProcess;
  FRegisterValueList:=TDbgRegisterValueList.Create;
  inherited Create;
end;

procedure TDbgThread.BeforeContinue;
begin
  // Do nothing
end;

function TDbgThread.AddWatchpoint(AnAddr: TDBGPtr): integer;
begin
  FProcess.log('Hardware watchpoints are not available.');
  result := -1;
end;

function TDbgThread.RemoveWatchpoint(AnId: integer): boolean;
begin
  FProcess.log('Hardware watchpoints are not available: '+self.classname);
  result := false;
end;

function TDbgThread.DetectHardwareWatchpoint: integer;
begin
  result := -1;
end;

procedure TDbgThread.PrepareCallStackEntryList(AFrameRequired: Integer);
var
  Address, Frame, LastFrame: QWord;
  Size, Count: integer;
  AnEntry: TDbgCallstackEntry;
begin
  // TODO: use AFrameRequired // check if already partly done
  if FCallStackEntryList = nil then
    FCallStackEntryList := TDbgCallstackEntryList.Create;
  if (AFrameRequired >= 0) and (AFrameRequired < FCallStackEntryList.Count) then
    exit;
  // TODO: remove, using AFrameRequired
  if FCallStackEntryList.Count > 0 then exit; // allready done

  Address := Process.GetInstructionPointerRegisterValue;
  Frame := Process.GetStackBasePointerRegisterValue;
  Size := sizeof(pointer); // TODO: Context.AddressSize

  FCallStackEntryList.FreeObjects:=true;
  AnEntry := TDbgCallstackEntry.create(Self, Frame, Address);
  // Top level entry needs no registerlist / same as GetRegisterValueList
  FCallStackEntryList.Add(AnEntry);

  LastFrame := 0;
  Count := 25;
  while (Frame <> 0) and (Frame > LastFrame) do
  begin
    if not Process.ReadData(Frame + Size, Size, Address) or (Address = 0) then Break;
    if not Process.ReadData(Frame, Size, Frame) then Break;
    AnEntry := TDbgCallstackEntry.create(Self, Frame, Address);
    AnEntry.RegisterValueList.DbgRegisterAutoCreate['eip'].SetValue(Address, IntToStr(Address),Size,8);
    AnEntry.RegisterValueList.DbgRegisterAutoCreate['ebp'].SetValue(Frame, IntToStr(Frame),Size,5);
    FCallStackEntryList.Add(AnEntry);
    Dec(count);
    if Count <= 0 then Break;
  end;
end;

procedure TDbgThread.ClearCallStack;
begin
  if FCallStackEntryList <> nil then
    FCallStackEntryList.Clear;
end;

destructor TDbgThread.Destroy;
begin
  FProcess.ThreadDestroyed(Self);
  FRegisterValueList.Free;
  ClearCallStack;
  FCallStackEntryList.Free;
  inherited;
end;

{ TDbgBreak }

constructor TDbgBreakpoint.Create(const AProcess: TDbgProcess; const ALocation: TDbgPtr);
begin
  FProcess := AProcess;
  FLocation := ALocation;
  inherited Create;
  SetBreak;
end;

destructor TDbgBreakpoint.Destroy;
begin
  ResetBreak;
  inherited;
end;

function TDbgBreakpoint.Hit(const AThreadID: Integer): Boolean;
var
  Thread: TDbgThread;
begin
  Result := False;
  if FOrgValue = $CC then Exit; // breakpoint on a hardcoded breakpoint
                                // no need to jum back and restore instruction
  ResetBreak;

  if not Process.GetThread(AThreadId, Thread) then Exit;

  if Thread.FNeedIPDecrement then
    Result := Thread.ResetInstructionPointerAfterBreakpoint
  else
    Result := true;
end;

procedure TDbgBreakpoint.ResetBreak;
begin
  if FProcess.ProcessID=0 then
    // The process is already exited.
    Exit;

  if FOrgValue = $CC then Exit; // breakpoint on a hardcoded breakpoint

  if not FProcess.WriteData(FLocation, 1, FOrgValue)
  then begin
    Log('Unable to reset breakpoint at %s', [FormatAddress(FLocation)]);
  end;
end;

procedure TDbgBreakpoint.SetBreak;
const
  Int3: Byte = $CC;
begin
  if not FProcess.ReadData(FLocation, 1, FOrgValue)
  then begin
    Log('Unable to read breakpoint at '+FormatAddress(FLocation));
    Exit;
  end;

  if FOrgValue = $CC then Exit; // breakpoint on a hardcoded breakpoint

  if not FProcess.WriteData(FLocation, 1, Int3)
  then begin
    Log('Unable to set breakpoint at '+FormatAddress(FLocation));
    Exit;
  end;
end;

initialization
  GOSDbgClasses := nil;
finalization
  GOSDbgClasses.Free;
end.
