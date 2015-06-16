unit DebugInOutputProcessor;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpjson,
  FpDbgUtil,
  DebugThreadCommand,
  DbgIntfDebuggerBase,
  debugthread,
  FpDbgClasses,
  typinfo,
  variants,
  jsonparser;

type

  { TCustomInOutputProcessor }

  TCustomInOutputProcessor = class
  private
    FConnectionIdentifier: integer;
  protected
    FOnLog: TOnLog;
  public
    constructor create(AConnectionIdentifier: integer; AnOnLog: TOnLog); virtual;
    function TextToCommand(const ACommandText: string): TFpDebugThreadCommand; virtual; abstract;
    function EventToText(AnEvent: TFpDebugEvent): string; virtual; abstract;
  end;

  { TJSonInOutputProcessor }

  TJSonInOutputProcessor = class(TCustomInOutputProcessor)
  public
    function TextToCommand(const ACommandText: string): TFpDebugThreadCommand; override;
    function EventToText(AnEvent: TFpDebugEvent): string; override;
    class function InteractiveInitializationMessage(APort: integer): string;
  end;

implementation

{ TCustomInOutputProcessor }

constructor TCustomInOutputProcessor.create(AConnectionIdentifier: integer; AnOnLog: TOnLog);
begin
  FConnectionIdentifier:=AConnectionIdentifier;
  FOnLog:=AnOnLog;
end;

{ TJSonInOutputProcessor }

function TJSonInOutputProcessor.TextToCommand(const ACommandText: string): TFpDebugThreadCommand;
var
  AJSonCommand: TJSONData;
  AJSonProp: TJSONData;
  AJSonUID: TJSONData;
  AnUID: variant;
  ACommandClass: TFpDebugThreadCommandClass;
  s: string;
  i: integer;
  APropCount: integer;
  APropList: PPropList;
  APropName: string;
begin
  result := nil;
  try
    AJSonCommand := GetJSON(ACommandText);
  except
    on E: Exception do
      begin
      TFpDebugThread.Instance.SendNotification(FConnectionIdentifier, ntInvalidCommand, NULL, 'Command "%s" is not a valid JSON string: %s', ACommandText, [ACommandText, e.Message]);
      Exit;
      end;
  end;
  if not assigned(AJSonCommand) then
    begin
    TFpDebugThread.Instance.SendNotification(FConnectionIdentifier, ntInvalidCommand, NULL, 'Command "%s" is not a valid JSON string.', ACommandText, [ACommandText]);
    exit;
    end;

  try
    if AJSonCommand.JSONType<>jtObject then
      begin
      TFpDebugThread.Instance.SendNotification(FConnectionIdentifier, ntInvalidCommand, NULL, 'Command "%s" is not a JSON-object.', ACommandText, [ACommandText]);
      exit;
      end;
    s := TJSONObject(AJSonCommand).Get('command', '');
    if s = '' then
      begin
      TFpDebugThread.Instance.SendNotification(FConnectionIdentifier, ntInvalidCommand, NULL, 'Command "%s" does not contain a "command" entry.', ACommandText,[ACommandText]);
      exit;
      end;
    ACommandClass := TFpDebugThreadCommandList.instance.GetCommandByName(s);
    if not assigned(ACommandClass) then
      begin
      TFpDebugThread.Instance.SendNotification(FConnectionIdentifier, ntInvalidCommand, NULL, 'Command "%s" does not exist.', s, [S]);
      exit;
      end;

    AJSonUID := TJSONObject(AJSonCommand).find('uid');
    if assigned(AJSonUID) then
      AnUID := AJSonUID.Value
    else
      AnUID := null;

    result := ACommandClass.Create(FConnectionIdentifier, AnUID, FOnLog);
    APropCount := GetPropList(result, APropList);
    try
      for i := 0 to APropCount-1 do
        begin
        APropName := APropList^[i]^.Name;
        AJSonProp := TJSONObject(AJSonCommand).Find(LowerCase(APropName));

        if assigned(AJSonProp) then
          begin
          case APropList^[i]^.PropType^.Kind of
            tkAString, tkString, tkUString:
              SetStrProp(result, APropList^[i], AJSonProp.AsString);
            tkInteger:
              SetOrdProp(result, APropList^[i], AJSonProp.AsInteger);
          end;
          end;
        end;
    finally
      Freemem(APropList);
    end;
  finally
    AJSonCommand.Free;
  end;
end;

function TJSonInOutputProcessor.EventToText(AnEvent: TFpDebugEvent): string;
var
  JSonEvent: TJSONObject;
  JSonLocationRec: TJSONObject;
  JSonStackArray: TJSONArray;
  JSonStackEntry: TJSONObject;
  i: Integer;
