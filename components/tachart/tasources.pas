{

 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

 Authors: Alexander Klenin

}

unit TASources;

{$H+}

interface

uses
  Classes, Types, TAChartUtils, TACustomSource;

type
  { TListChartSource }

  TListChartSource = class(TCustomChartSource)
  private
    FData: TFPList;
    FDataPoints: TStrings;
    FSorted: Boolean;

    procedure AddAt(
      APos: Integer; AX, AY: Double; const ALabel: String; AColor: TChartColor);
    procedure ClearCaches;
    function NewItem: PChartDataItem;
    procedure SetDataPoints(AValue: TStrings);
    procedure SetSorted(AValue: Boolean);
    procedure UpdateCachesAfterAdd(AX, AY: Double);
  protected
    function GetCount: Integer; override;
    function GetItem(AIndex: Integer): PChartDataItem; override;
    procedure SetYCount(AValue: Cardinal); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    function Add(
      AX, AY: Double; const ALabel: String = '';
      AColor: TChartColor = clTAColor): Integer;
    procedure Clear;
    procedure CopyFrom(ASource: TCustomChartSource);
    procedure Delete(AIndex: Integer);
    function IsSorted: Boolean; override;

    procedure SetColor(AIndex: Integer; AColor: TChartColor);
    function SetXValue(AIndex: Integer; AValue: Double): Integer;
    procedure SetYList(AIndex: Integer; const AYList: array of Double);
    procedure SetYValue(AIndex: Integer; AValue: Double);

    procedure Sort;
  published
    property DataPoints: TStrings read FDataPoints write SetDataPoints;
    property Sorted: Boolean read FSorted write SetSorted default false;
    property YCount;
  end;

  { TMWCRandomGenerator }

  // Mutliply-with-carry random number generator.
  // Algorithm by George Marsaglia.
  // A generator is incapsulated in a class to allow using many simultaneous
  // random sequences, each determined by its own seed.
  TMWCRandomGenerator = class
  strict private
    FHistory: array [0..4] of LongWord;
    procedure SetSeed(AValue: Integer);
  public
    function Get: LongWord;
    function GetInRange(AMin, AMax: Integer): Integer;
    property Seed: Integer write SetSeed;
  end;

  { TRandomChartSource }

  TRandomChartSource = class(TCustomChartSource)
  strict private
    FPointsNumber: Integer;
    FRandomX: Boolean;
    FRandSeed: Integer;
    FXMax: Double;
    FXMin: Double;
    FYMax: Double;
    FYMin: Double;
  strict private
    FCurIndex: Integer;
    FCurItem: TChartDataItem;
    FRNG: TMWCRandomGenerator;

    procedure SetPointsNumber(AValue: Integer);
    procedure SetRandomX(AValue: Boolean);
    procedure SetRandSeed(AValue: Integer);
    procedure SetXMax(AValue: Double);
    procedure SetXMin(AValue: Double);
    procedure SetYMax(AValue: Double);
    procedure SetYMin(AValue: Double);
  protected
    function GetCount: Integer; override;
    function GetItem(AIndex: Integer): PChartDataItem; override;
    procedure SetYCount(AValue: Cardinal); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    function IsSorted: Boolean; override;
  published
    property PointsNumber: Integer
      read FPointsNumber write SetPointsNumber default 0;
    property RandomX: Boolean read FRandomX write SetRandomX default false;
    property RandSeed: Integer read FRandSeed write SetRandSeed;
    property XMax: Double read FXMax write SetXMax;
    property XMin: Double read FXMin write SetXMin;
    property YCount;
    property YMax: Double read FYMax write SetYMax;
    property YMin: Double read FYMin write SetYMin;
  end;

  TUserDefinedChartSource = class;

  TGetChartDataItemEvent = procedure (
    ASource: TUserDefinedChartSource; AIndex: Integer;
    var AItem: TChartDataItem) of object;

  { TUserDefinedChartSource }

  TUserDefinedChartSource = class(TCustomChartSource)
  strict private
    FItem: TChartDataItem;
    FOnGetChartDataItem: TGetChartDataItemEvent;
    FPointsNumber: Integer;
    FSorted: Boolean;
    procedure SetOnGetChartDataItem(AValue: TGetChartDataItemEvent);
    procedure SetPointsNumber(AValue: Integer);
  protected
    function GetCount: Integer; override;
    function GetItem(AIndex: Integer): PChartDataItem; override;
    procedure SetYCount(AValue: Cardinal); override;
  public
    procedure EndUpdate; override;
    function IsSorted: Boolean; override;
    procedure Reset; inline;
  published
    property OnGetChartDataItem: TGetChartDataItemEvent
      read FOnGetChartDataItem write SetOnGetChartDataItem;
    property PointsNumber: Integer
      read FPointsNumber write SetPointsNumber default 0;
    property Sorted: Boolean read FSorted write FSorted default false;
  end;

  TChartAccumulationMethod = (
    camNone, camSum, camAverage, camDerivative, camSmoothDerivative);
  TChartAccumulationDirection = (cadBackward, cadForward, cadCenter);

  { TCalculatedChartSource }

  TCalculatedChartSource = class(TCustomChartSource)
  strict private
    FAccumulationDirection: TChartAccumulationDirection;
    FAccumulationMethod: TChartAccumulationMethod;
    FAccumulationRange: Cardinal;
    FHistory: TChartSourceBuffer;
    FIndex: Integer;
    FItem: TChartDataItem;
    FListener: TListener;
    FOrigin: TCustomChartSource;
    FOriginYCount: Cardinal;
    FPercentage: Boolean;
    FReorderYList: String;
    FYOrder: array of Integer;

    procedure CalcAccumulation(AIndex: Integer);
    procedure CalcDerivative(AIndex: Integer);
    procedure CalcPercentage;
    procedure Changed(ASender: TObject);
    function EffectiveAccumulationRange: Cardinal;
    procedure ExtractItem(AIndex: Integer);
    function IsDerivative: Boolean; inline;
    procedure RangeAround(AIndex: Integer; out ALeft, ARight: Integer);
    procedure SetAccumulationDirection(AValue: TChartAccumulationDirection);
    procedure SetAccumulationMethod(AValue: TChartAccumulationMethod);
    procedure SetAccumulationRange(AValue: Cardinal);
    procedure SetOrigin(AValue: TCustomChartSource);
    procedure SetPercentage(AValue: Boolean);
    procedure SetReorderYList(const AValue: String);
    procedure UpdateYOrder;
  protected
    function GetCount: Integer; override;
    function GetItem(AIndex: Integer): PChartDataItem; override;
    procedure SetYCount(AValue: Cardinal); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function IsSorted: Boolean; override;
  published
    property AccumulationDirection: TChartAccumulationDirection
      read FAccumulationDirection write SetAccumulationDirection
      default cadBackward;
    property AccumulationMethod: TChartAccumulationMethod
      read FAccumulationMethod write SetAccumulationMethod default camNone;
    property AccumulationRange: Cardinal
      read FAccumulationRange write SetAccumulationRange default 2;

    property Origin: TCustomChartSource read FOrigin write SetOrigin;
    property Percentage: Boolean
      read FPercentage write SetPercentage default false;
    property ReorderYList: String read FReorderYList write SetReorderYList;
  end;

