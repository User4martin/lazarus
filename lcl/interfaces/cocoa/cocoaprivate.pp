{ $Id: $}
{                  --------------------------------------------
                  cocoaprivate.pp  -  Cocoa internal classes
                  --------------------------------------------

 This unit contains the private classhierarchy for the Cocoa implemetations

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit CocoaPrivate;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}
{$interfaces corba}

{.$DEFINE COCOA_DEBUG_SETBOUNDS}
{.$DEFINE COCOA_DEBUG_LISTVIEW}
{.$DEFINE COCOA_SPIN_DEBUG}
{.$DEFINE COCOA_SPINEDIT_INSIDE_CONTAINER}
{.$DEFINE COCOA_SUPERVIEW_HEIGHT}

interface

uses
  // rtl+ftl
  Types, Classes, SysUtils,
  CGGeometry,
  // Libs
  MacOSAll, CocoaAll, CocoaUtils, CocoaGDIObjects,
  // LCL
  LMessages, LCLMessageGlue, ExtCtrls, Graphics, Forms,
  LCLType, LCLProc, Controls, ComCtrls, Spin, StdCtrls;

const
  SPINEDIT_DEFAULT_STEPPER_WIDTH = 15;
  SPINEDIT_EDIT_SPACING_FOR_SELECTION = 4;
  STATUSBAR_DEFAULT_HEIGHT = 18;

