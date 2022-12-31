unit IdeDebuggerOpts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IDEOptionsIntf, Laz2_XMLCfg, LazFileUtils, LazUTF8,
  LazLoggerBase, Laz2_DOM, laz2_XMLRead, laz2_XMLWrite, DbgIntfDebuggerBase,
  IdeDebuggerStringConstants, IdeDebuggerBackendValueConv, EnvironmentOpts;

type

  { TDebuggerPropertiesConfig }

  TDebuggerPropertiesConfig = class(TPersistent)
  private
    FFLags: set of (dpcLoaded);
    FActive: Boolean;
    FConfigClass: String;
    FConfigClassInOldXml: String; // The ConfigClass in the xml file. In case the class in memory is changed
    FConfigName: String;
    FDebuggerClass: TDebuggerClass;
    FDebuggerFilename: string;
    FUID: String;
    FDebuggerProperties: TDebuggerProperties;
    FDebuggerPropertiesAsXml: String; // In case the DebuggerClass is unknown

    procedure InitUID;
  public
    destructor Destroy; override;
    constructor CreateFromXmlConf(AXMLCfg: TRttiXMLConfig; APath: String; AIndex: Integer; APreventActive: Boolean = False);
    constructor CreateFromOldXmlConf(AXMLCfg: TRttiXMLConfig; APath: String;
      ADebuggerClassName: String; ACreateAsActive: Boolean);
    constructor CreateForDebuggerClass(ADebuggerClass: TDebuggerClass; ACreateAsActive: Boolean);
    constructor CreateForDebuggerClass(ADebuggerClassName: String; ACreateAsActive: Boolean);
    constructor CreateCopy(ASource: TDebuggerPropertiesConfig; ACopyPropValues: Boolean = True; ACopyXmlOrigin: Boolean = False);

    procedure CopyFrom(ASource: TDebuggerPropertiesConfig; ACopyPropValues: Boolean = True);
    procedure AssignTo(Dest: TPersistent); override;
    function DisplayName: String;
    function NeedsExePath: Boolean;
    procedure ChangeDebuggerClass(ADebuggerClass: TDebuggerClass; ACopyPropValues: Boolean = True);
    function IsLoaded: Boolean;  // The class for the debugger was found
    function DebugText: String;

    procedure DeleteFromOldXml(AXMLCfg: TRttiXMLConfig; APath: String);
    procedure SaveToXml(AXMLCfg: TRttiXMLConfig; APath: String; AIndex: Integer);
    //procedure SaveToOldXml(AXMLCfg: TRttiXMLConfig; APath: String);

    property DebuggerClass: TDebuggerClass read FDebuggerClass;
    property DebuggerProperties: TDebuggerProperties read FDebuggerProperties;
  published
    property ConfigName: String read FConfigName write FConfigName;
    property ConfigClass: String read FConfigClass write FConfigClass;
    property ConfigClassInOldXml: String read FConfigClassInOldXml;
    property DebuggerFilename: string read FDebuggerFilename write FDebuggerFilename;
    property Active: Boolean read FActive write FActive;
    property UID: String read FUID write FUID;
  end;

  { TDebuggerPropertiesConfigList }

  TDebuggerPropertiesConfigList = class(TStringListUTF8Fast)
  private const
    XML_PATH_DEBUGGER_CONF     = 'Config[%d]/';
    XML_PATH_DEBUGGER_CONF_OLD = 'Class%s/';
  private
    FHasActiveDebuggerEntry: Boolean;
    FKnownDebuggerClassCount: Integer;
    FCurrentDebuggerPropertiesConfig: TDebuggerPropertiesConfig; // Active entry, if loaded (if class was found, and is supported)

    function GetOpt(Index: Integer): TDebuggerPropertiesConfig;
    procedure SetCurrentDebuggerPropertiesOpt(AValue: TDebuggerPropertiesConfig);
  public
    constructor Create;
    procedure LoadFromXml(AXMLCfg: TRttiXMLConfig; APath: String);
    procedure LoadFromOldXml(AXMLCfg: TRttiXMLConfig; APath: String; AnOldFileNamePath: String = '');
    procedure SaveToXml(AXMLCfg: TRttiXMLConfig; APath: String; AForceSaveEmpty: Boolean = False);

    function EntryByName(AConfName, AConfClass: String): TDebuggerPropertiesConfig;
    function EntryByUid(AnUid: String): TDebuggerPropertiesConfig;
    property Opt[Index: Integer]: TDebuggerPropertiesConfig read GetOpt;
    property HasActiveDebuggerEntry: Boolean read FHasActiveDebuggerEntry write FHasActiveDebuggerEntry; // for the initial setup dialog / entry may be of unknown class
    property CurrentDebuggerPropertiesConfig: TDebuggerPropertiesConfig read FCurrentDebuggerPropertiesConfig write SetCurrentDebuggerPropertiesOpt;
  end;

  { TDebuggerOptions }

  TDebuggerOptions = class(TAbstractIDEEnvironmentOptions)
  private
    FFilename: string;
    FBackendConverterConfig: TIdeDbgValueConvertSelectorList;
    FHasActiveDebuggerEntry: Boolean;
    FPrimaryConfigPath: String;
    FXMLCfg: TRttiXMLConfig;

    FDebuggerConfigList: TDebuggerPropertiesConfigList; // named entries

    function GetCurrentDebuggerPropertiesConfig: TDebuggerPropertiesConfig;
    procedure SetCurrentDebuggerPropertiesOpt(AValue: TDebuggerPropertiesConfig);
    procedure LoadDebuggerProperties;
  protected
    procedure InitXMLCfg(CleanConfig: boolean);
    property XMLCfg: TRttiXMLConfig read FXMLCfg;
  public
    class function GetGroupCaption:string; override;
    class function GetInstance: TAbstractIDEOptions; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load;
    procedure Save;
    function GetDefaultConfigFilename: string;
    procedure CreateConfig;

    property Filename: string read FFilename;
    property PrimaryConfigPath: String read FPrimaryConfigPath write FPrimaryConfigPath;

    property BackendConverterConfig: TIdeDbgValueConvertSelectorList read FBackendConverterConfig write FBackendConverterConfig;

    function DebuggerFilename: string;
    function GetParsedDebuggerFilename(AProjectDbgFileName: String = ''): string;

    procedure SaveDebuggerPropertiesList;
    function  DebuggerPropertiesConfigList: TDebuggerPropertiesConfigList;
    function  CurrentDebuggerClass: TDebuggerClass;
    function  CurrentDebuggerPropertiesConfigEx(AnUID: String = ''): TDebuggerPropertiesConfig;
    property  CurrentDebuggerPropertiesConfig: TDebuggerPropertiesConfig read GetCurrentDebuggerPropertiesConfig write SetCurrentDebuggerPropertiesOpt;
    // HasActiveDebuggerEntry => marked as active in the xml, even if not IsLoaded
    property  HasActiveDebuggerEntry: Boolean read FHasActiveDebuggerEntry write FHasActiveDebuggerEntry; // for the initial setup dialog / entry may be of unknown class
    //property  DebuggerConfig: TDebuggerConfigStore read FDebuggerConfig;
  end;

