unit IdeDebuggerCommonValueFormatter;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math,
  // DebuggerIntf
  DbgIntfDebuggerBase, DbgIntfBaseTypes,
  // LazDebuggerIntf
  LazDebuggerIntf,
  // IdeIntf
  IdeDebuggerValueFormatterIntf, IdeDebuggerWatchValueIntf;

type

  { TIdeDbgValueFormatterDateTime }

  TIdeDbgValueFormatterDateTime = class(specialize TLazDbgIdeValueFormatterGeneric<TObject>)
  public
    class function GetRegisteredDisplayName: String;
    function FormatValue(AWatchValue: IWatchResultDataIntf;
      ADisplayFormat: TWatchDisplayFormat;
      AWatchResultPrinter: IWatchResultPrinter; out APrintedValue: String
      ): Boolean; override; experimental;
    function FormatValue(aDBGType: TDBGType;
                         aValue: string;
                         ADisplayFormat: TWatchDisplayFormat;
                         out APrintedValue: String
                        ): boolean; override; deprecated 'For values from older backends only - to be removed as backends are upgraded';

    function SupportedFeatures: LazDbgIdeValFormatterFeatures; override;
  end;

implementation

class function TIdeDbgValueFormatterDateTime.GetRegisteredDisplayName: String;
begin
  result:='DateTime';
end;

function TIdeDbgValueFormatterDateTime.FormatValue(
  AWatchValue: IWatchResultDataIntf; ADisplayFormat: TWatchDisplayFormat;
  AWatchResultPrinter: IWatchResultPrinter; out APrintedValue: String): Boolean;
var
  FS: TFormatSettings;
  MyDate: Extended;
begin
  Result := (AWatchValue.ValueKind = rdkFloatVal) and
            (ADisplayFormat in [wdfDefault, wdfStructure, wdfString]);
  if not Result then
    exit;

  //t := UpperCase(AWatchValue.TypeName);
  //Result := (t = 'TDATETIME') or (t = 'TDATE') or (t = 'TTIME');
  //if not Result then
  //  exit;

  FillChar(FS{%H-}, SizeOf(TFormatSettings), 0);
  FS.DecimalSeparator := '.';
  MyDate := AWatchValue.AsFloat;
  // it is important to know datetime for all TDate/TTime/TDateTime
  if SameValue(Frac(MyDate), 0) then
    APrintedValue := DateToStr(MyDate)
  else
  if SameValue(Int(MyDate), 0) then
    APrintedValue := TimeToStr(MyDate)
  else
    APrintedValue := DateTimeToStr(MyDate);

  if ADisplayFormat = wdfStructure then
    APrintedValue := AWatchResultPrinter.PrintWatchValue(AWatchValue, wdfDefault) + ' = ' + APrintedValue;

  Result := True;
end;

function TIdeDbgValueFormatterDateTime.FormatValue(aDBGType: TDBGType;
  aValue: string; ADisplayFormat: TWatchDisplayFormat; out APrintedValue: String
  ): boolean;
var
  FS: TFormatSettings;
  MyDate: Extended;
begin
  Result := (aDBGType <> nil) and
            (aDBGType.Kind in [skSimple, skFloat]) and
            (ADisplayFormat in [wdfDefault, wdfStructure, wdfString]);
  if not Result then
    exit;

  //t := UpperCase(aDBGType.TypeName);
  //Result := (t = 'TDATETIME') or (t = 'TDATE') or (t = 'TTIME');
  //if not Result then
  //  exit;

  FillChar(FS{%H-}, SizeOf(TFormatSettings), 0);
  FS.DecimalSeparator := '.';
  if TryStrToFloat(aValue, MyDate, FS) then
  begin
    // it is important to know datetime for all TDate/TTime/TDateTime
    if SameValue(Frac(MyDate), 0) then
      APrintedValue := DateToStr(MyDate)
    else
    if SameValue(Int(MyDate), 0) then
      APrintedValue := TimeToStr(MyDate)
    else
      APrintedValue := DateTimeToStr(MyDate);
    Result := True;

    if ADisplayFormat = wdfStructure then
      APrintedValue := aValue + ' = ' + APrintedValue;
  end;
end;

function TIdeDbgValueFormatterDateTime.SupportedFeatures: LazDbgIdeValFormatterFeatures;
begin
  Result := [vffFormatValue, vffFormatOldValue];
end;

initialization
  ValueFormatterRegistry.Add(specialize TLazDbgIdeValueFormatterRegistryEntryGeneric<TIdeDbgValueFormatterDateTime>);
end.

