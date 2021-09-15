unit FpDbgRsp;

interface

uses
  Classes, SysUtils, ssockets, DbgIntfDebuggerBase, DbgIntfBaseTypes,
  FpDbgClasses;

const
  // Possible signal numbers that can be expected over rsp
  // for now only cater for posix like signals
  SIGHUP     = 1;
  SIGINT     = 2;
  SIGQUIT    = 3;
  SIGILL     = 4;
  SIGTRAP    = 5;
  SIGABRT    = 6;
  SIGIOT     = 6;
  SIGBUS     = 7;
  SIGFPE     = 8;
  SIGKILL    = 9;
  SIGUSR1    = 10;
  SIGSEGV    = 11;
  SIGUSR2    = 12;
  SIGPIPE    = 13;
  SIGALRM    = 14;
  SIGTERM    = 15;
  SIGSTKFLT  = 16;
  SIGCHLD    = 17;
  SIGCONT    = 18;
  SIGSTOP    = 19;
  SIGTSTP    = 20;
  SIGTTIN    = 21;
  SIGTTOU    = 22;
  SIGURG     = 23;
  SIGXCPU    = 24;
  SIGXFSZ    = 25;
  SIGVTALRM  = 26;
  SIGPROF    = 27;
  SIGWINCH   = 28;
  SIGIO      = 29;
  SIGPOLL    = SIGIO;
  SIGPWR     = 30;
  SIGUNUSED  = 31;

type
  TInitializedRegister = record
    Initialized: boolean;
    Value: qword; // sized to handle largest register, should truncate as required to smaller registers
  end;
  TInitializedRegisters = array of TInitializedRegister;

  TStopReason = (srNone, srSWBreakPoint, srHWBreakPoint, srWriteWatchPoint, srReadWatchPoint, srAnyWatchPoint);

  TStatusEvent = record
    signal: integer;
    coreID: integer;
    threadID: integer;
    stopReason: TStopReason;
    watchPointAddress: qword;  // contains address which triggered watch point
    registers: TInitializedRegisters;
  end;

  { TRspConnection }

  TRspConnection = class(TInetSocket)
  private
    FState: integer;
    FStatusEvent: TStatusEvent;
    fCS: TRTLCriticalSection;
    FFileName: string;
    FOwner: TDbgProcess;
    // Catch exceptions and store as socket errors
    FSockErr: boolean;
    procedure FSetRegisterCacheSize(sz: cardinal);
    procedure FResetStatusEvent;
    // Blocking
    function FWaitForData(): boolean; overload;
    function FWaitForData(timeout_ms: integer): boolean; overload;

    // Wrappers to catch exceptions and set SockErr
    function SafeReadByte: byte;
    function SafeWrite(const buffer; count : Longint): Longint;
    procedure SafeWriteByte(b: Byte);

    function FReadReply(out retval: string): boolean;
    function FSendCommand(const cmd: string): boolean;
    // Send command and wait for acknowledge
    function FSendCommandOK(const cmd: string): boolean;
    // Return reply to cmd
    function FSendCmdWaitForReply(const cmd: string; out reply: string): boolean;

    // Note that numbers are transmitted as hex characters in target endian sequence
    // For little endian targets this creates an endian swap if the string is parsed by Val
    // because a hex representation of a number is interpreted as big endian
    function convertHexWithLittleEndianSwap(constref hextext: string; out value: qword): boolean;
    function FHexEncodeStr(s: string): string;
    function FHexDecodeStr(hexcode: string): string;
  public
    constructor Create(AFileName: string; AOwner: TDbgProcess); Overload;
    destructor Destroy; override;
    // Wait for async signal - blocking
    function WaitForSignal(out msg: string; out registers: TInitializedRegisters): integer;

    procedure Break();
    function Kill(): boolean;
    function Detach(): boolean;
    function MustReplyEmpty: boolean;
    function SetBreakWatchPoint(addr: PtrUInt; BreakWatchKind: TDBGWatchPointKind; watchsize: integer = 1): boolean;
    function DeleteBreakWatchPoint(addr: PtrUInt; BreakWatchKind: TDBGWatchPointKind; watchsize: integer = 1): boolean;
    // TODO: no support thread ID or different address
    function Continue(): boolean;
    function SingleStep(): boolean;

    // Data exchange
    function ReadDebugReg(ind: byte; out AVal: TDbgPtr): boolean;
    function WriteDebugReg(ind: byte; AVal: TDbgPtr): boolean;
    function ReadRegisters(out regs; const sz: integer): boolean;  // size is not required by protocol, but is used to preallocate memory for the response
    function WriteRegisters(constref regs; const sz: integer): boolean;
    function ReadData(const AAddress: TDbgPtr; const ASize: cardinal; out AData
      ): boolean;
    function WriteData(const AAdress: TDbgPtr;
      const ASize: Cardinal; const AData): Boolean;

    function SendMonitorCmd(const s: string): boolean;
    // check state of target - ?
    function Init: integer;

    property State: integer read FState;
    property RegisterCacheSize: cardinal write FSetRegisterCacheSize;
    property lastStatusEvent: TStatusEvent read FStatusEvent;
    property SockErr: boolean read FSockErr;
  end;