procedure Register;

implementation

uses
  Math, StrUtils, SysUtils, TAMath;

type

  { TListChartSourceStrings }

  TListChartSourceStrings = class(TStrings)
  strict private
    FSource: TListChartSource;
    procedure Parse(AString: String; ADataItem: PChartDataItem);
  protected
    function Get(Index: Integer): String; override;
    function GetCount: Integer; override;
    procedure Put(Index: Integer; const S: String); override;
    procedure SetUpdateState(AUpdating: Boolean); override;
  public
    constructor Create(ASource: TListChartSource);
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const S: String); override;
  end;

procedure Register;
begin
  RegisterComponents(
    CHART_COMPONENT_IDE_PAGE, [
      TListChartSource, TRandomChartSource, TUserDefinedChartSource,
      TCalculatedChartSource
    ]);
end;

{ TListChartSourceStrings }

procedure TListChartSourceStrings.Clear;
begin
  FSource.Clear;
end;

constructor TListChartSourceStrings.Create(ASource: TListChartSource);
begin
  inherited Create;
  FSource := ASource;
end;

procedure TListChartSourceStrings.Delete(Index: Integer);
begin
  FSource.Delete(Index);
end;

function TListChartSourceStrings.Get(Index: Integer): String;
var
  i: Integer;
  fs: TFormatSettings;
begin
  fs := DefaultFormatSettings;
  fs.DecimalSeparator := '.';
  with FSource[Index]^ do begin
    Result := Format('%g', [X], fs);
    if FSource.YCount > 0 then
      Result += Format('|%g', [Y], fs);
    for i := 0 to High(YList) do
      Result += Format('|%g', [YList[i]], fs);
    Result += Format('|%s|%s', [IntToColorHex(Color), Text]);
  end;
end;

function TListChartSourceStrings.GetCount: Integer;
begin
  Result := FSource.Count;
end;

procedure TListChartSourceStrings.Insert(Index: Integer; const S: String);
var
  item: PChartDataItem;
begin
  item := FSource.NewItem;
  FSource.FData.Insert(Index, item);
  Parse(S, item);
  FSource.UpdateCachesAfterAdd(item^.X, item^.Y);
end;

