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

Authors: Lu�s Rodrigues, Philippe Martinole, Alexander Klenin

}

unit TASeries;

{$H+}

interface

uses
  Classes, Dialogs, Graphics, sysutils,
  TAGraph, TAChartUtils, TATypes;

type
  BarException = class(Exception);

  { TChartSeries }

  TChartSeries = class(TBasicChartSeries)
  private
    // Graph = coordinates in the graph
    FXGraphMin, FYGraphMin: Double;                // Max Graph value of points
    FXGraphMax, FYGraphMax: Double;
    FCoordList: TList;
    FActive: Boolean;
    FMarks: TChartMarks;
    FShowInLegend: Boolean;
    FValuesTotal: Double;
    FValuesTotalValid: Boolean;

    function GetXMinVal: Integer;
    procedure SetActive(Value: Boolean);
    procedure SetMarks(const AValue: TChartMarks);
    procedure SetShowInLegend(Value: Boolean);
    procedure InitBounds(out XMin, YMin, XMax, YMax: Integer);
  protected
    procedure AfterAdd; override;
    procedure StyleChanged(Sender: TObject);
    property Coord: TList read FCoordList;
    procedure DrawLegend(ACanvas: TCanvas; const ARect: TRect); override;
    function GetLegendWidth(ACanvas: TCanvas): Integer; override;
    function GetLegendCount: Integer; override;
    function IsInLegend: Boolean; override;
    procedure UpdateBounds(
      var ANumPoints: Integer; var AXMin, AYMin, AXMax, AYMax: Double); override;
    procedure UpdateParentChart;
    function GetValuesTotal: Double;
    procedure GetCoords(AIndex: Integer; out AG: TDoublePoint; out AI: TPoint);
    function ColorOrDefault(AColor: TColor; ADefault: TColor = clTAColor): TColor;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property XGraphMin: Double read FXGraphMin write FXGraphMin;
    property YGraphMin: Double read FYGraphMin write FYGraphMin;
    property XGraphMax: Double read FXGraphMax write FXGraphMax;
    property YGraphMax: Double read FYGraphMax write FYGraphMax;

    function Count: Integer; override;
    procedure Draw(ACanvas: TCanvas); virtual; abstract;
    procedure DrawIfActive(ACanvas: TCanvas); override;
    function AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint; virtual;
    function Add(AValue: Double; XLabel: String; Color: TColor): Longint; virtual;
    procedure Delete(AIndex: Integer); virtual;
    procedure Clear;
    function FormattedMark(AIndex: integer): String;

  published
    property Active: Boolean read FActive write SetActive default true;
    property Marks: TChartMarks read FMarks write SetMarks;
    property ShowInLegend: Boolean
      read FShowInLegend write SetShowInLegend default true;
    property Title;
  end;

  { TBasicPointSeries }

  TBasicPointSeries = class(TChartSeries)
  private
    FPrevLabelRect: TRect;
  protected
    procedure UpdateMargins(ACanvas: TCanvas; var AMargins: TRect); override;
    procedure DrawLabel(
      ACanvas: TCanvas; AIndex: Integer; const ADataPoint: TPoint;
      ADown: Boolean);
    procedure DrawLabels(ACanvas: TCanvas; ADrawDown: Boolean);
  end;

  { TBarSeries }

  TBarSeries = class(TBasicPointSeries)
  private
    FBarBrush: TBrush;
    FBarPen: TPen;
    FBarWidthPercent: Integer;

    procedure SetBarWidthPercent(Value: Integer);
    procedure SetBarBrush(Value: TBrush);
    procedure SetBarPen(Value: TPen);
    procedure ExamineAllBarSeries(out ATotalNumber, AMyPos: Integer);
  protected
    procedure DrawLegend(ACanvas: TCanvas; const ARect: TRect); override;
    function GetSeriesColor: TColor; override;
    procedure SetSeriesColor(const AValue: TColor); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Draw(ACanvas: TCanvas); override;
    function AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint; override;
  published
    property BarBrush: TBrush read FBarBrush write SetBarBrush;
    property BarPen: TPen read FBarPen write SetBarPen;
    property BarWidthPercent: Integer
      read FBarWidthPercent write SetBarWidthPercent default 70;
    property SeriesColor;
  end;

  { TPieSeries }

  TPieSeries = class(TChartSeries)
  private
    ColorIndex: Integer;
  protected
    procedure DrawLegend(ACanvas: TCanvas; const ARect: TRect); override;
    function GetLegendCount: Integer; override;
    function GetLegendWidth(ACanvas: TCanvas): Integer; override;
    procedure AfterAdd; override;
    function GetSeriesColor: TColor; override;
    procedure SetSeriesColor(const AValue: TColor); override;
  public
    constructor Create(AOwner: TComponent); override;

    procedure Draw(ACanvas: TCanvas); override;
    function AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint; override;
    function AddPie(Value: Double; Text: String; Color: TColor): Longint;
  end;

  { TAreaSeries }

  TAreaSeries = class(TBasicPointSeries)
  private
    FAreaLinesPen: TChartPen;
    FAreaBrush: TBrush;
    FStairs: Boolean;
    FInvertedStairs: Boolean;

    procedure SetAreaBrush(Value: TBrush);
    procedure SetStairs(Value: Boolean);
    procedure SetInvertedStairs(Value: Boolean);
  protected
    procedure DrawLegend(ACanvas: TCanvas; const ARect: TRect); override;
    function GetSeriesColor: TColor; override;
    procedure SetSeriesColor(const AValue: TColor); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    procedure Draw(ACanvas: TCanvas); override;
    function AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint; override;
  published
    property AreaLinesPen: TChartPen read FAreaLinesPen write FAreaLinesPen;
    property AreaBrush: TBrush read FAreaBrush write SetAreaBrush;
    property InvertedStairs: Boolean read FInvertedStairs write SetInvertedStairs;
    property SeriesColor;
    property Stairs: Boolean read FStairs write SetStairs;
  end;

  { TBasicLineSeries }

  TBasicLineSeries  = class(TBasicPointSeries)
  protected
    procedure DrawLegend(ACanvas: TCanvas; const ARect: TRect); override;
  end;

  { TSerie }

  TSerie = class(TBasicLineSeries)
  private
    FPointer: TSeriesPointer;
    FStyle: TPenStyle;
    FSeriesColor: TColor;

    XOfYGraphMin, XOfYGraphMax: Double;          // X max value of points
    FShowPoints: Boolean;
    FShowLines: Boolean;
    UpdateInProgress: Boolean;

    procedure SetShowPoints(Value: Boolean);
    procedure SetShowLines(Value: Boolean);
    procedure SetPointer(Value: TSeriesPointer);
  protected
    procedure AfterAdd; override;
    function GetNearestPoint(
      ADistFunc: TPointDistFunc; const APoint: TPoint;
      out AIndex: Integer; out AImg: TPoint; out AValue: TDoublePoint): Boolean;
      override;
    function GetSeriesColor: TColor; override;
    procedure SetSeriesColor(const AValue: TColor); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    procedure Draw(ACanvas: TCanvas); override;
    function  AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint; override;
    function  GetXValue(AIndex: Integer): Double;
    function  GetYValue(AIndex: Integer): Double;
    procedure SetXValue(AIndex: Integer; Value: Double);
    procedure SetYValue(AIndex: Integer; Value: Double);
    function  GetXImgValue(AIndex: Integer): Integer;
    function  GetYImgValue(AIndex: Integer): Integer;
    procedure GetMin(var X, Y: Double);
    procedure GetMax(var X, Y: Double);
    function  GetXMin: Double;
    function  GetXMax: Double;
    function  GetYMin: Double;
    function  GetYMax: Double;
    procedure SetColor(AIndex: Integer; AColor: TColor);
    function  GetColor(AIndex: Integer): TColor;

    procedure BeginUpdate;
    procedure EndUpdate;

    property XGraphMin;
    property YGraphMin;
    property XGraphMax;
    property YGraphMax;
  published
    property Pointer: TSeriesPointer read FPointer write SetPointer;
    property SeriesColor;
    property ShowLines: Boolean read FShowLines write SetShowLines default true;
    property ShowPoints: Boolean read FShowPoints write SetShowPoints;
  end;

  TLineStyle = (lsVertical, lsHorizontal);

  { TLine }

  TLine = class(TBasicLineSeries)
  private
    FPen: TPen;
    FPosGraph: Double;                      // Graph coordinates of line
    FStyle: TLineStyle;

    procedure SetPen(AValue: TPen);
    procedure SetPos(AValue: Double);
    procedure SetStyle(AValue: TLineStyle);
    procedure Changed;
  protected
    function GetSeriesColor: TColor; override;
    procedure SetSeriesColor(const AValue: TColor); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    procedure Draw(ACanvas: TCanvas); override;

  published
    property LineStyle: TLineStyle read FStyle write SetStyle default lsHorizontal;
    property Pen: TPen read FPen write SetPen;
    property Position: Double read FPosGraph write SetPos;
    property SeriesColor;
  end;

