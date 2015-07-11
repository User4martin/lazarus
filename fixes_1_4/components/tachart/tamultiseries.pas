{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Authors: Alexander Klenin

}

unit TAMultiSeries;

{$H+}

interface

uses
  Classes, Graphics,
  TAChartUtils, TACustomSeries, TADrawUtils, TALegend;

const
  DEF_BOX_WIDTH = 50;
  DEF_WHISKERS_WIDTH = 25;
  DEF_OHLC_TICK_WIDTH = 25;
  DEF_YINDEX_OPEN = 1;
  DEF_YINDEX_HIGH = 3;
  DEF_YINDEX_LOW = 0;
  DEF_YINDEX_CLOSE = 2;

type

  TBubbleRadiusTransform = (brtNone, brtX, brtY);
  TBubbleOverrideColor = (bocBrush, bocPen);
  TBubbleOverrideColors = set of TBubbleOverrideColor;

  { TBubbleSeries }

  TBubbleSeries = class(TBasicPointSeries)
  private
    FBubbleBrush: TBrush;
    FBubblePen: TPen;
    FOverrideColor: TBubbleOverrideColors;
    procedure SetBubbleBrush(AValue: TBrush);
    procedure SetBubblePen(AValue: TPen);
    procedure SetOverrideColor(AValue: TBubbleOverrideColors);
  protected
    procedure GetLegendItems(AItems: TChartLegendItems); override;
    function GetSeriesColor: TColor; override;
  public
    function AddXY(AX, AY, ARadius: Double; AXLabel: String = '';
      AColor: TColor = clTAColor): Integer; overload;
    procedure Assign(ASource: TPersistent); override;
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    procedure Draw(ADrawer: IChartDrawer); override;
    function Extent: TDoubleRect; override;
  published
    property AxisIndexX;
    property AxisIndexY;
    property BubbleBrush: TBrush read FBubbleBrush write SetBubbleBrush;
    property BubblePen: TPen read FBubblePen write SetBubblePen;
    property OverrideColor: TBubbleOverrideColors
      read FOverrideColor write SetOverrideColor default [];
    property Source;
  end;

  TBoxAndWhiskerSeriesLegendDir = (bwlHorizontal, bwlVertical, bwlAuto);
  TBoxAndWhiskerSeriesWidthStyle = (bwsPercent, bwsPercentMin);

  TBoxAndWhiskerSeries = class(TBasicPointSeries)
  strict private
    FBoxBrush: TBrush;
    FBoxPen: TPen;
    FBoxWidth: Integer;
    FLegendDirection: TBoxAndWhiskerSeriesLegendDir;
    FMedianPen: TPen;
    FWhiskersPen: TPen;
    FWhiskersWidth: Integer;
    FWidthStyle: TBoxAndWhiskerSeriesWidthStyle;
    procedure SetBoxBrush(AValue: TBrush);
    procedure SetBoxPen(AValue: TPen);
    procedure SetBoxWidth(AValue: Integer);
    procedure SetLegendDirection(AValue: TBoxAndWhiskerSeriesLegendDir);
    procedure SetMedianPen(AValue: TPen);
    procedure SetWhiskersPen(AValue: TPen);
    procedure SetWhiskersWidth(AValue: Integer);
  protected
    procedure GetLegendItems(AItems: TChartLegendItems); override;
    function GetSeriesColor: TColor; override;
  public
    function AddXY(
      AX, AYLoWhisker, AYLoBox, AY, AYHiBox, AYHiWhisker: Double;
      AXLabel: String = ''; AColor: TColor = clTAColor): Integer; overload;
    procedure Assign(ASource: TPersistent); override;
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Draw(ADrawer: IChartDrawer); override;
    function Extent: TDoubleRect; override;
  published
    property BoxBrush: TBrush read FBoxBrush write SetBoxBrush;
    property BoxPen: TPen read FBoxPen write SetBoxPen;
    property BoxWidth: Integer
      read FBoxWidth write SetBoxWidth default DEF_BOX_WIDTH;
    property LegendDirection: TBoxAndWhiskerSeriesLegendDir
      read FLegendDirection write SetLegendDirection default bwlHorizontal;
    property MedianPen: TPen read FMedianPen write SetMedianPen;
    property WidthStyle: TBoxAndWhiskerSeriesWidthStyle
      read FWidthStyle write FWidthStyle default bwsPercent;
    property WhiskersPen: TPen read FWhiskersPen write SetWhiskersPen;
    property WhiskersWidth: Integer
      read FWhiskersWidth write SetWhiskersWidth default DEF_WHISKERS_WIDTH;
  published
    property AxisIndexX;
    property AxisIndexY;
    property Source;
  end;

  TOHLCDownPen = class(TPen)
  published
    property Color default clTAColor;
  end;

  TOHLCMode = (mOHLC, mCandleStick);

  TOpenHighLowCloseSeries = class(TBasicPointSeries)
  private
    FCandlestickDownBrush: TBrush;
    FCandleStickLinePen: TPen;
    FCandlestickUpBrush: TBrush;
    FDownLinePen: TOHLCDownPen;
    FLinePen: TPen;
    FTickWidth: Cardinal;
    FYIndexClose: Cardinal;
    FYIndexHigh: Cardinal;
    FYIndexLow: Cardinal;
    FYIndexOpen: Cardinal;
    FMode: TOHLCMode;
    procedure SetCandlestickLinePen(AValue: TPen);
    procedure SetCandlestickDownBrush(AValue: TBrush);
    procedure SetCandlestickUpBrush(AValue: TBrush);
    procedure SetDownLinePen(AValue: TOHLCDownPen);
    procedure SetLinePen(AValue: TPen);
    procedure SetOHLCMode(AValue: TOHLCMode);
    procedure SetTickWidth(AValue: Cardinal);
    procedure SetYIndexClose(AValue: Cardinal);
    procedure SetYIndexHigh(AValue: Cardinal);
    procedure SetYIndexLow(AValue: Cardinal);
    procedure SetYIndexOpen(AValue: Cardinal);
  protected
    procedure GetLegendItems(AItems: TChartLegendItems); override;
    function GetSeriesColor: TColor; override;
  public
    procedure Assign(ASource: TPersistent); override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddXOHLC(
      AX, AOpen, AHigh, ALow, AClose: Double;
      ALabel: String = ''; AColor: TColor = clTAColor): Integer; inline;
    procedure Draw(ADrawer: IChartDrawer); override;
    function Extent: TDoubleRect; override;
  published
    property CandlestickDownBrush: TBrush
      read FCandlestickDownBrush write SetCandlestickDownBrush;
    property CandlestickLinePen: TPen
      read FCandlestickLinePen write FCandleStickLinePen;
    property CandlestickUpBrush: TBrush
      read FCandlestickUpBrush write SetCandlestickUpBrush;
    property DownLinePen: TOHLCDownPen read FDownLinePen write SetDownLinePen;
    property LinePen: TPen read FLinePen write SetLinePen;
    property Mode: TOHLCMode read FMode write SetOHLCMode;
    property TickWidth: Cardinal
      read FTickWidth write SetTickWidth default DEF_OHLC_TICK_WIDTH;
    property YIndexClose: Cardinal
      read FYIndexClose write SetYIndexClose default DEF_YINDEX_CLOSE;
    property YIndexHigh: Cardinal
      read FYIndexHigh write SetYIndexHigh default DEF_YINDEX_HIGH;
    property YIndexLow: Cardinal
      read FYIndexLow write SetYIndexLow default DEF_YINDEX_LOW;
    property YIndexOpen: Cardinal
      read FYIndexOpen write SetYIndexOpen default DEF_YINDEX_OPEN;
  published
    property AxisIndexX;
    property AxisIndexY;
    property Source;
  end;


