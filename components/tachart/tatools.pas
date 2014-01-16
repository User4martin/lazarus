{

 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Authors: Alexander Klenin

}

unit TATools;

interface

{$H+}

uses
  Classes, Controls, CustomTimer, Forms, FPCanvas, Types,
  TAChartUtils, TADrawUtils, TAGraph, TATypes;

type

  TChartToolset = class;
  TChartTool = class;

  TChartToolEvent = procedure (ATool: TChartTool; APoint: TPoint) of object;

  TChartToolDrawingMode = (tdmDefault, tdmNormal, tdmXor);
  TChartToolEffectiveDrawingMode = tdmNormal .. tdmXor;

  { TChartTool }

  TChartTool = class(TBasicChartTool)
  strict private
    FActiveCursor: TCursor;
    FDrawingMode: TChartToolDrawingMode;
    FEnabled: Boolean;
    FEscapeCancels: Boolean;
    FEventsAfter: array [TChartToolEventId] of TChartToolEvent;
    FEventsBefore: array [TChartToolEventId] of TChartToolEvent;
    FOldCursor: TCursor;
    FShift: TShiftState;
    FToolset: TChartToolset;
    FTransparency: TChartTransparency;
    function GetAfterEvent(AIndex: Integer): TChartToolEvent;
    function GetBeforeEvent(AIndex: Integer): TChartToolEvent;
    procedure SetActiveCursor(AValue: TCursor);
    procedure SetAfterEvent(AIndex: Integer; AValue: TChartToolEvent);
    procedure SetBeforeEvent(AIndex: Integer; AValue: TChartToolEvent);
    procedure SetDrawingMode(AValue: TChartToolDrawingMode);
    procedure SetToolset(AValue: TChartToolset);
  protected
    procedure ReadState(Reader: TReader); override;
    procedure SetParentComponent(AParent: TComponent); override;
    property DrawingMode: TChartToolDrawingMode
      read FDrawingMode write SetDrawingMode default tdmDefault;
  strict protected
    procedure Activate; override;
    procedure Cancel; virtual;
    procedure Deactivate; override;
    function EffectiveDrawingMode: TChartToolEffectiveDrawingMode;
    function GetIndex: Integer; override;
    function IsActive: Boolean;
    procedure KeyDown(APoint: TPoint); virtual;
    procedure KeyUp(APoint: TPoint); virtual;
    procedure MouseDown(APoint: TPoint); virtual;
    procedure MouseMove(APoint: TPoint); virtual;
    procedure MouseUp(APoint: TPoint); virtual;
    procedure MouseWheelDown(APoint: TPoint); virtual;
    procedure MouseWheelUp(APoint: TPoint); virtual;
    procedure PrepareDrawingModePen(ADrawer: IChartDrawer; APen: TFPCustomPen);
    procedure RestoreCursor;
    procedure SetCursor;
    procedure SetIndex(AValue: Integer); override;
    procedure StartTransparency;

    property EscapeCancels: Boolean
      read FEscapeCancels write FEscapeCancels default false;
    property Transparency: TChartTransparency
      read FTransparency write FTransparency default 0;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    function GetParentComponent: TComponent; override;
    function HasParent: Boolean; override;
  public
    procedure AfterDraw(AChart: TChart; ADrawer: IChartDrawer); virtual;
    procedure Assign(Source: TPersistent); override;
    procedure Dispatch(
      AChart: TChart; AEventId: TChartToolEventId; APoint: TPoint); overload;
    procedure Draw(AChart: TChart; ADrawer: IChartDrawer); virtual;
    procedure Handled;

    property ActiveCursor: TCursor
      read FActiveCursor write SetActiveCursor default crDefault;
    property Toolset: TChartToolset read FToolset write SetToolset;
  published
    property Enabled: Boolean read FEnabled write FEnabled default true;
    property Shift: TShiftState read FShift write FShift default [];
  published
    property OnAfterKeyDown: TChartToolEvent
      index 0 read GetAfterEvent write SetAfterEvent;
    property OnAfterKeyUp: TChartToolEvent
      index 1 read GetAfterEvent write SetAfterEvent;
    property OnAfterMouseDown: TChartToolEvent
      index 2 read GetAfterEvent write SetAfterEvent;
    property OnAfterMouseMove: TChartToolEvent
      index 3 read GetAfterEvent write SetAfterEvent;
    property OnAfterMouseUp: TChartToolEvent
      index 4 read GetAfterEvent write SetAfterEvent;
    property OnAfterMouseWheelDown: TChartToolEvent
      index 5 read GetAfterEvent write SetAfterEvent;
    property OnAfterMouseWheelUp: TChartToolEvent
      index 6 read GetAfterEvent write SetAfterEvent;

    property OnBeforeKeyDown: TChartToolEvent
      index 0 read GetBeforeEvent write SetBeforeEvent;
    property OnBeforeKeyUp: TChartToolEvent
      index 1 read GetBeforeEvent write SetBeforeEvent;
    property OnBeforeMouseDown: TChartToolEvent
      index 2 read GetBeforeEvent write SetBeforeEvent;
    property OnBeforeMouseMove: TChartToolEvent
      index 3 read GetBeforeEvent write SetBeforeEvent;
    property OnBeforeMouseUp: TChartToolEvent
      index 4 read GetBeforeEvent write SetBeforeEvent;
    property OnBeforeMouseWheelDown: TChartToolEvent
      index 5 read GetBeforeEvent write SetBeforeEvent;
    property OnBeforeMouseWheelUp: TChartToolEvent
      index 6 read GetBeforeEvent write SetBeforeEvent;
  end;

  {$IFNDEF fpdoc} // Workaround for issue #18549.
  TChartToolsEnumerator = specialize TTypedFPListEnumerator<TChartTool>;
  {$ENDIF}

  TChartToolClass = class of TChartTool;

  TChartTools = class(TIndexedComponentList)
  public
    function GetEnumerator: TChartToolsEnumerator;
  end;

  { TChartToolset }

  TChartToolset = class(TBasicChartToolset)
  strict private
    FDispatchedShiftState: TShiftState;
    FTools: TChartTools;
    function GetItem(AIndex: Integer): TChartTool;
  private
    FIsHandled: Boolean;
  protected
    procedure SetName(const AValue: TComponentName); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure SetChildOrder(Child: TComponent; Order: Integer); override;
  public
    function Dispatch(
      AChart: TChart; AEventId: TChartToolEventId;
      AShift: TShiftState; APoint: TPoint): Boolean; override;
    procedure Draw(AChart: TChart; ADrawer: IChartDrawer); override;
    property DispatchedShiftState: TShiftState read FDispatchedShiftState;
    property Item[AIndex: Integer]: TChartTool read GetItem; default;
  published
    property Tools: TChartTools read FTools;
  end;

  TUserDefinedTool = class(TChartTool)
  end;

  { TBasicZoomTool }

  TBasicZoomTool = class(TChartTool)
  strict private
    FAnimationInterval: Cardinal;
    FAnimationSteps: Cardinal;
    FCurrentStep: Cardinal;
    FExtDst: TDoubleRect;
    FExtSrc: TDoubleRect;
    FFullZoom: Boolean;
    FTimer: TCustomTimer;

    procedure OnTimer(ASender: TObject);
  protected
    procedure DoZoom(const ANewExtent: TDoubleRect; AFull: Boolean);
    function IsAnimating: Boolean; inline;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    procedure Deactivate; override;
  published
    property AnimationInterval: Cardinal
      read FAnimationInterval write FAnimationInterval default 0;
    property AnimationSteps: Cardinal
      read FAnimationSteps write FAnimationSteps default 0;
  end;

  TZoomRatioLimit = (zrlNone, zrlProportional, zrlFixedX, zrlFixedY);

  TZoomDragTool = class(TBasicZoomTool)
  published
  type
    TRestoreExtentOn = (
      zreDragTopLeft, zreDragTopRight, zreDragBottomLeft, zreDragBottomRight,
      zreClick, zreDifferentDrag);
    TRestoreExtentOnSet = set of TRestoreExtentOn;
    TZoomDragBrush = TClearBrush;
  strict private
    FAdjustSelection: Boolean;
    FBrush: TZoomDragBrush;
    FFrame: TChartPen;
    FPrevDragDir: TRestoreExtentOn;
    FRatioLimit: TZoomRatioLimit;
    FRestoreExtentOn: TRestoreExtentOnSet;
    FSelectionRect: TRect;
    function CalculateNewExtent: TDoubleRect;
    function CalculateDrawRect: TRect;
    function GetProportional: Boolean;
    procedure SetBrush(AValue: TZoomDragBrush);
    procedure SetFrame(AValue: TChartPen);
    procedure SetProportional(AValue: Boolean);
    procedure SetSelectionRect(AValue: TRect);
  strict protected
    procedure Cancel; override;
  public
    procedure MouseDown(APoint: TPoint); override;
    procedure MouseMove(APoint: TPoint); override;
    procedure MouseUp(APoint: TPoint); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Draw(AChart: TChart; ADrawer: IChartDrawer); override;
    property SelectionRect: TRect read FSelectionRect write SetSelectionRect;
  published
    property AdjustSelection: Boolean
      read FAdjustSelection write FAdjustSelection default true;
    property Brush: TZoomDragBrush read FBrush write SetBrush;
    property DrawingMode;
    property EscapeCancels;
    property Frame: TChartPen read FFrame write SetFrame;
    property Proportional: Boolean
      read GetProportional write SetProportional stored false default false;
      deprecated;
    property RatioLimit: TZoomRatioLimit
      read FRatioLimit write FRatioLimit default zrlNone;
    property RestoreExtentOn: TRestoreExtentOnSet
      read FRestoreExtentOn write FRestoreExtentOn
      default [zreDragTopLeft, zreDragTopRight, zreDragBottomLeft, zreClick];
    property Transparency;
  end;

  TBasicZoomStepTool = class(TBasicZoomTool)
  strict private
    FFixedPoint: Boolean;
    FZoomFactor: Double;
    FZoomRatio: Double;
    function ZoomFactorIsStored: boolean;
    function ZoomRatioIsStored: boolean;
  strict protected
    procedure DoZoomStep(const APoint: TPoint; const AFactor: TDoublePoint);
  public
    constructor Create(AOwner: TComponent); override;
  published
    property FixedPoint: Boolean read FFixedPoint write FFixedPoint default true;
    property ZoomFactor: Double
      read FZoomFactor write FZoomFactor stored ZoomFactorIsStored;
    property ZoomRatio: Double
      read FZoomRatio write FZoomRatio stored ZoomRatioIsStored;
  end;

  TZoomClickTool = class(TBasicZoomStepTool)
  public
    procedure MouseDown(APoint: TPoint); override;
  end;

  TZoomMouseWheelTool = class(TBasicZoomStepTool)
  public
    procedure MouseWheelDown(APoint: TPoint); override;
    procedure MouseWheelUp(APoint: TPoint); override;
  end;

  TPanDirection = (pdLeft, pdUp, pdRight, pdDown);
  TPanDirectionSet = set of TPanDirection;