implementation

uses
  GraphMath, Math, Types;

constructor TChartSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  XGraphMin := MaxDouble;
  YGraphMin := MaxDouble;
  XGraphMax := MinDouble;
  YGraphMax := MinDouble;

  FActive := true;
  FShowInLegend := true;
  FCoordList := TList.Create;
  FMarks := TChartMarks.Create(FChart);
end;

destructor TChartSeries.Destroy;
var
  i: Integer;
begin
  for i := 0 to FCoordList.Count - 1 do
    Dispose(PChartCoord(FCoordList.Items[i]));
  FCoordList.Free;
  FMarks.Free;
  UpdateParentChart;

  inherited Destroy;
end;

procedure TChartSeries.DrawIfActive(ACanvas: TCanvas);
begin
  if Active then
    Draw(ACanvas);
end;

procedure TChartSeries.DrawLegend(ACanvas: TCanvas; const ARect: TRect);
begin
  ACanvas.TextOut(ARect.Right + 3, ARect.Top, Title);
end;

function TChartSeries.FormattedMark(AIndex: integer): String;
var
  total, percent: Double;
begin
  total := GetValuesTotal;
  with PChartCoord(FCoordList[AIndex])^ do begin
    if total = 0 then
      percent := 0
    else
      percent := y / total * 100;
    Result := Format(FMarks.Format, [y, percent, Text, total, x]);
  end;
end;

procedure TChartSeries.GetCoords(
  AIndex: Integer; out AG: TDoublePoint; out AI: TPoint);
begin
  AG := DoublePoint(PChartCoord(FCoordList[AIndex])^);
  AI := ParentChart.GraphToImage(AG);
end;

function TChartSeries.GetLegendCount: Integer;
begin
  Result := 1;
end;

function TChartSeries.GetLegendWidth(ACanvas: TCanvas): Integer;
begin
  Result := ACanvas.TextWidth(Title);
end;

function TChartSeries.GetValuesTotal: Double;
var
  i: Integer;
begin
  if not FValuesTotalValid then begin
    FValuesTotal := 0;
    for i := 0 to FCoordList.Count - 1 do
      FValuesTotal += PChartCoord(FCoordList[i])^.y;
    FValuesTotalValid := true;
  end;
  Result := FValuesTotal;
end;

function TChartSeries.GetXMinVal: Integer;
begin
  if Count > 0 then
    Result := Round(PChartCoord(FCoordList[FCoordList.Count-1])^.x)
  else
    Result := 0;
end;

