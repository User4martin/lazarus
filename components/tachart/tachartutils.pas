{
 /***************************************************************************
                               TAChartUtils.pas
                               ----------------
              Component Library Standard Graph Utiliity Functions


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

Authors: Luнs Rodrigues, Philippe Martinole, Alexander Klenin

}

unit TAChartUtils;

{$H+}

interface

uses
  Graphics, Types;

const
  MaxColor = 15;
  Colors: array [1..MaxColor] of TColor = (
    clRed, clGreen, clYellow, clBlue, clWhite, clGray, clFuchsia,
    clTeal, clNavy, clMaroon, clLime, clOlive, clPurple, clSilver, clAqua);

type
  TChartCoord = record
    x, y: Double;
    Color: TColor;
    Text: String;
  end;
  PChartCoord = ^TChartCoord;

  TDoublePoint = record
    X, Y: Double;
  end;

  TDoubleRect = record
  case Integer of
    0: (
      a, b: TDoublePoint;
    );
    1: (
      coords: array [1..4] of Double;
    );
  end;

  TPointDistFunc = function (const A, B: TPoint): Integer;

  TAxisScale = (asIncreasing, asDecreasing, asLogIncreasing, asLogDecreasing);

  TPenBrushFont = set of (pbfPen, pbfBrush, pbfFont);

  TSeriesMarksStyle = (
    smsCustom,         { user-defined }
    smsNone,           { no labels }
    smsValue,          { 1234 }
    smsPercent,        { 12 % }
    smsLabel,          { Cars }
    smsLabelPercent,   { Cars 12 % }
    smsLabelValue,     { Cars 1234 }
    smsLegend,         { ? }
    smsPercentTotal,   { 12 % of 1234 }
    smsLabelPercentTotal, { Cars 12 % of 1234 }
    smsXValue);        { 21/6/1996 }

  TSeriesPointerStyle = (
    psNone, psRectangle, psCircle, psCross, psDiagCross, psStar,
    psLowBracket, psHighBracket, psLeftBracket, psRightBracket, psDiamond);

  { TPenBrushFontRecall }

  TPenBrushFontRecall = class
  private
    FPen: TPen;
    FBrush: TBrush;
    FFont: TFont;
    FCanvas: TCanvas;
  public
    constructor Create(ACanvas: TCanvas; AParams: TPenBrushFont);
    destructor Destroy; override;
    procedure Recall;
  end;

const
  // 0-value, 1-percent, 2-label, 3-total, 4-xvalue
  SERIES_MARK_FORMATS: array [TSeriesMarksStyle] of String = (
    '', '',
    '%0:g', // smsValue
    '%1:.2f%%', // smsPercent
    '%2:s', // smsLabel
    '%2:s %1:.2f%%', // smsLabelPercent
    '%2:s %0:g', // smsLabelValue
    '%2:s', // smsLegend: not sure what it means, left for Delphi compatibility
    '%1:.2f%% of %3:g', // smsPercentTotal
    '%1:.2f%% of %3:g', // smsLabelPercentTotal
    '%4:g' // smsXValue
  );

procedure CalculateIntervals(
  AMin, AMax: Double; AxisScale: TAxisScale; out AStart, AStep: Double);

function DoublePoint(const ACoord: TChartCoord): TDoublePoint;

procedure Exchange(var A, B: Integer); overload;
procedure Exchange(var A, B: Double); overload;
procedure Exchange(var A, B: TDoublePoint); overload;

// True if float ranges [A, B] and [C, D] have at least one common point.
function FloatRangesOverlap(A, B, C, D: Double): Boolean; inline;

function PointDist(const A, B: TPoint): Integer; inline;
function PointDistX(const A, B: TPoint): Integer; inline;
function PointDistY(const A, B: TPoint): Integer; inline;

procedure RotateLabel(
  Canvas: TCanvas; x, y: Integer; const St: String; RotDegree: Integer);

operator +(const A: TPoint; B: TSize): TPoint;

implementation

uses
  Math, SysUtils, LCLIntf, LCLType;

procedure CalculateIntervals(
  AMin, AMax: Double; AxisScale: TAxisScale; out AStart, AStep: Double);
var
  extent, extentTmp, stepCount, scale, maxStepCount, m: Double;
  i: Integer;
const
  GOOD_STEPS: array [1..3] of Double = (0.2, 0.5, 1.0);
begin
  extent := AMax - AMin;
  AStep := 1;
  AStart := AMin;
  if extent <= 0 then exit;

  maxStepCount := 0;
  scale := 1.0;
  for i := Low(GOOD_STEPS) to High(GOOD_STEPS) do begin
    extentTmp := extent / GOOD_STEPS[i];
    m := power(10, Round(log10(extentTmp)));
    while extentTmp * m > 10 do
      m *= 0.1;
    while extentTmp * m <= 1 do
      m *= 10;
    stepCount := extentTmp * m;
    if stepCount > maxStepCount then begin
      maxStepCount := stepCount;
      scale := m;
      AStep := GOOD_STEPS[i] / m;
    end;
  end;
  case AxisScale of
    asIncreasing: begin
      // If 0 is in the interval, set it as a mark.
      if InRange(0, AMin, AMax) then
        AStart := 0
      else
        AStart := Round((AMin - AStep) * scale) / scale;
      while AStart > AMin do AStart -= AStep;
    end;
    asDecreasing: begin
      // If 0 is in the interval, set it as a mark.
      if InRange(0, AMin, AMax) then
        AStart := 0
      else
        AStart := Round((AMax + AStep) * scale) / scale;
      while AStart < AMax do AStart += AStep;
    end;
    asLogIncreasing: begin
      // FIXME: asLogIncreasing is still not implemented.
      // The following is the same code for asIncreasing;
      // If 0 is in the interval, set it as a mark.
      if InRange(0, AMin, AMax) then
        AStart := 0
      else
        AStart := Round((AMin - AStep) * scale) / scale;
      while AStart > AMin do AStart -= AStep;
    end;
    asLogDecreasing: begin
      // FIXME: asLogDecreasing is still not implemented.
      // The following is the same code for asIncreasing;
      // If 0 is in the interval, set it as a mark.
      if InRange(0, AMin, AMax) then
        AStart := 0
      else
        AStart := Round((AMax + AStep) * scale) / scale;
      while AStart < AMax do AStart += AStep;
    end;
  end; {case AxisScale}
end;

function DoublePoint(const ACoord: TChartCoord): TDoublePoint;
begin
  Result.X := ACoord.x;
  Result.Y := ACoord.y;
end;

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

procedure Exchange(var A, B: TDoublePoint);
var
  t: TDoublePoint;
begin
  t := A;
  A := B;
  B := t;
end;

function FloatRangesOverlap(A, B, C, D: Double): Boolean; inline;
begin
  Result := (A <= D) and (C <= B);
end;


function PointDist(const A, B: TPoint): Integer;
begin
  Result := Sqr(A.X - B.X) + Sqr(A.Y - B.Y);
end;

function PointDistX(const A, B: TPoint): Integer;
begin
  Result := Abs(A.X - B.X);
end;

function PointDistY(const A, B: TPoint): Integer; inline;
begin
  Result := Abs(A.Y - B.Y);
end;

procedure RotateLabel(
  Canvas: TCanvas; x, y: Integer; const St: String; RotDegree: Integer);
var
  OldFont, NewFont: HFONT;
  LogRec: TLOGFONT;
  DC: HDC;
begin
  with Canvas do begin
    Brush.Style := bsClear;
    GetObject(Font.Handle, SizeOf(LogRec), @LogRec);
    LogRec.lfEscapement   := RotDegree * 10;
    LogRec.lfOrientation  := 0;
    LogRec.lfOutPrecision := OUT_TT_ONLY_PRECIS;
    NewFont := CreateFontIndirect(LogRec);
    DC := Handle;
  end;
  OldFont := SelectObject(DC, NewFont);
  TextOut(DC, X, Y, @St[1], Length(St));
  DeleteObject(SelectObject(DC, OldFont));
end;

operator + (const A: TPoint; B: TSize): TPoint;
begin
  Result.X := A.X + B.cx;
  Result.Y := A.Y + B.cy;
end;

{ TPenBrushFontRecall }

constructor TPenBrushFontRecall.Create(ACanvas: TCanvas; AParams: TPenBrushFont);
begin
  inherited Create;
  FCanvas := ACanvas;
  if pbfPen in AParams then begin
    FPen := TPen.Create;
    FPen.Assign(FCanvas.Pen);
  end;
  if pbfBrush in AParams then begin
    FBrush := TBrush.Create;
    FBrush.Assign(FCanvas.Brush);
  end;
  if pbfFont in AParams then begin
    FFont := TFont.Create;
    FFont.Assign(FCanvas.Font);
  end;
end;

destructor TPenBrushFontRecall.Destroy;
begin
  Recall;
  inherited;
end;

procedure TPenBrushFontRecall.Recall;
begin
  if FPen <> nil then begin
    FCanvas.Pen.Assign(FPen);
    FreeAndNil(FPen);
  end;
  if FBrush <> nil then begin
    FCanvas.Brush.Assign(FBrush);
    FreeAndNil(FBrush);
  end;
  if FFont <> nil then begin
    FCanvas.Font.Assign(FFont);
    FreeAndNil(FFont);
  end;
end;

end.