implementation

uses
  FPCanvas, Math, SysUtils, TACustomSource, TAGeometry, TAGraph, TAMath;

type

  TLegendItemOHLCLine = class(TLegendItemLine)
  strict private
    FMode: TOHLCMode;
    FCandleStickUpColor: TColor;
    FCandleStickDownColor: TColor;
  public
    constructor Create(ASeries: TOpenHighLowCloseSeries; const AText: String);
    procedure Draw(ADrawer: IChartDrawer; const ARect: TRect); override;
  end;

  TLegendItemBoxAndWhiskers = class(TLegendItem)
  strict private
    FBoxBrush: TBrush;
    FBoxPen: TPen;
    FBoxWidth: Integer;
    FIsVertical: Boolean;
    FMedianPen: TPen;
    FWhiskersPen: TPen;
    FWhiskersWidth: Integer;
  public
    constructor Create(ASeries: TBoxAndWhiskerSeries; const AText: String);
    procedure Draw(ADrawer: IChartDrawer; const ARect: TRect); override;
  end;

{ TLegendItemOHLCLine }

constructor TLegendItemOHLCLine.Create(ASeries: TOpenHighLowCloseSeries; const AText: String);
var
  pen: TFPCustomPen;
begin
  case ASeries.Mode of
    mOHLC        : pen := ASeries.LinePen;
    mCandleStick : pen := ASeries.CandleStickLinePen;
  end;
  inherited Create(pen, AText);
  FMode := ASeries.Mode;
  FCandlestickUpColor := ASeries.CandlestickUpBrush.Color;
  FCandlestickDownColor := ASeries.CandlestickDownBrush.Color;
