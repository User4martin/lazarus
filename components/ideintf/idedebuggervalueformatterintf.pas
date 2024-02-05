unit IdeDebuggerValueFormatterIntf experimental;

{$mode objfpc}{$H+}
{$INTERFACES CORBA}

interface

uses fgl, SysUtils, LazDebuggerIntf, IdeDebuggerWatchValueIntf,
  DbgIntfDebuggerBase;

type

  LazDbgIdeValFormatterFeature = (
    vffFormatValue,    // FormatValue() for IWatchResultDataIntf
    vffFormatOldValue  // FormatValue() for older backends TDBGType
  ) experimental;
  LazDbgIdeValFormatterFeatures = set of LazDbgIdeValFormatterFeature;

  ILazDbgIdeValueFormatterIntf = interface
    ['{AE8A0E22-E052-4C77-AD88-8812D27F3180}']

    (* *** Experimental - This interface will still change *** *)

    function FormatValue(AWatchValue: IWatchResultDataIntf;
                         ADisplayFormat: TWatchDisplayFormat;
                         AWatchResultPrinter: IWatchResultPrinter;
                         out APrintedValue: String
                        ): Boolean; experimental;

    function FormatValue(aDBGType: TDBGType;
                         aValue: string;
                         ADisplayFormat: TWatchDisplayFormat;
                         out APrintedValue: String
                        ): boolean; deprecated 'For values from older backends only - to be removed as backends are upgraded';

    function SupportedFeatures: LazDbgIdeValFormatterFeatures;

    // Config
    function  GetObject: TObject;  // for TXmlConfig.WriteObject / must have all config in published fields
    function CreateCopy: ILazDbgIdeValueFormatterIntf;
    procedure Free;
  end;

  (* ILazDbgIdeValueFormatterSettingsFrameIntf
     interface that must be implemented by the TFrame class returned by GetSettingsFrameClass
  *)

  ILazDbgIdeValueFormatterSettingsFrameIntf = interface
    ['{83CDB4A1-6B32-44F0-B225-7F591AE06497}']
    procedure ReadFrom(AFormatter: ILazDbgIdeValueFormatterIntf);
    function  WriteTo(AFormatter: ILazDbgIdeValueFormatterIntf): Boolean;
  end;

  (* TLazDbgIdeValueFormatterRegistryEntry
     Class of a value formatter.
     The user can create any amount of configurable formatters from this.
  *)

  TLazDbgIdeValueFormatterRegistryEntry = class
  public
    class function CreateValueFormatter: ILazDbgIdeValueFormatterIntf; virtual; abstract;
    class function GetSettingsFrameClass: TClass; virtual; // class(TFrame, ILazDbgIdeValueFormatterSettingsFrameIntf)
    class function GetDisplayName: String; virtual; abstract;
    class function GetClassName: String; virtual; abstract; // Used in XmlConfig
  end;
  TLazDbgIdeValueFormatterRegistryEntryClass = class of TLazDbgIdeValueFormatterRegistryEntry;

  (* TLazDbgIdeValueFormatterRegistry
     List of create-able value formatter classes.
  *)

  TLazDbgIdeValueFormatterRegistry = class(specialize TFPGList<TLazDbgIdeValueFormatterRegistryEntryClass>)
  public
    function FindByFormatterClassName(AName: String): TLazDbgIdeValueFormatterRegistryEntryClass;
  end;

  { TLazDbgIdeValueFormatterGeneric }

  generic TLazDbgIdeValueFormatterGeneric<_BASE: TObject> = class(_BASE, ILazDbgIdeValueFormatterIntf)
  protected
    function CreateCopy: ILazDbgIdeValueFormatterIntf;
    function GetObject: TObject; virtual;
    procedure Assign(AnOther: TLazDbgIdeValueFormatterGeneric); virtual;
    procedure DoFree; virtual;
    procedure ILazDbgIdeValueFormatterIntf.Free = DoFree;
  public
    function FormatValue(AWatchValue: IWatchResultDataIntf;
                         ADisplayFormat: TWatchDisplayFormat;
                         AWatchResultPrinter: IWatchResultPrinter;
                         out APrintedValue: String
                        ): Boolean; virtual; experimental;

    function FormatValue(aDBGType: TDBGType;
                         aValue: string;
                         ADisplayFormat: TWatchDisplayFormat;
                         out APrintedValue: String
                        ): boolean; virtual; deprecated 'For values from older backends only - to be removed as backends are upgraded';

    function SupportedFeatures: LazDbgIdeValFormatterFeatures; virtual;
  end;

  { TLazDbgIdeValueFormatterRegistryEntryGeneric }

  generic TLazDbgIdeValueFormatterRegistryEntryGeneric<_Formatter> = class(TLazDbgIdeValueFormatterRegistryEntry)
  public
    class function CreateValueFormatter: ILazDbgIdeValueFormatterIntf; override;
    class function GetClassName: String; override;
    class function GetDisplayName: String; override; // calls GetRegisteredDisplayName on the _Formatter
  end;


