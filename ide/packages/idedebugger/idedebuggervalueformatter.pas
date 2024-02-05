unit IdeDebuggerValueFormatter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, IdeDebuggerValueFormatterIntf,
  IdeDebuggerWatchValueIntf, Laz2_XMLCfg, DbgIntfDebuggerBase, StrUtils,
  LazDebuggerIntf;

type

  { TIdeDbgValueFormatterSelector }

  TIdeDbgValueFormatterSelector = class
  private
    FValFormatter: ILazDbgIdeValueFormatterIntf;
    FMatchTypeNames: TStringList;
    FEnabled: Boolean;
    FName: String;
    FValFormatterRegEntry: TLazDbgIdeValueFormatterRegistryEntryClass;

    procedure FreeValFormater;
  public
    constructor Create;
    constructor Create(AFormatter: TLazDbgIdeValueFormatterRegistryEntryClass);
    destructor Destroy; override;

    function CreateCopy: TIdeDbgValueFormatterSelector;
    procedure Assign(ASource: TIdeDbgValueFormatterSelector);
    procedure LoadDataFromXMLConfig(const AConfig: TRttiXMLConfig; const APath: string);
    procedure SaveDataToXMLConfig(const AConfig: TRttiXMLConfig; const APath: string);

    function IsMatchingTypeName(ATypeName: String): boolean;
  published
    property ValFormatter: ILazDbgIdeValueFormatterIntf read FValFormatter;
    property ValFormatterRegEntry: TLazDbgIdeValueFormatterRegistryEntryClass read FValFormatterRegEntry;
    property Enabled: Boolean read FEnabled write FEnabled;
    property Name: String read FName write FName;
    property MatchTypeNames: TStringList read FMatchTypeNames;
  end;
  TIdeDbgValueFormatterSelectorClass = class of TIdeDbgValueFormatterSelector;

  { TIdeDbgValueFormatterSelectorList }

  TIdeDbgValueFormatterSelectorList = class(specialize TFPGObjectList<TIdeDbgValueFormatterSelector>)
  private
    FChanged: Boolean;
    FOnChanged: TNotifyEvent;
    procedure SetChanged(AValue: Boolean);
  public
    procedure Assign(ASource: TIdeDbgValueFormatterSelectorList);
    procedure AssignEnabledTo(ADest: TIdeDbgValueFormatterSelectorList; AnAppend: Boolean = False);

    function IndexOf(AName: String): Integer; overload;

    procedure LoadDataFromXMLConfig(const AConfig: TRttiXMLConfig; const APath: string);
    procedure SaveDataToXMLConfig(const AConfig: TRttiXMLConfig; const APath: string);

    property Changed: Boolean read FChanged write SetChanged;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  public
    function FormatValue(AWatchValue: IWatchResultDataIntf;
      ADisplayFormat: TWatchDisplayFormat;
      AWatchResultPrinter: IWatchResultPrinter; out APrintedValue: String
      ): Boolean; experimental;
    function FormatValue(aDBGType: TDBGType;
                         aValue: string;
                         ADisplayFormat: TWatchDisplayFormat;
                         out APrintedValue: String
                        ): boolean; deprecated 'For values from older backends only - to be removed as backends are upgraded';
  end;

  //procedure AddDefaultValueFormatter(
  //  AName: String;
  //  AMatchTypeName: String; // can contain linebreaks
  //  AValFormatter: ILazDbgIdeValueFormatterIntf;
  //  AValFormatterRegEntry: TLazDbgIdeValueFormatterRegistryEntryClass
  //);

var
  ValueFormatterSelectorList: TIdeDbgValueFormatterSelectorList;


implementation

{ TIdeDbgValueFormatterSelector }

procedure TIdeDbgValueFormatterSelector.FreeValFormater;
begin
  if FValFormatter <> nil then
    FValFormatter.Free;
  FValFormatter := nil;
end;

constructor TIdeDbgValueFormatterSelector.Create;
begin
  inherited Create;
  FMatchTypeNames := TStringList.Create;
  TStringList(FMatchTypeNames).CaseSensitive := False;
  TStringList(FMatchTypeNames).Sorted := True;