function GetDebuggerOptions: TDebuggerOptions;
property DebuggerOptions: TDebuggerOptions read GetDebuggerOptions;


implementation

const
  DebuggerOptsConfFileName = 'debuggeroptions.xml';
var
  TheDebuggerOptions: TDebuggerOptions = nil;

function GetDebuggerOptions: TDebuggerOptions;
begin
  if TheDebuggerOptions = nil then
    TheDebuggerOptions := TDebuggerOptions.Create;
  Result := TheDebuggerOptions;
end;

{ TDebuggerPropertiesConfig }

procedure TDebuggerPropertiesConfig.InitUID;
var
  g: TGUID;
begin
  if FUID <> '' then
    exit;

  if CreateGUID(g) = 0 then
    FUID := GUIDToString(g)
  else
    FUID := IntToHex(Random($100000000), 8)+'-'+IntToHex(Random($100000000), 8)+'-'+IntToHex(Random($100000000), 8);
end;

destructor TDebuggerPropertiesConfig.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FDebuggerProperties);
end;

constructor TDebuggerPropertiesConfig.CreateFromXmlConf(
  AXMLCfg: TRttiXMLConfig; APath: String; AIndex: Integer;
  APreventActive: Boolean);
var
  n: TDOMNode;
  st: TStringStream;
