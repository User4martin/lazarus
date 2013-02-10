{
 /***************************************************************************
                              lazcanvas.pas
                              ---------------

 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Author: Felipe Monteiro de Carvalho

  Abstract:
    Classes and functions for extending TFPImageCanvas to support more stretching
    filters and to support all features from the LCL TCanvas

    TLazCanvas also fixes various small problems and incompatibilities between
    TFPImageCanvas versions, making the interface smoother for its users

  Dont use anything from the LCL here as this unit should be kept strictly independent
  only LCLProc for DebugLn is allowed, but only during debuging
}
unit lazcanvas;

{$mode objfpc}{$H+}
{.$define lazcanvas_debug}

interface

uses
  // RTL
  Classes, SysUtils, contnrs, Math,
  // FCL-Image
  fpimgcanv, fpcanvas, fpimage, clipping, pixtools, fppixlcanv,
  // regions
  lazregions
  {$ifdef lazcanvas_debug}, LCLProc{$endif};

type

  { TFPSharpInterpolation }

  // This does a very sharp and square interpolation for stretching,
  // similar to StretchBlt from the Windows API
  TFPSharpInterpolation = class (TFPCustomInterpolation)
  protected
    procedure Execute (x,y,w,h : integer); override;
  end;

  { TLazCanvasState }

  TLazCanvasState = class
  public
    Brush: TFPCustomBrush;
    Pen: TFPCustomPen;
    Font: TFPCustomFont;
    BaseWindowOrg: TPoint;
    WindowOrg: TPoint;
    Clipping: Boolean;
    ClipRegion: TFPCustomRegion;
    destructor Destroy; override;
  end;

  { TLazCanvas }

  TLazCanvas = class(TFPImageCanvas)
  private
    FAssignedBrush: TFPCustomBrush;
    FAssignedFont: TFPCustomFont;
    FAssignedPen: TFPCustomPen;
    FBaseWindowOrg: TPoint;
    {$if defined(ver2_4) or defined(ver2_5) or defined(ver2_6)}
    FLazClipRegion: TFPCustomRegion;
    {$endif}
    FWindowOrg: TPoint; // already in absolute coords with BaseWindowOrg summed up
    GraphicStateList: TFPList; // TLazCanvasState
    function GetAssignedBrush: TFPCustomBrush;
    function GetAssignedPen: TFPCustomPen;
    function GetAssignedFont: TFPCustomFont;
    function GetWindowOrg: TPoint;
    procedure SetWindowOrg(AValue: TPoint);
  protected
    procedure SetColor (x,y:integer; const AValue:TFPColor); override;
    function DoCreateDefaultFont : TFPCustomFont; override;
    // Routines broken/unimplemented/incompatible in FPC
    procedure DoRectangle (const Bounds:TRect); override;
    procedure DoRectangleFill (const Bounds:TRect); override;
    procedure DoPolygonFill (const points:array of TPoint); override;
    // Routines which don't work with out extended clipping in TFPImageCanvas
    procedure DoLine (x1,y1,x2,y2:integer); override;
  public
    HasNoImage: Boolean;
    NativeDC: PtrInt; // Utilized by LCL-CustomDrawn
    ExtraFontData: TObject; // Utilized by LCL-CustomDrawn
    constructor create (AnImage : TFPCustomImage);
    destructor destroy; override;
    procedure SetLazClipRegion(ARegion: TLazRegion);
    // Canvas states list
    function SaveState: Integer;
    procedure RestoreState(AIndex: Integer);
    // A simple operation to bring the Canvas in the default LCL TCanvas state
    procedure ResetCanvasState;
    // Alpha blending operations
    procedure AlphaBlend(ASource: TLazCanvas;
      const ADestX, ADestY, ASourceX, ASourceY, ASourceWidth, ASourceHeight: Integer);
    procedure AlphaBlendIgnoringDestPixels(ASource: TLazCanvas;
      const ADestX, ADestY, ASourceX, ASourceY, ASourceWidth, ASourceHeight: Integer);
    procedure CanvasCopyRect(ASource: TLazCanvas;
      const ADestX, ADestY, ASourceX, ASourceY, ASourceWidth, ASourceHeight: Integer);
    // Compatibility with older FPC versions
    {$if defined(ver2_4) or defined(ver2_5)}
    procedure FillRect(const ARect: TRect);
    procedure FillRect(X1,Y1,X2,Y2: Integer);
    {$endif}
    // Fills the entire drawing with a color
    // AIgnoreClippingAndWindowOrg speeds up the drawing a lot, but it is dangerous,
    // don't use it unless you know what you are doing!
    procedure FillColor(AColor: TFPColor; AIgnoreClippingAndWindowOrg: Boolean = False);
    // Utilized by LCLIntf.SelectObject and by RestoreState
    // This needed to be added because Pen/Brush.Assign raises exceptions
    procedure AssignPenData(APen: TFPCustomPen);
    procedure AssignBrushData(ABrush: TFPCustomBrush);
    procedure AssignFontData(AFont: TFPCustomFont);
    // These properties are utilized to implement LCLIntf.SelectObject
    // to keep track of which brush handle was assigned to this canvas
    // They are not utilized by TLazCanvas itself
    property AssignedPen: TFPCustomPen read GetAssignedPen write FAssignedPen;
    property AssignedBrush: TFPCustomBrush read GetAssignedBrush write FAssignedBrush;
    property AssignedFont: TFPCustomFont read GetAssignedFont write FAssignedFont;
    //
    // SetWindowOrg operations will be relative to BaseWindowOrg,
    // This is very useful for implementing the non-native wincontrol,
    // because operations of SetWindowOrg inside a non-native wincontrol will be
    // based upon the BaseWindowOrg which is set relative to the Form canvas
    property BaseWindowOrg: TPoint read FBaseWindowOrg write FBaseWindowOrg;
    {$if defined(ver2_4) or defined(ver2_5) or defined(ver2_6)}
    property ClipRegion: TFPCustomRegion read FLazClipRegion write FLazClipRegion;
    {$endif}
    property WindowOrg: TPoint read GetWindowOrg write SetWindowOrg;
  end;

implementation

{ TLazCanvasState }

destructor TLazCanvasState.Destroy;
begin
  if Brush <> nil then Brush.Free;
  if Pen <> nil then Pen.Free;
  inherited Destroy;
end;

{ TLazCanvas }

function TLazCanvas.GetAssignedBrush: TFPCustomBrush;
begin
  if FAssignedBrush = nil then
    Result := TFPEmptyBrush.Create
  else
    Result := FAssignedBrush;
end;

function TLazCanvas.GetAssignedPen: TFPCustomPen;
begin
  if FAssignedPen = nil then
    Result := TFPEmptyPen.Create
  else
    Result := FAssignedPen;
end;

function TLazCanvas.GetAssignedFont: TFPCustomFont;
begin
  if FAssignedFont = nil then
    Result := TFPEmptyFont.Create
  else
    Result := FAssignedFont;
end;

function TLazCanvas.GetWindowOrg: TPoint;
begin
  Result := Point(FWindowOrg.X-FBaseWindowOrg.X, FWindowOrg.Y-FBaseWindowOrg.Y)
end;

procedure TLazCanvas.SetWindowOrg(AValue: TPoint);
begin
  FWindowOrg.X := AValue.X+FBaseWindowOrg.X;
  FWindowOrg.Y := AValue.Y+FBaseWindowOrg.Y;
  {$ifdef lazcanvas_debug}
  DebugLn(Format('[TLazCanvas.SetWindowOrg] AValue=%d,%d BaseWindowOrg=%d,%d', [AValue.X, AValue.Y, FBaseWindowOrg.X, FBaseWindowOrg.y]));
  {$endif}
end;

procedure TLazCanvas.SetColor(x, y: integer; const AValue: TFPColor);
var
  lx, ly: Integer;
begin
  lx := x + FWindowOrg.X;
  ly := y + FWindowOrg.Y;
  {$if defined(ver2_4) or defined(ver2_5) or defined(ver2_6)}
  if Clipping and (not FLazClipRegion.IsPointInRegion(lx, ly)) then
    Exit;
  if (lx >= 0) and (lx < width) and (ly >= 0) and (ly < height) then
      Image.Colors[lx,ly] := AValue;
  {$else}
  if Clipping and (not FClipRegion.IsPointInRegion(lx, ly)) then
    Exit;
  if (lx >= 0) and (lx < width) and (ly >= 0) and (ly < height) then
      FImage.Colors[lx,ly] := AValue;
  {$endif}
end;

function TLazCanvas.DoCreateDefaultFont: TFPCustomFont;
begin
  result := TFPEmptyFont.Create;
  Result.Size := 0; // To allow it to use the default platform size
  Result.FPColor := colBlack;
end;

// The coordinates utilized by DoRectangle in fcl-image are not TCanvas compatible
// so we reimplement it here
procedure TLazCanvas.DoRectangle (const Bounds:TRect);
var pattern : longword;

  procedure CheckLine (x1,y1, x2,y2 : integer);
  begin
//    if clipping then
//      CheckLineClipping (ClipRect, x1,y1, x2,y2);
    if x1 >= 0 then
      DrawSolidLine (self, x1,y1, x2,y2, Pen.FPColor)
  end;

  procedure CheckPLine (x1,y1, x2,y2 : integer);
  begin
//    if clipping then
//      CheckLineClipping (ClipRect, x1,y1, x2,y2);
    if x1 >= 0 then
      DrawPatternLine (self, x1,y1, x2,y2, pattern, Pen.FPColor)
  end;

var b : TRect;
    r : integer;

begin
  b := bounds;
  b.right := b.Right-1;
  b.bottom := b.bottom-1;
  if pen.style = psSolid then
    for r := 1 to pen.width do
      begin
      with b do
        begin
        CheckLine (left,top,left,bottom);
        CheckLine (left,bottom,right,bottom);
        CheckLine (right,bottom,right,top);
        CheckLine (right,top,left,top);
        end;
      DecRect (b);
      end
  else if pen.style <> psClear then
    begin
    if pen.style = psPattern then
      pattern := Pen.pattern
    else
      pattern := PenPatterns[pen.style];
    with b do
      begin
      CheckPLine (left,top,left,bottom);
      CheckPLine (left,bottom,right,bottom);
      CheckPLine (right,bottom,right,top);
      CheckPLine (right,top,left,top);
      end;
    end;
end;

procedure TLazCanvas.DoRectangleFill(const Bounds: TRect);
var b : TRect;
begin
  b := Bounds;
  SortRect (b);
//  if clipping then
//    CheckRectClipping (ClipRect, B);
  with b do
    case Brush.style of
      bsSolid : FillRectangleColor (self, left,top, right,bottom);
      bsPattern : FillRectanglePattern (self, left,top, right,bottom, brush.pattern);
      bsImage :
        if assigned (brush.image) then
          if RelativeBrushImage then
            FillRectangleImageRel (self, left,top, right,bottom, brush.image)
          else
            FillRectangleImage (self, left,top, right,bottom, brush.image)
        else
          raise PixelCanvasException.Create (sErrNoImage);
      bsBDiagonal : FillRectangleHashDiagonal (self, b, HashWidth);
      bsFDiagonal : FillRectangleHashBackDiagonal (self, b, HashWidth);
      bsCross :
        begin
        FillRectangleHashHorizontal (self, b, HashWidth);
        FillRectangleHashVertical (self, b, HashWidth);
        end;
      bsDiagCross :
        begin
        FillRectangleHashDiagonal (self, b, HashWidth);
        FillRectangleHashBackDiagonal (self, b, HashWidth);
        end;
      bsHorizontal : FillRectangleHashHorizontal (self, b, HashWidth);
      bsVertical : FillRectangleHashVertical (self, b, HashWidth);
    end;
end;

// unimplemented in FPC
procedure TLazCanvas.DoPolygonFill(const points: array of TPoint);
var
  lBoundingBox: TRect;
  x, y, i: integer;
begin
  if Brush.Style = bsClear then Exit;

  // Find the Bounding Box of the Polygon
  lBoundingBox := Rect(0, 0, 0, 0);
  for i := low(Points) to High(Points) do
  begin
    lBoundingBox.Left := Min(Points[i].X, lBoundingBox.Left);
    lBoundingBox.Top := Min(Points[i].Y, lBoundingBox.Top);
    lBoundingBox.Right := Max(Points[i].X, lBoundingBox.Right);
    lBoundingBox.Bottom := Max(Points[i].Y, lBoundingBox.Bottom);
  end;

  // Now scan all points using IsPointInPolygon
  for x := lBoundingBox.Left to lBoundingBox.Right do
    for y := lBoundingBox.Top to lBoundingBox.Bottom do
    begin
      if IsPointInPolygon(X, Y, Points) then SetColor(X, Y, Brush.FPColor);
    end;
end;

procedure TLazCanvas.DoLine(x1, y1, x2, y2: integer);
  procedure DrawOneLine (xx1,yy1, xx2,yy2:integer);
  begin
    if Clipping then
      CheckLineClipping (ClipRect, xx1,yy1, xx2,yy2);
    DrawSolidLine (self, xx1,yy1, xx2,yy2, Pen.FPColor);
  end;

  procedure SolidThickLine;
  var w1, w2, r : integer;
      MoreHor : boolean;
  begin
    // determine lines above and under
    w1 := pen.width div 2;
    w2 := w1;
    if w1+w2 = pen.width then
      dec (w1);
    // determine slanting
    MoreHor := (abs(x2-x1) < abs(y2-y1));
    if MoreHor then
      begin  // add lines left/right
      for r := 1 to w1 do
        DrawOneLine (x1-r,y1, x2-r,y2);
      for r := 1 to w2 do
        DrawOneLine (x1+r,y1, x2+r,y2);
      end
    else
      begin  // add lines above/under
      for r := 1 to w1 do
        DrawOneLine (x1,y1-r, x2,y2-r);
      for r := 1 to w2 do
        DrawOneLine (x1,y1+r, x2,y2+r);
      end;
  end;

begin
{ We can are not clip here because we clip in each drawn pixel
  or introduce a more complex algorithm to take into account lazregions
  if Clipping then
    CheckLineClipping (ClipRect, x1,y1, x2,y2);}
  case Pen.style of
    psSolid :
      begin
      DrawSolidLine (self, x1,y1, x2,y2, Pen.FPColor);
      if pen.width > 1 then
        SolidThickLine;
      end;
    psPattern:
      DrawPatternLine (self, x1,y1, x2,y2, pen.pattern);
      // Patterned lines have width always at 1
    psDash, psDot, psDashDot, psDashDotDot :
      DrawPatternLine (self, x1,y1, x2,y2, PenPatterns[Pen.Style]);
  end;
end;

constructor TLazCanvas.create(AnImage: TFPCustomImage);
begin
  inherited Create(AnImage);
  GraphicStateList := TFPList.Create;
  HasNoImage := AnImage = nil;
end;

destructor TLazCanvas.destroy;
begin
  GraphicStateList.Free;
  if FAssignedBrush <> nil then FAssignedBrush.Free;
  if FAssignedPen <> nil then FAssignedPen.Free;
  inherited destroy;
end;

procedure TLazCanvas.SetLazClipRegion(ARegion: TLazRegion);
begin
  Clipping := True;
  {$if defined(ver2_4) or defined(ver2_5) or defined(ver2_6)}
  ClipRect := TLazRegionRect(ARegion.Parts.Items[0]).Rect;
  FLazClipRegion := ARegion;
  {$else}
  ClipRegion := ARegion;
  {$endif}
end;

function TLazCanvas.SaveState: Integer;
var
  lState: TLazCanvasState;
begin
  lState := TLazCanvasState.Create;

  lState.Brush := Brush.CopyBrush;
  lState.Pen := Pen.CopyPen;
  lState.Font := Font.CopyFont;
  lState.BaseWindowOrg := BaseWindowOrg;
  lState.WindowOrg := WindowOrg;
  lState.Clipping := Clipping;

  Result := GraphicStateList.Add(lState);
end;

// if AIndex is positive, it represents the wished saved dc instance
// if AIndex is negative, it's a relative number from last pushed state
procedure TLazCanvas.RestoreState(AIndex: Integer);
var
  lState: TLazCanvasState;
begin
  if AIndex < 0 then AIndex := AIndex + GraphicStateList.Count;
  lState := TLazCanvasState(GraphicStateList.Items[AIndex]);
  GraphicStateList.Delete(AIndex);
  if lState = nil then Exit;

  AssignPenData(lState.Pen);
  AssignBrushData(lState.Brush);
  AssignFontData(lState.Font);
  BaseWindowOrg := lState.BaseWindowOrg;
  WindowOrg := lState.WindowOrg;
  Clipping := lState.Clipping;

  lState.Free;
end;

procedure TLazCanvas.ResetCanvasState;
begin
  Pen.FPColor := colBlack;
  Pen.Style := psSolid;

  Brush.FPColor := colWhite;
  Brush.Style := bsSolid;
end;

procedure TLazCanvas.AlphaBlend(ASource: TLazCanvas;
  const ADestX, ADestY, ASourceX, ASourceY, ASourceWidth, ASourceHeight: Integer);
var
  x, y, CurDestX, CurDestY, CurSrcX, CurSrcY: Integer;
  MaskValue, InvMaskValue: Word;
  CurColor, SrcColor: TFPColor;
  lDrawWidth, lDrawHeight: Integer;
begin
  // Take care not to draw outside the destination area
  lDrawWidth := Min(Self.Width - ADestX, ASource.Width - ASourceX);
  lDrawHeight := Min(Self.Height - ADestY, ASource.Height - ASourceY);
  lDrawWidth := Min(lDrawWidth, ASourceWidth);
  lDrawHeight := Min(lDrawHeight, ASourceHeight);
  //DebugLn(Format('[TLazCanvas.AlphaBlend] lDrawWidth=%d lDrawHeight=%d',
  //  [lDrawWidth, lDrawHeight]));
  for y := 0 to lDrawHeight - 1 do
  begin
    for x := 0 to lDrawWidth - 1 do
    begin
      CurDestX := ADestX + x;
      CurDestY := ADestY + y;
      CurSrcX := ASourceX + x;
      CurSrcY := ASourceY + y;

      // Never draw outside the destination
      if (CurDestX < 0) or (CurDestY < 0) then Continue;

      MaskValue := ASource.Colors[CurSrcX, CurSrcY].alpha;
      InvMaskValue := $FFFF - MaskValue;

      if MaskValue = $FFFF then
      begin
        Self.Colors[CurDestX, CurDestY] := ASource.Colors[CurSrcX, CurSrcY];
      end
      else if MaskValue > $00 then
      begin
        CurColor := Self.Colors[CurDestX, CurDestY];
        SrcColor := ASource.Colors[CurSrcX, CurSrcY];

        CurColor.Red := Round(
          CurColor.Red * InvMaskValue / $FFFF +
          SrcColor.Red * MaskValue / $FFFF);

        CurColor.Green := Round(
          CurColor.Green * InvMaskValue / $FFFF +
          SrcColor.Green * MaskValue / $FFFF);

        CurColor.Blue := Round(
          CurColor.Blue * InvMaskValue / $FFFF +
          SrcColor.Blue * MaskValue / $FFFF);

        CurColor.alpha := alphaOpaque;

        {DebugLn(Format('Alpha blending pixels Old=%d %d Src=%d %d New=%d %d alpha=%d',
          [Self.Colors[CurDestX, CurDestY].Red, Self.Colors[CurDestX, CurDestY].Green,
           SrcColor.Red, SrcColor.Green,
           CurColor.Red, CurColor.Green,
           MaskValue
           ]));}

        Self.Colors[CurDestX, CurDestY] := CurColor;
      end;
    end;
  end;
end;

// This is a safer version in case one doesnt trust the destination pixels
// It will draw as if the target area contained opaque white
procedure TLazCanvas.AlphaBlendIgnoringDestPixels(ASource: TLazCanvas;
  const ADestX, ADestY, ASourceX, ASourceY, ASourceWidth, ASourceHeight: Integer
  );
var
  x, y, CurDestX, CurDestY, CurSrcX, CurSrcY: Integer;
  MaskValue, InvMaskValue: Word;
  CurColor, SrcColor: TFPColor;
  lDrawWidth, lDrawHeight: Integer;
begin
  // Take care not to draw outside the destination area
  lDrawWidth := Min(Self.Width - ADestX, ASource.Width - ASourceX);
  lDrawHeight := Min(Self.Height - ADestY, ASource.Height - ASourceY);
  lDrawWidth := Min(lDrawWidth, ASourceWidth);
  lDrawHeight := Min(lDrawHeight, ASourceHeight);
  //DebugLn(Format('[TLazCanvas.AlphaBlendIgnoringDestPixels] lDrawWidth=%d lDrawHeight=%d',
    //[lDrawWidth, lDrawHeight]));
  for y := 0 to lDrawHeight - 1 do
  begin
    for x := 0 to lDrawWidth - 1 do
    begin
      CurDestX := ADestX + x;
      CurDestY := ADestY + y;
      CurSrcX := ASourceX + x;
      CurSrcY := ASourceY + y;

      // Never draw outside the destination
      if (CurDestX < 0) or (CurDestY < 0) then Continue;

      MaskValue := ASource.Colors[CurSrcX, CurSrcY].alpha;
      InvMaskValue := $FFFF - MaskValue;

      if MaskValue = $FFFF then
      begin
        Self.Colors[CurDestX, CurDestY] := ASource.Colors[CurSrcX, CurSrcY];
      end
      // Theorically it should be > 0 but we make a filter here to exclude low-alpha pixels
      // because those cause small white pixels in the image
      else if MaskValue > $4000 then
      begin
        SrcColor := ASource.Colors[CurSrcX, CurSrcY];

        CurColor.Red := InvMaskValue + (SrcColor.Red * MaskValue) div $FFFF;
        CurColor.Green := InvMaskValue + (SrcColor.Green * MaskValue) div $FFFF;
        CurColor.Blue := InvMaskValue + (SrcColor.Blue * MaskValue) div $FFFF;
        CurColor.alpha := alphaOpaque;

        Self.Colors[CurDestX, CurDestY] := CurColor;
      end;
    end;
  end;
end;

procedure TLazCanvas.CanvasCopyRect(ASource: TLazCanvas; const ADestX, ADestY,
  ASourceX, ASourceY, ASourceWidth, ASourceHeight: Integer);
var
  x, y, CurDestX, CurDestY, CurSrcX, CurSrcY: Integer;
  lDrawWidth, lDrawHeight: Integer;
  lColor: TFPColor;
begin
  // Take care not to draw outside the source and also not outside the destination area
  lDrawWidth := Min(Self.Width - ADestX, ASource.Width - ASourceX);
  lDrawHeight := Min(Self.Height - ADestY, ASource.Height - ASourceY);
  lDrawWidth := Min(lDrawWidth, ASourceWidth);
  lDrawHeight := Min(lDrawHeight, ASourceHeight);

  for y := 0 to lDrawHeight - 1 do
  begin
    for x := 0 to lDrawWidth - 1 do
    begin
      CurDestX := ADestX + x;
      CurDestY := ADestY + y;
      CurSrcX := ASourceX + x;
      CurSrcY := ASourceY + y;

      // Never draw outside the destination
      if (CurDestX < 0) or (CurDestY < 0) then Continue;

      lColor := ASource.Colors[CurSrcX, CurSrcY];
      Self.Colors[CurDestX, CurDestY] := lColor;
    end;
  end;
end;

{$if defined(ver2_4) or defined(ver2_5)}
procedure TLazCanvas.FillRect(const ARect: TRect);
begin
  if (Brush.style <> bsClear) then
    begin
    //if not (brush is TFPCustomDrawBrush) then
      DoRectangleFill (ARect)
    //else
    //  with ARect do
    //    TFPCustomDrawBrush(Brush).Rectangle (left,top,right,bottom);
    end;
end;

procedure TLazCanvas.FillRect(X1, Y1, X2, Y2: Integer);
begin
  FillRect (Rect(X1,Y1,X2,Y2));
end;
{$endif}

procedure TLazCanvas.FillColor(AColor: TFPColor;
  AIgnoreClippingAndWindowOrg: Boolean);
var
  x, y: Integer;
begin
  if AIgnoreClippingAndWindowOrg then
  begin
    for y := 0 to Height-1 do
      for x := 0 to Width-1 do
        Image.Colors[x, y] := AColor;
  end
  else
  begin
    for y := 0 to Height-1 do
      for x := 0 to Width-1 do
        SetColor(x, y, AColor);
  end;
end;

procedure TLazCanvas.AssignPenData(APen: TFPCustomPen);
begin
  if APen = nil then Exit;
  Pen.FPColor := APen.FPColor;
  Pen.Style := APen.Style;
  Pen.Width := APen.Width;
end;

procedure TLazCanvas.AssignBrushData(ABrush: TFPCustomBrush);
begin
  if ABrush = nil then Exit;
  Brush.FPColor := ABrush.FPColor;
  Brush.Style := ABrush.Style;
end;

procedure TLazCanvas.AssignFontData(AFont: TFPCustomFont);
begin
  if AFont = nil then Exit;
  Font.FPColor := AFont.FPColor;
  Font.Name := AFont.Name;
  Font.Size := AFont.Size;
  Font.Bold := AFont.Bold;
  Font.Italic := AFont.Italic;
  Font.Underline := AFont.Underline;
  {$IF (FPC_FULLVERSION=20601) or (FPC_FULLVERSION>=20701)} //changed in 2.6.1 and 2.7; remove when FPC 2.6.2+ only is supported
  Font.StrikeThrough := AFont.StrikeThrough;
  {$ELSE}
  Font.StrikeTrough := AFont.StrikeTrough; //old version with typo
  {$ENDIF}
end;

{ TFPWindowsSharpInterpolation }

procedure TFPSharpInterpolation.Execute(x, y, w, h: integer);
// paint Image on Canvas at x,y,w*h
var
  srcx, srcy: Integer; // current coordinates in the source image
  dx, dy, dw, dh: Integer; // current coordinates in the destination canvas
  lWidth, lHeight: Integer; // Image size
  lColor: TFPColor;
begin
  if (w<=0) or (h<=0) or (image.Width=0) or (image.Height=0) then
    exit;

  lWidth := Image.Width-1;
  lHeight := Image.Height-1;
  dw := w - 1;
  dh := h - 1;

  for dx := 0 to w-1 do
   for dy := 0 to h-1 do
   begin
     srcx := Round((dx / dw) * lWidth);
     srcy := Round((dy / dh) * lHeight);
     lColor := Image.Colors[srcx, srcy];
     Canvas.Colors[dx+x, dy+y] := lColor;
   end;
end;

end.