procedure TListChartSourceStrings.Parse(
  AString: String; ADataItem: PChartDataItem);
var
  p: Integer = 0;
  parts: TStringList;

  function NextPart: String;
  begin
    if p < parts.Count then
      Result := parts[p]
    else
      Result := '';
    p += 1;
  end;

var
  i: Integer;
begin
  parts := TStringList.Create;
  try
    parts.Delimiter := '|';
    parts.StrictDelimiter := true;
    parts.DelimitedText := AString;
    if FSource.YCount + 3 < Cardinal(parts.Count) then
      FSource.YCount := parts.Count - 3;
    with ADataItem^ do begin
      X := StrToFloatDefSep(NextPart);
      if FSource.YCount > 0 then begin
        Y := StrToFloatDefSep(NextPart);
        for i := 0 to High(YList) do
          YList[i] := StrToFloatDefSep(NextPart);
      end;
      Color := StrToIntDef(NextPart, clTAColor);
      Text := NextPart;
    end;
  finally
    parts.Free;
  end;
end;

procedure TListChartSourceStrings.Put(Index: Integer; const S: String);
begin
  FSource.BeginUpdate;
  try
  Parse(S, FSource[Index]);
  finally
    FSource.EndUpdate;
  end;
end;

procedure TListChartSourceStrings.SetUpdateState(AUpdating: Boolean);
begin
  if AUpdating then
    FSource.BeginUpdate
  else
    FSource.EndUpdate;
end;

{ TListChartSource }

function TListChartSource.Add(
  AX, AY: Double; const ALabel: String; AColor: TChartColor): Integer;
begin
  Result := FData.Count;
  if Sorted then
    // Keep data points ordered by X coordinate.
    // Note that this leads to O(N^2) time except
    // for the case of adding already ordered points.
    // So, is the user wants to add many (>10000) points to a graph,
    // he should pre-sort them to avoid performance penalty.
    while (Result > 0) and (Item[Result - 1]^.X > AX) do
      Dec(Result);
  AddAt(Result, AX, AY, ALabel, AColor);
end;

procedure TListChartSource.AddAt(
  APos: Integer; AX, AY: Double; const ALabel: String; AColor: TChartColor);
var
  pcd: PChartDataItem;
begin
  pcd := NewItem;
  pcd^.X := AX;
  pcd^.Y := AY;
  pcd^.Color := AColor;
  pcd^.Text := ALabel;
  FData.Insert(APos, pcd);
  UpdateCachesAfterAdd(AX, AY);
end;

procedure TListChartSource.Clear; inline;
var
  i: Integer;
begin
  for i := 0 to FData.Count - 1 do
    Dispose(Item[i]);
  FData.Clear;
  ClearCaches;
  Notify;
end;

procedure TListChartSource.ClearCaches;
begin
  FExtent := EmptyExtent;
  FExtentIsValid := true;
  FValuesTotal := 0;
  FValuesTotalIsValid := true;
end;

procedure TListChartSource.CopyFrom(ASource: TCustomChartSource);
var
  i: Integer;
begin
  BeginUpdate;
  try
    Clear;
    YCount := ASource.YCount;
    for i := 0 to ASource.Count - 1 do
      with ASource[i]^ do begin
        AddAt(FData.Count, X, Y, Text, Color);
        SetYList(FData.Count - 1, YList);
      end;
    if Sorted and not ASource.IsSorted then Sort;
  finally
    EndUpdate;
  end;
end;

constructor TListChartSource.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FData := TFPList.Create;
  FDataPoints := TListChartSourceStrings.Create(Self);
  FYCount := 1;
  ClearCaches;
end;

procedure TListChartSource.Delete(AIndex: Integer);
begin
  with Item[AIndex]^ do begin
    FExtentIsValid := FExtentIsValid and
      (FExtent.a.X < X) and (X < FExtent.b.X) and
      (FExtent.a.Y < Y) and (Y < FExtent.b.Y);
    if FValuesTotalIsValid then
      FValuesTotal -= NumberOr(Y);
  end;
  Dispose(Item[AIndex]);
  FData.Delete(AIndex);
  Notify;
end;

destructor TListChartSource.Destroy;
begin
  Clear;
  FreeAndNil(FDataPoints);
  FreeAndNil(FData);
  inherited;
end;

function TListChartSource.GetCount: Integer;
begin
  Result := FData.Count;
end;

function TListChartSource.GetItem(AIndex: Integer): PChartDataItem;
begin
  Result := PChartDataItem(FData.Items[AIndex]);
end;

function TListChartSource.IsSorted: Boolean;
begin
  Result := Sorted;
end;

function TListChartSource.NewItem: PChartDataItem;
begin
  New(Result);
  SetLength(Result^.YList, Max(YCount - 1, 0));