procedure TChartSeries.InitBounds(out XMin, YMin, XMax, YMax: Integer);
begin
  with ParentChart do begin
    XMin := XImageMin;
    XMax := XImageMax;
    YMin := YImageMin;
    YMax := YImageMax;
  end;

  if XMin > XMax then
    Exchange(XMin, XMax);
  if YMin > YMax then
    Exchange(YMin, YMax);
end;

function TChartSeries.IsInLegend: Boolean;
begin
  Result := Active and ShowInLegend;
end;

function TChartSeries.AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint;
var
  pcc: PChartCoord;
begin
  New(pcc);
  pcc^.x := X;
  pcc^.y := Y;
  pcc^.Color := Color;
  pcc^.Text := XLabel;

  // We keep FCoordList ordered by X coordinate.
  // Note that this leads to O(N^2) time except
  // for the case of adding already ordered points.
  // So, is the user wants to add many (>10000) points to a graph,
  // he should pre-sort them to avoid performance penalty.
  Result := FCoordList.Count;
  while (Result > 0) and (PChartCoord(FCoordList.Items[Result - 1])^.x > X) do
    Dec(Result);
  FCoordList.Insert(Result, pcc);
  if FValuesTotalValid then
    FValuesTotal += Y;
end;

procedure TChartSeries.AfterAdd;
begin
  FMarks.SetOwner(FChart);
end;

function TChartSeries.Add(AValue: Double; XLabel: String; Color: TColor): Longint;
var
  XVal: Integer;
begin
  if FCoordList.Count = 0 then
    XVal := 0
  else
    XVal := Round(PChartCoord(FCoordList.Items[FCoordList.Count - 1])^.x);
  Result := AddXY(XVal + 1, AValue, XLabel, Color);
end;


procedure TChartSeries.Delete(AIndex:Integer);
begin
  Dispose(PChartCoord(FCoordList.Items[AIndex]));
  FCoordList.Delete(AIndex);
  FValuesTotalValid := false;
  UpdateParentChart;
end;

procedure TChartSeries.Clear;
begin
  FCoordList.Clear;

  XGraphMin := MaxDouble;
  YGraphMin := MaxDouble;
  XGraphMax := MinDouble;
  YGraphMax := MinDouble;
  FValuesTotalValid := false;

  UpdateParentChart;
end;

function TChartSeries.ColorOrDefault(AColor: TColor; ADefault: TColor): TColor;
begin
  Result := AColor;
  if Result <> clTAColor then exit;
  Result := ADefault;
  if Result <> clTAColor then exit;
  Result := SeriesColor;
end;

function TChartSeries.Count:Integer;
begin
  Result := FCoordList.Count;
end;

procedure TChartSeries.SetActive(Value: Boolean);
begin
  FActive := Value;
  UpdateParentChart;
end;

procedure TChartSeries.SetMarks(const AValue: TChartMarks);
begin
  if FMarks = AValue then exit;
  FMarks.Assign(AValue);
end;

procedure TChartSeries.SetShowInLegend(Value: Boolean);
begin
  FShowInLegend := Value;
  UpdateParentChart;
end;

procedure TChartSeries.StyleChanged(Sender: TObject);
begin
  UpdateParentChart;
end;

procedure TChartSeries.UpdateBounds(
  var ANumPoints: Integer; var AXMin, AYMin, AXMax, AYMax: Double);
begin
  if not Active or (Count = 0) then exit;
  ANumPoints += Count;
  if XGraphMin < AXMin then AXMin := XGraphMin;
  if YGraphMin < AYMin then AYMin := YGraphMin;
  if XGraphMax > AXMax then AXMax := XGraphMax;
  if YGraphMax > AYMax then AYMax := YGraphMax;
end;

procedure TChartSeries.UpdateParentChart;
begin
  if ParentChart <> nil then ParentChart.Invalidate;
end;

{ TSerie }

constructor TSerie.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FPointer := TSeriesPointer.Create(FChart);
  FStyle := psSolid;
  FShowLines := true;

  UpdateInProgress := false;
end;

destructor TSerie.Destroy;
begin
  FPointer.Free;
  inherited Destroy;
end;

procedure TSerie.SetPointer(Value: TSeriesPointer);
begin
  FPointer.Assign(Value);
  UpdateParentChart;
end;

procedure TSerie.SetSeriesColor(const AValue: TColor);
begin
  FSeriesColor := AValue;
end;

procedure TSerie.Draw(ACanvas: TCanvas);
var
  i1, i2: TPoint;
  g1, g2: TDoublePoint;
  XMin, XMax, YMin, YMax: Integer;

  function PrepareLine: Boolean;
  begin
    Result := false;
    if not FShowLines then exit;

    with ParentChart do
      if // line is totally outside the viewport
        (g1.X < XGraphMin) and (g2.X < XGraphMin) or
        (g1.X > XGraphMax) and (g2.X > XGraphMax) or
        (g1.Y < YGraphMin) and (g2.Y < YGraphMin) or
        (g1.Y > YGraphMax) and (g2.Y > YGraphMax)
      then
        exit;

    Result := true;
    // line is totally inside the viewport
    with ParentChart do
      if IsPointInViewPort(g1) and IsPointInViewPort(g2) then
        exit;

    if g1.Y > g2.Y then
      Exchange(g1, g2);

    if g1.Y = g2.Y then begin
      if g1.X > g2.X then
        Exchange(g1, g2);
      if g1.X < ParentChart.XGraphMin then i1.X := ParentChart.XImageMin;
      if g2.X > ParentChart.XGraphMax then i2.X := ParentChart.XImageMax;
    end
    else if g1.X = g2.X then begin
      if g1.Y < ParentChart.YGraphMin then i1.Y := ParentChart.YImageMin;
      if g2.Y > ParentChart.YGraphMax then i2.Y := ParentChart.YImageMax;
    end
    else if ParentChart.LineInViewPort(g1, g2) then begin
      i1 := ParentChart.GraphToImage(g1);
      i2 := ParentChart.GraphToImage(g2);
    end
    else
      Result := false;
  end;

  procedure DrawPoint;
  begin
    if
      FShowPoints and InRange(i1.Y, YMin, YMax) and InRange(i1.X, XMin, XMax)
    then
      FPointer.Draw(ACanvas, i1, SeriesColor);
  end;