begin
  Create;
  FFLags := [];

  APath := Format(APath, [AIndex]);
  AXMLCfg.ReadObject(APath, Self);
  if APreventActive then
    FActive := False;

  FDebuggerClass := TBaseDebugManagerIntf.DebuggersByClassName[ConfigClass];
  if (FDebuggerClass <> nil) and
     ( Active or not (dfNotSuitableForOsArch in FDebuggerClass.SupportedFeatures) ) // Active entries will always be loaded for compatibility
  then begin
    FDebuggerProperties := FDebuggerClass.CreateProperties;
    if FDebuggerProperties <> nil then
      AXMLCfg.ReadObject(APath + 'Properties/', FDebuggerProperties);
    FFLags := [dpcLoaded];
  end
  else begin
    n := AXMLCfg.FindNode(APath + 'Properties', False);
    FDebuggerPropertiesAsXml := '';
    if n <> nil then begin
      st := TStringStream.Create('');
      WriteXML(n, st);
      FDebuggerPropertiesAsXml := st.DataString;
      st.Free;
    end;
  end;

  InitUID;
end;

constructor TDebuggerPropertiesConfig.CreateFromOldXmlConf(
  AXMLCfg: TRttiXMLConfig; APath: String; ADebuggerClassName: String;
  ACreateAsActive: Boolean);
var
  p: String;
  n: TDOMNode;
  st: TStringStream;
begin
  Create;
  FFLags := [];

  APath := Format(APath, [ADebuggerClassName]);
  p := APath + 'Config/';
  // Read first, so any (invalid) Class/Name will be cleared after reading
  AXMLCfg.ReadObject(p, Self);  // read FDebuggerFilename;

  FConfigClass := ADebuggerClassName;
  FConfigClassInOldXml := FConfigClass;
//  FConfigName := '';
  FActive := ACreateAsActive;

  FDebuggerClass := TBaseDebugManagerIntf.DebuggersByClassName[ConfigClass];

  p := APath + 'Properties/';
  if (FDebuggerClass <> nil) then begin
    FDebuggerProperties := FDebuggerClass.CreateProperties;
    if FDebuggerProperties <> nil then
      AXMLCfg.ReadObject(p, FDebuggerProperties);
    if Active or not (dfNotSuitableForOsArch in FDebuggerClass.SupportedFeatures) then
      FFLags := [dpcLoaded];
  end
  else begin
    if p[Length(p)] = '/' then
      delete(p, Length(p), 1);
    n := AXMLCfg.FindNode(p, False);
    FDebuggerPropertiesAsXml := '';
    if n <> nil then begin
      st := TStringStream.Create('');
      WriteXML(n, st);
      FDebuggerPropertiesAsXml := st.DataString;
      st.Free;
    end;
  end;

  InitUID;
end;

constructor TDebuggerPropertiesConfig.CreateForDebuggerClass(
  ADebuggerClass: TDebuggerClass; ACreateAsActive: Boolean);
begin
  Create;

  FDebuggerClass := ADebuggerClass;
  FConfigClass := ADebuggerClass.ClassName;
  FConfigName := '';
  FActive := ACreateAsActive;
  FDebuggerProperties := ADebuggerClass.CreateProperties;
  if FActive or not (dfNotSuitableForOsArch in FDebuggerClass.SupportedFeatures) then
    FFLags := [dpcLoaded]; // i.e. treat as loaded, save when saving all

  InitUID;
end;

constructor TDebuggerPropertiesConfig.CreateForDebuggerClass(
  ADebuggerClassName: String; ACreateAsActive: Boolean);