var
  AHost: string = 'localhost';
  APort: integer = 2345;
  AUploadBinary: boolean = False;
  AAfterConnectMonitorCmds: TStringList;
  ASkipSectionsList: TStringList;
  AAfterUploadBreakZero: boolean;
  AAfterUploadMonitorReset: boolean;

implementation

uses
  {$ifdef FORCE_LAZLOGGER_DUMMY} LazLoggerDummy {$else} LazLoggerBase {$endif}, StrUtils,
  FpDbgClasses, FpImgReaderBase,
  {$IFNDEF WINDOWS}BaseUnix, termio;
  {$ELSE}winsock2, windows;
  {$ENDIF}

var
  DBG_VERBOSE, DBG_WARNINGS, DBG_RSP: PLazLoggerLogGroup;

procedure TRspConnection.FSetRegisterCacheSize(sz: cardinal);
begin
  SetLength(FStatusEvent.registers, sz);
end;

procedure TRspConnection.FResetStatusEvent;
var
  i: integer;
begin
  with FStatusEvent do
  begin
    signal := 0;
    coreID := 0;
    threadID := 0;
    stopReason := srNone;
    watchPointAddress := 0;
    for i := low(registers) to high(registers) do
    begin
      registers[i].Initialized := false;
      registers[i].Value := 0;
    end;
  end;
end;

function TRspConnection.FWaitForData({timeout: integer}): boolean;
{$if defined(unix) or defined(windows)}
var
  FDS: TFDSet;
  r: integer;
{$endif}
begin
  Result:=False;
  if SockErr then exit;
{$if defined(unix)}
  FDS := Default(TFDSet);
  fpFD_Zero(FDS);
  fpFD_Set(self.Handle, FDS);
  fpSelect(self.Handle + 1, @FDS, nil, nil, nil);
  // FDS is set even if the socket has been closed.
  // Read available data and if 0 data is available then socket must be closed/ or error
  r := 0;
  FpIOCtl(self.Handle, FIONREAD, @r);
  Result := r > 0;
{$elseif defined(windows)}
  FDS := Default(TFDSet);
  FD_Zero(FDS);
  FD_Set(self.Handle, FDS);
  Result := winsock2.Select(self.Handle + 1, @FDS, nil, nil, nil) > SOCKET_ERROR;
{$endif}
end;

function TRspConnection.FWaitForData(timeout_ms: integer): boolean;
{$if defined(unix) or defined(windows)}
var
  FDS: TFDSet;
  TimeV: TTimeVal;
{$endif}
begin
  Result:=False;
  if SockErr then exit;
//{$if defined(unix) or defined(windows)}
  TimeV.tv_usec := timeout_ms * 1000;  // 1 msec
  TimeV.tv_sec := 0;
