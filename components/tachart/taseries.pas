{
 /***************************************************************************
                               TASeries.pas
                               ------------
                Component Library Standard Graph Series


 ***************************************************************************/

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

Authors: Luís Rodrigues, Philippe Martinole, Alexander Klenin

}

unit TASeries;

{$H+}

interface

uses
  Classes, Graphics, Types,
  TAChartUtils, TADrawUtils, TACustomSeries, TALegend, TARadialSeries, TATypes;

const
  DEF_BAR_WIDTH_PERCENT = 70;

type
  EBarError = class(EChartError);

  TBarWidthStyle = (bwPercent, bwPercentMin);

  { TBarSeries }

  TBarSeries = class(TBasicPointSeries)
  private
    FBarBrush: TBrush;
    FBarOffsetPercent: Integer;
    FBarPen: TPen;
    FBarWidthPercent: Integer;
    FBarWidthStyle: TBarWidthStyle;
    FZeroLevel: Double;

    procedure BarOffsetWidth(
      AX: Double; AIndex: Integer; out AOffset, AWidth: Double);
    function IsZeroLevelStored: boolean;
    procedure SetBarBrush(Value: TBrush);
    procedure SetBarOffsetPercent(AValue: Integer);
    procedure SetBarPen(Value: TPen);
    procedure SetBarWidthPercent(Value: Integer);
    procedure SetBarWidthStyle(AValue: TBarWidthStyle);
    procedure SetSeriesColor(AValue: TColor);
    procedure SetZeroLevel(AValue: Double);
  protected
    procedure GetLegendItems(AItems: TChartLegendItems); override;
    function GetSeriesColor: TColor; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    procedure Draw(ACanvas: TCanvas); override;
    function Extent: TDoubleRect; override;
  published
    property AxisIndexX;
    property AxisIndexY;
    property BarBrush: TBrush read FBarBrush write SetBarBrush;
    property BarOffsetPercent: Integer
      read FBarOffsetPercent write SetBarOffsetPercent default 0;
    property BarPen: TPen read FBarPen write SetBarPen;
    property BarWidthPercent: Integer
      read FBarWidthPercent write SetBarWidthPercent default DEF_BAR_WIDTH_PERCENT;
    property BarWidthStyle: TBarWidthStyle
      read FBarWidthStyle write SetBarWidthStyle default bwPercent;
    property Depth;
    property SeriesColor: TColor
      read GetSeriesColor write SetSeriesColor stored false default clRed;
    property Source;
    property Styles;
    property UseReticule;
    property ZeroLevel: Double
      read FZeroLevel write SetZeroLevel stored IsZeroLevelStored;
  end;


  { TPieSeries }

  TPieSeries = class(TCustomPieSeries)
  published
    property Exploded;
    property FixedRadius;
    property RotateLabels;
    property Source;
  end;

  TConnectType = (ctLine, ctStepXY, ctStepYX);

  { TAreaSeries }

  TAreaSeries = class(TBasicPointSeries)
  private
    FAreaBrush: TBrush;
    FAreaContourPen: TPen;
    FAreaLinesPen: TPen;
    FConnectType: TConnectType;
    FUseZeroLevel: Boolean;
    FZeroLevel: Double;

    function IsZeroLevelStored: boolean;
    procedure SetAreaBrush(AValue: TBrush);
    procedure SetAreaContourPen(AValue: TPen);
    procedure SetAreaLinesPen(AValue: TPen);
    procedure SetConnectType(AValue: TConnectType);
    procedure SetSeriesColor(AValue: TColor);
    procedure SetUseZeroLevel(AValue: Boolean);
    procedure SetZeroLevel(AValue: Double);
  protected
    function GetLabelDirection(AIndex: Integer): TLabelDirection; override;
    procedure GetLegendItems(AItems: TChartLegendItems); override;
    function GetSeriesColor: TColor; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Draw(ACanvas: TCanvas); override;
    function Extent: TDoubleRect; override;
  published
    property AxisIndexX;
    property AxisIndexY;
  published
    property AreaBrush: TBrush read FAreaBrush write SetAreaBrush;
    property AreaContourPen: TPen read FAreaContourPen write SetAreaContourPen;
    property AreaLinesPen: TPen read FAreaLinesPen write SetAreaLinesPen;
    property ConnectType: TConnectType
      read FConnectType write SetConnectType default ctLine;
    property Depth;
    property SeriesColor: TColor
      read GetSeriesColor write SetSeriesColor stored false default clWhite;
    property Source;
    property Styles;
    property UseReticule;
    property UseZeroLevel: Boolean
      read FUseZeroLevel write SetUseZeroLevel default false;
    property ZeroLevel: Double
      read FZeroLevel write SetZeroLevel stored IsZeroLevelStored;
  end;

  TSeriesPointerDrawEvent = procedure (
    ASender: TChartSeries; ACanvas: TCanvas; AIndex: Integer;
    ACenter: TPoint) of object;

  TLineType = (ltNone, ltFromPrevious, ltFromOrigin, ltStepXY, ltStepYX);

  { TLineSeries }

  TLineSeries = class(TBasicPointSeries)
  private
    FLinePen: TPen;
    FLineType: TLineType;
    FOnDrawPointer: TSeriesPointerDrawEvent;
    FPointer: TSeriesPointer;
    FShowPoints: Boolean;

    procedure DrawSingleLineInStack(ACanvas: TCanvas; AIndex: Integer);
    function GetShowLines: Boolean;
    procedure SetLinePen(AValue: TPen);
    procedure SetLineType(AValue: TLineType);
    procedure SetPointer(Value: TSeriesPointer);
    procedure SetSeriesColor(AValue: TColor);
    procedure SetShowLines(Value: Boolean);
    procedure SetShowPoints(Value: Boolean);
  protected
    procedure AfterAdd; override;
    procedure GetLegendItems(AItems: TChartLegendItems); override;
    function GetSeriesColor: TColor; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    procedure Draw(ACanvas: TCanvas); override;
  public
    procedure BeginUpdate;
    procedure EndUpdate;
  published
    property AxisIndexX;
    property AxisIndexY;
    property Depth;
    property LinePen: TPen read FLinePen write SetLinePen;
    property LineType: TLineType
      read FLineType write SetLineType default ltFromPrevious;
    property OnDrawPointer: TSeriesPointerDrawEvent
      read FOnDrawPointer write FOnDrawPointer;
    property Pointer: TSeriesPointer read FPointer write SetPointer;
    property SeriesColor: TColor
      read GetSeriesColor write SetSeriesColor stored false default clBlack;
    property ShowLines: Boolean
      read GetShowLines write SetShowLines stored false default true;
    property ShowPoints: Boolean
      read FShowPoints write SetShowPoints default false;
    property Source;
    property Styles;
    property UseReticule default true;
  end;

  // 'TSerie' alias is for compatibility with older versions of TAChart.
  // Use TLineSeries instead.
  TSerie = TLineSeries deprecated;

  TLineStyle = (lsVertical, lsHorizontal);

  { TConstantLine }

  TConstantLine = class(TCustomChartSeries)
  private
    FLineStyle: TLineStyle;
    FPen: TPen;
    FPosGraph: Double; // Graph coordinate of line
    FUseBounds: Boolean;

    function GetSeriesColor: TColor;
    procedure SavePosToCoord(var APoint: TDoublePoint);
    procedure SetLineStyle(AValue: TLineStyle);
    procedure SetPen(AValue: TPen);
    procedure SetPos(AValue: Double);
    procedure SetSeriesColor(AValue: TColor);
    procedure SetUseBounds(AValue: Boolean);
  protected
    procedure GetBounds(var ABounds: TDoubleRect); override;
    procedure GetLegendItems(AItems: TChartLegendItems); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    procedure Draw(ACanvas: TCanvas); override;
    function GetNearestPoint(
      ADistFunc: TPointDistFunc;
      const APoint: TPoint; out AIndex: Integer; out AImg: TPoint;
      out AValue: TDoublePoint): Boolean; override;
    procedure MovePoint(var AIndex: Integer; const ANewPos: TPoint); override;

  published
    property Active default true;
    property LineStyle: TLineStyle
      read FLineStyle write SetLineStyle default lsHorizontal;
    property Pen: TPen read FPen write SetPen;
    property Position: Double read FPosGraph write SetPos;
    property SeriesColor: TColor
      read GetSeriesColor write SetSeriesColor default clTAColor;
    property ShowInLegend;
    property Title;
    property UseBounds: Boolean read FUseBounds write SetUseBounds default true;
    property ZPosition;
  end;

  // 'TLine' alias is for compatibility with older versions of TAChart.
  // Use TConstantLine instead.
  TLine = class(TConstantLine) end deprecated;

  TSeriesDrawEvent = procedure (ACanvas: TCanvas; const ARect: TRect) of object;
  TSeriesGetBoundsEvent = procedure (var ABounds: TDoubleRect) of object;

  { TUserDrawnSeries }

  TUserDrawnSeries = class(TCustomChartSeries)
  private
    FOnDraw: TSeriesDrawEvent;
    FOnGetBounds: TSeriesGetBoundsEvent;
    procedure SetOnDraw(AValue: TSeriesDrawEvent);
    procedure SetOnGetBounds(AValue: TSeriesGetBoundsEvent);
  protected
    procedure GetBounds(var ABounds: TDoubleRect); override;
    procedure GetLegendItems(AItems: TChartLegendItems); override;
  public
    procedure Draw(ACanvas: TCanvas); override;
    function IsEmpty: Boolean; override;
  published
    property Active default true;
    property ZPosition;
  published
    property OnDraw: TSeriesDrawEvent read FOnDraw write SetOnDraw;
    property OnGetBounds: TSeriesGetBoundsEvent
      read FOnGetBounds write SetOnGetBounds;
  end;