begin
  Create;

  FConfigClass := ADebuggerClassName;
  FConfigName := '';
  FActive := ACreateAsActive;
  FDebuggerClass := TBaseDebugManagerIntf.DebuggersByClassName[ConfigClass];
  if FDebuggerClass <> nil then begin
    FDebuggerProperties := FDebuggerClass.CreateProperties;
    if FActive or not (dfNotSuitableForOsArch in FDebuggerClass.SupportedFeatures) then
      FFLags := [dpcLoaded]; // i.e. treat as loaded, save when saving all
  end;

  InitUID;
end;

constructor TDebuggerPropertiesConfig.CreateCopy(
  ASource: TDebuggerPropertiesConfig; ACopyPropValues: Boolean;
  ACopyXmlOrigin: Boolean);
begin
  Create;
  CopyFrom(ASource, ACopyPropValues);
  if ACopyXmlOrigin then
    FUID          := ASource.FUID;
end;

procedure TDebuggerPropertiesConfig.CopyFrom(
  ASource: TDebuggerPropertiesConfig; ACopyPropValues: Boolean);
begin
  FConfigClass         := ASource.FConfigClass;
  FConfigClassInOldXml := ASource.FConfigClassInOldXml;
  FConfigName       := ASource.FConfigName;
  FDebuggerClass    := ASource.FDebuggerClass;
  FDebuggerFilename := ASource.FDebuggerFilename;
  FFLags            := ASource.FFLags;

  FreeAndNil(FDebuggerProperties);
  if ASource.DebuggerClass <> nil then
    FDebuggerProperties := ASource.DebuggerClass.CreateProperties;
  if ACopyPropValues and (ASource.FDebuggerProperties <> nil) then
    FDebuggerProperties.Assign(ASource.FDebuggerProperties);

  FUID := '';
  InitUID;
end;

procedure TDebuggerPropertiesConfig.AssignTo(Dest: TPersistent);
begin
  TDebuggerPropertiesConfig(Dest).CopyFrom(Self);
end;

function TDebuggerPropertiesConfig.DisplayName: String;
begin
  if FDebuggerClass <> nil then
    Result := FDebuggerClass.Caption
  else
    Result := FConfigClass;
  if FConfigName <> '' then
    Result := FConfigName + ' [' + Result + ']'
  else
    Result := '[' + Result + ']';
end;

function TDebuggerPropertiesConfig.NeedsExePath: Boolean;
begin
  Result := (FDebuggerClass <> nil) and FDebuggerClass.NeedsExePath;
end;

procedure TDebuggerPropertiesConfig.ChangeDebuggerClass(
  ADebuggerClass: TDebuggerClass; ACopyPropValues: Boolean);
var
  p: TDebuggerProperties;
begin
  assert(IsLoaded, 'TDebuggerPropertiesConfig.ChangeDebuggerClass: IsLoaded');
  FDebuggerClass := ADebuggerClass;
  FConfigClass := ADebuggerClass.ClassName;
  p := FDebuggerProperties;
  FDebuggerProperties := ADebuggerClass.CreateProperties;
  if ACopyPropValues and (p <> nil) then
    FDebuggerProperties.Assign(p);
  p.Free;
end;

function TDebuggerPropertiesConfig.IsLoaded: Boolean;
begin
  Result := dpcLoaded in FFLags; // (FDebuggerClass <> nil) and (FDebuggerProperties <> nil);
end;

function TDebuggerPropertiesConfig.DebugText: String;
begin
  if Self = nil then
    exit('NIL');
  Result := Format('C-Name: %s, C-Class: %s, Class %s, Prop %s, Path: %s',
    [FConfigName, FConfigClass, DbgSName(FDebuggerClass), dbgs(FDebuggerProperties),
     FDebuggerFilename]);
end;

procedure TDebuggerPropertiesConfig.DeleteFromOldXml(AXMLCfg: TRttiXMLConfig;
  APath: String);
