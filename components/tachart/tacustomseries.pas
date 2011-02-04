{

 Basic types for TAChart series.

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
unit TACustomSeries;

{$H+}

interface

uses
  Classes, Graphics, SysUtils,
  TAChartAxis, TAChartUtils, TACustomSource, TAGraph, TALegend, TASources,
  TAStyles, TATypes;

const
  DEF_AXIS_INDEX = -1;

type
  { TCustomChartSeries }

  TCustomChartSeries = class(TBasicChartSeries)
  private
    FAxisIndexX: Integer;
    FAxisIndexY: Integer;
    FLegend: TChartSeriesLegend;
    procedure SetAxisIndexX(AValue: Integer);
    procedure SetAxisIndexY(AValue: Integer);
    procedure SetLegend(AValue: TChartSeriesLegend);
    procedure SetShowInLegend(AValue: Boolean);

  protected
    procedure AfterAdd; override;
    procedure GetGraphBounds(var ABounds: TDoubleRect); override;
    procedure GetLegendItems(AItems: TChartLegendItems); virtual; abstract;
    procedure GetLegendItemsBasic(AItems: TChartLegendItems); override;
    function GetShowInLegend: Boolean; override;
    procedure SetActive(AValue: Boolean); override;
    procedure SetDepth(AValue: TChartDistance); override;
    procedure SetTitle(const AValue: String); override;
    procedure SetZPosition(AValue: TChartDistance); override;
    procedure StyleChanged(Sender: TObject);
    procedure UpdateParentChart;

  protected
    procedure ReadState(Reader: TReader); override;
    procedure SetParentComponent(AParent: TComponent); override;

  protected
    function GetIndex: Integer; override;
    procedure SetIndex(AValue: Integer); override;

  protected
    function AxisToGraph(const APoint: TDoublePoint): TDoublePoint;
    function AxisToGraphX(AX: Double): Double; override;
    function AxisToGraphY(AY: Double): Double; override;
    function GetAxisX: TChartAxis;
    function GetAxisY: TChartAxis;
    function GraphToAxis(APoint: TDoublePoint): TDoublePoint;
    function GraphToAxisX(AX: Double): Double; override;
    function GraphToAxisY(AY: Double): Double; override;

    function IsRotated: Boolean;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetNearestPoint(
      ADistFunc: TPointDistFunc; const APoint: TPoint;
      out AIndex: Integer; out AImg: TPoint; out AValue: TDoublePoint): Boolean;
      virtual;
    function GetParentComponent: TComponent; override;
    function HasParent: Boolean; override;

    property AxisIndexX: Integer
      read FAxisIndexX write SetAxisIndexX default DEF_AXIS_INDEX;
    property AxisIndexY: Integer
      read FAxisIndexY write SetAxisIndexY default DEF_AXIS_INDEX;

  published
    property Legend: TChartSeriesLegend read FLegend write SetLegend;
    property ShowInLegend: Boolean
      read GetShowInLegend write SetShowInLegend stored false default true;
      deprecated;
  end;

  TChartGetMarkEvent = procedure (
    out AFormattedMark: String; AIndex: Integer) of object;

  { TChartSeries }

  TChartSeries = class(TCustomChartSeries)
  private
    FBuiltinSource: TCustomChartSource;
    FListener: TListener;
    FMarks: TChartMarks;
    FOnGetMark: TChartGetMarkEvent;
    FSource: TCustomChartSource;
    FStyles: TChartStyles;
    FStylesListener: TListener;

    function GetSource: TCustomChartSource;
    function IsSourceStored: boolean;
    procedure SetMarks(const AValue: TChartMarks);
    procedure SetOnGetMark(const AValue: TChartGetMarkEvent);
    procedure SetSource(AValue: TCustomChartSource);
    procedure SetStyles(AValue: TChartStyles);
  protected
    procedure AfterAdd; override;
    procedure AfterDraw; override;
    procedure BeforeDraw; override;
    function ColorOrDefault(AColor: TColor; ADefault: TColor = clTAColor): TColor;
    procedure GetBounds(var ABounds: TDoubleRect); override;
    function GetGraphPoint(AIndex: Integer): TDoublePoint;
    function GetGraphPointX(AIndex: Integer): Double; inline;
    function GetGraphPointY(AIndex: Integer): Double; inline;
    function GetSeriesColor: TColor; virtual;
    function GetXMaxVal: Integer;
    procedure VisitSources(
      AVisitor: TChartOnSourceVisitor; AAxis: TChartAxis; var AData); override;
  protected
    property Styles: TChartStyles read FStyles write SetStyles;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  public
    function  GetColor(AIndex: Integer): TColor;
    procedure GetMax(out X, Y: Double);
    procedure GetMin(out X, Y: Double);
    function  GetXImgValue(AIndex: Integer): Integer;
    function  GetXMax: Double;
    function  GetXMin: Double;
    function  GetXValue(AIndex: Integer): Double;
    function  GetYImgValue(AIndex: Integer): Integer;
    function  GetYMax: Double;
    function  GetYMin: Double;
    function  GetYValue(AIndex: Integer): Double;
    procedure SetColor(AIndex: Integer; AColor: TColor);
    procedure SetXValue(AIndex: Integer; AValue: Double); inline;
    procedure SetYValue(AIndex: Integer; AValue: Double); inline;
  public
    function Add(AValue: Double; XLabel: String; Color: TColor): Integer; inline;
    function AddXY(
      X, Y: Double; XLabel: String; Color: TColor): Integer; virtual; overload;
    function AddXY(X, Y: Double): Integer; overload; inline;
    procedure Clear; inline;
    function Count: Integer; inline;
    procedure Delete(AIndex: Integer); virtual;
    function Extent: TDoubleRect; virtual;
    function FormattedMark(AIndex: Integer): String;
    function IsEmpty: Boolean; override;
    function ListSource: TListChartSource;
    property Source: TCustomChartSource
      read GetSource write SetSource stored IsSourceStored;
  published
    property Active default true;
    property Marks: TChartMarks read FMarks write SetMarks;
    property ShowInLegend;
    property Title;
    property ZPosition;
  published
    property OnGetMark: TChartGetMarkEvent read FOnGetMark write SetOnGetMark;
  end;

  TLabelDirection = (ldLeft, ldTop, ldRight, ldBottom);

  { TBasicPointSeries }

  TBasicPointSeries = class(TChartSeries)
  private
    procedure SetUseReticule(AValue: Boolean);

  protected
    FGraphPoints: array of TDoublePoint;
    FLoBound: Integer;
    FMinXRange: Double;
    FUpBound: Integer;
    FUseReticule: Boolean;

    procedure DrawLabels(ACanvas: TCanvas);
    function GetLabelDirection(AIndex: Integer): TLabelDirection; virtual;
    procedure GetLegendItemsRect(AItems: TChartLegendItems; ABrush: TBrush);
    function GetXRange(AX: Double; AIndex: Integer): Double;
    procedure PrepareGraphPoints(
      const AExtent: TDoubleRect; AFilterByExtent: Boolean);
    procedure UpdateGraphPoints(AIndex: Integer);
    procedure UpdateMargins(ACanvas: TCanvas; var AMargins: TRect); override;
    procedure UpdateMinXRange;
    property UseReticule: Boolean
      read FUseReticule write SetUseReticule default false;
  public
    function GetNearestPoint(
      ADistFunc: TPointDistFunc; const APoint: TPoint;
      out AIndex: Integer; out AImg: TPoint; out AValue: TDoublePoint): Boolean;
      override;
    procedure MovePoint(var AIndex: Integer; const ANewPos: TPoint); override;
  end;

implementation

uses
  Math, PropEdits, Types;

{ TCustomChartSeries }

procedure TCustomChartSeries.AfterAdd;
begin
  Legend.SetOwner(FChart);
end;

function TCustomChartSeries.AxisToGraph(
  const APoint: TDoublePoint): TDoublePoint;
begin
  Result := DoublePoint(AxisToGraphX(APoint.X), AxisToGraphY(APoint.Y));
  if IsRotated then
    Exchange(Result.X, Result.Y);
end;

function TCustomChartSeries.AxisToGraphX(AX: Double): Double;
begin
  Result := TransformByAxis(FChart.AxisList, AxisIndexX).AxisToGraph(AX)
end;

function TCustomChartSeries.AxisToGraphY(AY: Double): Double;
begin
  Result := TransformByAxis(FChart.AxisList, AxisIndexY).AxisToGraph(AY)
end;

constructor TCustomChartSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActive := true;
  FAxisIndexX := DEF_AXIS_INDEX;
  FAxisIndexY := DEF_AXIS_INDEX;
  FLegend := TChartSeriesLegend.Create(FChart);
end;

destructor TCustomChartSeries.Destroy;
begin
  FreeAndNil(FLegend);
  inherited Destroy;
end;

function TCustomChartSeries.GetAxisX: TChartAxis;
begin
  if InRange(AxisIndexX, 0, FChart.AxisList.Count - 1) then
    Result := FChart.AxisList[AxisIndexX]
  else
    Result := FChart.BottomAxis;
end;

function TCustomChartSeries.GetAxisY: TChartAxis;
begin
  if InRange(AxisIndexY, 0, FChart.AxisList.Count - 1) then
    Result := FChart.AxisList[AxisIndexY]
  else
    Result := FChart.LeftAxis;
end;

procedure TCustomChartSeries.GetGraphBounds(var ABounds: TDoubleRect);
begin
  GetBounds(ABounds);
  with ABounds do begin
    TransformByAxis(FChart.AxisList, AxisIndexX).UpdateBounds(a.X, b.X);
    TransformByAxis(FChart.AxisList, AxisIndexY).UpdateBounds(a.Y, b.Y);
    if IsRotated then begin
      Exchange(a.X, a.Y);
      Exchange(b.X, b.Y);
    end;
  end;
end;

function TCustomChartSeries.GetIndex: Integer;
begin
  Result := FChart.Series.List.IndexOf(Self);
end;

procedure TCustomChartSeries.GetLegendItemsBasic(AItems: TChartLegendItems);
var
  i: Integer;
begin
  if Assigned(Legend.OnDraw) then
    for i := 0 to Legend.UserItemsCount - 1 do
      AItems.Add(TLegendItemUserDrawn.Create(i, Legend.OnDraw, Title))
  else
    GetLegendItems(AItems);
end;

function TCustomChartSeries.GetNearestPoint(
  ADistFunc: TPointDistFunc; const APoint: TPoint; out AIndex: Integer;
  out AImg: TPoint; out AValue: TDoublePoint): Boolean;
begin
  Unused(ADistFunc, APoint);
  AIndex := 0;
  AImg := Point(0, 0);
  AValue := ZeroDoublePoint;
  Result := false;
end;

function TCustomChartSeries.GetParentComponent: TComponent;
begin
  Result := FChart;
end;

function TCustomChartSeries.GetShowInLegend: Boolean;
begin
  Result := Legend.Visible;
end;

function TCustomChartSeries.GraphToAxis(APoint: TDoublePoint): TDoublePoint;
begin
  if IsRotated then
    Exchange(APoint.X, APoint.Y);
  Result := DoublePoint(GraphToAxisX(APoint.X), GraphToAxisY(APoint.Y));
end;

function TCustomChartSeries.GraphToAxisX(AX: Double): Double;
begin
  Result := TransformByAxis(FChart.AxisList, AxisIndexX).GraphToAxis(AX)
end;

function TCustomChartSeries.GraphToAxisY(AY: Double): Double;
begin
  Result := TransformByAxis(FChart.AxisList, AxisIndexY).GraphToAxis(AY)
end;

function TCustomChartSeries.HasParent: Boolean;
begin
  Result := true;
end;

function TCustomChartSeries.IsRotated: Boolean;
begin
  Result :=
    (AxisIndexX >= 0) and FChart.AxisList[AxisIndexX].IsVertical and
    (AxisIndexY >= 0) and not FChart.AxisList[AxisIndexY].IsVertical;
end;

procedure TCustomChartSeries.ReadState(Reader: TReader);
begin
  inherited ReadState(Reader);
  if Reader.Parent is TChart then
    (Reader.Parent as TChart).AddSeries(Self);
end;

procedure TCustomChartSeries.SetActive(AValue: Boolean);
begin
  if FActive = AValue then exit;
  FActive := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetAxisIndexX(AValue: Integer);
begin
  if FAxisIndexX = AValue then exit;
  FAxisIndexX := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetAxisIndexY(AValue: Integer);
begin
  if FAxisIndexY = AValue then exit;
  FAxisIndexY := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetDepth(AValue: TChartDistance);
begin
  if FDepth = AValue then exit;
  FDepth := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetIndex(AValue: Integer);
begin
  with FChart.Series.List do
    Move(Index, EnsureRange(AValue, 0, Count - 1));
end;

procedure TCustomChartSeries.SetLegend(AValue: TChartSeriesLegend);
begin
  if FLegend = AValue then exit;
  FLegend := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetParentComponent(AParent: TComponent);
begin
  if not (csLoading in ComponentState) then
    (AParent as TChart).AddSeries(Self);
end;

procedure TCustomChartSeries.SetShowInLegend(AValue: Boolean);
begin
  Legend.Visible := AValue;
end;

procedure TCustomChartSeries.SetTitle(const AValue: String);
begin
  if FTitle = AValue then exit;
  FTitle := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetZPosition(AValue: TChartDistance);
begin
  if FZPosition = AValue then exit;
  FZPosition := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.StyleChanged(Sender: TObject);
begin
  UpdateParentChart;
end;

procedure TCustomChartSeries.UpdateParentChart;
begin
  if ParentChart <> nil then
    ParentChart.StyleChanged(Self);
end;

{ TChartSeries }

function TChartSeries.Add(AValue: Double; XLabel: String; Color: TColor): Integer;
begin
  Result := AddXY(GetXMaxVal + 1, AValue, XLabel, Color);
end;

function TChartSeries.AddXY(X, Y: Double; XLabel: String; Color: TColor): Integer;
begin
  Result := ListSource.Add(X, Y, XLabel, Color);
end;

function TChartSeries.AddXY(X, Y: Double): Integer;
begin
  Result := AddXY(X, Y, '', clTAColor);
end;

procedure TChartSeries.AfterAdd;
begin
  inherited;
  FMarks.SetOwner(FChart);
end;

procedure TChartSeries.AfterDraw;
begin
  inherited AfterDraw;
  Source.AfterDraw;
end;

procedure TChartSeries.BeforeDraw;
begin
  inherited BeforeDraw;
  Source.BeforeDraw;
end;

procedure TChartSeries.Clear;
begin
  ListSource.Clear;
end;

function TChartSeries.ColorOrDefault(AColor: TColor; ADefault: TColor): TColor;
begin
  Result := AColor;
  if Result <> clTAColor then exit;
  Result := ADefault;
  if Result <> clTAColor then exit;
  Result := GetSeriesColor;
end;

function TChartSeries.Count: Integer;
begin
  Result := Source.Count;
end;

constructor TChartSeries.Create(AOwner: TComponent);
const
  BUILTIN_SOURCE_NAME = 'Builtin';
begin
  inherited Create(AOwner);

  FListener := TListener.Create(@FSource,  @StyleChanged);
  FBuiltinSource := TListChartSource.Create(Self);
  FBuiltinSource.Name := BUILTIN_SOURCE_NAME;
  FBuiltinSource.Broadcaster.Subscribe(FListener);
  FMarks := TChartMarks.Create(FChart);
  FStylesListener := TListener.Create(@FStyles,  @StyleChanged);
end;

procedure TChartSeries.Delete(AIndex: Integer);
begin
  ListSource.Delete(AIndex);
end;

destructor TChartSeries.Destroy;
begin
  FreeAndNil(FListener);
  FreeAndNil(FBuiltinSource);
  FreeAndNil(FMarks);
  FreeAndNil(FStylesListener);
  inherited;
end;

function TChartSeries.Extent: TDoubleRect;
begin
  Result := Source.ExtentCumulative;
end;

function TChartSeries.FormattedMark(AIndex: integer): String;
begin
  if Assigned(FOnGetMark) then
    FOnGetMark(Result, AIndex)
  else
    Result := Source.FormatItem(Marks.Format, AIndex);
end;

procedure TChartSeries.GetBounds(var ABounds: TDoubleRect);
begin
  if not Active or (Count = 0) then exit;
  ABounds := Extent;
end;

function TChartSeries.GetColor(AIndex: Integer): TColor;
begin
  Result := ColorOrDefault(Source[AIndex]^.Color);
end;

function TChartSeries.GetGraphPoint(AIndex: Integer): TDoublePoint;
begin
  Result.X := GetGraphPointX(AIndex);
  Result.Y := GetGraphPointY(AIndex);;
  if IsRotated then
    Exchange(Result.X, Result.Y);
end;

function TChartSeries.GetGraphPointX(AIndex: Integer): Double;
begin
  Result := AxisToGraphX(Source[AIndex]^.X);
end;

function TChartSeries.GetGraphPointY(AIndex: Integer): Double;
begin
  Result := AxisToGraphY(Source[AIndex]^.Y);
end;

procedure TChartSeries.GetMax(out X, Y: Double);
begin
  X := Source.XOfMax;
  Y := Extent.b.Y;
end;

procedure TChartSeries.GetMin(out X, Y: Double);
begin
  X := Source.XOfMin;
  Y := Extent.a.Y;
end;

function TChartSeries.GetSeriesColor: TColor;
begin
  Result := clTAColor;
end;

function TChartSeries.GetSource: TCustomChartSource;
begin
  if Assigned(FSource) then
    Result := FSource
  else
    Result := FBuiltinSource;
end;

function TChartSeries.GetXImgValue(AIndex: Integer): Integer;
begin
  Result := ParentChart.XGraphToImage(Source[AIndex]^.X);
end;

function TChartSeries.GetXMax: Double;
begin
  Result := Extent.b.X;
end;

function TChartSeries.GetXMaxVal: Integer;
begin
  if Count > 0 then
    Result := Round(Source[Count - 1]^.X)
  else
    Result := 0;
end;

function TChartSeries.GetXMin: Double;
begin
  Result := Extent.a.X;
end;

function TChartSeries.GetXValue(AIndex: Integer): Double;
begin
  Result := Source[AIndex]^.X;
end;

function TChartSeries.GetYImgValue(AIndex: Integer): Integer;
begin
  Result := ParentChart.YGraphToImage(Source[AIndex]^.Y);
end;

function TChartSeries.GetYMax: Double;
begin
  Result := Extent.b.Y;
end;

function TChartSeries.GetYMin: Double;
begin
  Result := Extent.a.Y;
end;

function TChartSeries.GetYValue(AIndex: Integer): Double;
begin
  Result := Source[AIndex]^.Y;
end;

function TChartSeries.IsEmpty: Boolean;
begin
  Result := Count = 0;
end;

function TChartSeries.IsSourceStored: boolean;
begin
  Result := FSource <> nil;
end;

function TChartSeries.ListSource: TListChartSource;
begin
  if not (Source is TListChartSource) then
    raise EEditableSourceRequired.Create('Editable chart source required');
  Result := Source as TListChartSource;
end;

procedure TChartSeries.SetColor(AIndex: Integer; AColor: TColor);
begin
  with Source[AIndex]^ do begin
    if Color = AColor then exit;
    Color := AColor;
    UpdateParentChart;
  end;
end;

procedure TChartSeries.SetMarks(const AValue: TChartMarks);
begin
  if FMarks = AValue then exit;
  FMarks.Assign(AValue);
end;

procedure TChartSeries.SetOnGetMark(const AValue: TChartGetMarkEvent);
begin
  if FOnGetMark = AValue then exit;
  FOnGetMark := AValue;
  UpdateParentChart;
end;

procedure TChartSeries.SetSource(AValue: TCustomChartSource);
begin
  if FSource = AValue then exit;
  if FListener.IsListening then
    Source.Broadcaster.Unsubscribe(FListener);
  FSource := AValue;
  Source.Broadcaster.Subscribe(FListener);
  UpdateParentChart;
end;

procedure TChartSeries.SetStyles(AValue: TChartStyles);
begin
  if FStyles = AValue then exit;
  if FStylesListener.IsListening then
    Styles.Broadcaster.Unsubscribe(FStylesListener);
  FStyles := AValue;
  Styles.Broadcaster.Subscribe(FStylesListener);
  UpdateParentChart;
end;

procedure TChartSeries.SetXValue(AIndex: Integer; AValue: Double); inline;
begin
  ListSource.SetXValue(AIndex, AValue);
end;

procedure TChartSeries.SetYValue(AIndex: Integer; AValue: Double); inline;
begin
  ListSource.SetYValue(AIndex, AValue);
end;

procedure TChartSeries.VisitSources(
  AVisitor: TChartOnSourceVisitor; AAxis: TChartAxis; var AData);
begin
  if (AAxis = GetAxisX) or (AAxis = GetAxisY) then
    AVisitor(Source, AData);
end;

{ TBasicPointSeries }

procedure TBasicPointSeries.DrawLabels(ACanvas: TCanvas);
var
  prevLabelPoly: TPointArray;

  procedure DrawLabel(
    const AText: String; const ADataPoint: TPoint; ADir: TLabelDirection);
  const
    OFFSETS: array [TLabelDirection] of TPoint =
      ((X: -1; Y: 0), (X: 0; Y: -1), (X: 1; Y: 0), (X: 0; Y: 1));
  var
    center: TPoint;
  begin
    if AText = '' then exit;
    center := ADataPoint + OFFSETS[ADir] * Marks.CenterOffset(ACanvas, AText);
    Marks.DrawLabel(ACanvas, ADataPoint, center, AText, prevLabelPoly);
  end;

var
  g: TDoublePoint;
  i: Integer;
begin
  if not Marks.IsMarkLabelsVisible then exit;
  for i := 0 to Count - 1 do begin
    g := GetGraphPoint(i);
    with ParentChart do
      if IsPointInViewPort(g) then
        DrawLabel(FormattedMark(i), GraphToImage(g), GetLabelDirection(i));
  end;
end;

function TBasicPointSeries.GetLabelDirection(AIndex: Integer): TLabelDirection;
const
  DIR: array [Boolean, Boolean] of TLabelDirection =
    ((ldTop, ldBottom), (ldRight, ldLeft));
begin
  Result := DIR[IsRotated, GetGraphPointY(AIndex) < 0];
end;

procedure TBasicPointSeries.GetLegendItemsRect(
  AItems: TChartLegendItems; ABrush: TBrush);
var
  i: Integer;
  li: TLegendItemBrushRect;
begin
  case Legend.Multiplicity of
    lmSingle:
      AItems.Add(TLegendItemBrushRect.Create(ABrush, Title));
    lmPoint:
      for i := 0 to Count - 1 do begin
        li := TLegendItemBrushRect.Create(ABrush, FormattedMark(i));
        li.Color := GetColor(i);
        AItems.Add(li);
      end;
  end;
end;

function TBasicPointSeries.GetNearestPoint(
  ADistFunc: TPointDistFunc; const APoint: TPoint;
  out AIndex: Integer; out AImg: TPoint; out AValue: TDoublePoint): Boolean;
var
  dist, minDist, i: Integer;
  pt: TPoint;
begin
  Result := UseReticule and (Count > 0);
  minDist := MaxInt;
  for i := 0 to Count - 1 do begin
    // Since axis transformation may be non-linear, the distance should be
    // measured in screen coordinates. With high zoom ratios this may lead to
    // an integer overflow, so ADistFunc should use saturation arithmetics.
    pt := Point(GetXImgValue(i), GetYImgValue(i));
    dist := ADistFunc(APoint, pt);
    if dist >= minDist then
      continue;
    minDist := dist;
    AIndex := i;
    AImg := pt;
    AValue.X := GetXValue(i);
    AValue.Y := GetYValue(i);
  end;
end;

function TBasicPointSeries.GetXRange(AX: Double; AIndex: Integer): Double;
begin
  case CASE_OF_TWO[AIndex > 0, AIndex < Count - 1] of
    cotNone: Result := 1.0;
    cotFirst: Result := Abs(AX - GetGraphPointX(AIndex - 1));
    cotSecond: Result := Abs(AX - GetGraphPointX(AIndex + 1));
    cotBoth: Result := Min(
      Abs(AX - GetGraphPointX(AIndex - 1)),
      Abs(AX - GetGraphPointX(AIndex + 1)));
  end;
end;

procedure TBasicPointSeries.MovePoint(
  var AIndex: Integer; const ANewPos: TPoint);
var
  p: TDoublePoint;
begin
  if not InRange(AIndex, 0, Count - 1) then exit;
  p := FChart.ImageToGraph(ANewPos);
  with ListSource do begin
    AIndex := SetXValue(AIndex, p.X);
    SetYValue(AIndex, p.Y);
  end;
end;

procedure TBasicPointSeries.PrepareGraphPoints(
  const AExtent: TDoubleRect; AFilterByExtent: Boolean);
var
  axisExtent: TDoubleInterval;
  i: Integer;
begin
  // Find an interval of x-values intersecting the extent.
  // Requires monotonic (but not necessarily increasing) axis transformation.
  FLoBound := 0;
  FUpBound := Count - 1;
  if AFilterByExtent then begin
    with AExtent do
      if IsRotated then
        axisExtent := DoubleInterval(GraphToAxisY(a.Y), GraphToAxisY(b.Y))
      else
        axisExtent := DoubleInterval(GraphToAxisX(a.X), GraphToAxisX(b.X));
    Source.FindBounds(axisExtent.FStart, axisExtent.FEnd, FLoBound, FUpBound);
    FLoBound := Max(FLoBound - 1, 0);
    FUpBound := Min(FUpBound + 1, Count - 1);
  end;

  SetLength(FGraphPoints, FUpBound - FLoBound + 1);
  if (AxisIndexX < 0) and (AxisIndexY < 0) then
    // Optimization: bypass transformations in the default case.
    for i := FLoBound to FUpBound do
      with Source[i]^ do
        FGraphPoints[i - FLoBound] := DoublePoint(X, Y)
  else
    for i := FLoBound to FUpBound do
      FGraphPoints[i - FLoBound] := GetGraphPoint(i);
end;

procedure TBasicPointSeries.SetUseReticule(AValue: Boolean);
begin
  if FUseReticule = AValue then exit;
  FUseReticule := AValue;
  UpdateParentChart;
end;

procedure TBasicPointSeries.UpdateGraphPoints(AIndex: Integer);
var
  i: Integer;
begin
  if IsRotated then
    for i := FLoBound to FUpBound do
      FGraphPoints[i - FLoBound].X += AxisToGraphY(Source[i]^.YList[AIndex])
  else
    for i := FLoBound to FUpBound do
      FGraphPoints[i - FLoBound].Y += AxisToGraphY(Source[i]^.YList[AIndex]);
end;

procedure TBasicPointSeries.UpdateMargins(ACanvas: TCanvas; var AMargins: TRect);
const
  LABEL_TO_BORDER = 4;
var
  i, dist, d: Integer;
  labelText: String;
  dir: TLabelDirection;
  m: array [TLabelDirection] of Integer absolute AMargins;
begin
  if not Marks.IsMarkLabelsVisible then exit;

  for i := 0 to Count - 1 do begin
    if not ParentChart.IsPointInViewPort(GetGraphPoint(i)) then continue;
    labelText := FormattedMark(i);
    if labelText = '' then continue;

    dir := GetLabelDirection(i);
    d := IfThen(Marks.DistanceToCenter, 2, 1);
    with Marks.MeasureLabel(ACanvas, labelText) do
      dist := IfThen(dir in [ldLeft, ldRight], cx, cy) div d;
    m[dir] := Max(m[dir], dist + Marks.Distance + LABEL_TO_BORDER);
  end;
end;

procedure TBasicPointSeries.UpdateMinXRange;
var
  x, prevX: Double;
  i: Integer;
begin
  if Count < 2 then begin
    FMinXRange := 1.0;
    exit;
  end;
  x := Source[0]^.X;
  prevX := Source[1]^.X;
  FMinXRange := Abs(x - prevX);
  for i := 2 to Count - 1 do begin
    x := Source[i]^.X;
    FMinXRange := Min(Abs(x - prevX), FMinXRange);
    prevX := x;
  end;
end;

procedure SkipObsoleteProperties;
begin
  RegisterPropertyEditor(
    TypeInfo(Boolean), TCustomChartSeries,
    'ShowInLegend', THiddenPropertyEditor);
end;

initialization
  SkipObsoleteProperties;

end.