implementation

uses
  GraphMath, LResources, Math, PropEdits, SysUtils,
  TAGraph;

{ TLineSeries }

procedure TLineSeries.AfterAdd;
begin
  inherited AfterAdd;
  FPointer.SetOwner(FChart);
end;

procedure TLineSeries.BeginUpdate;
begin
  ListSource.BeginUpdate;
end;

constructor TLineSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FLinePen := TPen.Create;
  FLinePen.OnChange := @StyleChanged;
  FLineType := ltFromPrevious;
  FPointer := TSeriesPointer.Create(FChart);
  FUseReticule := true;
end;

destructor TLineSeries.Destroy;
begin
  FreeAndNil(FLinePen);
  FreeAndNil(FPointer);
  inherited;
end;

procedure TLineSeries.Draw(ACanvas: TCanvas);
var
  ext: TDoubleRect;
  i: Integer;
begin
  with Extent do begin
    ext.a := AxisToGraph(a);
    ext.b := AxisToGraph(b);
  end;
  if LineType = ltFromOrigin then
    ExpandRect(ext, AxisToGraph(ZeroDoublePoint));
  // Do not draw anything if the series extent does not intersect CurrentExtent.
  if not RectIntersectsRect(ext, ParentChart.CurrentExtent) then exit;

  PrepareGraphPoints(ext, LineType <> ltFromOrigin);
  DrawSingleLineInStack(ACanvas, 0);
  for i := 0 to Source.YCount - 2 do begin
    UpdateGraphPoints(i);
    DrawSingleLineInStack(ACanvas, i + 1);
  end;