//{$endif}
{$ifdef unix}
  FDS := Default(TFDSet);
  fpFD_Zero(FDS);
  fpFD_Set(self.Handle, FDS);
  Result := fpSelect(self.Handle + 1, @FDS, nil, nil, @TimeV) > 0;
{$else}
{$ifdef windows}
  FDS := Default(TFDSet);
  FD_Zero(FDS);
  FD_Set(self.Handle, FDS);
  Result := winsock2.Select(self.Handle + 1, @FDS, nil, nil, @TimeV) > 0;
{$endif}
{$endif}
end;

function TRspConnection.SafeReadByte: byte;
begin
  try
    Result := ReadByte;
  except
    FSockErr := true;
    Result := 0;
  end;
end;

function TRspConnection.SafeWrite(const buffer; count: Longint): Longint;
begin
  try
    Result := Write(buffer, count);
  except
    FSockErr := true;
    Result := 0;
  end;
end;

procedure TRspConnection.SafeWriteByte(b: Byte);
begin
  try
    WriteByte(b);
  except
    FSockErr := true;
  end;
end;

function TRspConnection.FSendCommand(const cmd: string): boolean;
var
  checksum: byte;
  i, totalSent: integer;
  s: string;
begin
  Result := false;
  if SockErr then exit;
  checksum := 0;
  for i := 1 to length(cmd) do
    checksum := byte(checksum + ord(cmd[i]));

  s := '$'+cmd+'#'+IntToHex(checksum, 2);
  totalSent := SafeWrite(s[1], length(s));

  result := (totalSent = length(s));
  if not result then
    DebugLn(DBG_WARNINGS, ['Warning: TRspConnection.FSendRspCommand error.'])
  else
    DebugLn(DBG_RSP, ['RSP -> ', cmd]);
end;

function TRspConnection.FSendCommandOK(const cmd: string): boolean;
var
  c: char;
  retryCount: integer;
begin
  result := false;
  if SockErr then exit;
  retryCount := 0;

  repeat
    if FSendCommand(cmd) then
    begin
      // now check if target returned error, resend ('-') or ACK ('+')
      // No support for ‘QStartNoAckMode’, i.e. always expect a -/+
      c := char(SafeReadByte);
      result := c = '+';
      if not result then
        inc(retryCount);
    end
    else
      inc(retryCount);
  // Abort this command if no ACK after 5 attempts
  until result or (retryCount > 5) or SockErr;
end;

function TRspConnection.FReadReply(out retval: string): boolean;
const failcountmax = 1000;
var
  c: char;
  s: string;
  i: integer;
  cksum, calcSum: byte;
begin
  Result := false;
  if SockErr then exit;
  i := 0;
  s := '';
  repeat
    c := chr(SafeReadByte);
    inc(i);
    s := s + c;
  until (c = '$') or (i = failcountmax) or SockErr;  // exit loop after start or count expired

  if c <> '$' then
  begin
    DebugLn(DBG_WARNINGS, ['Warning: Timeout waiting for RSP reply']);
    result := false;
    retval := '';
    exit;
  end
  else if i > 1 then
    DebugLn(DBG_WARNINGS, ['Warning: Discarding unexpected data before start of new message', s])
  else if SockErr then
    DebugLn(DBG_WARNINGS, ['Warning: socket error.']);

  c := chr(SafeReadByte);
  s := '';
  calcSum := 0;
  while c <> '#' do
  begin
    calcSum := byte(calcSum+byte(c));

    if c=#$7D then // escape marker, unescape data
    begin
      c := char(SafeReadByte);

      // Something weird happened
      if c = '#' then
      begin
        DebugLn(DBG_WARNINGS, ['Warning: Received end of packet marker in escaped sequence: ', c]);
        break;
      end;

      calcSum := byte(calcSum + byte(c));

      c := char(byte(c) xor $20);
    end;

    s := s + c;
    c := char(SafeReadByte);
  end;

  cksum := StrToInt('$' + char(SafeReadByte) + char(SafeReadByte));

  // Ignore checksum for now
  SafeWriteByte(byte('+'));
  result := not SockErr;
  retval := s;
  if not (calcSum = cksum) then
  begin
    DebugLn(DBG_WARNINGS, ['Warning: Reply packet with invalid checksum: ', s]);
  end;

  DebugLn(DBG_RSP, ['RSP <- ', retval]);