end;

procedure TLegendItemOHLCLine.Draw(ADrawer: IChartDrawer; const ARect: TRect);
const
  TICK_LENGTH = 3;
var
  dx, dy, x, y: Integer;
  pts: array[0..3] of TPoint;
begin
  inherited Draw(ADrawer, ARect);
  y := (ARect.Top + ARect.Bottom) div 2;
  dx := (ARect.Right - ARect.Left) div 3;
  x := ARect.Left + dx;
  case FMode of
    mOHLC:
      begin
        dy := ADrawer.Scale(TICK_LENGTH);
        ADrawer.Line(x, y, x, y + dy);
        x += dx;
        ADrawer.Line(x, y, x, y - dy);
      end;
    mCandlestick:
      begin
        dy := (ARect.Bottom - ARect.Top) div 4;
        pts[0] := Point(x, y-dy);
        pts[1] := Point(x, y+dy);
        pts[2] := Point(x+dx, y+dy);
        pts[3] := pts[0];
        ADrawer.SetBrushParams(bsSolid, FCandlestickUpColor);
        ADrawer.Polygon(pts, 0, 4);
        pts[0] := Point(x+dx, y+dy);
        pts[1] := Point(x+dx, y-dy);
        pts[2] := Point(x, y-dy);
        pts[3] := pts[0];
        ADrawer.SetBrushParams(bsSolid, FCandlestickDownColor);
        ADrawer.Polygon(pts, 0, 4);
      end;
  end;
end;

{ TLegendItemBoxAndWhiskers }

constructor TLegendItemBoxAndWhiskers.Create(
  ASeries: TBoxAndWhiskerSeries; const AText: String);
begin
  inherited Create(AText);
  with ASeries do begin
    FBoxBrush := BoxBrush;
    FBoxPen := BoxPen;
    FBoxWidth := BoxWidth;
    FIsVertical :=
      (LegendDirection = bwlVertical) or
      (LegendDirection = bwlAuto) and IsRotated;
    FMedianPen := MedianPen;
    FWhiskersPen := WhiskersPen;
    FWhiskersWidth := WhiskersWidth;
  end;
end;

procedure TLegendItemBoxAndWhiskers.Draw(
  ADrawer: IChartDrawer; const ARect: TRect);

  function FlipRect(const AR: TRect): TRect;
  begin
    Result := Rect(AR.Top, AR.Left, AR.Bottom, AR.Right);
  end;

var
  symbol: array [1..5] of TRect;
var
  center: TPoint;
  i, m, ww, bw: Integer;
  r: TRect;
begin
  inherited Draw(ADrawer, ARect);
  r := ARect;
  r.BottomRight -= Point(1, 1);
  if FIsVertical then
    r := FlipRect(r);

  center := (r.TopLeft + r.BottomRight) div 2;
  m := MaxValue([FWhiskersWidth, FBoxWidth, 1]) * 2;
  ww := (r.Bottom - r.Top) * FWhiskersWidth div m;
  symbol[1] := Rect(r.Left, center.y, r.Right, center.y);
  symbol[2] := Rect(r.Left, center.y - ww, r.Left, center.y + ww + 1);
  symbol[3] := Rect(r.Right, center.y - ww, r.Right, center.y + ww + 1);
  bw := (r.Bottom - r.Top) * FBoxWidth div m;
  symbol[4] := Rect(
    (r.Left * 2 + r.Right) div 3, center.y - bw,
    (r.Left + r.Right * 2) div 3, center.y + bw);
  bw -= IfThen(FBoxPen.Style = psClear, 0, (FBoxPen.Width + 1) div 2);
  symbol[5] := Rect(center.x, center.y - bw, center.x, center.y + bw);

  if FIsVertical then
    for i := 1 to High(symbol) do
      symbol[i] := FlipRect(symbol[i]);

  ADrawer.Pen := FWhiskersPen;
  ADrawer.SetBrushParams(bsClear, clTAColor);
  for i := 1 to 3 do
    ADrawer.Line(symbol[i].TopLeft, symbol[i].BottomRight);
  ADrawer.Pen := FBoxPen;
  ADrawer.Brush:= FBoxBrush;
  ADrawer.Rectangle(symbol[4]);
  ADrawer.Pen := FMedianPen;
  ADrawer.Line(symbol[5].TopLeft, symbol[5].BottomRight);