end;

procedure TLineSeries.DrawSingleLineInStack(ACanvas: TCanvas; AIndex: Integer);
var
  points: array of TPoint;
  pointCount: Integer = 0;
  breaks: TIntegerDynArray;
  breakCount: Integer = 0;

  procedure CacheLine(AA, AB: TDoublePoint);
  var
    ai, bi: TPoint;
  begin
    // This is not an optimization, but a safety check to avoid
    // integer overflow with extreme zoom-ins.
    if not LineIntersectsRect(AA, AB, ParentChart.CurrentExtent) then exit;
    ai := ParentChart.GraphToImage(AA);
    bi := ParentChart.GraphToImage(AB);
    if ai = bi then exit;
    if (pointCount = 0) or (points[pointCount - 1] <> ai) then begin
      breaks[breakCount] := pointCount;
      breakCount += 1;
      points[pointCount] := ai;
      pointCount += 1;
    end;
    points[pointCount] := bi;
    pointCount += 1;
  end;

  procedure DrawLines;
  var
    i, j: Integer;
    orig, m: TDoublePoint;
  begin
    if LineType = ltNone then exit;
    // For extremely long series (10000 points or more), the Canvas.Line call
    // becomes a bottleneck. So represent a serie as a sequence of polylines.
    // This achieves approximately 3x speedup for the typical case.
    SetLength(points, 2 * Length(FGraphPoints));
    SetLength(breaks, Length(FGraphPoints) + 1);
    case LineType of
      ltFromPrevious: begin
        for i := 0 to High(FGraphPoints) - 1 do
          CacheLine(FGraphPoints[i], FGraphPoints[i + 1]);
      end;
      ltFromOrigin: begin
        orig := AxisToGraph(ZeroDoublePoint);
        for i := 0 to High(FGraphPoints) do
          CacheLine(orig, FGraphPoints[i]);
      end;
      ltStepXY, ltStepYX: begin
        for i := 0 to High(FGraphPoints) - 1 do begin
          if (LineType = ltStepXY) xor IsRotated then
            m := DoublePoint(FGraphPoints[i + 1].X, FGraphPoints[i].Y)
          else
            m := DoublePoint(FGraphPoints[i].X, FGraphPoints[i + 1].Y);
          CacheLine(FGraphPoints[i], m);
          CacheLine(m, FGraphPoints[i + 1]);
        end;
      end;
    end;
    breaks[breakCount] := pointCount;
    breakCount += 1;
    SetLength(points, pointCount);
    SetLength(breaks, breakCount);

    if Styles = nil then
      ACanvas.Pen.Assign(LinePen)
    else
      Styles.Apply(ACanvas, AIndex);
    if Depth = 0 then
      for i := 0 to High(breaks) - 1 do
        ACanvas.Polyline(points, breaks[i], breaks[i + 1] - breaks[i])
    else begin
      if Styles = nil then begin
        ACanvas.Brush.Style := bsSolid;
        ACanvas.Brush.Color := LinePen.Color;
        ACanvas.Pen.Color := clBlack;
      end;
      for i := 0 to High(breaks) - 1 do
        for j := breaks[i] to breaks[i + 1] - 2 do
          DrawLineDepth(ACanvas, points[j], points[j + 1], Depth);
    end;
  end;

