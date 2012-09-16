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
unit TADrawerOpenGL;

{$H+}

interface

uses
  Classes, FPCanvas, FPImage, GL, GLu, Glut,
  TAChartUtils, TADrawUtils;

type

  { TOpenGLDrawer }

  TOpenGLDrawer = class(TBasicDrawer, IChartDrawer)
  strict private
    FBrushColor: TFPColor;
    FFontColor: TFPColor;
    FPenColor: TFPColor;
    FPenStyle: TFPPenStyle;
    FPenWidth: Integer;
    FPos: TPoint;
    procedure InternalPolyline(
      const APoints: array of TPoint; AStartIndex, ANumPts, AMode: Integer);
    procedure SetBrush(ABrush: TFPCustomBrush);
    procedure SetFont(AFont: TFPCustomFont);
    procedure SetPen(APen: TFPCustomPen);
  strict protected
    function GetFontAngle: Double; override;
    function SimpleTextExtent(const AText: String): TPoint; override;
    procedure SimpleTextOut(AX, AY: Integer; const AText: String); override;
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
    procedure RadialPie(
      AX1, AY1, AX2, AY2: Integer;
      AStartAngle16Deg, AAngleLength16Deg: Integer);
    procedure Rectangle(const ARect: TRect);
    procedure Rectangle(AX1, AY1, AX2, AY2: Integer);
    procedure SetAntialiasingMode(AValue: TChartAntialiasingMode);
    procedure SetBrushColor(AColor: TChartColor);
    procedure SetBrushParams(AStyle: TFPBrushStyle; AColor: TChartColor);
    procedure SetPenParams(AStyle: TFPPenStyle; AColor: TChartColor);
  end;

implementation

procedure ChartGLColor(AColor: TFPColor);
begin
  with AColor do
    glColor4us(red, green, blue, alpha);
end;

{ TOpenGLDrawer }

procedure TOpenGLDrawer.AddToFontOrientation(ADelta: Integer);
begin
  Unused(ADelta);
end;

procedure TOpenGLDrawer.ClippingStart(const AClipRect: TRect);
type
  TGLClipPlaneEqn = record A, B, C, D: GLdouble; end;
var
  cp: TGLClipPlaneEqn;
begin
  cp.A := 1.0;
  cp.D := -AClipRect.Left;
  glClipPlane(GL_CLIP_PLANE0, @cp);
  cp.A := -1.0;
  cp.D := AClipRect.Right;
  glClipPlane(GL_CLIP_PLANE1, @cp);
  cp.A := 0.0;
  cp.B := 1.0;
  cp.D := -AClipRect.Top;
  glClipPlane(GL_CLIP_PLANE2, @cp);
  cp.B := -1.0;
  cp.D := AClipRect.Bottom;
  glClipPlane(GL_CLIP_PLANE3, @cp);
  ClippingStart;
end;

procedure TOpenGLDrawer.ClippingStart;
begin
  glEnable(GL_CLIP_PLANE0);
  glEnable(GL_CLIP_PLANE1);
  glEnable(GL_CLIP_PLANE2);
  glEnable(GL_CLIP_PLANE3);
end;

procedure TOpenGLDrawer.ClippingStop;
begin
  glDisable(GL_CLIP_PLANE0);
  glDisable(GL_CLIP_PLANE1);
  glDisable(GL_CLIP_PLANE2);
  glDisable(GL_CLIP_PLANE3);
end;

procedure TOpenGLDrawer.Ellipse(AX1, AY1, AX2, AY2: Integer);
begin
  Unused(AX1, AY1);
  Unused(AX2, AY2);
  raise EChartError.Create('TOpenGLDrawer.Ellipse not implemented');
end;

procedure TOpenGLDrawer.FillRect(AX1, AY1, AX2, AY2: Integer);
begin
  ChartGLColor(FBrushColor);
  glRecti(AX1, AY1, AX2, AY2);
end;

function TOpenGLDrawer.GetBrushColor: TChartColor;
begin
  Result := FPColorToChartColor(FBrushColor);
end;

function TOpenGLDrawer.GetFontAngle: Double;
begin
  Result := 0.0;
end;

procedure TOpenGLDrawer.InternalPolyline(
  const APoints: array of TPoint; AStartIndex, ANumPts, AMode: Integer);
var
  i: Integer;
begin
  if FPenStyle = psClear then exit;
  glBegin(AMode);
  ChartGLColor(FPenColor);
  glLineWidth(FPenWidth);
  for i := AStartIndex to AStartIndex + ANumPts - 1 do
    glVertex2iv(@APoints[i]);
  glEnd();
end;

procedure TOpenGLDrawer.Line(AX1, AY1, AX2, AY2: Integer);
begin
  if FPenStyle = psClear then exit;
  glBegin(GL_LINES);
  ChartGLColor(FPenColor);
  glLineWidth(FPenWidth);
  glVertex2i(AX1, AY1);
  glVertex2i(AX2, AY2);
  glEnd();
