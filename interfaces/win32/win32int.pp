{ $Id$ }
{
 /***************************************************************************
                         WIN32INT.pp  -  Win32Interface Object
                             -------------------



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
}

unit Win32Int;

{$mode objfpc}{$H+}{$T-}{$message warning Fix implicit pointer conversions}
{$I win32defines.inc}

interface

{
  When editing this unit list, be sure to keep Windows listed first to ensure
  successful compilation.
}
uses
  Windows, ActiveX, Classes, Translations, ComCtrls, Controls, Buttons, Dialogs,
  DynHashArray, ExtCtrls, Forms, GraphMath, GraphType, InterfaceBase, LCLIntf,
  LCLType, LMessages, StdCtrls, SysUtils, Win32Def, Graphics, Menus, CommCtrl,
  Themes{, Win32Debug};

const
  // standard windows cursors
  // they are already defined in the rtl, however the
  // const = const defines after this fail with an illegal expression
  IDC_ARROW     = System.MakeIntResource(32512);
  IDC_IBEAM     = System.MakeIntResource(32513);
  IDC_WAIT      = System.MakeIntResource(32514);
  IDC_CROSS     = System.MakeIntResource(32515);
  IDC_UPARROW   = System.MakeIntResource(32516);
  IDC_SIZE      = System.MakeIntResource(32640);
  IDC_ICON      = System.MakeIntResource(32641);
  IDC_SIZENWSE  = System.MakeIntResource(32642);
  IDC_SIZENESW  = System.MakeIntResource(32643);
  IDC_SIZEWE    = System.MakeIntResource(32644);
  IDC_SIZENS    = System.MakeIntResource(32645);
  IDC_SIZEALL   = System.MakeIntResource(32646);
  IDC_NO        = System.MakeIntResource(32648);
  IDC_HAND      = System.MakeIntResource(32649);
  IDC_APPSTARTING = System.MakeIntResource(32650);
  IDC_HELP      = System.MakeIntResource(32651);

{
  These are add-ons, don't exist in windows itself!
  IDC_NODROP    = MakeIntResource(32767);
  IDC_DRAG      = MakeIntResource(32766);
  IDC_HSPLIT    = MakeIntResource(32765);
  IDC_VSPLIT    = MakeIntResource(32764);
  IDC_MULTIDRAG = MakeIntResource(32763);
  IDC_SQLWAIT   = MakeIntResource(32762);
  IDC_HANDPT    = MakeIntResource(32761);
}
  IDC_NODROP    = IDC_NO;
  IDC_DRAG      = IDC_ARROW;
  IDC_HSPLIT    = IDC_SIZEWE;
  IDC_VSPLIT    = IDC_SIZENS;
  IDC_MULTIDRAG = IDC_ARROW;
  IDC_SQLWAIT   = IDC_WAIT;
  IDC_HANDPT    = IDC_HAND;

  LclCursorToWin32CursorMap: array[crLow..crHigh] of PChar = (
  // uni-direction cursors are mapped to bidirection win32 cursors
     IDC_SIZENWSE, IDC_SIZENS, IDC_SIZENESW, IDC_SIZEWE, IDC_SIZEWE,
     IDC_SIZENESW, IDC_SIZENS, IDC_SIZENWSE, IDC_SIZEALL, IDC_HANDPT, IDC_HELP,
     IDC_APPSTARTING, IDC_NO, IDC_SQLWAIT, IDC_MULTIDRAG, IDC_VSPLIT,
     IDC_HSPLIT, IDC_NODROP, IDC_DRAG, IDC_WAIT, IDC_UPARROW, IDC_SIZEWE,
     IDC_SIZENWSE, IDC_SIZENS, IDC_SIZENESW, IDC_SIZE, IDC_IBEAM, IDC_CROSS,
     IDC_ARROW, IDC_ARROW, IDC_ARROW);


  // standard windows icons (WinUser.h)
  // they are already defined in the rtl, however the
  // const = const defines after this fail with an illegal expression
  IDI_APPLICATION = System.MakeIntResource(32512);
  IDI_HAND        = System.MakeIntResource(32513);
  IDI_QUESTION    = System.MakeIntResource(32514);
  IDI_EXCLAMATION = System.MakeIntResource(32515);
  IDI_ASTERISK    = System.MakeIntResource(32516);
  IDI_WINLOGO     = System.MakeIntResource(32517); // XP only

  IDI_WARNING     = IDI_EXCLAMATION;
  IDI_ERROR       = IDI_HAND;
  IDI_INFORMATION = IDI_ASTERISK;

type
  PInitCommonControlsEx = ^TInitCommonControlsEx;
  TInitCommonControlsEx = record
    dwSize: dword;
    dwICC: dword;
  end;

  PPPipeEventInfo = ^PPipeEventInfo;
  PPipeEventInfo = ^TPipeEventInfo;
  TPipeEventInfo = record
    Handle: THandle;
    UserData: PtrInt;
    OnEvent: TPipeEvent;
    Prev: PPipeEventInfo;
    Next: PPipeEventInfo;
  end;

  TWaitHandler = record
    ListIndex: pdword;
    UserData: PtrInt;
    OnEvent: TWaitHandleEvent;
  end;

  TSocketEvent = function(ASocket: THandle; Flags: dword): Integer of object;

  { Win32 interface-object class }

  { TWin32WidgetSet }

  TWin32WidgetSet = class(TWidgetSet)
  private
    // The parent of all windows, represents the button of the taskbar
    // This window is also the owner of the clipboard.
    // Assoc. windowproc also acts as handler for popup menus
    FAppHandle: HWND;
    FCommonControlsVersion: DWord;

    FMetrics: TNonClientMetrics;
    FMetricsFailed: Boolean;

    FWaitHandleCount: dword;
    FWaitHandles: array of HANDLE;
    FWaitHandlers: array of TWaitHandler;
    FWaitPipeHandlers: PPipeEventInfo;
    FPendingWaitHandlerIndex: Integer;

    InitCommonControlsEx: function(ICC: PInitCommonControlsEx): LongBool; stdcall;

    FOnAsyncSocketMsg: TSocketEvent;
    FDotsPatternBitmap: HBitmap;

    procedure AssignSelf(Window: HWnd; Data: Pointer);
    function GetDotsPatternBitmap: HBitmap;

    { event handler helper functions }
    procedure HandleProcessEvent(AData: PtrInt; AFlags: dword);
    procedure CheckPipeEvents;

    function WinRegister: Boolean;
  protected
    function CreateThemeServices: TThemeServices; override;
  public
    { Creates a callback of Lazarus message Msg for Sender }
    procedure SetCallback(Msg: LongInt; Sender: TObject); virtual;
    { Removes all callbacks for Sender }
    procedure RemoveCallbacks(Sender: TObject); virtual;

    { Constructor of the class }
    constructor Create; override;
    { Destructor of the class }
    destructor Destroy; override;

    function LCLPlatform: TLCLPlatform; override;
    function GetLCLCapability(ACapability: TLCLCapability): PtrUInt; override;

    { Initialize the API }
    procedure AppInit(var ScreenInfo: TScreenInfo); override;
    procedure AppMinimize; override;
    procedure AppRestore; override;
    procedure AppBringToFront; override;
    procedure AppProcessMessages; override;
    procedure AppWaitMessage; override;
    procedure AppTerminate; override;
    procedure AppSetIcon(const Small, Big: HICON); override;
    procedure AppSetTitle(const ATitle: string); override;
    procedure AppSetVisible(const AVisible: Boolean); override;

    function  InitHintFont(HintFont: TObject): Boolean; Override;
    procedure AttachMenuToWindow(AMenuObject: TComponent); Override;

    procedure DCSetPixel(CanvasHandle: HDC; X, Y: integer; AColor: TGraphicsColor); override;
    function  DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor; override;
    procedure DCRedraw(CanvasHandle: HDC); override;
    procedure SetDesigning(AComponent: TComponent); override;

    procedure ShowHide(Sender: TObject);

    // create and destroy
    function CreateTimer(Interval: integer; TimerFunc: TFNTimerProc) : THandle; override;
    function DestroyTimer(TimerHandle: THandle) : boolean; override;

    // thread synchronize support
    procedure HandleWakeMainThread(Sender: TObject);
    function AppHandle: THandle; override;

    {$I win32winapih.inc}
    {$I win32lclintfh.inc}

    //property MessageFont: HFONT read FMessageFont;
    property CommonControlsVersion: DWord read FCommonControlsVersion;
    property OnAsyncSocketMsg: TSocketEvent read FOnAsyncSocketMsg write FOnAsyncSocketMsg;
    property DotsPatternBitmap: HBitmap read GetDotsPatternBitmap;
  end;

  {$I win32listslh.inc}
  
var
  Win32WidgetSet: TWin32WidgetSet absolute WidgetSet;


const
  BOOL_RESULT: array[Boolean] of String = ('False', 'True');
  ClsName: array[0..6] of char = 'Window'#0;
  EditClsName: array[0..4] of char = 'Edit'#0;
  ButtonClsName: array[0..6] of char = 'Button'#0;
  ComboboxClsName: array[0..8] of char = 'ComboBox'#0;
  TabControlClsName: array[0..15] of char = 'SysTabControl32'#0;
  ListViewClsName: array[0..13] of char = 'SysListView32'#0;

  ClsNameW: array[0..6] of WideChar = ('W', 'i', 'n', 'd', 'o', 'w', #0);

{$ifdef DEBUG_DOUBLEBUFFER}
var
  CopyBitmapToClipboard: boolean = true;
{$endif}

{ export for widgetset implementation }

function WindowProc(Window: HWnd; Msg: UInt; WParam: Windows.WParam;
    LParam: Windows.LParam): LResult; stdcall;
function CallDefaultWindowProc(Window: HWnd; Msg: UInt; WParam: Windows.WParam;
  LParam: Windows.LParam): LResult;

implementation

uses
  WsControls,
  Win32Proc,
////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To get as little as possible circles,
// uncomment only those units with implementation
////////////////////////////////////////////////////
// Win32WSActnList,
 Win32WSArrow,
 Win32WSButtons,
 Win32WSCalendar,
 Win32WSCheckLst,
 Win32WSComCtrls,
 Win32WSControls,
// Win32WSDbCtrls,
// Win32WSDBGrids,
 Win32WSDialogs,
// Win32WSEditBtn,
 Win32WSExtCtrls,
 Win32WSExtDlgs,
// Win32WSFileCtrl,
 Win32WSForms,
 Win32WSGrids,
 Win32WSImgList,
// Win32WSMaskEdit,
 Win32WSMenus,
 Win32WSPairSplitter,
 Win32WSSpin,
 Win32WSStdCtrls,
// Win32WSToolwin,
 Win32Themes,
////////////////////////////////////////////////////
 Arrow, Calendar, Spin, CheckLst, Win32Extra, LclProc, LCLMessageGlue, Win32WSFactory;

type
  TMouseDownFocusStatus = (mfNone, mfFocusSense, mfFocusChanged);

  PProcessEvent = ^TProcessEvent;
  TProcessEvent = record
    Handle: THandle;
    Handler: PEventHandler;
    UserData: PtrInt;
    OnEvent: TChildExitEvent;
  end;

var
  MouseDownCount: Integer;
  MouseDownTime: dword;
  MouseDownPos: TPoint;
  MouseDownWindow: HWND = 0;
  MouseDownFocusWindow: HWND;
  MouseDownFocusStatus: TMouseDownFocusStatus = mfNone;
  ComboBoxHandleSizeWindow: HWND = 0;
  IgnoreNextCharWindow: HWND = 0;  // ignore next WM_(SYS)CHAR message
  // set to true, if we are redirecting a WM_MOUSEWHEEL message, to prevent recursion
  InMouseWheelRedirection: boolean = false;
  OnClipBoardRequest: TClipboardRequestEvent;

  MMenuItemInfoSize: DWORD; // size depends on windows version;

{$ifdef MSG_DEBUG}
  MessageStackDepth: string = '';
{$endif}

{$I win32listsl.inc}
{$I win32callback.inc}
{$I win32object.inc}
{$I win32winapi.inc}
{$I win32lclintf.inc}

const
  W95_MENUITEMINFO_SIZE = 44;
  
initialization

  Assert(False, 'Trace:win32int.pp - Initialization');
  { initialize mousedownclick to far before double click time }
  MouseDownTime := GetTickCount - 5000;
  {$IFDEF WindowsUnicodeSupport}
  SystemCharSetIsUTF8:=true;
  {$ELSE}
  SystemCharSetIsUTF8:=false;
  {$ENDIF}

  if (Win32MajorVersion = 4) and (Win32MinorVersion = 0)
  then MMenuItemInfoSize := W95_MENUITEMINFO_SIZE
  else MMenuItemInfoSize := sizeof(MENUITEMINFO);

finalization
  if CurDoubleBuffer.Bitmap <> 0 then
  begin
    Windows.DeleteObject(CurDoubleBuffer.Bitmap);
    CurDoubleBuffer.Bitmap := 0;
  end;
  Assert(False, 'Trace:win32int.pp - Finalization');

end.