var
  i: Integer;
  ai: TPoint;
  p: TDoublePoint;
begin
  DrawLines;
  DrawLabels(ACanvas);

  if FShowPoints then
    for i := FLoBound to FUpBound do begin
      p := FGraphPoints[i - FLoBound];
      if not ParentChart.IsPointInViewPort(p) then continue;
      ai := ParentChart.GraphToImage(p);
      FPointer.Draw(ACanvas, ai, Source[i]^.Color);
      if Assigned(FOnDrawPointer) then
        FOnDrawPointer(Self, ACanvas, i, ai);
    end;
end;

procedure TLineSeries.EndUpdate;
begin
  ListSource.EndUpdate;
  UpdateParentChart;
end;

procedure TLineSeries.GetLegendItems(AItems: TChartLegendItems);
var
  lp: TPen;
  p: TSeriesPointer;
  i: Integer;
  li: TLegendItemLinePointer;
begin
  if LineType = ltNone then
    lp := nil
  else
    lp := LinePen;
  if ShowPoints then
    p := Pointer
  else
    p := nil;
  case Legend.Multiplicity of
    lmSingle:
      AItems.Add(TLegendItemLinePointer.Create(lp, p, Title));
    lmPoint: begin
      for i := 0 to Count - 1 do begin
        li := TLegendItemLinePointer.Create(lp, p, FormattedMark(i));
        li.Color := GetColor(i);
        AItems.Add(li);
      end;
    end;
  end;
end;

function TLineSeries.GetSeriesColor: TColor;
begin
  Result := FLinePen.Color;
end;

function TLineSeries.GetShowLines: Boolean;
begin
  Result := FLineType <> ltNone;
end;

procedure TLineSeries.SetLinePen(AValue: TPen);
begin
  FLinePen.Assign(AValue);
end;

procedure TLineSeries.SetLineType(AValue: TLineType);
begin
  if FLineType = AValue then exit;
  FLineType := AValue;
  UpdateParentChart;
end;

procedure TLineSeries.SetPointer(Value: TSeriesPointer);
begin
  FPointer.Assign(Value);
  UpdateParentChart;
end;

procedure TLineSeries.SetSeriesColor(AValue: TColor);
begin
  FLinePen.Color := AValue;
end;

procedure TLineSeries.SetShowLines(Value: Boolean);
begin
  if ShowLines = Value then exit;
  if Value then
    FLineType := ltFromPrevious
  else
    FLineType := ltNone;
  UpdateParentChart;
end;

procedure TLineSeries.SetShowPoints(Value: Boolean);
begin
  FShowPoints := Value;
  UpdateParentChart;
end;

{ TConstantLine }

constructor TConstantLine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FLineStyle := lsHorizontal;
  FPen := TPen.Create;
  FPen.OnChange := @StyleChanged;
  FUseBounds := true;
end;

destructor TConstantLine.Destroy;
begin
  FreeAndNil(FPen);
  inherited;
end;

procedure TConstantLine.Draw(ACanvas: TCanvas);
begin
  ACanvas.Brush.Style := bsClear;
  ACanvas.Pen.Assign(FPen);

  with ParentChart do
    case LineStyle of
      lsHorizontal:
        DrawLineHoriz(ACanvas, YGraphToImage(FPosGraph));
      lsVertical:
        DrawLineVert(ACanvas, XGraphToImage(FPosGraph));
    end;
end;