const
  PAN_DIRECTIONS_ALL = [Low(TPanDirection) .. High(TPanDirection)];

type

  { TBasicPanTool }

  TBasicPanTool = class(TChartTool)
  strict private
    FLimitToExtent: TPanDirectionSet;
  strict protected
    procedure PanBy(AOffset: TPoint);
  public
    constructor Create(AOwner: TComponent); override;
  published
    property LimitToExtent: TPanDirectionSet
      read FLimitToExtent write FLimitToExtent default [];
  end;

  { TPanDragTool }

  TPanDragTool = class(TBasicPanTool)
  strict private
    FDirections: TPanDirectionSet;
    FMinDragRadius: Cardinal;
    FOrigin: TPoint;
    FPrev: TPoint;
  strict protected
    procedure Cancel; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure MouseDown(APoint: TPoint); override;
    procedure MouseMove(APoint: TPoint); override;
    procedure MouseUp(APoint: TPoint); override;
  published
    property ActiveCursor default crSizeAll;
    property Directions: TPanDirectionSet
      read FDirections write FDirections default PAN_DIRECTIONS_ALL;
    property EscapeCancels;
    property MinDragRadius: Cardinal
      read FMinDragRadius write FMinDragRadius default 0;
  end;

  { TPanClickTool }

  TPanClickTool = class(TBasicPanTool)
  strict private
    FInterval: Cardinal;
    FMargins: TChartMargins;
    FOffset: TPoint;
    FTimer: TCustomTimer;

    function GetOffset(APoint: TPoint): TPoint;
    procedure OnTimer(ASender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    procedure Deactivate; override;
    procedure MouseDown(APoint: TPoint); override;
    procedure MouseMove(APoint: TPoint); override;
    procedure MouseUp(APoint: TPoint); override;
  published
    property ActiveCursor default crSizeAll;
    property Interval: Cardinal read FInterval write FInterval default 0;
    property Margins: TChartMargins read FMargins write FMargins;
  end;

  { TPanMouseWheelTool }

  TPanMouseWheelTool = class(TBasicPanTool)
  strict private
    FStep: Cardinal;
    FWheelUpDirection: TPanDirection;

    procedure DoPan(AStep: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    procedure MouseWheelDown(APoint: TPoint); override;
    procedure MouseWheelUp(APoint: TPoint); override;
  published
    property Step: Cardinal read FStep write FStep default 10;
    property WheelUpDirection: TPanDirection
      read FWheelUpDirection write FWheelUpDirection default pdUp;
  end;

  TChartDistanceMode = (cdmXY, cdmOnlyX, cdmOnlyY);

  TDataPointTool = class(TChartTool)
  public
  type
    TPointRef = class
    private
      FGraphPos: TDoublePoint;
      FIndex: Integer;
      FSeries: TBasicChartSeries;

      procedure SetGraphPos(const ANewPos: TDoublePoint);
    public
      procedure Assign(ASource: TPointRef);
      function AxisPos(ADefaultSeries: TBasicChartSeries = nil): TDoublePoint;
      property GraphPos: TDoublePoint read FGraphPos;
      property Index: Integer read FIndex;
      property Series: TBasicChartSeries read FSeries;
    end;

  strict private
    FAffectedSeries: TPublishedIntegerSet;
    FDistanceMode: TChartDistanceMode;
    FGrabRadius: Integer;
    function GetAffectedSeries: String; inline;
    function GetIsSeriesAffected(AIndex: Integer): Boolean; inline;
    procedure SetAffectedSeries(AValue: String); inline;
    procedure SetIsSeriesAffected(AIndex: Integer; AValue: Boolean); inline;
  strict protected
    FNearestGraphPoint: TDoublePoint;
    FPointIndex: Integer;
    FSeries: TBasicChartSeries;
    procedure FindNearestPoint(APoint: TPoint);
  public
    constructor Create(AOwner: TComponent); override;
  public
    property IsSeriesAffected[AIndex: Integer]: Boolean
      read GetIsSeriesAffected write SetIsSeriesAffected;
    property NearestGraphPoint: TDoublePoint read FNearestGraphPoint;
    property PointIndex: Integer read FPointIndex;
    property Series: TBasicChartSeries read FSeries;
  published
    property AffectedSeries: String
      read GetAffectedSeries write SetAffectedSeries;
    property DistanceMode: TChartDistanceMode
      read FDistanceMode write FDistanceMode default cdmXY;
    property GrabRadius: Integer read FGrabRadius write FGrabRadius default 4;
  end;

  TDataPointDragTool = class;
  TDataPointDragEvent = procedure (
    ASender: TDataPointDragTool; var AGraphPoint: TDoublePoint) of object;

  { TDataPointDragTool }

  TDataPointDragTool = class(TDataPointTool)
  strict private
    FOnDrag: TDataPointDragEvent;
    FOnDragStart: TDataPointDragEvent;
    FOrigin: TDoublePoint;
  strict protected
    procedure Cancel; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure MouseDown(APoint: TPoint); override;
    procedure MouseMove(APoint: TPoint); override;
    procedure MouseUp(APoint: TPoint); override;
    property Origin: TDoublePoint read FOrigin;
  published
    property ActiveCursor default crSizeAll;
    property EscapeCancels default true;
    property OnDrag: TDataPointDragEvent read FOnDrag write FOnDrag;
    property OnDragStart: TDataPointDragEvent
      read FOnDragStart write FOnDragStart;
  end;

  { TDataPointClickTool }

  TDataPointClickTool = class(TDataPointTool)
  strict private
    FMouseDownPoint: TPoint;
    FOnPointClick: TChartToolEvent;
  public
    procedure MouseDown(APoint: TPoint); override;
    procedure MouseUp(APoint: TPoint); override;
  published
    property ActiveCursor;
    property OnPointClick: TChartToolEvent
      read FOnPointClick write FOnPointClick;
  end;

  TDataPointHintTool = class;

  TChartToolHintEvent = procedure (
    ATool: TDataPointHintTool; const APoint: TPoint; var AHint: String) of object;

  TChartToolHintPositionEvent = procedure (
    ATool: TDataPointHintTool; var APoint: TPoint) of object;

  { TDataPointHintTool }

  TDataPointHintTool = class(TDataPointTool)
  strict private
    FHintWindow: THintWindow;
    FOnHint: TChartToolHintEvent;
    FOnHintPosition: TChartToolHintPositionEvent;
    FPrevPointIndex: Integer;
    FPrevSeries: TBasicChartSeries;
    FUseApplicationHint: Boolean;
    FUseDefaultHintText: Boolean;
    procedure HideHint;
    procedure SetUseApplicationHint(AValue: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure KeyDown(APoint: TPoint); override;
    procedure KeyUp(APoint: TPoint); override;
    procedure MouseDown(APoint: TPoint); override;
    procedure MouseMove(APoint: TPoint); override;
    procedure MouseUp(APoint: TPoint); override;
  published
    property ActiveCursor;
    property OnHint: TChartToolHintEvent read FOnHint write FOnHint;
    property OnHintPosition: TChartToolHintPositionEvent
      read FOnHintPosition write FOnHintPosition;
    property UseApplicationHint: Boolean
      read FUseApplicationHint write SetUseApplicationHint default false;
    property UseDefaultHintText: Boolean
      read FUseDefaultHintText write FUseDefaultHintText default true;
  end;

  { TDataPointDrawTool }

  TDataPointDrawTool = class;

  TChartDataPointDrawEvent = procedure (ASender: TDataPointDrawTool) of object;

  TDataPointDrawTool = class(TDataPointTool)
  strict private
    FOnDraw: TChartDataPointDrawEvent;
  strict protected
    FPen: TChartPen;
    procedure DoDraw; virtual;
    procedure DoHide; virtual;
    procedure SetPen(AValue: TChartPen);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Draw(AChart: TChart; ADrawer: IChartDrawer); override;
    procedure Hide; virtual;
  published
    property DrawingMode;
    property GrabRadius default 20;
    property OnDraw: TChartDataPointDrawEvent read FOnDraw write FOnDraw;
  end;

  TChartCrosshairShape = (ccsNone, ccsVertical, ccsHorizontal, ccsCross);

  { TDataPointCrossHairTool }

  TDataPointCrosshairTool = class(TDataPointDrawTool)
  strict private
    FPosition: TDoublePoint;
    FShape: TChartCrosshairShape;
    FSize: Integer;
  strict protected
    procedure DoDraw; override;
    procedure DoHide; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Draw(AChart: TChart; ADrawer: IChartDrawer); override;
    procedure KeyDown(APoint: TPoint); override;
    procedure MouseDown(APoint: TPoint); override;
    procedure MouseMove(APoint: TPoint); override;
    property Position: TDoublePoint read FPosition;
  published
    property CrosshairPen: TChartPen read FPen write SetPen;
    property Shape: TChartCrosshairShape
      read FShape write FShape default ccsCross;
    property Size: Integer read FSize write FSize default -1;
  end;

  TReticuleTool = class(TChartTool)
  public
    procedure MouseMove(APoint: TPoint); override;
  end;

  procedure Register;
  procedure RegisterChartToolClass(
    AToolClass: TChartToolClass; const ACaption: String);

var
  ToolsClassRegistry: TStringList;

implementation

uses
  GraphMath, InterfaceBase, LCLType, LCLIntf, Math, SysUtils,
  TACustomSeries, TAEnumerators, TAGeometry, TAMath;

function InitBuiltinTools(AChart: TChart): TBasicChartToolset;
var
  ts: TChartToolset;
begin
  ts := TChartToolset.Create(AChart);
  Result := ts;
  with TZoomDragTool.Create(AChart) do begin
    Shift := [ssLeft];
    Toolset := ts;
  end;
  with TPanDragTool.Create(AChart) do begin
    Shift := [ssRight];
    Toolset := ts;
  end;
  TReticuleTool.Create(AChart).Toolset := ts;
end;

procedure Register;
var
  i: Integer;
begin
  for i := 0 to ToolsClassRegistry.Count - 1 do
    RegisterNoIcon([TChartToolClass(ToolsClassRegistry.Objects[i])]);
  RegisterComponents(CHART_COMPONENT_IDE_PAGE, [TChartToolset]);
end;

procedure RegisterChartToolClass(
  AToolClass: TChartToolClass; const ACaption: String);
begin
  RegisterClass(AToolClass);
  ToolsClassRegistry.AddObject(ACaption, TObject(AToolClass));
end;

{ TDataPointTool.TPointRef }

procedure TDataPointTool.TPointRef.Assign(ASource: TPointRef);
begin
  with ASource do begin
    Self.FGraphPos := FGraphPos;
    Self.FIndex := FIndex;
    Self.FSeries := FSeries;
  end;
end;

function TDataPointTool.TPointRef.AxisPos(
  ADefaultSeries: TBasicChartSeries): TDoublePoint;
var
  s: TBasicChartSeries;
begin
  s := Series;
  if s = nil then
    s := ADefaultSeries;
  if s = nil then
    Result := GraphPos
  else
    Result := DoublePoint(s.GraphToAxisX(GraphPos.X), s.GraphToAxisY(GraphPos.Y));
end;

procedure TDataPointTool.TPointRef.SetGraphPos(const ANewPos: TDoublePoint);
begin
  FGraphPos := ANewPos;
  FIndex := -1;
  FSeries := nil;
end;

{ TChartTool }

procedure TChartTool.Activate;
var
  i: Integer;
begin
  i := FChart.ActiveToolIndex;
  if (i <> Index) and InRange(i, 0, Toolset.Tools.Count) then
    Toolset[i].Deactivate;
  inherited;
  SetCursor;
end;

procedure TChartTool.AfterDraw(AChart: TChart; ADrawer: IChartDrawer);
begin
  Unused(AChart, ADrawer);
  if not IsActive then
    FChart := nil;
end;

procedure TChartTool.Assign(Source: TPersistent);
begin
  if Source is TChartTool then
    with TChartTool(Source) do begin
      Self.FEnabled := Enabled;
      Self.FShift := Shift;
    end
  else
    inherited Assign(Source);
end;

procedure TChartTool.Cancel;
begin
  // Empty.
end;

constructor TChartTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEnabled := true;
  FActiveCursor := crDefault;
end;

procedure TChartTool.Deactivate;
begin
  RestoreCursor;
  inherited;
end;

destructor TChartTool.Destroy;
begin
  Toolset := nil;
  inherited;
end;

procedure TChartTool.Dispatch(
  AChart: TChart; AEventId: TChartToolEventId; APoint: TPoint);
var
  ev: TChartToolEvent;
begin
  if not Enabled or (FChart <> nil) and (FChart <> AChart) then exit;
  FChart := AChart;
  ev := FEventsBefore[AEventId];
  if Assigned(ev) then begin
    ev(Self, APoint);
    if Toolset.FIsHandled then exit;
  end;
  case AEventId of
    evidKeyDown       : KeyDown       (APoint);
    evidKeyUp         : KeyUp         (APoint);
    evidMouseDown     : MouseDown     (APoint);
    evidMouseMove     : MouseMove     (APoint);
    evidMouseUp       : MouseUp       (APoint);
    evidMouseWheelDown: MouseWheelDown(APoint);
    evidMouseWheelUp  : MouseWheelUp  (APoint);
  end;
  ev := FEventsAfter[AEventId];
  if Assigned(ev) then
    ev(Self, APoint);
  if not IsActive then
    FChart := nil;
end;

procedure TChartTool.Draw(AChart: TChart; ADrawer: IChartDrawer);
begin
  Unused(ADrawer);
  FChart := AChart;
end;

function TChartTool.EffectiveDrawingMode: TChartToolEffectiveDrawingMode;
begin
  if DrawingMode <> tdmDefault then
    Result := DrawingMode
  else if WidgetSet.LCLPlatform in [lpGtk, lpGtk2, lpWin32] then
    Result := tdmXor
  else
    Result := tdmNormal;
end;

function TChartTool.GetAfterEvent(AIndex: Integer): TChartToolEvent;
begin
  Result := FEventsAfter[TChartToolEventId(AIndex)];
end;

function TChartTool.GetBeforeEvent(AIndex: Integer): TChartToolEvent;
begin
  Result := FEventsBefore[TChartToolEventId(AIndex)];
end;

function TChartTool.GetIndex: Integer;
begin
  if Toolset = nil then
    Result := -1
  else
    Result := Toolset.Tools.IndexOf(Self);
end;

function TChartTool.GetParentComponent: TComponent;
begin
  Result := FToolset;
end;

procedure TChartTool.Handled;
begin
  Toolset.FIsHandled := true;
end;

function TChartTool.HasParent: Boolean;
begin
  Result := true;
end;

function TChartTool.IsActive: Boolean;
begin
  Result := (FChart <> nil) and (FChart.ActiveToolIndex = Index);
end;

procedure TChartTool.KeyDown(APoint: TPoint);
begin
  Unused(APoint);
  if EscapeCancels and ((GetKeyState(VK_ESCAPE) and $8000) <> 0) then
    Cancel;
end;

procedure TChartTool.KeyUp(APoint: TPoint);
begin
  Unused(APoint);
end;

procedure TChartTool.MouseDown(APoint: TPoint);
begin
  Unused(APoint);
end;

procedure TChartTool.MouseMove(APoint: TPoint);
begin
  Unused(APoint);
end;

procedure TChartTool.MouseUp(APoint: TPoint);
begin
  Unused(APoint);
end;

procedure TChartTool.MouseWheelDown(APoint: TPoint);
begin
  Unused(APoint);
end;

procedure TChartTool.MouseWheelUp(APoint: TPoint);
begin
  Unused(APoint);
end;

procedure TChartTool.PrepareDrawingModePen(
  ADrawer: IChartDrawer; APen: TFPCustomPen);
begin
  ADrawer.SetXor(EffectiveDrawingMode = tdmXor);
  ADrawer.Pen := APen;
end;

procedure TChartTool.ReadState(Reader: TReader);
begin
  inherited ReadState(Reader);
  if Reader.Parent is TChartToolset then
    Toolset := Reader.Parent as TChartToolset;
end;

procedure TChartTool.RestoreCursor;
begin
  if ActiveCursor = crDefault then exit;
  FChart.Cursor := FOldCursor;
end;

procedure TChartTool.SetActiveCursor(AValue: TCursor);
begin
  if FActiveCursor = AValue then exit;
  if IsActive then
    RestoreCursor;
  FActiveCursor := AValue;
  if IsActive then
    SetCursor;
end;

procedure TChartTool.SetAfterEvent(AIndex: Integer; AValue: TChartToolEvent);
begin
  FEventsAfter[TChartToolEventId(AIndex)] := AValue;
end;

procedure TChartTool.SetBeforeEvent(AIndex: Integer; AValue: TChartToolEvent);
begin
  FEventsBefore[TChartToolEventId(AIndex)] := AValue;
end;

procedure TChartTool.SetCursor;
begin
  if ActiveCursor = crDefault then exit;
  FOldCursor := FChart.Cursor;
  FChart.Cursor := ActiveCursor;
end;

procedure TChartTool.SetDrawingMode(AValue: TChartToolDrawingMode);
begin
  if FDrawingMode = AValue then exit;
  FDrawingMode := AValue;
end;

procedure TChartTool.SetIndex(AValue: Integer);
begin
  Toolset.Tools.Move(Index, EnsureRange(AValue, 0, Toolset.Tools.Count - 1));
end;

procedure TChartTool.SetParentComponent(AParent: TComponent);
begin
  if not (csLoading in ComponentState) then
    Toolset := AParent as TChartToolset;
end;

procedure TChartTool.SetToolset(AValue: TChartToolset);
begin
  if FToolset = AValue then exit;
  if FToolset <> nil then
    FToolset.Tools.Remove(Self);
  FToolset := AValue;
  if FToolset <> nil then
    FToolset.Tools.Add(Self);
end;

procedure TChartTool.StartTransparency;
begin
  if EffectiveDrawingMode = tdmNormal then
    Chart.Drawer.SetTransparency(Transparency);
end;

{ TChartTools }

function TChartTools.GetEnumerator: TChartToolsEnumerator;
begin
  Result := TChartToolsEnumerator.Create(Self);
end;

{ TChartToolset }

constructor TChartToolset.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTools := TChartTools.Create;
end;

destructor TChartToolset.Destroy;
begin
  while Tools.Count > 0 do
    Item[Tools.Count - 1].Free;
  FreeAndNil(FTools);
  inherited;
end;

function TChartToolset.Dispatch(
  AChart: TChart; AEventId: TChartToolEventId;
  AShift: TShiftState; APoint: TPoint): Boolean;
var
  candidates: array of TChartTool;
  candidateCount: Integer;

  procedure AddCandidate(AIndex: Integer);
  begin
    candidates[candidateCount] := Item[AIndex];
    candidateCount += 1;
  end;

var
  i, ai: Integer;
begin
  if Tools.Count = 0 then exit(false);

  SetLength(candidates, Tools.Count);
  candidateCount := 0;

  ai := AChart.ActiveToolIndex;
  if InRange(ai, 0, Tools.Count - 1) then
    AddCandidate(ai);
  for i := 0 to Tools.Count - 1 do
    if (i <> ai) and (Item[i].Shift = AShift) then
      AddCandidate(i);

  FDispatchedShiftState := AShift;
  FIsHandled := false;
  for i := 0 to candidateCount - 1 do begin
    candidates[i].Dispatch(AChart, AEventId, APoint);
    if FIsHandled then exit(true);
  end;
  Result := false;
end;

procedure TChartToolset.Draw(AChart: TChart; ADrawer: IChartDrawer);
var
  t: TChartTool;
begin
  for t in Tools do begin
    t.Draw(AChart, ADrawer);
    t.AfterDraw(AChart, ADrawer);
  end;
end;

procedure TChartToolset.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  t: TChartTool;
begin
  for t in Tools do
    if t.Owner = Root then
      Proc(t);
end;

function TChartToolset.GetItem(AIndex: Integer): TChartTool;
begin
  Result := TChartTool(Tools.Items[AIndex]);
end;

procedure TChartToolset.SetChildOrder(Child: TComponent; Order: Integer);
var
  i: Integer;
begin
  i := Tools.IndexOf(Child);
  if i >= 0 then
    Tools.Move(i, Order);
end;

procedure TChartToolset.SetName(const AValue: TComponentName);
var
  oldName: String;
begin
  if Name = AValue then exit;
  oldName := Name;
  inherited SetName(AValue);
  if csDesigning in ComponentState then
    Tools.ChangeNamePrefix(oldName, AValue);
end;

{ TBasicZoomTool }

constructor TBasicZoomTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTimer := TCustomTimer.Create(nil);
  FTimer.Enabled := false;
  FTimer.OnTimer := @OnTimer;
end;

procedure TBasicZoomTool.Deactivate;
begin
  FTimer.Enabled := false;
  inherited;
end;

destructor TBasicZoomTool.Destroy;
begin
  FreeAndNil(FTimer);
  inherited Destroy;
end;

procedure TBasicZoomTool.DoZoom(const ANewExtent: TDoubleRect; AFull: Boolean);
begin
  if (AnimationInterval = 0) or (AnimationSteps = 0) then begin
    if AFull then
      FChart.ZoomFull
    else
      FChart.LogicalExtent := ANewExtent;
    if IsActive then
      Deactivate;
    exit;
  end;
  if not IsActive then
    Activate;
  FExtSrc := FChart.LogicalExtent;
  FExtDst := ANewExtent;
  FFullZoom := AFull;
  FCurrentStep := 0;
  FTimer.Interval := AnimationInterval;
  FTimer.Enabled := true;
end;

function TBasicZoomTool.IsAnimating: Boolean;
begin
  Result := FTimer.Enabled;
end;

procedure TBasicZoomTool.OnTimer(ASender: TObject);
var
  ext: TDoubleRect;
  t: Double;
  i: Integer;
begin
  Unused(ASender);
  FCurrentStep += 1;
  FTimer.Enabled := FCurrentStep < AnimationSteps;
  if FFullZoom and not IsAnimating then
    FChart.ZoomFull
  else begin
    t := FCurrentStep / AnimationSteps;
    for i := Low(ext.coords) to High(ext.coords) do
      ext.coords[i] := WeightedAverage(FExtSrc.coords[i], FExtDst.coords[i], t);
    NormalizeRect(ext);
    FChart.LogicalExtent := ext;
  end;
  if not IsAnimating then
    Deactivate;
end;

{ TZoomDragTool }

function TZoomDragTool.CalculateDrawRect: TRect;
begin
  if not AdjustSelection or (RatioLimit = zrlNone) then exit(FSelectionRect);
  with CalculateNewExtent do begin
    Result.TopLeft := Chart.GraphToImage(a);
    Result.BottomRight := Chart.GraphToImage(b);
  end;
end;

function TZoomDragTool.CalculateNewExtent: TDoubleRect;

  procedure CheckProportions;
  var
    newSize, oldSize: TDoublePoint;
    coeff: Double;
  begin
    case RatioLimit of
      zrlNone: exit;
      zrlProportional: begin
        newSize := Result.b - Result.a;
        oldSize := FChart.LogicalExtent.b - FChart.LogicalExtent.a;
        coeff := newSize.Y * oldSize.X;
        if coeff = 0 then exit;
        coeff := newSize.X * oldSize.Y / coeff;
        if coeff = 0 then exit;
        if coeff > 1 then
          ExpandRange(Result.a.Y, Result.b.Y, (coeff - 1) / 2)
        else
          ExpandRange(Result.a.X, Result.b.X, (1 / coeff - 1) / 2);
      end;
      zrlFixedX:
        with FChart.GetFullExtent do begin
          Result.a.X := a.X;
          Result.b.X := b.X;
        end;
      zrlFixedY:
        with FChart.GetFullExtent do begin
          Result.a.Y := a.Y;
          Result.b.Y := b.Y;
        end;
    end;
  end;

begin
  with FSelectionRect do begin
    Result.a := Chart.ImageToGraph(TopLeft);
    Result.b := Chart.ImageToGraph(BottomRight);
  end;
  NormalizeRect(Result);
  CheckProportions;
end;

procedure TZoomDragTool.Cancel;
begin
  if not IsActive then exit;
  if EffectiveDrawingMode = tdmXor then
    Draw(FChart, FChart.Drawer)
  else
    FChart.StyleChanged(Self);
  Deactivate;
  Handled;
end;

constructor TZoomDragTool.Create(AOwner: TComponent);
begin
  inherited;
  SetPropDefaults(Self, ['RestoreExtentOn']);
  FAdjustSelection := true;
  FBrush := TZoomDragBrush.Create;
  FBrush.Style := bsClear;
  FFrame := TChartPen.Create;
  FPrevDragDir := zreDifferentDrag;
end;

destructor TZoomDragTool.Destroy;
begin
  FreeAndNil(FBrush);
  FreeAndNil(FFrame);
  inherited;
end;

procedure TZoomDragTool.Draw(AChart: TChart; ADrawer: IChartDrawer);
begin
  if not IsActive or IsAnimating then exit;
  inherited;
  StartTransparency;
  PrepareDrawingModePen(ADrawer, Frame);
  ADrawer.SetBrush(Brush);
  ADrawer.Rectangle(CalculateDrawRect);
  ADrawer.SetXor(false);
  ADrawer.SetTransparency(0);
end;

function TZoomDragTool.GetProportional: Boolean;
begin
  Result := RatioLimit = zrlProportional;
end;

procedure TZoomDragTool.MouseDown(APoint: TPoint);
begin
  if not FChart.AllowZoom then exit;
  Activate;
  with APoint do
    FSelectionRect := Rect(X, Y, X, Y);
  Handled;
end;

procedure TZoomDragTool.MouseMove(APoint: TPoint);
begin
  if not IsActive then exit;
  SelectionRect := Rect(SelectionRect.Left, SelectionRect.Top, APoint.X, APoint.Y);
  Handled;
end;

procedure TZoomDragTool.MouseUp(APoint: TPoint);
const
  DRAG_DIR: array [-1..1, -1..1] of TRestoreExtentOn = (
    (zreDragTopLeft, zreClick, zreDragBottomLeft),
    (zreClick, zreClick, zreClick),
    (zreDragTopRight, zreClick, zreDragBottomRight));
var
  dragDir: TRestoreExtentOn;
begin
  Unused(APoint);
  if not IsActive then exit;

  if EffectiveDrawingMode = tdmXor then
    Draw(FChart, FChart.Drawer);

  with FSelectionRect do
    dragDir := DRAG_DIR[Sign(Right - Left), Sign(Bottom - Top)];
  if
    (dragDir in RestoreExtentOn) or
    (zreDifferentDrag in RestoreExtentOn) and
    (dragDir <> zreClick) and not (FPrevDragDir in [dragDir, zreDifferentDrag])
  then begin
    FPrevDragDir := zreDifferentDrag;
    if not Chart.IsZoomed and (EffectiveDrawingMode = tdmNormal) then
      // ZoomFull will not cause redraw, force it to erase the tool.
      Chart.StyleChanged(Self);
    DoZoom(FChart.GetFullExtent, true);
    Handled;
    exit;
  end;
  // If empty rectangle does not cause un-zooming, ignore it to prevent SIGFPE.
  if dragDir = zreClick then begin
    Deactivate;
    exit;
  end;
  FPrevDragDir := dragDir;

  DoZoom(CalculateNewExtent, false);
  Handled;
end;

procedure TZoomDragTool.SetBrush(AValue: TZoomDragBrush);
begin
  if FBrush = AValue then exit;
  FBrush.Assign(AValue);
end;

procedure TZoomDragTool.SetFrame(AValue: TChartPen);
begin
  FFrame.Assign(AValue);
end;

procedure TZoomDragTool.SetProportional(AValue: Boolean);
begin
  if AValue then
    RatioLimit := zrlProportional
  else
    RatioLimit := zrlNone;
end;

procedure TZoomDragTool.SetSelectionRect(AValue: TRect);
begin
  if (FSelectionRect = AValue) or not IsActive or IsAnimating then exit;
  case EffectiveDrawingMode of
    tdmXor: with FChart.Drawer do begin
      SetXor(true);
      Pen := Frame;
      Brush := Self.Brush;
      Rectangle(CalculateDrawRect);
      FSelectionRect := AValue;
      Rectangle(CalculateDrawRect);
      SetXor(false);
    end;
    tdmNormal: begin
      FSelectionRect := AValue;
      FChart.StyleChanged(Self);
    end;
  end;
end;

{ TReticuleTool }

procedure TReticuleTool.MouseMove(APoint: TPoint);
const
  DIST_FUNCS: array [TReticuleMode] of TPointDistFunc = (
    nil, @PointDistX, @PointDistY, @PointDist);
var
  cur, best: TNearestPointResults;
  p: TNearestPointParams;
  s, bestS: TCustomChartSeries;
begin
  if FChart.ReticuleMode = rmNone then exit;
  best.FDist := MaxInt;
  p.FDistFunc := DIST_FUNCS[FChart.ReticuleMode];
  p.FPoint := APoint;
  p.FRadius := Trunc(Sqrt(MaxInt));
  p.FOptimizeX := false;
  for s in CustomSeries(FChart) do
    if
      (not (s is TBasicPointSeries) or TBasicPointSeries(s).UseReticule) and
      s.GetNearestPoint(p, cur) and PtInRect(FChart.ClipRect, cur.FImg) and
      (cur.FDist < best.FDist)
    then begin
      bestS := s;
      best := cur;
    end;
  if (best.FDist = MaxInt) or (best.FImg = FChart.ReticulePos) then exit;
  FChart.ReticulePos := best.FImg;
  if Assigned(FChart.OnDrawReticule) then
    FChart.OnDrawReticule(FChart, bestS.Index, best.FIndex, best.FValue);
end;

{ TBasicZoomStepTool }

constructor TBasicZoomStepTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFixedPoint := true;
  FZoomFactor := 1.0;
  FZoomRatio := 1.0;
end;

procedure TBasicZoomStepTool.DoZoomStep(
  const APoint: TPoint; const AFactor: TDoublePoint);
var
  sz, center, ratio: TDoublePoint;
  ext: TDoubleRect;
begin
  ext := FChart.LogicalExtent;
  center := FChart.ImageToGraph(APoint);
  sz := ext.b - ext.a;
  if FixedPoint and (sz.X <> 0) and (sz.Y <> 0) then
    ratio := (center - ext.a) / sz
  else
    ratio := DoublePoint(0.5, 0.5);
  ext.a := center - sz * ratio / AFactor;
  ext.b := center + sz * (DoublePoint(1, 1) - ratio) / AFactor;
  DoZoom(ext, false);
  Handled;
end;

function TBasicZoomStepTool.ZoomFactorIsStored: boolean;
begin
  Result := FZoomFactor <> 1.0;
end;

function TBasicZoomStepTool.ZoomRatioIsStored: boolean;
begin
  Result := FZoomRatio <> 1.0;
end;

{ TZoomClickTool }

procedure TZoomClickTool.MouseDown(APoint: TPoint);
begin
  if (ZoomFactor <= 0) or (ZoomRatio <= 0) then exit;
  DoZoomStep(APoint, DoublePoint(ZoomFactor, ZoomFactor * ZoomRatio));
end;

{ TZoomMouseWheelTool }

procedure TZoomMouseWheelTool.MouseWheelDown(APoint: TPoint);
begin
  if (ZoomFactor <= 0) or (ZoomRatio <= 0) then exit;
  DoZoomStep(APoint, DoublePoint(ZoomFactor, ZoomFactor * ZoomRatio));
end;

procedure TZoomMouseWheelTool.MouseWheelUp(APoint: TPoint);
begin
  if (ZoomFactor <= 0) or (ZoomRatio <= 0) then exit;
  DoZoomStep(APoint, DoublePoint(1 / ZoomFactor, 1 / ZoomFactor / ZoomRatio));
end;

{ TBasicPanTool }

constructor TBasicPanTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActiveCursor := crSizeAll;
end;

procedure TBasicPanTool.PanBy(AOffset: TPoint);
var
  dd: TDoublePoint;
  ext, fullExt: TDoubleRect;
begin
  dd := FChart.ImageToGraph(AOffset) - FChart.ImageToGraph(Point(0, 0));
  ext := FChart.LogicalExtent;
  if LimitToExtent <> [] then begin
    fullExt := FChart.GetFullExtent;
    if (pdRight in LimitToExtent) and (ext.a.X + dd.X < fullExt.a.X) then
      dd.X := fullExt.a.X - ext.a.X;
    if (pdUp in LimitToExtent) and (ext.a.Y + dd.Y < fullExt.a.Y) then
      dd.Y := fullExt.a.Y - ext.a.Y;
    if (pdLeft in LimitToExtent) and (ext.b.X + dd.X > fullExt.b.X) then
      dd.X := fullExt.b.X - ext.b.X;
    if (pdDown in LimitToExtent) and (ext.b.Y + dd.Y > fullExt.b.Y) then
      dd.Y := fullExt.b.Y - ext.b.Y;
  end;
  ext.a += dd;
  ext.b += dd;
  FChart.LogicalExtent := ext;
end;

{ TPanDragTool }

procedure TPanDragTool.Cancel;
begin
  if not IsActive then exit;
  MouseMove(FOrigin);
  Deactivate;
end;

constructor TPanDragTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDirections := PAN_DIRECTIONS_ALL;
end;

procedure TPanDragTool.MouseDown(APoint: TPoint);
begin
  FOrigin := APoint;
  FPrev := APoint;
  if MinDragRadius = 0 then begin
    Activate;
    Handled;
  end;
end;

procedure TPanDragTool.MouseMove(APoint: TPoint);
var
  d: TPoint;
begin
  if not IsActive then begin
    if PointDist(FOrigin, APoint) < Sqr(MinDragRadius) then
      exit;
    Activate;
  end;
  d := FPrev - APoint;
  FPrev := APoint;

  if not (pdLeft in Directions) then d.X := Max(d.X, 0);
  if not (pdRight in Directions) then d.X := Min(d.X, 0);
  if not (pdUp in Directions) then d.Y := Max(d.Y, 0);
  if not (pdDown in Directions) then d.Y := Min(d.Y, 0);

  PanBy(d);
  Handled;
end;

procedure TPanDragTool.MouseUp(APoint: TPoint);
begin
  if not IsActive then exit;
  Unused(APoint);
  Deactivate;
  Handled;
end;

{ TPanClickTool }

constructor TPanClickTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMargins := TChartMargins.Create(nil);
  FTimer := TCustomTimer.Create(nil);
  FTimer.Enabled := false;
  FTimer.OnTimer := @OnTimer;
end;

procedure TPanClickTool.Deactivate;
begin
  FTimer.Enabled := false;
  inherited;
end;

destructor TPanClickTool.Destroy;
begin
  FreeAndNil(FMargins);
  FreeAndNil(FTimer);
  inherited Destroy;
end;

function TPanClickTool.GetOffset(APoint: TPoint): TPoint;
var
  r: TRect;
begin
  Result := Point(0, 0);
  r := FChart.ClipRect;
  if not PtInRect(r, APoint) then exit;
  with Size(r) do
    if
      (Margins.Left + Margins.Right >= cx) or
      (Margins.Top + Margins.Bottom >= cy)
    then
      exit;
  Result.X := Min(APoint.X - r.Left - Margins.Left, 0);
  if Result.X = 0 then
    Result.X := Max(Margins.Right - r.Right + APoint.X, 0);
  Result.Y := Min(APoint.Y - r.Top - Margins.Top, 0);
  if Result.Y = 0 then
    Result.Y := Max(Margins.Bottom - r.Bottom + APoint.Y, 0);
end;

procedure TPanClickTool.MouseDown(APoint: TPoint);
begin
  FOffset := GetOffset(APoint);
  if FOffset = Point(0, 0) then exit;
  PanBy(FOffset);
  if Interval > 0 then begin
    Activate;
    FTimer.Interval := Interval;
    FTimer.Enabled := true;
  end;
  Handled;
end;

procedure TPanClickTool.MouseMove(APoint: TPoint);
begin
  if not IsActive then exit;
  FOffset := GetOffset(APoint);
  FTimer.Enabled := FOffset <> Point(0, 0);
end;

procedure TPanClickTool.MouseUp(APoint: TPoint);
begin
  Unused(APoint);
  Deactivate;
  Handled;
end;

procedure TPanClickTool.OnTimer(ASender: TObject);
begin
  Unused(ASender);
  if FOffset <> Point(0, 0) then
    PanBy(FOffset);
end;

{ TPanMouseWheelTool }

constructor TPanMouseWheelTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetPropDefaults(Self, ['Step', 'WheelUpDirection']);
end;

procedure TPanMouseWheelTool.DoPan(AStep: Integer);
const
  DIR_TO_OFFSET: array [TPanDirection] of TPoint =
    // pdLeft, pdUp, pdRight, pdDown
    ((X: -1; Y: 0), (X: 0; Y: -1), (X: 1; Y: 0), (X: 0; Y: 1));
begin
  PanBy(DIR_TO_OFFSET[WheelUpDirection] * AStep);
end;

procedure TPanMouseWheelTool.MouseWheelDown(APoint: TPoint);
begin
  Unused(APoint);
  DoPan(-Step);
end;

procedure TPanMouseWheelTool.MouseWheelUp(APoint: TPoint);
begin
  Unused(APoint);
  DoPan(Step);
end;

{ TDataPointTool }

constructor TDataPointTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAffectedSeries.Init;
  SetPropDefaults(Self, ['GrabRadius']);
  FPointIndex := -1;
end;

procedure TDataPointTool.FindNearestPoint(APoint: TPoint);

  function InBoundaryBox(ASeries: TCustomChartSeries): Boolean;
  var
    r, gr: TDoubleRect;
  begin
    r := ASeries.GetGraphBounds;
    if not RectIntersectsRect(r, FChart.CurrentExtent) then exit(false);
    case DistanceMode of
      cdmOnlyX: begin
        gr.a := DoublePoint(FChart.XImageToGraph(APoint.X - GrabRadius), NegInfinity);
        gr.b := DoublePoint(FChart.XImageToGraph(APoint.X + GrabRadius), SafeInfinity);
      end;
      cdmOnlyY: begin
        gr.a := DoublePoint(NegInfinity, FChart.YImageToGraph(APoint.Y - GrabRadius));
        gr.b := DoublePoint(SafeInfinity, FChart.YImageToGraph(APoint.Y + GrabRadius));
      end;
      cdmXY: begin
        gr.a := FChart.ImageToGraph(APoint - Point(GrabRadius, GrabRadius));
        gr.b := FChart.ImageToGraph(APoint + Point(GrabRadius, GrabRadius));
      end;
    end;
    Result := RectIntersectsRect(r, gr);
  end;

const
  DIST_FUNCS: array [TChartDistanceMode] of TPointDistFunc = (
    @PointDist, @PointDistX, @PointDistY);
var
  s, bestS: TCustomChartSeries;
  p: TNearestPointParams;
  cur, best: TNearestPointResults;
begin
  p.FDistFunc := DIST_FUNCS[DistanceMode];
  p.FPoint := APoint;
  p.FRadius := GrabRadius;
  p.FOptimizeX := DistanceMode <> cdmOnlyY;
  best.FDist := MaxInt;
  for s in CustomSeries(FChart, FAffectedSeries.AsBooleans(FChart.SeriesCount)) do
    if
      InBoundaryBox(s) and s.GetNearestPoint(p, cur) and
      PtInRect(FChart.ClipRect, cur.FImg) and (cur.FDist < best.FDist)
    then begin
      bestS := s;
      best := cur;
    end;
  if best.FDist = MaxInt then exit;
  FSeries := bestS;
  FPointIndex := best.FIndex;
  FNearestGraphPoint := FChart.ImageToGraph(best.FImg);
end;

function TDataPointTool.GetAffectedSeries: String;
begin
  Result := FAffectedSeries.AsString;
end;

function TDataPointTool.GetIsSeriesAffected(AIndex: Integer): Boolean;
begin
  Result := FAffectedSeries.IsSet[AIndex];
end;

procedure TDataPointTool.SetAffectedSeries(AValue: String);
begin
  FAffectedSeries.AsString := AValue;
end;

procedure TDataPointTool.SetIsSeriesAffected(AIndex: Integer; AValue: Boolean);
begin
  FAffectedSeries.IsSet[AIndex] := AValue;
end;

{ TDataPointDragTool }

procedure TDataPointDragTool.Cancel;
begin
  if FSeries <> nil then
    FSeries.MovePoint(FPointIndex, Origin);
  if IsActive then
    Deactivate;
  Handled;
end;

constructor TDataPointDragTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActiveCursor := crSizeAll;
  EscapeCancels := true;
end;

procedure TDataPointDragTool.MouseDown(APoint: TPoint);
var
  p: TDoublePoint;
begin
  FindNearestPoint(APoint);
  if FSeries = nil then exit;
  FOrigin := NearestGraphPoint;
  if Assigned(OnDragStart) then begin
    p := FChart.ImageToGraph(APoint);
    OnDragStart(Self, p);
    if Toolset.FIsHandled then exit;
  end;
  Activate;
  Handled;
end;

procedure TDataPointDragTool.MouseMove(APoint: TPoint);
var
  p: TDoublePoint;
begin
  if not IsActive or (FSeries = nil) then exit;
  p := FChart.ImageToGraph(APoint);
  if Assigned(OnDrag) then begin
    OnDrag(Self, p);
    if Toolset.FIsHandled then exit;
  end;
  FSeries.MovePoint(FPointIndex, p);
  Handled;
end;

procedure TDataPointDragTool.MouseUp(APoint: TPoint);
begin
  Unused(APoint);
  FSeries := nil;
  Deactivate;
  Handled;
end;

{ TDataPointClickTool }

procedure TDataPointClickTool.MouseDown(APoint: TPoint);
begin
  FindNearestPoint(APoint);
  if FSeries = nil then exit;
  FMouseDownPoint := APoint;
  Activate;
  Handled;
end;

procedure TDataPointClickTool.MouseUp(APoint: TPoint);
begin
  if
    Assigned(OnPointClick) and (FSeries <> nil) and
    (PointDist(APoint, FMouseDownPoint) <= Sqr(GrabRadius))
  then
    OnPointClick(Self, FMouseDownPoint);
  FSeries := nil;
  Deactivate;
  Handled;
end;

{ TDataPointHintTool }

constructor TDataPointHintTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUseDefaultHintText := true;
end;

destructor TDataPointHintTool.Destroy;
begin
  FreeAndNil(FHintWindow);
  inherited;
end;

procedure TDataPointHintTool.HideHint;
begin
  if UseApplicationHint then begin
    FChart.ShowHint := false;
    Application.CancelHint;
  end
  else
    FreeAndNil(FHintWindow);
  RestoreCursor;
  FPrevSeries := nil;
end;

procedure TDataPointHintTool.KeyDown(APoint: TPoint);
begin
  MouseMove(APoint);
end;

procedure TDataPointHintTool.KeyUp(APoint: TPoint);
begin
  Unused(APoint);
  HideHint;
end;

procedure TDataPointHintTool.MouseDown(APoint: TPoint);
begin
  MouseMove(APoint);
end;

procedure TDataPointHintTool.MouseMove(APoint: TPoint);

  function GetHintText: String;
  begin
    if UseDefaultHintText then begin
      if Series is TChartSeries then
        Result := (Series as TChartSeries).FormattedMark(PointIndex)
      else
        Result := Format(
          '%s: %d', [(Series as TCustomChartSeries).Title, PointIndex]);
    end;
    if Assigned(OnHint) then
      OnHint(Self, APoint, Result);
  end;

var
  r: TRect;
  h: String;
begin
  FSeries := nil;
  FindNearestPoint(APoint);
  if Series = nil then begin
    HideHint;
    exit;
  end;
  if (FPrevSeries = Series) and (FPrevPointIndex = PointIndex) then
    exit;
  if FPrevSeries = nil then
    SetCursor;
  FPrevSeries := Series;
  FPrevPointIndex := PointIndex;
  h := GetHintText;
  APoint := FChart.ClientToScreen(APoint);
  if Assigned(OnHintPosition) then
    OnHintPosition(Self, APoint);

  if UseApplicationHint then begin
    FChart.Hint := h;
    FChart.ShowHint := FChart.Hint <> '';
    if not FChart.ShowHint then exit;
    Application.HintPause := 0;
    Application.ActivateHint(APoint);
  end
  else begin
    if FHintWindow = nil then
      FHintWindow := THintWindow.Create(nil);
    if h = '' then exit;
    r := FHintWindow.CalcHintRect(FChart.Width, h, nil);
    OffsetRect(r, APoint.X, APoint.Y);
    FHintWindow.ActivateHint(r, h);
  end;
end;

procedure TDataPointHintTool.MouseUp(APoint: TPoint);
begin
  Unused(APoint);
  HideHint;
end;

procedure TDataPointHintTool.SetUseApplicationHint(AValue: Boolean);
begin
  if FUseApplicationHint = AValue then exit;
  FUseApplicationHint := AValue;
end;

{ TDataPointDrawTool }

constructor TDataPointDrawTool.Create(AOwner: TComponent);
begin
  inherited;
  GrabRadius := 20;
  FPen := TChartPen.Create;
end;

destructor TDataPointDrawTool.Destroy;
begin
  FreeAndNil(FPen);
  inherited;
end;

procedure TDataPointDrawTool.DoDraw;
begin
  if Assigned(OnDraw) then
    OnDraw(Self);
end;

procedure TDataPointDrawTool.DoHide;
begin
  case EffectiveDrawingMode of
    tdmXor: begin
      FChart.Drawer.SetXor(true);
      DoDraw;
      FChart.Drawer.SetXor(false);
    end;
    tdmNormal:
      FChart.StyleChanged(Self);
  end;
end;

procedure TDataPointDrawTool.Draw(AChart: TChart; ADrawer: IChartDrawer);
begin
  inherited;
  PrepareDrawingModePen(ADrawer, FPen);
  DoDraw;
  ADrawer.SetXor(false);
end;

procedure TDataPointDrawTool.Hide;
begin
  DoHide;
  Deactivate;
end;

procedure TDataPointDrawTool.SetPen(AValue: TChartPen);
begin
  FPen.Assign(AValue);
end;

{ TDataPointCrosshairTool }

constructor TDataPointCrosshairTool.Create(AOwner: TComponent);
begin
  inherited;
  SetPropDefaults(Self, ['Shape', 'Size']);
end;

procedure TDataPointCrosshairTool.DoDraw;
var
  p: TPoint;
begin
  FChart.Drawer.Pen := CrosshairPen;
  p := FChart.GraphToImage(Position);
  if Shape in [ccsVertical, ccsCross] then
    if Size < 0 then
      FChart.DrawLineVert(FChart.Drawer, p.X)
    else
      FChart.Drawer.Line(p - Point(0, Size), p + Point(0, Size));
  if Shape in [ccsHorizontal, ccsCross] then
    if Size < 0 then
      FChart.DrawLineHoriz(FChart.Drawer, p.Y)
    else
      FChart.Drawer.Line(p - Point(Size, 0), p + Point(Size, 0));
  inherited;
end;

procedure TDataPointCrosshairTool.DoHide;
begin
  if FSeries = nil then exit;
  FSeries := nil;
  inherited;
end;

procedure TDataPointCrosshairTool.Draw(AChart: TChart; ADrawer: IChartDrawer);
begin
  if FSeries = nil then exit;
  inherited;
end;

procedure TDataPointCrosshairTool.KeyDown(APoint: TPoint);
begin
  MouseMove(APoint);
end;

procedure TDataPointCrosshairTool.MouseDown(APoint: TPoint);
begin
  MouseMove(APoint);
end;

procedure TDataPointCrosshairTool.MouseMove(APoint: TPoint);
begin
  DoHide;
  FindNearestPoint(APoint);
  if FSeries = nil then exit;
  FPosition := FNearestGraphPoint;
  if EffectiveDrawingMode = tdmXor then begin
    FChart.Drawer.SetXor(true);
    DoDraw;
    FChart.Drawer.SetXor(false);
  end;
end;

initialization

  ToolsClassRegistry := TStringList.Create;
  OnInitBuiltinTools := @InitBuiltinTools;
  RegisterChartToolClass(TZoomDragTool, 'Zoom by drag');
  RegisterChartToolClass(TZoomClickTool, 'Zoom by click');
  RegisterChartToolClass(TZoomMouseWheelTool, 'Zoom by mouse wheel');
  RegisterChartToolClass(TPanDragTool, 'Panning by drag');
  RegisterChartToolClass(TPanClickTool, 'Panning by click');
  RegisterChartToolClass(TPanMouseWheelTool, 'Panning by mouse wheel');
  RegisterChartToolClass(TReticuleTool, 'Reticule');
  RegisterChartToolClass(TDataPointClickTool, 'Data point click');
  RegisterChartToolClass(TDataPointDragTool, 'Data point drag');
  RegisterChartToolClass(TDataPointHintTool, 'Data point hint');
  RegisterChartToolClass(TDataPointCrosshairTool, 'Data point crosshair');
  RegisterChartToolClass(TUserDefinedTool, 'User-defined');

finalization

  FreeAndNil(ToolsClassRegistry);

end.