var
  i: Integer;
begin
  if Count = 0 then exit;

  InitBounds(XMin, YMin, XMax, YMax);
  ACanvas.Pen.Mode := pmCopy;
  ACanvas.Pen.Width := 1;

  for i := 0 to Count - 2 do begin
    GetCoords(i, g1, i1);
    GetCoords(i + 1, g2, i2);

    if PrepareLine then begin
      ACanvas.Pen.Style := FStyle;
      ACanvas.Pen.Color := PChartCoord(FCoordList[i])^.Color;
      ACanvas.Line(i1, i2);
    end;
    DrawPoint;
  end;

  // Draw last point
  GetCoords(Count - 1, g1, i1);
  DrawPoint;

  DrawLabels(ACanvas, true);
end;


function TSerie.AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint;
begin
  Color := ColorOrDefault(Color);

  Result := inherited AddXY(X, Y, XLabel, Color);

  // Update max
  if X > XGraphMax then XGraphMax := X;
  if X < XGraphMin then XGraphMin := X;
  if Y > YGraphMax then begin
    YGraphMax := Y;
    XOfYGraphMax := X;
  end;
  if Y < YGraphMin then begin
    YGraphMin := Y;
    XOfYGraphMin := X;
  end;

  UpdateParentChart;
end;

procedure TSerie.AfterAdd;
begin
  inherited AfterAdd;
  FPointer.SetOwner(FChart);
end;

function TSerie.GetXValue(AIndex: Integer): Double;
begin
  Result := PChartCoord(FCoordList.Items[AIndex])^.x;
end;

function TSerie.GetYValue(AIndex: Integer): Double;
begin
  Result := PChartCoord(FCoordList.Items[AIndex])^.y;
end;

procedure TSerie.SetXValue(AIndex: Integer; Value: Double);
var
  i: Integer;
  Val: Double;
begin
  if not UpdateInProgress then begin
     if Value < XGraphMin then XGraphMin := Value
     else if Value > XGraphMax then XGraphMax := Value
     else begin
       if PChartCoord(FCoordList.Items[AIndex])^.x = XGraphMax then begin
         PChartCoord(FCoordList.Items[AIndex])^.x := Value;
         if Value < XGraphMax then begin
           XGraphMax := MinDouble;
           for i := 0 to FCoordList.Count - 1 do begin
             Val := PChartCoord(FCoordList.Items[AIndex])^.x;
             if Val > XGraphMax then XGraphMax := Val;
           end;
         end;
       end
       else if PChartCoord(FCoordList.Items[AIndex])^.x = XGraphMin then begin
         PChartCoord(FCoordList.Items[AIndex])^.x := Value;
         if Value > XGraphMin then begin
           XGraphMin := MaxDouble;
           for i := 0 to FCoordList.Count - 1 do begin
             Val := PChartCoord(FCoordList.Items[AIndex])^.x;
             if Val < XGraphMin then XGraphMin := Val;
           end;
         end;
       end;
     end;
  end;

  PChartCoord(FCoordList.Items[AIndex])^.x := Value;

  UpdateParentChart;
end;

procedure TSerie.SetYValue(AIndex: Integer; Value: Double);
var
  i: Integer;
  Val: Double;
begin
  if not UpdateInProgress then begin
    if Value<YGraphMin then YGraphMin:=Value
    else if Value>YGraphMax then YGraphMax:=Value
    else begin
      if PChartCoord(FCoordList.Items[AIndex])^.y=YGraphMax then begin
        PChartCoord(FCoordList.Items[AIndex])^.y:=Value;
        if Value<YGraphMax then begin
          YGraphMax:=MinDouble;
          for i:=0 to FCoordList.Count-1 do begin
            Val:=PChartCoord(FCoordList.Items[AIndex])^.y;
            if Val>YGraphMax then YGraphMax:=Val;
          end;
        end;
      end
      else if PChartCoord(FCoordList.Items[AIndex])^.y=YGraphMin then begin
        PChartCoord(FCoordList.Items[AIndex])^.y:=Value;
        if Value>YGraphMin then begin
          YGraphMin:=MaxDouble;
          for i:=0 to FCoordList.Count-1 do begin
            Val:=PChartCoord(FCoordList.Items[AIndex])^.y;
            if Val<YGraphMin then YGraphMin:=Val;
          end;
        end;
      end;
    end;
  end;

  PChartCoord(FCoordList.Items[AIndex])^.y := Value;

  UpdateParentChart;
end;

function TSerie.GetXImgValue(AIndex: Integer): Integer;
begin
  ParentChart.XGraphToImage(PChartCoord(FCoordList.Items[AIndex])^.x, Result);
end;

function TSerie.GetYImgValue(AIndex: Integer): Integer;
begin
  ParentChart.YGraphToImage(PChartCoord(FCoordList.Items[AIndex])^.y, Result);
end;

function TSerie.GetXMin: Double;
begin
  Result := XGraphMin;
end;

function TSerie.GetXMax: Double;
begin
  Result := XGraphMax;
end;

function TSerie.GetYMin: Double;
begin
  Result := YGraphMin;
end;

function TSerie.GetYMax: Double;
begin
  Result := YGraphMax;
end;

procedure TSerie.GetMax(var X, Y: Double);
begin
  X := XOfYGraphMax;
  Y := YGraphMax;
end;

procedure TSerie.GetMin(var X, Y: Double);
begin
  X := XOfYGraphMin;
  Y := YGraphMin;
end;

function TSerie.GetNearestPoint(
  ADistFunc: TPointDistFunc; const APoint: TPoint;
  out AIndex: Integer; out AImg: TPoint; out AValue: TDoublePoint): Boolean;