procedure TConstantLine.GetBounds(var ABounds: TDoubleRect);
begin
  if not UseBounds then exit;
  SavePosToCoord(ABounds.a);
  SavePosToCoord(ABounds.b);
end;

procedure TConstantLine.GetLegendItems(AItems: TChartLegendItems);
begin
  AItems.Add(TLegendItemLine.Create(Pen, Title));
end;

function TConstantLine.GetNearestPoint(ADistFunc: TPointDistFunc;
  const APoint: TPoint; out AIndex: Integer; out AImg: TPoint; out
  AValue: TDoublePoint): Boolean;
begin
  Unused(ADistFunc);
  Result := true;
  AIndex := -1;
  AImg := APoint;
  // Return the actual nearest point of the line.
  if LineStyle = lsVertical then begin
    AValue.Y := FChart.YImageToGraph(APoint.Y);
    AImg.X := FChart.XGraphToImage(Position);
  end
  else begin
    AValue.X := FChart.XImageToGraph(APoint.X);
    AImg.Y := FChart.YGraphToImage(Position);
  end;
  SavePosToCoord(AValue);
end;

function TConstantLine.GetSeriesColor: TColor;
begin
  Result := FPen.Color;
end;

procedure TConstantLine.MovePoint(var AIndex: Integer; const ANewPos: TPoint);
begin
  Unused(AIndex);
  if LineStyle = lsVertical then
    Position := FChart.XImageToGraph(ANewPos.X)
  else
    Position := FChart.YImageToGraph(ANewPos.Y);
end;

procedure TConstantLine.SavePosToCoord(var APoint: TDoublePoint);
begin
  if LineStyle = lsVertical then
    APoint.X := Position
  else
    APoint.Y := Position;
end;

procedure TConstantLine.SetLineStyle(AValue: TLineStyle);
begin
  if FLineStyle = AValue then exit;
  FLineStyle := AValue;
  UpdateParentChart;
end;

procedure TConstantLine.SetPen(AValue: TPen);
begin
  FPen.Assign(AValue);
end;

procedure TConstantLine.SetPos(AValue: Double);
begin
  if FPosGraph = AValue then exit;
  FPosGraph := AValue;
  UpdateParentChart;
end;

procedure TConstantLine.SetSeriesColor(AValue: TColor);
begin
  if FPen.Color = AValue then exit;
  FPen.Color := AValue;
end;

procedure TConstantLine.SetUseBounds(AValue: Boolean);
begin
  if FUseBounds = AValue then exit;
  FUseBounds := AValue;
  UpdateParentChart;
end;

{ TBarSeries }

procedure TBarSeries.BarOffsetWidth(
  AX: Double; AIndex: Integer; out AOffset, AWidth: Double);
var
  r: Double;
begin
  case BarWidthStyle of
    bwPercent: r := GetXRange(AX, AIndex) * PERCENT;
    bwPercentMin: r := FMinXRange * PERCENT;
    else
      raise EBarError.Create('BarWidthStyle not implemented');
  end;
  AOffset := r * BarOffsetPercent;
  AWidth := r * BarWidthPercent / 2;
end;

constructor TBarSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBarWidthPercent := DEF_BAR_WIDTH_PERCENT;

  FBarBrush := TBrush.Create;
  FBarBrush.OnChange := @StyleChanged;

  FBarPen := TPen.Create;
  FBarPen.OnChange := @StyleChanged;
  FBarPen.Color := clBlack;
  FBarBrush.Color := clRed;
end;

destructor TBarSeries.Destroy;
begin
  FreeAndNil(FBarPen);
  FreeAndNil(FBarBrush);
  inherited;
end;

procedure TBarSeries.Draw(ACanvas: TCanvas);

  procedure DrawBar(const AR: TRect; AIndex: Integer);
  var
    sz: TSize;
  begin
    sz := Size(AR);
    if Styles <> nil then
      Styles.Apply(ACanvas, AIndex)
    else
      ACanvas.Pen.Assign(BarPen);
    if (sz.cx <= 2) or (sz.cy <= 2) then begin
      // Bars are too small to distinguish border from interior.
      ACanvas.Pen.Color := ACanvas.Brush.Color;
      ACanvas.Pen.Style := psSolid;
    end;

    ACanvas.Rectangle(AR);

    if Depth = 0 then exit;
    DrawLineDepth(ACanvas, AR.Left, AR.Top, AR.Right - 1, AR.Top, Depth);
    DrawLineDepth(
      ACanvas, AR.Right - 1, AR.Top, AR.Right - 1, AR.Bottom - 1, Depth);
  end;