type

  { ICommonCallback }

  ICommonCallback = interface
    // mouse events
    function MouseUpDownEvent(Event: NSEvent): Boolean;
    procedure MouseClick;
    function MouseMove(Event: NSEvent): Boolean;
    function KeyEvent(Event: NSEvent; AForceAsKeyDown: Boolean = False): Boolean;
    function scrollWheel(Event: NSEvent): Boolean;
    // size, pos events
    procedure frameDidChange;
    procedure boundsDidChange;
    // misc events
    procedure Draw(ctx: NSGraphicsContext; const bounds, dirty: NSRect);
    procedure DrawBackground(ctx: NSGraphicsContext; const bounds, dirty: NSRect);
    function ResetCursorRects: Boolean;
    procedure BecomeFirstResponder;
    procedure ResignFirstResponder;
    procedure DidBecomeKeyNotification;
    procedure DidResignKeyNotification;
    procedure SendOnChange;
    procedure SendOnTextChanged;
    // non event methods
    function DeliverMessage(Msg: Cardinal; WParam: WParam; LParam: LParam): LResult;
    function GetPropStorage: TStringList;
    function GetContext: TCocoaContext;
    function GetTarget: TObject;
    function GetHasCaret: Boolean;
    function GetCallbackObject: TObject;
    procedure SetHasCaret(AValue: Boolean);
    function GetIsOpaque: Boolean;
    procedure SetIsOpaque(AValue: Boolean);

    // properties
    property HasCaret: Boolean read GetHasCaret write SetHasCaret;
    property IsOpaque: Boolean read GetIsOpaque write SetIsOpaque;
  end;

  { LCLObjectExtension }

  LCLObjectExtension = objccategory(NSObject)
    function lclIsEnabled: Boolean; message 'lclIsEnabled';
    procedure lclSetEnabled(AEnabled: Boolean); message 'lclSetEnabled:';
    function lclIsVisible: Boolean; message 'lclIsVisible';
    procedure lclSetVisible(AVisible: Boolean); message 'lclSetVisible:';
    function lclWindowState: Integer; message 'lclWindowState';

    procedure lclInvalidateRect(const r: TRect); message 'lclInvalidateRect:';
    procedure lclInvalidate; message 'lclInvalidate';
    procedure lclUpdate; message 'lclUpdate';
    procedure lclRelativePos(var Left, Top: Integer); message 'lclRelativePos::';
    procedure lclLocalToScreen(var X, Y: Integer); message 'lclLocalToScreen::';
    procedure lclScreenToLocal(var X, Y: Integer); message 'lclScreenToLocal::';
    function lclParent: id; message 'lclParent';
    function lclFrame: TRect; message 'lclFrame';
    procedure lclSetFrame(const r: TRect); message 'lclSetFrame:';
    function lclClientFrame: TRect; message 'lclClientFrame';
    function lclGetCallback: ICommonCallback; message 'lclGetCallback';
    procedure lclClearCallback; message 'lclClearCallback';
    function lclGetPropStorage: TStringList; message 'lclGetPropStorage';
    function lclGetTarget: TObject; message 'lclGetTarget';
    function lclDeliverMessage(Msg: Cardinal; WParam: WParam; LParam: LParam): LResult; message 'lclDeliverMessage:::';
    function lclIsHandle: Boolean; message 'lclIsHandle';
  end;

  { LCLViewExtension }

  LCLViewExtension = objccategory(NSView)

    function lclInitWithCreateParams(const AParams: TCreateParams): id; message 'lclInitWithCreateParams:';

    function lclIsVisible: Boolean; message 'lclIsVisible'; reintroduce;
    procedure lclSetVisible(AVisible: Boolean); message 'lclSetVisible:'; reintroduce;
    function lclIsPainting: Boolean; message 'lclIsPainting';
    procedure lclInvalidateRect(const r: TRect); message 'lclInvalidateRect:'; reintroduce;
    procedure lclInvalidate; message 'lclInvalidate'; reintroduce;
    procedure lclUpdate; message 'lclUpdate'; reintroduce;
    procedure lclRelativePos(var Left, Top: Integer); message 'lclRelativePos::'; reintroduce;
    procedure lclLocalToScreen(var X, Y: Integer); message 'lclLocalToScreen::'; reintroduce;
    procedure lclScreenToLocal(var X, Y: Integer); message 'lclScreenToLocal::'; reintroduce;
    function lclParent: id; message 'lclParent'; reintroduce;
    function lclFrame: TRect; message 'lclFrame'; reintroduce;
    procedure lclSetFrame(const r: TRect); message 'lclSetFrame:'; reintroduce;
    function lclClientFrame: TRect; message 'lclClientFrame'; reintroduce;
  end;

  NSViewFix = objccategory external (NSView)
    function fittingSize: NSSize; message 'fittingSize';
  end;

  { LCLControlExtension }

  LCLControlExtension = objccategory(NSControl)
    function lclIsEnabled: Boolean; message 'lclIsEnabled'; reintroduce;
    procedure lclSetEnabled(AEnabled: Boolean); message 'lclSetEnabled:'; reintroduce;
  end;

  { LCLWindowExtension }

  LCLWindowExtension = objccategory(NSWindow)
    function lclIsVisible: Boolean; message 'lclIsVisible'; reintroduce;
    procedure lclSetVisible(AVisible: Boolean); message 'lclSetVisible:'; reintroduce;
    function lclIsEnabled: Boolean; message 'lclIsEnabled'; reintroduce;
    procedure lclSetEnabled(AEnabled: Boolean); message 'lclSetEnabled:'; reintroduce;

    function lclWindowState: Integer; message 'lclWindowState'; reintroduce;
    procedure lclInvalidateRect(const r: TRect); message 'lclInvalidateRect:'; reintroduce;
    procedure lclInvalidate; message 'lclInvalidate'; reintroduce;
    procedure lclUpdate; message 'lclUpdate'; reintroduce;
    procedure lclRelativePos(var Left, Top: Integer); message 'lclRelativePos::'; reintroduce;
    procedure lclLocalToScreen(var X, Y: Integer); message 'lclLocalToScreen::'; reintroduce;
    procedure lclScreenToLocal(var X, Y: Integer); message 'lclScreenToLocal::'; reintroduce;
    function lclFrame: TRect; message 'lclFrame'; reintroduce;
    procedure lclSetFrame(const r: TRect); message 'lclSetFrame:'; reintroduce;
    function lclClientFrame: TRect; message 'lclClientFrame'; reintroduce;
    function lclGetTopBarHeight:integer; message 'lclGetTopBarHeight'; reintroduce;
  end;

  { IButtonCallback }

  IButtonCallback = interface(ICommonCallback)
    procedure ButtonClick;
  end;

  { IListBoxCallBack }

  IListBoxCallBack = interface(ICommonCallback)
    procedure SelectionChanged;
  end;

  { IListViewCallBack }

  IListViewCallBack = interface(ICommonCallback)
    procedure delayedSelectionDidChange_OnTimer(ASender: TObject);
  end;

  { IWindowCallback }

  IWindowCallback = interface(ICommonCallBack)
    function CanActivate: Boolean;
    procedure Activate;
    procedure Deactivate;
    procedure CloseQuery(var CanClose: Boolean);
    procedure Close;
    procedure Resize;
    procedure Move;

    function GetEnabled: Boolean;
    procedure SetEnabled(AValue: Boolean);

    property Enabled: Boolean read GetEnabled write SetEnabled;
  end;

  { TCocoaButton }

  TCocoaButton = objcclass(NSButton)
  protected
    procedure actionButtonClick(sender: NSObject); message 'actionButtonClick:';
    procedure boundsDidChange(sender: NSNotification); message 'boundsDidChange:';
    procedure frameDidChange(sender: NSNotification); message 'frameDidChange:';
  public
    callback: IButtonCallback;
    Glyph: TBitmap;
    procedure dealloc; override;
    function initWithFrame(frameRect: NSRect): id; override;
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    // mouse
    procedure mouseDown(event: NSEvent); override;
    procedure mouseUp(event: NSEvent); override;
    procedure rightMouseDown(event: NSEvent); override;
    procedure rightMouseUp(event: NSEvent); override;
    procedure otherMouseDown(event: NSEvent); override;
    procedure otherMouseUp(event: NSEvent); override;

    procedure mouseDragged(event: NSEvent); override;
    procedure mouseEntered(event: NSEvent); override;
    procedure mouseExited(event: NSEvent); override;
    procedure mouseMoved(event: NSEvent); override;
    procedure resetCursorRects; override;
    // lcl overrides
    function lclIsHandle: Boolean; override;
    procedure lclSetFrame(const r: TRect); override;
  end;

  TCocoaFieldEditor = objcclass;

  { TCocoaTextField }

  TCocoaTextField = objcclass(NSTextField)
    callback: ICommonCallback;
    procedure dealloc; override;
    function GetFieldEditor: TCocoaFieldEditor; message 'GetFieldEditor';
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function RealResignFirstResponder: Boolean; message 'RealResignFirstResponder';
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    procedure resetCursorRects; override;
    function lclIsHandle: Boolean; override;
    // key
    //procedure keyDown(event: NSEvent); override; -> keyDown doesn't work in NSTextField
    procedure keyUp(event: NSEvent); override;
  end;

  { TCocoaSecureTextField }

  TCocoaSecureTextField = objcclass(NSSecureTextField)
  public
    callback: ICommonCallback;
    procedure dealloc; override;
    function GetFieldEditor: TCocoaFieldEditor; message 'GetFieldEditor';
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function RealResignFirstResponder: Boolean; message 'RealResignFirstResponder';
    function resignFirstResponder: Boolean; override;
    procedure resetCursorRects; override;
    function lclIsHandle: Boolean; override;
    // key
    //procedure keyDown(event: NSEvent); override; -> keyDown doesn't work in NSTextField
    procedure keyUp(event: NSEvent); override;
  end;


  { TCocoaTextView }

  TCocoaTextView = objcclass(NSTextView)
  public
    callback: ICommonCallback;
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    procedure resetCursorRects; override;
    function lclIsHandle: Boolean; override;
    // key
    procedure keyDown(event: NSEvent); override;
    procedure keyUp(event: NSEvent); override;
    procedure flagsChanged(event: NSEvent); override;
  end;

  { TCocoaPanel }

  TCocoaPanel = objcclass(NSPanel, NSWindowDelegateProtocol)
  protected
    function windowShouldClose(sender : id): LongBool; message 'windowShouldClose:';
    procedure windowWillClose(notification: NSNotification); message 'windowWillClose:';
    procedure windowDidBecomeKey(notification: NSNotification); message 'windowDidBecomeKey:';
    procedure windowDidResignKey(notification: NSNotification); message 'windowDidResignKey:';
    procedure windowDidResize(notification: NSNotification); message 'windowDidResize:';
    procedure windowDidMove(notification: NSNotification); message 'windowDidMove:';
  public
    callback: IWindowCallback;
    function acceptsFirstResponder: Boolean; override;
    function canBecomeKeyWindow: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    // mouse
    procedure mouseDown(event: NSEvent); override;
    procedure mouseUp(event: NSEvent); override;
    procedure rightMouseDown(event: NSEvent); override;
    procedure rightMouseUp(event: NSEvent); override;
    procedure rightMouseDragged(event: NSEvent); override;
    procedure otherMouseDown(event: NSEvent); override;
    procedure otherMouseUp(event: NSEvent); override;
    procedure otherMouseDragged(event: NSEvent); override;
    procedure mouseDragged(event: NSEvent); override;
    procedure mouseEntered(event: NSEvent); override;
    procedure mouseExited(event: NSEvent); override;
    procedure mouseMoved(event: NSEvent); override;
    procedure sendEvent(event: NSEvent); override;
    function lclIsHandle: Boolean; override;
  end;

  { TCocoaFieldEditor }

  TCocoaFieldEditor = objcclass(NSTextView)
  public
    lastEditBox: NSTextField;
    function resignFirstResponder: Boolean; override;
  end;

  { TCocoaWindow }

  TCocoaWindow = objcclass(NSWindow, NSWindowDelegateProtocol)
  protected
    fieldEditor: TCocoaFieldEditor;
    function windowShouldClose(sender : id): LongBool; message 'windowShouldClose:';
    function windowWillReturnFieldEditor_toObject(sender: NSWindow; client: id): id; message 'windowWillReturnFieldEditor:toObject:';
    procedure windowWillClose(notification: NSNotification); message 'windowWillClose:';
    procedure windowDidBecomeKey(notification: NSNotification); message 'windowDidBecomeKey:';
    procedure windowDidResignKey(notification: NSNotification); message 'windowDidResignKey:';
    procedure windowDidResize(notification: NSNotification); message 'windowDidResize:';
    procedure windowDidMove(notification: NSNotification); message 'windowDidMove:';
  public
    callback: IWindowCallback;
    LCLForm: TCustomForm;
    procedure dealloc; override;
    function acceptsFirstResponder: Boolean; override;
    function canBecomeKeyWindow: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    // mouse
    procedure mouseDown(event: NSEvent); override;
    procedure mouseUp(event: NSEvent); override;
    procedure rightMouseDown(event: NSEvent); override;
    procedure rightMouseUp(event: NSEvent); override;
    procedure rightMouseDragged(event: NSEvent); override;
    procedure otherMouseDown(event: NSEvent); override;
    procedure otherMouseUp(event: NSEvent); override;
    procedure otherMouseDragged(event: NSEvent); override;
    procedure mouseDragged(event: NSEvent); override;
    procedure mouseEntered(event: NSEvent); override;
    procedure mouseExited(event: NSEvent); override;
    procedure mouseMoved(event: NSEvent); override;
    procedure scrollWheel(event: NSEvent); override;
    procedure sendEvent(event: NSEvent); override;
    function lclIsHandle: Boolean; override;
    // NSDraggingDestinationCategory
    function draggingEntered(sender: NSDraggingInfoProtocol): NSDragOperation; override;
    function performDragOperation(sender: NSDraggingInfoProtocol): Boolean; override;
    // menu support
    procedure lclItemSelected(sender: id); message 'lclItemSelected:';
  end;

  { TCocoaCustomControl }

  TCocoaCustomControl = objcclass(NSControl)
  public
    callback: ICommonCallback;
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    procedure drawRect(dirtyRect: NSRect); override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    // mouse
    procedure mouseDown(event: NSEvent); override;
    procedure mouseUp(event: NSEvent); override;
    procedure rightMouseDown(event: NSEvent); override;
    procedure rightMouseUp(event: NSEvent); override;
    procedure rightMouseDragged(event: NSEvent); override;
    procedure otherMouseDown(event: NSEvent); override;
    procedure otherMouseUp(event: NSEvent); override;
    procedure otherMouseDragged(event: NSEvent); override;
    procedure mouseDragged(event: NSEvent); override;
    procedure mouseEntered(event: NSEvent); override;
    procedure mouseExited(event: NSEvent); override;
    procedure mouseMoved(event: NSEvent); override;
    procedure scrollWheel(event: NSEvent); override;
    // key
    procedure keyDown(event: NSEvent); override;
    procedure keyUp(event: NSEvent); override;
    procedure flagsChanged(event: NSEvent); override;
    // other
    procedure resetCursorRects; override;
    function lclIsHandle: Boolean; override;
  end;

  { TCocoaWindowContent }

  TCocoaWindowContent = objcclass(TCocoaCustomControl)
  protected
    procedure didBecomeKeyNotification(sender: NSNotification); message 'didBecomeKeyNotification:';
    procedure didResignKeyNotification(sender: NSNotification); message 'didResignKeyNotification:';
  public
    isembedded: Boolean; // true - if the content is inside of another control, false - if the content is in its own window;
    ownwin: NSWindow;
    function lclOwnWindow: NSWindow; message 'lclOwnWindow';
    procedure lclSetFrame(const r: TRect); override;
    procedure viewDidMoveToSuperview; override;
    procedure viewDidMoveToWindow; override;
    procedure viewWillMoveToWindow(newWindow: NSWindow); override;
    procedure dealloc; override;
    procedure setHidden(aisHidden: Boolean); override;
    function lclIsHandle: Boolean; override;
  end;

  { TCocoaScrollView }

  TCocoaScrollView = objcclass(NSScrollView)
  public
    callback: ICommonCallback;
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    procedure resetCursorRects; override;
    function lclIsHandle: Boolean; override;
  end;

  TStatusItemData = record
    Text  : NSString;
    Width : Integer;
    Align : TAlignment;
  end;

  TStatusItemDataArray = array of TStatusItemData;

  { TCocoaStatusBar }

  TCocoaStatusBar = objcclass(TCocoaCustomControl)
  public
    StatusBar : TStatusBar;
    panelCell : NSCell;
    procedure drawRect(dirtyRect: NSRect); override;
    procedure dealloc; override;
  end;

  TCocoaComboBox = objcclass;
  TCocoaReadOnlyComboBox = objcclass;

  { TCocoaComboBoxList }

  TCocoaComboBoxList = class(TStringList)
  protected
    FOwner: TCocoaComboBox;
    FReadOnlyOwner: TCocoaReadOnlyComboBox;
    FPreChangeListCount: Integer;
    procedure Changed; override;
    procedure Changing; override;
  public
    // Pass only 1 owner and nil for the other ones
    constructor Create(AOwner: TCocoaComboBox; AReadOnlyOwner: TCocoaReadOnlyComboBox);
  end;

  IComboboxCallBack = interface(ICommonCallBack)
    procedure ComboBoxWillPopUp;
    procedure ComboBoxWillDismiss;
    procedure ComboBoxSelectionDidChange;
    procedure ComboBoxSelectionIsChanging;
  end;

  { TCocoaComboBox }

  TCocoaComboBox = objcclass(NSComboBox, NSComboBoxDataSourceProtocol, NSComboBoxDelegateProtocol)
  public
    callback: IComboboxCallBack;
    list: TCocoaComboBoxList;
    resultNS: NSString;  //use to return values to combo
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function comboBox_objectValueForItemAtIndex_(combo: TCocoaComboBox; row: NSInteger): id; message 'comboBox:objectValueForItemAtIndex:';
    function numberOfItemsInComboBox(combo: TCocoaComboBox): NSInteger; message 'numberOfItemsInComboBox:';
    procedure dealloc; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    procedure resetCursorRects; override;
    procedure comboBoxWillPopUp(notification: NSNotification); message 'comboBoxWillPopUp:';
    procedure comboBoxWillDismiss(notification: NSNotification); message 'comboBoxWillDismiss:';
    procedure comboBoxSelectionDidChange(notification: NSNotification); message 'comboBoxSelectionDidChange:';
    procedure comboBoxSelectionIsChanging(notification: NSNotification); message 'comboBoxSelectionIsChanging:';
    function lclIsHandle: Boolean; override;
  end;

  { TCocoaReadOnlyComboBox }

  TCocoaReadOnlyComboBox = objcclass(NSPopUpButton)
  public
    Owner: TCustomComboBox;
    callback: IComboboxCallBack;
    list: TCocoaComboBoxList;
    resultNS: NSString;  //use to return values to combo
    lastSelectedItemIndex: Integer; // -1 means invalid or none selected
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    procedure dealloc; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    procedure resetCursorRects; override;
    function lclIsHandle: Boolean; override;
    procedure comboboxAction(sender: id); message 'comboboxAction:';
  end;

  { TCocoaScrollBar }

  TCocoaScrollBar = objcclass(NSScroller)
  public
    callback: ICommonCallback;
    LCLScrollBar: TCustomScrollBar;
    procedure actionScrolling(sender: NSObject); message 'actionScrolling:';
    function IsHorizontal: Boolean; message 'IsHorizontal';
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    procedure resetCursorRects; override;
    function lclIsHandle: Boolean; override;
  end;

  TCocoaListBox = objcclass;

  { TCocoaStringList }

  TCocoaStringList = class(TStringList)
  protected
    procedure Changed; override;
  public
    Owner: TCocoaListBox;
    constructor Create(AOwner: TCocoaListBox);
  end;

  { TCocoaListBox }

  TCocoaListBox = objcclass(NSTableView, NSTableViewDelegateProtocol, NSTableViewDataSourceProtocol)
  public
    callback: IListBoxCallback;
    resultNS: NSString;
    list: TCocoaStringList;
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    function numberOfRowsInTableView(aTableView: NSTableView): NSInteger; message 'numberOfRowsInTableView:';

    function tableView_shouldEditTableColumn_row(tableView: NSTableView;
      tableColumn: NSTableColumn; row: NSInteger): Boolean;
      message 'tableView:shouldEditTableColumn:row:';

    function tableView_objectValueForTableColumn_row(tableView: NSTableView;
      objectValueForTableColumn: NSTableColumn; row: NSInteger):id;
      message 'tableView:objectValueForTableColumn:row:';

    procedure tableViewSelectionDidChange(notification: NSNotification); message 'tableViewSelectionDidChange:';

    procedure dealloc; override;
    procedure resetCursorRects; override;

    // mouse
    procedure mouseDown(event: NSEvent); override;
    // procedure mouseUp(event: NSEvent); override;   This is eaten by NSTableView - worked around with NSTableViewDelegateProtocol
    procedure rightMouseDown(event: NSEvent); override;
    procedure rightMouseUp(event: NSEvent); override;
    procedure otherMouseDown(event: NSEvent); override;
    procedure otherMouseUp(event: NSEvent); override;
    procedure mouseDragged(event: NSEvent); override;
    procedure mouseEntered(event: NSEvent); override;
    procedure mouseExited(event: NSEvent); override;
    procedure mouseMoved(event: NSEvent); override;
    // key
    procedure keyDown(event: NSEvent); override;
    procedure keyUp(event: NSEvent); override;
    function lclIsHandle: Boolean; override;
  end;

  { TCocoaCheckListBox }

  TCocoaCheckListBox = objcclass(TCocoaListBox)
  public
    // LCL functions
    AllowMixedState: Boolean;
    class function LCLCheckStateToCocoa(ALCLState: TCheckBoxState): NSInteger; message 'LCLCheckStateToCocoa:';
    class function CocoaCheckStateToLCL(ACocoaState: NSInteger): TCheckBoxState; message 'CocoaCheckStateToLCL:';
    function CheckListBoxGetNextState(ACurrent: TCheckBoxState): TCheckBoxState; message 'CheckListBoxGetNextState:';
    function GetCocoaState(const AIndex: integer): NSInteger; message 'GetCocoaState:';
    procedure SetCocoaState(const AIndex: integer; AState: NSInteger); message 'SetCocoaState:AState:';
    function GetState(const AIndex: integer): TCheckBoxState; message 'GetState:';
    procedure SetState(const AIndex: integer; AState: TCheckBoxState); message 'SetState:AState:';
    // Cocoa functions
    function tableView_objectValueForTableColumn_row(tableView: NSTableView;
      objectValueForTableColumn: NSTableColumn; row: NSInteger):id;
      override;
    procedure tableView_setObjectValue_forTableColumn_row(tableView: NSTableView;
      object_: id; tableColumn: NSTableColumn; row: NSInteger);
      message 'tableView:setObjectValue:forTableColumn:row:';
    function tableView_dataCellForTableColumn_row(tableView: NSTableView;
      tableColumn: NSTableColumn; row: NSInteger): NSCell;
      message 'tableView:dataCellForTableColumn:row:';
  end;

  { TCocoaTabPage }

  TCocoaTabPage = objcclass(NSTabViewItem)
  public
    callback: ICommonCallback;
    LCLPage: TCustomPage;
    LCLParent: TCustomTabControl;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    function lclFrame: TRect; override;
    function lclClientFrame: TRect; override;
  end;

  { TCocoaTabControl }

  TCocoaTabControl = objcclass(NSTabView, NSTabViewDelegateProtocol)
  public
    LCLPageControl: TCustomTabControl;
    callback: ICommonCallback;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    // NSTabViewDelegateProtocol
    function tabView_shouldSelectTabViewItem(tabView: NSTabView; tabViewItem: NSTabViewItem): Boolean; message 'tabView:shouldSelectTabViewItem:';
    procedure tabView_willSelectTabViewItem(tabView: NSTabView; tabViewItem: NSTabViewItem); message 'tabView:willSelectTabViewItem:';
    procedure tabView_didSelectTabViewItem(tabView: NSTabView; tabViewItem: NSTabViewItem); message 'tabView:didSelectTabViewItem:';
    procedure tabViewDidChangeNumberOfTabViewItems(TabView: NSTabView); message 'tabViewDidChangeNumberOfTabViewItems:';
  end;

  TCocoaTabPageView = objcclass(TCocoaCustomControl)
  public
    tabView: TCocoaTabControl;
    tabPage: TCocoaTabPage;
  end;

  { TListView }

  { TCocoaTableListView }

  TCocoaTableListView = objcclass(NSTableView, NSTableViewDelegateProtocol, NSTableViewDataSourceProtocol)
  public
    ListView: TCustomListView; // just reference, don't release
    callback: IListViewCallback;

    // Owned Pascal classes which need to be released
    Items: TStringList; // Object are TStringList for sub-items
    Timer: TTimer;

    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;

    // Own methods, mostly convenience methods
    procedure setStringValue_forCol_row(AStr: NSString; col, row: NSInteger); message 'setStringValue:forCol:row:';
    procedure deleteItemForRow(row: NSInteger); message 'deleteItemForRow:';
    procedure setListViewStringValue_forCol_row(AStr: NSString; col, row: NSInteger); message 'setListViewStringValue:forCol:row:';
    function getIndexOfColumn(ACol: NSTableColumn): NSInteger; message 'getIndexOfColumn:';
    procedure reloadDataForRow_column(ARow, ACol: NSInteger); message 'reloadDataForRow:column:';
    procedure scheduleSelectionDidChange(); message 'scheduleSelectionDidChange';

    procedure dealloc; override;
    procedure resetCursorRects; override;

    // mouse
    procedure mouseDown(event: NSEvent); override;
    // procedure mouseUp(event: NSEvent); override;   This is eaten by NSTableView - worked around with NSTableViewDelegateProtocol
    procedure rightMouseDown(event: NSEvent); override;
    procedure rightMouseUp(event: NSEvent); override;
    procedure otherMouseDown(event: NSEvent); override;
    procedure otherMouseUp(event: NSEvent); override;
    procedure mouseDragged(event: NSEvent); override;
    procedure mouseEntered(event: NSEvent); override;
    procedure mouseExited(event: NSEvent); override;
    procedure mouseMoved(event: NSEvent); override;
    // key
    procedure keyDown(event: NSEvent); override;
    procedure keyUp(event: NSEvent); override;
    function lclIsHandle: Boolean; override;

    // NSTableViewDataSourceProtocol
    function numberOfRowsInTableView(tableView: NSTableView): NSInteger; message 'numberOfRowsInTableView:';
    function tableView_objectValueForTableColumn_row(tableView: NSTableView; tableColumn: NSTableColumn; row: NSInteger): id; message 'tableView:objectValueForTableColumn:row:';
    procedure tableView_setObjectValue_forTableColumn_row(tableView: NSTableView; object_: id; tableColumn: NSTableColumn; row: NSInteger); message 'tableView:setObjectValue:forTableColumn:row:';
    //procedure tableView_sortDescriptorsDidChange(tableView: NSTableView; oldDescriptors: NSArray); message 'tableView:sortDescriptorsDidChange:';
    //function tableView_writeRowsWithIndexes_toPasteboard(tableView: NSTableView; rowIndexes: NSIndexSet; pboard: NSPasteboard): Boolean; message 'tableView:writeRowsWithIndexes:toPasteboard:';
    //function tableView_validateDrop_proposedRow_proposedDropOperation(tableView: NSTableView; info: NSDraggingInfoProtocol; row: NSInteger; dropOperation: NSTableViewDropOperation): NSDragOperation; message 'tableView:validateDrop:proposedRow:proposedDropOperation:';
    //function tableView_acceptDrop_row_dropOperation(tableView: NSTableView; info: NSDraggingInfoProtocol; row: NSInteger; dropOperation: NSTableViewDropOperation): Boolean; message 'tableView:acceptDrop:row:dropOperation:';
    //function tableView_namesOfPromisedFilesDroppedAtDestination_forDraggedRowsWithIndexes(tableView: NSTableView; dropDestination: NSURL; indexSet: NSIndexSet): NSArray; message 'tableView:namesOfPromisedFilesDroppedAtDestination:forDraggedRowsWithIndexes:';

    // NSTableViewDelegateProtocol
    //procedure tableView_willDisplayCell_forTableColumn_row(tableView: NSTableView; cell: id; tableColumn: NSTableColumn; row: NSInteger); message 'tableView:willDisplayCell:forTableColumn:row:';
    function tableView_shouldEditTableColumn_row(tableView: NSTableView; tableColumn: NSTableColumn; row: NSInteger): Boolean; message 'tableView:shouldEditTableColumn:row:';
    {function selectionShouldChangeInTableView(tableView: NSTableView): Boolean; message 'selectionShouldChangeInTableView:';
    function tableView_shouldSelectRow(tableView: NSTableView; row: NSInteger): Boolean; message 'tableView:shouldSelectRow:';
    function tableView_selectionIndexesForProposedSelection(tableView: NSTableView; proposedSelectionIndexes: NSIndexSet): NSIndexSet; message 'tableView:selectionIndexesForProposedSelection:';
    function tableView_shouldSelectTableColumn(tableView: NSTableView; tableColumn: NSTableColumn): Boolean; message 'tableView:shouldSelectTableColumn:';
    procedure tableView_mouseDownInHeaderOfTableColumn(tableView: NSTableView; tableColumn: NSTableColumn); message 'tableView:mouseDownInHeaderOfTableColumn:';
    procedure tableView_didClickTableColumn(tableView: NSTableView; tableColumn: NSTableColumn); message 'tableView:didClickTableColumn:';
    procedure tableView_didDragTableColumn(tableView: NSTableView; tableColumn: NSTableColumn); message 'tableView:didDragTableColumn:';
    function tableView_toolTipForCell_rect_tableColumn_row_mouseLocation(tableView: NSTableView; cell: NSCell; rect: NSRectPointer; tableColumn: NSTableColumn; row: NSInteger; mouseLocation: NSPoint): NSString; message 'tableView:toolTipForCell:rect:tableColumn:row:mouseLocation:';
    function tableView_heightOfRow(tableView: NSTableView; row: NSInteger): CGFloat; message 'tableView:heightOfRow:';
    function tableView_typeSelectStringForTableColumn_row(tableView: NSTableView; tableColumn: NSTableColumn; row: NSInteger): NSString; message 'tableView:typeSelectStringForTableColumn:row:';
    function tableView_nextTypeSelectMatchFromRow_toRow_forString(tableView: NSTableView; startRow: NSInteger; endRow: NSInteger; searchString: NSString): NSInteger; message 'tableView:nextTypeSelectMatchFromRow:toRow:forString:';
    function tableView_shouldTypeSelectForEvent_withCurrentSearchString(tableView: NSTableView; event: NSEvent; searchString: NSString): Boolean; message 'tableView:shouldTypeSelectForEvent:withCurrentSearchString:';
    function tableView_shouldShowCellExpansionForTableColumn_row(tableView: NSTableView; tableColumn: NSTableColumn; row: NSInteger): Boolean; message 'tableView:shouldShowCellExpansionForTableColumn:row:';
    function tableView_shouldTrackCell_forTableColumn_row(tableView: NSTableView; cell: NSCell; tableColumn: NSTableColumn; row: NSInteger): Boolean; message 'tableView:shouldTrackCell:forTableColumn:row:';
    function tableView_dataCellForTableColumn_row(tableView: NSTableView; tableColumn: NSTableColumn; row: NSInteger): NSCell; message 'tableView:dataCellForTableColumn:row:';
    function tableView_isGroupRow(tableView: NSTableView; row: NSInteger): Boolean; message 'tableView:isGroupRow:';
    function tableView_sizeToFitWidthOfColumn(tableView: NSTableView; column: NSInteger): CGFloat; message 'tableView:sizeToFitWidthOfColumn:';
    function tableView_shouldReorderColumn_toColumn(tableView: NSTableView; columnIndex: NSInteger; newColumnIndex: NSInteger): Boolean; message 'tableView:shouldReorderColumn:toColumn:';}
    procedure tableViewSelectionDidChange(notification: NSNotification); message 'tableViewSelectionDidChange:';
    {procedure tableViewColumnDidMove(notification: NSNotification); message 'tableViewColumnDidMove:';
    procedure tableViewColumnDidResize(notification: NSNotification); message 'tableViewColumnDidResize:';
    procedure tableViewSelectionIsChanging(notification: NSNotification); message 'tableViewSelectionIsChanging:';}
  end;

  TCocoaListView = objcclass(NSScrollView)
  public
    ListView: TCustomListView; // just reference, don't release
    callback: ICommonCallback;
    // For report style:
    TableListView: TCocoaTableListView;
    // For the other styles:
    // ToDo
  end;

  { TCocoaGroupBox }

  TCocoaGroupBox = objcclass(NSBox)
  public
    callback: ICommonCallback;
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    procedure resetCursorRects; override;
    function lclIsHandle: Boolean; override;
  end;

  { TCocoaProgressIndicator }

  TCocoaProgressIndicator = objcclass(NSProgressIndicator)
    callback: ICommonCallback;
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    procedure resetCursorRects; override;
  end;

  { TCocoaSlider }

  TCocoaSlider = objcclass(NSSlider)
    callback: ICommonCallback;
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    procedure resetCursorRects; override;
    //
    procedure keyDown(event: NSEvent); override;
    procedure keyUp(event: NSEvent); override;
    //
    procedure SnapToInteger(AExtraFactor: Integer = 0); message 'SnapToInteger:';
    procedure sliderAction(sender: id); message 'sliderAction:';
  end;

  TCocoaSliderCell = objcclass(NSSliderCell)
  end;

  { TCocoaSpinEdit }
{$IFDEF COCOA_SPINEDIT_INSIDE_CONTAINER}
  TCocoaSpinEdit = objcclass(NSControl)
  public
    callback: ICommonCallback;
    Stepper: NSStepper;
    Edit: NSTextField;
    Spin: TCustomFloatSpinEdit;
    procedure dealloc; override;
    procedure UpdateControl(ASpinEdit: TCustomFloatSpinEdit); message 'UpdateControl:';
    procedure CreateSubcontrols(ASpinEdit: TCustomFloatSpinEdit; const AParams: TCreateParams); message 'CreateSubControls:AParams:';
    procedure PositionSubcontrols(const ALeft, ATop, AWidth, AHeight: Integer); message 'PositionSubcontrols:ATop:AWidth:AHeight:';
    procedure CalculateSubcontrolPos(const ASpinLCLBounds: TRect; out AEditBounds, AStepperBounds: TRect); message 'CalculateSubcontrolPos:AEditBounds:AStepperBounds:';
    procedure StepperChanged(sender: NSObject); message 'StepperChanged:';
    // lcl
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    function lclIsHandle: Boolean; override;
    // NSViewFix
    function fittingSize: NSSize; override;
  end;
{$ELSE}
  TCocoaSpinEdit = objcclass(NSTextField, NSTextFieldDelegateProtocol)
    callback: ICommonCallback;
    Stepper: NSStepper;
    NumberFormatter: NSNumberFormatter;
    Spin: TCustomFloatSpinEdit;
    procedure dealloc; override;
    procedure UpdateControl(ASpinEdit: TCustomFloatSpinEdit); message 'UpdateControl:';
    procedure CreateSubcontrols(ASpinEdit: TCustomFloatSpinEdit; const AParams: TCreateParams); message 'CreateSubControls:AParams:';
    procedure PositionSubcontrols(const ALeft, ATop, AWidth, AHeight: Integer); message 'PositionSubcontrols:ATop:AWidth:AHeight:';
    procedure StepperChanged(sender: NSObject); message 'StepperChanged:';
    function GetFieldEditor: TCocoaFieldEditor; message 'GetFieldEditor';
    // NSTextFieldDelegateProtocol
    procedure controlTextDidChange(obj: NSNotification); override;
    // lcl
    function acceptsFirstResponder: Boolean; override;
    function becomeFirstResponder: Boolean; override;
    function RealResignFirstResponder: Boolean; message 'RealResignFirstResponder';
    function resignFirstResponder: Boolean; override;
    function lclGetCallback: ICommonCallback; override;
    procedure lclClearCallback; override;
    procedure resetCursorRects; override;
    function lclIsHandle: Boolean; override;
    procedure lclSetVisible(AVisible: Boolean); override;
    procedure lclSetFrame(const r: TRect); override;
    // NSViewFix
    function fittingSize: NSSize; override;
  end;
{$ENDIF}

