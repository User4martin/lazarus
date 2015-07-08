{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Author: Maciej Izak

  DaThoX 2004-2015
  FreeSparta.com
}

unit sparta_Resizer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, sparta_ResizerFrame, sparta_DesignedForm, Forms, Math, StdCtrls,
  LCLType, LazIDEIntf, Buttons, SpartaAPI, Dialogs,
{$IFDEF USE_GENERICS_COLLECTIONS}
  Generics.Defaults,
{$ENDIF}
  FormEditingIntf;

type

  { TResizer }

{$IFDEF USE_GENERICS_COLLECTIONS}
  TResizer = class(TSingletonImplementation, IResizer)
{$ELSE}
  TResizer = class(TComponent, IResizer)
{$ENDIF}
  private
    FDesignedForm: IDesignedForm;

    procedure SetDesignedForm(const AValue: IDesignedForm);
    procedure SetDesignScroll(AIndex: Integer; AValue: Boolean);
    procedure sbScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);

    procedure FunnyButtonClick(Sender: TObject);
  protected
    // By poprawnie dzialal scroolbar z "PageSize" trzeba pamiętać prawdziwe
    // maxymalne wartosci (co prawda nie mozna przesuwac suwakiem poza zakres Max - PageSize,
    // jednak po kliknieciu przycisku przesuwajacego maxymalna wartosc wynosi już max)
    // obejsciem tego problematycznego problemu jest pamiętanie we wlasnym zakresie maxymalnej wartosci
    FRealMaxH: Integer;
    FRealMaxV: Integer;
    FSpecialMargin: array[0..3] of Integer;
    FDesignScroll: array[0..1] of Boolean;
    FParent: TWinControl;

    class var
      FStarter, FProfessional: TNotifyEvent;
  public
    pMainDTU: TPanel;
    pMain: TPanel;
    pAddons: TPanel;
    pComponents: TPanel;
    lInfo: TLabel;
    sbShowComponents  : TSpeedButton;
    sbShowFormEditor: TSpeedButton;
    sbShowAnchorEditor: TSpeedButton;
    sbShowNonVisualEditor: TSpeedButton;
    pDesignTimeUtils: TPanel;
    sbV: TScrollBar;
    sbH: TScrollBar;
    bR: TButton;
    FResizerFrame: TResizerFrame;

    FMainDTU: ISTAMainDesignTimeUtil;

    FEDTU: TList;

    constructor Create(AParent: TWinControl);
    destructor Destroy; override;

    property DesignedForm: IDesignedForm read FDesignedForm write SetDesignedForm;

    procedure TryBoundSizerToDesignedForm(Sender: TObject);

    procedure NodePositioning(Sender: TObject; PositioningKind: TPositioningKind; PositioningCode: TPositioningCode);

    property DesignScrollRight: Boolean index SB_Vert read FDesignScroll[SB_Vert] write SetDesignScroll;
    property DesignScrollBottom: Boolean index SB_Horz read FDesignScroll[SB_Horz] write SetDesignScroll;
  end;

implementation

{ TResizer }

procedure TResizer.SetDesignedForm(const AValue: IDesignedForm);

  function FindFirstFormParent: TCustomForm;
  begin
    Result := TCustomForm(FResizerFrame.Parent);
    while not (Result is TCustomForm) do
      Result := TCustomForm(Result.Parent);
  end;

var
  LLookupRoot: TComponent;
begin
  if FDesignedForm <> nil then
  begin
    FDesignedForm.OnChangeHackedBounds := nil;
  end;

  FDesignedForm := AValue;

  if FDesignedForm <> nil then
  begin
    FDesignedForm.BeginUpdate;
    
{$IFDEF USE_POPUP_PARENT_DESIGNER}
    FDesignedForm.RealPopupMode := pmExplicit;
    // for dock/undock
    FDesignedForm.RealPopupParent := nil;
    FDesignedForm.RealPopupParent := FindFirstFormParent;
{$ELSE}
    FDesignedForm.Form.ParentWindow := FResizerFrame.pClient.Handle; 
{$ENDIF}
    FDesignedForm.EndUpdate;
    FDesignedForm.OnChangeHackedBounds := @TryBoundSizerToDesignedForm;
    // w tym miejscu powinno już być zainicjalizowane obecnym edytorem na ktorym jest sizer :)
    // zautomatyzowac jakims interfejsem utilsy?
    LLookupRoot := LookupRoot(DesignedForm.Form);

    if FMainDTU <> nil then
      FMainDTU.Root := LLookupRoot;
  end
  else
  begin
    if FMainDTU <> nil then
      FMainDTU.Root := nil;
  end;

  FResizerFrame.DesignedForm := AValue;
end;

procedure TResizer.SetDesignScroll(AIndex: Integer; AValue: Boolean);

  procedure PerformScroll(AScroll: TScrollBar);
  begin
    AScroll.Visible := AValue;
    AScroll.Position:=0;
  end;

