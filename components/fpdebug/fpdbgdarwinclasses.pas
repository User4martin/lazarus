unit FpDbgDarwinClasses;

{$mode objfpc}{$H+}
{$linkframework security}

interface

uses
  Classes,
  SysUtils,
  BaseUnix,
  termio,
  process,
  FpDbgClasses,
  FpDbgLoader,
  DbgIntfBaseTypes,
  FpDbgLinuxExtra,
  FpDbgDwarfDataClasses,
  FpImgReaderMacho,
  FpDbgInfo,
  MacOSAll,
  FpDbgUtil,
  LazLoggerBase;

type
  x86_thread_state32_t = record
    __eax: cuint;
    __ebx: cuint;
    __ecx: cuint;
    __edx: cuint;
    __edi: cuint;
    __esi: cuint;
    __ebp: cuint;
    __esp: cuint;
    __ss: cuint;
    __eflags: cuint;
    __eip: cuint;
    __cs: cuint;
    __ds: cuint;
    __es: cuint;
    __fs: cuint;
    __gs: cuint;
  end;

  x86_thread_state64_t = record
    __rax: cuint64;
    __rbx: cuint64;
    __rcx: cuint64;
    __rdx: cuint64;
    __rdi: cuint64;
    __rsi: cuint64;
    __rbp: cuint64;
    __rsp: cuint64;
    __r8: cuint64;
    __r9: cuint64;
    __r10: cuint64;
    __r11: cuint64;
    __r12: cuint64;
    __r13: cuint64;
    __r14: cuint64;
    __r15: cuint64;
    __rip: cuint64;
    __rflags: cuint64;
    __cs: cuint64;
    __fs: cuint64;
    __gs: cuint64;
  end;

  x86_debug_state32_t = record
    __dr0: cuint32;
    __dr1: cuint32;
    __dr2: cuint32;
    __dr3: cuint32;
    __dr4: cuint32;
    __dr5: cuint32;
    __dr6: cuint32;
    __dr7: cuint32;
  end;

  x86_debug_state64_t = record
    __dr0: cuint64;
    __dr1: cuint64;
    __dr2: cuint64;
    __dr3: cuint64;
    __dr4: cuint64;
    __dr5: cuint64;
    __dr6: cuint64;
    __dr7: cuint64;
  end;

  x86_debug_state = record
    case a: byte of
      1: (ds32: x86_debug_state32_t);
      2: (ds64: x86_debug_state64_t);
  end;

type

  { TDbgDarwinThread }

  TDbgDarwinThread = class(TDbgThread)
  private
    FThreadState32: x86_thread_state32_t;
    FThreadState64: x86_thread_state64_t;
    FDebugState32: x86_debug_state32_t;
    FDebugState64: x86_debug_state64_t;
    FDebugStateRead: boolean;
    FDebugStateChanged: boolean;
  protected
    function ReadThreadState: boolean;
    function ReadDebugState: boolean;
  public
    function ResetInstructionPointerAfterBreakpoint: boolean; override;
    function AddWatchpoint(AnAddr: TDBGPtr): integer; override;
    function RemoveWatchpoint(AnId: integer): boolean; override;
    function DetectHardwareWatchpoint: integer; override;
    procedure BeforeContinue; override;
    procedure LoadRegisterValues; override;
  end;

  { TDbgDarwinProcess }

  TDbgDarwinProcess = class(TDbgProcess)
  private
    FStatus: cint;
    FProcessStarted: boolean;
    FTaskPort: mach_port_name_t;
    FProcProcess: TProcess;
    FIsTerminating: boolean;
    FExceptionSignal: PtrUInt;
    FMasterPtyFd: cint;
    FExecutableFilename: string;
    function GetDebugAccessRights: boolean;
    {$ifndef VER2_6}
    procedure OnForkEvent(Sender : TObject);
    {$endif}
  protected
    procedure InitializeLoaders; override;
    function CreateThread(AthreadIdentifier: THandle; out IsMainThread: boolean): TDbgThread; override;
    function AnalyseDebugEvent(AThread: TDbgThread): TFPDEvent; override;
  public
    class function StartInstance(AFileName: string; AParams, AnEnvironment: TStrings; AWorkingDirectory, AConsoleTty: string; AOnLog: TOnLog; ReDirectOutput: boolean): TDbgProcess; override;
    constructor Create(const AName: string; const AProcessID, AThreadID: Integer; AOnLog: TOnLog); override;
    destructor Destroy; override;

    function ReadData(const AAdress: TDbgPtr; const ASize: Cardinal; out AData): Boolean; override;
    function WriteData(const AAdress: TDbgPtr; const ASize: Cardinal; const AData): Boolean; override;

    function CheckForConsoleOutput(ATimeOutMs: integer): integer; override;
    function GetConsoleOutput: string; override;
    procedure SendConsoleInput(AString: string); override;

    function GetInstructionPointerRegisterValue: TDbgPtr; override;
    function GetStackPointerRegisterValue: TDbgPtr; override;
    function GetStackBasePointerRegisterValue: TDbgPtr; override;
    procedure TerminateProcess; override;

    function Continue(AProcess: TDbgProcess; AThread: TDbgThread; SingleStep: boolean): boolean; override;
    function WaitForDebugEvent(out ProcessIdentifier, ThreadIdentifier: THandle): boolean; override;
    function Pause: boolean; override;
  end;