end;


{ TBubbleSeries }

function TBubbleSeries.AddXY(AX, AY, ARadius: Double; AXLabel: String;
  AColor: TColor): Integer;
begin
  if ListSource.YCount < 2 then ListSource.YCount := 2;
  Result := AddXY(AX, AY, [ARadius], AXLabel, AColor);
end;

procedure TBubbleSeries.Assign(ASource: TPersistent);
begin
  if ASource is TBubbleSeries then
    with TBubbleSeries(ASource) do begin
      Self.BubbleBrush := FBubbleBrush;
      Self.BubblePen := FBubblePen;
    end;
  inherited Assign(ASource);
end;

constructor TBubbleSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBubblePen := TPen.Create;
  FBubblePen.OnChange := @StyleChanged;
  FBubbleBrush := TBrush.Create;
  FBubbleBrush.OnChange := @StyleChanged;
end;

destructor TBubbleSeries.Destroy;
begin
  FreeAndNil(FBubbleBrush);
  FreeAndNil(FBubblePen);
  inherited Destroy;
end;

procedure TBubbleSeries.Draw(ADrawer: IChartDrawer);
var
  i: Integer;
  pt, d: TPoint;
  r: Double;
  pi: PChartDataItem;
begin
  if Source.YCount < 2 then exit;
  r := 0;
  for i := 0 to Count - 1 do
    if IsNaN(Source[i]^.YList[0]) then
      continue
    else
      r := Max(Source[i]^.YList[0], r);
  with ParentChart.CurrentExtent do
    PrepareGraphPoints(DoubleRect(a.X - r, a.Y - r, b.X + r, b.Y + r), true);
  ADrawer.Pen := BubblePen;
  ADrawer.Brush := BubbleBrush;
  for i := 0 to High(FGraphPoints) do begin
    if IsNaN(FGraphPoints[i].X) or IsNaN(FGraphPoints[i].Y) then
      Continue;
    pt := ParentChart.GraphToImage(FGraphPoints[i]);
    pi := Source[i + FLoBound];
    r := pi^.YList[0];
    if IsNaN(r) then
      Continue;
    d.X := ParentChart.XGraphToImage(r) - ParentChart.XGraphToImage(0);
    d.Y := ParentChart.YGraphToImage(r) - ParentChart.YGraphToImage(0);
    if bocPen in OverrideColor then
      ADrawer.SetPenParams(BubblePen.Style, ColorDef(pi^.Color, BubblePen.Color));
    if bocBrush in OverrideColor then
      ADrawer.SetBrushColor(ColorDef(pi^.Color, BubbleBrush.Color));
    ADrawer.Ellipse(pt.X - d.X, pt.Y - d.Y, pt.X + d.X, pt.Y + d.Y);
  end;
  DrawLabels(ADrawer);
end;

function TBubbleSeries.Extent: TDoubleRect;
var
  i: Integer;
  r: Double;
begin
  Result := EmptyExtent;
  if Source.YCount < 2 then exit;
  for i := 0 to Count - 1 do
    with Source[i]^ do begin
      r := YList[0];
      if IsNaN(X) or IsNaN(Y) or IsNaN(r) then continue;
      Result.a.X := Min(Result.a.X, X - r);
      Result.b.X := Max(Result.b.X, X + r);
      Result.a.Y := Min(Result.a.Y, Y - r);
      Result.b.Y := Max(Result.b.Y, Y + r);
    end;
end;

procedure TBubbleSeries.GetLegendItems(AItems: TChartLegendItems);
begin
  GetLegendItemsRect(AItems, BubbleBrush);
end;

function TBubbleSeries.GetSeriesColor: TColor;
begin
  Result := FBubbleBrush.Color;
end;

procedure TBubbleSeries.SetBubbleBrush(AValue: TBrush);
begin
  if FBubbleBrush = AValue then exit;
  FBubbleBrush.Assign(AValue);
  UpdateParentChart;
end;

procedure TBubbleSeries.SetBubblePen(AValue: TPen);
begin
  if FBubblePen = AValue then exit;
  FBubblePen.Assign(AValue);
  UpdateParentChart;
end;