var
  ext2: TDoubleRect;
  w, cumulHeight: Double;
  p: TDoublePoint;

  procedure BuildBar(AY: Double; AIndex: Integer);
  var
    graphBar: TDoubleRect;
    imageBar: TRect;
  begin
    graphBar := DoubleRect(p.X - w, cumulHeight, p.X + w, cumulHeight + AY);
    if IsRotated then
      with graphBar do begin
        Exchange(a.X, a.Y);
        Exchange(b.X, b.Y);
      end;

    cumulHeight += AY;
    if not RectIntersectsRect(graphBar, ext2) then exit;

    with imageBar do begin
      TopLeft := ParentChart.GraphToImage(graphBar.a);
      BottomRight := ParentChart.GraphToImage(graphBar.b);
      NormalizeRect(imageBar);

      // Draw a line instead of an empty rectangle.
      if Bottom = Top then Dec(Top);
      if Left = Right then Inc(Right);
    end;
    DrawBar(imageBar, AIndex);
  end;

var
  i, j: Integer;
  z, ofs: Double;
begin
  if IsEmpty then exit;

  if BarWidthStyle = bwPercentMin then
    UpdateMinXRange;
  ext2 := ParentChart.CurrentExtent;
  ExpandRange(ext2.a.X, ext2.b.X, 1.0);
  ExpandRange(ext2.a.Y, ext2.b.Y, 1.0);

  PrepareGraphPoints(ext2, true);
  ACanvas.Brush.Assign(BarBrush);
  if IsRotated then
    z := AxisToGraphX(ZeroLevel)
  else
    z := AxisToGraphY(ZeroLevel);
  for i := FLoBound to FUpBound do begin
    BarOffsetWidth(GetGraphPointX(i), i, ofs, w);
    p := FGraphPoints[i - FLoBound];
    if IsRotated then
      Exchange(p.X, p.Y);
    p.X += ofs;
    cumulHeight := z;
    ACanvas.Brush.Color := GetColor(i);
    BuildBar(p.Y - z, 0);
    for j := 0 to Source.YCount - 2 do
      BuildBar(Source[i]^.YList[j], j + 1);
  end;

  DrawLabels(ACanvas);
end;

function TBarSeries.Extent: TDoubleRect;
var
  x, ofs, w: Double;
begin
  Result := inherited Extent;
  if IsEmpty then exit;
  if BarWidthStyle = bwPercentMin then
    UpdateMinXRange;
  UpdateMinMax(ZeroLevel, Result.a.Y, Result.b.Y);
  // Show first and last bars fully.
  x := GetGraphPointX(0);
  BarOffsetWidth(x, 0, ofs, w);
  Result.a.X := Min(Result.a.X, x + ofs - w);
  x := GetGraphPointX(Count - 1);
  BarOffsetWidth(x, Count - 1, ofs, w);
  Result.b.X := Max(Result.b.X, x + ofs + w);
end;

procedure TBarSeries.GetLegendItems(AItems: TChartLegendItems);
begin
  GetLegendItemsRect(AItems, BarBrush);
end;

function TBarSeries.GetSeriesColor: TColor;
begin
  Result := FBarBrush.Color;
end;

function TBarSeries.IsZeroLevelStored: boolean;
begin
  Result := ZeroLevel <> 0.0;
end;

procedure TBarSeries.SetBarBrush(Value: TBrush);
begin
  FBarBrush.Assign(Value);
end;

procedure TBarSeries.SetBarOffsetPercent(AValue: Integer);
begin
  if FBarOffsetPercent = AValue then exit;
  FBarOffsetPercent := AValue;
  UpdateParentChart;
end;

procedure TBarSeries.SetBarPen(Value:TPen);
begin
  FBarPen.Assign(Value);
end;

procedure TBarSeries.SetBarWidthPercent(Value: Integer);
begin
  if (Value < 1) or (Value > 100) then
    raise EBarError.Create('Wrong BarWidth Percent');
  FBarWidthPercent := Value;
  UpdateParentChart;
end;

procedure TBarSeries.SetBarWidthStyle(AValue: TBarWidthStyle);
begin
  if FBarWidthStyle = AValue then exit;
  FBarWidthStyle := AValue;
  UpdateParentChart;
end;

procedure TBarSeries.SetSeriesColor(AValue: TColor);
begin
  FBarBrush.Color := AValue;
end;

procedure TBarSeries.SetZeroLevel(AValue: Double);
begin
  if FZeroLevel = AValue then exit;
  FZeroLevel := AValue;
  UpdateParentChart;
end;

{ TAreaSeries }