procedure SetViewDefaults(AView: NSView);
function CheckMainThread: Boolean;
function GetNSViewSuperViewHeight(view: NSView): CGFloat;

implementation

uses CocoaWSComCtrls, CocoaInt;

{$I mackeycodes.inc}

procedure SetViewDefaults(AView: NSView);
begin
  if not Assigned(AView) then Exit;
  AView.setAutoresizingMask(NSViewMinYMargin or NSViewMaxXMargin);
end;

function CheckMainThread: Boolean;
begin
  Result := NSThread.currentThread.isMainThread;
end;

function GetNSViewSuperViewHeight(view: NSView): CGFloat;
begin
  Result := -1;
  if not Assigned(view) then Exit;
  if not Assigned(view.superview) then Exit;
  if view.superview.isKindOfClass_(TCocoaTabPageView) then
    Result := TCocoaTabPageView(view.superview).tabview.contentRect.size.height
  else
    Result := view.superview.frame.size.height;
  {$IFDEF COCOA_SUPERVIEW_HEIGHT}
  WriteLn(Format('GetNSViewSuperViewHeight Result=%f', [Result]));
  {$ENDIF}
end;

{ TCocoaWindowContent }

function TCocoaWindowContent.lclIsHandle: Boolean;
begin
  Result:=true;
end;

procedure TCocoaWindowContent.didBecomeKeyNotification(sender: NSNotification);
begin
  if Assigned(callback) then
    callback.DidBecomeKeyNotification;
end;

procedure TCocoaWindowContent.didResignKeyNotification(sender: NSNotification);
begin
  if Assigned(callback) then
    callback.DidResignKeyNotification;
end;

function TCocoaWindowContent.lclOwnWindow: NSWindow;
begin
  if not isembedded then
    Result := window
  else
    Result := nil;
end;

procedure TCocoaWindowContent.lclSetFrame(const r: TRect);
begin
  if isembedded then
    inherited lclSetFrame(r)
  else
    window.lclSetFrame(r);
end;

procedure TCocoaWindowContent.viewDidMoveToSuperview;
begin
  inherited viewDidMoveToSuperview;
end;

procedure TCocoaWindowContent.viewDidMoveToWindow;
begin
  isembedded := window.contentView <> self;
  if isembedded then
  begin
    if Assigned(ownwin) then
      ownwin.close;
    ownwin := nil;
  end
  else
  begin
    ownwin := window;
  end;
  inherited viewDidMoveToWindow;
end;

procedure TCocoaWindowContent.viewWillMoveToWindow(newWindow: NSWindow);
begin
  if newWindow<>nil then
     newWindow.setAcceptsMouseMovedEvents(True);
  if not isembedded and (newWindow <> window) then
  begin
    if Assigned(window) then
       window.close;
    ownwin := nil;
    isembedded := false;
  end;
  inherited viewWillMoveToWindow(newWindow);
end;

procedure TCocoaWindowContent.dealloc;
begin
  inherited dealloc;
end;

procedure TCocoaWindowContent.setHidden(aisHidden: Boolean);
begin
  if isembedded then
  begin
    inherited setHidden(aisHidden);
  end
  else
  begin
    if aisHidden and window.isVisible then
      window.orderOut(nil)
    else
    if not aisHidden and not window.isVisible then
      window.orderBack(nil);
  end;
end;

{ TCocoaPanel }

function TCocoaPanel.lclIsHandle: Boolean;
begin
  Result:=true;
end;

function TCocoaPanel.windowShouldClose(sender: id): LongBool;
var
  canClose: Boolean;
begin
  canClose := True;
  if Assigned(callback) then
    callback.CloseQuery(canClose);
  Result := canClose;
end;

procedure TCocoaPanel.windowWillClose(notification: NSNotification);
begin
  if Assigned(callback) then
    callback.Close;
end;

procedure TCocoaPanel.windowDidBecomeKey(notification: NSNotification);
begin
  if Assigned(callback) then
    callback.Activate;
end;

procedure TCocoaPanel.windowDidResignKey(notification: NSNotification);
begin
  if Assigned(callback) then
    callback.Deactivate;
end;

procedure TCocoaPanel.windowDidResize(notification: NSNotification);
begin
  if Assigned(callback) then
    callback.Resize;
end;

procedure TCocoaPanel.windowDidMove(notification: NSNotification);
begin
  if Assigned(callback) then
    callback.Move;
end;

function TCocoaPanel.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaPanel.canBecomeKeyWindow: Boolean;
begin
  Result := Assigned(callback) and callback.CanActivate;
end;

function TCocoaPanel.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
//  if Assigned(callback) then
//    callback.BecomeFirstResponder;
end;

function TCocoaPanel.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
//  if Assigned(callback) then
//    callback.ResignFirstResponder;
end;

function TCocoaPanel.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaPanel.lclClearCallback;
begin
  callback := nil;
  contentView.lclClearCallback;
end;

procedure TCocoaPanel.mouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited mouseDown(event);
end;

procedure TCocoaPanel.mouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited mouseUp(event);
end;

procedure TCocoaPanel.rightMouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited rightMouseUp(event);
end;

procedure TCocoaPanel.rightMouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited rightMouseDown(event);
end;

