{
 /***************************************************************************
                                  forms.pp
                                  --------
                             Component Library Code


                   Initial Revision  : Sun Mar 28 23:15:32 CST 1999
                   Revised : Sat Jul 15 1999

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

unit Forms;

{$mode objfpc}{$H+}{$macro on}

interface

{$ifdef Trace}
  {$ASSERTIONS ON}
{$endif}

{$DEFINE HasDefaultValues}

uses
  Classes, SysUtils, Types, TypInfo, Math,
  AvgLvlTree, Maps, LCLVersion, LCLStrConsts, LCLType, LCLProc, LCLIntf,
  FileUtil, InterfaceBase, LResources, GraphType, Graphics, Menus, LMessages,
  CustomTimer, ActnList, ClipBrd, CustApp, HelpIntfs, LCLClasses, Controls, Themes
  {$ifndef wince},gettext{$endif}// remove ifdefs when gettext is fixed and a new fpc is released
  ;

type
  // forward class declarations
  TIDesigner = class;
  TMonitor = class;
  TScrollingWinControl = class;

  TProcedure = procedure;
  TProcedureOfObject = procedure of object;

  // form position policies:
  TPosition = (
    poDesigned,        // use bounds from the designer (read from stream)
    poDefault,         // LCL decision (normally window manager decides)
    poDefaultPosOnly,  // designed size and LCL position
    poDefaultSizeOnly, // designed position and LCL size
    poScreenCenter,    // center form on screen (depends on DefaultMonitor)
    poDesktopCenter,   // center form on desktop (total of all screens)
    poMainFormCenter,  // center form on main form (depends on DefaultMonitor)
    poOwnerFormCenter  // center form on owner form (depends on DefaultMonitor)
    );

  TWindowState = (wsNormal, wsMinimized, wsMaximized);
  TCloseAction = (caNone, caHide, caFree, caMinimize);

  { Hint actions }

  TCustomHintAction = class(TCustomAction)
  published
    property Hint;
  end;


  { TControlScrollBar }

  TScrollBarKind = (sbHorizontal, sbVertical);
  TScrollBarInc = 1..32768;
  TScrollBarStyle = (ssRegular, ssFlat, ssHotTrack);
  EScrollBar = class(Exception) end;

  TControlScrollBar = class(TPersistent)
  private
    FAutoRange : Longint;
    FIncrement: TScrollBarInc;
    FKind: TScrollBarKind;
    FPage: TScrollBarInc;
    FPosition: Integer;
    FRange: Integer;
    FSmooth : Boolean;
    FVisible: Boolean;
    FOldScrollInfo: TScrollInfo;
    FOldScrollInfoValid: Boolean;
    FOldHandleVisible: Boolean;
  protected
    FControl: TWinControl;
    function ControlAutoScroll: boolean; virtual;
    function ControlHandle: HWnd; virtual;
    function GetIncrement: TScrollBarInc; virtual;
    function GetPage: TScrollBarInc; virtual;
    function GetPosition: Integer; virtual;
    function GetRange: Integer; virtual;
    function GetSize: integer; virtual;
    function GetSmooth: Boolean; virtual;
    function GetVisible: Boolean; virtual;
    function HandleAllocated: boolean; virtual;
    function SmoothIsStored: boolean; virtual;
    function VisibleIsStored: boolean; virtual;
    procedure AutoCalcRange; virtual;
    procedure ControlUpdateScrollBars; virtual;
    procedure ScrollHandler(var Message: TLMScroll);
    procedure SetIncrement(const AValue: TScrollBarInc); virtual;
    procedure SetPage(const AValue: TScrollBarInc); virtual;
    procedure SetPosition(const Value: Integer); virtual;
    procedure SetRange(const Value: Integer); virtual;
    procedure SetSize(const AValue: integer); virtual;
    procedure SetSmooth(const Value: Boolean); virtual;
    procedure SetVisible(const Value: Boolean); virtual;
    procedure UpdateScrollBar; virtual;
    procedure InvalidateScrollInfo;
  {$ifdef VerboseScrollingWinControl}
    function DebugCondition: Boolean;
  {$endif}
    function GetHorzScrollBar: TControlScrollBar; virtual;
    function GetVertScrollBar: TControlScrollBar; virtual;
  public
    constructor Create(AControl: TWinControl; AKind: TScrollBarKind);
    procedure Assign(Source: TPersistent); override;
    function IsScrollBarVisible: Boolean; virtual;
    function ScrollPos: Integer; virtual;
    property Kind: TScrollBarKind read FKind;
    function GetOtherScrollBar: TControlScrollBar;
    property Size: integer read GetSize write SetSize stored false;
  published
    property Increment: TScrollBarInc read GetIncrement write SetIncrement default 8;
    property Page: TScrollBarInc read GetPage write SetPage default 80;
    property Smooth : Boolean read GetSmooth write SetSmooth stored SmoothIsStored;
    property Position: Integer read GetPosition write SetPosition default 0;
    property Range: Integer read GetRange write SetRange default 0;
    property Visible: Boolean read GetVisible write SetVisible stored VisibleIsStored;
  end;


  { TScrollingWinControl }

  TScrollingWinControl = class(TCustomControl)
  private
    FHorzScrollBar: TControlScrollBar;
    FVertScrollBar: TControlScrollBar;
    FAutoScroll: Boolean;
    FIsUpdating: Boolean;
    procedure SetAutoScroll(Value: Boolean);
    procedure SetHorzScrollBar(Value: TControlScrollBar);
    procedure SetVertScrollBar(Value: TControlScrollBar);
    function StoreScrollBars : Boolean;
  protected
    class procedure WSRegisterClass; override;
    property AutoScroll: Boolean read FAutoScroll write SetAutoScroll default true;
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    procedure CreateWnd; override;
    function GetClientScrollOffset: TPoint; override;
    function GetLogicalClientRect: TRect; override;// logical size of client area
    procedure DoOnResize; override;
    procedure WMHScroll(var Message : TLMHScroll); message LM_HScroll;
    procedure WMVScroll(var Message : TLMVScroll); message LM_VScroll;
    function ComputeScrollbars: Boolean; virtual;
    procedure ScrollbarHandler(ScrollKind: TScrollBarKind;
                               OldPosition: Integer); virtual;
    procedure Loaded; override;
  public
    constructor Create(TheOwner : TComponent); override;
    destructor Destroy; override;
    procedure UpdateScrollbars;
    function HasVisibleScrollbars: boolean; virtual;
    class function GetControlClassDefaultSize: TPoint; override;
    procedure ScrollBy(DeltaX, DeltaY: Integer);
  published
    property HorzScrollBar: TControlScrollBar
              read FHorzScrollBar write SetHorzScrollBar stored StoreScrollBars;
    property VertScrollBar: TControlScrollBar
              read FVertScrollBar write SetVertScrollBar stored StoreScrollBars;
  end;


  { TScrollBox }

  TScrollBox = class(TScrollingWinControl)
  protected
    class procedure WSRegisterClass; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Align;
    property Anchors;
    property AutoSize;
    property AutoScroll;
    property BorderSpacing;
    property BiDiMode;
    property BorderStyle default bsSingle;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Constraints;
    property DockSite;
    property DragCursor;
    property DragKind;

    property DragMode;
    property Enabled;
    property Color nodefault;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    //property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnDblClick;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    property OnPaint;
  end;


  { TCustomFrame }

  TCustomFrame = class(TScrollingWinControl)
  private
    procedure AddActionList(ActionList: TCustomActionList);
    procedure RemoveActionList(ActionList: TCustomActionList);
    procedure ReadDesignLeft(Reader: TReader);
    procedure ReadDesignTop(Reader: TReader);
    procedure WriteDesignLeft(Writer: TWriter);
    procedure WriteDesignTop(Writer: TWriter);
  protected
    class procedure WSRegisterClass; override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure SetParent(AParent: TWinControl); override;
    procedure DefineProperties(Filer: TFiler); override;
  public
    constructor Create(AOwner: TComponent); override;
    class function GetControlClassDefaultSize: TPoint; override;
  end;

  TCustomFrameClass = class of TCustomFrame;


  { TFrame }

  TFrame = class(TCustomFrame)
  private
    FLCLVersion: string;
    function LCLVersionIsStored: boolean;
  public
    constructor Create(TheOwner: TComponent); override;
  published
    property Align;
    property Anchors;
    property AutoScroll;
    property AutoSize;
    property BorderSpacing;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Color nodefault;
    property Constraints;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property LCLVersion: string read FLCLVersion write FLCLVersion stored LCLVersionIsStored;
    property OnClick;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDblClick;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
  end;


  { TCustomForm }

  TBorderIcon = ( // Form title bar items
    biSystemMenu, // system menu
    biMinimize,   // minimize button
    biMaximize,   // maximize button
    biHelp        // help button
  );
  TBorderIcons = set of TBorderIcon;

  TDefaultMonitor = ( // monitor to place form
    dmDesktop,        // use full desktop
    dmPrimary,        // use primary monitor
    dmMainForm,       // use monitor of main form
    dmActiveForm      // use monitor of active form
  );

  TFormStateType = (
    fsCreating,          // initializing (form streaming)
    fsVisible,           // form should be shown
    fsShowing,           // form handling WM_SHOWWINDOW message
    fsModal,             // form is modal
    fsCreatedMDIChild,   // todo: not mplemented
    fsBorderStyleChanged,// border style is changed before window handle creation
    fsFormStyleChanged,  // form style is changed before window handle creation
    fsFirstShow,         // form is shown for the first time
    fsDisableAutoSize    // disable autosize
    );
  TFormState = set of TFormStateType;

  TModalResult = low(Integer)..high(Integer);
  PModalResult = ^TModalResult;

  TFormHandlerType = (
    fhtFirstShow,
    fhtClose,
    fhtCreate
    );

  TShowInTaskbar = (stDefault, stAlways, stNever);

  TCloseEvent = procedure(Sender: TObject; var CloseAction: TCloseAction) of object;
  TCloseQueryEvent = procedure(Sender : TObject; var CanClose : boolean) of object;
  TDropFilesEvent = procedure (Sender: TObject; const FileNames: Array of String) of object;
  THelpEvent = function(Command: Word; Data: PtrInt; var CallHelp: Boolean): Boolean of object;
  TShortCutEvent = procedure (var Msg: TLMKey; var Handled: Boolean) of object;

  TCustomForm = class(TScrollingWinControl)
  private
    FActive: Boolean;
    FActiveControl: TWinControl;
    FActiveDefaultControl: TControl;
    FAllowDropFiles: Boolean;
    FBorderIcons: TBorderIcons;
    FDefaultControl: TControl;
    FCancelControl: TControl;
    FDefaultMonitor: TDefaultMonitor;
    FDesigner: TIDesigner;
    FFormState: TFormState;
    FFormStyle: TFormStyle;
    FFormUpdateCount: integer;
    FFormHandlers: array[TFormHandlerType] of TMethodList;
    FHelpFile: string;
    FIcon: TIcon;
    FSmallIconHandle: HICON;
    FBigIconHandle: HICON;
    FKeyPreview: Boolean;
    FMenu: TMainMenu;
    FModalResult: TModalResult;
    FOldBorderStyle: TFormBorderStyle;
    FOnActivate: TNotifyEvent;
    FOnClose: TCloseEvent;
    FOnCloseQuery: TCloseQueryEvent;
    FOnCreate: TNotifyEvent;
    FOnDeactivate: TNotifyEvent;
    FOnDestroy: TNotifyEvent;
    FOnDropFiles: TDropFilesEvent;
    FOnHelp: THelpEvent;
    FOnHide: TNotifyEvent;
    FOnShortcut: TShortCutEvent;
    FOnShow: TNotifyEvent;
    FOnWindowStateChange: TNotifyEvent;
    FPixelsPerInch: Longint;
    FPosition: TPosition;
    FRestoredLeft: integer;
    FRestoredTop: integer;
    FRestoredWidth: integer;
    FRestoredHeight: integer;
    FShowInTaskbar: TShowInTaskbar;
    FWindowState: TWindowState;
    function GetMonitor: TMonitor;
    function GetPixelsPerInch: Longint;
    function GetRestoredLeft: integer;
    function GetRestoredTop: integer;
    function IsForm : Boolean;
    function IsHelpFileStored: boolean;
    function IsIconStored: Boolean;
    procedure CloseModal;
    procedure FreeIconHandles;
    procedure IconChanged(Sender: TObject);
    function IsKeyPreviewStored: boolean;
    procedure SetActive(AValue: Boolean);
    procedure SetActiveControl(AWinControl: TWinControl);
    procedure SetActiveDefaultControl(AControl: TControl);
    procedure SetAllowDropFiles(const AValue: Boolean);
    procedure SetBorderIcons(NewIcons: TBorderIcons);
    procedure SetFormBorderStyle(NewStyle: TFormBorderStyle);
    procedure SetCancelControl(NewControl: TControl);
    procedure SetDefaultControl(NewControl: TControl);
    procedure SetDesigner(Value : TIDesigner);
    procedure SetFormStyle(Value : TFormStyle);
    procedure SetIcon(AValue: TIcon);
    procedure SetMenu(Value : TMainMenu);
    procedure SetModalResult(const AValue: TModalResult);
    procedure SetPosition(Value : TPosition);
    procedure SetShowInTaskbar(Value: TShowInTaskbar);
    procedure SetWindowFocus;
    procedure SetWindowState(Value : TWindowState);
    procedure WMActivate(var Message : TLMActivate); message LM_ACTIVATE;
    procedure WMCloseQuery(var message: TLMessage); message LM_CLOSEQUERY;
    procedure WMDeactivate(var Message : TLMActivate); message LM_DEACTIVATE;
    procedure WMPaint(var message: TLMPaint); message LM_PAINT;
    procedure WMShowWindow(var message: TLMShowWindow); message LM_SHOWWINDOW;
    procedure WMSize(var message: TLMSize); message LM_Size;
    procedure CMBiDiModeChanged(var Message: TLMessage); message CM_BIDIMODECHANGED;
    procedure CMAppShowBtnGlyphChanged(var Message: TLMessage); message CM_APPSHOWBTNGLYPHCHANGED;
    procedure CMAppShowMenuGlyphChanged(var Message: TLMessage); message CM_APPSHOWMENUGLYPHCHANGED;
    procedure CMIconChanged(var Message: TLMessage); message CM_ICONCHANGED;
    procedure CMRelease(var Message: TLMessage); message CM_RELEASE;
    procedure AddHandler(HandlerType: TFormHandlerType;
                         const Handler: TMethod; AsLast: Boolean);
    procedure RemoveHandler(HandlerType: TFormHandlerType;
                            const Handler: TMethod);
    function FindDefaultForActiveControl: TWinControl;
  protected
    FFormBorderStyle: TFormBorderStyle;
    FActionLists: TList;
    class procedure WSRegisterClass; override;
    procedure CMShowingChanged(var Message: TLMessage); message CM_SHOWINGCHANGED;
    procedure DoShowWindow; virtual;
    procedure Activate; virtual;
    procedure ActiveChanged; virtual;
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure BeginFormUpdate;
    function ColorIsStored: boolean; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Deactivate; virtual;
    procedure DoClose(var CloseAction: TCloseAction); virtual;
    procedure DoCreate; virtual;
    procedure DoDestroy; virtual;
    procedure DoHide; virtual;
    procedure DoShow; virtual;
    procedure EndFormUpdate;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    function HandleCreateException: Boolean; virtual;
    function HandleDestroyException: Boolean; virtual;
    function HandleShowHideException: Boolean; virtual;
    procedure Loaded; override;
    procedure ChildHandlesCreated; override;
    procedure Notification(AComponent: TComponent; Operation : TOperation);override;
    procedure PaintWindow(dc : Hdc); override;
    procedure RequestAlign; override;
    procedure SetZOrder(Topmost: Boolean); override;
    procedure SetParent(NewParent: TWinControl); override;
    procedure UpdateShowing; override;
    procedure SetVisible(Value: boolean); override;
    procedure DoFirstShow; virtual;
    procedure UpdateWindowState;
    procedure VisibleChanging; override;
    procedure WndProc(var TheMessage : TLMessage); override;
    function VisibleIsStored: boolean;
    procedure DoSendBoundsToInterface; override;
    procedure DoAutoSize; override;
    procedure SetAutoSize(Value: Boolean); override;
  protected
    // drag and dock
    procedure BeginAutoDrag; override;
    procedure DoDock(NewDockSite: TWinControl; var ARect: TRect); override;
    function GetFloating: Boolean; override;
    function GetDefaultDockCaption: String; override;
  protected
    // actions
    procedure CMActionExecute(var Message: TLMessage); message CM_ACTIONEXECUTE;
    procedure CMActionUpdate(var Message: TLMessage); message CM_ACTIONUPDATE;
    function DoExecuteAction(ExeAction: TBasicAction): boolean;
    function DoUpdateAction(TheAction: TBasicAction): boolean;
    procedure UpdateActions; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateNew(AOwner: TComponent; Num : Integer{=0}); virtual;
    destructor Destroy; override;
    procedure BeforeDestruction; override;

    class function GetControlClassDefaultSize: TPoint; override;

    function BigIconHandle: HICON;
    procedure Close;
    function CloseQuery: boolean; virtual;
    procedure DefocusControl(Control: TWinControl; Removing: Boolean);
    procedure DestroyWnd; override;
    procedure EnsureVisible(AMoveToTop: Boolean = True);
    procedure FocusControl(WinControl: TWinControl);
    function FormIsUpdating: boolean; override;
    function GetFormImage: TBitmap;
    function GetRolesForControl(AControl: TControl): TControlRolesForForm;
    procedure Hide;
    procedure IntfDropFiles(const FileNames: array of String);
    procedure IntfHelp(AComponent: TComponent);
    function IsShortcut(var Message: TLMKey): boolean; virtual;
    procedure MakeFullyVisible(AMonitor: TMonitor = nil; UseWorkarea: Boolean = False);
    function NeedParentForAutoSize: Boolean; override;
    procedure Release;
    procedure SetFocus; override;
    function SetFocusedControl(Control: TWinControl): Boolean ; virtual;
    procedure SetRestoredBounds(ALeft, ATop, AWidth, AHeight: integer);
    procedure Show;
    function ShowModal: Integer; virtual;
    procedure ShowOnTop;
    function SmallIconHandle: HICON;
    function WantChildKey(Child : TControl;
                          var Message : TLMessage): Boolean; virtual;

    // handlers
    procedure AddHandlerFirstShow(OnFirstShowHandler: TNotifyEvent;
                                  AsLast: Boolean=true);
    procedure RemoveAllHandlersOfObject(AnObject: TObject); override;
    procedure RemoveHandlerFirstShow(OnFirstShowHandler: TNotifyEvent);
    procedure AddHandlerClose(OnCloseHandler: TCloseEvent; AsLast: Boolean=true);
    procedure RemoveHandlerClose(OnCloseHandler: TCloseEvent);
    procedure AddHandlerCreate(OnCreateHandler: TNotifyEvent; AsLast: Boolean=true);
    procedure RemoveHandlerCreate(OnCreateHandler: TNotifyEvent);
  public
    // drag and dock
    procedure Dock(NewDockSite: TWinControl; ARect: TRect); override;
  public
    property Active: Boolean read FActive;
    property ActiveControl: TWinControl read FActiveControl write SetActiveControl;
    property ActiveDefaultControl: TControl read FActiveDefaultControl write SetActiveDefaultControl;
    property AllowDropFiles: Boolean read FAllowDropFiles write SetAllowDropFiles default False;
    property BorderIcons: TBorderIcons read FBorderIcons write SetBorderIcons
      default [biSystemMenu, biMinimize, biMaximize];
    property BorderStyle: TFormBorderStyle
                      read FFormBorderStyle write SetFormBorderStyle default bsSizeable;
    property CancelControl: TControl read FCancelControl write SetCancelControl;
    property Caption stored IsForm;
    property Color default clBtnFace;
    property DefaultControl: TControl read FDefaultControl write SetDefaultControl;
    property DefaultMonitor: TDefaultMonitor read FDefaultMonitor
      write FDefaultMonitor default dmActiveForm;
    property Designer: TIDesigner read FDesigner write SetDesigner;
    property FormState: TFormState read FFormState;
    property FormStyle: TFormStyle read FFormStyle write SetFormStyle
                                   default fsNormal;
    property HelpFile: string read FHelpFile write FHelpFile
                              stored IsHelpFileStored;
    property Icon: TIcon read FIcon write SetIcon stored IsIconStored;
    property KeyPreview: Boolean read FKeyPreview write FKeyPreview
                                 stored IsKeyPreviewStored default False;
    property Menu : TMainMenu read FMenu write SetMenu;
    property ModalResult : TModalResult read FModalResult write SetModalResult;
    property Monitor: TMonitor read GetMonitor;
    property OnActivate: TNotifyEvent read FOnActivate write FOnActivate;
    property OnClose: TCloseEvent read FOnClose write FOnClose stored IsForm;
    property OnCloseQuery : TCloseQueryEvent
                     read FOnCloseQuery write FOnCloseQuery stored IsForm;
    property OnCreate: TNotifyEvent read FOnCreate write FOnCreate;
    property OnDeactivate: TNotifyEvent read FOnDeactivate write FOnDeactivate;
    property OnDestroy: TNotifyEvent read FOnDestroy write FOnDestroy;
    property OnDropFiles: TDropFilesEvent read FOnDropFiles write FOnDropFiles;
    property OnHelp: THelpEvent read FOnHelp write FOnHelp;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnResize stored IsForm;
    property OnShortcut: TShortcutEvent read FOnShortcut write FOnShortcut;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
    property OnWindowStateChange: TNotifyEvent
                         read fOnWindowStateChange write fOnWindowStateChange;
    property ParentFont default False;
    property PixelsPerInch: Longint read GetPixelsPerInch write FPixelsPerInch stored False;
    property Position: TPosition read FPosition write SetPosition default poDesigned;
    property RestoredLeft: integer read GetRestoredLeft;
    property RestoredTop: integer read GetRestoredTop;
    property RestoredWidth: integer read FRestoredWidth;
    property RestoredHeight: integer read FRestoredHeight;
    property ShowInTaskBar: TShowInTaskbar read FShowInTaskbar write SetShowInTaskBar
                                    default stDefault;
    property Visible stored VisibleIsStored default false;
    property WindowState: TWindowState read FWindowState write SetWindowState
                                       default wsNormal;
  end;

  TCustomFormClass = class of TCustomForm;


  { TForm }

  TForm = class(TCustomForm)
  private
    FClientHandle: HWND;
    FLCLVersion: string;
    function LCLVersionIsStored: boolean;
  protected
    procedure CreateWnd; override;
    procedure Loaded; override;
  public
    constructor Create(TheOwner: TComponent); override;
    property ClientHandle: HWND read FClientHandle;
    property DockManager;
  published
    property Action;
    property ActiveControl;
    property Align;
    property AllowDropFiles;
    property AutoScroll;
    property AutoSize;
    property BiDiMode;
    property BorderIcons;
    property BorderStyle;
    property BorderWidth;
    property Caption;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Color;
    property Constraints;
    property DefaultMonitor;
    property DockSite;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property FormStyle;
    property HelpFile;
    property Icon;
    property KeyPreview;
    property Menu;
    property OnActivate;
    property OnChangeBounds;
    property OnClick;
    property OnClose;
    property OnCloseQuery;
    property OnCreate;
    property OnDblClick;
    property OnDeactivate;
    property OnDestroy;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    property OnDropFiles;
    property OnEndDock;
    property OnGetSiteInfo;
    property OnHelp;
    property OnHide;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnPaint;
    property OnResize;
    property OnShortCut;
    property OnShow;
    property OnShowHint;
    property OnStartDock;
    property OnUnDock;
    property OnUTF8KeyPress;
    property OnWindowStateChange;
    property ParentBiDiMode;
    property ParentFont;
    property PixelsPerInch;
    property PopupMenu;
    property Position;
    property SessionProperties;
    property ShowHint;
    property ShowInTaskBar;
    property UseDockManager;
    property LCLVersion: string read FLCLVersion write FLCLVersion stored LCLVersionIsStored;
    property Visible;
    property WindowState;
  end;

  TFormClass = class of TForm;


  { TCustomDockForm }

  TCustomDockForm = class(TCustomForm)
  protected
    procedure DoAddDockClient(Client: TControl; const ARect: TRect); override;
    procedure DoRemoveDockClient(Client: TControl); override;
    procedure GetSiteInfo(Client: TControl; var InfluenceRect: TRect;
                          MousePos: TPoint; var CanDock: Boolean); override;
    procedure Loaded; override;
  public
    constructor Create(TheOwner: TComponent); override;
    property AutoScroll default False;
    property BorderStyle default bsSizeToolWin;
    property FormStyle default fsStayOnTop;
  published
    property PixelsPerInch;
  end;


  { THintWindow }

  THintWindow = class(TCustomForm)
  private
    FActivating: Boolean;
    FAutoHide : Boolean;
    FAutoHideTimer : TComponent;
    FHideInterval : Integer;
    procedure SetAutoHide(Value : Boolean);
    procedure AutoHideHint(Sender : TObject);
    procedure SetHideInterval(Value : Integer);
  protected
    class procedure WSRegisterClass; override;
    procedure DoShowWindow; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ActivateHint(ARect: TRect; const AHint: String); virtual;
    procedure ActivateHintData(ARect: TRect; const AHint: String;
                               AData: pointer); virtual;
    function CalcHintRect(MaxWidth: Integer; const AHint: String;
                          AData: Pointer): TRect; virtual;
    procedure ReleaseHandle;
    procedure Paint; override;
    class function GetControlClassDefaultSize: TPoint; override;
  public
    property AutoHide : Boolean read FAutoHide write SetAutoHide;
    property HideInterval : Integer read FHideInterval write SetHideInterval;
  end;

  THintWindowClass = class of THintWindow;

  { TMonitor }

  TMonitor = class(TObject)
  private
    FHandle: HMONITOR;
    FMonitorNum: Integer;
    function GetInfo(out Info: TMonitorInfo): Boolean; {inline; fpc bug - compilation error with inline}
    function GetLeft: Integer;
    function GetHeight: Integer;
    function GetTop: Integer;
    function GetWidth: Integer;
    function GetBoundsRect: TRect;
    function GetWorkareaRect: TRect;
    function GetPrimary: Boolean;
  public
    property Handle: HMONITOR read FHandle;
    property MonitorNum: Integer read FMonitorNum;
    property Left: Integer read GetLeft;
    property Height: Integer read GetHeight;
    property Top: Integer read GetTop;
    property Width: Integer read GetWidth;
    property BoundsRect: TRect read GetBoundsRect;
    property WorkareaRect: TRect read GetWorkareaRect;
    property Primary: Boolean read GetPrimary;
  end;

  { TMonitorList }

  TMonitorList = class(TList)
  private
    function GetItem(AIndex: Integer): TMonitor;
    procedure SetItem(AIndex: Integer; const AValue: TMonitor);
  protected
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  public
    property Items[AIndex: Integer]: TMonitor read GetItem write SetItem; default;
  end;

  { TScreen }

  PCursorRec = ^TCursorRec;
  TCursorRec = record
    Next: PCursorRec;
    Index: Integer;
    Handle: HCURSOR;
  end;

  TScreenFormEvent = procedure(Sender: TObject; Form: TCustomForm) of object;
  TScreenActiveFormChangedEvent = procedure(Sender: TObject;
                                            LastForm: TCustomForm) of object;
  TScreenControlEvent = procedure(Sender: TObject;
                                  LastControl: TControl) of object;

  TScreenNotification = (
    snFormAdded,
    snRemoveForm,
    snActiveControlChanged,
    snActiveFormChanged
    );

  TMonitorDefaultTo = (mdNearest, mdNull, mdPrimary);

  { TScreen }

  TScreen = class(TLCLComponent)
  private
    FActiveControl: TWinControl;
    FActiveCustomForm: TCustomForm;
    FActiveForm: TForm;
    FCursor: TCursor;
    FCursorMap: TMap;
    FCustomForms: TList;
    FCustomFormsZOrdered: TList;
    FDefaultCursor: HCURSOR;
    FHintFont: TFont;
    FFocusedForm: TCustomForm;
    FFonts : TStrings;
    FFormList: TList;
    FDataModuleList: TList;
    FIconFont: TFont;
    FMenuFont: TFont;
    FScreenHandlers: array[TScreenNotification] of TMethodList;
    FLastActiveControl: TWinControl;
    FLastActiveCustomForm: TCustomForm;
    FMonitors: TMonitorList;
    FOnActiveControlChange: TNotifyEvent;
    FOnActiveFormChange: TNotifyEvent;
    FPixelsPerInch : integer;
    FSaveFocusedList: TList;
    FSystemFont: TFont;
    procedure DeleteCursor(AIndex: Integer);
    procedure DestroyCursors;
    procedure DestroyMonitors;
    function GetCursors(AIndex: Integer): HCURSOR;
    function GetCustomFormCount: Integer;
    function GetCustomFormZOrderCount: Integer;
    function GetCustomForms(Index: Integer): TCustomForm;
    function GetCustomFormsZOrdered(Index: Integer): TCustomForm;
    function GetDataModuleCount: Integer;
    function GetDataModules(AIndex: Integer): TDataModule;
    function GetDesktopHeight: Integer;
    function GetDesktopWidth: Integer;
    function GetFonts : TStrings;
    function GetFormCount: Integer;
    function GetForms(IIndex: Integer): TForm;
    function GetHeight : Integer;
    function GetMonitor(Index: Integer): TMonitor;
    function GetMonitorCount: Integer;
    function GetPrimaryMonitor: TMonitor;
    function GetWidth : Integer;
    procedure AddForm(AForm: TCustomForm);
    procedure RemoveForm(AForm: TCustomForm);
    procedure SetCursor(const AValue: TCursor);
    procedure SetCursors(AIndex: Integer; const AValue: HCURSOR);
    procedure SetHintFont(const AValue: TFont);
    procedure SetIconFont(const AValue: TFont);
    procedure SetMenuFont(const AValue: TFont);
    procedure SetSystemFont(const AValue: TFont);
    procedure UpdateLastActive;
    procedure UpdateMonitors;
    procedure RestoreLastActive;
    procedure AddHandler(HandlerType: TScreenNotification;
                         const Handler: TMethod; AsLast: Boolean);
    procedure RemoveHandler(HandlerType: TScreenNotification;
                            const Handler: TMethod);
    procedure DoAddDataModule(DataModule: TDataModule);
    procedure DoRemoveDataModule(DataModule: TDataModule);
  protected
    function GetHintFont: TFont; virtual;
    function GetIconFont: TFont; virtual;
    function GetMenuFont: TFont; virtual;
    function GetSystemFont: TFont; virtual;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    function CustomFormIndex(AForm: TCustomForm): integer;
    function FormIndex(AForm: TForm): integer;
    function CustomFormZIndex(AForm: TCustomForm): integer;
    procedure MoveFormToFocusFront(ACustomForm: TCustomForm);
    procedure MoveFormToZFront(ACustomForm: TCustomForm);
    function GetCurrentModalForm: TCustomForm;
    function GetCurrentModalFormZIndex: Integer;
    function CustomFormBelongsToActiveGroup(AForm: TCustomForm): Boolean;
    function FindForm(const FormName: string): TCustomForm;
    function FindDataModule(const DataModuleName: string): TDataModule;
    procedure UpdateScreen;
    // handler
    procedure AddHandlerFormAdded(OnFormAdded: TScreenFormEvent;
                                  AsLast: Boolean=true);
    procedure RemoveHandlerFormAdded(OnFormAdded: TScreenFormEvent);
    procedure AddHandlerRemoveForm(OnRemoveForm: TScreenFormEvent;
                                   AsLast: Boolean=true);
    procedure RemoveHandlerRemoveForm(OnRemoveForm: TScreenFormEvent);
    procedure AddHandlerActiveControlChanged(
                                    OnActiveControlChanged: TScreenControlEvent;
                                    AsLast: Boolean=true);
    procedure RemoveHandlerActiveControlChanged(
                                   OnActiveControlChanged: TScreenControlEvent);
    procedure AddHandlerActiveFormChanged(
                             OnActiveFormChanged: TScreenActiveFormChangedEvent;
                             AsLast: Boolean=true);
    procedure RemoveHandlerActiveFormChanged(
                            OnActiveFormChanged: TScreenActiveFormChangedEvent);
    procedure RemoveAllHandlersOfObject(AnObject: TObject); override;

    function DisableForms(SkipForm: TCustomForm; DisabledList: TList = nil): TList;
    procedure EnableForms(var AFormList: TList);
    function MonitorFromPoint(const Point: TPoint;
      MonitorDefault: TMonitorDefaultTo = mdNearest): TMonitor;
    function MonitorFromRect(const Rect: TRect;
      MonitorDefault: TMonitorDefaultTo = mdNearest): TMonitor;
    function MonitorFromWindow(const Handle: THandle;
      MonitorDefault: TMonitorDefaultTo = mdNearest): TMonitor;
  public
    property ActiveControl: TWinControl read FActiveControl;
    property ActiveCustomForm: TCustomForm read FActiveCustomForm;
    property ActiveForm: TForm read FActiveForm;
    property Cursor: TCursor read FCursor write SetCursor;
    property Cursors[Index: Integer]: HCURSOR read GetCursors write SetCursors;
    property CustomFormCount: Integer read GetCustomFormCount;
    property CustomForms[Index: Integer]: TCustomForm read GetCustomForms;
    property CustomFormZOrderCount: Integer read GetCustomFormZOrderCount;
    property CustomFormsZOrdered[Index: Integer]: TCustomForm
                                                    read GetCustomFormsZOrdered;
    property DesktopHeight: Integer read GetDesktopHeight;
    property DesktopWidth: Integer read GetDesktopWidth;
    property FocusedForm: TCustomForm read FFocusedForm;
    property FormCount: Integer read GetFormCount;
    property Forms[Index: Integer]: TForm read GetForms;
    property DataModuleCount: Integer read GetDataModuleCount;
    property DataModules[Index: Integer]: TDataModule read GetDataModules;
    
    property HintFont: TFont read GetHintFont write SetHintFont;
    property IconFont: TFont read GetIconFont write SetIconFont;
    property MenuFont: TFont read GetMenuFont write SetMenuFont;
    property SystemFont: TFont read GetSystemFont write SetSystemFont;
    property Fonts: TStrings read GetFonts;

    property Height: Integer read Getheight;
    property MonitorCount: Integer read GetMonitorCount;
    property Monitors[Index: Integer]: TMonitor read GetMonitor;
    property PixelsPerInch: integer read FPixelsPerInch;
    property PrimaryMonitor: TMonitor read GetPrimaryMonitor;
    property Width: Integer read GetWidth;
    property OnActiveControlChange: TNotifyEvent read FOnActiveControlChange
                                                 write FOnActiveControlChange;
    property OnActiveFormChange: TNotifyEvent read FOnActiveFormChange
                                              write FOnActiveFormChange;
  end;


  { TApplication }

  TQueryEndSessionEvent = procedure (var Cancel : Boolean) of object;
  TExceptionEvent = procedure (Sender: TObject; E: Exception) of object;
  TIdleEvent = procedure (Sender: TObject; var Done: Boolean) of object;
  TOnUserInputEvent = procedure(Sender: TObject; Msg: Cardinal) of object;
  TDataEvent = procedure (Data: PtrInt) of object;

  // application hint stuff
  TCMHintShow = record
    Msg: Cardinal;
    Reserved: WPARAM;
    HintInfo: PHintInfo;
    Result: LRESULT;
  end;

  TCMHintShowPause = record
    Msg: Cardinal;
    WasActive: Integer;
    Pause: PInteger;
    Result: LRESULT;
  end;

  TAppHintTimerType = (ahttNone, ahttShowHint, ahttHideHint, ahttReshowHint);

  TShowHintEvent = procedure (var HintStr: string; var CanShow: Boolean;
    var HintInfo: THintInfo) of object;

  THintInfoAtMouse = record
    MousePos: TPoint;
    Control: TControl;
    ControlHasHint: boolean;
  end;

  TApplicationFlag = (
    AppWaiting,
    AppIdleEndSent,
    AppHandlingException,
    AppNoExceptionMessages,
    AppActive, // application has focus
    AppDestroying,
    AppDoNotCallAsyncQueue,
    AppInitialized // initialization of application was done
    );
  TApplicationFlags = set of TApplicationFlag;

  TApplicationNavigationOption = (
    anoTabToSelectNext,
    anoReturnForDefaultControl,
    anoEscapeForCancelControl,
    anoF1ForHelp,
    anoArrowToSelectNextInParent
    );
  TApplicationNavigationOptions = set of TApplicationNavigationOption;

  TApplicationHandlerType = (
    ahtIdle,
    ahtIdleEnd,
    ahtKeyDownBefore, // before interface and LCL
    ahtKeyDownAfter,  // after interface and LCL
    ahtActivate,
    ahtDeactivate,
    ahtUserInput,
    ahtException,
    ahtEndSession,
    ahtQueryEndSession,
    ahtMinimize,
    ahtRestore,
    ahtDropFiles,
    ahtHelp,
    ahtHint,
    ahtShowHint
    );

  PAsyncCallQueueItem = ^TAsyncCallQueueItem;
  TAsyncCallQueueItem = record
    Method: TDataEvent;
    Data: PtrInt;
    NextItem: PAsyncCallQueueItem;
  end;
  
  TApplicationType = (
    atDefault,
    atDesktop,
    atHandheld,
    atPDA,
    atSmartphone
  );

  TApplicationShowGlyphs = (
    sbgAlways,  // show them always (default)
    sbgNever,   // show them never
    sbgSystem   // show them depending on OS
  );

  { TApplication }

  TApplication = class(TCustomApplication)
  private
    FApplicationHandlers: array[TApplicationHandlerType] of TMethodList;
    FApplicationType: TApplicationType;
    FCaptureExceptions: boolean;
    FComponentsToRelease: TAvgLvlTree;
    FCreatingForm: TForm;// currently created form (CreateForm), candidate for MainForm
    FFindGlobalComponentEnabled: boolean;
    FFlags: TApplicationFlags;
    FHint: string;
    FHintColor: TColor;
    FHintControl: TControl;
    FHintHidePause: Integer;
    FHintHidePausePerChar: Integer;
    FHintPause: Integer;
    FHintRect: TRect;
    FHintShortCuts: Boolean;
    FHintShortPause: Integer;
    FHintTimer: TCustomTimer;
    FHintTimerType: TAppHintTimerType;
    FHintWindow: THintWindow;
    FIcon: TIcon;
    FBigIconHandle: HICON;
    FShowButtonGlyphs: TApplicationShowGlyphs;
    FShowMenuGlyphs: TApplicationShowGlyphs;
    FSmallIconHandle: HICON;
    FIdleLockCount: Integer;
    FFormList: TList;
    FLastKeyDownSender: TWinControl;
    FLastKeyDownKey: Word;
    FLastKeyDownShift: TShiftState;
    FMainForm : TForm;
    FMouseControl: TControl;
    FNavigation: TApplicationNavigationOptions;
    FOldExceptProc: TExceptProc;
    FOldExitProc: Pointer;
    FOnActionExecute: TActionEvent;
    FOnActionUpdate: TActionEvent;
    FOnActivate: TNotifyEvent;
    FOnDeactivate: TNotifyEvent;
    FOnDestroy: TNotifyEvent;
    FOnDropFiles: TDropFilesEvent;
    FOnHelp: THelpEvent;
    FOnHint: TNotifyEvent;
    FOnIdle: TIdleEvent;
    FOnIdleEnd: TNotifyEvent;
    FOnEndSession : TNotifyEvent;
    FOnQueryEndSession : TQueryEndSessionEvent;
    FOnMinimize: TNotifyEvent;
    FOnRestore: TNotifyEvent;
    FOnShortcut: TShortcutEvent;
    FOnShowHint: TShowHintEvent;
    FOnUserInput: TOnUserInputEvent;
    FAsyncCallQueue: PAsyncCallQueueItem;
    FAsyncCallQueueLast: PAsyncCallQueueItem;
    FShowHint: Boolean;
    FShowMainForm: Boolean;
    FLastMousePos: TPoint;
    FLastMouseControl: TControl;
    FLastMouseControlValid: Boolean;
    FBidiMode: TBiDiMode;
    FRestoreStayOnTop: TList;
    procedure DoOnIdleEnd;
    function GetActive: boolean;
    function GetCurrentHelpFile: string;
    function GetExename: String;
    function GetTitle: string;
    procedure FreeIconHandles;
    procedure IconChanged(Sender: TObject);
    function GetControlAtMouse: TControl;
    procedure SetBidiMode ( const AValue : TBiDiMode ) ;
    procedure SetFlags(const AValue: TApplicationFlags);
    procedure SetNavigation(const AValue: TApplicationNavigationOptions);
    procedure SetShowButtonGlyphs(const AValue: TApplicationShowGlyphs);
    procedure SetShowMenuGlyphs(const AValue: TApplicationShowGlyphs);
    procedure UpdateMouseControl(NewMouseControl: TControl);
    procedure UpdateMouseHint(CurrentControl: TControl);
    procedure SetCaptureExceptions(const AValue: boolean);
    procedure SetHint(const AValue: string);
    procedure SetHintColor(const AValue: TColor);
    procedure SetIcon(AValue: TIcon);
    procedure SetShowHint(const AValue: Boolean);
    procedure StopHintTimer;
    function  ValidateHelpSystem: Boolean;
    procedure WndProc(var AMessage : TLMessage);
    function DispatchAction(Msg: Longint; Action: TBasicAction): Boolean;
    procedure AddHandler(HandlerType: TApplicationHandlerType;
                         const Handler: TMethod; AsLast: Boolean);
    procedure RemoveHandler(HandlerType: TApplicationHandlerType;
                            const Handler: TMethod);
    procedure RunLoop;
    procedure Activate;
    procedure Deactivate(Data: PtrInt = 0);
  protected
    function GetConsoleApplication: boolean; override;
    procedure NotifyIdleHandler(var Done: Boolean);
    procedure NotifyIdleEndHandler;
    procedure NotifyActivateHandler;
    procedure NotifyDeactivateHandler;
    procedure NotifyCustomForms(Msg: Word);
    function IsHintMsg(var Msg: TMsg): Boolean;
    function DoOnHelp(Command: Word; Data: PtrInt; var CallHelp: Boolean): Boolean; virtual;
    procedure DoOnMouseMove; virtual;
    procedure ShowHintWindow(const Info: THintInfoAtMouse);
    procedure OnHintTimer(Sender: TObject);
    procedure SetTitle(const AValue: String); override;
    procedure StartHintTimer(Interval: integer; TimerType: TAppHintTimerType);
    procedure UpdateVisible;
    procedure DoIdleActions;
    procedure MenuPopupHandler(Sender: TObject);
    procedure ProcessAsyncCallQueue;
    procedure FreeComponent(Data: PtrInt);
    procedure ReleaseComponents;
    procedure DoBeforeFinalization;
    function GetParams(Index: Integer): string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ControlDestroyed(AControl: TControl);
    function BigIconHandle: HIcon;
    function SmallIconHandle: HIcon;
    procedure BringToFront;
    procedure CreateForm(InstanceClass: TComponentClass; out Reference);
    procedure UpdateMainForm(AForm: TForm);
    procedure QueueAsyncCall(const AMethod: TDataEvent; Data: PtrInt);
    procedure ReleaseComponent(AComponent: TComponent);
    function ExecuteAction(ExeAction: TBasicAction): Boolean; override;
    function UpdateAction(TheAction: TBasicAction): Boolean; override;
    procedure HandleException(Sender: TObject); override;
    procedure HandleMessage;
    function HelpCommand(Command: Word; Data: PtrInt): Boolean;
    function HelpContext(Sender: TObject; const Position: TPoint;
                         Context: THelpContext): Boolean;
    function HelpContext(Context: THelpContext): Boolean;
    function HelpKeyword(Sender: TObject; const Position: TPoint;
                         const Keyword: String): Boolean;
    function HelpKeyword(const Keyword: String): Boolean;
    procedure ShowHelpForObject(Sender: TObject);
    procedure RemoveStayOnTop;
    procedure RestoreStayOnTop;
    function IsWaiting: boolean;
    procedure CancelHint;
    procedure HideHint;
    procedure HintMouseMessage(Control : TControl; var AMessage: TLMessage);
    procedure Initialize; override;
    function MessageBox(Text, Caption: PChar; Flags: Longint): Integer;
    procedure Minimize;
    procedure Restore;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure ProcessMessages;
    procedure Idle(Wait: Boolean);
    procedure Run;
    procedure ShowException(E: Exception); override;
    procedure Terminate; override;
    procedure DisableIdleHandler;
    procedure EnableIdleHandler;
    procedure NotifyUserInputHandler(Msg: Cardinal);
    procedure NotifyKeyDownBeforeHandler(Sender: TObject;
                                         var Key: Word; Shift: TShiftState);
    procedure NotifyKeyDownHandler(Sender: TObject;
                                   var Key: Word; Shift: TShiftState);
    procedure ControlKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ControlKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AddOnIdleHandler(Handler: TIdleEvent; AsLast: Boolean=true);
    procedure RemoveOnIdleHandler(Handler: TIdleEvent);
    procedure AddOnIdleEndHandler(Handler: TNotifyEvent; AsLast: Boolean=true);
    procedure RemoveOnIdleEndHandler(Handler: TNotifyEvent);
    procedure AddOnUserInputHandler(Handler: TOnUserInputEvent;
                                    AsLast: Boolean=true);
    procedure RemoveOnUserInputHandler(Handler: TOnUserInputEvent);
    procedure AddOnKeyDownBeforeHandler(Handler: TKeyEvent;
                                        AsLast: Boolean=true);
    procedure RemoveOnKeyDownBeforeHandler(Handler: TKeyEvent);
    procedure AddOnKeyDownHandler(Handler: TKeyEvent; AsLast: Boolean=true);
    procedure RemoveOnKeyDownHandler(Handler: TKeyEvent);
    procedure AddOnActivateHandler(Handler: TNotifyEvent; AsLast: Boolean=true);
    procedure RemoveOnActivateHandler(Handler: TNotifyEvent);
    procedure AddOnDeactivateHandler(Handler: TNotifyEvent; AsLast: Boolean=true);
    procedure RemoveOnDeactivateHandler(Handler: TNotifyEvent);
    procedure AddOnExceptionHandler(Handler: TExceptionEvent; AsLast: Boolean=true);
    procedure RemoveOnExceptionHandler(Handler: TExceptionEvent);
    procedure AddOnEndSessionHandler(Handler: TNotifyEvent; AsLast: Boolean=true);
    procedure RemoveOnEndSessionHandler(Handler: TNotifyEvent);
    procedure AddOnQueryEndSessionHandler(Handler: TQueryEndSessionEvent; AsLast: Boolean=true);
    procedure RemoveOnQueryEndSessionHandler(Handler: TQueryEndSessionEvent);
    procedure AddOnMinimizeHandler(Handler: TNotifyEvent; AsLast: Boolean=true);
    procedure RemoveOnMinimizeHandler(Handler: TNotifyEvent);
    procedure AddOnRestoreHandler(Handler: TNotifyEvent; AsLast: Boolean=true);
    procedure RemoveOnRestoreHandler(Handler: TNotifyEvent);
    procedure AddOnDropFilesHandler(Handler: TDropFilesEvent; AsLast: Boolean=true);
    procedure RemoveOnDropFilesHandler(Handler: TDropFilesEvent);
    procedure AddOnHelpHandler(Handler: THelpEvent; AsLast: Boolean=true);
    procedure RemoveOnHelpHandler(Handler: THelpEvent);
    procedure AddOnHintHandler(Handler: TNotifyEvent; AsLast: Boolean=true);
    procedure RemoveOnHintHandler(Handler: TNotifyEvent);
    procedure AddOnShowHintHandler(Handler: TShowHintEvent; AsLast: Boolean=true);
    procedure RemoveOnShowHintHandler(Handler: TShowHintEvent);
    procedure RemoveAllHandlersOfObject(AnObject: TObject); virtual;
    procedure DoBeforeMouseMessage(CurMouseControl: TControl);
    function  IsShortcut(var Message: TLMKey): boolean;
    procedure IntfQueryEndSession(var Cancel : Boolean);
    procedure IntfEndSession;
    procedure IntfAppMinimize;
    procedure IntfAppRestore;
    procedure IntfDropFiles(const FileNames: Array of String);
    procedure IntfThemeOptionChange(AThemeServices: TThemeServices; AOption: TThemeOption);
  public
    procedure DoArrowKey(AControl: TWinControl; var Key: Word;
      Shift: TShiftState);
    procedure DoEscapeKey(AControl: TWinControl; var Key: Word;
      Shift: TShiftState);
    procedure DoReturnKey(AControl: TWinControl; var Key: Word;
      Shift: TShiftState);
    procedure DoTabKey(AControl: TWinControl; var Key: Word;
      Shift: TShiftState);

    property Active: boolean read GetActive;
    property ApplicationType : TApplicationType read FApplicationType write FApplicationType;
    property BidiMode: TBiDiMode read FBidiMode write SetBidiMode;
    property CaptureExceptions: boolean read FCaptureExceptions
                                        write SetCaptureExceptions;
    property FindGlobalComponentEnabled: boolean read FFindGlobalComponentEnabled
                                               write FFindGlobalComponentEnabled;
    property Flags: TApplicationFlags read FFlags write SetFlags;
    //property HelpSystem : IHelpSystem read FHelpSystem;
    property Hint: string read FHint write SetHint;
    property HintColor: TColor read FHintColor write SetHintColor;
    property HintHidePause: Integer read FHintHidePause write FHintHidePause;
    property HintHidePausePerChar: Integer read FHintHidePausePerChar write FHintHidePausePerChar;
    property HintPause: Integer read FHintPause write FHintPause;
    property HintShortCuts: Boolean read FHintShortCuts write FHintShortCuts;
    property HintShortPause: Integer read FHintShortPause write FHintShortPause;
    property Icon: TIcon read FIcon write SetIcon;
    property Navigation: TApplicationNavigationOptions read FNavigation write SetNavigation;
    property MainForm: TForm read FMainForm;
    property MouseControl: TControl read FMouseControl;
    property OnActionExecute: TActionEvent read FOnActionExecute write FOnActionExecute;
    property OnActionUpdate: TActionEvent read FOnActionUpdate write FOnActionUpdate;
    property OnActivate: TNotifyEvent read FOnActivate write FOnActivate;
    property OnDeactivate: TNotifyEvent read FOnDeactivate write FOnDeactivate;
    property OnIdle: TIdleEvent read FOnIdle write FOnIdle;
    property OnIdleEnd: TNotifyEvent read FOnIdleEnd write FOnIdleEnd;
    property OnEndSession: TNotifyEvent read FOnEndSession write FOnEndSession;
    property OnQueryEndSession: TQueryEndSessionEvent read FOnQueryEndSession write FOnQueryEndSession;
    property OnMinimize: TNotifyEvent read FOnMinimize write FOnMinimize;
    property OnRestore: TNotifyEvent read FOnRestore write FOnRestore;
    property OnDropFiles: TDropFilesEvent read FOnDropFiles write FOnDropFiles;
    property OnHelp: THelpEvent read FOnHelp write FOnHelp;
    property OnHint: TNotifyEvent read FOnHint write FOnHint;
    property OnShortcut: TShortcutEvent read FOnShortcut write FOnShortcut;
    property OnShowHint: TShowHintEvent read FOnShowHint write FOnShowHint;
    property OnUserInput: TOnUserInputEvent read FOnUserInput write FOnUserInput;
    property OnDestroy: TNotifyEvent read FOnDestroy write FOnDestroy;
    property ShowButtonGlyphs: TApplicationShowGlyphs read FShowButtonGlyphs write SetShowButtonGlyphs default sbgAlways;
    property ShowMenuGlyphs: TApplicationShowGlyphs read FShowMenuGlyphs write SetShowMenuGlyphs default sbgAlways;
    property ShowHint: Boolean read FShowHint write SetShowHint;
    property ShowMainForm: Boolean read FShowMainForm write FShowMainForm default True;
    property Title: String read GetTitle write SetTitle;
  end;

const
  DefHintColor = clInfoBk;           // default hint window color
  DefHintPause = 500;                // default pause before hint window displays (ms)
  DefHintShortPause = 0;             // default reshow pause
  DefHintHidePause = 5*DefHintPause; // default pause before hint is hidden (ms)
  DefHintHidePausePerChar = 200;     // added to DefHintHidePause (ms)

type
  { TApplicationProperties }

  TApplicationProperties = class(TLCLComponent)
  private
    FCaptureExceptions: boolean;
    FHelpFile: string;
    FHint: string;
    FHintColor: TColor;
    FHintHidePause: Integer;
    FHintPause: Integer;
    FHintShortCuts: Boolean;
    FHintShortPause: Integer;
    FOnDropFiles: TDropFilesEvent;
    FShowButtonGlyphs: TApplicationShowGlyphs;
    FShowHint: Boolean;
    FShowMainForm: Boolean;
    FShowMenuGlyphs: TApplicationShowGlyphs;
    FTitle: String;

    FOnException: TExceptionEvent;
    FOnIdle: TIdleEvent;
    FOnIdleEnd: TNotifyEvent;
    FOnHelp: THelpEvent;
    FOnHint: TNotifyEvent;
    FOnShowHint: TShowHintEvent;
    FOnUserInput: TOnUserInputEvent;
    FOnEndSession : TNotifyEvent;
    FOnQueryEndSession : TQueryEndSessionEvent;
    FOnMinimize : TNotifyEvent;
    FOnRestore : TNotifyEvent;
  protected
    procedure SetCaptureExceptions(const AValue : boolean);
    procedure SetHelpFile(const AValue : string);
    procedure SetHint(const AValue : string);
    procedure SetHintColor(const AValue : TColor);
    procedure SetHintHidePause(const AValue : Integer);
    procedure SetHintPause(const AValue : Integer);
    procedure SetHintShortCuts(const AValue : Boolean);
    procedure SetHintShortPause(const AValue : Integer);
    procedure SetShowButtonGlyphs(const AValue: TApplicationShowGlyphs);
    procedure SetShowMenuGlyphs(const AValue: TApplicationShowGlyphs);
    procedure SetShowHint(const AValue : Boolean);
    procedure SetShowMainForm(const AValue: Boolean);
    procedure SetTitle(const AValue : String);

    procedure SetOnException(const AValue : TExceptionEvent);
    procedure SetOnIdle(const AValue : TIdleEvent);
    procedure SetOnIdleEnd(const AValue : TNotifyEvent);
    procedure SetOnEndSession(const AValue : TNotifyEvent);
    procedure SetOnQueryEndSession(const AValue : TQueryEndSessionEvent);
    procedure SetOnMinimize(const AValue : TNotifyEvent);
    procedure SetOnRestore(const AValue : TNotifyEvent);
    procedure SetOnDropFiles(const AValue: TDropFilesEvent);
    procedure SetOnHelp(const AValue : THelpEvent);
    procedure SetOnHint(const AValue : TNotifyEvent);
    procedure SetOnShowHint(const AValue : TShowHintEvent);
    procedure SetOnUserInput(const AValue : TOnUserInputEvent);
  public
    constructor Create(AOwner: TComponent); Override;
    destructor Destroy; override;
  published
    property CaptureExceptions: boolean read FCaptureExceptions
                                        write SetCaptureExceptions default True;
    property HelpFile: string read FHelpFile write SetHelpFile;
    property Hint: string read FHint write SetHint;
    property HintColor: TColor read FHintColor write SetHintColor default DefHintColor;
    property HintHidePause: Integer read FHintHidePause write SetHintHidePause default DefHintHidePause;
    property HintPause: Integer read FHintPause write SetHintPause default DefHintPause;
    property HintShortCuts: Boolean read FHintShortCuts write SetHintShortCuts default True;
    property HintShortPause: Integer read FHintShortPause write SetHintShortPause default DefHintShortPause;
    property ShowButtonGlyphs: TApplicationShowGlyphs read FShowButtonGlyphs write SetShowButtonGlyphs default sbgAlways;
    property ShowMenuGlyphs: TApplicationShowGlyphs read FShowMenuGlyphs write SetShowMenuGlyphs default sbgAlways;
    property ShowHint: Boolean read FShowHint write SetShowHint default True;
    property ShowMainForm: Boolean read FShowMainForm write SetShowMainForm default True;
    property Title: String read FTitle write SetTitle;

    property OnException: TExceptionEvent read FOnException write SetOnException;
    property OnIdle: TIdleEvent read FOnIdle write SetOnIdle;
    property OnIdleEnd: TNotifyEvent read FOnIdleEnd write SetOnIdleEnd;
    property OnEndSession : TNotifyEvent read FOnEndSession write SetOnEndSession;
    property OnQueryEndSession : TQueryEndSessionEvent read FOnQueryEndSession write SetOnQueryEndSession;
    property OnMinimize : TNotifyEvent read FOnMinimize write SetOnMinimize;
    property OnRestore : TNotifyEvent read FOnRestore write SetOnRestore;
    property OnDropFiles: TDropFilesEvent read FOnDropFiles write SetOnDropFiles;
    property OnHelp: THelpEvent read FOnHelp write SetOnHelp;
    property OnHint: TNotifyEvent read FOnHint write SetOnHint;
    property OnShowHint: TShowHintEvent read FOnShowHint write SetOnShowHint;
    property OnUserInput: TOnUserInputEvent read FOnUserInput write SetOnUserInput;
  end;


  { TIDesigner }

  TIDesigner = class(TObject)
  public
    function IsDesignMsg(Sender: TControl; var Message: TLMessage): Boolean;
      virtual; abstract;
    procedure Modified; virtual; abstract;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); virtual; abstract;
    procedure PaintGrid; virtual; abstract;
    procedure ValidateRename(AComponent: TComponent;
      const CurName, NewName: string); virtual; abstract;
    function GetShiftState: TShiftState; virtual; abstract;
    procedure SelectOnlyThisComponent(AComponent: TComponent); virtual; abstract;
    function UniqueName(const BaseName: string): string; virtual; abstract;
  end;


  { TFormPropertyStorage - abstract base class }

  TFormPropertyStorage = class(TControlPropertyStorage)
  private
    procedure FormFirstShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

function KeysToShiftState(Keys: PtrUInt): TShiftState;
function KeyDataToShiftState(KeyData: Longint): TShiftState;
function ShiftStateToKeys(ShiftState: TShiftState): PtrUInt;

function WindowStateToStr(const State: TWindowState): string;
function StrToWindowState(const Name: string): TWindowState;

type
  TFocusState = Pointer;

function SaveFocusState: TFocusState;
procedure RestoreFocusState(FocusState: TFocusState);

type
  TGetDesignerFormEvent =
    function(AComponent: TComponent): TCustomForm of object;

var
  OnGetDesignerForm: TGetDesignerFormEvent = nil;

function GetParentForm(Control:TControl): TCustomForm;
function GetFirstParentForm(Control:TControl): TCustomForm;
function GetDesignerForm(AComponent: TComponent): TCustomForm;
function FindRootDesigner(AComponent: TComponent): TIDesigner;

function IsAccel(VK: word; const Str: string): Boolean;
procedure NotifyApplicationUserInput(Msg: Cardinal);


function GetShortHint(const Hint: string): string;
function GetLongHint(const Hint: string): string;


var
  Application: TApplication = nil;
  Screen: TScreen = nil;
  ExceptionObject: TExceptObject;
  HintWindowClass: THintWindowClass = THintWindow;

type
  TMessageBoxFunction =
    function(Text, Caption : PChar; Flags : Longint) : Integer;
var
  MessageBoxFunction: TMessageBoxFunction = nil;

const
  DefaultBorderIcons : array[TFormBorderStyle] of TBorderIcons =
    ([],                                        // bsNone
     [biSystemMenu, biMinimize],                // bsSingle
     [biSystemMenu, biMinimize, biMaximize],    // bsSizeable
     [biSystemMenu],                            // bsDialog
     [biSystemMenu, biMinimize],                // bsToolWindow
     [biSystemMenu, biMinimize, biMaximize]);   // bsSizeToolWin
     

procedure CreateWidgetset(AWidgetsetClass: TWidgetsetClass);
procedure FreeWidgetSet;

procedure Register;


implementation

{$ifdef WinCE}
  {$define extdecl := cdecl}
{$else}
  {$define extdecl := stdcall}
{$endif}

uses
  WSForms; // Widgetset uses circle is allowed

var
  FocusCount: Integer=0;
  HandlingException: boolean=False;
  HaltingProgram: boolean=False;

procedure Register;
begin
  RegisterComponents('Standard',[TFrame]);
  RegisterComponents('Additional',[TScrollBox, TApplicationProperties]);
end;

{------------------------------------------------------------------------------
  procedure NotifyApplicationUserInput;

 ------------------------------------------------------------------------------}
procedure NotifyApplicationUserInput(Msg: Cardinal);
begin
  if Application <> nil then
    Application.NotifyUserInputHandler(Msg);
end;


//------------------------------------------------------------------------------
procedure ExceptionOccurred(Sender: TObject; Addr:Pointer; FrameCount: Longint;
  Frames: PPointer);
var
  FrameNumber: integer;
Begin
  DebugLn('[FORMS.PP] ExceptionOccurred ');
  if HaltingProgram or HandlingException then Halt;
  HandlingException:=true;
  if Sender<>nil then begin
    DebugLn('  Sender=',Sender.ClassName);
    if Sender is Exception then begin
      DebugLn('  Exception=',Exception(Sender).Message);
      DebugLn('  Stack trace:');
      DebugLn(BackTraceStrFunc(ExceptAddr));
      for FrameNumber := 0 to FrameCount-1 do
        DebugLn(BackTraceStrFunc(Frames[FrameNumber]));
    end;
  end else
    DebugLn('  Sender=nil');
  if Application<>nil then
    Application.HandleException(Sender);
  HandlingException:=false;
end;

procedure BeforeFinalization;
// This is our ExitProc handler.
begin
  Application.DoBeforeFinalization;
end;

//------------------------------------------------------------------------------
// The focus state is just the focus count for now. To save having to allocate
// anything, I just map the Integer to the TFocusState.
function SaveFocusState: TFocusState;
begin
  Result := TFocusState(PtrInt(FocusCount));
end;

procedure RestoreFocusState(FocusState: TFocusState);
begin
  FocusCount := integer(PtrUInt(FocusState));
end;

{function SendFocusMessage(Window: HWnd; Msg: Word): Boolean;
var
  Count: Integer;
begin
  Count := FocusCount;
  SendMessage(Window, Msg, 0, 0);
  Result := (FocusCount = Count);
end;}

//------------------------------------------------------------------------------
function KeysToShiftState(Keys: PtrUInt): TShiftState;
begin
  Result := [];
  if Keys and MK_Shift <> 0 then Include(Result, ssShift);
  if Keys and MK_Control <> 0 then Include(Result, ssCtrl);
  if Keys and MK_LButton <> 0 then Include(Result, ssLeft);
  if Keys and MK_RButton <> 0 then Include(Result, ssRight);
  if Keys and MK_MButton <> 0 then Include(Result, ssMiddle);
  if Keys and MK_XBUTTON1 <> 0 then Include(Result, ssExtra1);
  if Keys and MK_XBUTTON2 <> 0 then Include(Result, ssExtra2);
  if GetKeyState(VK_MENU) < 0 then Include(Result, ssAlt);
end;

function KeyDataToShiftState(KeyData: Longint): TShiftState;
begin
  Result := MsgKeyDataToShiftState(KeyData);
end;

function ShiftStateToKeys(ShiftState: TShiftState): PtrUInt;
begin
  Result := 0;
  if ssShift  in ShiftState then Result := Result or MK_SHIFT;
  if ssCtrl   in ShiftState then Result := Result or MK_CONTROL;
  if ssLeft   in ShiftState then Result := Result or MK_LBUTTON;
  if ssRight  in ShiftState then Result := Result or MK_RBUTTON;
  if ssMiddle in ShiftState then Result := Result or MK_MBUTTON;
  if ssExtra1 in ShiftState then Result := Result or MK_XBUTTON1;
  if ssExtra2 in ShiftState then Result := Result or MK_XBUTTON2;
end;

function WindowStateToStr(const State: TWindowState): string;
begin
  Result:=GetEnumName(TypeInfo(TWindowState),ord(State));
end;

function StrToWindowState(const Name: string): TWindowState;
begin
  Result:=TWindowState(GetEnumValueDef(TypeInfo(TWindowState),Name,
                                       ord(wsNormal)));
end;

//------------------------------------------------------------------------------
function GetParentForm(Control: TControl): TCustomForm;
begin
  while Control.Parent <> nil do
    Control := Control.Parent;
  if Control is TCustomForm
  then Result := TCustomForm(Control)
  else Result := nil;
end;

//------------------------------------------------------------------------------
function IsAccel(VK: word; const Str: string): Boolean;
var
  lPos: integer;
begin
  lPos:=1;
  while (lPos<length(Str)) do begin
    if Str[lPos]<>'&' then begin
      inc(lPos);
    end else begin
      inc(lPos);
      if (Str[lPos]<>'&') then begin
        Result := UpCase(Str[lPos]) = UpCase(char(VK));
        exit;
      end else begin
        // skip double &&
        inc(lPos);
      end;
    end;
  end;
  Result := false;
end;

//==============================================================================

function FindRootDesigner(AComponent: TComponent): TIDesigner;
var
  Form: TCustomForm;
begin
  Result:=nil;
  Form:=GetDesignerForm(AComponent);
  if Form<>nil then
    Result:=Form.Designer;
end;

function GetFirstParentForm(Control: TControl): TCustomForm;
begin
  while (Control<>nil) and (not (Control is TCustomForm)) do
    Control:=Control.Parent;
  Result:=TCustomForm(Control);
end;

function GetDesignerForm(AComponent: TComponent): TCustomForm;
var
  OwnerComponent: TComponent;
begin
  Result:=nil;
  if AComponent=nil then exit;
  if Assigned(OnGetDesignerForm) then
    Result:=OnGetDesignerForm(AComponent)
  else begin
    OwnerComponent:=AComponent;
    while OwnerComponent.Owner<>nil do OwnerComponent:=OwnerComponent.Owner;
    if OwnerComponent is TCustomForm then Result:=TCustomForm(OwnerComponent);
  end;
end;

function SendApplicationMsg(Msg: Cardinal; WParam: WParam; LParam: LParam): Longint;
var
  AMessage: TLMessage;
begin
  if Application<>nil then begin
    AMessage.Msg := Msg;
    AMessage.WParam := WParam;
    AMessage.LParam := LParam;
    { Can't simply use SendMessage, as the Application does not necessarily have a handle }
    Application.WndProc(AMessage);
    Result := AMessage.Result;
  end else
    Result := 0;
end;

procedure IfOwnerIsFormThenDesignerModified(AComponent: TComponent);
begin
  if (AComponent<>nil) and (AComponent.Owner<>nil)
  and ([csDesigning,csLoading]*AComponent.ComponentState=[csDesigning])
  and (AComponent.Owner is TForm)
  and (TForm(AComponent.Owner).Designer <> nil) then
    TForm(AComponent.Owner).Designer.Modified;
end;

function GetShortHint(const Hint: string): string;
var
  I: Integer;
begin
  I := Pos('|', Hint);
  if I = 0 then
    Result := Hint else
    Result := Copy(Hint, 1, I - 1);
end;

function GetLongHint(const Hint: string): string;
var
  I: Integer;
begin
  I := Pos('|', Hint);
  if I = 0 then
    Result := Hint else
    Result := Copy(Hint, I + 1, Maxint);
end;

procedure CreateWidgetset(AWidgetsetClass: TWidgetsetClass);
begin
  //debugln('CreateWidgetset');
  CallInterfaceInitializationHandlers;
  WidgetSet := AWidgetsetClass.Create;
end;

procedure FreeWidgetSet;
begin
  //debugln('FreeWidgetSet');
  if Screen <> nil then
  begin
    Screen.DestroyCursors;
    Screen.DestroyMonitors;
  end;
  Application.Free;
  Application:=nil;
  FreeAllClipBoards;
  CallInterfaceFinalizationHandlers;
  WidgetSet.Free;
  WidgetSet:=nil;
end;


//==============================================================================

{$I controlscrollbar.inc}
{$I scrollingwincontrol.inc}
{$I scrollbox.inc}
{$I customframe.inc}
{$I customform.inc}
{$I customdockform.inc}
{$I monitor.inc}
{$I screen.inc}
{$I application.inc}
{$I applicationproperties.inc}
{$I hintwindow.inc}


//==============================================================================

initialization
  {$INCLUDE cursors.lrs}
  RegisterPropertyToSkip(TForm, 'OldCreateOrder', 'VCL compatibility property', '');
  LCLProc.OwnerFormDesignerModifiedProc:=@IfOwnerIsFormThenDesignerModified;
  Screen:=TScreen.Create(nil);
  Application:=TApplication.Create(nil);

finalization
  //DebugLn('forms.pp - finalization section');
  LCLProc.OwnerFormDesignerModifiedProc:=nil;
  HintWindowClass:=nil;
  FreeThenNil(Application);
  FreeThenNil(Screen);

end.