procedure TBubbleSeries.SetOverrideColor(AValue: TBubbleOverrideColors);
begin
  if FOverrideColor = AValue then exit;
  FOverrideColor := AValue;
  UpdateParentChart;
end;

{ TBoxAndWhiskerSeries }

function TBoxAndWhiskerSeries.AddXY(
  AX, AYLoWhisker, AYLoBox, AY, AYHiBox, AYHiWhisker: Double; AXLabel: String;
  AColor: TColor): Integer;
begin
  if ListSource.YCount < 5 then ListSource.YCount := 5;
  Result := AddXY(
    AX, AYLoWhisker, [AYLoBox, AY, AYHiBox, AYHiWhisker], AXLabel, AColor);
end;

procedure TBoxAndWhiskerSeries.Assign(ASource: TPersistent);
begin
  if ASource is TBoxAndWhiskerSeries then
    with TBoxAndWhiskerSeries(ASource) do begin
      Self.BoxBrush.Assign(FBoxBrush);
      Self.BoxPen.Assign(FBoxPen);
      Self.FBoxWidth := FBoxWidth;
      Self.MedianPen.Assign(FMedianPen);
      Self.WhiskersPen.Assign(FWhiskersPen);
      Self.FWhiskersWidth := FWhiskersWidth;
    end;
  inherited Assign(ASource);
end;

constructor TBoxAndWhiskerSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBoxBrush := TBrush.Create;
  FBoxBrush.OnChange := @StyleChanged;
  FBoxPen := TPen.Create;
  FBoxPen.OnChange := @StyleChanged;
  FBoxWidth := DEF_BOX_WIDTH;
  FMedianPen := TPen.Create;
  FMedianPen.OnChange := @StyleChanged;
  FWhiskersPen := TPen.Create;
  FWhiskersPen.OnChange := @StyleChanged;
  FWhiskersWidth := DEF_WHISKERS_WIDTH;
end;

destructor TBoxAndWhiskerSeries.Destroy;
begin
  FreeAndNil(FBoxBrush);
  FreeAndNil(FBoxPen);
  FreeAndNil(FMedianPen);
  FreeAndNil(FWhiskersPen);
  inherited Destroy;
end;

procedure TBoxAndWhiskerSeries.Draw(ADrawer: IChartDrawer);

  function MaybeRotate(AX, AY: Double): TPoint;
  begin
    if IsRotated then
      Exchange(AX, AY);
    Result := ParentChart.GraphToImage(DoublePoint(AX, AY));
  end;

  procedure DoLine(AX1, AY1, AX2, AY2: Double);
  begin
    ADrawer.Line(MaybeRotate(AX1, AY1), MaybeRotate(AX2, AY2));
  end;

  procedure DoRect(AX1, AY1, AX2, AY2: Double);
  var
    r: TRect;
  begin
    with ParentChart do begin
      r.TopLeft := MaybeRotate(AX1, AY1);
      r.BottomRight := MaybeRotate(AX2, AY2);
    end;
    ADrawer.Rectangle(r);
  end;

var
  ext2: TDoubleRect;
  x, ymin, yqmin, ymed, yqmax, ymax, wb, ww, w: Double;
  i: Integer;
begin
  if IsEmpty or (Source.YCount < 5) then
    exit;
  if FWidthStyle = bwsPercentMin then
    UpdateMinXRange;

  ext2 := ParentChart.CurrentExtent;
  ExpandRange(ext2.a.X, ext2.b.X, 1.0);
  ExpandRange(ext2.a.Y, ext2.b.Y, 1.0);

  PrepareGraphPoints(ext2, true);

  for i := FLoBound to FUpBound do begin
    x := GetGraphPointX(i);
    ymin := GetGraphPointY(i);
    if IsNaN(x) or IsNaN(ymin) then
      continue;
    with Source[i]^ do begin
      if IsNaN(YList[0]) then continue else yqmin := AxisToGraphY(YList[0]);
      if IsNaN(YList[1]) then continue else ymed := AxisToGraphY(YList[1]);
      if IsNaN(YList[2]) then continue else yqmax := AxisToGraphY(YList[2]);
      if IsNaN(YList[3]) then continue else ymax := AxisToGraphY(YList[3]);
    end;
    case FWidthStyle of
      bwsPercent: w := GetXRange(x, i) * PERCENT / 2;
      bwsPercentMin: w := FMinXRange * PERCENT / 2;
    end;
    wb := w * BoxWidth;
    ww := w * WhiskersWidth;

    ADrawer.Pen := WhiskersPen;
    ADrawer.SetBrushParams(bsClear, clTAColor);
    DoLine(x - ww, ymin, x + ww, ymin);
    DoLine(x, ymin, x, yqmin);
    DoLine(x - ww, ymax, x + ww, ymax);
    DoLine(x, ymax, x, yqmax);
    ADrawer.Pen := BoxPen;
    if Source[i]^.Color <> clTAColor then
      ADrawer.SetBrushParams(bsSolid, Source[i]^.Color)
    else
      ADrawer.Brush := BoxBrush;
    DoRect(x - wb, yqmin, x + wb, yqmax);
    ADrawer.Pen := MedianPen;
    ADrawer.SetBrushParams(bsClear, clTAColor);
    DoLine(x - wb, ymed, x + wb, ymed);
  end;