begin
  if FConfigClassInOldXml = '' then begin
    debugln(['Debugger was loaded, but has no ConfigClass in XML', DebugText]);
    FConfigClassInOldXml := FConfigClass;
  end;

  AXMLCfg.DeletePath(Format(APath, [FConfigClassInOldXml, 'Config']));
  AXMLCfg.DeletePath(Format(APath, [FConfigClassInOldXml, 'Properties']));

  if FConfigClassInOldXml <> FConfigClass then begin
    AXMLCfg.DeletePath(Format(APath, [FConfigClass, 'Config']));
    AXMLCfg.DeletePath(Format(APath, [FConfigClass, 'Properties']));
  end;
  FConfigClassInOldXml := FConfigClass;
end;

procedure TDebuggerPropertiesConfig.SaveToXml(AXMLCfg: TRttiXMLConfig;
  APath: String; AIndex: Integer);
var
  PropDef: TDebuggerProperties;
  OptDef: TDebuggerPropertiesConfig;
  n: TDOMNode;
  st: TStringStream;
begin
  APath := Format(APath, [AIndex]);

  OptDef := TDebuggerPropertiesConfig.Create;
  AXMLCfg.WriteObject(APath, Self, OptDef);
  OptDef.Free;

  if IsLoaded then begin
    if FDebuggerProperties <> nil then begin
      PropDef := FDebuggerClass.CreateProperties;
      AXMLCfg.WriteObject(APath + 'Properties/', FDebuggerProperties, PropDef);
      PropDef.Free;
    end;
  end
  else
  if FDebuggerPropertiesAsXml <> '' then begin
    AXMLCfg.DeletePath(APath + 'Properties');
    n := AXMLCfg.FindNode(APath, False);
    assert(n<>nil, 'TDebuggerPropertiesConfig.SaveToXml: n<>nil');
    if n <> nil then begin
      st := TStringStream.Create(FDebuggerPropertiesAsXml);
      st.Position := 0;
      ReadXMLFragment(n, st, []);
      st.Free;
    end;
  end;
end;

//procedure TDebuggerPropertiesConfig.SaveToOldXml(AXMLCfg: TRttiXMLConfig;
//  APath: String);
//var
//  PropDef: TDebuggerProperties;
//  OptDef: TDebuggerPropertiesConfig;
//  n: TDOMNode;
//  st: TStringStream;
//begin
//  FConfigClassInOldXml := FConfigClass;
//
//  OptDef := TDebuggerPropertiesConfig.Create;
//  OptDef.ConfigName := ConfigName;   // Do not write Name
//  // ConfigClass will differ and be written. This ensures that even an unmodified config is written (to preserve its existence)
//  AXMLCfg.WriteObject(Format(APath, [FConfigClass, 'Config']), Self, OptDef);
//  OptDef.Free;
//
//  if FDebuggerProperties <> nil then begin
//    APath := Format(APath, [FConfigClass, 'Properties']);
//    PropDef := FDebuggerClass.CreateProperties;
//    AXMLCfg.WriteObject(APath, FDebuggerProperties, PropDef);
//    PropDef.Free;
//  end
//  else
//  if FDebuggerPropertiesAsXml <> '' then begin
//    APath := Format(APath, [FConfigClass, '']);
//    while (APath <> '') and (APath[Length(APath)] = '/') do
//      delete(APath, Length(APath), 1);
//    AXMLCfg.DeletePath(APath + '/Properties');
//    n := AXMLCfg.FindNode(APath, False);
//    assert(n<>nil, 'TDebuggerPropertiesConfig.SaveToXml: n<>nil');
//    if n <> nil then begin
//      st := TStringStream.Create(FDebuggerPropertiesAsXml);
//      st.Position := 0;
//      ReadXMLFragment(n, st, []);
//      st.Free;
//    end;
//  end;
//end;

{ TDebuggerPropertiesConfigList }

function TDebuggerPropertiesConfigList.GetOpt(Index: Integer): TDebuggerPropertiesConfig;
begin
  Result := TDebuggerPropertiesConfig(Objects[Index]);
end;

procedure TDebuggerPropertiesConfigList.SetCurrentDebuggerPropertiesOpt(
  AValue: TDebuggerPropertiesConfig);