end;

procedure TListChartSource.SetColor(AIndex: Integer; AColor: TChartColor);
begin
  with Item[AIndex]^ do begin
    if Color = AColor then exit;
    Color := AColor;
  end;
  Notify;
end;

procedure TListChartSource.SetDataPoints(AValue: TStrings);
begin
  if FDataPoints = AValue then exit;
  BeginUpdate;
  try
    FDataPoints.Assign(AValue);
    if Sorted then Sort;
  finally
    EndUpdate;
  end;
end;

procedure TListChartSource.SetSorted(AValue: Boolean);
begin
  if FSorted = AValue then exit;
  FSorted := AValue;
  if Sorted then begin
    Sort;
    Notify;
  end;
end;

function TListChartSource.SetXValue(AIndex: Integer; AValue: Double): Integer;
var
  oldX: Double;

  procedure UpdateExtent;
  var
    it: PChartDataItem;
  begin
    if not FExtentIsValid then exit;

    if not IsNan(AValue) then begin
      if AValue <= FExtent.a.X then
        FExtent.a.X := AValue
      else if AValue >= FExtent.b.X then
        FExtent.b.X := AValue;
    end;

    if IsNan(oldX) then exit;
    if oldX = FExtent.b.X then begin
      FExtent.b.X := NegInfinity;
      for it in Self do
        if not IsNan(it^.X) then
          FExtent.b.X := Max(FExtent.b.X, it^.X);
    end;
    if oldX = FExtent.a.X then begin
      FExtent.a.X := SafeInfinity;
      for it in Self do
        if not IsNan(it^.X) then
          FExtent.a.X := Min(FExtent.a.X, it^.X);
    end;
  end;

begin
  oldX := Item[AIndex]^.X;
  Item[AIndex]^.X := AValue;
  UpdateExtent;
  Result := AIndex;
  if Sorted then begin
    if IsNan(AValue) then
      raise EChartError.Create('X = NaN in a sorted source');
    if AValue > oldX then
      while (Result < Count - 1) and (Item[Result + 1]^.X < AValue) do
        Inc(Result)
    else
      while (Result > 0) and (Item[Result - 1]^.X > AValue) do
        Dec(Result);
    if Result <> AIndex then
      FData.Move(AIndex, Result);
  end;
  Notify;
end;

procedure TListChartSource.SetYCount(AValue: Cardinal);
var
  i: Integer;
begin
  if AValue = FYCount then exit;
  FYCount := AValue;
  for i := 0 to Count - 1 do
    SetLength(Item[i]^.YList, Max(FYCount - 1, 0));
end;

procedure TListChartSource.SetYList(
  AIndex: Integer; const AYList: array of Double);
var
  i: Integer;
begin
  with Item[AIndex]^ do
    for i := 0 to Min(High(AYList), High(YList)) do
      YList[i] := AYList[i];
end;

procedure TListChartSource.SetYValue(AIndex: Integer; AValue: Double);
var
  oldY: Double;

  procedure UpdateExtent;
  var
    it: PChartDataItem;
  begin
    if not FExtentIsValid then exit;

    if not IsNan(AValue) then begin
      if AValue <= FExtent.a.Y then
        FExtent.a.Y := AValue
      else if AValue >= FExtent.b.Y then
        FExtent.b.Y := AValue;
    end;

    if IsNan(oldY) then exit;
    if oldY = FExtent.b.Y then begin
      FExtent.b.Y := NegInfinity;
      for it in Self do
        if not IsNan(it^.Y) then
          FExtent.b.Y := Max(FExtent.b.Y, it^.Y);
    end;
    if oldY = FExtent.a.Y then begin
      FExtent.a.Y := SafeInfinity;
      for it in Self do
        if not IsNan(it^.Y) then
          FExtent.a.Y := Min(FExtent.a.Y, it^.Y);
    end;
  end;

begin
  oldY := Item[AIndex]^.Y;
  Item[AIndex]^.Y := AValue;
  if FValuesTotalIsValid then
    FValuesTotal += NumberOr(AValue) - NumberOr(oldY);
  UpdateExtent;
  Notify;
end;

function CompareDataItemX(AItem1, AItem2: Pointer): Integer;
begin
  Result := Sign(PChartDataItem(AItem1)^.X - PChartDataItem(AItem2)^.X);
end;

procedure TListChartSource.Sort;
begin
  FData.Sort(@CompareDataItemX);
end;

procedure TListChartSource.UpdateCachesAfterAdd(AX, AY: Double);
begin
  if FExtentIsValid then begin
    UpdateMinMax(AX, FExtent.a.X, FExtent.b.X);
    UpdateMinMax(AY, FExtent.a.Y, FExtent.b.Y);
  end;
  if FValuesTotalIsValid then
    FValuesTotal += NumberOr(AY);
  Notify;