end;

function TBoxAndWhiskerSeries.Extent: TDoubleRect;
var
  x: Double;

  function ExtraWidth(AIndex: Integer): Double;
  begin
    Result := GetXRange(x, AIndex) * Max(BoxWidth, WhiskersWidth) * PERCENT / 2;
  end;

begin
  if Source.YCount < 5 then exit(EmptyExtent);
  Result := Source.ExtentList;
  // Show first and last boxes fully.
  x := GetGraphPointX(0);
  Result.a.X := Min(Result.a.X, x - ExtraWidth(0));
  x := GetGraphPointX(Count - 1);
  Result.b.X := Max(Result.b.X, x + ExtraWidth(Count - 1));
end;

procedure TBoxAndWhiskerSeries.GetLegendItems(AItems: TChartLegendItems);
begin
  AItems.Add(TLegendItemBoxAndWhiskers.Create(Self, LegendTextSingle));
end;

function TBoxAndWhiskerSeries.GetSeriesColor: TColor;
begin
  Result := BoxBrush.Color;
end;

procedure TBoxAndWhiskerSeries.SetBoxBrush(AValue: TBrush);
begin
  if FBoxBrush = AValue then exit;
  FBoxBrush.Assign(AValue);
  UpdateParentChart;
end;

procedure TBoxAndWhiskerSeries.SetBoxPen(AValue: TPen);
begin
  if FBoxPen = AValue then exit;
  FBoxPen.Assign(AValue);
  UpdateParentChart;
end;

procedure TBoxAndWhiskerSeries.SetBoxWidth(AValue: Integer);
begin
  if FBoxWidth = AValue then exit;
  FBoxWidth := AValue;
  UpdateParentChart;
end;

procedure TBoxAndWhiskerSeries.SetLegendDirection(
  AValue: TBoxAndWhiskerSeriesLegendDir);
begin
  if FLegendDirection = AValue then exit;
  FLegendDirection := AValue;
  UpdateParentChart;
end;

procedure TBoxAndWhiskerSeries.SetMedianPen(AValue: TPen);
begin
  if FMedianPen = AValue then exit;
  FMedianPen.Assign(AValue);
  UpdateParentChart;
end;

procedure TBoxAndWhiskerSeries.SetWhiskersPen(AValue: TPen);
begin
  if FWhiskersPen = AValue then exit;
  FWhiskersPen.Assign(AValue);
  UpdateParentChart;
end;

procedure TBoxAndWhiskerSeries.SetWhiskersWidth(AValue: Integer);
begin
  if FWhiskersWidth = AValue then exit;
  FWhiskersWidth := AValue;
  UpdateParentChart;
end;

{ TOpenHighLowCloseSeries }

function TOpenHighLowCloseSeries.AddXOHLC(
  AX, AOpen, AHigh, ALow, AClose: Double;
  ALabel: String; AColor: TColor): Integer;
begin
  if ListSource.YCount < 4 then ListSource.YCount := 4;
  Result := ListSource.Add(AX, NaN, ALabel, AColor);
  with ListSource.Item[Result]^ do begin
    SetY(YIndexOpen, AOpen);
    SetY(YIndexHigh, AHigh);
    SetY(YIndexLow, ALow);
    SetY(YIndexClose, AClose);
  end;
end;