begin
  if FCurrentDebuggerPropertiesConfig = AValue then Exit;

  if (AValue <> nil) and (IndexOfObject(AValue) < 0) then
    AddObject(AValue.ConfigName, AValue);
  FCurrentDebuggerPropertiesConfig := AValue;
end;

constructor TDebuggerPropertiesConfigList.Create;
begin
  inherited Create;
  OwnsObjects := True;
end;

procedure TDebuggerPropertiesConfigList.LoadFromXml(AXMLCfg: TRttiXMLConfig;
  APath: String);
var
  ConfCount, i: Integer;
  Entry: TDebuggerPropertiesConfig;
begin
  // Check if new Debugger-Classes were registered since the last load.
  if (Count > 0) and
     (TBaseDebugManagerIntf.DebuggerCount = FKnownDebuggerClassCount)
  then
    exit;
  FKnownDebuggerClassCount := TBaseDebugManagerIntf.DebuggerCount;
  HasActiveDebuggerEntry := False;


  Clear;
  FCurrentDebuggerPropertiesConfig := nil;

  ConfCount := AXMLCfg.GetListItemCount(APath, 'Config', False);
  for i := 1 to ConfCount do begin
    Entry := TDebuggerPropertiesConfig.CreateFromXmlConf(AXMLCfg, APath + XML_PATH_DEBUGGER_CONF, i, FCurrentDebuggerPropertiesConfig<>nil);
    AddObject(Entry.ConfigName, Entry);
    if Entry.Active then begin
      HasActiveDebuggerEntry := True;
      if Entry.IsLoaded and (FCurrentDebuggerPropertiesConfig = nil) then
        FCurrentDebuggerPropertiesConfig := Entry;
    end;
  end;
end;

procedure TDebuggerPropertiesConfigList.LoadFromOldXml(AXMLCfg: TRttiXMLConfig;
  APath: String; AnOldFileNamePath: String);
var
  i: Integer;
  Entry: TDebuggerPropertiesConfig;
  ActiveClassName, CurFilename: String;
  IsEntryForCurrentClass: Boolean;
  nd, nd2: TDOMNode;
  s: String;
begin
  if (Count > 0) and
     (TBaseDebugManagerIntf.DebuggerCount = FKnownDebuggerClassCount)
  then
    exit;

  LoadFromXml(AXMLCfg, APath + 'Configs/');

  // Read old style, per class
  if (AnOldFileNamePath <> '') then begin
    ActiveClassName := AXMLCfg.GetValue(APath + 'Class', '');
    HasActiveDebuggerEntry := HasActiveDebuggerEntry or (ActiveClassName <> '');
    // There is only one filename for all classes
    CurFilename:=AXMLCfg.GetValue(AnOldFileNamePath, '');


    nd := AXMLCfg.FindNode(APath, False);
    if nd <> nil then begin
      for i := 0 to nd.GetChildCount - 1 do begin
        nd2 := nd.ChildNodes[i];
        s :=  nd2.NodeName;
        if (Length(s) < 6) or (CompareText(copy(s,1,5), 'Class') <> 0)
           //or ( (nd2.FindNode('Properties') = nil) and (nd2.FindNode('Config') = nil) )
        then
          Continue;

        s := copy(s, 6, Length(s));
        IsEntryForCurrentClass := (ActiveClassName <> '') and (CompareText(s, ActiveClassName)=0);

        Entry := TDebuggerPropertiesConfig.CreateFromOldXmlConf(AXMLCfg,
          APath + XML_PATH_DEBUGGER_CONF_OLD, s,
          IsEntryForCurrentClass and (FCurrentDebuggerPropertiesConfig = nil)
        );

        if IsEntryForCurrentClass then begin
          ActiveClassName := '';
          if Entry.IsLoaded and Entry.Active then
            FCurrentDebuggerPropertiesConfig := Entry;
          if (Entry.DebuggerFilename = '') and (Entry.NeedsExePath or (not Entry.IsLoaded)) then
            Entry.DebuggerFilename := CurFilename;
        end;

        AddObject(Entry.ConfigName, Entry);
      end;
    end;

    if ActiveClassName <> '' then begin
      Entry := TDebuggerPropertiesConfig.CreateForDebuggerClass(ActiveClassName, True);
      if (Entry.DebuggerFilename = '') and (Entry.NeedsExePath or (not Entry.IsLoaded)) then
        Entry.DebuggerFilename := CurFilename;

      AddObject(Entry.ConfigName, Entry);
      assert(FCurrentDebuggerPropertiesConfig=nil, 'TDebuggerPropertiesConfigList.LoadFromOldXml: FCurrentDebuggerPropertiesConfig=nil');
      if Entry.IsLoaded then
        FCurrentDebuggerPropertiesConfig := Entry;
    end;
  end;