var
  dist, minDist, i: Integer;
  pt: TPoint;
begin
  Result := Count > 0;
  minDist := MaxInt;
  for i := 0 to Count - 1 do begin
    pt := Point(GetXImgValue(i), GetYImgValue(i));
    dist := ADistFunc(APoint, pt);
    if dist >= minDist then
      Continue;
    minDist := dist;
    AIndex := i;
    AImg := pt;
    AValue.X := GetXValue(i);
    AValue.Y := GetYValue(i);
  end;
end;

function TSerie.GetSeriesColor: TColor;
begin
  Result := FSeriesColor;
end;

procedure TSerie.SetColor(AIndex: Integer; AColor: TColor);
begin
  PChartCoord(FCoordList.items[AIndex])^.Color := AColor;
end;

function TSerie.GetColor(AIndex: Integer): TColor;
begin
  Result := PChartCoord(FCoordList.items[AIndex])^.Color;
end;

procedure TSerie.SetShowPoints(Value: Boolean);
begin
  FShowPoints := Value;
  UpdateParentChart;
end;

procedure TSerie.SetShowLines(Value: Boolean);
begin
  FShowLines := Value;
  UpdateParentChart;
end;

procedure TSerie.BeginUpdate;
begin
  UpdateInProgress := true;
end;

procedure TSerie.EndUpdate;
var
  i: Integer;
  Val: Double;
begin
  UpdateInProgress := false;

  XGraphMax := MinDouble;
  XGraphMin := MaxDouble;
  for i := 0 to Count - 1 do begin
    Val := PChartCoord(FCoordList.Items[i])^.x;
    if Val > XGraphMax then XGraphMax := Val;
    if Val < XGraphMin then XGraphMin := Val;
  end;

  YGraphMax := MinDouble;
  YGraphMin := MaxDouble;
  for i:=0 to Count-1 do begin
    Val := PChartCoord(FCoordList.Items[i])^.y;
    if Val > YGraphMax then YGraphMax := Val;
    if Val < YGraphMin then YGraphMin := Val;
  end;

  UpdateParentChart;
end;

{ TLine }

procedure TLine.Changed;
begin
  //FIXME: not the best way of doing this
  {if Visible then begin
     NBPointsMax:=NBPointsMax+1;
     case LineStyle of
        lsHorizontal:
           begin
           if Position<YMinSeries then YMinSeries:=Position;
           if Position>YMaxSeries then YMaxSeries:=Position;
           end;
        lsVertical:
           begin
           if Position<XMinSeries then XMinSeries:=Position;
           if Position>XMaxSeries then XMaxSeries:=Position;
           end;
        end;
     end;
  end;}
  case LineStyle of
    lsHorizontal: begin YGraphMin := FPosGraph; YGraphMax := FPosGraph; end;
    lsVertical: begin XGraphMin := FPosGraph; XGraphMax := FPosGraph; end;
  end;
  UpdateParentChart;
end;

constructor TLine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FPen := TPen.Create;
  FPen.OnChange := @StyleChanged;
  LineStyle := lsHorizontal;
end;

destructor TLine.Destroy;
begin
  inherited Destroy;
  FPen.Free;
end;

procedure TLine.SetPen(AValue: TPen);
begin
  FPen.Assign(AValue);
end;

procedure TLine.SetStyle(AValue: TLineStyle);
begin
  if FStyle = AValue then exit;
  FStyle := AValue;
  Changed;
end;

procedure TLine.SetPos(AValue: Double);
begin
  if FPosGraph = AValue then exit;
  FPosGraph := AValue;
  Changed;
end;

procedure TLine.SetSeriesColor(const AValue: TColor);
begin
  FPen.Color := AValue;
end;

procedure TLine.Draw(ACanvas: TCanvas);
var
  xmin, xmax, ymin, ymax, posImage: Integer;
begin
  InitBounds(xmin, ymin, xmax, ymax);

  ACanvas.Pen.Assign(FPen);

  case LineStyle of
    lsHorizontal:
      if InRange(FPosGraph, ParentChart.XGraphMin, ParentChart.XGraphMax) then begin
        ParentChart.YGraphToImage(FPosGraph, posImage);
        ACanvas.MoveTo(xmin, posImage);
        ACanvas.LineTo(xmax, posImage);
      end;
    lsVertical:
      if InRange(FPosGraph, ParentChart.YGraphMin, ParentChart.YGraphMax) then begin
        ParentChart.XGraphToImage(FPosGraph, posImage);
        ACanvas.MoveTo(posImage, ymin);
        ACanvas.LineTo(posImage, ymax);
      end;
  end;
end;

function TLine.GetSeriesColor: TColor;
begin
  Result := FPen.Color;
end;

{ TBasicPointSeries }

procedure TBasicPointSeries.DrawLabel(
  ACanvas: TCanvas; AIndex: Integer; const ADataPoint: TPoint; ADown: Boolean);
var
  labelRect: TRect;
  dummy: TRect = (Left: 0; Top: 0; Right: 0; Bottom: 0);
  labelText: String;
  labelSize: TSize;
begin
  labelText := FormattedMark(AIndex);
  if labelText = '' then exit;

  labelSize := ACanvas.TextExtent(labelText);
  labelRect.Left := ADataPoint.X - labelSize.cx div 2;
  if ADown then
    labelRect.Top := ADataPoint.Y + Marks.Distance
  else
    labelRect.Top := ADataPoint.Y - Marks.Distance - labelSize.cy;
  labelRect.BottomRight := labelRect.TopLeft + labelSize;
  InflateRect(labelRect, MARKS_MARGIN_X, MARKS_MARGIN_Y);
  if
    not IsRectEmpty(FPrevLabelRect) and
    IntersectRect(dummy, labelRect, FPrevLabelRect)
  then
    exit;
  FPrevLabelRect := labelRect;

  // Link between the label and the bar.
  ACanvas.Pen.Assign(Marks.LinkPen);
  with ADataPoint do
    if ADown then
      ACanvas.Line(X, Y, X, labelRect.Top)
    else
      ACanvas.Line(X, Y - 1, X, labelRect.Bottom - 1);

  Marks.DrawLabel(ACanvas, labelRect, labelText);