function ValueFormatterRegistry: TLazDbgIdeValueFormatterRegistry;

implementation

var
  TheValueFormatterRegistry: TLazDbgIdeValueFormatterRegistry;

function ValueFormatterRegistry: TLazDbgIdeValueFormatterRegistry;
begin
  if TheValueFormatterRegistry = nil then
    TheValueFormatterRegistry := TLazDbgIdeValueFormatterRegistry.Create;
  Result := TheValueFormatterRegistry;
end;

{ TLazDbgIdeValueFormatterRegistryEntry }

class function TLazDbgIdeValueFormatterRegistryEntry.GetSettingsFrameClass: TClass;
begin
  Result := nil;
end;

{ TLazDbgIdeValueFormatterRegistry }

function TLazDbgIdeValueFormatterRegistry.FindByFormatterClassName(AName: String
  ): TLazDbgIdeValueFormatterRegistryEntryClass;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
    if Items[i].GetClassName = AName then
      exit(Items[i]);
end;

{ TLazDbgIdeValueFormatterGeneric }

function TLazDbgIdeValueFormatterGeneric.GetObject: TObject;
begin
  Result := Self;
end;

procedure TLazDbgIdeValueFormatterGeneric.Assign(AnOther: TLazDbgIdeValueFormatterGeneric);
begin
  //
end;

function TLazDbgIdeValueFormatterGeneric.CreateCopy: ILazDbgIdeValueFormatterIntf;
type
  tc = class of TLazDbgIdeValueFormatterGeneric;
var
  r: TLazDbgIdeValueFormatterGeneric;
begin
  r := tc(ClassType).Create;
  r.Assign(Self);
  Result := r;
end;

procedure TLazDbgIdeValueFormatterGeneric.DoFree;
begin
  Destroy;
end;

function TLazDbgIdeValueFormatterGeneric.FormatValue(
  AWatchValue: IWatchResultDataIntf; ADisplayFormat: TWatchDisplayFormat;
  AWatchResultPrinter: IWatchResultPrinter; out APrintedValue: String): Boolean;
begin
  Result := False;
end;

function TLazDbgIdeValueFormatterGeneric.FormatValue(aDBGType: TDBGType;
  aValue: string; ADisplayFormat: TWatchDisplayFormat; out APrintedValue: String
  ): boolean;
begin
  Result := False;
end;

function TLazDbgIdeValueFormatterGeneric.SupportedFeatures: LazDbgIdeValFormatterFeatures;
begin
  Result := [];
end;

{ TLazDbgIdeValueFormatterRegistryEntryGeneric }

class function TLazDbgIdeValueFormatterRegistryEntryGeneric.CreateValueFormatter: ILazDbgIdeValueFormatterIntf;
begin
  Result := _Formatter.Create;
end;

class function TLazDbgIdeValueFormatterRegistryEntryGeneric.GetClassName: String;
begin
  Result := _Formatter.ClassName;
end;

class function TLazDbgIdeValueFormatterRegistryEntryGeneric.GetDisplayName: String;
begin
  Result := _Formatter.GetRegisteredDisplayName;
end;


finalization
  FreeAndNil(TheValueFormatterRegistry);
end.