end;

constructor TIdeDbgValueFormatterSelector.Create(
  AFormatter: TLazDbgIdeValueFormatterRegistryEntryClass);
begin
  Create;

  FValFormatterRegEntry := AFormatter;
  if FValFormatterRegEntry <> nil then
    FValFormatter := FValFormatterRegEntry.CreateValueFormatter;
end;

destructor TIdeDbgValueFormatterSelector.Destroy;
begin
  inherited Destroy;
  FMatchTypeNames.Free;
  FreeValFormater;
end;

function TIdeDbgValueFormatterSelector.CreateCopy: TIdeDbgValueFormatterSelector;
begin
  Result := TIdeDbgValueFormatterSelectorClass(ClassType).Create(FValFormatterRegEntry);
  Result.Assign(Self);
end;

procedure TIdeDbgValueFormatterSelector.Assign(ASource: TIdeDbgValueFormatterSelector);
begin
  FreeValFormater;

  FValFormatter := ASource.FValFormatter.CreateCopy;
  FMatchTypeNames.Assign(ASource.FMatchTypeNames);
  FName     := ASource.FName;
  FEnabled  := ASource.FEnabled;
end;

procedure TIdeDbgValueFormatterSelector.LoadDataFromXMLConfig(
  const AConfig: TRttiXMLConfig; const APath: string);
var
  s: String;
begin
  FreeValFormater;
  AConfig.ReadObject(APath + 'Filter/', Self);
  MatchTypeNames.CommaText := AConfig.GetValue(APath + 'Filter/MatchTypeNames', '');

  s := AConfig.GetValue(APath + 'FormatterClass', '');
  FValFormatterRegEntry := ValueFormatterRegistry.FindByFormatterClassName(s);
  if FValFormatterRegEntry = nil then
    exit;

  FValFormatter := FValFormatterRegEntry.CreateValueFormatter;
  AConfig.ReadObject(APath + 'Formatter/', FValFormatter.GetObject);
end;

procedure TIdeDbgValueFormatterSelector.SaveDataToXMLConfig(
  const AConfig: TRttiXMLConfig; const APath: string);
begin
  AConfig.WriteObject(APath + 'Filter/', Self);
  AConfig.SetDeleteValue(APath + 'Filter/MatchTypeNames', MatchTypeNames.CommaText, '');

  AConfig.SetValue(APath + 'FormatterClass', FValFormatterRegEntry.GetClassName);
  AConfig.WriteObject(APath + 'Formatter/', FValFormatter.GetObject);
end;

function TIdeDbgValueFormatterSelector.IsMatchingTypeName(ATypeName: String
  ): boolean;
  function MatchPattern(const APattern: String): Boolean;
  var
    NamePos, PatternPos, p: Integer;
  begin
    Result := False;
    if APattern = '' then
      exit;

    NamePos := 1;
    PatternPos := 1;

    while PatternPos <= Length(APattern) do begin
      if APattern[PatternPos] = '*' then begin
        inc(PatternPos);
      end
      else begin
        p := PatternPos;
        PatternPos := PosEx('*', APattern, p);
        if PatternPos < 1 then
          PatternPos := Length(APattern)+1;
        if PatternPos-p > Length(ATypeName)+1 - NamePos then
          break;

        NamePos := PosEx(Copy(APattern, p, PatternPos-p), ATypeName, NamePos);
        if (NamePos < 1) or
           ( (p = 1) and (NamePos <> 1) ) // APattern does not start with *
        then
          break;

        inc(NamePos, PatternPos-p);
      end;
    end;

    Result := (PatternPos = Length(APattern)+1) and
              ( (NamePos = Length(ATypeName)+1) or
                ( (APattern[Length(APattern)] = '*') and
                  (NamePos <= Length(ATypeName)+1)
                )
              );
  end;

var
  i: Integer;
begin
  ATypeName := UpperCase(ATypeName);
  Result := True;
  for i := 0 to FMatchTypeNames.Count - 1 do
    if MatchPattern(UpperCase(FMatchTypeNames[i])) then
      exit;
  Result := False;