end;

procedure TDebuggerPropertiesConfigList.SaveToXml(AXMLCfg: TRttiXMLConfig;
  APath: String; AForceSaveEmpty: Boolean);
var
  i, ConfCount, Idx: Integer;
  Entry: TDebuggerPropertiesConfig;
begin
  ConfCount := AXMLCfg.GetListItemCount(APath, 'Config', False) + 1;
  for i := ConfCount downto 1 do
    AXMLCfg.DeletePath(APath + Format(XML_PATH_DEBUGGER_CONF, [i]));

  Idx := 1;
  for i := 0 to Count - 1 do begin
    Entry := Opt[i];

    Entry.Active := Entry = FCurrentDebuggerPropertiesConfig;
    Entry.SaveToXml(AXMLCfg, APath + XML_PATH_DEBUGGER_CONF, Idx);
    inc(Idx);
  end;

  if (Count > 0) or AForceSaveEmpty then
    AXMLCfg.SetValue(APath+'Version', 1);
end;

function TDebuggerPropertiesConfigList.EntryByName(AConfName, AConfClass: String
  ): TDebuggerPropertiesConfig;
var
  i: Integer;
  dpCfg: TDebuggerPropertiesConfig;
begin
  Result := nil;
  i := Count - 1;
  while i >= 0 do begin
    dpCfg := Opt[i];
    if dpCfg.IsLoaded
    and (dpCfg.ConfigName = AConfName)
    and (dpCfg.ConfigClass = AConfClass) then
      Break;
    dec(i);
  end;
  if i >= 0 then
    Result := dpCfg;
end;

function TDebuggerPropertiesConfigList.EntryByUid(AnUid: String
  ): TDebuggerPropertiesConfig;
var
  i: Integer;
begin
  Result := nil;
  i := Count - 1;
  while (i >= 0) and (Opt[i].UID <> AnUid) do
    dec(i);
  if i >= 0 then
    Result := Opt[i];
end;

{ TDebuggerOptions }

procedure TDebuggerOptions.InitXMLCfg(CleanConfig: boolean);
begin
  if (FXMLCfg=nil) then begin
    FreeAndNil(FXMLCfg);
    if CleanConfig then
      FXMLCfg:=TRttiXMLConfig.CreateClean(Filename)
    else
      FXMLCfg:=TRttiXMLConfig.Create(Filename);
  end;
end;

class function TDebuggerOptions.GetGroupCaption: string;
begin
  Result := dlgIdeDbgDebugger;
end;

class function TDebuggerOptions.GetInstance: TAbstractIDEOptions;
begin
  Result := DebuggerOptions;
end;

constructor TDebuggerOptions.Create;
begin
  inherited Create;
  FDebuggerConfigList := TDebuggerPropertiesConfigList.Create;
  BackendConverterConfig := TIdeDbgValueConvertSelectorList.Create;
end;

destructor TDebuggerOptions.Destroy;
begin
  inherited Destroy;
  BackendConverterConfig.Free;
  FDebuggerConfigList.Free;

  FXMLCfg.Free;
end;

procedure TDebuggerOptions.Load;
var
  Path: String;
begin
  InitXMLCfg(False);

  Path := 'Debugger/';

  FBackendConverterConfig.LoadDataFromXMLConfig(FXMLCfg, Path + 'FpDebug/ValueConvert/');
