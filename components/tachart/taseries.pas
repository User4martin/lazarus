{
 /***************************************************************************
                               TASeries.pp
                               ----------
                Component Library Standard Graph Series


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

Authors: Lu�s Rodrigues and Philippe Martinole

}

unit TASeries;

{$IFDEF fpc}
{$MODE DELPHI}{$H+}
{$ENDIF}

interface

uses
  {$IFDEF fpc}
  {$ELSE}
  Windows,
  {$ENDIF}
  Classes, Dialogs, Graphics, sysutils, TAGraph;

const
  clTAColor = clScrollBar;

type

  //not completetly implemented (only TPieSeries - not all)
  TSeriesMarksStyle = (
    smsValue,          { 1234 }
    smsPercent,        { 12 % }
    smsLabel,          { Cars }
    smsLabelPercent,   { Cars 12 % }
    smsLabelValue,     { Cars 1234 }
    smsLegend,         { ? }
    smsPercentTotal,   { 12 % of 1234 }
    smsLabelPercentTotal, { Cars 12 % of 1234 }
    smsXValue);        { 21/6/1996 }

  ChartCoord = record
    x, y: Double;
    Color: TColor;
    Text: String;
  end;
  PChartCoord = ^ChartCoord;

  TSeriesPointerStyle = (
    psRectangle, psCircle, psCross, psDiagCross, psStar,
    psLowBracket, psHighBracket);

  BarException = class(Exception);

  { TChartSeries }

  TChartSeries = class(TComponent)
  private
    // Graph = coordinates in the graph
    FXGraphMin, FYGraphMin: Double;                // Max Graph value of points
    FXGraphMax, FYGraphMax: Double;
    FSeriesColor: TColor;
    FTitle: String;
    FCoordList: TList;
    FActive: Boolean;
    FMarks: TSeriesMarksStyle;
    FShowInLegend: Boolean;

    procedure SetActive(Value: Boolean);
    procedure SetMarks(Value: TSeriesMarksStyle);
    function GetXMinVal: Integer;
    procedure SetShowInLegend(Value: Boolean);
    procedure InitBounds(out XMin, YMin, XMax, YMax: Integer);
  protected
    procedure UpdateParentChart;
  public
    ParentChart: TChart;
    procedure Draw(ACanvas: TCanvas); virtual; abstract;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property XGraphMin: Double read FXGraphMin write FXGraphMin;
    property YGraphMin: Double read FYGraphMin write FYGraphMin;
    property XGraphMax: Double read FXGraphMax write FXGraphMax;
    property YGraphMax: Double read FYGraphMax write FYGraphMax;
    property SeriesColor: TColor read FSeriesColor write FSeriesColor default clTAColor;
    property Title: String read FTitle write FTitle;

    function Count: Integer;
    function AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint; virtual;
    function Add(AValue: Double; XLabel: String; Color: TColor): Longint; virtual;
    procedure Delete(Index: Integer); virtual;
    procedure Clear;

    property Coord: TList read FCoordList;
  published
    property MarksStyle: TSeriesMarksStyle read FMarks write SetMarks; //this should be an object
    property Active: Boolean read FActive write SetActive;
    property ShowInLegend: Boolean read FShowInLegend write SetShowInLegend;
  end;

  TSeriesPointer = class(TPersistent)
  private
    FHorizSize, FVertSize: Integer;
    FStyle: TSeriesPointerStyle;
    FPen: TChartPen;
    FBrush: TBrush;
    FVisible: Boolean;
    FOwner: TChartSeries;
    FChanged: TNotifyEvent;

    procedure SetVisible(Value: Boolean);
    procedure SetStyle(Value: TSeriesPointerStyle);
    procedure SetPen(Value: TChartPen);
    procedure SetBrush(Value: TBrush);
    procedure SetHorizSize(Value: Integer);
    procedure SetVertSize(Value: Integer);
  protected
  public
    constructor Create(AOwner: TChartSeries);
    destructor Destroy; override;
    procedure Draw(ACanvas: TCanvas; px, py: Integer; AColor: TColor = clTAColor);

    property ParentSeries: TChartSeries read FOwner;
    procedure Assign(Source: TPersistent); override;
  published
    property Brush: TBrush read FBrush write SetBrush;
    property Pen: TChartPen read FPen write SetPen;
    property Style: TSeriesPointerStyle read FStyle write SetStyle;
    property Visible: Boolean read FVisible write SetVisible;
    property OnChange: TNotifyEvent read FChanged write FChanged;
    property HorizSize: Integer read FHorizSize write SetHorizSize default 4;
    property VertSize: Integer read FVertSize write SetVertSize default 4;

  end;

  TLineStyle = (lsVertical, lsHorizontal);

  TBarSeries = class(TChartSeries)
  private
    FBarBrush: TBrush;
    FBarPen: TPen;
    FBarWidthPercent: Integer;
    FSeriesNumber: Integer;

    procedure SetBarWidthPercent(Value: Integer);
    procedure SetBarBrush(Value: TBrush);
    procedure SetBarPen(Value: TPen);
  protected
    procedure StyleChanged(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    {from parent}
    procedure Draw(ACanvas: TCanvas); override;
    function AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint; override;
  published
    property BarWidthPercent:Integer read FBarWidthPercent write SetBarWidthPercent default 70;
    property BarBrush: TBrush read FBarBrush write SetBarBrush;
    property BarPen: TPen read FBarPen write SetBarPen;
    property Title;
    property Active;
    property SeriesNumber: Integer read FSeriesNumber write FSeriesNumber;
  end;

  TPieSeries = class(TChartSeries)
  private
    ColorIndex: Integer;
    FPiePen: TPen;
    procedure SetPiePen(Value: TPen);
  protected
    procedure StyleChanged(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    {from parent}
    procedure Draw(ACanvas: TCanvas); override;
    function AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint; override;
    function AddPie(Value: Double; Text: String; Color: TColor): Longint;
  published
    property PiePen: TPen read FPiePen write SetPiePen;
    property Title;
    property Active;
  end;

  TAreaSeries = class(TChartSeries)
  private
    FAreaLinesPen: TChartPen;
    FAreaBrush: TBrush;
    FStairs: Boolean;
    FInvertedStairs: Boolean;

    procedure SetAreaBrush(Value: TBrush);
    procedure SetStairs(Value: Boolean);
    procedure SetInvertedStairs(Value: Boolean);
  protected
    procedure StyleChanged(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    {from parent}
    procedure Draw(ACanvas: TCanvas); override;
    function AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint; override;
  published
     property AreaLinesPen: TChartPen read FAreaLinesPen write FAreaLinesPen;
     property AreaBrush: TBrush read FAreaBrush write SetAreaBrush;
     property Stairs: boolean read FStairs write SetStairs;
     property InvertedStairs: boolean read FInvertedStairs write SetInvertedStairs;
     property Title;
     property Active;
  end;

  { TSerie }

  TSerie = class(TChartSeries)
  private
    FPointer: TSeriesPointer;
    FStyle: TPenStyle;

    XOfYGraphMin, XOfYGraphMax: Double;          // X max value of points
    FShowPoints: Boolean;
    FShowLines: Boolean;
    UpdateInProgress: Boolean;

    procedure SetShowPoints(Value: Boolean);
    procedure SetShowLines(Value: Boolean);
    procedure SetPointer(Value: TSeriesPointer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    procedure StyleChanged(Sender: TObject);
    procedure Draw(ACanvas: TCanvas); override;
    function  AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint; override;
    function  GetXValue(Index: Integer): Double;
    function  GetYValue(Index: Integer): Double;
    procedure SetXValue(Index: Integer; Value: Double);
    procedure SetYValue(Index: Integer; Value: Double);
    function  GetXImgValue(Index: Integer): Integer;
    function  GetYImgValue(Index: Integer): Integer;
    procedure GetMin(var X, Y: Double);
    procedure GetMax(var X, Y: Double);
    function  GetXMin: Double;
    function  GetXMax: Double;
    function  GetYMin: Double;
    function  GetYMax: Double;
    procedure SetColor(Index: Integer; AColor: TColor);
    function  GetColor(Index: Integer): TColor;

    procedure BeginUpdate;
    procedure EndUpdate;

    property XGraphMin;
    property YGraphMin;
    property XGraphMax;
    property YGraphMax;
  published
    property Title;
    property Active;

    property ShowPoints: Boolean read FShowPoints write SetShowPoints;
    property ShowLines: Boolean read FShowLines write SetShowLines default true;
    property Pointer: TSeriesPointer read FPointer write SetPointer;
  end;

  TLine = class(TChartSeries)
  private
    FStyle: TLineStyle;

    PosImage: Integer;                     // Image coordinates of line
    PosGraph: Double;                      // Graph coordinates of line

    FPen: TPen;

    procedure SetPos(Value: Double);
    procedure SetPen(Value: TPen);
    procedure SetStyle(Value: TLineStyle);
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    procedure Draw(ACanvas: TCanvas); override;
    procedure StyleChanged(Sender:TObject);

    property  LineStyle: TLineStyle read FStyle write SetStyle;
  published
    property Pen: TPen read FPen write SetPen;
    property Position: Double read PosGraph write SetPos;
    property Active;
  end;

implementation

uses
  math;

procedure Exchange(var A, B: Integer); overload;
var
  t: Integer;
begin
  t := A;
  A := B;
  B := t;
end;

procedure Exchange(var A, B: Double); overload;
var
  t: Double;
begin
  t := A;
  A := B;
  B := t;
end;

constructor TChartSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  XGraphMin := MaxDouble;
  YGraphMin := MaxDouble;
  XGraphMax := MinDouble;
  YGraphMax := MinDouble;

  FActive := true;
  FShowInLegend := true;
  FMarks := smsLabel;
  FCoordList := TList.Create;
end;

destructor TChartSeries.Destroy;
var
  i: Integer;
begin
  if ParentChart <> nil then
    ParentChart.Series.Remove(Self);
  UpdateParentChart;
  ParentChart := nil;

  for i := 0 to FCoordList.Count - 1 do
    Dispose(PChartCoord(FCoordList.Items[i]));
  FCoordList.Free;

  inherited Destroy;
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


procedure TChartSeries.Delete(Index:Integer);
begin
  Dispose(PChartCoord(FCoordList.Items[Index]));
  FCoordList.Delete(Index);
  UpdateParentChart;
end;

procedure TChartSeries.Clear;
begin
  FCoordList.Clear;

  XGraphMin := MaxDouble;
  YGraphMin := MaxDouble;
  XGraphMax := MinDouble;
  YGraphMax := MinDouble;

  UpdateParentChart;
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

procedure TChartSeries.SetShowInLegend(Value: Boolean);
begin
  FShowInLegend := Value;
  UpdateParentChart;
end;

procedure TChartSeries.UpdateParentChart;
begin
  if ParentChart <> nil then ParentChart.Invalidate;
end;

procedure TChartSeries.SetMarks(Value: TSeriesMarksStyle);
begin
  FMarks := Value;
  UpdateParentChart;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TSeriesPointer.SetVisible(Value: Boolean);
begin
  FVisible := Value;
  if Assigned(FChanged) then FChanged(Self);
end;

procedure TSeriesPointer.SetStyle(Value: TSeriesPointerStyle);
begin
  FStyle := Value;
  if Assigned(FChanged) then FChanged(Self);
end;

procedure TSeriesPointer.SetPen(Value: TChartPen);
begin
  FPen.Assign(Value);
  if Assigned(FChanged) then FChanged(Self);
end;

procedure TSeriesPointer.SetBrush(Value: TBrush);
begin
  FBrush.Assign(Value);
  if Assigned(FChanged) then FChanged(Self);
end;

procedure TSeriesPointer.SetHorizSize(Value: Integer);
begin
  FHorizSize := Value;
  if Assigned(FChanged) then FChanged(Self);
end;

procedure TSeriesPointer.SetVertSize(Value: Integer);
begin
  FVertSize := Value;
  if Assigned(FChanged) then FChanged(Self);
end;

constructor TSeriesPointer.Create(AOwner: TChartSeries);
begin
  FBrush := TBrush.Create;
  FBrush.Color := clLime;
  FPen := TChartPen.Create;
  FOwner := AOwner;

  FHorizSize := 4;
  FVertSize  := 4;
end;

destructor TSeriesPointer.Destroy;
begin
  FBrush.Free;
  FPen.Free;
  inherited Destroy;
end;

procedure TSeriesPointer.Draw(ACanvas: TCanvas; px, py: Integer; AColor: TColor);
begin
  with FOwner do begin
    if AColor = clTAColor then
      AColor := SeriesColor;
    ACanvas.Brush.Assign(FBrush);
    ACanvas.Pen.Assign(FPen);

    case FStyle of
      psRectangle: begin
        ACanvas.Brush.Color := AColor;
        ACanvas.Rectangle(px-FHorizSize,py-FVertSize,px+FHorizSize+1,py+FVertSize+1);
      end;
      psCross: begin
        ACanvas.Pen.Color := AColor;
        ACanvas.MoveTo(px-FHorizSize,py);
        ACanvas.LineTo(px+FHorizSize+1,py);
        ACanvas.MoveTo(px,py-FVertSize);
        ACanvas.LineTo(px,py+FVertSize+1);
      end;
      psDiagCross: begin
        ACanvas.Pen.Color := AColor;
        ACanvas.MoveTo(px-FHorizSize,py-FVertSize);
        ACanvas.LineTo(px+FHorizSize+1,py+FVertSize+1);
        ACanvas.MoveTo(px-FHorizSize,py+FVertSize+1);
        ACanvas.LineTo(px+FHorizSize+1,py-FVertSize);
      end;
      psStar: begin
        ACanvas.Pen.Color := AColor;
        ACanvas.MoveTo(px-FHorizSize,py);
        ACanvas.LineTo(px+FHorizSize+1,py);
        ACanvas.MoveTo(px,py-FVertSize);
        ACanvas.LineTo(px,py+FVertSize+1);

        ACanvas.MoveTo(px-FHorizSize,py-FVertSize);
        ACanvas.LineTo(px+FHorizSize+1,py+FVertSize+1);
        ACanvas.MoveTo(px-FHorizSize,py+FVertSize+1);
        ACanvas.LineTo(px+FHorizSize+1,py-FVertSize);
      end;
      psCircle: begin
        ACanvas.Brush.Color := AColor;
        ACanvas.Ellipse(px-FHorizSize,py-FVertSize,px+FHorizSize+1,py+FVertSize+1);
      end;
      psLowBracket: begin
        ACanvas.Pen.Color := AColor;
        ACanvas.MoveTo(px-FHorizSize,py);
        ACanvas.LineTo(px-FHorizSize,py+FVertSize+1);
        ACanvas.LineTo(px+FHorizSize+1,py+FVertSize+1);
        ACanvas.LineTo(px+FHorizSize+1,py-1);
      end;
      psHighBracket: begin
        ACanvas.Pen.Color := AColor;
        ACanvas.MoveTo(px-FHorizSize,py);
        ACanvas.LineTo(px-FHorizSize,py-FVertSize);
        ACanvas.LineTo(px+FHorizSize+1,py-FVertSize);
        ACanvas.LineTo(px+FHorizSize+1,py+1);
      end;
    end;
  end;
end;

procedure TSeriesPointer.Assign(Source: TPersistent);
begin
  if Source is TSeriesPointer then
    with TSeriesPointer(Source) do begin
      FBrush.Assign(Brush);
      FPen.Assign(Pen);
      FStyle := Style;
      FVisible := Visible;
    end;
  inherited Assign(Source);
end;

////////////////////////////////////////////////////////////////////////////////

constructor TSerie.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FPointer := TSeriesPointer.Create(Self);
  FPointer.FStyle := psCross;
  FPointer.OnChange := StyleChanged;

  FStyle := psSolid;

  ShowPoints := false;
  ShowLines := true;

  UpdateInProgress := false;
end;

destructor TSerie.Destroy;
begin
  FPointer.Free;
  inherited Destroy;
end;

procedure TSerie.StyleChanged(Sender: TObject);
begin
  UpdateParentChart;
end;

procedure TSerie.SetPointer(Value: TSeriesPointer);
begin
  FPointer.Assign(Value);
  UpdateParentChart;
end;

procedure TSerie.Draw(ACanvas: TCanvas);
var
  xi1, yi1, xi2, yi2: Integer;
  xg1, yg1, xg2, yg2: Double;
  XMin, XMax, YMin, YMax: Integer;
  chartCoord: PChartCoord;

  function PrepareLine: Boolean;
  begin
    Result := false;
    if not FShowLines then exit;

    with ParentChart do
      if // line is totally outside the viewport
        (xg1 < XGraphMin) and (xg2 < XGraphMin) or
        (xg1 > XGraphMax) and (xg2 > XGraphMax) or
        (yg1 < YGraphMin) and (yg2 < YGraphMin) or
        (yg1 > YGraphMax) and (yg2 > YGraphMax)
      then
        exit;

    Result := true;
    with ParentChart do
      if // line is totally inside the viewport
        InRange(xg1, XGraphMin, XGraphMax) and
        InRange(xg2, XGraphMin, XGraphMax) and
        InRange(yg1, YGraphMin, YGraphMax) and
        InRange(yg2, YGraphMin, YGraphMax)
      then
        exit;

    if yg1 > yg2 then begin
      Exchange(xg1, xg2);
      Exchange(yg1, yg2);
    end;

    if yg1 = yg2 then begin
      if xg1 > xg2 then begin
        Exchange(xg1, xg2);
        Exchange(yg1, yg2);
      end;
      if xg1 < ParentChart.XGraphMin then xi1 := ParentChart.XImageMin;
      if xg2 > ParentChart.XGraphMax then xi2 := ParentChart.XImageMax;
    end
    else if xg1 = xg2 then begin
      if yg1 < ParentChart.YGraphMin then yi1 := ParentChart.YImageMin;
      if yg2 > ParentChart.YGraphMax then yi2 := ParentChart.YImageMax;
    end
    else if ParentChart.LineInViewPort(xg1, yg1, xg2, yg2) then begin
      ParentChart.GraphToImage(xg1, yg1, xi1, yi1);
      ParentChart.GraphToImage(xg2, yg2, xi2, yi2);
    end
    else
      Result := false;
  end;

  procedure DrawPoint;
  begin
    if
      FShowPoints and InRange(yi1, YMin, YMax) and InRange(xi1, XMin, XMax)
    then
      FPointer.Draw(ACanvas, xi1, yi1, SeriesColor);
  end;

  procedure GetCoords(
    AIndex: Integer; out AX, AY: Double; out AXScr, AYScr: Integer);
  begin
    chartCoord := FCoordList.Items[AIndex];
    AX := chartCoord^.x;
    AY := chartCoord^.y;
    ParentChart.GraphToImage(AX, AY, AXScr, AYScr);
  end;

var
  i: Integer;
begin
  if Count = 0 then exit;

  InitBounds(XMin, YMin, XMax, YMax);
  ACanvas.Pen.Mode := pmCopy;
  ACanvas.Pen.Width := 1;

  for i := 0 to Count - 2 do begin
    GetCoords(i, xg1, yg1, xi1, yi1);
    GetCoords(i + 1, xg2, yg2, xi2, yi2);

    if PrepareLine then begin
      ACanvas.Pen.Style := FStyle;
      ACanvas.Pen.Color := chartCoord^.Color;
      ACanvas.MoveTo(xi1, yi1);
      ACanvas.LineTo(xi2, yi2);
    end;
    DrawPoint;
  end;

  // Draw last point
  GetCoords(Count - 1, xg1, yg1, xi1, yi1);
  DrawPoint;
end;


function TSerie.AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint;
begin
  if Color = clTAColor then
    Color := SeriesColor;

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

function TSerie.GetXValue(Index: Integer): Double;
begin
  Result := PChartCoord(FCoordList.Items[Index])^.x;
end;

function TSerie.GetYValue(Index: Integer): Double;
begin
  Result := PChartCoord(FCoordList.Items[Index])^.y;
end;

procedure TSerie.SetXValue(Index: Integer; Value: Double);
var
  i: Integer;
  Val: Double;
begin
  if not UpdateInProgress then begin
     if Value < XGraphMin then XGraphMin := Value
     else if Value > XGraphMax then XGraphMax := Value
     else begin
       if PChartCoord(FCoordList.Items[Index])^.x = XGraphMax then begin
         PChartCoord(FCoordList.Items[Index])^.x := Value;
         if Value < XGraphMax then begin
           XGraphMax := MinDouble;
           for i := 0 to FCoordList.Count - 1 do begin
             Val := PChartCoord(FCoordList.Items[Index])^.x;
             if Val > XGraphMax then XGraphMax := Val;
           end;
         end;
       end
       else if PChartCoord(FCoordList.Items[Index])^.x = XGraphMin then begin
         PChartCoord(FCoordList.Items[Index])^.x := Value;
         if Value > XGraphMin then begin
           XGraphMin := MaxDouble;
           for i := 0 to FCoordList.Count - 1 do begin
             Val := PChartCoord(FCoordList.Items[Index])^.x;
             if Val < XGraphMin then XGraphMin := Val;
           end;
         end;
       end;
     end;
  end;

  PChartCoord(FCoordList.Items[Index])^.x := Value;

  UpdateParentChart;
end;

procedure TSerie.SetYValue(Index: Integer; Value: Double);
var
  i: Integer;
  Val: Double;
begin
  if not UpdateInProgress then begin
    if Value<YGraphMin then YGraphMin:=Value
    else if Value>YGraphMax then YGraphMax:=Value
    else begin
      if PChartCoord(FCoordList.Items[Index])^.y=YGraphMax then begin
        PChartCoord(FCoordList.Items[Index])^.y:=Value;
        if Value<YGraphMax then begin
          YGraphMax:=MinDouble;
          for i:=0 to FCoordList.Count-1 do begin
            Val:=PChartCoord(FCoordList.Items[Index])^.y;
            if Val>YGraphMax then YGraphMax:=Val;
          end;
        end;
      end
      else if PChartCoord(FCoordList.Items[Index])^.y=YGraphMin then begin
        PChartCoord(FCoordList.Items[Index])^.y:=Value;
        if Value>YGraphMin then begin
          YGraphMin:=MaxDouble;
          for i:=0 to FCoordList.Count-1 do begin
            Val:=PChartCoord(FCoordList.Items[Index])^.y;
            if Val<YGraphMin then YGraphMin:=Val;
          end;
        end;
      end;
    end;
  end;

  PChartCoord(FCoordList.Items[Index])^.y := Value;

  UpdateParentChart;
end;

function TSerie.GetXImgValue(Index: Integer): Integer;
begin
  ParentChart.XGraphToImage(PChartCoord(FCoordList.Items[Index])^.x, Result);
end;

function TSerie.GetYImgValue(Index: Integer): Integer;
begin
  ParentChart.YGraphToImage(PChartCoord(FCoordList.Items[Index])^.y, Result);
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

procedure TSerie.SetColor(Index: Integer; AColor: TColor);
begin
  PChartCoord(FCoordList.items[Index])^.Color := AColor;
end;

function TSerie.GetColor(Index: Integer): TColor;
begin
  Result := PChartCoord(FCoordList.items[Index])^.Color;
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

constructor TLine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FPen := TPen.Create;
  FPen.OnChange := StyleChanged;
  LineStyle := lsHorizontal;
end;

destructor TLine.Destroy;
begin
  inherited Destroy;
  FPen.Free;
end;

procedure TLine.StyleChanged(Sender: TObject);
begin
  UpdateParentChart;
end;

procedure TLine.SetPen(Value: TPen);
begin
  FPen.Assign(Value);
end;

procedure TLine.SetStyle(Value: TLineStyle);
begin
  if FStyle <> Value then begin
    FStyle := Value;
    case LineStyle of
      lsHorizontal: begin YGraphMin := PosGraph; YGraphMax := PosGraph; end;
      lsVertical:  begin XGraphMin := PosGraph; XGraphMax := PosGraph; end;
    end;
    UpdateParentChart;
  end;
end;

procedure TLine.SetPos(Value: Double);
begin
  PosGraph := Value;
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
    lsHorizontal: begin YGraphMin := PosGraph; YGraphMax := PosGraph; end;
    lsVertical:  begin XGraphMin := PosGraph; XGraphMax := PosGraph; end;
  end;

  UpdateParentChart;
end;

procedure TLine.Draw;
var
  XMin, XMax, YMin, YMax: Integer;
begin
  InitBounds(XMin, YMin, XMax, YMax);

  ACanvas.Pen.Assign(FPen);

  case LineStyle of
    lsHorizontal:
      if (PosGraph < ParentChart.XGraphMax) and (PosGraph > ParentChart.XGraphMin) then begin
        ParentChart.YGraphToImage(PosGraph, PosImage);
        ACanvas.MoveTo(XMin, PosImage);
        ACanvas.LineTo(XMax, PosImage);
      end;
    lsVertical:
      if (PosGraph < ParentChart.YGraphMax) and (PosGraph > ParentChart.YGraphMin) then begin
        ParentChart.XGraphToImage(PosGraph, PosImage);
        ACanvas.MoveTo(PosImage, YMin);
        ACanvas.LineTo(PosImage, YMax);
      end;
  end;
end;

constructor TBarSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBarWidthPercent := 70; //70%

  FBarBrush := TBrush.Create;
  FBarBrush.OnChange := StyleChanged;

  FBarPen := TPen.Create;
  FBarPen.OnChange := StyleChanged;
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

procedure TBarSeries.StyleChanged(Sender: TObject);
begin
  UpdateParentChart;
end;

procedure TBarSeries.SetBarBrush(Value: TBrush);
begin
  FSeriesColor := Value.Color;
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

function TBarSeries.AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint;
begin
  if Color = clTAColor then Color := SeriesColor;

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
  XMin, XMax: Integer;
  i: Integer;
  graphCoordTop: ChartCoord;
  graphCoordBottom: ChartCoord;
  topX, topY, bottomY: Integer;
  barWidth, TotalbarWidth: Integer;
  bx1, by1, bx2, by2: Integer;

  function BarInViewPort(cTop, cBottom: ChartCoord): Boolean;
  begin //FIXME make cleaner?
    Result :=
      ((cTop.x >= ParentChart.XGraphMin) and (cTop.x <= ParentChart.XGraphMax)) and
      ( ((cTop.y > ParentChart.YGraphMax) and (cBottom.y < ParentChart.YGraphMin))
        or ( (cTop.y < ParentChart.YGraphMax) and (cTop.y > ParentChart.YGraphMin))
        or ( (cBottom.y < ParentChart.YGraphMax) and (cBottom.y > ParentChart.YGraphMin))
      );
  end;

begin
  //no elements to draw
  if FCoordList.Count = 0 then exit;

  //get the limits (for the zoom) ??
  XMin := ParentChart.XImageMin;
  XMax := ParentChart.XImageMax;
  if XMin > XMax then
    Exchange(XMin, XMax);

  // Draw the bars
  ACanvas.Pen.Assign(FBarPen);
  ACanvas.Brush.Assign(FBarBrush);

  //calc the single bar width
  TotalbarWidth :=
    Round((FBarWidthPercent * 0.01) * ParentChart.ChartWidth / FCoordList.Count);
  //to use with multibar -- with is on by default
  barWidth := TotalbarWidth div ParentChart.NumBarSeries;

  for i := 0 to FCoordList.Count - 1 do begin
    //get the top and bottom points
    if ChartCoord(FCoordList.Items[i]^).y >= 0 then begin
      graphCoordTop := ChartCoord(FCoordList.Items[i]^);
      graphCoordBottom.x := graphCoordTop.x;
      graphCoordBottom.y := 0;
    end else begin
      graphCoordBottom := ChartCoord(FCoordList.Items[i]^);
      graphCoordTop.x := graphCoordBottom.x;
      graphCoordTop.y := 0;
    end;

    //check if bar in view port
    if BarInViewPort(graphCoordTop, graphCoordBottom) then begin
      //only draw to the limits
      if graphCoordTop.y > ParentChart.YGraphMax then graphCoordTop.y := ParentChart.YGraphMax;
      if graphCoordBottom.y < ParentChart.YGraphMin then graphCoordBottom.y := ParentChart.YGraphMin;
      //convert from graph to imgs coords
      ParentChart.GraphToImage(graphCoordTop.x, graphCoordTop.y, topX, topY);
      ParentChart.YGraphToImage(graphCoordBottom.y, bottomY);

      //calc coords for bar
{     bx1 := topX-(barWidth div 2);
      by1 := topY;
      bx2 := topX+(barWidth div 2);
      by2 := bottomY;
}
      bx1 := topX - (TotalbarWidth div 2) + SeriesNumber * barWidth;
      by1 := topY;
      bx2 := topX - (TotalbarWidth div 2) + SeriesNumber * barWidth + barWidth;
      by2 := bottomY;

      //FIXME only draw if bar inside image coord (get a better way of doing this)
      if (bx1 >= XMin) and (bx2 <= XMax) then
        if by1 = by2 then begin //draw a line when y=0 FIXME (clean)
          ACanvas.Pen.Color := FBarBrush.Color;
          ACanvas.MoveTo(bx1, by1);
          ACanvas.LineTo(bx2, by2);
          ACanvas.Pen.Assign(FBarPen);
        end else
          ACanvas.Rectangle( bx1, by1, bx2, by2);
    end;
  end; // for
end;

constructor TPieSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ColorIndex := 1;

  FPiePen := TPen.Create;
  FPiePen.OnChange := StyleChanged;
  FPiePen.Mode := pmCopy;
  FPiePen.Style := psSolid;
  FPiePen.Width := 1;
  FPiePen.Color := clBlack;
end;

destructor TPieSeries.Destroy;
begin
  FPiePen.Free;
  inherited Destroy;
end;

procedure TPieSeries.StyleChanged(Sender: TObject);
begin
  UpdateParentChart;
end;

procedure TPieSeries.SetPiePen(Value: TPen);
begin
  FPiePen.Assign(Value);
end;

function TPieSeries.AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint;
begin
  if Color = clTAColor then Color := Colors[ColorIndex];
  Inc(ColorIndex);
  if ColorIndex > MaxColor then ColorIndex := 1;

  Result := inherited AddXY(X, Y, XLabel, Color);

  UpdateParentChart;
end;

function TPieSeries.AddPie(Value: Double; Text: String; Color: TColor): Longint;
begin
  Result := AddXY(getXMinVal + 1, Value, Text, Color);
end;

procedure conv_angle(nOrigoX, nOrigoY, nLen: Integer; Angle: Double; out PX, PY: Integer);
begin
  PX := nOrigoX + round(Cos(Angle) * nLen);
  PY := nOrigoY - round(Sin(Angle) * nLen);
end;

procedure TPieSeries.Draw(ACanvas: TCanvas);
var
  nOrigoX, nOrigoY: LongInt;
  nLen: Integer;
  n100Sum: Double;
  i, AX, AY, BX, BY: Integer;
  curangle, prevangle, midleangle, prop: Double;
  maxtextw: Integer;
  CircleRect: TRect;
  markrect: TRect;
  W: Integer;
  graphCoord: PChartCoord;
  MarkTxtWidth: Integer;
  SPACE_InMarks: integer;
  labelText: String;
const
  TAGSMargin = 20;
  MarkYMargin = 2;
  MarkXMargin = 4;
begin
  SPACE_InMarks := 40;
  //no elements to draw
  if FCoordList.Count = 0 then exit;

  //center the ParentChart on the canvas
  if ParentChart.XImageMax - ParentChart.XImageMin > ParentChart.YImageMin - ParentChart.YImageMax then begin
    W := ParentChart.YImageMin - ParentChart.YImageMax;
    nOrigoX := (ParentChart.XImageMax - ParentChart.XImageMin) div 2 + ParentChart.XImageMin;
    nOrigoY := Round((W - 1.01) / 2) + ParentChart.YImageMax;
  end
  else begin
    W := ParentChart.XImageMax - ParentChart.XImageMin;
    nOrigoX := Round((W - 1.01) / 2) + ParentChart.XImageMin;
    nOrigoY := (ParentChart.YImageMin - ParentChart.YImageMax) div 2 + ParentChart.YImageMax;
  end;

  prevangle := 0;
  maxtextw := 0;
  n100Sum := 0;

  for i := 0 to FCoordList.Count - 1 do begin
    graphCoord := FCoordList[i];
    n100Sum  := n100Sum + graphCoord^.y;
    if ACanvas.TextWidth(graphCoord^.Text) > maxtextw then
      maxtextw := ACanvas.TextWidth(graphCoord^.Text);
  end;

  //we can only draw if enought space for text is saved
  //so we remove maxtextw and MarkXMargin
  nLen := Round((W - maxtextw * 2) / 2);
  CircleRect.Left   := nOrigoX - nLen - TAGSMargin;
  CircleRect.Top    := nOrigoY - nLen - TAGSMargin;
  CircleRect.Right  := nOrigoX + nlen + TAGSMargin;
  CircleRect.Bottom := nOrigoY + nlen + TAGSMargin;

  // ACanvas.Rectangle(CircleRect.Left, CircleRect.Top, CircleRect.Right, CircleRect.Bottom);

  for i := 0 to FCoordList.Count - 1 do begin
    graphCoord := FCoordList[i];
    if graphCoord^.y < 0 then graphCoord^.y := -graphCoord^.y;
    //if graphCoord^.y = 0 then graphCoord^.y := 0.1; //just to simulate tchart when y=0

    conv_angle(nOrigoX, nOrigoY, nLen, prevangle, AX, AY);
    prop := graphCoord^.y / n100Sum;
    curangle := prop * (2 * pi);
    conv_angle(nOrigoX, nOrigoY, nLen, prevangle+curangle, BX, BY);

    ACanvas.Brush.Color := graphCoord^.Color;
    ACanvas.Pie(
      CircleRect.Left, CircleRect.Top, CircleRect.Right, CircleRect.Bottom,
      AX, AY, BX, BY);

    if nLen < SPACE_InMarks then
       SPACE_InMarks := nLen;

    //marks
    midleangle := prevangle + curangle / 2;
    conv_angle(nOrigoX, nOrigoY, nLen + SPACE_InMarks, midleangle, BX, BY);
    conv_angle(nOrigoX, nOrigoY, nLen, midleangle, aX, aY);

    ACanvas.Pen.Color := clWhite;
    ACanvas.MoveTo(ax, ay);
    ACanvas.LineTo(bx, by);
    ACanvas.Pen.Color := clBlack;

    case MarksStyle of
      smsLabel:
        labelText := graphCoord^.Text;
      smsLabelPercent:
        labelText := graphCoord^.Text + Format(' %1.3g%%', [prop * 100]);
    end;
    MarkTxtWidth := ACanvas.TextWidth(labelText);

    //line from mark to pie
    if Bx < nOrigoX then
      markrect.Left := BX - MarkTxtWidth - MarkXMargin
    else
      markrect.Left := BX - MarkXMargin;
    markrect.Right := markrect.Left + MarkTxtWidth + MarkXMargin * 2;

    markrect.Top := BY - MarkYMargin;
    markrect.Bottom := BY + ACanvas.TextHeight(graphCoord^.Text) + MarkYMargin;

    ACanvas.Brush.Color := clYellow;
    ACanvas.Rectangle(markrect);

    if Bx < nOrigoX then BX := BX - MarkTxtWidth;
    ACanvas.Brush.Color := clYellow;
    ACanvas.TextOut(BX, BY, labelText);

    prevangle := prevangle + curangle;
  end; // for
end;


constructor TAreaSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAreaLinesPen := TChartPen.Create;
  FAreaBrush := TBrush.Create;
  FStairs := false;
end;

destructor TAreaSeries.Destroy;
begin
  FAreaLinesPen.Free;
  FAreaBrush.Free;
  inherited Destroy;
end;

function TAreaSeries.AddXY(X, Y: Double; XLabel: String; Color: TColor): Longint;
begin
  if Color = clTAColor then Color := SeriesColor;

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


procedure TAreaSeries.StyleChanged(Sender: TObject);
begin
  UpdateParentChart;
end;


procedure TAreaSeries.Draw(ACanvas: TCanvas);
var
  i: Integer;
  xi1, yi1, xi2, yi2, xi2a: Integer;
  xg1, yg1, xg2, yg2: Double;
  XMin, XMax, YMin, YMax: Integer;
  graphCoord: PChartCoord;
  iy_min: Integer;

  procedure DrawPart;
  begin
    ACanvas.Polygon([
      Point(xi1, iy_min), Point(xi1, yi1), Point(xi2, yi2), Point(xi2, iy_min)]);
  end;

begin
  if Count = 0 then exit;

  InitBounds(XMin, YMin, XMax, YMax);

  with ParentChart do begin
    Canvas.Pen.Mode := pmCopy;
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;
  end;

  for i := 0 to Count - 2 do begin
    graphCoord := FCoordList.Items[i];
    xg1 := graphCoord^.x;
    yg1 := graphCoord^.y;
    ParentChart.GraphToImage(xg1, yg1, xi1, yi1);
    graphCoord := FCoordList.Items[i + 1];
    xg2 := graphCoord^.x;
    yg2 := graphCoord^.y;
    ParentChart.GraphToImage(xg2, yg2, xi2, yi2);

    ParentChart.YGraphToImage(ParentChart.YGraphMin, iy_min);
    ACanvas.Pen.Color:= clBlack;
    ACanvas.Brush.Color:= graphCoord^.Color;

    with ParentChart do
      if // top line is totally inside the viewport
        InRange(xg1, XGraphMin, XGraphMax) and
        InRange(xg2, XGraphMin, XGraphMax) and
        InRange(yg1, YGraphMin, YGraphMax) and
        InRange(yg2, YGraphMin, YGraphMax)
    then begin
      if FStairs then begin
        if FInvertedStairs then
          ACanvas.Polygon([
            Point(xi1, iy_min), Point(xi1, yi2), Point(xi2, yi2), Point(xi2, iy_min)])
        else
          ACanvas.Polygon([
            Point(xi1, iy_min), Point(xi1, yi1), Point(xi2, yi1), Point(xi2, iy_min)])
      end else
        DrawPart;
      continue;
    end;

    with ParentChart do
      if // top line is totally outside the viewport
        (xg1 < XGraphMin) and (xg2 < XGraphMin) or
        (xg1 > XGraphMax) and (xg2 > XGraphMax) or
        (yg1 < YGraphMin) and (yg2 < YGraphMin)
      then
        continue;

    if yg1 > yg2 then begin
      Exchange(xg1, xg2); Exchange(yg1, yg2);
      Exchange(xi1, xi2); Exchange(yi1, yi2);
    end;

    if yg1 = yg2 then begin
      if xg1 > xg2 then begin
        Exchange(xg1, xg2);
        Exchange(yg1, yg2);
      end;
      if xg1 < ParentChart.XGraphMin then xi1 := ParentChart.XImageMin;
      if xg2 > ParentChart.XGraphMax then xi2 := ParentChart.XImageMax;
    end
    else if xg1 = xg2 then begin
      if yg1 < ParentChart.YGraphMin then yi1 := ParentChart.YImageMin;
      if yg2 > ParentChart.YGraphMax then yi2 := ParentChart.YImageMax;
    end
    else if ParentChart.LineInViewPort(xg1, yg1, xg2, yg2) then begin
      xi2a := xi2;
      ParentChart.GraphToImage(xg1, yg1, xi1, yi1);
      ParentChart.GraphToImage(xg2, yg2, xi2, yi2);
      if yi2 <= YMin then begin
        ACanvas.Polygon([
          Point(xi1, iy_min), Point(xi1, yi1), Point(xi2, yi2),
          Point(xi2a, YMin), Point(xi2a, iy_min)]);
        continue;
      end;
    end
    else if yg2 >= ParentChart.YGraphMax then begin
      yi1 := YMin;
      yi2 := YMin;
      xi1 := EnsureRange(xi1, XMin, XMax);
      xi2 := EnsureRange(xi2, XMin, XMax);
    end;
    DrawPart;
  end;
end;

end.
