{
 *****************************************************************************
 *                              QtWidgets.pas                                *
 *                              --------------                               *
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit qtwidgets;

{$mode objfpc}{$H+}

interface

{$I qtdefines.inc}

uses
  // Bindings
  qt4,
  qtobjects, qtint,
  // Free Pascal
  Classes, SysUtils, Types, Math,
  // LCL
  LCLType, LCLProc, LCLIntf, LMessages, Buttons, Forms, Controls, ComCtrls,
  ExtCtrls, StdCtrls, CheckLst, Menus, Dialogs;

type
  // forward declarations
  TQtListWidget = class;
  TQtViewPort = class;

  TByteSet = set of byte;
  
  // records
  TPaintData = record
    PaintWidget: QWidgetH;
    ClipRect: Prect;
    ClipRegion: QRegionH;
  end;
  
  // interfaces

  { IQtTextEdit }

  IQtEdit = interface
  ['{035CA259-4442-4E82-9E70-96A114DD3BC6}']
    function getMaxLength: Integer;
    function getSelectionStart: Integer;
    function getSelectionLength: Integer;
    function isUndoAvailable: Boolean;
    procedure setEchoMode(const AMode: QLineEditEchoMode);
    procedure setMaxLength(const ALength: Integer);
    procedure setReadOnly(const AReadOnly: Boolean);
    procedure setSelection(const AStart, ALength: Integer);
    procedure Undo;
  end;

  // classes
  
  { TQtWidget }

  TQtWidget = class(TQtObject, IUnknown)
  private
    FOwnWidget: Boolean;
    FProps: TStringList;
    FPaintData: TPaintData;
    FCentralWidget: QWidgetH;
    FContext: HDC;
    FParams: TCreateParams;
    FDefaultCursor: QCursorH;
    FKeysToEat: TByteSet;
    FText: WideString;
    FHasCaret: Boolean;
    FHasPaint: Boolean;
    FOwner: TQtWidget;

    {TQtWidget.scroll() info}
    FScrollX: Integer;
    FScrollY: Integer;

    function GetProps(const AnIndex: String): pointer;
    function GetWidget: QWidgetH;
    function LCLKeyToQtKey(AKey: Word): Integer;
    function QtButtonsToLCLButtons(AButtons: QTMouseButton): PtrInt;
    function QtKeyModifiersToKeyState(AModifiers: QtKeyboardModifiers): PtrInt;
    function QtKeyToLCLKey(AKey: Integer; AText: WideString): Word;
    procedure SetProps(const AnIndex: String; const AValue: pointer);
    procedure SetWidget(const AValue: QWidgetH);
    function ShiftStateToQtModifiers(Shift: TShiftState): QtModifier;
  protected
    // IUnknown implementation
    function QueryInterface(const iid : tguid;out obj) : longint;stdcall;
    function _AddRef : longint;stdcall;
    function _Release : longint;stdcall;

    function GetContext: HDC; virtual;
    function CreateWidget(const Params: TCreateParams):QWidgetH; virtual;
    procedure DestroyWidget; virtual;
    procedure SetHasCaret(const AValue: Boolean);
    
    class procedure removeProperty(AObject: QObjectH; APropName: PAnsiChar);
    class procedure setProperty(AObject: QObjectH; APropName: PAnsiChar; APropValue: Int64);
  public
    LCLObject: TWinControl;
  public
    constructor Create(const AWinControl: TWinControl; const AParams: TCreateParams); virtual; overload;
    constructor CreateFrom(const AWinControl: TWinControl; AWidget: QWidgetH); virtual;
    procedure InitializeWidget; virtual;
    procedure DeInitializeWidget;
    procedure RecreateWidget;
    procedure DestroyNotify(AWidget: TQtWidget); virtual;
    
    destructor Destroy; override;
    function GetContainerWidget: QWidgetH; virtual;
    procedure Release; override;
  public
    function DeliverMessage(var Msg): LRESULT; virtual;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure SlotActivateWindow(vActivate: Boolean); cdecl;
    procedure SlotShow(vShow: Boolean); cdecl;
    function SlotClose: Boolean; cdecl; virtual;
    procedure SlotDestroy; cdecl;
    procedure SlotHover(Sender: QObjectH; Event: QEventH); cdecl;
    function SlotKey(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    procedure SlotMouse(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotNCMouse(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotMouseEnter(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotMouseMove(Event: QEventH); cdecl;
    procedure SlotMouseWheel(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotMove(Event: QEventH); cdecl;
    procedure SlotPaint(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotResize(Event: QEventH); cdecl;
    procedure SlotContextMenu(Sender: QObjectH; Event: QEventH); cdecl;
    procedure SlotLCLMessage(Sender: QObjectH; Event: QEventH); cdecl;
  public
    procedure Activate;
    procedure BringToFront;
    procedure clearMask;
    procedure OffsetMousePos(APoint: PQtPoint); virtual;
    procedure Update(ARect: PRect = nil); virtual;
    procedure Repaint(ARect: PRect = nil); virtual;
    procedure setWindowTitle(Str: PWideString);
    procedure WindowTitle(Str: PWideString);
    procedure Hide;
    procedure Show;
    procedure ShowNormal;
    procedure ShowMinimized;
    procedure ShowMaximized;
    function getActionByIndex(AIndex: Integer): QActionH;
    function getAutoFillBackground: Boolean;
    function getClientBounds: TRect; virtual;
    function getClientOffset: TPoint; virtual;
    function getEnabled: Boolean;
    function getFocusPolicy: QtFocusPolicy;
    function getFrameGeometry: TRect;
    function getGeometry: TRect; virtual;
    function getVisible: Boolean; virtual;
    function getParent: QWidgetH;
    function getPos: TQtPoint;
    function getFrameSize: TSize;
    function getSize: TSize;
    function getText: WideString; virtual;
    function getTextStatic: Boolean; virtual;
    function getHeight: Integer;
    function getWidth: Integer;
    procedure grabMouse; virtual;
    function hasFocus: Boolean; virtual;
    procedure lowerWidget; virtual;
    procedure move(ANewLeft, ANewTop: Integer);
    procedure preferredSize(var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); virtual;
    procedure raiseWidget; virtual;
    procedure frame_resize(ANewWidth, ANewHeight: Integer);
    procedure resize(ANewWidth, ANewHeight: Integer);
    procedure releaseMouse;
    procedure scroll(dx, dy: integer);
    procedure setAutoFillBackground(const AValue: Boolean);
    procedure setAttribute(const Attr: QtWidgetAttribute; const TurnOn: Boolean = True);
    procedure setBackgroundRole(const ARole: QPaletteColorRole);
    procedure setColor(const Value: PQColor); virtual;
    function getContextMenuPolicy: QtContextMenuPolicy; virtual;
    procedure setContextMenuPolicy(const AValue: QtContextMenuPolicy); virtual;
    procedure setCursor(const ACursor: QCursorH); virtual;
    procedure setEnabled(p1: Boolean);
    procedure setFocus;
    procedure setFocusPolicy(const APolicy: QtFocusPolicy); virtual;
    procedure setFocusProxy(const AWidget: QWidgetH);
    procedure setFont(AFont: QFontH);
    procedure setGeometry(ARect: TRect); overload;
    procedure setLayoutDirection(ADirection: QtLayoutDirection);
    procedure setMaximumSize(AWidth, AHeight: Integer);
    procedure setMask(AMask: QBitmapH);
    procedure setMinimumSize(AWidth, AHeight: Integer);
    procedure setParent(parent: QWidgetH); virtual;
    procedure setText(const W: WideString); virtual;
    procedure setTextColor(const Value: PQColor); virtual;
    procedure setVisible(visible: Boolean); virtual;
    procedure setWindowFlags(_type: QtWindowFlags);
    procedure setWindowIcon(AIcon: QIconH);
    procedure setWindowModality(windowModality: QtWindowModality);
    procedure setWidth(p1: Integer);
    procedure setHeight(p1: Integer);
    procedure setUpdatesEnabled(const AEnabled: Boolean);
    procedure setWindowState(AState: QtWindowStates);
    procedure sizeHint(size: PSize);
    function windowFlags: QtWindowFlags;
    function windowModality: QtWindowModality;

    property Context: HDC read GetContext;
    property KeysToEat: TByteSet read FKeysToEat write FKeysToEat;
    property Props[AnIndex:String]:pointer read GetProps write SetProps;
    property PaintData: TPaintData read FPaintData write FPaintData;
    property Widget: QWidgetH read GetWidget write SetWidget;
    property HasCaret: Boolean read FHasCaret write SetHasCaret;
    property HasPaint: Boolean read FHasPaint write FHasPaint;
  end;

  { TQtAbstractSlider , inherited by TQtScrollBar, TQtTrackBar }

  TQtAbstractSlider = class(TQtWidget)
  private
    FSliderPressed: Boolean;
    FSliderReleased: Boolean;
    FRangeChangedHook: QAbstractSlider_hookH;
    FSliderMovedHook:  QAbstractSlider_hookH;
    FSliderPressedHook: QAbstractSlider_hookH;
    FSliderReleasedHook: QAbstractSlider_hookH;
    FValueChangedHook: QAbstractSlider_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;

    procedure SlotSliderMoved(p1: Integer); cdecl; virtual;
    procedure SlotValueChanged(p1: Integer); cdecl; virtual;
    procedure SlotRangeChanged(minimum: Integer; maximum: Integer); cdecl; virtual;
    procedure SlotSliderPressed; cdecl;
    procedure SlotSliderReleased; cdecl;
  public
    function getOrientation: QtOrientation;
    function getValue: Integer;
    function getPageStep: Integer;
    function getMin: Integer;
    function getMax: Integer;
    function getSingleStep: Integer;
    function getSliderPosition: Integer;

    procedure setInvertedAppereance(p1: Boolean); virtual;
    procedure setInvertedControls(p1: Boolean); virtual;

    procedure setMaximum(p1: Integer); virtual;
    procedure setMinimum(p1: Integer); virtual;

    procedure setOrientation(p1: QtOrientation); virtual;
    procedure setPageStep(p1: Integer); virtual;
    procedure setRange(minimum: Integer; maximum: Integer); virtual;
    procedure setSingleStep(p1: Integer); virtual;
    procedure setSliderDown(p1: Boolean); virtual;
    procedure setSliderPosition(p1: Integer); virtual;
    procedure setTracking(p1: Boolean); virtual;
    procedure setValue(p1: Integer); virtual;
    property SliderPressed: Boolean read FSliderPressed;
    property SliderReleased: Boolean read FSliderReleased;
  end;

  { TQtScrollBar }

  TQtScrollBar = class(TQtAbstractSlider)
  private
    FRealParentCtl: TWinControl;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure AttachEvents; override;
  end;

  { TQtFrame }

  TQtFrame = class(TQtWidget)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure setFrameStyle(p1: Integer);
    procedure setFrameShape(p1: QFrameShape);
    procedure setFrameShadow(p1: QFrameShadow);
    procedure setTextColor(const Value: PQColor); override;
  end;
  
  { TQtAbstractScrollArea }

  TQtAbstractScrollArea = class(TQtFrame)
  private
    FCornerWidget: TQtWidget;
    FViewPortWidget: TQtViewPort;
    FHScrollbar: TQtScrollBar;
    FVScrollbar: TQtScrollbar;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure ViewPortEventFilter(event: QEventH; retval: PBoolean); cdecl;

    procedure DestroyNotify(AWidget: TQtWidget); override;
  public
    function cornerWidget: TQtWidget;
    function horizontalScrollBar: TQtScrollBar;
    function verticalScrollBar: TQtScrollBar;
    function viewport: TQtViewPort;
    function GetContainerWidget: QWidgetH; override;

    function getClientOffset: TPoint; override;
    function getClientBounds: TRect; override;
    procedure grabMouse; override;
    procedure preferredSize(var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;
    procedure SetColor(const Value: PQColor); override;
    procedure setCornerWidget(AWidget: TQtWidget);
    procedure setCursor(const ACursor: QCursorH); override;
    procedure setHorizontalScrollBar(AScrollBar: TQtScrollBar);
    procedure setScrollStyle(AScrollStyle: TScrollStyle);
    procedure setTextColor(const Value: PQColor); override;
    procedure setViewport(const AViewPort: QWidgetH);
    procedure setVerticalScrollBar(AScrollBar: TQtScrollBar);
    procedure setVisible(visible: Boolean); override;
    procedure Update(ARect: PRect = nil); override;
    procedure Repaint(ARect: PRect = nil); override;
    procedure viewportNeeded;
    procedure viewportDelete;
  end;
  
  { TQtViewPort }
  
  TQtViewPort = class(TQtWidget)
  public
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
  end;
  
  { TQtGraphicView }

  TQtGraphicsView = class(TQtAbstractScrollArea)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  end;

  { TQtArrow }

  TQtArrow = class(TQtFrame)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    ArrowType: Integer;
  end;

  { TQtAbstractButton }

  TQtAbstractButton = class(TQtWidget)
  private
  public
    function getIconSize: TSize;
    function getText: WideString; override;
    procedure setColor(const Value: PQColor); override;
    procedure setTextColor(const Value: PQColor); override;
    procedure setIcon(AIcon: QIconH);
    procedure setIconSize(Size: PSize);
    procedure setShortcut(AShortcut: TShortcut);
    procedure setText(const W: WideString); override;
    procedure Toggle;
    function isChecked: Boolean;
    function isDown: Boolean;
    procedure setChecked(p1: Boolean);
    procedure setDown(p1: Boolean);
    procedure SignalPressed; cdecl;
    procedure SignalReleased; cdecl;
    procedure SignalClicked(Checked: Boolean = False); cdecl;
    procedure SignalClicked2; cdecl;
    procedure SignalToggled(Checked: Boolean); cdecl;
  end;

  { TQtPushButton }

  TQtPushButton = class(TQtAbstractButton)
  private
    FClickedHook: QAbstractButton_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams): QWidgetH; override;
  public
    destructor Destroy; override;
    procedure preferredSize(var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure SlotClicked; cdecl;
  end;

  { TQtMainWindow }

  TQtMenuBar = class;
  TQtToolBar = class;
  TQtStatusBar = class;

  TQtMainWindow = class(TQtWidget)
  private
    LayoutWidget: QBoxLayoutH;
    FCWEventHook: QObject_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    IsMainForm: Boolean;
    MDIAreaHandle: QMDIAreaH;
    MenuBar: TQtMenuBar;
    ToolBar: TQtToolBar;
    destructor Destroy; override;
    function getText: WideString; override;
    function getTextStatic: Boolean; override;
    procedure setText(const W: WideString); override;
    procedure setMenuBar(AMenuBar: QMenuBarH);
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    function IsMdiChild: Boolean;
    procedure OffsetMousePos(APoint: PQtPoint); override;
    procedure SlotWindowStateChange; cdecl;
    procedure setShowInTaskBar(AValue: Boolean);
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function CWEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
  end;
  
  { TQtHintWindow }

  TQtHintWindow = class(TQtMainWindow)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  end;

  { TQtStaticText }

  TQtStaticText = class(TQtFrame)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
    function getText: WideString; override;
    procedure setText(const W: WideString); override;
    procedure setAlignment(const AAlignment: QtAlignment);
  end;

  { TQtCheckBox }

  TQtCheckBox = class(TQtAbstractButton)
  private
    FStateChangedHook : QCheckBox_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
    function CheckState: QtCheckState;
    procedure setCheckState(state: QtCheckState);
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure signalStateChanged(p1: Integer); cdecl;
  end;

  { TQtRadioButton }

  TQtRadioButton = class(TQtAbstractButton)
  private
    FClickedHook: QAbstractButton_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
  end;

  { TQtGroupBox }

  TQtGroupBox = class(TQtWidget)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
    function getText: WideString; override;
    procedure setText(const W: WideString); override;
  end;
  
  { TQtToolBar }
  
  TQtToolBar = class(TQtWidget)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  end;
  
  { TQtToolButton }

  TQtToolButton = class(TQtAbstractButton)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  end;
  
  { TQtTrackBar }
  
  TQtTrackBar = class(TQtAbstractSlider)
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function getTickInterval: Integer;
    procedure setTickPosition(Value: QSliderTickPosition);
    procedure setTickInterval(Value: Integer);
  public
    procedure AttachEvents; override;
    
    procedure SlotSliderMoved(p1: Integer); cdecl; override;
    procedure SlotValueChanged(p1: Integer); cdecl; override;
  end;

  { TQtLineEdit }

  TQtLineEdit = class(TQtWidget, IQtEdit)
  private
    FTextChanged: QLineEdit_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function getCursorPosition: Integer;
    function getMaxLength: Integer;
    function getSelectedText: WideString;
    function getSelectionStart: Integer;
    function getSelectionLength: Integer;
    function getText: WideString; override;
    function getTextStatic: Boolean; override;
    function isUndoAvailable: Boolean;
    function hasSelectedText: Boolean;
    procedure selectAll;
    procedure setColor(const Value: PQColor); override;
    procedure setTextColor(const Value: PQColor); override;
    procedure setCursorPosition(const AValue: Integer);
    procedure setEchoMode(const AMode: QLineEditEchoMode);
    procedure setInputMask(const AMask: WideString);
    procedure setMaxLength(const ALength: Integer);
    procedure setReadOnly(const AReadOnly: Boolean);
    procedure setSelection(const AStart, ALength: Integer);
    procedure setText(const AText: WideString); override;
    procedure Undo;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure SignalTextChanged(p1: PWideString); cdecl;
  end;

  { TQtTextEdit }

  TQtTextEdit = class(TQtWidget, IQtEdit)
  private
    FViewportEventHook: QObject_hookH;
    FTextChangedHook: QTextEdit_hookH;
    FUndoAvailableHook: QTextEdit_hookH;
    FUndoAvailable: Boolean;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    FList: TStrings;
    procedure append(AStr: WideString);
    function getMaxLength: Integer;
    function getText: WideString; override;
    function getTextStatic: Boolean; override;
    function getSelectionStart: Integer;
    function getSelectionEnd: Integer;
    function getSelectionLength: Integer;
    function isUndoAvailable: Boolean;
    procedure setAlignment(const AAlignment: QtAlignment);
    procedure setColor(const Value: PQColor); override;
    procedure setTextColor(const Value: PQColor); override;
    procedure setEchoMode(const AMode: QLineEditEchoMode);
    procedure setLineWrapMode(const AMode: QTextEditLineWrapMode);
    procedure setMaxLength(const ALength: Integer);
    procedure setText(const AText: WideString); override;
    procedure setReadOnly(const AReadOnly: Boolean);
    procedure setSelection(const AStart, ALength: Integer);
    procedure setTabChangesFocus(const AValue: Boolean);
    procedure Undo;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function viewportEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    function getContextMenuPolicy: QtContextMenuPolicy; override;
    procedure setContextMenuPolicy(const AValue: QtContextMenuPolicy); override;
    procedure SignalTextChanged; cdecl;
    procedure SignalUndoAvailable(b: Boolean); cdecl;
    procedure setScrollStyle(AScrollStyle: TScrollStyle);
  end;

  { TQtTabWidget }

  TQtTabWidget = class(TQtWidget)
  private
    FCurrentChangedHook: QTabWidget_hookH;
    FTabBarEventHook: QWidget_hookH;
    FTabBarChangedHook: QTabBar_hookH;
    FTabBar: QTabBarH;
    FStackWidget: QWidgetH;
    function getShowTabs: Boolean;
    function getStackWidget: QWidgetH;
    function getTabBar: QTabBarH;
    procedure setShowTabs(const AValue: Boolean);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    procedure SignalCurrentChanged(Index: Integer); cdecl;
    procedure SignalTabBarCurrentChanged(Index: Integer); cdecl;
    function SlotTabBarMouse(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
  public
    function indexOf(const AWidget: QWidgetH): integer;
    function insertTab(index: Integer; page: QWidgetH; p2: WideString): Integer; overload;
    function insertTab(index: Integer; page: QWidgetH; icon: QIconH; p2: WideString): Integer; overload;
    function getClientBounds: TRect; override;
    function getCurrentIndex: Integer;
    function getTabPosition: QTabWidgetTabPosition;
    procedure removeTab(AIndex: Integer);
    procedure setCurrentIndex(AIndex: Integer);
    procedure setCurrentWidget(APage: TQtWidget);
    procedure setFocusPolicy(const APolicy: QtFocusPolicy); override;
    procedure setTabPosition(ATabPosition: QTabWidgetTabPosition);
    procedure setTabText(index: Integer; p2: WideString);
    function tabAt(APoint: TPoint): Integer;

    property ShowTabs: Boolean read getShowTabs write setShowTabs;
    property TabBar: QTabBarH read getTabBar;
    property StackWidget: QWidgetH read getStackWidget;
  end;

  { TQtComboBox }

  TQtComboBox = class(TQtWidget, IQtEdit)
  private
    // hooks
    FChangeHook: QComboBox_hookH;
    FActivateHook: QComboBox_hookH;
    FOwnerDrawn: Boolean;
    FSelectHook: QComboBox_hookH;
    FDropListEventHook: QObject_hookH;
    // parts
    FLineEdit: TQtLineEdit;
    FDropList: TQtListWidget;
    function GetDropList: TQtListWidget;
    function GetLineEdit: TQtLineEdit;
    procedure SetOwnerDrawn(const AValue: Boolean);
    procedure slotPaintCombo(Sender: QObjectH; Event: QEventH); cdecl;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
    // IQtEdit implementation
    function getMaxLength: Integer;
    function getSelectionStart: Integer;
    function getSelectionLength: Integer;
    function isUndoAvailable: Boolean;
    procedure setEchoMode(const AMode: QLineEditEchoMode);
    procedure setMaxLength(const ALength: Integer);
    procedure setReadOnly(const AReadOnly: Boolean);
    procedure setSelection(const AStart, ALength: Integer);
    procedure Undo;
  public
    FList: TStrings;
    destructor Destroy; override;
    procedure SetColor(const Value: PQColor); override;
    procedure setTextColor(const Value: PQColor); override;
    function currentIndex: Integer;
    function getEditable: Boolean;
    function getMaxVisibleItems: Integer;
    function getText: WideString; override;
    function getTextStatic: Boolean; override;
    procedure insertItem(AIndex: Integer; AText: String); overload;
    procedure insertItem(AIndex: Integer; AText: PWideString); overload;
    procedure setCurrentIndex(index: Integer);
    procedure setMaxVisibleItems(ACount: Integer);
    procedure setEditable(const AValue: Boolean);
    procedure setItemText(AIndex: Integer; AText: String);
    procedure setText(const W: WideString); override;
    procedure removeItem(AIndex: Integer);
    
    property DropList: TQtListWidget read GetDropList;
    property LineEdit: TQtLineEdit read GetLineEdit;
    property OwnerDrawn: Boolean read FOwnerDrawn write SetOwnerDrawn;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;

    procedure SlotActivate(index: Integer); cdecl;
    procedure SlotChange(p1: PWideString); cdecl;
    procedure SlotSelect(index: Integer); cdecl;
    procedure SlotDropListVisibility(AVisible: Boolean); cdecl;
  end;

  { TQtAbstractSpinBox}
  
  TQtAbstractSpinBox = class(TQtWidget, IQtEdit)
  private
    FEditingFinishedHook: QAbstractSpinBox_hookH;
    // parts
    FLineEdit: QLineEditH;
    function GetLineEdit: QLineEditH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
    // IQtEdit implementation
    function getMaxLength: Integer;
    function getSelectionStart: Integer;
    function getSelectionLength: Integer;
    function isUndoAvailable: Boolean;
    procedure setEchoMode(const AMode: QLineEditEchoMode);
    procedure setMaxLength(const ALength: Integer);
    procedure setSelection(const AStart, ALength: Integer);
    procedure Undo;
  public
    function getValue: Double; virtual; abstract;
    function getReadOnly: Boolean;
    function getText: WideString; override;
    function getTextStatic: Boolean; override;
    procedure setFocusPolicy(const APolicy: QtFocusPolicy); override;
    procedure setMinimum(const v: Double); virtual; abstract;
    procedure setMaximum(const v: Double); virtual; abstract;
    procedure setSingleStep(const v: Double); virtual; abstract;
    procedure setReadOnly(const r: Boolean);
    procedure setValue(const v: Double); virtual; abstract;
    procedure setText(const W: WideString); override;
    procedure SetColor(const Value: PQColor); override;
    procedure setTextColor(const Value: PQColor); override;

    property LineEdit: QLineEditH read GetLineEdit;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure SignalEditingFinished; cdecl;
  end;

  { TQtFloatSpinBox }

  TQtFloatSpinBox = class(TQtAbstractSpinBox)
  private
    FValueChangedHook: QDoubleSpinBox_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function getValue: Double; override;
    procedure setDecimals(const v: integer);
    procedure setMinimum(const v: Double); override;
    procedure setMaximum(const v: Double); override;
    procedure setSingleStep(const v: Double); override;
    procedure setValue(const v: Double); override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;

    procedure SignalValueChanged(p1: Double); cdecl;
  end;
  
  { TQtSpinBox }

  TQtSpinBox = class(TQtAbstractSpinBox)
  private
    FValueChangedHook: QSpinBox_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function getValue: Double; override;
    procedure setMinimum(const v: Double); override;
    procedure setMaximum(const v: Double); override;
    procedure setSingleStep(const v: Double); override;
    procedure setValue(const v: Double); override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;

    procedure SignalValueChanged(p1: Integer); cdecl;
  end;

  { TQtAbstractItemView }

  TQtAbstractItemView = class(TQtWidget)
  private
    FOldDelegate: QAbstractItemDelegateH;
    FNewDelegate: QLCLItemDelegateH;
    FSignalActivated: QAbstractItemView_hookH;
    FSignalClicked: QAbstractItemView_hookH;
    FSignalDoubleClicked: QAbstractItemView_hookH;
    FSignalEntered: QAbstractItemView_hookH;
    FSignalPressed: QAbstractItemView_hookH;
    FSignalViewportEntered: QAbstractItemView_hookH;
    FAbstractItemViewportEventHook: QObject_hookH;
    function GetOwnerDrawn: Boolean;
    procedure SetOwnerDrawn(const AValue: Boolean);
  public
    constructor Create(const AWinControl: TWinControl; const AParams: TCreateParams); override;
    procedure signalActivated(index: QModelIndexH); cdecl; virtual;
    procedure signalClicked(index: QModelIndexH); cdecl; virtual;
    procedure signalDoubleClicked(index: QModelIndexH); cdecl; virtual;
    procedure signalEntered(index: QModelIndexH); cdecl; virtual;
    procedure signalPressed(index: QModelIndexH); cdecl; virtual;
    procedure signalViewportEntered; cdecl; virtual;
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    procedure SetColor(const Value: PQColor); override;
    procedure setTextColor(const Value: PQColor); override;

    function itemViewViewportEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; virtual;
 public
    procedure clearSelection;
    function getModel: QAbstractItemModelH;
    function getSelectionMode: QAbstractItemViewSelectionMode;

    procedure modelIndex(retval: QModelIndexH; row, column: Integer; parent: QModelIndexH = nil);
    function visualRect(Index: QModelIndexH): TRect;
    procedure setEditTriggers(ATriggers: QAbstractItemViewEditTriggers);
    procedure setSelectionMode(AMode: QAbstractItemViewSelectionMode);
    procedure setSelectionBehavior(ABehavior: QAbstractItemViewSelectionBehavior);
    property OwnerDrawn: Boolean read GetOwnerDrawn write SetOwnerDrawn;
  public
    procedure ItemDelegateSizeHint(option: QStyleOptionViewItemH; index: QModelIndexH; Size: PSize); cdecl; virtual;
    procedure ItemDelegatePaint(painter: QPainterH; option: QStyleOptionViewItemH; index: QModelIndexH); cdecl; virtual;
  end;

  { TQtListView }

  TQtListView = class(TQtAbstractItemView)
  public
  end;

  { TQtListWidget }

  TQtListWidget = class(TQtListView)
  private
    FCurrentItemChangeHook: QListWidget_hookH;
    FSelectionChangeHook: QListWidget_hookH;
    FItemDoubleClickedHook: QListWidget_hookH;
    FItemClickedHook: QListWidget_hookH;
    FItemTextChangedHook: QListWidget_hookH;
    FDontPassSelChange: Boolean;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    FList: TStrings;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function itemViewViewportEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;

    procedure signalCurrentItemChange(current: QListWidgetItemH; previous: QListWidgetItemH); cdecl;
    procedure signalItemDoubleClicked(item: QListWidgetItemH); cdecl;
    procedure signalItemClicked(item: QListWidgetItemH); cdecl;
    procedure signalItemTextChanged(ANewText: PWideString); cdecl;
    procedure signalSelectionChanged(); cdecl;
    procedure ItemDelegatePaint(painter: QPainterH; option: QStyleOptionViewItemH; index: QModelIndexH); cdecl; override;
  public
    function currentRow: Integer;
    function IndexAt(APoint: PQtPoint): Integer;
    procedure insertItem(AIndex: Integer; AText: String); overload;
    procedure insertItem(AIndex: Integer; AText: PWideString); overload;
    procedure setCurrentRow(row: Integer);
    procedure setItemText(AIndex: Integer; AText: String);
    procedure scrollToItem(row: integer; hint: QAbstractItemViewScrollHint);
    procedure removeItem(AIndex: Integer);
    procedure exchangeItems(AIndex1, AIndex2: Integer);
  end;
  
  { TQtHeaderView }

  TQtHeaderView = class (TQtAbstractItemView)
  private
    FSelectionClicked: QHeaderView_hookH;
    function getClickable: Boolean;
    function getMinSectionSize: Integer;
    procedure setClickable(const AValue: Boolean);
    procedure setMinSectionSize(const AValue: Integer);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    procedure SignalSectionClicked(logicalIndex: Integer) cdecl;
    function getResizeMode(AIndex: Integer): QHeaderViewResizeMode;
    procedure setResizeMode(AResizeMode: QHeaderViewResizeMode); overload;
    procedure setResizeMode(AIndex: Integer; AResizeMode: QHeaderViewResizeMode); overload;
    procedure moveSection(AFromIndex: Integer; AToIndex: Integer);
    procedure resizeSection(ASection: Integer; ASize: Integer);
    procedure setHighlightSections(AValue: Boolean);
    procedure setDefaultSectionSize(AValue: Integer);
    procedure setStretchLastSection(AValue: Boolean);
    function sortIndicatorOrder: QtSortOrder;
    property Clickable: Boolean read getClickable write setClickable;
    property MinSectionSize: Integer read getMinSectionSize write setMinSectionSize;
  end;

  { TQtTreeView }
  
  TQtTreeView = class (TQtAbstractItemView)
  private
    function getColVisible(AIndex: Integer): Boolean;
    function getColWidth(AIndex: Integer): Integer;
    procedure setColVisible(AIndex: Integer; const AValue: Boolean);
    procedure setColWidth(AIndex: Integer; const AValue: Integer);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure setAllColumnsShowFocus(AValue: Boolean);
    procedure setWordWrap(AValue: Boolean);
    procedure setRootIsDecorated(AValue: Boolean);
    property ColWidth[AIndex: Integer]: Integer read getColWidth write setColWidth;
    property ColVisible[AIndex: Integer]: Boolean read getColVisible write setColVisible;
  end;
  
  { TQtTreeWidget }

  TQtTreeWidget = class(TQtTreeView)
  private
    FHeader: TQtHeaderView;
    FSectionClicked: QHeaderView_hookH;
    FHeaderEventFilterHook: QObject_hookH;
    FCurrentItemChangedHook: QTreeWidget_hookH;
    FItemDoubleClickedHook: QTreeWidget_hookH;
    FItemClickedHook: QTreeWidget_hookH;
    FItemActivatedHook: QTreeWidget_hookH;
    FItemChangedHook: QTreeWidget_hookH;
    FItemSelectionChangedHook: QTreeWidget_hookH;
    FItemPressedHook: QTreeWidget_hookH;
    FItemEnteredHook: QTreeWidget_hookH;
    function getColCount: Integer;
    function getHeader: TQtHeaderView;
    function getMaxColSize(ACol: Integer): Integer;
    function getMinColSize(ACol: Integer): Integer;
    function getSortEnabled: Boolean;
    procedure setColCount(const AValue: Integer);
    procedure setMaxColSize(ACol: Integer; const AValue: Integer);
    procedure setMinColSize(ACol: Integer; const AValue: Integer);
    procedure setSortEnabled(const AValue: Boolean);
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    destructor Destroy; override;
    function currentRow: Integer;
    procedure setCurrentRow(row: Integer);
    function currentItem: QTreeWidgetItemH;
    procedure setCurrentItem(AItem: QTreeWidgetItemH);
    function headerItem: QTreeWidgetItemH;
    function itemAt(APoint: TPoint): QTreeWidgetItemH; overload;
    function itemAt(x: Integer; y: Integer): QTreeWidgetItemH; overload;
    function indexOfTopLevelItem(AItem: QTreeWidgetItemH): Integer;
    procedure insertTopLevelItem(AIndex: Integer; AItem: QTreeWidgetItemH);
    function takeTopLevelItem(AIndex: Integer): QTreeWidgetItemH;
    function topLevelItem(AIndex: Integer): QTreeWidgetItemH;
    function visualItemRect(AItem: QTreeWidgetItemH): TRect;
    function getItemVisible(AItem: QTreeWidgetItemH): Boolean;
    procedure setItemVisible(AItem: QTreeWidgetItemH; Const AVisible: Boolean);
    function selCount: Integer;
    function selectedItems: TPtrIntArray;
    procedure setHeaderVisible(AVisible: Boolean);
    procedure setItemSelected(AItem: QTreeWidgetItemH; ASelect: Boolean);
    procedure sortItems(Acolumn: Integer; AOrder: QtSortOrder);
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function headerViewEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;

    procedure SignalItemPressed(item: QTreeWidgetItemH; column: Integer) cdecl;
    procedure SignalItemClicked(item: QTreeWidgetItemH; column: Integer) cdecl;
    procedure SignalItemDoubleClicked(item: QTreeWidgetItemH; column: Integer) cdecl;
    procedure SignalItemActivated(item: QTreeWidgetItemH; column: Integer) cdecl;
    procedure SignalItemEntered(item: QTreeWidgetItemH; column: Integer) cdecl;
    procedure SignalItemChanged(item: QTreeWidgetItemH; column: Integer) cdecl;
    procedure SignalitemExpanded(item: QTreeWidgetItemH) cdecl;
    procedure SignalItemCollapsed(item: QTreeWidgetItemH) cdecl;
    procedure SignalCurrentItemChanged(current: QTreeWidgetItemH; previous: QTreeWidgetItemH) cdecl;
    procedure SignalItemSelectionChanged; cdecl;

    property ColCount: Integer read getColCount write setColCount;
    property Header: TQtHeaderView read getHeader;
    property MaxColSize[ACol: Integer]: Integer read getMaxColSize write setMaxColSize;
    property MinColSize[ACol: Integer]: Integer read getMinColSize write setMinColSize;
    property SortEnabled: Boolean read getSortEnabled write setSortEnabled;
  end;
  
  {TQtTableView}
  
  TQtTableView = class(TQtAbstractItemView)
  private
    FVerticalHeader: TQtHeaderView;
    FHorizontalHeader: TQtHeaderView;
  public
    function verticalHeader: TQtHeaderView;
    function horizontalHeader: TQtHeaderView;
    function CreateWidget(const Params: TCreateParams): QWidgetH; override;
    function getViewPort: QWidgetH;
    function getClientBounds: TRect; override;
    procedure grabMouse; override;
    procedure setVisible(visible: Boolean); override;
    function getGridStyle: QtPenStyle;
    procedure setGridStyle(ANewStyle: QtPenStyle);
  public
    destructor Destroy; override;
  end;

  { TQtMenu }

  TQtMenu = class(TQtWidget)
  private
    FIcon: QIconH;
    FTriggeredHook: QAction_hookH;
    FHoveredHook: QAction_hookH;
    FAboutToHideHook: QMenu_hookH;
    FActionHandle: QActionH;
    FMenuItem: TMenuItem;
  protected
    function CreateWidget(const APrams: TCreateParams): QWidgetH; override;
    procedure DoPopupClose;
  public
    constructor Create(const AMenuItem: TMenuItem); overload;
    destructor Destroy; override;
    procedure InitializeWidget; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    
    procedure SlotHovered; cdecl;
    procedure SlotAboutToHide; cdecl;
    procedure SlotDestroy; cdecl;
    procedure SlotTriggered(checked: Boolean = False); cdecl;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
  public
    procedure PopUp(pos: PQtPoint; at: QActionH = nil);
    function actionHandle: QActionH;
    function addMenu(AMenu: QMenuH): QActionH;
    function insertMenu(AIndex: Integer; AMenu: QMenuH): QActionH;
    function getVisible: Boolean; override;
    function getText: WideString; override;
    procedure setChecked(p1: Boolean);
    procedure setCheckable(p1: Boolean);
    procedure setHasSubmenu(AValue: Boolean);
    procedure setIcon(AIcon: QIconH);
    procedure setImage(AImage: TQtImage);
    procedure setSeparator(AValue: Boolean);
    procedure setShortcut(AShortcut: TShortcut);
    procedure setText(const W: WideString); override;
    procedure setVisible(visible: Boolean); override;
  end;

  { TQtMenuBar }

  TQtMenuBar = class(TQtWidget)
  private
    FVisible: Boolean;
    FHeight: Integer;
  public
    constructor Create(const AParent: QWidgetH); overload;
  public
    function addMenu(AMenu: QMenuH): QActionH;
    function insertMenu(AIndex: Integer; AMenu: QMenuH): QActionH;
    function getGeometry: TRect; override;
  end;

  { TQtProgressBar }

  TQtProgressBar = class(TQtWidget)
  private
    FValueChangedHook: QProgressBar_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    procedure SignalValueChanged(Value: Integer); cdecl;
  public
    procedure setRange(minimum: Integer; maximum: Integer);
    procedure setTextVisible(visible: Boolean);
    procedure setAlignment(const AAlignment: QtAlignment);
    procedure setTextDirection(textDirection: QProgressBarDirection);
    procedure setValue(value: Integer);
    procedure setOrientation(p1: QtOrientation);
    procedure setInvertedAppearance(invert: Boolean);
  end;

  { TQtStatusBar }

  TQtStatusBar = class(TQtWidget)
  private
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    Panels: array of QLabelH;
    procedure showMessage(text: PWideString; timeout: Integer = 0);
    procedure addWidget(AWidget: QWidgetH; AStretch: Integer = 0);
    function isSizeGripEnabled: Boolean;
    procedure setSizeGripEnabled(const Value: Boolean);
  end;
  
  { TQtDialog }
  
  TQtDialog = class(TQtWidget)
  protected
    FDialog: TCommonDialog;
    function CreateWidget(parent: QWidgetH; f: QtWindowFlags):QWidgetH; virtual; overload;
  public
    constructor Create(ADialog: TCommonDialog; parent: QWidgetH = nil; f: QtWindowFlags = 0); overload;
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function DeliverMessage(var Msg): LRESULT; override;
    function SlotClose: Boolean; cdecl; override;
  public
    function exec: Integer;
    procedure setSizeGripEnabled(const AEnabled: Boolean);
  end;
  
  { TQtFileDialog }

  TQtFileDialog = class(TQtDialog)
  private
    FCurrentChangedHook: QFileDialog_hookH;
    FDirecotyEnteredHook: QFileDialog_hookH;
    FFilterSelectedHook: QFileDialog_hookH;
  protected
    function CreateWidget(parent: QWidgetH; f: QtWindowFlags):QWidgetH; override;
  public
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    procedure CurrentChangedEvent(path: PWideString); cdecl;
    procedure FilterSelectedEvent(filter: PWideString); cdecl;
    procedure DirectoryEnteredEvent(directory: PWideString); cdecl;
  public
    procedure getFilters(const retval: QStringListH);
    function selectFile: WideString;
    procedure selectedFiles(retval: QStringListH);
    procedure setAcceptMode(const AMode: QFileDialogAcceptMode);
    procedure setConfirmOverwrite(const AValue: Boolean);
    procedure setDirectory(const ADirectory: WideString);
    procedure setHistory(AList: TStrings);
    procedure setFileMode(const AMode: QFileDialogFileMode);
    procedure setFilter(const AFilter: WideString);
    procedure setLabelText(const ALabel: QFileDialogDialogLabel; const AText: WideString);
    procedure setReadOnly(const AReadOnly: Boolean);
    procedure setViewMode(const AMode: QFileDialogViewMode);
  end;

  { TQtMessageBox }

  TQtMessageBox = class(TQtWidget)
  private
    FMBEventHook: QObject_hookH;
    FButtons: Array of QPushButtonH;
    FTitle: WideString;
    function getDetailText: WideString;
    function getMessageStr: WideString;
    function getMsgBoxType: QMessageBoxIcon;
    procedure setDetailText(const AValue: WideString);
    procedure setMessageStr(const AValue: WideString);
    procedure setMsgBoxType(const AValue: QMessageBoxIcon);
    procedure setTitle(const AValue: WideString);
  protected
    function CreateWidget(AParent: QWidgetH):QWidgetH; overload;
  public
    constructor Create(AParent: QWidgetH); overload;
    destructor Destroy; override;
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
  public
    procedure AddButton(ABtnType: QMessageBoxStandardButton; ACaption: WideString;
      AIsDefaultBtn: Boolean; Const AEscapeBtn: Boolean = False);
    function exec: QMessageBoxStandardButton;
    property DetailText: WideString read getDetailText write setDetailText;
    property MessageStr: WideString read getMessageStr write setMessageStr;
    property MsgBoxType:QMessageBoxIcon read getMsgBoxType write setMsgBoxType;
    property Title: WideString read FTitle write setTitle;
  end;
  
  { TQtCalendar }

  TQtCalendar = class(TQtWidget)
  private
    FMouseDoubleClicked: Boolean;
    FCalViewportEventHook: QObject_hookH;
    FClickedHook: QCalendarWidget_hookH;
    FActivatedHook: QCalendarWidget_hookH;
    FSelectionChangedHook: QCalendarWidget_hookH;
    FCurrentPageChangedHook: QCalendarWidget_hookH;
  protected
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    AYear, AMonth, ADay: Word;
    procedure AttachEvents; override;
    procedure DetachEvents; override;
    function calViewportEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;

    procedure SignalActivated(ADate: QDateH); cdecl;
    procedure SignalClicked(ADate: QDateH); cdecl;
    procedure SignalSelectionChanged; cdecl;
    procedure SignalCurrentPageChanged(p1, p2: Integer); cdecl;
  end;
  
  // for page control / notebook

  { TQtPage }

  TQtPage = class(TQtWidget)
  protected
    FIcon: QIconH;
    function CreateWidget(const AParams: TCreateParams):QWidgetH; override;
  public
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;
    function getIcon: QIconH;
    function getIndex: Integer;
    function getTabWidget: QTabWidgetH;
    procedure setIcon(const AIcon: QIconH);
    procedure setText(const W: WideString); override;
  end;
  
  { TQtRubberBand }
  
  TQtRubberBand = class(TQtWidget)
  private
    FShape: QRubberBandShape;
  protected
    function CreateWidget(const AParams: TCreateParams): QWidgetH; override;
  public
    constructor Create(const AWinControl: TWinControl; const AParams: TCreateParams); override;
    function getShape: QRubberBandShape;
    procedure setShape(AShape: QRubberBandShape);
  end;
  
  { TQtDesignWidget }

  TQtDesignWidget = class(TQtMainWindow)
  protected
    FDesignControlEventHook: QObject_hookH;
    FDesignControl: QWidgetH;
    FDesignContext: HDC;
    function CreateWidget(const AParams: TCreateParams): QWidgetH; override;
    procedure DestroyWidget; override;
    procedure SlotDesignControlPaint(Sender: QObjectH; Event: QEventH); cdecl;
    procedure BringDesignerToFront;
    procedure ResizeDesigner;
    function GetContext: HDC; override;
  public
    function DesignControlEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
    function EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl; override;

    procedure AttachEvents; override;
    procedure DetachEvents; override;

    procedure lowerWidget; override;
    procedure raiseWidget; override;
  public
    property DesignContext: HDC read FDesignContext;
  end;

const
  AlignmentMap: array[TAlignment] of QtAlignment =
  (
{taLeftJustify } QtAlignLeft,
{taRightJustify} QtAlignRight,
{taCenter      } QtAlignHCenter
  );

implementation

uses
  LCLMessageGlue,
  qtCaret,
  qtproc;

const
  DblClickThreshold = 3;// max Movement between two clicks of a DblClick

type
  TWinControlAccess = class(TWinControl)
  end;
  TLastMouseInfo = record
    Widget: QObjectH;
    MousePos: TQtPoint;
    TheTime: TDateTime;
    ClickCount: Integer;
  end;

var
{$IFDEF DARWIN}
  LastMouse: TLastMouseInfo = (Widget: nil; MousePos: (y:0; x:0); TheTime:0; ClickCount: 0);
{$ELSE}
  LastMouse: TLastMouseInfo = (Widget: nil; MousePos: (x:0; y:0); TheTime:0; ClickCount: 0);
{$ENDIF}

{ TQtWidget }

{------------------------------------------------------------------------------
  Function: TQtWidget.Create
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
constructor TQtWidget.Create(const AWinControl: TWinControl; const AParams: TCreateParams);
begin
  inherited Create;
  FOwner := nil;
  FCentralWidget := nil;
  FOwnWidget := True;
  // Initializes the properties
  FProps := nil;
  LCLObject := AWinControl;
  FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  FHasPaint := False;

  FParams := AParams;
  InitializeWidget;
end;

constructor TQtWidget.CreateFrom(const AWinControl: TWinControl;
  AWidget: QWidgetH);
begin
  inherited Create;

  FOwner := nil;
  FOwnWidget := False;
  FCentralWidget := nil;
  // Initializes the properties
  FProps := niL;
  LCLObject := AWinControl;
  FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  
  // Creates the widget
  Widget := AWidget;
  
  FDefaultCursor := QCursor_create();
  QWidget_cursor(Widget, FDefaultCursor);

  // set Handle->QWidget map
  setProperty(Widget, 'lclwidget', Int64(PtrUInt(Self)));
  FillChar(FPaintData, sizeOf(FPaintData), 0);
  
  // set focus policy
  if (LCLObject <> nil) and not (Self is TQtMainWindow) then
  begin
    if LCLObject.TabStop then
      setFocusPolicy(QtStrongFocus)
    else
      setFocusPolicy(QtNoFocus);
  end;

  // Set mouse move messages policy
  QWidget_setMouseTracking(Widget, True);
end;

procedure TQtWidget.InitializeWidget;
var
  QtEdit: IQtEdit;
begin
  // Creates the widget
  Widget := CreateWidget(FParams);

  // retrieve default cursor on create
  FDefaultCursor := QCursor_create();
  QWidget_cursor(Widget, FDefaultCursor);
  
  // apply initial position and size
  move(FParams.X, FParams.Y);
  resize(FParams.Width, FParams.Height);
  
  FScrollX := 0;
  FScrollY := 0;

  {$ifdef VerboseQt}
  DebugLn('TQtWidget.InitializeWidget: Self:%x Widget:%x was created for control %s',
    [ptrint(Self), ptrint(Widget), LCLObject.Name]);
  {$endif}

  // set Handle->QWidget map
  setProperty(Widget, 'lclwidget', Int64(PtrUInt(Self)));

  FillChar(FPaintData, sizeOf(FPaintData), 0);

  // Sets it's initial properties

  // set focus policy
  if (LCLObject <> nil) and not (Self is TQtMainWindow) then
  begin
    if LCLObject.TabStop then
      setFocusPolicy(QtStrongFocus)
    else
      setFocusPolicy(QtNoFocus);
  end;

  // Set context menus to custom so LCL can better handle our popup menus
  if Supports(Self, IQtEdit, QtEdit) then
  begin
    setContextMenuPolicy(QtCustomContextMenu);
    setAttribute(QtWA_NoMousePropagation, True);
  end;

  if (csDesigning in LCLObject.ComponentState) and not
     (Self is TQtMainWindow) and
     HasPaint and
     getAutoFillBackground then
    setAutoFillBackground(False);

  // Set mouse move messages policy
  QWidget_setMouseTracking(Widget, True);
end;

procedure TQtWidget.DeInitializeWidget;
begin
  if Widget <> nil then
    DetachEvents;

  if Widget <> nil then
    removeProperty(Widget, 'lclwidget');

  QCursor_destroy(FDefaultCursor);
  
  if HasCaret then
    DestroyCaret;

  DestroyWidget;
end;

procedure TQtWidget.RecreateWidget;
var
  Parent: QWidgetH;
begin
  // update createparams
  with getPos do
  begin
    FParams.X := X;
    FParams.Y := Y;
  end;
  with getSize do
  begin
    FParams.Width := cx;
    FParams.Height := cy;
  end;
  if Widget <> nil then
    Parent := QWidget_parentWidget(Widget)
  else
    Parent := nil;
  DeinitializeWidget;
  InitializeWidget;
  if Parent <> nil then
    setParent(Parent);
end;

procedure TQtWidget.DestroyNotify(AWidget: TQtWidget);
begin
  if AWidget = FOwner then
    FOwner := nil;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtWidget.Destroy;
begin
  DeinitializeWidget;

  if FProps <> nil then
  begin
    FProps.Free;
    FProps:=nil;
  end;

  if FPaintData.ClipRegion <> nil then
  begin
    QRegion_Destroy(FPaintData.ClipRegion);
    FPaintData.ClipRegion:=nil;
  end;
  
  if FOwner <> nil then
    FOwner.DestroyNotify(Self);

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.GetContainerWidget
  Params:  None
  Returns: The widget of the control on top of which other controls
           should be placed
 ------------------------------------------------------------------------------}
function TQtWidget.GetContainerWidget: QWidgetH;
begin
  if FCentralWidget <> nil then
    Result := FCentralWidget
  else
    Result := Widget;
end;

procedure TQtWidget.Release;
begin
  LCLObject := nil;
  inherited Release;
end;

{$IFDEF VerboseQt}
function EventTypeToStr(Event:QEventH):string;
// Qt 3 events
const
  QEventChildInsertedRequest = 67;
  QEventChildInserted = 70;
  QEventLayoutHint = 72;
begin
  case QEvent_type(Event) of
    QEventNone: result:='QEventNone';
    QEventTimer: result:='QEventTimer';
    QEventMouseButtonPress: result:='QEventMouseButtonPress';
    QEventMouseButtonRelease: result:='QEventMouseButtonRelease';
    QEventMouseButtonDblClick: result:='QEventMouseButtonDblClick';
    QEventMouseMove: result:='QEventMouseMove';
    QEventKeyPress: result:='QEventKeyPress';
    QEventKeyRelease: result:='QEventKeyRelease';
    QEventFocusIn: result:='QEventFocusIn';
    QEventFocusOut: result:='QEventFocusOut';
    QEventEnter: result:='QEventEnter';
    QEventLeave: result:='QEventLeave';
    QEventPaint: result:='QEventPaint';
    QEventMove: result:='QEventMove';
    QEventResize: result:='QEventResize';
    QEventCreate: result:='QEventCreate';
    QEventDestroy: result:='QEventDestroy';
    QEventShow: result:='QEventShow';
    QEventHide: result:='QEventHide';
    QEventClose: result:='QEventClose';
    QEventQuit: result:='QEventQuit';
    QEventParentChange: result:='QEventParentChange';
    QEventThreadChange: result:='QEventThreadChange';
    QEventWindowActivate: result:='QEventWindowActivate';
    QEventWindowDeactivate: result:='QEventWindowDeactivate';
    QEventShowToParent: result:='QEventShowToParent';
    QEventHideToParent: result:='QEventHideToParent';
    QEventWheel: result:='QEventWheel';
    QEventWindowTitleChange: result:='QEventWindowTitleChange';
    QEventWindowIconChange: result:='QEventWindowIconChange';
    QEventApplicationWindowIconChange: result:='QEventApplicationWindowIconChange';
    QEventApplicationFontChange: result:='QEventApplicationFontChange';
    QEventApplicationLayoutDirectionChange: result:='QEventApplicationLayoutDirectionChange';
    QEventApplicationPaletteChange: result:='QEventApplicationPaletteChange';
    QEventPaletteChange: result:='QEventPaletteChange';
    QEventClipboard: result:='QEventClipboard';
    QEventSpeech: result:='QEventSpeech';
    QEventMetaCall: result:='QEventMetaCall';
    QEventSockAct: result:='QEventSockAct';
    QEventShortcutOverride: result:='QEventShortcutOverride';
    QEventDeferredDelete: result:='QEventDeferredDelete';
    QEventDragEnter: result:='QEventDragEnter';
    QEventDragMove: result:='QEventDragMove';
    QEventDragLeave: result:='QEventDragLeave';
    QEventDrop: result:='QEventDrop';
    QEventDragResponse: result:='QEventDragResponse';
//    QEventChildInsertedRequest: result:='(Qt3) QEventChildAdded'; //qt3
    QEventChildAdded: result:='QEventChildAdded';
    QEventChildPolished: result:='QEventChildPolished';
//    QEventChildInserted: result:='(Qt3) QEventChildAdded'; // qt3
//    QEventLayoutHint: result:='(Qt3) QEventChildAdded'; // qt3
    QEventChildRemoved: result:='QEventChildRemoved';
    QEventShowWindowRequest: result:='QEventShowWindowRequest';
    QEventPolishRequest: result:='QEventPolishRequest';
    QEventPolish: result:='QEventPolish';
    QEventLayoutRequest: result:='QEventLayoutRequest';
    QEventUpdateRequest: result:='QEventUpdateRequest';
    QEventUpdateLater: result:='QEventUpdateLater';
    QEventEmbeddingControl: result:='QEventEmbeddingControl';
    QEventActivateControl: result:='QEventActivateControl';
    QEventDeactivateControl: result:='QEventDeactivateControl';
    QEventContextMenu: result:='QEventContextMenu';
    QEventInputMethod: result:='QEventInputMethod';
    QEventAccessibilityPrepare: result:='QEventAccessibilityPrepare';
    QEventTabletMove: result:='QEventTabletMove';
    QEventLocaleChange: result:='QEventLocaleChange';
    QEventLanguageChange: result:='QEventLanguageChange';
    QEventLayoutDirectionChange: result:='QEventLayoutDirectionChange';
    QEventStyle: result:='QEventStyle';
    QEventTabletPress: result:='QEventTabletPress';
    QEventTabletRelease: result:='QEventTabletRelease';
    QEventOkRequest: result:='QEventOkRequest';
    QEventHelpRequest: result:='QEventHelpRequest';
    QEventIconDrag: result:='QEventIconDrag';
    QEventFontChange: result:='QEventFontChange';
    QEventEnabledChange: result:='QEventEnabledChange';
    QEventActivationChange: result:='QEventActivationChange';
    QEventStyleChange: result:='QEventStyleChange';
    QEventIconTextChange: result:='QEventIconTextChange';
    QEventModifiedChange: result:='QEventModifiedChange';
    QEventWindowBlocked: result:='QEventWindowBlocked';
    QEventWindowUnblocked: result:='QEventWindowUnblocked';
    QEventWindowStateChange: result:='QEventWindowStateChange';
    QEventMouseTrackingChange: result:='QEventMouseTrackingChange';
    QEventToolTip: result:='QEventToolTip';
    QEventWhatsThis: result:='QEventWhatsThis';
    QEventStatusTip: result:='QEventStatusTip';
    QEventActionChanged: result:='QEventActionChanged';
    QEventActionAdded: result:='QEventActionAdded';
    QEventActionRemoved: result:='QEventActionRemoved';
    QEventFileOpen: result:='QEventFileOpen';
    QEventShortcut: result:='QEventShortcut';
    QEventWhatsThisClicked: result:='QEventWhatsThisClicked';
    QEventAccessibilityHelp: result:='QEventAccessibilityHelp';
    QEventToolBarChange: result:='QEventToolBarChange';
    QEventApplicationActivated: result:='QEventApplicationActivated';
    QEventApplicationDeactivated: result:='QEventApplicationDeactivated';
    QEventQueryWhatsThis: result:='QEventQueryWhatsThis';
    QEventEnterWhatsThisMode: result:='QEventEnterWhatsThisMode';
    QEventLeaveWhatsThisMode: result:='QEventLeaveWhatsThisMode';
    QEventZOrderChange: result:='QEventZOrderChange';
    QEventHoverEnter: result:='QEventHoverEnter';
    QEventHoverLeave: result:='QEventHoverLeave';
    QEventHoverMove: result:='QEventHoverMove';
    QEventAccessibilityDescription: result:='QEventAccessibilityDescription';
    QEventParentAboutToChange: result:='QEventParentAboutToChange';
    QEventWinEventAct: result:='QEventWinEventAct';
    QEventAcceptDropsChange: result:='QEventAcceptDropsChange';
    QEventMenubarUpdated: result:='QEventMenubarUpdated';
    QEventZeroTimerEvent: result:='QEventZeroTimerEvent';
    QEventNonClientAreaMouseMove: result:='QEventNonClientAreaMouseMove';
    QEventNonClientAreaMouseButtonPress: result:='QEventNonClientAreaMouseButtonPress';
    QEventNonClientAreaMouseButtonRelease: result:='QEventNonClientAreaMouseButtonRelease';
    QEventNonClientAreaMouseButtonDblClick: result:='QEventNonClientAreaMouseButtonDblClick';
    QEventUser: result:='QEventUser';
    QEventMaxUser: result:='QEventMaxUser';
  else
    Result := Format('Unknown event: %d', [QEvent_type(Event)]);
  end;
end;
{$ENDIF}

{------------------------------------------------------------------------------
  Function: TQtWidget.EventFilter
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtWidget.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  BeginEventProcessing;
  Result := False;

  QEvent_accept(Event);

  {$ifdef VerboseQt}
  WriteLn('TQtWidget.EventFilter: Sender=', IntToHex(ptrint(Sender),8),
    ' LCLObject=', dbgsName(LCLObject),
    ' Event=', EventTypeToStr(Event));
  {$endif}

  if LCLObject <> nil then
  begin
    case QEvent_type(Event) of
      QEventWindowActivate: SlotActivateWindow(True);
      QEventWindowDeactivate: SlotActivateWindow(False);
      QEventShowToParent:
      begin
        if (Self is TQtMainWindow) and (TQtMainWindow(Self).IsMdiChild) then
        begin
          if not TCustomForm(LCLObject).Active then
          begin
            SlotActivateWindow(True);
            Result := True;
            QEvent_ignore(Event);
          end;
        end;
      end;
      QEventShow: SlotShow(True);
      QEventHide: SlotShow(False);
      QEventClose:
        if not SlotClose then
        begin
          QEvent_ignore(Event);
          Result := True;
        end;
      QEventDestroy: SlotDestroy;
      QEventEnter,
      QEventLeave: SlotMouseEnter(Sender, Event);
      
      QEventHoverEnter,
      QEventHoverLeave,
      QEventHoverMove: SlotHover(Sender, Event);

      QEventKeyPress,
      QEventKeyRelease:
        begin
          Result := SlotKey(Sender, Event) or (LCLObject is TCustomControl);
        end;

      QEventMouseButtonPress,
      QEventMouseButtonRelease,
      QEventMouseButtonDblClick: SlotMouse(Sender, Event);
      QEventMouseMove:
        begin
          SlotMouseMove(Event);
        end;
      QEventWheel:
        begin
          SlotMouseWheel(Sender, Event);
        end;
      QEventMove: SlotMove(Event);
      QEventResize: SlotResize(Event);
      QEventPaint:
        begin
          if FHasPaint then
            SlotPaint(Sender, Event);
        end;
      QEventContextMenu: SlotContextMenu(Sender, Event);
      QEventNonClientAreaMouseButtonPress:
        begin
          SlotNCMouse(Sender, Event);
        end;
      QEventLCLMessage:
        begin
          SlotLCLMessage(Sender, Event);
          Result := True;
        end;
    else
      QEvent_ignore(Event);
    end;
  end
  else
    QEvent_ignore(Event);
  EndEventProcessing;
end;

procedure TQtWidget.SlotActivateWindow(vActivate: Boolean); cdecl;
var
  Msg: TLMActivate;
  ParentForm: TCustomForm;
  FIsActivated: Boolean;
begin
  {$ifdef VerboseQt}
  WriteLn('TQtWidget.SlotActivateWindow Name', LCLObject.Name, ' vActivate: ', dbgs(vActivate));
  {$endif}

  FillChar(Msg, SizeOf(Msg), #0);
  
  if LCLObject is TCustomForm then
  begin
    FIsActivated := TCustomForm(LCLObject).Active;
    if vActivate = FIsActivated then
      exit;
  end;

  Msg.Active := vActivate;
  
  if not (LCLObject is TCustomForm) then
  begin
    ParentForm := GetParentForm(LCLObject);
    if Assigned(ParentForm) then
      TQtWidget(ParentForm.Handle).SlotActivateWindow(vActivate);
    exit;
  end else
    Msg.ActiveWindow := LCLObject.Handle;
  
  if vActivate then
    Msg.Msg := LM_ACTIVATE
  else
    Msg.Msg := LM_DEACTIVATE;

  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotShow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotShow(vShow: Boolean); cdecl;
var
  Msg: TLMShowWindow;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotShow Name', LCLObject.Name, ' vShow: ', dbgs(vShow));
  {$endif}

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SHOWWINDOW;
  Msg.Show := vShow;

  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.Close
  Params:  None
  Returns: Nothing

  Note: LCL uses LM_CLOSEQUERY to set the form visibility and if we don�t send this
 message, you won�t be able to show a form twice.
 ------------------------------------------------------------------------------}
function TQtWidget.SlotClose: Boolean; cdecl;
var
  Msg : TLMessage;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotClose');
  {$endif}
  FillChar(Msg, SizeOf(Msg), 0);

  Msg.Msg := LM_CLOSEQUERY;

  DeliverMessage(Msg);
  
  Result := False;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotDestroy
  Params:  None
  Returns: Nothing

  Currently commented because it was raising exception on software exit
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotDestroy; cdecl;
var
  Msg: TLMessage;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotDestroy');
  {$endif}
  Widget := nil;
  
  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_DESTROY;

  DeliverMessage(Msg);
end;

procedure TQtWidget.SlotHover(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMessage;
  MouseMsg: TLMMouseMove absolute Msg;
  MousePos: TQtPoint;
begin
  if QApplication_mouseButtons() = 0 then // in other case MouseMove will be hooked
  begin
    FillChar(Msg, SizeOf(Msg), #0);

    MousePos := QHoverEvent_pos(QHoverEventH(Event))^;
    OffsetMousePos(@MousePos);

    case QEvent_type(Event) of
      QEventHoverEnter : Msg.Msg := CM_MOUSEENTER;
      QEventHoverLeave : Msg.Msg := CM_MOUSELEAVE;
      QEventHoverMove  :
        begin
          MouseMsg.Msg := LM_MOUSEMOVE;
          MouseMsg.XPos := SmallInt(MousePos.X);
          MouseMsg.YPos := SmallInt(MousePos.Y);
        end;
    end;
    NotifyApplicationUserInput(Msg.Msg);
    DeliverMessage(Msg);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotKey
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtWidget.SlotKey(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
const
  CN_KeyDownMsgs: array[Boolean] of UINT = (CN_KEYDOWN, CN_SYSKEYDOWN);
  CN_KeyUpMsgs: array[Boolean] of UINT = (CN_KEYUP, CN_SYSKEYUP);
  LM_KeyDownMsgs: array[Boolean] of UINT = (LM_KEYDOWN, LM_SYSKEYDOWN);
  LM_KeyUpMsgs: array[Boolean] of UINT = (LM_KEYUP, LM_SYSKEYUP);
  CN_CharMsg: array[Boolean] of UINT = (CN_CHAR, CN_SYSCHAR);
  LM_CharMsg: array[Boolean] of UINT = (LM_CHAR, LM_SYSCHAR);
var
  KeyMsg: TLMKey;
  CharMsg: TLMChar;
  Modifiers: QtKeyboardModifiers;
  IsSysKey: Boolean;
  Text: WideString;
  UTF8Text: String; // use to prevent 3 time convertion from WideString to utf8 string
  UTF8Char: TUTF8Char;
  ACharCode: Word;
  AChar: Char;
  AKeyEvent: QKeyEventH;
begin
  {$ifdef VerboseQt}
    DebugLn('TQtWidget.SlotKey ', dbgsname(LCLObject));
  {$endif}

  Result := True;
  FillChar(KeyMsg, SizeOf(KeyMsg), #0);
  FillChar(CharMsg, SizeOf(CharMsg), #0);
  UTF8Text := '';
  UTF8Char := '';
  AChar := #0;

  // Detects special keys (shift, alt, control, etc)
  Modifiers := QKeyEvent_modifiers(QKeyEventH(Event));
  IsSysKey := (QtAltModifier and Modifiers) <> $0;
  KeyMsg.KeyData := QtKeyModifiersToKeyState(Modifiers);

  {$ifdef windows}
    ACharCode := QKeyEvent_nativeVirtualKey(QKeyEventH(Event));
    KeyMsg.CharCode := ACharCode;
  // todo: VK to Win_VK for other os too
    //WriteLn(QKeyEvent_nativeVirtualKey(QKeyEventH(Event)));
    //WriteLn(QKeyEvent_nativeScanCode(QKeyEventH(Event)));
  {$endif}

  // Loads the UTF-8 character associated with the keypress, if any
  QKeyEvent_text(QKeyEventH(Event), @Text);

  // Translates a Qt4 Key to a LCL VK_* key
  if KeyMsg.CharCode = 0 then
  begin
    ACharCode := QtKeyToLCLKey(QKeyEvent_key(QKeyEventH(Event)), Text);
    KeyMsg.CharCode := ACharCode;
  end;

  {------------------------------------------------------------------------------
   Sends the adequate key messages
   ------------------------------------------------------------------------------}
  case QEvent_type(Event) of
    QEventKeyPress: KeyMsg.Msg := CN_KeyDownMsgs[IsSysKey];
    QEventKeyRelease: KeyMsg.Msg := CN_KeyUpMsgs[IsSysKey];
  end;

  {$ifdef VerboseQt}
    WriteLn(' message: ', KeyMsg.Msg);
  {$endif}
  if KeyMsg.CharCode <> VK_UNKNOWN then
  begin
    NotifyApplicationUserInput(KeyMsg.Msg);
    if (DeliverMessage(KeyMsg) <> 0) or (KeyMsg.CharCode=VK_UNKNOWN) then
    begin
  {$ifdef VerboseQt}
      WriteLn('handled!');
  {$endif}
      Exit;
    end;

    // here we should let widgetset to handle key
    //...

    case QEvent_type(Event) of
      QEventKeyPress: KeyMsg.Msg := LM_KeyDownMsgs[IsSysKey];
      QEventKeyRelease: KeyMsg.Msg := LM_KeyUpMsgs[IsSysKey];
    end;
  {$ifdef VerboseQt}
    WriteLn(' message: ', KeyMsg.Msg);
  {$endif}
    NotifyApplicationUserInput(KeyMsg.Msg);
    if (DeliverMessage(KeyMsg) <> 0) or (KeyMsg.CharCode=VK_UNKNOWN) then
    begin
      // the LCL handled the key
  {$ifdef VerboseQt}
      WriteLn('handled!');
  {$endif}
      Result := KeyMsg.CharCode=VK_UNKNOWN;
      Exit;
    end;
  end;
  { Also sends a utf-8 key event for key down }

  if (QEvent_type(Event) = QEventKeyPress) and (Length(Text) <> 0) then
  begin
    UTF8Text := UTF8Encode(Text);
    UTF8Char := UTF8Text;
  {$ifdef VerboseQt}
    WriteLn('sending char ', UTF8Char);
  {$endif}
    if LCLObject.IntfUTF8KeyPress(UTF8Char, 1, IsSysKey) then
    begin
      // the LCL has handled the key
  {$ifdef VerboseQt}
      WriteLn('handled!');
  {$endif}
      Exit;
    end;

    // create the CN_CHAR / CN_SYSCHAR message
    FillChar(CharMsg, SizeOf(CharMsg), 0);
    CharMsg.Msg := CN_CharMsg[IsSysKey];
    CharMsg.KeyData := KeyMsg.KeyData;
    AChar := Text[1];
    CharMsg.CharCode := Word(AChar);

    //Send message to LCL
  {$ifdef VerboseQt}
    WriteLn(' message: ', CharMsg.Msg);
  {$endif}
    NotifyApplicationUserInput(CharMsg.Msg);
    if (DeliverMessage(CharMsg) <> 0) or (CharMsg.CharCode = VK_UNKNOWN) then
    begin
      // the LCL has handled the key
  {$ifdef VerboseQt}
      WriteLn('handled!');
  {$endif}
      Exit;
    end;

    //Here is where we (interface) can do something with the key
    //...

    //Send a LM_(SYS)CHAR
    CharMsg.Msg := LM_CharMsg[IsSysKey];

  {$ifdef VerboseQt}
    WriteLn(' message: ', CharMsg.Msg);
  {$endif}
    NotifyApplicationUserInput(CharMsg.Msg);
    DeliverMessage(CharMsg);
  end;
  
  // check if data was changed during key handling
  if (KeyMsg.CharCode <> ACharCode) or (UTF8Char <> UTF8Text) or (Word(AChar) <> CharMsg.CharCode) then
  begin
    // data was changed
    if UTF8Char <> UTF8Text then
      Text := UTF8Decode(Utf8Char)
    else
    if Word(AChar) <> CharMsg.CharCode then
      Text := Char(CharMsg.CharCode);
    AKeyEvent := QKeyEvent_createExtendedKeyEvent(
      QEvent_type(Event),
      LCLKeyToQtKey(KeyMsg.CharCode),
      Modifiers,
      0,
      KeyMsg.CharCode,
      0,
      @Text,
      QKeyEvent_isAutoRepeat(QKeyEventH(Event)),
      QKeyEvent_count(QKeyEventH(Event))
      );
    try
      QCoreApplication_sendEvent(Sender, AKeyEvent);
    finally
      QKeyEvent_destroy(AKeyEvent);
    end;
  end else
  begin
    Result := KeyMsg.CharCode in KeysToEat;
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotMouse
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotMouse(Sender: QObjectH; Event: QEventH); cdecl;
const
  // array of clickcount x buttontype
  MSGKIND: array[0..2, 1..4] of Integer =
  (
    (LM_LBUTTONDOWN, LM_LBUTTONDBLCLK, LM_LBUTTONTRIPLECLK, LM_LBUTTONQUADCLK),
    (LM_RBUTTONDOWN, LM_RBUTTONDBLCLK, LM_RBUTTONTRIPLECLK, LM_RBUTTONQUADCLK),
    (LM_MBUTTONDOWN, LM_MBUTTONDBLCLK, LM_MBUTTONTRIPLECLK, LM_MBUTTONQUADCLK)
  );
var
  Msg: TLMMouse;
  MousePos: TQtPoint;
  MButton: QTMouseButton;
  Modifiers: QtKeyboardModifiers;

  function CheckMouseButtonDown(AButton: Integer): Cardinal;

    function LastClickInSameWidget: boolean;
    begin
      Result := (LastMouse.Widget <> nil) and
                (LastMouse.Widget = Sender);
    end;

    function LastClickAtSamePosition: boolean;
    begin
      Result:= (Abs(MousePos.X-LastMouse.MousePos.X) <= DblClickThreshold) and
               (Abs(MousePos.Y-LastMouse.MousePos.Y) <= DblClickThreshold);
    end;

    function LastClickInTime: boolean;
    begin
      Result:=((now - LastMouse.TheTime) <= ((1/86400)*(QApplication_doubleClickInterval/1000)));
    end;

    function TestIfMultiClick: boolean;
    begin
      Result:= LastClickInSameWidget and
               LastClickAtSamePosition and
               LastClickInTime;
    end;

  var
    IsMultiClick: boolean;
  begin
    Result := LM_NULL;

    IsMultiClick := TestIfMultiClick;

    if QEvent_type(Event) = QEventMouseButtonDblClick then
    begin
      // the qt itself has detected a double click
      if (LastMouse.ClickCount >= 2) and IsMultiClick then
        // the double click was already detected and sent to the LCL
        // -> skip this message
        exit
      else
        LastMouse.ClickCount := 2;
    end
    else
    begin
      inc(LastMouse.ClickCount);

      if (LastMouse.ClickCount <= 4) and IsMultiClick then
      begin
        // multi click
      end else
      begin
        // normal click
        LastMouse.ClickCount:=1;
      end;
    end;

    LastMouse.TheTime := Now;
    LastMouse.MousePos := MousePos;
    LastMouse.Widget := Sender;

    Result := MSGKIND[AButton][LastMouse.ClickCount];
  end;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotMouse');
  {$endif}

  // idea of multi click implementation is taken from gtk

  FillChar(Msg, SizeOf(Msg), #0);
  
  MousePos := QMouseEvent_pos(QMouseEventH(Event))^;
  OffsetMousePos(@MousePos);

  Modifiers := QInputEvent_modifiers(QInputEventH(Event));
  Msg.Keys := QtKeyModifiersToKeyState(Modifiers);

  Msg.XPos := SmallInt(MousePos.X);
  Msg.YPos := SmallInt(MousePos.Y);
  
  MButton := QmouseEvent_Button(QMouseEventH(Event));

  case QEvent_type(Event) of
    QEventMouseButtonPress, QEventMouseButtonDblClick:
    begin
      Msg.Keys := Msg.Keys or QtButtonsToLCLButtons(MButton);
      case MButton of
        QtLeftButton: Msg.Msg := CheckMouseButtonDown(0);
        QtRightButton: Msg.Msg := CheckMouseButtonDown(1);
        QtMidButton: Msg.Msg := CheckMouseButtonDown(2);
      end;
      NotifyApplicationUserInput(Msg.Msg);
      DeliverMessage(Msg);
      Msg.Msg := LM_PRESSED;
      DeliverMessage(Msg);
    end;
    QEventMouseButtonRelease:
    begin
      LastMouse.Widget := Sender;
      LastMouse.MousePos := MousePos;
      Msg.Keys := Msg.Keys or QtButtonsToLCLButtons(MButton);
      case MButton of
        QtLeftButton: Msg.Msg := LM_LBUTTONUP;
        QtRightButton: Msg.Msg := LM_RBUTTONUP;
        QtMidButton: Msg.Msg := LM_MBUTTONUP;
      end;

      NotifyApplicationUserInput(Msg.Msg);
      DeliverMessage(Msg);
      { Clicking on buttons operates differently, because QEventMouseButtonRelease
        is sent if you click a control, drag the mouse out of it and release, but
        buttons should not be clicked on this case. }
      if not (LCLObject is TCustomButton) then
      begin
        Msg.Msg := LM_CLICKED;
        DeliverMessage(Msg);
      end;
      Msg.Msg := LM_RELEASED;
      DeliverMessage(Msg);
    end;
  end;
end;

procedure TQtWidget.SlotNCMouse(Sender: QObjectH; Event: QEventH); cdecl;
var
  AHeader: TRect;
  APoint: TQtPoint;
begin
  //Drag&Dock support TCustomForm => Start BeginDrag()
  if (LCLObject is TCustomForm) and 
     (TWinControlAccess(LCLObject).DragKind = dkDock) and
     (TWinControlAccess(LCLObject).DragMode = dmAutomatic) and
     (QMouseEvent_button(QMouseEventH(Event)) = QtLeftButton) then
  begin
    APoint := QMouseEvent_globalPos(QMouseEventH(Event))^;
    AHeader := getGeometry;
    with getFrameGeometry do
      AHeader.Top := Top;

    // remove various buttons from header (how to request their pos cross platform?):
    Inc(AHeader.Left, 20);  // system menu
    Dec(AHeader.Right, 80); // close, min, max buttons
    if AHeader.Right < AHeader.Left then
      AHeader.Right := AHeader.Left + 1;

    // we can skip translation of coords to global since we already working with window
    // check for title
    if PtInRect(AHeader, Point(APoint.x, APoint.y)) then
      LCLObject.BeginDrag(true);
  end;
end;

procedure TQtWidget.SlotMouseEnter(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  case QEvent_type(Event) of
    QEventEnter: Msg.Msg := CM_MOUSEENTER;
    QEventLeave: Msg.Msg := CM_MOUSELEAVE;
  end;
  DeliverMessage(Msg);
end;

function TQtWidget.QtButtonsToLCLButtons(AButtons: QTMouseButton): PtrInt;
begin
  Result := 0;
  if (QtLeftButton and AButtons) <> 0 then
    Result := Result or MK_LBUTTON;

  if (QtRightButton and AButtons) <> 0 then
    Result := Result or MK_RBUTTON;

  if (QtMidButton and AButtons) <> 0 then
    Result := Result or MK_MBUTTON;

  if (QtXButton1 and AButtons) <> 0 then
    Result := Result or MK_XBUTTON1;
    
  if (QtXButton2 and AButtons) <> 0 then
    Result := Result or MK_XBUTTON2;
end;

function TQtWidget.QtKeyModifiersToKeyState(AModifiers: QtKeyboardModifiers): PtrInt;
begin
  Result := 0;
  if AModifiers and qtShiftModifier <> 0 then
    Result := Result or MK_SHIFT;
  if AModifiers and qtControlModifier <> 0 then
    Result := Result or MK_CONTROL;
  { TODO: add support for ALT, META and NUMKEYPAD }
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotMouseMove
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotMouseMove(Event: QEventH); cdecl;
var
  Msg: TLMMouseMove;
  MousePos: TQtPoint;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  
  MousePos := QMouseEvent_pos(QMouseEventH(Event))^;
  OffsetMousePos(@MousePos);

  Msg.XPos := SmallInt(MousePos.X);
  Msg.YPos := SmallInt(MousePos.Y);
  
  Msg.Keys := QtButtonsToLCLButtons(QmouseEvent_Buttons(QMouseEventH(Event)));

  Msg.Msg := LM_MOUSEMOVE;

  NotifyApplicationUserInput(Msg.Msg);
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotMouseWheel
  Params:  None
  Returns: Nothing

  Qt stores the delta in 1/8 of a degree
  Most mouses scroll 15 degrees each time
 
  Msg.WheelData: -1 for up, 1 for down
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotMouseWheel(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMMouseEvent;
  MousePos: TQtPoint;
  Modifiers: QtKeyboardModifiers;
  ModifierState: PtrInt;
begin
  FillChar(Msg, SizeOf(Msg), #0);

  MousePos := QWheelEvent_Pos(QWheelEventH(Event))^;
  OffsetMousePos(@MousePos);

  Modifiers := QInputEvent_modifiers(QInputEventH(Event));
  Msg.State := [];
  ModifierState := QtKeyModifiersToKeyState(Modifiers);
  if (ModifierState and MK_SHIFT) <> 0 then
    Msg.State := [ssShift];
  if (ModifierState and MK_CONTROL) <> 0 then
    Msg.State := [ssCtrl] + Msg.State;

  LastMouse.Widget := Sender;
  LastMouse.MousePos := MousePos;
  
  Msg.Msg := LM_MOUSEWHEEL;

  Msg.X := SmallInt(MousePos.X);
  Msg.Y := SmallInt(MousePos.Y);

  Msg.WheelDelta := QWheelEvent_delta(QWheelEventH(Event));
  
  NotifyApplicationUserInput(Msg.Msg);
  DeliverMessage(Msg);

  {propagate mousewheel to parent if our sender is TPanel,
   fixes problem with mousewheel scroll with lazreport}
  if not (csDesigning in LCLObject.ComponentState) and
    (LCLObject is TPanel) and
    Assigned(LCLObject.Parent) then
      TQtWidget(LCLObject.Parent.Handle).DeliverMessage(Msg);
end;

procedure TQtWidget.SlotMove(Event: QEventH); cdecl;
var
  Msg: TLMMove;
  Pos: TQtPoint;
  FrameRect, WindowRect: TRect;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotMove');
  {$endif}

  if not QEvent_spontaneous(Event) or
    (not QEvent_spontaneous(Event) and
    ((Self is TQtMainWindow) and not
    TQtMainWindow(Self).IsMdiChild)) then
    Exit;

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_MOVE;

  Msg.MoveType := Msg.MoveType or Move_SourceIsInterface;

  Pos := QMoveEvent_pos(QMoveEventH(Event))^;
  FrameRect := getFrameGeometry;
  WindowRect := getGeometry;

  Msg.XPos := Pos.x - (WindowRect.Left - FrameRect.Left);
  Msg.YPos := Pos.y - (WindowRect.Top - FrameRect.Top);

  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotPaint
  Params:  None
  Returns: Nothing

  Sends a LM_PAINT message to the LCL. This is for windowed controls only
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotPaint(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMPaint;
  AStruct: PPaintStruct;
  P: TPoint;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotPaint ', dbgsName(LCLObject));
  {$endif}
  if (LCLObject is TWinControl) then
  begin
    FillChar(Msg, SizeOf(Msg), #0);

    Msg.Msg := LM_PAINT;
    New(AStruct);
    FillChar(AStruct^, SizeOf(TPaintStruct), 0);
    Msg.PaintStruct := AStruct;

    with PaintData do
    begin
      PaintWidget := Widget;
      ClipRegion := QPaintEvent_Region(QPaintEventH(Event));
      if ClipRect = nil then
        New(ClipRect);
      QPaintEvent_Rect(QPaintEventH(Event), ClipRect);
    end;

    Msg.DC := BeginPaint(THandle(Self), AStruct^);
    FContext := Msg.DC;
    
    Msg.PaintStruct^.rcPaint := PaintData.ClipRect^;
    Msg.PaintStruct^.hdc := FContext;

    if LCLObject is THintWindow then
      Msg.DC := Msg.DC;

    P := getClientOffset;
    inc(P.X, FScrollX);
    inc(P.Y, FScrollY);
    TQtDeviceContext(Msg.DC).translate(P.X, P.Y);

    // send paint message
    try
      // Saving clip rect and clip region
      try
        LCLObject.WindowProc(TLMessage(Msg));
        if HasCaret then
          QtCaret.DrawCaret;
      finally
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
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SlotResize
  Params:  None
  Returns: Nothing

  Sends a LM_SIZE message to the LCL.
 ------------------------------------------------------------------------------}
procedure TQtWidget.SlotResize(Event: QEventH); cdecl;
var
  Msg: TLMSize;
  NewSize: TSize;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotResize');
  {$endif}
  
  // return size w/o frame
  NewSize := QResizeEvent_size(QResizeEventH(Event))^;
{
  WriteLn('SlotResize: ', dbgsName(LCLObject),
    ' AOldWidth = ', LCLObject.Width, ' AOldHeight = ', LCLObject.Height,
    ' ANewWidth = ', NewSize.cx, ' ANewHeight = ', NewSize.cy
  );
}
  if not Assigned(LCLObject) then exit;
  
  if (NewSize.cx <> LCLObject.Width) or (NewSize.cy <> LCLObject.Height) or
     (LCLObject.ClientRectNeedsInterfaceUpdate) then
  begin
    LCLObject.InvalidateClientRectCache(true);
    LCLObject.DoAdjustClientRectChange;
  end;

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SIZE;

  case QWidget_windowState(Widget) of
    QtWindowMinimized: Msg.SizeType := SIZEICONIC;
    QtWindowMaximized: Msg.SizeType := SIZEFULLSCREEN;
    QtWindowFullScreen: Msg.SizeType := SIZEFULLSCREEN;
  else
    Msg.SizeType := SIZENORMAL;
  end;

  Msg.SizeType := Msg.SizeType or Size_SourceIsInterface;

  Msg.Width := NewSize.cx;
  Msg.Height := NewSize.cy;

  DeliverMessage(Msg);
end;

procedure TQtWidget.SlotContextMenu(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMMouse;
  Modifiers: QtKeyboardModifiers;
  MousePos: TQtPoint;
  QtEdit: IQtEdit;
begin

  if Supports(Self, IQtEdit, QtEdit) then
  begin
    if Assigned(LCLObject.PopupMenu) then
    begin
      if getContextMenuPolicy <> QtCustomContextMenu then
        setContextMenuPolicy(QtCustomContextMenu);
    end else
    begin
      {revert to default if widget supports defaultcontextmenu }
      if getContextMenuPolicy <> QtDefaultContextMenu then
        setContextMenuPolicy(QtDefaultContextMenu);
        exit;
    end;
  end;

  FillChar(Msg, SizeOf(Msg), #0);
  MousePos := QContextMenuEvent_pos(QContextMenuEventH(Event))^;
  OffsetMousePos(@MousePos);
  Modifiers := QInputEvent_modifiers(QInputEventH(Event));

  Msg.Msg := LM_CONTEXTMENU;
  Msg.Keys := QtKeyModifiersToKeyState(Modifiers);
  Msg.XPos := SmallInt(MousePos.X);
  Msg.YPos := SmallInt(MousePos.Y);

  DeliverMessage(Msg);
end;

procedure TQtWidget.SlotLCLMessage(Sender: QObjectH; Event: QEventH); cdecl;
var
  MessageEvent: QLCLMessageEventH absolute Event;
  Msg: TLMessage;
begin
  Msg.msg := QLCLMessageEvent_getMsg(MessageEvent);
  Msg.wParam := QLCLMessageEvent_getWParam(MessageEvent);
  Msg.lParam := QLCLMessageEvent_getLParam(MessageEvent);
  Msg.Result := 0;
  QLCLMessageEvent_setMsgResult(MessageEvent, DeliverMessage(Msg));
end;

procedure TQtWidget.Activate;
begin
  QWidget_activateWindow(Widget);
  {$IFDEF LINUX}
  // qt X11 bug ?  activates window but it's not in
  // front of others.
  {$note Check this with next qt version (>4.3.4)}
  if QWidget_isWindow(Widget)
  and not QWidget_isModal(Widget) then
    QWidget_raise(Widget);
  {$ENDIF}
end;

procedure TQtWidget.BringToFront;
begin
  Activate;
  raiseWidget;
end;

procedure TQtWidget.clearMask;
begin
  QWidget_clearMask(Widget);
end;

procedure TQtWidget.OffsetMousePos(APoint: PQtPoint);
begin
  with getClientOffset do
  begin
    dec(APoint^.x, x - FScrollX);
    dec(APoint^.y, y - FScrollY);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SetColor
  Params:  QColorH
  Returns: Nothing

  Changes the color of a widget
 ------------------------------------------------------------------------------}
procedure TQtWidget.SetColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteWindow, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

function TQtWidget.getContextMenuPolicy: QtContextMenuPolicy;
begin
  Result := QWidget_contextMenuPolicy(Widget);
end;

procedure TQtWidget.setContextMenuPolicy(const AValue: QtContextMenuPolicy);
begin
  QWidget_setContextMenuPolicy(Widget, AValue);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.SetTextColor
  Params:  QColorH
  Returns: Nothing

  Changes the text color of a widget
 ------------------------------------------------------------------------------}
procedure TQtWidget.SetTextColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteWindowText, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtWidget.SetCursor(const ACursor: QCursorH);
begin
  {$IFDEF DARWIN}
  if not QWidget_isVisible(Widget) then
    exit;
  {$ENDIF}
  if ACursor <> nil then
    QWidget_setCursor(Widget, ACursor)
  else
    QWidget_setCursor(Widget, FDefaultCursor);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.Update
  Params:  None
  Returns: Nothing

  Schedules a paint event for processing when Qt returns to the main event loop
 ------------------------------------------------------------------------------}
procedure TQtWidget.Update(ARect: PRect = nil);
begin
  if ARect <> nil then
    QWidget_update(Widget, ARect)
  else
    QWidget_update(Widget);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.Repaint
  Params:  None
  Returns: Nothing

  Repaints the control imediately
 ------------------------------------------------------------------------------}
procedure TQtWidget.Repaint(ARect: PRect = nil);
begin
  if ARect <> nil then
    QWidget_repaint(Widget, ARect)
  else
    QWidget_repaint(Widget);
end;

procedure TQtWidget.setWindowTitle(Str: PWideString);
begin
  QWidget_setWindowTitle(Widget, Str);
end;

procedure TQtWidget.WindowTitle(Str: PWideString);
begin
  QWidget_WindowTitle(Widget, Str);
end;

procedure TQtWidget.Hide;
begin
  QWidget_hide(Widget);
end;

procedure TQtWidget.Show;
begin
  QWidget_show(Widget);
  {$IFNDEF QTOPIA}
  {$IFDEF LINUX}
  if QWidget_isWindow(Widget) then
    QtX11WaitForWindowManager(Widget);
  {$ENDIF}  
  {$ENDIF}
end;

procedure TQtWidget.ShowNormal;
begin
  QWidget_showNormal(Widget);
  {$IFNDEF QTOPIA}
  {$IFDEF LINUX}
  if QWidget_isWindow(Widget) then
    QtX11WaitForWindowManager(Widget);
  {$ENDIF}  
  {$ENDIF}
end;

procedure TQtWidget.ShowMinimized;
begin
  QWidget_showMinimized(Widget);
  {$IFNDEF QTOPIA}
  {$IFDEF LINUX}
  if QWidget_isWindow(Widget) then
    QtX11WaitForWindowManager(Widget);
  {$ENDIF}
  {$ENDIF}
end;

procedure TQtWidget.ShowMaximized;
begin
  QWidget_showMaximized(Widget);
  {$IFNDEF QTOPIA}
  {$IFDEF LINUX}
  if QWidget_isWindow(Widget) then
    QtX11WaitForWindowManager(Widget);
  {$ENDIF}  
  {$ENDIF}
end;

function TQtWidget.getActionByIndex(AIndex: Integer): QActionH;
var
  ActionList: TPtrIntArray;
begin
  QWidget_actions(Widget, @ActionList);
  if (AIndex > 0) and (AIndex < Length(ActionList)) then
    Result := QActionH(ActionList[AIndex])
  else
    Result := nil;
end;

function TQtWidget.getAutoFillBackground: Boolean;
begin
  Result := QWidget_autoFillBackground(Widget);
end;

function TQtWidget.getEnabled: Boolean;
begin
  Result := QWidget_isEnabled(Widget);
end;

function TQtWidget.getFocusPolicy: QtFocusPolicy;
begin
  Result := QWidget_focusPolicy(Widget);
end;

function TQtWidget.getFrameGeometry: TRect;
begin
  QWidget_frameGeometry(Widget, @Result);
end;

function TQtWidget.getGeometry: TRect;
begin
  QWidget_geometry(Widget, @Result);
end;

function TQtWidget.getVisible: boolean;
begin
  Result := QWidget_isVisible(Widget);
end;

function TQtWidget.getParent: QWidgetH;
begin
  Result := QWidget_parentWidget(Widget);
end;

function TQtWidget.getPos: TQtPoint;
begin
  QWidget_pos(Widget, @Result);
end;

function TQtWidget.getFrameSize: TSize;
begin
  QWidget_frameSize(Widget, @Result);
end;

function TQtWidget.getSize: TSize;
begin
  QWidget_size(Widget, @Result);
end;

function TQtWidget.getText: WideString;
begin
  Result := FText;
end;

function TQtWidget.getTextStatic: Boolean;
begin
  Result := True;
end;

function TQtWidget.getHeight: Integer;
begin
  Result := QWidget_height(Widget);
end;

function TQtWidget.getWidth: Integer;
begin
  Result := QWidget_width(Widget);
end;

function TQtWidget.getClientBounds: TRect;
begin
  QWidget_contentsRect(getContainerWidget, @Result);
end;

function TQtWidget.getClientOffset: TPoint;
var
  P: TQtPoint;
  R: TRect;
begin
  // we need an offset of container inside widget, but if container = widget then
  // offset = 0
  if Widget <> GetContainerWidget then
    QWidget_pos(GetContainerWidget, @P)
  else
    P := QtPoint(0, 0);
  R := getClientBounds;
  Result := Point(P.x + R.Left, P.y + R.Top);
end;

procedure TQtWidget.grabMouse;
begin
  //DumpStack;
  //DebugLn(['current grab is: ', dbgs(QWidget_mouseGrabber())]);
  //DebugLn(['grab mouse for: ', dbgsName(LCLObject), ' : ', dbgs(Widget)]);
  QWidget_grabMouse(Widget);
end;

function TQtWidget.hasFocus: Boolean;
begin
  Result := QWidget_hasFocus(Widget);
end;

procedure TQtWidget.lowerWidget;
begin
  QWidget_lower(Widget);
end;

procedure TQtWidget.move(ANewLeft, ANewTop: Integer);
begin
  QWidget_move(Widget, ANewLeft, ANewTop);
end;

procedure TQtWidget.preferredSize(var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean);
var
  PrefSize: TSize;
begin
  sizeHint(@PrefSize);
  if (PrefSize.cx >= 0) and (PrefSize.cy >=0) then
  begin
    PreferredWidth := PrefSize.cx;
    PreferredHeight := PrefSize.cy;
  end;
end;

procedure TQtWidget.raiseWidget;
begin
  QWidget_raise(Widget);
end;

procedure TQtWidget.frame_resize(ANewWidth, ANewHeight: Integer);
var
  R1, R2: TRect;
  dw, dh: integer;
begin
  R1 := getGeometry;
  R2 := getFrameGeometry;
  dw := (R1.Left - R2.Left) + (R2.Right - R1.Right);
  dh := (R1.Top - R2.Top) + (R2.Bottom - R1.Bottom);
  QWidget_resize(Widget, ANewWidth - dw, ANewHeight - dh);
end;

procedure TQtWidget.resize(ANewWidth, ANewHeight: Integer);
begin
{
  WriteLn('Resize: ', dbgsName(LCLObject),
    ' AOldWidth = ', LCLObject.Width, ' AOldHeight = ', LCLObject.Height,
    ' ANewWidth = ', ANewWidth, ' ANewHeight = ', ANewHeight);
}
  QWidget_resize(Widget, ANewWidth, ANewHeight);
end;

procedure TQtWidget.releaseMouse;
var
  AGrabWidget: QWidgetH;
begin
  // capture widget can be one of childs of Widget if Widget is complex control
  // so better to look for current Capture widget to release it instead of pass Widget as argument
  AGrabWidget := QWidget_mouseGrabber();
  //DebugLn(['releasing current grab: ', dbgs(AGrabWidget)]);
  if AGrabWidget <> nil then
    QWidget_releaseMouse(AGrabWidget);
end;

procedure TQtWidget.scroll(dx, dy: integer);
begin
  QWidget_scroll(getContainerWidget, dx, dy);
  FScrollX := FScrollX + dx;
  FScrollY := FScrollY + dy;
end;

procedure TQtWidget.setAutoFillBackground(const AValue: Boolean);
begin
  QWidget_setAutoFillBackground(Widget, AValue);
end;

procedure TQtWidget.setAttribute(const Attr: QtWidgetAttribute;
  const TurnOn: Boolean);
begin
  QWidget_setAttribute(Widget, Attr, TurnOn);
end;

procedure TQtWidget.setBackgroundRole(const ARole: QPaletteColorRole);
begin
  QWidget_setBackgroundRole(Widget, ARole);
end;

procedure TQtWidget.setEnabled(p1: Boolean);
begin
  QWidget_setEnabled(Widget, p1);
end;

procedure TQtWidget.setFocus;
begin
  QWidget_setFocus(Widget);
end;

procedure TQtWidget.setFocusPolicy(const APolicy: QtFocusPolicy);
begin
  QWidget_setFocusPolicy(Widget, APolicy);
end;

procedure TQtWidget.setFocusProxy(const AWidget: QWidgetH);
begin
  QWidget_setFocusProxy(Widget, AWidget);
end;

procedure TQtWidget.setFont(AFont: QFontH);
begin
  QWidget_setFont(Widget, AFont);
end;

procedure TQtWidget.setGeometry(ARect: TRect);
begin
  QWidget_setGeometry(Widget, @ARect);
end;

procedure TQtWidget.setLayoutDirection(ADirection: QtLayoutDirection);
begin
  QWidget_setLayoutDirection(Widget, ADirection);
end;

procedure TQtWidget.setMaximumSize(AWidth, AHeight: Integer);
begin
  QWidget_setMaximumSize(Widget, AWidth, AHeight);
end;

procedure TQtWidget.setMask(AMask: QBitmapH);
begin
  QWidget_setMask(Widget, AMask);
end;

procedure TQtWidget.setMinimumSize(AWidth, AHeight: Integer);
begin
  QWidget_setMinimumSize(Widget, AWidth, AHeight);
end;

procedure TQtWidget.setVisible(visible: Boolean);
begin
  QWidget_setVisible(Widget, visible);
  {$IFNDEF QTOPIA}
  {$IFDEF LINUX}
  if Visible and QWidget_isWindow(Widget) then
    QtX11WaitForWindowManager(Widget);
  {$ENDIF}  
  {$ENDIF}
end;

function TQtWidget.windowModality: QtWindowModality;
begin
  Result := QWidget_windowModality(Widget);
end;

procedure TQtWidget.setWindowModality(windowModality: QtWindowModality);
begin
  QWidget_setWindowModality(Widget, windowModality);
end;

procedure TQtWidget.setParent(parent: QWidgetH);
begin
  QWidget_setParent(Widget, parent);
end;

procedure TQtWidget.setText(const W: WideString);
begin
  FText := W;
end;

procedure TQtWidget.setWindowFlags(_type: QtWindowFlags);
begin
  QWidget_setWindowFlags(Widget, _type);
end;

procedure TQtWidget.setWindowIcon(AIcon: QIconH);
var
  DestroyIcon: Boolean;
begin
  DestroyIcon := AIcon = nil;
  if DestroyIcon then
    AIcon := QIcon_create();
  QWidget_setWindowIcon(Widget, AIcon);
  if DestroyIcon then
    QIcon_destroy(AIcon);
end;

function TQtWidget.windowFlags: QtWindowFlags;
begin
  Result := QWidget_windowFlags(Widget);
end;

procedure TQtWidget.setWidth(p1: Integer);
var
  R: TRect;
begin
  R := getGeometry;
  R.Right := R.Left + p1;
  setGeometry(R);
end;

procedure TQtWidget.setHeight(p1: Integer);
var
  R: TRect;
begin
  R := getGeometry;
  R.Bottom := R.Top + p1;
  setGeometry(R);
end;

procedure TQtWidget.setUpdatesEnabled(const AEnabled: Boolean);
begin
  QWidget_setUpdatesEnabled(Widget, AEnabled);
end;

procedure TQtWidget.setWindowState(AState: QtWindowStates);
begin
  QWidget_setWindowState(Widget, AState);
end;

procedure TQtWidget.sizeHint(size: PSize);
begin
  QWidget_sizeHint(Widget, size);
end;

{------------------------------------------------------------------------------
  Function: TQtWidget.QtKeyToLCLKey
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtWidget.QtKeyToLCLKey(AKey: Integer; AText: WideString): Word;
begin
  // The big problem here with unicode keys
  // Example: for Russian letter A qt returns AKey = $0410 and this is
  // absolutely correct: 0400 - 04FF - is russian unicode space and
  // 0410 is defined as "CYRILLIC CAPITAL LETTER A"

  Result := VK_UNKNOWN;
  case AKey of
    QtKey_0..QtKey_9: Result := VK_0 + (AKey - QtKey_0);
    QtKey_At: Result := VK_2; // some bug, but Ctrl + Shit + 2 produce QtKey_At
    QtKey_Escape: Result := VK_ESCAPE;
    QtKey_Tab: Result := VK_TAB;
    QtKey_Backtab: Result := VK_TAB; // ???
    QtKey_Backspace: Result := VK_BACK;
    QtKey_Return: Result := VK_RETURN;
    QtKey_Enter: Result := VK_RETURN;
    QtKey_Insert: Result := VK_INSERT;
    QtKey_Delete: Result := VK_DELETE;
    QtKey_Pause: Result := VK_PAUSE;
    QtKey_Print: Result := VK_PRINT;
    QtKey_SysReq: Result := VK_UNKNOWN; // ???
    QtKey_Clear: Result := VK_CLEAR;
    QtKey_Home: Result := VK_HOME;
    QtKey_End: Result := VK_END;
    QtKey_Left: Result := VK_LEFT;
    QtKey_Up: Result := VK_UP;
    QtKey_Right: Result := VK_RIGHT;
    QtKey_Down: Result := VK_DOWN;
    QtKey_PageUp: Result := VK_PRIOR;
    QtKey_PageDown: Result := VK_NEXT;
    QtKey_Shift: Result := VK_SHIFT;     // There is also RSHIFT
    QtKey_Control: Result := VK_CONTROL; // There is also RCONTROL
    QtKey_Meta: Result := VK_UNKNOWN; // ???
    QtKey_Alt: Result := VK_MENU;
    QtKey_CapsLock: Result := VK_CAPITAL;
    QtKey_NumLock: Result := VK_NUMLOCK;
    QtKey_ScrollLock: Result := VK_SCROLL;
    QtKey_F1..QtKey_F24: Result := VK_F1 + (AKey - QtKey_F1);
    QtKey_F25..
    QtKey_F35: Result := VK_UNKNOWN;
    QtKey_Super_L: Result := VK_LWIN;
    QtKey_Super_R: Result := VK_RWIN;
    QtKey_Menu: Result := VK_MENU;
    QtKey_Hyper_L,
    QtKey_Hyper_R: Result := VK_UNKNOWN;
    QtKey_Help: Result := VK_HELP;
    QtKey_Direction_L,
    QtKey_Direction_R,
    QtKey_Exclam..
    QtKey_ParenRight: Result := VK_UNKNOWN;
    QtKey_Asterisk: Result := VK_MULTIPLY;
    QtKey_Plus: Result := VK_ADD;
    QtKey_Comma: Result := VK_SEPARATOR;
    QtKey_Minus: Result := VK_SUBTRACT;
    QtKey_Period: Result := VK_DECIMAL;
    QtKey_Slash: Result := VK_DIVIDE;
    QtKey_BracketLeft..
    QtKey_ydiaeresis,
    QtKey_Multi_key..
    QtKey_No: Result := VK_UNKNOWN;
    QtKey_Cancel: Result := VK_CANCEL;
    QtKey_Printer: Result := VK_PRINT;
    QtKey_Execute: Result := VK_EXECUTE;
    QtKey_Sleep: Result := VK_SLEEP;
    QtKey_Play: Result := VK_PLAY;
    QtKey_Zoom: Result := VK_ZOOM;
    QtKey_Context1..
    QtKey_Flip,
    QtKey_unknown: Result := VK_UNKNOWN;
  else
    if AKey <= $FF then // Qt:AKey = VK_KEY in many cases
      Result := AKey
    else
    if AText <> '' then
    begin
      // use QChar to understand whether we have unicode letter or number here or no
      // then try to map that char to VK_ code
    end;
  end;
end;

procedure TQtWidget.SetHasCaret(const AValue: Boolean);
begin
  FHasCaret := AValue;
end;

class procedure TQtWidget.removeProperty(AObject: QObjectH; APropName: PAnsiChar);
var
  AVariant: QVariantH;
begin
  AVariant := QVariant_create(QVariantInvalid);
  QObject_setProperty(AObject, APropName, AVariant);
  QVariant_destroy(AVariant);
end;

class procedure TQtWidget.setProperty(AObject: QObjectH; APropName: PAnsiChar; APropValue: Int64);
var
  AVariant: QVariantH;
begin
  AVariant := QVariant_create(APropValue);
  QObject_setProperty(AObject, APropName, AVariant);
  QVariant_destroy(AVariant);
end;

function TQtWidget.LCLKeyToQtKey(AKey: Word): Integer;
const
  VKKeyToQtKeyMap: array[0..255] of Integer = // Keyboard mapping table
   (
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Cancel,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Backspace,
    QtKey_Tab,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Clear,
    QtKey_Return,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Shift,
    QtKey_Control,
    QtKey_Alt,
    QtKey_Pause,
    QtKey_CapsLock,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Escape,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Mode_switch,
    QtKey_Space,
    QtKey_PageUp,
    QtKey_PageDown,
    QtKey_End,
    QtKey_Home,
    QtKey_Left,
    QtKey_Up,
    QtKey_Right,
    QtKey_Down,
    QtKey_Select,
    QtKey_Printer,
    QtKey_Execute,
    QtKey_Print,
    QtKey_Insert,
    QtKey_Delete,
    QtKey_Help,
    QtKey_0,
    QtKey_1,
    QtKey_2,
    QtKey_3,
    QtKey_4,
    QtKey_5,
    QtKey_6,
    QtKey_7,
    QtKey_8,
    QtKey_9,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_A,
    QtKey_B,
    QtKey_C,
    QtKey_D,
    QtKey_E,
    QtKey_F,
    QtKey_G,
    QtKey_H,
    QtKey_I,
    QtKey_J,
    QtKey_K,
    QtKey_L,
    QtKey_M,
    QtKey_N,
    QtKey_O,
    QtKey_P,
    QtKey_Q,
    QtKey_R,
    QtKey_S,
    QtKey_T,
    QtKey_U,
    QtKey_V,
    QtKey_W,
    QtKey_X,
    QtKey_Y,
    QtKey_Z,
    QtKey_Meta,
    QtKey_Meta,
    QtKey_Menu,
    QtKey_unknown,
    QtKey_Sleep,
    QtKey_0,
    QtKey_1,
    QtKey_2,
    QtKey_3,
    QtKey_4,
    QtKey_5,
    QtKey_6,
    QtKey_7,
    QtKey_8,
    QtKey_9,
    QtKey_Asterisk,
    QtKey_Plus,
    QtKey_Comma,
    QtKey_Minus,
    QtKey_Period,
    QtKey_Slash,
    QtKey_F1,
    QtKey_F2,
    QtKey_F3,
    QtKey_F4,
    QtKey_F5,
    QtKey_F6,
    QtKey_F7,
    QtKey_F8,
    QtKey_F9,
    QtKey_F10,
    QtKey_F11,
    QtKey_F12,
    QtKey_F13,
    QtKey_F14,
    QtKey_F15,
    QtKey_F16,
    QtKey_F17,
    QtKey_F18,
    QtKey_F19,
    QtKey_F20,
    QtKey_F21,
    QtKey_F22,
    QtKey_F23,
    QtKey_F24,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_NumLock,
    QtKey_ScrollLock,
    QtKey_unknown,
    QtKey_Massyo,
    QtKey_Touroku,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Shift,
    QtKey_Shift,
    QtKey_Control,
    QtKey_Control,
    QtKey_Alt,
    QtKey_Alt,
    QtKey_Back,
    QtKey_Forward,
    QtKey_Refresh,
    QtKey_Stop,
    QtKey_Search,
    QtKey_Favorites,
    QtKey_HomePage,
    QtKey_VolumeMute,
    QtKey_VolumeDown,
    QtKey_VolumeUp,
    QtKey_MediaNext,
    QtKey_MediaPrevious,
    QtKey_MediaStop,
    QtKey_MediaPlay,
    QtKey_LaunchMail,
    QtKey_LaunchMedia,
    QtKey_Launch0,
    QtKey_Launch1,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Plus,
    QtKey_Comma,
    QtKey_Minus,
    QtKey_Period,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Play,
    QtKey_Zoom,
    QtKey_unknown,
    QtKey_unknown,
    QtKey_Clear,
    QtKey_unknown
   );
begin
  if AKey > 255 then
    Result := QtKey_unknown
  else
    Result := VKKeyToQtKeyMap[AKey];
end;

function TQtWidget.ShiftStateToQtModifiers(Shift: TShiftState): QtModifier;
begin
  Result := 0;
  if ssCtrl  in Shift then inc(Result, QtCTRL);
  if ssShift in Shift then Inc(Result, QtSHIFT);
  if ssMeta  in Shift then Inc(Result, QtMETA);
  if ssAlt   in Shift then Inc(Result, QtALT);
end;

function TQtWidget.QueryInterface(const iid: tguid; out obj): longint; stdcall;
begin
  if GetInterface(iid, obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TQtWidget._AddRef: longint; stdcall;
begin
  Result := -1; // no ref counting
end;

function TQtWidget._Release: longint; stdcall;
begin
  Result := -1;
end;

function TQtWidget.GetProps(const AnIndex: String): pointer;
var
  i: Integer;
begin
  if (Fprops<>nil) then
  begin
    i:=Fprops.IndexOf(AnIndex);
    if i>=0 then
    begin
      result:=Fprops.Objects[i];
      exit;
    end;
  end;
  result := nil;
end;

function TQtWidget.GetContext: HDC;
begin
  Result := FContext;
end;

function TQtWidget.GetWidget: QWidgetH;
begin
  if TheObject <> nil then
    Result := QWidgetH(TheObject)
  else
    Result := nil;
end;

function TQtWidget.DeliverMessage(var Msg): LRESULT;
begin
  Result := 0;
  if LCLObject = nil then
    Exit;
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

procedure TQtWidget.SetProps(const AnIndex: String; const AValue: pointer);
var
  i: Integer;
begin
  if FProps=nil then
  begin
    FProps:=TStringList.Create;
    //FProps.CaseSensitive:=false;
    FProps.Sorted:=true;
  end;
  i := Fprops.IndexOf(AnIndex);
  if i < 0 then
    i := FProps.Add(AnIndex);
  Fprops.Objects[i] := TObject(AValue);
end;

procedure TQtWidget.SetWidget(const AValue: QWidgetH);
begin
  TheObject := AValue;
end;

function TQtWidget.CreateWidget(const Params: TCreateParams): QWidgetH;
begin
  FHasPaint := True;
  Widget := QWidget_create();
  Result := Widget;
end;

procedure TQtWidget.DestroyWidget;
begin
  if (Widget <> nil) and FOwnWidget then
    QObject_deleteLater(Widget);
  Widget := nil;
end;

{ TQtAbstractButton }

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SetColor
  Params:  QColorH
  Returns: Nothing

  Changes the color of a widget
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SetColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteButton, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtAbstractButton.setTextColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteButtonText, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtAbstractButton.setIcon(AIcon: QIconH);
begin
  QAbstractButton_setIcon(QAbstractButtonH(Widget), AIcon);
end;

procedure TQtAbstractButton.setIconSize(Size: PSize);
begin
  QAbstractButton_setIconSize(QAbstractButtonH(Widget), Size);
end;

procedure TQtAbstractButton.setShortcut(AShortcut: TShortcut);
var
  Key: Word;
  Shift: TShiftState;
  Modifiers: QtModifier;
  KeySequence: QKeySequenceH;
begin
  if AShortCut <> 0 then
  begin
    ShortCutToKey(AShortCut, Key, Shift);
    Modifiers := ShiftStateToQtModifiers(Shift);
    KeySequence := QKeySequence_create(LCLKeyToQtKey(Key) or Modifiers);
  end
  else
    KeySequence := QKeySequence_create();
  QAbstractButton_setShortcut(QAbstractButtonH(Widget), KeySequence);
  QKeySequence_destroy(KeySequence);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SetText(const W: WideString);
begin
  QAbstractButton_setText(QAbstractButtonH(Widget), @W);
end;

function TQtAbstractButton.getIconSize: TSize;
begin
  QAbstractButton_iconSize(QAbstractButtonH(Widget), @Result);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.Text
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractButton.getText: WideString;
begin
  QAbstractButton_text(QAbstractButtonH(Widget), @Result);
end;

procedure TQtAbstractButton.Toggle;
begin
  QAbstractButton_toggle(QAbstractButtonH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.isChecked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractButton.isChecked: Boolean;
begin
  Result := QAbstractButton_isChecked(QAbstractButtonH(Widget));
end;

function TQtAbstractButton.isDown: Boolean;
begin
  Result := QAbstractButton_isDown(QAbstractButtonH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.setChecked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.setChecked(p1: Boolean);
begin
  QAbstractButton_setChecked(QAbstractButtonH(Widget), p1);
end;

procedure TQtAbstractButton.setDown(p1: Boolean);
begin
  QAbstractButton_setDown(QAbstractButtonH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalPressed
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalPressed; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_KEYDOWN;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalReleased
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalReleased; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_KEYUP;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalClicked(Checked: Boolean = False); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalClicked2
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalClicked2; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CLICKED;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractButton.SignalToggled
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractButton.SignalToggled(Checked: Boolean); cdecl;
begin
 {use this for TToggleButton }
end;


{ TQtPushButton }

function TQtPushButton.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  Result := QPushButton_create();
end;

{------------------------------------------------------------------------------
  Function: TQtPushButton.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtPushButton.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtPushButton.Destroy');
  {$endif}

  if Widget <> nil then
  begin
    DetachEvents;
    QPushButton_destroy(QPushButtonH(Widget));
    Widget := nil;
  end;

  inherited Destroy;
end;

procedure TQtPushButton.preferredSize(var PreferredWidth,
  PreferredHeight: integer; WithThemeSpace: Boolean);
const
  IconSpacing: Integer = 4;
var
  W: WideString;
  AMetrics: QFontMetricsH;
  AIcon: QIconH;
  ASize: TSize;
begin
  PreferredWidth := 0;
  PreferredHeight := 0;

  // first part - text width/height calculation
  W := getText;
  if W <> '' then
  begin
    AMetrics := QFontMetrics_create(QWidget_font(Widget));
    PreferredWidth := QFontMetrics_width(AMetrics, @W, -1);
    PreferredHeight := QFontMetrics_height(AMetrics);
    {$note there's a bug with QFontMetrics_width() & QFontMetrics_height()
     on MacOSX (qt-4.3,qt-4.4)
     so we must increase PrefW & PrefH for some reasonable value.}
    {$IFDEF DARWIN}
    PreferredWidth := PreferredWidth + (PreferredWidth div 4);
    PreferredHeight := PreferredHeight + (PreferredHeight div 2);
    {$ENDIF}
    QFontMetrics_destroy(AMetrics);
  end;

  // second part - icon width/height
  AIcon := QIcon_create();
  QAbstractButton_icon(QAbstractButtonH(Widget), AIcon);
  if not QIcon_isNull(AIcon) then
  begin
    ASize := getIconSize;
    inc(PreferredWidth, ASize.cx + IconSpacing);
    PreferredHeight := Max(PreferredHeight, ASize.cy + IconSpacing);
  end;
  QIcon_destroy(AIcon);

  // third part - space between bounds and contents
  inc(PreferredWidth, 10);
  inc(PreferredHeight, 4);

  if WithThemeSpace then
  begin
    inc(PreferredWidth, 6);
    inc(PreferredHeight, 6);
  end;
end;

procedure TQtPushButton.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  
  FClickedHook := QAbstractButton_hook_create(Widget);
  QAbstractButton_clicked2_Event(Method) := @SlotClicked;
  QAbstractButton_hook_hook_clicked2(FClickedHook, Method);
end;

procedure TQtPushButton.DetachEvents;
begin
  QAbstractButton_hook_destroy(FClickedHook);
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtPushButton.SlotClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtPushButton.SlotClicked; cdecl;
var
  Msg: TLMessage;
begin
  Msg.Msg := LM_CLICKED;
  DeliverMessage(Msg);
end;

{ TQtMainWindow }

function TQtMainWindow.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  w: QWidgetH;
  p: QPaletteH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtMainWindow.CreateWidget Name: ', LCLObject.Name);
  {$endif}
  
  FHasPaint := True;
  IsMainForm := False;

  w := QApplication_activeWindow;
  if not Assigned(w) and not ((Application.MainForm <> nil) and (Application.MainForm.Visible))
  and (TCustomForm(LCLObject).FormStyle <> fsSplash) then
  begin
  
    IsMainForm := True;
    Result := QMainWindow_create(nil, QtWindow);

    {$ifdef darwin}
      if csDesigning in LCLObject.ComponentState then
        MenuBar := TQtMenuBar.Create(nil)
      else
        MenuBar := TQtMenuBar.Create(Result);
    {$else}
      MenuBar := TQtMenuBar.Create(Result);
    {$endif}
    
    if (Application.MainForm <> nil) and (Application.MainForm.FormStyle = fsMDIForm)
    and not (csDesigning in LCLObject.ComponentState) then
    begin
      FCentralWidget := QWidget_create(Result);
      MDIAreaHandle := QMdiArea_create(Result);
      p := QWidget_palette(FCentralWidget);
      if p <> nil then
        QMdiArea_setBackground(MdiAreaHandle, QPalette_background(P));
      QWidget_setParent(MdiAreaHandle, FCentralWidget);
    end
    else
    begin
      FCentralWidget := QWidget_create(Result);
      MDIAreaHandle := nil;
    end;
    
    if FCentralWidget <> nil then
      QMainWindow_setCentralWidget(QMainWindowH(Result), FCentralWidget);
    
    if not (csDesigning in LCLObject.ComponentState) then
      QMainWindow_setDockOptions(QMainWindowH(Result), QMainWindowAnimatedDocks);
  end
  else
  begin
    if IsMdiChild then
    begin

      if TQtMainWindow(Application.MainForm.Handle).MDIAreaHandle = nil then
        raise Exception.Create('MDIChild can be added to MDIForm only !');

      Result := QMdiSubWindow_create(nil, QtWindow);

      // QMdiSubWindow already have an layout

      LayoutWidget := QBoxLayoutH(QWidget_layout(Result));
      if LayoutWidget <> nil then
        QBoxLayout_destroy(LayoutWidget);
    end
    else
    begin
      if (TCustomForm(LCLObject).FormStyle = fsSplash) and
      not (csDesigning in LCLObject.ComponentState) then
        Result := QWidget_create(nil, QtSplashScreen)
      else
        Result := QWidget_create(nil, QtWindow);
      QWidget_setAttribute(Result, QtWA_Hover);
    end;

    // Main menu bar
    {$ifdef darwin}
      MenuBar := TQtMenuBar.Create(nil);
    {$else}
      MenuBar := TQtMenuBar.Create(Result);
    {$endif}

    FCentralWidget := QWidget_create(Result);
      
    LayoutWidget := QBoxLayout_create(QBoxLayoutTopToBottom, Result);

    QBoxLayout_setSpacing(LayoutWidget, 0);
    QLayout_setContentsMargins(LayoutWidget, 0, 0, 0, 0);

    {we must fix mouse events in QMDISubWindow by adding FCentralWidget as it''s widget }
    if IsMdiChild then
      QMdiSubWindow_setWidget(QMdiSubWindowH(Result), FCentralWidget);
      
    QLayout_addWidget(LayoutWidget, FCentralWidget);
    QWidget_setLayout(Result, QLayoutH(LayoutWidget));
  end;
  
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
end;

{------------------------------------------------------------------------------
  Function: TQtMainWindow.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtMainWindow.Destroy;
begin
  // The main window takes care of the menubar handle
  if MenuBar <> nil then
  begin
    MenuBar.Widget := nil;
    MenuBar.Free;
  end;

  inherited Destroy;
end;

function TQtMainWindow.getText: WideString;
begin
  WindowTitle(@Result);
end;

function TQtMainWindow.getTextStatic: Boolean;
begin
  Result := False;
end;

procedure TQtMainWindow.setText(const W: WideString);
begin
  setWindowTitle(@W);
end;

procedure TQtMainWindow.setMenuBar(AMenuBar: QMenuBarH);
begin
  if IsMainForm then
    QMainWindow_setMenuBar(QMainWindowH(Widget), AMenuBar)
  else
    QLayout_setMenuBar(LayoutWidget, AMenuBar);
end;

{------------------------------------------------------------------------------
  Function: TQtMainWindow.EventFilter
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtMainWindow.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
begin
  BeginEventProcessing;
  Result := False;

  case QEvent_type(Event) of
    QEventWindowStateChange: SlotWindowStateChange;
  else
    Result := inherited EventFilter(Sender, Event);
  end;
  EndEventProcessing;
end;

function TQtMainWindow.IsMdiChild: Boolean;
begin
  Result := (LCLObject <> nil) and not
    (csDesigning in LCLObject.ComponentState) and
    (TCustomForm(LCLObject).FormStyle = fsMDIChild);
end;

procedure TQtMainWindow.OffsetMousePos(APoint: PQtPoint);
begin
  if not IsMdiChild then
    inherited OffsetMousePos(APoint);
end;

{------------------------------------------------------------------------------
  Function: TQtMainWindow.SlotWindowStateChange
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtMainWindow.SlotWindowStateChange; cdecl;
var
  Msg: TLMSize;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtMainWindow.SlotWindowStateChange');
  {$endif}

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_SIZE;

  case QWidget_windowState(Widget) of
    QtWindowMinimized: Msg.SizeType := SIZEICONIC;
    QtWindowMaximized: Msg.SizeType := SIZEFULLSCREEN;
    QtWindowFullScreen: Msg.SizeType := SIZEFULLSCREEN;
  else
    Msg.SizeType := SIZENORMAL;
  end;

  Msg.SizeType := Msg.SizeType or Size_SourceIsInterface;

  Msg.Width := getWidth;
  Msg.Height := getHeight;
  
  DeliverMessage(Msg);
end;

procedure TQtMainWindow.setShowInTaskBar(AValue: Boolean);
var
  w: QWidgetH;
  Flags: QtWindowFlags;
  Visible: Boolean;
begin
  if not AValue then
  begin
    w := TQtMainWindow(Application.MainForm.Handle).Widget;
    if w <> Widget then
    begin
      Visible := getVisible;
      Flags := windowFlags;
      setParent(w);
      setWindowFlags(Flags);
      setVisible(Visible);
    end;
  end
  else
  begin
    Visible := getVisible;
    Flags := windowFlags;
    setParent(nil);
    setWindowFlags(Flags);
    setVisible(Visible);
  end;
end;

procedure TQtMainWindow.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  if FCentralWidget <> nil then
  begin
    FCWEventHook := QObject_hook_create(FCentralWidget);
    TEventFilterMethod(Method) := @CWEventFilter;
    QObject_hook_hook_events(FCWEventHook, Method);
  end;
end;

procedure TQtMainWindow.DetachEvents;
begin
  if FCWEventHook <> nil then
  begin
    QObject_hook_destroy(FCWEventHook);
    FCWEventHook := nil;
  end;

  inherited DetachEvents;
end;

function TQtMainWindow.CWEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  R: TRect;
  R2: TRect;
  i: Integer;
begin
  Result := False;
  
  if LCLObject <> nil then
  begin
    case QEvent_type(Event) of
      QEventResize:
        begin
          LCLObject.InvalidateClientRectCache(true);
          LCLObject.DoAdjustClientRectChange;
          
          {mdi area part begins}
          if MdiAreaHandle <> nil then
          begin
            {first must get contents rect - all except main menu}
            QWidget_contentsRect(FCentralWidget, @R);
            
            {TODO: find better way to find out which controls are top,left,right & bottom aligned ...}
            for i := 0 to LCLObject.ComponentCount - 1 do
            begin
            
              {find statusbars}
              if LCLObject.Components[i] is TStatusBar then
              begin
                R2 := TWinControl(LCLObject.Components[i]).ClientRect;
                case TWinControl(LCLObject.Components[i]).Align of
                  alLeft: R.Left := R.Left + (R2.Right - R2.Left);
                  alTop: R.Top := R.Top + (R2.Bottom - R2.Top);
                  alRight: R.Right := R.Right - (R2.Right - R2.Left);
                  alBottom: R.Bottom := R.Bottom - (R2.Bottom - R2.Top);
                end;
              end;
              
              {find toolbars}
              if LCLObject.Components[i] is TToolBar then
              begin
                R2 := TWinControl(LCLObject.Components[i]).ClientRect;
                case TWinControl(LCLObject.Components[i]).Align of
                  alLeft: R.Left := R.Left + (R2.Right - R2.Left);
                  alTop: R.Top := R.Top + (R2.Bottom - R2.Top);
                  alRight: R.Right := R.Right - (R2.Right - R2.Left);
                  alBottom: R.Bottom := R.Bottom - (R2.Bottom - R2.Top);
                end;
              end;
              
            end; {components loop}
            
            QWidget_setGeometry(MDIAreaHandle, @R);
          end;
          {mdi area part end}
          
        end;
    end;
  end;
end;

{ TQtStaticText }

function TQtStaticText.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtStaticText.Create');
  {$endif}

  Result := QLabel_create();
  QWidget_setAutoFillBackground(Result, True);
end;

{------------------------------------------------------------------------------
  Function: TQtStaticText.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtStaticText.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtStaticText.Destroy');
  {$endif}

  if Widget <> nil then
  begin
    DetachEvents;
    QLabel_destroy(QLabelH(Widget));
    Widget := nil;
  end;

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Function: TQtStaticText.SetText
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtStaticText.SetText(const W: WideString);
var
  AmpersandPos: Integer;
  LocalW: WideString;
begin
  LocalW := W;
  if TCustomStaticText(LCLObject).ShowAccelChar then
  begin
    // replace '&' by underline
    AmpersandPos := Pos('&', W);
    if AmpersandPos > 0 then
    begin
      LocalW := Copy(W, 1, AmpersandPos - 1) + '<u>';
      if AmpersandPos < Length(W) then
        LocalW := LocalW + W[AmpersandPos + 1];
      LocalW := LocalW + '</u>' + Copy(W, AmpersandPos + 2, Length(W));
    end;
  end;
  QLabel_setText(QLabelH(Widget), @LocalW);
end;

procedure TQtStaticText.setAlignment(const AAlignment: QtAlignment);
begin
  QLabel_setAlignment(QLabelH(Widget), AAlignment);
end;

{------------------------------------------------------------------------------
  Function: TQtStaticText.Text
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtStaticText.getText: WideString;
begin
  QLabel_text(QLabelH(Widget), @Result);
end;

{ TQtCheckBox }

function TQtCheckBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtCheckBox.Create');
  {$endif}
  
  Result := QCheckBox_create;
end;

{------------------------------------------------------------------------------
  Function: TQtCheckBox.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtCheckBox.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtCheckBox.Destroy');
  {$endif}

  if Widget <> nil then
  begin
    DetachEvents;
    QCheckBox_destroy(QCheckBoxH(Widget));
    Widget := nil;
  end;

  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Function: TQtCheckBox.CheckState
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtCheckBox.CheckState: QtCheckState;
begin
  Result := QCheckBox_checkState(QCheckBoxH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtCheckBox.setCheckState
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtCheckBox.setCheckState(state: QtCheckState);
begin
  QCheckBox_setCheckState(QCheckBoxH(Widget), state);
end;

procedure TQtCheckBox.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FStateChangedHook := QCheckBox_hook_create(Widget);
  QCheckBox_stateChanged_Event(Method) := @SignalStateChanged;
  QCheckBox_hook_hook_stateChanged(FStateChangedHook, Method);
end;

procedure TQtCheckBox.DetachEvents;
begin
  QCheckBox_hook_destroy(FStateChangedHook);
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtCheckBox.signalStateChanged
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtCheckBox.signalStateChanged(p1: Integer); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  DeliverMessage(Msg);
end;

{ TQtRadioButton }

function TQtRadioButton.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtRadioButton.Create');
  {$endif}

  Result := QRadioButton_create();
  // hide widget by default
  QWidget_hide(Result);
end;

{------------------------------------------------------------------------------
  Function: TQtRadioButton.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtRadioButton.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtRadioButton.Destroy');
  {$endif}

  if Widget <> nil then
  begin
    DetachEvents;
    QRadioButton_destroy(QRadioButtonH(Widget));
    Widget := nil;
  end;

  inherited Destroy;
end;

procedure TQtRadioButton.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FClickedHook := QAbstractButton_hook_create(Widget);
  
  QAbstractButton_clicked_Event(Method) := @SignalClicked;
  QAbstractButton_hook_hook_clicked(FClickedHook, Method);
end;

procedure TQtRadioButton.DetachEvents;
begin
  QAbstractButton_hook_destroy(FClickedHook);
  inherited DetachEvents;
end;

{ TQtGroupBox }

function TQtGroupBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
var
  Layout: QBoxLayoutH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtGroupBox.Create ');
  {$endif}
  FHasPaint := True;
  Result := QGroupBox_create();
  FCentralWidget := QWidget_create(Result, 0);
  Layout := QVBoxLayout_create(Result);
  QLayout_addWidget(Layout, FCentralWidget);
  QLayout_setSpacing(Layout, 0);
  QLayout_setMargin(Layout, 0);
  QWidget_setLayout(Result, QLayoutH(Layout));
end;

{------------------------------------------------------------------------------
  Function: TQtGroupBox.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtGroupBox.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtGroupBox.Destroy');
  {$endif}

  if Widget <> nil then
  begin
    DetachEvents;
    QGroupBox_destroy(QGroupBoxH(Widget));
    Widget := nil;
  end;

  inherited Destroy;
end;

function TQtGroupBox.getText: WideString;
begin
  QGroupBox_title(QGroupBoxH(Widget), @Result);
end;

procedure TQtGroupBox.setText(const W: WideString);
begin
  QGroupBox_setTitle(QGroupBoxH(Widget), @W);
end;

{ TQtFrame }

function TQtFrame.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtFrame.Create');
  {$endif}
  FHasPaint := True;
  Result := QFrame_create();
  QWidget_setAutoFillBackground(Result, True);
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
end;

{------------------------------------------------------------------------------
  Function: TQtFrame.setFrameStyle
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtFrame.setFrameStyle(p1: Integer);
begin
  QFrame_setFrameStyle(QFrameH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtFrame.setFrameShape
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtFrame.setFrameShape(p1: QFrameShape);
begin
  QFrame_setFrameShape(QFrameH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtFrame.setFrameShadow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtFrame.setFrameShadow(p1: QFrameShadow);
begin
  QFrame_setFrameShadow(QFrameH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtFrame.setTextColor
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtFrame.setTextColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteWindowText, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtArrow.CreateWidget
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtArrow.CreateWidget(const AParams: TCreateParams):QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtArrow.Create');
  {$endif}
  FHasPaint := True;
  Result := QFrame_create();
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
end;

function TQtAbstractSlider.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSlider.Create');
  {$endif}
  
  FSliderPressed := False;
  FSliderReleased:= False;

  Result := QAbstractSlider_create();
end;

procedure TQtAbstractSlider.AttachEvents;
begin
  inherited AttachEvents;
  FRangeChangedHook := QAbstractSlider_hook_create(Widget);
  FSliderMovedHook :=  QAbstractSlider_hook_create(Widget);
  FSliderPressedHook := QAbstractSlider_hook_create(Widget);
  FSliderReleasedHook := QAbstractSlider_hook_create(Widget);
  FValueChangedHook := QAbstractSlider_hook_create(Widget);
end;

procedure TQtAbstractSlider.DetachEvents;
begin
  QAbstractSlider_hook_destroy(FRangeChangedHook);
  QAbstractSlider_hook_destroy(FSliderMovedHook);
  QAbstractSlider_hook_destroy(FSliderPressedHook);
  QAbstractSlider_hook_destroy(FSliderReleasedHook);
  QAbstractSlider_hook_destroy(FValueChangedHook);
  inherited DetachEvents;
end;

function TQtAbstractSlider.getValue: Integer;
begin
  Result := QAbstractSlider_value(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getPageStep: Integer;
begin
  Result := QAbstractSlider_pageStep(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getMin: Integer;
begin
  Result := QAbstractSlider_minimum(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getMax: Integer;
begin
  Result := QAbstractSlider_maximum(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getSingleStep: Integer;
begin
  Result := QAbstractSlider_singleStep(QAbstractSliderH(Widget));
end;

function TQtAbstractSlider.getSliderPosition: Integer;
begin
  Result := QAbstractSlider_sliderPosition(QAbstractSliderH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.rangeChanged
  Params:  minimum,maximum: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.SlotRangeChanged(minimum: Integer; maximum: Integer); cdecl;
begin
  { TODO: find out what needs to be done on rangeChanged event
    Possibilities: repaint or recount pageSize() }
 {$ifdef VerboseQt}
  writeln('TQtAbstractSlider.rangeChanged() to min=',minimum,' max=',maximum);
 {$endif}
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setInvertedAppereance
  Params:  p1: Boolean
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setInvertedAppereance(p1: Boolean);
begin
  QAbstractSlider_setInvertedAppearance(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setInvertedControls
  Params:  p1: Boolean
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setInvertedControls(p1: Boolean);
begin
  QAbstractSlider_setInvertedControls(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setMaximum
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setMaximum(p1: Integer);
begin
  QAbstractSlider_setMaximum(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setMinimum
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setMinimum(p1: Integer);
begin
  QAbstractSlider_setMinimum(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setOrientation
  Params:  p1: QtOrientation (QtHorizontal or QtVertical)
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setOrientation(p1: QtOrientation);
begin
  QAbstractSlider_setOrientation(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setPageStep
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setPageStep(p1: Integer);
begin
  QAbstractSlider_setPageStep(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setRange
  Params:  minimum,maximum: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setRange(minimum: Integer; maximum: Integer);
begin
  QAbstractSlider_setRange(QAbstractSliderH(Widget), minimum, maximum);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setSingleStep
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setSingleStep(p1: Integer);
begin
  QAbstractSlider_setSingleStep(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setSliderDown
  Params:  p1: Boolean
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setSliderDown(p1: Boolean);
begin
  QAbstractSlider_setSliderDown(QAbstractSliderH(Widget), p1);
end;


{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setSliderPosition
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setSliderPosition(p1: Integer);
begin
  QAbstractSlider_setSliderPosition(QAbstractSliderH(Widget), p1);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractSlider.setTracking
  Params:  p1: Boolean
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setTracking(p1: Boolean);
begin
  QAbstractSlider_setTracking(QAbstractSliderH(Widget), p1);
end;

{-----------------------------------------------------------------------------
  Function: TQtAbstractSlider.setValue
  Params:  p1: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractSlider.setValue(p1: Integer);
begin
  QAbstractSlider_setValue(QAbstractSliderH(Widget), p1);
end;

procedure TQtAbstractSlider.SlotSliderMoved(p1: Integer); cdecl;
var
  LMScroll: TLMScroll;
begin
 {$ifdef VerboseQt}
  writeln('TQtAbstractSlider.sliderMoved() to pos=',p1);
 {$endif}
 
  FillChar(LMScroll, SizeOf(LMScroll), #0);

  LMScroll.ScrollBar := PtrUInt(Self);
   
  if QAbstractSlider_orientation(QAbstractSliderH(Widget)) = QtHorizontal then
    LMScroll.Msg := LM_HSCROLL
  else
    LMScroll.Msg := LM_VSCROLL;

  LMScroll.Pos := p1;
  LMScroll.ScrollCode := SIF_POS; { SIF_TRACKPOS }

  DeliverMessage(LMScroll);
end;

procedure TQtAbstractSlider.SlotSliderPressed; cdecl;
begin
  {$ifdef VerboseQt}
   writeln('TQtAbstractSlider.sliderPressed()');
  {$endif}
  FSliderPressed := True;
  FSliderReleased := False;
end;

procedure TQtAbstractSlider.SlotSliderReleased; cdecl;
begin
  {$ifdef VerboseQt}
   writeln('TQtAbstractSlider.sliderReleased()');
  {$endif}
  FSliderPressed := False;
  FSliderReleased := True;
end;

function TQtAbstractSlider.getOrientation: QtOrientation;
begin
  Result := QAbstractSlider_orientation(QAbstractSliderH(Widget));
end;

procedure TQtAbstractSlider.SlotValueChanged(p1: Integer); cdecl;
var
  LMScroll: TLMScroll;
begin
  {$ifdef VerboseQt}
  writeln('TQtAbstractSlider.SlotValueChanged() to value ',p1);
 {$endif}
 
  FillChar(LMScroll, SizeOf(LMScroll), #0);

  LMScroll.ScrollBar := PtrUInt(Self);

  if QAbstractSlider_orientation(QAbstractSliderH(Widget)) = QtHorizontal then
    LMScroll.Msg := LM_HSCROLL
  else
    LMScroll.Msg := LM_VSCROLL;
  
  LMScroll.Pos := p1;
  LMScroll.ScrollCode := SIF_POS;

  if not SliderPressed then
    DeliverMessage(LMScroll);
end;


{ TQtScrollBar }

function TQtScrollBar.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtScrollBar.Create');
  {$endif}
  FRealParentCtl := nil;
  Result := QScrollBar_create();
  FHasPaint := True;
end;

function TQtScrollBar.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
var
  QtWidget: TQtWidget;
  AParent: TWinControl;
begin
  beginEventProcessing;

  {fixes #11601 -
   TODO: Real qt apps behaviour: when we click onto scrollbar
   it focuses control eg. treeview (if it isn't focused yet)
   but seem that we cannot get it via LCL.
   For now we use FRealParentCtl variable to get around this !
  }
  if QWidget_focusProxy(QWidgetH(Sender)) = nil then
  begin
    if not (csDesigning in LCLObject.ComponentState) then
    begin
      AParent := LCLObject.Parent;
      if Assigned(AParent) then
      begin
        if AParent.HandleAllocated then
        begin
          QtWidget := TQtWidget(AParent.Handle);
          if Assigned(QtWidget) and (QtWidget.Widget <> nil) then
          begin
            while Assigned(AParent.Parent) do
            begin
              AParent := AParent.Parent;
              QtWidget := TQtWidget(AParent.Handle);
            end;
            if (QtWidget <> nil) and Assigned(AParent) then
              QWidget_setFocusProxy(QWidgetH(Sender), QtWidget.Widget);
          end;
        end;
      end;
    end;
  end;

  case QEvent_type(Event) of
    {if any of those events returs TRUE our scrollbar becomes invisible.}
    QEventMouseButtonPress,
    QEventMouseButtonRelease,
    QEventMouseButtonDblClick:
    begin
      if (FRealParentCtl <> nil)
      and (FRealParentCtl.CanFocus)
      and not FRealParentCtl.Focused then
        FRealParentCtl.SetFocus;
      Result := False;
    end;
    QEventMouseMove,
    QEventWheel,
    QEventPaint,
    QEventKeyPress,
    QEventKeyRelease: Result := False;
  else
    if FOwnWidget then
      Result := inherited EventFilter(Sender, Event);
  end;
  endEventProcessing;
end;

procedure TQtScrollBar.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  QAbstractSlider_rangeChanged_Event(Method) := @SlotRangeChanged;
  QAbstractSlider_hook_hook_rangeChanged(FRangeChangedHook, Method);

  QAbstractSlider_sliderMoved_Event(Method) := @SlotSliderMoved;
  QAbstractSlider_hook_hook_sliderMoved(FSliderMovedHook, Method);

  QAbstractSlider_sliderPressed_Event(Method) := @SlotSliderPressed;
  QAbstractSlider_hook_hook_sliderPressed(FSliderPressedHook, Method);

  QAbstractSlider_sliderReleased_Event(Method) := @SlotSliderReleased;
  QAbstractSlider_hook_hook_sliderReleased(FSliderReleasedHook, Method);

  QAbstractSlider_valueChanged_Event(Method) := @SlotValueChanged;
  QAbstractSlider_hook_hook_valueChanged(FValueChangedHook, Method);
end;

{ TQtToolBar }

function TQtToolBar.CreateWidget(const AParams: TCreateParams):QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtToolBar.Create');
  {$endif}
  Result := QToolBar_create();
end;

{ TQtToolButton }

function TQtToolButton.CreateWidget(const AParams: TCreateParams):QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtToolButton.Create');
  {$endif}
  Result := QToolButton_create();
end;

{ TQtTrackBar }

function TQtTrackBar.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTrackBar.Create');
  {$endif}
  Result := QSlider_create();
end;

function TQtTrackBar.getTickInterval: Integer;
begin
  Result := QSlider_tickInterval(QSliderH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtTrackBar.setTickPosition
  Params:  Value: QSliderTickPosition
  Returns: Nothing
 ------------------------------------------------------------------------------ }
procedure TQtTrackBar.setTickPosition(Value: QSliderTickPosition);
begin
  QSlider_setTickPosition(QSliderH(Widget), Value);
end;

{------------------------------------------------------------------------------
  Function: TQtTrackBar.setTickInterval
  Params:  Value: Integer
  Returns: Nothing
 ------------------------------------------------------------------------------ }
procedure TQtTrackBar.SetTickInterval(Value: Integer);
begin
  QSlider_setTickInterval(QSliderH(Widget), Value);
end;

procedure TQtTrackBar.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  
  QAbstractSlider_sliderMoved_Event(Method) := @SlotSliderMoved;
  QAbstractSlider_hook_hook_sliderMoved(FSliderMovedHook, Method);

  QAbstractSlider_sliderPressed_Event(Method) := @SlotSliderPressed;
  QAbstractSlider_hook_hook_sliderPressed(FSliderPressedHook, Method);

  QAbstractSlider_sliderReleased_Event(Method) := @SlotSliderReleased;
  QAbstractSlider_hook_hook_sliderReleased(FSliderReleasedHook, Method);

  QAbstractSlider_valueChanged_Event(Method) := @SlotValueChanged;
  QAbstractSlider_hook_hook_valueChanged(FValueChangedHook, Method);
end;

procedure TQtTrackBar.SlotSliderMoved(p1: Integer); cdecl;
var
  Msg: TLMessage;
begin
 {$ifdef VerboseQt}
  writeln('TQtTrackBar.SlotSliderMoved()');
 {$endif}
  if (TTrackBar(LCLObject).Position <> p1) and not InUpdate then
  begin
    FillChar(Msg, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    DeliverMessage(Msg);
  end;
end;

procedure TQtTrackBar.SlotValueChanged(p1: Integer); cdecl;
var
  Msg: TLMessage;
begin
 {$ifdef VerboseQt}
  writeln('TQtTrackBar.SlotValueChanged()');
 {$endif}

  if not SliderPressed and (TTrackBar(LCLObject).Position <> p1) and not InUpdate then
  begin
    FillChar(Msg, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    DeliverMessage(Msg);
  end;
end;

{ TQtLineEdit }

function TQtLineEdit.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  Result := QLineEdit_create();
end;

function TQtLineEdit.getCursorPosition: Integer;
begin
  Result := QLineEdit_cursorPosition(QLineEditH(Widget));
end;

function TQtLineEdit.getMaxLength: Integer;
begin
  Result := QLineEdit_maxLength(QLineEditH(Widget));
end;

function TQtLineEdit.getSelectedText: WideString;
begin
  QLineEdit_selectedText(QLineEditH(Widget), @Result);
end;

function TQtLineEdit.getSelectionStart: Integer;
begin
  if hasSelectedText then
    Result := QLineEdit_selectionStart(QLineEditH(Widget))
  else
    Result := getCursorPosition;
end;

function TQtLineEdit.getSelectionLength: Integer;
var
  W: WideString;
begin
  if hasSelectedText then
  begin
    W := getSelectedText;
    Result := Length(W);
  end
  else
    Result := 0;
end;

function TQtLineEdit.getText: WideString;
begin
  QLineEdit_text(QLineEditH(Widget), @Result);
end;

function TQtLineEdit.getTextStatic: Boolean;
begin
  Result := False;
end;

function TQtLineEdit.isUndoAvailable: Boolean;
begin
  Result := QLineEdit_isUndoAvailable(QLineEditH(Widget));
end;

function TQtLineEdit.hasSelectedText: Boolean;
begin
  Result := QLineEdit_hasSelectedText(QLineEditH(Widget));
end;

procedure TQtLineEdit.selectAll;
begin
  QLineEdit_selectAll(QLineEditH(Widget));
end;

procedure TQtLineEdit.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FTextChanged := QLineEdit_hook_create(Widget);
  QLineEdit_textChanged_Event(Method) := @SignalTextChanged;
  QLineEdit_hook_hook_textChanged(FTextChanged, Method);
end;

procedure TQtLineEdit.DetachEvents;
begin
  QLineEdit_hook_destroy(FTextChanged);
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtLineEdit.EventFilter
  Params:  QObjectH, QEventH
  Returns: boolean

  Overrides TQtWidget EventFilter()
 ------------------------------------------------------------------------------}
function TQtLineEdit.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  case QEvent_type(Event) of
    QEventFocusIn:
    begin
      if not (csDesigning in LCLObject.ComponentState) then
      begin
        if QFocusEvent_reason(QFocusEventH(Event)) in
          [QtTabFocusReason,QtBacktabFocusReason,QtActiveWindowFocusReason,
           QtShortcutFocusReason, QtOtherFocusReason] then
        begin
          // it would be better if we have AutoSelect published from TCustomEdit
          // then TMaskEdit also belongs here.
          if (LCLObject is TEdit) and
             getEnabled and
             TEdit(LCLObject).AutoSelect and not
             TEdit(LCLObject).ReadOnly then
               QLineEdit_selectAll(QLineEditH(Widget));
        end;
      end;
    end;
  end;
  Result := inherited EventFilter(Sender, Event);
end;

{------------------------------------------------------------------------------
  Function: TQtLineEdit.SetColor
  Params:  QColorH
  Returns: Nothing

  Changes the color of a widget
 ------------------------------------------------------------------------------}
procedure TQtLineEdit.SetColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteBase, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtLineEdit.setTextColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteText, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtLineEdit.setCursorPosition(const AValue: Integer);
begin
  QLineEdit_setCursorPosition(QLineEditH(Widget), AValue);
end;

procedure TQtLineEdit.setEchoMode(const AMode: QLineEditEchoMode);
begin
  QLineEdit_setEchoMode(QLineEditH(Widget), AMode);
end;

procedure TQtLineEdit.setInputMask(const AMask: WideString);
begin
  QLineEdit_setInputMask(QLineEditH(Widget), @AMask);
end;

procedure TQtLineEdit.setMaxLength(const ALength: Integer);
begin
  QLineEdit_setMaxLength(QLineEditH(Widget), ALength);
end;

procedure TQtLineEdit.setReadOnly(const AReadOnly: Boolean);
begin
  QLineEdit_setReadOnly(QLineEditH(Widget), AReadOnly);
end;

procedure TQtLineEdit.setSelection(const AStart, ALength: Integer);
begin
  if AStart >= 0 then
  begin
    if ALength > 0 then
      QLineEdit_setSelection(QLineEditH(Widget), AStart, ALength)
    else
      setCursorPosition(AStart);
  end;
end;

procedure TQtLineEdit.setText(const AText: WideString);
begin
  QLineEdit_setText(QLineEditH(Widget), @AText);
end;

procedure TQtLineEdit.Undo;
begin
  QLineEdit_undo(QLineEditH(Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtLineEdit.SignalTextChanged
  Params:  PWideString
  Returns: Nothing

  Fires OnChange() event of TCustomEdit
 ------------------------------------------------------------------------------}
procedure TQtLineEdit.SignalTextChanged(p1: PWideString); cdecl;
var
   Msg: TLMessage;
begin
   FillChar(Msg, SizeOf(Msg), #0);
   Msg.Msg := CM_TEXTCHANGED;
   DeliverMessage(Msg);
end;

{ TQtTextEdit }

function TQtTextEdit.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTextEdit.Create');
  {$endif}
  Result := QTextEdit_create();
  FKeysToEat := [];
  FUndoAvailable := False;
end;

procedure TQtTextEdit.append(AStr: WideString);
begin
  QTextEdit_append(QTextEditH(Widget), @AStr);
end;

function TQtTextEdit.getMaxLength: Integer;
begin
  {$note implement}
  Result := 0;
end;

function TQtTextEdit.getText: WideString;
begin
  QTextEdit_toPlainText(QTextEditH(Widget), @Result);
end;

function TQtTextEdit.getTextStatic: Boolean;
begin
  Result := False;
end;

function TQtTextEdit.getSelectionStart: Integer;
var
  TextCursor: QTextCursorH;
begin
  TextCursor := QTextCursor_create();
  QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
  Result := QTextCursor_selectionStart(TextCursor);
  QTextCursor_destroy(TextCursor);
end;

function TQtTextEdit.getSelectionEnd: Integer;
var
  TextCursor: QTextCursorH;
begin
  TextCursor := QTextCursor_create();
  QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
  Result := QTextCursor_selectionEnd(TextCursor);
  QTextCursor_destroy(TextCursor);
end;

function TQtTextEdit.getSelectionLength: Integer;
begin
  Result := getSelectionEnd - getSelectionStart;
end;

function TQtTextEdit.isUndoAvailable: Boolean;
begin
  Result := QTextEdit_isUndoRedoEnabled(QTextEditH(Widget)) and FUndoAvailable;
end;

{------------------------------------------------------------------------------
  Function: TQtTextEdit.SetColor
  Params:  QColorH
  Returns: Nothing

  Changes the color of a widget
 ------------------------------------------------------------------------------}
procedure TQtTextEdit.SetColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteBase, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtTextEdit.setTextColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteText, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtTextEdit.setEchoMode(const AMode: QLineEditEchoMode);
begin
  {$note implement}
end;

procedure TQtTextEdit.setLineWrapMode(const AMode: QTextEditLineWrapMode);
begin
  QTextEdit_setLineWrapMode(QTextEditH(Widget), AMode);
end;

procedure TQtTextEdit.setMaxLength(const ALength: Integer);
begin
  {$note implement}
end;

procedure TQtTextEdit.setText(const AText: WideString);
begin
  QTextEdit_setPlainText(QTextEditH(Widget), @AText);
end;

procedure TQtTextEdit.setReadOnly(const AReadOnly: Boolean);
begin
  QTextEdit_setReadOnly(QTextEditH(Widget), AReadOnly);
end;

procedure TQtTextEdit.setSelection(const AStart, ALength: Integer);
var
  TextCursor: QTextCursorH;
begin
  if AStart >= 0 then
  begin
    TextCursor := QTextCursor_create();
    QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
    QTextCursor_clearSelection(TextCursor);
    QTextCursor_setPosition(TextCursor, AStart);
    QTextCursor_setPosition(TextCursor, AStart + ALength, QTextCursorKeepAnchor);
    QTextEdit_setTextCursor(QTextEditH(Widget), TextCursor);
    QTextCursor_destroy(TextCursor);
  end;
end;

procedure TQtTextEdit.setTabChangesFocus(const AValue: Boolean);
begin
  QTextEdit_setTabChangesFocus(QTextEditH(Widget), AValue);
end;

procedure TQtTextEdit.Undo;
begin
  QTextEdit_undo(QTextEditH(Widget));
end;

procedure TQtTextEdit.SetAlignment(const AAlignment: QtAlignment);
var
  TextCursor: QTextCursorH;
begin
  // QTextEdit supports alignment for every paragraph. We need to align all text.
  // So, we should select all text, set format, and clear selection
  
  // 1. Select all text
  QTextEdit_selectAll(QTextEditH(Widget));
  
  // 2. Set format
  QTextEdit_setAlignment(QTextEditH(Widget), AAlignment);
  
  // 3. Clear selection. To unselect all document we must create new text cursor,
  // get format from Text Edit, clear selection in cursor and set it back to Text Edit
  TextCursor := QTextCursor_create();
  QTextEdit_textCursor(QTextEditH(Widget), TextCursor);
  QTextCursor_clearSelection(TextCursor);
  QTextEdit_setTextCursor(QTextEditH(Widget), TextCursor);
  QTextCursor_destroy(TextCursor);
end;

procedure TQtTextEdit.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FTextChangedHook := QTextEdit_hook_create(Widget);
  FUndoAvailableHook := QTextEdit_hook_create(Widget);

  QTextEdit_textChanged_Event(Method) := @SignalTextChanged;
  QTextEdit_hook_hook_textChanged(FTextChangedHook, Method);
  
  QTextEdit_undoAvailable_Event(Method) := @SignalUndoAvailable;
  QTextEdit_hook_hook_undoAvailable(FUndoAvailableHook, Method);

  FViewportEventHook := QObject_hook_create(QAbstractScrollArea_viewport(QTextEditH(Widget)));
  TEventFilterMethod(Method) := @viewportEventFilter;
  QObject_hook_hook_events(FViewportEventHook, Method);

end;

procedure TQtTextEdit.DetachEvents;
begin
  QObject_hook_destroy(FViewportEventHook);
  inherited DetachEvents;
  QTextEdit_hook_destroy(FTextChangedHook);
end;

function TQtTextEdit.viewportEventFilter(Sender: QObjectH; Event: QEventH
  ): Boolean; cdecl;
begin
  Result := False;
  QEvent_accept(Event);
  case QEvent_type(Event) of
    QEventContextMenu: SlotContextMenu(Sender, Event);
    QEventMouseButtonPress,
    QEventMouseButtonRelease,
    QEventMouseButtonDblClick: SlotMouse(Sender, Event);
    QEventMouseMove: SlotMouseMove(Event);
  end;
end;

function TQtTextEdit.getContextMenuPolicy: QtContextMenuPolicy;
var
  w: QWidgetH;
begin
  w := QAbstractScrollArea_viewport(QAbstractScrollAreaH(Widget));
  Result := QWidget_contextMenuPolicy(w)
end;

procedure TQtTextEdit.setContextMenuPolicy(const AValue: QtContextMenuPolicy);
var
  w: QWidgetH;
begin
  w := QAbstractScrollArea_viewport(QAbstractScrollAreaH(Widget));
  QWidget_setContextMenuPolicy(w, AValue);
end;

{------------------------------------------------------------------------------
  Function: TQtTextEdit.SignalTextChanged
  Params:  none
  Returns: Nothing

  Fires OnChange() event of TCustomMemo
 ------------------------------------------------------------------------------}
procedure TQtTextEdit.SignalTextChanged; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := CM_TEXTCHANGED;
  DeliverMessage(Msg);
end;

procedure TQtTextEdit.SignalUndoAvailable(b: Boolean); cdecl;
begin
  FUndoAvailable := b;
end;

procedure TQtTextEdit.setScrollStyle(AScrollStyle: TScrollStyle);
begin
  {$ifdef VerboseQt}
    WriteLn('TQTextEdit.setScrollStyle');
  {$endif}
  case AScrollStyle of
    ssNone:
    begin
      QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOff);
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOff);
    end;
    ssHorizontal:
    begin
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOn);
    end;
    ssVertical:
    begin
     QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOn);
    end;
    ssBoth:
    begin
      QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOn);
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOn);
    end;
    ssAutoHorizontal:
    begin
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAsNeeded);
    end;
    ssAutoVertical:
    begin
      QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAsNeeded);
    end;
    ssAutoBoth:
    begin
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAsNeeded);
      QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAsNeeded);
    end;
  end;
end;

{ TQtTabWidget }

function TQtTabWidget.getTabBar: QTabBarH;
begin
  if FTabBar = nil then
  begin
    {$note we can remove QLCLTabWidget, and get it like StackWidget,
     objectName is qt_tabwidget_tabbar.}
    FTabBar := QLCLTabWidget_tabBarHandle(QTabWidgetH(Widget));
    QWidget_setFocusPolicy(FTabBar, QtNoFocus);
  end;
  Result := FTabBar;
end;

function TQtTabWidget.getShowTabs: Boolean;
begin
  Result := QWidget_isVisible(TabBar);
end;

function TQtTabWidget.getStackWidget: QWidgetH;
var
  List: TPtrIntArray;
  Obj: QObjectH;
  i: Integer;
  WStr: WideString;
begin
  if FStackWidget = nil then
  begin
    QObject_children(Widget, @List);
    for i := 0 to High(List) do
    begin
      Obj := QObjectH(List[i]);
      QObject_objectName(Obj, @WStr);
      {do not localize !}
      if WStr = 'qt_tabwidget_stackedwidget' then
      begin
        FStackWidget := QWidgetH(List[i]);
        break;
      end;
    end;
    FCentralWidget := FStackWidget;
  end;
  Result := FStackWidget;
end;

procedure TQtTabWidget.setShowTabs(const AValue: Boolean);
begin
  QWidget_setVisible(TabBar, AValue);
end;

function TQtTabWidget.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTabWidget.Create');
  {$endif}
  Result := QTabWidget_create();
  
  {note: for some reason tabbar scroll buttons are not enabled as default option
  under mac - but under linux & win are. Qt docs says that this options is enabled
  as default ... possible qt bug}
  {$ifdef darwin}
  QTabWidget_setUsesScrollButtons(QTabWidgetH(Result), True);
  {$endif}
end;

procedure TQtTabWidget.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FCurrentChangedHook := QTabWidget_hook_create(Widget);
  FTabBarEventHook := QWidget_hook_create(TabBar);
  FTabBarChangedHook := QTabBar_hook_create(TabBar);

  QTabWidget_currentChanged_Event(Method) := @SignalCurrentChanged;
  QTabWidget_hook_hook_currentChanged(FCurrentChangedHook, Method);
  QTabBar_currentChanged_Event(Method) := @SignalTabBarCurrentChanged;
  QTabBar_hook_hook_currentChanged(FTabBarChangedHook, Method);
  TEventFilterMethod(Method) := @EventFilter;
  QObject_hook_hook_events(FTabBarEventHook, Method);
end;

procedure TQtTabWidget.DetachEvents;
begin
  QTabBar_hook_destroy(FTabBarChangedHook);
  QTabWidget_hook_destroy(FCurrentChangedHook);
  QWidget_hook_destroy(FTabBarEventHook);
  inherited DetachEvents;
end;

function TQtTabWidget.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
begin
  BeginEventProcessing;
  if (Sender = TabBar) then
  begin
    Result := False;

    QEvent_accept(Event);

    case QEvent_type(Event) of
      QEventKeyPress,
      QEventKeyRelease: SlotKey(Sender, Event);
      QEventMouseButtonPress,
      QEventMouseButtonRelease,
      QEventMouseButtonDblClick: Result := SlotTabBarMouse(Sender, Event);
    else
      QEvent_ignore(Event);
    end;
  end else
  begin
    Result := inherited EventFilter(Sender, Event);
  end;

  EndEventProcessing;
end;

{------------------------------------------------------------------------------
  Function: TQtTabWidget.insertTab
  Params:  index: Integer; page: QWidgetH; p2: PWideString
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtTabWidget.insertTab(index: Integer; page: QWidgetH; p2: WideString): Integer; overload;
begin
  Result := QTabWidget_insertTab(QTabWidgetH(Widget), index, page, @p2);
end;

{------------------------------------------------------------------------------
  Function: TQtTabWidget.insertTab
  Params:  index: Integer; page: QWidgetH; icon: QIconH; p2: PWideString
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtTabWidget.insertTab(index: Integer; page: QWidgetH; icon: QIconH; p2: WideString): Integer; overload;
begin
  if icon <> nil then
    Result := QTabWidget_insertTab(QTabWidgetH(Widget), index, page, icon, @p2)
  else
    Result := QTabWidget_insertTab(QTabWidgetH(Widget), index, page, @p2);
end;

function TQtTabWidget.getClientBounds: TRect;
begin
  QWidget_contentsRect(StackWidget, @Result)
end;

function TQtTabWidget.getCurrentIndex: Integer;
begin
  Result := QTabWidget_currentIndex(QTabWidgetH(Widget));
end;

function TQtTabWidget.getTabPosition: QTabWidgetTabPosition;
begin
  Result := QTabWidget_tabPosition(QTabWidgetH(Widget));
end;

procedure TQtTabWidget.removeTab(AIndex: Integer);
begin
  QTabWidget_removeTab(QTabWidgetH(Widget), AIndex);
end;

procedure TQtTabWidget.setCurrentIndex(AIndex: Integer);
begin
  QTabWidget_setCurrentIndex(QTabWidgetH(Widget), AIndex);
end;

procedure TQtTabWidget.setCurrentWidget(APage: TQtWidget);
begin
  QTabWidget_setCurrentWidget(QTabWidgetH(Widget), APage.Widget);
  APage.setFocus;
end;

procedure TQtTabWidget.setFocusPolicy(const APolicy: QtFocusPolicy);
begin
  QWidget_setFocusPolicy(TabBar, QtNoFocus);
end;

{------------------------------------------------------------------------------
  Function: TQtTabWidget.setTabPosition
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTabWidget.setTabPosition(ATabPosition: QTabWidgetTabPosition);
begin
  QTabWidget_setTabPosition(QTabWidgetH(Widget), ATabPosition);
end;

{------------------------------------------------------------------------------
  Function: TQtTabWidget.SignalCurrentChanged
  Params:  None
  Returns: Nothing
           Changes ActivePage of TPageControl
 ------------------------------------------------------------------------------}
procedure TQtTabWidget.SignalCurrentChanged(Index: Integer); cdecl;
var
  Msg: TLMNotify;
  Hdr: TNmHdr;
begin
  if LCLObject = nil then
    Exit;
    
  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := LM_NOTIFY;
  FillChar(Hdr, SizeOf(Hdr), 0);

  Hdr.hwndFrom := LCLObject.Handle;
  Hdr.Code := TCN_SELCHANGING;
  Hdr.idFrom := Index;
  Msg.NMHdr := @Hdr;
  Msg.Result := 0;
  DeliverMessage(Msg);
end;

procedure TQtTabWidget.SignalTabBarCurrentChanged(Index: Integer); cdecl;
var
  Msg: TLMNotify;
  Hdr: TNmHdr;
begin
  if LCLObject = nil then
    Exit;

  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := LM_NOTIFY;
  FillChar(Hdr, SizeOf(Hdr), 0);

  Hdr.hwndFrom := LCLObject.Handle;
  Hdr.Code := TCN_SELCHANGE;
  Hdr.idFrom := Index;
  Msg.NMHdr := @Hdr;
  Msg.Result := 0;
  DeliverMessage(Msg);
end;

function TQtTabWidget.SlotTabBarMouse(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  MousePos: TQtPoint;
  NewIndex, CurIndex: Integer;
  Msg: TLMNotify;
  Hdr: TNmHdr;
begin
  Result := False;
  MousePos := QMouseEvent_pos(QMouseEventH(Event))^;
  NewIndex := QTabBar_tabAt(QTabBarH(Sender), @MousePos);
  CurIndex := QTabBar_currentIndex(QTabBarH(Sender));
  if (NewIndex <> CurIndex) and (NewIndex <> -1) and (CurIndex <> -1) then
  begin
    FillChar(Msg, SizeOf(Msg), 0);
    Msg.Msg := LM_NOTIFY;
    FillChar(Hdr, SizeOf(Hdr), 0);

    Hdr.hwndFrom := LCLObject.Handle;
    Hdr.Code := TCN_SELCHANGING;
    Hdr.idFrom := CurIndex;
    Msg.NMHdr := @Hdr;
    Msg.Result := 0;
    DeliverMessage(Msg);

    if Msg.Result <> 0 then
    begin
      QEvent_accept(Event);
      Result := True;
      Exit;
    end;
  end;
  SlotMouse(Sender, Event);
end;

function TQtTabWidget.indexOf(const AWidget: QWidgetH): integer;
begin
  Result := QTabWidget_indexOf(QTabWidgetH(Widget), AWidget);
end;

procedure TQtTabWidget.setTabText(index: Integer; p2: WideString);
begin
  QTabWidget_setTabText(QTabWidgetH(Widget), index, @p2);
end;

function TQtTabWidget.tabAt(APoint: TPoint): Integer;
var
  AQtPoint: TQtPoint;
begin
  AQtPoint := QtPoint(APoint.x, APoint.y);
  Result := QTabBar_tabAt(TabBar, @AQtPoint);
end;

{ TQtComboBox }

function TQtComboBox.GetLineEdit: TQtLineEdit;
begin
  if not getEditable then
  begin
    FLineEdit := nil
  end
  else
  begin
    if FLineEdit = nil then
    begin
      FLineEdit := TQtLineEdit.CreateFrom(LCLObject, QComboBox_lineEdit(QComboBoxH(Widget)));
      QObject_disconnect(FLineEdit.Widget, '2returnPressed()', Widget, '1_q_returnPressed()');
      FLineEdit.AttachEvents;
    end;
  end;
  Result := FLineEdit;
end;

procedure TQtComboBox.SetOwnerDrawn(const AValue: Boolean);
begin
  FOwnerDrawn := AValue;
  if FDropList <> nil then
    FDropList.OwnerDrawn := FOwnerDrawn;
end;

function TQtComboBox.GetDropList: TQtListWidget;
begin
  if FDropList = nil then
  begin
    FDropList := TQtListWidget.CreateFrom(LCLObject, QListWidget_create());
    FDropList.setAttribute(QtWA_NoMousePropagation, False);
    FDropList.OwnerDrawn := OwnerDrawn;
    QComboBox_setModel(QComboBoxH(Widget), FDropList.getModel);
    QComboBox_setView(QComboBoxH(Widget), QListWidgetH(FDropList.Widget));
  end;
  Result := FDropList;
end;

function TQtComboBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtComboBox.Create');
  {$endif}
  Result := QComboBox_create();
  // disable AutoCompletion. LCL has its own
  QComboBox_setAutoCompletion(QComboboxH(Result), False);
  FLineEdit := nil;
  FOwnerDrawn := False;
end;

function TQtComboBox.getMaxLength: Integer;
begin
  if LineEdit <> nil then
    Result := LineEdit.getMaxLength
  else
    Result := 0;
end;

function TQtComboBox.getSelectionStart: Integer;
begin
  if (LineEdit <> nil) then
    Result := LineEdit.getSelectionStart
  else
    Result := 0;
end;

function TQtComboBox.getSelectionLength: Integer;
begin
  if (LineEdit <> nil) then
    Result := LineEdit.getSelectionLength
  else
    Result := 0;
end;

function TQtComboBox.isUndoAvailable: Boolean;
begin
  if LineEdit <> nil then
    Result := LineEdit.isUndoAvailable
  else
    Result := False;
end;

procedure TQtComboBox.setEchoMode(const AMode: QLineEditEchoMode);
begin
  if LineEdit <> nil then
    LineEdit.setEchoMode(AMode);
end;

procedure TQtComboBox.setMaxLength(const ALength: Integer);
begin
  if LineEdit <> nil then
    LineEdit.setMaxLength(ALength);
end;

procedure TQtComboBox.setReadOnly(const AReadOnly: Boolean);
begin
  setEditable(not AReadOnly);
end;

procedure TQtComboBox.setSelection(const AStart, ALength: Integer);
begin
  if LineEdit <> nil then
    LineEdit.setSelection(AStart, ALength);
end;

procedure TQtComboBox.Undo;
begin
  if LineEdit <> nil then
    LineEdit.Undo;
end;

{------------------------------------------------------------------------------
  Function: TQtComboBox.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtComboBox.Destroy;
begin
  FDropList.Free;
  FLineEdit.Free;
  inherited Destroy;
end;

procedure TQtComboBox.SetColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteBase, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtComboBox.setTextColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteText, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtComboBox.currentIndex
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtComboBox.currentIndex: Integer;
begin
  Result := QComboBox_currentIndex(QComboBoxH(Widget));
end;

function TQtComboBox.getEditable: Boolean;
begin
  Result := QComboBox_isEditable(QComboBoxH(Widget));
end;

function TQtComboBox.getMaxVisibleItems: Integer;
begin
  Result := QComboBox_maxVisibleItems(QComboboxH(Widget));
end;

function TQtComboBox.getText: WideString;
begin
  QComboBox_currentText(QComboBoxH(Widget), @Result);
  if FOwnerDrawn and (FLineEdit = nil) and
    (Result = '') and (Result <> FText) then
    Result := FText;
end;

function TQtComboBox.getTextStatic: Boolean;
begin
  Result := False;
end;

procedure TQtComboBox.insertItem(AIndex: Integer; AText: String);
var
  Str: WideString;
begin
  Str := GetUtf8String(AText);
  insertItem(AIndex, @Str);
end;

procedure TQtComboBox.insertItem(AIndex: Integer; AText: PWideString);
begin
  QComboBox_insertItem(QComboBoxH(WIdget), AIndex, AText, QVariant_create());
end;

{------------------------------------------------------------------------------
  Function: TQtComboBox.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtComboBox.setCurrentIndex(index: Integer);
begin
  // don't fire any events when we are changing it from the LCL side
  BeginUpdate;
  QComboBox_setCurrentIndex(QComboBoxH(Widget), index);
  EndUpdate;
end;

procedure TQtComboBox.setMaxVisibleItems(ACount: Integer);
begin
  QComboBox_setMaxVisibleItems(QComboboxH(Widget), ACount);
end;

procedure TQtComboBox.setEditable(const AValue: Boolean);
begin
  QComboBox_setEditable(QComboBoxH(Widget), AValue);
  if not AValue then
    FreeAndNil(FLineEdit)
  else
  begin
    LineEdit.setFocusPolicy(getFocusPolicy);
    setText(FText);
  end;
end;

procedure TQtComboBox.setItemText(AIndex: Integer; AText: String);
var
  Str: WideString;
  item: QListWidgetItemH;
  R: TRect;
begin
  if (AIndex >= 0) and (AIndex < QComboBox_count(QComboBoxH(Widget))) then
  begin
    Str := GetUTF8String(AText);
    QComboBox_setItemText(QComboBoxH(Widget), AIndex, @Str);
    {we must update our custom delegate}
    if (FDropList <> nil) and
       (FDropList.getVisible) and
       (FDropList.OwnerDrawn) then
    begin
      Item := QListWidget_item(QListWidgetH(FDropList.Widget), AIndex);
      if Item <> nil then
      begin
        QListWidget_visualItemRect(QListWidgetH(FDropList.Widget), @R, item);
        QWidget_update(QAbstractScrollArea_viewport(QAbstractScrollAreaH(FDropList.Widget)), @R);
      end;
    end;
  end else
    insertItem(AIndex, AText);
end;

procedure TQtComboBox.setText(const W: WideString);
begin
  if FLineEdit = nil then
    FText := W
  else
    QComboBox_setEditText(QComboBoxH(Widget), @W);
end;

procedure TQtComboBox.removeItem(AIndex: Integer);
begin
  QComboBox_removeItem(QComboBoxH(Widget), AIndex);
end;

procedure TQtComboBox.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FActivateHook := QComboBox_hook_create(Widget);
  FChangeHook := QComboBox_hook_create(Widget);
  FSelectHook := QComboBox_hook_create(Widget);

  // OnChange event if itemindex changed by mouse or kbd
  QComboBox_activated_Event(Method) := @SlotActivate;
  QComboBox_hook_hook_activated(FActivateHook, Method);
  
  // OnChange event -> fires only when text changed
  QComboBox_editTextChanged_Event(Method) := @SlotChange;
  QComboBox_hook_hook_editTextChanged(FChangeHook, Method);
  // OnSelect event
  QComboBox_currentIndexChanged_Event(Method) := @SlotSelect;
  QComboBox_hook_hook_currentIndexChanged(FSelectHook, Method);
  
  // DropList events
  FDropListEventHook := QObject_hook_create(DropList.Widget);
  TEventFilterMethod(Method) := @EventFilter;
  QObject_hook_hook_events(FDropListEventHook, Method);
end;

procedure TQtComboBox.DetachEvents;
begin
  QObject_hook_destroy(FDropListEventHook);
  QComboBox_hook_destroy(FActivateHook);
  QComboBox_hook_destroy(FChangeHook);
  QComboBox_hook_destroy(FSelectHook);

  inherited DetachEvents;
end;

procedure TQtComboBox.slotPaintCombo(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMPaint;
  AStruct: PPaintStruct;
  MsgItem: TLMDrawListItem;
  DrawStruct: TDrawListItemStruct;
  P: TPoint;
  Opt: QStyleOptionComboBoxH;
  R: TRect;
  State: QStyleState;
  CurrIndex: Integer;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtComboBox.SlotPaintCombo ', dbgsName(LCLObject));
  {$endif}
  CurrIndex := currentIndex;
  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_PAINT;
  New(AStruct);
  FillChar(AStruct^, SizeOf(TPaintStruct), 0);
  Msg.PaintStruct := AStruct;

  with PaintData do
  begin
    PaintWidget := Widget;
    ClipRegion := QPaintEvent_Region(QPaintEventH(Event));
    if ClipRect = nil then
      New(ClipRect);
    QPaintEvent_Rect(QPaintEventH(Event), ClipRect);
  end;

  Msg.DC := BeginPaint(THandle(Self), AStruct^);
  FContext := Msg.DC;

  Msg.PaintStruct^.rcPaint := PaintData.ClipRect^;
  Msg.PaintStruct^.hdc := FContext;

  P := getClientOffset;
  inc(P.X, FScrollX);
  inc(P.Y, FScrollY);
  TQtDeviceContext(Msg.DC).translate(P.X, P.Y);

  TQtDeviceContext(Msg.DC).save;
  try
    Opt := QStyleOptionComboBox_create();
    QStyleOption_initFrom(Opt, Widget);
    State := QStyleOption_state(opt);
    QStyleOption_rect(Opt, @R);
    QPainter_setClipRect(TQtDeviceContext(Msg.DC).Widget, @R);

    QStyle_drawComplexControl(QApplication_style(), QStyleCC_ComboBox, Opt,
      TQtDeviceContext(Msg.DC).Widget, Widget);
    QStyle_subControlRect(QApplication_style(), @R, QStyleCC_ComboBox, Opt,
      QStyleSC_ComboBoxEditField , Widget);
    if CurrIndex < 0 then
    begin
      QStyleOptionComboBox_setCurrentText(Opt, @FText);
      QStyle_drawControl(QApplication_style(), QStyleCE_ComboBoxLabel, opt,
        TQtDeviceContext(Msg.DC).Widget, Widget);
    end;

  finally
    QStyleOptionComboBox_destroy(Opt);
    TQtDeviceContext(Msg.DC).restore;
  end;

  inc(R.Top);
  dec(R.Bottom);
  QPainter_setClipRect(TQTDeviceContext(Msg.DC).Widget, @R);

  DrawStruct.ItemID := CurrIndex;
  DrawStruct.Area := R;
  DrawStruct.DC := Msg.DC;

  DrawStruct.ItemState := [];

  // selected
  if (State and QStyleState_Selected) <> 0 then
    Include(DrawStruct.ItemState, odSelected);
  // disabled
  if (State and QStyleState_Enabled) = 0 then
    Include(DrawStruct.ItemState, odDisabled);
  // focused (QStyleState_FocusAtBorder?)
  if ((State and QStyleState_HasFocus) <> 0) or
    ((State and QStyleState_FocusAtBorder) <> 0) then
    Include(DrawStruct.ItemState, odFocused);
  // hotlight
  if (State and QStyleState_MouseOver) <> 0 then
    Include(DrawStruct.ItemState, odHotLight);

  MsgItem.Msg := LM_DRAWLISTITEM;
  MsgItem.DrawListItemStruct := @DrawStruct;

  try
    if CurrIndex >= 0 then
      DeliverMessage(MsgItem);
  finally
    Dispose(PaintData.ClipRect);
    Fillchar(FPaintData, SizeOf(FPaintData), 0);
    FContext := 0;
    EndPaint(THandle(Self), AStruct^);
    Dispose(AStruct);
  end;
end;

function TQtComboBox.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
var
  ev: QEventH;
  str: WideString;
begin
  BeginEventProcessing;

  Result := False;
  QEvent_accept(Event);

  if (FDropList <> nil) and (Sender = FDropList.Widget) then
  begin
    case QEvent_type(Event) of
      QEventShow: SlotDropListVisibility(True);
      QEventHide:
      begin
        {we must delay SlotDropDownVisiblity according to #9574
         so order is OnChange(if editable)->OnSelect->OnCloseUp }
        ev := QEvent_create(QEventHideToParent);
        QCoreApplication_postEvent(Sender, ev);
      end;
      QEventHideToParent: SlotDropListVisibility(False);
    else
      QEvent_ignore(Event);
    end;
  end else
  begin
    case QEvent_type(Event) of
      QEventPaint:
      begin
        if FOwnerDrawn and not getEditable then
        begin
          SlotPaintCombo(Widget, Event);
          Result := True;
          QEvent_accept(Event);
        end;
      end;
      QEventFocusIn:
      begin
        if not (csDesigning in LCLObject.ComponentState) then
          if QFocusEvent_reason(QFocusEventH(Event)) in
            [QtTabFocusReason,QtBacktabFocusReason,QtActiveWindowFocusReason,
             QtShortcutFocusReason, QtOtherFocusReason] then
          begin
            if Assigned(LineEdit) and
               LineEdit.getEnabled and
               TComboBox(LCLObject).AutoSelect then
              LineEdit.selectAll;
          end;
        TCustomComboBox(LCLObject).IntfGetItems;
      end;

      QEventKeyPress,
      QEventKeyRelease:
      begin
        if (QEvent_type(Event) = QEventKeyRelease) and
        ((QKeyEvent_key(QKeyEventH(Event)) = QtKey_Return) or
        (QKeyEvent_key(QKeyEventH(Event)) = QtKey_Enter)) and
        (QKeyEvent_modifiers(QKeyEventH(Event)) = QtNoModifier) and
        (FLineEdit <> nil) and (FLineEdit.hasFocus) then
        begin
          Str := UTF8Encode(getText);
          if TCustomComboBox(LCLObject).Items.IndexOf(Str) < 0 then
            TCustomComboBox(LCLObject).AddItem(Str, nil);
        end;
      	Result := SlotKey(Sender, Event);
      end;
      else
        Result := inherited EventFilter(Sender, Event);
    end;

  end;
  
  EndEventProcessing;
end;

procedure TQtComboBox.SlotActivate(index: Integer); cdecl;
var
  Msg: TLMessage;
begin
  if InUpdate then
    Exit;

  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_ACTIVATE;
  DeliverMessage(Msg);
end;

procedure TQtComboBox.SlotChange(p1: PWideString); cdecl;
var
  Msg: TLMessage;
begin
  if InUpdate then
    Exit;
    
  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Msg := LM_CHANGED;

  DeliverMessage(Msg);
end;

procedure TQtComboBox.SlotSelect(index: Integer); cdecl;
var
  Msg: TLMessage;
begin
  if InUpdate then
    exit;

  {we must fire OnChange() if it isn''t editable
   since SlotChange() fires only for editable
   comboboxes }
  if not getEditable then
  begin
    FillChar(Msg, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    DeliverMessage(Msg);
  end;
  
  FillChar(Msg, SizeOf(Msg), #0);
  
  Msg.Msg := LM_SELCHANGE;

  DeliverMessage(Msg);
end;

procedure TQtComboBox.SlotDropListVisibility(AVisible: Boolean); cdecl;
const
  VisibilityToCodeMap: array[Boolean] of Word =
  (
    CBN_CLOSEUP,
    CBN_DROPDOWN
  );
var
  Msg : TLMCommand;
begin
  if InUpdate then
    Exit;

  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := CN_COMMAND;
  Msg.NotifyCode := VisibilityToCodeMap[AVisible];

  DeliverMessage(Msg);
end;

{ TQtAbstractSpinBox }

function TQtAbstractSpinBox.GetLineEdit: QLineEditH;
begin
  if FLineEdit = nil then
    FLineEdit := QLCLAbstractSpinBox_lineEditHandle(QAbstractSpinBoxH(Widget));
  Result := FLineEdit;
end;

function TQtAbstractSpinBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSpinBox.Create');
  {$endif}
  Result := QAbstractSpinBox_create();
end;

function TQtAbstractSpinBox.getMaxLength: Integer;
begin
  if LineEdit <> nil then
    Result := QLineEdit_maxLength(LineEdit);
end;

function TQtAbstractSpinBox.getSelectionStart: Integer;
begin
  if (LineEdit <> nil) then
  begin
    if QLineEdit_hasSelectedText(LineEdit) then
      Result := QLineEdit_selectionStart(LineEdit)
    else
      Result := QLineEdit_cursorPosition(LineEdit);
  end
  else
    Result := 0;
end;

function TQtAbstractSpinBox.getSelectionLength: Integer;
var
  W: WideString;
begin
  if (LineEdit <> nil) and QLineEdit_hasSelectedText(LineEdit) then
  begin
    QLineEdit_selectedText(LineEdit, @W);
    Result := Length(W);
  end
  else
    Result := 0;
end;

function TQtAbstractSpinBox.isUndoAvailable: Boolean;
begin
  if LineEdit <> nil then
    Result := QLineEdit_isUndoAvailable(LineEdit)
  else
    Result := False;
end;

procedure TQtAbstractSpinBox.setEchoMode(const AMode: QLineEditEchoMode);
begin
  if LineEdit <> nil then
    QLineEdit_setEchoMode(LineEdit, AMode);
end;

procedure TQtAbstractSpinBox.setMaxLength(const ALength: Integer);
begin
  if LineEdit <> nil then
    QLineEdit_setMaxLength(LineEdit, ALength);
end;

procedure TQtAbstractSpinBox.setSelection(const AStart, ALength: Integer);
begin
  if (LineEdit <> nil) and (AStart >= 0) then
  begin
    if ALength > 0 then
      QLineEdit_setSelection(LineEdit, AStart, ALength)
    else
      QLineEdit_setCursorPosition(LineEdit, AStart);
  end;
end;

procedure TQtAbstractSpinBox.Undo;
begin
  if LineEdit <> nil then
    QLineEdit_undo(LineEdit);
end;

function TQtAbstractSpinBox.getReadOnly: Boolean;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSpinBox.IsReadOnly');
  {$endif}
  Result := QAbstractSpinBox_isReadOnly(QAbstractSpinBoxH(Widget));
end;

function TQtAbstractSpinBox.getText: WideString;
begin
  if LineEdit <> nil then
    QLineEdit_text(LineEdit, @Result)
  else
    Result := '';
end;

function TQtAbstractSpinBox.getTextStatic: Boolean;
begin
  Result := False;
end;

procedure TQtAbstractSpinBox.setFocusPolicy(const APolicy: QtFocusPolicy);
begin
  inherited setFocusPolicy(APolicy);
  QWidget_setFocusPolicy(LineEdit, APolicy);
end;

procedure TQtAbstractSpinBox.setReadOnly(const r: Boolean);
begin
  QAbstractSpinBox_setReadOnly(QAbstractSpinBoxH(Widget), r);
end;

procedure TQtAbstractSpinBox.setText(const W: WideString);
begin
  if (LineEdit <> nil) then
    QLineEdit_setText(LineEdit, @W)
end;

procedure TQtAbstractSpinBox.SetColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteBase, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtAbstractSpinBox.setTextColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteText, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtAbstractSpinBox.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FEditingFinishedHook := QAbstractSpinBox_hook_create(Widget);
  {TODO: find out which TLMessage should be sended }
  QAbstractSpinBox_editingFinished_Event(Method) := @SignalEditingFinished;
  QAbstractSpinBox_hook_hook_editingFinished(FEditingFinishedHook, Method);
end;

procedure TQtAbstractSpinBox.DetachEvents;
begin
  QAbstractSpinBox_hook_destroy(FEditingFinishedHook);
  
  inherited DetachEvents;
end;

procedure TQtAbstractSpinBox.SignalEditingFinished; cdecl;
var
  Msg: TLMessage;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractSpinBox.SignalEditingFinished');
  {$endif}
  FillChar(Msg, SizeOf(Msg), #0);
  { TODO: Find out which message should be sended here
    problem:
     everything is fine when we work with mouse, or
     press TabKey to select next control, but if we
     connect OnKeyDown and say eg. VK_RETURN: SelectNext(ActiveControl, true, true)
     then spinedit text is always selected, nothing important but looks ugly.}
//  Msg.Msg := LM_EXIT;
//  DeliverMessage(Msg);
end;

{ TQtFloatSpinBox }

function TQtFloatSpinBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtFloatSpinBox.Create');
  {$endif}
  Result := QDoubleSpinBox_create();
end;

function TQtFloatSpinBox.getValue: Double;
begin
  Result := QDoubleSpinBox_value(QDoubleSpinBoxH(Widget));
end;

procedure TQtFloatSpinBox.setDecimals(const v: integer);
begin
  QDoubleSpinBox_setDecimals(QDoubleSpinBoxH(Widget), v);
end;

procedure TQtFloatSpinBox.setMinimum(const v: Double);
begin
  QDoubleSpinBox_setMinimum(QDoubleSpinBoxH(Widget), v);
end;

procedure TQtFloatSpinBox.setMaximum(const v: Double);
begin
  QDoubleSpinBox_setMaximum(QDoubleSpinBoxH(Widget), v);
end;

procedure TQtFloatSpinBox.setSingleStep(const v: Double);
begin
  QDoubleSpinBox_setSingleStep(QDoubleSpinBoxH(Widget), v);
end;

procedure TQtFloatSpinBox.setValue(const v: Double);
begin
  QDoubleSpinBox_setValue(QDoubleSpinBoxH(Widget), v);
end;

procedure TQtFloatSpinBox.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FValueChangedHook := QDoubleSpinBox_hook_create(Widget);
  QDoubleSpinBox_valueChanged_Event(Method) := @SignalValueChanged;
  QDoubleSpinBox_hook_hook_valueChanged(FValueChangedHook, Method);
end;

procedure TQtFloatSpinBox.DetachEvents;
begin
  QDoubleSpinBox_hook_destroy(FValueChangedHook);
  inherited DetachEvents;
end;

procedure TQtFloatSpinBox.SignalValueChanged(p1: Double); cdecl;
var
   Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := CM_TEXTCHANGED;
  DeliverMessage(Msg);
end;

{ TQtSpinBox }

function TQtSpinBox.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtSpinBox.Create');
  {$endif}
  Result := QSpinBox_create();
end;

function TQtSpinBox.getValue: Double;
begin
  Result := QSpinBox_value(QSpinBoxH(Widget));
end;

procedure TQtSpinBox.setMinimum(const v: Double);
begin
  QSpinBox_setMinimum(QSpinBoxH(Widget), round(v));
end;

procedure TQtSpinBox.setMaximum(const v: Double);
begin
  QSpinBox_setMaximum(QSpinBoxH(Widget), round(v));
end;

procedure TQtSpinBox.setSingleStep(const v: Double);
begin
  QSpinBox_setSingleStep(QSpinBoxH(Widget), round(v));
end;

procedure TQtSpinBox.setValue(const v: Double);
begin
  QSpinBox_setValue(QSpinBoxH(Widget), round(v));
end;

procedure TQtSpinBox.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FValueChangedHook := QSpinBox_hook_create(Widget);
  QSpinBox_valueChanged_Event(Method) := @SignalValueChanged;
  QSpinBox_hook_hook_valueChanged(FValueChangedHook, Method);
end;

procedure TQtSpinBox.DetachEvents;
begin
  QSpinBox_hook_destroy(FValueChangedHook);
  inherited DetachEvents;
end;

procedure TQtSpinBox.SignalValueChanged(p1: Integer); cdecl;
var
   Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := CM_TEXTCHANGED;
  DeliverMessage(Msg);
end;

function TQtListWidget.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  FDontPassSelChange := False;
  Result := QListWidget_create();
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
end;

procedure TQtListWidget.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  
  FSelectionChangeHook := QListWidget_hook_create(Widget);
  FCurrentItemChangeHook := QListWidget_hook_create(Widget);
  FItemDoubleClickedHook := QListWidget_hook_create(Widget);
  FItemClickedHook := QListWidget_hook_create(Widget);
  FItemTextChangedHook := QListWidget_hook_create(Widget);

  // OnSelectionChange event
  QListWidget_itemSelectionChanged_Event(Method) := @signalSelectionChanged;
  QListWidget_hook_hook_itemSelectionChanged(FSelectionChangeHook, Method);

  QListWidget_currentItemChanged_Event(Method) := @signalCurrentItemChange;
  QListWidget_hook_hook_currentItemChanged(FCurrentItemChangeHook, Method);

  QListWidget_itemDoubleClicked_Event(Method) := @signalItemDoubleClicked;
  QListWidget_hook_hook_ItemDoubleClicked(FItemDoubleClickedHook, Method);

  QListWidget_itemClicked_Event(Method) := @signalItemClicked;
  QListWidget_hook_hook_ItemClicked(FItemClickedHook, Method);

  QListWidget_currentTextChanged_Event(Method) := @signalItemTextChanged;
  QListWidget_hook_hook_currentTextChanged(FItemTextChangedHook, Method);
end;

procedure TQtListWidget.DetachEvents;
begin
  QListWidget_hook_destroy(FSelectionChangeHook);
  QListWidget_hook_destroy(FCurrentItemChangeHook);
  QListWidget_hook_destroy(FItemDoubleClickedHook);
  QListWidget_hook_destroy(FItemClickedHook);
  QListWidget_hook_destroy(FItemTextChangedHook);

  inherited DetachEvents;
end;

function TQtListWidget.itemViewViewportEventFilter(Sender: QObjectH;
  Event: QEventH): Boolean; cdecl;
var
  NewEvent: QMouseEventH;
begin
  Result := False;
  QEvent_accept(Event);
  if (LCLObject <> nil) then
  begin
    case QEvent_type(Event) of
      QEventMouseButtonPress,
      QEventMouseButtonRelease,
      QEventMouseButtonDblClick:
      begin
        {$note possible qt bug with QListView mouse events !}
        if (QEvent_type(Event) = QEventMouseButtonRelease) then
        begin
          if QEvent_spontaneous(Event) then
            SlotMouse(Sender, Event)
          else
          begin
            {we sent non spontaneous event below so kill it}
            Result := True;
            QEvent_ignore(Event);
          end;
        end else
          SlotMouse(Sender, Event);

        {listwidget item never sends an QEventMouseButtonRelease,
         i'll check this with trolltech. zeljko}
        if (QEvent_type(Event) = QEventMouseButtonPress) and
          (QEvent_spontaneous(Event)) then
        begin
          {create missing mouse release}
          NewEvent := QMouseEvent_create(QEventMouseButtonRelease, QMouseEvent_pos(QMouseEventH(Event)),
            QMouseEvent_globalpos(QMouseEventH(Event)),QMouseEvent_button(QMouseEventH(Event)),
            QMouseEvent_buttons(QMouseEventH(Event)),QApplication_keyboardModifiers());
          {post event with high priority}
          QCoreApplication_postEvent(Sender, NewEvent, 1);
        end        ;
      end;
    end;
  end;
end;

procedure TQtListWidget.signalCurrentItemChange(current: QListWidgetItemH;
  previous: QListWidgetItemH); cdecl;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtListWidget.signalCurrentItemChange ');
  {$endif}
  if (previous = nil) and (current <> nil) and not QListWidgetItem_isSelected(current) then
    QListWidgetItem_setSelected(current, True);
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.SlotSelectionChange
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}

procedure TQtListWidget.signalSelectionChanged(); cdecl;
var
  Msg: TLMessage;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtListWidget.signalSelectionChange');
  {$endif}

  if FDontPassSelChange then
  begin
    FDontPassSelChange := False;
    Exit;
  end;

  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_SELCHANGE;
  if QListWidget_currentItem(QListWidgetH(Widget)) <> nil then
    DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.SignalItemDoubleClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtListWidget.signalItemDoubleClicked(item: QListWidgetItemH); cdecl;
begin
  {does nothing at this time wait more featured LCL implementation
   eg. OnItemDoubleClick}
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.SignalItemClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtListWidget.signalItemClicked(item: QListWidgetItemH); cdecl;
begin
  {does nothing at this time wait more featured LCL implementation
   eg. OnItemClick}
end;

procedure TQtListWidget.signalItemTextChanged(ANewText: PWideString); cdecl;
var
  Msg: TLMessage;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtListWidget.signalItemTextChanged');
  {$endif}
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := CM_TEXTCHANGED;
  DeliverMessage(Msg);
end;

procedure TQtListWidget.ItemDelegatePaint(painter: QPainterH;
  option: QStyleOptionViewItemH; index: QModelIndexH); cdecl;
var
  Msg: TLMDrawListItem;
  DrawStruct: TDrawListItemStruct;
  State: QStyleState;
begin
  QPainter_save(painter);
  State := QStyleOption_state(option);
  DrawStruct.ItemID := QModelIndex_row(index);

  DrawStruct.Area := visualRect(index);
  DrawStruct.DC := HDC(TQtDeviceContext.CreateFromPainter(painter));

  DrawStruct.ItemState := [];
  // selected
  if (State and QStyleState_Selected) <> 0 then
    Include(DrawStruct.ItemState, odSelected);
  // disabled
  if (State and QStyleState_Enabled) = 0 then
    Include(DrawStruct.ItemState, odDisabled);
  // focused (QStyleState_FocusAtBorder?)
  if (State and QStyleState_HasFocus) <> 0 then
    Include(DrawStruct.ItemState, odFocused);
  // hotlight
  if (State and QStyleState_MouseOver) <> 0 then
    Include(DrawStruct.ItemState, odHotLight);

  { todo: over states:
  
    odGrayed, odChecked,
    odDefault, odInactive, odNoAccel,
    odNoFocusRect, odReserved1, odReserved2, odComboBoxEdit,
    odPainted
  }
  Msg.Msg := LM_DRAWLISTITEM;
  Msg.DrawListItemStruct := @DrawStruct;
  DeliverMessage(Msg);

  QPainter_restore(painter);
  
  TQtDeviceContext(DrawStruct.DC).Free;
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.currentRow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtListWidget.currentRow: Integer;
begin
  Result := QListWidget_currentRow(QListWidgetH(Widget));
end;

function TQtListWidget.IndexAt(APoint: PQtPoint): Integer;
var
  AModelIndex: QModelIndexH;
begin
  AModelIndex := QModelIndex_create();
  QListView_indexAt(QListWidgetH(Widget), AModelIndex, APoint);
  Result := QModelIndex_row(AModelIndex);
  QModelIndex_destroy(AModelIndex);
end;

procedure TQtListWidget.insertItem(AIndex: Integer; AText: String);
var
  Str: WideString;
begin
  Str := GetUtf8String(AText);
  insertItem(AIndex, @Str);
end;

procedure TQtListWidget.insertItem(AIndex: Integer; AText: PWideString);
var
  Item: QListWidgetItemH;
begin
  Item := QListWidgetItem_create(AText, nil, 0);
  if LCLObject is TCustomCheckListBox then
    QListWidgetItem_setCheckState(Item, QtUnChecked);
  QListWidget_insertItem(QListWidgetH(Widget), AIndex, Item);
end;

{------------------------------------------------------------------------------
  Function: TQtListWidget.setCurrentRow
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtListWidget.setCurrentRow(row: Integer);
begin
  if (getSelectionMode <> QAbstractItemViewSingleSelection) and (row < 0) then
    row := 0;

  if QListWidget_currentRow(QListWidgetH(Widget)) <> row then
  begin
    FDontPassSelChange := True;
    QListWidget_setCurrentRow(QListWidgetH(Widget), row);
  end;
end;

procedure TQtListWidget.setItemText(AIndex: Integer; AText: String);
var
  Item: QListWidgetItemH;
  Str: WideString;
  R: TRect;
begin
  Str := GetUTF8String(AText);
  if (AIndex >= 0) and (AIndex < QListWidget_count(QListWidgetH(Widget))) then
  begin
    Item := QListWidget_item(QListWidgetH(Widget), AIndex);
    QListWidgetItem_setText(Item, @Str);
    {we must update our custom delegate}
    if OwnerDrawn then
    begin
      QListWidget_visualItemRect(QListWidgetH(Widget), @R, item);
      QWidget_update(QAbstractScrollArea_viewport(QAbstractScrollAreaH(Widget)), @R);
    end;
  end else
    insertItem(AIndex, @Str);
end;

procedure TQtListWidget.scrollToItem(row: integer;
  hint: QAbstractItemViewScrollHint);
var
  Item: QListWidgetItemH;
begin
  Item := QListWidget_item(QListWidgetH(Widget), row);
  QListWidget_scrollToItem(QListWidgetH(Widget), Item, hint);
end;

procedure TQtListWidget.removeItem(AIndex: Integer);
var
  Item: QListWidgetItemH;
begin
  if (currentRow = AIndex) then
    if (getSelectionMode = QAbstractItemViewSingleSelection) then
      setCurrentRow(-1);
  Item := QListWidget_takeitem(QListWidgetH(Widget), AIndex);
  QListWidgetItem_destroy(Item);
end;

procedure TQtListWidget.exchangeItems(AIndex1, AIndex2: Integer);
var
  Item1, Item2: QListWidgetItemH;
  R: TRect;
begin
  if AIndex1 = AIndex2 then
    exit;

  if (currentRow = AIndex1) or (currentRow = AIndex2) then
    if (getSelectionMode = QAbstractItemViewSingleSelection) then
      setCurrentRow(-1);

  if AIndex1 < AIndex2 then
  begin
    Item1 := QListWidget_takeItem(QListWidgetH(Widget), AIndex1);
    Item2 := QListWidget_takeItem(QListWidgetH(Widget), AIndex2 - 1);
    QListWidget_insertItem(QListWidgetH(Widget), AIndex1, Item2);
    QListWidget_insertItem(QListWidgetH(Widget), AIndex2, Item1);
  end else
  begin
    Item1 := QListWidget_takeItem(QListWidgetH(Widget), AIndex2);
    Item2 := QListWidget_takeItem(QListWidgetH(Widget), AIndex1 - 1);
    QListWidget_insertItem(QListWidgetH(Widget), AIndex2, Item2);
    QListWidget_insertItem(QListWidgetH(Widget), AIndex1, Item1);
  end;
  if OwnerDrawn then
  begin
    QListWidget_visualItemRect(QListWidgetH(Widget), @R, Item1);
    QWidget_update(QAbstractScrollArea_viewport(QAbstractScrollAreaH(Widget)), @R);
    QListWidget_visualItemRect(QListWidgetH(Widget), @R, Item2);
    QWidget_update(QAbstractScrollArea_viewport(QAbstractScrollAreaH(Widget)), @R);
  end;
end;

  { TQtHeaderView }

function TQtHeaderView.getClickable: Boolean;
begin
  Result := QHeaderView_isClickable(QHeaderViewH(Widget));
end;


function TQtHeaderView.getMinSectionSize: Integer;
begin
  Result := QHeaderView_minimumSectionSize(QHeaderViewH(Widget));
end;

procedure TQtHeaderView.setClickable(const AValue: Boolean);
begin
  QHeaderView_setClickable(QHeaderViewH(Widget), AValue);
end;

procedure TQtHeaderView.setMinSectionSize(const AValue: Integer);
begin
  QHeaderView_setMinimumSectionSize(QHeaderViewH(Widget), AValue);
end;

{------------------------------------------------------------------------------
  Function: TQtHeaderView.CreateWidget
  Params:  None
  Returns: Widget (QHeaderViewH)
 ------------------------------------------------------------------------------}
function TQtHeaderView.CreateWidget(const AParams: TCreateParams):QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtHeaderView.Create');
  {$endif}
  Result := QHeaderView_create(QtHorizontal);
end;

procedure TQtHeaderView.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FSelectionClicked := QHeaderView_hook_create(Widget);
  QHeaderView_sectionClicked_Event(Method) := @SignalSectionClicked;
  QHeaderView_hook_hook_sectionClicked(FSelectionClicked, Method);
end;

procedure TQtHeaderView.DetachEvents;
begin
  QHeaderView_hook_destroy(FSelectionClicked);
  inherited DetachEvents;
end;

{------------------------------------------------------------------------------
  Function: TQtHeaderView.SignalSectionClicked
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtHeaderView.SignalSectionClicked(logicalIndex: Integer) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin
  {$ifdef VerboseQt}
  writeln('TQtHeaderView.signalSectionClicked index ',logicalIndex);
  {$endif}
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);
  
  Msg.Msg := CN_NOTIFY;
  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_COLUMNCLICK;
  NMLV.iItem := -1;
  NMLV.iSubItem := logicalIndex;
  
  Msg.NMHdr := @NMLV.hdr;
  
  DeliverMessage(Msg);
  
end;

function TQtHeaderView.getResizeMode(AIndex: Integer): QHeaderViewResizeMode;
begin
  Result := QHeaderView_resizeMode(QHeaderViewH(Widget), AIndex);
end;

procedure TQtHeaderView.setResizeMode(AResizeMode: QHeaderViewResizeMode);
begin
  QHeaderView_setResizeMode(QHeaderViewH(Widget), AResizeMode);
end;

procedure TQtHeaderView.setResizeMode(AIndex: Integer;
  AResizeMode: QHeaderViewResizeMode);
begin
  QHeaderView_setResizeMode(QHeaderViewH(Widget), AIndex, AResizeMode);
end;

procedure TQtHeaderView.moveSection(AFromIndex: Integer; AToIndex: Integer);
begin
  QHeaderView_moveSection(QHeaderViewH(Widget), AFromIndex, AToIndex);
end;

procedure TQtHeaderView.resizeSection(ASection: Integer; ASize: Integer);
begin
  QHeaderView_resizeSection(QHeaderViewH(Widget), ASection, ASize);
end;

procedure TQtHeaderView.setHighlightSections(AValue: Boolean);
begin
  QHeaderView_setHighlightSections(QHeaderViewH(Widget), AValue);
end;

procedure TQtHeaderView.setDefaultSectionSize(AValue: Integer);
begin
  QHeaderView_setDefaultSectionSize(QHeaderViewH(Widget), AValue);
end;

procedure TQtHeaderView.setStretchLastSection(AValue: Boolean);
begin
  QHeaderView_setStretchLastSection(QHeaderViewH(Widget), AValue);
end;

function TQtHeaderView.sortIndicatorOrder: QtSortOrder;
begin
  Result := QHeaderView_sortIndicatorOrder(QHeaderViewH(Widget));
end;

  { TQtTreeView }

function TQtTreeView.getColVisible(AIndex: Integer): Boolean;
begin
  Result := not QTreeView_isColumnHidden(QTreeViewH(Widget), AIndex);
end;

function TQtTreeView.getColWidth(AIndex: Integer): Integer;
begin
  Result := QTreeView_columnWidth(QTreeViewH(Widget), AIndex);
end;

procedure TQtTreeView.setColVisible(AIndex: Integer; const AValue: Boolean);
begin
  QTreeView_setColumnHidden(QTreeViewH(Widget), AIndex, not AValue);
end;

procedure TQtTreeView.setColWidth(AIndex: Integer; const AValue: Integer);
begin
  QTreeView_setColumnWidth(QTreeViewH(Widget), AIndex, AValue);
end;

procedure TQtTreeView.setWordWrap(AValue: Boolean);
begin
  QTreeView_setWordWrap(QTreeViewH(Widget), AValue);
end;

procedure TQtTreeView.setRootIsDecorated(AValue: Boolean);
begin
  QTreeView_setRootIsDecorated(QTreeViewH(Widget), AValue);
end;

procedure TQtTreeView.setAllColumnsShowFocus(AValue: Boolean);
begin
  QTreeView_setAllColumnsShowFocus(QTreeViewH(Widget), AValue);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeView.CreateWidget
  Params:  None
  Returns: Widget (QTreeViewH)
 ------------------------------------------------------------------------------}
function TQtTreeView.CreateWidget(const AParams: TCreateParams):QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTreeView.Create');
  {$endif}
  Result := QTreeView_create();
end;

  { TQtTreeWidget }

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.CreateWidget
  Params:  None
  Returns: Widget (QTreeWidgetH)
 ------------------------------------------------------------------------------}
function TQtTreeWidget.CreateWidget(const AParams: TCreateParams):QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtTreeWidget.Create');
  {$endif}
  Result := QTreeWidget_create();
  FHeader := nil;
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtTreeWidget.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtTreeWidget.Destroy');
  {$endif}

  if Assigned(FHeader) then
    FHeader.Free;

  inherited Destroy;
end;

function TQtTreeWidget.getHeader: TQtHeaderView;
var
  Method: TMethod;
begin
  {while designing TQtHeaderView is a no-no}
  if not (csDesigning in LCLObject.ComponentState) and (FHeader = nil) then
  begin
    FHeader := TQtHeaderView.CreateFrom(LCLObject, QTreeView_header(QTreeViewH(Widget)));
    FHeaderEventFilterHook := QObject_hook_create(FHeader.Widget);
    TEventFilterMethod(Method) := @headerViewEventFilter;
    QObject_hook_hook_events(FHeaderEventFilterHook, Method);

    FSectionClicked := QHeaderView_hook_create(FHeader.Widget);
    QHeaderView_sectionClicked_Event(Method) := @FHeader.SignalSectionClicked;
    QHeaderView_hook_hook_sectionClicked(FSectionClicked, Method);
  end;
  Result := FHeader;
end;

function TQtTreeWidget.getMaxColSize(ACol: Integer): Integer;
begin
  {$note QSizeH implementation missing for this}
  Result := MAXINT -1;
end;

function TQtTreeWidget.getMinColSize(ACol: Integer): Integer;
begin
  {$note QSizeH implementation missing for this}
  Result := 0;
end;

function TQtTreeWidget.getSortEnabled: Boolean;
begin
  Result := QTreeWidget_isSortingEnabled(QTreeWidgetH(Widget));
end;

function TQtTreeWidget.getColCount: Integer;
begin
  Result := QTreeWidget_columnCount(QTreeWidgetH(Widget));
end;

procedure TQtTreeWidget.setColCount(const AValue: Integer);
begin
  QTreeWidget_setColumnCount(QTreeWidgetH(Widget), AValue);
end;

procedure TQtTreeWidget.setMaxColSize(ACol: Integer; const AValue: Integer);
begin
  {$note QSizeH implementation missing for this}
end;

procedure TQtTreeWidget.setMinColSize(ACol: Integer; const AValue: Integer);
begin
  // QTreeWidgetItem_setSizeHint(headerItem, @Size, ACol);
  {$note QSizeH implementation missing for this}
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.setSortEnabled
  Params:  Boolean
  Returns: Nothing
  Enables sorting of items.
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.setSortEnabled(const AValue: Boolean);
begin
  QTreeWidget_setSortingEnabled(QTreeWidgetH(Widget), AValue);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.CurrentRow
  Params:  None
  Returns: Integer
 ------------------------------------------------------------------------------}
function TQtTreeWidget.currentRow: Integer;
var
  TWI: QTreeWidgetItemH;
begin
  TWI := QTreeWidget_currentItem(QTreeWidgetH(Widget));
  Result := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), TWI);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.setCurrentRow
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.setCurrentRow(row: Integer);
var
  TWI: QTreeWidgetItemH;
begin
  TWI := QTreeWidget_topLevelItem(QTreeWidgetH(Widget), Row);
  QTreeWidget_setCurrentItem(QTreeWidgetH(Widget), TWI);
end;

function TQtTreeWidget.currentItem: QTreeWidgetItemH;
begin
  Result := QTreeWidget_currentItem(QTreeWidgetH(Widget));
end;

procedure TQtTreeWidget.setCurrentItem(AItem: QTreeWidgetItemH);
begin
  QTreeWidget_setCurrentItem(QTreeWidgetH(Widget), AItem);
end;

function TQtTreeWidget.headerItem: QTreeWidgetItemH;
begin
  Result := QTreeWidget_headerItem(QTreeWidgetH(Widget));
end;

function TQtTreeWidget.itemAt(APoint: TPoint): QTreeWidgetItemH;
begin
  Result := QTreeWidget_itemAt(QTreeWidgetH(Widget), APoint.x, APoint.y);
end;

function TQtTreeWidget.itemAt(x: Integer; y: Integer): QTreeWidgetItemH;
begin
  Result := QTreeWidget_itemAt(QTreeWidgetH(Widget), x, y);
end;

function TQtTreeWidget.indexOfTopLevelItem(AItem: QTreeWidgetItemH): Integer;
begin
  Result := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), AItem);
end;

procedure TQtTreeWidget.insertTopLevelItem(AIndex: Integer;
  AItem: QTreeWidgetItemH);
begin
  QTreeWidget_insertTopLevelItem(QTreeWidgetH(Widget), AIndex, AItem);
end;

function TQtTreeWidget.takeTopLevelItem(AIndex: Integer): QTreeWidgetItemH;
begin
  Result := QTreeWidget_takeTopLevelItem(QTreeWidgetH(Widget), AIndex);
end;

function TQtTreeWidget.topLevelItem(AIndex: Integer): QTreeWidgetItemH;
begin
  Result := QTreeWidget_topLevelItem(QTreeWidgetH(Widget), AIndex);
end;

function TQtTreeWidget.visualItemRect(AItem: QTreeWidgetItemH): TRect;
var
  ItemRect: TRect;
begin
  QTreeWidget_visualItemRect(QTreeWidgetH(Widget), @ItemRect, AItem);
  Result := ItemRect;
end;

function TQtTreeWidget.getItemVisible(AItem: QTreeWidgetItemH): Boolean;
begin
  Result := not QTreeWidget_isItemHidden(QTreeWidgetH(Widget), AItem);
end;

procedure TQtTreeWidget.setItemVisible(AItem: QTreeWidgetItemH;
  const AVisible: Boolean);
begin
  QTreeWidget_setItemHidden(QTreeWidgetH(Widget), AItem, not AVisible);
end;

function TQtTreeWidget.selCount: Integer;
var
  FPInts: TPtrIntArray;
begin
  QTreeWidget_selectedItems(QTreeWidgetH(Widget), @FPInts);
  Result := length(FPInts);
end;

function TQtTreeWidget.selectedItems: TPtrIntArray;
begin
  QTreeWidget_selectedItems(QTreeWidgetH(Widget), @Result);
end;

procedure TQtTreeWidget.setHeaderVisible(AVisible: Boolean);
begin
  if (csDesigning in LCLObject.ComponentState) then
    {$IFDEF USE_QT_44}
    QTreeView_setHeaderHidden(QTreeViewH(Widget), not AVisible)
    {$ELSE}
    QWidget_setVisible(QTreeView_header(QTreeViewH(Widget)), AVisible)
    {$ENDIF}
  else
    Header.setVisible(AVisible);
end;

procedure TQtTreeWidget.setItemSelected(AItem: QTreeWidgetItemH;
  ASelect: Boolean);
begin
  QTreeWidget_setItemSelected(QTreeWidgetH(Widget), AItem, ASelect);
end;

procedure TQtTreeWidget.sortItems(Acolumn: Integer; AOrder: QtSortOrder);
begin
  QTreeWidget_sortItems(QTreeWidgetH(Widget), AColumn, AOrder);
end;

procedure TQtTreeWidget.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FCurrentItemChangedHook := QTreeWidget_hook_create(Widget);
  FItemDoubleClickedHook := QTreeWidget_hook_create(Widget);
  FItemClickedHook := QTreeWidget_hook_create(Widget);
  FItemActivatedHook := QTreeWidget_hook_create(Widget);
  FItemChangedHook := QTreeWidget_hook_create(Widget);
  FItemSelectionChangedHook := QTreeWidget_hook_create(Widget);
  FItemPressedHook := QTreeWidget_hook_create(Widget);
  FItemEnteredHook := QTreeWidget_hook_create(Widget);
  
  QTreeWidget_currentItemChanged_Event(Method) := @SignalCurrentItemChanged;
  QTreeWidget_hook_hook_currentItemChanged(FCurrentItemChangedHook, Method);

  QTreeWidget_itemDoubleClicked_Event(Method) := @SignalItemDoubleClicked;
  QTreeWidget_hook_hook_ItemDoubleClicked(FItemDoubleClickedHook, Method);

  QTreeWidget_itemClicked_Event(Method) := @SignalItemClicked;
  QTreeWidget_hook_hook_ItemClicked(FItemClickedHook, Method);

  QTreeWidget_itemActivated_Event(Method) := @SignalItemActivated;
  QTreeWidget_hook_hook_ItemActivated(FItemActivatedHook, Method);

  QTreeWidget_itemChanged_Event(Method) := @SignalItemChanged;
  QTreeWidget_hook_hook_ItemChanged(FItemChangedHook, Method);

  QTreeWidget_itemSelectionChanged_Event(Method) := @SignalItemSelectionChanged;
  QTreeWidget_hook_hook_ItemSelectionChanged(FItemSelectionChangedHook, Method);

  QTreeWidget_itemPressed_Event(Method) := @SignalItemPressed;
  QTreeWidget_hook_hook_ItemPressed(FItemPressedHook, Method);

  QTreeWidget_itemEntered_Event(Method) := @SignalItemEntered;
  QTreeWidget_hook_hook_ItemEntered(FItemEnteredHook, Method);

end;

procedure TQtTreeWidget.DetachEvents;
begin
  QTreeWidget_hook_destroy(FCurrentItemChangedHook);
  QTreeWidget_hook_destroy(FItemDoubleClickedHook);
  QTreeWidget_hook_destroy(FItemClickedHook);
  QTreeWidget_hook_destroy(FItemActivatedHook);
  QTreeWidget_hook_destroy(FItemChangedHook);
  QTreeWidget_hook_destroy(FItemSelectionChangedHook);
  QTreeWidget_hook_destroy(FItemPressedHook);
  QTreeWidget_hook_destroy(FItemEnteredHook);
  if FHeaderEventFilterHook <> nil then
    QObject_hook_destroy(FHeaderEventFilterHook);
  if FSectionClicked <> nil then
    QHeaderView_hook_destroy(FSectionClicked);

  inherited DetachEvents;
end;

function TQtTreeWidget.headerViewEventFilter(Sender: QObjectH; Event: QEventH
  ): Boolean; cdecl;
begin
  {TQtTreeWidget header event filter hook}
  Result := False;
  case QEvent_type(Event) of
    QEventFocusIn:
    begin
      Result := True;
      QEvent_ignore(Event);
      QWidget_setFocus(Widget);
    end;
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemPressed
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemPressed(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := LM_PRESSED;
  
  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGED;

  NMLV.iItem := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), Item);

  NMLV.iSubItem := Column;
  NMLV.uNewState := UINT(NM_KEYDOWN);
  NMLV.uChanged := LVIS_SELECTED;

  Msg.NMHdr := @NMLV.hdr;

  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemClicked
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemClicked(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  MsgN: TLMNotify;
  NMLV: TNMListView;
  R: TRect;
  Pt: TPoint;
begin
  // we'll send also which item is clicked ... probably future
  // lcl implementation of OnItemClick.
  FillChar(MsgN, SizeOf(MsgN), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  MsgN.Msg := LM_CLICKED;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := NM_CLICK;

  NMLV.iItem := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), Item);

  NMLV.iSubItem := Column;
  NMLV.uNewState := UINT(NM_CLICK);
  NMLV.uChanged :=  LVIS_SELECTED;

  QTreeWidget_visualItemRect(QTreeWidgetH(Widget), @R, Item);

  pt.X := R.Left;
  pt.Y := R.Top;

  NMLV.ptAction := pt;

  MsgN.NMHdr := @NMLV.hdr;

  DeliverMessage(MsgN);

end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemDoubleClicked
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemDoubleClicked(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := LM_LBUTTONDBLCLK;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := NM_DBLCLK;

  NMLV.iItem := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), Item);

  NMLV.iSubItem := Column;
  NMLV.uNewState := UINT(NM_DBLCLK);
  NMLV.uChanged := LVIS_SELECTED;
  // LVIF_STATE;
  
  Msg.NMHdr := @NMLV.hdr;
  {we send dblclick over TQtAbstractItemView.itemViewViewportEventFilter }
 // DeliverMessage( Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemActivated
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemActivated(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := CN_NOTIFY;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGED;

  NMLV.iItem := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), Item);

  NMLV.iSubItem := Column;
  NMLV.uNewState := LVIS_FOCUSED;
  NMLV.uChanged := LVIF_STATE;

  Msg.NMHdr := @NMLV.hdr;

  DeliverMessage( Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemEntered
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemEntered(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_ENTER;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemChanged
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemChanged(item: QTreeWidgetItemH; column: Integer) cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemExpanded
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalitemExpanded(item: QTreeWidgetItemH) cdecl;
begin
{fixme}
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemCollapsed
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemCollapsed(item: QTreeWidgetItemH) cdecl;
begin
{fixme}
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalCurrentItemChanged
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalCurrentItemChanged(current: QTreeWidgetItemH; previous: QTreeWidgetItemH) cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
  AParent: QTreeWidgetItemH;
  ASubIndex: Integer;
begin

  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := CN_NOTIFY;

  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGING;
  
  NMLV.iItem := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), Current);

  if NMLV.iItem = -1 then
    exit;
    
	AParent := QTreeWidgetItem_parent(Current);
  
  if AParent <> nil then
    ASubIndex := QTreeWidgetItem_indexOfChild(AParent, Current)
  else
    ASubIndex := 0;
    
  NMLV.iSubItem := ASubIndex;
  NMLV.uNewState := LVIS_SELECTED;
  NMLV.uChanged := LVIF_STATE;

  Msg.NMHdr := @NMLV.hdr;
  
  if Current <> Previous then
  	DeliverMessage(Msg);
  
end;

{------------------------------------------------------------------------------
  Function: TQtTreeWidget.SignalItemSelectionChanged
  Params:  Integer
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtTreeWidget.SignalItemSelectionChanged; cdecl;
var
  Msg: TLMNotify;
  NMLV: TNMListView;
  Item: QTreeWidgetItemH;
  AParent: QTreeWidgetItemH;
  AIndex: Integer;
  ASubIndex: Integer;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  FillChar(NMLV, SizeOf(NMLV), #0);

  Msg.Msg := CN_NOTIFY;


  NMLV.hdr.hwndfrom := LCLObject.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGED;


  Item := QTreeWidget_currentItem(QTreeWidgetH(Widget));
  AIndex := QTreeWidget_indexOfTopLevelItem(QTreeWidgetH(Widget), Item);
  
  if AIndex = -1 then
    exit;
    
 	AParent := QTreeWidgetItem_parent(Item);
   
  if AParent <> nil then
    ASubIndex := QTreeWidgetItem_indexOfChild(AParent, Item)
  else
    ASubIndex := 0;

  NMLV.iItem := AIndex;
  NMLV.iSubItem := ASubIndex;
  NMLV.uNewState := LVIS_SELECTED;
  NMLV.uChanged := LVIF_STATE;


  Msg.NMHdr := @NMLV.hdr;

  DeliverMessage(Msg);
  
end;

{TQtTableView}

function TQtTableView.CreateWidget(const Params: TCreateParams): QWidgetH;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtTableView.CreateWidget');
  {$endif}
  HasPaint := False;
  Result := QTableView_create();
  QWidget_setAutoFillBackground(Result, True);
end;

function TQtTableView.verticalHeader: TQtHeaderView;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtTableView.verticalHeader');
  {$endif}
  if FVerticalHeader = nil then
    FVerticalHeader := TQtHeaderView.CreateFrom(LCLObject, QTableView_verticalHeader(QTableViewH(Widget)));
  Result := FVerticalHeader;
end;

function TQtTableView.horizontalHeader: TQtHeaderView;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtTableView.horizontalHeader');
  {$endif}
  if FHorizontalHeader = nil then
    FHorizontalHeader := TQtHeaderView.CreateFrom(LCLObject, QTableView_horizontalHeader(QTableViewH(Widget)));
  Result := FHorizontalHeader;
end;

procedure TQtTableView.setVisible(visible: Boolean);
begin
  QWidget_setVisible(Widget, visible);
end;

function TQtTableView.getGridStyle: QtPenStyle;
begin
  Result := QTableView_gridStyle(QTableViewH(Widget));
end;

procedure TQtTableView.setGridStyle(ANewStyle: QtPenStyle);
begin
  QTableView_setGridStyle(QTableViewH(Widget), ANewStyle);
end;

destructor TQtTableView.Destroy;
begin
  if FVerticalHeader <> nil then
    FVerticalHeader.Free;
  if FHorizontalHeader <> nil then
    FHorizontalHeader.Free;
  inherited Destroy;
end;

function TQtTableView.getViewPort: QWidgetH;
begin
  Result := QAbstractScrollArea_viewport(QAbstractScrollAreaH(Widget));
end;

function TQtTableView.getClientBounds: TRect;
begin
  QWidget_contentsRect(Widget, @Result);
end;

procedure TQtTableView.grabMouse;
begin
  QWidget_grabMouse(Widget);
end;


{ TQtMenu }

function TQtMenu.CreateWidget(const APrams: TCreateParams): QWidgetH;
begin
  FIcon := nil;
  Result := QMenu_create();
  FActionHandle := nil;;
end;

procedure TQtMenu.InitializeWidget;
begin
  Widget := CreateWidget(FParams);
  setProperty(Widget, 'lclwidget', Int64(PtrUInt(Self)));
end;

constructor TQtMenu.Create(const AMenuItem: TMenuItem);
var
  AParams: TCreateParams;
begin
  FillChar(AParams, SizeOf(AParams), #0);
  FMenuItem := AMenuItem;
  inherited Create(nil, AParams);
end;

destructor TQtMenu.Destroy;
begin
  if FIcon <> nil then
    QIcon_destroy(FIcon);
  inherited Destroy;
end;

procedure TQtMenu.AttachEvents;
var
  Method: TMethod;
begin
  FTriggeredHook := QAction_hook_create(ActionHandle);
  FHoveredHook := QAction_hook_create(ActionHandle);
  FAboutToHideHook := QMenu_hook_create(Widget);
  FEventHook := QObject_hook_create(Widget);

  QAction_triggered_Event(Method) := @SlotTriggered;
  QAction_hook_hook_triggered(FTriggeredHook, Method);
  TEventFilterMethod(Method) := @EventFilter;

  QAction_hovered_Event(Method) := @SlotHovered;
  QAction_hook_hook_hovered(FHoveredHook, Method);
  
  QMenu_aboutToHide_Event(Method) := @SlotAboutToHide;
  QMenu_hook_hook_aboutToHide(FAboutToHideHook, Method);

  TEventFilterMethod(Method) := @EventFilter;
  QObject_hook_hook_events(FEventHook, Method);
end;

procedure TQtMenu.DetachEvents;
begin
  if FTriggeredHook <> nil then
  begin
    QAction_hook_destroy(FTriggeredHook);
    FTriggeredHook := nil;
  end;

  if FHoveredHook <> nil then
  begin
    QAction_hook_destroy(FHoveredHook);
    FHoveredHook := nil;
  end;
  
  if FAboutToHideHook <> nil then
  begin
    QMenu_hook_destroy(FAboutToHideHook);
    FAboutToHideHook := nil;
  end;

  inherited DetachEvents;
end;

procedure TQtMenu.SlotHovered; cdecl;
begin
  FMenuItem.IntfDoSelect;
end;

procedure TQtMenu.SlotAboutToHide; cdecl;
begin
  if FMenuItem.Menu is TPopupMenu then
    QCoreApplication_postEvent(Widget, QEvent_create(LCLQt_PopupMenuClose));
end;

procedure TQtMenu.DoPopupClose;
begin
  if Assigned(TPopupMenu(FMenuItem.Menu).OnClose) then
    TPopupMenu(FMenuItem.Menu).OnClose(TPopupMenu(FMenuItem.Menu));
end;

procedure TQtMenu.SlotDestroy; cdecl;
begin
  Widget := nil;
end;

procedure TQtMenu.PopUp(pos: PQtPoint; at: QActionH);
begin
  QMenu_Popup(QMenuH(Widget), pos, at);
end;

function TQtMenu.actionHandle: QActionH;
begin
  if FActionHandle = nil then
    FActionHandle := QMenu_menuAction(QMenuH(Widget));
  Result := FActionHandle;
end;

function TQtMenu.addMenu(AMenu: QMenuH): QActionH;
begin
  setHasSubmenu(True);
  Result := QMenu_addMenu(QMenuH(Widget), AMenu);
end;

function TQtMenu.insertMenu(AIndex: Integer; AMenu: QMenuH): QActionH;
var
  actionBefore: QActionH;
begin
  setHasSubmenu(True);
  actionBefore := getActionByIndex(AIndex);
  if actionBefore <> nil then
    Result := QMenu_insertMenu(QMenuH(Widget), actionBefore, AMenu)
  else
    Result := QMenu_addMenu(QMenuH(Widget), AMenu);
end;

function TQtMenu.getVisible: Boolean;
begin
  Result := QAction_isVisible(ActionHandle);
end;

function TQtMenu.getText: WideString;
begin
  QAction_text(ActionHandle, @Result);
end;

procedure TQtMenu.setText(const W: WideString);
begin
  QAction_setText(ActionHandle, @W);
end;

procedure TQtMenu.setVisible(visible: Boolean);
begin
  QAction_setVisible(ActionHandle, visible);
end;

procedure TQtMenu.setChecked(p1: Boolean);
begin
  setCheckable(p1);

  QAction_setChecked(ActionHandle, p1);
end;

procedure TQtMenu.setCheckable(p1: Boolean);
begin
  QAction_setCheckable(ActionHandle, p1);
end;

procedure TQtMenu.setHasSubmenu(AValue: Boolean);
begin
  if AValue then
    QAction_setMenu(ActionHandle, QMenuH(Widget))
  else
    QAction_setMenu(ActionHandle, nil);
end;

procedure TQtMenu.setIcon(AIcon: QIconH);
begin
  QMenu_setIcon(QMenuH(Widget), AIcon)
end;

procedure TQtMenu.setImage(AImage: TQtImage);
begin
  if FIcon <> nil then
  begin
    QIcon_destroy(FIcon);
    FIcon := nil;
  end;

  if AImage <> nil then
    FIcon := AImage.AsIcon()
  else
    FIcon := QIcon_create();
    
  setIcon(FIcon);
end;

procedure TQtMenu.setSeparator(AValue: Boolean);
begin
  QAction_setSeparator(ActionHandle, AValue);
end;

procedure TQtMenu.setShortcut(AShortcut: TShortcut);
var
  Key: Word;
  KeySequence: QKeySequenceH;
  Shift: TShiftState;
  Modifiers: QtModifier;
begin
  if AShortCut <> 0 then
  begin
    ShortCutToKey(AShortCut, Key, Shift);
    Modifiers := ShiftStateToQtModifiers(Shift);
    // there is no need in destroying QKeySequnce
    KeySequence := QKeySequence_create(LCLKeyToQtKey(Key) or Modifiers);
  end
  else
    KeySequence := QKeySequence_create();
  QAction_setShortcut(ActionHandle, KeySequence);
  QKeySequence_destroy(KeySequence);
end;

{------------------------------------------------------------------------------
  Method: TQtMenu.SlotTriggered

  Callback for menu item click
 ------------------------------------------------------------------------------}
procedure TQtMenu.SlotTriggered(checked: Boolean); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), 0);
  Msg.msg := LM_ACTIVATE;
  if Assigned(FMenuItem) then
    FMenuItem.Dispatch(Msg);
end;

function TQtMenu.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  BeginEventProcessing;
  Result := False;

  case QEvent_type(Event) of
    LCLQt_PopupMenuClose:
      begin
        DoPopupClose;
        Result := True;
      end;
    QEventDestroy: SlotDestroy;
  end;
  EndEventProcessing;
end;

{ TQtMenuBar }

constructor TQtMenuBar.Create(const AParent: QWidgetH);
begin
  Create;
  Widget := QMenuBar_create(AParent);
  FHeight := getHeight;
  FVisible := False;
  setVisible(FVisible);
end;

function TQtMenuBar.addMenu(AMenu: QMenuH): QActionH;
begin
  if not FVisible then
  begin
    FVisible := True;
    setVisible(FVisible);
  end;
  Result := QMenuBar_addMenu(QMenuBarH(Widget), AMenu);
end;

function TQtMenuBar.insertMenu(AIndex: Integer; AMenu: QMenuH): QActionH;
var
  actionBefore: QActionH;
begin
  if not FVisible then
  begin
    FVisible := True;
    setVisible(FVisible);
  end;
  actionBefore := getActionByIndex(AIndex);
  if actionBefore <> nil then
    Result := QMenuBar_insertMenu(QMenuBarH(Widget), actionBefore, AMenu)
  else
    Result := QMenuBar_addMenu(QMenuBarH(Widget), AMenu);
end;

function TQtMenuBar.getGeometry: TRect;
begin
  Result := inherited getGeometry;
  if Result.Bottom = 0 then
  begin
    Result.Bottom := FHeight; // workaround since after attaching menu it takes 0 height
  end;
end;

{ TQtProgressBar }

function TQtProgressBar.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQProgressBar.Create');
  {$endif}
  Result := QProgressBar_create();
end;

procedure TQtProgressBar.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FValueChangedHook := QProgressBar_hook_create(Widget);
  QProgressBar_valueChanged_Event(Method) := @SignalValueChanged;
  QProgressBar_hook_hook_valueChanged(FValueChangedHook, Method);
end;

procedure TQtProgressBar.DetachEvents;
begin
  QProgressBar_hook_destroy(FValueChangedHook);
  inherited DetachEvents;
end;

procedure TQtProgressBar.setRange(minimum: Integer; maximum: Integer);
begin
  QProgressBar_setRange(QProgressBarH(Widget), minimum, maximum);
end;

procedure TQtProgressBar.setTextVisible(visible: Boolean);
begin
  QProgressBar_setTextVisible(QProgressBarH(Widget), visible);
end;

procedure TQtProgressBar.setAlignment(const AAlignment: QtAlignment);
begin
  QProgressBar_setAlignment(QProgressBarH(Widget), AAlignment);
end;

procedure TQtProgressBar.setTextDirection(textDirection: QProgressBarDirection);
begin
  QProgressBar_setTextDirection(QProgressBarH(Widget), textDirection);
end;

procedure TQtProgressBar.setValue(value: Integer);
begin
  QProgressBar_setValue(QProgressBarH(Widget), value);
end;

procedure TQtProgressBar.setOrientation(p1: QtOrientation);
begin
  QProgressBar_setOrientation(QProgressBarH(Widget), p1);
end;

procedure TQtProgressBar.setInvertedAppearance(invert: Boolean);
begin
  QProgressBar_setInvertedAppearance(QProgressBarH(Widget), invert);
end;

procedure TQtProgressBar.SignalValueChanged(Value: Integer); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  DeliverMessage(Msg);
end;

{ TQtStatusBar }

function TQtStatusBar.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  SetLength(Panels, 0);
  Result := QStatusBar_create();
  QWidget_setAutoFillBackground(Result, True);
  Widget := Result;
end;

procedure TQtStatusBar.showMessage(text: PWideString; timeout: Integer);
begin
  QStatusBar_showMessage(QStatusBarH(Widget), text, timeout);
end;

procedure TQtStatusBar.addWidget(AWidget: QWidgetH; AStretch: Integer = 0);
begin
  QStatusBar_addWidget(QStatusBarH(Widget), AWidget, AStretch);
end;

function TQtStatusBar.isSizeGripEnabled: Boolean;
begin
  Result := QStatusBar_isSizeGripEnabled(QStatusBarH(Widget));
end;

procedure TQtStatusBar.setSizeGripEnabled(const Value: Boolean);
begin
  QStatusBar_setSizeGripEnabled(QStatusBarH(Widget), Value);
end;

{ TQtDialog }

function TQtDialog.CreateWidget(parent: QWidgetH; f: QtWindowFlags): QWidgetH;
begin
  Result := QDialog_create(parent, f);
end;

constructor TQtDialog.Create(ADialog: TCommonDialog; parent: QWidgetH; f: QtWindowFlags);
begin
  FDialog := ADialog;
  Widget := CreateWidget(parent, f);
end;

procedure TQtDialog.AttachEvents;
begin
  inherited AttachEvents;
end;

procedure TQtDialog.DetachEvents;
begin
  inherited DetachEvents;
end;

function TQtDialog.DeliverMessage(var Msg): LRESULT;
begin
  try
    if FDialog.HandleAllocated then
    begin
      FDialog.Dispatch(TLMessage(Msg));
      Result := TLMessage(Msg).Result;
    end else
      Result := 0;
  except
    Application.HandleException(nil);
  end;
end;

function TQtDialog.SlotClose: Boolean; cdecl;
begin
  Result := True;
  FDialog.DoCanClose(Result);
end;

function TQtDialog.exec: Integer;
begin
  Result := QDialog_exec(QDialogH(Widget));
end;

procedure TQtDialog.setSizeGripEnabled(const AEnabled: Boolean);
begin
  QDialog_setSizeGripEnabled(QDialogH(Widget), AEnabled);
end;

{ TQtViewPort }

function TQtViewPort.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  case QEvent_type(Event) of
    QEventWheel: Result := False;
    QEventResize:
    begin
      Result := False;
      LCLObject.InvalidateClientRectCache(True);
      LCLObject.DoAdjustClientRectChange;
    end;
    QEventLayoutRequest:
    begin
      {TODO: something here  (maybe) }
       Result := False;
    end;
  else
    Result := inherited EventFilter(Sender, Event);
  end;
end;

{ TQtAbstractScrollArea }

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.CreateWidget
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractScrollArea.CreateWidget(const AParams: TCreateParams):QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtAbstractScrollArea.Create');
  {$endif}
  FHasPaint := True;
  FViewPortWidget := nil;
  Result := QLCLAbstractScrollArea_create();
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
  QWidget_setAttribute(Result, QtWA_InputMethodEnabled);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.Destroy
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
destructor TQtAbstractScrollArea.Destroy;
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.Destroy');
  {$endif}
  viewportDelete;
  FreeAndNil(FHScrollBar);
  FreeAndNil(FVScrollBar);

  inherited Destroy;
end;

function TQtAbstractScrollArea.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  if (QEvent_type(Event) in [
                            QEventPaint,
                            QEventMouseButtonPress,
                            QEventMouseButtonRelease,
                            QEventMouseButtonDblClick,
                            QEventWheel,
                            QEventContextMenu
                           ]) and
     (ClassType = TQtAbstractScrollArea) then
    Result := False
  else
    Result := inherited EventFilter(Sender, Event);
end;

procedure TQtAbstractScrollArea.ViewPortEventFilter(event: QEventH; retval: PBoolean); cdecl;
begin
  {$ifdef VerboseViewPortEventFilter}
    WriteLn('ViewPortEventFilter ',QEvent_type(Event));
  {$endif}
  
  QEvent_accept(Event);

  case QEvent_type(Event) of
    QEventResize,
    QEventMouseButtonPress,
    QEventMouseButtonRelease,
    QEventMouseButtonDblClick,
    QEventPaint:
    begin
      retval^ := True;
      viewport.EventFilter(viewport.Widget, Event);
      QEvent_ignore(Event);
    end;
  else
    retval^ := QLCLAbstractScrollArea_InheritedViewportEvent(QLCLAbstractScrollAreaH(Widget), event);
  end;
end;

procedure TQtAbstractScrollArea.DestroyNotify(AWidget: TQtWidget);
begin
  if AWidget = FCornerWidget then
    FCornerWidget := nil;

  if AWidget = FViewPortWidget then
    FViewPortWidget := nil;

  if AWidget = FHScrollbar then
    FHScrollbar := nil;

  if AWidget = FVScrollbar then
    FVScrollbar := nil;

  inherited DestroyNotify(AWidget);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.cornerWidget
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractScrollArea.cornerWidget: TQtWidget;
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.cornerWidget');
  {$endif}
  Result := FCornerWidget;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setColor
  Params:  TQtWidget
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(viewport.Widget));
  try
    QPalette_setColor(Palette, QPaletteWindow, Value);
    QWidget_setPalette(viewport.Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setCornerWidget
  Params:  TQtWidget
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setCornerWidget(AWidget: TQtWidget);
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.setCornerWidget');
  {$endif}
  FCornerWidget := AWidget;
  if Assigned(FCornerWidget) then
    QAbstractScrollArea_setCornerWidget(QAbstractScrollAreaH(Widget), FCornerWidget.Widget)
  else
    QAbstractScrollArea_setCornerWidget(QAbstractScrollAreaH(Widget), NiL);
end;

procedure TQtAbstractScrollArea.setCursor(const ACursor: QCursorH);
begin
  if (LCLObject is TCustomControl) and HasPaint then
    viewport.setCursor(ACursor)
  else
    inherited setCursor(ACursor);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setTextColor
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setTextColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(viewport.Widget));
  try
    QPalette_setColor(Palette, QPaletteWindowText, Value);
    QWidget_setPalette(viewport.Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtAbstractScrollArea.setViewport(const AViewPort: QWidgetH);
begin
  QAbstractScrollArea_setViewport(QAbstractScrollAreaH(Widget), AViewPort);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setHorizontalScrollbar
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setHorizontalScrollBar(AScrollBar: TQtScrollBar);
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.setHorizontalScrollBar');
  {$endif}
  FHScrollbar := AScrollBar;
  if Assigned(FHScrollBar) then
    QAbstractScrollArea_setHorizontalScrollBar(QAbstractScrollAreaH(Widget), QScrollBarH(FHScrollBar.Widget));
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setVerticalScrollbar
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setVerticalScrollBar(AScrollBar: TQtScrollBar);
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.setVerticalScrollBar');
  {$endif}
  FVScrollBar := AScrollBar;
  if Assigned(FVScrollBar) then
    QAbstractScrollArea_setVerticalScrollBar(QAbstractScrollAreaH(Widget), QScrollBarH(FVScrollBar.Widget));
end;

procedure TQtAbstractScrollArea.setVisible(visible: Boolean);
begin
  inherited setVisible(visible);
  if FViewPortWidget <> nil then
    FViewPortWidget.setVisible(visible);
end;

procedure TQtAbstractScrollArea.Update(ARect: PRect);
var
  P: TPoint;
begin
  if ARect <> nil then
  begin
    P := getClientOffset;
    OffsetRect(ARect^, -P.X , -P.Y);
    QWidget_update(viewport.Widget, ARect);
  end else
    QWidget_update(viewport.Widget);
end;

procedure TQtAbstractScrollArea.Repaint(ARect: PRect);
var
  P: TPoint;
begin
  if ARect <> nil then
  begin
    P := getClientOffset;
    OffsetRect(ARect^, -P.X , -P.Y);
    QWidget_repaint(viewport.Widget, ARect);
  end else
    QWidget_repaint(viewport.Widget);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.horizontalScrollbar
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractScrollArea.horizontalScrollBar: TQtScrollBar;
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.horizontalScrollBar');
  {$endif}
  if FHScrollBar = nil then
  begin
    FHScrollBar := TQtScrollBar.CreateFrom(LCLObject, QAbstractScrollArea_horizontalScrollBar(QAbstractScrollAreaH(Widget)));
    FHScrollBar.AttachEvents;
    FHScrollBar.FRealParentCtl := LCLObject;
  end;
  Result := FHScrollBar;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.verticalScrollbar
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtAbstractScrollArea.verticalScrollBar: TQtScrollBar;
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.verticalScrollBar');
  {$endif}
  if FVScrollBar = nil then
  begin
    FVScrollbar := TQtScrollBar.CreateFrom(LCLObject, QAbstractScrollArea_verticalScrollBar(QAbstractScrollAreaH(Widget)));;
    FVScrollbar.AttachEvents;
    FVScrollBar.FRealParentCtl := LCLObject;
  end;
  Result := FVScrollBar;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.viewport
  Params:  None
  Returns: viewport widget of QAbstractScrollArea
 ------------------------------------------------------------------------------}
function TQtAbstractScrollArea.viewport: TQtViewport;
begin
  viewportNeeded;
  Result := FViewPortWidget;
end;

function TQtAbstractScrollArea.GetContainerWidget: QWidgetH;
begin
  if ClassType = TQtAbstractScrollArea then
    Result := viewport.Widget
  else
    Result := Widget;
end;

function TQtAbstractScrollArea.getClientOffset: TPoint;
begin
  with getClientBounds do
    Result := Point(Left, Top);
end;

function TQtAbstractScrollArea.getClientBounds: TRect;
begin
  QWidget_contentsRect(Widget, @Result);

  if (verticalScrollBar.getVisible) then
    dec(Result.Right, verticalScrollBar.getWidth);

  if (horizontalScrollBar.getVisible) then
    dec(Result.Bottom, horizontalScrollBar.getHeight);
end;

procedure TQtAbstractScrollArea.grabMouse;
begin
  if LCLObject is TCustomControl then
    viewport.grabMouse
  else
    inherited grabMouse;
end;

procedure TQtAbstractScrollArea.preferredSize(var PreferredWidth,
  PreferredHeight: integer; WithThemeSpace: Boolean);
begin
  if LCLObject is TCustomControl then
  begin
    PreferredWidth := 0;
    PreferredHeight := 0;
  end else
    inherited preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.viewportNeeded
  Params:  None
  Returns: Nothing
           Creates viewport widget for QAbstractScrollArea
 ------------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.viewportNeeded;
var
  AParams: TCreateParams;
  Method: TMethod;
begin
  if FViewPortWidget <> niL then
    exit;
  FillChar(AParams, SizeOf(AParams), #0);
  FViewPortWidget := TQtViewPort.Create(LCLObject, AParams);
  FViewPortWidget.setFocusProxy(Widget);
  FViewPortWidget.setBackgroundRole(QPaletteNoRole);
  FViewPortWidget.setAutoFillBackground(False);
  FViewPortWidget.FOwner := Self;
  FViewPortWidget.AttachEvents; // some event will be redirected to scroll area

  QLCLAbstractScrollArea_viewportEvent_Override(Method) := @ViewPortEventFilter;
  QLCLAbstractScrollArea_override_viewportEvent(QLCLAbstractScrollAreaH(Widget), Method);

  setViewport(FViewPortWidget.Widget);
end;

procedure TQtAbstractScrollArea.viewportDelete;
var
  NilMethod: TMethod;
begin
  if Assigned(FViewPortWidget) then
  begin
    FillChar(NilMethod, SizeOf(NilMethod), 0);
    QLCLAbstractScrollArea_override_viewportEvent(QLCLAbstractScrollAreaH(Widget), NilMethod);
    FreeAndNil(FViewPortWidget);
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtAbstractScrollArea.setScrollStyle
  Params:  None
  Returns: Nothing
           Setting scrollbar''s policy (LCL TScrollStyle)
 -----------------------------------------------------------------------------}
procedure TQtAbstractScrollArea.setScrollStyle(AScrollStyle: TScrollStyle);
begin
  {$ifdef VerboseQt}
    WriteLn('TQAbstractScrollArea.setScrollStyle');
  {$endif}
  case AScrollStyle of
    ssNone:
    begin
      QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOff);
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOff);
    end;
    ssHorizontal:
    begin
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOn);
    end;
    ssVertical:
    begin
     QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOn);
    end;
    ssBoth:
    begin
      QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOn);
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAlwaysOn);
    end;
    ssAutoHorizontal:
    begin
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAsNeeded);
    end;
    ssAutoVertical:
    begin
      QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAsNeeded);
    end;
    ssAutoBoth:
    begin
      QAbstractScrollArea_setHorizontalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAsNeeded);
      QAbstractScrollArea_setVerticalScrollBarPolicy(QAbstractScrollAreaH(Widget), QtScrollBarAsNeeded);
    end;
  end;
  LCLObject.InvalidateClientRectCache(True);
  LCLObject.DoAdjustClientRectChange;
end;

  { TQtCalendar }

{------------------------------------------------------------------------------
  Function: TQtCalendar.CreateWidget
  Params:  None
  Returns: Nothing
 ------------------------------------------------------------------------------}
function TQtCalendar.CreateWidget(const AParams: TCreateParams):QWidgetH;
begin
  // Creates the widget
  {$ifdef VerboseQt}
    WriteLn('TQtCalendar.Create');
  {$endif}
  FMouseDoubleClicked := False;
  Result := QCalendarWidget_create();
end;

procedure TQtCalendar.AttachEvents;
var
  Method: TMethod;
  i: integer;
  Children: TPtrIntArray;
  AnObject: QObjectH;
begin
  inherited AttachEvents;
  
  FClickedHook := QCalendarWidget_hook_create(Widget);
  FActivatedHook := QCalendarWidget_hook_create(Widget);
  FSelectionChangedHook := QCalendarWidget_hook_create(Widget);
  FCurrentPageChangedHook := QCalendarWidget_hook_create(Widget);
  
  QCalendarWidget_clicked_Event(Method) := @SignalClicked;
  QCalendarWidget_hook_hook_clicked(FClickedHook, Method);

  QCalendarWidget_activated_Event(Method) := @SignalActivated;
  QCalendarWidget_hook_hook_activated(FActivatedHook, Method);

  QCalendarWidget_selectionChanged_Event(Method) := @SignalSelectionChanged;
  QCalendarWidget_hook_hook_selectionChanged(FSelectionChangedHook, Method);

  QCalendarWidget_currentPageChanged_Event(Method) := @SignalCurrentPageChanged;
  QCalendarWidget_hook_hook_currentPageChanged(FCurrentPageChangedHook, Method);

  QObject_children(Widget, @Children);
  for i := 0 to High(Children) do
  begin
    AnObject := QObjectH(Children[i]);
    if QObject_isWidgetType(AnObject) then
    begin
      {do not localize !!}
      if QObject_inherits(AnObject,'QAbstractScrollArea') then
      begin
        FCalViewportEventHook := QObject_hook_create(QAbstractScrollArea_viewport(QAbstractScrollAreaH(AnObject)));
        TEventFilterMethod(Method) := @calViewportEventFilter;
        QObject_hook_hook_events(FCalViewportEventHook, Method);
      end;
    end;
  end;

end;

procedure TQtCalendar.DetachEvents;
begin
  QObject_hook_destroy(FCalViewportEventHook);
  QCalendarWidget_hook_destroy(FClickedHook);
  QCalendarWidget_hook_destroy(FActivatedHook);
  QCalendarWidget_hook_destroy(FSelectionChangedHook);
  QCalendarWidget_hook_destroy(FCurrentPageChangedHook);
  inherited DetachEvents;
end;

function TQtCalendar.calViewportEventFilter(Sender: QObjectH; Event: QEventH
  ): Boolean; cdecl;
begin
  {we install only mouse events on QCalendar viewport}
  Result := False;
  QEvent_accept(Event);
  if (LCLObject <> nil) then
  begin
    case QEvent_type(Event) of
      QEventMouseButtonPress,
      QEventMouseButtonRelease: SlotMouse(Sender, Event);
      QEventMouseButtonDblClick:
      begin
        FMouseDoubleClicked := True;
        SlotMouse(Sender, Event);
      end;
    end;
  end;
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.SignalActivated
  Params:  None
  Returns: Nothing
           Sends signal when RETURN pressed on selected date.
 ------------------------------------------------------------------------------}
procedure TQtCalendar.SignalActivated(ADate: QDateH); cdecl;
var
  y,m,d: Integer;
  Msg: TLMMouse;
  Event: QKeyEventH;
begin
  {$IFDEF VerboseQt}
  writeln('TQtCalendar.signalActivated ');
  {$ENDIF}

  {avoid OnAcceptDate() to trigger twice if doubleclicked
   via FMouseDoubleClicked, also send Key events when item
   activated (only Key_Return & Key_Enter activates)}
  if not FMouseDoubleClicked then
  begin
    Event := QKeyEvent_create(QEventKeyPress, QtKey_Return, QtNoModifier);
    QCoreApplication_postEvent(Widget, Event);
    Event := QKeyEvent_create(QEventKeyRelease, QtKey_Return, QtNoModifier);
    QCoreApplication_postEvent(Widget, Event);
  end else
    FMouseDoubleClicked := False;

  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_DAYCHANGED;
  y := QDate_year(ADate);
  m := QDate_month(ADate);
  d := QDate_day(ADate);
  if (y <> aYear) or (m <> aMonth) or (d <> aDay) then
    DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.SignalClicked
  Params:  None
  Returns: Nothing
           Sends msg LM_DAYCHANGED when OldDate<>NewDate
 ------------------------------------------------------------------------------}
procedure TQtCalendar.SignalClicked(ADate: QDateH); cdecl;
var
  Msg: TLMessage;
  y, m, d: Integer;
begin
  {$IFDEF VerboseQt}
  writeln('TQtCalendar.signalClicked');
  {$ENDIF}
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_DAYCHANGED;
  y := QDate_year(ADate);
  m := QDate_month(ADate);
  d := QDate_day(ADate);
  if (y <> aYear) or (m <> aMonth) or (d <> aDay) then
    DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.SignalSelectionChanged
  Params:  None
  Returns: Nothing

  Notes: no event for date changed by keyboard ?!?
   always triggers even if selection isn't changed ...
   this is not Qt4 bug ... tested with pure Qt C++ app
 ------------------------------------------------------------------------------}
procedure TQtCalendar.SignalSelectionChanged; cdecl;
var
  Msg: TLMessage;
begin
  {$IFDEF VerboseQt}
  writeln('TQtCalendar.SignalSelectionChanged');
  {$ENDIF}
  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_SELCHANGE;
  DeliverMessage(Msg);
end;

{------------------------------------------------------------------------------
  Function: TQtCalendar.SignalCurrentPageChanged
  Params:  None
  Returns: Nothing

  Notes: fixme what's wrong with those values ?!?
   with pure Qt C++ app this works ok, but via bindings get
   impossible year & month values ...
 ------------------------------------------------------------------------------}
procedure TQtCalendar.signalCurrentPageChanged(p1, p2: Integer); cdecl;
var
  Msg: TLMessage;
begin
  {$IFDEF VerboseQt}
  writeln('TQtCalendar.SignalCurrentPageChanged p1=',p1,' p2=',p2);
  {$ENDIF}
  FillChar(Msg, SizeOf(Msg), #0);
  if AYear <> p1 then
  begin
    Msg.Msg := LM_YEARCHANGED;
    DeliverMessage(Msg);
  end;

  if AMonth <> p2 then
  begin
    Msg.Msg := LM_MONTHCHANGED;
    DeliverMessage(Msg);
  end;
end;

{ TQtHintWindow }

function TQtHintWindow.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  FHasPaint := True;
  Result := QWidget_create(nil, QtToolTip);
  MenuBar := nil;
end;

{ TQtPage }

function TQtPage.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  FHasPaint := True;
  Result := QWidget_create;
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
end;

function TQtPage.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  if QEvent_type(Event) = QEventResize then
    LCLObject.Parent.InvalidateClientRectCache(False);
  Result:=inherited EventFilter(Sender, Event);
end;

function TQtPage.getIcon: QIconH;
begin
  Result := FIcon;
end;

function TQtPage.getIndex: Integer;
{var
  AParent: QTabWidgetH;}
begin
  if LCLObject.Parent is TCustomNotebook then
    Result := TCustomNotebook(LCLObject.Parent).IndexOf(TCustomPage(LCLObject))
  else
    Result := -1;
{
  AParent := getTabWidget;
  if AParent <> nil then
    Result := QTabWidget_indexOf(AParent, Widget)
  else
    Result := -1;
}
end;

function TQtPage.getTabWidget: QTabWidgetH;
var
  AParent: TQtWidget;
begin
  //AParent := QWidget_parentWidget(Widget);
  if LCLObject.Parent is TCustomNotebook then
  begin
    AParent := TQtWidget(LCLObject.Parent.Handle);
    Result := QTabWidgetH(AParent.Widget);
  end
  else
    Result := nil;
end;

procedure TQtPage.setIcon(const AIcon: QIconH);
var
  AParent: QTabWidgetH;
begin
  FIcon := AIcon;
  AParent := getTabWidget;
  if AParent <> nil then
    QTabWidget_setTabIcon(AParent, getIndex, AIcon);
end;

procedure TQtPage.setText(const W: WideString);
var
  AParent: QTabWidgetH;
begin
  inherited setText(W);
  AParent := getTabWidget;
  if AParent <> nil then
    QTabWidget_setTabText(AParent, getIndex, @W);
end;

{ TQtAbstractItemView }

function TQtAbstractItemView.GetOwnerDrawn: Boolean;
begin
  Result := FNewDelegate <> nil;
end;

procedure TQtAbstractItemView.SetOwnerDrawn(const AValue: Boolean);
var
  Method: TMethod;
begin
  if AValue and (FNewDelegate = nil) then
  begin
    FNewDelegate := QLCLItemDelegate_create(Widget);

    QLCLItemDelegate_sizeHint_Override(Method) := @ItemDelegateSizeHint;
    QLCLItemDelegate_override_sizeHint(FNewDelegate, Method);

    QLCLItemDelegate_paint_Override(Method) := @ItemDelegatePaint;
    QLCLItemDelegate_override_Paint(FNewDelegate, Method);

    FOldDelegate := QAbstractItemView_itemDelegate(QAbstractItemViewH(Widget));
    QAbstractItemView_setItemDelegate(QAbstractItemViewH(Widget), FNewDelegate);
  end
  else
  if ((not AValue) and (FNewDelegate <> nil)) then
  begin
    {$note this call avoid sporadic AVs with QLCLItemDelegate_destroy(FNewDelegate).}
    {howto reproduce: comment next code line, recompile laz, and then in oi click
     in first field eg. Action (TForm), now push kbd down arrow let it pass all properties,
     you'll have crash at Constraints property.}
    FNewDelegate := QLCLItemDelegateH(QAbstractItemView_itemDelegate(QAbstractItemViewH(Widget)));
    QAbstractItemView_setItemDelegate(QAbstractItemViewH(Widget), FOldDelegate);
    QLCLItemDelegate_destroy(FNewDelegate);
    FNewDelegate := nil;
  end;
end;

constructor TQtAbstractItemView.Create(const AWinControl: TWinControl;
  const AParams: TCreateParams);
begin
  inherited Create(AWinControl, AParams);
  FOldDelegate := nil;
  FNewDelegate := nil;
end;

procedure TQtAbstractItemView.signalActivated(index: QModelIndexH); cdecl;
var
  Msg: TLMessage;
begin
  // writeln('SIGNAL: TQtAbstractItemView.signalActivated');
  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := LM_ACTIVATE;
  DeliverMessage( Msg );
end;

procedure TQtAbstractItemView.signalClicked(index: QModelIndexH); cdecl;
begin
  {use to be overriden by descedants, don''t implement it here,
   or U get in trouble with TQtListView && TQtListWidget items.}
end;

procedure TQtAbstractItemView.signalDoubleClicked(index: QModelIndexH); cdecl;
begin
  {use to be overriden by descedants, don''t implement it here,
   or U get in trouble with TQtListView && TQtListWidget items.}
end;

procedure TQtAbstractItemView.signalEntered(index: QModelIndexH); cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := LM_ENTER;
  DeliverMessage( Msg );
end;

procedure TQtAbstractItemView.signalPressed(index: QModelIndexH); cdecl;
begin
  {should be overriden by descedants}
end;

procedure TQtAbstractItemView.SignalViewportEntered; cdecl;
begin
  {should be overriden by descedants}
end;

procedure TQtAbstractItemView.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FSignalActivated := QAbstractItemView_hook_create(Widget);
  FSignalClicked := QAbstractItemView_hook_create(Widget);
  FSignalDoubleClicked := QAbstractItemView_hook_create(Widget);
  FSignalEntered := QAbstractItemView_hook_create(Widget);
  FSignalPressed := QAbstractItemView_hook_create(Widget);
  FSignalViewportEntered := QAbstractItemView_hook_create(Widget);
  
  QAbstractItemView_activated_Event(Method) := @SignalActivated;
  QAbstractItemView_hook_hook_activated(FSignalActivated, Method);

  QAbstractItemView_clicked_Event(Method) := @SignalClicked;
  QAbstractItemView_hook_hook_clicked(FSignalClicked, Method);
  
  QAbstractItemView_doubleClicked_Event(Method) := @SignalDoubleClicked;
  QAbstractItemView_hook_hook_doubleClicked(FSignalDoubleClicked, Method);
  
  QAbstractItemView_entered_Event(Method) := @SignalEntered;
  QAbstractItemView_hook_hook_entered(FSignalEntered, Method);

  QAbstractItemView_pressed_Event(Method) := @SignalPressed;
  QAbstractItemView_hook_hook_pressed(FSignalPressed, Method);

  QAbstractItemView_viewportEntered_Event(Method) := @SignalViewportEntered;
  QAbstractItemView_hook_hook_viewportEntered(FSignalViewportEntered, Method);

  FAbstractItemViewportEventHook := QObject_hook_create(QAbstractScrollArea_viewport(QAbstractScrollAreaH(Widget)));
  TEventFilterMethod(Method) := @itemViewViewportEventFilter;
  QObject_hook_hook_events(FAbstractItemViewportEventHook, Method);
end;

procedure TQtAbstractItemView.DetachEvents;
begin
  QAbstractItemView_hook_destroy(FSignalActivated);
  QAbstractItemView_hook_destroy(FSignalClicked);
  QAbstractItemView_hook_destroy(FSignalDoubleClicked);
  QAbstractItemView_hook_destroy(FSignalEntered);
  QAbstractItemView_hook_destroy(FSignalPressed);
  QAbstractItemView_hook_destroy(FSignalViewportEntered);
  QObject_hook_destroy(FAbstractItemViewportEventHook);
  inherited DetachEvents;
end;

procedure TQtAbstractItemView.SetColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteBase, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

procedure TQtAbstractItemView.setTextColor(const Value: PQColor);
var
  Palette: QPaletteH;
begin
  Palette := QPalette_create(QWidget_palette(Widget));
  try
    QPalette_setColor(Palette, QPaletteText, Value);
    QWidget_setPalette(Widget, Palette);
  finally
    QPalette_destroy(Palette);
  end;
end;

function TQtAbstractItemView.itemViewViewportEventFilter(Sender: QObjectH;
  Event: QEventH): Boolean; cdecl;
begin
  {we install only mouse events on QAbstractItemView viewport}
  Result := False;
  QEvent_accept(Event);
  if (LCLObject <> nil) then
  begin
    case QEvent_type(Event) of
      QEventMouseButtonPress,
      QEventMouseButtonRelease,
      QEventMouseButtonDblClick: SlotMouse(Sender, Event);
    end;
  end;
end;

procedure TQtAbstractItemView.clearSelection;
begin
  QAbstractItemView_clearSelection(QAbstractItemViewH(Widget));
end;

function TQtAbstractItemView.getModel: QAbstractItemModelH;
begin
  Result := QAbstractItemView_model(QAbstractItemViewH(Widget));
end;

function TQtAbstractItemView.getSelectionMode: QAbstractItemViewSelectionMode;
begin
  Result := QAbstractItemView_SelectionMode(QAbstractItemViewH(Widget));
end;

procedure TQtAbstractItemView.modelIndex(retval: QModelIndexH; row, column: Integer; parent: QModelIndexH = nil);
begin
  QAbstractItemModel_index(getModel, retval, row, column, parent);
end;

function TQtAbstractItemView.visualRect(Index: QModelIndexH): TRect;
begin
  QAbstractItemView_visualRect(QAbstractItemViewH(Widget), @Result, Index);
end;

procedure TQtAbstractItemView.setEditTriggers(
  ATriggers: QAbstractItemViewEditTriggers);
begin
  QAbstractItemView_setEditTriggers(QAbstractItemViewH(Widget), ATriggers);
end;

procedure TQtAbstractItemView.setSelectionMode(
  AMode: QAbstractItemViewSelectionMode);
begin
  QAbstractItemView_setSelectionMode(QAbstractItemViewH(Widget), AMode);
end;

procedure TQtAbstractItemView.setSelectionBehavior(
  ABehavior: QAbstractItemViewSelectionBehavior);
begin
  QAbstractItemView_setSelectionBehavior(QAbstractItemViewH(Widget), ABehavior);
end;

procedure TQtAbstractItemView.ItemDelegateSizeHint(
  option: QStyleOptionViewItemH; index: QModelIndexH; Size: PSize); cdecl;
var
  Msg: TLMMeasureItem;
  MeasureItemStruct: TMeasureItemStruct;
begin
  MeasureItemStruct.itemID := QModelIndex_row(index);
  MeasureItemStruct.itemWidth := Size^.cx;
  MeasureItemStruct.itemHeight := Size^.cy;
  Msg.Msg := LM_MEASUREITEM;
  Msg.MeasureItemStruct := @MeasureItemStruct;
  DeliverMessage(Msg);
  Size^.cx := MeasureItemStruct.itemWidth;
  Size^.cy := MeasureItemStruct.itemHeight;
end;

procedure TQtAbstractItemView.ItemDelegatePaint(painter: QPainterH;
  option: QStyleOptionViewItemH; index: QModelIndexH); cdecl;
begin
  // should be overrided
end;

{ TQtRubberBand }

function TQtRubberBand.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  Result := QRubberBand_create(FShape);
end;

constructor TQtRubberBand.Create(const AWinControl: TWinControl;
  const AParams: TCreateParams);
begin
  FShape := QRubberBandLine;
  inherited Create(AWinControl, AParams);
end;

function TQtRubberBand.getShape: QRubberBandShape;
begin
  Result := QRubberBand_shape(QRubberBandH(Widget));
end;

procedure TQtRubberBand.setShape(AShape: QRubberBandShape);
begin
  if getShape <> AShape then
  begin
    // recreate widget
    FShape := AShape;
    RecreateWidget;
    AttachEvents;
  end;
end;

{ TQtFileDialog }

function TQtFileDialog.CreateWidget(parent: QWidgetH; f: QtWindowFlags): QWidgetH;
begin
  Result := QFileDialog_create(parent, f);
end;

procedure TQtFileDialog.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;

  FCurrentChangedHook := QFileDialog_hook_create(Widget);
  FDirecotyEnteredHook := QFileDialog_hook_create(Widget);
  FFilterSelectedHook := QFileDialog_hook_create(Widget);

  QFileDialog_filterSelected_Event(Method) := @FilterSelectedEvent;
  QFileDialog_hook_hook_filterSelected(FFilterSelectedHook, Method);

  QFileDialog_currentChanged_Event(Method) := @CurrentChangedEvent;
  QFileDialog_hook_hook_currentChanged(FCurrentChangedHook, Method);

  QFileDialog_directoryEntered_Event(Method) := @DirectoryEnteredEvent;
  QFileDialog_hook_hook_directoryEntered(FDirecotyEnteredHook, Method);
end;

procedure TQtFileDialog.DetachEvents;
begin
  QFileDialog_hook_destroy(FCurrentChangedHook);
  QFileDialog_hook_destroy(FFilterSelectedHook);
  QFileDialog_hook_destroy(FDirecotyEnteredHook);

  inherited DetachEvents;
end;

function TQtFileDialog.selectFile: WideString;
begin
  QFileDialog_selectFile(QFileDialogH(Widget), @Result);
end;

procedure TQtFileDialog.selectedFiles(retval: QStringListH);
begin
  QFileDialog_selectedFiles(QFileDialogH(Widget), retval);
end;

procedure TQtFileDialog.setAcceptMode(const AMode: QFileDialogAcceptMode);
begin
  QFileDialog_setAcceptMode(QFileDialogH(Widget), AMode)
end;

procedure TQtFileDialog.setConfirmOverwrite(const AValue: Boolean);
begin
  QFileDialog_setConfirmOverwrite(QFileDialogH(Widget), AValue);
end;

procedure TQtFileDialog.setDirectory(const ADirectory: WideString);
begin
  QFileDialog_setDirectory(QFileDialogH(Widget), @ADirectory);
end;

procedure TQtFileDialog.setHistory(AList: TStrings);
var
  List: QStringListH;
  i: Integer;
  WStr: WideString;
begin
  List := QStringList_create();
  try
    for i := 0 to AList.Count - 1 do
    begin
      WStr := GetUTF8String(AList.Strings[i]);
      QStringList_append(List, @WStr);
    end;
    QFileDialog_setHistory(QFileDialogH(Widget), List);
  finally
    QStringList_destroy(List);
  end;
end;

procedure TQtFileDialog.setFileMode(const AMode: QFileDialogFileMode);
begin
  QFileDialog_setFileMode(QFileDialogH(Widget), AMode);
end;

procedure TQtFileDialog.setFilter(const AFilter: WideString);
begin
  {$IFDEF USE_QT_44}
  QFileDialog_setNameFilter(QFileDialogH(Widget), @AFilter);
  {$ELSE}
  QFileDialog_setFilter(QFileDialogH(Widget), @AFilter);
  {$ENDIF}
end;

procedure TQtFileDialog.setLabelText(const ALabel: QFileDialogDialogLabel; const AText: WideString);
begin
  QFileDialog_setLabelText(QFileDialogH(Widget), ALabel, @AText);
end;

procedure TQtFileDialog.setReadOnly(const AReadOnly: Boolean);
begin
  QFileDialog_setReadOnly(QFileDialogH(Widget), AReadOnly);
end;

procedure TQtFileDialog.setViewMode(const AMode: QFileDialogViewMode);
begin
  QFileDialog_setViewMode(QFileDialogH(Widget), AMode);
end;

procedure TQtFileDialog.FilterSelectedEvent(filter: PWideString); cdecl;
var
  List: TQtStringList;
  index: Integer;
begin
  if filter <> nil then
  begin
    List := TQtStringList.Create;
    getFilters(List.Handle);
    index := List.IndexOf(Utf8Encode(filter^));
    if index <> -1 then
      TFileDialog(FDialog).IntfFileTypeChanged(index + 1);
    List.Free;
  end;
end;

procedure TQtFileDialog.CurrentChangedEvent(path: PWideString); cdecl;
begin
  if FDialog is TOpenDialog then
  begin
    TOpenDialog(FDialog).FileName := Utf8Encode(path^);
    TOpenDialog(FDialog).DoSelectionChange;
  end;
end;

procedure TQtFileDialog.DirectoryEnteredEvent(directory: PWideString); cdecl;
begin
  if FDialog is TOpenDialog then
    TOpenDialog(FDialog).DoFolderChange;
end;

procedure TQtFileDialog.getFilters(const retval: QStringListH);
begin
  {$IFDEF USE_QT_44}
  QFileDialog_nameFilters(QFileDialogH(Widget), retval);
  {$ELSE}
  QFileDialog_filters(QFileDialogH(Widget), retval);
  {$ENDIF}
end;

{ TQtGraphicView }

function TQtGraphicsView.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  FHasPaint := True;
  FViewPortWidget := nil;
  Result := QGraphicsView_create();
  QWidget_setAttribute(Result, QtWA_NoMousePropagation);
end;

{ TQtDesignWidget }

function TQtDesignWidget.CreateWidget(const AParams: TCreateParams): QWidgetH;
begin
  Result := inherited CreateWidget(AParams);
  FDesignControl := QWidget_create(Result);
  QWidget_setMouseTracking(FDesignControl, True);
  setProperty(FDesignControl, 'lclwidget', Int64(PtrUInt(Self)));
  BringDesignerToFront;
end;

procedure TQtDesignWidget.DestroyWidget;
begin
  if FDesignControl <> nil then
  begin
    removeProperty(FDesignControl, 'lclwidget');
    QObject_deleteLater(FDesignControl);
    FDesignControl := nil;
  end;
  inherited DestroyWidget;
end;

procedure TQtDesignWidget.SlotDesignControlPaint(Sender: QObjectH; Event: QEventH); cdecl;
var
  Msg: TLMPaint;
  AStruct: PPaintStruct;
  P: TPoint;
begin
  {$ifdef VerboseQt}
    WriteLn('TQtWidget.SlotPaint ', dbgsName(LCLObject));
  {$endif}

  if (LCLObject is TWinControl) then
  begin
    FillChar(Msg, SizeOf(Msg), #0);

    Msg.Msg := LM_PAINT;
    New(AStruct);
    FillChar(AStruct^, SizeOf(TPaintStruct), 0);
    Msg.PaintStruct := AStruct;

    with PaintData do
    begin
      PaintWidget := FDesignControl;
      ClipRegion := QPaintEvent_Region(QPaintEventH(Event));
      if ClipRect = nil then
        New(ClipRect);
      QPaintEvent_Rect(QPaintEventH(Event), ClipRect);
    end;

    Msg.DC := BeginPaint(THandle(Self), AStruct^);
    FDesignContext := Msg.DC;

    Msg.PaintStruct^.rcPaint := PaintData.ClipRect^;
    Msg.PaintStruct^.hdc := FDesignContext;

    P := getClientOffset;
    inc(P.X, FScrollX);
    inc(P.Y, FScrollY);
    TQtDeviceContext(Msg.DC).translate(P.X, P.Y);

    // send paint message
    try
      // Saving clip rect and clip region
      try
        LCLObject.WindowProc(TLMessage(Msg));
      finally
        Dispose(PaintData.ClipRect);
        Fillchar(FPaintData, SizeOf(FPaintData), 0);
        FDesignContext := 0;
        EndPaint(THandle(Self), AStruct^);
        Dispose(AStruct);
      end;
    except
      Application.HandleException(nil);
    end;
  end;
end;

procedure TQtDesignWidget.BringDesignerToFront;
begin
  if FDesignControl <> nil then
    QWidget_raise(FDesignControl);
end;

procedure TQtDesignWidget.ResizeDesigner;
begin
  if FDesignControl = nil then
    Exit;
  with getClientBounds do
  begin
    QWidget_move(FDesignControl, Left, Top);
    QWidget_resize(FDesignControl, Right - Left, Bottom - Top);
  end;
end;

function TQtDesignWidget.GetContext: HDC;
begin
  if FDesignContext <> 0 then
    Result := FDesignContext
  else
    Result := FContext;
end;

function TQtDesignWidget.DesignControlEventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  BeginEventProcessing;
  Result := False;
  if LCLObject <> nil then
  begin
    QEvent_Accept(Event);
    case QEvent_type(Event) of
      QEventPaint: SlotDesignControlPaint(Sender, Event);
    end;
  end;
  EndEventProcessing;
end;

function TQtDesignWidget.EventFilter(Sender: QObjectH; Event: QEventH): Boolean; cdecl;
begin
  BeginEventProcessing;
  Result := False;
  if LCLObject <> nil then
  begin
    QEvent_accept(Event);
    case QEvent_type(Event) of
      QEventChildAdded,
      QEventChildRemoved: BringDesignerToFront;
      QEventResize:
        begin
          Result := inherited EventFilter(Sender, Event);
          ResizeDesigner;
        end;
    else
      Result := inherited EventFilter(Sender, Event);
    end;
  end;
  EndEventProcessing;
end;

procedure TQtDesignWidget.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  if FDesignControl <> nil then
  begin
    FDesignControlEventHook := QObject_hook_create(FDesignControl);
    TEventFilterMethod(Method) := @DesignControlEventFilter;
    QObject_hook_hook_events(FDesignControlEventHook, Method);
  end;
end;

procedure TQtDesignWidget.DetachEvents;
begin
  if FDesignControlEventHook <> nil then
    QObject_hook_destroy(FDesignControlEventHook);
  inherited DetachEvents;
end;

procedure TQtDesignWidget.lowerWidget;
begin
  inherited lowerWidget;
  BringDesignerToFront;
end;

procedure TQtDesignWidget.raiseWidget;
begin
  inherited raiseWidget;
  BringDesignerToFront;
end;

{ TQtMessageBox }

function TQtMessageBox.getMsgBoxType: QMessageBoxIcon;
begin
  Result := QMessageBox_icon(QMessageBoxH(Widget));
end;

procedure TQtMessageBox.setDetailText(const AValue: WideString);
var
  Str: WideString;
begin
  Str := GetUTF8String(AValue);
  QMessageBox_setDetailedText(QMessageBoxH(Widget), @Str);
end;

function TQtMessageBox.getMessageStr: WideString;
var
  Str: WideString;
begin
  QMessageBox_text(QMessageBoxH(Widget), @Str);
  Result := UTF8Encode(Str);
end;

function TQtMessageBox.getDetailText: WideString;
var
  Str: WideString;
begin
  QMessageBox_detailedText(QMessageBoxH(Widget), @Str);
  Result := UTF8Encode(Str);
end;

procedure TQtMessageBox.setMessageStr(const AValue: WideString);
var
  Str: WideString;
begin
  Str := GetUTF8String(AValue);
  QMessageBox_setText(QMessageBoxH(Widget), @Str);
end;

procedure TQtMessageBox.setMsgBoxType(const AValue: QMessageBoxIcon);
begin
  QMessageBox_setIcon(QMessageBoxH(Widget), AValue);
end;

procedure TQtMessageBox.setTitle(const AValue: WideString);
begin
  if AValue <> FTitle then
  begin
    FTitle := GetUTF8String(AValue);
    QMessageBox_setWindowTitle(QMessageBoxH(Widget), @FTitle);
  end;
end;

function TQtMessageBox.CreateWidget(AParent: QWidgetH): QWidgetH;
begin
  Initialize(FButtons);
  FHasPaint := False;
  Result := QMessageBox_create(AParent);
  QMessageBox_setWindowModality(QMessageBoxH(Result), QtApplicationModal);
end;

constructor TQtMessageBox.Create(AParent: QWidgetH);
begin
  FOwner := nil;
  FCentralWidget := nil;
  FOwnWidget := True;
  FProps := nil;
  LCLObject := nil;
  FKeysToEat := [];
  FHasPaint := False;
  Widget := CreateWidget(AParent);
end;

destructor TQtMessageBox.Destroy;
var
  i: Integer;
begin
  for i := 0 to High(FButtons) do
  begin
    QMessageBox_removeButton(QMessageBoxH(Widget), FButtons[i]);
    FButtons[i] := nil;
  end;
  Finalize(FButtons);
  FButtons := nil;
  inherited Destroy;
end;

procedure TQtMessageBox.AttachEvents;
var
  Method: TMethod;
begin
  inherited AttachEvents;
  FMBEventHook := QObject_hook_create(Widget);
  TEventFilterMethod(Method) := @EventFilter;
  QObject_hook_hook_events(FMBEventHook, Method);
end;

procedure TQtMessageBox.DetachEvents;
begin
  QObject_hook_destroy(FMBEventHook);
  inherited DetachEvents;
end;

function TQtMessageBox.EventFilter(Sender: QObjectH; Event: QEventH): Boolean;
  cdecl;
begin
  {we'll need it later. QMessageBox uses it's own eventLoop !}
  Result := False;
  QEvent_accept(Event);
end;

procedure TQtMessageBox.AddButton(ABtnType: QMessageBoxStandardButton;
  ACaption: WideString; AIsDefaultBtn: Boolean; const AEscapeBtn: Boolean);
var
  ABtn: QPushButtonH;
  Str: WideString;
  i: Integer;
  v: QVariantH;
begin
  ABtn := QMessageBox_addButton(QMessageBoxH(Widget), ABtnType);
  Str := GetUTF8String(ACaption);
  QAbstractButton_setText(ABtn, @Str);

  if AIsDefaultBtn then
    QMessageBox_setDefaultButton(QMessageBoxH(Widget), ABtn);

  if AEscapeBtn then
    QMessageBox_setEscapeButton(QMessageBoxH(Widget), ABtn);

  i := length(FButtons);
  SetLength(FButtons, i + 1);

  v := QVariant_create(Int64(PtrUInt(ABtnType)));
  try
    QObject_setProperty(ABtn, 'lclmsgboxbutton', v);
  finally
    QVariant_destroy(v);
  end;

  FButtons[i] := ABtn;
end;

function TQtMessageBox.exec: QMessageBoxStandardButton;
var
  ABtn: QPushButtonH;
  v: QVariantH;
  ok: Boolean;
  QResult: QMessageBoxStandardButton;
begin
  Result := QMessageBoxNoButton;
  QDialog_exec(QMessageBoxH(Widget));
  ABtn := QPushButtonH(QMessageBox_clickedButton(QMessageBoxH(Widget)));
  if ABtn <> nil then
  begin
    v := QVariant_create();
    try
      QObject_property(ABtn, v, 'lclmsgboxbutton');
      if QVariant_isValid(v) then
      begin
        QResult := QVariant_toULongLong(v, @Ok);
        if Ok then
          Result := QResult;
      end;
    finally
      QVariant_destroy(v);
    end;
  end;
end;

end.