end;

procedure TDebuggerOptions.Save;
var
  Path: String;
begin
  InitXMLCfg(False); // Dont delete old content
  Path := 'Debugger/';

  if FBackendConverterConfig.Changed then
    FBackendConverterConfig.SaveDataToXMLConfig(FXMLCfg, Path + 'FpDebug/ValueConvert/');
  FBackendConverterConfig.Changed := False;

  SaveDebuggerPropertiesList;

  FXMLCfg.Flush;
end;

function TDebuggerOptions.GetDefaultConfigFilename: string;
begin
  Result:=TrimFilename(AppendPathDelim(PrimaryConfigPath)+DebuggerOptsConfFileName);

end;

procedure TDebuggerOptions.CreateConfig;
begin
  FFilename:=GetDefaultConfigFilename;
end;

function TDebuggerOptions.DebuggerFilename: string;
var
  DbgCfg: TDebuggerPropertiesConfig;
begin
  Result := '';
  DbgCfg := CurrentDebuggerPropertiesConfig;
  if DbgCfg <> nil then
    Result := DbgCfg.DebuggerFilename;
end;

function TDebuggerOptions.GetParsedDebuggerFilename(AProjectDbgFileName: String
  ): string;
begin
  if AProjectDbgFileName = '' then
    AProjectDbgFileName := DebuggerFilename;

  Result:=EnvironmentOptions.GetParsedDebuggerFilename(AProjectDbgFileName);
end;

function TDebuggerOptions.GetCurrentDebuggerPropertiesConfig: TDebuggerPropertiesConfig;
begin
  LoadDebuggerProperties;
  Result := FDebuggerConfigList.CurrentDebuggerPropertiesConfig;
end;

procedure TDebuggerOptions.SetCurrentDebuggerPropertiesOpt(
  AValue: TDebuggerPropertiesConfig);
begin
  LoadDebuggerProperties;
  FDebuggerConfigList.CurrentDebuggerPropertiesConfig := AValue;
end;

procedure TDebuggerOptions.LoadDebuggerProperties;
begin
  if XMLCfg.HasPath('Debugger/Backends/', False) then begin
    FDebuggerConfigList.LoadFromXml(XMLCfg, 'Debugger/Backends/');
  end
  else begin
    debugln(['TDebuggerOptions.LoadDebuggerProperties importing OLD debugger backend config from environment-opts']);
    FDebuggerConfigList.LoadFromOldXml(EnvironmentOptions.XMLCfg, 'EnvironmentOptions/Debugger/', 'EnvironmentOptions/DebuggerFilename/Value');
  end;

  HasActiveDebuggerEntry := FDebuggerConfigList.HasActiveDebuggerEntry;
end;

procedure TDebuggerOptions.SaveDebuggerPropertiesList;
begin
  FDebuggerConfigList.SaveToXml(XMLCfg, 'Debugger/Backends/', True);
  EnvironmentOptions.XMLCfg.SetValue('EnvironmentOptions/Debugger/Deprecated', 'Backends/Class-Config moved to DebuggerOptions.xml');
end;

function TDebuggerOptions.DebuggerPropertiesConfigList: TDebuggerPropertiesConfigList;
begin
  LoadDebuggerProperties;

  Result := FDebuggerConfigList;
end;

function TDebuggerOptions.CurrentDebuggerClass: TDebuggerClass;
var
  Cfg: TDebuggerPropertiesConfig;
begin
  LoadDebuggerProperties;

  Result := nil;
  Cfg := CurrentDebuggerPropertiesConfig;
  if  Cfg<> nil then
    Result := Cfg.DebuggerClass;
end;

function TDebuggerOptions.CurrentDebuggerPropertiesConfigEx(AnUID: String): TDebuggerPropertiesConfig;
begin
  Result := nil;
  if AnUID <> '' then
    Result := FDebuggerConfigList.EntryByUid(AnUID);

  if Result = nil then
    Result := CurrentDebuggerPropertiesConfig;
end;

finalization
  TheDebuggerOptions.Free;

end.