procedure TCocoaPanel.rightMouseDragged(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited rightMouseDragged(event);
end;

procedure TCocoaPanel.otherMouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited otherMouseDown(event);
end;

procedure TCocoaPanel.otherMouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited otherMouseUp(event);
end;

procedure TCocoaPanel.otherMouseDragged(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited otherMouseDown(event);
end;

procedure TCocoaPanel.mouseDragged(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseMove(event) then
    inherited mouseDragged(event);
end;

procedure TCocoaPanel.mouseEntered(event: NSEvent);
begin
  inherited mouseEntered(event);
end;

procedure TCocoaPanel.mouseExited(event: NSEvent);
begin
  inherited mouseExited(event);
end;

procedure TCocoaPanel.mouseMoved(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseMove(event) then
    inherited mouseMoved(event);
end;

procedure TCocoaPanel.sendEvent(event: NSEvent);
var
  Message: NSMutableDictionary;
  Handle: HWND;
  Msg: Cardinal;
  WP: WParam;
  LP: LParam;
  Result: NSNumber;
  Obj: NSObject;
begin
  if event.type_ = NSApplicationDefined then
  begin
    // event which we get through PostMessage or SendMessage
    if event.subtype = LCLEventSubTypeMessage then
    begin
      // extract message data
      Message := NSMutableDictionary(event.data1);
      Handle := NSNumber(Message.objectForKey(NSMessageWnd)).unsignedIntegerValue;
      Msg := NSNumber(Message.objectForKey(NSMessageMsg)).unsignedLongValue;
      WP := NSNumber(Message.objectForKey(NSMessageWParam)).integerValue;
      LP := NSNumber(Message.objectForKey(NSMessageLParam)).integerValue;
      // deliver message and set result
      Obj := NSObject(Handle);
      // todo: check that Obj is still a valid NSView/NSWindow
      Result := NSNumber.numberWithInteger(Obj.lclDeliverMessage(Msg, WP, LP));
      Message.setObject_forKey(Result, NSMessageResult);
      Result.release;
    end;
  end
  else
    inherited sendEvent(event);
end;

{ TCocoaFieldEditor }

function TCocoaFieldEditor.resignFirstResponder: Boolean;
begin
  //DebugLn('[TCocoaFieldEditor.resignFirstResponder]');
  if (lastEditBox <> nil) then
  begin
    if lastEditBox.isKindOfClass_(TCocoaTextField) then
    begin
      TCocoaTextField(lastEditBox).RealResignFirstResponder();
    end
    else if lastEditBox.isKindOfClass_(TCocoaSecureTextField) then
    begin
      TCocoaSecureTextField(lastEditBox).RealResignFirstResponder();
    end;
    lastEditBox := nil;
  end;
  Result := inherited resignFirstResponder;
end;

{ TCocoaWindow }

function TCocoaWindow.lclIsHandle: Boolean;
begin
  Result:=true;
end;

function TCocoaWindow.windowShouldClose(sender: id): LongBool;
var
  canClose: Boolean;
begin
  canClose := True;
  if Assigned(callback) then
    callback.CloseQuery(canClose);
  Result := canClose;
end;

function TCocoaWindow.windowWillReturnFieldEditor_toObject(sender: NSWindow;
  client: id): id;
begin
  //DebugLn('[TCocoaWindow.windowWillReturnFieldEditor_toObject]');
  Result := nil;
  if (fieldEditor = nil) then
  begin
    fieldEditor := TCocoaFieldEditor.alloc.init;
    fieldEditor.setFieldEditor(True);
  end;
  if client.isKindOfClass_(TCocoaTextField) or
     client.isKindOfClass_(TCocoaSecureTextField) then
  begin
    Result := fieldEditor;
  end;
end;

procedure TCocoaWindow.windowWillClose(notification: NSNotification);
begin
  if Assigned(callback) then
    callback.Close;
end;

procedure TCocoaWindow.windowDidBecomeKey(notification: NSNotification);
begin
  if Assigned(callback) then
    callback.Activate;
end;

procedure TCocoaWindow.windowDidResignKey(notification: NSNotification);
begin
  if Assigned(callback) then
    callback.Deactivate;
end;

procedure TCocoaWindow.windowDidResize(notification: NSNotification);
begin
  if Assigned(callback) then
    callback.Resize;
end;

procedure TCocoaWindow.windowDidMove(notification: NSNotification);
begin
  if Assigned(callback) then
    callback.Move;
end;

procedure TCocoaWindow.dealloc;
begin
  if (fieldEditor <> nil) then
  begin
    fieldEditor.release;
    fieldEditor := nil;
  end;
  inherited dealloc;
end;

function TCocoaWindow.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaWindow.canBecomeKeyWindow: Boolean;
begin
  Result := Assigned(callback) and callback.CanActivate;
end;

function TCocoaWindow.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  // uncommenting the following lines starts an endless focus loop

//  if Assigned(callback) then
//    callback.BecomeFirstResponder;
end;

function TCocoaWindow.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
//  if Assigned(callback) then
//    callback.ResignFirstResponder;
end;

function TCocoaWindow.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaWindow.lclClearCallback;
begin
  callback := nil;
  contentView.lclClearCallback;
end;

procedure TCocoaWindow.mouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited mouseDown(event);
end;

procedure TCocoaWindow.mouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited mouseUp(event);
end;

procedure TCocoaWindow.rightMouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited rightMouseUp(event);
end;

procedure TCocoaWindow.rightMouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited rightMouseDown(event);
end;

procedure TCocoaWindow.rightMouseDragged(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited rightMouseDragged(event);
end;

procedure TCocoaWindow.otherMouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited otherMouseDown(event);
end;

procedure TCocoaWindow.otherMouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited otherMouseUp(event);
end;

procedure TCocoaWindow.otherMouseDragged(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited otherMouseDown(event);
end;

procedure TCocoaWindow.mouseDragged(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseMove(event) then
    inherited mouseDragged(event);
end;

procedure TCocoaWindow.mouseEntered(event: NSEvent);
begin
  inherited mouseEntered(event);
end;

procedure TCocoaWindow.mouseExited(event: NSEvent);
begin
  inherited mouseExited(event);
end;

procedure TCocoaWindow.mouseMoved(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseMove(event) then
    inherited mouseMoved(event);
end;

procedure TCocoaWindow.scrollWheel(event: NSEvent);
begin
  if not Assigned(callback) or not callback.scrollWheel(event) then
    inherited scrollWheel(event);
end;

procedure TCocoaWindow.sendEvent(event: NSEvent);
var
  Message: NSMutableDictionary;
  Handle: HWND;
  Msg: Cardinal;
  WP: WParam;
  LP: LParam;
  Result: NSNumber;
  Obj: NSObject;
begin
  if event.type_ = NSApplicationDefined then
  begin
    // event which we get through PostMessage or SendMessage
    if event.subtype = LCLEventSubTypeMessage then
    begin
      // extract message data
      Message := NSMutableDictionary(event.data1);
      Handle := NSNumber(Message.objectForKey(NSMessageWnd)).unsignedIntegerValue;
      Msg := NSNumber(Message.objectForKey(NSMessageMsg)).unsignedLongValue;
      WP := NSNumber(Message.objectForKey(NSMessageWParam)).integerValue;
      LP := NSNumber(Message.objectForKey(NSMessageLParam)).integerValue;
      // deliver message and set result
      Obj := NSObject(Handle);
      // todo: check that Obj is still a valid NSView/NSWindow
      Result := NSNumber.numberWithInteger(Obj.lclDeliverMessage(Msg, WP, LP));
      Message.setObject_forKey(Result, NSMessageResult);
      Result.release;
    end;
  end
  else
    inherited sendEvent(event);
end;

function TCocoaWindow.draggingEntered(sender: NSDraggingInfoProtocol): NSDragOperation;
var
  lTarget: TCustomForm = nil;
begin
  Result := NSDragOperationNone;
  if (callback <> nil) and (callback.GetTarget() <> nil) and (callback.GetTarget() is TCustomForm) then
    lTarget := TCustomForm(callback.GetTarget());
  if (lTarget <> nil) and (lTarget.OnDropFiles <> nil) then
  begin
    Result := sender.draggingSourceOperationMask();
  end;
end;

function TCocoaWindow.performDragOperation(sender: NSDraggingInfoProtocol): Boolean;
var
  draggedURLs{, lClasses}: NSArray;
  lFiles: array of string;
  i: Integer;
  pboard: NSPasteboard;
  lNSStr: NSString;
  //lClass: pobjc_class;
begin
  Result := False;
  pboard := sender.draggingPasteboard();

  // Multiple strings
  draggedURLs := pboard.propertyListForType(NSFilenamesPboardType);
  SetLength(lFiles, draggedURLs.count);
  for i := 0 to draggedURLs.count-1 do
  begin
    lNSStr := NSString(draggedURLs.objectAtIndex(i));
    lFiles[i] := NSStringToString(lNSStr);
  end;

  // Multiple URLs -> Results in strange URLs with file:// protocol
  {if pboard.types.containsObject(NSURLPboardType) then
  begin
    lClass := NSURL.classClass;
    lClasses := NSArray.arrayWithObjects_count(@lClass, 1);
    draggedURLs := pboard.readObjectsForClasses_options(lClasses, nil);
    SetLength(lFiles, draggedURLs.count);
    for i := 0 to draggedURLs.count-1 do
    begin
      lNSStr := NSURL(draggedURLs.objectAtIndex(i)).absoluteString;
      lFiles[i] := NSStringToString(lNSStr);
    end;
  end;}

  if (Length(lFiles) > 0) and (callback <> nil) and (callback.GetTarget() <> nil) then
    TCustomForm(callback.GetTarget()).IntfDropFiles(lFiles);
  Result := True;
end;

procedure TCocoaWindow.lclItemSelected(sender: id);
begin

end;

{ TCocoaScrollView }

function TCocoaScrollView.lclIsHandle: Boolean;
begin
  Result := True;
end;

function TCocoaScrollView.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaScrollView.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  if Assigned(callback) then
    callback.BecomeFirstResponder;
end;

function TCocoaScrollView.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  if Assigned(callback) then
    callback.ResignFirstResponder;
end;

function TCocoaScrollView.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaScrollView.lclClearCallback;
begin
  callback := nil;
end;

procedure TCocoaScrollView.resetCursorRects;
begin
  if not Assigned(callback) or not callback.resetCursorRects then
    inherited resetCursorRects;
end;

{ TCocoaScrollBar }

procedure TCocoaScrollBar.actionScrolling(sender: NSObject);
var
  LMScroll: TLMScroll;
  b: Boolean;
begin
  FillChar(LMScroll{%H-}, SizeOf(LMScroll), #0);
  LMScroll.ScrollBar := PtrUInt(Self);

  if IsHorizontal() then
    LMScroll.Msg := LM_HSCROLL
  else
    LMScroll.Msg := LM_VSCROLL;

  LMScroll.Pos := Round(floatValue * LCLScrollBar.Max);
  LMScroll.ScrollCode := SIF_POS;

  LCLMessageGlue.DeliverMessage(LCLScrollBar, LMScroll);
end;

function TCocoaScrollBar.IsHorizontal: Boolean;
begin
  Result := frame.size.width > frame.size.height;
end;

function TCocoaScrollBar.lclIsHandle: Boolean;
begin
  Result := True;
end;

function TCocoaScrollBar.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaScrollBar.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  if Assigned(callback) then
    callback.BecomeFirstResponder;
end;

function TCocoaScrollBar.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  if Assigned(callback) then
    callback.ResignFirstResponder;
end;

function TCocoaScrollBar.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaScrollBar.lclClearCallback;
begin
  callback := nil;
end;

procedure TCocoaScrollBar.resetCursorRects;
begin
  if not Assigned(callback) or not callback.resetCursorRects then
    inherited resetCursorRects;
end;

{ TCocoaGroupBox }

function TCocoaGroupBox.lclIsHandle: Boolean;
begin
  Result := True;
end;

function TCocoaGroupBox.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaGroupBox.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  if Assigned(callback) then
    callback.BecomeFirstResponder;
end;

function TCocoaGroupBox.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  if Assigned(callback) then
    callback.ResignFirstResponder;
end;

function TCocoaGroupBox.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaGroupBox.lclClearCallback;
begin
  callback := nil;
end;

procedure TCocoaGroupBox.resetCursorRects;
begin
  if not Assigned(callback) or not callback.resetCursorRects then
    inherited resetCursorRects;
end;

{ TCocoaButton }

function TCocoaButton.lclIsHandle: Boolean;
begin
  Result := True;
end;

procedure TCocoaButton.lclSetFrame(const r: TRect);
var
  lBtnHeight, lDiff: Integer;
  lRoundBtnSize: NSSize;
begin
  // NSTexturedRoundedBezelStyle should be the preferred style, but it has a fixed height!
  // fittingSize is 10.7+
  if respondsToSelector(objcselector('fittingSize')) then
  begin
    lBtnHeight := r.Bottom - r.Top;
    lRoundBtnSize := fittingSize();
    lDiff := Abs(Round(lRoundBtnSize.Height) - lBtnHeight);
    if lDiff < 4 then // this nr of pixels maximum size difference is arbitrary and we could choose another number
      setBezelStyle(NSTexturedRoundedBezelStyle)
    else
      setBezelStyle(NSTexturedSquareBezelStyle);
  end
  else
    setBezelStyle(NSTexturedSquareBezelStyle);

  inherited lclSetFrame(r);
end;

procedure TCocoaButton.actionButtonClick(sender: NSObject);
begin
  // this is the action handler of button
  if Assigned(callback) then
    callback.ButtonClick;
end;

procedure TCocoaButton.boundsDidChange(sender: NSNotification);
begin
  if Assigned(callback) then
    callback.boundsDidChange;
end;

procedure TCocoaButton.frameDidChange(sender: NSNotification);
begin
  if Assigned(callback) then
    callback.frameDidChange;
end;

procedure TCocoaButton.dealloc;
begin
  if Assigned(Glyph) then
    FreeAndNil(Glyph);

  inherited dealloc;
end;

function TCocoaButton.initWithFrame(frameRect: NSRect): id;
begin
  Result := inherited initWithFrame(frameRect);
  if Assigned(Result) then
  begin
    setTarget(Self);
    setAction(objcselector('actionButtonClick:'));
  //  todo: find a way to release notifications below
  //  NSNotificationCenter.defaultCenter.addObserver_selector_name_object(Self, objcselector('boundsDidChange:'), NSViewBoundsDidChangeNotification, Result);
  //  NSNotificationCenter.defaultCenter.addObserver_selector_name_object(Self, objcselector('frameDidChange:'), NSViewFrameDidChangeNotification, Result);
  //  Result.setPostsBoundsChangedNotifications(True);
  //  Result.setPostsFrameChangedNotifications(True);
  end;
end;

function TCocoaButton.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaButton.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  if Assigned(callback) then
    callback.BecomeFirstResponder;
end;

function TCocoaButton.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  if Assigned(callback) then
    callback.ResignFirstResponder;
end;

function TCocoaButton.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaButton.lclClearCallback;
begin
  callback := nil;
end;

procedure TCocoaButton.mouseUp(event: NSEvent);
begin
  if not callback.MouseUpDownEvent(event) then
    inherited mouseUp(event);
end;

procedure TCocoaButton.rightMouseDown(event: NSEvent);
begin
  if not callback.MouseUpDownEvent(event) then
    inherited rightMouseDown(event);
end;

procedure TCocoaButton.rightMouseUp(event: NSEvent);
begin
  if not callback.MouseUpDownEvent(event) then
    inherited rightMouseUp(event);
end;

procedure TCocoaButton.otherMouseDown(event: NSEvent);
begin
  if not callback.MouseUpDownEvent(event) then
    inherited otherMouseDown(event);
end;

procedure TCocoaButton.otherMouseUp(event: NSEvent);
begin
  if not callback.MouseUpDownEvent(event) then
    inherited otherMouseUp(event);
end;

procedure TCocoaButton.resetCursorRects;
begin
  if not callback.resetCursorRects then
    inherited resetCursorRects;
end;

procedure TCocoaButton.mouseDown(event: NSEvent);
begin
  if not callback.MouseUpDownEvent(event) then
    inherited mouseDown(event);
end;

procedure TCocoaButton.mouseDragged(event: NSEvent);
begin
  if not callback.MouseMove(event) then
    inherited mouseDragged(event);
end;

procedure TCocoaButton.mouseEntered(event: NSEvent);
begin
  inherited mouseEntered(event);
end;

procedure TCocoaButton.mouseExited(event: NSEvent);
begin
  inherited mouseExited(event);
end;

procedure TCocoaButton.mouseMoved(event: NSEvent);
begin
  if not callback.MouseMove(event) then
    inherited mouseMoved(event);
end;

{ TCocoaTextField }

function TCocoaTextField.lclIsHandle: Boolean;
begin
  Result := True;
end;

procedure TCocoaTextField.dealloc;
var
  lFieldEditor: TCocoaFieldEditor;
begin
  lFieldEditor := GetFieldEditor();
  if (lFieldEditor <> nil) and (lFieldEditor.lastEditBox = Self) then
  begin
    lFieldEditor.lastEditBox := nil;
  end;

  inherited dealloc;
end;

function TCocoaTextField.GetFieldEditor: TCocoaFieldEditor;
var
  lFieldEditor: TCocoaFieldEditor;
  lText: NSText;
begin
  Result := nil;
  if window = nil then Exit;
  lText := window.fieldEditor_forObject(True, Self);
  if (lText <> nil) and lText.isKindOfClass_(TCocoaFieldEditor) then
  begin
    Result := TCocoaFieldEditor(lText);
  end;
end;

function TCocoaTextField.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaTextField.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  callback.BecomeFirstResponder;
end;

function TCocoaTextField.RealResignFirstResponder: Boolean;
begin
  callback.ResignFirstResponder;
  Result := True;
end;

// Do not propagate this event to the LCL,
// because Cocoa NSTextField loses focus as soon as it receives it
// and the shared editor gets focus instead.
// see NSWindow.fieldEditor:forObject:
// See http://www.cocoabuilder.com/archive/cocoa/103607-resignfirstresponder-called-immediately.html
// See http://stackoverflow.com/questions/3192905/nstextfield-not-noticing-lost-focus-when-pressing-tab
function TCocoaTextField.resignFirstResponder: Boolean;
var
  lFieldEditor: TCocoaFieldEditor;
begin
  //DebugLn('[TCocoaTextField.resignFirstResponder]');
  Result := inherited resignFirstResponder;
  lFieldEditor := GetFieldEditor();
  if (lFieldEditor <> nil) then
  begin
    lFieldEditor.lastEditBox := Self;
  end;
end;

function TCocoaTextField.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaTextField.lclClearCallback;
begin
  callback := nil;
end;

procedure TCocoaTextField.resetCursorRects;
begin
  // this will not work well because
  // cocoa replaced TextField and TextView cursors in
  // mouseEntered, mouseMoved and CursorUpdate
  if not callback.resetCursorRects then
    inherited resetCursorRects;
end;

procedure TCocoaTextField.keyUp(event: NSEvent);
begin
  if Assigned(callback) then
  begin
    // NSTextField doesn't provide keyDown, so emulate it here
    callback.KeyEvent(event, True);
    // keyUp now
    callback.KeyEvent(event);
  end;
  inherited keyUp(event);
end;

{ TCocoaTextView }

function TCocoaTextView.lclIsHandle: Boolean;
begin
  Result := True;
end;

procedure TCocoaTextView.keyDown(event: NSEvent);
begin
  if Assigned(callback) then callback.KeyEvent(event);
  // don't skip inherited or else key input won't work
  inherited keyDown(event);
end;

procedure TCocoaTextView.keyUp(event: NSEvent);
begin
  if Assigned(callback) then callback.KeyEvent(event);
  // don't skip inherited or else key input won't work
  inherited keyUp(event);
end;

procedure TCocoaTextView.flagsChanged(event: NSEvent);
begin
  if Assigned(callback) then callback.KeyEvent(event);
  // don't skip inherited or else key input won't work
  inherited flagsChanged(event);
end;

function TCocoaTextView.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaTextView.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  callback.BecomeFirstResponder;
end;

function TCocoaTextView.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  callback.ResignFirstResponder;
end;

function TCocoaTextView.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaTextView.lclClearCallback;
begin
  callback := nil;
end;

procedure TCocoaTextView.resetCursorRects;
begin
  if not callback.resetCursorRects then
    inherited resetCursorRects;
end;

{ TCocoaSecureTextField }

function TCocoaSecureTextField.lclIsHandle: Boolean;
begin
  Result := True;
end;

procedure TCocoaSecureTextField.dealloc;
var
  lFieldEditor: TCocoaFieldEditor;
begin
  lFieldEditor := GetFieldEditor();
  if (lFieldEditor <> nil) and (lFieldEditor.lastEditBox = Self) then
  begin
    lFieldEditor.lastEditBox := nil;
  end;

  inherited dealloc;
end;

function TCocoaSecureTextField.GetFieldEditor: TCocoaFieldEditor;
var
  lFieldEditor: TCocoaFieldEditor;
  lText: NSText;
begin
  Result := nil;
  if window = nil then Exit;
  lText := window.fieldEditor_forObject(True, Self);
  if (lText <> nil) and lText.isKindOfClass_(TCocoaFieldEditor) then
  begin
    Result := TCocoaFieldEditor(lText);
  end;
end;

function TCocoaSecureTextField.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaSecureTextField.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  callback.BecomeFirstResponder;
end;

function TCocoaSecureTextField.RealResignFirstResponder: Boolean;
begin
  callback.ResignFirstResponder;
  Result := True;
end;

function TCocoaSecureTextField.resignFirstResponder: Boolean;
var
  lFieldEditor: TCocoaFieldEditor;
begin
  //DebugLn('[TCocoaTextField.resignFirstResponder]');
  Result := inherited resignFirstResponder;
  lFieldEditor := GetFieldEditor();
  if (lFieldEditor <> nil) then
  begin
    lFieldEditor.lastEditBox := Self;
  end;
end;

procedure TCocoaSecureTextField.resetCursorRects;
begin
  if not callback.resetCursorRects then
    inherited resetCursorRects;
end;

procedure TCocoaSecureTextField.keyUp(event: NSEvent);
begin
  if Assigned(callback) then
  begin
    // NSTextField doesn't provide keyDown, so emulate it here
    callback.KeyEvent(event, True);
    // keyUp now
    callback.KeyEvent(event);
  end;
  inherited keyUp(event);
end;

{ TCocoaCustomControl }

function TCocoaCustomControl.lclIsHandle: Boolean;
begin
  Result := True;
end;

function TCocoaCustomControl.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaCustomControl.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  if Assigned(callback) then
    callback.BecomeFirstResponder;
end;

function TCocoaCustomControl.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  if Assigned(callback) then
    callback.ResignFirstResponder;
end;

procedure TCocoaCustomControl.drawRect(dirtyRect: NSRect);
begin
  inherited drawRect(dirtyRect);

  // Implement Color property
  if Assigned(callback) then
    callback.DrawBackground(NSGraphicsContext.currentContext, bounds, dirtyRect);

  if CheckMainThread and Assigned(callback) then
    callback.Draw(NSGraphicsContext.currentContext, bounds, dirtyRect);
end;

function TCocoaCustomControl.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaCustomControl.lclClearCallback;
begin
  callback := nil;
end;

procedure TCocoaCustomControl.mouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited mouseDown(event);
end;

procedure TCocoaCustomControl.mouseDragged(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseMove(event) then
    inherited mouseDragged(event);
end;

procedure TCocoaCustomControl.mouseEntered(event: NSEvent);
begin
  inherited mouseEntered(event);
end;

procedure TCocoaCustomControl.mouseExited(event: NSEvent);
begin
  inherited mouseExited(event);
end;

procedure TCocoaCustomControl.mouseMoved(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseMove(event) then
    inherited mouseMoved(event);
end;

procedure TCocoaCustomControl.scrollWheel(event: NSEvent);
begin
  if not Assigned(callback) or not callback.scrollWheel(event) then
    inherited scrollWheel(event);
end;

procedure TCocoaCustomControl.keyDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.KeyEvent(event) then
    inherited keyDown(event);
end;

procedure TCocoaCustomControl.keyUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.KeyEvent(event) then
    inherited keyUp(event);
end;

procedure TCocoaCustomControl.flagsChanged(event: NSEvent);
begin
  if not Assigned(callback) or not callback.KeyEvent(event) then
    inherited flagsChanged(event);
end;

procedure TCocoaCustomControl.mouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited mouseUp(event);
end;

procedure TCocoaCustomControl.rightMouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited rightMouseDown(event);
end;

procedure TCocoaCustomControl.rightMouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited rightMouseUp(event);
end;

procedure TCocoaCustomControl.rightMouseDragged(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseMove(event) then
    inherited rightMouseDragged(event);
end;

procedure TCocoaCustomControl.otherMouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited otherMouseDown(event);
end;

procedure TCocoaCustomControl.otherMouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited otherMouseUp(event);
end;

procedure TCocoaCustomControl.otherMouseDragged(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseMove(event) then
    inherited otherMouseDragged(event);
end;

procedure TCocoaCustomControl.resetCursorRects;
begin
  if not Assigned(callback) or not callback.resetCursorRects then
    inherited resetCursorRects;
end;

{ LCLObjectExtension }

function LCLObjectExtension.lclIsEnabled: Boolean;
begin
  Result := False;
end;

procedure LCLObjectExtension.lclSetEnabled(AEnabled: Boolean);
begin
end;

function LCLObjectExtension.lclIsVisible: Boolean;
begin
  Result := False;
end;

procedure LCLObjectExtension.lclSetVisible(AVisible: Boolean);
begin
end;

function LCLObjectExtension.lclWindowState: Integer;
begin
  Result := SIZE_RESTORED;
end;

procedure LCLObjectExtension.lclInvalidateRect(const r: TRect);
begin
end;

procedure LCLObjectExtension.lclInvalidate;
begin
end;

procedure LCLObjectExtension.lclUpdate;
begin
end;

procedure LCLObjectExtension.lclRelativePos(var Left,Top: Integer);
begin
end;

procedure LCLObjectExtension.lclLocalToScreen(var X,Y: Integer);
begin
end;

procedure LCLObjectExtension.lclScreenToLocal(var X, Y: Integer);
begin
end;

function LCLObjectExtension.lclParent:id;
begin
  Result:=nil;
end;

function LCLObjectExtension.lclFrame:TRect;
begin
  FillChar(Result, sizeof(Result), 0);
end;

procedure LCLObjectExtension.lclSetFrame(const r:TRect);
begin

end;

function LCLObjectExtension.lclClientFrame:TRect;
begin
  FillChar(Result, sizeof(Result), 0);
end;

function LCLObjectExtension.lclGetCallback: ICommonCallback;
begin
  Result := nil;
end;

procedure LCLObjectExtension.lclClearCallback;
begin
end;

function LCLObjectExtension.lclGetPropStorage: TStringList;
var
  Callback: ICommonCallback;
begin
  Callback := lclGetCallback;
  if Assigned(Callback) then
    Result := Callback.GetPropStorage
  else
    Result := nil;
end;

function LCLObjectExtension.lclGetTarget: TObject;
var
  Callback: ICommonCallback;
begin
  Callback := lclGetCallback;
  if Assigned(Callback) then
    Result := Callback.GetTarget
  else
    Result := nil;
end;

function LCLObjectExtension.lclDeliverMessage(Msg: Cardinal; WParam: WParam; LParam: LParam): LResult;
var
  Callback: ICommonCallback;
begin
  Callback := lclGetCallback;
  if Assigned(Callback) then
    Result := Callback.DeliverMessage(Msg, WParam, LParam)
  else
    Result := 0;
end;

function LCLObjectExtension.lclIsHandle: Boolean;
begin
result:=false;
end;

{ LCLControlExtension }

function RectToViewCoord(view: NSView; const r: TRect): NSRect;
var
  b: NSRect;
begin
  if not Assigned(view) then Exit;
  b := view.bounds;
  with r do
  begin
    Result.origin.x := Left;
    Result.origin.y := b.size.height - Bottom;
    Result.size.width := Right - Left;
    Result.size.height := Bottom - Top;
  end;
end;

function LCLControlExtension.lclIsEnabled:Boolean;
begin
  Result := IsEnabled;
  if Result and CocoaWidgetSet.IsControlDisabledDueToModal(Self) then Result := False;
end;

procedure LCLControlExtension.lclSetEnabled(AEnabled:Boolean);
begin
  SetEnabled(AEnabled);
end;

function LCLViewExtension.lclInitWithCreateParams(const AParams: TCreateParams): id;
var
  p: NSView;
  ns: NSRect;
  {$IFDEF COCOA_DEBUG_SETBOUNDS}
  pstr: string;
  {$ENDIF}
begin
  p := nil;
  if (AParams.WndParent <> 0) then
    p := CocoaUtils.GetNSObjectView(NSObject(AParams.WndParent));

  if Assigned(p) then
    LCLToNSRect(Types.Bounds(AParams.X, AParams.Y, AParams.Width, AParams.Height),
      p.frame.size.height, ns)
  else
    ns := GetNSRect(AParams.X, AParams.Y, AParams.Width, AParams.Height);

  {$IFDEF COCOA_DEBUG_SETBOUNDS}
  if Assigned(p) then
  begin
    pstr := NSStringToString(p.className);
    if NSStringToString(NSObject(AParams.WndParent).className) = 'TCocoaTabPage' then
      pstr := pstr + ' ' + NSStringToString(TCocoaTabPage(AParams.WndParent).label_);
  end
  else
    pstr := '';
  WriteLn(Format('[LCLViewExtension.lclInitWithCreateParams] Class=%s Caption=%s ParentClass=%s ParentClassView=%s rect=%d %d %d %d Visible=%d',
    [NSStringToString(Self.className), AParams.Caption,
     NSStringToString(NSObject(AParams.WndParent).className), pstr,
     Round(ns.Origin.x), Round(ns.Origin.y), Round(ns.size.width), Round(ns.size.height),
     AParams.Style and WS_VISIBLE]));
  {$ENDIF}

  Result := initWithFrame(ns);
  if not Assigned(Result) then
    Exit;

  setHidden(AParams.Style and WS_VISIBLE = 0);

  if Assigned(p) then
    p.addSubview(Result);
  SetViewDefaults(Result);
end;

function LCLViewExtension.lclIsVisible: Boolean;
begin
  Result := not isHidden;
end;

procedure LCLViewExtension.lclSetVisible(AVisible: Boolean);
begin
  setHidden(not AVisible);
  {$IFDEF COCOA_DEBUG_SETBOUNDS}
  WriteLn(Format('LCLViewExtension.lclSetVisible: %s AVisible=%d',
    [NSStringToString(Self.ClassName), Integer(AVisible)]));
  {$ENDIF}
end;

function LCLViewExtension.lclIsPainting: Boolean;
begin
  Result := Assigned(lclGetCallback) and Assigned(lclGetCallback.GetContext);
end;

procedure LCLViewExtension.lclInvalidateRect(const r:TRect);
begin
  setNeedsDisplayInRect(RectToViewCoord(Self, r));
end;

procedure LCLViewExtension.lclInvalidate;
begin
  setNeedsDisplay_(True);
end;

procedure LCLViewExtension.lclUpdate;
begin
  display;
end;

procedure LCLViewExtension.lclRelativePos(var Left, Top: Integer);
begin
  with frame.origin do
  begin
    Left := Round(x);
    Top := Round(y);
  end;
end;

procedure LCLViewExtension.lclLocalToScreen(var X, Y:Integer);
var
  P: NSPoint;

begin
  // 1. convert to window base
  P.x := X;
  P.y := frame.size.height-y;   // convert to Cocoa system
  P := convertPoint_ToView(P, nil);

  X := Round(P.X);
  Y := Round(window.frame.size.height-P.Y); // convert to LCL system

  // 2. convert window to screen
  window.lclLocalToScreen(X, Y);
end;

procedure LCLViewExtension.lclScreenToLocal(var X, Y: Integer);
var
  P: NSPoint;
begin
  // 1. convert from screen to window

  window.lclScreenToLocal(X, Y);
  P.x := X;
  P.y := Round(window.frame.size.height-Y); // convert to Cocoa system

  // 2. convert from window to local
  P := convertPoint_FromView(P, nil);
  X := Round(P.x);
  Y := Round(frame.size.height-P.y);   // convert to Cocoa system
end;

function LCLViewExtension.lclParent:id;
begin
  Result := superView;
end;

function LCLViewExtension.lclFrame: TRect;
var
  v: NSView;
begin
  v := superview;
  if Assigned(v) then
    NSToLCLRect(frame, v.frame.size.height, Result)
  else
    Result := NSRectToRect(frame);
end;

procedure LCLViewExtension.lclSetFrame(const r: TRect);
var
  ns: NSRect;
  svHeight: CGFloat;
begin
  svHeight := GetNSViewSuperViewHeight(Self);
  if Assigned(superview)  then
  begin
    LCLToNSRect(r, svHeight, ns)
  end
  else
    ns := RectToNSRect(r);
  {$IFDEF COCOA_DEBUG_SETBOUNDS}
  WriteLn(Format('LCLViewExtension.lclSetFrame: %s Bounds=%s height=%d ns_pos=%d %d ns_size=%d %d',
    [NSStringToString(Self.ClassName), dbgs(r), Round(svHeight),
     Round(ns.origin.x), Round(ns.origin.y), Round(ns.size.width), Round(ns.size.height)]));
  {$ENDIF}
  setFrame(ns);
end;

function LCLViewExtension.lclClientFrame: TRect;
var
  r: NSRect;
begin
  r := bounds;
  with Result do
  begin
    Left := 0;
    Top := 0;
    Right := Round(r.size.width);
    Bottom := Round(r.size.height);
  end;
end;


{ LCLWindowExtension }

function LCLWindowExtension.lclIsVisible: Boolean;
begin
  Result := isVisible;
end;

procedure LCLWindowExtension.lclSetVisible(AVisible: Boolean);
begin
  if AVisible then
    orderFrontRegardless
  else
    orderOut(nil);
end;

function LCLWindowExtension.lclIsEnabled: Boolean;
begin
  Result := contentView.lclIsEnabled;
end;

procedure LCLWindowExtension.lclSetEnabled(AEnabled: Boolean);
begin
  contentView.lclSetEnabled(AEnabled);
end;

function LCLWindowExtension.lclWindowState: Integer;
const
  NSFullScreenWindowMask = 1 shl 14;
begin
  if isMiniaturized then
    Result := SIZE_MINIMIZED
  else
  if (styleMask and NSFullScreenWindowMask) <> 0 then
    Result := SIZE_FULLSCREEN
  else
  if isZoomed then
    Result := SIZE_MAXIMIZED
  else
    Result := SIZE_RESTORED;
end;

procedure LCLWindowExtension.lclInvalidateRect(const r: TRect);
begin
  contentView.lclInvalidateRect(r);
end;

procedure LCLWindowExtension.lclInvalidate;
begin
  contentView.lclInvalidate;
end;

procedure LCLWindowExtension.lclUpdate;
begin
  contentView.lclUpdate;
end;

procedure LCLWindowExtension.lclRelativePos(var Left, Top: Integer);
var
   f: NSRect;
begin
  if Assigned(screen) then
  begin
    f:=frame;
    Left := Round(f.origin.x);
    Top := Round(screen.frame.size.height - f.size.height - f.origin.y);
    //debugln('Top:'+dbgs(Top));
  end;
end;

procedure LCLWindowExtension.lclLocalToScreen(var X, Y:Integer);
var
  f: NSRect;
begin
  if Assigned(screen) then
  begin
    f := frame;
    inc(X, Round(f.origin.x));
    inc(Y, Round(screen.frame.size.height - f.size.height - f.origin.y));
  end;
end;

procedure LCLWindowExtension.lclScreenToLocal(var X, Y: Integer);
var
  f: NSRect;
begin
  if Assigned(screen) then
  begin
    f := frame;
    dec(X, Round(f.origin.x));
    dec(Y, Round(screen.frame.size.height - f.size.height - f.origin.y));
  end;
end;

function LCLWindowExtension.lclFrame: TRect;
begin
  if Assigned(screen) then
    NSToLCLRect(frame, screen.frame.size.height, Result)
  else
    Result := NSRectToRect(frame);
end;

function LCLWindowExtension.lclGetTopBarHeight:integer;
var nw,nf: NSRect;
begin
  nf:= NSMakeRect (0, 0, 100, 100);
  nw:=contentRectForFrameRect(nf);
  result:=round(nf.size.height-nw.size.height);
end;

procedure LCLWindowExtension.lclSetFrame(const r: TRect);
var
  ns: NSRect;
  h:integer;
begin
  if Assigned(screen) then
    LCLToNSRect(r, screen.frame.size.height, ns)
  else
    ns := RectToNSRect(r);

  // add topbar height
  h:=lclGetTopBarHeight;
  ns.size.height:=ns.size.height+h;
  ns.origin.y:=ns.origin.y-h;
  setFrame_display(ns, isVisible);
end;

function LCLWindowExtension.lclClientFrame: TRect;
var
  wFrame, cFrame: NSRect;
begin
  wFrame := frame;
  cFrame := contentRectForFrameRect(wFrame);
  with Result do
  begin
    Left := Round(cFrame.origin.x - wFrame.origin.x);
    Top := Round(wFrame.origin.y + wFrame.size.height - cFrame.origin.y - cFrame.size.height);
    Right := Left + Round(cFrame.size.width);
    Bottom := Top + Round(cFrame.size.height);
  end;
end;

{ TCocoaListBox }

function TCocoaListBox.lclIsHandle: Boolean;
begin
  Result:=true;
end;

function TCocoaListBox.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaListBox.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  callback.BecomeFirstResponder;
end;

function TCocoaListBox.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  callback.ResignFirstResponder;
end;

function TCocoaListBox.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaListBox.lclClearCallback;
begin
  callback := nil;
end;

function TCocoaListBox.numberOfRowsInTableView(aTableView:NSTableView): NSInteger;
begin
  if Assigned(list) then
    Result := list.Count
  else
    Result := 0;
end;


function TCocoaListBox.tableView_shouldEditTableColumn_row(tableView: NSTableView; tableColumn: NSTableColumn; row: NSInteger): Boolean;
begin
  Result := False;  // disable cell editing by default
end;

function TCocoaListBox.tableView_objectValueForTableColumn_row(tableView: NSTableView;
  objectValueForTableColumn: NSTableColumn; row: NSInteger):id;
begin
  //WriteLn('TCocoaListBox.tableView_objectValueForTableColumn_row');
  if not Assigned(list) then
    Result:=nil
  else
  begin
    if row>=list.count then
      Result := nil
    else
    begin
      resultNS.release;
      resultNS := NSStringUtf8(list[row]);
      Result := ResultNS;
    end;
  end;
end;

procedure TCocoaListBox.dealloc;
begin
  FreeAndNil(list);
  resultNS.release;
  inherited dealloc;
end;

procedure TCocoaListBox.resetCursorRects;
begin
  if not callback.resetCursorRects then
    inherited resetCursorRects;
end;

procedure TCocoaListBox.tableViewSelectionDidChange(notification: NSNotification);
begin
  if Assigned(callback) then
    callback.SelectionChanged;
end;

procedure TCocoaListBox.mouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited mouseDown(event);
end;

procedure TCocoaListBox.rightMouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited rightMouseDown(event);
end;

procedure TCocoaListBox.rightMouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited rightMouseUp(event);
end;

procedure TCocoaListBox.otherMouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited otherMouseDown(event);
end;

procedure TCocoaListBox.otherMouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited otherMouseUp(event);
end;

procedure TCocoaListBox.mouseDragged(event: NSEvent);
begin
if not Assigned(callback) or not callback.MouseMove(event) then
  inherited mouseDragged(event);
end;

procedure TCocoaListBox.mouseEntered(event: NSEvent);
begin
  inherited mouseEntered(event);
end;

procedure TCocoaListBox.mouseExited(event: NSEvent);
begin
  inherited mouseExited(event);
end;

procedure TCocoaListBox.mouseMoved(event: NSEvent);
begin
  inherited mouseMoved(event);
end;

procedure TCocoaListBox.keyDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.KeyEvent(event) then
    inherited keyDown(event);
end;

procedure TCocoaListBox.keyUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.KeyEvent(event) then
    inherited keyUp(event);
end;

{ TCocoaCheckListBox }

class function TCocoaCheckListBox.LCLCheckStateToCocoa(ALCLState: TCheckBoxState): NSInteger;
begin
  case ALCLState of
  cbChecked: Result := NSOnState;
  cbGrayed:  Result := NSMixedState;
  else // cbUnchecked
    Result := NSOffState;
  end;
end;

class function TCocoaCheckListBox.CocoaCheckStateToLCL(ACocoaState: NSInteger): TCheckBoxState;
begin
  case ACocoaState of
  NSOnState:    Result := cbChecked;
  NSMixedState: Result := cbGrayed;
  else // NSOffState
    Result := cbUnchecked;
  end;
end;

function TCocoaCheckListBox.CheckListBoxGetNextState(ACurrent: TCheckBoxState): TCheckBoxState;
begin
  case ACurrent of
  cbChecked: Result := cbUnchecked;
  cbGrayed:  Result := cbChecked;
  else // cbUnchecked
    if AllowMixedState then
      Result := cbGrayed
    else
      Result := cbChecked;
  end;
end;

function TCocoaCheckListBox.GetCocoaState(const AIndex: integer): NSInteger;
begin
  Result := NSInteger(list.Objects[AIndex]);
end;

procedure TCocoaCheckListBox.SetCocoaState(const AIndex: integer; AState: NSInteger);
begin
  list.Objects[AIndex] := TObject(AState);
end;

function TCocoaCheckListBox.GetState(const AIndex: integer): TCheckBoxState;
var
  lInt: NSInteger;
begin
  lInt := GetCocoaState(AIndex);
  Result := CocoaCheckStateToLCL(lInt);
end;

procedure TCocoaCheckListBox.SetState(const AIndex: integer; AState: TCheckBoxState);
begin
  SetCocoaState(AIndex, LCLCheckStateToCocoa(AState));
end;

function TCocoaCheckListBox.tableView_objectValueForTableColumn_row(tableView: NSTableView;
  objectValueForTableColumn: NSTableColumn; row: NSInteger):id;
var
  lInt: NSInteger;
begin
  //WriteLn('[TCocoaCheckListBox.tableView_objectValueForTableColumn_row] row='+IntToStr(row));
  if not Assigned(list) then
    Exit(nil);

  if row>=list.count then
    Exit(nil);

  // Returns if the state is checked or unchecked
  lInt := GetCocoaState(row);
  Result := NSNumber.numberWithInteger(lInt);
end;

procedure TCocoaCheckListBox.tableView_setObjectValue_forTableColumn_row(tableView: NSTableView;
  object_: id; tableColumn: NSTableColumn; row: NSInteger);
begin
  //WriteLn('[TCocoaCheckListBox.tableView_setObjectValue_forTableColumn_row] row='+IntToStr(row));
  SetState(row, CheckListBoxGetNextState(GetState(row)));
end;

function TCocoaCheckListBox.tableView_dataCellForTableColumn_row(tableView: NSTableView;
  tableColumn: NSTableColumn; row: NSInteger): NSCell;
var
  lNSString: NSString;
begin
  Result := NSButtonCell.alloc.init.autorelease;
  Result.setAllowsMixedState(True);
  NSButtonCell(Result).setButtonType(NSSwitchButton);

  lNSString := NSStringUtf8(list[row]);
  NSButtonCell(Result).setTitle(lNSString);
  lNSString.release;
end;

{ TCocoaTabPage }

function TCocoaTabPage.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaTabPage.lclClearCallback;
begin
  callback := nil;
end;

function TCocoaTabPage.lclFrame: TRect;
var
  svh: CGFloat;
  lParent: TCocoaTabControl;
begin
  lParent := TCocoaWSCustomTabControl.GetCocoaTabControlHandle(LCLParent);
  if lParent <> nil then
  begin
    svh := lParent.contentRect.size.height;
    NSToLCLRect(lParent.contentRect, svh, Result);
  end
  else
  begin
    svh := tabView.frame.size.height;
    NSToLCLRect(tabView.contentRect, svh, Result);
  end;
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn('[TCocoaTabPage.lclFrame] '+dbgs(Result)+' '+NSStringToString(Self.label_));
  {$ENDIF}
end;

function TCocoaTabPage.lclClientFrame: TRect;
begin
  Result := lclFrame();
end;

{ TCocoaTabControl }

function TCocoaTabControl.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaTabControl.lclClearCallback;
begin
  callback := nil;
end;

function TCocoaTabControl.tabView_shouldSelectTabViewItem(tabView: NSTabView;
  tabViewItem: NSTabViewItem): Boolean;
begin
  Result := True;
end;

procedure TCocoaTabControl.tabView_willSelectTabViewItem(tabView: NSTabView;
  tabViewItem: NSTabViewItem);
var
  Msg: TLMNotify;
  Hdr: TNmHdr;
begin
  if LCLPageControl = nil then Exit;

  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := LM_NOTIFY;
  FillChar(Hdr, SizeOf(Hdr), 0);

  Hdr.hwndFrom := HWND(tabview);
  Hdr.Code := TCN_SELCHANGING;
  Hdr.idFrom := PtrUInt(tabview.indexOfTabViewItem(tabViewItem));
  Msg.NMHdr := @Hdr;
  Msg.Result := 0;
  LCLMessageGlue.DeliverMessage(LCLPageControl, Msg);
end;

procedure TCocoaTabControl.tabView_didSelectTabViewItem(tabView: NSTabView;
  tabViewItem: NSTabViewItem);
var
  Msg: TLMNotify;
  Hdr: TNmHdr;
begin
  if LCLPageControl = nil then Exit;

  FillChar(Msg, SizeOf(Msg), 0);
  Msg.Msg := LM_NOTIFY;
  FillChar(Hdr, SizeOf(Hdr), 0);

  Hdr.hwndFrom := HWND(tabview);
  Hdr.Code := TCN_SELCHANGE;
  Hdr.idFrom := PtrUInt(tabview.indexOfTabViewItem(tabViewItem));
  Msg.NMHdr := @Hdr;
  Msg.Result := 0;
  LCLMessageGlue.DeliverMessage(LCLPageControl, Msg);
end;

procedure TCocoaTabControl.tabViewDidChangeNumberOfTabViewItems(
  TabView: NSTabView);
begin

end;

{ TCocoaTableListView }

function TCocoaTableListView.lclIsHandle: Boolean;
begin
  Result:=true;
end;

function TCocoaTableListView.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaTableListView.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  callback.BecomeFirstResponder;
end;

function TCocoaTableListView.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  callback.ResignFirstResponder;
end;

function TCocoaTableListView.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaTableListView.lclClearCallback;
begin
  callback := nil;
end;

procedure TCocoaTableListView.dealloc;
begin
  if Assigned(Items) then FreeAndNil(Items);
  inherited dealloc;
end;

procedure TCocoaTableListView.resetCursorRects;
begin
  if not callback.resetCursorRects then
    inherited resetCursorRects;
end;

procedure TCocoaTableListView.setStringValue_forCol_row(
  AStr: NSString; col, row: NSInteger);
var
  lStringList: TStringList;
  lStr: string;
begin
  lStr := NSStringToString(AStr);
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn(Format('[TCocoaTableListView.setStringValue_forTableColumn_row] AStr=%s col=%d row=%d Items.Count=%d',
    [lStr, col, row, Items.Count]));
  {$ENDIF}

  // make sure we have enough lines
  while (row >= Items.Count) do
  begin
    {$IFDEF COCOA_DEBUG_TABCONTROL}
    WriteLn(Format('[TCocoaTableListView.setStringValue_forTableColumn_row] Adding line', []));
    {$ENDIF}
    Items.AddObject('', TStringList.Create());
  end;

  // Now write it
  if col = 0 then
    Items.Strings[row] := lStr
  else
  begin
    lStringList := TStringList(Items.Objects[row]);
    if lStringList = nil then
    begin
      lStringList := TStringList.Create;
      Items.Objects[row] := lStringList;
    end;

    // make sure we have enough columns
    while (col-1 >= lStringList.Count) do
    begin
      {$IFDEF COCOA_DEBUG_TABCONTROL}
      WriteLn(Format('[TCocoaTableListView.setStringValue_forTableColumn_row] Adding column', []));
      {$ENDIF}
      lStringList.Add('');
    end;

    lStringList.Strings[col-1] := lStr;
  end;
end;

procedure TCocoaTableListView.deleteItemForRow(row: NSInteger);
var
  lStringList: TStringList;
begin
  lStringList := TStringList(Items.Objects[row]);
  if lStringList <> nil then lStringList.Free;
  Items.Delete(row);
end;

procedure TCocoaTableListView.setListViewStringValue_forCol_row(
  AStr: NSString; col, row: NSInteger);
var
  lSubItems: TStrings;
  lItem: TListItem;
  lNewValue: string;
begin
  lNewValue := NSStringToString(AStr);
  if ListView.ReadOnly then Exit;

  if row >= ListView.Items.Count then Exit;
  lItem := ListView.Items.Item[row];

  if col = 0 then
  begin
    lItem.Caption := lNewValue;
  end
  else if col > 0 then
  begin
    lSubItems := lItem.SubItems;
    if col >= lSubItems.Count+1 then Exit;
    lSubItems.Strings[col-1] := lNewValue;
  end;
end;

function TCocoaTableListView.getIndexOfColumn(ACol: NSTableColumn): NSInteger;
begin
  Result := tableColumns.indexOfObject(ACol);
end;

procedure TCocoaTableListView.reloadDataForRow_column(ARow, ACol: NSInteger);
var
  lRowSet, lColSet: NSIndexSet;
begin
  lRowSet := NSIndexSet.indexSetWithIndex(ARow);
  lColSet := NSIndexSet.indexSetWithIndex(ACol);
  reloadDataForRowIndexes_columnIndexes(lRowSet, lColSet);
end;

procedure TCocoaTableListView.scheduleSelectionDidChange;
begin
  if Timer = nil then Timer := TTimer.Create(nil);
  Timer.Interval := 1;
  Timer.Enabled := True;
  Timer.OnTimer := @callback.delayedSelectionDidChange_OnTimer;
end;

procedure TCocoaTableListView.mouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited mouseDown(event);
end;

procedure TCocoaTableListView.rightMouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited rightMouseDown(event);
end;

procedure TCocoaTableListView.rightMouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited rightMouseUp(event);
end;

procedure TCocoaTableListView.otherMouseDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited otherMouseDown(event);
end;

procedure TCocoaTableListView.otherMouseUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseUpDownEvent(event) then
    inherited otherMouseUp(event);
end;

procedure TCocoaTableListView.mouseDragged(event: NSEvent);
begin
  if not Assigned(callback) or not callback.MouseMove(event) then
    inherited mouseDragged(event);
end;

procedure TCocoaTableListView.mouseEntered(event: NSEvent);
begin
  inherited mouseEntered(event);
end;

procedure TCocoaTableListView.mouseExited(event: NSEvent);
begin
  inherited mouseExited(event);
end;

procedure TCocoaTableListView.mouseMoved(event: NSEvent);
begin
  inherited mouseMoved(event);
end;

procedure TCocoaTableListView.keyDown(event: NSEvent);
begin
  if not Assigned(callback) or not callback.KeyEvent(event) then
    inherited keyDown(event);
end;

procedure TCocoaTableListView.keyUp(event: NSEvent);
begin
  if not Assigned(callback) or not callback.KeyEvent(event) then
    inherited keyUp(event);
end;

function TCocoaTableListView.numberOfRowsInTableView(tableView: NSTableView
  ): NSInteger;
begin
  if Assigned(Items) then
    Result := Items.Count
  else
    Result := 0;
end;

function TCocoaTableListView.tableView_objectValueForTableColumn_row(
  tableView: NSTableView; tableColumn: NSTableColumn; row: NSInteger): id;
var
  lStringList: TStringList;
  col: NSInteger;
  StrResult: NSString;
begin
  col := tableColumns.indexOfObject(tableColumn);
  {$IFDEF COCOA_DEBUG_TABCONTROL}
  WriteLn(Format('[TCocoaTableListView.tableView_objectValueForTableColumn_row] col=%d row=%d Items.Count=%d',
    [col, row, Items.Count]));
  {$ENDIF}
  if row > Items.Count-1 then Exit;
  if col = 0 then
    StrResult := NSStringUTF8(Items.Strings[row])
  else
  begin
    lStringList := TStringList(Items.Objects[row]);
    StrResult := NSStringUTF8(lStringList.Strings[col-1]);
  end;
  Result := StrResult;
end;

procedure TCocoaTableListView.tableView_setObjectValue_forTableColumn_row(
  tableView: NSTableView; object_: id; tableColumn: NSTableColumn;
  row: NSInteger);
var
  lColumnIndex: NSInteger;
  lNewValue: NSString;
begin
  //WriteLn('[TCocoaTableListView.tableView_setObjectValue_forTableColumn_row]');
  lNewValue := NSString(object_);
  if not NSObject(object_).isKindOfClass(NSString) then Exit;
  //WriteLn('[TCocoaTableListView.tableView_setObjectValue_forTableColumn_row] A');
  if ListView.ReadOnly then Exit;

  lColumnIndex := getIndexOfColumn(tableColumn);

  setListViewStringValue_forCol_row(lNewValue, lColumnIndex, row);
  setStringValue_forCol_row(lNewValue, lColumnIndex, row);
  reloadDataForRow_column(lColumnIndex, row);
end;

function TCocoaTableListView.tableView_shouldEditTableColumn_row(tableView: NSTableView; tableColumn: NSTableColumn; row: NSInteger): Boolean;
begin
  Result := not ListView.ReadOnly;
end;

procedure TCocoaTableListView.tableViewSelectionDidChange(notification: NSNotification);
var
  Msg: TLMNotify;
  NMLV: TNMListView;
  OldSel, NewSel: Integer;
begin
  NewSel := Self.selectedRow();
  {$IFDEF COCOA_DEBUG_LISTVIEW}
  WriteLn(Format('[TLCLListViewCallback.SelectionChanged] NewSel=%d', [NewSel]));
  {$ENDIF}

  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  FillChar(NMLV{%H-}, SizeOf(NMLV), #0);

  Msg.Msg := CN_NOTIFY;

  NMLV.hdr.hwndfrom := ListView.Handle;
  NMLV.hdr.code := LVN_ITEMCHANGED;
  NMLV.iSubItem := 0;
  NMLV.uChanged := LVIF_STATE;
  Msg.NMHdr := @NMLV.hdr;

  if NewSel >= 0 then
  begin
    NMLV.iItem := NewSel;
    NMLV.uNewState := LVIS_SELECTED;
  end
  else
  begin
    NMLV.iItem := 0;
    NMLV.uNewState := 0;
    NMLV.uOldState := LVIS_SELECTED;
  end;

  LCLMessageGlue.DeliverMessage(ListView, Msg);
end;

{ TCocoaStringList }

procedure TCocoaStringList.Changed;
begin
  inherited Changed;
  Owner.reloadData;
end;

constructor TCocoaStringList.Create(AOwner:TCocoaListBox);
begin
  Owner:=AOwner;
  inherited Create;
end;

{ TCocoaStatusBar }

procedure TCocoaStatusBar.drawRect(dirtyRect: NSRect);
var
  R    : TRect;
  i    : Integer;
  txt  : NSString;
  nr   : NSRect;
  x    : Integer;
const
  CocoaAlign: array [TAlignment] of Integer = (NSNaturalTextAlignment, NSRightTextAlignment, NSCenterTextAlignment);
begin
  //inherited NSControl.drawRect(dirtyRect);
  if callback = nil then Exit;

  if not Assigned(panelCell) then Exit;

  panelCell.setControlView(Self);
  FillChar(nr, sizeof(nr), 0);

  r := lclClientFrame();
  nr.size.height := StatusBar.Height+5; // it gets closer to filling the whole area with +5 no idea why

  if StatusBar.SimplePanel then
  begin
    nr.size.width := r.Right-r.Left;
    txt := NSStringUtf8(StatusBar.SimpleText);
    panelCell.setAlignment( NSNaturalTextAlignment );
    panelCell.setTitle( txt );
    panelCell.drawWithFrame_inView(nr, Self);
    txt.release;
  end
  else
  begin
    x:=0;
    for i:=0 to StatusBar.Panels.Count-1 do
    begin
      if i=StatusBar.Panels.Count-1 then
        nr.size.width := r.Right-x+1
      else
        nr.size.width := StatusBar.Panels[i].Width+1;
      nr.origin.x := x;
      inc(x, StatusBar.Panels[i].Width);
      txt := NSStringUtf8(StatusBar.Panels[i].Text);
      panelCell.setTitle(txt);
      panelCell.setAlignment(CocoaAlign[StatusBar.Panels[i].Alignment]);
      panelCell.drawWithFrame_inView(nr, Self);
      txt.release;
    end;
  end;
end;

procedure TCocoaStatusBar.dealloc;
begin
  if Assigned(panelCell) then panelCell.release;
  inherited;
end;

{ TCocoaComboBoxList }

procedure TCocoaComboBoxList.Changed;
var
  i: Integer;
  nsstr: NSString;
  lCurItem: NSMenuItem;
begin
  if FOwner <> nil then
    fOwner.reloadData;
  if FReadOnlyOwner <> nil then
  begin
    // store the current item
    FReadOnlyOwner.lastSelectedItemIndex := FReadOnlyOwner.indexOfSelectedItem;

    FReadOnlyOwner.removeAllItems();
    for i := 0 to Count-1 do
    begin
      nsstr := NSStringUtf8(Strings[i]);
      FReadOnlyOwner.addItemWithTitle(nsstr);
      nsstr.release;
    end;

    // reset the selected item
    FReadOnlyOwner.selectItemAtIndex(FReadOnlyOwner.lastSelectedItemIndex);
  end;
  inherited Changed;
end;

procedure TCocoaComboBoxList.Changing;
begin
  FPreChangeListCount := Count;
end;

constructor TCocoaComboBoxList.Create(AOwner: TCocoaComboBox; AReadOnlyOwner: TCocoaReadOnlyComboBox);
begin
  FOwner := AOwner;
  FReadOnlyOwner := AReadOnlyOwner;
end;

{ TCocoaComboBox }

function TCocoaComboBox.lclIsHandle: Boolean;
begin
  Result:=true;
end;

function TCocoaComboBox.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaComboBox.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  callback.BecomeFirstResponder;
end;

function TCocoaComboBox.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  callback.ResignFirstResponder;
end;

function TCocoaComboBox.comboBox_objectValueForItemAtIndex_(combo:TCocoaComboBox;
  row: NSInteger):id;
begin
  if not Assigned(list) or (row<0) or (row>=list.Count)
    then Result:=nil
    else Result:=NSStringUtf8(list[row]);
end;

function TCocoaComboBox.numberOfItemsInComboBox(combo:TCocoaComboBox):NSInteger;
begin
  if not Assigned(list) then Result:=0
  else Result:=list.Count;
end;

procedure TCocoaComboBox.dealloc;
begin
  if Assigned(list) then
  begin
    list.Free;
    list:=nil;
  end;
  resultNS.release;
  inherited dealloc;
end;

function TCocoaComboBox.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaComboBox.lclClearCallback;
begin
  callback := nil;
end;

procedure TCocoaComboBox.resetCursorRects;
begin
  if not callback.resetCursorRects then
    inherited resetCursorRects;
end;

procedure TCocoaComboBox.comboBoxWillPopUp(notification: NSNotification);
begin
  callback.ComboBoxWillPopUp;
end;

procedure TCocoaComboBox.comboBoxWillDismiss(notification: NSNotification);
begin
  callback.ComboBoxWillDismiss;
end;

procedure TCocoaComboBox.comboboxSelectionDidChange(notification: NSNotification);
begin
  callback.ComboBoxSelectionDidChange;
end;

procedure TCocoaComboBox.comboBoxSelectionIsChanging(notification: NSNotification);
begin
  callback.ComboBoxSelectionIsChanging;
end;

{ TCocoaReadOnlyComboBox }

function TCocoaReadOnlyComboBox.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaReadOnlyComboBox.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  callback.BecomeFirstResponder;
end;

function TCocoaReadOnlyComboBox.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  callback.ResignFirstResponder;
end;

procedure TCocoaReadOnlyComboBox.dealloc;
begin
  if Assigned(list) then
  begin
    list.Free;
    list:=nil;
  end;
  if resultNS <> nil then
    resultNS.release;
  inherited dealloc;
end;

function TCocoaReadOnlyComboBox.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaReadOnlyComboBox.lclClearCallback;
begin
  callback := nil;
end;

procedure TCocoaReadOnlyComboBox.resetCursorRects;
begin
  if not callback.resetCursorRects then
    inherited resetCursorRects;
end;

function TCocoaReadOnlyComboBox.lclIsHandle: Boolean;
begin
  Result:=true;
end;

procedure TCocoaReadOnlyComboBox.comboBoxAction(sender: id);
begin
  //setTitle(NSSTR(PChar(Format('%d=%d', [indexOfSelectedItem, lastSelectedItemIndex])))); // <= for debugging
  if (indexOfSelectedItem <> lastSelectedItemIndex) and (callback <> nil) then
    callback.ComboBoxSelectionDidChange;
  lastSelectedItemIndex := indexOfSelectedItem;
end;

{ TCocoaProgressIndicator }

function TCocoaProgressIndicator.acceptsFirstResponder: Boolean;
begin
  Result:=True;
end;

function TCocoaProgressIndicator.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  callback.BecomeFirstResponder;
end;

function TCocoaProgressIndicator.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  callback.ResignFirstResponder;
end;

function TCocoaProgressIndicator.lclGetCallback: ICommonCallback;
begin
  Result:=callback;
end;

procedure TCocoaProgressIndicator.lclClearCallback;
begin
  callback:=nil;
end;

procedure TCocoaProgressIndicator.resetCursorRects;
begin
  if not callback.resetCursorRects then
    inherited resetCursorRects;
end;

{ TCocoaSlider }

function TCocoaSlider.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaSlider.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  callback.BecomeFirstResponder;
end;

function TCocoaSlider.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  callback.ResignFirstResponder;
end;

function TCocoaSlider.lclGetCallback: ICommonCallback;
begin
  Result:=callback;
end;

procedure TCocoaSlider.lclClearCallback;
begin
  callback := nil;
end;

procedure TCocoaSlider.resetCursorRects;
begin
  if not callback.resetCursorRects then
    inherited resetCursorRects;
end;

procedure TCocoaSlider.keyDown(event: NSEvent);
var
  KeyCode: word;
begin
  KeyCode := Event.keyCode;
  case KeyCode of
    MK_UP       : SnapToInteger(1);
    MK_DOWN     : SnapToInteger(-1);
    MK_LEFT     : SnapToInteger(-1);
    MK_RIGHT    : SnapToInteger(1);
  else
    // If this isn't done callback.KeyEvent will cause arrow left/right to change control
    if Assigned(callback) then callback.KeyEvent(event)
    else inherited keyDown(event);
  end;
end;

procedure TCocoaSlider.keyUp(event: NSEvent);
var
  KeyCode: word;
begin
  KeyCode := Event.keyCode;
  case KeyCode of
    MK_UP, MK_DOWN, MK_LEFT, MK_RIGHT: inherited keyUp(event);
  else
    // If this isn't done callback.KeyEvent will cause arrow left/right to change control
    if Assigned(callback) then callback.KeyEvent(event)
    else inherited keyUp(event);
  end;
end;

procedure TCocoaSlider.SnapToInteger(AExtraFactor: Integer);
begin
  setIntValue(Round(doubleValue() + AExtraFactor));
end;

procedure TCocoaSlider.sliderAction(sender: id);
begin
  SnapToInteger();
  // OnChange event
  if callback <> nil then
    callback.SendOnChange();
end;

{ TCocoaSpinEdit }

{$IFDEF COCOA_SPINEDIT_INSIDE_CONTAINER}

procedure TCocoaSpinEdit.dealloc;
begin
  if Stepper <> nil then
    Stepper.release;
  if Edit <> nil then
    Edit.release;
  inherited dealloc;
end;

procedure TCocoaSpinEdit.UpdateControl(ASpinEdit: TCustomFloatSpinEdit);
begin
  Stepper.setMaxValue(ASpinEdit.MaxValue);
  Stepper.setMinValue(ASpinEdit.MinValue);
  Stepper.setIncrement(ASpinEdit.Increment);
  Stepper.setDoubleValue(ASpinEdit.Value);

  // update the UI too
  StepperChanged(Self);
end;

procedure TCocoaSpinEdit.CreateSubcontrols(ASpinEdit: TCustomFloatSpinEdit; const AParams: TCreateParams);
var
  lParams: TCreateParams;
  lEditRect, lStepperRect: TRect;
begin
  {$IFDEF COCOA_SPIN_DEBUG}
  WriteLn('[TCocoaSpinEdit.CreateSubcontrols]');
  {$ENDIF}

  Spin := ASpinEdit;
  CalculateSubcontrolPos(Types.Bounds(AParams.X, AParams.Y, AParams.Width,
    AParams.Height), lEditRect, lStepperRect);

  // Now creates the subcontrols
  lParams := AParams;
  lParams.WndParent := HWND(Self);
  lParams.Style := AParams.Style or WS_VISIBLE;

  // Stepper
  lParams.X := lStepperRect.Left;
  lParams.Y := lStepperRect.Top;
  lParams.Width := lStepperRect.Right - lStepperRect.Left;
  lParams.Height := lStepperRect.Bottom - lStepperRect.Top;
  Stepper := NSStepper.alloc.lclInitWithCreateParams(lParams);
  Stepper.setValueWraps(False);

  // Edit
  lParams.X := lEditRect.Left;
  lParams.Y := lEditRect.Top;
  lParams.Width := lEditRect.Right - lEditRect.Left;
  lParams.Height := lEditRect.Bottom - lEditRect.Top;
  Edit := NSTextField.alloc.lclInitWithCreateParams(lParams);

  // Change event for the stepper
  Stepper.setTarget(Self);
  Stepper.setAction(objcselector('StepperChanged:'));
end;

procedure TCocoaSpinEdit.PositionSubcontrols(const ALeft, ATop, AWidth, AHeight: Integer);
var
  lNSStepperRect, lRect: NSRect;
  lStepperRect, lEditRect: TRect;
begin
  {$IFDEF COCOA_SPIN_DEBUG}
  WriteLn('[TCocoaSpinEdit.PositionSubcontrols] AHeight=', AHeight);
  {$ENDIF}

  CalculateSubcontrolPos(Types.Bounds(ALeft, ATop, AWidth, AHeight), lEditRect, lStepperRect);

  // Stepper
  LCLToNSRect(lStepperRect, AHeight, lNSStepperRect);
  Stepper.setBounds(lNSStepperRect);

  // Edit
  LCLToNSRect(lEditRect, AHeight, lRect);
  Edit.setBounds(lRect);

  {$IFDEF COCOA_SPIN_DEBUG}
  WriteLn(':<[TCocoaSpinEdit.PositionSubcontrols] Edit=> X=', lRect.origin.x,
    ' Y=', lRect.origin.y, ' W=', lRect.size.width, ' H=', lRect.size.height,
    ' Stepper X=', lNSStepperRect.origin.x, ' Y=', lNSStepperRect.origin.y,
    ' W=', lNSStepperRect.size.width, ' H=', lNSStepperRect.size.height,
    ' frame.size.height=', frame.size.height);
  {$ENDIF}
end;

procedure TCocoaSpinEdit.CalculateSubcontrolPos(
  const ASpinLCLBounds: TRect; out AEditBounds, AStepperBounds: TRect);
var
  lWidth, lHeight: Integer;
begin
  lWidth := ASpinLCLBounds.Right - ASpinLCLBounds.Left;
  lHeight := ASpinLCLBounds.Bottom - ASpinLCLBounds.Top;

  // Stepper
  AStepperBounds.Left := lWidth - SPINEDIT_DEFAULT_STEPPER_WIDTH;
  AStepperBounds.Top := SPINEDIT_EDIT_SPACING_FOR_SELECTION;
  AStepperBounds.Right := lWidth;
  AStepperBounds.Bottom := lHeight - SPINEDIT_EDIT_SPACING_FOR_SELECTION;

  // Edit
  AEditBounds.Left := SPINEDIT_EDIT_SPACING_FOR_SELECTION;
  AEditBounds.Top := SPINEDIT_EDIT_SPACING_FOR_SELECTION;
  AEditBounds.Right := lWidth - SPINEDIT_DEFAULT_STEPPER_WIDTH;
  AEditBounds.Bottom := lHeight - SPINEDIT_EDIT_SPACING_FOR_SELECTION;

  {$IFDEF COCOA_SPIN_DEBUG}
  WriteLn('[TCocoaSpinEdit.CalculateSubcontrolPos] lWidth=', lWidth, ' lHeight=', lHeight,
    ' Stepper.Left=', AStepperBounds.Left, ' Stepper.Top=', AStepperBounds.Top,
    ' Stepper.Right=', AStepperBounds.Right, ' Stepper.Bottom=', AStepperBounds.Bottom,
    ' Edit.Left=', AEditBounds.Left, ' Edit.Top=', AEditBounds.Top,
    ' Edit.Right=', AEditBounds.Right, ' Edit.Bottom=', AEditBounds.Bottom
    );
  {$ENDIF}
end;

procedure TCocoaSpinEdit.StepperChanged(sender: NSObject);
var
  lNSStr: NSString;
  lStr: string;
begin
  lStr := Format('%.*f', [Spin.DecimalPlaces, Stepper.doubleValue()]);
  lNSStr := CocoaUtils.NSStringUtf8(lStr);
  Edit.setStringValue(lNSStr);
  lNSStr.release;
  // This implements OnChange for both user and code changes
  if callback <> nil then callback.SendOnTextChanged();
end;

function TCocoaSpinEdit.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaSpinEdit.becomeFirstResponder: Boolean;
begin
  Result := Edit.becomeFirstResponder;
  if Assigned(callback) then
    callback.BecomeFirstResponder;
end;

function TCocoaSpinEdit.resignFirstResponder: Boolean;
begin
  Result := inherited resignFirstResponder;
  if Assigned(callback) then
    callback.ResignFirstResponder;
end;

function TCocoaSpinEdit.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaSpinEdit.lclClearCallback;
begin
  callback := nil;
end;

function TCocoaSpinEdit.lclIsHandle: Boolean;
begin
  Result := True;
end;

function TCocoaSpinEdit.fittingSize: NSSize;
begin
  Result.width := -1;
  Edit.sizeToFit();
  Result.height := Edit.bounds.size.height + SPINEDIT_EDIT_SPACING_FOR_SELECTION * 2;
  {$IFDEF COCOA_SPIN_DEBUG}
  WriteLn('[TCocoaSpinEdit.fittingSize] width=', Result.width,
    ' height=', Result.height);
  {$ENDIF}
end;

function TCocoaTextField.lclIsHandle: Boolean;
begin
  Result := True;
end;

{$ELSE}

procedure TCocoaSpinEdit.dealloc;
var
  lFieldEditor: TCocoaFieldEditor;
begin
  lFieldEditor := GetFieldEditor();
  if (lFieldEditor <> nil) and (lFieldEditor.lastEditBox = Self) then
  begin
    lFieldEditor.lastEditBox := nil;
  end;

  if Stepper <> nil then
    Stepper.release;
  if NumberFormatter <> nil then
    NumberFormatter.release;

  inherited dealloc;
end;

procedure TCocoaSpinEdit.UpdateControl(ASpinEdit: TCustomFloatSpinEdit);
begin
  Stepper.setMaxValue(ASpinEdit.MaxValue);
  Stepper.setMinValue(ASpinEdit.MinValue);
  Stepper.setIncrement(ASpinEdit.Increment);
  Stepper.setDoubleValue(ASpinEdit.Value);

  // update the UI too
  StepperChanged(Self);
end;

procedure TCocoaSpinEdit.CreateSubcontrols(ASpinEdit: TCustomFloatSpinEdit; const AParams: TCreateParams);
var
  lParams: TCreateParams;
begin
  {$IFDEF COCOA_SPIN_DEBUG}
  WriteLn('[TCocoaSpinEdit.CreateSubcontrols]');
  {$ENDIF}

  Spin := ASpinEdit;

  // Now creates the subcontrols
  lParams := AParams;
  //lParams.Style := AParams.Style or WS_VISIBLE;

  // Stepper
  lParams.X := AParams.X + AParams.Width - SPINEDIT_DEFAULT_STEPPER_WIDTH;
  lParams.Width := SPINEDIT_DEFAULT_STEPPER_WIDTH;
  Stepper := NSStepper.alloc.lclInitWithCreateParams(lParams);
  Stepper.setValueWraps(False);

  // Change event for the stepper
  Stepper.setTarget(Self);
  Stepper.setAction(objcselector('StepperChanged:'));

  // Accept numbers only
  setDelegate(Self);

  { The default way to do this in Cocoa is with NSNumberFormatter
    But it is a bit annoying, it just disallows losing focus from the control
    instead of the Windows like solution to just override with the last value
    If we ever want the Cocoa behavior, instead of implementing controlTextDidChange
    do this:
  var
  lNSStr: NSString;
  lStr: string;
  i: Integer;

  NumberFormatter := NSNumberFormatter.alloc.init;
  lStr := '##0';
  if ASpinEdit.DecimalPlaces > 0 then lStr := lStr + '.';
  for i := 0 to ASpinEdit.DecimalPlaces-1 do
    lStr := lStr + '0';
  lNSStr := CocoaUtils.NSStringUtf8(lStr);
  NumberFormatter.setFormat(lNSStr);
  lNSStr.release;
  NumberFormatter.setNumberStyle(NSNumberFormatterDecimalStyle);
  setFormatter(NumberFormatter);}
end;

procedure TCocoaSpinEdit.PositionSubcontrols(const ALeft, ATop, AWidth, AHeight: Integer);
begin
  lclSetFrame(Types.Bounds(ALeft, ATop, AWidth, AHeight));
end;

procedure TCocoaSpinEdit.StepperChanged(sender: NSObject);
var
  lNSStr: NSString;
  lStr: string;
begin
  lStr := Format('%.*f', [Spin.DecimalPlaces, Stepper.doubleValue()]);
  lNSStr := CocoaUtils.NSStringUtf8(lStr);
  setStringValue(lNSStr);
  lNSStr.release;
  // This implements OnChange for both user and code changes
  if callback <> nil then callback.SendOnTextChanged();
end;

function TCocoaSpinEdit.GetFieldEditor: TCocoaFieldEditor;
var
  lFieldEditor: TCocoaFieldEditor;
  lText: NSText;
begin
  Result := nil;
  if window = nil then Exit;
  lText := window.fieldEditor_forObject(True, Self);
  if (lText <> nil) and lText.isKindOfClass_(TCocoaFieldEditor) then
  begin
    Result := TCocoaFieldEditor(lText);
  end;
end;

procedure TCocoaSpinEdit.controlTextDidChange(obj: NSNotification);
var
  lValid: Boolean = False;
  lValue: String;
  lFloat: Double;
begin
  lValue := CocoaUtils.NSStringToString(stringValue());
  lValid := SysUtils.TryStrToFloat(lValue, lFloat);
  Spin.Value := lFloat;
end;

function TCocoaSpinEdit.acceptsFirstResponder: Boolean;
begin
  Result := True;
end;

function TCocoaSpinEdit.becomeFirstResponder: Boolean;
begin
  Result := inherited becomeFirstResponder;
  callback.BecomeFirstResponder;
end;

function TCocoaSpinEdit.RealResignFirstResponder: Boolean;
begin
  callback.ResignFirstResponder;
  Result := True;
end;

// See TCocoaTextField.resignFirstResponder as to why this is done here
function TCocoaSpinEdit.resignFirstResponder: Boolean;
var
  lFieldEditor: TCocoaFieldEditor;
begin
  //DebugLn('[TCocoaTextField.resignFirstResponder]');
  Result := inherited resignFirstResponder;
  lFieldEditor := GetFieldEditor();
  if (lFieldEditor <> nil) then
  begin
    lFieldEditor.lastEditBox := Self;
  end;
end;

function TCocoaSpinEdit.lclGetCallback: ICommonCallback;
begin
  Result := callback;
end;

procedure TCocoaSpinEdit.lclClearCallback;
begin
  callback := nil;
end;

procedure TCocoaSpinEdit.resetCursorRects;
begin
  // this will not work well because
  // cocoa replaced TextField and TextView cursors in
  // mouseEntered, mouseMoved and CursorUpdate
  if not callback.resetCursorRects then
    inherited resetCursorRects;
end;

function TCocoaSpinEdit.lclIsHandle: Boolean;
begin
  Result := True;
end;

procedure TCocoaSpinEdit.lclSetVisible(AVisible: Boolean);
begin
  inherited lclSetVisible(AVisible);
  Stepper.setHidden(not AVisible);
end;

procedure TCocoaSpinEdit.lclSetFrame(const r: TRect);
var
  ns, lStepperNS: NSRect;
  svHeight: CGFloat;
  lRect, lStepperRect: TRect;
begin
  lRect := r;
  lStepperRect := r;
  lRect.Right := lRect.Right - SPINEDIT_DEFAULT_STEPPER_WIDTH;
  lStepperRect.Left := lRect.Right;
  svHeight := GetNSViewSuperViewHeight(Self);
  if Assigned(superview)  then
  begin
    LCLToNSRect(lRect, svHeight, ns);
    LCLToNSRect(lStepperRect, svHeight, lStepperNS);
  end
  else
  begin
    ns := RectToNSRect(lRect);
    lStepperNS := RectToNSRect(lStepperRect);
  end;
  {$IFDEF COCOA_DEBUG_SETBOUNDS}
  WriteLn(Format('LCLViewExtension.lclSetFrame: %s Bounds=%s height=%d ns_pos=%d %d ns_size=%d %d',
    [NSStringToString(Self.ClassName), dbgs(r), Round(svHeight),
     Round(ns.origin.x), Round(ns.origin.y), Round(ns.size.width), Round(ns.size.height)]));
  {$ENDIF}
  setFrame(ns);
  Stepper.setFrame(lStepperNS);
end;

function TCocoaSpinEdit.fittingSize: NSSize;
begin
  Result.width := -1;
  sizeToFit();
  Result.height := bounds.size.height;
  {$IFDEF COCOA_SPIN_DEBUG}
  WriteLn('[TCocoaSpinEdit.fittingSize] width=', Result.width, ' height=', Result.height);
  {$ENDIF}
end;

{$ENDIF}

end.