procedure TOpenHighLowCloseSeries.Assign(ASource: TPersistent);
begin
  if ASource is TOpenHighLowCloseSeries then
    with TOpenHighLowCloseSeries(ASource) do begin
      Self.FCandlestickDownBrush := FCandlestickDownBrush;
      Self.FCandlestickLinePen := FCandlestickLinePen;
      Self.FCandlestickUpBrush := FCandlestickUpBrush;
      Self.FDownLinePen := FDownLinePen;
      Self.FLinePen := FLinePen;
      Self.FMode := FMode;
      Self.FTickWidth := FTickWidth;
      Self.FYIndexClose := FYIndexClose;
      Self.FYIndexHigh := FYIndexHigh;
      Self.FYIndexLow := FYIndexLow;
      Self.FYIndexOpen := FYIndexOpen;
    end;
  inherited Assign(ASource);
end;

constructor TOpenHighLowCloseSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCandlestickDownBrush := TBrush.Create;
  with FCandlestickDownBrush do begin
    Color := clRed;
    OnChange := @StyleChanged;
  end;
  FCandlestickLinePen := TPen.Create;
  with FCandlestickLinePen do begin
    Color := clBlack;
    OnChange := @StyleChanged;
  end;
  FCandlestickUpBrush := TBrush.Create;
  with FCandlestickUpBrush do begin
    Color := clLime;
    OnChange := @StyleChanged;
  end;
  FDownLinePen := TOHLCDownPen.Create;
  with FDownLinePen do begin
    Color := clTAColor;
    OnChange := @StyleChanged;
  end;
  FLinePen := TPen.Create;
  with FLinePen do
    OnChange := @StyleChanged;
  FTickWidth := DEF_OHLC_TICK_WIDTH;
  FYIndexClose := DEF_YINDEX_CLOSE;
  FYIndexHigh := DEF_YINDEX_HIGH;
  FYIndexLow := DEF_YINDEX_LOW;
  FYIndexOpen := DEF_YINDEX_OPEN;
end;

destructor TOpenHighLowCloseSeries.Destroy;
begin
  FreeAndNil(FCandlestickDownBrush);
  FreeAndNil(FCandlestickLinePen);
  FreeAndNil(FCandlestickUpBrush);
  FreeAndNil(FDownLinePen);
  FreeAndNil(FLinePen);
  inherited;
end;

procedure TOpenHighLowCloseSeries.Draw(ADrawer: IChartDrawer);

  function MaybeRotate(AX, AY: Double): TPoint;
  begin
    if IsRotated then
      Exchange(AX, AY);
    Result := ParentChart.GraphToImage(DoublePoint(AX, AY));
  end;

  procedure DoLine(AX1, AY1, AX2, AY2: Double);
  begin
    ADrawer.Line(MaybeRotate(AX1, AY1), MaybeRotate(AX2, AY2));
  end;

  procedure DoRect(AX1, AY1, AX2, AY2: Double);
  var
    r: TRect;
  begin
    with ParentChart do begin
      r.TopLeft := MaybeRotate(AX1, AY1);
      r.BottomRight := MaybeRotate(AX2, AY2);
    end;
    ADrawer.FillRect(r.Left, r.Top, r.Right, r.Bottom);
    ADrawer.Rectangle(r);
  end;

  function GetGraphPointYIndex(AIndex, AYIndex: Integer): Double;
  begin
    if AYIndex = 0 then
      Result := GetGraphPointY(AIndex)
    else
      Result := AxisToGraphY(Source[AIndex]^.YList[AYIndex - 1]);
  end;

  procedure DrawOHLC(x, yopen, yhigh, ylow, yclose, tw: Double);
  begin
    DoLine(x, yhigh, x, ylow);
    DoLine(x - tw, yopen, x, yopen);
    DoLine(x, yclose, x + tw, yclose);
  end;

  procedure DrawCandleStick(x, yopen, yhigh, ylow, yclose, tw: Double);
  var
    clr: TColor;
  begin
    ADrawer.Pen := FCandlestickLinePen;
    if FCandleStickLinePen.Color = clDefault then begin
      if yopen <= yclose then
        clr := FCandleStickUpBrush.Color
      else
        clr := FCandleStickDownBrush.Color;
      ADrawer.SetPenParams(FCandleStickLinePen.Style, clr);
    end;
    DoLine(x, yhigh, x, ylow);
    DoRect(x - tw, yopen, x + tw, yclose);
  end;

var
  my: Cardinal;
  ext2: TDoubleRect;
  i: Integer;
  x, tw, yopen, yhigh, ylow, yclose: Double;
  p: TPen;