end;

procedure TBasicPointSeries.DrawLabels(ACanvas: TCanvas; ADrawDown: Boolean);
var
  g: TDoublePoint;
  pt: TPoint;
  i: Integer;
begin
  if not Marks.IsMarkLabelsVisible then exit;
  for i := 0 to Count - 1 do begin
    GetCoords(i, g, pt);
    with ParentChart do
      if IsPointInViewPort(g) then
        DrawLabel(ACanvas, i, pt, ADrawDown and (g.Y < 0));
  end;
end;

procedure TBasicPointSeries.UpdateMargins(ACanvas: TCanvas; var AMargins: TRect);
var
  h: Integer;
begin
  if not Marks.IsMarkLabelsVisible then exit;
  h := ACanvas.TextHeight('0') + Marks.Distance + 2 * MARKS_MARGIN_Y + 4;
  AMargins.Top := Max(AMargins.Top, h);
  AMargins.Bottom := Max(AMargins.Bottom, h);
  FPrevLabelRect := Rect(0, 0, 0, 0);
end;

{ TBarSeries }

constructor TBarSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBarWidthPercent := 70; //70%

  FBarBrush := TBrush.Create;
  FBarBrush.OnChange := @StyleChanged;

  FBarPen := TPen.Create;
  FBarPen.OnChange := @StyleChanged;
  FBarPen.Mode := pmCopy;
  FBarPen.Style := psSolid;
  FBarPen.Width := 1;
  FBarPen.Color := clBlack;
  FBarBrush.Color := clRed;
end;

destructor TBarSeries.Destroy;
begin
  FBarPen.Free;
  FBarBrush.Free;
  inherited Destroy;
end;

procedure TBarSeries.SetBarBrush(Value: TBrush);
begin
  FBarBrush.Assign(Value);
end;

procedure TBarSeries.SetBarPen(Value:TPen);
begin
  FBarPen.Assign(Value);
end;

procedure TBarSeries.SetBarWidthPercent(Value: Integer);
begin
  if (Value < 1) or (Value > 100) then
    raise BarException.Create('Wrong BarWidth Percent')
  else
    FBarWidthPercent := Value;
end;

procedure TBarSeries.SetSeriesColor(const AValue: TColor);
begin
  FBarBrush.Color := AValue;
end;

function TBarSeries.AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint;
begin
  Color := ColorOrDefault(Color);

  Result := inherited AddXY(X, Y, XLabel, Color);

  //update the interval - the 0.6 is a hack to allow the bars to have some space apart
  if X > XGraphMax - 0.6 then XGraphMax := X + 0.6;
  if X < XGraphMin + 0.6 then XGraphMin := X - 0.6;
  //check if the bar is abouve 0 or not
  if Y >= 0 then begin
    if Y > YGraphMax then YGraphMax := Y;
    if YGraphMin > 0 then YGraphMin := 0;
  end else begin
    if Y < YGraphMin then YGraphMin := Y;
    if YGraphMax < 0 then YGraphMax := 0;
  end;

  UpdateParentChart;
end;

procedure TBarSeries.Draw(ACanvas: TCanvas);
var
  barTop: TDoublePoint;
  i, barWidth, totalbarWidth, totalBarSeries, myPos: Integer;
  r: TRect;

  function PrepareBar: Boolean;
  var
    barBottomY: Double;
  begin
    barTop := DoublePoint(PChartCoord(FCoordList.Items[i])^);
    barBottomY := 0;
    if barTop.Y < barBottomY then
      Exchange(barTop.Y, barBottomY);

    with ParentChart do begin
      // Check if bar is in view port.
      Result :=
        InRange(barTop.X, XGraphMin, XGraphMax) and
        FloatRangesOverlap(barBottomY, barTop.Y, YGraphMin, YGraphMax);
      if not Result then exit;

      // Only draw to the limits.
      if barTop.Y > YGraphMax then barTop.Y := YGraphMax;
      if barBottomY < YGraphMin then barBottomY := YGraphMin;

      r.TopLeft := GraphToImage(barTop);
      YGraphToImage(barBottomY, r.Bottom);
    end;

    // Adjust for multiple bar series.
    r.Left += myPos * barWidth - totalbarWidth div 2;
    r.Right := r.Left + barWidth;
  end;

begin
  if FCoordList.Count = 0 then exit;

  totalbarWidth :=
    Round(FBarWidthPercent * 0.01 * ParentChart.ChartWidth / FCoordList.Count);
  ExamineAllBarSeries(totalBarSeries, myPos);
  barWidth := totalbarWidth div totalBarSeries;

  ACanvas.Brush.Assign(BarBrush);
  for i := 0 to FCoordList.Count - 1 do begin
    if not PrepareBar then continue;
    // Draw a line instead of an empty rectangle.
    if r.Bottom = r.Top then Inc(r.Bottom);
    if r.Left = r.Right then Inc(r.Right);

    if (barWidth > 2) and (r.Bottom - r.Top > 2) then
      ACanvas.Pen.Assign(BarPen)
    else begin
      // Bars are too small to distinguish border from interior.
      ACanvas.Pen.Color := BarBrush.Color;
      ACanvas.Pen.Style := psSolid;
    end;

    ACanvas.Rectangle(r);
  end;

  if not Marks.IsMarkLabelsVisible then exit;
  for i := 0 to FCoordList.Count - 1 do
    if PrepareBar then
      DrawLabel(
        ACanvas, i,
        Point((r.Left + r.Right) div 2, ifthen(barTop.Y = 0, r.Bottom, r.Top)),
        barTop.Y = 0);