end;

function TRspConnection.FSendCmdWaitForReply(const cmd: string; out reply: string
  ): boolean;
var
  retryCount: integer;
begin
  reply := '';
  if SockErr then exit;
  retryCount := 0;

  if FSendCommandOK(cmd) then
  begin
    // Read reply, with retry if no success
    repeat
      result := FReadReply(reply);
      if not result then
      begin
        inc(retryCount);
        SafeWriteByte(ord('-'));
      end;
    until result or (retryCount > 5) or SockErr;
  end;

  if retryCount > 5 then
    DebugLn(DBG_WARNINGS, ['Warning: Retries exceeded in TRspConnection.FSendCmdWaitForReply for cmd: ', cmd]);
end;

function TRspConnection.convertHexWithLittleEndianSwap(constref
  hextext: string; out value: qword): boolean;
var
  err: integer;
begin
  Val('$'+hextext, value, err);
  if (err = 0) then
  begin
    result := true;
    case length(hextext) of
      2: ; // no conversion required
      4:  value := SwapEndian(word(value));
      8:  value := SwapEndian(dword(value));
      16: value := SwapEndian(value);
      else
      begin
        result := false;
        DebugLn(DBG_WARNINGS, ['Warning: Unexpected hex length: ', IntToStr(length(hextext))]);
      end;
    end;
  end
  else
    result := false;
end;

function TRspConnection.FHexEncodeStr(s: string): string;
var
  i: integer;
  tmp: string;
begin
  setlength(Result, length(s)*2);
  for i := 1 to length(s) do
  begin
    tmp := HexStr(ord(s[i]), 2);
    Result[2*i - 1] := tmp[1];
    Result[2*i] := tmp[2];
  end;
end;

function TRspConnection.FHexDecodeStr(hexcode: string): string;
var
  i: integer;
  s: string;
begin
  SetLength(Result, length(hexCode) div 2);
  for i := 1 to length(Result) do
  begin
    s := '$' + hexCode[2*i-1] + hexCode[2*i];
    result[i] := char(StrToInt(s));
  end;
end;

procedure TRspConnection.Break();
begin
  EnterCriticalSection(fCS);
  try
     SafeWriteByte(3);  // Ctrl-C
  finally
    LeaveCriticalSection(fCS);
  end;
end;

function TRspConnection.Kill(): boolean;
var
  c: char;
begin
  EnterCriticalSection(fCS);
  try
    result := FSendCommand('k');
    // Swallow the last ack if send
    result := not(SockErr) and FWaitForData(1000);
  finally
    LeaveCriticalSection(fCS);
  end;

  if result then
  begin
    c := char(SafeReadByte);
    Result := c = '+';
  end;
end;

function TRspConnection.Detach(): boolean;
var
  reply: string;
begin
  EnterCriticalSection(fCS);
  try
    result := FSendCmdWaitForReply('D', reply);
  finally
    LeaveCriticalSection(fCS);
  end;
  result := not(SockErr) and (pos('OK', reply) = 1);
end;

constructor TRspConnection.Create(AFileName: string; AOwner: TDbgProcess);
var
  FSocketHandler: TSocketHandler;
begin
  { Create a socket handler, so that TInetSocket.Create call doesn't automatically connect.
    This can raise an exception when connection fails.
    The FSocketHandler instance will be managed by TInetSocket. }
  FSocketHandler := TSocketHandler.Create;
  inherited Create(AHost, APort, FSocketHandler);
  InitCriticalSection(fCS);
  FFileName := AFileName;
  FOwner := AOwner;
  FSockErr := false;
end;

destructor TRspConnection.Destroy;
begin
  inherited;
  DoneCriticalSection(fCS);
end;

function TRspConnection.WaitForSignal(out msg: string; out
  registers: TInitializedRegisters): integer;
var
  res: boolean;
  startIndex, colonIndex, semicolonIndex: integer;
  tmp, tmp2: qword;
  part1, part2: string;
