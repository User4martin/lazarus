unit SynGutterLineNumber;

{$I synedit.inc}

interface

uses
  Classes, SysUtils, Graphics, LCLType, LCLIntf, SynGutter,
  SynEditMiscProcs, SynEditMiscClasses, SynTextDrawer, SynEditFoldedView;

type

  { TSynGutterLineNumber }

  TSynGutterLineNumber = class(TSynGutterPartBase)
  private
    FEdit: TSynEditBase;
    FFoldView: TSynEditFoldedView;
    FTextDrawer: TheTextDrawer;
    FMarkupInfoLineNumber: TSynSelectedColor;

    FDigitCount: integer;
    FAutoSizeDigitCount: integer;
    FShowOnlyLineNumbersMultiplesOf: integer;
    FLeadingZeros: boolean;
    FZeroStart: boolean;

    procedure SetDigitCount(AValue : integer);
    procedure SetLeadingZeros(const AValue : boolean);
    procedure SetShowOnlyLineNumbersMultiplesOf(const AValue : integer);
    procedure SetZeroStart(const AValue : boolean);
    function FormatLineNumber(Line: integer; IsDot: boolean): string;
  public
    constructor Create(AOwner : TSynEditBase; AFoldView : TSynEditFoldedView;
      ATextDrawer: TheTextDrawer);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;

    procedure Paint(Canvas: TCanvas; AClip: TRect; FirstLine, LastLine: integer);
      override;
    procedure AutoSizeDigitCount(LinesCount: integer);
    function RealGutterWidth(CharWidth: integer): integer;  override;
  public
    property MarkupInfoLineNumber: TSynSelectedColor read FMarkupInfoLineNumber;
    property DigitCount: integer read FDigitCount write SetDigitCount;
    property ShowOnlyLineNumbersMultiplesOf: integer
      read FShowOnlyLineNumbersMultiplesOf
      write SetShowOnlyLineNumbersMultiplesOf;
    property ZeroStart: boolean read FZeroStart write SetZeroStart;
    property LeadingZeros: boolean read FLeadingZeros write SetLeadingZeros;
  end;

implementation
uses
  SynEdit;

{ TSynGutterLineNumber }

constructor TSynGutterLineNumber.Create(AOwner : TSynEditBase;
  AFoldView : TSynEditFoldedView; ATextDrawer : TheTextDrawer);
begin
  inherited Create;
  FEdit := AOwner;
  FFoldView := AFoldView;
  FTextDrawer := ATextDrawer;

  FDigitCount := 2;
  FAutoSizeDigitCount := FDigitCount;
  FShowOnlyLineNumbersMultiplesOf := 1;
  FLeadingZeros := false;
  FZeroStart := False;
  FMarkupInfoLineNumber := TSynSelectedColor.Create;
  FMarkupInfoLineNumber.Background := clNone;
  FMarkupInfoLineNumber.Foreground := clNone;
  FMarkupInfoLineNumber.OnChange := @DoChange;
end;

destructor TSynGutterLineNumber.Destroy;
begin
  FMarkupInfoLineNumber.Free;
  inherited Destroy;
end;

procedure TSynGutterLineNumber.Assign(Source : TPersistent);
var
  Src: TSynGutterLineNumber;
begin
  if Assigned(Source) and (Source is TSynGutterLineNumber) then
  begin
    Src := TSynGutterLineNumber(Source);
    FLeadingZeros := Src.FLeadingZeros;
    FZeroStart := Src.FZeroStart;
    FDigitCount := Src.FDigitCount;
    FAutoSizeDigitCount := Src.FAutoSizeDigitCount;
    FShowOnlyLineNumbersMultiplesOf := Src.FShowOnlyLineNumbersMultiplesOf;
    FMarkupInfoLineNumber.Assign(Src.MarkupInfoLineNumber);
  end;
  inherited;
end;

procedure TSynGutterLineNumber.SetDigitCount(AValue : integer);
begin
  AValue := MinMax(AValue, 2, 12);
  if FDigitCount <> AValue then
  begin
    FDigitCount := AValue;
    FAutoSizeDigitCount := FDigitCount;
    DoChange(Self);
  end;
end;

procedure TSynGutterLineNumber.SetLeadingZeros(const AValue : boolean);
begin
  if FLeadingZeros <> AValue then
  begin
    FLeadingZeros := AValue;
    DoChange(Self);
  end;
end;

procedure TSynGutterLineNumber.SetShowOnlyLineNumbersMultiplesOf(const AValue : integer);
begin
  If FShowOnlyLineNumbersMultiplesOf <> AValue then
  begin
    FShowOnlyLineNumbersMultiplesOf := AValue;
    DoChange(self);
  end;
end;

procedure TSynGutterLineNumber.SetZeroStart(const AValue : boolean);
begin
  if FZeroStart <> AValue then
  begin
    FZeroStart := AValue;
    DoChange(Self);
  end;
end;

function TSynGutterLineNumber.RealGutterWidth(CharWidth : integer) : integer;
begin
  if not Visible then
  begin
    Result := 0;
    Exit;
  end;

  if AutoSize then
    Width := FAutoSizeDigitCount * CharWidth + 1;
  Result := Width;
