{

 Function series for TAChart.

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
unit TAFuncSeries;

{$H+}

interface

uses
  Classes, Graphics, typ, Types,
  TAChartUtils, TACustomSeries, TACustomSource, TADrawUtils, TALegend, TATypes;

const
  DEF_FUNC_STEP = 2;
  DEF_SPLINE_DEGREE = 3;
  DEF_SPLINE_STEP = 4;
  DEF_FIT_STEP = 4;
  DEF_FIT_PARAM_COUNT = 3;
  DEF_COLORMAP_STEP = 4;

type
  TFuncCalculateEvent = procedure (const AX: Double; out AY: Double) of object;

  TFuncSeriesStep = 1..MaxInt;

  { TBasicFuncSeries }

  TBasicFuncSeries = class(TCustomChartSeries)
  strict private
    FExtent: TChartExtent;
    procedure SetExtent(AValue: TChartExtent);
  protected
    procedure AfterAdd; override;
    procedure GetBounds(var ABounds: TDoubleRect); override;
  public
    procedure Assign(ASource: TPersistent); override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Active default true;
    property Extent: TChartExtent read FExtent write SetExtent;
    property ShowInLegend;
    property Title;
    property ZPosition;
  end;

  { TFuncSeries }

  TFuncSeries = class(TBasicFuncSeries)
  strict private
    FDomainExclusions: TIntervalList;
    FOnCalculate: TFuncCalculateEvent;
    FPen: TChartPen;
    FStep: TFuncSeriesStep;

    function DoCalcIdentity(AX: Double): Double;
    function DoCalculate(AX: Double): Double;
    procedure SetOnCalculate(AValue: TFuncCalculateEvent);
    procedure SetPen(AValue: TChartPen);
    procedure SetStep(AValue: TFuncSeriesStep);
  protected
    procedure GetLegendItems(AItems: TChartLegendItems); override;

  public
    procedure Assign(ASource: TPersistent); override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Draw(ADrawer: IChartDrawer); override;
    function GetNearestPoint(
      const AParams: TNearestPointParams;
      out AResults: TNearestPointResults): Boolean; override;
    function IsEmpty: Boolean; override;
  public
    property DomainExclusions: TIntervalList read FDomainExclusions;
  published
    property AxisIndexX;
    property AxisIndexY;
    property OnCalculate: TFuncCalculateEvent
      read FOnCalculate write SetOnCalculate;
    property Pen: TChartPen read FPen write SetPen;
    property Step: TFuncSeriesStep
      read FStep write SetStep default DEF_FUNC_STEP;
  end;

  TSplineDegree = 1..100;

  { TBSplineSeries }

  TBSplineSeries = class(TBasicPointSeries)
  strict private
    FDegree: TSplineDegree;
    FPen: TChartPen;
    FStep: TFuncSeriesStep;

    procedure SetDegree(AValue: TSplineDegree);
    procedure SetPen(AValue: TChartPen);
    procedure SetStep(AValue: TFuncSeriesStep);
  protected
    procedure GetLegendItems(AItems: TChartLegendItems); override;

  public
    procedure Assign(ASource: TPersistent); override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Draw(ADrawer: IChartDrawer); override;
  published
    property Active default true;
    property AxisIndexX;
    property AxisIndexY;
    property ShowInLegend;
    property Source;
    property Title;
    property ZPosition;
  published
    property Degree: TSplineDegree
      read FDegree write SetDegree default DEF_SPLINE_DEGREE;
    property Pen: TChartPen read FPen write SetPen;
    property Pointer;
    property Step: TFuncSeriesStep
      read FStep write SetStep default DEF_SPLINE_STEP;
  end;

  TBadDataChartPen = class(TChartPen)
  published
    property Color default clRed;
  end;

  TCubicSplineOptions = set of (
    csoDrawFewPoints, csoDrawUnorderedX, csoExtrapolateLeft,
    csoExtrapolateRight);

  { TCubicSplineSeries }

  TCubicSplineSeries = class(TBasicPointSeries)
  strict private
    FBadDataPen: TBadDataChartPen;
    FOptions: TCubicSplineOptions;
    FPen: TChartPen;
    FStep: TFuncSeriesStep;

    procedure SetPen(AValue: TChartPen);
    procedure SetStep(AValue: TFuncSeriesStep);
  strict private
    FUnorderedX: Boolean;
    FX, FY, FCoeff: array of ArbFloat;

    procedure PrepareCoeffs;
    function PrepareIntervals: TIntervalList;
    procedure SetBadDataPen(AValue: TBadDataChartPen);
    procedure SetOptions(AValue: TCubicSplineOptions);
  protected
    procedure GetLegendItems(AItems: TChartLegendItems); override;
    procedure SourceChanged(ASender: TObject); override;

  public
    procedure Assign(ASource: TPersistent); override;
    function Calculate(AX: Double): Double;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Draw(ADrawer: IChartDrawer); override;
    function Extent: TDoubleRect; override;
    function GetNearestPoint(
      const AParams: TNearestPointParams;
      out AResults: TNearestPointResults): Boolean; override;
  published
    property Active default true;
    property AxisIndexX;
    property AxisIndexY;
    property Pointer;
    property ShowInLegend;
    property Source;
    property Title;
    property ZPosition;
  published
    // Used when data is not suitable for drawing cubic spline --
    // e.g. points are too few or not ordered by X value.
    property BadDataPen: TBadDataChartPen read FBadDataPen write SetBadDataPen;
    property Options: TCubicSplineOptions
      read FOptions write SetOptions default [];
    property Pen: TChartPen read FPen write SetPen;
    property Step: TFuncSeriesStep
      read FStep write SetStep default DEF_SPLINE_STEP;
  end;

  TFitEquation = (
    fePolynomial, // y = b0 + b1*x + b2*x^2 + ... bn*x^n
    feLinear,     // y = a + b*x
    feExp,        // y = a * exp(b * x)
    fePower       // y = a * x^b
  );

  TFitSeries = class(TBasicPointSeries)
  strict private
    FDrawFitRangeOnly: Boolean;
    FFitEquation: TFitEquation;
    FFitParams: TDoubleDynArray;
    FFitRange: TChartRange;
    FOnFitComplete: TNotifyEvent;
    FPen: TChartPen;
    FStep: TFuncSeriesStep;
    FValidFitParams: Boolean;
    function GetParam(AIndex: Integer): Double;
    function GetParamCount: Integer;
    function PrepareIntervals: TIntervalList;
    procedure SetDrawFitRangeOnly(AValue: Boolean);
    procedure SetFitEquation(AValue: TFitEquation);
    procedure SetFitRange(AValue: TChartRange);
    procedure SetParam(AIndex: Integer; AValue: Double);
    procedure SetParamCount(AValue: Integer);
    procedure SetPen(AValue: TChartPen);
    procedure SetStep(AValue: TFuncSeriesStep);
  strict protected
    procedure CalcXRange(out AXMin, AXMax: Double);
    procedure Transform(AX, AY: Double; out ANewX, ANewY: Extended);
  protected
    procedure AfterAdd; override;
    procedure GetLegendItems(AItems: TChartLegendItems); override;
    procedure SourceChanged(ASender: TObject); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    function Calculate(AX: Double): Double; virtual;
    procedure Draw(ADrawer: IChartDrawer); override;
    procedure ExecFit; virtual;
    function GetFitEquationString(
      ANumFormat: String; AXText: String = 'x'; AYText: String = 'y'): String; virtual;
    function GetNearestPoint(
      const AParams: TNearestPointParams;
      out AResults: TNearestPointResults): Boolean; override;
    property Param[AIndex: Integer]: Double read GetParam write SetParam;
  published
    property AxisIndexX;
    property AxisIndexY;
    property DrawFitRangeOnly: Boolean
      read FDrawFitRangeOnly write SetDrawFitRangeOnly default true;
    property FitEquation: TFitEquation read FFitEquation write SetFitEquation default fePolynomial;
    property FitRange: TChartRange read FFitRange write SetFitRange;
    property OnFitComplete: TNotifyEvent read FOnFitComplete write FOnFitComplete;
    property ParamCount: Integer
      read GetParamCount write SetParamCount default DEF_FIT_PARAM_COUNT;
    property Pen: TChartPen read FPen write SetPen;
    property Source;
    property Step: TFuncSeriesStep read FStep write SetStep default DEF_FIT_STEP;
  end;

  TFuncCalculate3DEvent =
    procedure (const AX, AY: Double; out AZ: Double) of object;

  { TColorMapSeries }

  TColorMapSeries = class(TBasicFuncSeries)
  strict private
    FBrush: TBrush;
    FColorSource: TCustomChartSource;
    FColorSourceListener: TListener;
    FInterpolate: Boolean;
    FOnCalculate: TFuncCalculate3DEvent;
    FStepX: TFuncSeriesStep;
    FStepY: TFuncSeriesStep;
    procedure SetBrush(AValue: TBrush);
    procedure SetColorSource(AValue: TCustomChartSource);
    procedure SetInterpolate(AValue: Boolean);
    procedure SetOnCalculate(AValue: TFuncCalculate3DEvent);
    procedure SetStepX(AValue: TFuncSeriesStep);
    procedure SetStepY(AValue: TFuncSeriesStep);
  protected
    procedure GetLegendItems(AItems: TChartLegendItems); override;

  public
    procedure Assign(ASource: TPersistent); override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  public
    function ColorByValue(AValue: Double): TColor;
    procedure Draw(ADrawer: IChartDrawer); override;
    function IsEmpty: Boolean; override;
  published
    property AxisIndexX;
    property AxisIndexY;
    property Brush: TBrush read FBrush write SetBrush;
    property ColorSource: TCustomChartSource
      read FColorSource write SetColorSource;
    property Interpolate: Boolean
      read FInterpolate write SetInterpolate default false;
    property OnCalculate: TFuncCalculate3DEvent
      read FOnCalculate write SetOnCalculate;
    property StepX: TFuncSeriesStep
      read FStepX write SetStepX default DEF_COLORMAP_STEP;
    property StepY: TFuncSeriesStep
      read FStepY write SetStepY default DEF_COLORMAP_STEP;
  end;

  function ParamsToEquation(
    AEquation: TFitEquation; const AParams: array of Double;
    ANumFormat: String; AXText: String = 'x'; AYText: String = 'y'): String;

implementation

uses
  ipf, Math, StrUtils, SysUtils, TAGeometry, TAGraph, TAMath;

type
  TMakeDoublePoint = function (AX, AY: Double): TDoublePoint;

  TDrawFuncHelper = class
  strict private
  type
    TOnPoint = procedure (AXg, AXa: Double) of object;
  var
    FAxisToGraphXr, FAxisToGraphYr, FGraphToAxisXr: TTransformFunc;
    FCalc: TTransformFunc;
    FChart: TChart;
    FDomainExclusions: TIntervalList;
    FDrawer: IChartDrawer;
    FExtent: TDoubleRect;
    FGraphStep: Double;
    FNearestPointParams: ^TNearestPointParams;
    FNearestPointResults: ^TNearestPointResults;
    FMakeDP: TMakeDoublePoint;
    FPrev: TDoublePoint;
    FPrevInExtent: Boolean;
    FSeries: TCustomChartSeries;

    procedure CalcAt(AXg, AXa: Double; out APt: TDoublePoint; out AIn: Boolean);
    procedure CheckForNearestPoint(AXg, AXa: Double);
    procedure ForEachPoint(AXg, AXMax: Double; AOnMoveTo, AOnLineTo: TOnPoint);
    procedure LineTo(AXg, AXa: Double);
    procedure MoveTo(AXg, AXa: Double);
  public
    constructor Create(
      ASeries: TCustomChartSeries; ADomainExclusions:
      TIntervalList; ACalc: TTransformFunc; AStep: Integer);
    procedure DrawFunction(ADrawer: IChartDrawer);
    function GetNearestPoint(
      const AParams: TNearestPointParams;
      out AResults: TNearestPointResults): Boolean;
  end;

  TFitSeriesRange = class(TChartRange)
  strict private
    FSeries: TFitSeries;
  strict protected
    procedure StyleChanged(ASender: TObject); override;
  public
    constructor Create(ASeries: TFitSeries);
  end;

function DoublePointRotated(AX, AY: Double): TDoublePoint;
begin
  Result.X := AY;
  Result.Y := AX;
end;

// Builds an equation string based on the parameters and the type of equation.
// AXText and AYText are placeholders for the x and y variables, respectively.
// Parameters are formatted by passing ANumFormat to the "Format" function.
function ParamsToEquation(
  AEquation: TFitEquation; const AParams: array of Double;
  ANumFormat, AXText, AYText: String): String;
var
  ps: String = '';
  i: Integer;
begin
  if Length(AParams) = 0 then exit('');
  Result := Format('%s = ' + ANumFormat, [AYText, AParams[0]]);
  if AEquation in [fePolynomial, feLinear] then
    for i := 1 to High(AParams) do begin
      if AParams[i] = 0 then continue;
      if i > 1 then ps := Format('^%d', [i]);
      Result += Format(
        ' %s ' + ANumFormat + '*%s%s',
        [IfThen(AParams[i] > 0, '+', '-'), Abs(AParams[i]), AXText, ps]);
    end
  else if (Length(AParams) >= 2) and (AParams[0] <> 0) and (AParams[1] <> 0) then
    case AEquation of
      feExp:
        Result += Format(' * exp(' + ANumFormat +' * %s)', [AParams[1], AXText]);
      fePower:
        Result += Format(' * %s^' + ANumFormat, [AXText, AParams[1]]);
    end;
end;

{ TFitSeriesRange }

constructor TFitSeriesRange.Create(ASeries: TFitSeries);
begin
  inherited Create(ASeries.ParentChart);
  FSeries := ASeries;
end;

procedure TFitSeriesRange.StyleChanged(ASender: TObject);
begin
  FSeries.ExecFit;
  inherited;
end;

{ TDrawFuncHelper }

procedure TDrawFuncHelper.CalcAt(
  AXg, AXa: Double; out APt: TDoublePoint; out AIn: Boolean);
begin
  APt := FMakeDP(AXg, FAxisToGraphYr(FCalc(AXa)));
  AIn := (FExtent.a <= APt) and (APt <= FExtent.b);
end;

procedure TDrawFuncHelper.CheckForNearestPoint(AXg, AXa: Double);
var
  inExtent: Boolean;
  gp: TDoublePoint;
  ip: TPoint;
  d: Integer;
begin
  CalcAt(AXg, AXa, gp, inExtent);
  if not inExtent then exit;
  ip := FChart.GraphToImage(gp);
  d := FNearestPointParams^.FDistFunc(FNearestPointParams^.FPoint, ip);
  if d >= FNearestPointResults^.FDist then exit;
  FNearestPointResults^.FDist := d;
  FNearestPointResults^.FImg := ip;
  FNearestPointResults^.FValue.X := AXa;
end;

constructor TDrawFuncHelper.Create(
  ASeries: TCustomChartSeries; ADomainExclusions: TIntervalList;
  ACalc: TTransformFunc; AStep: Integer);
begin
  FChart := ASeries.ParentChart;
  FExtent := FChart.CurrentExtent;
  FSeries := ASeries;
  FDomainExclusions := ADomainExclusions;
  FCalc := ACalc;

  with FSeries do
    if IsRotated then begin
      FAxisToGraphXr := @AxisToGraphY;
      FAxisToGraphYr := @AxisToGraphX;
      FGraphToAxisXr := @GraphToAxisY;
      FMakeDP := @DoublePointRotated;
      FGraphStep := FChart.YImageToGraph(-AStep) - FChart.YImageToGraph(0);
    end
    else begin
      FAxisToGraphXr := @AxisToGraphX;
      FAxisToGraphYr := @AxisToGraphY;
      FGraphToAxisXr := @GraphToAxisX;
      FMakeDP := @DoublePoint;
      FGraphStep := FChart.XImageToGraph(AStep) - FChart.XImageToGraph(0);
    end;
end;

procedure TDrawFuncHelper.DrawFunction(ADrawer: IChartDrawer);
var
  xg, xmax: Double;
begin
  FDrawer := ADrawer;
  with FSeries do
    if IsRotated then begin
      xg := FExtent.a.Y;
      xmax := FExtent.b.Y;
    end
    else begin
      xg := FExtent.a.X;
      xmax := FExtent.b.X;
    end;
  ForEachPoint(xg, xmax, @MoveTo, @LineTo);
end;

procedure TDrawFuncHelper.ForEachPoint(
  AXg, AXMax: Double; AOnMoveTo, AOnLineTo: TOnPoint);
var
  hint: Integer;
  xa, xg1, xa1: Double;
begin
  if FGraphStep = 0 then exit;

  hint := 0;
  xa := FGraphToAxisXr(AXg);
  if FDomainExclusions.Intersect(xa, xa, hint) then
    AXg := FAxisToGraphXr(xa);

  AOnMoveTo(AXg, xa);

  while AXg < AXMax do begin
    xg1 := AXg + FGraphStep;
    xa1 := FGraphToAxisXr(xg1);
    if FDomainExclusions.Intersect(xa, xa1, hint) then begin
      AOnLineTo(FAxisToGraphXr(xa), xa);
      xg1 := FAxisToGraphXr(xa1);
      AOnMoveTo(xg1, xa1);
    end
    else
      AOnLineTo(xg1, xa1);
    AXg := xg1;
    xa := xa1;
  end;
end;

function TDrawFuncHelper.GetNearestPoint(
  const AParams: TNearestPointParams;
  out AResults: TNearestPointResults): Boolean;
var
  xg, xmax: Double;
begin
  AResults.FIndex := -1;
  AResults.FDist := Sqr(AParams.FRadius) + 1;

  with AParams do
    if FSeries.IsRotated then begin
      xg := Max(FExtent.a.Y, FChart.YImageToGraph(FPoint.Y - FRadius));
      xmax := Min(FExtent.b.Y, FChart.YImageToGraph(FPoint.Y + FRadius));
    end
    else begin
      xg := Max(FExtent.a.X, FChart.XImageToGraph(FPoint.X - FRadius));
      xmax := Min(FExtent.b.X, FChart.XImageToGraph(FPoint.X + FRadius));
    end;

  FNearestPointParams := @AParams;
  FNearestPointResults := @AResults;
  ForEachPoint(xg, xmax, @CheckForNearestPoint, @CheckForNearestPoint);

  Result := AResults.FDist < Sqr(AParams.FRadius) + 1;
end;

procedure TDrawFuncHelper.LineTo(AXg, AXa: Double);
var
  p, t: TDoublePoint;
  inExtent: Boolean;
begin
  CalcAt(AXg, AXa, p, inExtent);
  t := p;
  if inExtent and FPrevInExtent then
    FDrawer.LineTo(FChart.GraphToImage(p))
  else if LineIntersectsRect(FPrev, t, FExtent) then begin
    FDrawer.MoveTo(FChart.GraphToImage(FPrev));
    FDrawer.LineTo(FChart.GraphToImage(t));
  end;
  FPrevInExtent := inExtent;
  FPrev := p;
end;

procedure TDrawFuncHelper.MoveTo(AXg, AXa: Double);
begin
  CalcAt(AXg, AXa, FPrev, FPrevInExtent);
  if FPrevInExtent then
    FDrawer.MoveTo(FChart.GraphToImage(FPrev));
end;

{ TBasicFuncSeries }

procedure TBasicFuncSeries.AfterAdd;
begin
  inherited AfterAdd;
  FExtent.SetOwner(FChart);
end;

procedure TBasicFuncSeries.Assign(ASource: TPersistent);
begin
  if ASource is TBasicFuncSeries then
    with TBasicFuncSeries(ASource) do
      Self.Extent := FExtent;
  inherited Assign(ASource);
end;

constructor TBasicFuncSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FExtent := TChartExtent.Create(FChart);
end;

destructor TBasicFuncSeries.Destroy;
begin
  FreeAndNil(FExtent);
  inherited Destroy;
end;

procedure TBasicFuncSeries.GetBounds(var ABounds: TDoubleRect);
begin
  with Extent do begin
    if UseXMin then ABounds.a.X := XMin;
    if UseYMin then ABounds.a.Y := YMin;
    if UseXMax then ABounds.b.X := XMax;
    if UseYMax then ABounds.b.Y := YMax;
  end;
end;

procedure TBasicFuncSeries.SetExtent(AValue: TChartExtent);
begin
  if FExtent = AValue then exit;
  FExtent.Assign(AValue);
  UpdateParentChart;
end;

{ TFuncSeries }

procedure TFuncSeries.Assign(ASource: TPersistent);
begin
  if ASource is TFuncSeries then
    with TFuncSeries(ASource) do begin
      Self.FDomainExclusions.Assign(FDomainExclusions);
      Self.FOnCalculate := FOnCalculate;
      Self.Pen := FPen;
      Self.FStep := FStep;
    end;
  inherited Assign(ASource);
end;

constructor TFuncSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDomainExclusions := TIntervalList.Create;
  FDomainExclusions.OnChange := @StyleChanged;
  FPen := TChartPen.Create;
  FPen.OnChange := @StyleChanged;
  FStep := DEF_FUNC_STEP;
end;

destructor TFuncSeries.Destroy;
begin
  FreeAndNil(FDomainExclusions);
  FreeAndNil(FPen);
  inherited;
end;

function TFuncSeries.DoCalcIdentity(AX: Double): Double;
begin
  Result := AX;
end;

function TFuncSeries.DoCalculate(AX: Double): Double;
begin
  OnCalculate(AX, Result)
end;

procedure TFuncSeries.Draw(ADrawer: IChartDrawer);
var
  calc: TTransformFunc;
begin
  if Assigned(OnCalculate) then
    calc := @DoCalculate
  else if csDesigning in ComponentState then
    calc := @DoCalcIdentity
  else
    exit;
  ADrawer.Pen := Pen;
  with TDrawFuncHelper.Create(Self, DomainExclusions, calc, Step) do
    try
      DrawFunction(ADrawer);
    finally
      Free;
    end;
end;

procedure TFuncSeries.GetLegendItems(AItems: TChartLegendItems);
begin
  AItems.Add(TLegendItemLine.Create(Pen, LegendTextSingle));
end;

function TFuncSeries.GetNearestPoint(
  const AParams: TNearestPointParams;
  out AResults: TNearestPointResults): Boolean;
begin
  Result := false;
  AResults.FIndex := -1;
  if not Assigned(OnCalculate) then exit;

  with TDrawFuncHelper.Create(Self, DomainExclusions, @DoCalculate, Step) do
    try
      Result := GetNearestPoint(AParams, AResults);
    finally
      Free;
    end;
end;

function TFuncSeries.IsEmpty: Boolean;
begin
  Result := not Assigned(OnCalculate);
end;

procedure TFuncSeries.SetOnCalculate(AValue: TFuncCalculateEvent);
begin
  if TMethod(FOnCalculate) = TMethod(AValue) then exit;
  FOnCalculate := AValue;
  UpdateParentChart;
end;

procedure TFuncSeries.SetPen(AValue: TChartPen);
begin
  if FPen = AValue then exit;
  FPen.Assign(AValue);
  UpdateParentChart;
end;

procedure TFuncSeries.SetStep(AValue: TFuncSeriesStep);
begin
  if FStep = AValue then exit;
  FStep := AValue;
  UpdateParentChart;
end;

{ TBSplineSeries }

procedure TBSplineSeries.Assign(ASource: TPersistent);
begin
  if ASource is TBSplineSeries then
    with TBSplineSeries(ASource) do begin
      Self.FDegree := FDegree;
      Self.Pen := FPen;
      Self.FStep := FStep;
    end;
  inherited Assign(ASource);
end;

constructor TBSplineSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDegree := DEF_SPLINE_DEGREE;
  FPen := TChartPen.Create;
  FPen.OnChange := @StyleChanged;
  FPointer := TSeriesPointer.Create(ParentChart);
  FStep := DEF_SPLINE_STEP;
end;

destructor TBSplineSeries.Destroy;
begin
  FreeAndNil(FPen);
  inherited;
end;

procedure TBSplineSeries.Draw(ADrawer: IChartDrawer);
var
  p: array of TDoublePoint;
  startIndex: Integer;

  function SplinePoint(APos: Double): TPoint;
  var
    i, d: Integer;
    w, denom: Double;
  begin
    // Duplicate end points Degree times to fix spline to them.
    for i := 0 to Degree do
      p[i] := FGraphPoints[
        EnsureRange(startIndex - Degree + i, 0, High(FGraphPoints))];
    // De Boor's algorithm, source points used as control points.
    // Parametric coordinate is equal to point index.
    for d := 1 to Degree do begin
      denom := 1 / (Degree + 1 - d);
      for i := Degree downto d do begin
        w := (APos + Degree - i) * denom;
        p[i].X := WeightedAverage(p[i - 1].X, p[i].X, w);
        p[i].Y := WeightedAverage(p[i - 1].Y, p[i].Y, w);
      end;
    end;
    Result := ParentChart.GraphToImage(p[Degree]);
  end;

var
  level: Integer = 0;

  // Pass screen coordinates down to calculate them only once for each point.
  procedure SplineSegment(AL, AR: Double; const APL, APR: TPoint);
  const
    INF_SENTINEL = 15; // Arbitrary guard against infinite recursion.
  var
    m: Double;
    pm: TPoint;
  begin
    if (level > INF_SENTINEL) or (PointDist(APL, APR) <= Sqr(Step)) then
      // Left-then-right recursive call order guarantees that
      // the last drawn segment is the immediately preceding one.
      ADrawer.LineTo(APR)
    else begin
      m := (AL + AR) / 2;
      pm := SplinePoint(m);
      level += 1;
      SplineSegment(AL, m, APL, pm);
      SplineSegment(m, AR, pm, APR);
      level -= 1;
    end;
  end;

var
  ext: TDoubleRect;
begin
  if IsEmpty then exit;

  with Extent do begin
    ext.a := AxisToGraph(a);
    ext.b := AxisToGraph(b);
  end;
  NormalizeRect(ext);
  ExpandRange(ext.a.X, ext.b.X, 1.0);
  ExpandRange(ext.a.Y, ext.b.Y, 1.0);
  PrepareGraphPoints(ext, true);

  SetLength(p, Degree + 1);
  ADrawer.Pen := Pen;
  ADrawer.MoveTo(ParentChart.GraphToImage(FGraphPoints[0]));
  for startIndex := 0 to High(FGraphPoints) + Degree - 1 do
    SplineSegment(0.0, 1.0, SplinePoint(0.0), SplinePoint(1.0));
  DrawLabels(ADrawer);
  DrawPointers(ADrawer);
end;

procedure TBSplineSeries.GetLegendItems(AItems: TChartLegendItems);
begin
  AItems.Add(TLegendItemLine.Create(Pen, LegendTextSingle));
end;

procedure TBSplineSeries.SetDegree(AValue: TSplineDegree);
begin
  if FDegree = AValue then exit;
  FDegree := AValue;
  UpdateParentChart;
end;

procedure TBSplineSeries.SetPen(AValue: TChartPen);
begin
  if FPen = AValue then exit;
  FPen.Assign(AValue);
  UpdateParentChart;
end;

procedure TBSplineSeries.SetStep(AValue: TFuncSeriesStep);
begin
  if FStep = AValue then exit;
  FStep := AValue;
  UpdateParentChart;
end;

{ TCubicSplineSeries }

procedure TCubicSplineSeries.Assign(ASource: TPersistent);
begin
  if ASource is TCubicSplineSeries then
    with TCubicSplineSeries(ASource) do begin
      Self.Pen := FPen;
      Self.FStep := FStep;
    end;
  inherited Assign(ASource);
end;

function TCubicSplineSeries.Calculate(AX: Double): Double;
var
  ok: Integer = 0;
begin
  Result := ipfspn(High(FCoeff), FX[0], FY[0], FCoeff[0], AX, ok);
  if ok > 1 then
    Result := SafeNaN;
end;

constructor TCubicSplineSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBadDataPen := TBadDataChartPen.Create;
  FBadDataPen.OnChange := @StyleChanged;
  FPen := TChartPen.Create;
  FPen.OnChange := @StyleChanged;
  FPointer := TSeriesPointer.Create(ParentChart);
  FStep := DEF_SPLINE_STEP;
  FUseReticule := true;
end;

destructor TCubicSplineSeries.Destroy;
begin
  FreeAndNil(FBadDataPen);
  FreeAndNil(FPen);
  inherited;
end;

procedure TCubicSplineSeries.Draw(ADrawer: IChartDrawer);

  function DrawFewPoints: Boolean;
  const
    MIN_SPLINE_POINTS = 4;
  var
    pts: TPointArray;
    i: Integer;
  begin
    Result := Length(FX) < MIN_SPLINE_POINTS;
    if
      not Result or not (csoDrawFewPoints in Options) or not BadDataPen.Visible
    then
      exit;
    SetLength(pts, Length(FGraphPoints));
    for i := 0 to High(FGraphPoints) do
      pts[i] := ParentChart.GraphToImage(FGraphPoints[i]);
    ADrawer.Pen := BadDataPen;
    ADrawer.Polyline(pts, 0, Length(pts));
  end;

  procedure DrawSpline;
  var
    de: TIntervalList;
    p: TChartPen;
  begin
    if FCoeff = nil then exit;
    if FUnorderedX then begin
      if csoDrawUnorderedX in Options then
        p := BadDataPen
      else
        exit;
    end
    else
      p := Pen;
    if not p.Visible then exit;
    ADrawer.Pen := p;
    de := PrepareIntervals;
    try
      with TDrawFuncHelper.Create(Self, de, @Calculate, Step) do
        try
          DrawFunction(ADrawer);
        finally
          Free;
        end;
    finally
      de.Free;
    end;
  end;

begin
  if IsEmpty then exit;
  if FCoeff = nil then
    PrepareCoeffs;

  PrepareGraphPoints(FChart.CurrentExtent, true);
  if not DrawFewPoints then
    DrawSpline;

  DrawLabels(ADrawer);
  DrawPointers(ADrawer);
end;

function TCubicSplineSeries.Extent: TDoubleRect;
var
  r: Integer = 0;
  minv, maxv: ArbFloat;
begin
  Result := inherited Extent;
  if FCoeff = nil then
    PrepareCoeffs;
  if FCoeff = nil then exit;
  minv := Result.a.Y;
  maxv := Result.b.Y;
  ipfsmm(High(FCoeff), FX[0], FY[0], FCoeff[0], minv, maxv, r);
  Result.a.Y := minv;
  Result.b.Y := maxv;
end;

procedure TCubicSplineSeries.GetLegendItems(AItems: TChartLegendItems);
begin
  AItems.Add(TLegendItemLine.Create(Pen, LegendTextSingle));
end;

function TCubicSplineSeries.GetNearestPoint(
  const AParams: TNearestPointParams;
  out AResults: TNearestPointResults): Boolean;
var
  de: TIntervalList;
begin
  if FUnorderedX and not (csoDrawUnorderedX in Options) then
    exit(false);
  de := PrepareIntervals;
  try
    with TDrawFuncHelper.Create(Self, de, @Calculate, Step) do
      try
        Result := GetNearestPoint(AParams, AResults);
      finally
        Free;
      end;
  finally
    de.Free;
  end;
end;

procedure TCubicSplineSeries.PrepareCoeffs;
var
  i, n: Integer;
begin
  n := Source.Count;
  SetLength(FX, n);
  SetLength(FY, n);
  SetLength(FCoeff, n);
  FUnorderedX := false;
  n := 0;
  for i := 0 to Source.Count - 1 do
    with Source[i]^ do
      if (i > 0) and (FX[n - 1] >= X) then
        FUnorderedX := true
      else begin
        FX[n] := X;
        FY[n] := Y;
        n += 1;
      end;
  SetLength(FX, n);
  SetLength(FY, n);
  SetLength(FCoeff, n);
  ipfisn(n - 1, FX[0], FY[0], FCoeff[0], i);
  if i > 1 then
    FCoeff := nil;
end;

function TCubicSplineSeries.PrepareIntervals: TIntervalList;
begin
  Result := TIntervalList.Create;
  try
    if not (csoExtrapolateLeft in Options) then
      Result.AddRange(NegInfinity, FX[0]);
    if not (csoExtrapolateRight in Options) then
      Result.AddRange(FX[High(FX)], SafeInfinity);
  except
    Result.Free;
    raise;
  end;
end;

procedure TCubicSplineSeries.SetBadDataPen(AValue: TBadDataChartPen);
begin
  if FBadDataPen = AValue then exit;
  FBadDataPen.Assign(AValue);
  UpdateParentChart;
end;

procedure TCubicSplineSeries.SetOptions(AValue: TCubicSplineOptions);
begin
  if FOptions = AValue then exit;
  FOptions := AValue;
  FCoeff := nil;
  UpdateParentChart;
end;

procedure TCubicSplineSeries.SetPen(AValue: TChartPen);
begin
  if FPen = AValue then exit;
  FPen.Assign(AValue);
  UpdateParentChart;
end;

procedure TCubicSplineSeries.SetStep(AValue: TFuncSeriesStep);
begin
  if FStep = AValue then exit;
  FStep := AValue;
  UpdateParentChart;
end;

procedure TCubicSplineSeries.SourceChanged(ASender: TObject);
begin
  inherited SourceChanged(ASender);
  FCoeff := nil;
end;

{ TFitSeries }

procedure TFitSeries.AfterAdd;
begin
  inherited AfterAdd;
  FFitRange.SetOwner(ParentChart);
end;

function TFitSeries.Calculate(AX: Double): Double;
var
  i: Integer;
begin
  if IsInfinite(AX) then exit(AX);
  Result := SafeNaN;
  if IsNaN(AX) or not FValidFitParams then exit;

  case FFitEquation of
    fePolynomial, feLinear:
      begin
        Result := 0;
        for i := High(FFitParams) downto 0 do
          Result := Result * AX + FFitParams[i];
      end;
    feExp:
      Result := FFitParams[0] * Exp(FFitParams[1] * AX);
    fePower:
      if AX < 0 then
        Result := SafeNaN
      else
        Result := FFitParams[0] * Power(AX, FFitParams[1]);
  end;
end;

procedure TFitSeries.CalcXRange(out AXMin, AXMax: Double);
var
  ext: TDoubleRect;
begin
  with Extent do begin
    ext.a := AxisToGraph(a);
    ext.b := AxisToGraph(b);
  end;
  NormalizeRect(ext);
  AXMin := GraphToAxisX(ext.a.X);
  AXMax := GraphToAxisX(ext.b.X);
  EnsureOrder(AXMin, AXMax);
  FFitRange.Intersect(AXMin, AXMax);
end;

constructor TFitSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFitEquation := fePolynomial;
  FFitRange := TFitSeriesRange.Create(Self);
  FDrawFitRangeOnly := true;
  FPen := TChartPen.Create;
  FPen.OnChange := @StyleChanged;
  FStep := DEF_FIT_STEP;
  ParamCount := DEF_FIT_PARAM_COUNT; // Parabolic fit as default.
end;

destructor TFitSeries.Destroy;
begin
  FreeAndNil(FPen);
  FreeAndNil(FFitRange);
  inherited;
end;

procedure TFitSeries.Draw(ADrawer: IChartDrawer);
var
  de : TIntervalList;
begin
  if IsEmpty then exit;
  ADrawer.Pen := Pen;
  de := PrepareIntervals;
  try
    with TDrawFuncHelper.Create(Self, de, @Calculate, Step) do
      try
        DrawFunction(ADrawer);
      finally
        Free;
      end;
  finally
    de.Free;
  end;
end;

procedure TFitSeries.ExecFit;
var
  i, j, term, ns, np, n: Integer;
  xmin, xmax: Double;
  xv, yv, fp: array of ArbFloat;

  function IsValidPoint(AX, AY: Double): Boolean; inline;
  begin
    Result := not IsNaN(AX) and not IsNaN(AY) and InRange(AX, xmin, xmax);
  end;

begin
  FValidFitParams := false;

  np := ParamCount;
  ns := Source.Count;
  if (np <= 0) or (ns = 0) or (ns < np) then exit;
  CalcXRange(xmin, xmax);

  n := 0;
  for i := 0 to ns - 1 do
    with Source.Item[i]^ do
      n += Ord(IsValidPoint(X, Y));
  if n < np then exit;

  // Copy data in fit range to temporary arrays.
  SetLength(xv, n);
  SetLength(yv, n);
  j := 0;
  for i := 0 to ns - 1 do
    with Source.Item[i]^ do
      if IsValidPoint(X, Y) then begin
        Transform(X, Y, xv[j], yv[j]);
        j += 1;
      end;

  // Execute the polynomial fit; the degree of the polynomial is np - 1.
  SetLength(fp, np);
  term := 0;
  ipfpol(n, np - 1, xv[0], yv[0], fp[0], term);
  if term <> 1 then exit;
  for i := 0 to High(FFitParams) do
    FFitParams[i] := fp[i];

  // See comment for "Transform": for exponential and power fit equations, the
  // first fitted parameter is the logarithm of the "real" parameter. It needs
  // to be transformed back to real units by exp function.
  if FFitEquation in [feExp, fePower] then
    FFitParams[0] := Exp(FFitParams[0]);
  FValidFitParams := true;
  if Assigned(FOnFitComplete) then
    FOnFitComplete(Self);
  UpdateParentChart;
end;

function TFitSeries.GetFitEquationString(
  ANumFormat, AXText, AYText: String): String;
begin
  Result := ParamsToEquation(FFitEquation, FFitParams, ANumFormat, AXText, AYText);
end;

procedure TFitSeries.GetLegendItems(AItems: TChartLegendItems);
var
  t: String;
begin
  if Legend.Format = '' then
    t := Title
  else
    t := Format(Legend.Format, [Title, Index, GetFitEquationString('%f')]);
  AItems.Add(TLegendItemLine.Create(Pen, t));
end;

function TFitSeries.GetNearestPoint(
  const AParams: TNearestPointParams; out AResults: TNearestPointResults): Boolean;
var
  de : TIntervalList;
begin
  Result := false;
  AResults.FIndex := -1;
  de := PrepareIntervals;
  try
    with TDrawFuncHelper.Create(Self, de, @Calculate, Step) do
      try
        Result := GetNearestPoint(AParams, AResults);
      finally
        Free;
      end;
  finally
    de.Free;
  end;
end;

function TFitSeries.GetParam(AIndex: Integer): Double;
begin
  if not InRange(AIndex, 0, ParamCount - 1) then
    raise EChartError.Create('TFitSeries.GetParam index out of range');
  Result := FFitParams[AIndex]
end;

function TFitSeries.GetParamCount: Integer;
begin
  Result := Length(FFitParams);
end;

function TFitSeries.PrepareIntervals: TIntervalList;
var
  xmin, xmax: Double;
begin
  Result := TIntervalList.Create;
  try
    CalcXRange(xmin, xmax);
    if DrawFitRangeOnly then begin
      Result.AddRange(NegInfinity, xmin);
      Result.AddRange(xmax, SafeInfinity);
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TFitSeries.SetDrawFitRangeOnly(AValue: Boolean);
begin
  if FDrawFitRangeOnly = AValue then exit;
  FDrawFitRangeOnly := AValue;
  UpdateParentChart;
end;

procedure TFitSeries.SetFitEquation(AValue: TFitEquation);
begin
  if FFitEquation = AValue then exit;
  FFitEquation := AValue;
  SetLength(
    FFitParams, IfThen(FFitEquation = fePolynomial, DEF_FIT_PARAM_COUNT, 2));
  ExecFit;
end;

procedure TFitSeries.SetFitRange(AValue: TChartRange);
begin
  if FFitRange = AValue then exit;
  FFitRange := AValue;
  ExecFit;
end;

procedure TFitSeries.SetParam(AIndex: Integer; AValue: Double);
begin
  if not InRange(AIndex, 0, ParamCount - 1) then
    raise EChartError.Create('TFitSeries.SetParam index out of range');
  FFitParams[AIndex] := AValue;
  UpdateParentChart;
end;

procedure TFitSeries.SetParamCount(AValue: Integer);
begin
  if (AValue = ParamCount) or (FFitEquation <> fePolynomial) then exit;
  SetLength(FFitParams, AValue);
  ExecFit;
end;

procedure TFitSeries.SetPen(AValue: TChartPen);
begin
  if FPen = AValue then exit;
  FPen.Assign(AValue);
  UpdateParentChart;
end;

procedure TFitSeries.SetStep(AValue: TFuncSeriesStep);
begin
  if FStep = AValue then exit;
  FStep := AValue;
  UpdateParentChart;
end;

procedure TFitSeries.SourceChanged(ASender: TObject);
begin
  inherited;
  ExecFit;
end;

procedure TFitSeries.Transform(AX, AY: Double; out ANewX, ANewY: Extended);
begin
  // The exponential and power fitting equations can be transformed to a
  // polynomial by taking the logarithm:
  // feExp:   y = a exp(b*x) ==> ln(y) = ln(a) + b*x
  // fePower: y = a*x^b      ==> ln(y) = ln(a) + b*ln(x)
  // In each case, the first parameter (a) needs to be transformed back
  // after the fitting -- see "ExecFit".
  if FitEquation in [fePower] then
    ANewX := Ln(AX)
  else
    ANewX := AX;
  if FitEquation in [feExp, fePower] then
    ANewY := Ln(AY)
  else
    ANewY := AY;
end;

{ TColorMapSeries }

procedure TColorMapSeries.Assign(ASource: TPersistent);
begin
  if ASource is TColorMapSeries then
    with TColorMapSeries(ASource) do begin
      Self.Brush := FBrush;
      Self.ColorSource := FColorSource;
      Self.FInterpolate := FInterpolate;
      Self.FOnCalculate := FOnCalculate;
      Self.FStepX := FStepX;
      Self.FStepY := FStepY;
    end;
  inherited Assign(ASource);
end;

function TColorMapSeries.ColorByValue(AValue: Double): TColor;
var
  lb, ub: Integer;
  c1, c2: TColor;
  v1, v2: Double;
begin
  if ColorSource = nil then exit(clTAColor);
  ColorSource.FindBounds(AValue, SafeInfinity, lb, ub);
  if Interpolate and InRange(lb, 1, ColorSource.Count - 1) then begin
    with ColorSource[lb - 1]^ do begin
      v1 := X;
      c1 := Color;
    end;
    with ColorSource[lb]^ do begin
      v2 := X;
      c2 := Color;
    end;
    if v2 <= v1 then
      Result := c1
    else
      Result := InterpolateRGB(c1, c2, (AValue - v1) / (v2 - v1));
  end
  else
    Result := ColorSource[EnsureRange(lb, 0, ColorSource.Count - 1)]^.Color;
end;

constructor TColorMapSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColorSourceListener := TListener.Create(@FColorSource, @StyleChanged);
  FBrush := TBrush.Create;
  FBrush.OnChange := @StyleChanged;
  FStepX := DEF_COLORMAP_STEP;
  FStepY := DEF_COLORMAP_STEP;
end;

destructor TColorMapSeries.Destroy;
begin
  FreeAndNil(FColorSourceListener);
  FreeAndNil(FBrush);
  inherited Destroy;
end;

procedure TColorMapSeries.Draw(ADrawer: IChartDrawer);
var
  ext: TDoubleRect;
  bounds: TDoubleRect;
  r: TRect;
  pt, next, offset: TPoint;
  gp: TDoublePoint;
  v: Double;
begin
  if not (csDesigning in ComponentState) and IsEmpty then exit;

  ext := ParentChart.CurrentExtent;
  bounds := EmptyExtent;
  GetBounds(bounds);
  bounds.a := AxisToGraph(bounds.a);
  bounds.b := AxisToGraph(bounds.b);
  if not RectIntersectsRect(ext, bounds) then exit;

  r.TopLeft := ParentChart.GraphToImage(ext.a);
  r.BottomRight := ParentChart.GraphToImage(ext.b);
  NormalizeRect(r);
  offset := ParentChart.GraphToImage(ZeroDoublePoint);

  ADrawer.Brush := Brush;
  ADrawer.SetPenParams(psClear, clTAColor);
  pt.Y := (r.Top div StepY - 1) * StepY + offset.Y mod StepY;
  while pt.Y <= r.Bottom do begin
    next.Y := pt.Y + StepY;
    if next.Y <= r.Top then begin
      pt.Y := next.Y;
      continue;
    end;
    pt.X := (r.Left div StepX  - 1) * StepX + offset.X mod StepX;
    while pt.X <= r.Right do begin
      next.X := pt.X + StepX;
      if next.X <= r.Left then begin
        pt.X := next.X;
        continue;
      end;
      gp := GraphToAxis(ParentChart.ImageToGraph((pt + next) div 2));
      if not (csDesigning in ComponentState) then
        OnCalculate(gp.X, gp.Y, v);
      if ColorSource <> nil then
        ADrawer.BrushColor := ColorByValue(v);
      ADrawer.Rectangle(
        Max(pt.X, r.Left), Max(pt.Y, r.Top),
        Min(next.X, r.Right) + 1, Min(next.Y, r.Bottom) + 1);
      pt.X := next.X;
    end;
    pt.Y := next.Y;
  end;
end;

procedure TColorMapSeries.GetLegendItems(AItems: TChartLegendItems);
var
  i: Integer;
  prev: Double;

  function ItemTitle(const AText: String; AX: Double): String;
  const
    FORMATS: array [1..3] of String = ('z ≤ %1:g', '%g < z ≤ %g', '%g < z');
  var
    idx: Integer;
  begin
    if AText <> '' then exit(AText);
    if ColorSource.Count = 1 then exit('');
    if i = 0 then idx := 1
    else if i = ColorSource.Count - 1 then idx := 3
    else idx := 2;
    Result := Format(FORMATS[idx], [prev, AX]);
  end;

var
  li: TLegendItemBrushRect;
begin
  case Legend.Multiplicity of
    lmSingle: AItems.Add(TLegendItemBrushRect.Create(Brush, LegendTextSingle));
    lmPoint:
      if ColorSource <> nil then begin
        prev := 0.0;
        for i := 0 to ColorSource.Count - 1 do
          with ColorSource[i]^ do begin
            li := TLegendItemBrushRect.Create(Brush, ItemTitle(Text, X));
            li.Color := Color;
            AItems.Add(li);
            prev := X;
          end;
      end;
  end;
end;

function TColorMapSeries.IsEmpty: Boolean;
begin
  Result := not Assigned(OnCalculate);
end;

procedure TColorMapSeries.SetBrush(AValue: TBrush);
begin
  if FBrush = AValue then exit;
  FBrush := AValue;
  UpdateParentChart;
end;

procedure TColorMapSeries.SetColorSource(AValue: TCustomChartSource);
begin
  if FColorSource = AValue then exit;
  if FColorSourceListener.IsListening then
    ColorSource.Broadcaster.Unsubscribe(FColorSourceListener);
  FColorSource := AValue;
  if ColorSource <> nil then
    ColorSource.Broadcaster.Subscribe(FColorSourceListener);
  UpdateParentChart;
end;

procedure TColorMapSeries.SetInterpolate(AValue: Boolean);
begin
  if FInterpolate = AValue then exit;
  FInterpolate := AValue;
  UpdateParentChart;
end;

procedure TColorMapSeries.SetOnCalculate(AValue: TFuncCalculate3DEvent);
begin
  if TMethod(FOnCalculate) = TMethod(AValue) then exit;
  FOnCalculate := AValue;
  UpdateParentChart;
end;

procedure TColorMapSeries.SetStepX(AValue: TFuncSeriesStep);
begin
  if FStepX = AValue then exit;
  FStepX := AValue;
  UpdateParentChart;
end;

procedure TColorMapSeries.SetStepY(AValue: TFuncSeriesStep);
begin
  if FStepY = AValue then exit;
  FStepY := AValue;
  UpdateParentChart;
end;

initialization
  RegisterSeriesClass(TFuncSeries, 'Function series');
  RegisterSeriesClass(TBSplineSeries, 'B-Spline series');
  RegisterSeriesClass(TCubicSplineSeries, 'Cubic spline series');
  RegisterSeriesClass(TFitSeries, 'Least-squares fit series');
  RegisterSeriesClass(TColorMapSeries, 'Color map series');

end.