begin
  if FDesignScroll[AIndex] = AValue then
    Exit;

  FDesignScroll[AIndex] := AValue;

  case AIndex of
    SB_Horz: PerformScroll(sbH);
    SB_Vert: PerformScroll(sbV);
  else
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  end;
end;

procedure TResizer.sbScroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: Integer);
var
  LScrollPos: Integer;
begin
  if FDesignedForm = nil then
    Exit;

  if ScrollCode <> scEndScroll then
    FResizerFrame.HideSizeRects
  else
    FResizerFrame.ShowSizeRects;


  FDesignedForm.BeginUpdate;
  if Sender = sbV then
  begin
    // uwazaj by nie przekroczyc zakresu. Max ma calkowita wartosc wlacznie z codepage (patrz opis zmiennej FRealMaxV)
    ScrollPos := Min(ScrollPos, FRealMaxV);
    FResizerFrame.VerticalScrollPos := ScrollPos;
    // scroll w formie
    with FResizerFrame do // -8 gdy skalujemy formę i gdzy przestaje wymagać scrolla -> stąd Max
      LScrollPos := Max(ifthen(pBG.Top + BgTopMargin <= 0, ScrollPos - SIZER_RECT_SIZE - BgTopMargin, 0), 0);
    FDesignedForm.VertScrollPosition := LScrollPos;
  end;
  if Sender = sbH then
  begin
    ScrollPos := Min(ScrollPos, FRealMaxH);
    FResizerFrame.HorizontalScrollPos := ScrollPos;
    // scroll w formie
    with FResizerFrame do
      LScrollPos := Max(ifthen(pBG.Left + BgLeftMargin <= 0, ScrollPos - SIZER_RECT_SIZE - BgLeftMargin, 0), 0);
    FDesignedForm.HorzScrollPosition := LScrollPos;
  end;
  FDesignedForm.EndUpdate;

  FResizerFrame.PositionNodes(FResizerFrame);

  FDesignedForm.Form.Invalidate;
end;

constructor TResizer.Create(AParent: TWinControl);
begin
  FParent := AParent;
  // create layout
  FEDTU := TList.Create;

  if Assigned(FStarter) then
    FStarter(Self);

  pMainDTU := TPanel.Create(AParent);
  with pMainDTU do
  begin
    Parent := AParent;
    Align := alTop;
    BevelOuter := bvNone;
    Height := 0;
  end;

  pAddons := TPanel.Create(AParent);
  pAddons.Parent := AParent;
  pAddons.Align := alRight;
  pAddons.BevelOuter := bvNone;
  pAddons.Width:=0;

  if DTUManager <> nil then
  begin
    FMainDTU := DTUManager.CreateMainDTU(pMainDTU, pAddons);
  end;

  // Funny button
  bR := TButton.Create(AParent);
  with bR do
  begin
    Parent := AParent;
    Height := 17;
    Width := 17;
    AnchorSideRight.Control := pAddons;
    AnchorSideBottom.Control := AParent;
    AnchorSideBottom.Side := asrBottom;
    Anchors := [akRight, akBottom];
    Caption := 'R';
    Visible := True;
    OnClick := @FunnyButtonClick;
  end;

  sbV := TScrollBar.Create(AParent);
  with sbV do
  begin
    Kind := sbVertical;
    Parent := AParent;
    AnchorSideTop.Control := pMainDTU;
    AnchorSideTop.Side := asrBottom;
    AnchorSideRight.Control := pAddons;
    AnchorSideBottom.Control := bR;
    Width := 17;
    Anchors := [akTop, akRight, akBottom];
    Visible := False;
    OnScroll := @sbScroll;
  end;

  sbH := TScrollBar.Create(AParent);
  with sbH do
  begin
    Parent := AParent;
    AnchorSideLeft.Control := AParent;
    AnchorSideRight.Control := bR;
    AnchorSideBottom.Control := AParent;
    AnchorSideBottom.Side := asrBottom;
    Anchors := [akLeft, akRight, akBottom];
    Visible := False;
    OnScroll := @sbScroll;
  end;

  pMain := TPanel.Create(AParent);
  with pMain do
  begin
    Parent := AParent;
    AnchorSideLeft.Control := AParent;
    AnchorSideTop.Control := pMainDTU;
    AnchorSideTop.Side := asrBottom;
    AnchorSideRight.Control := sbV;
    AnchorSideBottom.Control := sbH;
    Anchors := [akTop, akLeft, akRight, akBottom];
    BevelOuter := bvNone;
  end;

  FResizerFrame := TResizerFrame.Create(AParent);
  FResizerFrame.Parent := pMain;
  FResizerFrame.Left := 0;
  FResizerFrame.Top := 0;
  FResizerFrame.OnNodePositioning := @NodePositioning;

  pMain.OnChangeBounds:=@TryBoundSizerToDesignedForm;
end;

destructor TResizer.Destroy;
begin
  FMainDTU := nil;
  FEDTU.Free;
  inherited Destroy;