constructor TAreaSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAreaBrush := TBrush.Create;
  FAreaBrush.OnChange := @StyleChanged;
  FAreaContourPen := TPen.Create;
  FAreaContourPen.OnChange := @StyleChanged;
  FAreaLinesPen := TPen.Create;
  FAreaLinesPen.OnChange := @StyleChanged;
end;

destructor TAreaSeries.Destroy;
begin
  FreeAndNil(FAreaBrush);
  FreeAndNil(FAreaContourPen);
  FreeAndNil(FAreaLinesPen);
  inherited;
end;

procedure TAreaSeries.Draw(ACanvas: TCanvas);
var
  pts: TPointArray;
  numPts: Integer;

  procedure PushPoint(const AP: TPoint); overload;
  begin
    if (numPts > 0) and (AP = pts[numPts - 1]) then exit;
    pts[numPts] := AP;
    numPts += 1;
  end;

  procedure PushPoint(const AP: TDoublePoint); overload;
  begin
    PushPoint(ParentChart.GraphToImage(AP));
  end;

  function ProjToLine(const APt: TDoublePoint; ACoord: Double): TDoublePoint;
  begin
    Result := APt;
    if IsRotated then
      Result.X := ACoord
    else
      Result.Y := ACoord;
  end;
var
  i, j, n2, numPrevPts: Integer;
  a, b: TDoublePoint;
  ext, ext2: TDoubleRect;
  z, z1, z2: Double;
  prevPts: TPointArray;
begin
  if IsEmpty then exit;

  ext := ParentChart.CurrentExtent;
  ext2 := ext;
  ExpandRange(ext2.a.X, ext2.b.X, 0.1);
  ExpandRange(ext2.a.Y, ext2.b.Y, 0.1);

  PrepareGraphPoints(ext, true);
  if Length(FGraphPoints) = 0 then exit;

  SetLength(pts, Length(FGraphPoints) * 4 + 4);
  SetLength(prevPts, Length(pts));
  numPrevPts := 0;

  if UseZeroLevel then
    z := AxisToGraphY(ZeroLevel)
  else
    z := IfThen(IsRotated, ext2.a.X, ext2.a.Y);
  z1 := z;
  z2 := z;

  for j := 0 to Source.YCount - 1 do begin
    if j > 0 then
      UpdateGraphPoints(j - 1);
    numPts := 0;
    a := ProjToRect(FGraphPoints[0], ext2);
    PushPoint(ProjToLine(a, z1));
    z1 := IfThen(IsRotated, a.X, a.Y);
    for i := 0 to High(FGraphPoints) - 1 do begin
      a := FGraphPoints[i];
      b := FGraphPoints[i + 1];
      case ConnectType of
        ctLine: ;
        ctStepXY:
          if IsRotated then
            b.X := a.X
          else
            b.Y := a.Y;
        ctStepYX:
          if IsRotated then
            a.X := b.X
          else
            a.Y := b.Y;
      end;
      // Avoid integer overflow at extreme zoom levels.
      if LineIntersectsRect(a, b, ext2) then begin
        PushPoint(a);
        PushPoint(b);
      end
      else begin
        PushPoint(ProjToRect(a, ext2));
        PushPoint(ProjToRect(b, ext2));
      end;
    end;
    a := ProjToRect(FGraphPoints[High(FGraphPoints)], ext2);
    PushPoint(ProjToLine(a, z2));
    z2 := IfThen(IsRotated, a.X, a.Y);
    n2 := numPts;

    for i := 0 to numPrevPts - 1 do
      PushPoint(prevPts[numPrevPts - i - 1]);
    for i := 0 to n2 - 1 do
      prevPts[i] := pts[i];
    numPrevPts := n2;

    if Styles = nil then begin
      ACanvas.Brush.Assign(AreaBrush);
      ACanvas.Pen.Assign(AreaContourPen);
    end
    else
      Styles.Apply(ACanvas, j);
    if Depth > 0 then
      // Rendering is incorrect when values cross zero level.
      for i := 1 to n2 - 2 do
        DrawLineDepth(ACanvas, pts[i], pts[i + 1], Depth);
    ACanvas.Polygon(pts, false, 0, numPts);
    DrawLabels(ACanvas);
  end;
  if AreaLinesPen.Style <> psClear then begin
    ACanvas.Pen.Assign(AreaLinesPen);
    for i := 1 to High(FGraphPoints) - 1 do begin
      a := ProjToRect(FGraphPoints[i], ext2);
      b := ProjToLine(a, z);
      ACanvas.Line(ParentChart.GraphToImage(a), ParentChart.GraphToImage(b));
    end;
  end;
