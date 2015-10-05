{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Authors: Alexander Klenin

}
unit TADrawerBGRA;

{$H+}

interface

uses
  BGRABitmap, BGRABitmapTypes, BGRACanvas, Classes, FPCanvas, FPImage,
  TAChartUtils, TADrawUtils;

type

  TBGRABitmapDrawer = class(TBasicDrawer, IChartDrawer)
  strict private
    function BGRAColorOrMono(AColor: TFPColor): TBGRAPixel; inline;
    function Canvas: TBGRACanvas; inline;
    function Opacity: Byte; inline;
    procedure SetBrush(ABrush: TFPCustomBrush);
    procedure SetFont(AFont: TFPCustomFont);
    procedure SetPen(APen: TFPCustomPen);
  strict protected
    FBitmap: TBGRABitmap;

    function GetFontAngle: Double; override;
    procedure SetAntialiasingMode(AValue: TChartAntialiasingMode);
    function SimpleTextExtent(const AText: String): TPoint; override;
    procedure SimpleTextOut(AX, AY: Integer; const AText: String); override;
  public
    constructor Create(ABitmap: TBGRABitmap);
  public
    procedure AddToFontOrientation(ADelta: Integer);
    procedure ClippingStart;
    procedure ClippingStart(const AClipRect: TRect);
    procedure ClippingStop;
    procedure Ellipse(AX1, AY1, AX2, AY2: Integer);
    procedure FillRect(AX1, AY1, AX2, AY2: Integer);
    function GetBrushColor: TChartColor;
    procedure Line(AX1, AY1, AX2, AY2: Integer);
    procedure Line(const AP1, AP2: TPoint);
    procedure LineTo(AX, AY: Integer); override;
    procedure MoveTo(AX, AY: Integer); override;
    procedure Polygon(
      const APoints: array of TPoint; AStartIndex, ANumPts: Integer); override;
    procedure Polyline(
      const APoints: array of TPoint; AStartIndex, ANumPts: Integer);
    procedure PrepareSimplePen(AColor: TChartColor);
    procedure PutImage(AX, AY: Integer; AImage: TFPCustomImage); override;
    procedure PutPixel(AX, AY: Integer; AColor: TChartColor); override;
    procedure RadialPie(
      AX1, AY1, AX2, AY2: Integer;
      AStartAngle16Deg, AAngleLength16Deg: Integer);
    procedure Rectangle(const ARect: TRect);
    procedure Rectangle(AX1, AY1, AX2, AY2: Integer);
    procedure SetBrushColor(AColor: TChartColor);
    procedure SetBrushParams(AStyle: TFPBrushStyle; AColor: TChartColor);
    procedure SetPenParams(AStyle: TFPPenStyle; AColor: TChartColor);
    procedure SetTransparency(ATransparency: TChartTransparency);
  end;

implementation

uses
  BGRAText, Graphics, TAGeometry;

{ TBGRABitmapDrawer }

procedure TBGRABitmapDrawer.AddToFontOrientation(ADelta: Integer);
begin
  with Canvas.Font do
    Orientation := Orientation + ADelta;
end;

function TBGRABitmapDrawer.BGRAColorOrMono(AColor: TFPColor): TBGRAPixel;
begin
  if FMonochromeColor = clTAColor then
    Result := FPColorToBGRA(AColor)
  else
    Result := ColorToBGRA(FMonochromeColor);
end;

function TBGRABitmapDrawer.Canvas: TBGRACanvas;
begin
  Result := FBitmap.CanvasBGRA;
end;

procedure TBGRABitmapDrawer.ClippingStart(const AClipRect: TRect);
begin
  Canvas.ClipRect := AClipRect;
  ClippingStart;
end;

procedure TBGRABitmapDrawer.ClippingStart;
begin
  Canvas.Clipping := true;
end;

procedure TBGRABitmapDrawer.ClippingStop;
begin
  Canvas.Clipping := false;
end;

constructor TBGRABitmapDrawer.Create(ABitmap: TBGRABitmap);
begin
  inherited Create;
  FBitmap := ABitmap;
end;

procedure TBGRABitmapDrawer.Ellipse(AX1, AY1, AX2, AY2: Integer);
begin
  Canvas.Ellipse(AX1, AY1, AX2, AY2);
end;

procedure TBGRABitmapDrawer.FillRect(AX1, AY1, AX2, AY2: Integer);
begin
  Canvas.FillRect(AX1, AY1, AX2, AY2);
end;

function TBGRABitmapDrawer.GetBrushColor: TChartColor;
begin
  Result := TChartColor(Canvas.Brush.Color);
end;

function TBGRABitmapDrawer.GetFontAngle: Double;
begin
  Result := 0.0;
end;

procedure TBGRABitmapDrawer.Line(AX1, AY1, AX2, AY2: Integer);
begin
  Canvas.MoveTo(AX1, AY1);
  Canvas.LineTo(AX2, AY2);
end;

procedure TBGRABitmapDrawer.Line(const AP1, AP2: TPoint);
begin
  Canvas.MoveTo(AP1);
  Canvas.LineTo(AP2);
end;

procedure TBGRABitmapDrawer.LineTo(AX, AY: Integer);
begin
  Canvas.LineTo(AX, AY);
end;