begin
  result := 0;
  res := false;
  SetLength(registers, 0);

  EnterCriticalSection(fCS);
  try
    // False if no data available, e.g. socket is closed
    if not FWaitForData() then
    begin
      msg := '';
      result := SIGHUP;
      exit;
    end;

    try
      res := FReadReply(msg);
    except
      on E: Exception do
        DebugLn(DBG_WARNINGS, ['Warning: WaitForSignal exception: ', E.Message]);
    end;
  finally
    LeaveCriticalSection(fCS);
  end;

  if res then
  begin
    if (length(msg) > 2) and (msg[1] in ['S', 'T']) then
    begin
      try
        FResetStatusEvent;
        result := StrToInt('$' + copy(msg, 2, 2));
        FState := result;
        FStatusEvent.signal := result;
        if (msg[1] = 'T') and (length(msg) > 6) then // not much meaning can be returned in less than 2 bytes
        begin
          startIndex := 4; // first part of message TAA... is already parsed, rest should be nn:rr; pairs
          repeat
            colonIndex := posex(':', msg, startIndex);
            semicolonIndex := posex(';', msg, startIndex);
            // Check if there is a first part
            if colonIndex > startIndex then
              part1 := copy(msg, startIndex, colonIndex-startIndex)
            else
              part1 := '';

            if (part1 <> '') and (semicolonIndex > colonIndex + 1) then
              part2 := copy(msg, colonIndex+1, semicolonIndex - colonIndex - 1)
            else
              part2 := '';

            // Check for stop reason
            case part1 of
              'watch','rwatch','awatch':
              begin
                case part1 of
                  'watch': FStatusEvent.stopReason := srWriteWatchPoint;
                  'rwatch': FStatusEvent.stopReason := srReadWatchPoint;
                  'awatch': FStatusEvent.stopReason := srAnyWatchPoint;
                end;
                if convertHexWithLittleEndianSwap(part2, tmp) then
                  FStatusEvent.watchPointAddress := tmp
                else
                  DebugLn(DBG_WARNINGS, format('Invalid value received for %s: %s ', [part1, part2]));
              end;
              'swbreak':
              begin
                FStatusEvent.stopReason := srSWBreakPoint;
              end;
              'hwbreak':
              begin
                FStatusEvent.stopReason := srHWBreakPoint;
              end;
              else // catch valid hex numbers - will be register info
              begin
                // check if part1 is a number, this should then be a register index
                if convertHexWithLittleEndianSwap(part1, tmp) and convertHexWithLittleEndianSwap(part2, tmp2) then
                begin
                  if tmp < length(FStatusEvent.registers) then
                  begin
                    FStatusEvent.registers[tmp].Value := tmp2;
                    FStatusEvent.registers[tmp].Initialized := true;
                  end
                  else
                    DebugLn(DBG_WARNINGS, format('Register index exceeds total number of registers (%d > %d] ',
                            [tmp, length(FStatusEvent.registers)]));
                end
                else
                  DebugLn(DBG_WARNINGS, format('Ignoring stop reply  pair [%s:%s] ', [part1, part2]));
              end;
            end;
            startIndex := semicolonIndex + 1;
          until (semicolonIndex = 0) or (semicolonIndex = length(msg));
        end;
      except
        DebugLn(DBG_WARNINGS, ['Error converting signal number from reply: ', msg]);
      end;
    end
    else
      DebugLn(DBG_WARNINGS, ['Unexpected WaitForSignal reply: ', msg]);
  end;
end;

function TRspConnection.MustReplyEmpty: boolean;
var
  reply: string;
begin
  EnterCriticalSection(fCS);
  try
    FSendCmdWaitForReply('vMustReplyEmpty', reply);
  finally
    LeaveCriticalSection(fCS);
  end;
  result := not(SockErr) and (reply = '');
  if not result then
    DebugLn(DBG_WARNINGS, ['Warning: vMustReplyEmpty command returned unexpected result: ', reply]);
end;

function TRspConnection.SetBreakWatchPoint(addr: PtrUInt;
  BreakWatchKind: TDBGWatchPointKind; watchsize: integer): boolean;
var
  cmd, reply: string;