end;

procedure TResizer.TryBoundSizerToDesignedForm(Sender: TObject);
var
  LWidth, LHeight: Integer;
  LScrollPos: Integer;
begin
  if DesignedForm = nil then
    Exit;

  FResizerFrame.Constraints.MaxWidth := pMain.Width;
  FResizerFrame.Constraints.MaxHeight := pMain.Height;

  LWidth  := DesignedForm.Width + FResizerFrame.BgLeftMargin + FResizerFrame.BgRightMargin + 2*FResizerFrame.SIZER_RECT_SIZE;
  LHeight := DesignedForm.Height + FResizerFrame.BgTopMargin + FResizerFrame.BgBottomMargin + 2*FResizerFrame.SIZER_RECT_SIZE;
  if not FResizerFrame.NodePositioning then
  begin
    FResizerFrame.Width := LWidth;
    FResizerFrame.Height := LHeight;
    // zaraportować... po rozszerzeniu i po zmniejszeniu constrait nie dzia dla frame (LCL bug)
    if FResizerFrame.Width > FResizerFrame.Constraints.MaxWidth then
      FResizerFrame.Width := FResizerFrame.Constraints.MaxWidth;
    if FResizerFrame.Height > FResizerFrame.Constraints.MaxHeight then
      FResizerFrame.Height := FResizerFrame.Constraints.MaxHeight;
  end;

  FResizerFrame.PositionNodes(FResizerFrame);

  DesignScrollBottom := FResizerFrame.Width < LWidth;
  sbH.Max := LWidth;
  FRealMaxH := LWidth - FResizerFrame.Width;
  sbH.PageSize := FResizerFrame.Width;
  if FResizerFrame.HorizontalScrollPos > FRealMaxH then
  begin
    FResizerFrame.HorizontalScrollPos := FRealMaxH;
    LScrollPos := FResizerFrame.HorizontalScrollPos;
    sbScroll(sbH, scEndScroll, LScrollPos);
  end;

  DesignScrollRight := FResizerFrame.Height < LHeight;
  sbV.Max := LHeight;
  FRealMaxV := LHeight - FResizerFrame.Height;
  sbV.PageSize := FResizerFrame.Height;
  if FResizerFrame.VerticalScrollPos > FRealMaxV then
  begin
    FResizerFrame.VerticalScrollPos := FRealMaxV;
    LScrollPos := FResizerFrame.VerticalScrollPos;
    sbScroll(sbV, scEndScroll, LScrollPos);
  end;

  {!}
  FResizerFrame.ClientChangeBounds(nil);

  // kazdy edytor moze miec scrole w roznych pozycjach. ten event jest wywolywany i to jedyna mozliwosc ustawienia pozycji
  LScrollPos := FResizerFrame.VerticalScrollPos;
  sbScroll(sbV, scEndScroll, LScrollPos);
  LScrollPos := FResizerFrame.HorizontalScrollPos;
  sbScroll(sbH, scEndScroll, LScrollPos);

  if Supports(FDesignedForm, IDesignedFormBackground) then
    (FDesignedForm as IDesignedFormBackground).RefreshValues;
end;

procedure TResizer.NodePositioning(Sender: TObject; PositioningKind: TPositioningKind; PositioningCode: TPositioningCode);

  procedure Positioning;
  var
    LHiddenHeight: Integer;
    LHiddenWidth: Integer;
  begin
    DesignedForm.BeginUpdate;

    if pkRight in PositioningKind then
    begin
      LHiddenWidth := sbH.Position;
      if LHiddenWidth > FResizerFrame.DesignedWidthToScroll then
        LHiddenWidth := FResizerFrame.DesignedWidthToScroll;
      DesignedForm.RealWidth := FResizerFrame.pClient.Width;
      DesignedForm.Width := FResizerFrame.pClient.Width + LHiddenWidth;
    end;

    if pkBottom in PositioningKind then
    begin
      LHiddenHeight := sbV.Position;
      if LHiddenHeight > FResizerFrame.DesignedHeightToScroll then
        LHiddenHeight := FResizerFrame.DesignedHeightToScroll;
      DesignedForm.RealHeight := FResizerFrame.pClient.Height;
      DesignedForm.Height := FResizerFrame.pClient.Height + LHiddenHeight;
    end;

    DesignedForm.EndUpdate;
  end;

  procedure PositioningEnd;
  begin
    TryBoundSizerToDesignedForm(nil);
  end;

begin
  if DesignedForm = nil then
    Exit;

  case PositioningCode of
    pcPositioningEnd: PositioningEnd;
    pcPositioning: Positioning;
  end;
end;

procedure TResizer.FunnyButtonClick(Sender: TObject);
begin
  ShowMessage('Funny button with no functionality!'
              + sLineBreak
              + sLineBreak +
              'Regards'
              + sLineBreak +
              'Maciej Izak'
              + sLineBreak
              + sLineBreak + 'DaThoX team FreeSparta.com project');
end;

end.