end;

function TAreaSeries.Extent: TDoubleRect;
begin
  Result := inherited Extent;
  if not IsEmpty and UseZeroLevel then
    UpdateMinMax(ZeroLevel, Result.a.Y, Result.b.Y);
end;

function TAreaSeries.GetLabelDirection(AIndex: Integer): TLabelDirection;
const
  DIR: array [Boolean, Boolean] of TLabelDirection =
    ((ldTop, ldBottom), (ldRight, ldLeft));
begin
  Result :=
    DIR[IsRotated, UseZeroLevel and (GetGraphPointY(AIndex) < ZeroLevel)];
end;

procedure TAreaSeries.GetLegendItems(AItems: TChartLegendItems);
begin
  GetLegendItemsRect(AItems, AreaBrush);
end;

function TAreaSeries.GetSeriesColor: TColor;
begin
  Result := FAreaBrush.Color;
end;

function TAreaSeries.IsZeroLevelStored: boolean;
begin
  Result := ZeroLevel <> 0.0;
end;

procedure TAreaSeries.SetAreaBrush(AValue: TBrush);
begin
  FAreaBrush.Assign(AValue);
  UpdateParentChart;
end;

procedure TAreaSeries.SetAreaContourPen(AValue: TPen);
begin
  FAreaContourPen.Assign(AValue);
  UpdateParentChart;
end;

procedure TAreaSeries.SetAreaLinesPen(AValue: TPen);
begin
  FAreaLinesPen.Assign(AValue);
  UpdateParentChart;
end;

procedure TAreaSeries.SetConnectType(AValue: TConnectType);
begin
  if FConnectType = AValue then exit;
  FConnectType := AValue;
  UpdateParentChart;
end;

procedure TAreaSeries.SetSeriesColor(AValue: TColor);
begin
  FAreaBrush.Color := AValue;
end;

procedure TAreaSeries.SetUseZeroLevel(AValue: Boolean);
begin
  if FUseZeroLevel = AValue then exit;
  FUseZeroLevel := AValue;
  UpdateParentChart;
end;

procedure TAreaSeries.SetZeroLevel(AValue: Double);
begin
  if FZeroLevel = AValue then exit;
  FZeroLevel := AValue;
  UpdateParentChart;
end;

{ TUserDrawnSeries }

procedure TUserDrawnSeries.Draw(ACanvas: TCanvas);
begin
  if Assigned(FOnDraw) then
     FOnDraw(ACanvas, FChart.ClipRect);
end;

procedure TUserDrawnSeries.GetBounds(var ABounds: TDoubleRect);
begin
  if Assigned(FOnGetBounds) then
    FOnGetBounds(ABounds);
end;

procedure TUserDrawnSeries.GetLegendItems(AItems: TChartLegendItems);
begin
  Unused(AItems);
end;

function TUserDrawnSeries.IsEmpty: Boolean;
begin
  Result := not Assigned(FOnDraw);
end;

procedure TUserDrawnSeries.SetOnDraw(AValue: TSeriesDrawEvent);
begin
  if TMethod(FOnDraw) = TMethod(AValue) then exit;
  FOnDraw := AValue;
  UpdateParentChart;
end;

procedure TUserDrawnSeries.SetOnGetBounds(AValue: TSeriesGetBoundsEvent);
begin
  if TMethod(FOnGetBounds) = TMethod(AValue) then exit;
  FOnGetBounds := AValue;
  UpdateParentChart;
end;

procedure SkipObsoleteProperties;
const
  STAIRS_NOTE = 'Obsolete, use ConnectType instead';
begin
  RegisterPropertyEditor(
    TypeInfo(Boolean), TLineSeries, 'ShowLines', THiddenPropertyEditor);
  RegisterPropertyToSkip(TAreaSeries, 'Stairs', STAIRS_NOTE, '');
  RegisterPropertyToSkip(TAreaSeries, 'InvertedStairs', STAIRS_NOTE, '');
end;

initialization
  RegisterSeriesClass(TLineSeries, 'Line series');
  RegisterSeriesClass(TAreaSeries, 'Area series');
  RegisterSeriesClass(TBarSeries, 'Bar series');
  RegisterSeriesClass(TPieSeries, 'Pie series');
  RegisterSeriesClass(TUserDrawnSeries, 'User-drawn series');
  RegisterSeriesClass(TConstantLine, 'Constant line');
  {$WARNINGS OFF}RegisterSeriesClass(TLine, '');{$WARNINGS ON}
  SkipObsoleteProperties;

end.
