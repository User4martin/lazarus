{
 *****************************************************************************
 *                               gtk3widgets.pas                             *
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

unit gtk3widgets;
{$i gtk3defines.inc}
{$mode objfpc}
{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Dialogs, Forms, StdCtrls, ComCtrls, Menus,
  types,
  LCLType, LCLProc, LMessages, LCLMessageGlue, LCLIntf,
  LazGtk3, LazGdk3, LazGObject2, LazGLib2, LazCairo1, LazPango1, LazGdkPixbuf2,
  gtk3objects;

type
  TByteSet = set of byte;

  // records
  TPaintData = record
    PaintWidget: PGtkWidget;
    ClipRect: PRect;
    ClipRegion: Pcairo_region_t;
  end;

  TDefaultRGBA = record
    R: Double;
    G: Double;
    B: Double;
    Alpha: Double;
  end;

  TGtk3WidgetType = (wtWidget, wtStaticText, wtProgressBar, wtLayout,
    wtContainer, wtMenuBar, wtMenu, wtMenuItem, wtEntry, wtSpinEdit,
    wtNotebook, wtComboBox,
    wtGroupBox, wtCalendar, wtTrackBar, wtScrollBar,
    wtScrollingWin, wtListBox, wtListView, wtCheckListBox, wtMemo, wtTreeModel,
    wtCustomControl, wtScrollingWinControl,
    wtWindow, wtDialog, wtHintWindow);
  TGtk3WidgetTypes = set of TGtk3WidgetType;

  { TGtk3Widget }

  TGtk3Widget = class(TGtk3Object, IUnknown)
  private
    FFocusableByMouse: Boolean; {shell we call SetFocus on mouse down. Default = False}
    FEnterLeaveTime: Cardinal;
    FHasPaint: Boolean;
    FKeysToEat: TByteSet;
    FPaintData: TPaintData;
    FContext: HDC;
    FCairoContext: Pcairo_t;
    FWidgetType: TGtk3WidgetTypes;
    FParams: TCreateParams;
    FOwnWidget: Boolean;
    FOwner: PGtkWidget;
    FCentralWidget: PGtkWidget;
    FWidget: PGtkWidget;
    FProps: TStringList;
    FWidgetRGBA: array [0{GTK_STATE_NORMAL}..4{GTK_STATE_INSENSITIVE}] of TDefaultRGBA;
    FCentralWidgetRGBA: array [0{GTK_STATE_NORMAL}..4{GTK_STATE_INSENSITIVE}] of TDefaultRGBA;

    function CanSendLCLMessage: Boolean;
    function GetCairoContext: Pcairo_t;
    function GetEnabled: Boolean;
    function GetFont: PPangoFontDescription;
    function GetStyleContext: PGtkStyleContext;
    function GetVisible: Boolean;
    procedure SetEnabled(AValue: Boolean);
    procedure SetFont(AValue: PPangoFontDescription);
    procedure SetVisible(AValue: Boolean);
    procedure SetStyleContext(AValue: PGtkStyleContext);
  protected
    // IUnknown implementation
    function QueryInterface(constref iid: TGuid; out obj): LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
    function _AddRef: LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
    function _Release: LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
    function EatArrowKeys(const AKey: Word): Boolean; virtual;
    function getText: String; virtual;
    procedure setText(AValue: String); virtual;
    function GetContext: HDC; virtual;
    function CreateWidget(const Params: TCreateParams):PGtkWidget; virtual;
    procedure DestroyWidget; virtual;
    procedure DoBeforeLCLPaint; virtual;

    function GetColor: TColor; virtual;
    procedure SetColor(AValue: TColor); virtual;
    function GetFontColor: TColor; virtual;
    procedure SetFontColor(AValue: TColor); virtual;
  public
    LCLObject: TWinControl;
  public
    constructor Create(const AWinControl: TWinControl; const AParams: TCreateParams); virtual; overload;
    constructor CreateFrom(const AWinControl: TWinControl; AWidget: PGtkWidget); virtual;

    procedure InitializeWidget; virtual;
    procedure DeInitializeWidget;
    procedure RecreateWidget;
    procedure DestroyNotify(AWidget: PGtkWidget); virtual;
    destructor Destroy; override;

    function CanFocus: Boolean; virtual;
    function GetFocusableByMouse: Boolean;
    function getClientOffset: TPoint; virtual;
    function getWidgetPos: TPoint; virtual;

    procedure OffsetMousePos(APoint: PPoint); virtual;

    function DeliverMessage(var Msg; const AIsInputEvent: Boolean = False): LRESULT; virtual;
    function GtkEventMouseEnterLeave(Sender: PGtkWidget; Event: PGdkEvent): Boolean; virtual; cdecl;
    function GtkEventKey(Sender: PGtkWidget; Event: PGdkEvent; AKeyPress: Boolean): Boolean; virtual; cdecl;
    function GtkEventMouse(Sender: PGtkWidget; Event: PGdkEvent): Boolean; virtual; cdecl;
    function GtkEventMouseMove(Sender: PGtkWidget; Event: PGdkEvent): Boolean; virtual; cdecl;
    function GtkEventPaint(Sender: PGtkWidget; AContext: Pcairo_t): Boolean; virtual; cdecl;
    function GtkEventResize(Sender: PGtkWidget; Event: PGdkEvent): Boolean; virtual; cdecl;
    procedure GtkEventFocus(Sender: PGtkWidget; Event: PGdkEvent); cdecl;
    procedure GtkEventDestroy; cdecl;
    function GtkEventMouseWheel(Sender: PGtkWidget; Event: PGdkEvent): Boolean; virtual; cdecl;

    function IsValidHandle: Boolean;
    function IsWidgetOk: Boolean; virtual;
    function IsIconic: Boolean; virtual;

    function getType: TGType;
    function getTypeName: PgChar;

    procedure lowerWidget; virtual;
    procedure raiseWidget; virtual;
    procedure stackUnder(AWidget: PGtkWidget); virtual;

    function GetCapture: TGtk3Widget; virtual;
    function SetCapture: HWND; virtual;

    function getClientRect: TRect; virtual;
    function getClientBounds: TRect; virtual;
    function GetContainerWidget: PGtkWidget; virtual;
    function GetPosition(out APoint: TPoint): Boolean; virtual;
    procedure Release; override;
    procedure Hide; virtual;
    function getParent: TGtk3Widget;
    function GetWindow: PGdkWindow; virtual;
    procedure Move(ALeft, ATop: Integer);
    procedure Activate; virtual;
    procedure preferredSize(var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); virtual;
    procedure SetCursor(ACursor: HCURSOR);
    procedure SetFocus; virtual;
    procedure SetParent(AParent: TGtk3Widget; const ALeft, ATop: Integer); virtual;
    procedure Show; virtual;
    procedure ShowAll; virtual;
    procedure Update(ARect: PRect);
    property CairoContext: Pcairo_t read GetCairoContext;
    property Color: TColor read GetColor write SetColor;
    property Context: HDC read GetContext;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property Font: PPangoFontDescription read GetFont write SetFont;
    property FontColor: TColor read GetFontColor write SetFontColor;
    property KeysToEat: TByteSet read FKeysToEat write FKeysToEat;
    property PaintData: TPaintData read FPaintData write FPaintData;
    property StyleContext: PGtkStyleContext read GetStyleContext write SetStyleContext;
    property Text: String read getText write setText;
    property Visible: Boolean read GetVisible write SetVisible;
    property Widget: PGtkWidget read FWidget;
    property WidgetType: TGtk3WidgetTypes read FWidgetType;
  end;

  { TGtk3Editable }

  TGtk3Editable = class(TGtk3Widget)
  private
    function GetReadOnly: Boolean;
    procedure SetReadOnly(AValue: Boolean);
  protected
    PrivateCursorPos: Integer; // used only for delayed selStart and selLength
    PrivateSelection: Integer;
    function getCaretPos: TPoint; virtual;
    procedure SetCaretPos(AValue: TPoint); virtual;
  public
    function getSelStart: Integer; virtual;
    function getSelLength: Integer; virtual;
    procedure setSelStart(AValue: Integer); virtual;
    procedure setSelLength(AValue: Integer); virtual;
    property CaretPos: TPoint read GetCaretPos write SetCaretPos;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly;
  end;

  { TGtk3Entry }

  TGtk3Entry = class(TGtk3Editable)
  private
    function GetAlignment: TAlignment;
    procedure SetAlignment(AValue: TAlignment);
  protected
    function EatArrowKeys(const AKey: Word): Boolean; override;
    function getText: String; override;
    procedure setText(AValue: String); override;
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    procedure InitializeWidget; override;
    procedure SetEchoMode(AVisible: Boolean);
    procedure SetMaxLength(AMaxLength: Integer);
    procedure SetPasswordChar(APasswordChar: Char);
    function IsWidgetOk: Boolean; override;
    property Alignment: TAlignment read GetAlignment write SetAlignment;
  end;

  { TGtk3SpinEdit }

  TGtk3SpinEdit = class(TGtk3Entry)
  private
    function GetMaximum: Double;
    function GetMinimum: Double;
    function GetNumDigits: Integer;
    function GetNumeric: Boolean;
    function GetStep: Double;
    function GetValue: Double;
    procedure SetNumDigits(AValue: Integer);
    procedure SetNumeric(AValue: Boolean);
    procedure SetStep(AValue: Double);
    procedure SetValue(AValue: Double);
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
    function EatArrowKeys(const AKey: Word): Boolean; override;
  public
    function IsWidgetOk: Boolean; override;
    procedure SetRange(AMin, AMax: Double);
    property Minimum: Double read GetMinimum;
    property Maximum: Double read GetMaximum;
    property Numeric: Boolean read GetNumeric write SetNumeric;
    property NumDigits: Integer read GetNumDigits write SetNumDigits;
    property Step: Double read GetStep write SetStep;
    property Value: Double read GetValue write SetValue;
  end;

  { TGtk3Range }

  TGtk3Range = class(TGtk3Widget)
  private
    function GetPosition: Integer;
    function GetRange: TPoint;
    procedure SetPosition(AValue: Integer);
    procedure SetRange(AValue: TPoint);
  public
    procedure InitializeWidget; override;
    procedure SetStep(AStep: Integer; APageSize: Integer);
    property Range: TPoint read GetRange write SetRange;
    property Position: Integer read GetPosition write SetPosition;
  end;

  { TGtk3TrackBar }

  TGtk3TrackBar = class(TGtk3Range)
  private
    FOrientation: TTrackBarOrientation;
    function GetReversed: Boolean;
    procedure SetReversed(AValue: Boolean);
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    function GetTrackBarOrientation: TTrackBarOrientation;
    procedure SetScalePos(AValue: TTrackBarScalePos);
    procedure SetTickMarks(AValue: TTickMark; ATickStyle: TTickStyle);
    property Reversed: Boolean read GetReversed write SetReversed;
  end;

  { TGtk3ScrollBar }

  TGtk3ScrollBar = class(TGtk3Range)
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    procedure SetParams;
  end;

  { TGtk3ProgressBar }

  TGtk3ProgressBar = class(TGtk3Widget)
  private
    function GetOrientation: TProgressBarOrientation;
    function GetPosition: Integer;
    function GetShowText: Boolean;
    function GetStyle: TProgressBarStyle;
    procedure SetOrientation(AValue: TProgressBarOrientation);
    procedure SetPosition(AValue: Integer);
    procedure SetShowText(AValue: Boolean);
    procedure SetStyle(AValue: TProgressBarStyle);
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    procedure InitializeWidget; override;
    property Orientation: TProgressBarOrientation read GetOrientation write SetOrientation;
    property Position: Integer read GetPosition write SetPosition;
    property ShowText: Boolean read GetShowText write SetShowText;
    property Style: TProgressBarStyle read GetStyle write SetStyle;
  end;

  { TGtk3Calendar }

  TGtk3Calendar = class(TGtk3Widget)
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    procedure GetDate(out AYear, AMonth, ADay: Word);
    procedure SetDate(const AYear, AMonth, ADay: Word);
    procedure SetDisplayOptions(const ADisplayOptions: TGtkCalendarDisplayOptions);
  end;

  { TGtk3StaticText }

  TGtk3StaticText = class(TGtk3Widget)
  private
    function GetAlignment: TAlignment;
    function GetStaticBorderStyle: TStaticBorderStyle;
    procedure SetAlignment(AValue: TAlignment);
    procedure SetStaticBorderStyle(AValue: TStaticBorderStyle);
  protected
    function getText: String; override;
    procedure setText(AValue: String); override;
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    property Alignment: TAlignment read GetAlignment write SetAlignment;
    property StaticBorderStyle: TStaticBorderStyle read GetStaticBorderStyle write SetStaticBorderStyle;
  end;

  { TGtk3Container }

  TGtk3Container = class(TGtk3Widget)
  public
    procedure AddChild(AWidget: PGtkWidget; const ALeft, ATop: Integer); virtual;
  end;

  { TGtk3Page }

  TGtk3Page = class(TGtk3Container)
  private
    FPageLabel: PGtkLabel;
  protected
    procedure setText(AValue: String); override;
    function getText: String; override;
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
    procedure DestroyWidget; override;
  public
    function getClientRect: TRect; override;
  end;

  { TGtk3NoteBook }

  TGtk3NoteBook = class (TGtk3Container)
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    function getClientRect: TRect; override;
    procedure InsertPage(ACustomPage: TCustomPage; AIndex: Integer);
    procedure MovePage(ACustomPage: TCustomPage; ANewIndex: Integer);
    procedure RemovePage(AIndex: Integer);
    procedure SetPageIndex(AIndex: Integer);
    procedure SetShowTabs(const AShowTabs: Boolean);
    procedure SetTabPosition(const ATabPosition: TTabPosition);
    procedure SetTabLabelText(AChild: TCustomPage; AText: String);
    function  GetTabLabelText(AChild: TCustomPage): String;
  end;

  { TGtk3Bin }

  TGtk3Bin = class(TGtk3Container)

  end;

  { TGtk3MenuShell }

  TGtk3MenuShell = class(TGtk3Container)
  public
    MenuObject: TMenu;
    constructor Create(const AMenu: TMenu; AMenuBar: PGtkMenuBar); virtual; overload;
    procedure Insert(AMenuShell: PGtkMenuShell; APosition: Integer);
    procedure InitializeWidget; override;
  end;

  { TGtk3MenuBar }

  TGtk3MenuBar = class(TGtk3MenuShell)
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  end;

  { TGtk3Menu }

  TGtk3Menu = class(TGtk3MenuShell)
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    PopupPoint: TPoint;
    constructor CreateFromMenuItem(const AMenuItem: TMenuItem); virtual; overload;
  end;

  { TGtk3MenuItem }

  TGtk3MenuItem = class(TGtk3Bin)
  private
    function GetCaption: string;
    procedure SetCaption(AValue: string);
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    MenuItem: TMenuItem;
    constructor Create(const AMenuItem: TMenuItem); virtual; overload;
    procedure InitializeWidget; override;
    property Caption: string read GetCaption write SetCaption;
  end;

  { TGtk3ScrollableWin }

  TGtk3ScrollableWin = class(TGtk3Container)
  private
    FBorderStyle: TBorderStyle;
    FScrollX: Integer;
    FScrollY: Integer;
    function GetHScrollBarPolicy: TGtkPolicyType;
    function GetVScrollBarPolicy: TGtkPolicyType;
    procedure SetBorderStyle(AValue: TBorderStyle);
    procedure SetHScrollBarPolicy(AValue: TGtkPolicyType); virtual;
    procedure SetVScrollBarPolicy(AValue: TGtkPolicyType); virtual;
  public
    procedure SetScrollBarsSignalHandlers;
    function getClientBounds: TRect; override;
    function getHorizontalScrollbar: PGtkScrollbar; virtual; abstract;
    function getVerticalScrollbar: PGtkScrollbar; virtual; abstract;
    function getScrolledWindow: PGtkScrolledWindow; virtual; abstract;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle;
    property HScrollBarPolicy: TGtkPolicyType read GetHScrollBarPolicy write SetHScrollBarPolicy;
    property VScrollBarPolicy: TGtkPolicyType read GetVScrollBarPolicy write SetVScrollBarPolicy;
    property ScrollX: Integer read FScrollX write FScrollX;
    property ScrollY: Integer read FScrollY write FScrollY;
  end;

  { TGtk3ToolBar }

  TGtk3ToolBar = class(TGtk3Container)
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  end;

  { TGtk3Memo }

  TGtk3Memo = class(TGtk3ScrollableWin)
  private
    function GetAlignment: TAlignment;
    function GetReadOnly: Boolean;
    function GetWantTabs: Boolean;
    function GetWordWrap: Boolean;
    procedure SetAlignment(AValue: TAlignment);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetWantTabs(AValue: Boolean);
    procedure SetWordWrap(AValue: Boolean);
  protected
    function getText: String; override;
    procedure setText(AValue: String); override;
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
    function EatArrowKeys(const AKey: Word): Boolean; override;
  public
    function getHorizontalScrollbar: PGtkScrollbar; override;
    function getVerticalScrollbar: PGtkScrollbar; override;
    function GetScrolledWindow: PGtkScrolledWindow; override;
  public
    property Alignment: TAlignment read GetAlignment write SetAlignment;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly;
    property WantTabs: Boolean read GetWantTabs write SetWantTabs;
    property WordWrap: Boolean read GetWordWrap write SetWordWrap;
  end;

  { TGtk3ListBox }

  TGtk3ListBox = class(TGtk3ScrollableWin)
  private
    FListBoxStyle: TListBoxStyle;
    function GetItemIndex: Integer;
    function GetMultiSelect: Boolean;
    procedure SetItemIndex(AValue: Integer);
    procedure SetListBoxStyle(AValue: TListBoxStyle);
    procedure SetMultiSelect(AValue: Boolean);
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
    function EatArrowKeys(const AKey: Word): Boolean; override;
    procedure InitializeWidget; override;
  public
    function getHorizontalScrollbar: PGtkScrollbar; override;
    function getVerticalScrollbar: PGtkScrollbar; override;
    function GetScrolledWindow: PGtkScrolledWindow; override;
  public
    function GetSelCount: Integer;
    function GetSelection: PGtkTreeSelection;
    function GetItemSelected(const AIndex: Integer): Boolean;
    procedure SelectItem(const AIndex: Integer; ASelected: Boolean);
    procedure SetTopIndex(const AIndex: Integer);
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    property MultiSelect: Boolean read GetMultiSelect write SetMultiSelect;
    property ListBoxStyle: TListBoxStyle read FListBoxStyle write SetListBoxStyle;
  end;

  { TGtk3CheckListBox }

  TGtk3CheckListBox = class(TGtk3ListBox)
  protected
    function CreateWidget(const Params: TCreateParams): PGtkWidget; override;
  end;

  { TGtk3ListView }

  TGtk3ListView = class(TGtk3ScrollableWin)
  private
    FPreselectedIndices: TFPList;
    FImages: TFPList;
    FIsTreeView: Boolean;
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
    function EatArrowKeys(const AKey: Word): Boolean; override;
  public
    destructor Destroy; override;
    {interface implementation}
    function getHorizontalScrollbar: PGtkScrollbar; override;
    function getVerticalScrollbar: PGtkScrollbar; override;
    function GetScrolledWindow: PGtkScrolledWindow; override;
    procedure ClearImages;
    procedure ColumnDelete(AIndex: Integer);
    function ColumnGetWidth(AIndex: Integer): Integer;
    procedure ColumnInsert(AIndex: Integer; AColumn: TListColumn);
    procedure SetAlignment(AIndex: Integer; AColumn: TListColumn; AAlignment: TAlignment);
    procedure SetColumnAutoSize(AIndex: Integer; AColumn: TListColumn; AAutoSize: Boolean);
    procedure SetColumnCaption(AIndex: Integer; AColumn: TListColumn; const ACaption: String);
    procedure SetColumnMaxWidth(AIndex: Integer; AColumn: TListColumn; AMaxWidth: Integer);
    procedure SetColumnMinWidth(AIndex: Integer; AColumn: TListColumn; AMinWidth: Integer);
    procedure SetColumnWidth(AIndex: Integer; AColumn: TListColumn; AWidth: Integer);
    procedure SetColumnVisible(AIndex: Integer; AColumn: TListColumn; AVisible: Boolean);

    procedure ItemDelete(AIndex: Integer);
    procedure ItemInsert(AIndex: Integer; AItem: TListItem);
    procedure ItemSetText(AIndex, ASubIndex: Integer; AItem: TListItem; const AText: String);
    procedure ItemSetState(const AIndex: Integer; const AItem: TListItem; const AState: TListItemState;
      const AIsSet: Boolean);
    function ItemGetState(const AIndex: Integer; const AItem: TListItem; const AState: TListItemState;
      out AIsSet: Boolean): Boolean;

    procedure UpdateImageCellsSize;

    property Images: TFPList read FImages write FImages;
    property IsTreeView: Boolean read FIsTreeView;
  end;

  { TGtk3Box }

  TGtk3Box = class(TGtk3Container)

  end;

  { TGtk3StatusBar }

  TGtk3StatusBar = class(TGtk3Box)
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  end;

  { TGtk3Panel }

  TGtk3Panel = class(TGtk3Bin)
  private
    FBevelInner: TBevelCut;
    FBevelOuter: TBevelCut;
    FBorderStyle: TBorderStyle;
    FText: String;
  protected
    procedure SetColor(AValue: TColor); override;
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
    procedure DoBeforeLCLPaint; override;
    function getText: String; override;
    procedure setText(AValue: String); override;
  public
    property BevelInner: TBevelCut read FBevelInner write FBevelInner;
    property BevelOuter: TBevelCut read FBevelOuter write FBevelOuter;
    property BorderStyle: TBorderStyle read FBorderStyle write FBorderStyle;
  end;

  { TGtk3GroupBox }

  TGtk3GroupBox = class(TGtk3Bin)
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
    function getText: String; override;
    procedure setText(AValue: String); override;
  public
  end;

  { TGtk3ComboBox }

  TGtk3ComboBox = class(TGtk3Bin)
  private
    FCellView: PGtkCellView;
    function GetItemIndex: Integer;
    procedure SetDroppedDown(AValue: boolean);
    procedure SetItemIndex(AValue: Integer);
    function GetDroppedDown: boolean;
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
    function EatArrowKeys(const AKey: Word): Boolean; override;
    function getText: String; override;
    procedure setText(AValue: String); override;
  public
    procedure DumpPrivateStructValues(ADbgEvent: String);
  public
    function CanFocus: Boolean; override;
    procedure SetFocus; override;
    function GetCellView: PGtkCellView;
    function GetPopupWidget: PGtkWidget;
    function GetButtonWidget: PGtkWidget;
    function GetCellViewFrame: PGtkWidget;
    procedure InitializeWidget; override;
    property DroppedDown: boolean read GetDroppedDown write SetDroppedDown;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
  end;

  { TGtk3Button }

  TGtk3Button = class(TGtk3Bin)
  private
    FMargin: Integer;
    FLayout: Integer;
    FSpacing: Integer;
    function getLayout: Integer;
    function getMargin: Integer;
    procedure SetLayout(AValue: Integer);
    procedure SetMargin(AValue: Integer);
    procedure SetSpacing(AValue: Integer);
  protected
    function getText: String; override;
    procedure setText(AValue: String); override;
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    function IsWidgetOk: Boolean; override;
    procedure SetDefault(const ADefault: Boolean);
    property Layout: Integer read getLayout write SetLayout;
    property Margin: Integer read getMargin write SetMargin;
    property Spacing: Integer read FSpacing write SetSpacing;
  end;

  { TGtk3ToggleButton }

  TGtk3ToggleButton = class(TGtk3Button)
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    procedure InitializeWidget; override;
  end;

  { TGtk3CheckBox }

  TGtk3CheckBox = class(TGtk3ToggleButton)
  private
    function GetState: TCheckBoxState;
    procedure SetState(AValue: TCheckBoxState);
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    property State: TCheckBoxState read GetState write SetState;
  end;

  { TGtk3RadioButton }

  TGtk3RadioButton = class(TGtk3CheckBox)
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
  end;

  { TGtk3CustomControl }

  TGtk3CustomControl = class(TGtk3ScrollableWin)
    private
    protected
      function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
      function EatArrowKeys(const AKey: Word): Boolean; override;
    public
      procedure InitializeWidget; override;
      function getClientRect: TRect; override;
      function getHorizontalScrollbar: PGtkScrollbar; override;
      function getVerticalScrollbar: PGtkScrollbar; override;
      function GetScrolledWindow: PGtkScrolledWindow; override;
  end;

  { TGtk3ScrollingWinControl }

  TGtk3ScrollingWinControl = class(TGtk3CustomControl)
    protected
      function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  end;

  { TGtk3Window }

  TGtk3Window = class(TGtk3ScrollableWin) {we are TGtk3Bin actually, but it won't hurt since we need scroll}
  private
    FIcon: PGdkPixBuf;
    FScrollWin: PGtkScrolledWindow;
    FMenuBar: PGtkMenuBar;
    FBox: PGtkBox;
    function GetSkipTaskBarHint: Boolean;
    function GetTitle: String;
    procedure SetIcon(AValue: PGdkPixBuf);
    procedure SetSkipTaskBarHint(AValue: Boolean);
    procedure SetTitle(AValue: String);
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
    function EatArrowKeys(const AKey: Word): Boolean; override;
    function getText: String; override;
    procedure setText(AValue: String); override;
  public
    // function getClientBounds: TRect; override;
    function getClientRect: TRect; override;
    function getHorizontalScrollbar: PGtkScrollbar; override;
    function getVerticalScrollbar: PGtkScrollbar; override;
    function GetScrolledWindow: PGtkScrolledWindow; override;
  public
    destructor Destroy; override;
    procedure Activate; override;
    procedure Gtk3ActivateWindow(AEvent: PGdkEvent);
    function Gtk3CloseQuery: Boolean;
    function GetWindow: PGdkWindow; override;
    function GetMenuBar: PGtkMenuBar;
    function GetBox: PGtkBox;
    function GetWindowState: TGdkWindowState;
    property Icon: PGdkPixBuf read FIcon write SetIcon;
    property SkipTaskBarHint: Boolean read GetSkipTaskBarHint write SetSkipTaskBarHint;
    property Title: String read GetTitle write SetTitle;
  end;

  { TGtk3HintWindow }

  TGtk3HintWindow = class(TGtk3Window)
    private
      FText: String;
    protected
      function getText: String; override;
      procedure setText(AValue: String); override;
      function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  end;

  { TGtk3Dialog }

  TGtk3Dialog = class(TGtk3Widget)
  protected
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
  public
    CommonDialog: TCommonDialog;
    procedure InitializeWidget; override;
  end;

  { TGtk3FileDialog }

  TGtk3FileDialog = class(TGtk3Dialog)
  private
  protected
    function CreateWidget(const Params: TCreateParams): PGtkWidget; override;
  public
    constructor Create(const ACommonDialog: TCommonDialog); virtual; overload;
  end;

  { TGtk3FontSelectionDialog }

  TGtk3FontSelectionDialog = class(TGtk3Dialog)
  protected
    function CreateWidget(const Params: TCreateParams): PGtkWidget; override;
  public
    constructor Create(const ACommonDialog: TCommonDialog); virtual; overload;
  end;

{main event filter for all widgets, also called from widgetset main eventfilter}
function Gtk3WidgetEvent(widget: PGtkWidget; event: PGdkEvent; data: GPointer): gboolean; cdecl;

implementation
uses Spin, gtk3int, gtk3procs, gtk3private, Gtk3CellRenderer, ExtDlgs, math,
  CheckLst;

function Gtk3EventToStr(AEvent: TGdkEventType): String;
begin
  Result := 'GDK_NOTHING';
  case AEvent of
    // GDK_DELETE:
    0: Result := 'GDK_DELETE';
    // GDK_DESTROY:
    1: Result := 'GDK_DESTROY';
    // GDK_EXPOSE:
    2: Result := 'GDK_EXPOSE';
    // GDK_MOTION_NOTIFY:
    3: Result := 'GDK_MOTION_NOTIFY';
    // GDK_BUTTON_PRESS:
    4: Result := 'GDK_BUTTON_PRESS';
    // GDK_2BUTTON_PRESS:
    5: Result := 'GDK_2BUTTON_PRESS';
    // GDK_3BUTTON_PRESS:
    6: Result := 'GDK_3BUTTON_PRESS';
    // GDK_BUTTON_RELEASE:
    7: Result := 'GDK_BUTTON_RELEASE';
    // GDK_KEY_PRESS:
    8: Result := 'GDK_KEY_PRESS';
    // GDK_KEY_RELEASE:
    9: Result := 'GDK_KEY_RELEASE';
    // GDK_ENTER_NOTIFY:
    10: Result := 'GDK_ENTER_NOTIFY';
    // GDK_LEAVE_NOTIFY:
    11: Result := 'GDK_LEAVE_NOTIFY';
    // GDK_FOCUS_CHANGE:
    12: Result := 'GDK_FOCUS_CHANGE';
    // GDK_CONFIGURE:
    13: Result := 'GDK_CONFIGURE';
    // GDK_MAP:
    14: Result := 'GDK_MAP';
    // GDK_UNMAP:
    15: Result := 'GDK_UNMAP';
    // GDK_PROPERTY_NOTIFY:
    16: Result := 'GDK_PROPERTY_NOTIFY';
    // GDK_SELECTION_CLEAR:
    17: Result := 'GDK_SELECTION_CLEAR';
    // GDK_SELECTION_REQUEST:
    18: Result := 'GDK_SELECTION_REQUEST';
    // GDK_SELECTION_NOTIFY:
    19: Result := 'GDK_SELECTION_NOTIFY';
    // GDK_PROXIMITY_IN:
    20: Result := 'GDK_PROXIMITY_IN';
    // GDK_PROXIMITY_OUT:
    21: Result := 'GDK_PROXIMITY_OUT';
    // GDK_DRAG_ENTER:
    22: Result := 'GDK_DRAG_ENTER';
    // GDK_DRAG_LEAVE:
    23: Result := 'GDK_DRAG_LEAVE';
    // GDK_DRAG_MOTION_:
    24: Result := 'GDK_DRAG_MOTION_';
    // GDK_DRAG_STATUS_:
    25: Result := 'GDK_DRAG_STATUS_';
    // GDK_DROP_START:
    26: Result := 'GDK_DROP_START';
    // GDK_DROP_FINISHED:
    27: Result := 'GDK_DROP_FINISHED';
    // GDK_CLIENT_EVENT:
    28: Result := 'GDK_CLIENT_EVENT';
    // GDK_VISIBILITY_NOTIFY:
    29: Result := 'GDK_VISIBILITY_NOTIFY';
    // GDK_SCROLL:
    31: Result := 'GDK_SCROLL';
    // GDK_WINDOW_STATE:
    32: Result := 'GDK_WINDOW_STATE';
    // GDK_SETTING:
    33: Result := 'GDK_SETTING';
    // GDK_OWNER_CHANGE:
    34: Result := 'GDK_OWNER_CHANGE';
    // GDK_GRAB_BROKEN:
    35: Result := 'GDK_GRAB_BROKEN';
    // GDK_DAMAGE:
    36: Result := 'GDK_DAMAGE';
    // GDK_TOUCH_BEGIN:
    37: Result := 'GDK_TOUCH_BEGIN';
    // GDK_TOUCH_UPDATE:
    38: Result := 'GDK_TOUCH_UPDATE';
    // GDK_TOUCH_END:
    39: Result := 'GDK_TOUCH_END';
    // GDK_TOUCH_CANCEL:
    40: Result := 'GDK_TOUCH_CANCEL';
    // GDK_EVENT_LAST:
    41: Result := 'GDK_EVENT_LAST';
  end;
end;

function Gtk3MenuItemEvent(widget: PGtkWidget; event: PGdkEvent; data: GPointer): gboolean; cdecl;
begin
  Result := False;

  if not Assigned(Application) or (Assigned(Application) and Application.Terminated) then
      exit;

  // DebugLn('Gtk3MenuItemEvent triggered ',dbgsName(TGtk3MenuItem(Data).MenuItem),
  //  ' ',Gtk3EventToStr(event^.type_));

  case event^.type_ of
    // GDK_DELETE
    0:
    begin
      // DebugLn('****** GDK_DELETE FOR ',dbgsName(TGtk3Widget(Data).LCLObject),' main_level=',dbgs(gtk_main_level));
    end;
    // GDK_DESTROY
    1:
    begin
     // DebugLn('****** GDK_DESTROY FOR ' + dbgsName(TGtk3Widget(Data).LCLObject));
    end;
    // GDK_EXPOSE
    2:
    begin
      // DebugLn('****** GDK_EXPOSE FOR ' + dbgsName(TGtk3Widget(Data).LCLObject));
      // Gtk3DrawWidget is attached to 'draw' signal, Expose event doesn't trigger
      // under gtk3.
       // we use 'draw' signal Gtk3DrawEvent()
      // Result := TGtk3Widget(Data).GtkEventPaint(Widget, Event);
    end;
    // GDK_MOTION_NOTIFY
    3:
    begin
      // Result := TGtk3Widget(Data).GtkEventMouseMove(Widget, Event);
    end;
    // GDK_BUTTON_PRESS:
    4:
    begin
      // Result := TGtk3Widget(Data).GtkEventMouse(Widget , Event);
    end;
    // GDK_2BUTTON_PRESS:
    5:
    begin
      // if not TGtk3Widget(Data).LCLObject.Focused and TGtk3Widget(Data).LCLObject.CanFocus then
      //  LCLIntf.SetFocus(HWND(TGtk3Widget(Data)));
      // Result := TGtk3Widget(Data).GtkEventMouse(Widget , Event);
    end;
    // GDK_3BUTTON_PRESS:
    6:
    begin
      // if not TGtk3Widget(Data).LCLObject.Focused and TGtk3Widget(Data).LCLObject.CanFocus then
      //  LCLIntf.SetFocus(HWND(TGtk3Widget(Data)));
      // Result := TGtk3Widget(Data).GtkEventMouse(Widget , Event);
    end;
    // GDK_BUTTON_RELEASE:
    7:
    begin
      // Result := TGtk3Widget(Data).GtkEventMouse(Widget , Event);
    end;

    // GDK_KEY_PRESS
    8:
    begin
      // if Widget^.has_focus then // or (Widget = TGtk3Widget(data).GetContainerWidget) then
      //  Result := TGtk3Widget(Data).GtkEventKey(Widget, Event, True);
    end;
    // GDK_KEY_RELEASE
    9:
    begin
      // if Widget^.has_focus then // or (Widget = TGtk3Widget(data).GetContainerWidget) then
      //  Result := TGtk3Widget(Data).GtkEventKey(Widget, Event, False);
    end;

    // GDK_ENTER_NOTIFY
    10:
    begin
      // TGtk3Widget(Data).GtkEventMouseEnterLeave(Widget, Event);
    end;
    // GDK_LEAVE_NOTIFY
    11:
    begin
      // TGtk3Widget(Data).GtkEventMouseEnterLeave(Widget, Event);
    end;
    12:
    begin
      // GDK_FOCUS_CHANGE
    end;
    // GDK_CONFIGURE
    13:
    begin
      // GDK_CONFIGURE
    end;
    14: // GDK_MAP
    begin
      // DebugLn('****** GDK_MAP FOR ',dbgsName(TGtk3Widget(Data).LCLObject));
    end;
    16: // GDK_PROPERTY_NOTIFY
    begin
      // DebugLn('****** GDK_PROPERTY_NOTIFY FOR ',dbgsName(TGtk3Widget(Data).LCLObject));
    end;
    28: // GDK_CLIENT_EVENT
    begin
      // DebugLn('****** GDK_CLIENT_EVENT FOR ',dbgsName(TGtk3Widget(Data).LCLObject));
    end;
    29: // GDK_VISIBILITY_NOTIFY
    begin
      // Result := TGtk3Widget(Data).GtkEventShowHide(Widget, Event);
      // DebugLn('****** GDK_VISIBILITY_NOTIFY FOR ' + dbgsName(TGtk3Widget(Data).LCLObject));
    end;
    31: // GDK_SCROLL
    begin
      // DebugLn('****** GDK_SCROLL ' + dbgsName(TGtk3Widget(Data).LCLObject));
    end;
  end;
end;

function Gtk3WidgetEvent(widget: PGtkWidget; event: PGdkEvent; data: GPointer): gboolean; cdecl;
var
  APrivate: PGtkComboBoxPrivate;
  AComboWidget: PGtkComboBox;
begin
  {$IFDEF GTK3DEBUGCOMBOBOX}
  if (Data <> nil) and (wtComboBox in TGtk3Widget(Data).WidgetType) and
    (event^.type_ <> GDK_MOTION_NOTIFY) then
  begin
    if (Widget = TGtk3ComboBox(Data).GetPopupWidget) then
    DebugLn('***** Gtk3WidgetEvent(MENU triggered ',dbgsName(TGtk3Widget(Data).LCLObject),
      ' ',Gtk3EventToStr(event^.type_))
    else
    if (Widget = TGtk3ComboBox(Data).GetButtonWidget) then
    DebugLn('***** Gtk3WidgetEvent(BUTTON triggered ',dbgsName(TGtk3Widget(Data).LCLObject),
      ' ',Gtk3EventToStr(event^.type_))
    else
    if (Widget = PGtkWidget(TGtk3ComboBox(Data).GetCellView)) then
    DebugLn('***** Gtk3WidgetEvent(CELLVIEW triggered ',dbgsName(TGtk3Widget(Data).LCLObject),
      ' ',Gtk3EventToStr(event^.type_))
    else
    if (Widget = TGtk3ComboBox(Data).Widget) then
      DebugLn('***** Gtk3WidgetEvent(EVENTBOX triggered ',dbgsName(TGtk3Widget(Data).LCLObject),
        ' ',Gtk3EventToStr(event^.type_));
  end;
  {$ENDIF}
  {$IFDEF GTK3DEBUGCORE}
  // if event^.type_ = GDK_EXPOSE then
  if event^.type_ <> GDK_MOTION_NOTIFY then
    DebugLn('Gtk3WidgetEvent triggered ',dbgsName(TGtk3Widget(Data).LCLObject),
      ' ',Gtk3EventToStr(event^.type_));
  {$ENDIF}
  Result := False;
  if Assigned(Application) and Application.Terminated then
      exit;
  case event^.type_ of
    // GDK_DELETE
    0:
    begin
      // DebugLn('****** GDK_DELETE FOR ',dbgsName(TGtk3Widget(Data).LCLObject),' main_level=',dbgs(gtk_main_level));
      if wtWindow in TGtk3Widget(Data).WidgetType then
      begin
        TGtk3Window(Data).Gtk3CloseQuery;
        // let lcl destroy widget
        Result := True;
      end;
    end;
    // GDK_DESTROY
    1:
    begin
     // DebugLn('****** GDK_DESTROY FOR ' + dbgsName(TGtk3Widget(Data).LCLObject));
    end;
    // GDK_EXPOSE
    2:
    begin
      DebugLn('****** GDK_EXPOSE FOR ' + dbgsName(TGtk3Widget(Data).LCLObject));
      // Gtk3DrawWidget is attached to 'draw' signal, Expose event doesn't trigger
      // under gtk3.
       // we use 'draw' signal Gtk3DrawEvent()
      // Result := TGtk3Widget(Data).GtkEventPaint(Widget, Event);
    end;
    // GDK_MOTION_NOTIFY
    3:
    begin
      if wtWindow in TGtk3Widget(Data).WidgetType then
      begin
        if Widget = TGtk3Widget(Data).Widget then
          exit;
      end;
      Result := TGtk3Widget(Data).GtkEventMouseMove(Widget, Event);
    end;
    // GDK_BUTTON_PRESS:
    4:
    begin
      // set focus before gtk does that, so we have same behaviour as other ws
      if TGtk3Widget(Data).GetFocusableByMouse and
        not TGtk3Widget(Data).LCLObject.Focused and
        TGtk3Widget(Data).LCLObject.CanFocus then
      begin
        //FIXME: combobox updates popup-shown property too late
        // so we dont know yet if its dropped down or not
        if (wtComboBox in TGtk3Widget(Data).WidgetType) then
        begin
          TGtk3ComboBox(Data).DumpPrivateStructValues('GDK_BUTTON_PRESS btn='+IntToStr(Event^.button.button));
        end;
        if (wtWindow in TGtk3Widget(Data).WidgetType) then
        begin
          TGtk3Widget(Data).Activate;
        end else
          LCLIntf.SetFocus(HWND(TGtk3Widget(Data)));
      end;

      Result := TGtk3Widget(Data).GtkEventMouse(Widget , Event);
    end;
    // GDK_2BUTTON_PRESS:
    5:
    begin
      // set focus before gtk does that, so we have same behaviour as other ws
      if TGtk3Widget(Data).GetFocusableByMouse and
        not TGtk3Widget(Data).LCLObject.Focused and
        TGtk3Widget(Data).LCLObject.CanFocus then
          LCLIntf.SetFocus(HWND(TGtk3Widget(Data)));
      Result := TGtk3Widget(Data).GtkEventMouse(Widget , Event);
    end;
    // GDK_3BUTTON_PRESS:
    6:
    begin
      // set focus before gtk does that, so we have same behaviour as other ws
      if TGtk3Widget(Data).GetFocusableByMouse and
        not TGtk3Widget(Data).LCLObject.Focused and
        TGtk3Widget(Data).LCLObject.CanFocus then
          LCLIntf.SetFocus(HWND(TGtk3Widget(Data)));
      Result := TGtk3Widget(Data).GtkEventMouse(Widget , Event);
    end;
    // GDK_BUTTON_RELEASE:
    7:
    begin
      Result := TGtk3Widget(Data).GtkEventMouse(Widget , Event);
    end;

    // GDK_KEY_PRESS
    8:
    begin
      if Widget^.has_focus then
        Result := TGtk3Widget(Data).GtkEventKey(Widget, Event, True);
    end;
    // GDK_KEY_RELEASE
    9:
    begin
      if Widget^.has_focus then // or (Widget = TGtk3Widget(data).GetContainerWidget) then
        Result := TGtk3Widget(Data).GtkEventKey(Widget, Event, False);
    end;

    // GDK_ENTER_NOTIFY
    10:
    begin
      if wtWindow in TGtk3Widget(Data).WidgetType then
      begin
        if Widget <> TGtk3Widget(Data).GetContainerWidget then
          exit;
      end;
      (*
      DebugLn('** ENTER_NOTIFY ',dbgs(Event^.crossing.send_event),' TIME ',dbgs(Event^.crossing.time),' MODE ',dbgs(Event^.crossing.mode),
       ' WIDGET ',dbgHex(PtrUInt(Widget)),' LCLObject ',dbgsName(TGtk3Widget(Data).LCLObject),
       ' Widget=?',dbgs(Widget=TGtk3Widget(Data).GetContainerWidget));
      *)
      (*
      if wtComboBox in TGtk3Widget(Data).WidgetType then
      begin
        // DebugLn('** ENTER_NOTIFY ',dbgs(Event^.crossing.send_event),' TIME ',dbgs(Event^.crossing.time),' MODE ',dbgs(Event^.crossing.mode),
        //  ' ENTERLEAVETIME=',dbgs(TGtk3ComboBox(Data).FEnterLeaveTime),' WIDGET ',dbgHex(PtrUInt(Widget)));
        TGtk3ComboBox(Data).DumpPrivateStructValues('GDK_ENTER_NOTIFY');
        if Widget <> TGtk3Widget(Data).Widget then
          exit;
        // upisi u combobox enter time, ako je enter.time - leave.time < 20 onda ne salji msg !
        TGtk3ComboBox(Data).FEnterLeaveTime := Event^.crossing.time;
      end;
      *)
      TGtk3Widget(Data).GtkEventMouseEnterLeave(Widget, Event);
    end;
    // GDK_LEAVE_NOTIFY
    11:
    begin
      if wtWindow in TGtk3Widget(Data).WidgetType then
      begin
        if Widget <> TGtk3Widget(Data).GetContainerWidget then
          exit;
      end;
      (*
      DebugLn('** LEAVE_NOTIFY ',dbgs(Event^.crossing.send_event),' TIME ',dbgs(Event^.crossing.time),' MODE ',dbgs(Event^.crossing.mode),
       ' WIDGET ',dbgHex(PtrUInt(Widget)),' LCLObject ',dbgsName(TGtk3Widget(Data).LCLObject),
       ' Widget=?',dbgs(Widget=TGtk3Widget(Data).GetContainerWidget));
      *)
      (*
      if wtComboBox in TGtk3Widget(Data).WidgetType then
      begin
        // DebugLn('** LEAVE_NOTIFY ',dbgs(Event^.crossing.send_event),' TIME ',dbgs(Event^.crossing.time),' MODE ',dbgs(Event^.crossing.mode),
        // ' TIME DIFF=',dbgs(Event^.crossing.time - TGtk3ComboBox(Data).FEnterLeaveTime),
        // ' WIDGET ',dbgHex(PtrUInt(Widget)));
        if Widget <> TGtk3Widget(Data).Widget then
          exit;
        if Event^.crossing.time - TGtk3ComboBox(Data).FEnterLeaveTime < 100 then
        begin
          exit(False);
        end;
      end;
      *)
      TGtk3Widget(Data).GtkEventMouseEnterLeave(Widget, Event);
    end;
    // GDK_FOCUS_CHANGE
    12:
    begin
      if wtComboBox in TGtk3Widget(Data).WidgetType then
      begin
        TGtk3ComboBox(Data).DumpPrivateStructValues('GDK_FOCUS_CHANGE='+IntToStr(Event^.focus_change.in_));
        //FIXME: combobox updates popup-shown property too late
        // so we dont know yet if its dropped down or not
        if TGtk3ComboBox(Data).DroppedDown then
          exit;
      end;
      TGtk3Widget(Data).GtkEventFocus(Widget, Event);
    end;
    // GDK_CONFIGURE
    13:
    begin
      (* DOES NOT WORK AS DOCUMENTATION SAYS
      if Data <> nil then
      begin
        if wtWindow in TGtk3Widget(Data).WidgetType then
        begin
          TGtk3Window(Data).Gtk3ActivateWindow(Event);
          DebugLn('** WindowState event ',dbgsName(TGtk3Widget(Data).LCLObject),' windowState=',dbgs(TGtk3Window(Data).GetWindowState));
        end else
          DebugLn('** WindowState event not wtWindow ',dbgsName(TGtk3Widget(Data).LCLObject));
      end;
      *)
      Result := TGtk3Widget(Data).GtkEventResize(Widget, Event);
    end;
    14: // GDK_MAP
    begin
      // DebugLn('****** GDK_MAP FOR ',dbgsName(TGtk3Widget(Data).LCLObject));
    end;
    15: // GDK_UNMAP
    begin
       // DebugLn('****** GDK_UNMAP FOR ',dbgsName(TGtk3Widget(Data).LCLObject));
    end;
    16: // GDK_PROPERTY_NOTIFY
    begin
      // DebugLn('****** GDK_PROPERTY_NOTIFY FOR ',dbgsName(TGtk3Widget(Data).LCLObject));
    end;
    28: // GDK_CLIENT_EVENT
    begin
      // DebugLn('****** GDK_CLIENT_EVENT FOR ',dbgsName(TGtk3Widget(Data).LCLObject));
    end;
    29: // GDK_VISIBILITY_NOTIFY
    begin
      // ONLY HERE WE CAN CATCH Activate/Deactivate but problem is that
      // PGtkWindow does not update active property properly
      // so PGtkWindow(Widget)^.is_active returns TRUE even if window isn't active anymore
      if wtWindow in TGtk3Widget(Data).WidgetType then
      begin
        TGtk3Window(Data).Gtk3ActivateWindow(Event);
      end;
      // Result := TGtk3Widget(Data).GtkEventShowHide(Widget, Event);
      // DebugLn('****** GDK_VISIBILITY_NOTIFY FOR ' + dbgsName(TGtk3Widget(Data).LCLObject));
    end;
    32: // GDK_WINDOW_STATE
    begin
      // DebugLn('****** GDK_WINDOW_STATE FOR ' + dbgsName(TGtk3Widget(Data).LCLObject));
      // this doesn't work as expected ... must use GDK_CONFIGURE to get active status ?!?
    end;
    35: // GDK_GRAB_BROKEN  could be broken eg. because of popupmenu
    begin
      DebugLn('****** GDK_GRAB_BROKEN (no problem if popupmenu is activated) ' + dbgsName(TGtk3Widget(Data).LCLObject));
    end;
  otherwise
    DebugLn('****** GDK unhandled event type ' + dbgsName(TGtk3Widget(Data).LCLObject));
    WriteLn(event^.type_);

  end;
end;

function Gtk3DrawWidget(AWidget: PGtkWidget; AContext: Pcairo_t; Data: gpointer): gboolean; cdecl;
var
  ARect: TGdkRectangle;
begin
  Result := False;
  if Data <> nil then
  begin
    gdk_cairo_get_clip_rectangle(AContext, @ARect);
    // DebugLn('**** Sending paint event to ',dbgsName(TGtk3Widget(Data).LCLObject),' clip ',dbgs(RectFromGdkRect(ARect)),' w=',dbgs(ARect.Width),' h=',dbgs(ARect.height));
    Result := TGtk3Widget(Data).GtkEventPaint(AWidget, AContext);
    // workaround for lcl painted widgets until we found why gtk3 sends wrong rect
    if (TGtk3Widget(Data).FHasPaint) and
      (ARect.height < (TGtk3Widget(Data).GetContainerWidget^.get_allocated_height div 4) ) then
        AWidget^.queue_draw;
  end;
end;

procedure Gtk3MapWidget(AWidget: PGtkWidget; Data: gPointer); cdecl;
var
  Allocation: TGtkAllocation;
  ARect: TRect;
  AWindow: PGdkWindow;
  xx,yy,w,h: Gint;
begin
  AWidget^.get_allocation(@Allocation);
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('**** Gtk3MapWidget ....',dbgsName(TGtk3Widget(Data).LCLObject));
  with Allocation do
    DebugLn(' Allocation ',Format('x %d y %d w %d h %d',[x,y,width,height]));
  {$ENDIF}
  ARect := TGtk3Widget(Data).LCLObject.BoundsRect;
  {$IFDEF GTK3DEBUGCORE}
  with ARect do
    DebugLn(' Rect ',Format('x %d y %d w %d h %d',[Left,Top,Right - Left, Bottom - Top]));
  {$ENDIF}
  AWindow := AWidget^.get_window;
  // at least TPanel needs this
  if Gtk3IsGdkWindow(AWindow) and (g_object_get_data(AWindow,'lclwidget') = nil) then
    g_object_set_data(AWindow,'lclwidget', TGtk3Widget(Data));
  if (AWindow <> nil) and AWidget^.get_has_window then
  begin
    // do resize to lcl size when mapping widget
    gdk_window_set_events(AWindow, GDK_ALL_EVENTS_MASK);
    if not (wtWindow in TGtk3Widget(Data).WidgetType) then
    begin
      with TGtk3Widget(Data).LCLObject do
      begin
        xx := Left;
        yy := Top;
        w := Width;
        h := Height;
      end;
      TGtk3Widget(Data).BeginUpdate;
      AWindow^.move(xx, yy);
      AWindow^.resize(w, h);
      TGtk3Widget(Data).EndUpdate;
    end else
    begin
      // DebugLn('TGtk3Window is mapped , setting lclwidget property to PGdkWindow ...');
      // now we set 'lclwidget' to our window.
      // g_object_set_data(AWindow,'lclwidget', TGtk3Widget(Data));
    end;
  end else
  begin
    if wtMemo in TGtk3Widget(Data).WidgetType then
    begin
      // gdk_window_get_geometry(AWindow, @xx,@yy,@w,@h);
      // gdk_window_get_position(AWindow, @xx,@yy);
      // DebugLn(' ***** Window ',Format('x %d y %d w %d h %d',[xx,yy,w,h]),' lclobject ',dbgsName(TGtk3Widget(Data).LCLObject));
    end;
  end;
end;

procedure Gtk3SizeAllocate(AWidget: PGtkWidget; AGdkRect: PGdkRectangle; Data: gpointer); cdecl;
var
  Msg: TLMSize;
  MoveMsg: TLMMove;
  NewSize: TSize;
  ACtl: TGtk3Widget;
begin
  //TODO: Move to TGtk3Widget.GtkResizeEvent
  {$IFDEF GTK3DEBUGSIZE}
  with AGdkRect^ do
    DebugLn('**** Gtk3SizeAllocate **** ....',dbgsName(TGtk3Widget(Data).LCLObject),
      ' ',Format('x %d y %d w %d h %d',[x, y, width, height]));
  {$ENDIF}

  ACtl := TGtk3Widget(Data);

  // return size w/o frame
  NewSize.cx := AGdkRect^.width;
  NewSize.cy := AGdkRect^.height;

  if not Assigned(ACtl.LCLObject) then exit;

  // do not loop with LCL but do not apply it to TQtMainWindow !
  if not (csDesigning in ACtl.LCLObject.ComponentState) then
  begin
    if ACtl.InUpdate then
      exit;
    //  if not (ClassType = TQtMainWindow) and InUpdate then
    //    exit;
  end;

  if ((NewSize.cx <> ACtl.LCLObject.Width) or (NewSize.cy <> ACtl.LCLObject.Height) or
     ACtl.LCLObject.ClientRectNeedsInterfaceUpdate) then
  begin
    ACtl.LCLObject.DoAdjustClientRectChange;
  end;

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SIZE;
  (*
  case getWindowState of
    GtkWindowMinimized: Msg.SizeType := SIZE_MINIMIZED;
    GtkWindowMaximized: Msg.SizeType := SIZE_MAXIMIZED;
    GtkWindowFullScreen: Msg.SizeType := SIZE_FULLSCREEN;
  else
    Msg.SizeType := SIZE_RESTORED;
  end;
  *)
  Msg.SizeType := SIZE_RESTORED;

  Msg.SizeType := Msg.SizeType or Size_SourceIsInterface;
  Msg.Width := Word(NewSize.cx);
  Msg.Height := Word(NewSize.cy);
  ACtl.DeliverMessage(Msg);

  if (wtWindow in ACtl.WidgetType) and
    ((AGdkRect^.x <> ACtl.LCLObject.Left) or (AGdkRect^.y <> ACtl.LCLObject.Top)) then
  begin
    FillChar(MoveMsg, SizeOf(MoveMsg), #0);
    MoveMsg.Msg := LM_MOVE;
    MoveMsg.MoveType := MoveMsg.MoveType or Move_SourceIsInterface;
    MoveMsg.XPos := SmallInt(AGdkRect^.x);
    MoveMsg.YPos := SmallInt(AGdkRect^.y);
    {$IFDEF GTK3DEBUGEVENTS}
    DebugLn('SEND MOVE MESSAGE X=',dbgs(AGdkRect^.x),' Y=',dbgs(AGdkRect^.y),' control ',dbgsName(ACtl.LCLObject));
    {$ENDIF}
    ACtl.DeliverMessage(MoveMsg);
  end;
end;

function Gtk3ResizeEvent(AWidget: PGtkWidget; AEvent: PGdkEvent; Data: gpointer): gboolean; cdecl;
var
  ARect: TGdkRectangle;
begin
  Result := False;
  ARect.X := AEvent^.configure.x;
  ARect.Y := AEvent^.configure.y;
  ARect.width := AEvent^.configure.width;
  ARect.height := AEvent^.configure.height;
  // DebugLn('**** Gtk3ResizeEvent(CONFIGURE) **** ....',dbgsName(TGtk3Widget(Data).LCLObject),' ARect ',dbgs(RectFromGdkRect(ARect)));
  Gtk3SizeAllocate(AWidget, @ARect, Data);
end;

procedure Gtk3WidgetHide(AWidget: PGtkWidget; AData: gpointer); cdecl;
var
  Msg: TLMShowWindow;
  Gtk3Widget: TGtk3Widget;
begin
  Gtk3Widget := TGtk3Widget(AData);
  {do not pass message to LCL if LCL setted up control visibility}
  if Gtk3Widget.inUpdate then
    exit;
  // DebugLn('SEND LM_HIDE FOR ',dbgsName(Gtk3Widget.LCLObject));
  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SHOWWINDOW;
  Msg.Show := False;

  Gtk3Widget.DeliverMessage(Msg);
end;

procedure Gtk3WidgetShow(AWidget: PGtkWidget; AData: gpointer); cdecl;
var
  Msg: TLMShowWindow;
  Gtk3Widget: TGtk3Widget;
begin
  Gtk3Widget := TGtk3Widget(AData);
  {do not pass message to LCL if LCL setted up control visibility}
  if Gtk3Widget.inUpdate then
    exit;
  // DebugLn('SEND LM_SHOW FOR ',dbgsName(Gtk3Widget.LCLObject));
  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SHOWWINDOW;
  Msg.Show := True;

  Gtk3Widget.DeliverMessage(Msg);
end;

function GtkModifierStateToShiftState(AState: TGdkModifierType;
    AIsKeyEvent: Boolean): Cardinal;
begin
  Result := 0;
  if AState and GDK_SHIFT_MASK <> 0 then
    Result := Result or MK_SHIFT;
  if AState and GDK_CONTROL_MASK <> 0 then
    Result := Result or MK_CONTROL;
  if AState and GDK_MOD1_MASK <> 0 then
  begin
    if AIsKeyEvent then
      Result := Result or KF_ALTDOWN
    else
      Result := Result or $20000000;
  end;
end;

function SubtractScroll(AWidget: PGtkWidget; APosition: TPoint): TPoint;
begin
  Result := APosition;
  if Gtk3IsScrolledWindow(AWidget) then
  begin
    with gtk_scrolled_window_get_hadjustment(PGtkScrolledWindow(AWidget))^ do
      dec(Result.x, Trunc(value - lower));
    with gtk_scrolled_window_get_vadjustment(PGtkScrolledWindow(AWidget))^ do
      dec(Result.y, Trunc(value - lower));
  end;
end;

function Gtk3ScrolledWindowScrollEvent(AScrollWindow: PGtkScrolledWindow; AEvent: PGdkEvent; AData: gPointer): gboolean; cdecl;
var
  Msg: TLMVScroll;
  AValue: Double;
  Range: PGtkRange;
begin
  {$IFDEF SYNSCROLLDEBUG}
  debugln(['Gtk3ScrolledWindowScrollEvent ']);
  {$ENDIF}
  Result := False;
  case AEvent^.scroll.direction of
    0, 1{GDK_SCROLL_UP,
    GDK_SCROLL_DOWN}: Msg.Msg := LM_VSCROLL;
    2, 3{GDK_SCROLL_LEFT,
    GDK_SCROLL_RIGHT}: Msg.Msg := LM_HSCROLL;
  end;

  case Msg.Msg of
    LM_VSCROLL: Range := PGtkRange(AScrollWindow^.get_vscrollbar);
    LM_HSCROLL: Range := PGtkRange(AScrollWindow^.get_hscrollbar);
  end;

  AValue :=  power(Range^.adjustment^.page_size, 2 / 3);

  if (AEvent^.scroll.direction = GDK_SCROLL_UP) or
     (AEvent^.scroll.direction = GDK_SCROLL_LEFT)
  then
    AValue := -AValue;

  AValue := gtk_range_get_value(Range) + AValue;

  AValue := Max(AValue, Range^.adjustment^.lower);
  AValue := Min(AValue, Range^.adjustment^.upper - Range^.adjustment^.page_size);

  with Msg do
  begin
    Pos := Round(AValue);
    if Pos < High(SmallPos) then
      SmallPos := Pos
    else
      SmallPos := High(SmallPos);

    ScrollBar := HWND(PtrUInt(AData));
    ScrollCode := SB_THUMBPOSITION;
  end;
  Result := TGtk3Widget(AData).DeliverMessage(Msg) <> 0;
  // DeliverMessage(.LCLObject, Msg) <> 0;
end;

function Gtk3ScrollEvent(AWidget: PGtkWidget; AEvent: PGdkEvent; AData: GPointer): GBoolean; cdecl;
var
  AWinControl: TWinControl;
  EventXY: TPoint;
  AState: Cardinal;
  ShiftState: TShiftState;
  MappedXY: TPoint;
  MessE : TLMMouseEvent;
begin
  Result := False;
  AWinControl := TGtk3Widget(AData).LCLObject;

  if AEvent^.scroll.send_event = NO_PROPAGATION_TO_PARENT then
    exit;

  EventXY := Point(TruncToInt(AEvent^.Scroll.X),TruncToInt(AEvent^.scroll.Y));
  AState := GtkModifierStateToShiftState(AEvent^.scroll.state, False);
  ShiftState := [];
  if AState and MK_SHIFT <> 0 then
    ShiftState := ShiftState + [ssShift];
  if AState and MK_CONTROL <> 0 then
    ShiftState := ShiftState + [ssCtrl];
  if AState and $20000000 <> 0 then
    ShiftState := ShiftState + [ssAlt];
  // MappedXY := TranslateGdkPointToClientArea(AEvent^.scroll.window, EventXY,
  //                                        {%H-}TGtk3Widget(AWinControl.Handle).GetContainerWidget);
  MappedXY := EventXY;
  MappedXY := SubtractScroll(TGtk3Widget(AWinControl.Handle).GetContainerWidget, MappedXY);
  //DebugLn('gtkMouseWheelCB ',DbgSName(AWinControl),' Mapped=',dbgs(MappedXY.X),',',dbgs(MappedXY.Y),' Event=',dbgs(EventXY.X),',',dbgs(EventXY.Y));

  // this is a mouse wheel event
  FillChar(MessE,SizeOf(MessE),0);
  MessE.Msg := LM_MOUSEWHEEL;
  case AEvent^.scroll.direction of
    0 {GDK_SCROLL_UP}: MessE.WheelDelta := 120;
    1 {GDK_SCROLL_DOWN}: MessE.WheelDelta := -120;
  else
    exit;
  end;
  MessE.X := MappedXY.X;
  MessE.Y := MappedXY.Y;
  MessE.State := ShiftState;
  MessE.UserData := AWinControl;
  MessE.Button := 0;

  // send the message directly to the LCL
  NotifyApplicationUserInput(AWinControl, MessE.Msg);
  if DeliverMessage(AWinControl, MessE) <> 0 then
    Result := True // message handled by LCL, stop processing
  else
    AEvent^.scroll.send_event := NO_PROPAGATION_TO_PARENT;

  // DebugLn('Gtk3ScrollEvent for ', dbgsName(TGtk3Widget(AData).LCLObject),' Result ',dbgs(Result));
end;

{ TGtk3Widget }

function TGtk3Widget.GtkEventMouseEnterLeave(Sender: PGtkWidget; Event: PGdkEvent): Boolean;
  cdecl;
var
  Msg: TLMessage;
  // MouseMsg: TLMMouseMove absolute Msg;
  MousePos: TPoint;
begin
  Result := False;
  FillChar(Msg, SizeOf(Msg), #0);
  if Event^.type_ = GDK_ENTER_NOTIFY then
  begin
    Msg.Msg := LM_MOUSEENTER;
  end else
  begin
    Msg.Msg := LM_MOUSELEAVE;
  end;

  MousePos.X := Round(Event^.crossing.x);
  MousePos.Y := Round(Event^.crossing.y);
  NotifyApplicationUserInput(LCLObject, Msg.Msg);
  Result := DeliverMessage(Msg, True) <> 0;
  {$IFDEF GTK3DEBUGCORE}
  DebugLn('GtkEventMouseEnterLeave: mousePos ',dbgs(MousePos),' Object ',dbgsName(LCLObject),
    ' IsEnter ',dbgs(Event^.type_ = GDK_ENTER_NOTIFY),' Result=',dbgs(Result));
  {$ENDIF}
end;

function TGtk3Widget.GtkEventMouseMove(Sender: PGtkWidget; Event: PGdkEvent
  ): Boolean; cdecl;
var
  Msg: TLMMouseMove;
  MousePos: TPoint;
  GlobPos: TPoint;
  R: TRect;
  P: TPoint;
begin
  Result := False;

  {$IFDEF GTK3DEBUGEVENTS}
  R := GetClientBounds;
  DebugLn(['GtkEventMouseMove: ',dbgsName(LCLObject),' Send=',dbgs(Event^.motion.send_event),
  ' state=',dbgs(event^.motion.state),
  ' x=',dbgs(Round(event^.motion.x)),
  ' y=',dbgs(Round(event^.motion.y)),
  ' x_root=',dbgs(Round(event^.motion.x_root)),
  ' y_root=',dbgs(Round(event^.motion.y_root)),
  ' STOP PROCESSING ? ',dbgs(Event^.motion.send_event = NO_PROPAGATION_TO_PARENT),
  ' GtkBounds ',dbgs(R),' LCLBounds ',dbgs(LCLObject.BoundsRect),' W=',dbgs(LCLObject.Width)]
  );
  {$ENDIF}

  if Event^.motion.send_event = NO_PROPAGATION_TO_PARENT then
    exit;

  FillChar(Msg, SizeOf(Msg), #0);

  MousePos.x := Round(Event^.motion.x);
  MousePos.y := Round(Event^.motion.y);

  OffsetMousePos(@MousePos);

  Msg.XPos := SmallInt(MousePos.X);
  Msg.YPos := SmallInt(MousePos.Y);

  Msg.Keys := GdkModifierStateToLCL(Event^.motion.state, False);

  Msg.Msg := LM_MOUSEMOVE;


  NotifyApplicationUserInput(LCLObject, Msg.Msg);
  if Widget^.get_parent <> nil then
    Event^.motion.send_event := NO_PROPAGATION_TO_PARENT;
  DeliverMessage(Msg, True);
end;

function TGtk3Widget.GtkEventPaint(Sender: PGtkWidget; AContext: Pcairo_t
  ): Boolean; cdecl;
var
  PS: TPaintStruct;
  Msg: TLMPaint;
  AStruct: PPaintStruct;
  P: TPoint;
  B: Boolean;
  AClipRect: TGdkRectangle;
  dx: Double;
  dy: Double;
  AMatrix: Pcairo_matrix_t;
begin
  Result := False;

  if not FHasPaint then
    exit;

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_PAINT;
  New(AStruct);
  FillChar(AStruct^, SizeOf(TPaintStruct), 0);
  Msg.PaintStruct := AStruct;

  with PaintData do
  begin
    if GetContainerWidget = nil then
      PaintWidget := Widget
    else
      PaintWidget := GetContainerWidget;
    ClipRegion := nil;
    // gdk_cairo_region(AContext, ClipRegion);
    // Event^.expose.region;
    if ClipRect = nil then
      New(ClipRect);
    gdk_cairo_get_clip_rectangle(AContext, @AClipRect);
    ClipRect^ := RectFromGdkRect(AClipRect);
  end;

  FCairoContext := AContext;
  Msg.DC := BeginPaint(THandle(Self), AStruct^);
  FContext := Msg.DC;

  Msg.PaintStruct^.rcPaint := PaintData.ClipRect^;
  Msg.PaintStruct^.hdc := FContext;

  // P := Point(0, 0);

  P := Self.getClientOffset;
  if wtCustomControl in WidgetType then
  begin
    // ofsetting
    P := Point(0, 0);
    //TGtk3DeviceContext(Msg.DC).TranslateCairoToDevice;
    //P.X := Round(TGtk3CustomControl(Self).getHorizontalScrollbar^.get_adjustment^.get_value);
    //P.Y := Round(TGtk3CustomControl(Self).getVerticalScrollbar^.get_adjustment^.get_value);
  end else
  if wtScrollingWinControl in WidgetType then
  begin
    P := Point(0, 0);
    //DebugLn('GtkEventPaint Scrollable ScrollX=',dbgs(TGtk3ScrollableWin(Self).ScrollX),
    //  ' scrollY=',dbgs(TGtk3ScrollableWin(Self).ScrollY),' P=',dbgs(P));
    //Inc(P.X, TGtk3ScrollableWin(Self).ScrollX);
    //Inc(P.Y, TGtk3ScrollableWin(Self).ScrollY);
    // cairo_surface_get_device_offset(cairo_get_target(AContext), @dx, @dy);
    // TGtk3DeviceContext(Msg.DC).TranslateCairoToDevice;
  end else
  if wtGroupBox in WidgetType then
  begin
    // why is gtk3 so crazy about parent/child relation ?!?
    // in this case child PGtkFixed has same top (+top caption) as parent TGtkFrame ... crap
    // debugln('groupbox paint offset ',dbgs(p));
    TGtk3DeviceContext(Msg.DC).TranslateCairoToDevice;
    P := Point(0, 0);
  end;

  {$NOTE Currently TGtk3DeviceContext(Msg.DC).Translate(P) is creating incorrect offsets inside TPages for TLabel and maybe others}
  TGtk3DeviceContext(Msg.DC).Translate(P);

  try
    try
      // DebugLn('**** Sending paint event to ',dbgsName(LCLObject),' clipRect=',dbgs(PaintData.ClipRect^),' P=',dbgs(P));
      DoBeforeLCLPaint;
      LCLObject.WindowProc(TLMessage(Msg));
    finally
      FCairoContext := nil;
      Dispose(PaintData.ClipRect);
      Fillchar(FPaintData, SizeOf(FPaintData), 0);
      FContext := 0;
      EndPaint(THandle(Self), AStruct^);
      Dispose(AStruct);
    end;
  except
    Application.HandleException(nil);
  end;
end;

function TGtk3Widget.GtkEventResize(Sender: PGtkWidget; Event: PGdkEvent
  ): Boolean; cdecl;
begin
  {$IF DEFINED(GTK3DEBUGEVENTS) OR DEFINED(GTK3DEBUGSIZE)}
  DebugLn('GtkEventResize: ',dbgsName(LCLObject),' Send=',dbgs(Event^.configure.send_event),
  ' x=',dbgs(Round(event^.configure.x)),
  ' y=',dbgs(Round(event^.configure.y)),
  ' w=',dbgs(Round(event^.configure.height)),
  ' h=',dbgs(Round(event^.configure.width)));
  {$ENDIF}
  Result := False;
end;

procedure TGtk3Widget.GtkEventFocus(Sender: PGtkWidget; Event: PGdkEvent);
  cdecl;
var
  Msg: TLMessage;
begin
  {$IF DEFINED(GTK3DEBUGEVENTS) OR DEFINED(GTK3DEBUGFOCUS)}
  DebugLn('TGtk3Widget.GtkEventFocus ',dbgsName(LCLObject),' FocusIn ',dbgs(Event^.focus_change.in_ <> 0));
  {$ENDIF}
  FillChar(Msg, SizeOf(Msg), #0);
  if Event^.focus_change.in_ <> 0 then
    Msg.Msg := LM_SETFOCUS
  else
    Msg.Msg := LM_KILLFOCUS;
  DeliverMessage(Msg);
end;

procedure TGtk3Widget.GtkEventDestroy; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_DESTROY;
  DeliverMessage(Msg);
  Release;
end;

function TGtk3Widget.GtkEventMouseWheel(Sender: PGtkWidget; Event: PGdkEvent
  ): Boolean; cdecl;
begin
  // gtk3 have ugly bug with scroll-event
  // https://bugzilla.gnome.org/show_bug.cgi?id=675959
  Result := False;
end;

function TGtk3Widget.IsValidHandle: Boolean;
begin
  Result := Assigned(FWidget) and Gtk3IsWidget(FWidget) and not FWidget^.in_destruction;
end;

function TGtk3Widget.IsWidgetOk: Boolean;
begin
  Result := (FWidget <> nil) and Gtk3IsWidget(FWidget);
end;

function TGtk3Widget.IsIconic: Boolean;
begin
  Result := False;
  if IsWidgetOk then
  begin
    if FWidget^.get_window <> nil then
      Result := gdk_window_get_state(FWidget^.get_window) and GDK_WINDOW_STATE_ICONIFIED <> 0;
  end;
end;

function TGtk3Widget.getType: TGType;
begin
  Result := getContainerWidget^.g_type_instance.g_class^.g_type;
end;

function TGtk3Widget.getTypeName: PgChar;
begin
  Result := g_type_name(getType);
end;

procedure TGtk3Widget.lowerWidget;
begin
  if Gtk3IsGdkWindow(FWidget^.window) then
    FWidget^.window^.lower;
end;

procedure TGtk3Widget.raiseWidget;
begin
  if Gtk3IsGdkWindow(FWidget^.window) then
    FWidget^.window^.raise_;
end;

procedure TGtk3Widget.stackUnder(AWidget: PGtkWidget);
begin
  // FWidget^.
end;

function TGtk3Widget.GetCapture: TGtk3Widget;
var
  AHandle: HWND;
begin
  AHandle := HwndFromGtkWidget(gtk_grab_get_current);
  if AHandle <> 0 then
    Result := TGtk3Widget(AHandle);
end;

function TGtk3Widget.SetCapture: HWND;
begin
  Result := HWND(GetCapture);
  gtk_grab_add(GetContainerWidget);
end;

function TGtk3Widget.GtkEventKey(Sender: PGtkWidget; Event: PGdkEvent; AKeyPress: Boolean): Boolean;
  cdecl;
const
  CN_KeyDownMsgs: array[Boolean] of UINT = (CN_KEYDOWN, CN_SYSKEYDOWN);
  CN_KeyUpMsgs: array[Boolean] of UINT = (CN_KEYUP, CN_SYSKEYUP);
  LM_KeyDownMsgs: array[Boolean] of UINT = (LM_KEYDOWN, LM_SYSKEYDOWN);
  LM_KeyUpMsgs: array[Boolean] of UINT = (LM_KEYUP, LM_SYSKEYUP);
  CN_CharMsg: array[Boolean] of UINT = (CN_CHAR, CN_SYSCHAR);
  LM_CharMsg: array[Boolean] of UINT = (LM_CHAR, LM_SYSCHAR);
var
  AEvent: TGdkEventKey;
  Msg: TLMKey;
  CharMsg: TLMChar;
  KeyCode: Word;
  AShiftState: TShiftState;
  AEventString: String;
  KeyValue, ACharCode: Word;
  LCLModifiers: Word;
  IsSysKey: Boolean;
  UTF8Char: TUTF8Char;
  AChar: Char;
  IsArrowKey: Boolean;
begin
  //TODO: finish LCL messaging
  Result := False;
  AEvent := Event^.key;
  FillChar(Msg, SizeOf(Msg), 0);
  AEventString := AEvent.string_;

  if gdk_keyval_is_lower(AEvent.keyval) then
    KeyValue := Word(gdk_keyval_to_upper(AEvent.keyval))
  else
    KeyValue := Word(AEvent.keyval);

  // state=16 = numlock= on.

  LCLModifiers := GtkModifierStateToShiftState(AEvent.state, True);

  if length(AEventString) = 0 then
  begin
    if KeyValue = GDK_KEY_Alt_L then
      LCLModifiers := LCLModifiers or KF_ALTDOWN
    else
    if (KeyValue = GDK_KEY_Control_L) or (KeyValue = GDK_KEY_Control_R)  then
      LCLModifiers := LCLModifiers or MK_CONTROL
    else
    if (KeyValue = GDK_KEY_Shift_L) or (KeyValue = GDK_KEY_Shift_R) then
      LCLModifiers := LCLModifiers or MK_SHIFT;
    // writeln('MODIFIERS BY KEYS ',LCLModifiers);
  end;

  IsSysKey := LCLModifiers and KF_ALTDOWN <> 0;

  if not AKeyPress then
    LCLModifiers := LCLModifiers or KF_UP;

  // else
  //  writeln('KeyRelease: ',dbgsName(LCLObject),' Dump state=',AEvent.state,' hwkey=',KeyCode,' keyvalue=',KeyValue,' modifier=',AEvent.Bitfield0.is_modifier);

  // this is just for testing purposes.
  ACharCode := GdkKeyToLCLKey(KeyValue);
  if KeyValue > VK_UNDEFINED then
    KeyValue := ACharCode; // VK_UNKNOWN;

  if AKeyPress and (ACharCode = VK_TAB) then
  begin

  end;

  IsArrowKey := ((ACharCode = VK_UP) or (ACharCode = VK_DOWN) or (ACharCode = VK_LEFT) or (ACharCode = VK_RIGHT));

  {$IFDEF GTK3DEBUGKEYPRESS}
  if AKeyPress then
    writeln('EVENT KeyPress: ',dbgsName(LCLObject),' Dump state=',AEvent.state,' keyvalue=',KeyValue,' modifier=',AEvent.Bitfield0.is_modifier,
    ' KeyValue ',KeyValue,' MODIFIERS ',LCLModifiers,' CharCode ',ACharCode,' EAT ',EatArrowKeys(ACharCode))
  else
    writeln('EVENT KeyRelease: ',dbgsName(LCLObject),' Dump state=',AEvent.state,' keyvalue=',KeyValue,' modifier=',AEvent.Bitfield0.is_modifier,
    ' KeyValue ',KeyValue,' MODIFIERS ',LCLModifiers,' CharCode ',ACharCode,
    ' EAT ',EatArrowKeys(ACharCode));
  {$ENDIF}

  if (ACharCode <> VK_UNKNOWN) then
  begin
    if AKeyPress then
      Msg.Msg := CN_KeyDownMsgs[IsSysKey]
    else
      Msg.Msg := CN_KeyUpMsgs[IsSysKey];
    Msg.CharCode := ACharCode;
    Msg.KeyData := PtrInt((KeyValue shl 16) or (LCLModifiers shl 16) or $0001);

    NotifyApplicationUserInput(LCLObject, Msg.Msg);

    if not CanSendLCLMessage then
      exit;

    if (DeliverMessage(Msg, True) <> 0) or (Msg.CharCode = VK_UNKNOWN) or EatArrowKeys(ACharCode) then
    begin
      {$IFDEF GTK3DEBUGKEYPRESS}
      DebugLn('CN_KeyDownMsgs handled ... exiting');
      {$ENDIF}
      exit(True);
    end;

    if not CanSendLCLMessage then
      exit;

    if AKeyPress then
      Msg.Msg := LM_KeyDownMsgs[IsSysKey]
    else
      Msg.Msg := LM_KeyUpMsgs[IsSysKey];
    Msg.CharCode := ACharCode;
    Msg.KeyData := PtrInt((KeyValue shl 16) or (LCLModifiers shl 16) or $0001);

    NotifyApplicationUserInput(LCLObject, Msg.Msg);

    if not CanSendLCLMessage then
      exit;

    {$warning workaround for GtkTreeView key bindings.Must find out what LCL does with
     this keys.}
    if IsArrowKey and ([wtListBox,wtListView] * WidgetType <> []) then
    // let gtk3 select cell for now. Must check what LCL does with arrow keys
    // since gtk3 becomes crazy after delivery of this message
    else
    if (DeliverMessage(Msg, True) <> 0) or (Msg.CharCode = 0) then
    begin
      Result := Msg.CharCode = 0;
      {$IFDEF GTK3DEBUGKEYPRESS}
      DebugLn('LM_KeyDownMsgs handled ... exiting ',dbgs(ACharCode),' Result=',dbgs(Result),' AKeyPress=',dbgs(AKeyPress));
      {$ENDIF}
      exit;
    end;

    if not CanSendLCLMessage then
      exit;

  end;

  if AKeyPress and (length(AEventString) > 0) then
  begin
    UTF8Char := AEventString;
    // TODO: If not IsControlKey
    Result := LCLObject.IntfUTF8KeyPress(UTF8Char, 1, IsSysKey);

    if not CanSendLCLMessage then
      exit;

    if Result then
    begin
      {$IFDEF GTK3DEBUGKEYPRESS}
      DebugLn('LCLObject.IntfUTF8KeyPress handled ... exiting');
      {$ENDIF}
      exit;
    end;

    // create the CN_CHAR / CN_SYSCHAR message
    FillChar(CharMsg, SizeOf(CharMsg), 0);
    CharMsg.Msg := CN_CharMsg[IsSysKey];
    CharMsg.KeyData := Msg.KeyData;
    AChar := AEventString[1];
    CharMsg.CharCode := Word(AChar);
    NotifyApplicationUserInput(LCLObject, CharMsg.Msg);

    if not CanSendLCLMessage then
      exit;

    Result := (DeliverMessage(CharMsg, True) <> 0) or (CharMsg.CharCode = VK_UNKNOWN);

    if not CanSendLCLMessage then
      exit;

    if Result then
    begin
      {$IFDEF GTK3DEBUGKEYPRESS}
      DebugLn('CN_CharMsg handled ... exiting');
      {$ENDIF}
      exit;
    end;

    //Send a LM_(SYS)CHAR
    CharMsg.Msg := LM_CharMsg[IsSysKey];

    NotifyApplicationUserInput(LCLObject, CharMsg.Msg);

    if not CanSendLCLMessage then
      exit;

    DeliverMessage(CharMsg, True);

    if not CanSendLCLMessage then
      exit;
  end;
  if AKeyPress then
  begin
    {$IFDEF GTK3DEBUGKEYPRESS}
    if Msg.CharCode in FKeysToEat then
    begin
      DebugLn('EVENT: ******* KeyPress charcode is in keys to eat (FKeysToEat), charcode=',dbgs(Msg.CharCode));
    end;
    {$ENDIF}
    Result := Msg.CharCode in FKeysToEat;
  end;
end;

function TGtk3Widget.GtkEventMouse(Sender: PGtkWidget; Event: PGdkEvent): Boolean;
  cdecl;
var
  Msg: TLMMouse;
  MsgPopup : TLMMouse;
  MousePos: TPoint;
  MButton: guint;
begin
  Result := False;
  {$IF DEFINED(GTK3DEBUGEVENTS) OR DEFINED(GTK3DEBUGMOUSE)}
  DebugLn('TGtk3Widget.GtkEventMouse ',dbgsName(LCLObject),
    ' propagate=',dbgs(not (Event^.button.send_event = NO_PROPAGATION_TO_PARENT)));
  {$ENDIF}
  if Event^.button.send_event = NO_PROPAGATION_TO_PARENT then
    exit;

  FillChar(Msg, SizeOf(Msg), #0);

  MousePos.x := Round(Event^.button.x);
  MousePos.y := Round(Event^.button.y);

  OffsetMousePos(@MousePos);

  Msg.Keys := GdkModifierStateToLCL(Event^.button.state, False);

  Msg.XPos := SmallInt(MousePos.X);
  Msg.YPos := SmallInt(MousePos.Y);

  MButton := Event^.button.button;

  case Event^.type_ of
    // GDK_BUTTON_PRESS
    4:
    begin
      if MButton = GTK3_LEFT_BUTTON then
        Msg.Msg := LM_LBUTTONDOWN
      else
      if MButton = GTK3_RIGHT_BUTTON then
        Msg.Msg := LM_RBUTTONDOWN
      else
      if MButton = GTK3_MIDDLE_BUTTON then
        Msg.Msg := LM_MBUTTONDOWN;
    end;
    // GDK_BUTTON2_PRESS -> double click
    5: Msg.Msg := LM_LBUTTONDBLCLK;
    // GDK_BUTTON_RELEASE: TGdkEventType = 7;
    7:
    begin
      if MButton = GTK3_LEFT_BUTTON then
        Msg.Msg := LM_LBUTTONUP
      else
      if MButton = GTK3_RIGHT_BUTTON then
        Msg.Msg := LM_RBUTTONUP
      else
      if MButton = GTK3_MIDDLE_BUTTON then
        Msg.Msg := LM_MBUTTONUP;
    end;
  end;
  {$IF DEFINED(GTK3DEBUGEVENTS) OR DEFINED(GTK3DEBUGMOUSE)}
  DebugLn('TGtk3Widget.GtkEventMouse ',dbgsName(LCLObject),
    ' msg=',dbgs(msg.Msg), ' point=',dbgs(Msg.XPos),',',dbgs(Msg.YPos));
  {$ENDIF}
  NotifyApplicationUserInput(LCLObject, Msg.Msg);
  Event^.button.send_event := NO_PROPAGATION_TO_PARENT;

  Result := false;
  if Msg.Msg = LM_RBUTTONDOWN then
  begin
    MsgPopup := Msg;
    MsgPopup.Msg := LM_CONTEXTMENU;
    MsgPopup.XPos := SmallInt(Round(Event^.button.x_root));
    MsgPopup.YPos := SmallInt(Round(Event^.button.y_root));
    Result := DeliverMessage(MsgPopup, True) <> 0;
  end;
  if not Result then
    Result := DeliverMessage(Msg, True) <> 0;
  if Event^.type_ = GDK_BUTTON_RELEASE then
  begin
    Msg.Msg := LM_CLICKED;
    DeliverMessage(Msg, True);
  end;
end;

function TGtk3Widget.GetVisible: Boolean;
begin
  Result := Assigned(FWidget) and FWidget^.visible;
end;

procedure TGtk3Widget.SetEnabled(AValue: Boolean);
begin
  if IsWidgetOK then
    FWidget^.set_sensitive(AValue);
end;

procedure TGtk3Widget.SetFont(AValue: PPangoFontDescription);
begin
  if IsWidgetOk then
  begin
    GetContainerWidget^.override_font(AValue);
  end;
end;

procedure TGtk3Widget.SetFontColor(AValue: TColor);
var
  AColor: TGdkRGBA;
  i: TGtkStateType;
begin
  if IsWidgetOK then
  begin
    AColor := TColortoTGdkRGBA(AValue);
    if FWidget <> GetContainerWidget then
    begin
      with FWidget^ do
      begin
        for i := GTK_STATE_NORMAL to GTK_STATE_INSENSITIVE do
          override_color(i, @AColor);
      end;
    end;
    with GetContainerWidget^ do
    begin
      for i := GTK_STATE_NORMAL to GTK_STATE_INSENSITIVE do
        override_color(i, @AColor);
    end;
  end;
end;

procedure TGtk3Widget.SetColor(AValue: TColor);
var
  AColor: TGdkRGBA;
  i: TGtkStateType;
  ARgba: TGdkRGBA;
  R: Double;
  G: Double;
  B: Double;
begin
  // new way (gtk3) but still buggy
  if IsWidgetOK and (0 > 1) then
  begin
    if AValue = clDefault then
    begin
      (*
      with FDefaultRGBA do
      begin
        writeln('clDefault ',Format('R %2.2n G %2.2n B %2.2n A %2.2n',[R, G, B , Alpha]));
        ARgba.red := R;
        ARgba.green := G;
        ARgba.blue := B;
        ARgba.alpha := Alpha;
      end;
      *)
    end else
    begin
      ARgba := TColortoTGdkRGBA(AValue);
      {$info GTK3: set GdkRGBA.alpah to 1.0?}

      {ColorToCairoRGB(ColorToRGB(AValue), R, G, B);
      ARgba.red := R;
      ARgba.green := G;
      ARgba.blue := B;
      ARgba.alpha := 1.0;}
    end;
    if FWidget <> GetContainerWidget then
    begin
      with FWidget^ do
      begin
        for i := GTK_STATE_NORMAL to GTK_STATE_INSENSITIVE do
        begin
          if AValue = clDefault then
          begin
            ARgba.red := FWidgetRGBA[i].R;
            ARgba.green := FWidgetRGBA[i].G;
            ARgba.blue := FWidgetRGBA[i].B;
            ARgba.alpha := FWidgetRGBA[i].Alpha;
          end;
          FWidget^.override_background_color(i, @ARgba);
        end;
      end;
    end;
    with GetContainerWidget^ do
    begin
      for i := GTK_STATE_NORMAL to GTK_STATE_INSENSITIVE do
      begin
        //if AVAlue = clDefault then
        //  GetContainerWidget^.get_style_context^.get_background_color(GTK_STATE_NORMAL, @ARgba);
        if AValue = clDefault then
        begin
          ARgba.red := FCentralWidgetRGBA[i].R;
          ARgba.green := FCentralWidgetRGBA[i].G;
          ARgba.blue := FCentralWidgetRGBA[i].B;
          ARgba.alpha := FCentralWidgetRGBA[i].Alpha;
        end;
        GetContainerWidget^.override_background_color(i, @ARgba);
      end;
    end;
  end;

  if IsWidgetOK then
  begin
    AColor := TColortoTGdkRGBA(AValue);
    if FWidget <> GetContainerWidget then
    begin
      with FWidget^ do
      begin
        for i := GTK_STATE_NORMAL to GTK_STATE_INSENSITIVE do
          if AValue = clDefault then
            override_background_color(i, nil)
          else
            override_background_color(i, @AColor);
      end;
    end;
    with GetContainerWidget^ do
    begin
      for i := GTK_STATE_NORMAL to GTK_STATE_INSENSITIVE do
      begin
        if AValue = clDefault then
          override_background_color(i, nil)
        else
          override_background_color(i, @AColor);
      end;
    end;
  end;
end;

function TGtk3Widget.GetStyleContext: PGtkStyleContext;
begin
  Result := nil;
  if IsWidgetOK then
    Result := GetContainerWidget^.get_style_context;
end;

function TGtk3Widget.GetFont: PPangoFontDescription;
var
  AContext: PPangoContext;
begin
  Result := nil;
  if IsWidgetOK then
  begin
    AContext := GetContainerWidget^.get_pango_context;
    Result := pango_context_get_font_description(AContext);
  end;
end;

function TGtk3Widget.CanSendLCLMessage: Boolean;
begin
  Result := IsWidgetOk and (LCLObject <> nil);
end;

function TGtk3Widget.GetCairoContext: Pcairo_t;
begin
  Result := FCairoContext;
end;

function TGtk3Widget.GetEnabled: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := FWidget^.get_sensitive;
end;

function TGtk3Widget.GetFontColor: TColor;
var
  AStyle: PGtkStyleContext;
  AGdkRGBA: TGdkRGBA;
begin
  Result := clDefault;
  if IsWidgetOK then
  begin
    AStyle := GetStyleContext;
    AStyle^.get_background_color(GTK_STATE_NORMAL, @AGdkRGBA);
    Result := TGdkRGBAToTColor(AGdkRGBA);
  end;
end;

function TGtk3Widget.GetColor: TColor;
var
  AStyle: PGtkStyleContext;
  AColor: TGdkRGBA;
begin
  Result := clDefault;
  if IsWidgetOK then
  begin
    AStyle := GetStyleContext;
    AStyle^.get_background_color(GTK_STATE_NORMAL, @AColor);
    Result := TGdkRGBAToTColor(AColor);
  end;
end;

procedure TGtk3Widget.SetStyleContext(AValue: PGtkStyleContext);
begin
  {$NOTE Gtk3: Find a nice way to assign StyleContext}
  {if IsWidgetOK then
    GetContainerWidget^.set_style(AValue);}
end;

function TGtk3Widget.getText: String;
begin
  Result := '';
end;

procedure TGtk3Widget.setText(AValue: String);
begin
  // DebugLn('WARNING: ',dbgsName(LCLObject),' self=',dbgsName(Self),' does not implement setText !');
end;

procedure TGtk3Widget.SetVisible(AValue: Boolean);
begin
  if IsWidgetOK then
    FWidget^.Visible := AValue;
end;

function TGtk3Widget.QueryInterface(constref iid: TGuid; out obj): LongInt;
  cdecl;
begin
  if GetInterface(iid, obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TGtk3Widget._AddRef: LongInt; cdecl;
begin
  Result := -1; // no ref counting
end;

function TGtk3Widget._Release: LongInt; cdecl;
begin
  Result := -1;
end;

function TGtk3Widget.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := AKey in [VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN];
end;

function TGtk3Widget.GetContext: HDC;
begin
  Result := FContext;
end;

function TGtk3Widget.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  Result := PGtkWidget(TGtkWidget.newv(32, 0 ,nil));
end;

procedure TGtk3Widget.DestroyWidget;
begin
  if IsWidgetOk and FOwnWidget then
    FWidget^.destroy_;
  FWidget := nil;
end;

procedure TGtk3Widget.DoBeforeLCLPaint;
begin
  //
end;

constructor TGtk3Widget.Create(const AWinControl: TWinControl;
  const AParams: TCreateParams);
begin
  inherited Create;
  FContext := 0;
  FHasPaint := False;
  FWidget := nil;
  FOwner := nil;
  FCentralWidget := nil;
  FOwnWidget := True;
  // Initializes the properties
  FProps := nil;
  LCLObject := AWinControl;
  FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  // FHasPaint := False;

  FParams := AParams;
  InitializeWidget;
end;

constructor TGtk3Widget.CreateFrom(const AWinControl: TWinControl;
  AWidget: PGtkWidget);
begin
  inherited Create;
  FContext := 0;
  FHasPaint := False;
  FWidget := nil;
  FOwner := nil;
  FCentralWidget := nil;
  FOwnWidget := False;
  // Initializes the properties
  FProps := nil;
  LCLObject := AWinControl;
  FWidget := AWidget;
  // FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  // FHasPaint := False;
end;

procedure TGtk3Widget.InitializeWidget;
var
  ARect: TGdkRectangle;
  ARgba: TGdkRGBA;
  i: TGtkStateType;
begin
  FFocusableByMouse := False;
  FCentralWidget := nil;
  FCairoContext := nil;
  FContext := 0;
  FEnterLeaveTime := 0;

  FWidgetType := [wtWidget];
  FWidget := CreateWidget(FParams);

  // connect events
  if not (wtWindow in FWidgetType) then
  begin
    FWidget^.show_all;
    with ARect do
    begin
      x := LCLObject.Left;
      y := LCLObject.Top;
      width := LCLObject.Width;
      height := LCLObject.Height;
    end;
    FWidget^.set_allocation(@ARect);
  end;
  LCLIntf.SetProp(HWND(Self),'lclwidget',Self);

  // move signal connections into attach events
  FWidget^.set_events(GDK_ALL_EVENTS_MASK);
  g_signal_connect_data(FWidget, 'event', TGCallback(@Gtk3WidgetEvent), Self, nil, 0);


  for i := GTK_STATE_NORMAL to GTK_STATE_INSENSITIVE do
  begin
    FWidget^.get_style_context^.get_background_color(i, @ARgba);
    with FWidgetRGBA[i] do
    begin
      R := ARgba.red;
      G := ARgba.green;
      B := ARgba.blue;
      Alpha := ARgba.alpha;
    end;
  end;


  if FCentralWidget <> nil then
  begin
    FCentralWidget^.set_events(GDK_ALL_EVENTS_MASK);
    g_signal_connect_data(FCentralWidget, 'event', TGCallback(@Gtk3WidgetEvent), Self, nil, 0);
    for i := GTK_STATE_NORMAL to GTK_STATE_INSENSITIVE do
    begin
      FCentralWidget^.get_style_context^.get_background_color(i, @ARgba);
      with FCentralWidgetRGBA[i] do
      begin
        R := ARgba.red;
        G := ARgba.green;
        B := ARgba.blue;
        Alpha := ARgba.alpha;
      end;
    end;
  end else
  begin
    for i := GTK_STATE_NORMAL to GTK_STATE_INSENSITIVE do
      FCentralWidgetRGBA[i] := FWidgetRGBA[i];
  end;
  g_signal_connect_data(GetContainerWidget,'draw', TGCallback(@Gtk3DrawWidget), Self, nil, 0);
  g_signal_connect_data(GetContainerWidget,'scroll-event', TGCallback(@Gtk3ScrollEvent), Self, nil, 0);

  // must hide all by default
  FWidget^.hide;

  g_signal_connect_data(FWidget,'hide', TGCallback(@Gtk3WidgetHide), Self, nil, 0);
  g_signal_connect_data(FWidget,'show', TGCallback(@Gtk3WidgetShow), Self, nil, 0);
  g_signal_connect_data(FWidget,'map', TGCallback(@Gtk3MapWidget), Self, nil, 0);
  g_signal_connect_data(FWidget,'size-allocate',TGCallback(@Gtk3SizeAllocate), Self, nil, 0);
  // g_signal_connect_data(FWidget, 'motion_notify_event', TGCallback(@Gtk3MotionNotifyEvent), LCLObject, nil, 0);
end;

procedure TGtk3Widget.DeInitializeWidget;
begin

end;

procedure TGtk3Widget.RecreateWidget;
begin

end;

procedure TGtk3Widget.DestroyNotify(AWidget: PGtkWidget);
begin

end;

destructor TGtk3Widget.Destroy;
begin
  DestroyWidget;
  inherited Destroy;
end;

function TGtk3Widget.CanFocus: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := FWidget^.can_focus or GetContainerWidget^.can_focus;
end;

function TGtk3Widget.GetFocusableByMouse: Boolean;
begin
  Result := FFocusableByMouse;
end;

function TGtk3Widget.getClientOffset: TPoint;
var
  Allocation: TGtkAllocation;
  R: TRect;
  B: Boolean;
begin
  {offset between inner and outer rect of widget.
   It tricky since some widgets have regular offset eg
   Parent (FWidget) = (120,80) Child (FCentralWidget) = (2,2)
   but some are
   Parent (FWidget) = (120,80) Child (FCentralWidget) = (122,82).
   Such widgets are usually those with FCentralWidget^.get_has_window}
  Result := Point(0, 0);
  if Widget <> getContainerWidget then
  begin
    GetContainerWidget^.get_allocation(@Allocation);
    Result.X := Allocation.X;
    Result.Y := Allocation.Y;
  end else
    exit;
  R := getClientBounds;
  Result := Point(Result.x + R.Left, Result.y + R.Top);
end;

function TGtk3Widget.getWidgetPos: TPoint;
var
  Allocation: TGtkAllocation;
begin
  Result := Point(0, 0);
  if IsWidgetOk then
  begin
    FWidget^.get_allocation(@Allocation);
    Result := Point(Allocation.X, Allocation.Y);
  end;
end;

procedure TGtk3Widget.OffsetMousePos(APoint: PPoint);
begin
  with getClientOffset do
  begin
    dec(APoint^.x, x);
    dec(APoint^.y, y);
  end;
end;

function TGtk3Widget.DeliverMessage(var Msg; const AIsInputEvent: Boolean
  ): LRESULT;
var
  AEvent: Cardinal;
begin
  Result := LRESULT(AIsInputEvent);
  if LCLObject = nil then
    Exit;
  AEvent := TLMessage(Msg).Msg;
  try
    if LCLObject.HandleAllocated then
    begin
      LCLObject.WindowProc(TLMessage(Msg));
      Result := TLMessage(Msg).Result;
    end;
  except
    Application.HandleException(nil);
  end;
end;

function TGtk3Widget.getClientRect: TRect;
var
  AAlloc: TGtkAllocation;
begin
  Result := Rect(0, 0, 0, 0);
  if not IsWidgetOK then
    exit;
  if GetContainerWidget^.get_realized then
  begin
    GetContainerWidget^.get_allocation(@AAlloc);
    Result := Rect(AAlloc.x, AAlloc.y, AAlloc.width + AAlloc.x,AAlloc.height + AAlloc.y);
  end else
  if FWidget^.get_realized then
  begin
    FWidget^.get_allocation(@AAlloc);
    Result := Rect(AAlloc.x, AAlloc.y, AAlloc.width + AAlloc.x,AAlloc.height + AAlloc.y);
  end;

  OffsetRect(Result, -Result.Left, -Result.Top);
end;

function TGtk3Widget.getClientBounds: TRect;
var
  AAlloc: TGtkAllocation;
begin
  Result := Rect(0, 0, 0, 0);
  if IsWidgetOk then
  begin
    if FWidget^.get_realized then
    begin
      FWidget^.get_allocation(@AAlloc);
      Result := Rect(AAlloc.x, AAlloc.y, AAlloc.width + AAlloc.x,AAlloc.height + AAlloc.y);
    end else
    if GetContainerWidget^.get_realized then
    begin
      GetContainerWidget^.get_allocation(@AAlloc);
      Result := Rect(AAlloc.x, AAlloc.y, AAlloc.width + AAlloc.x,AAlloc.height + AAlloc.y);
    end;
  end;
end;

function TGtk3Widget.GetContainerWidget: PGtkWidget;
begin
  if Assigned(FCentralWidget) then
    Result := FCentralWidget
  else
    Result := FWidget;
end;

function TGtk3Widget.GetPosition(out APoint: TPoint): Boolean;
var
  ALeft, ATop: gint;
begin
  APoint := Point(0, 0);
  Result := False;
  if IsWidgetOk then
  begin
    if FWidget^.get_realized then
    begin
      if FWidget^.get_has_window then
      begin
        gdk_window_get_position(FWidget^.window, @ALeft, @ATop);
        APoint.X := ALeft;
        APoint.Y := ATop;
        Result := True;
      end;
    end;
    if not Result then
    begin
      APoint := Point(LCLObject.Left, LCLObject.Top);
      Result := True;
    end;
  end;
end;

procedure TGtk3Widget.Release;
begin
  LCLObject := nil;
  Free;
end;

procedure TGtk3Widget.Hide;
begin
  if Assigned(FWidget) then
    FWidget^.hide;
end;

function TGtk3Widget.getParent: TGtk3Widget;
begin
  Result := Gtk3WidgetFromGtkWidget(Widget^.get_parent);
end;

function TGtk3Widget.GetWindow: PGdkWindow;
begin
  Result := FWidget^.window;
end;

procedure TGtk3Widget.Move(ALeft, ATop: Integer);
var
  AParent: TGtk3Widget;
  Allocation: TGtkAllocation;
begin
  AParent := getParent;
  if (AParent <> nil) then
  begin
    if (wtContainer in AParent.WidgetType) then
      PGtkFixed(AParent.GetContainerWidget)^.move(FWidget, ALeft, ATop)
    else
    if (wtLayout in AParent.WidgetType) then
      PGtkLayout(AParent.GetContainerWidget)^.move(FWidget, ALeft, ATop);
  end;
end;

procedure TGtk3Widget.Activate;
begin
  if IsWidgetOK then
  begin
    if not FWidget^.visible then
      exit;
    if Gtk3IsGdkWindow(FWidget^.window) then
      FWidget^.window^.raise_
    else
    begin
      FWidget^.get_parent_window^.raise_;
    end;
    if FWidget^.can_focus then
      FWidget^.grab_focus;
  end;
end;

procedure TGtk3Widget.preferredSize(var PreferredWidth,
  PreferredHeight: integer; WithThemeSpace: Boolean);
var
  ABorder: TGtkBorder;
  AMinH: gint;
  AMinW: gint;
begin
  if IsWidgetOK then
  begin
    {$IFDEF GTK3DEBUGPREFERREDSIZE}
    Widget^.get_size_request(@AMinW, @AMinH);
    DebugLn('>',dbgsName(LCLObject),'.preferredSize W=',dbgs(PreferredWidth),' H=',dbgs(PreferredHeight),' WithThemeSpace ',dbgs(WithThemeSpace),' AMinW=',dbgs(AMinW),' AMinH=',dbgs(AMinH));
    {$ENDIF}
    GetContainerWidget^.get_preferred_height(@AMinH, @PreferredHeight);
    GetContainerWidget^.get_preferred_width(@AMinW, @PreferredWidth);
    {$IFDEF GTK3DEBUGPREFERREDSIZE}
    if WithThemeSpace then
    begin
      GetContainerWidget^.get_style_context^.get_margin(GTK_STATE_NORMAL, @ABorder);
      with ABorder do
        DebugLn('BorderSpaces ',Format('L %d T %d R %d B %d',[Left, Top, Right, Bottom]));
      GetContainerWidget^.get_style_context^.get_padding(GTK_STATE_NORMAL, @ABorder);
      with ABorder do
        DebugLn('Padding ',Format('L %d T %d R %d B %d',[Left, Top, Right, Bottom]));
    end;
    DebugLn('<',dbgsName(LCLObject),'.preferredSize W=',dbgs(PreferredWidth),' H=',dbgs(PreferredHeight),' WithThemeSpace ',dbgs(WithThemeSpace),' AMinH=',dbgs(AMinH),' AMinW=',dbgs(AMinW));
    {$ENDIF}
  end;
end;

procedure TGtk3Widget.SetCursor(ACursor: HCURSOR);
begin
  if IsWidgetOk then
  begin
    if GetContainerWidget^.get_has_window and Gtk3IsGdkWindow(GetContainerWidget^.window) then
      SetWindowCursor(GetContainerWidget^.window, ACursor, False, True)
    else
    if Widget^.get_has_window and Gtk3IsGdkWindow(Widget^.window) then
      SetWindowCursor(Widget^.window, ACursor, False, True);
  end;
end;

procedure TGtk3Widget.SetFocus;
begin
  if GetContainerWidget^.can_focus then
    GetContainerWidget^.grab_focus
  else
  if FWidget^.can_focus then
    FWidget^.grab_focus;
end;

procedure TGtk3Widget.SetParent(AParent: TGtk3Widget; const ALeft, ATop: Integer
  );
var
  Allocation: TGtkAllocation;
  R: TRect;
  W,H: Integer;
  AParentParent: PGtkWidget;
begin
  if wtLayout in AParent.WidgetType then
    PGtkLayout(AParent.GetContainerWidget)^.put(FWidget, ALeft, ATop)
  else
  if wtContainer in AParent.WidgetType then
    PGtkFixed(AParent.GetContainerWidget)^.put(FWidget, ALeft, ATop)
  else
  if wtNotebook in AParent.WidgetType then
    // do nothing !
  else
    FWidget^.set_parent(AParent.GetContainerWidget);
end;

procedure TGtk3Widget.Show;
begin
  if IsValidHandle then
    FWidget^.show;
end;

procedure TGtk3Widget.ShowAll;
begin
  if IsValidHandle then
    FWidget^.show_all;
end;

procedure TGtk3Widget.Update(ARect: PRect);
begin
  if IsWidgetOK then
  begin
    if ARect <> nil then
    begin
      with ARect^ do
        FWidget^.queue_draw_area(Left, Top, Right - Left, Bottom - Top);
      if FWidget <> GetContainerWidget then
        with ARect^ do
          GetContainerWidget^.queue_draw_area(Left, Top, Right - Left, Bottom - Top);
    end else
    begin
      FWidget^.queue_draw;
      if FWidget <> GetContainerWidget then
        GetContainerWidget^.queue_draw;
    end;
  end;
end;

{ TGtk3StatusBar }

function TGtk3StatusBar.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AStatusBar: TStatusBar;
begin
  AStatusBar := TStatusBar(LCLObject);
  Result := TGtkEventBox.new;
  FCentralWidget := TGtkHBox.new(GTK_ORIENTATION_HORIZONTAL, 1);
  PGtkBox(FCentralWidget)^.set_homogeneous(True);
  PGtkEventBox(Result)^.add(FCentralWidget);
  //TODO: add routines to set panels
end;

{ TGtk3Panel }

procedure TGtk3Panel.SetColor(AValue: TColor);
var
  AGdkRGBA: TGdkRGBA;
  AColor: TGdkColor;
begin
  inherited SetColor(AValue);
  exit;
  if (AValue = clDefault) or (AValue = clBackground) then
  begin
    // this is just to test if we can get transparent panel again
    // clDefault must be extracted from style

    // nil resets color to gtk default
    FWidget^.override_background_color(GTK_STATE_FLAG_NORMAL, nil);
    StyleContext^.get_background_color(GTK_STATE_FLAG_NORMAL, @AGdkRGBA);

    // writeln('ACOLOR R=',AColor.Red,' G=',AColor.green,' B=',AColor.blue);
    // AColor := TColortoTGDKColor(AValue);
    {AGdkRGBA.alpha := 0;
    AGdkRGBA.red := AColor.red / 65535.00;
    AGdkRGBA.blue := AColor.blue / 65535.00;
    AGdkRGBA.green := AColor.red / 65535.00;}
    FWidget^.override_background_color(GTK_STATE_FLAG_NORMAL, @AGdkRGBA);
    FWidget^.override_background_color(GTK_STATE_FLAG_ACTIVE, @AGdkRGBA);
    FWidget^.override_background_color(GTK_STATE_FLAG_FOCUSED, @AGdkRGBA);
    FWidget^.override_background_color(GTK_STATE_FLAG_PRELIGHT, @AGdkRGBA);
    FWidget^.override_background_color(GTK_STATE_FLAG_SELECTED, @AGdkRGBA);
  end else
  begin
    AColor := TColortoTGDKColor(AValue);
    // writeln('ACOLOR R=',AColor.Red,' G=',AColor.green,' B=',AColor.blue);
    //inherited SetColor(AValue);
  end;
end;

function TGtk3Panel.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AGdkRGBA: TGdkRGBA;
  AColor: TGdkColor;
begin
  FHasPaint := True;
  FBorderStyle := bsNone;
  FBevelInner := bvNone;
  FBevelOuter := bvNone;
  // wtLayout = using GtkLayout
  // FWidgetType := [wtWidget, wtLayout];
  // Result := TGtkLayout.new(nil, nil);
  FWidgetType := [wtWidget, wtContainer];
  Result := TGtkFixed.new;
  Result^.set_has_window(True);
  // AColor := Result^.style^.bg[0];
  // writeln('BG COLOR R=',AColor.red,' G=',AColor.green,' B=',AColor.blue);
  // now we make panel completely transparent.
  // SetColor must usr override_background_color for panel
  // we must implement cairo_pattern_t since background can be brush
  AGdkRGBA.alpha := 0;
  AGdkRGBA.red := 0; // AColor.Red / 65535.00;
  AGdkRGBA.blue := 0; // AColor.Blue / 65535.00;
  AGdkRGBA.green := 0; // AColor.green / 65535.00;
  Result^.override_background_color(GTK_STATE_FLAG_NORMAL, @AGdkRGBA);
  Result^.override_background_color(GTK_STATE_FLAG_ACTIVE, @AGdkRGBA);
  Result^.override_background_color(GTK_STATE_FLAG_FOCUSED, @AGdkRGBA);
  Result^.override_background_color(GTK_STATE_FLAG_PRELIGHT, @AGdkRGBA);
  Result^.override_background_color(GTK_STATE_FLAG_SELECTED, @AGdkRGBA);
end;

procedure TGtk3Panel.DoBeforeLCLPaint;
var
  DC: TGtk3DeviceContext;
begin
  inherited DoBeforeLCLPaint;
  // example how to paint borderstyle/bevels of TPanel before we send event to lcl
  DC := TGtk3DeviceContext(FContext);
  if not Visible then
    exit;
  if BorderStyle <> bsNone then
    DC.drawRect(0, 0, LCLObject.Width, LCLObject.Height, LCLObject.Color <> clDefault);
end;

function TGtk3Panel.getText: String;
begin
  Result := FText;
end;

procedure TGtk3Panel.setText(AValue: String);
begin
  if FText = AValue then
    exit;
  FText := AValue;
  if Self.Visible then
    FWidget^.queue_draw;
end;

{ TGtk3GroupBox }

function TGtk3GroupBox.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FHasPaint := True;
  //dont use layout for now
  FWidgetType := [wtWidget, wtContainer, wtGroupBox];
  Result := TGtkFrame.new('');
  // FCentralWidget := TGtkLayout.new(nil, nil);
  FCentralWidget := TGtkFixed.new;
  PGtkBin(Result)^.add(FCentralWidget);
  FCentralWidget^.set_has_window(True);
end;

function TGtk3GroupBox.getText: String;
begin
  Result := '';
  if IsWidgetOK then
  begin
    if PGtkFrame(Widget)^.get_label_widget = nil then
      exit;
    Result := PGtkFrame(Widget)^.get_label;
  end;
end;

procedure TGtk3GroupBox.setText(AValue: String);
begin
  if IsWidgetOK then
  begin
    if AValue = '' then
      PGtkFrame(Widget)^.set_label_widget(nil)
      // maybe DoAdjustClientRect here
    else
    begin
      if PGtkFrame(Widget)^.get_label_widget = nil then
        PGtkFrame(Widget)^.set_label_widget(TGtkLabel.new(''));
      PGtkFrame(Widget)^.set_label(PgChar(AValue));
    end;
  end;
end;


{ TGtk3Editable }

function gtk3EditableDelayedSelStart(AData: Pointer): gboolean; cdecl;
var
  AWidget: PGtkEditable;
  AEditable: TGtk3Editable;
begin
  Result := False;
  AEditable := TGtk3Editable(AData);
  AWidget := PGtkEditable(TGtk3Widget(AData).Widget);
  if (AEditable.PrivateCursorPos <> -1) and (AEditable.PrivateSelection <> -1) then
  begin
    gtk_editable_select_region(AWidget,AEditable.PrivateCursorPos, AEditable.PrivateSelection);
    // gtk_editable_set_position(AWidget, TGtk3Editable(AData).PrivateCursorPos);
  end;
  AEditable.PrivateCursorPos := -1;
  AEditable.PrivateSelection := -1;
  g_idle_remove_by_data(AData);
end;

function TGtk3Editable.GetReadOnly: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := not PGtkEditable(FWidget)^.get_editable;
end;

procedure TGtk3Editable.SetReadOnly(AValue: Boolean);
begin
  if IsWidgetOK then
    PGtkEditable(FWidget)^.set_editable(not AValue);
end;

function TGtk3Editable.getCaretPos: TPoint;
begin
  Result := Point(0, 0);
  if not IsWidgetOk then
    exit;
  Result.X := PGtkEditable(FWidget)^.get_position;
end;

procedure TGtk3Editable.SetCaretPos(AValue: TPoint);
begin
  if not IsWidgetOk then
    exit;
  PGtkEditable(FWidget)^.set_position(AValue.X);
end;

function TGtk3Editable.getSelStart: Integer;
var
  AStart: gint;
  AStop: gint;
begin
  Result := 0;
  if not IsWidgetOk then
    exit;
  if PGtkEditable(FWidget)^.get_selection_bounds(@AStart, @AStop) then
  begin
    Result := AStart;
  end;
end;

function TGtk3Editable.getSelLength: Integer;
var
  AStart: gint;
  AStop: gint;
begin
  Result := 0;
  if not IsWidgetOk then
    exit;
  if PGtkEditable(FWidget)^.get_selection_bounds(@AStart, @AStop) then
  begin
    Result := AStop - AStart;
  end;
end;

procedure TGtk3Editable.setSelStart(AValue: Integer);
var
  AStart: gint;
  AStop: gint;
begin
  if not IsWidgetOk then
    exit;
  CaretPos := Point(AValue, 0);
  (*
  if InUpdate then
  begin
    PrivateCursorPos := AValue;
    CaretPos := Point(AValue, 0);
    // setDelayed when mouse events are finished.
    // This is needed to SetSelStart/SetSelLength inside changed event of text edit
    // g_idle_add(@gtk3EditableDelayedSelStart, Self);
  end else
    CaretPos := Point(AValue, 0);
    *)
  // DebugLn('TGtk3Editable.SetSelStart ',dbgsName(LCLObject),' value=',dbgs(AValue));
  (*
  PGtkEditable(FWidget)^.get_selection_bounds(@AStart, @AStop);
  if AStop < AValue then
    AStop := AValue;
  PGtkEditable(FWidget)^.select_region(AValue, AStop);
  *)
end;

procedure TGtk3Editable.setSelLength(AValue: Integer);
var
  AStart: gint;
  AStop: gint;
begin
  if not IsWidgetOk then
    exit;
  PGtkEditable(FWidget)^.get_selection_bounds(@AStart, @AStop);
  AStart := CaretPos.X;
  // DebugLn('TGtk3Editable.SetSelLength ',dbgsName(LCLObject),' value=',dbgs(AValue),' AStart=',dbgs(AStart),' InUpdate ',dbgs(InUpdate));
  if InUpdate then
  begin
    PrivateCursorPos := AStart;
    PrivateSelection := AValue;
    // g_idle_add(@gtk3EditableDelayedSelStart, Self)
    // setDelayed later
    PGtkEditable(FWidget)^.select_region(AStart, AStart + AValue)
  end else
    PGtkEditable(FWidget)^.select_region(AStart, AStart + AValue);
end;

{ TGtk3Entry }

procedure Gtk3EntryDeletedText(AEntry: PGtkEntryBuffer; APosition: guint; ANumChars: guint; AData: GPointer); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := CM_TEXTCHANGED;
  TGtk3Widget(AData).DeliverMessage(Msg);
end;

procedure Gtk3EntryInsertedText(AEntry: PGtkEntryBuffer; APosition: guint; AChars: PGChar; ANumChars: guint; AData: GPointer); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := CM_TEXTCHANGED;
  TGtk3Widget(AData).DeliverMessage(Msg);
end;

procedure Gtk3EntryChanged(AEntry: PGtkEntryBuffer; AData: GPointer); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := CM_TEXTCHANGED;
  TGtk3Widget(AData).DeliverMessage(Msg);
end;

function TGtk3Entry.GetAlignment: TAlignment;
var
  AFloat: GFloat;
begin
  Result := taLeftJustify;
  if not IsWidgetOk then
    exit;
  AFloat := PGtkEntry(FWidget)^.get_alignment;
  if AFloat = 1 then
    Result := taRightJustify
  else
  if AFloat = 0.5 then
    Result := taCenter;
end;

procedure TGtk3Entry.SetAlignment(AValue: TAlignment);
var
  AFloat: GFloat;
begin
  AFloat := 0;
  if not IsWidgetOk then
    exit;
  case AValue of
    taCenter: AFloat := 0.5;
    taRightJustify: AFloat := 1.0;
  end;
  PGtkEntry(FWidget)^.set_alignment(AFloat);
end;

function TGtk3Entry.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := AKey in [VK_UP, VK_DOWN];
end;

function TGtk3Entry.getText: String;
begin
  if IsValidHandle and IsWidgetOk then
    Result := StrPas(PGtkEntry(Widget)^.get_text)
  else
    Result := '';
end;

procedure TGtk3Entry.setText(AValue: String);
begin
  if IsValidHandle and IsWidgetOK then
    PGtkEntry(Widget)^.set_text(PgChar(AValue));
end;

function TGtk3Entry.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  Result := PGtkWidget(TGtkEntry.new);
  FWidgetType := FWidgetType + [wtEntry];
  PrivateCursorPos := -1;
  PrivateSelection := -1;
end;

procedure TGtk3Entry.InitializeWidget;
begin
  inherited InitializeWidget;
  g_signal_connect_data(PGtkEntry(FWidget), 'changed', TGCallback(@Gtk3EntryChanged), Self, nil, 0);
  //g_signal_connect_data(PGtkEntry(FWidget)^.get_buffer, 'deleted-text', TGCallback(@Gtk3EntryDeletedText), Self, nil, 0);
  //g_signal_connect_data(PGtkEntry(FWidget)^.get_buffer, 'inserted-text', TGCallback(@Gtk3EntryInsertedText), Self, nil, 0);
end;

procedure TGtk3Entry.SetPasswordChar(APasswordChar: Char);
var
  PWChar: Integer;
begin
  if IsWidgetOK then
  begin
    PWChar := ord(APasswordChar);
    if (PWChar < 192) or (PWChar = ord('*')) then
      PWChar := 9679;
    PGtkEntry(FWidget)^.set_invisible_char(PWChar);
  end;
end;

procedure TGtk3Entry.SetEchoMode(AVisible: Boolean);
begin
  if IsWidgetOK then
    PGtkEntry(FWidget)^.set_visibility(AVisible);
end;

procedure TGtk3Entry.SetMaxLength(AMaxLength: Integer);
begin
  if IsWidgetOK then
    PGtkEntry(FWidget)^.set_max_length(AMaxLength);
end;

function TGtk3Entry.IsWidgetOk: Boolean;
begin
  Result := (FWidget <> nil) and Gtk3IsEntry(FWidget);
end;

{ TGtk3SpinEdit }

function TGtk3SpinEdit.GetMaximum: Double;
var
  AFloat: gdouble;
begin
  Result := 0;
  if IsWidgetOk then
    PGtkSpinButton(FWidget)^.get_range(@AFloat ,@Result);
end;

function TGtk3SpinEdit.GetMinimum: Double;
var
  AFloat: gdouble;
begin
  Result := 0;
  if IsWidgetOk then
    PGtkSpinButton(FWidget)^.get_range(@Result ,@AFloat);
end;

function TGtk3SpinEdit.GetNumDigits: Integer;
begin
  Result := 0;
  if IsWidgetOk then
    Result := Integer(PGtkSpinButton(FWidget)^.get_digits);
end;

function TGtk3SpinEdit.GetNumeric: Boolean;
begin
  Result := False;
  if IsWidgetOk then
    Result := PGtkSpinButton(FWidget)^.get_numeric;
end;

function TGtk3SpinEdit.GetStep: Double;
var
  AFloat: Double;
begin
  Result := 0;
  if IsWidgetOk then
    PGtkSpinButton(FWidget)^.get_increments(@Result, @AFloat);
end;

function TGtk3SpinEdit.GetValue: Double;
begin
  Result := 0;
  if IsWidgetOk then
    Result := PGtkSpinButton(FWidget)^.get_value;
end;

procedure TGtk3SpinEdit.SetNumDigits(AValue: Integer);
begin
  if IsWidgetOk then
    PGtkSpinButton(FWidget)^.set_digits(GUint(AValue));
end;

procedure TGtk3SpinEdit.SetNumeric(AValue: Boolean);
begin
  if IsWidgetOk then
    PGtkSpinButton(FWidget)^.set_numeric(AValue);
end;

procedure TGtk3SpinEdit.SetStep(AValue: Double);
var
  AStep: gdouble;
  APage: gdouble;
begin
  if IsWidgetOk then
  begin
    PGtkSpinButton(FWidget)^.get_increments(@AStep, @APage);
    PGtkSpinButton(FWidget)^.set_increments(AValue, APage);
  end;
end;

procedure TGtk3SpinEdit.SetValue(AValue: Double);
begin
  if IsWidgetOk then
  begin
    PGtkSpinButton(FWidget)^.set_value(AValue);
  end;
end;

function TGtk3SpinEdit.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  ASpin: TCustomSpinEdit;
  ARect: TGdkRectangle;
  // Adjustment: PGtkAdjustment;
begin
  PrivateCursorPos := -1;
  PrivateSelection := -1;
  ASpin := TCustomSpinEdit(LCLObject);
  FWidgetType := FWidgetType + [wtSpinEdit];
  // Adjustment := TGtkAdjustment.new(ASpin.Value, ASpin.MinValue, ASpin.MaxValue, ASpin.Increment,
  //  ASpin.Increment, ASpin.Increment);
  Result := TGtkSpinButton.new_with_range(ASpin.MinValue, ASpin.MaxValue, ASpin.Increment);
end;

function TGtk3SpinEdit.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := False;
end;

function TGtk3SpinEdit.IsWidgetOk: Boolean;
begin
  Result := (FWidget <> nil) and Gtk3IsSpinButton(FWidget);
end;

procedure TGtk3SpinEdit.SetRange(AMin, AMax: Double);
begin
  if IsWidgetOk then
    PGtkSpinButton(FWidget)^.set_range(AMin, AMax);
end;

{ TGtk3Range }

procedure Gtk3RangeChanged(ARange: PGtkRange; AData: gPointer); cdecl;
var
  Msg: TLMessage;
begin
  if AData <> nil then
  begin
    if TGtk3Widget(AData).InUpdate then
      Exit;
    FillChar(Msg, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    TGtk3Widget(AData).DeliverMessage(Msg);
  end;
end;

function TGtk3Range.GetPosition: Integer;
begin
  Result := 0;
  if IsWidgetOK then
    Result := Round(PGtkRange(FWidget)^.get_value);
end;

function TGtk3Range.GetRange: TPoint;
begin
  Result := Point(0, 0);
  if IsWidgetOK then
    PGtkRange(FWidget)^.get_slider_range(@Result.X, @Result.Y);
end;

procedure TGtk3Range.SetPosition(AValue: Integer);
begin
  if IsWidgetOK then
    PGtkRange(FWidget)^.set_value(gDouble(AValue));
end;

procedure TGtk3Range.SetRange(AValue: TPoint);
var
  dx,dy: gdouble;
begin
  if IsWidgetOK then
  begin
    dx := AValue.X;
    dy := AValue.Y;
    PGtkRange(FWidget)^.set_range(dx, dy);
  end;
end;

procedure TGtk3Range.InitializeWidget;
begin
  inherited InitializeWidget;
  g_signal_connect_data(GetContainerWidget, 'value-changed', TGCallback(@Gtk3RangeChanged), Self, nil, 0);
end;

procedure TGtk3Range.SetStep(AStep: Integer; APageSize: Integer);
begin
  if IsWidgetOk then
    PGtkRange(FWidget)^.set_increments(gDouble(AStep), gDouble(APageSize));
end;

{ TGtk3TrackBar }

function TGtk3TrackBar.GetReversed: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := PGtkScale(FWidget)^.get_inverted;
end;

procedure TGtk3TrackBar.SetReversed(AValue: Boolean);
begin
  if IsWidgetOK then
    PGtkScale(FWidget)^.set_inverted(AValue);
end;

function TGtk3TrackBar.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  ATrack: TCustomTrackBar;
begin
  ATrack := TCustomTrackBar(LCLObject);
  FWidgetType := FWidgetType + [wtTrackBar];
  Result := PGtkWidget(TGtkScale.new(Ord(ATrack.Orientation), nil));
  FOrientation := ATrack.Orientation;
  if ATrack.Reversed then
    PGtkScale(Result)^.set_inverted(True);

  PGtkScale(Result)^.set_digits(0);
end;

function TGtk3TrackBar.GetTrackBarOrientation: TTrackBarOrientation;
begin
  Result := FOrientation;
end;

procedure TGtk3TrackBar.SetScalePos(AValue: TTrackBarScalePos);
begin
  if IsWidgetOK then
    PGtkScale(FWidget)^.set_value_pos(Ord(AValue));
end;

procedure TGtk3TrackBar.SetTickMarks(AValue: TTickMark; ATickStyle: TTickStyle);
var
  i: Integer;
begin
  if IsWidgetOK then
  begin
    if ATickStyle = tsNone then
      PGtkScale(FWidget)^.clear_marks
    else
    begin
      for i := TCustomTrackbar(LCLObject).Min to TCustomTrackbar(LCLObject).Max do
      begin
        if TCustomTrackbar(LCLObject).Orientation = trHorizontal then
        begin
          if AValue in [tmBoth, tmTopLeft] then
            PGtkScale(FWidget)^.add_mark(gDouble(i), GTK_POS_TOP, nil);
          if AValue in [tmBoth, tmBottomRight] then
            PGtkScale(FWidget)^.add_mark(gDouble(i), GTK_POS_BOTTOM, nil);
        end else
        begin
          if AValue in [tmBoth, tmTopLeft] then
            PGtkScale(FWidget)^.add_mark(gDouble(i), GTK_POS_LEFT, nil);
          if AValue in [tmBoth, tmBottomRight] then
            PGtkScale(FWidget)^.add_mark(gDouble(i), GTK_POS_RIGHT, nil);
        end;
      end;
    end;
  end;
end;

{ TGtk3ScrollBar }

function TGtk3ScrollBar.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AScrollbar: TCustomScrollBar;
  ARange: PGtkRange;
begin
  AScrollBar := TCustomScrollBar(LCLObject);
  FWidgetType := FWidgetType + [wtScrollBar];
  Result := TGtkScrollbar.new(Ord(AScrollBar.Kind), nil);
  ARange := PGtkRange(Result);
  // ARange^.set_can_focus(True);
  with AScrollBar do
  begin
    ARange^.adjustment^.configure(Position, Min, Max + PageSize,
      SmallChange, LargeChange, PageSize);
    ARange^.adjustment^.set_value(Position);
  end;
end;

procedure TGtk3ScrollBar.SetParams;
var
  ARange: PGtkRange;
begin
  if not IsWidgetOk then
    exit;
  ARange := PGtkRange(Widget);
  with TCustomScrollbar(LCLObject) do
  begin
    ARange^.adjustment^.configure(Position, Min, Max + PageSize,
      SmallChange, LargeChange, PageSize);
    ARange^.adjustment^.set_value(Position);
    ARange^.adjustment^.changed;
   // gtk_adjustment_changed(Range^.adjustment);
  end;
end;

{ TGtk3Calendar }

function TGtk3Calendar.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := [wtWidget, wtCalendar];
  Result := TGtkFrame.new(nil);
  FCentralWidget := TGtkCalendar.new;
  PGtkContainer(Result)^.add(FCentralWidget);
  FCentralWidget^.set_can_focus(True);
end;

procedure TGtk3Calendar.GetDate(out AYear, AMonth, ADay: Word);
begin
  AYear := 0;
  AMonth := 0;
  ADay := 0;
  if IsWidgetOk then
    PGtkCalendar(GetContainerWidget)^.get_date(@AYear, @AMonth, @ADay);
end;

procedure TGtk3Calendar.SetDate(const AYear, AMonth, ADay: Word);
begin
  if IsWidgetOK then
  begin
    PGtkCalendar(GetContainerWidget)^.select_month(AMonth, AYear);
    PGtkCalendar(GetContainerWidget)^.select_day(ADay);
  end;
end;

procedure TGtk3Calendar.SetDisplayOptions(
  const ADisplayOptions: TGtkCalendarDisplayOptions);
begin
  if IsWidgetOK then
    PGtkCalendar(GetContainerWidget)^.set_display_options(ADisplayOptions);
end;

{ TGtk3StaticText }

function TGtk3StaticText.GetAlignment: TAlignment;
var
  X: gfloat;
  Y: gfloat;
begin
  Result := taLeftJustify;
  if IsWidgetOK then
  begin
    PGtkLabel(GetContainerWidget)^.get_alignment(@X, @Y);
    if X = 1 then
      Result := taRightJustify
    else
    if X = 0.5 then
      Result := taCenter;
  end;
end;

function TGtk3StaticText.GetStaticBorderStyle: TStaticBorderStyle;
var
  AShadowType: TGtkShadowType;
begin
  Result := sbsNone;
  if IsWidgetOK then
  begin
    AShadowType := PGtkFrame(Widget)^.get_shadow_type;
    if AShadowType = GTK_SHADOW_ETCHED_IN then
      Result := sbsSingle
    else
    if AShadowType = GTK_SHADOW_IN then
      Result := sbsSunken;
  end;
end;

procedure TGtk3StaticText.SetAlignment(AValue: TAlignment);
begin
  if IsWidgetOk then
    PGtkLabel(GetContainerWidget)^.set_alignment(AGtkJustificationF[AValue], 0);
end;

procedure TGtk3StaticText.SetStaticBorderStyle(AValue: TStaticBorderStyle);
begin
  if IsWidgetOK then
    PGtkFrame(Widget)^.set_shadow_type(StaticBorderShadowMap[AValue]);
end;

function TGtk3StaticText.getText: String;
begin
  Result := '';
  if IsWidgetOk then
    Result := PGtkLabel(getContainerWidget)^.get_text;
end;

procedure TGtk3StaticText.setText(AValue: String);
begin
  if IsWidgetOk then
    PGtkLabel(getContainerWidget)^.set_text(PgChar(AValue));
end;

function TGtk3StaticText.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AStaticText: TCustomStaticText;
begin
  FWidgetType := FWidgetType + [wtStaticText];
  AStaticText := TCustomStaticText(LCLObject);
  Result := TGtkFrame.new('');
  PGtkFrame(Result)^.set_shadow_type(StaticBorderShadowMap[AStaticText.BorderStyle]);
  FCentralWidget := TGtkLabel.new('');
  FCentralWidget^.set_has_window(True);
  PGtkFrame(Result)^.set_label_widget(nil);
  PGtkFrame(Result)^.add(FCentralWidget);
  PGtkLabel(FCentralWidget)^.set_alignment(AGtkJustificationF[AStaticText.Alignment], 0.0);
end;

{ TGtk3ProgressBar }

function TGtk3ProgressBar.GetOrientation: TProgressBarOrientation;
var
  AOrientation: TGtkOrientation;
begin
  Result := pbHorizontal;
  if IsWidgetOk then
  begin
    AOrientation := PGtkOrientable(getContainerWidget)^.get_orientation;
    if AOrientation = GTK_ORIENTATION_HORIZONTAL then
    begin
      if PGtkProgressBar(getContainerWidget)^.get_inverted then
        Result := pbRightToLeft
      else
        Result := pbHorizontal;
    end else
    begin
      if PGtkProgressBar(getContainerWidget)^.get_inverted then
        Result := pbTopDown
      else
        Result := pbVertical;
    end;
  end;
end;

function TGtk3ProgressBar.GetPosition: Integer;
begin
  Result := 0;
  if IsWidgetOk then
    Result := Round(PGtkProgressBar(GetContainerWidget)^.get_fraction);
end;

function TGtk3ProgressBar.GetShowText: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := PGtkProgressBar(GetContainerWidget)^.get_show_text;
end;

function TGtk3ProgressBar.GetStyle: TProgressBarStyle;
var
  ABar: TCustomProgressBar;
begin
  Result := pbstNormal;
  if Assigned(LCLObject) and IsWidgetOk then
    Result := TCustomProgressBar(LCLObject).Style;
end;

procedure TGtk3ProgressBar.SetOrientation(AValue: TProgressBarOrientation);
begin
  if IsWidgetOk then
  begin
    case AValue of
      pbHorizontal,pbRightToLeft:
      begin
        PGtkOrientable(GetContainerWidget)^.set_orientation(GTK_ORIENTATION_HORIZONTAL);
        PGtkProgressBar(GetContainerWidget)^.set_inverted(AValue = pbRightToLeft);
      end;
      pbVertical, pbTopDown:
      begin
        PGtkOrientable(GetContainerWidget)^.set_orientation(GTK_ORIENTATION_VERTICAL);
        PGtkProgressBar(GetContainerWidget)^.set_inverted(AValue = pbVertical);
      end;
    end;
  end;
end;

procedure TGtk3ProgressBar.SetPosition(AValue: Integer);
var
  ABar: TCustomProgressBar;
  fraction: gDouble;
begin
  if not Assigned(LCLObject) or not IsWidgetOK then
    exit;
  ABar := TCustomProgressBar(LCLObject);
  if ((ABar.Max - ABar.Min) <> 0) then
    fraction := (AValue - ABar.Min) / (ABar.Max - ABar.Min)
  else
    fraction := 0;
  PGtkProgressBar(GetContainerWidget)^.set_fraction(fraction);
end;

procedure TGtk3ProgressBar.SetShowText(AValue: Boolean);
begin
  if IsWidgetOK then
    PGtkProgressBar(GetContainerWidget)^.set_show_text(AValue);
end;

function ProgressPulseTimeout(data: gpointer): gboolean; cdecl;
begin
  Result := {%H-}PtrUInt(g_object_get_data(data, 'lclprogressbarstyle')) = 1;
  if Result then
    PGtkProgressBar(Data)^.pulse;
end;

procedure ProgressDestroy(data: gpointer); cdecl;
begin
  g_source_remove({%H-}PtrUInt(data));
end;

procedure TGtk3ProgressBar.SetStyle(AValue: TProgressBarStyle);
begin
  if IsWidgetOk then
  begin
    g_object_set_data(GetContainerWidget,'lclprogressbarstyle', Pointer(PtrUInt(Ord(AValue))));
    if AValue = pbstNormal then
    begin
      Position := TCustomProgressBar(LCLObject).Position;
    end else
    begin
      g_object_set_data_full(GetContainerWidget, 'timeout',
        {%H-}Pointer(PtrUInt(g_timeout_add(100, @ProgressPulseTimeout, GetContainerWidget))), @ProgressDestroy);
      PGtkProgressBar(GetContainerWidget)^.pulse;
    end;
  end;
end;

{we must override preferred width since gtk3 have strange opinion about minimum width of progress bar}
procedure get_progress_preferred_width(widget: PGtkWidget; minimum_width: Pgint; natural_width: Pgint); cdecl;
var
  Handle: HWND;
begin
  Handle := HwndFromGtkWidget(Widget);
  if Handle <> 0 then
  begin
    minimum_width^ := TGtk3Widget(Handle).LCLObject.Width;
    natural_width^ := TGtk3Widget(Handle).LCLObject.Width;
  end else
  begin
    minimum_width^ := 0;
    natural_width^ := 0;
    DebugLn('ERROR: get_progress_preferred_width cannot find GtkWidget LCL Handle ....');
  end;
end;

{we must override preferred height since gtk3 have strange opinion about height of progress bar}
procedure get_progress_preferred_height(widget: PGtkWidget; minimum_height: Pgint; natural_height: Pgint); cdecl;
var
  Handle: HWND;
begin
  Handle := HwndFromGtkWidget(Widget);
  if Handle <> 0 then
  begin
    minimum_height^ := TGtk3Widget(Handle).LCLObject.Height;
    natural_height^ := TGtk3Widget(Handle).LCLObject.Height;
    // TODO: get spacing from style property
    // Widget^.get_style_context^.get_style_property();
  end else
  begin
    minimum_height^ := 0;
    natural_height^ := 0;
    DebugLn('ERROR: get_progress_preferred_height cannot find GtkWidget LCL Handle ....');
  end;
end;

function TGtk3ProgressBar.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AProgres: TCustomProgressBar;
begin
  AProgres := TCustomProgressBar(LCLObject);
  FWidgetType := FWidgetType + [wtProgressBar];
  Result := TGtkEventBox.new;
  FCentralWidget := TGtkProgressBar.new;
  PGtkEventBox(Result)^.add(FCentralWidget);
  FCentralWidget^.set_can_focus(True);
end;

var
  AProgressClassHookInitialized: Boolean = False;

procedure TGtk3ProgressBar.InitializeWidget;
var
  AClass: PGTypeClass;
begin
  inherited InitializeWidget;
  //TODO: move hookers check variable code into Gtk3WidgetSet.
  if not AProgressClassHookInitialized then
  begin
    AProgressClassHookInitialized := True;
    AClass := g_type_class_ref(gtk_progress_bar_get_type);
    PGtkWidgetClass(AClass)^.get_preferred_width := @get_progress_preferred_width;
    PGtkWidgetClass(AClass)^.get_preferred_height := @get_progress_preferred_height;
    g_type_class_unref(AClass);
  end;
end;

{ TGtk3Container }

procedure TGtk3Container.AddChild(AWidget: PGtkWidget; const ALeft, ATop: Integer);
begin
  if Assigned(FCentralWidget) then
    PGtkFixed(PGtkScrolledWindow(FCentralWidget)^.get_child)^.put(AWidget, ALeft, ATop)
  else
    PGtkContainer(FWidget)^.add(AWidget);
end;

{ TGtk3ToolBar }

function TGtk3ToolBar.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AToolBar: TToolBar;
begin
  AToolBar := TToolBar(LCLObject);
  FHasPaint := False;
  FWidgetType := [wtWidget, wtContainer];
  Result := PGtkWidget(TGtkHBox.new(GTK_ORIENTATION_HORIZONTAL, 0));
  FCentralWidget := PGtkWidget(TGtkFixed.new);
  PGtkHBox(Result)^.add(FCentralWidget);
  PGtkFixed(FCentralWidget)^.set_has_window(True);
end;

{ TGtk3Page }

procedure TGtk3Page.setText(AValue: String);
begin
  if Assigned(FPageLabel) then
    FPageLabel^.set_text(PChar(AValue));
end;

function TGtk3Page.getText: String;
begin
  if Assigned(FPageLabel) then
    Result := FPageLabel^.get_text
  else
    Result := '';
end;

function TGtk3Page.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := FWidgetType + [wtContainer];
  FPageLabel:= TGtkLabel.new(PChar(Params.Caption));
  // ref it to save it in case TabVisble is set to false
  FPageLabel^.ref;
  Result := TGtkHBox.new(GTK_ORIENTATION_HORIZONTAL, 0);
  FCentralWidget := TGtkFixed.new;
  PGtkHBox(Result)^.pack_start(FCentralWidget, True , True, 0);
  PGtkFixed(FCentralWidget)^.set_has_window(True);
  // PGtkFixed(FCentralWidget)^.set_can_focus(True);
end;

procedure TGtk3Page.DestroyWidget;
begin
  inherited DestroyWidget;
  // unref it to allow it to be destroyed
  FPageLabel^.unref;
end;

function TGtk3Page.getClientRect: TRect;
var
  AParent: PGtkWidget;
  AParentObject: TGtk3Widget;
begin
  if not getContainerWidget^.get_realized then
  begin
    AParent := FWidget^.get_parent;
    AParentObject := TGtk3Widget(HwndFromGtkWidget(AParent));
    if AParentObject <> nil then
      Result := AParentObject.getClientRect
    else
      Result := inherited getClientRect;
  end else
    Result := inherited getClientRect;
  // DebugLn('TGtk3Page.GetClientRect Result=',dbgs(Result),' Realized ',dbgs(getContainerWidget^.get_realized));
end;

{ TGtk3NoteBook }

function NotebookPageRealToLCLIndex(const ATabControl: TCustomTabControl; AIndex: integer): integer;
var
  I: Integer;
begin
  Result := AIndex;
  if csDesigning in ATabControl.ComponentState then exit;
  I := 0;
  while (I < ATabControl.PageCount) and (I <= Result) do
  begin
    if not ATabControl.Page[I].TabVisible then Inc(Result);
    Inc(I);
  end;
end;

// function GtkNotebookAfterSwitchPage(widget: PGtkWidget; pagenum: integer; data: gPointer): GBoolean; cdecl;
procedure GtkNotebookAfterSwitchPage(widget: PGtkWidget; {%H-}page: PGtkWidget; pagenum: integer; data: gPointer); cdecl;
var
  Mess: TLMNotify;
  NMHdr: tagNMHDR;
  ACtl: TWinControl;
  AParentForm: TCustomForm;
  i: Integer;
  LCLPageIndex: Integer;
  Pg: TCustomPage;
  ChildWidget: PGtkWidget;
begin
  if TGtk3Widget(Data).InUpdate then
    exit;
  DebugLn('GtkNotebookAfterSwitchPage ');
  FillChar(Mess{%H-}, SizeOf(Mess), 0);
  Mess.Msg := LM_NOTIFY;
  FillChar(NMHdr{%H-}, SizeOf(NMHdr), 0);
  NMHdr.code := TCN_SELCHANGE;
  NMHdr.hwndFrom := HWND(TGtk3Widget(Data));
  LCLPageIndex := NotebookPageRealToLCLIndex(TCustomTabControl(TGtk3Widget(Data).LCLObject), pagenum);  //use this to set pageindex to the correct page.
  NMHdr.idFrom := LCLPageIndex;
  Mess.NMHdr := @NMHdr;
  TGtk3Widget(Data).DeliverMessage(Mess);
end;

function BackNoteBookSignal(AData: Pointer): gboolean; cdecl;
var
  AWidget: PGtkNotebook;
  APageNum: PtrInt;
  ACurrentPage: gint;
begin
  Result := False;
  AWidget := AData;
  if not Gtk3IsWidget(AWidget) then
    exit;
  if g_object_get_data(AWidget,'switch-page-signal-stopped') <> nil then
  begin
    Result := True;
    APageNum := PtrInt(g_object_get_data(AWidget,'switch-page-signal-stopped'));
    ACurrentPage := AWidget^.get_current_page;
    g_object_set_data(AWidget,'switch-page-signal-stopped', nil);
    DebugLn('BackNoteBookSignal back notebook switch-page signal currpage=',dbgs(AWidget^.get_current_page),' blockedPage ',dbgs(APageNum));
    // must hook into notebook^.priv to unlock APageNum
    // AWidget^.set_current_page(AWidget^.get_current_page);
    // g_object_thaw_notify(AWidget^.get_nth_page(AWidget^.get_current_page));
    // PGtkFixed(AWidget^.get_nth_page(AWidget^.get_current_page))^.
    // g_signal_emit_by_name(AWidget,'switch-page',[AWidget^.get_nth_page(APageNum), APageNum, gPointer(HwndFromGtkWidget(AWidget)), nil{AWidget, True, gPointer(HwndFromGtkWidget(AWidget))}]);
    // AWidget^.notify('page');
    // g_signal_stop_emission_by_name(AWidget, 'switch-page');
    // g_signal_emit_by_name(AWidget,'switch-page',[G_TYPE_NONE, AWidget, AWidget^.get_nth_page(AWidget^.get_current_page), AWidget^.get_current_page, gPointer(HwndFromGtkWidget(AWidget))]);
  end;
  g_idle_remove_by_data(AData);
end;

procedure GtkNotebookSwitchPage(widget: PGtkWidget; {%H-}page: PGtkWidget; pagenum: integer; data: gPointer); cdecl;
var
  Mess: TLMNotify;
  NMHdr: tagNMHDR;
begin
  if TGtk3Widget(Data).InUpdate then
    exit;
  DebugLn('GtkNotebookSwitchPage Data ',dbgHex(PtrUInt(Data)),' Realized ',dbgs(Widget^.get_realized),' pageNum=',dbgs(pageNum));
  FillChar(Mess{%H-}, SizeOf(Mess), 0);
  Mess.Msg := LM_NOTIFY;
  FillChar(NMHdr{%H-}, SizeOf(NMHdr), 0);
  NMHdr.code := TCN_SELCHANGING;
  NMHdr.hwndFrom := HWND(TGtk3Widget(Data));
  NMHdr.idFrom := NotebookPageRealToLCLIndex(TCustomTabControl(TGtk3Widget(Data).LCLObject), pagenum);  //use this to set pageindex to the correct page.
  // DebugLn('LCLObject ',dbgsName(TGtk3Widget(Data).LCLObject),' IdFrom ',dbgs(NMHdr.idFrom));
  Mess.NMHdr := @NMHdr;
  Mess.Result := 0;
  // DebugLn('LCLObject ',dbgsName(TGtk3Widget(Data).LCLObject),' sending message ....');
  TGtk3Widget(Data).DeliverMessage(Mess);
  if Mess.Result <> 0 then
  begin
    g_object_set_data(Widget,'switch-page-signal-stopped', GPointer(pageNum));
    g_signal_stop_emission_by_name(PGObject(Widget), 'switch-page');
    // GtkNotebookAfterSwitchPage(Widget, page, pagenum, data);
    g_idle_add(@BackNoteBookSignal, Widget);
    Exit;
  end;
end;

function GtkNotebookSelectPage(ANoteBook: PGtkNotebook; p1: gboolean; Data: gPointer): GBoolean; cdecl;
begin
  // does not trigger for some reason
  DebugLn('GtkNotebookSelectPage ');
end;

function TGtk3NoteBook.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := FWidgetType + [wtNotebook];
  Result := TGtkEventBox.new;
  PGtkEventBox(Result)^.set_has_window(True);
  FCentralWidget := TGtkNotebook.new;
  PGtkEventBox(Result)^.add(FCentralWidget);
  PGtkNoteBook(FCentralWidget)^.set_scrollable(True);
  if (nboHidePageListPopup in TCustomTabControl(LCLObject).Options) then
    PGtkNoteBook(FCentralWidget)^.popup_disable;
  PGtkNoteBook(FCentralWidget)^.show;

  g_signal_connect_data(FCentralWidget,'switch-page', TGCallback(@GtkNotebookSwitchPage), Self, nil, 0);
  // this one triggers after above switch-page
  g_signal_connect_data(FCentralWidget,'switch-page', TGCallback(@GtkNotebookAfterSwitchPage), Self, nil, 0);

  // those signals doesn't trigger with gtk3-3.6
  // g_signal_connect_data(FCentralWidget,'change-current-page', TGCallback(@GtkNotebookAfterSwitchPage), Self, nil, 0);
  // g_signal_connect_data(FCentralWidget,'select-page', TGCallback(@GtkNotebookSelectPage), Self, nil, 0);
end;

function TGtk3NoteBook.getClientRect: TRect;
var
  AAlloc: TGtkAllocation;
  ACurrentPage: gint;
  APage: PGtkWidget;
begin
  Result := Rect(0, 0, 0, 0);
  if PGtkNoteBook(GetContainerWidget)^.get_n_pages = 0 then
  begin
    GetContainerWidget^.get_allocation(@AAlloc);
    Result := RectFromGtkAllocation(AAlloc);
    OffsetRect(Result, -Result.Left, -Result.Top);
  end else
  begin
    ACurrentPage := PGtkNoteBook(GetContainerWidget)^.get_current_page;
    if (ACurrentPage >= 0) then
    begin
      APage := PGtkNoteBook(GetContainerWidget)^.get_nth_page(ACurrentPage);
      if APage^.get_realized then
        APage^.get_allocation(@AAlloc)
      else
        GetContainerWidget^.get_allocation(@AAlloc);
      Result := RectFromGtkAllocation(AAlloc);
      OffsetRect(Result, -Result.Left, -Result.Top);
    end;
  end;
  // DebugLn('TGtk3NoteBook.getClientRect Result ',dbgs(Result));
end;

procedure TGtk3NoteBook.InsertPage(ACustomPage: TCustomPage; AIndex: Integer);
var
  Gtk3Page: TGtk3Page;
begin
  if IsWidgetOK then
  begin
    Gtk3Page := TGtk3Page(ACustomPage.Handle);
    PGtkNoteBook(GetContainerWidget)^.insert_page(Gtk3Page.Widget, Gtk3Page.FPageLabel, AIndex);
  end;
end;

procedure TGtk3NoteBook.MovePage(ACustomPage: TCustomPage; ANewIndex: Integer);
begin
  if IsWidgetOK then
    PGtkNoteBook(GetContainerWidget)^.reorder_child(TGtk3Widget(ACustomPage.Handle).Widget, ANewIndex);
end;

procedure TGtk3NoteBook.RemovePage(AIndex: Integer);
begin
  if IsWidgetOK then
  begin
    PGtkNotebook(GetContainerWidget)^.remove_page(AIndex);
  end;
end;

procedure TGtk3NoteBook.SetPageIndex(AIndex: Integer);
begin
  if IsWidgetOK then
  begin
    PGtkNotebook(GetContainerWidget)^.set_current_page(AIndex);
  end;
end;

procedure TGtk3NoteBook.SetShowTabs(const AShowTabs: Boolean);
begin
  if IsWidgetOK then
    PGtkNoteBook(GetContainerWidget)^.set_show_tabs(AShowTabs);
end;

procedure TGtk3NoteBook.SetTabPosition(const ATabPosition: TTabPosition);
const
  GtkPositionTypeMap: array[TTabPosition] of TGtkPositionType =
  (
    2, // { tpTop    } GTK_POS_TOP,
    3, // { tpBottom } GTK_POS_BOTTOM,
    0, // { tpLeft   } GTK_POS_LEFT,
    1 // { tpRight  } GTK_POS_RIGHT
  );
begin
  if IsWidgetOK then
    PGtkNoteBook(GetContainerWidget)^.set_tab_pos(GtkPositionTypeMap[ATabPosition]);
end;

procedure TGtk3NoteBook.SetTabLabelText(AChild: TCustomPage; AText: String);
begin
  if IsWidgetOK then
    TGtk3Widget(AChild.Handle).setText(AText);
end;

function TGtk3NoteBook.GetTabLabelText(AChild: TCustomPage): String;
begin
  if IsWidgetOK then
    Result := TGtk3Widget(AChild.Handle).getText
  else
    Result := '';
end;

{ TGtk3MenuShell }

procedure TGtk3MenuShell.Insert(AMenuShell: PGtkMenuShell; APosition: Integer);
begin
  if IsWidgetOK then
    PGtkMenuShell(Widget)^.insert(AMenuShell, APosition);
end;

constructor TGtk3MenuShell.Create(const AMenu: TMenu; AMenuBar: PGtkMenuBar);
begin
  inherited Create;
  MenuObject := AMenu;
  FContext := 0;
  FHasPaint := False;
  FWidget := nil;
  FOwner := nil;
  FCentralWidget := nil;
  if AMenuBar <> nil then
  begin
    FOwnWidget := False;
    FWidget := AMenuBar;
  end else
    FOwnWidget := True;
  // Initializes the properties
  FProps := nil;
  LCLObject := nil;
  // FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  // FHasPaint := False;

  // FParams := AParams;
  InitializeWidget;
end;

procedure TGtk3MenuShell.InitializeWidget;
var
  ARect: TGdkRectangle;
begin
  FCentralWidget := nil;
  FCairoContext := nil;
  FContext := 0;
  FEnterLeaveTime := 0;
  if FOwnWidget then
    FWidget := CreateWidget(FParams);

  LCLIntf.SetProp(HWND(Self),'lclwidget',Self);
end;


{ TGtk3MenuBar }

function TGtk3MenuBar.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := [wtWidget, wtMenuBar];
  Result := TGtkMenuBar.new;
  PGtkMenuBar(Result)^.set_pack_direction(MenuDirection[TMenu(MenuObject).UseRightToLeftAlignment]);
end;

{ TGtk3Menu }

function TGtk3Menu.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := [wtWidget, wtMenu];
  Result := TGtkMenu.new;
end;

constructor TGtk3Menu.CreateFromMenuItem(const AMenuItem: TMenuItem);
begin
  inherited Create(AMenuItem.GetParentMenu, nil);
end;

{ TGtk3MenuItem }

function TGtk3MenuItem.GetCaption: string;
begin
  Result := '';
  if IsWidgetOK then
    Result := PGtkMenuItem(FWidget)^.get_label;
end;

procedure TGtk3MenuItem.SetCaption(AValue: string);
begin
  if IsWidgetOK then
    PGtkMenuItem(FWidget)^.set_label(PgChar(AValue));
end;

function TGtk3MenuItem.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := [wtWidget, wtMenuItem];
  if MenuItem.Caption = cLineCaption then
    Result := TGtkSeparatorMenuItem.new
  else
  if MenuItem.RadioItem and not MenuItem.HasIcon then
    Result := TGtkRadioMenuItem.new(nil)
  else
  if MenuItem.IsCheckItem or MenuItem.HasIcon then
    Result := TGtkCheckMenuItem.new
  else
    Result := TGtkMenuItem.new;

  if MenuItem.Caption <> cLineCaption then
  begin
    PGtkMenuItem(Result)^.set_label(PgChar(MenuItem.Caption));
    PGtkMenuItem(Result)^.set_sensitive(MenuItem.Enabled);
    // there's nothing like this in Gtk3
    // if MenuItem.RightJustify then
    //  gtk_menu_item_right_justify(PGtkMenuItem(Widget));

  end;
end;

constructor TGtk3MenuItem.Create(const AMenuItem: TMenuItem);
begin
  inherited Create;
  MenuItem := AMenuItem;
  FContext := 0;
  FHasPaint := False;
  FWidget := nil;
  FOwner := nil;
  FCentralWidget := nil;
  FOwnWidget := True;
  // Initializes the properties
  FProps := nil;
  LCLObject := nil;
  // FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  // FHasPaint := False;

  // FParams := AParams;
  InitializeWidget;
end;

procedure Gtk3MenuItemActivated(AItem: PGtkMenuItem; AData: GPointer); cdecl;
var
  Msg: TLMessage;
begin
  // DebugLn('Gtk3MenuItemActivated ',dbgsName(TGtk3MenuItem(Adata)));
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_ACTIVATE;
  if Assigned(TGtk3MenuItem(AData).MenuItem) then
    TGtk3MenuItem(AData).MenuItem.Dispatch(Msg);
end;

procedure TGtk3MenuItem.InitializeWidget;
begin
  FCentralWidget := nil;
  FCairoContext := nil;
  FContext := 0;
  FEnterLeaveTime := 0;

  FWidget := CreateWidget(FParams);
  LCLIntf.SetProp(HWND(Self),'lclwidget',Self);

  // move signal connections into attach events
  FWidget^.set_events(GDK_ALL_EVENTS_MASK);
  g_signal_connect_data(FWidget, 'event', TGCallback(@Gtk3MenuItemEvent), Self, nil, 0);
  g_signal_connect_data(FWidget,'activate',TGCallBack(@Gtk3MenuItemActivated), Self, nil, 0);
  // must hide all by default
  // FWidget^.hide;
end;


{ TGtk3ScrollableWin}

function TGtk3ScrollableWin.GetHScrollBarPolicy: TGtkPolicyType;
var
  AScrollWin: PGtkScrolledWindow;
  APolicy: TGtkPolicyType;
begin
  Result := GTK_POLICY_AUTOMATIC;
  AScrollWin := getScrolledWindow;
  if not Gtk3IsScrolledWindow(AScrollWin) then
    exit;
  AScrollWin^.get_policy(@Result, @APolicy);
end;

function TGtk3ScrollableWin.GetVScrollBarPolicy: TGtkPolicyType;
var
  AScrollWin: PGtkScrolledWindow;
  APolicy: TGtkPolicyType;
begin
  Result := GTK_POLICY_AUTOMATIC;
  AScrollWin := getScrolledWindow;
  if not Gtk3IsScrolledWindow(AScrollWin) then
    exit;
  AScrollWin^.get_policy(@APolicy, @Result);
end;

procedure TGtk3ScrollableWin.SetBorderStyle(AValue: TBorderStyle);
begin
  if FBorderStyle=AValue then Exit;
  FBorderStyle:=AValue;
  if IsWidgetOK then
  begin
    if AValue = bsNone then
      getScrolledWindow^.set_shadow_type(GTK_SHADOW_NONE)
    else
      getScrolledWindow^.set_shadow_type(GTK_SHADOW_ETCHED_IN);
  end;
end;

procedure TGtk3ScrollableWin.SetHScrollBarPolicy(AValue: TGtkPolicyType);
var
  AScrollWin: PGtkScrolledWindow;
  APolicyH, APolicyV: TGtkPolicyType;
begin
  AScrollWin := getScrolledWindow;
  if not Gtk3IsScrolledWindow(AScrollWin) then
    exit;
  AScrollWin^.get_policy(@APolicyH, @APolicyV);
  AScrollWin^.set_policy(AValue, APolicyV);
end;

procedure TGtk3ScrollableWin.SetVScrollBarPolicy(AValue: TGtkPolicyType);
var
  AScrollWin: PGtkScrolledWindow;
  APolicyH, APolicyV: TGtkPolicyType;
begin
  AScrollWin := getScrolledWindow;
  if not Gtk3IsScrolledWindow(AScrollWin) then
    exit;
  AScrollWin^.get_policy(@APolicyH, @APolicyV);
  AScrollWin^.set_policy(APolicyH, AValue);
end;

function Gtk3RangeScrollCB(ARange: PGtkRange; AScrollType: TGtkScrollType;
  AValue: gdouble; AData: TGtk3Widget): gboolean; cdecl;
var
  Msg: TLMVScroll;
  MaxValue: gdouble;
  Widget: PGtkWidget;
begin
  Result := False;

  Widget := PGTKWidget(ARange);
  {$IFDEF SYNSCROLLDEBUG}
  DebugLn(Format('Trace:[Gtk3RangeScrollCB] Value: %d', [RoundToInt(AValue)]),' IsHScrollBar ',dbgs(PGtkOrientable(ARange)^.get_orientation = GTK_ORIENTATION_HORIZONTAL));
  {$ENDIF}
  if PGtkOrientable(ARange)^.get_orientation = GTK_ORIENTATION_HORIZONTAL then
    Msg.Msg := LM_HSCROLL
  else
    Msg.Msg := LM_VSCROLL;

  if ARange^.adjustment^.page_size > 0 then
    MaxValue := ARange^.adjustment^.upper - ARange^.adjustment^.page_size
  else
    MaxValue := ARange^.adjustment^.upper;

  if (AValue > MaxValue) then
    AValue := MaxValue
  else if (AValue < ARange^.adjustment^.lower) then
    AValue := ARange^.adjustment^.lower;

  with Msg do
  begin
    Pos := Round(AValue);
    if Pos < High(SmallPos) then
      SmallPos := Pos
    else
      SmallPos := High(SmallPos);
    {$note to get this correct we must use TQtWidget.CreateFrom() for scrollbars}
    ScrollBar := HWND(AData); // HWND({%H-}PtrUInt(ARange));
    ScrollCode := Gtk3ScrollTypeToScrollCode(AScrollType);
  end;
  DeliverMessage(AData.LCLObject, Msg);

  if Msg.Scrollcode = SB_THUMBTRACK then
  begin
    if Widget^.get_state_flags = GTK_STATE_NORMAL then
    begin
      Msg.ScrollCode := SB_THUMBPOSITION;
      DeliverMessage(AData.LCLObject, Msg);
      Msg.ScrollCode := SB_ENDSCROLL;
      DeliverMessage(AData.LCLObject, Msg);
    end;
  end else
    Widget^.set_state_flags(GTK_STATE_FLAG_ACTIVE, True);

  if (AData.LCLObject is TScrollingWinControl) and
  ((Msg.ScrollCode=SB_LINEUP) or (Msg.ScrollCode=SB_LINEDOWN)) then
    Result:=True;
end;

procedure TGtk3ScrollableWin.SetScrollBarsSignalHandlers;
begin
  {TODO: create real instances for scrollbars via TGtk3Widget.CreateFrom() ?}
  FBorderStyle := bsNone;
  g_signal_connect_data(getHorizontalScrollbar, 'change-value',
    TGCallback(@Gtk3RangeScrollCB), Self, nil, 0);
  g_signal_connect_data(getVerticalScrollbar, 'change-value',
    TGCallback(@Gtk3RangeScrollCB), Self, nil, 0);
end;

function TGtk3ScrollableWin.getClientBounds: TRect;
var
  Allocation: TGtkAllocation;
begin
  Result := Rect(0, 0, 0, 0);
  if IsWidgetOK then
  begin
    getContainerWidget^.get_allocation(@Allocation);
    Result := RectFromGtkAllocation(Allocation);
  end;
  // DebugLn('TGtk3ScrollableWin.getClientBounds result ',dbgs(Result));
end;

{ TGtk3Memo }

function TGtk3Memo.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AMemo: TCustomMemo;
  ABuffer: PGtkTextBuffer;
  AScrollStyle: TPoint;
begin
  FScrollX := 0;
  FScrollY := 0;

  FKeysToEat := [];
  AMemo := TCustomMemo(LCLObject);

  FWidgetType := FWidgetType + [wtMemo, wtScrollingWin];
  Result := PGtkScrolledWindow(TGtkScrolledWindow.new(nil, nil));

  FCentralWidget := PGtkTextView(TGtkTextView.new);

  FCentralWidget^.set_has_window(True);

  if AMemo.WordWrap then
    PGtkTextView(FCentralWidget)^.set_wrap_mode(GTK_WRAP_WORD)
  else
    PGtkTextView(FCentralWidget)^.set_wrap_mode(GTK_WRAP_NONE);

  ABuffer := PGtkTextBuffer^.new(PGtkTextTagTable^.new);
  ABuffer^.set_text(PgChar(AMemo.Text), -1);
  PGtkTextView(FCentralWidget)^.set_buffer(ABuffer);

  PGtkScrolledWindow(Result)^.add(FCentralWidget);

  // PGtkScrolledWindow(Result)^.set_focus_child(FCentralWidget);

  AScrollStyle := Gtk3TranslateScrollStyle(AMemo.ScrollBars);

  // Gtk3 GtkTextView is weird. When scrollbars policy is GTK_POLICY_NONE
  // then GtkTextView resizes itself (resizes parent) while adding text,
  // so our TMemo size grows.
  // http://stackoverflow.com/questions/2695843/gtktextview-automatically-resizing/16881764#16881764
  // http://stackoverflow.com/questions/15534475/how-can-i-create-a-fixed-size-gtk-textview-in-gtk3
  // https://bugzilla.gnome.org/show_bug.cgi?id=690099
  // seem to be fixed in 3.8.2


  if (gtk_get_major_version = 3) and (gtk_get_minor_version <= 8) then
  begin
    if AScrollStyle.X = GTK_POLICY_NEVER then
      AScrollStyle.X := GTK_POLICY_AUTOMATIC;
    if AScrollStyle.Y = GTK_POLICY_NEVER then
      AScrollStyle.Y := GTK_POLICY_AUTOMATIC;
  end;


  PGtkScrolledWindow(Result)^.set_policy(AScrollStyle.X, AScrollStyle.Y);

  PGtkScrolledWindow(Result)^.set_shadow_type(BorderStyleShadowMap[AMemo.BorderStyle]);
  PGtkScrolledWindow(Result)^.get_vscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.get_hscrollbar^.set_can_focus(False);

  FCentralWidget^.set_can_focus(True);
  PGtkScrolledWindow(Result)^.set_can_focus(False);
end;

function TGtk3Memo.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := False;
end;

function TGtk3Memo.getHorizontalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_hscrollbar);
end;

function TGtk3Memo.getVerticalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_vscrollbar);
end;

function TGtk3Memo.GetScrolledWindow: PGtkScrolledWindow;
begin
  if IsWidgetOK then
    Result := PGtkScrolledWindow(Widget)
  else
    Result := nil;
end;

function TGtk3Memo.GetAlignment: TAlignment;
var
  AJustification: TGtkJustification;
begin
  Result := taLeftJustify;
  if IsWidgetOk then
  begin
    AJustification := PGtkTextView(GetContainerWidget)^.get_justification;
    if AJustification = GTK_JUSTIFY_RIGHT then
      Result := taRightJustify
    else
    if AJustification = GTK_JUSTIFY_CENTER then
      Result := taCenter;
  end;
end;

function TGtk3Memo.GetReadOnly: Boolean;
begin
  Result := True;
  if IsWidgetOk then
    Result := not PGtkTextView(GetContainerWidget)^.get_editable;
end;

function TGtk3Memo.GetWantTabs: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := PGtkTextView(GetContainerWidget)^.get_accepts_tab;
end;

function TGtk3Memo.GetWordWrap: Boolean;
begin
  Result := True;
  if IsWidgetOk then
    Result := PGtkTextView(GetContainerWidget)^.get_wrap_mode = GTK_WRAP_WORD;
end;

procedure TGtk3Memo.SetAlignment(AValue: TAlignment);
begin
  if IsWidgetOk then
    PGtkTextView(GetContainerWidget)^.set_justification(AGtkJustification[AValue]);
end;

procedure TGtk3Memo.SetReadOnly(AValue: Boolean);
begin
  if IsWidgetOk then
    PGtkTextView(GetContainerWidget)^.set_editable(not AValue);
end;

procedure TGtk3Memo.SetWantTabs(AValue: Boolean);
begin
  if IsWidgetOK then
    PGtkTextView(GetContainerWidget)^.set_accepts_tab(AValue);
end;

procedure TGtk3Memo.SetWordWrap(AValue: Boolean);
begin
  if IsWidgetOk then
  begin
    if AValue then
      PGtkTextView(GetContainerWidget)^.set_wrap_mode(GTK_WRAP_WORD)
    else
      PGtkTextView(GetContainerWidget)^.set_wrap_mode(GTK_WRAP_NONE);
  end;
end;

function TGtk3Memo.getText: String;
var
  ABuffer: PGtkTextBuffer;
  AIter: TGtkTextIter;
  ALastIter: TGtkTextIter;
begin
  Result := '';
  if IsWidgetOk then
  begin
    ABuffer := PGtkTextView(FCentralWidget)^.get_buffer;
    ABuffer^.get_start_iter(@AIter);
    ABuffer^.get_end_iter(@ALastIter);
    Result := ABuffer^.get_text(@AIter, @ALastIter, False);
  end;
  // DebugLn('TGtk3Memo.getText Result=',Result);
end;

procedure TGtk3Memo.setText(AValue: String);
var
  ABuffer: PGtkTextBuffer;
  AIter: PGtkTextIter;
begin
  // DebugLn('TGtk3Memo.setText AValue=',AValue);
  if IsWidgetOk then
  begin
    ABuffer := PGtkTextView(FCentralWidget)^.get_buffer;
    ABuffer^.set_text(PgChar(AValue), -1);
    ABuffer^.get_start_iter(AIter);
    ABuffer^.place_cursor(AIter);
  end;
end;

{ TGtk3ListBox }

procedure Gtk3ListBoxSelectionChanged(ASelection: PGtkTreeSelection; AData: GPointer); cdecl;
var
  Msg: TLMessage;
begin
  // DebugLn('Gtk3ListBoxSelectionChanged ');
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_SELCHANGE;
  if not TGtk3Widget(AData).InUpdate then
    TGtk3Widget(AData).DeliverMessage(Msg, False);
end;

function TGtk3ListBox.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AListBox: TCustomListBox;
  ListStore: PGtkListStore;
  ItemList: TGtkListStoreStringList;
  AColumn: PGtkTreeViewColumn;
  Renderer : PGtkCellRenderer;
  VAdjust, HAdjust: PGtkAdjustment;
begin
  FScrollX := 0;
  FScrollY := 0;
  FListBoxStyle := lbStandard;

  FWidgetType := FWidgetType + [wtTreeModel, wtListBox, wtScrollingWin];
  AListBox := TCustomListBox(LCLObject);


  Result := PGtkScrolledWindow(TGtkScrolledWindow.new(nil, nil));
  Result^.show;

  ListStore := gtk_list_store_new (2, [G_TYPE_STRING, G_TYPE_POINTER, nil]);
  FCentralWidget := TGtkTreeView.new_with_model(PGtkTreeModel(ListStore));
  PGtkTreeView(FCentralWidget)^.set_headers_visible(False);
  g_object_unref (liststore);

  ItemList := TGtkListStoreStringList.Create(PGtkListStore(PGtkTreeView(FCentralWidget)^.get_model), 0, LCLObject);
  g_object_set_data(PGObject(FCentralWidget),GtkListItemLCLListTag, ItemList);

  Renderer := LCLIntfCellRenderer_New();

  g_object_set_data(PGObject(renderer), 'lclwidget', Self);

  AColumn := gtk_tree_view_column_new_with_attributes ('LISTITEMS', renderer,
             ['text', 0, nil]);

  g_object_set_data(PGObject(AColumn), 'lclwidget', Self);

  // maybe create GtkCellLayout class with our implementation and set that layout
  // to AColumn
  // PGtkCellLayout(AColumn)^.set_cell_data_func()
  // PGtkCellLayout(AColumn)^.set_cell_data_func(renderer, @LCLIntfRenderer_GtkCellLayoutDataFunc, Self, nil);
  AColumn^.set_cell_data_func(renderer, @LCLIntfRenderer_ColumnCellDataFunc, Self, nil);

  PGtkTreeView(FCentralWidget)^.append_column(AColumn);

  AColumn^.set_clickable(True);

  // AColumn^set_cell_data_func(AColumn, renderer, @LCLIntfRenderer_ColumnCellDataFunc, Self, nil);

  PGtkScrolledWindow(Result)^.add(FCentralWidget);

  PGtkScrolledWindow(Result)^.get_vscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.get_hscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.set_policy(GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
  FListBoxStyle := AListBox.Style;
  if FListBoxStyle <> lbOwnerDrawVariable then
  begin
    AColumn^.set_sizing(GTK_TREE_VIEW_COLUMN_FIXED);
    PGtkTreeView(FCentralWidget)^.set_fixed_height_mode(True);
  end;

end;

function TGtk3ListBox.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := False;
end;

procedure TGtk3ListBox.InitializeWidget;
var
  ASelection: PGtkTreeSelection;
begin
  inherited InitializeWidget;
  g_signal_connect_data(GetSelection, 'changed', TGCallback(@Gtk3ListBoxSelectionChanged), Self, nil, 0);
end;

function TGtk3ListBox.getHorizontalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_hscrollbar);
end;

function TGtk3ListBox.getVerticalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_vscrollbar);
end;

function TGtk3ListBox.GetScrolledWindow: PGtkScrolledWindow;
begin
  if IsWidgetOK then
    Result := PGtkScrolledWindow(Widget)
  else
    Result := nil;
end;

function TGtk3ListBox.GetItemIndex: Integer;
var
  TreeView: PGtkTreeView;
  Path: PGtkTreePath;
  Column: PGtkTreeViewColumn;
  Selection: PGtkTreeSelection;
begin
  Result := -1;
  if Gtk3IsWidget(FWidget) then
  begin
    Path := nil;
    Column := nil;
    TreeView := PGtkTreeView(GetContainerWidget);
    TreeView^.get_cursor(@Path, @Column);
    if Path <> nil then
    begin
      Result := gtk_tree_path_get_indices(Path)^;
      if Result = 0 then
      begin
        Selection :=  TreeView^.get_selection;
        if not Selection^.path_is_selected(Path) then
          Result := -1;
      end;
    end;
  end;
end;

function TGtk3ListBox.GetMultiSelect: Boolean;
var
  Selection: PGtkTreeSelection;
begin
  if IsWidgetOk then
  begin
    Selection := GetSelection;
    if Selection <> nil then
      Result := Selection^.get_mode <> GTK_SELECTION_SINGLE;
  end;
end;

procedure TGtk3ListBox.SetItemIndex(AValue: Integer);
var
  TreeView: PGtkTreeView;
  Selection: PGtkTreeSelection;
  Path: PGtkTreePath;
begin
  if Gtk3IsWidget(FWidget) then
  begin
    TreeView := PGtkTreeView(GetContainerWidget);
    Selection := GetSelection;
    if (AValue < 0) then
      Path := nil
    else
      Path := gtk_tree_path_new_from_indices(AValue, [-1]);

    // if singleselection mode then selection = itemindex
    if Path <> nil then
    begin
      gtk_tree_view_set_cursor(TreeView, Path, nil, False);
    end else
    begin
      Path := gtk_tree_path_new_from_indices(0, [-1]);
        gtk_tree_view_set_cursor(TreeView, Path, nil, False);
      gtk_tree_selection_unselect_all(Selection);
    end;

    if Path <> nil then
      gtk_tree_path_free(Path);
  end;
end;

procedure TGtk3ListBox.SetListBoxStyle(AValue: TListBoxStyle);
begin
  if FListBoxStyle=AValue then Exit;
  FListBoxStyle:=AValue;
end;

procedure TGtk3ListBox.SetMultiSelect(AValue: Boolean);
var
  Selection: PGtkTreeSelection;
begin
  if IsWidgetOk then
  begin
    Selection := GetSelection;
    if Selection <> nil then
    begin
      if AValue then
        Selection^.set_mode(GTK_SELECTION_MULTIPLE)
      else
        Selection^.set_mode(GTK_SELECTION_SINGLE);
    end;
  end;
end;

function TGtk3ListBox.GetSelCount: Integer;
var
  Selection: PGtkTreeSelection;
  Rows: PGList;
  ListStoreModel: PGtkTreeModel;
begin
  Result := 0;
  if not Gtk3IsWidget(FWidget) then
    exit;
  Selection := GetSelection;
  if Selection = nil then
    exit;
  Rows := Selection^.get_selected_rows(@ListStoreModel);
  Result := g_list_length(Rows);
  g_list_free(Rows);
end;

function TGtk3ListBox.GetSelection: PGtkTreeSelection;
begin
  if not IsWidgetOk then
    exit(nil);
  Result := PGtkTreeView(GetContainerWidget)^.get_selection;
end;

function TGtk3ListBox.GetItemSelected(const AIndex: Integer): Boolean;
var
  ASelection: PGtkTreeSelection;
  AModel: PGtkTreeModel;
  Item: TGtkTreeIter;
begin
  Result := False;

  if not IsWidgetOK then
    exit;

  AModel := PGtkTreeView(GetContainerWidget)^.model;

  if AModel = nil then
    exit;

  ASelection := GetSelection;

  if ASelection = nil then
    exit;

  if AModel^.iter_nth_child(@Item, nil, AIndex) then
    Result := ASelection^.iter_is_selected(@Item);
end;

procedure TGtk3ListBox.SelectItem(const AIndex: Integer; ASelected: Boolean);
var
  ASelection: PGtkTreeSelection;
  AModel: PGtkTreeModel;
  Iter: TGtkTreeIter;
begin
  if not IsWidgetOK then
    exit;

  AModel := PGtkTreeView(getContainerWidget)^.model;

  if AModel = nil then
    exit;

  ASelection := GetSelection;

  if AModel^.iter_nth_child(@Iter, nil, AIndex) then
  begin
    case ASelected of
      True:
        if not ASelection^.iter_is_selected(@Iter) then
          ASelection^.select_iter(@Iter);
      False:
        if ASelection^.iter_is_selected(@Iter) then
          ASelection^.unselect_iter(@Iter);
    end;
  end;
end;

procedure TGtk3ListBox.SetTopIndex(const AIndex: Integer);
var
  AModel: PGtkTreeModel;
  Iter: TGtkTreeIter;
  APath: PGtkTreePath;
begin
  AModel := PGtkTreeView(getContainerWidget)^.model;

  if not AModel^.iter_nth_child(@Iter, nil, AIndex) then
    exit;
  APath := AModel^.get_path(@Iter);
  PGtkTreeView(getContainerWidget)^.scroll_to_cell(APath, nil, False, 0.0, 0.0);
  APath^.free;
end;

{ TGtk3CheckListBox }

procedure Gtk3WS_CheckListBoxDataFunc({%H-}tree_column: PGtkTreeViewColumn;
  cell: PGtkCellRenderer; tree_model: PGtkTreeModel; iter: PGtkTreeIter; {%H-}data: Pointer); cdecl;
var
  b: byte;
  ADisabled: gboolean;
  AValue: TCheckBoxState;
begin
  B := 0;
  ADisabled := False;
  gtk_tree_model_get(tree_model, iter, [gtk3CLBState, @b, -1]);
  gtk_tree_model_get(tree_model, iter, [gtk3CLBDisabled, @ADisabled, -1]);
  AValue := TCheckBoxState(b); // TCheckBoxState is 4 byte
  g_object_set(cell, 'inconsistent', [gboolean(AValue = cbGrayed), nil]);
  if AValue <> cbGrayed then
    gtk_cell_renderer_toggle_set_active(PGtkCellRendererToggle(cell), AValue = cbChecked);

  g_object_set(cell, 'activatable', [gboolean(not ADisabled), nil]);
end;

procedure Gtk3WS_CheckListBoxToggle({%H-}cellrenderertoggle : PGtkCellRendererToggle;
  arg1 : PGChar; AData: GPointer); cdecl;
var
  Mess: TLMessage;
  Param: PtrInt;
  Iter, IterParent : TGtkTreeIter;
  TreeView: PGtkTreeView;
  ListStore: PGtkTreeModel;
  Path: PGtkTreePath;
  AState: TCheckBoxState;
begin
  Val(arg1, Param);

  TreeView := PGtkTreeView(TGtk3CheckListBox(AData).GetContainerWidget);
  ListStore := gtk_tree_view_get_model(TreeView);
  if gtk_tree_model_iter_nth_child(ListStore, @Iter, nil, Param) then
    begin
      TCustomCheckListBox(TGtk3Widget(AData).LCLObject).Toggle(Param);
      AState := TCustomCheckListBox(TGtk3Widget(AData).LCLObject).State[Param];
      gtk_list_store_set(PGtkListStore(ListStore), @Iter, [gtk3CLBState,
        Byte(AState), -1]);
    end;


  Path := gtk_tree_path_new_from_indices(Param, [-1]);
  if Path <> nil then
  begin
    gtk_tree_view_set_cursor(TreeView, Path, nil, False);
    gtk_tree_path_free(Path);
  end;

  FillChar(Mess{%H-}, SizeOf(Mess), #0);
  Mess.Msg := LM_CHANGED;

  Mess.Result := 0;
  Mess.WParam := Param;
  DeliverMessage(TGtk3Widget(AData).LCLObject, Mess);

end;

function TGtk3CheckListBox.CreateWidget(const Params: TCreateParams
  ): PGtkWidget;
var
  ACheckListBox: TCustomCheckListBox;
  ListStore: PGtkListStore;
  ItemList: TGtkListStoreStringList;
  AColumn: PGtkTreeViewColumn;
  Toggle: PGtkCellRendererToggle;
  Renderer : PGtkCellRenderer;
  VAdjust, HAdjust: PGtkAdjustment;
  AScrollStyle: TPoint;
  TreeModel: PGtkTreeModel;
begin
  FScrollX := 0;
  FScrollY := 0;
  FWidgetType := FWidgetType + [wtTreeModel, wtListBox, wtCheckListBox, wtScrollingWin];
  ACheckListBox := TCustomCheckListBox(LCLObject);
  FListBoxStyle := lbStandard;

  Result := PGtkScrolledWindow(TGtkScrolledWindow.new(nil, nil));
  Result^.show;

  ListStore := gtk_list_store_new (4, [G_TYPE_UCHAR, G_TYPE_STRING, G_TYPE_POINTER, G_TYPE_BOOLEAN, nil]);
  FCentralWidget := TGtkTreeView.new_with_model(PGtkTreeModel(ListStore));
  PGtkTreeView(FCentralWidget)^.set_headers_visible(False);
  g_object_unref (liststore);

  AColumn := gtk_tree_view_column_new;

  // checkable column
  Toggle := gtk_cell_renderer_toggle_new;
  g_object_set_data(PGObject(Toggle), 'lclwidget', Self);

  AColumn^.set_title('CHECKBINS');
  AColumn^.pack_start(Toggle, True);
  AColumn^.set_cell_data_func(Toggle, @Gtk3WS_CheckListBoxDataFunc, Self, nil);
  Toggle^.set_active(True);
  PGtkTreeView(FCentralWidget)^.append_column(AColumn);
  AColumn^.set_clickable(True);

  g_signal_connect_data(Toggle, 'toggled', TGCallback(@Gtk3WS_CheckListBoxToggle), Self, nil, 0);

  Renderer := LCLIntfCellRenderer_New(); // gtk_cell_renderer_text_new;

  g_object_set_data(PGObject(Renderer), 'lclwidget', Self);

  AColumn := gtk_tree_view_column_new_with_attributes ('LISTITEMS', Renderer,
             ['text', 1, nil]);

  g_object_set_data(PGObject(AColumn), 'lclwidget', Self);

  // AColumn^.pack_start(Renderer, True);

  AColumn^.set_cell_data_func(Renderer, @LCLIntfRenderer_ColumnCellDataFunc, Self, nil);

  PGtkTreeView(FCentralWidget)^.append_column(AColumn);

  ItemList := TGtkListStoreStringList.Create(PGtkListStore(PGtkTreeView(FCentralWidget)^.get_model), 1, LCLObject);
  g_object_set_data(PGObject(FCentralWidget),GtkListItemLCLListTag, ItemList);


  AColumn^.set_clickable(True);

  // AColumn^set_cell_data_func(AColumn, renderer, @LCLIntfRenderer_ColumnCellDataFunc, Self, nil);

  PGtkScrolledWindow(Result)^.add(FCentralWidget);


  PGtkScrolledWindow(Result)^.get_vscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.get_hscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.set_policy(GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
  FListBoxStyle := ACheckListBox.Style;
  if ACheckListBox.MultiSelect then
    PGtkTreeView(FCentralWidget)^.get_selection^.set_mode(GTK_SELECTION_MULTIPLE)
  else
    PGtkTreeView(FCentralWidget)^.get_selection^.set_mode(GTK_SELECTION_SINGLE);
  // AListBox.Style;
  if FListBoxStyle <> lbOwnerDrawVariable then
  begin
    //AColumn^.set_sizing(GTK_TREE_VIEW_COLUMN_FIXED);
    //PGtkTreeView(FCentralWidget)^.set_fixed_height_mode(True);
  end;

end;

{ TGtk3ListView }

function Gtk3WS_ListViewItemPreSelected({%H-}selection: PGtkTreeSelection; {%H-}model: PGtkTreeModel;
  path: PGtkTreePath; path_is_currently_selected: GBoolean; AData: GPointer): GBoolean; cdecl;
begin
  // DebugLn('Gtk3WS_ListViewItemSelected ,path selected ',dbgs(path_is_currently_selected));
  // this function is called *before* the item is selected
  // The result should be True to allow the Item to change selection
  Result := True;

  if (AData = nil) or TGtk3Widget(AData).InUpdate then
    exit;

  if not Assigned(TGtk3ListView(AData).FPreselectedIndices) then
    TGtk3ListView(AData).FPreselectedIndices := TFPList.Create;

  if TGtk3ListView(AData).FPreselectedIndices.IndexOf(Pointer(PtrInt(gtk_tree_path_get_indices(path)^))) = -1 then
    TGtk3ListView(AData).FPreselectedIndices.Add(Pointer(PtrInt(gtk_tree_path_get_indices(path)^)));
end;

procedure Gtk3WS_ListViewItemSelected(ASelection: PGtkTreeSelection; AData: GPointer); cdecl;
var
  ATreeView: PGtkTreeView;
  AList: PGList;
  Msg: TLMNotify;
  NM: TNMListView;
  Path: PGtkTreePath;
  Indices: Integer;
  i, j: Integer;
  B: Boolean;
begin
  if (AData = nil) or TGtk3Widget(AData).InUpdate then
    exit;
  if not Assigned(TGtk3ListView(AData).FPreselectedIndices) then
    exit;
  ATreeView := gtk_tree_selection_get_tree_view(ASelection);
  AList := gtk_tree_selection_get_selected_rows(ASelection, nil);
  TGtk3Widget(AData).BeginUpdate; // dissalow entering Gtk3WS_ListViewItemPreSelected
  try
    for i := 0 to TGtk3ListView(AData).FPreselectedIndices.Count - 1 do
    begin
      FillChar(Msg{%H-}, SizeOf(Msg), 0);
      Msg.Msg := CN_NOTIFY;
      FillChar(NM{%H-}, SizeOf(NM), 0);
      NM.hdr.hwndfrom := HWND(TGtk3Widget(AData));
      NM.hdr.code := LVN_ITEMCHANGED;
      NM.iItem := PtrInt(TGtk3ListView(AData).FPreselectedIndices.Items[i]);
      NM.iSubItem := 0;
      B := False;
      for j := 0 to g_list_length(AList) - 1 do
      begin
        Path := g_list_nth_data(AList, guint(j));
        if Path <> nil then
        begin
          Indices := gtk_tree_path_get_indices(Path)^;
          B := Indices = PtrInt(TGtk3ListView(AData).FPreselectedIndices.Items[i]);
          if B then
            break;
        end;
      end;
      if not B then
        NM.uOldState := LVIS_SELECTED
      else
        NM.uNewState := LVIS_SELECTED;
      NM.uChanged := LVIF_STATE;
      Msg.NMHdr := @NM.hdr;
      DeliverMessage(TGtk3Widget(AData).LCLObject, Msg);
    end;
  finally
    FreeAndNil(TGtk3ListView(AData).FPreselectedIndices);
    if AList <> nil then
      g_list_free(AList);
    TGtk3Widget(AData).EndUpdate;
  end;
end;

function TGtk3ListView.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AListView: TCustomListView;
  AScrollStyle: TPoint;
  PtrType: GType;
  TreeModel: PGtkTreeModel;
begin
  FImages := nil;
  FScrollX := 0;
  FScrollY := 0;
  FPreselectedIndices := nil;
  FWidgetType := FWidgetType + [wtTreeModel, wtListView, wtScrollingWin];
  AListView := TCustomListView(LCLObject);
  Result := PGtkScrolledWindow(TGtkScrolledWindow.new(nil, nil));

  PtrType := G_TYPE_POINTER;

  TreeModel := PGtkTreeModel(gtk_list_store_newv(1, @PtrType));

  if TListView(AListView).ViewStyle in [vsIcon,vsSmallIcon] then
    FCentralWidget := TGtkIconView.new_with_model(TreeModel)
  else
    FCentralWidget := TGtkTreeView.new_with_model(TreeModel);

  FIsTreeView := not (TListView(AListView).ViewStyle in [vsIcon,vsSmallIcon]);

  FCentralWidget^.set_has_window(True);
  FCentralWidget^.show;

  PGtkScrolledWindow(Result)^.add(FCentralWidget);
  //PGtkScrolledWindow(Result)^.set_focus_child(FCentralWidget);

  AScrollStyle := Gtk3TranslateScrollStyle(TListView(AListView).ScrollBars);
  // gtk3 scrolled window hates GTK_POLICY_NONE
  PGtkScrolledWindow(Result)^.set_policy(AScrollStyle.X, AScrollStyle.Y);
  PGtkScrolledWindow(Result)^.set_shadow_type(BorderStyleShadowMap[AListView.BorderStyle]);
  PGtkScrolledWindow(Result)^.get_vscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.get_hscrollbar^.set_can_focus(False);
  g_object_unref (PGObject(TreeModel));
  PGtkScrolledWindow(Result)^.set_can_focus(False);
  PGtkTreeView(FCentralWidget)^.set_can_focus(True);
  if FIsTreeView then
  begin
    gtk_tree_selection_set_select_function(PGtkTreeView(FCentralWidget)^.get_selection, TGtkTreeSelectionFunc(@Gtk3WS_ListViewItemPreSelected),
      Self, nil);
    g_signal_connect_data(PGtkTreeView(FCentralWidget)^.get_selection, 'changed', TGCallback(@Gtk3WS_ListViewItemSelected), Self, nil, 0);
  end;
  // if FIsTreeView then
  //  PGtkTreeView(FCentralWidget)^.set_search_column(0);
end;

function TGtk3ListView.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := False;
end;

destructor TGtk3ListView.Destroy;
begin
  ClearImages;
  FreeAndNil(FImages);
  FreeAndNil(FPreselectedIndices);
  inherited Destroy;
end;

function TGtk3ListView.getHorizontalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_hscrollbar);
end;

function TGtk3ListView.getVerticalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_vscrollbar);
end;

function TGtk3ListView.GetScrolledWindow: PGtkScrolledWindow;
begin
  if IsWidgetOK then
    Result := PGtkScrolledWindow(Widget)
  else
    Result := nil;
end;

procedure TGtk3ListView.ClearImages;
var
  i: Integer;
begin
  if Assigned(FImages) then
  begin
    for i := FImages.Count - 1 downto 0 do
      if FImages[i] <> nil then
        TGtk3Object(FImages[i]).Free;
    FImages.Clear;
  end;
end;

procedure TGtk3ListView.ColumnDelete(AIndex: Integer);
var
  AColumn: PGtkTreeViewColumn;
begin
  if IsWidgetOK and IsTreeView then
  begin
    AColumn := PGtkTreeView(GetContainerWidget)^.get_column(AIndex);
    if (AColumn<>nil) then
      PGtkTreeView(GetContainerWidget)^.remove_column(AColumn);
  end;
end;

function TGtk3ListView.ColumnGetWidth(AIndex: Integer): Integer;
var
  AColumn: PGtkTreeViewColumn;
begin
  Result := 0;
  if IsWidgetOK and IsTreeView then
  begin
    AColumn := PGtkTreeView(GetContainerWidget)^.get_column(AIndex);
    if (AColumn<>nil) then
      Result := AColumn^.get_width;
  end;
end;

procedure Gtk3WSLV_ListViewGetPixbufDataFuncForColumn(tree_column: PGtkTreeViewColumn;
  cell: PGtkCellRenderer; tree_model: PGtkTreeModel; iter: PGtkTreeIter; AData: GPointer); cdecl;
var
  ListItem: TListItem;
  Images: TFPList;
  // Widgets: PTVWidgets;
  ListColumn: TListColumn;
  ImageIndex: Integer;
  ColumnIndex: Integer;
  APath: PGtkTreePath;
begin
  // TODO: set_property('pixbuf', TGValue);
  // PGtkCellRendererPixbuf(cell)^.pixbuf := nil;
  gtk_tree_model_get(tree_model, iter, [0, @ListItem, -1]);

  ListColumn := TListColumn(g_object_get_data(tree_column, 'TListColumn'));
  if ListColumn = nil then
    Exit;
  ColumnIndex := ListColumn.Index;
  // Images := Widgets^.Images;
  Images := TGtk3ListView(AData).Images;
  if Images = nil then
    Exit;
  ImageIndex := -1;

  if (ListItem = nil) and TCustomListView(TGtk3Widget(AData).LCLObject).OwnerData then
  begin
    APath := gtk_tree_model_get_path(tree_model,iter);
    ListItem := TCustomListView(TGtk3Widget(AData).LCLObject).Items[gtk_tree_path_get_indices(APath)^];
    gtk_tree_path_free(APath);
  end;

  if ListItem = nil then
    Exit;

  if ColumnIndex = 0 then
    ImageIndex := ListItem.ImageIndex
  else
    if ColumnIndex -1 <= ListItem.SubItems.Count-1 then
      ImageIndex := ListItem.SubItemImages[ColumnIndex-1];

  (* TODO: set property
  if (ImageIndex > -1) and (ImageIndex <= Images.Count-1) then
    PGtkCellRendererPixbuf(cell)^.pixbuf := PGdkPixbuf(Images.Items[ImageIndex])
  else
    PGtkCellRendererPixbuf(cell)^.pixbuf := nil;
   *)
end;

procedure Gtk3WS_ListViewColumnClicked(column: PGtkTreeViewColumn; AData: GPointer); cdecl;
var
  AColumn: TListColumn;
  Msg: TLMNotify;
  NM: TNMListView;
begin
  AColumn := TListColumn(g_object_get_data(PGObject(column), 'TListColumn'));

  if (AColumn = nil) or (AData = nil) then
    exit;

  FillChar(Msg{%H-}, SizeOf(Msg), 0);
  Msg.Msg := CN_NOTIFY;

  FillChar(NM{%H-}, SizeOf(NM), 0);
  NM.hdr.hwndfrom := {%H-}PtrUInt(AData);
  NM.hdr.code := LVN_COLUMNCLICK;
  NM.iItem := -1;
  NM.iSubItem := AColumn.Index;
  Msg.NMHdr := @NM.hdr;
  DeliverMessage(TGtk3Widget(AData).LCLObject, Msg);
end;

procedure TGtk3ListView.ColumnInsert(AIndex: Integer; AColumn: TListColumn);
var
  AGtkColumn: PGtkTreeViewColumn;
  PixRenderer,
  TextRenderer: PGtkCellRenderer;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  AGtkColumn := TGtkTreeViewColumn.new;

  PixRenderer := gtk_cell_renderer_pixbuf_new();
  TextRenderer := LCLIntfCellRenderer_New;

  AGtkColumn^.pack_start(PixRenderer, False);
  AGtkColumn^.pack_start(TextRenderer, True);

  // gtk_tree_view_column_set_cell_data_func(column, pixrenderer,  TGtkTreeCellDataFunc(@Gtk2WSLV_ListViewGetPixbufDataFuncForColumn), WidgetInfo, nil);
  // gtk_tree_view_column_set_cell_data_func(column, textrenderer, TGtkTreeCellDataFunc(@LCLIntfCellRenderer_CellDataFunc), Self, nil);
  AGtkColumn^.set_cell_data_func(PixRenderer, @Gtk3WSLV_ListViewGetPixbufDataFuncForColumn, Self, nil);


  AGtkColumn^.set_cell_data_func(PGtkCellRenderer(TextRenderer), TGtkTreeCellDataFunc(@LCLIntfCellRenderer_CellDataFunc), Self, nil);

  //store the TColumn in the column data for callbacks
  g_object_set_data(AGtkColumn, PgChar('TListColumn'), gpointer(AColumn));

  g_signal_connect_data(AGtkColumn,'clicked', TGCallback(@Gtk3WS_ListViewColumnClicked), Self, nil, 0);
  PGtkTreeView(GetContainerWidget)^.insert_column(AGtkColumn, AIndex);
  AGtkColumn^.set_clickable(True);

end;

procedure TGtk3ListView.SetAlignment(AIndex: Integer; AColumn: TListColumn;
  AAlignment: TAlignment);
var
  AGtkColumn: PGtkTreeViewColumn;
  AFloat: Double;
  AList: PGList;
  textrenderer: PGtkCellRenderer;
  Value: TGValue;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn = nil then
    exit;

  AFloat := 0;
  case AAlignment of
    taRightJustify: AFloat := 1;
    taCenter: AFloat := 0.5;
  end;


  AList := PGtkCellLayout(AGtkColumn)^.get_cells;
  // AList := gtk_tree_view_column_get_cell_renderers(AColumn);
  textrenderer := PGtkCellRenderer(g_list_last(AList)^.data);
  g_list_free(AList);

  Value.g_type := G_TYPE_FLOAT;
  Value.set_float(AFloat);
  g_object_set_property(textrenderer, PChar('xalign'), @Value);

  {now we call set alignment because it calls update over visible rows in col}
  AGtkColumn^.set_alignment(AFloat);
end;

procedure TGtk3ListView.SetColumnAutoSize(AIndex: Integer;
  AColumn: TListColumn; AAutoSize: Boolean);
const
  SizingMap: array[Boolean] of TGtkTreeViewColumnSizing = (
    2 {GTK_TREE_VIEW_COLUMN_FIXED},
    1 {GTK_TREE_VIEW_COLUMN_AUTOSIZE}
  );
var
  AGtkColumn: PGtkTreeViewColumn;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn <> nil then
  begin
    AGtkColumn^.set_resizable(True);
    AGtkColumn^.set_sizing(SizingMap[AAutoSize]);
  end;
end;

procedure TGtk3ListView.SetColumnCaption(AIndex: Integer; AColumn: TListColumn;
  const ACaption: String);
var
  AGtkColumn: PGtkTreeViewColumn;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn <> nil then
  begin
    AGtkColumn^.set_title(PgChar(ACaption));
  end;
end;

procedure TGtk3ListView.SetColumnMaxWidth(AIndex: Integer;
  AColumn: TListColumn; AMaxWidth: Integer);
var
  AGtkColumn: PGtkTreeViewColumn;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn <> nil then
  begin
    if AMaxWidth <= 0 then
      AGtkColumn^.set_max_width(10000)
    else
      AGtkColumn^.set_max_width(AMaxWidth);
  end;
end;

procedure TGtk3ListView.SetColumnMinWidth(AIndex: Integer;
  AColumn: TListColumn; AMinWidth: Integer);
var
  AGtkColumn: PGtkTreeViewColumn;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn <> nil then
    AGtkColumn^.set_min_width(AMinWidth);
end;

procedure TGtk3ListView.SetColumnWidth(AIndex: Integer; AColumn: TListColumn;
  AWidth: Integer);
var
  AGtkColumn: PGtkTreeViewColumn;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn <> nil then
  begin
    AGtkColumn^.set_fixed_width(AWidth + Ord(AWidth < 1));
  end;
  //  AGtkColumn^.set_widget();
end;

procedure TGtk3ListView.SetColumnVisible(AIndex: Integer; AColumn: TListColumn;
  AVisible: Boolean);
var
  AGtkColumn: PGtkTreeViewColumn;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn <> nil then
  begin
    AGtkColumn^.set_visible(AVisible and (TListView(LCLObject).ViewStyle in [vsList, vsReport]));
  end;
end;

procedure TGtk3ListView.ItemDelete(AIndex: Integer);
var
  AModel: PGtkTreeModel;
  Iter: TGtkTreeIter;
begin
  if IsTreeView then
    AModel := PGtkTreeView(getContainerWidget)^.get_model
  else
    AModel := PGtkIconView(getContainerWidget)^.get_model;
  if gtk_tree_model_iter_nth_child(AModel, @Iter, nil, AIndex) then
    gtk_list_store_remove(PGtkListStore(AModel), @Iter);
end;

procedure TGtk3ListView.ItemInsert(AIndex: Integer; AItem: TListItem);
var
  AModel: PGtkTreeModel;
  Iter: TGtkTreeIter;
  NewIndex: Integer;
  AGValue: TGValue;
  AColumns: gint;
begin
  if not IsWidgetOK then
    exit;
  if IsTreeView then
    AModel := PGtkTreeView(getContainerWidget)^.get_model
  else
    AModel := PGtkIconView(getContainerWidget)^.get_model;

  if AIndex = -1 then
    NewIndex := AModel^.iter_n_children(nil)
  else
    NewIndex := AIndex;
  // AGValue.g_type := G_TYPE_POINTER;
  // AGValue.set_pointer(AItem);
  gtk_list_store_insert_with_values(PGtkListStore(AModel), @Iter, NewIndex, [0, Pointer(AItem), -1]);
  // PGtkListStore(AModel)^.insert_with_valuesv(@Iter, NewIndex, @AColumns, @AGValue, 1);
end;

procedure TGtk3ListView.ItemSetText(AIndex, ASubIndex: Integer;
  AItem: TListItem; const AText: String);
var
  Path: PGtkTreePath;
  ItemRect: TGdkRectangle;
begin
  if not IsWidgetOK then
    exit;
  if not getContainerWidget^.get_realized then
    exit;
  if IsTreeView then
  begin
    Path := gtk_tree_path_new_from_indices(AIndex, [-1]);
    PGtkTreeView(GetContainerWidget)^.get_cell_area(Path, nil, @ItemRect);
    gtk_tree_path_free(Path);
  end else
    ItemRect.Height := 1;
  if GetContainerWidget^.get_visible and (ItemRect.height <> 0) then // item is visible
    GetContainerWidget^.queue_draw;
end;

procedure TGtk3ListView.ItemSetState(const AIndex: Integer;
  const AItem: TListItem; const AState: TListItemState; const AIsSet: Boolean);
var
  Path: PGtkTreePath;
  ATreeSelection: PGtkTreeSelection;
begin
  if not IsWidgetOK then
    exit;

  case AState of
    lisCut,
    lisDropTarget:
    begin
      //TODO: do something with the rowcolor ?
    end;

    lisFocused:
    begin
      Path := gtk_tree_path_new_from_string(PgChar(IntToStr(AIndex)));
      if IsTreeView then
      begin
        if AIsSet then
          PGtkTreeView(getContainerWidget)^.set_cursor(Path, nil, False)
        else
          PGtkTreeView(GetContainerWidget)^.set_cursor(Path, nil, False);
      end else
        PGtkIconView(GetContainerWidget)^.set_cursor(Path, nil, False);
      if Path <> nil then
        gtk_tree_path_free(Path);
    end;

    lisSelected:
    begin
      Path := gtk_tree_path_new_from_string(PgChar(IntToStr(AIndex)));
      if IsTreeView then
      begin
        ATreeSelection := PGtkTreeView(GetContainerWidget)^.get_selection;
        if AIsSet and not ATreeSelection^.path_is_selected(Path) then
        begin
          ATreeSelection^.select_path(Path);
          // BroadcastMsg := True;
        end else
        if not AIsSet and ATreeSelection^.path_is_selected(Path) then
        begin
          ATreeSelection^.unselect_path(Path);
          // BroadcastMsg := True;
        end;
      end else
      begin
        if AIsSet and not PGtkIconView(GetContainerWidget)^.path_is_selected(Path) then
        begin
          PGtkIconView(GetContainerWidget)^.select_path(Path);
          // BroadCastMsg := True;
        end else
        if not AIsSet and PGtkIconView(GetContainerWidget)^.path_is_selected(Path) then
        begin
          PGtkIconView(GetContainerWidget)^.unselect_path(Path);
          // BroadCastMsg := True;
        end;
      end;
      if Path <> nil then
        gtk_tree_path_free(Path);
      // if BroadcastMsg then
      //  BroadCastListSelection(ALV, {%H-}PtrUInt(MainView), AIndex, not AIsSet);
    end;
  end;

end;

function TGtk3ListView.ItemGetState(const AIndex: Integer;
  const AItem: TListItem; const AState: TListItemState; out AIsSet: Boolean
  ): Boolean;
var
  Path: PPGtkTreePath;
  Column: PPGtkTreeViewColumn;
  Cell: PPGtkCellRenderer;
  APath: PGtkTreePath;
begin
  Result := False;
  AIsSet := False;
  if not IsWidgetOK then
    exit;
  case AState of
    lisCut,
    lisDropTarget:
    begin
      //TODO: do something with the rowcolor ?
    end;
    lisFocused:
    begin
      Path := nil;
      Column := nil;
      if IsTreeView then
        PGtkTreeView(GetContainerWidget)^.get_cursor(Path, Column)
      else
        PGtkIconView(GetContainerWidget)^.get_cursor(Path, Cell);

      AIsSet := (Path <> nil) and (StrToInt(gtk_tree_path_to_string(path^)) = AIndex);
      if Path <> nil then
        gtk_tree_path_free(Path^);
      Result := True;
    end;

    lisSelected:
    begin
      APath := gtk_tree_path_new_from_string(PChar(IntToStr(AIndex)));
      if IsTreeView then
        AIsSet := PGtkTreeView(GetContainerWidget)^.get_selection^.path_is_selected(APath)
      else
        AIsSet := PGtkIconView(GetContainerWidget)^.path_is_selected(APath);

      if APath <> nil then
        gtk_tree_path_free(APath);
      Result := True;
    end;
  end;
end;

procedure TGtk3ListView.UpdateImageCellsSize;
begin
  // must get renderer via property
  // gtk_tree_view_column_get_cell_renderers
end;

{ TGtk3ComboBox }

function TGtk3ComboBox.GetItemIndex: Integer;
begin
  Result := -1;
  if Assigned(FWidget) and Gtk3IsComboBox(GetContainerWidget) then
    Result := PGtkComboBox(GetContainerWidget)^.get_active;
end;

procedure TGtk3ComboBox.SetDroppedDown(AValue: boolean);
begin
  if Assigned(FWidget) and Gtk3IsComboBox(GetContainerWidget) then
  begin
    if AValue then
      PGtkComboBox(GetContainerWidget)^.popup
    else
      PGtkComboBox(GetContainerWidget)^.popdown;
  end;
end;

procedure TGtk3ComboBox.SetItemIndex(AValue: Integer);
begin
  if IsWidgetOK and Gtk3IsComboBox(GetContainerWidget) then
    PGtkComboBox(GetContainerWidget)^.set_active(AValue);
end;

function TGtk3ComboBox.GetCellView: PGtkCellView;
var
  AList: PGList;
  i: Integer;
begin
  if FCellView = nil then
  begin
    AList := PGtkComboBox(getContainerWidget)^.get_children;
    for i := 0 to g_list_length(AList) -1 do
    begin
      if Gtk3IsCellView(g_list_nth(AList, i)^.data) then
      begin
        FCellView := PGtkCellView(g_list_first(AList)^.data);
        break;
      end;
    end;
    g_list_free(AList);
  end;
  Result := FCellView;
end;

function TGtk3ComboBox.GetPopupWidget: PGtkWidget;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  if PGtkComboBox(GetContainerWidget)^.priv3^.popup_widget <> nil then
    Result := PGtkComboBox(GetContainerWidget)^.priv3^.popup_widget
  else
  if PGtkComboBox(GetContainerWidget)^.priv3^.tree_view <> nil then
    Result := PGtkComboBox(GetContainerWidget)^.priv3^.tree_view;
end;

function TGtk3ComboBox.GetButtonWidget: PGtkWidget;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  if PGtkComboBox(GetContainerWidget)^.priv3^.button <> nil then
    Result := PGtkComboBox(GetContainerWidget)^.priv3^.button;
end;

function TGtk3ComboBox.GetCellViewFrame: PGtkWidget;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  if PGtkComboBox(GetContainerWidget)^.priv3^.cell_view_frame <> nil then
    Result := PGtkComboBox(GetContainerWidget)^.priv3^.cell_view_frame;
end;

function TGtk3ComboBox.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  ACombo: TCustomComboBox;
  ListStore: PGtkListStore;
  ItemList: TGtkListStoreStringList;
  Renderer : PGtkCellRenderer;
  AList: PGList;
begin
  FWidgetType := FWidgetType + [wtTreeModel, wtComboBox];
  ACombo := TCustomComboBox(LCLObject);
  ListStore := gtk_list_store_new (2, [G_TYPE_STRING, G_TYPE_POINTER, nil]);
  if ACombo.Style in [csDropDown, csSimple] then
    Result := PGtkWidget(TGtkComboBox.new_with_model_and_entry(PGtkTreeModel(ListStore)))
  else
    Result := PGtkWidget(TGtkComboBox.new_with_model(PGtkTreeModel(ListStore)));

  if ACombo.Style in [csDropDown, csSimple] then
  begin
    ItemList := TGtkListStoreStringList.Create(PGtkListStore(PGtkComboBox(Result)^.get_model), 0, LCLObject);
    g_object_set_data(PGObject(Result), GtkListItemLCLListTag, ItemList);

    PGtkComboBox(Result)^.set_entry_text_column(0);
    if ACombo.Style = csDropDownList then
      PGtkEditable(PGtkComboBox(Result)^.get_child)^.set_editable(False);
    // do not allow combo button to get focus, entry should take focus
    if PGtkComboBox(Result)^.priv3^.button <> nil then
      PGtkComboBox(Result)^.priv3^.button^.set_can_focus(False);
    // set lclwidget data to entry
    g_object_set_data(PGtkComboBox(Result)^.get_child, 'lclwidget', Self);
    // when we scroll with mouse wheel over entry our scrollevent doesn't catch entry
    // but parent control with window (eg. form), so we are settint all events mask to
    // catch all mouse events on gtkentry.
    PGtkEntry(PGtkComboBox(Result)^.get_child)^.set_events(GDK_ALL_EVENTS_MASK);
  end else
  begin
    // FCentralWidget := PGtkWidget(TGtkComboBox.new_with_model(PGtkTreeModel(ListStore)));
    FCentralWidget := Result;

    ItemList := TGtkListStoreStringList.Create(PGtkListStore(PGtkComboBox(FCentralWidget)^.get_model), 0, LCLObject);
    g_object_set_data(PGObject(FCentralWidget), GtkListItemLCLListTag, ItemList);

    renderer := LCLIntfCellRenderer_New();
    g_object_set_data(PGObject(renderer), 'lclwidget', Self);

    gtk_cell_layout_clear(PGtkCellLayout(FCentralWidget));
    gtk_cell_layout_pack_start(PGtkCellLayout(FCentralWidget), renderer, True);
    if not (ACombo.Style in [csOwnerDrawFixed, csOwnerDrawVariable]) then
      gtk_cell_layout_set_attributes(PGtkCellLayout(FCentralWidget), renderer, ['text', 0, nil]);
    gtk_cell_layout_set_cell_data_func(PGtkCellLayout(FCentralWidget), renderer,
      @LCLIntfCellRenderer_CellDataFunc, Self, nil);

    FCentralWidget := nil;   //FWidget will be returned from getContainerWidget
    // we need cell renderer, but we need f***g GtkEventBox too
    // maybe an workaround is possible for csDropDownList (use entry with readonly param).
    // if we have GtkEventBox, then ComboBox becomes FCentralWidget.
    // Maybe the best thing would be to organize complete combo around GtkEntry
    // Anyway , I dont see any mouse button event in this case, only when entry_set_above_child is used.
    // FCentralWidget := PGtkComboBox(TGtkComboBox.new_with_model(PGtkTreeModel(ListStore)));
    // PGtkEventBox(Result)^.add(FCentralWidget);
    // ItemList := TGtkListStoreStringList.Create(PGtkListStore(PGtkComboBox(FCentralWidget)^.get_model), 0, LCLObject);
    // g_object_set_data(PGObject(FCentralWidget), GtkListItemLCLListTag, ItemList);
    // PGtkEventBox(Result)^.set_visible_window(True);
  end;
  g_object_unref(ListStore);

end;

function TGtk3ComboBox.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := AKey in [VK_UP, VK_DOWN];
end;

function TGtk3ComboBox.getText: String;
begin
  Result := inherited getText;
  if Gtk3IsComboBox(GetContainerWidget) then
    Result := StrPas(PGtkComboBox(GetContainerWidget)^.get_title);
end;

procedure TGtk3ComboBox.setText(AValue: String);
begin
  if Gtk3IsComboBox(FWidget) then
    PGtkComboBox(GetContainerWidget)^.set_title(PgChar(AValue));
end;

procedure TGtk3ComboBox.DumpPrivateStructValues(ADbgEvent: String);
var
  AComboWidget: PGtkComboBox;
  APrivate: PGtkComboBoxPrivate;
begin
  exit;
  AComboWidget := PGtkComboBox(GetContainerWidget);
  APrivate := PGtkComboBoxPrivate(AComboWidget^.priv3);
  DebugLn('** COMBO DUMP OF PGtkComboBoxPrivate struct EVENT=',ADbgEvent);
  DebugLn('BUTTON=',dbgHex(PtrUInt(APrivate^.button)),' ARROW=',dbgHex(PtrUInt(APrivate^.arrow)),
    ' SCROLLEDWINDOW=',dbgHex(PtrUInt(APrivate^.scrolled_window)),
    ' CELLVIEW=',dbgHex(PtrUInt(APrivate^.cell_view)),
    ' CELLAREA=',dbgHex(PtrUInt(APrivate^.area)));
  DebugLn(' PrivatePopupW ',dbgHex(PtrUInt(APrivate^.popup_widget)),
  ' PrivatePopupWin ',dbgHex(PtrUInt(APrivate^.popup_window)),' TreeView ',dbgHex(PtrUInt(APrivate^.tree_view)));
  if Gtk3IsWidget(APrivate^.popup_widget) then
  begin
    DebugLn('POPUPWIDGET VISIBLE ',dbgs(APrivate^.popup_widget^.get_visible),
      ' PopupInProgress=',dbgs(APrivate^.popup_in_progress),' POPUPSHOWN=',
      dbgs(APrivate^.popup_shown),' POPUPIDLE_ID=',dbgs(APrivate^.popup_idle_id));
    if Gtk3IsMenu(APrivate^.popup_widget) then
      DebugLn('POPUPWIDGET IS MENU ')
    else
    if Gtk3IsMenuItem(APrivate^.popup_widget) then
      DebugLn('POPUPWIDGET IS MENUITEM ');
  end;
end;

function TGtk3ComboBox.CanFocus: Boolean;
begin
  Result := False;
  if IsWidgetOK then
  begin
    if PGtkComboBox(FWidget)^.has_entry then
      Result := PGtkComboBox(FWidget)^.get_child^.can_focus
    else
    if GetButtonWidget <> nil then
      Result := GetButtonWidget^.can_focus;
  end;
end;

procedure TGtk3ComboBox.SetFocus;
begin
  {$IFDEF GTK3DEBUGFOCUS}
  DebugLn('TGtk3ComboBox.SetFocus LCLObject ',dbgsName(LCLObject),' WidgetOK ',dbgs(IsWidgetOK),
  ' FWidget <> GetContainerWidget ',dbgs(FWidget <> GetContainerWidget));
  {$ENDIF}
  if Assigned(LCLObject) then
  begin
    if IsWidgetOK  then // and (FWidget <> GetContainerWidget) then
    begin
      if PGtkComboBox(FWidget)^.has_entry then
        FWidget^.grab_focus
      else
      if GetButtonWidget <> nil then
        GetButtonWidget^.grab_focus;
    end else
      inherited SetFocus;
  end else
    inherited SetFocus;
end;

procedure Gtk3ComboBoxChanged(ACombo: PGtkComboBox; AData: gpointer); cdecl;
var
  Msg: TLMessage;
begin
  if AData <> nil then
  begin
    if TGtk3Widget(AData).InUpdate then
      Exit;
    FillChar(Msg, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    TGtk3Widget(AData).DeliverMessage(Msg);
  end;
end;

function GtkPopupCloseUp(AData: Pointer): gboolean; cdecl;
var
  ComboBox: TCustomComboBox;
begin
  ComboBox := TCustomComboBox(TGtk3Widget(AData).LCLObject);
  LCLSendCloseUpMsg(TGtk3Widget(AData).LCLObject);
  Result := False;// stop the timer
end;

procedure GtkNotifyCombo(AObject: PGObject; pspec: PGParamSpec; AData: GPointer); cdecl;
var
  AValue: TGValue;
  AMenu: PGtkWidget;
  ComboBox: TCustomComboBox;
begin
  if pspec^.name = 'popup-shown' then
  begin
    ComboBox := TCustomComboBox(TGtk3Widget(AData).LCLObject);
    AValue.g_type := G_TYPE_BOOLEAN;
    g_object_get_property(AObject, pspec^.name, @AValue); // get property value
    if AValue.data[0].v_int = 0 then // if 0 = False then it is close up
      g_timeout_add(0,@GtkPopupCloseUp, AData)
    else // in other case it is drop down
    begin
      ComboBox.IntfGetItems;
      LCLSendDropDownMsg(ComboBox);
    end;
  end;
end;

procedure Gtk3ComboMenuRealized(AWidget: PGtkWidget; AData: gPointer); cdecl;
begin
  DebugLn('Gtk3ComboMenuRealized *****',dbgsName(TGtk3ComboBox(AData).LCLObject));
end;

procedure TGtk3ComboBox.InitializeWidget;
begin
  inherited InitializeWidget;
  // appears-as-list make it appear as list ... no way, its read only property.
  //OnChange
  g_signal_connect_data(GetContainerWidget, 'changed', TGCallback(@Gtk3ComboBoxChanged), Self, nil, 0);
  //OnCloseUp
  g_signal_connect_data(GetContainerWidget, 'notify', TGCallback(@GtkNotifyCombo), Self, nil, 0);

  //TODO: if we have an entry then use CreateFrom() to create TGtk3Entry
  if Gtk3IsEntry(PGtkComboBox(FWidget)^.get_child) then
  begin
    g_object_set_data(PGtkComboBox(FWidget)^.get_child, 'lclwidget', Self);
    g_signal_connect_data(PGtkComboBox(FWidget)^.get_child, 'event', TGCallback(@Gtk3WidgetEvent), Self, nil, 0);
  end;
  if GetCellView <> nil then
  begin
    gtk_widget_set_events(FCellView, GDK_ALL_EVENTS_MASK);
    g_object_set_data(FCellView, 'lclwidget', Self);
    g_signal_connect_data(FCellView, 'event', TGCallback(@Gtk3WidgetEvent), Self, nil, 0);
  end;
  // set to all combo widgets lclwidget data, so we will easy find TGtk3ComboBox in events.
  if PGtkComboBox(GetContainerWidget)^.priv3^.button <> nil then
  begin
    g_object_set_data(PGObject(PGtkComboBox(GetContainerWidget)^.priv3^.button), 'lclwidget', Self);
    g_signal_connect_data(PGObject(PGtkComboBox(GetContainerWidget)^.priv3^.button), 'event', TGCallback(@Gtk3WidgetEvent), Self, nil, 0);
  end;
  if PGtkComboBox(GetContainerWidget)^.priv3^.popup_widget <> nil then
  begin
    g_object_set_data(PGObject(PGtkComboBox(GetContainerWidget)^.priv3^.popup_widget), 'lclwidget', Self);
    g_signal_connect_data(PGObject(PGtkComboBox(GetContainerWidget)^.priv3^.popup_widget), 'event', TGCallback(@Gtk3WidgetEvent), Self, nil, 0);
    PGtkComboBox(GetContainerWidget)^.priv3^.popup_widget^.set_has_window(True);
    PGtkComboBox(GetContainerWidget)^.priv3^.popup_widget^.set_can_focus(True);
    // g_signal_connect_data(PGObject(PGtkComboBox(GetContainerWidget)^.priv3^.popup_widget), 'map', TGCallback(@Gtk3ComboMenuRealized), Self, nil, 0);
  end;
  if PGtkComboBox(GetContainerWidget)^.priv3^.area <> nil then
    g_object_set_data(PGObject(PGtkComboBox(GetContainerWidget)^.priv3^.area), 'lclwidget', Self);
  // if combo doesnt use menu
  if PGtkComboBox(GetContainerWidget)^.priv3^.tree_view <> nil then
    g_object_set_data(PGObject(PGtkComboBox(GetContainerWidget)^.priv3^.tree_view), 'lclwidget', Self);
end;

function TGtk3ComboBox.GetDroppedDown: boolean;
var
  AValue: TGValue;
begin
  Result := False;
  if Assigned(FWidget) and Gtk3IsComboBox(GetContainerWidget) then
  begin
    AValue.g_type := G_TYPE_BOOLEAN;
    g_object_get_property(PGObject(GetContainerWidget), 'popup-shown', @AValue);
    Result := AValue.data[0].v_int <> 0;
  end;
end;

{ TGtk3Button }

function TGtk3Button.getLayout: Integer;
begin
  Result := FLayout;
  // PGtkButton(FWidget)^.get_image_position;
end;

function TGtk3Button.getMargin: Integer;
begin
  Result := FMargin;
end;

procedure TGtk3Button.SetLayout(AValue: Integer);
begin
  FLayout := AValue;
  if IsWidgetOk then
  begin
    PGtkButton(FWidget)^.set_image_position(AValue);
    // set margin and spacing when layout is changed
    SetMargin(FMargin);
  end;
end;

procedure TGtk3Button.SetMargin(AValue: Integer);
begin
  FMargin := AValue;
  if not IsWidgetOK then
    exit;
  if FMargin = -1 then
    PGtkButton(FWidget)^.set_alignment(0.5, 0.5)
  else
  begin
    case FLayout of
      0 {GTK_POS_LEFT}: PGtkButton(FWidget)^.set_alignment(0, 0.5);
      1 {GTK_POS_RIGHT}: PGtkButton(FWidget)^.set_alignment(1.0, 0.5);
      2 {GTK_POS_TOP}: PGtkButton(FWidget)^.set_alignment(0.5, 0);
      3 {GTK_POS_BOTTOM}: PGtkButton(FWidget)^.set_alignment(0.5, 1);
    end;
  end;
end;

procedure TGtk3Button.SetSpacing(AValue: Integer);
var
  ATGValue: TGValue;
  AImage: PGtkWidget;
begin
  // if FSpacing=AValue then Exit;
  FSpacing:=AValue;
  if AValue < 0 then
    FSpacing := 2;
  ATGValue.g_type := G_TYPE_INT;
  ATGValue.set_int(AValue);

  // no way under gtk3 ... we cannot set style property image-spacing
  // so we are using cheat
  AImage := PGtkButton(FWidget)^.get_image;
  if AImage <> nil then
  begin
    if AValue < 0 then
      AVAlue := 0;
    //TODO: margin depends on layout ! This is ok for left (default) layout
    PGtkImage(AImage)^.set_margin_right(AValue);
  end;
end;

function TGtk3Button.getText: String;
begin
  if IsWidgetOK then
    Result := PGtkButton(FWidget)^.get_label
  else
    Result := '';
end;

procedure TGtk3Button.setText(AValue: String);
begin
  if IsWidgetOk then
    PGtkButton(FWidget)^.set_label(PgChar(AValue));
end;

function TGtk3Button.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  Result := PGtkWidget(TGtkButton.new);
  FMargin := -1;
  FLayout := GTK_POS_LEFT;
  FSpacing := 2; // default gtk3 spacing is 2
end;

function TGtk3Button.IsWidgetOk: Boolean;
begin
  Result := (FWidget <> nil) and Gtk3IsButton(FWidget);
end;

procedure TGtk3Button.SetDefault(const ADefault: Boolean);
begin
  if IsWidgetOk then
    GetContainerWidget^.set_can_default(ADefault);
end;

{ TGtk3ToggleButton }
procedure Gtk3Toggled(AWidget: PGtkToggleButton; AData: gPointer); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := LM_CHANGED;
  if (TGtk3Widget(AData).LCLObject <> nil) and not TGtk3Widget(AData).InUpdate then
    TGtk3Widget(AData).DeliverMessage(Msg, False);
end;

procedure TGtk3ToggleButton.InitializeWidget;
begin
  inherited InitializeWidget;
  g_signal_connect_data(FWidget, 'toggled', TGCallback(@Gtk3Toggled), Self, nil, 0);
end;

function TGtk3ToggleButton.CreateWidget(const Params: TCreateParams
  ): PGtkWidget;
begin
  Result := PGtkWidget(TGtkToggleButton.new);
end;

{ TGtk3CheckBox }

function TGtk3CheckBox.GetState: TCheckBoxState;
begin
  Result := cbUnchecked;
  if IsWidgetOk then
  begin
    if PGtkCheckButton(FWidget)^.get_inconsistent then
      Result := cbGrayed
    else
    if PGtkCheckButton(FWidget)^.get_active then
      Result := cbChecked;
  end;
end;

procedure TGtk3CheckBox.SetState(AValue: TCheckBoxState);
begin
  if IsWidgetOK then
  begin
    if AValue = cbGrayed then
      PGtkCheckButton(FWidget)^.set_inconsistent(True)
    else
      PGtkCheckButton(FWidget)^.set_active(AValue = cbChecked);
  end;
end;

function TGtk3CheckBox.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  Result := PGtkWidget(TGtkCheckButton.new);
end;

{ TGtk3RadioButton }

function TGtk3RadioButton.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  Result := PGtkWidget(TGtkRadioButton.new(nil));
end;

{ TGtk3CustomControl }

function TGtk3CustomControl.CreateWidget(const Params: TCreateParams
  ): PGtkWidget;
var
  FUseLayout: Boolean;
begin
  FScrollX := 0;
  FScrollY := 0;
  FHasPaint := True;
  FUseLayout := False;
  if FUseLayout then
    FWidgetType := [wtWidget, wtLayout, wtScrollingWin, wtCustomControl]
  else
    FWidgetType := [wtWidget, wtContainer, wtScrollingWin, wtCustomControl];
  Result := PGtkScrolledWindow(TGtkScrolledWindow.new(nil, nil));

  if FUseLayout then
    FCentralWidget := TGtkLayout.new(nil, nil)
  else
    FCentralWidget := TGtkFixed.new;

  FCentralWidget^.set_has_window(True);

  // this is deprecated since 3.8 .add() should be used
  // in this case viewport should be blocked somehow.....
  //if FUseLayout or (gtk_get_major_version > 3 or gtk_get_minor_version >=8 )then
  //  PGtkScrolledWindow(Result)^.add(FCentralWidget)
  //else
  //  PGtkScrolledWindow(Result)^.add_with_viewport(FCentralWidget);

  // gtk_container_add() will now automatically add a GtkViewport if the child doesn't implement GtkScrollable.

  PGtkScrolledWindow(Result)^.add(FCentralWidget);

  // PGtkViewport(PGtkScrolledWindow(Result)^.get_child)^.;
  // also works fine with 3.6 but raises asserts
  // PGtkScrolledWindow(Result)^.add(FCentralWidget);
  Result^.set_can_focus(False);
  FCentralWidget^.set_can_focus(True);
end;

function TGtk3CustomControl.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := False;
end;

procedure TGtk3CustomControl.InitializeWidget;
begin
  inherited InitializeWidget;
  SetScrollBarsSignalHandlers;
  g_signal_connect_data(GetScrolledWindow,'scroll-event', TGCallback(@Gtk3ScrolledWindowScrollEvent), Self, nil, 0);
end;

function TGtk3CustomControl.getClientRect: TRect;
var
  Allocation, VAllocation: TGtkAllocation;
  R,RV: TRect;
  w: gint;
  h: gint;
  x: gint;
  y: gint;
  AViewPort: PGtkViewport;
begin
  // Result := inherited getClientRect;
  AViewPort := PGtkViewPort(FCentralWidget^.get_parent);
  if Gtk3IsViewPort(AViewPort) and Gtk3IsGdkWindow(AViewPort^.get_view_window) then
  begin
    AViewPort^.get_view_window^.get_geometry(@x, @y, @w, @h);
    Result := Rect(0, 0, AViewPort^.get_view_window^.get_width, AViewPort^.get_view_window^.get_height);
    // DebugLn('TGtk3CustomControl.GetClientRect via Viewport ',dbgsName(LCLObject),' Result ',dbgs(Result),' X=',dbgs(X),' Y=',dbgs(Y));
    exit;
  end else
    FCentralWidget^.get_allocation(@Allocation);

  with Allocation do
    R := Rect(x, y, width + x, height + y);

  if IsRectEmpty(R) then
    R := Rect(0, 0, 0, 0);

  Result := R;
  // DebugLn('TGtk3CustomControl.GetClientRect normal ',dbgsName(LCLObject),' Result ',dbgs(Result));
  OffsetRect(Result, -Result.Left, -Result.Top);
end;

function TGtk3CustomControl.getHorizontalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_hscrollbar);
  g_object_set_data(Result,'lclwidget',Self);
end;

function TGtk3CustomControl.getVerticalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_vscrollbar);
  g_object_set_data(Result,'lclwidget',Self);
end;

function TGtk3CustomControl.GetScrolledWindow: PGtkScrolledWindow;
begin
  if IsWidgetOK then
    Result := PGtkScrolledWindow(Widget)
  else
    Result := nil;
end;

{ TGtk3ScrollingWinControl }

function TGtk3ScrollingWinControl.CreateWidget(const Params: TCreateParams
  ): PGtkWidget;
var
  ABox: PGtkBox;
begin
  FHasPaint := True;
  FScrollX := 0;
  FScrollY := 0;
  // layout is crap under gtk3
  (*
  FWidgetType := [wtWidget, wtLayout, wtScrollingWin];
  Result := PGtkScrolledWindow(TGtkScrolledWindow.new(nil, nil));
  FCentralWidget := TGtkLayout.new(nil, nil);
  FCentralWidget^.set_has_window(True);
  FCentralWidget^.show;

  PGtkScrolledWindow(Result)^.add(FCentralWidget);
  *)
  FWidgetType := [wtWidget, wtContainer, wtScrollingWin, wtScrollingWinControl];
  Result := PGtkScrolledWindow(TGtkScrolledWindow.new(nil, nil));
  FCentralWidget := TGtkFixed.new;
  FCentralWidget^.set_has_window(True);
  FCentralWidget^.show;

  PGtkScrolledWindow(Result)^.add_with_viewport(FCentralWidget);
  // PGtkScrolledWindow(Result)^.add(FCentralWidget);

  PGtkViewport(PGtkScrolledWindow(Result)^.get_child)^.set_shadow_type(BorderStyleShadowMap[bsNone]);
  PGtkScrolledWindow(Result)^.set_shadow_type(BorderStyleShadowMap[TScrollingWinControl(LCLObject).BorderStyle]);
  PGtkScrolledWindow(Result)^.get_vscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.get_hscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.set_policy(GTK_POLICY_NEVER, GTK_POLICY_NEVER);

  // this is very important
  PGtkScrolledWindow(Result)^.set_can_focus(False);
  FCentralWidget^.set_can_focus(True);
end;

{ TGtk3Window }

function TGtk3Window.GetTitle: String;
begin
  Result := '';
end;

procedure TGtk3Window.SetIcon(AValue: PGdkPixBuf);
begin
  // if FIcon=AValue then Exit;
  if Assigned(FIcon) then
  begin
    FIcon^.unref;
    FIcon := nil;
  end;
  if Gtk3IsGdkPixbuf(AValue) then
    FIcon := PGdkPixbuf(AValue)^.copy
  else
    FIcon := nil;
  //  DebugLn('Setting icon ',dbgHex(PtrUInt(FIcon)),' AppIcon ',dbgHex(PtrUInt(GTK3WidgetSet.AppIcon)));
  PGtkWindow(Widget)^.set_icon(FIcon);
end;

function TGtk3Window.GetSkipTaskBarHint: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := PGtkWindow(Widget)^.get_skip_taskbar_hint;
end;

procedure TGtk3Window.SetSkipTaskBarHint(AValue: Boolean);
begin
  if IsWidgetOK then
    PGtkWindow(Widget)^.set_skip_taskbar_hint(AValue);
end;

procedure TGtk3Window.SetTitle(AValue: String);
begin
  PGtkWindow(FWidget)^.set_title(PGChar(AValue));
end;

function Gtk3WindowState(AWidget: PGtkWidget; AEvent: PGdkEvent; AData: gPointer): GBoolean; cdecl;
var
  Msg: TLMSize;
  AState: TGdkWindowState;
  AScreen: PGdkScreen;
  ActiveWindow: PGdkWindow;
begin
  Result := False;
  FillChar(Msg, SizeOf(Msg), #0);

  AScreen := AWidget^.window^.get_screen;
  ActiveWindow := AScreen^.get_active_window;
  (*
  if ActiveWindow <> AWidget^.window then
    TGtk3Window(AData).Gtk3ActivateWindow(nil)
  else
    TGtk3Window(AData).Gtk3ActivateWindow(AEvent);
  *)
  // window state isn't changed on activate/deactivate, so must provide another solution
  // DebugLn('Gtk3WindowState ',dbgsName(TGtk3Widget(AData).LCLObject),' changedmask=',dbgs(AEvent^.window_state.changed_mask),
  // ' newstate ',dbgs(AEvent^.window_state.new_window_state),' currentState ', dbgs(TGtk3Window(AData).GetWindowState),
  // ' WITHDRAWN ? ',dbgs(TGtk3Window(AData).getWindowState and GDK_WINDOW_STATE_WITHDRAWN));

  Msg.Msg := LM_SIZE;
  Msg.SizeType := SIZE_RESTORED;

  AState := AEvent^.window_state.new_window_state AND NOT GDK_WINDOW_STATE_FOCUSED;

  if AState = 0 then
  begin
    if (AEvent^.window_state.changed_mask = GDK_WINDOW_STATE_ICONIFIED) or
      (AEvent^.window_state.changed_mask = GDK_WINDOW_STATE_MAXIMIZED) or
      (AEvent^.window_state.changed_mask = GDK_WINDOW_STATE_FULLSCREEN) then
      // restore win
    else
      exit;
  end;
  // PGtkWindow(nil)^.window^.get_state;
  if AState and GDK_WINDOW_STATE_ICONIFIED <> 0 then
    Msg.SizeType := SIZE_MINIMIZED
  else
  if AState and GDK_WINDOW_STATE_FULLSCREEN <> 0 then
    Msg.SizeType := SIZE_FULLSCREEN
  else
  if AState and GDK_WINDOW_STATE_MAXIMIZED <> 0 then
    Msg.SizeType := SIZE_MAXIMIZED;

  Msg.SizeType := Msg.SizeType or Size_SourceIsInterface;

  Msg.Width := Word(AWidget^.window^.get_width);
  Msg.Height := Word(AWidget^.window^.get_height);
  // DebugLn('GetWindowState SizeType=',dbgs(Msg.SizeType),' realized ',dbgs(AWidget^.get_realized));
  TGtk3Window(AData).DeliverMessage(Msg);
  // DeliverMessage(Msg);
end;

function TGtk3Window.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  Geometry: TGdkGeometry;
  WinMask: TGdkWindowHints;
  AResize: TGtkResizeMode;
  AForm: TCustomForm;
begin
  FIcon := nil;
  FScrollX := 0;
  FScrollY := 0;

  FHasPaint := True;
  AForm := TCustomForm(LCLObject);

  FWidgetType := [wtWidget, wtLayout, wtScrollingWin, wtWindow];

  Result := TGtkWindow.new(GTK_WINDOW_TOPLEVEL);

  FBox := TGtkVBox.new(GTK_ORIENTATION_VERTICAL, 0);

  //TODO: when menu is added dynamically to the form create FMenuBar
  if (AForm.Menu <> nil) then
  begin
    FMenuBar := TGtkMenuBar.new; // our menubar (needed for main menu)
    // MenuBar
    //  -> Menu    Menu2
    //    Item 1   Item 3
    //    Item 2
    g_object_set_data(Result,'lclmenubar',GPointer(1));
    FBox^.pack_start(FMenuBar, False, False, 0);
  end;

  FScrollWin := PGtkScrolledWindow(TGtkScrolledWindow.new(nil, nil));
  g_object_set_data(FScrollWin,'lclscrollingwindow',GPointer(1));
  g_object_set_data(PGObject(FScrollWin), 'lclwidget', Self);


  FCentralWidget := TGtkLayout.new(nil, nil);
  FCentralWidget^.set_has_window(True);

  if AForm.AutoScroll then
    FScrollWin^.add(FCentralWidget)
  else
    FScrollWin^.add_with_viewport(FCentralWidget);

  FScrollWin^.show;
  FBox^.pack_end(FScrollWin, True, True, 0);
  FBox^.show;

  FScrollWin^.get_vscrollbar^.set_can_focus(False);
  FScrollWin^.get_hscrollbar^.set_can_focus(False);
  FScrollWin^.set_policy(GTK_POLICY_NEVER, GTK_POLICY_NEVER);
  PGtkContainer(Result)^.add(FBox);
  g_signal_connect_data(Result,'window-state-event', TGCallback(@Gtk3WindowState), Self, nil, 0);

  //REMOVE THIS, USED TO TRACK MOUSE MOVE OVER WIDGET TO SEE SIZE OF FIXED !
  //g_object_set_data(PGObject(FScrollWin), 'lcldebugscrollwin', Self);
  //g_object_set_data(PGObject(FCentralWidget), 'lcldebugfixed', Self);
  //g_object_set_data(PGObject(Result), 'lcldebugwindow', Self);
end;

function TGtk3Window.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := False;
end;

function TGtk3Window.getText: String;
begin
  Result := Title;
end;

procedure TGtk3Window.setText(AValue: String);
begin
  Title := AValue;
end;

function TGtk3Window.getClientRect: TRect;
var
  Allocation, VAllocation: TGtkAllocation;
  R,RV: TRect;
  w: gint;
  h: gint;
  x: gint;
  y: gint;
  AViewPort: PGtkViewport;
begin
  AViewPort := PGtkViewPort(FCentralWidget^.get_parent);
  if Gtk3IsViewPort(AViewPort) and Gtk3IsGdkWindow(AViewPort^.get_view_window) then
  begin
    AViewPort^.get_view_window^.get_geometry(@x, @y, @w, @h);
    Result := Rect(0, 0, AViewPort^.get_view_window^.get_width, AViewPort^.get_view_window^.get_height);
    // DebugLn('GetClientRect via Viewport ',dbgsName(LCLObject),' Result ',dbgs(Result));
    exit;
  end else
    FCentralWidget^.get_allocation(@Allocation);

  with Allocation do
    R := Rect(x, y, width + x, height + y);

  if IsRectEmpty(R) then
    R := Rect(0, 0, 0, 0);

  Result := R;
  OffsetRect(Result, -Result.Left, -Result.Top);

  // DebugLn('GetClientRect ',dbgsName(LCLObject),' Result ',dbgs(Result));
end;

function TGtk3Window.getHorizontalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(FScrollWin^.get_hscrollbar);
end;

function TGtk3Window.getVerticalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(FScrollWin^.get_vscrollbar);
end;

function TGtk3Window.GetScrolledWindow: PGtkScrolledWindow;
begin
  if IsWidgetOK then
    Result := FScrollWin
  else
    Result := nil;
end;

destructor TGtk3Window.Destroy;
begin
  // DebugLn('TGtk3Window.Destroy AWidget ',dbgs(IsWidgetOK));
  if Gtk3IsGdkPixbuf(FIcon) then
  begin
    FIcon^.unref;
    FIcon := nil;
  end;
  inherited Destroy;
end;

procedure TGtk3Window.Activate;
begin
  if IsWidgetOk then
  begin
    if Gtk3IsGdkWindow(PGtkWindow(FWidget)^.window) then
    begin
      PGtkWindow(FWidget)^.window^.raise_;
      PGtkWindow(FWidget)^.present;
      PGtkWindow(FWidget)^.activate;
    end;
  end;
end;

procedure TGtk3Window.Gtk3ActivateWindow(AEvent: PGdkEvent);
var
  MsgActivate: TLMActivate;
  FIsActivated: Boolean;
begin
  //gtk3 does not handle activate/deactivate at all
  //even cannot catch it via GDK_FOCUS event ?!?
  FillChar(MsgActivate, SizeOf(MsgActivate), #0);
  MsgActivate.Msg := LM_ACTIVATE;

  if (AEvent <> nil) and PGtkWindow(Widget)^.is_active then
    MsgActivate.Active := WA_ACTIVE
  else
    MsgActivate.Active := WA_INACTIVE;
  MsgActivate.ActiveWindow := HWND(Self);

  // DebugLn('TGtk3Window.Gtk3ActivateWindow ',dbgsName(LCLObject),' Active ',dbgs(PGtkWindow(Widget)^.is_active),
  // ' CustomFormActive ',dbgs(TCustomForm(LCLObject).Active));
  FIsActivated := TCustomForm(LCLObject).Active;
  {do not send activate if form is already activated,
   also do not send activate if TCustomForm.Parent is assigned
   since it's form embedded into another control or form}
  if (Boolean(MsgActivate.Active) = FIsActivated) or (LCLObject.Parent <> nil) then
  else
  begin
    // DebugLn('TGtk3Window.Gtk3ActivateWindow Active ',dbgs(MsgActivate.Active = WA_ACTIVE),
    //  ' Message delivery to lcl ',dbgs(MsgActivate.Active));
    DeliverMessage(MsgActivate);
  end;
end;

function TGtk3Window.Gtk3CloseQuery: Boolean;
var
  Msg : TLMessage;
begin
  {$IFDEF GTK3DEBUGCORE}
    DebugLn('TGtk3Window.Gtk3CloseQuery');
  {$ENDIF}
  FillChar(Msg, SizeOf(Msg), 0);

  Msg.Msg := LM_CLOSEQUERY;

  DeliverMessage(Msg);

  Result := False;
end;

function TGtk3Window.GetWindow: PGdkWindow;
begin
  Result := FWidget^.window;
end;

function TGtk3Window.GetMenuBar: PGtkMenuBar;
begin
  Result := FMenuBar;
end;

function TGtk3Window.GetBox: PGtkBox;
begin
  Result := FBox;
end;

function TGtk3Window.GetWindowState: TGdkWindowState;
begin
  Result := 0;
  if IsWidgetOK and (FWidget^.get_realized) then
    Result := FWidget^.window^.get_state;
end;

{ TGtk3HintWindow }

function TGtk3HintWindow.getText: String;
begin
  Result := FText;
end;

procedure TGtk3HintWindow.setText(AValue: String);
begin
  FText := AValue;
end;

function TGtk3HintWindow.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AForm: THintWindow;
begin
  FText := '';
  FHasPaint := True;
  AForm := THintWindow(LCLObject);

  FWidgetType := [wtWidget, wtContainer, wtScrollingWin, wtWindow, wtHintWindow];

  Result := TGtkWindow.new(GTK_WINDOW_POPUP);

  FBox := TGtkVBox.new(GTK_ORIENTATION_VERTICAL, 0);

  if (AForm.Menu <> nil) then
  begin
    FMenuBar := TGtkMenuBar.new; // our menubar (needed for main menu)
    // MenuBar
    //  -> Menu    Menu2
    //    Item 1   Item 3
    //    Item 2
    g_object_set_data(Result,'lclmenubar',GPointer(1));
    FBox^.pack_start(FMenuBar, False, False, 0);
  end;

  FScrollWin := PGtkScrolledWindow(TGtkScrolledWindow.new(nil, nil));
  g_object_set_data(FScrollWin,'lclscrollingwindow',GPointer(1));
  g_object_set_data(PGObject(FScrollWin), 'lclwidget', Self);


  //FCentralWidget := TGtkLayout.new(nil, nil);
  FCentralWidget := TGtkFixed.new;
  FCentralWidget^.set_has_window(True);
  FCentralWidget^.show;

  FScrollWin^.add_with_viewport(FCentralWidget);
  // FScrollWin^.add(FCentralWidget);
  FScrollWin^.show;
  FBox^.pack_end(FScrollWin, True, True, 0);
  FBox^.show;

  FScrollWin^.get_vscrollbar^.set_can_focus(False);
  FScrollWin^.get_hscrollbar^.set_can_focus(False);
  FScrollWin^.set_policy(GTK_POLICY_NEVER, GTK_POLICY_NEVER);
  PGtkContainer(Result)^.add(FBox);
  // FWidgetType := FWidgetType + [wtContainer, wtWindow];
  // Result := TGtkWindow.new(GTK_WINDOW_POPUP);
  // FCentralWidget := TGtkFixed.new;
  // PGtkWindow(Result)^.add(FCentralWidget);
end;

{ TGtk3Dialog }

function TGtk3Dialog.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := [wtWidget, wtDialog];
  Result := TGtkDialog.new;
  DebugLn('WARNING: TGtk3Dialog.CreateWidget should be used in real dialog constructor .');
end;

procedure TGtk3Dialog.InitializeWidget;
begin
  g_object_set_data(FWidget,'lclwidget', Self);
end;


{ TGtk3FileDialog }

function TGtk3FileDialog.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  DebugLn('ERROR: TGtk3FileDialog.CreateWidget error.');
  // Result := nil;
  Result := TGtkFileChooserDialog.new;
  // gtk_file_chooser_dialog_new();
end;

constructor TGtk3FileDialog.Create(const ACommonDialog: TCommonDialog);

var
  FileDialog: TFileDialog absolute ACommonDialog;
  Action: TGtkFileChooserAction;
  Button1: String;
  ADialog: TGtk3FileDialog;
  AFileDialog: PGtkFileChooserDialog;
  AParams: TCreateParams;
begin
  inherited Create;
  FContext := 0;
  FHasPaint := False;
  FWidget := nil;
  FOwner := nil;
  FCentralWidget := nil;
  FOwnWidget := True;
  // Initializes the properties
  FProps := nil;
  LCLObject := nil;
  FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  FWidgetType := [wtWidget, wtDialog];

  // FHasPaint := False;
  CommonDialog := ACommonDialog;
  // Defines an action for the dialog and creates it
  Action := GTK_FILE_CHOOSER_ACTION_OPEN;
  Button1 := GTK_STOCK_OPEN;

  if (FileDialog is TSaveDialog) or (FileDialog is TSavePictureDialog) then
  begin
    Action := GTK_FILE_CHOOSER_ACTION_SAVE;
    Button1 := GTK_STOCK_SAVE;
  end
  else
  if FileDialog is TSelectDirectoryDialog then
  begin
    Action := GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER;
    Button1 := GTK_STOCK_OPEN;
  end;

  FWidget := gtk_file_chooser_dialog_new(PgChar(FileDialog.Title), nil,
    Action, PChar(GTK_STOCK_CANCEL),
    [GTK_RESPONSE_CANCEL, PChar(Button1), GTK_RESPONSE_OK, nil]);

  AFileDialog := PGtkFileChooserDialog(FWidget);
  if FileDialog is TSaveDialog then
  begin
    gtk_file_chooser_set_do_overwrite_confirmation(PGtkFileChooser(AFileDialog),
      ofOverwritePrompt in TOpenDialog(FileDialog).Options);
  end;

  if FileDialog.InitialDir <> '' then
    gtk_file_chooser_set_current_folder(PGtkFileChooser(AFileDialog), Pgchar(FileDialog.InitialDir));

  if gtk_file_chooser_get_action(PGtkFileChooser(AFileDialog)) in
    [GTK_FILE_CHOOSER_ACTION_SAVE, GTK_FILE_CHOOSER_ACTION_CREATE_FOLDER]
  then
    gtk_file_chooser_set_current_name(PGtkFileChooser(AFileDialog), Pgchar(FileDialog.FileName));

  InitializeWidget;
end;

{ TGtk3FontSelectionDialog }

function TGtk3FontSelectionDialog.CreateWidget(const Params: TCreateParams
  ): PGtkWidget;
begin
  Result := TGtkFontSelectionDialog.new;
end;

constructor TGtk3FontSelectionDialog.Create(const ACommonDialog: TCommonDialog);
begin
  inherited Create;
  FContext := 0;
  FHasPaint := False;
  FWidget := nil;
  FOwner := nil;
  FCentralWidget := nil;
  FOwnWidget := True;
  // Initializes the properties
  FProps := nil;
  LCLObject := nil;
  FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  FWidgetType := [wtWidget, wtDialog];

  // FHasPaint := False;
  CommonDialog := ACommonDialog;
end;


end.