end;

procedure TBarSeries.DrawLegend(ACanvas: TCanvas; const ARect: TRect);
begin
  inherited DrawLegend(ACanvas, ARect);
  ACanvas.Pen.Color := clBlack;
  ACanvas.Brush.Assign(BarBrush);
  ACanvas.Rectangle(ARect);
end;

procedure TBarSeries.ExamineAllBarSeries(out ATotalNumber, AMyPos: Integer);
var
  i: Integer;
begin
  ATotalNumber := 0;
  AMyPos := -1;
  for i := 0 to ParentChart.SeriesCount - 1 do begin
    if ParentChart.Series[i] = Self then
      AMyPos := ATotalNumber;
    if ParentChart.Series[i] is TBarSeries then
      Inc(ATotalNumber);
  end;
  Assert(AMyPos >= 0);
end;

function TBarSeries.GetSeriesColor: TColor;
begin
  Result := FBarBrush.Color;
end;

{ TPieSeries }

function TPieSeries.AddPie(Value: Double; Text: String; Color: TColor): Longint;
begin
  Result := AddXY(getXMinVal + 1, Value, Text, Color);
end;

function TPieSeries.AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint;
begin
  Color := ColorOrDefault(Color, Colors[ColorIndex]);
  Inc(ColorIndex);
  if ColorIndex > MaxColor then ColorIndex := 1;

  Result := inherited AddXY(X, Y, XLabel, Color);

  UpdateParentChart;
end;

procedure TPieSeries.AfterAdd;
begin
  // disable axis when we have TPie series
  ParentChart.LeftAxis.Visible := false;
  ParentChart.BottomAxis.Visible := false;
end;

constructor TPieSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ColorIndex := 1;
end;

procedure TPieSeries.Draw(ACanvas: TCanvas);
var
  i, radius: Integer;
  prevAngle, angleStep: Double;
  graphCoord: PChartCoord;
  labelWidths, labelHeights: TIntegerDynArray;
  labelTexts: TStringDynArray;
  a, b, center: TPoint;
  r: TRect;
const
  MARGIN = 8;
begin
  if FCoordList.Count = 0 then exit;

  SetLength(labelWidths, FCoordList.Count);
  SetLength(labelHeights, FCoordList.Count);
  SetLength(labelTexts, FCoordList.Count);
  for i := 0 to FCoordList.Count - 1 do begin
    labelTexts[i] := FormattedMark(i);
    with ACanvas.TextExtent(labelTexts[i]) do begin
      labelWidths[i] := cx;
      labelHeights[i] := cy;
    end;
  end;

  with ParentChart do begin
    center.x := (XImageMin + XImageMax) div 2;
    center.y := (YImageMin + YImageMax) div 2;
    // Reserve space for labels.
    radius := Min(
      XImageMax - center.x - MaxIntValue(labelWidths),
      YImageMin - center.y - MaxIntValue(labelHeights));
  end;
  if Marks.IsMarkLabelsVisible then
    radius -= Marks.Distance;
  radius := Max(radius - MARGIN, 0);

  prevAngle := 0;
  for i := 0 to FCoordList.Count - 1 do begin
    // if y < 0 then y := -y;
    // if y = 0 then y := 0.1; // just to simulate tchart when y=0

    graphCoord := FCoordList[i];
    angleStep := graphCoord^.y / GetValuesTotal * 360 * 16;
    ACanvas.Brush.Color := graphCoord^.Color;

    ACanvas.RadialPie(
      center.x - radius, center.y - radius,
      center.x + radius, center.y + radius, round(prevAngle), round(angleStep));

    prevAngle += angleStep;

    if not Marks.IsMarkLabelsVisible then continue;

    a := LineEndPoint(center, prevAngle - angleStep / 2, radius);
    b := LineEndPoint(center, prevAngle - angleStep / 2, radius + Marks.Distance);

    // line from mark to pie
    ACanvas.Pen.Assign(Marks.LinkPen);
    ACanvas.Line(a, b);

    if b.x < center.x then
      b.x -= labelWidths[i];
    if b.y < center.y then
      b.y -= labelHeights[i];

    r := Rect(b.x, b.y, b.x + labelWidths[i], b.y + labelHeights[i]);
    InflateRect(r, MARKS_MARGIN_X, MARKS_MARGIN_Y);
    Marks.DrawLabel(ACanvas, r, labelTexts[i]);
  end;
end;

procedure TPieSeries.DrawLegend(ACanvas: TCanvas; const ARect: TRect);
var
  i: Integer;
  pc, bc: TColor;
  r: TRect;
begin
  r := ARect;
  pc := ACanvas.Pen.Color;
  bc := ACanvas.Brush.Color;
  for i := 0 to Count - 1 do begin
    ACanvas.Pen.Color := pc;
    ACanvas.Brush.Color := bc;
    with PChartCoord(Coord.Items[i])^ do begin
      ACanvas.TextOut(r.Right + 3, r.Top, Format('%1.2g %s', [y, Text]));
      ACanvas.Pen.Color := clBlack;
      ACanvas.Brush.Color := Color;
    end;
    ACanvas.Rectangle(r);
    OffsetRect(r, 0, r.Bottom - r.Top + LEGEND_SPACING);
  end;
end;

function TPieSeries.GetLegendCount: Integer;
begin
  Result := Count;
end;

function TPieSeries.GetLegendWidth(ACanvas: TCanvas): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
    with PChartCoord(Coord.Items[i])^ do
      Result := Max(ACanvas.TextWidth(Format('%1.2g %s', [y, Text])), Result);
end;

function TPieSeries.GetSeriesColor: TColor;
begin
  Result := clBlack; // SeriesColor is meaningless for PieSeries
end;

procedure TPieSeries.SetSeriesColor(const AValue: TColor);
begin
  // SeriesColor is meaningless for PieSeries