begin
  cmd := 'Z';
  case BreakWatchKind of
    wpkWrite: cmd := cmd + '2,' + IntToHex(addr, 4) + ',' + IntToHex(watchsize, 4);
    wpkRead:  cmd := cmd + '3,' + IntToHex(addr, 4) + ',' + IntToHex(watchsize, 4);
    wpkReadWrite: cmd := cmd + '4,' + IntToHex(addr, 4) + ',' + IntToHex(watchsize, 4);
    // NOTE: Not sure whether hardware break is better than software break, depends on gdbserver implementation...
    wkpExec: cmd := cmd + '1,' + IntToHex(addr, 4) + ',00';
  end;

  EnterCriticalSection(fCS);
  try
    result := FSendCmdWaitForReply(cmd, reply) and not(SockErr);
  finally
    LeaveCriticalSection(fCS);
  end;
  if result then
    result := pos('OK', reply) > 0;
end;

function TRspConnection.DeleteBreakWatchPoint(addr: PtrUInt;
  BreakWatchKind: TDBGWatchPointKind; watchsize: integer): boolean;
var
  cmd, reply: string;
begin
  cmd := 'z';
  case BreakWatchKind of
    wpkWrite: cmd := cmd + '2,' + IntToHex(addr, 4) + ',' + IntToHex(watchsize, 4);
    wpkRead:  cmd := cmd + '3,' + IntToHex(addr, 4) + ',' + IntToHex(watchsize, 4);
    wpkReadWrite: cmd := cmd + '4,' + IntToHex(addr, 4) + ',' + IntToHex(watchsize, 4);
    // NOTE: Not sure whether hardware break is better than software break, depends on gdbserver implementation...
    wkpExec: cmd := cmd + '1,' + IntToHex(addr, 4) + ',00';
  end;

  EnterCriticalSection(fCS);
  try
    result := FSendCmdWaitForReply(cmd, reply) and not(SockErr);
  finally
    LeaveCriticalSection(fCS);
  end;
  if result then
    result := pos('OK', reply) > 0;
end;

function TRspConnection.Continue(): boolean;
begin
  DebugLn(DBG_VERBOSE, ['TRspConnection.Continue() called']);
  EnterCriticalSection(fCS);
  try
    result := FSendCommandOK('c') and not(SockErr);
  finally
    LeaveCriticalSection(fCS);
  end;
  if not result then
    DebugLn(DBG_WARNINGS, ['Warning: Continue command failure in TRspConnection.Continue()']);
end;

function TRspConnection.SingleStep(): boolean;
begin
  EnterCriticalSection(fCS);
  try
    result := FSendCommandOK('s') and not(SockErr);
  finally
    LeaveCriticalSection(fCS);
  end;
  if not result then
    DebugLn(DBG_WARNINGS, ['Warning: SingleStep command failure in TRspConnection.SingleStep()']);
end;

function TRspConnection.ReadDebugReg(ind: byte; out AVal: TDbgPtr): boolean;
var
  cmd, reply: string;
  tmp: qword;
begin
  cmd := 'p'+IntToHex(ind, 2);
  EnterCriticalSection(fCS);
  try
    result := FSendCmdWaitForReply(cmd, reply) and not(SockErr);
  finally
    LeaveCriticalSection(fCS);
  end;
  if result then
  begin
    result := convertHexWithLittleEndianSwap(reply, tmp);
    AVal := PtrUInt(tmp);
  end;

  if not result then
    DebugLn(DBG_WARNINGS, ['Warning: "p" command returned unexpected result: ', reply]);
end;

function TRspConnection.WriteDebugReg(ind: byte; AVal: TDbgPtr): boolean;
var
  cmd, reply: string;
begin
  cmd := 'P'+IntToHex(ind, 2);
  EnterCriticalSection(fCS);
  try
    result := FSendCmdWaitForReply(cmd, reply) and (reply = 'OK');
  finally
    LeaveCriticalSection(fCS);
  end;
  if not result then
    DebugLn(DBG_WARNINGS, ['Warning: "P" command returned unexpected result: ', reply]);
end;

function TRspConnection.ReadRegisters(out regs; const sz: integer): boolean;
var
  reply: string;
  b: array of byte;
  i: integer;
