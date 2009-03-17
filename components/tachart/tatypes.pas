{
 /***************************************************************************
                               TATypes.pas
                               -----------
              Component Library Standard Graph Element Types


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
unit TATypes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, FPCanvas,
  TAChartUtils;

type
  TCustomChart = class(TCustomControl);

  TChartPen = class(TPen)
  private
    FVisible: Boolean;
    procedure SetVisible(AValue: Boolean);
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Visible: Boolean read FVisible write SetVisible;
  end;

  TLegendAlignment = (laLeft, laRight, laTop, laBottom);

  TFPCanvasHelperClass = class of TFPCanvasHelper;

  { TChartElement }

  TChartElement = class(TPersistent)
  private
    FVisible: Boolean;
    procedure SetVisible(const AValue: Boolean);
  protected
    FOwner: TCustomChart;
    procedure StyleChanged(Sender: TObject);
    procedure InitHelper(
      var AResult: TFPCanvasHelper; AClass: TFPCanvasHelperClass);
  public
    constructor Create(AOwner: TCustomChart);
    procedure Assign(Source: TPersistent); override;

    procedure SetOwner(AOwner: TCustomChart);

    property Visible: Boolean read FVisible write SetVisible;
  end;

  TChartLegend = class(TChartElement)
  private
    FAlignment: TLegendAlignment;
    FFont: TFont;
    FFrame: TChartPen;

    procedure SetAlignment(AValue: TLegendAlignment);
    procedure SetFont(AValue: TFont);
    procedure SetFrame(AValue: TChartPen);
  public
    constructor Create(AOwner: TCustomChart);
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
  published
    property Alignment: TLegendAlignment read FAlignment write SetAlignment;
    property Font: TFont read FFont write SetFont;
    property Frame: TChartPen read FFrame write SetFrame;
    property Visible;
  end;

  TChartTitle = class(TChartElement)
  private
    FAlignment: TAlignment;
    FBrush: TBrush;
    FFont: TFont;
    FFrame: TChartPen;
    FText: TStrings;

    procedure SetAlignment(AValue: TAlignment);
    procedure SetBrush(AValue: TBrush);
    procedure SetFont(AValue: TFont);
    procedure SetFrame(AValue: TChartPen);
    procedure SetText(AValue: TStrings);
  public
    constructor Create(AOwner: TCustomChart);
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
  published
    property Alignment: TAlignment read FAlignment write SetAlignment;
    property Brush: TBrush read FBrush write SetBrush;
    property Font: TFont read FFont write SetFont;
    property Frame: TChartPen read FFrame write SetFrame;
    property Text: TStrings read FText write SetText;
    property Visible;
  end;

  TChartAxisTitle = class(TChartElement)
  private
    FAngle: Integer;
    FCaption: String;
    FFont: TFont;

    procedure SetAngle(AValue: Integer);
    procedure SetCaption(AValue: String);
    procedure SetFont(AValue: TFont);
  public
    constructor Create(AOwner: TCustomChart);
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
  published
    property Angle: Integer read FAngle write SetAngle;
    property Caption: String read FCaption write SetCaption;
    property Font: TFont read FFont write SetFont;
  end;

  TChartAxis = class(TChartElement)
  private
    FGrid: TChartPen;
    FInverted: Boolean;
    FTitle: TChartAxisTitle;

    procedure SetGrid(AValue: TChartPen);
    procedure SetInverted(AValue: Boolean);
    procedure SetTitle(AValue: TChartAxisTitle);
  public
    constructor Create(AOwner: TCustomChart);
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
  published
    property Grid: TChartPen read FGrid write SetGrid;
    // Inverts the axis scale from increasing to decreasing.
    property Inverted: boolean read FInverted write SetInverted;
    property Title: TChartAxisTitle read FTitle write SetTitle;
    property Visible;
  end;

  TChartLinkPen = class(TChartPen)
  published
    property Color default clWhite;
  end;

  TChartLabelBrush = class(TBrush)
  published
    property Color default clYellow;
  end;

  { TChartMarks }

  TChartMarks = class(TChartElement)
  private
    FDistance: Integer;
    FFormat: String;
    FFrame: TChartPen;
    FLabelBrush: TChartLabelBrush;
    FLabelFont: TFont;
    FLinkPen: TChartLinkPen;
    FStyle: TSeriesMarksStyle;

    procedure SetDistance(const AValue: Integer);
    procedure SetFormat(const AValue: String);
    procedure SetFrame(const AValue: TChartPen);
    procedure SetLabelBrush(const AValue: TChartLabelBrush);
    procedure SetLabelFont(const AValue: TFont);
    procedure SetLinkPen(const AValue: TChartLinkPen);
    procedure SetStyle(const AValue: TSeriesMarksStyle);
  public
    constructor Create(AOwner: TCustomChart);
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    procedure DrawLabel(
      ACanvas: TCanvas; const ALabelRect: TRect; const AText: String);
    function IsMarkLabelsVisible: Boolean;
  published
    // Distance between series point and label.
    property Distance: Integer read FDistance write SetDistance default 20;
    property Format: String read FFormat write SetFormat;
    property Frame: TChartPen read FFrame write SetFrame;
    property LabelBrush: TChartLabelBrush read FLabelBrush write SetLabelBrush;
    property LabelFont: TFont read FLabelFont write SetLabelFont;
    property LinkPen: TChartLinkPen read FLinkPen write SetLinkPen;
    property Style: TSeriesMarksStyle
      read FStyle write SetStyle default smsNone;
    property Visible default true;
  end;

  { TSeriesPointer }

  TSeriesPointer = class(TChartElement)
  private
    FBrush: TBrush;
    FHorizSize: Integer;
    FPen: TChartPen;
    FStyle: TSeriesPointerStyle;
    FVertSize: Integer;

    procedure SetBrush(AValue: TBrush);
    procedure SetHorizSize(AValue: Integer);
    procedure SetPen(AValue: TChartPen);
    procedure SetStyle(AValue: TSeriesPointerStyle);
    procedure SetVertSize(AValue: Integer);
  public
    constructor Create(AOwner: TCustomChart);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;

    procedure Draw(ACanvas: TCanvas; ACenter: TPoint; AColor: TColor);
  published
    property Brush: TBrush read FBrush write SetBrush;
    property HorizSize: Integer read FHorizSize write SetHorizSize default 4;
    property Pen: TChartPen read FPen write SetPen;
    property Style: TSeriesPointerStyle read FStyle write SetStyle default psRectangle;
    property VertSize: Integer read FVertSize write SetVertSize default 4;
    property Visible default true;
  end;

const
  MARKS_MARGIN_X = 4;
  MARKS_MARGIN_Y = 2;

implementation

uses
  Types;

{ TChartPen }

procedure TChartPen.Assign(Source: TPersistent);
begin
  if Source is TChartPen then
    with TChartPen(Source) do
      FVisible := Visible;
  inherited Assign( Source );
end;

procedure TChartPen.SetVisible(AValue: Boolean);
begin
  FVisible := AValue;
  if Assigned(OnChange) then OnChange(Self);
end;

{ TChartElement }

procedure TChartElement.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
  if Source is TChartElement then
    Self.FVisible := TChartElement(Source).FVisible;
end;

constructor TChartElement.Create(AOwner: TCustomChart);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TChartElement.InitHelper(
  var AResult: TFPCanvasHelper; AClass: TFPCanvasHelperClass);
begin
  AResult := AClass.Create;
  AResult.OnChange := @StyleChanged;
end;

procedure TChartElement.SetOwner(AOwner: TCustomChart);
begin
  FOwner := AOwner;
end;

procedure TChartElement.SetVisible(const AValue: Boolean);
begin
  if FVisible = AValue then exit;
  FVisible := AValue;
  StyleChanged(Self);
end;

procedure TChartElement.StyleChanged(Sender: TObject);
begin
  if FOwner <> nil then
    FOwner.Invalidate;
end;

{ TChartLegend }

procedure TChartLegend.Assign(Source: TPersistent);
begin
  if Source is TChartLegend then
    with TChartLegend(Source) do begin
      Self.FAlignment := FAlignment;
      Self.FVisible := FVisible;
    end;

  inherited Assign(Source);
end;

constructor TChartLegend.Create(AOwner: TCustomChart);
begin
  inherited Create(AOwner);
  FAlignment := laRight;
  FVisible := false;

  InitHelper(FFont, TFont);
  InitHelper(FFrame, TChartPen);
end;

destructor TChartLegend.Destroy;
begin
  FFont.Free;
  FFrame.Free;

  inherited;
end;

procedure TChartLegend.SetAlignment(AValue: TLegendAlignment);
begin
  if FAlignment = AValue then exit;
  FAlignment := AValue;
  StyleChanged(Self);
end;

procedure TChartLegend.SetFont(AValue: TFont);
begin
  FFont.Assign(AValue);
  StyleChanged(Self);
end;

procedure TChartLegend.SetFrame(AValue: TChartPen);
begin
  FFrame.Assign(AValue);
  StyleChanged(Self);
end;

{ TChartTitle }

procedure TChartTitle.Assign(Source: TPersistent);
begin
  if Source is TChartTitle then
    with TChartTitle(Source) do begin
      Self.FAlignment := Alignment;
      Self.FBrush.Assign(Brush);
      Self.FFont.Assign(Font);
      Self.FFrame.Assign(Frame);
      Self.FText.Assign(Text);
   end;

  inherited Assign(Source);
end;

constructor TChartTitle.Create(AOwner: TCustomChart);
begin
  inherited Create(AOwner);

  InitHelper(FBrush, TBrush);
  FBrush.Color := FOwner.Color;
  InitHelper(FFont, TFont);
  FFont.Color := clBlue;
  InitHelper(FFrame, TChartPen);
  FText := TStringList.Create;
end;

destructor TChartTitle.Destroy;
begin
  FBrush.Free;
  FFont.Free;
  FFrame.Free;
  FText.Free;

  inherited;
end;

procedure TChartTitle.SetAlignment(AValue: TAlignment);
begin
  if FAlignment = AValue then exit;
  FAlignment := AValue;
  StyleChanged(Self);
end;

procedure TChartTitle.SetBrush(AValue: TBrush);
begin
  FBrush.Assign(AValue);
  StyleChanged(Self);
end;

procedure TChartTitle.SetFont(AValue: TFont);
begin
  FFont.Assign(AValue);
  StyleChanged(Self);
end;

procedure TChartTitle.SetFrame(AValue: TChartPen);
begin
  FFrame.Assign(AValue);
  StyleChanged(Self);
end;

procedure TChartTitle.SetText(AValue: TStrings);
begin
  FText.Assign(AValue);
  StyleChanged(Self);
end;

{ TChartAxisTitle }

procedure TChartAxisTitle.Assign(Source: TPersistent);
begin
  if Source is TChartAxisTitle then
    with TChartAxisTitle(Source) do begin
      FCaption := Caption;
      FAngle := Angle;
      FFont.Assign(Font);
    end;
  inherited Assign(Source);
end;

constructor TChartAxisTitle.Create(AOwner: TCustomChart);
begin
  inherited Create(AOwner);
  InitHelper(FFont, TFont);
end;

destructor TChartAxisTitle.Destroy;
begin
  FFont.Free;
  inherited;
end;

procedure TChartAxisTitle.SetAngle(AValue: Integer);
begin
  FAngle := AValue;
  StyleChanged(Self);
end;

procedure TChartAxisTitle.SetCaption(AValue: String);
begin
  FCaption := AValue;
  StyleChanged(Self);
end;

procedure TChartAxisTitle.SetFont(AValue: TFont);
begin
  FFont.Assign(AValue);
  StyleChanged(Self);
end;

{ TChartAxis }

procedure TChartAxis.Assign(Source: TPersistent);
begin
  if Source is TChartAxis then
    with TChartAxis(Source) do begin
      FGrid.Assign(Grid);
      FInverted := Inverted;
      FTitle.Assign(Title);
    end;
  inherited Assign(Source);
end;

constructor TChartAxis.Create(AOwner: TCustomChart);
begin
  inherited Create(AOwner);
  FTitle := TChartAxisTitle.Create(AOwner);
  InitHelper(FGrid, TChartPen);
end;

destructor TChartAxis.Destroy;
begin
  FTitle.Free;
  FGrid.Free;
  inherited;
end;

procedure TChartAxis.SetGrid(AValue: TChartPen);
begin
  FGrid.Assign(AValue);
  StyleChanged(Self);
end;

procedure TChartAxis.SetInverted(AValue: Boolean);
begin
  FInverted := AValue;
  StyleChanged(Self);
end;

procedure TChartAxis.SetTitle(AValue: TChartAxisTitle);
begin
  FTitle.Assign(AValue);
  StyleChanged(Self);
end;

{ TChartMarks }

procedure TChartMarks.Assign(Source: TPersistent);
begin
  inherited Assign(Source);
  if Source is TChartMarks then
    with TChartMarks(Source) do begin
      Self.FDistance := FDistance;
      Self.FFrame.Assign(FFrame);
      Self.FFormat := FFormat;
      Self.FLabelBrush.Assign(FLabelBrush);
      Self.FLabelFont.Assign(FLabelFont);
      Self.FLinkPen.Assign(FLinkPen);
      Self.FStyle := FStyle;
    end;
end;

constructor TChartMarks.Create(AOwner: TCustomChart);
begin
  inherited Create(AOwner);
  FDistance := 20;
  InitHelper(FFrame, TChartPen);
  InitHelper(FLabelBrush, TChartLabelBrush);
  FLabelBrush.Color := clYellow;
  InitHelper(FLabelFont, TFont);
  InitHelper(FLinkPen, TChartLinkPen);
  FLinkPen.Color := clWhite;
  FStyle := smsNone;
  FVisible := true;
end;

destructor TChartMarks.Destroy;
begin
  FFrame.Free;
  FLabelBrush.Free;
  FLabelFont.Free;
  FLinkPen.Free;
  inherited Destroy;
end;

procedure TChartMarks.DrawLabel(
  ACanvas: TCanvas; const ALabelRect: TRect; const AText: String);
begin
  ACanvas.Brush.Assign(LabelBrush);
  ACanvas.Pen.Assign(Frame);
  ACanvas.Rectangle(ALabelRect);
  ACanvas.Font.Assign(LabelFont);
  ACanvas.TextOut(
    ALabelRect.Left + MARKS_MARGIN_X, ALabelRect.Top + MARKS_MARGIN_Y, AText);
end;

function TChartMarks.IsMarkLabelsVisible: Boolean;
begin
  Result := Visible and (Style <> smsNone) and (Format <> '');
end;

procedure TChartMarks.SetDistance(const AValue: Integer);
begin
  if FDistance = AValue then exit;
  FDistance := AValue;
  StyleChanged(Self);
end;

procedure TChartMarks.SetFormat(const AValue: String);
begin
  if FFormat = AValue then exit;
  FFormat := AValue;
  FStyle := High(FStyle);
  while (FStyle > smsCustom) and (SERIES_MARK_FORMATS[FStyle] <> AValue) do
    Dec(FStyle);
  StyleChanged(Self);
end;

procedure TChartMarks.SetFrame(const AValue: TChartPen);
begin
  if FFrame = AValue then exit;
  FFrame.Assign(AValue);
  StyleChanged(Self);
end;

procedure TChartMarks.SetLabelBrush(const AValue: TChartLabelBrush);
begin
  if FLabelBrush = AValue then exit;
  FLabelBrush.Assign(AValue);
  StyleChanged(Self);
end;

procedure TChartMarks.SetLabelFont(const AValue: TFont);
begin
  if FLabelFont = AValue then exit;
  FLabelFont := AValue;
  StyleChanged(Self);
end;

procedure TChartMarks.SetLinkPen(const AValue: TChartLinkPen);
begin
  if FLinkPen = AValue then exit;
  FLinkPen := AValue;
  StyleChanged(Self);
end;

procedure TChartMarks.SetStyle(const AValue: TSeriesMarksStyle);
begin
  if FStyle = AValue then exit;
  FStyle := AValue;
  if FStyle <> smsCustom then
    FFormat := SERIES_MARK_FORMATS[FStyle];
  StyleChanged(Self);
end;

{ TSeriesPointer }

procedure TSeriesPointer.Assign(Source: TPersistent);
begin
  if Source is TSeriesPointer then
    with TSeriesPointer(Source) do begin
      Self.FBrush.Assign(Brush);
      Self.FPen.Assign(Pen);
      Self.FStyle := Style;
    end;
  inherited Assign(Source);
end;

constructor TSeriesPointer.Create(AOwner: TCustomChart);
begin
  inherited Create(AOwner);

  InitHelper(FBrush, TBrush);
  InitHelper(FPen, TChartPen);

  FHorizSize := 4;
  FStyle := psRectangle;
  FVertSize  := 4;
  FVisible := true;
end;

destructor TSeriesPointer.Destroy;
begin
  FBrush.Free;
  FPen.Free;
  inherited Destroy;
end;

procedure TSeriesPointer.Draw(ACanvas: TCanvas; ACenter: TPoint; AColor: TColor);
var
  r: TRect;
begin
  ACanvas.Brush.Assign(FBrush);
  ACanvas.Pen.Assign(FPen);
  r := Bounds(ACenter.X, ACenter.Y, 1, 1);
  InflateRect(r, FHorizSize, FVertSize);

  if FStyle in [psRectangle, psCircle] then
    ACanvas.Brush.Color := AColor
  else
    ACanvas.Pen.Color := AColor;

  // Line does not draw the end point, so coordinates have to be incremented.
  case FStyle of
    psRectangle:
      ACanvas.Rectangle(r);
    psCross: begin
      ACanvas.Line(r.Left, ACenter.Y, r.Right + 1, ACenter.Y);
      ACanvas.Line(ACenter.X, r.Top, ACenter.X, r.Bottom + 1);
    end;
    psDiagCross: begin
      ACanvas.Line(r.Left, r.Top, r.Right + 1, r.Bottom + 1);
      ACanvas.Line(r.Left, r.Bottom, r.Right + 1, r.Top - 1);
    end;
    psStar: begin
      ACanvas.Line(r.Left, ACenter.Y, r.Right + 1, ACenter.Y);
      ACanvas.Line(ACenter.X, r.Top, ACenter.X, r.Bottom + 1);
      ACanvas.Line(r.Left, r.Top, r.Right + 1, r.Bottom + 1);
      ACanvas.Line(r.Left, r.Bottom, r.Right + 1, r.Top - 1);
    end;
    psCircle:
      ACanvas.Ellipse(r);
    psLowBracket: begin
      ACanvas.MoveTo(r.Left, ACenter.Y);
      ACanvas.LineTo(r.Left, r.Bottom);
      ACanvas.LineTo(r.Right, r.Bottom);
      ACanvas.LineTo(r.Right, ACenter.Y - 1);
    end;
    psHighBracket: begin
      ACanvas.MoveTo(r.Left, ACenter.Y);
      ACanvas.LineTo(r.Left, r.Top);
      ACanvas.LineTo(r.Right, r.Top);
      ACanvas.LineTo(r.Right, ACenter.Y + 1);
    end;
  end;
end;

procedure TSeriesPointer.SetBrush(AValue: TBrush);
begin
  FBrush.Assign(AValue);
  StyleChanged(Self);
end;

procedure TSeriesPointer.SetHorizSize(AValue: Integer);
begin
  if FHorizSize = AValue then exit;
  FHorizSize := AValue;
  StyleChanged(Self);
end;

procedure TSeriesPointer.SetPen(AValue: TChartPen);
begin
  FPen.Assign(AValue);
  StyleChanged(Self);
end;

procedure TSeriesPointer.SetStyle(AValue: TSeriesPointerStyle);
begin
  if FStyle = AValue then exit;
  FStyle := AValue;
  StyleChanged(Self);
end;

procedure TSeriesPointer.SetVertSize(AValue: Integer);
begin
  if FVertSize = AValue then exit;
  FVertSize := AValue;
  StyleChanged(Self);
end;

end.