end;

procedure TOpenGLDrawer.Line(const AP1, AP2: TPoint);
begin
  Line(AP1.X, AP1.Y, AP2.X, AP2.Y);
end;

procedure TOpenGLDrawer.LineTo(AX, AY: Integer);
begin
  Line(FPos.X, FPos.Y, AX, AY);
end;

procedure TOpenGLDrawer.MoveTo(AX, AY: Integer);
begin
  FPos := Point(AX, AY);
end;

procedure TOpenGLDrawer.Polygon(
  const APoints: array of TPoint; AStartIndex, ANumPts: Integer);
var
  i: Integer;
begin
  glBegin(GL_POLYGON);
  ChartGLColor(FBrushColor);
  for i := AStartIndex to AStartIndex + ANumPts - 1 do
    glVertex2iv(@APoints[i]);
  glEnd();
  InternalPolyline(APoints, AStartIndex, ANumPts, GL_LINE_LOOP);
end;

procedure TOpenGLDrawer.Polyline(
  const APoints: array of TPoint; AStartIndex, ANumPts: Integer);
begin
  InternalPolyline(APoints, AStartIndex, ANumPts, GL_LINE_STRIP);
end;

procedure TOpenGLDrawer.PrepareSimplePen(AColor: TChartColor);
begin
  FPenWidth := 1;
  FPenColor := FChartColorToFPColorFunc(AColor);
  FPenStyle := psSolid;
end;

procedure TOpenGLDrawer.RadialPie(
  AX1, AY1, AX2, AY2: Integer; AStartAngle16Deg, AAngleLength16Deg: Integer);
begin
  Unused(AX1, AY1);
  Unused(AX2, AY2);
  Unused(AStartAngle16Deg, AAngleLength16Deg);
  raise EChartError.Create('TOpenGLDrawer.RadialPie not implemented');
end;

procedure TOpenGLDrawer.Rectangle(AX1, AY1, AX2, AY2: Integer);
begin
  ChartGLColor(FBrushColor);
  glRecti(AX1, AY1, AX2, AY2);
  if FPenStyle = psClear then exit;
  ChartGLColor(FPenColor);
  glBegin(GL_LINE_LOOP);
  glVertex2i(AX1, AY1);
  glVertex2i(AX2, AY1);
  glVertex2i(AX2, AY2);
  glVertex2i(AX1, AY2);
  glEnd();
end;

procedure TOpenGLDrawer.Rectangle(const ARect: TRect);
begin
  Rectangle(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
end;

procedure TOpenGLDrawer.SetAntialiasingMode(AValue: TChartAntialiasingMode);
begin
  case AValue of
    amOn: begin
      glEnable(GL_LINE_SMOOTH);
      glEnable(GL_POLYGON_SMOOTH);
    end;
    amOff: begin
      glDisable(GL_LINE_SMOOTH);
      glDisable(GL_POLYGON_SMOOTH);
    end;
  end;
end;

procedure TOpenGLDrawer.SetBrush(ABrush: TFPCustomBrush);
begin
  FBrushColor := ABrush.FPColor;
end;

procedure TOpenGLDrawer.SetBrushColor(AColor: TChartColor);
begin
  FBrushColor := FChartColorToFPColorFunc(AColor);
end;

procedure TOpenGLDrawer.SetBrushParams(
  AStyle: TFPBrushStyle; AColor: TChartColor);
begin
  SetBrushColor(AColor);
  Unused(AStyle);
end;

procedure TOpenGLDrawer.SetFont(AFont: TFPCustomFont);
begin
  FFontColor := AFont.FPColor;
end;

procedure TOpenGLDrawer.SetPen(APen: TFPCustomPen);
begin
  FPenWidth := APen.Width;
  FPenColor := APen.FPColor;
  FPenStyle := APen.Style;
end;

procedure TOpenGLDrawer.SetPenParams(AStyle: TFPPenStyle; AColor: TChartColor);
begin
  FPenStyle := AStyle;
  FPenColor := FChartColorToFPColorFunc(AColor);
end;

function TOpenGLDrawer.SimpleTextExtent(const AText: String): TPoint;
const
  F_WIDTH = 8;
  F_HEIGHT = 13;
begin
  Result := Point(F_WIDTH * Length(AText), F_HEIGHT);
end;

procedure TOpenGLDrawer.SimpleTextOut(AX, AY: Integer; const AText: String);
const
  X_OFFSET = 0;
  Y_OFFSET = 10;
var
  i: Integer;
begin
  ChartGLColor(FFontColor);
  glRasterPos2i(AX + X_OFFSET, AY + Y_OFFSET);
  for i := 1 to Length(AText) do
    glutBitmapCharacter(GLUT_BITMAP_8_BY_13, Ord(AText[i]));
end;

end.