end;

{ TMWCRandomGenerator }

function TMWCRandomGenerator.Get: LongWord;
const
  MULT: array [0..4] of UInt64 = (5115, 1776, 1492, 2111111111, 1);
var
  i: Integer;
  s: UInt64;
begin
  s := 0;
  for i := 0 to High(FHistory) do
    s += MULT[i] * FHistory[i];
  FHistory[3] := FHistory[2];
  FHistory[2] := FHistory[1];
  FHistory[1] := FHistory[0];
  FHistory[4] := Hi(s);
  FHistory[0] := Lo(s);
  Result := FHistory[0];
end;

function TMWCRandomGenerator.GetInRange(AMin, AMax: Integer): Integer;
var
  m: UInt64;
begin
  m := AMax - AMin + 1;
  m *= Get;
  // m is now equidistributed on [0, (2^32-1) * range],
  // so its upper double word is equidistributed on [0, range].
  Result := Integer(Hi(m)) + AMin;
end;

procedure TMWCRandomGenerator.SetSeed(AValue: Integer);
var
  i: Integer;
begin
  FHistory[0] := AValue;
  // Use trivial LCG for seeding
  for i := 1 to High(FHistory) do
    FHistory[i] := Lo(Int64(FHistory[i - 1]) * 29943829 - 1);
  // Skip some initial values to increase randomness.
  for i := 1 to 20 do
    Get;
end;

{ TRandomChartSource }

constructor TRandomChartSource.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCurItem.Color := clTAColor;
  FRNG := TMWCRandomGenerator.Create;
  FYCount := 1;
  RandSeed := Trunc(Frac(Now) * MaxInt);
end;

destructor TRandomChartSource.Destroy;
begin
  FreeAndNil(FRNG);
  inherited;
end;

function TRandomChartSource.GetCount: Integer;
begin
  Result := FPointsNumber;
end;

function TRandomChartSource.GetItem(AIndex: Integer): PChartDataItem;

  function GetRandomY: Double;
  begin
    if YMax <= YMin then
      Result := YMin
    else
      Result := FRNG.Get / High(LongWord) * (YMax - YMin) + YMin;
  end;

var
  i: Integer;
begin
  if FCurIndex > AIndex then begin
    FRNG.Seed := FRandSeed;
    FCurIndex := -1;
  end;
  while FCurIndex < AIndex do begin
    Inc(FCurIndex);
    if XMax <= XMin then
      FCurItem.X := XMin
    else begin
      if FRandomX then
        FCurItem.X := FRNG.Get / High(LongWord)
      else
        FCurItem.X := FCurIndex / (Count - 1);
      FCurItem.X := FCurItem.X * (XMax - XMin) + XMin;
    end;
    if YCount > 0 then begin
      FCurItem.Y := GetRandomY;
      SetLength(FCurItem.YList, Max(YCount - 1, 0));
      for i := 0 to YCount - 2 do
        FCurItem.YList[i] := GetRandomY;
    end;
  end;
  Result := @FCurItem;
end;

function TRandomChartSource.IsSorted: Boolean;
begin
  Result := not RandomX;
end;

procedure TRandomChartSource.SetPointsNumber(AValue: Integer);
begin
  if FPointsNumber = AValue then exit;
  FPointsNumber := AValue;
  InvalidateCaches;
  Notify;
end;

procedure TRandomChartSource.SetRandomX(AValue: Boolean);
begin
  if FRandomX = AValue then exit;
  FRandomX := AValue;
  InvalidateCaches;
  Notify;
end;

procedure TRandomChartSource.SetRandSeed(AValue: Integer);
begin
  if FRandSeed = AValue then exit;
  FRandSeed := AValue;
  FRNG.Seed := AValue;
  FCurIndex := -1;
  InvalidateCaches;
  Notify;
end;

procedure TRandomChartSource.SetXMax(AValue: Double);
begin
  if FXMax = AValue then exit;
  FXMax := AValue;
  InvalidateCaches;
  Notify;
end;

procedure TRandomChartSource.SetXMin(AValue: Double);
begin
  if FXMin = AValue then exit;
  FXMin := AValue;
  InvalidateCaches;
  Notify;
end;

procedure TRandomChartSource.SetYCount(AValue: Cardinal);
begin
  if YCount = AValue then exit;
  FYCount := AValue;
  InvalidateCaches;
  Notify;
end;

procedure TRandomChartSource.SetYMax(AValue: Double);
begin
  if FYMax = AValue then exit;
  FYMax := AValue;
  InvalidateCaches;
  Notify;
end;

procedure TRandomChartSource.SetYMin(AValue: Double);
begin
  if FYMin = AValue then exit;
  FYMin := AValue;
  InvalidateCaches;
  Notify;