begin
  JSonEvent := TJSONObject.Create;
  try
    JSonEvent.Add('type',FpEventTypeNames[AnEvent.EventType]);
    if AnEvent.BreakpointAddr<>0 then
      JSonEvent.Add('breakpointLocation', FormatAddress(AnEvent.BreakpointAddr));
    if AnEvent.SendByConnectionIdentifier>0 then
      JSonEvent.Add('connIdentifier', AnEvent.SendByConnectionIdentifier);
    if AnEvent.Validity<>ddsUnknown then
      JSonEvent.Add('validity', DebuggerDataStateStr[AnEvent.Validity]);
    if AnEvent.LocationRec.Address <> 0 then
      begin
      JSonLocationRec := TJSONObject.Create;
      JSonLocationRec.Add('address', FormatAddress(AnEvent.LocationRec.Address));
      JSonLocationRec.Add('funcName', AnEvent.LocationRec.FuncName);
      JSonLocationRec.Add('srcFile', AnEvent.LocationRec.SrcFile);
      JSonLocationRec.Add('srcFullName', AnEvent.LocationRec.SrcFullName);
      JSonLocationRec.Add('srcLine', AnEvent.LocationRec.SrcLine);
      JSonEvent.Add('locationRec',JSonLocationRec);
      end;
    if not varisnull(AnEvent.AnUID) then
      begin
      if VarIsOrdinal(AnEvent.AnUID) then
        JSonEvent.Add('uid', integer(AnEvent.AnUID))
      else
        JSonEvent.Add('uid', VarToStr(AnEvent.AnUID));
      end;
    case AnEvent.EventType of
      etEvent:
        begin
        JSonEvent.Add('eventName',AnEvent.EventName);
        if AnEvent.InstructionPointerRegValue<>0 then
          JSonEvent.Add('instrPointer', FormatAddress(AnEvent.InstructionPointerRegValue));
        end;
      etLog  :
        begin
        case AnEvent.LogLevel of
          dllDebug: JSonEvent.Add('logType','debug');
          dllError: JSonEvent.Add('logType','error');
          dllInfo: JSonEvent.Add('logType','info');
        end;
        end;
      etNotification:
        begin
        JSonEvent.Add('notificationType',FpDebugNotificationTypeNames[AnEvent.NotificationType]);
        if AnEvent.EventName<>'' then
          JSonEvent.Add('command',AnEvent.EventName);
        end;
    end;
    JSonEvent.Add('message',AnEvent.Message);
    if length(AnEvent.StackEntryArray)>0 then
      begin
      JSonStackArray := TJSONArray.Create;
      for i := 0 to high(AnEvent.StackEntryArray) do
        begin
        JSonStackEntry := TJSONObject.Create;
        JSonStackEntry.Add('address', FormatAddress(AnEvent.StackEntryArray[i].AnAddress));
        JSonStackEntry.Add('frameaddress', FormatAddress(AnEvent.StackEntryArray[i].FrameAdress));
        JSonStackEntry.Add('sourcefile', AnEvent.StackEntryArray[i].SourceFile);
        JSonStackEntry.Add('line', AnEvent.StackEntryArray[i].Line);
        JSonStackEntry.Add('functionname', AnEvent.StackEntryArray[i].FunctionName);
        JSonStackArray.Add(JSonStackEntry);
        end;
      JSonEvent.Add('callstack', JSonStackArray);
      end;
    if length(AnEvent.DisassemblerEntryArray)>0 then
      begin
      JSonStackArray := TJSONArray.Create;
      for i := 0 to high(AnEvent.DisassemblerEntryArray) do
        begin
        JSonStackEntry := TJSONObject.Create;
        JSonStackEntry.Add('address', FormatAddress(AnEvent.DisassemblerEntryArray[i].Addr));
        JSonStackEntry.Add('dump', AnEvent.DisassemblerEntryArray[i].Dump);
        JSonStackEntry.Add('statement', AnEvent.DisassemblerEntryArray[i].Statement);
        JSonStackEntry.Add('srcfilename', AnEvent.DisassemblerEntryArray[i].SrcFileName);
        JSonStackEntry.Add('srcfileline', AnEvent.DisassemblerEntryArray[i].SrcFileLine);
        JSonStackEntry.Add('srcstatementindex', AnEvent.DisassemblerEntryArray[i].SrcStatementIndex);
        JSonStackEntry.Add('srcstatementcount', AnEvent.DisassemblerEntryArray[i].SrcStatementCount);
        JSonStackEntry.Add('functionname', AnEvent.DisassemblerEntryArray[i].FuncName);
        JSonStackEntry.Add('offset', AnEvent.DisassemblerEntryArray[i].Offset);
        JSonStackArray.Add(JSonStackEntry);
        end;
      JSonEvent.Add('disassembly', JSonStackArray);
      JSonEvent.Add('startaddress', FormatAddress(AnEvent.Addr1));
      JSonEvent.Add('endaddress', FormatAddress(AnEvent.Addr2));
      JSonEvent.Add('lastentryendaddress', FormatAddress(AnEvent.Addr3));
      end;
    result := JSonEvent.AsJSON;
  finally
    JSonEvent.Free;
  end;
end;

class function TJSonInOutputProcessor.InteractiveInitializationMessage(APort: integer): string;
var
  JSonMessage: TJSONObject;
begin
  JSonMessage := TJSONObject.Create;
  try
    JSonMessage.Add('welcome', 'FPDebug Server');
    JSonMessage.Add('copyright', 'Joost van der Sluis (2015)');
    if APort>-1 then
      JSonMessage.Add('port', APort);
    result := JSonMessage.AsJSON;
  finally
    JSonMessage.Free;
  end;
end;

end.