begin
  reply := '';
  setlength(b, sz);
  // Normal receive error, or an error response of the form Exx
  EnterCriticalSection(fCS);
  try
    result := FSendCmdWaitForReply('g', reply) and ((length(reply) > 4) and (reply[1] <> 'E'))
      and (length(reply) = 2*sz);
  finally
    LeaveCriticalSection(fCS);
  end;
  Result := Result and not(SockErr);
  if Result then
  begin
    for i := 0 to sz-1 do
      b[i] := StrToInt('$'+reply[2*i+1]+reply[2*i+2]);
    result := true;
  end
  else
  begin
    DebugLn(DBG_WARNINGS, ['Warning: "g" command returned unexpected result: ', reply]);
    FillByte(b[0], sz, 0);
  end;
  Move(b[0], regs, sz);
end;

function TRspConnection.WriteRegisters(constref regs; const sz: integer
  ): boolean;
var
  cmd, reply, s: string;
  i, offset: integer;
  pb: PByte;
begin
  pb := @regs;
  result := false;
  reply := '';
  cmd := format('G', []);
  offset := length(cmd);
  setlength(cmd, offset+sz*2);
  for i := 0 to sz-1 do
  begin
    s := IntToHex(pb^, 2);
    cmd[offset + 2*i + 1] := s[1];
    cmd[offset + 2*i + 2] := s[2];
  end;

  // Normal receive error, or an error number of the form Exx
  EnterCriticalSection(fCS);
  try
    result := FSendCmdWaitForReply(cmd, reply) and (reply = 'OK') and not(SockErr);
  finally
    LeaveCriticalSection(fCS);
  end;
  if not result then
    DebugLn(DBG_WARNINGS, ['Warning: "G" command returned unexpected result: ', reply]);
end;

function TRspConnection.ReadData(const AAddress: TDbgPtr;
  const ASize: cardinal; out AData): boolean;
var
  buf: pbyte;
  cmd, reply: string;
  i: integer;
begin
  result := false;
  getmem(buf, ASize);
  cmd := 'm'+IntToHex(AAddress, 2)+',' + IntToHex(ASize, 2);
  EnterCriticalSection(fCS);
  try
    result := FSendCmdWaitForReply(cmd, reply) and (length(reply) = ASize*2) and not(SockErr);
  finally
    LeaveCriticalSection(fCS);
  end;
  if result then
  begin
    for i := 0 to ASize-1 do
      buf[i] := StrToInt('$'+reply[2*i + 1]+reply[2*i + 2])
  end
  else
  begin
    DebugLn(DBG_WARNINGS, ['Warning: "m" command returned unexpected result: ', reply]);
    FillByte(buf[0], ASize, 0);
  end;

  System.Move(buf^, AData, ASize);
  Freemem(buf);
end;

function TRspConnection.WriteData(const AAdress: TDbgPtr;
  const ASize: Cardinal; const AData): Boolean;
var
  cmd, reply, s: string;
  i, offset: integer;
  pb: PByte;
begin
  result := false;
  cmd := format('M%X,%X:', [AAdress, ASize]);
  offset := length(cmd);
  setlength(cmd, offset + 2*ASize);
  pb := @AData;
  for i := 0 to ASize-1 do
  begin
    s := IntToHex(pb^, 2);
    cmd[offset + 2*i+1] := s[1];
    cmd[offset + 2*i+2] := s[2];
    inc(pb);
  end;

  EnterCriticalSection(fCS);
  try
    result := FSendCmdWaitForReply(cmd, reply) and (reply = 'OK') and not(SockErr);
  finally
    LeaveCriticalSection(fCS);
  end;
  if not result then
    DebugLn(DBG_WARNINGS, ['Warning: "M" command returned unexpected result: ', reply]);
end;

function TRspConnection.SendMonitorCmd(const s: string): boolean;
var
  cmdstr, reply: string;
