{
 /***************************************************************************
                               TAGraph.pas
                               -----------
                    Component Library Standard Graph


 ***************************************************************************/

 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Authors: Luís Rodrigues, Philippe Martinole, Alexander Klenin

}
unit TAGraph;

{$H+}

interface

uses
  Graphics, Classes, Controls, LCLType, SysUtils,
  TAChartAxis, TAChartAxisUtils, TAChartUtils, TADrawUtils, TAGUIConnector,
  TALegend, TATextElements, TATypes;

type
  TChart = class;

  TReticuleMode = (rmNone, rmVertical, rmHorizontal, rmCross);

  TDrawReticuleEvent = procedure(
    ASender: TChart; ASeriesIndex, AIndex: Integer;
    const AData: TDoublePoint) of object;

  TChartDrawLegendEvent = procedure(
    ASender: TChart; ADrawer: IChartDrawer; ALegendItems: TChartLegendItems;
    ALegendItemSize: TPoint; const ALegendRect: TRect;
    AColCount, ARowCount: Integer) of object;

  { TBasicChartSeries }

  TBasicChartSeries = class(TIndexedComponent)
  protected
    FActive: Boolean;
    FChart: TChart;
    FDepth: TChartDistance;
    FShadow: TChartShadow;
    FTransparency: TChartTransparency;
    FZPosition: TChartDistance;

    procedure AfterAdd; virtual; abstract;
    procedure AfterDraw; virtual;
    procedure BeforeDraw; virtual;
    procedure GetLegendItemsBasic(AItems: TChartLegendItems); virtual; abstract;
    function GetShowInLegend: Boolean; virtual; abstract;
    procedure SetActive(AValue: Boolean); virtual; abstract;
    procedure SetDepth(AValue: TChartDistance); virtual; abstract;
    procedure SetShadow(AValue: TChartShadow); virtual; abstract;
    procedure SetShowInLegend(AValue: Boolean); virtual; abstract;
    procedure SetTransparency(AValue: TChartTransparency); virtual; abstract;
    procedure SetZPosition(AValue: TChartDistance); virtual; abstract;
    procedure UpdateMargins(ADrawer: IChartDrawer; var AMargins: TRect); virtual;
    procedure VisitSources(
      AVisitor: TChartOnSourceVisitor; AAxis: TChartAxis; var AData); virtual;

  public
    function AxisToGraphX(AX: Double): Double; virtual;
    function AxisToGraphY(AY: Double): Double; virtual;
    function GraphToAxisX(AX: Double): Double; virtual;
    function GraphToAxisY(AY: Double): Double; virtual;

  public
    procedure Assign(Source: TPersistent); override;
    destructor Destroy; override;

  public
    procedure Draw(ADrawer: IChartDrawer); virtual; abstract;
    function GetGraphBounds: TDoubleRect; virtual; abstract;
    function IsEmpty: Boolean; virtual; abstract;
    procedure MovePoint(var AIndex: Integer; const ANewPos: TPoint); overload; inline;
    procedure MovePoint(var AIndex: Integer; const ANewPos: TDoublePoint); overload; virtual;

    property Active: Boolean read FActive write SetActive default true;
    property Depth: TChartDistance read FDepth write SetDepth default 0;
    property ParentChart: TChart read FChart;
    property Shadow: TChartShadow read FShadow write SetShadow;
    property Transparency: TChartTransparency
      read FTransparency write SetTransparency default 0;
    property ZPosition: TChartDistance read FZPosition write SetZPosition default 0;
  end;

  TSeriesClass = class of TBasicChartSeries;

  { TBasicСhartTool }

  TBasicChartTool = class(TIndexedComponent)
  strict protected
    FChart: TChart;

    procedure Activate; virtual;
    procedure Deactivate; virtual;
  public
    property Chart: TChart read FChart;
  end;

  TChartToolEventId = (
    evidKeyDown, evidKeyUp, evidMouseDown, evidMouseMove, evidMouseUp,
    evidMouseWheelDown, evidMouseWheelUp);

  { TBasicChartToolset }

  TBasicChartToolset = class(TComponent)
  public
    function Dispatch(
      AChart: TChart; AEventId: TChartToolEventId;
      AShift: TShiftState; APoint: TPoint): Boolean; virtual; abstract; overload;
      procedure Draw(AChart: TChart; ADrawer: IChartDrawer); virtual; abstract;
  end;

  TBasicChartSeriesEnumerator = class(TFPListEnumerator)
  public
    function GetCurrent: TBasicChartSeries;
    property Current: TBasicChartSeries read GetCurrent;
  end;

  { TChartSeriesList }

  TChartSeriesList = class(TPersistent)
  private
    FList: TIndexedComponentList;
    function GetItem(AIndex: Integer): TBasicChartSeries;
  public
    constructor Create;
    destructor Destroy; override;
  public
    procedure Clear;
    function Count: Integer;
    function GetEnumerator: TBasicChartSeriesEnumerator;
  public
    property Items[AIndex: Integer]: TBasicChartSeries read GetItem; default;
    property List: TIndexedComponentList read FList;
  end;

  TChartAfterDrawEvent = procedure (
    ASender: TChart; ACanvas: TCanvas; const ARect: TRect) of object;
  TChartBeforeDrawEvent = procedure (
    ASender: TChart; ACanvas: TCanvas; const ARect: TRect;
    var ADoDefaultDrawing: Boolean) of object;
  TChartEvent = procedure (ASender: TChart) of object;
  TChartPaintEvent = procedure (
    ASender: TChart; const ARect: TRect;
    var ADoDefaultDrawing: Boolean) of object;

  TChartRenderingParams = record
    FClipRect: TRect;
    FIsZoomed: Boolean;
    FLogicalExtent, FPrevLogicalExtent: TDoubleRect;
    FScale, FOffset: TDoublePoint;
  end;

  { TChart }

  TChart = class(TCustomChart, ICoordTransformer)
  public
  type
    TDrawEvent = procedure (ASender: TChart; ADrawer: IChartDrawer) of object;
  strict private // Property fields
    FAllowZoom: Boolean;
    FAntialiasingMode: TChartAntialiasingMode;
    FAxisList: TChartAxisList;
    FAxisVisible: Boolean;
    FBackColor: TColor;
    FConnectorData: TChartGUIConnectorData;
    FDepth: TChartDistance;
    FDefaultGUIConnector: TChartGUIConnector;
    FExpandPercentage: Integer;
    FExtent: TChartExtent;
    FExtentSizeLimit: TChartExtent;
    FFoot: TChartTitle;
    FFrame: TChartPen;
    FGUIConnector: TChartGUIConnector;
    FGUIConnectorListener: TListener;
    FLegend: TChartLegend;
    FLogicalExtent: TDoubleRect;
    FMargins: TChartMargins;
    FMarginsExternal: TChartMargins;
    FOnAfterDraw: TDrawEvent;
    FOnAfterDrawBackground: TChartAfterDrawEvent;
    FOnAfterDrawBackWall: TChartAfterDrawEvent;
    FOnBeforeDrawBackground: TChartBeforeDrawEvent;
    FOnBeforeDrawBackWall: TChartBeforeDrawEvent;
    FOnChartPaint: TChartPaintEvent;
    FOnDrawReticule: TDrawReticuleEvent;
    FOnDrawLegend: TChartDrawLegendEvent;
    FProportional: Boolean;
    FSeries: TChartSeriesList;
    FTitle: TChartTitle;
    FToolset: TBasicChartToolset;

    function ClipRectWithoutFrame(AZPosition: TChartDistance): TRect;
    function EffectiveGUIConnector: TChartGUIConnector; inline;
  private
    FActiveToolIndex: Integer;
    FAutoFocus: Boolean;
    FBroadcaster: TBroadcaster;
    FBuiltinToolset: TBasicChartToolset;
    FClipRect: TRect;
    FCurrentExtent: TDoubleRect;
    FDisableRedrawingCounter: Integer;
    FExtentBroadcaster: TBroadcaster;
    FIsZoomed: Boolean;
    FOffset: TDoublePoint;   // Coordinates transformation
    FOnAfterPaint: TChartEvent;
    FOnExtentChanged: TChartEvent;
    FOnExtentChanging: TChartEvent;
    FPrevLogicalExtent: TDoubleRect;
    FReticuleMode: TReticuleMode;
    FReticulePos: TPoint;
    FScale: TDoublePoint;    // Coordinates transformation

    procedure CalculateTransformationCoeffs(const AMargin: TRect);
    procedure DrawReticule(ADrawer: IChartDrawer);
    procedure FindComponentClass(
      AReader: TReader; const AClassName: String; var AClass: TComponentClass);
    function GetChartHeight: Integer;
    function GetChartWidth: Integer;
    function GetMargins(ADrawer: IChartDrawer): TRect;
    function GetRenderingParams: TChartRenderingParams;
    function GetSeriesCount: Integer;
    function GetToolset: TBasicChartToolset;
    procedure HideReticule;

    procedure SetAntialiasingMode(AValue: TChartAntialiasingMode);
    procedure SetAxisList(AValue: TChartAxisList);
    procedure SetAxisVisible(Value: Boolean);
    procedure SetBackColor(AValue: TColor);
    procedure SetDepth(AValue: TChartDistance);
    procedure SetExpandPercentage(AValue: Integer);
    procedure SetExtent(AValue: TChartExtent);
    procedure SetExtentSizeLimit(AValue: TChartExtent);
    procedure SetFoot(Value: TChartTitle);
    procedure SetFrame(Value: TChartPen);
    procedure SetGUIConnector(AValue: TChartGUIConnector);
    procedure SetLegend(Value: TChartLegend);
    procedure SetLogicalExtent(const AValue: TDoubleRect);
    procedure SetMargins(AValue: TChartMargins);
    procedure SetMarginsExternal(AValue: TChartMargins);
    procedure SetOnAfterDraw(AValue: TDrawEvent);
    procedure SetOnAfterDrawBackground(AValue: TChartAfterDrawEvent);
    procedure SetOnAfterDrawBackWall(AValue: TChartAfterDrawEvent);
    procedure SetOnBeforeDrawBackground(AValue: TChartBeforeDrawEvent);
    procedure SetOnBeforeDrawBackWall(AValue: TChartBeforeDrawEvent);
    procedure SetOnChartPaint(AValue: TChartPaintEvent);
    procedure SetOnDrawLegend(AValue: TChartDrawLegendEvent);
    procedure SetOnDrawReticule(AValue: TDrawReticuleEvent);
    procedure SetProportional(AValue: Boolean);
    procedure SetRenderingParams(AValue: TChartRenderingParams);
    procedure SetReticuleMode(AValue: TReticuleMode);
    procedure SetReticulePos(const AValue: TPoint);
    procedure SetTitle(Value: TChartTitle);
    procedure SetToolset(AValue: TBasicChartToolset);
    procedure VisitSources(
      AVisitor: TChartOnSourceVisitor; AAxis: TChartAxis; var AData);
  protected
    function DoMouseWheel(
      AShift: TShiftState; AWheelDelta: Integer;
      AMousePos: TPoint): Boolean; override;
    procedure MouseDown(
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(
      AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer); override;
  protected
    function GetAxisByAlign(AAlign: TChartAxisAlignment): TChartAxis;
    procedure SetAxisByAlign(AAlign: TChartAxisAlignment; AValue: TChartAxis); inline;
  protected
    procedure Clear(ADrawer: IChartDrawer; const ARect: TRect);
    procedure DisplaySeries(ADrawer: IChartDrawer);
    procedure DrawBackWall(ADrawer: IChartDrawer);
    procedure KeyDownAfterInterface(var AKey: Word; AShift: TShiftState); override;
    procedure KeyUpAfterInterface(var AKey: Word; AShift: TShiftState); override;
    {$IFDEF LCLGtk2}
    procedure DoOnResize; override;
    {$ENDIF}
    procedure Notification(
      AComponent: TComponent; AOperation: TOperation); override;
    procedure PrepareAxis(ADrawer: IChartDrawer);
    function PrepareLegend(
      ADrawer: IChartDrawer; var AClipRect: TRect): TChartLegendDrawingData;
    procedure SetName(const AValue: TComponentName); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure EraseBackground(DC: HDC); override;
    procedure GetChildren(AProc: TGetChildProc; ARoot: TComponent); override;
    procedure Paint; override;
    procedure SetChildOrder(Child: TComponent; Order: Integer); override;

  public // Helpers for series drawing
    procedure DrawLineHoriz(ADrawer: IChartDrawer; AY: Integer);
    procedure DrawLineVert(ADrawer: IChartDrawer; AX: Integer);
    procedure DrawOnCanvas(Rect: TRect; ACanvas: TCanvas); deprecated;
    function IsPointInViewPort(const AP: TDoublePoint): Boolean;

  public
    procedure AddSeries(ASeries: TBasicChartSeries);
    procedure ClearSeries;
    function Clone: TChart;
    procedure CopyToClipboardBitmap;
    procedure DeleteSeries(ASeries: TBasicChartSeries);
    procedure DisableRedrawing;
    procedure Draw(ADrawer: IChartDrawer; const ARect: TRect);
    procedure DrawLegendOn(ACanvas: TCanvas; var ARect: TRect);
    procedure EnableRedrawing;
    function GetFullExtent: TDoubleRect;
    function GetLegendItems(AIncludeHidden: Boolean = false): TChartLegendItems;
    procedure PaintOnAuxCanvas(ACanvas: TCanvas; ARect: TRect);
    procedure PaintOnCanvas(ACanvas: TCanvas; ARect: TRect);
    procedure Prepare;
    procedure RemoveSeries(ASeries: TBasicChartSeries); inline;
    procedure SaveToBitmapFile(const AFileName: String); inline;
    procedure SaveToFile(AClass: TRasterImageClass; AFileName: String);
    function SaveToImage(AClass: TRasterImageClass): TRasterImage;
    procedure StyleChanged(Sender: TObject); override;
    procedure ZoomFull(AImmediateRecalc: Boolean = false); override;
    property Drawer: IChartDrawer read FConnectorData.FDrawer;

  public // Coordinate conversion
    function GraphToImage(const AGraphPoint: TDoublePoint): TPoint;
    function ImageToGraph(const APoint: TPoint): TDoublePoint;
    function XGraphToImage(AX: Double): Integer; inline;
    function XImageToGraph(AX: Integer): Double; inline;
    function YGraphToImage(AY: Double): Integer; inline;
    function YImageToGraph(AY: Integer): Double; inline;

  public
    property ActiveToolIndex: Integer read FActiveToolIndex;
    property Broadcaster: TBroadcaster read FBroadcaster;
    property ChartHeight: Integer read GetChartHeight;
    property ChartWidth: Integer read GetChartWidth;
    property ClipRect: TRect read FClipRect;
    property CurrentExtent: TDoubleRect read FCurrentExtent;
    property ExtentBroadcaster: TBroadcaster read FExtentBroadcaster;
    property IsZoomed: Boolean read FIsZoomed;
    property LogicalExtent: TDoubleRect read FLogicalExtent write SetLogicalExtent;
    property OnChartPaint: TChartPaintEvent
      read FOnChartPaint write SetOnChartPaint; experimental;
    property PrevLogicalExtent: TDoubleRect read FPrevLogicalExtent;
    property RenderingParams: TChartRenderingParams
      read GetRenderingParams write SetRenderingParams;
    property ReticulePos: TPoint read FReticulePos write SetReticulePos;
    property SeriesCount: Integer read GetSeriesCount;
    property XGraphMax: Double read FCurrentExtent.b.X;
    property XGraphMin: Double read FCurrentExtent.a.X;
    property YGraphMax: Double read FCurrentExtent.b.Y;
    property YGraphMin: Double read FCurrentExtent.a.Y;

  published
    property AutoFocus: Boolean read FAutoFocus write FAutoFocus default false;
    property AllowZoom: Boolean read FAllowZoom write FAllowZoom default true;
    property AntialiasingMode: TChartAntialiasingMode
      read FAntialiasingMode write SetAntialiasingMode default amDontCare;
    property AxisList: TChartAxisList read FAxisList write SetAxisList;
    property AxisVisible: Boolean read FAxisVisible write SetAxisVisible default true;
    property BackColor: TColor read FBackColor write SetBackColor default clBtnFace;
    property BottomAxis: TChartAxis index calBottom read GetAxisByAlign write SetAxisByAlign stored false;
    property Depth: TChartDistance read FDepth write SetDepth default 0;
    property ExpandPercentage: Integer
      read FExpandPercentage write SetExpandPercentage default 0;
    property Extent: TChartExtent read FExtent write SetExtent;
    property ExtentSizeLimit: TChartExtent read FExtentSizeLimit write SetExtentSizeLimit;
    property Foot: TChartTitle read FFoot write SetFoot;
    property Frame: TChartPen read FFrame write SetFrame;
    property GUIConnector: TChartGUIConnector
      read FGUIConnector write SetGUIConnector;
    property LeftAxis: TChartAxis index calLeft read GetAxisByAlign write SetAxisByAlign stored false;
    property Legend: TChartLegend read FLegend write SetLegend;
    property Margins: TChartMargins read FMargins write SetMargins;
    property MarginsExternal: TChartMargins
      read FMarginsExternal write SetMarginsExternal;
    property Proportional: Boolean
      read FProportional write SetProportional default false;
    property ReticuleMode: TReticuleMode
      read FReticuleMode write SetReticuleMode default rmNone;
    property Series: TChartSeriesList read FSeries;
    property Title: TChartTitle read FTitle write SetTitle;
    property Toolset: TBasicChartToolset read FToolset write SetToolset;

  published
    property OnAfterDraw: TDrawEvent read FOnAfterDraw write SetOnAfterDraw;
    property OnAfterDrawBackground: TChartAfterDrawEvent
      read FOnAfterDrawBackground write SetOnAfterDrawBackground;
    property OnAfterDrawBackWall: TChartAfterDrawEvent
      read FOnAfterDrawBackWall write SetOnAfterDrawBackWall;
    property OnAfterPaint: TChartEvent read FOnAfterPaint write FOnAfterPaint;
    property OnBeforeDrawBackground: TChartBeforeDrawEvent
      read FOnBeforeDrawBackground write SetOnBeforeDrawBackground;
    property OnBeforeDrawBackWall: TChartBeforeDrawEvent
      read FOnBeforeDrawBackWall write SetOnBeforeDrawBackWall;
    property OnDrawLegend: TChartDrawLegendEvent
      read FOnDrawLegend write SetOnDrawLegend;
    property OnDrawReticule: TDrawReticuleEvent
      read FOnDrawReticule write SetOnDrawReticule;
    property OnExtentChanged: TChartEvent
      read FOnExtentChanged write FOnExtentChanged;
    property OnExtentChanging: TChartEvent
      read FOnExtentChanging write FOnExtentChanging;

  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Color default clBtnFace;
    property DoubleBuffered;
    property DragCursor;
    property DragMode;
    property Enabled;
    property ParentColor;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;

  published
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
  end;

procedure Register;
procedure RegisterSeriesClass(ASeriesClass: TSeriesClass; const ACaption: string);

var
  SeriesClassRegistry: TStringList;
  OnInitBuiltinTools: function(AChart: TChart): TBasicChartToolset;

implementation

uses
  Clipbrd, Dialogs, GraphMath, LCLProc, LResources, Math, TADrawerCanvas,
  TAGeometry, TAMath, Types;

function CompareZPosition(AItem1, AItem2: Pointer): Integer;
begin
  Result :=
    TBasicChartSeries(AItem1).ZPosition - TBasicChartSeries(AItem2).ZPosition;
end;

procedure Register;
var
  i: Integer;
  sc: TSeriesClass;
begin
  RegisterComponents(CHART_COMPONENT_IDE_PAGE, [TChart]);
  for i := 0 to SeriesClassRegistry.Count - 1 do begin
    sc := TSeriesClass(SeriesClassRegistry.Objects[i]);
    RegisterClass(sc);
    RegisterNoIcon([sc]);
  end;
end;

procedure RegisterSeriesClass(
  ASeriesClass: TSeriesClass; const ACaption: String);
begin
  if SeriesClassRegistry.IndexOfObject(TObject(ASeriesClass)) < 0 then
    SeriesClassRegistry.AddObject(ACaption, TObject(ASeriesClass));
end;

procedure WriteComponentToStream(AStream: TStream; AComponent: TComponent);
var
  writer: TWriter;
  destroyDriver: Boolean = false;
begin
  writer := CreateLRSWriter(AStream, destroyDriver);
  try
    writer.Root := AComponent.Owner;
    writer.WriteComponent(AComponent);
  finally
    if destroyDriver then
      writer.Driver.Free;
    writer.Free;
  end;
end;

{ TBasicChartSeriesEnumerator }

function TBasicChartSeriesEnumerator.GetCurrent: TBasicChartSeries;
begin
  Result := TBasicChartSeries(inherited GetCurrent);
end;

{ TChart }

procedure TChart.AddSeries(ASeries: TBasicChartSeries);
begin
  if ASeries.FChart = Self then exit;
  if ASeries.FChart <> nil then
    ASeries.FChart.DeleteSeries(ASeries);
  HideReticule;
  Series.FList.Add(ASeries);
  ASeries.FChart := Self;
  ASeries.AfterAdd;
  StyleChanged(ASeries);
end;

procedure TChart.CalculateTransformationCoeffs(const AMargin: TRect);
var
  rX, rY: TAxisCoeffHelper;
begin
  rX.Init(
    BottomAxis, FClipRect.Left, FClipRect.Right, AMargin.Left, -AMargin.Right,
    @FCurrentExtent.a.X, @FCurrentExtent.b.X);
  rY.Init(
    LeftAxis, FClipRect.Bottom, FClipRect.Top, -AMargin.Bottom, AMargin.Top,
    @FCurrentExtent.a.Y, @FCurrentExtent.b.Y);
  FScale.X := rX.CalcScale(1);
  FScale.Y := rY.CalcScale(-1);
  if Proportional then begin
    if Abs(FScale.X) > Abs(FScale.Y) then
      FScale.X := Abs(FScale.Y) * Sign(FScale.X)
    else
      FScale.Y := Abs(FScale.X) * Sign(FScale.Y);
  end;
  FOffset.X := rX.CalcOffset(FScale.X);
  FOffset.Y := rY.CalcOffset(FScale.Y);
  rX.UpdateMinMax(@XImageToGraph);
  rY.UpdateMinMax(@YImageToGraph);
end;

procedure TChart.Clear(ADrawer: IChartDrawer; const ARect: TRect);
var
  defaultDrawing: Boolean = true;
  ic: IChartTCanvasDrawer;
begin
  ADrawer.PrepareSimplePen(Color);
  ADrawer.SetBrushParams(bsSolid, Color);
  if Supports(ADrawer, IChartTCanvasDrawer, ic) and Assigned(OnBeforeDrawBackground) then
    OnBeforeDrawBackground(Self, ic.Canvas, ARect, defaultDrawing);
  if defaultDrawing then
    ADrawer.Rectangle(ARect);
  if Supports(ADrawer, IChartTCanvasDrawer, ic) and Assigned(OnAfterDrawBackground) then
    OnAfterDrawBackground(Self, ic.Canvas, ARect);
end;

procedure TChart.ClearSeries;
begin
  FSeries.Clear;
  StyleChanged(Self);
end;

function TChart.ClipRectWithoutFrame(AZPosition: TChartDistance): TRect;
begin
  Result := FClipRect;
  if (AZPosition > 0) or not Frame.EffVisible then exit;
  Result.Left += (Frame.Width + 1) div 2;
  Result.Top += (Frame.Width + 1) div 2;
  Result.Bottom -= Frame.Width div 2;
  Result.Right -= Frame.Width div 2;
end;

function TChart.Clone: TChart;
var
  ms: TMemoryStream;
  cloned: TComponent = nil;
begin
  ms := TMemoryStream.Create;
  try
    WriteComponentToStream(ms, Self);
    ms.Seek(0, soBeginning);
    ReadComponentFromBinaryStream(
      ms, cloned, @FindComponentClass, Owner, Parent, Owner);
    Result := cloned as TChart;
  finally
    ms.Free;
  end;
end;

procedure TChart.CopyToClipboardBitmap;
begin
  with SaveToImage(TBitmap) do
    try
      SaveToClipboardFormat(RegisterClipboardFormat(MimeType));
    finally
      Free;
    end;
end;

constructor TChart.Create(AOwner: TComponent);
const
  DEFAULT_CHART_WIDTH = 300;
  DEFAULT_CHART_HEIGHT = 200;
  DEFAULT_CHART_TITLE = 'TAChart';
  FONT_VERTICAL = 900;
begin
  inherited Create(AOwner);

  FBroadcaster := TBroadcaster.Create;
  FExtentBroadcaster := TBroadcaster.Create;
  FAllowZoom := true;
  FAntialiasingMode := amDontCare;
  FAxisVisible := true;
  FConnectorData.FCanvas := Canvas;
  FDefaultGUIConnector := TChartGUIConnectorCanvas.Create(Self);
  FDefaultGUIConnector.CreateDrawer(FConnectorData);
  FGUIConnectorListener := TListener.Create(@FGUIConnector, @StyleChanged);

  FScale := DoublePoint(1, 1);

  Width := DEFAULT_CHART_WIDTH;
  Height := DEFAULT_CHART_HEIGHT;

  FReticulePos := Point(-1, -1);
  FReticuleMode := rmNone;

  FSeries := TChartSeriesList.Create;

  Color := clBtnFace;
  FBackColor := clBtnFace;

  FIsZoomed := false;

  FLegend := TChartLegend.Create(Self);
  FTitle := TChartTitle.Create(Self);
  FTitle.Alignment := taCenter;
  FTitle.Text.Add(DEFAULT_CHART_TITLE);
  FFoot := TChartTitle.Create(Self);

  FAxisList := TChartAxisList.Create(Self);
  FAxisList.OnVisitSources := @VisitSources;
  with TChartAxis.Create(FAxisList) do begin
    Alignment := calLeft;
    Title.LabelFont.Orientation := FONT_VERTICAL;
  end;
  with TChartAxis.Create(FAxisList) do
    Alignment := calBottom;

  FFrame :=  TChartPen.Create;
  FFrame.OnChange := @StyleChanged;

  FExtent := TChartExtent.Create(Self);
  FExtentSizeLimit := TChartExtent.Create(Self);
  FMargins := TChartMargins.Create(Self);
  FMarginsExternal := TChartMargins.Create(Self);

  FBuiltinToolset := OnInitBuiltinTools(Self);
  FActiveToolIndex := -1;

  FLogicalExtent := EmptyExtent;
  FPrevLogicalExtent := EmptyExtent;
end;

procedure TChart.DeleteSeries(ASeries: TBasicChartSeries);
var
  i: Integer;
begin
  i := FSeries.FList.IndexOf(ASeries);
  if i < 0 then exit;
  FSeries.FList.Delete(i);
  ASeries.FChart := nil;
  StyleChanged(Self);
end;

destructor TChart.Destroy;
begin
  FreeAndNil(FSeries);

  FreeAndNil(FLegend);
  FreeAndNil(FTitle);
  FreeAndNil(FFoot);
  FreeAndNil(FAxisList);
  FreeAndNil(FFrame);
  FreeAndNil(FGUIConnectorListener);
  FreeAndNil(FExtent);
  FreeAndNil(FExtentSizeLimit);
  FreeAndNil(FMargins);
  FreeAndNil(FMarginsExternal);
  FreeAndNil(FBuiltinToolset);
  FreeAndNil(FBroadcaster);
  FreeAndNil(FExtentBroadcaster);
  FreeAndNil(FDefaultGUIConnector);

  DrawData.DeleteByChart(Self);
  inherited;
end;

procedure TChart.DisableRedrawing;
begin
  FDisableRedrawingCounter += 1;
end;

procedure TChart.DisplaySeries(ADrawer: IChartDrawer);

  procedure OffsetDrawArea(ADX, ADY: Integer); inline;
  begin
    FOffset.X += ADX;
    FOffset.Y += ADY;
    OffsetRect(FClipRect, ADX, ADY);
  end;

  procedure OffsetWithDepth(AZPos, ADepth: Integer);
  begin
    OffsetDrawArea(-AZPos, AZPos);
    FClipRect.Right += ADepth;
    FClipRect.Top -= ADepth;
  end;

  procedure DrawOrDeactivate(
    ASeries: TBasicChartSeries; ATransparency: TChartTransparency);
  begin
    try
      ADrawer.SetTransparency(ATransparency);
      ASeries.Draw(ADrawer);
    except
      ASeries.Active := false;
      raise;
    end;
  end;

var
  axisIndex: Integer;
  seriesInZOrder: TChartSeriesList;
  s: TBasicChartSeries;
begin
  axisIndex := 0;
  if SeriesCount > 0 then begin
    seriesInZOrder := TChartSeriesList.Create;
    try
      seriesInZOrder.List.Assign(FSeries.List);
      seriesInZOrder.List.Sort(@CompareZPosition);

      for s in seriesInZOrder do begin
        if not s.Active then continue;
        // Interleave axises with series according to ZPosition.
        if AxisVisible then
          AxisList.Draw(s.ZPosition, axisIndex);
        OffsetWithDepth(Min(s.ZPosition, Depth), Min(s.Depth, Depth));
        ADrawer.ClippingStart(ClipRectWithoutFrame(s.ZPosition));

        try
          with s.Shadow do
            if Visible then begin
              OffsetDrawArea(OffsetX, OffsetY);
              ADrawer.SetMonochromeColor(Color);
              try
                DrawOrDeactivate(s, Transparency);
              finally
                ADrawer.SetMonochromeColor(clTAColor);
                OffsetDrawArea(-OffsetX, -OffsetY);
              end;
            end;
          DrawOrDeactivate(s, s.Transparency);
        finally
          OffsetWithDepth(-Min(s.ZPosition, Depth), -Min(s.Depth, Depth));
          ADrawer.ClippingStop;
        end;
      end;
    finally
      seriesInZOrder.List.Clear; // Avoid freeing series.
      seriesInZOrder.Free;
      ADrawer.SetTransparency(0);
    end;
  end;
  if AxisVisible then
    AxisList.Draw(MaxInt, axisIndex);
end;

function TChart.DoMouseWheel(
  AShift: TShiftState; AWheelDelta: Integer; AMousePos: TPoint): Boolean;
const
  EV: array [Boolean] of TChartToolEventId = (
    evidMouseWheelDown, evidMouseWheelUp);
begin
  Result :=
    GetToolset.Dispatch(Self, EV[AWheelDelta > 0], AShift, AMousePos) or
    inherited DoMouseWheel(AShift, AWheelDelta, AMousePos);
end;

{$IFDEF LCLGtk2}
procedure TChart.DoOnResize;
begin
  inherited;
  // FIXME: GTK does not invalidate the control on resizing, do it manually
  Invalidate;
end;
{$ENDIF}

procedure TChart.Draw(ADrawer: IChartDrawer; const ARect: TRect);
var
  ldd: TChartLegendDrawingData;
  s: TBasicChartSeries;
begin
  Prepare;

  FClipRect := ARect;
  with MarginsExternal do begin
    FClipRect.Left += Left;
    FClipRect.Top += Top;
    FClipRect.Right -= Right;
    FClipRect.Bottom -= Bottom;
  end;

  with ClipRect do begin;
    FTitle.Measure(ADrawer, 1, Left, Right, Top);
    FFoot.Measure(ADrawer, -1, Left, Right, Bottom);
  end;

  ldd.FItems := nil;
  if Legend.Visible then
    ldd := PrepareLegend(ADrawer, FClipRect);

  try
    PrepareAxis(ADrawer);
    if (FPrevLogicalExtent <> FLogicalExtent) and Assigned(OnExtentChanging) then
      OnExtentChanging(Self);

    ADrawer.DrawingBegin(ARect);
    ADrawer.SetAntialiasingMode(AntialiasingMode);
    Clear(ADrawer, ARect);
    FTitle.Draw(ADrawer);
    FFoot.Draw(ADrawer);
    DrawBackWall(ADrawer);
    DisplaySeries(ADrawer);
    if Legend.Visible then begin
      if Assigned(FOnDrawLegend) then
        FOnDrawlegend(Self, ldd.FDrawer, ldd.FItems, ldd.FItemSize, ldd.FBounds,
          ldd.FColCount, ldd.FRowCount)
      else
        Legend.Draw(ldd);
    end;
  finally
    ldd.FItems.Free;
  end;
  DrawReticule(ADrawer);
  GetToolset.Draw(Self, ADrawer);

  for s in Series do
    s.AfterDraw;

  if Assigned(OnAfterDraw) then
    OnAfterDraw(Self, ADrawer);
  ADrawer.DrawingEnd;

  if FPrevLogicalExtent <> FLogicalExtent then begin
    FExtentBroadcaster.Broadcast(Self);
    if Assigned(OnExtentChanged) then
      OnExtentChanged(Self);
    FPrevLogicalExtent := FLogicalExtent;
  end;
end;

procedure TChart.DrawBackWall(ADrawer: IChartDrawer);
var
  defaultDrawing: Boolean = true;
  ic: IChartTCanvasDrawer;
begin
  if Supports(ADrawer, IChartTCanvasDrawer, ic) and Assigned(OnBeforeDrawBackWall) then
    OnBeforeDrawBackWall(Self, ic.Canvas, FClipRect, defaultDrawing);
  if defaultDrawing then
    with ADrawer do begin
      if FFrame.Visible then
        Pen := FFrame
      else
        SetPenParams(psClear, clTAColor);
      SetBrushParams(bsSolid, BackColor);
      with FClipRect do
        Rectangle(Left, Top, Right + 1, Bottom + 1);
    end;
  if Supports(ADrawer, IChartTCanvasDrawer, ic) and Assigned(OnAfterDrawBackWall) then
    OnAfterDrawBackWall(Self, ic.Canvas, FClipRect);

  // Z axis
  if (Depth > 0) and FFrame.Visible then begin
    ADrawer.Pen := FFrame;
    with FClipRect do
      ADrawer.Line(Left, Bottom, Left - Depth, Bottom + Depth);
  end;
end;

procedure TChart.DrawLegendOn(ACanvas: TCanvas; var ARect: TRect);
var
  ldd: TChartLegendDrawingData;
begin
  ldd := PrepareLegend(TCanvasDrawer.Create(ACanvas), ARect);
  try
    Legend.Draw(ldd);
  finally
    ldd.FItems.Free;
  end;
end;

procedure TChart.DrawLineHoriz(ADrawer: IChartDrawer; AY: Integer);
begin
  if (FClipRect.Top < AY) and (AY < FClipRect.Bottom) then
    ADrawer.Line(FClipRect.Left, AY, FClipRect.Right, AY);
end;

procedure TChart.DrawLineVert(ADrawer: IChartDrawer; AX: Integer);
begin
  if (FClipRect.Left < AX) and (AX < FClipRect.Right) then
    ADrawer.Line(AX, FClipRect.Top, AX, FClipRect.Bottom);
end;

procedure TChart.DrawOnCanvas(Rect: TRect; ACanvas: TCanvas);
begin
  PaintOnCanvas(ACanvas, Rect);
end;

procedure TChart.DrawReticule(ADrawer: IChartDrawer);
begin
  ADrawer.SetXor(true);
  ADrawer.PrepareSimplePen(clTAColor);
  if ReticuleMode in [rmVertical, rmCross] then
    DrawLineVert(ADrawer, FReticulePos.X);
  if ReticuleMode in [rmHorizontal, rmCross] then
    DrawLineHoriz(ADrawer, FReticulePos.Y);
  ADrawer.SetXor(false);
end;

function TChart.EffectiveGUIConnector: TChartGUIConnector;
begin
  Result := TChartGUIConnector(
    IfThen(FGUIConnector = nil, FDefaultGUIConnector, FGUIConnector));
end;

procedure TChart.EnableRedrawing;
begin
  FDisableRedrawingCounter -= 1;
end;

procedure TChart.EraseBackground(DC: HDC);
begin
  // do not erase, since we will paint over it anyway
  Unused(DC);
end;

procedure TChart.FindComponentClass(
  AReader: TReader; const AClassName: String; var AClass: TComponentClass);
var
  i: Integer;
begin
  Unused(AReader);
  if AClassName = ClassName then begin
    AClass := TChart;
    exit;
  end;
  for i := 0 to SeriesClassRegistry.Count - 1 do begin
    AClass := TSeriesClass(SeriesClassRegistry.Objects[i]);
    if AClass.ClassNameIs(AClassName) then exit;
  end;
  AClass := nil;
end;

function TChart.GetAxisByAlign(AAlign: TChartAxisAlignment): TChartAxis;
begin
  Result := FAxisList.GetAxisByAlign(AAlign);
end;

function TChart.GetChartHeight: Integer;
begin
  Result := FClipRect.Bottom - FClipRect.Top;
end;

function TChart.GetChartWidth: Integer;
begin
  Result := FClipRect.Right - FClipRect.Left;
end;

procedure TChart.GetChildren(AProc: TGetChildProc; ARoot: TComponent);
var
  s: TBasicChartSeries;
begin
  // FIXME: This is a workaround for issue #16035
  if FSeries = nil then exit;
  for s in Series do
    if s.Owner = ARoot then
      AProc(s);
end;

function TChart.GetFullExtent: TDoubleRect;

  procedure SetBounds(
    var ALo, AHi: Double; AMin, AMax: Double; AUseMin, AUseMax: Boolean);
  const
    DEFAULT_WIDTH = 2.0;
  begin
    if AUseMin then ALo := AMin;
    if AUseMax then AHi := AMax;
    case CASE_OF_TWO[IsInfinite(ALo), IsInfinite(AHi)] of
      cotNone: begin // Both high and low boundary defined
        if ALo = AHi then begin
          ALo -= DEFAULT_WIDTH / 2;
          AHi += DEFAULT_WIDTH / 2;
        end
        else begin
          EnsureOrder(ALo, AHi);
          // Expand view slightly to avoid data points on the chart edge.
          ExpandRange(ALo, AHi, ExpandPercentage * PERCENT);
        end;
      end;
      cotFirst: ALo := AHi - DEFAULT_WIDTH;
      cotSecond: AHi := ALo + DEFAULT_WIDTH;
      cotBoth: begin // No boundaries defined, take some arbitrary values
        ALo := -DEFAULT_WIDTH / 2;
        AHi := DEFAULT_WIDTH / 2;
      end;
    end;
  end;

  procedure JoinBounds(const ABounds: TDoubleRect);
  begin
    with Result do begin
      a.X := Min(a.X, ABounds.a.X);
      b.X := Max(b.X, ABounds.b.X);
      a.Y := Min(a.Y, ABounds.a.Y);
      b.Y := Max(b.Y, ABounds.b.Y);
    end;
  end;

var
  axisBounds: TDoubleRect;
  s: TBasicChartSeries;
  a: TChartAxis;
begin
  Extent.CheckBoundsOrder;

  for a in AxisList do
    if a.Transformations <> nil then
      a.Transformations.ClearBounds;

  Result := EmptyExtent;
  for s in Series do begin
    if not s.Active then continue;
    try
      JoinBounds(s.GetGraphBounds);
    except
      s.Active := false;
      raise;
    end;
  end;
  for a in AxisList do begin
    axisBounds := EmptyExtent;
    if a.Range.UseMin then
      TDoublePointBoolArr(axisBounds.a)[a.IsVertical] :=
        a.GetTransform.AxisToGraph(a.Range.Min);
    if a.Range.UseMax then
      TDoublePointBoolArr(axisBounds.b)[a.IsVertical] :=
        a.GetTransform.AxisToGraph(a.Range.Max);
    JoinBounds(axisBounds);
  end;
  with Extent do begin
    SetBounds(Result.a.X, Result.b.X, XMin, XMax, UseXMin, UseXMax);
    SetBounds(Result.a.Y, Result.b.Y, YMin, YMax, UseYMin, UseYMax);
  end;
end;

function TChart.GetLegendItems(AIncludeHidden: Boolean): TChartLegendItems;
var
  s: TBasicChartSeries;
begin
  Result := TChartLegendItems.Create;
  try
    for s in Series do
      if AIncludeHidden or (s.Active and s.GetShowInLegend) then
        try
          s.GetLegendItemsBasic(Result);
        except
          s.SetShowInLegend(AIncludeHidden);
          raise;
        end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TChart.GetMargins(ADrawer: IChartDrawer): TRect;
var
  i: Integer;
  a: TRectArray absolute Result;
  s: TBasicChartSeries;
begin
  Result := ZeroRect;
  for s in Series do
    if s.Active then
      s.UpdateMargins(ADrawer, Result);
  for i := Low(a) to High(a) do
    a[i] := ADrawer.Scale(a[i] + TRectArray(Margins.Data)[i]);
end;

function TChart.GetRenderingParams: TChartRenderingParams;
begin
  Result.FScale := FScale;
  Result.FOffset := FOffset;
  Result.FClipRect := FClipRect;
  Result.FLogicalExtent := FLogicalExtent;
  Result.FPrevLogicalExtent := FPrevLogicalExtent;
  Result.FIsZoomed := FIsZoomed;
end;

function TChart.GetSeriesCount: Integer;
begin
  Result := FSeries.FList.Count;
end;

function TChart.GetToolset: TBasicChartToolset;
begin
  Result := FToolset;
  if Result = nil then
    Result := FBuiltinToolset;
end;

function TChart.GraphToImage(const AGraphPoint: TDoublePoint): TPoint;
begin
  Result := Point(XGraphToImage(AGraphPoint.X), YGraphToImage(AGraphPoint.Y));
end;

procedure TChart.HideReticule;
begin
  // Hide reticule - - it will be drawn again in the next MouseMove.
  FReticulePos := Point( - 1, - 1);
end;

function TChart.ImageToGraph(const APoint: TPoint): TDoublePoint;
begin
  Result.X := XImageToGraph(APoint.X);
  Result.Y := YImageToGraph(APoint.Y);
end;

function TChart.IsPointInViewPort(const AP: TDoublePoint): Boolean;
begin
  Result :=
    not IsNan(AP) and
    InRange(AP.X, XGraphMin, XGraphMax) and InRange(AP.Y, YGraphMin, YGraphMax);
end;

procedure TChart.KeyDownAfterInterface(var AKey: Word; AShift: TShiftState);
var
  p: TPoint;
begin
  p := ScreenToClient(Mouse.CursorPos);
  if GetToolset.Dispatch(Self, evidKeyDown, AShift, p) then exit;
  inherited;
end;

procedure TChart.KeyUpAfterInterface(var AKey: Word; AShift: TShiftState);
var
  p: TPoint;
begin
  p := ScreenToClient(Mouse.CursorPos);
  // To find a tool, toolset must see the shift state with the key still down.
  case AKey of
    VK_CONTROL: AShift += [ssCtrl];
    VK_MENU: AShift += [ssAlt];
    VK_SHIFT: AShift += [ssShift];
  end;
  if GetToolset.Dispatch(Self, evidKeyUp, AShift, p) then exit;
  inherited;
end;

procedure TChart.MouseDown(
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if
    PtInRect(FClipRect, Point(X, Y)) and
    GetToolset.Dispatch(Self, evidMouseDown, Shift, Point(X, Y))
  then
    exit;
  inherited;
end;

procedure TChart.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if AutoFocus then
    SetFocus;
  if GetToolset.Dispatch(Self, evidMouseMove, Shift, Point(X, Y)) then exit;
  inherited;
end;

procedure TChart.MouseUp(
  AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
const
  MOUSE_BUTTON_TO_SHIFT: array [TMouseButton] of TShiftStateEnum = (
    ssLeft, ssRight, ssMiddle, ssExtra1, ssExtra2);
begin
  // To find a tool, toolset must see the shift state with the button still down.
  Include(AShift, MOUSE_BUTTON_TO_SHIFT[AButton]);
  if GetToolset.Dispatch(Self, evidMouseUp, AShift, Point(AX, AY)) then exit;
  inherited;
end;

procedure TChart.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  if (AOperation = opRemove) and (AComponent = Toolset) then
    FToolset := nil
  else if (AOperation = opRemove) and (AComponent = GUIConnector) then
    GUIConnector := nil;
  inherited Notification(AComponent, AOperation);
end;

procedure TChart.Paint;
var
  defaultDrawing: Boolean = true;
begin
  FConnectorData.FBounds := GetClientRect;
  {$WARNINGS OFF}
  if Assigned(OnChartPaint) then
    OnChartPaint(Self, FConnectorData.FBounds, defaultDrawing);
  {$WARNINGS ON}
  if defaultDrawing then
    with EffectiveGUIConnector do begin
      SetBounds(FConnectorData);
      Draw(Drawer, FConnectorData.FDrawerBounds);
      EffectiveGUIConnector.Display(FConnectorData);
  end;
  if Assigned(OnAfterPaint) then
    OnAfterPaint(Self);
end;

procedure TChart.PaintOnAuxCanvas(ACanvas: TCanvas; ARect: TRect);
var
  rp: TChartRenderingParams;
begin
  rp := RenderingParams;
  ExtentBroadcaster.Locked := true;
  try
    FIsZoomed := false;
    PaintOnCanvas(ACanvas, ARect);
  finally
    RenderingParams := rp;
    ExtentBroadcaster.Locked := false;
  end;
end;

procedure TChart.PaintOnCanvas(ACanvas: TCanvas; ARect: TRect);
begin
  Draw(TCanvasDrawer.Create(ACanvas), ARect);
end;

procedure TChart.PrepareAxis(ADrawer: IChartDrawer);
var
  axisMargin: TChartAxisMargins;
  aa: TChartAxisAlignment;
  cr: TRect;
  tries: Integer;
  prevExt: TDoubleRect;
  axis: TChartAxis;
begin
  if not AxisVisible then begin
    FClipRect.Left += Depth;
    FClipRect.Bottom -= Depth;
    CalculateTransformationCoeffs(GetMargins(ADrawer));
    exit;
  end;

  AxisList.PrepareGroups;
  for axis in AxisList do
    axis.PrepareHelper(ADrawer, Self, @FClipRect, Depth);

  // There is a cyclic dependency: extent -> visible marks -> margins.
  // We recalculate them iteratively hoping that the process converges.
  CalculateTransformationCoeffs(ZeroRect);
  cr := FClipRect;
  for tries := 1 to 10 do begin
    axisMargin := AxisList.Measure(CurrentExtent, Depth);
    axisMargin[calLeft] := Max(axisMargin[calLeft], Depth);
    axisMargin[calBottom] := Max(axisMargin[calBottom], Depth);
    FClipRect := cr;
    for aa := Low(aa) to High(aa) do
      SideByAlignment(FClipRect, aa, -axisMargin[aa]);
    prevExt := FCurrentExtent;
    FCurrentExtent := FLogicalExtent;
    CalculateTransformationCoeffs(GetMargins(ADrawer));
    if prevExt = FCurrentExtent then break;
    prevExt := FCurrentExtent;
  end;

  AxisList.Prepare(FClipRect);
end;

procedure TChart.Prepare;
var
  a: TChartAxis;
  s: TBasicChartSeries;
begin
  for a in AxisList do
    if a.Transformations <> nil then
      a.Transformations.SetChart(Self);
  for s in Series do
    s.BeforeDraw;

  if not FIsZoomed then
    FLogicalExtent := GetFullExtent;
  FCurrentExtent := FLogicalExtent;
end;

function TChart.PrepareLegend(
  ADrawer: IChartDrawer; var AClipRect: TRect): TChartLegendDrawingData;
begin
  Result.FDrawer := ADrawer;
  Result.FItems := GetLegendItems;
  try
    Legend.SortItemsByOrder(Result.FItems);
    Legend.AddGroups(Result.FItems);
    Legend.Prepare(Result, AClipRect);
  except
    FreeAndNil(Result.FItems);
    raise;
  end;
end;

procedure TChart.RemoveSeries(ASeries: TBasicChartSeries);
begin
  DeleteSeries(ASeries);
end;

procedure TChart.SaveToBitmapFile(const AFileName: String);
begin
  SaveToFile(TBitmap, AFileName);
end;

procedure TChart.SaveToFile(AClass: TRasterImageClass; AFileName: String);
begin
  with SaveToImage(AClass) do
    try
      SaveToFile(AFileName);
    finally
      Free;
    end;
end;

function TChart.SaveToImage(AClass: TRasterImageClass): TRasterImage;
begin
  Result := AClass.Create;
  try
    Result.Width := Width;
    Result.Height := Height;
    PaintOnCanvas(Result.Canvas, Rect(0, 0, Width, Height));
  except
    Result.Free;
    raise;
  end;
end;

procedure TChart.SetAntialiasingMode(AValue: TChartAntialiasingMode);
begin
  if FAntialiasingMode = AValue then exit;
  FAntialiasingMode := AValue;
  StyleChanged(Self);
end;

procedure TChart.SetAxisByAlign(AAlign: TChartAxisAlignment; AValue: TChartAxis);
begin
  FAxisList.SetAxisByAlign(AAlign, AValue);
  StyleChanged(AValue);
end;

procedure TChart.SetAxisList(AValue: TChartAxisList);
begin
  FAxisList.Assign(AValue);
  StyleChanged(Self);
end;

procedure TChart.SetAxisVisible(Value: Boolean);
begin
  FAxisVisible := Value;
  StyleChanged(Self);
end;

procedure TChart.SetBackColor(AValue: TColor);
begin
  FBackColor:= AValue;
  StyleChanged(Self);
end;

procedure TChart.SetChildOrder(Child: TComponent; Order: Integer);
var
  i: Integer;
begin
  i := Series.FList.IndexOf(Child);
  if i >= 0 then
    Series.FList.Move(i, Order);
end;

procedure TChart.SetDepth(AValue: TChartDistance);
begin
  if FDepth = AValue then exit;
  FDepth := AValue;
  StyleChanged(Self);
end;

procedure TChart.SetExpandPercentage(AValue: Integer);
begin
  if FExpandPercentage = AValue then exit;
  FExpandPercentage := AValue;
  StyleChanged(Self);
end;

procedure TChart.SetExtent(AValue: TChartExtent);
begin
  FExtent.Assign(AValue);
  StyleChanged(Self);
end;

procedure TChart.SetExtentSizeLimit(AValue: TChartExtent);
begin
  if FExtentSizeLimit = AValue then exit;
  FExtentSizeLimit.Assign(AValue);
  StyleChanged(Self);
end;

procedure TChart.SetFoot(Value: TChartTitle);
begin
  FFoot.Assign(Value);
  StyleChanged(Self);
end;

procedure TChart.SetFrame(Value: TChartPen);
begin
  FFrame.Assign(Value);
  StyleChanged(Self);
end;

procedure TChart.SetGUIConnector(AValue: TChartGUIConnector);
begin
  if FGUIConnector = AValue then exit;
  if FGUIConnector <> nil then
    RemoveFreeNotification(FGUIConnector);
  if FGUIConnectorListener.IsListening then
    FGUIConnector.Broadcaster.Unsubscribe(FGUIConnectorListener);
  FGUIConnector := AValue;
  if FGUIConnector <> nil then begin
    FGUIConnector.Broadcaster.Subscribe(FGUIConnectorListener);
    FreeNotification(FGUIConnector);
  end;
  EffectiveGUIConnector.CreateDrawer(FConnectorData);
  StyleChanged(Self);
end;

procedure TChart.SetLegend(Value: TChartLegend);
begin
  FLegend.Assign(Value);
  StyleChanged(Self);
end;

procedure TChart.SetLogicalExtent(const AValue: TDoubleRect);
var
  w, h: Double;
begin
  if FLogicalExtent = AValue then exit;
  w := Abs(AValue.a.X - AValue.b.X);
  h := Abs(AValue.a.Y - AValue.b.Y);
  with ExtentSizeLimit do
    if
      UseXMin and (w < XMin) or UseXMax and (w > XMax) or
      UseYMin and (h < YMin) or UseYMax and (h > YMax)
    then
      exit;
  HideReticule;
  FLogicalExtent := AValue;
  FIsZoomed := true;
  StyleChanged(Self);
end;

procedure TChart.SetMargins(AValue: TChartMargins);
begin
  FMargins.Assign(AValue);
  StyleChanged(Self);
end;

procedure TChart.SetMarginsExternal(AValue: TChartMargins);
begin
  if FMarginsExternal = AValue then exit;
  FMarginsExternal.Assign(AValue);
  StyleChanged(Self);
end;

procedure TChart.SetName(const AValue: TComponentName);
var
  oldName: String;
begin
  if Name = AValue then exit;
  oldName := Name;
  inherited SetName(AValue);
  if csDesigning in ComponentState then
    Series.List.ChangeNamePrefix(oldName, AValue);
end;

procedure TChart.SetOnAfterDraw(AValue: TDrawEvent);
begin
  if TMethod(FOnAfterDraw) = TMethod(AValue) then exit;
  FOnAfterDraw := AValue;
  StyleChanged(Self);
end;

procedure TChart.SetOnAfterDrawBackground(AValue: TChartAfterDrawEvent);
begin
  if TMethod(FOnAfterDrawBackground) = TMEthod(AValue) then exit;
  FOnAfterDrawBackground := AValue;
  StyleChanged(Self);
end;

procedure TChart.SetOnAfterDrawBackWall(AValue: TChartAfterDrawEvent);
begin
  if TMethod(FOnAfterDrawBackWall) = TMethod(AValue) then exit;
  FOnAfterDrawBackWall := AValue;
  StyleChanged(Self);
end;

procedure TChart.SetOnBeforeDrawBackground(AValue: TChartBeforeDrawEvent);
begin
  if TMethod(FOnBeforeDrawBackground) = TMethod(AValue) then exit;
  FOnBeforeDrawBackground := AValue;
  StyleChanged(Self);
end;

procedure TChart.SetOnBeforeDrawBackWall(AValue: TChartBeforeDrawEvent);
begin
  if TMethod(FOnBeforeDrawBackWall) = TMethod(AValue) then exit;
  FOnBeforeDrawBackWall := AValue;
  StyleChanged(Self);
end;

procedure TChart.SetOnChartPaint(AValue: TChartPaintEvent);
begin
  if TMethod(FOnChartPaint) = TMethod(AValue) then exit;
  FOnChartPaint := AValue;
  StyleChanged(Self);
end;

procedure TChart.SetOnDrawLegend(AValue: TChartDrawLegendEvent);
begin
  if TMethod(FOnDrawLegend) = TMethod(AValue) then exit;
  FOnDrawLegend := AValue;
  StyleChanged(self);
end;

procedure TChart.SetOnDrawReticule(AValue: TDrawReticuleEvent);
begin
  if TMethod(FOnDrawReticule) = TMethod(AValue) then exit;
  FOnDrawReticule := AValue;
  StyleChanged(Self);
end;

procedure TChart.SetProportional(AValue: Boolean);
begin
  if FProportional = AValue then exit;
  FProportional := AValue;
  StyleChanged(Self);
end;

procedure TChart.SetRenderingParams(AValue: TChartRenderingParams);
begin
  FScale := AValue.FScale;
  FOffset := AValue.FOffset;
  FClipRect := AValue.FClipRect;
  FLogicalExtent := AValue.FLogicalExtent;
  FPrevLogicalExtent := AValue.FPrevLogicalExtent;
  FIsZoomed := AValue.FIsZoomed;
end;

procedure TChart.SetReticuleMode(AValue: TReticuleMode);
begin
  if FReticuleMode = AValue then exit;
  FReticuleMode := AValue;
  StyleChanged(Self);
end;

procedure TChart.SetReticulePos(const AValue: TPoint);
begin
  if FReticulePos = AValue then exit;
  DrawReticule(Drawer);
  FReticulePos := AValue;
  DrawReticule(Drawer);
end;

procedure TChart.SetTitle(Value: TChartTitle);
begin
  FTitle.Assign(Value);
  StyleChanged(Self);
end;

procedure TChart.SetToolset(AValue: TBasicChartToolset);
begin
  if FToolset = AValue then exit;
  if FToolset <> nil then
    RemoveFreeNotification(FToolset);
  FToolset := AValue;
  FActiveToolIndex := -1;
  if FToolset <> nil then
    FreeNotification(FToolset);
end;

procedure TChart.StyleChanged(Sender: TObject);
begin
  if FDisableRedrawingCounter > 0 then exit;
  if Sender is TChartExtent then
    ZoomFull;
  Invalidate;
  Broadcaster.Broadcast(Sender);
end;

procedure TChart.VisitSources(
  AVisitor: TChartOnSourceVisitor; AAxis: TChartAxis; var AData);
var
  s: TBasicChartSeries;
begin
  for s in Series do
    if s.Active then
      s.VisitSources(AVisitor, AAxis, AData);
end;

function TChart.XGraphToImage(AX: Double): Integer;
begin
  Result := RoundChecked(FScale.X * AX + FOffset.X);
end;

function TChart.XImageToGraph(AX: Integer): Double;
begin
  Result := (AX - FOffset.X) / FScale.X;
end;

function TChart.YGraphToImage(AY: Double): Integer;
begin
  Result := RoundChecked(FScale.Y * AY + FOffset.Y);
end;

function TChart.YImageToGraph(AY: Integer): Double;
begin
  Result := (AY - FOffset.Y) / FScale.Y;
end;

procedure TChart.ZoomFull(AImmediateRecalc: Boolean);
begin
  if AImmediateRecalc then
    FLogicalExtent := GetFullExtent;
  if not FIsZoomed then exit;
  HideReticule;
  FIsZoomed := false;
  Invalidate;
end;

{ TBasicChartSeries }

procedure TBasicChartSeries.AfterDraw;
begin
  // empty
end;

procedure TBasicChartSeries.Assign(Source: TPersistent);
begin
  if Source is TBasicChartSeries then
    with TBasicChartSeries(Source) do begin
      Self.FActive := FActive;
      Self.FDepth := FDepth;
      Self.FZPosition := FZPosition;
    end;
end;

function TBasicChartSeries.AxisToGraphX(AX: Double): Double;
begin
  Result := AX;
end;

function TBasicChartSeries.AxisToGraphY(AY: Double): Double;
begin
  Result := AY;
end;

procedure TBasicChartSeries.BeforeDraw;
begin
  // empty
end;

destructor TBasicChartSeries.Destroy;
begin
  if FChart <> nil then
    FChart.DeleteSeries(Self);
  inherited;
end;

function TBasicChartSeries.GraphToAxisX(AX: Double): Double;
begin
  Result := AX;
end;

function TBasicChartSeries.GraphToAxisY(AY: Double): Double;
begin
  Result := AY;
end;

procedure TBasicChartSeries.MovePoint(
  var AIndex: Integer; const ANewPos: TDoublePoint);
begin
  Unused(AIndex, ANewPos)
end;

procedure TBasicChartSeries.MovePoint(
  var AIndex: Integer; const ANewPos: TPoint);
begin
  MovePoint(AIndex, FChart.ImageToGraph(ANewPos));
end;

procedure TBasicChartSeries.UpdateMargins(
  ADrawer: IChartDrawer; var AMargins: TRect);
begin
  Unused(ADrawer, AMargins);
end;

procedure TBasicChartSeries.VisitSources(
  AVisitor: TChartOnSourceVisitor; AAxis: TChartAxis; var AData);
begin
  Unused(AVisitor, AAxis);
  Unused(AData);
end;

{ TChartSeriesList }

procedure TChartSeriesList.Clear;
var
  i: Integer;
begin
  if FList.Count > 0 then
    Items[0].FChart.StyleChanged(Items[0].FChart);
  for i := 0 to FList.Count - 1 do begin
    Items[i].FChart := nil;
    Items[i].Free;
  end;
  FList.Clear;
end;

function TChartSeriesList.Count: Integer;
begin
  Result := FList.Count;
end;

constructor TChartSeriesList.Create;
begin
  FList := TIndexedComponentList.Create;
end;

destructor TChartSeriesList.Destroy;
begin
  Clear;
  FreeAndNil(FList);
  inherited;
end;

function TChartSeriesList.GetEnumerator: TBasicChartSeriesEnumerator;
begin
  Result := TBasicChartSeriesEnumerator.Create(FList);
end;

function TChartSeriesList.GetItem(AIndex: Integer): TBasicChartSeries;
begin
  Result := TBasicChartSeries(FList.Items[AIndex]);
end;

{ TBasicChartTool }

procedure TBasicChartTool.Activate;
begin
  FChart.FActiveToolIndex := Index;
  FChart.MouseCapture := true;
end;

procedure TBasicChartTool.Deactivate;
begin
  FChart.MouseCapture := false;
  FChart.FActiveToolIndex := -1;
end;

procedure SkipObsoleteChartProperties;
const
  MIRRORX_NOTE = 'Obsolete, use BottomAxis.Invert instead';
  AXIS_COLOR_NOTE = 'Obsolete, use Axis.TickColor instead';
  ANGLE_NOTE = 'Obsolete, use Font.Orientation instead';
  NOTE = 'Obsolete, use Extent instead';
  NAMES: array [1..4] of String = (
    'XGraph', 'YGraph', 'AutoUpdateX', 'AutoUpdateY');
var
  i: Integer;
begin
  RegisterPropertyToSkip(TChart, 'MirrorX', MIRRORX_NOTE, '');
  RegisterPropertyToSkip(TChart, 'AxisColor', AXIS_COLOR_NOTE, '');
  RegisterPropertyToSkip(TChartAxisTitle, 'Angle', ANGLE_NOTE, '');
  for i := 1 to High(NAMES) do begin
    RegisterPropertyToSkip(TChart, NAMES[i] + 'Min', NOTE, '');
    RegisterPropertyToSkip(TChart, NAMES[i] + 'Max', NOTE, '');
  end;
end;

initialization
  {$I tagraph.lrs}
  SkipObsoleteChartProperties;
  SeriesClassRegistry := TStringList.Create;
  ShowMessageProc := @ShowMessage;

finalization
  FreeAndNil(SeriesClassRegistry);

end.