procedure RegisterDbgClasses;

implementation

var
  GConsoleTty: string;

type
  vm_map_t = mach_port_t;
  vm_offset_t = UIntPtr;
  vm_address_t = vm_offset_t;
  vm_size_t = UIntPtr;
  vm_prot_t = cint;
  mach_vm_address_t = uint64;
  mach_msg_Type_number_t = natural_t;
  mach_vm_size_t = uint64;
  task_t = mach_port_t;
  thread_act_t = mach_port_t;
  thread_act_array = array[0..255] of thread_act_t;
  thread_act_array_t = ^thread_act_array;
  thread_state_flavor_t = cint;
  thread_state_t = ^natural_t;

const
  x86_THREAD_STATE32    = 1;
  x86_FLOAT_STATE32     = 2;
  x86_EXCEPTION_STATE32 = 3;
  x86_THREAD_STATE64    = 4;
  x86_FLOAT_STATE64     = 5;
  x86_EXCEPTION_STATE64 = 6;
  x86_THREAD_STATE      = 7;
  x86_FLOAT_STATE       = 8;
  x86_EXCEPTION_STATE   = 9;
  x86_DEBUG_STATE32     = 10;
  x86_DEBUG_STATE64     = 11;
  //x86_DEBUG_STATE       = 12;
  THREAD_STATE_NONE     = 13;
  x86_AVX_STATE32       = 16;
  x86_AVX_STATE64       = 17;
  x86_AVX_STATE         = 18;

  x86_THREAD_STATE32_COUNT: mach_msg_Type_number_t = sizeof(x86_thread_state32_t) div sizeof(cint);
  x86_THREAD_STATE64_COUNT: mach_msg_Type_number_t = sizeof(x86_thread_state64_t) div sizeof(cint);
  x86_DEBUG_STATE32_COUNT:  mach_msg_Type_number_t = sizeof(x86_debug_state32_t) div sizeof(cint);
  x86_DEBUG_STATE64_COUNT:  mach_msg_Type_number_t = sizeof(x86_debug_state64_t) div sizeof(cint);

function task_for_pid(target_tport: mach_port_name_t; pid: integer; var t: mach_port_name_t): kern_return_t; cdecl external name 'task_for_pid';
function mach_task_self: mach_port_name_t; cdecl external name 'mach_task_self';
function mach_error_string(error_value: mach_error_t): pchar; cdecl; external name 'mach_error_string';
function mach_vm_protect(target_task: vm_map_t; adress: mach_vm_address_t; size: mach_vm_size_t; set_maximum: boolean_t; new_protection: vm_prot_t): kern_return_t; cdecl external name 'mach_vm_protect';
function mach_vm_write(target_task: vm_map_t; address: mach_vm_address_t; data: vm_offset_t; dataCnt: mach_msg_Type_number_t): kern_return_t; cdecl external name 'mach_vm_write';
function mach_vm_read(target_task: vm_map_t; address: mach_vm_address_t; size: mach_vm_size_t; var data: vm_offset_t; var dataCnt: mach_msg_Type_number_t): kern_return_t; cdecl external name 'mach_vm_read';

function task_threads(target_task: task_t; var act_list: thread_act_array_t; var act_listCnt: mach_msg_type_number_t): kern_return_t; cdecl external name 'task_threads';
function thread_get_state(target_act: thread_act_t; flavor: thread_state_flavor_t; old_state: thread_state_t; var old_stateCnt: mach_msg_Type_number_t): kern_return_t; cdecl external name 'thread_get_state';
function thread_set_state(target_act: thread_act_t; flavor: thread_state_flavor_t; new_state: thread_state_t; old_stateCnt: mach_msg_Type_number_t): kern_return_t; cdecl external name 'thread_set_state';

function posix_openpt(oflag: cint): cint;cdecl;external 'c' name 'posix_openpt';
function ptsname(__fd:longint):Pchar;cdecl;external 'c' name 'ptsname';
function grantpt(__fd:longint):longint;cdecl;external 'c' name 'grantpt';
function unlockpt(__fd:longint):longint;cdecl;external 'c' name 'unlockpt';

procedure RegisterDbgClasses;
begin
  OSDbgClasses.DbgProcessClass:=TDbgDarwinProcess;
  OSDbgClasses.DbgThreadClass:=TDbgDarwinThread;
end;

Function WIFSTOPPED(Status: Integer): Boolean;
begin
  WIFSTOPPED:=((Status and $FF)=$7F);
end;

{ TDbgDarwinThread }

Function safefpdup2(fildes, fildes2 : cInt): cInt;
begin
  repeat
    safefpdup2:=fpdup2(fildes,fildes2);
  until (safefpdup2<>-1) or (fpgeterrno<>ESysEINTR);
end;