end;

procedure TSynGutterLineNumber.AutoSizeDigitCount(LinesCount: integer);
var
  nDigits: integer;
begin
  if Visible and AutoSize then
  begin
    if FZeroStart then Dec(LinesCount);
    nDigits := Max(Length(IntToStr(LinesCount)), FDigitCount);
    if FAutoSizeDigitCount <> nDigits then
    begin
      FAutoSizeDigitCount := nDigits;
      DoChange(Self);
    end;
  end else
    FAutoSizeDigitCount := FDigitCount;
end;

function TSynGutterLineNumber.FormatLineNumber(Line: integer; IsDot: boolean): string;
var
  i: integer;
begin
  Result := '';
  // if a dot must be showed
  if IsDot then
    if Line mod 5 = 0 then // every 5 lines show '-' instead of '.'
      Result := StringOfChar(' ', FAutoSizeDigitCount-1) + '-'
    else
      Result := StringOfChar(' ', FAutoSizeDigitCount-1) + '.'
  // else format the line number
  else begin
    if FZeroStart then Dec(Line);
    Str(Line : FAutoSizeDigitCount, Result);
    if FLeadingZeros then
      for i := 1 to FAutoSizeDigitCount - 1 do begin
        if (Result[i] <> ' ') then break;
        Result[i] := '0';
      end;
  end;
end;

procedure TSynGutterLineNumber.Paint(Canvas : TCanvas; AClip : TRect; FirstLine, LastLine : integer);
var
  i, iLine: integer;
  rcLine: TRect;
  s: string;
  dc: HDC;
  ShowDot: boolean;
  LineHeight: Integer;

begin
  if not Visible then exit;

  LineHeight := TSynEdit(FEdit).LineHeight;
  // Changed to use fTextDrawer.BeginDrawing and fTextDrawer.EndDrawing only
  // when absolutely necessary.  Note: Never change brush / pen / font of the
  // canvas inside of this block (only through methods of fTextDrawer)!
  Canvas.Brush.Color := Color;
  dc := Canvas.Handle;
  {$IFDEF SYN_LAZARUS}
  LCLIntf.SetBkColor(dc,Canvas.Brush.Color);
  {$ENDIF}
  fTextDrawer.BeginDrawing(dc);
  try
    if MarkupInfoLineNumber.Background <> clNone then
      fTextDrawer.SetBackColor(MarkupInfoLineNumber.Background)
    else
      fTextDrawer.SetBackColor(Color);
    if MarkupInfoLineNumber.Foreground <> clNone then
      fTextDrawer.SetForeColor(MarkupInfoLineNumber.Foreground)
    else
      fTextDrawer.SetForeColor(TSynEdit(FEdit).Font.Color);
    fTextDrawer.SetFrameColor(MarkupInfoLineNumber.FrameColor);
    fTextDrawer.Style := MarkupInfoLineNumber.Style;
    // prepare the rect initially
    rcLine := AClip;
    rcLine.Bottom := FirstLine * LineHeight;
    for i := FirstLine to LastLine do
    begin
      iLine := FFoldView.DisplayNumber[i];
      // next line rect
      rcLine.Top := rcLine.Bottom;
      // Must show a dot instead of line number if
      // line number is not the first, the last, the current line
      // or a multiple of ShowOnlyLineNumbersMultiplesOf
      ShowDot := ((iLine mod ShowOnlyLineNumbersMultiplesOf) <> 0)
          and (iLine <> TSynEdit(FEdit).CaretY) and (iLine <> 1)
          and (iLine <> TSynEdit(FEdit).Lines.Count);
      // Get the formatted line number or dot
      s := FormatLineNumber(iLine, ShowDot);
      Inc(rcLine.Bottom, LineHeight);
      // erase the background and draw the line number string in one go
      fTextDrawer.ExtTextOut(rcLine.Left, rcLine.Top, ETO_OPAQUE or ETO_CLIPPED, rcLine,
        PChar(Pointer(S)),Length(S));
    end;

    // now erase the remaining area if any
    if AClip.Bottom > rcLine.Bottom then
    begin
      rcLine.Top := rcLine.Bottom;
      rcLine.Bottom := AClip.Bottom;
      with rcLine do
        fTextDrawer.ExtTextOut(Left, Top, ETO_OPAQUE, rcLine, nil, 0);
    end;
    // restore original style
    fTextDrawer.SetBackColor(Color);
    fTextDrawer.SetForeColor(TSynEdit(FEdit).Font.Color);
    fTextDrawer.SetFrameColor(clNone);
    if AClip.Left < rcLine.Left then
    begin
      rcLine.Right := rcLine.Left;
      rcLine.Left := AClip.Left;
      rcLine.Top := AClip.Top;
      rcLine.Bottom := AClip.Bottom;
      with rcLine do
        fTextDrawer.ExtTextOut(Left, Top, ETO_OPAQUE, rcLine, nil, 0);
    end;
  finally
    fTextDrawer.EndDrawing;
  end;
end;

end.

