{
 *****************************************************************************
 *                               gtk3int.pas                                 *
 *                               -------------                               *
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit gtk3int;
{$i gtk3defines.inc}
{$mode objfpc}
{$H+}

interface

uses
  {$IFDEF UNIX}
  BaseUnix, Unix,
  {$ENDIF}
  SysUtils, Classes, types,
  InterfaceBase, Translations,
  Controls, Forms, FPImage, Graphics, GraphUtil, GraphType, LCLProc,
  LCLStrConsts,
  LCLType, LMessages,
  LazGtk3, LazGdk3, LazGlib2, LazGObject2, LazCairo1, LazPango1, LazPangoCairo1, LazGio2,
  LazGdkPixbuf2, gtk3widgets, gtk3objects, gtk3procs, IntfGraphics;

type

  { lazarus GtkInterface definition for additional timer data, not in gtk }
  PGtkITimerInfo = ^TGtkITimerinfo;
  TGtkITimerInfo = record
    TimerHandle: guint;        // the gtk handle for this timer
    TimerFunc  : TWSTimerProc; // owner function to handle timer
  end;

  { TGtk3WidgetSet }

  TGtk3WidgetSet = class(TWidgetSet)
  private
    FMainPoll: PGPollFD;
    FGtk3Application: PGtkApplication;
    FDefaultAppFontName: String;
    {$IFDEF UNIX}
    FChildSignalHandlers: PChildSignalEventHandler;
    {$ELSE}
    {$IFDEF VerboseGtkToDos}{$warning no declaration of FChildSignalHandlers for this OS}{$ENDIF}
    {$ENDIF}

    procedure Gtk3Create;
    procedure Gtk3Destroy;
    {$IFNDEF UNIX}
    procedure DoWakeMainThread(Sender: TObject);
    {$ENDIF}
    procedure SetDefaultAppFontName;
    procedure InitSysColorBrushes;
    procedure FreeSysColorBrushes;
  protected
    {shared stuff}
    FAppIcon: PGdkPixbuf;
    FStockNullBrush: HBRUSH;
    FStockBlackBrush: HBRUSH;
    FStockLtGrayBrush: HBRUSH;
    FStockGrayBrush: HBRUSH;
    FStockDkGrayBrush: HBRUSH;
    FStockWhiteBrush: HBRUSH;

    FStockNullPen: HPEN;
    FStockBlackPen: HPEN;
    FStockWhitePen: HPEN;
    FStockSystemFont: HFONT;
    FStockDefaultDC: HDC;
    FSysColorBrushes: array[0..MAX_SYS_COLORS] of HBRUSH;
    FGlobalCursor: HCursor;
  public
    function CreateDCForWidget(AWidget: PGtkWidget; AWindow: PGdkWindow; cr: Pcairo_t): HDC;
    procedure AddWindow(AWindow: PGtkWindow);
    {$IFDEF UNIX}
    procedure InitSynchronizeSupport;
    procedure ProcessChildSignal;
    procedure PrepareSynchronize({%H-}AObject: TObject);
    {$ENDIF}

    procedure InitStockItems;
    procedure FreeStockItems;
    function CreateDefaultFont: HFONT;

  public
    constructor Create; override;
    destructor Destroy; override;

    function LCLPlatform: TLCLPlatform; override;
    procedure AppInit(var ScreenInfo: TScreenInfo); override;
    procedure AppRun(const ALoop: TApplicationMainLoop); override;
    procedure AppWaitMessage; override;
    procedure AppProcessMessages; override;
    procedure AppTerminate; override;

    procedure AppMinimize; override;
    procedure AppRestore; override;
    procedure AppBringToFront; override;
    procedure AppSetIcon(const Small, Big: HICON); override;
    procedure AppSetTitle(const ATitle: string); override;
    function AppRemoveStayOnTopFlags(const ASystemTopAlso: Boolean = False): Boolean; override;
    function AppRestoreStayOnTopFlags(const ASystemTopAlso: Boolean = False): Boolean; override;

    function CreateStandardCursor(ACursor: SmallInt): HCURSOR; override;

    function  DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor; override;
    procedure DCSetPixel(CanvasHandle: HDC; X, Y: integer; AColor: TGraphicsColor); override;
    procedure DCRedraw(CanvasHandle: HDC); override;
    procedure DCSetAntialiasing(CanvasHandle: HDC; AEnabled: Boolean); override;
    procedure SetDesigning(AComponent: TComponent); override;

    function CreateTimer(Interval: integer; TimerFunc: TWSTimerProc): THandle; override;
    function DestroyTimer(TimerHandle: THandle): boolean; override;

    function IsValidDC(const DC: HDC): Boolean;
    function IsValidGDIObject(const AGdiObject: HGDIOBJ): Boolean;
    function IsValidHandle(const AHandle: HWND): Boolean;

    property AppIcon: PGdkPixbuf read FAppIcon;
    property DefaultAppFontName: String read FDefaultAppFontName;
    property Gtk3Application: PGtkApplication read FGtk3Application;

    {$i gtk3winapih.inc}
    {$i gtk3lclintfh.inc}
  end;

var
  GTK3WidgetSet: TGTK3WidgetSet;
  // FTimerData contains the currently running timers
  FTimerData: TFPList;   // list of PGtkITimerinfo


function Gtk3WidgetFromGtkWidget(const AWidget: PGtkWidget): TGtk3Widget;
function HwndFromGtkWidget(AWidget: PGtkWidget): HWND;

implementation
uses
  Math, LCLMessageGlue,
  {%H-}Gtk3WSFactory{%H-};

const
  GTK_RESPONSE_LCL_ALL = -10;
  GTK_RESPONSE_LCL_YESTOALL = -3; // GTK_RESPONSE_ACCEPT;
  GTK_RESPONSE_LCL_RETRY = -12;
  GTK_RESPONSE_LCL_IGNORE = -13;
  GTK_RESPONSE_LCL_NOTOALL = -14;

{------------------------------------------------------------------------------
  Function: FillStandardDescription
  Params:
  Returns:
 ------------------------------------------------------------------------------}
procedure FillStandardDescription(var Desc: TRawImageDescription);
begin
  Desc.Init;

  Desc.Format := ricfRGBA;
//  Desc.Width := 0
//  Desc.Height := 0
//  Desc.PaletteColorCount := 0;

  Desc.BitOrder := riboReversedBits;
  Desc.ByteOrder := riboLSBFirst;
  Desc.LineOrder := riloTopToBottom;

  Desc.BitsPerPixel := 32;
  Desc.Depth := 32;
  // Qt wants dword-aligned data
  Desc.LineEnd := rileDWordBoundary;

  // 8-8-8-8 mode, high byte is Alpha
  Desc.AlphaPrec := 8;
  Desc.RedPrec := 8;
  Desc.GreenPrec := 8;
  Desc.BluePrec := 8;

  Desc.AlphaShift := 24;
  Desc.RedShift := 16;
  Desc.GreenShift := 8;
//  Desc.BlueShift := 0;

  // Qt wants dword-aligned data
  Desc.MaskLineEnd := rileDWordBoundary;
  Desc.MaskBitOrder := riboReversedBits;
  Desc.MaskBitsPerPixel := 1;
//  Desc.MaskShift := 0;
end;


function Gtk3WidgetFromGtkWidget(const AWidget: PGtkWidget): TGtk3Widget;
begin
  Result := nil;

  if AWidget = nil then
    exit;

  Result := TGtk3Widget(g_object_get_data(AWidget, 'lclwidget'));
end;

function HwndFromGtkWidget(AWidget: PGtkWidget): HWND;
begin
  Result := HWND(Gtk3WidgetFromGtkWidget(AWidget));
end;

{$i gtk3object.inc}
{$i gtk3winapi.inc}
{$i gtk3lclintf.inc}

end.
