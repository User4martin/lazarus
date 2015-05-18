unit DebugInOutputProcessor;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  fpjson,
  FpDbgUtil,
  DebugThreadCommand,
  debugthread,
  FpDbgClasses,
  typinfo,
  varutils,
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
  end;

implementation

var
  GJSonInOutputProcessor: TJSonInOutputProcessor = nil;

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
  s: string;
  JSonEvent: TJSONObject;
  JSonLocationRec: TJSONObject;
begin
  JSonEvent := TJSONObject.Create;
  try
    JSonEvent.Add('type',FpEventTypeNames[AnEvent.EventType]);
    if AnEvent.BreakpointAddr<>0 then
      JSonEvent.Add('breakpointLocation', FormatAddress(AnEvent.BreakpointAddr));
    if AnEvent.SendByConnectionIdentifier>0 then
      JSonEvent.Add('connIdentifier', AnEvent.SendByConnectionIdentifier);
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
        JSonEvent.Add('message',AnEvent.Message);
        case AnEvent.LogLevel of
          dllDebug: JSonEvent.Add('logType','debug');
          dllError: JSonEvent.Add('logType','error');
          dllInfo: JSonEvent.Add('logType','info');
        end;
        end;
      etNotification:
        begin
        JSonEvent.Add('notificationType',FpDebugNotificationTypeNames[AnEvent.NotificationType]);
        JSonEvent.Add('message',AnEvent.Message);
        if AnEvent.EventName<>'' then
          JSonEvent.Add('command',AnEvent.EventName);
        end;
    end;
    result := JSonEvent.AsJSON;
  finally
    JSonEvent.Free;
  end;
end;

finalization
  GJSonInOutputProcessor := nil;
end.