begin
  cmdstr := 'qRcmd,' + FHexEncodeStr(s);
  result := FSendCmdWaitForReply(cmdstr, reply) and not(SockErr);

  // Check if reply is not hex encoded, else decode reply
  if Result and not((reply = '') or (reply = 'OK') or ((length(reply) = 3) and (reply[1] = 'E'))) then
     reply := FHexDecodeStr(reply);

  DebugLn(DBG_RSP, ['[Monitor '+s+'] reply: ', reply]);
end;

function TRspConnection.Init: integer;
var
  reply: string;
  intRegs: TInitializedRegisters;
  res: boolean;
  source: TDbgFileLoader;
  imgReader: TDbgImageReader;
  pSection: PDbgImageSection;
  dataStart: int64;
  reloadData: boolean = false;
  i: integer;
begin
  result := 0;
  reply := '';
  EnterCriticalSection(fCS);
  try
    if not FSendCmdWaitForReply('vMustReplyEmpty', reply) or (reply <> '') or SockErr then
    begin
      DebugLn(DBG_WARNINGS, ['Warning: vMustReplyEmpty command returned unexpected result: ', reply]);
      exit;
    end;

    // Fancy stuff - load exe & sections, run monitor cmds etc
    if assigned(AAfterConnectMonitorCmds) and (AAfterConnectMonitorCmds.Count > 0) then
     begin
       for i := 0 to AAfterConnectMonitorCmds.Count-1 do
         SendMonitorCmd(AAfterConnectMonitorCmds[i]);
     end;

    // Start with AVR logic
    // If more targets are supported, move this to target specific debugger class
    if AUploadBinary and (FFileName <> '') then
    begin
      // Ensure loader is initialized
      FOwner.InitializeLoaders;
      datastart := -1;
      i := -1;
      repeat
        inc(i);
        pSection := FOwner.LoaderList[0].SectionByID[i];
        if (pSection <> nil) and (pSection^.Size > 0) and (pSection^.IsLoadable) then
        begin
          if Assigned(ASkipSectionsList) and
             (ASkipSectionsList.IndexOf(pSection^.Name) < 0) then
          begin
            // .data section should be programmed straight after .text for AVR
            // Require tracking because sections are sorted alphabetically,
            // so .data is encountered before .text
            if (pSection^.Name = '.data') then
            begin
              // Data can only be loaded after text, since the end address of text+1 is the start of data in flash
              if (dataStart < 0) then
              begin
                reloadData := true;
                system.Continue;
              end
              else
                WriteData(dataStart, pSection^.Size, pSection^.RawData^);
            end
            else
            begin
              WriteData(pSection^.VirtualAddress, pSection^.Size, pSection^.RawData^);
              if pSection^.Name = '.text' then
                dataStart := pSection^.Size;
            end;
          end;
        end;
      until (pSection = nil);

      // reloadData will only be set if it is not in the skipped sections list
      if reloadData and (dataStart >= 0) then
      begin
        pSection := FOwner.LoaderList[0].Section['.data'];
        WriteData(dataStart, pSection^.Size, pSection^.RawData^);
      end;
    end;

    // Hack to finish initializing atbackend agent
    if AAfterUploadBreakZero then
      SetBreakWatchPoint(0, wkpExec);  // Todo: check if different address is required

    if AAfterUploadMonitorReset then
      SendMonitorCmd('reset');

    // Must be last init command, after init the debug loop waits for the response in WaitForSignal
    res := FSendCommand('?');
  finally
    LeaveCriticalSection(fCS);
  end;

  if res then
  begin
    // Already wrapped in critical section
    result := WaitForSignal(reply, intRegs);
  end;
end;

initialization
  DBG_VERBOSE := DebugLogger.FindOrRegisterLogGroup('DBG_VERBOSE' {$IFDEF DBG_VERBOSE} , True {$ENDIF} );
  DBG_WARNINGS := DebugLogger.FindOrRegisterLogGroup('DBG_WARNINGS' {$IFDEF DBG_WARNINGS} , True {$ENDIF} );
  DBG_RSP := DebugLogger.FindOrRegisterLogGroup('DBG_RSP' {$IFDEF DBG_RSP} , True {$ENDIF} );

finalization
  if Assigned(AAfterConnectMonitorCmds) then
    FreeAndNil(AAfterConnectMonitorCmds);
end.