{$ifndef VER2_6}
procedure TDbgDarwinProcess.OnForkEvent(Sender: TObject);
{$else}
procedure OnForkEvent;
{$endif VER2_6}
var
  ConsoleTtyFd: cint;
begin
  if FpSetsid<>0 then
    begin
    // For some reason, FpSetsid always fails.
    // writeln('Failed to set sid. '+inttostr(fpgeterrno));
    end;
  if GConsoleTty<>'' then
  begin
    ConsoleTtyFd:=FpOpen(GConsoleTty, O_RDWR + O_NOCTTY);
    if ConsoleTtyFd>-1 then
      begin
      if (FpIOCtl(ConsoleTtyFd, TIOCSCTTY, nil) = -1) then
        begin
        // This call always fails for some reason. That's also why login_tty can not be used. (login_tty
        // also calls TIOCSCTTY, but when it fails it aborts) The failure is ignored.
        // writeln('Failed to set tty '+inttostr(fpgeterrno));
        end;

      safefpdup2(ConsoleTtyFd,0);
      safefpdup2(ConsoleTtyFd,1);
      safefpdup2(ConsoleTtyFd,2);
      end
    else
      writeln('Failed to open tty '+GConsoleTty+'. Errno: '+inttostr(fpgeterrno));
  end;

  fpPTrace(PTRACE_TRACEME, 0, nil, nil);
end;

function TDbgDarwinThread.ReadThreadState: boolean;
var
  aKernResult: kern_return_t;
  old_StateCnt: mach_msg_Type_number_t;
begin
  if ID<0 then
    begin
    // The ID is set to -1 when the debugger does not have sufficient rights.
    // In that case just return zero's, so that the debuggee wil just run without
    // any problems/exceptions in the debugger.
    FillByte(FThreadState32, SizeOf(FThreadState32),0);
    FillByte(FThreadState64, SizeOf(FThreadState64),0);
    result := true;
    exit;
    end;
  if Process.Mode=dm32 then
    begin
    old_StateCnt:=x86_THREAD_STATE32_COUNT;
    aKernResult:=thread_get_state(Id,x86_THREAD_STATE32, @FThreadState32,old_StateCnt);
    end
  else
    begin
    old_StateCnt:=x86_THREAD_STATE64_COUNT;
    aKernResult:=thread_get_state(Id,x86_THREAD_STATE64, @FThreadState64,old_StateCnt);
    end;
  result := aKernResult = KERN_SUCCESS;
  if not result then
    begin
    Log('Failed to call thread_get_state for thread %d. Mach error: '+mach_error_string(aKernResult),[Id]);
    end;
  FRegisterValueListValid:=false;
  FDebugStateRead:=false;
end;

function TDbgDarwinThread.ReadDebugState: boolean;
var
  aKernResult: kern_return_t;
  old_StateCnt: mach_msg_Type_number_t;
begin
  if FDebugStateRead then
  begin
    result := true;
    exit;
  end;

  if Process.Mode=dm32 then
  begin
    old_StateCnt:=x86_DEBUG_STATE32_COUNT;
    aKernResult:=thread_get_state(ID, x86_DEBUG_STATE32, @FDebugState32, old_StateCnt);
  end
  else
  begin
    old_StateCnt:=x86_DEBUG_STATE64_COUNT;
    aKernResult:=thread_get_state(ID, x86_DEBUG_STATE64, @FDebugState64, old_StateCnt);
  end;
  if aKernResult <> KERN_SUCCESS then
  begin
    Log('Failed to call thread_get_state to ge debug-info for thread %d. Mach error: '+mach_error_string(aKernResult),[Id]);
    result := false;
  end
  else
  begin
    result := true;
    FDebugStateRead:=true;
  end;
end;

function TDbgDarwinThread.ResetInstructionPointerAfterBreakpoint: boolean;
var
  aKernResult: kern_return_t;
  new_StateCnt: mach_msg_Type_number_t;
begin
  result := true;
  if ID<0 then
    Exit;

  if Process.Mode=dm32 then
    begin
    Dec(FThreadState32.__eip);
    new_StateCnt := x86_THREAD_STATE32_COUNT;
    aKernResult:=thread_set_state(ID,x86_THREAD_STATE32, @FThreadState32, new_StateCnt);
    end
  else
    begin
    Dec(FThreadState64.__rip);
    new_StateCnt := x86_THREAD_STATE64_COUNT;
    aKernResult:=thread_set_state(ID,x86_THREAD_STATE64, @FThreadState64, new_StateCnt);
    end;

  if aKernResult <> KERN_SUCCESS then
    begin
    Log('Failed to call thread_set_state for thread %d. Mach error: '+mach_error_string(aKernResult),[Id]);
    result := false;
    end;
end;

type
  TDr32bitArr = array[0..4] of cuint32;
  TDr64bitArr = array[0..4] of cuint64;