end;

{ TUserDefinedChartSource }

procedure TUserDefinedChartSource.EndUpdate;
begin
  // There is no way to detect if the extent changed --
  // so call Reset to be a bit safer, but a bit slower.
  Reset;
  inherited EndUpdate;
end;

function TUserDefinedChartSource.GetCount: Integer;
begin
  Result := FPointsNumber;
end;

function TUserDefinedChartSource.GetItem(AIndex: Integer): PChartDataItem;
begin
  SetDataItemDefaults(FItem);
  if Assigned(FOnGetChartDataItem) then
    FOnGetChartDataItem(Self, AIndex, FItem);
  Result := @FItem;
end;

function TUserDefinedChartSource.IsSorted: Boolean;
begin
  Result := Sorted;
end;

procedure TUserDefinedChartSource.Reset;
begin
  InvalidateCaches;
  Notify;
end;

procedure TUserDefinedChartSource.SetOnGetChartDataItem(
  AValue: TGetChartDataItemEvent);
begin
  if TMethod(FOnGetChartDataItem) = TMethod(AValue) then exit;
  FOnGetChartDataItem := AValue;
  Reset;
end;

procedure TUserDefinedChartSource.SetPointsNumber(AValue: Integer);
begin
  if FPointsNumber = AValue then exit;
  FPointsNumber := AValue;
  Reset;
end;

procedure TUserDefinedChartSource.SetYCount(AValue: Cardinal);
begin
  if FYCount = AValue then exit;
  FYCount := AValue;
  SetLength(FItem.YList, Max(YCount - 1, 0));
  Reset;
end;

{ TCalculatedChartSource }

procedure TCalculatedChartSource.CalcAccumulation(AIndex: Integer);
var
  lastItemIndex: Integer = -1;

  function GetOriginItem(AItemIndex: Integer): PChartDataItem;
  begin
    Result := @FItem;
    if lastItemIndex = AItemIndex then exit;
    ExtractItem(AItemIndex);
    lastItemIndex := AItemIndex;
  end;

var
  i, oldLeft, oldRight, newLeft, newRight: Integer;
begin
  if AccumulationDirection = cadCenter then
    FHistory.Capacity := EffectiveAccumulationRange * 2
  else
    FHistory.Capacity := EffectiveAccumulationRange;
  RangeAround(FIndex, oldLeft, oldRight);
  RangeAround(AIndex, newLeft, newRight);
  if
    (FIndex < 0) or (Abs(oldLeft - newLeft) > 1) or
    (Abs(oldRight - newRight) > 1)
  then begin
    FHistory.Clear;
    for i := newLeft to newRight do
      FHistory.AddLast(GetOriginItem(i)^);
  end
  else begin
    if FHistory.Capacity = 0 then
      for i := oldLeft to newLeft - 1 do
        FHistory.RemoveValue(GetOriginItem(i)^)
    else
      for i := oldLeft to newLeft - 1 do
        FHistory.RemoveFirst;
    if FHistory.Capacity = 0 then
      for i := oldRight downto newRight + 1 do
        FHistory.RemoveValue(GetOriginItem(i)^)
    else
      for i := oldRight downto newRight + 1 do
        FHistory.RemoveLast;
    for i := oldLeft - 1 downto newLeft do
      FHistory.AddFirst(GetOriginItem(i)^);
    for i := oldRight + 1 to newRight do
      FHistory.AddLast(GetOriginItem(i)^);
  end;
  GetOriginItem(AIndex);
  case AccumulationMethod of
    camSum:
      FHistory.GetSum(FItem);
    camAverage: begin
      FHistory.GetSum(FItem);
      FItem.MultiplyY(1 / (newRight - newLeft + 1));
    end;
    camDerivative, camSmoothDerivative:
      CalcDerivative(AIndex);
  end;
  FIndex := AIndex;
end;

procedure TCalculatedChartSource.CalcDerivative(AIndex: Integer);

  procedure WeightedSum(const ACoeffs: array of Double; ADir, ACount: Integer);
  var
    i, j: Integer;
    prevItem: PChartDataItem;
  begin
    for j := 0 to ACount - 1 do begin
      prevItem := FHistory.GetPtr(AIndex + ADir * j);
      FItem.Y += prevItem^.Y * ADir * ACoeffs[j];
      for i := 0 to High(FItem.YList) do
        FItem.YList[i] += prevItem^.YList[i] * ADir * ACoeffs[j];
    end;
  end;

