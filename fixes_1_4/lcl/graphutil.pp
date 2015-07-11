{ $Id$ }
{
 /***************************************************************************
                                graphtype.pp
                                ------------
                          Graphic utility functions.

 ***************************************************************************/

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit GraphUtil;

{$mode objfpc}{$H+}

interface

uses
  Types, Graphics, GraphType, Math, LCLType, LCLIntf;

function ColorToGray(const AColor: TColor): Byte;
procedure ColorToHLS(const AColor: TColor; out H, L, S: Byte);
procedure RGBtoHLS(const R, G, B: Byte; out H, L, S: Byte);
function HLStoColor(const H, L, S: Byte): TColor;
procedure HLStoRGB(const H, L, S: Byte; out R, G, B: Byte);

// specific things:

{
  Draw gradient from top to bottom with parabolic color grow
}
procedure DrawVerticalGradient(Canvas: TCanvas; ARect: TRect; TopColor, BottomColor: TColor);

{
 Draw nice looking window with Title
}
procedure DrawGradientWindow(Canvas: TCanvas; WindowRect: TRect; TitleHeight: Integer; BaseColor: TColor);


{
 Draw arrows
}
type TScrollDirection=(sdLeft,sdRight,sdUp,sdDown);
     TArrowType = (atSolid, atArrows);
const NiceArrowAngle=45*pi/180;

procedure DrawArrow(Canvas:TCanvas;Direction:TScrollDirection; Location: TPoint; Size: Longint; ArrowType: TArrowType=atSolid);
procedure DrawArrow(Canvas:TCanvas;p1,p2: TPoint; ArrowType: TArrowType=atSolid);
procedure DrawArrow(Canvas:TCanvas;p1,p2: TPoint; ArrowLen: longint; ArrowAngleRad: float=NiceArrowAngle; ArrowType: TArrowType=atSolid);

procedure FloodFill(Canvas: TCanvas; X, Y: Integer; lColor: TColor; FillStyle: TFillStyle);

// delphi compatibility
procedure ColorRGBToHLS(clrRGB: COLORREF; var Hue, Luminance, Saturation: Word);
function ColorHLSToRGB(Hue, Luminance, Saturation: Word): TColorRef;
function ColorAdjustLuma(clrRGB: TColor; n: Integer; fScale: BOOL): TColor;
function GetHighLightColor(const Color: TColor; Luminance: Integer = 19): TColor;
function GetShadowColor(const Color: TColor; Luminance: Integer = -50): TColor;

// misc
function NormalizeRect(const R: TRect): TRect;
procedure WaveTo(ADC: HDC; X, Y, R: Integer);

implementation

//TODO: Check code on endianess

procedure ExtractRGB(RGB: TColorRef; var R, G, B: Byte); inline;
begin
  R := RGB and $FF;
  G := (RGB shr 8) and $FF;
  B := (RGB shr 16) and $FF;
end;

function ColorToGray(const AColor: TColor): Byte;
var
  RGB: TColorRef;
begin
  if AColor = clNone
  then RGB := 0
  else RGB := ColorToRGB(AColor);
  Result := Trunc(0.222 * (RGB and $FF) + 0.707 * ((RGB shr 8) and $FF) + 0.071 * (RGB shr 16 and $FF));
end;

procedure ColorToHLS(const AColor: TColor; out H, L, S: Byte);
var
  R, G, B: Byte;
  RGB: TColorRef;
begin
  RGB := ColorToRGB(AColor);
  ExtractRGB(RGB, R, G, B);

  RGBtoHLS(R, G, B, H, L, S);
end;

function HLStoColor(const H, L, S: Byte): TColor;
var
  R, G, B: Byte;
begin
  HLStoRGB(H, L, S, R, G, B);
  Result := R or (G shl 8) or (B shl 16);
end;

const
  HUE_000 = 0;
  HUE_060 = 43;
  HUE_120 = 85;
  HUE_180 = 128;
  HUE_240 = 170;
  HUE_300 = 213;

procedure RGBtoHLS(const R, G, B: Byte; out H, L, S: Byte);
var
  cMax, cMin: Byte;             // max and min RGB values
  Rdelta, Gdelta, Bdelta: Byte; // intermediate value: % of spread from max
  diff: Byte;
begin
  // calculate lightness
  cMax := MaxIntValue([R, G, B]);
  cMin := MinIntValue([R, G, B]);
  L := (integer(cMax) + cMin + 1) div 2;
  diff := cMax - cMin;

  if diff = 0
  then begin
    // r=g=b --> achromatic case
    S := 0;
    H := 0;
  end
  else begin
    // chromatic case
    // saturation
    if L <= 128
    then S := integer(diff * 255) div (cMax + cMin)
    else S := integer(diff * 255) div (510 - cMax - cMin);

    // hue
    Rdelta := (cMax - R);
    Gdelta := (cMax - G);
    Bdelta := (cMax - B);

    if R = cMax
    then H := (HUE_000 + integer(Bdelta - Gdelta) * HUE_060 div diff) and $ff
    else if G = cMax
    then H := HUE_120 + integer(Rdelta - Bdelta) * HUE_060 div diff
    else H := HUE_240 + integer(Gdelta - Rdelta) * HUE_060 div diff;
  end;
end;


procedure HLStoRGB(const H, L, S: Byte; out R, G, B: Byte);

  // utility routine for HLStoRGB
  function HueToRGB(const n1, n2: Byte; Hue: Integer): Byte;
  begin
    if Hue > 255
    then Dec(Hue, 255)
    else if Hue < 0
    then Inc(Hue, 255);
     
    // return r,g, or b value from this tridrant
    case Hue of
      HUE_000..HUE_060 - 1: Result := n1 + (n2 - n1) * Hue div HUE_060;
      HUE_060..HUE_180 - 1: Result := n2;
      HUE_180..HUE_240 - 1: Result := n1 + (n2 - n1) * (HUE_240 - Hue) div HUE_060;
    else
      Result := n1;
    end;
  end;

var
  n1, n2: Byte;
begin
  if S = 0
  then begin
    // achromatic case
    R := L;
    G := L;
    B := L;
  end
  else begin
    // chromatic case
    // set up magic numbers
    if L < 128
    then begin
      n2 := L + (L * S) div 255;
      n1 := 2 * L - n2;
    end
    else begin
      n2 := S + L - (L * S) div 255;
      n1 := 2 * L - n2 - 1;
    end;


    // get RGB
    R := HueToRGB(n1, n2, H + HUE_120);
    G := HueToRGB(n1, n2, H);
    B := HueToRGB(n1, n2, H - HUE_120);
  end;
end;




procedure DrawArrow(Canvas: TCanvas; Direction: TScrollDirection;
  Location: TPoint; Size: Longint; ArrowType: TArrowType);
const ScrollDirectionX:array[TScrollDirection]of longint=(-1,+1,0,0);
      ScrollDirectionY:array[TScrollDirection]of longint=(0,0,-1,+1);
begin
  DrawArrow(Canvas,Location,
            point(ScrollDirectionX[Direction]*size+Location.x,ScrollDirectionY[Direction]*size+Location.y),
            max(5,size div 10),
            NiceArrowAngle,ArrowType);
end;

procedure DrawArrow(Canvas: TCanvas; p1, p2: TPoint; ArrowType: TArrowType);
begin
  DrawArrow(Canvas,p1,p2,round(sqrt(sqr(p1.x-p2.x)+sqr(p1.y-p2.y))/10),NiceArrowAngle,ArrowType);
end;

procedure DrawArrow(Canvas: TCanvas; p1, p2: TPoint; ArrowLen: longint;
  ArrowAngleRad: float; ArrowType: TArrowType);
var {NormalizedLineX, NormalizedLineY, LineLen,} LineAngle: float;
    ArrowPoint1, ArrowPoint2: TPoint;
begin
  LineAngle:=arctan2(p2.y-p1.y,p2.x-p1.x);
  ArrowPoint1.x:=round(ArrowLen*cos(pi+LineAngle-ArrowAngleRad))+p2.x;
  ArrowPoint1.y:=round(ArrowLen*sin(pi+LineAngle-ArrowAngleRad))+p2.y;
  ArrowPoint2.x:=round(ArrowLen*cos(pi+LineAngle+ArrowAngleRad))+p2.x;
  ArrowPoint2.y:=round(ArrowLen*sin(pi+LineAngle+ArrowAngleRad))+p2.y;

  Canvas.Line(p1,p2);

  case ArrowType of
    atSolid: begin
      canvas.Polygon([ArrowPoint1,p2,ArrowPoint2]);
    end;
    atArrows: begin
      Canvas.LineTo(ArrowPoint1.x,ArrowPoint1.y);
      Canvas.Line(p2.x,p2.y,ArrowPoint2.x,ArrowPoint2.y);
    end;
  end;
end;

type
  ByteRA = array [1..1] of byte;
  Bytep = ^ByteRA;
  LongIntRA = array [1..1] of LongInt;
  LongIntp = ^LongIntRA;

procedure FloodFill(Canvas: TCanvas; X, Y: Integer; lColor: TColor;
  FillStyle: TFillStyle);
//Written by Chris Rorden
// Very slow, because uses Canvas.Pixels.
//A simple first-in-first-out circular buffer (the queue) for flood-filling contiguous voxels.
//This algorithm avoids stack problems associated simple recursive algorithms
//http://steve.hollasch.net/cgindex/polygons/floodfill.html [^]
const
  kFill = 0; //pixels we will want to flood fill
  kFillable = 128; //voxels we might flood fill
  kUnfillable = 255; //voxels we can not flood fill
var
  lWid,lHt,lQSz,lQHead,lQTail: integer;
  lQRA: LongIntP;
  lMaskRA: ByteP;
  
  procedure IncQra(var lVal, lQSz: integer);//nested inside FloodFill
  begin
      inc(lVal);
      if lVal >= lQSz then
         lVal := 1;
  end; //nested Proc IncQra
  
  function Pos2XY (lPos: integer): TPoint;
  begin
      result.X := ((lPos-1) mod lWid)+1; //horizontal position
      result.Y := ((lPos-1) div lWid)+1; //vertical position
  end; //nested Proc Pos2XY
  
  procedure TestPixel(lPos: integer);
  begin
       if (lMaskRA^[lPos]=kFillable) then begin
          lMaskRA^[lPos] := kFill;
          lQra^[lQHead] := lPos;
          incQra(lQHead,lQSz);
       end;
  end; //nested Proc TestPixel
  
  procedure RetirePixel; //nested inside FloodFill
  var
     lVal: integer;
     lXY : TPoint;
  begin
     lVal := lQra^[lQTail];
     lXY := Pos2XY(lVal);
     if lXY.Y > 1 then
          TestPixel (lVal-lWid);//pixel above
     if lXY.Y < lHt then
        TestPixel (lVal+lWid);//pixel below
     if lXY.X > 1 then
          TestPixel (lVal-1); //pixel to left
     if lXY.X < lWid then
        TestPixel (lVal+1); //pixel to right
     incQra(lQTail,lQSz); //done with this pixel
  end; //nested proc RetirePixel
  
var
   lTargetColorVal,lDefaultVal: byte;
   lX,lY,lPos: integer;
   lBrushColor: TColor;
begin //FloodFill
  if FillStyle = fsSurface then begin
     //fill only target color with brush - bounded by nontarget color.
     if Canvas.Pixels[X,Y] <> lColor then exit;
     lTargetColorVal := kFillable;
     lDefaultVal := kUnfillable;
  end else begin //fsBorder
      //fill non-target color with brush - bounded by target-color
     if Canvas.Pixels[X,Y] = lColor then exit;
     lTargetColorVal := kUnfillable;
     lDefaultVal := kFillable;
  end;
  //if (lPt < 1) or (lPt > lMaskSz) or (lMaskP[lPt] <> 128) then exit;
  lHt := Canvas.Height;
  lWid := Canvas.Width;
  lQSz := lHt * lWid;
  //Qsz should be more than the most possible simultaneously active pixels
  //Worst case scenario is a click at the center of a 3x3 image: all 9 pixels will be active simultaneously
  //for larger images, only a tiny fraction of pixels will be active at one instance.
  //perhaps lQSz = ((lHt*lWid) div 4) + 32; would be safe and more memory efficient
  if (lHt < 1) or (lWid < 1) then exit;
  getmem(lQra,lQSz*sizeof(longint)); //very wasteful -
  getmem(lMaskRA,lHt*lWid*sizeof(byte));
  for lPos := 1 to (lHt*lWid) do
      lMaskRA^[lPos] := lDefaultVal; //assume all voxels are non targets
  lPos := 0;
  // MG: it is very slow to access the whole (!) canvas with pixels
  for lY := 0 to (lHt-1) do
      for lX := 0 to (lWid-1) do begin
          lPos := lPos + 1;
          if Canvas.Pixels[lX,lY] = lColor then
             lMaskRA^[lPos] := lTargetColorVal;
      end;
  lQHead := 2;
  lQTail := 1;
  lQra^[lQTail] := ((Y * lWid)+X+1); //NOTE: both X and Y start from 0 not 1
  lMaskRA^[lQra^[lQTail]] := kFill;
  RetirePixel;
  while lQHead <> lQTail do
        RetirePixel;
  lBrushColor := Canvas.Brush.Color;
  lPos := 0;
  for lY := 0 to (lHt-1) do
      for lX := 0 to (lWid-1) do begin
          lPos := lPos + 1;
          if lMaskRA^[lPos] = kFill then
             Canvas.Pixels[lX,lY] := lBrushColor;
      end;
  freemem(lMaskRA);
  freemem(lQra);
end;

procedure ColorRGBToHLS(clrRGB: COLORREF; var Hue, Luminance, Saturation: Word);
var
  H, L, S: Byte;
begin
  ColorToHLS(clrRGB, H, L, S);
  Hue := H;
  Luminance := L;
  Saturation := S;
end;

function ColorHLSToRGB(Hue, Luminance, Saturation: Word): TColorRef;
begin
  Result := HLStoColor(Hue, Luminance, Saturation);
end;

function ColorAdjustLuma(clrRGB: TColor; n: Integer; fScale: BOOL): TColor;
var
  H, L, S: Byte;
begin
  // what is fScale?
  ColorToHLS(clrRGB, H, L, S);
  Result := HLStoColor(H, L + n, S);
end;

function GetHighLightColor(const Color: TColor; Luminance: Integer): TColor;
begin
  Result := ColorAdjustLuma(Color, Luminance, False);
end;

function GetShadowColor(const Color: TColor; Luminance: Integer): TColor;
begin
  Result := ColorAdjustLuma(Color, Luminance, False);
end;

function NormalizeRect(const R: TRect): TRect;
begin
  if R.Left <= R.Right then
  begin
    Result.Left := R.Left;
    Result.Right := R.Right;
  end
  else
  begin
    Result.Left := R.Right;
    Result.Right := R.Left;
  end;

  if R.Top <= R.Bottom then
  begin
    Result.Top := R.Top;
    Result.Bottom := R.Bottom;
  end
  else
  begin
    Result.Top := R.Bottom;
    Result.Bottom := R.Top;
  end;
end;

procedure DrawVerticalGradient(Canvas: TCanvas; ARect: TRect; TopColor, BottomColor: TColor);
var
  y, h: Integer;
  r1, g1, b1: byte;
  r2, g2, b2: byte;
  dr, dg, db: integer;

 function GetColor(pos, total: integer): TColor;

   function GetComponent(c1, dc: integer): integer;
   begin
     Result := Round(dc / sqr(total) * sqr(pos) + c1);
   end;

 begin
   Result :=
     GetComponent(r1, dr) or
     (GetComponent(g1, dg) shl 8) or
     (GetComponent(b1, db) shl 16);
 end;

begin
  ExtractRGB(ColorToRGB(TopColor), r1, g1, b1);
  ExtractRGB(ColorToRGB(BottomColor), r2, g2, b2);
  dr := r2 - r1;
  dg := g2 - g1;
  db := b2 - b1;
  h := ARect.Bottom - ARect.Top;
  for y := ARect.Top to ARect.Bottom do
  begin
    Canvas.Pen.Color := GetColor(y - ARect.Top, h);
    Canvas.Line(ARect.Left, y, ARect.Right, y);
  end;
end;

procedure DrawGradientWindow(Canvas: TCanvas; WindowRect: TRect; TitleHeight: Integer; BaseColor: TColor);
begin
  Canvas.Brush.Color := BaseColor;
  Canvas.FrameRect(WindowRect);
  InflateRect(WindowRect, -1, -1);
  WindowRect.Bottom := WindowRect.Top + TitleHeight;
  DrawVerticalGradient(Canvas, WindowRect, GetHighLightColor(BaseColor), GetShadowColor(BaseColor));
end;

procedure WaveTo(ADC: HDC; X, Y, R: Integer);
var
  Direction, Cur: Integer;
  PenPos, Dummy: TPoint;
begin
  dec(R);
  // get the current pos
  MoveToEx(ADC, 0, 0, @PenPos);
  MoveToEx(ADC, PenPos.X, PenPos.Y, @Dummy);

  Direction := 1;
  // vertical wave
  if PenPos.X = X then
  begin
    Cur := PenPos.Y;
    if Cur < Y then
      while (Cur < Y) do
      begin
        X := X + Direction * R;
        LineTo(ADC, X, Cur + R);
        Direction := -Direction;
        inc(Cur, R);
      end
    else
      while (Cur > Y) do
      begin
        X := X + Direction * R;
        LineTo(ADC, X, Cur - R);
        Direction := -Direction;
        dec(Cur, R);
      end;
  end
  else
  // horizontal wave
  begin
    Cur := PenPos.X;
    if (Cur < X) then
      while (Cur < X) do
      begin
        Y := Y + Direction * R;
        LineTo(ADC, Cur + R, Y);
        Direction := -Direction;
        inc(Cur, R);
      end
    else
      while (Cur > X) do
      begin
        Y := Y + Direction * R;
        LineTo(ADC, Cur - R, Y);
        Direction := -Direction;
        dec(Cur, R);
      end;
  end;
end;

end.