function TDbgDarwinThread.AddWatchpoint(AnAddr: TDBGPtr): integer;

  function SetBreakpoint32(ind: byte): boolean;
  var
    drArr: ^TDr32bitArr;
  begin
    drArr := @FDebugState32.__dr0;
    if (drArr^[ind]=0) and ((FDebugState32.__dr7 and (1 shl ind))=0) then
    begin
      FDebugState32.__dr7 := FDebugState32.__dr7 or (1 shl (ind*2));
      FDebugState32.__dr7 := FDebugState32.__dr7 or ($30000 shl (ind*4));
      drArr^[ind]:=AnAddr;
      FDebugStateChanged:=true;
      Result := True;
    end
    else
    begin
      result := False;
    end;
  end;

  function SetBreakpoint64(ind: byte): boolean;
  var
    drArr: ^TDr64bitArr;
  begin
    drArr := @FDebugState64.__dr0;
    if (drArr^[ind]=0) and ((FDebugState64.__dr7 and (1 shl ind))=0) then
    begin
      FDebugState64.__dr7 := FDebugState64.__dr7 or (1 shl (ind*2));
      FDebugState64.__dr7 := FDebugState64.__dr7 or ($30000 shl (ind*4));
      drArr^[ind]:=AnAddr;
      FDebugStateChanged:=true;
      Result := True;
    end
    else
    begin
      result := False;
    end;
  end;

var
  i: integer;
begin
  result := -1;
  if ID<0 then
    Exit;
  if not ReadDebugState then
    exit;

  i := 0;
  if Process.Mode=dm32 then
    while (i<4) and not SetBreakpoint32(i) do
      inc(i)
  else
    while (i<4) and not SetBreakpoint64(i) do
      inc(i);
  if i=4 then
    Process.Log('No hardware breakpoint available.')
  else
    result := i;
end;

function TDbgDarwinThread.RemoveWatchpoint(AnId: integer): boolean;

  function RemoveBreakpoint32(ind: byte): boolean;
  var
    drArr: ^TDr32bitArr;
  begin
    drArr := @FDebugState32.__dr0;
    if (drArr^[ind]<>0) and ((FDebugState32.__dr7 and (1 shl (ind*2)))<>0) then
    begin
      FDebugState32.__dr7 := FDebugState32.__dr7 xor (1 shl (ind*2));
      FDebugState32.__dr7 := FDebugState32.__dr7 xor ($30000 shl (ind*4));
      drArr^[ind]:=0;
      FDebugStateChanged:=true;
      Result := True;
    end
    else
    begin
      result := False;
      Process.Log('HW watchpoint %d is not set.',[ind]);
    end;
  end;

  function RemoveBreakpoint64(ind: byte): boolean;
  var
    drArr: ^TDr64bitArr;
  begin
    drArr := @FDebugState64.__dr0;
    if (drArr^[ind]<>0) and ((FDebugState64.__dr7 and (1 shl (ind*2)))<>0) then
    begin
      FDebugState64.__dr7 := FDebugState64.__dr7 xor (1 shl (ind*2));
      FDebugState64.__dr7 := FDebugState64.__dr7 xor ($30000 shl (ind*4));
      drArr^[ind]:=0;
      FDebugStateChanged:=true;
      Result := True;
    end
    else
    begin
      result := False;
      Process.Log('HW watchpoint %d is not set.',[ind]);
    end;
  end;

begin
  result := false;
  if ID<0 then
    Exit;
  if not ReadDebugState then
    exit;

  if Process.Mode=dm32 then
    result := RemoveBreakpoint32(AnId)
  else
    result := RemoveBreakpoint64(AnId);
end;

function TDbgDarwinThread.DetectHardwareWatchpoint: integer;
var
  dr6: DWord;
begin
  result := -1;
  if ID<0 then
    Exit;
  if ReadDebugState then
    begin
    if Process.Mode=dm32 then
      dr6 := FDebugState32.__dr6
    else
      dr6 := lo(FDebugState64.__dr6);

    if dr6 and 1 = 1 then result := 0
    else if dr6 and 2 = 2 then result := 1
    else if dr6 and 4 = 4 then result := 2
    else if dr6 and 8 = 8 then result := 3;
    end;
end;

procedure TDbgDarwinThread.BeforeContinue;
var
  aKernResult: kern_return_t;
  old_StateCnt: mach_msg_Type_number_t;
begin
  if Process.CurrentWatchpoint>-1 then
    begin
    if Process.Mode=dm32 then
      FDebugState32.__dr6:=0
    else
      FDebugState64.__dr6:=0;
    FDebugStateChanged:=true;
    end;

  if FDebugStateRead and FDebugStateChanged then
  begin
    if Process.Mode=dm32 then
      begin
      old_StateCnt:=x86_DEBUG_STATE32_COUNT;
      aKernResult:=thread_set_state(Id, x86_DEBUG_STATE32, @FDebugState32, old_StateCnt);
      end
    else
      begin
      old_StateCnt:=x86_DEBUG_STATE64_COUNT;
      aKernResult:=thread_set_state(Id, x86_DEBUG_STATE64, @FDebugState64, old_StateCnt);
      end;

    if aKernResult <> KERN_SUCCESS then
      Log('Failed to call thread_set_state for thread %d. Mach error: '+mach_error_string(aKernResult),[Id]);
  end;
end;