// Derivative is approximated by finite differences
// with accuracy order of (AccumulationRange - 1).
// Smoothed derivative coefficients are based on work
// by Pavel Holoborodko (http://www.holoborodko.com/pavel/).
const
  COEFFS_BF: array [Boolean, 2..7, 0..6] of Double = (
    ( (     -1, 1,     0,    0,     0,   0,    0),
      (   -3/2, 2,  -1/2,    0,     0,   0,    0),
      (  -11/6, 3,  -3/2,  1/3,     0,   0,    0),
      ( -25/12, 4,    -3,  4/3,  -1/4,   0,    0),
      (-137/60, 5,    -5, 10/3,  -5/4, 1/5,    0),
      ( -49/20, 6, -15/2, 20/3, -15/4, 6/5, -1/6)
    ),
    ( (   -1,     1,     0,   0,    0,    0,    0),
      ( -1/2,     0,   1/2,   0,    0,    0,    0),
      ( -1/4,  -1/4,   1/4, 1/4,    0,    0,    0),
      ( -1/8,  -1/4,     0, 1/4,  1/8,    0,    0),
      (-1/16, -3/16,  -1/8, 1/8, 3/16, 1/16,    0),
      (-1/32,  -1/8, -5/32,   0, 5/32,  1/8, 1/32)
    ));
  COEFFS_C: array [Boolean, 2..5, 0..4] of Double = (
    ( (0,  1/2,     0,     0,      0),
      (0,  2/3, -1/12,     0,      0),
      (0,  3/4, -3/20,  1/60,      0),
      (0,  4/5,  -1/5, 4/105, -1/280)
    ),
    ( (0,  1/2,    0,    0,     0),
      (0,  1/4,  1/8,    0,     0),
      (0, 5/32,  1/8, 1/32,     0),
      (0, 7/64, 7/64, 3/64, 1/128)
    ));
var
  ar, iLeft, iRight, dir: Integer;
  isSmooth: Boolean;
  dx: Double;
begin
  RangeAround(AIndex, iLeft, iRight);
  case CASE_OF_TWO[iLeft = AIndex, iRight = AIndex] of
    cotNone: begin
      dx := Max(
        FItem.X - FHistory.GetPtr(AIndex - iLeft - 1)^.X,
        FHistory.GetPtr(AIndex - iLeft + 1)^.X - FItem.X);
      ar := Min(Min(AIndex - iLeft, iRight - AIndex) + 1, High(COEFFS_C[false]));
      dir := 0;
    end;
    cotFirst: begin
      dx := FHistory.GetPtr(1)^.X - FItem.X;
      ar := Min(iRight - AIndex + 1, High(COEFFS_BF[false]));
      dir := 1;
    end;
    cotSecond: begin
      dx := FItem.X - FHistory.GetPtr(AIndex - iLeft - 1)^.X;
      ar := Min(AIndex - iLeft + 1, High(COEFFS_BF[false]));
      dir := -1;
    end;
    cotBoth: begin
      FItem.SetY(SafeNan);
      exit;
    end
  end;
  if dx = 0 then begin
    FItem.SetY(SafeNan);
    exit;
  end;
  FItem.SetY(0.0);
  AIndex -= iLeft;
  isSmooth := AccumulationMethod = camSmoothDerivative;
  if dir = 0 then begin
    WeightedSum(COEFFS_C[isSmooth][ar], -1, ar);
    WeightedSum(COEFFS_C[isSmooth][ar], +1, ar);
  end
  else
    WeightedSum(COEFFS_BF[isSmooth][ar], dir, ar);
  FItem.MultiplyY(1 / dx);
end;

procedure TCalculatedChartSource.CalcPercentage;
var
  s: Double;
begin
  if not Percentage then exit;
  s := (FItem.Y + Sum(FItem.YList)) * PERCENT;
  if s = 0 then exit;
  FItem.MultiplyY(1 / s);
end;

procedure TCalculatedChartSource.Changed(ASender: TObject);
begin
  if
    (FOrigin <> nil) and (ASender = FOrigin) and
    (FOrigin.YCount <> FOriginYCount)
  then begin
    UpdateYOrder;
    exit;
  end;
  FIndex := -1;
  InvalidateCaches;
  Notify;
end;

constructor TCalculatedChartSource.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAccumulationRange := 2;
  FIndex := -1;
  FHistory := TChartSourceBuffer.Create;
  FListener := TListener.Create(@FOrigin, @Changed);
end;

destructor TCalculatedChartSource.Destroy;
begin
  FreeAndNil(FHistory);
  FreeAndNil(FListener);
  inherited Destroy;
end;

function TCalculatedChartSource.EffectiveAccumulationRange: Cardinal;
const
  MAX_DERIVATIVE_RANGE = 10;
begin
  if IsDerivative and (AccumulationRange = 0) then
    Result := MAX_DERIVATIVE_RANGE
  else
    Result := AccumulationRange;
end;