end;

{ TAreaSeries }

constructor TAreaSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAreaLinesPen := TChartPen.Create;
  FAreaBrush := TBrush.Create;
end;

destructor TAreaSeries.Destroy;
begin
  FAreaLinesPen.Free;
  FAreaBrush.Free;
  inherited Destroy;
end;

function TAreaSeries.AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint;
begin
  Color := ColorOrDefault(Color);

  Result := inherited AddXY(X, Y, XLabel, Color);

  // Update max
  if X > XGraphMax then XGraphMax := X;
  if X < XGraphMin then XGraphMin := X;
  if Y > YGraphMax then YGraphMax := Y;
  if Y < YGraphMin then YGraphMin := Y;

  UpdateParentChart;
end;

procedure TAreaSeries.SetAreaBrush(Value: TBrush);
begin
  FAreaBrush.Assign(Value);
  UpdateParentChart;
end;

procedure TAreaSeries.SetStairs(Value: Boolean);
begin
  FStairs := Value;
  UpdateParentChart;
end;

procedure TAreaSeries.SetInvertedStairs(Value: Boolean);
begin
  FInvertedStairs := Value;
  UpdateParentChart;
end;

procedure TAreaSeries.SetSeriesColor(const AValue: TColor);
begin
  FAreaBrush.Color := AValue;
end;

procedure TAreaSeries.Draw(ACanvas: TCanvas);
var
  i, xi2a, iy_min: Integer;
  i1, i2: TPoint;
  g1, g2: TDoublePoint;
  XMin, XMax, YMin, YMax: Integer;

  procedure DrawPart;
  begin
    ACanvas.Polygon([Point(i1.X, iy_min), i1, i2, Point(i2.X, iy_min)]);
  end;

begin
  if Count = 0 then exit;

  InitBounds(XMin, YMin, XMax, YMax);

  ACanvas.Pen.Mode := pmCopy;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Width := 1;

  for i := 0 to Count - 2 do begin
    GetCoords(i, g1, i1);
    GetCoords(i + 1, g2, i2);

    iy_min := ParentChart.YImageMin;
    ACanvas.Pen.Color:= clBlack;
    ACanvas.Brush.Color:= PChartCoord(FCoordList.Items[i])^.Color;

    // top line is totally inside the viewport
    if
      ParentChart.IsPointInViewPort(g1) and ParentChart.IsPointInViewPort(g2)
    then begin
      if FStairs then begin
        if FInvertedStairs then
          ACanvas.Polygon([Point(i1.X, iy_min), i1, i2, Point(i2.X, iy_min)])
        else
          ACanvas.Polygon([
            Point(i1.X, iy_min), i1, Point(i2.X, i1.Y), Point(i2.X, iy_min)])
      end else
        DrawPart;
      continue;
    end;

    with ParentChart do
      if // top line is totally outside the viewport
        (g1.X < XGraphMin) and (g2.X < XGraphMin) or
        (g1.X > XGraphMax) and (g2.X > XGraphMax) or
        (g1.Y < YGraphMin) and (g2.Y < YGraphMin)
      then
        continue;

    if g1.Y > g2.Y then begin
      Exchange(g1, g2);
      Exchange(i1.X, i2.X); Exchange(i1.Y, i2.Y);
    end;

    if g1.Y = g2.Y then begin
      if g1.X > g2.X then
        Exchange(g1, g2);
      if g1.X < ParentChart.XGraphMin then i1.X := ParentChart.XImageMin;
      if g2.X > ParentChart.XGraphMax then i2.X := ParentChart.XImageMax;
    end
    else if g1.X = g2.X then begin
      if g1.Y < ParentChart.YGraphMin then i1.Y := ParentChart.YImageMin;
      if g2.Y > ParentChart.YGraphMax then i2.Y := ParentChart.YImageMax;
    end
    else if ParentChart.LineInViewPort(g1, g2) then begin
      xi2a := i2.X;
      i1 := ParentChart.GraphToImage(g1);
      i2 := ParentChart.GraphToImage(g2);
      {if i2.Y <= YMin then} begin
        ACanvas.Polygon([
          Point(i1.X, iy_min), i1, i2, Point(xi2a, YMin), Point(xi2a, iy_min)]);
        continue;
      end;
    end
    else if g2.Y >= ParentChart.YGraphMax then begin
      i1.Y := YMin;
      i2.Y := YMin;
      i1.X := EnsureRange(i1.X, XMin, XMax);
      i2.X := EnsureRange(i2.X, XMin, XMax);
    end;
    DrawPart;
  end;

  DrawLabels(ACanvas, false);
end;

procedure TAreaSeries.DrawLegend(ACanvas: TCanvas; const ARect: TRect);
begin
  inherited DrawLegend(ACanvas, ARect);
  ACanvas.Pen.Color := clBlack;
  ACanvas.Brush.Color := SeriesColor;
  ACanvas.Rectangle(ARect);
end;

function TAreaSeries.GetSeriesColor: TColor;
begin
  Result := FAreaBrush.Color;
end;

{ TBasicLineSeries }

procedure TBasicLineSeries.DrawLegend(ACanvas: TCanvas; const ARect: TRect);
var
  y: Integer;
begin
  inherited DrawLegend(ACanvas, ARect);
  ACanvas.Pen.Color := SeriesColor;
  y := (ARect.Top + ARect.Bottom) div 2;
  ACanvas.MoveTo(ARect.Left, y);
  ACanvas.LineTo(ARect.Right, y);
end;

initialization
  RegisterSeriesClass(TSerie, 'Line series');
  RegisterSeriesClass(TAreaSeries, 'Area series');
  RegisterSeriesClass(TBarSeries, 'Bar series');
  RegisterSeriesClass(TPieSeries, 'Pie series');
  RegisterSeriesClass(TLine, 'Line');

end.