end;

{ TIdeDbgValueFormatterSelectorList }

procedure TIdeDbgValueFormatterSelectorList.SetChanged(AValue: Boolean);
begin
  if FChanged = AValue then
    exit;
  FChanged := AValue;

  if FOnChanged <> nil then
    FOnChanged(Self);
end;

procedure TIdeDbgValueFormatterSelectorList.Assign(
  ASource: TIdeDbgValueFormatterSelectorList);
var
  i: Integer;
begin
  Clear;
  inherited Count := ASource.Count;
  for i := 0 to Count - 1 do
    Items[i] := ASource[i].CreateCopy;
end;

procedure TIdeDbgValueFormatterSelectorList.AssignEnabledTo(
  ADest: TIdeDbgValueFormatterSelectorList; AnAppend: Boolean);
var
  i: Integer;
begin
  if not AnAppend then
    ADest.Clear;

  for i := 0 to Count - 1 do
    if Items[i].Enabled then
      ADest.Add(Items[i].CreateCopy);
end;

function TIdeDbgValueFormatterSelectorList.IndexOf(AName: String): Integer;
begin
  Result := Count - 1;
  while (Result >= 0) and (Items[Result].Name <> AName) do
    dec(Result);
end;

procedure TIdeDbgValueFormatterSelectorList.LoadDataFromXMLConfig(
  const AConfig: TRttiXMLConfig; const APath: string);
var
  i, c: Integer;
  obj: TIdeDbgValueFormatterSelector;
begin
  clear;
  c := AConfig.GetChildCount(APath);
  for i := 0 to c - 1 do begin
    obj := TIdeDbgValueFormatterSelector.Create(nil);
    obj.LoadDataFromXMLConfig(AConfig, APath + 'Entry[' + IntToStr(i+1) + ']/');
    if obj.ValFormatter <> nil then
      Add(obj)
    else
      obj.Free;
  end
end;

procedure TIdeDbgValueFormatterSelectorList.SaveDataToXMLConfig(
  const AConfig: TRttiXMLConfig; const APath: string);
var
  i: Integer;
begin
  AConfig.DeletePath(APath);
  for i := 0 to Count - 1 do
    Items[i].SaveDataToXMLConfig(AConfig, APath + 'Entry[' + IntToStr(i+1) + ']/');
end;

function TIdeDbgValueFormatterSelectorList.FormatValue(
  AWatchValue: IWatchResultDataIntf; ADisplayFormat: TWatchDisplayFormat;
  AWatchResultPrinter: IWatchResultPrinter; out APrintedValue: String): Boolean;
var
  i: Integer;
  f: TIdeDbgValueFormatterSelector;
begin
  for i := 0 to Count - 1 do begin
    f := Items[i];
    if not (vffFormatValue in f.ValFormatter.SupportedFeatures) then
      continue;
    if not f.IsMatchingTypeName(AWatchValue.TypeName) then
      continue;
    Result := f.ValFormatter.FormatValue(AWatchValue, ADisplayFormat, AWatchResultPrinter, APrintedValue);
    if Result then
      exit;
  end;
  Result := False;
end;

function TIdeDbgValueFormatterSelectorList.FormatValue(aDBGType: TDBGType;
  aValue: string; ADisplayFormat: TWatchDisplayFormat; out APrintedValue: String
  ): boolean;
var
  i: Integer;
  f: TIdeDbgValueFormatterSelector;
begin
  Result := aDBGType <> nil;
  if not Result then
    exit;
  for i := 0 to Count - 1 do begin
    f := Items[i];
    if not (vffFormatOldValue in f.ValFormatter.SupportedFeatures) then
      continue;
    if not f.IsMatchingTypeName(aDBGType.TypeName) then
      continue;
    Result := f.ValFormatter.FormatValue(aDBGType, aValue, ADisplayFormat, APrintedValue);
    if Result then
      exit;
  end;
  Result := False;
end;

initialization
  ValueFormatterSelectorList := TIdeDbgValueFormatterSelectorList.Create;

finalization
  FreeAndNil(ValueFormatterSelectorList);
end.