procedure TCalculatedChartSource.ExtractItem(AIndex: Integer);

  function YByOrder(AOrderIndex: Integer): Double;
  begin
    if AOrderIndex = 0 then
      Result := FItem.Y
    else
      Result := FItem.YList[AOrderIndex - 1];
  end;

var
  t: TDoubleDynArray;
  i: Integer;
begin
  FItem := Origin[AIndex]^;
  SetLength(t, High(FYOrder));
  for i := 1 to High(FYOrder) do
    t[i - 1] := YByOrder(FYOrder[i]);
  FItem.Y := YByOrder(FYOrder[0]);
  FItem.YList := t;
end;

function TCalculatedChartSource.GetCount: Integer;
begin
  if Origin <> nil then
    Result := Origin.Count
  else
    Result := 0;
end;

function TCalculatedChartSource.GetItem(AIndex: Integer): PChartDataItem;
begin
  if Origin = nil then exit(nil);
  Result := @FItem;
  if FIndex = AIndex then exit;
  if (AccumulationMethod = camNone) or (AccumulationRange = 1) then
    ExtractItem(AIndex)
  else
    CalcAccumulation(AIndex);
  CalcPercentage;
end;

function TCalculatedChartSource.IsDerivative: Boolean;
begin
  Result := AccumulationMethod in [camDerivative, camSmoothDerivative];
end;

function TCalculatedChartSource.IsSorted: Boolean;
begin
  if Origin <> nil then
    Result := Origin.IsSorted
  else
    Result := false;
end;

procedure TCalculatedChartSource.RangeAround(
  AIndex: Integer; out ALeft, ARight: Integer);
var
  ar: Integer;
begin
  ar := EffectiveAccumulationRange;
  ar := IfThen(ar = 0, MaxInt div 2, ar - 1);
  ALeft := AIndex - IfThen(AccumulationDirection = cadForward, 0, ar);
  ARight := AIndex + IfThen(AccumulationDirection = cadBackward, 0, ar);
  ALeft := EnsureRange(ALeft, 0, Count - 1);
  ARight := EnsureRange(ARight, 0, Count - 1);
end;

procedure TCalculatedChartSource.SetAccumulationDirection(
  AValue: TChartAccumulationDirection);
begin
  if FAccumulationDirection = AValue then exit;
  FAccumulationDirection := AValue;
  Changed(nil);
end;

procedure TCalculatedChartSource.SetAccumulationMethod(
  AValue: TChartAccumulationMethod);
begin
  if FAccumulationMethod = AValue then exit;
  FAccumulationMethod := AValue;
  Changed(nil);
end;

procedure TCalculatedChartSource.SetAccumulationRange(AValue: Cardinal);
begin
  if FAccumulationRange = AValue then exit;
  FAccumulationRange := AValue;
  Changed(nil);
end;

procedure TCalculatedChartSource.SetOrigin(AValue: TCustomChartSource);
begin
  if AValue = Self then
      AValue := nil;
  if FOrigin = AValue then exit;
  if FOrigin <> nil then
    FOrigin.Broadcaster.Unsubscribe(FListener);
  FOrigin := AValue;
  if FOrigin <> nil then
    FOrigin.Broadcaster.Subscribe(FListener);
  UpdateYOrder;
end;

procedure TCalculatedChartSource.SetPercentage(AValue: Boolean);
begin
  if FPercentage = AValue then exit;
  FPercentage := AValue;
  Changed(nil);
end;

procedure TCalculatedChartSource.SetReorderYList(const AValue: String);
begin
  if FReorderYList = AValue then exit;
  FReorderYList := AValue;
  UpdateYOrder;
end;

procedure TCalculatedChartSource.SetYCount(AValue: Cardinal);
begin
  Unused(AValue);
  raise EYCountError.Create('Can not set YCount');
end;

procedure TCalculatedChartSource.UpdateYOrder;
var
  order: TStringList;
  i: Integer;
begin
  if FOrigin = nil then begin
    FOriginYCount := 0;
    FYCount := 0;
    FYOrder := nil;
    FItem.YList := nil;
    Changed(nil);
    exit;
  end;

  FOriginYCount := FOrigin.YCount;
  if ReorderYList = '' then begin
    SetLength(FYOrder,  FOriginYCount);
    for i := 0 to High(FYOrder) do
      FYOrder[i] := i;
  end
  else begin
    order := TStringList.Create;
    try
      order.CommaText := ReorderYList;
      SetLength(FYOrder, order.Count);
      for i := 0 to High(FYOrder) do
        FYOrder[i] := EnsureRange(StrToIntDef(order[i], 0), 0, FOriginYCount - 1);
    finally
      order.Free;
    end;
  end;
  FYCount := Length(FYOrder);

  SetLength(FItem.YList, Max(High(FYOrder), 0));
  Changed(nil);
end;

end.