procedure TBGRABitmapDrawer.MoveTo(AX, AY: Integer);
begin
  Canvas.MoveTo(AX, AY);
end;

function TBGRABitmapDrawer.Opacity: Byte;
begin
  Result := 255 - FTransparency;
end;

procedure TBGRABitmapDrawer.Polygon(
  const APoints: array of TPoint; AStartIndex, ANumPts: Integer);
begin
  Canvas.Polygon(APoints, false, AStartIndex, ANumPts);
end;

procedure TBGRABitmapDrawer.Polyline(
  const APoints: array of TPoint; AStartIndex, ANumPts: Integer);
begin
  Canvas.Polyline(APoints, AStartIndex, ANumPts);
end;

procedure TBGRABitmapDrawer.PrepareSimplePen(AColor: TChartColor);
begin
  Canvas.Pen.Color := AColor;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Opacity := Opacity;
end;

procedure TBGRABitmapDrawer.PutImage(AX, AY: Integer; AImage: TFPCustomImage);
var
  x, y: Integer;
begin
  for y := 0 to AImage.Height - 1 do
    for x := 0 to AImage.Width - 1 do
      if AImage[x, y].alpha > 0 then
        Canvas.Colors[AX + x, AY + y] := AImage[x, y];
end;

procedure TBGRABitmapDrawer.PutPixel(AX, AY: Integer; AColor: TChartColor);
begin
  Canvas.Pixels[AX, AY] := AColor;
end;

procedure TBGRABitmapDrawer.RadialPie(
  AX1, AY1, AX2, AY2: Integer; AStartAngle16Deg, AAngleLength16Deg: Integer);
begin
  Canvas.RadialPie(
    AX1, AY1, AX2, AY2, AStartAngle16Deg, AAngleLength16Deg);
end;

procedure TBGRABitmapDrawer.Rectangle(AX1, AY1, AX2, AY2: Integer);
begin
  Canvas.Rectangle(AX1, AY1, AX2, AY2);
end;

procedure TBGRABitmapDrawer.Rectangle(const ARect: TRect);
begin
  with ARect do
    Rectangle(Left, Top, Right, Bottom)
end;

procedure TBGRABitmapDrawer.SetAntialiasingMode(AValue: TChartAntialiasingMode);
begin
  Canvas.AntialiasingMode := TAntialiasingMode(AValue);
  Canvas.Font.Antialiasing := AValue = TADrawUtils.amOn;
end;

procedure TBGRABitmapDrawer.SetBrush(ABrush: TFPCustomBrush);
begin
  Canvas.Brush.BGRAColor := BGRAColorOrMono(ABrush.FPColor);
  Canvas.Brush.Style := ABrush.Style;
  Canvas.Brush.Opacity := Opacity;
end;

procedure TBGRABitmapDrawer.SetBrushColor(AColor: TChartColor);
begin
  Canvas.Brush.Color := ColorOrMono(AColor);
end;

procedure TBGRABitmapDrawer.SetBrushParams(
  AStyle: TFPBrushStyle; AColor: TChartColor);
begin
  Canvas.Brush.Style := AStyle;
  Canvas.Brush.Color := ColorOrMono(AColor);
  Canvas.Brush.Opacity := Opacity;
end;

procedure TBGRABitmapDrawer.SetFont(AFont: TFPCustomFont);
begin
  Canvas.Font.Name := AFont.Name;
  Canvas.Font.Height :=
    FontEmHeightSign * AFont.Size * ScreenInfo.PixelsPerInchY div 72;
  Canvas.Font.Orientation := FGetFontOrientationFunc(AFont);
  Canvas.Font.BGRAColor := BGRAColorOrMono(AFont.FPColor);
  if AFont is TFont then
    Canvas.Font.Style := (AFont as TFont).Style;
  Canvas.Font.Opacity := Opacity;
end;

procedure TBGRABitmapDrawer.SetPen(APen: TFPCustomPen);
begin
  with Canvas.Pen do begin
    Style := APen.Style;
    Width := APen.Width;
    // TODO: Update for FPC 2.8
    if APen is TPen then begin
      JoinStyle := (APen as TPen).JoinStyle;
      EndCap := (APen as TPen).EndCap;
    end;
    BGRAColor := BGRAColorOrMono(APen.FPColor);
    Opacity := Self.Opacity;
  end;
end;

procedure TBGRABitmapDrawer.SetPenParams(
  AStyle: TFPPenStyle; AColor: TChartColor);
begin
  Canvas.Pen.Style := AStyle;
  Canvas.Pen.Color := ColorOrMono(AColor);
  Canvas.Pen.Opacity := Opacity;
end;

procedure TBGRABitmapDrawer.SetTransparency(ATransparency: TChartTransparency);
begin
  inherited;
  Canvas.Brush.Opacity := Opacity;
  Canvas.Font.Opacity := Opacity;
  Canvas.Pen.Opacity := Opacity;
end;

function TBGRABitmapDrawer.SimpleTextExtent(const AText: String): TPoint;
begin
  Result := Canvas.TextExtent(AText);
end;

procedure TBGRABitmapDrawer.SimpleTextOut(AX, AY: Integer; const AText: String);
begin
  Canvas.TextOut(AX, AY, AText);
end;

initialization
  // Suppress incorrect "TAGeometry is unused" hint
  Unused(DoublePoint(0, 0));

end.