procedure TDbgDarwinThread.LoadRegisterValues;
begin
  if Process.Mode=dm32 then with FThreadState32 do
  begin
    FRegisterValueList.DbgRegisterAutoCreate['eax'].SetValue(__eax, IntToStr(__eax),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['ecx'].SetValue(__ecx, IntToStr(__ecx),4,1);
    FRegisterValueList.DbgRegisterAutoCreate['edx'].SetValue(__edx, IntToStr(__edx),4,2);
    FRegisterValueList.DbgRegisterAutoCreate['ebx'].SetValue(__ebx, IntToStr(__ebx),4,3);
    FRegisterValueList.DbgRegisterAutoCreate['esp'].SetValue(__esp, IntToStr(__esp),4,4);
    FRegisterValueList.DbgRegisterAutoCreate['ebp'].SetValue(__ebp, IntToStr(__ebp),4,5);
    FRegisterValueList.DbgRegisterAutoCreate['esi'].SetValue(__esi, IntToStr(__esi),4,6);
    FRegisterValueList.DbgRegisterAutoCreate['edi'].SetValue(__edi, IntToStr(__edi),4,7);
    FRegisterValueList.DbgRegisterAutoCreate['eip'].SetValue(__eip, IntToStr(__eip),4,8);

    FRegisterValueList.DbgRegisterAutoCreate['eflags'].Setx86EFlagsValue(__eflags);

    FRegisterValueList.DbgRegisterAutoCreate['cs'].SetValue(__cs, IntToStr(__cs),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['ss'].SetValue(__ss, IntToStr(__ss),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['ds'].SetValue(__ds, IntToStr(__ds),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['es'].SetValue(__es, IntToStr(__es),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['fs'].SetValue(__fs, IntToStr(__fs),4,0);
    FRegisterValueList.DbgRegisterAutoCreate['gs'].SetValue(__gs, IntToStr(__gs),4,0);
  end else with FThreadState64 do
    begin
    FRegisterValueList.DbgRegisterAutoCreate['rax'].SetValue(__rax, IntToStr(__rax),8,0);
    FRegisterValueList.DbgRegisterAutoCreate['rbx'].SetValue(__rbx, IntToStr(__rbx),8,3);
    FRegisterValueList.DbgRegisterAutoCreate['rcx'].SetValue(__rcx, IntToStr(__rcx),8,2);
    FRegisterValueList.DbgRegisterAutoCreate['rdx'].SetValue(__rdx, IntToStr(__rdx),8,1);
    FRegisterValueList.DbgRegisterAutoCreate['rsi'].SetValue(__rsi, IntToStr(__rsi),8,4);
    FRegisterValueList.DbgRegisterAutoCreate['rdi'].SetValue(__rdi, IntToStr(__rdi),8,5);
    FRegisterValueList.DbgRegisterAutoCreate['rbp'].SetValue(__rbp, IntToStr(__rbp),8,6);
    FRegisterValueList.DbgRegisterAutoCreate['rsp'].SetValue(__rsp, IntToStr(__rsp),8,7);

    FRegisterValueList.DbgRegisterAutoCreate['r8'].SetValue(__r8, IntToStr(__r8),8,8);
    FRegisterValueList.DbgRegisterAutoCreate['r9'].SetValue(__r9, IntToStr(__r9),8,9);
    FRegisterValueList.DbgRegisterAutoCreate['r10'].SetValue(__r10, IntToStr(__r10),8,10);
    FRegisterValueList.DbgRegisterAutoCreate['r11'].SetValue(__r11, IntToStr(__r11),8,11);
    FRegisterValueList.DbgRegisterAutoCreate['r12'].SetValue(__r12, IntToStr(__r12),8,12);
    FRegisterValueList.DbgRegisterAutoCreate['r13'].SetValue(__r13, IntToStr(__r13),8,13);
    FRegisterValueList.DbgRegisterAutoCreate['r14'].SetValue(__r14, IntToStr(__r14),8,14);
    FRegisterValueList.DbgRegisterAutoCreate['r15'].SetValue(__r15, IntToStr(__r15),8,15);

    FRegisterValueList.DbgRegisterAutoCreate['rip'].SetValue(__rip, IntToStr(__rip),8,16);
    FRegisterValueList.DbgRegisterAutoCreate['eflags'].Setx86EFlagsValue(__rflags);

    FRegisterValueList.DbgRegisterAutoCreate['cs'].SetValue(__cs, IntToStr(__cs),8,43);
    FRegisterValueList.DbgRegisterAutoCreate['fs'].SetValue(__fs, IntToStr(__fs),8,46);
    FRegisterValueList.DbgRegisterAutoCreate['gs'].SetValue(__gs, IntToStr(__gs),8,47);
  end;
  FRegisterValueListValid:=true;
end;

{ TDbgDarwinProcess }

function TDbgDarwinProcess.GetDebugAccessRights: boolean;
var
  authFlags: AuthorizationFlags;
  stat: OSStatus;
  author: AuthorizationRef;
  authItem: AuthorizationItem;
  authRights: AuthorizationRights;
begin
  result := false;
  authFlags := kAuthorizationFlagExtendRights or kAuthorizationFlagPreAuthorize or kAuthorizationFlagInteractionAllowed or ( 1 << 5);

  stat := AuthorizationCreate(nil, kAuthorizationEmptyEnvironment, authFlags, author);
  if stat <> errAuthorizationSuccess then
    begin
    debugln('Failed to create authorization. Authorization error: ' + inttostr(stat));
    exit;
    end;

  authItem.name:='system.privilege.taskport';
  authItem.flags:=0;
  authItem.value:=nil;
  authItem.valueLength:=0;

  authRights.count:=1;
  authRights.items:=@authItem;

  stat := AuthorizationCopyRights(author, authRights, kAuthorizationEmptyEnvironment, authFlags, nil);
  if stat <> errAuthorizationSuccess then
    begin
    debugln('Failed to get debug-(taskport)-privilege. Authorization error: ' + inttostr(stat));
    exit;
    end;
  result := true;
end;

procedure TDbgDarwinProcess.InitializeLoaders;
var
  dSYMFilename: string;
  PrimaryLoader: TDbgImageLoader;
  ALoader: TDbgImageLoader;
begin
  ALoader:=nil;
  PrimaryLoader := TDbgImageLoader.Create(FExecutableFilename);
  LoaderList.Add(PrimaryLoader);

  // JvdS: Mach-O binaries do not contain DWARF-debug info. Instead this info
  // is stored inside the .o files, and the executable contains a map (in stabs-
  // format) of all these .o files. An alternative to parsing this map and reading
  // those .o files a dSYM-bundle could be used, which could be generated
  // with dsymutil.
  dSYMFilename:=ChangeFileExt(FExecutableFilename, '.dSYM');
  dSYMFilename:=dSYMFilename+'/Contents/Resources/DWARF/'+ExtractFileName(Name);

  if ExtractFileExt(dSYMFilename)='.app' then
    dSYMFilename := ChangeFileExt(dSYMFilename,'');

  if FileExists(dSYMFilename) then
    begin
    ALoader := TDbgImageLoader.Create(dSYMFilename);
    if GUIDToString(ALoader.UUID)<>GUIDToString(PrimaryLoader.UUID) then
      begin
      log('The unique UUID''s of the executable and the dSYM bundle with debug-info ('+dSYMFilename+') do not match.', dllDebug);
      FreeAndNil(ALoader);
      end
    else
      begin
      log('Load debug-info from dSYM bundle ('+dSYMFilename+').', dllDebug);
      LoaderList.Add(ALoader);
      end;
    end;

  if not assigned(ALoader) then
    begin
    log('Read debug-info from separate object files.', dllDebug);
    TDbgMachoDataSource.LoadSubFiles(PrimaryLoader.SubFiles, LoaderList);
    end;
end;

function TDbgDarwinProcess.CreateThread(AthreadIdentifier: THandle; out IsMainThread: boolean): TDbgThread;
begin
  IsMainThread:=true;
  result := TDbgDarwinThread.Create(Self, AthreadIdentifier, AthreadIdentifier)
end;

constructor TDbgDarwinProcess.Create(const AName: string; const AProcessID,
  AThreadID: Integer; AOnLog: TOnLog);
var
  aKernResult: kern_return_t;
begin
  inherited Create(AName, AProcessID, AThreadID, AOnLog);

  GetDebugAccessRights;
  aKernResult:=task_for_pid(mach_task_self, AProcessID, FTaskPort);
  if aKernResult <> KERN_SUCCESS then
    begin
    log('Failed to get task for process '+IntToStr(AProcessID)+'. Probably insufficient rights to debug applications. Mach error: '+mach_error_string(aKernResult), dllInfo);
    end;
end;

destructor TDbgDarwinProcess.Destroy;
begin
  FProcProcess.Free;
  inherited Destroy;
end;

class function TDbgDarwinProcess.StartInstance(AFileName: string; AParams, AnEnvironment: TStrings; AWorkingDirectory, AConsoleTty: string; AOnLog: TOnLog; ReDirectOutput: boolean): TDbgProcess;
var
  PID: TPid;
  AProcess: TProcess;
  AnExecutabeFilename: string;
  AMasterPtyFd: cint;
begin
  result := nil;

  AnExecutabeFilename:=ExcludeTrailingPathDelimiter(AFileName);
  if DirectoryExists(AnExecutabeFilename) then
    begin
    if not (ExtractFileExt(AnExecutabeFilename)='.app') then
      begin
      DebugLn(format('Can not debug %s, because it''s a directory',[AnExecutabeFilename]));
      Exit;
      end;

    AnExecutabeFilename := AnExecutabeFilename + '/Contents/MacOS/' + ChangeFileExt(ExtractFileName(AnExecutabeFilename),'');
    if not FileExists(AFileName) then
      begin
      DebugLn(format('Can not find  %s.',[AnExecutabeFilename]));
      Exit;
      end;
    end;

  AMasterPtyFd:=-1;
  if ReDirectOutput then
    begin
    if AConsoleTty<>'' then
      AOnLog('It is of no use to provide a console-tty when the console output is being redirected.', dllInfo);
    AMasterPtyFd := posix_openpt(O_RDWR + O_NOCTTY);
    if AMasterPtyFd<0 then
      AOnLog('Failed to open pseudo-tty. Errno: ' + IntToStr(fpgeterrno), dllError)
    else
      begin
      if grantpt(AMasterPtyFd)<>0 then
        AOnLog('Failed to set pseudo-tty slave permissions. Errno: ' + IntToStr(fpgeterrno), dllError);
      if unlockpt(AMasterPtyFd)<>0 then
        AOnLog('Failed to unlock pseudo-tty slave. Errno: ' + IntToStr(fpgeterrno), dllError);
      AConsoleTty := strpas(ptsname(AMasterPtyFd));
      end;
    end;

  AProcess := TProcess.Create(nil);
  try
    AProcess.OnForkEvent:=@OnForkEvent;
    AProcess.Executable:=AnExecutabeFilename;
    AProcess.Parameters:=AParams;
    AProcess.Environment:=AnEnvironment;
    AProcess.CurrentDirectory:=AWorkingDirectory;
    GConsoleTty := AConsoleTty;

    AProcess.Execute;
    PID:=AProcess.ProcessID;

    sleep(100);
    result := TDbgDarwinProcess.Create(AFileName, Pid, -1, AOnLog);
    TDbgDarwinProcess(result).FMasterPtyFd := AMasterPtyFd;
    TDbgDarwinProcess(result).FProcProcess := AProcess;
    TDbgDarwinProcess(result).FExecutableFilename := AnExecutabeFilename;
  except
    on E: Exception do
    begin
      AOnLog(Format('Failed to start process "%s". Errormessage: "%s".',[AFileName, E.Message]), dllInfo);
      AProcess.Free;

      if AMasterPtyFd>-1 then
        FpClose(AMasterPtyFd);
    end;
  end;
end;

function TDbgDarwinProcess.ReadData(const AAdress: TDbgPtr;
  const ASize: Cardinal; out AData): Boolean;
var
  aKernResult: kern_return_t;
  cnt: mach_msg_Type_number_t;
  b: pointer;
begin
  result := false;

  aKernResult := mach_vm_read(FTaskPort, AAdress, ASize, PtrUInt(b), cnt);
  if aKernResult <> KERN_SUCCESS then
    begin
    DebugLn('Failed to read data at address '+FormatAddress(AAdress)+'. Mach error: '+mach_error_string(aKernResult));
    Exit;
    end;
  System.Move(b^, AData, Cnt);
  MaskBreakpointsInReadData(AAdress, ASize, AData);
  result := true;
end;

function TDbgDarwinProcess.WriteData(const AAdress: TDbgPtr;
  const ASize: Cardinal; const AData): Boolean;
var
  aKernResult: kern_return_t;
begin
  result := false;
  aKernResult:=mach_vm_protect(FTaskPort, AAdress, ASize, boolean_t(false), 7 {VM_PROT_READ + VM_PROT_WRITE + VM_PROT_COPY});
  if aKernResult <> KERN_SUCCESS then
    begin
    DebugLn('Failed to call vm_protect for address '+FormatAddress(AAdress)+'. Mach error: '+mach_error_string(aKernResult));
    Exit;
    end;

  aKernResult := mach_vm_write(FTaskPort, AAdress, vm_offset_t(@AData), ASize);
  if aKernResult <> KERN_SUCCESS then
    begin
    DebugLn('Failed to write data at address '+FormatAddress(AAdress)+'. Mach error: '+mach_error_string(aKernResult));
    Exit;
    end;

  result := true;
end;

function TDbgDarwinProcess.CheckForConsoleOutput(ATimeOutMs: integer): integer;
Var
  f: TfdSet;
  sleepytime: ttimeval;
begin
  sleepytime.tv_sec := ATimeOutMs div 1000;
  sleepytime.tv_usec := (ATimeOutMs mod 1000)*1000;
  FpFD_ZERO(f);
  fpFD_SET(FMasterPtyFd,f);
  result := fpselect(FMasterPtyFd+1,@f,nil,nil,@sleepytime);
end;

function TDbgDarwinProcess.GetConsoleOutput: string;
var
  ABytesRead: cint;
  ABuf: array[0..1023] of char;
begin
  ABytesRead := fpRead(FMasterPtyFd, ABuf[0], SizeOf(ABuf));
  if ABytesRead>0 then
    result := Copy(ABuf, 0, ABytesRead)
  else
    result := '';
end;

procedure TDbgDarwinProcess.SendConsoleInput(AString: string);
begin
  if FpWrite(FMasterPtyFd, AString[1], length(AString)) <> Length(AString) then
    Log('Failed to send input to console.', dllDebug);
end;

function TDbgDarwinProcess.GetInstructionPointerRegisterValue: TDbgPtr;
begin
  if Mode=dm32 then
    result := TDbgDarwinThread(FMainThread).FThreadState32.__eip
  else
    result := TDbgDarwinThread(FMainThread).FThreadState64.__rip;
end;

function TDbgDarwinProcess.GetStackPointerRegisterValue: TDbgPtr;
begin
  if Mode=dm32 then
    result := TDbgDarwinThread(FMainThread).FThreadState32.__esp
  else
    result := TDbgDarwinThread(FMainThread).FThreadState64.__rsp;
end;

function TDbgDarwinProcess.GetStackBasePointerRegisterValue: TDbgPtr;
begin
  if Mode=dm32 then
    result := TDbgDarwinThread(FMainThread).FThreadState32.__ebp
  else
    result := TDbgDarwinThread(FMainThread).FThreadState64.__rbp;
end;

procedure TDbgDarwinProcess.TerminateProcess;
begin
  FIsTerminating:=true;
  if fpkill(ProcessID,SIGKILL)<>0 then
    begin
    log('Failed to send SIGKILL to process %d. Errno: %d',[ProcessID, errno]);
    FIsTerminating:=false;
    end;
end;

function TDbgDarwinProcess.Continue(AProcess: TDbgProcess; AThread: TDbgThread; SingleStep: boolean): boolean;
var
  e: integer;
begin
  fpseterrno(0);
{$ifdef linux}
  fpPTrace(PTRACE_CONT, ProcessID, nil, nil);
{$endif linux}
{$ifdef darwin}
  AThread.NextIsSingleStep:=SingleStep;
  AThread.BeforeContinue;
  if SingleStep or assigned(FCurrentBreakpoint) then
    fpPTrace(PTRACE_SINGLESTEP, ProcessID, pointer(1), pointer(FExceptionSignal))
  else if FIsTerminating then
    fpPTrace(PTRACE_KILL, ProcessID, pointer(1), nil)
  else
    fpPTrace(PTRACE_CONT, ProcessID, pointer(1), pointer(FExceptionSignal));
{$endif darwin}
  e := fpgeterrno;
  if e <> 0 then
    begin
    log('Failed to continue process. Errcode: '+inttostr(e));
    result := false;
    end
  else
    result := true;
end;

function TDbgDarwinProcess.WaitForDebugEvent(out ProcessIdentifier, ThreadIdentifier: THandle): boolean;
var
  aKernResult: kern_return_t;
  act_list: thread_act_array_t;
  act_listCtn: mach_msg_type_number_t;
begin
  ThreadIdentifier:=-1;

  ProcessIdentifier:=FpWaitPid(-1, FStatus, 0);

  result := ProcessIdentifier<>-1;
  if not result then
    Log('Failed to wait for debug event. Errcode: %d', [fpgeterrno])
  else if (WIFSTOPPED(FStatus)) then
    begin
    aKernResult := task_threads(FTaskPort, act_list, act_listCtn);
    if aKernResult <> KERN_SUCCESS then
      begin
      Log('Failed to call task_threads. Mach error: '+mach_error_string(aKernResult));
      end
    else if act_listCtn>0 then
      ThreadIdentifier := act_list^[0];
    end
end;

function TDbgDarwinProcess.Pause: boolean;
begin
  result := FpKill(ProcessID, SIGTRAP)=0;
end;

function TDbgDarwinProcess.AnalyseDebugEvent(AThread: TDbgThread): TFPDEvent;

begin
  FExceptionSignal:=0;
  if wifexited(FStatus) or wifsignaled(FStatus) then
    begin
    SetExitCode(wexitStatus(FStatus));
    // Clear all pending signals
    repeat
    until FpWaitPid(-1, FStatus, WNOHANG)<1;

    result := deExitProcess
    end
  else if WIFSTOPPED(FStatus) then
    begin
    //log('Stopped ',FStatus, ' signal: ',wstopsig(FStatus));
    TDbgDarwinThread(AThread).ReadThreadState;
    case wstopsig(FStatus) of
      SIGTRAP:
        begin
        if not FProcessStarted then
          begin
          result := deCreateProcess;
          FProcessStarted:=true;
          end
        else
          result := deBreakpoint;
        end;
      SIGBUS:
        begin
        ExceptionClass:='SIGBUS';
        FExceptionSignal:=SIGBUS;
        result := deException;
        end;
      SIGINT:
        begin
        ExceptionClass:='SIGINT';
        FExceptionSignal:=SIGINT;
        result := deException;
        end;
      SIGSEGV:
        begin
        ExceptionClass:='SIGSEGV';
        FExceptionSignal:=SIGSEGV;
        result := deException;
        end;
      SIGKILL:
        begin
        if FIsTerminating then
          result := deInternalContinue
        else
          begin
          ExceptionClass:='SIGKILL';
          FExceptionSignal:=SIGKILL;
          result := deException;
          end;
        end;
      SIGCHLD:
        begin
        FExceptionSignal:=SIGCHLD;
        result := deInternalContinue;
        end
      else
        begin
        ExceptionClass:='Unknown exception code '+inttostr(wstopsig(FStatus));
        FExceptionSignal:=wstopsig(FStatus);
        result := deException;
        end;
    end; {case}
    if result=deException then
      ExceptionClass:='External: '+ExceptionClass;
    end
  else
    raise exception.CreateFmt('Received unknown status %d from process with pid=%d',[FStatus, ProcessID]);
end;

end.