begin
  my := MaxIntValue([YIndexOpen, YIndexHigh, YIndexLow, YIndexClose]);
  if IsEmpty or (my >= Source.YCount) then exit;

  ext2 := ParentChart.CurrentExtent;
  ExpandRange(ext2.a.X, ext2.b.X, 1.0);
  ExpandRange(ext2.a.Y, ext2.b.Y, 1.0);

  PrepareGraphPoints(ext2, true);

  for i := FLoBound to FUpBound do begin
    x := GetGraphPointX(i);
    yopen := GetGraphPointYIndex(i, YIndexOpen);
    yhigh := GetGraphPointYIndex(i, YIndexHigh);
    ylow := GetGraphPointYIndex(i, YIndexLow);
    yclose := GetGraphPointYIndex(i, YIndexClose);
    tw := GetXRange(x, i) * PERCENT * TickWidth;

    if (yopen <= yclose) then begin
      p := LinePen;
      ADrawer.Brush := FCandleStickUpBrush;
    end
    else begin
      p := DownLinePen;
      ADrawer.Brush := FCandleStickDownBrush;
    end;
    ADrawer.Pen := p;
    with Source[i]^ do
      if Color <> clTAColor then
        ADrawer.SetPenParams(p.Style, Color);

    case FMode of
      mOHLC: DrawOHLC(x, yopen, yhigh, ylow, yclose, tw);
      mCandleStick: DrawCandleStick(x, yopen, yhigh, ylow, yclose, tw);
    end;
  end;
end;

function TOpenHighLowCloseSeries.Extent: TDoubleRect;
begin
  Result := Source.ExtentList;
end;

procedure TOpenHighLowCloseSeries.GetLegendItems(AItems: TChartLegendItems);
begin
  AItems.Add(TLegendItemOHLCLine.Create(Self, LegendTextSingle));
end;

function TOpenHighLowCloseSeries.GetSeriesColor: TColor;
begin
  Result := LinePen.Color;
end;

procedure TOpenHighLowCloseSeries.SetCandlestickLinePen(AValue: TPen);
begin
  if FCandleStickLinePen = AValue then exit;
  FCandleStickLinePen.Assign(AValue);
  UpdateParentChart;
end;

procedure TOpenHighLowCloseSeries.SetCandlestickDownBrush(AValue: TBrush);
begin
  if FCandlestickDownBrush = AValue then exit;
  FCandlestickDownBrush.Assign(AValue);
  UpdateParentChart;
end;

procedure TOpenHighLowCloseSeries.SetCandlestickUpBrush(AValue: TBrush);
begin
  if FCandlestickUpBrush = AValue then exit;
  FCandlestickUpBrush.Assign(AValue);
  UpdateParentChart;
end;

procedure TOpenHighLowCloseSeries.SetDownLinePen(AValue: TOHLCDownPen);
begin
  if FDownLinePen = AValue then exit;
  FDownLinePen.Assign(AValue);
  UpdateParentChart;
end;

procedure TOpenHighLowCloseSeries.SetLinePen(AValue: TPen);
begin
  if FLinePen = AValue then exit;
  FLinePen.Assign(AValue);
  UpdateParentChart;
end;

procedure TOpenHighLowCloseSeries.SetOHLCMode(AValue: TOHLCMode);
begin
  if FMode = AValue then exit;
  FMode := AValue;
  UpdateParentChart;
end;

procedure TOpenHighLowCloseSeries.SetTickWidth(AValue: Cardinal);
begin
  if FTickWidth = AValue then exit;
  FTickWidth := AValue;
  UpdateParentChart;
end;

procedure TOpenHighLowCloseSeries.SetYIndexClose(AValue: Cardinal);
begin
  if FYIndexClose = AValue then exit;
  FYIndexClose := AValue;
  UpdateParentChart;
end;

procedure TOpenHighLowCloseSeries.SetYIndexHigh(AValue: Cardinal);
begin
  if FYIndexHigh = AValue then exit;
  FYIndexHigh := AValue;
  UpdateParentChart;
end;

procedure TOpenHighLowCloseSeries.SetYIndexLow(AValue: Cardinal);
begin
  if FYIndexLow = AValue then exit;
  FYIndexLow := AValue;
  UpdateParentChart;
end;

procedure TOpenHighLowCloseSeries.SetYIndexOpen(AValue: Cardinal);
begin
  if FYIndexOpen = AValue then exit;
  FYIndexOpen := AValue;
  UpdateParentChart;
end;


initialization
  RegisterSeriesClass(TBubbleSeries, 'Bubble series');
  RegisterSeriesClass(TBoxAndWhiskerSeries, 'Box-and-whiskers series');
  RegisterSeriesClass(TOpenHighLowCloseSeries, 'Open-high-low-close series');

end.
